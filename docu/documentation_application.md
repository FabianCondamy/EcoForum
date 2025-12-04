---
title: "Documentation de l'application Shiny"
author: "Anne-Laure"
date: 25/11/2025
format: html
---

# 1. Introduction

Cette application Shiny permet d'explorer, visualiser et analyser des données de température issues de différents capteurs répartis en zones. Elle propose plusieurs types de visualisations (séries temporelles, boxplots, cartes, résumés statistiques) et offre un ensemble complet de filtres permettant d'affiner l'analyse selon l'année, les capteurs, le jour de l'année (DOY) et l'heure.

L'application est structurée autour d'un **app.R** composé d'une interface utilisateur (`ui`) et d'un serveur (`server`), complétés par des **modules** contenus dans le dossier `R/` ainsi qu'un fichier `global.R` et une feuille de style personnalisée `style.css` dans `www/`.

# 2. Structure générale de l'application dans le fichier 

```src/
.
├── R/                      # Dossier des modules Shiny
│   ├── data_prep.R         # Préparation des données
│   ├── mod_serietemp.R     # Module séries temporelles
│   ├── mod_map.R           # Module carte spatiale
│   ├── mod_stats.R         # Module statistiques et boxplots
│   ├── mod_summary.R       # Module résumé statistique
│   └── mod_newsection.R    # Module vierge pour futures fonctionnalités
├── rsconnect/...           # Fichiers de déploiement ShinyApps.io
├── www/                    # Dossier des ressources web
│    └── style.css          # Feuille de style CSS personnalisée
├── app.R                   # Fichier principal de l'application
├── global.R                # Fichier global pour l'application
├── server.R                # Fichier serveur (inclus dans app.R)
└── ui.R                    # Fichier UI (inclus dans app.R)
```

# 3. Contenu du fichier `app.R`

## 3.1 Interface utilisateur (`ui`)

L'interface contient :

* **sidebarPanel** :
  - Sélecteur de variable (`temp.corr`, `temp.ecart.prc`, `temp.ecart.raw`)  
  - Sélecteur d'années  
  - Slider DOY avec conversion en dates  
  - Slider d'heures  
  - SelectizeInput pour les capteurs + boutons *Tout sélectionner / Effacer*  
  - Boutons :
    - **Tout réinitialiser** : réinitialise tous les filtres  
    - **Mettre à jour** : applique les filtres sélectionnés  
    - **Exporter données** : exporte les données filtrées en CSV  

* **mainPanel** :
  - `tabsetPanel` : Température vs DOY, Boxplots, Carte des zones, Résumé statistique, Section vierge  
  - CSS intégré via `tags$head(includeCSS("www/style.css"))`  

## 3.2 Serveur (`server`)

- Gestion des capteurs et DOY  
- Filtrage des données dans `filtered_data()`  
- Export CSV avec coordonnées géographiques  
- Activation des modules : `timeseriesServer()`, `statsServer()`, `mapServer()`, `summaryServer()`, `NewSectionServer()`

# 4. Contenu du fichier `global.R`

- Palette Okabe–Ito pour visualisations  
- Import des modules via `source()`  

---

# 5. Feuille de style `style.css`

Personnalisation des onglets, panels, boutons et balises `<details>`.

# 6. Modules Shiny

| Module             | Fonctionnalité                                 |
|------------------- |----------------------------------------------- |
| mod_serietemp      | Séries temporelles Température vs DOY          |
| mod_stats          | Boxplots et statistiques                       |
| mod_map            | Carte spatiale avec tuiles                     |
| mod_summary        | Résumé statistique                             |
| mod_newsection     | Module vierge pour nouvelles fonctionnalités   |

# 7. Fonctionnement général

1. Choisir variable, années, capteurs, DOY, heures  
2. Cliquer sur **Mettre à jour**  
3. Modules génèrent graphiques et analyses sur les données filtrées  
4. (Optionnel) Cliquer sur **Exporter filtres** pour sauvegarder les filtres sélectionnés et les réutiliser ultérieurement

# 8. Data Preparation (`data_prep.R`)

- Chargement et préparation des températures de référence et capteurs  
- Création des colonnes `temp.ecart.raw` et `temp.ecart.prc`  
- Transformation en objets spatiaux pour carte  

# 9. Packages R requis

Avant de lancer l'application, assurez-vous que les packages suivants sont installés :

| Package       | Utilisation principale                                   |
|---------------|--------------------------------------------------------- |
| shiny         | Interface web et serveur Shiny                           |
| ggplot2       | Visualisations graphiques                                |
| dplyr         | Manipulation et transformation de données                |
| sf            | Gestion des données spatiales                            |
| viridis       | Palettes de couleurs pour les graphiques                 |
| lubridate     | Gestion des dates et conversion DOY → Date               |
| readr         | Lecture de fichiers CSV                                  |
| shinyWidgets  | Composants UI avancés (sliders, boutons, selectizeInput) |
| shinycssloaders | Spinners pour les graphiques et modules                |
| maptiles      | Fond de carte pour visualisations spatiales              |

**Installer tous les packages en une fois :**

```r
required_packages <- c("shiny", "ggplot2", "dplyr", "sf", "viridis",
                       "lubridate", "readr", "shinyWidgets", "shinycssloaders", "maptiles")
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)
```

# 10. Lancer l'application Shiny

Directement via R :

```r
# Positionnez-vous dans le dossier app
setwd("src/app.R")

# Lancer l'application
shiny::runApp()

```
Ou avec le bouton "Run App" dans RStudio (toujours dans le fichier app.R).

