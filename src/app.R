library(shiny)

# Modules
source("R/mod_serietemp.R")
source("R/mod_map.R")
source("R/mod_stats.R")
source("R/mod_summary.R")
source("R/mod_newsection.R")

# UI et server
source("ui.R")
source("server.R")
source("R/mod_data.R")
source("R/mod_map.R")
source("R/mod_serietemp.R")
source("R/mod_stats.R")
source("R/mod_summary.R")

# Lancer l'application
shinyApp(ui = ui, server = server)