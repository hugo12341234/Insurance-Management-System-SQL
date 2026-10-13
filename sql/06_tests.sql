/* ============================================================================
   Proyecto : Sistema de Base de Datos para una Aseguradora (ASEGURADORA06)
   Archivo  : 06_tests.sql
   Contenido: Pruebas de funciones, triggers, vistas y procedimientos de
              02_logic.sql.
              - Las pruebas que modifican datos se ejecutan dentro de una
                transacción que se revierte al final, para que la base quede
                igual que después de 03_seed_data.sql.
              - Las pruebas que deben fallar usan TRY/CATCH e imprimen el
                mensaje de error esperado.
   Autores  : Aranda Marrón Fernando
              Chacón Jaral Hugo Emmanuel
              Gutiérrez Nolasco Emiliano
   Fecha    : 30/11/2025
   Motor    : Microsoft SQL Server 2019 o superior
   Orden    : 6 de 6 (requiere los scripts 01 a 03)
   ============================================================================ */

USE ASEGURADORA06;
GO

/* ============================================================================
   FUNCIONES
   ============================================================================ */

-- F1. Edad actual del cliente 1
SELECT
    ID_CLIENTE,
    NOMBRE,
    APELLIDO_P,
    FECHA_NACIMIENTO,
    Personas.fn_EdadClienteEnFecha(ID_CLIENTE, CAST(GETDATE() AS DATE)) AS EDAD_CALCULADA
FROM Personas.CLIENTE
WHERE ID_CLIENTE = 1;
GO

-- F2. Días transcurridos desde el siniestro 3001
SELECT
    NUM_SINIESTRO,
    FECHA_HORA,
    Operaciones.fn_DiasTranscurridosSiniestro(NUM_SINIESTRO) AS DIAS_TRANSCURRIDOS
FROM Operaciones.SINIESTRO
WHERE NUM_SINIESTRO = 3001;
GO

-- F3. Saldo pendiente de la póliza 2001 (esperado: 10,000 - 5 x 1,500 = 2,500)
SELECT
    NUM_POLIZA,
    MONTO_PRIMA_TOT,
    SALDO_PENDIENTE,
    Operaciones.fn_SaldoPendiente(NUM_POLIZA) AS SALDO_CALCULADO
FROM Operaciones.POLIZA
WHERE NUM_POLIZA = 2001;
GO

/* ============================================================================
   TRIGGERS
   ============================================================================ */

-- T1. trg_BeneficiariosMaximo100: debe rechazar un beneficiario con 120 %
BEGIN TRY
    INSERT INTO Personas.BENEFICIARIO
        (ID_BENEFICIARIO, APELLIDO_M, APELLIDO_P, NOMBRE, PARENTESCO,
         PORCENTAJE, CLAVE_SEGURO, ID_CLIENTE)
    VALUES
        (9991, 'TEST', 'EXCESO', 'ERROR', 'HO', 120, '100', 1);

    PRINT 'T1 FALLÓ: se aceptó un porcentaje mayor a 100.';
END TRY
BEGIN CATCH
    PRINT 'T1 OK (error esperado): ' + ERROR_MESSAGE();
END CATCH;
GO

-- T2. trg_BitacoraCotizacion: al cambiar el estado se agrega un registro
BEGIN TRANSACTION;

    UPDATE Operaciones.COTIZACION
    SET ESTADO = 'APROBADA'
    WHERE NUM_COTIZACION = 1006;

    SELECT *
    FROM Operaciones.BITACORA_COTIZACIONES
    WHERE NUM_COTIZACION = 1006
    ORDER BY ID_BITACORA;

ROLLBACK TRANSACTION;
GO

-- T3. trg_AsignaCorredorZona: un cliente sin corredor con CP 04200 debe
--     quedar asignado al corredor 8 (rango 04000 a 04999)
BEGIN TRANSACTION;

    INSERT INTO Personas.CLIENTE
        (ID_CLIENTE, RFC, CURP, TIPO_CLIENTE, NOMBRE, APELLIDO_P, APELLIDO_M,
         FECHA_NACIMIENTO, ID_CORREDOR)
    VALUES
        (11, 'CLI810102ZZZ', 'CLI810121HDFXXX11', 'NATURAL', 'JUAN', 'PRUEBA', 'TEST',
         '1981-01-01', NULL);

    INSERT INTO Personas.DIRECCIONCP (ID_CPDIR, ESTADO, CIUDAD, ID_CLIENTE)
    VALUES ('04200', 'CDMX', 'CDMX', 11);

    SELECT ID_CLIENTE, ID_CORREDOR AS CORREDOR_ASIGNADO
    FROM Personas.CLIENTE
    WHERE ID_CLIENTE = 11;

ROLLBACK TRANSACTION;
GO

-- T4. trg_ActualizaSaldoPendiente: un pago de 500 a la póliza 2001 baja su
--     saldo de 2,500 a 2,000
BEGIN TRANSACTION;

    INSERT INTO Operaciones.PAGO
        (ID_PAGO, NUM_POLIZA, STSPAGO, NUM_PAGO, FECHA_PAGO, MONTO_PAGADO, METODO_PAGO)
    VALUES
        (101, 2001, 'PAGADO', 6, CAST(GETDATE() AS DATE), 500, 'TRANSFERENCIA');

    SELECT NUM_POLIZA, MONTO_PRIMA_TOT, SALDO_PENDIENTE
    FROM Operaciones.POLIZA
    WHERE NUM_POLIZA = 2001;

ROLLBACK TRANSACTION;
GO

