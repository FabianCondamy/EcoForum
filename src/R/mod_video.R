# Module UI
videoUI <- function(id) {
  ns <- NS(id)
  tagList(
    div(
      style = "max-width:600px; margin:0 auto; text-align:center;",
      shinycssloaders::withSpinner(
        imageOutput(ns("img_current"), height = "500px"),
        type = 4,
        color = "#56B4E9",
        size = 1.2
      ),
      sliderInput(
        ns("frame"), "Image :", 
        min = 1, max = 1, value = 1, step = 1,
        width = "100%"
      ),
      div(
        style = "display:flex; justify-content: space-between; font-size:14px;",
        span(textOutput(ns("date_start"))),
        span(textOutput(ns("date_end")))
      ),
      div(
        style = "margin-top:5px;",
        textOutput(ns("date_current"))
      )),
      
    tags$br(),
    tags$details(
      tags$summary("Explications (cliquer pour dérouler)"),
      tags$p("...")
    )
  )
}

# Module server
videoServer <- function(id, img_dir) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Liste des fichiers
    files <- list.files(img_dir, pattern = "\\.png$", full.names = TRUE)
    files <- sort(files)
    
    # Dates
    extract_date <- function(x) {
      m <- regexec("(\\d{4})_week(\\d+)_", basename(x))
      r <- regmatches(basename(x), m)[[1]]
      if(length(r) == 3) return(paste0("Semaine ", r[3], " - ", r[2]))
      return(NA)
    }
    dates <- sapply(files, extract_date)
    
    # Cache pour images (optionnel)
    img_cache <- list()
    get_image <- function(i) {
      if(!i %in% names(img_cache)) {
        img_cache[[as.character(i)]] <<- image_read(files[i])
      }
      return(img_cache[[as.character(i)]])
    }
    
    output$date_start <- renderText({ dates[1] })
    output$date_end   <- renderText({ dates[length(dates)] })
    
    updateSliderInput(session, "frame", min = 1, max = length(files), value = 1)
    
    current <- reactiveVal(1)
    
    observeEvent(input$frame, { current(input$frame) })
    
    output$img_current <- renderImage({
      tmpfile <- tempfile(fileext = ".png")
      image_write(get_image(current()), tmpfile)
      list(src = tmpfile, contentType = "image/png", width = "100%", height = "auto")
    }, deleteFile = TRUE)
    
    output$date_current <- renderText({ dates[current()] })
  })
}