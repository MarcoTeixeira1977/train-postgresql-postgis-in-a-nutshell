----------------
-- LISTING 1
----------------
CREATE ROLE geodb_admin CREATEROLE CREATEDB LOGIN PASSWORD 'geodb_admin';

----------------
-- LISTING 2
----------------
--CREATE ROLE mwagner LOGIN PASSWORD 'mwagner';

----------------
-- LISTING 3
----------------
CREATE ROLE gis_view;
CREATE ROLE gis_update;

----------------
-- LISTING 4
----------------
GRANT gis_update TO user_name;

----------------
-- LISTING 5
----------------
DROP ROLE role_name;

----------------
-- LISTING 6
----------------
CREATE DATABASE template_postgis;

----------------
-- LISTING 7
----------------
CREATE EXTENSION postgis;

----------------
-- LISTING 8
----------------
REVOKE CREATE ON SCHEMA public FROM public;

----------------
-- LISTING 9
----------------
UPDATE pg_database SET datistemplate = true WHERE datname = 'template_postgis';

----------------
-- LISTING 10
----------------
CREATE DATABASE my_first_geodb TEMPLATE = template_postgis;

----------------
-- LISTING 11
----------------
GRANT CREATE ON DATABASE my_first_geodb TO user_name;

----------------
-- LISTING 12
----------------
DROP DATABASE my_db;

----------------
-- LISTING 13
----------------
CREATE SCHEMA cadastre;

----------------
-- LISTING 14
----------------
SELECT * FROM cadastre.parcel;

----------------
-- LISTING 15
----------------
GRANT USAGE ON SCHEMA cadastre TO public;

----------------
-- LISTING 16
----------------
CREATE SCHEMA vector_data;
CREATE SCHEMA raster_data;

----------------
-- LISTING 17
----------------
GRANT USAGE ON SCHEMA vector_data TO public;
GRANT USAGE ON SCHEMA raster_data TO public;

----------------
-- LISTING 18
----------------
DROP SCHEMA cadastre CASCADE;

----------------
-- LISTING 19
----------------
CREATE TABLE vector_data.river (
gid SERIAL PRIMARY KEY,
name VARCHAR(50),
length INT,
depth DECIMAL(3, 2),
polluted BOOLEAN DEFAULT FALSE,
date_last_checked DATE
);

SELECT AddGeometryColumn('vector_data', 'river', 'geometry', 32740, 'MULTILINESTRING', 2);

----------------
-- LISTING 20
----------------
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE vector_data.river TO gis_update;
GRANT SELECT ON TABLE vector_data.river TO gis_view;
GRANT USAGE ON SEQUENCE vector_data.river_gid_seq TO gis_update;

----------------
-- LISTING 21
----------------
CREATE INDEX river_geometry_idx ON vector_data.river USING gist(geometry);

----------------
-- LISTING 22
----------------
DROP TABLE vector_data.river;

----------------
-- LISTING 23
----------------
CREATE OR REPLACE VIEW polluted_rivers AS SELECT * FROM vector_data.river WHERE polluted = true;

----------------
-- LISTING 24
----------------
GRANT SELECT ON VIEW vector_data.polluted_rivers TO gis_update, gis_view;

----------------
-- LISTING 25 (no SQL!)
----------------
cd "C:\Program Files\PostgreSQL\9.5\bin"

----------------
-- LISTING 26 (no SQL!)
----------------
raster2pgsql -I -C -e -Y -F -s 32740 -t auto -l 2,4,8,16,32,64 Z:\PostgreSQL_PostGIS_in_a_Nutshell\Data\DEM\Mahe_DEM.tif raster_data.mahe_dem | psql -U geodb_admin -d my_first_geodb

----------------
-- LISTING 27
----------------
GRANT SELECT ON raster_data.mahe_dem TO gis_update, gis_view;
GRANT SELECT ON raster_data.o_2_mahe_dem TO gis_update, gis_view;
GRANT SELECT ON raster_data.o_4_mahe_dem TO gis_update, gis_view;
GRANT SELECT ON raster_data.o_8_mahe_dem TO gis_update, gis_view;
GRANT SELECT ON raster_data.o_16_mahe_dem TO gis_update, gis_view;
GRANT SELECT ON raster_data.o_32_mahe_dem TO gis_update, gis_view;
GRANT SELECT ON raster_data.o_64_mahe_dem TO gis_update, gis_view;

----------------
-- EXAMPLE QUERIES
----------------
SELECT id AS parcel_no, gid, ST_IsValidReason(geometry) AS reason FROM vector_data.parcel WHERE NOT ST_IsValid(geometry);

SELECT gid, ST_AsGeoJSON(geometry, 1) FROM vector_data.building LIMIT 3;

SELECT id, ST_Area(geometry) AS area_m2 FROM vector_data.parcel ORDER BY area_m2 DESC LIMIT 5;

SELECT id, ST_AsText(geometry) FROM vector_data.parcel ORDER BY ST_Area(geometry) LIMIT 3;

SELECT count(a.*) FROM vector_data.parcel a, vector_data.river b WHERE ST_Intersects(a.geometry, b.geometry);

CREATE OR REPLACE VIEW user_name.donut_buildings AS SELECT * FROM vector_data.building WHERE ST_NRings(geometry) > 1;

SELECT b.name as church_name, round(st_value(a.rast, b.geometry)) AS elevation FROM raster_data.mahe_dem a, vector_data.church b WHERE ST_Intersects(a.rast, b.geometry) ORDER BY elevation;

SELECT a.name as district_name, count(b.*) as parcel_count FROM vector_data.district a, vector_data.parcel b WHERE ST_Intersects(a.geometry, b.geometry) group by a.name ORDER BY a.name;
