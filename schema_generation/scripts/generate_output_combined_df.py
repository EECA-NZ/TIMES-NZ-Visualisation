"""
My understanding of the postprocessing that the New_Data_Processing.R script does:

# Heat Pump (Multi-Split)
Electricity consumption is split out for Space Cooling and Space Heating according to the fractional end-use demand

# Biofuel computation for Heavy Truck, Medium Truck, Car/SUV, Van/Ute, Bus, Passenger Rail and Freight Rail
Total biodiesel input to FTE_TRADSL is divided between these end_uses according to their fractional diesel consumption
    Really, TRA_BDSL_percentage is the fraction of BDSL to the total flow into FTE_TRADSL.

# Biofuel computation for Domestic Aviation, International Aviation
Total drop-in jet input to FTE_TRAJET is divided between these end_uses according to their fractional Jet Fuel consumption
Note however that International Aviation uses JET as input whereas Domestic Aviation uses TRAJET.                            So in this case we are not presenting what is actually in the model.
    E.g. for Kea 2060, 
    92.077567 # Jet imports
    6.332581 + 16.676717 # DIJ + JET into TRAJET
    75.400850 # JET into International Aviation
    23.009298 + 75.400850 # Domestic + International Aviation
    So the Drop-in Jet gets allocated 1/4 to Domestic Aviation and 3/4 to International Aviation:
    Domestic Drop-in JET = 6.332581 / 98.410148 * 23.009298 = 1.48062
    International Drop-in JET = 6.332581 / 98.410148 * 75.400850 = 4.85195

    Really, DIJ_percentage is the fraction of DIJ coming out of CT_CWODDID to that plus JET coming out of IMPJET1 applied to the fuel consumption (TRAJET or JET) of the aviation processes.

# Fuel Consumption Biofuel computation for Industry:  "Construction" and "Mining"
Total drop-in diesel input to FTE-INDDSL_00 is divided between these subsectors according to their fraction of the total fuel consumption in these two subsectors.

# Emissions biofuel computation for Heavy Truck, Medium Truck, Car/SUV, Van/Ute, Bus
Total biodiesel "neg-emissions" from CT_COILBDS (the process that turns OILWST into BDSL) are divided between these end_uses evenly (20% each)
(presumed intention: to divide according to their fraction of the overall Road transport biodiesel consumption. This would also be wrong since the same neg-emissions also get allocated to the Rail transport end_uses.)

# Emissions biofuel computation for Passenger Rail and Freight Rail
Total biodiesel "neg-emissions" from CT_COILBDS (the process that turns OILWST into BDSL) are divided between these end_uses evenly (50% each).
(Presumed intention: to divide according to their fraction of the overall Rail biodiesel consumption. This would also be wrong since the same neg-emissions also get allocated to the Road transport end_uses.)

# Emissions Biofuel computation for Domestic Aviation
Total aviation "neg-emissions" from CT_CWODDID (the process that turns WODWST into DID and DIJ) are halved (presumed intent: multiplied by the fraction of DIJ use in Domestic aviation) and then multiplied by 0.4* and attributed to Domestic aviation.
Not obvious why neg-emissions are not applied to International Aviation but presume this was deliberate.

# Emissions Biofuel computation for Industry: Construction and Mining subsectors
Total "neg-emissions" from CT_CWODDID (the process that turns WODWST into DID and DIJ) are divided evently between these subsectors (50% each) and also multiplied by 0.6.*
(Presumed intent: multiplied by the fraction of DIJ use in Domestic aviation)


*Presumably DID takes 60% of the output energy and DIJ takes 40%
"""


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
    ({"Commodity": "BDSL", "Sector": "Transport"}, "inplace", {"Fuel": "Biodiesel", "FuelGroup": "Renewables (direct use)"}),
    ({"Commodity": "BDSL", "Sector": "Industry"}, "inplace", {"Fuel": "Drop-In Diesel", "FuelGroup": "Renewables (direct use)"}),
    ({"Commodity": "DIJ"},  "inplace", {"Fuel": "Drop-In Jet", "FuelGroup": "Renewables (direct use)"})
]

#### FUNCTIONS

def save(df, path):
    _df = df.copy()
    _df['Period'] = _df['Period'].astype(int)
    #_df['Value'] = _df['Value'].astype(float).round(10)
    _df['Value'] = _df['Value'].apply(lambda x: f"{x:.6f}")
    _df.to_csv(path, index=False, quoting=csv.QUOTE_ALL)

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
clean_df = clean_df.groupby(group_columns).agg(Value=('Value', 'sum')).reset_index()
save(clean_df, "../data/output/output_clean_df_v2_0_0.csv")


