#!/usr/bin/env python3
"""Ejecuta las consultas de una carpeta de sql/ y documenta los resultados.

Cada archivo .sql lleva un encabezado con sus metadatos:

    -- @id: 3.2a
    -- @titulo: ...
    -- @objetivo: ...
    -- @fuente: ...

Por cada carpeta se genera:
    docs/resultados/<carpeta>.md         SQL + objetivo + fuente + resultado + tiempo
    docs/resultados/<carpeta>/<consulta>.csv   resultado completo de cada consulta

Uso:
    python scripts/run_sql.py ejercicio3
    python scripts/run_sql.py ejercicio4
    python scripts/run_sql.py ejercicio4 --solo 4_05     # una sola consulta
    python scripts/run_sql.py ejercicio4 --anio 2026     # vistas restringidas a 2026

--anio restringe los anios que leen las vistas (sql/00_vistas.sql). Las
consultas del Ejercicio 3 leen los Parquet directamente con read_parquet() y no
se ven afectadas: describen todos los archivos descargados.

--tablero (Ejercicio 7) ademas guarda el resultado de cada consulta que tenga
'-- @tabla: <nombre>' como tabla en data/processed/tablero.duckdb, la base
pequenia que lee el tablero de Metabase (scripts/tablero_metabase.py):

    python scripts/run_sql.py ejercicio7 --tablero
"""

import argparse
import datetime as dt
import sys
from pathlib import Path

import duckdb

from lab import DIR_SQL, RAIZ_REPO, conectar, ejecutar_sql, tabla_markdown

DIR_RESULTADOS = RAIZ_REPO / "docs" / "resultados"
TABLERO = RAIZ_REPO / "data" / "processed" / "tablero.duckdb"
CAMPOS = (("pregunta", "Pregunta"), ("objetivo", "Objetivo"),
          ("indicador", "Indicador"), ("justificacion", "Justificacion"),
          ("visualizacion", "Visualizacion"), ("fuente", "Fuente"))


def guardar_en_tablero(ruta, carpeta, archivo, meta, df, anios) -> None:
    """Guarda (reemplaza) el resultado como tabla meta['tabla'] en la base del
    tablero y registra de que consulta y con que anios se genero."""
    con = duckdb.connect(str(ruta))
    try:
        con.register("resultado", df)
        con.execute(f'CREATE OR REPLACE TABLE "{meta["tabla"]}" AS SELECT * FROM resultado')
        con.unregister("resultado")
        con.execute("""
            CREATE TABLE IF NOT EXISTS indicadores (
                tabla VARCHAR PRIMARY KEY, id VARCHAR, titulo VARCHAR,
                pregunta VARCHAR, consulta VARCHAR, filas INTEGER,
                anios VARCHAR, generado_en TIMESTAMP)""")
        con.execute("INSERT OR REPLACE INTO indicadores VALUES (?, ?, ?, ?, ?, ?, ?, current_localtimestamp())",
                    [meta["tabla"], meta.get("id"), meta.get("titulo"), meta.get("pregunta"),
                     f"sql/{carpeta}/{archivo.name}", len(df), anios])
    finally:
        con.close()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("carpeta", help="subcarpeta de sql/, p. ej. ejercicio3")
    parser.add_argument("--solo", help="ejecutar solo los archivos que empiecen con este prefijo")
    parser.add_argument("--max-filas", type=int, default=40,
                        help="filas a mostrar en el Markdown (el CSV lleva todas)")
    parser.add_argument("--anio", type=int, nargs="+",
                        help="anios que leen las vistas (por defecto: todos los descargados)")
    parser.add_argument("--salida",
                        help="nombre de la salida en docs/resultados/ (por defecto: la carpeta); "
                             "p. ej. ejercicio8/indicadores_3_anios")
    parser.add_argument("--tablero", nargs="?", const=str(TABLERO), metavar="BASE",
                        help="guardar los resultados con '@tabla' en la base del tablero "
                             f"(por defecto {TABLERO.relative_to(RAIZ_REPO).as_posix()})")
    args = parser.parse_args()

    carpeta = DIR_SQL / args.carpeta
    archivos = sorted(carpeta.glob("*.sql"))
    if args.solo:
        archivos = [a for a in archivos if a.name.startswith(args.solo)]
    if not archivos:
        print(f"No hay archivos .sql en {carpeta}")
        return 1

    con = conectar(anios=args.anio)
    nombre = args.salida or args.carpeta
    dir_csv = DIR_RESULTADOS / nombre
    dir_csv.mkdir(parents=True, exist_ok=True)
    if args.tablero:
        tablero = Path(args.tablero)
        tablero = tablero if tablero.is_absolute() else RAIZ_REPO / tablero
        tablero.parent.mkdir(parents=True, exist_ok=True)
        anios = args.anio or sorted(int(d.name) for d in (RAIZ_REPO / "data" / "raw" / "yellow").iterdir()
                                    if d.is_dir() and d.name.isdigit())
        anios = ", ".join(map(str, anios))

    secciones, errores = [], 0
    for archivo in archivos:
        texto = archivo.read_text(encoding="utf-8")
        print(f"-> {archivo.name} ... ", end="", flush=True)
        try:
            meta, df, segundos = ejecutar_sql(con, archivo)
        except duckdb.Error as error:
            errores += 1
            print("ERROR")
            secciones.append(f"## {archivo.stem}\n\n**ERROR:** `{error}`\n")
            continue
        print(f"{len(df)} filas, {segundos:.2f} s")
        df.to_csv(dir_csv / f"{archivo.stem}.csv", index=False)
        if args.tablero and "tabla" in meta:
            guardar_en_tablero(tablero, args.carpeta, archivo, meta, df, anios)

        partes = [f"## {meta.get('id', '')} - {meta.get('titulo', archivo.stem)}", ""]
        partes += [f"**{nombre}:** {meta[clave]}  " for clave, nombre in CAMPOS if clave in meta]
        partes += [
            f"**Archivo:** `sql/{args.carpeta}/{archivo.name}`  ",
            f"**Tiempo de ejecucion:** {segundos:.3f} s - **filas del resultado:** {len(df)}",
            "", "```sql", texto.strip(), "```", "", "**Resultado:**", "",
            tabla_markdown(df, args.max_filas), "",
        ]
        secciones.append("\n".join(partes))

    sufijo = f"_{args.solo}" if args.solo else ""
    salida = DIR_RESULTADOS / f"{nombre}{sufijo}.md"
    encabezado = (
        f"# Resultados de sql/{args.carpeta}\n\n"
        f"Generado automaticamente el {dt.datetime.now().isoformat(timespec='seconds')} "
        f"con `python scripts/run_sql.py {args.carpeta}"
        f"{' --solo ' + args.solo if args.solo else ''}"
        f"{' --anio ' + ' '.join(map(str, args.anio)) if args.anio else ''}"
        f"{' --salida ' + args.salida if args.salida else ''}"
        f"{' --tablero' if args.tablero else ''}`.\n"
        f"No editar a mano: volver a ejecutar el script tras cambiar las consultas.\n\n"
        f"DuckDB {duckdb.__version__}\n\n"
    )
    salida.write_text(encabezado + "\n---\n\n".join(secciones), encoding="utf-8")
    print(f"\nDocumentacion: {salida.relative_to(RAIZ_REPO)}  (CSV en {dir_csv.relative_to(RAIZ_REPO)}/)")
    return 1 if errores else 0


if __name__ == "__main__":
    sys.exit(main())
