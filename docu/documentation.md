---
title: "Documentation du projet EcoForum"
date: 06/12/2025
format: html
---

# 1. Introduction

Cette application Shiny permet d'explorer, visualiser et analyser des données de température issues de différents capteurs répartis en zones. Elle propose plusieurs types de visualisations (séries temporelles, boxplots, cartes, résumés statistiques) et offre un ensemble complet de filtres permettant d'affiner l'analyse selon l'année, les capteurs, le jour de l'année (DOY) et l'heure.

Le projet se décompose en 4 répertoires principaux, un dossier **src** contenant l'ensemble du code R développé, un dossier **data** qui regroupe les différents fichiers de données utilisés par l'application, un dossier **docu** rassemblant des notices et divers éléments de documentation pour comprendre l’usage et la structure des fichiers du projet et enfin un dossier **tests** actuellement vide, dédié à l'implémentation de tests pour l'application dans le futur. 

L'application est structurée autour d'un fichier **app.R** composé d'une interface utilisateur (`ui`) et d'un serveur (`server`), complétés par des **modules** contenus dans le dossier `R/` ainsi qu'un fichier `global.R` et une feuille de style personnalisée `style.css` dans `www/`.

# 2. Structure générale de l'application (dossier src)

```src/
.
├── R/                                              # dossier des différents modules Shiny
|   ├── mod_analyse.R                               # module d'analyse des données
│   ├── mod_data.R                                  # module de préparation des données
│   ├── mod_serietemp.R                             # module des séries temporelles
│   ├── mod_map.R                                   # module des cartes spatiales
│   ├── mod_stats.R                                 # module des statistiques générales et des boxplots
│   ├── mod_summary.R                               # module du résumé statistique
│   └── mod_newsection.R                            # module vierge pour futures fonctionnalités
├── rsconnect/shinyapps.io/ecoforum/shiny_app.dcf   # fichiers de déploiement ShinyApps.io
├── www/                                            # dossier des ressources web
│    └── style.css                                  # feuille de style CSS personnalisée
├── app.R                                           # fichier principal de l'application
├── global.R                                        # fichier global pour l'application
├── server.R                                        # fichier serveur de l'application (back)
└── ui.R                                            # fichier UI de l'application (front)
```

# 3. Contenu plus détaillé de l'application

## 3.1 Interface utilisateur (`ui.R`)

L'interface contient :

* **sidebarPanel** :
  - Sélecteur parmi 3 variables : `temp.corr`, `temp.ecart.prc` et `temp.ecart.raw`  
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

## 3.2 Serveur (`server.R`)

Ce fichier constitue le back de l'application, il réalise :

- la gestion des capteurs et DOY  
- le filtrage des données dans `filtered_data()`  
- l'export CSV avec coordonnées géographiques  
- l'activation des différents modules : `timeseriesServer()`, `statsServer()`, `mapServer()`, `summaryServer()`, `analyseServer()`, `NewSectionServer()`

# 3.3 Contenu du fichier `global.R`

- Palette de couleurs Okabe–Ito pour visualisations  
- Import des modules via `source()`  


---

# 3.4 Feuille de style `style.css`

Ce fichier permet la personnalisation des onglets, panels, boutons et balises `<details>`.

# 4. Différents modules de l'application Shiny

Tous les codes des divers modules sont organisés de la même manière avec une partie dediée au back de l'application (partie server) et une partie dediée au front (partie UI).

## 4.1 `mod_analyse.R`

Ce premier module se concentre sur l'affichage d'une série temporelle, il permet :

- de construire une série temporelle complète en agrégeant les données par heure en faisant une décomposition additive classique (fonction decompose)
- de régler le cycle temporel sur lequel on veut tracer (journalier, hebdomadaire ou mensuel)
- d'afficher quatre graphiques : les données brutes, la tendance, la saisonnalité et les résidus


## 4.2 `mod_data.R`

Ce module est dédié à la préparation des données, il effectue :

- le chargement des données brutes provenant de divers fichiers csv et leur harmonisation
- l'enrichissement de ces dernières avec les températures de référence et le type d'habitat de chaque capteur 
- la génération d'une carte de fond avec OpenStreetMap lorsque les données sont disponibles


