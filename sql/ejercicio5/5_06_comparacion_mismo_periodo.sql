-- @id: 5.6
-- @titulo: Comparacion entre anios en los mismos meses
-- @objetivo: Comparar los anios con metricas del Ejercicio 4 (P1, P3, P4, P6)
--   usando solo los meses presentes en todos los anios descargados (enero a
--   agosto mientras 2026 este incompleto), para que la estacionalidad no sesgue
--   la comparacion. Los meses comunes se obtienen de los nombres de archivo.
-- Nota: se usa approx_quantile (T-Digest) por memoria, igual que en el
--   Ejercicio 4.
-- @fuente: vista viajes_validos + glob('data/raw/*/*/*.parquet')
WITH archivos AS (
    SELECT
        CAST(regexp_extract(file, '_(\d{4})-\d{2}\.parquet$', 1) AS INTEGER) AS anio,
        CAST(regexp_extract(file, '_\d{4}-(\d{2})\.parquet$', 1) AS INTEGER) AS mes
    FROM glob('data/raw/*/*/*.parquet')
), meses_comunes AS (
    SELECT mes
    FROM archivos
    GROUP BY mes
    HAVING count(DISTINCT anio) = (SELECT count(DISTINCT anio) FROM archivos)
)
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    (SELECT string_agg(mes, ',' ORDER BY mes) FROM meses_comunes)   AS meses,
    count(*)                                                        AS viajes_validos,
    round(count(*) / count(DISTINCT fecha), 0)                      AS viajes_por_dia,
    round(approx_quantile(trip_distance, 0.5), 2)                   AS distancia_mediana_mi,
    round(approx_quantile(duracion_min, 0.5), 1)                    AS duracion_mediana_min,
    round(approx_quantile(total_amount, 0.5), 2)                    AS total_mediano_usd,
    round(avg(total_amount), 2)                                     AS total_prom_usd,
    round(100.0 * avg((payment_type = 1)::INT), 1)                  AS pct_tarjeta,
    round(100.0 * avg((payment_type = 2)::INT), 1)                  AS pct_efectivo,
    round(100.0 * avg((payment_type = 0 OR payment_type IS NULL)::INT), 1) AS pct_flex_o_sin_dato,
    round(100.0 * avg((coalesce(airport_fee, 0) > 0 OR ratecode_id IN (2, 3))::INT), 2)
                                                                    AS pct_aeropuerto,
    round(100.0 * avg((coalesce(cbd_congestion_fee, 0) > 0)::INT), 1) AS pct_cargo_cbd
FROM viajes_validos
WHERE mes_archivo IN (SELECT mes FROM meses_comunes)
GROUP BY ALL
ORDER BY taxi DESC, anio;
