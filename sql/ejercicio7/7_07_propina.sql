-- @id: I7
-- @titulo: Propina de los pagos con tarjeta, por mes
-- @pregunta: Q8 Cuanto dejan de propina quienes pagan con tarjeta y es estable
--   en el tiempo?
-- @indicador: % de pagos con tarjeta que deja propina, % que deja exactamente
--   el 20 % del total antes de propina, propina mediana como % del total antes
--   de propina y propina mediana en USD.
-- @justificacion: el Ejercicio 4 (P11) mostro que la propina se mide bien
--   sobre el total antes de propina (asi la calcula la pantalla del taxi) y que
--   20 % es la opcion dominante. Solo tarjeta (la propina en efectivo no se
--   registra) y solo el proveedor 2, cuyos totales son consistentes con sus
--   componentes (Ejercicio 3, 3.6h).
-- @visualizacion: lineas por mes (% con propina y % exactamente 20 %).
-- @tabla: ind_propina
-- @fuente: vista viajes_validos (payment_type = 1, vendor_id = 2)
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    mes_archivo                                                     AS mes,
    make_date(anio_archivo, mes_archivo, 1)                         AS periodo,
    count(*)                                                        AS pagos_tarjeta,
    round(100.0 * count_if(tip_amount > 0) / count(*), 2)           AS pct_con_propina,
    round(100.0 * count_if(round(100.0 * tip_amount
          / (total_amount - tip_amount)) = 20) / count(*), 2)       AS pct_propina_20,
    round(approx_quantile(100.0 * tip_amount
          / (total_amount - tip_amount), 0.5), 1)                   AS propina_pct_mediana,
    round(approx_quantile(tip_amount, 0.5), 2)                      AS propina_mediana_usd
FROM viajes_validos
WHERE payment_type = 1
  AND vendor_id = 2
  AND total_amount - tip_amount > 0
GROUP BY ALL
ORDER BY taxi DESC, anio, mes;
