# Resultados de sql/ejercicio3

Generado automaticamente el 2026-10-06T00:14:17 con `python scripts/run_sql.py ejercicio3`.
No editar a mano: volver a ejecutar el script tras cambiar las consultas.

DuckDB 1.5.5

## 3.1 - Cantidad de archivos disponibles por tipo y anio

**Objetivo:** Contar los archivos Parquet descargados y listar los meses que cubren, para confirmar que no hay huecos en la serie mensual.  
**Fuente:** data/raw/*/*/*.parquet (solo nombres de archivo, no se leen datos)  
**Archivo:** `sql/ejercicio3/3_01_cantidad_archivos.sql`  
**Tiempo de ejecucion:** 0.927 s - **filas del resultado:** 2

```sql
-- @id: 3.1
-- @titulo: Cantidad de archivos disponibles por tipo y anio
-- @objetivo: Contar los archivos Parquet descargados y listar los meses que
--   cubren, para confirmar que no hay huecos en la serie mensual.
-- @fuente: data/raw/*/*/*.parquet (solo nombres de archivo, no se leen datos)
SELECT
    regexp_extract(file, 'raw[/\\](\w+)[/\\]', 1)           AS tipo,
    regexp_extract(file, 'raw[/\\]\w+[/\\](\d{4})', 1)      AS anio,
    count(*)                                                AS archivos,
    string_agg(regexp_extract(file, '_\d{4}-(\d{2})\.parquet$', 1), ', '
               ORDER BY file)                               AS meses
FROM glob('data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY tipo, anio;
```

**Resultado:**

| tipo | anio | archivos | meses |
|---|---|---|---|
| green | 2026 | 8 | 01, 02, 03, 04, 05, 06, 07, 08 |
| yellow | 2026 | 8 | 01, 02, 03, 04, 05, 06, 07, 08 |

---

## 3.2a - Registros por archivo usando solo los metadatos Parquet

**Objetivo:** Obtener la cantidad de filas de cada archivo leyendo unicamente el footer del Parquet (sin escanear los datos) y detectar meses con volumen anormalmente bajo o alto.  
**Fuente:** data/raw/*/*/*.parquet via parquet_file_metadata()  
**Archivo:** `sql/ejercicio3/3_02_registros_por_archivo.sql`  
**Tiempo de ejecucion:** 0.067 s - **filas del resultado:** 16

```sql
-- @id: 3.2a
-- @titulo: Registros por archivo usando solo los metadatos Parquet
-- @objetivo: Obtener la cantidad de filas de cada archivo leyendo unicamente el
--   footer del Parquet (sin escanear los datos) y detectar meses con volumen
--   anormalmente bajo o alto.
-- @fuente: data/raw/*/*/*.parquet via parquet_file_metadata()
SELECT
    regexp_extract(file_name, 'raw[/\\](\w+)[/\\]', 1)      AS tipo,
    regexp_extract(file_name, '_(\d{4}-\d{2})\.parquet$', 1) AS periodo,
    num_rows                                                AS registros,
    num_row_groups                                          AS row_groups,
    created_by
FROM parquet_file_metadata('data/raw/*/*/*.parquet')
ORDER BY tipo, periodo;
```

**Resultado:**

| tipo | periodo | registros | row_groups | created_by |
|---|---|---|---|---|
| green | 2026-01 | 40,272 | 1 | parquet-cpp-arrow version 16.1.0 |
| green | 2026-02 | 37,373 | 1 | parquet-cpp-arrow version 16.1.0 |
| green | 2026-03 | 44,208 | 1 | parquet-cpp-arrow version 16.1.0 |
| green | 2026-04 | 44,238 | 1 | parquet-cpp-arrow version 16.1.0 |
| green | 2026-05 | 44,921 | 1 | parquet-cpp-arrow version 16.1.0 |
| green | 2026-06 | 44,163 | 1 | parquet-cpp-arrow version 21.0.0 |
| green | 2026-07 | 41,252 | 1 | parquet-cpp-arrow version 21.0.0 |
| green | 2026-08 | 40,687 | 1 | parquet-cpp-arrow version 21.0.0 |
| yellow | 2026-01 | 3,724,889 | 4 | parquet-cpp-arrow version 16.1.0 |
| yellow | 2026-02 | 3,399,866 | 4 | parquet-cpp-arrow version 16.1.0 |
| yellow | 2026-03 | 3,952,451 | 4 | parquet-cpp-arrow version 16.1.0 |
| yellow | 2026-04 | 3,831,240 | 4 | parquet-cpp-arrow version 24.0.0 |
| yellow | 2026-05 | 4,090,836 | 4 | parquet-cpp-arrow version 16.1.0 |
| yellow | 2026-06 | 3,837,248 | 4 | parquet-cpp-arrow version 21.0.0 |
| yellow | 2026-07 | 3,530,109 | 4 | parquet-cpp-arrow version 21.0.0 |
| yellow | 2026-08 | 3,336,716 | 4 | parquet-cpp-arrow version 21.0.0 |

---

## 3.2b - Registros totales por tipo de taxi (escaneo con count)

**Objetivo:** Contar el total de registros consultando los Parquet y comparar con la suma de metadatos de 3.2a (deben coincidir).  
**Fuente:** data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet  
**Archivo:** `sql/ejercicio3/3_03_registros_totales.sql`  
**Tiempo de ejecucion:** 0.178 s - **filas del resultado:** 3

```sql
-- @id: 3.2b
-- @titulo: Registros totales por tipo de taxi (escaneo con count)
-- @objetivo: Contar el total de registros consultando los Parquet y comparar
--   con la suma de metadatos de 3.2a (deben coincidir).
-- @fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet
SELECT 'yellow' AS tipo, count(*) AS registros
FROM read_parquet('data/raw/yellow/*/*.parquet')
UNION ALL
SELECT 'green', count(*)
FROM read_parquet('data/raw/green/*/*.parquet')
UNION ALL
SELECT 'total', count(*)
FROM read_parquet('data/raw/*/*/*.parquet', union_by_name = true);
```

**Resultado:**

| tipo | registros |
|---|---|
| yellow | 29,703,355 |
| green | 337,114 |
| total | 30,040,469 |

---

## 3.3a - Columnas y tipos de datos - taxis amarillos

