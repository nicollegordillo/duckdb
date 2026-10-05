#!/usr/bin/env python3
"""Descarga los archivos Parquet del NYC TLC Trip Record Data.

Descarga los registros de viajes de taxis amarillos (yellow) y verdes (green)
para uno o varios anios, ademas de la tabla de zonas de taxi (taxi_zone_lookup),
que se usa como catalogo de referencia en el analisis.

Fuente oficial de los datos:
    https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page

Uso:
    python scripts/download_data.py                        # anios de ANIOS_POR_DEFECTO
    python scripts/download_data.py --anio 2026 2024       # varios anios
    python scripts/download_data.py --taxi green --anio 2026

Los archivos se guardan en:
    data/raw/<tipo>/<anio>/<nombre-original>.parquet
    data/raw/zonas/taxi_zone_lookup.csv

y cada descarga queda registrada en data/raw/manifest.csv (archivo, URL,
tamanio, sha256 y fecha de descarga).

Comportamiento:
  - La TLC publica cada mes con varias semanas de atraso, por lo que no todos
    los meses del anio en curso existen todavia. El script consulta al servidor
    que meses estan publicados en lugar de suponerlos. Los meses que aun no han
    ocurrido no se consultan.
  - Un error de red NO se confunde con "no publicado": solo las respuestas
    403/404 se interpretan como archivo inexistente.
  - Un archivo que ya existe localmente y es un Parquet valido no se vuelve a
    descargar. Si esta vacio o corrupto (sin la firma PAR1), se reemplaza.
  - La descarga se hace sobre un nombre temporal, se compara el tamanio con el
    Content-Length del servidor y solo entonces se renombra, de modo que una
    interrupcion no deja archivos .parquet a medias.
  - Las rutas se resuelven respecto a la raiz del repositorio, por lo que el
    script funciona igual sin importar desde que directorio se ejecute.
"""

import argparse
import csv
import datetime as dt
import hashlib
import sys
from pathlib import Path

import requests

# --- Configuracion -----------------------------------------------------------
# Para incorporar un anio nuevo basta con agregarlo aqui (o pasarlo con --anio).
ANIOS_POR_DEFECTO = (2026,)
TIPOS_TAXI = ("yellow", "green")

URL_BASE = "https://d37ci6vzurychx.cloudfront.net/trip-data"
URL_ZONAS = "https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv"

RAIZ_REPO = Path(__file__).resolve().parent.parent
DIR_DESTINO = RAIZ_REPO / "data" / "raw"
RUTA_ZONAS = DIR_DESTINO / "zonas" / "taxi_zone_lookup.csv"
RUTA_MANIFIESTO = DIR_DESTINO / "manifest.csv"

TIEMPO_ESPERA = 60          # segundos por peticion
INTENTOS = 3                # intentos por archivo antes de darse por vencido
BLOQUE = 1024 * 1024        # 1 MiB por bloque de descarga
SUFIJO_TEMPORAL = ".part"
FIRMA_PARQUET = b"PAR1"     # los Parquet empiezan y terminan con estos 4 bytes
CODIGOS_NO_PUBLICADO = (403, 404)  # CloudFront/S3 responde 403 si no existe

CAMPOS_MANIFIESTO = ("tipo", "anio", "mes", "archivo", "url", "bytes",
                     "sha256", "descargado_en")


class ErrorConsulta(Exception):
    """El servidor no pudo consultarse (distinto de 'archivo no publicado')."""


# --- Nombres y rutas ---------------------------------------------------------
def construir_nombre(tipo: str, anio: int, mes: int) -> str:
    """Nombre del archivo publicado por la TLC, p. ej. yellow_tripdata_2026-01.parquet."""
    return f"{tipo}_tripdata_{anio}-{mes:02d}.parquet"


def construir_url(tipo: str, anio: int, mes: int) -> str:
    """URL completa del archivo Parquet mensual."""
    return f"{URL_BASE}/{construir_nombre(tipo, anio, mes)}"


def ruta_destino(tipo: str, anio: int, mes: int) -> Path:
    """Ruta local donde se guarda el archivo."""
    return DIR_DESTINO / tipo / str(anio) / construir_nombre(tipo, anio, mes)


def ruta_relativa(ruta: Path) -> str:
    try:
        return str(ruta.relative_to(RAIZ_REPO))
    except ValueError:
        return str(ruta)


def meses_posibles(anio: int, hoy: dt.date | None = None) -> range:
    """Meses que pueden existir: un mes que aun no termina no puede estar publicado."""
    hoy = hoy or dt.date.today()
    if anio > hoy.year:
        return range(1, 1)
    if anio == hoy.year:
        return range(1, hoy.month)
    return range(1, 13)


# --- Validacion local --------------------------------------------------------
def es_parquet_valido(ruta: Path) -> bool:
    """Revision barata de integridad: el archivo existe, no esta vacio y tiene
    la firma PAR1 al inicio y al final (un archivo truncado pierde el footer)."""
    try:
        if ruta.stat().st_size < 12:
            return False
        with ruta.open("rb") as archivo:
            inicio = archivo.read(4)
            archivo.seek(-4, 2)
            fin = archivo.read(4)
    except OSError:
        return False
    return inicio == FIRMA_PARQUET and fin == FIRMA_PARQUET


