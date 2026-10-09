# Ejercicio 9 - Discusión

Las respuestas se apoyan en lo que se midió u observó durante el laboratorio. Entre paréntesis se indica el ejercicio y el archivo donde está la evidencia.

Escala final del proyecto: **121.2 millones de registros** (amarillos y verdes de 2024, 2025 y enero–agosto de 2026), **64 archivos Parquet** (2.0 GB). Los últimos ejercicios se ejecutaron en una computadora con 5.9 GB de RAM, con DuckDB limitado a 1.5–2 GB de memoria.

## 9.1 ¿Qué características de DuckDB resultaron más útiles?

1. **Consultar Parquet directamente con SQL, sin cargarlo antes.** `read_parquet('data/raw/yellow/*/*.parquet')` con un patrón *glob* trata 64 archivos como una sola tabla. Todo el análisis se apoya en vistas que no copian datos (`sql/00_vistas.sql`). Agregar 2024 (Ejercicio 5) y 2025 (Ejercicio 8) no requirió ningún paso de carga: los archivos nuevos entraron al análisis al aparecer en la carpeta.
2. **`union_by_name = true` y `filename = true`.** Los archivos de distintos años no tienen las mismas columnas (`cbd_congestion_fee` existe desde 2025, `request_source` desde junio de 2026). `union_by_name` las alinea por nombre y deja NULL donde faltan. `filename` permite saber de qué archivo (año y mes) viene cada fila, que es la base de `anio_archivo`/`mes_archivo`, de la regla `f_fuera_periodo` y de las comparaciones por año.
3. **Trabajar con más datos que memoria.** Con `memory_limit` de 1.5–2 GB, DuckDB procesó 121 M de filas y escribió en disco (`temp_directory`) cuando hizo falta. Las 12 consultas de indicadores sobre los tres años tardan 5.8 min en total (Ejercicio 8). `approx_quantile` (T-Digest) calcula medianas con memoria constante. La mediana exacta (`median`) agotaba la memoria con solo 30 M filas (Ejercicio 4).
4. **Proyección de columnas y descarte de *row groups* (*pushdown*).** Una consulta que usa 5 de 20 columnas solo lee esas 5, y un filtro por fecha descarta *row groups* con las estadísticas min/max del Parquet. Por eso B7 (un día en JFK) tarda 1.3 s sobre 72 M filas en Parquet y 0.02 s en la tabla (Ejercicio 6).
5. **SQL analítico expresivo:** `GROUP BY ALL`, `count_if`, `FILTER`, `QUALIFY`, `GROUPING SETS`, ventanas sobre agregados, `UNION ALL BY NAME`, `SET VARIABLE` / `getvariable()`. Con `getvariable()`, las mismas vistas leen 1 mes, 3 meses o 3 años sin editar el SQL (`scripts/lab.py:fijar_archivos`). Esto hizo posibles el benchmark del Ejercicio 6 y la opción `--anio`.
6. **Un solo archivo de base, sin servidor.** `taxis.duckdb` y `tablero.duckdb` son archivos que se copian, se borran y se regeneran con un comando. El modo `read_only` permite que Metabase, un notebook y un script lean a la vez.
7. **Herramientas de diagnóstico:** `EXPLAIN` y `EXPLAIN ANALYZE` mostraron, por ejemplo, que la CTE de 3.6e se materializaba completa (Ejercicio 5) y que con la tabla el optimizador reescribía una ventana como un *join* doble (Ejercicio 6). Sin el plan, esas diferencias de tiempo no se habrían explicado.
8. **El mismo motor en Python, notebooks y Metabase.** `duckdb` en Python, el driver JDBC en Metabase, el mismo SQL y los mismos archivos. Los resultados se pasan a pandas con `.df()` solo cuando ya son pequeños.

## 9.2 Ventajas y limitaciones de consultar directamente Parquet

