#Load libraries required
library(readxl) # read excel files
library(magrittr) #allows piping (more available options than just those in dplyr/tidyr)
library(tidyverse) # data manipulation, gather and spread commands
options(scipen=999) # eliminates scientific notation

#setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

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

raw_df <- union_all(coh_raw, ind_raw)

period_list <- raw_df %>% distinct(Period) %>% filter(between(Period, 2000, 2100))

# Import schemas ----------------------------------------------------------

#schemas are used for two main purposes:
#   restricting TIMES model output to relevant rows via codes such as "Attribute", "Commidity", "Process" etc
#   include 'natural language' translations from TIMES codes

schema_transport   <- read_xlsx("Schema3.xlsx", "Transport") 
schema_electricity <- read_xlsx("Schema3.xlsx", "Electricity")
schema_primary     <- read_xlsx("Schema3.xlsx", "Primary")
schema_energy      <- read_xlsx("Schema3.xlsx", "Energy")
schema_specific    <- read_xlsx("Schema3.xlsx", "Energy_Specific")
schema_tech        <- read_xlsx("Schema3.xlsx", "ResComTech")
schema_industrial  <- read_xlsx("Schema3.xlsx", "IND_Deep_Dive")
schema_emissions   <- read_xlsx("Schema3.xlsx", "Emissions")
schema_prices      <- read_xlsx("Schema3.xlsx", "Prices")
schema_weights     <- read_xlsx("Schema3.xlsx", "Load_Curve")
schema_supplem     <- read_xlsx("Schema3.xlsx", "Transformation")
schema_eff         <- read_xlsx("Schema3.xlsx", "Efficiency") # Service demand (VAR_FOut) by PSI's commodity sets
schema_sets        <- read_xlsx("Schema3.xlsx", "Sets") # Need this to sum energy demand by PSI's commodity sets, since VAR_FIn is not available by commodity sets, only fuel and process
schema_costs       <- read_xlsx("Schema3.xlsx", "Costs")

# Transport ---------------------------------------------------------------

transport_raw <- inner_join(schema_transport, raw_df, by = c("Attribute", "Process"))

# Generate table of vehicle numbers
transport_num <- transport_raw %>% 
  filter(Attribute == "VAR_Cap") %>% # Vehicle numbers are coded as VAR_Cap
  group_by(scen, Chart_Desc, Type, Period) %>%
  summarise(Value = sum(Value), .groups = "drop") %>% 
  # Complete is used to 'fill out' missing combinations from the data set
  complete(scen, nesting(Chart_Desc, Type), period_list, fill = list(Value = 0)) %>%
  mutate(data_group = "Transport", Attribute = "Number of Vehicles, m")

# Generate table of vehicle energy demand
transport_nrg <- transport_raw %>% 
  filter(Attribute == "VAR_FIn") %>% # Vehicle energy usage is coded as VAR_Cap
  group_by(scen, Chart_Desc, Type, Period) %>% 
  summarise(Value = sum(Value), .groups = "drop") %>% 
  complete(scen, nesting(Chart_Desc, Type), period_list, fill = list(Value = 0)) %>% 
  mutate(data_group = "Transport", Attribute = "PJ") 

# Electricity -------------------------------------------------------------

electricity_raw <- inner_join(schema_electricity, raw_df, by = c("Attribute", "Process"))

# Estimated electricity generation
electricity_gen <- electricity_raw %>% 
  filter(Attribute == "VAR_Act" & Chart_Desc != "Batteries") %>% # Battery figures do not make sense from an energy consumption perspective
  group_by(scen, Chart_Desc, Period) %>% 
  summarise(Value = sum(Value), .groups = "drop") %>% 
  complete(scen, Chart_Desc, period_list, fill = list(Value = 0)) %>% 
  mutate(Value = Value / 3.6, #TWh conversion
         data_group = "Electricity",
         Attribute = "Generation in TWh")

# Electricity generation capacity
electricity_cap <- electricity_raw %>% 
  filter(Attribute == "VAR_Cap") %>% 
  group_by(scen, Chart_Desc, Period) %>% 
  summarise(Value = sum(Value), .groups = "drop") %>% 
  complete(scen, Chart_Desc, period_list, fill = list(Value = 0)) %>% 
  mutate(data_group = "Electricity", Attribute = "Capacity in GW")

