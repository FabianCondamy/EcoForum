library(shiny)
library(ggplot2)
library(dplyr)
library(sf)
library(maptiles)
library(ggspatial)
library(tidyterra)
library(lubridate)

server <- function(input, output, session) {

  # Crée une liste de tous les capteurs valides
  all_sensors <- sort(unique(temp$sensor))
  all_sensors_str <- as.character(all_sensors)
  
  confirmed_sensors <- reactiveVal(all_sensors)
  
  # selectize in UI
  observe({
    updateSelectizeInput(
      session,
      "sensor_input",
      choices = all_sensors_str,
      selected = all_sensors_str,
      server = FALSE
    )
  })
  
  # button "Sélectionner tout"
  observeEvent(input$select_all_sensors, {
    updateSelectizeInput(session, 
                         "sensor_input", 
                         selected = all_sensors_str, 
                         server = FALSE)
    })
  
  selected_sensors <- reactive({
    req(input$sensor_input)
    nums <- as.numeric(input$sensor_input)
    nums[!is.na(nums) & nums %in% all_sensors]
  })
  
  # doy text calculation
  doy_to_date <- function(doy) {
    # thinking that every year 365 days
    month_days <- c(31,28,31,30,31,30,31,31,30,31,30,31)
    month_names <- c("Janv", "Févr", "Mars", "Avr", "Mai", "Juin",
                     "Juil", "Août", "Sept", "Oct", "Nov", "Déc")
    
    month <- 1
    remaining <- doy
    while(remaining > month_days[month]) {
      remaining <- remaining - month_days[month]
      month <- month + 1
    }
    day <- remaining
    paste0(day, " ", month_names[month])
  }
  
  # doy text under slider
  output$doy_text <- renderText({
    req(input$doy_range)
    start_date <- doy_to_date(input$doy_range[1])
    end_date   <- doy_to_date(input$doy_range[2])
    paste0("Du ", start_date, " au ", end_date)
  })
  
  data_available <- reactive({
    req(exists("temp"))
    req("YYYY" %in% names(temp))
    temp
  })
  
  # Primary filtering at start
  filtered_data <- reactiveVal(NULL)
  
  # Remplissage dynamique des choix
  observe({
    
    updateCheckboxGroupInput(session, "year_select",
                             choices = sort(unique(temp$YYYY)),
                             selected = unique(temp$YYYY))
    
    # sensors: selectize -> all_sensors
    updateSelectizeInput(session, "sensor_input",
                         choices = all_sensors,
                         selected = all_sensors,                        ,
                         server = TRUE)
    
    # DOY
    updateSliderInput(session, "doy_range", 
                      value = c(1, 365))
    
    # Heures (slider)
    updateSliderInput(session, "hour_range", 
                      value = c(0, 23))
  })
  
  
  # Primary filtering at start
  filtered_data <- reactiveVal(NULL)
  
  observe({
    
    # Use confirmed_sensors() so filtering changes only when confirmed (at start it's all_sensors)
    sel <- confirmed_sensors()
    if (is.null(sel) || length(sel) == 0) {
      filtered_data(NULL)
      return()
    }
    
    filtered <- temp %>%
      filter(
        sensor %in% sel,
        YYYY %in% unique(temp$YYYY),
        doy >= 1, doy <= 365,
        HH >= 0, HH <= 23
      )
    filtered_data(filtered)
  })
  
  observeEvent(input$clear_all, {

    updateCheckboxGroupInput(session, "year_select", selected = character(0))
    updateSliderInput(session, "doy_range", value = c(1, 365))
    updateSliderInput(session, "hour_range", value = c(0, 23))
    updateSelectizeInput(session, "sensor_input", selected = character(0), server = FALSE)
    
    confirmed_sensors(NULL)
  })
  
  observeEvent(input$clear_sensors, {
    updateSelectizeInput(session, "sensor_input", selected = character(0))
  })
  
  # Apply filters only when user clicks "update"
  observeEvent (input$update, {
    sel <- selected_sensors()
    req(!is.null(sel) && length(sel) > 0)
    req(!is.null(input$year_select) && length(input$year_select) > 0)
    
    confirmed_sensors(sel)
    
    filtered <- temp %>%
      filter(
        sensor %in% sel,
        YYYY %in% input$year_select,
        doy >= input$doy_range[1], 
        doy <= input$doy_range[2],
        HH >= input$hour_range[1], 
        HH <= input$hour_range[2]
      )
    filtered_data(filtered)
  })
  
  # Download des données filtrées
  output$download_filtered <- downloadHandler(
    filename = function() {
      var <- input$variable
      years <- paste(input$year_select, collapse = "-")
      doy <- input$doy_input
      sensors <- gsub(" ", "", input$sensor_input)
      paste0("donnees_filtrees_", var, "_", years, "_", doy, "_sensors", sensors, ".csv")
    },
    content = function(file) {
      df <- filtered_data()                  # sf intact
      coords <- sf::st_coordinates(df)       # matrice X/Y
      df_export <- sf::st_drop_geometry(df)  # copie sans géométrie
      df_export$Longitude <- coords[,1]
      df_export$Latitude  <- coords[,2]
      write.csv(df_export, file, row.names = FALSE)
    }
  )
  
  timeseriesServer("ts1", data = filtered_data, variable = reactive(input$variable))
  statsServer("stat1", data = filtered_data, variable = reactive(input$variable))
  mapServer("map1", data = filtered_data, variable = reactive(input$variable), tiles = tiles_global)
  summaryServer("sum1",filtered_data = filtered_data,selected_variable = reactive(input$variable))
  
  NewSectionServer("new_section")
}
