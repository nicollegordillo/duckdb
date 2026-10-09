-- @id: 8.3
-- @titulo: Registros amarillos con monto <= 0 por anio, mes, proveedor y metodo de pago
-- @pregunta: Por que en 2025 la regla de monto (tarifa o total <= 0) marca
--   hasta 9.5 % de los registros amarillos, contra 1-2 % en 2024 y 2026?
-- @objetivo: el indicador I11 con los tres anios muestra el salto. Esta
--   consulta busca en que proveedor y metodo de pago se concentra, igual que
--   5.9 lo hizo con la regla de duracion. Solo meses con mas de 1 % de
--   registros marcados en alguna combinacion, para que la tabla sea legible.
-- @fuente: vista viajes_enriquecidos (todos los registros)
WITH m AS (
    SELECT
        anio_archivo                                                AS anio,
        mes_archivo                                                 AS mes,
        vendor_id,
        metodo_pago,
        count(*)                                                    AS registros,
        count_if(f_monto)                                           AS con_monto_cero,
        count_if(f_monto AND fare_amount = 0 AND total_amount = 0)  AS todo_en_cero,
        count_if(f_monto AND trip_distance > 0)                     AS con_distancia
    FROM viajes_enriquecidos
    WHERE taxi = 'yellow'
    GROUP BY ALL
)
SELECT
    anio,
    mes,
    vendor_id,
    metodo_pago,
    registros,
    con_monto_cero,
    round(100.0 * con_monto_cero
          / sum(registros) OVER (PARTITION BY anio, mes), 2)        AS pct_de_registros_del_mes,
    round(100.0 * todo_en_cero / nullif(con_monto_cero, 0), 1)      AS pct_tarifa_y_total_en_cero,
    round(100.0 * con_distancia / nullif(con_monto_cero, 0), 1)     AS pct_con_distancia
FROM m
QUALIFY max(100.0 * con_monto_cero / registros) OVER (PARTITION BY anio, vendor_id, metodo_pago) > 1
    AND con_monto_cero > 0
ORDER BY anio, mes, con_monto_cero DESC;
