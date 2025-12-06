---
title: "Documentation du projet EcoForum"
author: "Anne-Laure"
date: 25/11/2025
format: html
---

# 1. Introduction

Cette application Shiny permet d'explorer, visualiser et analyser des données de température issues de différents capteurs répartis en zones. Elle propose plusieurs types de visualisations (séries temporelles, boxplots, cartes, résumés statistiques) et offre un ensemble complet de filtres permettant d'affiner l'analyse selon l'année, les capteurs, le jour de l'année (DOY) et l'heure.

Le projet se décompose en 4 répertoires principaux, un dossier **src** contenant l'ensemble du code R développé, un dossier **data** qui regroupe les différents fichiers de données utilisés par l'application, un dossier **docu** rassemblant des notices et divers éléments de documentation pour comprendre l’usage et la structure des fichiers du projet et enfin un dossier **tests** actuellement vide, dédié à l'implémentation de tests pour l'application dans le futur. 

L'application est structurée autour d'un fichier **app.R** composé d'une interface utilisateur (`ui`) et d'un serveur (`server`), complétés par des **modules** contenus dans le dossier `R/` ainsi qu'un fichier `global.R` et une feuille de style personnalisée `style.css` dans `www/`.

# 2. Structure générale de l'application (dossier src)

```src/
.
├── R/                      # Dossier des différents modules Shiny
│   ├── data_prep.R         # Préparation des données
│   ├── mod_serietemp.R     # Module des séries temporelles
│   ├── mod_map.R           # Module des cartes spatiales
│   ├── mod_stats.R         # Module des statistiques générales et des boxplots
│   ├── mod_summary.R       # Module du résumé statistique
│   └── mod_newsection.R    # Module vierge pour futures fonctionnalités
├── rsconnect/...           # Fichiers de déploiement ShinyApps.io
├── www/                    # Dossier des ressources web
│    └── style.css          # Feuille de style CSS personnalisée
├── app.R                   # Fichier principal de l'application
├── global.R                # Fichier global pour l'application
├── server.R                # Fichier serveur de l'application (back)
└── ui.R                    # Fichier UI de l'application (front)
```

# 3. Contenu du fichier `app.R`

## 3.1 Interface utilisateur (`ui.R`)

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

## 3.2 Serveur (`server.R`)

- Gestion des capteurs et DOY  
- Filtrage des données dans `filtered_data()`  
- Export CSV avec coordonnées géographiques  
- Activation des modules : `timeseriesServer()`, `statsServer()`, `mapServer()`, `summaryServer()`, `NewSectionServer()`

# 3.3 Contenu du fichier `global.R`

- Palette Okabe–Ito pour visualisations  
- Import des modules via `source()`  


---

# 5. Feuille de style `style.css`

Personnalisation des onglets, panels, boutons et balises `<details>`.

# 6. Différents modules de l'application Shiny

Tous les codes des divers modules sont organisés de la même manière avec une partie dediée au back de l'application (partie server) et une partie dediée au front (partie UI).

## 6.1 `mod_analyse.R`

Ce premier module permet :

- de construire une série temporelle complète en agrégeant les données par heure en faisant une décomposition additive classique (fonction decompose)
- de régler le cycle temporel sur lequel on veut tracer (journalier, hebdomadaire ou mensuel)
- d'afficher quatre graphiques : les données brutes, la tendance, la saisonnalité et les résidus


## 6.2 `mod_data.R`

Ce module est dédié à la préparation des données, il effectue :

- le chargement des données brutes provenant de divers fichiers csv et leur harmonisation
- l'enrichissement de ces dernières avec les températures de référence et le type d'habitat de chaque capteur 
- la génération d'une carte de fond avec OpenStreetMap lorsque les données sont disponibles


## 6.3 `mod_map.R`

Ce module génère une série de cartes générées à partir de l'ensemble des capteurs. Plus précisément, il réalise :

- le chargement automatique des images en format .png d'un dossier
- l'extraction de la date depuis le nom des fichiers 
- la conversion de la DOY en date réelle
- l'affichage d'une image légendée avec un slider permettant de sélectionner la date voulue

## 6.4 `mod_newsection.R`

Ce module fournit une page vide dans l'application prête à être complétée pour accueillir de nouvelles features. Il effectue :

