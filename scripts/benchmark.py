#!/usr/bin/env python3
"""Benchmark: archivos Parquet vs. tabla materializada en DuckDB (Ejercicio 6).

Para cada escenario de volumen se ejecutan las MISMAS consultas (los mismos
archivos .sql) de dos formas:

  parquet  conexion en memoria con las vistas de sql/00_vistas.sql, que leen
           los Parquet del escenario en cada consulta (SET VARIABLE con la
           lista de archivos, ver scripts/lab.py:fijar_archivos).
  tabla    esos mismos archivos copiados a una base DuckDB
           (data/processed/benchmark/<escenario>.duckdb, con
           scripts/materializar.py) y abierta en solo lectura.

En ambos modos las consultas usan las mismas vistas de analisis
(sql/02_vistas_analisis.sql): lo unico que cambia es si `viajes` es una vista
sobre Parquet o una tabla. Para que la comparacion sea valida se comprueba que
ambos modos devuelvan el mismo resultado.

Medicion: cada consulta se ejecuta en una conexion nueva; la primera ejecucion
se registra aparte y luego se hacen N repeticiones (se reporta la mediana). El
tiempo incluye convertir el resultado a pandas (pocas filas). No se puede
vaciar la cache de archivos del sistema operativo dentro del contenedor, asi
que la "primera ejecucion" no es una lectura en frio desde disco.

Escenarios (todos incluyen enero de 2026, que usa la consulta B7):
  1m     2026-01
  3m     2026-01 a 2026-03
  2026   todos los meses publicados de 2026
  todos  todos los archivos descargados (2024 + 2026)

Salidas:
  docs/resultados/ejercicio6/tiempos.csv          una fila por ejecucion
  docs/resultados/ejercicio6/materializacion.csv  costo de crear cada tabla
  docs/resultados/ejercicio6/resumen.csv          mediana por consulta, escenario y modo
  docs/resultados/ejercicio6.md                   tablas + SQL de cada consulta

Uso:
  python scripts/benchmark.py                                  # completo
  python scripts/benchmark.py --escenarios 1m 3m --repeticiones 2
  python scripts/benchmark.py --conservar                      # no borrar las bases
"""

import argparse
import datetime as dt
import os
import platform
import re
import statistics
import sys
from pathlib import Path

import duckdb
import pandas as pd

from compatibilidad import comparar_df
from lab import (RAIZ_REPO, conectar, ejecutar_sql, fijar_archivos,
                 leer_metadatos, tabla_markdown)
from materializar import materializar

DIR_RAW = RAIZ_REPO / "data" / "raw"
DIR_BASES = RAIZ_REPO / "data" / "processed" / "benchmark"
DIR_SALIDA = RAIZ_REPO / "docs" / "resultados" / "ejercicio6"
REPORTE = RAIZ_REPO / "docs" / "resultados" / "ejercicio6.md"

# 6.3 Consultas representativas del analisis anterior (se usan los mismos
# archivos .sql, sin copiarlos ni modificarlos).
CONSULTAS = [
    ("B1", "sql/ejercicio6/6_01_conteo_por_tipo.sql"),
    ("B2", "sql/ejercicio4/4_01_viajes_por_mes.sql"),
    ("B3", "sql/ejercicio4/4_02_hora_dia_semana.sql"),
    ("B4", "sql/ejercicio4/4_03_caracteristicas_viaje.sql"),
    ("B5", "sql/ejercicio4/4_05_viajes_por_borough.sql"),
    ("B6", "sql/ejercicio4/4_09_impacto_reglas_calidad.sql"),
    ("B7", "sql/ejercicio6/6_02_filtro_selectivo.sql"),
]

ESCENARIOS = {
    "1m":    ("1 mes", lambda anio, mes: (anio, mes) == (2026, 1)),
    "3m":    ("3 meses", lambda anio, mes: anio == 2026 and mes <= 3),
    "2026":  ("2026", lambda anio, mes: anio == 2026),
    "todos": ("todos", lambda anio, mes: True),
}
MODOS = ("parquet", "tabla")
_PATRON = re.compile(r"_(\d{4})-(\d{2})\.parquet$")


def archivos_escenario(clave: str):
    """Rutas relativas (amarillos, verdes) de los Parquet del escenario."""
    filtro = ESCENARIOS[clave][1]
    salida = {}
    for tipo in ("yellow", "green"):
        rutas = []
        for ruta in sorted(DIR_RAW.glob(f"{tipo}/*/*.parquet")):
            m = _PATRON.search(ruta.name)
            if m and filtro(int(m.group(1)), int(m.group(2))):
                rutas.append(ruta.relative_to(RAIZ_REPO).as_posix())
        salida[tipo] = rutas
    return salida["yellow"], salida["green"]


def abrir(modo: str, yellow, green, base: Path):
    if modo == "parquet":
        con = conectar()
        fijar_archivos(con, yellow, green)
        return con
    return conectar(str(base), vistas=False, read_only=True)


