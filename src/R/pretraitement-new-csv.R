library(readr)
library(openxlsx)
library(lubridate)

# Dossier contenant les CSV
folder_csv <- "../data/new-csv"

# Dossier de sortie
folder_xlsx <- "../data/raw-data"

# Créer le dossier de sortie s'il n'existe pas
if (!dir.exists(folder_xlsx)) {
  dir.create(folder_xlsx)
}

# Lister tous les fichiers CSV
csv_files <- list.files(folder_csv, pattern = "\\.csv$", full.names = TRUE)

if (length(csv_files) == 0) {
  stop("Aucun fichier CSV trouvé dans le dossier ", folder_csv)
}

# Fonction pour traiter un CSV et créer un XLSX
process_csv <- function(file_path) {
  # Lire le CSV
  df <- read_csv(file_path)
  
  # Garder uniquement les 3 premières colonnes
  df <- df[, 1:3]
  
  # Conversion de la 2e colonne en POSIXct
  date_col <- names(df)[2]
  df[[date_col]] <- parse_date_time(df[[date_col]],
                                    orders = c("mdY HMS", "mdY HM", "Ymd HMS", "Ymd HM", "dmy HMS", "dmy HM"),
                                    tz = "UTC")
  
  cat("Fichier :", basename(file_path), "→ Nombre de dates NA :", sum(is.na(df[[date_col]])), "\n")
  
  # Exporter en XLSX dans folder_xlsx
  new_file <- file.path(folder_xlsx, paste0(tools::file_path_sans_ext(basename(file_path)), ".xlsx"))
  write.xlsx(df, new_file, rowNames = FALSE)
  
  cat("Fichier XLSX créé :", basename(new_file), "\n")
}

# Appliquer à tous les fichiers CSV du dossier
lapply(csv_files, process_csv)
