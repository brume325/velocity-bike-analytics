# Projet VéloCity – Architecture Médaillon & Analytics

Ce projet met en place une plateforme analytics pour les données de location de vélos de VéloCity.

## Objectifs

- Explorer et documenter les sources de données (OpenMetadata).
- Mettre en place une architecture Médaillon dans PostgreSQL :
  - Schéma raw
  - Schéma silver
  - Schéma gold (table `gold_daily_activity`).
- Construire un dashboard marketing dans Metabase.
- Mettre en place la sécurité (moindre privilège, Row Level Security).
- Étendre l’environnement avec Spark + MySQL et l’ingestion d’un jeu de données CSV/JSON.

## Stack technique

- Docker
- OpenMetadata
- PostgreSQL
- Metabase
- Spark
- MySQL

## Structure du dépôt

- `docs/` : rapport, architecture, gestion de projet.
- `sql/` : scripts de création/transformations (raw → silver → gold, sécurité).
- `spark/` : notebooks et scripts Spark.
- `data/` : fichiers CSV/JSON d’entrée.
- `metabase/` : exports et captures du dashboard.
- `docker/` : fichiers docker-compose / configuration.

## Organisation (rôles simulés)

- Data Engineer Infra : environnement Docker, bases, outils.
- Data Engineer Modélisation : schémas raw/silver/gold, SQL, qualité.
- Data Analyst : dashboard Metabase, KPIs, rapport fonctionnel.
