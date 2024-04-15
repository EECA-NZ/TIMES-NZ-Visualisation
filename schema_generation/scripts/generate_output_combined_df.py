import os
import csv
import numpy as np
import pandas as pd


# Make sure to import the necessary functions from helpers.py
from helpers import read_vd
from rulesets import MISSING_ROWS

# Set the working directory to the script's directory
os.chdir('C:/Users/cattonw/git/TIMES-NZ-Visualisation/schema_generation/scripts')

needed_attributes = ['VAR_Cap', 'VAR_FIn', 'VAR_FOut']

non_emission_fuel = ['Electricity', 'Wood', 'Hydrogen', 'Hydro', 'Wind', 'Solar', 'Biogas']

# List of file paths for input files
scenario_input_files = {
    'Kea': '../data/input/kea-v2_0_0.vd',
    'Tui': '../data/input/tui-v2_0_0.vd'
}

raw_df = pd.DataFrame()

# Read the VEDA Data (VD) files
for scen, path in scenario_input_files.items():
    if not os.path.exists(path):
        raise FileNotFoundError(f'File not found: {path}')
    scen_df = read_vd(path)
    scen_df['scen'] = scen
    raw_df = pd.concat([raw_df, scen_df])


# Filtering and transformation
raw_df.rename(columns={'PV': 'Value'}, inplace=True)
raw_df = raw_df[raw_df['Attribute'].isin(needed_attributes)]
raw_df = raw_df.groupby(['scen', 'Attribute', 'Commodity', 'Process', 'Period']).sum(['Value']).reset_index()

# Read other necessary files
intro = pd.read_csv('../../data_cleaning/intro.csv', delimiter=';')
schema_all = pd.read_csv('../data/output/output_schema_df_v2_0_0.csv')
schema_technology = pd.read_excel('../../data_cleaning/Schema_Technology.xlsx')
schema_technology['Technology'] = schema_technology['Technology'].str.strip()

# Drop MISSING_ROWS from schema_all before we begin
schema_all = pd.merge(schema_all, MISSING_ROWS, on=['Attribute', 'Process', 'Commodity', 'Sector', 'Subsector', 'Technology', 'Fuel', 'Enduse', 'Unit', 'Parameters', 'FuelGroup'], 
                  how='outer', indicator=True)
schema_all = schema_all[schema_all['_merge'] == 'left_only'].drop(columns=['_merge'])

# Join operations (Assuming appropriate join keys and relationships are known)
clean_df = pd.merge(raw_df, schema_all, on=['Attribute', 'Process', 'Commodity'], how='inner')
clean_df = pd.merge(clean_df, schema_technology, on=['Technology'], how='left')

# Setting values based on conditions
clean_df['Value'] = np.where((clean_df['Fuel'].isin(non_emission_fuel)) & (clean_df['Parameters'] == 'Emissions'), 0, clean_df['Value'])
clean_df['Sector'] = np.where(clean_df['Sector'] == 'Electricity', 'Other', clean_df['Sector'])

# Convert emissions to Mt CO2/yr
clean_df.loc[clean_df['Parameters'] == 'Emissions', 'Value'] /= 1000
clean_df.loc[clean_df['Parameters'] == 'Emissions', 'Unit'] = 'Mt CO<sub>2</sub>/yr' #'Mt CO₂/yr'

# Convert Annualised Capital Costs to Billion NZD
clean_df.loc[clean_df['Parameters'] == 'Annualised Capital Costs', 'Value'] /= 1000
clean_df.loc[clean_df['Parameters'] == 'Annualised Capital Costs', 'Unit'] = 'Billion NZD'

# Remove unwanted rows and group data
clean_df = clean_df[(clean_df['Parameters'] != 'Annualised Capital Costs') & (clean_df['Parameters'] != 'Technology Capacity')]

group_columns = ['scen', 'Attribute', 'Process', 'Commodity', 'Sector', 'Subsector', 'Technology', 'Enduse', 'Unit', 'Parameters', 'Fuel', 'Period', 'FuelGroup', 'Technology_Group']
#group_columns = ['scen', 'Sector', 'Subsector', 'Technology', 'Enduse', 'Unit', 'Parameters', 'Fuel', 'Period', 'FuelGroup', 'Technology_Group']
clean_df = clean_df.groupby(group_columns).agg(Value=('Value', 'sum')).reset_index()

clean_df['Period'] = clean_df['Period'].astype(int)

# Write the clean data to a CSV file
#clean_df.to_csv("../data/output/output_clean_df_v2_0_0.csv", index=False, quoting=csv.QUOTE_NONNUMERIC)
