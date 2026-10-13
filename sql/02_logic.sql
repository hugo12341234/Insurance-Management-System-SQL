/* ============================================================================
   Proyecto : Sistema de Base de Datos para una Aseguradora (ASEGURADORA06)
   Archivo  : 02_logic.sql
   Contenido: Lógica programable: funciones, triggers, vistas y procedimientos
              almacenados. Las pruebas de cada objeto están en 06_tests.sql.
   Autores  : Aranda Marrón Fernando
              Chacón Jaral Hugo Emmanuel
              Gutiérrez Nolasco Emiliano
   Fecha    : 30/11/2025
   Motor    : Microsoft SQL Server 2019 o superior
   Orden    : 2 de 6 (requiere 01_schema.sql)
   ============================================================================ */

USE ASEGURADORA06;
GO

/* ============================================================================
   FUNCIONES
   ============================================================================ */

/* ----------------------------------------------------------------------------
   Personas.fn_EdadClienteEnFecha
   Devuelve la edad cumplida de un cliente en una fecha dada.
   Resta un año cuando el cliente todavía no cumple años en esa fecha.
---------------------------------------------------------------------------- */
CREATE OR ALTER FUNCTION Personas.fn_EdadClienteEnFecha
(
    @id_cliente INT,
    @fecha      DATE
)
RETURNS INT
AS
BEGIN
    DECLARE @edad INT;

    SELECT @edad = DATEDIFF(YEAR, FECHA_NACIMIENTO, @fecha)
                 - CASE
                       WHEN DATEADD(YEAR, DATEDIFF(YEAR, FECHA_NACIMIENTO, @fecha), FECHA_NACIMIENTO) > @fecha
                       THEN 1
                       ELSE 0
                   END
    FROM Personas.CLIENTE
    WHERE ID_CLIENTE = @id_cliente;

    RETURN @edad;
END;
GO

/* ----------------------------------------------------------------------------
   Operaciones.fn_DiasTranscurridosSiniestro
   Devuelve los días transcurridos desde que ocurrió un siniestro.
---------------------------------------------------------------------------- */
CREATE OR ALTER FUNCTION Operaciones.fn_DiasTranscurridosSiniestro
(
    @num_siniestro INT
)
RETURNS INT
AS
BEGIN
    DECLARE @dias INT;

    SELECT @dias = DATEDIFF(DAY, FECHA_HORA, GETDATE())
    FROM Operaciones.SINIESTRO
    WHERE NUM_SINIESTRO = @num_siniestro;

    RETURN @dias;
END;
GO

/* ----------------------------------------------------------------------------
   Operaciones.fn_SaldoPendiente
   Calcula el saldo pendiente de una póliza: prima total menos los pagos con
   estatus PAGADO. Los pagos con estatus PENDIENTE no reducen el saldo.
---------------------------------------------------------------------------- */
CREATE OR ALTER FUNCTION Operaciones.fn_SaldoPendiente
(
    @num_poliza INT
)
RETURNS DECIMAL(14,2)
AS
BEGIN
    DECLARE @monto_prima DECIMAL(14,2);
    DECLARE @pagado      DECIMAL(14,2);

    SELECT @monto_prima = MONTO_PRIMA_TOT
    FROM Operaciones.POLIZA
    WHERE NUM_POLIZA = @num_poliza;

    SELECT @pagado = ISNULL(SUM(MONTO_PAGADO), 0)
    FROM Operaciones.PAGO
    WHERE NUM_POLIZA = @num_poliza
      AND STSPAGO = 'PAGADO';

    RETURN @monto_prima - @pagado;
END;
GO

/* ============================================================================
   TRIGGERS
   Todos trabajan sobre el conjunto completo de filas de inserted/deleted, por
   lo que funcionan bien con inserciones o actualizaciones de varias filas.
   ============================================================================ */

