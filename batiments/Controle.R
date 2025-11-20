#Pour contrôler la carte des bâtiments dans shiny
library(shiny)
library(leaflet) 
library(sf)

ui <- fluidPage(
  leafletOutput("map", height = 600)
)

server <- function(input, output, session) {
  
  # Charger le fichier nettoyé
  batiments <- st_read("batiments.geojson")
  
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$OpenStreetMap.Mapnik) %>%  # fond carte
      addPolygons(data = batiments,
                  color = "red", weight = 1,
                  fillColor = "red", fillOpacity = 1,
                  popup = ~name)
  })
}

shinyApp(ui, server)
