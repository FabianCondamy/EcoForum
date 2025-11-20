library(shiny)
library(shinycssloaders)

ui <- fluidPage(
  # CSS pour les blocs <details> 
  tags$style(HTML("
  /* ---- Onglets modernisés ---- */
  .nav-tabs > li > a {
    border-radius: 10px 10px 0 0 !important;
    background-color: #e8e8e8 !important;
    color: #333 !important;
    margin-right: 4px !important;
    padding: 10px 15px !important;
    font-weight: 500;
  }
  
  .nav-tabs > li.active > a,
  .nav-tabs > li.active > a:focus,
  .nav-tabs > li.active > a:hover {
    background-color: #56B4E9 !important;   /* bleu Okabe-Ito */
    color: white !important;
    border-radius: 10px 10px 0 0 !important;
    border: none !important;
  }

  .tab-content {
    border: 1px solid #ccc;
    border-radius: 0 10px 10px 10px !important;
    padding: 15px;
    box-shadow: 0 2px 5px rgba(0,0,0,0.1);
    background-color: white;
  }

  /* ---- Sidebar et panels arrondis ---- */
  .well, .panel, .panel-body, .form-group, .input-group {
    border-radius: 12px !important;
    background: #f9f9f9 !important;
    padding: 12px !important;
    box-shadow: 0 2px 4px rgba(0,0,0,0.08);
    border: 1px solid #ddd !important;
  }

  /* ---- Blocs <details> modernisés ---- */
  details {
    border: 1px solid #aaa;
    padding: 12px;
    border-radius: 12px;
    margin-top: 15px;
    background-color: #fafafa;
    position: relative;
    box-shadow: 0 2px 4px rgba(0,0,0,0.07);
  }

  summary {
    font-weight: 600;
    font-size: 15px;
    cursor: pointer;
    list-style: none;
    padding-right: 20px;
  }

  /* Triangle animé */
  summary::after {
    content: '\\25B6'; /* triangle */
    position: absolute;
    right: 0;
    top: 50%;
    transform: translateY(-50%) rotate(90deg);
    transition: transform 0.2s;
    font-size: 12px;
  }

  details[open] summary::after {
    transform: translateY(-50%) rotate(-90deg);
  }
")),
  titlePanel("Analyse des Températures par Zone"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput("variable", "Choisir une variable :",
                  choices = c(
                    "Température corrigée (temp.corr)" = "temp.corr",
                    "Écart (%) (temp.ecart.prc)" = "temp.ecart.prc",
                    "Écart brut (temp.ecart.raw)" = "temp.ecart.raw"
                  )
                  ),
      checkboxGroupInput("year_select", "Année(s) :", choices = NULL),
      textInput(
        inputId = "doy_input",
        label = "Période de l'année (DOY):",
        placeholder = "ex: 1-365"
      ),
#      sliderInput("doy_range", "Période de l'année (DOY) :", 
#                  min = 1, max = 365, value = c(1, 365), step = 1),

#tags$div(
#  style = "border: 1px solid #ddd; padding: 8px; border-radius: 8px; display: flex; align-items: center; gap: 10px; width: 100%;",
#  tags$span("Heure :", style = "font-weight: 600; width: 70px;"),
#  tags$span("de", style = "font-weight: 600; width: 20px; text-align: center;"),
#  textInput("hour_start", NULL, value = "0", width = "35%"),
#  tags$span("à", style = "font-weight: 600; width: 20px; text-align: center;"),
#  textInput("hour_end", NULL, value = "23", width = "35%")
#),

      sliderInput("hour_range", "Heure(s) de la journée :", 
                  min = 0, max = 23, value = c(0, 23), step = 1),
      tags$div(
        style = "border: 1px solid #ddd; padding: 10px; border-radius: 8px; margin-top: 10px;",
        textInput(
          inputId = "sensor_input",
          label = "Capteurs (séparer par des virgules) :",
          placeholder = "ex: 2,3,5",
          width = "100%"
          ),
        actionButton(
          inputId = "select_all_sensors",
          label = "Sélectionner tout",
          width = "100%",
          style = "margin-top: 1px;"
          )
        ),
#      checkboxGroupInput("sensor_select", "Capteurs :", choices = NULL),
#      actionButton("update", "Mettre à jour", style = "margin-top: 10px;")
      fluidRow(
        column(6,actionButton("clear_all", "Tout réinitialiser", width = "100%")),
        column(6,actionButton("update", "Mettre à jour", width = "100%")),
        style = "margin-top: 10px;")
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