-- @id: I1
-- @titulo: Demanda diaria y participacion de cada tipo de taxi, por mes
-- @pregunta: Q1 Como evoluciona la demanda diaria de cada tipo de taxi mes a
--   mes? Q2 Que peso tienen los taxis verdes dentro del sistema y esta cambiando?
-- @indicador: viajes validos por dia (viajes del mes / dias con viajes) y % de
--   los viajes del mes que corresponde a cada tipo.
-- @justificacion: es la medida basica de actividad. Se usa por dia y no el
--   total del mes porque los meses tienen distinta cantidad de dias; la
--   participacion muestra si los verdes ganan o pierden mercado.
-- @visualizacion: lineas, mes en el eje x y una serie por anio (filtro por tipo).
-- @tabla: ind_demanda
-- @fuente: vista viajes_validos
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    mes_archivo                                                     AS mes,
    make_date(anio_archivo, mes_archivo, 1)                         AS periodo,
    count(*)                                                        AS viajes,
    count(DISTINCT fecha)                                           AS dias,
    round(count(*) / count(DISTINCT fecha), 0)                      AS viajes_por_dia,
    round(100.0 * count(*)
          / sum(count(*)) OVER (PARTITION BY anio_archivo, mes_archivo), 2) AS pct_del_mes
FROM viajes_validos
GROUP BY taxi, anio_archivo, mes_archivo
ORDER BY taxi DESC, anio, mes;