-- T5. trg_ValidaEdadContratacionVida: el cliente 1 (nacido en 1980) tendría
--     120 años en 2100, por lo que la póliza de vida debe rechazarse
BEGIN TRY
    INSERT INTO Operaciones.POLIZA
        (NUM_POLIZA, ID_CLIENTE, ID_CORREDOR, CLAVE_SEGURO, FECHA_INICIO,
         FECHA_FIN, SALDO_PENDIENTE, MONTO_PRIMA_TOT, ESTADO_POLIZA)
    VALUES
        (9001, 1, 1, '100', '2100-01-01', '2101-01-01', 5000, 5000, 'ACTIVA');

    PRINT 'T5 FALLÓ: se aceptó la póliza de vida.';
END TRY
BEGIN CATCH
    PRINT 'T5 OK (error esperado): ' + ERROR_MESSAGE();
END CATCH;
GO

/* ============================================================================
   VISTAS
   ============================================================================ */

-- V1. Siniestros con días transcurridos
SELECT * FROM Operaciones.v_SiniestrosConDias ORDER BY NUM_SINIESTRO;
GO

-- V2. Resumen por cliente
SELECT * FROM Operaciones.v_ClienteEstadisticas ORDER BY ID_CLIENTE;
GO

-- V3. Estatus financiero por póliza
SELECT * FROM Operaciones.v_PolizaFinanzas ORDER BY NUM_POLIZA;
GO

/* ============================================================================
   PROCEDIMIENTOS ALMACENADOS
   ============================================================================ */

-- P1. sp_RegistrarCotizacion
BEGIN TRANSACTION;

    DECLARE @nueva_cotizacion INT;

    EXEC Operaciones.sp_RegistrarCotizacion
        @id_cliente         = 1,
        @fecha_cotiz        = '2025-03-10',
        @monto_est_prima    = 15000,
        @estado             = 'PENDIENTE',
        @recordatorio       = 'Cotización generada por SP',
        @vigencia_dias      = '30',
        @num_cotizacion_out = @nueva_cotizacion OUTPUT;

    SELECT * FROM Operaciones.COTIZACION WHERE NUM_COTIZACION = @nueva_cotizacion;

ROLLBACK TRANSACTION;
GO

-- P2. sp_RegistrarPoliza (genérico)
BEGIN TRANSACTION;

    DECLARE @nueva_poliza INT;

    EXEC Operaciones.sp_RegistrarPoliza
        @id_cliente      = 4,
        @id_corredor     = 8,
        @clave_seguro    = '100',      -- 100 = Vida, 200 = Retiro, 300 = Auto
        @fecha_inicio    = '2025-04-10',
        @fecha_fin       = '2026-04-10',
        @monto_prima_tot = 13000,
        @estado_poliza   = 'ACTIVA',
        @num_poliza_out  = @nueva_poliza OUTPUT;

    SELECT * FROM Operaciones.POLIZA WHERE NUM_POLIZA = @nueva_poliza;

ROLLBACK TRANSACTION;
GO

-- P3. sp_RegistrarPolizaVida, sp_RegistrarPolizaAuto y sp_RegistrarPolizaRetiro
BEGIN TRANSACTION;

    DECLARE @poliza_vida INT, @poliza_auto INT, @poliza_retiro INT;

    EXEC Operaciones.sp_RegistrarPolizaVida
        @id_cliente = 1, @id_corredor = 5,
        @fecha_inicio = '2025-04-01', @fecha_fin = '2026-04-01',
        @monto_prima_tot = 12000, @num_poliza_out = @poliza_vida OUTPUT;

    EXEC Operaciones.sp_RegistrarPolizaAuto
        @id_cliente = 2, @id_corredor = 6,
        @fecha_inicio = '2025-04-01', @fecha_fin = '2026-04-01',
        @monto_prima_tot = 14500, @num_poliza_out = @poliza_auto OUTPUT;

    EXEC Operaciones.sp_RegistrarPolizaRetiro
        @id_cliente = 3, @id_corredor = 7,
        @fecha_inicio = '2025-04-01', @fecha_fin = '2026-04-01',
        @monto_prima_tot = 18000, @num_poliza_out = @poliza_retiro OUTPUT;

    SELECT *
    FROM Operaciones.POLIZA
    WHERE NUM_POLIZA IN (@poliza_vida, @poliza_auto, @poliza_retiro);

ROLLBACK TRANSACTION;
GO

-- P4. sp_RegistrarPago (el saldo de la póliza 2001 baja de 2,500 a 1,000)
BEGIN TRANSACTION;

    DECLARE @nuevo_pago INT;

    EXEC Operaciones.sp_RegistrarPago
        @num_poliza   = 2001,
        @stspago      = 'PAGADO',
        @fecha_pago   = '2025-08-01',
        @monto_pagado = 1500,
        @metodo_pago  = 'TRANSFERENCIA',
        @id_pago_out  = @nuevo_pago OUTPUT;

    SELECT * FROM Operaciones.PAGO WHERE ID_PAGO = @nuevo_pago;

    SELECT NUM_POLIZA, SALDO_PENDIENTE
    FROM Operaciones.POLIZA
    WHERE NUM_POLIZA = 2001;

ROLLBACK TRANSACTION;
GO

-- P5. sp_RegistrarSiniestro
BEGIN TRANSACTION;

    DECLARE @nuevo_siniestro INT;

    EXEC Operaciones.sp_RegistrarSiniestro
        @num_poliza        = 2002,
        @fecha_hora        = '2025-10-05T14:00:00',
        @lugar             = 'CDMX - CENTRO',
        @causa             = 'Choque en crucero',
        @monto_indemniz    = 25000,
        @num_siniestro_out = @nuevo_siniestro OUTPUT;

    SELECT * FROM Operaciones.SINIESTRO WHERE NUM_SINIESTRO = @nuevo_siniestro;

ROLLBACK TRANSACTION;
GO
