# Resultados del benchmark: Parquet vs. tabla DuckDB

Generado automaticamente el 2026-10-07T23:35:52 con `python scripts/benchmark.py` (3 repeticiones por consulta y modo, ademas de la primera ejecucion). No editar a mano.

## Ambiente

| duckdb | python | sistema | cpus | memoria_total | threads | memory_limit |
|---|---|---|---|---|---|---|
| 1.5.5 | 3.11.14 | Linux-5.15.167.4-microsoft-standard-WSL2-x86_64-with-glibc2.41 | 8 | 7.6 GiB | 8 | 3.5 GiB |

## Escenarios y costo de materializar

`segundos_crear_tabla` = `CREATE TABLE viajes AS SELECT * FROM viajes` (lee los Parquet y escribe la tabla); `segundos_total` agrega zonas, la tabla `origen`, las vistas y el CHECKPOINT final.

| escenario | nombre | meses | archivos | filas | mib_parquet | mib_duckdb | segundos_crear_tabla | segundos_total |
|---|---|---|---|---|---|---|---|---|
| 1m | 1 mes | 1 | 2 | 3,765,161 | 62.1 | 103 | 7.28 | 7.59 |
| 3m | 3 meses | 3 | 6 | 11,199,059 | 184.8 | 307.8 | 13.98 | 14.65 |
| 2026 | 2026 | 8 | 16 | 30,040,469 | 495.7 | 842.5 | 36.93 | 39.37 |
| todos | todos | 20 | 40 | 71,870,407 | 1,171.7 | 1,995 | 75.1 | 79.18 |

## Tiempo por consulta (mediana de las repeticiones, segundos)

`parquet/tabla` > 1 significa que la tabla materializada fue mas rapida.

| consulta | 1m: parquet | 1m: tabla | 1m: parquet/tabla | 3m: parquet | 3m: tabla | 3m: parquet/tabla | 2026: parquet | 2026: tabla | 2026: parquet/tabla | todos: parquet | todos: tabla | todos: parquet/tabla |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| B1 Conteo de registros por tipo de taxi | 0.092 | 0.025 | 3.7x | 0.103 | 0.055 | 1.9x | 0.330 | 0.102 | 3.2x | 0.995 | 0.182 | 5.5x |
| B2 Volumen mensual de viajes por tipo de taxi | 1.254 | 1.159 | 1.1x | 2.606 | 2.749 | 0.9x | 6.410 | 7.144 | 0.9x | 14.354 | 16.706 | 0.9x |
| B3 Demanda por hora del dia y dia de la semana | 0.918 | 0.726 | 1.3x | 2.100 | 2.309 | 0.9x | 5.503 | 6.106 | 0.9x | 12.993 | 14.071 | 0.9x |
| B4 Distribucion de distancia, duracion, velocidad y monto | 1.661 | 0.824 | 2.0x | 3.740 | 2.672 | 1.4x | 9.459 | 6.668 | 1.4x | 21.546 | 15.781 | 1.4x |
| B5 Origen de los viajes por borough | 1.069 | 0.466 | 2.3x | 2.292 | 1.238 | 1.9x | 5.761 | 3.214 | 1.8x | 12.839 | 7.323 | 1.8x |
| B6 Registros atipicos o inconsistentes por regla, tipo y mes | 0.881 | 0.306 | 2.9x | 1.869 | 1.081 | 1.7x | 5.198 | 3.111 | 1.7x | 11.509 | 7.136 | 1.6x |
| B7 Consulta selectiva: viajes desde JFK en un dia, por hora | 0.248 | 0.013 | 19.6x | 0.317 | 0.011 | 27.6x | 0.544 | 0.024 | 22.9x | 1.325 | 0.020 | 65.6x |

## Tiempo de la primera ejecucion en una conexion nueva (segundos)