# Primary -----------------------------------------------------------------

primary_raw <- inner_join(schema_primary, raw_df, by = c("Attribute", "Commodity", "Process")) %>% 
  # In order to do net = domestic + imports - exports balance, create column with values multiplied by coefficients
  # Coefficient_for_balance == 1 for domestic and imports, -1 for exports
  mutate(NetValue = Coefficient_for_balance * Value)

# Primary energy supply - All
primary_nrg <- primary_raw %>% 
  group_by(scen, Chart_Desc, Period) %>% 
  summarise(Value = sum(NetValue), .groups = "drop") %>% 
  complete(scen, Chart_Desc, period_list, fill = list(Value = 0)) %>% 
  mutate(data_group = "Primary Energy", Attribute = "Domestic")

# Primary energy supply - net imports
primary_imp <- primary_raw %>% 
  filter(Source %in% c("IMP", "EXP")) %>% 
  group_by(scen, Chart_Desc, Period) %>% 
  summarise(Value = sum(NetValue), .groups = "drop") %>%
  complete(scen, Chart_Desc, period_list, fill = list(Value = 0)) %>% 
  mutate(data_group = "Primary Energy", Attribute = "Net Imports")

# Primary energy supply - domestic gas production
primary_gas <- primary_raw %>% 
  filter(Commodity == "NGA") %>% 
  group_by(scen, Resource_Name, Period) %>% 
  summarise(Value = sum(Value), .groups = "drop") %>% 
  complete(scen, Resource_Name, period_list, fill = list(Value = 0)) %>% 
  mutate(data_group = "Primary Energy", Attribute = "Gas Resources")


# Energy ------------------------------------------------------------------

energy_raw <- bind_rows(inner_join(schema_energy, raw_df, by = c("Attribute","Commodity")),
                        inner_join(schema_specific, raw_df, by = c("Attribute","Commodity","Process")))

# Energy use - all
energy_nrg <- energy_raw %>% 
  group_by(scen, Commodity2, Sector_Set, Fuel_Desc, Fuel_HighLevel, Period) %>% 
  summarise(Value = sum(Value), .groups = "drop") %>% 
  complete(scen, nesting(Commodity2, Sector_Set, Fuel_Desc, Fuel_HighLevel), period_list, fill = list(Value = 0)) %>% 
  mutate(Attribute = "PJ")

# Energy use - residential/commercial
energy_svc <- energy_raw %>% 
  filter(Sector_Set %in% c("Residential", "Commercial")) %>% 
  inner_join(schema_tech, by = c("Process", "Sector_Set")) %>%
  group_by(scen, Service, Sector_Set, Fuel_Desc, Period) %>% 
  summarise(Value = sum(Value), .groups = "drop") %>% 
  complete(scen, nesting(Service, Sector_Set, Fuel_Desc), period_list, fill = list(Value = 0)) %>% 
  mutate(data_group = "RES and COM Services", Attribute = "PJ")

# Renewables --------------------------------------------------------------

# renewable energy proportions
#   first part is Electricity renewable proportion
renew_pc <- electricity_gen %>%
  group_by(scen, Period) %>% 
  summarise(renew_ele = sum(if_else(Chart_Desc %in% c("Coal","Coal+CCS","Cogen","Gas","Gas+CCS"), 0, Value)),
            fossil_ele = sum(if_else(Chart_Desc %in% c("Coal","Coal+CCS","Cogen","Gas","Gas+CCS"), Value, 0)),
            total_ele = sum(Value),
            .groups = "drop") %>% 
  mutate(Value = renew_ele / total_ele,
         Fuel = "Electricity") %>% 
  union_all(., 
            # this second part is all other renewables
            inner_join(., 
                       energy_nrg %>% 
                         group_by(scen, Period) %>% 
                         summarise(renew_nrg = sum(if_else(Fuel_HighLevel %in% c("Coal","Oil Products","Natural Gas"), 0, Value)),
                                   fossil_nrg = sum(if_else(Fuel_HighLevel %in% c("Coal","Oil Products","Natural Gas"), Value, 0)),
                                   total_nrg = sum(Value),
                                   .groups = "drop"),
                       by = c("scen", "Period")) %>% 
              mutate(Value = 1 - (fossil_nrg + fossil_ele) / total_nrg,
                     Fuel = "Energy")) %>%
  select(scen, Period, Value, Fuel) %>% 
  mutate(data_group = "Renewables", Attribute = "Renewable percent")

