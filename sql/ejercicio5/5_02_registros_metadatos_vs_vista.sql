-- @id: 5.2
-- @titulo: Registros por tipo y anio: metadatos Parquet vs. vista unificada
-- @objetivo: Verificar que la vista `viajes`, que ahora une 2024 y 2026 con
--   union_by_name, incluye todas las filas de los archivos nuevos. La suma de
--   num_rows de los footers (sin leer datos) debe ser igual a count(*) sobre la
--   vista para cada tipo y anio: diferencia = 0.
-- @fuente: parquet_file_metadata('data/raw/*/*/*.parquet') y vista viajes
WITH meta AS (
    SELECT
        regexp_extract(file_name, 'raw[/\\](\w+)[/\\]', 1)                   AS taxi,
        CAST(regexp_extract(file_name, '_(\d{4})-\d{2}\.parquet$', 1) AS INTEGER) AS anio,
        count(*)                                                                AS archivos,
        sum(num_rows)                                                           AS registros_metadatos
    FROM parquet_file_metadata('data/raw/*/*/*.parquet')
    GROUP BY ALL
), vista AS (
    SELECT taxi, anio_archivo AS anio, count(*) AS registros_vista
    FROM viajes
    GROUP BY ALL
)
SELECT
    coalesce(m.taxi, v.taxi)                                AS taxi,
    coalesce(m.anio, v.anio)                                AS anio,
    m.archivos,
    m.registros_metadatos,
    v.registros_vista,
    v.registros_vista - m.registros_metadatos               AS diferencia
FROM meta m
FULL JOIN vista v ON m.taxi = v.taxi AND m.anio = v.anio
ORDER BY taxi DESC, anio;
