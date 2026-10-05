-- @id: 3.3b
-- @titulo: Columnas y tipos de datos - taxis verdes
-- @objetivo: Identificar las columnas y el tipo de dato de los archivos verdes.
-- @fuente: data/raw/green/*/*.parquet
DESCRIBE SELECT * FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true);
