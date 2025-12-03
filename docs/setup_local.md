# Installation et exécution locale (sans Docker)

Ce guide montre comment faire fonctionner l'environnement du TP **sans Docker** : installation de PostgreSQL sous Windows, import des tables fournies, et préparation d'un environnement Python/Jupyter pour travailler sur les notebooks.

## Prérequis
- Accès administrateur Windows (installation de PostgreSQL)
- Connexion Internet pour télécharger les paquets

## 1) Installer PostgreSQL (Windows)

- Télécharge l'installateur officiel : https://www.postgresql.org/download/windows/
- Lance l'installateur (version 13+ recommandée). Pendant l'installation :
  - Choisis un mot de passe pour l'utilisateur `postgres` (note-le)
  - Laisse le port par défaut `5432`

## 2) Vérifier `psql` dans le PATH

Ouvre PowerShell et exécute :

```powershell
psql --version
```

Si `psql` n'est pas trouvé, ajoute le dossier `bin` de PostgreSQL à la variable d'environnement `PATH`, par exemple :

```powershell
# Exemple : adapte le chemin si nécessaire
$env:Path += ";C:\Program Files\PostgreSQL\14\bin"
```

## 3) Créer la base et importer les données

Le projet contient un script d'initialisation `docker/init/backup.sql` (copie du TP). Pour l'importer :

```powershell
# depuis la racine du projet
cd 'C:\Users\gui\Desktop\data\Nouveau dossier\velocity-bike-analytics'
# exécuter le script (il utilisera l'utilisateur postgres et demandera le mot de passe)
psql -U postgres -f docker\init\backup.sql
```

Remarque : si le script doit être appliqué sur une base différente, créez la base d'abord :

```powershell
psql -U postgres -c "CREATE DATABASE velocity;"
psql -U postgres -d velocity -f docker\init\backup.sql
```

## 4) Préparer l'environnement Python

Installer Python 3.10+ et créer un environnement virtuel :

```powershell
# installer Python (si besoin), puis :
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install --upgrade pip
pip install -r requirements.txt
```

## 5) Lancer Jupyter Notebook / Lab

```powershell
# dans le venv activé
jupyter lab  # ou jupyter notebook
```

## 6) Se connecter à PostgreSQL depuis Python

Exemple de chaîne de connexion SQLAlchemy :

```
postgresql+psycopg2://postgres:postgres@localhost:5432/postgres
```

## 7) Metabase / pgAdmin (optionnel)

- Si tu veux Metabase sans Docker, tu peux télécharger l'archive Java standalone (jar) depuis le site Metabase et la lancer localement :
  - https://www.metabase.com/start/
- Pour pgAdmin, installe l'outil natif Windows depuis https://www.pgadmin.org/download/ et configure un serveur pointant sur `localhost:5432`.

---

Si tu veux, j'automatise l'import SQL avec le script `scripts/import_backup.ps1` que je fournis et je vérifie que les notebooks s'ouvrent correctement.

## 8) Exécuter les scripts de transformations et de sécurité

Après avoir importé `docker/init/backup.sql`, exécutez les scripts suivants pour créer les couches Silver et Gold et appliquer les règles de sécurité :

```powershell
# depuis la racine du projet
psql -U postgres -f sql/04_transformations.sql
psql -U postgres -f sql/05_security.sql
```

Vérifiez ensuite dans `psql` ou `pgAdmin` que les schémas `silver` et `analytics_velocity` existent et contiennent les objets attendus.
