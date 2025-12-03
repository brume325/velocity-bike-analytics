# Partie 1 — Découverte et choix des sources

Ce document liste les tables sources identifiées dans le dump `init/backup.sql` et justifie leur utilisation pour construire le Dashboard Marketing demandé.

Tables retenues

- `raw.bike_rentals` (fait principal)
  - Contient chaque location (`rental_id`, `bike_id`, `user_id`, `start_station_id`, `end_station_id`, `start_t`, `end_t`).
  - Rôle : table de fait (événements de location). C'est la source pour les métriques métier (nombre de locations, durée moyenne, utilisateurs uniques).

- `raw.bikes` (dimension)
  - Contient caractéristiques du vélo (`bike_id`, `bike_type`, `model_name`, `status`).
  - Rôle : dimension pour segmenter par type de vélo.

- `raw.bike_stations` (dimension)
  - Localisation des stations (`station_id`, `station_name`, `latitude`, `longitude`, `capacity`, `city_id`).
  - Rôle : dimension géographique (ville, station) pour agrégation par ville / station.

- `raw.cities` (dimension)
  - Contient `city_id` et `city_name`.
  - Rôle : résolution des `city_id` en nom de ville pour reporting.

- `raw.user_accounts` (dimension / PII)
  - Contient informations utilisateur (`user_id`, `first_name`, `last_name`, `email`, `birthdate`, `subscription_id`).
  - Rôle : permet calculer l'âge, segmenter par type d'abonnement. Attention PII — ne doit pas être exposé au Marketing.

- `raw.subscriptions` (dimension)
  - Contient `subscription_id`, `subscription_type`, `price_eur`.
  - Rôle : permettre agrégations par type d'abonnement.

Tables complémentaires (optionnelles)

- `raw.user_session_logs` : utile pour détecter comptes inactifs/actifs, mais pas nécessaire pour les KPI principaux.
- `raw.weather_forecast_hourly` : possibilité d'enrichir les analyses (corrélation météo vs usage).

Synthèse

Pour répondre aux indicateurs demandés (total_rentals, average_duration_minutes, unique_users, top villes, répartition par type d'abonnement), la chaîne principale est :

raw.bike_rentals (fait) -> jointures vers raw.bikes, raw.bike_stations (+ raw.cities), raw.user_accounts -> enrichir avec subscription_type via raw.subscriptions.

Stratégie Médaillon

- Raw : données telles quelles (dans `raw.*`).
- Silver : nettoyage et typage (cast des timestamps, calcul des durées, suppression des trajets courts < 2 minutes, normalisation des coordonnées).
- Gold : table agrégée `analytics_velocity.gold_daily_activity` (par jour / ville / station / bike_type / subscription_type) prête pour Metabase.

Remarque sur la gouvernance

- Les données PII (raw.user_accounts.email, noms, birthdate) ne seront pas exposées au rôle `marketing_user`. Seule la table Gold agrégée est accessible au marketing.
