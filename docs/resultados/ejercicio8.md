# Resultados de sql/ejercicio8

Generado automaticamente el 2026-10-08T23:14:15 con `python scripts/run_sql.py ejercicio8 --tablero`.
No editar a mano: volver a ejecutar el script tras cambiar las consultas.

DuckDB 1.5.5

## 8.1 - Velocidad dentro de la zona CBD frente a un grupo de control, por anio y mes

**Pregunta:** El cambio de velocidad dentro de la zona de cobro por congestion es propio de la zona o tambien ocurre en el resto de Manhattan?  
**Objetivo:** separar el efecto de la zona del de cambios generales (clima, obras, mas viajes). Se comparan viajes amarillos de lunes a viernes de 7 a 19 h con origen y destino dentro de la zona CBD contra viajes con origen y destino en Manhattan pero fuera de la zona (al norte de la calle 60). Si ambos grupos cambian igual, el cambio no se puede atribuir al cobro. Las zonas CBD se identifican igual que en el indicador I5 (sql/ejercicio7/7_05_velocidad_zona_congestion.sql).  
**Fuente:** vistas viajes_validos y zonas  
**Archivo:** `sql/ejercicio8/8_01_velocidad_cbd_vs_control.sql`  
**Tiempo de ejecucion:** 33.307 s - **filas del resultado:** 64

```sql
-- @id: 8.1
-- @titulo: Velocidad dentro de la zona CBD frente a un grupo de control, por anio y mes
-- @pregunta: El cambio de velocidad dentro de la zona de cobro por congestion
--   es propio de la zona o tambien ocurre en el resto de Manhattan?
-- @objetivo: separar el efecto de la zona del de cambios generales (clima,
--   obras, mas viajes). Se comparan viajes amarillos de lunes a viernes de 7 a
--   19 h con origen y destino dentro de la zona CBD contra viajes con origen y
--   destino en Manhattan pero fuera de la zona (al norte de la calle 60). Si
--   ambos grupos cambian igual, el cambio no se puede atribuir al cobro.
--   Las zonas CBD se identifican igual que en el indicador I5
--   (sql/ejercicio7/7_05_velocidad_zona_congestion.sql).
-- @tabla: ind_cbd_control
-- @fuente: vistas viajes_validos y zonas
WITH zonas_cbd AS (
    SELECT pu_location_id AS location_id
    FROM viajes_validos
    WHERE taxi = 'yellow'
      AND anio_archivo >= 2025
      AND cbd_congestion_fee IS NOT NULL
    GROUP BY 1
    HAVING count(*) >= 1000
       AND avg(CASE WHEN cbd_congestion_fee > 0 THEN 1 ELSE 0 END) >= 0.9
),
manhattan_fuera AS (
    SELECT location_id
    FROM zonas
    WHERE borough = 'Manhattan'
      AND location_id NOT IN (SELECT location_id FROM zonas_cbd)
),
v AS (
    SELECT
        anio_archivo                                                AS anio,
        mes_archivo                                                 AS mes,
        CASE
            WHEN pu_location_id IN (SELECT location_id FROM zonas_cbd)
             AND do_location_id IN (SELECT location_id FROM zonas_cbd) THEN 'Dentro de la zona CBD'
            WHEN pu_location_id IN (SELECT location_id FROM manhattan_fuera)
             AND do_location_id IN (SELECT location_id FROM manhattan_fuera) THEN 'Manhattan fuera de la zona'
        END                                                         AS grupo,
        velocidad_mph,
        trip_distance
    FROM viajes_validos
    WHERE taxi = 'yellow'
      AND dia_semana <= 5
      AND hora BETWEEN 7 AND 18
)
SELECT
    grupo,
    anio,
    mes,
    make_date(anio, mes, 1)                                         AS periodo,
    count(*)                                                        AS viajes,
    round(approx_quantile(velocidad_mph, 0.5), 2)                   AS mph_mediana,
    round(approx_quantile(trip_distance, 0.5), 2)                   AS distancia_mediana_mi
FROM v
WHERE grupo IS NOT NULL
GROUP BY ALL
ORDER BY grupo, anio, mes;
```

**Resultado:**

