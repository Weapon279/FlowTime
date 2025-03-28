<?php
/**
 * Funciones de seguridad
 * 
 * Implementa funciones para proteger contra inyección SQL, XSS y otras vulnerabilidades
 */

// Prevenir acceso directo al archivo
if (!defined('ACCESO_PERMITIDO')) {
    header('HTTP/1.0 403 Forbidden');
    exit;
}

/**
 * Sanitiza una entrada para prevenir XSS
 * 
 * @param string $input Entrada a sanitizar
 * @return string Entrada sanitizada
 */
function sanitizar($input) {
    return htmlspecialchars($input, ENT_QUOTES, 'UTF-8');
}

/**
 * Sanitiza un array de entradas
 * 
 * @param array $array Array a sanitizar
 * @return array Array sanitizado
 */
function sanitizarArray($array) {
    $resultado = [];
    
    foreach ($array as $clave => $valor) {
        if (is_array($valor)) {
            $resultado[$clave] = sanitizarArray($valor);
        } else {
            $resultado[$clave] = sanitizar($valor);
        }
    }
    
    return $resultado;
}

/**
 * Valida y sanitiza un ID
 * 
 * @param mixed $id ID a validar
 * @return int|false ID validado o false si no es válido
 */
function validarID($id) {
    return filter_var($id, FILTER_VALIDATE_INT);
}

/**
 * Valida y sanitiza un email
 * 
 * @param string $email Email a validar
 * @return string|false Email validado o false si no es válido
 */
function validarEmail($email) {
    return filter_var($email, FILTER_VALIDATE_EMAIL);
}

/**
 * Valida y sanitiza una URL
 * 
 * @param string $url URL a validar
 * @return string|false URL validada o false si no es válida
 */
function validarURL($url) {
    return filter_var($url, FILTER_VALIDATE_URL);
}

/**
 * Valida y sanitiza un número
 * 
 * @param mixed $numero Número a validar
 * @return float|false Número validado o false si no es válido
 */
function validarNumero($numero) {
    return filter_var($numero, FILTER_VALIDATE_FLOAT);
}

/**
 * Valida y sanitiza un número entero
 * 
 * @param mixed $numero Número a validar
 * @return int|false Número validado o false si no es válido
 */
function validarEntero($numero) {
    return filter_var($numero, FILTER_VALIDATE_INT);
}

/**
 * Valida y sanitiza un booleano
 * 
 * @param mixed $bool Booleano a validar
 * @return bool Booleano validado
 */
function validarBooleano($bool) {
    return filter_var($bool, FILTER_VALIDATE_BOOLEAN);
}

/**
 * Valida y sanitiza una fecha
 * 
 * @param string $fecha Fecha a validar (formato Y-m-d)
 * @return string|false Fecha validada o false si no es válida
 */
function validarFecha($fecha) {
    $fecha = trim($fecha);
    
    if (preg_match('/^\d{4}-\d{2}-\d{2}$/', $fecha)) {
        $partes = explode('-', $fecha);
        if (checkdate($partes[1], $partes[2], $partes[0])) {
            return $fecha;
        }
    }
    
    return false;
}

/**
 * Valida y sanitiza una hora
 * 
 * @param string $hora Hora a validar (formato H:i:s o H:i)
 * @return string|false Hora validada o false si no es válida
 */
function validarHora($hora) {
    $hora = trim($hora);
    
    if (preg_match('/^\d{2}:\d{2}(:\d{2})?$/', $hora)) {
        $partes = explode(':', $hora);
        $horas = (int)$partes[0];
        $minutos = (int)$partes[1];
        $segundos = isset($partes[2]) ? (int)$partes[2] : 0;
        
        if ($horas >= 0 && $horas <= 23 && $minutos >= 0 && $minutos <= 59 && $segundos >= 0 && $segundos <= 59) {
            return $hora;
        }
    }
    
    return false;
}

/**
 * Valida y sanitiza un nombre de archivo
 * 
 * @param string $nombre Nombre de archivo a validar
 * @return string|false Nombre validado o false si no es válido
 */
