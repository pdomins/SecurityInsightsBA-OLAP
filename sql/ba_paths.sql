-- SENDEROS ------------------------------------------------------------------------------------------------------------
CREATE TABLE paths(
    id serial primary key,
    path_id text,
    name text,
    coordinates geometry,
    neighborhood text references neighborhoods(neighborhood)
);

CREATE TEMPORARY TABLE aux_paths(
    CUE numeric,
    name text,
    address text,
    path_id text,
    scope text,
    barrio text,
    comuna text,
    de text,
    X numeric,
    Y numeric,
    lat numeric,
    long numeric
);

COPY aux_paths FROM '/Users/paudomingues/Documents/ITBA/OLAP/SecurityInsightsBA-OLAP/data/paths/senderos_escolares_2023.csv' DELIMITER ',' NULL AS '' CSV HEADER;

INSERT INTO paths(path_id, name, coordinates, neighborhood)
SELECT path_id, name, ST_POINT(long, lat), barrio
FROM aux_paths;

DROP TABLE aux_paths;