**Ventajas:**
- **Cero tiempo de carga y siempre actualizado.** Un archivo descargado está disponible para el análisis de inmediato. Es lo que hizo triviales los Ejercicios 5 y 8.
- **Formato columnar y comprimido.** Los 121 M de registros ocupan 2.0 GB en Parquet. La tabla DuckDB equivalente ocupa ×1.7 más (1,995 MiB contra 1,172 MiB para 72 M filas, Ejercicio 6). Solo se leen las columnas que la consulta usa.
- **Inmutable y fuente de verdad.** El SHA-256 de cada archivo queda en `data/raw/manifest.csv`, y `verify_data.py` compara su tamaño con el publicado por la TLC. Cualquiera puede verificar que trabaja con los mismos datos.
- **Abierto e interoperable.** El mismo archivo lo leen DuckDB, pandas/pyarrow, Spark o Metabase, sin depender del formato interno de una herramienta.

**Limitaciones:**
- **Cada consulta paga leer y decodificar.** Descomprimir ZSTD y convertir páginas fue ~45 % del tiempo de CPU en las consultas de recorrido completo (Ejercicio 6, perfil de B5 y B6).
- **Costo fijo por archivo.** Abrir los archivos y leer sus metadatos se paga en cada consulta, aunque el resultado esté en un solo archivo. B7 tarda 0.25 s con 2 archivos y 1.3 s con 40. Con la tabla tarda 0.02 s sin importar el volumen.
- **El esquema cambia entre archivos y eso solo se descubre al leerlos.** La vista unificada falló con solo 2024 (`Referenced column "cbd_congestion_fee" not found`) hasta que se agregó la rama vacía con `UNION ALL BY NAME` (Ejercicio 5). Por la misma razón, la vista convierte los identificadores y códigos con `TRY_CAST`, para que un tipo distinto en un archivo no rompa la unión.
- **Información derivada que no está en el archivo.** El año y el mes se obtienen del nombre del archivo con una expresión regular en cada consulta. En la tabla quedan guardados.
- **Inmutable significa no corregible:** un registro erróneo no se puede arreglar en el Parquet, solo filtrar en las vistas (`viajes_validos`).

## 9.3 Ventajas y limitaciones de las tablas materializadas en DuckDB

**Ventajas:**
- **Consultas selectivas mucho más rápidas:** ×20 a ×66 en B7, con un tiempo que no crece con el volumen gracias a las estadísticas por bloque (*zone maps*) del formato nativo (Ejercicio 6).
- **Recorridos completos algo más rápidos:** ×1.4 a ×1.8 en las consultas con *join* o muchas agregaciones, porque se evita descomprimir Parquet.
- **Foto fija y trazable de los datos:** la tabla `origen` registra qué archivos contiene; varios procesos pueden leerla en `read_only`.
- **Se puede ir más allá de la tabla de viajes.** En el Ejercicio 7 se materializaron **los resultados de los indicadores** (`tablero.duckdb`, 5.8 MB) y no los viajes. Así el tablero de Metabase responde al instante, sin recorrer 121 M de filas en cada visita y sin competir por memoria con DuckDB. El Ejercicio 6 había recomendado conectar el tablero a `taxis.duckdb`, pero con 5.9 GB de RAM y Metabase compartiendo la máquina, ni siquiera ×1.8 hace interactiva una consulta de 15–50 s.

**Limitaciones:**
- **Es una copia que envejece.** No incluye los archivos descargados después de crearla, así que tras el Ejercicio 8 hay que volver a ejecutar `materializar.py` o `run_sql.py --tablero`. Si se olvida, el análisis queda desactualizado sin ningún error que lo avise. Por eso la tabla `indicadores` de `tablero.duckdb` guarda los años y la fecha con que se generó cada indicador.
- **Costo de creación y de espacio:** 79 s y ×1.7 el tamaño del Parquet para 72 M filas, y crece de forma lineal (~1.1 s por millón de filas). Solo se recupera después de ~5–6 rondas de consultas (Ejercicio 6).
- **No siempre es más rápida.** B2 y B3 fueron ×0.9 más lentas, porque con estadísticas exactas el optimizador eligió un plan peor (Ejercicio 6). Hay que medir.
- **Un solo escritor.** Mientras `run_sql.py --tablero` escribe en `tablero.duckdb`, Metabase no debería estar consultándolo. El flujo documentado detiene Metabase, regenera y vuelve a iniciar.
- **El cálculo no desaparece.** Con la tabla, las columnas derivadas y las banderas de calidad son el 70–75 % del tiempo. Materializar `viajes` no evita recalcularlas en cada consulta.

