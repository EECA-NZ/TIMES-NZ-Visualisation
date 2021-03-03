library(shiny)
library(magrittr)
library(tidyverse)
library(ggiraph)
library(scales)

width_svg_const <- 16
height_svg_const <- 6

theme_set(theme_minimal(base_size = 20))

server <- function(input, output){
  
  make_ggiraph_layer <- function(.ggobject, .add_totals = FALSE){
    if (.add_totals == TRUE) {
      totals_df <- .ggobject$data %>%
        group_by(scen, Period) %>%
        summarise(total = sum(Value), .groups = "drop") %>%
        mutate(data_id2 = paste0(Period, scen),
               tool_tip2 = paste0("Total (", Period, "): ",
                                  round(total, 1), " ",
                                  .ggobject$labels$y))
      
      .ggobject <- .ggobject +
        geom_point_interactive(aes(x = Period, y = total,
                                   tooltip = tool_tip2,
                                   data_id = data_id2),
                               stat = "identity",
                               data = totals_df)
    }
    
    # call chart to frame - have to do this to use ggiraph and to set width
    ggiraph_obj <- .ggobject %>%
      ggiraph(ggobj = .,
              width_svg = width_svg_const,
              height_svg = height_svg_const) %>% 
      girafe_options(opts_tooltip(opacity = .7),
                     opts_selection(type = "single"),
                     opts_toolbar(saveaspng = TRUE),
                     opts_hover(css = "fill:red;stroke:orange;r:5pt;"))
  }
  
  output$assumptions_gplot <- renderggiraph({ 
    chart_data <- assumptions_df %>% mutate(data_id = paste0(Period,Scenario),
                                            tool_tip = paste0(Scenario,
                                                              " (", Period, "): ",
                                                              tool_tip_pre,
                                                              formatC(Value, format="f", big.mark = ",", digits = 0),
                                                              tool_tip_trail)) %>%
      filter(Parameter == input$ass_ass_select)
    
    aa <- ggplot(chart_data, aes(x = Period, y = Value,
                                 data_id = data_id, tooltip = tool_tip,
                                 group = Scenario, color = Scenario)) +
      geom_point_interactive() + 
      geom_line() +
      ylim(0,NA) + 
      labs(x = "Year", y = chart_data$Units)
    
    make_ggiraph_layer(aa)
    
  })
  
  output$emissions_plot <- renderggiraph({ 
    chart_data <- combined_df %>% 
      filter(data_group == "Emissions") %>%
      group_by(.data[[input$emi_group_select]], Period, scen) %>%
      summarise(Value = sum(Value), .groups = "drop") %>%
      mutate(data_id := paste0(.data[[input$emi_group_select]], Period, scen),
             tool_tip := paste0(.data[[input$emi_group_select]], " (", Period, "): ",
                                formatC(Value, format="f", big.mark = ",", digits = 0),
                                "kT"))
    
    aa <- ggplot(chart_data,
                 aes(x = Period)) +
      geom_bar_interactive(aes(y = Value,
                               tooltip = tool_tip,
                               data_id = data_id,
                               group = .data[[input$emi_group_select]],
                               fill = .data[[input$emi_group_select]]),
                           stat = "identity") +
      ylim(0, NA) + #causes warning message for sub zero values...
      facet_grid(cols = vars(scen)) +
      ggtitle(paste0("Emissions by ", input$emi_group_select)) +
      theme(axis.title = element_text(size = 10, color = "grey20"),
            axis.text = element_text(size = 20)) +
      labs(x = "Year", y = "kT CO2")
    
    make_ggiraph_layer(aa, TRUE)
  })
  
  output$primary_gplot <- renderggiraph({ 
    chart_data <- combined_df %>% 
      filter(data_group == "Primary Energy",
             Attribute == "Domestic") %>%
      group_by(Fuel, Period, scen) %>%
      summarise(Value = sum(Value), .groups = "drop") %>%
      mutate(data_id = paste0(Fuel, Period, scen),
             tool_tip = paste0(Fuel, " (", Period,"): ",
                               formatC(Value, format="f", big.mark = ",", digits = 0),
                               "PJ"))
    
    aa <- ggplot(chart_data, aes(x = Period, y = Value)) +
      geom_bar_interactive(aes(tooltip = tool_tip, data_id = data_id,
                               group = Fuel, fill = Fuel), stat = "identity") +
      ylim(0, NA) + 
      facet_grid(cols = vars(scen)) +
      ggtitle(paste0("Primary Energy")) +
      theme(axis.title = element_text(size = rel(0.9), color = "grey20")) +
      labs(x = "Year", y = "PJ")
    
    make_ggiraph_layer(aa, .add_totals = TRUE)
    
  })
  
  output$imports_gplot <- renderggiraph({ 
    chart_data <- combined_df %>% 
      filter(data_group == "Primary Energy",
             Attribute == "Net Imports",
             Fuel %in% c("LNG", "Oil Products")) %>%
      group_by(Fuel, Period, scen) %>%
      summarise(Value = sum(Value), .groups = "drop") %>%
      mutate(data_id = paste0(Fuel, Period, scen),
             tool_tip = paste0(Fuel, " (", Period,"): ",
                               formatC(Value, format="f", big.mark = ",", digits = 0),
                               "PJ"))
    
    aa <- ggplot(chart_data, aes(x = Period)) +
      geom_bar_interactive(aes(y = Value,
                               tooltip = tool_tip, data_id = data_id,
                               group = Fuel, fill = Fuel), stat = "identity") +
      ylim(0,NA) + 
      facet_grid(cols = vars(scen)) +
      ggtitle(paste0("Net Imports of Energy")) +
      theme(axis.title = element_text(size = rel(0.9), color = "grey20")) +
      labs(x = "Year", y = "PJ")
    
    make_ggiraph_layer(aa, .add_totals = TRUE)
    
  })
  
  output$gasprod_gplot <- renderggiraph({ 
    chart_data <- combined_df %>% 
      filter(data_group == "Primary Energy",
             Attribute == "Gas Resources") %>%
      group_by(Period, scen) %>% 
      summarise(Value = sum(Value), .groups = "drop") %>%
      mutate(data_id = paste0(Period, scen),
             tool_tip = paste0("Natural Gas (", Period,"): ",
                               formatC(Value, format="f", big.mark = ",", digits = 0),
                               "PJ"))
    
    aa <- ggplot(chart_data, aes(x = Period, y = Value, tooltip = tool_tip, data_id = data_id)) +
      geom_bar_interactive(stat = "identity") +
      ylim(0,NA) + 
      facet_grid(cols = vars(scen)) +
      ggtitle(paste0("Domestic Gas Production")) +
      theme(axis.title = element_text(size = rel(0.9), color = "grey20")) +
      labs(x = "Year", y = "PJ")
    
    make_ggiraph_layer(aa)
    
  })
  
  output$electricity_plot <- renderggiraph({
    y_title <- if_else(input$sup_ele_gencap_select == "Generation in TWh", "TWh", "GW")
    
    chart_data <- combined_df %>% 
      filter(data_group == "Electricity",
             Attribute == input$sup_ele_gencap_select) %>% 
      group_by(Fuel, Period, scen) %>%
      summarise(Value = sum(Value), .groups = "drop") %>% 
      mutate(data_id = paste0(Fuel,Period,scen),
             tool_tip = paste0(Fuel, " (", Period,"): ", round(Value, 1),
                               y_title))
    
    aa <- ggplot(chart_data, aes(x = Period)) +
      geom_bar_interactive(aes(y = Value,
                               tooltip = tool_tip, data_id = data_id,
                               group = Fuel, fill = Fuel), stat = "identity") +
      ylim(0, NA) + 
      labs(x = "Year", y = y_title) +
      ggtitle(paste0("Electricity ", input$sup_ele_gencap_select)) +
      theme(axis.title = element_text(size = rel(0.9), color = "grey20")) +
      facet_grid(cols = vars(scen))
    
    make_ggiraph_layer(aa, TRUE)
    
  })
  
  output$supplem_plot <- renderggiraph({ 
    
    chart_data <- combined_df %>% 
      filter(data_group == "Primary Energy",
             Attribute == "Supplementary Processes",
             Technology == input$sup_oth_gas_select) %>% 
      group_by(Sector, Period, scen) %>% 
      summarise(Value = sum(Value), .groups = "drop") %>%
      mutate(data_id = paste0(Sector, Period, scen),
             tool_tip = paste0(Sector," (", Period,"): ",
                               formatC(Value, format="f", big.mark = ",", digits = 1),
                               "PJ"))
    
    aa <- ggplot(chart_data, aes(x = Period)) +
      geom_bar_interactive(aes(y = Value, 
                               tooltip = tool_tip, data_id = data_id,
                               group = Sector, fill = Sector),stat = "identity") +
      ylim(0,NA) + 
      facet_grid(cols = vars(scen)) +
      ggtitle(paste0(input$sup_oth_gas_select)) +
      labs(x = "Year", y = "PJ") +
      theme(axis.title = element_text(size = rel(0.9), color = "grey20"))
    
    make_ggiraph_layer(aa, .add_totals = TRUE)
    
  })
  
  output$energy_by_sector_plot <- renderggiraph({ 
    
    chart_data <- combined_df %>% 
      filter(data_group == "Energy - high level",
             Fuel == input$nrg_sec_fuel_select | input$nrg_sec_fuel_select == "All") %>%
      group_by(Sector,Period,scen) %>% 
      summarise(Value = sum(Value), .groups = "drop") %>%
      mutate(data_id = paste0(Sector,Period,scen),
             tool_tip = paste0(Sector," (", Period,"): ",
                               formatC(Value, format="f", big.mark = ",", digits = 0), "PJ"))
    
    aa <- ggplot(chart_data, aes(x = Period)) +
      geom_bar_interactive(aes(y = Value,
                               tooltip = tool_tip, data_id = data_id,
                               group = Sector, fill = Sector),
                           stat = "identity") +
      ylim(0, NA) + 
      facet_grid(cols = vars(scen)) +
      labs(x = "Year", y = "PJ") +
      ggtitle(paste0("Consumption of Energy - ", input$nrg_sec_fuel_select)) +
      theme(axis.title = element_text(size = rel(0.9), color = "grey20"))
    
    make_ggiraph_layer(aa, .add_totals = TRUE)
    
  }) 
  
  output$energy_by_fuel_plot <- renderggiraph({ 
    
    
    chart_data <- combined_df %>% 
      filter(data_group == c("Energy - high level"),
             Sector == input$nrg_fuel_sec_select | input$nrg_fuel_sec_select == "All") %>%
      group_by(Fuel,Period,scen) %>% 
      summarise(Value = sum(Value), .groups = "drop") %>%
      mutate(data_id = paste0(Fuel,Period,scen),
             tool_tip = paste0(Fuel," (", Period,"): ",formatC(Value, format="f", big.mark = ",", digits = 0), "PJ"))
    
    aa <- ggplot(chart_data, aes(x = Period)) +
      geom_bar_interactive(aes(y = Value,
                               tooltip = tool_tip, data_id = data_id,
                               group = Fuel, fill = Fuel),
                           stat = "identity") +
      ylim(0,NA) + 
      facet_grid(cols = vars(scen)) +
      ggtitle(paste0("Consumption of Energy in ", input$nrg_fuel_sec_select)) +
      labs(x = "Year", y = "PJ") +
      theme(axis.title = element_text(size = rel(0.9), color = "grey20"))
    
    make_ggiraph_layer(aa, .add_totals = TRUE)
    
  })
  
  output$industrial_plot <- renderggiraph({ 
    
    chart_data <- combined_df %>% 
      filter(data_group == "Industry - detailed",
             Sector == input$nrg_inddd_sect_select) %>%
      group_by(Fuel,Period,scen) %>% 
      summarise(Value = sum(Value), .groups = "drop") %>%
      mutate(data_id = paste0(Fuel,Period,scen),
             tool_tip = paste0(Fuel," (", Period,"): ",formatC(Value, format="f", big.mark = ",", digits = 0), "PJ"))
    
    aa <- ggplot(chart_data, aes(x = Period)) +
      geom_bar_interactive(aes(y = Value,
                               tooltip = tool_tip, data_id = data_id,
                               group = Fuel, fill = Fuel),
                           stat = "identity") +
      ylim(0,NA) + 
      facet_grid(cols = vars(scen)) +
      ggtitle(paste0("Energy Consumption in ", input$nrg_inddd_sect_select)) +
      labs(x = "Year", y = "PJ") +
      theme(axis.title = element_text(size = rel(0.9), color = "grey20"))
    
    make_ggiraph_layer(aa, .add_totals = TRUE)
    
  })
  
  output$resi_com_plot <- renderggiraph({ 
    
    chart_data <- combined_df %>%
      filter(data_group == "RES and COM Services",
             Sector == input$nrg_rescom_select) %>%
      group_by(.data[[input$nrg_rescom_fueltech_select]],Period,scen) %>%
      summarise(Value = sum(Value), .groups = "drop") %>% 
      mutate(data_id = paste0(.data[[input$nrg_rescom_fueltech_select]], Period, scen),
             tool_tip = paste0(.data[[input$nrg_rescom_fueltech_select]]," (", Period,"): ",round(Value,1), "PJ"))
    
    aa <- ggplot(chart_data, aes(x = Period)) +
      geom_bar_interactive(aes(y = Value,
                               tooltip = tool_tip, data_id = data_id,
                               group = .data[[input$nrg_rescom_fueltech_select]],
                               fill = .data[[input$nrg_rescom_fueltech_select]]),
                           stat = "identity") +
      ylim(0,NA) + 
      labs(x = "Year", y = "PJ") +
      ggtitle(paste0("Energy Consumption in ", input$nrg_rescom_select)) +
      theme(axis.title = element_text(size = rel(0.9), color = "grey20")) +
      facet_grid(cols = vars(scen)) #change formatting
    
    make_ggiraph_layer(aa, .add_totals = TRUE)
    
  })
  
  
  transport_chart_data <- reactive({
    chart_data <- NULL
    if(input$nrg_trans_brkdwn_select == "Transport Fuels"){
      chart_data$df <- combined_df %>% 
        filter(data_group == "Energy - detailed",
               Sector == "Transport") %>%
        group_by(Fuel, Period, scen) %>% 
        summarise(Value = sum(Value), .groups = "drop") %>%
        mutate(data_id = paste0(Fuel, Period, scen),
               tool_tip = paste0(Fuel," (", Period,"): ",formatC(Value, format="f", big.mark = ",", digits = 0), "PJ"))
      
      chart_data$group_by_var <- "Fuel"
      chart_data$y_title <- "PJ"
      chart_data$title_text <- c("Energy Consumption in Transport")
    } else if(input$nrg_trans_brkdwn_select == "Transport Types"){
      chart_data$df <- combined_df %>%
        rename(Type = Sector) %>% 
        filter(data_group == "Transport",
               Attribute == "PJ") %>%
        group_by(Type, Period, scen) %>% 
        summarise(Value = sum(Value), .groups = "drop") %>%
        mutate(data_id = paste0(Type, Period, scen),
               tool_tip = paste0(Type," (", Period,"): ",formatC(Value, format="f", big.mark = ",", digits = 0), " PJ"))
      
      chart_data$group_by_var <- "Type"
      chart_data$y_title <- "PJ"
      chart_data$title_text <- c("Energy Consumption in Transport")
    } else if(input$nrg_trans_brkdwn_select == "Fleet Numbers"){
      chart_data$df <- combined_df %>% 
        filter(data_group == "Transport",
               Attribute == "Number of Vehicles, m") %>% 
        filter(input$nrg_trans_sector_select == "All" | Sector == input$nrg_trans_sector_select) %>%
        group_by(Technology,Period,scen) %>%
        summarise(Value = sum(Value), .groups = "drop")
      
      chart_data$title_text <- paste0("Transport Fleet Numbers - ", input$nrg_trans_sector_select)
      
      if(input$nrg_trans_sector_select == "Car"){
        chart_data$df$Value <- chart_data$df$Value / 1000
        chart_data$df %<>% mutate(data_id = paste0(Technology,Period,scen), tool_tip = paste0(Technology," (", Period,"): ",formatC(Value, format="f", big.mark = ",", digits = 1), " M Vehicles"))
        chart_data$group_by_var <- c("Technology")
        chart_data$y_title <- c("Millions of Vehicles")
      } else {
        chart_data$df$Value <- 1000 * chart_data$df$Value
        chart_data$df %<>% mutate(data_id = paste0(Technology,Period,scen),
                                  tool_tip = paste0(Technology," (", Period,"): ",formatC(Value, format="f", big.mark = ",", digits = 0), " Vehicles"))
        chart_data$group_by_var <- c("Technology")
        chart_data$y_title <- c("Vehicles")
      }
      
    }
    chart_data
  })
  
  output$transport_plot <- renderggiraph({ 
    
    aa <- ggplot(transport_chart_data()$df, aes(x = Period)) +
      geom_bar_interactive(aes(y = Value,
                               tooltip = tool_tip, data_id = data_id,
                               group = .data[[transport_chart_data()$group_by_var]],
                               fill = .data[[transport_chart_data()$group_by_var]]),
                           stat = "identity") +
      facet_grid(cols = vars(scen)) +
      labs(x = "Year", y = transport_chart_data()$y_title) +
      ggtitle(paste0(transport_chart_data()$title_text)) +
      scale_y_continuous(labels = comma_format(),
                         limits = c(0, NA)) +
      theme(axis.title = element_text(size = rel(0.9), color = "grey20"))
    
    make_ggiraph_layer(aa, .add_totals = TRUE)
  })
  
  output$download_transport_data <- downloadHandler(
    filename = function() {
      paste0(input$nrg_trans_brkdwn_select,
             if_else(input$nrg_trans_brkdwn_select == "Fleet Numbers",
                     paste0("_", input$nrg_trans_sector_select),
                     ""),
             ".csv") %>% 
        str_remove_all("[\\s\\/]")
    },
    content = function(file) {
      write.csv(transport_chart_data()$df %>% 
                  select(Fuel, Period, scen, Value), file, row.names = FALSE)
    }
  )
  
  output$efficiency_plot <- renderggiraph({ 
    
    chart_data <- combined_df %>% 
      filter(data_group == "Efficiency") %>% 
      group_by(Sector,Period,scen) %>% 
      summarise(Value = sum(Value), .groups = "drop") %>% 
      mutate(data_id = paste0(Sector,Period,scen),
             tool_tip = paste0(Sector," (", Period,"): ",formatC(Value, format="f", big.mark = ",", digits = 1), "PJ"))
    
    aa <- ggplot(chart_data, aes(x = Period)) +
      geom_bar_interactive(aes(y = Value,
                               tooltip = tool_tip, data_id = data_id,
                               group = Sector, fill = Sector),
                           stat = "identity") + 
      facet_grid(cols = vars(scen)) +
      ggtitle(paste0("Energy saved through efficiency")) +      
      theme(axis.title = element_text(size = rel(0.9), color = "grey20")) +
      labs(x = "Year", y = "PJ")
    
    make_ggiraph_layer(aa, .add_totals = TRUE)
    
  })
  
  
  output$renewables_plot <- renderggiraph({ 
    
    chart_data <- combined_df %>% 
      filter(data_group == "Renewables") %>% 
      group_by(Fuel,Period,scen) %>% 
      summarise(Value = sum(Value), .groups = "drop") %>% 
      mutate(Value = Value * 100,
             data_id = paste0(Fuel,Period,scen),
             tool_tip = paste0(scen, " (",Period,"): ",formatC(Value, format="f", big.mark = ",", digits = 0),"%"))
    
    aa <- ggplot(chart_data, aes(x = Period, y = Value,
                                 tooltip = tool_tip, data_id = data_id,
                                 group = Fuel,
                                 color = Fuel)) +
      geom_point_interactive() + 
      geom_line() +
      ylim(0,100) + 
      facet_grid(cols = vars(scen)) +
      ggtitle(paste0("Renewables")) +   
      theme(axis.title = element_text(size = rel(0.9), color = "grey20")) +
      labs(x = "Year", y = "%")
    
    make_ggiraph_layer(aa)
    
  })
  
  output$prices_plot <- renderggiraph({ 
    
    if(input$price_allele_select == "All Energy Prices in $/GJ"){
      validate(need(input$price_commod_chbx, 'Check at least one fuel'))
      
      chart_data <- prices_df %>% 
        filter(data_group == "Prices",
               Fuel %in% c(input$price_commod_chbx),
               Sector == "NI") %>%
        mutate(data_id = paste0(Fuel, Period, scen),
               tool_tip = paste0(Fuel,", (", Period, "): $",
                                 formatC(Value, format="f", big.mark = ",", digits = 2),
                                 "/GJ"))
      
      aa <- ggplot(chart_data, aes(x = Period, y = Value,
                                   tooltip = tool_tip, data_id = data_id,
                                   group = Fuel, color = Fuel)) +
        geom_point_interactive() +
        geom_line() +
        ylim(-5,80) + 
        ggtitle(paste0("Energy Prices")) +
        facet_grid(cols = vars(scen)) +
        theme(axis.title = element_text(size = rel(0.9), color = "grey20")) +
        labs(x = "Year", y = "$/GJ")
      
    } else {
      chart_data <- prices_df %>% 
        filter(data_group == "Prices",
               Fuel == "Electricity - $/MWh") %>%
        mutate(data_id = paste0(Period, scen, Sector),
               tool_tip = paste0(Fuel,", ", Sector, " (", Period, "): $",
                                 formatC(Value, format="f", big.mark = ",", digits = 2),
                                 "/GJ"))
      
      aa <- ggplot(chart_data, aes(x = Period, y = Value,
                                   tooltip = tool_tip, data_id = data_id,
                                   group = Sector, color = Sector)) +
        geom_point_interactive() + 
        geom_line() +
        ylim(0, NA) + 
        ggtitle(paste0("Energy Prices")) +
        facet_grid(cols = vars(scen)) +
        theme(axis.title = element_text(size = rel(0.9), color = "grey20")) +
        guides(colour = guide_legend(title = "Island")) +
        labs(x = "Year", y = "$/MWh")
      
    }
    make_ggiraph_layer(aa)
    
  })
  
  output$costs_plot <- renderggiraph({ 
    
    chart_data <- combined_df %>% 
      filter(data_group == "Costs",
             Attribute %in% c("Cost_Act","Cost_Inv","Cost_Fom","Cost_Comx"),
             Sector == input$cost_sector_select,
             Period != 2015) %>%
      group_by(Period, scen) %>%
      summarise(Value = sum(Value), .groups = "drop") %>% 
      mutate(data_id = paste0(Period,scen),
             tool_tip = paste0(input$cost_sector_select,
                               " (", Period,"): $",
                               formatC(Value, format="f", big.mark = ",", digits = 0),
                               "M"))
    
    aa <- ggplot(chart_data, aes(x = Period, y = Value,
                                 tooltip = tool_tip, data_id = data_id)) +
      geom_bar_interactive(stat = "identity") +
      ylim(0,NA) + 
      facet_grid(cols = vars(scen)) +
      ggtitle(paste0("Total Annualised Costs by Sector (Undiscounted) - ", input$cost_sector_select)) +
      theme(axis.title = element_text(size = 10, color = "grey20")) +
      labs(x = "Year", y = "$M")
    
    make_ggiraph_layer(aa)
    
  })
  
} 
