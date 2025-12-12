# Module UI
mapUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    div(
      style = "max-width:750px; margin:0 auto; text-align:center;",
      
      tags$h4(
        "Cartes générées à partir de tous les capteurs",
        style = "margin-bottom:20px; font-weight:600;"
      ),
      
      div(
        style = "display:flex; gap:15px; align-items:flex-start; justify-content:center;",
        
        shinycssloaders::withSpinner(
          imageOutput(ns("img_current"), height = "500px"),
          type = 4, color = "#56B4E9", size = 1.2
        ),
        
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
            "Les tons bleus représentent les zones les plus fraîches, tandis que les tons rouges indiquent les températures plus élevées."
          )
        )
      ),
      
      tags$br(),
      
      sliderInput(
        ns("frame"), "Image :",
        min = 1, max = 1, value = 1, step = 1, width = "100%"
      ),
      
      div(
        style = "display:flex; justify-content: space-between; font-size:14px;",
        span(textOutput(ns("date_start"))),
        span(textOutput(ns("date_end")))
      ),
      
      div(style = "margin-top:5px;", textOutput(ns("date_current")))
    ),
    
    tags$br(),
    
    tags$details(
      tags$summary("Explications (cliquer pour dérouler)"),
      tags$p(
        "Dans cet onglet, vous pouvez explorer l’évolution des températures moyennes sur le campus de la faculté des sciences. ",
        "Les cartes présentées sont obtenues à partir d’une interpolation spatiale, réalisée à l’aide de la méthode du krigeage ordinaire, ",
        "qui permet d’estimer la température entre les points de mesure."
      ),
      tags$p(
        "Ces cartes illustrent la répartition spatiale de la température pour des intervalles de 4 heures tout au long de la journée. ",
        "À l’aide du curseur, vous pouvez faire défiler les cartes dans l’ordre chronologique. ",
        "Pour chaque carte affichée, la date et la plage horaire correspondantes s’affichent automatiquement. ",
        "L’échelle de température est ajustée chaque jour afin de faciliter la lecture et la comparaison des cartes."
      )
    )
  )
}


# Module server
mapServer <- function(id) {
  
  img_dir <- file.path("..", "data", "images")
  
  moduleServer(id, function(input, output, session) {
    
    ns <- session$ns
    
    # Lister les images
    files <- list.files(img_dir, pattern = "\\.png$", full.names = TRUE)

    # sort image names 
    extract_date_raw <- function(x) {
      fname <- basename(x)
      
      m <- regexec(".*_(\\d{4})_doy(\\d+)_HH", fname)
      r <- regmatches(fname, m)[[1]]
      
      if (length(r) >= 3) {
        year <- as.numeric(r[2])
        doy  <- as.numeric(r[3])
        return(as.Date(doy - 1, origin = paste0(year, "-01-01")))
      }
      
      return(as.Date(NA))
    }
    
    dates_raw <- sapply(files, extract_date_raw)
    ord <- order(dates_raw)
    files <- files[ord]
    dates_raw <- dates_raw[ord]
    
    # Extraction date + conversion DOY
    extract_date <- function(x) {
      fname <- basename(x)
      
      m <- regexec(".*_(\\d{4})_doy(\\d+)_HH([0-9]+-[0-9]+)", fname)
      r <- regmatches(fname, m)[[1]]
      
      if (length(r) == 4) {
        year <- as.numeric(r[2])
        doy  <- as.numeric(r[3])
        hh   <- r[4]
        
        # Conversion DOY -> date réelle
        date_real <- as.Date(doy - 1, origin = paste0(year, "-01-01"))
        
        # Heures formatées
        hh_fmt <- gsub("-", "–", hh)   # tiret long
        
        # Format ex : "Jeudi 9 janvier 2025 — 00h–03h"
        txt <- paste0(
          format(date_real, "%A %d %B %Y"),
          " — ",
          gsub("([0-9]+)", "\\1h", hh_fmt)
        )
        
        # Mettre la 1ère lettre capitale
        txt <- paste0(toupper(substr(txt,1,1)), substr(txt,2,nchar(txt)))
        
        return(txt)
      }
      
      return(NA)
    }
    
    # Toutes les dates converties
    dates <- sapply(files, extract_date)
    
    
    # Cache images magick
    img_cache <- list()
    
    get_image <- function(i) {
      key <- as.character(i)
      if (!key %in% names(img_cache)) {
        img_cache[[key]] <<- image_read(files[i])
      }
      img_cache[[key]]
    }
    
    
    # Initialisation affichage
    output$date_start <- renderText({ dates[1] })
    output$date_end   <- renderText({ dates[length(dates)] })
    
    updateSliderInput(session, "frame",
                      min = 1, max = length(files), value = 1)
    
    
    # Frame courante 
    current <- reactiveVal(1)
    
    observeEvent(input$frame, {
      current(input$frame)
    })
    
    
    # Image affichée 
    output$img_current <- renderImage({
      
      tmpfile <- tempfile(fileext = ".png")
      image_write(get_image(current()), tmpfile)
      
      list(
        src = tmpfile,
        contentType = "image/png",
        width = "100%",
        height = "auto"
      )
      
    }, deleteFile = TRUE)
    
    
    # Date courante 
    output$date_current <- renderText({
      dates[current()]
    })
    
  })
}
