-- @id: B1
-- @titulo: Conteo de registros por tipo de taxi
-- @objetivo: Consulta minima del benchmark (equivale a 3.2b, pero sobre
--   `viajes`): solo cuenta filas. Sobre Parquet, `taxi` es una constante de
--   cada rama de la vista y no se lee ninguna columna; sobre la tabla, `taxi`
--   es una columna almacenada que hay que recorrer. Mide el costo fijo de abrir
--   y recorrer el origen de datos.
-- @fuente: relacion viajes (vista sobre Parquet o tabla materializada)
SELECT
    taxi,
    count(*)                                                        AS registros
FROM viajes
GROUP BY taxi
ORDER BY taxi DESC;
