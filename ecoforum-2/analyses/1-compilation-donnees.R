################################################################################ 
#                                                                              #
#                   COMPILATION DONNEES CAPTEURS                               #
#                              (HOBO MX2203)                                   #
#                                                                              #
################################################################################

# Marine Zwicke
# Mars 2025
# HAV628B

#Chargement des librairies
library(tidyverse)
library(readxl)
library(stringr)

# 0. Pour commencer : quelques informations -----

## enregistrement  ----
# température de l'air
# pas de temps : toutes les 30 minutes

## calibration ----
#  tous les capteurs ont été placés dans une étuve entre 47 et 48°C 
# pendant un week-end : du 21/03 au 24/03/2024

## date début des enregistrement sur le campus ----
# capteurs n°1 à n°17 : début enregistrement 30/04
# capteurs n° 18 à 32 : début enregistrement 07/06
# capteurs 29, 32, 35, 35 et 37 non présents sur Campus


# 1.Chargement des données ----

# importer le fichier Listing-HOBO contenant les informations de chaque capteur
metadata <- read_xlsx("data/raw-data/Listing-HOBO.xlsx", col_names = T) 
head(metadata)

# créer une liste 'files.to.load' contenant le nom de tous les fichiers Excel à compiler
files.to.load = list.files(path = "data/raw-data/250703" )
files.to.load # vérifier que la liste des fichiers est complète 
length(files.to.load)

# on crée un objet 'df.capteur' qui est un dataframe contenant les données des capteurs
df.capteur = map_df(.x = files.to.load,
                    .f = ~{
                      read_xlsx(paste0("data/raw-data/250703/",.x)) %>%
                        mutate(sensor = as.numeric(str_sub(.x, 4,5), .before = '#')) %>%
                        rename('index'='#',
                               'date.time'= all_of(names(.)[2]),
                               'temperature'= all_of(names(.)[3]))
                    }) 

head(df.capteur)
summary(df.capteur)

dim(df.capteur)

# on compile les métadonnées et df.capteur selon le numéro du capteur
df.compil = df.capteur %>% 
  left_join(metadata, by = join_by(sensor))
head(df.compil)

# on modifier le format de la date pour 
df.compil <- df.compil %>% mutate(date.time = as.POSIXct(date.time))
head(df.compil)


#### 2. Filtrer les données ----

# on filtre les données pour garder uniquement les données de calibration du 23/03 minuit au 24/04 23:59
df.calibr = df.compil %>%
  filter(year(date.time) == 2024,
         month(date.time) == 3,
         day(date.time) %in% 23:24)
head(df.calibr)
summary(df.calibr)

#### on filtre les données  pour garder les donnees de terrain
# 
# pour les capteurs n°1 à n°17 : début des enregistrements 1/05
# pour les capteurs n° 18 à 32 : début des enregistrements 08/06


# on applique le filtre pour le premier lot de capteurs
df.lot1_capteurs = df.compil %>%
  filter(sensor %in% c(1:17) & date.time >= as.POSIXct("2024-06-07 14:00:00"))
head(df.lot1_capteurs)
summary(df.lot1_capteurs)

# on applique le filtre pour le 2e lot de capteurs
df.lot2_capteurs = df.compil %>%
  filter(sensor %in% c(18:31, 33, 36, 38) & date.time >= as.POSIXct("2024-06-07 14:00:00"))

# Combiner les deux dataframes
df.terrain = bind_rows(df.lot1_capteurs, df.lot2_capteurs) %>%
  group_by(sensor)
head(df.terrain)
summary(df.terrain)

#### 3. Export des données ----

# on exporte toutes ces données dans un fichiers en .csv dans le dossier "TD-analyse-donnees"
write.table(df.calibr, "data/derived-data/data.calibr.csv", row.names=FALSE, sep=";",dec=".", col.names = TRUE)
write.table(df.terrain, "data/derived-data/250703.csv", row.names=FALSE, sep=";",dec=".", col.names = TRUE) 

