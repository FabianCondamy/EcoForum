# Module UI
mapUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    
    div(
      style = "max-width:700px; margin:0 auto; text-align:center;",
      tags$h4("Cartes générées à partir de tous les capteurs",style = "margin-bottom:20px; font-weight:600;"),
      div(
        style = "display:flex; gap:15px; align-items:flex-start; justify-content:center;",
        shinycssloaders::
          withSpinner(imageOutput(ns("img_current"), height = "500"),type = 4, color = "#56B4E9", size = 1.2),
        div(
          style = "
          width:200px;
          font-size:13px;
          background:#f9f9f9;
          padding:10px;
          border-radius:6px;
          text-align:left;
          margin-top:160px;
          ",
          
          tags$strong("Couleurs & températures"),
          tags$p(
            style = "margin-top:8px;",
            "Les tons bleus représentent les zones les plus fraîches, tandis que les tons rouges indiquent les températures plus élevées.")
          )
        )
      ),
    
    # Slider
    div(
      style = "margin-top:-30px; margin-bottom:-10px; text-align:center;",
      sliderInput(ns("frame"), "Image :",
                  min = 1, max = 1, value = 1, step = 1, 
                  width = "100%")
      ),
    
    
    # Date range
    div(
      style = "display:flex; justify-content: space-between; font-size:14px; margin-bottom: 5px",
      span(textOutput(ns("date_start"))),
      span(textOutput(ns("date_end")))
      ),
    
    # Interactive date block
    wellPanel(
      fluidRow(
        column(2, numericInput(ns("day"), "Jour", value = 1, min = 1, max = 31)),
        column(4, selectInput(ns("month"), "Mois", choices = month.name)),
        column(3, selectInput(ns("year"), "Année", choices = c(2024, 2025))),
        
        # This is the version with an active selection button has a problem: it lags when launched from an app rather than a browser.
        # column(3, selectInput(ns("hour"), "Heure", choices = c("0-3","4-7","8-11","12-15","16-19","20-23")))
        
        column(3,div(style = "position: relative;",
                     
                     # Disabled selectInput
                     tags$div(style = "pointer-events:none;opacity:0.7;",
                              selectInput(ns("hour"),"Heure",choices = c("0-3","4-7","8-11","12-15","16-19","20-23"))
                              ),
                     
                     # Help icon
                     tags$span(icon("question"),id = ns("hour_help_icon"),
                               style = "
                               position:absolute;
                               top:6px;
                               right:10px;
                               cursor: help;
                               color:#666;
                               pointer-events:auto;
                               "),
                     
                     # Tooltip (content-relative, above the field)
                     tags$div(id = ns("hour_help_text"),
                              style = "
                              display:none;
                              position:absolute;
                              bottom:110%;
                              right:0;
                              width:320px;
                              background:white;
                              border:1px solid #ccc;
                              border-radius:6px;
                              padding:12px;
                              font-size:12px;
                              box-shadow:0 4px 10px rgba(0,0,0,0.15);
                              z-index:1000;")
                     )
               )
        )
      ),
    
    # Tooltip JS logic
    tags$script(HTML(sprintf("
      const hourIcon = document.getElementById('%s');
      const hourText = document.getElementById('%s');

      hourText.innerHTML = `
        <b>FR :</b><br>
        La sélection manuelle du créneau horaire n’est actuellement pas disponible.
        Vous pouvez toutefois utiliser les flèches gauche et droite de votre clavier
        afin de naviguer entre les images successives dans la chronologie.
        <br><br>
        <b>EN :</b><br>
        Manual selection of the time interval is currently unavailable.
        However, you may use the left and right arrow keys on your keyboard
        to navigate to the previous or next image in the temporal sequence.
      `;

      hourIcon.addEventListener('mouseenter', () => {
        hourText.style.display = 'block';
      });

      hourIcon.addEventListener('mouseleave', () => {
        hourText.style.display = 'none';
      });
    ", ns("hour_help_icon"), ns("hour_help_text")))),
    
    
    # Explanation block
    tags$details(
      tags$summary("Explications (cliquer pour dérouler)"),
      tags$p(
        "Dans cet onglet, vous pouvez explorer l’évolution des températures moyennes
        sur le campus de la faculté des sciences. Les cartes présentées sont obtenues
        à partir d’une interpolation spatiale, appelée krigeage ordinaire, permettant
        d’estimer la température dans les zones non instrumentées.")
    )
  )
  }

# Module server
mapServer <- function(id) {
  img_dir <- file.path("..", "data", "images")
  
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    files <- list.files(img_dir, pattern = "\\.png$", full.names = TRUE)
    
    # Parse filename into structured date-time components   
    parse_file <- function(x) {
      fname <- basename(x)
      m <- regexec(".*_(\\d{4})_doy(\\d+)_HH([0-9]+-[0-9]+)", fname)
      r <- regmatches(fname, m)[[1]]
      if(length(r) == 4){
        year <- as.numeric(r[2])
        doy  <- as.numeric(r[3])
        hour <- r[4]
        date_real <- as.Date(doy-1, origin=paste0(year,"-01-01"))
        list(
          year = year,
          day  = as.integer(format(date_real,"%d")),
          month= format(date_real,"%B"),
          hour = hour,
          doy = doy
        )
      } else NULL
    }
    
    dates_list <- lapply(files, parse_file)
    
    # Sort files and dates by year, DOY and hour sequence
    hour_order <- c("0-3","4-7","8-11","12-15","16-19","20-23")
    order_idx <- order(
      sapply(dates_list, function(d) d$year),
      sapply(dates_list, function(d) d$doy),
      sapply(dates_list, function(d) match(d$hour, hour_order))
    )
    files <- files[order_idx]
    dates_list <- dates_list[order_idx]
    
    img_cache <- list()
    
    # Retrieve image, load once into cache
    get_image <- function(i){
      key <- as.character(i)
      if(!key %in% names(img_cache)){
        img_cache[[key]] <<- image_read(files[i])
      }
      img_cache[[key]]
    }
    
    # first frame
    first_idx <- 1
    current <- reactiveVal(first_idx)
    
    output$date_start <- renderText({
      d <- dates_list[[first_idx]]
      paste(d$day,d$month,d$year)
    })
    
    output$date_end <- renderText({
      last <- dates_list[[length(dates_list)]]
      paste(last$day,last$month,last$year)
    })
    
    first_date <- dates_list[[first_idx]]
    updateSliderInput(session,"frame",min=1,max=length(files),value=first_idx)
    updateNumericInput(session,"day",value=first_date$day)
    updateSelectInput(session,"month",selected=first_date$month)
    updateSelectInput(session,"year",selected=first_date$year)
    updateSelectInput(session,"hour",selected=first_date$hour)
    
    # Slider -> date fields
    observeEvent(input$frame, {
      isolate({
        d <- dates_list[[input$frame]]
        current(input$frame)
        updateSelectInput(session,"year",selected=d$year)
        updateNumericInput(session,"day",value=d$day)
        updateSelectInput(session,"month",selected=d$month)
        updateSelectInput(session,"hour",selected=d$hour)
      })
    })
    
    # Date fields -> slider
    observe({
      year_match  <- input$year
      day_match   <- input$day
      month_match <- input$month
      hour_match  <- input$hour
      idx <- which(sapply(dates_list,function(d){
        !is.null(d) && d$year==year_match && d$day==day_match &&
          d$month==month_match && d$hour==hour_match
      }))
      if(length(idx)==1 && idx != isolate(current())){
        current(idx)
        updateSliderInput(session,"frame",value=idx)
      }
    })
    
    # Render current image
    output$img_current <- renderImage({
      tmpfile <- tempfile(fileext = ".png")
      image_write(get_image(current()), tmpfile)
      list(
        src = tmpfile,
        contentType = "image/png",
        width = "100%",
        height = "auto"
      )
    }, deleteFile=TRUE)
  })
}
