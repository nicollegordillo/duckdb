# Resultados de sql/ejercicio4

Generado automaticamente el 2026-10-06T00:15:39 con `python scripts/run_sql.py ejercicio4`.
No editar a mano: volver a ejecutar el script tras cambiar las consultas.

DuckDB 1.5.5

## P1 - Volumen mensual de viajes por tipo de taxi

**Pregunta:** Como evoluciona la cantidad de viajes mes a mes y que proporcion del total corresponde a cada tipo de taxi?  
**Justificacion:** Los datos llegan en archivos mensuales; el volumen por mes es la serie temporal basica y revela estacionalidad, meses incompletos y el peso relativo de amarillos vs. verdes.  
**Fuente:** vista viajes_validos (data/raw/*/*/*.parquet)  
**Archivo:** `sql/ejercicio4/4_01_viajes_por_mes.sql`  
**Tiempo de ejecucion:** 5.728 s - **filas del resultado:** 16

```sql
-- @id: P1
-- @titulo: Volumen mensual de viajes por tipo de taxi
-- @pregunta: Como evoluciona la cantidad de viajes mes a mes y que proporcion
--   del total corresponde a cada tipo de taxi?
-- @justificacion: Los datos llegan en archivos mensuales; el volumen por mes es
--   la serie temporal basica y revela estacionalidad, meses incompletos y el
--   peso relativo de amarillos vs. verdes.
-- @fuente: vista viajes_validos (data/raw/*/*/*.parquet)
SELECT
    date_trunc('month', pickup_at)::DATE                        AS mes,
    taxi,
    count(*)                                                    AS viajes,
    round(count(*) / count(DISTINCT fecha), 0)                  AS viajes_por_dia,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY date_trunc('month', pickup_at)::DATE), 2)
                                                                AS pct_del_mes
FROM viajes_validos
GROUP BY 1, 2
ORDER BY mes, taxi DESC;
```

**Resultado:**

| mes | taxi | viajes | viajes_por_dia | pct_del_mes |
|---|---|---|---|---|
| 2026-01-01 00:00:00 | yellow | 3,500,703 | 112,926 | 98.94 |
| 2026-01-01 00:00:00 | green | 37,567 | 1,212 | 1.06 |
| 2026-02-01 00:00:00 | yellow | 3,196,364 | 114,156 | 98.93 |
| 2026-02-01 00:00:00 | green | 34,593 | 1,235 | 1.07 |
| 2026-03-01 00:00:00 | yellow | 3,748,151 | 120,908 | 98.91 |
| 2026-03-01 00:00:00 | green | 41,154 | 1,328 | 1.09 |
| 2026-04-01 00:00:00 | yellow | 3,660,483 | 122,016 | 98.89 |
| 2026-04-01 00:00:00 | green | 41,085 | 1,370 | 1.11 |
| 2026-05-01 00:00:00 | yellow | 3,897,714 | 125,733 | 98.94 |
| 2026-05-01 00:00:00 | green | 41,794 | 1,348 | 1.06 |
| 2026-06-01 00:00:00 | yellow | 3,633,908 | 121,130 | 98.88 |
| 2026-06-01 00:00:00 | green | 41,011 | 1,367 | 1.12 |
| 2026-07-01 00:00:00 | yellow | 3,335,678 | 107,603 | 98.87 |
| 2026-07-01 00:00:00 | green | 38,019 | 1,226 | 1.13 |
| 2026-08-01 00:00:00 | yellow | 3,154,473 | 101,757 | 98.82 |
| 2026-08-01 00:00:00 | green | 37,554 | 1,211 | 1.18 |

---

## P2 - Demanda por hora del dia y dia de la semana

**Pregunta:** En que horas y dias se concentra la demanda y difiere el patron entre taxis amarillos y verdes?  
**Justificacion:** El pickup trae fecha y hora exactas; el patron hora x dia distingue viajes de trabajo (picos entre semana) de ocio (noches de fin de semana). Se normaliza a % del total de cada tipo para comparar tipos con volumenes muy distintos.  
**Fuente:** vista viajes_validos  
**Archivo:** `sql/ejercicio4/4_02_hora_dia_semana.sql`  
**Tiempo de ejecucion:** 4.486 s - **filas del resultado:** 336

```sql
-- @id: P2
-- @titulo: Demanda por hora del dia y dia de la semana
-- @pregunta: En que horas y dias se concentra la demanda y difiere el patron
--   entre taxis amarillos y verdes?
-- @justificacion: El pickup trae fecha y hora exactas; el patron hora x dia
--   distingue viajes de trabajo (picos entre semana) de ocio (noches de fin de
--   semana). Se normaliza a % del total de cada tipo para comparar tipos con
--   volumenes muy distintos.
-- @fuente: vista viajes_validos
SELECT
    taxi,
    dia_semana,                                   -- 1 = lunes ... 7 = domingo
    hora,
    count(*)                                                        AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi), 3) AS pct_del_tipo
FROM viajes_validos
GROUP BY taxi, dia_semana, hora
ORDER BY taxi DESC, dia_semana, hora;
```

**Resultado:**

