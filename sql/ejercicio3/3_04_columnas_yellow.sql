-- @id: 3.3a
-- @titulo: Columnas y tipos de datos - taxis amarillos
-- @objetivo: Identificar las columnas y el tipo de dato que DuckDB infiere al
--   leer todos los archivos amarillos en conjunto.
-- @fuente: data/raw/yellow/*/*.parquet
DESCRIBE SELECT * FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true);
