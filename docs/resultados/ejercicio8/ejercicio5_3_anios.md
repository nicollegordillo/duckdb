# Resultados de sql/ejercicio5

Generado automaticamente el 2026-10-08T22:43:15 con `python scripts/run_sql.py ejercicio5 --salida ejercicio8/ejercicio5_3_anios`.
No editar a mano: volver a ejecutar el script tras cambiar las consultas.

DuckDB 1.5.5

## 5.1 - Archivos y meses disponibles por tipo de taxi y anio

**Objetivo:** Confirmar que los archivos de 2024 quedaron en la estructura del proyecto (data/raw/<tipo>/<anio>/) junto a los de 2026, que la carpeta coincide con el anio del nombre del archivo y que no hay huecos en la serie mensual (12 meses en 2024; en 2026, los meses publicados por la TLC).  
**Fuente:** data/raw/*/*/*.parquet (solo nombres de archivo, no se leen datos)  
**Archivo:** `sql/ejercicio5/5_01_archivos_por_anio.sql`  
**Tiempo de ejecucion:** 2.934 s - **filas del resultado:** 6

```sql
-- @id: 5.1
-- @titulo: Archivos y meses disponibles por tipo de taxi y anio
-- @objetivo: Confirmar que los archivos de 2024 quedaron en la estructura del
--   proyecto (data/raw/<tipo>/<anio>/) junto a los de 2026, que la carpeta
--   coincide con el anio del nombre del archivo y que no hay huecos en la serie
--   mensual (12 meses en 2024; en 2026, los meses publicados por la TLC).
-- @fuente: data/raw/*/*/*.parquet (solo nombres de archivo, no se leen datos)
WITH f AS (
    SELECT
        regexp_extract(file, 'raw[/\\](\w+)[/\\]', 1)                        AS tipo,
        CAST(regexp_extract(file, 'raw[/\\]\w+[/\\](\d{4})', 1) AS INTEGER)  AS anio_carpeta,
        CAST(regexp_extract(file, '_(\d{4})-\d{2}\.parquet$', 1) AS INTEGER)   AS anio,
        CAST(regexp_extract(file, '_\d{4}-(\d{2})\.parquet$', 1) AS INTEGER)   AS mes
    FROM glob('data/raw/*/*/*.parquet')
)
SELECT
    tipo,
    anio,
    count(*)                                                AS archivos,
    min(mes)                                                AS primer_mes,
    max(mes)                                                AS ultimo_mes,
    (max(mes) - min(mes) + 1) - count(*)                    AS huecos,
    count(*) FILTER (WHERE anio_carpeta <> anio)            AS en_carpeta_incorrecta,
    string_agg(lpad(CAST(mes AS VARCHAR), 2, '0'), ', ' ORDER BY mes) AS meses
FROM f
GROUP BY ALL
ORDER BY tipo DESC, anio;
```

**Resultado:**

| tipo | anio | archivos | primer_mes | ultimo_mes | huecos | en_carpeta_incorrecta | meses |
|---|---|---|---|---|---|---|---|
| yellow | 2,024 | 12 | 1 | 12 | 0 | 0 | 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12 |
| yellow | 2,025 | 12 | 1 | 12 | 0 | 0 | 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12 |
| yellow | 2,026 | 8 | 1 | 8 | 0 | 0 | 01, 02, 03, 04, 05, 06, 07, 08 |
| green | 2,024 | 12 | 1 | 12 | 0 | 0 | 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12 |
| green | 2,025 | 12 | 1 | 12 | 0 | 0 | 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12 |
| green | 2,026 | 8 | 1 | 8 | 0 | 0 | 01, 02, 03, 04, 05, 06, 07, 08 |

---

## 5.2 - Registros por tipo y anio: metadatos Parquet vs. vista unificada

**Objetivo:** Verificar que la vista `viajes`, que ahora une 2024 y 2026 con union_by_name, incluye todas las filas de los archivos nuevos. La suma de num_rows de los footers (sin leer datos) debe ser igual a count(*) sobre la vista para cada tipo y anio: diferencia = 0.  
**Fuente:** parquet_file_metadata('data/raw/*/*/*.parquet') y vista viajes  
**Archivo:** `sql/ejercicio5/5_02_registros_metadatos_vs_vista.sql`  
**Tiempo de ejecucion:** 0.341 s - **filas del resultado:** 6

