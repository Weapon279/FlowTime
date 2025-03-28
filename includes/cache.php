<?php
/**
 * Sistema de caché
 * 
 * Implementa funciones para el manejo de caché para optimizar el rendimiento
 */

// Prevenir acceso directo al archivo
if (!defined('ACCESO_PERMITIDO')) {
    header('HTTP/1.0 403 Forbidden');
    exit;
}

/**
 * Obtiene un valor de la caché
 * 
 * @param string $clave Clave del valor a obtener
 * @return mixed|null Valor almacenado o null si no existe o ha expirado
 */
function obtenerCache($clave) {
    // Si la caché está desactivada, retornar null
    if (!CACHE_ENABLED) {
        return null;
    }
    
    $db = getDbConnection();
    
    // Limpiar caché expirada
    limpiarCacheExpirada();
    
    // Buscar en la caché
    $stmt = $db->prepare("
        SELECT valor, expiracion
        FROM cache
        WHERE clave = :clave
    ");
    
    $stmt->execute([':clave' => $clave]);
    $resultado = $stmt->fetch();
    
    // Si no existe o ha expirado, retornar null
    if (!$resultado || $resultado['expiracion'] < time()) {
        return null;
    }
    
    // Deserializar y retornar el valor
    return unserialize($resultado['valor']);
}

/**
 * Almacena un valor en la caché
 * 
 * @param string $clave Clave para almacenar el valor
 * @param mixed $valor Valor a almacenar
 * @param int $tiempo Tiempo de vida en segundos (opcional)
 * @return bool True si se almacenó correctamente, false en caso contrario
 */
function guardarCache($clave, $valor, $tiempo = null) {
    // Si la caché está desactivada, retornar false
    if (!CACHE_ENABLED) {
        return false;
    }
    
    $db = getDbConnection();
    
    // Usar tiempo predeterminado si no se especifica
    if ($tiempo === null) {
        $tiempo = CACHE_LIFETIME;
    }
    
    // Calcular tiempo de expiración
    $expiracion = time() + $tiempo;
    
    // Serializar el valor
    $valorSerializado = serialize($valor);
    
    // Intentar actualizar si ya existe
    $stmt = $db->prepare("
        INSERT INTO cache (clave, valor, expiracion)
        VALUES (:clave, :valor, :expiracion)
        ON DUPLICATE KEY UPDATE
        valor = :valor, expiracion = :expiracion
    ");
    
    return $stmt->execute([
        ':clave' => $clave,
        ':valor' => $valorSerializado,
        ':expiracion' => $expiracion
    ]);
}

/**
 * Elimina un valor de la caché
 * 
 * @param string $clave Clave del valor a eliminar
 * @return bool True si se eliminó correctamente, false en caso contrario
 */
function eliminarCache($clave) {
    // Si la caché está desactivada, retornar false
    if (!CACHE_ENABLED) {
        return false;
    }
    
    $db = getDbConnection();
    
    $stmt = $db->prepare("
        DELETE FROM cache
        WHERE clave = :clave
    ");
    
    return $stmt->execute([':clave' => $clave]);
}

/**
 * Limpia toda la caché
 * 
 * @return bool True si se limpió correctamente, false en caso contrario
 */
function limpiarCache() {
    // Si la caché está desactivada, retornar false
    if (!CACHE_ENABLED) {
        return false;
    }
    
    $db = getDbConnection();
    
    $stmt = $db->prepare("TRUNCATE TABLE cache");
    
    return $stmt->execute();
}

/**
 * Limpia la caché expirada
 * 
 * @return bool True si se limpió correctamente, false en caso contrario
 */
function limpiarCacheExpirada() {
    // Si la caché está desactivada, retornar false
    if (!CACHE_ENABLED) {
        return false;
    }
    
    $db = getDbConnection();
    
    $stmt = $db->prepare("
        DELETE FROM cache
        WHERE expiracion < :tiempo_actual
    ");
    
    return $stmt->execute([':tiempo_actual' => time()]);
}

/**
 * Genera una clave de caché basada en parámetros
 * 
 * @param string $prefijo Prefijo para la clave
 * @param array $parametros Parámetros para generar la clave
 * @return string Clave generada
 */
function generarClaveCache($prefijo, $parametros = []) {
    // Ordenar parámetros para asegurar consistencia
    if (!empty($parametros) && is_array($parametros)) {
        ksort($parametros);
    }
    
    // Generar hash de los parámetros
    $hash = md5(serialize($parametros));
    
    // Retornar clave con prefijo
    return $prefijo . '_' . $hash;
}

/**
 * Ejecuta una función y almacena su resultado en caché
 * 
 * @param string $clave Clave para almacenar el resultado
 * @param callable $funcion Función a ejecutar
 * @param int $tiempo Tiempo de vida en segundos (opcional)
 * @return mixed Resultado de la función
 */
function cachear($clave, $funcion, $tiempo = null) {
    // Intentar obtener de la caché
    $resultado = obtenerCache($clave);
    
    // Si no está en caché, ejecutar función y guardar resultado
    if ($resultado === null) {
        $resultado = $funcion();
        guardarCache($clave, $resultado, $tiempo);
    }
    
    return $resultado;
}

/**
 * Cachea una consulta SQL
 * 
 * @param string $sql Consulta SQL
 * @param array $parametros Parámetros de la consulta
 * @param int $tiempo Tiempo de vida en segundos (opcional)
 * @return array Resultado de la consulta
 */
function cachearConsulta($sql, $parametros = [], $tiempo = null) {
    // Si la caché de consultas está desactivada, ejecutar directamente
    if (!DB_QUERY_CACHE) {
        return ejecutarConsulta($sql, $parametros);
    }
    
    // Generar clave de caché
    $clave = generarClaveCache('query', [
        'sql' => $sql,
        'params' => $parametros
    ]);
    
    // Usar tiempo predeterminado si no se especifica
    if ($tiempo === null) {
        $tiempo = DB_QUERY_CACHE_TIME;
    }
    
    // Cachear la consulta
    return cachear($clave, function() use ($sql, $parametros) {
        return ejecutarConsulta($sql, $parametros);
    }, $tiempo);
}

/**
 * Ejecuta una consulta SQL
 * 
 * @param string $sql Consulta SQL
 * @param array $parametros Parámetros de la consulta
 * @return array Resultado de la consulta
 */
function ejecutarConsulta($sql, $parametros = []) {
    $db = getDbConnection();
    
    $stmt = $db->prepare($sql);
    $stmt->execute($parametros);
    
    return $stmt->fetchAll();
}