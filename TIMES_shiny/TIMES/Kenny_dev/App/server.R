server <- function(input, output, session){
  
  
  # The main dataset set up as a reactive object. It gets refiltered whenever an input dropdown is changed
  filtered_data <- reactive({
    
    combined_df %>% 
      filter(
        Subsector == input$subsector,
        Enduse == input$enduse,
        Technology == input$tech,
        Unit == input$unit     
      )
    
  })
  
  # The assumptions dataset set up as a reactive object.
  filtered_assumptions <- reactive({
    
    assumptions_df %>% 
      filter(Parameter == input$assumptions)
    
  })
  
  # A reactive object based on the hierarchy dataset. When on the overview tab, it shows all subsectors/data groups.
  # When not on the overview tab it filters to the current tab (using the value returned by input$tabs)
  filtered_dropdowns <- reactive({
    
    if(input$tabs == "Overview"){
      
      hierarchy
      
    } else {
      
      hierarchy %>% filter(str_detect(Sector, input$tabs))
      
    }
    
    
  })
  
  # These are the dropdowns that are generated dynamically and served up to the UI (via the call to uiOutput())
  output$drop_downs <- renderUI({
    
    tagList(
      
      selectInput("subsector", "Subsector", choices = unique(filtered_dropdowns()$Subsector)),
      selectInput("enduse", "End use", choices = unique(filtered_dropdowns()$Enduse)),
      selectInput("tech", "Technology", choices = unique(filtered_dropdowns()$Technology)),
      selectInput("unit", "Unit", choices = unique(filtered_dropdowns()$Unit))
      # ,
      
      # selectInput("fuel", "Fuel", choices = unique(filtered_dropdowns()$Fuel))
      
    )
    
  })
  
  # The next few functions 'listen' for changes in the dropdowns and update the dropdowns based
  # on what combinations of filters make sense. 
  # I'm not sure I've totally nailed it but I think it's mostly there.
  observeEvent(input$tabs, {
    
    df <- filtered_dropdowns() %>% filter(Sector == input$tabs)
    
    if(input$tabs != "Overview"){
      
      updateSelectInput(session, "subsector", choices = unique(df$Subsector))
      
    } else {
        updateSelectInput(session, "subsector", choices = "All Sectors")
    }
    
    
  }, ignoreNULL = TRUE)
  
  
  
  observeEvent(input$subsector, {
    
    if (input$subsector != "All Sectors") {
      df <- filtered_dropdowns() %>% filter(Subsector == input$subsector)
    } else{
      df <- filtered_dropdowns()
    }
    
    
    
    updateSelectInput(session, "enduse", choices = unique(df$Enduse))
    updateSelectInput(session, "unit", choices = unique(df$Unit))
    
  }, ignoreNULL = TRUE)
  
  
  
  observeEvent(input$enduse, {
    if (input$subsector != "All Sectors") {
      
    df <- filtered_dropdowns() %>% filter(Subsector == input$subsector, Enduse == input$enduse)
    } else{
      df <- filtered_dropdowns() %>% filter(Enduse == input$enduse)
    }
    updateSelectInput(session, "unit", choices = unique(df$Unit))
    updateSelectInput(session, "tech", choices = unique(df$Technology))
    
  }, ignoreNULL = TRUE)
  
  
  
  observeEvent(input$unit, {
    
    df <- filtered_dropdowns() %>% filter(Enduse == input$enduse, Unit == input$unit)
    
    updateSelectInput(session, "tech", choices = unique(df$Technology))
    
  }, ignoreNULL = TRUE)
  
  
  
  # observeEvent(input$tech, {
  #   
  #   df <- filtered_dropdowns() %>% filter(Subsector == input$subsector, Technology == input$tech)
  #   
  #   # updateSelectInput(session, "fuel", choices = unique(df$Fuel))
  #   
  # }, ignoreNULL = TRUE)
  # 
  
  
  
  
  
  
  # # The main dataset set up as a reactive object. It gets refiltered whenever an input dropdown is changed
  # filtered_data <- reactive({
  #   
  #   combined_df %>% 
  #     filter(
  #       data_group == input$topic,
  #       Sector == input$sector,
  #       Attribute == input$attr,
  #       Technology == input$tech
  #       # ,
  #       # Fuel == input$fuel
  #     )
  #   
  # })
  # 
  # # The assumptions dataset set up as a reactive object.
  # filtered_assumptions <- reactive({
  #   
  #   assumptions_df %>% 
  #     filter(Parameter == input$assumptions)
  #   
  # })
  # 
  # # A reactive object based on the hierarchy dataset. When on the overview tab, it shows all topics/data groups.
  # # When not on the overview tab it filters to the current tab (using the value returned by input$tabs)
  # filtered_dropdowns <- reactive({
  #   
  #   if(input$tabs == "Overview"){
  #     
  #     hierarchy
  #     
  #   } else {
  #     
  #     hierarchy %>% filter(str_detect(data_group, input$tabs))
  #     
  #   }
  #   
  #   
  # })
  # 
  # # These are the dropdowns that are generated dynamically and served up to the UI (via the call to uiOutput())
  # output$drop_downs <- renderUI({
  #   
  #   tagList(
  #     
  #     selectInput("topic", "Subsector", choices = unique(filtered_dropdowns()$data_group)),
  #     
  #     selectInput("sector", "End use", choices = unique(filtered_dropdowns()$Sector)),
  #     selectInput("tech", "Technology", choices = unique(filtered_dropdowns()$Technology)),
  #     selectInput("attr", "Unit", choices = unique(filtered_dropdowns()$Attribute))
  #     # ,
  #     
  #     # selectInput("fuel", "Fuel", choices = unique(filtered_dropdowns()$Fuel))
  #     
  #   )
  #   
  # })
  # 
  # # The next few functions 'listen' for changes in the dropdowns and update the dropdowns based
  # # on what combinations of filters make sense. 
  # # I'm not sure I've totally nailed it but I think it's mostly there.
  # observeEvent(input$tabs, {
  # 
  #   df <- filtered_dropdowns() %>% filter(data_group == input$tabs)
  # 
  #   if(input$tabs != "Overview"){
  # 
  #     updateSelectInput(session, "topic", choices = unique(df$data_group))
  # 
  #   }
  # 
  # }, ignoreNULL = TRUE)
  # 
  # observeEvent(input$topic, {
  #   
  #   df <- filtered_dropdowns() %>% filter(data_group == input$topic)
  #   
  #   updateSelectInput(session, "sector", choices = unique(df$Sector))
  #   updateSelectInput(session, "attr", choices = unique(df$Attribute))
  #   
  # }, ignoreNULL = TRUE)
  # 
  # observeEvent(input$sector, {
  #   
  #   df <- filtered_dropdowns() %>% filter(data_group == input$topic, Sector == input$sector)
  #   
  #   updateSelectInput(session, "attr", choices = unique(df$Attribute))
  #   updateSelectInput(session, "tech", choices = unique(df$Technology))
  #   
  # }, ignoreNULL = TRUE)
  # 
  # observeEvent(input$attr, {
  #   
  #   df <- filtered_dropdowns() %>% filter(Sector == input$sector, Attribute == input$attr)
  #   
  #   updateSelectInput(session, "tech", choices = unique(df$Technology))
  #   
  # }, ignoreNULL = TRUE)
  # 
  # observeEvent(input$tech, {
  #   
  #   df <- filtered_dropdowns() %>% filter(data_group == input$topic, Technology == input$tech)
  #   
  #   # updateSelectInput(session, "fuel", choices = unique(df$Fuel))
  #   
  # }, ignoreNULL = TRUE)
  
 
  
  
  
   # Plots
  
  ## The plot output for the assumptions page.
  output$assumptions_plot <- renderHighchart({
    
    # Read the filtered assumptions dataset and then split by scenario.
    assumptions_data <- filtered_assumptions()
    assumptions_data_kea <- assumptions_data %>% filter(Scenario == "Kea") %>% pull(Value)
    assumptions_data_tui <- assumptions_data %>% filter(Scenario == "Tui") %>% pull(Value)
    
    # Retrieve chart type (to be used in the next step). 
    chart_type_assumptions <- ifelse(input$chart_type_assumptions == "column_percent", "column", input$chart_type_assumptions)
    
    # # Stacked Plots
    # # Converting the filtered data to stact_plotting
    if (chart_type_assumptions != "line") {
      # Generate the needed dataframe
      sample_data <- 
        assumptions_data %>% 
        # assumptions_df %>%
        # filter(Parameter=="Total GDP") %>%
        select(Scenario,Period,Value) %>%
        pivot_wider(names_from =Scenario,values_from =Value) %>%
        as.data.frame()
      
      measure_columns <- names(sample_data)[-1]
      categories_column <- names(sample_data)[1]
      # Setting the percent bottom
      stacking_type <- ifelse(input$chart_type_assumptions == "column_percent", "percent", "normal")
      Y_lable <- ifelse(input$chart_type_assumptions == "column_percent", "Percent", unique(assumptions_data$Units))
      generic_stacking_charts(
        data = sample_data,
        chart_type = chart_type_assumptions,
        categories_column = categories_column,
        measure_columns = measure_columns,
        stacking_type = stacking_type) %>%
        # Adding plot options
        hc_title(text = paste0(input$assumptions, " (", unique(assumptions_data$Units), ")")) %>%
        hc_xAxis(categories = unique(assumptions_data$Period)) %>%
        hc_yAxis(title = list(text =Y_lable ), min = min(0, min(assumptions_data_kea), min(assumptions_data_tui)))

        # Setting the line plot
        } else {
          
          # Plot if the line plot is selected
          assumptions_data %>% 
          # assumptions_df %>%
          #   filter(Parameter=="Total GDP") %>%
          select(Scenario,Period,Value) %>%
          as.data.frame() %>%
          hchart('line', hcaes(x = Period, y= Value, group = Scenario)) %>% 
          # Add more plot options
          hc_title(text = paste0(input$assumptions, " (", unique(assumptions_data$Units), ")")) %>%
          hc_xAxis(categories = unique(assumptions_data$Period)) %>%
          hc_yAxis(title = list(text = unique(assumptions_data$Units)), min = min(0, min(assumptions_data_kea), min(assumptions_data_tui))) %>%
          hc_xAxis(title = list(text =""))
        
      
        }

  })
  
  ## Plot output for overview page (Kea). Very similar to code above (but without a percentage chart)
  output$overview_kea <- renderHighchart({
    
    req(input$topic)
    
    plot_data <- filtered_data() %>% filter(scen == "Kea")
    
    # chart_type_overview <- ifelse(input$chart_type_overview == "column_percent", "column", input$chart_type_overview)
    chart_type_overview <- input$chart_type_overview
    
    hc <- highchart() %>% 
      # hc_title(text = "Title placeholder") %>% 
      # hc_xAxis(categories = unique(plot_data$Period)) %>% 
      # hc_yAxis(title = list(text = unique(plot_data$Attribute)), min = min(0, min(plot_data$Value))) %>% 
      hc_add_series(
        name = "Kea", data = plot_data$Value, type = chart_type_overview
      ) 
    
    # if(input$chart_type_overview == "column_percent"){
    #   
    #   hc <- hc %>% 
    #     hc_plotOptions(column = list(stacking = "percent")) %>% 
    #     hc_yAxis(title = list(text = "%"), min = 0)
    #   
    # }
    
    hc
    
  })
  
  ## Plot output for overview page (Tui). Very similar to code above - this is why I suggested turning this into a function as its mostly copy and paste.
  output$overview_tui <- renderHighchart({
    
    req(input$topic)
    
    plot_data <- filtered_data() %>% filter(scen == "Tui")
    
    # chart_type_overview <- ifelse(input$chart_type_overview == "column_percent", "column", input$chart_type_overview)
    chart_type_overview <- input$chart_type_overview
    
    hc <- highchart() %>% 
      # hc_title(text = "Title placeholder") %>% 
      hc_xAxis(categories = unique(plot_data$Period)) %>% 
      hc_yAxis(title = list(text = unique(plot_data$Attribute)), min = min(0, min(plot_data$Value))) %>% 
      hc_add_series(
        name = "Tui", data = plot_data$Value, type = chart_type_overview
      ) 
    
    # if(input$chart_type_overview == "column_percent"){
    #   
    #   hc <- hc %>% 
    #     hc_plotOptions(column = list(stacking = "percent")) %>% 
    #     hc_yAxis(title = list(text = "%"), min = 0)
    #   
    # }
    
    hc
    
  })
  
  output$transport_kea <- renderHighchart({
    
    hchart(AirPassengers) # placeholder
    
  })
  
  output$transport_tui <- renderHighchart({
    
    hchart(AirPassengers) # placeholder
    
  })
  
}