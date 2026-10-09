#!/usr/bin/env python3
"""Construye el tablero de indicadores en Metabase (Ejercicios 7 y 8).

El tablero se crea por la API de Metabase a partir de este archivo, en lugar
de armarlo a mano en la interfaz. Asi queda en el repositorio, se puede
revisar en Git y cualquiera lo reconstruye igual con un comando.

Flujo de datos:

    Parquet --(sql/ejercicio7/*.sql, run_sql.py --tablero)--> data/processed/tablero.duckdb
    tablero.duckdb (tablas ind_*, solo lectura) --> Metabase --> tablero

Metabase no consulta los ~100 millones de viajes: lee las tablas pequenias que
dejan las consultas de los indicadores (decenas o cientos de filas cada una).
Cada tarjeta indica en su descripcion que consulta de sql/ la respalda.

Uso (con Metabase levantado y despues de `run_sql.py ejercicio7 --tablero`):

    python scripts/tablero_metabase.py
    docker compose exec lab python scripts/tablero_metabase.py --url http://metabase:3000

Lo que hace, en orden (es idempotente: volver a ejecutarlo reemplaza el tablero):
  1. Si Metabase no tiene usuario, lo configura con --email/--password.
  2. Registra (o actualiza) la base DuckDB del tablero en modo solo lectura.
  3. Crea la coleccion "Lab 8 - Indicadores"; archiva las tarjetas y tableros
     que hubiera en ella de una ejecucion anterior.
  4. Crea una tarjeta (pregunta SQL nativa) por visualizacion y el tablero con
     los filtros de tipo de taxi y anio, y textos con la interpretacion.
  5. Con --publico, habilita un enlace publico de solo lectura (sirve para
     tomar capturas sin iniciar sesion).

Credenciales: variables LAB8_MB_EMAIL / LAB8_MB_PASSWORD o --email/--password.
Los valores por defecto son solo para el ambiente local (puertos ligados a
127.0.0.1); cambielos si Metabase se expone en otra red.
"""

import argparse
import os
import re
import sys
import time
import uuid

import requests

COLECCION = "Lab 8 - Indicadores"
NOMBRE_BASE = "Lab 8 - Tablero (DuckDB)"
NOMBRE_TABLERO = "Viajes de taxi en NYC - Indicadores"
# Ruta de la base del tablero DENTRO del contenedor de Metabase
# (docker-compose.yml monta data/ en /workspace/data).
RUTA_BASE = "/workspace/data/processed/tablero.duckdb"

# Paleta categorica validada (contraste y separacion con daltonismo), la misma
# de los notebooks. El color sigue a la entidad: cada anio y cada tipo de taxi
# conserva su color en todas las tarjetas.
AZUL, NARANJA, AGUA, AMARILLO, GRIS = "#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#8a8f98"
COLOR_ANIO = {"2024": AZUL, "2025": AGUA, "2026": NARANJA}


# ---------------------------------------------------------------------------
# Definicion del tablero
# ---------------------------------------------------------------------------
# Cada tarjeta: titulo, consulta de respaldo, SQL de la tarjeta sobre la tabla
# del indicador, tipo de grafico, ajustes de visualizacion, filtros que usa y
# posicion en la cuadricula de 24 columnas (fila, columna, ancho, alto).
#
# {{taxi}} y {{anio}} son variables de Metabase conectadas a los filtros del
# tablero. CAST(anio AS VARCHAR) hace que el anio se use como serie y no como
# eje numerico.

def serie_anio(metrica, eje_x="mes", titulo_y=None, titulo_x=None):
    """Ajustes de un grafico de lineas con una serie por anio."""
    ajustes = {"graph.dimensions": [eje_x, "anio"], "graph.metrics": [metrica],
               "graph.x_axis.scale": "ordinal", "graph.show_values": False,
               "series_settings": {a: {"color": c} for a, c in COLOR_ANIO.items()}}
    if titulo_y:
        ajustes["graph.y_axis.title_text"] = titulo_y
    if titulo_x:
        ajustes["graph.x_axis.title_text"] = titulo_x
    return ajustes