| grupo | anio | mes | periodo | viajes | mph_mediana | distancia_mediana_mi |
|---|---|---|---|---|---|---|
| Dentro de la zona CBD | 2,024 | 1 | 2024-01-01 00:00:00 | 536,615 | 7.68 | 1.27 |
| Dentro de la zona CBD | 2,024 | 2 | 2024-02-01 00:00:00 | 535,887 | 7.27 | 1.28 |
| Dentro de la zona CBD | 2,024 | 3 | 2024-03-01 00:00:00 | 587,474 | 7.05 | 1.3 |
| Dentro de la zona CBD | 2,024 | 4 | 2024-04-01 00:00:00 | 610,102 | 7.06 | 1.31 |
| Dentro de la zona CBD | 2,024 | 5 | 2024-05-01 00:00:00 | 654,937 | 6.8 | 1.31 |
| Dentro de la zona CBD | 2,024 | 6 | 2024-06-01 00:00:00 | 589,533 | 6.85 | 1.3 |
| Dentro de la zona CBD | 2,024 | 7 | 2024-07-01 00:00:00 | 603,406 | 7.08 | 1.29 |
| Dentro de la zona CBD | 2,024 | 8 | 2024-08-01 00:00:00 | 544,933 | 7.23 | 1.29 |
| Dentro de la zona CBD | 2,024 | 9 | 2024-09-01 00:00:00 | 588,991 | 6.58 | 1.31 |
| Dentro de la zona CBD | 2,024 | 10 | 2024-10-01 00:00:00 | 655,969 | 6.53 | 1.31 |
| Dentro de la zona CBD | 2,024 | 11 | 2024-11-01 00:00:00 | 588,573 | 6.72 | 1.28 |
| Dentro de la zona CBD | 2,024 | 12 | 2024-12-01 00:00:00 | 610,681 | 6.38 | 1.26 |
| Dentro de la zona CBD | 2,025 | 1 | 2025-01-01 00:00:00 | 609,064 | 7.69 | 1.26 |
| Dentro de la zona CBD | 2,025 | 2 | 2025-02-01 00:00:00 | 575,533 | 7.38 | 1.27 |
| Dentro de la zona CBD | 2,025 | 3 | 2025-03-01 00:00:00 | 613,033 | 7.25 | 1.29 |
| Dentro de la zona CBD | 2,025 | 4 | 2025-04-01 00:00:00 | 654,027 | 7.1 | 1.3 |
| Dentro de la zona CBD | 2,025 | 5 | 2025-05-01 00:00:00 | 681,071 | 6.73 | 1.31 |
| Dentro de la zona CBD | 2,025 | 6 | 2025-06-01 00:00:00 | 650,514 | 6.95 | 1.31 |
| Dentro de la zona CBD | 2,025 | 7 | 2025-07-01 00:00:00 | 662,042 | 6.87 | 1.3 |
| Dentro de la zona CBD | 2,025 | 8 | 2025-08-01 00:00:00 | 534,144 | 7.32 | 1.32 |
| Dentro de la zona CBD | 2,025 | 9 | 2025-09-01 00:00:00 | 646,330 | 6.55 | 1.33 |
| Dentro de la zona CBD | 2,025 | 10 | 2025-10-01 00:00:00 | 682,028 | 6.46 | 1.31 |
| Dentro de la zona CBD | 2,025 | 11 | 2025-11-01 00:00:00 | 563,377 | 6.45 | 1.29 |
| Dentro de la zona CBD | 2,025 | 12 | 2025-12-01 00:00:00 | 669,199 | 6.36 | 1.29 |
| Dentro de la zona CBD | 2,026 | 1 | 2026-01-01 00:00:00 | 551,884 | 7.13 | 1.28 |
| Dentro de la zona CBD | 2,026 | 2 | 2026-02-01 00:00:00 | 485,215 | 6.31 | 1.25 |
| Dentro de la zona CBD | 2,026 | 3 | 2026-03-01 00:00:00 | 601,841 | 6.8 | 1.26 |
| Dentro de la zona CBD | 2,026 | 4 | 2026-04-01 00:00:00 | 598,054 | 6.66 | 1.29 |
| Dentro de la zona CBD | 2,026 | 5 | 2026-05-01 00:00:00 | 579,961 | 6.32 | 1.3 |
| Dentro de la zona CBD | 2,026 | 6 | 2026-06-01 00:00:00 | 615,056 | 6.33 | 1.29 |
| Dentro de la zona CBD | 2,026 | 7 | 2026-07-01 00:00:00 | 616,526 | 6.52 | 1.29 |
| Dentro de la zona CBD | 2,026 | 8 | 2026-08-01 00:00:00 | 510,051 | 6.77 | 1.29 |
| Manhattan fuera de la zona | 2,024 | 1 | 2024-01-01 00:00:00 | 345,623 | 8.55 | 1.16 |
| Manhattan fuera de la zona | 2,024 | 2 | 2024-02-01 00:00:00 | 328,730 | 8.53 | 1.15 |
| Manhattan fuera de la zona | 2,024 | 3 | 2024-03-01 00:00:00 | 334,680 | 8.69 | 1.18 |
| Manhattan fuera de la zona | 2,024 | 4 | 2024-04-01 00:00:00 | 365,336 | 8.44 | 1.18 |
| Manhattan fuera de la zona | 2,024 | 5 | 2024-05-01 00:00:00 | 401,067 | 8.05 | 1.18 |
| Manhattan fuera de la zona | 2,024 | 6 | 2024-06-01 00:00:00 | 329,073 | 8.52 | 1.16 |
| Manhattan fuera de la zona | 2,024 | 7 | 2024-07-01 00:00:00 | 284,227 | 9.07 | 1.16 |
| Manhattan fuera de la zona | 2,024 | 8 | 2024-08-01 00:00:00 | 264,470 | 8.97 | 1.16 |

