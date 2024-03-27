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


# Replace with the correct project_base_path variable initialization if necessary
project_base_path = get_project_base_path()

# Generate rulesets for 'Set' attributes and descriptions
commodity_set_rules = itemlist_column_to_ruleset(
    COMMODITY_TO_SET["Items-List-CSV"],
    COMMODITY_TO_SET["ParseColumn"],
    COMMODITY_TO_SET["Schema"],
    COMMODITY_TO_SET["MatchColumn"]
)

process_set_rules = itemlist_column_to_ruleset(
    PROCESS_TO_SET["Items-List-CSV"],
    PROCESS_TO_SET["ParseColumn"],
    PROCESS_TO_SET["Schema"],
    PROCESS_TO_SET["MatchColumn"]
)

commodity_rules = itemlist_column_to_ruleset(
    COMMODITY_TO_SECTOR_SUBSECTOR_FUEL_ENDUSE["Items-List-CSV"],
    COMMODITY_TO_SECTOR_SUBSECTOR_FUEL_ENDUSE["ParseColumn"],
    COMMODITY_TO_SECTOR_SUBSECTOR_FUEL_ENDUSE["Schema"],
    COMMODITY_TO_SECTOR_SUBSECTOR_FUEL_ENDUSE["MatchColumn"]
)

process_rules = itemlist_column_to_ruleset(
    PROCESS_TO_SECTOR_SUBSECTOR_FUEL_ENDUSE["Items-List-CSV"],
    PROCESS_TO_SECTOR_SUBSECTOR_FUEL_ENDUSE["ParseColumn"],
    PROCESS_TO_SECTOR_SUBSECTOR_FUEL_ENDUSE["Schema"],
    PROCESS_TO_SECTOR_SUBSECTOR_FUEL_ENDUSE["MatchColumn"]
)

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
    (
        {"Attribute": "VAR_Cap", "Unit": "000 Vehicles"},
        {"Parameters": "Number of Vehicles"},
    ),
    (
        {"Attribute": "VAR_FIn", "Unit": "PJ", "Set": "NRG"},
        {"Parameters": "Fuel Consumption"},
    ),
    (
        {"Attribute": "VAR_FOut", "Unit": "Billion Vehicle Kilometres"},
        {"Parameters": "Distance Travelled"},
    ),
    (
        {"Attribute": "VAR_Cap", "Unit": "GW", "Set": ".DMD."},
        {"Parameters": "Technology Capacity"},
    ),
    ({"Attribute": "VAR_FOut", "Unit": "kt CO2"}, {"Parameters": "Emissions"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ"}, {"Parameters": "End Use Demand"}),
    # Specific Rules
    (
        {
            "Attribute": "VAR_FIn",
            "Unit": "PJ",
            "Set": "NRG",
            "Process": "MTHOL-FDSTCK-NGA-FDSTCK",
        },
        {"Parameters": "Feedstock"},
    ),
    (
        {
            "Attribute": "VAR_FIn",
            "Unit": "PJ",
            "Set": "NRG",
            "Process": "UREA-FDSTCK-NGA-FDSTCK",
        },
        {"Parameters": "Feedstock"},
    ),
    (
        {
            "Attribute": "VAR_FIn",
            "Unit": "PJ",
            "Set": "NRG",
            "Process": "UREA-FDSTCK-NGA-FDSTCK15",
        },
        {"Parameters": "Feedstock"},
    ),
    (
        {"Attribute": "VAR_FOut", "Unit": "PJ", "Set": "NRG", "Process": "EBAT-Li-Ion"},
        {"Parameters": "Grid Injection (from Storage)"},
    ),
    (
        {
            "Attribute": "VAR_FOut",
            "Unit": "PJ",
            "Set": "NRG",
            "Process": "EHYDPUMPSTG_L",
        },
        {"Parameters": "Grid Injection (from Storage)"},
    ),
    (
        {"Attribute": "VAR_FIn", "Unit": "PJ", "Set": "NRG", "Process": "EBAT-Li-Ion"},
        {"Parameters": "Gross Electricity Storage"},
    ),
    (
        {
            "Attribute": "VAR_FIn",
            "Unit": "PJ",
            "Set": "NRG",
            "Process": "EHYDPUMPSTG_L",
        },
        {"Parameters": "Gross Electricity Storage"},
    ),
]

# Aggregating all rulesets for application in the processing script in the specified order
RULESETS = [
    commodity_set_rules,
    process_set_rules,
    commodity_rules,
    process_rules,
    commodity_unit_rules,
    FUEL_TO_FUELGROUP_RULES,
    SECTOR_CAPACITY_RULES,
    PARAMS_RULES,
]
