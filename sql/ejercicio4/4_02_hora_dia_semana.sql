-- @id: P2
-- @titulo: Demanda por hora del dia y dia de la semana
-- @pregunta: En que horas y dias se concentra la demanda y difiere el patron
--   entre taxis amarillos y verdes?
-- @justificacion: El pickup trae fecha y hora exactas; el patron hora x dia
--   distingue viajes de trabajo (picos entre semana) de ocio (noches de fin de
--   semana). Se normaliza a % del total de cada tipo para comparar tipos con
--   volumenes muy distintos.
-- @fuente: vista viajes_validos
SELECT
    taxi,
    dia_semana,                                   -- 1 = lunes ... 7 = domingo
    hora,
    count(*)                                                        AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi), 3) AS pct_del_tipo
FROM viajes_validos
GROUP BY taxi, dia_semana, hora
ORDER BY taxi DESC, dia_semana, hora;
