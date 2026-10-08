-- @id: 5.3
-- @titulo: Columnas que cambian de nombre, tipo o presencia entre anios
-- @objetivo: Comparar el esquema fisico de los archivos de cada anio y mostrar
--   solo las columnas que NO son uniformes: ausentes en algunos archivos, con
--   mas de un tipo Parquet o con distinta capitalizacion del nombre. Son las
--   columnas que pueden romper una consulta al incorporar un anio nuevo y las
--   que justifican union_by_name, TRY_CAST y las columnas opcionales de
--   sql/00_vistas.sql.
-- @fuente: data/raw/*/*/*.parquet via parquet_schema()
WITH s AS (
    SELECT
        regexp_extract(file_name, 'raw[/\\](\w+)[/\\]', 1)                   AS tipo,
        CAST(regexp_extract(file_name, '_(\d{4})-\d{2}\.parquet$', 1) AS INTEGER) AS anio,
        file_name,
        name                                                                    AS columna,
        type || coalesce(' (' || CASE
            WHEN logical_type LIKE 'TimestampType%'
                THEN 'TIMESTAMP_' || regexp_extract(logical_type, '(MILLIS|MICROS|NANOS)=[^<]', 1)
            ELSE coalesce(converted_type, regexp_replace(logical_type, '\(.*', ''))
        END || ')', '')                                                         AS tipo_parquet
    FROM parquet_schema('data/raw/*/*/*.parquet')
    WHERE type IS NOT NULL                     -- excluye el nodo raiz del esquema
), archivos AS (
    SELECT tipo, anio, count(DISTINCT file_name) AS total FROM s GROUP BY ALL
), por_anio AS (
    SELECT
        s.tipo,
        lower(s.columna)                                    AS columna,
        s.anio,
        string_agg(DISTINCT s.columna, ' | ')               AS nombres,
        string_agg(DISTINCT s.tipo_parquet, ' | ')          AS tipos_parquet,
        count(DISTINCT s.file_name)                         AS en_archivos,
        any_value(a.total)                                  AS archivos_del_anio
    FROM s JOIN archivos a USING (tipo, anio)
    GROUP BY ALL
), todos AS (
    -- tipos y anios presentes, para detectar columnas que faltan en un anio completo
    SELECT DISTINCT p.tipo, p.columna, a.anio, a.total
    FROM por_anio p JOIN archivos a USING (tipo)
), no_uniformes AS (
    SELECT t.tipo, t.columna
    FROM todos t
    LEFT JOIN por_anio p USING (tipo, columna, anio)
    GROUP BY ALL
    HAVING count(DISTINCT p.tipos_parquet) > 1
        OR count(DISTINCT p.nombres) > 1
        OR bool_or(p.nombres LIKE '%|%' OR p.tipos_parquet LIKE '%|%')
        OR bool_or(coalesce(p.en_archivos, 0) < t.total)
)
SELECT
    t.tipo,
    t.columna,
    t.anio,
    coalesce(p.nombres, '(no existe)')                      AS nombres,
    p.tipos_parquet,
    coalesce(p.en_archivos, 0)                              AS en_archivos,
    t.total                                                 AS archivos_del_anio
FROM todos t
JOIN no_uniformes USING (tipo, columna)
LEFT JOIN por_anio p USING (tipo, columna, anio)
ORDER BY t.tipo DESC, t.columna, t.anio;
