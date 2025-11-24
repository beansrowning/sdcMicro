library(shiny)

addResourcePath("sdcwww", file.path(
  getShinyOption(".appDir", getwd()),
  "www"
))

shinyUI(
  navbarPage(
    id = "mainnav", theme = paste0("sdcwww/", getShinyOption(".guitheme")), title = "sdcMicro GUI",
    tabPanel("About/Help", uiOutput("ui_about")),
    tabPanel("Microdata", mod_file_input_data_ui("file-import")),
    tabPanel("Explore", uiOutput("ui_modify_data")),
    tabPanel("Anonymize", uiOutput("ui_anonymize")),
    tabPanel("Risk/Utility", uiOutput("ui_results")),
    tabPanel("Export Data", uiOutput("ui_export")),
    tabPanel("Reproducibility", uiOutput("ui_script")),
    tabPanel("Undo", uiOutput("ui_undo")),
    header = tags$head(tags$script(
      src = paste0("sdcwww/", getShinyOption(".guijsfile"))
    ))
  )
)
