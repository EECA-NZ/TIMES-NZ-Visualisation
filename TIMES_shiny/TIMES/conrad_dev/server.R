server <- function(input, output, session){
  
  # The main dataset set up as a reactive object. It gets refiltered whenever an input dropdown is changed
  filtered_data <- reactive({
    
    combined_df %>% 
      filter(
        data_group == input$topic,
        Sector == input$sector,
        Attribute == input$attr,
        Technology == input$tech,
        Fuel == input$fuel
      )
    
  })
  
  # The assumptions dataset set up as a reactive object.
  filtered_assumptions <- reactive({
    
    assumptions_df %>% 
      filter(Parameter == input$assumptions)
    
  })
  
  # A reactive object based on the hierarchy dataset. When on the overview tab, it shows all topics/data groups.
  # When not on the overview tab it filters to the current tab (using the value returned by input$tabs)
  filtered_dropdowns <- reactive({
    
    if(input$tabs == "Overview"){
      
      hierarchy
      
    } else {
      
      hierarchy %>% filter(str_detect(data_group, input$tabs))
      
    }
    
    
  })
  
  # These are the dropdowns that are generated dynamically and served up to the UI (via the call to uiOutput())
  output$drop_downs <- renderUI({
    
    tagList(
      
      selectInput("topic", "Topic", choices = unique(filtered_dropdowns()$data_group)),
      
      selectInput("sector", "Sector", choices = unique(filtered_dropdowns()$Sector)),
      
      selectInput("attr", "Attribute", choices = unique(filtered_dropdowns()$Attribute)),
      
      selectInput("tech", "Technology", choices = unique(filtered_dropdowns()$Technology)),
      
      selectInput("fuel", "Fuel", choices = unique(filtered_dropdowns()$Fuel))
      
    )
    
  })
  
  # The next few functions 'listen' for changes in the dropdowns and update the dropdowns based
  # on what combinations of filters make sense. 
  # I'm not sure I've totally nailed it but I think it's mostly there.
  observeEvent(input$tabs, {

    df <- filtered_dropdowns() %>% filter(data_group == input$tabs)

    if(input$tabs != "Overview"){

      updateSelectInput(session, "topic", choices = unique(df$data_group))

    }

  }, ignoreNULL = TRUE)
  
  observeEvent(input$topic, {
    
    df <- filtered_dropdowns() %>% filter(data_group == input$topic)
    
    updateSelectInput(session, "sector", choices = unique(df$Sector))
    updateSelectInput(session, "attr", choices = unique(df$Attribute))
    
  }, ignoreNULL = TRUE)
  
  observeEvent(input$sector, {
    
    df <- filtered_dropdowns() %>% filter(data_group == input$topic, Sector == input$sector)
    
    updateSelectInput(session, "attr", choices = unique(df$Attribute))
    updateSelectInput(session, "tech", choices = unique(df$Technology))
    
  }, ignoreNULL = TRUE)
  
  observeEvent(input$attr, {
    
    df <- filtered_dropdowns() %>% filter(Sector == input$sector, Attribute == input$attr)
    
    updateSelectInput(session, "tech", choices = unique(df$Technology))
    
  }, ignoreNULL = TRUE)
  
  observeEvent(input$tech, {
    
    df <- filtered_dropdowns() %>% filter(data_group == input$topic, Technology == input$tech)
    
    updateSelectInput(session, "fuel", choices = unique(df$Fuel))
    
  }, ignoreNULL = TRUE)
  
  # Plots
  
  ## The plot output for the assumptions page.
  output$assumptions_plot <- renderHighchart({
    
    # Read the filtered assumptions dataset and then split by scenario.
    assumptions_data <- filtered_assumptions()
    assumptions_data_kea <- assumptions_data %>% filter(Scenario == "Kea") %>% pull(Value)
    assumptions_data_tui <- assumptions_data %>% filter(Scenario == "Tui") %>% pull(Value)
    
    # Retrieve chart type (to be used in the next step). 
    chart_type_assumptions <- ifelse(input$chart_type_assumptions == "column_percent", "column", input$chart_type_assumptions)
    
    hc <- highchart() %>% 
      hc_title(text = paste0(input$assumptions, " (", unique(assumptions_data$Units), ")")) %>% 
      hc_xAxis(categories = unique(assumptions_data$Period)) %>% 
      hc_yAxis(title = list(text = unique(assumptions_data$Units)), min = min(0, min(assumptions_data_kea), min(assumptions_data_tui))) %>% 
      hc_add_series(
        name = "Kea", data = assumptions_data_kea, type = chart_type_assumptions
      ) %>% 
      hc_add_series(
        name = "Tui", data = assumptions_data_tui, type = chart_type_assumptions
      ) 
    
    if(input$chart_type_assumptions == "column_percent"){
      # This is how we get the 100% stacked bars. Should be similar if we want to do this
      # for area charts
      hc <- hc %>% 
        hc_plotOptions(column = list(stacking = "percent")) %>% 
        hc_yAxis(title = list(text = "%"), min = 0)
      
    }
    
    hc
    
  })
  
  ## Plot output for overview page (Kea). Very similar to code above (but without a percentage chart)
  output$overview_kea <- renderHighchart({
    
    req(input$topic)
    
    plot_data <- filtered_data() %>% filter(scen == "Kea")
    
    # chart_type_overview <- ifelse(input$chart_type_overview == "column_percent", "column", input$chart_type_overview)
    chart_type_overview <- input$chart_type_overview
    
    hc <- highchart() %>% 
      # hc_title(text = "Title placeholder") %>% 
      hc_xAxis(categories = unique(plot_data$Period)) %>% 
      hc_yAxis(title = list(text = unique(plot_data$Attribute)), min = min(0, min(plot_data$Value))) %>% 
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