| consulta | 1m: parquet | 1m: tabla | 1m: parquet/tabla | 3m: parquet | 3m: tabla | 3m: parquet/tabla | 2026: parquet | 2026: tabla | 2026: parquet/tabla | todos: parquet | todos: tabla | todos: parquet/tabla |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| B1 Conteo de registros por tipo de taxi | 0.094 | 0.041 | 2.3x | 0.094 | 0.050 | 1.9x | 0.453 | 0.184 | 2.5x | 0.742 | 0.388 | 1.9x |
| B2 Volumen mensual de viajes por tipo de taxi | 1.505 | 1.192 | 1.3x | 3.404 | 3.553 | 1.0x | 8.279 | 8.906 | 0.9x | 18.957 | 20.296 | 0.9x |
| B3 Demanda por hora del dia y dia de la semana | 1.306 | 0.942 | 1.4x | 2.507 | 2.955 | 0.8x | 5.763 | 7.152 | 0.8x | 15.561 | 17.475 | 0.9x |
| B4 Distribucion de distancia, duracion, velocidad y monto | 1.693 | 0.842 | 2.0x | 4.239 | 3.202 | 1.3x | 11.509 | 7.830 | 1.5x | 23.756 | 20.076 | 1.2x |
| B5 Origen de los viajes por borough | 1.010 | 0.620 | 1.6x | 2.084 | 2.433 | 0.9x | 6.712 | 4.827 | 1.4x | 16.552 | 13.524 | 1.2x |
| B6 Registros atipicos o inconsistentes por regla, tipo y mes | 0.849 | 0.526 | 1.6x | 2.219 | 1.849 | 1.2x | 5.484 | 3.957 | 1.4x | 11.891 | 9.687 | 1.2x |
| B7 Consulta selectiva: viajes desde JFK en un dia, por hora | 0.284 | 0.041 | 6.9x | 0.282 | 0.046 | 6.1x | 0.578 | 0.093 | 6.2x | 1.280 | 0.134 | 9.6x |

## Suma de las 7 consultas y punto de equilibrio

`rondas_para_amortizar` = segundos de materializar / segundos ahorrados por cada ejecucion del conjunto completo de consultas (medianas).

| escenario | filas | segundos_total | parquet | tabla | ahorro_por_ronda_s | rondas_para_amortizar |
|---|---|---|---|---|---|---|
| 1m | 3,765,161 | 7.59 | 6.12 | 3.52 | 2.6 | 2.91 |
| 3m | 11,199,059 | 14.65 | 13.03 | 10.12 | 2.91 | 5.03 |
| 2026 | 30,040,469 | 39.37 | 33.21 | 26.37 | 6.84 | 5.76 |
| todos | 71,870,407 | 79.18 | 75.56 | 61.22 | 14.34 | 5.52 |

## Validez: mismo resultado en ambos modos

`aprox` = diferencias < 1 % por percentiles aproximados (approx_quantile).

| consulta | 1m | 3m | 2026 | todos |
|---|---|---|---|---|
| B1 | igual | igual | igual | igual |
| B2 | igual | igual | igual | igual |
| B3 | igual | igual | igual | igual |
| B4 | aprox | aprox | aprox | aprox |
| B5 | igual | igual | igual | igual |
| B6 | igual | igual | igual | igual |
| B7 | igual | igual | igual | igual |

## Consultas del benchmark

### B1 - Conteo de registros por tipo de taxi

**Archivo:** `sql/ejercicio6/6_01_conteo_por_tipo.sql` (id original: B1)  

```sql
-- @id: B1
-- @titulo: Conteo de registros por tipo de taxi
-- @objetivo: Consulta minima del benchmark (equivale a 3.2b, pero sobre
--   `viajes`): solo cuenta filas. Sobre Parquet, `taxi` es una constante de
--   cada rama de la vista y no se lee ninguna columna; sobre la tabla, `taxi`
--   es una columna almacenada que hay que recorrer. Mide el costo fijo de abrir
--   y recorrer el origen de datos.
-- @fuente: relacion viajes (vista sobre Parquet o tabla materializada)
SELECT
    taxi,
    count(*)                                                        AS registros
FROM viajes
GROUP BY taxi
ORDER BY taxi DESC;
```

### B2 - Volumen mensual de viajes por tipo de taxi

**Archivo:** `sql/ejercicio4/4_01_viajes_por_mes.sql` (id original: P1)  

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

### B3 - Demanda por hora del dia y dia de la semana

**Archivo:** `sql/ejercicio4/4_02_hora_dia_semana.sql` (id original: P2)  

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

### B4 - Distribucion de distancia, duracion, velocidad y monto

**Archivo:** `sql/ejercicio4/4_03_caracteristicas_viaje.sql` (id original: P3)  

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

### B5 - Origen de los viajes por borough

**Archivo:** `sql/ejercicio4/4_05_viajes_por_borough.sql` (id original: P5)  

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

### B6 - Registros atipicos o inconsistentes por regla, tipo y mes

**Archivo:** `sql/ejercicio4/4_09_impacto_reglas_calidad.sql` (id original: P9)  

```sql
-- @id: P9
-- @titulo: Registros atipicos o inconsistentes por regla, tipo y mes
-- @pregunta: Que proporcion de los registros es atipica o inconsistente, que
--   regla la explica y cambia entre tipos de taxi o meses?
-- @justificacion: Cuantifica el efecto de los filtros definidos a partir del
--   Ejercicio 3 (sql/02_vistas_analisis.sql). Un mes o tipo con un porcentaje mucho mayor
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

### B7 - Consulta selectiva: viajes desde JFK en un dia, por hora

**Archivo:** `sql/ejercicio6/6_02_filtro_selectivo.sql` (id original: B7)  

```sql
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
```
