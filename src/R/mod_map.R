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
      
      # Vérification : Est-ce qu'on a des données ?
      req(nrow(df) > 0)
      
      # Vérification : Est-ce qu'on a un fond de carte ?
      validate(
        need(!is.null(tiles()), "Ce fichier ne contient pas de coordonnées GPS. Impossible d'afficher la carte.")
      )
      
      ggplot() +
        tidyterra::geom_spatraster_rgb(data = tiles()) + 
        geom_sf(data = df, aes(color = .data[[var_name]]), size = 3) +
        scale_color_viridis_c(option = "plasma") +
        labs(title = "Localisation des Capteurs", color = var_name) +
        theme_minimal() +
        coord_sf()
    })
  })
}