## 9.4 Ventajas frente a cargar todo con pandas

Se midió en la misma computadora y en el mismo momento en que DuckDB procesaba los tres años:

| Prueba | Resultado |
|---|---|
| `pd.read_parquet` de **un mes** de amarillos (`2025-05`, 4.6 M filas, 60 MB en disco) | **Falla:** `ArrowMemoryError: malloc of size 477551936 failed` |
| `pd.read_parquet` de enero de 2025 (3.5 M filas) | **Falla:** `malloc of size 361423552 failed` |
| `pd.read_parquet` de un mes de verdes (55 mil filas, 1.3 MB en disco) | 8.3 MiB en memoria: **157 bytes por fila**, ~6 veces su tamaño en Parquet |
| Extrapolación a los 121.2 M de registros | **~17.7 GiB**, tres veces la RAM total de la computadora |
| DuckDB sobre los 121.2 M de registros, límite de 2 GB | Las 12 consultas de indicadores terminan en 5.8 min |

Con pandas, el análisis completo no cabe en memoria. En esta máquina, ni siquiera cabe un mes. DuckDB hace el mismo trabajo con un límite de 2 GB.

Ventajas concretas del flujo DuckDB + Parquet + SQL:

1. **Memoria acotada y procesamiento fuera de memoria.** DuckDB lee solo las columnas necesarias, por bloques, y escribe a disco cuando no alcanza la memoria. Pandas carga cada archivo completo y sus operaciones (`groupby`, `merge`) crean copias intermedias.
2. **Velocidad.** DuckDB ejecuta en paralelo en todos los núcleos, con un motor vectorizado. Las operaciones de pandas usan un solo núcleo.
3. **Pandas sigue teniendo su lugar, pero al final del flujo.** Las consultas reducen 121 M de filas a resultados de 6 a 288 filas, y esos sí se pasan a pandas (`.df()`) para graficar en los notebooks. Cada herramienta se usa en lo que hace mejor.
4. **El SQL es la documentación.** Cada indicador es un archivo `.sql` con pregunta, justificación y fuente en el encabezado, que `run_sql.py` ejecuta y documenta. La misma consulta corre en Python, en la terminal de DuckDB y en Metabase. Un notebook de pandas mezclaría la lógica con el estado de las celdas.
5. **Reproducibilidad.** Las vistas definen la lógica una sola vez. En pandas, cada notebook repetiría la limpieza y podría divergir.

La desventaja: para transformaciones fila a fila complejas, modelos o gráficas, pandas (o Python en general) es más flexible que SQL. En este laboratorio no hizo falta.

## 9.5 ¿Qué características permiten incorporar datos con cambios mínimos?

Incorporar 2025 requirió **cambiar una línea**:

```python
ANIOS_POR_DEFECTO = (2024, 2025, 2026)      # scripts/download_data.py
```

No se modificó ninguna consulta (Ejercicio 8). Las 12 del Ejercicio 7, las 9 del 5 y las 2 del 6 corrieron sin cambios. De las 29 de los Ejercicios 3 y 4, 28 terminaron. La de duplicados (3.6g) se quedó sin memoria con 4 hilos y 2 GB; con 2 hilos y 1.5 GB terminó en 184 s (32,812 duplicados en 119.6 M de registros amarillos). Fue un límite de la máquina, no un error de la consulta. Las características que lo permiten:

