"""Utilidades compartidas por los scripts y notebooks del laboratorio.

    from lab import conectar, ejecutar_sql

    con = conectar()                       # conexion en memoria + vistas
    meta, df, segundos = ejecutar_sql(con, "sql/ejercicio4/4_01_viajes_por_mes.sql")

    con = conectar(anios=[2026])           # las vistas leen solo 2026

Todas las rutas de datos en los archivos .sql son relativas a la raiz del
repositorio (p. ej. 'data/raw/yellow/*/*.parquet'). `conectar()` cambia el
directorio de trabajo a esa raiz para que funcionen igual desde scripts/,
notebooks/ o la terminal, dentro o fuera del contenedor.

Vistas (en este orden):
    sql/00_vistas.sql            origen: yellow_raw, green_raw, viajes (Parquet)
    sql/01_zonas.sql             zonas (CSV del catalogo de la TLC)
    sql/02_vistas_analisis.sql   viajes_enriquecidos, viajes_validos
"""

import os
import re
import time
from pathlib import Path

import duckdb

RAIZ_REPO = Path(__file__).resolve().parent.parent
DIR_SQL = RAIZ_REPO / "sql"
RUTA_ZONAS = RAIZ_REPO / "data" / "raw" / "zonas" / "taxi_zone_lookup.csv"
DIR_TEMPORAL = RAIZ_REPO / "data" / "processed" / "duckdb_tmp"

_PATRON_META = re.compile(r"^--\s*@(\w+):\s*(.*)$")


def conectar(base: str = ":memory:", vistas: bool = True, read_only: bool = False,
             anios=None):
    """Abre DuckDB y (opcionalmente) crea las vistas sobre los Parquet.

    Las vistas no copian datos: solo guardan la definicion de la consulta sobre
    los archivos Parquet, que se leen en el momento de consultar.

    anios: lista de anios que leen las vistas (por defecto todos los
    descargados). Si no se indica, se usa la variable de entorno LAB8_ANIOS
    (p. ej. LAB8_ANIOS=2026 o LAB8_ANIOS=2024,2026).
    """
    os.chdir(RAIZ_REPO)
    con = duckdb.connect(base, read_only=read_only)
    # Si una consulta no cabe en memoria, DuckDB escribe temporales a disco.
    # Se ubican en data/processed/ (ignorado por Git) en lugar de la raiz.
    DIR_TEMPORAL.mkdir(parents=True, exist_ok=True)
    con.execute(f"SET temp_directory = '{DIR_TEMPORAL.as_posix()}'")
    _configurar_memoria(con)
    if anios is None and os.environ.get("LAB8_ANIOS"):
        anios = [int(a) for a in re.split(r"[,\s]+", os.environ["LAB8_ANIOS"].strip()) if a]
    if anios:
        fijar_archivos(con, *archivos_por_anio(anios))
    if vistas:
        crear_vistas(con)
    return con


def crear_vistas(con) -> None:
    """Crea las vistas de origen (Parquet), zonas y analisis."""
    con.execute((DIR_SQL / "00_vistas.sql").read_text(encoding="utf-8"))
    if RUTA_ZONAS.exists():
        con.execute((DIR_SQL / "01_zonas.sql").read_text(encoding="utf-8"))
    con.execute((DIR_SQL / "02_vistas_analisis.sql").read_text(encoding="utf-8"))


def archivos_por_anio(anios):
    """Patrones de archivos (amarillos, verdes) para los anios indicados."""
    anios = sorted({int(a) for a in anios})
    return ([f"data/raw/yellow/{a}/*.parquet" for a in anios],
            [f"data/raw/green/{a}/*.parquet" for a in anios])


def fijar_archivos(con, yellow, green) -> None:
    """Restringe los archivos que leen yellow_raw y green_raw (sql/00_vistas.sql).

    Recibe listas de rutas o patrones relativos a la raiz del repositorio. Las
    vistas leen la variable cada vez que se consultan, asi que puede llamarse
    antes o despues de crearlas.
    """
    for tipo, archivos in (("yellow", yellow), ("green", green)):
        lista = [str(a) for a in archivos]
        if not lista:
            raise ValueError(f"lista de archivos {tipo} vacia")
        con.execute(f"SET VARIABLE archivos_{tipo} = ?::VARCHAR[]", [lista])


