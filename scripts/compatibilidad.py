#!/usr/bin/env python3
"""Comprueba si las consultas de ejercicios anteriores siguen funcionando
cuando cambia el conjunto de archivos descargados (Ejercicio 5.7 y 8.3).

Ejecuta, sin modificarlas, todas las consultas de las carpetas indicadas sobre
TODOS los datos descargados en ese momento y registra para cada una:
  - si se ejecuto o fallo (y el error);
  - filas del resultado y tiempo de ejecucion;
  - si el resultado coincide con el documentado en docs/resultados/<carpeta>/
    (generado en su momento solo con 2026):
        igual               mismas filas, columnas y valores
        igual (otro orden)  mismas filas en otro orden (empates en ORDER BY)
        aprox               mismos valores con diferencias < 1 % (percentiles
                            aproximados)
        distinto            el resultado cambio (esperado si se agregaron
                            datos; con los mismos datos, solo en funciones no
                            deterministas: approx_quantile, SUMMARIZE, mode()
                            con empates, string_agg sin orden)

Uso (el nombre de la etapa describe los datos presentes al ejecutar):
    python scripts/compatibilidad.py --etapa 2026                 # antes de agregar 2024
    python scripts/compatibilidad.py --etapa 2024_2026 --guardar-csv

Cada ejecucion guarda docs/resultados/ejercicio5/compatibilidad_<etapa>.csv y
regenera el resumen de todas las etapas en docs/resultados/ejercicio5_compatibilidad.md.
"""

import argparse
import datetime as dt
import io
import sys

import duckdb
import numpy as np
import pandas as pd

from lab import DIR_SQL, RAIZ_REPO, conectar, ejecutar_sql

DIR_RESULTADOS = RAIZ_REPO / "docs" / "resultados"
DIR_SALIDA = DIR_RESULTADOS / "ejercicio5"
RESUMEN = DIR_RESULTADOS / "ejercicio5_compatibilidad.md"


def _numerica(serie: pd.Series):
    """La serie como numeros si todos sus valores no nulos lo son; si no, None."""
    if pd.api.types.is_numeric_dtype(serie):
        return serie.astype(float)
    convertida = pd.to_numeric(serie, errors="coerce")
    if convertida.isna().sum() == serie.isna().sum():
        return convertida.astype(float)
    return None


def comparar(df: pd.DataFrame, ruta_ref) -> str:
    """Compara un resultado con el CSV documentado (ida y vuelta por CSV para
    que los tipos sean comparables)."""
    if not ruta_ref.exists():
        return "sin referencia"
    return comparar_df(pd.read_csv(ruta_ref), df)


def comparar_df(ref: pd.DataFrame, df: pd.DataFrame) -> str:
    """Compara dos resultados (ida y vuelta por CSV para igualar tipos)."""
    ref = pd.read_csv(io.StringIO(ref.to_csv(index=False)))
    nuevo = pd.read_csv(io.StringIO(df.to_csv(index=False)))
    if list(ref.columns) != list(nuevo.columns) or len(ref) != len(nuevo):
        return "distinto"
    estado = _comparar_valores(ref, nuevo)
    if estado == "distinto":
        # Mismas filas en otro orden (empates en ORDER BY ... LIMIT)
        claves = list(ref.columns)
        orden = lambda d: d.astype(str).sort_values(claves).reset_index(drop=True)
        if _comparar_valores(orden(ref), orden(nuevo)) == "igual":
            return "igual (otro orden)"
    return estado


def _comparar_valores(ref: pd.DataFrame, nuevo: pd.DataFrame) -> str:
    estado = "igual"
    for col in ref.columns:
        a, b = _numerica(ref[col]), _numerica(nuevo[col])
        if a is not None and b is not None:
            if np.allclose(a, b, rtol=1e-9, atol=0, equal_nan=True):
                continue
            if np.allclose(a, b, rtol=0.01, atol=1e-6, equal_nan=True):
                estado = "aprox"
                continue
            return "distinto"
        if not (ref[col].fillna("<NULL>").astype(str)
                == nuevo[col].fillna("<NULL>").astype(str)).all():
            return "distinto"
    return estado


def archivos_presentes(con) -> pd.DataFrame:
    return con.execute("""
        SELECT regexp_extract(file, 'raw/(\\w+)/', 1) AS tipo,
               regexp_extract(file, 'raw/\\w+/(\\d{4})/', 1) AS anio,
               count(*) AS archivos
        FROM glob('data/raw/*/*/*.parquet') GROUP BY ALL ORDER BY ALL""").df()