## 4.3 `mod_map.R`

Ce module génère une série de cartes générées à partir de l'ensemble des capteurs. Plus précisément, il réalise :

- le chargement automatique des images en format .png d'un dossier
- l'extraction de la date depuis le nom des fichiers 
- la conversion de la DOY en date réelle
- l'affichage d'une image légendée avec un slider permettant de sélectionner la date voulue

Grâce à ce fichier, il est possible de mettre à jour l'application pour de nouvelles données. Pour ceci, suivez les étapes décrite plus bas au point #9. 

## 4.4 `mod_newsection.R`

Ce module fournit une page vide dans l'application prête à être complétée pour accueillir de nouvelles features. Il effectue :

- l'affichage d'un titre et d'un texte introductif
- la génération d'un panneau d'explication 
- la génération d'une structure UI minimale servant de base à une future page

## 4.5 `mod_serietemp.R`

Ce module permet d'afficher l'évolution temporelle de la variable choisie parmi 3 options avec un choix des capteurs et un code couleur pour chacune des années. Plus en détail, il dispose de :

- l'affichage d'une série temporelle continue des variables avec des couleurs pour chacune des années et un facettage des capteurs
- l'affichage d'un spinner animé pendant le rendu
- l'affichage d'une section repliable d'explications sur les données

## 4.6 `mod_stats.R`

Ce module gère l'affichage et le calcul des boxplots qui permettent de comparer la distribution d'une variable selon l'année et le capteur.

- affichage de boxplots pour chaque année avec un facettage par capteur et un spinner animé pendant le rendu
- gestion des valeurs aberrantes
- section repliable d'explications sur les données

## 4.7 `mod_summary.R`

Ce module Shiny affiche un ensemble de statistiques descriptives par capteur, ainsi que deux visualisations dédiées au capteur sélectionné. Il permet :

- l'affichage des valeurs minimales, maximales et moyennes de la variable choisie
- la sélection d'un capteur puis l'affichage des statistiques sur cet unique capteur
- l'intégration d'un graphique temporel et de boxplots pour le capteur choisi
- l'affichage d'une section repliable d'explications sur les données


# 5. Structure générale du dossier data

Le dossier data à vocation d'accueillir l'ensemble des fichiers de données utilisés ensuite dans les codes du dossier src qui construisent l'application.

```data/
.
├── derived-data/                   # dossier contenant les fichiers de données traités et recalibrés
│   ├── new-data.csv                # fichier obtenu après compilation
│   ├── new-data_corr.csv           # fichier obtenu après compilation/calibration
│   ├── correction.csv              # fichier représentant la correction à appliquer à chaque capteur pour les calibrer
│   └── data.calibr.csv             # jeu de données de calibration des capteurs
├── raw-data/                       # fichiers de données brutes    
│   ├── new-data/                   # dernières données brutes récoltées sur les capteurs 
│       ├── (n°02)                  # fichier de données du premier capteur (n°2)
│       ├──  ...                    # fichiers de données des autres capteurs
│       └── (n°38)                  # fichier de données du dernier capteur (n°38) 
│   ├── new-csv/                    # dossier vide dédié à l'accueil de nouvelles données
│   ├── data.terrain.corrige.csv    # fichier contenant les données sur le terrain et les corrections à appliquer aux capteurs
│   ├── habitat.csv                 # jeu de données rendant compte du type d'habitat dans lequel les capteurs sont positionnés 
│   ├── listing-HOBO.xlsx           # jeu de données contenant les informations sur les capteurs (coordonnées, modèle, numéro de série)
│   ├── map.osm                     # carte openstreetmap
│   └── temp_ref.csv                # jeu de données contenant les températures de référence sur le campus prises toutes les demi-heures
```


# 6. Structure générale du dossier docu

Ce dossier contient l'ensemble des notices qui permettent de comprendre le projet et ses différents codes.