**Objetivo:** Identificar las columnas y el tipo de dato que DuckDB infiere al leer todos los archivos amarillos en conjunto.  
**Fuente:** data/raw/yellow/*/*.parquet  
**Archivo:** `sql/ejercicio3/3_04_columnas_yellow.sql`  
**Tiempo de ejecucion:** 0.031 s - **filas del resultado:** 21

```sql
-- @id: 3.3a
-- @titulo: Columnas y tipos de datos - taxis amarillos
-- @objetivo: Identificar las columnas y el tipo de dato que DuckDB infiere al
--   leer todos los archivos amarillos en conjunto.
-- @fuente: data/raw/yellow/*/*.parquet
DESCRIBE SELECT * FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true);
```

**Resultado:**

| column_name | column_type | null | key | default | extra |
|---|---|---|---|---|---|
| VendorID | INTEGER | YES | NULL | NULL | NULL |
| tpep_pickup_datetime | TIMESTAMP | YES | NULL | NULL | NULL |
| tpep_dropoff_datetime | TIMESTAMP | YES | NULL | NULL | NULL |
| passenger_count | BIGINT | YES | NULL | NULL | NULL |
| trip_distance | DOUBLE | YES | NULL | NULL | NULL |
| RatecodeID | BIGINT | YES | NULL | NULL | NULL |
| store_and_fwd_flag | VARCHAR | YES | NULL | NULL | NULL |
| PULocationID | INTEGER | YES | NULL | NULL | NULL |
| DOLocationID | INTEGER | YES | NULL | NULL | NULL |
| payment_type | BIGINT | YES | NULL | NULL | NULL |
| fare_amount | DOUBLE | YES | NULL | NULL | NULL |
| extra | DOUBLE | YES | NULL | NULL | NULL |
| mta_tax | DOUBLE | YES | NULL | NULL | NULL |
| tip_amount | DOUBLE | YES | NULL | NULL | NULL |
| tolls_amount | DOUBLE | YES | NULL | NULL | NULL |
| improvement_surcharge | DOUBLE | YES | NULL | NULL | NULL |
| total_amount | DOUBLE | YES | NULL | NULL | NULL |
| congestion_surcharge | DOUBLE | YES | NULL | NULL | NULL |
| Airport_fee | DOUBLE | YES | NULL | NULL | NULL |
| cbd_congestion_fee | DOUBLE | YES | NULL | NULL | NULL |
| request_source | VARCHAR | YES | NULL | NULL | NULL |

---

## 3.3b - Columnas y tipos de datos - taxis verdes

**Objetivo:** Identificar las columnas y el tipo de dato de los archivos verdes.  
**Fuente:** data/raw/green/*/*.parquet  
**Archivo:** `sql/ejercicio3/3_05_columnas_green.sql`  
**Tiempo de ejecucion:** 0.030 s - **filas del resultado:** 22

```sql
-- @id: 3.3b
-- @titulo: Columnas y tipos de datos - taxis verdes
-- @objetivo: Identificar las columnas y el tipo de dato de los archivos verdes.
-- @fuente: data/raw/green/*/*.parquet
DESCRIBE SELECT * FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true);
```

**Resultado:**

| column_name | column_type | null | key | default | extra |
|---|---|---|---|---|---|
| VendorID | INTEGER | YES | NULL | NULL | NULL |
| lpep_pickup_datetime | TIMESTAMP | YES | NULL | NULL | NULL |
| lpep_dropoff_datetime | TIMESTAMP | YES | NULL | NULL | NULL |
| store_and_fwd_flag | VARCHAR | YES | NULL | NULL | NULL |
| RatecodeID | BIGINT | YES | NULL | NULL | NULL |
| PULocationID | INTEGER | YES | NULL | NULL | NULL |
| DOLocationID | INTEGER | YES | NULL | NULL | NULL |
| passenger_count | BIGINT | YES | NULL | NULL | NULL |
| trip_distance | DOUBLE | YES | NULL | NULL | NULL |
| fare_amount | DOUBLE | YES | NULL | NULL | NULL |
| extra | DOUBLE | YES | NULL | NULL | NULL |
| mta_tax | DOUBLE | YES | NULL | NULL | NULL |
| tip_amount | DOUBLE | YES | NULL | NULL | NULL |
| tolls_amount | DOUBLE | YES | NULL | NULL | NULL |
| ehail_fee | DOUBLE | YES | NULL | NULL | NULL |
| improvement_surcharge | DOUBLE | YES | NULL | NULL | NULL |
| total_amount | DOUBLE | YES | NULL | NULL | NULL |
| payment_type | BIGINT | YES | NULL | NULL | NULL |
| trip_type | BIGINT | YES | NULL | NULL | NULL |
| congestion_surcharge | DOUBLE | YES | NULL | NULL | NULL |
| cbd_congestion_fee | DOUBLE | YES | NULL | NULL | NULL |
| request_source | VARCHAR | YES | NULL | NULL | NULL |

---

## 3.3c - Comparacion de columnas entre amarillos y verdes

**Objetivo:** Ver que columnas son comunes, cuales son exclusivas de un tipo y cuales tienen distinto nombre o tipo, para disenar un esquema unificado.  
**Fuente:** data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet  
**Archivo:** `sql/ejercicio3/3_06_comparacion_columnas.sql`  
**Tiempo de ejecucion:** 0.067 s - **filas del resultado:** 25

```sql
-- @id: 3.3c
-- @titulo: Comparacion de columnas entre amarillos y verdes
-- @objetivo: Ver que columnas son comunes, cuales son exclusivas de un tipo y
--   cuales tienen distinto nombre o tipo, para disenar un esquema unificado.
-- @fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet
WITH y AS (
    SELECT column_name, column_type
    FROM (DESCRIBE SELECT * FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true))
), g AS (
    SELECT column_name, column_type
    FROM (DESCRIBE SELECT * FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true))
)
SELECT
    coalesce(y.column_name, g.column_name)  AS columna,
    y.column_type                           AS tipo_yellow,
    g.column_type                           AS tipo_green,
    CASE WHEN y.column_name IS NULL THEN 'solo green'
         WHEN g.column_name IS NULL THEN 'solo yellow'
         WHEN y.column_type <> g.column_type THEN 'tipo distinto'
         ELSE 'comun' END                   AS estado
FROM y FULL OUTER JOIN g ON lower(y.column_name) = lower(g.column_name)
ORDER BY estado, columna;
```

**Resultado:**

| columna | tipo_yellow | tipo_green | estado |
|---|---|---|---|
| DOLocationID | INTEGER | INTEGER | comun |
| PULocationID | INTEGER | INTEGER | comun |
| RatecodeID | BIGINT | BIGINT | comun |
| VendorID | INTEGER | INTEGER | comun |
| cbd_congestion_fee | DOUBLE | DOUBLE | comun |
| congestion_surcharge | DOUBLE | DOUBLE | comun |
| extra | DOUBLE | DOUBLE | comun |
| fare_amount | DOUBLE | DOUBLE | comun |
| improvement_surcharge | DOUBLE | DOUBLE | comun |
| mta_tax | DOUBLE | DOUBLE | comun |
| passenger_count | BIGINT | BIGINT | comun |
| payment_type | BIGINT | BIGINT | comun |
| request_source | VARCHAR | VARCHAR | comun |
| store_and_fwd_flag | VARCHAR | VARCHAR | comun |
| tip_amount | DOUBLE | DOUBLE | comun |
| tolls_amount | DOUBLE | DOUBLE | comun |
| total_amount | DOUBLE | DOUBLE | comun |
| trip_distance | DOUBLE | DOUBLE | comun |
| ehail_fee | NULL | DOUBLE | solo green |
| lpep_dropoff_datetime | NULL | TIMESTAMP | solo green |
| lpep_pickup_datetime | NULL | TIMESTAMP | solo green |
| trip_type | NULL | BIGINT | solo green |
| Airport_fee | DOUBLE | NULL | solo yellow |
| tpep_dropoff_datetime | TIMESTAMP | NULL | solo yellow |
| tpep_pickup_datetime | TIMESTAMP | NULL | solo yellow |

---

## 3.4 - Consistencia de tipos fisicos entre archivos

**Objetivo:** Revisar, columna por columna, si todos los archivos usan el mismo tipo Parquet. Una columna con mas de un tipo o presente en menos archivos que el total indica un cambio de esquema entre meses/anios.  
**Fuente:** data/raw/*/*/*.parquet via parquet_schema()  
**Archivo:** `sql/ejercicio3/3_07_tipos_por_archivo.sql`  
**Tiempo de ejecucion:** 0.087 s - **filas del resultado:** 43

```sql
-- @id: 3.4
-- @titulo: Consistencia de tipos fisicos entre archivos
-- @objetivo: Revisar, columna por columna, si todos los archivos usan el mismo
--   tipo Parquet. Una columna con mas de un tipo o presente en menos archivos
--   que el total indica un cambio de esquema entre meses/anios.
-- @fuente: data/raw/*/*/*.parquet via parquet_schema()
WITH s AS (
    SELECT
        regexp_extract(file_name, 'raw[/\\](\w+)[/\\]', 1) AS tipo,
        file_name,
        name,
        type || coalesce(' (' || CASE
            WHEN logical_type LIKE 'TimestampType%'
                THEN 'TIMESTAMP_' || regexp_extract(logical_type, '(MILLIS|MICROS|NANOS)=[^<]', 1)
            ELSE coalesce(converted_type, regexp_replace(logical_type, '\(.*', ''))
        END || ')', '')                                    AS tipo_parquet
    FROM parquet_schema('data/raw/*/*/*.parquet')
    WHERE type IS NOT NULL                     -- excluye el nodo raiz del esquema
), archivos AS (
    SELECT tipo, count(DISTINCT file_name) AS total FROM s GROUP BY tipo
)
SELECT
    s.tipo,
    s.name                                         AS columna,
    string_agg(DISTINCT s.tipo_parquet, ' | ')     AS tipos_parquet,
    count(DISTINCT s.tipo_parquet)                 AS n_tipos,
    count(DISTINCT s.file_name)                    AS en_archivos,
    any_value(a.total)                             AS archivos_totales
FROM s JOIN archivos a USING (tipo)
GROUP BY s.tipo, s.name
ORDER BY s.tipo, (n_tipos > 1 OR en_archivos < archivos_totales) DESC, columna;
```

**Resultado:**

| tipo | columna | tipos_parquet | n_tipos | en_archivos | archivos_totales |
|---|---|---|---|---|---|
| green | request_source | BYTE_ARRAY (UTF8) | 1 | 3 | 8 |
| green | DOLocationID | INT32 | 1 | 8 | 8 |
| green | PULocationID | INT32 | 1 | 8 | 8 |
| green | RatecodeID | INT64 | 1 | 8 | 8 |
| green | VendorID | INT32 | 1 | 8 | 8 |
| green | cbd_congestion_fee | DOUBLE | 1 | 8 | 8 |
| green | congestion_surcharge | DOUBLE | 1 | 8 | 8 |
| green | ehail_fee | DOUBLE | 1 | 8 | 8 |
| green | extra | DOUBLE | 1 | 8 | 8 |
| green | fare_amount | DOUBLE | 1 | 8 | 8 |
| green | improvement_surcharge | DOUBLE | 1 | 8 | 8 |
| green | lpep_dropoff_datetime | INT64 (TIMESTAMP_MICROS) | 1 | 8 | 8 |
| green | lpep_pickup_datetime | INT64 (TIMESTAMP_MICROS) | 1 | 8 | 8 |
| green | mta_tax | DOUBLE | 1 | 8 | 8 |
| green | passenger_count | INT64 | 1 | 8 | 8 |
| green | payment_type | INT64 | 1 | 8 | 8 |
| green | store_and_fwd_flag | BYTE_ARRAY (UTF8) | 1 | 8 | 8 |
| green | tip_amount | DOUBLE | 1 | 8 | 8 |
| green | tolls_amount | DOUBLE | 1 | 8 | 8 |
| green | total_amount | DOUBLE | 1 | 8 | 8 |
| green | trip_distance | DOUBLE | 1 | 8 | 8 |
| green | trip_type | INT64 | 1 | 8 | 8 |
| yellow | request_source | BYTE_ARRAY (UTF8) | 1 | 3 | 8 |
| yellow | Airport_fee | DOUBLE | 1 | 8 | 8 |
| yellow | DOLocationID | INT32 | 1 | 8 | 8 |
| yellow | PULocationID | INT32 | 1 | 8 | 8 |
| yellow | RatecodeID | INT64 | 1 | 8 | 8 |
| yellow | VendorID | INT32 | 1 | 8 | 8 |
| yellow | cbd_congestion_fee | DOUBLE | 1 | 8 | 8 |
| yellow | congestion_surcharge | DOUBLE | 1 | 8 | 8 |
| yellow | extra | DOUBLE | 1 | 8 | 8 |
| yellow | fare_amount | DOUBLE | 1 | 8 | 8 |
| yellow | improvement_surcharge | DOUBLE | 1 | 8 | 8 |
| yellow | mta_tax | DOUBLE | 1 | 8 | 8 |
| yellow | passenger_count | INT64 | 1 | 8 | 8 |
| yellow | payment_type | INT64 | 1 | 8 | 8 |
| yellow | store_and_fwd_flag | BYTE_ARRAY (UTF8) | 1 | 8 | 8 |
| yellow | tip_amount | DOUBLE | 1 | 8 | 8 |
| yellow | tolls_amount | DOUBLE | 1 | 8 | 8 |
| yellow | total_amount | DOUBLE | 1 | 8 | 8 |

_... 3 filas mas (ver CSV)._

---

## 3.5a - Muestra reproducible de 10 registros - taxis amarillos

**Objetivo:** Inspeccionar registros reales para entender formato y valores. Se ordena por un hash de varias columnas en lugar de usar USING SAMPLE: el resultado es pseudoaleatorio pero identico en cada ejecucion, sin importar cuantos hilos use DuckDB.  
**Fuente:** data/raw/yellow/*/*.parquet  
**Archivo:** `sql/ejercicio3/3_08_muestra_yellow.sql`  
**Tiempo de ejecucion:** 5.981 s - **filas del resultado:** 10

