
# Create 'Assumption_template' file. Based on all combinations of dropdowns.
Assumption_template <- combined_df %>%
  distinct(
    Sector, 
    Subsector, 
    Enduse, 
    Technology, 
    Fuel, 
    scen
  ) %>%
  union_all(
    distinct(
      .,
      Sector, 
      Enduse, 
      Technology, 
      Fuel, 
      scen
    ) %>% 
      mutate(
        Subsector = "All Subsectors"
      )
  ) %>% 
  union_all(
    distinct(
      .,
      Sector, 
      Subsector, 
      Technology, 
      Fuel, 
      scen
    ) %>% 
      mutate(
        Enduse = "All Enduse"
      )
  ) %>% 
  union_all(
    distinct(
      .,
      Sector, 
      Subsector, 
      Enduse, 
      Fuel, 
      scen
    ) %>% 
      mutate(
        Technology = "All Technology"
      )
  ) %>% 
  arrange(across()) %>% 
  select(Scenario =scen, Sector, Subsector, Fuel,Technology, Enduse ) %>% 
  mutate(Summary_assumption = "") 

Assumption_template %>%  writexl::write_xlsx("TIMES_assumption_summary.xlsx")
