--import csv's as one table
CREATE TABLE total_trips AS
SELECT *
FROM read_csv_auto('C:/Users/User/Desktop/trip_data/*.csv');

--check if all rows were imported
SELECT COUNT(*)
FROM total_trips;

--check if all columns are correct
SELECT *
FROM total_trips
LIMIT 100;

--ckeck if column names are consistent and data types make sense
DESCRIBE total_trips;

--VERIFY DATA

--check for duplicate rows
SELECT COUNT(*) - COUNT(DISTINCT ride_id)
FROM total_trips;

--check for missing data in important columns
SELECT
    COUNT(*) FILTER (WHERE ride_id IS NULL) AS missing_ride_id,
    COUNT(*) FILTER (WHERE rideable_type IS NULL) AS missing_rideable_type,
    COUNT(*) FILTER (WHERE started_at IS NULL) AS missing_start_time,
    COUNT(*) FILTER (WHERE ended_at IS NULL) AS missing_end_time,
    COUNT(*) FILTER (WHERE start_station_name IS NULL) AS missing_start_station,
    COUNT(*) FILTER (WHERE end_station_name IS NULL) AS missing_end_station,
    COUNT(*) FILTER (WHERE member_casual IS NULL) AS missing_membership,
    COUNT(*) FILTER (WHERE start_lat IS NULL) AS missing_start_lat,
    COUNT(*) FILTER (WHERE start_lng IS NULL) AS missing_start_lng,
    COUNT(*) FILTER (WHERE end_lat IS NULL) AS missing_end_lat,
    COUNT(*) FILTER (WHERE end_lng IS NULL) AS missing_end_lng,
FROM total_trips;

--check how many missing both end and start station
SELECT COUNT(*)
FROM total_trips
WHERE start_station_name IS NULL
AND end_station_name IS NULL;

--check how many rows are missing start or end station
SELECT COUNT(*)
FROM total_trips
WHERE start_station_name IS NULL
OR end_station_name IS NULL;

--check if missing stations correlate with docked bikes
SELECT rideable_type, COUNT(*)
FROM total_trips
WHERE start_station_name IS NULL
OR end_station_name IS NULL
GROUP BY rideable_type;

--check if any rides have negative time
SELECT *
FROM total_trips
WHERE ended_at < started_at;

--check if all ride_id are same length
SELECT DISTINCT len(ride_id)
FROM total_trips;

--check if ridable_type are only two types
SELECT DISTINCT rideable_type
FROM total_trips
GROUP BY rideable_type;

--check if member_casual are only two types
SELECT DISTINCT member_casual
FROM total_trips
GROUP BY member_casual;

--check for unrealistic ride durations <1min, >24h
SELECT COUNT(*),
FROM total_trips
WHERE ended_at - started_at < INTERVAL '1 minute'
OR ended_at - started_at > INTERVAL '24 hours';

--calculate day of week and hour of day
SELECT started_at,
	STRFTIME(started_at, '%A') AS day_of_week, --extract weekday
	EXTRACT(HOUR FROM started_at) AS hour_of_day,
	EXTRACT(MONTH FROM started_at) AS month
FROM total_trips;


--ANALIYSE DATA

--calculate mean ride_length
SELECT
member_casual,
AVG(ended_at - started_at) AS avg_ride_length
FROM total_trips
WHERE (ended_at - started_at) >= INTERVAL '1 minute'
AND (ended_at - started_at) <= INTERVAL '24 hours'
GROUP BY member_casual;


--calculate most popular day of week
SELECT 
	strftime(started_at, '%A') AS day_of_week,
	member_casual,
	COUNT(*) AS num_of_trips
FROM total_trips
GROUP BY member_casual, day_of_week
ORDER BY num_of_trips DESC;

--calculate most popular month
SELECT 
	EXTRACT(MONTH FROM started_at) AS month,
	member_casual,
	COUNT(*) AS num_of_trips
FROM total_trips
GROUP BY member_casual, month
ORDER BY num_of_trips DESC;

--calculate most popular hour of day
SELECT 
	member_casual,
	EXTRACT(HOUR FROM started_at) AS hour_of_day,
	COUNT(*) num_of_trips,
FROM total_trips
GROUP BY member_casual, hour_of_day
ORDER BY num_of_trips DESC;

--calculate top stations used
SELECT
	station_name,
	member_casual,
	lat,
	lng,
	SUM(num_of_trips) AS total_trips
	FROM (
		SELECT start_station_name AS station_name,
			member_casual,
			start_lat AS lat,
			start_lng AS lng,
			COUNT(*) AS num_of_trips
		FROM total_trips
		WHERE start_station_name IS NOT NULL
		GROUP BY start_station_name, member_casual, start_lat, start_lng
		
		UNION ALL
		
		SELECT end_station_name AS station_name,
			member_casual,
			end_lat AS lat,
			end_lng AS lng,
			COUNT(*) AS num_of_trips
		FROM total_trips
		WHERE end_station_name IS NOT NULL
		GROUP BY end_station_name, member_casual, end_lat, end_lng
) 
	AS combined_stations
GROUP BY station_name, member_casual, lat, lng
ORDER BY total_trips DESC
LIMIT 20;
