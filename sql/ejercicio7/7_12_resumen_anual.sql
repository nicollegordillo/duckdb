-- @id: I12
-- @titulo: Resumen por anio en los meses comunes a todos los anios
-- @pregunta: Q13 Como se comparan los anios entre si en volumen, precio,
--   caracteristicas del viaje y forma de pago, sin que la estacionalidad
--   sesgue la comparacion?
-- @indicador: por tipo y anio, en los meses presentes en todos los anios
--   descargados: viajes por dia, total mediano, distancia, duracion y
--   velocidad medianas, % tarjeta, % Flex Fare / sin dato y % con cargo CBD.
-- @justificacion: los anios no tienen los mismos meses (2026 solo llega hasta
--   el ultimo mes publicado) y la demanda es estacional; un promedio anual
--   directo compararia periodos distintos. Los meses comunes se calculan a
--   partir de los datos, asi la consulta se ajusta sola al agregar anios o meses.
-- @visualizacion: tabla y tarjetas KPI del tablero.
-- @tabla: ind_resumen_anual
-- @fuente: vista viajes_validos
WITH meses_comunes AS (
    SELECT mes_archivo
    FROM viajes_validos
    GROUP BY mes_archivo
    HAVING count(DISTINCT anio_archivo)
         = (SELECT count(DISTINCT anio_archivo) FROM viajes_validos)
)
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    min(mes_archivo) || '-' || max(mes_archivo)                     AS meses,
    count(*)                                                        AS viajes,
    round(count(*) / count(DISTINCT fecha), 0)                      AS viajes_por_dia,
    round(approx_quantile(total_amount, 0.5), 2)                    AS total_mediano,
    round(approx_quantile(trip_distance, 0.5), 2)                   AS distancia_mediana,
    round(approx_quantile(duracion_min, 0.5), 1)                    AS duracion_mediana,
    round(approx_quantile(velocidad_mph, 0.5), 2)                   AS mph_mediana,
    round(100.0 * count_if(metodo_pago = 'Tarjeta') / count(*), 1)  AS pct_tarjeta,
    round(100.0 * count_if(metodo_pago IN ('Flex fare', 'Sin dato')) / count(*), 1) AS pct_flex_sin_dato,
    round(100.0 * count_if(cbd_congestion_fee > 0)
          / nullif(count(cbd_congestion_fee), 0), 1)                AS pct_con_cargo_cbd
FROM viajes_validos
WHERE mes_archivo IN (SELECT mes_archivo FROM meses_comunes)
GROUP BY taxi, anio_archivo
ORDER BY taxi DESC, anio;
