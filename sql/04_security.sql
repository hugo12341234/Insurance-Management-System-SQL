/* ============================================================================
   Proyecto : Sistema de Base de Datos para una Aseguradora (ASEGURADORA06)
   Archivo  : 04_security.sql
   Contenido: DCL. Crea los roles del sistema, asigna permisos según las
              funciones de cada puesto y crea los usuarios de ejemplo.
   Autores  : Aranda Marrón Fernando
              Chacón Jaral Hugo Emmanuel
              Gutiérrez Nolasco Emiliano
   Fecha    : 30/11/2025
   Motor    : Microsoft SQL Server 2019 o superior
   Orden    : 4 de 6 (requiere 01_schema.sql y 02_logic.sql)
   Nota     : Las contraseñas de este archivo son solo de ejemplo para un
              entorno local. No deben usarse en un servidor real.
   ============================================================================ */

USE ASEGURADORA06;
GO

/* ============================================================================
   1. ROLES (uno por tipo de puesto)
   ============================================================================ */
CREATE ROLE ADMINISTRADOR_SEGURO;
CREATE ROLE GERENTE;
CREATE ROLE JEFE_COMERCIAL;
CREATE ROLE JEFE_AGENCIA;
CREATE ROLE ASESOR_COMERCIAL;
GO

/* ============================================================================
   2. PERMISOS DE LECTURA (SELECT)
   ============================================================================ */

-- Clientes y sus datos
GRANT SELECT ON Personas.CLIENTE      TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL, JEFE_AGENCIA, ASESOR_COMERCIAL;
GRANT SELECT ON Personas.DIRECCION    TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL, JEFE_AGENCIA, ASESOR_COMERCIAL;
GRANT SELECT ON Personas.CONTACTO     TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL, JEFE_AGENCIA, ASESOR_COMERCIAL;
GRANT SELECT ON Personas.BENEFICIARIO TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL, JEFE_AGENCIA;

-- Empleados y corredores
GRANT SELECT ON Personas.CORREDOR     TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL, JEFE_AGENCIA;
GRANT SELECT ON Personas.AJUSTADOR    TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_AGENCIA;
GRANT SELECT ON Personas.CP_CORREDOR  TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL, JEFE_AGENCIA;

-- Seguros
GRANT SELECT ON Seguros.TIPO_SEGURO   TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL, ASESOR_COMERCIAL;
GRANT SELECT ON Seguros.SEGURO_AUTO   TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL, ASESOR_COMERCIAL;
GRANT SELECT ON Seguros.SEGURO_VIDA   TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL, ASESOR_COMERCIAL;
GRANT SELECT ON Seguros.SEGURO_RETIRO TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL, ASESOR_COMERCIAL;
GRANT SELECT ON Seguros.VEHICULO      TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL, ASESOR_COMERCIAL;

-- Pólizas, pagos y siniestros
GRANT SELECT ON Operaciones.POLIZA    TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL, ASESOR_COMERCIAL;
GRANT SELECT ON Operaciones.PAGO      TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL, ASESOR_COMERCIAL;
GRANT SELECT ON Operaciones.SINIESTRO TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL;

-- Cotizaciones y bitácora
GRANT SELECT ON Operaciones.COTIZACION            TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL, ASESOR_COMERCIAL;
GRANT SELECT ON Operaciones.BITACORA_COTIZACIONES TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL, ASESOR_COMERCIAL;

-- Vistas de reportes
GRANT SELECT ON Operaciones.v_SiniestrosConDias   TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL;
GRANT SELECT ON Operaciones.v_ClienteEstadisticas TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL;
GRANT SELECT ON Operaciones.v_PolizaFinanzas      TO ADMINISTRADOR_SEGURO, GERENTE, JEFE_COMERCIAL;
GO

/* ============================================================================
   3. PERMISOS DE INSERCIÓN (INSERT)
   ============================================================================ */

