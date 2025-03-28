<?php
/**
 * Controlador de Autenticación
 * 
 * Gestiona las operaciones de autenticación y registro de usuarios
 */

// Prevenir acceso directo al archivo
if (!defined('ACCESO_PERMITIDO')) {
    header('HTTP/1.0 403 Forbidden');
    exit;
}

class AuthController {
    private $usuarioModel;
    
    /**
     * Constructor
     */
    public function __construct() {
        $this->usuarioModel = new Usuario();
    }
    
    /**
     * Procesa el inicio de sesión
     * 
     * @param array $datos Datos del formulario
     * @return array Resultado del proceso
     */
    public function login($datos) {
        // Validar datos
        $errores = validarFormulario($datos, [
            'email' => ['required', 'email'],
            'password' => ['required']
        ]);
        
        if (!empty($errores)) {
            return [
                'exito' => false,
                'errores' => $errores
            ];
        }
        
        $email = $datos['email'];
        $password = $datos['password'];
        
        // Verificar si el usuario ha excedido los intentos de inicio de sesión
        if (haExcedidoIntentosLogin($email)) {
            return [
                'exito' => false,
                'mensaje' => 'Has excedido el número máximo de intentos de inicio de sesión. Por favor, inténtalo de nuevo más tarde.'
            ];
        }
        
        // Verificar credenciales
        $usuario = $this->usuarioModel->verificarCredenciales($email, $password);
        
        if (!$usuario) {
            // Registrar intento fallido
            registrarIntentoLogin($email, false);
            
            return [
                'exito' => false,
                'mensaje' => ERROR_LOGIN
            ];
        }
        
        // Iniciar sesión
        iniciarSesion($usuario);
        
        // Registrar intento exitoso
        registrarIntentoLogin($email, true, $usuario['id']);
        
        return [
            'exito' => true,
            'mensaje' => EXITO_LOGIN,
            'usuario' => $usuario
        ];
    }
    
    /**
     * Procesa el registro de un nuevo usuario
     * 
     * @param array $datos Datos del formulario
     * @return array Resultado del proceso
     */
    public function registro($datos) {
        // Validar datos
        $errores = validarFormulario($datos, [
            'nombre' => ['required', ['min', 2], ['max', 50]],
            'apellido' => ['required', ['min', 2], ['max', 50]],
            'email' => ['required', 'email', ['unique', 'usuarios', 'email']],
            'password' => ['required', ['min', 8]],
            'confirm_password' => ['required', ['same', 'password']]
        ]);
        
        // Validar contraseña
        $erroresPassword = validarPassword($datos['password']);
        if (!empty($erroresPassword)) {
            $errores['password'] = $erroresPassword;
        }
        
        if (!empty($errores)) {
            return [
                'exito' => false,
                'errores' => $errores
            ];
        }
        
        // Crear usuario
        $idUsuario = $this->usuarioModel->crear([
            'nombre' => $datos['nombre'],
            'apellido' => $datos['apellido'],
            'email' => $datos['email'],
            'password' => $datos['password']
        ]);
        
        if (!$idUsuario) {
            return [
                'exito' => false,
                'mensaje' => ERROR_REGISTRO
            ];
        }
        
        // Obtener usuario creado
        $usuario = $this->usuarioModel->obtenerPorId($idUsuario);
        
        // Iniciar sesión automáticamente
        iniciarSesion($usuario);
        
        // Enviar correo de bienvenida
        $this->enviarCorreoBienvenida($usuario);
        
        return [
            'exito' => true,
            'mensaje' => EXITO_REGISTRO,
            'usuario' => $usuario
        ];
    }
    
    /**
     * Cierra la sesión del usuario
     * 
     * @return array Resultado del proceso
     */
    public function logout() {
        cerrarSesion();
        
        return [
            'exito' => true,
            'mensaje' => EXITO_LOGOUT
        ];
    }
    
    /**
     * Procesa la solicitud de recuperación de contraseña
     * 
     * @param array $datos Datos del formulario
     * @return array Resultado del proceso
     */
    public function recuperarPassword($datos) {
        // Validar datos
        $errores = validarFormulario($datos, [
            'email' => ['required', 'email', ['exists', 'usuarios', 'email']]
        ]);
        
        if (!empty($errores)) {
            return [
                'exito' => false,
                'errores' => $errores
            ];
        }
        
        $email = $datos['email'];
        
        // Generar token de recuperación
        $token = $this->usuarioModel->generarTokenRecuperacion($email);
        
        if (!$token) {
            return [
                'exito' => false,
                'mensaje' => 'No se pudo generar el token de recuperación. Inténtalo de nuevo más tarde.'
            ];
        }
        
        // Obtener usuario
        $usuario = $this->usuarioModel->obtenerPorEmail($email);
        
        // Enviar correo con enlace de recuperación
        $this->enviarCorreoRecuperacion($usuario, $token);
        
        return [
            'exito' => true,
            'mensaje' => 'Se ha enviado un correo con instrucciones para recuperar tu contraseña.'
        ];
    }
    
