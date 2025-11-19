library(dplyr)
library(lubridate)
library(sf)
library(tidyr)
library(maptiles)

# Cette fonction permet de récupérer les données
ecoforum_data <- function(
    path_ref = "../data/raw-data/temp_ref.csv",
    path_temp = "../data/derived-data/250703_corr.csv",
    path_habitat = "../data/raw-data/habitat.csv"
) {
  
  # 1. Chargement de la référence
  ref <- read.csv(path_ref, sep = ",") %>%
    group_by(X_date) %>%
    summarise(temp.ref = mean(outside_temp)) %>%
    mutate(date = ymd(X_date),
           YYYY = year(date),
           MM = month(date),
           DD = day(date)) %>%
    select(-X_date)
  
  # 2. Chargement de l'habitat
  habitat <- read.csv(path_habitat, sep = ";") %>%
    rename(sensor = id) %>%
    select(sensor, type.zone)
  
  # 3. Chargement et Traitement des Températures
  temp <- read.csv(path_temp, sep = ";") %>%
    separate(coord, sep = ",", into = c("Longitude", "Latitude")) %>%
    mutate(across(c(Longitude, Latitude), as.numeric)) %>%
    st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326) %>%
    st_transform("EPSG:2154") %>%
    mutate(date.time = ymd_hms(date.time),
           YYYY = year(date.time),
           MM = month(date.time),
           DD = day(date.time),
           HH = hour(date.time),
           Min = minute(date.time),
           SS = second(date.time),
           doy = yday(make_date(YYYY, MM, DD)))
  
  # 4. Enrichissement
  temp_final <- temp %>%
    left_join(habitat, by = "sensor") %>%
    left_join(ref, by = c("YYYY", "MM", "DD")) %>%
    mutate(temp.ecart.raw = temp.corr - temp.ref,
           temp.ecart.prc = (temp.corr - temp.ref) / temp.ref)
  
  temp_final$month_name <- factor(month.name[temp_final$MM], levels = month.name)
  
  # 5. Récupération des tuiles

  bbox_global <- st_bbox(temp_final)
  tiles <- tryCatch({
    get_tiles(bbox_global, crop = TRUE, provider = "OpenStreetMap")
  }, error = function(e) {
    warning("Impossible de charger les tuiles (pas de connexion ?)")
    return(NULL)
  })
  
  # 6. On retourne une LISTE contenant tout ce dont l'appli a besoin
  return(list(
    data = temp_final,
    tiles = tiles
  ))
}

dataServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    raw_data <- reactive({
      ecoforum_data()
    })
    
    return(raw_data)
  })
}