# Lab 8 - DuckDB

Repositorio base del laboratorio 8 del curso **CC3084 - Data Science**
(Universidad del Valle de Guatemala, Ciclo 2, 2026).

Este es el repositorio **proporcionado por el docente**. Contiene la estructura
del proyecto, el ambiente de ejecucion basado en Docker y un script que descarga
los datos de **2026**. Todo lo demas debe ser construido por cada equipo.

## Trabajo con fork

El laboratorio se desarrolla y se entrega sobre un **fork** de este repositorio.
No se trabaja directamente sobre el repositorio del docente.

1. Realice un fork de este repositorio:
   <https://github.com/menene/duckdb>

2. Clone **su propio fork** (no el del docente):

   ```bash
   git clone https://github.com/nicollegordillo/duckdb.git
   cd duckdb
   ```

3. Opcional, para recibir correcciones publicadas por el docente:

   ```bash
   git remote add upstream https://github.com/menene/duckdb.git
   git fetch upstream
   ```

Realice commits frecuentes y descriptivos: el historial del repositorio es parte
de la evaluacion. **La entrega del laboratorio es la URL de su fork.**

## Estructura

```text
duckdb/
|
+-- data/
|   +-- raw/
|   +-- processed/
|
+-- notebooks/
|
+-- scripts/
|   +-- download_data.py      descarga (Ejercicios 2 y 5)
|   +-- verify_data.py        verificacion de la descarga
|   +-- run_sql.py            ejecuta y documenta las consultas
|   +-- compatibilidad.py     consultas anteriores vs. datos ampliados (Ejercicio 5)
|   +-- materializar.py       tabla DuckDB a partir de los Parquet (Ejercicio 6)
|   +-- benchmark.py          Parquet vs. tabla materializada (Ejercicio 6)
|   +-- perfilar.py           planes y tiempo por operador del benchmark
|   +-- lab.py                utilidades compartidas
|   +-- verificar_ambiente.py
|
+-- sql/
|   +-- 00_vistas.sql         origen: vistas sobre los Parquet (viajes)
|   +-- 01_zonas.sql
|   +-- 02_vistas_analisis.sql  viajes_enriquecidos, viajes_validos
|   +-- ejercicio3/ ... ejercicio6/
|
+-- docs/
|
+-- Dockerfile
+-- metabase.Dockerfile
+-- docker-compose.yml
+-- README.md
```

## Requisitos

- Docker, con Docker Compose
- Git

La primera construccion del ambiente descarga varios cientos de MB y puede
tardar algunos minutos.

Considere el espacio en disco: las imagenes de Docker ocupan unos 3 GB y los
datos de los tres anios del laboratorio superan 1.5 GB, a los que se suma la
base materializada del Ejercicio 6. Se recomienda tener al menos 10 GB libres.

## Datos

El repositorio incluye `scripts/download_data.py`, que descarga los archivos de
2026 publicados por la TLC (`--help` muestra las opciones disponibles). Los
archivos se guardan en `data/raw/<tipo>/<anio>/`.

La TLC publica cada mes con varias semanas de atraso, por lo que los ultimos
meses de 2026 todavia no existen. El script consulta al servidor que meses estan
publicados, de modo que vuelve a ejecutarse sin problema conforme aparezcan
nuevos archivos.

Los datos descargados **no deben incluirse en el repositorio Git**. El archivo
`.gitignore` ya esta configurado para evitarlo.

Fuente de datos: NYC TLC Trip Record Data
<https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page>

Dentro de los contenedores, la carpeta `data/` del proyecto esta montada en
`/workspace/data`. Esa es la ruta que deben usar las herramientas que corren
dentro del ambiente, no la ruta de su computadora.

> **Nota sobre DuckDB:** un archivo `.duckdb` admite un solo proceso con permiso
> de escritura a la vez. Si conecta una herramienta externa a su base de datos,
> use el modo de solo lectura (`read_only`) en esa conexion; de lo contrario los
> demas procesos no podran abrir el archivo.

## Material a entregar

Al finalizar, su fork debe contener:

