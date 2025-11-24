# библиотеки
library(dplyr)
library(ggplot2)
library(lubridate)
library(sf)
library(tidyr)
library(maptiles)

# палитра Okabe-Ito
okabe_ito <- c(
  "#CC79A7",      # rose
  "#0072B2",     # bleu
  "#009E73",     # vert
  "black",       # noir
  "#E69F00",     # orange
  "#56B4E9",     # bleu ciel
  "#F0E442",     # jaune
  "#D55E00"     # rouge
  
)

# Загрузка и подготовка данных
source("R/data_prep.R")

# Modules
source("R/mod_serietemp.R")
source("R/mod_map.R")
source("R/mod_stats.R")
source("R/mod_summary.R")
source("R/mod_newsection.R")