#' Run the Alien Invertebrates of Romania Shiny App
#'
#' @description Launches the interactive dashboard for exploring alien invertebrate
#' species data in Romania.
#'
#' @param ... Additional arguments passed to \code{\link[shiny]{runApp}}
#'
#' @return No return value, launches the Shiny application
#' @export
#'
#' @examples
#' \dontrun{
#' run_alieninvro_app()
#' }
run_alieninvro_app <- function(...) {
  app_dir <- system.file("shiny", package = "alieninvro")
  if (app_dir == "") {
    stop("Could not find Shiny app directory. Try re-installing `alieninvro`.", call. = FALSE)
  }
  
  shiny::runApp(app_dir, ...)
}