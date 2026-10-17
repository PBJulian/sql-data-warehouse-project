/*
===============================================================================
Procedimiento : silver.load_silver
Capa          : Silver (Bronze -> Silver)
Autor         : José Julián Pérez Bustamante
Asignatura    : Ingeniería y Minería de Datos
===============================================================================
Propósito:
    Ejecutar el proceso ETL (Extracción, Transformación y Carga) que puebla
    las tablas del esquema 'silver' a partir de los datos crudos del esquema
    'bronze'. Para cada tabla el procedimiento:
        1. Vacía la tabla destino mediante TRUNCATE TABLE (carga completa).
        2. Inserta los datos depurados, estandarizados y enriquecidos.
        3. Registra la duración de la carga en segundos (DATEDIFF).

    Transformaciones aplicadas:
        - crm_cust_info     : eliminación de espacios, normalización de estado
                              civil y género, y deduplicación conservando el
                              registro más reciente de cada cliente.
        - crm_prd_info      : derivación de 'cat_id' y 'prd_key', reemplazo de
                              costos nulos, normalización de la línea de
                              producto y cálculo de la fecha de fin de vigencia
                              sin solapamientos.
        - crm_sales_details : conversión de fechas enteras a DATE y recálculo
                              de ventas y precios inválidos.
        - erp_cust_az12     : limpieza del prefijo 'NAS', anulación de fechas
                              de nacimiento futuras y normalización del género.
        - erp_loc_a101      : eliminación de guiones en 'cid' y normalización
                              de los nombres de país.
        - erp_px_cat_g1v2   : carga directa (los datos ya son consistentes).

Parámetros:
    Ninguno. El procedimiento no recibe parámetros ni devuelve valores.

Ejemplo de uso:
    EXEC silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Iniciando la carga de la capa Silver';
        PRINT '================================================';

        PRINT '------------------------------------------------';
        PRINT 'Cargando tablas del sistema CRM';
        PRINT '------------------------------------------------';

        -- ====================================================================
        -- 1. Carga de silver.crm_cust_info
        -- ====================================================================
        SET @start_time = GETDATE();
        PRINT '>> Vaciando la tabla: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;
        PRINT '>> Insertando datos en: silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,  -- Eliminar espacios al inicio y al final
            TRIM(cst_lastname)  AS cst_lastname,
            CASE
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'n/a'
            END                 AS cst_marital_status, -- Normalizar el estado civil a un valor descriptivo
            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'n/a'
            END                 AS cst_gndr,           -- Normalizar el género a un valor descriptivo
            cst_create_date
        FROM (
            SELECT
                *,
                ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t
        WHERE flag_last = 1; -- Conservar únicamente el registro más reciente de cada cliente
        SET @end_time = GETDATE();
        PRINT '>> Duración de la carga: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -------------';

        -- ====================================================================
        -- 2. Carga de silver.crm_prd_info
        -- ====================================================================
        SET @start_time = GETDATE();
        PRINT '>> Vaciando la tabla: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;
        PRINT '>> Insertando datos en: silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,       -- Extraer el identificador de categoría
            SUBSTRING(prd_key, 7, LEN(prd_key))         AS prd_key,      -- Extraer la clave del producto
            prd_nm,
            ISNULL(prd_cost, 0)                         AS prd_cost,     -- Sustituir costos nulos por 0
            CASE
                WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
                WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
                WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
                WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
                ELSE 'n/a'
            END                                         AS prd_line,     -- Mapear códigos de línea a valores descriptivos
            CAST(prd_start_dt AS DATE)                  AS prd_start_dt,
            CAST(
                LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1
                AS DATE
            )                                           AS prd_end_dt    -- Fin de vigencia = día anterior al siguiente inicio
        FROM bronze.crm_prd_info;
        SET @end_time = GETDATE();
        PRINT '>> Duración de la carga: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -------------';

        -- ====================================================================
        -- 3. Carga de silver.crm_sales_details
        -- ====================================================================
        SET @start_time = GETDATE();
        PRINT '>> Vaciando la tabla: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;
        PRINT '>> Insertando datos en: silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            -- Convertir fechas enteras AAAAMMDD a DATE; valores 0 o de longitud inválida pasan a NULL
            CASE
                WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END AS sls_order_dt,
            CASE
                WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END AS sls_ship_dt,
            CASE
                WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END AS sls_due_dt,
            CASE
                WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
                    THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,    -- Recalcular la venta si el valor original es nulo, negativo o inconsistente
            sls_quantity,
            CASE
                WHEN sls_price IS NULL OR sls_price <= 0
                    THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price     -- Derivar el precio unitario si el valor original es inválido
        FROM bronze.crm_sales_details;
        SET @end_time = GETDATE();
        PRINT '>> Duración de la carga: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -------------';

        PRINT '------------------------------------------------';
        PRINT 'Cargando tablas del sistema ERP';
        PRINT '------------------------------------------------';

        -- ====================================================================
        -- 4. Carga de silver.erp_cust_az12
        -- ====================================================================
        SET @start_time = GETDATE();
        PRINT '>> Vaciando la tabla: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;
        PRINT '>> Insertando datos en: silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT
            CASE
                WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) -- Eliminar el prefijo 'NAS' si existe
                ELSE cid
            END AS cid,
            CASE
                WHEN bdate > GETDATE() THEN NULL
                ELSE bdate
            END AS bdate, -- Anular fechas de nacimiento posteriores a la fecha actual
            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                ELSE 'n/a'
            END AS gen    -- Normalizar el género y tratar valores desconocidos
        FROM bronze.erp_cust_az12;
        SET @end_time = GETDATE();
        PRINT '>> Duración de la carga: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -------------';

        -- ====================================================================
        -- 5. Carga de silver.erp_loc_a101
        -- ====================================================================
        SET @start_time = GETDATE();
        PRINT '>> Vaciando la tabla: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;
        PRINT '>> Insertando datos en: silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry
        )
        SELECT
            REPLACE(cid, '-', '') AS cid, -- Eliminar guiones para que coincida con cst_key del CRM
            CASE
                WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
                WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                ELSE TRIM(cntry)
            END                   AS cntry -- Normalizar códigos de país y tratar valores vacíos o nulos
        FROM bronze.erp_loc_a101;
        SET @end_time = GETDATE();
        PRINT '>> Duración de la carga: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -------------';

        -- ====================================================================
        -- 6. Carga de silver.erp_px_cat_g1v2
        -- ====================================================================
        SET @start_time = GETDATE();
        PRINT '>> Vaciando la tabla: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        PRINT '>> Insertando datos en: silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT
            id,
            cat,
            subcat,
            maintenance
        FROM bronze.erp_px_cat_g1v2; -- Carga directa: los datos de origen ya son consistentes
        SET @end_time = GETDATE();
        PRINT '>> Duración de la carga: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -------------';

        SET @batch_end_time = GETDATE();
        PRINT '==========================================';
        PRINT 'Carga de la capa Silver finalizada';
        PRINT '   - Duración total de la carga: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' segundos';
        PRINT '==========================================';

    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'SE PRODUJO UN ERROR DURANTE LA CARGA DE LA CAPA SILVER';
        PRINT 'Mensaje de error: ' + ERROR_MESSAGE();
        PRINT 'Número de error: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Estado del error: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
    END CATCH
END
GO
