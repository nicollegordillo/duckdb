-- @id: B7
-- @titulo: Consulta selectiva: viajes desde JFK en un dia, por hora
-- @objetivo: Representa una consulta puntual de exploracion (detalle de un dia
--   y una zona, como las revisiones de fechas del Ejercicio 3). Menos del
--   0.01 % de las filas cumple el filtro, asi que mide cuanto aprovecha cada
--   estrategia las estadisticas min/max (row groups del Parquet, zone maps de
--   la tabla) para saltarse datos que no necesita leer. El 15 de enero de 2026
--   esta en todos los escenarios del benchmark. 132 = JFK Airport.
-- @fuente: vista viajes_validos (sobre Parquet o sobre la tabla materializada)
SELECT
    hora,
    taxi,
    count(*)                                                        AS viajes,
    round(avg(total_amount), 2)                                     AS total_prom_usd
FROM viajes_validos
WHERE pickup_at >= TIMESTAMP '2026-01-15'
  AND pickup_at <  TIMESTAMP '2026-01-16'
  AND pu_location_id = 132
GROUP BY ALL
ORDER BY hora, taxi DESC;
