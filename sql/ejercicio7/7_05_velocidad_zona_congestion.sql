-- @id: I5
-- @titulo: Velocidad de los viajes dentro de la zona de cobro por congestion
-- @pregunta: Q6 Cambio la velocidad de los viajes que empiezan y terminan
--   dentro de la zona de cobro por congestion de Manhattan (CBD) despues de que
--   empezo el cobro (5 de enero de 2025)?
-- @indicador: velocidad mediana (mph) y duracion mediana de los viajes
--   amarillos con origen y destino dentro de la zona, lunes a viernes de 7 a
--   19 h, por mes.
-- @justificacion: el objetivo declarado del cobro es reducir el trafico en la
--   zona; es la pregunta de politica publica que estos datos pueden responder.
--   Se restringe a horario laboral y a viajes internos para comparar el mismo
--   tipo de viaje antes y despues.
--   El catalogo de zonas no indica cuales estan dentro de la zona de cobro. Se
--   identifican con los propios datos: zonas de origen donde al menos el 90 %
--   de los viajes amarillos desde 2025 paga cbd_congestion_fee (todo viaje que
--   empieza dentro de la zona lo paga; los que empiezan fuera solo si entran).
--   Con solo 2024 descargado la lista queda vacia y la consulta no devuelve filas.
-- @visualizacion: lineas, mes en el eje x y una serie por anio.
-- @tabla: ind_velocidad_cbd
-- @fuente: vista viajes_validos
WITH zonas_cbd AS (
    SELECT pu_location_id AS location_id
    FROM viajes_validos
    WHERE taxi = 'yellow'
      AND anio_archivo >= 2025
      AND cbd_congestion_fee IS NOT NULL
    GROUP BY 1
    HAVING count(*) >= 1000
       AND avg(CASE WHEN cbd_congestion_fee > 0 THEN 1 ELSE 0 END) >= 0.9
)
SELECT
    anio_archivo                                                    AS anio,
    mes_archivo                                                     AS mes,
    make_date(anio_archivo, mes_archivo, 1)                         AS periodo,
    (SELECT count(*) FROM zonas_cbd)                                AS zonas_en_cbd,
    count(*)                                                        AS viajes,
    round(approx_quantile(velocidad_mph, 0.5), 2)                   AS mph_mediana,
    round(approx_quantile(duracion_min, 0.5), 1)                    AS duracion_mediana_min,
    round(approx_quantile(trip_distance, 0.5), 2)                   AS distancia_mediana_mi
FROM viajes_validos
WHERE taxi = 'yellow'
  AND dia_semana <= 5
  AND hora BETWEEN 7 AND 18
  AND pu_location_id IN (SELECT location_id FROM zonas_cbd)
  AND do_location_id IN (SELECT location_id FROM zonas_cbd)
GROUP BY ALL
ORDER BY anio, mes;