-- Clientes (administrados por asesores y administradores)
GRANT INSERT ON Personas.CLIENTE      TO ADMINISTRADOR_SEGURO, ASESOR_COMERCIAL;
GRANT INSERT ON Personas.DIRECCION    TO ADMINISTRADOR_SEGURO, ASESOR_COMERCIAL;
GRANT INSERT ON Personas.CONTACTO     TO ADMINISTRADOR_SEGURO, ASESOR_COMERCIAL;
GRANT INSERT ON Personas.BENEFICIARIO TO ADMINISTRADOR_SEGURO;

-- Empleados y corredores (solo administradores)
GRANT INSERT ON Personas.CORREDOR     TO ADMINISTRADOR_SEGURO;
GRANT INSERT ON Personas.AJUSTADOR    TO ADMINISTRADOR_SEGURO;
GRANT INSERT ON Personas.CP_CORREDOR  TO ADMINISTRADOR_SEGURO;

-- Seguros (administradores y jefes comerciales)
GRANT INSERT ON Seguros.TIPO_SEGURO   TO ADMINISTRADOR_SEGURO, JEFE_COMERCIAL;
GRANT INSERT ON Seguros.SEGURO_AUTO   TO ADMINISTRADOR_SEGURO, JEFE_COMERCIAL;
GRANT INSERT ON Seguros.SEGURO_VIDA   TO ADMINISTRADOR_SEGURO, JEFE_COMERCIAL;
GRANT INSERT ON Seguros.SEGURO_RETIRO TO ADMINISTRADOR_SEGURO, JEFE_COMERCIAL;
GRANT INSERT ON Seguros.VEHICULO      TO ADMINISTRADOR_SEGURO, JEFE_COMERCIAL;

-- Pólizas, pagos y siniestros
GRANT INSERT ON Operaciones.POLIZA    TO ADMINISTRADOR_SEGURO, ASESOR_COMERCIAL, JEFE_COMERCIAL;
GRANT INSERT ON Operaciones.PAGO      TO ADMINISTRADOR_SEGURO, ASESOR_COMERCIAL;
GRANT INSERT ON Operaciones.SINIESTRO TO ADMINISTRADOR_SEGURO;

-- Cotizaciones y bitácora (asesores y jefes)
GRANT INSERT ON Operaciones.COTIZACION            TO ADMINISTRADOR_SEGURO, ASESOR_COMERCIAL, JEFE_COMERCIAL;
GRANT INSERT ON Operaciones.BITACORA_COTIZACIONES TO ADMINISTRADOR_SEGURO, ASESOR_COMERCIAL, JEFE_COMERCIAL;
GO

/* ============================================================================
   4. PERMISOS DE ACTUALIZACIÓN (UPDATE)
   ============================================================================ */

-- Clientes
GRANT UPDATE ON Personas.CLIENTE      TO ADMINISTRADOR_SEGURO, ASESOR_COMERCIAL;
GRANT UPDATE ON Personas.DIRECCION    TO ADMINISTRADOR_SEGURO, ASESOR_COMERCIAL;
GRANT UPDATE ON Personas.CONTACTO     TO ADMINISTRADOR_SEGURO, ASESOR_COMERCIAL;
GRANT UPDATE ON Personas.BENEFICIARIO TO ADMINISTRADOR_SEGURO;

-- Empleados y corredores
GRANT UPDATE ON Personas.CORREDOR     TO ADMINISTRADOR_SEGURO, JEFE_AGENCIA;
GRANT UPDATE ON Personas.AJUSTADOR    TO ADMINISTRADOR_SEGURO;
GRANT UPDATE ON Personas.CP_CORREDOR  TO ADMINISTRADOR_SEGURO;

-- Seguros
GRANT UPDATE ON Seguros.TIPO_SEGURO   TO ADMINISTRADOR_SEGURO, JEFE_COMERCIAL;
GRANT UPDATE ON Seguros.SEGURO_AUTO   TO ADMINISTRADOR_SEGURO, JEFE_COMERCIAL;
GRANT UPDATE ON Seguros.SEGURO_VIDA   TO ADMINISTRADOR_SEGURO, JEFE_COMERCIAL;
GRANT UPDATE ON Seguros.SEGURO_RETIRO TO ADMINISTRADOR_SEGURO, JEFE_COMERCIAL;
GRANT UPDATE ON Seguros.VEHICULO      TO ADMINISTRADOR_SEGURO, JEFE_COMERCIAL;

