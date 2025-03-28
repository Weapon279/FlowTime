<?php
/**
 * Validación de datos
 * 
 * Contiene funciones para validar datos de entrada
 */

// Prevenir acceso directo al archivo
if (!defined('ACCESO_PERMITIDO')) {
    header('HTTP/1.0 403 Forbidden');
    exit;
}

/**
 * Valida un formulario
 * 
 * @param array $datos Datos a validar
 * @param array $reglas Reglas de validación
 * @return array Array con errores o vacío si no hay errores
 */
function validarFormulario($datos, $reglas) {
    $errores = [];
    
    foreach ($reglas as $campo => $reglasDelCampo) {
        // Si el campo no existe y es requerido, agregar error
        if (!isset($datos[$campo]) && in_array('required', $reglasDelCampo)) {
            $errores[$campo] = 'El campo es obligatorio';
            continue;
        }
        
        // Si el campo no existe y no es requerido, continuar
        if (!isset($datos[$campo])) {
            continue;
        }
        
        $valor = $datos[$campo];
        
        // Validar cada regla
        foreach ($reglasDelCampo as $regla) {
            // Regla simple (sin parámetros)
            if (is_string($regla)) {
                switch ($regla) {
                    case 'required':
                        if (empty($valor) && $valor !== '0') {
                            $errores[$campo] = 'El campo es obligatorio';
                        }
                        break;
                    case 'email':
                        if (!filter_var($valor, FILTER_VALIDATE_EMAIL)) {
                            $errores[$campo] = 'El correo electrónico no es válido';
                        }
                        break;
                    case 'url':
                        if (!filter_var($valor, FILTER_VALIDATE_URL)) {
                            $errores[$campo] = 'La URL no es válida';
                        }
                        break;
                    case 'numeric':
                        if (!is_numeric($valor)) {
                            $errores[$campo] = 'El campo debe ser numérico';
                        }
                        break;
                    case 'integer':
                        if (!filter_var($valor, FILTER_VALIDATE_INT)) {
                            $errores[$campo] = 'El campo debe ser un número entero';
                        }
                        break;
                    case 'float':
                        if (!filter_var($valor, FILTER_VALIDATE_FLOAT)) {
                            $errores[$campo] = 'El campo debe ser un número decimal';
                        }
                        break;
                    case 'alpha':
                        if (!ctype_alpha($valor)) {
                            $errores[$campo] = 'El campo solo debe contener letras';
                        }
                        break;
                    case 'alphanumeric':
                        if (!ctype_alnum($valor)) {
                            $errores[$campo] = 'El campo solo debe contener letras y números';
                        }
                        break;
                    case 'date':
                        if (!esFechaValida($valor)) {
                            $errores[$campo] = 'La fecha no es válida';
                        }
                        break;
                    case 'time':
                        if (!preg_match('/^([01]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$/', $valor)) {
                            $errores[$campo] = 'La hora no es válida';
                        }
                        break;
                }
            }
            // Regla con parámetros
            elseif (is_array($regla)) {
                $nombreRegla = $regla[0];
                $parametros = array_slice($regla, 1);
                
                switch ($nombreRegla) {
                    case 'min':
                        if (strlen($valor) < $parametros[0]) {
                            $errores[$campo] = "El campo debe tener al menos {$parametros[0]} caracteres";
                        }
                        break;
                    case 'max':
                        if (strlen($valor) > $parametros[0]) {
                            $errores[$campo] = "El campo debe tener como máximo {$parametros[0]} caracteres";
                        }
                        break;
                    case 'between':
                        if (strlen($valor) < $parametros[0] || strlen($valor) > $parametros[1]) {
                            $errores[$campo] = "El campo debe tener entre {$parametros[0]} y {$parametros[1]} caracteres";
                        }
                        break;
                    case 'min_value':
                        if (floatval($valor) < $parametros[0]) {
                            $errores[$campo] = "El valor debe ser mayor o igual a {$parametros[0]}";
                        }
                        break;
                    case 'max_value':
                        if (floatval($valor) > $parametros[0]) {
                            $errores[$campo] = "El valor debe ser menor o igual a {$parametros[0]}";
                        }
                        break;
                    case 'between_value':
                        if (floatval($valor) < $parametros[0] || floatval($valor) > $parametros[1]) {
                            $errores[$campo] = "El valor debe estar entre {$parametros[0]} y {$parametros[1]}";
                        }
                        break;
                    case 'in':
                        if (!in_array($valor, $parametros)) {
                            $errores[$campo] = "El valor no es válido";
                        }
                        break;
                    case 'not_in':
                        if (in_array($valor, $parametros)) {
                            $errores[$campo] = "El valor no es válido";
                        }
                        break;
                    case 'regex':
                        if (!preg_match($parametros[0], $valor)) {
                            $errores[$campo] = "El formato no es válido";
                        }
                        break;
                    case 'same':
                        if (!isset($datos[$parametros[0]]) || $valor !== $datos[$parametros[0]]) {
                            $errores[$campo] = "Los campos no coinciden";
                        }
                        break;
                    case 'different':
                        if (isset($datos[$parametros[0]]) && $valor === $datos[$parametros[0]]) {
                            $errores[$campo] = "Los campos no deben coincidir";
                        }
                        break;
                    case 'unique':
                        // Verificar si el valor ya existe en la base de datos
                        $db = getDbConnection();
                        $tabla = $parametros[0];
                        $columna = $parametros[1];
                        $excepcion = isset($parametros[2]) ? $parametros[2] : null;
                        
                        $sql = "SELECT COUNT(*) as total FROM $tabla WHERE $columna = :valor";
                        $params = [':valor' => $valor];
                        
                        if ($excepcion) {
                            $sql .= " AND id != :excepcion";
                            $params[':excepcion'] = $excepcion;
                        }
                        
                        $stmt = $db->prepare($sql);
                        $stmt->execute($params);
                        $resultado = $stmt->fetch();
                        
                        if ($resultado['total'] > 0) {
                            $errores[$campo] = "El valor ya está en uso";
                        }
                        break;
                    case 'exists':
                        // Verificar si el valor existe en la base de datos
                        $db = getDbConnection();
                        $tabla = $parametros[0];
                        $columna = $parametros[1];
                        
                        $stmt = $db->prepare("SELECT COUNT(*) as total FROM $tabla WHERE $columna = :valor");
                        $stmt->execute([':valor' => $valor]);
                        $resultado = $stmt->fetch();
                        
                        if ($resultado['total'] === 0) {
                            $errores[$campo] = "El valor no existe";
                        }
                        break;
                    case 'file':
                        // Validar archivo
                        if (!isset($_FILES[$campo])) {
                            $errores[$campo] = "No se ha subido ningún archivo";
                            break;
                        }
                        
                        $archivo = $_FILES[$campo];
                        
                        // Verificar si hubo error en la subida
                        if ($archivo['error'] !== UPLOAD_ERR_OK) {
                            $errores[$campo] = "Error al subir el archivo";
                            break;
                        }
                        
                        // Verificar tipo de archivo
                        if (isset($parametros[0]) && $parametros[0] === 'image') {
                            if (!esImagen($archivo['name'])) {
                                $errores[$campo] = "El archivo debe ser una imagen";
                            }
                        }
                        
                        // Verificar extensiones permitidas
                        if (isset($parametros[0]) && is_array($parametros[0])) {
                            $extension = obtenerExtensionArchivo($archivo['name']);
                            if (!in_array($extension, $parametros[0])) {
                                $errores[$campo] = "La extensión del archivo no es válida";
                            }
                        }
                        
                        // Verificar tamaño máximo
                        if (isset($parametros[1]) && $archivo['size'] > $parametros[1]) {
                            $errores[$campo] = "El archivo es demasiado grande";
                        }
                        break;
                }
            }
            
            // Si ya hay un error para este campo, no seguir validando
            if (isset($errores[$campo])) {
                break;
            }
        }
    }
    
    return $errores;
}

