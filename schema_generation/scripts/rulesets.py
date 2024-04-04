"""
Defines rulesets used for data processing and transformation in the project. Each ruleset consists of rules that are
used to set values in the schema DataFrame based on conditions.

Each rule is a tuple containing a condition dictionary, a rule_type, and an actions dictionary.
* The condition dictionary contains key-value pairs that must match the DataFrame row.
* The rule_type - either 'inplace' or 'newrow' - specifies whether the rule should update the existing row or a copy of it.
* The actions dictionary contains key-value pairs to set in the schema DataFrame row.

Rulesets are defined as lists of tuples. When a ruleset is applied, rules are applied in order of specificity, from least
to most specific. A more specific rule's condition dictionary has a superset of the keys of a less specific one.

When a sequence of rulesets is applied, later rulesets can override the effects of earlier ones.

The rulesets are applied in a sequence determined by the RULESETS list (defined at the end of this module)
to ensure data consistency and completeness.
"""
import pandas as pd
from constants import *
from helpers import *

schema = pd.read_csv(REFERENCE_SCHEMA_FILEPATH).drop_duplicates()
schema = schema[OUT_COLS].dropna().drop_duplicates().sort_values(by=OUT_COLS)

# Not currently being used. TODO: Could "Set" membership allow the "Parameters" column to be inferred, simplifying PARAMS_RULES?
# Generate rulesets for 'Set' attributes and descriptions
commodity_set_rules = csv_columns_to_ruleset(
    filepath=ITEMS_LIST_COMMODITY_CSV,
    target_column_map={"Name": "Commodity"},
    parse_column="Set",
    separator="-:-",
    schema=["Set"],
    rule_type="inplace",
)

process_set_rules = csv_columns_to_ruleset(
    filepath=ITEMS_LIST_PROCESS_CSV,
    target_column_map={"Name": "Process"},
    parse_column="Set",
    separator="-:-",
    schema=["Set"],
    rule_type="inplace",
)

commodity_rules = csv_columns_to_ruleset(
    filepath=ITEMS_LIST_COMMODITY_CSV,
    target_column_map={"Name": "Commodity"},
    parse_column="Description",
    separator="-:-",
    schema=["NA1", "NA2", "Fuel", "NA3"], # ["Fuel", "Enduse"],
    rule_type="inplace",
)

process_rules = csv_columns_to_ruleset(
    filepath=ITEMS_LIST_PROCESS_CSV,
    target_column_map={"Name": "Process"},
    parse_column="Description",
    separator="-:-",
    schema=["Sector", "Subsector", "Enduse", "Technology", "Fuel"], # "ParametersOverride", "DisplayCapacity"
    rule_type="inplace",
)

# Rules for assigning units to commodities based on the TIMES base.dd definitions
commodity_unit_rules = base_dd_commodity_unit_rules(
    filepath=BASE_DD_FILEPATH,
    rule_type="inplace",
    )

# Predefined rules for mapping fuels to their respective fuel groups
FUEL_TO_FUELGROUP_RULES = [
    # Each tuple consists of a condition (e.g., {"Fuel": "Electricity"}) and an action (e.g., {"FuelGroup": "Electricity"}).
    ({"Fuel": "Electricity"}, "inplace", {"FuelGroup": "Electricity"}),
    ({"Fuel": "Green Hydrogen"}, "inplace", {"FuelGroup": "Electricity"}),
    ({"Fuel": "Coal"}, "inplace", {"FuelGroup": "Fossil Fuels"}),
    ({"Fuel": "Diesel"}, "inplace", {"FuelGroup": "Fossil Fuels"}),
    ({"Fuel": "Fuel Oil"}, "inplace", {"FuelGroup": "Fossil Fuels"}),
    ({"Fuel": "Jet Fuel"}, "inplace", {"FuelGroup": "Fossil Fuels"}),
    ({"Fuel": "LPG"}, "inplace", {"FuelGroup": "Fossil Fuels"}),
    ({"Fuel": "Natural Gas"}, "inplace", {"FuelGroup": "Fossil Fuels"}),
    ({"Fuel": "Petrol"}, "inplace", {"FuelGroup": "Fossil Fuels"}),
    ({"Fuel": "Waste Incineration"}, "inplace", {"FuelGroup": "Fossil Fuels"}),
    ({"Fuel": "Biodiesel"}, "inplace", {"FuelGroup": "Renewables (direct use)"}),
    ({"Fuel": "Biogas"}, "inplace", {"FuelGroup": "Renewables (direct use)"}),
    ({"Fuel": "Drop-In Diesel"}, "inplace", {"FuelGroup": "Renewables (direct use)"}),
    ({"Fuel": "Drop-In Jet"}, "inplace", {"FuelGroup": "Renewables (direct use)"}),
    ({"Fuel": "Geothermal"}, "inplace", {"FuelGroup": "Renewables (direct use)"}),
    ({"Fuel": "Hydro"}, "inplace", {"FuelGroup": "Renewables (direct use)"}),
    ({"Fuel": "Solar"}, "inplace", {"FuelGroup": "Renewables (direct use)"}),
    ({"Fuel": "Wind"}, "inplace", {"FuelGroup": "Renewables (direct use)"}),
    ({"Fuel": "Wood"}, "inplace", {"FuelGroup": "Renewables (direct use)"}),
]

