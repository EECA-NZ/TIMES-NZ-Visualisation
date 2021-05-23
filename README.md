# TIMES-NZ Data Visualisation App
This repository contains README, the source code and data behind TIMES-NZ shiny Data Visualisation App: https://times-nz-model-eeca.shinyapps.io/TIMES_V2/

 
## To run app
There are two main R project associated with this App. 
1. The data processing project (TIMES_shiny_data_cleaning.Rproj) which is in the data_cleaning folder. 
	- To Run:
		- Open project using `TIMES_shiny_data_cleaning.Rproj` file in the data_cleaning folder.
		- Run `renv::restore()` in the Console to installl all needed envorinment and packages.
		- Run `source('New_Data_Processing.R', echo=TRUE)` to generate the needed data.
2. The Shiny App project (TIMES_shiny_app.Rproj) which is in the the app folder.
	- To Run:
		- Open project using `TIMES_shiny_app.Rproj` file in the app folder. 
		- Run `renv::restore()` to installl all needed envorinment and packages for the app. 
		- Run `shiny::runApp()` in the Console to run the App.




## Background
...

## Graphs

The graphs shows more information when one mouse-hover over the elements of the graph.

The graphs have interactive legends and by clicking on the names on the legend turns them on and off.
...

## app folder

...

## data_cleaning folder

...

## Updating the app

...

## Updating the data

...
