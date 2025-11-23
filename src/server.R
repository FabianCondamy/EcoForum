library(shiny)
library(ggplot2)
library(dplyr)
library(sf)
library(maptiles)
library(ggspatial)
library(tidyterra)
library(lubridate)

server <- function(input, output, session) {
  # On récupère les données chargées (c'est une reactive)
  data_loaded <- dataServer("data_source")
  
  # Extrait le dataframe et les tuiles
  dataset <- reactive({ data_loaded()$data })
  tiles   <- reactive({ data_loaded()$tiles })
  
  
  # 3. Mise à jour des inputs (Listes déroulantes)
  observe({
    # On attend que les données soient là
    req(dataset())
    df <- dataset()
    
    updateCheckboxGroupInput(session, "year_select",
                             choices = sort(unique(df$YYYY)),
                             selected = unique(df$YYYY))
    
    updateCheckboxGroupInput(session, "sensor_select",
                             choices = sort(unique(df$sensor)),
                             selected = unique(df$sensor))
  })
  
  # 4. Filtrage des données
  filtered_data <- eventReactive(input$update, {
    req(input$sensor_select, input$year_select, dataset())
    
    dataset() %>%
      filter(sensor %in% input$sensor_select,
             YYYY %in% input$year_select,
             doy >= input$doy_range[1], doy <= input$doy_range[2],
             HH >= input$hour_range[1], HH <= input$hour_range[2])
  }, ignoreNULL = FALSE)
  
  
  # 5. Appel des Modules de Visualisation
  timeseriesServer("ts1", data = filtered_data, variable = reactive(input$variable))
  
  statsServer("stat1", data = filtered_data, variable = reactive(input$variable))
  
  mapServer("map1", data = filtered_data, variable = reactive(input$variable), tiles = tiles)
  
  summaryServer("sum1", data = filtered_data, variable = reactive(input$variable))
}