server <- function(input, output, session){
  
  
  # The main dataset set up as a reactive object. It gets refiltered whenever an input dropdown is changed
  filtered_data <- reactive({
     if (input$subsector != "All Sectors") {
       combined_df %>% 
         filter(
           Subsector == input$subsector,
           Enduse == input$enduse,
           Technology == input$tech,
           Unit == input$unit     
         )
     }else{
       combined_df %>% 
         filter(
           # Subsector == input$subsector,
           Enduse == input$enduse,
           Technology == input$tech,
           Unit == input$unit  )   
     }
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
      selectInput("subsector", label = NULL, choices = c("All Sectors",unique(filtered_dropdowns()$Subsector))),
      selectInput("enduse", label = NULL, choices = unique(filtered_dropdowns()$Enduse)),
      selectInput("tech", label = NULL, choices = unique(filtered_dropdowns()$Technology)),
      selectInput("unit", label = NULL, choices = unique(filtered_dropdowns()$Unit))
      
      # selectInput("subsector", "Subsector", choices = unique(filtered_dropdowns()$Subsector)),
      # selectInput("enduse", "End use", choices = unique(filtered_dropdowns()$Enduse)),
      # selectInput("tech", "Technology", choices = unique(filtered_dropdowns()$Technology)),
      # selectInput("unit", "Unit", choices = unique(filtered_dropdowns()$Unit))
      
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
    
    if (input$subsector == "All Sectors") {
      df <- filtered_dropdowns()
    } else{
      df <- filtered_dropdowns() %>% filter(Subsector == input$subsector)
      
    }
    
    
    
    updateSelectInput(session, "enduse", choices = unique(df$Enduse))
    updateSelectInput(session, "unit", choices = unique(df$Unit))
    
  }, ignoreNULL = TRUE)
  
  
  
  observeEvent(input$enduse, {
    if (input$subsector == "All Sectors") {
      df <- filtered_dropdowns() %>% filter(Enduse == input$enduse)
      
        } else{
          df <- filtered_dropdowns() %>% filter(Subsector == input$subsector, Enduse == input$enduse)
          
    }
    updateSelectInput(session, "unit", choices = unique(df$Unit))
    updateSelectInput(session, "tech", choices = unique(df$Technology))
    
  }, ignoreNULL = TRUE)
  
  
  
  # observeEvent(input$unit, {
  #   
  #   df <- filtered_dropdowns() %>% filter(Enduse == input$enduse, Unit == input$unit)
  #   
  #   updateSelectInput(session, "tech", choices = unique(df$Technology))
  #   
  # }, ignoreNULL = TRUE)
  
  
  
  
  
  ##################################
  ######## Plotting ################
  ##################################
  
  ## The plot output for the assumptions page.
  output$assumptions_plot <- renderHighchart({
    
    # Read the filtered assumptions dataset and then split by scenario.
    assumptions_data <- filtered_assumptions()
    assumptions_data_kea <- assumptions_data %>% filter(Scenario == "Kea") %>% pull(Value)
    assumptions_data_tui <- assumptions_data %>% filter(Scenario == "Tui") %>% pull(Value)
    
    # Retrieve chart type (to be used in the next step). 
    chart_type_assumptions <- ifelse(input$chart_type_assumptions == "column_percent", "column", input$chart_type_assumptions)
    title_n <- paste0(input$assumptions, " (", unique(assumptions_data$Units), ")")
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
        stacking_type = stacking_type,
        filename = title_n) %>%
        # Adding plot options
        hc_title(text = title_n) %>%
        hc_xAxis(categories = unique(assumptions_data$Period)) %>%
        hc_yAxis(title = list(text =Y_lable ), min = min(0, min(assumptions_data_kea), min(assumptions_data_tui)))

        # Setting the line plot
        } else {
          
          # Plot if the line plot is selected
          sample_data <- assumptions_data %>% 
          as.data.frame() 
          line_plot_assumptions(data = sample_data,
                    filen_title= title_n, 
                    chart_type = "line")  
      }
    
  })
  

  
  ## Plot output for overview page (Kea). Very similar to code above (but without a percentage chart)
  output$overview_kea <- renderHighchart({
    
    req(input$subsector)
    
    plot_data_kae <- filtered_data() %>% filter(scen == "Kea")
    # View(plot_data_kae)
    # chart_type_overview <- input$chart_type_overview
    # chart_type_overview <- ifelse(input$chart_type_overview == "column_percent", "column", input$chart_type_overview)
    # if (input$chart_type_overview == "column_percent") {
    if (input$chart_type == "column_percent") {
      # chart_type_overview <-"column"
      chart_type <-"column"
      stacking_type <- "percent"
      Y_lable <- "Percent"
    } else{
      # chart_type_overview <-input$chart_type_overview
      chart_type <-input$chart_type
      stacking_type <- "normal"
      Y_lable <-  input$unit
    }
    
    # if (chart_type_overview != "line") {
    if (chart_type != "line") {
      # Generate the needed dataframe
      sample_data_kea <- plot_data_kae %>% 
        group_by(Fuel,Period) %>%  
        summarise(Value = sum(Value),.groups = "drop") %>% 
        ungroup() %>% 
        pivot_wider(names_from =Fuel,values_from =Value, 
                    values_fn = sum,values_fill = 0) %>%
        as.data.frame()
      
      measure_columns <- names(sample_data_kea)[-1]
      categories_column <- names(sample_data_kea)[1]
      # Setting the percent bottom
      # stacking_type <- ifelse(chart_type_overview == "column_percent", "percent", "normal")
      
      generic_stacking_charts(
        data = sample_data_kea,
        # chart_type = chart_type_overview,
        chart_type = chart_type,
        categories_column = categories_column,
        measure_columns = measure_columns,
        stacking_type = stacking_type,
        filename = paste(input$subsector, input$enduse, input$unit,'line', sep = "_") ) %>%
        # Adding plot options
        # hc_title(text = paste0(input$assumptions, " (", unique(assumptions_data$Units), ")")) %>%
        hc_xAxis(categories = unique(plot_data_kae$Period)) %>%
        # hc_yAxis(title = list(text =Y_lable ), min = min(0, min(assumptions_data_kea), min(assumptions_data_tui)))
        hc_yAxis(title = list(text =Y_lable ))
      # Setting the line plot
    } else {
      
      # Plot if the line plot is selected
      sample_data <- plot_data_kae %>% 
        # assumptions_df %>%
        #   filter(Parameter=="Total GDP") %>%
        select(Fuel,Period,Value) %>%
        group_by(Fuel,Period) %>%  
        summarise(Value = sum(Value),.groups = "drop") %>% 
        ungroup() %>% 
        as.data.frame() %>% 
      
        # line_plot(data = sample_data,
        #         filen_title= title_n, 
        #         chart_type = "line") %>% 
        
        hchart('line', hcaes(x = Period, y= Value, group = Fuel)) %>%
        # Add more plot options
        # hc_title(text = paste0(input$assumptions, " (", unique(assumptions_data$Units), ")")) %>%
        hc_xAxis(categories = unique(plot_data_kae$Period)) %>%
        # hc_yAxis(title = list(text = input$unit), min = min(0, min(assumptions_data_kea), min(assumptions_data_tui))) %>%
        hc_yAxis(title = list(text = input$unit)) %>%
        hc_xAxis(title = list(text ="")) %>%
        hc_exporting(enabled = TRUE, filename = paste(input$subsector, input$enduse, input$unit,'line', sep = "_") , 
                     buttons = list(contextButton = list(menuItems = c("downloadPNG", "downloadCSV" ))))
    }
    
  })
  
  ## Plot output for overview page (Tui). Very similar to code above - this is why I suggested turning this into a function as its mostly copy and paste.
  output$overview_tui <- renderHighchart({
    
    req(input$subsector)
    
    plot_data_Tui <- filtered_data() %>% filter(scen == "Tui")
    
    # if (input$chart_type_overview == "column_percent") {
    if (input$chart_type == "column_percent") {
      # chart_type_overview <-"column"
      chart_type <-"column"
      stacking_type <- "percent"
      Y_lable <- "Percent"
    } else{
      # chart_type_overview <-input$chart_type_overview
      chart_type <-input$chart_type
      stacking_type <- "normal"
      Y_lable <-  input$unit
    }
    # chart_type_overview <- ifelse(input$chart_type_overview == "column_percent", "column", input$chart_type_overview)
    # chart_type_overview <- input$chart_type_overview
    
    
    # if (chart_type_overview != "line") {
    if (chart_type != "line") {
      # Generate the needed dataframe
      sample_data <- plot_data_Tui %>% 
        group_by(Fuel,Period) %>%  
        summarise(Value = sum(Value),.groups = "drop") %>% 
        ungroup() %>% 
        pivot_wider(names_from =Fuel,values_from =Value, 
                    values_fn = sum,values_fill = 0) %>%
        as.data.frame()
      
      
      measure_columns <- names(sample_data)[-1]
      categories_column <- names(sample_data)[1]
      # Setting the percent bottom
      # stacking_type <- ifelse(chart_type_overview == "column_percent", "percent", "normal")
      
      generic_stacking_charts(
        data = sample_data,
        chart_type = chart_type,
        categories_column = categories_column,
        measure_columns = measure_columns,
        stacking_type = stacking_type,
        filename = paste(input$subsector, input$enduse, input$unit,'line', sep = "_")) %>%
        # Adding plot options
        # hc_title(text = paste0(input$assumptions, " (", unique(assumptions_data$Units), ")")) %>%
        hc_xAxis(categories = unique(plot_data_Tui$Period)) %>%
        # hc_yAxis(title = list(text =Y_lable ), min = min(0, min(assumptions_data_kea), min(assumptions_data_tui)))
        hc_yAxis(title = list(text =Y_lable ))
      # Setting the line plot
    } else {
      
      # Plot if the line plot is selected
      plot_data_Tui %>% 
        # assumptions_df %>%
        #   filter(Parameter=="Total GDP") %>%
        select(Fuel,Period,Value) %>%
        group_by(Fuel,Period) %>%  
        summarise(Value = sum(Value),.groups = "drop") %>% 
        ungroup() %>% 
        as.data.frame() %>%
        hchart('line', hcaes(x = Period, y= Value, group = Fuel)) %>% 
        # Add more plot options
        # hc_title(text = paste0(input$assumptions, " (", unique(assumptions_data$Units), ")")) %>%
        hc_xAxis(categories = unique(plot_data_Tui$Period)) %>%
        # hc_yAxis(title = list(text = input$unit), min = min(0, min(assumptions_data_kea), min(assumptions_data_tui))) %>%
        hc_yAxis(title = list(text = input$unit)) %>%
        hc_xAxis(title = list(text =""))%>%
        hc_exporting(enabled = TRUE, filename = paste(input$subsector, input$enduse, input$unit,'line', sep = "_") , 
                     buttons = list(contextButton = list(menuItems = c("downloadPNG", "downloadCSV" ))))
      
      
    }
    
  })
  
  ## Plot output for Transport page
  # Kea
  output$transport_kea <- renderHighchart({
    
    # hchart(AirPassengers) # placeholder
    
    # req(input$subsector)
    
    plot_data_kae <- filtered_data() %>% filter(scen == "Kea")
    
    # chart_type_overview <- input$chart_type_overview
    # chart_type_overview <- ifelse(input$chart_type_overview == "column_percent", "column", input$chart_type_overview)
    if (input$chart_type == "column_percent") {
      chart_type <-"column"
      stacking_type <- "percent"
      Y_lable <- "Percent"
    } else{
      chart_type <-input$chart_type
      stacking_type <- "normal"
      Y_lable <-  input$unit
    }
    
    if (chart_type != "line") {
      # Generate the needed dataframe
      sample_data_kea <- plot_data_kae %>% 
        group_by(Fuel,Period) %>%  
        summarise(Value = sum(Value),.groups = "drop") %>% 
        ungroup() %>% 
        pivot_wider(names_from =Fuel,values_from =Value, 
                    values_fn = sum,values_fill = 0) %>%
        as.data.frame()
      
      measure_columns <- names(sample_data_kea)[-1]
      categories_column <- names(sample_data_kea)[1]
      # Setting the percent bottom
      # stacking_type <- ifelse(chart_type_overview == "column_percent", "percent", "normal")
      
      generic_stacking_charts(
        data = sample_data_kea,
        chart_type = chart_type,
        categories_column = categories_column,
        measure_columns = measure_columns,
        stacking_type = stacking_type,
        filename = paste(input$subsector, input$enduse, input$unit,'line', sep = "_")) %>%
        # Adding plot options
        # hc_title(text = paste0(input$assumptions, " (", unique(assumptions_data$Units), ")")) %>%
        hc_xAxis(categories = unique(plot_data_kae$Period)) %>%
        # hc_yAxis(title = list(text =Y_lable ), min = min(0, min(assumptions_data_kea), min(assumptions_data_tui)))
        hc_yAxis(title = list(text =Y_lable ))
      # Setting the line plot
    } else {
      
      # Plot if the line plot is selected
      plot_data_kae %>% 
        # assumptions_df %>%
        #   filter(Parameter=="Total GDP") %>%
        select(Fuel,Period,Value) %>%
        group_by(Fuel,Period) %>%  
        summarise(Value = sum(Value),.groups = "drop") %>% 
        ungroup() %>% 
        as.data.frame() %>%
        hchart('line', hcaes(x = Period, y= Value, group = Fuel)) %>% 
        # Add more plot options
        # hc_title(text = paste0(input$assumptions, " (", unique(assumptions_data$Units), ")")) %>%
        hc_xAxis(categories = unique(plot_data_kae$Period)) %>%
        # hc_yAxis(title = list(text = input$unit), min = min(0, min(assumptions_data_kea), min(assumptions_data_tui))) %>%
        hc_yAxis(title = list(text = input$unit)) %>%
        hc_xAxis(title = list(text ="")) %>%
        hc_exporting(enabled = TRUE, filename = paste(input$subsector, input$enduse, input$unit,'line', sep = "_") , 
                     buttons = list(contextButton = list(menuItems = c("downloadPNG", "downloadCSV" ))))
    }
    
  })
  
  #Tui
  output$transport_tui <- renderHighchart({
    
    # hchart(AirPassengers) # placeholder
    # req(input$subsector)
    
    plot_data_Tui <- filtered_data() %>% filter(scen == "Tui")
    
    if (input$chart_type == "column_percent") {
      chart_type <-"column"
      stacking_type <- "percent"
      Y_lable <- "Percent"
    } else{
      chart_type <-input$chart_type
      stacking_type <- "normal"
      Y_lable <-  input$unit
    }
    # chart_type_overview <- ifelse(input$chart_type_overview == "column_percent", "column", input$chart_type_overview)
    # chart_type_overview <- input$chart_type_overview
    
    
    if (chart_type != "line") {
      # Generate the needed dataframe
      sample_data <- plot_data_Tui %>% 
        group_by(Fuel,Period) %>%  
        summarise(Value = sum(Value),.groups = "drop") %>% 
        ungroup() %>% 
        pivot_wider(names_from =Fuel,values_from =Value, 
                    values_fn = sum,values_fill = 0) %>%
        as.data.frame()
      
      
      measure_columns <- names(sample_data)[-1]
      categories_column <- names(sample_data)[1]
      # Setting the percent bottom
      # stacking_type <- ifelse(chart_type_overview == "column_percent", "percent", "normal")
      
      generic_stacking_charts(
        data = sample_data,
        chart_type = chart_type,
        categories_column = categories_column,
        measure_columns = measure_columns,
        stacking_type = stacking_type,
        filename = paste(input$subsector, input$enduse, input$unit,'line', sep = "_")) %>%
        # Adding plot options
        # hc_title(text = paste0(input$assumptions, " (", unique(assumptions_data$Units), ")")) %>%
        hc_xAxis(categories = unique(plot_data_Tui$Period)) %>%
        # hc_yAxis(title = list(text =Y_lable ), min = min(0, min(assumptions_data_kea), min(assumptions_data_tui)))
        hc_yAxis(title = list(text =Y_lable ))
      # Setting the line plot
    } else {
      
      # Plot if the line plot is selected
      plot_data_Tui %>% 
        # assumptions_df %>%
        #   filter(Parameter=="Total GDP") %>%
        select(Fuel,Period,Value) %>%
        group_by(Fuel,Period) %>%  
        summarise(Value = sum(Value),.groups = "drop") %>% 
        ungroup() %>% 
        as.data.frame() %>%
        hchart('line', hcaes(x = Period, y= Value, group = Fuel)) %>%  
        # Add more plot options
        # hc_title(text = paste0(input$assumptions, " (", unique(assumptions_data$Units), ")")) %>%
        hc_xAxis(categories = unique(plot_data_Tui$Period)) %>%
        # hc_yAxis(title = list(text = input$unit), min = min(0, min(assumptions_data_kea), min(assumptions_data_tui))) %>%
        hc_yAxis(title = list(text = input$unit)) %>%
        hc_xAxis(title = list(text ="")) %>% 
        hc_exporting(enabled = TRUE, filename = paste(input$subsector, input$enduse, input$unit,'line', sep = "_") , 
                     buttons = list(contextButton = list(menuItems = c("downloadPNG", "downloadCSV" ))))
    }
    
    
  })
  
}