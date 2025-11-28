statsUI <- function(id) {
  ns <- NS(id)
  tagList(
    shinycssloaders::withSpinner(
      plotOutput(ns("boxplotPlot"), height = "500px"),
      type = 4,              # type de spinner
      color = "#56B4E9",     # couleur Okabe-Ito (bleu)
      size = 1.2             # taille du spinner
    ),
    tags$br(),
    tags$details(
      tags$summary("Explications (cliquer pour dérouler)"),
      tags$p("Ces boxplots montrent la distribution de la variable choisie pour chaque année et chaque capteur.")
    )
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
        scale_fill_manual(values = okabe_ito) +
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
