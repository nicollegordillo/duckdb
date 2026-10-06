# Lab 4 — Cianobacteria en Atitlán y Amatitlán

Monitoreo satelital de floraciones de cianobacteria en los lagos de Atitlán y
Amatitlán, y modelos de aprendizaje automático para detectar zonas afectadas.

**CC3084 – Data Science · Universidad del Valle de Guatemala · Semestre II 2026**

## Equipo de desarrollo

- Daniel Oswaldo Juárez Herrera
- Humberto Alexander de la Cruz
- Nicolle Alexandra Gordillo

## Descripción del proyecto

Los lagos de Atitlán y Amatitlán vienen mostrando floraciones de cianobacteria, un
riesgo para la salud pública y el turismo. El proyecto usa imágenes Sentinel-2 (vía
openEO) para monitorear el fenómeno de forma remota, y se divide en dos partes.

**Parte 1 — Análisis geoespacial.** Se calcula el índice de cianobacteria NDCI/Chl-a
(script CyanoLakes de Sentinel Hub) junto con NDVI y NDWI sobre 11 fechas por lago,
entre enero de 2025 y julio de 2026, y se analiza cómo varía la floración en el tiempo
y en el espacio.

**Parte 2 — Modelos de Machine Learning.** A partir de esos mismos rásteres se
construye un conjunto de 314,896 observaciones píxel-fecha y se entrenan tres modelos
de clasificación binaria (regresión logística, Random Forest y XGBoost) para
identificar zonas con alta presencia de cianobacteria. Se evalúan mediante tres
estrategias de validación —aleatoria, espacial por bloques de 1 km y temporal por
fecha—, se analiza la generalización entre lagos, se interpretan con SHAP y se generan
mapas predictivos.

## Informes

- **Parte 1:** https://docs.google.com/document/d/1h8zRgpkovIHd9CXIRsFOxNLwAYtTIMXxwG4_hdEo6iw/edit?usp=sharing


## Contenido

| Archivo | Descripción |
|---|---|
| `01_descarga.py` | Descarga las 22 escenas (11 fechas × 2 lagos) vía openEO a `datos/raw/`. |
| `02_analisis.ipynb` | **Parte 1:** cálculo de índices y análisis temporal, espacial y comparativo. |
| `03_modelado_ml.ipynb` | **Parte 2:** dataset, modelos, validación, SHAP y mapas predictivos. |
| `datos/` | Imágenes crudas, índices derivados, geojson de cada lago y dataset de ML. |
| `resultados/` | CSVs, figuras y mapas interactivos generados por los notebooks. |
| `requirements.txt` | Dependencias con versiones fijadas. |

## Requisitos

```bash
pip install -r requirements.txt
```

Se necesita una cuenta gratuita del [Copernicus Data Space Ecosystem](https://dataspace.copernicus.eu)
para ejecutar `01_descarga.py`; la primera ejecución abre el navegador para autenticarse.

> **Nota sobre versiones.** `xgboost` está fijado en 2.0.3 a propósito. Desde la
> versión 2.1 el parámetro `base_score` se serializa como `'[5E-1]'` en lugar de
> `'5E-1'`, y `shap` 0.49.1 —la última versión disponible para Python 3.10— no
> interpreta ese formato, por lo que `TreeExplainer` falla en el ejercicio 8 de la
> Parte 2. Si se actualiza a Python 3.11 o superior, puede usarse `shap>=0.52` con
> cualquier versión de `xgboost`.

## Cómo reproducir

```bash
# 1. Descarga de imágenes (una sola vez, tarda entre 15 y 40 minutos)
python 01_descarga.py

# 2. Parte 1: abrir y ejecutar de principio a fin
jupyter notebook 02_analisis.ipynb

# 3. Parte 2: requiere que la Parte 1 se haya ejecutado antes
jupyter notebook 03_modelado_ml.ipynb
```

La carpeta `datos/` no se versiona: se regenera ejecutando los pasos anteriores. Los
geojson de los lagos deben colocarse en `datos/geojson/` como `atitlan.geojson` y
`amatitlan.geojson`; si no están, el notebook los descarga de OpenStreetMap.

## Decisiones metodológicas

Estas decisiones afectan a los resultados de ambas partes y están documentadas en los
notebooks y en los informes:

- **Máscara fija del lago.** Los límites provienen de OpenStreetMap (96 % de la
  superficie oficial de Atitlán y 99 % de la de Amatitlán) y se mantienen constantes en
  todas las fechas. Recalcular la máscara por fecha excluiría los píxeles con floración,
  que ópticamente dejan de comportarse como agua, sesgando el análisis contra el
  fenómeno de interés.
- **Fecha descartada.** La imagen de Atitlán del 18/01/2025 presentó reflectancia fuera
  de rango físico en el 75 % de su superficie y se excluyó por completo de ambas partes.
- **Umbral de floración.** Chl-a ≥ 10 µg/L, correspondiente al Nivel de Alerta 1 de la
  OMS para aguas recreativas y equivalente a NDCI ≥ 0.2413.
- **Control de fuga de información.** En la Parte 2 se excluyen como predictoras `chla`,
  `ndci`, `B04` y `B05`, ya que las dos bandas reconstruyen el índice de forma exacta y,
  con él, la variable respuesta.

## Versionado

El historial completo está en este repositorio. Las entregas quedan marcadas con
etiquetas de Git:

```bash
git tag -l          # lista las etiquetas disponibles
```

- `parte1` — entrega del Laboratorio 4, Parte 1
- `parte2` — entrega del Laboratorio 4, Parte 2
