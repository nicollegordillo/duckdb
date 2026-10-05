# Ejercicio 1 - Preparación del ambiente

## Análisis de la estructura del proyecto

| Directorio / archivo | Propósito |
|---|---|
| `data/raw/` | Datos **tal como los publica la fuente** (Parquet de la TLC y catálogo de zonas), organizados como `data/raw/<tipo>/<anio>/`. Nunca se modifican: si algo sale mal, se pueden volver a descargar. Ignorado por Git. |
| `data/processed/` | Datos **derivados**: bases DuckDB materializadas (Ejercicio 6), temporales de DuckDB y cualquier salida intermedia. Se pueden regenerar desde `raw/` con los scripts. Ignorado por Git. |
| `notebooks/` | Exploración interactiva y visualización (JupyterLab). Ejecutan las consultas de `sql/` y generan figuras. |
| `scripts/` | Código reproducible por línea de comandos: descarga, verificación, ejecución de consultas y (más adelante) benchmarks. |
| `sql/` | Consultas SQL versionadas, una por archivo, con su objetivo y fuente en el encabezado. Es la "fuente de verdad" del análisis: notebooks y scripts las leen de aquí. |
| `docs/` | Documentación del equipo, resultados generados (`docs/resultados/`) y figuras (`docs/figuras/`). |
| `Dockerfile` | Imagen del servicio `lab`: Python 3.11 + DuckDB + JupyterLab + pandas/pyarrow/matplotlib, con versiones fijas (`requirements.txt`). |
| `metabase.Dockerfile` | Imagen de Metabase sobre Debian con el driver de DuckDB (la imagen oficial basada en Alpine no es compatible con la librería nativa del driver). |
| `docker-compose.yml` | Define y conecta los dos servicios, sus puertos y los volúmenes. |
| `.gitignore` | Garantiza que los datos (`data/raw/**`, `data/processed/**`) y las bases `.duckdb` no entren al repositorio. |

La separación `raw` / `processed` hace explícito qué es dato original y qué es resultado de una transformación, y la separación `sql` / `scripts` / `notebooks` evita que las consultas queden escondidas dentro de celdas de un notebook.

## 1.1 - 1.2 Fork, clonación y levantamiento

El procedimiento completo está en la sección **Cómo levantar el ambiente** del [README](../README.md).

## 1.3 Verificación de los servicios

| Verificación | Cómo | Resultado esperado |
|---|---|---|
| Contenedores en ejecución | `docker compose ps` | `lab8-lab` y `lab8-metabase` con estado `running` |
| JupyterLab | abrir <http://localhost:8888> | JupyterLab abre sin pedir token |
| Metabase | abrir <http://localhost:3000> | asistente de configuración inicial (la primera vez tarda ~1 min) |
| Librerías, DuckDB y Metabase desde el contenedor | `docker compose exec lab python scripts/verificar_ambiente.py` | todas las líneas `[OK]` y `Ambiente OK` |
| Montaje de datos | `docker compose exec lab ls /workspace/data` y `docker compose exec metabase ls /workspace/data` | `raw processed` en ambos |

Salida obtenida al ejecutar `verificar_ambiente.py`:

```text
Python
  [OK] 3.11.14 (Linux x86_64)
Librerias
  [OK] duckdb 1.5.5
  [OK] pandas 3.0.6
  [OK] pyarrow 25.0.1
  [OK] matplotlib 3.11.2
  [OK] requests 2.34.2
  [OK] jupyterlab 4.6.4
DuckDB
  [OK] escritura y lectura de Parquet (1000 filas)
  [OK] threads=16, memory_limit=5.9 GiB
Directorios del proyecto
  [OK] data/raw
  [OK] data/processed
  [OK] notebooks
  [OK] scripts
  [OK] sql
  [OK] docs
Metabase
  [OK] http://metabase:3000/api/health -> 200 {"status":"ok"}

Ambiente OK
```

## 1.4 Herramientas disponibles en el ambiente

| Herramienta | Versión | Dónde | Uso en el laboratorio |
|---|---|---|---|
| Python | 3.11.14 | `lab` | Lenguaje de los scripts y notebooks |
| DuckDB (Python) | 1.5.5 | `lab` | Motor SQL analítico embebido; consulta Parquet directamente |
| JupyterLab | 4.6.4 | `lab`, puerto 8888 | Notebooks de exploración |
| pandas | 3.0.6 | `lab` | Recibir resultados de DuckDB (`.df()`) para graficar |
| pyarrow | 25.0.1 | `lab` | Soporte Arrow/Parquet para pandas |
| matplotlib | 3.11.2 | `lab` | Gráficas de los notebooks |
| requests | 2.34.2 | `lab` | Descarga de archivos desde la TLC |
| curl | (sistema) | `lab` y `metabase` | Pruebas HTTP desde la terminal |
| Metabase | v0.63.19 | `metabase`, puerto 3000 | Tablero de indicadores (Ejercicio 7) |
| Driver DuckDB para Metabase | 1.5.5.0 | `metabase` | Permite que Metabase lea archivos `.duckdb` |
| Java (Temurin JRE) | 21 | `metabase` | Ejecuta Metabase |

Observaciones sobre la configuración:

- **Las versiones están fijadas** (imagen base `python:3.11.14-slim`, `requirements.txt` con `==`, `ARG` de Metabase y del driver). La versión de `duckdb` en Python coincide con la del driver de Metabase porque ambos deben poder abrir el mismo archivo `.duckdb`.
- **Los puertos solo escuchan en `127.0.0.1`.** JupyterLab corre sin token ni contraseña, lo cual solo es aceptable porque no queda expuesto a la red.
- **Solo se montan subcarpetas** (`data`, `notebooks`, `scripts`, `sql`, `docs`) en `/workspace`. Los cambios en esas carpetas se ven al instante dentro del contenedor; un cambio en `requirements.txt` o en el `Dockerfile` requiere `docker compose up --build`.
- Dentro de los contenedores los datos están en **`/workspace/data`**, que es la ruta que debe usar Metabase.
- La configuración de Metabase (usuario, preguntas, tableros) vive en el volumen `metabase-data`: sobrevive a `docker compose down`, pero se borra con `docker compose down -v`.
- Un archivo `.duckdb` solo admite un proceso con escritura a la vez: Metabase debe conectarse en modo solo lectura.

## 1.6 ¿Por qué es importante un ambiente reproducible?

En un proyecto de análisis el resultado depende del código **y** del ambiente en que corre. La misma consulta puede dar resultados distintos, o simplemente fallar, con otra versión de DuckDB (cambios en funciones, en la inferencia de tipos o en el formato del archivo `.duckdb`), con otra versión de pandas o con otro sistema operativo. Un ambiente definido como código (Dockerfile + versiones fijas + docker-compose) permite que:

1. **Cualquier persona obtenga los mismos resultados**: el docente o un compañero que clone el repositorio ejecuta exactamente el mismo software, sin "en mi máquina sí funciona".
2. **Los hallazgos sean verificables**: un número reportado puede volver a calcularse meses después.
3. **El ambiente sea desechable**: si algo se daña, se destruye y se reconstruye con un comando, sin pasos manuales no documentados.
4. **Las dependencias entre componentes queden explícitas**, como el requisito de que DuckDB y el driver de Metabase tengan la misma versión.
5. **Se separen código y datos**: el repositorio guarda cómo obtener y procesar los datos, no los datos en sí, que son grandes y se regeneran desde la fuente.
