-- @id: 3.5b
-- @titulo: Muestra reproducible de 10 registros - taxis verdes
-- @objetivo: Inspeccionar registros reales para entender formato y valores.
--   Se ordena por un hash de varias columnas en lugar de usar USING SAMPLE:
--   el resultado es pseudoaleatorio pero identico en cada ejecucion, sin
--   importar cuantos hilos use DuckDB.
-- @fuente: data/raw/green/*/*.parquet
SELECT *
FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true)
ORDER BY hash(lpep_pickup_datetime, lpep_dropoff_datetime, PULocationID, DOLocationID, total_amount)
LIMIT 10;
