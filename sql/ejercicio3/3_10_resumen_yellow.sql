-- @id: 3.6a
-- @titulo: Perfil estadistico de columnas - taxis amarillos (SUMMARIZE)
-- @objetivo: Obtener min, max, promedio, cuartiles, valores unicos aproximados y
--   porcentaje de nulos de cada columna para detectar rangos imposibles y
--   columnas con muchos nulos.
-- @fuente: data/raw/yellow/*/*.parquet
SUMMARIZE SELECT * FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true);
