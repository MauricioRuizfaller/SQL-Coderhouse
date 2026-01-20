-- Creación de Vista 1: Detalle de transacciones.

CREATE OR REPLACE VIEW vw_transacciones_detalle AS
SELECT
    t.id_transaccion,
    t.fecha_creacion,
    t.estatus,
    t.monto_origen,
    t.monto_destino,

    c.id_cliente,
    c.nombre AS cliente_nombre,
    c.apellido_paterno AS cliente_apellido_paterno,
    c.apellido_materno AS cliente_apellido_materno,
    c.email AS cliente_email,

    b.id_beneficiario,
    b.nombre AS beneficiario_nombre,
    b.apellido_paterno AS beneficiario_apellido_paterno,
	b.apellido_materno AS beneficiario_apellido_materno,
    b.email AS beneficiario_email,

    a.id_agente AS agente_id,
    a.nombre_agente AS agente_nombre,
    a.pais AS agente_pais,

    tc.id_tasa_cambio,
    tc.moneda_origen,
    tc.moneda_destino,
    tc.fecha AS fecha_tasa,
    tc.tipo_cambio
FROM TRANSACCION t
INNER JOIN CLIENTE c
    ON t.id_cliente = c.id_cliente
INNER JOIN BENEFICIARIO b
    ON t.id_beneficiario = b.id_beneficiario
INNER JOIN AGENTE a
    ON t.id_agente_origen = a.id_agente
INNER JOIN TASA_CAMBIO tc
    ON t.id_tasa_cambio = tc.id_tasa_cambio;

SELECT * FROM vw_transacciones_detalle;

-- Creación de Vista 2: Comisiones por Mes.

CREATE OR REPLACE VIEW vw_comisiones_por_mes AS
SELECT
    YEAR(tc.fecha_aplicacion) AS anio,
    MONTH(tc.fecha_aplicacion) AS mes,
    COUNT(tc.id_comision) AS total_transacciones,
    SUM(tc.monto_comision) AS total_comisiones
FROM TRANSACCION_COMISION tc
INNER JOIN TRANSACCION t
    ON tc.id_transaccion = t.id_transaccion
GROUP BY
    YEAR(tc.fecha_aplicacion),
    MONTH(tc.fecha_aplicacion)
ORDER BY
    anio,
    mes;

SELECT * FROM vw_comisiones_por_mes;

-- Creación de la vista 3: Transacciones Pagadas

CREATE OR REPLACE VIEW vw_transacciones_pagadas AS
SELECT
    t.id_transaccion,
    t.fecha_creacion,
    t.monto_origen,
    t.monto_destino,
    t.estatus,

    c.id_cliente,
    c.nombre AS cliente_nombre,
    c.apellido_paterno AS cliente_apellido_paterno,
    c.apellido_materno AS cliente_apellido_materno,

    b.id_beneficiario,
    b.nombre AS beneficiario_nombre,
    b.apellido_paterno AS beneficiario_apellido_paterno,
	b.apellido_materno AS beneficiario_apellido_materno,

    a.id_agente AS agente_id,
    a.nombre_agente AS agente_nombre,
    a.pais AS agente_pais
FROM TRANSACCION t
INNER JOIN CLIENTE c
    ON t.id_cliente = c.id_cliente
INNER JOIN BENEFICIARIO b
    ON t.id_beneficiario = b.id_beneficiario
INNER JOIN AGENTE a
    ON t.id_agente_origen = a.id_agente
WHERE t.estatus = 'PAGADA';

SELECT * FROM vw_transacciones_pagadas;

-- Creación de la vista 4: Detalle de cancelaciones

CREATE OR REPLACE VIEW vw_cancelaciones_detalle AS
SELECT
    ca.id_cancelacion,
    ca.id_transaccion,
    ca.fecha_cancelacion,
    ca.motivo_cancelacion,
    ca.reembolsado,

    t.fecha_creacion AS fecha_transaccion,
    t.monto_origen,
    t.monto_destino,
    t.estatus,

    c.id_cliente,
    c.nombre AS cliente_nombre,
    c.apellido_paterno AS cliente_apellido_paterno,
    c.apellido_materno AS cliente_apellido_materno,

    a.id_agente AS agente_id,
    a.nombre_agente AS agente_nombre,
    a.pais AS agente_pais
