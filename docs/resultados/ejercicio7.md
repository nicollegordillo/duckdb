# Resultados de sql/ejercicio7

Generado automaticamente el 2026-10-08T22:17:27 con `python scripts/run_sql.py ejercicio7 --anio 2024 2026 --tablero`.
No editar a mano: volver a ejecutar el script tras cambiar las consultas.

DuckDB 1.5.5

## I1 - Demanda diaria y participacion de cada tipo de taxi, por mes

**Pregunta:** Q1 Como evoluciona la demanda diaria de cada tipo de taxi mes a mes? Q2 Que peso tienen los taxis verdes dentro del sistema y esta cambiando?  
**Indicador:** viajes validos por dia (viajes del mes / dias con viajes) y % de los viajes del mes que corresponde a cada tipo.  
**Justificacion:** es la medida basica de actividad. Se usa por dia y no el total del mes porque los meses tienen distinta cantidad de dias; la participacion muestra si los verdes ganan o pierden mercado.  
**Visualizacion:** lineas, mes en el eje x y una serie por anio (filtro por tipo).  
**Fuente:** vista viajes_validos  
**Archivo:** `sql/ejercicio7/7_01_demanda_diaria.sql`  
**Tiempo de ejecucion:** 14.023 s - **filas del resultado:** 40

```sql
-- @id: I1
-- @titulo: Demanda diaria y participacion de cada tipo de taxi, por mes
-- @pregunta: Q1 Como evoluciona la demanda diaria de cada tipo de taxi mes a
--   mes? Q2 Que peso tienen los taxis verdes dentro del sistema y esta cambiando?
-- @indicador: viajes validos por dia (viajes del mes / dias con viajes) y % de
--   los viajes del mes que corresponde a cada tipo.
-- @justificacion: es la medida basica de actividad. Se usa por dia y no el
--   total del mes porque los meses tienen distinta cantidad de dias; la
--   participacion muestra si los verdes ganan o pierden mercado.
-- @visualizacion: lineas, mes en el eje x y una serie por anio (filtro por tipo).
-- @tabla: ind_demanda
-- @fuente: vista viajes_validos
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    mes_archivo                                                     AS mes,
    make_date(anio_archivo, mes_archivo, 1)                         AS periodo,
    count(*)                                                        AS viajes,
    count(DISTINCT fecha)                                           AS dias,
    round(count(*) / count(DISTINCT fecha), 0)                      AS viajes_por_dia,
    round(100.0 * count(*)
          / sum(count(*)) OVER (PARTITION BY anio_archivo, mes_archivo), 2) AS pct_del_mes
FROM viajes_validos
GROUP BY taxi, anio_archivo, mes_archivo
ORDER BY taxi DESC, anio, mes;
```

**Resultado:**

| taxi | anio | mes | periodo | viajes | dias | viajes_por_dia | pct_del_mes |
|---|---|---|---|---|---|---|---|
| yellow | 2,024 | 1 | 2024-01-01 00:00:00 | 2,836,223 | 31 | 91,491 | 98.18 |
| yellow | 2,024 | 2 | 2024-02-01 00:00:00 | 2,865,951 | 29 | 98,826 | 98.29 |
| yellow | 2,024 | 3 | 2024-03-01 00:00:00 | 3,398,154 | 31 | 109,618 | 98.45 |
| yellow | 2,024 | 4 | 2024-04-01 00:00:00 | 3,373,190 | 30 | 112,440 | 98.47 |
| yellow | 2,024 | 5 | 2024-05-01 00:00:00 | 3,575,459 | 31 | 115,337 | 98.44 |
| yellow | 2,024 | 6 | 2024-06-01 00:00:00 | 3,391,071 | 30 | 113,036 | 98.52 |
| yellow | 2,024 | 7 | 2024-07-01 00:00:00 | 2,943,435 | 31 | 94,950 | 98.4 |
| yellow | 2,024 | 8 | 2024-08-01 00:00:00 | 2,839,716 | 31 | 91,604 | 98.34 |
| yellow | 2,024 | 9 | 2024-09-01 00:00:00 | 3,452,355 | 30 | 115,079 | 98.56 |
| yellow | 2,024 | 10 | 2024-10-01 00:00:00 | 3,644,845 | 31 | 117,576 | 98.58 |
| yellow | 2,024 | 11 | 2024-11-01 00:00:00 | 3,479,841 | 30 | 115,995 | 98.63 |
| yellow | 2,024 | 12 | 2024-12-01 00:00:00 | 3,486,595 | 31 | 112,471 | 98.59 |
| yellow | 2,026 | 1 | 2026-01-01 00:00:00 | 3,500,703 | 31 | 112,926 | 98.94 |
| yellow | 2,026 | 2 | 2026-02-01 00:00:00 | 3,196,364 | 28 | 114,156 | 98.93 |
| yellow | 2,026 | 3 | 2026-03-01 00:00:00 | 3,748,151 | 31 | 120,908 | 98.91 |
| yellow | 2,026 | 4 | 2026-04-01 00:00:00 | 3,660,483 | 30 | 122,016 | 98.89 |
| yellow | 2,026 | 5 | 2026-05-01 00:00:00 | 3,897,714 | 31 | 125,733 | 98.94 |
| yellow | 2,026 | 6 | 2026-06-01 00:00:00 | 3,633,908 | 30 | 121,130 | 98.88 |
| yellow | 2,026 | 7 | 2026-07-01 00:00:00 | 3,335,678 | 31 | 107,603 | 98.87 |
| yellow | 2,026 | 8 | 2026-08-01 00:00:00 | 3,154,473 | 31 | 101,757 | 98.82 |
| green | 2,024 | 1 | 2024-01-01 00:00:00 | 52,662 | 31 | 1,699 | 1.82 |
| green | 2,024 | 2 | 2024-02-01 00:00:00 | 49,771 | 29 | 1,716 | 1.71 |
| green | 2,024 | 3 | 2024-03-01 00:00:00 | 53,427 | 31 | 1,723 | 1.55 |
| green | 2,024 | 4 | 2024-04-01 00:00:00 | 52,404 | 30 | 1,747 | 1.53 |
| green | 2,024 | 5 | 2024-05-01 00:00:00 | 56,814 | 31 | 1,833 | 1.56 |
| green | 2,024 | 6 | 2024-06-01 00:00:00 | 51,048 | 30 | 1,702 | 1.48 |
| green | 2,024 | 7 | 2024-07-01 00:00:00 | 47,897 | 31 | 1,545 | 1.6 |
| green | 2,024 | 8 | 2024-08-01 00:00:00 | 47,971 | 31 | 1,547 | 1.66 |
| green | 2,024 | 9 | 2024-09-01 00:00:00 | 50,545 | 30 | 1,685 | 1.44 |
| green | 2,024 | 10 | 2024-10-01 00:00:00 | 52,447 | 31 | 1,692 | 1.42 |
| green | 2,024 | 11 | 2024-11-01 00:00:00 | 48,306 | 30 | 1,610 | 1.37 |
| green | 2,024 | 12 | 2024-12-01 00:00:00 | 49,782 | 31 | 1,606 | 1.41 |
| green | 2,026 | 1 | 2026-01-01 00:00:00 | 37,567 | 31 | 1,212 | 1.06 |
| green | 2,026 | 2 | 2026-02-01 00:00:00 | 34,593 | 28 | 1,235 | 1.07 |
| green | 2,026 | 3 | 2026-03-01 00:00:00 | 41,154 | 31 | 1,328 | 1.09 |
| green | 2,026 | 4 | 2026-04-01 00:00:00 | 41,085 | 30 | 1,370 | 1.11 |
| green | 2,026 | 5 | 2026-05-01 00:00:00 | 41,794 | 31 | 1,348 | 1.06 |
| green | 2,026 | 6 | 2026-06-01 00:00:00 | 41,011 | 30 | 1,367 | 1.12 |
| green | 2,026 | 7 | 2026-07-01 00:00:00 | 38,019 | 31 | 1,226 | 1.13 |
| green | 2,026 | 8 | 2026-08-01 00:00:00 | 37,554 | 31 | 1,211 | 1.18 |

---

## I2 - Costo del viaje tipico y facturacion diaria, por mes

**Pregunta:** Q3 Cuanto paga un pasajero en un viaje tipico, cuanto factura el sistema por dia y como cambia en el tiempo?  
**Indicador:** total mediano por viaje (USD), total promedio, facturacion registrada por dia (suma de total_amount / dias) y tarifa base mediana por milla.  
**Justificacion:** total_amount es la variable de negocio. Se reporta la mediana porque la distribucion es muy asimetrica (Ejercicio 4, P3/P8). La tarifa por milla separa el efecto de precio del de viajes mas largos. La facturacion no incluye propinas en efectivo, que la TLC no registra (Ejercicio 4, P6).  
**Visualizacion:** lineas por mes (una serie por anio); facturacion diaria en barras.  
**Fuente:** vista viajes_validos  
**Archivo:** `sql/ejercicio7/7_02_costo_y_facturacion.sql`  
**Tiempo de ejecucion:** 23.220 s - **filas del resultado:** 40

```sql
-- @id: I2
-- @titulo: Costo del viaje tipico y facturacion diaria, por mes
-- @pregunta: Q3 Cuanto paga un pasajero en un viaje tipico, cuanto factura el
--   sistema por dia y como cambia en el tiempo?
-- @indicador: total mediano por viaje (USD), total promedio, facturacion
--   registrada por dia (suma de total_amount / dias) y tarifa base mediana por milla.
-- @justificacion: total_amount es la variable de negocio. Se reporta la mediana
--   porque la distribucion es muy asimetrica (Ejercicio 4, P3/P8). La tarifa por
--   milla separa el efecto de precio del de viajes mas largos. La facturacion
--   no incluye propinas en efectivo, que la TLC no registra (Ejercicio 4, P6).
-- @visualizacion: lineas por mes (una serie por anio); facturacion diaria en barras.
-- @tabla: ind_costo
-- @fuente: vista viajes_validos

-- approx_quantile (T-Digest) en lugar de median(): memoria constante con
-- decenas de millones de filas (Ejercicio 4).
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    mes_archivo                                                     AS mes,
    make_date(anio_archivo, mes_archivo, 1)                         AS periodo,
    round(approx_quantile(total_amount, 0.5), 2)                    AS total_mediano,
    round(avg(total_amount), 2)                                     AS total_promedio,
    round(sum(total_amount) / count(DISTINCT fecha), 0)             AS facturacion_por_dia,
    round(approx_quantile(fare_amount / trip_distance, 0.5), 2)     AS tarifa_por_milla_mediana
FROM viajes_validos
GROUP BY ALL
ORDER BY taxi DESC, anio, mes;
```

**Resultado:**

