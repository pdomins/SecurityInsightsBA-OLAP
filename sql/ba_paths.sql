DROP TABLE IF EXISTS schools CASCADE;
CREATE TABLE schools
(
    school_id    serial primary key,
    cue          numeric,
    name         text,
    coordinates  geometry,
    neighborhood text references neighborhoods (neighborhood),
    CONSTRAINT school_cue UNIQUE (cue, name)
);

DROP TABLE IF EXISTS paths;
CREATE TABLE paths
(
    path_id   text,
    school_id integer references schools (school_id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS aux_paths;
CREATE TEMPORARY TABLE aux_paths
(
    CUE     numeric,
    name    text,
    address text,
    path_id text,
    scope   text,
    barrio  text,
    comuna  text,
    de      text,
    X       numeric,
    Y       numeric,
    lat     numeric,
    long    numeric
);

COPY aux_paths FROM '/Users/paudomingues/Documents/ITBA/OLAP/SecurityInsightsBA-OLAP/data/paths/senderos_escolares_2023.csv' DELIMITER ',' NULL AS '' CSV HEADER;

INSERT INTO schools(cue, name, coordinates, neighborhood)
SELECT cue, name, ST_POINT(long, lat), barrio
FROM aux_paths;

INSERT INTO paths
SELECT path_id, (SELECT school_id FROM schools s WHERE aux_paths.CUE = s.cue AND aux_paths.name = s.name)
FROM aux_paths;

DROP TABLE aux_paths;