librarian::shelf(shiny, ggplot2, dplyr, sf, maptiles, raster, tidyterra, ggspatial, lubridate, tidyr,here,gstat,sp,automap,stars)

# Chargement des données
ref <- read.csv("ecoforum-2/data/raw-data/temp_ref.csv", h = TRUE, sep = ",") %>%
  group_by(X_date) %>%
  summarise(temp.ref = mean(outside_temp)) %>%
  mutate(date = ymd(X_date),
         YYYY = year(date),
         MM = month(date),
         DD = day(date)) %>%
  dplyr::select(-X_date)

temp <- read.csv("ecoforum-2/data/derived-data/250703_corr.csv", h = TRUE, sep = ";") %>%
  separate(coord, sep = ",", into = c("Longitude", "Latitude"))

habitat <- read.csv("ecoforum-2/data/raw-data/habitat.csv", h = TRUE, sep = ";") %>%
  rename(sensor = id) %>%
  dplyr::select(sensor, type.zone)

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

batiments <- st_read("batiments/batiments.geojson")
batiments=st_transform(batiments,3857)


filtered_data=function(Y,min_doy,max_doy,min_HH,max_HH){
  temp %>%
    filter(YYYY %in% Y,
           doy >= min_doy, doy <= max_doy,
           HH >= min_HH, HH <= max_HH)
}


#df=df %>%
#  group_by(geometry) %>%
#  summarise(temperature=median(temperature))


interpolation=function(Y,min_doy,max_doy,min_HH,max_HH,contours=FALSE){
  p=NULL
  df=filtered_data(Y,min_doy,max_doy,min_HH,max_HH)
  if(nrow(df) == 0) return(NULL)
  
  df_temp=filtered_data(Y,min_doy,max_doy,0,23)
  temp_range=c(min(df_temp$temperature),max(df_temp$temperature))
  
  df = st_transform(df, 2154)
  df=df %>% dplyr::select(temperature,geometry)
  df=df %>%
    group_by(geometry) %>%
    summarise(temperature=mean(temperature))
  
  # Grille d'interpolation
  bbox=st_bbox(df)
  grid=st_make_grid(st_as_sfc(bbox),cellsize=1,what="centers")
  grid=st_sf(geometry=grid)
  
  # Variogramme
  v=variogram(temperature~1,df)
  v_mod_ok <- fit.variogram(v, model=vgm(model="Sph"))

  g=gstat(formula=temperature~1,model=v_mod_ok,data=df)
  z=predict(g,newdata=grid)
  
  # Rasterisation
  template=st_as_stars(st_bbox(df),dx=1,dy=1)
  z_rast=st_rasterize(z["var1.pred"],template=template)
  
  # bbox interpolation
  z_df=as.data.frame(z_rast)
  z_df=z_df[!is.na(z_df$var1.pred), ]
  z_sf=st_as_sf(z_df,coords=c("x","y"),crs=st_crs(df))
  interp_bbox=st_bbox(z_sf)
  
  # Fond de carte
  tiles=get_tiles(df,crop=TRUE)
  
  #DÉCOUPE DES BÂTIMENTS À LA ZONE INTERPOLÉE
  interp_poly=st_as_sfc(interp_bbox)
  st_crs(interp_poly)=st_crs(df)
  batiments <- st_transform(batiments, st_crs(df))
  batiments_clip=st_intersection(batiments,interp_poly)
  

  # Construction du ggplot
  p=ggplot()+
    geom_spatraster_rgb(data=tiles,alpha=1) +
    geom_stars(data=z_rast,aes(fill=var1.pred),alpha=1)
  
  # Ajouter les contours si demandé
  if(contours){
    p=p+geom_contour(
      data=z_df,
      aes(x=x,y=y,z=var1.pred),
      color="black",size=0.3
    )
  }
  
  # Ajouter bâtiments
  p=p+
    geom_sf(data=batiments_clip,color="grey30",fill="grey80",size=0.3,alpha=1)+
    geom_sf(data=df,aes(fill=temperature),shape=21,color="black",
            size=5,stroke=0.5)+
    scale_fill_viridis_c(option="turbo",name="Température (°C)",limits=temp_range)+
    theme_minimal()+
    labs(
      title="Interpolation spatiale des températures (OK)",
      x="Longitude (m)",y ="Latitude (m)"
    ) +
    coord_sf(
      xlim=c(interp_bbox["xmin"],interp_bbox["xmax"]),
      ylim=c(interp_bbox["ymin"],interp_bbox["ymax"])
    )
  
  chemin="cartes_interpolees"
  nom_fichier=sprintf("%s/interpolation_%d_doy%d_HH%d-%d.png",chemin,Y,min_doy,min_HH,max_HH)
  ggsave(nom_fichier,p,width=10,height=8,dpi=300)
  
  return(p)
}



## Fonction pour créer les cartes dans un dossier cartes_interpolees ##
## chaque carte représente une interpolation de la température moyenne de chaque capteur dans un intervalle de 4h ##
## Pour que la fonction enregistre ces cartes, il faut enlever les 3 derniers commentaires de la fonction interpolation ##

for (i in 2024:2025){
  for (j in 1:366){
    for (z in 1:6)
    interpolation(i,j,j,4*(z-1),4*z-1)
  }
}


ui <- fluidPage(
  titlePanel("Analyse des Températures par Zone"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      radioButtons("year_select", "Année :", choices = sort(unique(temp$YYYY)), selected = 2024),
      
      sliderInput("week_range", "Semaine de l'année :", 
                  min = 1, max = 53,
                  value = 23, step = 1),
      
      sliderInput("hour_range", "Heure(s) de la journée :", 
                  min = 0, max = 23, value = 16, step = 1),
      
      actionButton("update", "Mettre à jour")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Température vs DOY", plotOutput("tempPlot")),
        tabPanel("Boxplots", plotOutput("boxplotTemp")),
        tabPanel("Carte des zones", imageOutput("mapPlot")),
        tabPanel("Résumé statistique", tableOutput("summaryTable"))
      )
    )
  )
)

# Serveur
server <- function(input, output, session) {

  p <- reactive({
    interpolation(input$year_select,input$doy_range,input$doy_range,input$hour_range,input$hour_range)
  })
  
  # Température vs DOY
  output$tempPlot <- renderPlot({
    p
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
  output$mapPlot <- renderImage({
    list(
      src = sprintf("%s/interpolation_%s_week%s.png",chemin,input$year_select,input$week_range),
      contentType = "image/png",
      width=750,
      height=600,
      alt = "Mon image PNG"
    )
  }, deleteFile = FALSE)

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