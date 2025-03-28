<?php
/**
 * Funciones de utilidad
 * 
 * Contiene funciones generales utilizadas en toda la aplicación
 */

// Prevenir acceso directo al archivo
if (!defined('ACCESO_PERMITIDO')) {
    header('HTTP/1.0 403 Forbidden');
    exit;
}

/**
 * Sanitiza una entrada para prevenir XSS
 * 
 * @param string $input Entrada a sanitizar
 * @return string Entrada sanitizada
 */
function sanitizar($input) {
    return htmlspecialchars($input, ENT_QUOTES, 'UTF-8');
}

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
 * Muestra un mensaje de éxito
 * 
 * @param string $mensaje Mensaje a mostrar
 * @return string HTML del mensaje
 */
function mensajeExito($mensaje) {
    return '<div class="alert alert-success">' . sanitizar($mensaje) . '</div>';
}

/**
 * Muestra un mensaje de error
 * 
 * @param string $mensaje Mensaje a mostrar
 * @return string HTML del mensaje
 */
function mensajeError($mensaje) {
    return '<div class="alert alert-danger">' . sanitizar($mensaje) . '</div>';
}

/**
 * Muestra un mensaje de información
 * 
 * @param string $mensaje Mensaje a mostrar
 * @return string HTML del mensaje
 */
function mensajeInfo($mensaje) {
    return '<div class="alert alert-info">' . sanitizar($mensaje) . '</div>';
}

/**
 * Muestra un mensaje de advertencia
 * 
 * @param string $mensaje Mensaje a mostrar
 * @return string HTML del mensaje
 */
function mensajeAdvertencia($mensaje) {
    return '<div class="alert alert-warning">' . sanitizar($mensaje) . '</div>';
}

/**
 * Redirige a una URL
 * 
 * @param string $url URL a la que redirigir
 * @return void
 */
function redirigir($url) {
    header('Location: ' . $url);
    exit;
}

/**
 * Formatea una fecha
 * 
 * @param string $fecha Fecha a formatear
 * @param string $formato Formato de salida (opcional)
 * @return string Fecha formateada
 */
function formatearFecha($fecha, $formato = 'd/m/Y') {
    $timestamp = strtotime($fecha);
    return date($formato, $timestamp);
}

/**
 * Formatea una hora
 * 
 * @param string $hora Hora a formatear
 * @param string $formato Formato de salida (opcional)
 * @return string Hora formateada
 */
function formatearHora($hora, $formato = 'H:i') {
    $timestamp = strtotime($hora);
    return date($formato, $timestamp);
}

/**
 * Formatea un número como tiempo (horas y minutos)
 * 
 * @param int $minutos Minutos a formatear
 * @return string Tiempo formateado
 */
function formatearTiempo($minutos) {
    $horas = floor($minutos / 60);
    $mins = $minutos % 60;
    
    if ($horas > 0) {
        return $horas . 'h ' . $mins . 'm';
    } else {
        return $mins . 'm';
    }
}

/**
 * Trunca un texto a una longitud determinada
 * 
 * @param string $texto Texto a truncar
 * @param int $longitud Longitud máxima (opcional)
 * @param string $sufijo Sufijo a añadir si se trunca (opcional)
 * @return string Texto truncado
 */
function truncarTexto($texto, $longitud = 100, $sufijo = '...') {
    if (mb_strlen($texto) <= $longitud) {
        return $texto;
    }
    
    return mb_substr($texto, 0, $longitud) . $sufijo;
}

/**
 * Genera un slug a partir de un texto
 * 
 * @param string $texto Texto a convertir
 * @return string Slug generado
 */
function generarSlug($texto) {
    // Convertir a minúsculas
    $texto = mb_strtolower($texto);
    
    // Reemplazar caracteres especiales
    $texto = preg_replace('/[^a-z0-9\s-]/', '', $texto);
    
    // Reemplazar espacios por guiones
    $texto = preg_replace('/[\s-]+/', '-', $texto);
    
    // Eliminar guiones al principio y al final
    $texto = trim($texto, '-');
    
    return $texto;
}

/**
 * Genera un color aleatorio en formato hexadecimal
 * 
 * @return string Color generado
 */
function generarColorAleatorio() {
    return '#' . dechex(mt_rand(0, 0xFFFFFF));
}

/**
 * Verifica si una cadena es una fecha válida
 * 
 * @param string $fecha Fecha a verificar
 * @param string $formato Formato esperado (opcional)
 * @return bool True si es una fecha válida, false en caso contrario
 */
function esFechaValida($fecha, $formato = 'Y-m-d') {
    $d = DateTime::createFromFormat($formato, $fecha);
    return $d && $d->format($formato) === $fecha;
}

/**
 * Calcula la diferencia entre dos fechas
 * 
 * @param string $fecha1 Primera fecha
 * @param string $fecha2 Segunda fecha (opcional, por defecto fecha actual)
 * @return array Array con la diferencia en días, horas, minutos y segundos
 */
function diferenciaFechas($fecha1, $fecha2 = null) {
    $fecha1 = new DateTime($fecha1);
    $fecha2 = $fecha2 ? new DateTime($fecha2) : new DateTime();
    
    $diff = $fecha1->diff($fecha2);
    
    return [
        'dias' => $diff->days,
        'horas' => $diff->h,
        'minutos' => $diff->i,
        'segundos' => $diff->s,
        'total_segundos' => $diff->days * 86400 + $diff->h * 3600 + $diff->i * 60 + $diff->s
    ];
}

