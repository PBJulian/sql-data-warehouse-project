# Catálogo de Datos — Capa Gold

**Autores:** José Julián Pérez Bustamante
**Asignatura:** Ingeniería y Minería de Datos

## Descripción general

La capa **Gold** constituye la representación de los datos a nivel de negocio.
Está estructurada como un **modelo en estrella** (*Star Schema*) orientado al
análisis y a la generación de reportes, y se compone de dos **dimensiones** y
una **tabla de hechos**, implementadas como vistas sobre la capa Silver.

| Objeto               | Tipo      | Granularidad                                   |
|----------------------|-----------|------------------------------------------------|
| `gold.dim_customers` | Dimensión | Un registro por cliente                        |
| `gold.dim_products`  | Dimensión | Un registro por producto vigente               |
| `gold.fact_sales`    | Hechos    | Un registro por línea de pedido de venta       |

> **Nota sobre los tipos de datos:** las claves sustitutas se generan con
> `ROW_NUMBER()`, función que en SQL Server devuelve el tipo `BIGINT`.

---

## 1. `gold.dim_customers`

- **Propósito:** almacenar los datos de los clientes enriquecidos con
  información demográfica (ERP) y geográfica (ERP).
- **Fuentes:** `silver.crm_cust_info`, `silver.erp_cust_az12`,
  `silver.erp_loc_a101`.

| Columna           | Tipo de dato   | Origen                                   | Descripción                                                                                         |
|-------------------|----------------|------------------------------------------|-----------------------------------------------------------------------------------------------------|
| `customer_key`    | BIGINT         | Generada (`ROW_NUMBER()`)                | Clave sustituta que identifica de forma única cada registro de la dimensión.                        |
| `customer_id`     | INT            | `crm_cust_info.cst_id`                   | Identificador numérico único asignado al cliente en el CRM.                                         |
| `customer_number` | NVARCHAR(50)   | `crm_cust_info.cst_key`                  | Identificador alfanumérico del cliente, utilizado para el seguimiento y la integración con el ERP.  |
| `first_name`      | NVARCHAR(50)   | `crm_cust_info.cst_firstname`            | Nombre del cliente, sin espacios sobrantes.                                                         |
| `last_name`       | NVARCHAR(50)   | `crm_cust_info.cst_lastname`             | Apellido del cliente, sin espacios sobrantes.                                                       |
| `country`         | NVARCHAR(50)   | `erp_loc_a101.cntry`                     | País de residencia del cliente (p. ej., `Australia`, `Germany`, `United States`).                   |
| `marital_status`  | NVARCHAR(50)   | `crm_cust_info.cst_marital_status`       | Estado civil normalizado: `Married`, `Single` o `n/a`.                                              |
| `gender`          | NVARCHAR(50)   | `crm_cust_info.cst_gndr` / `erp_cust_az12.gen` | Género del cliente: `Male`, `Female` o `n/a`. Prevalece el CRM; el ERP se usa como respaldo. |
| `birthdate`       | DATE           | `erp_cust_az12.bdate`                    | Fecha de nacimiento en formato AAAA-MM-DD (p. ej., `1971-10-06`). Fechas futuras se anulan.         |
| `create_date`     | DATE           | `crm_cust_info.cst_create_date`          | Fecha en que se creó el registro del cliente en el sistema de origen.                               |

---

## 2. `gold.dim_products`

- **Propósito:** proporcionar la información de los productos y sus atributos
  de clasificación. Solo incluye la versión **vigente** de cada producto
  (`prd_end_dt IS NULL`), por lo que excluye el histórico.
- **Fuentes:** `silver.crm_prd_info`, `silver.erp_px_cat_g1v2`.

