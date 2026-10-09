-- @id: 8.4
-- @titulo: Componentes promedio del total de un viaje amarillo, por anio y mes
-- @pregunta: Que componente explica el aumento del total entre 2024, 2025 y
--   2026: la tarifa, los recargos fijos, el cargo CBD o la propina?
-- @objetivo: el total mediano sube 3 % de 2024 a 2025 y 9 % de 2025 a 2026, y
--   el salto empieza en diciembre de 2025. Se descompone el total en sus
--   columnas para ver cual cambia y desde que mes. Se usan promedios (y no
--   medianas) porque los promedios de los componentes suman el promedio del
--   total. Solo el proveedor 2, cuyo total es consistente con sus componentes
--   (Ejercicio 3, 3.6h), y viajes con tarifa estandar (RatecodeID = 1) para
--   no mezclar tarifas fijas de aeropuerto.
-- @fuente: vista viajes_validos (taxi = 'yellow', vendor_id = 2, ratecode_id = 1)
SELECT
    anio_archivo                                                    AS anio,
    mes_archivo                                                     AS mes,
    count(*)                                                        AS viajes,
    round(avg(trip_distance), 2)                                    AS distancia,
    round(avg(fare_amount), 2)                                      AS tarifa,
    round(avg(fare_amount) / avg(trip_distance), 2)                 AS tarifa_por_milla,
    round(avg(extra), 2)                                            AS extra,
    round(avg(mta_tax), 2)                                          AS mta_tax,
    round(avg(improvement_surcharge), 2)                            AS improvement_surcharge,
    round(avg(congestion_surcharge), 2)                             AS congestion_surcharge,
    round(avg(coalesce(cbd_congestion_fee, 0)), 2)                  AS cbd_congestion_fee,
    round(avg(tolls_amount), 2)                                     AS peajes,
    round(avg(tip_amount), 2)                                       AS propina,
    round(avg(total_amount), 2)                                     AS total
FROM viajes_validos
WHERE taxi = 'yellow'
  AND vendor_id = 2
  AND ratecode_id = 1
GROUP BY ALL
ORDER BY anio, mes;