| taxi | dia_semana | hora | viajes | pct_del_tipo |
|---|---|---|---|---|
| yellow | 1 | 0 | 66,807 | 0.238 |
| yellow | 1 | 1 | 34,304 | 0.122 |
| yellow | 1 | 2 | 19,450 | 0.069 |
| yellow | 1 | 3 | 15,138 | 0.054 |
| yellow | 1 | 4 | 20,488 | 0.073 |
| yellow | 1 | 5 | 38,600 | 0.137 |
| yellow | 1 | 6 | 77,412 | 0.275 |
| yellow | 1 | 7 | 138,217 | 0.491 |
| yellow | 1 | 8 | 179,626 | 0.639 |
| yellow | 1 | 9 | 169,195 | 0.602 |
| yellow | 1 | 10 | 159,295 | 0.566 |
| yellow | 1 | 11 | 165,796 | 0.589 |
| yellow | 1 | 12 | 176,676 | 0.628 |
| yellow | 1 | 13 | 181,098 | 0.644 |
| yellow | 1 | 14 | 202,041 | 0.718 |
| yellow | 1 | 15 | 212,743 | 0.756 |
| yellow | 1 | 16 | 198,470 | 0.706 |
| yellow | 1 | 17 | 223,360 | 0.794 |
| yellow | 1 | 18 | 221,251 | 0.787 |
| yellow | 1 | 19 | 191,695 | 0.682 |
| yellow | 1 | 20 | 197,789 | 0.703 |
| yellow | 1 | 21 | 194,746 | 0.692 |
| yellow | 1 | 22 | 155,547 | 0.553 |
| yellow | 1 | 23 | 103,095 | 0.367 |
| yellow | 2 | 0 | 58,713 | 0.209 |
| yellow | 2 | 1 | 27,125 | 0.096 |
| yellow | 2 | 2 | 14,552 | 0.052 |
| yellow | 2 | 3 | 9,620 | 0.034 |
| yellow | 2 | 4 | 13,676 | 0.049 |
| yellow | 2 | 5 | 32,960 | 0.117 |
| yellow | 2 | 6 | 76,946 | 0.274 |
| yellow | 2 | 7 | 151,144 | 0.537 |
| yellow | 2 | 8 | 203,067 | 0.722 |
| yellow | 2 | 9 | 196,661 | 0.699 |
| yellow | 2 | 10 | 181,248 | 0.644 |
| yellow | 2 | 11 | 185,680 | 0.66 |
| yellow | 2 | 12 | 194,812 | 0.693 |
| yellow | 2 | 13 | 200,281 | 0.712 |
| yellow | 2 | 14 | 221,629 | 0.788 |
| yellow | 2 | 15 | 232,903 | 0.828 |

_... 296 filas mas (ver CSV)._

---

## P3 - Distribucion de distancia, duracion, velocidad y monto

**Pregunta:** Como es un viaje tipico (distancia, duracion, velocidad, costo) y en que se diferencian los viajes de taxis amarillos y verdes?  
**Justificacion:** Estas variables son muy asimetricas (muchos viajes cortos y pocos muy largos), por lo que se reportan percentiles ademas del promedio: si el promedio esta muy por encima de la mediana, la cola derecha pesa. Nota: las estadisticas se calculan en una sola lectura de viajes_validos y solo el resultado (8 filas) se reorganiza en formato largo; expandir primero los 30 millones de filas x 4 variables agotaba la memoria. Se usa approx_quantile (algoritmo T-Digest) en lugar de median / quantile_cont. El calculo exacto necesita guardar en memoria todos los valores (~30 millones por variable) y se quedo sin memoria en el contenedor; approx_quantile usa memoria constante con un error minimo, despreciable para describir distribuciones.  
**Fuente:** vista viajes_validos  
**Archivo:** `sql/ejercicio4/4_03_caracteristicas_viaje.sql`  
**Tiempo de ejecucion:** 8.628 s - **filas del resultado:** 8

```sql
-- @id: P3
-- @titulo: Distribucion de distancia, duracion, velocidad y monto
-- @pregunta: Como es un viaje tipico (distancia, duracion, velocidad, costo) y
--   en que se diferencian los viajes de taxis amarillos y verdes?
-- @justificacion: Estas variables son muy asimetricas (muchos viajes cortos y
--   pocos muy largos), por lo que se reportan percentiles ademas del promedio:
--   si el promedio esta muy por encima de la mediana, la cola derecha pesa.
-- Nota: las estadisticas se calculan en una sola lectura de viajes_validos
--   y solo el resultado (8 filas) se reorganiza en formato largo; expandir
--   primero los 30 millones de filas x 4 variables agotaba la memoria.
--   Se usa approx_quantile (algoritmo T-Digest) en lugar de median /
--   quantile_cont. El calculo exacto necesita guardar en memoria todos los
--   valores (~30 millones por variable) y se quedo sin memoria en el
--   contenedor; approx_quantile usa memoria constante con un error minimo,
--   despreciable para describir distribuciones.
-- @fuente: vista viajes_validos
WITH stats AS (
    SELECT
        taxi,
        approx_quantile(trip_distance, [0.10, 0.25, 0.50, 0.75, 0.90, 0.99]) AS q_dist,
        avg(trip_distance)  AS avg_dist,  max(trip_distance)  AS max_dist,
        approx_quantile(duracion_min,  [0.10, 0.25, 0.50, 0.75, 0.90, 0.99]) AS q_dur,
        avg(duracion_min)   AS avg_dur,   max(duracion_min)   AS max_dur,
        approx_quantile(velocidad_mph, [0.10, 0.25, 0.50, 0.75, 0.90, 0.99]) AS q_vel,
        avg(velocidad_mph)  AS avg_vel,   max(velocidad_mph)  AS max_vel,
        approx_quantile(total_amount,  [0.10, 0.25, 0.50, 0.75, 0.90, 0.99]) AS q_tot,
        avg(total_amount)   AS avg_tot,   max(total_amount)   AS max_tot
    FROM viajes_validos
    GROUP BY taxi
), largo AS (
    SELECT taxi, 'distancia_mi'  AS variable, q_dist AS q, avg_dist AS promedio, max_dist AS maximo FROM stats
    UNION ALL SELECT taxi, 'duracion_min',  q_dur, avg_dur, max_dur FROM stats
    UNION ALL SELECT taxi, 'velocidad_mph', q_vel, avg_vel, max_vel FROM stats
    UNION ALL SELECT taxi, 'total_usd',     q_tot, avg_tot, max_tot FROM stats
)
SELECT
    variable,
    taxi,
    round(q[1], 2)        AS p10,
    round(q[2], 2)        AS p25,
    round(q[3], 2)        AS mediana,
    round(promedio, 2)    AS promedio,
    round(q[4], 2)        AS p75,
    round(q[5], 2)        AS p90,
    round(q[6], 2)        AS p99,
    round(maximo, 2)      AS maximo
FROM largo
ORDER BY variable, taxi DESC;
```

