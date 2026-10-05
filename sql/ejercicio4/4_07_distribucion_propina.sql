-- @id: P7
-- @titulo: Distribucion del porcentaje de propina (pagos con tarjeta)
-- @pregunta: Que porcentaje de propina dejan los pasajeros que pagan con
--   tarjeta y se concentra en valores particulares?
-- @justificacion: Solo los pagos con tarjeta registran la propina de forma
--   confiable (ver P6). Agrupar en rangos muestra si los pasajeros eligen los
--   porcentajes sugeridos por la pantalla del taxi.
-- @fuente: vista viajes_validos (payment_type = 1)
SELECT
    taxi,
    CASE
        WHEN pct_propina = 0     THEN '0 %'
        WHEN pct_propina < 0.15  THEN '(0, 15) %'
        WHEN pct_propina < 0.19  THEN '[15, 19) %'
        WHEN pct_propina < 0.21  THEN '[19, 21) %'
        WHEN pct_propina < 0.24  THEN '[21, 24) %'
        WHEN pct_propina < 0.26  THEN '[24, 26) %'
        WHEN pct_propina < 0.29  THEN '[26, 29) %'
        WHEN pct_propina < 0.31  THEN '[29, 31) %'
        ELSE '>= 31 %'
    END                                                             AS rango_propina,
    min(pct_propina)                                                AS orden,
    count(*)                                                        AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi), 2) AS pct_del_tipo
FROM viajes_validos
WHERE payment_type = 1 AND pct_propina IS NOT NULL
GROUP BY taxi, rango_propina
ORDER BY taxi DESC, orden;
