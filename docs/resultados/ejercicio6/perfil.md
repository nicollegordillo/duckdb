# Perfil de consultas del benchmark

Generado con `python scripts/perfilar.py` sobre todos los datos descargados (vistas sobre Parquet vs. `data/processed/taxis.duckdb`). `cpu_s` es el tiempo de CPU sumado de todos los hilos. En el profiler, la lectura de Parquet aparece como TABLE_SCAN.

| consulta | modo | segundos | cpu_s | operadores en el plan (EXPLAIN) | % del tiempo de operadores |
|---|---|---|---|---|---|
| B2 | parquet | 13.59 | 105.2 | READ_PARQUET x2, FILTER x1, PROJECTION x11, HASH_GROUP_BY x1, WINDOW x1 | TABLE_SCAN 39 %, FILTER 36 %, PROJECTION 16 %, HASH_GROUP_BY 9 % |
| B2 | tabla | 16.07 | 126.6 | SEQ_SCAN x2, FILTER x2, PROJECTION x15, HASH_GROUP_BY x3, HASH_JOIN x1 | FILTER 59 %, PROJECTION 25 %, HASH_GROUP_BY 10 %, TABLE_SCAN 6 % |
| B3 | parquet | 11.58 | 88.3 | READ_PARQUET x2, FILTER x1, PROJECTION x11, HASH_GROUP_BY x1, WINDOW x1 | TABLE_SCAN 45 %, FILTER 41 %, PROJECTION 9 %, HASH_GROUP_BY 5 % |
| B3 | tabla | 13.31 | 104.4 | SEQ_SCAN x2, FILTER x2, PROJECTION x16, HASH_GROUP_BY x3, HASH_JOIN x1 | FILTER 70 %, PROJECTION 14 %, HASH_GROUP_BY 9 %, TABLE_SCAN 7 % |
| B5 | parquet | 13.63 | 103.9 | READ_PARQUET x2, FILTER x1, PROJECTION x12, HASH_GROUP_BY x1, HASH_JOIN x1, WINDOW x1 | TABLE_SCAN 45 %, FILTER 38 %, PROJECTION 6 %, HASH_GROUP_BY 6 %, HASH_JOIN 4 % |
| B5 | tabla | 7.53 | 58.9 | SEQ_SCAN x2, FILTER x1, PROJECTION x9, HASH_GROUP_BY x1, HASH_JOIN x1, WINDOW x1 | FILTER 63 %, PROJECTION 11 %, HASH_GROUP_BY 11 %, HASH_JOIN 8 %, TABLE_SCAN 7 % |
| B6 | parquet | 11.03 | 84.6 | READ_PARQUET x2, PROJECTION x11, HASH_GROUP_BY x1 | PROJECTION 47 %, TABLE_SCAN 47 %, HASH_GROUP_BY 6 % |
| B6 | tabla | 8.12 | 63.8 | SEQ_SCAN x1, PROJECTION x9, HASH_GROUP_BY x1 | PROJECTION 71 %, HASH_GROUP_BY 17 %, TABLE_SCAN 12 % |
