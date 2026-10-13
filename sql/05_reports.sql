/* ============================================================================
   Proyecto : Sistema de Base de Datos para una Aseguradora (ASEGURADORA06)
   Archivo  : 05_reports.sql
   Contenido: Consultas de informes y estadísticas sobre pólizas, clientes,
              corredores, cotizaciones, pagos y siniestros.
   Autores  : Aranda Marrón Fernando
              Chacón Jaral Hugo Emmanuel
              Gutiérrez Nolasco Emiliano
   Fecha    : 30/11/2025
   Motor    : Microsoft SQL Server 2019 o superior
   Orden    : 5 de 6 (requiere los scripts 01 a 03)
   ============================================================================ */

USE ASEGURADORA06;
GO

/* ----------------------------------------------------------------------------
   Fecha de corte de los reportes que dependen de un periodo
   (último mes, último trimestre, último año, etc.).
   Por defecto es la fecha actual. Los datos de prueba son de 2025, así que
   para ver resultados en esos reportes se puede usar, por ejemplo:
       DECLARE @FechaCorte DATE = '2025-04-30';
   El script se ejecuta como un solo lote para que la variable esté
   disponible en todas las consultas.
---------------------------------------------------------------------------- */
DECLARE @FechaCorte DATE = CAST(GETDATE() AS DATE);

/* ============================================================================
   INFORMES OPERATIVOS
   ============================================================================ */

-- Informe 1. Pólizas activas por corredor, con su cliente y fecha de vencimiento
SELECT
    co.ID_CORREDOR,
    co.NOMBRE + ' ' + co.APELLIDOPAT + ISNULL(' ' + co.APELLIDOMAT, '') AS NombreCorredor,
    cl.ID_CLIENTE,
    cl.NOMBRE + ' ' + cl.APELLIDO_P  + ISNULL(' ' + cl.APELLIDO_M, '')  AS NombreCliente,
    p.NUM_POLIZA,
    p.FECHA_FIN                                                          AS FechaVencimiento
FROM Operaciones.POLIZA p
JOIN Personas.CLIENTE cl
    ON p.ID_CLIENTE = cl.ID_CLIENTE
JOIN Personas.CORREDOR co
    ON p.ID_CORREDOR = co.ID_CORREDOR
WHERE p.ESTADO_POLIZA = 'ACTIVA'
ORDER BY co.ID_CORREDOR, p.NUM_POLIZA;

-- Informe 2. Total de primas vendidas por corredor en el último trimestre
SELECT
    co.ID_CORREDOR,
    co.NOMBRE + ' ' + co.APELLIDOPAT + ISNULL(' ' + co.APELLIDOMAT, '') AS NombreCorredor,
    SUM(p.MONTO_PRIMA_TOT)                                               AS TotalPrimasTrimestre
FROM Operaciones.POLIZA p
JOIN Personas.CORREDOR co
    ON p.ID_CORREDOR = co.ID_CORREDOR
WHERE p.FECHA_INICIO >  DATEADD(MONTH, -3, @FechaCorte)
  AND p.FECHA_INICIO <= @FechaCorte
GROUP BY co.ID_CORREDOR, co.NOMBRE, co.APELLIDOPAT, co.APELLIDOMAT
ORDER BY TotalPrimasTrimestre DESC;

-- Informe 3. Cotizaciones pendientes o en revisión de los últimos 60 días, por
--            tipo de seguro.
--            Nota: el tipo de seguro se obtiene con TIPO_SEGURO.NUM_COTIZACION,
--            que es la única relación entre ambas tablas en el modelo actual.
SELECT
    ts.NOMBRE                    AS TipoSeguro,
    COUNT(cot.NUM_COTIZACION)    AS CotizacionesPendientes
FROM Operaciones.COTIZACION cot
JOIN Seguros.TIPO_SEGURO ts
    ON ts.NUM_COTIZACION = cot.NUM_COTIZACION
