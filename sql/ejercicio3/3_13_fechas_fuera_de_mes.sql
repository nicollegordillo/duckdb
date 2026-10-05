-- @id: 3.6d
-- @titulo: Detalle de fechas de pickup fuera del mes del archivo
-- @objetivo: Ver a que fechas corresponden los registros que no caen en el mes
--   del archivo (bordes de mes vs. fechas claramente erroneas como 2008/2009).
-- @fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet
WITH t AS (
    SELECT 'yellow' AS tipo, filename, tpep_pickup_datetime AS pu
    FROM read_parquet('data/raw/yellow/*/*.parquet', filename = true, union_by_name = true)
    UNION ALL
    SELECT 'green', filename, lpep_pickup_datetime
    FROM read_parquet('data/raw/green/*/*.parquet', filename = true, union_by_name = true)
)
SELECT
    tipo,
    regexp_extract(filename, '_(\d{4}-\d{2})\.parquet$', 1) AS archivo_periodo,
    strftime(pu, '%Y-%m')                                    AS pickup_periodo,
    count(*)                                                 AS registros,
    min(pu)                                                  AS pickup_min,
    max(pu)                                                  AS pickup_max
FROM t
WHERE strftime(pu, '%Y-%m') <> regexp_extract(filename, '_(\d{4}-\d{2})\.parquet$', 1)
GROUP BY ALL
ORDER BY registros DESC
LIMIT 30;
