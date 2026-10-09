-- @id: I8
-- @titulo: Peso de los aeropuertos en viajes y facturacion
-- @pregunta: Q9 Que proporcion de los viajes y de la facturacion corresponde a
--   viajes desde o hacia los aeropuertos (JFK, LaGuardia, Newark)?
-- @indicador: por tipo, anio y aeropuerto: viajes, % de los viajes, % de la
--   facturacion y total mediano.
-- @justificacion: los viajes de aeropuerto son pocos pero largos y caros
--   (tarifa fija a JFK, Ejercicio 4 P8); medir su peso en facturacion y no solo
--   en viajes muestra su importancia economica. Se usa el catalogo de zonas
--   (service_zone 'Airports' y 'EWR') en vez de airport_fee porque esa columna
--   solo existe en amarillos. Si el origen y el destino son aeropuertos, cuenta
--   el de origen.
-- @visualizacion: barras por anio, apiladas por aeropuerto (% de viajes y % de facturacion).
-- @tabla: ind_aeropuertos
-- @fuente: vistas viajes_validos y zonas
WITH v AS (
    SELECT
        v.taxi,
        v.anio_archivo                                              AS anio,
        v.total_amount,
        CASE WHEN zo.service_zone IN ('Airports', 'EWR') THEN zo.zona
             WHEN zd.service_zone IN ('Airports', 'EWR') THEN zd.zona
             ELSE 'Sin aeropuerto' END                              AS aeropuerto
    FROM viajes_validos v
    LEFT JOIN zonas zo ON zo.location_id = v.pu_location_id
    LEFT JOIN zonas zd ON zd.location_id = v.do_location_id
)
SELECT
    taxi,
    anio,
    aeropuerto,
    count(*)                                                        AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi, anio), 2) AS pct_viajes,
    round(100.0 * sum(total_amount)
          / sum(sum(total_amount)) OVER (PARTITION BY taxi, anio), 2) AS pct_facturacion,
    round(approx_quantile(total_amount, 0.5), 2)                    AS total_mediano
FROM v
GROUP BY taxi, anio, aeropuerto
ORDER BY taxi DESC, anio, aeropuerto;