**Resultado:**

| variable | taxi | p10 | p25 | mediana | promedio | p75 | p90 | p99 | maximo |
|---|---|---|---|---|---|---|---|---|---|
| distancia_mi | yellow | 0.69 | 1.1 | 1.94 | 3.51 | 3.96 | 8.69 | 19.57 | 99.93 |
| distancia_mi | green | 0.86 | 1.32 | 2.13 | 3.31 | 3.72 | 7.37 | 17.68 | 94.1 |
| duracion_min | yellow | 5.39 | 8.62 | 14.12 | 17.69 | 22.27 | 33.4 | 71.38 | 360 |
| duracion_min | green | 5.67 | 8.66 | 13.23 | 17.06 | 20.38 | 32.03 | 73.98 | 359.33 |
| total_usd | yellow | 13.97 | 17.49 | 23.62 | 30.26 | 34.47 | 54.67 | 105.31 | 1,065.72 |
| total_usd | green | 11.47 | 15.07 | 20.51 | 25.37 | 29.56 | 44.57 | 95.6 | 625.1 |
| velocidad_mph | yellow | 4.98 | 6.83 | 9.28 | 10.88 | 12.93 | 19.06 | 34.31 | 80 |
| velocidad_mph | green | 6.27 | 7.96 | 10.04 | 11.37 | 13.09 | 18.23 | 31.71 | 80 |

---

## P4 - Comparacion general entre taxis amarillos y verdes

**Pregunta:** En que se diferencian amarillos y verdes en volumen, distancia, costo, pasajeros, propina y cargos especiales?  
**Justificacion:** Los taxis verdes (boro taxis) operan con reglas distintas a los amarillos; un resumen lado a lado de las metricas clave cuantifica esa diferencia. Nota: se usa approx_quantile (algoritmo T-Digest) en lugar de median / quantile_cont. El calculo exacto necesita guardar en memoria todos los valores (~30 millones por variable) y se quedo sin memoria en el contenedor; approx_quantile usa memoria constante con un error minimo, despreciable para describir distribuciones.  
**Fuente:** vista viajes_validos  
**Archivo:** `sql/ejercicio4/4_04_resumen_por_tipo.sql`  
**Tiempo de ejecucion:** 6.518 s - **filas del resultado:** 2

```sql
-- @id: P4
-- @titulo: Comparacion general entre taxis amarillos y verdes
-- @pregunta: En que se diferencian amarillos y verdes en volumen, distancia,
--   costo, pasajeros, propina y cargos especiales?
-- @justificacion: Los taxis verdes (boro taxis) operan con reglas distintas a
--   los amarillos; un resumen lado a lado de las metricas clave cuantifica esa
--   diferencia.
-- Nota: se usa approx_quantile (algoritmo T-Digest) en lugar de median /
--   quantile_cont. El calculo exacto necesita guardar en memoria todos los
--   valores (~30 millones por variable) y se quedo sin memoria en el
--   contenedor; approx_quantile usa memoria constante con un error minimo,
--   despreciable para describir distribuciones.
-- @fuente: vista viajes_validos
SELECT
    taxi,
    count(*)                                                        AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER (), 2)              AS pct_viajes,
    round(avg(trip_distance), 2)                                    AS distancia_prom_mi,
    round(approx_quantile(duracion_min, 0.5), 1)                                  AS duracion_mediana_min,
    round(avg(total_amount), 2)                                     AS total_prom_usd,
    round(avg(total_amount / nullif(trip_distance, 0)), 2)          AS usd_por_milla_prom,
    round(avg(passenger_count), 2)                                  AS pasajeros_prom,
    round(100.0 * avg((payment_type = 1)::INT), 1)                  AS pct_tarjeta,
    round(100.0 * avg((coalesce(airport_fee, 0) > 0 OR ratecode_id IN (2, 3))::INT), 2)
                                                                    AS pct_aeropuerto,
    round(100.0 * avg((coalesce(cbd_congestion_fee, 0) > 0)::INT), 1) AS pct_cargo_cbd
FROM viajes_validos
GROUP BY taxi
ORDER BY viajes DESC;
```

