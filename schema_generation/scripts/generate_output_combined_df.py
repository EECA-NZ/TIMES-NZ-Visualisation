import os
import csv
import numpy as np
import pandas as pd
from itertools import product


#### IMPORTS

# Make sure to import the necessary functions from helpers.py
from rulesets import MISSING_ROWS
from helpers import read_vd, apply_rules


#### CONSTANTS

fix_multiple_fin = True

fix_multiple_fout = True

needed_attributes = ['VAR_Cap', 'VAR_FIn', 'VAR_FOut']

non_emission_fuel = ['Electricity', 'Wood', 'Hydrogen', 'Hydro', 'Wind', 'Solar', 'Biogas']

# List of file paths for input files
scenario_input_files = {
    'Kea': '../data/input/kea-v2_0_0.vd',
    'Tui': '../data/input/tui-v2_0_0.vd'
}

FUEL_RULES = [
    # Each tuple consists of a condition (e.g., {"Attribute": "VAR_Cap", "Sector": "Transport"}),
    # a ruletype (e.g. "inplace"),
    # and an action (e.g., {"Unit": "000 Vehicles"}).
    # (['COA', 'COL', 'BDSL', 'DSL', 'DIJ', 'JET']
    ({"Commodity": "BDSL", "Sector": "Transport"}, "inplace", {"Fuel": "Biodiesel"}),
    ({"Commodity": "BDSL", "Sector": "Industry"}, "inplace", {"Fuel": "Drop-In Diesel"}),
    ({"Commodity": "DIJ"},  "inplace", {"Fuel": "Drop-In Jet"})
]

#### FUNCTIONS


#### MAIN

# Set the working directory to the script's directory
os.chdir('C:/Users/cattonw/git/TIMES-NZ-Visualisation/schema_generation/scripts')

raw_df = pd.DataFrame()

# Read the VEDA Data (VD) files
for scen, path in scenario_input_files.items():
    if not os.path.exists(path):
        raise FileNotFoundError(f'File not found: {path}')
    scen_df = read_vd(path)
    scen_df = scen_df[(scen_df['Period'] != '2016') &
                      (scen_df['Commodity'] != 'COseq') &
                      (scen_df['Period'] != '2020')]
    scen_df['Scenario'] = scen
    raw_df = pd.concat([raw_df, scen_df])

# Filtering and transformation
raw_df.rename(columns={'PV': 'Value'}, inplace=True)
raw_df = raw_df[raw_df['Attribute'].isin(needed_attributes)]
raw_df = raw_df.groupby(['Scenario', 'Attribute', 'Commodity', 'Process', 'Period']).sum(['Value']).reset_index()

# Read other necessary files
intro = pd.read_csv('../../data_cleaning/intro.csv', delimiter=';')
schema_all = pd.read_csv('../data/output/output_schema_df_v2_0_0.csv')
schema_technology = pd.read_excel('../../data_cleaning/Schema_Technology.xlsx')
schema_technology['Technology'] = schema_technology['Technology'].str.strip()

