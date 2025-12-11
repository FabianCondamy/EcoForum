# EcoForum

## Description
Cette application Shiny permet d'analyser des données de température mesurées par différents capteurs répartis dans plusieurs zones. Elle propose des visualisations interactives (séries temporelles, carte, statistiques descriptives). L'application a été entièrement modularisée pour garantir la maintenabilité du code et faciliter le travail collaboratif.

---

## Structure du Projet

Le projet se structure de la manière suivante : 
```text
EcoForum/
├── data/                   # Données du projet
│   ├── derived-data/       # Données recalibrées
│   ├── images/             # Cartes générées 
│   └── raw-data/           # Données brutes 
│
├── docu/                   # Documentation et archives
│   ├── analyses/           # Archives : anciens codes R
│   ├── figures/            # Archives : fichiers images du calibrage des capteurs
│   └── notices/            # Diverses notices sur l'utilisation de l'application et d'HOBO
│
└── src/                      # Code source de l'application
    ├── app.R                 # Lanceur de l'application
    ├── server.R              # Logique serveur (back-end)
    ├── ui.R                  # Interface utilisateur (front-end)
    └── R/                    # Modules et fonctions (chargés automatiquement)
        ├── mod_data.R        # Gestion des données
        ├── mod_map.R         # Module : cartographie interactive
        ├── mod_serietemp.R   # Module : séries temporelles
        ├── mod_analyse.R     # Module : décomposition d'une série temporelle
        ├── mod_stats.R       # Module : statistiques (Boxplots)
        ├── mod_video.R       # Module : vidéo
        ├── mod_stats.R       # Module : statistiques (Boxplots)
        ├── mod_newsection.R  # Module : nouvelle section
        └── mod_summary.R     # Module : tableau récapitulatif
```
---

## Installation et Lancement

Comme indiqué avant, les données doivent être présentes dans le dossier data/ à la racine du projet.

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

Pour plus d'informations, une documentation plus détaillée est disponible dans le dossier docu. (fichier `documentation.md`)
