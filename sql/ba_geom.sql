CREATE EXTENSION IF NOT EXISTS postgis;

DROP TABLE IF EXISTS communes, neighborhoods, police_stations, subway_stations;
DROP TABLE IF EXISTS temp_police_stations, temp_subway_stations;
-- COMMUNES ------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS communes
(
    multipolygon  geometry,
    id            numeric,
    object        text,
    commune       numeric primary key,
    neighborhoods text,
    perimeter     numeric,
    area          numeric
);

COPY communes
    FROM '<set_path>/SecurityInsightsBA-OLAP/data/geo/comunas.csv'
    DELIMITER ';'
    NULL AS ''
    CSV HEADER;

ALTER TABLE communes
    DROP COLUMN id,
    DROP COLUMN neighborhoods,
    DROP COLUMN object;

-- NEIGHBORHOOD ------------------------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS neighborhoods
(
    multipolygon geometry,
    neighborhood text primary key,
    commune      numeric references communes (commune),
    perimeter    numeric,
    area         numeric,
    object       text
);
COPY neighborhoods
    FROM '<set_path>/SecurityInsightsBA-OLAP/data/geo/barrios.csv'
    DELIMITER ';'
    NULL AS ''
    CSV HEADER;

ALTER TABLE neighborhoods
    DROP COLUMN object;

-- SUBWAY STATIONS ------------------------------------------------------------------------------------------------------------
CREATE TEMPORARY TABLE IF NOT EXISTS temp_subway_stations
(
    id      numeric primary key,
    long    numeric,
    lat     numeric,
    station text,
    line    text
);
CREATE TABLE IF NOT EXISTS subway_stations
(
    id           serial primary key,
    coordinates  geometry,
    station      text,
    neighborhood text references neighborhoods (neighborhood),
    line         text
);

COPY temp_subway_stations (long, lat, id, station, line)
    FROM '<set_path>/SecurityInsightsBA-OLAP/data/geo/estaciones-de-subte.csv'
    DELIMITER ','
    CSV HEADER;

INSERT INTO subway_stations (coordinates, station, line, neighborhood)
SELECT ST_POINT(t.long, t.lat) AS coordinates, t.station, t.line, n.neighborhood
FROM temp_subway_stations t
         JOIN neighborhoods n ON ST_Contains(n.multipolygon, ST_POINT(t.long, t.lat));


-- POLICE STATIONS ------------------------------------------------------------------------------------------------------------
CREATE TEMPORARY TABLE IF NOT EXISTS temp_police_stations
(
    long                    numeric,
    lat                     numeric,
    id                      numeric primary key,
    nombre                  text,
    calle                   text,
    altura                  text,
    calle2                  text,
    direccion               text,
    telefonos               text,
    observaciones           text,
    observaciones_2         text,
    barrio                  text,
    comuna                  text,
    codigo_postal           text,
    codigo_postal_argentino text
);

CREATE TABLE IF NOT EXISTS police_stations
(
    name         text primary key,
    coordinates  geometry(POINT, 0),
    neighborhood text references neighborhoods (neighborhood)
);

COPY temp_police_stations
    FROM '<set_path>/SecurityInsightsBA-OLAP/data/geo/comisarias-ciudad.csv'
    DELIMITER ','
    NULL AS ''
    CSV HEADER;

INSERT INTO police_stations(name, coordinates, neighborhood)
SELECT t.nombre, ST_POINT(t.long, t.lat), t.barrio
FROM temp_police_stations t;
DROP TABLE IF EXISTS temp_police_stations;
