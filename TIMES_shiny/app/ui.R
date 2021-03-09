# Load libraries
library(shiny)
library(shinyBS)
library(bslib)
library(shinythemes)
library(highcharter)
library(tidyverse)
library(readr)
library(stringr)
library(stringi) # Only used for the placeholder text (i.e. stri_rand_lipsum()). Can be removed later.
library(shinyWidgets) # For the fancy radio buttons
library(shinyhelper)


# Source script that loads data
## This is where the .rda file is loaded (and where the hierarchy dataframe is created)
source("data/load_data.R")
# Load the plot functions 
source("functions.R")

# Start of the user interface code
ui <- navbarPage(
  
  title = "",
  # title = "EECA",
  # theme = bs_theme(version = 4, bootswatch = "litera"),
  theme = shinytheme("readable"),
  
  # Background tab
  tabPanel(
    
    "Background",
    
    conditionalPanel(
      
      condition = "input.showAssumptions == 0",
      
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
          paste(stri_rand_lipsum(1), collapse = "\n")
        )
        
      )
      
    ),
    
    fluidRow(
      
      column(
        
        width = 12,
        
        HTML("<br>"),
        
        # This is the switch for showing/not showing the assumptions plot. Defaults to FALSE.
        conditionalPanel(condition = "input.showAssumptions == 0", helpText("Show assumptions")),
        conditionalPanel(condition = "input.showAssumptions == 1", helpText("Hide assumptions")),
        prettySwitch("showAssumptions", "", value = FALSE, status = "success"),
        
        # This next panel only shows when the showAssumptions switch is clicked (i.e. it becomes TRUE)
        conditionalPanel(
          
          # This is the condition that must be satisfied for this panel to be shown. 1 is the same as TRUE in this case.
          condition = "input.showAssumptions == 1",
          
          # Below here is what gets shown when the condition is met.
          
          sidebarLayout(
            
            sidebarPanel = sidebarPanel(
              
              width = 3,
              
              radioGroupButtons(
                inputId = "chart_type_assumptions",
                label = NULL,
                individual = TRUE,
                choices = c(
                  `<i class='fa fa-line-chart'></i>` = "line",
                  `<i class='fa fa-bar-chart'></i>` = "column",
                  `<i class='fa fa-area-chart'></i>` = "area",
                  `<i class='fa fa-percent'></i>` = "column_percent"
                )
              ),
              
              selectInput("assumptions", label = NULL, choices = assumptions_list)
            ),
            
            mainPanel = mainPanel(
              
              width = 8,
              
              fluidRow(
                
                column(
                  
                  width = 12,
                  
                  highchartOutput("assumptions_plot") 
                  
                )
              )
            )
          )#,
          
          # fluidRow(
          #   column(
          #     width = 9,
          #     # offset = 1,
          #     # Assumptions plot output
          #     highchartOutput("assumptions_plot")
          #   )
          # )
          
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
        
        radioGroupButtons(
          inputId = "chart_type",
          label = NULL,
          individual = TRUE,
          choices = c(
            `<i class="fa fa-line-chart" aria-hidden="true"></i>` = "line",
            `<i class='fa fa-bar-chart'></i>` = "column",
            `<i class='fa fa-area-chart'></i>` = "area" ,
            `<i class='fa fa-percent'></i>` = "column_percent"
          )
        ),
        
        # This is where the drop downs are inserted in to the UI. They are created dynamically on the server side.
        uiOutput("drop_downs"),
        
        selectInput(
          "unit",
          label = NULL,
          choices = unique(sort(hierarchy$Parameters))
        )
        
      ),
      
      mainPanel = mainPanel(
        
        tabsetPanel(
          
          id = "tabs", # This is needed so that we can reference when someone clicks a tab
          
          type = "pills",
          
          tabPanel(
            
            "Overview",
            
            value = "Overview", # This is the value (of input$tabs) returned when the user clicks the 'Overview' tab
            
            fluidRow(
              
              # Again, these are the chart type buttons. Have turned off the percent button here as it doesn't make sense for how it is currently set up
              # column(
              #   width = 4,
              #   # radioButtons("chart_type_assumptions", "", choices = c("line", "column", "area", "column_percent"), inline = TRUE)
              #   # radioGroupButtons(
              #   #   inputId = "chart_type_overview",
              #   #   label = "",
              #   #   individual = TRUE,
              #   #   choices = c(
              #   #     `<i class="fa fa-line-chart" aria-hidden="true"></i>` = "line",
              #   #     `<i class='fa fa-bar-chart'></i>` = "column",
              #   #     `<i class='fa fa-area-chart'></i>` = "area" ,
              #   #     `<i class='fa fa-percent'></i>` = "column_percent"
              #   #   )
              #   # )
              # ),
              
              # Plot outputs
              column(
                
                width = 12,
                
                h3("Kea") %>% 
                  helper(
                    type = "inline",
                    title = "Kea scenario - overview",
                    content = c("Draft commentary: The Kea scenario shows that petrol has high consumption until 2035 at which point in sharply decreases due to XXXXXXXX.  Whereas in the Tui scenario the decrease happens at the same time yet is not as aggressive.  In Tui there is also a slight update of LPG due to #### being constrained."
                    ),
                    size = "m",
                    colour = "#3C4C49"
                  ),
                
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
              
              # Plot outputs
              column(
                
                width = 12,
                
                h3("Kea") ,
                
                highchartOutput("transport_kea")
                
              ),
              
              column(
                
                width = 12,
                
                h3("Tui"),
                
                highchartOutput("transport_tui")
              )
            )
            
            
          ),
          
          
          
          
          # Adding industry stuff
          tabPanel(
            
            "Industry",
            
            value = "Industry",
            
            fluidRow(
              
              # Plot outputs
              column(
                
                width = 12,
                
                h3("Kea"),
                
                highchartOutput("industry_kea")
                
              ),
              
              column(
                
                width = 12,
                
                h3("Tui"),
                
                highchartOutput("industry_tui")
              )
            )
            
            
          )
          
          # ,
          # 
          # 
          # # Adding Commercial stuff
          # tabPanel(
          #   
          #   "Commercial",
          #   
          #   value = "Commercial"
          #   
          # ),
          # 
          # 
          # # Adding Residential stuff
          # tabPanel(
          #   "Residential",
          #   
          #   value = "Residential" ),
          # 
          # # Adding Agriculture stuff
          # tabPanel(
          #   "Agriculture",
          #   
          #   value = "Agriculture" ),
          # 
          # 
          # # Adding Other stuff
          # tabPanel(
          #   
          #   "Other",
          #   
          #   value = "Other"
          #   
          # )
          # 
        )
        
      )
      
    )
    
  ),  
  
  
  
  
  # These are CSS files that are needed for displaying the fontawesome icons
  header = tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "font-awesome-5.3.1/css/all.min.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "font-awesome-5.3.1/css/v4-shims.min.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "css/styles.css")
  )
  
)