TARJETAS = [
    # --- KPI del ultimo anio, en los meses comunes a todos los anios (I12) ---
    dict(clave="kpi_viajes", titulo="Viajes por dia (ultimo anio, meses comunes)",
         consulta="sql/ejercicio7/7_12_resumen_anual.sql",
         sql="SELECT viajes_por_dia AS \"Viajes por dia\" FROM ind_resumen_anual "
             "WHERE taxi = {{taxi}} ORDER BY anio DESC LIMIT 1",
         display="scalar", viz={"scalar.compact_primary_number": False},
         filtros=["taxi"], pos=(3, 0, 6, 3)),
    dict(clave="kpi_total", titulo="Total mediano por viaje, USD (ultimo anio)",
         consulta="sql/ejercicio7/7_12_resumen_anual.sql",
         sql="SELECT total_mediano FROM ind_resumen_anual "
             "WHERE taxi = {{taxi}} ORDER BY anio DESC LIMIT 1",
         display="scalar", viz={"scalar.field": "total_mediano", "column_settings": {
             '["name","total_mediano"]': {"prefix": "$", "decimals": 2}}},
         filtros=["taxi"], pos=(3, 6, 6, 3)),
    dict(clave="kpi_flex", titulo="% Flex Fare / sin dato de pago (ultimo anio)",
         consulta="sql/ejercicio7/7_12_resumen_anual.sql",
         sql="SELECT pct_flex_sin_dato FROM ind_resumen_anual "
             "WHERE taxi = {{taxi}} ORDER BY anio DESC LIMIT 1",
         display="scalar", viz={"column_settings": {
             '["name","pct_flex_sin_dato"]': {"suffix": " %"}}},
         filtros=["taxi"], pos=(3, 12, 6, 3)),
    dict(clave="kpi_cbd", titulo="% de viajes con cargo CBD (ultimo anio)",
         consulta="sql/ejercicio7/7_12_resumen_anual.sql",
         sql="SELECT pct_con_cargo_cbd FROM ind_resumen_anual "
             "WHERE taxi = {{taxi}} ORDER BY anio DESC LIMIT 1",
         display="scalar", viz={"column_settings": {
             '["name","pct_con_cargo_cbd"]': {"suffix": " %"}}},
         filtros=["taxi"], pos=(3, 18, 6, 3)),
    dict(clave="I12", titulo="I12 - Resumen por anio (meses comunes a todos los anios)",
         consulta="sql/ejercicio7/7_12_resumen_anual.sql",
         sql="SELECT taxi AS \"Tipo\", CAST(anio AS VARCHAR) AS \"Anio\", meses AS \"Meses\", "
             "viajes_por_dia AS \"Viajes/dia\", total_mediano AS \"Total mediano\", "
             "distancia_mediana AS \"Distancia med. (mi)\", duracion_mediana AS \"Duracion med. (min)\", "
             "mph_mediana AS \"Velocidad med. (mph)\", pct_tarjeta AS \"% tarjeta\", "
             "pct_flex_sin_dato AS \"% Flex/sin dato\", pct_con_cargo_cbd AS \"% cargo CBD\" "
             "FROM ind_resumen_anual ORDER BY taxi DESC, anio",
         display="table", viz={}, filtros=[], pos=(6, 0, 24, 5)),

    # --- Demanda ---
    dict(clave="I1", titulo="I1 - Viajes validos por dia, por mes",
         consulta="sql/ejercicio7/7_01_demanda_diaria.sql",
         sql="SELECT mes, CAST(anio AS VARCHAR) AS anio, viajes_por_dia FROM ind_demanda "
             "WHERE taxi = {{taxi}} ORDER BY mes, anio",
         display="line", viz=serie_anio("viajes_por_dia", titulo_y="Viajes por dia", titulo_x="Mes"),
         filtros=["taxi"], pos=(14, 0, 12, 7)),
    dict(clave="I1b", titulo="I1 - Participacion de los taxis verdes en los viajes del mes (%)",
         consulta="sql/ejercicio7/7_01_demanda_diaria.sql",
         sql="SELECT periodo, pct_del_mes AS pct_verdes FROM ind_demanda "
             "WHERE taxi = 'green' ORDER BY periodo",
         display="line", viz={"graph.dimensions": ["periodo"], "graph.metrics": ["pct_verdes"],
                              "graph.y_axis.title_text": "% de los viajes del mes",
                              "graph.x_axis.title_text": "Mes",
                              "series_settings": {"pct_verdes": {"color": AGUA}}},
         filtros=[], pos=(14, 12, 12, 7)),
    dict(clave="I3", titulo="I3 - Viajes promedio por hora: laborable vs. fin de semana",
         consulta="sql/ejercicio7/7_03_perfil_horario.sql",
         sql="SELECT hora, serie, viajes_promedio FROM ind_perfil_horario "
             "WHERE taxi = {{taxi}} ORDER BY hora, serie",
         display="line", viz={"graph.dimensions": ["hora", "serie"],
                              "graph.metrics": ["viajes_promedio"],
                              "graph.x_axis.scale": "ordinal",
                              "graph.x_axis.title_text": "Hora de inicio",
                              "graph.y_axis.title_text": "Viajes promedio en esa hora",
                              "series_settings": {
                                  f"{a} - {d}": {"color": c,
                                                 "line.style": "solid" if d == "Laborable" else "dashed"}
                                  for a, c in COLOR_ANIO.items()
                                  for d in ("Laborable", "Fin de semana")}},
         filtros=["taxi"], pos=(21, 0, 24, 7)),

    # --- Precio y facturacion ---
    dict(clave="I2", titulo="I2 - Total mediano por viaje (USD), por mes",
         consulta="sql/ejercicio7/7_02_costo_y_facturacion.sql",
         sql="SELECT mes, CAST(anio AS VARCHAR) AS anio, total_mediano FROM ind_costo "
             "WHERE taxi = {{taxi}} ORDER BY mes, anio",
         display="line", viz=serie_anio("total_mediano", titulo_y="USD", titulo_x="Mes"),
         filtros=["taxi"], pos=(31, 0, 12, 7)),
    dict(clave="I2b", titulo="I2 - Facturacion registrada por dia (USD)",
         consulta="sql/ejercicio7/7_02_costo_y_facturacion.sql",
         sql="SELECT periodo, facturacion_por_dia FROM ind_costo "
             "WHERE taxi = {{taxi}} ORDER BY periodo",
         display="bar", viz={"graph.dimensions": ["periodo"],
                             "graph.metrics": ["facturacion_por_dia"],
                             "graph.y_axis.title_text": "USD por dia",
                             "graph.x_axis.title_text": "Mes",
                             "series_settings": {"facturacion_por_dia": {"color": AZUL}}},
         filtros=["taxi"], pos=(31, 12, 12, 7)),
    # Un solo eje por grafica: el % de viajes con cargo esta en la tarjeta KPI
    # y en la tabla I12; aqui solo la recaudacion.
    dict(clave="I10", titulo="I10 - Recaudacion diaria del cargo CBD (USD)",
         consulta="sql/ejercicio7/7_10_cargo_congestion.sql",
         sql="SELECT periodo, coalesce(recaudacion_por_dia, 0) AS recaudacion_por_dia FROM ind_cbd "
             "WHERE taxi = {{taxi}} ORDER BY periodo",
         display="bar", viz={"graph.dimensions": ["periodo"],
                             "graph.metrics": ["recaudacion_por_dia"],
                             "graph.y_axis.title_text": "USD por dia",
                             "graph.x_axis.title_text": "Mes",
                             "series_settings": {"recaudacion_por_dia": {"color": AZUL}}},
         filtros=["taxi"], pos=(38, 0, 12, 7)),
    dict(clave="I8", titulo="I8 - Aeropuertos: % de viajes y % de la facturacion",
         consulta="sql/ejercicio7/7_08_aeropuertos.sql",
         sql="SELECT CAST(anio AS VARCHAR) AS anio, "
             "sum(pct_viajes) AS \"% de viajes\", sum(pct_facturacion) AS \"% de facturacion\" "
             "FROM ind_aeropuertos WHERE taxi = {{taxi}} AND aeropuerto <> 'Sin aeropuerto' "
             "GROUP BY anio ORDER BY anio",
         display="bar", viz={"graph.dimensions": ["anio"],
                             "graph.metrics": ["% de viajes", "% de facturacion"],
                             "graph.show_values": True,
                             "graph.y_axis.auto_split": False,
                             "graph.y_axis.title_text": "% del anio",
                             "graph.x_axis.title_text": "Anio",
                             "series_settings": {"% de viajes": {"color": GRIS},
                                                 "% de facturacion": {"color": AZUL}}},
         filtros=["taxi"], pos=(38, 12, 12, 7)),

    # --- Movilidad ---
    dict(clave="I4", titulo="I4 - Velocidad mediana por hora, lunes a viernes (mph)",
         consulta="sql/ejercicio7/7_04_velocidad_por_hora.sql",
         sql="SELECT hora, CAST(anio AS VARCHAR) AS anio, mph_mediana FROM ind_velocidad_hora "
             "WHERE taxi = {{taxi}} ORDER BY hora, anio",
         display="line", viz=serie_anio("mph_mediana", eje_x="hora", titulo_y="mph",
                                        titulo_x="Hora de inicio"),
         filtros=["taxi"], pos=(48, 0, 12, 7)),
    dict(clave="I5", titulo="I5 - Velocidad mediana dentro de la zona de cobro CBD (amarillos, lun-vie 7-19 h)",
         consulta="sql/ejercicio7/7_05_velocidad_zona_congestion.sql",
         sql="SELECT mes, CAST(anio AS VARCHAR) AS anio, mph_mediana FROM ind_velocidad_cbd "
             "ORDER BY mes, anio",
         display="line", viz=serie_anio("mph_mediana", titulo_y="mph", titulo_x="Mes"),
         filtros=[], pos=(48, 12, 12, 7)),
    dict(clave="I9", titulo="I9 - Las 10 zonas de origen con mas viajes (% del anio)",
         consulta="sql/ejercicio7/7_09_zonas_origen.sql",
         sql="SELECT zona || ' (' || borough || ')' AS zona, pct_viajes FROM ind_zonas_origen "
             "WHERE taxi = {{taxi}} AND anio = {{anio}} ORDER BY posicion",
         display="row", viz={"graph.dimensions": ["zona"], "graph.metrics": ["pct_viajes"],
                             "graph.x_axis.title_text": "",
                             "graph.y_axis.title_text": "% de los viajes del anio",
                             "graph.show_values": True,
                             "series_settings": {"pct_viajes": {"color": AZUL}}},
         filtros=["taxi", "anio"], pos=(55, 0, 12, 8)),

    # --- Pago y propina ---
    dict(clave="I6", titulo="I6 - Metodo de pago (% de los viajes del mes)",
         consulta="sql/ejercicio7/7_06_metodo_pago.sql",
         sql="SELECT periodo, metodo, pct FROM ind_pago WHERE taxi = {{taxi}} "
             "ORDER BY periodo, metodo",
         display="bar", viz={"graph.dimensions": ["periodo", "metodo"], "graph.metrics": ["pct"],
                             "stackable.stack_type": "stacked",
                             "graph.y_axis.min": 0, "graph.y_axis.max": 100,
                             "graph.y_axis.auto_range": False,
                             "graph.y_axis.title_text": "% de los viajes",
                             "graph.x_axis.title_text": "Mes",
                             "series_settings": {"Tarjeta": {"color": AZUL},
                                                 "Efectivo": {"color": AGUA},
                                                 "Flex fare / sin dato": {"color": NARANJA},
                                                 "Otros": {"color": GRIS}}},
         filtros=["taxi"], pos=(55, 12, 12, 8)),
    dict(clave="I7", titulo="I7 - Propina con tarjeta: % con propina y % que deja exactamente 20 %",
         consulta="sql/ejercicio7/7_07_propina.sql",
         sql="SELECT periodo, pct_con_propina AS \"% con propina\", "
             "pct_propina_20 AS \"% exactamente 20 %\" FROM ind_propina "
             "WHERE taxi = {{taxi}} ORDER BY periodo",
         display="line", viz={"graph.dimensions": ["periodo"],
                              "graph.metrics": ["% con propina", "% exactamente 20 %"],
                              "graph.y_axis.min": 0, "graph.y_axis.max": 100,
                              "graph.y_axis.auto_range": False,
                              "graph.y_axis.auto_split": False,
                              "graph.x_axis.title_text": "Mes",
                              "series_settings": {"% con propina": {"color": AZUL},
                                                  "% exactamente 20 %": {"color": NARANJA}}},
         filtros=["taxi"], pos=(66, 0, 12, 7)),
    dict(clave="I11", titulo="I11 - Calidad: % de registros que pasan todas las reglas",
         consulta="sql/ejercicio7/7_11_calidad.sql",
         sql="SELECT periodo, taxi, pct_validos FROM ind_calidad ORDER BY periodo, taxi",
         display="line", viz={"graph.dimensions": ["periodo", "taxi"],
                              "graph.metrics": ["pct_validos"],
                              "graph.y_axis.title_text": "% validos",
                              "graph.x_axis.title_text": "Mes",
                              "series_settings": {"yellow": {"color": AMARILLO},
                                                  "green": {"color": AGUA}}},
         filtros=[], pos=(66, 12, 12, 7)),

    # --- Evolucion 2024-2026 (Ejercicio 8, sql/ejercicio8/) ---
    dict(clave="E1", titulo="8.1 - Velocidad mediana: dentro de la zona CBD vs. resto de Manhattan (amarillos, lun-vie 7-19 h)",
         consulta="sql/ejercicio8/8_01_velocidad_cbd_vs_control.sql",
         sql="SELECT periodo, grupo, mph_mediana FROM ind_cbd_control ORDER BY periodo, grupo",
         display="line", viz={"graph.dimensions": ["periodo", "grupo"], "graph.metrics": ["mph_mediana"],
                              "graph.y_axis.title_text": "mph", "graph.x_axis.title_text": "Mes",
                              "series_settings": {"Dentro de la zona CBD": {"color": NARANJA},
                                                  "Manhattan fuera de la zona": {"color": AZUL}}},
         filtros=[], pos=(76, 0, 12, 7)),
    dict(clave="E2", titulo="8.2 - Viajes por dia segun forma de pago (meses comunes)",
         consulta="sql/ejercicio8/8_02_crecimiento_por_franja_y_pago.sql",
         sql="SELECT CAST(anio AS VARCHAR) AS anio, pago, sum(viajes_por_dia) AS viajes_por_dia "
             "FROM ind_crecimiento WHERE taxi = {{taxi}} GROUP BY anio, pago ORDER BY anio, pago",
         display="bar", viz={"graph.dimensions": ["anio", "pago"], "graph.metrics": ["viajes_por_dia"],
                             "stackable.stack_type": "stacked", "graph.show_values": True,
                             "graph.y_axis.title_text": "Viajes por dia", "graph.x_axis.title_text": "Anio",
                             "series_settings": {"Flex fare / sin dato": {"color": NARANJA},
                                                 "Tarjeta, efectivo y otros": {"color": AZUL}}},
         filtros=["taxi"], pos=(76, 12, 12, 7)),
    dict(clave="E3", titulo="8.2 - Viajes por dia por franja horaria y anio (meses comunes)",
         consulta="sql/ejercicio8/8_02_crecimiento_por_franja_y_pago.sql",
         sql="SELECT substr(franja, 3) AS franja, CAST(anio AS VARCHAR) AS anio, "
             "sum(viajes_por_dia) AS viajes_por_dia FROM ind_crecimiento WHERE taxi = {{taxi}} "
             "GROUP BY franja, anio ORDER BY min(franja), anio",
         display="bar", viz={"graph.dimensions": ["franja", "anio"], "graph.metrics": ["viajes_por_dia"],
                             "graph.y_axis.title_text": "Viajes por dia", "graph.x_axis.title_text": "",
                             "series_settings": {a: {"color": c} for a, c in COLOR_ANIO.items()}},
         filtros=["taxi"], pos=(83, 0, 24, 7)),
]