_... 24 filas mas (ver CSV)._

---

## 8.2 - Viajes por dia por franja horaria y forma de pago, por anio (meses comunes)

**Pregunta:** En que horarios y con que forma de pago cambia el volumen de viajes entre 2024, 2025 y 2026?  
**Objetivo:** el Ejercicio 7 (I3, I6) mostro que el crecimiento de los amarillos se concentra en la madrugada y en Flex Fare. Esta consulta cruza ambas dimensiones para ver si son el mismo fenomeno y en que anio aparece. Se usan solo los meses presentes en todos los anios y viajes por dia de la franja (viajes / dias), para que los anios sean comparables. Franjas: madrugada 0-5 h, manana 6-9 h, dia 10-15 h, tarde 16-19 h, noche 20-23 h. Forma de pago: "Flex fare / sin dato" frente al resto.  
**Fuente:** vista viajes_validos  
**Archivo:** `sql/ejercicio8/8_02_crecimiento_por_franja_y_pago.sql`  
**Tiempo de ejecucion:** 54.396 s - **filas del resultado:** 60

```sql
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
```

**Resultado:**

| taxi | anio | franja | pago | viajes | viajes_por_dia |
|---|---|---|---|---|---|
| yellow | 2,024 | 1 Madrugada (0-5 h) | Flex fare / sin dato | 326,421 | 1,338 |
| yellow | 2,025 | 1 Madrugada (0-5 h) | Flex fare / sin dato | 943,492 | 3,883 |
| yellow | 2,026 | 1 Madrugada (0-5 h) | Flex fare / sin dato | 1,211,793 | 4,987 |
| yellow | 2,024 | 1 Madrugada (0-5 h) | Tarjeta, efectivo y otros | 1,667,079 | 6,832 |
| yellow | 2,025 | 1 Madrugada (0-5 h) | Tarjeta, efectivo y otros | 1,623,535 | 6,681 |
| yellow | 2,026 | 1 Madrugada (0-5 h) | Tarjeta, efectivo y otros | 1,478,255 | 6,083 |
| yellow | 2,024 | 2 Manana (6-9 h) | Flex fare / sin dato | 332,701 | 1,364 |
| yellow | 2,025 | 2 Manana (6-9 h) | Flex fare / sin dato | 878,798 | 3,616 |
| yellow | 2,026 | 2 Manana (6-9 h) | Flex fare / sin dato | 1,179,397 | 4,853 |
| yellow | 2,024 | 2 Manana (6-9 h) | Tarjeta, efectivo y otros | 2,742,668 | 11,240 |
| yellow | 2,025 | 2 Manana (6-9 h) | Tarjeta, efectivo y otros | 2,658,058 | 10,939 |
| yellow | 2,026 | 2 Manana (6-9 h) | Tarjeta, efectivo y otros | 2,506,516 | 10,315 |
| yellow | 2,024 | 3 Dia (10-15 h) | Flex fare / sin dato | 466,646 | 1,912 |
| yellow | 2,025 | 3 Dia (10-15 h) | Flex fare / sin dato | 1,216,673 | 5,007 |
| yellow | 2,026 | 3 Dia (10-15 h) | Flex fare / sin dato | 1,600,164 | 6,585 |
| yellow | 2,024 | 3 Dia (10-15 h) | Tarjeta, efectivo y otros | 7,706,811 | 31,585 |
| yellow | 2,025 | 3 Dia (10-15 h) | Tarjeta, efectivo y otros | 7,685,858 | 31,629 |
| yellow | 2,026 | 3 Dia (10-15 h) | Tarjeta, efectivo y otros | 7,097,393 | 29,207 |
| yellow | 2,024 | 4 Tarde (16-19 h) | Flex fare / sin dato | 525,117 | 2,152 |
| yellow | 2,025 | 4 Tarde (16-19 h) | Flex fare / sin dato | 993,826 | 4,090 |
| yellow | 2,026 | 4 Tarde (16-19 h) | Flex fare / sin dato | 1,111,754 | 4,575 |
| yellow | 2,024 | 4 Tarde (16-19 h) | Tarjeta, efectivo y otros | 6,136,360 | 25,149 |
| yellow | 2,025 | 4 Tarde (16-19 h) | Tarjeta, efectivo y otros | 6,229,053 | 25,634 |
| yellow | 2,026 | 4 Tarde (16-19 h) | Tarjeta, efectivo y otros | 5,729,514 | 23,578 |
| yellow | 2,024 | 5 Noche (20-23 h) | Flex fare / sin dato | 640,166 | 2,624 |
| yellow | 2,025 | 5 Noche (20-23 h) | Flex fare / sin dato | 1,591,601 | 6,550 |
| yellow | 2,026 | 5 Noche (20-23 h) | Flex fare / sin dato | 1,930,345 | 7,944 |
| yellow | 2,024 | 5 Noche (20-23 h) | Tarjeta, efectivo y otros | 4,679,230 | 19,177 |
| yellow | 2,025 | 5 Noche (20-23 h) | Tarjeta, efectivo y otros | 4,687,801 | 19,291 |
| yellow | 2,026 | 5 Noche (20-23 h) | Tarjeta, efectivo y otros | 4,282,343 | 17,623 |
| green | 2,024 | 1 Madrugada (0-5 h) | Flex fare / sin dato | 1,017 | 4 |
| green | 2,025 | 1 Madrugada (0-5 h) | Flex fare / sin dato | 1,179 | 5 |
| green | 2,026 | 1 Madrugada (0-5 h) | Flex fare / sin dato | 2,178 | 9 |
| green | 2,024 | 1 Madrugada (0-5 h) | Tarjeta, efectivo y otros | 22,238 | 91 |
| green | 2,025 | 1 Madrugada (0-5 h) | Tarjeta, efectivo y otros | 17,462 | 72 |
| green | 2,026 | 1 Madrugada (0-5 h) | Tarjeta, efectivo y otros | 13,110 | 54 |
| green | 2,024 | 2 Manana (6-9 h) | Flex fare / sin dato | 3,779 | 15 |
| green | 2,025 | 2 Manana (6-9 h) | Flex fare / sin dato | 5,813 | 24 |
| green | 2,026 | 2 Manana (6-9 h) | Flex fare / sin dato | 10,454 | 43 |
| green | 2,024 | 2 Manana (6-9 h) | Tarjeta, efectivo y otros | 57,637 | 236 |

