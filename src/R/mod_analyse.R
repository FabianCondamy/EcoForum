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
    h4("Décomposition STL"),
    p("Décomposition utilisant la méthode STL."),
    plotOutput(ns("plot_decomp"), height = "600px"),
    tags$details(
      tags$summary("Explications (cliquer pour dérouler)"),
      tags$p(
        "Sur les capteurs sélectionnés, nous décomposons l’évolution au cours du temps de la température (moyenne sur les capteurs).
  Les données sont préalablement agrégées à l’échelle horaire.
  La série est séparée en trois composantes : une tendance correspondant à l’évolution globale de la température à long terme,
  une saisonnalité représentant un cycle régulier selon la période choisie par l’utilisateur,
  et un résidu, défini comme la différence entre les données observées et la somme de la tendance et de la saisonnalité."
      )
    ))
}
analyseServer <- function(id, data, variable_name = reactive("temp.corr")) {
  moduleServer(id, function(input, output, session) {
    
    output$plot_decomp <- renderPlot({
      
      # Récupérer les données filtrées et la variable sélectionnée
      req(data())
      df <- data()
      req(nrow(df) > 24)
      var_sel <- variable_name()
      
      # Agrégation horaire
      dt <- as.data.table(df)
      dt[, time_unit := floor_date(date.time, "hour")]
      
      # Moyenne sur plusieurs capteurs si plusieurs sont sélectionnés
      dt <- dt[, .(temp = mean(.SD[[var_sel]], na.rm = TRUE)), by = time_unit]
      
      # Séquence complète et remplissage NA rapide
      full_seq <- data.table(time_unit = seq(min(dt$time_unit), max(dt$time_unit), by = "hour"))
      dt <- merge(full_seq, dt, by = "time_unit", all.x = TRUE)
      dt[, temp := zoo::na.locf(temp, na.rm = FALSE)]
      dt[, temp := zoo::na.locf(temp, fromLast = TRUE)]
      
      # Création de la série temporelle
      freq <- as.numeric(input$freq_select)
      ts_obj <- ts(dt$temp, frequency = freq)
      
      # Vérification série trop courte
      if (length(ts_obj) < freq * 2) {
        validate(
          need(FALSE, "Pas assez de données pour effectuer une décomposition avec cette fréquence.")
        )
      }
      
      # Décomposition STL
      decomp <- try(stats::stl(ts_obj, s.window = "periodic"), silent = TRUE)
      if (inherits(decomp, "try-error")) {
        validate(
          need(FALSE, "Erreur STL : fréquence incompatible ou série trop courte.")
        )
      }
###################### Décomposition avec la méthode decompose ##############################
      # decomp_classic <- try(stats::decompose(ts_obj, type = "additive"),silent = TRUE)
      # if (!inherits(decomp_classic, "try-error")) {
      #   trend_classic <- as.numeric(decomp_classic$trend)
      #   seasonal_classic <- as.numeric(decomp_classic$seasonal)
      #   remainder_classic <- as.numeric(decomp_classic$random)
      # }
      # df_plot_classic <- data.table(
      #   Date = dt$time_unit,
      #   Brutes = as.numeric(ts_obj),
      #   Tendance = trend_classic,
      #   Saisonnalité = seasonal_classic,
      #   Résidus = remainder_classic
      # )
#############################################################################################      
      residus <- as.numeric(decomp$time.series[, "remainder"])
      mean_res <- mean(residus, na.rm = TRUE)
      # On formate le chiffre pour qu'il soit joli (ex: 2.4e-16)
      mean_res_str <- format(mean_res, scientific = FALSE, digits = 3)
      
      # Préparer dataframe pour ggplot
      df_plot <- data.table(
        Date = dt$time_unit,
        Brutes = as.numeric(ts_obj),
        Tendance = as.numeric(decomp$time.series[, "trend"]),
        Saisonnalité = as.numeric(decomp$time.series[, "seasonal"]),
        Résidus = as.numeric(decomp$time.series[, "remainder"])
      )
      
      df_plot <- melt(df_plot, id.vars = "Date",
                      variable.name = "Composante",
                      value.name = "Valeur")
      df_plot[, Composante := factor(Composante,
                                     levels = c("Brutes", "Tendance", "Saisonnalité", "Résidus"))]
      
      # Choix des breaks x pour ggplot
      duree_jours <- as.numeric(difftime(max(dt$time_unit), min(dt$time_unit), units = "days"))
      if (duree_jours <= 30) {
        breaks_x <- "1 day"; labels_x <- "%d %b"
      } else if (duree_jours <= 365) {
        breaks_x <- "1 month"; labels_x <- "%b"
      } else {
        breaks_x <- "2 months"; labels_x <- "%b %Y"
      }
      
      titre_cycle <- switch(as.character(freq),
                            "24" = "Cycle Journalier (24h)",
                            "168" = "Cycle Hebdomadaire (7 jours)",
                            "720" = "Cycle Mensuel (30 jours)",
                            "Autre Cycle")
      
      cols <- c("Brutes" = "#2c3e50", "Tendance" = "#d35400",
                "Saisonnalité" = "#2980b9", "Résidus" = "#7f8c8d")
      
      # Plot final
      ggplot(df_plot, aes(x = Date, y = Valeur, color = Composante)) +
        geom_line(linewidth = 0.6) + #####
      facet_grid(Composante ~ ., scales = "free_y") +
        scale_color_manual(values = cols) +
        labs(
          title = paste("Décomposition :", titre_cycle),
          subtitle = paste0(
            "Variable : ", var_sel,
            " | Moyenne des résidus = ", mean_res_str
          ),
          x = NULL, y = "Température (°C)"
        )+
        theme_bw() +
        theme(strip.text = element_text(face = "bold", size = 11),
              legend.position = "none") +
        scale_x_datetime(date_labels = labels_x, date_breaks = breaks_x)
      
    })
    
  })
}
