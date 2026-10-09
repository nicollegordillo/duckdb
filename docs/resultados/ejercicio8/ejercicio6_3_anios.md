# Resultados de sql/ejercicio6

Generado automaticamente el 2026-10-08T22:43:21 con `python scripts/run_sql.py ejercicio6 --salida ejercicio8/ejercicio6_3_anios`.
No editar a mano: volver a ejecutar el script tras cambiar las consultas.

DuckDB 1.5.5

## B1 - Conteo de registros por tipo de taxi

**Objetivo:** Consulta minima del benchmark (equivale a 3.2b, pero sobre `viajes`): solo cuenta filas. Sobre Parquet, `taxi` es una constante de cada rama de la vista y no se lee ninguna columna; sobre la tabla, `taxi` es una columna almacenada que hay que recorrer. Mide el costo fijo de abrir y recorrer el origen de datos.  
**Fuente:** relacion viajes (vista sobre Parquet o tabla materializada)  
**Archivo:** `sql/ejercicio6/6_01_conteo_por_tipo.sql`  
**Tiempo de ejecucion:** 3.148 s - **filas del resultado:** 2

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

**Resultado:**

| taxi | registros |
|---|---|
| yellow | 119,595,677 |
| green | 1,588,707 |

---

## B7 - Consulta selectiva: viajes desde JFK en un dia, por hora

**Objetivo:** Representa una consulta puntual de exploracion (detalle de un dia y una zona, como las revisiones de fechas del Ejercicio 3). Menos del 0.01 % de las filas cumple el filtro, asi que mide cuanto aprovecha cada estrategia las estadisticas min/max (row groups del Parquet, zone maps de la tabla) para saltarse datos que no necesita leer. El 15 de enero de 2026 esta en todos los escenarios del benchmark. 132 = JFK Airport.  
**Fuente:** vista viajes_validos (sobre Parquet o sobre la tabla materializada)  
**Archivo:** `sql/ejercicio6/6_02_filtro_selectivo.sql`  
**Tiempo de ejecucion:** 0.680 s - **filas del resultado:** 24

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

**Resultado:**

| hora | taxi | viajes | total_prom_usd |
|---|---|---|---|
| 0 | yellow | 141 | 78.5 |
| 1 | yellow | 65 | 70.7 |
| 2 | yellow | 26 | 51.99 |
| 3 | yellow | 40 | 69.44 |
| 4 | yellow | 10 | 56.14 |
| 5 | yellow | 107 | 65.55 |
| 6 | yellow | 132 | 79.84 |
| 7 | yellow | 163 | 88.77 |
| 8 | yellow | 86 | 80.79 |
| 9 | yellow | 121 | 76.28 |
| 10 | yellow | 108 | 78.47 |
| 11 | yellow | 125 | 76.47 |
| 12 | yellow | 119 | 81.51 |
| 13 | yellow | 138 | 90.86 |
| 14 | yellow | 184 | 86.23 |
| 15 | yellow | 307 | 86.08 |
| 16 | yellow | 369 | 97.72 |
| 17 | yellow | 272 | 90.97 |
| 18 | yellow | 254 | 84.53 |
| 19 | yellow | 302 | 81.18 |
| 20 | yellow | 340 | 83.45 |
| 21 | yellow | 335 | 73.51 |
| 22 | yellow | 326 | 77.27 |
| 23 | yellow | 278 | 80.07 |
