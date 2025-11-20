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
  
  # Crée une liste de tous les capteurs valides
  all_sensors <- sort(unique(temp$sensor))
  
  selected_sensors <- reactiveVal(NULL)
  
  # Function for processing the input string
  process_sensor_input <- function(txt, valid_sensors) {
    if (is.null(txt) || txt == "") return(NULL)
    txt <- gsub("^,+|,+$", "", gsub(" ", "", txt))
    nums <- as.numeric(unlist(strsplit(txt, ",")))
    nums <- nums[!is.na(nums)]
    if (!is.null(valid_sensors) && length(valid_sensors) > 0) {
      nums <- nums[nums %in% valid_sensors]
    }
    return(nums)
  }
  
  # button "Sélectionner tout"
  observeEvent(input$select_all_sensors, {
    updateTextInput(session, "sensor_input", value = paste(all_sensors, collapse = ","))
  })
  
  doy_range <- reactive({
    
    txt <- input$doy_input
    
    # default range
    if (is.null(txt) || txt == "") return(c(1, 365))
    
    # replace all possible separators with "-"
    clean <- gsub("[–—:]", "-", txt)
    clean <- gsub(" ", "", clean)
    
    parts <- unlist(strsplit(clean, "-"))
    nums <- suppressWarnings(as.numeric(parts))
    nums <- nums[!is.na(nums)]
    
    if (length(nums) < 2) return(c(1, 365))
    start <- min(nums[1], nums[2])
    end   <- max(nums[1], nums[2])

    start <- max(1, min(start, 365))
    end   <- max(1, min(end, 365))
    
    return(c(start, end))
  })
  
  data_available <- reactive({
    req(exists("temp"))
    req("YYYY" %in% names(temp))
    temp
  })
  
  # Remplissage dynamique des choix
  observe({
    
    df <- data_available()
    
    updateCheckboxGroupInput(session, "year_select",
                             choices = sort(unique(temp$YYYY)),
                             selected = unique(temp$YYYY))
    
#    updateCheckboxGroupInput(session, "sensor_select",
#                             choices = sort(unique(temp$sensor)),
#                             selected = unique(temp$sensor))
  })
  
  hour_range <- reactive({
    c(input$hour_start, input$hour_end)
  })
  
  filtered_data <- eventReactive(input$update, {
    
    selected <- process_sensor_input(input$sensor_input, all_sensors)
    req(length(selected) > 0, input$year_select)
    
    temp %>%
      filter(
        sensor %in% selected,
        YYYY %in% input$year_select,
        doy >= doy_range()[1], 
        doy <= doy_range()[2],
        HH >= hour_range()[1], 
        HH <= hour_range()[2]
      )
  })
  
  timeseriesServer("ts1", data = filtered_data, variable = reactive(input$variable))
  statsServer("stat1", data = filtered_data, variable = reactive(input$variable))
  mapServer("map1", data = filtered_data, variable = reactive(input$variable), tiles = tiles_global)
  summaryServer("sum1", data = filtered_data, variable = reactive(input$variable))
}
