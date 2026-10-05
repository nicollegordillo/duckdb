-- @id: 3.6f
-- @titulo: Consistencia entre total_amount y la suma de sus componentes
-- @objetivo: Verificar si total_amount es igual a la suma de tarifa, recargos,
--   impuestos, propina y peajes. Diferencias grandes indican registros
--   inconsistentes o componentes que no estan en el archivo.
-- @fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet
WITH t AS (
    SELECT 'yellow' AS tipo, total_amount,
           coalesce(fare_amount,0) + coalesce(extra,0) + coalesce(mta_tax,0)
         + coalesce(tip_amount,0) + coalesce(tolls_amount,0)
         + coalesce(improvement_surcharge,0) + coalesce(congestion_surcharge,0)
         + coalesce(Airport_fee,0) + coalesce(cbd_congestion_fee,0) AS suma
    FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)
    UNION ALL
    SELECT 'green', total_amount,
           coalesce(fare_amount,0) + coalesce(extra,0) + coalesce(mta_tax,0)
         + coalesce(tip_amount,0) + coalesce(tolls_amount,0)
         + coalesce(improvement_surcharge,0) + coalesce(congestion_surcharge,0)
         + coalesce(ehail_fee,0) + coalesce(cbd_congestion_fee,0)
    FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true)
)
SELECT
    tipo,
    count(*)                                                    AS registros,
    count(*) FILTER (WHERE abs(total_amount - suma) <= 0.01)    AS coincide,
    count(*) FILTER (WHERE abs(total_amount - suma) > 0.01)     AS no_coincide,
    round(100.0 * count(*) FILTER (WHERE abs(total_amount - suma) > 0.01) / count(*), 3) AS pct_no_coincide,
    round(median(total_amount - suma) FILTER (WHERE abs(total_amount - suma) > 0.01), 2) AS mediana_diferencia
FROM t
GROUP BY tipo
ORDER BY tipo DESC;
