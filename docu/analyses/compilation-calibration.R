################################################################################ 
#                                                                              #
#                   COMPILATION ET CALIBRATION DONNEES CAPTEURS               #
#                              (HOBO MX2203 / MX2204)                          #
#                                                                              #
################################################################################

# Marine Zwicke
# Mars 2025
# HAV628B

# Chargement des librairies
library(tidyverse)
library(readxl)
library(stringr)
library(ggplot2)
library(lubridate)

#### 0. Informations sur les capteurs ----
# Pas de temps : toutes les 30 minutes
# Calibration : tous les capteurs dans étuve 47-48°C, du 21/03 au 24/03/2024
# Début enregistrement :
#  - capteurs 1 à 17 : 30/04
#  - capteurs 18 à 32 : 07/06
# Capteurs 29, 32, 35, 35 et 37 non présents sur campus

#### 1. Chargement des données ----

# Metadata des capteurs
metadata <- read_xlsx("data/raw-data/Listing-HOBO.xlsx", col_names = TRUE)

# Liste des fichiers Excel à compiler
files.to.load <- list.files(path = "data/raw-data/new-data")
length(files.to.load)

# Compilation des données brutes
df.capteur <- map_df(files.to.load, ~{
  read_xlsx(paste0("data/raw-data/new-data/", .x)) %>%
    mutate(sensor = as.numeric(str_sub(.x, 4,5), .before = '#')) %>%
    rename('index' = '#',
           'date.time' = all_of(names(.)[2]),
           'temperature' = all_of(names(.)[3]))
})

# Merge avec les métadonnées
df.compil <- df.capteur %>% 
  left_join(metadata, by = join_by(sensor)) %>%
  mutate(date.time = as.POSIXct(date.time))

#### 2. Filtrage des données ----

# Calibration : 23/03/2024 minuit -> 24/03/2024 23:59
df.calibr <- df.compil %>%
  filter(year(date.time) == 2024,
         month(date.time) == 3,
         day(date.time) %in% 23:24)

# Données terrains
df.lot1 <- df.compil %>%
  filter(sensor %in% 1:17 & date.time >= as.POSIXct("2024-06-07 14:00:00"))
df.lot2 <- df.compil %>%
  filter(sensor %in% c(18:31, 33, 36, 38) & date.time >= as.POSIXct("2024-06-07 14:00:00"))

df.terrain <- bind_rows(df.lot1, df.lot2) %>% group_by(sensor)

#### 3. Export des données brutes ----
write.table(df.calibr, "data/derived-data/data.calibr.csv", 
            row.names = FALSE, sep = ";", dec = ".", col.names = TRUE)
write.table(df.terrain, "data/derived-data/new-data.csv", 
            row.names = FALSE, sep = ";", dec = ".", col.names = TRUE)

#### 4. Visualisation et calcul de la calibration ----

# Charger le fichier calibration
df <- read.csv("data/derived-data/data.calibr.csv", header = TRUE, sep = ";", dec = ".")

# Moyenne par capteur
mean_by_sensor <- df %>%
  group_by(sensor) %>%
  summarise(m = mean(temperature))

# Moyenne globale
global_mean <- mean(mean_by_sensor$m)

# Plot température par capteur
q1 <- ggplot(df, aes(x = ymd_hms(date.time), y = temperature, color = factor(sensor), group = sensor)) +
  geom_point() +
  geom_hline(yintercept = global_mean) +
  labs(x = "", y = "Température mesurée (°C)", color = "n° capteur") +
  theme_bw()
ggsave("figures/fig-calibration/data.calib.png")

# Plot avec moyennes
q2 <- ggplot(df, aes(x = date.time, y = temperature)) +
  ylim(47, 48.5) +
  geom_point(data = mean_by_sensor, aes(x = ymd_hms('2024-03-25 01:00:00'), y = m)) +
  geom_hline(yintercept = global_mean) +
  labs(x = "", y = "Température moyenne par capteur (°C)") +
  theme_bw() +
  theme(axis.text.x = element_blank())
ggsave("figures/fig-calibration/data.calib.moy.png")

#### 5. Correction des températures ----

# Calcul de la correction
correction <- mean_by_sensor %>%
  mutate(corr = global_mean - m) %>%
  select(sensor, corr)

write.table(correction, "data/derived-data/correction.csv", col.names = TRUE, row.names = FALSE, sep = ";", dec = ".")

# Application de la correction aux données calibration
df_corr <- df %>%
  left_join(correction, by = "sensor") %>%
  mutate(temp.corr = temperature + corr)

# Plot des températures corrigées
q3 <- ggplot(df_corr, aes(x = ymd_hms(date.time), y = temp.corr, color = factor(sensor), group = sensor)) +
  geom_line() +
  geom_hline(yintercept = global_mean) +
  labs(x = "", y = "Température corrigée (°C)", color = "n° capteur") +
  theme_bw()
ggsave("figures/fig-calibration/data.calib.corr.png")

#### 6. Application des corrections aux données terrains ----

df_terrain <- read.csv("data/derived-data/new-data.csv", header = TRUE, sep = ";", dec = ".") %>%
  left_join(correction, by = "sensor") %>%
  mutate(temp.corr = temperature + corr,
         date.time = as.POSIXct(date.time))

write.table(df_terrain, "data/derived-data/new-data_corr.csv", 
            row.names = FALSE, sep = ";", dec = ".", col.names = TRUE)
