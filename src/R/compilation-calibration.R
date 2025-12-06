# ============================================================
#   Compilation et calibration des données HOBO
# ============================================================

# ------------------------------------------------------------
# 0. Chargement des librairies
# ------------------------------------------------------------
library(tidyverse)
library(readxl)
library(ggplot2)
library(stringr)
library(lubridate)

# ------------------------------------------------------------
# 1. Chargement des données
# ------------------------------------------------------------

# Import du fichier Listing-HOBO contenant les métadonnées
metadata <- read_xlsx("../data/raw-data/Listing-HOBO.xlsx", col_names = TRUE)

# Liste des fichiers Excel dans le dossier new-data/
files.to.load <- list.files(path = "../data/raw-data/new-data/")
files.to.load   # Vérification

# Compilation des fichiers capteurs
df.capteur <- map_df(
  .x = files.to.load,
  .f = ~ {
    read_xlsx(paste0("../data/raw-data/new-data/", .x)) %>%
      mutate(sensor = as.numeric(str_sub(.x, 4, 5), .before = '#')) %>%
      rename(
        index = '#',
        date.time = all_of(names(.)[2]),
        temperature = all_of(names(.)[3])
      )
  }
)

# Jointure avec les métadonnées
df.compil <- df.capteur %>%
  left_join(metadata, by = join_by(sensor)) %>%
  mutate(date.time = as.POSIXct(date.time))

# ------------------------------------------------------------
# 2. Filtrer les données
# ------------------------------------------------------------

# ---- 2a. Données de calibration (étuve : 23-24 mars 2024)
df.calibr <- df.compil %>%
  filter(
    year(date.time) == 2024,
    month(date.time) == 3,
    day(date.time) %in% 23:24
  )

# ---- 2b. Données de terrain
# Capteurs 1 à 17 : enregistrements >= 07/06/2024 à 14h
df.lot1_capteurs <- df.compil %>%
  filter(sensor %in% 1:17 & date.time >= as.POSIXct("2024-06-07 14:00:00"))

# Capteurs 18 à 32 + 33, 36, 38 : même date
df.lot2_capteurs <- df.compil %>%
  filter(sensor %in% c(18:31, 33, 36, 38) & date.time >= as.POSIXct("2024-06-07 14:00:00"))

# Fusion terrain
df.terrain <- bind_rows(df.lot1_capteurs, df.lot2_capteurs) %>%
  group_by(sensor)

# ------------------------------------------------------------
# 3. Export des données brutes filtrées
# ------------------------------------------------------------
write.table(df.calibr, "../data/derived-data/data.calibr.csv",
            row.names = FALSE, sep = ";", dec = ".", col.names = TRUE)

write.table(df.terrain, "../data/derived-data/new-data.csv",
            row.names = FALSE, sep = ";", dec = ".", col.names = TRUE)

# ============================================================
# PARTIE 2 : Visualisation et préparation des corrections
# ============================================================

# ------------------------------------------------------------
# 1. Recharger les données de calibration
# ------------------------------------------------------------
df <- read.csv("../data/derived-data/data.calibr.csv",
               header = TRUE, sep = ";", dec = ".")

# ------------------------------------------------------------
# 2. Calcul des moyennes
# ------------------------------------------------------------

# Moyenne par capteur
mean_by_sensor <- df %>%
  group_by(sensor) %>%
  summarise(m = mean(temperature))

# Moyenne globale
global_mean <- mean_by_sensor %>%
  summarise(m = mean(m)) %>%
  as.double()

# ============================================================
# PARTIE 3 : Correction des données
# ============================================================

# ------------------------------------------------------------
# 1. Calcul des corrections
# ------------------------------------------------------------
correction <- mean_by_sensor %>%
  mutate(corr = global_mean - m) %>%
  select(-m)

write.table(correction, "../data/derived-data/correction.csv",
            col.names = TRUE, row.names = FALSE, sep = ";", dec = ".")

# ------------------------------------------------------------
# 2. Appliquer la correction : données calibration
# ------------------------------------------------------------
df_corr <- df %>%
  left_join(correction, by = "sensor") %>%
  mutate(temp.corr = temperature + corr)


# ------------------------------------------------------------
# 3. Appliquer la correction : données terrain
# ------------------------------------------------------------
df_terrain <- read.csv("../data/derived-data/new-data.csv",
                       header = TRUE, sep = ";", dec = ".")

df_terrain <- df_terrain %>%
  left_join(correction, by = "sensor") %>%
  mutate(
    temp.corr = temperature + corr,
    date.time = as.POSIXct(date.time)
  )

write.table(df_terrain, "../data/derived-data/new-data_corr.csv",
            row.names = FALSE, sep = ";", dec = ".", col.names = TRUE)