**Resultado:**

| taxi | viajes | pct_viajes | distancia_prom_mi | duracion_mediana_min | total_prom_usd | usd_por_milla_prom | pasajeros_prom | pct_tarjeta | pct_aeropuerto | pct_cargo_cbd |
|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 28,127,474 | 98.9 | 3.51 | 14.1 | 30.26 | 34.46 | 1.25 | 65.3 | 9.74 | 72.4 |
| green | 312,777 | 1.1 | 3.31 | 13.2 | 25.37 | 20.53 | 1.32 | 76.8 | 0.29 | 8.5 |

---

## P5 - Origen de los viajes por borough

**Pregunta:** Desde que boroughs se originan los viajes de cada tipo de taxi?  
**Justificacion:** Los taxis verdes fueron creados para atender zonas fuera del centro de Manhattan; cruzar PULocationID con el catalogo de zonas permite comprobar si la distribucion geografica refleja esa regla.  
**Fuente:** vista viajes_validos + vista zonas (data/raw/zonas/taxi_zone_lookup.csv)  
**Archivo:** `sql/ejercicio4/4_05_viajes_por_borough.sql`  
**Tiempo de ejecucion:** 5.009 s - **filas del resultado:** 15

```sql
-- @id: P5
-- @titulo: Origen de los viajes por borough
-- @pregunta: Desde que boroughs se originan los viajes de cada tipo de taxi?
-- @justificacion: Los taxis verdes fueron creados para atender zonas fuera del
--   centro de Manhattan; cruzar PULocationID con el catalogo de zonas permite
--   comprobar si la distribucion geografica refleja esa regla.
-- @fuente: vista viajes_validos + vista zonas (data/raw/zonas/taxi_zone_lookup.csv)
SELECT
    v.taxi,
    coalesce(z.borough, 'Sin zona')                                 AS borough_origen,
    count(*)                                                        AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY v.taxi), 2) AS pct_del_tipo
FROM viajes_validos v
LEFT JOIN zonas z ON z.location_id = v.pu_location_id
GROUP BY 1, 2
ORDER BY v.taxi DESC, viajes DESC;
```

**Resultado:**

| taxi | borough_origen | viajes | pct_del_tipo |
|---|---|---|---|
| yellow | Manhattan | 24,366,104 | 86.63 |
| yellow | Queens | 2,491,392 | 8.86 |
| yellow | Brooklyn | 1,014,059 | 3.61 |
| yellow | Bronx | 217,585 | 0.77 |
| yellow | Unknown | 28,772 | 0.1 |
| yellow | N/A | 6,097 | 0.02 |
| yellow | Staten Island | 2,580 | 0.01 |
| yellow | EWR | 885 | 0 |
| green | Manhattan | 188,657 | 60.32 |
| green | Queens | 69,753 | 22.3 |
| green | Brooklyn | 46,813 | 14.97 |
| green | Bronx | 7,098 | 2.27 |
| green | Unknown | 248 | 0.08 |
| green | N/A | 159 | 0.05 |
| green | Staten Island | 49 | 0.02 |

---

## P6 - Metodo de pago y propina registrada

**Pregunta:** Como se distribuyen los metodos de pago por tipo de taxi y como cambia la propina registrada segun el metodo?  
**Justificacion:** payment_type y tip_amount son las variables de pago clave. Se espera que la propina en efectivo no quede registrada, lo que sesgaria cualquier analisis de propinas que no separe por metodo. Nota: se usa approx_quantile (algoritmo T-Digest) en lugar de median / quantile_cont. El calculo exacto necesita guardar en memoria todos los valores (~30 millones por variable) y se quedo sin memoria en el contenedor; approx_quantile usa memoria constante con un error minimo, despreciable para describir distribuciones.  
**Fuente:** vista viajes_validos  
**Archivo:** `sql/ejercicio4/4_06_metodo_pago.sql`  
**Tiempo de ejecucion:** 6.081 s - **filas del resultado:** 10

```sql
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
```

**Resultado:**

| taxi | payment_type | metodo_pago | viajes | pct_del_tipo | total_prom_usd | pct_con_propina | propina_mediana_pct |
|---|---|---|---|---|---|---|---|
| yellow | 1 | Tarjeta | 18,377,834 | 65.34 | 30.04 | 91.1 | 26.4 |
| yellow | 0 | Flex fare | 7,033,453 | 25.01 | 32.44 | 8.3 | 0 |
| yellow | 2 | Efectivo | 2,544,110 | 9.04 | 26.04 | 0 | 0 |
| yellow | 4 | Disputa | 117,357 | 0.42 | 28.86 | 0 | 0 |
| yellow | 3 | Sin cargo | 54,720 | 0.19 | 24.5 | 0 | 0 |
| green | 1 | Tarjeta | 207,581 | 66.37 | 25.6 | 91.5 | 23.6 |
| green | 2 | Efectivo | 61,702 | 19.73 | 20.81 | 0 | 0 |
| green | <NA> | Sin dato | 42,664 | 13.64 | 30.99 | 17.3 | 0 |
| green | 3 | Sin cargo | 587 | 0.19 | 18.12 | 0.3 | 0 |
| green | 4 | Disputa | 243 | 0.08 | 19.96 | 0 | 0 |