```docu/
.
├── figures/                                  #
│   ├── fig-calibration/                      # dossier contenant diverses images concernant la calibration des capteurs
│       ├── data.calib.corr.png               # graphique rendant compte des températures mesurées en continu par chaque capteur dans l’étuve lors de la calibration
│       ├── data.calib.moy.png                # graphique rendant compte des températures moyennes mesurées par chaque capteur dans l’étuve lors de la calibration
│       └── data.calib.png                    # zoom du premier graphique
│   └── sensor_map                            #
├── notices/                                  
│   ├── Notice_utilisation_HOBO-MX2203.docx   # notice décrivant l'utilisation de l'application HOBO-connect qui permet de relever les données sur les capteurs sur le terrain
│   └── Notice-analyse-donnees-HAV454H.docx   # notice concernant le travail du groupe précédent
├── documentation.md                          # ensemble de la documentation
├── Lien vers map capteurs.docx               # fichier docx renvoyant à la carte des capteurs sur le campus
└── Plan-capteur-HOBO.pdf                     # fichier pdf rendant compte de l'emplacement des capteurs
```

# 7. Packages R requis pour le projet

Avant de lancer l'application, assurez-vous que les packages suivants sont installés :

| Package         | Utilisation principale                                                           |
|-----------------|----------------------------------------------------------------------------------|
| shiny           | Création d'applications web interactives en R avec back et front                 |
| ggplot2         | Création de visualisations graphiques claires et personnalisables                |
| dplyr           | Manipulation et transformation de données                                        |
| tidyr           | Mise en forme des données                                                        |
| tidyterra       | Rendre les objets spatiaux manipulables avec dplyr et visualisables avec ggplot2 |
| readxl          | Importation de fichiers .xls et .xlsx                                            |
| readr           | Lecture de fichiers .csv                                                         |
| sf              | Gestion des données spatiales                                                    |
| viridis         | Utilisation de palettes de couleurs pour les graphiques                          |
| lubridate       | Gestion des dates et conversion DOY en Date                                      |
| stringr         | Manipulation des chaînes de caractères (str)                                     |
| ggspatial       | Ajout d'éléments cartographiques aux cartes réalisées avec ggplot2               |  
| shinyWidgets    | Enrichissement de l'UI Shiny avec widgets plus esthétiques et interactifs        |
| shinycssloaders | Ajout d'animations de chargement (spinners) sur les graphiques                   |
| maptiles        | Téléchargement et affichage de fond de carte pour visualisations spatiales       |
| magick          | Import et manipulation d'images dans R                                           |
| zoo             | Manipulation des séries temporelles                                              |

**Pour installer tous les packages en une fois :**

```r
required_packages <- c("shiny", "ggplot2", "dplyr", "tidyr", "tidyterra", "readr", "readxl", "sf", "viridis",
                       "lubridate", "stringr", "ggspatial", "shinyWidgets", "shinycssloaders", "maptiles", "magick", "zoo")
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)
```


# 8. Lancer l'application Shiny

Directement via R :

```r
# Positionnez-vous dans le dossier app
setwd("src/app.R")

# Lancer l'application
shiny::runApp()

```
Ou avec le bouton "Run App" dans RStudio (toujours dans le fichier app.R).


# 9. Notice concernant l'ajout de nouvelles données 

Pour ajouter de nouvelles données et continuer d'utiliser l'application :

1. Commencer par prélever les données des différents capteurs sur le terrain en se référant au fichier Notice_utilisation_HOBO-MX2203.docx disponible dans le sous-dossier notices de docu 
2. Déposer les fichiers de données des différents capteurs en suivant le chemin suivant : data\raw-data\new-data\ 
3. Nommer correctement les fichiers, ils doivent commencer par (n°XX) où XX est le numéro du capteur
4. Suivre les étapes du point précédent pour lancer l'application avec les nouvelles données

**NB** : il est nécessaire de récupérer les données sur l'ensemble des capteurs pour éviter un quelconque bug pour l'instant.

# 10. Fonctionnement général de l'application

1. Choisir variable, années, capteurs, DOY, heures  
2. Cliquer sur **Mettre à jour**  
3. Générer graphiques et analyses sur les données filtrées en utilisant les différents modules 
4. (Optionnel) Cliquer sur **Exporter filtres** pour sauvegarder les filtres sélectionnés et les réutiliser ultérieurement