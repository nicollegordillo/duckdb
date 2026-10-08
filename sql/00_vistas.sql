-- =============================================================================
-- Capa de ORIGEN: vistas sobre los archivos Parquet
-- =============================================================================
-- Una VISTA no copia ni importa datos: guarda la definicion de la consulta y
-- DuckDB lee los Parquet en el momento en que se consulta. Por eso:
--   * agregar un archivo nuevo en data/raw/<tipo>/<anio>/ lo incluye
--     automaticamente (el patron * cubre cualquier anio);
--   * los analisis consultan `viajes` / `viajes_validos` y no dependen de las
--     rutas de los archivos.
--
-- union_by_name = true: alinea columnas por nombre y no por posicion. Es
-- necesario porque los archivos de distintos anios no tienen exactamente las
-- mismas columnas (p. ej. cbd_congestion_fee existe desde 2025).
-- filename = true: agrega la ruta de origen de cada fila, que se usa para saber
-- a que archivo (anio-mes) pertenece cada registro.
--
-- Este archivo define solo el ORIGEN de los datos (yellow_raw, green_raw y el
-- esquema unificado `viajes`). Las columnas derivadas y los filtros de calidad
-- estan en sql/02_vistas_analisis.sql, que solo depende de `viajes`. Asi, en el
-- Ejercicio 6 `viajes` puede ser una tabla materializada en lugar de esta vista
-- y las consultas de analisis no cambian.
--
-- Archivos leidos (Ejercicios 5 y 6): por defecto todos los anios descargados.
-- Un script puede restringirlos sin editar este archivo:
--     SET VARIABLE archivos_yellow = ['data/raw/yellow/2026/*.parquet'];
--     SET VARIABLE archivos_green  = ['data/raw/green/2026/*.parquet'];
-- (scripts/lab.py lo hace con conectar(anios=[2026]) o LAB8_ANIOS=2026).
-- getvariable() se evalua cada vez que se consulta la vista.
--
-- Columnas opcionales (Ejercicio 5): cbd_congestion_fee no existe en 2024 y
-- request_source solo aparece desde junio de 2026. Con todos los anios,
-- union_by_name las trae de los archivos que si las tienen, pero si se leen
-- solo archivos que no las traen, `viajes` fallaria. El UNION ALL BY NAME con
-- una fila vacia (WHERE false) garantiza que existan (NULL donde el archivo no
-- las trae). El optimizador elimina esa rama vacia: la proyeccion de columnas y
-- los filtros se siguen aplicando dentro de la lectura del Parquet.
-- =============================================================================

CREATE OR REPLACE VIEW yellow_raw AS
SELECT * FROM read_parquet(coalesce(getvariable('archivos_yellow'),
                                    ['data/raw/yellow/*/*.parquet']),
                           union_by_name = true, filename = true)
UNION ALL BY NAME
SELECT NULL::DOUBLE AS cbd_congestion_fee, NULL::VARCHAR AS request_source
WHERE false;

CREATE OR REPLACE VIEW green_raw AS
SELECT * FROM read_parquet(coalesce(getvariable('archivos_green'),
                                    ['data/raw/green/*/*.parquet']),
                           union_by_name = true, filename = true)
UNION ALL BY NAME
SELECT NULL::DOUBLE AS cbd_congestion_fee, NULL::VARCHAR AS request_source
WHERE false;

-- -----------------------------------------------------------------------------
-- viajes: esquema unificado de amarillos y verdes.
-- Transformaciones aplicadas (solo de forma, no se elimina ninguna fila):
--   * tpep_/lpep_ -> pickup_at / dropoff_at (los nombres difieren por tipo)
--   * nombres en snake_case y tipos enteros homogeneos (TRY_CAST)
--   * columnas exclusivas de un tipo quedan NULL en el otro
--     (airport_fee solo amarillos; trip_type solo verdes; ehail_fee se
--     descarta porque esta vacia)
--   * anio_archivo / mes_archivo se extraen del nombre del archivo
--   * request_source: columna no documentada que aparece desde junio de 2026
--     (Ejercicio 3, consulta 3.6i); queda NULL en los archivos que no la traen
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW viajes AS
SELECT
    'yellow'                                                AS taxi,
    TRY_CAST(regexp_extract(filename, '_(\d{4})-\d{2}\.parquet$', 1) AS INTEGER) AS anio_archivo,
    TRY_CAST(regexp_extract(filename, '_\d{4}-(\d{2})\.parquet$', 1) AS INTEGER) AS mes_archivo,
    TRY_CAST(VendorID AS INTEGER)                           AS vendor_id,
    tpep_pickup_datetime                                    AS pickup_at,
    tpep_dropoff_datetime                                   AS dropoff_at,
    TRY_CAST(passenger_count AS INTEGER)                    AS passenger_count,
    trip_distance,
    TRY_CAST(RatecodeID AS INTEGER)                         AS ratecode_id,
    store_and_fwd_flag,
    TRY_CAST(PULocationID AS INTEGER)                       AS pu_location_id,
    TRY_CAST(DOLocationID AS INTEGER)                       AS do_location_id,
    TRY_CAST(payment_type AS INTEGER)                       AS payment_type,
    fare_amount, extra, mta_tax, tip_amount, tolls_amount,
    improvement_surcharge, total_amount, congestion_surcharge,
    Airport_fee                                             AS airport_fee,
    cbd_congestion_fee,
    CAST(NULL AS INTEGER)                                   AS trip_type,
    TRY_CAST(request_source AS VARCHAR)                     AS request_source,
    filename                                                AS archivo
FROM yellow_raw
UNION ALL BY NAME
SELECT
    'green'                                                 AS taxi,
    TRY_CAST(regexp_extract(filename, '_(\d{4})-\d{2}\.parquet$', 1) AS INTEGER) AS anio_archivo,
    TRY_CAST(regexp_extract(filename, '_\d{4}-(\d{2})\.parquet$', 1) AS INTEGER) AS mes_archivo,
    TRY_CAST(VendorID AS INTEGER)                           AS vendor_id,
    lpep_pickup_datetime                                    AS pickup_at,
    lpep_dropoff_datetime                                   AS dropoff_at,
    TRY_CAST(passenger_count AS INTEGER)                    AS passenger_count,
    trip_distance,
    TRY_CAST(RatecodeID AS INTEGER)                         AS ratecode_id,
    store_and_fwd_flag,
    TRY_CAST(PULocationID AS INTEGER)                       AS pu_location_id,
    TRY_CAST(DOLocationID AS INTEGER)                       AS do_location_id,
    TRY_CAST(payment_type AS INTEGER)                       AS payment_type,
    fare_amount, extra, mta_tax, tip_amount, tolls_amount,
    improvement_surcharge, total_amount, congestion_surcharge,
    CAST(NULL AS DOUBLE)                                    AS airport_fee,
    cbd_congestion_fee,
    TRY_CAST(trip_type AS INTEGER)                          AS trip_type,
    TRY_CAST(request_source AS VARCHAR)                     AS request_source,
    filename                                                AS archivo
FROM green_raw;
