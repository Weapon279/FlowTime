<?php
// Definir constante para permitir acceso a los archivos incluidos
define('ACCESO_PERMITIDO', true);

// Incluir archivos necesarios
require_once 'config/config.php';
require_once 'includes/conexion.php';
require_once 'includes/session.php';
require_once 'includes/security.php';
require_once 'includes/functions-compat.php'; // Nuevo archivo de compatibilidad

// Iniciar sesión segura
iniciarSesionSegura();

// Verificar si el usuario ya está autenticado
if (estaAutenticado()) {
    // Redirigir al dashboard
    header('Location: dashboard.php');
    exit;
}

// Procesar formulario de login
$error_login = '';
$error_registro = '';
$exito_registro = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Verificar token CSRF
    if (!verificarCSRF()) {
        setMensajeFlash('error', 'Error de seguridad. Por favor, inténtalo de nuevo.');
        header('Location: login.php');
        exit;
    }

    // Verificar si es login o registro
    if (isset($_POST['action'])) {
        if ($_POST['action'] === 'login') {
            // Procesar login
            $email = isset($_POST['email']) ? trim($_POST['email']) : '';
            $password = isset($_POST['password']) ? $_POST['password'] : '';
            $recordar = isset($_POST['remember']) ? true : false;

            // Validar campos
            if (empty($email) || empty($password)) {
                $error_login = 'Por favor, completa todos los campos.';
            } elseif (!validarEmail($email)) {
                $error_login = 'Por favor, ingresa un email válido.';
            } else {
                // Verificar si el usuario está bloqueado por intentos fallidos
                $ip = obtenerIP();
                if (estaBloqueado($ip, 'login_fallido')) {
                    $error_login = 'Has excedido el número máximo de intentos. Por favor, inténtalo más tarde.';
                } else {
                    // Obtener usuario por email
                    $db = getDB();
                    $sql = "SELECT * FROM usuarios WHERE email = :email AND estado = 'activo'";
                    $params = [':email' => $email];
                    $usuario = $db->query($sql, $params, 0);

                    if (empty($usuario)) {
                        // Registrar intento fallido
                        registrarIntento($ip, 'login_fallido', null, $email);
                        $error_login = 'Credenciales incorrectas. Por favor, verifica tus datos.';
                    } else {
                        $usuario = $usuario[0];
                        
                        // Verificar contraseña
                        if (password_verify($password, $usuario['password'])) {
                            // Login exitoso
                            $_SESSION['usuario_id'] = $usuario['id'];
                            $_SESSION['nombre'] = $usuario['nombre'];
                            $_SESSION['apellido'] = $usuario['apellido'];
                            $_SESSION['email'] = $usuario['email'];
                            $_SESSION['tipo_cuenta'] = $usuario['tipo_cuenta'] ?? 'gratuito';
                            $_SESSION['tema'] = $usuario['tema'] ?? 'claro';
                            
                            // Actualizar último acceso
                            $sql = "UPDATE usuarios SET ultimo_acceso = NOW() WHERE id = :id";
                            $params = [':id' => $usuario['id']];
                            $db->execute($sql, $params);
                            
                            // Registrar login exitoso
                            registrarIntento($ip, 'login_exitoso', $usuario['id'], $email);
                            
                            // Si hay URL de redirección guardada, redirigir a ella
                            if (isset($_SESSION['url_redireccion'])) {
                                $url_redireccion = $_SESSION['url_redireccion'];
                                unset($_SESSION['url_redireccion']);
                                header('Location: ' . $url_redireccion);
                            } else {
                                // Redirigir al dashboard
                                header('Location: dashboard.php');
                            }
                            exit;
                        } else {
                            // Contraseña incorrecta
                            registrarIntento($ip, 'login_fallido', null, $email);
                            $error_login = 'Credenciales incorrectas. Por favor, verifica tus datos.';
                        }
                    }
                }
            }
        } elseif ($_POST['action'] === 'register') {
            // Procesar registro
            $nombre = isset($_POST['nombre']) ? trim($_POST['nombre']) : '';
            $apellido = isset($_POST['apellido']) ? trim($_POST['apellido']) : '';
            $email = isset($_POST['email']) ? trim($_POST['email']) : '';
            $password = isset($_POST['password']) ? $_POST['password'] : '';
            $confirm_password = isset($_POST['confirm_password']) ? $_POST['confirm_password'] : '';
            $terminos = isset($_POST['terminos']) ? true : false;
            
            // Validar campos
            if (empty($nombre) || empty($apellido) || empty($email) || empty($password) || empty($confirm_password)) {
                $error_registro = 'Por favor, completa todos los campos.';
            } elseif (!validarEmail($email)) {
                $error_registro = 'Por favor, ingresa un email válido.';
            } elseif ($password !== $confirm_password) {
                $error_registro = 'Las contraseñas no coinciden.';
            } elseif (!$terminos) {
                $error_registro = 'Debes aceptar los términos y condiciones.';
            } else {
                // Verificar fortaleza de la contraseña
                $verificacion = verificarFortalezaPassword($password);
                if (!$verificacion['valida']) {
                    $error_registro = $verificacion['mensaje'];
                } else {
                    // Verificar si el email ya está registrado
                    $db = getDB();
                    $sql = "SELECT COUNT(*) as total FROM usuarios WHERE email = :email";
                    $params = [':email' => $email];
                    $result = $db->query($sql, $params, 0);
                    
                    if ($result[0]['total'] > 0) {
                        $error_registro = 'El email ya está registrado. Por favor, utiliza otro o recupera tu contraseña.';
                    } else {
                        // Crear usuario
                        try {
                            // Hashear contraseña
                            $password_hash = password_hash($password, PASSWORD_DEFAULT);
                            
                            // Insertar directamente en la tabla usuarios en lugar de usar el procedimiento almacenado
                            $db = getDB();
                            $sql = "INSERT INTO usuarios (nombre, apellido, email, password, estado, fecha_registro) 
                                    VALUES (:nombre, :apellido, :email, :password, 'activo', NOW())";
                            $params = [
                                ':nombre' => $nombre,
                                ':apellido' => $apellido,
                                ':email' => $email,
                                ':password' => $password_hash
                            ];
                            
                            $result = $db->execute($sql, $params);
                            
                            if ($result['success']) {
                                $usuario_id = $result['lastInsertId'];
                                
                                // Registrar registro exitoso
                                $ip = obtenerIP();
                                registrarIntento($ip, 'registro', $usuario_id, $email);
                                
                                // Mostrar mensaje de éxito
                                $exito_registro = 'Registro exitoso. Ahora puedes iniciar sesión con tus credenciales.';
                                
                                // Limpiar campos del formulario
                                $nombre = $apellido = $email = '';
                            } else {
                                $error_registro = 'Error al crear el usuario. No se pudo completar la inserción.';
                                error_log('Error al crear usuario: No se pudo completar la inserción');
                            }
                        } catch (Exception $e) {
                            $error_registro = 'Error al crear el usuario: ' . $e->getMessage();
                            error_log('Error al crear usuario: ' . $e->getMessage());
                        }
                    }
                }
            }
        }
    }
}