- l'affichage d'un titre et d'un texte introductif
- la génération d'un panneau d'explication 
- la génération d'une structure UI minimale servant de base à une future page

## 6.5 `mod_serietemp.R`

Ce module permet d'afficher l'évolution temporelle de la variable choisie parmi 3 options avec un choix des capteurs et un code couleur pour chacune des années. Plus en détail, il dispose de :

- l'affichage d'une série temporelle continue des variables avec des couleurs pour chacune des années et un facettage des capteurs
- l'affichage d'un spinner animé pendant le rendu
- l'affichage d'une section repliable d'explications sur les données

## 6.6 `mod_stats.R`

Ce module gère l'affichage et le calcul des boxplots qui permettent de comparer la distribution d'une variable selon l'année et le capteur.

- affichage de boxplots pour chaque année avec un facettage par capteur et un spinner animé pendant le rendu
- gestion des valeurs aberrantes
- section repliable d'explications sur les données

## 6.7 `mod_summary.R`

Ce module Shiny affiche un ensemble de statistiques descriptives par capteur, ainsi que deux visualisations dédiées au capteur sélectionné. Il permet :

- l'affichage des valeurs minimales, maximales et moyennes de la variable choisie
- la sélection d'un capteur puis l'affichage des statistiques sur cet unique capteur
- l'intégration d'un graphique temporel et de boxplots pour le capteur choisi
- l'affichage d'une section repliable d'explications sur les données


## 6.8 `compilation-calibration-data.R`




# 7. Structure générale du dossier data

Le dossier data à vocation d'accueillir l'ensemble des fichiers de données utilisés ensuite dans les codes du dossier src qui construisent l'application.

```data/
.
├── derived-data/                   # dossier contenant les fichiers de données traités et recalibrés
│   ├── 250703.csv                  # 
│   ├── 250703_corr.csv             #
│   ├── correction.csv              #
│   └── data.calibr.csv             #
├── raw-data/                       #     
│   ├── 250703/                     # données brutes récoltées sur les capteurs 
│       ├── (n°02)                  # fichier de données du premier capteur (n°2)
│       ├──  ...                    # fichiers de données des autres capteurs
│       └── (n°38)                  # fichier de données du dernier capteur (n°38) 
│   ├── new-csv/                    # dossier vide dédié à l'accueil de nouvelles données
│   ├── data.terrain.corrige.csv    # 
│   ├── habitat.csv                 #
│   ├── listing-HOBO.xlsx           #
│   ├── map.osm                     #
│   └── temp_ref.csv                #
```


# 8. Structure générale du dossier docu

Ce dossier contient l'ensemble des notices qui permettent de comprendre le projet et ses différents codes.

```docu/
.
├── figures/                                  #
│   ├── fig-calibration/                      # dossier contenant diverses images concernant la calibration des capteurs
│       ├── data.calib.corr.png               #
│       ├── data.calib.moy.png                #
│       └── data.calib.png                    #   
│   └── sensor_map                            #
├── notices/                                  #
│   ├── Notice_utilisation_HOBO-MX2203.docx   #
│   └── Notice-analyse-donnees-HAV454H.docx   #
├── documentation.md                          #
├── Lien vers map capteurs.docx               #
└── Plan-capteur-HOBO.pdf                     #
```

# 9. Packages R requis pour le projet

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

**Pour installer tous les packages en une fois :**

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


# 11. Notice concernant l'ajout de nouvelles données 

Pour ajouter de nouvelles données et continuer d'utiliser l'application :

1) Commencer par prélever les données des différents capteurs sur le terrain en se référant au fichier Notice_utilisation_HOBO-MX2203.docx disponible dans le sous-dossier notices de docu
2) Déposer les fichiers de données des différents capteurs en suivant le chemin suivant : data\raw-data\new-csv\
3) Lancer le fichier compilation-calibration-data.R disponible dans le dossier src
4) Suivre les étapes du point précédent


# 12. Fonctionnement général de l'application

1. Choisir variable, années, capteurs, DOY, heures  
2. Cliquer sur **Mettre à jour**  
3. Modules génèrent graphiques et analyses sur les données filtrées  
4. (Optionnel) Cliquer sur **Exporter filtres** pour sauvegarder les filtres sélectionnés et les réutiliser ultérieurement