function validarNombreArchivo($nombre) {
    $nombre = trim($nombre);
    
    // Eliminar caracteres peligrosos
    $nombre = preg_replace('/[^\w\.-]/', '', $nombre);
    
    // Verificar que no esté vacío y no contenga rutas
    if (!empty($nombre) && strpos($nombre, '/') === false && strpos($nombre, '\\') === false) {
        return $nombre;
    }
    
    return false;
}

/**
 * Genera un nombre seguro para un archivo
 * 
 * @param string $nombre Nombre original del archivo
 * @return string Nombre seguro
 */
function generarNombreArchivoSeguro($nombre) {
    $extension = pathinfo($nombre, PATHINFO_EXTENSION);
    $nombreBase = pathinfo($nombre, PATHINFO_FILENAME);
    
    // Eliminar caracteres peligrosos del nombre base
    $nombreBase = preg_replace('/[^\w\.-]/', '', $nombreBase);
    
    // Generar nombre único
    $nombreSeguro = $nombreBase . '_' . uniqid() . '.' . $extension;
    
    return $nombreSeguro;
}

/**
 * Verifica si una extensión de archivo es permitida
 * 
 * @param string $nombre Nombre del archivo
 * @param array $extensionesPermitidas Extensiones permitidas
 * @return bool True si la extensión es permitida, false en caso contrario
 */
function extensionPermitida($nombre, $extensionesPermitidas) {
    $extension = strtolower(pathinfo($nombre, PATHINFO_EXTENSION));
    return in_array($extension, $extensionesPermitidas);
}

/**
 * Verifica si un archivo es una imagen
 * 
 * @param string $nombre Nombre del archivo
 * @return bool True si es una imagen, false en caso contrario
 */
function esImagen($nombre) {
    $extensionesPermitidas = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    return extensionPermitida($nombre, $extensionesPermitidas);
}

/**
 * Verifica si un archivo es un documento
 * 
 * @param string $nombre Nombre del archivo
 * @return bool True si es un documento, false en caso contrario
 */
function esDocumento($nombre) {
    $extensionesPermitidas = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'];
    return extensionPermitida($nombre, $extensionesPermitidas);
}

/**
 * Genera una contraseña aleatoria segura
 * 
 * @param int $longitud Longitud de la contraseña
 * @return string Contraseña generada
 */
function generarPasswordSeguro($longitud = 12) {
    $caracteres = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+';
    $password = '';
    
    for ($i = 0; $i < $longitud; $i++) {
        $password .= $caracteres[random_int(0, strlen($caracteres) - 1)];
    }
    
    return $password;
}

/**
 * Verifica la fortaleza de una contraseña
 * 
 * @param string $password Contraseña a verificar
 * @return array Array con resultado y mensaje
 */
function verificarFortalezaPassword($password) {
    $resultado = [
        'valida' => false,
        'mensaje' => ''
    ];
    
    // Verificar longitud
    if (strlen($password) < 8) {
        $resultado['mensaje'] = 'La contraseña debe tener al menos 8 caracteres.';
        return $resultado;
    }
    
    // Verificar mayúsculas
    if (!preg_match('/[A-Z]/', $password)) {
        $resultado['mensaje'] = 'La contraseña debe contener al menos una letra mayúscula.';
        return $resultado;
    }
    
    // Verificar minúsculas
    if (!preg_match('/[a-z]/', $password)) {
        $resultado['mensaje'] = 'La contraseña debe contener al menos una letra minúscula.';
        return $resultado;
    }
    
    // Verificar números
    if (!preg_match('/[0-9]/', $password)) {
        $resultado['mensaje'] = 'La contraseña debe contener al menos un número.';
        return $resultado;
    }
    
    // Verificar caracteres especiales
    if (!preg_match('/[^A-Za-z0-9]/', $password)) {
        $resultado['mensaje'] = 'La contraseña debe contener al menos un carácter especial.';
        return $resultado;
    }
    
    $resultado['valida'] = true;
    return $resultado;
}

/**
 * Protege contra ataques de fuerza bruta
 * 
 * @param string $ip Dirección IP
 * @param string $accion Acción a verificar
 * @param int $maxIntentos Número máximo de intentos
 * @param int $tiempoBloqueo Tiempo de bloqueo en segundos
 * @return bool True si está bloqueado, false en caso contrario
 */
