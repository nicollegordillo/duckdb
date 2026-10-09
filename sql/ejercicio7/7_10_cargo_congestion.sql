-- @id: I10
-- @titulo: Cargo por congestion de Manhattan (CBD): cobertura y recaudacion
-- @pregunta: Q11 Que parte de los viajes paga el cargo CBD y cuanto recauda
--   por dia a traves de los taxis?
-- @indicador: % de viajes con cargo CBD > 0, cargo promedio de quienes lo
--   pagan y recaudacion diaria (suma del cargo / dias).
-- @justificacion: es el cambio regulatorio mas grande del periodo (desde el 5
--   de enero de 2025) y explica parte del aumento del total (Ejercicio 5). En
--   2024 la columna no existe y queda NULL: el % se calcula sobre los viajes
--   con la columna presente, asi 2024 aparece como NULL y no como 0.
-- @visualizacion: barras de recaudacion diaria por mes y lineas de % con cargo.
-- @tabla: ind_cbd
-- @fuente: vista viajes_validos
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    mes_archivo                                                     AS mes,
    make_date(anio_archivo, mes_archivo, 1)                         AS periodo,
    count(*)                                                        AS viajes,
    round(100.0 * count_if(cbd_congestion_fee > 0)
          / nullif(count(cbd_congestion_fee), 0), 2)                AS pct_con_cargo,
    round(avg(CASE WHEN cbd_congestion_fee > 0 THEN cbd_congestion_fee END), 2) AS cargo_promedio,
    round(sum(cbd_congestion_fee) / count(DISTINCT fecha), 0)       AS recaudacion_por_dia
FROM viajes_validos
GROUP BY ALL
ORDER BY taxi DESC, anio, mes;
