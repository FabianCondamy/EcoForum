analyseUI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(12,
             selectInput(ns("freq_select"), "Cycle à observer :",
                         choices = c("Cycle Journalier (24h)" = 24,
                                     "Cycle Hebdomadaire (7 jours)" = 168,
                                     "Cycle Mensuel (30 jours)" = 720),
                         selected = 24, width = "100%")
      )
    ),
    hr(),
    h4("Décomposition Classique (Moyennes Mobiles)"),
    p("Ce graphique décompose la série temporelle en utilisant un modèle additif : Donnée = Tendance + Saisonnalité + Bruit."),
    plotOutput(ns("plot_decomp"), height = "600px")
  )
}
analyseServer <- function(id, data, variable_name = "temp.corr") {
  moduleServer(id, function(input, output, session) {
    
    output$plot_decomp <- renderPlot({
      # On vérifie que les données sont présentes
      req(data())
      df <- data()
      
      # On vérifie qu'il y a assez de données ?
      req(nrow(df) > 24)
      
      # Agrégation à l'heure
      df_calc <- df %>%
        mutate(time_unit = floor_date(date.time, "hour")) %>%
        group_by(time_unit) %>%
        summarise(temp = mean(.data[[variable_name]], na.rm = TRUE), .groups = 'drop')
      
      freq <- as.numeric(input$freq_select)
      
      # Séquence complète
      full_seq <- data.frame(
        time_unit = seq(min(df_calc$time_unit), max(df_calc$time_unit), by = "hour")
      )
      
      df_filled <- full_seq %>%
        left_join(df_calc, by = "time_unit") %>%
        mutate(temp = na.approx(temp, na.rm = FALSE)) %>%
        fill(temp, .direction = "downup")
      
      # Création TS
      ts_obj <- ts(df_filled$temp, frequency = freq)
      
      # Vérification : la série doit être plus longue que freq * 2
      if (length(ts_obj) < freq * 2) {
        validate(
          need(FALSE, "Pas assez de données pour effectuer une décomposition avec cette fréquence.")
        )
      }
      
      # Décomposition
      decomp <- try(stats::decompose(ts_obj, type = "additive"), silent = TRUE)
      
      if (inherits(decomp, "try-error")) {
        validate(
          need(FALSE, "Erreur lors de la décomposition : série trop courte ou fréquence incompatible.")
        )
      }
      
      # Mise en forme du dataframe
      df_plot <- data.frame(
        Date = df_filled$time_unit,
        Brutes = as.numeric(ts_obj),
        Tendance = as.numeric(decomp$trend),
        Saisonnalité = as.numeric(decomp$seasonal),
        Résidus = as.numeric(decomp$random)
      ) %>%
        pivot_longer(cols = -Date, names_to = "Composante", values_to = "Valeur") %>%
        mutate(Composante = factor(
          Composante,
          levels = c("Brutes", "Tendance", "Saisonnalité", "Résidus")
        ))
      
      # Choix des dates
      duree_jours <- as.numeric(difftime(max(df_filled$time_unit),
                                         min(df_filled$time_unit), units = "days"))
      
      if (duree_jours <= 30) {
        breaks_x <- "1 day"
        labels_x <- "%d %b"
      } else if (duree_jours <= 365) {
        breaks_x <- "1 month"
        labels_x <- "%b"
      } else {
        breaks_x <- "2 months"
        labels_x <- "%b %Y"
      }
      
      titre_cycle <- case_when(
        freq == 24 ~ "Cycle Journalier (24h)",
        freq == 168 ~ "Cycle Hebdomadaire (7 jours)",
        freq == 720 ~ "Cycle Mensuel (30 jours)",
        TRUE ~ "Autre Cycle"
      )
      
      cols <- c(
        "Brutes" = "#2c3e50",
        "Tendance" = "#d35400",
        "Saisonnalité" = "#2980b9",
        "Résidus" = "#7f8c8d"
      )
      
      # Plot final
      ggplot(df_plot, aes(x = Date, y = Valeur, color = Composante)) +
        geom_line(size = 0.6) +
        facet_grid(Composante ~ ., scales = "free_y") +
        scale_color_manual(values = cols) +
        labs(
          title = paste("Décomposition :", titre_cycle),
          subtitle = "Méthode des Moyennes Mobiles (Additive)",
          x = NULL, y = "Température (°C)"
        ) +
        theme_bw() +
        theme(
          strip.text = element_text(face = "bold", size = 11),
          legend.position = "none"
        ) +
        scale_x_datetime(date_labels = labels_x, date_breaks = breaks_x)
    })
    
  })
}