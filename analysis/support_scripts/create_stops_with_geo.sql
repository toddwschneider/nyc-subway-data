CREATE TABLE stops_with_geo AS
SELECT s.*, z.borough, z.zone, z.locationid
FROM stops s, taxi_zones z
WHERE ST_Within(
  ST_SetSRID(
    ST_MakePoint(s.longitude, s.latitude),
    4326
  ),
  z.geom
);
CREATE UNIQUE INDEX ON stops_with_geo (mta_id);
