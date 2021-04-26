# Load libraries
library(shiny)
library(shinyBS)
library(bslib)
library(shinythemes)
library(shinyBS)
library(highcharter)
library(tidyverse)
library(readr)
library(stringr)
library(stringi) # Only used for the placeholder text (i.e. stri_rand_lipsum()). Can be removed later.
library(shinyWidgets) # For the fancy radio buttons
library(shinyhelper)
library(rintrojs) # Needed for the introductory tour

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
    
    "Overview",
      
      fluidRow(
        
        column(
          width = 12,
          h3("Background"),
          paste("Welcome to the TIMES-NZ 2.0 website. This site presents the key model outputs and assumptions for the latest TIMES-NZ scenarios. 
                The TIMES-NZ project grew out of BEC2060, an exploration of possible energy futures based on contrasted scenarios.",
                "The latest iteration of TIMES-NZ builds on the BEC2060 work, and has been developed in partnership between EECA, BEC and PSI adding more detail and sophistication to sectors, subsectors, technologies and end uses. 
                In particular, the 2020 update of EECA’s Energy End Use Database provides a greatly improved input dataset. 
                There are two scenarios <insert scenario names here> in TIMES-NZ 2.0.  
                The scenarios are modelled using an integrated energy-systems model known which is based on the IEA ETSAP TIMES model.  
                The TIMES-NZ model simultaneously represents all components of the energy system, ensuring any interdependencies are reflected.
                ." 
                , collapse = "\n"),
          HTML("<br><br>"),
          actionButton(inputId = "intro", 
                       label = HTML("Click here for a quick introduction tour"))
                       # icon = icon("info-circle")
                       # id = "actionButton btn-lg")
          # align = "center"
        )
        
      ),
      
      fluidRow(
        
        column(
          width = 12,
          h3("TIMES-NZ 2.0 Energy System Scenarios"),
          # Adding Kea and Tui comment 
          HTML("<div class='wrapper'>
                
                <div class='box a'><strong>Kea </strong>represents a future in which climate change is seen as the most pressing issue. 
                A broad economic transformation is pursued by New Zealand society and government, 
                deliberately choosing to be a global leader in the pursuit of a low-emissions society.</div>
               
                
                <div class='box b'><strong>Tui </strong>represents a future in which global communities,
                businesses and governments believe that climate change is only one of several competing priorities.</div>
                </div>"

          
          )
        )
        
      # )
      
    ),
    
    fluidRow(
      
      column(
        
        width = 12,
        # offset = 1, # centering the plot
        
        
        
        
        HTML("<br><br><br>"),
# 
#         # This is the switch for showing/not showing the assumptions plot. Defaults to FALSE.
#         conditionalPanel(condition = "input.showAssumptions == 0", helpText("Show assumptions")),
#         conditionalPanel(condition = "input.showAssumptions == 1", helpText("Hide assumptions")),
#         prettySwitch("showAssumptions", "", value = FALSE, status = "success"),
# 
#         # This next panel only shows when the showAssumptions switch is clicked (i.e. it becomes TRUE)
#         conditionalPanel(
# 
#           # This is the condition that must be satisfied for this panel to be shown. 1 is the same as TRUE in this case.
#           condition = "input.showAssumptions == 1",
# 
#           # Below here is what gets shown when the condition is met.

          sidebarLayout(
            
            sidebarPanel = sidebarPanel(
              
              width = 3,
              
              # radioGroupButtons(
              #   inputId = "chart_type_assumptions",
              #   label = NULL,
              #   individual = TRUE,
              #   choices = c(
              #     `<i class='fa fa-line-chart'></i>` = "line",
              #     `<i class='fa fa-bar-chart'></i>` = "column",
              #     `<i class='fa fa-area-chart'></i>` = "area",
              #     `<i class='fa fa-percent'></i>` = "column_percent"
              #   )
              # ),
              # Adding switch 
              # Adding an introduction tour
              introBox(data.step = 1, data.intro = intro$text[1],
              span(switchButton(inputId = "Insght_Switch",
                                label = NULL, 
                                value = TRUE, col = "RG", type = "OO"),
                   title="Switch to show Key Insight or Assumptions")),
              
              
              span(uiOutput("Assumption_drop_downs"), 
                   title="Dropdown for selecting Parameter")
              # conditionalPanel(condition = "input$Insght_Switch == 'NO'", 
              #                  selectInput("assumptions", label = NULL, 
              #                              choices = assumptions_list)),
              # conditionalPanel(condition = "input$Insght_Switch == 'OFF'", 
              #                  selectInput("insight", label = NULL, 
              #                              choices = insight_list))

            ),
            
            mainPanel = mainPanel(
              
              width = 9,
              
              fluidRow(
                
                column(
                  
                  width = 12,
                  
                  highchartOutput("assumptions_plot",height = 500)
                  
                      
                    )
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
        introBox(data.step = 2, data.intro = intro$text[2],
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
        )),
        
        # Intro for fuel switch
        introBox(data.step = 3, data.intro = intro$text[1],
        # Adding switch 
        span(switchButton(inputId = "Fuel_Switch",
                     label = NULL, 
                     value = TRUE, col = "RG", type = "TF"),
                     title="Toggle to show fuels grouped by either Renewables and Fossil Fuels, or all fuels separately displayed (eg, Electricity, Coal, Solar etc)"
             )),
        
        # Intro for drilldowns
        introBox(data.step = 4, data.intro = intro$text[4],
         
        # This is where the drop downs are inserted in to the UI. They are created dynamically on the server side.       
        uiOutput("drop_downs")),
        
        
        # Intro for Metric
        introBox(data.step = 5, data.intro = intro$text[5],
        selectInput(
          "unit",
          label = NULL,
          choices = unique(sort(hierarchy$Parameters))
        )),

      ),
      
      mainPanel = mainPanel(
        
        introBox(data.step = 6, data.intro = intro$text[6],
        
        tabsetPanel(
          
          id = "tabs", # This is needed so that we can reference when someone clicks a tab
          
          type = "pills",
          
          tabPanel(
            
            "All Sectors",
            
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
                
                # h3("Kea",hover_popup(text = textOutput("assumptions_popup", inline = TRUE), icon_type = "fa-info-circle")),
                # h3(textOutput("caption"))
                
                # h3("Kea", hover_popup(text = "The Kea scenario shows that petrol has high consumption until 2035 at which point in sharply decreases due to XXXXXXXX.",
                #                       icon_type = "fa-info-circle")),
                h3("Kea", uiOutput("info_overview", inline = TRUE)),
                # %>% 
                #   helper(
                #     type = "inline",
                #     title = "Kea scenario - overview",
                #     content = c("Draft commentary: The Kea scenario shows that petrol has high consumption until 2035 at which point in sharply decreases due to XXXXXXXX.  Whereas in the Tui scenario the decrease happens at the same time yet is not as aggressive.  In Tui there is also a slight update of LPG due to #### being constrained."
                #     ),
                #     size = "m",
                #     colour = "#3C4C49"
                #   ),
                
                highchartOutput("overview_kea") 
                
              ),
              
              column(
                
                width = 12,
                
                h3("Tui", ),
                
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
                
                h3("Kea", uiOutput("info_transport", inline = TRUE)),
                
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
            
            "Industrial",
            
            value = "Industry",
            
            fluidRow(
              
              # Plot outputs
              column(
                
                width = 12,
                
                h3("Kea", uiOutput("info_industry", inline = TRUE)),
                
                highchartOutput("industry_kea")
                
              ),
              
              column(
                
                width = 12,
                
                h3("Tui"),
                
                highchartOutput("industry_tui")
              )
            )
            
            
          ),
          
          
          # Adding Commercial stuff
          tabPanel(
            
            "Commercial",
            
            value = "Commercial",
            
            fluidRow(
              
              # Plot outputs
              column(
                
                width = 12,
                
                h3("Kea", uiOutput("info_commercial", inline = TRUE)),
                
                highchartOutput("Commercial_kea")
                
              ),
              
              column(
                
                width = 12,
                
                h3("Tui"),
                
                highchartOutput("Commercial_tui")
              )
            )
            
            
            
          ),
          
          # Adding Residential stuff
          tabPanel(
            "Residential",
            
            value = "Residential",
            
            fluidRow(
              
              # Plot outputs
              column(
                
                width = 12,
                
                h3("Kea", uiOutput("info_residential", inline = TRUE)),
                
                highchartOutput("Residential_kea")
                
              ),
              
              column(
                
                width = 12,
                
                h3("Tui"),
                
                highchartOutput("Residential_tui")
              )
            )
            
          ),
          
          # Adding Agriculture stuff
          tabPanel(span("Agriculture", title="Agriculture, Forestry and Fishing"),
            # "Agriculture, Forestry and Fishing",
            # bsTooltip("Agriculture", "The wait times will be broken into this many equally spaced bins",
            #           "right"),
            value = "Agriculture",
          
            fluidRow(
              
              # Plot outputs
              column(
                
                width = 12,
                
                h3("Kea", uiOutput("info_agriculture", inline = TRUE)),
                
                highchartOutput("Agriculture_kea")
                
              ),
              
              column(
                
                width = 12,
                
                h3("Tui"),
                
                highchartOutput("Agriculture_tui")
              )
            )
            
          ),
          
          
          # Adding Other stuff
          tabPanel(
            span("Electricity", title = "Electricity Generation"),
            # "Electricity Generation",
            
            value = "Other",
            
            fluidRow(
              
              # Plot outputs
              column(
                
                width = 12,
                
                h3("Kea", uiOutput("info_other", inline = TRUE)),
                
                highchartOutput("Other_kea")
                
              ),
              
              column(
                
                width = 12,
                
                h3("Tui"),
                
                highchartOutput("Other_tui")
              )
            )
            
          )
          
        ))
        
      )
      
    ),
    # This initiates the introjs functionality
    introjsUI(),
    
  ),  

# About tab
tabPanel(title =  "About",

    # column(width = 12,
    #        HTML("<br><br><br><br>"),
    #        h3("Background"),
    #        
    #   # includeHTML("intro_text.html"),
    #   paste("Welcome to the TIMES-NZ 2.0 website. This site presents the key model outputs and assumptions for the latest TIMES-NZ scenarios.
    #         The TIMES-NZ project grew out of BEC2060, an exploration of possible energy futures based on contrasted scenarios.",
    #         "The latest iteration of TIMES-NZ builds on the BEC2060 work, and has been developed in partnership between EECA, BEC and PSI adding more detail and 
    #         sophistication to sectors, subsectors, technologies and end uses. In particular, the 2020 update of EECA’s Energy End Use Database provides a greatly improved input dataset.
    #         There are two scenarios <insert scenario names here> in TIMES-NZ 2.0.  The scenarios are modelled using an integrated energy-systems model known which is based on the IEA ETSAP TIMES model.  
    #         The TIMES-NZ model simultaneously represents all components of the energy system, ensuring any interdependencies are reflected. 
    #         TIMES is a bottom-up, technology based system model that selects from available technologies to produce a least-cost energy system, optimised according to input constraints over the medium to long-term.
    #         Other forecast inputs come from a variety of reputable sources (MoT, MBIE, MfE, MPI)– including transport outlook scenarios for projections of the need for passenger and freight transport, 
    #         sub-sectoral GDP forecasts for future service demand from the commercial, agriculture and industrial sectors, and population to form the basis of the residential service demand projections.
    #         These results provide some insight into our future energy system, we hope you find them useful."
    #         , collapse = "\n")
    # )
  
    
  
  
  # fluidRow(
  #   
  #   column(
  #     width = 9,
  #     h3("Background"),
  #     paste("Welcome to the TIMES-NZ 2.0 website. This site presents the key model outputs and assumptions for the latest TIMES-NZ scenarios. 
  #               The TIMES-NZ project grew out of BEC2060, an exploration of possible energy futures based on contrasted scenarios.",
  #           "The latest iteration of TIMES-NZ builds on the BEC2060 work, and has been developed in partnership between EECA, BEC and PSI adding more detail and sophistication to sectors, subsectors, technologies and end uses. In particular, the 2020 update of EECA’s Energy End Use Database provides a greatly improved input dataset. 
  #               There are two scenarios <insert scenario names here> in TIMES-NZ 2.0.  The scenarios are modelled using an integrated energy-systems model known which is based on the IEA ETSAP TIMES model.  The TIMES-NZ model simultaneously represents all components of the energy system, ensuring any interdependencies are reflected. TIMES is a bottom-up, technology based system model that selects from available technologies to produce a least-cost energy system, optimised according to input constraints over the medium to long-term. 
  #               Other forecast inputs come from a variety of reputable sources (MoT, MBIE, MfE, MPI)– including transport outlook scenarios for projections of the need for passenger and freight transport, sub-sectoral GDP forecasts for future service demand from the commercial, agriculture and industrial sectors, and population to form the basis of the residential service demand projections.
  #               These results provide some insight into our future energy system, we hope you find them useful." 
  #           , collapse = "\n")
  #   )
  #   
  # )
  
  ),
  
  

  
  # These are CSS files that are needed for displaying the fontawesome icons
  header = tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "font-awesome-5.3.1/css/all.min.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "font-awesome-5.3.1/css/v4-shims.min.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "css/styles.css"),
    tags$script(type = "text/javascript", "$(function () {$('[data-toggle=\"popover\"]').popover()})")
  ),
  footer = tags$footer(img(src="img/EECA_BEC.svg", height = 120, width = 660),
  align = "center",
  style = "
  position: absolute;
  width:100%;
  padding: 80px;"
    ),
  collapsible =FALSE
  
)