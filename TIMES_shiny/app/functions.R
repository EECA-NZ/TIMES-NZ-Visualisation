# These are the functions used



########################################
######### Highchart Options ############
########################################

# Setting language options in highchart
hcoptslang <- getOption("highcharter.lang")

# Adding thousand separator to highchart
hcoptslang$thousandsSep <- ","

# updating the language settings
options(highcharter.lang = hcoptslang)


########################################
#########  Functions NEEDED  ###########
########################################

# Function to get max y from current filters (for the generic plotting function)
get_max_y <- function(data, group_var, input_chart_type){
  
  total_by_grp <- data %>% 
      
      # !!sym is used to call the group_var as a string
      group_by(!!sym(group_var), Period, scen) %>%  
      
      summarise(Value = sum(Value), .groups = "drop") %>% 
      
      ungroup()
  # Extracting the periods
  total_by_period <- data %>% 
    
    group_by(Period, scen) %>%  
    
    summarise(Value = sum(Value), .groups = "drop") %>% 
    
    ungroup()
  
  
  # Conditions to skip around percentage plots
  if(input_chart_type == "column_percent"){
    
    max_val <- 100
    
  } else if(input_chart_type %in% c("column", "area")) {
    
    max_val <- max(total_by_period$Value)
    
  } else {
    
    max_val <- max(total_by_grp$Value)
    
  }
  
  return(max_val)
  
}


# # Get max y from current filters (for the assumption plotting function)
# Currently not needed since we don't limit the max value
# get_max_y_assumptions <- function(data, group_var, input_chart_type){
#   
#   total <- data %>% 
#     filter(Parameter == group_var) %>% 
#     group_by(Period) %>% 
#     summarise(Value = sum(Value)) %>% 
#     ungroup()
#   
#   total_by_scenario <- data %>% 
#     filter(Parameter == group_var)
#   
#   if(input_chart_type == "column_percent"){
#     
#     max_val <- 100
#     
#   } else if(input_chart_type %in% c("column", "area")) {
#     
#     max_val <- max(total$Value)
#     
#   } else {
#     
#     max_val <- max(total_by_scenario$Value)
#     
#   }
#   
#   return(max_val)
#   
# }




########################################
######### Highchart Options ############
########################################

# Plotting theme to use
my_theme <-  hc_theme(
  
  chart = list(
    # Setting the fonts used
    style = list(
      
    fontFamily = "Source Sans Pro",   # Font style used 
    
    color= '#666666'                  # Font color used 
    
  )))