# Textos del tablero (Markdown): posicion, texto y tabla que debe existir para
# mostrarlo (None = siempre). Resumen de docs/ejercicio7_indicadores.md y
# docs/ejercicio8_2025.md.
TEXTOS = [
    ((0, 0, 24, 3),
     "# Viajes de taxi en NYC - indicadores\n"
     "NYC TLC Trip Record Data consultado con DuckDB. Cada tarjeta lee una tabla de "
     "`tablero.duckdb` generada por una consulta de `sql/ejercicio7/` o `sql/ejercicio8/` "
     "(ver su descripcion). Filtro **Tipo de taxi**: amarillos / verdes.", None),
    ((11, 0, 24, 3),
     "## Demanda\n**Q1-Q2, Q4.** Los amarillos crecieron en 2025 y se estancaron en 2026; los "
     "verdes caen cada anio. La estacionalidad se repite (valle en julio-agosto). Pico a las "
     "17-18 h entre semana; el fin de semana concentra la madrugada.", None),
    ((28, 0, 24, 3),
     "## Precio y facturacion\n**Q3, Q9, Q11.** El cargo CBD (USD 0.75 desde enero de 2025) "
     "lo paga ~73 % de los viajes amarillos. El total mediano sube sobre todo en 2026, por los "
     "viajes Flex Fare. Los aeropuertos son ~1 de cada 10 viajes amarillos pero ~1/4 de la "
     "facturacion.", None),
    ((45, 0, 24, 3),
     "## Movilidad\n**Q5-Q6, Q10.** El trafico es mas lento entre las 11 y las 16 h. Dentro de "
     "la zona CBD la velocidad no bajo en 2025 (inicio del cobro); la caida es de 2026 y tambien "
     "ocurre fuera de la zona (seccion de evolucion).", None),
    ((63, 0, 24, 3),
     "## Pago, propina y calidad\n**Q7-Q8, Q12.** Flex Fare / sin dato pasa de 9 % a 25 % de "
     "los amarillos. La propina con tarjeta es estable (mas de la mitad deja exactamente 20 %). "
     "Ojo: en enero-noviembre de 2025 la regla de monto excluye hasta 9.5 % de los amarillos.", None),
    ((73, 0, 24, 3),
     "## Evolucion 2024-2026 (Ejercicio 8)\n**8.1:** velocidad dentro de la zona CBD frente al "
     "resto de Manhattan (grupo de control). **8.2:** de donde viene el cambio de volumen: el "
     "crecimiento es Flex Fare y fuera de la hora pico; los demas viajes bajan en 2026.",
     "ind_cbd_control"),
]


