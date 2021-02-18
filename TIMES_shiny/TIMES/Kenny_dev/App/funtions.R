# These are the functions used


# Plotting function
# This is a generic function for stacked area chart
generic_stacking_charts <- function(data = NA,
                              categories_column = NA,
                              measure_columns = NA,
                              chart_type = NA,
                              stacking_type = NA) {

    chart <- highchart() %>%
    hc_xAxis(categories = data[, categories_column],
             title = categories_column)
  
  # This will create the needed series to add
  # The invisible function around add_series suppresses the returned output
  invisible(lapply(1:length(measure_columns), function(colNumber) {
    chart <<-
      hc_add_series(
        hc = chart,
        name = measure_columns[colNumber],
        data = data[, measure_columns[colNumber]]
      )
  }))
  
  chart %>%
    hc_chart(type = chart_type) %>%
    hc_plotOptions(series = list(stacking = as.character(stacking_type))) %>%
    hc_legend(reversed = TRUE)
    # Can add more plot options here
}
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


