<?php
/**
 * Gestión de sesiones
 * 
 * Contiene funciones para el manejo seguro de sesiones
 */

// Prevenir acceso directo al archivo
if (!defined('ACCESO_PERMITIDO')) {
    header('HTTP/1.0 403 Forbidden');
    exit;
}

/**
 * Inicia una sesión segura
 * 
 * @return void
 */
function iniciarSesionSegura() {
    // Configurar opciones de sesión
    ini_set('session.use_strict_mode', 1);
    ini_set('session.use_only_cookies', 1);
    ini_set('session.use_trans_sid', 0);
    ini_set('session.cookie_httponly', 1);
    
    // Configurar parámetros de cookie
    session_name(SESSION_NAME);
    
    $cookieParams = session_get_cookie_params();
    session_set_cookie_params(
        SESSION_LIFETIME,
        SESSION_PATH,
        SESSION_DOMAIN,
        SESSION_SECURE,
        SESSION_HTTPONLY
    );
    
    // Iniciar sesión
    session_start();
    
    // Regenerar ID de sesión periódicamente para prevenir ataques de fijación de sesión
    if (!isset($_SESSION['ultima_regeneracion']) || time() - $_SESSION['ultima_regeneracion'] > 300) {
        session_regenerate_id(true);
        $_SESSION['ultima_regeneracion'] = time();
    }
    
    // Verificar tiempo de inactividad
    if (isset($_SESSION['tiempo_inicio']) && time() - $_SESSION['tiempo_inicio'] > SESSION_LIFETIME) {
        cerrarSesion();
        session_start();
        $_SESSION['mensaje_error'] = ERROR_SESION_EXPIRADA;
    }
    
    // Actualizar tiempo de inicio
    $_SESSION['tiempo_inicio'] = time();
    
    // Verificar si la IP ha cambiado (posible robo de sesión)
    if (isset($_SESSION['ip_usuario']) && $_SESSION['ip_usuario'] !== $_SERVER['REMOTE_ADDR']) {
        cerrarSesion();
        session_start();
        $_SESSION['mensaje_error'] = 'Se ha detectado un cambio en tu dirección IP. Por seguridad, se ha cerrado tu sesión.';
    }
    
    // Guardar IP del usuario
    $_SESSION['ip_usuario'] = $_SERVER['REMOTE_ADDR'];
    
    // Guardar User-Agent del usuario
    if (!isset($_SESSION['user_agent'])) {
        $_SESSION['user_agent'] = $_SERVER['HTTP_USER_AGENT'];
    }
}

/**
 * Guarda una sesión en la base de datos
 * 
 * @param string $id ID de la sesión
 * @param int $usuario_id ID del usuario
 * @param string $ip IP del usuario
 * @param string $user_agent User-Agent del usuario
 * @param array $payload Datos de la sesión
 * @return bool True si se guardó correctamente, false en caso contrario
 */