```sql
-- @id: 5.2
-- @titulo: Registros por tipo y anio: metadatos Parquet vs. vista unificada
-- @objetivo: Verificar que la vista `viajes`, que ahora une 2024 y 2026 con
--   union_by_name, incluye todas las filas de los archivos nuevos. La suma de
--   num_rows de los footers (sin leer datos) debe ser igual a count(*) sobre la
--   vista para cada tipo y anio: diferencia = 0.
-- @fuente: parquet_file_metadata('data/raw/*/*/*.parquet') y vista viajes
WITH meta AS (
    SELECT
        regexp_extract(file_name, 'raw[/\\](\w+)[/\\]', 1)                   AS taxi,
        CAST(regexp_extract(file_name, '_(\d{4})-\d{2}\.parquet$', 1) AS INTEGER) AS anio,
        count(*)                                                                AS archivos,
        sum(num_rows)                                                           AS registros_metadatos
    FROM parquet_file_metadata('data/raw/*/*/*.parquet')
    GROUP BY ALL
), vista AS (
    SELECT taxi, anio_archivo AS anio, count(*) AS registros_vista
    FROM viajes
    GROUP BY ALL
)
SELECT
    coalesce(m.taxi, v.taxi)                                AS taxi,
    coalesce(m.anio, v.anio)                                AS anio,
    m.archivos,
    m.registros_metadatos,
    v.registros_vista,
    v.registros_vista - m.registros_metadatos               AS diferencia
FROM meta m
FULL JOIN vista v ON m.taxi = v.taxi AND m.anio = v.anio
ORDER BY taxi DESC, anio;
```

**Resultado:**

| taxi | anio | archivos | registros_metadatos | registros_vista | diferencia |
|---|---|---|---|---|---|
| yellow | 2,024 | 12 | 41,169,720 | 41,169,720 | 0 |
| yellow | 2,025 | 12 | 48,722,602 | 48,722,602 | 0 |
| yellow | 2,026 | 8 | 29,703,355 | 29,703,355 | 0 |
| green | 2,024 | 12 | 660,218 | 660,218 | 0 |
| green | 2,025 | 12 | 591,375 | 591,375 | 0 |
| green | 2,026 | 8 | 337,114 | 337,114 | 0 |

---

## 5.3 - Columnas que cambian de nombre, tipo o presencia entre anios

**Objetivo:** Comparar el esquema fisico de los archivos de cada anio y mostrar solo las columnas que NO son uniformes: ausentes en algunos archivos, con mas de un tipo Parquet o con distinta capitalizacion del nombre. Son las columnas que pueden romper una consulta al incorporar un anio nuevo y las que justifican union_by_name, TRY_CAST y las columnas opcionales de sql/00_vistas.sql.  
**Fuente:** data/raw/*/*/*.parquet via parquet_schema()  
**Archivo:** `sql/ejercicio5/5_03_esquema_por_anio.sql`  
**Tiempo de ejecucion:** 0.058 s - **filas del resultado:** 12

```sql
-- @id: 5.3
-- @titulo: Columnas que cambian de nombre, tipo o presencia entre anios
-- @objetivo: Comparar el esquema fisico de los archivos de cada anio y mostrar
--   solo las columnas que NO son uniformes: ausentes en algunos archivos, con
--   mas de un tipo Parquet o con distinta capitalizacion del nombre. Son las
--   columnas que pueden romper una consulta al incorporar un anio nuevo y las
--   que justifican union_by_name, TRY_CAST y las columnas opcionales de
--   sql/00_vistas.sql.
-- @fuente: data/raw/*/*/*.parquet via parquet_schema()
WITH s AS (
    SELECT
        regexp_extract(file_name, 'raw[/\\](\w+)[/\\]', 1)                   AS tipo,
        CAST(regexp_extract(file_name, '_(\d{4})-\d{2}\.parquet$', 1) AS INTEGER) AS anio,
        file_name,
        name                                                                    AS columna,
        type || coalesce(' (' || CASE
            WHEN logical_type LIKE 'TimestampType%'
                THEN 'TIMESTAMP_' || regexp_extract(logical_type, '(MILLIS|MICROS|NANOS)=[^<]', 1)
            ELSE coalesce(converted_type, regexp_replace(logical_type, '\(.*', ''))
        END || ')', '')                                                         AS tipo_parquet
    FROM parquet_schema('data/raw/*/*/*.parquet')
    WHERE type IS NOT NULL                     -- excluye el nodo raiz del esquema
), archivos AS (
    SELECT tipo, anio, count(DISTINCT file_name) AS total FROM s GROUP BY ALL
), por_anio AS (
    SELECT
        s.tipo,
        lower(s.columna)                                    AS columna,
        s.anio,
        string_agg(DISTINCT s.columna, ' | ')               AS nombres,
        string_agg(DISTINCT s.tipo_parquet, ' | ')          AS tipos_parquet,
        count(DISTINCT s.file_name)                         AS en_archivos,
        any_value(a.total)                                  AS archivos_del_anio
    FROM s JOIN archivos a USING (tipo, anio)
    GROUP BY ALL
), todos AS (
    -- tipos y anios presentes, para detectar columnas que faltan en un anio completo
    SELECT DISTINCT p.tipo, p.columna, a.anio, a.total
    FROM por_anio p JOIN archivos a USING (tipo)
), no_uniformes AS (
    SELECT t.tipo, t.columna
    FROM todos t
    LEFT JOIN por_anio p USING (tipo, columna, anio)
    GROUP BY ALL
    HAVING count(DISTINCT p.tipos_parquet) > 1
        OR count(DISTINCT p.nombres) > 1
        OR bool_or(p.nombres LIKE '%|%' OR p.tipos_parquet LIKE '%|%')
        OR bool_or(coalesce(p.en_archivos, 0) < t.total)
)
SELECT
    t.tipo,
    t.columna,
    t.anio,
    coalesce(p.nombres, '(no existe)')                      AS nombres,
    p.tipos_parquet,
    coalesce(p.en_archivos, 0)                              AS en_archivos,
    t.total                                                 AS archivos_del_anio
FROM todos t
JOIN no_uniformes USING (tipo, columna)
LEFT JOIN por_anio p USING (tipo, columna, anio)
ORDER BY t.tipo DESC, t.columna, t.anio;
```

