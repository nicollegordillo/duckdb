# Ejercicio 3 - Consultas directas sobre archivos Parquet

Todas las consultas de este ejercicio leen los Parquet **directamente** con `read_parquet`, `glob`, `parquet_file_metadata` o `parquet_schema`: no se crea ninguna tabla ni se importan datos.

- **Consultas:** `sql/ejercicio3/` (una por archivo; el encabezado de cada una documenta su objetivo y los archivos fuente).
- **SQL + resultado + tiempo de cada consulta (3.8):** [`docs/resultados/ejercicio3.md`](resultados/ejercicio3.md), generado con `python scripts/run_sql.py ejercicio3`. Los resultados completos están en `docs/resultados/ejercicio3/*.csv`.
- **Notebook:** `notebooks/ejercicio3_exploracion.ipynb`.
- **Referencia:** diccionario de datos de taxis amarillos de la TLC (versión del 18 de marzo de 2025).

## Resumen del conjunto de datos (2026)

| | Amarillos | Verdes | Total |
|---|---|---|---|
| Archivos | 8 (ene–ago) | 8 (ene–ago) | 16 |
| Registros | 29,703,355 | 337,114 | 30,040,469 |
| % del total | 98.88 % | 1.12 % | |
| Columnas | 21 | 22 | 25 distintas |
| Viajes por día (rango mensual) | 107,636 – 131,962 | 1,299 – 1,475 | |

## 3.8 Documentación de las consultas

