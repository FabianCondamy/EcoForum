summaryUI <- function(id) {
  ns <- NS(id)  
  
  tagList(
      fluidRow(
        # Statistiques globales
        column(4, wellPanel(
          style = "padding: 15px;",
          h4("Valeur minimale (globale)", align = "center"),
          tags$hr(),
          h3(textOutput(ns("global_min")), align = "center")
        )),
        column(4, wellPanel(
          style = "padding: 15px;",
          h4("Valeur moyenne (globale)", align = "center"),
          tags$hr(),
          h3(textOutput(ns("global_mean")), align = "center")
        )),
        column(4, wellPanel(
          style = "padding: 15px;",
          h4("Valeur maximale (globale)", align = "center"),
          tags$hr(),
          h3(textOutput(ns("global_max")), align = "center")
        ))
      ),
      
      tags$br(),
      
      fluidRow(
        column(3, wellPanel(
          h4("Choisir un capteur"),
          numericInput(ns("sensor_id"), "Numéro du capteur :", value = 1, min = 1)
        )),
        column(3, wellPanel(
          h4("Min (capteur choisi)"),
          textOutput(ns("sensor_min"))
        )),
        column(3, wellPanel(
          h4("Moyenne (capteur choisi)"),
          textOutput(ns("sensor_mean"))
        )),
        column(3, wellPanel(
          h4("Max (capteur choisi)"),
          textOutput(ns("sensor_max"))
        ))
      ),
      
      tags$br(),
      
      fluidRow(
        column(6, wellPanel(
          h4("Température vs DOY"),
          timeseriesUI(ns("ts1_single"))
        )),
        column(6, wellPanel(
          h4("Boxplots"),
          statsUI(ns("stat1_single"))
        ))
      ),
      
      tags$br(),
      tags$details(
        tags$summary("Explications (cliquer pour dérouler)"),
        tags$p("Cette page permet d'explorer les statistiques globales et celles d'un seul capteur sélectionné…")
      )
    )
}

summaryServer <- function(id, filtered_data, selected_variable) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    global_data <- reactive({
      req(filtered_data())
      var <- selected_variable()
      filtered_data()[[var]]
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
    
    single_sensor_data <- reactive({
      req(filtered_data())
      req(input$sensor_id)
      filtered_data() %>% filter(sensor == input$sensor_id)
    })
    
    output$sensor_min <- renderText({
      req(single_sensor_data())
      var <- selected_variable()
      vals <- single_sensor_data()[[var]]
      if (is.null(vals) || all(is.na(vals))) return("NA")
      formatC(min(vals, na.rm = TRUE), digits = 3, format = "f")
    })
    
    output$sensor_mean <- renderText({
      req(single_sensor_data())
      var <- selected_variable()
      vals <- single_sensor_data()[[var]]
      if (is.null(vals) || all(is.na(vals))) return("NA")
      formatC(mean(vals, na.rm = TRUE), digits = 3, format = "f")
    })
    
    output$sensor_max <- renderText({
      req(single_sensor_data())
      var <- selected_variable()
      vals <- single_sensor_data()[[var]]
      if (is.null(vals) || all(is.na(vals))) return("NA")
      formatC(max(vals, na.rm = TRUE), digits = 3, format = "f")
    })
    
    timeseriesServer("ts1_single", single_sensor_data, selected_variable)
    statsServer("stat1_single", single_sensor_data, selected_variable)
    
  })
}
