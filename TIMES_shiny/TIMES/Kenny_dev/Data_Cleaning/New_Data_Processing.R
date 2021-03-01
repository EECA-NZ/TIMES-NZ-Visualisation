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
# schema_unit   <- read_xlsx("Schema_unit.xlsx") 

needed_attributes = c("VAR_Act", "VAR_Cap", "VAR_FIn", "VAR_FOut",  "Cost_Inv")

# Merge all data ---------------------------------------------------------------

# raw_df_n <-    inner_join(schema_unit, raw_df_n, by = c("Attribute")) %>% 


clean_df <- raw_df %>%  
          # map the schema to the raw data
          inner_join(schema_all, raw_df, by = c("Attribute", "Process")) %>%  
          # Extract the needed attributes 
          filter(Attribute %in% needed_attributes) %>% 
          # Group by the main variables and sum up
          group_by(scen, Sector, Subsector, Technology, Enduse, Unit, Parameters, Fuel,Period) %>%
          # Sum up
          summarise(Value = sum(Value), .groups = "drop") %>% 
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
  gather(Period, Value, `2020`:`2060`) %>% 
  mutate(across(c(tool_tip_pre, tool_tip_trail), ~replace_na(., "")))

assumptions_list <- distinct(assumptions_df, Parameter)

#Create the R data set for Shiny to use
save(combined_df, # data for charting
     fuel_list,  # list of fuel for input$fuel_choice drop down
     sector_list,  # list of Sectors for input$sector_choice drop down
     assumptions_df,  # data behind assumptions
     assumptions_list,  # list of assumptions for input$assumptions drop-down
     schema_colors, # Color scheme
     file = "../App/data/data_for_shiny.rda")



# # Generating random colors 
# library(viridisLite)
# colors = viridis(nrow(fuel_list))
# cbind(fuel_list,colors)
# df <- cbind(fuel_list,colors)
# writexl::write_xlsx(df,"../Data_Cleaning/Schema_colors.xlsx")