library(shiny)
library(dplyr)
library(haven)
library(readxl)
library(data.table)

# UI for file input page
mod_file_input_data_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(width = 12, offset = 0, h3("Uploading microdata"), class = "wb-header"),
      column(width = 12, offset = 0, p("Load the dataset to be anonymized."), class = "wb-header-hint")
    ),
    fluidRow(
      column(
        12,
        fileInput(
          ns("file_input"),
          p("Select file (allowed types are .RDS, .sav, .sas7bdat, .csv, .xlsx, and .dta)"),
          width = "75%",
          accept = c(
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "text/csv",
            ".rds",
            ".sav",
            ".sas7bdat",
            ".xls",
            ".dta"
          )
        ),
        align = "center"
      )
    )
  )
}

# Server-side logic for file input page
mod_file_input_data_server <- function(id, obj) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    observeEvent(input$file_input, {
      # Read in data
      df <- switch(tools::file_ext(input$file_input$name),
        rds = readRDS(input$file_input$datapath),
        sav = haven::read_sav(input$file_input$datapath),
        xls = ,
        xlsx = readxl::read_excel(input$file_input$datapath),
        sas7bdat = haven::read_sas(input$file_input$datapath),
        csv = data.table::fread(input$file_input$datapath, data.table = FALSE),
        dta = haven::read_dta(input$file_input$datapath),
        # ..otherwise
        {
          showModal(modalDialog(
            title = "Error",
            paste("Unsupported file type:", tools::file_ext(input$file_input$name)),
            easyClose = TRUE,
            footer = NULL
          ))
          return(NULL)
        }
      )

      # If we didn't load in a data.frame, show error
      if (!is.data.frame(df)) {
        showModal(modalDialog(
          title = "Error",
          "The loaded object is not a data.frame or tibble.",
          easyClose = TRUE,
          footer = NULL
        ))
        # Set to NULL to avoid issues
        df <- NULL
      }

      # Convert all character columns to factors
      df <- df |>
        mutate(across(where(is.character), as.factor))

      # Drop completely empty columns by default
      # and store the col names in an attribute
      empty_cols <- vapply(df, \(x) all(is.na(x)), logical(1)) |>
        which() |>
        names()

      if (!length(empty_cols)) {
        empty_cols <- NULL
      }

      df <- df |>
        select(where(~ !all(is.na(.x))))

      attr(df, "dropped") <- empty_cols

      # If we used haven, convert columns so they play nice with UI elements
      haven_cols <- vapply(df, \(x) inherits(x, "haven_labelled"), logical(1)) |>
        which() |>
        names()

      for (col in haven_cols) {
        df[[col]] <- haven::as_factor(df[[col]], levels = "default")
      }


      # Assign data and file name for UI downstream
      obj$inputdata <- df
      obj$microfilename <- input$name
    })
  })
}
