import os
import re
import logging
import pandas as pd

from constants import *

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

def read_vd(filepath):
    """
    Reads a VD file, using column names extracted from the file's header with regex, skipping non-CSV formatted header lines.

    :param filepath: Path to the VD file.
    :param scen_label: Label for the 'scen' column for rows from this file.
    """
    dimensions_pattern = re.compile(r"\*\s*Dimensions-")

    # Determine the number of rows to skip and the column names
    with open(filepath, "r", encoding="utf-8") as file:
        columns = None
        skiprows = 0
        for line in file:
            if dimensions_pattern.search(line):
                columns_line = line.split("- ")[1].strip()
                columns = columns_line.split(";")
                continue
            if line.startswith('"'):
                break
            skiprows += 1

    # Read the CSV file with the determined column names and skiprows
    df = pd.read_csv(
        filepath, skiprows=skiprows, names=columns, header=None, low_memory=False
    )
    return df


def read_and_concatenate(input_filepaths):
    """
    Reads CSV files from the given filepaths, using custom headers extracted from each,
    labels them accordingly, and concatenates them into a single DataFrame.

    :param input_filepaths_labels: List of tuples (filepath, label) for the CSV files.
    :return: Concatenated DataFrame.
    """
    dfs = [read_vd(filepath) for filepath in input_filepaths]
    return pd.concat(dfs, ignore_index=True)


def add_missing_columns(df, missing_columns):
    """
    Adds missing columns to the DataFrame with default values set to NaN.

    :param df: The DataFrame to modify.
    :param missing_columns: A list of column names that are missing and need to be added.
    """
    for column in missing_columns:
        if column not in df.columns:
            df[column] = (
                None  # Adding the column with a default value of None (will become NaN in the DataFrame)
            )
    return df


def itemlist_column_to_ruleset(filepath, parse_column, schema, match_column):
    """
    Reads a CSV file to create rules based on the contents of a specified column.
    This function can handle both parsing of complex descriptions into multiple attributes
    and simple mappings like assigning 'Set' values. It also logs a warning if the same
    item_name is mapped to different dictionaries.

    :param filepath: Path to the CSV file.
    :param parse_column: The column to parse, which can be 'Description' or 'Set'.
    :param schema: Expected schema of the parsed data. For 'Set', this would typically be just ["Set"].
    :param match_column: The column in the DataFrame to match against the 'Name' from the CSV file.
    :return: A list of rules for data transformation.
    """
    mapping = {}
    df = pd.read_csv(filepath)
    for _, row in df.iterrows():
        item_name = row["Name"]
        new_mapping = None
        if len(schema) == 1:
            new_mapping = {schema[0]: row[parse_column]}
        else:
            parts = [x.strip() for x in row[parse_column].split("-:-")]
            if len(parts) == len(schema):
                new_mapping = dict(zip(schema, parts))
            else:
                logging.warning("Warning: Description for %s %s does not match expected format. %s: %s",
                                match_column, item_name, parse_column, row[parse_column])
        if new_mapping is not None:
            # Check if item_name already has a mapping
            if item_name in mapping and mapping[item_name] != new_mapping:
                logging.warning(f"{match_column} {item_name} is mapped to different dictionaries. Existing: {mapping[item_name]}, New: {new_mapping}")
            mapping[item_name] = new_mapping
    rules = []
    for item_name, attributes in mapping.items():
        condition = {match_column: item_name} if match_column else {}
        rules.append((condition, attributes))
    return rules