1. **El año es un parámetro, no un valor fijo.** Desde el Ejercicio 2, URL, ruta de destino y descarga reciben el año.
2. **Descarga idempotente.** Un archivo que existe y es un Parquet válido (firma `PAR1`) se omite. La descarga se escribe en un `.part` y se renombra solo si el tamaño coincide con el publicado. 403/404 significa "no publicado" y un error de red significa "fallido". En el Ejercicio 8: 24 descargados, 40 omitidos e idénticos en SHA-256; una segunda ejecución da 0 descargados.
3. **Un directorio por tipo y año** (`data/raw/<tipo>/<anio>/`) y vistas con patrones *glob* (`*/*.parquet`): los archivos nuevos entran solos.
4. **`union_by_name` + columnas opcionales garantizadas** en la vista de origen: un año con columnas de más o de menos no rompe el esquema unificado.
5. **Capas de vistas.** El origen (`00_vistas.sql`) es la única capa que sabe dónde están los archivos. El análisis (`02_vistas_analisis.sql`) solo depende de `viajes`, así que la misma lógica funciona sobre Parquet o sobre la tabla materializada.
6. **Consultas que agrupan por año** (`anio_archivo`) y que calculan los **meses comunes** a partir de los datos (I12, 8.2, 8.5). Agregar un año agrega filas al resultado, no requiere reescribir la consulta.
7. **Todo se regenera con comandos:** `run_sql.py` para la documentación y los CSV, `--tablero` para las tablas del tablero, `tablero_metabase.py` para el tablero. El tablero pasó de 2 a 3 años sin tocar su definición.

**Lo que no se resuelve solo:** un cambio de significado. La regla de monto ≤ 0 excluye entre 4 % y 9.5 % de los amarillos de enero a noviembre de 2025 (Ejercicio 8, patrón 3), y ninguna consulta falló por eso. Detectarlo requirió revisar los indicadores de calidad por mes.

## 9.6 ¿Qué debería automatizarse en producción?

1. **Ingesta programada.** Ejecutar `download_data.py` + `verify_data.py` cada día o semana (cron, Airflow, GitHub Actions) para incorporar los meses que la TLC publica con semanas de atraso. Si `verify_data.py` devuelve código 1, enviar una alerta.
2. **Validación de esquema y de calidad como una puerta de entrada.** Comparar las columnas y los tipos de cada archivo nuevo con lo esperado (consultas 3.3 y 5.3) y calcular los indicadores de calidad (I11, 8.3) **antes** de publicar resultados. Alertar si la proporción de registros válidos cambia más de un umbral respecto a meses anteriores. Esto habría detectado en su momento la regla de duración en 2026 (proveedor 7) y la de monto en 2025 (proveedor 2, Flex Fare).
3. **Actualización incremental de la capa materializada:** insertar solo los archivos nuevos (`INSERT INTO viajes SELECT ... FROM read_parquet(nuevos)`, usando la tabla `origen` para saber cuáles faltan) en lugar de recrear todo.
4. **Regeneración del tablero.** Después de cada ingesta: `run_sql.py ejercicio7 --tablero` sobre una copia de `tablero.duckdb` que luego reemplaza a la anterior. Así Metabase nunca lee una base a medio escribir y no hace falta detenerlo.
5. **Pruebas de regresión de las consultas:** `compatibilidad.py` como prueba automática, que falle si una consulta deja de ejecutarse o si un resultado histórico cambia cuando no debía.
6. **Monitoreo del benchmark:** registrar los tiempos de cada consulta para detectar degradaciones, como el caso de 3.6e, que creció ×9.6 con ×2.4 de datos.

## 9.7 Decisiones de diseño importantes para la reproducibilidad

