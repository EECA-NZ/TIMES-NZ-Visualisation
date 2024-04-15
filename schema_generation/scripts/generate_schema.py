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
from rulesets import *


if __name__ == "__main__":

    # First approach: VD OUTPUT. This approach will only include technologies selected by TIMES.
    vd_df = read_and_concatenate(INPUT_VD_FILES)

    # Add and subtract columns
    vd_df = add_missing_columns(vd_df, OUT_COLS + SUP_COLS)
    logging.info(
        "Dropping columns: %s", 
        [x for x in vd_df.columns if x not in OUT_COLS + SUP_COLS]
    )
    vd_df = vd_df[OUT_COLS + SUP_COLS]

    # Subset the rows and drop duplicates
    vd_df = vd_df[vd_df["Attribute"].isin(ATTRIBUTE_ROWS_TO_KEEP)]
    
    # Second approach: Read the 'Commodity Groups' CSV file. This approach would be preferred if the
    # Commodity Groups export from VEDA were complete. Unfortunately, it doesn't present the emissions
    cg_df = process_map_from_commodity_groups(ITEMS_LIST_COMMODITY_GROUPS_CSV)

    # Combine the two DataFrames and drop duplicates
    main_df = pd.concat([vd_df, cg_df]).drop_duplicates()

    # Populate the columns and augment with emissions rows according to the rulesets in the specified order
    for name, ruleset in RULESETS:
        logging.info("Applying ruleset: %s", name)
        main_df = apply_rules(main_df, ruleset)

    main_df.Commodity = main_df.Commodity.fillna('-')

    schema = pd.read_csv(REFERENCE_SCHEMA_FILEPATH).drop_duplicates()
    schema = schema.merge(
        main_df[["Attribute", "Process", "Commodity", "Set"]],
        on=["Attribute", "Process", "Commodity"],
        how="left",
    )
    logging.info("Adding missing rows")
    main_df = pd.concat([main_df, MISSING_ROWS], ignore_index=True)
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
        OUTPUT_SCHEMA_FILEPATH, REFERENCE_SCHEMA_FILEPATH, columns=OUT_COLS
    )
    print(message)
    if not extra_rows.empty and not missing_rows.empty:
        first_missing_row = missing_rows.head(1)
        first_extra_row = extra_rows[
            (extra_rows['Attribute'] == first_missing_row['Attribute'].values[0]) &
            (extra_rows['Process'] == first_missing_row['Process'].values[0]) &
            (extra_rows['Commodity'] == first_missing_row['Commodity'].values[0])
        ].head(1)

        if not first_extra_row.empty:
            columns_to_compare = set(main_df.columns).intersection(schema.columns)
            comparison_df = compare_rows_to_df(
                first_extra_row,
                first_missing_row,
                ['Attribute', 'Process', 'Commodity'] + list(columns_to_compare)
            )
            logging.info("\nDetailed row comparison:\n")
            print(comparison_df.to_string(index=False))
        else:
            logging.info("No matching extra row found for the first missing row.")
    else:
        logging.info("Either extra_rows or missing_rows DataFrame is empty.")
    print(message)

    logging.info("The files have been concatenated and saved to %s", OUTPUT_SCHEMA_FILEPATH)