/* ----------------------------------------------------------------------------
   Personas.trg_BeneficiariosMaximo100
   Impide que la suma de porcentajes de los beneficiarios de un mismo cliente
   y tipo de seguro supere 100 %.
---------------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER Personas.trg_BeneficiariosMaximo100
ON Personas.BENEFICIARIO
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM Personas.BENEFICIARIO b
        JOIN (SELECT DISTINCT ID_CLIENTE, CLAVE_SEGURO FROM inserted) i
            ON  i.ID_CLIENTE   = b.ID_CLIENTE
            AND i.CLAVE_SEGURO = b.CLAVE_SEGURO
        GROUP BY b.ID_CLIENTE, b.CLAVE_SEGURO
        HAVING SUM(b.PORCENTAJE) > 100
    )
    BEGIN
        RAISERROR('La suma de porcentajes de beneficiarios no puede exceder 100.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

/* ----------------------------------------------------------------------------
   Operaciones.trg_BitacoraCotizacion
   Registra en la bitácora cada cambio de estado de una cotización.
---------------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER Operaciones.trg_BitacoraCotizacion
ON Operaciones.COTIZACION
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ultimo_id INT;

    SELECT @ultimo_id = ISNULL(MAX(ID_BITACORA), 0)
    FROM Operaciones.BITACORA_COTIZACIONES;

    INSERT INTO Operaciones.BITACORA_COTIZACIONES
        (ID_BITACORA, NUM_COTIZACION, FECHA_CAMBIO, NUEVO_ESTADO, OBSERVACIONES)
    SELECT
        @ultimo_id + ROW_NUMBER() OVER (ORDER BY i.NUM_COTIZACION),
        i.NUM_COTIZACION,
        CAST(GETDATE() AS DATE),
        LEFT(i.ESTADO, 20),
        'Cambio de estado registrado automáticamente'
    FROM inserted i
    JOIN deleted d
        ON d.NUM_COTIZACION = i.NUM_COTIZACION
    WHERE i.ESTADO <> d.ESTADO;
END;
GO

/* ----------------------------------------------------------------------------
   Personas.trg_AsignaCorredorZona
   Al registrar el código postal de un cliente sin corredor, le asigna el
   corredor cuyo rango de códigos postales incluye ese código.
---------------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER Personas.trg_AsignaCorredorZona
ON Personas.DIRECCIONCP
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE c
    SET c.ID_CORREDOR = cc.ID_CORREDOR
    FROM Personas.CLIENTE c
    JOIN inserted d
        ON c.ID_CLIENTE = d.ID_CLIENTE
    JOIN Personas.CP_CORREDOR cc
        ON d.ID_CPDIR BETWEEN cc.CP_INICIAL AND cc.CP_FINAL
    WHERE c.ID_CORREDOR IS NULL;
END;
GO

/* ----------------------------------------------------------------------------
   Operaciones.trg_ActualizaSaldoPendiente
   Recalcula el saldo pendiente de las pólizas afectadas cada vez que se
   registra, modifica o elimina un pago.
---------------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER Operaciones.trg_ActualizaSaldoPendiente
ON Operaciones.PAGO
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET p.SALDO_PENDIENTE = Operaciones.fn_SaldoPendiente(p.NUM_POLIZA)
    FROM Operaciones.POLIZA p
    WHERE p.NUM_POLIZA IN (SELECT NUM_POLIZA FROM inserted
                           UNION
                           SELECT NUM_POLIZA FROM deleted);
END;
GO

/* ----------------------------------------------------------------------------
   Operaciones.trg_ValidaEdadContratacionVida
   Impide contratar un seguro de vida (clave 100) si, en la fecha de inicio de
   la póliza, el cliente supera la edad máxima de contratación definida en
   Seguros.SEGURO_VIDA.
---------------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER Operaciones.trg_ValidaEdadContratacionVida
ON Operaciones.POLIZA
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Seguros.SEGURO_VIDA sv
            ON sv.CLAVE_SEGURO = i.CLAVE_SEGURO
        WHERE Personas.fn_EdadClienteEnFecha(i.ID_CLIENTE, i.FECHA_INICIO) > sv.EDAD_MAXIM_CONTR
    )
    BEGIN
        RAISERROR('El cliente supera la edad máxima permitida para contratar un seguro de vida.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

/* ============================================================================
   VISTAS
   ============================================================================ */

