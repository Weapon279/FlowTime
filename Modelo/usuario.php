<?php
/**
 * Modelo de Usuario
 * 
 * Gestiona las operaciones relacionadas con los usuarios
 */

// Prevenir acceso directo al archivo
if (!defined('ACCESO_PERMITIDO')) {
    header('HTTP/1.0 403 Forbidden');
    exit;
}

class Usuario {
    private $db;
    
    /**
     * Constructor
     */
    public function __construct() {
        $this->db = getDbConnection();
    }
    
    /**
     * Obtiene un usuario por su ID
     * 
     * @param int $id ID del usuario
     * @return array|false Datos del usuario o false si no existe
     */
    public function obtenerPorId($id) {
        // Usar caché para mejorar rendimiento
        $clave = "usuario_id_$id";
        $usuario = obtenerCache($clave);
        
        if ($usuario !== null) {
            return $usuario;
        }
        
        $stmt = $this->db->prepare("
            SELECT id, nombre, apellido, email, tipo_cuenta, fecha_registro, ultimo_login, activo
            FROM usuarios
            WHERE id = :id
        ");
        
        $stmt->execute([':id' => $id]);
        $usuario = $stmt->fetch();
        
        if ($usuario) {
            // Guardar en caché por 5 minutos
            guardarCache($clave, $usuario, 300);
        }
        
        return $usuario;
    }
    
    /**
     * Obtiene un usuario por su email
     * 
     * @param string $email Email del usuario
     * @return array|false Datos del usuario o false si no existe
     */
    public function obtenerPorEmail($email) {
        $stmt = $this->db->prepare("
            SELECT id, nombre, apellido, email, password, tipo_cuenta, fecha_registro, ultimo_login, activo
            FROM usuarios
            WHERE email = :email
        ");
        
        $stmt->execute([':email' => $email]);
        return $stmt->fetch();
    }
    
    /**
     * Crea un nuevo usuario
     * 
     * @param array $datos Datos del usuario
     * @return int|false ID del usuario creado o false si falla
     */
    public function crear($datos) {
        $stmt = $this->db->prepare("
            INSERT INTO usuarios (nombre, apellido, email, password, tipo_cuenta)
            VALUES (:nombre, :apellido, :email, :password, :tipo_cuenta)
        ");
        
        $resultado = $stmt->execute([
            ':nombre' => $datos['nombre'],
            ':apellido' => $datos['apellido'],
            ':email' => $datos['email'],
            ':password' => hashPassword($datos['password']),
            ':tipo_cuenta' => isset($datos['tipo_cuenta']) ? $datos['tipo_cuenta'] : CUENTA_GRATUITA
        ]);
        
        if ($resultado) {
            return $this->db->lastInsertId();
        }
        
        return false;
    }
    
    /**
     * Actualiza un usuario
     * 
     * @param int $id ID del usuario
     * @param array $datos Datos a actualizar
     * @return bool True si se actualizó correctamente, false en caso contrario
     */
    public function actualizar($id, $datos) {
        // Construir consulta dinámica según los campos a actualizar
        $campos = [];
        $parametros = [':id' => $id];
        
        foreach ($datos as $campo => $valor) {
            // No permitir actualizar campos sensibles directamente
            if (in_array($campo, ['id', 'fecha_registro', 'ultimo_login'])) {
                continue;
            }
            
            // Manejar caso especial para password
            if ($campo === 'password') {
                $valor = hashPassword($valor);
            }
            
            $campos[] = "$campo = :$campo";
            $parametros[":$campo"] = $valor;
        }
        
        if (empty($campos)) {
            return false;
        }
        
        $sql = "UPDATE usuarios SET " . implode(', ', $campos) . " WHERE id = :id";
        $stmt = $this->db->prepare($sql);
        $resultado = $stmt->execute($parametros);
        
        if ($resultado) {
            // Invalidar caché
            eliminarCache("usuario_id_$id");
        }
        
        return $resultado;
    }
    
    /**
     * Elimina un usuario
     * 
     * @param int $id ID del usuario
     * @return bool True si se eliminó correctamente, false en caso contrario
     */
    public function eliminar($id) {
        $stmt = $this->db->prepare("DELETE FROM usuarios WHERE id = :id");
        $resultado = $stmt->execute([':id' => $id]);
        
        if ($resultado) {
            // Invalidar caché
            eliminarCache("usuario_id_$id");
        }
        
        return $resultado;
    }
    
    /**
     * Verifica las credenciales de un usuario
     * 
     * @param string $email Email del usuario
     * @param string $password Contraseña del usuario
     * @return array|false Datos del usuario o false si las credenciales son incorrectas
     */
    public function verificarCredenciales($email, $password) {
        $usuario = $this->obtenerPorEmail($email);
        
        if (!$usuario) {
            return false;
        }
        
        // Verificar si la cuenta está activa
        if (!$usuario['activo']) {
            return false;
        }
        
        // Verificar contraseña
        if (!verificarPassword($password, $usuario['password'])) {
            return false;
        }
        
        // No devolver la contraseña
        unset($usuario['password']);
        
        return $usuario;
    }
    
    /**
     * Actualiza la contraseña de un usuario
     * 
     * @param int $id ID del usuario
     * @param string $password Nueva contraseña
     * @return bool True si se actualizó correctamente, false en caso contrario
     */
    public function actualizarPassword($id, $password) {
        $stmt = $this->db->prepare("
            UPDATE usuarios
            SET password = :password
            WHERE id = :id
        ");
        
        return $stmt->execute([
            ':id' => $id,
            ':password' => hashPassword($password)
        ]);
    }
    
    /**
     * Genera un token de recuperación de contraseña
     * 
     * @param string $email Email del usuario
     * @return string|false Token generado o false si falla
     */
    public function generarTokenRecuperacion($email) {
        $usuario = $this->obtenerPorEmail($email);
        
        if (!$usuario) {
            return false;
        }
        
        $token = generarToken();
        $expiracion = date('Y-m-d H:i:s', time() + TOKEN_EXPIRY);
        
        $stmt = $this->db->prepare("
            UPDATE usuarios
            SET token_recuperacion = :token, expiracion_token = :expiracion
            WHERE id = :id
        ");
        
        $resultado = $stmt->execute([
            ':id' => $usuario['id'],
            ':token' => $token,
            ':expiracion' => $expiracion
        ]);
        
        if ($resultado) {
            return $token;
        }
        
        return false;
    }
    
    /**
     * Verifica un token de recuperación de contraseña
     * 
     * @param string $token Token a verificar
     * @return array|false Datos del usuario o false si el token es inválido
     */
    public function verificarTokenRecuperacion($token) {
        $stmt = $this->db->prepare("
            SELECT id, nombre, apellido, email
            FROM usuarios
            WHERE token_recuperacion = :token
            AND expiracion_token > NOW()
            AND activo = 1
        ");
        
        $stmt->execute([':token' => $token]);
        return $stmt->fetch();
    }
    
    /**
     * Restablece la contraseña de un usuario usando un token
     * 
     * @param string $token Token de recuperación
     * @param string $password Nueva contraseña
     * @return bool True si se restableció correctamente, false en caso contrario
     */
    public function restablecerPassword($token, $password) {
        $usuario = $this->verificarTokenRecuperacion($token);
        
        if (!$usuario) {
            return false;
        }
        
        $stmt = $this->db->prepare("
            UPDATE usuarios
            SET password = :password, token_recuperacion = NULL, expiracion_token = NULL
            WHERE id = :id
        ");
        
        return $stmt->execute([
            ':id' => $usuario['id'],
            ':password' => hashPassword($password)
        ]);
    }
    
    /**
     * Actualiza a cuenta premium
     * 
     * @param int $id ID del usuario
     * @return bool True si se actualizó correctamente, false en caso contrario
     */
    public function actualizarAPremium($id) {
        $stmt = $this->db->prepare("
            UPDATE usuarios
            SET tipo_cuenta = :tipo_cuenta
            WHERE id = :id
        ");
        
        $resultado = $stmt->execute([
            ':id' => $id,
            ':tipo_cuenta' => CUENTA_PREMIUM
        ]);
        
        if ($resultado) {
            // Invalidar caché
            eliminarCache("usuario_id_$id");
        }
        
        return $resultado;
    }
    
    /**
     * Actualiza a cuenta gratuita
     * 
     * @param int $id ID del usuario
     * @return bool True si se actualizó correctamente, false en caso contrario
     */
    public function actualizarAGratuita($id) {
        $stmt = $this->db->prepare("
            UPDATE usuarios
            SET tipo_cuenta = :tipo_cuenta
            WHERE id = :id
        ");
        
        $resultado = $stmt->execute([
            ':id' => $id,
            ':tipo_cuenta' => CUENTA_GRATUITA
        ]);
        
        if ($resultado) {
            // Invalidar caché
            eliminarCache("usuario_id_$id");
        }
        
        return $resultado;
    }
    
    /**
     * Verifica si un email ya está registrado
     * 
     * @param string $email Email a verificar
     * @return bool True si ya está registrado, false en caso contrario
     */
    public function emailExiste($email) {
        $stmt = $this->db->prepare("
            SELECT COUNT(*) as total
            FROM usuarios
            WHERE email = :email
        ");
        
        $stmt->execute([':email' => $email]);
        $resultado = $stmt->fetch();
        
        return $resultado['total'] > 0;
    }
    
    /**
     * Obtiene estadísticas de usuarios
     * 
     * @return array Estadísticas de usuarios
     */
    public function obtenerEstadisticas() {
        // Usar caché para mejorar rendimiento
        $clave = "estadisticas_usuarios";
        $estadisticas = obtenerCache($clave);
        
        if ($estadisticas !== null) {
            return $estadisticas;
        }
        
        $stmt = $this->db->prepare("
            SELECT
                COUNT(*) as total_usuarios,
                SUM(CASE WHEN tipo_cuenta = 'premium' THEN 1 ELSE 0 END) as usuarios_premium,
                SUM(CASE WHEN tipo_cuenta = 'gratuito' THEN 1 ELSE 0 END) as usuarios_gratuitos,
                SUM(CASE WHEN DATE(fecha_registro) = CURDATE() THEN 1 ELSE 0 END) as registros_hoy,
                SUM(CASE WHEN DATE(fecha_registro) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) as registros_semana,
                SUM(CASE WHEN DATE(fecha_registro) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) THEN 1 ELSE 0 END) as registros_mes
            FROM usuarios
        ");
        
        $stmt->execute();
        $estadisticas = $stmt->fetch();
        
        // Guardar en caché por 1 hora
        guardarCache($clave, $estadisticas, 3600);
        
        return $estadisticas;
    }
}