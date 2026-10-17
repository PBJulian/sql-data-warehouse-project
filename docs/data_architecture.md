# Arquitectura de Datos

**Autores:** José Julián Pérez Bustamante, Denzel Gael Cruz Prieto, Leonardo de Jesús Esquivel Palacios
**Asignatura:** Ingeniería y Minería de Datos

Este documento describe la arquitectura del almacén de datos, el flujo de los
datos entre capas, la integración de los sistemas fuente y el modelo analítico
final.

## Contenido

1. [Arquitectura Medallion](#1-arquitectura-medallion)
2. [Descripción de las capas](#2-descripción-de-las-capas)
3. [Flujo y linaje de los datos](#3-flujo-y-linaje-de-los-datos)
4. [Modelo de integración de las fuentes](#4-modelo-de-integración-de-las-fuentes)
5. [Modelo en estrella (capa Gold)](#5-modelo-en-estrella-capa-gold)
6. [Orden de ejecución del proceso ETL](#6-orden-de-ejecución-del-proceso-etl)

---

## 1. Arquitectura Medallion

El almacén de datos se implementa en **SQL Server** y adopta la arquitectura
**Medallion**, que organiza los datos en tres capas sucesivas de calidad
creciente: **Bronze**, **Silver** y **Gold**. Cada capa corresponde a un
esquema homónimo dentro de la base de datos `DataWarehouse`.

```mermaid
flowchart LR
    subgraph SRC["Sistemas fuente"]
        direction TB
        CRM[("CRM<br/>cust_info.csv<br/>prd_info.csv<br/>sales_details.csv")]
        ERP[("ERP<br/>CUST_AZ12.csv<br/>LOC_A101.csv<br/>PX_CAT_G1V2.csv")]
    end

    subgraph DWH["Data Warehouse · SQL Server"]
        direction LR
        BRZ["BRONZE<br/>Datos crudos<br/>Tablas<br/>TRUNCATE + BULK INSERT<br/>Sin transformaciones"]
        SLV["SILVER<br/>Datos depurados<br/>Tablas<br/>TRUNCATE + INSERT<br/>Limpieza y normalización"]
        GLD["GOLD<br/>Datos para el negocio<br/>Vistas<br/>Integración y reglas de negocio<br/>Modelo en estrella"]
    end

    subgraph USE["Consumo"]
        direction TB
        BI["Reportes y BI"]
        ADH["Consultas SQL ad hoc"]
        ML["Minería de datos y ML"]
    end

    CRM -->|"bronze.load_bronze"| BRZ
    ERP -->|"bronze.load_bronze"| BRZ
    BRZ -->|"silver.load_silver"| SLV
    SLV -->|"ddl_gold.sql"| GLD
    GLD --> BI
    GLD --> ADH
    GLD --> ML

    classDef bronze fill:#CD7F32,stroke:#8B5A2B,color:#FFFFFF
    classDef silver fill:#C0C0C0,stroke:#707070,color:#1A1A1A
    classDef gold fill:#FFD700,stroke:#B8860B,color:#1A1A1A
    class BRZ bronze
    class SLV silver
    class GLD gold
```

## 2. Descripción de las capas

| Criterio               | Bronze                                  | Silver                                                  | Gold                                                   |
|------------------------|-----------------------------------------|---------------------------------------------------------|--------------------------------------------------------|
| **Definición**         | Datos crudos, idénticos a la fuente     | Datos depurados y estandarizados                        | Datos listos para el consumo analítico                 |
| **Objetivo**           | Trazabilidad y depuración de errores    | Preparar datos confiables para el modelado              | Responder preguntas de negocio                         |
| **Tipo de objeto**     | Tablas                                  | Tablas                                                  | Vistas                                                 |
| **Método de carga**    | Completa (`TRUNCATE` + `BULK INSERT`)   | Completa (`TRUNCATE` + `INSERT ... SELECT`)             | Sin carga física (vistas)                              |
| **Transformaciones**   | Ninguna                                 | Limpieza, normalización, derivación de columnas, enriquecimiento | Integración de fuentes, agregación, reglas de negocio |
| **Modelado**           | Ninguno (estructura de origen)          | Ninguno (estructura de origen + columnas técnicas)      | Modelo en estrella (dimensiones y hechos)              |
| **Audiencia**          | Ingenieros de datos                     | Ingenieros y analistas de datos                         | Analistas de negocio, usuarios de BI, científicos de datos |

## 3. Flujo y linaje de los datos

El siguiente diagrama muestra el recorrido de cada conjunto de datos desde el
archivo de origen hasta el objeto analítico que lo consume.

```mermaid
flowchart LR
    subgraph SRC["Fuentes (CSV)"]
        direction TB
        f1["cust_info.csv"]
        f2["prd_info.csv"]
        f3["sales_details.csv"]
        f4["CUST_AZ12.csv"]
        f5["LOC_A101.csv"]
        f6["PX_CAT_G1V2.csv"]
    end

    subgraph BRZ["Capa Bronze"]
        direction TB
        b1["crm_cust_info"]
        b2["crm_prd_info"]
        b3["crm_sales_details"]
        b4["erp_cust_az12"]
        b5["erp_loc_a101"]
        b6["erp_px_cat_g1v2"]
    end

    subgraph SLV["Capa Silver"]
        direction TB
        s1["crm_cust_info"]
        s2["crm_prd_info"]
        s3["crm_sales_details"]
        s4["erp_cust_az12"]
        s5["erp_loc_a101"]
        s6["erp_px_cat_g1v2"]
    end

    subgraph GLD["Capa Gold"]
        direction TB
        g1["dim_customers"]
        g2["dim_products"]
        g3["fact_sales"]
    end

    f1 --> b1 --> s1
    f2 --> b2 --> s2
    f3 --> b3 --> s3
    f4 --> b4 --> s4
    f5 --> b5 --> s5
    f6 --> b6 --> s6

    s1 --> g1
    s4 --> g1
    s5 --> g1
    s2 --> g2
    s6 --> g2
    s3 --> g3
    g1 -.->|"customer_key"| g3
    g2 -.->|"product_key"| g3

    style BRZ fill:#F6E3D1,stroke:#CD7F32
    style SLV fill:#EFEFEF,stroke:#A0A0A0
    style GLD fill:#FFF6CC,stroke:#DAA520
```

## 4. Modelo de integración de las fuentes

Los sistemas CRM y ERP no comparten claves idénticas, por lo que la capa
Silver ajusta los identificadores para que puedan relacionarse.

```mermaid
flowchart LR
    subgraph CRMSYS["Sistema CRM"]
        direction TB
        cust["crm_cust_info<br/>Información de clientes"]
        prd["crm_prd_info<br/>Productos (histórico)"]
        sales["crm_sales_details<br/>Transacciones de venta"]
    end

    subgraph ERPSYS["Sistema ERP"]
        direction TB
        az12["erp_cust_az12<br/>Datos demográficos"]
        loc["erp_loc_a101<br/>País del cliente"]
        pxcat["erp_px_cat_g1v2<br/>Categorías de producto"]
    end

    sales -->|"sls_prd_key = prd_key"| prd
    sales -->|"sls_cust_id = cst_id"| cust
    cust -->|"cst_key = cid"| az12
    cust -->|"cst_key = cid"| loc
    prd -->|"cat_id = id"| pxcat
```

| Relación                                     | Ajuste aplicado en la capa Silver                                                     |
|----------------------------------------------|---------------------------------------------------------------------------------------|
| `crm_sales_details` → `crm_prd_info`         | `prd_key` se recorta a partir del carácter 7: `SUBSTRING(prd_key, 7, LEN(prd_key))`.  |
| `crm_prd_info` → `erp_px_cat_g1v2`           | `cat_id` se deriva de `prd_key`: `REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_')`.       |
| `crm_cust_info` → `erp_cust_az12`            | Se elimina el prefijo `NAS` de `cid` (p. ej., `NASAW00011000` → `AW00011000`).        |
| `crm_cust_info` → `erp_loc_a101`             | Se eliminan los guiones de `cid` (p. ej., `AW-00011000` → `AW00011000`).              |

## 5. Modelo en estrella (capa Gold)

La capa Gold expone un modelo en estrella compuesto por una tabla de hechos
(`fact_sales`) rodeada por dos dimensiones (`dim_customers` y `dim_products`).
Cada cliente y cada producto pueden participar en cero o muchas ventas, y cada
venta referencia exactamente a un cliente y a un producto.

```mermaid
erDiagram
    dim_customers ||--o{ fact_sales : "customer_key"
    dim_products  ||--o{ fact_sales : "product_key"

    dim_customers {
        BIGINT   customer_key PK
        INT      customer_id
        NVARCHAR customer_number
        NVARCHAR first_name
        NVARCHAR last_name
        NVARCHAR country
        NVARCHAR marital_status
        NVARCHAR gender
        DATE     birthdate
        DATE     create_date
    }

    dim_products {
        BIGINT   product_key PK
        INT      product_id
        NVARCHAR product_number
        NVARCHAR product_name
        NVARCHAR category_id
        NVARCHAR category
        NVARCHAR subcategory
        NVARCHAR maintenance
        INT      cost
        NVARCHAR product_line
        DATE     start_date
    }

    fact_sales {
        NVARCHAR order_number
        BIGINT   product_key FK
        BIGINT   customer_key FK
        DATE     order_date
        DATE     shipping_date
        DATE     due_date
        INT      sales_amount
        INT      quantity
        INT      price
    }
```

**Regla de cálculo:** `sales_amount = quantity * price`.

## 6. Orden de ejecución del proceso ETL

| Paso | Script                                   | Acción                                                     |
|------|------------------------------------------|------------------------------------------------------------|
| 1    | `scripts/init_database.sql`              | Crea la base de datos `DataWarehouse` y los tres esquemas. |
| 2    | `scripts/bronze/ddl_bronze.sql`          | Crea las tablas de la capa Bronze.                         |
| 3    | `scripts/bronze/proc_load_bronze.sql`    | Crea el procedimiento `bronze.load_bronze`.                |
| 4    | `EXEC bronze.load_bronze;`               | Carga los CSV en la capa Bronze.                           |
| 5    | `scripts/silver/ddl_silver.sql`          | Crea las tablas de la capa Silver.                         |
| 6    | `scripts/silver/proc_load_silver.sql`    | Crea el procedimiento `silver.load_silver`.                |
| 7    | `EXEC silver.load_silver;`               | Transforma y carga los datos en la capa Silver.            |
| 8    | `scripts/gold/ddl_gold.sql`              | Crea las vistas del modelo en estrella.                    |
| 9    | `tests/quality_checks_silver.sql`        | Valida la calidad de la capa Silver.                       |
| 10   | `tests/quality_checks_gold.sql`          | Valida la integridad del modelo Gold.                      |
