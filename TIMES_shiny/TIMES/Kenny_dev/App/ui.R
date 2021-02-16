# Load libraries
library(shiny)
library(shinyBS)
library(shinythemes)
library(highcharter)
library(dplyr)
library(readr)
library(stringr)
library(stringi) # Only used for the placeholder text (i.e. stri_rand_lipsum()). Can be removed later.
library(shinyWidgets) # For the fancy radio buttons


# Source script that loads data
## This is where the .rda file is loaded (and where the hierarchy dataframe is created)
source("data/load_data.R")
source("funtions.R")

# Start of the user interface code
ui <- navbarPage(
  
  title = "EECA",
  
  theme = shinytheme("lumen"),
  
  # Background tab
  tabPanel(
    
    "Background",
    
    fluidRow(
      
      column(
        width = 12,
        h2("Background"),
        paste(stri_rand_lipsum(2), collapse = "\n")
      )
      
    ),
    
    fluidRow(
      
      column(
        width = 12,
        h2("Assumptions"),
        paste(stri_rand_lipsum(1), collapse = "\n"),
        
        fluidRow(
          
          column(
            
            width = 12,
            
            HTML("<br>"),
            
            # This is the switch for showing/not showing the assumptions plot. Defaults to FALSE.
            helpText("Show assumptions"),
            prettySwitch("showAssumptions", "", value = FALSE, status = "success"),
            
            # This next panel only shows when the showAssumptions switch is clicked (i.e. it becomes TRUE)
            conditionalPanel(
              
              # This is the condition that must be satisfied for this panel to be shown. 1 is the same as TRUE in this case.
              condition = "input.showAssumptions == 1",
              
              # Below here is what gets shown when the condition is met.
              
              selectInput("assumptions", "", choices = assumptions_list),
              # radioButtons("chart_type_assumptions", "", choices = c("line", "column", "area"), inline = TRUE),
              
              # These are the chart type buttons.You can search the different icons on this website: https://fontawesome.com/v4.7.0/icons/
              column(
                width = 3,
                radioButtons("chart_type_assumptions", "", choices = c("line", "column", "area", "column_percent"), inline = TRUE)
                # radioGroupButtons(
                #   inputId = "chart_type_assumptions",
                #   label = "",
                #   choices = c(
                #     `<i class='fa fa-line-chart'></i>` = "line",
                #     `<i class='fa fa-bar-chart'></i>` = "column",
                #     `<i class='fa fa-area-chart'></i>` = "area",
                #     `<i class='fa fa-percent'></i>` = "column_percent"
                #   )
                # )
              )
              
              ,
              
              # Assumptions plot output
              highchartOutput("assumptions_plot")
              
            )
          )
        )
        
      )
    )
  ),
  
  # Data Explorer tab
  tabPanel(
    
    "Data Explorer",
    
    # The sidebarLayout is a specific built-in layout type which takes two arguments: a sidebarPanel and a mainPanel.
    sidebarLayout(
      
      sidebarPanel = sidebarPanel(
        
        width = 3,
        
        # This is where the drop downs are inserted in to the UI. They are created dynamically on the server side.
        uiOutput("drop_downs")
        
      ),
      
      mainPanel = mainPanel(
        
        tabsetPanel(
          
          id = "tabs", # This is needed so that we can reference when someone clicks a tab
          
          # type = "pills",
          
          tabPanel(
            
            "Overview",
            
            value = "Overview", # This is the value (of input$tabs) returned when the user clicks the 'Overview' tab
            
            fluidRow(
              
              # Again, these are the chart type buttons. Have turned off the percent button here as it doesn't make sense for how it is currently set up
              column(
                width = 3,
                # radioButtons("chart_type_assumptions", "", choices = c("line", "column", "area"), inline = TRUE)
                radioGroupButtons(
                  inputId = "chart_type_overview",
                  label = "",
                  choices = c(
                    `<i class="fa fa-line-chart" aria-hidden="true"></i>` = "line",
                    `<i class='fa fa-bar-chart'></i>` = "column",
                    `<i class='fa fa-area-chart'></i>` = "area"#,
                    # `<i class='fa fa-percent'></i>` = "column_percent"
                  )
                )
              ),
              
              # Plot outputs
              column(
                
                width = 12,
                
                h3("Kea"),
                
                highchartOutput("overview_kea")
                
              ),
              
              column(
                
                width = 12,
                
                h3("Tui"),
                
                highchartOutput("overview_tui")
                
              )
              
            )
          ),
          
          tabPanel(
            
            "Transport",
            
            value = "Transport",
            
            fluidRow(
              
              column(
                
                width = 12,
                
                h3("Kea"),
                
                highchartOutput("transport_kea")
                
              ),
              
              column(
                
                width = 12,
                
                h3("Tui"),
                
                highchartOutput("transport_tui")
                
              )
              
            )
          ),
          
          tabPanel(
            
            "Industry",
            
            value = "Industry"
            
          ),
          
          tabPanel("Residential"),
          
          tabPanel(
            
            "Emissions",
            
            value = "Emissions"
            
          )
          
        )
        
      )
      
    )
    
  ),
  
  # These are CSS files that are needed for displaying the fontawesome icons
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "font-awesome-5.3.1/css/all.min.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "font-awesome-5.3.1/css/v4-shims.min.css")
  )
  
)