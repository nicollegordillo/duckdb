-- @id: 8.2
-- @titulo: Viajes por dia por franja horaria y forma de pago, por anio (meses comunes)
-- @pregunta: En que horarios y con que forma de pago cambia el volumen de
--   viajes entre 2024, 2025 y 2026?
-- @objetivo: el Ejercicio 7 (I3, I6) mostro que el crecimiento de los
--   amarillos se concentra en la madrugada y en Flex Fare. Esta consulta cruza
--   ambas dimensiones para ver si son el mismo fenomeno y en que anio aparece.
--   Se usan solo los meses presentes en todos los anios y viajes por dia de la
--   franja (viajes / dias), para que los anios sean comparables.
--   Franjas: madrugada 0-5 h, manana 6-9 h, dia 10-15 h, tarde 16-19 h,
--   noche 20-23 h. Forma de pago: "Flex fare / sin dato" frente al resto.
-- @tabla: ind_crecimiento
-- @fuente: vista viajes_validos
WITH meses_comunes AS (
    SELECT mes_archivo
    FROM viajes_validos
    GROUP BY mes_archivo
    HAVING count(DISTINCT anio_archivo)
         = (SELECT count(DISTINCT anio_archivo) FROM viajes_validos)
),
por_dia AS (
    SELECT
        taxi,
        anio_archivo                                                AS anio,
        fecha,
        CASE WHEN hora < 6 THEN '1 Madrugada (0-5 h)'
             WHEN hora < 10 THEN '2 Manana (6-9 h)'
             WHEN hora < 16 THEN '3 Dia (10-15 h)'
             WHEN hora < 20 THEN '4 Tarde (16-19 h)'
             ELSE '5 Noche (20-23 h)' END                           AS franja,
        CASE WHEN metodo_pago IN ('Flex fare', 'Sin dato') THEN 'Flex fare / sin dato'
             ELSE 'Tarjeta, efectivo y otros' END                   AS pago,
        count(*)                                                    AS viajes
    FROM viajes_validos
    WHERE mes_archivo IN (SELECT mes_archivo FROM meses_comunes)
    GROUP BY ALL
),
dias AS (
    SELECT taxi, anio, count(DISTINCT fecha) AS dias
    FROM por_dia
    GROUP BY ALL
)
SELECT
    p.taxi,
    p.anio,
    p.franja,
    p.pago,
    sum(p.viajes)                                                   AS viajes,
    round(sum(p.viajes) / any_value(d.dias), 0)                     AS viajes_por_dia
FROM por_dia p
JOIN dias d USING (taxi, anio)
GROUP BY p.taxi, p.anio, p.franja, p.pago
ORDER BY p.taxi DESC, p.franja, p.pago, p.anio;
