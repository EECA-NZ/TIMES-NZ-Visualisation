# Load data objects from rda file
load("data/data_for_shiny.rda")

# Replace NAs in main dataset with missing
combined_df <- combined_df %>% 
  mutate(across(where(is.character), ~ifelse(is.na(.), "", .)))

# # Create 'hierarchy' file. Based on all combinations of dropdowns.
# hierarchy <- combined_df %>% 
#   distinct(data_group, Sector, Attribute, Technology, Fuel) %>% 
#   arrange(across()) #%>% 
#   # mutate(across(where(is.character), ~ifelse(is.na(.), "", .)))



# Create 'hierarchy' file. Based on all combinations of dropdowns.
hierarchy <- combined_df %>% 
  distinct(Sector, Subsector,Enduse, Technology,Unit) %>% 
  arrange(across())
