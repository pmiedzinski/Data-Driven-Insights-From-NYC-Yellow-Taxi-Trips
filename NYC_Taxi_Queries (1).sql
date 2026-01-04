-- NYC Yellow Taxi Trips (2022) — Multiverse take-home task
-- Dataset: bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022
-- Zones:   bigquery-public-data.new_york_taxi_trips.taxi_zone_geom

-- Notes:
-- • December 2022 is incomplete (57 rows). For time-series questions (Q4, Q7) we exclude month 12.
-- • NULL tip_amount is kept (cash tips are expected and should not be imputed).
-- • For Q2/Q3 revenue-type calculations, we apply reasonable outlier caps to prevent corrupted values dominating averages.

--------------------------------------------------------------------------------
-- Q1) Top 5 taxi pick-ups (zone names)
--------------------------------------------------------------------------------
SELECT
  z.zone_name AS pickup_zone,
  z.borough   AS pickup_borough,
  COUNT(*)    AS trip_count
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022` t
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` z
  ON t.pickup_location_id = z.zone_id
WHERE EXTRACT(YEAR FROM t.pickup_datetime) = 2022
GROUP BY pickup_zone, pickup_borough
ORDER BY trip_count DESC
LIMIT 5;

--------------------------------------------------------------------------------
-- Q1) Top 5 taxi drop-offs (zone names)
--------------------------------------------------------------------------------
SELECT
  z.zone_name AS dropoff_zone,
  z.borough   AS dropoff_borough,
  COUNT(*)    AS trip_count
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022` t
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` z
  ON t.dropoff_location_id = z.zone_id
WHERE EXTRACT(YEAR FROM t.pickup_datetime) = 2022
GROUP BY dropoff_zone, dropoff_borough
ORDER BY trip_count DESC
LIMIT 5;

--------------------------------------------------------------------------------
-- Q2) Top 3 zones with highest average fare per mile (price per mile anomaly check)
-- Using SUM(fare)/SUM(distance) is more stable than AVG(fare/distance).
--------------------------------------------------------------------------------
SELECT
  z.zone_name AS pickup_zone,
  COUNT(*)    AS trip_count,
  ROUND(SUM(t.fare_amount) / SUM(t.trip_distance), 2) AS avg_price_per_mile
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022` t
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` z
  ON t.pickup_location_id = z.zone_id
WHERE EXTRACT(YEAR FROM t.pickup_datetime) = 2022
  AND t.trip_distance > 0 AND t.trip_distance <= 200
  AND t.fare_amount   > 0 AND t.fare_amount   <= 500
  AND t.total_amount  > 0 AND t.total_amount  <= 600
GROUP BY pickup_zone
HAVING COUNT(*) >= 100   -- avoid tiny-sample zones
ORDER BY avg_price_per_mile DESC
LIMIT 3;

--------------------------------------------------------------------------------
-- Q3) Staten Island pickups: total revenue by drop-off borough (total_amount)
--------------------------------------------------------------------------------
WITH si_trips AS (
  SELECT
    t.total_amount,
    dp.borough AS dropoff_borough
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022` t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` pu
    ON t.pickup_location_id = pu.zone_id
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` dp
    ON t.dropoff_location_id = dp.zone_id
  WHERE EXTRACT(YEAR FROM t.pickup_datetime) = 2022
    AND pu.borough = 'Staten Island'
    AND t.total_amount > 0 AND t.total_amount <= 600
    AND (t.tip_amount >= 0 OR t.tip_amount IS NULL)
)
SELECT
  dropoff_borough,
  COUNT(*) AS trips,
  ROUND(SUM(total_amount), 2) AS total_revenue
FROM si_trips
GROUP BY dropoff_borough
ORDER BY total_revenue DESC;

--------------------------------------------------------------------------------
-- Q3) (Detail) Top 10 drop-off zones by revenue for Staten Island pickups
--------------------------------------------------------------------------------
WITH si_trips AS (
  SELECT
    t.total_amount,
    dp.borough   AS dropoff_borough,
    dp.zone_name AS dropoff_zone
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022` t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` pu
    ON t.pickup_location_id = pu.zone_id
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` dp
    ON t.dropoff_location_id = dp.zone_id
  WHERE EXTRACT(YEAR FROM t.pickup_datetime) = 2022
    AND pu.borough = 'Staten Island'
    AND t.total_amount > 0 AND t.total_amount <= 600
    AND (t.tip_amount >= 0 OR t.tip_amount IS NULL)
)
SELECT
  dropoff_borough,
  dropoff_zone,
  ROUND(SUM(total_amount), 2) AS total_revenue
FROM si_trips
GROUP BY dropoff_borough, dropoff_zone
ORDER BY total_revenue DESC
LIMIT 10;

