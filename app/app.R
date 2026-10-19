library(shiny)
library(bslib)
library(plotly)
library(leaflet)
#options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/jammy/latest"))
#remotes::install_version("terra", version = "1.8-21")
# Set up week labels for the app toggle 
week_labels <- paste0(
  "Week ", 1:53, " (",
  c("Early Jan","Early Jan", "Mid Jan", "Late Jan", "Late Jan",
    "Early Feb","Early Feb", "Late Feb","Late Feb",
    "Early Mar", "Early Mar","Mid Mar","Late Mar","Late Mar",
    "Early Apr", "Early Apr","Late Apr","Late Apr",
    "Early May","Early May", "Late May","Late May",
    "Early Jun", "Early Jun","Mid Jun","Late Jun","Late Jun",
    "Early Jul", "Early Jul","Late Jul", "Late Jul", 
    "Early Aug", "Early Aug","Mid Aug","Late Aug","Late Aug",
    "Early Sep", "Early Sep","Late Sep","Late Sep", 
    "Early Oct", "Early Oct","Late Oct","Late Oct",
    "Early Nov", "Early Nov","Mid Nov","Late Nov", "Late Nov",
    "Early Dec","Early Dec","Late Dec","Late Dec")[1:53],
  ")"
)

# Use system fonts instead of Google Fonts
# my_theme <- bs_theme(
#   base_font = font_collection("-apple-system", "BlinkMacSystemFont", "Segoe UI", "Roboto", "sans-serif")
# )

# Pull in data:
df.wide <- readRDS("data/df_wide_preprocessed.rds")
# spam.stat.areas <- readRDS("data/spam_stat_areas.rds")
spam.stat.areas <- readRDS("data/spam_stat_areas_filtered.rds")


