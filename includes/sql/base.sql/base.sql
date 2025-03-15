-- -----------------------------------------------------
-- TimeFlow - Esquema de Base de Datos
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Configuración inicial
-- -----------------------------------------------------
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

-- -----------------------------------------------------
-- Base de datos: `timeflow`
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS `timeflow` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `timeflow`;

-- -----------------------------------------------------
-- Tabla `usuarios`
-- -----------------------------------------------------
CREATE TABLE `usuarios` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(100) NOT NULL,
  `apellido` VARCHAR(100) NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `password` VARCHAR(255) NOT NULL,
  `foto_perfil` VARCHAR(255) DEFAULT NULL,
  `fecha_registro` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ultimo_acceso` DATETIME DEFAULT NULL,
  `estado` ENUM('activo', 'inactivo', 'suspendido') NOT NULL DEFAULT 'activo',
  `tema` ENUM('claro', 'oscuro') NOT NULL DEFAULT 'claro',
  `zona_horaria` VARCHAR(50) DEFAULT 'Europe/Madrid',
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `proyectos`
-- -----------------------------------------------------
CREATE TABLE `proyectos` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `usuario_id` INT NOT NULL,
  `nombre` VARCHAR(100) NOT NULL,
  `descripcion` TEXT,
  `color` VARCHAR(7) DEFAULT '#a3c9a8',
  `fecha_inicio` DATE,
  `fecha_fin` DATE,
  `estado` ENUM('pendiente', 'en_progreso', 'completado', 'archivado') NOT NULL DEFAULT 'pendiente',
  `fecha_creacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_proyectos_usuarios_idx` (`usuario_id`),
  CONSTRAINT `fk_proyectos_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `etiquetas`
-- -----------------------------------------------------
CREATE TABLE `etiquetas` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `usuario_id` INT NOT NULL,
  `nombre` VARCHAR(50) NOT NULL,
  `color` VARCHAR(7) DEFAULT '#bfd7ea',
  PRIMARY KEY (`id`),
  KEY `fk_etiquetas_usuarios_idx` (`usuario_id`),
  CONSTRAINT `fk_etiquetas_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `tareas`
-- -----------------------------------------------------
CREATE TABLE `tareas` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `usuario_id` INT NOT NULL,
  `proyecto_id` INT,
  `titulo` VARCHAR(255) NOT NULL,
  `descripcion` TEXT,
  `prioridad` ENUM('baja', 'media', 'alta') NOT NULL DEFAULT 'media',
  `estado` ENUM('pendiente', 'en_progreso', 'completada', 'archivada') NOT NULL DEFAULT 'pendiente',
  `fecha_vencimiento` DATE,
  `tiempo_estimado` INT DEFAULT NULL COMMENT 'Tiempo estimado en minutos',
  `tiempo_real` INT DEFAULT NULL COMMENT 'Tiempo real en minutos',
  `completada` TINYINT(1) NOT NULL DEFAULT 0,
  `fecha_completada` DATETIME DEFAULT NULL,
  `fecha_creacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `recurrente` TINYINT(1) NOT NULL DEFAULT 0,
  `patron_recurrencia` VARCHAR(255) DEFAULT NULL COMMENT 'Patrón de recurrencia en formato JSON',
  PRIMARY KEY (`id`),
  KEY `fk_tareas_usuarios_idx` (`usuario_id`),
  KEY `fk_tareas_proyectos_idx` (`proyecto_id`),
  CONSTRAINT `fk_tareas_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_tareas_proyectos` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `tareas_etiquetas`
