"""
Defines rulesets used for data processing and transformation in the project. Each ruleset consists of rules that are
used to set values in the schema DataFrame based on conditions.

Each rule is a tuple containing a condition dictionary and an actions dictionary.
The condition dictionary contains key-value pairs that must match the DataFrame row.
The actions dictionary contains key-value pairs to set in the schemaDataFrame row.

Rulesets are defined as lists of tuples. Each tuple contains a condition dictionary, specifying the criteria a row must
meet for the rule to apply, and an actions dictionary, specifying the updates to be made to the row when the condition
is met. When a ruleset is applied, rules are applied in order of specificity, from least to most specific.
A more specific rule's condition dictionary has a superset of the keys of a less specific one.

When a sequence of rulesets is applied, later rulesets can override the effects of earlier ones.

These rulesets are applied in a sequence determined by the RULESETS list (defined at the end of this module)
to ensure data consistency and completeness.
"""
import os

from constants import *
from helpers import *

schema = pd.read_csv(REFERENCE_SCHEMA_FILEPATH).drop_duplicates()
schema = schema[OUT_COLS].dropna().drop_duplicates().sort_values(by=OUT_COLS)

## Generate rulesets for 'Set' attributes and descriptions
#commodity_set_rules = itemlist_column_to_ruleset(
#    COMMODITY_TO_SET["Items-List-CSV"],
#    COMMODITY_TO_SET["ParseColumn"],
#    COMMODITY_TO_SET["Schema"],
#    COMMODITY_TO_SET["MatchColumn"],
#)

#process_set_rules = itemlist_column_to_ruleset(
#    PROCESS_TO_SET["Items-List-CSV"],
#    PROCESS_TO_SET["ParseColumn"],
#    PROCESS_TO_SET["Schema"],
#    PROCESS_TO_SET["MatchColumn"],
#)

commodity_rules = itemlist_column_to_ruleset(
    COMMODITY_TO_SECTOR_SUBSECTOR_FUEL_ENDUSE["Items-List-CSV"],
    COMMODITY_TO_SECTOR_SUBSECTOR_FUEL_ENDUSE["ParseColumn"],
    COMMODITY_TO_SECTOR_SUBSECTOR_FUEL_ENDUSE["Schema"],
    COMMODITY_TO_SECTOR_SUBSECTOR_FUEL_ENDUSE["MatchColumn"],
)

process_rules = itemlist_column_to_ruleset(
    PROCESS_TO_SECTOR_SUBSECTOR_FUEL_ENDUSE["Items-List-CSV"],
    PROCESS_TO_SECTOR_SUBSECTOR_FUEL_ENDUSE["ParseColumn"],
    PROCESS_TO_SECTOR_SUBSECTOR_FUEL_ENDUSE["Schema"],
    PROCESS_TO_SECTOR_SUBSECTOR_FUEL_ENDUSE["MatchColumn"],
)

process_baseyear_rules = generate_augmented_ruleset(process_rules)

# Rules for assigning units to commodities based on the TIMES base.dd definitions
commodity_unit_rules = base_dd_commodity_unit_rules(BASE_DD_FILEPATH)

# Predefined rules for mapping fuels to their respective fuel groups
FUEL_TO_FUELGROUP_RULES = [
    # Each tuple consists of a condition (e.g., {"Fuel": "Electricity"}) and an action (e.g., {"FuelGroup": "Electricity"}).
    ({"Fuel": "Electricity"}, {"FuelGroup": "Electricity"}),
    ({"Fuel": "Green Hydrogen"}, {"FuelGroup": "Electricity"}),
    ({"Fuel": "Coal"}, {"FuelGroup": "Fossil Fuels"}),
    ({"Fuel": "Diesel"}, {"FuelGroup": "Fossil Fuels"}),
    ({"Fuel": "Fuel Oil"}, {"FuelGroup": "Fossil Fuels"}),
    ({"Fuel": "Jet Fuel"}, {"FuelGroup": "Fossil Fuels"}),
    ({"Fuel": "LPG"}, {"FuelGroup": "Fossil Fuels"}),
    ({"Fuel": "Natural Gas"}, {"FuelGroup": "Fossil Fuels"}),
    ({"Fuel": "Petrol"}, {"FuelGroup": "Fossil Fuels"}),
    ({"Fuel": "Waste Incineration"}, {"FuelGroup": "Fossil Fuels"}),
    ({"Fuel": "Biodiesel"}, {"FuelGroup": "Renewables (direct use)"}),
    ({"Fuel": "Biogas"}, {"FuelGroup": "Renewables (direct use)"}),
    ({"Fuel": "Drop-In Diesel"}, {"FuelGroup": "Renewables (direct use)"}),
    ({"Fuel": "Drop-In Jet"}, {"FuelGroup": "Renewables (direct use)"}),
    ({"Fuel": "Geothermal"}, {"FuelGroup": "Renewables (direct use)"}),
    ({"Fuel": "Hydro"}, {"FuelGroup": "Renewables (direct use)"}),
    ({"Fuel": "Solar"}, {"FuelGroup": "Renewables (direct use)"}),
    ({"Fuel": "Wind"}, {"FuelGroup": "Renewables (direct use)"}),
    ({"Fuel": "Wood"}, {"FuelGroup": "Renewables (direct use)"}),
]

