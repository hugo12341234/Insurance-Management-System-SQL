/* ============================================================================
   Proyecto : Sistema de Base de Datos para una Aseguradora (ASEGURADORA06)
   Archivo  : 01_schema.sql
   Contenido: DDL. Crea la base de datos, los esquemas, las tablas, las llaves
              primarias y foráneas, y las restricciones de validación.
   Autores  : Aranda Marrón Fernando
              Chacón Jaral Hugo Emmanuel
              Gutiérrez Nolasco Emiliano
   Fecha    : 30/11/2025
   Motor    : Microsoft SQL Server 2019 o superior
   Orden    : 1 de 6
   ============================================================================ */

USE master;
GO

/* ----------------------------------------------------------------------------
   Si la base ya existe, se elimina para poder ejecutar el proyecto desde cero.
   ADVERTENCIA: esto borra todos los datos de ASEGURADORA06.
---------------------------------------------------------------------------- */
IF DB_ID(N'ASEGURADORA06') IS NOT NULL
BEGIN
    ALTER DATABASE ASEGURADORA06 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ASEGURADORA06;
END;
GO

CREATE DATABASE ASEGURADORA06;
GO

USE ASEGURADORA06;
GO

/* ============================================================================
   ESQUEMAS
   Personas    : clientes, contactos, direcciones, beneficiarios, corredores
                 y ajustadores.
   Seguros     : tipos de seguro, especializaciones y vehículos.
   Operaciones : cotizaciones, bitácora, pólizas, pagos y siniestros.
   ============================================================================ */
CREATE SCHEMA Personas;
GO
CREATE SCHEMA Seguros;
GO
CREATE SCHEMA Operaciones;
GO

/* ============================================================================
   ESQUEMA PERSONAS
   ============================================================================ */

-- Clientes y su información personal
CREATE TABLE Personas.CLIENTE (
    ID_CLIENTE        INT          NOT NULL PRIMARY KEY,
    RFC               VARCHAR(13)  NULL,
    CURP              VARCHAR(18)  NOT NULL,
    TIPO_CLIENTE      VARCHAR(10)  NOT NULL,
    NOMBRE            VARCHAR(70)  NOT NULL,
    APELLIDO_P        VARCHAR(60)  NOT NULL,
    APELLIDO_M        VARCHAR(60)  NULL,
    FECHA_NACIMIENTO  DATE         NOT NULL,
    ID_CORREDOR       INT          NULL
);

-- Medios de contacto (teléfono o correo) de cada cliente
CREATE TABLE Personas.CONTACTO (
    ID_CONTACTO  INT           NOT NULL PRIMARY KEY,
    TIPO         VARCHAR(10)   NOT NULL,
    VALOR        VARCHAR(150)  NOT NULL,
    ID_CLIENTE   INT           NULL,
    FOREIGN KEY (ID_CLIENTE) REFERENCES Personas.CLIENTE (ID_CLIENTE)
);

-- Domicilio de cada cliente (uno por cliente)
CREATE TABLE Personas.DIRECCION (
    ID_CLIENTE   INT           NOT NULL PRIMARY KEY,
    CALLE        VARCHAR(100)  NOT NULL,
    NUMEXTERIOR  VARCHAR(20)   NOT NULL,
    NUMINTERIOR  VARCHAR(20)   NULL,
    COLONIA      VARCHAR(100)  NOT NULL,
    FOREIGN KEY (ID_CLIENTE) REFERENCES Personas.CLIENTE (ID_CLIENTE)
);

-- Código postal, estado y ciudad del domicilio del cliente
CREATE TABLE Personas.DIRECCIONCP (
    ID_CPDIR    VARCHAR(40)  NOT NULL PRIMARY KEY,
    ESTADO      VARCHAR(40)  NOT NULL,
    CIUDAD      VARCHAR(40)  NOT NULL,
    ID_CLIENTE  INT          NOT NULL,
    FOREIGN KEY (ID_CLIENTE) REFERENCES Personas.CLIENTE (ID_CLIENTE)
);