/* ----------------------------------------------------------------------------
   Operaciones.v_SiniestrosConDias
   Siniestros junto con los días transcurridos desde que ocurrieron.
---------------------------------------------------------------------------- */
CREATE OR ALTER VIEW Operaciones.v_SiniestrosConDias
AS
SELECT
    s.NUM_SINIESTRO,
    s.NUM_POLIZA,
    s.FECHA_HORA,
    s.LUGAR,
    s.CAUSA,
    s.MONTO_INDEMNIZ,
    s.FECHA_REGISTRO,
    Operaciones.fn_DiasTranscurridosSiniestro(s.NUM_SINIESTRO) AS DIAS_TRANSCURRIDOS
FROM Operaciones.SINIESTRO s;
GO

/* ----------------------------------------------------------------------------
   Operaciones.v_ClienteEstadisticas
   Resumen por cliente: número de pólizas, tipos de seguro distintos,
   cotizaciones, prima total contratada, total pagado y saldo pendiente.
   Cada métrica se calcula en su propia subconsulta para que los totales no se
   multipliquen al combinar pólizas, pagos y cotizaciones.
---------------------------------------------------------------------------- */
CREATE OR ALTER VIEW Operaciones.v_ClienteEstadisticas
AS
SELECT
    c.ID_CLIENTE,
    c.NOMBRE,
    c.APELLIDO_P,
    c.APELLIDO_M,
    ISNULL(pol.NUM_POLIZAS, 0)            AS NUM_POLIZAS,
    ISNULL(pol.TIPOS_SEGURO_DISTINTOS, 0) AS TIPOS_SEGURO_DISTINTOS,
    ISNULL(cot.NUM_COTIZACIONES, 0)       AS NUM_COTIZACIONES,
    ISNULL(pol.PRIMA_TOTAL, 0)            AS PRIMA_TOTAL,
    ISNULL(pag.TOTAL_PAGADO, 0)           AS TOTAL_PAGADO,
    ISNULL(pol.SALDO_PENDIENTE_TOTAL, 0)  AS SALDO_PENDIENTE_TOTAL
FROM Personas.CLIENTE c
LEFT JOIN (
    SELECT
        ID_CLIENTE,
        COUNT(*)                      AS NUM_POLIZAS,
        COUNT(DISTINCT CLAVE_SEGURO)  AS TIPOS_SEGURO_DISTINTOS,
        SUM(MONTO_PRIMA_TOT)          AS PRIMA_TOTAL,
        SUM(ISNULL(SALDO_PENDIENTE, 0)) AS SALDO_PENDIENTE_TOTAL
    FROM Operaciones.POLIZA
    GROUP BY ID_CLIENTE
) pol
    ON pol.ID_CLIENTE = c.ID_CLIENTE
LEFT JOIN (
    SELECT ID_CLIENTE, COUNT(*) AS NUM_COTIZACIONES
    FROM Operaciones.COTIZACION
    GROUP BY ID_CLIENTE
) cot
    ON cot.ID_CLIENTE = c.ID_CLIENTE
LEFT JOIN (
    SELECT p.ID_CLIENTE, SUM(pg.MONTO_PAGADO) AS TOTAL_PAGADO
    FROM Operaciones.PAGO pg
    JOIN Operaciones.POLIZA p
        ON p.NUM_POLIZA = pg.NUM_POLIZA
    WHERE pg.STSPAGO = 'PAGADO'
    GROUP BY p.ID_CLIENTE
) pag
    ON pag.ID_CLIENTE = c.ID_CLIENTE;
GO

