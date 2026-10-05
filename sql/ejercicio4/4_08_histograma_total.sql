-- @id: P8
-- @titulo: Histograma del monto total del viaje
-- @pregunta: Como se distribuye el monto total cobrado y hay concentraciones
--   en valores especificos (p. ej. tarifas fijas)?
-- @justificacion: total_amount es la variable de negocio principal. Un
--   histograma en intervalos de 5 USD muestra la forma de la distribucion y
--   picos asociados a tarifas fijas como la del aeropuerto JFK.
-- @fuente: vista viajes_validos
SELECT
    taxi,
    least(floor(total_amount / 5) * 5, 150)                        AS desde_usd,
    count(*)                                                        AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi), 3) AS pct_del_tipo
FROM viajes_validos
GROUP BY 1, 2
ORDER BY taxi DESC, desde_usd;
-- El ultimo intervalo (150) agrupa todos los viajes de 150 USD o mas.
