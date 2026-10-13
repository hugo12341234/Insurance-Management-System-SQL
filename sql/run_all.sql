/* ============================================================================
   Proyecto : Sistema de Base de Datos para una Aseguradora (ASEGURADORA06)
   Archivo  : run_all.sql
   Contenido: Ejecuta todos los scripts del proyecto en orden.
   Uso      : En SSMS, activa el modo SQLCMD (menú Query > SQLCMD Mode),
              cambia SqlPath por la ruta completa de la carpeta sql/ y
              ejecuta. También funciona desde la terminal:
                  sqlcmd -S localhost -E -i run_all.sql
   ============================================================================ */

:setvar SqlPath "C:\ruta\al\repositorio\sql"
:on error exit

:r $(SqlPath)\01_schema.sql
:r $(SqlPath)\02_logic.sql
:r $(SqlPath)\03_seed_data.sql
:r $(SqlPath)\04_security.sql
:r $(SqlPath)\05_reports.sql
:r $(SqlPath)\06_tests.sql
