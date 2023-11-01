# ================================================================================================ #
# Description: The New_Data_Processing.R performs the data cleaning and calculations
# needed for the App. It depends on model output and schema
#
# Input: 
#
# Model inputs:
#   "Kea-v2_1.vd"   Kea model
#   "Tui-v2_1.vd"   Tui model
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
# 
# Output: Data for App
#
# Author: Kenny Graham (KG) and Conrad MacCormick (CM)
#
# Dependencies: 
#
# Notes:
# 
# Issues:
#
# History (reverse order): 
# 17 May 2021 KG v1 - Wrote the deliverable source code 
#
#

#Load libraries required
library(conflicted)
library(readxl) # read excel files
library(magrittr) #allows piping (more available options than just those in dplyr/tidyr)
library(tidyverse) # data manipulation, gather and spread commands
# library(writexl) # for writing excel 
options(scipen=999) # eliminates scientific notation

conflicts_prefer(dplyr::filter)

# ignore the first 12 rows, raw data doesn't have headers/column names as the first row
# code was implicitly filtering non-numeric Period values, which are associated with rows representing salvage costs - this is now done explicitly
coh_raw <- read.csv(file = "kea-v2_1_2.vd",
                    skip = 12,
                    header = FALSE, # first row read in is data not column names
                    stringsAsFactors = FALSE, # use character variable type instead of factors - easier to join to other table but less computationally efficient
                    col.names = c("Attribute","Commodity", "Process", "Period", "Region", "Vintage", "TimeSlice", "UserConstraint", "Value")) %>% 
  filter(grepl("^[0-9]+$", Period)) %>% # exclude rows with non-numeric Period values
  mutate(Period = as.integer(Period),
         scen = "Kea") %>% 
  filter(!(Period %in% c(2016)),
         Commodity != "COseq", 
         Period != "2020")

ind_raw <- read.csv(file = "tui-v2_1_2.vd",
                    skip = 12,
                    header = FALSE, # first row read in is data not column names
                    stringsAsFactors = FALSE, # use character variable type instead of factors - easier to join to other table but less computationally efficient
                    col.names = c("Attribute","Commodity", "Process", "Period", "Region", "Vintage", "TimeSlice", "UserConstraint", "Value")) %>% 
  filter(grepl("^[0-9]+$", Period)) %>% # exclude rows with non-numeric Period values
  mutate(Period = as.integer(Period),
         scen = "Tui") %>% 
  filter(!(Period %in% c(2016)),
         Commodity != "COseq", 
         Period != "2020")

# Merge the two scenarios
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
schema_technology   <- read_xlsx("Schema_Technology.xlsx") 

needed_attributes <- c("VAR_Act", "VAR_Cap", "VAR_FIn", "VAR_FOut")

non_emission_fuel <- c("Electricity", "Wood", "Hydrogen", "Hydro", "Wind", "Solar", "Biogas")


# Merge all data ---------------------------------------------------------------

# raw_df_n <-    inner_join(schema_unit, raw_df_n, by = c("Attribute")) %>% 


clean_df <- raw_df %>%  
          # map the schema to the raw data. code was implicitly doing an outer join - this is now done explicitly
          inner_join(schema_all, raw_df, by = c("Attribute", "Process", "Commodity"), relationship = "many-to-many") %>%
          # map the technology schema to the data
          inner_join(schema_technology, clean_df, by = c("Technology")) %>% 
          # Extract the needed attributes and Commodities
          filter(
                Attribute %in% needed_attributes
                 ) %>%
          # Setting Emission values to zero for  non emission fuel ("Electricity", "Wood",  "Hydrogen")
          mutate(Value = ifelse(Fuel %in% non_emission_fuel &  Parameters == 'Emissions', 0,Value) ) %>% 
          # complete data for all period by padding zeros
          complete(Period,nesting(scen,Sector, Subsector, Technology, Enduse, Unit, Parameters, Fuel, FuelGroup, Technology_Group),fill = list(Value = 0)) %>% 
          # Change Electricity to Other
          # Use this to convert the other sectors to Other 
          mutate(Sector = ifelse(Sector == "Electricity", "Other" , Sector)) %>% 
          # Modifying Attribute values: Changed emission to Mt C02
          mutate(Value = ifelse(Parameters == "Emissions", Value/1000,Value),
                 Unit = ifelse(Parameters == "Emissions", "Mt CO<sub>2</sub>/yr", Unit )) %>% 
          # Modifying Attribute values: Change Annualised Capital Costs to Billion NZD
          mutate(Value = ifelse(Parameters == "Annualised Capital Costs", Value/1000,Value),
                 Unit = ifelse(Parameters == "Annualised Capital Costs", "Billion NZD", Unit),
                 # Changing the Thousand Vehicles to Number of Vehicles (Thousands)
                 Unit = ifelse(Parameters == "Number of Vehicles", "Number of Vehicles (Thousands)", Unit)) %>% 
          # Remove the hard coded "N/A" in the data
          filter(!(Technology == "N/A")) %>% 
          # Group by the main variables and sum up
          group_by(scen, Sector, Subsector, Technology, Enduse, Unit, Parameters, Fuel,Period, FuelGroup,Technology_Group) %>%
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
                    Parameters == "End Use Demand" & 
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
                      Parameters == "End Use Demand" & 
                      Technology == "Heat Pump (Multi-Split)" &
                      Enduse     == "Space Heating"
                  ) 


