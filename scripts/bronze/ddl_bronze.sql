/*
===============================================================================
Script     : ddl_bronze.sql
Capa       : Bronze (ingesta de datos crudos)
Autor      : José Julián Pérez Bustamante, Denzel Gael Cruz Prieto, Leonardo de Jesús Esquivel Palacios
Asignatura : Ingeniería y Minería de Datos
===============================================================================
Propósito:
    Definir la estructura (DDL) de las tablas del esquema 'bronze'. Antes de
    crear cada tabla se valida su existencia mediante OBJECT_ID y, si existe,
    se elimina para garantizar una definición limpia.

    Las tablas de esta capa reproducen fielmente la estructura de los archivos
    CSV de origen (CRM y ERP), sin aplicar transformaciones de negocio.

Uso:
    Ejecutar este script cada vez que se requiera redefinir la estructura de
    las tablas de la capa Bronze.
===============================================================================
*/

-- ============================================================================
-- Sistema fuente: CRM
-- ============================================================================

-- Información maestra de clientes
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
GO

CREATE TABLE bronze.crm_cust_info (
    cst_id              INT,
    cst_key             NVARCHAR(50),
    cst_firstname       NVARCHAR(50),
    cst_lastname        NVARCHAR(50),
    cst_marital_status  NVARCHAR(50),
    cst_gndr            NVARCHAR(50),
    cst_create_date     DATE
);
GO

-- Catálogo histórico de productos
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
GO

CREATE TABLE bronze.crm_prd_info (
    prd_id       INT,
    prd_key      NVARCHAR(50),
    prd_nm       NVARCHAR(50),
    prd_cost     INT,
    prd_line     NVARCHAR(50),
    prd_start_dt DATETIME,
    prd_end_dt   DATETIME
);
GO

-- Detalle de transacciones de venta (las fechas llegan como enteros AAAAMMDD)
IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num  NVARCHAR(50),
    sls_prd_key  NVARCHAR(50),
    sls_cust_id  INT,
    sls_order_dt INT,
    sls_ship_dt  INT,
    sls_due_dt   INT,
    sls_sales    INT,
    sls_quantity INT,
    sls_price    INT
);
GO

-- ============================================================================
-- Sistema fuente: ERP
-- ============================================================================

-- Ubicación (país) de los clientes
IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
GO

CREATE TABLE bronze.erp_loc_a101 (
    cid    NVARCHAR(50),
    cntry  NVARCHAR(50)
);
GO

-- Datos demográficos de clientes (fecha de nacimiento y género)
IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
GO

CREATE TABLE bronze.erp_cust_az12 (
    cid    NVARCHAR(50),
    bdate  DATE,
    gen    NVARCHAR(50)
);
GO

-- Categorías y subcategorías de productos
IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
GO

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id           NVARCHAR(50),
    cat          NVARCHAR(50),
    subcat       NVARCHAR(50),
    maintenance  NVARCHAR(50)
);
GO
