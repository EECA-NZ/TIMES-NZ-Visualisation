"""
Functions used for data processing and transformation, and comparison of DataFrames.
"""

import re
import logging
import pandas as pd

from constants import *


logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")


def df_to_ruleset(df=None, target_column_map=None, parse_column=None, separator=None, schema=None, rule_type=None):
    """
    Reads a CSV file to create rules for updating or appending to a DataFrame based on
    the contents of a specified column and a mapping of source to target columns. This
    function can handle parsing complex descriptions into attributes, mapping values to 
    'Set' or similar, and ensures consistency across complex keys that might map to 
    multiple DataFrame columns.

    A special sentinel value '-:-' is used to split the parse_column into schema parts.

    :param filepath: Path to the CSV file that contains the data to parse.
    :param target_column_map: A dictionary mapping column names in the source CSV
                                to target DataFrame columns for rule conditions.
    :param parse_column: The column from which to parse data (e.g., 'Description' or 'Set').
    :param schema: A list of attribute names expected in the parse_column after splitting.
    :param rule_type: The type of rule to create, which informs how the rule is applied.
                      For example, 'inplace' for in-place updates, or 'newrow' for
                      appending new rows to the DataFrame.
    :return: A list of rules, each defined as a tuple containing a condition dictionary
             (for matching against DataFrame rows), a rule type (e.g., 'inplace', 'newrow'),
             and a dictionary of attribute updates or values to append.
    """
    assert(df is not None and target_column_map and parse_column and schema and rule_type)
    mapping = {}
    for _, row in df.iterrows():
        # Create the key tuple based on the target_column_map
        key_tuple = tuple(row[col] for col in target_column_map.keys())
        new_mapping = None
        parts = [x.strip() for x in row[parse_column].split(separator)]
        if len(parts) == len(schema):
            new_mapping = dict(zip(schema, parts))
        else:
            logging.warning("Warning: %s for %s does not match expected format. %s: %s",
                            parse_column, key_tuple, parse_column, row[parse_column])
        if new_mapping is not None:
            # Check if key_tuple already has a mapping
            if key_tuple in mapping and mapping[key_tuple] != new_mapping:
                logging.warning("%s is mapped to different dictionaries. Existing: %s, New: %s",
                                key_tuple, mapping[key_tuple], new_mapping)
            mapping[key_tuple] = new_mapping
    rules = []
    for key_tuple, attributes in mapping.items():
        condition = {target: key for target, key in zip(target_column_map.values(), key_tuple)}
        rules.append((condition, rule_type, attributes))
    return rules


def base_dd_commodity_unit_rules(filepath=None, rule_type=None):
    """
    Extracts the mapping of commodities to units from the specified section of a file.
    Assumes the section starts after 'SET COM_UNIT' and the opening '/', and ends at the next '/'.

    :param base_dd_filepath: Path to the TIMES base.dd file containing the definitions.
    :return: A list of rules, where each rule is a tuple of a condition and actions.
    """
    assert(filepath and rule_type)
    commodity_unit_mapping = {}
    with open(filepath, "r", encoding="utf-8") as file:
        capture = False  # Flag to start capturing data
        for line in file:
            line = line.strip()
            if line.startswith(
                "SET COM_UNIT"
            ):  # Check for start of the relevant section
                capture = True
                continue
            if capture and line.startswith("/"):
                if (
                    not commodity_unit_mapping
                ):  # If the mapping is empty, this is the opening '/'
                    continue
                else:  # If already capturing, this '/' signifies the end
                    break
            if capture and line:
                parts = line.strip("'").split("'.'")
                if len(parts) == 3:
                    region, commodity, unit = parts
                    if unit in SANITIZE_UNITS:
                        unit = SANITIZE_UNITS[unit]
                    commodity_unit_mapping[commodity] = unit
    rules = []
    for commodity, unit in commodity_unit_mapping.items():
        condition = {"Commodity": commodity}
        actions = {"Unit": unit}
        rules.append((condition, rule_type, actions))
    return rules


