import os
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

from constants import *
from helpers import *
from rulesets import RULESETS
from compare import *


if __name__ == "__main__":
    project_base_path = get_project_base_path()

    main_df = read_and_concatenate(INPUT_VD_FILES)

    # Add and subtract columns
    main_df = add_missing_columns(main_df, OUT_COLS + SUP_COLS)
    logging.info(
        "Dropping columns: %s", 
        [x for x in main_df.columns if x not in OUT_COLS + SUP_COLS]
    )
    main_df = main_df[OUT_COLS + SUP_COLS]

    # Subset the rows and drop duplicates
    main_df = main_df[main_df["Attribute"].isin(ATTRIBUTE_ROWS_TO_KEEP)]
    main_df = main_df.drop_duplicates()

    logging.info("Dataframe to apply rules to looks like this:\n%s",
                 main_df.head().to_string(index=False))

    # Populate the columns according to the rulesets
    for ruleset in RULESETS:
        main_df = apply_rules(main_df, ruleset)

    schema = pd.read_csv(SCHEMA_FILEPATH).drop_duplicates()
    schema = schema.merge(
        main_df[["Attribute", "Process", "Commodity", "Set"]],
        on=["Attribute", "Process", "Commodity"],
        how="left",
    )

    main_df = main_df[OUT_COLS].dropna().drop_duplicates().sort_values(by=OUT_COLS)
    schema = schema[OUT_COLS].dropna().drop_duplicates().sort_values(by=OUT_COLS)

    try:
        main_df.to_csv(OUTPUT_FILEPATH, index=False)
    except PermissionError:
        logging.warning(
            "The file %s may be currently open in Excel. Did not write to file.",
            OUTPUT_FILEPATH,
        )
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

    logging.info("The files have been concatenated and saved to %s", OUTPUT_FILEPATH)
    