---

## P7 - Distribucion del porcentaje de propina (pagos con tarjeta)

**Pregunta:** Que porcentaje de propina dejan los pasajeros que pagan con tarjeta y se concentra en valores particulares?  
**Justificacion:** Solo los pagos con tarjeta registran la propina de forma confiable (ver P6). Agrupar en rangos muestra si los pasajeros eligen los porcentajes sugeridos por la pantalla del taxi.  
**Fuente:** vista viajes_validos (payment_type = 1)  
**Archivo:** `sql/ejercicio4/4_07_distribucion_propina.sql`  
**Tiempo de ejecucion:** 4.899 s - **filas del resultado:** 18

```sql
-- @id: P7
-- @titulo: Distribucion del porcentaje de propina (pagos con tarjeta)
-- @pregunta: Que porcentaje de propina dejan los pasajeros que pagan con
--   tarjeta y se concentra en valores particulares?
-- @justificacion: Solo los pagos con tarjeta registran la propina de forma
--   confiable (ver P6). Agrupar en rangos muestra si los pasajeros eligen los
--   porcentajes sugeridos por la pantalla del taxi.
-- @fuente: vista viajes_validos (payment_type = 1)
SELECT
    taxi,
    CASE
        WHEN pct_propina = 0     THEN '0 %'
        WHEN pct_propina < 0.15  THEN '(0, 15) %'
        WHEN pct_propina < 0.19  THEN '[15, 19) %'
        WHEN pct_propina < 0.21  THEN '[19, 21) %'
        WHEN pct_propina < 0.24  THEN '[21, 24) %'
        WHEN pct_propina < 0.26  THEN '[24, 26) %'
        WHEN pct_propina < 0.29  THEN '[26, 29) %'
        WHEN pct_propina < 0.31  THEN '[29, 31) %'
        ELSE '>= 31 %'
    END                                                             AS rango_propina,
    min(pct_propina)                                                AS orden,
    count(*)                                                        AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi), 2) AS pct_del_tipo
FROM viajes_validos
WHERE payment_type = 1 AND pct_propina IS NOT NULL
GROUP BY taxi, rango_propina
ORDER BY taxi DESC, orden;
```

**Resultado:**

| taxi | rango_propina | orden | viajes | pct_del_tipo |
|---|---|---|---|---|
| yellow | 0 % | 0 | 1,631,472 | 8.88 |
| yellow | (0, 15) % | 0 | 2,080,340 | 11.32 |
| yellow | [15, 19) % | 0.15 | 939,523 | 5.11 |
| yellow | [19, 21) % | 0.19 | 533,465 | 2.9 |
| yellow | [21, 24) % | 0.21 | 1,665,668 | 9.06 |
| yellow | [24, 26) % | 0.24 | 1,916,058 | 10.43 |
| yellow | [26, 29) % | 0.26 | 3,038,234 | 16.53 |
| yellow | [29, 31) % | 0.29 | 1,543,501 | 8.4 |
| yellow | >= 31 % | 0.31 | 5,029,573 | 27.37 |
| green | 0 % | 0 | 17,631 | 8.49 |
| green | (0, 15) % | 0.0001 | 26,507 | 12.77 |
| green | [15, 19) % | 0.15 | 11,191 | 5.39 |
| green | [19, 21) % | 0.1901 | 7,033 | 3.39 |
| green | [21, 24) % | 0.21 | 46,287 | 22.3 |
| green | [24, 26) % | 0.24 | 26,541 | 12.79 |
| green | [26, 29) % | 0.26 | 27,983 | 13.48 |
| green | [29, 31) % | 0.29 | 13,463 | 6.49 |
| green | >= 31 % | 0.31 | 30,945 | 14.91 |

---

## P8 - Histograma del monto total del viaje

**Pregunta:** Como se distribuye el monto total cobrado y hay concentraciones en valores especificos (p. ej. tarifas fijas)?  
**Justificacion:** total_amount es la variable de negocio principal. Un histograma en intervalos de 5 USD muestra la forma de la distribucion y picos asociados a tarifas fijas como la del aeropuerto JFK.  
**Fuente:** vista viajes_validos  
**Archivo:** `sql/ejercicio4/4_08_histograma_total.sql`  
**Tiempo de ejecucion:** 4.576 s - **filas del resultado:** 62

```sql
-- @id: P8
-- @titulo: Histograma del monto total del viaje
-- @pregunta: Como se distribuye el monto total cobrado y hay concentraciones
--   en valores especificos (p. ej. tarifas fijas)?
-- @justificacion: total_amount es la variable de negocio principal. Un
--   histograma en intervalos de 5 USD muestra la forma de la distribucion y
--   picos asociados a tarifas fijas como la del aeropuerto JFK.
-- @fuente: vista viajes_validos
SELECT
    taxi,
    least(floor(total_amount / 5) * 5, 150)                        AS desde_usd,
    count(*)                                                        AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi), 3) AS pct_del_tipo
FROM viajes_validos
GROUP BY 1, 2
ORDER BY taxi DESC, desde_usd;
-- El ultimo intervalo (150) agrupa todos los viajes de 150 USD o mas.
```

