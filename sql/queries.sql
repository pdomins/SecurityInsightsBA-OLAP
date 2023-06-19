-- Create a spatial index on the 'multipolygon' column in the 'neighborhoods' table
CREATE INDEX neighborhoods_multipolygon_idx ON neighborhoods USING GIST(multipolygon);

-- Create a spatial index on the 'coordinates' column in the 'crimes' table
CREATE INDEX crimes_coordinates_idx ON crimes USING GIST(coordinates);

CREATE TABLE crime_statistics (
    neighborhood TEXT,
    year INTEGER,
    average_crimes INTEGER,
    crimes_per_square_km DOUBLE PRECISION,
    crimes_per_square_meter DOUBLE PRECISION
);

WITH crimes_per_unit AS (
    SELECT n.neighborhood, d.year, COUNT(c.id) AS average_crimes, COUNT(c.id)/(n.area/1000000) AS crimes_per_square_km, COUNT(c.id)/n.area AS crimes_per_square_meter
    FROM neighborhoods n
    JOIN crimes c ON ST_Contains(n.multipolygon, c.coordinates)
    JOIN datetime d ON c.date_key = d.date_key
    GROUP BY n.neighborhood, d.year
)
INSERT INTO crime_statistics (neighborhood, year, average_crimes, crimes_per_square_km, crimes_per_square_meter)
SELECT * FROM crimes_per_unit
UNION
SELECT neighborhood, NULL, AVG(average_crimes), AVG(crimes_per_square_km), AVG(crimes_per_square_meter)
FROM crimes_per_unit
GROUP BY neighborhood
ORDER BY neighborhood, year;