def sort_rules_by_specificity(rules):
    """
    Sort rules based on their specificity. A rule is considered more specific if its keys
    are a strict superset of the keys of another rule.

    :param rules: A list of tuples, where each tuple contains a condition dictionary and a
                  dictionary of target column(s) and value(s) to set.
    :return: A list of rules sorted from least to most specific.
    """
    # Convert each rule's condition dictionary keys to frozensets for easy comparison
    rule_sets = [
        (frozenset(condition.keys()), condition, rule_type, actions)
        for condition, rule_type, actions in rules
    ]
    # Sort rules based on the length of the condition keys as a primary criterion
    # and the lexicographical order of the keys as a secondary criterion for stability
    sorted_rules = sorted(rule_sets, key=lambda x: (len(x[0]), x[0]))
    # Rebuild sorted rules from sorted rule sets
    sorted_rules_rebuilt = [
        (condition, rule_type, actions) for _, condition, rule_type, actions in sorted_rules
    ]
    return sorted_rules_rebuilt


def apply_rules(schema, rules):
    """
    Apply rules, optimized by minimizing row-wise operations.

    :param schema: DataFrame to apply rules on.
    :param rules: Rules defined as a list of tuples with conditions and actions.
    :return: Modified DataFrame with rules applied.
    """
    sorted_rules = sort_rules_by_specificity(rules)
    new_rows = []
    rows_to_drop = []
    for condition, rule_type, actions in sorted_rules:
        query_conditions_parts, local_vars = [], {}
        for i, (key, value) in enumerate(condition.items()):
            if pd.notna(value) and value != "":
                query_placeholder = f"@value_{i}"
                query_conditions_parts.append(f"`{key}` == {query_placeholder}")
                local_vars[f"value_{i}"] = value
        query_conditions = " & ".join(query_conditions_parts)
        if rule_type == "inplace":
            if not query_conditions:
                continue
            # Filter schema DataFrame based on the query derived from the rule's conditions
            # Pass local_vars to query() to make external variables available
            filtered_indices = schema.query(query_conditions, local_dict=local_vars).index
            # Apply actions for filtered rows, ensuring we ignore empty updates
            for column, value_to_set in actions.items():
                if pd.notna(value_to_set) and value_to_set != "":
                    schema.loc[filtered_indices, column] = value_to_set
        elif rule_type == "newrow":
            # Apply newrow rule logic
            for _, row in schema.iterrows():
                if all(row.get(key, None) == value for key, value in condition.items()):
                    new_row = row.to_dict()
                    new_row.update(actions)
                    new_rows.append(new_row)
        elif rule_type == "drop":
            # Collect indices of rows to drop based on the condition
            if not query_conditions:
                continue
            rows_to_drop.extend(schema.fillna('-').query(query_conditions, local_dict=local_vars).index.tolist())    
    # Drop rows collected for dropping
    schema = schema.drop(rows_to_drop).reset_index(drop=True)
    if new_rows:
        new_rows_df = pd.DataFrame(new_rows)
        schema = pd.concat([schema, new_rows_df], ignore_index=True)
    return schema