_... 20 filas mas (ver CSV)._

---

## 8.3 - Registros amarillos con monto <= 0 por anio, mes, proveedor y metodo de pago

**Pregunta:** Por que en 2025 la regla de monto (tarifa o total <= 0) marca hasta 9.5 % de los registros amarillos, contra 1-2 % en 2024 y 2026?  
**Objetivo:** el indicador I11 con los tres anios muestra el salto. Esta consulta busca en que proveedor y metodo de pago se concentra, igual que 5.9 lo hizo con la regla de duracion. Solo meses con mas de 1 % de registros marcados en alguna combinacion, para que la tabla sea legible.  
**Fuente:** vista viajes_enriquecidos (todos los registros)  
**Archivo:** `sql/ejercicio8/8_03_desglose_monto_cero.sql`  
**Tiempo de ejecucion:** 10.232 s - **filas del resultado:** 213

```sql
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
```

**Resultado:**

| anio | mes | vendor_id | metodo_pago | registros | con_monto_cero | pct_de_registros_del_mes | pct_tarifa_y_total_en_cero | pct_con_distancia |
|---|---|---|---|---|---|---|---|---|
| 2,024 | 1 | 2 | Disputa | 42,811 | 21,406 | 0.72 | 0 | 93.2 |
| 2,024 | 1 | 2 | Efectivo | 334,469 | 8,477 | 0.29 | 0.3 | 92.3 |
| 2,024 | 1 | 2 | Sin cargo | 11,477 | 5,742 | 0.19 | 0 | 76.3 |
| 2,024 | 1 | 2 | Flex fare | 91,447 | 2,104 | 0.07 | 0 | 99 |
| 2,024 | 1 | 1 | Disputa | 3,817 | 183 | 0.01 | 69.9 | 65.6 |
| 2,024 | 1 | 1 | Sin cargo | 8,120 | 142 | 0 | 58.5 | 59.2 |
| 2,024 | 2 | 2 | Disputa | 43,687 | 21,845 | 0.73 | 0 | 93.2 |
| 2,024 | 2 | 2 | Efectivo | 316,203 | 8,833 | 0.29 | 0.1 | 92.9 |
| 2,024 | 2 | 2 | Sin cargo | 10,937 | 5,471 | 0.18 | 0 | 78.9 |
| 2,024 | 2 | 2 | Flex fare | 128,238 | 4,730 | 0.16 | 0 | 99.2 |
| 2,024 | 2 | 1 | Disputa | 4,054 | 238 | 0.01 | 79.4 | 51.7 |
| 2,024 | 2 | 1 | Sin cargo | 7,974 | 130 | 0 | 56.2 | 55.4 |
| 2,024 | 3 | 2 | Disputa | 53,434 | 26,738 | 0.75 | 0 | 93.6 |
| 2,024 | 3 | 2 | Flex fare | 322,331 | 14,605 | 0.41 | 0 | 99.2 |
| 2,024 | 3 | 2 | Efectivo | 364,357 | 10,668 | 0.3 | 0.1 | 92.5 |
| 2,024 | 3 | 2 | Sin cargo | 14,148 | 7,080 | 0.2 | 0 | 80.5 |
| 2,024 | 3 | 1 | Disputa | 4,784 | 214 | 0.01 | 80.4 | 53.3 |
| 2,024 | 3 | 1 | Sin cargo | 9,310 | 132 | 0 | 52.3 | 59.8 |
| 2,024 | 4 | 2 | Disputa | 52,612 | 26,328 | 0.75 | 0 | 92.9 |
| 2,024 | 4 | 2 | Flex fare | 315,905 | 14,286 | 0.41 | 0 | 99.2 |
| 2,024 | 4 | 2 | Efectivo | 357,916 | 10,844 | 0.31 | 0.1 | 92.7 |
| 2,024 | 4 | 2 | Sin cargo | 13,657 | 6,841 | 0.19 | 0 | 78 |
| 2,024 | 4 | 1 | Disputa | 4,484 | 220 | 0.01 | 79.1 | 52.7 |
| 2,024 | 4 | 1 | Sin cargo | 8,953 | 112 | 0 | 58 | 47.3 |
| 2,024 | 4 | 1 | Desconocido | 2 | 1 | 0 | 100 | 0 |
| 2,024 | 5 | 2 | Disputa | 59,156 | 29,621 | 0.8 | 0 | 93.4 |
| 2,024 | 5 | 2 | Flex fare | 318,951 | 12,719 | 0.34 | 0 | 99.1 |
| 2,024 | 5 | 2 | Efectivo | 382,629 | 12,196 | 0.33 | 0.1 | 92.7 |
| 2,024 | 5 | 2 | Sin cargo | 14,861 | 7,446 | 0.2 | 0 | 78.3 |
| 2,024 | 5 | 1 | Disputa | 5,144 | 169 | 0 | 66.3 | 52.7 |
| 2,024 | 5 | 1 | Sin cargo | 9,633 | 160 | 0 | 56.9 | 50.6 |
| 2,024 | 6 | 2 | Disputa | 58,686 | 29,367 | 0.83 | 0 | 93.3 |
| 2,024 | 6 | 2 | Flex fare | 330,073 | 13,575 | 0.38 | 0 | 97.7 |
| 2,024 | 6 | 2 | Efectivo | 357,661 | 12,141 | 0.34 | 0.1 | 92.3 |
| 2,024 | 6 | 2 | Sin cargo | 14,738 | 7,386 | 0.21 | 0 | 80.2 |
| 2,024 | 6 | 1 | Sin cargo | 9,544 | 181 | 0.01 | 43.6 | 65.7 |
| 2,024 | 6 | 1 | Disputa | 5,089 | 161 | 0 | 77 | 52.8 |
| 2,024 | 7 | 2 | Disputa | 61,001 | 30,529 | 0.99 | 0 | 93.8 |
| 2,024 | 7 | 2 | Efectivo | 349,383 | 12,244 | 0.4 | 0 | 92.7 |
| 2,024 | 7 | 2 | Flex fare | 223,447 | 8,776 | 0.29 | 0 | 96.8 |

