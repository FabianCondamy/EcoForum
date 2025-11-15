statsUI <- function(id) {
  ns <- NS(id)
  tagList(
    plotOutput(ns("boxplotPlot"))
  )
}

statsServer <- function(id, data, variable) {
  moduleServer(id, function(input, output, session) {
    
    output$boxplotPlot <- renderPlot({
      df <- data()
      var_name <- variable()
      
      req(nrow(df) > 0)
      
      ggplot(df, aes(x = as.factor(YYYY), y = .data[[var_name]],
                     fill = as.factor(YYYY))) +
        geom_boxplot(alpha = 0.7) +
        labs(title = paste("Boxplot de", var_name),
             x = "Année", y = var_name, fill = "Année") +
        facet_wrap(~ sensor) +
        theme_minimal()
    })
  })
}