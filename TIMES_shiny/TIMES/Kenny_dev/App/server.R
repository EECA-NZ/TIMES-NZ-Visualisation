server <- function(input, output, session){
  
  filtered_data <- reactive({
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
      filter(Parameters == input$unit)
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
      selectInput(
        "subsector",
        label = NULL,
        choices = unique(filtered_dropdowns()$Subsector)
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
      ),
      selectInput(
        "unit",
        label = NULL,
        choices = unique(sort(filtered_dropdowns()$Parameters))
      )
      
    )
    
  })
  
  # The next few functions 'listen' for changes in the dropdowns and update the dropdowns based
  # on what combinations of filters make sense. 
  # I'm not sure I've totally nailed it but I think it's mostly there.
  
  # observeEvent(input$tabs, {
  #   
  #   df <- filtered_dropdowns() %>% filter(Sector == input$tabs)
  #   
  #   if(input$tabs != "Overview"){
  #     
  #     updateSelectInput(session, "subsector", choices = unique(df$Subsector))
  #     
  #   } else {
  #     updateSelectInput(session, "subsector", choices = "All Subsectors")
  #   }
  #   
  #   
  # }, ignoreNULL = TRUE)
  
  
  observeEvent(input$subsector, {
    
    if (input$subsector == "All Subsectors") {
      df <- filtered_dropdowns()
    } else{
      df <- filtered_dropdowns() %>% filter(Subsector == input$subsector)
      
    }
    
    updateSelectInput(session, "enduse", choices = unique(df$Enduse))
    updateSelectInput(session, "unit", choices = sort(unique(df$Parameters)))
    
  }, ignoreNULL = TRUE)
  
  observeEvent(input$enduse, {
    if (input$subsector == "All Subsectors" & input$enduse == "All Enduse") {
      
      df <- filtered_dropdowns() #%>% filter(Enduse == input$enduse)
      
    } else {
      df <- filtered_dropdowns() %>% filter(Subsector == input$subsector, Enduse == input$enduse)
      
    }
    updateSelectInput(session, "unit", choices = sort(unique(df$Parameters)))
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
    assumptions_data <- filtered_assumptions() %>% 
      rename(Unit = Units)
    
    generic_charts(
      data = assumptions_data,
      group_var = Scenario,
      unit = unique(assumptions_data$Unit),
      filename = paste("Assumption", input$assumptions,input$chart_type_assumptions, "(" ,unique(assumptions_data$Unit) , ")", sep = " "),
      plot_title = paste0("Plot of ",input$assumptions, " (", unique(assumptions_data$Unit), ")"),
      input_chart_type = input$chart_type_assumptions
    )
    
  })
  
  ## Plot output for overview page (Kea). Very similar to code above (but without a percentage chart)
  output$overview_kea <- renderHighchart({
    
    req(input$subsector)
    
    plot_data_kea <- filtered_data() %>% filter(scen == "Kea")
    
    generic_charts(
      data = plot_data_kea,
      group_var = Fuel,
      unit = unique(plot_data_kea$Unit),
      filename = paste( "Kea", input$unit, input$subsector, input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0(input$unit, " plot for ",input$subsector, ", ", input$enduse," and " ,input$tech , " (", unique(plot_data_kea$Unit), ")"),
      input_chart_type = input$chart_type
    )
    
  })
  
  ## Plot output for overview page (Tui). Very similar to code above - this is why I suggested turning this into a function as its mostly copy and paste.
  output$overview_tui <- renderHighchart({
    
    req(input$subsector)
    
    plot_data_tui <- filtered_data() %>% filter(scen == "Tui")
    
    generic_charts(
      data = plot_data_tui,
      group_var = Fuel,
      unit = unique(plot_data_tui$Unit),
      filename = paste( "Tui", input$unit, input$subsector, input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0(input$unit, " plot for ",input$subsector, ", ", input$enduse," and " ,input$tech , " (", unique(plot_data_tui$Unit), ")"),
      input_chart_type = input$chart_type
    )
    
  })
  
  ## Plot output for Transport page
  # Kea
  output$transport_kea <- renderHighchart({
    
    req(input$subsector)
    
    plot_data_kea <- filtered_data() %>% filter(scen == "Kea")
    
    generic_charts(
      data = plot_data_kea,
      group_var = Fuel,
      unit = unique(plot_data_kea$Unit),
      filename = paste( "Kea", input$unit, input$subsector, input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0(input$unit, " plot for ",input$subsector, ", ", input$enduse," and " ,input$tech , " (", unique(plot_data_kea$Unit), ")"),
      input_chart_type = input$chart_type
    )
    
  })
  
  #Tui
  output$transport_tui <- renderHighchart({
    
    plot_data_tui <- filtered_data() %>% filter(scen == "Tui")
    
    generic_charts(
      data = plot_data_tui,
      group_var = Fuel,
      unit = unique(plot_data_tui$Unit),
      filename = paste( "Tui", input$unit, input$subsector, input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0(input$unit, " plot for ",input$subsector, ", ", input$enduse," and " ,input$tech , " (", unique(plot_data_tui$Unit), ")"),
      input_chart_type = input$chart_type
    )
    
    
  })

  
  
  
  ## Plot output for Industry page
  # Kea
  output$industry_kea <- renderHighchart({
    
    req(input$subsector)
    
    plot_data_kea <- filtered_data() %>% filter(scen == "Kea")
    
    generic_charts(
      data = plot_data_kea,
      group_var = Fuel,
      unit = unique(plot_data_kea$Unit),
      filename = paste( "Kea", input$unit, input$subsector, input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0(input$unit, " plot for ",input$subsector, ", ", input$enduse," and " ,input$tech , " (", unique(plot_data_kea$Unit), ")"),
      input_chart_type = input$chart_type
    )
    
  })
  
  #Tui
  output$industry_tui <- renderHighchart({
    
    plot_data_tui <- filtered_data() %>% filter(scen == "Tui")
    
    generic_charts(
      data = plot_data_tui,
      group_var = Fuel,
      unit = unique(plot_data_tui$Unit),
      filename = paste( "Tui", input$unit, input$subsector, input$enduse, input$tech , "(" ,input$chart_type , ")", sep = " "),
      plot_title = paste0(input$unit, " plot for ",input$subsector, ", ", input$enduse," and " ,input$tech , " (", unique(plot_data_tui$Unit), ")"),
      input_chart_type = input$chart_type
    )
    
    
  })
  
}