| Columna          | Tipo de dato   | Origen                          | Descripción                                                                                   |
|------------------|----------------|---------------------------------|-----------------------------------------------------------------------------------------------|
| `product_key`    | BIGINT         | Generada (`ROW_NUMBER()`)       | Clave sustituta que identifica de forma única cada producto en la dimensión.                 |
| `product_id`     | INT            | `crm_prd_info.prd_id`           | Identificador interno único del producto.                                                    |
| `product_number` | NVARCHAR(50)   | `crm_prd_info.prd_key`          | Código alfanumérico estructurado del producto (p. ej., `BK-R93R-62`).                        |
| `product_name`   | NVARCHAR(50)   | `crm_prd_info.prd_nm`           | Nombre descriptivo del producto, que incluye tipo, color y talla.                            |
| `category_id`    | NVARCHAR(50)   | `crm_prd_info.cat_id`           | Identificador de la categoría, derivado de los primeros caracteres de la clave del producto. |
| `category`       | NVARCHAR(50)   | `erp_px_cat_g1v2.cat`           | Clasificación general del producto (p. ej., `Bikes`, `Components`).                          |
| `subcategory`    | NVARCHAR(50)   | `erp_px_cat_g1v2.subcat`        | Clasificación detallada dentro de la categoría (p. ej., `Road Bikes`).                       |
| `maintenance`    | NVARCHAR(50)   | `erp_px_cat_g1v2.maintenance`   | Indica si el producto requiere mantenimiento: `Yes` o `No`.                                  |
| `cost`           | INT            | `crm_prd_info.prd_cost`         | Costo base del producto en unidades monetarias enteras. Los nulos se sustituyen por `0`.     |
| `product_line`   | NVARCHAR(50)   | `crm_prd_info.prd_line`         | Línea de producto: `Mountain`, `Road`, `Touring`, `Other Sales` o `n/a`.                      |
| `start_date`     | DATE           | `crm_prd_info.prd_start_dt`     | Fecha a partir de la cual el producto está disponible para la venta.                         |

---

## 3. `gold.fact_sales`

- **Propósito:** almacenar las transacciones de venta para fines analíticos,
  vinculadas a las dimensiones mediante claves sustitutas.
- **Fuentes:** `silver.crm_sales_details`, `gold.dim_products`,
  `gold.dim_customers`.

| Columna         | Tipo de dato   | Origen                               | Descripción                                                                                   |
|-----------------|----------------|--------------------------------------|-----------------------------------------------------------------------------------------------|
| `order_number`  | NVARCHAR(50)   | `crm_sales_details.sls_ord_num`      | Identificador alfanumérico del pedido de venta (p. ej., `SO54496`).                           |
| `product_key`   | BIGINT         | `dim_products.product_key`           | Clave sustituta que vincula la venta con la dimensión de productos.                           |
| `customer_key`  | BIGINT         | `dim_customers.customer_key`         | Clave sustituta que vincula la venta con la dimensión de clientes.                            |
| `order_date`    | DATE           | `crm_sales_details.sls_order_dt`     | Fecha en que se realizó el pedido.                                                            |
| `shipping_date` | DATE           | `crm_sales_details.sls_ship_dt`      | Fecha en que se envió el pedido al cliente.                                                   |
| `due_date`      | DATE           | `crm_sales_details.sls_due_dt`       | Fecha de vencimiento del pago del pedido.                                                     |
| `sales_amount`  | INT            | `crm_sales_details.sls_sales`        | Valor monetario total de la línea de venta. Cumple la regla `sales_amount = quantity * price`.|
| `quantity`      | INT            | `crm_sales_details.sls_quantity`     | Número de unidades del producto incluidas en la línea de venta.                               |
| `price`         | INT            | `crm_sales_details.sls_price`        | Precio unitario del producto en la línea de venta.                                            |

---

## Reglas de negocio aplicadas

| Regla                                   | Implementación                                                                                     |
|-----------------------------------------|----------------------------------------------------------------------------------------------------|
| Unicidad del cliente                    | Se conserva el registro más reciente por `cst_id` (`ROW_NUMBER() ... ORDER BY cst_create_date DESC`). |
| Prioridad de fuentes para el género     | El CRM prevalece; si su valor es `n/a`, se toma el del ERP (`COALESCE(ca.gen, 'n/a')`).            |
| Vigencia de productos                   | La fecha de fin es el día anterior al siguiente inicio (`LEAD(prd_start_dt) - 1`).                 |
| Consistencia de ventas                  | Si `sls_sales` es nulo, no positivo o inconsistente, se recalcula como `sls_quantity * ABS(sls_price)`. |
| Precio derivado                         | Si `sls_price` es nulo o no positivo, se calcula como `sls_sales / NULLIF(sls_quantity, 0)`.       |
| Fechas de nacimiento futuras            | Se reemplazan por `NULL`.                                                                          |