-- -----------------------------------------------------
CREATE TABLE `tareas_etiquetas` (
  `tarea_id` INT NOT NULL,
  `etiqueta_id` INT NOT NULL,
  PRIMARY KEY (`tarea_id`, `etiqueta_id`),
  KEY `fk_tareas_etiquetas_etiquetas_idx` (`etiqueta_id`),
  CONSTRAINT `fk_tareas_etiquetas_tareas` FOREIGN KEY (`tarea_id`) REFERENCES `tareas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_tareas_etiquetas_etiquetas` FOREIGN KEY (`etiqueta_id`) REFERENCES `etiquetas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `subtareas`
-- -----------------------------------------------------
CREATE TABLE `subtareas` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `tarea_id` INT NOT NULL,
  `titulo` VARCHAR(255) NOT NULL,
  `completada` TINYINT(1) NOT NULL DEFAULT 0,
  `fecha_creacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_subtareas_tareas_idx` (`tarea_id`),
  CONSTRAINT `fk_subtareas_tareas` FOREIGN KEY (`tarea_id`) REFERENCES `tareas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `eventos`
-- -----------------------------------------------------
CREATE TABLE `eventos` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `usuario_id` INT NOT NULL,
  `titulo` VARCHAR(255) NOT NULL,
  `descripcion` TEXT,
  `tipo` ENUM('trabajo', 'personal', 'otro') NOT NULL DEFAULT 'trabajo',
  `fecha_inicio` DATETIME NOT NULL,
  `fecha_fin` DATETIME NOT NULL,
  `todo_el_dia` TINYINT(1) NOT NULL DEFAULT 0,
  `color` VARCHAR(7) DEFAULT '#f5b7a5',
  `ubicacion` VARCHAR(255) DEFAULT NULL,
  `url` VARCHAR(255) DEFAULT NULL,
  `recordatorio` INT DEFAULT NULL COMMENT 'Minutos antes del evento',
  `recurrente` TINYINT(1) NOT NULL DEFAULT 0,
  `patron_recurrencia` VARCHAR(255) DEFAULT NULL COMMENT 'Patrón de recurrencia en formato JSON',
  `fecha_creacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_eventos_usuarios_idx` (`usuario_id`),
  CONSTRAINT `fk_eventos_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `eventos_participantes`
-- -----------------------------------------------------
CREATE TABLE `eventos_participantes` (
  `evento_id` INT NOT NULL,
  `usuario_id` INT NOT NULL,
  `estado` ENUM('pendiente', 'aceptado', 'rechazado') NOT NULL DEFAULT 'pendiente',
  `fecha_respuesta` DATETIME DEFAULT NULL,
  PRIMARY KEY (`evento_id`, `usuario_id`),
  KEY `fk_eventos_participantes_usuarios_idx` (`usuario_id`),
  CONSTRAINT `fk_eventos_participantes_eventos` FOREIGN KEY (`evento_id`) REFERENCES `eventos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_eventos_participantes_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `tecnicas_productividad`
-- -----------------------------------------------------
CREATE TABLE `tecnicas_productividad` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(100) NOT NULL,
  `descripcion` TEXT NOT NULL,
  `instrucciones` TEXT NOT NULL,
  `duracion_predeterminada` INT DEFAULT NULL COMMENT 'Duración en minutos',
  `icono` VARCHAR(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `sesiones_productividad`
-- -----------------------------------------------------
CREATE TABLE `sesiones_productividad` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `usuario_id` INT NOT NULL,
  `tecnica_id` INT NOT NULL,
  `tarea_id` INT DEFAULT NULL,
  `fecha_inicio` DATETIME NOT NULL,
  `fecha_fin` DATETIME DEFAULT NULL,
  `duracion` INT DEFAULT NULL COMMENT 'Duración en minutos',
  `completada` TINYINT(1) NOT NULL DEFAULT 0,
  `notas` TEXT,
  `calificacion` INT DEFAULT NULL COMMENT 'Calificación de 1 a 5',
  PRIMARY KEY (`id`),
  KEY `fk_sesiones_usuarios_idx` (`usuario_id`),
  KEY `fk_sesiones_tecnicas_idx` (`tecnica_id`),
  KEY `fk_sesiones_tareas_idx` (`tarea_id`),
  CONSTRAINT `fk_sesiones_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_sesiones_tecnicas` FOREIGN KEY (`tecnica_id`) REFERENCES `tecnicas_productividad` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_sesiones_tareas` FOREIGN KEY (`tarea_id`) REFERENCES `tareas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `notificaciones`
-- -----------------------------------------------------
CREATE TABLE `notificaciones` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `usuario_id` INT NOT NULL,
  `tipo` ENUM('tarea', 'evento', 'sistema', 'recordatorio') NOT NULL,
  `referencia_id` INT DEFAULT NULL COMMENT 'ID de la tarea, evento, etc.',
  `titulo` VARCHAR(255) NOT NULL,
  `mensaje` TEXT NOT NULL,
  `leida` TINYINT(1) NOT NULL DEFAULT 0,
  `fecha_creacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_lectura` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_notificaciones_usuarios_idx` (`usuario_id`),
  CONSTRAINT `fk_notificaciones_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `estadisticas_diarias`
-- -----------------------------------------------------
CREATE TABLE `estadisticas_diarias` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `usuario_id` INT NOT NULL,
  `fecha` DATE NOT NULL,
  `tareas_completadas` INT NOT NULL DEFAULT 0,
  `tareas_creadas` INT NOT NULL DEFAULT 0,
  `tiempo_productivo` INT NOT NULL DEFAULT 0 COMMENT 'Tiempo en minutos',
  `tiempo_por_proyecto` TEXT COMMENT 'JSON con tiempo por proyecto',
  `tiempo_por_tecnica` TEXT COMMENT 'JSON con tiempo por técnica',
  `productividad` FLOAT DEFAULT NULL COMMENT 'Índice de productividad (0-100)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `usuario_fecha` (`usuario_id`, `fecha`),
  KEY `fk_estadisticas_usuarios_idx` (`usuario_id`),
  CONSTRAINT `fk_estadisticas_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `configuracion_usuario`
-- -----------------------------------------------------
CREATE TABLE `configuracion_usuario` (
  `usuario_id` INT NOT NULL,
  `notificaciones_email` TINYINT(1) NOT NULL DEFAULT 1,
  `notificaciones_push` TINYINT(1) NOT NULL DEFAULT 1,
  `recordatorios_tareas` TINYINT(1) NOT NULL DEFAULT 1,
  `recordatorios_eventos` TINYINT(1) NOT NULL DEFAULT 1,
  `formato_hora` ENUM('12h', '24h') NOT NULL DEFAULT '24h',
  `primer_dia_semana` ENUM('lunes', 'domingo') NOT NULL DEFAULT 'lunes',
  `vista_predeterminada` ENUM('dia', 'semana', 'mes') NOT NULL DEFAULT 'semana',
  `idioma` VARCHAR(5) NOT NULL DEFAULT 'es-ES',
  PRIMARY KEY (`usuario_id`),
  CONSTRAINT `fk_configuracion_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `sesiones_usuario`
-- -----------------------------------------------------
CREATE TABLE `sesiones_usuario` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `usuario_id` INT NOT NULL,
  `token` VARCHAR(255) NOT NULL,
  `ip` VARCHAR(45) NOT NULL,
  `agente_usuario` VARCHAR(255) NOT NULL,
  `fecha_creacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_expiracion` DATETIME NOT NULL,
  `activa` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `fk_sesiones_usuarios_idx` (`usuario_id`),
  CONSTRAINT `fk_sesiones_usuarios_idx` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `restablecimiento_password`
-- -----------------------------------------------------
CREATE TABLE `restablecimiento_password` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `usuario_id` INT NOT NULL,
  `token` VARCHAR(255) NOT NULL,
  `fecha_creacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_expiracion` DATETIME NOT NULL,
  `utilizado` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `fk_restablecimiento_usuarios_idx` (`usuario_id`),
  CONSTRAINT `fk_restablecimiento_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `matriz_eisenhower`
-- -----------------------------------------------------
CREATE TABLE `matriz_eisenhower` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `usuario_id` INT NOT NULL,
  `nombre` VARCHAR(100) NOT NULL,
  `fecha_creacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_matriz_usuarios_idx` (`usuario_id`),
  CONSTRAINT `fk_matriz_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `elementos_matriz`
-- -----------------------------------------------------
CREATE TABLE `elementos_matriz` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `matriz_id` INT NOT NULL,
  `tarea_id` INT DEFAULT NULL,
  `titulo` VARCHAR(255) NOT NULL,
  `descripcion` TEXT,
  `cuadrante` ENUM('urgente_importante', 'no_urgente_importante', 'urgente_no_importante', 'no_urgente_no_importante') NOT NULL,
  `orden` INT NOT NULL DEFAULT 0,
  `completado` TINYINT(1) NOT NULL DEFAULT 0,
  `fecha_creacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_elementos_matriz_idx` (`matriz_id`),
  KEY `fk_elementos_tareas_idx` (`tarea_id`),
  CONSTRAINT `fk_elementos_matriz` FOREIGN KEY (`matriz_id`) REFERENCES `matriz_eisenhower` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_elementos_tareas` FOREIGN KEY (`tarea_id`) REFERENCES `tareas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `gantt`
-- -----------------------------------------------------
CREATE TABLE `gantt` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `usuario_id` INT NOT NULL,
  `proyecto_id` INT NOT NULL,
  `nombre` VARCHAR(100) NOT NULL,
  `descripcion` TEXT,
  `fecha_inicio` DATE NOT NULL,
  `fecha_fin` DATE NOT NULL,
  `fecha_creacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_gantt_usuarios_idx` (`usuario_id`),
  KEY `fk_gantt_proyectos_idx` (`proyecto_id`),
  CONSTRAINT `fk_gantt_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_gantt_proyectos` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `tareas_gantt`
-- -----------------------------------------------------
CREATE TABLE `tareas_gantt` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `gantt_id` INT NOT NULL,
  `tarea_id` INT DEFAULT NULL,
  `nombre` VARCHAR(255) NOT NULL,
  `descripcion` TEXT,
  `fecha_inicio` DATE NOT NULL,
  `fecha_fin` DATE NOT NULL,
  `progreso` INT NOT NULL DEFAULT 0 COMMENT 'Progreso en porcentaje (0-100)',
  `tarea_padre_id` INT DEFAULT NULL COMMENT 'ID de la tarea padre en el gantt',
  `orden` INT NOT NULL DEFAULT 0,
  `color` VARCHAR(7) DEFAULT '#a3c9a8',
  PRIMARY KEY (`id`),
  KEY `fk_tareas_gantt_gantt_idx` (`gantt_id`),
  KEY `fk_tareas_gantt_tareas_idx` (`tarea_id`),
  KEY `fk_tareas_gantt_padre_idx` (`tarea_padre_id`),
  CONSTRAINT `fk_tareas_gantt_gantt` FOREIGN KEY (`gantt_id`) REFERENCES `gantt` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_tareas_gantt_tareas` FOREIGN KEY (`tarea_id`) REFERENCES `tareas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_tareas_gantt_padre` FOREIGN KEY (`tarea_padre_id`) REFERENCES `tareas_gantt` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Tabla `dependencias_gantt`
-- -----------------------------------------------------
CREATE TABLE `dependencias_gantt` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `tarea_predecesora_id` INT NOT NULL,
  `tarea_sucesora_id` INT NOT NULL,
  `tipo` ENUM('fin_a_inicio', 'inicio_a_inicio', 'fin_a_fin', 'inicio_a_fin') NOT NULL DEFAULT 'fin_a_inicio',
  `retraso` INT NOT NULL DEFAULT 0 COMMENT 'Retraso en días',
  PRIMARY KEY (`id`),
  KEY `fk_dependencias_predecesora_idx` (`tarea_predecesora_id`),
  KEY `fk_dependencias_sucesora_idx` (`tarea_sucesora_id`),
  CONSTRAINT `fk_dependencias_predecesora` FOREIGN KEY (`tarea_predecesora_id`) REFERENCES `tareas_gantt` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_dependencias_sucesora` FOREIGN KEY (`tarea_sucesora_id`) REFERENCES `tareas_gantt` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Datos iniciales para la tabla `tecnicas_productividad`
-- -----------------------------------------------------
INSERT INTO `tecnicas_productividad` (`nombre`, `descripcion`, `instrucciones`, `duracion_predeterminada`, `icono`) VALUES
('Pomodoro', 'Técnica de gestión del tiempo que utiliza intervalos de trabajo de 25 minutos seguidos de descansos cortos.', '1. Elige una tarea a realizar\n2. Configura el temporizador a 25 minutos\n3. Trabaja en la tarea hasta que suene el temporizador\n4. Toma un descanso corto de 5 minutos\n5. Después de 4 pomodoros, toma un descanso más largo de 15-30 minutos', 25, 'fa-clock'),
('Flowtime', 'Técnica que adapta los intervalos de trabajo y descanso a tu flujo natural de productividad.', '1. Anota la hora de inicio cuando comiences a trabajar\n2. Trabaja hasta que sientas que necesitas un descanso\n3. Anota la hora de finalización y la duración del trabajo\n4. Toma un descanso proporcional al tiempo trabajado (1:5)\n5. Repite el proceso', NULL, 'fa-wave-square'),
('Técnica (10+2)*5', 'Método que alterna 10 minutos de trabajo intenso con 2 minutos de descanso, repetido 5 veces.', '1. Trabaja intensamente durante 10 minutos\n2. Descansa durante 2 minutos\n3. Repite este ciclo 5 veces (1 hora en total)', 10, 'fa-stopwatch'),
('Método 90/30', 'Técnica que aprovecha los ciclos naturales de atención, trabajando 90 minutos seguidos de 30 minutos de descanso.', '1. Trabaja concentrado durante 90 minutos\n2. Toma un descanso de 30 minutos\n3. Repite según sea necesario', 90, 'fa-hourglass-half'),
('Técnica 52/17', 'Basada en estudios que muestran que las personas más productivas trabajan 52 minutos y descansan 17.', '1. Trabaja con total concentración durante 52 minutos\n2. Toma un descanso completo de 17 minutos\n3. Repite el ciclo', 52, 'fa-business-time');

-- -----------------------------------------------------
-- Procedimiento almacenado para crear un nuevo usuario
-- -----------------------------------------------------
DELIMITER $$
CREATE PROCEDURE `crear_usuario`(
  IN p_nombre VARCHAR(100),
  IN p_apellido VARCHAR(100),
  IN p_email VARCHAR(255),
  IN p_password VARCHAR(255)
)
BEGIN
  DECLARE usuario_id INT;
  
  -- Insertar el nuevo usuario
  INSERT INTO `usuarios` (`nombre`, `apellido`, `email`, `password`)
  VALUES (p_nombre, p_apellido, p_email, p_password);
  
  -- Obtener el ID del usuario recién creado
  SET usuario_id = LAST_INSERT_ID();
  
  -- Crear configuración predeterminada para el usuario
  INSERT INTO `configuracion_usuario` (`usuario_id`) VALUES (usuario_id);
  
  -- Crear etiquetas predeterminadas
  INSERT INTO `etiquetas` (`usuario_id`, `nombre`, `color`) VALUES
  (usuario_id, 'Trabajo', '#f5b7a5'),
  (usuario_id, 'Personal', '#a3c9a8'),
  (usuario_id, 'Urgente', '#ef6f6c'),
  (usuario_id, 'Importante', '#ffd166');
  
  -- Crear matriz de Eisenhower predeterminada
  INSERT INTO `matriz_eisenhower` (`usuario_id`, `nombre`)
  VALUES (usuario_id, 'Mi Matriz de Priorización');
  
  -- Devolver el ID del usuario creado
  SELECT usuario_id AS 'id_usuario';
END$$
DELIMITER ;

-- -----------------------------------------------------
-- Procedimiento almacenado para obtener estadísticas del dashboard
-- -----------------------------------------------------
DELIMITER $$
CREATE PROCEDURE `obtener_estadisticas_dashboard`(
  IN p_usuario_id INT,
  IN p_fecha_inicio DATE,
  IN p_fecha_fin DATE
)
BEGIN
  -- Tareas completadas en el período
  SELECT COUNT(*) AS tareas_completadas
  FROM `tareas`
  WHERE `usuario_id` = p_usuario_id
  AND `completada` = 1
  AND `fecha_completada` BETWEEN p_fecha_inicio AND p_fecha_fin;
  
  -- Tareas pendientes
  SELECT COUNT(*) AS tareas_pendientes
  FROM `tareas`
  WHERE `usuario_id` = p_usuario_id
  AND `completada` = 0
  AND (`fecha_vencimiento` IS NULL OR `fecha_vencimiento` >= CURDATE());
  
  -- Tiempo productivo total
  SELECT SUM(`duracion`) AS tiempo_productivo
  FROM `sesiones_productividad`
  WHERE `usuario_id` = p_usuario_id
  AND `fecha_inicio` BETWEEN p_fecha_inicio AND p_fecha_fin
  AND `completada` = 1;
  
  -- Productividad promedio
  SELECT AVG(`productividad`) AS productividad_promedio
  FROM `estadisticas_diarias`
  WHERE `usuario_id` = p_usuario_id
  AND `fecha` BETWEEN p_fecha_inicio AND p_fecha_fin;
  
  -- Próximos eventos
  SELECT `id`, `titulo`, `fecha_inicio`, `tipo`
  FROM `eventos`
  WHERE `usuario_id` = p_usuario_id
  AND `fecha_inicio` >= NOW()
  ORDER BY `fecha_inicio`
  LIMIT 5;
  
  -- Tareas por proyecto
  SELECT p.`nombre` AS proyecto, COUNT(t.`id`) AS total_tareas
  FROM `tareas` t
  JOIN `proyectos` p ON t.`proyecto_id` = p.`id`
  WHERE t.`usuario_id` = p_usuario_id
  GROUP BY p.`id`
  ORDER BY total_tareas DESC;
  
  -- Distribución de tiempo por proyecto
  SELECT p.`nombre` AS proyecto, SUM(t.`tiempo_real`) AS tiempo_total
  FROM `tareas` t
  JOIN `proyectos` p ON t.`proyecto_id` = p.`id`
  WHERE t.`usuario_id` = p_usuario_id
  AND t.`completada` = 1
  AND t.`fecha_completada` BETWEEN p_fecha_inicio AND p_fecha_fin
  GROUP BY p.`id`
  ORDER BY tiempo_total DESC;
END$$
DELIMITER ;

-- -----------------------------------------------------
-- Trigger para actualizar estadísticas al completar una tarea
-- -----------------------------------------------------
DELIMITER $$
CREATE TRIGGER `actualizar_estadisticas_tarea_completada`
AFTER UPDATE ON `tareas`
FOR EACH ROW
BEGIN
  DECLARE v_fecha DATE;
  DECLARE v_tiempo_proyecto INT DEFAULT 0;
  
  -- Si la tarea se acaba de marcar como completada
  IF NEW.`completada` = 1 AND OLD.`completada` = 0 THEN
    -- Usar la fecha actual si no se proporciona fecha_completada
    IF NEW.`fecha_completada` IS NULL THEN
      SET v_fecha = CURDATE();
    ELSE
      SET v_fecha = DATE(NEW.`fecha_completada`);
    END IF;
    
    -- Actualizar o insertar estadísticas diarias
    INSERT INTO `estadisticas_diarias` (`usuario_id`, `fecha`, `tareas_completadas`)
    VALUES (NEW.`usuario_id`, v_fecha, 1)
    ON DUPLICATE KEY UPDATE
      `tareas_completadas` = `tareas_completadas` + 1;
    
    -- Si la tarea tiene tiempo_real, actualizar tiempo_productivo
    IF NEW.`tiempo_real` IS NOT NULL AND NEW.`tiempo_real` > 0 THEN
      UPDATE `estadisticas_diarias`
      SET `tiempo_productivo` = `tiempo_productivo` + NEW.`tiempo_real`
      WHERE `usuario_id` = NEW.`usuario_id` AND `fecha` = v_fecha;
      
      -- Si la tarea pertenece a un proyecto, actualizar tiempo_por_proyecto
      IF NEW.`proyecto_id` IS NOT NULL THEN
        -- Obtener el tiempo actual por proyecto (JSON)
        SELECT `tiempo_por_proyecto` INTO v_tiempo_proyecto
        FROM `estadisticas_diarias`
        WHERE `usuario_id` = NEW.`usuario_id` AND `fecha` = v_fecha;
        
        -- Actualizar el JSON con el nuevo tiempo para este proyecto
        UPDATE `estadisticas_diarias`
        SET `tiempo_por_proyecto` = JSON_SET(
          IFNULL(v_tiempo_proyecto, JSON_OBJECT()),
          CONCAT('$."', (SELECT `nombre` FROM `proyectos` WHERE `id` = NEW.`proyecto_id`), '"'),
          IFNULL(
            JSON_EXTRACT(v_tiempo_proyecto, CONCAT('$."', (SELECT `nombre` FROM `proyectos` WHERE `id` = NEW.`proyecto_id`), '"')),
            0
          ) + NEW.`tiempo_real`
        )
        WHERE `usuario_id` = NEW.`usuario_id` AND `fecha` = v_fecha;
      END IF;
    END IF;
  END IF;
END$$
DELIMITER ;

-- -----------------------------------------------------
-- Trigger para actualizar estadísticas al crear una tarea
-- -----------------------------------------------------
DELIMITER $$
CREATE TRIGGER `actualizar_estadisticas_tarea_creada`
AFTER INSERT ON `tareas`
FOR EACH ROW
BEGIN
  -- Actualizar o insertar estadísticas diarias
  INSERT INTO `estadisticas_diarias` (`usuario_id`, `fecha`, `tareas_creadas`)
  VALUES (NEW.`usuario_id`, CURDATE(), 1)
  ON DUPLICATE KEY UPDATE
    `tareas_creadas` = `tareas_creadas` + 1;
END$$
DELIMITER ;

-- -----------------------------------------------------
-- Trigger para actualizar estadísticas de sesiones de productividad
-- -----------------------------------------------------
DELIMITER $$
CREATE TRIGGER `actualizar_estadisticas_sesion_productividad`
AFTER UPDATE ON `sesiones_productividad`
FOR EACH ROW
BEGIN
  DECLARE v_fecha DATE;
  DECLARE v_tiempo_tecnica INT DEFAULT 0;
  
  -- Si la sesión se acaba de completar
  IF NEW.`completada` = 1 AND OLD.`completada` = 0 AND NEW.`duracion` IS NOT NULL THEN
    SET v_fecha = DATE(NEW.`fecha_inicio`);
    
    -- Actualizar tiempo_productivo
    UPDATE `estadisticas_diarias`
    SET `tiempo_productivo` = `tiempo_productivo` + NEW.`duracion`
    WHERE `usuario_id` = NEW.`usuario_id` AND `fecha` = v_fecha;
    
    -- Actualizar tiempo_por_tecnica
    SELECT `tiempo_por_tecnica` INTO v_tiempo_tecnica
    FROM `estadisticas_diarias`
    WHERE `usuario_id` = NEW.`usuario_id` AND `fecha` = v_fecha;
    
    UPDATE `estadisticas_diarias`
    SET `tiempo_por_tecnica` = JSON_SET(
      IFNULL(v_tiempo_tecnica, JSON_OBJECT()),
      CONCAT('$."', (SELECT `nombre` FROM `tecnicas_productividad` WHERE `id` = NEW.`tecnica_id`), '"'),
      IFNULL(
        JSON_EXTRACT(v_tiempo_tecnica, CONCAT('$."', (SELECT `nombre` FROM `tecnicas_productividad` WHERE `id` = NEW.`tecnica_id`), '"')),
        0
      ) + NEW.`duracion`
    )
    WHERE `usuario_id` = NEW.`usuario_id` AND `fecha` = v_fecha;
  END IF;
END$$
DELIMITER ;

-- -----------------------------------------------------
-- Vista para obtener tareas con información de proyecto
-- -----------------------------------------------------
CREATE VIEW `vista_tareas` AS
SELECT 
  t.`id`,
  t.`usuario_id`,
  t.`proyecto_id`,
  p.`nombre` AS `proyecto_nombre`,
  p.`color` AS `proyecto_color`,
  t.`titulo`,
  t.`descripcion`,
  t.`prioridad`,
  t.`estado`,
  t.`fecha_vencimiento`,
  t.`tiempo_estimado`,
  t.`tiempo_real`,
  t.`completada`,
  t.`fecha_completada`,
  t.`fecha_creacion`,
  t.`fecha_modificacion`,
  GROUP_CONCAT(e.`nombre` SEPARATOR ', ') AS `etiquetas`
FROM `tareas` t
LEFT JOIN `proyectos` p ON t.`proyecto_id` = p.`id`
LEFT JOIN `tareas_etiquetas` te ON t.`id` = te.`tarea_id`
LEFT JOIN `etiquetas` e ON te.`etiqueta_id` = e.`id`
GROUP BY t.`id`;

-- -----------------------------------------------------
-- Vista para obtener eventos con información de participantes
-- -----------------------------------------------------
CREATE VIEW `vista_eventos` AS
SELECT 
  e.`id`,
  e.`usuario_id`,
  e.`titulo`,
  e.`descripcion`,
  e.`tipo`,
  e.`fecha_inicio`,
  e.`fecha_fin`,
  e.`todo_el_dia`,
  e.`color`,
  e.`ubicacion`,
  e.`url`,
  e.`recordatorio`,
  e.`recurrente`,
  e.`patron_recurrencia`,
  COUNT(ep.`usuario_id`) AS `total_participantes`,
  SUM(CASE WHEN ep.`estado` = 'aceptado' THEN 1 ELSE 0 END) AS `participantes_aceptados`
FROM `eventos` e
LEFT JOIN `eventos_participantes` ep ON e.`id` = ep.`evento_id`
GROUP BY e.`id`;

-- -----------------------------------------------------
-- Vista para obtener estadísticas de productividad por usuario
-- -----------------------------------------------------
CREATE VIEW `vista_productividad_usuario` AS
SELECT 
  u.`id` AS `usuario_id`,
  u.`nombre`,
  u.`apellido`,
  COUNT(DISTINCT t.`id`) AS `total_tareas`,
  SUM(CASE WHEN t.`completada` = 1 THEN 1 ELSE 0 END) AS `tareas_completadas`,
  SUM(CASE WHEN t.`completada` = 0 THEN 1 ELSE 0 END) AS `tareas_pendientes`,
  SUM(t.`tiempo_real`) AS `tiempo_total_tareas`,
  SUM(sp.`duracion`) AS `tiempo_total_sesiones`,
  COUNT(DISTINCT sp.`id`) AS `total_sesiones_productividad`,
  AVG(sp.`calificacion`) AS `calificacion_promedio`
FROM `usuarios` u
LEFT JOIN `tareas` t ON u.`id` = t.`usuario_id`
LEFT JOIN `sesiones_productividad` sp ON u.`id` = sp.`usuario_id`
GROUP BY u.`id`;