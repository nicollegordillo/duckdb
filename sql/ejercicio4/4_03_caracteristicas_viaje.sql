-- @id: P3
-- @titulo: Distribucion de distancia, duracion, velocidad y monto
-- @pregunta: Como es un viaje tipico (distancia, duracion, velocidad, costo) y
--   en que se diferencian los viajes de taxis amarillos y verdes?
-- @justificacion: Estas variables son muy asimetricas (muchos viajes cortos y
--   pocos muy largos), por lo que se reportan percentiles ademas del promedio:
--   si el promedio esta muy por encima de la mediana, la cola derecha pesa.
-- @fuente: vista viajes_validos
WITH largo AS (
    UNPIVOT (
        SELECT taxi,
               trip_distance AS distancia_mi,
               duracion_min,
               velocidad_mph,
               total_amount  AS total_usd
        FROM viajes_validos
    )
    ON distancia_mi, duracion_min, velocidad_mph, total_usd
    INTO NAME variable VALUE valor
)
SELECT
    variable,
    taxi,
    round(quantile_cont(valor, 0.10), 2) AS p10,
    round(quantile_cont(valor, 0.25), 2) AS p25,
    round(quantile_cont(valor, 0.50), 2) AS mediana,
    round(avg(valor), 2)                 AS promedio,
    round(quantile_cont(valor, 0.75), 2) AS p75,
    round(quantile_cont(valor, 0.90), 2) AS p90,
    round(quantile_cont(valor, 0.99), 2) AS p99,
    round(max(valor), 2)                 AS maximo
FROM largo
GROUP BY variable, taxi
ORDER BY variable, taxi DESC;