# Generic Plotting function
generic_charts <- function(data,             # The filtered data 
                           group_var,        # The stacking (fill-by) variable
                           unit,             # Metric selected 
                           filename,         # Download name
                           plot_title,       # Plot title
                           input_chart_type, # Type of plot 
                           max_y,            # Maximum y value
                           credit_text       # 
                           ) {
  
  # Conditions for percentage plots
  if (input_chart_type == "column_percent") {
    
    chart_type    <- "column"    # Setting the plot type 
    
    stacking_type <- "percent"   # Setting the stacking type
    
    Y_label       <- "Percent"   # Setting the Y-label
    
  } else {
    
    chart_type    <- input_chart_type   # Setting the plot type 
    
    stacking_type <- "normal"           # Setting the stacking type
    
    Y_label       <-  unit              # Setting the Y-label
    
  }
  
  
  # Data processing
  data <- data %>%                          # Filtered data 
    
    # !!sym is used to call the group_var as a string
    group_by(!!sym(group_var), Period) %>%  # Group fill-by and period 
    
    summarise(Value   = sum(Value), 
              .groups = "drop") %>%         # Sum up period value 
    
    # This helps to sort chart by value
    arrange(desc(Value)) %>%                # Sorting value 
    
    mutate(Value = signif(Value,3)) %>%     # Apply 3 significant values
    
    ungroup() %>%                           # Remove grouping
    
    # Generate pivot table / Summary table 
    pivot_wider(
      
      names_from = {{group_var}},           
      
      values_from = Value,                  # The values to use 
      
      values_fn = sum,                      # Use the sum function 
      
      values_fill = 0                       # Setting zero if NULL
      
    ) %>%
    
    arrange(Period) %>%                     # Arrange the period
    
    as.data.frame()                         # Convert to data-frame
  
  
  # Extracting the grouped by value 
  measure_columns <- names(data)[-1]
  
  # Extracting the periods
  categories_column <- names(data)[1]
  
  
  # Generating the data-list for highchart series 
  data_list <- map(1:length(measure_columns), function(x) {
    
    list(data = data[, x + 1], 
         
         # Setting the series name
         name = names(data)[x + 1], 
         
         # Setting marker/symbol
         marker = 
           
           list(symbol =  schema_colors %>% 
                        
                        # Extracting the symbol from the color-schema    
                        filter(Fuel == names(data)[x + 1]) %>% 
                      
                        pull(Symbol)),
         
         # Setting the color hex code
         color = schema_colors %>% 
           
                     # Extracting the color from the color-schema 
                     filter(Fuel == names(data)[x + 1]) %>% 
                     
                     pull(Colors)
    )
  })


  
  # Highchart 
  hc <- highchart() %>%
    
    hc_chart(
             type = chart_type, # Setting the type of plot
             
             zoomType ='xy' ,  # Added a zoom option
             
             # Setting the style  
             style = list(
                          fontFamily = "Source Sans Pro", # Font type
                          
                          fontSize='15px'                 # Font size
                          
                          ) ) %>%
    
    # Adding the data series created
    # The color and marker are added in the data_list
    hc_add_series_list(data_list) %>%  
    
    # Turn off reversed legend
    hc_legend(reversed = FALSE) %>%
    
    # Add categories for the x-axis 
    hc_xAxis(categories = sort(unique(data$Period))) %>%
    
    # Adding the Y axis options
    hc_yAxis(
          title = list(text = Y_label),   # Adding Label text
          
          max = max_y,                    # Setting the y max value
          
          min = NULL,                        # Setting the y min value 
          
          # Keep values and remove and notations
          labels = list(format ='{value}'),
          
          # The keeps the stacked plot in a sorted order (Small values on top)
          reversedStacks = FALSE
          
    ) %>%

    
    # Adding the title (The subtitle was used instead of "title")
    hc_subtitle(text = paste0(plot_title, " (", Y_label , ")"),
                
                style = list(
                  
                  color = '#000000',       # Color 
                  
                  fontSize ='16px'         # Font size
                  
                  # fontWeight = 'bold'    # For bold font
                  
                )) %>% 
    

    # Adding credits
    hc_credits(
      
      text = credit_text,                 # The credit text
      
      # Changing the position of credit
      position = list(
              
              align= 'left',              # Keeping text left 
              
              x = 10                      # Padding in the x direction
            ),
      # href = "https://www.eeca.govt.nz/", # Reference the text
      
      enabled = TRUE                      # Show the credit
      
    ) %>%
    
    # Downloading data or image file
    hc_exporting(
      
      enabled = TRUE,                    # Allow download option
      
      filename = filename ,              # Setting the file name
      
      # Designing the download button
      buttons = list(
        
        contextButton = list(
          
          # Changing the position of download
          verticalAlign = 'bottom' ,     # Keeping the button at the bottom 
          
          y = -5,                        # Padding in the y direction
          
          menuItems = c("downloadPDF", "downloadCSV"), # List to download
          
          titleKey = "Click here to download",  # Key title
          
          text = "  Download  ",         # The text in the button
          
          # Setting the them for the download button 
          theme = list(
                       fill = '#f7f7f7',     # The fill color
                       
                       stroke = '#41B496',   # The bars around the text
                       
                       r = 7,                # Adding a curve around the button 
                       
                       states = list(hover=list(fill='#41B496'), # Hover color'
                                     
                       select = list(stroke='#41B496',
                                     fill ='#41B496')            # Select color
                       
                       )
                       ),
          symbol = ''                       # Use a null symbol
        )
      ),
      
      # Defining the selected download options
      menuItemDefinitions = list(
                          downloadPDF = list(text = "Download image"),
                                 
                          downloadCSV = list(text = "Download data"))
    ) %>% 

    # Adding theme 
    hc_add_theme(my_theme) 

  
  # Setting unique options for non-line chart
  if(chart_type != "line"){
    hc <- hc %>% 
      hc_plotOptions(
        series = list(
          
                stacking = as.character(stacking_type), # Stacking type
                
                animation = list(duration=1000),        # Animation duration
                
                # Turning off markers on area stack plot
                marker = list(enabled = FALSE),         # Turing off markers 
                
                lang = list(thousandsSep= ',')          # Setting thousand sep
                ))
  } else {
    
    # Adding options for line chart
    hc <- hc %>% 
      hc_plotOptions(
        series = list(animation = list(duration=2000),
                      # Setting the size of the markers
                      marker = list(radius= 2.5)#,
                      
                      # Adding label at the end of line
                      # Not needed now but uncomment to implement this if needed
                      
                      # dataLabels = list(
                      #   enabled= TRUE,
                      #   # crop= FALSE,
                      #   allowOverlap = TRUE,
                      #   # overflow= 'none',
                      #   align= 'left',
                      #   verticalAlign='middle',
                      #   # Showing the last data point
                      #   formatter= JS("function() {
                      #         // if last point
                      #     if(this.point === 
                      #         this.series.data[this.series.data.length-1]) 
                      #         {
                      #         return this.series.name;
                      #         }
                      #   }"))
                      
                      # This turns animation off (Uncomment to implement this)
                      # animation = FALSE,
        )) 

    
  }
  
  # Options for column percent chart
  if (input_chart_type == "column_percent") {
    
    hc <- hc %>%
      
      # Showing the percentage and value in the tooltip
      hc_tooltip(
        
        pointFormat = '<span style="color={series.color}">{series.name}</span>: <b>{point.y}</b> ({point.percentage:.0f}%)<br/>'
      
        ) 
    
  }
  
  
  # Options for column chart
  if (input_chart_type == "column") {
    
    hc <- hc %>%
      
      # Adding 
      hc_tooltip(
        
        # Adding total column value to tooltip
        footerFormat = 'Column total: <b>{point.total:,.4f} </b>'
        
      )
  }
  
  # This returns the plotting object
  return(hc)
  
}





