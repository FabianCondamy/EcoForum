library(shiny)
library(ggplot2)
library(dplyr)
library(sf)
library(maptiles)
library(ggspatial)
library(tidyterra)
library(lubridate)

# Palette daltonienne Okabe–Ito
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

server <- function(input, output, session) {
  
  # Remplissage dynamique des choix
  observe({
    updateCheckboxGroupInput(session, "year_select",
                             choices = sort(unique(temp$YYYY)),
                             selected = unique(temp$YYYY))
    
    updateCheckboxGroupInput(session, "sensor_select",
                             choices = sort(unique(temp$sensor)),
                             selected = unique(temp$sensor))
  })
  
  # Données filtrées (réactives)
  filtered_data <- eventReactive(input$update, {
    req(input$sensor_select, input$year_select)
    
    temp %>%
      filter(sensor %in% input$sensor_select,
             YYYY %in% input$year_select,
             doy >= input$doy_range[1], doy <= input$doy_range[2],
             HH >= input$hour_range[1], HH <= input$hour_range[2])
  })
  
  timeseriesServer("ts1", data = filtered_data, variable = reactive(input$variable))
  
  statsServer("stat1", data = filtered_data, variable = reactive(input$variable))
  
  mapServer("map1", data = filtered_data, variable = reactive(input$variable), tiles = tiles_global)
  
  summaryServer("sum1", data = filtered_data, variable = reactive(input$variable))
}
