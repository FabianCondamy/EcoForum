timeseriesUI <- function(id) {
  ns <- NS(id)
  tagList(
    plotOutput(ns("tempPlot"))
  )
}

timeseriesServer <- function(id, data, variable) {
  moduleServer(id, function(input, output, session) {
    
    output$tempPlot <- renderPlot({
      df <- data()
      var_name <- variable()
      
      # on attend d'avoir des données
      req(nrow(df) > 0)
      
      # Le graphique
      ggplot(df, aes(x = date.time, y = .data[[var_name]],
                     color = as.factor(YYYY),
                     group = interaction(sensor, YYYY))) +
        geom_line(alpha = 0.6, linewidth = 0.6) +
        geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
        labs(title = paste(var_name, "en continu (horodaté)"),
             x = "Date et heure", y = var_name, color = "Année") +
        theme_minimal() +
        facet_wrap(~ sensor)
    })
  })
}