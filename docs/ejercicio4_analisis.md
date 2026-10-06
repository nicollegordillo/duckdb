# Ejercicio 4 - Análisis exploratorio con DuckDB

- **Consultas:** `sql/ejercicio4/` (el encabezado de cada una incluye pregunta, justificación y fuente).
- **SQL + resultado + tiempo (4.3):** [`docs/resultados/ejercicio4.md`](resultados/ejercicio4.md), generado con `python scripts/run_sql.py ejercicio4`.
- **Notebook con gráficas:** `notebooks/ejercicio4_analisis.ipynb` (las figuras se guardan en `docs/figuras/`).

## Enfoque

Las consultas no leen rutas de archivos sino las vistas de `sql/00_vistas.sql`:

- `viajes`: amarillos y verdes con un esquema común (columna `taxi` = `yellow` / `green`).
- `viajes_enriquecidos`: agrega duración, velocidad, % de propina, hora, día de la semana, método de pago y banderas de calidad.
- `viajes_validos`: excluye los registros marcados por las reglas del Ejercicio 3.
- `zonas`: catálogo `LocationID → Borough / Zone`.

Ventajas: las consultas son legibles, las reglas de limpieza están en un solo lugar, y al agregar 2024/2025 (Ejercicios 5 y 8) o al reemplazar los Parquet por una tabla materializada (Ejercicio 6) las consultas no cambian.

## 4.1 Preguntas planteadas

| Id | Pregunta | Justificación (por qué es relevante para este conjunto de datos) | Tema del enunciado |
|---|---|---|---|
| P1 | ¿Cómo evoluciona la cantidad de viajes mes a mes y qué proporción corresponde a cada tipo de taxi? | Los datos llegan por mes; es la serie temporal básica y muestra estacionalidad y el peso de cada tipo. | Comportamiento temporal; amarillos vs. verdes |
| P2 | ¿En qué horas y días se concentra la demanda y difiere el patrón entre tipos? | El pickup tiene fecha y hora exactas; distingue patrones de trabajo y ocio. | Comportamiento temporal |
| P3 | ¿Cómo es un viaje típico (distancia, duración, velocidad, costo)? | Variables muy asimétricas: se requieren percentiles, no solo promedios. | Características; distribución |
| P4 | ¿En qué se diferencian amarillos y verdes en volumen, costo, pasajeros, propina y cargos especiales? | Los verdes (*boro taxis*) operan con reglas distintas. | Amarillos vs. verdes |
| P5 | ¿Desde qué boroughs se originan los viajes de cada tipo? | Los verdes se crearon para atender zonas fuera del centro de Manhattan; se puede comprobar con `PULocationID`. | Amarillos vs. verdes |
| P6 | ¿Cómo se distribuyen los métodos de pago y cómo cambia la propina registrada según el método? | Si la propina en efectivo no se registra, cualquier análisis de propinas que no separe por método está sesgado. | Pago |
| P7 | ¿Qué % de propina dejan quienes pagan con tarjeta y se concentra en valores particulares? | La pantalla del taxi sugiere porcentajes fijos; se puede ver su efecto. | Pago; distribución |
| P8 | ¿Cómo se distribuye el monto total y hay picos en valores específicos? | `total_amount` es la variable de negocio; los picos revelan tarifas fijas (p. ej. aeropuerto). | Distribución; atípicos |
| P9 | ¿Qué proporción de registros es atípica o inconsistente, por qué regla, tipo y mes? | Cuantifica el efecto de la limpieza y detecta meses o tipos con problemas de captura. | Atípicos e inconsistencias |
| P10 | Entre los viajes válidos, ¿cuántos tienen un costo por milla atípico (regla IQR)? | Detecta valores posibles pero inusuales (distancia mal registrada, tarifas fijas). | Atípicos |
| P11 | ¿Los pasajeros eligen los porcentajes sugeridos por la pantalla (20, 25, 30 %) si la propina se mide sobre el total antes de propina? | Surge del resultado de P7: el pico no cae en 20 % al medir sobre la tarifa base. Se usa solo el proveedor 2, cuyos totales son consistentes (Ejercicio 3, 3.6h). | Pago; distribución |