# Plotting function assumption 
# This follows the same structure as the generic plotting function.

assumption_charts <- function(data,             # The filtered data 
                              group_var,        # The stacking (fill-by) variable
                              unit,             # Metric selected 
                              filename,         # Download name
                              plot_title,       # Plot title
                              input_chart_type, # Type of plot 
                              max_y             # Maximum y value
                          ) {
  
  if (input_chart_type == "column_percent") {
    
    chart_type <-"column"
    stacking_type <- "percent"
    Y_label <- "Percent"
    
  } else {
    
    chart_type <-input_chart_type
    stacking_type <- "normal"
    Y_label <-  unit
    
  }
  
  total_by_year <- data %>% 
    group_by(Period) %>% 
    summarise(Value = sum(Value)) %>% 
    ungroup() 
  
  data <- data %>% 
    group_by({{group_var}}, Period) %>%  
    summarise(Value = sum(Value), .groups = "drop") %>% 
    mutate(Value = signif(Value,3)) %>% 
    ungroup() %>% 
    pivot_wider(
      names_from = {{group_var}}, values_from = Value, 
      values_fn = sum, values_fill = 0
    ) %>%
    as.data.frame()
  
  measure_columns <- names(data)[-1]
  categories_column <- names(data)[1]
  
  
  
  data_list <- map(1:length(measure_columns), function(x) {
    
    list(data = data[, x + 1], 
         
         name = names(data)[x + 1], 
         
         marker = list(symbol=  schema_colors %>% 
                         filter(Fuel == names(data)[x + 1]) %>% 
                         pull(Symbol)),
         color = schema_colors %>% 
           filter(Fuel ==names(data)[x + 1]) %>% 
           pull(Colors)
    )
  })
  # data_list <- map(1:length(measure_columns), function(x) {
  #   list(data = data[, x + 1], name = names(data)[x + 1])
  # })
  
  # # Extracting the needed colors from the color scheme
  # cols <- schema_colors[order(schema_colors$Fuel),] %>%  
  #   filter(Fuel %in% measure_columns) %>% 
  #   select(Colors) %>% 
  #   as.data.frame()
  
  hc <- highchart() %>%
    hc_chart(type = chart_type,
             # Added a zoom button
             zoomType ='xy' ,
             # Font type
             style = list(fontFamily = "Source Sans Pro",
                          fontSize='15px') ) %>%
    hc_add_series_list(data_list) %>% 
    hc_legend(reversed = FALSE) %>% 
    hc_xAxis(categories = sort(unique(data$Period))) %>%
    hc_yAxis(title = list(text = Y_label), max = max_y, min = 0,
             # Keep values and remove and notations
             labels = list(format ='{value}')
    ) %>%
    hc_subtitle(text = paste0(plot_title, " (", Y_label , ")"),
                style= list(
                  color= '#000000',
                  fontSize='16px'
                   # fontWeight: 'bold'
                   )) %>% 
    # Adding colors to plot 
    # hc_colors(colors =  cols$Colors) %>% 
    # Adding credits
    hc_credits(
      text = "TIMES-NZ 2.0",
      # href = "https://www.eeca.govt.nz/",
      enabled = TRUE,
      # Changing the position of credit
      position = list(
        align= 'left',
        x= 10
      )
    ) %>%
    # Downloading data or image file
    hc_exporting(
      enabled = TRUE,
      filename = filename ,
      buttons = list(
        contextButton = list(
          # Changing the position of download
          verticalAlign = 'bottom' ,
          y = -5,
          menuItems = c("downloadPDF", "downloadCSV"),
          titleKey = "Click here to download",
          text = "  Download  ",
          theme = list(fill = '#f7f7f7', stroke = '#41B496',r = 7,
                       states = list(hover=list(fill='#41B496'), 
                                     select= list(stroke='#41B496',fill ='#41B496'))),
          symbol = ''
        )
      ),
      menuItemDefinitions = list(downloadPDF = list(text = "Download image"),
                                 downloadCSV = list(text = "Download data"))
    ) %>% 
    # # Adding a caption
    # hc_caption(
    #   text = caption_text, 
    #   useHTML = TRUE
    # ) %>% 
    # Adding theme 
    hc_add_theme(my_theme) 
  # %>% 
  #   # Set the tooltip to three decimal places
  #   hc_tooltip(valueDecimals=2) 
  
  if(chart_type != "line"){
    hc <- hc %>% 
      hc_plotOptions(
        series = list(stacking = as.character(stacking_type),
                      animation = list(duration=1000),
                      # Turning off markers on area stack plot
                      marker = list(enabled = FALSE),
                      lang = list(thousandsSep= ',')))
  } else {
    # Adding options for line chart
    hc <- hc %>% 
      hc_plotOptions(
        series = list(animation = list(duration=2000),
                      # Setting the size of the markers
                      marker = list(radius= 2.5)#,
                      # Adding label at the end of line
                      # dataLabels = list(
                      #   enabled= TRUE,
                      #   # crop= FALSE,
                      #   allowOverlap = TRUE,
                      #   # overflow= 'none',
                      #   align= 'left',
                      #   verticalAlign='middle',
                      #   # Showing the last data point
                      #   formatter= JS("function() {
                      #         // if last point
                      #     if(this.point === 
                      #         this.series.data[this.series.data.length-1]) 
                      #         {
                      #         return this.series.name;
                      #         }
                      #   }"))
                      # This turns animation off
                      # animation = FALSE,
        )) 

  }

  # Formatting percent values 
  
  # Checking if unit is not Percent or NA
  if (unit != "Percent" | is.na(unit) ){
    
    hc
    
  }else{
    # If unit is percent apply percent formatting
    hc <- hc %>%  hc_yAxis(labels = list(formatter= JS("function() {
                        var result = Highcharts.numberFormat(this.value*100, 0) + '%' + '</b>';
                        return result
                        }")))  %>%
      
      hc_tooltip(
        pointFormatter = JS("function() {
                            var string = this.series.name + ': ' +'<b>' + Highcharts.numberFormat(this.y*100, 2)  + ' %' + '</b>' + '<br>';
                            return string;
                         }"))
  }
    

  
  return(hc)
  
}


# Helper function to order attributes
order_attribute <- function(dat, order_str){
  dat %>% 
    factor(levels = order_str, ordered = TRUE) %>% 
    unique() %>% sort() %>%  as.character()
}




# Helper function to preprocess data for Y-label (min, max values)
get_range <- function(dat, group_var){
  dat %>% 
    group_by({{group_var}}, Period) %>%  
    summarise(Value = sum(Value), .groups = "drop") %>% 
    ungroup() %>% 
    pivot_wider(
      names_from = {{group_var}}, values_from = Value, 
      values_fn = sum, values_fill = 0
    ) %>%
    as.data.frame() %>% 
    range()
}

# Hover button
hover_popup <- function(text, icon_type = "fa-question-circle", font_size = "14px") {
  HTML(
    paste0(
      '<i class=\"fa ',
      icon_type,
      '\" data-container="body" ',
      'data-toggle="popover" ',
      'data-trigger="hover" ',
      'data-placement="bottom" ',
      'data-content=\"',
      text,
      '\" style=\"font-size: ',
      font_size,
      ';',
      ' vertical-align:super;
        position: absolute;
        right: 10px;\"',
      '></i>'
    )
  )
  
}



# Customised TRUE-FALSE switch button for Rshiny
# Only sing CSS3 code (No javascript)
#
# Adapted from Sébastien Rochette

#' A function to change the Original checkbox of rshiny
#' into a nice true/false or on/off switch button
#' No javascript involved. Only CSS code.
#' 
#' To be used with CSS script 'button.css' stored in a 'www' folder in your Shiny app folder
#' 
#' @param inputId The input slot that will be used to access the value.
#' @param label Display label for the control, or NULL for no label.
#' @param value Initial value (TRUE or FALSE).
#' @param col Color set of the switch button. Choose between "GB" (Grey-Blue) and "RG" (Red-Green)
#' @param type Text type of the button. Choose between "TF" (TRUE - FALSE), "OO" (ON - OFF) or leave empty for no text.

switchButton <- function(inputId, label, value=FALSE, col = "GB", type="TF") {
  
  # color class
  if (col != "RG" & col != "GB") {
    stop("Please choose a color between \"RG\" (Red-Green) 
      and \"GB\" (Grey-Blue).")
  }
  if (!type %in% c("OO", "TF", "YN")){
    warning("No known text type (\"OO\", \"TF\" or \"YN\") have been specified, 
     button will be empty of text") 
  }
  if(col == "RG"){colclass <- "RedGreen"}
  if(col == "GB"){colclass <- "GreyBlue"}
  if(type == "OO"){colclass <- paste(colclass,"OnOff")}
  if(type == "TF"){colclass <- paste(colclass,"TrueFalse")}
  if(type == "YN"){colclass <- paste(colclass,"YesNo")}
  
  # No javascript button - total CSS3
  # As there is no javascript, the "checked" value implies to
  # duplicate code for giving the possibility to choose default value
  
  if(value){
    tagList(
      tags$div(class = "form-group shiny-input-container",
               tags$div(class = colclass,
                        # tags$label(label, class = "control-label"),
                        tags$div(class = "onoffswitch",
                                 tags$input(type = "checkbox", name = "onoffswitch", class = "onoffswitch-checkbox",
                                            id = inputId, checked = ""
                                 ),
                                 tags$label(class = "onoffswitch-label", `for` = inputId,
                                            tags$span(class = "onoffswitch-inner"),
                                            tags$span(class = "onoffswitch-switch")
                                 )
                        )
               )
      )
    )
  } else {
    tagList(
      tags$div(class = "form-group shiny-input-container",
               tags$div(class = colclass,
                        # tags$label(label, class = "control-label"),
                        tags$div(class = "onoffswitch",
                                 tags$input(type = "checkbox", name = "onoffswitch", class = "onoffswitch-checkbox",
                                            id = inputId
                                 ),
                                 tags$label(class = "onoffswitch-label", `for` = inputId,
                                            tags$span(class = "onoffswitch-inner"),
                                            tags$span(class = "onoffswitch-switch")
                                 )
                        )
               )
      )
    ) 
  }
}






# This is a generic function for stacked area chart
# generic_stacking_charts <- function(data = NA,
#                               categories_column = NA,
#                               measure_columns = NA,
#                               chart_type = NA,
#                               stacking_type = NA,
#                               filename = NA) {
# 
#     chart <- highchart() %>%
#     hc_xAxis(categories = data[, categories_column],
#              title = categories_column)
#   
#   # This will create the needed series to add
#   # The invisible function around add_series suppresses the returned output
#   invisible(lapply(1:length(measure_columns), function(colNumber) {
#     chart <<-
#       hc_add_series(
#         hc = chart,
#         name = measure_columns[colNumber],
#         data = data[, measure_columns[colNumber]]
#       )
#   }))
#   
#   chart %>%
#     hc_chart(type = chart_type) %>%
#     hc_plotOptions(series = list(stacking = as.character(stacking_type))) %>%
#     hc_legend(reversed = TRUE) %>% 
#     # Downloading data or png file
#     hc_exporting(
#       enabled = TRUE,
#       filename = paste(filename, chart_type, "Chart", sep = " ") ,
#       buttons = list(
#         contextButton = list(
#           menuItems = c("downloadPDF", "downloadCSV"),
#           titleKey = "Click here to download",
#           text = "  Download  ",
#           theme = list(fill = '#ddd', stroke = '#888'),
#           symbol = ''
#         )
#       ),
#       menuItemDefinitions = list(downloadPDF = list(text = "Download image"))
#     )
#   
#     # Can add more plot options here
# }

# Towards line plot functionality

# line_plot_assumptions <- function(data = NA, 
#                       filen_title= NA,
#                       chart_type = NA){
#   
#   hchart(data,
#          type = chart_type, hcaes(x = Period, y= Value, group = Scenario)) %>% 
#     # Add more plot options
#     hc_title(text = filen_title) %>%
#     hc_xAxis(categories = unique(data$Period)) %>%
#     hc_yAxis(title = list(text = unique(data$Units))) %>%
#     hc_xAxis(title = "") %>% 
#     # hc_xAxis(title = filename) %>% 
#     # Downloading data or png file
#     hc_exporting(
#       enabled = TRUE,
#       filename = paste(filen_title, chart_type, "Chart", sep = " "),
#       buttons = list(
#         contextButton = list(
#           menuItems = c("downloadPDF", "downloadCSV"),
#           titleKey = "Click here to download",
#           text = "  Download  ",
#           theme = list(fill = '#ddd', stroke = '#888'),
#           symbol = ''
#         )
#       ),
#       menuItemDefinitions = list(downloadPDF = list(text = "Download image"))
#     )
#     # hc_exporting(enabled = TRUE, filename = paste(filen_title, chart_type, "Chart", sep = " "), 
#     #              buttons = list(contextButton = list(menuItems = c("downloadPDF", "downloadCSV" ))))
# }


# `<i class='fa fa-bar-chart'></i>`



# line_plot_overiew <- function(data = NA, 
#                                   filen_title= NA,
#                                   chart_type = NA){
#   
#   hchart(data,
#          type = chart_type, hcaes(x = Period, y= Value, group = Scenario)) %>% 
#     # Add more plot options
#     hc_title(text = filen_title) %>%
#     hc_xAxis(categories = unique(data$Period)) %>%
#     # hc_yAxis(title = list(text = unique(data$Units))) %>%
#     # hc_xAxis(title = filename) %>% 
#     # Downloading data or png file
#     hc_exporting(
#       enabled = TRUE,
#       filename = paste(filen_title, chart_type, "Chart", sep = " "),
#       buttons = list(contextButton = list(
#         menuItems = c("downloadPDF", "downloadCSV")
#       ),
#       menuItemDefinitions = list(downloadPDF = list(text = "Download image"))
#       )
#     )
#   
# }



# 
# 
# 
# generic_stacking_charts(
#   data = sample_data,
#   chart_type = "column",
#   categories_column = categories_column,
#   measure_columns = measure_columns,
#   stacking_type = "normal"
# )


# hc_yAxis(title = list(text = Y_label),
#          min = ymin,
#          max = ymax 
# ) %>%

# Add a generice line plot

# get_period_list <- function(data, group_var){
#   total_by_period <- data %>% 
#     group_by(Period, scen) %>%  
#     summarise(Value = sum(Value), .groups = "drop") %>% 
#     ungroup()
#   return(unique(total_by_period$Period))
# }