| taxi | anio | mes | periodo | total_mediano | total_promedio | facturacion_por_dia | tarifa_por_milla_mediana |
|---|---|---|---|---|---|---|---|
| yellow | 2,024 | 1 | 2024-01-01 00:00:00 | 20.18 | 27.36 | 2,503,044 | 7.2 |
| yellow | 2,024 | 2 | 2024-02-01 00:00:00 | 20.41 | 27.26 | 2,693,819 | 7.25 |
| yellow | 2,024 | 3 | 2024-03-01 00:00:00 | 20.75 | 27.88 | 3,056,605 | 7.21 |
| yellow | 2,024 | 4 | 2024-04-01 00:00:00 | 21.03 | 28.22 | 3,172,628 | 7.25 |
| yellow | 2,024 | 5 | 2024-05-01 00:00:00 | 21.65 | 29.03 | 3,348,604 | 7.45 |
| yellow | 2,024 | 6 | 2024-06-01 00:00:00 | 21.32 | 28.72 | 3,245,905 | 7.32 |
| yellow | 2,024 | 7 | 2024-07-01 00:00:00 | 21.1 | 29.01 | 2,754,191 | 7.16 |
| yellow | 2,024 | 8 | 2024-08-01 00:00:00 | 21.1 | 29.25 | 2,679,166 | 7.13 |
| yellow | 2,024 | 9 | 2024-09-01 00:00:00 | 21.82 | 29.51 | 3,395,933 | 7.45 |
| yellow | 2,024 | 10 | 2024-10-01 00:00:00 | 21.8 | 29.4 | 3,456,533 | 7.53 |
| yellow | 2,024 | 11 | 2024-11-01 00:00:00 | 21.32 | 28.6 | 3,317,939 | 7.57 |
| yellow | 2,024 | 12 | 2024-12-01 00:00:00 | 21.94 | 29.4 | 3,307,065 | 7.79 |
| yellow | 2,026 | 1 | 2026-01-01 00:00:00 | 23.15 | 29.69 | 3,352,573 | 7.54 |
| yellow | 2,026 | 2 | 2026-02-01 00:00:00 | 24.05 | 30.47 | 3,478,645 | 7.92 |
| yellow | 2,026 | 3 | 2026-03-01 00:00:00 | 23.39 | 30.28 | 3,661,180 | 7.56 |
| yellow | 2,026 | 4 | 2026-04-01 00:00:00 | 23.57 | 30.11 | 3,674,096 | 7.61 |
| yellow | 2,026 | 5 | 2026-05-01 00:00:00 | 23.86 | 30.56 | 3,842,599 | 7.64 |
| yellow | 2,026 | 6 | 2026-06-01 00:00:00 | 23.79 | 30.61 | 3,708,183 | 7.7 |
| yellow | 2,026 | 7 | 2026-07-01 00:00:00 | 23.51 | 30.15 | 3,243,960 | 7.31 |
| yellow | 2,026 | 8 | 2026-08-01 00:00:00 | 23.54 | 30.16 | 3,069,452 | 7.1 |
| green | 2,024 | 1 | 2024-01-01 00:00:00 | 18.29 | 22.18 | 37,686 | 6.8 |
| green | 2,024 | 2 | 2024-02-01 00:00:00 | 18.43 | 22.47 | 38,569 | 6.79 |
| green | 2,024 | 3 | 2024-03-01 00:00:00 | 18.49 | 22.75 | 39,216 | 6.86 |
| green | 2,024 | 4 | 2024-04-01 00:00:00 | 18.93 | 23.28 | 40,673 | 6.83 |
| green | 2,024 | 5 | 2024-05-01 00:00:00 | 19.83 | 24.49 | 44,875 | 6.94 |
| green | 2,024 | 6 | 2024-06-01 00:00:00 | 19.69 | 24.76 | 42,130 | 6.8 |
| green | 2,024 | 7 | 2024-07-01 00:00:00 | 19.49 | 24.46 | 37,796 | 6.65 |
| green | 2,024 | 8 | 2024-08-01 00:00:00 | 19.86 | 25.85 | 40,004 | 6.62 |
| green | 2,024 | 9 | 2024-09-01 00:00:00 | 20.31 | 26.53 | 44,694 | 6.86 |
| green | 2,024 | 10 | 2024-10-01 00:00:00 | 19.79 | 24.96 | 42,223 | 6.86 |
| green | 2,024 | 11 | 2024-11-01 00:00:00 | 19.35 | 23.98 | 38,615 | 6.92 |
| green | 2,024 | 12 | 2024-12-01 00:00:00 | 19.17 | 23.82 | 38,252 | 6.9 |
| green | 2,026 | 1 | 2026-01-01 00:00:00 | 20.01 | 24.16 | 29,281 | 6.87 |
| green | 2,026 | 2 | 2026-02-01 00:00:00 | 20.07 | 24.32 | 30,041 | 6.96 |
| green | 2,026 | 3 | 2026-03-01 00:00:00 | 20.33 | 24.78 | 32,891 | 6.63 |
| green | 2,026 | 4 | 2026-04-01 00:00:00 | 20.37 | 25.23 | 34,556 | 6.64 |
| green | 2,026 | 5 | 2026-05-01 00:00:00 | 20.75 | 25.79 | 34,772 | 6.79 |
| green | 2,026 | 6 | 2026-06-01 00:00:00 | 20.92 | 26.06 | 35,622 | 6.73 |
| green | 2,026 | 7 | 2026-07-01 00:00:00 | 20.67 | 26.1 | 32,009 | 6.57 |
| green | 2,026 | 8 | 2026-08-01 00:00:00 | 20.89 | 26.42 | 32,001 | 6.54 |

---

## I3 - Viajes promedio por hora en un dia laborable y en fin de semana

**Pregunta:** Q4 En que horas se concentra la demanda en dias laborables frente a fines de semana, y se mantiene ese patron entre anios?  
**Indicador:** viajes promedio que inician en cada hora en un dia laborable o de fin de semana (viajes de esa hora / dias de ese tipo) y % del dia.  
**Justificacion:** dimensiona la oferta necesaria por hora. Se divide entre los dias de cada tipo porque hay ~2.5 veces mas dias laborables que de fin de semana; el % del dia permite comparar la forma entre anios aunque cambie el volumen.  
**Visualizacion:** lineas, hora en el eje x y una serie por anio y tipo de dia.  
**Fuente:** vista viajes_validos  
**Archivo:** `sql/ejercicio7/7_03_perfil_horario.sql`  
**Tiempo de ejecucion:** 17.545 s - **filas del resultado:** 192

```sql
-- @id: I3
-- @titulo: Viajes promedio por hora en un dia laborable y en fin de semana
-- @pregunta: Q4 En que horas se concentra la demanda en dias laborables frente
--   a fines de semana, y se mantiene ese patron entre anios?
-- @indicador: viajes promedio que inician en cada hora en un dia laborable o
--   de fin de semana (viajes de esa hora / dias de ese tipo) y % del dia.
-- @justificacion: dimensiona la oferta necesaria por hora. Se divide entre los
--   dias de cada tipo porque hay ~2.5 veces mas dias laborables que de fin de
--   semana; el % del dia permite comparar la forma entre anios aunque cambie
--   el volumen.
-- @visualizacion: lineas, hora en el eje x y una serie por anio y tipo de dia.
-- @tabla: ind_perfil_horario
-- @fuente: vista viajes_validos

-- Primero se agrega por fecha y hora (unas 70 mil filas): si la CTE leyera los
-- viajes y se usara dos veces, DuckDB la materializaria completa (decenas de
-- millones de filas) y se queda sin memoria (mismo caso que 3.6e, Ejercicio 5).
WITH por_fecha_hora AS (
    SELECT
        taxi,
        anio_archivo                                                AS anio,
        CASE WHEN dia_semana <= 5 THEN 'Laborable' ELSE 'Fin de semana' END AS tipo_dia,
        fecha,
        hora,
        count(*)                                                    AS viajes
    FROM viajes_validos
    GROUP BY ALL
),
por_hora AS (
    SELECT taxi, anio, tipo_dia, hora, sum(viajes) AS viajes
    FROM por_fecha_hora
    GROUP BY ALL
),
dias AS (
    SELECT taxi, anio, tipo_dia, count(DISTINCT fecha) AS dias
    FROM por_fecha_hora
    GROUP BY ALL
)
SELECT
    h.taxi,
    h.anio,
    h.tipo_dia,
    h.anio || ' - ' || h.tipo_dia                                   AS serie,
    h.hora,
    h.viajes,
    d.dias,
    round(h.viajes / d.dias, 1)                                     AS viajes_promedio,
    round(100.0 * h.viajes
          / sum(h.viajes) OVER (PARTITION BY h.taxi, h.anio, h.tipo_dia), 2) AS pct_del_dia
FROM por_hora h
JOIN dias d USING (taxi, anio, tipo_dia)
ORDER BY h.taxi DESC, h.anio, h.tipo_dia DESC, h.hora;
```

**Resultado:**

