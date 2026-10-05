#!/usr/bin/env python3
"""Verifica que el conjunto de datos descargado este completo y sea legible.

Para cada tipo de taxi y anio revisa:
  1. que meses publica la TLC (HEAD al servidor) y cuales existen localmente;
  2. que el tamanio local coincida con el Content-Length publicado;
  3. que DuckDB pueda leer cada archivo (metadatos del footer Parquet);
  4. la cantidad de registros por archivo y el porcentaje de viajes cuya fecha
     de recogida cae dentro del mes que indica el nombre del archivo.

El resultado se imprime y se guarda en docs/resultados/verificacion_descarga.md.

Uso:
    python scripts/verify_data.py                  # anios por defecto
    python scripts/verify_data.py --anio 2024 2026
    python scripts/verify_data.py --offline        # sin consultar al servidor

Codigo de salida 0 si todo lo publicado esta descargado y es valido; 1 si no.
"""

import argparse
import datetime as dt
import sys
from pathlib import Path

import duckdb

from download_data import (ANIOS_POR_DEFECTO, RAIZ_REPO, TIPOS_TAXI,
                           ErrorConsulta, construir_url, consultar_publicacion,
                           es_parquet_valido, meses_posibles, ruta_destino,
                           ruta_relativa)

SALIDA = RAIZ_REPO / "docs" / "resultados" / "verificacion_descarga.md"
COLUMNA_PICKUP = {"yellow": "tpep_pickup_datetime", "green": "lpep_pickup_datetime"}


def revisar_archivo(con, tipo: str, anio: int, mes: int, ruta: Path) -> dict:
    """Lee el footer (conteo de filas) y escanea solo la columna de pickup."""
    meta = con.execute(
        "SELECT num_rows, num_row_groups FROM parquet_file_metadata(?)", [str(ruta)]
    ).fetchone()
    col = COLUMNA_PICKUP[tipo]
    inicio = dt.datetime(anio, mes, 1)
    fin = dt.datetime(anio + (mes == 12), mes % 12 + 1, 1)
    dentro, minimo, maximo = con.execute(
        f"""SELECT count(*) FILTER (WHERE {col} >= ? AND {col} < ?),
                   min({col}), max({col})
            FROM read_parquet(?)""",
        [inicio, fin, str(ruta)],
    ).fetchone()
    filas = meta[0]
    return {"filas": filas, "row_groups": meta[1],
            "pct_en_mes": 100.0 * dentro / filas if filas else 0.0,
            "min_pickup": minimo, "max_pickup": maximo}


def main() -> int:
    parser = argparse.ArgumentParser(description="Verifica la descarga de datos TLC.")
    parser.add_argument("--anio", type=int, nargs="+", default=list(ANIOS_POR_DEFECTO))
    parser.add_argument("--offline", action="store_true",
                        help="no consultar al servidor; solo validar archivos locales")
    args = parser.parse_args()

    con = duckdb.connect()
    filas_reporte, problemas = [], []
    totales = {}

    for anio in sorted(set(args.anio)):
        for tipo in TIPOS_TAXI:
            for mes in range(1, 13):
                etiqueta = f"{tipo} {anio}-{mes:02d}"
                ruta = ruta_destino(tipo, anio, mes)
                local = ruta.exists()

                # 1-2. Estado en el servidor
                if args.offline:
                    remoto, estado_remoto = None, "sin consultar"
                elif mes not in meses_posibles(anio):
                    remoto, estado_remoto = None, "mes no concluido"
                else:
                    try:
                        remoto = consultar_publicacion(construir_url(tipo, anio, mes))
                        estado_remoto = "publicado" if remoto is not None else "no publicado"
                    except ErrorConsulta as error:
                        remoto, estado_remoto = None, "error de consulta"
                        problemas.append(f"{etiqueta}: {error}")

                if not local:
                    if estado_remoto == "publicado":
                        problemas.append(f"{etiqueta}: publicado pero no descargado")
                        filas_reporte.append([etiqueta, estado_remoto, "FALTA", "", "", "", "", ""])
                    continue

                # 3-4. Validacion local
                tam = ruta.stat().st_size
                coincide = "-" if remoto in (None, -1) else ("si" if remoto == tam else "NO")
                if coincide == "NO":
                    problemas.append(f"{etiqueta}: tamanio local {tam} != publicado {remoto}")
                if not es_parquet_valido(ruta):
                    problemas.append(f"{etiqueta}: archivo corrupto (sin firma PAR1)")
                    filas_reporte.append([etiqueta, estado_remoto, "CORRUPTO", tam, coincide, "", "", ""])
                    continue
                try:
                    info = revisar_archivo(con, tipo, anio, mes, ruta)
                except duckdb.Error as error:
                    problemas.append(f"{etiqueta}: DuckDB no puede leerlo ({error})")
                    filas_reporte.append([etiqueta, estado_remoto, "ILEGIBLE", tam, coincide, "", "", ""])
                    continue

                clave = (tipo, anio)
                totales[clave] = totales.get(clave, 0) + info["filas"]
                filas_reporte.append([
                    etiqueta, estado_remoto, "ok", f"{tam:,}", coincide,
                    f"{info['filas']:,}", f"{info['pct_en_mes']:.3f}%",
                    f"{info['min_pickup']} / {info['max_pickup']}",
                ])

    encabezado = ["archivo", "servidor", "local", "bytes", "tamanio = publicado",
                  "registros", "% pickup en el mes", "pickup min / max"]
    lineas = [
        "# Verificacion de la descarga",
        "",
        f"Generado: {dt.datetime.now().isoformat(timespec='seconds')} "
        f"con `python scripts/verify_data.py{' --offline' if args.offline else ''}`",
        "",
        "| " + " | ".join(encabezado) + " |",
        "|" + "---|" * len(encabezado),
        *["| " + " | ".join(str(c) for c in fila) + " |" for fila in filas_reporte],
        "",
        "## Registros por tipo y anio",
        "",
        "| tipo | anio | archivos | registros |",
        "|---|---|---|---|",
    ]
    for (tipo, anio), total in sorted(totales.items()):
        n = sum(1 for f in filas_reporte if f[0].startswith(f"{tipo} {anio}") and f[2] == "ok")
        lineas.append(f"| {tipo} | {anio} | {n} | {total:,} |")
    lineas += ["", "## Veredicto", ""]
    lineas += ([f"- {p}" for p in problemas] if problemas
               else ["Completo: todos los meses publicados por la TLC estan descargados, "
                     "su tamanio coincide con el publicado y DuckDB puede leerlos."])

    texto = "\n".join(lineas) + "\n"
    SALIDA.parent.mkdir(parents=True, exist_ok=True)
    SALIDA.write_text(texto, encoding="utf-8")
    print(texto)
    print(f"Reporte guardado en {ruta_relativa(SALIDA)}")
    return 1 if problemas else 0


if __name__ == "__main__":
    sys.exit(main())
