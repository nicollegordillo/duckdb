-- @id: 3.4
-- @titulo: Consistencia de tipos fisicos entre archivos
-- @objetivo: Revisar, columna por columna, si todos los archivos usan el mismo
--   tipo Parquet. Una columna con mas de un tipo o presente en menos archivos
--   que el total indica un cambio de esquema entre meses/anios.
-- @fuente: data/raw/*/*/*.parquet via parquet_schema()
WITH s AS (
    SELECT
        regexp_extract(file_name, 'raw[/\\](\w+)[/\\]', 1) AS tipo,
        file_name,
        name,
        type || coalesce(' (' || CASE
            WHEN logical_type LIKE 'TimestampType%'
                THEN 'TIMESTAMP_' || regexp_extract(logical_type, '(MILLIS|MICROS|NANOS)=[^<]', 1)
            ELSE coalesce(converted_type, regexp_replace(logical_type, '\(.*', ''))
        END || ')', '')                                    AS tipo_parquet
    FROM parquet_schema('data/raw/*/*/*.parquet')
    WHERE type IS NOT NULL                     -- excluye el nodo raiz del esquema
), archivos AS (
    SELECT tipo, count(DISTINCT file_name) AS total FROM s GROUP BY tipo
)
SELECT
    s.tipo,
    s.name                                         AS columna,
    string_agg(DISTINCT s.tipo_parquet, ' | ')     AS tipos_parquet,
    count(DISTINCT s.tipo_parquet)                 AS n_tipos,
    count(DISTINCT s.file_name)                    AS en_archivos,
    any_value(a.total)                             AS archivos_totales
FROM s JOIN archivos a USING (tipo)
GROUP BY s.tipo, s.name
ORDER BY s.tipo, (n_tipos > 1 OR en_archivos < archivos_totales) DESC, columna;