```sql
-- @id: 3.5a
-- @titulo: Muestra reproducible de 10 registros - taxis amarillos
-- @objetivo: Inspeccionar registros reales para entender formato y valores.
--   Se ordena por un hash de varias columnas en lugar de usar USING SAMPLE:
--   el resultado es pseudoaleatorio pero identico en cada ejecucion, sin
--   importar cuantos hilos use DuckDB.
-- @fuente: data/raw/yellow/*/*.parquet
SELECT *
FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)
ORDER BY hash(tpep_pickup_datetime, tpep_dropoff_datetime, PULocationID, DOLocationID, total_amount)
LIMIT 10;
```

**Resultado:**

| VendorID | tpep_pickup_datetime | tpep_dropoff_datetime | passenger_count | trip_distance | RatecodeID | store_and_fwd_flag | PULocationID | DOLocationID | payment_type | fare_amount | extra | mta_tax | tip_amount | tolls_amount | improvement_surcharge | total_amount | congestion_surcharge | Airport_fee | cbd_congestion_fee | request_source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2 | 2026-07-23 02:07:37 | 2026-07-23 02:37:35 | <NA> | 8.79 | <NA> | NULL | 48 | 61 | 0 | 33.04 | 0 | 0.5 | 0 | 0 | 1 | 37.79 | NULL | NULL | 0.75 | A |
| 2 | 2026-08-11 08:25:53 | 2026-08-11 08:38:23 | 1 | 1.94 | 1 | N | 263 | 162 | 1 | 13.5 | 0 | 0.5 | 3.65 | 0 | 1 | 21.9 | 2.5 | 0 | 0.75 | NULL |
| 2 | 2026-06-08 22:35:26 | 2026-06-08 22:40:56 | 1 | 1.4 | 1 | N | 151 | 239 | 1 | 8.6 | 1 | 0.5 | 2.72 | 0 | 1 | 16.32 | 2.5 | 0 | 0 | NULL |
| 2 | 2026-03-13 20:16:32 | 2026-03-13 20:32:58 | 1 | 4.45 | 1 | N | 13 | 79 | 1 | 21.9 | 1 | 0.5 | 6.91 | 0 | 1 | 34.56 | 2.5 | 0 | 0.75 | NULL |
| 2 | 2026-02-27 17:58:08 | 2026-02-27 18:27:12 | 1 | 6.78 | 1 | N | 151 | 231 | 1 | 33.8 | 2.5 | 0.5 | 8.21 | 0 | 1 | 49.26 | 2.5 | 0 | 0.75 | NULL |
| 2 | 2026-08-26 07:31:32 | 2026-08-26 07:37:09 | 1 | 0.85 | 1 | N | 170 | 161 | 1 | 7.2 | 0 | 0.5 | 2.39 | 0 | 1 | 14.34 | 2.5 | 0 | 0.75 | NULL |
| 2 | 2026-08-12 13:49:12 | 2026-08-12 14:08:18 | <NA> | 3.01 | <NA> | NULL | 237 | 24 | 0 | 19.94 | 0 | 0.5 | 0 | 0 | 1 | 23.94 | NULL | NULL | 0 | HV0003 |
| 1 | 2026-03-13 17:48:01 | 2026-03-13 18:00:44 | 1 | 2.1 | 99 | N | 55 | 108 | 1 | 19.5 | 0 | 0.5 | 0 | 0 | 0 | 20 | 0 | 0 | 0 | NULL |
| 2 | 2026-03-02 13:01:15 | 2026-03-02 13:06:01 | 1 | 1.01 | 1 | N | 236 | 238 | 1 | 7.2 | 0 | 0.5 | 2.24 | 0 | 1 | 13.44 | 2.5 | 0 | 0 | NULL |
| 2 | 2026-04-09 17:33:06 | 2026-04-09 17:56:00 | 2 | 2.13 | 1 | N | 236 | 161 | 1 | 20.5 | 2.5 | 0.5 | 5.55 | 0 | 1 | 33.3 | 2.5 | 0 | 0.75 | NULL |

---

## 3.5b - Muestra reproducible de 10 registros - taxis verdes

