-- Catalogo de zonas de taxi de la TLC (LocationID -> Borough, Zone).
-- Se lee directamente del CSV descargado por scripts/download_data.py.
CREATE OR REPLACE VIEW zonas AS
SELECT
    CAST(LocationID AS INTEGER) AS location_id,
    Borough                     AS borough,
    Zone                        AS zona,
    service_zone
FROM read_csv('data/raw/zonas/taxi_zone_lookup.csv', header = true);
