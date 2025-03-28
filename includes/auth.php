<?php
/**
 * Funciones de autenticación y autorización
 * 
 * Contiene funciones para gestionar la autenticación y autorización de usuarios
 */

// Prevenir acceso directo al archivo
if (!defined('ACCESO_PERMITIDO')) {
    header('HTTP/1.0 403 Forbidden');
    exit;
}

/**
 * Verifica si el usuario está autenticado
 * 
 * @return bool True si el usuario está autenticado, false en caso contrario
 */
function estaAutenticado() {
    return isset($_SESSION['usuario_id']) && !empty($_SESSION['usuario_id']);
}

/**
 * Verifica si el usuario tiene una cuenta premium
 * 
 * @return bool True si el usuario tiene cuenta premium, false en caso contrario
 */
function esPremium() {
    return isset($_SESSION['tipo_cuenta']) && $_SESSION['tipo_cuenta'] === CUENTA_PREMIUM;
}

/**
 * Verifica si el usuario tiene permiso para acceder a una funcionalidad premium
 * 
 * @param string $funcionalidad Nombre de la funcionalidad a verificar
 * @return bool True si tiene permiso, false en caso contrario
 */
function tienePermiso($funcionalidad) {
    // Si es premium, tiene acceso a todo
    if (esPremium()) {
        return true;
    }
    
    // Funcionalidades permitidas para usuarios gratuitos
    $funcionalidadesGratuitas = [
        'dashboard',
        'tareas',
        'calendario'
    ];
    
    return in_array($funcionalidad, $funcionalidadesGratuitas);
}

/**
 * Redirige al usuario si no está autenticado
 * 
 * @return void
 */
function requiereAutenticacion() {
    if (!estaAutenticado()) {
        // Guardar la URL actual para redirigir después del login
        $_SESSION['url_redireccion'] = $_SERVER['REQUEST_URI'];
        
        // Redirigir al login
        header('Location: ' . RUTA_LOGIN);
        exit;
    }
}

/**
 * Redirige al usuario si no tiene permiso para acceder a una funcionalidad
 * 
 * @param string $funcionalidad Nombre de la funcionalidad a verificar
 * @return void
 */
function requierePermiso($funcionalidad) {
    if (!tienePermiso($funcionalidad)) {
        // Mostrar mensaje de error
        $_SESSION['mensaje_error'] = ERROR_PERMISOS;
        
        // Redirigir al dashboard
        header('Location: ' . RUTA_DASHBOARD);
        exit;
    }
}

/**
 * Verifica si el usuario ha alcanzado el límite de su cuenta gratuita
 * 
 * @param string $tipo Tipo de límite a verificar (tareas, eventos, metas)
 * @param int $cantidad Cantidad actual
 * @return bool True si ha alcanzado el límite, false en caso contrario
 */
function haAlcanzadoLimite($tipo, $cantidad) {
    // Si es premium, no tiene límites
    if (esPremium()) {
        return false;
    }
    
    // Verificar según el tipo
    switch ($tipo) {
        case 'tareas':
            return $cantidad >= FREE_MAX_TASKS;
        case 'eventos':
            return $cantidad >= FREE_MAX_EVENTS;
        case 'metas':
            return $cantidad >= FREE_MAX_GOALS;
        default:
            return false;
    }
}

/**
 * Genera un hash seguro para una contraseña
 * 
 * @param string $password Contraseña en texto plano
 * @return string Hash de la contraseña
 */
function hashPassword($password) {
    return password_hash($password, PASSWORD_BCRYPT, ['cost' => HASH_COST]);
}

/**
 * Verifica si una contraseña coincide con su hash
 * 
 * @param string $password Contraseña en texto plano
 * @param string $hash Hash almacenado
 * @return bool True si la contraseña coincide, false en caso contrario
 */
function verificarPassword($password, $hash) {
    return password_verify($password, $hash);
}

/**
 * Genera un token seguro
 * 
 * @param int $length Longitud del token
 * @return string Token generado
 */
function generarToken($length = 32) {
    return bin2hex(random_bytes($length));
}

/**
 * Registra un intento de inicio de sesión
 * 
 * @param string $email Email del usuario
 * @param bool $exitoso Si el intento fue exitoso
 * @param int $usuario_id ID del usuario (opcional)
 * @return void
 */
