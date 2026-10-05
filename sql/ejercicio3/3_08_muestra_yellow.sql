-- @id: 3.5a
-- @titulo: Muestra reproducible de 10 registros - taxis amarillos
-- @objetivo: Inspeccionar registros reales para entender formato y valores.
--   Se ordena por un hash de varias columnas en lugar de usar USING SAMPLE:
--   el resultado es pseudoaleatorio pero identico en cada ejecucion, sin
--   importar cuantos hilos use DuckDB.
-- @fuente: data/raw/yellow/*/*.parquet
SELECT *
FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)
ORDER BY hash(tpep_pickup_datetime, tpep_dropoff_datetime, PULocationID, DOLocationID, total_amount)
LIMIT 10;
