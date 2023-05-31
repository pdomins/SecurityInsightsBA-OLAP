DROP TABLE IF EXISTS crimes;

CREATE TABLE crimes(
    id serial primary key,
    coordinates geometry,
    date_key integer references date(date_key),
    time_slot numeric
);

DROP TABLE IF EXISTS aux_crimes;
CREATE TABLE aux_crimes(
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


INSERT INTO crimes(coordinates, date_key, time_slot)
SELECT ST_POINT(c.long, c.lat), d.date_key,
    CASE WHEN c.franja_horaria ~ '^\d+(\.\d+)?$' THEN CAST(c.franja_horaria AS numeric)
    END
FROM aux_crimes c
LEFT JOIN date d ON c.fecha = d.date AND c.lat IS NOT NULL AND c.long IS NOT NULL;

DROP TABLE aux_crimes;