- el codigo fuente modificado y los scripts de descarga;
- las consultas SQL desarrolladas;
- el notebook o notebooks utilizados;
- la documentacion de las consultas;
- los scripts utilizados para los benchmarks;
- el codigo de los indicadores y visualizaciones;
- el tablero o la evidencia del tablero desarrollado;
- este `README.md`, completado segun la siguiente seccion.

Los archivos de datos descargados **no** deben incluirse.

---

# Documentacion del equipo

Las siguientes secciones deben ser completadas por cada equipo. El README final
debe permitir que una persona que no participo en el desarrollo pueda levantar el
ambiente, descargar los datos, ejecutar el analisis, reproducir los benchmarks y
generar los resultados principales.

## Como levantar el ambiente

Requisitos: Docker (con Docker Compose), Git y al menos 10 GB libres.

1. Clonar el fork del equipo y entrar a la carpeta:

   ```bash
   git clone https://github.com/nicollegordillo/duckdb.git
   cd duckdb
   ```

2. Construir las imagenes y levantar los servicios en segundo plano (la
   primera vez tarda varios minutos):

   ```bash
   docker compose up --build -d
   ```

3. Comprobar que ambos contenedores esten corriendo:

   ```bash
   docker compose ps          # lab8-lab y lab8-metabase deben aparecer "running"
   ```

4. Verificar librerias, DuckDB, directorios y Metabase:

   ```bash
   docker compose exec lab python scripts/verificar_ambiente.py
   ```

5. Abrir los servicios:
   - JupyterLab: <http://localhost:8888> (sin token)
   - Metabase: <http://localhost:3000> (la primera vez pide crear un usuario;
     tarda alrededor de un minuto en iniciar)

Para detener el ambiente: `docker compose down` (la configuracion de Metabase
se conserva; `docker compose down -v` la borra).

**Datos fuera del repositorio (opcional).** Si el repositorio esta en una
carpeta sincronizada (OneDrive, Dropbox), los varios GB de datos y bases DuckDB
se subirian a la nube. Para guardarlos en otra carpeta, cree un archivo `.env`
junto a `docker-compose.yml` (ignorado por Git) antes de `docker compose up`:

```bash
LAB8_DATA_DIR=C:/Users/<usuario>/lab8-data
```

Por defecto se usa `./data`. En ambos casos, dentro de los contenedores los
datos estan en `/workspace/data` y los scripts no cambian.

Todos los comandos de este README se ejecutan desde la raiz del repositorio en
la maquina anfitriona; `docker compose exec lab ...` los corre dentro del
contenedor, donde el proyecto esta en `/workspace`.

Detalle del ambiente, herramientas disponibles y justificacion:
[docs/ejercicio1_ambiente.md](docs/ejercicio1_ambiente.md).

## Como descargar los datos

```bash
# 1. Descargar los Parquet de taxis amarillos y verdes + catalogo de zonas
docker compose exec lab python scripts/download_data.py

# 2. Verificar que la descarga este completa
docker compose exec lab python scripts/verify_data.py
```

- Los archivos quedan en `data/raw/<tipo>/<anio>/` y el catalogo de zonas en
  `data/raw/zonas/`. Cada descarga se registra en `data/raw/manifest.csv`.
- Los anios por defecto estan en `ANIOS_POR_DEFECTO` dentro del script:
  **2024 y 2026** desde el Ejercicio 5 (unos 1.2 GB, 40 archivos). Para otros
  anios: `python scripts/download_data.py --anio 2024 2025 2026`.
- Volver a ejecutar el script es seguro: solo descarga lo que falta o esta
  corrupto. Asi se incorporan los meses que la TLC publique despues.
- `verify_data.py` compara lo descargado con lo publicado por la TLC y deja el
  reporte en `docs/resultados/verificacion_descarga.md`. Termina con codigo 1
  si falta algo.

Cambios realizados al script y criterio de completitud:
[docs/ejercicio2_descarga.md](docs/ejercicio2_descarga.md).

## Como ejecutar el analisis

Las consultas viven en `sql/` (una por archivo, con objetivo y fuente en el
encabezado). Las vistas se crean en dos capas:

