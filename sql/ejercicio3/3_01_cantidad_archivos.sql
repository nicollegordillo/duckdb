-- @id: 3.1
-- @titulo: Cantidad de archivos disponibles por tipo y anio
-- @objetivo: Contar los archivos Parquet descargados y listar los meses que
--   cubren, para confirmar que no hay huecos en la serie mensual.
-- @fuente: data/raw/*/*/*.parquet (solo nombres de archivo, no se leen datos)
SELECT
    regexp_extract(file, 'raw[/\\](\w+)[/\\]', 1)           AS tipo,
    regexp_extract(file, 'raw[/\\]\w+[/\\](\d{4})', 1)      AS anio,
    count(*)                                                AS archivos,
    string_agg(regexp_extract(file, '_\d{4}-(\d{2})\.parquet$', 1), ', '
               ORDER BY file)                               AS meses
FROM glob('data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY tipo, anio;
