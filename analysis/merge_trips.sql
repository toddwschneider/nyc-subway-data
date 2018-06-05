CREATE TABLE possible_bad_trips AS
SELECT *
FROM realtime_trips
WHERE route_mta_id NOT IN ('FS', 'GS', 'H')
  AND most_recently_observed_at - first_observed_at < '10 minutes'::interval;

CREATE TABLE merge_candidates AS
SELECT
  bad.id AS bad_trip_id,
  t.id AS candidate_trip_id
FROM possible_bad_trips bad
  INNER JOIN realtime_trips t
    ON bad.route_mta_id = t.route_mta_id
    AND bad.direction = t.direction
    AND bad.start_date = t.start_date
    AND bad.train_id = t.train_id
    AND bad.id != t.id
    AND t.first_observed_at > bad.most_recently_observed_at
    AND t.most_recently_observed_at - t.first_observed_at >= '10 minutes'::interval
ORDER BY bad.id, t.id;

CREATE TABLE merge_candidates_single as
SELECT *
FROM merge_candidates
WHERE bad_trip_id IN (SELECT bad_trip_id FROM merge_candidates GROUP BY bad_trip_id HAVING COUNT(*) = 1);

UPDATE stop_time_updates
SET realtime_trip_id = merge_candidates_single.candidate_trip_id
FROM merge_candidates_single
WHERE stop_time_updates.realtime_trip_id = merge_candidates_single.bad_trip_id;

UPDATE vehicle_positions
SET realtime_trip_id = merge_candidates_single.candidate_trip_id
FROM merge_candidates_single
WHERE vehicle_positions.realtime_trip_id = merge_candidates_single.bad_trip_id;