def sha256(ruta: Path) -> str:
    digest = hashlib.sha256()
    with ruta.open("rb") as archivo:
        for bloque in iter(lambda: archivo.read(BLOQUE), b""):
            digest.update(bloque)
    return digest.hexdigest()


# --- Servidor ----------------------------------------------------------------
def consultar_publicacion(url: str) -> int | None:
    """Consulta si el archivo existe en el servidor (sin descargarlo).

    Devuelve el tamanio publicado (Content-Length) si existe, None si la TLC no
    lo ha publicado (403/404) y lanza ErrorConsulta ante cualquier otro problema.
    En el script original un error de red se reportaba como "no publicado", lo
    que ocultaba descargas incompletas.
    """
    ultimo_error = None
    for _ in range(INTENTOS):
        try:
            respuesta = requests.head(url, timeout=TIEMPO_ESPERA, allow_redirects=True)
        except requests.RequestException as error:
            ultimo_error = error
            continue
        if respuesta.ok:
            largo = respuesta.headers.get("Content-Length")
            return int(largo) if largo and largo.isdigit() else -1
        if respuesta.status_code in CODIGOS_NO_PUBLICADO:
            return None
        ultimo_error = f"HTTP {respuesta.status_code}"
    raise ErrorConsulta(f"no se pudo consultar {url}: {ultimo_error}")


def formato_tamanio(n: float) -> str:
    for unidad in ("B", "KiB", "MiB", "GiB"):
        if n < 1024 or unidad == "GiB":
            return f"{n:.1f} {unidad}"
        n /= 1024
    return f"{n:.1f} GiB"


def descargar_archivo(url: str, destino: Path, esperado: int | None = None) -> int:
    """Descarga `url` en `destino`. Devuelve la cantidad de bytes escritos."""
    destino.parent.mkdir(parents=True, exist_ok=True)
    temporal = destino.with_name(destino.name + SUFIJO_TEMPORAL)

    ultimo_error = None
    for intento in range(1, INTENTOS + 1):
        try:
            with requests.get(url, stream=True, timeout=TIEMPO_ESPERA) as respuesta:
                respuesta.raise_for_status()
                escritos = 0
                with temporal.open("wb") as archivo:
                    for bloque in respuesta.iter_content(chunk_size=BLOQUE):
                        if bloque:
                            archivo.write(bloque)
                            escritos += len(bloque)
            if escritos == 0:
                raise requests.RequestException("el servidor devolvio un archivo vacio")
            if esperado and esperado > 0 and escritos != esperado:
                raise requests.RequestException(
                    f"descarga incompleta: {escritos} de {esperado} bytes")
            if destino.suffix == ".parquet" and not es_parquet_valido(temporal):
                raise requests.RequestException("el archivo no es un Parquet valido")
            temporal.replace(destino)
            return escritos
        except requests.RequestException as error:
            ultimo_error = error
            temporal.unlink(missing_ok=True)
            if intento < INTENTOS:
                print(f"      intento {intento}/{INTENTOS} fallido ({error}); reintentando")

    raise requests.RequestException(f"no se pudo descargar {url}: {ultimo_error}")


# --- Manifiesto --------------------------------------------------------------
def leer_manifiesto() -> dict:
    if not RUTA_MANIFIESTO.exists():
        return {}
    with RUTA_MANIFIESTO.open(newline="", encoding="utf-8") as archivo:
        return {fila["archivo"]: fila for fila in csv.DictReader(archivo)}


def escribir_manifiesto(manifiesto: dict) -> None:
    RUTA_MANIFIESTO.parent.mkdir(parents=True, exist_ok=True)
    with RUTA_MANIFIESTO.open("w", newline="", encoding="utf-8") as archivo:
        escritor = csv.DictWriter(archivo, fieldnames=CAMPOS_MANIFIESTO)
        escritor.writeheader()
        for clave in sorted(manifiesto):
            escritor.writerow(manifiesto[clave])


def registrar(manifiesto: dict, tipo: str, anio, mes, ruta: Path, url: str) -> None:
    manifiesto[ruta_relativa(ruta)] = {
        "tipo": tipo, "anio": anio, "mes": mes,
        "archivo": ruta_relativa(ruta), "url": url,
        "bytes": ruta.stat().st_size, "sha256": sha256(ruta),
        "descargado_en": dt.datetime.now().isoformat(timespec="seconds"),
    }


# --- Flujo principal ---------------------------------------------------------
def resumen_vacio() -> dict:
    return {"descargados": 0, "omitidos": 0, "no_publicados": [], "fallidos": []}