--------------------------------------------------------------------------------
-- Q4) Staten Island tips by UK quarter (Apr-Jun=Q1, Jul-Sep=Q2, Oct-Dec=Q3, Jan-Mar=Q4)
-- Note: This uses 2022 only; for this task Q4 refers to Jan–Mar 2022 (per instructions).
-- Also note: December 2022 is incomplete (57 rows). Consider excluding month 12 for a cleaner comparison.
--------------------------------------------------------------------------------
SELECT
  CASE
    WHEN EXTRACT(MONTH FROM t.pickup_datetime) BETWEEN 4 AND 6  THEN 'Q1 (Apr–Jun)'
    WHEN EXTRACT(MONTH FROM t.pickup_datetime) BETWEEN 7 AND 9  THEN 'Q2 (Jul–Sep)'
    WHEN EXTRACT(MONTH FROM t.pickup_datetime) BETWEEN 10 AND 12 THEN 'Q3 (Oct–Dec)'
    WHEN EXTRACT(MONTH FROM t.pickup_datetime) BETWEEN 1 AND 3  THEN 'Q4 (Jan–Mar)'
  END AS uk_quarter,
  ROUND(SUM(IFNULL(t.tip_amount, 0)), 2) AS total_tips
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022` t
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` z
  ON t.pickup_location_id = z.zone_id
WHERE EXTRACT(YEAR FROM t.pickup_datetime) = 2022
  AND z.borough = 'Staten Island'
  AND (t.tip_amount >= 0 OR t.tip_amount IS NULL)
GROUP BY uk_quarter
ORDER BY uk_quarter;

--------------------------------------------------------------------------------
-- Q5) In QX (highest-tipping quarter from Q4), find Staten Island pickup zones with > $100 tips
-- Here we assume QX = Q2 (Jul–Sep) based on the dataset output.
--------------------------------------------------------------------------------
WITH si_q2 AS (
  SELECT
    z.zone_name AS pickup_zone,
    IFNULL(t.tip_amount, 0) AS tip_amount
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022` t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` z
    ON t.pickup_location_id = z.zone_id
  WHERE EXTRACT(YEAR FROM t.pickup_datetime) = 2022
    AND z.borough = 'Staten Island'
    AND EXTRACT(MONTH FROM t.pickup_datetime) BETWEEN 7 AND 9
    AND (t.tip_amount >= 0 OR t.tip_amount IS NULL)
)
SELECT
  pickup_zone,
  ROUND(SUM(tip_amount), 2) AS total_tips
FROM si_q2
GROUP BY pickup_zone
HAVING total_tips > 100
ORDER BY total_tips DESC;

--------------------------------------------------------------------------------
-- Q6) Tip efficiency in QX (tips per trip), min 10 trips
--------------------------------------------------------------------------------
WITH si_q2 AS (
  SELECT
    z.zone_name AS pickup_zone,
    IFNULL(t.tip_amount, 0) AS tip_amount
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022` t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` z
    ON t.pickup_location_id = z.zone_id
  WHERE EXTRACT(YEAR FROM t.pickup_datetime) = 2022
    AND z.borough = 'Staten Island'
    AND EXTRACT(MONTH FROM t.pickup_datetime) BETWEEN 7 AND 9
    AND (t.tip_amount >= 0 OR t.tip_amount IS NULL)
)
SELECT
  pickup_zone,
  COUNT(*) AS trip_count,
  ROUND(SUM(tip_amount), 2) AS total_tips,
  ROUND(SUM(tip_amount) / COUNT(*), 2) AS avg_tip_per_trip
FROM si_q2
GROUP BY pickup_zone
HAVING trip_count >= 10
ORDER BY avg_tip_per_trip DESC;

--------------------------------------------------------------------------------
-- Q7) Staten Island trips by month (exclude Dec due to incompleteness)
--------------------------------------------------------------------------------
WITH si_trips AS (
  SELECT
    t.pickup_datetime
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022` t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` z
    ON t.pickup_location_id = z.zone_id
  WHERE EXTRACT(YEAR FROM t.pickup_datetime) = 2022
    AND z.borough = 'Staten Island'
    AND EXTRACT(MONTH FROM t.pickup_datetime) BETWEEN 1 AND 11
)
SELECT
  FORMAT_DATE('%Y-%m', DATE(pickup_datetime)) AS month_label,
  EXTRACT(MONTH FROM pickup_datetime) AS month_num,
  COUNT(*) AS trip_count,
  CASE WHEN COUNT(*) = MAX(COUNT(*)) OVER () THEN 'Peak month' ELSE '' END AS peak_flag
FROM si_trips
GROUP BY month_label, month_num
ORDER BY month_num;

-- Q8 is a narrative insight section (see report and slide 8).
