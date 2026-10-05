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