/**
 * Formatea un número como porcentaje
 * 
 * @param float $numero Número a formatear
 * @param int $decimales Número de decimales (opcional)
 * @return string Porcentaje formateado
 */
function formatearPorcentaje($numero, $decimales = 0) {
    return number_format($numero, $decimales) . '%';
}

/**
 * Formatea un número como moneda
 * 
 * @param float $numero Número a formatear
 * @param string $moneda Símbolo de moneda (opcional)
 * @param int $decimales Número de decimales (opcional)
 * @return string Moneda formateada
 */
function formatearMoneda($numero, $moneda = '$', $decimales = 2) {
    return $moneda . number_format($numero, $decimales);
}

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

/**
 * Registra un error en el archivo de log
 * 
 * @param string $mensaje Mensaje de error
 * @param string $nivel Nivel de error (opcional)
 * @return void
 */
function registrarError($mensaje, $nivel = 'ERROR') {
    if (!LOG_ERRORS) {
        return;
    }
    
    $fecha = date('Y-m-d H:i:s');
    $ip = obtenerIP();
    $usuario = isset($_SESSION['usuario_id']) ? $_SESSION['usuario_id'] : 'No autenticado';
    $url = $_SERVER['REQUEST_URI'];
    
    $log = "[$fecha] [$nivel] [$ip] [Usuario: $usuario] [$url] $mensaje" . PHP_EOL;
    
    error_log($log, 3, ERROR_LOG_FILE);
}

/**
 * Verifica si una URL es válida
 * 
 * @param string $url URL a verificar
 * @return bool True si es una URL válida, false en caso contrario
 */
function esURLValida($url) {
    return filter_var($url, FILTER_VALIDATE_URL) !== false;
}

/**
 * Verifica si un email es válido
 * 
 * @param string $email Email a verificar
 * @return bool True si es un email válido, false en caso contrario
 */
function esEmailValido($email) {
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

/**
 * Envía un correo electrónico
 * 
 * @param string $destinatario Email del destinatario
 * @param string $asunto Asunto del correo
 * @param string $mensaje Mensaje del correo
 * @param array $cabeceras Cabeceras adicionales (opcional)
 * @return bool True si se envió correctamente, false en caso contrario
 */
function enviarEmail($destinatario, $asunto, $mensaje, $cabeceras = []) {
    // Implementar según el sistema de correo que se utilice
    // Esta es una implementación básica con mail()
    
    $cabeceras_predeterminadas = [
        'From' => MAIL_FROM_NAME . ' <' . MAIL_FROM_ADDRESS . '>',
        'Reply-To' => MAIL_FROM_ADDRESS,
        'X-Mailer' => 'PHP/' . phpversion(),
        'MIME-Version' => '1.0',
        'Content-Type' => 'text/html; charset=UTF-8'
    ];
    
    $cabeceras_finales = array_merge($cabeceras_predeterminadas, $cabeceras);
    $cabeceras_string = '';
    
    foreach ($cabeceras_finales as $nombre => $valor) {
        $cabeceras_string .= "$nombre: $valor\r\n";
    }
    
    return mail($destinatario, $asunto, $mensaje, $cabeceras_string);
}

/**
 * Genera un código de verificación aleatorio
 * 
 * @param int $longitud Longitud del código (opcional)
 * @return string Código generado
 */
function generarCodigoVerificacion($longitud = 6) {
    return substr(str_shuffle('0123456789'), 0, $longitud);
}

/**
 * Obtiene la extensión de un archivo
 * 
 * @param string $nombreArchivo Nombre del archivo
 * @return string Extensión del archivo
 */
function obtenerExtensionArchivo($nombreArchivo) {
    return strtolower(pathinfo($nombreArchivo, PATHINFO_EXTENSION));
}

/**
 * Verifica si un archivo es una imagen
 * 
 * @param string $nombreArchivo Nombre del archivo
 * @return bool True si es una imagen, false en caso contrario
 */
function esImagen($nombreArchivo) {
    $extensiones = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    return in_array(obtenerExtensionArchivo($nombreArchivo), $extensiones);
}

/**
 * Genera un nombre único para un archivo
 * 
 * @param string $nombreArchivo Nombre original del archivo
 * @return string Nombre único generado
 */
function generarNombreUnicoArchivo($nombreArchivo) {
    $extension = obtenerExtensionArchivo($nombreArchivo);
    return uniqid() . '.' . $extension;
}

/**
 * Obtiene el tamaño de un archivo en formato legible
 * 
 * @param int $bytes Tamaño en bytes
 * @param int $precision Precisión decimal (opcional)
 * @return string Tamaño formateado
 */
function formatearTamanoArchivo($bytes, $precision = 2) {
    $unidades = ['B', 'KB', 'MB', 'GB', 'TB'];
    
    $bytes = max($bytes, 0);
    $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
    $pow = min($pow, count($unidades) - 1);
    
    $bytes /= pow(1024, $pow);
    
    return round($bytes, $precision) . ' ' . $unidades[$pow];
}