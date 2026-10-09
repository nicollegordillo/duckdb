-- @id: I3
-- @titulo: Viajes promedio por hora en un dia laborable y en fin de semana
-- @pregunta: Q4 En que horas se concentra la demanda en dias laborables frente
--   a fines de semana, y se mantiene ese patron entre anios?
-- @indicador: viajes promedio que inician en cada hora en un dia laborable o
--   de fin de semana (viajes de esa hora / dias de ese tipo) y % del dia.
-- @justificacion: dimensiona la oferta necesaria por hora. Se divide entre los
--   dias de cada tipo porque hay ~2.5 veces mas dias laborables que de fin de
--   semana; el % del dia permite comparar la forma entre anios aunque cambie
--   el volumen.
-- @visualizacion: lineas, hora en el eje x y una serie por anio y tipo de dia.
-- @tabla: ind_perfil_horario
-- @fuente: vista viajes_validos

-- Primero se agrega por fecha y hora (unas 70 mil filas): si la CTE leyera los
-- viajes y se usara dos veces, DuckDB la materializaria completa (decenas de
-- millones de filas) y se queda sin memoria (mismo caso que 3.6e, Ejercicio 5).
WITH por_fecha_hora AS (
    SELECT
        taxi,
        anio_archivo                                                AS anio,
        CASE WHEN dia_semana <= 5 THEN 'Laborable' ELSE 'Fin de semana' END AS tipo_dia,
        fecha,
        hora,
        count(*)                                                    AS viajes
    FROM viajes_validos
    GROUP BY ALL
),
por_hora AS (
    SELECT taxi, anio, tipo_dia, hora, sum(viajes) AS viajes
    FROM por_fecha_hora
    GROUP BY ALL
),
dias AS (
    SELECT taxi, anio, tipo_dia, count(DISTINCT fecha) AS dias
    FROM por_fecha_hora
    GROUP BY ALL
)
SELECT
    h.taxi,
    h.anio,
    h.tipo_dia,
    h.anio || ' - ' || h.tipo_dia                                   AS serie,
    h.hora,
    h.viajes,
    d.dias,
    round(h.viajes / d.dias, 1)                                     AS viajes_promedio,
    round(100.0 * h.viajes
          / sum(h.viajes) OVER (PARTITION BY h.taxi, h.anio, h.tipo_dia), 2) AS pct_del_dia
FROM por_hora h
JOIN dias d USING (taxi, anio, tipo_dia)
ORDER BY h.taxi DESC, h.anio, h.tipo_dia DESC, h.hora;
