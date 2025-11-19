library(shiny)

ui <- fluidPage(
  # CSS pour les blocs <details> 
  tags$style(HTML("
    details {
      border: 1px solid #aaa;
      padding: 10px;
      border-radius: 8px;
      margin-top: 15px;
      background-color: #f7f7f7;
      position: relative;
    }
    summary {
      font-weight: bold;
      font-size: 15px;
      cursor: pointer;
      list-style: none; /* enlève le triangle par défaut */
      position: relative;
      padding-right: 20px; /* espace pour le triangle */
    }
    summary::after {
      content: '\\25B6'; /* triangle pointant vers la droite */
      position: absolute;
      right: 0;
      top: 50%;
      transform: translateY(-50%) rotate(90deg); /* triangle vers le bas initial */
      transition: transform 0.2s ease;
      font-size: 12px;
    }
    details[open] summary::after {
      transform: translateY(-50%) rotate(-90deg); /* triangle vers le haut quand ouvert */
    }
  ")),
  
  titlePanel("Analyse des Températures par Zone"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput("variable", "Choisir une variable :", 
                  choices = c("temp.corr", "temp.ecart.prc", "temp.ecart.raw")),
      checkboxGroupInput("year_select", "Année(s) :", choices = NULL),
      sliderInput("doy_range", "Période de l'année (DOY) :", 
                  min = 1, max = 365, value = c(1, 365), step = 1),
      sliderInput("hour_range", "Heure(s) de la journée :", 
                  min = 0, max = 23, value = c(0, 23), step = 1),
      checkboxGroupInput("sensor_select", "Capteurs :", choices = NULL),
      actionButton("update", "Mettre à jour")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel(
          "Température vs DOY",
          timeseriesUI("ts1"),
          tags$br(),
          tags$details(
            tags$summary("Explications (cliquer pour dérouler)"),
            tags$p("Ce graphique montre l’évolution de la variable choisie en fonction du temps. 
                   Les différentes couleurs correspondent aux années sélectionnées. 
                   Vous pouvez filtrer les capteurs, les dates et les heures via le menu à gauche.")
          )
        ),
        
        tabPanel(
          "Boxplots",
          statsUI("stat1"),
          tags$br(),
          tags$details(
            tags$summary("Explications (cliquer pour dérouler)"),
            tags$p("Ces boxplots montrent la distribution de la variable choisie pour chaque année et chaque capteur.")
          )
        ),
        
        tabPanel(
          "Carte des zones",
          mapUI("map1"),
          tags$br(),
          tags$details(
            tags$summary("Explications (cliquer pour dérouler)"),
            tags$p("La carte montre la position des capteurs et leur valeur selon une échelle de couleurs. 
                   Les bâtiments et zones neutres ne sont pas colorés.")
          )
        ),
        
        tabPanel(
          "Résumé statistique",
          summaryUI("sum1"),
          tags$br(),
          tags$details(
            tags$summary("Explications (cliquer pour dérouler)"),
            tags$p("Ce tableau résume les statistiques principales : moyenne, écart-type, min, max et nombre de mesures par capteur.")
          )
        )
      )
    )
  )
)
