# Velocity Bike Analytics — Livrable TP (Médaillon & Sécurité)

Ce dépôt contient le livrable du TP « Cycle de vie de la donnée » pour VéloCity (locations de vélos). Il est structuré pour une correction simple et professionnelle.

## Branche à corriger

- Utilisez la branche `livrable` (tout le TP est dedans).

## Guide de correction rapide

1) Lire le guide TP: `README_TP.md` (architecture, exécution, conformité)
2) Consulter la synthèse: `SYNTHESE_TP_COMPLET.md` (vue globale + mapping des attentes)
3) Vérifier les livrables: `LIVRABLES.md` (statut et liens vers artefacts)

## Comment tester rapidement (PostgreSQL local)

Pré-requis: PostgreSQL et Python installés.

Exécution automatisée via PowerShell (Windows):

```
cd "C:\Users\gui\Desktop\data\Nouveau dossier\velocity-bike-analytics"
.\n+scripts\run_full_pipeline.ps1
```

Ce script exécute: import (raw) -> transformations (`sql/04_transformations.sql`) -> sécurité (`sql/05_security.sql`) -> validation (`notebooks/validate_db.py`). Les logs sont dans `logs/`.

## Structure du dépôt (niveau racine)

- `docs/` — guides et documentation (inclut `PARTIE3_METABASE_DASHBOARD.md`)
- `sql/` — transformations Médaillon (raw -> silver -> gold) et sécurité RLS
- `scripts/` — automatisation (import, pipeline complet)
- `notebooks/` — validation Python (SQLAlchemy/pandas)
- `archi/`, `gestion_projet/`, `data/`, `metabase/`, `spark/` — ressources du TP
- Fichiers clés: `README_TP.md`, `LIVRABLES.md`, `SYNTHESE_TP_COMPLET.md`, `requirements.txt`

## Couverture des attentes du projet

- Découverte des sources: `docs/part1_sources.md` (sélection + justification)
- Architecture Médaillon: `sql/04_transformations.sql` (raw -> silver -> gold)
- Visualisation Metabase: `docs/PARTIE3_METABASE_DASHBOARD.md` (procédure détaillée)
- Sécurité: `sql/05_security.sql` (RBAC + Row Level Security)
- Automatisation & validation: `scripts/run_full_pipeline.ps1`, `notebooks/validate_db.py`

## Notes d’exploitation

- Si Metabase via Docker n’est pas disponible, utilisez la procédure manuelle de `docs/PARTIE3_METABASE_DASHBOARD.md` pour configurer la source PostgreSQL locale.
- Les politiques RLS sont activées sur la table `analytics_velocity.gold_daily_activity` (restriction sur la ville Lyon pour `manager_lyon`).

## À propos

Projet pédagogique EPSI — Velocity Bike Analytics. Auteur: gui. Branche de travail: `livrable`.