# ---------------------------------------------------------------------------
# Cliente minimo de la API de Metabase
# ---------------------------------------------------------------------------

class Metabase:
    def __init__(self, url):
        self.url = url.rstrip("/")
        self.sesion = requests.Session()

    def _llamar(self, metodo, ruta, **kwargs):
        r = self.sesion.request(metodo, f"{self.url}/api/{ruta}", timeout=120, **kwargs)
        if r.status_code >= 400:
            raise RuntimeError(f"{metodo} /api/{ruta} -> {r.status_code}: {r.text[:500]}")
        return r.json() if r.content else None

    def get(self, ruta, **kw):
        return self._llamar("GET", ruta, **kw)

    def post(self, ruta, datos=None):
        return self._llamar("POST", ruta, json=datos)

    def put(self, ruta, datos=None):
        return self._llamar("PUT", ruta, json=datos)

    def esperar(self, segundos=300):
        """Espera a que Metabase termine de iniciar (tarda ~1 minuto)."""
        limite = time.time() + segundos
        while time.time() < limite:
            try:
                if self.sesion.get(f"{self.url}/api/health", timeout=5).json().get("status") == "ok":
                    return
            except (requests.RequestException, ValueError):
                pass
            time.sleep(3)
        raise RuntimeError(f"Metabase no respondio en {self.url} despues de {segundos} s")

    def iniciar_sesion(self, email, password):
        propiedades = self.get("session/properties")
        if not propiedades.get("has-user-setup"):
            print("  Metabase sin configurar: se crea el usuario administrador")
            self.post("setup", {
                "token": propiedades["setup-token"],
                "user": {"first_name": "Lab", "last_name": "8", "email": email,
                         "password": password, "site_name": "Lab 8 - DuckDB"},
                "prefs": {"site_name": "Lab 8 - DuckDB", "site_locale": "es",
                          "allow_tracking": False},
            })
        token = self.post("session", {"username": email, "password": password})["id"]
        self.sesion.headers["X-Metabase-Session"] = token


