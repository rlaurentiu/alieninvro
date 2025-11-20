# Load required libraries
library(shiny)
library(leaflet)
library(DT)
library(dplyr)
library(shinydashboard)
library(plotly)
library(circlize)
library(viridis)
library(ggplot2)
library(ggvenn)
library(ggpubr)
library(openxlsx)
library(shinyWidgets)

# Function to get package versions
get_package_versions <- function() {
  packages <- c("shiny", "leaflet", "DT", "dplyr", "shinydashboard",
                "plotly", "circlize", "viridis", "ggplot2", "ggvenn",
                "ggpubr", "openxlsx", "shinyWidgets")
  versions <- sapply(packages, function(pkg) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      as.character(packageVersion(pkg))
    } else {
      "Not installed"
    }
  })
  return(versions)
}

# Store package versions
package_versions <- get_package_versions()

# Load RDA files (must be created first using create_rda_files.R)
data("species_data", package = "alieninvro", envir = environment())
data("species_chord", package = "alieninvro", envir = environment())
data("species_list", package = "alieninvro", envir = environment())


# Prepare data with realm-specific popup
species_data <- species_data %>%
  filter(!is.na(decimalLatitude) & !is.na(decimalLongitude)) %>%
  mutate(
    popup_text = paste0(
      "<b>Species:</b> ", ScientificName, "<br>",
      "<b>Family:</b> ", Family, "<br>",
      "<b>Order:</b> ", Order, "<br>",
      "<b>Realm:</b> <span style='color:",
      ifelse(realm == "terrestrial", "#e74c3c",
             ifelse(realm == "freshwater", "#3498db",
                    ifelse(realm == "marine", "#2c3e50", "#95a5a6"))),
      ";'><b>", realm, "</b></span><br>",
      "<b>Location:</b> ", Locality, " <br>",
      "<b>County Code:</b> ", CountyCode, "<br>",
      "<b>Year of observation:</b> ", year, "<br>",
      "<b>Recorded by & Source:</b> ", recordedBy,", ", basisOfRecord, "<br>",
      "<b>EU Status:</b> ",
      ifelse(is.na(ias_eu), "Not specified",
             ifelse(ias_eu == "Yes",
                    "<span style='color:#e74c3c;'><b>Species of EU Concern</b></span>",
                    "Not of concern"))
    )
  )

# Prepare pathways data using available columns
prepare_chord_data <- function(data, realm_filter = NULL) {
  if (!is.null(realm_filter)) {
    data <- data %>% filter(realm == realm_filter)
  }

  # Detect which columns to use (after dot-to-underscore conversion)
  pathway_col <- if("pathway_1" %in% names(data)) {
    "pathway_1"
  } else if("pathway1" %in% names(data)) {
    "pathway1"
  } else {
    "pathway_1"
  }

  native_col <- if("native_in_1" %in% names(data)) {
    "native_in_1"
  } else if("nativein1" %in% names(data)) {
    "nativein1"
  } else {
    "native_in_1"
  }

  # Remove duplicates and create crosstab using detected columns
  data_unique <- data %>%
    filter(!is.na(.data[[pathway_col]]) & !is.na(.data[[native_col]])) %>%
    distinct(ScientificName, .data[[pathway_col]], .data[[native_col]], .keep_all = TRUE)

  # Create crosstab table using detected columns
  if (nrow(data_unique) > 0) {
    ct <- table(data_unique[[native_col]], data_unique[[pathway_col]])
    return(as.matrix(ct))
  } else {
    return(NULL)
  }
}

# Unique values for filters
unique_realms <- sort(unique(species_data$realm[!is.na(species_data$realm)]))
unique_species <- sort(unique(species_data$ScientificName[!is.na(species_data$ScientificName)]))
unique_families <- sort(unique(species_data$Family[!is.na(species_data$Family)]))
unique_counties <- sort(unique(species_data$CountyCode[!is.na(species_data$CountyCode)]))

# Calculate unique species counts by realm
unique_terrestrial_species <- species_data %>%
  filter(realm == "terrestrial") %>%
  distinct(ScientificName) %>%
  nrow()

unique_freshwater_species <- species_data %>%
  filter(realm == "freshwater") %>%
  distinct(ScientificName) %>%
  nrow()

unique_marine_species <- species_data %>%
  filter(realm == "marine") %>%
  distinct(ScientificName) %>%
  nrow()

unique_eu_concern_species <- species_data %>%
  filter(ias_eu == "Yes") %>%
  distinct(ScientificName) %>%
  nrow()