combined_df = clean_df.copy()
#combined_df = apply_rules(combined_df,
#    [({"Enduse": "International Aviation", "Commodity": "JET"}, "inplace", {"Commodity": "TRAJET"})]
#    )

# Find processes with multiple VAR_FOut rows (excluding emissions commodities) and split the VAR_FIn row across
# each of the end-uses obtained from the VAR_FOut rows, based on the ratio of VAR_FOut values
if fix_multiple_fout:

    filtered_df = combined_df[(combined_df['Attribute'] == 'VAR_FOut') & (~combined_df['Commodity'].str.contains('CO2'))]
    multi_fout = filtered_df.groupby(['Scenario', 'Process', 'Period']).filter(lambda x: len(x) > 1)
    unique_scenario_process_periods = multi_fout[['Scenario', 'Process', 'Period']].drop_duplicates()

    for _, row in unique_scenario_process_periods.iterrows():
        scen = row['Scenario']
        process = row['Process']
        period = row['Period']
        
        # Filter relevant rows for the current process and period
        relevant_rows = combined_df[(combined_df['Scenario'] == scen) & (combined_df['Process'] == process) & (combined_df['Period'] == period)]
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
            combined_df = combined_df.drop(fin_row.index)  # Remove original VAR_FIn row
            combined_df = pd.concat([combined_df, new_fin_rows], ignore_index=True)


if fix_multiple_fin:

    distribution_process_inputs = raw_df[(raw_df['Process'].str.startswith('FTE_')) & (raw_df['Attribute'] == 'VAR_FIn')]
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
    #for (scenario, commodity, period), group in distribution_processes[distribution_processes.CommodityOut=='TRAJET'].groupby(['Scenario', 'CommodityOut', 'Period']):
        matching_rows = combined_df[(combined_df['Scenario'] == scenario) &
                                (combined_df['Commodity'] == commodity) &
                                (combined_df['Period'] == period) &
                                (combined_df['Attribute'] == 'VAR_FIn')]
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
    combined_df = pd.concat([combined_df, new_rows_df], ignore_index=True)
    # Drop rows in a single operation to avoid KeyError
    combined_df = combined_df.drop(drop_indices, errors='ignore').reset_index(drop=True)
    print(f"Number of rows after processing: {len(combined_df)}")

print(combined_df)

# FF 19652
# TF 19670
# TT 19769

# Write the clean data to a CSV file
group_columns = ['Scenario', 'Sector', 'Subsector', 'Technology', 'Enduse', 'Unit', 'Parameters', 'Fuel', 'Period', 'FuelGroup', 'Technology_Group']

output_df = combined_df.groupby(group_columns).agg(Value=('Value', 'sum')).reset_index()

all_periods = np.sort(combined_df['Period'].unique())

categories = ['Scenario', 'Sector', 'Subsector', 'Technology', 'Enduse', 'Unit', 'Parameters', 'Fuel', 'FuelGroup', 'Technology_Group']
complete_df = combined_df.groupby(categories).apply(add_missing_periods).reset_index(drop=True)

group_columns = ['Scenario', 'Sector', 'Subsector', 'Technology', 'Enduse', 'Unit', 'Parameters', 'Fuel', 'Period', 'FuelGroup', 'Technology_Group']
complete_df = complete_df.groupby(group_columns).agg(Value=('Value', 'sum')).reset_index()

# Hack in to match R output
#complete_df.replace('Number of Vehicles (Thousands)', '000 Vehicles', inplace=True)

THOUSAND_VEHICLE_RULES = [
    ({"Sector": "Transport", "Subsector": "Road Transport",# "Technology": "Plug-In Hybrid Vehicle",
      "Unit": "000 Vehicles"}, "inplace", {"Unit": "Number of Vehicles (Thousands)"}),
]
complete_df = apply_rules(complete_df, THOUSAND_VEHICLE_RULES)

complete_df = complete_df.sort_values(by=['Scenario', 'Sector', 'Subsector', 'Technology', 'Enduse', 'Unit', 'Parameters', 'Fuel', 'Period', 'FuelGroup', 'Technology_Group'])

save(complete_df, '../data/output/output_combined_df_v2_0_0.csv')