WHERE cot.FECHA_COTIZ >  DATEADD(DAY, -60, @FechaCorte)
  AND cot.FECHA_COTIZ <= @FechaCorte
  AND cot.ESTADO IN ('PENDIENTE', 'REVISIÓN')
GROUP BY ts.NOMBRE
ORDER BY CotizacionesPendientes DESC;

-- Informe 4. Clientes que tienen seguro de vida (100) y seguro de retiro (200)
SELECT
    cl.ID_CLIENTE,
    cl.NOMBRE + ' ' + cl.APELLIDO_P + ISNULL(' ' + cl.APELLIDO_M, '') AS NombreCliente
FROM Personas.CLIENTE cl
JOIN Operaciones.POLIZA p
    ON cl.ID_CLIENTE = p.ID_CLIENTE
WHERE p.CLAVE_SEGURO IN ('100', '200')
GROUP BY cl.ID_CLIENTE, cl.NOMBRE, cl.APELLIDO_P, cl.APELLIDO_M
HAVING COUNT(DISTINCT p.CLAVE_SEGURO) = 2
ORDER BY cl.ID_CLIENTE;

-- Informe 5. Pólizas con saldo pendiente, ordenadas por fecha de vencimiento
SELECT
    p.NUM_POLIZA,
    p.SALDO_PENDIENTE,
    p.FECHA_FIN AS FechaVencimiento
FROM Operaciones.POLIZA p
WHERE p.SALDO_PENDIENTE > 0
ORDER BY p.FECHA_FIN, p.NUM_POLIZA;

-- Informe 6. Indemnización promedio por tipo de seguro de los siniestros del
--            mes anterior a la fecha de corte
SELECT
    ts.NOMBRE              AS TipoSeguro,
    AVG(s.MONTO_INDEMNIZ)  AS IndemnizacionPromedio,
    COUNT(*)               AS TotalSiniestros
FROM Operaciones.SINIESTRO s
JOIN Operaciones.POLIZA p
    ON s.NUM_POLIZA = p.NUM_POLIZA
JOIN Seguros.TIPO_SEGURO ts
    ON p.CLAVE_SEGURO = ts.CLAVE_SEGURO
WHERE MONTH(s.FECHA_HORA) = MONTH(DATEADD(MONTH, -1, @FechaCorte))
  AND YEAR(s.FECHA_HORA)  = YEAR(DATEADD(MONTH, -1, @FechaCorte))
GROUP BY ts.NOMBRE;

-- Informe 7. Vehículos asegurados por marca y modelo
SELECT
    v.MARCA,
    v.MODELO,
    COUNT(*) AS VehiculosAsegurados
FROM Seguros.VEHICULO v
GROUP BY v.MARCA, v.MODELO
ORDER BY v.MARCA, v.MODELO;

/* ============================================================================
   ESTADÍSTICAS
   ============================================================================ */

-- Estadística 1. Número de clientes con al menos una póliza activa
SELECT COUNT(DISTINCT c.ID_CLIENTE) AS ClientesActivos
FROM Personas.CLIENTE c
JOIN Operaciones.POLIZA p
    ON c.ID_CLIENTE = p.ID_CLIENTE
WHERE p.ESTADO_POLIZA = 'ACTIVA';

-- Estadística 2. Pólizas activas por tipo de seguro
SELECT
    ts.NOMBRE  AS TipoSeguro,
    COUNT(*)   AS PolizasActivas
FROM Operaciones.POLIZA p
JOIN Seguros.TIPO_SEGURO ts
    ON p.CLAVE_SEGURO = ts.CLAVE_SEGURO
WHERE p.ESTADO_POLIZA = 'ACTIVA'
GROUP BY ts.NOMBRE
ORDER BY ts.NOMBRE;

-- Estadística 3. Prima promedio por tipo de seguro
SELECT
    ts.NOMBRE               AS TipoSeguro,
    AVG(p.MONTO_PRIMA_TOT)  AS PrimaPromedio
