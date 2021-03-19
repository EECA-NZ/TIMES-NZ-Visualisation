#Load libraries required
library(readxl) # read excel files
library(magrittr) #allows piping (more available options than just those in dplyr/tidyr)
library(tidyverse) # data manipulation, gather and spread commands
options(scipen=999) # eliminates scientific notation


# ignore the first 12 rows, raw data doesn't have headers/column names as the first row
coh_raw <- read.csv(file = "COH.VD",
                    skip = 12,
                    header = FALSE, #first row read in is data not column names
                    stringsAsFactors = FALSE, #use character variable type instead of factors - easier to join to other table but less computationally efficient
                    col.names = c("Attribute","Commodity", "Process", "Period", "Region", "Vintage", "TimeSlice", "UserConstraint", "Value")) %>% 
  mutate(Period = as.integer(Period),
         scen = "Kea") %>% 
  filter(!(Period %in% c(2016)))

ind_raw <- read.csv(file = "IND.VD",
                    skip = 12,
                    header = FALSE, #first row read in is data not column names
                    stringsAsFactors = FALSE, #use character variable type instead of factors - easier to join to other table but less computationally efficient
                    col.names = c("Attribute","Commodity", "Process", "Period", "Region", "Vintage", "TimeSlice", "UserConstraint", "Value")) %>% 
  mutate(Period = as.integer(Period),
         scen = "Tui") %>% 
  filter(!(Period %in% c(2016)))

# Merge the two scenario 
raw_df <- union_all(coh_raw, ind_raw)

period_list <- raw_df %>% distinct(Period) %>% filter(between(Period, 2000, 2100))


# Import schemas ----------------------------------------------------------

#The schema is used for two main purposes:
#   restricting TIMES model output to relevant rows via codes such as "Attribute", "Process"
#   include 'natural language' translations from TIMES codes
schema_all   <- read_xlsx("Schema.xlsx") 
schema_colors <- read_xlsx("Schema_colors.xlsx")
caption_list <- read_xlsx("Caption_Table.xlsx")
# schema_unit   <- read_xlsx("Schema_unit.xlsx") 

needed_attributes = c("VAR_Act", "VAR_Cap", "VAR_FIn", "VAR_FOut",  "Cost_Inv")

# Merge all data ---------------------------------------------------------------

# raw_df_n <-    inner_join(schema_unit, raw_df_n, by = c("Attribute")) %>% 


clean_df <- raw_df %>%  
          # map the schema to the raw data
          inner_join(schema_all, raw_df, by = c("Attribute", "Process")) %>%  
          # Extract the needed attributes 
          filter(Attribute %in% needed_attributes) %>% 
          # complete data for all period by padding zeros
          complete(Period,nesting(scen,Sector, Subsector, Technology, Enduse, Unit, Parameters, Fuel),fill = list(Value = 0)) %>% 
          # Modifying Attribute values: Changed emission to Mt C02
          mutate(Value = ifelse(Parameters == "Emissions", Value/1000,Value),
                 Unit = ifelse(Parameters == "Emissions", "Mt CO2", Unit )) %>% 
          # Modifying Attribute values: Change Annualised Capital Costs to Billion NZD
          mutate(Value = ifelse(Parameters == "Annualised Capital Costs", Value/1000,Value),
                 Unit = ifelse(Parameters == "Annualised Capital Costs", "Billion NZD", Unit),
                 # Changing the Thousand Vehicles to Number of Vehicles (Thousands)
                 Unit = ifelse(Parameters == "Number of Vehicles", "Number of Vehicles (Thousands)", Unit)) %>% 
          # Remove the hard coded "N/A" in the data
          filter(!(Technology == "N/A")) %>% 
          # Group by the main variables and sum up
          group_by(scen, Sector, Subsector, Technology, Enduse, Unit, Parameters, Fuel,Period) %>%
          # Sum up
          summarise(Value = sum(Value), .groups = "drop") %>% 
          # Removed all Annualised Capital Costs and Technology Capacity
          filter(Parameters != "Annualised Capital Costs", Parameters != "Technology Capacity") %>% 
          # Replace any NAs in the dataset with missing
          mutate(across(where(is.character), ~ifelse(is.na(.), "", .)))


# # Add colors form the color schema
# combined_df <- inner_join(clean_df,schema_colors,by = c("Fuel")) 


combined_df <- clean_df


# 
# # Create 'hierarchy' file. Based on all combinations of dropdowns.
# hierarchy <- combined_df %>%
#   distinct(Sector, Subsector,Enduse, Technology,Unit) %>%
#   arrange(across())


# List generation
hierarchy_lits <- combined_df %>%
  distinct(Sector, Subsector,Enduse, Technology,Unit,Fuel) %>%
  arrange(across())

fuel_list <- distinct(hierarchy_lits,Fuel) # Fuel list
sector_list <-distinct(hierarchy_lits, Sector) # sector list
# Subsector_list <- distinct(hierarchy_lits, Subsector) 
# Technology_list <- distinct(hierarchy_lits, Technology)
# Enduse_list <- distinct(hierarchy_lits, Enduse)
# Unit_list <- distinct(hierarchy_lits,Unit)




assumptions_df <- read_excel(path = "Assumptions.xlsx", sheet = "Sheet1") %>% # extract assumptions for charting
  gather(Period, Value, `2022`:`2060`) %>% 
  mutate(across(c(tool_tip_pre, tool_tip_trail), ~replace_na(., "")))

assumptions_list <- distinct(assumptions_df, Parameter)

# Ordered attributes
order_attr = c("Fuel Consumption", "Demand", "Emissions", "Annualised Capital Costs", "Number of Vehicles", "Distance travelled")


#Create the R data set for Shiny to use
save(combined_df, # data for charting
     fuel_list,  # list of fuel for input$fuel_choice drop down
     sector_list,  # list of Sectors for input$sector_choice drop down
     assumptions_df,  # data behind assumptions
     assumptions_list,  # list of assumptions for input$assumptions drop-down
     schema_colors, # Color scheme
     order_attr, # Ordered attribute
     caption_list, # Add caption list
     file = "../App/data/data_for_shiny.rda")



# # Generating random colors 
# library(viridisLite)
# colors = viridis(nrow(fuel_list))
# cbind(fuel_list,colors)
# df <- cbind(fuel_list,colors)
# writexl::write_xlsx(df,"../Data_Cleaning/Schema_colors.xlsx")