| taxi | anio | tipo_dia | serie | hora | viajes | dias | viajes_promedio | pct_del_dia |
|---|---|---|---|---|---|---|---|---|
| yellow | 2,024 | Laborable | 2024 - Laborable | 0 | 533,904 | 262 | 2,037.8 | 1.89 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 1 | 254,716 | 262 | 972.2 | 0.9 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 2 | 137,922 | 262 | 526.4 | 0.49 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 3 | 91,449 | 262 | 349 | 0.32 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 4 | 100,280 | 262 | 382.7 | 0.35 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 5 | 188,451 | 262 | 719.3 | 0.67 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 6 | 462,786 | 262 | 1,766.4 | 1.63 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 7 | 945,957 | 262 | 3,610.5 | 3.34 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 8 | 1,282,233 | 262 | 4,894 | 4.53 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 9 | 1,303,934 | 262 | 4,976.8 | 4.61 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 10 | 1,308,521 | 262 | 4,994.4 | 4.62 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 11 | 1,378,643 | 262 | 5,262 | 4.87 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 12 | 1,481,812 | 262 | 5,655.8 | 5.23 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 13 | 1,534,746 | 262 | 5,857.8 | 5.42 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 14 | 1,683,114 | 262 | 6,424.1 | 5.95 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 15 | 1,752,840 | 262 | 6,690.2 | 6.19 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 16 | 1,749,311 | 262 | 6,676.8 | 6.18 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 17 | 1,966,853 | 262 | 7,507.1 | 6.95 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 18 | 2,097,161 | 262 | 8,004.4 | 7.41 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 19 | 1,822,446 | 262 | 6,955.9 | 6.44 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 20 | 1,702,461 | 262 | 6,497.9 | 6.01 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 21 | 1,768,934 | 262 | 6,751.7 | 6.25 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 22 | 1,599,635 | 262 | 6,105.5 | 5.65 |
| yellow | 2,024 | Laborable | 2024 - Laborable | 23 | 1,162,614 | 262 | 4,437.5 | 4.11 |
| yellow | 2,024 | Fin de semana | 2024 - Fin de semana | 0 | 599,778 | 104 | 5,767.1 | 5.46 |
| yellow | 2,024 | Fin de semana | 2024 - Fin de semana | 1 | 477,558 | 104 | 4,591.9 | 4.35 |
| yellow | 2,024 | Fin de semana | 2024 - Fin de semana | 2 | 336,945 | 104 | 3,239.9 | 3.07 |
| yellow | 2,024 | Fin de semana | 2024 - Fin de semana | 3 | 218,116 | 104 | 2,097.3 | 1.99 |
| yellow | 2,024 | Fin de semana | 2024 - Fin de semana | 4 | 124,940 | 104 | 1,201.3 | 1.14 |
| yellow | 2,024 | Fin de semana | 2024 - Fin de semana | 5 | 58,280 | 104 | 560.4 | 0.53 |
| yellow | 2,024 | Fin de semana | 2024 - Fin de semana | 6 | 92,808 | 104 | 892.4 | 0.85 |
| yellow | 2,024 | Fin de semana | 2024 - Fin de semana | 7 | 137,139 | 104 | 1,318.6 | 1.25 |
| yellow | 2,024 | Fin de semana | 2024 - Fin de semana | 8 | 215,109 | 104 | 2,068.4 | 1.96 |
| yellow | 2,024 | Fin de semana | 2024 - Fin de semana | 9 | 335,884 | 104 | 3,229.7 | 3.06 |
| yellow | 2,024 | Fin de semana | 2024 - Fin de semana | 10 | 449,638 | 104 | 4,323.4 | 4.1 |
| yellow | 2,024 | Fin de semana | 2024 - Fin de semana | 11 | 531,943 | 104 | 5,114.8 | 4.85 |
| yellow | 2,024 | Fin de semana | 2024 - Fin de semana | 12 | 605,414 | 104 | 5,821.3 | 5.52 |
| yellow | 2,024 | Fin de semana | 2024 - Fin de semana | 13 | 635,711 | 104 | 6,112.6 | 5.79 |
| yellow | 2,024 | Fin de semana | 2024 - Fin de semana | 14 | 645,239 | 104 | 6,204.2 | 5.88 |
| yellow | 2,024 | Fin de semana | 2024 - Fin de semana | 15 | 652,584 | 104 | 6,274.8 | 5.95 |

_... 152 filas mas (ver CSV)._

---

## I4 - Velocidad mediana por hora en dias laborables

**Pregunta:** Q5 A que horas es mas lento el trafico para los taxis y cuanto cambia la duracion de un viaje entre la hora mas lenta y la mas rapida?  
**Indicador:** velocidad mediana (mph) y minutos medianos por milla de los viajes que inician en cada hora, de lunes a viernes.  
**Justificacion:** la velocidad promedio de un viaje es un indicador indirecto de congestion; los minutos por milla traducen esa velocidad a tiempo para el pasajero. Solo dias laborables, para que el fin de semana no suavice las horas pico.  
**Visualizacion:** lineas, hora en el eje x y una serie por anio (filtro por tipo).  
**Fuente:** vista viajes_validos  
**Archivo:** `sql/ejercicio7/7_04_velocidad_por_hora.sql`  
**Tiempo de ejecucion:** 18.607 s - **filas del resultado:** 96

```sql
-- @id: I4
-- @titulo: Velocidad mediana por hora en dias laborables
-- @pregunta: Q5 A que horas es mas lento el trafico para los taxis y cuanto
--   cambia la duracion de un viaje entre la hora mas lenta y la mas rapida?
-- @indicador: velocidad mediana (mph) y minutos medianos por milla de los
--   viajes que inician en cada hora, de lunes a viernes.
-- @justificacion: la velocidad promedio de un viaje es un indicador indirecto
--   de congestion; los minutos por milla traducen esa velocidad a tiempo para
--   el pasajero. Solo dias laborables, para que el fin de semana no suavice
--   las horas pico.
-- @visualizacion: lineas, hora en el eje x y una serie por anio (filtro por tipo).
-- @tabla: ind_velocidad_hora
-- @fuente: vista viajes_validos
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    hora,
    count(*)                                                        AS viajes,
    round(approx_quantile(velocidad_mph, 0.5), 2)                   AS mph_mediana,
    round(approx_quantile(duracion_min / trip_distance, 0.5), 2)    AS min_por_milla_mediana
FROM viajes_validos
WHERE dia_semana <= 5
GROUP BY ALL
ORDER BY taxi DESC, anio, hora;
```

**Resultado:**

| taxi | anio | hora | viajes | mph_mediana | min_por_milla_mediana |
|---|---|---|---|---|---|
| yellow | 2,024 | 0 | 533,904 | 13.41 | 4.47 |
| yellow | 2,024 | 1 | 254,716 | 14.09 | 4.25 |
| yellow | 2,024 | 2 | 137,922 | 14.28 | 4.2 |
| yellow | 2,024 | 3 | 91,449 | 15.07 | 3.98 |
| yellow | 2,024 | 4 | 100,280 | 17.29 | 3.47 |
| yellow | 2,024 | 5 | 188,451 | 16.15 | 3.72 |
| yellow | 2,024 | 6 | 462,786 | 13.54 | 4.43 |
| yellow | 2,024 | 7 | 945,957 | 10.72 | 5.6 |
| yellow | 2,024 | 8 | 1,282,233 | 8.75 | 6.85 |
| yellow | 2,024 | 9 | 1,303,934 | 8.2 | 7.32 |
| yellow | 2,024 | 10 | 1,308,521 | 7.88 | 7.62 |
| yellow | 2,024 | 11 | 1,378,643 | 7.5 | 8.01 |
| yellow | 2,024 | 12 | 1,481,812 | 7.56 | 7.94 |
| yellow | 2,024 | 13 | 1,534,746 | 7.79 | 7.7 |
| yellow | 2,024 | 14 | 1,683,114 | 7.71 | 7.78 |
| yellow | 2,024 | 15 | 1,752,840 | 7.67 | 7.82 |
| yellow | 2,024 | 16 | 1,749,311 | 7.97 | 7.53 |
| yellow | 2,024 | 17 | 1,966,853 | 7.98 | 7.51 |
| yellow | 2,024 | 18 | 2,097,161 | 8.36 | 7.17 |
| yellow | 2,024 | 19 | 1,822,446 | 9.19 | 6.54 |
| yellow | 2,024 | 20 | 1,702,461 | 9.93 | 6.04 |
| yellow | 2,024 | 21 | 1,768,934 | 10.38 | 5.78 |
| yellow | 2,024 | 22 | 1,599,635 | 10.79 | 5.56 |
| yellow | 2,024 | 23 | 1,162,614 | 11.53 | 5.2 |
| yellow | 2,026 | 0 | 424,211 | 13.39 | 4.48 |
| yellow | 2,026 | 1 | 222,776 | 14.36 | 4.18 |
| yellow | 2,026 | 2 | 126,677 | 14.86 | 4.04 |
| yellow | 2,026 | 3 | 88,342 | 15.53 | 3.87 |
| yellow | 2,026 | 4 | 102,833 | 16.81 | 3.57 |
| yellow | 2,026 | 5 | 192,328 | 15.78 | 3.8 |
| yellow | 2,026 | 6 | 401,974 | 13.34 | 4.5 |
| yellow | 2,026 | 7 | 740,900 | 10.63 | 5.65 |
| yellow | 2,026 | 8 | 982,259 | 8.8 | 6.81 |
| yellow | 2,026 | 9 | 951,442 | 8.1 | 7.41 |
| yellow | 2,026 | 10 | 899,320 | 7.69 | 7.81 |
| yellow | 2,026 | 11 | 936,274 | 7.32 | 8.2 |
| yellow | 2,026 | 12 | 996,849 | 7.41 | 8.1 |
| yellow | 2,026 | 13 | 1,033,971 | 7.57 | 7.92 |
| yellow | 2,026 | 14 | 1,149,902 | 7.57 | 7.93 |
| yellow | 2,026 | 15 | 1,208,104 | 7.41 | 8.1 |

_... 56 filas mas (ver CSV)._

---

## I5 - Velocidad de los viajes dentro de la zona de cobro por congestion

**Pregunta:** Q6 Cambio la velocidad de los viajes que empiezan y terminan dentro de la zona de cobro por congestion de Manhattan (CBD) despues de que empezo el cobro (5 de enero de 2025)?  
**Indicador:** velocidad mediana (mph) y duracion mediana de los viajes amarillos con origen y destino dentro de la zona, lunes a viernes de 7 a 19 h, por mes.  
**Justificacion:** el objetivo declarado del cobro es reducir el trafico en la zona; es la pregunta de politica publica que estos datos pueden responder. Se restringe a horario laboral y a viajes internos para comparar el mismo tipo de viaje antes y despues. El catalogo de zonas no indica cuales estan dentro de la zona de cobro. Se identifican con los propios datos: zonas de origen donde al menos el 90 % de los viajes amarillos desde 2025 paga cbd_congestion_fee (todo viaje que empieza dentro de la zona lo paga; los que empiezan fuera solo si entran). Con solo 2024 descargado la lista queda vacia y la consulta no devuelve filas.  
**Visualizacion:** lineas, mes en el eje x y una serie por anio.  
**Fuente:** vista viajes_validos  
**Archivo:** `sql/ejercicio7/7_05_velocidad_zona_congestion.sql`  
**Tiempo de ejecucion:** 20.585 s - **filas del resultado:** 20