| Id | Archivo | Objetivo | Fuente | Resultado | Decisión tomada |
|---|---|---|---|---|---|
| 3.1 | `3_01_cantidad_archivos.sql` | Archivos por tipo y año, y meses cubiertos | nombres en `data/raw/*/*/*.parquet` | 8 archivos amarillos y 8 verdes, meses 01 a 08 sin huecos. | El conjunto coincide con lo publicado por la TLC (hasta agosto de 2026); no hace falta volver a descargar. |
| 3.2a | `3_02_registros_por_archivo.sql` | Registros por archivo desde los metadatos | footer de cada Parquet | Amarillos: entre 3.34 M (ago) y 4.09 M (may) por mes, 4 *row groups* por archivo. Verdes: entre 37 K (feb) y 45 K (may), 1 *row group*. Los archivos fueron escritos con distintas versiones de Arrow (16.1, 21.0 y 24.0). | Ningún mes tiene volumen anómalo que indique un archivo incompleto. La variación de versiones indica que la TLC generó los archivos en momentos distintos; no afecta la lectura. |
| 3.2b | `3_03_registros_totales.sql` | Total de registros con `count(*)` | `yellow/*/*`, `green/*/*` | 29,703,355 amarillos + 337,114 verdes = 30,040,469, igual a la suma de 3.2a. | Todos los archivos se leen completos. |
| 3.3a / 3.3b | `3_04`, `3_05` | Columnas y tipos de cada tipo de taxi | `yellow/*/*`, `green/*/*` | 21 columnas en amarillos y 22 en verdes. Incluye `request_source` (VARCHAR), que no está en el diccionario de la TLC. | Investigar `request_source` (ver 3.4 y 3.6i). |
| 3.3c | `3_06_comparacion_columnas.sql` | Columnas comunes, exclusivas y con tipo distinto | ambos | 18 columnas comunes con el mismo tipo. Fechas con prefijo distinto (`tpep_*` / `lpep_*`); `Airport_fee` solo en amarillos; `ehail_fee` y `trip_type` solo en verdes. | Vista unificada `viajes` (`sql/00_vistas.sql`) con nombres comunes, columna `taxi` y `NULL` donde la columna no aplica. Se descarta `ehail_fee` (100 % nula, ver 3.6b). |
| 3.4 | `3_07_tipos_por_archivo.sql` | Tipo físico de cada columna en cada archivo | `parquet_schema` de todos | Todas las columnas tienen un único tipo físico en los 8 archivos de cada tipo, **excepto** `request_source`, que solo existe en 3 de 8 archivos (jun–ago). | Leer siempre con `union_by_name = true` (los archivos sin la columna la reciben como `NULL`) y normalizar tipos con `TRY_CAST` en la vista, para tolerar cambios de esquema al agregar 2024 y 2025. |
| 3.5a / 3.5b | `3_08`, `3_09` | Muestra reproducible de 10 registros | ambos | Ver "Observaciones de la muestra". | Motivó revisar el bloque de nulos y la consistencia de montos. |
| 3.6a / 3.6b | `3_10`, `3_11` | Perfil de columnas (`SUMMARIZE`) | ambos | Ver "Problemas de calidad". | Definir los umbrales de las reglas de calidad. |
| 3.6c | `3_12_reglas_calidad.sql` | Conteo de violaciones por regla | ambos | Ver tabla de problemas de calidad. | Banderas `f_*` en `viajes_enriquecidos` y subconjunto `viajes_validos`. |
| 3.6d | `3_13_fechas_fuera_de_mes.sql` | Fechas de pickup fuera del mes del archivo | ambos | 146 amarillos y 98 verdes. Son de tres clases: bordes de mes, envíos tardíos y fechas imposibles (2001-01-01, 2008-12-31, 2009-01-01). | Bandera `f_fuera_periodo`. El análisis temporal agrupa por fecha de pickup solo sobre registros dentro del periodo del archivo. |
| 3.6e | `3_14_codigos_categoricos.sql` | Códigos presentes vs. diccionario TLC | ambos | Todos los códigos existen en el diccionario. En amarillos, `payment_type = 0` (Flex Fare) aparece en exactamente los mismos 7,716,688 registros con nulos. En verdes no hay código 0: el mismo bloque trae `payment_type` NULL (48,775). `RatecodeID = 99` (nulo/desconocido) aparece en 769,693 amarillos. | No eliminar el bloque Flex Fare/NULL: tratarlo como categoría de pago (`metodo_pago` = "Flex fare" o "Sin dato"). Excluir `RatecodeID = 99` solo de los análisis por tipo de tarifa (3.6h muestra que es un artefacto de un proveedor). |
| 3.6f | `3_15_consistencia_montos.sql` | `total_amount` vs. suma de componentes | ambos | No coincide en 36.7 % de amarillos (mediana de la diferencia: 2.50 USD) y 19.9 % de verdes (mediana 12.20 USD). | Usar `total_amount` tal como se reporta (es lo cobrado). No recalcularlo desde sus componentes. El origen de la diferencia se explica en 3.6h. |
| 3.6g | `3_16_duplicados.sql` | Viajes repetidos | ambos | 32,794 duplicados en amarillos (0.11 %); ninguno en verdes. | No deduplicar: el efecto en las métricas es despreciable. Se documenta como limitación. |
| 3.6h | `3_17_desglose_inconsistencia_montos.sql` | Origen de la inconsistencia de montos | ambos | La diferencia se explica casi por completo por proveedor y método de pago. El proveedor 2 (Curb) cuadra en más del 99.7 % de sus viajes que no son Flex Fare. Cada uno de los demás tiene una diferencia constante: Flex Fare +2.50 USD en amarillos y +2.75 en verdes, proveedor 1 −3.25 / −1.00, proveedor 6 +12.20 y proveedor 7 +1.00. El 99.9 % de los `RatecodeID = 99` viene del proveedor 1. | `total_amount` es la única medida de monto comparable entre proveedores. Los análisis por componente (p. ej. ingresos por recargo de congestión) solo son válidos para el proveedor 2 fuera de Flex Fare. Se agrega `vendor_id` como dimensión de control en el Ejercicio 4. |
| 3.6i | `3_18_request_source.sql` | Meses, valores y relación de `request_source` con el método de pago | ambos | Solo tiene valores de junio a agosto. **Todos** los registros con `request_source` son Flex Fare (amarillos) o tienen pago NULL (verdes), y cubren el 99.97 % de esos viajes. Toma seis valores: `A`, `CC`, `EH0004`, `EH0010`, `HV0003` y `HV0005`. `EH0010` aparece desde julio y `HV0005` solo en agosto. | Se interpreta como el canal o plataforma por el que se solicitó el viaje Flex Fare; se incluye en la vista `viajes`. Su análisis se limita a jun–ago de 2026. |

### Observaciones de la muestra (3.5)

