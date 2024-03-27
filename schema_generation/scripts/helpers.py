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
    and simple mappings like assigning 'Set' values.

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
        if len(schema) == 1:
            mapping[item_name] = {schema[0]: row[parse_column]}
        else:
            parts = [x.strip() for x in row[parse_column].split("-:-")]
            if len(parts) == len(schema):
                mapping[item_name] = dict(zip(schema, parts))
            else:
                logging.warning("Warning: Description for %s does not match expected format. %s: %s",
                                item_name, parse_column, row[parse_column])
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
