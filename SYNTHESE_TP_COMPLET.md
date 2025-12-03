# TP Cycle de Vie de la Donnée - Synthèse Complète

## Vue d'ensemble

Ce projet implémente un pipeline complet de données suivant le pattern medallion (Raw -> Silver -> Gold) pour VéloCity, une entreprise de location de vélos en libre-service.

**Objectif** : Fournir au service Marketing un Dashboard pour suivre l'activité quotidienne (locations, durées, utilisateurs, par ville).

**Branche GitHub** : feature/docker-infrastructure  
**Propriétaire** : brume325  
**Date** : 3 décembre 2025

---

## Architecture Globale

```
Raw Layer (docker/init/backup.sql)
   |
   | (import via scripts/import_backup_fixed.ps1)
   |
   v
Silver Layer (sql/04_transformations.sql)
   - Nettoyage et typage des données
   - Conversion timestamps, calcul durées
   - Schémas : silver.bike_rentals, silver.bike_stations, silver.user_accounts
   |
   v
Gold Layer (sql/04_transformations.sql)
   - Agrégations métier
   - Schema: analytics_velocity.gold_daily_activity
   - Dimensions: day, city
   - Métriques: total_rentals, average_duration_minutes, unique_users
   |
   v
Security (sql/05_security.sql)
   - Rôles PostgreSQL: marketing_user, manager_lyon
   - RLS (Row-Level Security) : manager_lyon voir uniquement Lyon
   - Révokations sur raw/silver
   |
   v
Dashboard Metabase
   - Chart 1 : Évolution total_rentals
   - Chart 2 : Top 3 villes
   - Chart 3 : Durée moyenne par ville
```

---

## Livrables Partie 1 - Découverte des Sources

Fichier : `docs/part1_sources.md`

Contient :
- Liste des tables sources (bike_rentals, bike_stations, user_accounts, cities)
- Justification de la sélection (tables de fait vs dimensions)
- Analyse de qualité des données (anomalies, types mal formés, etc.)

---

## Livrables Partie 2 - Transformations Medallion

Fichiers : `sql/04_transformations.sql` + `sql/05_security.sql`

### Schéma Silver (Nettoyage)

**silver.bike_rentals**
- Entrées : raw.bike_rentals
- Transformations :
  - start_t, end_t : conversion TEXT -> TIMESTAMP
  - Calcul duration_minutes : EXTRACT(EPOCH) / 60
  - Filtre : exclusion trajets < 2 minutes
- Sorties : (rental_id, bike_id, user_id, start_station_id, end_station_id, start_ts, end_ts, duration_minutes)

**silver.bike_stations**
- Entrées : raw.bike_stations
- Transformations :
  - latitude, longitude : TEXT -> NUMERIC
- Sorties : (station_id, station_name, latitude, longitude, capacity, city_id)

**silver.user_accounts**
- Entrées : raw.user_accounts
- Transformations :
  - birthdate, registration_date : TEXT -> DATE/TIMESTAMP
- Sorties : (user_id, first_name, last_name, email, birthdate, registration_date, subscription_type)

### Schéma Gold (Agrégations)

**analytics_velocity.gold_daily_activity**
- Entrées : silver.bike_rentals JOIN silver.bike_stations JOIN silver.user_accounts
- Agrégation : GROUP BY day, city
- Colonnes :
  - day (DATE)
  - city (VARCHAR)
  - total_rentals (COUNT(*))
  - average_duration_minutes (AVG(duration_minutes))
  - unique_users (COUNT(DISTINCT user_id))

**Sortie** : 1 ligne par jour/ville avec métriques agrégées

---

## Livrables Partie 3 - Visualisation Metabase

Fichier : `docs/PARTIE3_METABASE_DASHBOARD.md`

Contient les instructions détaillées pour :
1. Configuration de PostgreSQL dans Metabase
2. Création de 3 charts :
   - Chart 1 (Courbe) : Évolution temporelle total_rentals
   - Chart 2 (Bar) : Top 3 villes
   - Chart 3 (Indicateur) : Durée moyenne par ville
3. Assembly du dashboard "Suivi Activité VéloCity"
4. Export et documentation

---

## Livrables Partie 4 - Sécurité et Gouvernance

Fichier : `sql/05_security.sql`

### Création des rôles

```sql
CREATE ROLE marketing_user LOGIN PASSWORD 'changeme';
CREATE ROLE manager_lyon LOGIN PASSWORD 'changeme';
```

### Révokations (Moindre Privilège)

```sql
REVOKE ALL ON SCHEMA raw FROM marketing_user;
REVOKE ALL ON SCHEMA silver FROM marketing_user;
REVOKE ALL ON SCHEMA raw FROM manager_lyon;
REVOKE ALL ON SCHEMA silver FROM manager_lyon;
```

### Grants (Accès Gold)

```sql
GRANT USAGE ON SCHEMA analytics_velocity TO marketing_user;
GRANT SELECT ON analytics_velocity.gold_daily_activity TO marketing_user;
GRANT USAGE ON SCHEMA analytics_velocity TO manager_lyon;
GRANT SELECT ON analytics_velocity.gold_daily_activity TO manager_lyon;
```