**Resultado:**

| taxi | desde_usd | viajes | pct_del_tipo |
|---|---|---|---|
| yellow | 0 | 2,760 | 0.01 |
| yellow | 5 | 318,042 | 1.131 |
| yellow | 10 | 3,587,800 | 12.756 |
| yellow | 15 | 6,290,052 | 22.363 |
| yellow | 20 | 5,188,535 | 18.447 |
| yellow | 25 | 3,565,310 | 12.676 |
| yellow | 30 | 2,376,615 | 8.449 |
| yellow | 35 | 1,646,879 | 5.855 |
| yellow | 40 | 1,105,453 | 3.93 |
| yellow | 45 | 753,223 | 2.678 |
| yellow | 50 | 502,177 | 1.785 |
| yellow | 55 | 388,975 | 1.383 |
| yellow | 60 | 329,462 | 1.171 |
| yellow | 65 | 292,803 | 1.041 |
| yellow | 70 | 263,170 | 0.936 |
| yellow | 75 | 213,819 | 0.76 |
| yellow | 80 | 232,720 | 0.827 |
| yellow | 85 | 185,388 | 0.659 |
| yellow | 90 | 186,389 | 0.663 |
| yellow | 95 | 194,831 | 0.693 |
| yellow | 100 | 221,728 | 0.788 |
| yellow | 105 | 93,171 | 0.331 |
| yellow | 110 | 36,018 | 0.128 |
| yellow | 115 | 25,348 | 0.09 |
| yellow | 120 | 20,289 | 0.072 |
| yellow | 125 | 15,581 | 0.055 |
| yellow | 130 | 12,860 | 0.046 |
| yellow | 135 | 10,767 | 0.038 |
| yellow | 140 | 8,784 | 0.031 |
| yellow | 145 | 7,609 | 0.027 |
| yellow | 150 | 50,916 | 0.181 |
| green | 0 | 527 | 0.168 |
| green | 5 | 15,702 | 5.02 |
| green | 10 | 59,743 | 19.101 |
| green | 15 | 73,975 | 23.651 |
| green | 20 | 51,496 | 16.464 |
| green | 25 | 35,468 | 11.34 |
| green | 30 | 22,110 | 7.069 |
| green | 35 | 13,264 | 4.241 |
| green | 40 | 9,861 | 3.153 |

_... 22 filas mas (ver CSV)._

---

## P9 - Registros atipicos o inconsistentes por regla, tipo y mes

**Pregunta:** Que proporcion de los registros es atipica o inconsistente, que regla la explica y cambia entre tipos de taxi o meses?  
**Justificacion:** Cuantifica el efecto de los filtros definidos a partir del Ejercicio 3 (sql/00_vistas.sql). Un mes o tipo con un porcentaje mucho mayor de registros invalidos indicaria un problema de captura especifico.  
**Fuente:** vista viajes_enriquecidos (sin filtrar)  
**Archivo:** `sql/ejercicio4/4_09_impacto_reglas_calidad.sql`  
**Tiempo de ejecucion:** 4.317 s - **filas del resultado:** 16

```sql
-- @id: P9
-- @titulo: Registros atipicos o inconsistentes por regla, tipo y mes
-- @pregunta: Que proporcion de los registros es atipica o inconsistente, que
--   regla la explica y cambia entre tipos de taxi o meses?
-- @justificacion: Cuantifica el efecto de los filtros definidos a partir del
--   Ejercicio 3 (sql/00_vistas.sql). Un mes o tipo con un porcentaje mucho mayor
--   de registros invalidos indicaria un problema de captura especifico.
-- @fuente: vista viajes_enriquecidos (sin filtrar)
SELECT
    taxi,
    make_date(anio_archivo, mes_archivo, 1)                         AS mes_archivo,
    count(*)                                                        AS registros,
    count(*) FILTER (WHERE f_fuera_periodo)                         AS fuera_periodo,
    count(*) FILTER (WHERE f_duracion)                              AS duracion,
    count(*) FILTER (WHERE f_distancia)                             AS distancia,
    count(*) FILTER (WHERE f_velocidad)                             AS velocidad,
    count(*) FILTER (WHERE f_monto)                                 AS monto,
    count(*) FILTER (WHERE f_pasajeros)                             AS pasajeros,
    count(*) FILTER (WHERE f_fuera_periodo OR f_duracion OR f_distancia
                     OR f_velocidad OR f_monto OR f_pasajeros)      AS con_algun_problema,
    round(100.0 * count(*) FILTER (WHERE f_fuera_periodo OR f_duracion OR f_distancia
                     OR f_velocidad OR f_monto OR f_pasajeros) / count(*), 2) AS pct_excluido
FROM viajes_enriquecidos
GROUP BY ALL
ORDER BY taxi DESC, mes_archivo;
```

**Resultado:**

