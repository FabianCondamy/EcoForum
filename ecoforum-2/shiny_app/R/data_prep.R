library(dplyr)
library(lubridate)
library(sf)
library(tidyr)
# Chargement des données
ref <- read.csv("../data/raw-data/temp_ref.csv", sep = ",") %>%
  group_by(X_date) %>%
  summarise(temp.ref = mean(outside_temp)) %>%
  mutate(date = ymd(X_date),
         YYYY = year(date),
         MM = month(date),
         DD = day(date)) %>%
  select(-X_date)

temp <- read.csv("../data/derived-data/250703_corr.csv", sep = ";") %>%
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

habitat <- read.csv("../data/raw-data/habitat.csv", sep = ";") %>%
  rename(sensor = id) %>%
  select(sensor, type.zone)

# Enrichissement
temp <- temp %>%
  left_join(habitat, by = "sensor") %>%
  left_join(ref, by = c("YYYY", "MM", "DD")) %>%
  mutate(temp.ecart.raw = temp.corr - temp.ref,
         temp.ecart.prc = (temp.corr - temp.ref) / temp.ref)

temp$month_name <- factor(month.name[temp$MM], levels = month.name)

bbox_global <- st_bbox(temp)
tiles_global <- get_tiles(bbox_global, crop = TRUE, provider = "OpenStreetMap")