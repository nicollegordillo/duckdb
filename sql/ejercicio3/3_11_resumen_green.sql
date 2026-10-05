-- @id: 3.6b
-- @titulo: Perfil estadistico de columnas - taxis verdes (SUMMARIZE)
-- @objetivo: Igual que 3.6a para taxis verdes.
-- @fuente: data/raw/green/*/*.parquet
SUMMARIZE SELECT * FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true);
