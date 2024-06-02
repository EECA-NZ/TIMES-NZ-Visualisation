# ================================================================================================ #
# Description: The Newer_Data_Processing.R loads the data from the output_combined_df_v2_1_2.csv file for the Shiny app.
#
# Input: 
#
# Processed model output:
#   "output_combined_df_v2_1_2.csv" - outputs from Tui and Kea models, processed for Shiny app
# 
# Schema inputs
#   "Schema.xlsx" For restricting TIMES model and 'natural language' translations from TIMES codes                
#   "Schema_colors.xlsx"  To specify the color and shape for each Fuel and Technology              
#   "Schema_Technology.xlsx" For defining the Technology groups 
# 
# Assumption and Key insight data
#   "Assumptions.xlsx"                      The assumption data            
#   "Key-Insight.xlsx"                      The Key-Insight data
#   "Assumptions_Insight_comments.xlsx"     Plot commentary
# 
# Captions and pup-ups data
#   "Caption_Table.xlsx"                # Pup-up caption
#   "intro.csv"                         # Text for introduction to tour     
# 
# Output: Data for App
#
# History (reverse order): 
# 1 June 2024 WC removed the data cleaning - this script now only loads the data and saves to rda file
# 17 May 2021 KG v1 - Wrote the deliverable source code 
# ================================================================================================ #


#Load libraries required
library(readr)
library(readxl) # read excel files
library(magrittr) #allows piping (more available options than just those in dplyr/tidyr)
library(tidyverse) # data manipulation, gather and spread commands
library(conflicted)
options(scipen=999) # eliminates scientific notation

conflicts_prefer(dplyr::filter)

times_nz_version <- "2.1.2"
times_nz_version_str <- gsub("\\.", "_", times_nz_version)

# Reading in intro Data --------------------------

intro <- read_delim("intro.csv", delim = ";",  col_types = cols())
schema_colors <- read_xlsx("Schema_colors.xlsx")
caption_list <- read_xlsx("Caption_Table.xlsx")
schema_technology   <- read_xlsx("Schema_Technology.xlsx") 
combined_df <- read_csv(paste0("output_combined_df_v", times_nz_version_str, ".csv"))

# List generation
hierarchy_list <- combined_df %>%
  distinct(Sector, Subsector, Enduse, Technology, Unit, Fuel) %>%
  arrange(across(everything()))

fuel_list <- distinct(hierarchy_list, Fuel) # Fuel list
sector_list <-distinct(hierarchy_list, Sector) # sector list

# Reading in assumption data
assumptions_df <- read_excel(path = "Assumptions.xlsx", sheet = "Sheet1") %>% # extract assumptions for charting
  gather(Period, Value, `2022`:`2060`) %>%
  mutate(across(c(tool_tip_pre, tool_tip_trail), ~replace_na(., "")))  %>%
  # Changing total GDP 2022 period to 2018
  mutate(Period =  ifelse(Parameter == "Total GDP" & Period == 2022, 2018,Period))

assumptions_list <- distinct(assumptions_df, Parameter) %>% pull(Parameter)

# Reading in insight data to extract assumptions for charting
insight_df <- read_excel(path = "Key-Insight.xlsx", sheet = "Sheet1") %>% 
  gather(Period, Value, `2018`:`2060`) 

insight_list <- distinct(insight_df, Parameter)  %>% pull(Parameter)

# Reading in assumption key insight comments
Assumptions_Insight_df <- read_excel(path = "Assumptions_Insight_comments.xlsx")

# Ordered attributes
order_attr = c("Emissions","Fuel Consumption", "End Use Demand", "Annualised Capital Costs", 
               "Number of Vehicles", "Distance Travelled", "Electricity Generation",   
               "Gross Electricity Storage", "Grid Injection (from Storage)", 
               "Feedstock"  )

#Create the R data set for Shiny to use
save(combined_df, # data for charting
     fuel_list,  # list of fuel
     sector_list,  # list of Sectors 
     assumptions_df,  # data behind assumptions
     assumptions_list,  # list of assumptions for input$assumptions drop-down
     insight_df,  # data behind insight 
     insight_list,  # list of insight for input$insight drop-down
     Assumptions_Insight_df, # Add Assumptions Insight comments
     schema_colors, # Color scheme
     order_attr, # Ordered attribute
     caption_list, # Add caption list,
     intro, # Add introduction tour comments 
     file = "../App/data/data_for_shiny.rda")