def escribir_resumen() -> None:
    """Une los CSV de todas las etapas en una tabla Markdown. Las etapas se
    ordenan por cantidad de anios (2026, 2024_2026, 2024_2025_2026), que es el
    orden en que se incorporan en el laboratorio."""
    etapas = sorted(DIR_SALIDA.glob("compatibilidad_*.csv"),
                    key=lambda r: (len(r.stem.split("_")), r.stem))
    if not etapas:
        return
    tablas = {r.stem.removeprefix("compatibilidad_"): pd.read_csv(r) for r in etapas}
    nombres = list(tablas)
    base = tablas[nombres[0]][["carpeta", "consulta", "id"]]
    for nombre, t in tablas.items():
        t = t[["carpeta", "consulta", "estado", "filas", "segundos", "vs_documentado"]].rename(
            columns={c: f"{c}@{nombre}" for c in ("estado", "filas", "segundos", "vs_documentado")})
        base = base.merge(t, on=["carpeta", "consulta"], how="outer")

    encabezado = ["consulta", "id"]
    for n in nombres:
        encabezado += [f"{n}: estado", f"{n}: filas", f"{n}: s", f"{n}: vs. documentado"]
    lineas = [
        "# Compatibilidad de las consultas anteriores con el conjunto ampliado",
        "",
        f"Generado: {dt.datetime.now().isoformat(timespec='seconds')} con "
        "`python scripts/compatibilidad.py`. Cada etapa ejecuta las consultas **sin "
        "modificarlas** sobre todos los archivos descargados en ese momento.",
        "`vs. documentado` compara con `docs/resultados/<carpeta>/*.csv` (generados con 2026).",
        "",
        "| " + " | ".join(encabezado) + " |",
        "|" + "---|" * len(encabezado),
    ]
    for fila in base.itertuples(index=False):
        d = dict(zip(base.columns, fila))
        celdas = [f"`{d['carpeta']}/{d['consulta']}`", str(d["id"])]
        for n in nombres:
            seg = d[f"segundos@{n}"]
            filas = d[f"filas@{n}"]
            celdas += [str(d[f"estado@{n}"]),
                       "" if pd.isna(filas) else f"{int(filas):,}",
                       "" if pd.isna(seg) else f"{seg:.2f}",
                       str(d[f"vs_documentado@{n}"])]
        lineas.append("| " + " | ".join(celdas) + " |")
    lineas.append("")
    for n, t in tablas.items():
        ok = (t.estado == "ok").sum()
        lineas.append(f"- **{n}:** {ok} de {len(t)} consultas sin error; "
                      f"tiempo total {t.segundos.sum():.1f} s.")
    RESUMEN.write_text("\n".join(lineas) + "\n", encoding="utf-8")
    print(f"Resumen: {RESUMEN.relative_to(RAIZ_REPO)}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--etapa", required=True,
                        help="nombre de la etapa, p. ej. 2026 o 2024_2026")
    parser.add_argument("--carpetas", nargs="+", default=["ejercicio3", "ejercicio4"])
    parser.add_argument("--guardar-csv", action="store_true",
                        help="guardar cada resultado en docs/resultados/ejercicio5/resultados_<etapa>/")
    args = parser.parse_args()

    con = conectar()            # sin restringir anios: todo lo descargado
    print("Archivos presentes:")
    print(archivos_presentes(con).to_string(index=False))

    DIR_SALIDA.mkdir(parents=True, exist_ok=True)
    dir_csv = DIR_SALIDA / f"resultados_{args.etapa}"
    registros = []
    for carpeta in args.carpetas:
        for archivo in sorted((DIR_SQL / carpeta).glob("*.sql")):
            print(f"-> {carpeta}/{archivo.name} ... ", end="", flush=True)
            fila = {"carpeta": carpeta, "consulta": archivo.stem}
            try:
                meta, df, segundos = ejecutar_sql(con, archivo)
            except duckdb.Error as error:
                mensaje = str(error).splitlines()[0][:200]
                print(f"ERROR: {mensaje}")
                fila.update(id="", estado="error", error=mensaje, filas=None,
                            segundos=None, vs_documentado="")
                registros.append(fila)
                continue
            vs = comparar(df, DIR_RESULTADOS / carpeta / f"{archivo.stem}.csv")
            print(f"{len(df)} filas, {segundos:.2f} s, vs. documentado: {vs}")
            fila.update(id=meta.get("id", ""), estado="ok", error="", filas=len(df),
                        segundos=round(segundos, 3), vs_documentado=vs)
            registros.append(fila)
            if args.guardar_csv:
                (dir_csv / carpeta).mkdir(parents=True, exist_ok=True)
                df.to_csv(dir_csv / carpeta / f"{archivo.stem}.csv", index=False)

    salida = DIR_SALIDA / f"compatibilidad_{args.etapa}.csv"
    pd.DataFrame(registros).to_csv(salida, index=False)
    print(f"\nDetalle: {salida.relative_to(RAIZ_REPO)}")
    escribir_resumen()
    return 1 if any(r["estado"] == "error" for r in registros) else 0


if __name__ == "__main__":
    sys.exit(main())
