-- =============================================================================
-- Capa de ANALISIS: columnas derivadas y filtros de calidad
-- =============================================================================
-- Solo depende de la relacion `viajes` (esquema unificado), sin importar si es
-- la vista sobre los Parquet (sql/00_vistas.sql) o la tabla materializada del
-- Ejercicio 6 (scripts/materializar.py). Por eso las consultas de los
-- Ejercicios 4 en adelante corren igual sobre ambas.
-- (Hasta el Ejercicio 4 estas vistas estaban al final de sql/00_vistas.sql; se
-- separaron sin cambiar su definicion.)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- viajes_enriquecidos: columnas derivadas + banderas de calidad.
-- Las banderas NO eliminan filas; solo marcan problemas detectados en el
-- Ejercicio 3 para poder cuantificarlos (ver sql/ejercicio4/4_09_*.sql).
-- Umbrales elegidos a partir del Ejercicio 3 (docs/ejercicio3_exploracion.md):
--   f_fuera_periodo : el pickup no cae en el mes que indica el archivo
--   f_duracion      : duracion <= 0 min o > 6 horas
--   f_distancia     : distancia <= 0 o > 100 millas
--   f_velocidad     : velocidad promedio > 80 mph (imposible en la ciudad)
--   f_monto         : tarifa base <= 0 o total <= 0 (reembolsos/anulaciones)
--   f_pasajeros     : passenger_count = 0
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW viajes_enriquecidos AS
WITH base AS (
    SELECT
        *,
        date_diff('second', pickup_at, dropoff_at) / 60.0       AS duracion_min,
        CAST(pickup_at AS DATE)                                  AS fecha,
        hour(pickup_at)                                          AS hora,
        isodow(pickup_at)                                        AS dia_semana,  -- 1 = lunes
        -- Diccionario TLC (mar. 2025). En amarillos el bloque sin datos de
        -- pasajeros/tarifa usa payment_type = 0 (Flex Fare); en verdes el
        -- mismo bloque trae payment_type NULL (Ejercicio 3, 3.6e).
        CASE
            WHEN payment_type IS NULL THEN 'Sin dato'
            WHEN payment_type = 0 THEN 'Flex fare' WHEN payment_type = 1 THEN 'Tarjeta'
            WHEN payment_type = 2 THEN 'Efectivo'  WHEN payment_type = 3 THEN 'Sin cargo'
            WHEN payment_type = 4 THEN 'Disputa'   WHEN payment_type = 5 THEN 'Desconocido'
            WHEN payment_type = 6 THEN 'Anulado'   ELSE 'Otro' END   AS metodo_pago
    FROM viajes
)
SELECT
    *,
    trip_distance / nullif(duracion_min / 60.0, 0)               AS velocidad_mph,
    tip_amount / nullif(fare_amount, 0)                          AS pct_propina,
    coalesce(date_trunc('month', pickup_at)
             <> make_date(anio_archivo, mes_archivo, 1), true)   AS f_fuera_periodo,
    coalesce(duracion_min <= 0 OR duracion_min > 360, true)      AS f_duracion,
    coalesce(trip_distance <= 0 OR trip_distance > 100, true)    AS f_distancia,
    coalesce(trip_distance / nullif(duracion_min / 60.0, 0) > 80, false) AS f_velocidad,
    coalesce(fare_amount <= 0 OR total_amount <= 0, true)        AS f_monto,
    coalesce(passenger_count = 0, false)                         AS f_pasajeros
FROM base;

-- -----------------------------------------------------------------------------
-- viajes_validos: subconjunto usado en el analisis exploratorio.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW viajes_validos AS
SELECT * FROM viajes_enriquecidos
WHERE NOT (f_fuera_periodo OR f_duracion OR f_distancia
           OR f_velocidad OR f_monto OR f_pasajeros);