-- Corredores (fuerza de ventas) y su jerarquía de supervisión
CREATE TABLE Personas.CORREDOR (
    ID_CORREDOR         INT           NOT NULL PRIMARY KEY,
    APELLIDOMAT         VARCHAR(40)   NULL,
    APELLIDOPAT         VARCHAR(40)   NOT NULL,
    CEDULA_PROF         VARCHAR(30)   NOT NULL,
    NUM_EMPLEADO        VARCHAR(30)   NOT NULL,
    TIPO_EMPLEADO       VARCHAR(30)   NOT NULL,
    FECHA_CONTRATACION  DATE          NOT NULL,
    NOMBRE              VARCHAR(40)   NOT NULL,
    PORC_COMISION       DECIMAL(5,2)  NOT NULL,
    ID_SUPERVISOR       INT           NULL
);

-- Rangos de código postal que atiende cada corredor
CREATE TABLE Personas.CP_CORREDOR (
    ID_CPCORREDOR  VARCHAR(10)  NOT NULL PRIMARY KEY,
    CP_FINAL       VARCHAR(40)  NOT NULL,
    CP_INICIAL     VARCHAR(40)  NOT NULL,
    ID_CORREDOR    INT          NOT NULL,
    FOREIGN KEY (ID_CORREDOR) REFERENCES Personas.CORREDOR (ID_CORREDOR)
);

/* ============================================================================
   ESQUEMA OPERACIONES: COTIZACIONES
   ============================================================================ */

-- Cotizaciones solicitadas por los clientes
CREATE TABLE Operaciones.COTIZACION (
    NUM_COTIZACION   INT            NOT NULL PRIMARY KEY,
    ID_CLIENTE       INT            NOT NULL,
    FECHA_COTIZ      DATE           NOT NULL,
    MONTO_EST_PRIMA  DECIMAL(14,2)  NOT NULL,
    ESTADO           VARCHAR(40)    NOT NULL,
    RECORDATORIO     VARCHAR(400)   NULL,
    VIGENCIA_DIAS    VARCHAR(40)    NOT NULL,
    FOREIGN KEY (ID_CLIENTE) REFERENCES Personas.CLIENTE (ID_CLIENTE)
);

-- Historial de cambios de estado de cada cotización
CREATE TABLE Operaciones.BITACORA_COTIZACIONES (
    ID_BITACORA     INT            NOT NULL PRIMARY KEY,
    NUM_COTIZACION  INT            NOT NULL,
    FECHA_CAMBIO    DATE           NOT NULL,
    NUEVO_ESTADO    VARCHAR(20)    NOT NULL,
    OBSERVACIONES   VARCHAR(2000)  NULL,
    FOREIGN KEY (NUM_COTIZACION) REFERENCES Operaciones.COTIZACION (NUM_COTIZACION)
);

/* ============================================================================
   ESQUEMA SEGUROS
   ============================================================================ */

-- Catálogo de tipos de seguro (100 = Vida, 200 = Retiro, 300 = Auto)
CREATE TABLE Seguros.TIPO_SEGURO (
    CLAVE_SEGURO      VARCHAR(30)    NOT NULL PRIMARY KEY,
    NOMBRE            VARCHAR(100)   NOT NULL,
    DESCRIPCION       VARCHAR(4000)  NULL,
    VIGENCIA_MIN_MES  INT            NOT NULL,
    MONTO_MINIMO      DECIMAL(14,2)  NOT NULL,
    NUM_COTIZACION    INT            NOT NULL,
    FOREIGN KEY (NUM_COTIZACION) REFERENCES Operaciones.COTIZACION (NUM_COTIZACION)
);

-- Especialización: seguro de vida
CREATE TABLE Seguros.SEGURO_VIDA (
    CLAVE_SEGURO      VARCHAR(30)  NOT NULL PRIMARY KEY,
    CLAVE             VARCHAR(40)  NOT NULL,
    EDAD_MAXIM_CONTR  INT          NOT NULL,
    FOREIGN KEY (CLAVE_SEGURO) REFERENCES Seguros.TIPO_SEGURO (CLAVE_SEGURO)
);

-- Especialización: seguro de retiro
CREATE TABLE Seguros.SEGURO_RETIRO (
    CLAVE_SEGURO            VARCHAR(30)    NOT NULL PRIMARY KEY,
    EDAD_RETIRO             INT            NOT NULL,
    APORTACION_MIN_MENSUAL  DECIMAL(14,2)  NOT NULL,
    FOREIGN KEY (CLAVE_SEGURO) REFERENCES Seguros.TIPO_SEGURO (CLAVE_SEGURO)
);