/**
 * Valida un correo electrónico
 * 
 * @param string $email Correo electrónico a validar
 * @return bool True si es válido, false en caso contrario
 */
function validarEmail($email) {
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

/**
 * Valida una contraseña
 * 
 * @param string $password Contraseña a validar
 * @param int $minLength Longitud mínima (opcional)
 * @param bool $requireUppercase Requiere mayúsculas (opcional)
 * @param bool $requireLowercase Requiere minúsculas (opcional)
 * @param bool $requireNumbers Requiere números (opcional)
 * @param bool $requireSpecial Requiere caracteres especiales (opcional)
 * @return array Array con errores o vacío si no hay errores
 */
function validarPassword($password, $minLength = 8, $requireUppercase = true, $requireLowercase = true, $requireNumbers = true, $requireSpecial = true) {
    $errores = [];
    
    // Verificar longitud mínima
    if (strlen($password) < $minLength) {
        $errores[] = "La contraseña debe tener al menos $minLength caracteres";
    }
    
    // Verificar mayúsculas
    if ($requireUppercase && !preg_match('/[A-Z]/', $password)) {
        $errores[] = "La contraseña debe contener al menos una letra mayúscula";
    }
    
    // Verificar minúsculas
    if ($requireLowercase && !preg_match('/[a-z]/', $password)) {
        $errores[] = "La contraseña debe contener al menos una letra minúscula";
    }
    
    // Verificar números
    if ($requireNumbers && !preg_match('/[0-9]/', $password)) {
        $errores[] = "La contraseña debe contener al menos un número";
    }
    
    // Verificar caracteres especiales
    if ($requireSpecial && !preg_match('/[^A-Za-z0-9]/', $password)) {
        $errores[] = "La contraseña debe contener al menos un carácter especial";
    }
    
    return $errores;
}

/**
 * Valida una fecha
 * 
 * @param string $fecha Fecha a validar
 * @param string $formato Formato esperado (opcional)
 * @param string $min Fecha mínima (opcional)
 * @param string $max Fecha máxima (opcional)
 * @return array Array con errores o vacío si no hay errores
 */
function validarFecha($fecha, $formato = 'Y-m-d', $min = null, $max = null) {
    $errores = [];
    
    // Verificar formato
    $d = DateTime::createFromFormat($formato, $fecha);
    if (!$d || $d->format($formato) !== $fecha) {
        $errores[] = "La fecha no tiene el formato correcto";
        return $errores;
    }
    
    // Verificar fecha mínima
    if ($min !== null) {
        $minDate = new DateTime($min);
        if ($d < $minDate) {
            $errores[] = "La fecha debe ser posterior a " . $minDate->format($formato);
        }
    }
    
    // Verificar fecha máxima
    if ($max !== null) {
        $maxDate = new DateTime($max);
        if ($d > $maxDate) {
            $errores[] = "La fecha debe ser anterior a " . $maxDate->format($formato);
        }
    }
    
    return $errores;
}

/**
 * Valida una hora
 * 
 * @param string $hora Hora a validar
 * @param string $formato Formato esperado (opcional)
 * @return bool True si es válida, false en caso contrario
 */
function validarHora($hora, $formato = 'H:i') {
    $d = DateTime::createFromFormat($formato, $hora);
    return $d && $d->format($formato) === $hora;
}

/**
 * Valida un número de teléfono
 * 
 * @param string $telefono Teléfono a validar
 * @return bool True si es válido, false en caso contrario
 */
function validarTelefono($telefono) {
    // Eliminar caracteres no numéricos
    $telefono = preg_replace('/[^0-9]/', '', $telefono);
    
    // Verificar longitud (entre 8 y 15 dígitos)
    return strlen($telefono) >= 8 && strlen($telefono) <= 15;
}

/**
 * Valida un nombre
 * 
 * @param string $nombre Nombre a validar
 * @param int $minLength Longitud mínima (opcional)
 * @param int $maxLength Longitud máxima (opcional)
 * @return array Array con errores o vacío si no hay errores
 */
function validarNombre($nombre, $minLength = 2, $maxLength = 50) {
    $errores = [];
    
    // Verificar longitud
    if (strlen($nombre) < $minLength) {
        $errores[] = "El nombre debe tener al menos $minLength caracteres";
    }
    
    if (strlen($nombre) > $maxLength) {
        $errores[] = "El nombre debe tener como máximo $maxLength caracteres";
    }
    
    // Verificar que solo contenga letras, espacios y algunos caracteres especiales
    if (!preg_match('/^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s\'-]+$/', $nombre)) {
        $errores[] = "El nombre contiene caracteres no válidos";
    }
    
    return $errores;
}

/**
 * Muestra los errores de validación
 * 
 * @param array $errores Errores a mostrar
 * @return string HTML con los errores
 */
function mostrarErrores($errores) {
    if (empty($errores)) {
        return '';
    }
    
    $html = '<div class="alert alert-danger"><ul>';
    
    foreach ($errores as $campo => $error) {
        if (is_array($error)) {
            foreach ($error as $err) {
                $html .= '<li>' . sanitizar($err) . '</li>';
            }
        } else {
            $html .= '<li>' . sanitizar($error) . '</li>';
        }
    }
    
    $html .= '</ul></div>';
    
    return $html;
}