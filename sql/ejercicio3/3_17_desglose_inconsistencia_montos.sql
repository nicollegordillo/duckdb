-- @id: 3.6h
-- @titulo: Desglose de la inconsistencia de montos por metodo de pago y proveedor
-- @objetivo: Explicar de donde viene la diferencia entre total_amount y la suma
--   de sus componentes detectada en 3.6f (36.7 % en amarillos, 19.9 % en
--   verdes). Si la diferencia se concentra en un metodo de pago o proveedor y
--   tiene un valor fijo, es un patron de registro y no un error aleatorio.
--   Tambien muestra en que proveedor se concentra RatecodeID = 99.
-- @fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet
WITH t AS (
    SELECT 'yellow' AS tipo, VendorID, payment_type, RatecodeID, total_amount,
           coalesce(fare_amount,0) + coalesce(extra,0) + coalesce(mta_tax,0)
         + coalesce(tip_amount,0) + coalesce(tolls_amount,0)
         + coalesce(improvement_surcharge,0) + coalesce(congestion_surcharge,0)
         + coalesce(Airport_fee,0) + coalesce(cbd_congestion_fee,0) AS suma
    FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)
    UNION ALL
    SELECT 'green', VendorID, payment_type, RatecodeID, total_amount,
           coalesce(fare_amount,0) + coalesce(extra,0) + coalesce(mta_tax,0)
         + coalesce(tip_amount,0) + coalesce(tolls_amount,0)
         + coalesce(improvement_surcharge,0) + coalesce(congestion_surcharge,0)
         + coalesce(ehail_fee,0) + coalesce(cbd_congestion_fee,0)
    FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true)
), d AS (
    SELECT *, round(total_amount - suma, 2) AS dif FROM t
)
SELECT
    tipo,
    coalesce(CAST(payment_type AS VARCHAR), 'NULL')                 AS payment_type,
    VendorID                                                        AS vendor_id,
    count(*)                                                        AS registros,
    count(*) FILTER (WHERE abs(dif) > 0.01)                         AS no_coincide,
    round(100.0 * count(*) FILTER (WHERE abs(dif) > 0.01) / count(*), 2) AS pct_no_coincide,
    mode(dif) FILTER (WHERE abs(dif) > 0.01)                        AS diferencia_mas_comun,
    count(*) FILTER (WHERE RatecodeID = 99)                         AS ratecode_99
FROM d
GROUP BY ALL
ORDER BY tipo DESC, registros DESC;
