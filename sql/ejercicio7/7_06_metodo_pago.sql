-- @id: I6
-- @titulo: Participacion de cada metodo de pago, por mes
-- @pregunta: Q7 Como pagan los pasajeros y que tan rapido crece el bloque
--   Flex Fare / sin dato frente a tarjeta y efectivo?
-- @indicador: % de los viajes de cada mes por metodo de pago (tarjeta,
--   efectivo, Flex Fare / sin dato, otros).
-- @justificacion: el metodo de pago condiciona que propinas se registran
--   (Ejercicio 4, P6) y en el Ejercicio 5 el bloque Flex Fare explico casi todo
--   el crecimiento de los amarillos. Se agrupan disputa, sin cargo,
--   desconocido y anulado en "Otros" porque juntos son < 1 %.
-- @visualizacion: barras apiladas al 100 % por mes (filtro por tipo).
-- @tabla: ind_pago
-- @fuente: vista viajes_validos
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    mes_archivo                                                     AS mes,
    make_date(anio_archivo, mes_archivo, 1)                         AS periodo,
    CASE WHEN metodo_pago IN ('Tarjeta', 'Efectivo') THEN metodo_pago
         WHEN metodo_pago IN ('Flex fare', 'Sin dato') THEN 'Flex fare / sin dato'
         ELSE 'Otros' END                                           AS metodo,
    count(*)                                                        AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER
          (PARTITION BY taxi, anio_archivo, mes_archivo), 2)        AS pct
FROM viajes_validos
GROUP BY taxi, anio_archivo, mes_archivo, metodo
ORDER BY taxi DESC, anio, mes, metodo;