- Dos de los diez registros amarillos tienen `payment_type = 0`. Ambos tienen nulos simultáneos en `passenger_count`, `RatecodeID`, `store_and_fwd_flag`, `congestion_surcharge` y `Airport_fee`, y son los únicos con `request_source` lleno (`A` y `HV0003`).
- En esos dos registros, `total_amount` supera la suma de sus componentes por exactamente 2.50 USD, el mismo valor del recargo por congestión que falta.
- Un registro amarillo tiene `RatecodeID = 99` (proveedor 1) y `improvement_surcharge = 0`, distinto al 1.00 habitual.
- Un registro verde del proveedor 6 (Myle Technologies) tiene el bloque de nulos y una tarifa de 3.00 USD contra un total de 16.00 USD. La diferencia, 12.20 USD, es justamente la mediana de la diferencia de montos en verdes (3.6f).
- `ehail_fee` está vacía en todos los registros verdes.

## 3.6 Problemas de calidad identificados

Porcentajes sobre el total de registros de cada tipo (3.6a–3.6c, 3.6g).

| Problema | Amarillos | Verdes | Tratamiento |
|---|---|---|---|
| Pickup fuera del mes del archivo | 146 (<0.001 %) | 98 (0.03 %) | `f_fuera_periodo` |
| Dropoff antes del pickup | 10 | 5 | `f_duracion` |
| Duración cero | 371,673 (1.25 %) | 229 (0.07 %) | `f_duracion` |
| Duración mayor a 6 h | 7,315 (0.02 %) | 1,104 (0.33 %) | `f_duracion` |
| Distancia cero | 952,231 (3.21 %) | 12,212 (3.62 %) | `f_distancia` |
| Distancia mayor a 100 mi (máx. 328,522 / 179,831 mi) | 1,223 | 72 | `f_distancia`, `f_velocidad` |
| Tarifa negativa (mín. −2,555 / −500 USD) | 157,364 (0.53 %) | 999 (0.30 %) | `f_monto` |
| Total negativo | 161,835 (0.54 %) | 1,023 (0.30 %) | `f_monto` |
| `passenger_count = 0` | 91,359 (0.31 %) | 4,527 (1.34 %) | `f_pasajeros` |
| Bloque de nulos (pasajeros, tarifa, flag, congestión) | 7,716,688 (25.98 %) | 48,775 (14.47 %) | Se conserva como categoría de pago |
| `RatecodeID = 99` (99.9 % del proveedor 1) | 769,693 (2.59 %) | 2 | Se conserva; se excluye de análisis por tipo de tarifa |
| `total_amount` ≠ suma de componentes (patrones por proveedor, 3.6h) | 36.7 % | 19.9 % | Se usa `total_amount` reportado |
| Duplicados | 32,794 (0.11 %) | 0 | Se conservan |
| `ehail_fee` | — | 100 % nula | Se descarta |

Interpretación:

1. **Fechas fuera de periodo (3.6d).** Son muy pocas y de tres clases:
   - *Bordes de mes:* viajes que empiezan minutos antes de medianoche del último día del mes anterior.
   - *Envíos tardíos:* el archivo amarillo de junio trae 15 viajes del 16 al 20 de abril, y el de julio trae 38 del 1 al 5 de agosto.
   - *Fechas imposibles:* 2001-01-01, 2008-12-31 y 2009-01-01, típicas de un reloj sin configurar.

   Su efecto en los totales es nulo, pero sin filtrarlas una serie temporal mostraría puntos falsos en 2001 y 2009.
