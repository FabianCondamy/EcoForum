library(shiny)
library(ggplot2)
library(dplyr)
library(sf)
library(maptiles)
library(ggspatial)
library(tidyterra)
library(lubridate)

source("data_prep.R")

bbox_global <- st_bbox(temp)
tiles_global <- get_tiles(bbox_global, crop = TRUE, provider = "OpenStreetMap")
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
  
  # Graphique : Température vs DOY
  output$tempPlot <- renderPlot({
    df <- filtered_data()
    
    ggplot(df, aes(x = date.time, y = .data[[input$variable]],
                   color = as.factor(YYYY),
                   group = interaction(sensor, YYYY))) +
      geom_line(alpha = 0.6, linewidth = 0.6) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
      labs(title = paste(input$variable, "en continu (horodaté)"),
           x = "Date et heure", y = input$variable, color = "Année") +
      theme_minimal() +
      facet_wrap(~ sensor)
  })
  
  # Graphique : Boxplots
  output$boxplotTemp <- renderPlot({
    ggplot(filtered_data(), aes(x = as.factor(YYYY), y = .data[[input$variable]],
                                fill = as.factor(YYYY))) +
      geom_boxplot(alpha = 0.7) +
      labs(title = paste("Boxplot de", input$variable),
           x = "Année", y = input$variable) +
      facet_wrap(~ sensor) +
      theme_minimal()
  })
  
  # Carte des capteurs
  output$mapPlot <- renderPlot({
    df <- filtered_data()
    req(nrow(df) > 0)
    ggplot() +
      geom_spatraster_rgb(data = tiles_global) +
      geom_sf(data = df, aes(color = .data[[input$variable]]), size = 3) +
      scale_color_viridis_c(option = "plasma") +
      labs(title = "Localisation des Capteurs", color = input$variable) +
      theme_minimal() +
      coord_sf()
  })
  
  # Tableau résumé
  output$summaryTable <- renderTable({
    df <- filtered_data()
    var <- input$variable
    
    df %>%
      st_drop_geometry() %>%
      group_by(sensor, YYYY) %>%
      summarise(
        Moyenne = mean(.data[[var]], na.rm = TRUE),
        Écart_type = sd(.data[[var]], na.rm = TRUE),
        Min = min(.data[[var]], na.rm = TRUE),
        Max = max(.data[[var]], na.rm = TRUE),
        N = n(),
        .groups = "drop"
      ) %>%
      arrange(sensor, YYYY)
  }, digits = 2)
}
