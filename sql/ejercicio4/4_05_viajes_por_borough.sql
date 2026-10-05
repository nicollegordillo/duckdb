-- @id: P5
-- @titulo: Origen de los viajes por borough
-- @pregunta: Desde que boroughs se originan los viajes de cada tipo de taxi?
-- @justificacion: Los taxis verdes fueron creados para atender zonas fuera del
--   centro de Manhattan; cruzar PULocationID con el catalogo de zonas permite
--   comprobar si la distribucion geografica refleja esa regla.
-- @fuente: vista viajes_validos + vista zonas (data/raw/zonas/taxi_zone_lookup.csv)
SELECT
    v.taxi,
    coalesce(z.borough, 'Sin zona')                                 AS borough_origen,
    count(*)                                                        AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY v.taxi), 2) AS pct_del_tipo
FROM viajes_validos v
LEFT JOIN zonas z ON z.location_id = v.pu_location_id
GROUP BY 1, 2
ORDER BY v.taxi DESC, viajes DESC;
