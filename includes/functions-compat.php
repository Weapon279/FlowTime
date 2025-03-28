<?php
/**
 * Funciones de compatibilidad
 * 
 * Este archivo contiene funciones que evitan conflictos con las funciones
 * existentes en otros archivos.
 */

// Prevenir acceso directo al archivo
if (!defined('ACCESO_PERMITIDO')) {
    header('HTTP/1.0 403 Forbidden');
    exit;
}

// Verificar si la función sanitizar ya está definida
if (!function_exists('sanitizar')) {
    /**
     * Sanitiza una entrada para prevenir XSS
     * 
     * @param string $input Entrada a sanitizar
     * @return string Entrada sanitizada
     */
    function sanitizar($input) {
        return htmlspecialchars($input, ENT_QUOTES, 'UTF-8');
    }
}

// Verificar si la función sanitizarArray ya está definida
if (!function_exists('sanitizarArray')) {
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
}

// Verificar si la función validarEmail ya está definida
if (!function_exists('validarEmail')) {
    /**
     * Valida y sanitiza un email
     * 
     * @param string $email Email a validar
     * @return string|false Email validado o false si no es válido
     */
    function validarEmail($email) {
        return filter_var($email, FILTER_VALIDATE_EMAIL);
    }
}

// Verificar si la función obtenerIP ya está definida
if (!function_exists('obtenerIP')) {
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
}

// Verificar si la función estaBloqueado ya está definida
if (!function_exists('estaBloqueado')) {
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
}

// Verificar si la función registrarIntento ya está definida
if (!function_exists('registrarIntento')) {
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
}

// Verificar si la función verificarFortalezaPassword ya está definida
if (!function_exists('verificarFortalezaPassword')) {
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
}

// Verificar si la función generarPasswordSeguro ya está definida
if (!function_exists('generarPasswordSeguro')) {
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
}

// Verificar si la función verificarCSRF ya está definida
if (!function_exists('verificarCSRF')) {
    /**
     * Verifica el token CSRF
     * 
     * @return bool True si el token es válido, false en caso contrario
     */
    function verificarCSRF() {
        if (!isset($_POST['csrf_token']) || !isset($_SESSION['csrf_token'])) {
            return false;
        }
        
        $valid = hash_equals($_SESSION['csrf_token'], $_POST['csrf_token']);
        
        // Generar nuevo token después de la verificación
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        
        return $valid;
    }
}

// Verificar si la función generarTokenCSRF ya está definida
if (!function_exists('generarTokenCSRF')) {
    /**
     * Genera un token CSRF
     * 
     * @return string Token CSRF
     */
    function generarTokenCSRF() {
        $token = bin2hex(random_bytes(32));
        $_SESSION['csrf_token'] = $token;
        return $token;
    }
}

// Verificar si la función setMensajeFlash ya está definida
if (!function_exists('setMensajeFlash')) {
    /**
     * Establece un mensaje flash
     * 
     * @param string $tipo Tipo de mensaje (success, error, info, warning)
     * @param string $mensaje Mensaje a mostrar
     * @return void
     */
    function setMensajeFlash($tipo, $mensaje) {
        $_SESSION['flash_mensaje'] = [
            'tipo' => $tipo,
            'mensaje' => $mensaje
        ];
    }
}

// Verificar si la función getMensajeFlash ya está definida
if (!function_exists('getMensajeFlash')) {
    /**
     * Obtiene y elimina un mensaje flash
     * 
     * @return array|null Mensaje flash o null si no hay mensaje
     */
    function getMensajeFlash() {
        if (isset($_SESSION['flash_mensaje'])) {
            $mensaje = $_SESSION['flash_mensaje'];
            unset($_SESSION['flash_mensaje']);
            return $mensaje;
        }
        
        return null;
    }
}

// Verificar si la función estaAutenticado ya está definida
if (!function_exists('estaAutenticado')) {
    /**
     * Verifica si el usuario está autenticado
     * 
     * @return bool True si está autenticado, false en caso contrario
     */
    function estaAutenticado() {
        return isset($_SESSION['usuario_id']);
    }
}