def add_emissions_rows(main_df):
    """
    For every VAR_FOut row in the DataFrame where the FuelGroup is 'Fossil Fuels',
    or the Fuel is 'Geothermal' (TODO - determine condition dynamically from the model),
    if there is not already a VAR_FOut row for the same Process that has 
    Unit='kt CO2' and Parameters='Emissions', then duplicate the row with Unit='kt CO2'
    and Parameters='Emissions', keeping other values identical.

    :param main_df: The original DataFrame containing model data.
    :return: DataFrame with added VAR_FOut emissions rows.
    """
    # Filter to only VAR_FOut rows
    f_out_rows = main_df[main_df['Attribute'] == 'VAR_FOut'].copy()
    # Check if there are any rows with Unit='kt CO2' and Parameters='Emissions'
    existing_emissions_rows = f_out_rows[
        (f_out_rows['Unit'] == 'kt CO2') & (f_out_rows['Parameters'] == 'Emissions')
    ]
    # Remove any existing rows whose Process already has an emissions row
    f_out_rows = f_out_rows[
        ~f_out_rows['Process'].isin(existing_emissions_rows['Process'])
    ]
    # Only include rows where the FuelGroup is 'Fossil Fuels' or the Fuel is 'Geothermal'
    f_out_rows = f_out_rows[
        (f_out_rows['FuelGroup'].fillna('-').str.contains('Fossil Fuels', flags=re.IGNORECASE)) |
        (f_out_rows['Fuel'].fillna('-').str.contains('Geothermal', flags=re.IGNORECASE))
    ]
    # We only want one row per process, so drop duplicates
    f_out_rows = f_out_rows.drop_duplicates()
    print(existing_emissions_rows[existing_emissions_rows.Process=='DARY-PH-STM_HW-GEO-Heat15'])
    print(f_out_rows[f_out_rows.Process=='DARY-PH-STM_HW-GEO-Heat15'])
    # Update the Unit and Parameters columns for the duplicated rows
    f_out_rows['Unit'] = 'kt CO2'
    f_out_rows['Parameters'] = 'Emissions'
    # Append these updated rows to the original DataFrame using concat
    augmented_df = pd.concat([main_df, f_out_rows], ignore_index=True)
    return augmented_df


def process_commodity_groups(filepath):
    """
    Use the commodity groups file to add rows to the main DataFrame for each process, differentiating between
    energy inputs, energy outputs, CO2 emissions, and end-service energy demands based on the suffix in the Name column.

    :param filepath: Path to the commodity groups file.
    :param main_df: The main DataFrame containing model data.

    :return: DataFrame with added rows for each process in the commodity groups file.
    """
    main_df = pd.DataFrame(columns=OUT_COLS + SUP_COLS)
    commodity_groups_df = pd.read_csv(filepath)
    # Define suffixes and their implications
    suffix_mappings = {
        'NRGI': {'Attribute': 'VAR_FIn', 'Parameters': None, 'Unit': None},
        'NRGO': {'Attribute': 'VAR_FOut', 'Parameters': None, 'Unit': None},
        'ENVO': {'Attribute': 'VAR_FOut', 'Parameters': 'Emissions', 'Unit': 'kt CO2'},
        'DEMO': {'Attribute': 'VAR_FOut', 'Parameters': 'End Use Demand', 'Unit': None},
    }
    new_rows = []
    for process in commodity_groups_df['Process'].unique():
        # Always add a VAR_Cap row for each unique process
        new_rows.append({'Attribute': 'VAR_Cap', 'Process': process})
        # Filter rows related to the current process
        process_rows = commodity_groups_df[commodity_groups_df['Process'] == process]
        for _, row in process_rows.iterrows():
            for suffix, attrs in suffix_mappings.items():
                if row['Name'].endswith(suffix):
                    row_data = {
                        'Attribute': attrs['Attribute'],
                        'Process': process,
                        'Commodity': row['Member']
                    }
                    if attrs['Parameters']:
                        row_data['Parameters'] = attrs['Parameters']
                    if attrs['Unit']:
                        row_data['Unit'] = attrs['Unit']
                    new_rows.append(row_data)
    # Convert the list of dictionaries into a DataFrame
    new_rows_df = pd.DataFrame(new_rows)
    # Append the new rows to the main DataFrame and reset the index
    main_df = pd.concat([main_df, new_rows_df], ignore_index=True)
    return main_df


def stringify_and_strip(df):
    """
    Convert all columns to string and strip whitespace from them.
    """
    for col in df.columns:
        df[col] = df[col].astype(str).str.strip()
    return df


def compare_rows(df1, df2, df1_label="df1", df2_label="df2"):
    """
    Compare rows of two DataFrames and find rows that are only in one of the two
    DataFrames.

    :param df1: First DataFrame.
    :param df2: Second DataFrame.
    :param df1_label: Label for the first DataFrame.
    :param df2_label: Label for the second DataFrame.
    :return: A DataFrame with all unique rows from both DataFrames and a column
    indicating their source.
    """
    comparison_df = pd.merge(df1, df2, indicator=True, how="outer").query(
        '_merge != "both"'
    )
    return comparison_df


