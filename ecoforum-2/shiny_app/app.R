librarian::shelf(shiny, ggplot2, dplyr, sf, maptiles, raster, tidyterra, ggspatial, lubridate, tidyr)

# Chargement des données
ref <- read.csv("../data/raw-data/temp_ref.csv", h = TRUE, sep = ",") %>%
  group_by(X_date) %>%
  summarise(temp.ref = mean(outside_temp)) %>%
  mutate(date = ymd(X_date),
         YYYY = year(date),
         MM = month(date),
         DD = day(date)) %>%
  select(-X_date)

temp <- read.csv("../data/derived-data/250703_corr.csv", h = TRUE, sep = ";") %>%
  separate(coord, sep = ",", into = c("Longitude", "Latitude"))

habitat <- read.csv("../data/raw-data/habitat.csv", h = TRUE, sep = ";") %>%
  rename(sensor = id) %>%
  select(sensor, type.zone)

# Transformation spatiale et enrichissement
temp <- st_as_sf(temp, coords = c("Latitude", "Longitude"), crs = 4326) %>%
  st_transform("EPSG:2154") %>%
  mutate(date.time = ymd_hms(date.time),
         YYYY = year(date.time),
         MM = month(date.time),
         DD = day(date.time),
         HH = hour(date.time),
         Min = minute(date.time),
         SS = second(date.time),
         doy = yday(make_date(YYYY, MM, DD))) %>%
  left_join(habitat, by = "sensor") %>%
  left_join(ref, by = c("YYYY", "MM", "DD")) %>%
  mutate(temp.ecart.raw = temp.corr - temp.ref,
         temp.ecart.prc = (temp.corr - temp.ref) / temp.ref)

temp$month_name <- factor(month.name[temp$MM], levels = month.name)

# Interface utilisateur
ui <- fluidPage(
  titlePanel("Analyse des Températures par Zone"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput("variable", "Choisir une variable :", 
                  choices = c("temp.corr", "temp.ecart.prc", "temp.ecart.raw")),
      
      checkboxGroupInput("year_select", "Année(s) :", 
                         choices = sort(unique(temp$YYYY)), selected = unique(temp$YYYY)),
      
      sliderInput("doy_range", "Période de l'année (DOY) :", 
                  min = min(temp$doy), max = max(temp$doy),
                  value = c(min(temp$doy), max(temp$doy)), step = 1),
      
      sliderInput("hour_range", "Heure(s) de la journée :", 
                  min = 0, max = 23, value = c(0, 23), step = 1),
      
      checkboxGroupInput("sensor_select", "Sélectionner les capteurs :", 
                         choices = sort(unique(temp$sensor)), selected = unique(temp$sensor)),
      
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

# Serveur
server <- function(input, output, session) {
  
  filtered_data <- reactive({
    req(input$sensor_select, input$year_select)
    
    temp %>%
      filter(sensor %in% input$sensor_select,
             YYYY %in% input$year_select,
             doy >= input$doy_range[1], doy <= input$doy_range[2],
             HH >= input$hour_range[1], HH <= input$hour_range[2])
  })
  
  # Température vs DOY
  output$tempPlot <- renderPlot({
    df <- filtered_data()
    
    ggplot(df, aes(x = date.time, y = .data[[input$variable]],
                   color = as.factor(YYYY),
                   group = interaction(sensor, YYYY))) +
      geom_line(alpha = 0.5, linewidth = 0.6) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
      labs(title = paste(input$variable, "en continu (horodaté)"),
           x = "Date et heure", y = input$variable,
           color = "Année") +
      theme_minimal() +
      facet_wrap(~ sensor, scales = "fixed")
  })
  
  # Boxplots sensor × year
  output$boxplotTemp <- renderPlot({
    ggplot(filtered_data(), aes(x = as.factor(YYYY), y = .data[[input$variable]],
                                fill = as.factor(YYYY))) +
      geom_boxplot(alpha = 0.7) +
      labs(title = paste("Boxplot de", input$variable),
           x = "Année", y = input$variable) +
      facet_wrap(~ sensor) +
      theme_minimal()
  })
  
  # Carte
  output$mapPlot <- renderPlot({
    selected_data <- filtered_data()
    if (nrow(selected_data) == 0) return(NULL)
    
    tiles <- get_tiles(selected_data, crop = TRUE)
    
    ggplot() +
      geom_spatraster_rgb(data = tiles) +
      geom_sf(data = selected_data, aes(color = .data[[input$variable]], size = .data[[input$variable]])) +
      theme_minimal() +
      labs(title = "Localisation des Capteurs", color = input$variable) +
      coord_sf()
  })
  
  # Résumé statistique : sensor × year
  output$summaryTable <- renderTable({
    df <- filtered_data()
    var <- input$variable
    
    df %>%
      st_drop_geometry() %>%
      group_by(sensor, YYYY) %>%
      summarise(
        Moyenne = mean(.data[[var]], na.rm = TRUE),
        Écart_type = sd(.data[[var]], na.rm = TRUE),
        Min = min(.data[[var]], na.rm = TRUE),
        Max = max(.data[[var]], na.rm = TRUE),
        N = n(),
        .groups = "drop"
      ) %>%
      arrange(sensor, YYYY)
  }, digits = 2)
}

# Lancer l'application
shinyApp(ui = ui, server = server)