-- Especialización: seguro de auto
CREATE TABLE Seguros.SEGURO_AUTO (
    CLAVE_SEGURO      VARCHAR(30)    NOT NULL PRIMARY KEY,
    COBERTURA_BASICA  VARCHAR(4000)  NOT NULL,
    FOREIGN KEY (CLAVE_SEGURO) REFERENCES Seguros.TIPO_SEGURO (CLAVE_SEGURO)
);

-- Vehículos asegurados
CREATE TABLE Seguros.VEHICULO (
    ID_VEHICULO      INT            NOT NULL PRIMARY KEY,
    PLACAS           VARCHAR(20)    NOT NULL,
    NUM_SERIE        VARCHAR(50)    NOT NULL,
    MARCA            VARCHAR(60)    NOT NULL,
    MODELO           VARCHAR(60)    NOT NULL,
    ANIO             INT            NOT NULL,
    VALOR_COMERCIAL  DECIMAL(14,2)  NOT NULL,
    CLAVE_SEGURO     VARCHAR(30)    NOT NULL,
    FOREIGN KEY (CLAVE_SEGURO) REFERENCES Seguros.TIPO_SEGURO (CLAVE_SEGURO)
);

-- Beneficiarios de los seguros de cada cliente
CREATE TABLE Personas.BENEFICIARIO (
    ID_BENEFICIARIO  INT           NOT NULL PRIMARY KEY,
    APELLIDO_M       VARCHAR(40)   NULL,
    APELLIDO_P       VARCHAR(40)   NOT NULL,
    NOMBRE           VARCHAR(200)  NOT NULL,
    PARENTESCO       VARCHAR(20)   NOT NULL,
    PORCENTAJE       INT           NOT NULL,
    CLAVE_SEGURO     VARCHAR(30)   NOT NULL,
    ID_CLIENTE       INT           NOT NULL,
    FOREIGN KEY (CLAVE_SEGURO) REFERENCES Seguros.TIPO_SEGURO (CLAVE_SEGURO),
    FOREIGN KEY (ID_CLIENTE)   REFERENCES Personas.CLIENTE (ID_CLIENTE)
);

/* ============================================================================
   ESQUEMA OPERACIONES: PÓLIZAS, PAGOS Y SINIESTROS
   ============================================================================ */

-- Pólizas contratadas
CREATE TABLE Operaciones.POLIZA (
    NUM_POLIZA       INT            NOT NULL PRIMARY KEY,
    ID_CLIENTE       INT            NOT NULL,
    ID_CORREDOR      INT            NOT NULL,
    CLAVE_SEGURO     VARCHAR(30)    NOT NULL,
    FECHA_INICIO     DATE           NOT NULL,
    FECHA_FIN        DATE           NOT NULL,
    SALDO_PENDIENTE  DECIMAL(14,2)  NULL,
    MONTO_PRIMA_TOT  DECIMAL(14,2)  NOT NULL,
    ESTADO_POLIZA    VARCHAR(20)    NOT NULL,
    FOREIGN KEY (ID_CLIENTE)   REFERENCES Personas.CLIENTE (ID_CLIENTE),
    FOREIGN KEY (ID_CORREDOR)  REFERENCES Personas.CORREDOR (ID_CORREDOR),
    FOREIGN KEY (CLAVE_SEGURO) REFERENCES Seguros.TIPO_SEGURO (CLAVE_SEGURO)
);

-- Pagos de las pólizas
CREATE TABLE Operaciones.PAGO (
    ID_PAGO       INT            NOT NULL PRIMARY KEY,
    NUM_POLIZA    INT            NOT NULL,
    STSPAGO       VARCHAR(40)    NOT NULL,
    NUM_PAGO      INT            NOT NULL,
    FECHA_PAGO    DATE           NOT NULL,
    MONTO_PAGADO  DECIMAL(14,2)  NOT NULL,
    METODO_PAGO   VARCHAR(50)    NOT NULL,
    FOREIGN KEY (NUM_POLIZA) REFERENCES Operaciones.POLIZA (NUM_POLIZA)
);

-- Siniestros reportados sobre una póliza
CREATE TABLE Operaciones.SINIESTRO (
    NUM_SINIESTRO   INT            NOT NULL PRIMARY KEY,
    NUM_POLIZA      INT            NOT NULL,
    FECHA_HORA      DATETIME       NOT NULL,
    LUGAR           VARCHAR(400)   NOT NULL,
    CAUSA           VARCHAR(400)   NOT NULL,
    MONTO_INDEMNIZ  DECIMAL(14,2)  NOT NULL,
    FECHA_REGISTRO  DATE           NOT NULL,
    FOREIGN KEY (NUM_POLIZA) REFERENCES Operaciones.POLIZA (NUM_POLIZA)
);

