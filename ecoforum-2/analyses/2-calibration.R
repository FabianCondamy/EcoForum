################################################################################ 
#                                                                              #
#                        CALIBRATION DONNEES CAPTEURS                          #
#                                 (HOBO MX2204)                                #
#                                                                              #
################################################################################


# Marine Zwicke
# Mars 2025
# HAV628B

#Chargement des librairies
library(tidyverse)
library(readxl)
library(ggplot2)

###### Partie 1 : visualiser les données de calibration ---- 

#### 1. Chargement des données----

# importer le jeu de données calibration
df <- read.csv(file = "data/derived-data/data.calibr.csv", header = TRUE, sep = ";", dec = ".")
head(df)

#### 2. Calcul des moyennes----

# on crée un tableau avec les moyennes des températures mesurées dans l'étuve par capteur
mean_by_sensor = df %>%
  group_by(sensor) %>% 
  summarise(m = mean(temperature))

# on calcule la moyenne des moyennes
global_mean = mean_by_sensor %>%
  summarise(m = mean(m)) %>% # ici, on otbient la moy des moy dans un tibble (format de tableau)
  as.double() # pour obtenir un objet contenant juste 1 valeur

#### 3. Visualisation des données----

# plot avec une courbe de température par capteur et une barre pour la moyenne
q1 <- ggplot(data = df, 
       aes(x = ymd_hms(date.time), 
           y = temperature,
           color = factor(sensor), group = sensor)) +
  #ylim(47, 48.5) +
        geom_point() + 
        geom_hline(yintercept = global_mean) +
  labs(x = element_blank(), 
       y = "Température mesurée (°C)", 
       color = 'n° capteur') + 
  theme_bw()
q1

# exporter le graphique :
ggsave("figures/fig-calibration/data.calib.png")

# plot avec les moyennes de températures
q2 <- ggplot(data = df, 
       aes(x = date.time, 
           y = temperature)) +
  ylim(47, 48.5) +
  geom_point(data = mean_by_sensor, 
             aes(x = ymd_hms('2024-03-25 01:00:00'), 
                 y = m)) +
  geom_hline(yintercept = global_mean) +
  labs(x = element_blank(),
       y = 'Température moyenne mesurée par capteur (°C)') +
  theme_bw() +
  theme(axis.text.x = element_blank())
q2
# exporter le graphique :
ggsave("figures/fig-calibration/data.calib.moy.png")


###### Partie 2 : Correction des données températures  ---- 


#### 1. Calcul de la correction à appliquer ####

# Tableau des corrections (moyenne globale - moyenne capteur)
correction = mean_by_sensor %>%
  mutate(corr = global_mean - m) %>% # pour calculer la correction 
  select(-m) # pour supprimer la colonne m du tableau 

# exporter le fichier :
write.table(correction, "data/derived-data/correction.csv", 
            col.names=T, row.names=F, sep=";", dec=".")

#### 2. Appliquer les corrections ####

# on combine le tableau correction avec le tableau df 
# on crée une nouvelle colonne avec la temp corrigée

df_corr = df %>%
  left_join(correction, by = "sensor") %>%
  mutate(temp.corr = temperature + corr)

# plot avec une courbe de température par capteur et une barre pour la moyenne
# avec les valeurs corrigées

q3 <- ggplot(data = df_corr, 
       aes(x = ymd_hms(date.time), 
           y = temp.corr,
           color = factor(sensor), group = sensor)) +
  ylim(47, 48.5) +
  geom_line(data = df_corr, 
            aes(x = ymd_hms(date.time), 
                y = temp.corr,
                color = factor(sensor))) + 
  geom_hline(yintercept = global_mean) +
  labs(x = element_blank(), 
       y = "Température mesurée (°C)", 
       color = 'n° capteur') + 
  theme_bw()
q3

# exporter le graphique :
ggsave("figures/fig-calibration/data.calib.corr.png")


#### 3. Exporter les données terrains corrigées ----

# charger le csv à corriger 
df_terrain = read.csv(file = "data/derived-data/250703.csv", header = TRUE, sep = ';', dec = '.') 
  
  # rajouter la correction à appliquer
df_terrain = df_terrain %>%
  left_join(correction, by = "sensor") %>%
  mutate(temp.corr = temperature + corr)

# on modifie le format de la date pour 
df_terrain = df_terrain %>% mutate(date.time = as.POSIXct(date.time))
head(df_terrain)
summary(df_terrain)

# exporter le nouveau fichier
write.table(df_terrain, "data/derived-data/250703_corr.csv", 
            row.names=FALSE, sep=";",dec=".", col.names = TRUE)