**Objetivo:** Inspeccionar registros reales para entender formato y valores. Se ordena por un hash de varias columnas en lugar de usar USING SAMPLE: el resultado es pseudoaleatorio pero identico en cada ejecucion, sin importar cuantos hilos use DuckDB.  
**Fuente:** data/raw/green/*/*.parquet  
**Archivo:** `sql/ejercicio3/3_09_muestra_green.sql`  
**Tiempo de ejecucion:** 0.255 s - **filas del resultado:** 10

```sql
-- @id: 3.5b
-- @titulo: Muestra reproducible de 10 registros - taxis verdes
-- @objetivo: Inspeccionar registros reales para entender formato y valores.
--   Se ordena por un hash de varias columnas en lugar de usar USING SAMPLE:
--   el resultado es pseudoaleatorio pero identico en cada ejecucion, sin
--   importar cuantos hilos use DuckDB.
-- @fuente: data/raw/green/*/*.parquet
SELECT *
FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true)
ORDER BY hash(lpep_pickup_datetime, lpep_dropoff_datetime, PULocationID, DOLocationID, total_amount)
LIMIT 10;
```

**Resultado:**

| VendorID | lpep_pickup_datetime | lpep_dropoff_datetime | store_and_fwd_flag | RatecodeID | PULocationID | DOLocationID | passenger_count | trip_distance | fare_amount | extra | mta_tax | tip_amount | tolls_amount | ehail_fee | improvement_surcharge | total_amount | payment_type | trip_type | congestion_surcharge | cbd_congestion_fee | request_source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2 | 2026-07-29 08:01:49 | 2026-07-29 08:35:15 | N | 1 | 243 | 163 | 1 | 8.11 | 39.4 | 0 | 0.5 | 5 | 0 | NULL | 1 | 49.4 | 1 | 1 | 2.75 | 0.75 | NULL |
| 2 | 2026-06-04 07:52:48 | 2026-06-04 08:02:40 | N | 1 | 75 | 239 | 1 | 1.78 | 12.1 | 0 | 0.5 | 1.5 | 0 | NULL | 1 | 17.85 | 1 | 1 | 2.75 | 0 | NULL |
| 2 | 2026-08-26 23:19:11 | 2026-08-26 23:41:57 | N | 1 | 93 | 141 | 5 | 11.33 | 45.7 | 1 | 0.5 | 11.58 | 6.94 | NULL | 1 | 69.47 | 1 | 1 | 2.75 | 0 | NULL |
| 2 | 2026-08-15 16:21:11 | 2026-08-15 16:31:19 | N | 1 | 43 | 237 | 1 | 2.12 | 12.8 | 0 | 0.5 | 1.95 | 0 | NULL | 1 | 19 | 1 | 1 | 2.75 | 0 | NULL |
| 2 | 2026-08-18 11:45:08 | 2026-08-18 11:53:40 | N | 1 | 74 | 41 | 1 | 0.86 | 9.3 | 0 | 0.5 | 0.1 | 0 | NULL | 1 | 10.9 | 1 | 1 | 0 | 0 | NULL |
| 2 | 2026-03-23 07:20:26 | 2026-03-23 07:26:49 | N | 1 | 122 | 130 | 1 | 1.21 | 8.6 | 0 | 0.5 | 0 | 0 | NULL | 1 | 10.1 | 2 | 1 | 0 | 0 | NULL |
| 6 | 2026-05-24 00:14:58 | 2026-05-24 00:23:31 | NULL | <NA> | 20 | 241 | <NA> | 1.57 | 3 | 0 | 0.5 | 0 | 0 | NULL | 0.3 | 16 | <NA> | <NA> | NULL | 0 | NULL |
| 2 | 2026-04-21 12:13:16 | 2026-04-21 12:22:26 | N | 1 | 43 | 238 | 1 | 1.61 | 10.7 | 0 | 0.5 | 2.99 | 0 | NULL | 1 | 17.94 | 1 | 1 | 2.75 | 0 | NULL |
| 2 | 2026-07-30 08:43:56 | 2026-07-30 08:53:17 | N | 1 | 74 | 75 | 1 | 1.13 | 10 | 0 | 0.5 | 5 | 0 | NULL | 1 | 16.5 | 1 | 1 | 0 | 0 | NULL |
| 1 | 2026-05-04 17:26:48 | 2026-05-04 17:33:57 | N | 1 | 75 | 263 | 1 | 1.1 | 8.6 | 5.25 | 1.5 | 1 | 0 | NULL | 1 | 16.35 | 1 | 1 | 2.75 | 0 | NULL |

---

## 3.6a - Perfil estadistico de columnas - taxis amarillos (SUMMARIZE)

**Objetivo:** Obtener min, max, promedio, cuartiles, valores unicos aproximados y porcentaje de nulos de cada columna para detectar rangos imposibles y columnas con muchos nulos.  
**Fuente:** data/raw/yellow/*/*.parquet  
**Archivo:** `sql/ejercicio3/3_10_resumen_yellow.sql`  
**Tiempo de ejecucion:** 50.690 s - **filas del resultado:** 21

```sql
-- @id: 3.6a
-- @titulo: Perfil estadistico de columnas - taxis amarillos (SUMMARIZE)
-- @objetivo: Obtener min, max, promedio, cuartiles, valores unicos aproximados y
--   porcentaje de nulos de cada columna para detectar rangos imposibles y
--   columnas con muchos nulos.
-- @fuente: data/raw/yellow/*/*.parquet
SUMMARIZE SELECT * FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true);
```

**Resultado:**

| column_name | column_type | min | max | approx_unique | avg | std | q25 | q50 | q75 | count | null_percentage |
|---|---|---|---|---|---|---|---|---|---|---|---|
| VendorID | INTEGER | 1 | 7 | 4 | 1.885739809526567 | 0.715527751402235 | 2 | 2 | 2 | 29,703,355 | 0 |
| tpep_pickup_datetime | TIMESTAMP | 2001-01-01 09:23:58 | 2026-08-31 23:59:59 | 16,867,928 | 2026-04-30 15:29:29.519432 | NULL | 2026-03-03 08:52:16.673668 | 2026-04-30 18:49:24.542432 | 2026-06-26 06:36:12.304484 | 29,703,355 | 0 |
| tpep_dropoff_datetime | TIMESTAMP | 2001-01-01 16:09:38 | 2026-09-01 20:16:00 | 16,587,125 | 2026-04-30 15:47:08.186216 | NULL | 2026-03-03 22:55:43.052413 | 2026-04-30 22:54:37.262358 | 2026-06-26 07:45:22.980705 | 29,703,355 | 0 |
| passenger_count | BIGINT | 0 | 9 | 11 | 1.2494318488564 | 0.6529195072996739 | 1 | 1 | 1 | 29,703,355 | 25.98 |
| trip_distance | DOUBLE | 0.0 | 328522.2 | 7,217 | 5.55294014969445 | 550.6497893230727 | 1.0210855249090016 | 1.856982426183933 | 3.813593482037547 | 29,703,355 | 0 |
| RatecodeID | BIGINT | 1 | 99 | 7 | 4.527471444398553 | 18.00092654006735 | 1 | 1 | 1 | 29,703,355 | 25.98 |
| store_and_fwd_flag | VARCHAR | N | Y | 2 | NULL | NULL | NULL | NULL | NULL | 29,703,355 | 25.98 |
| PULocationID | INTEGER | 1 | 265 | 290 | 161.57793013617484 | 66.7465670325179 | 117 | 161 | 233 | 29,703,355 | 0 |
| DOLocationID | INTEGER | 1 | 265 | 298 | 161.05139342003622 | 70.72548569211571 | 109 | 162 | 233 | 29,703,355 | 0 |
| payment_type | BIGINT | 0 | 5 | 6 | 0.8621735154160195 | 0.6463324345961792 | 0 | 1 | 1 | 29,703,355 | 0 |
| fare_amount | DOUBLE | -2555.2 | 7045.0 | 18,028 | 21.262128778901857 | 18.958296845957676 | 10.011071253185747 | 15.77860754800396 | 26.380564587245072 | 29,703,355 | 0 |
| extra | DOUBLE | -7.5 | 244.35 | 360 | 1.112700345129355 | 1.7506914816702084 | 0.0 | 0.0 | 2.4997590347190366 | 29,703,355 | 0 |
| mta_tax | DOUBLE | -0.5 | 11.5 | 21 | 0.4882513830508388 | 0.09190423736483679 | 0.5 | 0.5 | 0.5 | 29,703,355 | 0 |
| tip_amount | DOUBLE | -222.0 | 766.0 | 6,049 | 2.8311150171483535 | 3.9665764205081824 | 0.0 | 2.044663348738667 | 3.9668857448198045 | 29,703,355 | 0 |
| tolls_amount | DOUBLE | -129.48 | 1400.0 | 3,451 | 0.5360736017846343 | 2.2270316740851284 | 0.0 | 0.0 | 0.0 | 29,703,355 | 0 |
| improvement_surcharge | DOUBLE | -1.0 | 4.0 | 6 | 0.9659906263119706 | 0.2079128726687153 | 1.0 | 1.0 | 1.0 | 29,703,355 | 0 |
| total_amount | DOUBLE | -2560.2 | 7053.5 | 38,649 | 30.06970577192441 | 22.75340804573155 | 17.371416622729036 | 23.64247008334145 | 34.59845211254647 | 29,703,355 | 0 |
| congestion_surcharge | DOUBLE | -2.5 | 2.75 | 7 | 2.216917730186208 | 0.836447665790652 | 2.5 | 2.5 | 2.5 | 29,703,355 | 25.98 |
| Airport_fee | DOUBLE | -2.0 | 27.0 | 15 | 0.16706982008687357 | 0.5781861746411203 | 0.0 | 0.0 | 0.0 | 29,703,355 | 25.98 |
| cbd_congestion_fee | DOUBLE | -0.75 | 0.75 | 3 | 0.5355387211309968 | 0.34470526991554573 | 0.0 | 0.75 | 0.75 | 29,703,355 | 0 |
| request_source | VARCHAR | A | HV0005 | 3 | NULL | NULL | NULL | NULL | NULL | 29,703,355 | 90.23 |

---

## 3.6b - Perfil estadistico de columnas - taxis verdes (SUMMARIZE)

**Objetivo:** Igual que 3.6a para taxis verdes.  
**Fuente:** data/raw/green/*/*.parquet  
**Archivo:** `sql/ejercicio3/3_11_resumen_green.sql`  
**Tiempo de ejecucion:** 0.760 s - **filas del resultado:** 22

