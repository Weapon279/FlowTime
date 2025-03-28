<?php
/**
 * API de Autenticación
 * 
 * Endpoints para autenticación y registro de usuarios
 */

// Definir constante para permitir acceso a los archivos incluidos
define('ACCESO_PERMITIDO', true);

// Incluir archivos necesarios
require_once '../config/config.php';
require_once '../config/database.php';
require_once '../config/constants.php';
require_once '../includes/functions.php';
require_once '../includes/auth.php';
require_once '../includes/session.php';
require_once '../includes/validation.php';
require_once '../includes/cache.php';
require_once '../models/Usuario.php';
require_once '../controllers/AuthController.php';

// Iniciar sesión segura
iniciarSesionSegura();

// Configurar cabeceras
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: ' . APP_URL);
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Access-Control-Allow-Credentials: true');

// Manejar solicitudes OPTIONS (CORS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

// Crear instancia del controlador
$authController = new AuthController();

// Obtener acción
$accion = isset($_GET['accion']) ? $_GET['accion'] : '';

// Procesar según la acción
switch ($accion) {
    case 'login':
        // Verificar método
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405); // Method Not Allowed
            echo json_encode(['error' => 'Método no permitido']);
            exit;
        }
        
        // Obtener datos
        $datos = json_decode(file_get_contents('php://input'), true);
        
        // Si no hay datos, intentar obtener de POST
        if (!$datos) {
            $datos = $_POST;
        }
        
        // Procesar login
        $resultado = $authController->login($datos);
        
        // Devolver respuesta
        echo json_encode($resultado);
        break;
    
    case 'registro':
        // Verificar método
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405); // Method Not Allowed
            echo json_encode(['error' => 'Método no permitido']);
            exit;
        }
        
        // Obtener datos
        $datos = json_decode(file_get_contents('php://input'), true);
        
        // Si no hay datos, intentar obtener de POST
        if (!$datos) {
            $datos = $_POST;
        }
        
        // Procesar registro
        $resultado = $authController->registro($datos);
        
        // Devolver respuesta
        echo json_encode($resultado);
        break;
    
    case 'logout':
        // Verificar método
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405); // Method Not Allowed
            echo json_encode(['error' => 'Método no permitido']);
            exit;
        }
        
        // Procesar logout
        $resultado = $authController->logout();
        
        // Devolver respuesta
        echo json_encode($resultado);
        break;
    
    case 'recuperar-password':
        // Verificar método
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405); // Method Not Allowed
            echo json_encode(['error' => 'Método no permitido']);
            exit;
        }
        
        // Obtener datos
        $datos = json_decode(file_get_contents('php://input'), true);
        
        // Si no hay datos, intentar obtener de POST
        if (!$datos) {
            $datos = $_POST;
        }
        
        // Procesar recuperación
        $resultado = $authController->recuperarPassword($datos);
        
        // Devolver respuesta
        echo json_encode($resultado);
        break;
    
    case 'verificar-token':
        // Verificar método
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405); // Method Not Allowed
            echo json_encode(['error' => 'Método no permitido']);
            exit;
        }
        
        // Obtener token
        $token = isset($_GET['token']) ? $_GET['token'] : '';
        
        // Verificar token
        $resultado = $authController->verificarToken($token);
        
        // Devolver respuesta
        echo json_encode($resultado);
        break;
    
    case 'restablecer-password':
        // Verificar método
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            http_response_code(405); // Method Not Allowed
            echo json_encode(['error' => 'Método no permitido']);
            exit;
        }
        
        // Obtener datos
        $datos = json_decode(file_get_contents('php://input'), true);
        
        // Si no hay datos, intentar obtener de POST
        if (!$datos) {
            $datos = $_POST;
        }
        
        // Procesar restablecimiento
        $resultado = $authController->restablecerPassword($datos);
        
        // Devolver respuesta
        echo json_encode($resultado);
        break;
    
    case 'verificar-sesion':
        // Verificar método
        if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
            http_response_code(405); // Method Not Allowed
            echo json_encode(['error' => 'Método no permitido']);
            exit;
        }
        
        // Verificar si hay sesión activa
        if (estaAutenticado()) {
            echo json_encode([
                'autenticado' => true,
                'usuario' => [
                    'id' => $_SESSION['usuario_id'],
                    'nombre' => $_SESSION['nombre'],
                    'apellido' => $_SESSION['apellido'],
                    'email' => $_SESSION['email'],
                    'tipo_cuenta' => $_SESSION['tipo_cuenta']
                ]
            ]);
        } else {
            echo json_encode([
                'autenticado' => false
            ]);
        }
        break;
    
    default:
        http_response_code(404); // Not Found
        echo json_encode(['error' => 'Acción no encontrada']);
        break;
}