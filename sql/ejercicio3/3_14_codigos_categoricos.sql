-- @id: 3.6e
-- @titulo: Valores de las columnas categoricas codificadas
-- @objetivo: Comparar los codigos presentes (VendorID, RatecodeID, payment_type,
--   store_and_fwd_flag) contra el diccionario de datos de la TLC para detectar
--   codigos no documentados y nulos.
-- @fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet
WITH t AS (
    SELECT 'yellow' AS tipo, VendorID, RatecodeID, payment_type, store_and_fwd_flag
    FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)
    UNION ALL
    SELECT 'green', VendorID, RatecodeID, payment_type, store_and_fwd_flag
    FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true)
)
SELECT tipo, 'VendorID' AS columna, CAST(VendorID AS VARCHAR) AS valor, count(*) AS registros FROM t GROUP BY ALL
UNION ALL
SELECT tipo, 'RatecodeID', CAST(RatecodeID AS VARCHAR), count(*) FROM t GROUP BY ALL
UNION ALL
SELECT tipo, 'payment_type', CAST(payment_type AS VARCHAR), count(*) FROM t GROUP BY ALL
UNION ALL
SELECT tipo, 'store_and_fwd_flag', store_and_fwd_flag, count(*) FROM t GROUP BY ALL
ORDER BY tipo DESC, columna, valor NULLS LAST;