```sql
-- @id: I5
-- @titulo: Velocidad de los viajes dentro de la zona de cobro por congestion
-- @pregunta: Q6 Cambio la velocidad de los viajes que empiezan y terminan
--   dentro de la zona de cobro por congestion de Manhattan (CBD) despues de que
--   empezo el cobro (5 de enero de 2025)?
-- @indicador: velocidad mediana (mph) y duracion mediana de los viajes
--   amarillos con origen y destino dentro de la zona, lunes a viernes de 7 a
--   19 h, por mes.
-- @justificacion: el objetivo declarado del cobro es reducir el trafico en la
--   zona; es la pregunta de politica publica que estos datos pueden responder.
--   Se restringe a horario laboral y a viajes internos para comparar el mismo
--   tipo de viaje antes y despues.
--   El catalogo de zonas no indica cuales estan dentro de la zona de cobro. Se
--   identifican con los propios datos: zonas de origen donde al menos el 90 %
--   de los viajes amarillos desde 2025 paga cbd_congestion_fee (todo viaje que
--   empieza dentro de la zona lo paga; los que empiezan fuera solo si entran).
--   Con solo 2024 descargado la lista queda vacia y la consulta no devuelve filas.
-- @visualizacion: lineas, mes en el eje x y una serie por anio.
-- @tabla: ind_velocidad_cbd
-- @fuente: vista viajes_validos
WITH zonas_cbd AS (
    SELECT pu_location_id AS location_id
    FROM viajes_validos
    WHERE taxi = 'yellow'
      AND anio_archivo >= 2025
      AND cbd_congestion_fee IS NOT NULL
    GROUP BY 1
    HAVING count(*) >= 1000
       AND avg(CASE WHEN cbd_congestion_fee > 0 THEN 1 ELSE 0 END) >= 0.9
)
SELECT
    anio_archivo                                                    AS anio,
    mes_archivo                                                     AS mes,
    make_date(anio_archivo, mes_archivo, 1)                         AS periodo,
    (SELECT count(*) FROM zonas_cbd)                                AS zonas_en_cbd,
    count(*)                                                        AS viajes,
    round(approx_quantile(velocidad_mph, 0.5), 2)                   AS mph_mediana,
    round(approx_quantile(duracion_min, 0.5), 1)                    AS duracion_mediana_min,
    round(approx_quantile(trip_distance, 0.5), 2)                   AS distancia_mediana_mi
FROM viajes_validos
WHERE taxi = 'yellow'
  AND dia_semana <= 5
  AND hora BETWEEN 7 AND 18
  AND pu_location_id IN (SELECT location_id FROM zonas_cbd)
  AND do_location_id IN (SELECT location_id FROM zonas_cbd)
GROUP BY ALL
ORDER BY anio, mes;
```

**Resultado:**

| anio | mes | periodo | zonas_en_cbd | viajes | mph_mediana | duracion_mediana_min | distancia_mediana_mi |
|---|---|---|---|---|---|---|---|
| 2,024 | 1 | 2024-01-01 00:00:00 | 38 | 536,615 | 7.67 | 10.8 | 1.27 |
| 2,024 | 2 | 2024-02-01 00:00:00 | 38 | 535,887 | 7.27 | 11.4 | 1.28 |
| 2,024 | 3 | 2024-03-01 00:00:00 | 38 | 587,474 | 7.04 | 12.1 | 1.3 |
| 2,024 | 4 | 2024-04-01 00:00:00 | 38 | 610,102 | 7.07 | 12.2 | 1.31 |
| 2,024 | 5 | 2024-05-01 00:00:00 | 38 | 654,937 | 6.8 | 12.7 | 1.31 |
| 2,024 | 6 | 2024-06-01 00:00:00 | 38 | 589,533 | 6.85 | 12.5 | 1.3 |
| 2,024 | 7 | 2024-07-01 00:00:00 | 38 | 603,406 | 7.08 | 12.1 | 1.29 |
| 2,024 | 8 | 2024-08-01 00:00:00 | 38 | 544,933 | 7.23 | 11.8 | 1.29 |
| 2,024 | 9 | 2024-09-01 00:00:00 | 38 | 588,991 | 6.59 | 13.1 | 1.31 |
| 2,024 | 10 | 2024-10-01 00:00:00 | 38 | 655,969 | 6.53 | 13.2 | 1.3 |
| 2,024 | 11 | 2024-11-01 00:00:00 | 38 | 588,573 | 6.72 | 12.6 | 1.28 |
| 2,024 | 12 | 2024-12-01 00:00:00 | 38 | 610,681 | 6.38 | 13.5 | 1.26 |
| 2,026 | 1 | 2026-01-01 00:00:00 | 38 | 551,884 | 7.14 | 11.9 | 1.29 |
| 2,026 | 2 | 2026-02-01 00:00:00 | 38 | 485,215 | 6.32 | 13.1 | 1.25 |
| 2,026 | 3 | 2026-03-01 00:00:00 | 38 | 601,841 | 6.81 | 12.3 | 1.26 |
| 2,026 | 4 | 2026-04-01 00:00:00 | 38 | 598,054 | 6.66 | 12.7 | 1.29 |
| 2,026 | 5 | 2026-05-01 00:00:00 | 38 | 579,961 | 6.32 | 13.6 | 1.3 |
| 2,026 | 6 | 2026-06-01 00:00:00 | 38 | 615,056 | 6.32 | 13.7 | 1.29 |
| 2,026 | 7 | 2026-07-01 00:00:00 | 38 | 616,526 | 6.52 | 13.3 | 1.29 |
| 2,026 | 8 | 2026-08-01 00:00:00 | 38 | 510,051 | 6.77 | 12.6 | 1.29 |

---

## I6 - Participacion de cada metodo de pago, por mes

**Pregunta:** Q7 Como pagan los pasajeros y que tan rapido crece el bloque Flex Fare / sin dato frente a tarjeta y efectivo?  
**Indicador:** % de los viajes de cada mes por metodo de pago (tarjeta, efectivo, Flex Fare / sin dato, otros).  
**Justificacion:** el metodo de pago condiciona que propinas se registran (Ejercicio 4, P6) y en el Ejercicio 5 el bloque Flex Fare explico casi todo el crecimiento de los amarillos. Se agrupan disputa, sin cargo, desconocido y anulado en "Otros" porque juntos son < 1 %.  
**Visualizacion:** barras apiladas al 100 % por mes (filtro por tipo).  
**Fuente:** vista viajes_validos  
**Archivo:** `sql/ejercicio7/7_06_metodo_pago.sql`  
**Tiempo de ejecucion:** 15.213 s - **filas del resultado:** 160

```sql
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
```

**Resultado:**

| taxi | anio | mes | periodo | metodo | viajes | pct |
|---|---|---|---|---|---|---|
| yellow | 2,024 | 1 | 2024-01-01 00:00:00 | Efectivo | 417,174 | 14.71 |
| yellow | 2,024 | 1 | 2024-01-01 00:00:00 | Flex fare / sin dato | 115,126 | 4.06 |
| yellow | 2,024 | 1 | 2024-01-01 00:00:00 | Otros | 32,192 | 1.14 |
| yellow | 2,024 | 1 | 2024-01-01 00:00:00 | Tarjeta | 2,271,731 | 80.1 |
| yellow | 2,024 | 2 | 2024-02-01 00:00:00 | Efectivo | 391,111 | 13.65 |
| yellow | 2,024 | 2 | 2024-02-01 00:00:00 | Flex fare / sin dato | 148,812 | 5.19 |
| yellow | 2,024 | 2 | 2024-02-01 00:00:00 | Otros | 32,675 | 1.14 |
| yellow | 2,024 | 2 | 2024-02-01 00:00:00 | Tarjeta | 2,293,353 | 80.02 |
| yellow | 2,024 | 3 | 2024-03-01 00:00:00 | Efectivo | 450,734 | 13.26 |
| yellow | 2,024 | 3 | 2024-03-01 00:00:00 | Flex fare / sin dato | 364,908 | 10.74 |
| yellow | 2,024 | 3 | 2024-03-01 00:00:00 | Otros | 40,201 | 1.18 |
| yellow | 2,024 | 3 | 2024-03-01 00:00:00 | Tarjeta | 2,542,311 | 74.81 |
| yellow | 2,024 | 4 | 2024-04-01 00:00:00 | Efectivo | 443,375 | 13.14 |
| yellow | 2,024 | 4 | 2024-04-01 00:00:00 | Flex fare / sin dato | 388,202 | 11.51 |
| yellow | 2,024 | 4 | 2024-04-01 00:00:00 | Otros | 38,751 | 1.15 |
| yellow | 2,024 | 4 | 2024-04-01 00:00:00 | Tarjeta | 2,502,862 | 74.2 |
| yellow | 2,024 | 5 | 2024-05-01 00:00:00 | Efectivo | 474,003 | 13.26 |
| yellow | 2,024 | 5 | 2024-05-01 00:00:00 | Flex fare / sin dato | 385,525 | 10.78 |
| yellow | 2,024 | 5 | 2024-05-01 00:00:00 | Otros | 43,219 | 1.21 |
| yellow | 2,024 | 5 | 2024-05-01 00:00:00 | Tarjeta | 2,672,712 | 74.75 |
| yellow | 2,024 | 6 | 2024-06-01 00:00:00 | Efectivo | 442,254 | 13.04 |
| yellow | 2,024 | 6 | 2024-06-01 00:00:00 | Flex fare / sin dato | 387,211 | 11.42 |
| yellow | 2,024 | 6 | 2024-06-01 00:00:00 | Otros | 43,164 | 1.27 |
| yellow | 2,024 | 6 | 2024-06-01 00:00:00 | Tarjeta | 2,518,442 | 74.27 |
| yellow | 2,024 | 7 | 2024-07-01 00:00:00 | Efectivo | 427,754 | 14.53 |
| yellow | 2,024 | 7 | 2024-07-01 00:00:00 | Flex fare / sin dato | 262,817 | 8.93 |
| yellow | 2,024 | 7 | 2024-07-01 00:00:00 | Otros | 44,726 | 1.52 |
| yellow | 2,024 | 7 | 2024-07-01 00:00:00 | Tarjeta | 2,208,138 | 75.02 |
| yellow | 2,024 | 8 | 2024-08-01 00:00:00 | Efectivo | 422,175 | 14.87 |
| yellow | 2,024 | 8 | 2024-08-01 00:00:00 | Flex fare / sin dato | 238,450 | 8.4 |
| yellow | 2,024 | 8 | 2024-08-01 00:00:00 | Otros | 46,654 | 1.64 |
| yellow | 2,024 | 8 | 2024-08-01 00:00:00 | Tarjeta | 2,132,437 | 75.09 |
| yellow | 2,024 | 9 | 2024-09-01 00:00:00 | Efectivo | 417,225 | 12.09 |
| yellow | 2,024 | 9 | 2024-09-01 00:00:00 | Flex fare / sin dato | 430,335 | 12.46 |
| yellow | 2,024 | 9 | 2024-09-01 00:00:00 | Otros | 48,920 | 1.42 |
| yellow | 2,024 | 9 | 2024-09-01 00:00:00 | Tarjeta | 2,555,875 | 74.03 |
| yellow | 2,024 | 10 | 2024-10-01 00:00:00 | Efectivo | 447,728 | 12.28 |
| yellow | 2,024 | 10 | 2024-10-01 00:00:00 | Flex fare / sin dato | 345,116 | 9.47 |
| yellow | 2,024 | 10 | 2024-10-01 00:00:00 | Otros | 53,427 | 1.47 |
| yellow | 2,024 | 10 | 2024-10-01 00:00:00 | Tarjeta | 2,798,574 | 76.78 |

_... 120 filas mas (ver CSV)._

---

## I7 - Propina de los pagos con tarjeta, por mes

