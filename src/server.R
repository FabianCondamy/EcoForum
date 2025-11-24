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
  all_sensors_str <- as.character(all_sensors)
  
  confirmed_sensors <- reactiveVal(all_sensors)
  
  #  selected_sensors <- reactiveVal(NULL)
  
  # Function for processing the input string
  #  process_sensor_input <- function(txt, valid_sensors) {
  #    if (is.null(txt) || txt == "") return(NULL)
  #    txt <- gsub("^,+|,+$", "", gsub(" ", "", txt))
  #    nums <- as.numeric(unlist(strsplit(txt, ",")))
  #    nums <- nums[!is.na(nums)]
  #    if (!is.null(valid_sensors) && length(valid_sensors) > 0) {
  #      nums <- nums[nums %in% valid_sensors]
  #    }
  #    return(nums)
  #  }
  
  
  # --- заполнение selectize в UI при старте ---
  observe({
    updateSelectizeInput(
      session,
      "sensor_input",
      choices = all_sensors_str,
      selected = all_sensors_str,  # изначально все выбраны
      server = FALSE               # server = FALSE, чтобы дропдаун был полноценным
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
  
  # Primary filtering at start
  filtered_data <- reactiveVal(NULL)
  
  # Remplissage dynamique des choix
  observe({
    
    updateCheckboxGroupInput(session, "year_select",
                             choices = sort(unique(temp$YYYY)),
                             selected = unique(temp$YYYY))
    
    # sensors: заполняем selectize выбором и предзаполняем all_sensors
    updateSelectizeInput(session, "sensor_input",
                         choices = all_sensors,
                         selected = all_sensors,                        ,
                         server = TRUE)
    
    # DOY
    updateTextInput(session, "doy_input", 
                    value = "1-365")
    
    # Heures (slider)
    updateSliderInput(session, "hour_range", 
                      value = c(0, 23))
    
#    updateCheckboxGroupInput(session, "sensor_select",
#                             choices = sort(unique(temp$sensor)),
#                             selected = unique(temp$sensor))
  })
  
  hour_range <- reactive({
    input$hour_range
  })
  
  # Primary filtering at start
  filtered_data <- reactiveVal(NULL)
  
  observe({
    
    # Use confirmed_sensors() so filtering changes only when confirmed (at start it's all_sensors)
    sel <- confirmed_sensors()
    # если ничего не подтверждено — не фильтровать (или можно оставить пустой набор)
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
    updateTextInput(session, "doy_input", value = "")
    updateSliderInput(session, "hour_range", value = c(0, 23))
    updateSelectizeInput(session, "sensor_input", selected = character(0), server = FALSE)
    
    confirmed_sensors(NULL)
  })
  
  
  # Apply filters only when user clicks "update"
  observeEvent (input$update, {
    sel <- selected_sensors()
    req(!is.null(sel) && length(sel) > 0, input$year_select)
    
    confirmed_sensors(sel)
    
    filtered <- temp %>%
      filter(
        sensor %in% sel,
        YYYY %in% input$year_select,
        doy >= doy_range()[1], 
        doy <= doy_range()[2],
        HH >= hour_range()[1], 
        HH <= hour_range()[2]
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
  
  # Last panel 
  
  # global
  global_data <- reactive({
    req(filtered_data())
    var <- input$variable
    vals <- filtered_data()[[var]]
    vals
  })
  
  output$global_min <- renderText({
    vals <- global_data()
    if (is.null(vals) || all(is.na(vals))) return("NA")
    formatC(min(vals, na.rm = TRUE), digits = 3, format = "f")
  })
  
  output$global_mean <- renderText({
    vals <- global_data()
    if (is.null(vals) || all(is.na(vals))) return("NA")
    formatC(mean(vals, na.rm = TRUE), digits = 3, format = "f")
  })
  
  output$global_max <- renderText({
    vals <- global_data()
    if (is.null(vals) || all(is.na(vals))) return("NA")
    formatC(max(vals, na.rm = TRUE), digits = 3, format = "f")
  })
  
  # Single sensore - last panel
  single_sensor_data <- reactive({
    req(filtered_data())
    req(input$sensor_id)
    filtered_data() %>% filter(sensor == input$sensor_id)
  })
  
  output$sensor_min <- renderText({
    req(single_sensor_data())
    req(input$variable)
    var <- input$variable
    vals <- single_sensor_data()[[var]]
    if (is.null(vals) || all(is.na(vals))) return("NA")
    formatC(min(vals, na.rm = TRUE), digits = 3, format = "f")
  })
  
  output$sensor_mean <- renderText({
    req(single_sensor_data())
    req(input$variable)
    var <- input$variable
    vals <- single_sensor_data()[[var]]
    if (is.null(vals) || all(is.na(vals))) return("NA")
    formatC(mean(vals, na.rm = TRUE), digits = 3, format = "f")
  })
  
  output$sensor_max <- renderText({
    req(single_sensor_data())
    req(input$variable)
    var <- input$variable
    vals <- single_sensor_data()[[var]]
    if (is.null(vals) || all(is.na(vals))) return("NA")
    formatC(max(vals, na.rm = TRUE), digits = 3, format = "f")
  })
  
  single_variable <- reactive({ input$variable })
  
  timeseriesServer("ts1_single", single_sensor_data, single_variable)
  statsServer("stat1_single", single_sensor_data, single_variable)
  
  NewSectionServer("new_section")
}
