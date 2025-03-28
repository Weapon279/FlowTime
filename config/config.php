<?php
/**
 * Archivo de configuración principal
 * 
 * Contiene las configuraciones generales de la aplicación
 */

// Prevenir acceso directo al archivo
if (!defined('ACCESO_PERMITIDO')) {
    header('HTTP/1.0 403 Forbidden');
    exit;
}

// Configuración de la aplicación
define('APP_NAME', 'FlowTime');
define('APP_VERSION', '1.0.0');
define('APP_URL', 'http://localhost/flowtime'); // Cambiar en producción
define('APP_ROOT', dirname(__DIR__));
define('APP_TIMEZONE', 'America/Mexico_City'); // Ajustar según tu ubicación

// Configuración de sesiones
define('SESSION_NAME', 'flowtime_session');
define('SESSION_LIFETIME', 7200); // 2 horas en segundos
define('SESSION_PATH', '/');
define('SESSION_DOMAIN', '');
define('SESSION_SECURE', false); // Cambiar a true en producción con HTTPS
define('SESSION_HTTPONLY', true);

// Configuración de cookies
define('COOKIE_LIFETIME', 604800); // 1 semana en segundos
define('COOKIE_PATH', '/');
define('COOKIE_DOMAIN', '');
define('COOKIE_SECURE', false); // Cambiar a true en producción con HTTPS
define('COOKIE_HTTPONLY', true);
define('COOKIE_SAMESITE', 'Lax');

// Configuración de seguridad
define('HASH_COST', 12); // Costo de bcrypt
define('TOKEN_EXPIRY', 3600); // 1 hora en segundos
define('MAX_LOGIN_ATTEMPTS', 5); // Intentos máximos de inicio de sesión
define('LOCKOUT_TIME', 900); // 15 minutos en segundos

// Configuración de caché
define('CACHE_ENABLED', true);
define('CACHE_LIFETIME', 3600); // 1 hora en segundos

// Configuración de límites para usuarios gratuitos
define('FREE_MAX_TASKS', 50); // Máximo de tareas para usuarios gratuitos
define('FREE_MAX_EVENTS', 30); // Máximo de eventos para usuarios gratuitos
define('FREE_MAX_GOALS', 5); // Máximo de metas para usuarios gratuitos

// Configuración de correo electrónico
define('MAIL_HOST', 'smtp.example.com');
define('MAIL_PORT', 587);
define('MAIL_USERNAME', 'noreply@example.com');
define('MAIL_PASSWORD', 'tu_contraseña');
define('MAIL_ENCRYPTION', 'tls');
define('MAIL_FROM_ADDRESS', 'noreply@example.com');
define('MAIL_FROM_NAME', 'FlowTime');

// Configuración de pagos
define('PAYMENT_GATEWAY', 'paypal'); // paypal, stripe, etc.
define('PAYMENT_SANDBOX', true); // Cambiar a false en producción
define('PAYMENT_CURRENCY', 'MXN');
define('PAYMENT_MONTHLY_PRICE', 99.00);
define('PAYMENT_ANNUAL_PRICE', 990.00);

// Configuración de mantenimiento
define('MAINTENANCE_MODE', false);
define('MAINTENANCE_MESSAGE', 'Estamos realizando mantenimiento. Volveremos pronto.');

// Configuración de depuración
define('DEBUG_MODE', true); // Cambiar a false en producción
define('LOG_ERRORS', true);
define('ERROR_LOG_FILE', APP_ROOT . '/logs/error.log');

// Configuración de API
define('API_RATE_LIMIT', 60); // Solicitudes por minuto
define('API_TOKEN_LIFETIME', 3600); // 1 hora en segundos