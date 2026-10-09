-- @id: I9
-- @titulo: Las 10 zonas de origen con mas viajes y su concentracion
-- @pregunta: Q10 Donde se concentra la demanda: que zonas generan mas viajes y
--   que parte del total representan las 10 principales?
-- @indicador: por tipo y anio, ranking de zonas de origen por viajes, % del
--   total y % acumulado de las 10 primeras.
-- @justificacion: la ubicacion explica las diferencias entre tipos (Ejercicio
--   4, P5) y sirve para ubicar oferta. El % acumulado mide que tan concentrado
--   esta el mercado; se reporta por anio para ver si las zonas cambian.
-- @visualizacion: barras horizontales (filtro por tipo y anio).
-- @tabla: ind_zonas_origen
-- @fuente: vistas viajes_validos y zonas
WITH conteo AS (
    SELECT taxi, anio_archivo AS anio, pu_location_id, count(*) AS viajes
    FROM viajes_validos
    GROUP BY ALL
),
ranking AS (
    SELECT
        *,
        row_number() OVER (PARTITION BY taxi, anio ORDER BY viajes DESC) AS posicion,
        100.0 * viajes / sum(viajes) OVER (PARTITION BY taxi, anio)      AS pct
    FROM conteo
)
SELECT
    r.taxi,
    r.anio,
    r.posicion,
    z.borough,
    coalesce(z.zona, 'Desconocida')                                 AS zona,
    r.viajes,
    round(r.pct, 2)                                                 AS pct_viajes,
    round(sum(r.pct) OVER (PARTITION BY r.taxi, r.anio ORDER BY r.posicion), 2) AS pct_acumulado
FROM ranking r
LEFT JOIN zonas z ON z.location_id = r.pu_location_id
WHERE r.posicion <= 10
ORDER BY r.taxi DESC, r.anio, r.posicion;
