# Ejercicio 8 - Incorporación de los datos de 2025 y análisis completo

- **Cambio al sistema de descarga (8.1):** `scripts/download_data.py`, una línea.
- **Verificación (8.2):** [`docs/resultados/verificacion_descarga.md`](resultados/verificacion_descarga.md).
- **Compatibilidad de las consultas (8.3):** [`docs/resultados/ejercicio5_compatibilidad.md`](resultados/ejercicio5_compatibilidad.md) (Ejercicios 3 y 4, nueva etapa `2024_2025_2026`), además de [`ejercicio8/ejercicio5_3_anios.md`](resultados/ejercicio8/ejercicio5_3_anios.md) y [`ejercicio8/ejercicio6_3_anios.md`](resultados/ejercicio8/ejercicio6_3_anios.md).
- **Indicadores con los tres años (8.4):** [`docs/resultados/ejercicio8/indicadores_3_anios.md`](resultados/ejercicio8/indicadores_3_anios.md), con las mismas 12 consultas de `sql/ejercicio7/` sin cambios.
- **Consultas de evolución (8.5–8.7):** `sql/ejercicio8/`. SQL, resultado y tiempo en [`docs/resultados/ejercicio8.md`](resultados/ejercicio8.md).
- **Notebook con las gráficas:** `notebooks/ejercicio8_evolucion.ipynb` (lee los CSV anteriores y guarda `docs/figuras/e8_*.png`).

Datos finales: amarillos y verdes de **2024** (12 meses), **2025** (12 meses) y **2026** (enero–agosto, el último mes publicado por la TLC). Son **64 archivos Parquet** (2.0 GB) y **121.2 millones de registros**.

## 8.1 Modificación del sistema de descarga

Como en el Ejercicio 5, bastó con agregar el año a la configuración:

```python
# scripts/download_data.py
ANIOS_POR_DEFECTO = (2024, 2025, 2026)      # antes: (2024, 2026)
```

No hizo falta cambiar nada más: desde el Ejercicio 2 el año es un parámetro de `construir_url`, `ruta_destino` y `descargar`. `verify_data.py` importa la misma constante, así que también verifica 2025. El mismo resultado se obtiene sin editar el código con `python scripts/download_data.py --anio 2024 2025 2026`.

## 8.2 Los archivos ya descargados no se descargan de nuevo

Ejecución con los tres años:

```text
  anios         : 2024, 2025, 2026
  descargados   : 24        <- 12 amarillos + 12 verdes de 2025 (844 MB)
  ya existian   : 40        <- 2024 y 2026: "ya existe, se omite"
  no publicados : 8         <- 2026-09 (aún no publicado) y 2026-10 a 12
  fallidos      : 0
```

Una segunda ejecución inmediata da `descargados: 0`, `ya existian: 64`.

**Evidencia.** Antes de descargar se guardó una copia de `data/raw/manifest.csv`. Después se comparó, archivo por archivo, URL, bytes, SHA-256 y fecha de descarga:

| tipo | año | archivos antes | archivos después | idénticos (URL, bytes, SHA-256, fecha) |
|---|---|---|---|---|
| yellow | 2024 | 12 | 12 | 12 |
| yellow | 2025 | 0 | 12 | - (nuevos) |
| yellow | 2026 | 8 | 8 | 8 |
| green | 2024 | 12 | 12 | 12 |
| green | 2025 | 0 | 12 | - (nuevos) |
| green | 2026 | 8 | 8 | 8 |
| zonas | - | 1 | 1 | 1 |

La fecha de modificación en disco de los archivos de 2024 y 2026 tampoco cambió. El script lo garantiza con lo construido en el Ejercicio 2:
- un Parquet que existe y es válido (firma `PAR1`) se omite;
- cada año tiene su carpeta (`data/raw/<tipo>/<anio>/`);
- la descarga se escribe en un `.part` y solo se renombra si el tamaño coincide con el publicado.

**Verificación de la descarga:** `verify_data.py` termina con código 0 (**completo**). Los 64 archivos publicados están descargados, su tamaño coincide con el publicado y DuckDB puede leerlos.

