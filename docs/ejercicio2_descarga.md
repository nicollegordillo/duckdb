# Ejercicio 2 - Sistema de descarga

## 2.1 Análisis del script proporcionado

El `scripts/download_data.py` original ya tenía una base sólida: recorría los 12 meses, hacía `HEAD` para saber si el archivo estaba publicado, descargaba por bloques sobre un archivo temporal `.part` que solo se renombraba al terminar, reintentaba hasta 3 veces y omitía los archivos que ya existían. Sin embargo, tenía estas limitaciones:

| # | Problema en el script original | Consecuencia |
|---|---|---|
| 1 | El año estaba fijo en la constante `ANIO = 2026` y en el nombre, la ruta y la documentación. | Incorporar 2024 y 2025 (Ejercicios 5 y 8) obligaba a editar el código o duplicar el script. |
| 2 | `esta_publicado()` devolvía `False` ante **cualquier** excepción de red. | Un corte de internet se reportaba como "aún no publicado por la TLC": el script terminaba sin error aunque faltaran meses. Es el problema más grave para garantizar que la descarga está completa. |
| 3 | Un archivo se consideraba válido solo con `tamaño > 0`. | Un archivo truncado o corrupto nunca se volvía a descargar. |
| 4 | No comparaba los bytes descargados contra el tamaño publicado (`Content-Length`). | Una descarga incompleta podía pasar como correcta. |
| 5 | La ruta `data/raw` era relativa al directorio actual. | Ejecutarlo desde `scripts/` creaba `scripts/data/raw/` y los datos quedaban fuera de la estructura del proyecto. |
| 6 | No dejaba registro de qué se descargó, de dónde y cuándo. | Sin trazabilidad para documentar o auditar la descarga. |
| 7 | Consultaba al servidor por meses que aún no han terminado. | Peticiones innecesarias (un mes en curso no puede estar publicado). |
| 8 | No descargaba el catálogo de zonas (`taxi_zone_lookup.csv`). | `PULocationID`/`DOLocationID` son números sin significado sin ese catálogo. |

## 2.2 - 2.4 Cambios realizados

| # | Cambio | Dónde |
|---|---|---|
| 1 | El año pasa a ser un parámetro: `--anio 2026 2024 ...`. Los años por defecto se definen en un solo lugar, `ANIOS_POR_DEFECTO`. Todas las funciones (`construir_nombre`, `construir_url`, `ruta_destino`, `descargar`) reciben el año. | `ANIOS_POR_DEFECTO`, `main()` |
| 2 | `consultar_publicacion()` distingue tres casos: publicado (200, devuelve `Content-Length`), no publicado (403/404; CloudFront responde 403 para objetos inexistentes) y **error** (cualquier otra respuesta o excepción, que se reporta como fallido y hace que el script termine con código 1). | `consultar_publicacion()`, `ErrorConsulta` |
| 3 | `es_parquet_valido()` comprueba la firma `PAR1` al inicio y al final del archivo (un Parquet truncado pierde el footer). Los archivos existentes válidos se omiten; los corruptos se reemplazan. | `es_parquet_valido()`, `descargar()` |
| 4 | La descarga se valida contra el `Content-Length` publicado y la firma Parquet **antes** de renombrar el `.part`. | `descargar_archivo()` |
| 5 | Las rutas se calculan desde la ubicación del script (`RAIZ_REPO`), así que funciona desde cualquier directorio, dentro o fuera del contenedor. | `RAIZ_REPO`, `DIR_DESTINO` |
| 6 | Cada archivo queda registrado en `data/raw/manifest.csv` con tipo, año, mes, URL, bytes, SHA-256 y fecha de descarga. | `registrar()`, `escribir_manifiesto()` |
| 7 | Los meses que aún no terminan se marcan como no publicados sin consultar al servidor. | `meses_posibles()` |
| 8 | Se descarga una vez el catálogo de zonas a `data/raw/zonas/` (se puede omitir con `--sin-zonas`). | `descargar_zonas()` |

Se agregó además `scripts/verify_data.py`, que comprueba que la descarga esté completa (ver 2.7).

Los archivos se guardan en la estructura del proyecto (2.3):

```text
data/raw/
├── manifest.csv
├── green/2026/green_tripdata_2026-01.parquet ...
├── yellow/2026/yellow_tripdata_2026-01.parquet ...
└── zonas/taxi_zone_lookup.csv
```

Con esta estructura, los Ejercicios 5 y 8 solo requieren descargar más años (`--anio 2024 2025 2026`, o agregarlos a `ANIOS_POR_DEFECTO`), sin modificar la lógica del script.

## 2.5 Ejecución

```bash
docker compose exec lab python scripts/download_data.py
docker compose exec lab python scripts/verify_data.py
```

Resumen de la primera ejecución:

```text
============================================================
RESUMEN
============================================================
  anios         : 2026
  descargados   : 16
  ya existian   : 0
  no publicados : 8
      yellow 2026-09, yellow 2026-10, yellow 2026-11, yellow 2026-12, green 2026-09, green 2026-10, green 2026-11, green 2026-12
  fallidos      : 0
  manifiesto    : data/raw/manifest.csv
============================================================
```

Resumen de una segunda ejecución:

```text
============================================================
RESUMEN
============================================================
  anios         : 2026
  descargados   : 0
  ya existian   : 16
  no publicados : 8
      yellow 2026-09, yellow 2026-10, yellow 2026-11, yellow 2026-12, green 2026-09, green 2026-10, green 2026-11, green 2026-12
  fallidos      : 0
  manifiesto    : data/raw/manifest.csv
============================================================
```

El reporte de verificación queda en [`docs/resultados/verificacion_descarga.md`](resultados/verificacion_descarga.md).

## 2.6 Registro de cambios

Ver la tabla de 2.2 - 2.4 y el historial de commits del archivo (`git log -p scripts/download_data.py`).

## 2.7 ¿Cómo se determinó que el conjunto de datos está completo?

"Completo" no significa 12 meses: la TLC publica cada mes con semanas de atraso, así que el conjunto esperado es **lo que la TLC tiene publicado hoy**. La verificación (`scripts/verify_data.py`) aplica cuatro criterios:

1. **Conjunto esperado = conjunto publicado.** Para cada tipo y cada mes que ya terminó se consulta al servidor (`HEAD`). Los meses con 200 son los esperados; con 403/404 aún no existen. Un error de red se reporta como problema, nunca como "no publicado".
2. **Todo lo publicado está descargado y no hay huecos.** Cada mes publicado debe existir localmente. La consulta 3.1 (`sql/ejercicio3/3_01_cantidad_archivos.sql`) confirma desde DuckDB que los meses son consecutivos.
3. **Cada archivo está íntegro.** El tamaño local coincide byte a byte con el `Content-Length` publicado, tiene la firma `PAR1` y DuckDB puede leer su footer (`parquet_file_metadata`). Además, el SHA-256 de cada archivo queda en el manifiesto.
4. **El contenido es coherente.** Cada archivo tiene un número de registros plausible y similar al de los otros meses, y prácticamente todos sus viajes tienen fecha de pickup dentro del mes que indica el nombre. La suma de registros por metadatos coincide con un `count(*)` completo (consultas 3.2a y 3.2b).

Resultado: 8 archivos amarillos y 8 verdes, meses 2026-01 a 2026-08; los meses 2026-08 en adelante aún no están publicados por la TLC; todos los tamaños coinciden. También se contrastó con la página oficial de la TLC, que lista los mismos meses para 2026.
