timeseriesUI <- function(id) {
  ns <- NS(id)
  tagList(
    plotOutput(ns("tempPlot"), height = "500px")  # on fixe la hauteur pour éviter chevauchement
  )
}

timeseriesServer <- function(id, data, variable) {
  moduleServer(id, function(input, output, session) {
    
    output$tempPlot <- renderPlot({
      df <- data()
      var_name <- variable()
      
      # Vérifie qu'il y a des données
      req(nrow(df) > 0)
      
      ggplot(df, aes(x = date.time, y = .data[[var_name]],
                     color = as.factor(YYYY),
                     group = interaction(sensor, YYYY))) +
        geom_line(alpha = 0.6, linewidth = 0.6) +
        scale_color_manual(values = okabe_ito) +
        geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
        labs(
          title = paste(var_name, "en continu (horodaté)"),
          x = "Date et heure",
          y = var_name,
          color = "Année"
        ) +
        theme_minimal(base_size = 12) +
        theme(
          axis.text.x = element_text(angle = 45, hjust = 1),
          axis.text.y = element_text(size = 11),
          panel.spacing = unit(1.5, "lines")  # espace entre facettes
        ) +
        facet_wrap(~ sensor)
    })
    
  })
}