# Industrial --------------------------------------------------------------

industrial_raw <- inner_join(schema_industrial, raw_df, by = c("Attribute", "Commodity", "Process"))

# Industrial energy use by sub-sector
industrial_nrg <- industrial_raw %>% 
  group_by(scen, Sector_Set, Fuel_Desc, Period) %>% 
  summarise(Value = sum(Value), .groups = "drop") %>% 
  #complete(scen, nesting(Sector_Set, Fuel_Desc), period_list, fill = list(Value = 0))
  mutate(data_group = "Industry - detailed", Attribute = "PJ")


# Emissions ---------------------------------------------------------------

emissisions_raw <- inner_join(schema_emissions, raw_df, by = c("Attribute", "Commodity", "Process"))

# CO2 Emissions by sector/fuel
emissions_co2 <- emissisions_raw %>% 
  group_by(scen, Technology, Fuel, Sector, Period) %>% 
  summarise(Value = sum(Value), .groups = "drop") %>% 
  #complete(scen, nesting(Technology, Fuel, Sector), period_list, fill = list(Value = 0))
  mutate(data_group = "Emissions", Attribute = "tCO2")

# Commodity prices --------------------------------------------------------

prices_raw <- inner_join(schema_prices, raw_df, by = c("Attribute", "Commodity")) %>% 
  inner_join(schema_weights, by = c("TimeSlice", "Region"))

# Energy and electricity prices
prices_nrg <- prices_raw %>% 
  filter(Period != 2015) %>% 
  mutate(WeightedPrice = TimeWeight * Value) %>% 
  group_by(scen, Fuel_Desc, Period, Region) %>% 
  summarise(Value = sum(WeightedPrice), .groups = "drop") %>%
  bind_rows(.,
            filter(., Fuel_Desc == "Electricity") %>% 
              mutate(Value = Value * 3.6,
                     Fuel_Desc = "Electricity - $/MWh")) %>% 
  mutate(data_group = "Prices", Attribute = "$/GJ")


# Supplementary Processes -------------------------------------------------

# Left join here as it appears not all the options always appear in the data
supplem_raw <- left_join(schema_supplem, raw_df, by = c("Attribute", "Commodity", "Process"))

# Other transformations
supplem_out <- supplem_raw %>% 
  group_by(scen, Chart_Desc, Sector, Period) %>% 
  summarise(Value = sum(Value), .groups = "drop") %>% 
  complete(scen, nesting(Chart_Desc, Sector), period_list, fill = list(Value = 0)) %>% 
  filter(!is.na(scen)) %>% # Artefact of the left join
  mutate(data_group = "Primary Energy", Attribute = "Supplementary Processes")
  


# Efficiency --------------------------------------------------------------

service_raw <- inner_join(schema_eff, raw_df, by = c("Attribute", "Commodity"))
demand_raw <- inner_join(schema_sets, raw_df, by = c("Attribute", "Process"))

# Energy savings through efficiency
efficiency_nrg <- inner_join(service_raw %>% # Below used to estimate growth in services (based on GDP/population etc)
                               group_by(scen, Commodity, Sector, Period) %>% 
                               summarise(Service = sum(Value), .groups = "drop_last") %>% 
                               complete(scen, nesting(Commodity, Sector), period_list, fill = list(Service = 0)) %>%
                               group_by(scen, Commodity, Sector) %>% 
                               mutate(Serv_growth = Service / sum(if_else(Period == 2015, Service, 0))) %>%
                               ungroup(),
                             demand_raw %>% # Below is modelled energy use
                               group_by(scen, Commodity = Cset, Period) %>% 
                               summarise(Demand = sum(Value), .groups = "drop") %>% 
                               complete(scen, Commodity, period_list, fill = list(Demand = 0)),
                             by = c("scen", "Commodity", "Period")) %>%
  group_by(scen, Commodity, Sector) %>%
  mutate(NoEff_Dem = Serv_growth * sum(if_else(Period == 2015, Demand, 0)), # Energy demand if no efficiency (based on service growth above)
         Efficiency = NoEff_Dem - Demand) %>% # Energy saved via efficiencies is the difference between the above and modelled demand
  ungroup() %>%
  mutate(data_group = "Efficiency", Attribute = "PJ")