## 4.2 - 4.3 Consultas y visualizaciones

| Id | Consulta | Figura |
|---|---|---|
| P1 | `4_01_viajes_por_mes.sql` | `figuras/p1_viajes_por_mes.png` |
| P2 | `4_02_hora_dia_semana.sql` | `figuras/p2_hora_dia.png` |
| P3 | `4_03_caracteristicas_viaje.sql` | `figuras/p3_caracteristicas.png` |
| P4 | `4_04_resumen_por_tipo.sql` | (tabla) |
| P5 | `4_05_viajes_por_borough.sql` | `figuras/p5_borough.png` |
| P6 | `4_06_metodo_pago.sql` | `figuras/p6_pago.png` |
| P7 | `4_07_distribucion_propina.sql` | `figuras/p7_propina.png` |
| P8 | `4_08_histograma_total.sql` | `figuras/p8_histograma_total.png` |
| P9 | `4_09_impacto_reglas_calidad.sql` | `figuras/p9_calidad.png` |
| P10 | `4_10_atipicos_tarifa_milla.sql` | (tabla) |
| P11 | `4_11_propina_sobre_total.sql` | `figuras/p11_propina_sobre_total.png` |

## 4.4 Resultados

Todas las cifras son sobre `viajes_validos`, salvo P9, que usa todos los registros. Las reglas de calidad excluyen el 5.31 % de los registros amarillos y el 7.22 % de los verdes, así que quedan 28,127,474 viajes amarillos y 312,777 verdes válidos (P9).

**P1 – Volumen mensual.**
- Los taxis amarillos hacen cerca de 90 viajes por cada viaje verde: 98.8–98.9 % de los viajes de cada mes.
- En amarillos, los viajes diarios suben de 112,926 en enero a un máximo de 125,733 en mayo. Luego caen hasta 101,757 en agosto, 19 % menos que en mayo.
- Los verdes tienen la misma forma pero más suave: 1,212 viajes por día en enero, un máximo de 1,370 en abril y 1,211 en agosto.
- Como los amarillos caen más en verano, la participación de los verdes alcanza su máximo en agosto (1.18 %).

**P2 – Hora y día de la semana** (figura `p2_hora_dia.png`).
- **Horas pico:** la hora con más viajes es las 18 h en amarillos y las 17 h en verdes. En ambos tipos, la demanda mínima está entre las 3 y las 5 h.
- **Amarillos, entre semana:** la demanda sube desde las 7 h, se mantiene alta todo el día y llega al máximo entre las 17 y las 21 h de martes a jueves.
- **Amarillos, fines de semana:** las madrugadas del sábado y el domingo (0–1 h) tienen tanta demanda como una hora pico de un día laboral, y el sábado se mantiene alto hasta las 23 h. Es el patrón de la vida nocturna.
- **Verdes:** siguen un horario de trabajo. Los viajes se concentran de lunes a viernes, con un pico de mañana (8–9 h) y otro de tarde (15–18 h, máximo el jueves a las 17 h). Los fines de semana y las noches son mucho más tranquilos, y casi no hay actividad de madrugada.

**P3 – Características del viaje** (percentiles aproximados con T-Digest).

| | Amarillos (mediana / promedio / p90) | Verdes (mediana / promedio / p90) |
|---|---|---|
| Distancia (mi) | 1.94 / 3.51 / 8.69 | 2.13 / 3.31 / 7.37 |
| Duración (min) | 14.1 / 17.7 / 33.4 | 13.2 / 17.1 / 32.0 |
| Velocidad (mph) | 9.3 / 10.9 / 19.1 | 10.0 / 11.4 / 18.2 |
| Total (USD) | 23.62 / 30.26 / 54.67 | 20.51 / 25.37 / 44.57 |

- **Viaje típico:** es corto, de unas 2 millas y 13–14 minutos, en el tráfico de la ciudad (9–10 mph).
- **Distribuciones asimétricas:** en todas las variables el promedio supera a la mediana. Por ejemplo, el total promedio de los amarillos es 28 % mayor que su mediana. Por eso se reportan percentiles.
- **Diferencias entre tipos:** el viaje mediano amarillo es *más corto* pero *más lento* y *más caro* que el verde, lo que concuerda con circular por Manhattan, pagar recargos de congestión y CBD, y hacer viajes largos al aeropuerto (p90 y p99 de distancia más altos).
- **Máximos:** coinciden con los límites de las reglas de calidad (100 mi, 360 min, 80 mph), lo que confirma que los filtros funcionan como se definieron.

