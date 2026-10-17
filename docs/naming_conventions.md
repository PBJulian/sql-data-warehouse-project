# Convenciones de Nombres

**Autores:** José Julián Pérez Bustamante, Denzel Gael Cruz Prieto, Leonardo de Jesús Esquivel Palacios
**Asignatura:** Ingeniería y Minería de Datos

Este documento establece las convenciones de nomenclatura aplicadas a los
esquemas, tablas, vistas, columnas, procedimientos almacenados y archivos del
almacén de datos.

## Contenido

1. [Principios generales](#principios-generales)
2. [Convenciones para tablas](#convenciones-para-tablas)
   - [Capa Bronze](#capa-bronze)
   - [Capa Silver](#capa-silver)
   - [Capa Gold](#capa-gold)
3. [Convenciones para columnas](#convenciones-para-columnas)
   - [Claves sustitutas](#claves-sustitutas)
   - [Columnas técnicas](#columnas-técnicas)
4. [Procedimientos almacenados](#procedimientos-almacenados)
5. [Archivos del repositorio](#archivos-del-repositorio)
6. [Mensajes de commit](#mensajes-de-commit)

---

## Principios generales

- **Formato:** se utiliza *snake_case*, es decir, letras minúsculas y guiones
  bajos (`_`) para separar palabras.
- **Idioma:** los nombres de los objetos de base de datos se escriben en
  **inglés**, para mantener la coherencia con los sistemas fuente. La
  documentación y los comentarios se redactan en español.
- **Palabras reservadas:** no se emplean palabras reservadas de SQL como
  nombres de objetos.

## Convenciones para tablas

### Capa Bronze

- Todos los nombres comienzan con el nombre del sistema fuente, y el nombre
  de la entidad coincide con el original, sin renombrarlo.
- **Patrón:** **`<sistema_fuente>_<entidad>`**
  - `<sistema_fuente>`: nombre del sistema de origen (`crm`, `erp`).
  - `<entidad>`: nombre exacto de la tabla en el sistema de origen.
  - Ejemplo: `crm_cust_info` → información de clientes del sistema CRM.

### Capa Silver

- Se aplica la misma regla que en Bronze: el nombre conserva el sistema fuente
  y la entidad original, lo que preserva la trazabilidad entre capas.
- **Patrón:** **`<sistema_fuente>_<entidad>`**
  - Ejemplo: `erp_loc_a101` → ubicación de clientes del sistema ERP.

### Capa Gold

- Los nombres son significativos y están alineados con el negocio, precedidos
  por un prefijo que indica la categoría del objeto.
- **Patrón:** **`<categoría>_<entidad>`**
  - `<categoría>`: rol del objeto, como `dim` (dimensión) o `fact` (hechos).
  - `<entidad>`: nombre descriptivo del dominio de negocio (`customers`,
    `products`, `sales`).
  - Ejemplos:
    - `dim_customers` → dimensión con los datos de clientes.
    - `fact_sales` → tabla de hechos con las transacciones de venta.

#### Glosario de prefijos

| Prefijo   | Significado          | Ejemplos                                     |
|-----------|----------------------|----------------------------------------------|
| `dim_`    | Tabla de dimensión   | `dim_customers`, `dim_products`              |
| `fact_`   | Tabla de hechos      | `fact_sales`                                 |
| `report_` | Tabla de reporte     | `report_customers`, `report_sales_monthly`   |

## Convenciones para columnas

### Claves sustitutas

- Todas las claves primarias de las dimensiones utilizan el sufijo `_key`.
- **Patrón:** **`<entidad>_key`**
  - `<entidad>`: nombre de la entidad a la que pertenece la clave.
  - `_key`: sufijo que identifica la columna como clave sustituta.
  - Ejemplo: `customer_key` → clave sustituta de `dim_customers`.

### Columnas técnicas

- Las columnas de metadatos generadas por el sistema comienzan con el prefijo
  `dwh_`, seguido de un nombre que describe su propósito.
- **Patrón:** **`dwh_<nombre_columna>`**
  - `dwh`: prefijo reservado para metadatos del almacén de datos.
  - Ejemplo: `dwh_create_date` → fecha y hora en que el registro se cargó en
    el almacén.

## Procedimientos almacenados

- Los procedimientos de carga siguen el patrón **`load_<capa>`** y se crean
  dentro del esquema de la capa que alimentan.
  - `<capa>`: capa que se carga (`bronze`, `silver`, `gold`).
  - Ejemplos:
    - `bronze.load_bronze` → carga de la capa Bronze desde los CSV.
    - `silver.load_silver` → carga de la capa Silver desde Bronze.

## Archivos del repositorio

| Patrón                        | Contenido                                        | Ejemplo                              |
|-------------------------------|--------------------------------------------------|--------------------------------------|
| `ddl_<capa>.sql`              | Definición de tablas o vistas de una capa        | `scripts/silver/ddl_silver.sql`      |
| `proc_load_<capa>.sql`        | Procedimiento almacenado de carga de una capa    | `scripts/bronze/proc_load_bronze.sql`|
| `quality_checks_<capa>.sql`   | Consultas de control de calidad de una capa      | `tests/quality_checks_gold.sql`      |

## Mensajes de commit

El historial del repositorio sigue la especificación
[Conventional Commits](https://www.conventionalcommits.org/es/v1.0.0/):

- **Patrón:** **`<tipo>(<ámbito>): <descripción>`**
  - `<tipo>`: `feat` (nueva funcionalidad), `docs` (documentación),
    `chore` (tareas de mantenimiento).
  - `<ámbito>`: capa o componente afectado (`db`, `bronze`, `silver`, `gold`).
  - Ejemplo: `feat(silver): desarrollar proceso ETL proc_load_silver y pruebas de calidad`.