2. **Duraciones y distancias imposibles.** Son el problema más frecuente: 3.2–3.6 % de viajes con distancia cero y 1.25 % de amarillos con duración cero. Hay distancias de hasta 328,522 millas. Se marcan con umbrales conservadores (duración ≤ 0 o > 6 h; distancia ≤ 0 o > 100 mi; velocidad > 80 mph) para no eliminar viajes largos reales como los de aeropuerto.
3. **Montos negativos.** Cerca de 0.5 % en amarillos. Corresponden a reembolsos o ajustes y no representan viajes cobrados, así que se excluyen del análisis con `f_monto`. Algunas colas extremas (tarifa de 7,045 USD, peajes de 1,400 USD) no son imposibles, por lo que no se eliminan; las métricas del Ejercicio 4 usan medianas y percentiles, que son robustos a esos valores.
4. **Bloque Flex Fare / sin dato.** No es ruido aleatorio. En amarillos los 7,716,688 registros con nulos en `passenger_count`, `RatecodeID`, `store_and_fwd_flag`, `congestion_surcharge` y `Airport_fee` son exactamente los que tienen `payment_type = 0`, que el diccionario define como *Flex Fare trip*. En verdes el mismo bloque (48,775) trae `payment_type` NULL. Eliminarlo descartaría la cuarta parte de los viajes amarillos y sesgaría el análisis, así que se conserva como categoría propia. Consecuencia: las métricas de pasajeros y tipo de tarifa solo describen al 74 % de los viajes amarillos.
5. **`RatecodeID = 99`.** Significa "nulo/desconocido" según el diccionario. Afecta 2.6 % de amarillos y casi ningún verde. El 99.93 % (769,133 de 769,693) viene del proveedor 1 (Creative Mobile Technologies). En sus viajes con tarjeta, 19 % llevan el código 99. Es una práctica de registro de ese proveedor, no un tipo de viaje. Por eso el promedio de `RatecodeID` en amarillos (4.5) no tiene sentido: es un código categórico.
6. **Proveedores nuevos.** Los proveedores 6 (Myle Technologies) y 7 (Helix) del diccionario de 2025 ya aparecen. El 6 genera 10.3 % de los registros verdes; el 7 genera 1.2 % de los amarillos.
7. **Inconsistencia de montos (3.6f, 3.6h).** La diferencia entre `total_amount` y la suma de sus componentes no es ruido aleatorio. Cada combinación de proveedor y método de pago tiene una diferencia constante:

   | Origen | Diferencia típica (total − suma) | % de las inconsistencias amarillas | % de las verdes |
   |---|---|---|---|
   | Flex Fare (pago 0 o NULL) de cualquier proveedor | +2.50 USD amarillos / +2.75 verdes | 63.4 % | 7.0 % |
   | Proveedor 1 (Creative Mobile Technologies), demás pagos | −3.25 USD amarillos / −1.00 verdes | 35.0 % | 40.8 % |
   | Proveedor 6 (Myle Technologies), todos sus viajes | +12.20 USD | (incluido en Flex Fare) | 52.0 % |
   | Proveedor 7 (Helix) | +1.00 USD | 1.4 % | — |
   | Proveedor 2 (Curb Mobility), fuera de Flex Fare | — | 0.2 % | 0.2 % |

   Interpretación:

   - **Flex Fare.** La diferencia es exactamente el recargo por congestión de cada tipo de taxi: 2.50 en amarillos y 2.75 en verdes (el máximo de `congestion_surcharge` en 3.6b). Esa columna viene NULL en estos viajes, así que el total sí incluye el recargo pero el desglose no lo reporta. Se confirma la hipótesis planteada en la muestra.
   - **Proveedor 1.** La suma de componentes **supera** al total por 3.25 USD, igual a congestión (2.50) + CBD (0.75). Esto sugiere que ese proveedor reporta los recargos en sus columnas pero no los suma al total, o los cuenta dos veces.
   - **Proveedores 6 y 7.** Tienen diferencias fijas (+12.20 y +1.00) que el diccionario no explica.
   - **Proveedor 2.** El de mayor volumen cuadra en más del 99.7 % de sus viajes que no son Flex Fare.

   **Decisión:** `total_amount` se usa tal como se reporta, porque es lo que se cobró. Los análisis que dependen de un componente aislado (recargo de congestión, peajes, CBD) mezclarían convenciones de registro distintas, así que solo se harían sobre el proveedor 2 fuera de Flex Fare. Se agrega `vendor_id` como dimensión de control cuando un resultado pueda depender del proveedor. Las cifras suman 278 inconsistencias menos que 3.6f porque 3.6h redondea la diferencia a centavos antes de comparar; el efecto es despreciable.
