-- SQL script : 04_transformations.sql
-- But : créer schema silver, créer tables silver nettoyées, créer schema analytics_velocity (gold) et la table gold_daily_activity

BEGIN;

-- 1) Créer les schémas (si non existants)
CREATE SCHEMA IF NOT EXISTS silver AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS analytics_velocity AUTHORIZATION postgres;

-- 2) Exemple : table silver.bike_rentals (nettoyage & typage)
DROP TABLE IF EXISTS silver.bike_rentals;
CREATE TABLE silver.bike_rentals AS
SELECT
  rental_id,
  bike_id,
  user_id,
  start_station_id,
  end_station_id,
  -- conversion texte -> timestamp si possible
  NULLIF(trim(start_t),'')::timestamp without time zone AS start_ts,
  NULLIF(trim(end_t),'')::timestamp without time zone AS end_ts,
  -- duration in minutes
  CASE
    WHEN NULLIF(trim(start_t),'') IS NOT NULL AND NULLIF(trim(end_t),'') IS NOT NULL
    THEN EXTRACT(EPOCH FROM (NULLIF(trim(end_t),'')::timestamp - NULLIF(trim(start_t),'')::timestamp))/60.0
    ELSE NULL
  END AS duration_minutes
FROM raw.bike_rentals;

-- 2b) Nettoyage stations : convertir lat/long en numeric
DROP TABLE IF EXISTS silver.bike_stations;
CREATE TABLE silver.bike_stations AS
SELECT
  station_id,
  station_name,
  NULLIF(trim(latitude),'')::numeric AS latitude,
  NULLIF(trim(longitude),'')::numeric AS longitude,
  capacity,
  city_id
FROM raw.bike_stations;

-- 2c) Silver user accounts : typer birthdate / registration
DROP TABLE IF EXISTS silver.user_accounts;
CREATE TABLE silver.user_accounts AS
SELECT
  user_id,
  first_name,
  last_name,
  email,
  NULLIF(trim(birthdate),'')::date AS birthdate,
  NULLIF(trim(registration_date),'')::timestamp AS registration_ts,
  subscription_id
FROM raw.user_accounts;

-- 3) Gold : table agrégée journalière (simplifiée pour fiabilité)
DROP TABLE IF EXISTS analytics_velocity.gold_daily_activity;
CREATE TABLE analytics_velocity.gold_daily_activity AS
SELECT
  (r.start_ts::date) AS day,
  COALESCE(cit.city_name, 'Unknown') AS city,
  COUNT(*) AS total_rentals,
  AVG(r.duration_minutes) AS average_duration_minutes,
  COUNT(DISTINCT r.user_id) AS unique_users
FROM silver.bike_rentals r
LEFT JOIN silver.bike_stations sst ON r.start_station_id = sst.station_id
LEFT JOIN raw.cities cit ON sst.city_id = cit.city_id
WHERE r.start_ts IS NOT NULL
  AND r.duration_minutes IS NOT NULL
  AND r.duration_minutes >= 0  -- tous les trajets valides
GROUP BY 1, 2
ORDER BY day DESC, city;

-- Indexes utiles
CREATE INDEX IF NOT EXISTS idx_gold_day_city ON analytics_velocity.gold_daily_activity (day, city);

COMMIT;

-- Fin du script de transformations
