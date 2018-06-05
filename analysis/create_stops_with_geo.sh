#!/bin/bash
psql nyc_gtfs_development -c "CREATE EXTENSION postgis;"
shp2pgsql -I -s 2263:4326 shapefile/taxi_zones.shp | psql -d nyc_gtfs_development
psql nyc_gtfs_development -f support_scripts/create_stops_with_geo.sql