-- Pólizas, pagos y siniestros
GRANT UPDATE ON Operaciones.POLIZA    TO ADMINISTRADOR_SEGURO, JEFE_COMERCIAL;
GRANT UPDATE ON Operaciones.PAGO      TO ADMINISTRADOR_SEGURO;
GRANT UPDATE ON Operaciones.SINIESTRO TO ADMINISTRADOR_SEGURO;

-- Cotizaciones y bitácora
GRANT UPDATE ON Operaciones.COTIZACION            TO ADMINISTRADOR_SEGURO, ASESOR_COMERCIAL, JEFE_COMERCIAL;
GRANT UPDATE ON Operaciones.BITACORA_COTIZACIONES TO ADMINISTRADOR_SEGURO, JEFE_COMERCIAL;
GO

/* ============================================================================
   5. PERMISOS DE BORRADO (DELETE): solo administradores
   ============================================================================ */
GRANT DELETE ON Personas.CLIENTE      TO ADMINISTRADOR_SEGURO;
GRANT DELETE ON Personas.DIRECCION    TO ADMINISTRADOR_SEGURO;
GRANT DELETE ON Personas.CONTACTO     TO ADMINISTRADOR_SEGURO;
GRANT DELETE ON Personas.BENEFICIARIO TO ADMINISTRADOR_SEGURO;
GRANT DELETE ON Personas.CORREDOR     TO ADMINISTRADOR_SEGURO;
GRANT DELETE ON Personas.AJUSTADOR    TO ADMINISTRADOR_SEGURO;
GRANT DELETE ON Personas.CP_CORREDOR  TO ADMINISTRADOR_SEGURO;

GRANT DELETE ON Seguros.TIPO_SEGURO   TO ADMINISTRADOR_SEGURO;
GRANT DELETE ON Seguros.SEGURO_AUTO   TO ADMINISTRADOR_SEGURO;
GRANT DELETE ON Seguros.SEGURO_VIDA   TO ADMINISTRADOR_SEGURO;
GRANT DELETE ON Seguros.SEGURO_RETIRO TO ADMINISTRADOR_SEGURO;
GRANT DELETE ON Seguros.VEHICULO      TO ADMINISTRADOR_SEGURO;

GRANT DELETE ON Operaciones.POLIZA                TO ADMINISTRADOR_SEGURO;
GRANT DELETE ON Operaciones.PAGO                  TO ADMINISTRADOR_SEGURO;
GRANT DELETE ON Operaciones.SINIESTRO             TO ADMINISTRADOR_SEGURO;
GRANT DELETE ON Operaciones.COTIZACION            TO ADMINISTRADOR_SEGURO;
GRANT DELETE ON Operaciones.BITACORA_COTIZACIONES TO ADMINISTRADOR_SEGURO;
GO

/* ============================================================================
   6. PERMISOS DE EJECUCIÓN DE PROCEDIMIENTOS (EXECUTE)
      Siguen las mismas reglas que los permisos de INSERT de cada tabla.
   ============================================================================ */
GRANT EXECUTE ON Operaciones.sp_RegistrarCotizacion   TO ADMINISTRADOR_SEGURO, ASESOR_COMERCIAL, JEFE_COMERCIAL;
GRANT EXECUTE ON Operaciones.sp_RegistrarPoliza       TO ADMINISTRADOR_SEGURO, ASESOR_COMERCIAL, JEFE_COMERCIAL;
GRANT EXECUTE ON Operaciones.sp_RegistrarPolizaVida   TO ADMINISTRADOR_SEGURO, ASESOR_COMERCIAL, JEFE_COMERCIAL;
GRANT EXECUTE ON Operaciones.sp_RegistrarPolizaRetiro TO ADMINISTRADOR_SEGURO, ASESOR_COMERCIAL, JEFE_COMERCIAL;
GRANT EXECUTE ON Operaciones.sp_RegistrarPolizaAuto   TO ADMINISTRADOR_SEGURO, ASESOR_COMERCIAL, JEFE_COMERCIAL;
GRANT EXECUTE ON Operaciones.sp_RegistrarPago         TO ADMINISTRADOR_SEGURO, ASESOR_COMERCIAL;
GRANT EXECUTE ON Operaciones.sp_RegistrarSiniestro    TO ADMINISTRADOR_SEGURO;
GO

