#Load libraries required
library(conflicted)
library(readxl) # read excel files
library(magrittr) #allows piping (more available options than just those in dplyr/tidyr)
library(tidyverse) # data manipulation, gather and spread commands
# library(writexl) # for writing excel 
options(scipen=999) # eliminates scientific notation

conflicts_prefer(dplyr::filter)

# Change the working directory to the script's directory
setwd("C:/Users/cattonw/git/TIMES-NZ-Visualisation/schema_generation/scripts")

# ignore the first 12 rows, raw data doesn't have headers/column names as the first row
# code was implicitly filtering non-numeric Period values, which are associated with rows representing salvage costs - this is now done explicitly
coh_raw <- read.csv(file = "../data/input/kea-v2_0_0.vd",
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

ind_raw <- read.csv(file = "../data/input/tui-v2_0_0.vd",
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


# Reading in intro Data --------------------------

intro <- read_delim("../../data_cleaning/intro.csv", delim = ";",  col_types = cols())

# Import schemas ----------------------------------------------------------


#The schema is used for two main purposes:
#   restricting TIMES model output to relevant rows via codes such as "Attribute", "Process"
#   include 'natural language' translations from TIMES codes
schema_all   <- read_csv("../data/reference/reference_schema_df_v2_0_0.csv")
schema_technology   <- read_xlsx("../../data_cleaning/Schema_Technology.xlsx") 

needed_attributes <- c("VAR_Act", "VAR_Cap", "VAR_FIn", "VAR_FOut")

non_emission_fuel <- c("Electricity", "Wood", "Hydrogen", "Hydro", "Wind", "Solar", "Biogas")


# Merge all data ---------------------------------------------------------------

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
          group_by(scen, Sector, Subsector, Technology, Enduse, Unit, Parameters, Fuel, Period, FuelGroup, Technology_Group) %>%
          # Sum up
          summarise(Value = sum(Value), .groups = "drop") %>% 
          # Removed all Annualised Capital Costs and Technology Capacity
          filter(Parameters != "Annualised Capital Costs", Parameters != "Technology Capacity") %>% 
          # Replace any NAs in the dataset with missing
          mutate(across(where(is.character), ~ifelse(is.na(.), "", .)))


# Write the data to a csv file
write_csv(clean_df, "../data/reference/reference_clean_df_v2_0_0.csv")