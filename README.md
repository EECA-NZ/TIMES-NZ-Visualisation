# TIMES-NZ Data Visualisation App
This repository contains README, the source code and data behind TIMES-NZ shiny Data Visualisation App. The App is located  at https://times-nz-model-eeca.shinyapps.io/TIMES_V2/
and it can be viewed through the EECA's webesite at https://www.eeca.govt.nz/new-zealand-energy-scenarios-times-nz-2-0/?stage=Stage
 
## To run app
There are two main R project associated with this App. 
1. The data processing project (TIMES_shiny_data_cleaning.Rproj) which is in the data_cleaning folder. 
	- To Run:
		- Open `TIMES_shiny_data_cleaning.Rproj` project file in the data_cleaning folder.
		- Run `renv::restore()` in the Console to installl all needed envorinment and packages.
		- Run `source('New_Data_Processing.R', echo=TRUE)` to generate the needed data.
2. The Shiny App project (TIMES_shiny_app.Rproj) which is in the the app folder.
	- To Run:
		- Open `TIMES_shiny_app.Rproj` project file in the app folder. 
		- Run `renv::restore()` to installl all needed envorinment and packages for the app. 
		- Run `shiny::runApp()` in the Console to run the App.

## Background
The New Zealand Energy Scenarios Times-NZ 2.0 website presents model insights for the latest TIMES-NZ scenarios to contribute to decision making in businesses and Government. This New Zealand Energy Scenarios TIMES-NZ 2.0 visualisation tool will allow you to explore how New Zealand energy futures may look like based on outputs from the New Zealand Energy Scenarios TIMES-NZ 2.0 model.

## Graphs

The graphs are interactive and shows more information when one mouse-hover over the elements of the graph.

The graphs have interactive legends and by clicking on the names on the legend turns them on and off.
...


## App folder

...
### Updating the app
...

## Data cleaning folder

...


### Updating the data

...