FROM Operaciones.POLIZA p
JOIN Seguros.TIPO_SEGURO ts
    ON p.CLAVE_SEGURO = ts.CLAVE_SEGURO
GROUP BY ts.NOMBRE
ORDER BY ts.NOMBRE;

-- Estadística 4. Primas de las pólizas iniciadas en el último mes
SELECT ISNULL(SUM(MONTO_PRIMA_TOT), 0) AS PrimasUltimoMes
FROM Operaciones.POLIZA
WHERE FECHA_INICIO >  DATEADD(MONTH, -1, @FechaCorte)
  AND FECHA_INICIO <= @FechaCorte;

-- Estadística 5. Siniestros por causa en el último año
SELECT
    CAUSA,
    COUNT(*) AS TotalSiniestros
FROM Operaciones.SINIESTRO
WHERE FECHA_HORA >  DATEADD(YEAR, -1, @FechaCorte)
  AND FECHA_HORA <= DATEADD(DAY, 1, @FechaCorte)
GROUP BY CAUSA
ORDER BY TotalSiniestros DESC, CAUSA;

-- Estadística 6. Clientes por ciudad
SELECT
    cp.CIUDAD,
    COUNT(c.ID_CLIENTE) AS TotalClientes
FROM Personas.CLIENTE c
JOIN Personas.DIRECCIONCP cp
    ON c.ID_CLIENTE = cp.ID_CLIENTE
GROUP BY cp.CIUDAD
ORDER BY TotalClientes DESC;

-- Estadística 7. Los 5 corredores con más prima vendida
SELECT TOP (5)
    co.ID_CORREDOR,
    co.NOMBRE + ' ' + co.APELLIDOPAT + ISNULL(' ' + co.APELLIDOMAT, '') AS Corredor,
    SUM(p.MONTO_PRIMA_TOT)                                               AS TotalPrimaVendida
FROM Operaciones.POLIZA p
JOIN Personas.CORREDOR co
    ON p.ID_CORREDOR = co.ID_CORREDOR
GROUP BY co.ID_CORREDOR, co.NOMBRE, co.APELLIDOPAT, co.APELLIDOMAT
ORDER BY TotalPrimaVendida DESC;

-- Estadística 8. Porcentaje de pagos realizados después del fin de la póliza
SELECT
    CAST(
        100.0 * SUM(CASE WHEN pg.FECHA_PAGO > p.FECHA_FIN THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
    AS DECIMAL(5,2)) AS PorcentajePagosFueraDeVigencia
FROM Operaciones.PAGO pg
JOIN Operaciones.POLIZA p
    ON pg.NUM_POLIZA = p.NUM_POLIZA;

-- Estadística 9. Edad promedio de los clientes con seguro de vida activo
SELECT
    AVG(Personas.fn_EdadClienteEnFecha(c.ID_CLIENTE, @FechaCorte)) AS EdadPromedio
FROM Personas.CLIENTE c
WHERE EXISTS (
    SELECT 1
    FROM Operaciones.POLIZA p
    WHERE p.ID_CLIENTE    = c.ID_CLIENTE
      AND p.CLAVE_SEGURO  = '100'
      AND p.ESTADO_POLIZA = 'ACTIVA'
);

-- Estadística 10. Morosidad: porcentaje de pólizas activas con al menos un
--                 pago pendiente
SELECT
    CAST(
        100.0 * COUNT(DISTINCT CASE WHEN pg.STSPAGO = 'PENDIENTE' THEN p.NUM_POLIZA END)
        / NULLIF(COUNT(DISTINCT p.NUM_POLIZA), 0)
    AS DECIMAL(5,2)) AS PorcentajeMorosidad
FROM Operaciones.POLIZA p
LEFT JOIN Operaciones.PAGO pg
    ON pg.NUM_POLIZA = p.NUM_POLIZA
WHERE p.ESTADO_POLIZA = 'ACTIVA';
GO
