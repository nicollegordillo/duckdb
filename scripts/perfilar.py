#!/usr/bin/env python3
"""Perfil de las consultas del benchmark: en que se va el tiempo (Ejercicio 6.9).

Para cada consulta y modo (Parquet / tabla materializada, con todos los datos)
registra:
  - el plan fisico: cuantas veces aparece cada operador (EXPLAIN);
  - la proporcion del tiempo de operadores que consume cada tipo de operador
    (profiler JSON de DuckDB, una ejecucion despues de una de calentamiento).

Sirve para explicar las diferencias del benchmark: si la lectura de datos es
una parte grande del tiempo, la tabla deberia ganar; si el plan cambia (p. ej.
la tabla se recorre dos veces), puede perder aunque cada lectura sea mas barata.

Requiere data/processed/taxis.duckdb (python scripts/materializar.py).

Uso:
    python scripts/perfilar.py                 # B2, B3, B5, B6
    python scripts/perfilar.py --consultas B3
Salida: docs/resultados/ejercicio6/perfil.md
"""

import argparse
import collections
import json
import re
import sys
import tempfile
from pathlib import Path

from benchmark import CONSULTAS, DIR_SALIDA
from lab import RAIZ_REPO, conectar, ejecutar_sql
from materializar import DESTINO

OPERADORES = ("SEQ_SCAN", "READ_PARQUET", "FILTER", "PROJECTION", "HASH_GROUP_BY",
              "HASH_JOIN", "WINDOW")


def operadores_plan(con, sql: str) -> dict:
    plan = con.execute("EXPLAIN " + sql).fetchall()[0][1]
    cuenta = {}
    for op in OPERADORES:
        # Cada caja del plan lleva el nombre del operador en su propia linea;
        # READ_PARQUET aparece dos veces por caja (titulo y "Function:").
        n = len(re.findall(r"│\s*" + op + r"\s*│", plan))
        if op == "READ_PARQUET":
            n //= 2
        if n:
            cuenta[op] = n
    return cuenta


def tiempo_por_operador(con, ruta) -> tuple:
    ejecutar_sql(con, ruta)                                   # calentamiento
    salida = Path(tempfile.gettempdir()) / "lab8_perfil.json"
    con.execute("SET enable_profiling = 'json'")
    con.execute(f"SET profiling_output = '{salida.as_posix()}'")
    _, _, segundos = ejecutar_sql(con, ruta)
    con.execute("SET enable_profiling = 'no_output'")
    arbol = json.loads(salida.read_text(encoding="utf-8"))
    tiempos = collections.Counter()

    def recorrer(nodo):
        tiempos[nodo.get("operator_type") or nodo.get("operator_name")] += nodo.get("operator_timing", 0)
        for hijo in nodo.get("children", []):
            recorrer(hijo)

    for hijo in arbol.get("children", []):
        recorrer(hijo)
    total = sum(tiempos.values()) or 1
    reparto = {op: 100 * t / total for op, t in tiempos.most_common() if 100 * t / total >= 1}
    return segundos, arbol.get("cpu_time", 0.0), reparto


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--consultas", nargs="+", default=["B2", "B3", "B5", "B6"])
    args = parser.parse_args()
    if not DESTINO.exists():
        raise SystemExit("Falta data/processed/taxis.duckdb: ejecutar scripts/materializar.py")

    filas = []
    for cid, ruta in CONSULTAS:
        if cid not in args.consultas:
            continue
        sql = (RAIZ_REPO / ruta).read_text(encoding="utf-8")
        for modo in ("parquet", "tabla"):
            con = (conectar() if modo == "parquet"
                   else conectar(str(DESTINO), vistas=False, read_only=True))
            plan = operadores_plan(con, sql)
            segundos, cpu, reparto = tiempo_por_operador(con, ruta)
            con.close()
            fila = (f"| {cid} | {modo} | {segundos:.2f} | {cpu:.1f} | "
                    + ", ".join(f"{k} x{v}" for k, v in plan.items()) + " | "
                    + ", ".join(f"{k} {v:.0f} %" for k, v in reparto.items()) + " |")
            print(fila)
            filas.append(fila)

    texto = "\n".join([
        "# Perfil de consultas del benchmark",
        "",
        "Generado con `python scripts/perfilar.py` sobre todos los datos descargados "
        "(vistas sobre Parquet vs. `data/processed/taxis.duckdb`). `cpu_s` es el tiempo de CPU "
        "sumado de todos los hilos. En el profiler, la lectura de Parquet aparece como TABLE_SCAN.",
        "",
        "| consulta | modo | segundos | cpu_s | operadores en el plan (EXPLAIN) | % del tiempo de operadores |",
        "|---|---|---|---|---|---|",
        *filas, "",
    ])
    salida = DIR_SALIDA / "perfil.md"
    salida.write_text(texto, encoding="utf-8")
    print(f"\n{salida.relative_to(RAIZ_REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
