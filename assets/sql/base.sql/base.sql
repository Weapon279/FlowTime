-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Versión del servidor:         8.0.30 - MySQL Community Server - GPL
-- SO del servidor:              Win64
-- HeidiSQL Versión:             12.1.0.6537
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- Volcando estructura de base de datos para flowtime
CREATE DATABASE IF NOT EXISTS `flowtime` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `flowtime`;

-- Volcando estructura para tabla flowtime.cache
CREATE TABLE IF NOT EXISTS `cache` (
  `clave` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `valor` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiracion` int NOT NULL,
  PRIMARY KEY (`clave`),
  KEY `expiracion` (`expiracion`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.cache: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.categorias
CREATE TABLE IF NOT EXISTS `categorias` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `color` varchar(7) COLLATE utf8mb4_unicode_ci DEFAULT '#A3C9A8',
  `icono` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT 'fa-folder',
  PRIMARY KEY (`id`),
  KEY `usuario_id` (`usuario_id`),
  CONSTRAINT `fk_categorias_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.categorias: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.configuracion_usuario
CREATE TABLE IF NOT EXISTS `configuracion_usuario` (
  `usuario_id` int NOT NULL,
  `notificaciones_email` tinyint(1) NOT NULL DEFAULT '1',
  `notificaciones_push` tinyint(1) NOT NULL DEFAULT '1',
  `recordatorios_tareas` tinyint(1) NOT NULL DEFAULT '1',
  `recordatorios_eventos` tinyint(1) NOT NULL DEFAULT '1',
  `formato_hora` enum('12h','24h') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '24h',
  `primer_dia_semana` enum('lunes','domingo') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'lunes',
  `vista_predeterminada` enum('dia','semana','mes') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'semana',
  `idioma` varchar(5) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'es-ES',
  PRIMARY KEY (`usuario_id`),
  CONSTRAINT `fk_configuracion_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.configuracion_usuario: ~0 rows (aproximadamente)

-- Volcando estructura para procedimiento flowtime.crear_tarea_recurrente
DELIMITER //
CREATE PROCEDURE `crear_tarea_recurrente`(
    IN p_usuario_id INT,
    IN p_proyecto_id INT,
    IN p_titulo VARCHAR(255),
    IN p_descripcion TEXT,
    IN p_prioridad ENUM('baja', 'media', 'alta'),
    IN p_fecha_vencimiento DATE,
    IN p_tiempo_estimado INT,
    IN p_tipo_recurrencia ENUM('diario', 'semanal', 'mensual', 'anual'),
    IN p_intervalo INT,
    IN p_etiquetas VARCHAR(255)
)
BEGIN
    DECLARE v_tarea_id INT;
    DECLARE v_etiqueta VARCHAR(50);
    DECLARE v_etiqueta_id INT;
    DECLARE v_done INT DEFAULT FALSE;
    DECLARE v_cursor CURSOR FOR 
        SELECT TRIM(etiqueta) FROM (
            SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p_etiquetas, ',', numbers.n), ',', -1) etiqueta
            FROM (
                SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL
                SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL
                SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
            ) numbers
            WHERE numbers.n <= 1 + LENGTH(p_etiquetas) - LENGTH(REPLACE(p_etiquetas, ',', ''))
        ) etiquetas;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    
    -- Crear la tarea
    INSERT INTO `tareas` (
        `usuario_id`,
        `proyecto_id`,
        `titulo`,
        `descripcion`,
        `prioridad`,
        `estado`,
        `fecha_vencimiento`,
        `tiempo_estimado`,
        `recurrente`,
        `patron_recurrencia`
    )
    VALUES (
        p_usuario_id,
        p_proyecto_id,
        p_titulo,
        p_descripcion,
        p_prioridad,
        'pendiente',
        p_fecha_vencimiento,
        p_tiempo_estimado,
        1,
        JSON_OBJECT(
            'tipo', p_tipo_recurrencia,
            'intervalo', p_intervalo
        )
    );
    
    SET v_tarea_id = LAST_INSERT_ID();
    
    -- Procesar etiquetas
    IF p_etiquetas IS NOT NULL AND p_etiquetas != '' THEN
        OPEN v_cursor;
        read_loop: LOOP
            FETCH v_cursor INTO v_etiqueta;
            IF v_done THEN
                LEAVE read_loop;
            END IF;
            
            -- Buscar o crear la etiqueta
            SELECT `id` INTO v_etiqueta_id
            FROM `etiquetas`
            WHERE `usuario_id` = p_usuario_id AND `nombre` = v_etiqueta
            LIMIT 1;
            
            IF v_etiqueta_id IS NULL THEN
                -- Crear nueva etiqueta
                INSERT INTO `etiquetas` (`usuario_id`, `nombre`)
                VALUES (p_usuario_id, v_etiqueta);
                
                SET v_etiqueta_id = LAST_INSERT_ID();
            END IF;
            
            -- Asociar etiqueta a la tarea
            INSERT INTO `tareas_etiquetas` (`tarea_id`, `etiqueta_id`)
            VALUES (v_tarea_id, v_etiqueta_id);
        END LOOP;
        CLOSE v_cursor;
    END IF;
    
    -- Devolver el ID de la tarea creada
    SELECT v_tarea_id AS tarea_id;
END//
DELIMITER ;

-- Volcando estructura para procedimiento flowtime.crear_usuario
DELIMITER //
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
END//
DELIMITER ;

-- Volcando estructura para tabla flowtime.dependencias_gantt
CREATE TABLE IF NOT EXISTS `dependencias_gantt` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tarea_predecesora_id` int NOT NULL,
  `tarea_sucesora_id` int NOT NULL,
  `tipo` enum('fin_a_inicio','inicio_a_inicio','fin_a_fin','inicio_a_fin') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'fin_a_inicio',
  `retraso` int NOT NULL DEFAULT '0' COMMENT 'Retraso en días',
  PRIMARY KEY (`id`),
  KEY `fk_dependencias_predecesora_idx` (`tarea_predecesora_id`),
  KEY `fk_dependencias_sucesora_idx` (`tarea_sucesora_id`),
  CONSTRAINT `fk_dependencias_predecesora` FOREIGN KEY (`tarea_predecesora_id`) REFERENCES `tareas_gantt` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_dependencias_sucesora` FOREIGN KEY (`tarea_sucesora_id`) REFERENCES `tareas_gantt` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.dependencias_gantt: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.elementos_matriz
CREATE TABLE IF NOT EXISTS `elementos_matriz` (
  `id` int NOT NULL AUTO_INCREMENT,
  `matriz_id` int NOT NULL,
  `tarea_id` int DEFAULT NULL,
  `titulo` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci,
  `cuadrante` enum('urgente_importante','no_urgente_importante','urgente_no_importante','no_urgente_no_importante') COLLATE utf8mb4_unicode_ci NOT NULL,
  `orden` int NOT NULL DEFAULT '0',
  `completado` tinyint(1) NOT NULL DEFAULT '0',
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_elementos_matriz_idx` (`matriz_id`),
  KEY `fk_elementos_tareas_idx` (`tarea_id`),
  CONSTRAINT `fk_elementos_matriz` FOREIGN KEY (`matriz_id`) REFERENCES `matriz_eisenhower` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_elementos_tareas` FOREIGN KEY (`tarea_id`) REFERENCES `tareas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.elementos_matriz: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.estadisticas
CREATE TABLE IF NOT EXISTS `estadisticas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `fecha` date NOT NULL,
  `tareas_completadas` int NOT NULL DEFAULT '0',
  `tareas_pendientes` int NOT NULL DEFAULT '0',
  `tiempo_productivo` int NOT NULL DEFAULT '0',
  `tiempo_pomodoro` int NOT NULL DEFAULT '0',
  `tiempo_flowtime` int NOT NULL DEFAULT '0',
  `tiempo_timeboxing` int NOT NULL DEFAULT '0',
  `productividad` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `usuario_fecha` (`usuario_id`,`fecha`),
  KEY `fecha` (`fecha`),
  CONSTRAINT `fk_estadisticas_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.estadisticas: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.estadisticas_diarias
CREATE TABLE IF NOT EXISTS `estadisticas_diarias` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `fecha` date NOT NULL,
  `tareas_completadas` int NOT NULL DEFAULT '0',
  `tareas_creadas` int NOT NULL DEFAULT '0',
  `tiempo_productivo` int NOT NULL DEFAULT '0' COMMENT 'Tiempo en minutos',
  `tiempo_por_proyecto` text COLLATE utf8mb4_unicode_ci COMMENT 'JSON con tiempo por proyecto',
  `tiempo_por_tecnica` text COLLATE utf8mb4_unicode_ci COMMENT 'JSON con tiempo por técnica',
  `productividad` float DEFAULT NULL COMMENT 'Índice de productividad (0-100)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `usuario_fecha` (`usuario_id`,`fecha`),
  KEY `fk_estadisticas_usuarios_idx` (`usuario_id`),
  KEY `idx_estadisticas_fecha` (`fecha`),
  CONSTRAINT `fk_estadisticas_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.estadisticas_diarias: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.etiquetas
CREATE TABLE IF NOT EXISTS `etiquetas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `color` varchar(7) COLLATE utf8mb4_unicode_ci DEFAULT '#bfd7ea',
  PRIMARY KEY (`id`),
  KEY `fk_etiquetas_usuarios_idx` (`usuario_id`),
  CONSTRAINT `fk_etiquetas_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.etiquetas: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.eventos
CREATE TABLE IF NOT EXISTS `eventos` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `titulo` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci,
  `tipo` enum('trabajo','personal','otro') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'trabajo',
  `fecha_inicio` datetime NOT NULL,
  `fecha_fin` datetime NOT NULL,
  `todo_el_dia` tinyint(1) NOT NULL DEFAULT '0',
  `color` varchar(7) COLLATE utf8mb4_unicode_ci DEFAULT '#f5b7a5',
  `ubicacion` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `recordatorio` int DEFAULT NULL COMMENT 'Minutos antes del evento',
  `recurrente` tinyint(1) NOT NULL DEFAULT '0',
  `patron_recurrencia` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Patrón de recurrencia en formato JSON',
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_eventos_usuarios_idx` (`usuario_id`),
  KEY `idx_eventos_fecha` (`fecha_inicio`,`fecha_fin`),
  KEY `idx_eventos_usuario_fecha` (`usuario_id`,`fecha_inicio`),
  CONSTRAINT `fk_eventos_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.eventos: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.eventos_participantes
CREATE TABLE IF NOT EXISTS `eventos_participantes` (
  `evento_id` int NOT NULL,
  `usuario_id` int NOT NULL,
  `estado` enum('pendiente','aceptado','rechazado') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pendiente',
  `fecha_respuesta` datetime DEFAULT NULL,
  PRIMARY KEY (`evento_id`,`usuario_id`),
  KEY `fk_eventos_participantes_usuarios_idx` (`usuario_id`),
  CONSTRAINT `fk_eventos_participantes_eventos` FOREIGN KEY (`evento_id`) REFERENCES `eventos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_eventos_participantes_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.eventos_participantes: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.gantt
CREATE TABLE IF NOT EXISTS `gantt` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `proyecto_id` int NOT NULL,
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_gantt_usuarios_idx` (`usuario_id`),
  KEY `fk_gantt_proyectos_idx` (`proyecto_id`),
  CONSTRAINT `fk_gantt_proyectos` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_gantt_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.gantt: ~0 rows (aproximadamente)

-- Volcando estructura para procedimiento flowtime.generar_recomendaciones_productividad
DELIMITER //
CREATE PROCEDURE `generar_recomendaciones_productividad`(
    IN p_usuario_id INT
)
BEGIN
    DECLARE v_tecnica_mas_efectiva INT;
    DECLARE v_hora_mas_productiva INT;
    DECLARE v_dia_mas_productivo VARCHAR(20);
    DECLARE v_tiempo_promedio_tarea INT;
    
    -- Encontrar la técnica más efectiva para el usuario
    SELECT 
        sp.`tecnica_id` INTO v_tecnica_mas_efectiva
    FROM 
        `sesiones_productividad` sp
    WHERE 
        sp.`usuario_id` = p_usuario_id
        AND sp.`completada` = 1
        AND sp.`calificacion` IS NOT NULL
    GROUP BY 
        sp.`tecnica_id`
    ORDER BY 
        AVG(sp.`calificacion`) DESC
    LIMIT 1;
    
    -- Encontrar la hora más productiva
    SELECT 
        HOUR(sp.`fecha_inicio`) INTO v_hora_mas_productiva
    FROM 
        `sesiones_productividad` sp
    WHERE 
        sp.`usuario_id` = p_usuario_id
        AND sp.`completada` = 1
    GROUP BY 
        HOUR(sp.`fecha_inicio`)
    ORDER BY 
        COUNT(*) DESC
    LIMIT 1;
    
    -- Encontrar el día más productivo
    SELECT 
        DAYNAME(ed.`fecha`) INTO v_dia_mas_productivo
    FROM 
        `estadisticas_diarias` ed
    WHERE 
        ed.`usuario_id` = p_usuario_id
    GROUP BY 
        DAYNAME(ed.`fecha`)
    ORDER BY 
        AVG(ed.`productividad`) DESC
    LIMIT 1;
    
    -- Calcular tiempo promedio por tarea
    SELECT 
        AVG(t.`tiempo_real`) INTO v_tiempo_promedio_tarea
    FROM 
        `tareas` t
    WHERE 
        t.`usuario_id` = p_usuario_id
        AND t.`completada` = 1
        AND t.`tiempo_real` IS NOT NULL;
    
    -- Generar recomendaciones
    SELECT 
        'Técnica más efectiva' AS tipo_recomendacion,
        CONCAT('La técnica "', tp.`nombre`, '" ha sido la más efectiva para ti. Considera usarla más frecuentemente.') AS recomendacion,
        tp.`icono` AS icono
    FROM 
        `tecnicas_productividad` tp
    WHERE 
        tp.`id` = v_tecnica_mas_efectiva
    
    UNION ALL
    
    SELECT 
        'Hora más productiva' AS tipo_recomendacion,
        CONCAT('Eres más productivo alrededor de las ', v_hora_mas_productiva, ':00 horas. Programa tus tareas más importantes durante este horario.') AS recomendacion,
        'fa-clock' AS icono
    
    UNION ALL
    
    SELECT 
        'Día más productivo' AS tipo_recomendacion,
        CONCAT('El ', v_dia_mas_productivo, ' es tu día más productivo. Considera programar tareas importantes este día.') AS recomendacion,
        'fa-calendar-day' AS icono
    
    UNION ALL
    
    SELECT 
        'Estimación de tiempo' AS tipo_recomendacion,
        CONCAT('En promedio, tardas ', ROUND(v_tiempo_promedio_tarea/60), ' horas y ', MOD(ROUND(v_tiempo_promedio_tarea), 60), ' minutos en completar una tarea. Usa esta información para planificar mejor.') AS recomendacion,
        'fa-hourglass-half' AS icono
    
    UNION ALL
    
    SELECT 
        'Tareas pendientes' AS tipo_recomendacion,
        CONCAT('Tienes ', COUNT(*), ' tareas pendientes con alta prioridad. Considera enfocarte en ellas primero.') AS recomendacion,
        'fa-exclamation-triangle' AS icono
    FROM 
        `tareas`
    WHERE 
        `usuario_id` = p_usuario_id
        AND `estado` != 'completada'
        AND `prioridad` = 'alta';
END//
DELIMITER ;

-- Volcando estructura para tabla flowtime.log_accesos
CREATE TABLE IF NOT EXISTS `log_accesos` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int DEFAULT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ip` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_agent` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `accion` enum('login_exitoso','login_fallido','logout','registro','recuperacion') COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `usuario_id` (`usuario_id`),
  KEY `accion` (`accion`),
  KEY `fecha` (`fecha`),
  KEY `ip` (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.log_accesos: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.matriz_eisenhower
CREATE TABLE IF NOT EXISTS `matriz_eisenhower` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_matriz_usuarios_idx` (`usuario_id`),
  CONSTRAINT `fk_matriz_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.matriz_eisenhower: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.metas
CREATE TABLE IF NOT EXISTS `metas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `nombre` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci,
  `categoria` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_vencimiento` date DEFAULT NULL,
  `progreso` int NOT NULL DEFAULT '0',
  `completada` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `usuario_id` (`usuario_id`),
  KEY `completada` (`completada`),
  KEY `fecha_vencimiento` (`fecha_vencimiento`),
  CONSTRAINT `fk_metas_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.metas: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.notificaciones
CREATE TABLE IF NOT EXISTS `notificaciones` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `tipo` enum('tarea','evento','sistema','recordatorio') COLLATE utf8mb4_unicode_ci NOT NULL,
  `referencia_id` int DEFAULT NULL COMMENT 'ID de la tarea, evento, etc.',
  `titulo` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mensaje` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `leida` tinyint(1) NOT NULL DEFAULT '0',
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_lectura` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_notificaciones_usuarios_idx` (`usuario_id`),
  KEY `idx_notificaciones_leida` (`leida`),
  KEY `idx_notificaciones_usuario_leida` (`usuario_id`,`leida`),
  CONSTRAINT `fk_notificaciones_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.notificaciones: ~0 rows (aproximadamente)

-- Volcando estructura para procedimiento flowtime.obtener_analisis_productividad
DELIMITER //
CREATE PROCEDURE `obtener_analisis_productividad`(
    IN p_usuario_id INT,
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE
)
BEGIN
    -- Verificar fechas
    IF p_fecha_inicio IS NULL THEN
        SET p_fecha_inicio = DATE_SUB(CURDATE(), INTERVAL 30 DAY);
    END IF;
    
    IF p_fecha_fin IS NULL THEN
        SET p_fecha_fin = CURDATE();
    END IF;
    
    -- Resumen general
    SELECT 
        COUNT(DISTINCT DATE(t.`fecha_completada`)) AS dias_activos,
        COUNT(t.`id`) AS tareas_completadas,
        SUM(t.`tiempo_real`) AS tiempo_total_tareas,
        SUM(sp.`duracion`) AS tiempo_total_sesiones,
        AVG(ed.`productividad`) AS productividad_promedio
    FROM 
        `usuarios` u
    LEFT JOIN 
        `tareas` t ON u.`id` = t.`usuario_id` AND t.`completada` = 1 AND DATE(t.`fecha_completada`) BETWEEN p_fecha_inicio AND p_fecha_fin
    LEFT JOIN 
        `sesiones_productividad` sp ON u.`id` = sp.`usuario_id` AND sp.`completada` = 1 AND DATE(sp.`fecha_inicio`) BETWEEN p_fecha_inicio AND p_fecha_fin
    LEFT JOIN 
        `estadisticas_diarias` ed ON u.`id` = ed.`usuario_id` AND ed.`fecha` BETWEEN p_fecha_inicio AND p_fecha_fin
    WHERE 
        u.`id` = p_usuario_id;
    
    -- Productividad por día
    SELECT 
        ed.`fecha`,
        ed.`tareas_completadas`,
        ed.`tiempo_productivo`,
        ed.`productividad`
    FROM 
        `estadisticas_diarias` ed
    WHERE 
        ed.`usuario_id` = p_usuario_id
        AND ed.`fecha` BETWEEN p_fecha_inicio AND p_fecha_fin
    ORDER BY 
        ed.`fecha` ASC;
    
    -- Tiempo por proyecto
    SELECT 
        p.`nombre` AS proyecto,
        p.`color`,
        SUM(t.`tiempo_real`) AS tiempo_total,
        COUNT(t.`id`) AS tareas_completadas
    FROM 
        `proyectos` p
    JOIN 
        `tareas` t ON p.`id` = t.`proyecto_id`
    WHERE 
        p.`usuario_id` = p_usuario_id
        AND t.`completada` = 1
        AND DATE(t.`fecha_completada`) BETWEEN p_fecha_inicio AND p_fecha_fin
    GROUP BY 
        p.`id`
    ORDER BY 
        tiempo_total DESC;
    
    -- Tiempo por técnica de productividad
    SELECT 
        tp.`nombre` AS tecnica,
        tp.`icono`,
        SUM(sp.`duracion`) AS tiempo_total,
        COUNT(sp.`id`) AS sesiones_completadas,
        AVG(sp.`calificacion`) AS calificacion_promedio
    FROM 
        `tecnicas_productividad` tp
    JOIN 
        `sesiones_productividad` sp ON tp.`id` = sp.`tecnica_id`
    WHERE 
        sp.`usuario_id` = p_usuario_id
        AND sp.`completada` = 1
        AND DATE(sp.`fecha_inicio`) BETWEEN p_fecha_inicio AND p_fecha_fin
    GROUP BY 
        tp.`id`
    ORDER BY 
        tiempo_total DESC;
    
    -- Horas más productivas
    SELECT 
        HOUR(sp.`fecha_inicio`) AS hora,
        COUNT(sp.`id`) AS sesiones_completadas,
        SUM(sp.`duracion`) AS tiempo_total,
        AVG(sp.`calificacion`) AS calificacion_promedio
    FROM 
        `sesiones_productividad` sp
    WHERE 
        sp.`usuario_id` = p_usuario_id
        AND sp.`completada` = 1
        AND DATE(sp.`fecha_inicio`) BETWEEN p_fecha_inicio AND p_fecha_fin
    GROUP BY 
        hora
    ORDER BY 
        tiempo_total DESC;
    
    -- Días más productivos
    SELECT 
        DAYNAME(ed.`fecha`) AS dia_semana,
        AVG(ed.`productividad`) AS productividad_promedio,
        SUM(ed.`tareas_completadas`) AS tareas_completadas,
        SUM(ed.`tiempo_productivo`) AS tiempo_productivo
    FROM 
        `estadisticas_diarias` ed
    WHERE 
        ed.`usuario_id` = p_usuario_id
        AND ed.`fecha` BETWEEN p_fecha_inicio AND p_fecha_fin
    GROUP BY 
        dia_semana
    ORDER BY 
        productividad_promedio DESC;
END//
DELIMITER ;

-- Volcando estructura para procedimiento flowtime.obtener_dashboard_usuario
DELIMITER //
CREATE PROCEDURE `obtener_dashboard_usuario`(
    IN p_usuario_id INT
)
BEGIN
    -- Verificar tipo de cuenta
    DECLARE v_tipo_cuenta VARCHAR(20);
    
    SELECT `tipo_cuenta` INTO v_tipo_cuenta
    FROM `usuarios`
    WHERE `id` = p_usuario_id;
    
    -- Información básica del usuario
    SELECT 
        u.`id`,
        u.`nombre`,
        u.`apellido`,
        u.`email`,
        u.`tipo_cuenta`,
        u.`fecha_registro`,
        u.`ultimo_acceso`,
        c.`notificaciones_email`,
        c.`notificaciones_push`,
        c.`tema`
    FROM 
        `usuarios` u
    JOIN 
        `configuracion_usuario` c ON u.`id` = c.`usuario_id`
    WHERE 
        u.`id` = p_usuario_id;
    
    -- Resumen de tareas
    SELECT 
        COUNT(*) AS total_tareas,
        SUM(CASE WHEN `estado` = 'pendiente' THEN 1 ELSE 0 END) AS tareas_pendientes,
        SUM(CASE WHEN `estado` = 'en_progreso' THEN 1 ELSE 0 END) AS tareas_en_progreso,
        SUM(CASE WHEN `estado` = 'completada' THEN 1 ELSE 0 END) AS tareas_completadas,
        SUM(CASE WHEN `fecha_vencimiento` < CURDATE() AND `estado` != 'completada' THEN 1 ELSE 0 END) AS tareas_vencidas,
        SUM(CASE WHEN `fecha_vencimiento` = CURDATE() AND `estado` != 'completada' THEN 1 ELSE 0 END) AS tareas_hoy
    FROM 
        `tareas`
    WHERE 
        `usuario_id` = p_usuario_id;
    
    -- Tareas para hoy
    SELECT 
        t.`id`,
        t.`titulo`,
        t.`prioridad`,
        t.`estado`,
        p.`nombre` AS proyecto_nombre,
        p.`color` AS proyecto_color
    FROM 
        `tareas` t
    LEFT JOIN 
        `proyectos` p ON t.`proyecto_id` = p.`id`
    WHERE 
        t.`usuario_id` = p_usuario_id
        AND t.`fecha_vencimiento` = CURDATE()
        AND t.`estado` != 'completada'
    ORDER BY 
        FIELD(t.`prioridad`, 'alta', 'media', 'baja'),
        t.`fecha_vencimiento` ASC
    LIMIT 5;
    
    -- Eventos para hoy
    SELECT 
        `id`,
        `titulo`,
        `fecha_inicio`,
        `fecha_fin`,
        `tipo`,
        `color`,
        `ubicacion`
    FROM 
        `eventos`
    WHERE 
        `usuario_id` = p_usuario_id
        AND DATE(`fecha_inicio`) = CURDATE()
    ORDER BY 
        `fecha_inicio` ASC;
    
    -- Estadísticas de productividad (últimos 7 días)
    SELECT 
        `fecha`,
        `tareas_completadas`,
        `tiempo_productivo`,
        `productividad`
    FROM 
        `estadisticas_diarias`
    WHERE 
        `usuario_id` = p_usuario_id
        AND `fecha` BETWEEN DATE_SUB(CURDATE(), INTERVAL 6 DAY) AND CURDATE()
    ORDER BY 
        `fecha` ASC;
    
    -- Notificaciones no leídas
    SELECT 
        `id`,
        `tipo`,
        `referencia_id`,
        `titulo`,
        `mensaje`,
        `fecha_creacion`
    FROM 
        `notificaciones`
    WHERE 
        `usuario_id` = p_usuario_id
        AND `leida` = 0
    ORDER BY 
        `fecha_creacion` DESC
    LIMIT 10;
    
    -- Proyectos activos
    SELECT 
        p.`id`,
        p.`nombre`,
        p.`color`,
        COUNT(t.`id`) AS total_tareas,
        SUM(CASE WHEN t.`estado` = 'completada' THEN 1 ELSE 0 END) AS tareas_completadas,
        CASE 
            WHEN COUNT(t.`id`) > 0 THEN 
                ROUND((SUM(CASE WHEN t.`estado` = 'completada' THEN 1 ELSE 0 END) / COUNT(t.`id`)) * 100, 2)
            ELSE 0
        END AS porcentaje_completado
    FROM 
        `proyectos` p
    LEFT JOIN 
        `tareas` t ON p.`id` = t.`proyecto_id`
    WHERE 
        p.`usuario_id` = p_usuario_id
        AND p.`estado` != 'archivado'
    GROUP BY 
        p.`id`
    ORDER BY 
        porcentaje_completado ASC
    LIMIT 5;
    
    -- Limitar resultados según tipo de cuenta
    IF v_tipo_cuenta = 'gratuito' THEN
        -- Aplicar límites para cuenta gratuita
        SELECT 'gratuito' AS tipo_cuenta_actual, 
               'Actualiza a Premium para acceder a todas las funcionalidades' AS mensaje_premium;
    ELSE
        -- Sin límites para cuenta premium
        SELECT 'premium' AS tipo_cuenta_actual,
               'Estás disfrutando de todas las funcionalidades premium' AS mensaje_premium;
    END IF;
END//
DELIMITER ;

-- Volcando estructura para procedimiento flowtime.obtener_estadisticas_dashboard
DELIMITER //
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
END//
DELIMITER ;

-- Volcando estructura para tabla flowtime.proyectos
CREATE TABLE IF NOT EXISTS `proyectos` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci,
  `color` varchar(7) COLLATE utf8mb4_unicode_ci DEFAULT '#a3c9a8',
  `fecha_inicio` date DEFAULT NULL,
  `fecha_fin` date DEFAULT NULL,
  `estado` enum('pendiente','en_progreso','completado','archivado') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pendiente',
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_proyectos_usuarios_idx` (`usuario_id`),
  CONSTRAINT `fk_proyectos_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.proyectos: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.restablecimiento_password
CREATE TABLE IF NOT EXISTS `restablecimiento_password` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_expiracion` datetime NOT NULL,
  `utilizado` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_restablecimiento_usuarios_idx` (`usuario_id`),
  CONSTRAINT `fk_restablecimiento_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.restablecimiento_password: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.sesiones
CREATE TABLE IF NOT EXISTS `sesiones` (
  `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `usuario_id` int NOT NULL,
  `ip` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_agent` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `ultimo_acceso` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `usuario_id` (`usuario_id`),
  KEY `ultimo_acceso` (`ultimo_acceso`),
  CONSTRAINT `fk_sesiones_activas_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.sesiones: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.sesiones_productividad
CREATE TABLE IF NOT EXISTS `sesiones_productividad` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `tecnica_id` int NOT NULL,
  `tarea_id` int DEFAULT NULL,
  `fecha_inicio` datetime NOT NULL,
  `fecha_fin` datetime DEFAULT NULL,
  `duracion` int DEFAULT NULL COMMENT 'Duración en minutos',
  `completada` tinyint(1) NOT NULL DEFAULT '0',
  `notas` text COLLATE utf8mb4_unicode_ci,
  `calificacion` int DEFAULT NULL COMMENT 'Calificación de 1 a 5',
  PRIMARY KEY (`id`),
  KEY `fk_sesiones_usuarios_idx` (`usuario_id`),
  KEY `fk_sesiones_tecnicas_idx` (`tecnica_id`),
  KEY `fk_sesiones_tareas_idx` (`tarea_id`),
  KEY `idx_sesiones_fecha` (`fecha_inicio`),
  KEY `idx_sesiones_usuario_tecnica` (`usuario_id`,`tecnica_id`),
  CONSTRAINT `fk_sesiones_tareas` FOREIGN KEY (`tarea_id`) REFERENCES `tareas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_sesiones_tecnicas` FOREIGN KEY (`tecnica_id`) REFERENCES `tecnicas_productividad` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_sesiones_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.sesiones_productividad: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.sesiones_tecnicas
CREATE TABLE IF NOT EXISTS `sesiones_tecnicas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `tarea_id` int DEFAULT NULL,
  `meta_id` int DEFAULT NULL,
  `tecnica` enum('pomodoro','flowtime','timeboxing') COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha_inicio` datetime NOT NULL,
  `fecha_fin` datetime DEFAULT NULL,
  `duracion` int DEFAULT NULL,
  `completada` tinyint(1) NOT NULL DEFAULT '0',
  `notas` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  KEY `usuario_id` (`usuario_id`),
  KEY `tarea_id` (`tarea_id`),
  KEY `meta_id` (`meta_id`),
  KEY `tecnica` (`tecnica`),
  KEY `fecha_inicio` (`fecha_inicio`),
  CONSTRAINT `fk_sesiones_meta` FOREIGN KEY (`meta_id`) REFERENCES `metas` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sesiones_tarea` FOREIGN KEY (`tarea_id`) REFERENCES `tareas` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sesiones_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.sesiones_tecnicas: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.sesiones_usuario
CREATE TABLE IF NOT EXISTS `sesiones_usuario` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ip` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL,
  `agente_usuario` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_expiracion` datetime NOT NULL,
  `activa` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `fk_sesiones_usuarios_idx` (`usuario_id`),
  CONSTRAINT `fk_sesiones_usuarios_idx` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.sesiones_usuario: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.subtareas
CREATE TABLE IF NOT EXISTS `subtareas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tarea_id` int NOT NULL,
  `titulo` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `completada` tinyint(1) NOT NULL DEFAULT '0',
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_subtareas_tareas_idx` (`tarea_id`),
  CONSTRAINT `fk_subtareas_tareas` FOREIGN KEY (`tarea_id`) REFERENCES `tareas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.subtareas: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.suscripciones
CREATE TABLE IF NOT EXISTS `suscripciones` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `plan` enum('mensual','anual') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'mensual',
  `fecha_inicio` datetime NOT NULL,
  `fecha_fin` datetime NOT NULL,
  `estado` enum('activa','cancelada','expirada') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'activa',
  `metodo_pago` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `referencia_pago` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `usuario_id` (`usuario_id`),
  KEY `estado` (`estado`),
  KEY `fecha_fin` (`fecha_fin`),
  CONSTRAINT `fk_suscripciones_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.suscripciones: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.tareas
CREATE TABLE IF NOT EXISTS `tareas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` int NOT NULL,
  `proyecto_id` int DEFAULT NULL,
  `titulo` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci,
  `prioridad` enum('baja','media','alta') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'media',
  `estado` enum('pendiente','en_progreso','completada','archivada') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pendiente',
  `fecha_vencimiento` date DEFAULT NULL,
  `tiempo_estimado` int DEFAULT NULL COMMENT 'Tiempo estimado en minutos',
  `tiempo_real` int DEFAULT NULL COMMENT 'Tiempo real en minutos',
  `completada` tinyint(1) NOT NULL DEFAULT '0',
  `fecha_completada` datetime DEFAULT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `recurrente` tinyint(1) NOT NULL DEFAULT '0',
  `patron_recurrencia` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Patrón de recurrencia en formato JSON',
  PRIMARY KEY (`id`),
  KEY `fk_tareas_usuarios_idx` (`usuario_id`),
  KEY `fk_tareas_proyectos_idx` (`proyecto_id`),
  KEY `idx_tareas_fecha_vencimiento` (`fecha_vencimiento`),
  KEY `idx_tareas_estado` (`estado`),
  KEY `idx_tareas_prioridad` (`prioridad`),
  KEY `idx_tareas_usuario_estado` (`usuario_id`,`estado`),
  KEY `idx_tareas_usuario_fecha` (`usuario_id`,`fecha_vencimiento`),
  CONSTRAINT `fk_tareas_proyectos` FOREIGN KEY (`proyecto_id`) REFERENCES `proyectos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_tareas_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.tareas: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.tareas_etiquetas
CREATE TABLE IF NOT EXISTS `tareas_etiquetas` (
  `tarea_id` int NOT NULL,
  `etiqueta_id` int NOT NULL,
  PRIMARY KEY (`tarea_id`,`etiqueta_id`),
  KEY `fk_tareas_etiquetas_etiquetas_idx` (`etiqueta_id`),
  CONSTRAINT `fk_tareas_etiquetas_etiquetas` FOREIGN KEY (`etiqueta_id`) REFERENCES `etiquetas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_tareas_etiquetas_tareas` FOREIGN KEY (`tarea_id`) REFERENCES `tareas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.tareas_etiquetas: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.tareas_gantt
CREATE TABLE IF NOT EXISTS `tareas_gantt` (
  `id` int NOT NULL AUTO_INCREMENT,
  `gantt_id` int NOT NULL,
  `tarea_id` int DEFAULT NULL,
  `nombre` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci,
  `fecha_inicio` date NOT NULL,
  `fecha_fin` date NOT NULL,
  `progreso` int NOT NULL DEFAULT '0' COMMENT 'Progreso en porcentaje (0-100)',
  `tarea_padre_id` int DEFAULT NULL COMMENT 'ID de la tarea padre en el gantt',
  `orden` int NOT NULL DEFAULT '0',
  `color` varchar(7) COLLATE utf8mb4_unicode_ci DEFAULT '#a3c9a8',
  PRIMARY KEY (`id`),
  KEY `fk_tareas_gantt_gantt_idx` (`gantt_id`),
  KEY `fk_tareas_gantt_tareas_idx` (`tarea_id`),
  KEY `fk_tareas_gantt_padre_idx` (`tarea_padre_id`),
  CONSTRAINT `fk_tareas_gantt_gantt` FOREIGN KEY (`gantt_id`) REFERENCES `gantt` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_tareas_gantt_padre` FOREIGN KEY (`tarea_padre_id`) REFERENCES `tareas_gantt` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_tareas_gantt_tareas` FOREIGN KEY (`tarea_id`) REFERENCES `tareas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.tareas_gantt: ~0 rows (aproximadamente)

-- Volcando estructura para tabla flowtime.tecnicas_productividad
CREATE TABLE IF NOT EXISTS `tecnicas_productividad` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `instrucciones` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `duracion_predeterminada` int DEFAULT NULL COMMENT 'Duración en minutos',
  `icono` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.tecnicas_productividad: ~5 rows (aproximadamente)
INSERT INTO `tecnicas_productividad` (`id`, `nombre`, `descripcion`, `instrucciones`, `duracion_predeterminada`, `icono`) VALUES
	(1, 'Pomodoro', 'Técnica de gestión del tiempo que utiliza intervalos de trabajo de 25 minutos seguidos de descansos cortos.', '1. Elige una tarea a realizar\n2. Configura el temporizador a 25 minutos\n3. Trabaja en la tarea hasta que suene el temporizador\n4. Toma un descanso corto de 5 minutos\n5. Después de 4 pomodoros, toma un descanso más largo de 15-30 minutos', 25, 'fa-clock'),
	(2, 'Flowtime', 'Técnica que adapta los intervalos de trabajo y descanso a tu flujo natural de productividad.', '1. Anota la hora de inicio cuando comiences a trabajar\n2. Trabaja hasta que sientas que necesitas un descanso\n3. Anota la hora de finalización y la duración del trabajo\n4. Toma un descanso proporcional al tiempo trabajado (1:5)\n5. Repite el proceso', NULL, 'fa-wave-square'),
	(3, 'Técnica (10+2)*5', 'Método que alterna 10 minutos de trabajo intenso con 2 minutos de descanso, repetido 5 veces.', '1. Trabaja intensamente durante 10 minutos\n2. Descansa durante 2 minutos\n3. Repite este ciclo 5 veces (1 hora en total)', 10, 'fa-stopwatch'),
	(4, 'Método 90/30', 'Técnica que aprovecha los ciclos naturales de atención, trabajando 90 minutos seguidos de 30 minutos de descanso.', '1. Trabaja concentrado durante 90 minutos\n2. Toma un descanso de 30 minutos\n3. Repite según sea necesario', 90, 'fa-hourglass-half'),
	(5, 'Técnica 52/17', 'Basada en estudios que muestran que las personas más productivas trabajan 52 minutos y descansan 17.', '1. Trabaja con total concentración durante 52 minutos\n2. Toma un descanso completo de 17 minutos\n3. Repite el ciclo', 52, 'fa-business-time');

-- Volcando estructura para tabla flowtime.usuarios
CREATE TABLE IF NOT EXISTS `usuarios` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `apellido` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `foto_perfil` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_registro` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ultimo_acceso` datetime DEFAULT NULL,
  `estado` enum('activo','inactivo','suspendido') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'activo',
  `tema` enum('claro','oscuro') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'claro',
  `zona_horaria` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT 'Europe/Madrid',
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla flowtime.usuarios: ~0 rows (aproximadamente)

-- Volcando estructura para vista flowtime.vista_calendario_completo
-- Creando tabla temporal para superar errores de dependencia de VIEW
CREATE TABLE `vista_calendario_completo` (
	`tipo` VARCHAR(6) NOT NULL COLLATE 'utf8mb4_general_ci',
	`id` INT(10) NOT NULL,
	`usuario_id` INT(10) NOT NULL,
	`titulo` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`descripcion` MEDIUMTEXT NULL COLLATE 'utf8mb4_unicode_ci',
	`fecha_inicio` VARCHAR(19) NULL COLLATE 'utf8mb4_general_ci',
	`fecha_fin` VARCHAR(19) NULL COLLATE 'utf8mb4_general_ci',
	`todo_el_dia` BIGINT(19) NOT NULL,
	`color` VARCHAR(7) NULL COLLATE 'utf8mb4_unicode_ci',
	`categoria` VARCHAR(8) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`ubicacion` VARCHAR(255) NULL COLLATE 'utf8mb4_unicode_ci',
	`prioridad` ENUM('baja','media','alta') NULL COLLATE 'utf8mb4_unicode_ci',
	`estado` ENUM('pendiente','en_progreso','completada','archivada') NULL COLLATE 'utf8mb4_unicode_ci',
	`proyecto_id` INT(10) NULL,
	`proyecto_nombre` VARCHAR(100) NULL COLLATE 'utf8mb4_unicode_ci'
) ENGINE=MyISAM;

-- Volcando estructura para vista flowtime.vista_eventos
-- Creando tabla temporal para superar errores de dependencia de VIEW
CREATE TABLE `vista_eventos` (
	`id` INT(10) NOT NULL,
	`usuario_id` INT(10) NOT NULL,
	`titulo` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`descripcion` TEXT NULL COLLATE 'utf8mb4_unicode_ci',
	`tipo` ENUM('trabajo','personal','otro') NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`fecha_inicio` DATETIME NOT NULL,
	`fecha_fin` DATETIME NOT NULL,
	`todo_el_dia` TINYINT(1) NOT NULL,
	`color` VARCHAR(7) NULL COLLATE 'utf8mb4_unicode_ci',
	`ubicacion` VARCHAR(255) NULL COLLATE 'utf8mb4_unicode_ci',
	`url` VARCHAR(255) NULL COLLATE 'utf8mb4_unicode_ci',
	`recordatorio` INT(10) NULL COMMENT 'Minutos antes del evento',
	`recurrente` TINYINT(1) NOT NULL,
	`patron_recurrencia` VARCHAR(255) NULL COMMENT 'Patrón de recurrencia en formato JSON' COLLATE 'utf8mb4_unicode_ci',
	`total_participantes` BIGINT(19) NOT NULL,
	`participantes_aceptados` DECIMAL(23,0) NULL
) ENGINE=MyISAM;

-- Volcando estructura para vista flowtime.vista_eventos_completa
-- Creando tabla temporal para superar errores de dependencia de VIEW
CREATE TABLE `vista_eventos_completa` (
	`id` INT(10) NULL,
	`usuario_id` INT(10) NULL,
	`usuario_nombre` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`usuario_apellido` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`titulo` VARCHAR(255) NULL COLLATE 'utf8mb4_unicode_ci',
	`descripcion` TEXT NULL COLLATE 'utf8mb4_unicode_ci',
	`tipo` ENUM('trabajo','personal','otro') NULL COLLATE 'utf8mb4_unicode_ci',
	`fecha_inicio` DATETIME NULL,
	`fecha_fin` DATETIME NULL,
	`todo_el_dia` TINYINT(1) NULL,
	`color` VARCHAR(7) NULL COLLATE 'utf8mb4_unicode_ci',
	`ubicacion` VARCHAR(255) NULL COLLATE 'utf8mb4_unicode_ci',
	`url` VARCHAR(255) NULL COLLATE 'utf8mb4_unicode_ci',
	`recordatorio` INT(10) NULL COMMENT 'Minutos antes del evento',
	`recurrente` TINYINT(1) NULL,
	`patron_recurrencia` VARCHAR(255) NULL COMMENT 'Patrón de recurrencia en formato JSON' COLLATE 'utf8mb4_unicode_ci',
	`fecha_creacion` DATETIME NULL,
	`fecha_modificacion` DATETIME NULL,
	`total_participantes` BIGINT(19) NULL,
	`participantes_aceptados` BIGINT(19) NULL,
	`participantes_rechazados` BIGINT(19) NULL,
	`participantes_pendientes` BIGINT(19) NULL,
	`participantes_nombres` TEXT NULL COLLATE 'utf8mb4_unicode_ci'
) ENGINE=MyISAM;

-- Volcando estructura para vista flowtime.vista_matriz_eisenhower_completa
-- Creando tabla temporal para superar errores de dependencia de VIEW
CREATE TABLE `vista_matriz_eisenhower_completa` (
	`matriz_id` INT(10) NOT NULL,
	`usuario_id` INT(10) NOT NULL,
	`usuario_nombre` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`usuario_apellido` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`matriz_nombre` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`fecha_creacion` DATETIME NOT NULL,
	`fecha_modificacion` DATETIME NOT NULL,
	`elemento_id` INT(10) NULL,
	`tarea_id` INT(10) NULL,
	`tarea_titulo` VARCHAR(255) NULL COLLATE 'utf8mb4_unicode_ci',
	`elemento_titulo` VARCHAR(255) NULL COLLATE 'utf8mb4_unicode_ci',
	`elemento_descripcion` TEXT NULL COLLATE 'utf8mb4_unicode_ci',
	`cuadrante` ENUM('urgente_importante','no_urgente_importante','urgente_no_importante','no_urgente_no_importante') NULL COLLATE 'utf8mb4_unicode_ci',
	`orden` INT(10) NULL,
	`completado` TINYINT(1) NULL,
	`elemento_fecha_creacion` DATETIME NULL,
	`elemento_fecha_modificacion` DATETIME NULL,
	`accion_recomendada` VARCHAR(13) NULL COLLATE 'utf8mb4_general_ci'
) ENGINE=MyISAM;

-- Volcando estructura para vista flowtime.vista_notificaciones_detalle
-- Creando tabla temporal para superar errores de dependencia de VIEW
CREATE TABLE `vista_notificaciones_detalle` (
	`id` INT(10) NOT NULL,
	`usuario_id` INT(10) NOT NULL,
	`usuario_nombre` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`usuario_apellido` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`tipo` ENUM('tarea','evento','sistema','recordatorio') NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`referencia_id` INT(10) NULL COMMENT 'ID de la tarea, evento, etc.',
	`titulo` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`mensaje` TEXT NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`leida` TINYINT(1) NOT NULL,
	`fecha_creacion` DATETIME NOT NULL,
	`fecha_lectura` DATETIME NULL,
	`referencia_titulo` VARCHAR(255) NULL COLLATE 'utf8mb4_unicode_ci',
	`url_redireccion` VARCHAR(34) NULL COLLATE 'utf8mb4_general_ci'
) ENGINE=MyISAM;

-- Volcando estructura para vista flowtime.vista_productividad_usuario
-- Creando tabla temporal para superar errores de dependencia de VIEW
CREATE TABLE `vista_productividad_usuario` (
	`usuario_id` INT(10) NOT NULL,
	`nombre` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`apellido` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`total_tareas` BIGINT(19) NOT NULL,
	`tareas_completadas` DECIMAL(23,0) NULL,
	`tareas_pendientes` DECIMAL(23,0) NULL,
	`tiempo_total_tareas` DECIMAL(32,0) NULL,
	`tiempo_total_sesiones` DECIMAL(32,0) NULL,
	`total_sesiones_productividad` BIGINT(19) NOT NULL,
	`calificacion_promedio` DECIMAL(14,4) NULL
) ENGINE=MyISAM;

-- Volcando estructura para vista flowtime.vista_proyectos_progreso
-- Creando tabla temporal para superar errores de dependencia de VIEW
CREATE TABLE `vista_proyectos_progreso` (
	`id` INT(10) NOT NULL,
	`usuario_id` INT(10) NOT NULL,
	`usuario_nombre` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`usuario_apellido` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`nombre` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`descripcion` TEXT NULL COLLATE 'utf8mb4_unicode_ci',
	`color` VARCHAR(7) NULL COLLATE 'utf8mb4_unicode_ci',
	`fecha_inicio` DATE NULL,
	`fecha_fin` DATE NULL,
	`estado` ENUM('pendiente','en_progreso','completado','archivado') NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`fecha_creacion` DATETIME NOT NULL,
	`fecha_modificacion` DATETIME NOT NULL,
	`total_tareas` BIGINT(19) NOT NULL,
	`tareas_completadas` DECIMAL(23,0) NULL,
	`tareas_en_progreso` DECIMAL(23,0) NULL,
	`tareas_pendientes` DECIMAL(23,0) NULL,
	`porcentaje_completado` DECIMAL(29,2) NULL,
	`estado_vencimiento` VARCHAR(21) NULL COLLATE 'utf8mb4_general_ci'
) ENGINE=MyISAM;

-- Volcando estructura para vista flowtime.vista_sesiones_productividad_completa
-- Creando tabla temporal para superar errores de dependencia de VIEW
CREATE TABLE `vista_sesiones_productividad_completa` (
	`id` INT(10) NOT NULL,
	`usuario_id` INT(10) NOT NULL,
	`usuario_nombre` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`usuario_apellido` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`tecnica_id` INT(10) NOT NULL,
	`tecnica_nombre` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`tecnica_descripcion` TEXT NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`tecnica_icono` VARCHAR(50) NULL COLLATE 'utf8mb4_unicode_ci',
	`tarea_id` INT(10) NULL,
	`tarea_titulo` VARCHAR(255) NULL COLLATE 'utf8mb4_unicode_ci',
	`proyecto_id` INT(10) NULL,
	`proyecto_nombre` VARCHAR(100) NULL COLLATE 'utf8mb4_unicode_ci',
	`fecha_inicio` DATETIME NOT NULL,
	`fecha_fin` DATETIME NULL,
	`duracion` INT(10) NULL COMMENT 'Duración en minutos',
	`completada` TINYINT(1) NOT NULL,
	`notas` TEXT NULL COLLATE 'utf8mb4_unicode_ci',
	`calificacion` INT(10) NULL COMMENT 'Calificación de 1 a 5',
	`duracion_formateada` VARCHAR(35) NULL COLLATE 'utf8mb4_general_ci',
	`duracion_calculada` BIGINT(19) NULL
) ENGINE=MyISAM;

-- Volcando estructura para vista flowtime.vista_tareas
-- Creando tabla temporal para superar errores de dependencia de VIEW
CREATE TABLE `vista_tareas` (
	`id` INT(10) NOT NULL,
	`usuario_id` INT(10) NOT NULL,
	`proyecto_id` INT(10) NULL,
	`proyecto_nombre` VARCHAR(100) NULL COLLATE 'utf8mb4_unicode_ci',
	`proyecto_color` VARCHAR(7) NULL COLLATE 'utf8mb4_unicode_ci',
	`titulo` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`descripcion` TEXT NULL COLLATE 'utf8mb4_unicode_ci',
	`prioridad` ENUM('baja','media','alta') NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`estado` ENUM('pendiente','en_progreso','completada','archivada') NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`fecha_vencimiento` DATE NULL,
	`tiempo_estimado` INT(10) NULL COMMENT 'Tiempo estimado en minutos',
	`tiempo_real` INT(10) NULL COMMENT 'Tiempo real en minutos',
	`completada` TINYINT(1) NOT NULL,
	`fecha_completada` DATETIME NULL,
	`fecha_creacion` DATETIME NOT NULL,
	`fecha_modificacion` DATETIME NOT NULL,
	`etiquetas` TEXT NULL COLLATE 'utf8mb4_unicode_ci'
) ENGINE=MyISAM;

-- Volcando estructura para vista flowtime.vista_tareas_completa
-- Creando tabla temporal para superar errores de dependencia de VIEW
CREATE TABLE `vista_tareas_completa` (
	`id` INT(10) NULL,
	`usuario_id` INT(10) NULL,
	`usuario_nombre` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`usuario_apellido` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`proyecto_id` INT(10) NULL,
	`proyecto_nombre` VARCHAR(100) NULL COLLATE 'utf8mb4_unicode_ci',
	`proyecto_color` VARCHAR(7) NULL COLLATE 'utf8mb4_unicode_ci',
	`titulo` VARCHAR(255) NULL COLLATE 'utf8mb4_unicode_ci',
	`descripcion` TEXT NULL COLLATE 'utf8mb4_unicode_ci',
	`prioridad` ENUM('baja','media','alta') NULL COLLATE 'utf8mb4_unicode_ci',
	`estado` ENUM('pendiente','en_progreso','completada','archivada') NULL COLLATE 'utf8mb4_unicode_ci',
	`fecha_vencimiento` DATE NULL,
	`tiempo_estimado` INT(10) NULL COMMENT 'Tiempo estimado en minutos',
	`tiempo_real` INT(10) NULL COMMENT 'Tiempo real en minutos',
	`completada` TINYINT(1) NULL,
	`fecha_completada` DATETIME NULL,
	`fecha_creacion` DATETIME NULL,
	`fecha_modificacion` DATETIME NULL,
	`recurrente` TINYINT(1) NULL,
	`patron_recurrencia` VARCHAR(255) NULL COMMENT 'Patrón de recurrencia en formato JSON' COLLATE 'utf8mb4_unicode_ci',
	`total_subtareas` BIGINT(19) NULL,
	`subtareas_completadas` BIGINT(19) NULL,
	`etiquetas` TEXT NULL COLLATE 'utf8mb4_unicode_ci',
	`etiquetas_colores` TEXT NULL COLLATE 'utf8mb4_unicode_ci'
) ENGINE=MyISAM;

-- Volcando estructura para disparador flowtime.actualizar_estadisticas_sesion_productividad
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO';
DELIMITER //
CREATE TRIGGER `actualizar_estadisticas_sesion_productividad` AFTER UPDATE ON `sesiones_productividad` FOR EACH ROW BEGIN
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
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Volcando estructura para disparador flowtime.actualizar_estadisticas_sesion_productividad_optimizado
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO';
DELIMITER //
CREATE TRIGGER `actualizar_estadisticas_sesion_productividad_optimizado` AFTER UPDATE ON `sesiones_productividad` FOR EACH ROW BEGIN
    DECLARE v_fecha DATE;
    DECLARE v_tecnica_nombre VARCHAR(100);
    
    -- Si la sesión se acaba de completar
    IF NEW.`completada` = 1 AND OLD.`completada` = 0 AND NEW.`duracion` IS NOT NULL THEN
        SET v_fecha = DATE(NEW.`fecha_inicio`);
        
        -- Obtener nombre de la técnica
        SELECT `nombre` INTO v_tecnica_nombre 
        FROM `tecnicas_productividad` 
        WHERE `id` = NEW.`tecnica_id`;
        
        -- Actualizar o insertar estadísticas diarias
        INSERT INTO `estadisticas_diarias` (`usuario_id`, `fecha`, `tiempo_productivo`, `tiempo_por_tecnica`)
        VALUES (
            NEW.`usuario_id`, 
            v_fecha, 
            NEW.`duracion`,
            JSON_OBJECT(v_tecnica_nombre, NEW.`duracion`)
        )
        ON DUPLICATE KEY UPDATE
            `tiempo_productivo` = `tiempo_productivo` + NEW.`duracion`,
            `tiempo_por_tecnica` = JSON_MERGE_PATCH(
                IFNULL(`tiempo_por_tecnica`, JSON_OBJECT()),
                JSON_OBJECT(v_tecnica_nombre, 
                    NEW.`duracion` + 
                    IFNULL(JSON_EXTRACT(`tiempo_por_tecnica`, CONCAT('$."', v_tecnica_nombre, '"')), 0)
                )
            );
        
        -- Si la sesión está asociada a una tarea, actualizar el tiempo real de la tarea
        IF NEW.`tarea_id` IS NOT NULL THEN
            UPDATE `tareas`
            SET `tiempo_real` = IFNULL(`tiempo_real`, 0) + NEW.`duracion`
            WHERE `id` = NEW.`tarea_id`;
        END IF;
    END IF;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Volcando estructura para disparador flowtime.actualizar_estadisticas_tarea_completada
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO';
DELIMITER //
CREATE TRIGGER `actualizar_estadisticas_tarea_completada` AFTER UPDATE ON `tareas` FOR EACH ROW BEGIN
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
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Volcando estructura para disparador flowtime.actualizar_estadisticas_tarea_completada_optimizado
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO';
DELIMITER //
CREATE TRIGGER `actualizar_estadisticas_tarea_completada_optimizado` AFTER UPDATE ON `tareas` FOR EACH ROW BEGIN
    DECLARE v_fecha DATE;
    DECLARE v_tiempo_proyecto JSON;
    DECLARE v_proyecto_nombre VARCHAR(100);
    
    -- Si la tarea se acaba de marcar como completada
    IF NEW.`completada` = 1 AND OLD.`completada` = 0 THEN
        -- Usar la fecha actual si no se proporciona fecha_completada
        IF NEW.`fecha_completada` IS NULL THEN
            SET v_fecha = CURDATE();
        ELSE
            SET v_fecha = DATE(NEW.`fecha_completada`);
        END IF;
        
        -- Obtener nombre del proyecto si existe
        IF NEW.`proyecto_id` IS NOT NULL THEN
            SELECT `nombre` INTO v_proyecto_nombre 
            FROM `proyectos` 
            WHERE `id` = NEW.`proyecto_id`;
        END IF;
        
        -- Actualizar o insertar estadísticas diarias
        INSERT INTO `estadisticas_diarias` (`usuario_id`, `fecha`, `tareas_completadas`, `tiempo_productivo`, `tiempo_por_proyecto`)
        VALUES (
            NEW.`usuario_id`, 
            v_fecha, 
            1, 
            IFNULL(NEW.`tiempo_real`, 0),
            CASE 
                WHEN NEW.`proyecto_id` IS NOT NULL AND NEW.`tiempo_real` IS NOT NULL THEN 
                    JSON_OBJECT(v_proyecto_nombre, NEW.`tiempo_real`)
                ELSE NULL
            END
        )
        ON DUPLICATE KEY UPDATE
            `tareas_completadas` = `tareas_completadas` + 1,
            `tiempo_productivo` = `tiempo_productivo` + IFNULL(NEW.`tiempo_real`, 0),
            `tiempo_por_proyecto` = CASE
                WHEN NEW.`proyecto_id` IS NOT NULL AND NEW.`tiempo_real` IS NOT NULL THEN
                    JSON_MERGE_PATCH(
                        IFNULL(`tiempo_por_proyecto`, JSON_OBJECT()),
                        JSON_OBJECT(v_proyecto_nombre, 
                            IFNULL(NEW.`tiempo_real`, 0) + 
                            IFNULL(JSON_EXTRACT(`tiempo_por_proyecto`, CONCAT('$."', v_proyecto_nombre, '"')), 0)
                        )
                    )
                ELSE `tiempo_por_proyecto`
            END;
        
        -- Crear notificación de tarea completada
        INSERT INTO `notificaciones` (`usuario_id`, `tipo`, `referencia_id`, `titulo`, `mensaje`)
        VALUES (
            NEW.`usuario_id`,
            'tarea',
            NEW.`id`,
            'Tarea completada',
            CONCAT('Has completado la tarea: ', NEW.`titulo`)
        );
        
        -- Actualizar productividad del día
        UPDATE `estadisticas_diarias`
        SET `productividad` = (
            SELECT 
                CASE 
                    WHEN (`tareas_completadas` + `tareas_creadas`) > 0 THEN
                        ROUND((`tareas_completadas` / (`tareas_completadas` + `tareas_creadas`)) * 100, 2)
                    ELSE 0
                END
        )
        WHERE `usuario_id` = NEW.`usuario_id` AND `fecha` = v_fecha;
    END IF;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Volcando estructura para disparador flowtime.actualizar_estadisticas_tarea_creada
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO';
DELIMITER //
CREATE TRIGGER `actualizar_estadisticas_tarea_creada` AFTER INSERT ON `tareas` FOR EACH ROW BEGIN
  -- Actualizar o insertar estadísticas diarias
  INSERT INTO `estadisticas_diarias` (`usuario_id`, `fecha`, `tareas_creadas`)
  VALUES (NEW.`usuario_id`, CURDATE(), 1)
  ON DUPLICATE KEY UPDATE
    `tareas_creadas` = `tareas_creadas` + 1;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Volcando estructura para disparador flowtime.actualizar_fecha_modificacion_proyecto
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO';
DELIMITER //
CREATE TRIGGER `actualizar_fecha_modificacion_proyecto` AFTER UPDATE ON `tareas` FOR EACH ROW BEGIN
    -- Si la tarea pertenece a un proyecto
    IF NEW.`proyecto_id` IS NOT NULL THEN
        -- Actualizar fecha de modificación del proyecto
        UPDATE `proyectos`
        SET `fecha_modificacion` = NOW()
        WHERE `id` = NEW.`proyecto_id`;
    END IF;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Volcando estructura para disparador flowtime.actualizar_tareas_recurrentes
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO';
DELIMITER //
CREATE TRIGGER `actualizar_tareas_recurrentes` AFTER UPDATE ON `tareas` FOR EACH ROW BEGIN
    DECLARE v_nueva_fecha DATE;
    DECLARE v_patron JSON;
    
    -- Si la tarea es recurrente y se acaba de completar
    IF NEW.`recurrente` = 1 AND NEW.`completada` = 1 AND OLD.`completada` = 0 AND NEW.`patron_recurrencia` IS NOT NULL THEN
        -- Parsear el patrón de recurrencia (JSON)
        SET v_patron = JSON_EXTRACT(NEW.`patron_recurrencia`, '$');
        
        -- Calcular la próxima fecha según el tipo de recurrencia
        CASE JSON_EXTRACT(v_patron, '$.tipo')
            WHEN '"diario"' THEN
                SET v_nueva_fecha = DATE_ADD(NEW.`fecha_vencimiento`, INTERVAL JSON_EXTRACT(v_patron, '$.intervalo') DAY);
            WHEN '"semanal"' THEN
                SET v_nueva_fecha = DATE_ADD(NEW.`fecha_vencimiento`, INTERVAL JSON_EXTRACT(v_patron, '$.intervalo') WEEK);
            WHEN '"mensual"' THEN
                SET v_nueva_fecha = DATE_ADD(NEW.`fecha_vencimiento`, INTERVAL JSON_EXTRACT(v_patron, '$.intervalo') MONTH);
            WHEN '"anual"' THEN
                SET v_nueva_fecha = DATE_ADD(NEW.`fecha_vencimiento`, INTERVAL JSON_EXTRACT(v_patron, '$.intervalo') YEAR);
            ELSE
                SET v_nueva_fecha = NULL;
        END CASE;
        
        -- Si se calculó una nueva fecha, crear una nueva tarea
        IF v_nueva_fecha IS NOT NULL THEN
            INSERT INTO `tareas` (
                `usuario_id`,
                `proyecto_id`,
                `titulo`,
                `descripcion`,
                `prioridad`,
                `estado`,
                `fecha_vencimiento`,
                `tiempo_estimado`,
                `recurrente`,
                `patron_recurrencia`
            )
            VALUES (
                NEW.`usuario_id`,
                NEW.`proyecto_id`,
                NEW.`titulo`,
                NEW.`descripcion`,
                NEW.`prioridad`,
                'pendiente',
                v_nueva_fecha,
                NEW.`tiempo_estimado`,
                1,
                NEW.`patron_recurrencia`
            );
            
            -- Copiar etiquetas de la tarea original a la nueva
            INSERT INTO `tareas_etiquetas` (`tarea_id`, `etiqueta_id`)
            SELECT LAST_INSERT_ID(), `etiqueta_id`
            FROM `tareas_etiquetas`
            WHERE `tarea_id` = NEW.`id`;
            
            -- Copiar subtareas de la tarea original a la nueva
            INSERT INTO `subtareas` (`tarea_id`, `titulo`, `completada`)
            SELECT LAST_INSERT_ID(), `titulo`, 0
            FROM `subtareas`
            WHERE `tarea_id` = NEW.`id`;
        END IF;
    END IF;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Volcando estructura para disparador flowtime.crear_notificacion_tarea_vencimiento
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO';
DELIMITER //
CREATE TRIGGER `crear_notificacion_tarea_vencimiento` AFTER INSERT ON `tareas` FOR EACH ROW BEGIN
    -- Si la tarea tiene fecha de vencimiento
    IF NEW.`fecha_vencimiento` IS NOT NULL THEN
        -- Crear recordatorio para el día anterior al vencimiento
        INSERT INTO `notificaciones` (`usuario_id`, `tipo`, `referencia_id`, `titulo`, `mensaje`, `fecha_creacion`)
        VALUES (
            NEW.`usuario_id`,
            'recordatorio',
            NEW.`id`,
            'Tarea próxima a vencer',
            CONCAT('La tarea "', NEW.`titulo`, '" vence mañana.'),
            DATE_SUB(CONCAT(NEW.`fecha_vencimiento`, ' 09:00:00'), INTERVAL 1 DAY)
        );
        
        -- Crear recordatorio para el día del vencimiento
        INSERT INTO `notificaciones` (`usuario_id`, `tipo`, `referencia_id`, `titulo`, `mensaje`, `fecha_creacion`)
        VALUES (
            NEW.`usuario_id`,
            'recordatorio',
            NEW.`id`,
            'Tarea vence hoy',
            CONCAT('La tarea "', NEW.`titulo`, '" vence hoy.'),
            CONCAT(NEW.`fecha_vencimiento`, ' 09:00:00')
        );
    END IF;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Volcando estructura para disparador flowtime.limpiar_notificaciones_antiguas
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO';
DELIMITER //
CREATE TRIGGER `limpiar_notificaciones_antiguas` BEFORE INSERT ON `notificaciones` FOR EACH ROW BEGIN
    -- Eliminar notificaciones leídas con más de 30 días
    DELETE FROM `notificaciones`
    WHERE `leida` = 1 
    AND `fecha_lectura` < DATE_SUB(CURDATE(), INTERVAL 30 DAY);
    
    -- Limitar a 100 notificaciones por usuario
    DELETE FROM `notificaciones` 
    WHERE `usuario_id` = NEW.`usuario_id`
    AND `id` NOT IN (
        SELECT `id` FROM (
            SELECT `id` 
            FROM `notificaciones` 
            WHERE `usuario_id` = NEW.`usuario_id` 
            ORDER BY `fecha_creacion` DESC 
            LIMIT 99
        ) AS temp
    );
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Volcando estructura para vista flowtime.vista_calendario_completo
-- Eliminando tabla temporal y crear estructura final de VIEW
DROP TABLE IF EXISTS `vista_calendario_completo`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vista_calendario_completo` AS select 'evento' AS `tipo`,`e`.`id` AS `id`,`e`.`usuario_id` AS `usuario_id`,`e`.`titulo` AS `titulo`,`e`.`descripcion` AS `descripcion`,`e`.`fecha_inicio` AS `fecha_inicio`,`e`.`fecha_fin` AS `fecha_fin`,`e`.`todo_el_dia` AS `todo_el_dia`,`e`.`color` AS `color`,`e`.`tipo` AS `categoria`,`e`.`ubicacion` AS `ubicacion`,NULL AS `prioridad`,NULL AS `estado`,NULL AS `proyecto_id`,NULL AS `proyecto_nombre` from `eventos` `e` union all select 'tarea' AS `tipo`,`t`.`id` AS `id`,`t`.`usuario_id` AS `usuario_id`,`t`.`titulo` AS `titulo`,`t`.`descripcion` AS `descripcion`,(case when (`t`.`fecha_vencimiento` is not null) then concat(`t`.`fecha_vencimiento`,' 00:00:00') else NULL end) AS `fecha_inicio`,(case when (`t`.`fecha_vencimiento` is not null) then concat(`t`.`fecha_vencimiento`,' 23:59:59') else NULL end) AS `fecha_fin`,1 AS `todo_el_dia`,(case when (`t`.`prioridad` = 'alta') then '#ef6f6c' when (`t`.`prioridad` = 'media') then '#ffd166' when (`t`.`prioridad` = 'baja') then '#a3c9a8' else '#bfd7ea' end) AS `color`,`t`.`prioridad` AS `categoria`,NULL AS `ubicacion`,`t`.`prioridad` AS `prioridad`,`t`.`estado` AS `estado`,`t`.`proyecto_id` AS `proyecto_id`,(select `p`.`nombre` from `proyectos` `p` where (`p`.`id` = `t`.`proyecto_id`)) AS `proyecto_nombre` from `tareas` `t` where (`t`.`fecha_vencimiento` is not null);

-- Volcando estructura para vista flowtime.vista_eventos
-- Eliminando tabla temporal y crear estructura final de VIEW
DROP TABLE IF EXISTS `vista_eventos`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vista_eventos` AS select `e`.`id` AS `id`,`e`.`usuario_id` AS `usuario_id`,`e`.`titulo` AS `titulo`,`e`.`descripcion` AS `descripcion`,`e`.`tipo` AS `tipo`,`e`.`fecha_inicio` AS `fecha_inicio`,`e`.`fecha_fin` AS `fecha_fin`,`e`.`todo_el_dia` AS `todo_el_dia`,`e`.`color` AS `color`,`e`.`ubicacion` AS `ubicacion`,`e`.`url` AS `url`,`e`.`recordatorio` AS `recordatorio`,`e`.`recurrente` AS `recurrente`,`e`.`patron_recurrencia` AS `patron_recurrencia`,count(`ep`.`usuario_id`) AS `total_participantes`,sum((case when (`ep`.`estado` = 'aceptado') then 1 else 0 end)) AS `participantes_aceptados` from (`eventos` `e` left join `eventos_participantes` `ep` on((`e`.`id` = `ep`.`evento_id`))) group by `e`.`id`;

-- Volcando estructura para vista flowtime.vista_eventos_completa
-- Eliminando tabla temporal y crear estructura final de VIEW
DROP TABLE IF EXISTS `vista_eventos_completa`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vista_eventos_completa` AS select `e`.`id` AS `id`,`e`.`usuario_id` AS `usuario_id`,`u`.`nombre` AS `usuario_nombre`,`u`.`apellido` AS `usuario_apellido`,`e`.`titulo` AS `titulo`,`e`.`descripcion` AS `descripcion`,`e`.`tipo` AS `tipo`,`e`.`fecha_inicio` AS `fecha_inicio`,`e`.`fecha_fin` AS `fecha_fin`,`e`.`todo_el_dia` AS `todo_el_dia`,`e`.`color` AS `color`,`e`.`ubicacion` AS `ubicacion`,`e`.`url` AS `url`,`e`.`recordatorio` AS `recordatorio`,`e`.`recurrente` AS `recurrente`,`e`.`patron_recurrencia` AS `patron_recurrencia`,`e`.`fecha_creacion` AS `fecha_creacion`,`e`.`fecha_modificacion` AS `fecha_modificacion`,(select count(0) from `eventos_participantes` `ep` where (`ep`.`evento_id` = `e`.`id`)) AS `total_participantes`,(select count(0) from `eventos_participantes` `ep` where ((`ep`.`evento_id` = `e`.`id`) and (`ep`.`estado` = 'aceptado'))) AS `participantes_aceptados`,(select count(0) from `eventos_participantes` `ep` where ((`ep`.`evento_id` = `e`.`id`) and (`ep`.`estado` = 'rechazado'))) AS `participantes_rechazados`,(select count(0) from `eventos_participantes` `ep` where ((`ep`.`evento_id` = `e`.`id`) and (`ep`.`estado` = 'pendiente'))) AS `participantes_pendientes`,(select group_concat(concat(`u2`.`nombre`,' ',`u2`.`apellido`) separator ', ') from (`usuarios` `u2` join `eventos_participantes` `ep` on((`u2`.`id` = `ep`.`usuario_id`))) where ((`ep`.`evento_id` = `e`.`id`) and (`ep`.`estado` = 'aceptado'))) AS `participantes_nombres` from (`eventos` `e` join `usuarios` `u` on((`e`.`usuario_id` = `u`.`id`)));

-- Volcando estructura para vista flowtime.vista_matriz_eisenhower_completa
-- Eliminando tabla temporal y crear estructura final de VIEW
DROP TABLE IF EXISTS `vista_matriz_eisenhower_completa`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vista_matriz_eisenhower_completa` AS select `m`.`id` AS `matriz_id`,`m`.`usuario_id` AS `usuario_id`,`u`.`nombre` AS `usuario_nombre`,`u`.`apellido` AS `usuario_apellido`,`m`.`nombre` AS `matriz_nombre`,`m`.`fecha_creacion` AS `fecha_creacion`,`m`.`fecha_modificacion` AS `fecha_modificacion`,`em`.`id` AS `elemento_id`,`em`.`tarea_id` AS `tarea_id`,`t`.`titulo` AS `tarea_titulo`,`em`.`titulo` AS `elemento_titulo`,`em`.`descripcion` AS `elemento_descripcion`,`em`.`cuadrante` AS `cuadrante`,`em`.`orden` AS `orden`,`em`.`completado` AS `completado`,`em`.`fecha_creacion` AS `elemento_fecha_creacion`,`em`.`fecha_modificacion` AS `elemento_fecha_modificacion`,(case when (`em`.`cuadrante` = 'urgente_importante') then 'Hacer primero' when (`em`.`cuadrante` = 'no_urgente_importante') then 'Programar' when (`em`.`cuadrante` = 'urgente_no_importante') then 'Delegar' when (`em`.`cuadrante` = 'no_urgente_no_importante') then 'Eliminar' end) AS `accion_recomendada` from (((`matriz_eisenhower` `m` join `usuarios` `u` on((`m`.`usuario_id` = `u`.`id`))) left join `elementos_matriz` `em` on((`m`.`id` = `em`.`matriz_id`))) left join `tareas` `t` on((`em`.`tarea_id` = `t`.`id`)));

-- Volcando estructura para vista flowtime.vista_notificaciones_detalle
-- Eliminando tabla temporal y crear estructura final de VIEW
DROP TABLE IF EXISTS `vista_notificaciones_detalle`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vista_notificaciones_detalle` AS select `n`.`id` AS `id`,`n`.`usuario_id` AS `usuario_id`,`u`.`nombre` AS `usuario_nombre`,`u`.`apellido` AS `usuario_apellido`,`n`.`tipo` AS `tipo`,`n`.`referencia_id` AS `referencia_id`,`n`.`titulo` AS `titulo`,`n`.`mensaje` AS `mensaje`,`n`.`leida` AS `leida`,`n`.`fecha_creacion` AS `fecha_creacion`,`n`.`fecha_lectura` AS `fecha_lectura`,(case when (`n`.`tipo` = 'tarea') then (select `t`.`titulo` from `tareas` `t` where (`t`.`id` = `n`.`referencia_id`)) when (`n`.`tipo` = 'evento') then (select `e`.`titulo` from `eventos` `e` where (`e`.`id` = `n`.`referencia_id`)) else NULL end) AS `referencia_titulo`,(case when (`n`.`tipo` = 'tarea') then concat('/tareas.php?id=',`n`.`referencia_id`) when (`n`.`tipo` = 'evento') then concat('/calendario.php?evento=',`n`.`referencia_id`) when (`n`.`tipo` = 'sistema') then '/dashboard.php' when (`n`.`tipo` = 'recordatorio') then concat('/calendario.php?fecha=',curdate()) else '#' end) AS `url_redireccion` from (`notificaciones` `n` join `usuarios` `u` on((`n`.`usuario_id` = `u`.`id`)));

-- Volcando estructura para vista flowtime.vista_productividad_usuario
-- Eliminando tabla temporal y crear estructura final de VIEW
DROP TABLE IF EXISTS `vista_productividad_usuario`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vista_productividad_usuario` AS select `u`.`id` AS `usuario_id`,`u`.`nombre` AS `nombre`,`u`.`apellido` AS `apellido`,count(distinct `t`.`id`) AS `total_tareas`,sum((case when (`t`.`completada` = 1) then 1 else 0 end)) AS `tareas_completadas`,sum((case when (`t`.`completada` = 0) then 1 else 0 end)) AS `tareas_pendientes`,sum(`t`.`tiempo_real`) AS `tiempo_total_tareas`,sum(`sp`.`duracion`) AS `tiempo_total_sesiones`,count(distinct `sp`.`id`) AS `total_sesiones_productividad`,avg(`sp`.`calificacion`) AS `calificacion_promedio` from ((`usuarios` `u` left join `tareas` `t` on((`u`.`id` = `t`.`usuario_id`))) left join `sesiones_productividad` `sp` on((`u`.`id` = `sp`.`usuario_id`))) group by `u`.`id`;

-- Volcando estructura para vista flowtime.vista_proyectos_progreso
-- Eliminando tabla temporal y crear estructura final de VIEW
DROP TABLE IF EXISTS `vista_proyectos_progreso`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vista_proyectos_progreso` AS select `p`.`id` AS `id`,`p`.`usuario_id` AS `usuario_id`,`u`.`nombre` AS `usuario_nombre`,`u`.`apellido` AS `usuario_apellido`,`p`.`nombre` AS `nombre`,`p`.`descripcion` AS `descripcion`,`p`.`color` AS `color`,`p`.`fecha_inicio` AS `fecha_inicio`,`p`.`fecha_fin` AS `fecha_fin`,`p`.`estado` AS `estado`,`p`.`fecha_creacion` AS `fecha_creacion`,`p`.`fecha_modificacion` AS `fecha_modificacion`,count(`t`.`id`) AS `total_tareas`,sum((case when (`t`.`estado` = 'completada') then 1 else 0 end)) AS `tareas_completadas`,sum((case when (`t`.`estado` = 'en_progreso') then 1 else 0 end)) AS `tareas_en_progreso`,sum((case when (`t`.`estado` = 'pendiente') then 1 else 0 end)) AS `tareas_pendientes`,(case when (count(`t`.`id`) > 0) then round(((sum((case when (`t`.`estado` = 'completada') then 1 else 0 end)) / count(`t`.`id`)) * 100),2) else 0 end) AS `porcentaje_completado`,(case when ((`p`.`fecha_fin` is not null) and (`p`.`fecha_fin` < curdate()) and (`p`.`estado` <> 'completado')) then 'Vencido' when ((`p`.`fecha_fin` is not null) and (`p`.`fecha_fin` = curdate()) and (`p`.`estado` <> 'completado')) then 'Vence hoy' when ((`p`.`fecha_fin` is not null) and (`p`.`fecha_fin` > curdate())) then concat('Faltan ',(to_days(`p`.`fecha_fin`) - to_days(curdate())),' días') else 'Sin fecha límite' end) AS `estado_vencimiento` from ((`proyectos` `p` join `usuarios` `u` on((`p`.`usuario_id` = `u`.`id`))) left join `tareas` `t` on((`p`.`id` = `t`.`proyecto_id`))) group by `p`.`id`;

-- Volcando estructura para vista flowtime.vista_sesiones_productividad_completa
-- Eliminando tabla temporal y crear estructura final de VIEW
DROP TABLE IF EXISTS `vista_sesiones_productividad_completa`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vista_sesiones_productividad_completa` AS select `sp`.`id` AS `id`,`sp`.`usuario_id` AS `usuario_id`,`u`.`nombre` AS `usuario_nombre`,`u`.`apellido` AS `usuario_apellido`,`sp`.`tecnica_id` AS `tecnica_id`,`tp`.`nombre` AS `tecnica_nombre`,`tp`.`descripcion` AS `tecnica_descripcion`,`tp`.`icono` AS `tecnica_icono`,`sp`.`tarea_id` AS `tarea_id`,`t`.`titulo` AS `tarea_titulo`,`t`.`proyecto_id` AS `proyecto_id`,`p`.`nombre` AS `proyecto_nombre`,`sp`.`fecha_inicio` AS `fecha_inicio`,`sp`.`fecha_fin` AS `fecha_fin`,`sp`.`duracion` AS `duracion`,`sp`.`completada` AS `completada`,`sp`.`notas` AS `notas`,`sp`.`calificacion` AS `calificacion`,(case when (`sp`.`duracion` is not null) then concat(floor((`sp`.`duracion` / 60)),'h ',(`sp`.`duracion` % 60),'m') else NULL end) AS `duracion_formateada`,(case when (`sp`.`fecha_fin` is not null) then timestampdiff(MINUTE,`sp`.`fecha_inicio`,`sp`.`fecha_fin`) else NULL end) AS `duracion_calculada` from ((((`sesiones_productividad` `sp` join `usuarios` `u` on((`sp`.`usuario_id` = `u`.`id`))) join `tecnicas_productividad` `tp` on((`sp`.`tecnica_id` = `tp`.`id`))) left join `tareas` `t` on((`sp`.`tarea_id` = `t`.`id`))) left join `proyectos` `p` on((`t`.`proyecto_id` = `p`.`id`)));

-- Volcando estructura para vista flowtime.vista_tareas
-- Eliminando tabla temporal y crear estructura final de VIEW
DROP TABLE IF EXISTS `vista_tareas`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vista_tareas` AS select `t`.`id` AS `id`,`t`.`usuario_id` AS `usuario_id`,`t`.`proyecto_id` AS `proyecto_id`,`p`.`nombre` AS `proyecto_nombre`,`p`.`color` AS `proyecto_color`,`t`.`titulo` AS `titulo`,`t`.`descripcion` AS `descripcion`,`t`.`prioridad` AS `prioridad`,`t`.`estado` AS `estado`,`t`.`fecha_vencimiento` AS `fecha_vencimiento`,`t`.`tiempo_estimado` AS `tiempo_estimado`,`t`.`tiempo_real` AS `tiempo_real`,`t`.`completada` AS `completada`,`t`.`fecha_completada` AS `fecha_completada`,`t`.`fecha_creacion` AS `fecha_creacion`,`t`.`fecha_modificacion` AS `fecha_modificacion`,group_concat(`e`.`nombre` separator ', ') AS `etiquetas` from (((`tareas` `t` left join `proyectos` `p` on((`t`.`proyecto_id` = `p`.`id`))) left join `tareas_etiquetas` `te` on((`t`.`id` = `te`.`tarea_id`))) left join `etiquetas` `e` on((`te`.`etiqueta_id` = `e`.`id`))) group by `t`.`id`;

-- Volcando estructura para vista flowtime.vista_tareas_completa
-- Eliminando tabla temporal y crear estructura final de VIEW
DROP TABLE IF EXISTS `vista_tareas_completa`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vista_tareas_completa` AS select `t`.`id` AS `id`,`t`.`usuario_id` AS `usuario_id`,`u`.`nombre` AS `usuario_nombre`,`u`.`apellido` AS `usuario_apellido`,`t`.`proyecto_id` AS `proyecto_id`,`p`.`nombre` AS `proyecto_nombre`,`p`.`color` AS `proyecto_color`,`t`.`titulo` AS `titulo`,`t`.`descripcion` AS `descripcion`,`t`.`prioridad` AS `prioridad`,`t`.`estado` AS `estado`,`t`.`fecha_vencimiento` AS `fecha_vencimiento`,`t`.`tiempo_estimado` AS `tiempo_estimado`,`t`.`tiempo_real` AS `tiempo_real`,`t`.`completada` AS `completada`,`t`.`fecha_completada` AS `fecha_completada`,`t`.`fecha_creacion` AS `fecha_creacion`,`t`.`fecha_modificacion` AS `fecha_modificacion`,`t`.`recurrente` AS `recurrente`,`t`.`patron_recurrencia` AS `patron_recurrencia`,(select count(0) from `subtareas` `s` where (`s`.`tarea_id` = `t`.`id`)) AS `total_subtareas`,(select count(0) from `subtareas` `s` where ((`s`.`tarea_id` = `t`.`id`) and (`s`.`completada` = 1))) AS `subtareas_completadas`,(select group_concat(`e`.`nombre` order by `e`.`nombre` ASC separator ', ') from (`etiquetas` `e` join `tareas_etiquetas` `te` on((`e`.`id` = `te`.`etiqueta_id`))) where (`te`.`tarea_id` = `t`.`id`)) AS `etiquetas`,(select group_concat(`e`.`color` order by `e`.`nombre` ASC separator ',') from (`etiquetas` `e` join `tareas_etiquetas` `te` on((`e`.`id` = `te`.`etiqueta_id`))) where (`te`.`tarea_id` = `t`.`id`)) AS `etiquetas_colores` from ((`tareas` `t` join `usuarios` `u` on((`t`.`usuario_id` = `u`.`id`))) left join `proyectos` `p` on((`t`.`proyecto_id` = `p`.`id`)));

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
