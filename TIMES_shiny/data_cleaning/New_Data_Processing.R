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

non_emission_fuel <- c("Electricity", "Wood", "Hydrogen", "Hydro", "Wind", "Solar", "Biogas")


# Merge all data ---------------------------------------------------------------

# raw_df_n <-    inner_join(schema_unit, raw_df_n, by = c("Attribute")) %>% 


clean_df <- raw_df %>%  
          # map the schema to the raw data
          inner_join(schema_all, raw_df, by = c("Attribute", "Process", "Commodity")) %>%  
          # Extract the needed attributes and Commodities
          filter(
                Attribute %in% needed_attributes
                 ) %>%
          # Setting Emission values to zero for  non emission fuel ("Electricity", "Wood",  "Hydrogen")
          mutate(Value = ifelse(Fuel %in% non_emission_fuel &  Parameters == 'Emissions', 0,Value) ) %>% 
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




# Calculating the new heating and cooling values


# Filter out the cooling values
Cool_Var1 <- clean_df %>% 
          filter(
            Subsector  == "Detached Dwellings" & 
            Parameters == "Fuel Consumption"  &
            Technology == "Heat Pump (Multi-Split)" & 
            Enduse     == "Space Cooling" 
                      )
# Filter out the cooling values to multiple
Cool_Multiple_Var <- clean_df %>%  
                  filter(
                    Subsector  == "Detached Dwellings" &
                    Parameters == "Demand" & 
                    Technology == "Heat Pump (Multi-Split)" &
                    Enduse     == "Space Cooling"
                    ) 


# Filter out the heating values to multiple
Heat_Var1 <- clean_df %>% 
                  filter(
                    Subsector  == "Detached Dwellings" & 
                      Parameters == "Fuel Consumption"  &
                      Technology == "Heat Pump (Multi-Split)" & 
                      Enduse     == "Space Heating" 
                  )


# Filter out the heating values to multiple
Heat_Multiple_Var <- clean_df %>%  
                  filter(
                    Subsector  == "Detached Dwellings" &
                      Parameters == "Demand" & 
                      Technology == "Heat Pump (Multi-Split)" &
                      Enduse     == "Space Heating"
                  ) 


# Filter out the values to divide
divide_df <- clean_df %>% 
                  filter(
                    Subsector  == "Detached Dwellings" &
                    Parameters  == "Demand" & 
                    Technology == "Heat Pump (Multi-Split)"
                  ) %>% group_by(scen, Sector, Subsector,  Technology, 
                                 Unit, Parameters,Fuel, Period, FuelGroup) %>% 
                    summarise(Value = sum(Value), .groups = "drop") 


# Creating the new cooling
new_cooling <- Cool_Var1 %>% 
          mutate(Value = (Cool_Var1$Value * Cool_Multiple_Var$Value)/divide_df$Value )

# Creating the new heating
new_heating <-  Heat_Var1 %>% 
          mutate(Value = (Heat_Var1$Value * Heat_Multiple_Var$Value)/divide_df$Value )


# Replacing all NaN with 0
new_cooling[is.na(new_cooling)] <- 0
new_heating[is.na(new_heating)] <- 0

# Adding all the needed new data set
combined_df <- rbind(clean_df %>%
                       
                     # Filter out the duplicated cooling and heating 
                     filter(!(
                            Parameters == "Fuel Consumption"  &
                            Technology == "Heat Pump (Multi-Split)")
                        ),    
                     # Adding the new data
                     new_cooling, # new cooling
                     new_heating  # new heating
                     )


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