- `sql/00_vistas.sql` (origen): `yellow_raw`, `green_raw` y el esquema
  unificado `viajes`, que leen todos los Parquet descargados;
- `sql/01_zonas.sql`: `zonas`;
- `sql/02_vistas_analisis.sql` (analisis): `viajes_enriquecidos` y
  `viajes_validos`, que solo dependen de `viajes` (vista o tabla).

```bash
# Ejercicio 3: exploracion directa de los Parquet
docker compose exec lab python scripts/run_sql.py ejercicio3

# Ejercicio 4: analisis exploratorio (documentado con 2026)
docker compose exec lab python scripts/run_sql.py ejercicio4 --anio 2026

# Ejercicio 5: validacion de la incorporacion de 2024
docker compose exec lab python scripts/run_sql.py ejercicio5
docker compose exec lab python scripts/compatibilidad.py --etapa 2024_2026 --guardar-csv
```

Cada `run_sql.py` genera `docs/resultados/<ejercicio>.md` (SQL, resultado y
tiempo de cada consulta) y un CSV por consulta en `docs/resultados/<ejercicio>/`.

**Anios que leen las vistas.** Por defecto, todos los descargados. `--anio`
(o la variable de entorno `LAB8_ANIOS=2026`) restringe las vistas a esos anios;
asi se reproducen los resultados del Ejercicio 4, que se escribieron cuando
solo existia 2026, aunque haya mas anios descargados. Las consultas del
Ejercicio 3 leen los Parquet con `read_parquet()` y describen todo lo
descargado: sus resultados documentados corresponden a una descarga de solo
2026 (`download_data.py --anio 2026`).

Notebooks (abrir en JupyterLab y ejecutar todas las celdas, o desde la terminal
con `docker compose exec lab jupyter nbconvert --to notebook --execute --inplace <notebook>`):

- `notebooks/ejercicio3_exploracion.ipynb`
- `notebooks/ejercicio4_analisis.ipynb`: grafica los CSV generados por
  `run_sql.py ejercicio4` (si falta uno, ejecuta la consulta) y guarda las
  figuras en `docs/figuras/`. Por eso se ejecuta **despues** de `run_sql.py`.
- `notebooks/ejercicio5_incorporacion.ipynb`: grafica los CSV de
  `run_sql.py ejercicio5` y `compatibilidad.py`.
- `notebooks/ejercicio6_benchmark.ipynb`: grafica los CSV de `benchmark.py`.

### Memoria

Las consultas procesan unos 30 millones de registros. `scripts/lab.py` limita
DuckDB al 60 % de la memoria disponible en el contenedor y usa
`data/processed/duckdb_tmp/` para temporales. Si aun asi aparece
`Cannot allocate memory` o el proceso termina sin mensaje:

- detener Metabase mientras se ejecutan las consultas (`docker compose stop metabase`)
  y cerrar los kernels abiertos de JupyterLab;
- reducir hilos y memoria con variables de entorno, por ejemplo:
  `docker compose exec -e LAB8_THREADS=2 -e LAB8_MEMORY_LIMIT=2GB lab python scripts/run_sql.py ejercicio4`;
- en Windows, mantener el repositorio fuera de carpetas sincronizadas como
  OneDrive y, si se mueve de carpeta, recrear los contenedores
  (`docker compose down` y `docker compose up -d`): `restart` conserva los
  montajes de la ubicacion anterior.

Documentacion e interpretacion:
[docs/ejercicio3_exploracion.md](docs/ejercicio3_exploracion.md),
[docs/ejercicio4_analisis.md](docs/ejercicio4_analisis.md),
[docs/ejercicio5_incorporacion.md](docs/ejercicio5_incorporacion.md).

## Como reproducir los benchmarks

Ejercicio 6: las mismas consultas sobre los Parquet y sobre una tabla DuckDB.

