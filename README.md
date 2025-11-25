# EcoForum

## Description
Cette application Shiny permet d'analyser des données de température mesurées par différents capteurs répartis dans plusieurs zones. Elle propose des visualisations interactives (séries temporelles, carte, statistiques descriptives). L'application a été entièrement modularisée pour garantir la maintenabilité du code et faciliter le travail collaboratif.

---

## Structure du Projet

Le projet se structure de la manière suivante : 
```text
EcoForum/
├── data/                   # Données du projet
│   ├── derived-data/       
│   ├── images/             
│   ├── new-csv/           
│   └── raw-data/         
│
├── docu/                   # Documentation et archives
│   ├── analyses/           
│   ├── figures/            
│   └── notices/            
│
└── src/                    # Code source de l'application
    ├── app.R               # Lanceur de l'application
    ├── server.R            # Logique serveur (Back-end)
    ├── ui.R                # Interface utilisateur (Front-end)
    └── R/                  # Modules et Fonctions (Chargement automatique)
        ├── mod_data.R      # Gestion des données
        ├── mod_map.R       # Module : Cartographie interactive
        ├── mod_serietemp.R # Module : Séries temporelles
        ├── mod_stats.R     # Module : Statistiques (Boxplots)
        └── mod_summary.R   # Module : Tableau récapitulatif
```
---

## Installation et Lancement

Les données doivent être présentes dans le dossier data/ à la racine du projet.

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

Note technique : Les fichiers dans `src/R/` sont chargés automatiquement par Shiny au lancement, il n'est donc pas nécessaire de les sourcer manuellement (source()) dans `app.R`.
