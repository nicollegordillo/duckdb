-- @id: 3.6i
-- @titulo: Columna request_source (no documentada) por mes y metodo de pago
-- @objetivo: request_source aparece solo en algunos archivos de 2026 y no esta
--   en el diccionario de datos de la TLC (version de marzo de 2025). Se revisa
--   en que meses existe, que valores toma y si coincide con los viajes Flex
--   Fare (payment_type = 0) o sin metodo de pago (NULL).
-- @fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet
WITH t AS (
    SELECT 'yellow' AS tipo, filename, request_source, payment_type
    FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true, filename = true)
    UNION ALL
    SELECT 'green', filename, request_source, payment_type
    FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true, filename = true)
)
SELECT
    tipo,
    regexp_extract(filename, '_(\d{4}-\d{2})\.parquet$', 1)         AS periodo,
    count(*)                                                        AS registros,
    count(request_source)                                           AS con_request_source,
    count(*) FILTER (WHERE payment_type = 0 OR payment_type IS NULL) AS pago_0_o_nulo,
    count(*) FILTER (WHERE request_source IS NOT NULL
                       AND (payment_type = 0 OR payment_type IS NULL)) AS ambos,
    string_agg(DISTINCT request_source, ', ')                       AS valores
FROM t
GROUP BY 1, 2
ORDER BY tipo DESC, periodo;
