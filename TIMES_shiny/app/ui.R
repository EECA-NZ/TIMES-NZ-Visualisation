# Load libraries
# These are the libraries needed for the App. 
# All the these libraries and depended packages are archived in the environment
# To restore the the archived libraries one needs to run the line below
#  renv::restore()


library(shiny)
library(shinyBS)
library(bslib)
library(shinythemes)
library(shinyBS)
library(highcharter)
library(tidyverse)
library(readr)
library(stringr)
library(shinyWidgets) # For the fancy radio buttons
library(shinyhelper)
library(rintrojs) # Needed for the introductory tour
library(shinyjs)

# Source script that loads data
# This is where the .rda file is loaded and the hierarchy dataframe is created
source("data/load_data.R")


# Load the plot functions and the helper functions
source("functions.R")



# Start of the user interface code
ui <- navbarPage(
  
  # Page title. Currently set to black since it is not needed
  title = "",
  

  # USing the readable theme
  theme = shinytheme("readable"),
  
  #########################################
  ############# Background tab ############
  #########################################
  tabPanel(
    
    # Title of the tab
    "Overview",
    
    # Defining the background content
    fluidRow(
      
      column(
        
        width = 12,
        
        h3("TIMES-NZ 2.0 Energy System Scenarios "),
        
        # The background text
        HTML("The TIMES-NZ 2.0 New Zealand Energy System Scenarios website 
              presents model insights outputs and assumptions for the latest 
              TIMES-NZ scenarios. TIMES-NZ 2.0 has been developed by <a href='https://www.eeca.govt.nz/'>EECA</a>  in 
              partnership with the <a href='https://www.bec.org.nz/'>Business Energy Council New Zealand</a>  and The 
              <a href='https://www.psi.ch/en'>Paul Scherrer Institut</a>. There are two scenarios Kea (Cohesive) and 
              Tui(Individualistic) in TIMES-NZ 2.0 . " ),
              

        
        # Adding the introduction tour button 
        HTML("<br><br>"),
        
        div(
          actionButton(inputId = "intro", 
                       
                       label = HTML("Click here for a quick introduction tour"),
                       
                       icon = icon("info-circle")),

                        align = "center")

      )),
    
    
    # Adding the Energy System Scenarios row
    fluidRow(
      
      column(
        
        width = 12,
        
        h3("Scenarios"),
        
        # Adding Kea and Tui comment 
        HTML("<div class='wrapper'>
                
        <div class='box a'><strong>Kea </strong>represents a scenario where 
        climate change is prioritised as the most pressing issue and New Zealand 
        deliberately pursues cohesive ways to achieve a low-emissions economy.</div>
       
        
        <div class='box b'><strong>Tui </strong>represents a scenario where 
        climate change is an important issue to be addressed as one of many 
        priorities.  </div>
        </div>"
     
             
        )
      )
      
      
    ),
    
    
    # Adding the Assumption and Key insight plots
    fluidRow(
      
      column(
        
        width = 12,

        HTML("<br><br><br>"),
        
        # Adding a sidebar for selection
        sidebarLayout(
          
          sidebarPanel = sidebarPanel(
            
            width = 3,
            
            # Adding switch button
            # Adding an introduction tour
            introBox(data.step = 1, data.intro = intro$text[1],
                     
                     # Used spa to add tooltip info
                     span(switchButton(inputId = "Insght_Switch",
                                       
                                       label = NULL, 
                                       
                                       value = TRUE, col = "RG", type = "OO"),
                          
                          
                          # Tooltip info 
                          title="Switch to show Key Insight or Assumptions")),
            
            
            # Adding the dropbox 
            span(uiOutput("Assumption_drop_downs"), 
                 
                 title="Dropdown for selecting Parameter")
            
          ),
          
          # Adding the key insight and assumtption plot 
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
  
  
  #########################################
  ########## Data Explorer tab ############
  #########################################
  tabPanel(
    
    "Data Explorer",
    
    # The sidebarLayout is a specific built-in layout type which takes 
    # two arguments: a sidebarPanel and a mainPanel.
    
    
    sidebarLayout(
      
      # Creating the chart type selection
      sidebarPanel = sidebarPanel(
        
        width = 3,
        
        introBox(data.step = 2, data.intro = intro$text[2],
                 
                 uiOutput("radioGroup")
                 
          ),
        
        
        
        # Adding tech and fuel switch
        span(switchButton(inputId = "Tech_Fuel_Switch",

                          label = NULL,

                          value = TRUE, col = "RG", type = "YN"),
             
             # uiOutput("switch"),

             title="Toggle to show fuels grouped by either Renewables
                            and Fossil Fuels, or all fuels separately displayed
                            (eg, Electricity, Coal, Solar etc)"
        ),
        # 
        # # Adding intro-tour for fuel switch
        # introBox(data.step = 3, data.intro = intro$text[3],
        #          
        #          # Adding group fuel and fuel switch 
        #          span(switchButton(inputId = "Fuel_Switch",
        #                            
        #                            label = NULL, 
        #                            
        #                            value = TRUE, col = "RG", type = "TF"),
        #               
        #               title="Toggle to show fuels grouped by either Renewables 
        #                     and Fossil Fuels, or all fuels separately displayed 
        #                     (eg, Electricity, Coal, Solar etc)"
        #          )),
        
        
        
        uiOutput("plot_by_dropdowns"),
        
        

        # Intro-tour for drilldowns
        introBox(data.step = 4, data.intro = intro$text[4],
                 
                 # This is where the drop downs are inserted in to the UI. 
                 # They are created dynamically on the server side.  
                 # The metric dropdown is added separately 
                 uiOutput("drop_downs")),
        
        
        # Intro-tour for Metric
        introBox(data.step = 5, data.intro = intro$text[5],
                 
                 # Adding the metric dropdown
                 selectInput(
                   
                   "unit",
                   
                   label = NULL,
                   
                   choices = unique(sort(hierarchy$Parameters))
                   
                 ))
        

        
      ),
      
      # Adding the Sector tabs
      mainPanel = mainPanel(
        
        width = 9,
        
        introBox(data.step = 6, data.intro = intro$text[6],
                 
                 tabsetPanel(
                   
                   # This is needed so that we can reference when someone clicks a tab
                   id = "tabs", 
                   
                   type = "pills",
                   
                   # Adding All Sector tab
                   tabPanel(
                     
                     "All Sectors",
                     
                     # This is the value (of input$tabs) returned when the user 
                     # clicks the 'Overview' tab
                     value = "Overview", 
                     
                     fluidRow(
                       

                       
                       # Plot outputs
                       column(
                         
                         width = 12,
                         
                         h3("Kea", uiOutput("info_overview", inline = TRUE)),

                         
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
  
  
  ##############################
  ######### About tab ##########
  ##############################
  
  # Adding the About Tab 
  tabPanel(
    
    # For some reason the title doesn't like the name "About".
    # "About " was used to get around this 
    title = "About ",
    
    # icon = icon("info"),
    
    fluidRow(
      
      column(
        
        width = 12,
        
        h3("About"),
        
        # includeHTML("intro_text.html"),
        
        paste("Welcome to the TIMES-NZ 2.0 website. This site presents the key model outputs and assumptions for the latest TIMES-NZ scenarios.
                   The TIMES-NZ project grew out of BEC2060, an exploration of possible energy futures based on contrasted scenarios.",
              "The latest iteration of TIMES-NZ builds on the BEC2060 work, and has been developed in partnership between EECA, BEC and PSI adding more detail and 
                   sophistication to sectors, subsectors, technologies and end uses. In particular, the 2020 update of EECA’s Energy End Use Database provides a greatly improved input dataset.
                   There are two scenarios <insert scenario names here> in TIMES-NZ 2.0.  The scenarios are modelled using an integrated energy-systems model known which is based on the IEA ETSAP TIMES model.  
                   The TIMES-NZ model simultaneously represents all components of the energy system, ensuring any interdependencies are reflected. 
                   TIMES is a bottom-up, technology based system model that selects from available technologies to produce a least-cost energy system, optimised according to input constraints over the medium to long-term.
                   Other forecast inputs come from a variety of reputable sources (MoT, MBIE, MfE, MPI)– including transport outlook scenarios for projections of the need for passenger and freight transport, 
                   sub-sectoral GDP forecasts for future service demand from the commercial, agriculture and industrial sectors, and population to form the basis of the residential service demand projections.
                   These results provide some insight into our future energy system, we hope you find them useful."
              , collapse = "\n"),
        HTML("<br><br>"),
        
        
        # Embedding  video into the App
        div(
        HTML('<iframe class="frame-boader" width="540" height="304" src="https://www.youtube.com/embed/onCzuMmZZuY" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>'),
        HTML('<iframe class="frame-boader" width="540" height="304" src="https://www.youtube.com/embed/HYS-0L7mods" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>'),
        align = "center"),
        
        
        # Embedding colapsing tabs
        # div( HTML(' <div class="page-width accordion-wrapper">
        #   <div class="accordion wide">
        #   <button id="accHeading2145" aria-controls="accToggle2145" class="js-trigger accordion-trigger" aria-expanded="false">Heavy transport</button>
        #   
        #   <div id="accToggle2145" class="js-toggle accordion-toggle typography" aria-expanded="false" aria-hidden="true" aria-labelledby="accHeading2145">
        #   <p>Similarly to the light fleet, conventional biofuels can be a short-term quick win for the existing truck fleet.</p><p>At the horizon of drop-in biofuel potential uptake (2035-2040), our view is that heavy electric vehicles (HEV) will present a better total cost of ownership (TCO). The largest cost component of HEVs is the large battery required. With declining prices of Li-Ion batteries, <a rel="noreferrer external" class="external" rel="external" title="Open external link" href="https://about.bnef.com/blog/behind-scenes-take-lithium-ion-battery-prices/" target="_blank">this will become less of an issue by 2035<span class="nonvisual-indicator">(external link)</span></a>. EVs have the benefit of lower fuel costs than diesel/Biofuel vehicles, which will allow for cost competitiveness or benefits from a TCO perspective.</p>
        #   </div>
        #   </div>
        #   </div>'))
      ))
    
    
  ),
  
  
  
  
  # These are CSS files that are needed for displaying the fontawesome icons
  header = tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "font-awesome-5.3.1/css/all.min.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "font-awesome-5.3.1/css/v4-shims.min.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "css/styles.css"),
    tags$script(type = "text/javascript", "$(function () {$('[data-toggle=\"popover\"]').popover()})")
  ),
  
  # Adding the Footer to the App
  footer = tags$footer(
                      # Image
                      img(src="img/EECA_BEC.svg",
                          
                       height = 120, 
                       
                       width = 660),
                      
                       align = "center",
                      
                       style = "
                            position: absolute;
                            width:100%;
                            padding: 80px;"
                            ),
  
                collapsible =FALSE
  
)