FROM CANCELACION ca
INNER JOIN TRANSACCION t
    ON ca.id_transaccion = t.id_transaccion
INNER JOIN CLIENTE c
    ON t.id_cliente = c.id_cliente
INNER JOIN AGENTE a
    ON t.id_agente_origen = a.id_agente;

SELECT * FROM vw_cancelaciones_detalle;

-- Creación de vista 5: detalle de reembolsos

CREATE OR REPLACE VIEW vw_reembolsos_detalle AS
SELECT
    r.id_reembolso,
    r.id_cancelacion,
    r.id_transaccion,
    r.fecha_reembolso,
    r.monto_reembolso,
    r.metodo_reembolso,

    ca.fecha_cancelacion,
    ca.motivo_cancelacion,
    ca.reembolsado,

    t.fecha_creacion AS fecha_transaccion,
    t.monto_origen,
    t.monto_destino,
    t.estatus,

    c.id_cliente,
    c.nombre AS cliente_nombre,
    c.apellido_paterno AS cliente_apellido_paterno,
    c.apellido_materno AS cliente_apellido_materno
FROM REEMBOLSO r
INNER JOIN CANCELACION ca
    ON r.id_cancelacion = ca.id_cancelacion
INNER JOIN TRANSACCION t
    ON r.id_transaccion = t.id_transaccion
INNER JOIN CLIENTE c
    ON t.id_cliente = c.id_cliente;

SELECT * FROM vw_reembolsos_detalle;

-- Funciones
-- Creación de la función 1: calcular comisión

DELIMITER $$

CREATE FUNCTION fn_calcular_comision(
    p_monto_origen DECIMAL(10,2),
    p_porcentaje DECIMAL(5,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    RETURN ROUND(p_monto_origen * (p_porcentaje / 100), 2);
END$$

DELIMITER ;

SELECT fn_calcular_comision(1000.00, 4.50) AS comision_calculada;

-- Función 2:

DELIMITER $$

CREATE FUNCTION fn_total_comision_transaccion(
    p_id_transaccion INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_total_comision DECIMAL(10,2);

    SELECT
        IFNULL(SUM(monto_comision), 0)
    INTO v_total_comision
    FROM TRANSACCION_COMISION
    WHERE id_transaccion = p_id_transaccion;

    RETURN v_total_comision;
END$$

DELIMITER ;

SELECT
    id_transaccion,
    fn_total_comision_transaccion(id_transaccion) AS total_comision
FROM TRANSACCION
WHERE id_transaccion = 10;

-- Stored Procedures
-- Stored Procedure 1: 
DELIMITER $$

CREATE PROCEDURE sp_crear_transaccion(
    IN p_id_transaccion INT,
    IN p_id_cliente INT,
    IN p_id_beneficiario INT,
    IN p_id_agente_origen INT,
    IN p_id_tasa_cambio INT,
    IN p_fecha_creacion DATETIME,
    IN p_monto_origen DECIMAL(10,2),
    IN p_estatus VARCHAR(20)
)
BEGIN
    DECLARE v_tipo_cambio DECIMAL(10,4);
    DECLARE v_monto_destino DECIMAL(14,2);

    -- 1) Obtener tipo de cambio asociado
    SELECT tipo_cambio
      INTO v_tipo_cambio
    FROM TASA_CAMBIO
    WHERE id_tasa_cambio = p_id_tasa_cambio;

    -- 2) Calcular monto destino
    SET v_monto_destino = ROUND(p_monto_origen * v_tipo_cambio, 2);

    -- 3) Insertar transacción
    INSERT INTO TRANSACCION (
        id_transaccion,
        id_cliente,
        id_beneficiario,
        id_agente_origen,
        id_tasa_cambio,
        fecha_creacion,
        monto_origen,
        monto_destino,
        estatus
    ) VALUES (
        p_id_transaccion,
        p_id_cliente,
        p_id_beneficiario,
        p_id_agente_origen,
        p_id_tasa_cambio,
        p_fecha_creacion,
        p_monto_origen,
        v_monto_destino,
        p_estatus
    );