# Filter out the values to divide
divide_df <- clean_df %>% 
                  filter(
                    Subsector  == "Detached Dwellings" &
                    Parameters  == "End Use Demand" & 
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



##########################################################################################################
# Biofuel computation for Heavy Truck, Medium Truck, Car/SUV, Van/Ute, Bus, Passenger Rail and Freight Rail
##########################################################################################################

end_uses <- c("Heavy Truck", "Medium Truck", "Car/SUV", "Van/Ute","Bus", "Passenger Rail", "Freight Rail")
# end_use <- "Heavy Truck"

for (end_use in end_uses) {
  
    # Filter out needed values
    needed_df <- clean_df %>%
      filter(
        Sector     == "Transport" &
        Parameters == "Fuel Consumption"  &
        Fuel       == "Biodiesel"  &
        Enduse     == end_use
      ) %>% arrange(scen)
    
    # Filter multiply values
    Multiple_df <- clean_df %>%
      filter(
        Sector     == "Transport" &
        Parameters == "Fuel Consumption"  &
        Fuel       == "Diesel"  &
        Enduse     == end_use
      ) %>% arrange(scen)
    
    # Filter out divide values
    divide_df <- clean_df %>%
      filter(
        Sector     == "Transport" &
        Parameters == "Fuel Consumption"  &
        Fuel       == "Diesel"
      ) %>% group_by(scen,
                     Sector,
                     Parameters,
                     Fuel,
                     Period,
                     FuelGroup) %>%
    
      summarise(Value = sum(Value), .groups = "drop") %>%
                arrange(scen)
    
    
    
    # Adding
    new_needed_df <- needed_df %>%
            mutate(Value = (needed_df$Value * Multiple_df$Value)/divide_df$Value )
    
    new_Multiple_df <- Multiple_df %>%
            mutate(Value = Multiple_df$Value - new_needed_df$Value )
    
    # Adding all computed values to the data frame
    combined_df <- rbind(combined_df %>%
    
                           # Filter out the duplicated df
                           filter(!(
                             Parameters == "Fuel Consumption"  &
                             Fuel       == "Biodiesel"  &
                             Enduse     == end_use )
                           ),
                           # Adding the new data
                           new_needed_df 
    
                  )
    
    # Adding all computed values to the data frame
    combined_df <- rbind(combined_df %>%
    
                           # Filter out the duplicated df
                           filter(!(
                             Parameters == "Fuel Consumption"  &
                             Fuel       == "Diesel"  &
                             Enduse     == end_use )
                           ),
                         # Adding the new data
                         new_Multiple_df   # new multiple df
    )

}






##########################################################################################################
# Biofuel computation for Domestic Aviation, International Aviation
##########################################################################################################

end_uses <- c("Domestic Aviation", "International Aviation")

for (end_use in end_uses) {

  # Filter out needed values
  needed_df <- clean_df %>%
    filter(
      Sector     == "Transport" &
        Parameters == "Fuel Consumption"  &
        Fuel       == "Drop-In Jet"  &
        Enduse     == end_use &
        scen       == "Kea"
    ) %>% arrange(scen)

  # Filter multiply values
  Multiple_df <- clean_df %>%
    filter(
      Sector     == "Transport" &
        Parameters == "Fuel Consumption"  &
        Fuel       == "Jet Fuel"  &
        Enduse     == end_use &
        scen       == "Kea"
    ) %>% arrange(scen)

  # Filter out divide values
  divide_df <- clean_df %>%
    filter(
      Sector     == "Transport" &
        Parameters == "Fuel Consumption"  &
        Fuel       == "Jet Fuel" &
        scen       == "Kea"
    ) %>% group_by(scen,
                   Sector,
                   Parameters,
                   Fuel,
                   Period,
                   FuelGroup) %>%

    summarise(Value = sum(Value), .groups = "drop") %>%
    arrange(scen)



  # Adding
  new_needed_df <- needed_df %>%
    mutate(Value = (needed_df$Value * Multiple_df$Value)/divide_df$Value )

  new_Multiple_df <- Multiple_df %>%
    mutate(Value = Multiple_df$Value - new_needed_df$Value )

  # Adding all computed values to the data frame
  combined_df <- rbind(combined_df %>%

                         # Filter out the duplicated df
                         filter(!(
                           Parameters == "Fuel Consumption"  &
                             Fuel       == "Drop-In Jet"  &
                             Enduse     == end_use &
                             scen       == "Kea" )
                         ),
                       # Adding the new data
                       new_needed_df 

  )

  # Adding all computed values to the data frame
  combined_df <- rbind(combined_df %>%

                         # Filter out the duplicated df
                         filter(!(
                           Parameters == "Fuel Consumption"  &
                             Fuel       == "Jet Fuel"  &
                             Enduse     == end_use &
                             scen       == "Kea" )
                         ),
                       # Adding the new data
                       new_Multiple_df   # new multiple df
  )

}







############################################################################
# Biofuel computation for Heavy Truck, Medium Truck, Car/SUV, Van/Ute, Bus
############################################################################

end_uses <- c("Heavy Truck", "Medium Truck", "Car/SUV", "Van/Ute", "Bus")

for (end_use in end_uses) {
  
  # Filter out needed values
  needed_df <- clean_df %>%
    filter(
      Subsector  == "Road Transport" &
        Parameters == "Emissions"  &
        Fuel       == "Biodiesel"  &
        Enduse     == end_use
    ) %>% arrange(scen)
  
  # Filter multiply values
  Multiple_df <- clean_df %>%
    filter(
      Subsector  == "Road Transport" &
        Parameters == "Fuel Consumption"  &
        Fuel       == "Biodiesel"  &
        Enduse     == end_use
    ) %>% arrange(scen)
  
  # Filter out divide values
  divide_df <- clean_df %>%
    filter(
      Subsector  == "Road Transport" &
        Parameters == "Fuel Consumption"  &
        Fuel       == "Biodiesel"
    ) %>% group_by(scen,
                   Sector,
                   Parameters,
                   Fuel,
                   Period,
                   FuelGroup) %>%
    
    summarise(Value = sum(Value), .groups = "drop") %>%
    arrange(scen)
  
  
  # Adding
  new_needed_df <- needed_df %>%
    mutate(Value = (needed_df$Value * Multiple_df$Value)/divide_df$Value )
  
  # Adding all computed values to the data frame
  combined_df <- rbind(combined_df %>%
                         
                         # Filter out the duplicated df
                         filter(!(
                           Parameters == "Emissions"  &
                             Fuel       == "Biodiesel"  &
                             Enduse     == end_use )
                         ),
                       # Adding the new data
                       new_needed_df 
                       
  )
  
}



############################################################
# Biofuel computation for Passenger Rail and Freight Rail
############################################################

end_uses <- c("Passenger Rail", "Freight Rail")

for (end_use in end_uses) {
  
  # Filter out needed values
  needed_df <- clean_df %>%
    filter(
      Subsector  == "Rail" &
        Parameters == "Emissions"  &
        Fuel       == "Biodiesel"  &
        Enduse     == end_use
    ) %>% arrange(scen)
  
  # Filter multiply values
  Multiple_df <- clean_df %>%
    filter(
      Subsector  == "Rail" &
        Parameters == "Fuel Consumption"  &
        Fuel       == "Biodiesel"  &
        Enduse     == end_use
    ) %>% arrange(scen)
  
  # Filter out divide values
  divide_df <- clean_df %>%
    filter(
      Subsector  == "Rail" &
        Parameters == "Fuel Consumption"  &
        Fuel       == "Biodiesel"
    ) %>% group_by(scen,
                   Sector,
                   Parameters,
                   Fuel,
                   Period,
                   FuelGroup) %>%
    
    summarise(Value = sum(Value), .groups = "drop") %>%
    arrange(scen)
  
  
  # Adding
  new_needed_df <- needed_df %>%
    mutate(Value = (needed_df$Value * Multiple_df$Value)/divide_df$Value )
  
  # Adding all computed values to the data frame
  combined_df <- rbind(combined_df %>%
                         
                         # Filter out the duplicated df
                         filter(!(
                           Parameters == "Emissions"  &
                             Fuel       == "Biodiesel"  &
                             Enduse     == end_use )
                         ),
                       # Adding the new data
                       new_needed_df 
                       
  )
  
}



##############################################################################
# Biofuel computation for Domestic Aviation
##############################################################################

end_uses <- c("Domestic Aviation")

for (end_use in end_uses) {
  
  # Filter out needed values
  needed_df <- clean_df %>%
    filter(
      Subsector  == "Aviation" &
        Parameters == "Emissions"  &
        Fuel       == "Drop-In Jet"  &
        Enduse     == end_use &
        scen       == "Kea"
    ) %>% arrange(scen)
  
  # Filter multiply values
  Multiple_df <- clean_df %>%
    filter(
      Subsector  == "Aviation" &
        Parameters == "Fuel Consumption"  &
        Fuel       == "Drop-In Jet"  &
        Enduse     == end_use &
        scen       == "Kea"
    ) %>% arrange(scen)
  
  # Filter out divide values
  divide_df <- clean_df %>%
    filter(
      Subsector  == "Aviation" &
        Parameters == "Fuel Consumption"  &
        Fuel       == "Drop-In Jet" &
        scen       == "Kea"
    ) %>% group_by(scen,
                   Sector,
                   Parameters,
                   Fuel,
                   Period,
                   FuelGroup) %>%
    
    summarise(Value = sum(Value), .groups = "drop") %>%
    arrange(scen)
  
  
  # Adding
  new_needed_df <- needed_df %>%
    mutate(Value = (0.4* needed_df$Value * Multiple_df$Value)/divide_df$Value )
  
  # Adding all computed values to the data frame
  combined_df <- rbind(combined_df %>%
                         
                         # Filter out the duplicated df
                         filter(!(
                           Parameters == "Emissions"  &
                             Fuel       == "Drop-In Jet"  &
                             Enduse     == end_use &
                             scen       == "Kea" 
                         )
                         ),
                       # Adding the new data
                       new_needed_df 
                       
  )
  
}





###############################################################################
# Emissions Biofuel computation for Industry: Construction and Mining subsectors
###############################################################################

subsectors <- c("Construction", "Mining")

for (subsector in subsectors){
  # Filter out needed values
  needed_df <- clean_df %>%
    filter(
      Sector     ==  "Industry" &
        Subsector  == subsector &
        Parameters == "Emissions"  &
        Fuel       == "Drop-In Diesel"  &
        Enduse     == "Motive Power, Mobile" &
        scen       == "Kea"
    )
  
  # Filter multiply values
  Multiple_df <- clean_df %>%
    filter(
      Sector     ==  "Industry" &
        Subsector  == subsector &
        Parameters == "Fuel Consumption"  &
        Fuel       == "Drop-In Diesel"  &
        Enduse     == "Motive Power, Mobile" &
        scen       == "Kea"
    ) 
  
  # Filter out divide values
  divide_df <- clean_df %>%
    filter(
      Sector     ==  "Industry" &
        Subsector %in% c("Construction", "Mining") &
        Parameters == "Fuel Consumption" &
        Fuel       == "Drop-In Diesel" &
        Enduse     == "Motive Power, Mobile" &
        scen       == "Kea"
    ) %>% group_by(scen,
                   Sector,
                   Fuel,
                   Period,
                   FuelGroup) %>%
    
    summarise(Value = sum(Value), .groups = "drop") 
  
  
  # Adding
  new_needed_df <- needed_df %>%
    mutate(Value = 0.6 * ( needed_df$Value * Multiple_df$Value)/divide_df$Value )
  
  # Adding all computed values to the data frame
  combined_df <- rbind(combined_df %>%
                         
                         # Filter out the duplicated df
                         filter(!(
                           Sector     ==  "Industry" &
                             Subsector  == subsector &
                             Parameters == "Emissions"  &
                             Fuel       == "Drop-In Diesel"  &
                             Enduse     == "Motive Power, Mobile" &
                             scen       == "Kea"
                         )
                         ),
                       # Adding the new data
                       new_needed_df 
                       
  )
  
}



###############################################################################
# Emissions Biofuel computation for Industry: Other subsectors
###############################################################################
# 
# subsectors <- c("Other")
# 
# for (subsector in subsectors){
#   # Filter out needed values
#   needed_df <- clean_df %>%
#     filter(
#       Sector     ==  "Industry" &
#         Subsector  == subsector &
#         Parameters == "Emissions"  &
#         Fuel       == "Drop-In Diesel"  &
#         Enduse     == "Other" &
#         scen       == "Kea"
#     )
#   
#   # Filter multiply values
#   Multiple_df <- clean_df %>%
#     filter(
#       Sector     ==  "Industry" &
#         Subsector  == subsector &
#         Parameters == "Fuel Consumption"  &
#         Fuel       == "Drop-In Diesel"  &
#         Enduse     == "Other" &
#         scen       == "Kea"
#     ) 
#   
#   # Filter out divide values
#   divide_df <- clean_df %>%
#     filter(
#       Sector     ==  "Industry" &
#         Parameters == "Fuel Consumption" &
#         Fuel       == "Drop-In Diesel" &
#         Enduse     == "Other" &
#         scen       == "Kea"
#     ) %>% group_by(scen,
#                    Sector,
#                    Fuel,
#                    Period,
#                    FuelGroup) %>%
#     
#     summarise(Value = sum(Value), .groups = "drop") 
#   
#   
#   # Adding
#   new_needed_df <- needed_df %>%
#     mutate(Value = 0.6 * ( needed_df$Value * Multiple_df$Value)/divide_df$Value )
#   
#   # Adding all computed values to the data frame
#   combined_df <- rbind(combined_df %>%
#                          
#                          # Filter out the duplicated df
#                          filter(!(
#                            Sector     ==  "Industry" &
#                              Subsector  == subsector &
#                              Parameters == "Emissions"  &
#                              Fuel       == "Drop-In Diesel"  &
#                              Enduse     == "Other" &
#                              scen       == "Kea"
#                          )
#                          ),
#                        # Adding the new data
#                        new_needed_df 
#                        
#   )
#   
# }



##########################################################################################################
# Fuel Consumption Biofuel computation for Industry:  "Construction" and "Mining"
##########################################################################################################

subsectors <- c("Construction", "Mining")

for (subsector in subsectors) {
  
  # Filter out needed values
  needed_df <- clean_df %>%
    filter(
      Sector     == "Industry" &
        Parameters == "Fuel Consumption"  &
        Fuel       == "Drop-In Diesel"  &
        Subsector  == subsector &
        Enduse     == "Motive Power, Mobile" &
        scen       == "Kea"
    ) %>% arrange(scen)
  
  # Filter multiply values
  Multiple_df <- clean_df %>%
    filter(
      Sector     == "Industry" &
        Parameters == "Fuel Consumption"  &
        Fuel       == "Diesel"  &
        Subsector  == subsector &
        Enduse     == "Motive Power, Mobile" &
        scen       == "Kea"
    ) %>% arrange(scen)
  
  # Filter out divide values
  divide_df <- clean_df %>%
    filter(
      Sector     == "Industry" &
        Subsector %in% c("Construction", "Mining") &
        Parameters == "Fuel Consumption"  &
        Fuel       == "Diesel" &
        Enduse     == "Motive Power, Mobile" &
        scen       == "Kea"
    ) %>% group_by(scen,
                   Sector,
                   Parameters,
                   Fuel,
                   Period,
                   FuelGroup) %>%
    
    summarise(Value = sum(Value), .groups = "drop") %>%
    arrange(scen)
  
  
  
  # Adding
  new_needed_df <- needed_df %>%
    mutate(Value = (needed_df$Value * Multiple_df$Value)/divide_df$Value )
  
  new_Multiple_df <- Multiple_df %>%
    mutate(Value = Multiple_df$Value - new_needed_df$Value )
  
  # Adding all computed values to the data frame
  combined_df <- rbind(combined_df %>%
                         
                         # Filter out the duplicated df
                         filter(!(
                           Sector     == "Industry" &
                             Parameters == "Fuel Consumption"  &
                             Fuel       == "Drop-In Diesel"  &
                             Subsector  == subsector &
                             Enduse     == "Motive Power, Mobile" &
                             scen       == "Kea" )
                         ),
                       # Adding the new data
                       new_needed_df 
                       
  )
  
  # Adding all computed values to the data frame
  combined_df <- rbind(combined_df %>%
                         
                         # Filter out the duplicated df
                         filter(!(
                           Sector     == "Industry" &
                             Parameters == "Fuel Consumption"  &
                             Fuel       == "Diesel"  &
                             Subsector  == subsector &
                             Enduse     == "Motive Power, Mobile" &
                             scen       == "Kea" )
                         ),
                       # Adding the new data
                       new_Multiple_df   # new multiple df
  )
  
}

# 
# ##########################################################################################################
# # Fuel Consumption Biofuel computation for Industry:  "Other"
# ##########################################################################################################
# 
# subsectors <- c("Other")
# 
# for (subsector in subsectors) {
#   
#   # Filter out needed values
#   needed_df <- clean_df %>%
#     filter(
#       Sector     == "Industry" &
#         Parameters == "Fuel Consumption"  &
#         Fuel       == "Drop-In Diesel"  &
#         Subsector  == subsector &
#         Enduse     == "Other" &
#         scen       == "Kea"
#     ) %>% arrange(scen)
#   
#   # Filter multiply values
#   Multiple_df <- clean_df %>%
#     filter(
#       Sector     == "Industry" &
#         Parameters == "Fuel Consumption"  &
#         Fuel       == "Diesel"  &
#         Subsector  == subsector &
#         Enduse     == "Other" &
#         scen       == "Kea"
#     ) %>% arrange(scen)
#   
#   # Filter out divide values
#   divide_df <- clean_df %>%
#     filter(
#       Sector     == "Industry" &
#         Parameters == "Fuel Consumption"  &
#         Fuel       == "Diesel" &
#         Enduse     == "Other" &
#         scen       == "Kea"
#     ) %>% group_by(scen,
#                    Sector,
#                    Parameters,
#                    Fuel,
#                    Period,
#                    FuelGroup) %>%
#     
#     summarise(Value = sum(Value), .groups = "drop") %>%
#     arrange(scen)
#   
#   
#   
#   # Adding
#   new_needed_df <- needed_df %>%
#     mutate(Value = (needed_df$Value * Multiple_df$Value)/divide_df$Value )
#   
#   new_Multiple_df <- Multiple_df %>%
#     mutate(Value = Multiple_df$Value - new_needed_df$Value )
#   
#   # Adding all computed values to the data frame
#   combined_df <- rbind(combined_df %>%
#                          
#                          # Filter out the duplicated df
#                          filter(!(
#                            Sector     == "Industry" &
#                              Parameters == "Fuel Consumption"  &
#                              Fuel       == "Drop-In Diesel"  &
#                              Subsector  == subsector &
#                              Enduse     == "Other" &
#                              scen       == "Kea" )
#                          ),
#                        # Adding the new data
#                        new_needed_df 
#                        
#   )
#   
#   # Adding all computed values to the data frame
#   combined_df <- rbind(combined_df %>%
#                          
#                          # Filter out the duplicated df
#                          filter(!(
#                            Sector     == "Industry" &
#                              Parameters == "Fuel Consumption"  &
#                              Fuel       == "Diesel"  &
#                              Subsector  == subsector &
#                              Enduse     == "Other" &
#                              scen       == "Kea" )
#                          ),
#                        # Adding the new data
#                        new_Multiple_df   # new multiple df
#   )
#   
# }


# Replacing all NaN with 0
combined_df[is.na(combined_df)] <- 0


# List generation
hierarchy_lits <- combined_df %>%
  distinct(Sector, Subsector,Enduse, Technology,Unit,Fuel) %>%
  arrange(across(everything()))


fuel_list <- distinct(hierarchy_lits,Fuel) # Fuel list
sector_list <-distinct(hierarchy_lits, Sector) # sector list
# Subsector_list <- distinct(hierarchy_lits, Subsector) 
# Technology_list <- distinct(hierarchy_lits, Technology)
# Enduse_list <- distinct(hierarchy_lits, Enduse)
# Unit_list <- distinct(hierarchy_lits,Unit)



# Reading in assumption data
assumptions_df <- read_excel(path = "Assumptions.xlsx", sheet = "Sheet1") %>% # extract assumptions for charting
  gather(Period, Value, `2022`:`2060`) %>%
  mutate(across(c(tool_tip_pre, tool_tip_trail), ~replace_na(., "")))  %>%
  # Changing total GDP 2022 period to 2018
  mutate(Period =  ifelse(Parameter == "Total GDP" & Period == 2022, 2018,Period))


assumptions_list <- distinct(assumptions_df, Parameter) %>% pull(Parameter)



# Reading in insight data
# extract assumptions for charting
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



# # Generating random colors 
# library(viridisLite)
# colors = viridis(nrow(fuel_list))
# cbind(fuel_list,colors)
# df <- cbind(fuel_list,colors)
# writexl::write_xlsx(df,"../Data_Cleaning/Schema_colors.xlsx")