```sql
-- @id: 3.6b
-- @titulo: Perfil estadistico de columnas - taxis verdes (SUMMARIZE)
-- @objetivo: Igual que 3.6a para taxis verdes.
-- @fuente: data/raw/green/*/*.parquet
SUMMARIZE SELECT * FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true);
```

**Resultado:**

| column_name | column_type | min | max | approx_unique | avg | std | q25 | q50 | q75 | count | null_percentage |
|---|---|---|---|---|---|---|---|---|---|---|---|
| VendorID | INTEGER | 1 | 6 | 3 | 2.328351833504393 | 1.2771882973738615 | 2 | 2 | 2 | 337,114 | 0 |
| lpep_pickup_datetime | TIMESTAMP | 2008-12-31 17:35:31 | 2026-08-31 23:58:28 | 332,702 | 2026-05-02 13:25:51.096427 | NULL | 2026-03-05 14:54:40.687588 | 2026-05-02 10:53:28.804252 | 2026-06-29 00:03:42.863509 | 337,114 | 0 |
| lpep_dropoff_datetime | TIMESTAMP | 2008-12-31 23:16:26 | 2026-09-02 09:39:37 | 396,286 | 2026-05-02 13:46:38.833759 | NULL | 2026-03-05 15:19:20.280822 | 2026-05-03 06:54:13.391653 | 2026-06-28 18:27:22.761652 | 337,114 | 0 |
| store_and_fwd_flag | VARCHAR | N | Y | 2 | NULL | NULL | NULL | NULL | NULL | 337,114 | 14.47 |
| RatecodeID | BIGINT | 1 | 99 | 7 | 1.2549672434183374 | 1.001532742429609 | 1 | 1 | 1 | 337,114 | 14.47 |
| PULocationID | INTEGER | 1 | 265 | 263 | 97.32761024460568 | 56.57830275002363 | 74 | 75 | 105 | 337,114 | 0 |
| DOLocationID | INTEGER | 1 | 265 | 266 | 142.8768458147689 | 77.24476821098133 | 75 | 140 | 229 | 337,114 | 0 |
| passenger_count | BIGINT | 0 | 9 | 11 | 1.3006461144694266 | 0.9481007387491724 | 1 | 1 | 1 | 337,114 | 14.47 |
| trip_distance | DOUBLE | 0.0 | 179830.92 | 2,472 | 13.349507644298589 | 880.4035093234602 | 1.2547362084877447 | 2.0664427789364144 | 3.692927759057714 | 337,114 | 0 |
| fare_amount | DOUBLE | -500.0 | 1676.7 | 4,808 | 17.014101995171035 | 17.958627635270734 | 8.6052967691756 | 13.227575877193386 | 19.679178764906137 | 337,114 | 0 |
| extra | DOUBLE | -7.5 | 10.0 | 21 | 0.8195284087875319 | 1.3603053200356445 | 0.0 | 0.0 | 1.0 | 337,114 | 0 |
| mta_tax | DOUBLE | -0.5 | 5.0 | 7 | 0.5467816524973748 | 0.3096869213407807 | 0.5 | 0.5 | 0.5 | 337,114 | 0 |
| tip_amount | DOUBLE | -14.0 | 495.0 | 2,212 | 2.6208176165925527 | 5.3993581721495945 | 0.0 | 2.010430709002768 | 3.856216563457941 | 337,114 | 0 |
| tolls_amount | DOUBLE | -24.5 | 85.0 | 75 | 0.2941987576902501 | 1.5552168995551865 | 0.0 | 0.0 | 0.0 | 337,114 | 0 |
| ehail_fee | DOUBLE | NULL | NULL | 0 | NULL | NULL | NULL | NULL | NULL | 337,114 | 100 |
| improvement_surcharge | DOUBLE | -1.0 | 1.0 | 5 | 0.915274654864457 | 0.2518603083055542 | 1.0 | 1.0 | 1.0 | 337,114 | 0 |
| total_amount | DOUBLE | -501.5 | 1678.2 | 8,186 | 25.492562070990026 | 20.55277723176857 | 14.944931296068003 | 20.46211232939094 | 29.687294770068505 | 337,114 | 0 |
| payment_type | BIGINT | 1 | 4 | 4 | 1.2481350077512927 | 0.46247144512197924 | 1 | 1 | 1 | 337,114 | 14.47 |
| trip_type | BIGINT | 1 | 2 | 2 | 1.0518525197945459 | 0.22172957965580284 | 1 | 1 | 1 | 337,114 | 14.47 |
| congestion_surcharge | DOUBLE | -2.75 | 2.75 | 5 | 0.8831271524143456 | 1.2846843025235193 | 0.0 | 0.0 | 2.75 | 337,114 | 14.47 |
| cbd_congestion_fee | DOUBLE | -0.75 | 0.75 | 3 | 0.06234018759232782 | 0.20713685724462977 | 0.0 | 0.0 | 0.0 | 337,114 | 0 |
| request_source | VARCHAR | A | HV0005 | 2 | NULL | NULL | NULL | NULL | NULL | 337,114 | 94.3 |

---

## 3.6c - Conteo de registros que violan reglas basicas de calidad

**Objetivo:** Cuantificar cada tipo de problema (fechas fuera del mes del archivo, duraciones y distancias imposibles, montos negativos, pasajeros 0, nulos) para decidir que filtros aplicar en el analisis.  
**Fuente:** data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet  
**Archivo:** `sql/ejercicio3/3_12_reglas_calidad.sql`  
**Tiempo de ejecucion:** 4.573 s - **filas del resultado:** 2

```sql
-- @id: 3.6c
-- @titulo: Conteo de registros que violan reglas basicas de calidad
-- @objetivo: Cuantificar cada tipo de problema (fechas fuera del mes del
--   archivo, duraciones y distancias imposibles, montos negativos, pasajeros 0,
--   nulos) para decidir que filtros aplicar en el analisis.
-- @fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet
WITH t AS (
    SELECT 'yellow' AS tipo, filename,
           tpep_pickup_datetime AS pu, tpep_dropoff_datetime AS dof,
           passenger_count, trip_distance, fare_amount, total_amount, payment_type, RatecodeID
    FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true, filename = true)
    UNION ALL
    SELECT 'green', filename,
           lpep_pickup_datetime, lpep_dropoff_datetime,
           passenger_count, trip_distance, fare_amount, total_amount, payment_type, RatecodeID
    FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true, filename = true)
), r AS (
    SELECT *,
        strftime(pu, '%Y-%m') <> regexp_extract(filename, '_(\d{4}-\d{2})\.parquet$', 1) AS fuera_mes,
        date_diff('second', pu, dof) / 60.0 AS dur
    FROM t
)
SELECT
    tipo,
    count(*)                                                      AS registros,
    count(*) FILTER (WHERE fuera_mes)                             AS pickup_fuera_del_mes,
    count(*) FILTER (WHERE dur < 0)                               AS dropoff_antes_pickup,
    count(*) FILTER (WHERE dur = 0)                               AS duracion_cero,
    count(*) FILTER (WHERE dur > 360)                             AS duracion_mas_6h,
    count(*) FILTER (WHERE trip_distance = 0)                     AS distancia_cero,
    count(*) FILTER (WHERE trip_distance > 100)                   AS distancia_mas_100mi,
    count(*) FILTER (WHERE fare_amount < 0)                       AS tarifa_negativa,
    count(*) FILTER (WHERE total_amount < 0)                      AS total_negativo,
    count(*) FILTER (WHERE passenger_count = 0)                   AS pasajeros_cero,
    count(*) FILTER (WHERE passenger_count IS NULL)               AS pasajeros_nulos,
    count(*) FILTER (WHERE RatecodeID IS NULL)                    AS ratecode_nulo,
    count(*) FILTER (WHERE RatecodeID = 99)                       AS ratecode_99,
    count(*) FILTER (WHERE payment_type = 0)                      AS pago_tipo_0
FROM r
GROUP BY tipo
ORDER BY tipo DESC;
```