8. **`request_source`, columna no documentada (3.4, 3.6i).** Solo existe en 3 de 8 archivos (junio a agosto) y no aparece en el diccionario de la TLC de marzo de 2025. La consulta 3.6i confirma su relación con Flex Fare:
   - en amarillos, de jun a ago, `request_source` tiene valor en 1,013,180, 969,417 y 920,849 registros, y **todos** son Flex Fare;
   - esos registros son el 99.97 % de los viajes Flex Fare de cada mes;
   - en verdes ocurre lo mismo con los viajes de pago NULL.

   Toma seis valores: `A`, `CC`, `EH0004`, `EH0010`, `HV0003` y `HV0005`. `HV0003` y `HV0005` coinciden con los códigos de licencia de Uber y Lyft en los datos de FHV de alto volumen de la TLC. Los `EH00xx` siguen un patrón similar, posiblemente licencias de otras aplicaciones de solicitud. `A` y `CC` no tienen equivalente conocido. Además, el conjunto de valores crece con el tiempo: `EH0010` aparece en julio y `HV0005` en agosto.

   **Interpretación:** `request_source` identifica el canal o plataforma por el que se pidió un viaje Flex Fare (tarifa acordada al solicitar el viaje). La TLC empezó a publicarla en los archivos de junio de 2026. Es una interpretación basada en los datos, no una definición oficial. **Decisión:** se incluye en la vista `viajes`; cualquier análisis con ella se limita a jun–ago de 2026.

9. **Peso de Flex Fare por mes (3.6i).** En amarillos, Flex Fare es el 29.2 % de los viajes en enero y 30.1 % en febrero, baja a 20.9 % en abril y sube de nuevo a 27.6 % en agosto. Es una variación relevante que se analiza en el Ejercicio 4.

Todas las transformaciones quedan registradas en `sql/00_vistas.sql` (esquema unificado `viajes`) y `sql/02_vistas_analisis.sql` (banderas de calidad; hasta el Ejercicio 5 estaban al final de `00_vistas.sql`). Las vistas **no borran datos**: solo marcan registros con banderas, y el impacto de cada regla se cuantifica en la consulta P9 del Ejercicio 4. Los umbrales se pueden ajustar en un solo lugar.

## 3.9 ¿Qué significa consultar directamente un archivo Parquet?

Significa que DuckDB trata el archivo, o un conjunto de archivos definido con un patrón como `data/raw/yellow/*/*.parquet`, como si fuera una tabla, **sin copiar los datos a una base de datos ni cargarlos completos en memoria**. Los datos se leen del disco en el momento de ejecutar la consulta. Es útil con volúmenes grandes por varias razones:

- **Formato columnar.** Parquet guarda cada columna por separado. Una consulta que usa 2 de 21 columnas solo lee esas 2 (*projection pushdown*).
- **Metadatos y estadísticas.** Cada archivo guarda en su footer el número de filas y, por cada *row group*, el mínimo y máximo de cada columna. DuckDB usa esto para responder conteos sin recorrer los datos y para saltarse bloques que no cumplen un filtro (*filter pushdown*).
- **Compresión.** Se lee mucho menos del disco que con el CSV equivalente.
- **Paralelismo.** DuckDB reparte archivos y *row groups* entre todos los núcleos.
- **Sin duplicar datos ni pasos de carga.** Al agregar un archivo nuevo a la carpeta, la siguiente consulta ya lo incluye.
- **Memoria acotada.** A diferencia de cargar todo en un DataFrame, DuckDB procesa por bloques y puede usar el disco si una agregación no cabe en memoria.

Evidencia en este laboratorio, sobre 30 millones de registros (tiempos de `docs/resultados/ejercicio3.md`):

| Consulta | Qué lee | Tiempo |
|---|---|---|
| 3.2a: conteo por archivo con metadatos | solo los footers de 16 archivos | 0.04 s |
| 3.2b: `count(*)` sobre todos los archivos | DuckDB también lo resuelve con metadatos | 0.11 s |
| 3.6d: fechas fuera del mes | 1 columna (pickup) + nombre de archivo | 0.54 s |
| 3.6c: reglas de calidad | ~10 columnas | 1.47 s |
| 3.6a: `SUMMARIZE` amarillos | las 21 columnas, con cuartiles y conteos de únicos | 11.19 s |

El tiempo crece con el número de columnas leídas y con el cálculo realizado. Leer pocas columnas de 30 millones de filas toma menos de un segundo sin haber importado nada. La comparación entre filas no es un experimento controlado, porque cada consulta además calcula cosas distintas; el Ejercicio 6 compara formalmente Parquet contra tabla materializada.