_... 173 filas mas (ver CSV)._

---

## 8.4 - Componentes promedio del total de un viaje amarillo, por anio y mes

**Pregunta:** Que componente explica el aumento del total entre 2024, 2025 y 2026: la tarifa, los recargos fijos, el cargo CBD o la propina?  
**Objetivo:** el total mediano sube 3 % de 2024 a 2025 y 9 % de 2025 a 2026, y el salto empieza en diciembre de 2025. Se descompone el total en sus columnas para ver cual cambia y desde que mes. Se usan promedios (y no medianas) porque los promedios de los componentes suman el promedio del total. Solo el proveedor 2, cuyo total es consistente con sus componentes (Ejercicio 3, 3.6h), y viajes con tarifa estandar (RatecodeID = 1) para no mezclar tarifas fijas de aeropuerto.  
**Fuente:** vista viajes_validos (taxi = 'yellow', vendor_id = 2, ratecode_id = 1)  
**Archivo:** `sql/ejercicio8/8_04_componentes_del_total.sql`  
**Tiempo de ejecucion:** 20.908 s - **filas del resultado:** 32

```sql
-- @id: 8.4
-- @titulo: Componentes promedio del total de un viaje amarillo, por anio y mes
-- @pregunta: Que componente explica el aumento del total entre 2024, 2025 y
--   2026: la tarifa, los recargos fijos, el cargo CBD o la propina?
-- @objetivo: el total mediano sube 3 % de 2024 a 2025 y 9 % de 2025 a 2026, y
--   el salto empieza en diciembre de 2025. Se descompone el total en sus
--   columnas para ver cual cambia y desde que mes. Se usan promedios (y no
--   medianas) porque los promedios de los componentes suman el promedio del
--   total. Solo el proveedor 2, cuyo total es consistente con sus componentes
--   (Ejercicio 3, 3.6h), y viajes con tarifa estandar (RatecodeID = 1) para
--   no mezclar tarifas fijas de aeropuerto.
-- @fuente: vista viajes_validos (taxi = 'yellow', vendor_id = 2, ratecode_id = 1)
SELECT
    anio_archivo                                                    AS anio,
    mes_archivo                                                     AS mes,
    count(*)                                                        AS viajes,
    round(avg(trip_distance), 2)                                    AS distancia,
    round(avg(fare_amount), 2)                                      AS tarifa,
    round(avg(fare_amount) / avg(trip_distance), 2)                 AS tarifa_por_milla,
    round(avg(extra), 2)                                            AS extra,
    round(avg(mta_tax), 2)                                          AS mta_tax,
    round(avg(improvement_surcharge), 2)                            AS improvement_surcharge,
    round(avg(congestion_surcharge), 2)                             AS congestion_surcharge,
    round(avg(coalesce(cbd_congestion_fee, 0)), 2)                  AS cbd_congestion_fee,
    round(avg(tolls_amount), 2)                                     AS peajes,
    round(avg(tip_amount), 2)                                       AS propina,
    round(avg(total_amount), 2)                                     AS total
FROM viajes_validos
WHERE taxi = 'yellow'
  AND vendor_id = 2
  AND ratecode_id = 1
GROUP BY ALL
ORDER BY anio, mes;
```