# Drop MISSING_ROWS from schema_all before we begin
schema_all = pd.merge(schema_all,
                      MISSING_ROWS,
                      on=['Attribute', 'Process', 'Commodity', 'Sector', 'Subsector', 'Technology', 'Fuel', 'Enduse', 'Unit', 'Parameters', 'FuelGroup'],
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

group_columns = ['Scenario', 'Attribute', 'Process', 'Commodity', 'Sector', 'Subsector', 'Technology', 'Enduse', 'Unit', 'Parameters', 'Fuel', 'Period', 'FuelGroup', 'Technology_Group']
#group_columns = ['Scenario', 'Sector', 'Subsector', 'Technology', 'Enduse', 'Unit', 'Parameters', 'Fuel', 'Period', 'FuelGroup', 'Technology_Group']
clean_df = clean_df.groupby(group_columns).agg(Value=('Value', 'sum')).reset_index()

# Find processes with multiple VAR_FOut rows (excluding emissions commodities) and split the VAR_FIn row across
# each of the end-uses obtained from the VAR_FOut rows, based on the ratio of VAR_FOut values


if fix_multiple_fout:

    filtered_df = clean_df[(clean_df['Attribute'] == 'VAR_FOut') & (~clean_df['Commodity'].str.contains('CO2'))]
    multi_fout = filtered_df.groupby(['Scenario', 'Process', 'Period']).filter(lambda x: len(x) > 1)
    unique_scenario_process_periods = multi_fout[['Scenario', 'Process', 'Period']].drop_duplicates()

    for _, row in unique_scenario_process_periods.iterrows():
        scen = row['Scenario']
        process = row['Process']
        period = row['Period']
        
        # Filter relevant rows for the current process and period
        relevant_rows = clean_df[(clean_df['Scenario'] == scen) & (clean_df['Process'] == process) & (clean_df['Period'] == period)]
        fin_row = relevant_rows[relevant_rows['Attribute'] == 'VAR_FIn']
        assert(len(fin_row) == 1)  # There should only be one VAR_FIn row - currently not handling multiple VAR_FIn rows
        fout_rows = relevant_rows[relevant_rows['Attribute'] == 'VAR_FOut']

        if not fin_row.empty:
            total_output = fout_rows['Value'].sum()
            ratios = fout_rows['Value'] / total_output
            
            # Create new VAR_FIn rows by multiplying the original Value with each ratio
            new_fin_rows = fin_row.copy().loc[fin_row.index.repeat(len(fout_rows))].reset_index(drop=True)
            new_fin_rows['Value'] = fin_row['Value'].values[0] * ratios.values
            new_fin_rows['Enduse'] = fout_rows['Enduse'].values
            
            # Replace the original VAR_FIn row with the new rows in the DataFrame
            clean_df = clean_df.drop(fin_row.index)  # Remove original VAR_FIn row
            clean_df = pd.concat([clean_df, new_fin_rows], ignore_index=True)


if fix_multiple_fin:

    distribution_process_inputs = raw_df[(raw_df['Process'].str.startswith('FTE_')) & (raw_df['Attribute'] == 'VAR_FIn')]
    print(distribution_process_inputs)
    input_commodity_counts = distribution_process_inputs.groupby(['Process', 'Scenario', 'Period']).size()
    multiple_input_commodity_processes = input_commodity_counts[input_commodity_counts > 1]
    multiple_input_commodity_processes_list = multiple_input_commodity_processes.index.tolist()
    filter_df = pd.DataFrame(multiple_input_commodity_processes_list, columns=['Process', 'Scenario', 'Period'])
    multi_fin_dist = pd.merge(raw_df, filter_df, on=['Process', 'Scenario', 'Period'], how='inner')

    print("Processes with multiple VAR_FIn entries:", multi_fin_dist.Process.unique())
    cols_of_interest = ['Scenario', 'Commodity', 'Process', 'Period', 'Value'] # drop Region, TimeSlice, Vintage, UserConstraint
    cols_to_aggregate = ['Scenario', 'Process', 'Period', 'Commodity']
    distribution_inputs = multi_fin_dist[multi_fin_dist['Attribute'] == 'VAR_FIn'].groupby(cols_to_aggregate).sum().reset_index()[cols_of_interest]
    distribution_inputs.rename(columns={'Commodity': 'CommodityIn', 'Value': 'ValueIn'}, inplace=True)
    distribution_outputs = multi_fin_dist[multi_fin_dist['Attribute'] == 'VAR_FOut'].groupby(cols_to_aggregate).sum().reset_index()[cols_of_interest]
    distribution_outputs.rename(columns={'Commodity': 'CommodityOut', 'Value': 'ValueOut'}, inplace=True)
    distribution_processes = pd.merge(distribution_inputs, distribution_outputs, on=['Scenario', 'Process', 'Period'], how='inner')
    distribution_processes['TotalValueIn'] = distribution_processes.groupby(['Scenario', 'Process', 'Period'])['ValueIn'].transform('sum')
    distribution_processes['InputFraction'] = distribution_processes['ValueIn'] / distribution_processes['TotalValueIn']

    # Initialize a DataFrame to store new rows
    new_rows_df = pd.DataFrame()
    drop_indices = []  # Collect indices to drop after all operations
    for (scenario, commodity, period), group in distribution_processes.groupby(['Scenario', 'CommodityOut', 'Period']):
        matching_rows = clean_df[(clean_df['Scenario'] == scenario) &
                                (clean_df['Commodity'] == commodity) &
                                (clean_df['Period'] == period) &
                                (clean_df['Attribute'] == 'VAR_FIn')]
        if matching_rows.empty:
            continue  # Skip if no matching rows are found
        for _, dist_row in group.iterrows():
            # Identify rows to replace
            inputs_to_replace = matching_rows[matching_rows['Commodity'] == dist_row['CommodityOut']]
            # Generate new rows based on each input commodity and its fraction
            for index, input_row in inputs_to_replace.iterrows():
                new_row = input_row.copy()
                new_row['Commodity'] = dist_row['CommodityIn']
                new_row['Value'] = input_row['Value'] * dist_row['InputFraction']
                new_rows_df = pd.concat([new_rows_df, pd.DataFrame(new_row).T], ignore_index=True)
                drop_indices.append(index)  # Collect index to drop later
    new_rows_df = apply_rules(new_rows_df, FUEL_RULES)
    # Append new rows to the main DataFrame
    clean_df = pd.concat([clean_df, new_rows_df], ignore_index=True)
    # Drop rows in a single operation to avoid KeyError
    clean_df = clean_df.drop(drop_indices, errors='ignore').reset_index(drop=True)
    print(f"Number of rows after processing: {len(clean_df)}")

# Assuming your clean_df should now contain the updated information
print(clean_df)

# FF 19652
# TF 19670
# TT 19769

# Write the clean data to a CSV file
group_columns = ['Scenario', 'Sector', 'Subsector', 'Technology', 'Enduse', 'Unit', 'Parameters', 'Fuel', 'Period', 'FuelGroup', 'Technology_Group']

output_df = clean_df.groupby(group_columns).agg(Value=('Value', 'sum')).reset_index()
# round the "Value" column to 8 decimal places
#output_df.to_csv("../data/output/output_clean_df_v2_0_0.csv", index=False, quoting=csv.QUOTE_NONNUMERIC)




## Try without quoting
#output_df.to_csv("../data/output/output_combined_df_v2_0_0.csv", 
#                 index=False, 
#                 quoting=csv.QUOTE_NONE, 
#                 escapechar='\\')


all_periods = np.sort(clean_df['Period'].unique())

# Function to find missing periods and create the necessary rows
def add_missing_periods(group):
    existing_periods = group['Period'].unique()
    missing_periods = np.setdiff1d(all_periods, existing_periods)
    if missing_periods.size > 0:
        # Create new rows for missing periods
        new_rows = pd.DataFrame({
            'Period': missing_periods,
            **{col: group.iloc[0][col] for col in group.columns if col != 'Period'}
        })
        # Set 'Value' to 0 for new rows, assuming 'Value' needs to be filled
        new_rows['Value'] = 0
        return pd.concat([group, new_rows], ignore_index=True)
    return group

# Apply the function to each group
categories = ['Scenario', 'Sector', 'Subsector', 'Technology', 'Enduse', 'Unit', 'Parameters', 'Fuel', 'FuelGroup', 'Technology_Group']
complete_df = clean_df.groupby(categories).apply(add_missing_periods).reset_index(drop=True)
complete_df = complete_df.sort_values(by=['Scenario', 'Sector', 'Subsector', 'Technology', 'Enduse', 'Unit', 'Parameters', 'Fuel', 'Period', 'FuelGroup', 'Technology_Group'])

group_columns = ['Scenario', 'Sector', 'Subsector', 'Technology', 'Enduse', 'Unit', 'Parameters', 'Fuel', 'Period', 'FuelGroup', 'Technology_Group']
complete_df = complete_df.groupby(group_columns).agg(Value=('Value', 'sum')).reset_index()

# Check the expanded DataFrame
print(complete_df)

complete_df['Period'] = complete_df['Period'].astype(int)
complete_df['Value'] = complete_df['Value'].astype('float').round(10)
pd.options.display.float_format = '{:.10f}'.format

complete_df.to_csv("../data/output/output_combined_df_v2_0_0.csv", 
                   index=False, 
                   quoting=csv.QUOTE_NONNUMERIC)