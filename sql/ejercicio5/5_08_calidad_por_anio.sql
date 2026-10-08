-- @id: 5.8
-- @titulo: Reglas de calidad por anio
-- @objetivo: Aplicar a 2024 las mismas reglas de calidad definidas con 2026
--   (Ejercicio 3; sql/02_vistas_analisis.sql) y comparar el porcentaje de
--   registros que marca cada regla. Si una regla marca a 2024 de forma muy
--   distinta, los umbrales elegidos con 2026 podrian no ser adecuados para el
--   anio nuevo.
-- @fuente: vista viajes_enriquecidos (sin filtrar)
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    count(*)                                                        AS registros,
    round(100.0 * avg(f_fuera_periodo::INT), 3)                     AS pct_fuera_periodo,
    round(100.0 * avg(f_duracion::INT), 3)                          AS pct_duracion,
    round(100.0 * avg(f_distancia::INT), 3)                         AS pct_distancia,
    round(100.0 * avg(f_velocidad::INT), 3)                         AS pct_velocidad,
    round(100.0 * avg(f_monto::INT), 3)                             AS pct_monto,
    round(100.0 * avg(f_pasajeros::INT), 3)                         AS pct_pasajeros,
    round(100.0 * avg((f_fuera_periodo OR f_duracion OR f_distancia
                       OR f_velocidad OR f_monto OR f_pasajeros)::INT), 2) AS pct_excluido
FROM viajes_enriquecidos
GROUP BY ALL
ORDER BY taxi DESC, anio;
