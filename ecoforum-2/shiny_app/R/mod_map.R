mapUI <- function(id) {
  ns <- NS(id)
  tagList(
    plotOutput(ns("mapPlot"))
  )
}

mapServer <- function(id, data, variable, tiles) {
  moduleServer(id, function(input, output, session) {
    
    output$mapPlot <- renderPlot({
      df <- data()
      var_name <- variable()
      
      # On vérifie qu'il y a des données
      req(nrow(df) > 0)
      
      ggplot() +
        geom_spatraster_rgb(data = tiles()) + 
        geom_sf(data = df, aes(color = .data[[var_name]]), size = 3) +
        scale_color_viridis_c(option = "plasma") +
        labs(title = "Localisation des Capteurs", color = var_name) +
        theme_minimal() +
        coord_sf()
    })
  })
}
