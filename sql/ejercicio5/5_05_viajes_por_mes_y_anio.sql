-- @id: 5.5
-- @titulo: Viajes por dia en cada mes: 2024 frente a 2026
-- @objetivo: Consultar ambos anios a la vez para comparar el mismo mes de
--   distintos anios. Se usan viajes por dia (y no el total del mes) porque los
--   meses tienen distinta cantidad de dias; la variacion se calcula contra el
--   mismo mes del anio anterior disponible, asi que la consulta sigue sirviendo
--   cuando se agregue 2025 (Ejercicio 8).
-- @fuente: vista viajes_validos
WITH m AS (
    SELECT
        taxi,
        anio_archivo                                                AS anio,
        mes_archivo                                                 AS mes,
        count(*)                                                    AS viajes,
        count(*) / count(DISTINCT fecha)                            AS viajes_por_dia
    FROM viajes_validos
    GROUP BY ALL
)
SELECT
    taxi,
    mes,
    anio,
    viajes,
    round(viajes_por_dia, 0)                                        AS viajes_por_dia,
    round(100.0 * (viajes_por_dia
          / lag(viajes_por_dia) OVER (PARTITION BY taxi, mes ORDER BY anio) - 1), 1)
                                                                    AS variacion_pct_vs_anio_previo
FROM m
ORDER BY taxi DESC, mes, anio;
