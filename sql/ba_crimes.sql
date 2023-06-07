DROP TABLE IF EXISTS crimes;

CREATE TABLE crimes(
    id serial primary key,
    coordinates geometry,
    date_key integer references datetime(date_key)
);

DROP TABLE IF EXISTS aux_crimes;
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

-- CRIMES 16-17-18-19 ------------------------------------------------------------------------------------------------------------
COPY aux_crimes FROM '/Users/paudomingues/Documents/ITBA/OLAP/SecurityInsightsBA-OLAP/data/crimes/delitos_2016.csv' DELIMITER ',' NULL AS '' CSV HEADER;
COPY aux_crimes FROM '/Users/paudomingues/Documents/ITBA/OLAP/SecurityInsightsBA-OLAP/data/crimes/delitos_2017.csv' DELIMITER ',' NULL AS '' CSV HEADER;
COPY aux_crimes FROM '/Users/paudomingues/Documents/ITBA/OLAP/SecurityInsightsBA-OLAP/data/crimes/delitos_2018.csv' DELIMITER ',' NULL AS '' CSV HEADER;
COPY aux_crimes FROM '/Users/paudomingues/Documents/ITBA/OLAP/SecurityInsightsBA-OLAP/data/crimes/delitos_2019.csv' DELIMITER ',' NULL AS '' CSV HEADER;

DELETE FROM aux_crimes
WHERE NOT franja_horaria ~ '^[0-9]+$';

INSERT INTO crimes(coordinates, date_key)
SELECT ST_POINT(c.long, c.lat), d.date_key
FROM aux_crimes c
LEFT JOIN datetime d ON c.fecha = d.date AND c.franja_horaria::numeric = d.time_range AND c.lat IS NOT NULL AND c.long IS NOT NULL;


DROP TABLE aux_crimes;