| tipo | año | archivos | registros |
|---|---|---|---|
| yellow | 2024 | 12 | 41,169,720 |
| yellow | 2025 | 12 | 48,722,602 |
| yellow | 2026 | 8 | 29,703,355 |
| green | 2024 | 12 | 660,218 |
| green | 2025 | 12 | 591,375 |
| green | 2026 | 8 | 337,114 |
| **total** | | **64** | **121,184,384** |

La consulta 5.2, ejecutada sobre los tres años, confirma que la vista unificada no pierde ni duplica filas. Para los 6 pares tipo-año, la suma de `num_rows` de los footers es igual a `count(*)` sobre `viajes`: diferencia **0**.

## 8.3 ¿Siguen funcionando las consultas?

**Ninguna consulta se modificó.** Se ejecutaron todas sobre los tres años:

| Consultas | Cómo se ejecutaron | Resultado |
|---|---|---|
| Ejercicios 3 y 4 (29) | `compatibilidad.py --etapa 2024_2025_2026 --guardar-csv` | 28 terminan; 3.6g se quedó sin memoria (ver abajo) |
| Ejercicio 5 (9) | `run_sql.py ejercicio5 --salida ejercicio8/ejercicio5_3_anios` | 9 / 9 |
| Ejercicio 6 (2) | `run_sql.py ejercicio6 --salida ejercicio8/ejercicio6_3_anios` | 2 / 2 |
| Ejercicio 7, indicadores (12) | `run_sql.py ejercicio7 --salida ejercicio8/indicadores_3_anios --tablero` | 12 / 12 |

- **Resultados que cambian y resultados que no.** El esquema (3.4, 3.5, 3.6a) da un resultado **idéntico** al documentado: 2025 no agrega columnas nuevas. Los demás dan resultados distintos, como se esperaba, porque ahora incluyen 2025. Las consultas por mes o por año simplemente tienen más filas (por ejemplo, P1 pasa de 40 a 64 meses-tipo).
- **3.6g (duplicados) se quedó sin memoria** (`Out of Memory Error: Allocation failure`) con 4 hilos y un límite de 2 GB. Agrupa por 7 columnas, lo que da ~120 millones de grupos, casi uno por fila. Con 2 hilos y 1.5 GB terminó en 184 s: hay **32,812 registros amarillos duplicados** en 119.6 M y ninguno verde. No es un error de la consulta sino un límite de la máquina usada (5.9 GB de RAM), porque cada hilo mantiene su propia tabla *hash*. Es la misma consulta que el Ejercicio 5 había señalado como la que más crece con el volumen.
- **Tiempo.** Las 29 consultas tardaron 20 min (540 s con 2024+2026 en el Ejercicio 5). Las más pesadas son 3.5 (SUMMARIZE, 342 s) y 3.6e (219 s). Los 12 indicadores pasaron de 4.0 min (72 M registros) a 5.8 min (121 M).

## 8.4 Indicadores y visualizaciones con los tres años

Los indicadores del Ejercicio 7 ya agrupaban por año, así que actualizarlos no requirió cambiar el SQL, solo volver a ejecutarlos:

```bash
docker compose stop metabase
docker compose exec lab python scripts/run_sql.py ejercicio7 --salida ejercicio8/indicadores_3_anios --tablero
docker compose exec lab python scripts/run_sql.py ejercicio8 --tablero
docker compose start metabase
docker compose exec lab python scripts/tablero_metabase.py --url http://metabase:3000
docker compose exec lab jupyter nbconvert --to notebook --execute --inplace notebooks/ejercicio8_evolucion.ipynb
```

- `--tablero` reemplaza las tablas `ind_*` de `data/processed/tablero.duckdb` con los tres años. Las tarjetas de Metabase leen esas tablas, así que todas las series muestran 2024, 2025 y 2026, con 2025 en su propio color (verde agua).
- `run_sql.py ejercicio8 --tablero` agrega `ind_cbd_control` e `ind_crecimiento`. Con ellas, `tablero_metabase.py` agrega la sección **"Evolución 2024–2026"** con tres tarjetas (8.1 y 8.2). Si esas tablas no existen, el script omite la sección, así que el mismo script sirve para el estado del Ejercicio 7.
- `--salida` deja estos resultados en `docs/resultados/ejercicio8/` y no sobrescribe los del Ejercicio 7, que se reproducen con `--anio 2024 2026`.

## 8.5 Evolución de los indicadores

