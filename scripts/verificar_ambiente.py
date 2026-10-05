#!/usr/bin/env python3
"""Verifica que el ambiente del laboratorio funcione (Ejercicio 1.3 y 1.4).

    docker compose exec lab python scripts/verificar_ambiente.py

Revisa versiones de Python y librerias, ejecuta una consulta de prueba en
DuckDB (incluida la lectura/escritura de Parquet), comprueba que los
directorios montados existan y que Metabase responda.
"""

import importlib
import platform
import sys
import tempfile
from pathlib import Path

import requests

RAIZ = Path(__file__).resolve().parent.parent
PAQUETES = ("duckdb", "pandas", "pyarrow", "matplotlib", "requests", "jupyterlab")
URLS_METABASE = ("http://metabase:3000/api/health",    # desde el contenedor lab
                 "http://localhost:3000/api/health")   # desde la maquina anfitriona

ok = True


def linea(estado: bool, texto: str) -> None:
    global ok
    ok &= estado
    print(f"  [{'OK' if estado else 'FALLA'}] {texto}")


print("Python")
linea(True, f"{platform.python_version()} ({platform.system()} {platform.machine()})")

print("Librerias")
for nombre in PAQUETES:
    try:
        modulo = importlib.import_module(nombre)
        linea(True, f"{nombre} {getattr(modulo, '__version__', '?')}")
    except ImportError as error:
        linea(False, f"{nombre}: {error}")

print("DuckDB")
try:
    import duckdb
    con = duckdb.connect()
    with tempfile.TemporaryDirectory() as tmp:
        archivo = Path(tmp) / "prueba.parquet"
        con.execute(f"COPY (SELECT range AS x FROM range(1000)) TO '{archivo}' (FORMAT parquet)")
        n = con.execute(f"SELECT count(*) FROM read_parquet('{archivo}')").fetchone()[0]
    linea(n == 1000, f"escritura y lectura de Parquet ({n} filas)")
    hilos = con.execute("SELECT current_setting('threads')").fetchone()[0]
    memoria = con.execute("SELECT current_setting('memory_limit')").fetchone()[0]
    linea(True, f"threads={hilos}, memory_limit={memoria}")
except Exception as error:  # noqa: BLE001
    linea(False, f"DuckDB: {error}")

print("Directorios del proyecto")
for sub in ("data/raw", "data/processed", "notebooks", "scripts", "sql", "docs"):
    linea((RAIZ / sub).is_dir(), sub)

print("Metabase")
for url in URLS_METABASE:
    try:
        r = requests.get(url, timeout=5)
        linea(r.ok, f"{url} -> {r.status_code} {r.text.strip()[:60]}")
        break
    except requests.RequestException:
        print(f"  [--] {url} no accesible desde aqui")
else:
    linea(False, "Metabase no responde (puede tardar ~1 min en iniciar)")

print("\nAmbiente OK" if ok else "\nHay componentes con fallas")
sys.exit(0 if ok else 1)