function registrarIntentoLogin($email, $exitoso, $usuario_id = null) {
    $db = getDbConnection();
    
    $accion = $exitoso ? 'login_exitoso' : 'login_fallido';
    $ip = $_SERVER['REMOTE_ADDR'];
    $user_agent = $_SERVER['HTTP_USER_AGENT'];
    
    $stmt = $db->prepare("
        INSERT INTO log_accesos (usuario_id, email, ip, user_agent, accion)
        VALUES (:usuario_id, :email, :ip, :user_agent, :accion)
    ");
    
    $stmt->execute([
        ':usuario_id' => $usuario_id,
        ':email' => $email,
        ':ip' => $ip,
        ':user_agent' => $user_agent,
        ':accion' => $accion
    ]);
}

/**
 * Verifica si un usuario ha excedido el número máximo de intentos de inicio de sesión
 * 
 * @param string $email Email del usuario
 * @return bool True si ha excedido el límite, false en caso contrario
 */
function haExcedidoIntentosLogin($email) {
    $db = getDbConnection();
    
    $stmt = $db->prepare("
        SELECT COUNT(*) as intentos
        FROM log_accesos
        WHERE email = :email
        AND accion = 'login_fallido'
        AND fecha > DATE_SUB(NOW(), INTERVAL " . LOCKOUT_TIME . " SECOND)
    ");
    
    $stmt->execute([':email' => $email]);
    $resultado = $stmt->fetch();
    
    return $resultado['intentos'] >= MAX_LOGIN_ATTEMPTS;
}

/**
 * Bloquea temporalmente a un usuario después de demasiados intentos fallidos
 * 
 * @param string $email Email del usuario
 * @return void
 */
function bloquearUsuario($email) {
    // Aquí podríamos actualizar un campo en la base de datos
    // o simplemente usar la función haExcedidoIntentosLogin para verificar
}

/**
 * Inicia sesión para un usuario
 * 
 * @param array $usuario Datos del usuario
 * @return void
 */
function iniciarSesion($usuario) {
    // Regenerar ID de sesión para prevenir ataques de fijación de sesión
    session_regenerate_id(true);
    
    // Guardar datos del usuario en la sesión
    $_SESSION['usuario_id'] = $usuario['id'];
    $_SESSION['nombre'] = $usuario['nombre'];
    $_SESSION['apellido'] = $usuario['apellido'];
    $_SESSION['email'] = $usuario['email'];
    $_SESSION['tipo_cuenta'] = $usuario['tipo_cuenta'];
    
    // Guardar tiempo de inicio de sesión
    $_SESSION['tiempo_inicio'] = time();
    
    // Registrar inicio de sesión exitoso
    registrarIntentoLogin($usuario['email'], true, $usuario['id']);
    
    // Actualizar último login en la base de datos
    $db = getDbConnection();
    $stmt = $db->prepare("UPDATE usuarios SET ultimo_login = NOW() WHERE id = :id");
    $stmt->execute([':id' => $usuario['id']]);
}

/**
 * Cierra la sesión del usuario
 * 
 * @return void
 */
function cerrarSesion() {
    // Registrar cierre de sesión si hay un usuario autenticado
    if (isset($_SESSION['usuario_id'])) {
        $db = getDbConnection();
        
        $stmt = $db->prepare("
            INSERT INTO log_accesos (usuario_id, email, ip, user_agent, accion)
            VALUES (:usuario_id, :email, :ip, :user_agent, 'logout')
        ");
        
        $stmt->execute([
            ':usuario_id' => $_SESSION['usuario_id'],
            ':email' => $_SESSION['email'],
            ':ip' => $_SERVER['REMOTE_ADDR'],
            ':user_agent' => $_SERVER['HTTP_USER_AGENT']
        ]);
    }
    
    // Destruir todas las variables de sesión
    $_SESSION = [];
    
    // Destruir la cookie de sesión si existe
    if (ini_get("session.use_cookies")) {
        $params = session_get_cookie_params();
        setcookie(
            session_name(),
            '',
            time() - 42000,
            $params["path"],
            $params["domain"],
            $params["secure"],
            $params["httponly"]
        );
    }
    
    // Destruir la sesión
    session_destroy();
}