-- @id: I2
-- @titulo: Costo del viaje tipico y facturacion diaria, por mes
-- @pregunta: Q3 Cuanto paga un pasajero en un viaje tipico, cuanto factura el
--   sistema por dia y como cambia en el tiempo?
-- @indicador: total mediano por viaje (USD), total promedio, facturacion
--   registrada por dia (suma de total_amount / dias) y tarifa base mediana por milla.
-- @justificacion: total_amount es la variable de negocio. Se reporta la mediana
--   porque la distribucion es muy asimetrica (Ejercicio 4, P3/P8). La tarifa por
--   milla separa el efecto de precio del de viajes mas largos. La facturacion
--   no incluye propinas en efectivo, que la TLC no registra (Ejercicio 4, P6).
-- @visualizacion: lineas por mes (una serie por anio); facturacion diaria en barras.
-- @tabla: ind_costo
-- @fuente: vista viajes_validos

-- approx_quantile (T-Digest) en lugar de median(): memoria constante con
-- decenas de millones de filas (Ejercicio 4).
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    mes_archivo                                                     AS mes,
    make_date(anio_archivo, mes_archivo, 1)                         AS periodo,
    round(approx_quantile(total_amount, 0.5), 2)                    AS total_mediano,
    round(avg(total_amount), 2)                                     AS total_promedio,
    round(sum(total_amount) / count(DISTINCT fecha), 0)             AS facturacion_por_dia,
    round(approx_quantile(fare_amount / trip_distance, 0.5), 2)     AS tarifa_por_milla_mediana
FROM viajes_validos
GROUP BY ALL
ORDER BY taxi DESC, anio, mes;
