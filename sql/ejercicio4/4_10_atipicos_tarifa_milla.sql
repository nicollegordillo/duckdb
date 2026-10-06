-- @id: P10
-- @titulo: Valores atipicos de costo por milla (regla de Tukey / IQR)
-- @pregunta: Entre los viajes que pasan los filtros basicos, cuantos tienen un
--   costo por milla atipico y como son esos viajes?
-- @justificacion: Los filtros de P9 solo eliminan valores imposibles. La regla
--   IQR (fuera de Q1 - 1.5*IQR, Q3 + 1.5*IQR) detecta valores posibles pero
--   inusuales; el costo por milla combina tarifa y distancia, asi que capta
--   viajes con distancia mal registrada o tarifas fijas.
-- Nota: se lee viajes_validos dos veces (limites y conteo) en lugar de
--   guardar una CTE intermedia con los 30 millones de viajes, que DuckDB
--   materializaba en memoria por usarse dos veces.
--   Se usa approx_quantile (algoritmo T-Digest) en lugar de median /
--   quantile_cont. El calculo exacto necesita guardar en memoria todos los
--   valores (~30 millones por variable) y se quedo sin memoria en el
--   contenedor; approx_quantile usa memoria constante con un error minimo,
--   despreciable para describir distribuciones.
-- @fuente: vista viajes_validos
WITH limites AS (
    SELECT
        taxi,
        approx_quantile(fare_amount / trip_distance, 0.25) AS q1,
        approx_quantile(fare_amount / trip_distance, 0.75) AS q3
    FROM viajes_validos
    GROUP BY taxi
), lim AS (
    SELECT taxi, q1, q3,
           q1 - 1.5 * (q3 - q1) AS limite_inf,
           q3 + 1.5 * (q3 - q1) AS limite_sup
    FROM limites
)
SELECT
    v.taxi,
    round(any_value(l.q1), 2)                                       AS q1,
    round(any_value(l.q3), 2)                                       AS q3,
    round(any_value(l.limite_inf), 2)                               AS limite_inf,
    round(any_value(l.limite_sup), 2)                               AS limite_sup,
    count(*)                                                        AS viajes,
    count(*) FILTER (WHERE v.fare_amount / v.trip_distance > l.limite_sup) AS atipicos_altos,
    count(*) FILTER (WHERE v.fare_amount / v.trip_distance < l.limite_inf) AS atipicos_bajos,
    round(approx_quantile(v.trip_distance, 0.5)
          FILTER (WHERE v.fare_amount / v.trip_distance > l.limite_sup), 2) AS distancia_mediana_atipicos_altos,
    round(100.0 * avg((v.ratecode_id <> 1)::INT)
          FILTER (WHERE v.fare_amount / v.trip_distance > l.limite_sup), 1) AS pct_tarifa_especial_en_altos
FROM viajes_validos v
JOIN lim l USING (taxi)
GROUP BY v.taxi
ORDER BY viajes DESC;