**Pregunta:** Q8 Cuanto dejan de propina quienes pagan con tarjeta y es estable en el tiempo?  
**Indicador:** % de pagos con tarjeta que deja propina, % que deja exactamente el 20 % del total antes de propina, propina mediana como % del total antes de propina y propina mediana en USD.  
**Justificacion:** el Ejercicio 4 (P11) mostro que la propina se mide bien sobre el total antes de propina (asi la calcula la pantalla del taxi) y que 20 % es la opcion dominante. Solo tarjeta (la propina en efectivo no se registra) y solo el proveedor 2, cuyos totales son consistentes con sus componentes (Ejercicio 3, 3.6h).  
**Visualizacion:** lineas por mes (% con propina y % exactamente 20 %).  
**Fuente:** vista viajes_validos (payment_type = 1, vendor_id = 2)  
**Archivo:** `sql/ejercicio7/7_07_propina.sql`  
**Tiempo de ejecucion:** 15.303 s - **filas del resultado:** 40

```sql
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
```

**Resultado:**

| taxi | anio | mes | periodo | pagos_tarjeta | pct_con_propina | pct_propina_20 | propina_pct_mediana | propina_mediana_usd |
|---|---|---|---|---|---|---|---|---|
| yellow | 2,024 | 1 | 2024-01-01 00:00:00 | 1,738,514 | 96.55 | 54.1 | 20 | 3.19 |
| yellow | 2,024 | 2 | 2024-02-01 00:00:00 | 1,757,062 | 96.45 | 54.36 | 20 | 3.22 |
| yellow | 2,024 | 3 | 2024-03-01 00:00:00 | 1,943,901 | 96.25 | 54.45 | 20 | 3.28 |
| yellow | 2,024 | 4 | 2024-04-01 00:00:00 | 1,906,933 | 96.29 | 54.52 | 20 | 3.32 |
| yellow | 2,024 | 5 | 2024-05-01 00:00:00 | 2,033,933 | 96.11 | 54.37 | 20 | 3.38 |
| yellow | 2,024 | 6 | 2024-06-01 00:00:00 | 1,922,398 | 95.68 | 54.2 | 20 | 3.32 |
| yellow | 2,024 | 7 | 2024-07-01 00:00:00 | 1,695,215 | 95.15 | 53.5 | 20 | 3.31 |
| yellow | 2,024 | 8 | 2024-08-01 00:00:00 | 1,644,237 | 94.81 | 53.22 | 20 | 3.3 |
| yellow | 2,024 | 9 | 2024-09-01 00:00:00 | 1,962,926 | 95.49 | 54.05 | 20 | 3.41 |
| yellow | 2,024 | 10 | 2024-10-01 00:00:00 | 2,142,125 | 95.82 | 54.45 | 20 | 3.44 |
| yellow | 2,024 | 11 | 2024-11-01 00:00:00 | 2,047,620 | 95.71 | 54.53 | 20 | 3.33 |
| yellow | 2,024 | 12 | 2024-12-01 00:00:00 | 2,079,918 | 95.69 | 54.31 | 20 | 3.42 |
| yellow | 2,026 | 1 | 2026-01-01 00:00:00 | 1,689,822 | 95.27 | 52.95 | 20 | 3.3 |
| yellow | 2,026 | 2 | 2026-02-01 00:00:00 | 1,547,459 | 95.15 | 52.93 | 20 | 3.35 |
| yellow | 2,026 | 3 | 2026-03-01 00:00:00 | 1,967,793 | 95.23 | 53.51 | 20 | 3.34 |
| yellow | 2,026 | 4 | 2026-04-01 00:00:00 | 1,986,526 | 95.25 | 53.44 | 20 | 3.42 |
| yellow | 2,026 | 5 | 2026-05-01 00:00:00 | 2,056,199 | 95.01 | 53.24 | 20 | 3.45 |
| yellow | 2,026 | 6 | 2026-06-01 00:00:00 | 1,941,401 | 94.71 | 53.03 | 20 | 3.45 |
| yellow | 2,026 | 7 | 2026-07-01 00:00:00 | 1,688,917 | 94 | 52.55 | 20 | 3.42 |
| yellow | 2,026 | 8 | 2026-08-01 00:00:00 | 1,571,940 | 93.98 | 52.34 | 20 | 3.39 |
| green | 2,024 | 1 | 2024-01-01 00:00:00 | 30,399 | 91.63 | 47.8 | 20 | 2.97 |
| green | 2,024 | 2 | 2024-02-01 00:00:00 | 29,353 | 91.41 | 48.22 | 20 | 2.98 |
| green | 2,024 | 3 | 2024-03-01 00:00:00 | 31,958 | 91.54 | 48.13 | 20 | 3 |
| green | 2,024 | 4 | 2024-04-01 00:00:00 | 32,868 | 91.68 | 49.2 | 20 | 3 |
| green | 2,024 | 5 | 2024-05-01 00:00:00 | 35,697 | 91.63 | 49.2 | 20 | 3.1 |
| green | 2,024 | 6 | 2024-06-01 00:00:00 | 32,125 | 91.24 | 48.89 | 20 | 3.08 |
| green | 2,024 | 7 | 2024-07-01 00:00:00 | 30,187 | 91.46 | 48.84 | 20 | 3.04 |
| green | 2,024 | 8 | 2024-08-01 00:00:00 | 30,212 | 90.35 | 48.48 | 20 | 3.07 |
| green | 2,024 | 9 | 2024-09-01 00:00:00 | 32,140 | 90.97 | 48.29 | 20 | 3.13 |
| green | 2,024 | 10 | 2024-10-01 00:00:00 | 33,672 | 91.53 | 49.55 | 20 | 3.07 |
| green | 2,024 | 11 | 2024-11-01 00:00:00 | 31,408 | 91.35 | 48.92 | 20 | 3.01 |
| green | 2,024 | 12 | 2024-12-01 00:00:00 | 31,598 | 91.38 | 48.34 | 20 | 3 |
| green | 2,026 | 1 | 2026-01-01 00:00:00 | 22,621 | 91.57 | 49.1 | 20 | 3.04 |
| green | 2,026 | 2 | 2026-02-01 00:00:00 | 20,699 | 91.23 | 48.65 | 20 | 3.04 |
| green | 2,026 | 3 | 2026-03-01 00:00:00 | 24,708 | 91.58 | 49.29 | 20 | 3.1 |
| green | 2,026 | 4 | 2026-04-01 00:00:00 | 25,224 | 91.98 | 49.71 | 20 | 3.11 |
| green | 2,026 | 5 | 2026-05-01 00:00:00 | 26,193 | 91.6 | 50.86 | 20 | 3.19 |
| green | 2,026 | 6 | 2026-06-01 00:00:00 | 24,975 | 91.51 | 49.53 | 20 | 3.18 |
| green | 2,026 | 7 | 2026-07-01 00:00:00 | 23,113 | 90.92 | 49.21 | 20 | 3.11 |
| green | 2,026 | 8 | 2026-08-01 00:00:00 | 22,564 | 91.14 | 49.67 | 20 | 3.17 |

---

## I8 - Peso de los aeropuertos en viajes y facturacion

**Pregunta:** Q9 Que proporcion de los viajes y de la facturacion corresponde a viajes desde o hacia los aeropuertos (JFK, LaGuardia, Newark)?  
**Indicador:** por tipo, anio y aeropuerto: viajes, % de los viajes, % de la facturacion y total mediano.  
**Justificacion:** los viajes de aeropuerto son pocos pero largos y caros (tarifa fija a JFK, Ejercicio 4 P8); medir su peso en facturacion y no solo en viajes muestra su importancia economica. Se usa el catalogo de zonas (service_zone 'Airports' y 'EWR') en vez de airport_fee porque esa columna solo existe en amarillos. Si el origen y el destino son aeropuertos, cuenta el de origen.  
**Visualizacion:** barras por anio, apiladas por aeropuerto (% de viajes y % de facturacion).  
**Fuente:** vistas viajes_validos y zonas  
**Archivo:** `sql/ejercicio7/7_08_aeropuertos.sql`  
**Tiempo de ejecucion:** 21.353 s - **filas del resultado:** 16

```sql
-- @id: I8
-- @titulo: Peso de los aeropuertos en viajes y facturacion
-- @pregunta: Q9 Que proporcion de los viajes y de la facturacion corresponde a
--   viajes desde o hacia los aeropuertos (JFK, LaGuardia, Newark)?
-- @indicador: por tipo, anio y aeropuerto: viajes, % de los viajes, % de la
--   facturacion y total mediano.
-- @justificacion: los viajes de aeropuerto son pocos pero largos y caros
--   (tarifa fija a JFK, Ejercicio 4 P8); medir su peso en facturacion y no solo
--   en viajes muestra su importancia economica. Se usa el catalogo de zonas
--   (service_zone 'Airports' y 'EWR') en vez de airport_fee porque esa columna
--   solo existe en amarillos. Si el origen y el destino son aeropuertos, cuenta
--   el de origen.
-- @visualizacion: barras por anio, apiladas por aeropuerto (% de viajes y % de facturacion).
-- @tabla: ind_aeropuertos
-- @fuente: vistas viajes_validos y zonas
WITH v AS (
    SELECT
        v.taxi,
        v.anio_archivo                                              AS anio,
        v.total_amount,
        CASE WHEN zo.service_zone IN ('Airports', 'EWR') THEN zo.zona
             WHEN zd.service_zone IN ('Airports', 'EWR') THEN zd.zona
             ELSE 'Sin aeropuerto' END                              AS aeropuerto
    FROM viajes_validos v
    LEFT JOIN zonas zo ON zo.location_id = v.pu_location_id
    LEFT JOIN zonas zd ON zd.location_id = v.do_location_id
)
SELECT
    taxi,
    anio,
    aeropuerto,
    count(*)                                                        AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi, anio), 2) AS pct_viajes,
    round(100.0 * sum(total_amount)
          / sum(sum(total_amount)) OVER (PARTITION BY taxi, anio), 2) AS pct_facturacion,
    round(approx_quantile(total_amount, 0.5), 2)                    AS total_mediano
FROM v
GROUP BY taxi, anio, aeropuerto
ORDER BY taxi DESC, anio, aeropuerto;
```

**Resultado:**