# UI
ui <- dashboardPage(
  title = "Alien Invertebrates of Romania",  # Set browser title

  dashboardHeader(
    title = tags$span(
      tags$i(class = "fa fa-bug", style = "margin-right: 10px;"),
      "Alien Invertebrates of Romania",
      style = "font-size: 18px; font-weight: 500;"
    ),
    titleWidth = 350
  ),

  dashboardSidebar(
    width = 280,
    tags$head(
      tags$style(HTML("
        /* United Theme - Clean and Professional CSS */
        .skin-blue .main-header .logo {
          background-color: #ff8c42;  /* Lighter orange */
          font-weight: 500;
        }
        .skin-blue .main-header .navbar {
          background-color: #ff8c42;  /* Lighter orange */
        }
        .skin-blue .main-header .navbar .sidebar-toggle:hover {
          background-color: #ff7a2e;  /* Slightly darker on hover */
        }
        .skin-blue .main-sidebar {
          background-color: #5c4033;  /* Warm medium brown to complement lighter orange */
          box-shadow: 2px 0 5px rgba(0, 0, 0, 0.1);
        }
        .skin-blue .sidebar-menu > li.active > a {
          background-color: #ff8c42;  /* Lighter orange for active */
          border-left-color: #ffd700;  /* Golden accent */
        }
        .skin-blue .sidebar-menu > li > a:hover {
          background-color: #74564a;  /* Lighter brown on hover */
          border-left-color: #ff8c42;  /* Lighter orange */
        }
        .skin-blue .sidebar-menu > li > a {
          color: #f5f5f5;  /* Light text for contrast */
        }
        .skin-blue .sidebar-menu > li > a > .fa,
        .skin-blue .sidebar-menu > li > a > .fas,
        .skin-blue .sidebar-menu > li > a > .far {
          color: #ffb366;  /* Lighter orange icons */
        }
        .skin-blue .sidebar-menu > li.active > a > .fa,
        .skin-blue .sidebar-menu > li.active > a > .fas,
        .skin-blue .sidebar-menu > li.active > a > .far {
          color: #fff;  /* White icons when active */
        }
        .content-wrapper {
          background-color: #f8f9fa;
        }
        .box {
          border-radius: 4px;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.12);
          border-top: 3px solid #ff8c42 !important;  /* Lighter orange default */
        }
        .box.box-primary {
          border-top-color: #3498db !important;
        }
        .box.box-success {
          border-top-color: #27ae60 !important;
        }
        .box.box-warning {
          border-top-color: #ffb366 !important;  /* Lighter warning orange */
        }
        .box.box-info {
          border-top-color: #00bcd4 !important;
        }
        .box.box-danger {
          border-top-color: #e74c3c !important;
        }
        .box-header {
          background-color: #ffffff;
          border-bottom: 1px solid #f4f4f4;
        }
        .box-header h3 {
          font-weight: 500;
          color: #2c3e50;
        }
        .small-box {
          border-radius: 4px;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.12);
        }
        .bg-aqua {
          background-color: #00bcd4 !important;
        }
        .bg-green {
          background-color: #27ae60 !important;
        }
        .bg-yellow {
          background-color: #ffb366 !important;  /* Lighter warning orange */
        }
        .bg-red {
          background-color: #e74c3c !important;
        }
        .bg-purple {
          background-color: #9b59b6 !important;
        }
        .bg-teal {
          background-color: #16a085 !important;
        }
        .bg-blue {
          background-color: #3498db !important;
        }
        .btn {
          border-radius: 3px;
          font-weight: 500;
        }
        .btn-warning {
          background-color: #ffb366;  /* Lighter warning orange */
          border-color: #ffb366;
          color: #2c3e50;
        }
        .btn-warning:hover {
          background-color: #ff9f40;
          border-color: #ff9f40;
        }
        .btn-info {
          background-color: #3498db;
          border-color: #3498db;
        }
        .btn-info:hover {
          background-color: #2980b9;
          border-color: #2980b9;
        }
        .btn-success {
          background-color: #27ae60;
          border-color: #27ae60;
        }
        .btn-success:hover {
          background-color: #229954;
          border-color: #229954;
        }
        .btn-primary {
          background-color: #ff8c42;  /* Lighter orange */
          border-color: #ff8c42;
        }
        .btn-primary:hover {
          background-color: #ff7a2e;  /* Slightly darker on hover */
          border-color: #ff7a2e;
        }
        .btn-danger {
          background-color: #e74c3c;
          border-color: #e74c3c;
        }
        .btn-danger:hover {
          background-color: #c0392b;
          border-color: #c0392b;
        }
        .selectize-input {
          border-radius: 3px;
          border-color: #ddd;
        }
        .sidebar-menu li > a {
          font-weight: 400;
        }
        /* Sidebar specific button styling */
        .main-sidebar .btn {
          transition: all 0.3s ease;
        }
        .main-sidebar .btn:hover {
          transform: translateY(-1px);
          box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
        }
        /* Sidebar input styling */
        .main-sidebar .selectize-control {
          background-color: transparent;
        }
        .main-sidebar .selectize-input {
          background-color: rgba(255, 255, 255, 0.9);
          border: 1px solid #ffb366;  /* Lighter orange border */
        }
        .main-sidebar .selectize-input.focus {
          border-color: #ff8c42;  /* Lighter orange on focus */
          box-shadow: 0 0 5px rgba(255, 140, 66, 0.3);
        }

        /* Force dropdown to open only downward */
        .main-sidebar .selectize-dropdown {
          top: 100% !important;
          bottom: auto !important;
          margin-top: 2px !important;
          max-height: 300px !important;
          overflow-y: auto !important;
        }

        .main-sidebar .slider-input {
          padding: 10px;
        }
        .main-sidebar .irs-bar {
          background: #ff8c42;  /* Lighter orange */
          border-top: 1px solid #ff8c42;
          border-bottom: 1px solid #ff8c42;
        }
        .main-sidebar .irs-bar-edge {
          background: #ff8c42;  /* Lighter orange */
          border: 1px solid #ff8c42;
        }
        .main-sidebar .irs-single, .main-sidebar .irs-from, .main-sidebar .irs-to {
          background: #ff8c42;  /* Lighter orange */
        }
        .main-sidebar label {
          color: #f5f5f5;
        }
        .main-sidebar .control-label {
          color: #f5f5f5;
        }
        .main-sidebar hr {
          border-color: #74564a;
          margin: 10px 0;
        }
        h4 {
          color: #2c3e50;
          font-weight: 500;
        }
        .chord-diagram-container {
          text-align: center;
          padding: 20px;
        }
        .chord-plot {
          display: inline-block;
          margin: 0 auto;
        }
        /* Download buttons styling */
        .download-section {
          background: #ffffff;
          padding: 15px;
          border-radius: 4px;
          margin: 10px 0;
          border: 1px solid #e0e0e0;
        }
        .download-btn-group {
          display: flex;
          gap: 10px;
          flex-wrap: wrap;
          justify-content: center;
        }
        /* Clean table styling */
        .dataTables_wrapper {
          font-size: 14px;
        }
        /* Value box improvements */
        .small-box h3 {
          font-weight: 600;
        }
        .small-box .icon {
          opacity: 0.3;
        }

        /* ENHANCED DataTable search and filter styling */
        .dataTables_wrapper .dataTables_filter {
          float: none !important;
          text-align: center !important;
          margin-bottom: 20px !important;
          margin-top: 10px !important;
        }

        .dataTables_filter label {
          font-weight: normal !important;
          font-size: 14px !important;
          color: #2c3e50 !important;
        }

        .dataTables_filter input {
          width: 400px !important;
          padding: 10px !important;
          font-size: 14px !important;
          border: 2px solid #ff8c42 !important;
          border-radius: 5px !important;
          background-color: white !important;
          margin-left: 0px !important;
        }

        .dataTables_filter input:focus {
          outline: none !important;
          border-color: #ff7a2e !important;
          box-shadow: 0 0 5px rgba(255, 140, 66, 0.5) !important;
        }

        /* Custom search box container */
        .custom-search-container {
          background: linear-gradient(135deg, #fff5eb, #ffe8d6);
          padding: 15px;
          border-radius: 8px;
          margin-bottom: 20px;
          border: 1px solid #ffb366;
        }

        .custom-search-container p {
          color: #666;
          font-size: 13px;
          margin: 0;
        }

        /* Individual column filters styling */
        thead input {
          width: 100% !important;
          padding: 5px !important;
          box-sizing: border-box !important;
          font-size: 12px !important;
          border: 1px solid #ddd !important;
          border-radius: 3px !important;
          background-color: white !important;
        }

        thead input:focus {
          border-color: #ff8c42 !important;
          outline: none !important;
        }

        /* Column filter select dropdowns */
        thead select {
          width: 100% !important;
          padding: 5px !important;
          font-size: 12px !important;
          border: 1px solid #ddd !important;
          border-radius: 3px !important;
          background-color: white !important;
        }

        /* Info text styling */
        .dataTables_info {
          color: #666 !important;
          font-size: 13px !important;
        }

        /* Length menu styling */
        .dataTables_length label {
          font-weight: normal !important;
          color: #666 !important;
        }

        .dataTables_length select {
          padding: 5px !important;
          border: 1px solid #ddd !important;
          border-radius: 3px !important;
        }
      "))
    ),

    sidebarMenu(
      menuItem("Species Map", tabName = "map", icon = icon("map-marked-alt")),
      menuItem("Statistics", tabName = "stats", icon = icon("chart-line")),
      menuItem("Occurrence Sources", tabName = "datasources", icon = icon("database")),
      menuItem("Pathways & Origin", tabName = "pathways", icon = icon("project-diagram")),
      menuItem("Data Table", tabName = "table", icon = icon("table")),
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    ),
    hr(),
    h4("Filters", style = "padding-left: 15px; color: #ffb366; font-weight: 500;"),

    # Filters with enhanced styling and dropdown direction
    pickerInput("realm_filter", "Select Realm:",
                choices = unique_realms,
                selected = NULL,
                multiple = TRUE,
                options = list(
                  `actions-box` = TRUE,
                  `selected-text-format` = "count > 2",
                  `count-selected-text` = "{0} realms selected",
                  `none-selected-text` = "All Realms",
                  `dropup-auto` = FALSE  # Force dropdown to open downward
                )),

    pickerInput("species_filter", "Select Species:",
                choices = unique_species,
                selected = NULL,
                multiple = TRUE,
                options = list(
                  `actions-box` = TRUE,
                  `live-search` = TRUE,
                  `selected-text-format` = "count > 2",
                  `count-selected-text` = "{0} species selected",
                  `none-selected-text` = "All Species",
                  `dropup-auto` = FALSE  # Force dropdown to open downward
                )),

    pickerInput("family_filter", "Select Family:",
                choices = unique_families,
                selected = NULL,
                multiple = TRUE,
                options = list(
                  `actions-box` = TRUE,
                  `live-search` = TRUE,
                  `selected-text-format` = "count > 2",
                  `count-selected-text` = "{0} families selected",
                  `none-selected-text` = "All Families",
                  `dropup-auto` = FALSE  # Force dropdown to open downward
                )),

    pickerInput("eu_filter", "EU Status:",
                choices = list("All" = "all", "Yes (Union Concern)" = "Yes", "Not of Union Concern" = "No"),
                selected = "all",
                multiple = FALSE,
                options = list(
                  `none-selected-text` = "All",
                  `dropup-auto` = FALSE  # Force dropdown to open downward
                )),

    pickerInput("county_filter", "Select County:",
                choices = unique_counties,
                selected = NULL,
                multiple = TRUE,
                options = list(
                  `actions-box` = TRUE,
                  `live-search` = TRUE,
                  `selected-text-format` = "count > 3",
                  `count-selected-text` = "{0} counties selected",
                  `none-selected-text` = "All Counties",
                  `dropup-auto` = FALSE  # Force dropdown to open downward
                )),

    sliderInput("year_filter", "Year Range:",
                min = min(species_data$year, na.rm = TRUE),
                max = max(species_data$year, na.rm = TRUE),
                value = c(min(species_data$year, na.rm = TRUE),
                          max(species_data$year, na.rm = TRUE)),
                step = 1, sep = ""),

    div(style = "text-align: center; padding: 10px;",
        actionButton("reset_filters", "Reset All Filters",
                     class = "btn",
                     style = "width: 90%; margin-bottom: 10px; background-color: #ff8c42; border-color: #ff8c42; color: white;"),
        actionButton("reset_zoom", "Reset Map Zoom",
                     class = "btn",
                     style = "width: 90%; background-color: #ffb366; border-color: #ffb366; color: #2c3e50;")
    )
  ),

  dashboardBody(
    tabItems(
      tabItem(
        tabName = "map",
        fluidRow(
          box(title = "Species Distribution Map",
              status = "primary", solidHeader = FALSE,
              width = 12, height = "600px",
              leafletOutput("species_map", height = "550px"))
        ),
        fluidRow(
          valueBoxOutput("total_records"),
          valueBoxOutput("selected_records"),
          valueBoxOutput("unique_species_count")
        ),
        fluidRow(
          valueBoxOutput("eu_species_count"),
          valueBoxOutput("oldest_record"),
          valueBoxOutput("newest_record")
        )
      ),

      tabItem(
        tabName = "stats",
        fluidRow(
          box(
            title = "Species Lists Download",
            status = "success",
            solidHeader = FALSE,
            width = 12,
            div(class = "download-section",
                h4(icon("download"), "Download Species Lists",
                   style = "text-align: center; margin-bottom: 15px; color: #2c3e50;"),
                div(class = "download-btn-group",
                    downloadButton("download_all_species", "All Species",
                                   class = "btn btn-success"),
                    downloadButton("download_terrestrial", "Terrestrial Species",
                                   class = "btn btn-warning"),
                    downloadButton("download_freshwater", "Freshwater Species",
                                   class = "btn btn-info"),
                    downloadButton("download_marine", "Marine Species",
                                   class = "btn btn-primary"),
                    downloadButton("download_eu_concern", "EU Concern Species",
                                   class = "btn btn-danger")
                ),
                br(),
                div(style = "text-align: center; color: #666; font-size: 12px;",
                    "Downloads will include species names from currently filtered data")
            )
          )
        ),
        fluidRow(
          box(title = "Top 25 Species by Occurrences",
              status = "warning", solidHeader = FALSE,
              width = 12, plotlyOutput("top_species_plot", height = "400px"))
        ),
        fluidRow(
          box(title = "Top 10 Counties by Records",
              status = "info", solidHeader = FALSE,
              width = 6, plotlyOutput("top_counties_plot", height = "350px")),
          box(title = "Top 10 Families by Occurrences",
              status = "success", solidHeader = FALSE,
              width = 6, plotlyOutput("top_families_plot", height = "350px"))
        ),
        fluidRow(
          box(title = "Basis of Record",
              status = "primary", solidHeader = FALSE,
              width = 6, plotlyOutput("basis_plot", height = "350px")),
          box(title = "Occurrences by Realm",
              status = "danger", solidHeader = FALSE,
              width = 6, plotlyOutput("realm_plot", height = "350px"))
        ),
        fluidRow(
          box(title = "Occurrences Accumulation Curve",
              status = "success", solidHeader = FALSE,
              width = 12, plotlyOutput("accum_curve_plot", height = "400px"))
        )
      ),

      tabItem(
        tabName = "datasources",
        fluidRow(
          box(
            title = "Data Sources Analysis",
            status = "primary",
            solidHeader = FALSE,
            width = 12,
            tags$div(style = "background: #ffffff; padding: 15px; border-radius: 4px; margin-bottom: 15px; border: 1px solid #e0e0e0;",
                     p(strong("Venn diagrams showing the overlap between different data sources for alien invertebrate species.")),
                     p(tags$span(class = "label", style = "background-color: #3498db;", "CS"), " Citizen Science  ",
                       tags$span(class = "label", style = "background-color: #e74c3c;", "PL"), " Published Literature  ",
                       tags$span(class = "label", style = "background-color: #f39c12;", "AO"), " Author's Observations")
            )
          )
        ),
        fluidRow(
          box(
            title = "All Species - Data Source Overlap",
            status = "success",
            solidHeader = FALSE,
            width = 12,
            plotOutput("all_venn_plot", height = "500px"),
            br(),
            fluidRow(
              valueBoxOutput("total_cs_count"),
              valueBoxOutput("total_pl_count"),
              valueBoxOutput("total_ao_count")
            )
          )
        ),
        fluidRow(
          box(
            title = "Terrestrial Species",
            status = "warning",
            solidHeader = FALSE,
            width = 4,
            plotOutput("terr_venn_plot", height = "300px"),
            br(),
            valueBoxOutput("terr_cs_count", width = 12),
            valueBoxOutput("terr_pl_count", width = 12),
            valueBoxOutput("terr_ao_count", width = 12)
          ),
          box(
            title = "Freshwater Species",
            status = "info",
            solidHeader = FALSE,
            width = 4,
            plotOutput("fw_venn_plot", height = "300px"),
            br(),
            valueBoxOutput("fw_cs_count", width = 12),
            valueBoxOutput("fw_pl_count", width = 12),
            valueBoxOutput("fw_ao_count", width = 12)
          ),
          box(
            title = "Marine Species",
            status = "primary",
            solidHeader = FALSE,
            width = 4,
            plotOutput("marine_venn_plot", height = "300px"),
            br(),
            valueBoxOutput("marine_cs_count", width = 12),
            valueBoxOutput("marine_pl_count", width = 12),
            valueBoxOutput("marine_ao_count", width = 12)
          )
        )
      ),

      tabItem(
        tabName = "pathways",
        fluidRow(
          box(
            title = "Introduction Pathways Analysis",
            status = "primary",
            solidHeader = FALSE,
            width = 12,
            tags$div(style = "background: #ffffff; padding: 15px; border-radius: 4px; border: 1px solid #e0e0e0;",
                     p(strong("Chord diagrams showing the relationships between species origins and their introduction pathways.")),
                     p("The width of the connections represents the number of species sharing that origin-pathway combination.")
            )
          )
        ),
        fluidRow(
          box(
            title = "Terrestrial Species: Origin-Pathway Relationships",
            status = "warning",
            solidHeader = FALSE,
            width = 12,
            div(class = "chord-diagram-container",
                plotOutput("terrestrial_chord", height = "700px", width = "100%")
            ),
            br(),
            fluidRow(
              valueBoxOutput("terr_species_count"),
              valueBoxOutput("terr_pathway_count"),
              valueBoxOutput("terr_origin_count")
            )
          )
        ),
        fluidRow(
          box(
            title = "Freshwater Species: Origin-Pathway Relationships",
            status = "info",
            solidHeader = FALSE,
            width = 12,
            div(class = "chord-diagram-container",
                plotOutput("freshwater_chord", height = "700px", width = "100%")
            ),
            br(),
            fluidRow(
              valueBoxOutput("fw_species_count"),
              valueBoxOutput("fw_pathway_count"),
              valueBoxOutput("fw_origin_count")
            )
          )
        ),
        fluidRow(
          box(
            title = "Marine Species: Origin-Pathway Relationships",
            status = "primary",
            solidHeader = FALSE,
            width = 12,
            div(class = "chord-diagram-container",
                plotOutput("marine_chord", height = "700px", width = "100%")
            ),
            br(),
            fluidRow(
              valueBoxOutput("marine_species_count"),
              valueBoxOutput("marine_pathway_count"),
              valueBoxOutput("marine_origin_count")
            )
          )
        )
      ),

      tabItem(
        tabName = "table",
        fluidRow(
          box(title = "Species Data Table",
              status = "primary", solidHeader = FALSE,
              width = 12,
              br(),
              # Simplified search box container
              div(class = "custom-search-container",
                  p("Use the search box below to filter all columns, or use individual column filters at the top of each column.")
              ),
              div(style = "background: #ffffff; padding: 15px; border-radius: 4px; margin-bottom: 15px; border: 1px solid #e0e0e0;",
                  fluidRow(
                    column(4,
                           p(strong("Password-protected download:")),
                           passwordInput("download_password", "Password:",
                                         value = "", width = "200px",
                                         placeholder = "Enter password")),
                    column(4,
                           br(),
                           downloadButton("download_data", "Download Filtered Data",
                                          class = "btn btn-primary"))
                  )
              ),
              DTOutput("species_table"))
        )
      ),

      tabItem(
        tabName = "about",
        fluidRow(
          box(title = "About This Application",
              status = "primary", solidHeader = FALSE, width = 12,
              tags$div(style = "padding: 20px;",
                       h3("Alien Invertebrates of Romania", style = "color: #2c3e50; margin-bottom: 20px; font-weight: 500;"),

                       tags$div(style = "background: #ffffff; padding: 20px; border-radius: 4px; margin-bottom: 20px; border: 1px solid #e0e0e0;",
                                h4(icon("info-circle"), "Application Information", style = "color: #2c3e50;"),
                                p(tags$b("Version:"), paste0(" ", as.character(packageVersion("alieninvro")))),
                                p(tags$b("Date of Deployment:"), {
                                  app_file <- system.file("shiny", "app.R", package = "alieninvro")
                                  format(file.info(app_file)$mtime, "%B %d, %Y")
                                }),
                                p(tags$b("Purpose:"), " This interactive application allows you to explore alien invertebrate species data included in the paper \"From soil to stream and sea: species richness and distribution of alien invertebrates in Romania\" by Preda et al. (submitted to Neobiota)."),
                                p(tags$b("Development:"), " Dashboard developed with assistance from Claude.ai Claude Opus 4.1 (Anthropic).")
                       ),

                       tags$div(style = "background: #ffffff; padding: 20px; border-radius: 4px; margin-bottom: 20px; border: 1px solid #e0e0e0;",
                                h4(icon("database"), "Dataset Information", style = "color: #2c3e50;"),
                                fluidRow(
                                  column(6,
                                         p(icon("list"), paste("Total records:", formatC(nrow(species_data), format="d", big.mark=","))),
                                         p(icon("bug"), paste("Total species:", length(unique_species))),
                                         p(icon("tree"), paste("Terrestrial species:", unique_terrestrial_species)),
                                         p(icon("water"), paste("Freshwater species:", unique_freshwater_species))
                                  ),
                                  column(6,
                                         p(icon("ship"), paste("Marine species:", unique_marine_species)),
                                         p(icon("exclamation-triangle"), paste("EU concern species:", unique_eu_concern_species)),
                                         p(icon("map-marker-alt"), "Geographic coverage: Romania"),
                                         p(icon("calendar"), paste("Temporal range:", min(species_data$year, na.rm=TRUE), "-", max(species_data$year, na.rm=TRUE)))
                                  )
                                )
                       ),

                       tags$div(style = "background: #ffffff; padding: 20px; border-radius: 4px; margin-bottom: 20px; border: 1px solid #e0e0e0;",
                                h4(icon("star"), "Key Features", style = "color: #2c3e50;"),
                                tags$ul(style = "list-style-type: none; padding-left: 0;",
                                        tags$li(icon("check", style="color: #27ae60;"), " Interactive map with species distribution (color-coded by realm)"),
                                        tags$li(icon("check", style="color: #27ae60;"), " Advanced filtering by realm, species, family, EU status, and county"),
                                        tags$li(icon("check", style="color: #27ae60;"), " Comprehensive statistical visualizations"),
                                        tags$li(icon("check", style="color: #27ae60;"), " Introduction pathways and origin analysis with chord diagrams"),
                                        tags$li(icon("check", style="color: #27ae60;"), " Data source overlap analysis with Venn diagrams"),
                                        tags$li(icon("check", style="color: #27ae60;"), " Downloadable species lists by realm"),
                                        tags$li(icon("check", style="color: #27ae60;"), " Password-protected data export functionality")
                                )
                       ),

                       tags$div(style = "background: #ffffff; padding: 20px; border-radius: 4px; border: 1px solid #e0e0e0;",
                                h4(icon("cogs"), "Technical Information", style = "color: #2c3e50;"),
                                p(tags$b("R version:"), paste0(" ", R.version.string)),
                                p(tags$b("RStudio version:"), " 2025.09.0+387"),
                                h5(tags$b("R Package Versions:")),
                                fluidRow(
                                  column(4,
                                         tags$ul(style = "list-style-type: none; padding-left: 0;",
                                                 tags$li(icon("cube", style="color: #ff8c42;"), paste(" shiny:", package_versions["shiny"])),
                                                 tags$li(icon("cube", style="color: #ff8c42;"), paste(" leaflet:", package_versions["leaflet"])),
                                                 tags$li(icon("cube", style="color: #ff8c42;"), paste(" DT:", package_versions["DT"])),
                                                 tags$li(icon("cube", style="color: #ff8c42;"), paste(" dplyr:", package_versions["dplyr"])),
                                                 tags$li(icon("cube", style="color: #ff8c42;"), paste(" shinydashboard:", package_versions["shinydashboard"]))
                                         )
                                  ),
                                  column(4,
                                         tags$ul(style = "list-style-type: none; padding-left: 0;",
                                                 tags$li(icon("cube", style="color: #ff8c42;"), paste(" plotly:", package_versions["plotly"])),
                                                 tags$li(icon("cube", style="color: #ff8c42;"), paste(" circlize:", package_versions["circlize"])),
                                                 tags$li(icon("cube", style="color: #ff8c42;"), paste(" viridis:", package_versions["viridis"])),
                                                 tags$li(icon("cube", style="color: #ff8c42;"), paste(" ggplot2:", package_versions["ggplot2"]))
                                         )
                                  ),
                                  column(4,
                                         tags$ul(style = "list-style-type: none; padding-left: 0;",
                                                 tags$li(icon("cube", style="color: #ff8c42;"), paste(" ggvenn:", package_versions["ggvenn"])),
                                                 tags$li(icon("cube", style="color: #ff8c42;"), paste(" ggpubr:", package_versions["ggpubr"])),
                                                 tags$li(icon("cube", style="color: #ff8c42;"), paste(" openxlsx:", package_versions["openxlsx"])),
                                                 tags$li(icon("cube", style="color: #ff8c42;"), paste(" shinyWidgets:", package_versions["shinyWidgets"]))
                                         )
                                  )
                                )
                       )
              )
          )
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {

  `%notin%` <- Negate(`%in%`)

  # Filtered data
  filtered_data <- reactive({
    data <- species_data

    # Apply realm filter
    if(!is.null(input$realm_filter) && length(input$realm_filter) > 0){
      data <- data %>% dplyr::filter(realm %in% input$realm_filter)
    }

    # Apply species filter
    if(!is.null(input$species_filter) && length(input$species_filter) > 0){
      data <- data %>% dplyr::filter(ScientificName %in% input$species_filter)
    }

    # Apply family filter
    if(!is.null(input$family_filter) && length(input$family_filter) > 0){
      data <- data %>% dplyr::filter(Family %in% input$family_filter)
    }

    # Apply EU status filter - FIXED
    if(!is.null(input$eu_filter) && input$eu_filter != "all"){
      data <- data %>% dplyr::filter(ias_eu == input$eu_filter)
    }

    # Apply county filter
    if(!is.null(input$county_filter) && length(input$county_filter) > 0){
      data <- data %>% dplyr::filter(CountyCode %in% input$county_filter)
    }

    # Apply year filter
    data <- data %>% dplyr::filter(year >= input$year_filter[1] & year <= input$year_filter[2])

    data
  })

  # FIXED Reset filters
  observeEvent(input$reset_filters, {
    updatePickerInput(session, "realm_filter", selected = character(0))
    updatePickerInput(session, "species_filter", selected = character(0))
    updatePickerInput(session, "family_filter", selected = character(0))
    updatePickerInput(session, "eu_filter", selected = "all")
    updatePickerInput(session, "county_filter", selected = character(0))
    updateSliderInput(session, "year_filter",
                      value = c(min(species_data$year, na.rm = TRUE),
                                max(species_data$year, na.rm = TRUE)))
  })

  # Map base with initial legend
  output$species_map <- renderLeaflet({
    leaflet::leaflet() %>%
      leaflet::addTiles() %>%
      leaflet::setView(lng = 25, lat = 46, zoom = 6) %>%
      leaflet::addProviderTiles(providers$CartoDB.Positron) %>%
      # Add initial legend
      leaflet::addLegend(
        position = "bottomright",
        colors = c("#e74c3c", "#3498db", "#2c3e50"),
        labels = c("Terrestrial", "Freshwater", "Marine"),
        title = "Realm",
        opacity = 0.7,
        layerId = "realm_legend"
      )
  })

  observeEvent(input$reset_zoom, {
    leaflet::leafletProxy("species_map") %>%
      leaflet::setView(lng = 25, lat = 46, zoom = 6)
  })

  # Map update with reactive data - updated colors to match United theme
  observeEvent(filtered_data(), {
    data <- filtered_data()
    leaflet::leafletProxy("species_map") %>%
      leaflet::clearMarkers() %>%
      leaflet::clearMarkerClusters() %>%
      leaflet::clearControls()

    if(nrow(data) > 0){
      # Create a SEPARATE dataset for map display only (preserves original data for table)
      map_data <- data %>%
        mutate(
          point_color = case_when(
            tolower(trimws(realm)) == "terrestrial" ~ "#e74c3c",  # Red
            tolower(trimws(realm)) == "freshwater" ~ "#3498db",   # Blue
            tolower(trimws(realm)) == "marine" ~ "#2c3e50",       # Dark gray
            TRUE ~ "#95a5a6"  # Light gray for any other/NA values
          )
        )

      # Add jittering for overlapping coordinates (ONLY for map display)
      # Group by coordinates to identify overlapping points
      map_data <- map_data %>%
        group_by(decimalLongitude, decimalLatitude) %>%
        mutate(
          point_count = n(),
          # Add small random jitter (max ~100 meters) for overlapping points
          jitter_lng = ifelse(point_count > 1,
                              decimalLongitude + runif(n(), -0.001, 0.001),
                              decimalLongitude),
          jitter_lat = ifelse(point_count > 1,
                              decimalLatitude + runif(n(), -0.001, 0.001),
                              decimalLatitude)
        ) %>%
        ungroup()

      # Get unique realms present in the filtered data
      present_realms <- unique(data$realm)
      present_realms <- present_realms[!is.na(present_realms)]

      # Filter colors and labels to only show present realms
      legend_colors <- c()
      legend_labels <- c()

      if("terrestrial" %in% present_realms) {
        legend_colors <- c(legend_colors, "#e74c3c")
        legend_labels <- c(legend_labels, "Terrestrial")
      }
      if("freshwater" %in% present_realms) {
        legend_colors <- c(legend_colors, "#3498db")
        legend_labels <- c(legend_labels, "Freshwater")
      }
      if("marine" %in% present_realms) {
        legend_colors <- c(legend_colors, "#2c3e50")
        legend_labels <- c(legend_labels, "Marine")
      }

      # If no realms present, show all as fallback
      if(length(legend_colors) == 0) {
        legend_colors <- c("#e74c3c", "#3498db", "#2c3e50")
        legend_labels <- c("Terrestrial", "Freshwater", "Marine")
      }

      # Add markers with jittered coordinates (using map_data, not original data)
      leaflet::leafletProxy("species_map") %>%
        leaflet::addCircleMarkers(
          data = map_data,
          lng = ~jitter_lng,  # Use jittered longitude for map display only
          lat = ~jitter_lat,  # Use jittered latitude for map display only
          radius = 6,
          popup = ~popup_text,  # Popup still shows original coordinates
          color = ~point_color,
          fillColor = ~point_color,
          fillOpacity = 0.7,
          stroke = TRUE,
          weight = 1,
          clusterOptions = leaflet::markerClusterOptions(maxClusterRadius = 50)
        ) %>%
        # Add legend for realm colors
        leaflet::addLegend(
          position = "bottomright",
          colors = legend_colors,
          labels = legend_labels,
          title = "Realm",
          opacity = 1,
          layerId = "realm_legend"
        )
    } else {
      # If no data, still add the default legend to maintain consistency
      leaflet::leafletProxy("species_map") %>%
        leaflet::addLegend(
          position = "bottomright",
          colors = c("#e74c3c", "#3498db", "#2c3e50"),
          labels = c("Terrestrial", "Freshwater", "Marine"),
          title = "Realm",
          opacity = 0.3,
          layerId = "realm_legend"
        )
    }
  }, ignoreNULL = FALSE)

  # FIXED DOWNLOAD HANDLERS (NO DUPLICATES)

  # Download handler for ALL species (no duplicates)
  output$download_all_species <- downloadHandler(
    filename = function() {
      paste("all_unique_species_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      # Get unique species first, then get their taxonomic info
      unique_species_list <- filtered_data() %>%
        # Group by species and take first occurrence of each taxonomic field
        group_by(ScientificName) %>%
        summarise(
          Family = first(Family),
          Order = first(Order),
          realms = paste(unique(realm[!is.na(realm)]), collapse = "; "),  # Combine all realms
          .groups = 'drop'
        ) %>%
        arrange(ScientificName)
      write.csv(unique_species_list, file, row.names = FALSE)
    }
  )

  # Download handler for TERRESTRIAL species (no duplicates)
  output$download_terrestrial <- downloadHandler(
    filename = function() {
      paste("terrestrial_species_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      terrestrial_list <- filtered_data() %>%
        filter(realm == "terrestrial") %>%
        # Get unique species within terrestrial realm
        group_by(ScientificName) %>%
        summarise(
          Family = first(Family),
          Order = first(Order),
          .groups = 'drop'
        ) %>%
        arrange(ScientificName)
      write.csv(terrestrial_list, file, row.names = FALSE)
    }
  )

  # Download handler for FRESHWATER species (no duplicates)
  output$download_freshwater <- downloadHandler(
    filename = function() {
      paste("freshwater_species_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      freshwater_list <- filtered_data() %>%
        filter(realm == "freshwater") %>%
        # Get unique species within freshwater realm
        group_by(ScientificName) %>%
        summarise(
          Family = first(Family),
          Order = first(Order),
          .groups = 'drop'
        ) %>%
        arrange(ScientificName)
      write.csv(freshwater_list, file, row.names = FALSE)
    }
  )

  # Download handler for MARINE species (no duplicates)
  output$download_marine <- downloadHandler(
    filename = function() {
      paste("marine_species_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      marine_list <- filtered_data() %>%
        filter(realm == "marine") %>%
        # Get unique species within marine realm
        group_by(ScientificName) %>%
        summarise(
          Family = first(Family),
          Order = first(Order),
          .groups = 'drop'
        ) %>%
        arrange(ScientificName)
      write.csv(marine_list, file, row.names = FALSE)
    }
  )

  # Download handler for EU CONCERN species (no duplicates)
  output$download_eu_concern <- downloadHandler(
    filename = function() {
      paste("eu_concern_species_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      eu_list <- filtered_data() %>%
        filter(ias_eu == "Yes") %>%
        # Get unique species and combine their realms
        group_by(ScientificName) %>%
        summarise(
          Family = first(Family),
          Order = first(Order),
          realms = paste(unique(realm[!is.na(realm)]), collapse = "; "),  # Combine all realms
          .groups = 'drop'
        ) %>%
        arrange(ScientificName)
      write.csv(eu_list, file, row.names = FALSE)
    }
  )

  # SIMPLIFIED DATA TABLE WITHOUT "Search all columns:" text
  output$species_table <- DT::renderDT({
    filtered_data() %>%
      dplyr::select(ID, ScientificName, Family, Order, realm, CountyCode,
                    Locality, year, recordedBy, basisOfRecord,
                    decimalLatitude, decimalLongitude, ias_eu) %>%
      DT::datatable(
        options = list(
          pageLength = 25,
          scrollX = TRUE,
          dom = 'lfrtip',  # Standard layout with search at top
          searching = TRUE,  # Enable searching
          search = list(
            regex = TRUE,
            caseInsensitive = TRUE,
            smart = TRUE
          ),
          language = list(
            search = "",  # Remove "Search all columns:" text
            searchPlaceholder = "Type to search..."
          ),
          initComplete = JS(
            "function(settings, json) {",
            "  $('.dataTables_filter input').css({",
            "    'width': '400px',",
            "    'padding': '10px',",
            "    'font-size': '14px'",
            "  });",
            "}"
          )
        ),
        filter = 'top',  # Column filters at top
        rownames = FALSE,
        class = 'cell-border stripe hover',
        caption = htmltools::tags$caption(
          style = 'caption-side: top; text-align: center; color: #666; font-size: 13px;',
          htmltools::em('Tip: Use individual column filters for specific fields.')
        )
      )
  })

  # Password-protected download (uses original filtered_data with correct coordinates)
  output$download_data <- downloadHandler(
    filename = function() {
      paste("filtered_species_data_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      if(input$download_password == "poim12008") {
        write.csv(filtered_data(), file, row.names = FALSE)
      } else {
        showNotification("Incorrect password!", type = "error")
        return(NULL)
      }
    }
  )

  # Value boxes with United theme colors
  output$total_records <- renderValueBox({
    valueBox(
      formatC(nrow(species_data), format = "d", big.mark = ","),
      "Total Records",
      icon = icon("database"),
      color = "blue"
    )
  })

  output$selected_records <- renderValueBox({
    valueBox(
      formatC(nrow(filtered_data()), format = "d", big.mark = ","),
      "Filtered Records",
      icon = icon("filter"),
      color = "yellow"
    )
  })

  output$unique_species_count <- renderValueBox({
    filtered_species <- filtered_data() %>%
      filter(!is.na(ScientificName)) %>%
      pull(ScientificName) %>%
      unique() %>%
      length()

    total_species <- length(unique_species)

    if(filtered_species == total_species) {
      valueBox(filtered_species, "Species", icon = icon("bug"), color = "green")
    } else {
      valueBox(
        filtered_species,
        paste0("Filtered Species (of ", total_species, " total)"),
        icon = icon("bug"),
        color = "green"
      )
    }
  })

  output$eu_species_count <- renderValueBox({
    eu_count <- filtered_data() %>%
      dplyr::filter(ias_eu == "Yes") %>%
      dplyr::distinct(ScientificName) %>%
      nrow()
    valueBox(eu_count, "Species of Union Concern",
             icon = icon("exclamation-triangle"), color = "red")
  })

  output$oldest_record <- renderValueBox({
    oldest_year <- min(filtered_data()$year, na.rm = TRUE)
    if(is.infinite(oldest_year)) oldest_year <- "N/A"
    valueBox(oldest_year, "Oldest Record (Year)",
             icon = icon("history"), color = "purple")
  })

  output$newest_record <- renderValueBox({
    newest_year <- max(filtered_data()$year, na.rm = TRUE)
    if(is.infinite(newest_year)) newest_year <- "N/A"
    valueBox(newest_year, "Newest Record (Year)",
             icon = icon("calendar"), color = "teal")
  })

  # FIXED Statistics plots - REMOVED numbers on bars
  output$top_species_plot <- plotly::renderPlotly({
    data <- filtered_data()
    if(nrow(data) == 0) {
      return(plotly::plotly_empty() %>%
               plotly::layout(title = "No data available"))
    }
    top_species <- data %>%
      dplyr::group_by(ScientificName) %>%
      dplyr::summarise(Count = dplyr::n()) %>%
      dplyr::arrange(dplyr::desc(Count)) %>%
      dplyr::slice_head(n = 25)

    plotly::plot_ly(top_species,
                    x = ~stats::reorder(ScientificName, -Count),
                    y = ~Count,
                    type = 'bar',
                    marker = list(color = '#ffb366'),  # Lighter orange
                    hovertemplate = '%{x}<br>Count: %{y}<extra></extra>') %>%
      plotly::layout(xaxis = list(title = "Species", tickangle = -45),
                     yaxis = list(title = "Number of Occurrences"),
                     margin = list(b = 150))
  })

  output$top_counties_plot <- plotly::renderPlotly({
    data <- filtered_data()
    if(nrow(data) == 0) {
      return(plotly::plotly_empty() %>%
               plotly::layout(title = "No data available"))
    }
    top_counties <- data %>%
      dplyr::filter(!is.na(CountyCode)) %>%
      dplyr::group_by(CountyCode) %>%
      dplyr::summarise(Count = dplyr::n()) %>%
      dplyr::arrange(dplyr::desc(Count)) %>%
      dplyr::slice_head(n = 10)

    plotly::plot_ly(top_counties,
                    x = ~stats::reorder(CountyCode, -Count),
                    y = ~Count,
                    type = 'bar',
                    marker = list(color = '#3498db'),
                    hovertemplate = '%{x}<br>Records: %{y}<extra></extra>') %>%
      plotly::layout(xaxis = list(title = "County", tickangle = -45),
                     yaxis = list(title = "Number of Records"),
                     margin = list(b = 100))
  })

  output$top_families_plot <- plotly::renderPlotly({
    data <- filtered_data()
    if(nrow(data) == 0) {
      return(plotly::plotly_empty() %>%
               plotly::layout(title = "No data available"))
    }
    top_families <- data %>%
      dplyr::filter(!is.na(Family)) %>%
      dplyr::group_by(Family) %>%
      dplyr::summarise(Count = dplyr::n()) %>%
      dplyr::arrange(dplyr::desc(Count)) %>%
      dplyr::slice_head(n = 10)

    plotly::plot_ly(top_families,
                    x = ~stats::reorder(Family, -Count),
                    y = ~Count,
                    type = 'bar',
                    marker = list(color = '#27ae60'),
                    hovertemplate = '%{x}<br>Count: %{y}<extra></extra>') %>%
      plotly::layout(xaxis = list(title = "Family", tickangle = -45),
                     yaxis = list(title = "Number of Occurrences"),
                     margin = list(b = 100))
  })

  output$basis_plot <- plotly::renderPlotly({
    data <- filtered_data()
    if(nrow(data) == 0) {
      return(plotly::plotly_empty() %>%
               plotly::layout(title = "No data available"))
    }
    basis_data <- data %>%
      dplyr::filter(!is.na(basisOfRecord)) %>%
      dplyr::group_by(basisOfRecord) %>%
      dplyr::summarise(Count = dplyr::n()) %>%
      dplyr::arrange(dplyr::desc(Count))

    plotly::plot_ly(basis_data,
                    labels = ~basisOfRecord,
                    values = ~Count,
                    type = 'pie',
                    textposition = 'inside',
                    textinfo = 'label+percent',
                    marker = list(colors = c('#ff8c42', '#ffb366', '#27ae60', '#3498db', '#9b59b6', '#e74c3c', '#16a085'))) %>%
      plotly::layout(title = "", showlegend = TRUE)
  })

  output$realm_plot <- plotly::renderPlotly({
    data <- filtered_data()
    if(nrow(data) == 0) {
      return(plotly::plotly_empty() %>%
               plotly::layout(title = "No data available"))
    }
    realm_data <- data %>%
      dplyr::filter(!is.na(realm)) %>%
      dplyr::group_by(realm) %>%
      dplyr::summarise(Count = dplyr::n()) %>%
      dplyr::arrange(dplyr::desc(Count))

    realm_colors <- c("terrestrial" = "#e74c3c",
                      "freshwater" = "#3498db",
                      "marine" = "#2c3e50")

    color_vector <- realm_colors[realm_data$realm]

    plotly::plot_ly(realm_data,
                    labels = ~realm,
                    values = ~Count,
                    type = 'pie',
                    textposition = 'inside',
                    textinfo = 'label+percent',
                    marker = list(colors = color_vector)) %>%
      plotly::layout(title = "", showlegend = TRUE)
  })

  output$accum_curve_plot <- plotly::renderPlotly({
    data <- filtered_data()
    if(nrow(data) == 0) {
      return(plotly::plotly_empty() %>%
               plotly::layout(title = "No data available"))
    }
    accum_data <- data %>%
      dplyr::group_by(year) %>%
      dplyr::summarise(Occurrences = dplyr::n()) %>%
      dplyr::arrange(year) %>%
      dplyr::mutate(Cumulative = cumsum(Occurrences))

    plotly::plot_ly(accum_data,
                    x = ~year,
                    y = ~Cumulative,
                    type = 'scatter',
                    mode = 'lines+markers',
                    line = list(color = '#27ae60', width = 3),
                    marker = list(size = 8, color = '#27ae60')) %>%
      plotly::layout(xaxis = list(title = "Year"),
                     yaxis = list(title = "Cumulative Occurrences"))
  })

  # CHORD DIAGRAMS

  # Helper function to create chord diagrams with labeling
  create_chord_diagram <- function(realm_filter, color_option = "B") {
    data <- species_chord %>% filter(realm == realm_filter)

    if(nrow(data) > 0) {
      # Prepare matrix using label columns
      mat <- prepare_chord_data(species_chord, realm_filter)

      if(!is.null(mat) && sum(mat) > 0) {
        # Reset circlize
        circos.clear()

        # Set parameters
        circos.par(
          gap.degree = 1,
          track.margin = c(0.02, 0.02),
          start.degree = -60
        )

        # Generate colors
        n_origins <- nrow(mat)
        n_pathways <- ncol(mat)

        # Use viridis palette
        origin_colors <- viridis(n_origins, alpha = 0.6, option = color_option, begin = 0.1, end = 0.4)
        pathway_colors <- viridis(n_pathways, alpha = 0.6, option = color_option, begin = 0.5, end = 0.9)

        # Combine colors
        grid_colors <- c(origin_colors, pathway_colors)
        names(grid_colors) <- c(rownames(mat), colnames(mat))

        # Create chord diagram
        chordDiagram(
          mat,
          grid.col = grid_colors,
          transparency = 0.30,
          directional = 1,
          annotationTrack = "grid",
          annotationTrackHeight = c(0.05, 0.1),
          link.sort = TRUE,
          link.largest.ontop = TRUE,
          preAllocateTracks = list(
            track.height = max(strwidth(unlist(dimnames(mat))))
          )
        )

        # Add labels with clockwise orientation
        circos.track(
          track.index = 1,
          panel.fun = function(x, y) {
            circos.text(
              CELL_META$xcenter,
              CELL_META$ylim[1],
              CELL_META$sector.index,
              facing = "clockwise",
              niceFacing = TRUE,
              adj = c(0, 0.5),
              cex = 1,
              col = "black",
              font = 2
            )
          },
          bg.border = NA
        )

        # Add static pathway legend
        legend("bottomright",
               legend = c(
                 "PATHWAY CODES:",
                 "C:EfC = Commodity: Escape from confinement",
                 "C:RiN = Commodity: Release in nature",
                 "C:T-C = Commodity: Transport-Contaminant",
                 "S:C = Spread: Corridor",
                 "S:U = Spread: Unaided",
                 "V:T-S = Vector: Transport-Stowaway"
               ),
               text.col = c("black", rep("gray30", 6)),
               text.font = c(2, rep(1, 6)),
               bty = "n",
               cex = 0.65)

        return(TRUE)
      }
    }
    return(FALSE)
  }

  # Terrestrial chord diagram
  output$terrestrial_chord <- renderPlot({
    success <- create_chord_diagram("terrestrial", "B")
    if(!success) {
      plot.new()
      text(0.5, 0.5, "No data available for terrestrial realm", cex = 1.5, col = "gray50")
    }
  }, width = 700, height = 700)

  # Freshwater chord diagram
  output$freshwater_chord <- renderPlot({
    success <- create_chord_diagram("freshwater", "C")
    if(!success) {
      plot.new()
      text(0.5, 0.5, "No data available for freshwater realm", cex = 1.5, col = "gray50")
    }
  }, width = 700, height = 700)

  # Marine chord diagram
  output$marine_chord <- renderPlot({
    success <- create_chord_diagram("marine", "D")
    if(!success) {
      plot.new()
      text(0.5, 0.5, "No data available for marine realm", cex = 1.5, col = "gray50")
    }
  }, width = 700, height = 700)

  # Pathway statistics value boxes
  output$terr_species_count <- renderValueBox({
    count <- species_chord %>%
      filter(realm == "terrestrial") %>%
      distinct(ScientificName) %>%
      nrow()
    valueBox(count, "Terrestrial Species", icon = icon("tree"), color = "yellow")
  })

  output$terr_pathway_count <- renderValueBox({
    count <- species_chord %>%
      filter(realm == "terrestrial", !is.na(pathway_1)) %>%
      distinct(pathway_1) %>%
      nrow()
    valueBox(count, "Unique Pathways", icon = icon("road"), color = "yellow")
  })

  output$terr_origin_count <- renderValueBox({
    count <- species_chord %>%
      filter(realm == "terrestrial", !is.na(native_in_1)) %>%
      distinct(native_in_1) %>%
      nrow()
    valueBox(count, "Origin Regions", icon = icon("globe"), color = "yellow")
  })

  output$fw_species_count <- renderValueBox({
    count <- species_chord %>%
      filter(realm == "freshwater") %>%
      distinct(ScientificName) %>%
      nrow()
    valueBox(count, "Freshwater Species", icon = icon("water"), color = "aqua")
  })

  output$fw_pathway_count <- renderValueBox({
    count <- species_chord %>%
      filter(realm == "freshwater", !is.na(pathway_1)) %>%
      distinct(pathway_1) %>%
      nrow()
    valueBox(count, "Unique Pathways", icon = icon("road"), color = "aqua")
  })

  output$fw_origin_count <- renderValueBox({
    count <- species_chord %>%
      filter(realm == "freshwater", !is.na(native_in_1)) %>%
      distinct(native_in_1) %>%
      nrow()
    valueBox(count, "Origin Regions", icon = icon("globe"), color = "aqua")
  })

  output$marine_species_count <- renderValueBox({
    count <- species_chord %>%
      filter(realm == "marine") %>%
      distinct(ScientificName) %>%
      nrow()
    valueBox(count, "Marine Species", icon = icon("ship"), color = "blue")
  })

  output$marine_pathway_count <- renderValueBox({
    count <- species_chord %>%
      filter(realm == "marine", !is.na(pathway_1)) %>%
      distinct(pathway_1) %>%
      nrow()
    valueBox(count, "Unique Pathways", icon = icon("road"), color = "blue")
  })

  output$marine_origin_count <- renderValueBox({
    count <- species_chord %>%
      filter(realm == "marine", !is.na(native_in_1)) %>%
      distinct(native_in_1) %>%
      nrow()
    valueBox(count, "Origin Regions", icon = icon("globe"), color = "blue")
  })

  # DATA SOURCES TAB - VENN DIAGRAMS

  # Prepare Venn diagram data
  prepare_venn_data <- function(data) {
    venn_data <- dplyr::tibble(
      CS = data$CS,
      PL = data$PL,
      AO = data$AO
    )
    return(venn_data)
  }

  # All species Venn diagram
  output$all_venn_plot <- renderPlot({
    all_venn <- prepare_venn_data(species_list)
    p <- ggvenn(all_venn, c("CS", "PL", "AO"),
                fill_color = c("#3498db", "#e74c3c", "#ffb366"),  # Lighter orange for AO
                stroke_size = 1,
                set_name_size = 5,
                text_size = 4) +
      labs(title = "Data Source Overlap - All Species",
           subtitle = "CS: Citizen Science, PL: Published Literature, AO: Author's Observations") +
      theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
            plot.subtitle = element_text(size = 12, hjust = 0.5))
    print(p)
  })

  # Terrestrial Venn diagram
  output$terr_venn_plot <- renderPlot({
    terr_data <- species_list %>% filter(realm == "terrestrial")
    if(nrow(terr_data) > 0) {
      terr_venn <- prepare_venn_data(terr_data)
      p <- ggvenn(terr_venn, c("CS", "PL", "AO"),
                  fill_color = c("#3498db", "#e74c3c", "#ffb366"),  # Lighter orange for AO
                  stroke_size = 0.8,
                  set_name_size = 4,
                  text_size = 3)
      print(p)
    } else {
      plot.new()
      text(0.5, 0.5, "No terrestrial data", cex = 1.2)
    }
  })

  # Freshwater Venn diagram
  output$fw_venn_plot <- renderPlot({
    fw_data <- species_list %>% filter(realm == "freshwater")
    if(nrow(fw_data) > 0) {
      fw_venn <- prepare_venn_data(fw_data)
      p <- ggvenn(fw_venn, c("CS", "PL", "AO"),
                  fill_color = c("#3498db", "#e74c3c", "#ffb366"),  # Lighter orange for AO
                  stroke_size = 0.8,
                  set_name_size = 4,
                  text_size = 3)
      print(p)
    } else {
      plot.new()
      text(0.5, 0.5, "No freshwater data", cex = 1.2)
    }
  })

  # Marine Venn diagram
  output$marine_venn_plot <- renderPlot({
    marine_data <- species_list %>% filter(realm == "marine")
    if(nrow(marine_data) > 0) {
      marine_venn <- prepare_venn_data(marine_data)
      p <- ggvenn(marine_venn, c("CS", "PL", "AO"),
                  fill_color = c("#3498db", "#e74c3c", "#ffb366"),  # Lighter orange for AO
                  stroke_size = 0.8,
                  set_name_size = 4,
                  text_size = 3)
      print(p)
    } else {
      plot.new()
      text(0.5, 0.5, "No marine data", cex = 1.2)
    }
  })

  # Data source value boxes - All species
  output$total_cs_count <- renderValueBox({
    count <- sum(species_list$CS, na.rm = TRUE)
    valueBox(count, "Citizen Science", icon = icon("users"), color = "teal")
  })

  output$total_pl_count <- renderValueBox({
    count <- sum(species_list$PL, na.rm = TRUE)
    valueBox(count, "Published Literature", icon = icon("book"), color = "red")
  })

  output$total_ao_count <- renderValueBox({
    count <- sum(species_list$AO, na.rm = TRUE)
    valueBox(count, "Author's Observations", icon = icon("user-edit"), color = "yellow")
  })

  # Terrestrial value boxes
  output$terr_cs_count <- renderValueBox({
    count <- species_list %>%
      filter(realm == "terrestrial") %>%
      pull(CS) %>%
      sum(na.rm = TRUE)
    valueBox(count, "CS", icon = icon("users"), color = "teal")
  })

  output$terr_pl_count <- renderValueBox({
    count <- species_list %>%
      filter(realm == "terrestrial") %>%
      pull(PL) %>%
      sum(na.rm = TRUE)
    valueBox(count, "PL", icon = icon("book"), color = "red")
  })

  output$terr_ao_count <- renderValueBox({
    count <- species_list %>%
      filter(realm == "terrestrial") %>%
      pull(AO) %>%
      sum(na.rm = TRUE)
    valueBox(count, "AO", icon = icon("user-edit"), color = "yellow")
  })

  # Freshwater value boxes
  output$fw_cs_count <- renderValueBox({
    count <- species_list %>%
      filter(realm == "freshwater") %>%
      pull(CS) %>%
      sum(na.rm = TRUE)
    valueBox(count, "CS", icon = icon("users"), color = "teal")
  })

  output$fw_pl_count <- renderValueBox({
    count <- species_list %>%
      filter(realm == "freshwater") %>%
      pull(PL) %>%
      sum(na.rm = TRUE)
    valueBox(count, "PL", icon = icon("book"), color = "red")
  })

  output$fw_ao_count <- renderValueBox({
    count <- species_list %>%
      filter(realm == "freshwater") %>%
      pull(AO) %>%
      sum(na.rm = TRUE)
    valueBox(count, "AO", icon = icon("user-edit"), color = "yellow")
  })

  # Marine value boxes
  output$marine_cs_count <- renderValueBox({
    count <- species_list %>%
      filter(realm == "marine") %>%
      pull(CS) %>%
      sum(na.rm = TRUE)
    valueBox(count, "CS", icon = icon("users"), color = "teal")
  })

  output$marine_pl_count <- renderValueBox({
    count <- species_list %>%
      filter(realm == "marine") %>%
      pull(PL) %>%
      sum(na.rm = TRUE)
    valueBox(count, "PL", icon = icon("book"), color = "red")
  })

  output$marine_ao_count <- renderValueBox({
    count <- species_list %>%
      filter(realm == "marine") %>%
      pull(AO) %>%
      sum(na.rm = TRUE)
    valueBox(count, "AO", icon = icon("user-edit"), color = "yellow")
  })
}

# Run app
shinyApp(ui = ui, server = server)
