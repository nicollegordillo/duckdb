-- @id: P1
-- @titulo: Volumen mensual de viajes por tipo de taxi
-- @pregunta: Como evoluciona la cantidad de viajes mes a mes y que proporcion
--   del total corresponde a cada tipo de taxi?
-- @justificacion: Los datos llegan en archivos mensuales; el volumen por mes es
--   la serie temporal basica y revela estacionalidad, meses incompletos y el
--   peso relativo de amarillos vs. verdes.
-- @fuente: vista viajes_validos (data/raw/*/*/*.parquet)
SELECT
    date_trunc('month', pickup_at)::DATE                        AS mes,
    taxi,
    count(*)                                                    AS viajes,
    round(count(*) / count(DISTINCT fecha), 0)                  AS viajes_por_dia,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY date_trunc('month', pickup_at)::DATE), 2)
                                                                AS pct_del_mes
FROM viajes_validos
GROUP BY 1, 2
ORDER BY mes, taxi DESC;
