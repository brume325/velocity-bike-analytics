# TP - Cycle de Vie de la Donnée : De la Source au Dashboard

**Objectif** : Construire un pipeline de données complet suivant le pattern medallion (raw -> silver -> gold) avec sécurité (RLS) et validation.

## Architecture

```
Raw Layer (docker/init/backup.sql)
    ↓ Import (scripts/import_backup_fixed.ps1)
    ↓
Silver Layer (sql/04_transformations.sql)
    - Crée schéma 'silver' avec tables nettoyées
    - Exemple : silver.rentals à partir de raw.bike_rentals
    ↓
Gold Layer (sql/04_transformations.sql)
    - Crée schéma 'analytics_velocity' avec tables agrégées
    - Exemple : gold_daily_activity (COUNT, AVG par jour)
    ↓
Security (sql/05_security.sql)
    - Crée rôles : marketing_user, manager_lyon
    - Applique RLS sur gold_daily_activity
    - manager_lyon limité à city='Lyon'
    ↓
Validation (notebooks/validate_db.py)
    - Vérifie counts et agrégats
    - Génère rapport logs/validation_report.txt
```

## Fichiers du Projet

### Import & Transformations
- `docker/init/backup.sql` — Schéma raw initial (fourni par le prof)
- `scripts/import_backup.ps1` — Import PowerShell original
- `scripts/import_backup_fixed.ps1` — Import PowerShell corrigé (recommandé)
- `sql/04_transformations.sql` — Transformations medallion (silver → gold)
- `sql/05_security.sql` — Rôles et RLS

### Validation & CI
- `notebooks/validate_db.py` — Script validation (SQLAlchemy + pandas)
- `.github/workflows/ci-pipeline.yml` — Workflow GitHub Actions
- `requirements.txt` — Dépendances Python (psycopg2-binary, pandas, sqlalchemy, etc.)

### Documentation
- `README_TP.md` — Ce fichier
- `docs/setup_local.md` — Setup PostgreSQL local (optionnel)
- `docs/part1_sources.md` — Sélection des sources données

## Mode d'Exécution Local

### Prérequis
- PostgreSQL installé (client `psql` + serveur running)
- Python 3.7+
- PowerShell 5.1+ (Windows)

### Étapes Manuelles

#### 1. Vérifier psql et python
```powershell
cd 'C:\chemin\vers\velocity-bike-analytics'
psql --version
python --version
```

#### 2. Importer le backup
```powershell
$env:PGPASSWORD='postgres'  # Ajustez si mot de passe différent
.\scripts\import_backup_fixed.ps1
```

#### 3. Appliquer transformations et sécurité
```powershell
psql -U postgres -f sql/04_transformations.sql
psql -U postgres -f sql/05_security.sql
```

#### 4. Vérification rapide
```powershell
psql -U postgres -c "SELECT COUNT(*) FROM analytics_velocity.gold_daily_activity;"
```

#### 5. Lancer la validation
```powershell
python -m pip install -r requirements.txt
python notebooks/validate_db.py
```

#### 6. Consulter le rapport
```powershell
notepad logs/validation_report.txt
```

### Exécution Automatisée (Script Unique)

Un script PowerShell complet est fourni (scripts/run_full_pipeline.ps1) qui exécute toutes les étapes ci-dessus. Usage :

```powershell
.\scripts\run_full_pipeline.ps1 -PgPassword 'postgres' -PgUser 'postgres'
```

Cela produit logs dans `logs/` et génère le rapport de validation `logs/validation_report.txt`.

## Exécution en CI (GitHub Actions)

Le workflow `.github/workflows/ci-pipeline.yml` s'exécute automatiquement à chaque push sur `main` ou `feature/docker-infrastructure`.

- Démarre un service PostgreSQL
- Importe le backup
- Applique transformations + sécurité
- Valide les données
- Téléverse `logs/` comme artefact

Consultez les artefacts dans l'onglet "Actions" du repo GitHub.

## Résultats Attendus

### Tables Créées
- `raw.bike_rentals` — Table originale (depuis backup)
- `silver.rentals` — Table nettoyée (transformations)
- `analytics_velocity.gold_daily_activity` — Agrégations quotidiennes

### Schéma gold_daily_activity
```
day (date) | city | total_rentals | average_duration_minutes | unique_users
```

### Rôles et Sécurité
- Rôle `marketing_user` : accès lecture sur gold (sans RLS)
- Rôle `manager_lyon` : accès lecture sur gold avec RLS (city='Lyon' uniquement)

### Rapport de Validation
Généré dans `logs/validation_report.txt` après exécution du script Python :
- Counts de raw.bike_rentals, silver.rentals, gold_daily_activity
- Plage de dates (MIN/MAX day)
- 5 derniers enregistrements de gold

## Dépannage

### `psql not found`
- Installez PostgreSQL (client + serveur) depuis https://www.postgresql.org/download/
- Ou lancez via Docker : `docker run -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:14`

### `ImportError: No module named psycopg2_binary`
```powershell
python -m pip install psycopg2-binary pandas sqlalchemy
```

### Erreur de connexion à PostgreSQL
- Vérifiez que PostgreSQL est running : `psql -U postgres -c "SELECT 1;"`
- Vérifiez le mot de passe : ajustez `$env:PGPASSWORD` ou adaptez le script

### Tables vides ou manquantes après import
- Vérifiez que `docker/init/backup.sql` existe
- Consultez `logs/import_output.txt` pour les erreurs SQL

## Conformité TP

Le projet respecte les consignes du TP :
- ✅ **Ingestion** : Import du backup SQL (`docker/init/backup.sql`)
- ✅ **Medallion** : Transformations raw → silver → gold
- ✅ **Sécurité** : Rôles et RLS sur gold
- ✅ **Validation** : Script Python + rapport (logs)
- ✅ **Livraison** : Artefacts commités, CI en place, documentation complète

## Contacts & Support

Pour toute question sur ce TP, consulter la documentation ou lancer le workflow CI pour identifier les erreurs.
