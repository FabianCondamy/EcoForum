library(shiny)

# UI et server
source("ui.R")
source("server.R")

# Lancer l'application
shinyApp(ui = ui, server = server)