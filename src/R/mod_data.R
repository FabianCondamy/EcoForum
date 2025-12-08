library(dplyr)
library(tidyr)
library(lubridate)
library(readxl)
library(ggplot2)
library(stringr)
library(sf)
library(maptiles)

#  Ce fichier compile, calibre, corrige et prépare les données HOBO

ecoforum_data <- function(
    path_ref = "../data/raw-data/temp_ref.csv",
    path_habitat = "../data/raw-data/habitat.csv",
    
    # Fichiers nécessaires à la compilation HOBO :
    path_metadata = "../data/raw-data/Listing-HOBO.xlsx",
    path_newdata = "../data/raw-data/new-data/",
    path_export_calibr = "../data/derived-data/data.calibr.csv",
    path_export_terrain = "../data/derived-data/new-data.csv",
    path_export_corr = "../data/derived-data/correction.csv",
    path_export_corr_terrain = "../data/derived-data/new-data_corr.csv"
) {
  
  # 0. COMPILATION AUTOMATIQUE DES DONNÉES HOBO
  
  if (dir.exists(path_newdata)) {
    
    message("→ Compilation des fichiers HOBO...")
    
    metadata <- read_xlsx(path_metadata, col_names = TRUE)
    files.to.load <- list.files(path_newdata)
    
    df.capteur <- purrr::map_df(
      .x = files.to.load,
      .f = ~ {
        read_xlsx(paste0(path_newdata, .x)) %>%
          mutate(sensor = as.numeric(str_sub(.x, 4, 5), .before = '#')) %>%
          rename(
            index = '#',
            date.time = all_of(names(.)[2]),
            temperature = all_of(names(.)[3])
          )
      }
    )
    
    df.compil <- df.capteur %>%
      left_join(metadata, by = join_by(sensor)) %>%
      mutate(date.time = as.POSIXct(date.time))
    
    # Calibration issue du 23–24 mars 2024

    df.calibr <- df.compil %>%
      filter(
        year(date.time) == 2024,
        month(date.time) == 3,
        day(date.time) %in% 23:24
      )
    
    # Terrain
    df.lot1 <- df.compil %>%
      filter(sensor %in% 1:17 & date.time >= as.POSIXct("2024-06-07 14:00:00"))
    
    df.lot2 <- df.compil %>%
      filter(sensor %in% c(18:31, 33, 36, 38) & date.time >= as.POSIXct("2024-06-07 14:00:00"))
    
    df.terrain <- bind_rows(df.lot1, df.lot2)
    
    # Exports
    write.table(df.calibr, path_export_calibr, row.names = FALSE, sep = ";", dec = ".", col.names = TRUE)
    write.table(df.terrain, path_export_terrain, row.names = FALSE, sep = ";", dec = ".", col.names = TRUE)
    

    # Calcul correction température

    mean_by_sensor <- df.calibr %>%
      group_by(sensor) %>%
      summarise(m = mean(temperature))
    
    global_mean <- mean(mean_by_sensor$m)
    
    correction <- mean_by_sensor %>%
      mutate(corr = global_mean - m) %>%
      select(sensor, corr)
    
    write.table(correction, path_export_corr, row.names = FALSE, sep = ";", dec = ".", col.names = TRUE)
    

    # Appliquer correction au terrain

    df_terrain <- read.csv(path_export_terrain, sep = ";", dec = ".")
    
    df_terrain <- df_terrain %>%
      left_join(correction, by = "sensor") %>%
      mutate(
        temp.corr = temperature + corr,
        date.time = as.POSIXct(date.time)
      )
    
    write.table(df_terrain, path_export_corr_terrain,
                row.names = FALSE, sep = ";", dec = ".", col.names = TRUE)
    
    message("✓ Compilation HOBO terminée.")
  }
  

  # 1. CHARGEMENT POUR L’APPLICATION (après correction)

  
  temp <- read.csv(path_export_corr_terrain, sep = ";") %>%
    separate(coord, into = c("Longitude", "Latitude"), sep = ",") %>%
    mutate(across(c(Longitude, Latitude), as.numeric)) %>%
    st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326) %>%
    st_transform(2154) %>%
    mutate(
      date.time = ymd_hms(date.time),
      YYYY = year(date.time), MM = month(date.time), DD = day(date.time),
      HH = hour(date.time), Min = minute(date.time), SS = second(date.time),
      doy = yday(date.time)
    )
  
  # 2. Habitat et Référence
  
  habitat <- read.csv(path_habitat, sep = ";") %>%
    rename(sensor = id)
  
  ref <- read.csv(path_ref, sep = ",") %>%
    group_by(X_date) %>%
    summarise(temp.ref = mean(outside_temp, na.rm = TRUE)) %>%
    mutate(
      date = ymd(X_date),
      YYYY = year(date), MM = month(date), DD = day(date)
    ) %>%
    select(-X_date)

  # 3. Jointures et enrichissements

  
  temp_final <- temp %>%
    left_join(habitat, by = "sensor") %>%
    left_join(ref, by = c("YYYY", "MM", "DD")) %>%
    mutate(
      temp.ecart.raw = temp.corr - temp.ref,
      temp.ecart.prc = (temp.corr - temp.ref) / temp.ref,
      month_name = factor(month.name[MM], levels = month.name)
    )
  
  # 4. Tuiles cartographiques (si coordonnées)
  
  bbox_global <- st_bbox(temp_final)
  
  tiles <- tryCatch({
    get_tiles(bbox_global, crop = TRUE, provider = "OpenStreetMap")
  }, error = function(e) NULL)
  
  # ------------------------------------------------------------
  # Retour
  # ------------------------------------------------------------
  return(list(data = temp_final, tiles = tiles))
}


#  MODULE SERVER POUR APP SHINY


dataServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    raw_data <- ecoforum_data()
    return(raw_data)
  })
}