# Predefined rules for setting the unit of capacity based on the sector
SECTOR_CAPACITY_RULES = [
    # Each tuple consists of a condition (e.g., {"Attribute": "VAR_Cap", "Sector": "Transport"}) and an action (e.g., {"Unit": "000 Vehicles"}).
    ({"Attribute": "VAR_Cap", "Sector": "Transport"}, "inplace", {"Unit": "000 Vehicles"}),
    ({"Attribute": "VAR_Cap", "Sector": "Industry"}, "inplace", {"Unit": "GW"}),
    ({"Attribute": "VAR_Cap", "Sector": "Commercial"}, "inplace", {"Unit": "GW"}),
    ({"Attribute": "VAR_Cap", "Sector": "Agriculture"}, "inplace", {"Unit": "GW"}),
    ({"Attribute": "VAR_Cap", "Sector": "Residential"}, "inplace", {"Unit": "GW"}),
    ({"Attribute": "VAR_Cap", "Sector": "Electricity"}, "inplace", {"Unit": "GW"}),
    ({"Attribute": "VAR_Cap", "Sector": "Green Hydrogen"}, "inplace", {"Unit": "GW"}),
    ({"Attribute": "VAR_Cap", "Sector": "Primary Fuel Supply"}, "inplace", {"Unit": "GW"}),
]

