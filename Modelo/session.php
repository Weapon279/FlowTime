<?php
/**
 * Gestión de sesiones seguras
 * 
 * Implementa funciones para manejar sesiones de forma segura
 * y prevenir ataques como session hijacking, fixation, etc.
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
    // Configurar opciones de sesión para mayor seguridad
    ini_set('session.use_strict_mode', 1);
    ini_set('session.use_only_cookies', 1);
    ini_set('session.use_trans_sid', 0);
    ini_set('session.cookie_httponly', 1);
    
    // Configurar cookie segura en producción
    if (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') {
        ini_set('session.cookie_secure', 1);
    }
    
    // Configurar SameSite=Lax para prevenir CSRF
    if (PHP_VERSION_ID >= 70300) {
        session_set_cookie_params([
            'lifetime' => 7200, // 2 horas
            'path' => '/',
            'domain' => '',
            'secure' => isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on',
            'httponly' => true,
            'samesite' => 'Lax'
        ]);
    }
    
    // Iniciar sesión
    session_start();
    
    // Regenerar ID de sesión periódicamente para prevenir ataques de fijación de sesión
    if (!isset($_SESSION['ultima_regeneracion']) || time() - $_SESSION['ultima_regeneracion'] > 300) {
        session_regenerate_id(true);
        $_SESSION['ultima_regeneracion'] = time();
    }
    
    // Verificar tiempo de inactividad
    if (isset($_SESSION['ultimo_acceso']) && time() - $_SESSION['ultimo_acceso'] > 7200) {
        cerrarSesion();
        session_start();
        $_SESSION['mensaje_error'] = 'Tu sesión ha expirado por inactividad. Por favor, inicia sesión nuevamente.';
    }
    
    // Actualizar tiempo de último acceso
    $_SESSION['ultimo_acceso'] = time();
    
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
 * Cierra la sesión actual
 * 
 * @return void
 */
function cerrarSesion() {
    // Registrar cierre de sesión si hay un usuario autenticado
    if (isset($_SESSION['usuario_id'])) {
        $db = getDB();
        
        $sql = "INSERT INTO log_accesos (usuario_id, email, ip, user_agent, accion) 
                VALUES (:usuario_id, :email, :ip, :user_agent, 'logout')";
        
        $params = [
            ':usuario_id' => $_SESSION['usuario_id'],
            ':email' => $_SESSION['email'] ?? '',
            ':ip' => $_SERVER['REMOTE_ADDR'],
            ':user_agent' => $_SERVER['HTTP_USER_AGENT']
        ];
        
        try {
            $db->execute($sql, $params);
        } catch (Exception $e) {
            error_log('Error al registrar cierre de sesión: ' . $e->getMessage());
        }
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
    return isset($_SESSION['tipo_cuenta']) && $_SESSION['tipo_cuenta'] === 'premium';
}

/**
 * Verifica si el usuario tiene permiso para acceder a una funcionalidad
 * 
 * @param string $funcionalidad Nombre de la funcionalidad a verificar
 * @return bool True si tiene permiso, false en caso contrario
 */
function tienePermiso($funcionalidad) {
    // Si no está autenticado, no tiene permiso
    if (!estaAutenticado()) {
        return false;
    }
    
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
        header('Location: login.php');
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
        $_SESSION['mensaje_error'] = 'No tienes permiso para acceder a esta funcionalidad. Actualiza a Premium para desbloquear todas las funcionalidades.';
        
        // Redirigir al dashboard
        header('Location: dashboard.php');
        exit;
    }
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
    
    $tipo = $mensaje['tipo'];
    $contenido = htmlspecialchars($mensaje['mensaje'], ENT_QUOTES, 'UTF-8');
    
    $html = '<div class="alert alert-' . $tipo . '">' . $contenido . '</div>';
    
    return $html;
}

/**
 * Genera un token CSRF
 * 
 * @return string Token generado
 */
function generarTokenCSRF() {
    if (!isset($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    
    return $_SESSION['csrf_token'];
}

/**
 * Verifica un token CSRF
 * 
 * @param string $token Token a verificar
 * @return bool True si el token es válido, false en caso contrario
 */
function verificarTokenCSRF($token) {
    return isset($_SESSION['csrf_token']) && hash_equals($_SESSION['csrf_token'], $token);
}

/**
 * Verifica el token CSRF en una solicitud POST
 * 
 * @return bool True si el token es válido, false en caso contrario
 */
function verificarCSRF() {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $token = $_POST['csrf_token'] ?? '';
        
        if (!verificarTokenCSRF($token)) {
            // Registrar posible ataque CSRF
            error_log('Posible ataque CSRF desde IP: ' . $_SERVER['REMOTE_ADDR']);
            
            // Mostrar mensaje de error
            $_SESSION['mensaje_error'] = 'Error de seguridad. Por favor, inténtalo de nuevo.';
            
            return false;
        }
    }
    
    return true;
}