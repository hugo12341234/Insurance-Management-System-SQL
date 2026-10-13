# Insurance Management System — SQL Server Database

![SQL Server](https://img.shields.io/badge/SQL%20Server-2019+-CC2927?logo=microsoftsqlserver&logoColor=white)
![T-SQL](https://img.shields.io/badge/Language-T--SQL-blue)
![Status](https://img.shields.io/badge/Status-Completed-success)

A relational database for a multi-line insurance company, built on **Microsoft SQL Server**. It covers the full business flow — clients, quotes, policies, payments, claims and the sales force — with business rules enforced directly in the database through constraints, triggers, functions and role-based security.

> Team project for the **Databases** course at the **Faculty of Engineering, UNAM** (Mexico City).

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Schema Design](#schema-design)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Requirements](#requirements)
- [Team](#team)

---

## Overview

The database, named `ASEGURADORA06`, centralizes the operations of an insurance provider that sells life, retirement and vehicle insurance. It is organized into separate **schemas** so that personal data, insurance product definitions and day-to-day transactions each live in their own layer.

## Key Features

- **Multi-line insurance** — specialized tables for life, retirement and vehicle policies.
- **Business automation** — triggers that generate folio numbers, update outstanding balances and validate states in real time.
- **Data integrity** — `PRIMARY KEY`, `FOREIGN KEY` and `CHECK` constraints (e.g. `CHK_POLIZA_VIGENCIA_LOGICA` guarantees a policy's end date is after its start date).
- **Role-based security** — roles such as `GERENTE`, `ASESOR`, `ADMINISTRADOR_SEGURO` and `JEFE_COMERCIAL`, with permissions granted through `GRANT`.
- **Reporting** — analytical queries for loss ratios, broker rankings and delinquency rates.

## Schema Design

| Schema | Purpose | Main tables |
|---|---|---|
| `Personas` | People involved in the business | `CLIENTE`, `CORREDOR`, `AJUSTADOR` |
| `Seguros` | Insurance products and coverages | `TIPO_SEGURO`, coverages |
| `Operaciones` | Transactional flow | `COTIZACION`, `POLIZA`, `PAGO`, `SINIESTRO` |

## Project Structure

| File | Description |
|---|---|
| `CREAR.sql` | **DDL** — creates the database, schemas, tables and constraints. |
| `DML.sql` | Programmable logic: functions (e.g. `fn_EdadClienteEnFecha`) and triggers. |
| `CARGA.sql` | Loads sample data, including catalogs and historical records. |
| `SEGURIDAD.sql` | Creates roles and assigns permissions. |
| `INFORMES1.sql` | Reporting queries and key business metrics. |

> The code (table names, comments and data) is written in Spanish, as it was developed for a course at UNAM.

## Getting Started

1. Open **SQL Server Management Studio** (or Azure Data Studio) and connect to your SQL Server instance.
2. Run the scripts **in this order** to avoid dependency errors:

   ```text
   1. CREAR.sql
   2. DML.sql
   3. CARGA.sql
   4. SEGURIDAD.sql
   5. INFORMES1.sql
   ```

3. Explore the data and run the reports in `INFORMES1.sql`.

## Requirements

- **Database engine:** Microsoft SQL Server 2019 or later
- **Client:** SQL Server Management Studio (SSMS) or Azure Data Studio

## Team

Developed as a team project at the Faculty of Engineering, UNAM.

- **Hugo Emmanuel Chacón Jaral** — [@hugo12341234](https://github.com/hugo12341234)
- **Fernando Aranda Marrón** — [@fdoaranda](https://github.com/fdoaranda)

Original repository: [fdoaranda/Insurance-Management-System-SQL](https://github.com/fdoaranda/Insurance-Management-System-SQL)
