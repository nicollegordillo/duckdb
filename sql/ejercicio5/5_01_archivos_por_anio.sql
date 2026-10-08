-- @id: 5.1
-- @titulo: Archivos y meses disponibles por tipo de taxi y anio
-- @objetivo: Confirmar que los archivos de 2024 quedaron en la estructura del
--   proyecto (data/raw/<tipo>/<anio>/) junto a los de 2026, que la carpeta
--   coincide con el anio del nombre del archivo y que no hay huecos en la serie
--   mensual (12 meses en 2024; en 2026, los meses publicados por la TLC).
-- @fuente: data/raw/*/*/*.parquet (solo nombres de archivo, no se leen datos)
WITH f AS (
    SELECT
        regexp_extract(file, 'raw[/\\](\w+)[/\\]', 1)                        AS tipo,
        CAST(regexp_extract(file, 'raw[/\\]\w+[/\\](\d{4})', 1) AS INTEGER)  AS anio_carpeta,
        CAST(regexp_extract(file, '_(\d{4})-\d{2}\.parquet$', 1) AS INTEGER)   AS anio,
        CAST(regexp_extract(file, '_\d{4}-(\d{2})\.parquet$', 1) AS INTEGER)   AS mes
    FROM glob('data/raw/*/*/*.parquet')
)
SELECT
    tipo,
    anio,
    count(*)                                                AS archivos,
    min(mes)                                                AS primer_mes,
    max(mes)                                                AS ultimo_mes,
    (max(mes) - min(mes) + 1) - count(*)                    AS huecos,
    count(*) FILTER (WHERE anio_carpeta <> anio)            AS en_carpeta_incorrecta,
    string_agg(lpad(CAST(mes AS VARCHAR), 2, '0'), ', ' ORDER BY mes) AS meses
FROM f
GROUP BY ALL
ORDER BY tipo DESC, anio;
