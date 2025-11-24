library(shiny)
library(shinycssloaders)

ui <- fluidPage(
  
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

      sliderInput("hour_range", "Heure(s) de la journée :", 
                  min = 0, max = 23, value = c(0, 23), step = 1),
      tags$div(
        style = "border: 1px solid #ddd; padding: 10px; border-radius: 8px; margin-top: 10px;",
        selectizeInput(
          inputId = "sensor_input",
          label = "Capteurs :",
          choices = NULL,
          multiple = TRUE,
          options = list(create = TRUE,placeholder = "ex: 2, 3, 5"),
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
      fluidRow(
        column(6,actionButton("clear_all", "Tout réinitialiser", width = "100%")),
        column(6,actionButton("update", "Mettre à jour", width = "100%")),
        style = "margin-top: 10px;"),
        
      fluidRow(
        column(12,
         div(style = "text-align:center; margin-top:20px;",
             downloadButton("download_filtered", "Exporter les données filtrées", width = "30%")
         )
        )
      )
    ),
    
    mainPanel(
      
      tabsetPanel(
        
        tabPanel(
          "Température vs DOY",
          timeseriesUI("ts1")),
        
        tabPanel(
          "Boxplots",
          statsUI("stat1")),
        
        tabPanel(
          "Carte des zones",
          mapUI("map1")),
        
        tabPanel(
          "Résumé statistique",
          summaryUI("sum1")),

        tabPanel(
          "Section vierge",
          NewSectionUI("new_section"))
        # À compléter avec du contenu futur dans le fichier "mod_newsection.R"
      )
    )
  ),
  tags$head(includeCSS("www/style.css"))
)