| taxi | anio | aeropuerto | viajes | pct_viajes | pct_facturacion | total_mediano |
|---|---|---|---|---|---|---|
| yellow | 2,024 | JFK Airport | 2,206,469 | 5.62 | 16.48 | 89.92 |
| yellow | 2,024 | LaGuardia Airport | 1,678,277 | 4.27 | 10.26 | 68.77 |
| yellow | 2,024 | Newark Airport | 100,876 | 0.26 | 1.15 | 127.27 |
| yellow | 2,024 | Sin aeropuerto | 35,301,213 | 89.86 | 72.11 | 20.06 |
| yellow | 2,026 | JFK Airport | 1,304,595 | 4.64 | 12.48 | 89.08 |
| yellow | 2,026 | LaGuardia Airport | 946,250 | 3.36 | 7.82 | 69.95 |
| yellow | 2,026 | Newark Airport | 48,462 | 0.17 | 0.76 | 131.71 |
| yellow | 2,026 | Sin aeropuerto | 25,828,167 | 91.83 | 78.94 | 22.51 |
| green | 2,024 | JFK Airport | 5,709 | 0.93 | 2.67 | 72.63 |
| green | 2,024 | LaGuardia Airport | 19,779 | 3.23 | 5.15 | 32.52 |
| green | 2,024 | Newark Airport | 380 | 0.06 | 0.37 | 143.83 |
| green | 2,024 | Sin aeropuerto | 587,206 | 95.78 | 91.81 | 18.76 |
| green | 2,026 | JFK Airport | 2,241 | 0.72 | 2 | 73.36 |
| green | 2,026 | LaGuardia Airport | 8,287 | 2.65 | 4.22 | 33.77 |
| green | 2,026 | Newark Airport | 162 | 0.05 | 0.3 | 145.79 |
| green | 2,026 | Sin aeropuerto | 302,087 | 96.58 | 93.48 | 20.07 |

---

## I9 - Las 10 zonas de origen con mas viajes y su concentracion

**Pregunta:** Q10 Donde se concentra la demanda: que zonas generan mas viajes y que parte del total representan las 10 principales?  
**Indicador:** por tipo y anio, ranking de zonas de origen por viajes, % del total y % acumulado de las 10 primeras.  
**Justificacion:** la ubicacion explica las diferencias entre tipos (Ejercicio 4, P5) y sirve para ubicar oferta. El % acumulado mide que tan concentrado esta el mercado; se reporta por anio para ver si las zonas cambian.  
**Visualizacion:** barras horizontales (filtro por tipo y anio).  
**Fuente:** vistas viajes_validos y zonas  
**Archivo:** `sql/ejercicio7/7_09_zonas_origen.sql`  
**Tiempo de ejecucion:** 19.115 s - **filas del resultado:** 40

```sql
-- @id: I9
-- @titulo: Las 10 zonas de origen con mas viajes y su concentracion
-- @pregunta: Q10 Donde se concentra la demanda: que zonas generan mas viajes y
--   que parte del total representan las 10 principales?
-- @indicador: por tipo y anio, ranking de zonas de origen por viajes, % del
--   total y % acumulado de las 10 primeras.
-- @justificacion: la ubicacion explica las diferencias entre tipos (Ejercicio
--   4, P5) y sirve para ubicar oferta. El % acumulado mide que tan concentrado
--   esta el mercado; se reporta por anio para ver si las zonas cambian.
-- @visualizacion: barras horizontales (filtro por tipo y anio).
-- @tabla: ind_zonas_origen
-- @fuente: vistas viajes_validos y zonas
WITH conteo AS (
    SELECT taxi, anio_archivo AS anio, pu_location_id, count(*) AS viajes
    FROM viajes_validos
    GROUP BY ALL
),
ranking AS (
    SELECT
        *,
        row_number() OVER (PARTITION BY taxi, anio ORDER BY viajes DESC) AS posicion,
        100.0 * viajes / sum(viajes) OVER (PARTITION BY taxi, anio)      AS pct
    FROM conteo
)
SELECT
    r.taxi,
    r.anio,
    r.posicion,
    z.borough,
    coalesce(z.zona, 'Desconocida')                                 AS zona,
    r.viajes,
    round(r.pct, 2)                                                 AS pct_viajes,
    round(sum(r.pct) OVER (PARTITION BY r.taxi, r.anio ORDER BY r.posicion), 2) AS pct_acumulado
FROM ranking r
LEFT JOIN zonas z ON z.location_id = r.pu_location_id
WHERE r.posicion <= 10
ORDER BY r.taxi DESC, r.anio, r.posicion;
```

**Resultado:**

| taxi | anio | posicion | borough | zona | viajes | pct_viajes | pct_acumulado |
|---|---|---|---|---|---|---|---|
| yellow | 2,024 | 1 | Queens | JFK Airport | 1,859,144 | 4.73 | 4.73 |
| yellow | 2,024 | 2 | Manhattan | Upper East Side South | 1,850,368 | 4.71 | 9.44 |
| yellow | 2,024 | 3 | Manhattan | Midtown Center | 1,841,596 | 4.69 | 14.13 |
| yellow | 2,024 | 4 | Manhattan | Upper East Side North | 1,671,408 | 4.25 | 18.38 |
| yellow | 2,024 | 5 | Manhattan | Midtown East | 1,366,843 | 3.48 | 21.86 |
| yellow | 2,024 | 6 | Manhattan | Times Sq/Theatre District | 1,324,134 | 3.37 | 25.23 |
| yellow | 2,024 | 7 | Manhattan | Penn Station/Madison Sq West | 1,308,184 | 3.33 | 28.56 |
| yellow | 2,024 | 8 | Manhattan | Lincoln Square East | 1,266,007 | 3.22 | 31.79 |
| yellow | 2,024 | 9 | Queens | LaGuardia Airport | 1,251,408 | 3.19 | 34.97 |
| yellow | 2,024 | 10 | Manhattan | Murray Hill | 1,128,189 | 2.87 | 37.84 |
| yellow | 2,026 | 1 | Manhattan | Upper East Side South | 1,247,677 | 4.44 | 4.44 |
| yellow | 2,026 | 2 | Manhattan | Midtown Center | 1,167,569 | 4.15 | 8.59 |
| yellow | 2,026 | 3 | Queens | JFK Airport | 1,123,325 | 3.99 | 12.58 |
| yellow | 2,026 | 4 | Manhattan | Upper East Side North | 1,108,262 | 3.94 | 16.52 |
| yellow | 2,026 | 5 | Manhattan | Penn Station/Madison Sq West | 865,055 | 3.08 | 19.6 |
| yellow | 2,026 | 6 | Manhattan | Midtown East | 861,235 | 3.06 | 22.66 |
| yellow | 2,026 | 7 | Manhattan | Times Sq/Theatre District | 814,437 | 2.9 | 25.55 |
| yellow | 2,026 | 8 | Manhattan | Lincoln Square East | 807,830 | 2.87 | 28.43 |
| yellow | 2,026 | 9 | Manhattan | East Village | 754,380 | 2.68 | 31.11 |
| yellow | 2,026 | 10 | Manhattan | Murray Hill | 735,050 | 2.61 | 33.72 |
| green | 2,024 | 1 | Manhattan | East Harlem North | 146,032 | 23.82 | 23.82 |
| green | 2,024 | 2 | Manhattan | East Harlem South | 88,028 | 14.36 | 38.18 |
| green | 2,024 | 3 | Manhattan | Morningside Heights | 32,512 | 5.3 | 43.48 |
| green | 2,024 | 4 | Manhattan | Central Park | 31,907 | 5.2 | 48.69 |
| green | 2,024 | 5 | Queens | Forest Hills | 31,139 | 5.08 | 53.76 |
| green | 2,024 | 6 | Queens | Elmhurst | 29,166 | 4.76 | 58.52 |
| green | 2,024 | 7 | Manhattan | Central Harlem | 27,721 | 4.52 | 63.04 |
| green | 2,024 | 8 | Brooklyn | Fort Greene | 19,806 | 3.23 | 66.27 |
| green | 2,024 | 9 | Brooklyn | Downtown Brooklyn/MetroTech | 16,914 | 2.76 | 69.03 |
| green | 2,024 | 10 | Queens | Jamaica | 14,473 | 2.36 | 71.39 |
| green | 2,026 | 1 | Manhattan | East Harlem North | 85,757 | 27.42 | 27.42 |
| green | 2,026 | 2 | Manhattan | East Harlem South | 41,568 | 13.29 | 40.71 |
| green | 2,026 | 3 | Queens | Forest Hills | 15,613 | 4.99 | 45.7 |
| green | 2,026 | 4 | Manhattan | Central Park | 12,973 | 4.15 | 49.85 |
| green | 2,026 | 5 | Manhattan | Morningside Heights | 12,402 | 3.97 | 53.81 |
| green | 2,026 | 6 | Queens | Elmhurst | 11,113 | 3.55 | 57.37 |
| green | 2,026 | 7 | Manhattan | Central Harlem | 10,912 | 3.49 | 60.85 |
| green | 2,026 | 8 | Brooklyn | Downtown Brooklyn/MetroTech | 9,189 | 2.94 | 63.79 |
| green | 2,026 | 9 | Queens | Jamaica | 8,937 | 2.86 | 66.65 |
| green | 2,026 | 10 | Brooklyn | Fort Greene | 7,915 | 2.53 | 69.18 |

---

## I10 - Cargo por congestion de Manhattan (CBD): cobertura y recaudacion

**Pregunta:** Q11 Que parte de los viajes paga el cargo CBD y cuanto recauda por dia a traves de los taxis?  
**Indicador:** % de viajes con cargo CBD > 0, cargo promedio de quienes lo pagan y recaudacion diaria (suma del cargo / dias).  
**Justificacion:** es el cambio regulatorio mas grande del periodo (desde el 5 de enero de 2025) y explica parte del aumento del total (Ejercicio 5). En 2024 la columna no existe y queda NULL: el % se calcula sobre los viajes con la columna presente, asi 2024 aparece como NULL y no como 0.  
**Visualizacion:** barras de recaudacion diaria por mes y lineas de % con cargo.  
**Fuente:** vista viajes_validos  
**Archivo:** `sql/ejercicio7/7_10_cargo_congestion.sql`  
**Tiempo de ejecucion:** 17.304 s - **filas del resultado:** 40

```sql
-- @id: I10
-- @titulo: Cargo por congestion de Manhattan (CBD): cobertura y recaudacion
-- @pregunta: Q11 Que parte de los viajes paga el cargo CBD y cuanto recauda
--   por dia a traves de los taxis?
-- @indicador: % de viajes con cargo CBD > 0, cargo promedio de quienes lo
--   pagan y recaudacion diaria (suma del cargo / dias).
-- @justificacion: es el cambio regulatorio mas grande del periodo (desde el 5
--   de enero de 2025) y explica parte del aumento del total (Ejercicio 5). En
--   2024 la columna no existe y queda NULL: el % se calcula sobre los viajes
--   con la columna presente, asi 2024 aparece como NULL y no como 0.
-- @visualizacion: barras de recaudacion diaria por mes y lineas de % con cargo.
-- @tabla: ind_cbd
-- @fuente: vista viajes_validos
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    mes_archivo                                                     AS mes,
    make_date(anio_archivo, mes_archivo, 1)                         AS periodo,
    count(*)                                                        AS viajes,
    round(100.0 * count_if(cbd_congestion_fee > 0)
          / nullif(count(cbd_congestion_fee), 0), 2)                AS pct_con_cargo,
    round(avg(CASE WHEN cbd_congestion_fee > 0 THEN cbd_congestion_fee END), 2) AS cargo_promedio,
    round(sum(cbd_congestion_fee) / count(DISTINCT fecha), 0)       AS recaudacion_por_dia
FROM viajes_validos
GROUP BY ALL
ORDER BY taxi DESC, anio, mes;
```