# ---------------------------------------------------------------------------
# Construccion
# ---------------------------------------------------------------------------

def registrar_base(mb: Metabase) -> int:
    """Crea o actualiza la conexion a la base del tablero (solo lectura)."""
    detalles = {"database_file": RUTA_BASE, "read_only": True, "old_implicit_casting": True}
    existentes = mb.get("database")
    existentes = existentes.get("data", existentes) if isinstance(existentes, dict) else existentes
    for base in existentes:
        if base["name"] == NOMBRE_BASE:
            mb.put(f"database/{base['id']}", {"details": detalles})
            id_base = base["id"]
            break
    else:
        # La primera conexion carga el driver nativo de DuckDB y puede pasar el
        # limite de 10 s de Metabase; se reintenta.
        for intento in range(5):
            try:
                id_base = mb.post("database", {"engine": "duckdb", "name": NOMBRE_BASE,
                                               "details": detalles, "is_full_sync": True})["id"]
                break
            except RuntimeError as error:
                if intento == 4 or "Timed out" not in str(error):
                    raise
                print("  la conexion a DuckDB tardo demasiado; se reintenta")
                time.sleep(5)
    mb.post(f"database/{id_base}/sync_schema")
    return id_base


def preparar_coleccion(mb: Metabase) -> int:
    """Devuelve la coleccion del laboratorio; archiva lo que haya en ella."""
    for col in mb.get("collection"):
        if col.get("name") == COLECCION and not col.get("archived"):
            id_col = col["id"]
            break
    else:
        id_col = mb.post("collection", {"name": COLECCION, "color": AZUL,
                                        "description": "Indicadores de los Ejercicios 7 y 8"})["id"]
    items = mb.get(f"collection/{id_col}/items")
    items = items.get("data", items) if isinstance(items, dict) else items
    for item in items:
        if item.get("model") == "card":
            mb.put(f"card/{item['id']}", {"archived": True})
        elif item.get("model") == "dashboard":
            mb.put(f"dashboard/{item['id']}", {"archived": True})
    return id_col