# Costs -------------------------------------------------------------------

costs_raw <- inner_join(schema_costs, raw_df, by = "Process") %>% 
  filter(Attribute %in% c("Cap_New","Cost_Cap","Cost_Comx","Cost_Fom","Cost_Inv","Cost_Act"))

# Modelled costs
costs_all <- costs_raw %>% 
  group_by(scen, Sector, Attribute, Period) %>% 
  summarise(Value = sum(Value), .groups = "drop") %>% 
  mutate(data_group = "Costs")

# Combine for export ------------------------------------------------------

combined_df <-  
  bind_rows(transport_num %>% select(data_group, Period, Attribute, Sector = Type, Technology = Chart_Desc, Value, scen),
            transport_nrg %>% select(data_group, Period, Attribute, Sector = Type, Technology = Chart_Desc, Value, scen),
            electricity_gen %>% select(data_group, Period, Attribute, Fuel = Chart_Desc, Value, scen),
            electricity_cap %>%  select(data_group, Period, Attribute, Fuel = Chart_Desc, Value, scen),
            primary_nrg %>% select(data_group, Period, Attribute, Fuel = Chart_Desc, Value, scen),
            primary_imp %>% select(data_group, Period, Attribute, Fuel = Chart_Desc, Value, scen),
            primary_gas %>% select(data_group, Period, Attribute, Fuel = Resource_Name, Value, scen),
            energy_nrg %>% mutate(data_group = "Energy - detailed") %>%
              select(data_group, Period, Attribute, Sector = Sector_Set, Fuel = Fuel_Desc, Value, scen),
            energy_nrg %>% mutate(data_group = "Energy - high level") %>%
              select(data_group, Period, Attribute, Sector = Sector_Set, Fuel = Fuel_HighLevel, Value, scen),
            energy_svc %>% select(data_group, Period, Attribute, Sector = Sector_Set, Technology = Service, Fuel = Fuel_Desc, Value, scen),
            renew_pc %>% select(data_group, Period, Attribute, Fuel, Value, scen),
            industrial_nrg %>% select(data_group, Period, Attribute, Sector = Sector_Set, Fuel = Fuel_Desc, Value, scen),
            emissions_co2 %>% select(data_group, Period, Attribute, Sector, Technology, Fuel, Value, scen),
            supplem_out %>% select(data_group, Period, Attribute, Sector, Technology = Chart_Desc, Value, scen),
            efficiency_nrg %>% select(data_group, Period, Attribute, Sector, Technology = Commodity, Value = Efficiency, scen),
            costs_all %>% select(data_group, Period, Attribute, Sector, Value, scen))

prices_df <- prices_nrg %>% 
    select(data_group, Period, Attribute, Sector = Region, Fuel = Fuel_Desc, Value, scen)

supplem_list <- distinct(schema_supplem, Chart_Desc)
fuel_list <- distinct(schema_energy, Fuel = Fuel_HighLevel)
sector_list <- distinct(schema_energy, Sector = Sector_Set)

assumptions_df <- read_excel(path = "Assumptions.xlsx", sheet = "Sheet1") %>% # extract assumptions for charting
  gather(Period, Value, `2020`:`2060`) %>% 
  mutate(across(c(tool_tip_pre, tool_tip_trail), ~replace_na(., "")))

assumptions_list <- distinct(assumptions_df, Parameter)

#Create the R data set for Shiny to use
save(combined_df, # data for charting
     supplem_list, # list of supplementary processes for input$supplem_type drop down
     fuel_list,  # list of fuel for input$fuel_choice drop down
     sector_list,  # list of Sectors for input$sector_choice drop down
     assumptions_df,  # data behind assumptions
     assumptions_list,  # list of assumptions for input$assumptions drop-down
     prices_df,  # data on prices for charting
     file = "..\\TIMES\\data\\data_for_shiny.rda")