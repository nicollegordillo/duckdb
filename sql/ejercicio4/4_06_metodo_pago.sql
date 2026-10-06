-- @id: P6
-- @titulo: Metodo de pago y propina registrada
-- @pregunta: Como se distribuyen los metodos de pago por tipo de taxi y como
--   cambia la propina registrada segun el metodo?
-- @justificacion: payment_type y tip_amount son las variables de pago clave.
--   Se espera que la propina en efectivo no quede registrada, lo que sesgaria
--   cualquier analisis de propinas que no separe por metodo.
-- Nota: se usa approx_quantile (algoritmo T-Digest) en lugar de median /
--   quantile_cont. El calculo exacto necesita guardar en memoria todos los
--   valores (~30 millones por variable) y se quedo sin memoria en el
--   contenedor; approx_quantile usa memoria constante con un error minimo,
--   despreciable para describir distribuciones.
-- @fuente: vista viajes_validos
SELECT
    taxi,
    payment_type,
    metodo_pago,
    count(*)                                                        AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi), 2) AS pct_del_tipo,
    round(avg(total_amount), 2)                                     AS total_prom_usd,
    round(100.0 * avg((tip_amount > 0)::INT), 1)                    AS pct_con_propina,
    round(100.0 * approx_quantile(pct_propina, 0.5), 1)                           AS propina_mediana_pct
FROM viajes_validos
GROUP BY taxi, payment_type, metodo_pago
ORDER BY taxi DESC, viajes DESC;
