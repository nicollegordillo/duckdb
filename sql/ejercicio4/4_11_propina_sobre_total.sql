-- @id: P11
-- @titulo: Propina como % del total antes de propina (tarjeta, proveedor 2)
-- @pregunta: Los pasajeros eligen los porcentajes sugeridos por la pantalla
--   del taxi (20, 25, 30 %) cuando la propina se mide sobre el total cobrado
--   antes de la propina, en lugar de sobre la tarifa base?
-- @justificacion: En P7 la propina se mide sobre fare_amount y el pico cae en
--   26-29 % (amarillos) y 21-24 % (verdes), no en 20 %. Hipotesis: la pantalla
--   calcula el porcentaje sobre la tarifa mas recargos, que en amarillos son
--   mayores (congestion 2.50 + CBD 0.75). Se usa solo el proveedor 2, cuyo
--   total_amount es consistente con sus componentes (Ejercicio 3, 3.6h).
-- @fuente: vista viajes_validos (payment_type = 1, vendor_id = 2)
SELECT
    taxi,
    least(round(100.0 * tip_amount / (total_amount - tip_amount)), 40) AS pct_propina_sobre_total,
    count(*)                                                        AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi), 2) AS pct_del_tipo
FROM viajes_validos
WHERE payment_type = 1
  AND vendor_id = 2
  AND total_amount - tip_amount > 0
GROUP BY 1, 2
ORDER BY taxi DESC, pct_propina_sobre_total;
-- El valor 40 agrupa todas las propinas de 40 % o mas.