END$$

DELIMITER ;
-- Ejemplo:
CALL sp_crear_transaccion(
    501,        -- id_transaccion nuevo
    10,         -- id_cliente
    20,         -- id_beneficiario
    5,          -- id_agente_origen
    1,          -- id_tasa_cambio (USD->MXN)
    '2024-03-01 10:30:00',
    250.00,     -- monto_origen
    'CREADA'    -- estatus
);
SELECT * FROM transaccion
WHERE id_transaccion = 501;

-- Stored Procedure 2: Cancelar transacciones

DELIMITER $$

CREATE PROCEDURE sp_cancelar_transaccion(
    IN p_id_transaccion INT,
    IN p_fecha_cancelacion DATETIME,
    IN p_motivo_cancelacion VARCHAR(200),
    IN p_reembolsado BIT
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_id_cancelacion INT DEFAULT 0;

    -- 1) Validar que la transacción exista
    SELECT COUNT(*)
      INTO v_existe
    FROM TRANSACCION
    WHERE id_transaccion = p_id_transaccion;

    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No existe la transacción indicada para cancelar.';
    END IF;

    -- 2) Validar que no esté ya cancelada
    IF (SELECT estatus FROM TRANSACCION WHERE id_transaccion = p_id_transaccion) = 'CANCELADA' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La transacción ya se encuentra CANCELADA.';
    END IF;

    -- 3) Actualizar estatus de la transacción
    UPDATE TRANSACCION
    SET estatus = 'CANCELADA'
    WHERE id_transaccion = p_id_transaccion;

    -- 4) Generar el siguiente id_cancelacion
    SELECT IFNULL(MAX(id_cancelacion), 0) + 1
      INTO v_id_cancelacion
    FROM CANCELACION;

    -- 5) Insertar registro en CANCELACION
    INSERT INTO CANCELACION (
        id_cancelacion,
        id_transaccion,
        fecha_cancelacion,
        motivo_cancelacion,
        reembolsado
    ) VALUES (
        v_id_cancelacion,
        p_id_transaccion,
        p_fecha_cancelacion,
        p_motivo_cancelacion,
        p_reembolsado
    );

END$$

DELIMITER ;

-- Triggers
-- Trigger 1: 

DELIMITER $$

CREATE TRIGGER tr_after_insert_transaccion_generar_comision
AFTER INSERT ON TRANSACCION
FOR EACH ROW
BEGIN
    DECLARE v_porcentaje DECIMAL(5,2);
    DECLARE v_monto_comision DECIMAL(10,2);
    DECLARE v_id_comision INT;

    -- 1) Definir porcentaje según monto
    IF NEW.monto_origen < 200 THEN
        SET v_porcentaje = 5.50;
    ELSEIF NEW.monto_origen <= 500 THEN
        SET v_porcentaje = 4.50;
    ELSE
        SET v_porcentaje = 3.50;
    END IF;

    -- 2) Calcular monto de comisión usando función
    SET v_monto_comision = fn_calcular_comision(NEW.monto_origen, v_porcentaje);

    -- 3) Generar id_comision incremental
    SELECT IFNULL(MAX(id_comision), 0) + 1
      INTO v_id_comision
    FROM TRANSACCION_COMISION;

    -- 4) Insertar registro de comisión
    INSERT INTO TRANSACCION_COMISION (
        id_comision,
        id_transaccion,
        porcentaje_comision,
        monto_comision,
        fecha_aplicacion
    ) VALUES (
        v_id_comision,
        NEW.id_transaccion,
        v_porcentaje,
        v_monto_comision,
        NEW.fecha_creacion
    );
END$$

DELIMITER ;

-- Trigger 2:

DELIMITER $$

CREATE TRIGGER tr_after_insert_cancelacion_actualizar_transaccion
AFTER INSERT ON CANCELACION
FOR EACH ROW
BEGIN
    UPDATE TRANSACCION
    SET estatus = 'CANCELADA'
    WHERE id_transaccion = NEW.id_transaccion;
END$$

DELIMITER ;