**Resultado:**

| taxi | anio | mes | periodo | viajes | pct_con_cargo | cargo_promedio | recaudacion_por_dia |
|---|---|---|---|---|---|---|---|
| yellow | 2,024 | 1 | 2024-01-01 00:00:00 | 2,836,223 | NULL | NULL | NULL |
| yellow | 2,024 | 2 | 2024-02-01 00:00:00 | 2,865,951 | NULL | NULL | NULL |
| yellow | 2,024 | 3 | 2024-03-01 00:00:00 | 3,398,154 | NULL | NULL | NULL |
| yellow | 2,024 | 4 | 2024-04-01 00:00:00 | 3,373,190 | NULL | NULL | NULL |
| yellow | 2,024 | 5 | 2024-05-01 00:00:00 | 3,575,459 | NULL | NULL | NULL |
| yellow | 2,024 | 6 | 2024-06-01 00:00:00 | 3,391,071 | NULL | NULL | NULL |
| yellow | 2,024 | 7 | 2024-07-01 00:00:00 | 2,943,435 | NULL | NULL | NULL |
| yellow | 2,024 | 8 | 2024-08-01 00:00:00 | 2,839,716 | NULL | NULL | NULL |
| yellow | 2,024 | 9 | 2024-09-01 00:00:00 | 3,452,355 | NULL | NULL | NULL |
| yellow | 2,024 | 10 | 2024-10-01 00:00:00 | 3,644,845 | NULL | NULL | NULL |
| yellow | 2,024 | 11 | 2024-11-01 00:00:00 | 3,479,841 | NULL | NULL | NULL |
| yellow | 2,024 | 12 | 2024-12-01 00:00:00 | 3,486,595 | NULL | NULL | NULL |
| yellow | 2,026 | 1 | 2026-01-01 00:00:00 | 3,500,703 | 70.91 | 0.75 | 60,058 |
| yellow | 2,026 | 2 | 2026-02-01 00:00:00 | 3,196,364 | 70.96 | 0.75 | 60,754 |
| yellow | 2,026 | 3 | 2026-03-01 00:00:00 | 3,748,151 | 71.56 | 0.75 | 64,887 |
| yellow | 2,026 | 4 | 2026-04-01 00:00:00 | 3,660,483 | 71.77 | 0.75 | 65,675 |
| yellow | 2,026 | 5 | 2026-05-01 00:00:00 | 3,897,714 | 66.74 | 0.75 | 62,938 |
| yellow | 2,026 | 6 | 2026-06-01 00:00:00 | 3,633,908 | 74.26 | 0.75 | 67,465 |
| yellow | 2,026 | 7 | 2026-07-01 00:00:00 | 3,335,678 | 77.21 | 0.75 | 62,312 |
| yellow | 2,026 | 8 | 2026-08-01 00:00:00 | 3,154,473 | 77.14 | 0.75 | 58,874 |
| green | 2,024 | 1 | 2024-01-01 00:00:00 | 52,662 | NULL | NULL | NULL |
| green | 2,024 | 2 | 2024-02-01 00:00:00 | 49,771 | NULL | NULL | NULL |
| green | 2,024 | 3 | 2024-03-01 00:00:00 | 53,427 | NULL | NULL | NULL |
| green | 2,024 | 4 | 2024-04-01 00:00:00 | 52,404 | NULL | NULL | NULL |
| green | 2,024 | 5 | 2024-05-01 00:00:00 | 56,814 | NULL | NULL | NULL |
| green | 2,024 | 6 | 2024-06-01 00:00:00 | 51,048 | NULL | NULL | NULL |
| green | 2,024 | 7 | 2024-07-01 00:00:00 | 47,897 | NULL | NULL | NULL |
| green | 2,024 | 8 | 2024-08-01 00:00:00 | 47,971 | NULL | NULL | NULL |
| green | 2,024 | 9 | 2024-09-01 00:00:00 | 50,545 | NULL | NULL | NULL |
| green | 2,024 | 10 | 2024-10-01 00:00:00 | 52,447 | NULL | NULL | NULL |
| green | 2,024 | 11 | 2024-11-01 00:00:00 | 48,306 | NULL | NULL | NULL |
| green | 2,024 | 12 | 2024-12-01 00:00:00 | 49,782 | NULL | NULL | NULL |
| green | 2,026 | 1 | 2026-01-01 00:00:00 | 37,567 | 7.78 | 0.75 | 71 |
| green | 2,026 | 2 | 2026-02-01 00:00:00 | 34,593 | 7.08 | 0.75 | 66 |
| green | 2,026 | 3 | 2026-03-01 00:00:00 | 41,154 | 8.06 | 0.75 | 80 |
| green | 2,026 | 4 | 2026-04-01 00:00:00 | 41,085 | 8.45 | 0.75 | 87 |
| green | 2,026 | 5 | 2026-05-01 00:00:00 | 41,794 | 8.99 | 0.75 | 91 |
| green | 2,026 | 6 | 2026-06-01 00:00:00 | 41,011 | 8.54 | 0.75 | 88 |
| green | 2,026 | 7 | 2026-07-01 00:00:00 | 38,019 | 9.27 | 0.75 | 85 |
| green | 2,026 | 8 | 2026-08-01 00:00:00 | 37,554 | 9.82 | 0.75 | 89 |

---

## I11 - Porcentaje de registros validos por mes y regla que mas excluye

**Pregunta:** Q12 Que tan confiables son los datos de cada mes y que problema de calidad pesa mas?  
**Indicador:** % de registros que pasan todas las reglas de calidad y % marcado por cada regla, por tipo y mes.  
**Justificacion:** todos los demas indicadores usan viajes_validos; si la proporcion excluida cambia mucho entre meses o anios, una variacion en otro indicador podria deberse a la captura y no al comportamiento real.  
**Visualizacion:** lineas por mes, una serie por tipo.  
**Fuente:** vista viajes_enriquecidos (todos los registros)  
**Archivo:** `sql/ejercicio7/7_11_calidad.sql`  
**Tiempo de ejecucion:** 14.680 s - **filas del resultado:** 40

```sql
-- @id: I11
-- @titulo: Porcentaje de registros validos por mes y regla que mas excluye
-- @pregunta: Q12 Que tan confiables son los datos de cada mes y que problema
--   de calidad pesa mas?
-- @indicador: % de registros que pasan todas las reglas de calidad y % marcado
--   por cada regla, por tipo y mes.
-- @justificacion: todos los demas indicadores usan viajes_validos; si la
--   proporcion excluida cambia mucho entre meses o anios, una variacion en
--   otro indicador podria deberse a la captura y no al comportamiento real.
-- @visualizacion: lineas por mes, una serie por tipo.
-- @tabla: ind_calidad
-- @fuente: vista viajes_enriquecidos (todos los registros)
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    mes_archivo                                                     AS mes,
    make_date(anio_archivo, mes_archivo, 1)                         AS periodo,
    count(*)                                                        AS registros,
    count_if(NOT (f_fuera_periodo OR f_duracion OR f_distancia
                  OR f_velocidad OR f_monto OR f_pasajeros))        AS validos,
    round(100.0 * count_if(NOT (f_fuera_periodo OR f_duracion OR f_distancia
                  OR f_velocidad OR f_monto OR f_pasajeros)) / count(*), 2) AS pct_validos,
    round(100.0 * count_if(f_distancia) / count(*), 2)              AS pct_distancia,
    round(100.0 * count_if(f_duracion) / count(*), 2)               AS pct_duracion,
    round(100.0 * count_if(f_monto) / count(*), 2)                  AS pct_monto,
    round(100.0 * count_if(f_pasajeros) / count(*), 2)              AS pct_pasajeros,
    round(100.0 * count_if(f_velocidad) / count(*), 2)              AS pct_velocidad,
    round(100.0 * count_if(f_fuera_periodo) / count(*), 3)          AS pct_fuera_periodo
FROM viajes_enriquecidos
GROUP BY ALL
ORDER BY taxi DESC, anio, mes;
```

**Resultado:**