def compare_tables(output_filepath, reference_filepath):
    """
    Assemble DataFrames from the output and reference CSV files and compare them.
    Report differences in columns and rows.

    :param output_filepath: Path to the output CSV file.
    :param reference_filepath: Path to the reference CSV file.

    :return: A tuple containing the comparison message, DataFrames, and comparison results.
    """
    output_df = pd.read_csv(output_filepath, low_memory=False).drop_duplicates()
    reference_df = pd.read_csv(reference_filepath, low_memory=False).drop_duplicates()
    #output_df = output_df[OUT_COLS]
    #reference_df = reference_df[OUT_COLS]

    # Convert all columns to string for comparison purposes to ensure compatibility
    output_df = stringify_and_strip(output_df)
    reference_df = stringify_and_strip(reference_df)

    # Compare columns
    missing_columns = set(reference_df.columns) - set(output_df.columns)
    extra_columns = set(output_df.columns) - set(reference_df.columns)

    # Initial message parts
    differences = []
    if missing_columns:
        differences.append(f"Missing columns: {', '.join(missing_columns)}")
    if extra_columns:
        differences.append(f"Extra columns: {', '.join(extra_columns)}")

    # Merge DataFrames to compare rows
    comparison_df = pd.merge(output_df, reference_df, indicator=True, how="outer")

    # Identify correct, missing, and extra rows
    correct_rows = comparison_df[comparison_df["_merge"] == "both"].sort_values(
        by=list(output_df.columns)
    )
    missing_rows = comparison_df[comparison_df["_merge"] == "right_only"].sort_values(
        by=list(output_df.columns)
    )
    extra_rows = comparison_df[comparison_df["_merge"] == "left_only"].sort_values(
        by=list(output_df.columns)
    )

    # Report counts
    differences.append(f"\nNumber of correct rows: {len(correct_rows)}")
    differences.append(f"Number of missing rows: {len(missing_rows)}")
    differences.append(f"Number of extra rows: {len(extra_rows)}")

    with pd.option_context('display.max_rows', None):
        differences.append(f"\nMissing rows:\n {missing_rows.to_string(index=False)}")
        # differences.append(f"\nExtra rows:\n {extra_rows.to_string(index=False)}")

    # Final output
    if differences:
        return (
            "\n".join(differences),
            output_df,
            reference_df,
            correct_rows,
            missing_rows,
            extra_rows,
        )
    return "All good", output_df, reference_df, correct_rows, missing_rows, extra_rows


def compare_rows_to_df(row_extra, row_missing, columns):
    """
    Compares the first rows in extra_rows and missing_rows DataFrames and reports differences
    in a DataFrame format.

    :param row_extra: The first row from extra_rows DataFrame.
    :param row_missing: The first row from missing_rows DataFrame.
    :param columns: List of columns to compare.
    :return: A DataFrame showing differences between the rows.
    """
    # Initialize lists to hold comparison data
    comparison_data = {"Column": [], "Correct Value": [], "Current Value": []}

    # Check if the DataFrames are empty and handle accordingly
    if row_extra.empty or row_missing.empty:
        return pd.DataFrame(
            comparison_data
        )  # Return an empty DataFrame if either row is missing

    for col in columns:
        extra_val = row_extra[col].values[0]
        missing_val = row_missing[col].values[0]
        if extra_val != missing_val:
            comparison_data["Column"].append(col)
            comparison_data["Correct Value"].append(missing_val)
            comparison_data["Current Value"].append(extra_val)

    # Create a DataFrame from the collected comparison data
    comparison_df = pd.DataFrame(comparison_data)
    transposed_df = comparison_df.set_index("Column").T.reset_index()

    return transposed_df

def show_subset(df, column_value_dict):
    """
    Show a subset of the DataFrame where the specified columns match the specified values.

    :param df: The DataFrame to filter.
    :param column_value_dict: A dictionary of column names and values to match.
    :return: The subset of the DataFrame where the specified columns match the specified values.
    """
    query_parts = []
    for column, value in column_value_dict.items():
        query_parts.append(f"{column} == '{value}'")
    query = " & ".join(query_parts)
    return df.query(query)