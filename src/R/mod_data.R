library(dplyr)
library(lubridate)
library(sf)
library(tidyr)
library(maptiles)
library(stringr)

ecoforum_data <- function(
    path_ref = "../data/raw-data/temp_ref.csv",
    path_habitat = "../data/raw-data/habitat.csv",
    path_temp = "../data/derived-data/250703_corr.csv",
    path_capteur = "../data/new-csv/data_one_sensor.csv"
) {
  
  # Chargement de la Référence et Habitat
  ref <- read.csv(path_ref, sep = ",") %>%
    group_by(X_date) %>%
    summarise(temp.ref = mean(outside_temp, na.rm = TRUE)) %>%
    mutate(date = ymd(X_date),
           YYYY = year(date), MM = month(date), DD = day(date)) %>%
    select(-X_date)
  
  habitat <- read.csv(path_habitat, sep = ";") %>%
    rename(sensor = id) %>%
    select(sensor, type.zone)
  
  # Initialisation des variables
  temp <- NULL
  tiles <- NULL



temp <- read.csv(path_temp, sep = ";") %>%
  separate(coord, sep = ",", into = c("Longitude", "Latitude")) %>%
  mutate(across(c(Longitude, Latitude), as.numeric)) %>%
  st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326) %>%
  st_transform("EPSG:2154") %>%
  mutate(date.time = ymd_hms(date.time),
         YYYY = year(date.time), MM = month(date.time), DD = day(date.time),
         HH = hour(date.time), Min = minute(date.time), SS = second(date.time),
         doy = yday(make_date(YYYY, MM, DD)))

# Carte : On calcule les tuiles car on a des coordonnées
bbox_global <- st_bbox(temp)
tiles <- tryCatch({
  get_tiles(bbox_global, crop = TRUE, provider = "OpenStreetMap")
}, error = function(e) return(NULL))

  
  # temp <- read.csv(path_capteur, sep = ",") %>%
  #   select(
  #     date_raw = Date.et.heure..CET.,
  #     temp_raw = Température.....C.
  #   ) %>%
  #   mutate(
  #     sensor = 99,
  #     temp.corr = as.numeric(temp_raw), # Conversion texte -> nombre
  #     date.time = mdy_hms(date_raw)     # Format US (Mois/Jour/Année)
  #   ) %>%
  #   filter(!is.na(date.time)) %>%
  #   mutate(
  #     YYYY = year(date.time), MM = month(date.time), DD = day(date.time),
  #     HH = hour(date.time), Min = minute(date.time), SS = second(date.time),
  #     doy = yday(date.time)
  #   )
  # 
  # # Pas de carte pour ce fichier (pas de GPS)
  # tiles <- NULL


  # Enrichissement
  temp_final <- temp %>%
    left_join(habitat, by = "sensor") %>%
    left_join(ref, by = c("YYYY", "MM", "DD")) %>%
    mutate(
      temp.ecart.raw = temp.corr - temp.ref,
      temp.ecart.prc = (temp.corr - temp.ref) / temp.ref
    )
  
  if("MM" %in% names(temp_final)){
    temp_final$month_name <- factor(month.name[temp_final$MM], levels = month.name)
  }
  
  return(list(data = temp_final, tiles = tiles))
}

dataServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    raw_data <- reactive({
      ecoforum_data()
    })
    return(raw_data)
  })
}