"""
This script reads several input data sources:
* the VEDA Data (VD) files
* the 'Items List' CSV files for Commodity, Commodity Groups, and Process
* the Base.dd file containing commodity to unit mappings

It combines the information to generate a schema file, which is saved in the 'data\output' directory.

The new schema file is then compared to the manually-created reference schema file in 'data\reference'.
"""

import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

from constants import *
from helpers import *
from rulesets import RULESETS, UPDATE_EMISSION_ATTRIBUTION_RULES, MISSING_ROWS

if __name__ == "__main__":
    main_df = process_commodity_groups(ITEMS_LIST_COMMODITY_GROUPS_CSV)

    # Populate the columns according to the rulesets
    for name, ruleset in RULESETS:
        logging.info("Applying ruleset: %s", name)
        main_df = apply_rules(main_df, ruleset)

    logging.info("Adding emission rows for VAR_FOut rows")
    main_df = add_emissions_rows(main_df)

    logging.info("Applying ruleset: UPDATE_EMISSION_ATTRIBUTION_RULES")
    main_df = apply_rules(main_df, UPDATE_EMISSION_ATTRIBUTION_RULES)

    logging.info("Adding missing rows")
    main_df = pd.concat([main_df, MISSING_ROWS], ignore_index=True)
    main_df.Commodity = main_df.Commodity.fillna('-')

    schema = pd.read_csv(REFERENCE_SCHEMA_FILEPATH).drop_duplicates()
    schema = schema.merge(
        main_df[["Attribute", "Process", "Commodity", "Set"]],
        on=["Attribute", "Process", "Commodity"],
        how="left",
    )
    main_df = main_df[OUT_COLS].drop_duplicates().dropna().sort_values(by=OUT_COLS)
    schema = schema[OUT_COLS].drop_duplicates().sort_values(by=OUT_COLS).fillna('-')

    try:
        main_df.to_csv(OUTPUT_SCHEMA_FILEPATH, index=False)
    except PermissionError:
        logging.warning(
            "The file %s may be currently open in Excel. Did not write to file.",
            OUTPUT_SCHEMA_FILEPATH,
        )
        exit()
    message, main_df, schema, correct_rows, missing_rows, extra_rows = compare_tables(
        OUTPUT_SCHEMA_FILEPATH, REFERENCE_SCHEMA_FILEPATH
    )
    print(message)
    if not extra_rows.empty and not missing_rows.empty:
        first_extra_row = extra_rows.head(1)
        first_missing_row = missing_rows.head(1)
        columns_to_compare = set(main_df.columns).intersection(schema.columns)
        comparison_df = compare_rows_to_df(
            first_extra_row, first_missing_row, ['Attribute', 'Process', 'Commodity'] + list(columns_to_compare)
        )
        logging.info("\nDetailed row comparison:\n")
        print(comparison_df.to_string(index=False))
    else:
        logging.info("Either extra_rows or missing_rows DataFrame is empty.")
    print(message)

    logging.info("The files have been concatenated and saved to %s", OUTPUT_SCHEMA_FILEPATH)