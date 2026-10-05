-- @id: 3.3c
-- @titulo: Comparacion de columnas entre amarillos y verdes
-- @objetivo: Ver que columnas son comunes, cuales son exclusivas de un tipo y
--   cuales tienen distinto nombre o tipo, para disenar un esquema unificado.
-- @fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet
WITH y AS (
    SELECT column_name, column_type
    FROM (DESCRIBE SELECT * FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true))
), g AS (
    SELECT column_name, column_type
    FROM (DESCRIBE SELECT * FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true))
)
SELECT
    coalesce(y.column_name, g.column_name)  AS columna,
    y.column_type                           AS tipo_yellow,
    g.column_type                           AS tipo_green,
    CASE WHEN y.column_name IS NULL THEN 'solo green'
         WHEN g.column_name IS NULL THEN 'solo yellow'
         WHEN y.column_type <> g.column_type THEN 'tipo distinto'
         ELSE 'comun' END                   AS estado
FROM y FULL OUTER JOIN g ON lower(y.column_name) = lower(g.column_name)
ORDER BY estado, columna;