def variable(nombre):
    if nombre == "taxi":
        return {"id": str(uuid.uuid4()), "name": "taxi", "display-name": "Tipo de taxi",
                "type": "text", "required": True, "default": "yellow"}
    return {"id": str(uuid.uuid4()), "name": "anio", "display-name": "Anio",
            "type": "number", "required": True, "default": "2026"}


def tablas_del_tablero(ruta_local):
    """Tablas presentes en la base del tablero (None si no se puede leer)."""
    try:
        import duckdb
        con = duckdb.connect(str(ruta_local), read_only=True)
        tablas = {r[0] for r in con.execute("SELECT table_name FROM information_schema.tables").fetchall()}
        con.close()
        return tablas
    except Exception:
        return None


def tabla_de(t):
    """Tabla ind_* que lee la tarjeta."""
    return re.search(r"FROM (ind_\w+)", t["sql"]).group(1)


def crear_tarjeta(mb, id_base, id_col, t) -> int:
    descripcion = f"Consulta de respaldo: {t['consulta']} (tabla del indicador en tablero.duckdb)."
    datos = {
        "name": t["titulo"], "description": descripcion, "display": t["display"],
        "collection_id": id_col, "visualization_settings": t["viz"],
        "dataset_query": {"type": "native", "database": id_base,
                          "native": {"query": t["sql"],
                                     "template-tags": {f: variable(f) for f in t["filtros"]}}},
    }
    return mb.post("card", datos)["id"]


