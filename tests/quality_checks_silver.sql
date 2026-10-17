/*
===============================================================================
Script     : quality_checks_silver.sql
Capa       : Silver (controles de calidad)
Autor      : José Julián Pérez Bustamante, Denzel Gael Cruz Prieto, Leonardo de Jesús Esquivel Palacios
Asignatura : Ingeniería y Minería de Datos
===============================================================================
Propósito:
    Validar la consistencia, exactitud y estandarización de los datos de la
    capa 'silver'. Las verificaciones incluyen:
        - Claves primarias nulas o duplicadas.
        - Espacios no deseados en campos de texto.
        - Estandarización y consistencia de valores categóricos.
        - Rangos y secuencias de fechas inválidos.
        - Consistencia entre campos relacionados (ventas = cantidad * precio).

Instrucciones de uso:
    - Ejecutar estas consultas después de cargar la capa Silver
      (EXEC silver.load_silver;).
    - Toda consulta marcada con "Resultado esperado: sin registros" que
      devuelva filas evidencia una anomalía que debe investigarse y corregirse.
===============================================================================
*/

-- ============================================================================
-- Verificaciones de 'silver.crm_cust_info'
-- ============================================================================
-- Claves primarias nulas o duplicadas
-- Resultado esperado: sin registros
SELECT
    cst_id,
    COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Espacios no deseados
-- Resultado esperado: sin registros
SELECT
    cst_key
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key);

SELECT
    cst_firstname,
    cst_lastname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
   OR cst_lastname  != TRIM(cst_lastname);

-- Estandarización y consistencia de valores
-- Resultado esperado: 'Single', 'Married', 'n/a' / 'Female', 'Male', 'n/a'
SELECT DISTINCT
    cst_marital_status
FROM silver.crm_cust_info;

SELECT DISTINCT
    cst_gndr
FROM silver.crm_cust_info;

-- ============================================================================
-- Verificaciones de 'silver.crm_prd_info'
-- ============================================================================
-- Claves primarias nulas o duplicadas
-- Resultado esperado: sin registros
SELECT
    prd_id,
    COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Espacios no deseados
-- Resultado esperado: sin registros
SELECT
    prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Costos nulos o negativos
-- Resultado esperado: sin registros
SELECT
    prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Estandarización y consistencia de valores
-- Resultado esperado: 'Mountain', 'Road', 'Other Sales', 'Touring', 'n/a'
SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info;

-- Secuencia de fechas inválida (fecha de fin anterior a la de inicio)
-- Resultado esperado: sin registros
SELECT
    *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- ============================================================================
-- Verificaciones de 'silver.crm_sales_details'
-- ============================================================================
-- Fechas inválidas
-- Nota: esta consulta se ejecuta sobre la capa Bronze, ya que en Silver las
-- columnas ya se almacenan como DATE.
-- Resultado esperado: identificar los valores que la capa Silver anula
SELECT
    NULLIF(sls_due_dt, 0) AS sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0
    OR LEN(sls_due_dt) != 8
    OR sls_due_dt > 20500101
    OR sls_due_dt < 19000101;

-- Secuencia de fechas inválida (pedido posterior al envío o al vencimiento)
-- Resultado esperado: sin registros
SELECT
    *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;

-- Consistencia de datos: ventas = cantidad * precio
-- Resultado esperado: sin registros
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- ============================================================================
-- Verificaciones de 'silver.erp_cust_az12'
-- ============================================================================
-- Fechas de nacimiento fuera de rango
-- Resultado esperado: fechas entre 1924-01-01 y la fecha actual
SELECT DISTINCT
    bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01'
   OR bdate > GETDATE();

-- Estandarización y consistencia de valores
-- Resultado esperado: 'Female', 'Male', 'n/a'
SELECT DISTINCT
    gen
FROM silver.erp_cust_az12;

-- ============================================================================
-- Verificaciones de 'silver.erp_loc_a101'
-- ============================================================================
-- Estandarización y consistencia de valores
-- Resultado esperado: nombres de país completos, sin códigos ni vacíos
SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101
ORDER BY cntry;

-- ============================================================================
-- Verificaciones de 'silver.erp_px_cat_g1v2'
-- ============================================================================
-- Espacios no deseados
-- Resultado esperado: sin registros
SELECT
    *
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat)
   OR subcat != TRIM(subcat)
   OR maintenance != TRIM(maintenance);

-- Estandarización y consistencia de valores
-- Resultado esperado: 'Yes', 'No'
SELECT DISTINCT
    maintenance
FROM silver.erp_px_cat_g1v2;
