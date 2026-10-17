/*
===============================================================================
Script     : ddl_silver.sql
Capa       : Silver (datos depurados y estandarizados)
Autor      : José Julián Pérez Bustamante, Denzel Gael Cruz Prieto, Leonardo de Jesús Esquivel Palacios
Asignatura : Ingeniería y Minería de Datos
===============================================================================
Propósito:
    Definir la estructura (DDL) de las tablas del esquema 'silver'. Antes de
    crear cada tabla se valida su existencia mediante OBJECT_ID y, si existe,
    se elimina para garantizar una definición limpia.

    Diferencias respecto de la capa Bronze:
        - Todas las tablas incorporan la columna técnica de auditoría
          'dwh_create_date', que registra automáticamente la fecha y hora de
          carga del registro en el almacén.
        - 'silver.crm_prd_info' agrega la columna derivada 'cat_id'
          (identificador de categoría extraído de 'prd_key').
        - Las fechas de 'crm_prd_info' y 'crm_sales_details' se almacenan como
          DATE, eliminando el componente horario y el formato entero AAAAMMDD.

Uso:
    Ejecutar este script cada vez que se requiera redefinir la estructura de
    las tablas de la capa Silver.
===============================================================================
*/

-- ============================================================================
-- Sistema fuente: CRM
-- ============================================================================

IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
GO

CREATE TABLE silver.crm_cust_info (
    cst_id             INT,
    cst_key            NVARCHAR(50),
    cst_firstname      NVARCHAR(50),
    cst_lastname       NVARCHAR(50),
    cst_marital_status NVARCHAR(50),
    cst_gndr           NVARCHAR(50),
    cst_create_date    DATE,
    dwh_create_date    DATETIME2 DEFAULT GETDATE()  -- Auditoría: fecha de carga
);
GO

IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
GO

CREATE TABLE silver.crm_prd_info (
    prd_id          INT,
    cat_id          NVARCHAR(50),                   -- Columna derivada de prd_key
    prd_key         NVARCHAR(50),
    prd_nm          NVARCHAR(50),
    prd_cost        INT,
    prd_line        NVARCHAR(50),
    prd_start_dt    DATE,                           -- DATETIME -> DATE
    prd_end_dt      DATE,                           -- DATETIME -> DATE
    dwh_create_date DATETIME2 DEFAULT GETDATE()     -- Auditoría: fecha de carga
);
GO

IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
GO

CREATE TABLE silver.crm_sales_details (
    sls_ord_num     NVARCHAR(50),
    sls_prd_key     NVARCHAR(50),
    sls_cust_id     INT,
    sls_order_dt    DATE,                           -- INT (AAAAMMDD) -> DATE
    sls_ship_dt     DATE,                           -- INT (AAAAMMDD) -> DATE
    sls_due_dt      DATE,                           -- INT (AAAAMMDD) -> DATE
    sls_sales       INT,
    sls_quantity    INT,
    sls_price       INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()     -- Auditoría: fecha de carga
);
GO

-- ============================================================================
-- Sistema fuente: ERP
-- ============================================================================

IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;
GO

CREATE TABLE silver.erp_loc_a101 (
    cid             NVARCHAR(50),
    cntry           NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()     -- Auditoría: fecha de carga
);
GO

IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;
GO

CREATE TABLE silver.erp_cust_az12 (
    cid             NVARCHAR(50),
    bdate           DATE,
    gen             NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()     -- Auditoría: fecha de carga
);
GO

IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;
GO

CREATE TABLE silver.erp_px_cat_g1v2 (
    id              NVARCHAR(50),
    cat             NVARCHAR(50),
    subcat          NVARCHAR(50),
    maintenance     NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()     -- Auditoría: fecha de carga
);
GO
