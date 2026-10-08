-- @id: 5.4
-- @titulo: Consulta conjunta 2024 + 2026: volumen, cobertura y calidad por anio
-- @objetivo: Comprobar que una sola consulta sobre las vistas devuelve ambos
--   anios y que cada anio tiene un volumen, un rango de fechas y una proporcion
--   de registros validos coherentes. Las fechas min/max se calculan solo con
--   los viajes cuyo pickup cae en el mes del archivo (el resto son errores ya
--   documentados en el Ejercicio 3).
-- @fuente: vista viajes_enriquecidos (data/raw/*/*/*.parquet)
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    count(DISTINCT mes_archivo)                                     AS meses,
    count(*)                                                        AS registros,
    min(pickup_at) FILTER (WHERE NOT f_fuera_periodo)               AS primer_pickup,
    max(pickup_at) FILTER (WHERE NOT f_fuera_periodo)               AS ultimo_pickup,
    round(100.0 * avg(f_fuera_periodo::INT), 3)                     AS pct_fuera_periodo,
    count(*) FILTER (WHERE NOT (f_fuera_periodo OR f_duracion OR f_distancia
                                OR f_velocidad OR f_monto OR f_pasajeros)) AS validos,
    round(100.0 * avg((NOT (f_fuera_periodo OR f_duracion OR f_distancia
                            OR f_velocidad OR f_monto OR f_pasajeros))::INT), 2) AS pct_validos
FROM viajes_enriquecidos
GROUP BY ALL
ORDER BY taxi DESC, anio;
