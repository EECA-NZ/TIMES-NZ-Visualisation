server <- function(input, output, session){

  # Required for creating the event handlers for shinyhelper
  observe_helpers()
  
  # Filter data based on dropdowns
  filtered_data <- reactive({
    
    # This condition is used to add "Select Metric" to the "unit" drop-downs
    if (input$unit == "Select Metric"){
      unit_selected = "Emissions"
    }else{
      unit_selected = input$unit
    }
    
    combined_df %>%
      purrr::when(
        
        input$subsector != "All Subsectors" ~
          
          filter(
            ., Subsector == input$subsector
          ),
        
        ~ .
        
      ) %>% 
      purrr::when(
        
        input$enduse != "All Enduse" ~
          
          filter(
            ., Enduse == input$enduse
          ),
        
        ~ .
        
      ) %>% 
      purrr::when(
        
        input$tech != "All Technology" ~
          
          filter(
            ., Technology == input$tech
          ),
        
        ~ .
        
      ) %>% 
      purrr::when(
        
        input$tabs != "Overview" ~
          
          filter(
            ., Sector == input$tabs, 
          ),
        
        ~ .
        
      ) %>% 
      filter(Parameters == unit_selected)
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
    
    # Explicitly changing the 'All Subsectors' name for Overview tab. Underneath, it still 'points'
    # to 'All Subsectors' (e.g. in the hierarchy)
    subsector_list <- unique(filtered_dropdowns()$Subsector)
    if(input$tabs == "Overview"){
      subsector_list <- c("All Sectors" = "All Subsectors")
    }
    
    tagList(
      selectInput(
        "subsector",
        label = NULL,
        # choices = unique(filtered_dropdowns()$Subsector)
        choices = subsector_list
      ),
      selectInput(
        "enduse",
        label = NULL,
        choices = unique(filtered_dropdowns()$Enduse)
      ),
      selectInput(
        "tech",
        label = NULL,
        choices = unique(filtered_dropdowns()$Technology)
      )#,
      # selectInput(
      #   "unit",
      #   label = NULL,
      #   choices = unique(sort(filtered_dropdowns()$Parameters))
      # )
      
    )
    
  })
  
  # The next few functions 'listen' for changes in the dropdowns and update the dropdowns based
  # on what combinations of filters make sense. 
  # I'm not sure I've totally nailed it but I think it's mostly there.
  
  observeEvent(input$tabs, {
    
    if (input$tabs == "Overview") {
      df <- filtered_dropdowns()
    } else{
      df <- filtered_dropdowns() %>% filter(Sector == input$tabs)
      
    }
    
    # Ordering the attributes 
    order_Parameters <- c("Select Metric", order_attribute(df$Parameters,order_attr))
    
    updateSelectInput(session, "unit", choices = order_Parameters)


  }, ignoreNULL = TRUE)
  
  
  
  observeEvent(input$subsector, {
    
    if (input$subsector == "All Subsectors") {
      df <- filtered_dropdowns()
    } else{
      df <- filtered_dropdowns() %>% filter(Subsector == input$subsector)
      
    }
    
    # Ordering the attributes 
    order_Parameters <- c("Select Metric", order_attribute(df$Parameters,order_attr))
    updateSelectInput(session, "enduse", choices = sort(unique(df$Enduse)))
    updateSelectInput(session, "tech", choices = sort(unique(df$Technology)))
    updateSelectInput(session, "unit", choices = order_Parameters)
    
  }, ignoreNULL = TRUE)
  
  
  observeEvent(input$enduse, {
    if (input$subsector == "All Subsectors" & input$enduse == "All Enduse") {
      
      df <- filtered_dropdowns() #%>% filter(Enduse == input$enduse)
      
    } else {
      df <- filtered_dropdowns() %>% filter(Subsector == input$subsector, Enduse == input$enduse)
      
    }
    # Ordering the attributes 
    order_Parameters <- c("Select Metric", order_attribute(df$Parameters,order_attr))
    updateSelectInput(session, "unit", choices = sort(order_Parameters))
    updateSelectInput(session, "tech", choices = sort(unique(df$Technology)))
    updateSelectInput(session, "unit", choices = order_Parameters)
    
  }, ignoreNULL = TRUE)
  
  
  
  
  observeEvent(input$tech, {
    if (input$subsector == "All Subsectors" & input$enduse == "All Enduse" & input$tech == "All Technology") {
      
      df <- filtered_dropdowns() #%>% filter(Enduse == input$enduse)
      
    } else {
      df <- filtered_dropdowns() %>% filter(Subsector == input$subsector, Enduse == input$enduse, 
                                            Technology == input$tech)
      
    }
    
    # Ordering the attributes 
    order_Parameters <- c("Select Metric", order_attribute(df$Parameters,order_attr))
    
    updateSelectInput(session, "unit", choices = order_Parameters)
    
  }, ignoreNULL = TRUE)
  

  ## column dropdown
  output$Assumption_drop_downs <- renderUI({
    
    if (input$Insght_Switch == FALSE){
      selectInput("assumptions", label = NULL, choices = assumptions_list)
      
    }else{
      selectInput("assumptions", label = NULL, choices = insight_list)
    }
  
    
  })
  
  
  # Selecting the type of data based on switch (Key insight or Assumptions)
  filtered_assumptions <- reactive({
    req(input$assumptions)
    if (input$Insght_Switch == FALSE){
    assumptions_df %>% 
      filter(Parameter == input$assumptions)
    }else{
      insight_df %>% 
        filter(Parameter == input$assumptions)
    }
      
  })
  
  # Selecting title based on switch (Key insight or Assumptions)
  filtered_assumptions_title <- reactive({
    req(input$assumptions)
    if (input$Insght_Switch == FALSE){
        "Assumption"
    }else{
        "Key insight"
    }
    
  })
  
  
  

  # This is used to select the group by values
  group_by <- reactive(
    {
      if (input$Fuel_Switch == TRUE){
        names(filtered_data())[10]
      } else{
        names(filtered_data())[8]
          }
      
    }
  )
  
  # Get max y for current filtered data
  max_y <- reactive({
    
    get_max_y(
      data = filtered_data(),
      group_var = group_by(),
      input_chart_type = input$chart_type
    )
    
  })
  
  
  max_y_assumptions <- reactive({
    
    
    
    get_max_y_assumptions(
      data = filtered_assumptions(),
      group_var = input$assumptions,
      input_chart_type = "line"
    )
    
  })
  
  
  
  # output$assumptions_popup <- renderText({
  #   req(input$subsector)
  #   
  #   caption_lists <- caption_list %>%
  #     filter(Subsector == input$subsector) %>% 
  #     pull(Comment)
  #   
  #   return(as.character(caption_lists))
  #   
  # })
  
  #############################
  ####### Adding intro tour ###
  #############################

  observeEvent(input$intro, {
    introjs(session,
            options = list("nextLabel" = "Next",
                           "prevLabel" = "Previous",
                           "skipLabel" = "Exit",
                           "doneLabel" = "Exit"),
            events = list(onbeforechange = readCallback("switchTabs")#,
                          # "oncomplete"=I('alert("Done")')
            )
    )
  })
  
  
  #############################
  ####### Adding tooltips #####
  #############################
  # 
  # 
  
  output$info_overview <- renderUI({
    
    req(input$subsector)
    
    caption_lists <- caption_list %>%
      filter(
             Tab       == "Overview") %>% 
      pull(Comment)
    
    popify(icon("info-circle"), NULL , caption_lists, placement = "left", trigger = "hover")
    
  })
  
  # Create unique for each tab
  output$info_transport <- renderUI({
    
    req(input$subsector)
    
    # Selecting "All Transport Subsectors"
    if (input$subsector == "All Subsectors") {
      
      select_sector = "All Transport Subsectors"
      
    } else{
      
      select_sector = input$subsector
      
    }
      
    
    caption_lists <- caption_list %>%
      filter(Subsector == select_sector,
             Tab       ==   "Transport") %>% 
      pull(Comment)
    
    popify(icon("info-circle"), NULL , caption_lists, placement = "left", trigger = "hover")
    
  })
  
  output$info_industry <- renderUI({
    
    req(input$subsector)
    
    # Selecting "All Industry  Subsectors"
    if (input$subsector == "All Subsectors") {
      
      select_sector = "All Industry Subsectors"
      
    } else{
      
      select_sector = input$subsector
      
    }
    
    
    caption_lists <- caption_list %>%
      filter(Subsector == select_sector,
             Tab       == "Industrial") %>% 
      pull(Comment)
    
    popify(icon("info-circle"), NULL , caption_lists, placement = "left", trigger = "hover")
    
  })
  
  output$info_commercial <- renderUI({
    
    req(input$subsector)
    
    # Selecting "All Commercial Subsectors"
    if (input$subsector == "All Subsectors") {
      
      select_sector = "All Commercial Subsectors"
      
    } else{
      
      select_sector = input$subsector
      
    }
    
    
    caption_lists <- caption_list %>%
      filter(Subsector == select_sector,
             Tab       == "Commercial"
             ) %>% 
      pull(Comment)
    
    popify(icon("info-circle"), NULL , caption_lists, placement = "left", trigger = "hover")
    
  })
  
  output$info_residential <- renderUI({
    
    req(input$subsector)
    
    # Selecting "All Residential Subsectors"
    if (input$subsector == "All Subsectors") {
      
      select_sector = "All Residential Subsectors"
      
    } else{
      
      select_sector = input$subsector
      
    }
    
    
    caption_lists <- caption_list %>%
      filter(Subsector == select_sector,
             Tab       == "Residential") %>% 
      pull(Comment)
    
    popify(icon("info-circle"), NULL , caption_lists, placement = "left", trigger = "hover")
    
  })
  
  output$info_agriculture <- renderUI({
    
    req(input$subsector)
    
    # Selecting "All Agriculture Subsectors"
    if (input$subsector == "All Subsectors") {
      
      select_sector = "All Agriculture Subsectors"
      
    } else{
      
      select_sector = input$subsector
      
    }
    
    
    caption_lists <- caption_list %>%
      filter(Subsector == select_sector,
             Tab       == "Agriculture") %>% 
      pull(Comment)
    
    popify(icon("info-circle"), NULL , caption_lists, placement = "left", trigger = "hover")
    
  })
  
  output$info_other <- renderUI({
    
    req(input$subsector)
    
    # Selecting "All Other Subsectors"
    if (input$subsector == "All Subsectors") {
      
      select_sector = "All Other Subsectors"
      
    } else{
      
      select_sector = input$subsector
      
    }
    
    
    caption_lists <- caption_list %>%
      filter(Subsector == select_sector,
             Tab       == "Other") %>% 
      pull(Comment)
    
    
    popify(icon("info-circle"), NULL , caption_lists, placement = "left", trigger = "hover")
    
  })
  # captions <- reactive(
  #   caption_lists<- caption_list %>% filter(Subsector == input$subsector) %>% pull(Comment)
  # 
  #   )
  
  ##################################
  #### Assumption  Plotting ########
  ##################################
  
  ## The plot output for the assumptions page.
  output$assumptions_plot <-  renderHighchart({
    
      # Read the filtered assumptions/insight dataset and then split by scenario.
      assumptions_data <- filtered_assumptions() %>%
        rename(Unit = Units) 
      
      assumption_charts(
        data = assumptions_data,
        group_var = Scenario,
        unit = assumptions_data$Unit[1],
        filename = paste(filtered_assumptions_title(), input$assumptions,"line", "(" ,assumptions_data$Unit[1] , ")", sep = " "),
        plot_title = paste0(assumptions_data$Title[1]),
        input_chart_type = "line",
        max_y = NULL #max_y_assumptions()
      )
  
})

  
  ##################################
  ##### Data explorer Plotting #####
  ##################################
  
  
  
  
  ## Plot output for overview page.
  # Kea
  output$overview_kea <- renderHighchart({
    
    req(input$subsector)
    
    plot_data_kea <- filtered_data() %>% filter(scen == "Kea")
    
    generic_charts(
      data = plot_data_kea,
      group_var = group_by(),
      unit = unique(plot_data_kea$Unit),
      filename = paste( "Kea", unique(plot_data_kea$Parameters), "All Sectors", input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0(unique(plot_data_kea$Parameters), " for ", "All Sectors", ", ", input$enduse," and " ,input$tech ),
      input_chart_type = input$chart_type,
      max_y = max_y(),
      credit_text = paste0("TIMES-NZ 2.0", ", Scenario: Kea")
    )
    
  })
  
  # Tui
  output$overview_tui <- renderHighchart({
    
    req(input$subsector)
    
    plot_data_tui <- filtered_data() %>% filter(scen == "Tui")
    
    generic_charts(
      data = plot_data_tui,
      group_var = group_by(),
      unit = unique(plot_data_tui$Unit),
      filename = paste( "Tui", unique(plot_data_tui$Parameters), "All Sectors", input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0(unique(plot_data_tui$Parameters), " for ", "All Sectors", ", ", input$enduse," and " ,input$tech ),
      input_chart_type = input$chart_type,
      max_y = max_y(),
      credit_text = paste0("TIMES-NZ 2.0", ", Scenario: Tui")
    )
    
  })
  
  ## Plot output for Transport page
  # Kea
  output$transport_kea <- renderHighchart({
    
    req(input$subsector)
    
    plot_data_kea <- filtered_data() %>% filter(scen == "Kea", Sector == "Transport")
    
    generic_charts(
      data = plot_data_kea,
      group_var = group_by(),
      unit = unique(plot_data_kea$Unit),
      filename = paste("Kea", "Transport",  unique(plot_data_kea$Parameters), input$subsector, input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0("Transport ",unique(plot_data_kea$Parameters), " for ",input$subsector, ", ", input$enduse," and " ,input$tech ),
      input_chart_type = input$chart_type,
      max_y = max_y(),
      credit_text = paste0("TIMES-NZ 2.0", ", Scenario: Kea")
    )
    
  })
  
  #Tui
  output$transport_tui <- renderHighchart({
    
    plot_data_tui <- filtered_data() %>% filter(scen == "Tui", Sector == "Transport")
    
    generic_charts(
      data = plot_data_tui,
      group_var = group_by(),
      unit = unique(plot_data_tui$Unit),
      filename = paste("Tui", "Transport",  unique(plot_data_tui$Parameters), input$subsector, input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0("Transport ",unique(plot_data_tui$Parameters), " for ",input$subsector, ", ", input$enduse," and " ,input$tech ),
      input_chart_type = input$chart_type,
      max_y = max_y(),
      credit_text = paste0("TIMES-NZ 2.0", ", Scenario: Tui")
    )
    
    
  })
  
  
  
  
  ## Plot output for Industry page
  # Kea
  output$industry_kea <- renderHighchart({
    
    req(input$subsector)
    
    plot_data_kea <- filtered_data() %>% filter(scen == "Kea", Sector == "Industry")
    
    generic_charts(
      data = plot_data_kea,
      group_var = group_by(),
      unit = unique(plot_data_kea$Unit),
      filename = paste("Kea", "Industry",  unique(plot_data_kea$Parameters), input$subsector, input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0("Industry ", unique(plot_data_kea$Parameters), " for ",input$subsector, ", ", input$enduse," and " ,input$tech ),
      input_chart_type = input$chart_type,
      max_y = max_y(),
      credit_text = paste0("TIMES-NZ 2.0", ", Scenario: Kea")
    )
    
  })
  
  #Tui
  output$industry_tui <- renderHighchart({
    
    plot_data_tui <- filtered_data() %>% filter(scen == "Tui", Sector == "Industry")
    
    generic_charts(
      data = plot_data_tui,
      group_var = group_by(),
      unit = unique(plot_data_tui$Unit),
      filename = paste("Tui", "Industry",  unique(plot_data_tui$Parameters), input$subsector, input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0("Industry ", unique(plot_data_tui$Parameters), " for ",input$subsector, ", ", input$enduse," and " ,input$tech ),
      input_chart_type = input$chart_type,
      max_y = max_y(),
      credit_text = paste0("TIMES-NZ 2.0", ", Scenario: Tui")
    )
    
    
  })
  
  
  
  
  ## Plot output for Commercial page
  # Kea
  output$Commercial_kea <- renderHighchart({
    
    req(input$subsector)
    
    plot_data_kea <- filtered_data() %>% filter(scen == "Kea", Sector == "Commercial")
    
    generic_charts(
      data = plot_data_kea,
      group_var = group_by(),
      unit = unique(plot_data_kea$Unit),
      filename = paste("Kea", "Commercial", unique(plot_data_kea$Parameters), input$subsector, input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0("Commercial ", unique(plot_data_kea$Parameters), " for ",input$subsector, ", ", input$enduse," and " ,input$tech ),
      input_chart_type = input$chart_type,
      max_y = max_y(),
      credit_text = paste0("TIMES-NZ 2.0", ", Scenario: Kea")
    )
    
  })
  
  #Tui
  output$Commercial_tui <- renderHighchart({
    
    plot_data_tui <- filtered_data() %>% filter(scen == "Tui", Sector == "Commercial")
    
    generic_charts(
      data = plot_data_tui,
      group_var = group_by(),
      unit = unique(plot_data_tui$Unit),
      filename = paste("Tui", "Commercial",  unique(plot_data_tui$Parameters), input$subsector, input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0("Commercial ", unique(plot_data_tui$Parameters), " for ",input$subsector, ", ", input$enduse," and " ,input$tech ),
      input_chart_type = input$chart_type,
      max_y = max_y(),
      credit_text = paste0("TIMES-NZ 2.0", ", Scenario: Tui")
    )
    
    
  })  
  
  
  ## Plot output for Residential page
  # Kea
  output$Residential_kea <- renderHighchart({
    
    req(input$subsector)
    
    plot_data_kea <- filtered_data() %>% filter(scen == "Kea", Sector == "Residential")
    
    generic_charts(
      data = plot_data_kea,
      group_var = group_by(),
      unit = unique(plot_data_kea$Unit),
      filename = paste("Kea", "Residential",  unique(plot_data_kea$Parameters), input$subsector, input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0("Residential ", unique(plot_data_kea$Parameters), " for ",input$subsector, ", ", input$enduse," and " ,input$tech ),
      input_chart_type = input$chart_type,
      max_y = max_y(),
      credit_text = paste0("TIMES-NZ 2.0", ", Scenario: Kea")
    )
    
  })
  
  #Tui
  output$Residential_tui <- renderHighchart({
    
    plot_data_tui <- filtered_data() %>% filter(scen == "Tui", Sector == "Residential")
    
    generic_charts(
      data = plot_data_tui,
      group_var = group_by(),
      unit = unique(plot_data_tui$Unit),
      filename = paste("Tui", "Residential", unique(plot_data_tui$Parameters), input$subsector, input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0("Residential ", unique(plot_data_tui$Parameters), " for ",input$subsector, ", ", input$enduse," and " ,input$tech ),
      input_chart_type = input$chart_type,
      max_y = max_y(),
      credit_text = paste0("TIMES-NZ 2.0", ", Scenario: Tui")
    )
    
    
  })
  
  
  
  ## Plot output for Agriculture page
  # Kea
  output$Agriculture_kea <- renderHighchart({
    
    req(input$subsector)
    
    plot_data_kea <- filtered_data() %>% filter(scen == "Kea", Sector == "Agriculture")
    
    generic_charts(
      data = plot_data_kea,
      group_var = group_by(),
      unit = unique(plot_data_kea$Unit),
      filename = paste("Kea", "Agriculture",  unique(plot_data_kea$Parameters), input$subsector, input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0("Agriculture ",unique(plot_data_kea$Parameters), " for ",input$subsector, ", ", input$enduse," and " ,input$tech ),
      input_chart_type = input$chart_type,
      max_y = max_y(),
      credit_text = paste0("TIMES-NZ 2.0", ", Scenario: Kea")
    )
    
  })
  
  #Tui
  output$Agriculture_tui <- renderHighchart({
    
    plot_data_tui <- filtered_data() %>% filter(scen == "Tui", Sector == "Agriculture")
    
    generic_charts(
      data = plot_data_tui,
      group_var = group_by(),
      unit = unique(plot_data_tui$Unit),
      filename = paste( "Tui","Agriculture",  unique(plot_data_tui$Parameters), input$subsector, input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0("Agriculture ", unique(plot_data_tui$Parameters), " for ",input$subsector, ", ", input$enduse," and " ,input$tech ),
      input_chart_type = input$chart_type,
      max_y = max_y(),
      credit_text = paste0("TIMES-NZ 2.0", ", Scenario: Tui")
    )
    
    
  })
  
  
  
  ## Plot output for Other page
  # Kea
  output$Other_kea <- renderHighchart({
    
    req(input$subsector)
    
    plot_data_kea <- filtered_data() %>% filter(scen == "Kea", Sector == "Other")
    
    generic_charts(
      data = plot_data_kea,
      group_var = group_by(),
      unit = unique(plot_data_kea$Unit),
      filename = paste("Kea", "Electricity",  unique(plot_data_kea$Parameters), input$subsector, input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0("Electricity ",unique(plot_data_kea$Parameters), " for ",input$subsector, ", ", input$enduse," and " ,input$tech ),
      input_chart_type = input$chart_type,
      max_y = max_y(),
      credit_text = paste0("TIMES-NZ 2.0", ", Scenario: Kea")
    )
    
  })
  
  #Tui
  output$Other_tui <- renderHighchart({
    
    plot_data_tui <- filtered_data() %>% filter(scen == "Tui", Sector == "Other")
    
    generic_charts(
      data = plot_data_tui,
      group_var = group_by(),
      unit = unique(plot_data_tui$Unit),
      filename = paste( "Tui", "Electricity", unique(plot_data_tui$Parameters), input$subsector, input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0("Electricity ",unique(plot_data_tui$Parameters), " for ",input$subsector, ", ", input$enduse," and " ,input$tech ),
      input_chart_type = input$chart_type,
      max_y = max_y(),
      credit_text = paste0("TIMES-NZ 2.0", ", Scenario: Tui")
    )
    
    
  })
  # observeEvent(input$unit, {
  #   
  #   req(input$subsector)
  #   
  #   print(input$tabs)
  #   print(input$subsector)
  #   print(input$enduse)
  #   print(input$tech)
  #   print(input$unit)
  #   print(filtered_data())
  #   
  #   
  # })
  
}