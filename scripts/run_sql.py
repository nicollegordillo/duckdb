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
"""

import argparse
import datetime as dt
import sys

import duckdb

from lab import DIR_SQL, RAIZ_REPO, conectar, ejecutar_sql, tabla_markdown

DIR_RESULTADOS = RAIZ_REPO / "docs" / "resultados"
CAMPOS = (("pregunta", "Pregunta"), ("objetivo", "Objetivo"),
          ("justificacion", "Justificacion"), ("fuente", "Fuente"))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("carpeta", help="subcarpeta de sql/, p. ej. ejercicio3")
    parser.add_argument("--solo", help="ejecutar solo los archivos que empiecen con este prefijo")
    parser.add_argument("--max-filas", type=int, default=40,
                        help="filas a mostrar en el Markdown (el CSV lleva todas)")
    args = parser.parse_args()

    carpeta = DIR_SQL / args.carpeta
    archivos = sorted(carpeta.glob("*.sql"))
    if args.solo:
        archivos = [a for a in archivos if a.name.startswith(args.solo)]
    if not archivos:
        print(f"No hay archivos .sql en {carpeta}")
        return 1

    con = conectar()
    dir_csv = DIR_RESULTADOS / args.carpeta
    dir_csv.mkdir(parents=True, exist_ok=True)

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
    salida = DIR_RESULTADOS / f"{args.carpeta}{sufijo}.md"
    encabezado = (
        f"# Resultados de sql/{args.carpeta}\n\n"
        f"Generado automaticamente el {dt.datetime.now().isoformat(timespec='seconds')} "
        f"con `python scripts/run_sql.py {args.carpeta}"
        f"{' --solo ' + args.solo if args.solo else ''}`.\n"
        f"No editar a mano: volver a ejecutar el script tras cambiar las consultas.\n\n"
        f"DuckDB {duckdb.__version__}\n\n"
    )
    salida.write_text(encabezado + "\n---\n\n".join(secciones), encoding="utf-8")
    print(f"\nDocumentacion: {salida.relative_to(RAIZ_REPO)}  (CSV en {dir_csv.relative_to(RAIZ_REPO)}/)")
    return 1 if errores else 0


if __name__ == "__main__":
    sys.exit(main())