**Resultado:**

| tipo | columna | anio | nombres | tipos_parquet | en_archivos | archivos_del_anio |
|---|---|---|---|---|---|---|
| yellow | cbd_congestion_fee | 2,024 | (no existe) | NULL | 0 | 12 |
| yellow | cbd_congestion_fee | 2,025 | cbd_congestion_fee | DOUBLE | 12 | 12 |
| yellow | cbd_congestion_fee | 2,026 | cbd_congestion_fee | DOUBLE | 8 | 8 |
| yellow | request_source | 2,024 | (no existe) | NULL | 0 | 12 |
| yellow | request_source | 2,025 | (no existe) | NULL | 0 | 12 |
| yellow | request_source | 2,026 | request_source | BYTE_ARRAY (UTF8) | 3 | 8 |
| green | cbd_congestion_fee | 2,024 | (no existe) | NULL | 0 | 12 |
| green | cbd_congestion_fee | 2,025 | cbd_congestion_fee | DOUBLE | 12 | 12 |
| green | cbd_congestion_fee | 2,026 | cbd_congestion_fee | DOUBLE | 8 | 8 |
| green | request_source | 2,024 | (no existe) | NULL | 0 | 12 |
| green | request_source | 2,025 | (no existe) | NULL | 0 | 12 |
| green | request_source | 2,026 | request_source | BYTE_ARRAY (UTF8) | 3 | 8 |

---

## 5.4 - Consulta conjunta 2024 + 2026: volumen, cobertura y calidad por anio

**Objetivo:** Comprobar que una sola consulta sobre las vistas devuelve ambos anios y que cada anio tiene un volumen, un rango de fechas y una proporcion de registros validos coherentes. Las fechas min/max se calculan solo con los viajes cuyo pickup cae en el mes del archivo (el resto son errores ya documentados en el Ejercicio 3).  
**Fuente:** vista viajes_enriquecidos (data/raw/*/*/*.parquet)  
**Archivo:** `sql/ejercicio5/5_04_resumen_por_anio.sql`  
**Tiempo de ejecucion:** 23.522 s - **filas del resultado:** 6

```sql
-- @id: 5.4
-- @titulo: Consulta conjunta 2024 + 2026: volumen, cobertura y calidad por anio
-- @objetivo: Comprobar que una sola consulta sobre las vistas devuelve ambos
--   anios y que cada anio tiene un volumen, un rango de fechas y una proporcion
--   de registros validos coherentes. Las fechas min/max se calculan solo con
--   los viajes cuyo pickup cae en el mes del archivo (el resto son errores ya
--   documentados en el Ejercicio 3).
-- @fuente: vista viajes_enriquecidos (data/raw/*/*/*.parquet)
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    count(DISTINCT mes_archivo)                                     AS meses,
    count(*)                                                        AS registros,
    min(pickup_at) FILTER (WHERE NOT f_fuera_periodo)               AS primer_pickup,
    max(pickup_at) FILTER (WHERE NOT f_fuera_periodo)               AS ultimo_pickup,
    round(100.0 * avg(f_fuera_periodo::INT), 3)                     AS pct_fuera_periodo,
    count(*) FILTER (WHERE NOT (f_fuera_periodo OR f_duracion OR f_distancia
                                OR f_velocidad OR f_monto OR f_pasajeros)) AS validos,
    round(100.0 * avg((NOT (f_fuera_periodo OR f_duracion OR f_distancia
                            OR f_velocidad OR f_monto OR f_pasajeros))::INT), 2) AS pct_validos
FROM viajes_enriquecidos
GROUP BY ALL
ORDER BY taxi DESC, anio;
```