**P4 – Amarillos vs. verdes.**

| | Amarillos | Verdes |
|---|---|---|
| Viajes válidos | 28,127,474 (98.9 %) | 312,777 (1.1 %) |
| Total promedio | 30.26 USD | 25.37 USD |
| Pasajeros promedio* | 1.25 | 1.32 |
| Pagan con tarjeta (sobre viajes con método conocido)** | 87.1 % | 76.9 % |
| Viajes de aeropuerto | 9.74 % | 0.29 % |
| Pagan cargo CBD | 72.4 % | 8.5 % |

\* Solo en viajes con `passenger_count` registrado: excluye Flex Fare / sin dato.
\*\* Calculado con P6, excluyendo Flex Fare (amarillos) y pago NULL (verdes). Sobre el total, la consulta da 65.3 % y 76.8 %.

Las diferencias más grandes están en los cargos ligados a la ubicación: el 72 % de los amarillos paga el cargo de la zona CBD contra el 8.5 % de los verdes, y los viajes de aeropuerto son el 9.7 % de los amarillos contra el 0.3 % de los verdes. Los verdes usan efectivo casi el doble que los amarillos (22.8 % contra 12.1 % entre viajes con método conocido). El costo promedio por milla de la consulta (34.46 contra 20.53 USD) está inflado por los viajes muy cortos; P10 da una medida más robusta.

**P5 – Origen por borough.**
- **Amarillos:** el 86.6 % sale de Manhattan, el 8.9 % de Queens, el 3.6 % de Brooklyn y el 0.8 % del Bronx.
- **Verdes:** el 60.3 % sale de Manhattan, el 22.3 % de Queens, el 15.0 % de Brooklyn y el 2.3 % del Bronx.

Que la mayoría de los verdes salga de Manhattan parece contradecir su propósito, pero no lo hace. Los taxis verdes no pueden recoger pasajeros en la calle en Manhattan al sur de la calle 96 Este y la 110 Oeste. El perfil del Ejercicio 3 (3.6b) lo confirma: `PULocationID` tiene cuartil 1 = 74 y mediana = 75. Es decir, al menos una cuarta parte de los viajes verdes empieza en solo dos zonas, East Harlem Norte y Sur, en el norte de Manhattan.

**P6 – Método de pago** (figura `p6_pago.png`).
- **Amarillos:** tarjeta 65.3 %, Flex Fare 25.0 %, efectivo 9.0 %, disputa 0.4 %, sin cargo 0.2 %.
- **Verdes:** tarjeta 66.4 %, efectivo 19.7 %, sin dato 13.6 %.
- **Propina en efectivo:** el 0 % de los viajes pagados en efectivo tiene propina registrada, en ambos tipos. Esto confirma el diccionario de la TLC: la propina en efectivo no se registra. Con tarjeta, el 91 % deja propina (91.1 % amarillos, 91.5 % verdes).
- **Flex Fare:** solo el 8.3 % tiene propina registrada, y su total promedio (32.44 USD) es mayor que el de tarjeta (30.04 USD). En verdes, los viajes "sin dato" también son los más caros (30.99 contra 25.60 USD con tarjeta).

En consecuencia, cualquier promedio de propinas sobre todos los viajes subestima la propina real. Las propinas solo se analizan con pagos con tarjeta (P7, P11).

**P7 – Porcentaje de propina con tarjeta (sobre la tarifa base).**
- Alrededor del 9 % de los pagos con tarjeta no deja propina (8.9 % en amarillos, 8.5 % en verdes).
- El rango de 19 a 21 % es de los **menos** frecuentes: 2.9 % en amarillos y 3.4 % en verdes.
- En amarillos la propina se concentra en 26–29 % (16.5 %) y en 31 % o más (27.4 %).
- En verdes el pico está en 21–24 % (22.3 %).

