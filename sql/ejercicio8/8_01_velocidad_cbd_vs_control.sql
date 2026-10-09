-- @id: 8.1
-- @titulo: Velocidad dentro de la zona CBD frente a un grupo de control, por anio y mes
-- @pregunta: El cambio de velocidad dentro de la zona de cobro por congestion
--   es propio de la zona o tambien ocurre en el resto de Manhattan?
-- @objetivo: separar el efecto de la zona del de cambios generales (clima,
--   obras, mas viajes). Se comparan viajes amarillos de lunes a viernes de 7 a
--   19 h con origen y destino dentro de la zona CBD contra viajes con origen y
--   destino en Manhattan pero fuera de la zona (al norte de la calle 60). Si
--   ambos grupos cambian igual, el cambio no se puede atribuir al cobro.
--   Las zonas CBD se identifican igual que en el indicador I5
--   (sql/ejercicio7/7_05_velocidad_zona_congestion.sql).
-- @tabla: ind_cbd_control
-- @fuente: vistas viajes_validos y zonas
WITH zonas_cbd AS (
    SELECT pu_location_id AS location_id
    FROM viajes_validos
    WHERE taxi = 'yellow'
      AND anio_archivo >= 2025
      AND cbd_congestion_fee IS NOT NULL
    GROUP BY 1
    HAVING count(*) >= 1000
       AND avg(CASE WHEN cbd_congestion_fee > 0 THEN 1 ELSE 0 END) >= 0.9
),
manhattan_fuera AS (
    SELECT location_id
    FROM zonas
    WHERE borough = 'Manhattan'
      AND location_id NOT IN (SELECT location_id FROM zonas_cbd)
),
v AS (
    SELECT
        anio_archivo                                                AS anio,
        mes_archivo                                                 AS mes,
        CASE
            WHEN pu_location_id IN (SELECT location_id FROM zonas_cbd)
             AND do_location_id IN (SELECT location_id FROM zonas_cbd) THEN 'Dentro de la zona CBD'
            WHEN pu_location_id IN (SELECT location_id FROM manhattan_fuera)
             AND do_location_id IN (SELECT location_id FROM manhattan_fuera) THEN 'Manhattan fuera de la zona'
        END                                                         AS grupo,
        velocidad_mph,
        trip_distance
    FROM viajes_validos
    WHERE taxi = 'yellow'
      AND dia_semana <= 5
      AND hora BETWEEN 7 AND 18
)
SELECT
    grupo,
    anio,
    mes,
    make_date(anio, mes, 1)                                         AS periodo,
    count(*)                                                        AS viajes,
    round(approx_quantile(velocidad_mph, 0.5), 2)                   AS mph_mediana,
    round(approx_quantile(trip_distance, 0.5), 2)                   AS distancia_mediana_mi
FROM v
WHERE grupo IS NOT NULL
GROUP BY ALL
ORDER BY grupo, anio, mes;
