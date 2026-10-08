-- @id: 5.7
-- @titulo: Contenido de las columnas que cambian entre anios
-- @objetivo: Verificar como quedaron en la vista unificada las columnas que no
--   existen en todos los archivos (5.3): deben ser NULL en los anios donde no
--   existian (no 0 ni un valor inventado). Tambien se revisan los codigos de
--   pago "sin dato" (payment_type 0 o NULL) y los pasajeros nulos, que en el
--   Ejercicio 3 aparecian juntos en 2026, para saber si 2024 tiene el mismo
--   patron.
-- @fuente: vista viajes (sin filtros de calidad)
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    count(*)                                                        AS registros,
    round(100.0 * count(cbd_congestion_fee) / count(*), 2)          AS pct_cbd_no_nulo,
    round(100.0 * count(*) FILTER (WHERE cbd_congestion_fee > 0) / count(*), 2) AS pct_cbd_mayor_0,
    round(100.0 * count(request_source) / count(*), 2)              AS pct_request_source_no_nulo,
    round(100.0 * count(airport_fee) / count(*), 2)                 AS pct_airport_fee_no_nulo,
    round(100.0 * count(*) FILTER (WHERE congestion_surcharge > 0) / count(*), 2) AS pct_congestion_mayor_0,
    round(100.0 * count(*) FILTER (WHERE payment_type = 0) / count(*), 2)        AS pct_pago_0,
    round(100.0 * count(*) FILTER (WHERE payment_type IS NULL) / count(*), 2)    AS pct_pago_nulo,
    round(100.0 * count(*) FILTER (WHERE passenger_count IS NULL) / count(*), 2) AS pct_pasajeros_nulo
FROM viajes
GROUP BY ALL
ORDER BY taxi DESC, anio;
