/*
consider checking/running merge_trips.sql before running these queries
*/

CREATE TABLE estimated_stop_times AS
SELECT DISTINCT ON (realtime_trip_id, stop_mta_id) *
FROM stop_time_updates
ORDER BY realtime_trip_id, stop_mta_id, observed_at DESC;

DELETE FROM estimated_stop_times
WHERE COALESCE(arrival_time, departure_time) > observed_at + '5 minutes'::interval
  OR COALESCE(arrival_time, departure_time) < observed_at - '20 minutes'::interval;

CREATE INDEX ON estimated_stop_times (realtime_trip_id);
CREATE INDEX ON estimated_stop_times (stop_mta_id);

CREATE TEMP TABLE tmp_realtime_trips AS
SELECT
  id,
  direction,
  CASE route_mta_id WHEN '5X' THEN '5' ELSE route_mta_id END AS route_mta_id
FROM realtime_trips;
CREATE UNIQUE INDEX ON tmp_realtime_trips (id);

CREATE TABLE times_between_trains AS
SELECT
  u.stop_mta_id,
  s.name AS stop_name,
  t.route_mta_id,
  t.direction,
  COALESCE(u.departure_time, u.arrival_time) AT TIME ZONE 'UTC' AT TIME ZONE 'America/New_York' AS departure_time,
  EXTRACT(
    EPOCH FROM
    LEAD(COALESCE(u.departure_time, u.arrival_time), 1) OVER w - COALESCE(u.departure_time, u.arrival_time)
  ) AS seconds_until_next_departure,
  u.realtime_trip_id,
  LEAD(u.realtime_trip_id, 1) OVER w AS next_realtime_trip_id
FROM estimated_stop_times u
  INNER JOIN tmp_realtime_trips t ON u.realtime_trip_id = t.id
  INNER JOIN stops s ON u.stop_mta_id = s.mta_id
WINDOW w AS (
  PARTITION BY u.stop_mta_id, t.route_mta_id, t.direction
  ORDER BY COALESCE(u.arrival_time, u.departure_time)
)
ORDER BY u.stop_mta_id, t.route_mta_id, t.direction, COALESCE(u.arrival_time, u.departure_time);

-- remove probable data errors. less than 0.2% of rows
DELETE FROM times_between_trains WHERE seconds_until_next_departure < 20;

-- remove likely scheduled maintenance windows
DELETE FROM times_between_trains WHERE seconds_until_next_departure > 60 * 60 * 2;

CREATE INDEX ON times_between_trains (stop_mta_id);
CREATE INDEX ON times_between_trains (route_mta_id);

CREATE TABLE route_stop_direction_counts AS
SELECT route_mta_id, stop_mta_id, direction, COUNT(*)
FROM times_between_trains
GROUP BY route_mta_id, stop_mta_id, direction;

CREATE TABLE subway_data_clean AS
SELECT
  t.realtime_trip_id,
  t.stop_mta_id,
  t.route_mta_id,
  t.direction,
  t.departure_time,
  t.seconds_until_next_departure
FROM times_between_trains t
  INNER JOIN route_stop_direction_counts c
    ON t.stop_mta_id = c.stop_mta_id
    AND t.route_mta_id = c.route_mta_id
    AND t.direction = c.direction
WHERE seconds_until_next_departure BETWEEN 20 AND (60 * 60 * 2)
  AND (
    c.count > 1000
    OR (c.route_mta_id = 'Z' AND c.count > 300)
  );

CREATE TABLE station_to_station_travel_times AS
SELECT
  t1.realtime_trip_id,
  rt.route_mta_id,
  t1.stop_mta_id AS from_stop_mta_id,
  t2.stop_mta_id AS to_stop_mta_id,
  t1.departure_time,
  t2.arrival_time,
  EXTRACT(EPOCH FROM t2.arrival_time - t1.departure_time) AS duration
FROM estimated_stop_times t1
  INNER JOIN estimated_stop_times t2
    ON t1.realtime_trip_id = t2.realtime_trip_id
    AND t2.arrival_time > t1.departure_time
  INNER JOIN realtime_trips rt
    ON t1.realtime_trip_id = rt.id
WHERE t2.arrival_time IS NOT NULL
  AND t1.departure_time IS NOT NULL
ORDER BY t1.realtime_trip_id, t1.departure_time, t2.arrival_time;

CREATE TABLE station_to_station_summary AS
SELECT
  route_mta_id,
  from_stop_mta_id,
  to_stop_mta_id,
  COUNT(*) AS trips,
  percentile_cont(0.1) WITHIN GROUP (ORDER BY duration) AS pct10,
  percentile_cont(0.25) WITHIN GROUP (ORDER BY duration) AS pct25,
  percentile_cont(0.5) WITHIN GROUP (ORDER BY duration) AS pct50,
  percentile_cont(0.75) WITHIN GROUP (ORDER BY duration) AS pct75,
  percentile_cont(0.9) WITHIN GROUP (ORDER BY duration) AS pct90,
  AVG(duration) AS mean
FROM station_to_station_travel_times
WHERE EXTRACT(dow FROM departure_time) BETWEEN 1 AND 5
  AND EXTRACT(hour FROM departure_time) BETWEEN 7 AND 19
  AND duration BETWEEN 15 AND (6 * 60 * 60)
GROUP BY route_mta_id, from_stop_mta_id, to_stop_mta_id
ORDER BY from_stop_mta_id, to_stop_mta_id, route_mta_id;

CREATE TABLE station_to_station_summary_yearly AS
SELECT
  route_mta_id,
  from_stop_mta_id,
  to_stop_mta_id,
  EXTRACT(year FROM departure_time) AS year,
  COUNT(*) AS trips,
  percentile_cont(0.1) WITHIN GROUP (ORDER BY duration) AS pct10,
  percentile_cont(0.25) WITHIN GROUP (ORDER BY duration) AS pct25,
  percentile_cont(0.5) WITHIN GROUP (ORDER BY duration) AS pct50,
  percentile_cont(0.75) WITHIN GROUP (ORDER BY duration) AS pct75,
  percentile_cont(0.9) WITHIN GROUP (ORDER BY duration) AS pct90,
  AVG(duration) AS mean
FROM station_to_station_travel_times
WHERE EXTRACT(dow FROM departure_time) BETWEEN 1 AND 5
  AND EXTRACT(hour FROM departure_time) BETWEEN 7 AND 19
  AND duration BETWEEN 15 AND (6 * 60 * 60)
GROUP BY route_mta_id, from_stop_mta_id, to_stop_mta_id, year
ORDER BY from_stop_mta_id, to_stop_mta_id, route_mta_id, year;
