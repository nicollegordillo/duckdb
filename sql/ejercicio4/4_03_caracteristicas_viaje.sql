-- @id: P3
-- @titulo: Distribucion de distancia, duracion, velocidad y monto
-- @pregunta: Como es un viaje tipico (distancia, duracion, velocidad, costo) y
--   en que se diferencian los viajes de taxis amarillos y verdes?
-- @justificacion: Estas variables son muy asimetricas (muchos viajes cortos y
--   pocos muy largos), por lo que se reportan percentiles ademas del promedio:
--   si el promedio esta muy por encima de la mediana, la cola derecha pesa.
-- Nota: las estadisticas se calculan en una sola lectura de viajes_validos
--   y solo el resultado (8 filas) se reorganiza en formato largo; expandir
--   primero los 30 millones de filas x 4 variables agotaba la memoria.
--   Se usa approx_quantile (algoritmo T-Digest) en lugar de median /
--   quantile_cont. El calculo exacto necesita guardar en memoria todos los
--   valores (~30 millones por variable) y se quedo sin memoria en el
--   contenedor; approx_quantile usa memoria constante con un error minimo,
--   despreciable para describir distribuciones.
-- @fuente: vista viajes_validos
WITH stats AS (
    SELECT
        taxi,
        approx_quantile(trip_distance, [0.10, 0.25, 0.50, 0.75, 0.90, 0.99]) AS q_dist,
        avg(trip_distance)  AS avg_dist,  max(trip_distance)  AS max_dist,
        approx_quantile(duracion_min,  [0.10, 0.25, 0.50, 0.75, 0.90, 0.99]) AS q_dur,
        avg(duracion_min)   AS avg_dur,   max(duracion_min)   AS max_dur,
        approx_quantile(velocidad_mph, [0.10, 0.25, 0.50, 0.75, 0.90, 0.99]) AS q_vel,
        avg(velocidad_mph)  AS avg_vel,   max(velocidad_mph)  AS max_vel,
        approx_quantile(total_amount,  [0.10, 0.25, 0.50, 0.75, 0.90, 0.99]) AS q_tot,
        avg(total_amount)   AS avg_tot,   max(total_amount)   AS max_tot
    FROM viajes_validos
    GROUP BY taxi
), largo AS (
    SELECT taxi, 'distancia_mi'  AS variable, q_dist AS q, avg_dist AS promedio, max_dist AS maximo FROM stats
    UNION ALL SELECT taxi, 'duracion_min',  q_dur, avg_dur, max_dur FROM stats
    UNION ALL SELECT taxi, 'velocidad_mph', q_vel, avg_vel, max_vel FROM stats
    UNION ALL SELECT taxi, 'total_usd',     q_tot, avg_tot, max_tot FROM stats
)
SELECT
    variable,
    taxi,
    round(q[1], 2)        AS p10,
    round(q[2], 2)        AS p25,
    round(q[3], 2)        AS mediana,
    round(promedio, 2)    AS promedio,
    round(q[4], 2)        AS p75,
    round(q[5], 2)        AS p90,
    round(q[6], 2)        AS p99,
    round(maximo, 2)      AS maximo
FROM largo
ORDER BY variable, taxi DESC;
