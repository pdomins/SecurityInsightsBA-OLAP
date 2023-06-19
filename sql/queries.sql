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

SELECT *, area/1000000, ST_AREA(multipolygon)*10000*1000000
FROM neighborhoods;

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

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- impact of subway stations on criminality
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1
WITH subway_buffer AS (
  SELECT id, station, line, neighborhood, ST_Buffer(coordinates, 0.00100) AS buffered_geometry, ST_area(ST_Buffer(coordinates, 0.00100))*10000*1000000 AS area_square_meters
    FROM subway_stations
)
SELECT station, d.year, line, neighborhood, COUNT(c.coordinates) AS crimes_count, COUNT(c.coordinates)/ area_square_meters AS crimes_per_square_meter
FROM crimes c, subway_buffer s, datetime d
WHERE ST_Within(c.coordinates, s.buffered_geometry) AND c.date_key = d.date_key
GROUP BY station, area_square_meters, d.year, neighborhood, line
ORDER BY crimes_per_square_meter ;

-- 2.a
WITH subway_buffer AS (
  SELECT id, station, line, neighborhood, ST_Buffer(coordinates, 0.00100) AS buffered_geometry, ST_area(ST_Buffer(coordinates, 0.00100))*10000*1000000 AS area_square_meters
    FROM subway_stations
), crimes_per_station_and_year AS (
SELECT station, d.year, line, neighborhood, COUNT(c.coordinates) AS crimes_count, COUNT(c.coordinates)/ area_square_meters AS crimes_per_square_meter
FROM crimes c, subway_buffer s, datetime d
WHERE ST_Within(c.coordinates, s.buffered_geometry) AND c.date_key = d.date_key
GROUP BY station, area_square_meters, d.year, neighborhood, line)
SELECT station, c.year, line, cs.crimes_per_square_meter - c.crimes_per_square_meter AS difference
FROM crimes_per_station_and_year c, crime_statistics cs
WHERE c.neighborhood = cs.neighborhood AND c.year = cs.year
ORDER BY difference DESC;

-- 2.b
WITH subway_buffer AS (
  SELECT id, station, line, neighborhood, ST_Buffer(coordinates, 0.00100) AS buffered_geometry, ST_area(ST_Buffer(coordinates, 0.00100))*10000*1000000 AS area_square_meters
    FROM subway_stations
), crimes_per_station_and_year AS (
SELECT station, d.year, line, neighborhood, COUNT(c.coordinates) AS crimes_count, COUNT(c.coordinates)/ area_square_meters AS crimes_per_square_meter
FROM crimes c, subway_buffer s, datetime d
WHERE ST_Within(c.coordinates, s.buffered_geometry) AND c.date_key = d.date_key
GROUP BY station, area_square_meters, d.year, neighborhood, line),
crimes_comparison AS(
    SELECT station, c.year, line, cs.crimes_per_square_meter - c.crimes_per_square_meter AS difference
        FROM crimes_per_station_and_year c, crime_statistics cs
        WHERE c.neighborhood = cs.neighborhood AND c.year = cs.year
)
SELECT line, year, AVG(difference) as average
FROM crimes_comparison
GROUP BY line, year
ORDER BY average DESC;

-- 3
-- subway stations that account for 50% of the recorded crimes
WITH subway_buffer AS (
  SELECT id, station, line, neighborhood, ST_Buffer(coordinates, 0.00100) AS buffered_geometry, ST_area(ST_Buffer(coordinates, 0.00100))*10000*1000000 AS area_square_meters
    FROM subway_stations
), crimes_per_station_and_year AS (
    SELECT station, d.year, line, neighborhood, COUNT(c.coordinates) AS crimes_count, COUNT(c.coordinates)/ area_square_meters AS crimes_per_square_meter
    FROM crimes c, subway_buffer s, datetime d
    WHERE ST_Within(c.coordinates, s.buffered_geometry) AND c.date_key = d.date_key
    GROUP BY station, area_square_meters, d.year, neighborhood, line),
total_crimes_per_year AS (
    SELECT line, year, SUM(crimes_count) AS total_crimes
    FROM crimes_per_station_and_year
    GROUP BY line, year),
sum_per_station_and_year AS(
    SELECT station, line, year, crimes_count, SUM(crimes_count) OVER (PARTITION BY year ORDER BY crimes_count DESC ROWS UNBOUNDED PRECEDING) AS cumul_crimes, SUM(crimes_count)OVER (PARTITION BY year ORDER BY crimes_count DESC ROWS UNBOUNDED PRECEDING)/(SELECT SUM(total_crimes) FROM total_crimes_per_year t WHERE t.year=c.year) AS crimes_percent
    FROM crimes_per_station_and_year c)
SELECT station, line, year, crimes_percent
FROM sum_per_station_and_year s1
WHERE cumul_crimes <= (SELECT MIN(cumul_crimes)
                     FROM sum_per_station_and_year s2
                     WHERE crimes_percent >= 0.5 AND s1.year = s2.year)
ORDER BY year, cumul_crimes;