**Resumen por año en los meses comunes (enero–agosto)**, indicador I12:

| | Amarillos 2024 | 2025 | 2026 | Verdes 2024 | 2025 | 2026 |
|---|---|---|---|---|---|---|
| Viajes válidos por día | 103,374 | 117,320 (+13.5 %) | 115,751 (−1.3 %) | 1,689 | 1,509 (−10.7 %) | 1,287 (−14.7 %) |
| Total mediano (USD) | 20.97 | 21.64 (+3.2 %) | 23.61 (+9.1 %) | 19.10 | 19.82 | 20.50 |
| Distancia mediana (mi) | 1.80 | 1.87 | 1.93 | 1.96 | 2.02 | 2.13 |
| Duración mediana (min) | 12.7 | 13.0 | 14.1 | 11.9 | 12.4 | 13.2 |
| Velocidad mediana (mph) | 9.52 | 9.66 | 9.28 | 10.39 | 10.30 | 10.04 |
| % tarjeta | 75.9 | 68.6 | 65.3 | 67.7 | 69.8 | 66.4 |
| % Flex Fare / sin dato | 9.1 | 19.7 | 25.0 | 4.1 | 6.5 | 13.6 |
| % con cargo CBD | - | 73.0 | 72.4 | - | 9.9 | 8.5 |

Otros indicadores a lo largo de los tres años:
- **Participación de los verdes (I1):** 1.82 % en enero de 2024, 1.36 % en enero de 2025 y 1.06 % en enero de 2026. Bajan en cada mes comparado con el mismo mes del año anterior.
- **Aeropuertos, amarillos (I8):** pasan de 10.2 % → 8.9 % → 8.2 % de los viajes y de 27.9 % → 24.3 % → 21.1 % de la facturación. La caída es continua.
- **Concentración (I9):** las 10 zonas principales concentran 37.8 % → 35.1 % → 33.7 % de los viajes amarillos. En verdes, East Harlem North y South suman 38.2 % → 40.3 % → 40.7 %.
- **Cargo CBD (I10):** desde el primer mes de cobro, entre 66 % y 77 % de los viajes amarillos lo pagan. La recaudación va de 51 mil USD por día en enero de 2025 a ~60–72 mil USD por día en los meses siguientes. En verdes, entre 7 % y 11 % de los viajes paga el cargo.
- **Propina (I7):** prácticamente constante. El 54.2 % → 53.5 % → 53.0 % de los pagos con tarjeta en amarillos deja exactamente 20 %, y la mediana es 20 % en los 64 meses-tipo.
- **Calidad (I11):** estable en 2024 y 2026 (92–96 % válidos), pero en 2025 los amarillos bajan a 86.6–93.6 % (patrón 3).

## 8.6 Cambios y patrones visibles al considerar 2024, 2025 y 2026

### Patrón 1 - El crecimiento de los amarillos ocurrió en 2025 y se detuvo en 2026; todo es Flex Fare

Con solo 2024 y 2026 (Ejercicio 7) se veía "+12 %". Con 2025 en medio, la historia es otra: **+13.5 % en 2025 y −1.3 % en 2026**. Con los registros sin filtrar el resultado es el mismo: 108,148 → 129,862 → 122,236 registros por día (2026 queda 5.9 % por debajo de 2025).

La consulta 8.2 separa los viajes por día según la forma de pago:

| Amarillos, viajes por día (ene–ago) | 2024 | 2025 | 2026 |
|---|---|---|---|
| Flex Fare / sin dato | 9,390 | 23,146 (×2.5) | 28,944 (+25 %) |
| Tarjeta, efectivo y otros | 93,983 | 94,174 (+0.2 %) | 86,806 (−7.8 %) |
| **Total** | 103,373 | 117,320 | 115,750 |

- **Todo el crecimiento de 2025 es Flex Fare.** Los viajes con tarjeta, efectivo y otros métodos se mantuvieron constantes.
- **En 2026 Flex Fare sigue creciendo, pero ya no compensa la caída de los demás viajes (−7.8 %).**
- **Por franja horaria:** en 2025 la madrugada (0–5 h) crece 29 % y la noche 18.5 %, contra +9 % en la tarde y el día. En 2026, las franjas de día y tarde **bajan** (−2.3 % y −5.3 %), mientras que la madrugada y la mañana todavía suben (~+4–5 %).

