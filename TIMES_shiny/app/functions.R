# These are the functions used

# Get max y from current filters
get_max_y <- function(data, group_var, input_chart_type){
  
  total_by_grp <- data %>% 
    group_by({{group_var}}, Period, scen) %>%  
    summarise(Value = sum(Value), .groups = "drop") %>% 
    ungroup()
  
  total_by_period <- data %>% 
    group_by(Period, scen) %>%  
    summarise(Value = sum(Value), .groups = "drop") %>% 
    ungroup()
  
  if(input_chart_type == "column_percent"){
    
    max_val <- 100
    
  } else if(input_chart_type %in% c("column", "area")) {
    
    max_val <- max(total_by_period$Value)
    
  } else {
    
    max_val <- max(total_by_grp$Value)
    
  }
  
  return(max_val)
  
}



get_max_y_assumptions <- function(data, group_var, input_chart_type){
  
  total <- data %>% 
    filter(Parameter == group_var) %>% 
    group_by(Period) %>% 
    summarise(Value = sum(Value)) %>% 
    ungroup()
  
  total_by_scenario <- data %>% 
    filter(Parameter == group_var)
  
  if(input_chart_type == "column_percent"){
    
    max_val <- 100
    
  } else if(input_chart_type %in% c("column", "area")) {
    
    max_val <- max(total$Value)
    
  } else {
    
    max_val <- max(total_by_scenario$Value)
    
  }
  
  return(max_val)
  
}




# Plotting theme to use
my_theme <-  hc_theme(
  chart = list(style = list(
    fontFamily = "Calibri Light",
    color= '#666666'
  )))


# Plotting function
generic_charts <- function(data, group_var, unit, filename, plot_title, input_chart_type, max_y) {
  
  if (input_chart_type == "column_percent") {
    
    chart_type <-"column"
    stacking_type <- "percent"
    Y_label <- "Percent"
    
  } else {
    
    chart_type <-input_chart_type
    stacking_type <- "normal"
    Y_label <-  unit
    
  }
  
  
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
    list(data = data[, x + 1], name = names(data)[x + 1])
  })
  
  # Extracting the needed colors from the color scheme
  cols <- schema_colors[order(schema_colors$Fuel),] %>%  
    filter(Fuel %in% measure_columns) %>% 
    select(Colors) %>% 
    as.data.frame()
  
  hc <- highchart() %>%
    hc_chart(type = chart_type,
             # Added a zoom buttom
             zoomType ='xy' ,
             # Font type
             style = list(fontFamily = "Calibri Light",
                          fontSize='15px') ) %>%
    hc_add_series_list(data_list) %>% 
    hc_legend(reversed = FALSE) %>% 
    hc_xAxis(categories = sort(unique(data$Period))) %>%
    hc_yAxis(title = list(text = Y_label), max = max_y, min = 0,
             # Keep values and remove and notations
             labels = list(format ='{value}')
    ) %>%
    hc_subtitle(text = paste0(plot_title, " (", Y_label , ")")) %>% 
    # Adding colors to plot 
    hc_colors(colors =  cols$Colors) %>% 
    # Adding credits
    hc_credits(
      text = "Chart created by EECA.",
      href = "https://www.eeca.govt.nz/",
      enabled = TRUE
    ) %>%
    # Downloading data or image file
    hc_exporting(
      enabled = TRUE,
      filename = filename ,
      buttons = list(
        contextButton = list(
          menuItems = c("downloadPDF", "downloadCSV"),
          titleKey = "Click here to download",
          text = 'Download',
          theme = list(fill = '#f7f7f7', stroke = '#41B496',
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
    
    hc <- hc %>% 
      hc_plotOptions(
        series = list(animation = list(duration=1000),
                      marker = list(radius= 3)
                      # This turns animation off
                      # animation = FALSE,
        ))    
    
  }
  
  if (input_chart_type == "column_percent") {
    hc <- hc %>%
      hc_tooltip(
        pointFormat = '<span style="color={series.color}">{series.name}</span>: <b>{point.y}</b> ({point.percentage:.0f}%)<br/>'#,
        # shared = TRUE
      ) 

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
#           text = 'Download',
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
#           text = 'Download',
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