**Resultado:**

| anio | mes | viajes | distancia | tarifa | tarifa_por_milla | extra | mta_tax | improvement_surcharge | congestion_surcharge | cbd_congestion_fee | peajes | propina | total |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2,024 | 1 | 1,987,878 | 2.66 | 16.04 | 6.03 | 1 | 0.5 | 1 | 2.36 | 0 | 0.3 | 3.18 | 24.5 |
| 2,024 | 2 | 1,996,045 | 2.63 | 16.15 | 6.15 | 1.02 | 0.5 | 1 | 2.37 | 0 | 0.3 | 3.23 | 24.67 |
| 2,024 | 3 | 2,208,216 | 2.7 | 16.57 | 6.14 | 1.03 | 0.5 | 1 | 2.37 | 0 | 0.33 | 3.28 | 25.2 |
| 2,024 | 4 | 2,161,753 | 2.72 | 16.81 | 6.19 | 1.07 | 0.5 | 1 | 2.36 | 0 | 0.34 | 3.32 | 25.52 |
| 2,024 | 5 | 2,304,769 | 2.75 | 17.32 | 6.31 | 1.08 | 0.5 | 1 | 2.36 | 0 | 0.35 | 3.38 | 26.13 |
| 2,024 | 6 | 2,176,160 | 2.75 | 17.12 | 6.22 | 1.05 | 0.5 | 1 | 2.36 | 0 | 0.35 | 3.33 | 25.83 |
| 2,024 | 7 | 1,941,071 | 2.84 | 17.15 | 6.04 | 1.07 | 0.5 | 1 | 2.34 | 0 | 0.34 | 3.24 | 25.77 |
| 2,024 | 8 | 1,888,710 | 2.89 | 17.24 | 5.96 | 1.06 | 0.5 | 1 | 2.33 | 0 | 0.35 | 3.22 | 25.84 |
| 2,024 | 9 | 2,189,123 | 2.8 | 17.8 | 6.37 | 1.05 | 0.5 | 1 | 2.36 | 0 | 0.35 | 3.44 | 26.61 |
| 2,024 | 10 | 2,384,795 | 2.74 | 17.54 | 6.4 | 1.06 | 0.5 | 1 | 2.37 | 0 | 0.34 | 3.44 | 26.37 |
| 2,024 | 11 | 2,288,668 | 2.64 | 17.05 | 6.45 | 0.97 | 0.5 | 1 | 2.38 | 0 | 0.31 | 3.36 | 25.67 |
| 2,024 | 12 | 2,356,558 | 2.64 | 17.6 | 6.66 | 1.02 | 0.5 | 1 | 2.37 | 0 | 0.32 | 3.45 | 26.37 |
| 2,025 | 1 | 2,086,052 | 2.55 | 15.5 | 6.09 | 0.99 | 0.5 | 1 | 2.37 | 0.5 | 0.27 | 3.21 | 24.44 |
| 2,025 | 2 | 1,958,868 | 2.53 | 15.58 | 6.17 | 1 | 0.5 | 1 | 2.38 | 0.57 | 0.27 | 3.24 | 24.64 |
| 2,025 | 3 | 2,292,101 | 2.63 | 16.11 | 6.11 | 1.01 | 0.5 | 1 | 2.37 | 0.58 | 0.31 | 3.32 | 25.3 |
| 2,025 | 4 | 2,288,921 | 2.61 | 16.36 | 6.26 | 1.05 | 0.5 | 1 | 2.37 | 0.58 | 0.3 | 3.35 | 25.62 |
| 2,025 | 5 | 2,357,906 | 2.71 | 17.19 | 6.33 | 1.06 | 0.5 | 1 | 2.36 | 0.57 | 0.32 | 3.47 | 26.59 |
| 2,025 | 6 | 2,147,040 | 2.74 | 16.99 | 6.19 | 1.07 | 0.5 | 1 | 2.35 | 0.58 | 0.32 | 3.43 | 26.37 |
| 2,025 | 7 | 1,997,707 | 2.75 | 16.89 | 6.14 | 1.05 | 0.5 | 1 | 2.34 | 0.59 | 0.3 | 3.33 | 26.12 |
| 2,025 | 8 | 1,851,998 | 2.88 | 17.04 | 5.92 | 1.03 | 0.5 | 1 | 2.31 | 0.58 | 0.32 | 3.3 | 26.23 |
| 2,025 | 9 | 2,201,428 | 2.73 | 17.5 | 6.41 | 1.05 | 0.5 | 1 | 2.35 | 0.57 | 0.31 | 3.5 | 26.91 |
| 2,025 | 10 | 2,388,452 | 2.68 | 17.41 | 6.49 | 1.05 | 0.5 | 1 | 2.36 | 0.57 | 0.31 | 3.54 | 26.86 |
| 2,025 | 11 | 2,220,093 | 2.63 | 17.11 | 6.51 | 0.93 | 0.5 | 1 | 2.36 | 0.57 | 0.29 | 3.47 | 26.35 |
| 2,025 | 12 | 2,168,483 | 2.63 | 17.52 | 6.67 | 1.03 | 0.5 | 1 | 2.36 | 0.56 | 0.3 | 3.54 | 26.94 |
| 2,026 | 1 | 1,855,666 | 2.58 | 16.21 | 6.27 | 1.02 | 0.5 | 1 | 2.35 | 0.55 | 0.29 | 3.34 | 25.37 |
| 2,026 | 2 | 1,691,884 | 2.57 | 16.65 | 6.47 | 1.02 | 0.5 | 1 | 2.35 | 0.55 | 0.29 | 3.42 | 25.9 |
| 2,026 | 3 | 2,146,692 | 2.61 | 16.34 | 6.27 | 1.03 | 0.5 | 1 | 2.36 | 0.57 | 0.3 | 3.4 | 25.61 |
| 2,026 | 4 | 2,174,152 | 2.62 | 16.82 | 6.42 | 1.04 | 0.5 | 1 | 2.36 | 0.57 | 0.31 | 3.48 | 26.2 |
| 2,026 | 5 | 2,244,424 | 2.63 | 17.25 | 6.56 | 1.03 | 0.5 | 1 | 2.36 | 0.56 | 0.32 | 3.54 | 26.69 |
| 2,026 | 6 | 2,120,415 | 2.65 | 17.28 | 6.51 | 1.06 | 0.5 | 1 | 2.36 | 0.57 | 0.33 | 3.53 | 26.76 |
| 2,026 | 7 | 1,866,401 | 2.71 | 17.08 | 6.3 | 1.07 | 0.5 | 1 | 2.34 | 0.58 | 0.32 | 3.42 | 26.46 |
| 2,026 | 8 | 1,743,396 | 2.8 | 17.09 | 6.11 | 1.04 | 0.5 | 1 | 2.32 | 0.58 | 0.34 | 3.39 | 26.41 |