**Resultado:**

| taxi | anio | meses | registros | primer_pickup | ultimo_pickup | pct_fuera_periodo | validos | pct_validos |
|---|---|---|---|---|---|---|---|---|
| yellow | 2,024 | 12 | 41,169,720 | 2024-01-01 00:00:00 | 2024-12-31 23:59:58 | 0.001 | 39,286,835 | 95.43 |
| yellow | 2,025 | 12 | 48,722,602 | 2025-01-01 00:00:00 | 2025-12-31 23:59:59 | 0 | 43,894,841 | 90.09 |
| yellow | 2,026 | 8 | 29,703,355 | 2026-01-01 00:00:00 | 2026-08-31 23:59:59 | 0 | 28,127,474 | 94.69 |
| green | 2,024 | 12 | 660,218 | 2024-01-01 00:03:57 | 2024-12-31 23:58:02 | 0.025 | 613,074 | 92.86 |
| green | 2,025 | 12 | 591,375 | 2025-01-01 00:01:11 | 2025-12-31 23:59:09 | 0.042 | 547,922 | 92.65 |
| green | 2,026 | 8 | 337,114 | 2026-01-01 00:03:27 | 2026-08-31 23:58:28 | 0.029 | 312,777 | 92.78 |

---

## 5.5 - Viajes por dia en cada mes: 2024 frente a 2026

**Objetivo:** Consultar ambos anios a la vez para comparar el mismo mes de distintos anios. Se usan viajes por dia (y no el total del mes) porque los meses tienen distinta cantidad de dias; la variacion se calcula contra el mismo mes del anio anterior disponible, asi que la consulta sigue sirviendo cuando se agregue 2025 (Ejercicio 8).  
**Fuente:** vista viajes_validos  
**Archivo:** `sql/ejercicio5/5_05_viajes_por_mes_y_anio.sql`  
**Tiempo de ejecucion:** 22.686 s - **filas del resultado:** 64

```sql
-- @id: 5.5
-- @titulo: Viajes por dia en cada mes: 2024 frente a 2026
-- @objetivo: Consultar ambos anios a la vez para comparar el mismo mes de
--   distintos anios. Se usan viajes por dia (y no el total del mes) porque los
--   meses tienen distinta cantidad de dias; la variacion se calcula contra el
--   mismo mes del anio anterior disponible, asi que la consulta sigue sirviendo
--   cuando se agregue 2025 (Ejercicio 8).
-- @fuente: vista viajes_validos
WITH m AS (
    SELECT
        taxi,
        anio_archivo                                                AS anio,
        mes_archivo                                                 AS mes,
        count(*)                                                    AS viajes,
        count(*) / count(DISTINCT fecha)                            AS viajes_por_dia
    FROM viajes_validos
    GROUP BY ALL
)
SELECT
    taxi,
    mes,
    anio,
    viajes,
    round(viajes_por_dia, 0)                                        AS viajes_por_dia,
    round(100.0 * (viajes_por_dia
          / lag(viajes_por_dia) OVER (PARTITION BY taxi, mes ORDER BY anio) - 1), 1)
                                                                    AS variacion_pct_vs_anio_previo
FROM m
ORDER BY taxi DESC, mes, anio;
```

**Resultado:**

