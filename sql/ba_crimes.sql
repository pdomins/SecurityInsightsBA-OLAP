DROP TABLE IF EXISTS crimes;

CREATE TABLE crimes(
    id serial primary key,
    coordinates geometry,
    date_key integer references datetime(date_key)
);

DROP TABLE IF EXISTS aux_crimes, aux_crimes2;
CREATE TEMPORARY TABLE aux_crimes(
    id numeric,
    fecha date,
    franja_horaria text,
    tipo_delito text,
    subtipo_delito text,
    cantidad_registrada text,
    comuna text,
    barrio text,
    lat numeric,
    long numeric
);

CREATE TEMPORARY TABLE aux_crimes2(
    id_mapa text,
    anio numeric,
    mes text,
    dia text,
    fecha date,
    franja_horaria  text,
    tipo text,
    subtipo text,
    uso_armas text,
    barrio text,
    comuna text,
    lat text,
    long text,
    victimas numeric
);

-- CRIMES 16-17-18-19 ------------------------------------------------------------------------------------------------------------
COPY aux_crimes FROM '/Users/paudomingues/Documents/ITBA/OLAP/SecurityInsightsBA-OLAP/data/crimes/delitos_2016.csv' DELIMITER ',' NULL AS '' CSV HEADER;
COPY aux_crimes FROM '/Users/paudomingues/Documents/ITBA/OLAP/SecurityInsightsBA-OLAP/data/crimes/delitos_2017.csv' DELIMITER ',' NULL AS '' CSV HEADER;
COPY aux_crimes FROM '/Users/paudomingues/Documents/ITBA/OLAP/SecurityInsightsBA-OLAP/data/crimes/delitos_2018.csv' DELIMITER ',' NULL AS '' CSV HEADER;
COPY aux_crimes FROM '/Users/paudomingues/Documents/ITBA/OLAP/SecurityInsightsBA-OLAP/data/crimes/delitos_2019.csv' DELIMITER ',' NULL AS '' CSV HEADER;
COPY aux_crimes2 FROM '/Users/paudomingues/Documents/ITBA/OLAP/SecurityInsightsBA-OLAP/data/crimes/delitos_2020.csv' DELIMITER ',' NULL AS '' CSV HEADER;
COPY aux_crimes2 FROM '/Users/paudomingues/Documents/ITBA/OLAP/SecurityInsightsBA-OLAP/data/crimes/delitos_2021.csv' DELIMITER ',' NULL AS '' CSV HEADER;

DELETE FROM aux_crimes
WHERE NOT franja_horaria ~ '^[0-9]+$';

DELETE FROM aux_crimes2
WHERE NOT franja_horaria ~ '^[0-9]+$'
   OR lat = 'SD'
   OR long = 'SD';

INSERT INTO crimes(coordinates, date_key)
SELECT ST_POINT(c.long, c.lat), d.date_key
FROM aux_crimes c
JOIN datetime d ON c.fecha = d.date AND c.franja_horaria::numeric = d.time_range AND c.lat IS NOT NULL AND c.long IS NOT NULL;

INSERT INTO crimes(coordinates, date_key)
SELECT ST_POINT(c.long::numeric, c.lat::numeric), d.date_key
FROM aux_crimes2 c
JOIN datetime d ON c.fecha = d.date AND c.franja_horaria::numeric = d.time_range AND c.lat IS NOT NULL AND c.long IS NOT NULL;

DROP TABLE aux_crimes, aux_crimes2;