// Generar token CSRF
$csrf_token = generarTokenCSRF();
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TimeFlow - Iniciar Sesión</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="assets/css/login.css">
    <script src="https://accounts.google.com/gsi/client" async defer></script>
    <link rel="stylesheet" href="assets/css/carga.css">
</head>
<body>
    <!-- Pantalla de carga modular -->
    <div class="loader-container" id="pageLoader">
        <div class="loader-content">
            <div class="clock-loader">
                <div class="clock-face">
                    <div class="clock-center"></div>
                    <div class="clock-hour"></div>
                    <div class="clock-minute"></div>
                    <div class="clock-second"></div>
                    <div class="clock-marking marking-12"></div>
                    <div class="clock-marking marking-3"></div>
                    <div class="clock-marking marking-6"></div>
                    <div class="clock-marking marking-9"></div>
                </div>
            </div>
            <div class="loader-text">
                <h2>Cargando...</h2>
                <div class="quote-container">
                    <p id="quoteText" class="quote-text"></p>
                    <p id="quoteAuthor" class="quote-author"></p>
                </div>
            </div>
        </div>
    </div>

    <div class="container">
        <div class="forms-container">
            <div class="signin-signup">
                <!-- Formulario de Login -->
                <form action="login.php" method="POST" class="sign-in-form" id="login-form">
                    <input type="hidden" name="action" value="login">
                    <input type="hidden" name="csrf_token" value="<?php echo $csrf_token; ?>">
                    
                    <div class="logo-container">
                        <div class="logo">
                            <i class="fas fa-clock"></i>
                        </div>
                        <h2 class="logo-text">FlowTime</h2>
                    </div>
                    
                    <!-- Botón para regresar al index -->
                    <a href="index.html" class="back-to-home">
                        <i class="fas fa-home"></i>
                        <span>Volver al inicio</span>
                    </a>

                    <h2 class="title">Iniciar Sesión</h2>
                    
                    <?php if (!empty($error_login)): ?>
                    <div class="error-message">
                        <i class="fas fa-exclamation-circle"></i>
                        <?php echo sanitizar($error_login); ?>
                    </div>
                    <?php endif; ?>
                    
                    <!-- Botones de inicio de sesión con Google -->
                    <div class="social-media">
                        <p class="social-text">Iniciar sesión con</p>
                        <div id="google-signin-button"></div>
                    </div>
                    
                    <div class="separator">
                        <span>o</span>
                    </div>
                    
                    <div class="input-field">
                        <i class="fas fa-user"></i>
                        <input type="email" name="email" placeholder="Correo Electrónico" id="login-email" required value="<?php echo isset($email) ? sanitizar($email) : ''; ?>">
                    </div>
                    <div class="input-field">
                        <i class="fas fa-lock"></i>
                        <input type="password" name="password" placeholder="Contraseña" id="login-password" required>
                    </div>
                    
                    <div class="remember-forgot">
                        <div class="remember-me">
                            <input type="checkbox" name="remember" id="remember-me">
                            <label for="remember-me">Recordarme</label>
                        </div>
                        <a href="recuperar-password.php" class="forgot-password">¿Olvidaste tu contraseña?</a>
                    </div>
                    
                    <input type="submit" value="Iniciar Sesión" class="btn solid">
                </form>

                <!-- Formulario de Registro (Diseño Horizontal) -->
                <form action="login.php" method="POST" class="sign-up-form" id="register-form">
                    <input type="hidden" name="action" value="register">
                    <input type="hidden" name="csrf_token" value="<?php echo $csrf_token; ?>">
                    
                    <div class="logo-container">
                        <div class="logo">
                            <i class="fas fa-clock"></i>
                        </div>
                        <h2 class="logo-text">FlowTime</h2>
                    </div>
                    
                    <h2 class="title">Registrarse</h2>
                    
                    <?php if (!empty($error_registro)): ?>
                    <div class="error-message">
                        <i class="fas fa-exclamation-circle"></i>
                        <?php echo sanitizar($error_registro); ?>
                    </div>
                    <?php endif; ?>
                    
                    <?php if (!empty($exito_registro)): ?>
                    <div class="success-message">
                        <i class="fas fa-check-circle"></i>
                        <?php echo sanitizar($exito_registro); ?>
                    </div>
                    <?php endif; ?>
                    
                    <!-- Botones de registro con Google -->
                    <div class="social-media">
                        <p class="social-text">Registrarse con</p>
                        <div id="google-signup-button"></div>
                    </div>
                    
                    <div class="separator">
                        <span>o</span>
                    </div>
                    
                    <!-- Formulario en estructura de grid 2x2 -->
                    <div class="form-grid">
                        <div class="grid-item">
                            <div class="input-field">
                                <i class="fas fa-user"></i>
                                <input type="text" name="nombre" placeholder="Nombre" id="register-name" required value="<?php echo isset($nombre) ? sanitizar($nombre) : ''; ?>">
                            </div>
                        </div>
                        <div class="grid-item">
                            <div class="input-field">
                                <i class="fas fa-user"></i>
                                <input type="text" name="apellido" placeholder="Apellido" id="register-lastname" required value="<?php echo isset($apellido) ? sanitizar($apellido) : ''; ?>">
                            </div>
                        </div>
                        <div class="grid-item">
                            <div class="input-field">
                                <i class="fas fa-envelope"></i>
                                <input type="email" name="email" placeholder="Correo Electrónico" id="register-email" required value="<?php echo isset($email) ? sanitizar($email) : ''; ?>">
                            </div>
                        </div>
                        <div class="grid-item">
                            <div class="input-field">
                                <i class="fas fa-lock"></i>
                                <input type="password" name="password" placeholder="Contraseña" id="register-password" required>
                            </div>
                        </div>
                        <div class="grid-item">
                            <div class="input-field">
                                <i class="fas fa-lock"></i>
                                <input type="password" name="confirm_password" placeholder="Confirmar Contraseña" id="register-confirm-password" required>
                            </div>
                        </div>
                        <div class="grid-item">
                            <div class="terms-container">
                                <input type="checkbox" name="terminos" id="terms" required>
                                <label for="terms">Acepto los <a href="terminos.php">Términos y Condiciones</a></label>
                            </div>
                        </div>
                    </div>
                    
                    <input type="submit" value="Registrarse" class="btn solid">
                </form>
            </div>
        </div>

        <div class="panels-container">
            <div class="panel left-panel">
                <div class="content">
                    <h3>¿Eres nuevo aquí?</h3>
                    <p>Regístrate y comienza a gestionar tu tiempo de manera eficiente con FlowTime.</p>
                    <button class="btn transparent" id="sign-up-btn">Registrarse</button>
                </div>
                <img src="img/login-illustration.svg" class="image" alt="Ilustración de login">
            </div>

            <div class="panel right-panel">
                <div class="content">
                    <h3>¿Ya tienes una cuenta?</h3>
                    <p>Inicia sesión para continuar gestionando tu tiempo y aumentando tu productividad.</p>
                    <button class="btn transparent" id="sign-in-btn">Iniciar Sesión</button>
                </div>
                <img src="img/register-illustration.svg" class="image" alt="Ilustración de registro">
            </div>
        </div>
    </div>

    <div class="notification" id="notification">
        <div class="notification-content">
            <i class="notification-icon"></i>
            <p class="notification-message"></p>
        </div>
        <span class="notification-progress"></span>
    </div>

    <script src="assets/js/login.js"></script>
    <script src="assets/js/carga.js"></script>
</body>
</html>