def crear_tablero(mb, id_col, tarjetas, anios, tablas) -> int:
    parametros = [
        {"id": "taxi", "name": "Tipo de taxi", "slug": "taxi", "type": "string/=",
         "sectionId": "string", "default": ["yellow"], "required": True,
         "values_query_type": "list", "values_source_type": "static-list",
         "values_source_config": {"values": [["yellow", "Amarillos"], ["green", "Verdes"]]}},
        {"id": "anio", "name": "Anio (ranking de zonas)", "slug": "anio", "type": "number/=",
         "sectionId": "number", "default": [max(anios)], "required": True,
         "values_query_type": "list", "values_source_type": "static-list",
         "values_source_config": {"values": [[a] for a in anios]}},
    ]
    id_tablero = mb.post("dashboard", {
        "name": NOMBRE_TABLERO, "collection_id": id_col, "parameters": parametros,
        "description": "Ejercicios 7 y 8. Tablas generadas con scripts/run_sql.py ejercicio7 --tablero; "
                       "tablero generado con scripts/tablero_metabase.py.",
    })["id"]

    dashcards, nuevo_id = [], -1
    for (fila, col, ancho, alto), texto, requiere in TEXTOS:
        if requiere and tablas is not None and requiere not in tablas:
            continue
        dashcards.append({"id": nuevo_id, "card_id": None, "row": fila, "col": col,
                          "size_x": ancho, "size_y": alto, "parameter_mappings": [],
                          "visualization_settings": {
                              "virtual_card": {"name": None, "display": "text",
                                               "visualization_settings": {},
                                               "dataset_query": {}, "archived": False},
                              "text": texto}})
        nuevo_id -= 1
    for t, id_tarjeta in tarjetas:
        fila, col, ancho, alto = t["pos"]
        dashcards.append({
            "id": nuevo_id, "card_id": id_tarjeta, "row": fila, "col": col,
            "size_x": ancho, "size_y": alto, "visualization_settings": {},
            "parameter_mappings": [{"parameter_id": f, "card_id": id_tarjeta,
                                    "target": ["variable", ["template-tag", f]]}
                                   for f in t["filtros"]]})
        nuevo_id -= 1
    mb.put(f"dashboard/{id_tablero}", {"dashcards": dashcards, "parameters": parametros})
    return id_tablero