| taxi | mes | anio | viajes | viajes_por_dia | variacion_pct_vs_anio_previo |
|---|---|---|---|---|---|
| yellow | 1 | 2,024 | 2,836,223 | 91,491 | NULL |
| yellow | 1 | 2,025 | 3,226,780 | 104,090 | 13.8 |
| yellow | 1 | 2,026 | 3,500,703 | 112,926 | 8.5 |
| yellow | 2 | 2,024 | 2,865,951 | 98,826 | NULL |
| yellow | 2 | 2,025 | 3,283,385 | 117,264 | 18.7 |
| yellow | 2 | 2,026 | 3,196,364 | 114,156 | -2.7 |
| yellow | 3 | 2,024 | 3,398,154 | 109,618 | NULL |
| yellow | 3 | 2,025 | 3,803,439 | 122,692 | 11.9 |
| yellow | 3 | 2,026 | 3,748,151 | 120,908 | -1.5 |
| yellow | 4 | 2,024 | 3,373,190 | 112,440 | NULL |
| yellow | 4 | 2,025 | 3,647,623 | 121,587 | 8.1 |
| yellow | 4 | 2,026 | 3,660,483 | 122,016 | 0.4 |
| yellow | 5 | 2,024 | 3,575,459 | 115,337 | NULL |
| yellow | 5 | 2,025 | 4,067,043 | 131,195 | 13.7 |
| yellow | 5 | 2,026 | 3,897,714 | 125,733 | -4.2 |
| yellow | 6 | 2,024 | 3,391,071 | 113,036 | NULL |
| yellow | 6 | 2,025 | 3,845,080 | 128,169 | 13.4 |
| yellow | 6 | 2,026 | 3,633,908 | 121,130 | -5.5 |
| yellow | 7 | 2,024 | 2,943,435 | 94,950 | NULL |
| yellow | 7 | 2,025 | 3,473,173 | 112,038 | 18 |
| yellow | 7 | 2,026 | 3,335,678 | 107,603 | -4 |
| yellow | 8 | 2,024 | 2,839,716 | 91,604 | NULL |
| yellow | 8 | 2,025 | 3,162,172 | 102,006 | 11.4 |
| yellow | 8 | 2,026 | 3,154,473 | 101,757 | -0.2 |
| yellow | 9 | 2,024 | 3,452,355 | 115,079 | NULL |
| yellow | 9 | 2,025 | 3,814,640 | 127,155 | 10.5 |
| yellow | 10 | 2,024 | 3,644,845 | 117,576 | NULL |
| yellow | 10 | 2,025 | 3,920,142 | 126,456 | 7.6 |
| yellow | 11 | 2,024 | 3,479,841 | 115,995 | NULL |
| yellow | 11 | 2,025 | 3,622,266 | 120,742 | 4.1 |
| yellow | 12 | 2,024 | 3,486,595 | 112,471 | NULL |
| yellow | 12 | 2,025 | 4,029,098 | 129,971 | 15.6 |
| green | 1 | 2,024 | 52,662 | 1,699 | NULL |
| green | 1 | 2,025 | 44,527 | 1,436 | -15.4 |
| green | 1 | 2,026 | 37,567 | 1,212 | -15.6 |
| green | 2 | 2,024 | 49,771 | 1,716 | NULL |
| green | 2 | 2,025 | 42,760 | 1,527 | -11 |
| green | 2 | 2,026 | 34,593 | 1,235 | -19.1 |
| green | 3 | 2,024 | 53,427 | 1,723 | NULL |
| green | 3 | 2,025 | 47,000 | 1,516 | -12 |

_... 24 filas mas (ver CSV)._

---

## 5.6 - Comparacion entre anios en los mismos meses

**Objetivo:** Comparar los anios con metricas del Ejercicio 4 (P1, P3, P4, P6) usando solo los meses presentes en todos los anios descargados (enero a agosto mientras 2026 este incompleto), para que la estacionalidad no sesgue la comparacion. Los meses comunes se obtienen de los nombres de archivo. Nota: se usa approx_quantile (T-Digest) por memoria, igual que en el Ejercicio 4.  
**Fuente:** vista viajes_validos + glob('data/raw/*/*/*.parquet')  
**Archivo:** `sql/ejercicio5/5_06_comparacion_mismo_periodo.sql`  
**Tiempo de ejecucion:** 33.699 s - **filas del resultado:** 6

```sql
-- @id: 5.6
-- @titulo: Comparacion entre anios en los mismos meses
-- @objetivo: Comparar los anios con metricas del Ejercicio 4 (P1, P3, P4, P6)
--   usando solo los meses presentes en todos los anios descargados (enero a
--   agosto mientras 2026 este incompleto), para que la estacionalidad no sesgue
--   la comparacion. Los meses comunes se obtienen de los nombres de archivo.
-- Nota: se usa approx_quantile (T-Digest) por memoria, igual que en el
--   Ejercicio 4.
-- @fuente: vista viajes_validos + glob('data/raw/*/*/*.parquet')
WITH archivos AS (
    SELECT
        CAST(regexp_extract(file, '_(\d{4})-\d{2}\.parquet$', 1) AS INTEGER) AS anio,
        CAST(regexp_extract(file, '_\d{4}-(\d{2})\.parquet$', 1) AS INTEGER) AS mes
    FROM glob('data/raw/*/*/*.parquet')
), meses_comunes AS (
    SELECT mes
    FROM archivos
    GROUP BY mes
    HAVING count(DISTINCT anio) = (SELECT count(DISTINCT anio) FROM archivos)
)
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    (SELECT string_agg(mes, ',' ORDER BY mes) FROM meses_comunes)   AS meses,
    count(*)                                                        AS viajes_validos,
    round(count(*) / count(DISTINCT fecha), 0)                      AS viajes_por_dia,
    round(approx_quantile(trip_distance, 0.5), 2)                   AS distancia_mediana_mi,
    round(approx_quantile(duracion_min, 0.5), 1)                    AS duracion_mediana_min,
    round(approx_quantile(total_amount, 0.5), 2)                    AS total_mediano_usd,
    round(avg(total_amount), 2)                                     AS total_prom_usd,
    round(100.0 * avg((payment_type = 1)::INT), 1)                  AS pct_tarjeta,
    round(100.0 * avg((payment_type = 2)::INT), 1)                  AS pct_efectivo,
    round(100.0 * avg((payment_type = 0 OR payment_type IS NULL)::INT), 1) AS pct_flex_o_sin_dato,
    round(100.0 * avg((coalesce(airport_fee, 0) > 0 OR ratecode_id IN (2, 3))::INT), 2)
                                                                    AS pct_aeropuerto,
    round(100.0 * avg((coalesce(cbd_congestion_fee, 0) > 0)::INT), 1) AS pct_cargo_cbd
FROM viajes_validos
WHERE mes_archivo IN (SELECT mes FROM meses_comunes)
GROUP BY ALL
ORDER BY taxi DESC, anio;
```