/* ----------------------------------------------------------------------------
   Operaciones.v_PolizaFinanzas
   Estatus financiero de cada póliza: total pagado, número de pagos,
   porcentaje pagado, monto restante y si está al corriente o con atraso.
---------------------------------------------------------------------------- */
CREATE OR ALTER VIEW Operaciones.v_PolizaFinanzas
AS
SELECT
    p.NUM_POLIZA,
    p.ID_CLIENTE,
    cl.NOMBRE + ' ' + cl.APELLIDO_P + ISNULL(' ' + cl.APELLIDO_M, '') AS CLIENTE,
    p.MONTO_PRIMA_TOT,
    ISNULL(pg.TOTAL_PAGADO, 0)                                      AS TOTAL_PAGADO,
    ISNULL(pg.NUM_PAGOS, 0)                                         AS NUM_PAGOS,
    CAST(ISNULL(pg.TOTAL_PAGADO, 0) * 100.0 / p.MONTO_PRIMA_TOT
         AS DECIMAL(5,2))                                           AS PORCENTAJE_PAGADO,
    p.SALDO_PENDIENTE                                               AS MONTO_RESTANTE,
    CASE
        WHEN p.SALDO_PENDIENTE <= 0                         THEN 'LIQUIDADA'
        WHEN ISNULL(pg.TOTAL_PAGADO, 0) = 0                 THEN 'SIN PAGOS'
        WHEN pg.TOTAL_PAGADO < p.MONTO_PRIMA_TOT * 0.5      THEN 'ATRASO'
        ELSE 'EN CURSO'
    END                                                             AS ESTATUS_FINANCIERO
FROM Operaciones.POLIZA p
JOIN Personas.CLIENTE cl
    ON cl.ID_CLIENTE = p.ID_CLIENTE
LEFT JOIN (
    SELECT
        NUM_POLIZA,
        SUM(MONTO_PAGADO) AS TOTAL_PAGADO,
        COUNT(*)          AS NUM_PAGOS
    FROM Operaciones.PAGO
    WHERE STSPAGO = 'PAGADO'
    GROUP BY NUM_POLIZA
) pg
    ON pg.NUM_POLIZA = p.NUM_POLIZA;
GO

/* ============================================================================
   PROCEDIMIENTOS ALMACENADOS
   Los consecutivos se obtienen con MAX() + 1, porque las tablas no usan
   IDENTITY.
   ============================================================================ */

