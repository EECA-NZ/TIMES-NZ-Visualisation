library(shiny)
library(shinycssloaders)
library(shinythemes)
library(DT)
library(ggplot2)
library(ggiraph)
library(scales)

start_measure <- "Emissions"

ui <- fluidPage(theme = shinytheme("cerulean"), id = "pageOuter",
                
                tags$head(
                  tags$link(rel = "stylesheet", type = "text/css", href = "https://www.bec2060.org.nz/designs/css/bec-shiny.css"),
                  tags$link(rel = "shortcut icon", href = "https://www.bec2060.org.nz/__data/assets/file/0016/141082/favicon.ico"),
                  tags$script(src="https://www.bec2060.org.nz/__data/assets/js_file/0011/177869/bec-shiny.js"),
                  tags$title("Modelling - BEC2060")
                ),
                
                fluidRow(HTML(paste('
          <div class="bec2060-breadcrumb"><a href="https://www.bec2060.org.nz" target="_blank">Back to BEC2060 Website</a></div>
          <div class="head-logo parallax-wrapper">
            <div class="col-12 logo d-flex justify-content-center parallax-outer">
                <div class="header-mountain parallax" data-speed="70"></div>
                <div class="main-logo-banner parallax" data-speed="50">
                    <h2>NEW ZEALAND ENERGY SCENARIOS</h2>
                    <p>Navigating our flight path to 2060</p>
                </div>
                <div class="header-forest-two parallax" data-speed="50"></div>
                <div class="header-forest parallax" data-speed="40"></div>
                <div class="header-tui parallax" data-speed="30"><img src="https://www.bec2060.org.nz/__data/assets/image/0009/178083/Tui.png"></div>
                <div class="header-kea parallax" data-speed="30"><img src="https://www.bec2060.org.nz/__data/assets/image/0008/178082/Kea.png"></div>
            </div>
        </div>
        '))),
                navbarPage(title = "",
                           id = "nav_bar_id",
                           tabPanel("Intro",
                                    fluidRow(
                                      HTML(paste('<div class="col-xs-12">
	<h2 class="h2-heading">Exploring the BEC2060 scenarios</h2>
	<p>Welcome to the modelling outputs for each of the BEC2060 scenarios.</p>
	<p>The BEC2060 project used inputs from a variety of sources – using two of MoT’s transport outlook scenarios to form projections of the need for passenger and freight transport, using sub-sectoral GDP forecasts project the future service demand from the commercial, agriculture and industrial sector, and population to form the basis of the residential service demand projections.</p>
	<p>The scenarios are quantified using a model known as “TIMES”, an integrated energy-systems model, which simultaneously represents all components of the energy system, ensuring any interdependencies are reflected.</p>
	<p>TIMES is a technology rich, bottom-up model generator, which uses linear programming to produce a least-cost energy system, optimised according to a number of user-specified constraints, over the medium to long-term. It is used for the exploration of possible energy futures based on contrasted scenarios. <a href="https://www.bec2060.org.nz/data/method" target="_blank">Find out more here</a>.</p>
	<h2 class="h2-heading">The Scenarios</h2>
</div>
<div class="col-xs-12 col-md-6">
	<div class="kea">
		<p><strong>Kea </strong>represents a future in which climate change is seen as the most pressing issue. A broad economic transformation is pursued by New Zealand society and government, deliberately choosing to be a global leader in the pursuit of a low-emissions society.</p>
	</div>	
</div>
<div class="col-xs-12 col-md-6">
	<div class="tui">
		<p><strong>Tui </strong>represents a future in which global communities, businesses and governments believe that climate change is only one of several competing priorities.</p>
	</div>
</div>	

<div class="col-xs-12">
	<p>In this world, New Zealand takes a cautious approach to achieving emissions reductions, maintaining economic growth through market mechanisms, eschewing collective action while waiting to see how other countries proceed.</p>
	<p>For more information about the BEC2060 project, see the <a href="https://www.bec2060.org.nz" target="_blank"> BEC2060 website</a></p>
</div>
                            '))
                                      
                                    )
                           ), # close intro tab
                           
                           tabPanel("Assumptions",
                                    fluidRow(class="section-row",
                                             HTML(paste('<div class="col-xs-12 section-desc">
                                    	  <p><strong> Assumptions </strong> - view the key model input assumptions we used for each scenario.</p>
                                    	</div>'))
                                    ),
                                    fluidRow(
                                      column(width = 2,
                                             selectInput("ass_ass_select",
                                                         h5("Select Assumptions:"),
                                                         choices = assumptions_list,
                                                         selected = "Total GDP"),
                                      ), #close column
                                      column(width = 10,
                                             ggiraphOutput("assumptions_gplot")
                                      ) # close fluid page
                                    )
                           ), #close Assumptions tab
                           
                           tabPanel("Emissions", 
                                    fluidRow(class="section-row", 
                                             HTML(paste('<div class="col-xs-12 section-desc">
                                    	  <p><strong> Emissions </strong> - view how CO2 emissions change under each scenario, and see which fuels and sectors see the most significant changes.</p>
                                    	</div>'))
                                    ),
                                    fluidRow(
                                      column(width = 2,
                                             selectInput("emi_group_select",
                                                         h5("Show breakdown by:"),
                                                         choices = c("Fuel", "Sector"),
                                                         selected = "Sector")
                                      ), #close column
                                      column(width = 10,
                                             ggiraphOutput("emissions_plot")
                                      )
                                    )
                                    
                           ), #close emissions tab
                           
                           tabPanel("Energy Supply",
                                    fluidRow(class="section-row",
                                             HTML(paste('<div class="col-xs-12 section-desc">
                                    	  <p><strong> Energy Supply </strong> - discover where our energy is sourced from in each scenario.  We also show where this energy is "transformed" (e.g. into Electricity) before being used by consumers.</p>
                                    	</div>'))
                                    ),
                                    tabsetPanel(id = "nrg_supply_tabset",
                                                tabPanel("Primary Energy",
                                                         fluidRow(
                                                           ggiraphOutput("primary_gplot"))
                                                ),
                                                
                                                tabPanel("Net Imports",
                                                         fluidRow(
                                                           ggiraphOutput("imports_gplot"))
                                                ),
                                                
                                                tabPanel("Domestic Gas Production",
                                                         fluidRow(
                                                           ggiraphOutput("gasprod_gplot"))
                                                ),
                                                
                                                tabPanel("Electricity",
                                                         fluidRow(
                                                           column(width = 2,
                                                                  selectInput("sup_ele_gencap_select",
                                                                              h5("Show:"),
                                                                              choices = c("Generation in TWh", "Capacity in GW"),
                                                                              selected = "Generation in TWh")
                                                           ), #close column
                                                           column(width = 10,
                                                                  ggiraphOutput("electricity_plot")
                                                           )
                                                           
                                                         )
                                                ),
                                                
                                                tabPanel("Other Transformation",
                                                         fluidRow(
                                                           column(width = 2,
                                                                  selectInput("sup_oth_gas_select",
                                                                              h5("Show:"),
                                                                              choices = c("Natural Gas (CH4) from Biogas", "Hydrogen by Electrolysis"), # supplem_list
                                                                              selected = "Natural Gas (CH4) from Biogas")
                                                           ), #close column
                                                           column(width = 10,
                                                                  ggiraphOutput("supplem_plot")
                                                           )
                                                         )
                                                         
                                                ) # close sub tab
                                    )
                           ), # close energy supply tab
                           
                           tabPanel("Energy Use",
                                    fluidRow(class="section-row", 
                                             #htmlOutput("energy-use"), 
                                             HTML(paste('<div class="col-xs-12 section-desc">
                                    	  <p><strong> Energy Use </strong> - see how energy is used by different parts of society.</p>
                                    	</div>'))
                                    ),
                                    tabsetPanel(
                                      tabPanel("By Sector",
                                               fluidRow(
                                                 h5("Select fuel and see sectoral breakdown:"),
                                                 column(width = 2,
                                                        selectInput("nrg_sec_fuel_select", # 
                                                                    label = NULL,
                                                                    choices = fuel_list,
                                                                    selected = "All")
                                                 ), #close column
                                                 column(width = 10, 
                                                        ggiraphOutput("energy_by_sector_plot")
                                                 )
                                               )
                                      ), 
                                      tabPanel("By Fuel",
                                               fluidRow(
                                                 h5("Select sector and see fuel breakdown:"),
                                                 column(width = 2,
                                                        selectInput("nrg_fuel_sec_select", # 
                                                                    label = NULL,
                                                                    choices = sector_list,
                                                                    selected = "All")
                                                 ), #close column
                                                 column(width = 10,
                                                        ggiraphOutput("energy_by_fuel_plot")
                                                 )
                                                 
                                               ) #close fluid row
                                               
                                      ),
                                      tabPanel("Industrial Deep Dive",
                                               fluidRow(
                                                 column(width = 2,
                                                        
                                                        selectInput("nrg_inddd_sect_select", # 
                                                                    h5("Show breakdown in sector:"),
                                                                    choices = c("Food Products", "Metals", "Methanol", "Other Manufacturing","Other Chemicals", "Wood Products"),
                                                                    selected = "Food Products")
                                                 ), #close column
                                                 column(width = 10,
                                                        ggiraphOutput("industrial_plot")
                                                 )
                                                 
                                               )
                                      ),
                                      tabPanel("Res & Com",
                                               fluidRow(
                                                 column(width = 2,
                                                        
                                                        selectInput("nrg_rescom_select", # 
                                                                    h5("Show sector:"),
                                                                    choices = c("Residential","Commercial"),
                                                                    selected = "Residential"),
                                                        selectInput("nrg_rescom_fueltech_select", # 
                                                                    h5("Show breakdown of:"),
                                                                    choices = c("Fuel","Technology"),
                                                                    selected = "Fuel")
                                                 ), #close column
                                                 column(width = 10,
                                                        ggiraphOutput("resi_com_plot")
                                                 )
                                                 
                                               )
                                               
                                      ), #close tabPanel
                                      tabPanel("Transport",
                                               fluidRow(
                                                 column(width = 2,
                                                        selectInput("nrg_trans_brkdwn_select", # 
                                                                    h5("Show me a breakdown by:"),
                                                                    choices = c("Transport Fuels", "Transport Types", "Fleet Numbers"),
                                                                    selected = "Fleet Size"),
                                                        conditionalPanel(condition = "input.nrg_trans_brkdwn_select == 'Fleet Numbers'",
                                                                         selectInput("nrg_trans_sector_select", # 
                                                                                     h5("Select vehicle type:"),
                                                                                     choices = c("All",
                                                                                                 "Van/Ute",
                                                                                                 "Heavy Truck",
                                                                                                 "Medium Truck",
                                                                                                 "Bus",
                                                                                                 "Car",
                                                                                                 "Motorcycle"),
                                                                                     selected = "All")),
                                                        downloadButton("download_transport_data", "Download Data")
                                                 ), #close column
                                                 column(width = 10,
                                                        ggiraphOutput("transport_plot")
                                                 )
                                               ),
                                               fluidRow(class="section-row",
                                                        #htmlOutput("efficiency"), 
                                                        HTML(paste('<div class="col-xs-12 section-desc transport-desc">
                                    	  <p>The BEC2060 modelling was baselined on 2015 data, and growth rates applied thereafter.  In most cases, this has provided plausible estimates for 2020.  However, in the case of jetfuel, demand increased significantly immediately after 2015, due to a range of drivers (the cost of jetfuel, tourist numbers, and increasing international competition for NZ-bound flights, for example); noting that this steep increase has abated more recently.  We will re-baseline jetfuel demand in 2020</p>
                                    	</div>'))
                                               ) # close fluid page
                                      ) #close tabPanel 
                                      
                                    ) # close tabsetPanel (sub tab)
                                    
                           ), # close tabPanel Energy Use
                           
                           tabPanel("Efficiency", 
                                    fluidRow(class="section-row",
                                             HTML(paste('<div class="col-xs-12 section-desc">
                                    	  <p><strong> Efficiency </strong> - understand what role energy efficiency has to play in each of the scenarios.</p>
                                    	</div>'))
                                    ),
                                    fluidRow(
                                      column(width = 12,
                                             ggiraphOutput("efficiency_plot")
                                      ) # close column
                                    ) #close fluidRow
                           ), # close tabPanel
                           
                           tabPanel("Renewables",
                                    fluidRow(
                                      column(width = 12,
                                             ggiraphOutput("renewables_plot")
                                      ) # close column
                                    ) #close fluidRow
                           ), # close tabPanel
                           
                           tabPanel("Energy Prices",
                                    fluidRow(
                                      column(width = 2,
                                             selectInput("price_allele_select", # 
                                                         h5("Show:"),
                                                         choices = c("All Energy Prices in $/GJ", "Electricity Prices by Island in $/MWh"),
                                                         selected = "All Energy Prices in $/GJ"),
                                             
                                             conditionalPanel(condition = "input.price_allele_select == 'All Energy Prices in $/GJ'",
                                                              checkboxGroupInput("price_commod_chbx",
                                                                                 label = h5("Show:"),
                                                                                 choices = c("Biodiesel","Diesel","Electricity","Petrol","Hydrogen","Natural Gas"),
                                                                                 selected = c("Electricity")
                                                              )
                                             ) #close conditional Panel
                                      ),
                                      
                                      column(width = 10,
                                             ggiraphOutput("prices_plot")
                                      ) # close column
                                    ) #close fluidRow
                           ), # close tabPanel
                           
                           tabPanel("Costs",
                                    fluidRow(
                                      column(width = 2,
                                             selectInput("cost_sector_select", # 
                                                         h5("Show:"),
                                                         choices = c("Carbon Taxes", "Commercial", "Residential","Transport", "Electricity", "Transformation"),
                                                         selected = "Transport")
                                      ), #close column
                                      column(width = 10,
                                             ggiraphOutput("costs_plot")
                                      )
                                    ) #close fluidRow
                           ) # close tabPanel
                           
                           
                ), #close NavBar page
                #footer
                fluidRow(id="footer",
                         HTML(paste('
            <div class="footer">
              <div class="col-xs-12 col-md-6 footer-menu footer-left">
                <p>
  					      <a href="https://www.bec2060.org.nz">BEC2060 Website</a><br>
  						    <a href="https://www.bec2060.org.nz/contact">Contact</a><br>
						    </p>
              </div>
              <div class="col-xs-12 col-md-6 footer-menu footer-right">
					      <a href="https://www.bec.org.nz"><img src="https://www.bec2060.org.nz/__data/assets/image/0003/141573/BusinessNZ-Energy-Council-White.png"></a>
              </div>
          </div>
          '
                                    )
                         )
                )
                
)# close fluidpage

