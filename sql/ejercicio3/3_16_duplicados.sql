-- @id: 3.6g
-- @titulo: Posibles registros duplicados
-- @objetivo: Contar viajes repetidos con el mismo proveedor, hora de pickup y
--   dropoff, zonas y monto total (un mismo viaje cargado dos veces).
-- @fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet
WITH t AS (
    SELECT 'yellow' AS tipo, VendorID, tpep_pickup_datetime AS pu, tpep_dropoff_datetime AS dof,
           PULocationID, DOLocationID, total_amount
    FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)
    UNION ALL
    SELECT 'green', VendorID, lpep_pickup_datetime, lpep_dropoff_datetime,
           PULocationID, DOLocationID, total_amount
    FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true)
), g AS (
    SELECT tipo, count(*) AS n
    FROM t
    GROUP BY tipo, VendorID, pu, dof, PULocationID, DOLocationID, total_amount
)
SELECT tipo,
       sum(n)                       AS registros,
       count(*)                     AS combinaciones_unicas,
       sum(n) - count(*)            AS registros_duplicados
FROM g GROUP BY tipo ORDER BY tipo DESC;