-- Ajustadores asignados a los siniestros
CREATE TABLE Personas.AJUSTADOR (
    ID_AJUSTADOR   INT           NOT NULL PRIMARY KEY,
    NOMBRE         VARCHAR(200)  NOT NULL,
    APELLIDO_M     VARCHAR(150)  NULL,
    APELLIDO_P     VARCHAR(150)  NOT NULL,
    NUM_SINIESTRO  INT           NULL,
    FOREIGN KEY (NUM_SINIESTRO) REFERENCES Operaciones.SINIESTRO (NUM_SINIESTRO)
);
GO

/* ============================================================================
   RESTRICCIONES ADICIONALES
   ============================================================================ */

-- Llaves foráneas que se agregan después porque las tablas se referencian
-- entre sí (cliente -> corredor, corredor -> supervisor).
ALTER TABLE Personas.CLIENTE ADD CONSTRAINT FK_CLIENTE_CORREDOR
    FOREIGN KEY (ID_CORREDOR) REFERENCES Personas.CORREDOR (ID_CORREDOR);

ALTER TABLE Personas.CORREDOR ADD CONSTRAINT FK_CORREDOR_SUPERVISOR
    FOREIGN KEY (ID_SUPERVISOR) REFERENCES Personas.CORREDOR (ID_CORREDOR);

-- Valores únicos
ALTER TABLE Personas.CORREDOR ADD CONSTRAINT UQ_CORREDOR_CEDULA_PROF
    UNIQUE (CEDULA_PROF);

-- Dominios de valores permitidos
ALTER TABLE Personas.CLIENTE ADD CONSTRAINT CHK_CLIENTE_TIPO_CLIENTE
    CHECK (TIPO_CLIENTE IN ('NATURAL', 'MORAL'));

ALTER TABLE Personas.CONTACTO ADD CONSTRAINT CHK_CONTACTO_TIPO
    CHECK (TIPO IN ('TELEFONO', 'CORREO'));

ALTER TABLE Personas.BENEFICIARIO ADD CONSTRAINT CHK_BENEF_PARENTESCO_LINEA_DIRECTA
    CHECK (PARENTESCO IN ('P', 'M', 'HO', 'HA', 'CO'));  -- Padre, Madre, Hijo, Hija, Cónyuge

ALTER TABLE Seguros.TIPO_SEGURO ADD CONSTRAINT CHK_TIPO_SEGURO_CLAVE
    CHECK (CLAVE_SEGURO IN ('100', '200', '300'));

ALTER TABLE Seguros.SEGURO_VIDA ADD CONSTRAINT CHK_SEGVIDA_CLAVE
    CHECK (CLAVE_SEGURO = '100');

ALTER TABLE Seguros.SEGURO_RETIRO ADD CONSTRAINT CHK_SEGRETIRO_CLAVE
    CHECK (CLAVE_SEGURO = '200');

ALTER TABLE Seguros.SEGURO_AUTO ADD CONSTRAINT CHK_SEGAUTO_CLAVE
    CHECK (CLAVE_SEGURO = '300');

ALTER TABLE Operaciones.POLIZA ADD CONSTRAINT CHK_POLIZA_ESTADO
    CHECK (ESTADO_POLIZA IN ('ACTIVA', 'INACTIVA'));

ALTER TABLE Operaciones.PAGO ADD CONSTRAINT CHK_PAGO_STATUS
    CHECK (STSPAGO IN ('PAGADO', 'PENDIENTE'));

-- Reglas de negocio
ALTER TABLE Operaciones.POLIZA ADD CONSTRAINT CHK_POLIZA_PRIMA_POSITIVA
    CHECK (MONTO_PRIMA_TOT > 0);

ALTER TABLE Operaciones.POLIZA ADD CONSTRAINT CHK_POLIZA_VIGENCIA_LOGICA
    CHECK (FECHA_FIN > FECHA_INICIO);

ALTER TABLE Personas.CLIENTE ADD CONSTRAINT CHK_CLIENTE_EDAD_MAX
    CHECK (FECHA_NACIMIENTO >= DATEADD(YEAR, -80, GETDATE()));
GO
