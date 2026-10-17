/*
===============================================================================
Script     : ddl_gold.sql
Capa       : Gold (modelo analítico - esquema estrella)
Autor      : José Julián Pérez Bustamante
Asignatura : Ingeniería y Minería de Datos
===============================================================================
Propósito:
    Crear las vistas de la capa 'gold', que representan las tablas de
    dimensiones y de hechos del modelo en estrella (Star Schema):
        - gold.dim_customers : dimensión de clientes (CRM + ERP).
        - gold.dim_products  : dimensión de productos vigentes.
        - gold.fact_sales    : tabla de hechos de ventas.

    Cada vista integra y enriquece los datos de la capa Silver para entregar
    un conjunto de datos limpio y orientado al negocio. Las claves sustitutas
    (surrogate keys) se generan con ROW_NUMBER().

Uso:
    Las vistas pueden consultarse directamente para análisis y reportes.
===============================================================================
*/

-- ============================================================================
-- Dimensión: gold.dim_customers
-- ============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,    -- Clave sustituta
    ci.cst_id                           AS customer_id,
    ci.cst_key                          AS customer_number,
    ci.cst_firstname                    AS first_name,
    ci.cst_lastname                     AS last_name,
    la.cntry                            AS country,
    ci.cst_marital_status               AS marital_status,
    CASE
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- El CRM es la fuente principal del género
        ELSE COALESCE(ca.gen, 'n/a')               -- Se recurre al ERP como fuente complementaria
    END                                 AS gender,
    ca.bdate                            AS birthdate,
    ci.cst_create_date                  AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;
GO

-- ============================================================================
-- Dimensión: gold.dim_products
-- ============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key, -- Clave sustituta
    pn.prd_id       AS product_id,
    pn.prd_key      AS product_number,
    pn.prd_nm       AS product_name,
    pn.cat_id       AS category_id,
    pc.cat          AS category,
    pc.subcat       AS subcategory,
    pc.maintenance  AS maintenance,
    pn.prd_cost     AS cost,
    pn.prd_line     AS product_line,
    pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL; -- Conservar solo la versión vigente de cada producto (excluir histórico)
GO

-- ============================================================================
-- Hechos: gold.fact_sales
-- ============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num  AS order_number,
    pr.product_key  AS product_key,   -- Clave sustituta hacia dim_products
    cu.customer_key AS customer_key,  -- Clave sustituta hacia dim_customers
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;
GO