**Resultado:**

| tipo | registros | pickup_fuera_del_mes | dropoff_antes_pickup | duracion_cero | duracion_mas_6h | distancia_cero | distancia_mas_100mi | tarifa_negativa | total_negativo | pasajeros_cero | pasajeros_nulos | ratecode_nulo | ratecode_99 | pago_tipo_0 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 29,703,355 | 146 | 10 | 371,673 | 7,315 | 952,231 | 1,223 | 157,364 | 161,835 | 91,359 | 7,716,688 | 7,716,688 | 769,693 | 7,716,688 |
| green | 337,114 | 98 | 5 | 229 | 1,104 | 12,212 | 72 | 999 | 1,023 | 4,527 | 48,775 | 48,775 | 2 | 0 |

---

## 3.6d - Detalle de fechas de pickup fuera del mes del archivo

**Objetivo:** Ver a que fechas corresponden los registros que no caen en el mes del archivo (bordes de mes vs. fechas claramente erroneas como 2008/2009).  
**Fuente:** data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet  
**Archivo:** `sql/ejercicio3/3_13_fechas_fuera_de_mes.sql`  
**Tiempo de ejecucion:** 1.526 s - **filas del resultado:** 30

```sql
-- @id: 3.6d
-- @titulo: Detalle de fechas de pickup fuera del mes del archivo
-- @objetivo: Ver a que fechas corresponden los registros que no caen en el mes
--   del archivo (bordes de mes vs. fechas claramente erroneas como 2008/2009).
-- @fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet
WITH t AS (
    SELECT 'yellow' AS tipo, filename, tpep_pickup_datetime AS pu
    FROM read_parquet('data/raw/yellow/*/*.parquet', filename = true, union_by_name = true)
    UNION ALL
    SELECT 'green', filename, lpep_pickup_datetime
    FROM read_parquet('data/raw/green/*/*.parquet', filename = true, union_by_name = true)
)
SELECT
    tipo,
    regexp_extract(filename, '_(\d{4}-\d{2})\.parquet$', 1) AS archivo_periodo,
    strftime(pu, '%Y-%m')                                    AS pickup_periodo,
    count(*)                                                 AS registros,
    min(pu)                                                  AS pickup_min,
    max(pu)                                                  AS pickup_max
FROM t
WHERE strftime(pu, '%Y-%m') <> regexp_extract(filename, '_(\d{4}-\d{2})\.parquet$', 1)
GROUP BY ALL
ORDER BY registros DESC
LIMIT 30;
```

**Resultado:**

| tipo | archivo_periodo | pickup_periodo | registros | pickup_min | pickup_max |
|---|---|---|---|---|---|
| yellow | 2026-07 | 2026-08 | 38 | 2026-08-01 00:02:37 | 2026-08-05 20:54:00 |
| green | 2026-01 | 2026-02 | 18 | 2026-02-01 00:15:28 | 2026-02-01 21:08:36 |
| yellow | 2026-03 | 2026-02 | 15 | 2026-02-28 23:38:17 | 2026-02-28 23:59:47 |
| yellow | 2026-06 | 2026-04 | 15 | 2026-04-16 18:12:39 | 2026-04-20 20:50:27 |
| yellow | 2026-08 | 2026-07 | 14 | 2026-07-31 22:08:35 | 2026-07-31 23:59:13 |
| green | 2026-08 | 2026-07 | 12 | 2026-07-25 21:42:42 | 2026-07-31 23:58:54 |
| yellow | 2026-02 | 2026-01 | 12 | 2026-01-31 23:31:23 | 2026-01-31 23:59:47 |
| green | 2026-06 | 2026-05 | 12 | 2026-05-26 19:47:06 | 2026-05-31 23:57:01 |
| yellow | 2026-05 | 2026-04 | 11 | 2026-04-30 23:47:18 | 2026-04-30 23:59:17 |
| green | 2026-02 | 2026-01 | 8 | 2026-01-26 23:38:06 | 2026-01-31 22:44:43 |
| green | 2026-03 | 2026-02 | 8 | 2026-02-25 20:13:58 | 2026-02-28 23:59:36 |
| green | 2026-05 | 2026-04 | 8 | 2026-04-24 22:00:18 | 2026-04-30 23:54:33 |
| yellow | 2026-04 | 2026-03 | 7 | 2026-03-31 23:50:54 | 2026-03-31 23:59:10 |
| yellow | 2026-07 | 2026-06 | 7 | 2026-06-30 23:39:59 | 2026-06-30 23:59:58 |
| yellow | 2026-01 | 2025-12 | 6 | 2025-12-31 23:57:29 | 2025-12-31 23:59:06 |
| green | 2026-07 | 2026-06 | 6 | 2026-06-24 21:30:14 | 2026-06-27 20:55:00 |
| green | 2026-07 | 2026-08 | 5 | 2026-08-01 00:03:21 | 2026-08-01 14:36:42 |
| yellow | 2026-02 | 2026-03 | 4 | 2026-03-01 00:00:37 | 2026-03-01 00:51:48 |
| green | 2026-01 | 2025-12 | 4 | 2025-12-27 16:49:41 | 2025-12-31 22:00:16 |
| green | 2026-02 | 2026-03 | 3 | 2026-03-01 00:04:03 | 2026-03-01 09:48:53 |
| yellow | 2026-04 | 2009-01 | 3 | 2009-01-01 00:02:29 | 2009-01-01 11:15:15 |
| green | 2026-07 | 2009-01 | 3 | 2009-01-01 00:07:09 | 2009-01-01 01:30:56 |
| green | 2026-05 | 2008-12 | 2 | 2008-12-31 23:05:50 | 2008-12-31 23:12:44 |
| green | 2026-04 | 2026-05 | 2 | 2026-05-01 07:32:15 | 2026-05-01 07:53:18 |
| green | 2026-07 | 2008-12 | 2 | 2008-12-31 17:35:31 | 2008-12-31 23:07:59 |
| yellow | 2026-03 | 2026-04 | 2 | 2026-04-01 00:00:16 | 2026-04-01 00:06:25 |
| yellow | 2026-08 | 2009-01 | 1 | 2009-01-01 14:39:49 | 2009-01-01 14:39:49 |
| yellow | 2026-04 | 2001-01 | 1 | 2001-01-01 09:23:58 | 2001-01-01 09:23:58 |
| green | 2026-03 | 2009-01 | 1 | 2009-01-01 01:35:31 | 2009-01-01 01:35:31 |
| green | 2026-08 | 2008-12 | 1 | 2008-12-31 23:06:23 | 2008-12-31 23:06:23 |

---

## 3.6e - Valores de las columnas categoricas codificadas

**Objetivo:** Comparar los codigos presentes (VendorID, RatecodeID, payment_type, store_and_fwd_flag) contra el diccionario de datos de la TLC para detectar codigos no documentados y nulos.  
**Fuente:** data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet  
**Archivo:** `sql/ejercicio3/3_14_codigos_categoricos.sql`  
**Tiempo de ejecucion:** 4.420 s - **filas del resultado:** 40

