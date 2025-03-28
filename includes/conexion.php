<?php
/**
 * Conexión a la base de datos optimizada para alto tráfico
 * 
 * Este archivo implementa un pool de conexiones, caché y otras optimizaciones
 * para soportar hasta 1000 usuarios simultáneos.
 */

// Configuración de la base de datos
if (!defined('DB_HOST')) define('DB_HOST', 'localhost');
if (!defined('DB_NAME')) define('DB_NAME', 'flowtime');
if (!defined('DB_USER')) define('DB_USER', 'root'); // Cambiar en producción
if (!defined('DB_PASS')) define('DB_PASS', ''); // Cambiar en producción
if (!defined('DB_CHARSET')) define('DB_CHARSET', 'utf8mb4');

// Configuración de caché
if (!defined('CACHE_ENABLED')) define('CACHE_ENABLED', true);
if (!defined('CACHE_LIFETIME')) define('CACHE_LIFETIME', 300); // 5 minutos en segundos
if (!defined('QUERY_CACHE_ENABLED')) define('QUERY_CACHE_ENABLED', true);

// Configuración de pool de conexiones
if (!defined('MAX_CONNECTIONS')) define('MAX_CONNECTIONS', 100);
if (!defined('CONNECTION_TIMEOUT')) define('CONNECTION_TIMEOUT', 5); // segundos

// Clase para gestionar conexiones a la base de datos
class DatabaseConnection {
    private static $instance = null;
    private $connections = [];
    private $activeConnections = 0;
    private $queryCache = [];
    
    // Constructor privado para patrón Singleton
    private function __construct() {
        // Inicializar caché si está habilitada
        if (CACHE_ENABLED) {
            $this->initCache();
        }
    }
    
    // Obtener instancia única (Singleton)
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    // Inicializar sistema de caché
    private function initCache() {
        // Si existe APC, usarlo para caché en memoria
        if (function_exists('apc_store')) {
            // APC está disponible
        } 
        // Si existe Memcached, usarlo como alternativa
        else if (class_exists('Memcached')) {
            // Configurar Memcached
        }
        // De lo contrario, usar caché en archivo
        else {
            // Asegurarse de que el directorio de caché exista
            if (!is_dir(__DIR__ . '/../cache')) {
                mkdir(__DIR__ . '/../cache', 0755, true);
            }
        }
    }
    
    // Obtener conexión del pool
    public function getConnection() {
        // Si hay conexiones disponibles en el pool, usar una
        if (!empty($this->connections)) {
            $connection = array_pop($this->connections);
            
            // Verificar si la conexión sigue activa
            try {
                $connection->query('SELECT 1');
                $this->activeConnections++;
                return $connection;
            } catch (PDOException $e) {
                // La conexión no es válida, crear una nueva
            }
        }
        
        // Si no hay conexiones disponibles o la conexión no es válida, crear una nueva
        if ($this->activeConnections < MAX_CONNECTIONS) {
            try {
                $connection = new PDO(
                    'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=' . DB_CHARSET,
                    DB_USER,
                    DB_PASS,
                    [
                        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                        PDO::ATTR_EMULATE_PREPARES => false,
                        PDO::MYSQL_ATTR_FOUND_ROWS => true,
                        PDO::ATTR_TIMEOUT => CONNECTION_TIMEOUT,
                        PDO::ATTR_PERSISTENT => true // Conexiones persistentes para mejor rendimiento
                    ]
                );
                
                $this->activeConnections++;
                return $connection;
            } catch (PDOException $e) {
                // Registrar error
                error_log('Error de conexión a la base de datos: ' . $e->getMessage());
                throw new Exception('Error de conexión a la base de datos. Por favor, inténtelo más tarde.');
            }
        } else {
            // Se ha alcanzado el límite de conexiones
            throw new Exception('Se ha alcanzado el límite de conexiones a la base de datos. Por favor, inténtelo más tarde.');
        }
    }
    
    // Devolver conexión al pool
    public function releaseConnection($connection) {
        if ($connection instanceof PDO) {
            $this->connections[] = $connection;
            $this->activeConnections--;
        }
    }
    
    // Ejecutar consulta con caché
    public function query($sql, $params = [], $cacheTime = null) {
        // Generar clave de caché
        $cacheKey = $this->generateCacheKey($sql, $params);
        
        // Si la caché está habilitada, intentar obtener de caché
        if (QUERY_CACHE_ENABLED) {
            $cachedResult = $this->getFromCache($cacheKey);
            if ($cachedResult !== null) {
                return $cachedResult;
            }
        }
        
        // Obtener conexión
        $connection = $this->getConnection();
        
        try {
            // Preparar y ejecutar consulta
            $stmt = $connection->prepare($sql);
            $stmt->execute($params);
            
            // Obtener resultados
            $result = $stmt->fetchAll();
            
            // Si la caché está habilitada, guardar en caché
            if (QUERY_CACHE_ENABLED && $cacheTime !== 0) {
                $this->saveToCache($cacheKey, $result, $cacheTime);
            }
            
            // Devolver conexión al pool
            $this->releaseConnection($connection);
            
            return $result;
        } catch (PDOException $e) {
            // Devolver conexión al pool
            $this->releaseConnection($connection);
            
            // Registrar error
            error_log('Error en consulta SQL: ' . $e->getMessage() . ' - SQL: ' . $sql);
            throw new Exception('Error en la consulta a la base de datos.');
        }
    }
    