    /**
     * Verifica un token de recuperación de contraseña
     * 
     * @param string $token Token a verificar
     * @return array Resultado del proceso
     */
    public function verificarToken($token) {
        $usuario = $this->usuarioModel->verificarTokenRecuperacion($token);
        
        if (!$usuario) {
            return [
                'exito' => false,
                'mensaje' => 'El enlace de recuperación no es válido o ha expirado.'
            ];
        }
        
        return [
            'exito' => true,
            'usuario' => $usuario
        ];
    }
    
    /**
     * Restablece la contraseña de un usuario
     * 
     * @param array $datos Datos del formulario
     * @return array Resultado del proceso
     */
    public function restablecerPassword($datos) {
        // Validar datos
        $errores = validarFormulario($datos, [
            'token' => ['required'],
            'password' => ['required', ['min', 8]],
            'confirm_password' => ['required', ['same', 'password']]
        ]);
        
        // Validar contraseña
        $erroresPassword = validarPassword($datos['password']);
        if (!empty($erroresPassword)) {
            $errores['password'] = $erroresPassword;
        }
        
        if (!empty($errores)) {
            return [
                'exito' => false,
                'errores' => $errores
            ];
        }
        
        $token = $datos['token'];
        $password = $datos['password'];
        
        // Verificar token
        $usuario = $this->usuarioModel->verificarTokenRecuperacion($token);
        
        if (!$usuario) {
            return [
                'exito' => false,
                'mensaje' => 'El enlace de recuperación no es válido o ha expirado.'
            ];
        }
        
        // Restablecer contraseña
        $resultado = $this->usuarioModel->restablecerPassword($token, $password);
        
        if (!$resultado) {
            return [
                'exito' => false,
                'mensaje' => 'No se pudo restablecer la contraseña. Inténtalo de nuevo más tarde.'
            ];
        }
        
        return [
            'exito' => true,
            'mensaje' => 'Tu contraseña ha sido restablecida correctamente. Ya puedes iniciar sesión.'
        ];
    }
    
    /**
     * Envía un correo de bienvenida
     * 
     * @param array $usuario Datos del usuario
     * @return bool True si se envió correctamente, false en caso contrario
     */
    private function enviarCorreoBienvenida($usuario) {
        $asunto = 'Bienvenido a ' . APP_NAME;
        
        $mensaje = '
            <html>
            <head>
                <title>Bienvenido a ' . APP_NAME . '</title>
            </head>
            <body>
                <h1>¡Bienvenido a ' . APP_NAME . ', ' . $usuario['nombre'] . '!</h1>
                <p>Gracias por registrarte en nuestra plataforma. Estamos emocionados de tenerte con nosotros.</p>
                <p>Con ' . APP_NAME . ' podrás gestionar tu tiempo de manera eficiente y aumentar tu productividad.</p>
                <p>Si tienes alguna pregunta, no dudes en contactarnos.</p>
                <p>Saludos,<br>El equipo de ' . APP_NAME . '</p>
            </body>
            </html>
        ';
        
        return enviarEmail($usuario['email'], $asunto, $mensaje);
    }
    
    /**
     * Envía un correo de recuperación de contraseña
     * 
     * @param array $usuario Datos del usuario
     * @param string $token Token de recuperación
     * @return bool True si se envió correctamente, false en caso contrario
     */
    private function enviarCorreoRecuperacion($usuario, $token) {
        $asunto = 'Recuperación de contraseña - ' . APP_NAME;
        
        $enlace = APP_URL . '/reset-password.php?token=' . $token;
        
        $mensaje = '
            <html>
            <head>
                <title>Recuperación de contraseña - ' . APP_NAME . '</title>
            </head>
            <body>
                <h1>Recuperación de contraseña</h1>
                <p>Hola ' . $usuario['nombre'] . ',</p>
                <p>Has solicitado restablecer tu contraseña. Haz clic en el siguiente enlace para crear una nueva contraseña:</p>
                <p><a href="' . $enlace . '">' . $enlace . '</a></p>
                <p>Este enlace expirará en ' . (TOKEN_EXPIRY / 60) . ' minutos.</p>
                <p>Si no has solicitado restablecer tu contraseña, puedes ignorar este correo.</p>
                <p>Saludos,<br>El equipo de ' . APP_NAME . '</p>
            </body>
            </html>
        ';
        
        return enviarEmail($usuario['email'], $asunto, $mensaje);
    }
}