-- SQL script : 05_security.sql
-- But : créer rôles marketing_user et manager_lyon, appliquer les droits de moindre privilège

BEGIN;

-- 1) Création des rôles (si nécessaire)
DO $$ BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'marketing_user') THEN
     CREATE ROLE marketing_user LOGIN PASSWORD 'changeme';
   END IF;
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'manager_lyon') THEN
     CREATE ROLE manager_lyon LOGIN PASSWORD 'changeme';
   END IF;
END $$;

-- 2) Révoquer l'accès par défaut aux schémas raw et silver
REVOKE ALL ON SCHEMA raw FROM marketing_user;
REVOKE ALL ON SCHEMA silver FROM marketing_user;
REVOKE ALL ON SCHEMA raw FROM manager_lyon;
REVOKE ALL ON SCHEMA silver FROM manager_lyon;

-- 3) Donner usage du schema analytics_velocity et SELECT sur gold
GRANT USAGE ON SCHEMA analytics_velocity TO marketing_user;
GRANT USAGE ON SCHEMA analytics_velocity TO manager_lyon;
GRANT SELECT ON analytics_velocity.gold_daily_activity TO marketing_user;
GRANT SELECT ON analytics_velocity.gold_daily_activity TO manager_lyon;

-- 4) Row-Level Security : restreindre manager_lyon aux données de la ville 'Lyon'
ALTER TABLE analytics_velocity.gold_daily_activity ENABLE ROW LEVEL SECURITY;

-- Supprimer anciennes policies
DROP POLICY IF EXISTS manager_lyon_policy ON analytics_velocity.gold_daily_activity;

-- Policy RLS : manager_lyon voit uniquement city='Lyon'
CREATE POLICY manager_lyon_policy ON analytics_velocity.gold_daily_activity
  FOR SELECT
  TO manager_lyon
  USING (city = 'Lyon');

-- Policy par défaut : marketing_user voit tout (pas de RLS restritive)
-- (Aucune policy n'est définie pour marketing_user, donc il verra tout dans gold)

COMMIT;

-- Note: changez les mots de passe et adaptez les noms de rôles selon votre annuaire.
