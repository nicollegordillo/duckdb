-- @id: 3.2a
-- @titulo: Registros por archivo usando solo los metadatos Parquet
-- @objetivo: Obtener la cantidad de filas de cada archivo leyendo unicamente el
--   footer del Parquet (sin escanear los datos) y detectar meses con volumen
--   anormalmente bajo o alto.
-- @fuente: data/raw/*/*/*.parquet via parquet_file_metadata()
SELECT
    regexp_extract(file_name, 'raw[/\\](\w+)[/\\]', 1)      AS tipo,
    regexp_extract(file_name, '_(\d{4}-\d{2})\.parquet$', 1) AS periodo,
    num_rows                                                AS registros,
    num_row_groups                                          AS row_groups,
    created_by
FROM parquet_file_metadata('data/raw/*/*/*.parquet')
ORDER BY tipo, periodo;