La propina se calcula como `tip_amount / fare_amount`. Si los pasajeros eligen 20, 25 o 30 % en la pantalla y la pantalla aplica ese porcentaje sobre la tarifa **más los recargos**, la propina se ve más alta al dividirla solo entre la tarifa. El desplazamiento es mayor en amarillos porque pagan más recargos: congestión 2.50 y CBD 0.75 en la mayoría de los viajes, mientras que en los verdes casi siempre son 0 (3.6a–3.6b). P11 pone a prueba esta explicación.

**P8 – Monto total.**
- **Amarillos:** el intervalo más frecuente es 15–20 USD (22.4 %), y el 74.7 % de los viajes cuesta entre 10 y 35 USD. La cola derecha es larga. Hay un segundo pico entre 95 y 105 USD (0.69 % y 0.79 %) que cae a 0.33 % en el intervalo siguiente. Es consistente con la tarifa fija al aeropuerto JFK (`RatecodeID = 2`, 694,936 viajes en 3.6e) más recargos, peajes y propina. Según P10, el 12 % de los atípicos de costo por milla en amarillos usa una tarifa especial.
- **Verdes:** la distribución está más a la izquierda. El 5.0 % cuesta 5–10 USD (1.1 % en amarillos), el 19.1 % cuesta 10–15 USD, y el intervalo más frecuente es 15–20 USD (23.7 %).

**P9 – Registros atípicos o inconsistentes.**
- **Amarillos:** se excluye entre 4.46 % (abril) y 6.02 % (enero) de los registros de cada mes. La regla que más pesa es distancia ≤ 0 o > 100 mi (~3.2 % de los registros), seguida de duración (~1.3 %). Las reglas de pasajeros y velocidad pesan poco.
- **Los montos ≤ 0 se concentran a inicios de año:** 41,592 en enero, 29,171 en febrero y 23,802 en marzo. De abril en adelante se estabilizan en ~17,000 por mes, 59 % menos que en enero.
- **Verdes:** tienen proporcionalmente más registros problemáticos, entre 6.7 % y 7.8 % por mes, con tendencia a subir hasta julio. Sobresalen la distancia y una tasa de velocidad imposible unas diez veces mayor que en amarillos (~0.35 % contra ~0.03 %).

**P10 – Atípicos de costo por milla** (tarifa / distancia, regla IQR).

| | Amarillos | Verdes |
|---|---|---|
| Q1 – Q3 (USD por milla) | 5.73 – 9.95 | 5.42 – 8.20 |
| Límites atípicos | < −0.59 o > 16.27 | < 1.23 o > 12.39 |
| Atípicos altos | 1,622,681 (5.8 %) | 16,589 (5.3 %) |
| Atípicos bajos | 0 | 24,181 (7.7 %) |
| Distancia mediana de los atípicos altos | 0.60 mi | 0.52 mi |
| % con tarifa especial entre atípicos altos | 12.0 % | 27.7 % |

- **Atípicos altos:** casi todos son viajes muy cortos (mediana de 0.5–0.6 mi), donde el cargo inicial fijo pesa mucho por milla. No son errores sino una propiedad de la estructura de la tarifa. Solo el 12 % (amarillos) o el 28 % (verdes) usa una tarifa especial (aeropuerto o negociada).
- **Atípicos bajos:** solo aparecen en verdes. Coinciden con que estos taxis usan con frecuencia la tarifa negociada (`RatecodeID = 5`, 17,739 viajes en 3.6e).

**Decisión:** no se eliminan. La regla IQR sobre un cociente marca como "atípico" lo que en realidad es un tipo de viaje legítimo.

**P11 – Propina sobre el total antes de propina** (tarjeta, proveedor 2; figura `p11_propina_sobre_total.png`).

| Propina / (total − propina) | Amarillos | Verdes |
|---|---|---|
| 0 % | 5.4 % | 9.2 % |
| 10 % | 4.1 % | < 3.8 % |
| 15 % | 4.5 % | 3.8 % |
| **20 %** | **53.0 %** | **49.5 %** |
| 25 % | 7.4 % | 10.9 % |
| 30 % | 3.1 % | 5.1 % |