# Predefined rules for setting the unit of capacity based on the sector
SECTOR_CAPACITY_RULES = [
    # Each tuple consists of a condition (e.g., {"Attribute": "VAR_Cap", "Sector": "Transport"}) and an action (e.g., {"Unit": "000 Vehicles"}).
    ({"Attribute": "VAR_Cap", "Sector": "Transport"}, {"Unit": "000 Vehicles"}),
    ({"Attribute": "VAR_Cap", "Sector": "Industry"}, {"Unit": "GW"}),
    ({"Attribute": "VAR_Cap", "Sector": "Commercial"}, {"Unit": "GW"}),
    ({"Attribute": "VAR_Cap", "Sector": "Agriculture"}, {"Unit": "GW"}),
    ({"Attribute": "VAR_Cap", "Sector": "Residential"}, {"Unit": "GW"}),
    ({"Attribute": "VAR_Cap", "Sector": "Electricity"}, {"Unit": "GW"}),
    ({"Attribute": "VAR_Cap", "Sector": "Green Hydrogen"}, {"Unit": "GW"}),
]

# General parameter rules for processing data, including basic and specific categorizations
PARAMS_RULES = [
    # Basic Rules
    ({"Attribute": "VAR_Cap", "Unit": "000 Vehicles"}, {"Parameters": "Number of Vehicles"}),
    ({"Attribute": "VAR_FIn", "Unit": "PJ"}, {"Parameters": "Fuel Consumption"}),
    ({"Attribute": "VAR_FOut", "Unit": "Billion Vehicle Kilometres"}, {"Parameters": "Distance Travelled"}),
    ({"Attribute": "VAR_Cap", "Unit": "GW"}, {"Parameters": "Technology Capacity"}),
    ({"Attribute": "VAR_FOut", "Unit": "kt CO2"}, {"Parameters": "Emissions"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ"}, {"Parameters": "End Use Demand"}),
    # Specific Rules
    ({"Attribute": "VAR_FIn", "Unit": "PJ", "Process": "MTHOL-FDSTCK-NGA-FDSTCK"}, {"Parameters": "Feedstock"}),
    ({"Attribute": "VAR_FIn", "Unit": "PJ", "Process": "UREA-FDSTCK-NGA-FDSTCK"}, {"Parameters": "Feedstock"}),
    ({"Attribute": "VAR_FIn", "Unit": "PJ", "Process": "UREA-FDSTCK-NGA-FDSTCK15"}, {"Parameters": "Feedstock"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EBAT-Li-Ion"}, {"Parameters": "Grid Injection (from Storage)"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EHYDPUMPSTG_L"}, {"Parameters": "Grid Injection (from Storage)"}),
    ({"Attribute": "VAR_FIn", "Unit": "PJ", "Process": "EBAT-Li-Ion"}, {"Parameters": "Gross Electricity Storage"}),
    ({"Attribute": "VAR_FIn", "Unit": "PJ", "Process": "EHYDPUMPSTG_L"}, {"Parameters": "Gross Electricity Storage"}),
    ({"Attribute": "VAR_FIn", "Unit": "PJ", "Process": "IIS-FDSTCK-COA-_", "Commodity": "COA"}, {"Parameters": "Feedstock"}),
    ({"Attribute": "VAR_FIn", "Unit": "PJ", "Process": "IIS-FDSTCK-COA-_15", "Commodity": "COA"}, {"Parameters": "Feedstock"}),
    ({"Attribute": "VAR_FIn", "Unit": "PJ", "Process": "MTHOL-FDSTCK-NGA-FDSTCK15", "Commodity": "NGA"}, {"Parameters": "Feedstock"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EGEOCONSFLSH20"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EGEOFLSH20"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EHYD-DAM-New20"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EHYD-RR-NSmall20"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EHYD-RR-New20"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCREGEO00"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCREHYDDAM00"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCREHYDRRFlex00"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCREHYDRRInflex00"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCRESOL00"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCREWind00"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCREWindMV00"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCTECOA00"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCTENGACCGT00"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCTENGACHP00"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCTENGAOCGT00"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ENGA_GTCC20"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ENGA_GTCCF20"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ESOLPVBCOM20"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ESOLPVUTIFIX20"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ESOLPVUTITRAC20"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EWINDCONS20"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EWINDDIST20"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EWINDHIGHCF20"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EWINDLOWCF20"}, {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EWSTINC20"}, {"Parameters": "Electricity Generation"})
]

# Aggregating all rulesets for application in the processing script in the specified order
RULESETS = [
    ("process_baseyear_rules", process_baseyear_rules), # process rules but with '00' appended at the end of the process name
    ("process_rules", process_rules),
    ("commodity_unit_rules", commodity_unit_rules),
    ("FUEL_TO_FUELGROUP_RULES", FUEL_TO_FUELGROUP_RULES),
    ("SECTOR_CAPACITY_RULES", SECTOR_CAPACITY_RULES),
    ("PARAMS_RULES", PARAMS_RULES),
]