<?php
/**
 * Configuración de la base de datos
 * 
 * Contiene las credenciales y configuración para la conexión a la base de datos
 */

// Prevenir acceso directo al archivo
if (!defined('ACCESO_PERMITIDO')) {
    header('HTTP/1.0 403 Forbidden');
    exit;
}

// Configuración de la base de datos
define('DB_HOST', 'localhost');
define('DB_NAME', 'timeflow');
define('DB_USER', 'root'); // Cambiar en producción
define('DB_PASS', ''); // Cambiar en producción
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', 'utf8mb4_unicode_ci');

// Configuración de PDO
define('DB_DSN', 'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=' . DB_CHARSET);
define('DB_OPTIONS', [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES => false,
    PDO::MYSQL_ATTR_FOUND_ROWS => true,
    PDO::ATTR_PERSISTENT => true // Conexiones persistentes para mejor rendimiento
]);

// Configuración de caché de consultas
define('DB_QUERY_CACHE', true);
define('DB_QUERY_CACHE_TIME', 300); // 5 minutos en segundos

// Configuración de pool de conexiones (para servidores con alta carga)
define('DB_MAX_CONNECTIONS', 100);
define('DB_CONNECTION_TIMEOUT', 5); // segundos

/**
 * Función para obtener una conexión a la base de datos
 * 
 * @return PDO Objeto de conexión a la base de datos
 */
function getDbConnection() {
    static $pdo = null;
    
    if ($pdo === null) {
        try {
            $pdo = new PDO(DB_DSN, DB_USER, DB_PASS, DB_OPTIONS);
        } catch (PDOException $e) {
            // Registrar el error pero no mostrar detalles sensibles
            error_log('Error de conexión a la base de datos: ' . $e->getMessage());
            die('Error de conexión a la base de datos. Por favor, inténtelo más tarde.');
        }
    }
    
    return $pdo;
}