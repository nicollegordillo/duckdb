-- =============================================================================
-- Vistas base sobre los archivos Parquet
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
-- =============================================================================

CREATE OR REPLACE VIEW yellow_raw AS
SELECT * FROM read_parquet('data/raw/yellow/*/*.parquet',
                           union_by_name = true, filename = true);

CREATE OR REPLACE VIEW green_raw AS
SELECT * FROM read_parquet('data/raw/green/*/*.parquet',
                           union_by_name = true, filename = true);

-- -----------------------------------------------------------------------------
-- viajes: esquema unificado de amarillos y verdes.
-- Transformaciones aplicadas (solo de forma, no se elimina ninguna fila):
--   * tpep_/lpep_ -> pickup_at / dropoff_at (los nombres difieren por tipo)
--   * nombres en snake_case y tipos enteros homogeneos (TRY_CAST)
--   * columnas exclusivas de un tipo quedan NULL en el otro
--     (airport_fee solo amarillos; trip_type solo verdes; ehail_fee se
--     descarta porque esta vacia)
--   * anio_archivo / mes_archivo se extraen del nombre del archivo
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
    filename                                                AS archivo
FROM green_raw;

-- -----------------------------------------------------------------------------
-- viajes_enriquecidos: columnas derivadas + banderas de calidad.
-- Las banderas NO eliminan filas; solo marcan problemas detectados en el
-- Ejercicio 3 para poder cuantificarlos (ver sql/ejercicio4/4_08_*.sql).
-- Umbrales elegidos (revisar con los resultados reales del Ejercicio 3):
--   f_fuera_periodo : el pickup no cae en el mes que indica el archivo
--   f_duracion      : duracion <= 0 min o > 6 horas
--   f_distancia     : distancia <= 0 o > 100 millas
--   f_velocidad     : velocidad promedio > 80 mph (imposible en la ciudad)
--   f_monto         : tarifa base <= 0 o total <= 0 (reembolsos/anulaciones)
--   f_pasajeros     : passenger_count = 0
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW viajes_enriquecidos AS
WITH base AS (
    SELECT
        *,
        date_diff('second', pickup_at, dropoff_at) / 60.0       AS duracion_min,
        CAST(pickup_at AS DATE)                                  AS fecha,
        hour(pickup_at)                                          AS hora,
        isodow(pickup_at)                                        AS dia_semana,  -- 1 = lunes
        CASE payment_type
            WHEN 0 THEN 'Flex fare' WHEN 1 THEN 'Tarjeta'  WHEN 2 THEN 'Efectivo'
            WHEN 3 THEN 'Sin cargo' WHEN 4 THEN 'Disputa'  WHEN 5 THEN 'Desconocido'
            WHEN 6 THEN 'Anulado'   ELSE 'Otro/NULL' END             AS metodo_pago
    FROM viajes
)
SELECT
    *,
    trip_distance / nullif(duracion_min / 60.0, 0)               AS velocidad_mph,
    tip_amount / nullif(fare_amount, 0)                          AS pct_propina,
    coalesce(date_trunc('month', pickup_at)
             <> make_date(anio_archivo, mes_archivo, 1), true)   AS f_fuera_periodo,
    coalesce(duracion_min <= 0 OR duracion_min > 360, true)      AS f_duracion,
    coalesce(trip_distance <= 0 OR trip_distance > 100, true)    AS f_distancia,
    coalesce(trip_distance / nullif(duracion_min / 60.0, 0) > 80, false) AS f_velocidad,
    coalesce(fare_amount <= 0 OR total_amount <= 0, true)        AS f_monto,
    coalesce(passenger_count = 0, false)                         AS f_pasajeros
FROM base;

-- -----------------------------------------------------------------------------
-- viajes_validos: subconjunto usado en el analisis exploratorio.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW viajes_validos AS
SELECT * FROM viajes_enriquecidos
WHERE NOT (f_fuera_periodo OR f_duracion OR f_distancia
           OR f_velocidad OR f_monto OR f_pasajeros);
