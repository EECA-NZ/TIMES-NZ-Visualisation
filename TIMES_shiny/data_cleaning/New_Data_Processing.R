#Load libraries required
library(readxl) # read excel files
library(magrittr) #allows piping (more available options than just those in dplyr/tidyr)
library(tidyverse) # data manipulation, gather and spread commands
library(writexl) # for writing excel 
options(scipen=999) # eliminates scientific notation


# ignore the first 12 rows, raw data doesn't have headers/column names as the first row
coh_raw <- read.csv(file = "Kea-v79.VD",
                    skip = 12,
                    header = FALSE, #first row read in is data not column names
                    stringsAsFactors = FALSE, #use character variable type instead of factors - easier to join to other table but less computationally efficient
                    col.names = c("Attribute","Commodity", "Process", "Period", "Region", "Vintage", "TimeSlice", "UserConstraint", "Value")) %>% 
  mutate(Period = as.integer(Period),
         scen = "Kea") %>% 
  filter(!(Period %in% c(2016)),
         Commodity != "COseq", 
         Period != "2020")



ind_raw <- read.csv(file = "Tui-v79.VD",
                    skip = 12,
                    header = FALSE, #first row read in is data not column names
                    stringsAsFactors = FALSE, #use character variable type instead of factors - easier to join to other table but less computationally efficient
                    col.names = c("Attribute","Commodity", "Process", "Period", "Region", "Vintage", "TimeSlice", "UserConstraint", "Value")) %>% 
  mutate(Period = as.integer(Period),
         scen = "Tui") %>% 
  filter(!(Period %in% c(2016)),
         Commodity != "COseq", 
         Period != "2020")

# Merge the two scenario 
raw_df <- union_all(coh_raw, ind_raw)

period_list <- raw_df %>% distinct(Period) %>% filter(between(Period, 2000, 2100))



# Reading in intro Data --------------------------

intro <- read_delim("intro.csv", delim = ";",  col_types = cols())

# Import schemas ----------------------------------------------------------


#The schema is used for two main purposes:
#   restricting TIMES model output to relevant rows via codes such as "Attribute", "Process"
#   include 'natural language' translations from TIMES codes
schema_all   <- read_xlsx("Schema.xlsx") 
schema_colors <- read_xlsx("Schema_colors.xlsx")
caption_list <- read_xlsx("Caption_Table.xlsx")
# schema_unit   <- read_xlsx("Schema_unit.xlsx") 

needed_attributes <- c("VAR_Act", "VAR_Cap", "VAR_FIn", "VAR_FOut")

# # These are Commodities used for analysis 
# needed_Commodities <- c("AGRELC", "AGRPET", "AGRDSL", "AGRFOL", "AGRCOA", "AGRNGA", 
#             "AGRGEO", "AGRLPG", "COMELC", "COMDSL", "COMPET", "COMCOA", 
#             "COMFOL", "COMNGA", "COMGEO", "COMLPG", "INDELC", "INDNGA", 
#             "INDFOL", "INDDSL", "OILWST", "INDCOA", "INDGEO", "INDLPG", 
#             "ELCCOA", "ELCNGA", "ELCWOD", "FOL", "JET", "COA", "GEO", 
#             "NGA", "WOD", "BDSL", "BIG", "ELCD", "ELCDD", "INDWOD", "INDBIG", 
#             "INDPET", "RESELC", "RESLPG", "RESNGA", "RESCOA", "RESDSL", "RESWOD", 
#             "RESGEO", "RESSOL", "AGRWST", "OILI", "TRAELC", "TRAPET", "TRADSL", 
#             "TRALPG", "TRAFOL", "TRAJET", "MNCWST", "INDOSWOD", "ELCBIG", 
#             "RESPET", "AGRWOD", "COMBIG", "H2R", "AGRH2R", 
#             "COMH2R", "ELCGEO", "ELCHYD", "ELCSOL", "ELCWIN", 
#             "HYD", "WIN", "DIJ", "DID", "AGRCO2", "COMCO2", 
#             "INDCO2", "TOTCO2", "ELCCO2", "GASCO2", "RESCO2", 
#             "REFCO2", "TRACO2", "ELCOIL", "H2D", "ANMMNR", "ELCBIL", 
#             "LNG", "TRAH2R", "ELCCOL", "COMPLT", "PLT", "COMWOD", "ACT", "-")

# Merge all data ---------------------------------------------------------------

# raw_df_n <-    inner_join(schema_unit, raw_df_n, by = c("Attribute")) %>% 


clean_df <- raw_df %>%  
          # map the schema to the raw data
          inner_join(schema_all, raw_df, by = c("Attribute", "Process", "Commodity")) %>%  
          # Extract the needed attributes and Commodities
          filter(
                Attribute %in% needed_attributes
                 ) %>%
          # complete data for all period by padding zeros
          complete(Period,nesting(scen,Sector, Subsector, Technology, Enduse, Unit, Parameters, Fuel, FuelGroup),fill = list(Value = 0)) %>% 
          # Change Electricity to Other
          # Use this to convert the other sectors to Other 
          mutate(Sector = ifelse(Sector == "Electricity", "Other" , Sector)) %>% 
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
          group_by(scen, Sector, Subsector, Technology, Enduse, Unit, Parameters, Fuel,Period, FuelGroup) %>%
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



# Reading in assumption data
assumptions_df <- read_excel(path = "Assumptions.xlsx", sheet = "Sheet1") %>% # extract assumptions for charting
  gather(Period, Value, `2022`:`2060`) %>%
  mutate(across(c(tool_tip_pre, tool_tip_trail), ~replace_na(., "")))


assumptions_list <- distinct(assumptions_df, Parameter) %>% pull(Parameter)



# Reading in insight data

insight_df <- read_excel(path = "Key-Insight.xlsx", sheet = "Sheet1") %>% # extract assumptions for charting
  gather(Period, Value, `2018`:`2060`) 

insight_list <- distinct(insight_df, Parameter)  %>% pull(Parameter)


# Ordered attributes
order_attr = c("Emissions","Fuel Consumption", "Demand",  "Annualised Capital Costs", "Number of Vehicles", 
               "Distance Travelled", "Electricity Generation",   "Gross Electricity Storage", "Grid Injection (from Storage)" )


#Create the R data set for Shiny to use
save(combined_df, # data for charting
     fuel_list,  # list of fuel for input$fuel_choice drop down
     sector_list,  # list of Sectors for input$sector_choice drop down
     assumptions_df,  # data behind assumptions
     assumptions_list,  # list of assumptions for input$assumptions drop-down
     insight_df,  # data behind insight 
     insight_list,  # list of insight for input$insight drop-down
     schema_colors, # Color scheme
     order_attr, # Ordered attribute
     caption_list, # Add caption list,
     intro, # Add introduction tour comments 
     file = "../App/data/data_for_shiny.rda")



# # Generating random colors 
# library(viridisLite)
# colors = viridis(nrow(fuel_list))
# cbind(fuel_list,colors)
# df <- cbind(fuel_list,colors)
# writexl::write_xlsx(df,"../Data_Cleaning/Schema_colors.xlsx")