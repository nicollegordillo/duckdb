#!/usr/bin/env python3
"""Materializa los viajes en una base de datos DuckDB (Ejercicio 6.2).

Crea un archivo .duckdb con:
  - tabla `viajes`: copia del esquema unificado de amarillos y verdes
    (la vista `viajes` de sql/00_vistas.sql, con las mismas columnas y tipos);
  - tabla `zonas`: catalogo de zonas de la TLC;
  - tabla `origen`: archivos Parquet copiados y registros de cada uno;
  - vistas `viajes_enriquecidos` y `viajes_validos` (sql/02_vistas_analisis.sql)
    definidas sobre la tabla, de modo que las consultas de los Ejercicios 4 en
    adelante corren sin cambios sobre la base materializada.

A diferencia de las vistas sobre Parquet, la tabla es una COPIA: no incluye
archivos descargados despues de crearla; hay que volver a ejecutar el script.

Uso:
    python scripts/materializar.py                    # todos los anios descargados
    python scripts/materializar.py --anio 2026        # solo 2026
    python scripts/materializar.py --destino data/processed/otra.duckdb

Para consultarla (solo lectura, permite varios procesos a la vez):
    con = conectar("data/processed/taxis.duckdb", vistas=False, read_only=True)
"""

import argparse
import sys
import time
from pathlib import Path

import duckdb

from lab import DIR_SQL, RAIZ_REPO, RUTA_ZONAS, conectar, fijar_archivos

DESTINO = RAIZ_REPO / "data" / "processed" / "taxis.duckdb"


def materializar(destino=DESTINO, anios=None, yellow=None, green=None) -> dict:
    """Crea (o reemplaza) la base `destino` a partir de los Parquet.

    anios restringe los anios; yellow/green (listas de archivos) restringen los
    archivos exactos, como en los escenarios del benchmark. Devuelve filas,
    segundos de creacion y tamanio del archivo.
    """
    destino = Path(destino)
    if not destino.is_absolute():
        destino = RAIZ_REPO / destino
    destino.parent.mkdir(parents=True, exist_ok=True)
    for viejo in (destino, destino.with_name(destino.name + ".wal")):
        viejo.unlink(missing_ok=True)

    # 1. Copia de la vista `viajes` (lectura de los Parquet) a la tabla.
    con = conectar(anios=anios)
    if yellow is not None:
        fijar_archivos(con, yellow, green)
    inicio = time.perf_counter()
    con.execute(f"ATTACH '{destino.as_posix()}' AS mat")
    con.execute("CREATE TABLE mat.viajes AS SELECT * FROM viajes")
    segundos_viajes = time.perf_counter() - inicio
    if RUTA_ZONAS.exists():
        con.execute("CREATE TABLE mat.zonas AS SELECT * FROM zonas")
    con.execute("""
        CREATE TABLE mat.origen AS
        SELECT archivo, taxi, anio_archivo AS anio, mes_archivo AS mes,
               count(*) AS registros, current_timestamp AS materializado_en
        FROM mat.viajes
        GROUP BY ALL
        ORDER BY taxi DESC, anio, mes""")
    con.execute("DETACH mat")
    con.close()

    # 2. Vistas de analisis dentro de la base, sobre la tabla.
    con = duckdb.connect(str(destino))
    con.execute((DIR_SQL / "02_vistas_analisis.sql").read_text(encoding="utf-8"))
    filas = con.execute("SELECT count(*) FROM viajes").fetchone()[0]
    archivos = con.execute("SELECT count(*) FROM origen").fetchone()[0]
    con.execute("CHECKPOINT")
    con.close()
    segundos = time.perf_counter() - inicio
    return {"filas": filas, "archivos": archivos,
            "segundos_tabla": segundos_viajes, "segundos_total": segundos,
            "bytes": destino.stat().st_size}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--anio", type=int, nargs="+",
                        help="anios a materializar (por defecto: todos los descargados)")
    parser.add_argument("--destino", default=str(DESTINO.relative_to(RAIZ_REPO)),
                        help="archivo .duckdb a crear (se reemplaza si existe)")
    args = parser.parse_args()

    print(f"Materializando en {args.destino} ...")
    r = materializar(args.destino, anios=args.anio)
    print(f"  archivos Parquet copiados : {r['archivos']}")
    print(f"  filas en la tabla viajes  : {r['filas']:,}")
    print(f"  tiempo CREATE TABLE       : {r['segundos_tabla']:.1f} s")
    print(f"  tiempo total              : {r['segundos_total']:.1f} s")
    print(f"  tamanio del archivo       : {r['bytes'] / 2**20:,.1f} MiB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