def base_dd_commodity_unit_rules(base_dd_filepath):
    """
    Extracts the mapping of commodities to units from the specified section of a file.
    Assumes the section starts after 'SET COM_UNIT' and the opening '/', and ends at the next '/'.

    :param base_dd_filepath: Path to the TIMES base.dd file containing the definitions.
    :return: A list of rules, where each rule is a tuple of a condition and actions.
    """
    commodity_unit_mapping = {}
    with open(base_dd_filepath, "r", encoding="utf-8") as file:
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
        rules.append((condition, actions))
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
        (frozenset(condition.keys()), condition, actions)
        for condition, actions in rules
    ]
    # Sort rules based on the length of the condition keys as a primary criterion
    # and the lexicographical order of the keys as a secondary criterion for stability
    sorted_rules = sorted(rule_sets, key=lambda x: (len(x[0]), x[0]))
    # Rebuild sorted rules from sorted rule sets
    sorted_rules_rebuilt = [
        (condition, actions) for _, condition, actions in sorted_rules
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
    for condition, actions in sorted_rules:
        query_conditions_parts = []
        local_vars = {}
        for i, (key, value) in enumerate(condition.items()):
            if pd.notna(value) and value != "":
                query_placeholder = f"@value_{i}"
                query_conditions_parts.append(f"`{key}` == {query_placeholder}")
                local_vars[f"value_{i}"] = value
        query_conditions = " & ".join(query_conditions_parts)
        if not query_conditions:
            continue
        # Filter schema DataFrame based on the query derived from the rule's conditions
        # Pass local_vars to query() to make external variables available
        filtered_indices = schema.query(query_conditions, local_dict=local_vars).index
        # Apply actions for filtered rows, ensuring we ignore empty updates
        for column, value_to_set in actions.items():
            if pd.notna(value_to_set) and value_to_set != "":
                schema.loc[filtered_indices, column] = value_to_set
    return schema


def add_emissions_rows(main_df):
    """
    For every VAR_FOut row in the DataFrame, duplicate it with Unit='kt CO2' and
    Parameters='Emissions', keeping other values identical.

    :param main_df: The original DataFrame containing model data.
    :return: DataFrame with added emissions rows for each VAR_FOut entry.
    """
    # Filter to only VAR_FOut rows
    f_out_rows = main_df[main_df['Attribute'] == 'VAR_FOut'].copy()

    # Update the Unit and Parameters columns for the duplicated rows
    f_out_rows['Unit'] = 'kt CO2'
    f_out_rows['Parameters'] = 'Emissions'

    # Append these updated rows to the original DataFrame using concat
    augmented_df = pd.concat([main_df, f_out_rows], ignore_index=True)

    return augmented_df


def process_commodity_groups(filepath, main_df):
    """
    Use the commodity groups file to add rows to the main DataFrame for each process

    :param filepath: Path to the commodity groups file.
    :param main_df: The main DataFrame containing model data.

    :return: DataFrame with added rows for each process in the commodity groups file.
    """
    commodity_groups_df = pd.read_csv(filepath)

    suffix_in = 'NRGI'
    suffix_demand_out = 'DEMO'
    new_rows = []

    for process in commodity_groups_df['Process'].unique():
        new_rows.append({'Attribute': 'VAR_Cap', 'Process': process})
        process_rows = commodity_groups_df[commodity_groups_df['Process'] == process]
        for _, row in process_rows.iterrows():
            if row['Name'].endswith(suffix_in):
                new_rows.append({'Attribute': 'VAR_FIn', 'Process': process, 'Commodity': row['Member']})
            elif row['Name'].endswith(suffix_demand_out):
                new_rows.append({'Attribute': 'VAR_FOut', 'Process': process, 'Commodity': row['Member']})
                new_rows.append({'Attribute': 'VAR_FOut', 'Process': process, 'Commodity': row['Member'], 'Unit': 'kt CO2', 'Parameters': 'Emissions'})

    new_rows_df = pd.DataFrame(new_rows)
    augmented_main_df = pd.concat([main_df, new_rows_df], ignore_index=True)
    return augmented_main_df


def generate_augmented_ruleset(ruleset):
    """
    Generate an augmented ruleset by creating rules for processes that do not end with '00'.
    The new ruleset will label processes ending with '00' as if the 00 suffix was removed.
    It is assumed that the processes ending with '00' are base-year processes.

    :param ruleset: The original ruleset to augment.
    :return: The augmented ruleset.
    """
    new_ruleset = []
    for condition, actions in ruleset:
        process_name = condition['Process']
        if not process_name.endswith('00'):
            new_condition = condition.copy()  # Create a copy of the condition dictionary
            new_condition['Process'] = process_name + '00'  # Append '00' to the process name
            new_ruleset.append((new_condition, actions))  # Create a new rule with the modified condition and original actions
    return new_ruleset


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