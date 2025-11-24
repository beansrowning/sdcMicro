# UI and logic for a button that returns the user to the data import page
library(shiny)
library(shinyBS)

mod_return_to_input_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
    column(12, h3("No input data available!"), class = "wb-header"),
    column(12, p("Go to the Microdata tab to upload a dataset or upload a previously saved problem from the Undo tab"), class = "wb-header-hint"),
    column(12, p("Go back to the Microdata tab by clicking the button below and load a dataset."), align = "center"),
    column(12, div(
      bsButton(
        ns("return_to_input"),
        "Load microdata",
        style = "primary"
      ),
      align = "center"))
  )
  )
}

mod_return_to_input_server <- function(id, navbar_session, navid = "mainnav") {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    observeEvent(input$return_to_input, {
      updateNavbarPage(navbar_session, navid, selected="Microdata")
    })
  })
}