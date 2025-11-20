library(shiny)

# Modules
source("R/mod_serietemp.R")
source("R/mod_map.R")
source("R/mod_stats.R")
source("R/mod_summary.R")

# UI et server
source("ui.R")
source("server.R")

# Lancer l'application
shinyApp(ui = ui, server = server)