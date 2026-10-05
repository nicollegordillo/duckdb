-- @id: P10
-- @titulo: Valores atipicos de costo por milla (regla de Tukey / IQR)
-- @pregunta: Entre los viajes que pasan los filtros basicos, cuantos tienen un
--   costo por milla atipico y como son esos viajes?
-- @justificacion: Los filtros de P9 solo eliminan valores imposibles. La regla
--   IQR (fuera de Q1 - 1.5*IQR, Q3 + 1.5*IQR) detecta valores posibles pero
--   inusuales; el costo por milla combina tarifa y distancia, asi que capta
--   viajes con distancia mal registrada o tarifas fijas.
-- @fuente: vista viajes_validos
WITH base AS (
    SELECT taxi, fare_amount / trip_distance AS usd_milla, trip_distance, fare_amount, ratecode_id
    FROM viajes_validos
), limites AS (
    SELECT taxi,
           quantile_cont(usd_milla, 0.25) AS q1,
           quantile_cont(usd_milla, 0.75) AS q3
    FROM base GROUP BY taxi
)
SELECT
    b.taxi,
    round(any_value(l.q1), 2)                                       AS q1,
    round(any_value(l.q3), 2)                                       AS q3,
    round(any_value(l.q1 - 1.5 * (l.q3 - l.q1)), 2)                 AS limite_inf,
    round(any_value(l.q3 + 1.5 * (l.q3 - l.q1)), 2)                 AS limite_sup,
    count(*)                                                        AS viajes,
    count(*) FILTER (WHERE b.usd_milla > l.q3 + 1.5 * (l.q3 - l.q1)) AS atipicos_altos,
    count(*) FILTER (WHERE b.usd_milla < l.q1 - 1.5 * (l.q3 - l.q1)) AS atipicos_bajos,
    round(median(b.trip_distance) FILTER (WHERE b.usd_milla > l.q3 + 1.5 * (l.q3 - l.q1)), 2)
                                                                    AS distancia_mediana_atipicos_altos,
    round(100.0 * avg((b.ratecode_id <> 1)::INT) FILTER (WHERE b.usd_milla > l.q3 + 1.5 * (l.q3 - l.q1)), 1)
                                                                    AS pct_tarifa_especial_en_altos
FROM base b JOIN limites l USING (taxi)
GROUP BY b.taxi
ORDER BY viajes DESC;
