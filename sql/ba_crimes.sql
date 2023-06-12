DROP TABLE IF EXISTS crimes;

DROP TABLE IF EXISTS crime_type, crime_subtype;
CREATE TABLE crime_type
(
    type_id     serial primary key,
    description text
);
CREATE TABLE crime_subtype
(
    subtype_id  serial primary key,
    type_id     integer references crime_type (type_id),
    description text
);

CREATE TABLE crimes
(
    id          serial primary key,
    coordinates geometry,
    date_key    integer references datetime (date_key),
    type_key    integer references crime_type (type_id),
    subtype_key integer references crime_subtype (subtype_id),
    CHECK ((type_key IS NOT NULL AND subtype_key IS NULL) OR
           (type_key IS NULL AND subtype_key IS NOT NULL) OR
           (type_key IS NULL AND subtype_key IS NULL))
);



DROP TABLE IF EXISTS aux_crimes, aux_crimes2;
CREATE TEMPORARY TABLE aux_crimes
(
    id                  numeric,
    fecha               date,
    franja_horaria      text,
    tipo_delito         text,
    subtipo_delito      text,
    cantidad_registrada text,
    comuna              text,
    barrio              text,
    lat                 numeric,
    long                numeric
);

CREATE TEMPORARY TABLE aux_crimes2
(
    id_mapa        text,
    anio           numeric,
    mes            text,
    dia            text,
    fecha          date,
    franja_horaria text,
    tipo_delito    text,
    subtipo_delito text,
    uso_armas      text,
    barrio         text,
    comuna         text,
    lat            text,
    long           text,
    victimas       numeric
);

-- CRIMES 16-17-18-19 ------------------------------------------------------------------------------------------------------------
COPY aux_crimes FROM '/Users/paudomingues/Documents/ITBA/OLAP/SecurityInsightsBA-OLAP/data/crimes/delitos_2016.csv' DELIMITER ',' NULL AS '' CSV HEADER;
COPY aux_crimes FROM '/Users/paudomingues/Documents/ITBA/OLAP/SecurityInsightsBA-OLAP/data/crimes/delitos_2017.csv' DELIMITER ',' NULL AS '' CSV HEADER;
COPY aux_crimes FROM '/Users/paudomingues/Documents/ITBA/OLAP/SecurityInsightsBA-OLAP/data/crimes/delitos_2018.csv' DELIMITER ',' NULL AS '' CSV HEADER;
COPY aux_crimes FROM '/Users/paudomingues/Documents/ITBA/OLAP/SecurityInsightsBA-OLAP/data/crimes/delitos_2019.csv' DELIMITER ',' NULL AS '' CSV HEADER;
COPY aux_crimes2 FROM '/Users/paudomingues/Documents/ITBA/OLAP/SecurityInsightsBA-OLAP/data/crimes/delitos_2020.csv' DELIMITER ',' NULL AS '' CSV HEADER;
COPY aux_crimes2 FROM '/Users/paudomingues/Documents/ITBA/OLAP/SecurityInsightsBA-OLAP/data/crimes/delitos_2021.csv' DELIMITER ',' NULL AS '' CSV HEADER;

DELETE
FROM aux_crimes
WHERE NOT franja_horaria ~ '^[0-9]+$';

DELETE
FROM aux_crimes2
WHERE NOT franja_horaria ~ '^[0-9]+$'
   OR lat = 'SD'
   OR long = 'SD';

INSERT INTO crime_type (description)
SELECT DISTINCT tipo_delito
FROM (SELECT tipo_delito
      FROM aux_crimes
      UNION
      SELECT tipo_delito
      FROM aux_crimes2) as actdac2td;

INSERT INTO crime_subtype (description, type_id)
SELECT s.subtipo_delito, ct.type_id
FROM (SELECT DISTINCT tipo_delito, subtipo_delito
      FROM aux_crimes
      UNION
      SELECT DISTINCT tipo_delito, subtipo_delito
      FROM aux_crimes2) as s
         JOIN crime_type ct ON ct.description = s.tipo_delito
WHERE s.subtipo_delito IS NOT NULL;

INSERT INTO crimes(coordinates, date_key, type_key, subtype_key)
SELECT ST_POINT(c.long, c.lat),
       d.date_key,
       CASE WHEN c.subtipo_delito IS NOT NULL THEN NULL ELSE ct.type_id END,
       CASE WHEN c.subtipo_delito IS NOT NULL THEN cst.subtype_id END
FROM aux_crimes c
         JOIN datetime d ON c.fecha = d.date AND c.franja_horaria::numeric = d.time_range AND c.lat IS NOT NULL AND
                            c.long IS NOT NULL
         LEFT JOIN crime_type ct ON ct.description = c.tipo_delito
         LEFT JOIN crime_subtype cst ON cst.description = c.subtipo_delito;

INSERT INTO crimes(coordinates, date_key, type_key, subtype_key)
SELECT ST_POINT(c.long::numeric, c.lat::numeric),
       d.date_key,
       CASE WHEN c.subtipo_delito IS NOT NULL THEN NULL ELSE ct.type_id END,
       CASE WHEN c.subtipo_delito IS NOT NULL THEN cst.subtype_id END
FROM aux_crimes2 c
         JOIN datetime d ON c.fecha = d.date AND c.franja_horaria::numeric = d.time_range AND c.lat IS NOT NULL AND
                            c.long IS NOT NULL
         LEFT JOIN crime_type ct ON ct.description = c.tipo_delito
         LEFT JOIN crime_subtype cst ON cst.description = c.subtipo_delito;

DROP TABLE aux_crimes, aux_crimes2;