# General parameter rules for processing data, including basic and specific categorizations
PARAMS_RULES = [
    # Basic Rules
    ({"Attribute": "VAR_Cap", "Unit": "000 Vehicles"}, "inplace", {"Parameters": "Number of Vehicles"}),
    ({"Attribute": "VAR_FIn", "Unit": "PJ"}, "inplace", {"Parameters": "Fuel Consumption"}),
    ({"Attribute": "VAR_FOut", "Unit": "Billion Vehicle Kilometres"}, "inplace", {"Parameters": "Distance Travelled"}),
    ({"Attribute": "VAR_Cap", "Unit": "GW"}, "inplace", {"Parameters": "Technology Capacity"}),
    ({"Attribute": "VAR_FOut", "Unit": "kt CO2"}, "inplace", {"Parameters": "Emissions"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ"}, "inplace", {"Parameters": "End Use Demand"}),
    # Specific Rules
    ({"Attribute": "VAR_FIn", "Unit": "PJ", "Process": "MTHOL-FDSTCK-NGA-FDSTCK"}, "inplace", {"Parameters": "Feedstock"}),
    ({"Attribute": "VAR_FIn", "Unit": "PJ", "Process": "UREA-FDSTCK-NGA-FDSTCK"}, "inplace", {"Parameters": "Feedstock"}),
    ({"Attribute": "VAR_FIn", "Unit": "PJ", "Process": "UREA-FDSTCK-NGA-FDSTCK15"}, "inplace", {"Parameters": "Feedstock"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EBAT-Li-Ion"}, "inplace", {"Parameters": "Grid Injection (from Storage)"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EHYDPUMPSTG_L"}, "inplace", {"Parameters": "Grid Injection (from Storage)"}),
    ({"Attribute": "VAR_FIn", "Unit": "PJ", "Process": "EBAT-Li-Ion"}, "inplace", {"Parameters": "Gross Electricity Storage"}),
    ({"Attribute": "VAR_FIn", "Unit": "PJ", "Process": "EHYDPUMPSTG_L"}, "inplace", {"Parameters": "Gross Electricity Storage"}),
    ({"Attribute": "VAR_FIn", "Unit": "PJ", "Process": "IIS-FDSTCK-COA-_", "Commodity": "COA"}, "inplace", {"Parameters": "Feedstock"}),
    ({"Attribute": "VAR_FIn", "Unit": "PJ", "Process": "IIS-FDSTCK-COA-_15", "Commodity": "COA"}, "inplace", {"Parameters": "Feedstock"}),
    ({"Attribute": "VAR_FIn", "Unit": "PJ", "Process": "MTHOL-FDSTCK-NGA-FDSTCK15", "Commodity": "NGA"}, "inplace", {"Parameters": "Feedstock"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EGEOCONSFLSH20"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EGEOFLSH20"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EHYD-DAM-New20"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EHYD-RR-NSmall20"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EHYD-RR-New20"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCREGEO00"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCREHYDDAM00"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCREHYDRRFlex00"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCREHYDRRInflex00"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCRESOL00"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCREWind00"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCREWindMV00"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCTECOA00"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCTENGACCGT00"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCTENGACHP00"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ELCTENGAOCGT00"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ENGA_GTCC20"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ENGA_GTCCF20"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ESOLPVBCOM20"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ESOLPVUTIFIX20"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "ESOLPVUTITRAC20"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EWINDCONS20"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EWINDDIST20"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EWINDHIGHCF20"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EWINDLOWCF20"}, "inplace", {"Parameters": "Electricity Generation"}),
    ({"Attribute": "VAR_FOut", "Unit": "PJ", "Process": "EWSTINC20"}, "inplace", {"Parameters": "Electricity Generation"})
]

# Rules for adding direct emissions rows for each sector
DIRECT_EMISSIONS_RULES = [
({'Attribute': 'VAR_FIn', 'Sector': 'Transport', 'FuelGroup': 'Fossil Fuels'}, "newrow", {'Attribute': 'VAR_FOut', 'Commodity': 'TRACO2', 'Unit': 'kt CO2'}),
({'Attribute': 'VAR_FIn', 'Sector': 'Industry', 'FuelGroup': 'Fossil Fuels'}, "newrow", {'Attribute': 'VAR_FOut', 'Commodity': 'INDCO2', 'Unit': 'kt CO2'}),
({'Attribute': 'VAR_FIn', 'Sector': 'Commercial', 'FuelGroup': 'Fossil Fuels'}, "newrow", {'Attribute': 'VAR_FOut', 'Commodity': 'COMCO2', 'Unit': 'kt CO2'}),
({'Attribute': 'VAR_FIn', 'Sector': 'Agriculture', 'FuelGroup': 'Fossil Fuels'}, "newrow", {'Attribute': 'VAR_FOut', 'Commodity': 'AGRCO2', 'Unit': 'kt CO2'}),
({'Attribute': 'VAR_FIn', 'Sector': 'Residential', 'FuelGroup': 'Fossil Fuels'}, "newrow", {'Attribute': 'VAR_FOut', 'Commodity': 'RESCO2', 'Unit': 'kt CO2'}),
({'Attribute': 'VAR_FIn', 'Sector': 'Electricity', 'FuelGroup': 'Fossil Fuels'}, "newrow", {'Attribute': 'VAR_FOut', 'Commodity': 'ELCCO2', 'Unit': 'kt CO2'}),
]

# Aggregating all rulesets for application in the processing script in the specified order
RULESETS = [
    ("process_rules", process_rules),
    ("commodity_rules", commodity_rules),
    ("commodity_unit_rules", commodity_unit_rules),
    ("FUEL_TO_FUELGROUP_RULES", FUEL_TO_FUELGROUP_RULES),
    ("SECTOR_CAPACITY_RULES", SECTOR_CAPACITY_RULES),
    ("PARAMS_RULES", PARAMS_RULES),
    ("DIRECT_EMISSIONS_RULES", DIRECT_EMISSIONS_RULES),
]

MISSING_ROWS = pd.DataFrame([
    {'Attribute':  'VAR_FIn', 'Process':     'FTE-INDDSL_00', 'Commodity':      'DID', 'Sector':    'Industry', 'Subsector':             'Mining', 'Technology': 'Internal Combustion Engine', 'Fuel': 'Drop-In Diesel', 'Enduse':   'Motive Power, Mobile', 'Unit':     'PJ', 'Parameters': 'Fuel Consumption', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute':  'VAR_FIn', 'Process':        'FTE_TRADSL', 'Commodity':     'BDSL', 'Sector':   'Transport', 'Subsector':               'Rail', 'Technology':                      'Train', 'Fuel':      'Biodiesel', 'Enduse':           'Freight Rail', 'Unit':     'PJ', 'Parameters': 'Fuel Consumption', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute':  'VAR_FIn', 'Process':        'FTE_TRADSL', 'Commodity':     'BDSL', 'Sector':   'Transport', 'Subsector':               'Rail', 'Technology':                      'Train', 'Fuel':      'Biodiesel', 'Enduse':         'Passenger Rail', 'Unit':     'PJ', 'Parameters': 'Fuel Consumption', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute':  'VAR_FIn', 'Process':        'FTE_TRADSL', 'Commodity':     'BDSL', 'Sector':   'Transport', 'Subsector':     'Road Transport', 'Technology': 'Internal Combustion Engine', 'Fuel':      'Biodiesel', 'Enduse':                    'Bus', 'Unit':     'PJ', 'Parameters': 'Fuel Consumption', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute':  'VAR_FIn', 'Process':        'FTE_TRADSL', 'Commodity':     'BDSL', 'Sector':   'Transport', 'Subsector':     'Road Transport', 'Technology': 'Internal Combustion Engine', 'Fuel':      'Biodiesel', 'Enduse':                'Car/SUV', 'Unit':     'PJ', 'Parameters': 'Fuel Consumption', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute':  'VAR_FIn', 'Process':        'FTE_TRADSL', 'Commodity':     'BDSL', 'Sector':   'Transport', 'Subsector':     'Road Transport', 'Technology': 'Internal Combustion Engine', 'Fuel':      'Biodiesel', 'Enduse':            'Heavy Truck', 'Unit':     'PJ', 'Parameters': 'Fuel Consumption', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute':  'VAR_FIn', 'Process':        'FTE_TRADSL', 'Commodity':     'BDSL', 'Sector':   'Transport', 'Subsector':     'Road Transport', 'Technology': 'Internal Combustion Engine', 'Fuel':      'Biodiesel', 'Enduse':           'Medium Truck', 'Unit':     'PJ', 'Parameters': 'Fuel Consumption', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute':  'VAR_FIn', 'Process':        'FTE_TRADSL', 'Commodity':     'BDSL', 'Sector':   'Transport', 'Subsector':     'Road Transport', 'Technology': 'Internal Combustion Engine', 'Fuel':      'Biodiesel', 'Enduse':                'Van/Ute', 'Unit':     'PJ', 'Parameters': 'Fuel Consumption', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute':  'VAR_FIn', 'Process':        'FTE_TRAJET', 'Commodity':      'DIJ', 'Sector':   'Transport', 'Subsector':           'Aviation', 'Technology':                      'Plane', 'Fuel':    'Drop-In Jet', 'Enduse':      'Domestic Aviation', 'Unit':     'PJ', 'Parameters': 'Fuel Consumption', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute':  'VAR_FIn', 'Process':        'FTE_TRAJET', 'Commodity':      'DIJ', 'Sector':   'Transport', 'Subsector':           'Aviation', 'Technology':                      'Plane', 'Fuel':    'Drop-In Jet', 'Enduse': 'International Aviation', 'Unit':     'PJ', 'Parameters': 'Fuel Consumption', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute':  'VAR_FIn', 'Process': 'R_DDW-SH_MSHP-ELC', 'Commodity':   'RESELC', 'Sector': 'Residential', 'Subsector': 'Detached Dwellings', 'Technology':    'Heat Pump (Multi-Split)', 'Fuel':    'Electricity', 'Enduse':          'Space Cooling', 'Unit':     'PJ', 'Parameters': 'Fuel Consumption', 'FuelGroup': 'Electricity'},
    {'Attribute': 'VAR_FOut', 'Process':        'CT_COILBDS', 'Commodity':   'TOTCO2', 'Sector':   'Transport', 'Subsector':               'Rail', 'Technology':                      'Train', 'Fuel':      'Biodiesel', 'Enduse':           'Freight Rail', 'Unit': 'kt CO2', 'Parameters':        'Emissions', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute': 'VAR_FOut', 'Process':        'CT_COILBDS', 'Commodity':   'TOTCO2', 'Sector':   'Transport', 'Subsector':               'Rail', 'Technology':                      'Train', 'Fuel':      'Biodiesel', 'Enduse':         'Passenger Rail', 'Unit': 'kt CO2', 'Parameters':        'Emissions', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute': 'VAR_FOut', 'Process':        'CT_COILBDS', 'Commodity':   'TOTCO2', 'Sector':   'Transport', 'Subsector':     'Road Transport', 'Technology': 'Internal Combustion Engine', 'Fuel':      'Biodiesel', 'Enduse':                    'Bus', 'Unit': 'kt CO2', 'Parameters':        'Emissions', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute': 'VAR_FOut', 'Process':        'CT_COILBDS', 'Commodity':   'TOTCO2', 'Sector':   'Transport', 'Subsector':     'Road Transport', 'Technology': 'Internal Combustion Engine', 'Fuel':      'Biodiesel', 'Enduse':                'Car/SUV', 'Unit': 'kt CO2', 'Parameters':        'Emissions', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute': 'VAR_FOut', 'Process':        'CT_COILBDS', 'Commodity':   'TOTCO2', 'Sector':   'Transport', 'Subsector':     'Road Transport', 'Technology': 'Internal Combustion Engine', 'Fuel':      'Biodiesel', 'Enduse':            'Heavy Truck', 'Unit': 'kt CO2', 'Parameters':        'Emissions', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute': 'VAR_FOut', 'Process':        'CT_COILBDS', 'Commodity':   'TOTCO2', 'Sector':   'Transport', 'Subsector':     'Road Transport', 'Technology': 'Internal Combustion Engine', 'Fuel':      'Biodiesel', 'Enduse':           'Medium Truck', 'Unit': 'kt CO2', 'Parameters':        'Emissions', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute': 'VAR_FOut', 'Process':        'CT_COILBDS', 'Commodity':   'TOTCO2', 'Sector':   'Transport', 'Subsector':     'Road Transport', 'Technology': 'Internal Combustion Engine', 'Fuel':      'Biodiesel', 'Enduse':                'Van/Ute', 'Unit': 'kt CO2', 'Parameters':        'Emissions', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute': 'VAR_FOut', 'Process':        'CT_CWODDID', 'Commodity':   'TOTCO2', 'Sector':    'Industry', 'Subsector':       'Construction', 'Technology': 'Internal Combustion Engine', 'Fuel': 'Drop-In Diesel', 'Enduse':   'Motive Power, Mobile', 'Unit': 'kt CO2', 'Parameters':        'Emissions', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute': 'VAR_FOut', 'Process':        'CT_CWODDID', 'Commodity':   'TOTCO2', 'Sector':    'Industry', 'Subsector':             'Mining', 'Technology': 'Internal Combustion Engine', 'Fuel': 'Drop-In Diesel', 'Enduse':   'Motive Power, Mobile', 'Unit': 'kt CO2', 'Parameters':        'Emissions', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute': 'VAR_FOut', 'Process':        'CT_CWODDID', 'Commodity':   'TOTCO2', 'Sector':   'Transport', 'Subsector':           'Aviation', 'Technology':                      'Plane', 'Fuel':    'Drop-In Jet', 'Enduse':      'Domestic Aviation', 'Unit': 'kt CO2', 'Parameters':        'Emissions', 'FuelGroup': 'Renewables (direct use)'},
    {'Attribute': 'VAR_FOut', 'Process': 'R_DDW-SH_MSHP-ELC', 'Commodity': 'R_DDW-SC', 'Sector': 'Residential', 'Subsector': 'Detached Dwellings', 'Technology':    'Heat Pump (Multi-Split)', 'Fuel':    'Electricity', 'Enduse':          'Space Cooling', 'Unit':     'PJ', 'Parameters':   'End Use Demand', 'FuelGroup': 'Electricity'},
    {'Attribute': 'VAR_FOut', 'Process': 'R_DDW-SH_MSHP-ELC', 'Commodity': 'R_DDW-SC', 'Sector': 'Residential', 'Subsector': 'Detached Dwellings', 'Technology':    'Heat Pump (Multi-Split)', 'Fuel':    'Electricity', 'Enduse':          'Space Cooling', 'Unit': 'kt CO2', 'Parameters':        'Emissions', 'FuelGroup': 'Electricity'}
])