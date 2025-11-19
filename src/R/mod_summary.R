summaryUI <- function(id) {
  ns <- NS(id)
  tagList(
    tableOutput(ns("summaryTable"))
  )
}
# Mettre bulle chargement (à voir si vraiment besoin)

summaryServer <- function(id, data, variable) {
  moduleServer(id, function(input, output, session) {
    
    output$summaryTable <- renderTable({
      df <- data()
      var <- variable()
      
      req(nrow(df) > 0)
      
      df %>%
        st_drop_geometry() %>%
        group_by(sensor, YYYY) %>%
        summarise(
          Moyenne = mean(.data[[var]], na.rm = TRUE),
          Ecart_type = sd(.data[[var]], na.rm = TRUE),
          Min = min(.data[[var]], na.rm = TRUE),
          Max = max(.data[[var]], na.rm = TRUE),
          N = n(),
          .groups = "drop"
        ) %>%
        arrange(sensor, YYYY)
    }, digits = 2)
  })
}