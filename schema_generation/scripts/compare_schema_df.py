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

from constants import OUTPUT_SCHEMA_FILEPATH, REFERENCE_SCHEMA_FILEPATH
from helpers import *

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

if __name__ == "__main__":
    message, main_df, schema, correct_rows, missing_rows, extra_rows = compare_tables(
        OUTPUT_SCHEMA_FILEPATH, REFERENCE_SCHEMA_FILEPATH
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
