-- @id: P9
-- @titulo: Registros atipicos o inconsistentes por regla, tipo y mes
-- @pregunta: Que proporcion de los registros es atipica o inconsistente, que
--   regla la explica y cambia entre tipos de taxi o meses?
-- @justificacion: Cuantifica el efecto de los filtros definidos a partir del
--   Ejercicio 3 (sql/00_vistas.sql). Un mes o tipo con un porcentaje mucho mayor
--   de registros invalidos indicaria un problema de captura especifico.
-- @fuente: vista viajes_enriquecidos (sin filtrar)
SELECT
    taxi,
    make_date(anio_archivo, mes_archivo, 1)                         AS mes_archivo,
    count(*)                                                        AS registros,
    count(*) FILTER (WHERE f_fuera_periodo)                         AS fuera_periodo,
    count(*) FILTER (WHERE f_duracion)                              AS duracion,
    count(*) FILTER (WHERE f_distancia)                             AS distancia,
    count(*) FILTER (WHERE f_velocidad)                             AS velocidad,
    count(*) FILTER (WHERE f_monto)                                 AS monto,
    count(*) FILTER (WHERE f_pasajeros)                             AS pasajeros,
    count(*) FILTER (WHERE f_fuera_periodo OR f_duracion OR f_distancia
                     OR f_velocidad OR f_monto OR f_pasajeros)      AS con_algun_problema,
    round(100.0 * count(*) FILTER (WHERE f_fuera_periodo OR f_duracion OR f_distancia
                     OR f_velocidad OR f_monto OR f_pasajeros) / count(*), 2) AS pct_excluido
FROM viajes_enriquecidos
GROUP BY ALL
ORDER BY taxi DESC, mes_archivo;