function guardarSesionBD($id, $usuario_id, $ip, $user_agent, $payload) {
    $db = getDbConnection();
    
    $stmt = $db->prepare("
        INSERT INTO sesiones (id, usuario_id, ip, user_agent, payload, ultimo_acceso)
        VALUES (:id, :usuario_id, :ip, :user_agent, :payload, :ultimo_acceso)
        ON DUPLICATE KEY UPDATE
        ip = :ip, user_agent = :user_agent, payload = :payload, ultimo_acceso = :ultimo_acceso
    ");
    
    return $stmt->execute([
        ':id' => $id,
        ':usuario_id' => $usuario_id,
        ':ip' => $ip,
        ':user_agent' => $user_agent,
        ':payload' => serialize($payload),
        ':ultimo_acceso' => time()
    ]);
}

/**
 * Obtiene una sesión de la base de datos
 * 
 * @param string $id ID de la sesión
 * @return array|null Datos de la sesión o null si no existe
 */
function obtenerSesionBD($id) {
    $db = getDbConnection();
    
    $stmt = $db->prepare("
        SELECT payload, ultimo_acceso
        FROM sesiones
        WHERE id = :id
    ");
    
    $stmt->execute([':id' => $id]);
    $resultado = $stmt->fetch();
    
    if (!$resultado) {
        return null;
    }
    
    // Actualizar último acceso
    $stmt = $db->prepare("
        UPDATE sesiones
        SET ultimo_acceso = :ultimo_acceso
        WHERE id = :id
    ");
    
    $stmt->execute([
        ':id' => $id,
        ':ultimo_acceso' => time()
    ]);
    
    return unserialize($resultado['payload']);
}

/**
 * Elimina una sesión de la base de datos
 * 
 * @param string $id ID de la sesión
 * @return bool True si se eliminó correctamente, false en caso contrario
 */
function eliminarSesionBD($id) {
    $db = getDbConnection();
    
    $stmt = $db->prepare("
        DELETE FROM sesiones
        WHERE id = :id
    ");
    
    return $stmt->execute([':id' => $id]);
}

/**
 * Limpia las sesiones expiradas de la base de datos
 * 
 * @return bool True si se limpiaron correctamente, false en caso contrario
 */
function limpiarSesionesBD() {
    $db = getDbConnection();
    
    $stmt = $db->prepare("
        DELETE FROM sesiones
        WHERE ultimo_acceso < :tiempo_expiracion
    ");
    
    return $stmt->execute([
        ':tiempo_expiracion' => time() - SESSION_LIFETIME
    ]);
}

/**
 * Obtiene todas las sesiones activas  => time() - SESSION_LIFETIME
    ]);
}

/**
 * Obtiene todas las sesiones activas
 * 
 * @param int $usuario_id ID del usuario (opcional)
 * @return array Sesiones activas
 */
function obtenerSesionesActivas($usuario_id = null) {
    $db = getDbConnection();
    
    if ($usuario_id) {
        $stmt = $db->prepare("
            SELECT id, ip, user_agent, ultimo_acceso
            FROM sesiones
            WHERE usuario_id = :usuario_id
            ORDER BY ultimo_acceso DESC
        ");
        
        $stmt->execute([':usuario_id' => $usuario_id]);
    } else {
        $stmt = $db->prepare("
            SELECT id, usuario_id, ip, user_agent, ultimo_acceso
            FROM sesiones
            ORDER BY ultimo_acceso DESC
        ");
        
        $stmt->execute();
    }
    
    return $stmt->fetchAll();
}

/**
 * Cierra todas las sesiones de un usuario excepto la actual
 * 
 * @param int $usuario_id ID del usuario
 * @return bool True si se cerraron correctamente, false en caso contrario
 */
function cerrarOtrasSesiones($usuario_id) {
    $db = getDbConnection();
    
    $stmt = $db->prepare("
        DELETE FROM sesiones
        WHERE usuario_id = :usuario_id
        AND id != :sesion_actual
    ");
    
    return $stmt->execute([
        ':usuario_id' => $usuario_id,
        ':sesion_actual' => session_id()
    ]);
}

/**
 * Establece un mensaje flash en la sesión
 * 
 * @param string $tipo Tipo de mensaje (success, error, info, warning)
 * @param string $mensaje Contenido del mensaje
 * @return void
 */
function setMensajeFlash($tipo, $mensaje) {
    $_SESSION['mensaje_flash'] = [
        'tipo' => $tipo,
        'mensaje' => $mensaje
    ];
}

/**
 * Obtiene y elimina un mensaje flash de la sesión
 * 
 * @return array|null Mensaje flash o null si no existe
 */
function getMensajeFlash() {
    if (isset($_SESSION['mensaje_flash'])) {
        $mensaje = $_SESSION['mensaje_flash'];
        unset($_SESSION['mensaje_flash']);
        return $mensaje;
    }
    
    return null;
}

/**
 * Muestra un mensaje flash si existe
 * 
 * @return string HTML del mensaje o cadena vacía si no existe
 */
function mostrarMensajeFlash() {
    $mensaje = getMensajeFlash();
    
    if (!$mensaje) {
        return '';
    }
    
    switch ($mensaje['tipo']) {
        case 'success':
            return mensajeExito($mensaje['mensaje']);
        case 'error':
            return mensajeError($mensaje['mensaje']);
        case 'info':
            return mensajeInfo($mensaje['mensaje']);
        case 'warning':
            return mensajeAdvertencia($mensaje['mensaje']);
        default:
            return '<div class="alert">' . sanitizar($mensaje['mensaje']) . '</div>';
    }
}