def _memoria_disponible_mb():
    """MemAvailable de /proc/meminfo (Linux/contenedor), en MB; None si no existe."""
    try:
        with open("/proc/meminfo", encoding="utf-8") as archivo:
            for linea in archivo:
                if linea.startswith("MemAvailable:"):
                    return int(linea.split()[1]) // 1024
    except OSError:
        pass
    return None


def _configurar_memoria(con) -> None:
    """Limita la memoria de DuckDB a lo que realmente esta libre.

    Por defecto DuckDB usa hasta el 80 % de la RAM total, sin considerar que
    Metabase (Java) o un kernel de Jupyter comparten la misma maquina virtual
    de Docker. Con 30 millones de filas eso provoca "Cannot allocate memory".
    Se fija el limite en el 60 % de la memoria disponible; si una consulta lo
    necesita, DuckDB escribe temporales en data/processed/duckdb_tmp.

    Se puede forzar con variables de entorno, p. ej.:
        LAB8_MEMORY_LIMIT=3GB  LAB8_THREADS=4
    """
    limite = os.environ.get("LAB8_MEMORY_LIMIT")
    if not limite:
        disponible = _memoria_disponible_mb()
        if disponible:
            limite = f"{max(512, int(disponible * 0.6))}MB"
    if limite:
        con.execute(f"SET memory_limit = '{limite}'")
    hilos = os.environ.get("LAB8_THREADS")
    if hilos:
        con.execute(f"SET threads = {int(hilos)}")
    # No conservar el orden de lectura reduce memoria; todas las consultas
    # que lo necesitan usan ORDER BY explicito.
    con.execute("SET preserve_insertion_order = false")


def leer_metadatos(texto: str) -> dict:
    """Lee el encabezado '-- @clave: valor' de un archivo .sql.

    Las lineas '--   texto' que siguen a una clave se agregan como continuacion.
    """
    meta, clave = {}, None
    for linea in texto.splitlines():
        m = _PATRON_META.match(linea.strip())
        if m:
            clave = m.group(1)
            meta[clave] = m.group(2).strip()
        elif clave and linea.startswith("--") and linea[2:].strip():
            meta[clave] += " " + linea[2:].strip()
        elif not linea.startswith("--"):
            break
    return meta


def ejecutar_sql(con, ruta):
    """Ejecuta un archivo .sql y devuelve (metadatos, DataFrame, segundos).

    Si el archivo tiene varias sentencias, el DataFrame corresponde a la ultima.
    """
    ruta = Path(ruta)
    if not ruta.is_absolute():
        ruta = RAIZ_REPO / ruta
    texto = ruta.read_text(encoding="utf-8")
    meta = leer_metadatos(texto)
    meta.setdefault("id", ruta.stem)
    inicio = time.perf_counter()
    df = con.execute(texto).df()
    segundos = time.perf_counter() - inicio
    return meta, df, segundos


def consulta(con, sql: str):
    """Atajo para consultas ad hoc en los notebooks."""
    return con.execute(sql).df()


def tabla_markdown(df, max_filas: int = 40) -> str:
    """Convierte un DataFrame a tabla Markdown sin dependencias extra."""
    def celda(v):
        if v is None or (isinstance(v, float) and v != v):
            return "NULL"
        if isinstance(v, float):
            return f"{v:,.4f}".rstrip("0").rstrip(".")
        if isinstance(v, int):
            return f"{v:,}"
        return str(v).replace("|", "\\|").replace("\n", " ")

    filas = df.head(max_filas)
    lineas = ["| " + " | ".join(map(str, df.columns)) + " |",
              "|" + "---|" * len(df.columns)]
    for registro in filas.itertuples(index=False):
        lineas.append("| " + " | ".join(celda(v) for v in registro) + " |")
    if len(df) > max_filas:
        lineas.append(f"\n_... {len(df) - max_filas} filas mas (ver CSV)._")
    return "\n".join(lineas)
