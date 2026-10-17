# Data Warehouse en SQL Server con Arquitectura Medallion

**Autor:** José Julián Pérez Bustamante
**Asignatura:** Ingeniería y Minería de Datos

> Proyecto en construcción. Este repositorio replica, paso a paso, el proyecto
> *"SQL Data Warehouse from Scratch"* de
> [DataWithBaraa](https://github.com/DataWithBaraa/sql-data-warehouse-project),
> adaptado y documentado en español.

## Objetivo

Construir un almacén de datos (*Data Warehouse*) moderno en SQL Server que
consolide la información de ventas proveniente de dos sistemas fuente (CRM y
ERP), aplicando procesos ETL organizados en las capas **Bronze**, **Silver** y
**Gold**, con el fin de habilitar el análisis y la generación de reportes.

## Estructura inicial del repositorio

```
sql-data-warehouse-project/
├── datasets/
│   ├── source_crm/     # Archivos CSV del sistema CRM
│   └── source_erp/     # Archivos CSV del sistema ERP
├── docs/               # Documentación técnica del proyecto
├── scripts/
│   ├── bronze/         # Scripts de ingesta de datos crudos
│   ├── silver/         # Scripts de limpieza y estandarización
│   └── gold/           # Scripts del modelo analítico (esquema estrella)
├── tests/              # Consultas de control de calidad
├── LICENSE
└── README.md
```

## Fuentes de datos

| Sistema | Archivo             | Contenido                                   |
|---------|---------------------|---------------------------------------------|
| CRM     | `cust_info.csv`     | Información maestra de clientes             |
| CRM     | `prd_info.csv`      | Catálogo histórico de productos             |
| CRM     | `sales_details.csv` | Transacciones de venta                      |
| ERP     | `CUST_AZ12.csv`     | Datos demográficos de clientes              |
| ERP     | `LOC_A101.csv`      | Ubicación (país) de los clientes            |
| ERP     | `PX_CAT_G1V2.csv`   | Categorías y subcategorías de productos     |

## Licencia

Distribuido bajo la licencia MIT. Consulte el archivo [LICENSE](LICENSE).
