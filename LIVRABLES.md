# Livrables TP - Cycle de Vie de la Donnée

**Date** : 3 décembre 2025
**Projet** : velocity-bike-analytics
**Branche** : feature/docker-infrastructure
**Statut** : Complet

## Résumé

Pipeline complet implémenté suivant le pattern medallion (raw -> silver -> gold) avec sécurité (RLS) et validation automatisée.

## Artefacts Livrés

### 1. Documentation
- **`README_TP.md`** — Guide complet (architecture, instructions, conformité TP)
- **`docs/setup_local.md`** — Setup PostgreSQL local (optionnel)
- **`docs/part1_sources.md`** — Sélection des sources de données
- **`LIVRABLES.md`** — Ce fichier

### 2. Ingestion des Données
- **docker/** — Contenu TP prof (docker-compose.yml, init/)
  - docker/init/backup.sql — Schéma raw initial
  - docker/init/docker-compose.yml — Stack (db + pgAdmin + Metabase)
- **scripts/import_backup.ps1** — Script d'import original (corrigé)
- **scripts/import_backup_fixed.ps1** — Version optimisée (recommandée)
- **scripts/run_full_pipeline.ps1** — Script automatisé (import + transforms + security + validation en une seule commande)

### 3. Transformations Medallion
- **sql/04_transformations.sql** — Schémas silver et gold
  - silver.bike_rentals — Nettoyage et typage des trajets
  - silver.bike_stations — Nettoyage stations (lat/long numeric)
  - silver.user_accounts — Typage comptes utilisateurs
  - analytics_velocity.gold_daily_activity — Agrégations quotidiennes (day, city, total_rentals, average_duration_minutes, unique_users)

### 4. Sécurité (RBAC + RLS)
- **sql/05_security.sql** — Rôles et politiques
  - Rôle marketing_user : lecture gold (pas de restriction)
  - Rôle manager_lyon : lecture gold, limité à city='Lyon' via RLS
  - Révokations sur schémas raw/silver

### 5. Validation et CI
- **notebooks/validate_db.py** — Script Python (SQLAlchemy/pandas)
  - Vérifie counts : raw -> silver -> gold
  - Agrégats journaliers
  - Générant rapport : logs/validation_report.txt
- **.github/workflows/ci-pipeline.yml** — GitHub Actions
  - Service PostgreSQL 14
  - Exécution automatique : import -> transforms -> security -> validation
  - Artefacts logs/ téléversés

### 6. Dépendances
- **requirements.txt** — Packages Python (psycopg2-binary, pandas, sqlalchemy, etc.)

## Conformité TP

| Critère | Statut | Evidence |
|---------|--------|----------|
| Ingestion | Complet | docker/init/backup.sql + scripts import |
| Medallion | Complet | sql/04_transformations.sql (raw -> silver -> gold) |
| Sécurité (RBAC) | Complet | sql/05_security.sql (rôles marketing_user, manager_lyon) |
| RLS | Complet | sql/05_security.sql (manager_lyon limité à city='Lyon') |
| Validation | Complet | notebooks/validate_db.py + rapport logs |
| Documentation | Complet | README_TP.md + guide setup |
| CI/CD | Complet | .github/workflows/ci-pipeline.yml |
| Livraison | Complet | Tous artefacts commités, branche feature |

## Utilisation Rapide

### Option 1 : Script Automatisé (recommandé)
```powershell
cd 'C:\chemin\vers\velocity-bike-analytics'
.\scripts\run_full_pipeline.ps1 -PgPassword 'postgres'
```

Produit automatiquement :
- Import du backup
- Transformations (silver/gold)
- Sécurité (RLS)
- Validation + rapport
- Option push vers GitHub

### Option 2 : Étapes Manuelles
```powershell
$env:PGPASSWORD='postgres'
.\scripts\import_backup_fixed.ps1
psql -U postgres -f sql/04_transformations.sql
psql -U postgres -f sql/05_security.sql
python -m pip install -r requirements.txt
python notebooks/validate_db.py
```

### Option 3 : CI GitHub Actions
Push vers `feature/docker-infrastructure` → workflow déclenché automatiquement  
Consultez onglet "Actions" pour logs et artefacts `logs/`.

---

## 📊 Résultats Attendus

### Tables Créées
```sql
raw.bike_rentals           -- Données brutes (import)
silver.bike_rentals        -- Nettoyage + conversion types
silver.bike_stations       -- Stations nettoyées
silver.user_accounts       -- Comptes utilisateurs
analytics_velocity.gold_daily_activity  -- Agrégations quotidiennes
```

### Exemple Requête Gold
```sql
SELECT day, city, total_rentals, average_duration_minutes, unique_users
FROM analytics_velocity.gold_daily_activity
ORDER BY day DESC
LIMIT 10;
```

### Rapport Validation
`logs/validation_report.txt` contient :
- Counts : raw.bike_rentals, silver.*, gold.*
- Plage de dates
- Top 5 enregistrements gold

---

## 🔧 Dépannage

| Problème | Solution |
|----------|----------|
| `psql not found` | Installer PostgreSQL ou `docker run postgres:14` |
| `ModuleNotFoundError: psycopg2` | `python -m pip install psycopg2-binary pandas sqlalchemy` |
| Connexion refusée (Postgres) | Vérifier : `psql -U postgres -c "SELECT 1;"` |
| Tables vides après import | Vérifier `logs/import_output.txt` pour erreurs SQL |
| RLS policy non appliquée | Se connecter en tant que `manager_lyon` (test via `psql -U manager_lyon`) |

---

## 📝 Prochaines Étapes (Optionnel)

### Pour le Dashboard Metabase
1. Accédez à `http://localhost:3000` (si stack Docker running)
2. Connectez-vous à PostgreSQL (credentials : postgres/postgres)
3. Sélectionnez schéma `analytics_velocity`
4. Créez dashboards sur `gold_daily_activity`

### Pour Production
- Changer mots de passe (actuellement 'changeme', 'postgres')
- Renommer rôles selon annuaire AD/LDAP
- Configurer backups automatiques
- Monitorer RLS policies en cas d'ajout de villes

---

## 📜 Contenu Commit

### Fichiers Modifiés/Ajoutés
```
README_TP.md
LIVRABLES.md
scripts/run_full_pipeline.ps1 (NOUVEAU)
scripts/import_backup.ps1 (corrigé)
scripts/import_backup_fixed.ps1 (NOUVEAU)
sql/04_transformations.sql (corrigé)
sql/05_security.sql (corrigé)
notebooks/validate_db.py (NOUVEAU)
.github/workflows/ci-pipeline.yml (NOUVEAU)
requirements.txt (nettoyé)
logs/ (rapports de validation)
```

### Message Commit
```
feat(tp): pipeline complet avec validation + CI

- Ingestion : import backup SQL via PowerShell
- Medallion : silver (nettoyage) + gold (agrégations quotidiennes)
- Sécurité : rôles (marketing_user, manager_lyon) + RLS (city='Lyon')
- Validation : script Python (counts, agrégats, rapport)
- CI : GitHub Actions (import→transforms→security→validate)
- Documentation : README_TP.md avec guide complet
- Automatisation : run_full_pipeline.ps1 pour exécution 1-click

Conforme aux consignes du TP.
```

---

## 👤 Contact

Pour toute question, consultez :
- `README_TP.md` — Guide d'exécution
- `logs/validation_report.txt` — Résultats de la dernière exécution
- `.github/workflows/ci-pipeline.yml` — Définition du pipeline CI

---

**État** : Prêt pour livraison ✅  
**Dernière mise à jour** : 3 décembre 2025, 12:00 UTC