| taxi | mes_archivo | registros | fuera_periodo | duracion | distancia | velocidad | monto | pasajeros | con_algun_problema | pct_excluido |
|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 2026-01-01 00:00:00 | 3,724,889 | 7 | 46,379 | 125,900 | 874 | 41,592 | 14,787 | 224,186 | 6.02 |
| yellow | 2026-02-01 00:00:00 | 3,399,866 | 16 | 41,720 | 123,422 | 762 | 29,171 | 12,884 | 203,502 | 5.99 |
| yellow | 2026-03-01 00:00:00 | 3,952,451 | 19 | 49,947 | 121,371 | 1,126 | 23,802 | 12,967 | 204,300 | 5.17 |
| yellow | 2026-04-01 00:00:00 | 3,831,240 | 12 | 50,364 | 93,651 | 1,146 | 17,300 | 11,692 | 170,757 | 4.46 |
| yellow | 2026-05-01 00:00:00 | 4,090,836 | 14 | 53,028 | 113,167 | 1,020 | 17,329 | 12,533 | 193,122 | 4.72 |
| yellow | 2026-06-01 00:00:00 | 3,837,248 | 17 | 50,664 | 128,255 | 992 | 16,934 | 10,416 | 203,340 | 5.3 |
| yellow | 2026-07-01 00:00:00 | 3,530,109 | 46 | 43,059 | 128,494 | 1,148 | 16,969 | 8,602 | 194,431 | 5.51 |
| yellow | 2026-08-01 00:00:00 | 3,336,716 | 15 | 43,837 | 119,194 | 919 | 17,289 | 7,478 | 182,243 | 5.46 |
| green | 2026-01-01 00:00:00 | 40,272 | 22 | 140 | 1,297 | 144 | 679 | 562 | 2,705 | 6.72 |
| green | 2026-02-01 00:00:00 | 37,373 | 11 | 138 | 1,400 | 151 | 663 | 567 | 2,780 | 7.44 |
| green | 2026-03-01 00:00:00 | 44,208 | 9 | 209 | 1,439 | 145 | 828 | 584 | 3,054 | 6.91 |
| green | 2026-04-01 00:00:00 | 44,238 | 3 | 213 | 1,613 | 156 | 821 | 543 | 3,153 | 7.13 |
| green | 2026-05-01 00:00:00 | 44,921 | 10 | 207 | 1,571 | 151 | 769 | 600 | 3,127 | 6.96 |
| green | 2026-06-01 00:00:00 | 44,163 | 13 | 173 | 1,503 | 158 | 886 | 560 | 3,152 | 7.14 |
| green | 2026-07-01 00:00:00 | 41,252 | 16 | 140 | 1,658 | 136 | 837 | 586 | 3,233 | 7.84 |
| green | 2026-08-01 00:00:00 | 40,687 | 14 | 118 | 1,803 | 117 | 713 | 525 | 3,133 | 7.7 |

---

## P10 - Valores atipicos de costo por milla (regla de Tukey / IQR)

**Pregunta:** Entre los viajes que pasan los filtros basicos, cuantos tienen un costo por milla atipico y como son esos viajes?  
**Justificacion:** Los filtros de P9 solo eliminan valores imposibles. La regla IQR (fuera de Q1 - 1.5*IQR, Q3 + 1.5*IQR) detecta valores posibles pero inusuales; el costo por milla combina tarifa y distancia, asi que capta viajes con distancia mal registrada o tarifas fijas. Nota: se lee viajes_validos dos veces (limites y conteo) en lugar de guardar una CTE intermedia con los 30 millones de viajes, que DuckDB materializaba en memoria por usarse dos veces. Se usa approx_quantile (algoritmo T-Digest) en lugar de median / quantile_cont. El calculo exacto necesita guardar en memoria todos los valores (~30 millones por variable) y se quedo sin memoria en el contenedor; approx_quantile usa memoria constante con un error minimo, despreciable para describir distribuciones.  
**Fuente:** vista viajes_validos  
**Archivo:** `sql/ejercicio4/4_10_atipicos_tarifa_milla.sql`  
**Tiempo de ejecucion:** 10.801 s - **filas del resultado:** 2

```sql
-- @id: P10
-- @titulo: Valores atipicos de costo por milla (regla de Tukey / IQR)
-- @pregunta: Entre los viajes que pasan los filtros basicos, cuantos tienen un
--   costo por milla atipico y como son esos viajes?
-- @justificacion: Los filtros de P9 solo eliminan valores imposibles. La regla
--   IQR (fuera de Q1 - 1.5*IQR, Q3 + 1.5*IQR) detecta valores posibles pero
--   inusuales; el costo por milla combina tarifa y distancia, asi que capta
--   viajes con distancia mal registrada o tarifas fijas.
-- Nota: se lee viajes_validos dos veces (limites y conteo) en lugar de
--   guardar una CTE intermedia con los 30 millones de viajes, que DuckDB
--   materializaba en memoria por usarse dos veces.
--   Se usa approx_quantile (algoritmo T-Digest) en lugar de median /
--   quantile_cont. El calculo exacto necesita guardar en memoria todos los
--   valores (~30 millones por variable) y se quedo sin memoria en el
--   contenedor; approx_quantile usa memoria constante con un error minimo,
--   despreciable para describir distribuciones.
-- @fuente: vista viajes_validos
WITH limites AS (
    SELECT
        taxi,
        approx_quantile(fare_amount / trip_distance, 0.25) AS q1,
        approx_quantile(fare_amount / trip_distance, 0.75) AS q3
    FROM viajes_validos
    GROUP BY taxi
), lim AS (
    SELECT taxi, q1, q3,
           q1 - 1.5 * (q3 - q1) AS limite_inf,
           q3 + 1.5 * (q3 - q1) AS limite_sup
    FROM limites
)
SELECT
    v.taxi,
    round(any_value(l.q1), 2)                                       AS q1,
    round(any_value(l.q3), 2)                                       AS q3,
    round(any_value(l.limite_inf), 2)                               AS limite_inf,
    round(any_value(l.limite_sup), 2)                               AS limite_sup,
    count(*)                                                        AS viajes,
    count(*) FILTER (WHERE v.fare_amount / v.trip_distance > l.limite_sup) AS atipicos_altos,
    count(*) FILTER (WHERE v.fare_amount / v.trip_distance < l.limite_inf) AS atipicos_bajos,
    round(approx_quantile(v.trip_distance, 0.5)
          FILTER (WHERE v.fare_amount / v.trip_distance > l.limite_sup), 2) AS distancia_mediana_atipicos_altos,
    round(100.0 * avg((v.ratecode_id <> 1)::INT)
          FILTER (WHERE v.fare_amount / v.trip_distance > l.limite_sup), 1) AS pct_tarifa_especial_en_altos
FROM viajes_validos v
JOIN lim l USING (taxi)
GROUP BY v.taxi
ORDER BY viajes DESC;
```