Medida sobre el total antes de propina, la distribución se concentra en valores exactos. **Más de la mitad de los pagos con tarjeta deja justamente 20 %**, y los valores redondos 10, 15, 20, 25 y 30 % suman cerca del 72 % de los viajes amarillos. Entre esos valores casi no hay viajes: por ejemplo, de 21 a 24 % se acumula apenas 1.3 % de los viajes amarillos. La hipótesis de P7 se confirma. Además, la aparente diferencia de generosidad entre tipos desaparece: ambos tienen la moda en 20 %. Los verdes dejan propina 0 % con más frecuencia (9.2 % contra 5.4 %) y 25 % con más frecuencia que los amarillos.

## 4.5 Hallazgos relevantes

1. **La forma de medir la propina cambia la conclusión (P7, P11).** Medida sobre la tarifa base (`tip_amount / fare_amount`), casi nadie deja 20 % y los amarillos parecen más generosos que los verdes: pico en 26–29 % contra 21–24 %. Medida sobre el total antes de propina, que es como la calcula la pantalla del taxi, el 53 % de los amarillos y el 50 % de los verdes deja **exactamente 20 %**, y los valores redondos 10–30 % concentran cerca del 72 % de los viajes amarillos. La diferencia entre tipos era un artefacto de la métrica: los amarillos pagan más recargos (congestión y CBD), y eso infla el cociente propina/tarifa. Lección: una métrica derivada debe definirse igual que el proceso que genera el dato. Además, este análisis solo es posible con tarjeta, porque la propina en efectivo aparece como 0 en el 100 % de los casos (P6).

2. **Amarillos y verdes atienden mercados distintos, en el espacio y en el tiempo (P2, P5).**
   - **Amarillos:** el 87 % sale de Manhattan y casi el 10 % son viajes de aeropuerto. Tienen fuerte actividad nocturna los fines de semana.
   - **Verdes:** el 60 % sale de Manhattan, pero solo de la parte norte donde tienen permitido recoger (al menos 25 % desde East Harlem). Casi no van al aeropuerto (0.3 %) y siguen un horario de trabajo: picos de lunes a viernes a las 8–9 h y las 15–18 h, con poca actividad de noche y en fin de semana.

   Esa diferencia explica que los verdes casi no paguen el cargo CBD (8.5 % contra 72 %) y que sus viajes sean más baratos (mediana 20.51 contra 23.62 USD) aunque sean un poco más largos.

3. **La demanda de 2026 tiene un ciclo estacional marcado (P1).** El máximo es en mayo y en julio–agosto los viajes caen 19 % en amarillos y 12 % en verdes respecto a su mes más alto. Como los verdes caen menos, su participación es la más alta en agosto. Al incorporar 2024 y 2025 (Ejercicios 5 y 8) se podrá comprobar si el patrón se repite cada año.

4. **Un valor atípico no siempre es un error, y los errores no se reparten de forma uniforme (P9, P10).**
   - Las reglas de calidad excluyen el 5.3 % de los amarillos y el 7.2 % de los verdes, con variaciones por mes. Por ejemplo, los montos ≤ 0 en amarillos se concentran en enero–marzo y luego bajan 59 %.
   - En cambio, la regla estadística IQR marca como atípico al 5.8 % de los viajes amarillos por su costo por milla, y casi todos son viajes legítimos de medio kilómetro (0.6 mi), donde pesa el cargo fijo inicial.

   Por eso la limpieza usa reglas de negocio explícitas (valores imposibles) y no reglas estadísticas genéricas, que eliminarían viajes reales.

5. **Una cuarta parte de los viajes amarillos son Flex Fare, y se comportan distinto (P4, P6; Ejercicio 3).** Representan el 25 % de los viajes amarillos válidos y cuestan más en promedio que los pagados con tarjeta (32.44 contra 30.04 USD). Además, casi no registran propina (8.3 %) y les faltan datos de pasajeros y tipo de tarifa. Cualquier métrica que dependa de esos campos (pasajeros promedio, tipo de tarifa, propina) describe solo al 75 % restante, y conviene reportarla separando este grupo.