def anios_del_tablero(ruta_local):
    """Anios presentes en ind_resumen_anual (para el filtro); lee la base local."""
    try:
        import duckdb
        con = duckdb.connect(str(ruta_local), read_only=True)
        anios = [r[0] for r in con.execute(
            "SELECT DISTINCT anio FROM ind_resumen_anual ORDER BY anio").fetchall()]
        con.close()
        return anios or [2026]
    except Exception as error:  # la base puede no estar accesible desde aqui
        print(f"  aviso: no se pudieron leer los anios ({error}); se usa 2024-2026")
        return [2024, 2025, 2026]


def main() -> int:
    from pathlib import Path
    raiz = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--url", default=os.environ.get("LAB8_MB_URL", "http://localhost:3000"))
    parser.add_argument("--email", default=os.environ.get("LAB8_MB_EMAIL", "admin@lab8.local"))
    parser.add_argument("--password", default=os.environ.get("LAB8_MB_PASSWORD", "Lab8-DuckDB-2026"))
    parser.add_argument("--publico", action="store_true",
                        help="habilitar un enlace publico de solo lectura al tablero")
    args = parser.parse_args()

    tablero_local = raiz / "data" / "processed" / "tablero.duckdb"
    if not tablero_local.exists():
        print(f"No existe {tablero_local}. Ejecute antes: python scripts/run_sql.py ejercicio7 --tablero")
        return 1
    anios = anios_del_tablero(tablero_local)

    mb = Metabase(args.url)
    print(f"Metabase: {args.url}")
    mb.esperar()
    mb.iniciar_sesion(args.email, args.password)
    id_base = registrar_base(mb)
    print(f"  base DuckDB registrada (id {id_base}): {RUTA_BASE}")
    id_col = preparar_coleccion(mb)
    tablas = tablas_del_tablero(tablero_local)
    tarjetas = []
    for t in TARJETAS:
        if tablas is not None and tabla_de(t) not in tablas:
            # p. ej. las del Ejercicio 8 antes de ejecutar run_sql.py ejercicio8 --tablero
            print(f"  (se omite {t['clave']}: falta la tabla {tabla_de(t)})")
            continue
        tarjetas.append((t, crear_tarjeta(mb, id_base, id_col, t)))
        print(f"  tarjeta: {t['titulo']}")
    id_tablero = crear_tablero(mb, id_col, tarjetas, anios, tablas)
    print(f"\nTablero: {args.url}/dashboard/{id_tablero}")
    if args.publico:
        mb.put("setting/enable-public-sharing", {"value": True})
        uuid_publico = mb.post(f"dashboard/{id_tablero}/public_link")["uuid"]
        print(f"Enlace publico: {args.url}/public/dashboard/{uuid_publico}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