- **Ambiente fijo:** Docker con versiones exactas (`duckdb==1.5.5`, Metabase v0.63.19 con el driver 1.5.5.0, alineados entre sí), rutas relativas a la raíz del repositorio (`scripts/lab.py` cambia el directorio de trabajo) y `LAB8_DATA_DIR` para mover los datos sin cambiar código.
- **Datos fuera de Git pero verificables:** `.gitignore` excluye `data/`, y `manifest.csv` (URL, bytes, SHA-256 y fecha) y `verify_data.py` permiten comprobar que dos personas tienen los mismos archivos.
- **Todo el SQL en archivos, con metadatos.** Una consulta por archivo, con `@pregunta`, `@justificacion`, `@fuente`. `run_sql.py` genera la documentación (SQL, resultado y tiempo) y los CSV. Ninguna tabla de resultados se escribió a mano.
- **Resultados históricos reproducibles con `--anio`.** El Ejercicio 4 se reproduce con `--anio 2026` y el 7 con `--anio 2024 2026`, aunque haya más años descargados. Las salidas del Ejercicio 8 van a otra carpeta (`--salida`) y no sobrescriben las anteriores.
- **El tablero se define en código** (`tablero_metabase.py`) y no con clics: está en Git, se revisa en un *diff* y se reconstruye igual.
- **Funciones deterministas donde importa y aproximadas donde lo exige la memoria,** documentando cuál se usa (`approx_quantile`). `compatibilidad.py` distingue "igual", "aprox" y "distinto" por eso.
- **Las reglas de limpieza en un solo lugar** (`viajes_enriquecidos`). Marcan con banderas en lugar de borrar, así se puede medir su impacto (I11, 8.3).

## 9.8 ¿Qué se aprendió que no habría sido evidente con datos pequeños?

1. **La memoria es una restricción de diseño, no un detalle.** `median()` exacta, una CTE usada dos veces (3.6e, I3) o un `GROUP BY` casi único (3.6g) funcionan con un mes y agotan la memoria o se vuelven ×5–×10 más lentas con el conjunto completo. Con 1 mes, `median` y `approx_quantile` son indistinguibles; con 30 M filas, solo una termina.
2. **El costo no crece de forma uniforme.** Con ×2.4 datos, la mayoría de las consultas tardó ×1.5–×2.7, pero 3.6e tardó ×9.6 (Ejercicio 5). Probar con una muestra no predice el comportamiento con todo el volumen.
3. **Los problemas de calidad aparecen por bloques, no al azar.** Se concentran en un proveedor, un método de pago y un período. Entre enero y noviembre de 2025, entre 2.4 % y 8.3 % de los registros amarillos de cada mes son viajes Flex Fare del proveedor 2 con monto ≤ 0, y el problema desaparece en diciembre de 2025. En 2026, la regla de duración se dispara por el proveedor 7. Una muestra de un mes vería un problema o el otro, nunca el patrón. Y como los datos son masivos, nadie lo vería sin indicadores de calidad por mes.
4. **Con muchos datos casi cualquier diferencia es "significativa", así que la pregunta es si es comparable.** Comparar años completos con un año de 8 meses, o promedios de todo el período que mezclan años, da cifras precisas pero sin sentido (el "30.2 % paga cargo CBD" del Ejercicio 5). Hubo que diseñar las consultas con meses comunes, tasas por día y grupos de control (8.1).
5. **Un año más puede cambiar la conclusión.** Con 2024 y 2026, los amarillos "crecen 12 %" y la zona CBD "se volvió 7 % más lenta". Con 2025, se ve que todo el crecimiento ocurrió en 2025 y se detuvo en 2026, y que en 2025 la zona CBD no se hizo más lenta (incluso mejoró frente al resto de Manhattan). La caída es de 2026 y afecta también al resto de Manhattan (Ejercicio 8).
6. **El formato y la organización física importan tanto como la consulta.** El mismo SQL tarda 1.3 s o 0.02 s según si los datos están en 40 Parquet o en una tabla con *zone maps* (Ejercicio 6). Y un tablero puede ser instantáneo o inutilizable según si lee 121 M de filas o 200 filas preagregadas (Ejercicio 7).
7. **Los recursos del ambiente son parte del sistema.** Con 5.9 GB de RAM, Metabase y DuckDB no pueden calcular al mismo tiempo: al iniciar Metabase, las consultas fallaron con `Out of Memory Error: Allocation failure`. Hubo que limitar la memoria de DuckDB explícitamente (`LAB8_MEMORY_LIMIT`) y separar el momento de calcular del de visualizar.