-- 3
-- subway lines that account for 50% of the recorded crimes
WITH subway_buffer AS (
  SELECT id, station, line, neighborhood, ST_Buffer(coordinates, 0.00100) AS buffered_geometry, ST_area(ST_Buffer(coordinates, 0.00100))*10000*1000000 AS area_square_meters
    FROM subway_stations
), crimes_per_station_and_year AS (
    SELECT station, d.year, line, neighborhood, COUNT(c.coordinates) AS crimes_count, COUNT(c.coordinates)/ area_square_meters AS crimes_per_square_meter
    FROM crimes c, subway_buffer s, datetime d
    WHERE ST_Within(c.coordinates, s.buffered_geometry) AND c.date_key = d.date_key
    GROUP BY station, area_square_meters, d.year, neighborhood, line),
total_crimes_per_year AS (
    SELECT line, year, SUM(crimes_count) AS total_crimes
    FROM crimes_per_station_and_year
    GROUP BY line, year),
acc_crimes_per_line AS(
    SELECT line, year, total_crimes, SUM(total_crimes) OVER(PARTITION BY year ORDER BY total_crimes DESC ROWS UNBOUNDED PRECEDING) AS cumul_crimes, SUM(total_crimes) OVER(PARTITION BY year ORDER BY total_crimes DESC ROWS UNBOUNDED PRECEDING)/(SELECT SUM(total_crimes) FROM total_crimes_per_year t WHERE t.year=c.year) AS crimes_percent
    FROM total_crimes_per_year c
)
SELECT line, year, crimes_percent
FROM acc_crimes_per_line s1
WHERE cumul_crimes <= (SELECT MIN(cumul_crimes)
                     FROM acc_crimes_per_line s2
                     WHERE crimes_percent >= 0.5 AND s1.year = s2.year)
ORDER BY year, cumul_crimes;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- neighborhood criminality
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1
WITH difference_per_neighborhood AS
    (SELECT c1.neighborhood, c1.year, c1.crimes_count,c1.crimes_count - c2.crimes_count as difference
FROM crime_statistics c1 LEFT JOIN crime_statistics c2 ON c1.year - 1 = c2.year  AND c1.neighborhood = c2.neighborhood
WHERE c1.year IS NOT NULL AND c1.neighborhood IS NOT NULL)
SELECT year, AVG(difference)
FROM difference_per_neighborhood
GROUP BY year
ORDER BY year;

-- 2
WITH monthly_statistics AS (
    SELECT d.month, COUNT(*) AS crimes_amount
    FROM crimes c
    JOIN datetime d ON c.date_key = d.date_key
    GROUP BY d.month
),
average_crimes_amount AS (
    SELECT AVG(crimes_amount) AS avg_crimes_amount
    FROM monthly_statistics
)
SELECT ms.month, ms.crimes_amount, ac.avg_crimes_amount - ms.crimes_amount AS difference
FROM monthly_statistics ms
CROSS JOIN average_crimes_amount ac;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- crime patterns by hour of the day
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1
WITH crimes_by_hour AS (
    SELECT d.time_range, neighborhood, COUNT(*) AS total_crimes
    FROM crimes c, neighborhoods n, datetime d
    WHERE c.date_key = d.date_key AND ST_Contains(n.multipolygon, c.coordinates)
    GROUP BY d.time_range, n.neighborhood
), average_crimes_by_neighborhood AS (
SELECT neighborhood, AVG(total_crimes) AS avg_crimes
FROM crimes_by_hour
GROUP BY neighborhood
)
SELECT c.time_range, c.neighborhood, c.total_crimes
FROM crimes_by_hour c
JOIN average_crimes_by_neighborhood a ON c.neighborhood = a.neighborhood
WHERE c.total_crimes > a.avg_crimes * 1.8
ORDER BY c.neighborhood, c.time_range;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- influence of police stations
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--1
WITH distance_to_stations AS (
    SELECT c.id, ps.name, ps.neighborhood, ST_Distance(c.coordinates, ps.coordinates) AS distance
    FROM crimes c
    CROSS JOIN LATERAL (
        SELECT police_stations.name, police_stations.coordinates, police_stations.neighborhood
        FROM police_stations
        ORDER BY ST_Distance(c.coordinates, police_stations.coordinates)
        LIMIT 1
    ) AS ps)
SELECT neighborhood, AVG(distance) AS distance
FROM distance_to_stations
GROUP BY neighborhood
ORDER BY distance;
--2
WITH police_station_buffer AS (
  SELECT name, neighborhood, ST_Buffer(coordinates, 0.00500) AS buffered_geometry, ST_area(ST_Buffer(coordinates, 0.00100))*10000*1000000 AS area_square_meters
    FROM police_stations
), crimes_per_station_and_year AS (
SELECT p.name, d.year, neighborhood, COUNT(c.coordinates) AS crimes_count, COUNT(c.coordinates)/area_square_meters AS crimes_per_square_meter
FROM crimes c, police_station_buffer p, datetime d
WHERE ST_Within(c.coordinates, p.buffered_geometry) AND c.date_key = d.date_key
GROUP BY p.name, area_square_meters, d.year, neighborhood),
crimes_comparison AS(
    SELECT name, c.neighborhood, c.year, cs.crimes_per_square_meter - c.crimes_per_square_meter AS difference
        FROM crimes_per_station_and_year c, crime_statistics cs
        WHERE c.neighborhood = cs.neighborhood AND c.year = cs.year
)
SELECT name, neighborhood, AVG(difference) as average
FROM crimes_comparison
GROUP BY name, neighborhood
ORDER BY average DESC;