/* ----------------------------------------------------------------------------
   Operaciones.sp_RegistrarCotizacion
   Registra una cotización nueva y devuelve su número.
---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE Operaciones.sp_RegistrarCotizacion
    @id_cliente          INT,
    @fecha_cotiz         DATE,
    @monto_est_prima     DECIMAL(14,2),
    @estado              VARCHAR(40),
    @recordatorio        VARCHAR(400) = NULL,
    @vigencia_dias       VARCHAR(40),
    @num_cotizacion_out  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Personas.CLIENTE WHERE ID_CLIENTE = @id_cliente)
    BEGIN
        RAISERROR('El cliente indicado no existe.', 16, 1);
        RETURN;
    END;

    IF @monto_est_prima <= 0
    BEGIN
        RAISERROR('El monto estimado de prima debe ser mayor que 0.', 16, 1);
        RETURN;
    END;

    SELECT @num_cotizacion_out = ISNULL(MAX(NUM_COTIZACION), 0) + 1
    FROM Operaciones.COTIZACION;

    INSERT INTO Operaciones.COTIZACION
        (NUM_COTIZACION, ID_CLIENTE, FECHA_COTIZ, MONTO_EST_PRIMA,
         ESTADO, RECORDATORIO, VIGENCIA_DIAS)
    VALUES
        (@num_cotizacion_out, @id_cliente, @fecha_cotiz, @monto_est_prima,
         @estado, @recordatorio, @vigencia_dias);
END;
GO

/* ----------------------------------------------------------------------------
   Operaciones.sp_RegistrarPoliza
   Registra una póliza de cualquier tipo de seguro y devuelve su número.
   El saldo pendiente inicial es igual a la prima total.
---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE Operaciones.sp_RegistrarPoliza
    @id_cliente       INT,
    @id_corredor      INT,
    @clave_seguro     VARCHAR(30),
    @fecha_inicio     DATE,
    @fecha_fin        DATE,
    @monto_prima_tot  DECIMAL(14,2),
    @estado_poliza    VARCHAR(20) = 'ACTIVA',
    @num_poliza_out   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Personas.CLIENTE WHERE ID_CLIENTE = @id_cliente)
    BEGIN
        RAISERROR('El cliente indicado no existe.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM Personas.CORREDOR WHERE ID_CORREDOR = @id_corredor)
    BEGIN
        RAISERROR('El corredor indicado no existe.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM Seguros.TIPO_SEGURO WHERE CLAVE_SEGURO = @clave_seguro)
    BEGIN
        RAISERROR('La clave de seguro indicada no existe en TIPO_SEGURO.', 16, 1);
        RETURN;
    END;

    IF @monto_prima_tot <= 0
    BEGIN
        RAISERROR('El monto de la prima total debe ser mayor que 0.', 16, 1);
        RETURN;
    END;

    IF @fecha_fin <= @fecha_inicio
    BEGIN
        RAISERROR('La fecha de fin debe ser mayor que la fecha de inicio.', 16, 1);
        RETURN;
    END;

    SELECT @num_poliza_out = ISNULL(MAX(NUM_POLIZA), 0) + 1
    FROM Operaciones.POLIZA;

    INSERT INTO Operaciones.POLIZA
        (NUM_POLIZA, ID_CLIENTE, ID_CORREDOR, CLAVE_SEGURO, FECHA_INICIO,
         FECHA_FIN, SALDO_PENDIENTE, MONTO_PRIMA_TOT, ESTADO_POLIZA)
    VALUES
        (@num_poliza_out, @id_cliente, @id_corredor, @clave_seguro, @fecha_inicio,
         @fecha_fin, @monto_prima_tot, @monto_prima_tot, @estado_poliza);
END;
GO

/* ----------------------------------------------------------------------------
   Operaciones.sp_RegistrarPolizaVida / Auto / Retiro
   Atajos para registrar una póliza activa de un tipo específico.
   Reutilizan sp_RegistrarPoliza para no duplicar las validaciones.
---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE Operaciones.sp_RegistrarPolizaVida
    @id_cliente       INT,
    @id_corredor      INT,
    @fecha_inicio     DATE,
    @fecha_fin        DATE,
    @monto_prima_tot  DECIMAL(14,2),
    @num_poliza_out   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    EXEC Operaciones.sp_RegistrarPoliza
        @id_cliente      = @id_cliente,
        @id_corredor     = @id_corredor,
        @clave_seguro    = '100',          -- Seguro de vida
        @fecha_inicio    = @fecha_inicio,
        @fecha_fin       = @fecha_fin,
        @monto_prima_tot = @monto_prima_tot,
        @estado_poliza   = 'ACTIVA',
        @num_poliza_out  = @num_poliza_out OUTPUT;
END;
GO

CREATE OR ALTER PROCEDURE Operaciones.sp_RegistrarPolizaRetiro
    @id_cliente       INT,
    @id_corredor      INT,
    @fecha_inicio     DATE,
    @fecha_fin        DATE,
    @monto_prima_tot  DECIMAL(14,2),
    @num_poliza_out   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    EXEC Operaciones.sp_RegistrarPoliza
        @id_cliente      = @id_cliente,
        @id_corredor     = @id_corredor,
        @clave_seguro    = '200',          -- Seguro de retiro
        @fecha_inicio    = @fecha_inicio,
        @fecha_fin       = @fecha_fin,
        @monto_prima_tot = @monto_prima_tot,
        @estado_poliza   = 'ACTIVA',
        @num_poliza_out  = @num_poliza_out OUTPUT;
END;
GO

CREATE OR ALTER PROCEDURE Operaciones.sp_RegistrarPolizaAuto
    @id_cliente       INT,
    @id_corredor      INT,
    @fecha_inicio     DATE,
    @fecha_fin        DATE,
    @monto_prima_tot  DECIMAL(14,2),
    @num_poliza_out   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    EXEC Operaciones.sp_RegistrarPoliza
        @id_cliente      = @id_cliente,
        @id_corredor     = @id_corredor,
        @clave_seguro    = '300',          -- Seguro de auto
        @fecha_inicio    = @fecha_inicio,
        @fecha_fin       = @fecha_fin,
        @monto_prima_tot = @monto_prima_tot,
        @estado_poliza   = 'ACTIVA',
        @num_poliza_out  = @num_poliza_out OUTPUT;
END;
GO

/* ----------------------------------------------------------------------------
   Operaciones.sp_RegistrarPago
   Registra un pago de una póliza y devuelve su ID. El número de pago se
   calcula como consecutivo dentro de la póliza. El saldo pendiente se
   actualiza automáticamente con trg_ActualizaSaldoPendiente.
---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE Operaciones.sp_RegistrarPago
    @num_poliza    INT,
    @stspago       VARCHAR(40),
    @fecha_pago    DATE,
    @monto_pagado  DECIMAL(14,2),
    @metodo_pago   VARCHAR(50),
    @id_pago_out   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @num_pago INT;

    IF NOT EXISTS (SELECT 1 FROM Operaciones.POLIZA WHERE NUM_POLIZA = @num_poliza)
    BEGIN
        RAISERROR('La póliza indicada no existe.', 16, 1);
        RETURN;
    END;

    IF @monto_pagado <= 0
    BEGIN
        RAISERROR('El monto pagado debe ser mayor que 0.', 16, 1);
        RETURN;
    END;

    IF @stspago NOT IN ('PAGADO', 'PENDIENTE')
    BEGIN
        RAISERROR('El estatus de pago debe ser PAGADO o PENDIENTE.', 16, 1);
        RETURN;
    END;

    SELECT @id_pago_out = ISNULL(MAX(ID_PAGO), 0) + 1
    FROM Operaciones.PAGO;

    SELECT @num_pago = ISNULL(MAX(NUM_PAGO), 0) + 1
    FROM Operaciones.PAGO
    WHERE NUM_POLIZA = @num_poliza;

    INSERT INTO Operaciones.PAGO
        (ID_PAGO, NUM_POLIZA, STSPAGO, NUM_PAGO, FECHA_PAGO, MONTO_PAGADO, METODO_PAGO)
    VALUES
        (@id_pago_out, @num_poliza, @stspago, @num_pago, @fecha_pago, @monto_pagado, @metodo_pago);
END;
GO

/* ----------------------------------------------------------------------------
   Operaciones.sp_RegistrarSiniestro
   Registra un siniestro sobre una póliza y devuelve su número.
---------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE Operaciones.sp_RegistrarSiniestro
    @num_poliza         INT,
    @fecha_hora         DATETIME,
    @lugar              VARCHAR(400),
    @causa              VARCHAR(400),
    @monto_indemniz     DECIMAL(14,2),
    @num_siniestro_out  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Operaciones.POLIZA WHERE NUM_POLIZA = @num_poliza)
    BEGIN
        RAISERROR('La póliza indicada no existe.', 16, 1);
        RETURN;
    END;

    IF @monto_indemniz <= 0
    BEGIN
        RAISERROR('El monto de indemnización debe ser mayor que 0.', 16, 1);
        RETURN;
    END;

    SELECT @num_siniestro_out = ISNULL(MAX(NUM_SINIESTRO), 0) + 1
    FROM Operaciones.SINIESTRO;

    INSERT INTO Operaciones.SINIESTRO
        (NUM_SINIESTRO, NUM_POLIZA, FECHA_HORA, LUGAR, CAUSA,
         MONTO_INDEMNIZ, FECHA_REGISTRO)
    VALUES
        (@num_siniestro_out, @num_poliza, @fecha_hora, @lugar, @causa,
         @monto_indemniz, CAST(GETDATE() AS DATE));
END;
GO