### Row-Level Security (RLS)

```sql
ALTER TABLE analytics_velocity.gold_daily_activity ENABLE ROW LEVEL SECURITY;
CREATE POLICY manager_lyon_policy ON analytics_velocity.gold_daily_activity
  FOR SELECT
  TO manager_lyon
  USING (city = 'Lyon');
```

### Résultats Attendus

| Rôle | raw.* | silver.* | gold.* | Filtrage |
|------|-------|----------|--------|----------|
| marketing_user | REVOKED | REVOKED | SELECT | Aucun (tous les villes) |
| manager_lyon | REVOKED | REVOKED | SELECT | city = 'Lyon' (RLS) |
| postgres (admin) | FULL | FULL | FULL | Aucun |

---

## Fichiers de Support

### Scripts d'Exécution

1. **scripts/import_backup.ps1** (original)
   - Importe raw.* depuis docker/init/backup.sql
   - Compatible PowerShell 5.1

2. **scripts/import_backup_fixed.ps1** (optimisé)
   - Version nettoyée (recommandée)

3. **scripts/run_full_pipeline.ps1** (automatisé)
   - Exécute : import + 04_transformations + 05_security + validate_db.py
   - Argument : -PgPassword (mot de passe PostgreSQL)
   - Génère : logs/validation_report.txt

### Validation et CI

1. **notebooks/validate_db.py**
   - Vérifie row counts : raw -> silver -> gold
   - Valide agrégats (sommes, moyennes)
   - Rapport : logs/validation_report.txt

2. **.github/workflows/ci-pipeline.yml**
   - Exécution automatique sur push
   - PostgreSQL 14 service
   - Artefacts logs/

### Documentation

1. **README_TP.md** : Guide général et architecture
2. **LIVRABLES.md** : Synthèse des artefacts livrés
3. **docs/setup_local.md** : Configuration PostgreSQL local
4. **docs/part1_sources.md** : Analyse des sources
5. **docs/PARTIE3_METABASE_DASHBOARD.md** : Instructions Metabase

---

## Exécution du TP

### Prérequis

- PostgreSQL 14+ (installé et en cours d'exécution)
- Python 3.7+
- PowerShell 5.1 (Windows)

### Étapes Rapides

#### Option 1 : Script Automatisé (Recommandé)

```powershell
cd 'C:\chemin\vers\velocity-bike-analytics'
.\scripts\run_full_pipeline.ps1 -PgPassword 'postgres'
```

#### Option 2 : Étapes Manuelles

```powershell
# 1. Importer raw
$env:PGPASSWORD='postgres'
.\scripts\import_backup_fixed.ps1

# 2. Transformations
psql -U postgres -f sql/04_transformations.sql

# 3. Sécurité
psql -U postgres -f sql/05_security.sql

# 4. Valider
python notebooks/validate_db.py

# 5. Vérifier
psql -U postgres -c "SELECT COUNT(*) FROM analytics_velocity.gold_daily_activity;"
```

### Résultats Attendus

1. Schéma raw : tables originales (bike_rentals, bike_stations, user_accounts, cities)
2. Schéma silver : tables nettoyées avec types corrects
3. Schéma analytics_velocity : table gold_daily_activity agrégée
4. Rôles : marketing_user et manager_lyon créés avec droits appropriés
5. RLS : manager_lyon limité à city='Lyon'
6. Validation : rapport logs/validation_report.txt sans erreurs

---

## Conformité TP

| Partie | Critère | Livrable | Statut |
|--------|---------|----------|--------|
| 1 | Identification sources | docs/part1_sources.md | Complet |
| 1 | Justification tables | Documentation incluse | Complet |
| 2 | Schéma silver | sql/04_transformations.sql (1-49) | Complet |
| 2 | Schéma gold | sql/04_transformations.sql (50-79) | Complet |
| 2 | Métriques gold | total_rentals, avg_duration, unique_users | Complet |
| 3 | Configuration Metabase | docs/PARTIE3_METABASE_DASHBOARD.md | Complet |
| 3 | Charts (3x) | Instructions pour création | Complet |
| 3 | Dashboard | Instructions pour création | Complet |
| 4 | Rôles (2x) | sql/05_security.sql (6-13) | Complet |
| 4 | GRANT/REVOKE | sql/05_security.sql (15-29) | Complet |
| 4 | RLS policy | sql/05_security.sql (31-45) | Complet |
| Global | Documentation | README_TP.md + docs/ | Complet |
| Global | Automation | scripts/run_full_pipeline.ps1 | Complet |
| Global | CI/CD | .github/workflows/ci-pipeline.yml | Complet |

---

## Contacts et Support

- Données sources : docs/part1_sources.md
- Problèmes Metabase : docs/PARTIE3_METABASE_DASHBOARD.md (Dépannage)
- Erreurs SQL : logs/validation_report.txt après exécution
- Git branch : feature/docker-infrastructure (voir LIVRABLES.md)