def descargar(tipo: str, anio: int, manifiesto: dict) -> dict:
    """Descarga todos los meses publicados de un tipo de taxi para un anio."""
    print(f"\n=== {tipo.upper()} {anio} ===")
    resumen = resumen_vacio()
    posibles = meses_posibles(anio)

    for mes in range(1, 13):
        etiqueta = f"{anio}-{mes:02d}"
        destino = ruta_destino(tipo, anio, mes)

        if destino.exists():
            if es_parquet_valido(destino):
                print(f"  {etiqueta}  ya existe, se omite")
                resumen["omitidos"] += 1
                if ruta_relativa(destino) not in manifiesto:
                    registrar(manifiesto, tipo, anio, mes, destino,
                              construir_url(tipo, anio, mes))
                continue
            print(f"  {etiqueta}  existe pero esta corrupto/incompleto; se reemplaza")

        if mes not in posibles:
            print(f"  {etiqueta}  el mes aun no termina; no puede estar publicado")
            resumen["no_publicados"].append(etiqueta)
            continue

        url = construir_url(tipo, anio, mes)
        try:
            publicado = consultar_publicacion(url)
        except ErrorConsulta as error:
            print(f"  {etiqueta}  ERROR al consultar el servidor: {error}")
            resumen["fallidos"].append(etiqueta)
            continue
        if publicado is None:
            print(f"  {etiqueta}  aun no publicado por la TLC")
            resumen["no_publicados"].append(etiqueta)
            continue

        print(f"  {etiqueta}  descargando...")
        try:
            escritos = descargar_archivo(url, destino, publicado)
        except requests.RequestException as error:
            print(f"  {etiqueta}  ERROR: {error}")
            resumen["fallidos"].append(etiqueta)
        else:
            registrar(manifiesto, tipo, anio, mes, destino, url)
            print(f"  {etiqueta}  listo ({formato_tamanio(escritos)}) -> {ruta_relativa(destino)}")
            resumen["descargados"] += 1

    return resumen


def descargar_zonas(manifiesto: dict) -> bool:
    """Descarga la tabla de zonas (LocationID -> Borough/Zone) si no existe."""
    print("\n=== ZONAS (taxi_zone_lookup.csv) ===")
    if RUTA_ZONAS.exists() and RUTA_ZONAS.stat().st_size > 0:
        print("  ya existe, se omite")
        return True
    try:
        escritos = descargar_archivo(URL_ZONAS, RUTA_ZONAS)
    except requests.RequestException as error:
        print(f"  ERROR: {error}")
        return False
    registrar(manifiesto, "zonas", "", "", RUTA_ZONAS, URL_ZONAS)
    print(f"  listo ({formato_tamanio(escritos)}) -> {ruta_relativa(RUTA_ZONAS)}")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Descarga los datos de taxis amarillos y verdes del NYC TLC."
    )
    parser.add_argument(
        "--taxi", choices=(*TIPOS_TAXI, "all"), default="all",
        help="tipo de taxi a descargar (por defecto: all)",
    )
    parser.add_argument(
        "--anio", type=int, nargs="+", default=list(ANIOS_POR_DEFECTO),
        help=f"anio(s) a descargar (por defecto: {' '.join(map(str, ANIOS_POR_DEFECTO))})",
    )
    parser.add_argument(
        "--sin-zonas", action="store_true",
        help="no descargar la tabla de zonas taxi_zone_lookup.csv",
    )
    argumentos = parser.parse_args()

    tipos = TIPOS_TAXI if argumentos.taxi == "all" else (argumentos.taxi,)
    anios = sorted(set(argumentos.anio))
    manifiesto = leer_manifiesto()

    total = resumen_vacio()
    for anio in anios:
        for tipo in tipos:
            resumen = descargar(tipo, anio, manifiesto)
            total["descargados"] += resumen["descargados"]
            total["omitidos"] += resumen["omitidos"]
            total["no_publicados"] += [f"{tipo} {m}" for m in resumen["no_publicados"]]
            total["fallidos"] += [f"{tipo} {m}" for m in resumen["fallidos"]]
            escribir_manifiesto(manifiesto)   # se guarda tras cada bloque

    if not argumentos.sin_zonas and not descargar_zonas(manifiesto):
        total["fallidos"].append("zonas")
    escribir_manifiesto(manifiesto)

    print("\n" + "=" * 60)
    print("RESUMEN")
    print("=" * 60)
    print(f"  anios         : {', '.join(map(str, anios))}")
    print(f"  descargados   : {total['descargados']}")
    print(f"  ya existian   : {total['omitidos']}")
    print(f"  no publicados : {len(total['no_publicados'])}")
    if total["no_publicados"]:
        print(f"      {', '.join(total['no_publicados'])}")
    print(f"  fallidos      : {len(total['fallidos'])}")
    if total["fallidos"]:
        print(f"      {', '.join(total['fallidos'])}")
    print(f"  manifiesto    : {ruta_relativa(RUTA_MANIFIESTO)}")
    print("=" * 60)
    print("Siguiente paso: python scripts/verify_data.py")

    return 1 if total["fallidos"] else 0


if __name__ == "__main__":
    sys.exit(main())
