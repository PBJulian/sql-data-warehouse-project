/*
===============================================================================
Procedimiento : bronze.load_bronze
Capa          : Bronze (Fuente -> Bronze)
Autor         : José Julián Pérez Bustamante
Asignatura    : Ingeniería y Minería de Datos
===============================================================================
Propósito:
    Cargar en el esquema 'bronze' los datos crudos contenidos en los archivos
    CSV de los sistemas fuente CRM y ERP. Para cada tabla el procedimiento:
        1. Vacía la tabla destino mediante TRUNCATE TABLE (carga completa).
        2. Inserta el contenido del CSV mediante BULK INSERT.
        3. Registra la duración de la carga en segundos (DATEDIFF).
    Al finalizar informa la duración total del lote. Cualquier error se
    captura en el bloque TRY...CATCH y se reporta con su mensaje, número y
    estado.

Parámetros:
    Ninguno. El procedimiento no recibe parámetros ni devuelve valores.

Ejemplo de uso:
    EXEC bronze.load_bronze;

Nota sobre las rutas:
    Las instrucciones BULK INSERT apuntan a 'C:\sql\dwh_project\datasets\'.
    Ajuste estas rutas a la carpeta donde se encuentren los archivos CSV en el
    servidor. En SQL Server sobre Linux (por ejemplo, en Docker) la ruta
    'C:\sql\dwh_project\datasets\' se traduce a '/sql/dwh_project/datasets/'
    y los nombres de archivo distinguen mayúsculas de minúsculas.
===============================================================================
*/
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Iniciando la carga de la capa Bronze';
        PRINT '================================================';

        PRINT '------------------------------------------------';
        PRINT 'Cargando tablas del sistema CRM';
        PRINT '------------------------------------------------';

        -- Carga de bronze.crm_cust_info
        SET @start_time = GETDATE();
        PRINT '>> Vaciando la tabla: bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;
        PRINT '>> Insertando datos en: bronze.crm_cust_info';
        BULK INSERT bronze.crm_cust_info
        FROM 'C:\sql\dwh_project\datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,           -- Omitir la fila de encabezados
            FIELDTERMINATOR = ',',  -- Separador de campos del CSV
            TABLOCK                 -- Bloqueo de tabla para acelerar la carga masiva
        );
        SET @end_time = GETDATE();
        PRINT '>> Duración de la carga: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -------------';

        -- Carga de bronze.crm_prd_info
        SET @start_time = GETDATE();
        PRINT '>> Vaciando la tabla: bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;
        PRINT '>> Insertando datos en: bronze.crm_prd_info';
        BULK INSERT bronze.crm_prd_info
        FROM 'C:\sql\dwh_project\datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Duración de la carga: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -------------';

        -- Carga de bronze.crm_sales_details
        SET @start_time = GETDATE();
        PRINT '>> Vaciando la tabla: bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details;
        PRINT '>> Insertando datos en: bronze.crm_sales_details';
        BULK INSERT bronze.crm_sales_details
        FROM 'C:\sql\dwh_project\datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Duración de la carga: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -------------';

        PRINT '------------------------------------------------';
        PRINT 'Cargando tablas del sistema ERP';
        PRINT '------------------------------------------------';

        -- Carga de bronze.erp_loc_a101
        SET @start_time = GETDATE();
        PRINT '>> Vaciando la tabla: bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;
        PRINT '>> Insertando datos en: bronze.erp_loc_a101';
        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\sql\dwh_project\datasets\source_erp\LOC_A101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Duración de la carga: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -------------';

        -- Carga de bronze.erp_cust_az12
        SET @start_time = GETDATE();
        PRINT '>> Vaciando la tabla: bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;
        PRINT '>> Insertando datos en: bronze.erp_cust_az12';
        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\sql\dwh_project\datasets\source_erp\CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Duración de la carga: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -------------';

        -- Carga de bronze.erp_px_cat_g1v2
        SET @start_time = GETDATE();
        PRINT '>> Vaciando la tabla: bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;
        PRINT '>> Insertando datos en: bronze.erp_px_cat_g1v2';
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\sql\dwh_project\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Duración de la carga: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -------------';

        SET @batch_end_time = GETDATE();
        PRINT '==========================================';
        PRINT 'Carga de la capa Bronze finalizada';
        PRINT '   - Duración total de la carga: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' segundos';
        PRINT '==========================================';
    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'SE PRODUJO UN ERROR DURANTE LA CARGA DE LA CAPA BRONZE';
        PRINT 'Mensaje de error: ' + ERROR_MESSAGE();
        PRINT 'Número de error: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Estado del error: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
    END CATCH
END
GO
