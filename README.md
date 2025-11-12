# EcoForum

## Description
Cette application Shiny permet d’analyser des données de température mesurées par différents capteurs répartis dans plusieurs zones.  
Elle propose plusieurs visualisations interactives :
- Graphiques temporels (évolution des températures)
- Boxplots comparatifs
- Carte interactive des capteurs
- Tableau de statistiques descriptives
---

## Structure du projet
- **`app.R`** : point d’entrée de l’application. Charge l’interface (`ui.R`) et la logique serveur (`server.R`).
- **`ui.R`** : définition de l’interface utilisateur.
- **`server.R`** : logique serveur — traitement des données, calculs et génération des visualisations.
- **`data_prep.R`** : script de préparation et de nettoyage des données (chargement, transformation, enrichissement).

Les données sont attendues dans les répertoires :
- `../data/raw-data/`
- `../data/derived-data/`
---

## Lancement de l’application
1. Vérifiez que les fichiers `ui.R`, `server.R`, `data_prep.R` et `app.R` sont dans le même dossier.
2. Assurez-vous que les données nécessaires se trouvent dans les répertoires indiqués ci-dessus.
3. Lancez l’application :
   - Depuis RStudio : ouvrez `app.R` puis cliquez sur **Run App**
   - Ou via la console R :
     ```r
     shiny::runApp("app.R")
     ```
---

## Notes et recommandations
- Pour de meilleures performances, limitez la plage de dates ou le nombre de capteurs sélectionnés.
- Le traitement peut être plus long si la période d’analyse ou le volume de données est important.
---