/* ============================================================================
   7. PERMISOS ADICIONALES DEL ADMINISTRADOR
   ============================================================================ */
GRANT ALTER ANY USER   TO ADMINISTRADOR_SEGURO;
GRANT ALTER ANY ROLE   TO ADMINISTRADOR_SEGURO;
GRANT CREATE PROCEDURE TO ADMINISTRADOR_SEGURO;
GRANT VIEW DEFINITION  TO ADMINISTRADOR_SEGURO;
GO

/* ============================================================================
   8. USUARIOS DE EJEMPLO
      Los logins son objetos del servidor y no se borran al eliminar la base,
      por eso solo se crean si todavía no existen.
   ============================================================================ */

-- Administrador general
IF SUSER_ID(N'admin_seg') IS NULL
    CREATE LOGIN admin_seg WITH PASSWORD = N'AdminSeg#2025',
        DEFAULT_DATABASE = ASEGURADORA06, CHECK_EXPIRATION = OFF;
GO
CREATE USER admin_seg FOR LOGIN admin_seg;
ALTER ROLE ADMINISTRADOR_SEGURO ADD MEMBER admin_seg;
GO

-- Gerente
IF SUSER_ID(N'gerente_seg') IS NULL
    CREATE LOGIN gerente_seg WITH PASSWORD = N'GerenteSeg#2025',
        DEFAULT_DATABASE = ASEGURADORA06, CHECK_EXPIRATION = OFF;
GO
CREATE USER gerente_seg FOR LOGIN gerente_seg;
ALTER ROLE GERENTE ADD MEMBER gerente_seg;
GO

-- Jefe comercial
IF SUSER_ID(N'jefecom_seg') IS NULL
    CREATE LOGIN jefecom_seg WITH PASSWORD = N'JefeComSeg#2025',
        DEFAULT_DATABASE = ASEGURADORA06, CHECK_EXPIRATION = OFF;
GO
CREATE USER jefecom_seg FOR LOGIN jefecom_seg;
ALTER ROLE JEFE_COMERCIAL ADD MEMBER jefecom_seg;
GO

-- Jefe de agencia
IF SUSER_ID(N'jefeag_seg') IS NULL
    CREATE LOGIN jefeag_seg WITH PASSWORD = N'JefeAgSeg#2025',
        DEFAULT_DATABASE = ASEGURADORA06, CHECK_EXPIRATION = OFF;
GO
CREATE USER jefeag_seg FOR LOGIN jefeag_seg;
ALTER ROLE JEFE_AGENCIA ADD MEMBER jefeag_seg;
GO

-- Asesor comercial
IF SUSER_ID(N'asesor_seg') IS NULL
    CREATE LOGIN asesor_seg WITH PASSWORD = N'AsesorSeg#2025',
        DEFAULT_DATABASE = ASEGURADORA06, CHECK_EXPIRATION = OFF;
GO
CREATE USER asesor_seg FOR LOGIN asesor_seg;
ALTER ROLE ASESOR_COMERCIAL ADD MEMBER asesor_seg;
GO

/* ============================================================================
   VERIFICACIÓN: permisos asignados a cada rol
   ============================================================================ */
SELECT
    r.name                                                AS Rol,
    p.permission_name                                     AS Permiso,
    p.state_desc                                          AS Estado,
    ISNULL(OBJECT_SCHEMA_NAME(p.major_id) + '.' + OBJECT_NAME(p.major_id),
           p.class_desc)                                  AS Objeto
FROM sys.database_permissions p
JOIN sys.database_principals r
    ON p.grantee_principal_id = r.principal_id
WHERE r.name IN ('ADMINISTRADOR_SEGURO', 'GERENTE', 'JEFE_COMERCIAL',
                 'JEFE_AGENCIA', 'ASESOR_COMERCIAL')
ORDER BY Rol, Objeto, Permiso;
GO