def ambiente() -> dict:
    con = conectar(vistas=False)
    hilos, memoria = con.execute(
        "SELECT current_setting('threads'), current_setting('memory_limit')").fetchone()
    con.close()
    memoria_total = None
    try:
        with open("/proc/meminfo", encoding="utf-8") as f:
            memoria_total = f"{int(f.readline().split()[1]) / 2**20:.1f} GiB"
    except OSError:
        pass
    return {"duckdb": duckdb.__version__, "python": platform.python_version(),
            "sistema": platform.platform(), "cpus": os.cpu_count(),
            "memoria_total": memoria_total, "threads": hilos, "memory_limit": memoria}


def correr_escenario(clave, consultas, repeticiones, conservar):
    nombre = ESCENARIOS[clave][0]
    yellow, green = archivos_escenario(clave)
    if not yellow:
        raise SystemExit(f"Escenario {clave}: no hay archivos descargados")
    bytes_parquet = sum((RAIZ_REPO / r).stat().st_size for r in yellow + green)
    meses = len(yellow)
    base = DIR_BASES / f"{clave}.duckdb"

    print(f"\n=== Escenario {clave} ({nombre}): {meses} meses, "
          f"{len(yellow) + len(green)} archivos, {bytes_parquet / 2**20:,.0f} MiB Parquet ===")
    print("  materializando ...", end=" ", flush=True)
    m = materializar(base, yellow=yellow, green=green)
    print(f"{m['filas']:,} filas en {m['segundos_tabla']:.1f} s "
          f"({m['bytes'] / 2**20:,.0f} MiB)")
    mat = {"escenario": clave, "nombre": nombre, "meses": meses,
           "archivos": len(yellow) + len(green), "filas": m["filas"],
           "mib_parquet": round(bytes_parquet / 2**20, 1),
           "mib_duckdb": round(m["bytes"] / 2**20, 1),
           "segundos_crear_tabla": round(m["segundos_tabla"], 2),
           "segundos_total": round(m["segundos_total"], 2)}

    tiempos, validez = [], []
    for cid, ruta in consultas:
        resultados = {}
        for modo in MODOS:
            con = abrir(modo, yellow, green, base)
            for i in range(1 + repeticiones):
                _, df, seg = ejecutar_sql(con, ruta)
                tiempos.append({"escenario": clave, "filas_escenario": m["filas"],
                                "consulta": cid, "modo": modo, "ejecucion": i,
                                "primera": i == 0, "segundos": round(seg, 4),
                                "filas_resultado": len(df)})
            resultados[modo] = df
            con.close()
        mediana = {modo: statistics.median(t["segundos"] for t in tiempos
                                           if t["consulta"] == cid and t["modo"] == modo
                                           and not t["primera"])
                   for modo in MODOS} if repeticiones else {}
        igual = comparar_df(resultados["parquet"], resultados["tabla"])
        validez.append({"escenario": clave, "consulta": cid, "resultado_parquet_vs_tabla": igual})
        print(f"  {cid}: parquet {mediana.get('parquet', float('nan')):7.3f} s | "
              f"tabla {mediana.get('tabla', float('nan')):7.3f} s | resultados: {igual}")

    if not conservar:
        for archivo in (base, base.with_name(base.name + ".wal")):
            archivo.unlink(missing_ok=True)
    return mat, tiempos, validez


def resumir(tiempos: pd.DataFrame) -> pd.DataFrame:
    rep = tiempos[~tiempos.primera]
    prim = tiempos[tiempos.primera]
    claves = ["escenario", "filas_escenario", "consulta", "modo"]
    r = rep.groupby(claves).segundos.agg(mediana_s="median", min_s="min", max_s="max",
                                         repeticiones="count").reset_index()
    p = prim.groupby(claves).segundos.first().rename("primera_s").reset_index()
    return p.merge(r, on=claves, how="left")


def _seg(v) -> str:
    return "" if pd.isna(v) else f"{v:.3f}"


