analyseUI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(12,
             selectInput(ns("freq_select"), "Cycle à observer :",
                         choices = c("Cycle Journalier (24h)" = 24,
                                     "Cycle Hebdomadaire (7 jours)" = 168),
                         selected = 24)
      )
    ),
    hr(),
    h4("Décomposition STL sur tout l'historique"),
    p("Ce graphique analyse l'ensemble des données pour extraire : la Tendance, la Saisonnalité et le Bruit."),
    plotOutput(ns("plot_decomp"), height = "600px")
  )
}

analyseServer <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    
    output$plot_decomp <- renderPlot({
      req(data())
      df <- data()
      
      req(nrow(df) > 24)
      
      df_calc <- df %>%
        mutate(time_unit = lubridate::floor_date(date.time, "hour")) %>%
        group_by(time_unit) %>%
        summarise(temp = mean(temp.corr, na.rm = TRUE), .groups = 'drop')
      
      freq <- as.numeric(input$freq_select)
      
      full_seq <- data.frame(
        time_unit = seq(min(df_calc$time_unit), max(df_calc$time_unit), by = "hour")
      )
      
      df_filled <- full_seq %>%
        left_join(df_calc, by = "time_unit") %>%
        mutate(temp = zoo::na.approx(temp, na.rm = FALSE)) %>%
        tidyr::fill(temp, .direction = "downup")
      
      ts_obj <- ts(df_filled$temp, frequency = freq)
      
      tryCatch({
        decomp <- stats::stl(ts_obj, s.window = "periodic")
        
        df_plot <- data.frame(
          Date = df_filled$time_unit,
          Brutes = as.numeric(ts_obj),
          Tendance = as.numeric(decomp$time.series[, "trend"]),
          Saisonnalité = as.numeric(decomp$time.series[, "seasonal"]),
          Résidus = as.numeric(decomp$time.series[, "remainder"])
        ) %>%
          tidyr::pivot_longer(cols = -Date, names_to = "Composante", values_to = "Valeur") %>%
          mutate(Composante = factor(Composante, 
                                     levels = c("Brutes", "Tendance", "Saisonnalité", "Résidus")))
        
        titre_cycle <- ifelse(freq == 24, "Cycle Journalier (24h)", "Cycle Hebdomadaire (7 jours)")
        
        ggplot(df_plot, aes(x = Date, y = Valeur)) +
          geom_line(color = "#2c3e50", size = 0.5) +
          facet_grid(Composante ~ ., scales = "free_y") +
          labs(title = paste("Analyse :", titre_cycle), 
               subtitle = "Analyse sur toute la période disponible",
               x = NULL, y = "Température (°C)") +
          theme_bw() +
          theme(strip.text = element_text(face = "bold", size = 11)) +
          scale_x_datetime(date_labels = "%b %Y", date_breaks = "2 months")
        
      }, error = function(e) {
        validate(need(FALSE, "Erreur de calcul. Les données sont peut-être insuffisantes."))
      })
    })
  })
}