**Resultado:**

| taxi | q1 | q3 | limite_inf | limite_sup | viajes | atipicos_altos | atipicos_bajos | distancia_mediana_atipicos_altos | pct_tarifa_especial_en_altos |
|---|---|---|---|---|---|---|---|---|---|
| yellow | 5.73 | 9.95 | -0.59 | 16.27 | 28,127,474 | 1,622,681 | 0 | 0.6 | 12 |
| green | 5.42 | 8.2 | 1.23 | 12.39 | 312,777 | 16,589 | 24,181 | 0.52 | 27.7 |

---

## P11 - Propina como % del total antes de propina (tarjeta, proveedor 2)

**Pregunta:** Los pasajeros eligen los porcentajes sugeridos por la pantalla del taxi (20, 25, 30 %) cuando la propina se mide sobre el total cobrado antes de la propina, en lugar de sobre la tarifa base?  
**Justificacion:** En P7 la propina se mide sobre fare_amount y el pico cae en 26-29 % (amarillos) y 21-24 % (verdes), no en 20 %. Hipotesis: la pantalla calcula el porcentaje sobre la tarifa mas recargos, que en amarillos son mayores (congestion 2.50 + CBD 0.75). Se usa solo el proveedor 2, cuyo total_amount es consistente con sus componentes (Ejercicio 3, 3.6h).  
**Fuente:** vista viajes_validos (payment_type = 1, vendor_id = 2)  
**Archivo:** `sql/ejercicio4/4_11_propina_sobre_total.sql`  
**Tiempo de ejecucion:** 4.289 s - **filas del resultado:** 82

```sql
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
```

**Resultado:**

| taxi | pct_propina_sobre_total | viajes | pct_del_tipo |
|---|---|---|---|
| yellow | 0 | 774,618 | 5.36 |
| yellow | 1 | 17,071 | 0.12 |
| yellow | 2 | 17,110 | 0.12 |
| yellow | 3 | 42,861 | 0.3 |
| yellow | 4 | 86,265 | 0.6 |
| yellow | 5 | 197,775 | 1.37 |
| yellow | 6 | 207,195 | 1.43 |
| yellow | 7 | 221,194 | 1.53 |
| yellow | 8 | 237,565 | 1.64 |
| yellow | 9 | 224,981 | 1.56 |
| yellow | 10 | 591,198 | 4.09 |
| yellow | 11 | 221,954 | 1.54 |
| yellow | 12 | 244,865 | 1.69 |
| yellow | 13 | 189,931 | 1.31 |
| yellow | 14 | 179,119 | 1.24 |
| yellow | 15 | 642,813 | 4.45 |
| yellow | 16 | 131,312 | 0.91 |
| yellow | 17 | 112,473 | 0.78 |
| yellow | 18 | 154,794 | 1.07 |
| yellow | 19 | 426,193 | 2.95 |
| yellow | 20 | 7,662,775 | 53.03 |
| yellow | 21 | 29,069 | 0.2 |
| yellow | 22 | 31,299 | 0.22 |
| yellow | 23 | 21,572 | 0.15 |
| yellow | 24 | 105,435 | 0.73 |
| yellow | 25 | 1,063,756 | 7.36 |
| yellow | 26 | 10,686 | 0.07 |
| yellow | 27 | 11,867 | 0.08 |
| yellow | 28 | 11,114 | 0.08 |
| yellow | 29 | 28,970 | 0.2 |
| yellow | 30 | 446,814 | 3.09 |
| yellow | 31 | 5,503 | 0.04 |
| yellow | 32 | 6,922 | 0.05 |
| yellow | 33 | 6,156 | 0.04 |
| yellow | 34 | 4,502 | 0.03 |
| yellow | 35 | 4,792 | 0.03 |
| yellow | 36 | 5,669 | 0.04 |
| yellow | 37 | 4,161 | 0.03 |
| yellow | 38 | 3,255 | 0.02 |
| yellow | 39 | 2,811 | 0.02 |

_... 42 filas mas (ver CSV)._
