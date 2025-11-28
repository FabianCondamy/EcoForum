library(shiny)
library(shinycssloaders)

ui <- fluidPage(
  
  titlePanel("Analyse des Températures par Zone"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput("variable","Choisir une variable :",
                  choices = c("Température corrigée (temp.corr)" = "temp.corr",
                              "Écart (%) (temp.ecart.prc)" = "temp.ecart.prc",
                              "Écart brut (temp.ecart.raw)" = "temp.ecart.raw"),
                  width = "100%", 
                  selectize = FALSE),

      # icon "?" on top selectInput
      tags$span(icon("question"),id = "variable_help_icon"),
      tags$div(id = "variable_help_text"),

      tags$script(HTML("
      const helpIcon = document.getElementById('variable_help_icon');
      const helpText = document.getElementById('variable_help_text');
      const variableInput = $('select#variable')[0];

      function updateHelp() {
        let selected = variableInput.value;
        let text = '';
        if(selected === 'temp.corr') {
          text = '<b>FR:</b> Température corrigée (temp.corr) - température mesurée et calibrée.<br><b>EN:</b> Corrected temperature (temp.corr) - measured and calibrated temperature.';
        } else if(selected === 'temp.ecart.raw') {
          text = '<b>FR:</b> Écart brut (temp.ecart.raw) - différence entre température corrigée et référence.<br><b>EN:</b> Raw difference (temp.ecart.raw) - difference between corrected and reference temperature.';
        } else if(selected === 'temp.ecart.prc') {
          text = '<b>FR:</b> Écart (%) (temp.ecart.prc) - pourcentage d\\'écart par rapport à la référence.<br><b>EN:</b> Percentage difference (temp.ecart.prc) - percent deviation from reference temperature.';
        }
        helpText.innerHTML = text;
      }

      variableInput.addEventListener('change', updateHelp);
      updateHelp();

      helpIcon.addEventListener('mouseenter', () => { helpText.style.display = 'block'; });
      helpIcon.addEventListener('mouseleave', () => { helpText.style.display = 'none'; });
      ")),
      checkboxGroupInput("year_select", "Année(s) :", choices = NULL),
      tags$div(
        style = "border: 1px solid #ddd; padding: 10px; border-radius: 8px; margin-top: 10px;",
        sliderInput("doy_range", "Période de l'année (DOY) :", 
                  min = 1, max = 365, value = c(1, 365), step = 1),
        div(
          style = "text-align: center;",
          textOutput("doy_text")
        )
        ),
      tags$div(
        style = "margin-top: 10px;",
        sliderInput("hour_range", "Heure(s) de la journée :", 
                    min = 0, max = 23, value = c(0, 23), step = 1)),
      tags$div(
        style = "border: 1px solid #ddd; padding: 10px; border-radius: 8px; margin-top: 10px;",
        # Bouton Croix
        tags$div(
          style = "position: relative;",
        
        actionButton(
          inputId = "clear_sensors",
          label = NULL,
          icon = icon("times"),
          style = "
      position: absolute;
      top: 5px;
      right: 5px;
      padding: 2px 6px;
      font-size: 12px;
      background-color: #f5f5f5;
      border: 1px solid #ccc;
      border-radius: 50%;
    "
        ),
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
          ))
        ),
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
          "Vidéo",
          videoUI("player1")),
        
        tabPanel(
          "Section vierge",
          NewSectionUI("new_section"))
        # À compléter avec du contenu futur dans le fichier "mod_newsection.R"
      )
    )
  ),
  tags$head(includeCSS("www/style.css"))
)