# USER INTERFACE (UI) ------------------------------------------------------
ui <- page_navbar(
  title = "SPAM: Spawning Seasonality & Maturity Tracker",
  window_title = "SPAM Tracker",
  
  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",
    base_font = font_google("Inter"),       # Extremely clean, highly legible neo-grotesque sans-serif
    heading_font = font_google("Oswald") # base_font = font_collection("-apple-system", "BlinkMacSystemFont", "Segoe UI", "Roboto", "Helvetica Neue", "Arial", "sans-serif"),
    # heading_font = font_collection("-apple-system", "BlinkMacSystemFont", "Segoe UI", "Roboto", "Helvetica Neue", "Arial", "sans-serif")
  ),
  
  tags$head(
    tags$style(HTML("
      /* Keep map interactive borders sharp */
      .leaflet-pane path.leaflet-interactive { 
        stroke: #111111 !important; 
        stroke-width: 1px !important; 
        stroke-opacity: 0.9 !important; 
      } 
      
      /* Outline the Leaflet Minichart legend box in black */
      .leaflet-control.minicharts-legend {
        border: 2px solid #000000 !important;
        border-radius: 6px !important;
        box-shadow: 0 2px 6px rgba(0,0,0,0.2) !important;
        background-color: #FFFFFF !important;
        padding: 8px !important;
      }

      /* Clean popup theme rules */
      .leaflet-popup-content-wrapper {
        font-family: 'Open Sans', -apple-system, sans-serif !important;
        border-radius: 8px !important;
      }
      .leaflet-popup-content {
        font-size: 15px !important; 
        line-height: 1.5 !important;
        color: #2C3E50 !important;
      }
      .popup-title {
        font-weight: 800;
        font-size: 16px;
        border-bottom: 2px solid #ECF0F1;
        padding-bottom: 4px;
        margin-bottom: 6px;
      }

      /* 🎨 NEW: Dark Slate Blue Theme for Card Headers */
      .card-header {
        background-color: #2C3E50 !important;
        color: #FFFFFF !important;
        #font-weight: bold !important;
        font-size: 20px !important;
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif !important;    
        }
     

      /* 📱 NEW: Massive, easy-to-tap touch targets for filters */
      .form-group label {
        font-weight: 800 !important;
        font-size: 20px !important;
        letter-spacing: 0.8px !important;
        color: #2C3E50;
        margin-bottom: 6px;
      }
      .selectize-input {
        font-size: 18px !important;      /* Large readable font size */
        padding: 12px 16px !important;   /* Extra thick padding for thick fingers */
        line-height: 1.5 !important;
        border: 2px solid #BDC3C7 !important; /* Prominent border outline */
        border-radius: 6px !important;
      }
      .selectize-dropdown {
        font-size: 18px !important;  
        z-index: 9999 !important; /* Floats menu above all other cards */
        max-height: 250px !important; /* Keeps list scrollable on smaller screens */
      }
      .selectize-dropdown .option {
        padding: 10px 16px !important;   /* Spacious items in the list */
      }

      /* MOBILE NO-SCROLL MAGIC: Adjust heights automatically based on screen layout */
      @media (min-width: 768px) {
        /* Desktop: Standard column sizing */
        .desktop-card-height { height: 40vh !important; }
        .desktop-map-height { height: 80vh !important; }
      }
      
      @media (max-width: 767px) {
        /* Mobile: Lock visual height to prevent scrolling outside the viewing frame */
        .mobile-stack-container {
          height: calc(100vh - 70px) !important;
          display: flex;
          flex-direction: column;
          gap: 10px;
        }
        .mobile-filter-card { flex: 0 0 auto; }
        .mobile-chart-card { flex: 1 1 30%; }
        .mobile-map-card { flex: 1 1 50%; }
        
        /* Force plot contents to scale instead of clipping out */
        .shiny-plot-output, .leaflet-container { 
          height: 100% !important; 
          width: 100% !important; 
        }
      }
    "))
  ),
  
  nav_panel(
    title = "Weekly Tracker",
    
    div(
      class = "mobile-stack-container",
      
      layout_columns(
        col_widths = c(4, 8),
        
        # LEFT COLUMN (Controls & Chart stacked cleanly inside a standard div)
        div(
          class = "d-flex flex-column gap-3",
          
          card(
            class = "mobile-filter-card",
            card_header("Filter Panel"),
            selectizeInput(
              inputId = "selected_week", 
              label = "Select Week of Year:", 
              choices = setNames(1:53, week_labels), 
              selected = 10,
              options = list(
                dropdownParent = "body"
                )
            )
          ),
          
          card(
            class = "desktop-card-height mobile-chart-card",
            card_header(uiOutput(outputId = "dynamic_regional_title")),
            plotlyOutput(outputId = "regional_pies", height = "100%"),
            full_screen = TRUE
          )
        ),
        
        # RIGHT COLUMN (The Map Window)
        card(
          class = "mobile-map-card desktop-map-height",
          card_header("Mackerel Maturity Stages (Weekly Snapshot)"),
          leafletOutput(outputId = "maturity_map", height = "100%"),
          full_screen = TRUE
        )
      )
    )
  )
)

# SERVER LOGIC -------------------------------------------------------------
server <- function(input, output, session) {
  
  # Calendar contextual banner rendering
  output$week_context_text <- renderUI({
    wk <- as.numeric(input$selected_week)
  })
  
  # Reactive map subset
  my_map_data <- reactive({
    req(input$selected_week)
   
    selected_wk <- as.integer(input$selected_week)
    
    df.wide |> 
      dplyr::filter(week == selected_wk & MAT != 0 & #as.numeric(input$selected_week)
                      !is.na(stat.lat) & 
                      !is.na(stat.lon)) |> 
      dplyr::group_by(area_code, region, stat.lat, stat.lon) |> 
      dplyr::summarise(
        Immature   = sum(MAT == 1, na.rm = TRUE),
        Developing = sum(MAT == 2, na.rm = TRUE),
        Spawning   = sum(MAT %in% c(3,4), na.rm = TRUE),
        Spent      = sum(MAT == 5, na.rm = TRUE),
        Resting    = sum(MAT == 6, na.rm = TRUE),
        Max_Weight = max(OW, na.rm = TRUE), # Added na.rm = TRUE to prevent errors
        Avg_Weight = mean(OW, na.rm = TRUE),
        Min_Weight = min(OW, na.rm = TRUE),
        Max_Length = max(TL, na.rm = TRUE),
        Avg_Length = mean(TL, na.rm = TRUE),
        Min_Length = min(TL, na.rm = TRUE),
        .groups = "drop"
      ) |> 
      dplyr::mutate(Total_Samples = Immature + Developing + Spawning + Spent + Resting)
  })
  # Reactive monthly spawn subset
  # month_data <- reactive({
  #   req(input$selected_week)
  #   target_month <- df.wide |> 
  #     dplyr::filter(week == selected_week) |> #as.numeric(input$selected_week)
  #     dplyr::pull(month) |> 
  #     unique() |> 
  #     na.omit()
  #   if(length(target_month) > 1) target_month <- target_month[1] 
  #   
  #   df.wide |> 
  #     tidyr::drop_na(MAT) |> 
  #     dplyr::filter(month == target_month & MAT !=0 & !is.na(region)) |> 
  #     dplyr::mutate(MAT = as.factor(MAT)) |> 
  #     dplyr::group_by(region,month)|> 
  #     dplyr::summarise(
  #       Immature   = sum(MAT == 1, na.rm = TRUE),
  #       Developing = sum(MAT == 2, na.rm = TRUE),
  #       Spawning   = sum(MAT %in% c(3,4), na.rm = TRUE),
  #       Spent      = sum(MAT == 5, na.rm = TRUE),
  #       Resting    = sum(MAT == 6, na.rm = TRUE),
  #       .groups = "drop"
  #     ) |> 
  #     dplyr::mutate(Total_Samples = Immature + Developing + Spawning + Spent + Resting, 
  #                   calc_month = month)
  # })
  month_data <- reactive({
    req(input$selected_week)
    
    selected_wk <- as.numeric(input$selected_week)
    
    # Safe extraction of month string
    sub_df <- df.wide[df.wide$week == selected_wk & !is.na(df.wide$month), ]
    if (nrow(sub_df) == 0) return(NULL)
    
    target_month <- as.character(sub_df$month[1])
    
    res <- df.wide |> 
      dplyr::filter(!is.na(MAT) & MAT != 0 & month == target_month & !is.na(region)) |> 
      dplyr::mutate(MAT = as.character(MAT)) |> 
      dplyr::group_by(region) |> 
      dplyr::summarise(
        Immature   = sum(MAT == "1", na.rm = TRUE),
        Developing = sum(MAT == "2", na.rm = TRUE),
        Spawning   = sum(MAT %in% c("3","4"), na.rm = TRUE),
        Spent      = sum(MAT == "5", na.rm = TRUE),
        Resting    = sum(MAT == "6", na.rm = TRUE),
        .groups = "drop"
      ) |> 
      dplyr::mutate(
        Total_Samples = Immature + Developing + Spawning + Spent + Resting,
        calc_month = target_month
      )
    
    if (nrow(res) == 0) return(NULL)
    res
  })
  
  
  # Render base bathymetric ocean layout
  output$maturity_map <- renderLeaflet({
    leaflet(
      options = leafletOptions(
      zoomControl = FALSE,       
      minZoom = 6.3,              
      maxZoom = 8,                
      dragging = FALSE,           
      doubleClickZoom = FALSE,   
      scrollWheelZoom = FALSE,    
      touchZoom = FALSE           
      )
      ) |> 
      addProviderTiles(providers$Esri.OceanBasemap) |> 
      addPolygons(
        data = spam.stat.areas,
        fillColor = "transparent",     
        color = "#333333",           
        weight = 1.5,                 
        opacity = 0.7,                 
        label = ~paste("Statistical Area:", Id),
        highlightOptions = highlightOptions(
          weight = 3,
          color = "#16a085",
          bringToFront = FALSE  
        )
      ) |> 
      setView(lng = -70.0, lat = 41.5, zoom = 6)
  })
  
 
  # Reactive map layer for updating pie charts (Timing-safe for Shinylive)
  observeEvent(list(my_map_data(), input$maturity_map_bounds), { 
    # Wait until both data and map bounds are initialized in JS
    req(input$maturity_map_bounds)
    data <- my_map_data() 
    
    # clear previous minicharts
    leafletProxy("maturity_map") |> leaflet.minicharts::clearMinicharts()
    
    if (!is.null(data) && nrow(data) > 0) { 
      stages <- c('Immature', 'Developing', 'Spawning', 'Spent', 'Resting') 
      stage_colors <- c("#cccccc", "#56B4E9", "#FFC72C", "#2ecc71", '#CC79A7') 
      
      # Extract coordinates as clean numeric vectors
      lons <- as.numeric(data$stat.lon)
      lats <- as.numeric(data$stat.lat)
      widths <- as.numeric(18 + (data$Total_Samples * 0.15))
      
      # Create a clean matrix
      mat <- as.matrix(data[, stages])
      chart_mat <- matrix(
        as.numeric(mat), 
        nrow = nrow(mat), 
        ncol = ncol(mat),
        dimnames = list(NULL, stages)
      )
      
      # Clean HTML popup strings
      popups <- paste0(
        "<div>",
        "<strong>Stat Area:</strong> ", data$area_code, "<br/>",
        "<strong>Total Fish Sampled:</strong> ", data$Total_Samples, "<br/>",
        "<strong>Min & Max Weight:</strong> ", data$Min_Weight, " to ", data$Max_Weight, " g<br/>",
        "<strong>Min & Max Length:</strong> ", data$Min_Length/10, " to ", data$Max_Length/10, " cm<br/>",
        "<strong>Avg Weight:</strong> ", round(data$Avg_Weight, 1), " g<br/>",
        "<strong>Avg Length:</strong> ", round(data$Avg_Length/10, 1), " cm",
        "</div>"
      )
      
      # Render minicharts safely
      leafletProxy("maturity_map") |> 
        leaflet.minicharts::addMinicharts( 
          lng = lons, 
          lat = lats, 
          type = "pie", 
          chartdata = chart_mat, 
          colorPalette = stage_colors, 
          layerId = as.character(data$area_code),
          width = widths, 
          popup = leaflet.minicharts::popupArgs(html = popups),
          transitionTime = 0, 
          legendPosition = "topleft"
        ) 
    } 
  }, ignoreInit = FALSE)
  
  
  
  
  # Dynamic UI heading for the regional monthly pie charts
  # output$dynamic_regional_title <- renderUI({
  #   req(month_data()) # Pause rendering until the dataset calculates
  #   current_month <- unique(month_data()$calc_month)
  #   h4(
  #     paste("Month at a Glance (By Region) —", current_month), 
  #     #style = "font-weight: bold; color: #2c3e50;"
  #   )
  # })
  
  output$dynamic_regional_title <- renderUI({
    m_data <- month_data()
    if (is.null(m_data) || nrow(m_data) == 0) {
      return("Month at a Glance")
    }
    
    current_month <- m_data$calc_month[1]
    paste("Month at a Glance (By Region) —", current_month)
  })
  
  
  # Reactive map layer updating regional pie charts
  output$regional_pies <- renderPlotly({
    req(month_data()) # Ensure data is loaded
    # Set color pallete to match map pies
    stage_colors <- c("#cccccc", "#56B4E9", "#FFC72C", "#2ecc71", '#CC79A7')
    
    # Transform your wide reactive data into long format for plotting
    long_data <- month_data() |> 
      tidyr::pivot_longer(
        cols = c(Immature, Developing, Spawning, Spent, Resting),
        names_to = "Stage",
        values_to = "Count"
      ) 
    
    # Filter for North Region
    p_north <- plot_ly(
      data = dplyr::filter(long_data, region == "North"),
      labels = ~Stage,
      values = ~Count,
      marker = list(line = list(color = 'black', width = 1.5),colors = stage_colors),
      type = 'pie',
      name = "North",
      domain = list(x = c(0, 0.45))
    ) 
    
    # Filter for South Region
    p_south <- plot_ly(
      data = dplyr::filter(long_data, region == "South"),
      labels = ~Stage,
      values = ~Count,
      marker = list(line = list(color = 'black', width = 1.5),colors = stage_colors),
      type = 'pie',
      name = "South",
      domain = list(x = c(0.55, 1))
    ) 
    
    # Combine into one layout
    subplot(p_north, p_south, nrows = 1) |>
      layout(
        showlegend = FALSE,
        margin = list(t = 60),
        annotations = list(
          list(
            text = "<b>North</b>", showarrow = FALSE,
            x = 0.05, # Centered above the North pie domain (0 to 0.45)
            y = 1.20,
            xref = "paper", yref = "paper",
            font = list(size = 16, face = "bold")
          ),
          list(
            text = "<b>South</b>", showarrow = FALSE,
            x = 0.78,           # Centered above the South pie domain (0.55 to 1)        
            y = 1.20, xref = "paper", yref = "paper",
            font = list(size = 16, face = "bold")
          )
        )
      )
   
    
  })
  
}

# RUN APPLICATION ----------------------------------------------------------
shinyApp(ui = ui, server = server)

