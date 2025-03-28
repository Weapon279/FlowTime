<?php
/**
 * Constantes de la aplicación
 * 
 * Define constantes utilizadas en toda la aplicación
 */

// Prevenir acceso directo al archivo
if (!defined('ACCESO_PERMITIDO')) {
    header('HTTP/1.0 403 Forbidden');
    exit;
}

// Estados de tareas
define('TAREA_PENDIENTE', 'pendiente');
define('TAREA_EN_PROGRESO', 'en_progreso');
define('TAREA_COMPLETADA', 'completada');

// Prioridades de tareas
define('PRIORIDAD_BAJA', 'baja');
define('PRIORIDAD_MEDIA', 'media');
define('PRIORIDAD_ALTA', 'alta');

// Tipos de cuenta
define('CUENTA_GRATUITA', 'gratuito');
define('CUENTA_PREMIUM', 'premium');

// Tipos de eventos
define('EVENTO_TRABAJO', 'Trabajo');
define('EVENTO_PERSONAL', 'Personal');

// Técnicas de productividad
define('TECNICA_POMODORO', 'pomodoro');
define('TECNICA_FLOWTIME', 'flowtime');
define('TECNICA_TIMEBOXING', 'timeboxing');

// Estados de suscripción
define('SUSCRIPCION_ACTIVA', 'activa');
define('SUSCRIPCION_CANCELADA', 'cancelada');
define('SUSCRIPCION_EXPIRADA', 'expirada');

// Planes de suscripción
define('PLAN_MENSUAL', 'mensual');
define('PLAN_ANUAL', 'anual');

// Rutas de la aplicación
define('RUTA_LOGIN', APP_URL . '/login.php');
define('RUTA_REGISTRO', APP_URL . '/register.php');
define('RUTA_DASHBOARD', APP_URL . '/dashboard.php');
define('RUTA_TAREAS', APP_URL . '/tareas.php');
define('RUTA_CALENDARIO', APP_URL . '/calendario.php');
define('RUTA_TECNICAS', APP_URL . '/tecnicas.php');
define('RUTA_DIAGRAMA', APP_URL . '/diagrama.php');
define('RUTA_ANALISIS', APP_URL . '/analisis.php');
define('RUTA_CONFIGURACION', APP_URL . '/configuracion.php');

// Mensajes de error
define('ERROR_LOGIN', 'Correo electrónico o contraseña incorrectos.');
define('ERROR_REGISTRO', 'No se pudo completar el registro. Inténtelo de nuevo.');
define('ERROR_PERMISOS', 'No tienes permisos para acceder a esta página.');
define('ERROR_LIMITE_ALCANZADO', 'Has alcanzado el límite de tu cuenta gratuita. Actualiza a Premium para continuar.');
define('ERROR_SESION_EXPIRADA', 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.');
define('ERROR_CUENTA_INACTIVA', 'Tu cuenta está inactiva. Contacta a soporte para más información.');
define('ERROR_SUSCRIPCION_EXPIRADA', 'Tu suscripción ha expirado. Renueva para seguir disfrutando de los beneficios premium.');

// Mensajes de éxito
define('EXITO_LOGIN', 'Has iniciado sesión correctamente.');
define('EXITO_REGISTRO', 'Te has registrado correctamente. Bienvenido a FlowTime.');
define('EXITO_LOGOUT', 'Has cerrado sesión correctamente.');
define('EXITO_ACTUALIZACION', 'Información actualizada correctamente.');
define('EXITO_SUSCRIPCION', 'Tu suscripción se ha procesado correctamente. ¡Gracias por elegir FlowTime Premium!');