---

## 8.5 - Total mediano y participacion por forma de pago, amarillos, por anio (meses comunes)

**Pregunta:** El aumento del total mediano en 2026 viene de que cada tipo de viaje es mas caro o de que cambio la mezcla (mas viajes Flex Fare)?  
**Objetivo:** la consulta 8.4 muestra que en los viajes con tarifa estandar del proveedor 2 el total promedio sube solo ~3-4 % entre 2025 y 2026, mientras que el total mediano de todos los amarillos sube 9 % (I12). Se compara el total mediano de cada forma de pago con el de todos los viajes (fila "Todos", con GROUPING SETS): si cada grupo sube poco y el total sube mucho, el aumento es un efecto de composicion.  
**Fuente:** vista viajes_validos (taxi = 'yellow')  
**Archivo:** `sql/ejercicio8/8_05_precio_por_forma_de_pago.sql`  
**Tiempo de ejecucion:** 64.861 s - **filas del resultado:** 15

```sql
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
```

**Resultado:**

| anio | pago | viajes | pct_viajes | total_mediano | total_promedio | distancia_mediana |
|---|---|---|---|---|---|---|
| 2,024 | Efectivo | 3,468,580 | 13.8 | 17.53 | 24.79 | 1.61 |
| 2,025 | Efectivo | 2,842,082 | 10 | 17.82 | 24.99 | 1.58 |
| 2,026 | Efectivo | 2,544,110 | 9 | 18.47 | 26.04 | 1.59 |
| 2,024 | Flex fare / sin dato | 2,291,051 | 9.1 | 22.27 | 25.18 | 2.44 |
| 2,025 | Flex fare / sin dato | 5,624,390 | 19.7 | 22.8 | 25.53 | 2.69 |
| 2,026 | Flex fare / sin dato | 7,033,453 | 25 | 29.15 | 32.44 | 2.89 |
| 2,024 | Otros | 321,582 | 1.3 | 17.2 | 26.74 | 1.47 |
| 2,025 | Otros | 471,475 | 1.7 | 18.54 | 30.85 | 1.58 |
| 2,026 | Otros | 172,077 | 0.6 | 17.84 | 27.48 | 1.43 |
| 2,024 | Tarjeta | 19,141,986 | 75.9 | 21.42 | 29.41 | 1.77 |
| 2,025 | Tarjeta | 19,570,748 | 68.6 | 21.91 | 29.66 | 1.73 |
| 2,026 | Tarjeta | 18,377,834 | 65.3 | 22.38 | 30.04 | 1.71 |
| 2,024 | Todos | 25,223,199 | 100 | 20.97 | 28.36 | 1.8 |
| 2,025 | Todos | 28,508,695 | 100 | 21.65 | 28.4 | 1.87 |
| 2,026 | Todos | 28,127,474 | 100 | 23.61 | 30.26 | 1.93 |