```sql
-- @id: 3.6e
-- @titulo: Valores de las columnas categoricas codificadas
-- @objetivo: Comparar los codigos presentes (VendorID, RatecodeID, payment_type,
--   store_and_fwd_flag) contra el diccionario de datos de la TLC para detectar
--   codigos no documentados y nulos.
-- @fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet
WITH t AS (
    SELECT 'yellow' AS tipo, VendorID, RatecodeID, payment_type, store_and_fwd_flag
    FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)
    UNION ALL
    SELECT 'green', VendorID, RatecodeID, payment_type, store_and_fwd_flag
    FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true)
)
SELECT tipo, 'VendorID' AS columna, CAST(VendorID AS VARCHAR) AS valor, count(*) AS registros FROM t GROUP BY ALL
UNION ALL
SELECT tipo, 'RatecodeID', CAST(RatecodeID AS VARCHAR), count(*) FROM t GROUP BY ALL
UNION ALL
SELECT tipo, 'payment_type', CAST(payment_type AS VARCHAR), count(*) FROM t GROUP BY ALL
UNION ALL
SELECT tipo, 'store_and_fwd_flag', store_and_fwd_flag, count(*) FROM t GROUP BY ALL
ORDER BY tipo DESC, columna, valor NULLS LAST;
```

**Resultado:**

| tipo | columna | valor | registros |
|---|---|---|---|
| yellow | RatecodeID | 1 | 20,102,072 |
| yellow | RatecodeID | 2 | 694,936 |
| yellow | RatecodeID | 3 | 90,052 |
| yellow | RatecodeID | 4 | 67,285 |
| yellow | RatecodeID | 5 | 262,614 |
| yellow | RatecodeID | 6 | 15 |
| yellow | RatecodeID | 99 | 769,693 |
| yellow | RatecodeID | NULL | 7,716,688 |
| yellow | VendorID | 1 | 5,467,071 |
| yellow | VendorID | 2 | 23,809,774 |
| yellow | VendorID | 6 | 59,390 |
| yellow | VendorID | 7 | 367,120 |
| yellow | payment_type | 0 | 7,716,688 |
| yellow | payment_type | 1 | 18,941,008 |
| yellow | payment_type | 2 | 2,708,031 |
| yellow | payment_type | 3 | 98,138 |
| yellow | payment_type | 4 | 239,488 |
| yellow | payment_type | 5 | 2 |
| yellow | store_and_fwd_flag | N | 21,952,339 |
| yellow | store_and_fwd_flag | Y | 34,328 |
| yellow | store_and_fwd_flag | NULL | 7,716,688 |
| green | RatecodeID | 1 | 269,152 |
| green | RatecodeID | 2 | 887 |
| green | RatecodeID | 3 | 203 |
| green | RatecodeID | 4 | 354 |
| green | RatecodeID | 5 | 17,739 |
| green | RatecodeID | 6 | 2 |
| green | RatecodeID | 99 | 2 |
| green | RatecodeID | NULL | 48,775 |
| green | VendorID | 1 | 28,696 |
| green | VendorID | 2 | 273,571 |
| green | VendorID | 6 | 34,847 |
| green | payment_type | 1 | 219,980 |
| green | payment_type | 2 | 65,921 |
| green | payment_type | 3 | 1,688 |
| green | payment_type | 4 | 750 |
| green | payment_type | NULL | 48,775 |
| green | store_and_fwd_flag | N | 287,873 |
| green | store_and_fwd_flag | Y | 466 |
| green | store_and_fwd_flag | NULL | 48,775 |

---

## 3.6f - Consistencia entre total_amount y la suma de sus componentes

**Objetivo:** Verificar si total_amount es igual a la suma de tarifa, recargos, impuestos, propina y peajes. Diferencias grandes indican registros inconsistentes o componentes que no estan en el archivo.  
**Fuente:** data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet  
**Archivo:** `sql/ejercicio3/3_15_consistencia_montos.sql`  
**Tiempo de ejecucion:** 3.048 s - **filas del resultado:** 2

```sql
-- @id: 3.6f
-- @titulo: Consistencia entre total_amount y la suma de sus componentes
-- @objetivo: Verificar si total_amount es igual a la suma de tarifa, recargos,
--   impuestos, propina y peajes. Diferencias grandes indican registros
--   inconsistentes o componentes que no estan en el archivo.
-- @fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet
WITH t AS (
    SELECT 'yellow' AS tipo, total_amount,
           coalesce(fare_amount,0) + coalesce(extra,0) + coalesce(mta_tax,0)
         + coalesce(tip_amount,0) + coalesce(tolls_amount,0)
         + coalesce(improvement_surcharge,0) + coalesce(congestion_surcharge,0)
         + coalesce(Airport_fee,0) + coalesce(cbd_congestion_fee,0) AS suma
    FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)
    UNION ALL
    SELECT 'green', total_amount,
           coalesce(fare_amount,0) + coalesce(extra,0) + coalesce(mta_tax,0)
         + coalesce(tip_amount,0) + coalesce(tolls_amount,0)
         + coalesce(improvement_surcharge,0) + coalesce(congestion_surcharge,0)
         + coalesce(ehail_fee,0) + coalesce(cbd_congestion_fee,0)
    FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true)
)
SELECT
    tipo,
    count(*)                                                    AS registros,
    count(*) FILTER (WHERE abs(total_amount - suma) <= 0.01)    AS coincide,
    count(*) FILTER (WHERE abs(total_amount - suma) > 0.01)     AS no_coincide,
    round(100.0 * count(*) FILTER (WHERE abs(total_amount - suma) > 0.01) / count(*), 3) AS pct_no_coincide,
    round(median(total_amount - suma) FILTER (WHERE abs(total_amount - suma) > 0.01), 2) AS mediana_diferencia
FROM t
GROUP BY tipo
ORDER BY tipo DESC;
```

**Resultado:**

| tipo | registros | coincide | no_coincide | pct_no_coincide | mediana_diferencia |
|---|---|---|---|---|---|
| yellow | 29,703,355 | 18,807,599 | 10,895,756 | 36.682 | 2.5 |
| green | 337,114 | 270,144 | 66,970 | 19.866 | 12.2 |

---

## 3.6g - Posibles registros duplicados

**Objetivo:** Contar viajes repetidos con el mismo proveedor, hora de pickup y dropoff, zonas y monto total (un mismo viaje cargado dos veces).  
**Fuente:** data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet  
**Archivo:** `sql/ejercicio3/3_16_duplicados.sql`  
**Tiempo de ejecucion:** 6.497 s - **filas del resultado:** 2

```sql
-- @id: 3.6g
-- @titulo: Posibles registros duplicados
-- @objetivo: Contar viajes repetidos con el mismo proveedor, hora de pickup y
--   dropoff, zonas y monto total (un mismo viaje cargado dos veces).
-- @fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet
WITH t AS (
    SELECT 'yellow' AS tipo, VendorID, tpep_pickup_datetime AS pu, tpep_dropoff_datetime AS dof,
           PULocationID, DOLocationID, total_amount
    FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)
    UNION ALL
    SELECT 'green', VendorID, lpep_pickup_datetime, lpep_dropoff_datetime,
           PULocationID, DOLocationID, total_amount
    FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true)
), g AS (
    SELECT tipo, count(*) AS n
    FROM t
    GROUP BY tipo, VendorID, pu, dof, PULocationID, DOLocationID, total_amount
)
SELECT tipo,
       sum(n)                       AS registros,
       count(*)                     AS combinaciones_unicas,
       sum(n) - count(*)            AS registros_duplicados
FROM g GROUP BY tipo ORDER BY tipo DESC;
```

**Resultado:**

| tipo | registros | combinaciones_unicas | registros_duplicados |
|---|---|---|---|
| yellow | 29,703,355 | 29,670,561 | 32,794 |
| green | 337,114 | 337,114 | 0 |

---

## 3.6h - Desglose de la inconsistencia de montos por metodo de pago y proveedor

**Objetivo:** Explicar de donde viene la diferencia entre total_amount y la suma de sus componentes detectada en 3.6f (36.7 % en amarillos, 19.9 % en verdes). Si la diferencia se concentra en un metodo de pago o proveedor y tiene un valor fijo, es un patron de registro y no un error aleatorio. Tambien muestra en que proveedor se concentra RatecodeID = 99.  
**Fuente:** data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet  
**Archivo:** `sql/ejercicio3/3_17_desglose_inconsistencia_montos.sql`  
**Tiempo de ejecucion:** 4.042 s - **filas del resultado:** 27

