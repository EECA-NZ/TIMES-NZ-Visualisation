# These are the functions used


# Plotting function

generic_charts <- function(data, group_var, unit, filename, input_chart_type) {
  
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
    hc_chart(type = chart_type) %>%
    hc_add_series_list(data_list) %>% 
    hc_legend(reversed = TRUE) %>% 
    hc_xAxis(categories = unique(data$Period)) %>%
    hc_yAxis(title = list(text = Y_label)) %>%
    hc_subtitle(text = filename) %>% 
    # Adding colors to plot 
    hc_colors(colors =  cols$Colors) %>% 
    # Downloading data or image file
    hc_exporting(
      enabled = TRUE,
      filename = filename ,
      buttons = list(
        contextButton = list(
          menuItems = c("downloadPDF", "downloadCSV"),
          titleKey = "Click here to download",
          text = 'Download',
          theme = list(fill = '#ddd', stroke = '#888'),
          symbol = ''
        )
      ),
      menuItemDefinitions = list(downloadPDF = list(text = "Download image"))
    ) %>% 
    # Set the tooltip to three decimal places
    hc_tooltip(valueDecimals=3)
  
  if(chart_type != "line"){
    hc <- hc %>% 
      hc_plotOptions(series = list(stacking = as.character(stacking_type)))
  }
  
  return(hc)
  
  # Can add more plot options here
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


# Add a generice line plot


