-- @id: I11
-- @titulo: Porcentaje de registros validos por mes y regla que mas excluye
-- @pregunta: Q12 Que tan confiables son los datos de cada mes y que problema
--   de calidad pesa mas?
-- @indicador: % de registros que pasan todas las reglas de calidad y % marcado
--   por cada regla, por tipo y mes.
-- @justificacion: todos los demas indicadores usan viajes_validos; si la
--   proporcion excluida cambia mucho entre meses o anios, una variacion en
--   otro indicador podria deberse a la captura y no al comportamiento real.
-- @visualizacion: lineas por mes, una serie por tipo.
-- @tabla: ind_calidad
-- @fuente: vista viajes_enriquecidos (todos los registros)
SELECT
    taxi,
    anio_archivo                                                    AS anio,
    mes_archivo                                                     AS mes,
    make_date(anio_archivo, mes_archivo, 1)                         AS periodo,
    count(*)                                                        AS registros,
    count_if(NOT (f_fuera_periodo OR f_duracion OR f_distancia
                  OR f_velocidad OR f_monto OR f_pasajeros))        AS validos,
    round(100.0 * count_if(NOT (f_fuera_periodo OR f_duracion OR f_distancia
                  OR f_velocidad OR f_monto OR f_pasajeros)) / count(*), 2) AS pct_validos,
    round(100.0 * count_if(f_distancia) / count(*), 2)              AS pct_distancia,
    round(100.0 * count_if(f_duracion) / count(*), 2)               AS pct_duracion,
    round(100.0 * count_if(f_monto) / count(*), 2)                  AS pct_monto,
    round(100.0 * count_if(f_pasajeros) / count(*), 2)              AS pct_pasajeros,
    round(100.0 * count_if(f_velocidad) / count(*), 2)              AS pct_velocidad,
    round(100.0 * count_if(f_fuera_periodo) / count(*), 3)          AS pct_fuera_periodo
FROM viajes_enriquecidos
GROUP BY ALL
ORDER BY taxi DESC, anio, mes;