def escribir_reporte(amb, mat, resumen, validez, consultas, repeticiones) -> None:
    orden = [c for c in ESCENARIOS if c in set(mat.escenario)]
    mat = mat.set_index("escenario").loc[orden].reset_index()
    titulos = {cid: leer_metadatos((RAIZ_REPO / ruta).read_text(encoding="utf-8"))
               for cid, ruta in consultas}

    def tabla_tiempos(columna: str) -> list:
        enc = ["consulta"]
        for c in orden:
            enc += [f"{c}: parquet", f"{c}: tabla", f"{c}: parquet/tabla"]
        lineas = ["| " + " | ".join(enc) + " |", "|" + "---|" * len(enc)]
        for cid, ruta in consultas:
            celdas = [f"{cid} {titulos[cid].get('titulo', '')}"]
            for c in orden:
                v = resumen[(resumen.escenario == c) & (resumen.consulta == cid)].set_index("modo")[columna]
                p, t = v.get("parquet"), v.get("tabla")
                celdas += [_seg(p), _seg(t), "" if p is None or t is None or not t else f"{p / t:.1f}x"]
            lineas.append("| " + " | ".join(celdas) + " |")
        return lineas

    totales = (resumen.groupby(["escenario", "modo"]).mediana_s.sum().unstack("modo")
               .reindex(orden))
    equilibrio = mat.set_index("escenario")[["filas", "segundos_total"]].join(totales)
    equilibrio["ahorro_por_ronda_s"] = equilibrio.parquet - equilibrio.tabla
    equilibrio["rondas_para_amortizar"] = (equilibrio.segundos_total
                                           / equilibrio.ahorro_por_ronda_s).where(
                                               equilibrio.ahorro_por_ronda_s > 0)

    lineas = [
        "# Resultados del benchmark: Parquet vs. tabla DuckDB",
        "",
        f"Generado automaticamente el {dt.datetime.now().isoformat(timespec='seconds')} con "
        f"`python scripts/benchmark.py` ({repeticiones} repeticiones por consulta y modo, "
        "ademas de la primera ejecucion). No editar a mano.",
        "",
        "## Ambiente",
        "",
        "| " + " | ".join(amb) + " |",
        "|" + "---|" * len(amb),
        "| " + " | ".join(str(v) for v in amb.values()) + " |",
        "",
        "## Escenarios y costo de materializar",
        "",
        "`segundos_crear_tabla` = `CREATE TABLE viajes AS SELECT * FROM viajes` (lee los Parquet "
        "y escribe la tabla); `segundos_total` agrega zonas, la tabla `origen`, las vistas y el "
        "CHECKPOINT final.",
        "",
        tabla_markdown(mat),
        "",
        "## Tiempo por consulta (mediana de las repeticiones, segundos)",
        "",
        "`parquet/tabla` > 1 significa que la tabla materializada fue mas rapida.",
        "",
        *tabla_tiempos("mediana_s"),
        "",
        "## Tiempo de la primera ejecucion en una conexion nueva (segundos)",
        "",
        *tabla_tiempos("primera_s"),
        "",
        f"## Suma de las {len(consultas)} consultas y punto de equilibrio",
        "",
        "`rondas_para_amortizar` = segundos de materializar / segundos ahorrados por cada "
        "ejecucion del conjunto completo de consultas (medianas).",
        "",
        tabla_markdown(equilibrio.reset_index().round(2)),
        "",
        "## Validez: mismo resultado en ambos modos",
        "",
        "`aprox` = diferencias < 1 % por percentiles aproximados (approx_quantile).",
        "",
        tabla_markdown(validez.pivot(index="consulta", columns="escenario",
                                     values="resultado_parquet_vs_tabla")[orden].reset_index()),
        "",
        "## Consultas del benchmark",
        "",
    ]
    for cid, ruta in consultas:
        meta = titulos[cid]
        texto = (RAIZ_REPO / ruta).read_text(encoding="utf-8").strip()
        lineas += [f"### {cid} - {meta.get('titulo', '')}", "",
                   f"**Archivo:** `{ruta}` (id original: {meta.get('id', '')})  ", "",
                   "```sql", texto, "```", ""]
    REPORTE.write_text("\n".join(lineas), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--escenarios", nargs="+", choices=list(ESCENARIOS),
                        default=list(ESCENARIOS))
    parser.add_argument("--consultas", nargs="+", help="ids de consulta, p. ej. B1 B7")
    parser.add_argument("--repeticiones", type=int, default=3)
    parser.add_argument("--conservar", action="store_true",
                        help="no borrar las bases de data/processed/benchmark/")
    args = parser.parse_args()

    consultas = [c for c in CONSULTAS if not args.consultas or c[0] in args.consultas]
    amb = ambiente()
    print("Ambiente:", amb)
    DIR_SALIDA.mkdir(parents=True, exist_ok=True)

    mats, tiempos, validez = [], [], []
    for clave in args.escenarios:
        mat, t, v = correr_escenario(clave, consultas, args.repeticiones, args.conservar)
        mats.append(mat)
        tiempos += t
        validez += v
        # Se guarda despues de cada escenario para no perder lo medido.
        df_t = pd.DataFrame(tiempos)
        df_m, df_v = pd.DataFrame(mats), pd.DataFrame(validez)
        resumen = resumir(df_t)
        df_t.to_csv(DIR_SALIDA / "tiempos.csv", index=False)
        df_m.to_csv(DIR_SALIDA / "materializacion.csv", index=False)
        resumen.to_csv(DIR_SALIDA / "resumen.csv", index=False)
        df_v.to_csv(DIR_SALIDA / "validez.csv", index=False)
        escribir_reporte(amb, df_m, resumen, df_v, consultas, args.repeticiones)

    print(f"\nReporte: {REPORTE.relative_to(RAIZ_REPO)} (CSV en {DIR_SALIDA.relative_to(RAIZ_REPO)}/)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
