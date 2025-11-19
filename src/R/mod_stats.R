statsUI <- function(id) {
  ns <- NS(id)
  tagList(
    plotOutput(ns("boxplotPlot"), height = "500px")   # Hauteur fixée pour éviter chevauchements
  )
}

statsServer <- function(id, data, variable) {
  moduleServer(id, function(input, output, session) {
    
    output$boxplotPlot <- renderPlot({
      df <- data()
      var_name <- variable()
      
      req(nrow(df) > 0)
      
      ggplot(df, aes(
        x = as.factor(YYYY),
        y = .data[[var_name]],
        fill = as.factor(YYYY)
      )) +
        geom_boxplot(alpha = 0.7, outlier.size = 0.8) +
        
        labs(
          title = paste("Boxplot de", var_name),
          x = "Année",
          y = var_name,
          fill = "Année"
        ) +
        
        facet_wrap(~ sensor) +  
        theme_minimal(base_size = 12) +
        
        theme(
          axis.text.x = element_text(angle = 45, hjust = 1),   # Lisibilité
          panel.spacing = unit(1.3, "lines"),                  # Espacement = évite chevauchements
          strip.text = element_text(size = 13),                # Titres des facettes plus lisibles
          axis.text.y = element_text(size = 11),
          legend.position = "bottom"
        )
    })
    
  })
}
