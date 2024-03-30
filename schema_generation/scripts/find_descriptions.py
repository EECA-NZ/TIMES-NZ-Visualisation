import re
from collections import defaultdict

# Define the paths to the input and reference files
process_list_path = r"C:\Users\cattonw\git\TIMES-NZ-Visualisation\schema_generation\out.txt"
raw_tables_path = r"C:\Users\cattonw\git\TIMES-NZ-Model-Files\TIMES-NZ\raw_table_summary\raw_tables.txt"

# Function to read the process names from out.txt
def read_process_names(filepath):
    with open(filepath, 'r') as file:
        return [line.strip() for line in file.readlines()]

# Function to search for process information in raw_tables.txt and organize it
def search_process_info(process_names, raw_tables_path):
    with open(raw_tables_path, 'r') as file:
        raw_tables = file.read()

    blocks = raw_tables.split("\n\n")
    workbook_info = defaultdict(lambda: defaultdict(list))
    pattern = re.compile(r'sheetname: (\w+)\nrange: .*\nfilename: (.+\.xlsx)\n(.*?)TechName', re.DOTALL)

    for process in process_names:
        for block in blocks:
            if process in block and "Technology Description" in block:
                match = pattern.search(block)
                if match:
                    sheetname, filename = match.group(1), match.group(2)
                    workbook_info[filename][sheetname].append(process)
                    break

    return workbook_info

process_names = read_process_names(process_list_path)
workbook_info = search_process_info(process_names, raw_tables_path)

for workbook, sheets in workbook_info.items():
    print(f"{workbook}:")
    for sheet, processes in sheets.items():
        print(f"    {sheet}:")
        for process in processes:
            print(f"        {process}")
