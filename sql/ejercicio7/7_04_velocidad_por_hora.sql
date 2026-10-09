-- @id: I4
-- @titulo: Velocidad mediana por hora en dias laborables
-- @pregunta: Q5 A que horas es mas lento el trafico para los taxis y cuanto
--   cambia la duracion de un viaje entre la hora mas lenta y la mas rapida?
-- @indicador: velocidad mediana (mph) y minutos medianos por milla de los
--   viajes que inician en cada hora, de lunes a viernes.
-- @justificacion: la velocidad promedio de un viaje es un indicador indirecto
--   de congestion; los minutos por milla traducen esa velocidad a tiempo para
--   el pasajero. Solo dias laborables, para que el fin de semana no suavice
--   las horas pico.
-- @visualizacion: lineas, hora en el eje x y una serie por anio (filtro por tipo).
-- @tabla: ind_velocidad_hora
-- @fuente: vista viajes_validos
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    hora,
    count(*)                                                        AS viajes,
    round(approx_quantile(velocidad_mph, 0.5), 2)                   AS mph_mediana,
    round(approx_quantile(duracion_min / trip_distance, 0.5), 2)    AS min_por_milla_mediana
FROM viajes_validos
WHERE dia_semana <= 5
GROUP BY ALL
ORDER BY taxi DESC, anio, hora;
