#exportation du geojson depuis https://overpass-turbo.eu/ script :
  #// Faculté des Sciences Montpellier
  #[out:json][timeout:55];(way["building"](43.630,3.860,43.640,3.870);relation["building"](43.630,3.860,43.640,3.870););out body;>;out skel qt;
  # coordonnées précisées dans un 2ème temps 20/11/2025
library(sf)
library(dplyr)

# Charger le fichier brut
batiments <- st_read("batiments_raw2.geojson")

# Garder uniquement les polygones
batiments_poly <- batiments %>%
  filter(st_geometry_type(.) %in% c("POLYGON", "MULTIPOLYGON"))

# Filtrer uniquement les bâtiments dont building est university ou yes
batiments_univ <- batiments_poly %>%
  filter(building %in% c("university", "yes"))

# Autres batiments en trop:


# Sauvegarder le fichier nettoyé
st_write(batiments_univ, "batiments.geojson", delete_dsn = TRUE)
