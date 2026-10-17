/*
===============================================================================
Script     : quality_checks_gold.sql
Capa       : Gold (controles de calidad)
Autor      : José Julián Pérez Bustamante, Denzel Gael Cruz Prieto, Leonardo de Jesús Esquivel Palacios
Asignatura : Ingeniería y Minería de Datos
===============================================================================
Propósito:
    Validar la integridad, consistencia y exactitud del modelo en estrella de
    la capa 'gold'. Las verificaciones garantizan:
        - Unicidad de las claves sustitutas en las dimensiones.
        - Integridad referencial entre la tabla de hechos y las dimensiones.
        - Conectividad del modelo de datos para fines analíticos.

Instrucciones de uso:
    - Ejecutar después de crear las vistas Gold (scripts/gold/ddl_gold.sql).
    - Toda consulta que devuelva filas evidencia una anomalía que debe
      investigarse y corregirse.
===============================================================================
*/

-- ============================================================================
-- Verificaciones de 'gold.dim_customers'
-- ============================================================================
-- Unicidad de la clave sustituta customer_key
-- Resultado esperado: sin registros
SELECT
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- Integración del género entre CRM y ERP
-- Resultado esperado: únicamente 'Female', 'Male', 'n/a'
SELECT DISTINCT
    gender
FROM gold.dim_customers;

-- ============================================================================
-- Verificaciones de 'gold.dim_products'
-- ============================================================================
-- Unicidad de la clave sustituta product_key
-- Resultado esperado: sin registros
SELECT
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- ============================================================================
-- Verificaciones de 'gold.fact_sales'
-- ============================================================================
-- Conectividad del modelo: cada hecho debe enlazar con ambas dimensiones
-- Resultado esperado: sin registros
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL;
