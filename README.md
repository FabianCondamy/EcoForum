# EcoForum

## Description
Cette application Shiny permet d'analyser des données de température mesurées par différents capteurs répartis dans plusieurs zones. Elle propose des visualisations interactives (séries temporelles, carte, statistiques descriptives). L'application a été restructurée selon une architecture modulaire pour faciliter le développement collaboratif.

---

## Structure du projet
L'application utilise désormais le dossier `R/` pour le chargement automatique des fonctions et modules.

- **app.R** : Point d'entrée de l'application.
- **ui.R** : Interface utilisateur principale (appel des modules).
- **server.R** : Logique serveur principale.
- **R/** : Dossier contenant le code qui gère le traitement des données et les sorties (chargé automatiquement par Shiny).
  - **data_prep.R** : Chargement et nettoyage des données.
  - **mod_serietemp.R** : Module de visualisation des séries temporelles.
  - **mod_map.R** : Module de cartographie interactive.
  - **mod_stats.R** : Module des boxplots comparatifs.
  - **mod_summary.R** : Module du résumé statistique.

 ---

## Données
Les données sources ne sont pas incluses dans le répertoire de l'application mais se trouvent dans l'arborescence parente :
- `../data/raw-data/`.
- `../data/derived-data/`.

---

## Installation et Lancement
1. Assurez-vous que les données sont placées correctement par rapport au dossier de l'application.
2. Ouvrez le fichier `app.R` dans RStudio.
3. Cliquez sur le bouton "Run App".
