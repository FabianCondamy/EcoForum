# EcoForum

## Description
Cette application Shiny permet d'analyser des données de température mesurées par différents capteurs répartis dans plusieurs zones. Elle propose des visualisations interactives (séries temporelles, carte, statistiques descriptives). L'application a été restructurée de manière à faciliter le développement collaboratif en faisant une séparation back/front.

---

## Structure du projet
L'application utilise désormais le sous-dossier `R/` pour le chargement automatique des fonctions et modules. On a les différents fichiers suivants :

- **app.R** : point d'entrée de l'application.
- **ui.R** : interface utilisateur principale, appel des modules. (front)
- **server.R** : logique serveur principale. (back)
- **R/** : dossier contenant le code qui gère le traitement des données et les sorties qui est chargé automatiquement par Shiny.
  - **data_prep.R** : chargement et préparation des données.
  - **mod_serietemp.R** : module de visualisation des séries temporelles.
  - **mod_map.R** : module de cartographie interactive.
  - **mod_stats.R** : module des boxplots comparatifs et d'autres éléments d'analyse de données.
  - **mod_summary.R** : module du résumé statistique.

 ---

## Données
Les données sources ne sont pas incluses dans le répertoire de l'application mais se trouvent dans l'arborescence parente :
- `../data/raw-data/`
- `../data/derived-data/`

---

## Installation et Lancement
1. Ouvrez le fichier `app.R` dans le sous-dossier `shiny_app` dans RStudio.
2. Cliquez sur le bouton "Run App" en haut à droite.
