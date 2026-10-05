-- @id: 3.2b
-- @titulo: Registros totales por tipo de taxi (escaneo con count)
-- @objetivo: Contar el total de registros consultando los Parquet y comparar
--   con la suma de metadatos de 3.2a (deben coincidir).
-- @fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet
SELECT 'yellow' AS tipo, count(*) AS registros
FROM read_parquet('data/raw/yellow/*/*.parquet')
UNION ALL
SELECT 'green', count(*)
FROM read_parquet('data/raw/green/*/*.parquet')
UNION ALL
SELECT 'total', count(*)
FROM read_parquet('data/raw/*/*/*.parquet', union_by_name = true);