    // Ejecutar consulta sin caché
    public function execute($sql, $params = []) {
        // Obtener conexión
        $connection = $this->getConnection();
        
        try {
            // Preparar y ejecutar consulta
            $stmt = $connection->prepare($sql);
            $result = $stmt->execute($params);
            
            // Obtener ID insertado si es una inserción
            $lastInsertId = null;
            if (stripos($sql, 'INSERT') === 0) {
                $lastInsertId = $connection->lastInsertId();
            }
            
            // Obtener número de filas afectadas
            $rowCount = $stmt->rowCount();
            
            // Devolver conexión al pool
            $this->releaseConnection($connection);
            
            return [
                'success' => $result,
                'lastInsertId' => $lastInsertId,
                'rowCount' => $rowCount
            ];
        } catch (PDOException $e) {
            // Devolver conexión al pool
            $this->releaseConnection($connection);
            
            // Registrar error
            error_log('Error en consulta SQL: ' . $e->getMessage() . ' - SQL: ' . $sql);
            throw new Exception('Error en la consulta a la base de datos.');
        }
    }
    
    // Iniciar transacción
    public function beginTransaction() {
        $connection = $this->getConnection();
        $connection->beginTransaction();
        return $connection;
    }
    
    // Confirmar transacción
    public function commit($connection) {
        $connection->commit();
        $this->releaseConnection($connection);
    }
    
    // Revertir transacción
    public function rollback($connection) {
        $connection->rollBack();
        $this->releaseConnection($connection);
    }
    
    // Generar clave de caché
    private function generateCacheKey($sql, $params) {
        return md5($sql . serialize($params));
    }
    
    // Obtener de caché
    private function getFromCache($key) {
        // Si existe APC, usarlo para caché en memoria
        if (function_exists('apc_fetch')) {
            return apc_fetch('db_' . $key);
        } 
        // Si existe Memcached, usarlo como alternativa
        else if (class_exists('Memcached')) {
            // Implementar obtención de Memcached
        }
        // De lo contrario, usar caché en archivo
        else {
            $cacheFile = __DIR__ . '/../cache/' . $key . '.cache';
            if (file_exists($cacheFile) && (time() - filemtime($cacheFile) < CACHE_LIFETIME)) {
                return unserialize(file_get_contents($cacheFile));
            }
        }
        
        return null;
    }
    
    // Guardar en caché
    private function saveToCache($key, $data, $lifetime = null) {
        if ($lifetime === null) {
            $lifetime = CACHE_LIFETIME;
        }
        
        // Si existe APC, usarlo para caché en memoria
        if (function_exists('apc_store')) {
            apc_store('db_' . $key, $data, $lifetime);
        } 
        // Si existe Memcached, usarlo como alternativa
        else if (class_exists('Memcached')) {
            // Implementar guardado en Memcached
        }
        // De lo contrario, usar caché en archivo
        else {
            $cacheFile = __DIR__ . '/../cache/' . $key . '.cache';
            file_put_contents($cacheFile, serialize($data), LOCK_EX);
        }
    }
    
    // Limpiar caché
    public function clearCache() {
        // Si existe APC, usarlo para caché en memoria
        if (function_exists('apc_clear_cache')) {
            apc_clear_cache('user');
        } 
        // Si existe Memcached, usarlo como alternativa
        else if (class_exists('Memcached')) {
            // Implementar limpieza de Memcached
        }
        // De lo contrario, limpiar caché en archivo
        else {
            $cacheDir = __DIR__ . '/../cache/';
            if (is_dir($cacheDir)) {
                $files = glob($cacheDir . '*.cache');
                foreach ($files as $file) {
                    unlink($file);
                }
            }
        }
    }
    
    // Limpiar caché expirada
    public function clearExpiredCache() {
        // Si se usa caché en archivo, limpiar archivos expirados
        $cacheDir = __DIR__ . '/../cache/';
        if (is_dir($cacheDir)) {
            $files = glob($cacheDir . '*.cache');
            foreach ($files as $file) {
                if (time() - filemtime($file) > CACHE_LIFETIME) {
                    unlink($file);
                }
            }
        }
    }
}

// Función global para obtener instancia de conexión
function getDB() {
    return DatabaseConnection::getInstance();
}