function estaBloqueado($ip, $accion, $maxIntentos = 5, $tiempoBloqueo = 900) {
    $db = getDB();
    
    // Verificar intentos recientes
    $sql = "SELECT COUNT(*) as intentos 
            FROM log_accesos 
            WHERE ip = :ip 
            AND accion = :accion 
            AND fecha > DATE_SUB(NOW(), INTERVAL :tiempo_bloqueo SECOND)";
    
    $params = [
        ':ip' => $ip,
        ':accion' => $accion,
        ':tiempo_bloqueo' => $tiempoBloqueo
    ];
    
    try {
        $result = $db->query($sql, $params, 0);
        return $result[0]['intentos'] >= $maxIntentos;
    } catch (Exception $e) {
        error_log('Error al verificar bloqueo: ' . $e->getMessage());
        return false;
    }
}

/**
 * Registra un intento de acceso
 * 
 * @param string $ip Dirección IP
 * @param string $accion Acción realizada
 * @param int $usuario_id ID del usuario (opcional)
 * @param string $email Email del usuario (opcional)
 * @return bool True si se registró correctamente, false en caso contrario
 */
function registrarIntento($ip, $accion, $usuario_id = null, $email = null) {
    $db = getDB();
    
    $sql = "INSERT INTO log_accesos (usuario_id, email, ip, user_agent, accion) 
            VALUES (:usuario_id, :email, :ip, :user_agent, :accion)";
    
    $params = [
        ':usuario_id' => $usuario_id,
        ':email' => $email,
        ':ip' => $ip,
        ':user_agent' => $_SERVER['HTTP_USER_AGENT'],
        ':accion' => $accion
    ];
    
    try {
        $db->execute($sql, $params);
        return true;
    } catch (Exception $e) {
        error_log('Error al registrar intento: ' . $e->getMessage());
        return false;
    }
}

/**
 * Verifica si una solicitud es AJAX
 * 
 * @return bool True si es una solicitud AJAX, false en caso contrario
 */
function esAjax() {
    return !empty($_SERVER['HTTP_X_REQUESTED_WITH']) && 
           strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) === 'xmlhttprequest';
}

/**
 * Obtiene la IP real del cliente
 * 
 * @return string IP del cliente
 */
function obtenerIP() {
    $ip = '';
    
    if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
        $ip = $_SERVER['HTTP_CLIENT_IP'];
    } elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
        $ip = $_SERVER['HTTP_X_FORWARDED_FOR'];
    } else {
        $ip = $_SERVER['REMOTE_ADDR'];
    }
    
    return $ip;
}

/**
 * Verifica si una solicitud proviene del mismo sitio (previene CSRF)
 * 
 * @return bool True si es una solicitud del mismo sitio, false en caso contrario
 */
function verificarOrigen() {
    if (!isset($_SERVER['HTTP_REFERER'])) {
        return false;
    }
    
    $referer = parse_url($_SERVER['HTTP_REFERER']);
    $host = $_SERVER['HTTP_HOST'];
    
    return $referer['host'] === $host;
}

/**
 * Establece cabeceras de seguridad
 * 
 * @return void
 */
function establecerCabecerasSeguridad() {
    // Protección contra XSS
    header('X-XSS-Protection: 1; mode=block');
    
    // Prevenir MIME-sniffing
    header('X-Content-Type-Options: nosniff');
    
    // Política de seguridad de contenido (CSP)
    header("Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdnjs.cloudflare.com https://code.highcharts.com https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com https://cdnjs.cloudflare.com; img-src 'self' data:; connect-src 'self'");
    
    // Política de referencia
    header('Referrer-Policy: strict-origin-when-cross-origin');
    
    // Política de enmarcado (evitar clickjacking)
    header('X-Frame-Options: SAMEORIGIN');
    
    // Desactivar caché para archivos PHP
    header('Cache-Control: private, no-cache, no-store, must-revalidate');
    header('Pragma: no-cache');
    header('Expires: 0');
}