**Resultado:**

| taxi | anio | meses | viajes_validos | viajes_por_dia | distancia_mediana_mi | duracion_mediana_min | total_mediano_usd | total_prom_usd | pct_tarjeta | pct_efectivo | pct_flex_o_sin_dato | pct_aeropuerto | pct_cargo_cbd |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 2,024 | 1,2,3,4,5,6,7,8 | 25,223,199 | 103,374 | 1.8 | 12.7 | 20.96 | 28.36 | 75.9 | 13.8 | 9.1 | 10.28 | 0 |
| yellow | 2,025 | 1,2,3,4,5,6,7,8 | 28,508,695 | 117,320 | 1.88 | 13 | 21.64 | 28.4 | 68.6 | 10 | 19.7 | 10 | 73 |
| yellow | 2,026 | 1,2,3,4,5,6,7,8 | 28,127,474 | 115,751 | 1.93 | 14.1 | 23.6 | 30.26 | 65.3 | 9 | 25 | 9.74 | 72.4 |
| green | 2,024 | 1,2,3,4,5,6,7,8 | 411,994 | 1,689 | 1.96 | 11.9 | 19.09 | 23.76 | 70.6 | 29 | 4.1 | 0.28 | 0 |
| green | 2,025 | 1,2,3,4,5,6,7,8 | 366,715 | 1,509 | 2.02 | 12.4 | 19.81 | 24.84 | 74.7 | 24.9 | 6.5 | 0.26 | 9.8 |
| green | 2,026 | 1,2,3,4,5,6,7,8 | 312,777 | 1,287 | 2.13 | 13.2 | 20.51 | 25.37 | 76.8 | 22.8 | 13.6 | 0.29 | 8.5 |

---

## 5.7 - Contenido de las columnas que cambian entre anios

**Objetivo:** Verificar como quedaron en la vista unificada las columnas que no existen en todos los archivos (5.3): deben ser NULL en los anios donde no existian (no 0 ni un valor inventado). Tambien se revisan los codigos de pago "sin dato" (payment_type 0 o NULL) y los pasajeros nulos, que en el Ejercicio 3 aparecian juntos en 2026, para saber si 2024 tiene el mismo patron.  
**Fuente:** vista viajes (sin filtros de calidad)  
**Archivo:** `sql/ejercicio5/5_07_columnas_por_anio.sql`  
**Tiempo de ejecucion:** 7.121 s - **filas del resultado:** 6

```sql
-- @id: 5.7
-- @titulo: Contenido de las columnas que cambian entre anios
-- @objetivo: Verificar como quedaron en la vista unificada las columnas que no
--   existen en todos los archivos (5.3): deben ser NULL en los anios donde no
--   existian (no 0 ni un valor inventado). Tambien se revisan los codigos de
--   pago "sin dato" (payment_type 0 o NULL) y los pasajeros nulos, que en el
--   Ejercicio 3 aparecian juntos en 2026, para saber si 2024 tiene el mismo
--   patron.
-- @fuente: vista viajes (sin filtros de calidad)
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    count(*)                                                        AS registros,
    round(100.0 * count(cbd_congestion_fee) / count(*), 2)          AS pct_cbd_no_nulo,
    round(100.0 * count(*) FILTER (WHERE cbd_congestion_fee > 0) / count(*), 2) AS pct_cbd_mayor_0,
    round(100.0 * count(request_source) / count(*), 2)              AS pct_request_source_no_nulo,
    round(100.0 * count(airport_fee) / count(*), 2)                 AS pct_airport_fee_no_nulo,
    round(100.0 * count(*) FILTER (WHERE congestion_surcharge > 0) / count(*), 2) AS pct_congestion_mayor_0,
    round(100.0 * count(*) FILTER (WHERE payment_type = 0) / count(*), 2)        AS pct_pago_0,
    round(100.0 * count(*) FILTER (WHERE payment_type IS NULL) / count(*), 2)    AS pct_pago_nulo,
    round(100.0 * count(*) FILTER (WHERE passenger_count IS NULL) / count(*), 2) AS pct_pasajeros_nulo
FROM viajes
GROUP BY ALL
ORDER BY taxi DESC, anio;
```