```bash
# Tabla materializada con todos los anios descargados (6.2)
# -> data/processed/taxis.duckdb: tabla viajes + zonas + origen + vistas de analisis
docker compose exec lab python scripts/materializar.py

# Benchmark completo: 4 volumenes x 7 consultas x 2 modos (unos 30 minutos)
docker compose stop metabase        # recomendado: libera memoria y CPU
docker compose exec lab python scripts/benchmark.py

# Perfil de operadores y planes (explica las diferencias; usa taxis.duckdb)
docker compose exec lab python scripts/perfilar.py
```

- El benchmark crea una base por escenario en `data/processed/benchmark/` y la
  borra al terminar (`--conservar` para mantenerlas). Requiere unos 6 GB libres
  durante la ejecucion.
- Escenarios: `1m` (2026-01), `3m` (2026-01 a 03), `2026` y `todos` (todos
  los anios descargados). Opciones: `--escenarios 1m 3m`, `--consultas B1 B7`,
  `--repeticiones 5`.
- Salidas: `docs/resultados/ejercicio6.md` (tablas y SQL de cada consulta) y
  `docs/resultados/ejercicio6/*.csv`. Las figuras se generan con
  `notebooks/ejercicio6_benchmark.ipynb`.
- Los tiempos dependen de la maquina; los del reporte se midieron con Docker
  Desktop (WSL2) en Windows, 8 CPU y 7.6 GiB para el contenedor.

Para consultar la base materializada desde Python (solo lectura, varios
procesos a la vez):

```python
from lab import conectar
con = conectar("data/processed/taxis.duckdb", vistas=False, read_only=True)
```

Analisis: [docs/ejercicio6_benchmark.md](docs/ejercicio6_benchmark.md).

## Como generar los resultados principales

Secuencia completa, desde un clon limpio, para los Ejercicios 1 a 6. El orden
importa: los Ejercicios 3 y 4 se documentaron cuando solo existia 2026, por eso
se ejecutan antes de descargar 2024 (el 4 se puede repetir despues con
`--anio 2026`).

```bash
docker compose up --build -d
docker compose exec lab python scripts/verificar_ambiente.py

# Ejercicios 2-4: solo 2026
docker compose exec lab python scripts/download_data.py --anio 2026
docker compose exec lab python scripts/run_sql.py ejercicio3
docker compose exec lab python scripts/run_sql.py ejercicio4
docker compose exec lab python scripts/compatibilidad.py --etapa 2026      # linea base del 5.7
docker compose exec lab jupyter nbconvert --to notebook --execute --inplace notebooks/ejercicio3_exploracion.ipynb
docker compose exec lab jupyter nbconvert --to notebook --execute --inplace notebooks/ejercicio4_analisis.ipynb

# Ejercicio 5: se agrega 2024 (ANIOS_POR_DEFECTO = 2024, 2026)
docker compose exec lab python scripts/download_data.py
docker compose exec lab python scripts/verify_data.py
docker compose exec lab python scripts/run_sql.py ejercicio5
docker compose exec lab python scripts/compatibilidad.py --etapa 2024_2026 --guardar-csv
docker compose exec lab jupyter nbconvert --to notebook --execute --inplace notebooks/ejercicio5_incorporacion.ipynb

# Ejercicio 6: tabla materializada y benchmark
docker compose stop metabase
docker compose exec lab python scripts/materializar.py
docker compose exec lab python scripts/benchmark.py
docker compose exec lab python scripts/perfilar.py
docker compose exec lab jupyter nbconvert --to notebook --execute --inplace notebooks/ejercicio6_benchmark.ipynb
```

| Resultado | Archivo |
|---|---|
| Verificacion de la descarga | `docs/resultados/verificacion_descarga.md` |
| Consultas, resultados y tiempos | `docs/resultados/ejercicio3.md` a `docs/resultados/ejercicio5.md` (+ CSV) |
| Compatibilidad de las consultas al agregar 2024 | `docs/resultados/ejercicio5_compatibilidad.md` |
| Benchmark Parquet vs. tabla | `docs/resultados/ejercicio6.md` (+ CSV) |
| Figuras | `docs/figuras/` |
| Respuestas e interpretacion | `docs/ejercicio1_ambiente.md` a `docs/ejercicio6_benchmark.md` |

<!-- Pendiente: agregar Ejercicios 7 a 9. -->
