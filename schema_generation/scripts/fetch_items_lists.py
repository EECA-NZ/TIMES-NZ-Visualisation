import os
import pandas as pd
from datetime import datetime

def fetch_and_convert_latest_item_lists(source_directory, target_directory):
    # Define patterns for commodity and process files
    commodity_pattern = "Items List-Commodity("
    process_pattern = "Items List-Process("

    # Initialize variables to hold the latest file details
    latest_commodity_file = {"path": None, "datetime": None}
    latest_process_file = {"path": None, "datetime": None}

    # Iterate through files in the source directory
    for file in os.listdir(source_directory):
        if commodity_pattern in file:
            datetime_str = file.split(commodity_pattern)[-1].split(').xlsx')[0]
            datetime_obj = datetime.strptime(datetime_str, "%Y%m%d%H%M%S")
            if latest_commodity_file["datetime"] is None or datetime_obj > latest_commodity_file["datetime"]:
                latest_commodity_file["path"] = os.path.join(source_directory, file)
                latest_commodity_file["datetime"] = datetime_obj
        elif process_pattern in file:
            datetime_str = file.split(process_pattern)[-1].split(').xlsx')[0]
            datetime_obj = datetime.strptime(datetime_str, "%Y%m%d%H%M%S")
            if latest_process_file["datetime"] is None or datetime_obj > latest_process_file["datetime"]:
                latest_process_file["path"] = os.path.join(source_directory, file)
                latest_process_file["datetime"] = datetime_obj

    # Convert and save the latest files found
    if latest_commodity_file["path"]:
        df = pd.read_excel(latest_commodity_file["path"])
        output_path = os.path.join(target_directory, "Items-List-Commodity.csv")
        df.to_csv(output_path, index=False)
        print(f"Latest commodity list saved to {output_path}")

    if latest_process_file["path"]:
        df = pd.read_excel(latest_process_file["path"])
        output_path = os.path.join(target_directory, "Items-List-Process.csv")
        df.to_csv(output_path, index=False)
        print(f"Latest process list saved to {output_path}")

if __name__ == "__main__":
    source_dir = r"C:\Users\cattonw\git\TIMES-NZ-Model-Files\TIMES-NZ\Exported_files"
    target_dir = r"C:\Users\cattonw\git\TIMES-NZ-Visualisation\schema_generation\data\input"
    fetch_and_convert_latest_item_lists(source_dir, target_dir)
