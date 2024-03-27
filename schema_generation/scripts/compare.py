"""
This script compares two DataFrames and reports differences between them.
It also provides a detailed comparison of the first extra and missing rows.

Usage:
python scripts/process.py
python scripts/compare.py
"""

import os
import logging
import pandas as pd

from constants import OUT_COLS, OUTPUT_FILEPATH, SCHEMA_FILEPATH

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')


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
    output_df = output_df[OUT_COLS]
    reference_df = reference_df[OUT_COLS]

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

    differences.append(f"\nFirst 5 missing rows: {missing_rows.head().to_string(index=False)}")
    differences.append(f"\nFirst 5 extra rows: {extra_rows.head().to_string(index=False)}")

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


if __name__ == "__main__":
    message, main_df, schema, correct_rows, missing_rows, extra_rows = compare_tables(
        OUTPUT_FILEPATH, SCHEMA_FILEPATH
    )
    logging.info(message)
    if not extra_rows.empty and not missing_rows.empty:
        first_extra_row = extra_rows.head(1)
        first_missing_row = missing_rows.head(1)
        columns_to_compare = set(main_df.columns).intersection(schema.columns)
        comparison_df = compare_rows_to_df(
            first_extra_row, first_missing_row, list(columns_to_compare)
        )
        logging.info("\nDetailed row comparison in DataFrame format:\n")
        logging.info(comparison_df.to_string(index=False))
    else:
        logging.info("Either extra_rows or missing_rows DataFrame is empty.")
