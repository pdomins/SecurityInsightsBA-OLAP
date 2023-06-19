DROP TABLE IF EXISTS datetime;
CREATE TABLE datetime
(
    date_key    serial primary key,
    time_range  integer,
    date        date,
    daynbmonth  integer,
    month       integer,
    month_name  text,
    daynbweek   integer,
    daynameweek text,
    is_weekend  boolean,
    year        integer
);

INSERT INTO datetime (date, month, year, month_name, daynbweek, daynameweek, daynbmonth, is_weekend, time_range)
SELECT date_value,
       EXTRACT(month FROM date_value),
       EXTRACT(year FROM date_value),
       to_char(date_value, 'Month'),
       EXTRACT(isodow FROM date_value),
       to_char(date_value, 'Day'),
       EXTRACT(day FROM date_value),
       EXTRACT(isodow FROM date_value) IN (6, 7), -- Check if day is Saturday (6) or Sunday (7)
       generate_series(0, 23)                     -- Generate a series of numbers from 0 to 23
FROM generate_series('2016-01-01'::date, '2021-12-31'::date, '1 day') as date_value;
