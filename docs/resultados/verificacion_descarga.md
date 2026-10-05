# Verificacion de la descarga

Generado: 2026-10-05T23:01:18 con `python scripts/verify_data.py`

| archivo | servidor | local | bytes | tamanio = publicado | registros | % pickup en el mes | pickup min / max |
|---|---|---|---|---|---|---|---|
| yellow 2026-01 | publicado | ok | 64,165,080 | si | 3,724,889 | 100.000% | 2025-12-31 23:57:29 / 2026-02-01 00:45:01 |
| yellow 2026-02 | publicado | ok | 58,683,353 | si | 3,399,866 | 100.000% | 2026-01-31 23:31:23 / 2026-03-01 00:51:48 |
| yellow 2026-03 | publicado | ok | 67,891,249 | si | 3,952,451 | 100.000% | 2008-12-31 23:03:20 / 2026-04-01 00:06:25 |
| yellow 2026-04 | publicado | ok | 64,818,115 | si | 3,831,240 | 100.000% | 2001-01-01 09:23:58 / 2026-05-01 00:01:28 |
| yellow 2026-05 | publicado | ok | 69,699,174 | si | 4,090,836 | 100.000% | 2008-12-31 23:05:53 / 2026-06-01 00:20:35 |
| yellow 2026-06 | publicado | ok | 65,465,637 | si | 3,837,248 | 100.000% | 2008-12-31 23:03:25 / 2026-06-30 23:59:59 |
| yellow 2026-07 | publicado | ok | 61,685,033 | si | 3,530,109 | 99.999% | 2008-12-30 23:06:00 / 2026-08-05 20:54:00 |
| yellow 2026-08 | publicado | ok | 59,043,961 | si | 3,336,716 | 100.000% | 2009-01-01 14:39:49 / 2026-08-31 23:59:59 |
| green 2026-01 | publicado | ok | 991,656 | si | 40,272 | 99.945% | 2025-12-27 16:49:41 / 2026-02-01 21:08:36 |
| green 2026-02 | publicado | ok | 920,753 | si | 37,373 | 99.971% | 2026-01-26 23:38:06 / 2026-03-01 09:48:53 |
| green 2026-03 | publicado | ok | 1,082,530 | si | 44,208 | 99.980% | 2009-01-01 01:35:31 / 2026-03-31 23:57:29 |
| green 2026-04 | publicado | ok | 1,075,896 | si | 44,238 | 99.993% | 2026-03-31 23:28:50 / 2026-05-01 07:53:18 |
| green 2026-05 | publicado | ok | 1,102,947 | si | 44,921 | 99.978% | 2008-12-31 23:05:50 / 2026-05-31 23:59:13 |
| green 2026-06 | publicado | ok | 1,075,836 | si | 44,163 | 99.971% | 2026-05-26 19:47:06 / 2026-07-01 03:21:24 |
| green 2026-07 | publicado | ok | 1,018,250 | si | 41,252 | 99.961% | 2008-12-31 17:35:31 / 2026-08-01 14:36:42 |
| green 2026-08 | publicado | ok | 1,007,530 | si | 40,687 | 99.966% | 2008-12-31 23:06:23 / 2026-08-31 23:58:28 |

## Registros por tipo y anio

| tipo | anio | archivos | registros |
|---|---|---|---|
| green | 2026 | 8 | 337,114 |
| yellow | 2026 | 8 | 29,703,355 |

## Veredicto

Completo: todos los meses publicados por la TLC estan descargados, su tamanio coincide con el publicado y DuckDB puede leerlos.