**Resultado:**

| taxi | anio | registros | pct_cbd_no_nulo | pct_cbd_mayor_0 | pct_request_source_no_nulo | pct_airport_fee_no_nulo | pct_congestion_mayor_0 | pct_pago_0 | pct_pago_nulo | pct_pasajeros_nulo |
|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 2,024 | 41,169,720 | 0 | 0 | 0 | 90.06 | 81.62 | 9.94 | 0 | 9.94 |
| yellow | 2,025 | 48,722,602 | 100 | 71.64 | 0 | 76.17 | 67.82 | 23.83 | 0 | 23.83 |
| yellow | 2,026 | 29,703,355 | 100 | 71.76 | 9.77 | 74.02 | 66.07 | 25.98 | 0 | 25.98 |
| green | 2,024 | 660,218 | 0 | 0 | 0 | 0 | 28.54 | 0 | 3.68 | 3.68 |
| green | 2,025 | 591,375 | 99.35 | 9.21 | 0 | 0 | 29.11 | 0 | 8.43 | 8.43 |
| green | 2,026 | 337,114 | 100 | 8.32 | 5.7 | 0 | 27.48 | 0 | 14.47 | 14.47 |

---

## 5.8 - Reglas de calidad por anio

**Objetivo:** Aplicar a 2024 las mismas reglas de calidad definidas con 2026 (Ejercicio 3; sql/02_vistas_analisis.sql) y comparar el porcentaje de registros que marca cada regla. Si una regla marca a 2024 de forma muy distinta, los umbrales elegidos con 2026 podrian no ser adecuados para el anio nuevo.  
**Fuente:** vista viajes_enriquecidos (sin filtrar)  
**Archivo:** `sql/ejercicio5/5_08_calidad_por_anio.sql`  
**Tiempo de ejecucion:** 18.783 s - **filas del resultado:** 6

```sql
-- @id: 5.8
-- @titulo: Reglas de calidad por anio
-- @objetivo: Aplicar a 2024 las mismas reglas de calidad definidas con 2026
--   (Ejercicio 3; sql/02_vistas_analisis.sql) y comparar el porcentaje de
--   registros que marca cada regla. Si una regla marca a 2024 de forma muy
--   distinta, los umbrales elegidos con 2026 podrian no ser adecuados para el
--   anio nuevo.
-- @fuente: vista viajes_enriquecidos (sin filtrar)
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    count(*)                                                        AS registros,
    round(100.0 * avg(f_fuera_periodo::INT), 3)                     AS pct_fuera_periodo,
    round(100.0 * avg(f_duracion::INT), 3)                          AS pct_duracion,
    round(100.0 * avg(f_distancia::INT), 3)                         AS pct_distancia,
    round(100.0 * avg(f_velocidad::INT), 3)                         AS pct_velocidad,
    round(100.0 * avg(f_monto::INT), 3)                             AS pct_monto,
    round(100.0 * avg(f_pasajeros::INT), 3)                         AS pct_pasajeros,
    round(100.0 * avg((f_fuera_periodo OR f_duracion OR f_distancia
                       OR f_velocidad OR f_monto OR f_pasajeros)::INT), 2) AS pct_excluido
FROM viajes_enriquecidos
GROUP BY ALL
ORDER BY taxi DESC, anio;
```

**Resultado:**

| taxi | anio | registros | pct_fuera_periodo | pct_duracion | pct_distancia | pct_velocidad | pct_monto | pct_pasajeros | pct_excluido |
|---|---|---|---|---|---|---|---|---|---|
| yellow | 2,024 | 41,169,720 | 0.001 | 0.086 | 1.89 | 0.032 | 1.818 | 0.975 | 4.57 |
| yellow | 2,025 | 48,722,602 | 0 | 1.152 | 2.885 | 0.028 | 5.892 | 0.534 | 9.91 |
| yellow | 2,026 | 29,703,355 | 0 | 1.276 | 3.21 | 0.027 | 0.607 | 0.308 | 5.31 |
| green | 2,024 | 660,218 | 0.025 | 0.498 | 5.272 | 0.325 | 0.404 | 1.029 | 7.14 |
| green | 2,025 | 591,375 | 0.042 | 0.741 | 4.168 | 0.599 | 0.845 | 1.396 | 7.35 |
| green | 2,026 | 337,114 | 0.029 | 0.397 | 3.644 | 0.344 | 1.838 | 1.343 | 7.22 |