| taxi | anio | mes | periodo | registros | validos | pct_validos | pct_distancia | pct_duracion | pct_monto | pct_pasajeros | pct_velocidad | pct_fuera_periodo |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 2,024 | 1 | 2024-01-01 00:00:00 | 2,964,624 | 2,836,223 | 95.67 | 2.04 | 0.09 | 1.29 | 1.06 | 0.04 | 0.001 |
| yellow | 2,024 | 2 | 2024-02-01 00:00:00 | 3,007,526 | 2,865,951 | 95.29 | 2.27 | 0.08 | 1.38 | 1.13 | 0.03 | 0 |
| yellow | 2,024 | 3 | 2024-03-01 00:00:00 | 3,582,628 | 3,398,154 | 94.85 | 2.44 | 0.09 | 1.67 | 1.13 | 0.03 | 0.001 |
| yellow | 2,024 | 4 | 2024-04-01 00:00:00 | 3,514,289 | 3,373,190 | 95.98 | 1.31 | 0.09 | 1.68 | 1.13 | 0.03 | 0 |
| yellow | 2,024 | 5 | 2024-05-01 00:00:00 | 3,723,833 | 3,575,459 | 96.02 | 1.34 | 0.08 | 1.68 | 1.07 | 0.03 | 0.001 |
| yellow | 2,024 | 6 | 2024-06-01 00:00:00 | 3,539,193 | 3,391,071 | 95.81 | 1.5 | 0.09 | 1.78 | 1.01 | 0.03 | 0.001 |
| yellow | 2,024 | 7 | 2024-07-01 00:00:00 | 3,076,903 | 2,943,435 | 95.66 | 1.57 | 0.09 | 1.94 | 0.95 | 0.04 | 0.002 |
| yellow | 2,024 | 8 | 2024-08-01 00:00:00 | 2,979,183 | 2,839,716 | 95.32 | 1.93 | 0.09 | 1.99 | 0.88 | 0.04 | 0.002 |
| yellow | 2,024 | 9 | 2024-09-01 00:00:00 | 3,633,030 | 3,452,355 | 95.03 | 2.24 | 0.08 | 2.06 | 0.84 | 0.03 | 0.001 |
| yellow | 2,024 | 10 | 2024-10-01 00:00:00 | 3,833,771 | 3,644,845 | 95.07 | 2.13 | 0.07 | 2.01 | 0.93 | 0.03 | 0.001 |
| yellow | 2,024 | 11 | 2024-11-01 00:00:00 | 3,646,369 | 3,479,841 | 95.43 | 1.88 | 0.1 | 2 | 0.78 | 0.03 | 0.001 |
| yellow | 2,024 | 12 | 2024-12-01 00:00:00 | 3,668,371 | 3,486,595 | 95.04 | 2.06 | 0.09 | 2.2 | 0.83 | 0.03 | 0.001 |
| yellow | 2,026 | 1 | 2026-01-01 00:00:00 | 3,724,889 | 3,500,703 | 93.98 | 3.38 | 1.25 | 1.12 | 0.4 | 0.02 | 0 |
| yellow | 2,026 | 2 | 2026-02-01 00:00:00 | 3,399,866 | 3,196,364 | 94.01 | 3.63 | 1.23 | 0.86 | 0.38 | 0.02 | 0 |
| yellow | 2,026 | 3 | 2026-03-01 00:00:00 | 3,952,451 | 3,748,151 | 94.83 | 3.07 | 1.26 | 0.6 | 0.33 | 0.03 | 0 |
| yellow | 2,026 | 4 | 2026-04-01 00:00:00 | 3,831,240 | 3,660,483 | 95.54 | 2.44 | 1.31 | 0.45 | 0.31 | 0.03 | 0 |
| yellow | 2,026 | 5 | 2026-05-01 00:00:00 | 4,090,836 | 3,897,714 | 95.28 | 2.77 | 1.3 | 0.42 | 0.31 | 0.02 | 0 |
| yellow | 2,026 | 6 | 2026-06-01 00:00:00 | 3,837,248 | 3,633,908 | 94.7 | 3.34 | 1.32 | 0.44 | 0.27 | 0.03 | 0 |
| yellow | 2,026 | 7 | 2026-07-01 00:00:00 | 3,530,109 | 3,335,678 | 94.49 | 3.64 | 1.22 | 0.48 | 0.24 | 0.03 | 0.001 |
| yellow | 2,026 | 8 | 2026-08-01 00:00:00 | 3,336,716 | 3,154,473 | 94.54 | 3.57 | 1.31 | 0.52 | 0.22 | 0.03 | 0 |
| green | 2,024 | 1 | 2024-01-01 00:00:00 | 56,551 | 52,662 | 93.12 | 5.16 | 0.48 | 0.41 | 0.91 | 0.38 | 0.004 |
| green | 2,024 | 2 | 2024-02-01 00:00:00 | 53,577 | 49,771 | 92.9 | 5.36 | 0.46 | 0.37 | 1 | 0.29 | 0.011 |
| green | 2,024 | 3 | 2024-03-01 00:00:00 | 57,457 | 53,427 | 92.99 | 5.29 | 0.38 | 0.39 | 0.97 | 0.3 | 0.017 |
| green | 2,024 | 4 | 2024-04-01 00:00:00 | 56,471 | 52,404 | 92.8 | 5.68 | 0.46 | 0.46 | 0.77 | 0.28 | 0.007 |
| green | 2,024 | 5 | 2024-05-01 00:00:00 | 61,003 | 56,814 | 93.13 | 5.12 | 0.49 | 0.45 | 0.89 | 0.29 | 0.015 |
| green | 2,024 | 6 | 2024-06-01 00:00:00 | 54,748 | 51,048 | 93.24 | 5.01 | 0.46 | 0.39 | 0.98 | 0.33 | 0.024 |
| green | 2,024 | 7 | 2024-07-01 00:00:00 | 51,837 | 47,897 | 92.4 | 5.78 | 0.49 | 0.41 | 0.99 | 0.3 | 0.05 |
| green | 2,024 | 8 | 2024-08-01 00:00:00 | 51,771 | 47,971 | 92.66 | 5.22 | 0.55 | 0.46 | 1.05 | 0.45 | 0.039 |
| green | 2,024 | 9 | 2024-09-01 00:00:00 | 54,440 | 50,545 | 92.85 | 5.14 | 0.52 | 0.45 | 1.07 | 0.36 | 0.062 |
| green | 2,024 | 10 | 2024-10-01 00:00:00 | 56,147 | 52,447 | 93.41 | 4.65 | 0.52 | 0.35 | 1.1 | 0.32 | 0.012 |
| green | 2,024 | 11 | 2024-11-01 00:00:00 | 52,222 | 48,306 | 92.5 | 5.32 | 0.6 | 0.31 | 1.28 | 0.31 | 0.029 |
| green | 2,024 | 12 | 2024-12-01 00:00:00 | 53,994 | 49,782 | 92.2 | 5.59 | 0.59 | 0.39 | 1.38 | 0.3 | 0.033 |
| green | 2,026 | 1 | 2026-01-01 00:00:00 | 40,272 | 37,567 | 93.28 | 3.22 | 0.35 | 1.69 | 1.4 | 0.36 | 0.055 |
| green | 2,026 | 2 | 2026-02-01 00:00:00 | 37,373 | 34,593 | 92.56 | 3.75 | 0.37 | 1.77 | 1.52 | 0.4 | 0.029 |
| green | 2,026 | 3 | 2026-03-01 00:00:00 | 44,208 | 41,154 | 93.09 | 3.26 | 0.47 | 1.87 | 1.32 | 0.33 | 0.02 |
| green | 2,026 | 4 | 2026-04-01 00:00:00 | 44,238 | 41,085 | 92.87 | 3.65 | 0.48 | 1.86 | 1.23 | 0.35 | 0.007 |
| green | 2,026 | 5 | 2026-05-01 00:00:00 | 44,921 | 41,794 | 93.04 | 3.5 | 0.46 | 1.71 | 1.34 | 0.34 | 0.022 |
| green | 2,026 | 6 | 2026-06-01 00:00:00 | 44,163 | 41,011 | 92.86 | 3.4 | 0.39 | 2.01 | 1.27 | 0.36 | 0.029 |
| green | 2,026 | 7 | 2026-07-01 00:00:00 | 41,252 | 38,019 | 92.16 | 4.02 | 0.34 | 2.03 | 1.42 | 0.33 | 0.039 |
| green | 2,026 | 8 | 2026-08-01 00:00:00 | 40,687 | 37,554 | 92.3 | 4.43 | 0.29 | 1.75 | 1.29 | 0.29 | 0.034 |

---

## I12 - Resumen por anio en los meses comunes a todos los anios

**Pregunta:** Q13 Como se comparan los anios entre si en volumen, precio, caracteristicas del viaje y forma de pago, sin que la estacionalidad sesgue la comparacion?  
**Indicador:** por tipo y anio, en los meses presentes en todos los anios descargados: viajes por dia, total mediano, distancia, duracion y velocidad medianas, % tarjeta, % Flex Fare / sin dato y % con cargo CBD.  
**Justificacion:** los anios no tienen los mismos meses (2026 solo llega hasta el ultimo mes publicado) y la demanda es estacional; un promedio anual directo compararia periodos distintos. Los meses comunes se calculan a partir de los datos, asi la consulta se ajusta sola al agregar anios o meses.  
**Visualizacion:** tabla y tarjetas KPI del tablero.  
**Fuente:** vista viajes_validos  
**Archivo:** `sql/ejercicio7/7_12_resumen_anual.sql`  
**Tiempo de ejecucion:** 49.563 s - **filas del resultado:** 4

```sql
-- @id: I12
-- @titulo: Resumen por anio en los meses comunes a todos los anios
-- @pregunta: Q13 Como se comparan los anios entre si en volumen, precio,
--   caracteristicas del viaje y forma de pago, sin que la estacionalidad
--   sesgue la comparacion?
-- @indicador: por tipo y anio, en los meses presentes en todos los anios
--   descargados: viajes por dia, total mediano, distancia, duracion y
--   velocidad medianas, % tarjeta, % Flex Fare / sin dato y % con cargo CBD.
-- @justificacion: los anios no tienen los mismos meses (2026 solo llega hasta
--   el ultimo mes publicado) y la demanda es estacional; un promedio anual
--   directo compararia periodos distintos. Los meses comunes se calculan a
--   partir de los datos, asi la consulta se ajusta sola al agregar anios o meses.
-- @visualizacion: tabla y tarjetas KPI del tablero.
-- @tabla: ind_resumen_anual
-- @fuente: vista viajes_validos
WITH meses_comunes AS (
    SELECT mes_archivo
    FROM viajes_validos
    GROUP BY mes_archivo
    HAVING count(DISTINCT anio_archivo)
         = (SELECT count(DISTINCT anio_archivo) FROM viajes_validos)
)
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    min(mes_archivo) || '-' || max(mes_archivo)                     AS meses,
    count(*)                                                        AS viajes,
    round(count(*) / count(DISTINCT fecha), 0)                      AS viajes_por_dia,
    round(approx_quantile(total_amount, 0.5), 2)                    AS total_mediano,
    round(approx_quantile(trip_distance, 0.5), 2)                   AS distancia_mediana,
    round(approx_quantile(duracion_min, 0.5), 1)                    AS duracion_mediana,
    round(approx_quantile(velocidad_mph, 0.5), 2)                   AS mph_mediana,
    round(100.0 * count_if(metodo_pago = 'Tarjeta') / count(*), 1)  AS pct_tarjeta,
    round(100.0 * count_if(metodo_pago IN ('Flex fare', 'Sin dato')) / count(*), 1) AS pct_flex_sin_dato,
    round(100.0 * count_if(cbd_congestion_fee > 0)
          / nullif(count(cbd_congestion_fee), 0), 1)                AS pct_con_cargo_cbd
FROM viajes_validos
WHERE mes_archivo IN (SELECT mes_archivo FROM meses_comunes)
GROUP BY taxi, anio_archivo
ORDER BY taxi DESC, anio;
```

**Resultado:**

| taxi | anio | meses | viajes | viajes_por_dia | total_mediano | distancia_mediana | duracion_mediana | mph_mediana | pct_tarjeta | pct_flex_sin_dato | pct_con_cargo_cbd |
|---|---|---|---|---|---|---|---|---|---|---|---|
| yellow | 2,024 | 1-8 | 25,223,199 | 103,374 | 20.96 | 1.8 | 12.7 | 9.52 | 75.9 | 9.1 | NULL |
| yellow | 2,026 | 1-8 | 28,127,474 | 115,751 | 23.62 | 1.93 | 14.1 | 9.27 | 65.3 | 25 | 72.4 |
| green | 2,024 | 1-8 | 411,994 | 1,689 | 19.09 | 1.96 | 11.9 | 10.39 | 67.7 | 4.1 | NULL |
| green | 2,026 | 1-8 | 312,777 | 1,287 | 20.5 | 2.13 | 13.2 | 10.05 | 66.4 | 13.6 | 8.5 |
