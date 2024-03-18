import pandas as pd
import numpy as np
import re

# ======================================================================
# Readme

# This file partly replaces "New_Data_Processing.R" which was used for TIMES-NZ 2.0.

# Initial focus is on generating a "clean" dataframe as per lines 109-142 of the above file.

# Key change is that the file "Schema.xlsx" is no longer used, and instead two alternative files are used:
#   Items-List-Commodity-20240110105111.csv
#   Items-List-Process-20240110105048.csv

# These two "Item-List" files are generated from Veda, and utilise updated commodity (CommDesc) and technology (TechDesc) descriptions in the ~FI_Comm and ~FI_Process tables.

# CommDesc is a concatenation of Sector -:- Subsector -:- Fuel/Enduse
# TechDesc is a concatenation of Sector -:- Subsector -:- Enduse -:- Technology -:- Fuel

# Note that -:- is used as a separator, as , . ; : and - could potentially all be used in the text field.

# Note also that the Item-List files were generated from files which will form the 2.1.3 release, but should be back-compatible with 2.0 files.

# ======================================================================
# Specify folders and filenames for VD files:

VD_filenames = [ "./kea-v2_0_0.vd" ]

VD_colnames = [
    "Attribute", "Commodity", "Process", "Period", "Region", "Vintage", "TimeSlice", "UserConstraint", "PV"
]

VD = pd.read_csv( VD_filenames[0], names=VD_colnames, skiprows=13, low_memory=False )

print( "VD shape: ", VD.shape )
