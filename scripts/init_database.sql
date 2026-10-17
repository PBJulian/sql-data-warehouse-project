/*
===============================================================================
Script     : init_database.sql
Proyecto   : Data Warehouse en SQL Server con Arquitectura Medallion
Autor      : José Julián Pérez Bustamante
Asignatura : Ingeniería y Minería de Datos
===============================================================================
Propósito:
    Crear la base de datos 'DataWarehouse' desde cero. El script verifica si la
    base de datos ya existe; en caso afirmativo, la elimina y la vuelve a crear.
    Posteriormente define los tres esquemas que componen la arquitectura
    Medallion del almacén de datos:
        - bronze : datos crudos, tal como llegan desde los sistemas fuente.
        - silver : datos depurados, estandarizados y normalizados.
        - gold   : datos modelados para el consumo analítico (esquema estrella).

ADVERTENCIA:
    La ejecución de este script elimina por completo la base de datos
    'DataWarehouse' si ya existe. Toda la información almacenada se perderá de
    forma permanente. Verifique que cuenta con respaldos antes de ejecutarlo.
===============================================================================
*/

USE master;
GO

-- Eliminar y volver a crear la base de datos 'DataWarehouse'.
-- Se fuerza el modo SINGLE_USER para cerrar conexiones abiertas y revertir
-- transacciones pendientes antes de la eliminación.
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Crear la base de datos 'DataWarehouse'
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Crear los esquemas de la arquitectura Medallion
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
