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
|   +-- download_data.py      descarga (Ejercicio 2)
|   +-- verify_data.py        verificacion de la descarga
|   +-- run_sql.py            ejecuta y documenta las consultas
|   +-- lab.py                utilidades compartidas
|   +-- verificar_ambiente.py
|
+-- sql/
|   +-- 00_vistas.sql         vistas sobre los Parquet
|   +-- 01_zonas.sql
|   +-- ejercicio3/
|   +-- ejercicio4/
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
   git clone https://github.com/<usuario>/duckdb.git
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
- Los anios por defecto estan en `ANIOS_POR_DEFECTO` dentro del script. Para
  otros anios: `python scripts/download_data.py --anio 2024 2025 2026`.
- Volver a ejecutar el script es seguro: solo descarga lo que falta o esta
  corrupto. Asi se incorporan los meses que la TLC publique despues.
- `verify_data.py` compara lo descargado con lo publicado por la TLC y deja el
  reporte en `docs/resultados/verificacion_descarga.md`. Termina con codigo 1
  si falta algo.

Cambios realizados al script y criterio de completitud:
[docs/ejercicio2_descarga.md](docs/ejercicio2_descarga.md).

## Como ejecutar el analisis

Las consultas viven en `sql/` (una por archivo, con objetivo y fuente en el
encabezado). `sql/00_vistas.sql` define las vistas `viajes`,
`viajes_enriquecidos`, `viajes_validos` y `zonas` sobre los Parquet.

```bash
# Ejercicio 3: exploracion directa de los Parquet
docker compose exec lab python scripts/run_sql.py ejercicio3

# Ejercicio 4: analisis exploratorio
docker compose exec lab python scripts/run_sql.py ejercicio4
```

Cada comando genera `docs/resultados/<ejercicio>.md` (SQL, resultado y tiempo
de cada consulta) y un CSV por consulta en `docs/resultados/<ejercicio>/`.

Notebooks (abrir en JupyterLab y ejecutar todas las celdas):

- `notebooks/ejercicio3_exploracion.ipynb`
- `notebooks/ejercicio4_analisis.ipynb` (guarda las figuras en `docs/figuras/`)

Documentacion e interpretacion:
[docs/ejercicio3_exploracion.md](docs/ejercicio3_exploracion.md),
[docs/ejercicio4_analisis.md](docs/ejercicio4_analisis.md).

## Como reproducir los benchmarks

<!-- TODO (Ejercicio 6) -->

## Como generar los resultados principales

<!-- TODO -->
