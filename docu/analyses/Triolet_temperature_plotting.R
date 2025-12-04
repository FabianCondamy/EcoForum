# Installer et charger les bibliothèques nécessaires
librarian::shelf(shiny, ggplot2, dplyr, sf, maptiles, raster,
                 tidyterra, ggspatial, lubridate, tidyr)

# télécharger les données
ref <- read.csv("data/raw-data/temp_ref.csv", h=T, sep=",") %>%
  group_by(X_date)%>%
  summarise(temp.ref = mean(outside_temp))%>%
  mutate(date = ymd(X_date),
         YYYY = year(date),
         MM = month(date),
         DD = day(date)) %>%
  dplyr::select(-X_date)

temp <- read.csv("data/derived-data/250703_corr.csv", h=T, sep=";") %>%
  separate(coord, sep = ",", c("Longitude", "Latitude"))

habitat <- read.csv("data/raw-data/habitat.csv", h=T, sep=";") %>%
  rename(sensor = id) %>%
  select(sensor, type.zone)

# transformation de la matrice en objet spatial (sf)
temp <- st_as_sf(temp, # first argument = data frame with coordinates
                 coords = c("Latitude", "Longitude"), # name of columns, in quotation marks
                 crs = 4326) %>%
  st_transform("EPSG:2154") %>%
  mutate(
    date.time = ymd_hms(date.time),  # Convertir en format date-heure
    YYYY = year(date.time),
    MM = month(date.time),
    DD = day(date.time),
    HH = hour(date.time),
    Min = minute(date.time),
    SS = second(date.time)
  ) %>%
  mutate(doy = yday(make_date(YYYY, MM, DD))) %>%
  left_join(habitat) %>%
  left_join(ref) %>%
  mutate(temp.ecart.raw = temp.corr - temp.ref,
         temp.ecart.prc = (temp.corr - temp.ref)/temp.ref)
temp$month_name <- factor(month.name[temp$MM], levels = month.name)

# téléchargement des tuiles qui correspondent à la box 
# (osm par défaut, possibilité de changer)
tiles <- get_tiles(temp)

# représenter les points sur un fond de carte 

ggplot() +
  geom_sf(data = temp, aes(geometry = geometry), alpha = 0) +  
  geom_spatraster_rgb(data = tiles)+
  stat_sf_coordinates(data = temp, aes(color = temp.corr, size = temp.corr), 
                      geom = "point")+
  theme_minimal() +
  coord_sf()+ 
  theme(legend.position = "none")