```sql
-- @id: 3.6h
-- @titulo: Desglose de la inconsistencia de montos por metodo de pago y proveedor
-- @objetivo: Explicar de donde viene la diferencia entre total_amount y la suma
--   de sus componentes detectada en 3.6f (36.7 % en amarillos, 19.9 % en
--   verdes). Si la diferencia se concentra en un metodo de pago o proveedor y
--   tiene un valor fijo, es un patron de registro y no un error aleatorio.
--   Tambien muestra en que proveedor se concentra RatecodeID = 99.
-- @fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet
WITH t AS (
    SELECT 'yellow' AS tipo, VendorID, payment_type, RatecodeID, total_amount,
           coalesce(fare_amount,0) + coalesce(extra,0) + coalesce(mta_tax,0)
         + coalesce(tip_amount,0) + coalesce(tolls_amount,0)
         + coalesce(improvement_surcharge,0) + coalesce(congestion_surcharge,0)
         + coalesce(Airport_fee,0) + coalesce(cbd_congestion_fee,0) AS suma
    FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)
    UNION ALL
    SELECT 'green', VendorID, payment_type, RatecodeID, total_amount,
           coalesce(fare_amount,0) + coalesce(extra,0) + coalesce(mta_tax,0)
         + coalesce(tip_amount,0) + coalesce(tolls_amount,0)
         + coalesce(improvement_surcharge,0) + coalesce(congestion_surcharge,0)
         + coalesce(ehail_fee,0) + coalesce(cbd_congestion_fee,0)
    FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true)
), d AS (
    SELECT *, round(total_amount - suma, 2) AS dif FROM t
)
SELECT
    tipo,
    coalesce(CAST(payment_type AS VARCHAR), 'NULL')                 AS payment_type,
    VendorID                                                        AS vendor_id,
    count(*)                                                        AS registros,
    count(*) FILTER (WHERE abs(dif) > 0.01)                         AS no_coincide,
    round(100.0 * count(*) FILTER (WHERE abs(dif) > 0.01) / count(*), 2) AS pct_no_coincide,
    mode(dif) FILTER (WHERE abs(dif) > 0.01)                        AS diferencia_mas_comun,
    count(*) FILTER (WHERE RatecodeID = 99)                         AS ratecode_99
FROM d
GROUP BY ALL
ORDER BY tipo DESC, registros DESC;
```

**Resultado:**

| tipo | payment_type | vendor_id | registros | no_coincide | pct_no_coincide | diferencia_mas_comun | ratecode_99 |
|---|---|---|---|---|---|---|---|
| yellow | 1 | 2 | 14,592,874 | 16,620 | 0.11 | 2.5 | 533 |
| yellow | 0 | 2 | 6,761,917 | 5,963,133 | 88.19 | 2.5 | 0 |
| yellow | 1 | 1 | 4,028,246 | 3,315,691 | 82.31 | -3.25 | 766,522 |
| yellow | 2 | 2 | 2,217,837 | 5,381 | 0.24 | 2.5 | 25 |
| yellow | 0 | 1 | 895,381 | 881,364 | 98.43 | 2.5 | 0 |
| yellow | 2 | 1 | 447,521 | 416,904 | 93.16 | -3.25 | 47 |
| yellow | 1 | 7 | 319,888 | 139,226 | 43.52 | 1 | 0 |
| yellow | 4 | 2 | 201,691 | 416 | 0.21 | -2.5 | 0 |
| yellow | 3 | 1 | 59,767 | 50,793 | 84.99 | -3.25 | 202 |
| yellow | 0 | 6 | 59,390 | 59,389 | 100 | 12.2 | 0 |
| yellow | 2 | 7 | 42,673 | 16,170 | 37.89 | 1 | 0 |
| yellow | 4 | 1 | 36,154 | 28,447 | 78.68 | -3.25 | 2,361 |
| yellow | 3 | 2 | 35,455 | 70 | 0.2 | -2.5 | 2 |
| yellow | 3 | 7 | 2,916 | 1,126 | 38.61 | 1 | 0 |
| yellow | 4 | 7 | 1,643 | 748 | 45.53 | 1 | 0 |
| yellow | 5 | 1 | 2 | 0 | 0 | NULL | 1 |
| green | 1 | 2 | 198,078 | 67 | 0.03 | 2.5 | 0 |
| green | 2 | 2 | 60,407 | 39 | 0.06 | 2.5 | 0 |
| green | NULL | 6 | 34,847 | 34,847 | 100 | 12.2 | 0 |
| green | 1 | 1 | 21,902 | 21,381 | 97.62 | -1 | 2 |
| green | NULL | 2 | 13,400 | 4,345 | 32.43 | 2.75 | 0 |
| green | 2 | 1 | 5,514 | 5,391 | 97.77 | -1 | 0 |
| green | 3 | 2 | 1,128 | 0 | 0 | NULL | 0 |
| green | 3 | 1 | 560 | 447 | 79.82 | -1 | 0 |
| green | 4 | 2 | 558 | 0 | 0 | NULL | 0 |
| green | NULL | 1 | 528 | 339 | 64.2 | 2.75 | 0 |
| green | 4 | 1 | 192 | 114 | 59.38 | -1 | 0 |

---

## 3.6i - Columna request_source (no documentada) por mes y metodo de pago

**Objetivo:** request_source aparece solo en algunos archivos de 2026 y no esta en el diccionario de datos de la TLC (version de marzo de 2025). Se revisa en que meses existe, que valores toma y si coincide con los viajes Flex Fare (payment_type = 0) o sin metodo de pago (NULL).  
**Fuente:** data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet  
**Archivo:** `sql/ejercicio3/3_18_request_source.sql`  
**Tiempo de ejecucion:** 0.426 s - **filas del resultado:** 16

```sql
-- @id: 3.6i
-- @titulo: Columna request_source (no documentada) por mes y metodo de pago
-- @objetivo: request_source aparece solo en algunos archivos de 2026 y no esta
--   en el diccionario de datos de la TLC (version de marzo de 2025). Se revisa
--   en que meses existe, que valores toma y si coincide con los viajes Flex
--   Fare (payment_type = 0) o sin metodo de pago (NULL).
-- @fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet
WITH t AS (
    SELECT 'yellow' AS tipo, filename, request_source, payment_type
    FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true, filename = true)
    UNION ALL
    SELECT 'green', filename, request_source, payment_type
    FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true, filename = true)
)
SELECT
    tipo,
    regexp_extract(filename, '_(\d{4}-\d{2})\.parquet$', 1)         AS periodo,
    count(*)                                                        AS registros,
    count(request_source)                                           AS con_request_source,
    count(*) FILTER (WHERE payment_type = 0 OR payment_type IS NULL) AS pago_0_o_nulo,
    count(*) FILTER (WHERE request_source IS NOT NULL
                       AND (payment_type = 0 OR payment_type IS NULL)) AS ambos,
    string_agg(DISTINCT request_source, ', ')                       AS valores
FROM t
GROUP BY 1, 2
ORDER BY tipo DESC, periodo;
```

**Resultado:**

| tipo | periodo | registros | con_request_source | pago_0_o_nulo | ambos | valores |
|---|---|---|---|---|---|---|
| yellow | 2026-01 | 3,724,889 | 0 | 1,088,058 | 0 | NULL |
| yellow | 2026-02 | 3,399,866 | 0 | 1,023,317 | 0 | NULL |
| yellow | 2026-03 | 3,952,451 | 0 | 945,748 | 0 | NULL |
| yellow | 2026-04 | 3,831,240 | 0 | 799,786 | 0 | NULL |
| yellow | 2026-05 | 4,090,836 | 0 | 955,371 | 0 | NULL |
| yellow | 2026-06 | 3,837,248 | 1,013,180 | 1,013,500 | 1,013,180 | HV0003, EH0004, A, CC |
| yellow | 2026-07 | 3,530,109 | 969,417 | 969,727 | 969,417 | HV0003, A, EH0004, EH0010, CC |
| yellow | 2026-08 | 3,336,716 | 920,849 | 921,181 | 920,849 | HV0005, CC, HV0003, A, EH0004, EH0010 |
| green | 2026-01 | 40,272 | 0 | 5,414 | 0 | NULL |
| green | 2026-02 | 37,373 | 0 | 5,387 | 0 | NULL |
| green | 2026-03 | 44,208 | 0 | 6,692 | 0 | NULL |
| green | 2026-04 | 44,238 | 0 | 6,290 | 0 | NULL |
| green | 2026-05 | 44,921 | 0 | 5,772 | 0 | NULL |
| green | 2026-06 | 44,163 | 6,471 | 6,472 | 6,471 | A |
| green | 2026-07 | 41,252 | 6,430 | 6,435 | 6,430 | A, CC |
| green | 2026-08 | 40,687 | 6,310 | 6,313 | 6,310 | CC, HV0005, A |