### Patrón 2 - En la zona CBD la velocidad no bajó con el cobro; la caída de 2026 es general

El Ejercicio 7 encontró que, dentro de la zona de cobro, los viajes de 2026 son 7 % más lentos que los de 2024. Con dos años no se podía saber si era efecto del cobro. La consulta 8.1 agrega 2025 y un **grupo de control**: viajes amarillos con origen y destino en Manhattan pero fuera de la zona. En ambos grupos se toman días laborables de 7 a 19 h.

| Velocidad mediana (mph), promedio ene–ago | 2024 | 2025 | 2026 |
|---|---|---|---|
| Dentro de la zona CBD | 7.13 | 7.16 (+0.4 %) | 6.60 (−7.8 %) |
| Manhattan fuera de la zona | 8.60 | 8.44 (−1.9 %) | 8.10 (−4.0 %) |
| Cociente dentro / fuera | 0.829 | **0.848** | 0.815 |

- **En 2025, el primer año del cobro, la zona CBD mantuvo su velocidad mientras el resto de Manhattan se hizo 1.9 % más lento.** Respecto al control, la zona mejoró ~2.3 %. Es consistente con un efecto moderado del cobro.
- **En 2026 ambos grupos se vuelven más lentos.** La caída es mayor dentro de la zona y el cociente baja a 0.815, por debajo de 2024. Como el grupo de control también cae, la mayor parte del cambio de 2026 es general y no se puede atribuir al cobro.
- La distancia mediana de los viajes internos es la misma los tres años (1.28–1.30 mi), así que no se están comparando viajes distintos.

### Patrón 3 - En 2025 hay un problema de captura en los montos de un proveedor

Con los tres años, el indicador de calidad (I11) muestra algo que no aparecía con 2024+2026. En los amarillos de enero a noviembre de 2025, la regla de monto (tarifa o total ≤ 0) marca entre **4.2 % y 9.5 %** de los registros de cada mes, contra 1.3–2.2 % en 2024 y 0.4–1.1 % en 2026. En diciembre de 2025 vuelve de golpe a 1.2 %.

La consulta 8.3 lo ubica en un solo grupo: **viajes Flex Fare del proveedor 2**, que pasan de < 0.5 % de los registros del mes en 2024 a 2.4–8.3 % en enero–noviembre de 2025, y a 0 en diciembre. Además:
- el 90 % de esos registros tiene distancia > 0, es decir, son viajes reales;
- casi ninguno tiene tarifa **y** total en cero a la vez.

Es un cambio en cómo ese proveedor registró los montos de Flex Fare durante 11 meses, no un cambio en los viajes. Consecuencias:
- en 2025 se excluye ~10 % de los amarillos, contra ~5 % los otros años;
- los viajes válidos de 2025 **subestiman** el volumen real: con registros sin filtrar, 2025 queda 20 % sobre 2024, y no 13.5 %.

Es el mismo tipo de hallazgo que la regla de duración en 2026 (proveedor 7, Ejercicio 5).

### Patrón 4 - El total sube en 2026 por los viajes Flex Fare, no por la tarifa ni por el cargo CBD

El total mediano de los amarillos sube 3.2 % en 2025 y 9.1 % en 2026. Lo esperable era que el salto ocurriera en 2025, cuando empezó el cargo CBD. Dos consultas lo explican:

**8.4 (proveedor 2, tarifa estándar, promedios de ene–ago):** el total promedio pasa de 25.43 a 25.66 USD (+0.9 %) y luego a 26.18 USD (+2.0 %).
- En 2025 el cargo CBD agrega 0.57 USD por viaje, pero los viajes son más cortos (2.74 → 2.68 mi) y la tarifa baja (16.80 → 16.46 USD). El efecto casi se compensa.
- En 2026 la tarifa por milla sube de 6.15 a 6.36 USD (+3.4 %).
- Los recargos fijos no cambian en los tres años: `extra` ~1.0, `mta_tax` 0.50, `improvement_surcharge` 1.00, `congestion_surcharge` ~2.36.

**8.5 (total mediano por forma de pago):**

