"""
This modulue contains constants and functions used to clean and process the VD files.
Test
"""
import os

def get_project_base_path():
    """
    Determines and returns the absolute path to the project base directory.

    Assumes the script is located within a subdirectory of the project base directory,
    commonly under a 'scripts' or similar directory. This function calculates the path
    relative to the current file's location (__file__).

    Returns:
        str: The absolute path to the project base directory.
    """
    script_dir = os.path.dirname(os.path.realpath(__file__))
    return os.path.dirname(script_dir)

# Initialize the base path for the project, used for constructing paths to other resources.
project_base_path = get_project_base_path()

# List of VEDA Data (VD) files to be read and processed.
INPUT_VD_FILES = [
    os.path.join(project_base_path, "data/input", "kea-v2_0_0.vd"),
    os.path.join(project_base_path, "data/input", "tui-v2_0_0.vd"),
]

# Path to the TIMES base.dd file containing commodity to unit mappings.
BASE_DD_FILEPATH = os.path.join(project_base_path, "data/input", "base.dd")

ITEMS_LIST_COMMODITY_CSV = os.path.join(project_base_path, "data/input", "Items-List-Commodity.csv")

ITEMS_LIST_PROCESS_CSV = os.path.join(project_base_path, "data/input", "Items-List-Process.csv")

# Definitions for paths and schemas of VEDA 'Items List' export CSV files used for creating mappings and rules.
COMMODITY_TO_SECTOR_SUBSECTOR_FUEL_ENDUSE = {
    "Items-List-CSV": ITEMS_LIST_COMMODITY_CSV,
    "ParseColumn": "Description",
    "Schema": ["Sector", "Subsector", "Fuel", "Enduse"],
    "MatchColumn": "Commodity",
}

PROCESS_TO_SECTOR_SUBSECTOR_FUEL_ENDUSE = {
    "Items-List-CSV": ITEMS_LIST_PROCESS_CSV,
    "ParseColumn": "Description",
    "Schema": ["Sector", "Subsector", "Enduse", "Technology", "Fuel"],
    "MatchColumn": "Process",
}

COMMODITY_TO_SET = {
    "Items-List-CSV": ITEMS_LIST_COMMODITY_CSV,
    "ParseColumn": "Set",
    "Schema": ["Set"],
    "MatchColumn": "Commodity",
}

PROCESS_TO_SET = {
    "Items-List-CSV": ITEMS_LIST_PROCESS_CSV,
    "ParseColumn": "Set",
    "Schema": ["Set"],
    "MatchColumn": "Process",
}


# Attributes to retain during data processing.
ATTRIBUTE_ROWS_TO_KEEP = ["VAR_Cap", "VAR_FIn", "VAR_FOut"]

# Define output and supplementary columns for the resulting DataFrame.
OUT_COLS = [
    "Attribute",
    "Process",
    "Commodity",
    "Sector",
    "Subsector",
    "Technology",
    "Fuel",
    "Enduse",
    "Unit",
    "Parameters",
    "FuelGroup",
]
SUP_COLS = ["Set"]

# Mapping for sanitizing unit names.
SANITIZE_UNITS = {
    None: None,
    "PJ": "PJ",
    "kt": "kt CO2",
    "BVkm": "Billion Vehicle Kilometres",
}

# Define the path to the output CSV file.
OUTPUT_FILEPATH = os.path.join(project_base_path, "data/output/clean_df_v2_0_0.csv")

# Define the path to the reference (manually created) schema CSV file.
SCHEMA_FILEPATH = os.path.join(project_base_path, "data/reference/schema_df_v2_0_0.csv")