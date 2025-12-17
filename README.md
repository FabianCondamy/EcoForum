# EcoForum

## Description
Cette application Shiny permet d'analyser des données de température mesurées par différents capteurs répartis dans plusieurs zones. Elle propose des visualisations interactives (séries temporelles, carte, statistiques descriptives). L'application a été entièrement modularisée pour garantir la maintenabilité du code et faciliter le travail collaboratif.

---

## Structure du Projet

Le projet se structure de la manière suivante : 
```text
EcoForum/
├── data/ 
│   ├── batiments/                      # Contient les données géographiques des bâtiments et les scripts associés      
│   │       ├── batiments.geojson       # Géométrie finale utilisée pour l’interpolation (interp.R)
│   │       └── batiments_raw2.geojson  # Fichier brut avant nettoyage
│   │                      
│   ├── derived-data/                   # Dossier contenant les jeux de données dérivés après traitement, correction et calibration
│   ├── images/                         # Dossier contenant les cartes interpolées générées par le script interp.R
│   ├── new-csv/                        # Dossier de nouvelles données brutes à prétraiter   
│   └── raw-data/                       # Dossier regroupant l’ensemble des données brutes non traitées 
│
├── docu/                               # Documentation et archives
│   ├── analyses/                       # Dossier archives : anciens codes R
│   ├── figures/                        # Dossier archives : fichiers images du calibrage des capteurs
│   ├── notices/                        # Diverses notices sur l'utilisation de l'application et d'HOBO
│   ├── documentation_files/libs/       # Fichiers annexes à la documentation complète                      
│   ├── Lien vers map capteurs.docx     # Lien vers la carte interactive des capteurs
│   ├── Plan-capteurs-HOBO.pdf          # Plan des capteurs sur le site
│   ├── documentation.html              # Documentation complète de l'application       
│   └── documentation.md                # Version markdown de la documentation complète de l'application        
│
├── src/                                # Code source de l'application
│    ├── app.R                          # Lanceur de l'application
│    ├── server.R                       # Logique serveur (back-end)
│    ├── global.R                       # Palette Okabe–Ito (daltoniens)
│    ├── ui.R                           # Interface utilisateur (front-end)
│    └── R/                             # Dossier des différents modules et scripts R
│        ├── interp.R                   # Script de génération automatique des cartes interpolées
│        ├── pretraitement-new-csv.R    # Script de prétraitement des nouveaux fichiers de données des capteurs       
│        ├── mod_analyse.R              # Module : séries temporelles
│        ├── mod_data.R                 # Module : préparation des données
│        ├── mod_map.R                  # Module : cartes interpolées
│        ├── mod_newsection.R           # Module : nouvelle section
│        ├── mod_serietemp.R            # Module : graphique interactif de l'évolution temporelle d'une variable par capteur
│        ├── mod_stats.R                # Module : boxplots
│        ├── mod_summary.R              # Module : résumé statistique
│        └── nettoyage_geojson.R        # Script de nettoyage et préparation du geojson des bâtiments
└── tests/                              # Dossier "tests"
```
---
## Préparation des données : génération des cartes 

Avant de lancer l'application Shiny, il est indispensable d'exécuter le script `interp.R` (dans src/R/).
Ce script génère l'ensemble des cartes interpolées nécessaires au fonctionnement de la section cartographique.
Les cartes seront automatiquement enregistrées dans data/images/.

**Durée d'exécution :** 

Avec les données actuelles, le script met environ 2 heures à s'exécuter. Si davantage de données sont ajoutées dans le futur, le temps d'exécution augmentera proportionnellement.

Pour lancer ce script, ouvrir `interp.R` dans RStudio et exécuter l'intégralité du fichier.

## Installation et Lancement

Comme indiqué avant, les données doivent être présentes dans le dossier data/ à la racine du projet.

Une fois le script `interp.R` exécuté et les cartes générées, vous pouvez lancer l'application.

**Comment lancer l'application ?**

**Option 1 :**
1. Dans l'explorateur de fichiers de RStudio, naviguez dans le dossier src/.
2. Ouvrez le fichier `app.R`.
3. Cliquez sur le bouton "Run App" (flèche verte) en haut à droite de l'éditeur de script.

**Option 2 :**
Pour lancer l'application sans ambiguïté sur le répertoire de travail, exécutez cette commande depuis la racine du projet :
```r
shiny::runApp("src")
```

Note technique : les fichiers dans `src/R/` sont chargés automatiquement par Shiny au lancement, il n'est donc pas nécessaire de les sourcer manuellement (source()) dans `app.R`.

Note technique n°2 : lorsque l'on change la période et/ou les capteurs sélectionnés pour visualiser ce que l'on souhaite dans les différents onglets, il est parfois nécessaire de cliquer deux fois sur le bouton de mise à jour pour que cela fonctionne correctement.

## Ajout de nouvelles données

Pour ajouter de nouvelles données et continuer d'utiliser l'application :

1. Commencer par prélever les données des différents capteurs sur le terrain en se référant au fichier Notice_utilisation_HOBO-MX2203.docx disponible dans le sous-dossier notices de docu
2. Déposer les fichiers de données des différents capteurs en suivant le chemin suivant : data\new-csv\
3. Nommer correctement les fichiers, ils doivent commencer par "(n°XX)" où XX est le numéro du capteur
4. Compiler ensuite le fichier `pretraitement-new-csv.R` disponible dans src\R
5. Aller dans le dossier data\raw-data et déplacer les fichiers dans le sous-dossier new-data en supprimant l'ancienne version du fichier pour chaque capteur mis à jour

Pour plus d'informations, une documentation plus détaillée est disponible dans le dossier docu. (fichier `documentation.md`)
