"""
Script de validation de la base PostgreSQL.
Crée un rapport minimal dans `logs/validation_report.txt`.
Usage (PowerShell):
  $env:PGPASSWORD='postgres'
  python notebooks/validate_db.py

Le script lit les paramètres de connexion dans les variables d'environnement suivantes (optionnel):
  PGHOST (default localhost)
  PGPORT (default 5432)
  PGUSER (default postgres)
  PGPASSWORD
  PGDATABASE (default postgres)

"""
import os
import sys
from sqlalchemy import create_engine, text
import pandas as pd

# Connexion
host = os.environ.get('PGHOST', 'localhost')
port = os.environ.get('PGPORT', '5432')
user = os.environ.get('PGUSER', 'postgres')
password = os.environ.get('PGPASSWORD', '')
db = os.environ.get('PGDATABASE', 'postgres')

if not password:
    print('Warning: PGPASSWORD vide — définissez $env:PGPASSWORD avant d\'exécuter.')

engine_url = f'postgresql+psycopg2://{user}:{password}@{host}:{port}/{db}'

try:
    engine = create_engine(engine_url)
    conn = engine.connect()
except Exception as e:
    print('Erreur de connexion:', e)
    sys.exit(2)

reports = []

queries = {
    'raw_bike_rentals_count': "SELECT COUNT(*)::bigint AS cnt FROM raw.bike_rentals;",
    'silver_rentals_sample': "SELECT COUNT(*)::bigint AS cnt FROM silver.rentals;",
    'gold_daily_count': "SELECT COUNT(*)::bigint AS cnt FROM analytics_velocity.gold_daily_activity;",
    'gold_daily_range': "SELECT MIN(day) AS min_day, MAX(day) AS max_day FROM analytics_velocity.gold_daily_activity;",
    'gold_recent_5': "SELECT * FROM analytics_velocity.gold_daily_activity ORDER BY day DESC LIMIT 5;"
}

for name, q in queries.items():
    try:
        df = pd.read_sql_query(text(q), conn)
        reports.append((name, df))
    except Exception as e:
        reports.append((name, f'ERROR: {e}'))

# Écrire rapport
os.makedirs('logs', exist_ok=True)
with open('logs/validation_report.txt', 'w', encoding='utf-8') as f:
    for name, result in reports:
        f.write(f'--- {name} ---\n')
        if isinstance(result, str):
            f.write(result + '\n')
        else:
            f.write(result.to_csv(index=False))
        f.write('\n')

print('Rapport généré: logs/validation_report.txt')
