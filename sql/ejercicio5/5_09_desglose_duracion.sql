-- @id: 5.9
-- @titulo: Desglose de la regla de duracion por anio y proveedor
-- @objetivo: La consulta 5.8 muestra que la regla de duracion (<= 0 min o
--   > 6 h) marca el 0.09 % de los amarillos de 2024 y el 1.28 % de 2026, 15
--   veces mas. Se separa en duracion exactamente 0, negativa y mayor a 6 horas,
--   por proveedor, para saber si es un cambio en como se registran los datos
--   (concentrado en un proveedor) o un cambio en los viajes.
-- @fuente: vista viajes_enriquecidos (sin filtrar)
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    vendor_id,
    count(*)                                                        AS registros,
    count(*) FILTER (WHERE duracion_min = 0)                        AS duracion_cero,
    count(*) FILTER (WHERE duracion_min < 0)                        AS duracion_negativa,
    count(*) FILTER (WHERE duracion_min > 360)                      AS duracion_mas_6h,
    round(100.0 * avg(f_duracion::INT), 3)                          AS pct_regla_duracion,
    round(100.0 * count(*) FILTER (WHERE duracion_min = 0 AND trip_distance > 0)
          / nullif(count(*) FILTER (WHERE duracion_min = 0), 0), 1) AS pct_cero_con_distancia
FROM viajes_enriquecidos
GROUP BY ALL
ORDER BY taxi DESC, anio, vendor_id;
