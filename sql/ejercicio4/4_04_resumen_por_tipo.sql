-- @id: P4
-- @titulo: Comparacion general entre taxis amarillos y verdes
-- @pregunta: En que se diferencian amarillos y verdes en volumen, distancia,
--   costo, pasajeros, propina y cargos especiales?
-- @justificacion: Los taxis verdes (boro taxis) operan con reglas distintas a
--   los amarillos; un resumen lado a lado de las metricas clave cuantifica esa
--   diferencia.
-- Nota: se usa approx_quantile (algoritmo T-Digest) en lugar de median /
--   quantile_cont. El calculo exacto necesita guardar en memoria todos los
--   valores (~30 millones por variable) y se quedo sin memoria en el
--   contenedor; approx_quantile usa memoria constante con un error minimo,
--   despreciable para describir distribuciones.
-- @fuente: vista viajes_validos
SELECT
    taxi,
    count(*)                                                        AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER (), 2)              AS pct_viajes,
    round(avg(trip_distance), 2)                                    AS distancia_prom_mi,
    round(approx_quantile(duracion_min, 0.5), 1)                                  AS duracion_mediana_min,
    round(avg(total_amount), 2)                                     AS total_prom_usd,
    round(avg(total_amount / nullif(trip_distance, 0)), 2)          AS usd_por_milla_prom,
    round(avg(passenger_count), 2)                                  AS pasajeros_prom,
    round(100.0 * avg((payment_type = 1)::INT), 1)                  AS pct_tarjeta,
    round(100.0 * avg((coalesce(airport_fee, 0) > 0 OR ratecode_id IN (2, 3))::INT), 2)
                                                                    AS pct_aeropuerto,
    round(100.0 * avg((coalesce(cbd_congestion_fee, 0) > 0)::INT), 1) AS pct_cargo_cbd
FROM viajes_validos
GROUP BY taxi
ORDER BY viajes DESC;