---

## 5.9 - Desglose de la regla de duracion por anio y proveedor

**Objetivo:** La consulta 5.8 muestra que la regla de duracion (<= 0 min o > 6 h) marca el 0.09 % de los amarillos de 2024 y el 1.28 % de 2026, 15 veces mas. Se separa en duracion exactamente 0, negativa y mayor a 6 horas, por proveedor, para saber si es un cambio en como se registran los datos (concentrado en un proveedor) o un cambio en los viajes.  
**Fuente:** vista viajes_enriquecidos (sin filtrar)  
**Archivo:** `sql/ejercicio5/5_09_desglose_duracion.sql`  
**Tiempo de ejecucion:** 10.450 s - **filas del resultado:** 20

```sql
-- @id: 5.9
-- @titulo: Desglose de la regla de duracion por anio y proveedor
-- @objetivo: La consulta 5.8 muestra que la regla de duracion (<= 0 min o
--   > 6 h) marca el 0.09 % de los amarillos de 2024 y el 1.28 % de 2026, 15
--   veces mas. Se separa en duracion exactamente 0, negativa y mayor a 6 horas,
--   por proveedor, para saber si es un cambio en como se registran los datos
--   (concentrado en un proveedor) o un cambio en los viajes.
-- @fuente: vista viajes_enriquecidos (sin filtrar)
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    vendor_id,
    count(*)                                                        AS registros,
    count(*) FILTER (WHERE duracion_min = 0)                        AS duracion_cero,
    count(*) FILTER (WHERE duracion_min < 0)                        AS duracion_negativa,
    count(*) FILTER (WHERE duracion_min > 360)                      AS duracion_mas_6h,
    round(100.0 * avg(f_duracion::INT), 3)                          AS pct_regla_duracion,
    round(100.0 * count(*) FILTER (WHERE duracion_min = 0 AND trip_distance > 0)
          / nullif(count(*) FILTER (WHERE duracion_min = 0), 0), 1) AS pct_cero_con_distancia
FROM viajes_enriquecidos
GROUP BY ALL
ORDER BY taxi DESC, anio, vendor_id;
```

**Resultado:**

| taxi | anio | vendor_id | registros | duracion_cero | duracion_negativa | duracion_mas_6h | pct_regla_duracion | pct_cero_con_distancia |
|---|---|---|---|---|---|---|---|---|
| yellow | 2,024 | 1 | 9,715,918 | 10,610 | 389 | 201 | 0.115 | 2.7 |
| yellow | 2,024 | 2 | 31,451,503 | 1,076 | 759 | 21,821 | 0.075 | 25.6 |
| yellow | 2,024 | 6 | 2,069 | 19 | 427 | 1 | 21.605 | 100 |
| yellow | 2,024 | 7 | 230 | 230 | 0 | 0 | 100 | 99.1 |
| yellow | 2,025 | 1 | 9,586,873 | 7,188 | 373 | 2,258 | 0.102 | 2.8 |
| yellow | 2,025 | 2 | 38,575,846 | 947 | 1,112 | 12,652 | 0.038 | 36 |
| yellow | 2,025 | 6 | 23,982 | 33 | 750 | 6 | 3.29 | 100 |
| yellow | 2,025 | 7 | 535,901 | 535,901 | 0 | 0 | 100 | 98.5 |
| yellow | 2,026 | 1 | 5,467,071 | 4,297 | 4 | 1,442 | 0.105 | 1.8 |
| yellow | 2,026 | 2 | 23,809,774 | 256 | 2 | 5,863 | 0.026 | 39.5 |
| yellow | 2,026 | 6 | 59,390 | 0 | 4 | 10 | 0.024 | NULL |
| yellow | 2,026 | 7 | 367,120 | 367,120 | 0 | 0 | 100 | 98.2 |
| green | 2,024 | 1 | 80,450 | 327 | 1 | 0 | 0.408 | 5.2 |
| green | 2,024 | 2 | 579,768 | 333 | 1 | 2,629 | 0.511 | 20.7 |
| green | 2,025 | 1 | 65,489 | 249 | 2 | 0 | 0.383 | 4.8 |
| green | 2,025 | 2 | 498,801 | 272 | 3 | 2,464 | 0.549 | 15.8 |
| green | 2,025 | 6 | 27,085 | 45 | 1,339 | 10 | 5.147 | 100 |
| green | 2,026 | 1 | 28,696 | 86 | 0 | 0 | 0.3 | 2.3 |
| green | 2,026 | 2 | 273,571 | 143 | 0 | 1,101 | 0.455 | 16.1 |
| green | 2,026 | 6 | 34,847 | 0 | 5 | 3 | 0.023 | NULL |
