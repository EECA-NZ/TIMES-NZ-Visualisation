import pandas as pd
import numpy as np
import re

# ======================================================================
# Readme

# This file partly replaces "New_Data_Processing.R" which was used for TIMES-NZ 2.0.

# Initial focus is on generating a "clean" dataframe as per lines 109-142 of the above file.

# Key change is that the files "Schema.xlsx" and "Schema_Technology.csv/xlsx" are no longer used, and instead *six* alternative files are used:

#   Items-List-Commodity-20240110105111.csv which replaces Schema.xlsx
#   Items-List-Process-20240110105048.csv which replaces Schema.xlsx
#   Schema_Attribute_ShortUnit_LongUnit_Parameters.csv which replaces Schema.xlsx
#   Schema_ActivityUnit_2_CapacityUnit.csv which replaces Schema.xlsx
#   Schema_Fuel_to_FuelGroup.csv which replaces Schema.xlsx
#   Schema_Technology_to_TechnologyGroup.csv which replaces Schema_Technology.csv/xlsx

# These two "Item-List" files are generated from Veda, and utilise updated commodity (CommDesc) and technology (TechDesc) descriptions in the ~FI_Comm and ~FI_Process tables.

# CommDesc is a concatenation of Sector -:- Subsector -:- Fuel/Enduse
# TechDesc is a concatenation of Sector -:- Subsector -:- Enduse -:- Technology -:- Fuel

# Note that -:- is used as a separator, as , . ; : and - could potentially all be used in the text field.

# Note also that the Item-List files were generated from files which will form the 2.1.3 release, but should be back-compatible with 2.0 files.

# Other files are manually generated.

# For Schema_Attribute_ShortUnit_LongUnit_Parameters.csv, note that the ShortUnit is as used by TIMES, and the LongUnit is for the visualisation tool (as previously defined in Schema.xlsx)

# Additional notes, as per table below, are:

# PJ can be Fuel Consumption or End Use Demand
# Capacity units are not transferred to the *.dd files, so there is no ShortUnit

# Attribute	ShortUnit	LongUnit	    Parameters
# VAR_FIn	PJ      	PJ	            Fuel Consumption
# VAR_FOut	PJ      	PJ	            End Use Demand
# VAR_Cap		        000 Vehicles	Number of Vehicles
# VAR_FOut	BVkm	    Billion Vehicle Kilometres	Distance Travelled

# The file Schema_ActivityUnit_2_CapacityUnit.csv is required because capacity units are not exported to the *.dd file

# Two points to note here:

# 1. There is very likely (?) a single capacity unit given a combination of activity unit and CAP2ACT (otherwise we would have two words for the same quantity?)
# 2. For vehicles, the CAP2ACT factor of 0.08 reflects a reference point of 80,000 km travelled per vehicle, per year. This is an arbitrary quantity.

# ======================================================================
# Specify folders and filenames for VD files:

VD_filenames = [ "./kea-v2_0_0.vd" ]

VD_colnames = [
    "Attribute", "Commodity", "Process", "Period", "Region", "Vintage", "TimeSlice", "UserConstraint", "PV"
]

VD = pd.read_csv( VD_filenames[0], names=VD_colnames, skiprows=13, low_memory=False )

print( "VD shape: ", VD.shape )