| Amarillos, ene–ago | 2024 | 2025 | 2026 |
|---|---|---|---|
| Tarjeta | 21.42 | 21.91 | 22.38 (+2.1 %) |
| Efectivo | 17.53 | 17.82 | 18.47 (+3.6 %) |
| **Flex Fare / sin dato** | 22.27 | 22.80 | **29.15 (+27.9 %)** |
| Todos | 20.97 | 21.65 | 23.61 (+9.1 %) |
| % de viajes Flex Fare | 9.1 | 19.7 | 25.0 |

En 2026 los viajes Flex Fare se vuelven **28 % más caros** y más largos (distancia mediana 2.69 → 2.89 mi), y además son una cuarta parte de los viajes. Las demás formas de pago suben solo 2–4 %. El aumento del total de 2026 es sobre todo un efecto de composición. No es que cada viaje cueste 9 % más.

### Patrón 5 - Los verdes se contraen cada año y se concentran en East Harlem

Los verdes pierden viajes en cada año: −10.7 % y luego −14.7 %, un 24 % acumulado. Su participación baja de 1.8 % a 1.1 %. Mientras tanto, sus dos zonas principales (East Harlem North y South) pasan de 38.2 % a 40.7 % de sus viajes. El total mediano sube de forma pareja, ~3.5 % por año. A diferencia de los amarillos, Flex Fare no compensa la caída: crece (4.1 % → 13.6 % de los viajes), pero sobre una base mucho menor.

### Lo que no cambió

La propina (53–54 % de los amarillos dejan exactamente 20 %), la forma del día (pico a las 17–18 h, madrugada de fin de semana) y la estacionalidad (máximo en mayo y octubre, valle en julio–agosto) se repiten en los tres años. Esto refuerza que los patrones 1 a 5 son cambios reales y no ruido.

## 8.7 Consultas utilizadas

Todas están en `sql/`, con pregunta, objetivo y fuente en el encabezado. SQL, resultado completo y tiempo de cada una en los archivos `.md` de `docs/resultados/`.

| Consulta | Para qué se usó | Resultado |
|---|---|---|
| `sql/ejercicio7/7_01` a `7_12` (sin cambios) | Indicadores con los tres años (8.4, 8.5) | [`ejercicio8/indicadores_3_anios.md`](resultados/ejercicio8/indicadores_3_anios.md) |
| `sql/ejercicio8/8_01_velocidad_cbd_vs_control.sql` | Patrón 2: zona CBD frente al resto de Manhattan, por año y mes | [`ejercicio8.md`](resultados/ejercicio8.md) |
| `sql/ejercicio8/8_02_crecimiento_por_franja_y_pago.sql` | Patrón 1: viajes por día por franja y forma de pago (meses comunes) | ídem |
| `sql/ejercicio8/8_03_desglose_monto_cero.sql` | Patrón 3: registros con monto ≤ 0 por proveedor y método de pago | ídem |
| `sql/ejercicio8/8_04_componentes_del_total.sql` | Patrón 4: componentes promedio del total (proveedor 2, tarifa estándar) | ídem |
| `sql/ejercicio8/8_05_precio_por_forma_de_pago.sql` | Patrón 4: total mediano por forma de pago, con `GROUPING SETS` | ídem |
| `sql/ejercicio5/5_01` a `5_09` (sin cambios) | Validación de la incorporación de 2025 (archivos, filas, esquema, calidad) | [`ejercicio8/ejercicio5_3_anios.md`](resultados/ejercicio8/ejercicio5_3_anios.md) |
| `sql/ejercicio3/*`, `sql/ejercicio4/*` (sin cambios) | 8.3: compatibilidad | [`ejercicio5_compatibilidad.md`](resultados/ejercicio5_compatibilidad.md) |

Las consultas 8.1, 8.2 y 8.5 calculan sus parámetros a partir de los datos y no los tienen fijos en el código: las zonas CBD, igual que el indicador I5, y los meses comunes a todos los años. Si se agrega 2027 o llegan nuevos meses de 2026, funcionan sin cambios.

Nota sobre el ambiente: estas consultas se ejecutaron con DuckDB 1.5.5 (la misma versión de `requirements.txt`) en una computadora con 5.9 GB de RAM, con `LAB8_MEMORY_LIMIT=2GB` y `LAB8_THREADS=4`. Metabase estuvo detenido durante el cálculo.
