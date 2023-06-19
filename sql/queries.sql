-- Create a spatial index on the 'multipolygon' column in the 'neighborhoods' table
CREATE INDEX neighborhoods_multipolygon_idx ON neighborhoods USING GIST(multipolygon);

-- Create a spatial index on the 'coordinates' column in the 'crimes' table
CREATE INDEX crimes_coordinates_idx ON crimes USING GIST(coordinates);

DROP TABLE crime_statistics;
CREATE TABLE crime_statistics (
    neighborhood TEXT,
    year INTEGER,
    crimes_count INTEGER,
    crimes_per_square_km DOUBLE PRECISION,
    crimes_per_square_meter DOUBLE PRECISION
);
WITH crimes_per_unit AS (
    SELECT n.neighborhood, d.year, COUNT(c.id) AS crimes_count, COUNT(c.id)/(n.area/1000000) AS crimes_per_square_km, COUNT(c.id)/n.area AS crimes_per_square_meter
    FROM neighborhoods n
    JOIN crimes c ON ST_Contains(n.multipolygon, c.coordinates)
    JOIN datetime d ON c.date_key = d.date_key
    GROUP BY n.neighborhood, d.year
)
INSERT INTO crime_statistics (neighborhood, year, crimes_count, crimes_per_square_km, crimes_per_square_meter)
SELECT * FROM crimes_per_unit
UNION
SELECT cpu.neighborhood, NULL, SUM(crimes_count), SUM(crimes_count)/(n.area/1000000), SUM(crimes_count)/n.area
FROM crimes_per_unit cpu, neighborhoods n
WHERE cpu.neighborhood = n.neighborhood
GROUP BY cpu.neighborhood, n.area
UNION
SELECT NULL, year, SUM(crimes_count), SUM(crimes_count)/((SELECT SUM(area) FROM neighborhoods)/1000000), SUM(crimes_count)/(SELECT SUM(area) FROM neighborhoods)
FROM crimes_per_unit
GROUP BY year
ORDER BY neighborhood, year;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- historical trends and all-time highs
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1
SELECT n.commune, cs.year, SUM(cs.crimes_count) AS crimes_count, AVG(cs.crimes_per_square_km) AS crimes_per_square_km
FROM crime_statistics cs, neighborhoods n
WHERE cs.neighborhood = n.neighborhood AND cs.neighborhood IS NOT NULL and cs.year IS NOT NULL
GROUP BY n.commune, cs.year
ORDER BY crimes_per_square_km DESC;

-- 3
WITH max_year AS (
SELECT year, crimes_count, crimes_per_square_km
FROM crime_statistics
WHERE neighborhood IS NULL
ORDER BY crimes_per_square_km DESC
LIMIT 1),
max_year_crimes AS (
    SELECT c.*
    FROM crimes c, datetime d, max_year my
    WHERE c.date_key = d.date_key AND d.year = my.year
),
crimes_with_types AS (
    SELECT c.id, ct.description as type
    FROM max_year_crimes c, crime_type ct, crime_subtype cs
    WHERE c.type_key = ct.type_id OR (c.subtype_key = cs.subtype_id AND cs.type_id=ct.type_id)
    GROUP BY c.id, ct.description
)
SELECT type, COUNT(*) as crimes_amount
FROM crimes_with_types
GROUP BY type;