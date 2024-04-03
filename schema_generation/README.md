## This subdirectory is being used to develop the automatic generation of schema files used to visualize TIMES output.

Workflow overview:

* Modify the process and commodity descriptions as required in the TIMES workbooks.
* Modify the local copy of the Schema spreadsheet, which is the CSV file `.\data\reference\reference_schema_df_v2_0_0.csv`
* Sync the VEDA database from the TIMES workbooks
* Using VEDA, export the Items List files for Processes and Commodities
* Pull the new Items List files over to the schema generation directory using `fetch_items_lists.py`:
```bash
python scripts\fetch_items_lists.py
```
* Generate the schema file:
```bash
python scripts\generate_schema.py
```
Note that this will also automatically provide a comparison between the `reference_schema_df` and the newly generated schema file.
* Generate the `combined_df` based on the new automated process:
```bash
Rscript scripts\output_combined_df.R
```
* Generate the `combined_df` based on the reference schema file:
```bash
Rscript scripts\reference_combined_df.R
```
* Compare the two combined_df files
```bash
python scripts\compare_combined_df.py
```