library(shiny)
library(grid)
library(sdcMicro)
library(rhandsontable)
library(haven)
library(shinyBS)
library(data.table)

source("fn.R")
source("modules/microdata_import.R")
source("modules/bt_to_input.R")
.startdir <- .guitheme <- .guijsfile <- NULL
maxRequestSize <- 50
options(
  shiny.maxRequestSize = ceiling(maxRequestSize) * 1024^2,
  stringsAsFactors = TRUE
)

shinyOptions(.startdir = getwd())

theme <- "IHSN"
shinyOptions(.guitheme = "ihsn-root.css")
shinyOptions(.guijsfile = "js/ihsn-style.js")

# required that 'dQuote()' works nicely when
# outputting R-Code
options(useFancyQuotes = FALSE)

# maximum upload size = 1GB (defined in sdcApp())
# options(shiny.maxRequestSize=1000*1024^2)


# global, reactive data-structure
data(testdata, envir = .GlobalEnv)
data(testdata2, envir = .GlobalEnv)
testdata$urbrur <- factor(testdata$urbrur)
testdata$urbrur[sample(1:nrow(testdata), 10)] <- NA
testdata$roof <- factor(testdata$roof)
testdata$walls <- factor(testdata$walls)
testdata$sex <- factor(testdata$sex)

# Ignore dfs in the global environment to avoid cross-contamination
# between sessions
available_dfs <- NULL

get_keyVars <- reactive({
  if (is.null(obj$sdcObj)) {
    return(NULL)
  }
  return(obj$sdcObj@keyVars)
})

# get key variables by names
get_keyVars_names <- reactive({
  if (is.null(obj$sdcObj)) {
    return(NULL)
  }
  return(colnames(get_origData())[get_keyVars()])
})

get_weightVar <- reactive({
  if (is.null(obj$sdcObj)) {
    return(NULL)
  }
  return(obj$sdcObj@weightVar)
})
get_numVars <- reactive({
  if (is.null(obj$sdcObj)) {
    return(NULL)
  }
  return(obj$sdcObj@numVars)
})
get_origData <- reactive({
  if (is.null(obj$sdcObj)) {
    return(NULL)
  }
  return(obj$sdcObj@origData)
})
get_risk <- reactive({
  if (is.null(obj$sdcObj)) {
    return(NULL)
  }
  return(as.data.frame(obj$sdcObj@risk$individual))
})

href_to_setup <- genDynLinkObserver(prefix = "btn_a_setup_", verbose = FALSE, inputId = "mainnav", selected = "Anonymize")
href_to_microdata <- genDynLinkObserver(prefix = "btn_a_micro_", verbose = FALSE, inputId = "mainnav", selected = "Microdata")

permPfad <- reactiveValues()
obj <- reactiveValues() # we work with this data!

testdata$urbrur <- as.numeric(testdata$urbrur)

obj$inputdata <- NULL
obj$sdcObj <- NULL
obj$code_read_and_modify <- c()
obj$code_setup <- c()
obj$code_anonymize <- c()
obj$code <- c(
  paste("# created using sdcMicro", packageVersion("sdcMicro")),
  "library(sdcMicro)", "",
  "obj <- NULL"
)
obj$transmat <- NULL
obj$last_warning <- NULL
obj$last_error <- NULL
obj$comptime <- 0
obj$microfilename <- NULL # name of uploaded file
obj$lastaction <- NULL
obj$anon_performed <- NULL # what has been applied?
obj$rbs <- obj$sls <- NULL
obj$setupval_inc <- 0
obj$inp_sel_viewvar1 <- NULL
obj$inp_sel_anonvar1 <- NULL
obj$lastreport <- NULL # required to show the last saved report
obj$lastdataexport <- NULL # required to show the last saved exported data
obj$lastproblemexport <- NULL # required to show the last exported sdcproblem
obj$lastproblemexport1 <- NULL # required to show the last exported sdcproblem (undo-page)
obj$lastscriptexport <- NULL # required to show the last saved script
obj$ldiv_result <- NULL # required for l-diversity risk-measure
obj$suda2_result <- NULL # required for suda2 risk-measure
obj$hhdata <- NULL # household-file data required for merging
obj$hhdata_applied <- FALSE # TRUE, if mergeHouseholdData() has been applied
obj$hhdata_selected <- FALSE # TRUE, if selectHouseholdData() has been applied

# stores the current selection of the relevant navigation menus
obj$cur_selection_results <- "btn_results_1" # navigation for Results/Risks
obj$cur_selection_exports <- "btn_export_results_1" # navigation for export
obj$cur_selection_script <- "btn_export_script_1" # navigation for reproducibility/script
obj$cur_selection_microdata <- "btn_menu_microdata_1" # navigation for microdata
obj$cur_selection_import <- "btn_import_data_1" # navigation for import
obj$cur_selection_anon <- "btn_sel_anon_1" # navigation for anonymization

# for stata-labelling
obj$stata_labs <- NULL
obj$stata_varnames <- NULL

# the path, where all output will be saved to
obj$path_export <- normalizePath(tempdir())

# is available in exported problem instances
# helpful for debugging
obj$sessioninfo <- sessionInfo()
