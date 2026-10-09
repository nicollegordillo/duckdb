-- @id: 8.5
-- @titulo: Total mediano y participacion por forma de pago, amarillos, por anio (meses comunes)
-- @pregunta: El aumento del total mediano en 2026 viene de que cada tipo de
--   viaje es mas caro o de que cambio la mezcla (mas viajes Flex Fare)?
-- @objetivo: la consulta 8.4 muestra que en los viajes con tarifa estandar
--   del proveedor 2 el total promedio sube solo ~3-4 % entre 2025 y 2026,
--   mientras que el total mediano de todos los amarillos sube 9 % (I12). Se
--   compara el total mediano de cada forma de pago con el de todos los viajes
--   (fila "Todos", con GROUPING SETS): si cada grupo sube poco y el total sube
--   mucho, el aumento es un efecto de composicion.
-- @fuente: vista viajes_validos (taxi = 'yellow')
WITH meses_comunes AS (
    SELECT mes_archivo
    FROM viajes_validos
    GROUP BY mes_archivo
    HAVING count(DISTINCT anio_archivo)
         = (SELECT count(DISTINCT anio_archivo) FROM viajes_validos)
),
v AS (
    SELECT
        anio_archivo                                                AS anio,
        CASE WHEN metodo_pago IN ('Tarjeta', 'Efectivo') THEN metodo_pago
             WHEN metodo_pago IN ('Flex fare', 'Sin dato') THEN 'Flex fare / sin dato'
             ELSE 'Otros' END                                       AS pago,
        total_amount,
        trip_distance
    FROM viajes_validos
    WHERE taxi = 'yellow'
      AND mes_archivo IN (SELECT mes_archivo FROM meses_comunes)
)
SELECT
    anio,
    coalesce(pago, 'Todos')                                         AS pago,
    count(*)                                                        AS viajes,
    round(100.0 * count(*) / sum(count(*)) FILTER (WHERE pago IS NOT NULL)
          OVER (PARTITION BY anio), 1)                              AS pct_viajes,
    round(approx_quantile(total_amount, 0.5), 2)                    AS total_mediano,
    round(avg(total_amount), 2)                                     AS total_promedio,
    round(approx_quantile(trip_distance, 0.5), 2)                   AS distancia_mediana
FROM v
GROUP BY GROUPING SETS ((anio, pago), (anio))
ORDER BY pago, anio;
