# Partie 3 - Visualisation Metabase

## Objectif
Créer un Dashboard pour le service Marketing de VéloCity, permettant de suivre l'activité quotidienne de location de vélos avec les métriques clés.

## Accès à Metabase

- URL : http://localhost:3000
- Identifiants : À configurer lors de la première connexion

## Source de Données

La table **analytics_velocity.gold_daily_activity** est prête pour la visualisation et contient les colonnes suivantes :

| Colonne | Type | Description |
|---------|------|-------------|
| day | DATE | Date d'activité |
| city | VARCHAR | Ville de la station |
| total_rentals | BIGINT | Nombre total de locations |
| average_duration_minutes | NUMERIC | Durée moyenne des trajets (en minutes) |
| unique_users | BIGINT | Nombre d'utilisateurs uniques |

## Configuration de la Source PostgreSQL dans Metabase

1. Accéder à Paramètres -> Bases de Données
2. Cliquer sur "Nouvelle base de données"
3. Sélectionner PostgreSQL
4. Entrer les paramètres :
   - Nom : velocity-bike-analytics
   - Hôte : localhost (ou IP du serveur)
   - Port : 5432
   - Nom base : postgres
   - Utilisateur : postgres
   - Mot de passe : (selon votre configuration)
5. Cliquer sur Enregistrer

Metabase va scanner automatiquement le schéma analytics_velocity et identifier la table gold_daily_activity.

## Création des Charts

### Chart 1 - Courbe : Évolution du total_rentals dans le temps

1. Cliquer sur "+ Nouvelle question"
2. Sélectionner "Simple question"
3. Choisir : velocity-bike-analytics > analytics_velocity > gold_daily_activity
4. Configuration :
   - Axe X : day (groupé par Date)
   - Axe Y : total_rentals (somme)
   - Tri : day croissant
5. Visualisation : Courbe (Ligne)
6. Titre : "Evolution du nombre total de locations"
7. Enregistrer : Nommer "Chart_1_Total_Rentals_Trend"

### Chart 2 - Diagramme en Barres : Top 3 des villes par total_rentals

1. Cliquer sur "+ Nouvelle question"
2. Sélectionner "Simple question"
3. Choisir : velocity-bike-analytics > analytics_velocity > gold_daily_activity
4. Configuration :
   - Grouper par : city
   - Agréger : somme de total_rentals
   - Tri : total_rentals décroissant
   - Limite : 3 résultats
5. Visualisation : Bar chart (Barres horizontales)
6. Titre : "Top 3 des villes par nombre de locations"
7. Enregistrer : Nommer "Chart_2_Top_Cities"

### Chart 3 - Indicateur KPI : average_duration_minutes par ville

1. Cliquer sur "+ Nouvelle question"
2. Sélectionner "Simple question"
3. Choisir : velocity-bike-analytics > analytics_velocity > gold_daily_activity
4. Configuration :
   - Grouper par : city
   - Agréger : moyenne de average_duration_minutes
5. Visualisation : Table (avec option "Indicator" si disponible) ou Pivot
6. Titre : "Durée moyenne de trajets par ville"
7. Enregistrer : Nommer "Chart_3_Avg_Duration_By_City"

### Variante avec Filtrage (Optionnel)

Pour rendre les charts interactifs, ajouter des filtres :
- Filtre par plage de dates (day)
- Filtre par ville (city)

## Création du Dashboard

1. Aller à Tableaux de bord
2. Cliquer sur "+ Nouveau tableau de bord"
3. Nom : "Suivi Activité VéloCity"
4. Description : "Dashboard pour le suivi quotidien de l'activité de location de vélos"
5. Créer (mode édition s'active)

### Ajout des Charts au Dashboard

1. Cliquer sur "Ajouter une carte"
2. Sélectionner "Chart_1_Total_Rentals_Trend"
3. Redimensionner et positionner (haut, largeur complète)
4. Répéter pour "Chart_2_Top_Cities" (milieu gauche)
5. Répéter pour "Chart_3_Avg_Duration_By_City" (milieu droit ou bas)

### Layout Recommandé

```
[Chart 1 - Évolution total_rentals]  [spanning 2 columns, 4 rows]

[Chart 2 - Top 3 villes]              [Chart 3 - Avg Duration]
[4 rows]                              [4 rows]
```

6. Sauvegarder le dashboard
7. Quitter le mode édition

## Résultat Attendu

Le dashboard affichera :

- Une courbe montrant l'évolution du nombre de locations jour après jour
- Un classement des 3 villes les plus actives
- Une table avec la durée moyenne des trajets par ville

## Export et Documentation

Pour documenter le travail :

1. Prendre des captures d'écran du dashboard final
2. Exporter au format PDF (via "Plus" -> "Exporter")
3. Conserver les images/PDF dans le dossier docs/ du projet

## Notes de Sécurité

Si vous avez configuré les rôles PostgreSQL :
- marketing_user : peut accéder au dashboard (lecture seule sur gold_daily_activity)
- manager_lyon : peut accéder mais les données sont filtrées (seule la ville Lyon visible via RLS)

Pour tester :
1. Créer une connexion Metabase avec le rôle marketing_user
2. Vérifier que les données sont visibles
3. Créer une autre connexion avec manager_lyon
4. Vérifier que seule Lyon apparaît dans les résultats

## Dépannage

| Problème | Solution |
|----------|----------|
| Metabase inaccessible | Vérifier que Docker est en cours d'exécution |
| Table gold_daily_activity non visible | Attendre le scan automatique ou forcer la synchronisation dans Paramètres -> Bases de Données |
| Pas de données dans les charts | Vérifier que sql/04_transformations.sql a été exécuté et la table gold_daily_activity contient des données |
| Erreur de connexion PostgreSQL | Vérifier host, port, identifiants (PGPASSWORD) |

