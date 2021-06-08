# TIMES-NZ 2.0 Data Visualization App
This repository contains the README, source code and data behind the TIMES-NZ 2.0 visualisation tool. The app is located on the [shinyapps.io](https://shinyapps.io) platform [here](https://eeca-nz.shinyapps.io/TIMES_V2/) and it can be viewed through [EECA's website](http://www.eeca.govt.nz/TIMES-NZ).

## Background
The New Zealand Energy Scenarios Times-NZ 2.0 website presents model insights for the latest TIMES-NZ scenarios to contribute to decision making by businesses and Government. The New Zealand Energy Scenarios TIMES-NZ 2.0 visualisation tool allows users to explore how New Zealand energy futures may look like based on outputs from the New Zealand Energy Scenarios TIMES-NZ 2.0 model. A detailed description of the  model and the app is found on the [EECA website](https://www.eeca.govt.nz/New-Zealand-Energy-Scenarios-TIMES-NZ-2.pdf).

## Software requirements
- [R (v4+)](https://cran.r-project.org/bin/windows/base/)
- [RStudio (v1.4+)](https://www.rstudio.com/products/rstudio/)

## To run the app
There are two R project folders associated with this app:
1. The data processing project (`TIMES_shiny_data_cleaning.Rproj`) which is in the `data_cleaning` folder.
	- To run:
		- open the `TIMES_shiny_data_cleaning.Rproj` project file. This will open the project in an RStudio window.
		- run `renv::restore()` in the console to install all required packages.
		- run `source('New_Data_Processing.R', echo=TRUE)` in the console to generate the required data. This data is saved as `data_for_shiny.rda` in the `app/data` folder.
2. The Shiny app project (`TIMES_shiny_app.Rproj`) which is in the app folder.
	- To run:
		- open the `TIMES_shiny_app.Rproj` project file in the `app` folder.
		- run `renv::restore()` to install all required packages for the app.
		- run `shiny::runApp()` in the console to run the app locally.

## Deploy app
To deploy the app, run `source('Deploy_App.R', echo=TRUE)` in the console. The user will need to configure the `rsconnect` package to use EECA's shinyapps.io account. A detailed description on how to configure `rsconnect` is located [here](https://shiny.rstudio.com/articles/shinyapps.html). Before running the `Deploy_App.R` script, the user will need to set up EECA's shinyapps.io account using the `rsconnect` package. The shinyapps.io site automatically generates a secret token, which the `rsconnect` package can use to link the shinyapps.io account to your local set-up. Step by step instructions can be found [here](https://shiny.rstudio.com/articles/shinyapps.html) under the **Configure rsconnect** section.

## Graphs
The graphs are interactive and show more information when the user hovers over the elements of the graph with their mouse. The graphs have interactive legends and by clicking on the names on the legend the user can turn them on and off.

## App folder

    ├── app													# Application files (Files needed for app to run)
    │   ├── TIMES_shiny_app.Rproj 	# The R project file for the app
    │   ├── server.R								# `server.R` defines the responses to the user inputs, the logic and data filtering
    │   ├── ui.R 										# `ui.R` defines the UI component of the Shiny app, such as the buttons, pickers, menus
    │   ├── Deploy_App.R        		# This script is used to deploy the app
    │   ├── functions.R							# The plotting function and helper functions are located here
    │   ├── intro_text.html					# This holds the text for introduction to tour
    │   ├── renv.lock   						# It used by `renv::restore()` to install all needed environment and packages
    │   ├── data
    │	     ├── data_for_shiny.rda  	# The contains the data objects generated by the data processing scripts
    │	     ├── load_data.R					# Loads the data objects from `rda` file and generate the hierarchy data object
    │   ├── rsconnect
    │		├── shinyapps.io
    │			├── ... 									# Contains the credentials for shinyapps.io
    │   ├──  renv
    │		├── library
    │		     ├── ...								# Contains the needed files for the environment needed for the App
    │		├── activate								# Script to install the needed environments
    │   ├── www                
    │		├── css											# Contains the styling files
    │		├── font-awesome-5.3.1  		# Contains all the awesome fonts  
    │		├── img											# Contains the EECA and BEC logo


## Data cleaning folder
    ├── data_cleaning			    								# Application files (Files needed for App to run)
    │   ├── TIMES_shiny_data_cleaning.Rproj 	# The R project file for the app
    │   ├── Assumptions.xlsx 									# The assumption data
    │   ├── Assumptions_Insight_comments.xlsx	# Assumption and insight plot commentary
    │   ├── Caption_Table.xlsx								# Pop-up caption
    │   ├── intro.csv													# This holds the introduction to tour
    │   ├── Kea-v79.VD												# Kea model output
    │   ├── Tui-v79.VD												# Tui model output
    │   ├── Key-Insight.xlsx									# The Key-Insight data
    │   ├── New_Data_Processing.R							# Script that performs the data cleaning and calculations needed for the app
    │   ├── renv
    │		├── library
    │		     ├── ...													# Contains the needed files for the environment needed for the app
    │		├── activate													# Script to install the needed environments
    │   ├── renv.lock													# It used by `renv::restore()` to install all needed environment and packages
    │   ├── Schema.xlsx												# For restricting TIMES model and 'natural language' translations from TIMES codes
    │   ├── Schema_colors.xlsx								# To specify the colour and shape for each fuel and technology
    │   ├── Schema_Technology.xlsx 						# For defining the Technology groups
