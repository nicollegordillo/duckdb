# Compatibilidad de las consultas anteriores con el conjunto ampliado

Generado: 2026-10-08T23:07:24 con `python scripts/compatibilidad.py`. Cada etapa ejecuta las consultas **sin modificarlas** sobre todos los archivos descargados en ese momento.
`vs. documentado` compara con `docs/resultados/<carpeta>/*.csv` (generados con 2026).

| consulta | id | 2026: estado | 2026: filas | 2026: s | 2026: vs. documentado | 2024_2026: estado | 2024_2026: filas | 2024_2026: s | 2024_2026: vs. documentado | 2024_2025_2026: estado | 2024_2025_2026: filas | 2024_2025_2026: s | 2024_2025_2026: vs. documentado |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `ejercicio3/3_01_cantidad_archivos` | 3.1 | ok | 2 | 0.04 | igual | ok | 4 | 0.12 | distinto | ok | 6 | 0.02 | distinto |
| `ejercicio3/3_02_registros_por_archivo` | 3.2a | ok | 16 | 0.06 | igual | ok | 40 | 0.16 | distinto | ok | 64 | 0.04 | distinto |
| `ejercicio3/3_03_registros_totales` | 3.2b | ok | 3 | 0.23 | igual | ok | 3 | 0.44 | distinto | ok | 3 | 0.28 | distinto |
| `ejercicio3/3_04_columnas_yellow` | 3.3a | ok | 21 | 0.04 | igual | ok | 21 | 0.06 | igual | ok | 21 | 0.04 | igual |
| `ejercicio3/3_05_columnas_green` | 3.3b | ok | 22 | 0.05 | igual | ok | 22 | 0.08 | igual | ok | 22 | 0.03 | igual |
| `ejercicio3/3_06_comparacion_columnas` | 3.3c | ok | 25 | 0.07 | igual | ok | 25 | 0.11 | igual | ok | 25 | 0.08 | igual |
| `ejercicio3/3_07_tipos_por_archivo` | 3.4 | ok | 43 | 0.18 | igual | ok | 43 | 0.13 | distinto | ok | 43 | 0.12 | distinto |
| `ejercicio3/3_08_muestra_yellow` | 3.5a | ok | 10 | 6.08 | igual | ok | 10 | 9.16 | distinto | ok | 10 | 12.39 | distinto |
| `ejercicio3/3_09_muestra_green` | 3.5b | ok | 10 | 0.20 | igual | ok | 10 | 0.48 | distinto | ok | 10 | 0.26 | distinto |
| `ejercicio3/3_10_resumen_yellow` | 3.6a | ok | 21 | 56.28 | distinto | ok | 21 | 128.38 | distinto | ok | 21 | 342.48 | distinto |
| `ejercicio3/3_11_resumen_green` | 3.6b | ok | 22 | 0.96 | distinto | ok | 22 | 2.63 | distinto | ok | 22 | 7.31 | distinto |
| `ejercicio3/3_12_reglas_calidad` | 3.6c | ok | 2 | 5.08 | igual | ok | 2 | 19.39 | distinto | ok | 2 | 40.81 | distinto |
| `ejercicio3/3_13_fechas_fuera_de_mes` | 3.6d | ok | 30 | 1.88 | distinto | ok | 30 | 6.71 | distinto | ok | 30 | 15.32 | distinto |
| `ejercicio3/3_14_codigos_categoricos` | 3.6e | ok | 40 | 5.21 | igual | ok | 41 | 49.99 | distinto | ok | 41 | 219.04 | distinto |
| `ejercicio3/3_15_consistencia_montos` | 3.6f | ok | 2 | 3.29 | igual | ok | 2 | 27.94 | distinto | ok | 2 | 25.45 | distinto |
| `ejercicio3/3_16_duplicados` | 3.6g | ok | 2 | 13.27 | igual | ok | 2 | 72.89 | distinto | error |  |  | nan |
| `ejercicio3/3_17_desglose_inconsistencia_montos` | 3.6h | ok | 27 | 7.51 | igual | ok | 28 | 25.03 | distinto | ok | 28 | 32.18 | distinto |
| `ejercicio3/3_18_request_source` | 3.6i | ok | 16 | 1.09 | distinto | ok | 40 | 2.69 | distinto | ok | 64 | 3.67 | distinto |
| `ejercicio4/4_01_viajes_por_mes` | P1 | ok | 16 | 10.55 | igual | ok | 40 | 20.83 | distinto | ok | 64 | 45.20 | distinto |
| `ejercicio4/4_02_hora_dia_semana` | P2 | ok | 336 | 6.77 | igual | ok | 336 | 14.38 | distinto | ok | 336 | 40.86 | distinto |
| `ejercicio4/4_03_caracteristicas_viaje` | P3 | ok | 8 | 9.84 | aprox | ok | 8 | 24.80 | distinto | ok | 8 | 71.60 | distinto |
| `ejercicio4/4_04_resumen_por_tipo` | P4 | ok | 2 | 12.01 | igual | ok | 2 | 17.68 | distinto | ok | 2 | 59.59 | distinto |
| `ejercicio4/4_05_viajes_por_borough` | P5 | ok | 15 | 7.15 | igual | ok | 15 | 14.01 | distinto | ok | 16 | 46.31 | distinto |
| `ejercicio4/4_06_metodo_pago` | P6 | ok | 10 | 9.13 | igual | ok | 11 | 17.53 | distinto | ok | 12 | 40.85 | distinto |
| `ejercicio4/4_07_distribucion_propina` | P7 | ok | 18 | 5.99 | igual | ok | 18 | 14.81 | distinto | ok | 18 | 28.27 | distinto |
| `ejercicio4/4_08_histograma_total` | P8 | ok | 62 | 6.15 | igual | ok | 62 | 12.78 | distinto | ok | 62 | 24.90 | distinto |
| `ejercicio4/4_09_impacto_reglas_calidad` | P9 | ok | 16 | 5.39 | igual | ok | 40 | 12.09 | distinto | ok | 64 | 23.64 | distinto |
| `ejercicio4/4_10_atipicos_tarifa_milla` | P10 | ok | 2 | 15.46 | distinto | ok | 2 | 32.51 | distinto | ok | 2 | 59.27 | distinto |
| `ejercicio4/4_11_propina_sobre_total` | P11 | ok | 82 | 8.18 | igual | ok | 82 | 12.13 | distinto | ok | 82 | 22.29 | distinto |

- **2026:** 29 de 29 consultas sin error; tiempo total 198.1 s.
- **2024_2026:** 29 de 29 consultas sin error; tiempo total 539.9 s.
- **2024_2025_2026:** 28 de 29 consultas sin error; tiempo total 1162.3 s.
