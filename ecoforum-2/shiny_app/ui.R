library(shiny)

ui <- fluidPage(
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
        tabPanel("Température vs DOY", plotOutput("tempPlot")),
        tabPanel("Boxplots", plotOutput("boxplotTemp")),
        tabPanel("Carte des zones", plotOutput("mapPlot")),
        tabPanel("Résumé statistique", tableOutput("summaryTable"))
      )
    )
  )
)
