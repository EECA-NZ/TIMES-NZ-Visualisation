
# Posistion the legend on the left side
hc %>%
  hc_legend(
    align = "left",
    verticalAlign = "top",
    layout = "vertical",
    x = 0, y = 100
    ) %>%

    # What user sees when hovers over a series or point. 
  hc_tooltip(
    crosshairs = TRUE,
    backgroundColor = "#F0F0F0",
    shared = TRUE, 
    borderWidth = 5
    )

library(highcharter)

data("citytemp")

hc <- highchart() %>% 
    hc_xAxis(categories = citytemp$month) %>% 
    hc_add_series(
        name = "Tokyo", data = citytemp$tokyo
        ) %>% 
    hc_add_series(
        name = "London", data = citytemp$london
        ) %>% 
    hc_add_series(
        name = "Other city",
        data = (citytemp$tokyo + citytemp$london)/2
        ) %>% 
    # Adding 3D effect
    hc_chart(
        type = "column",
        options3d = list(
        enabled = TRUE, 
        beta = -15,
        alpha = 5
        )
        ) %>%
    # Adding title
    hc_title(
        text = "This is the title of the chart"
        ) %>% 
    # Adding a caption
    hc_caption(
        text = "This is a long text to give some 
        subtle details of the data which can be relevant to the reader. 
        This is usually a long text that's why I'm trying to put a 
        <i>loooooong</i> text.", 
        useHTML = TRUE
        ) %>% 
    # Adding credits 
    hc_credits(
        text = "Chart created by EECA",
        href = "https://www.eeca.govt.nz/",
        enabled = TRUE
        ) %>%
    # What user sees when hovers over a series or point. 
    hc_tooltip(
        crosshairs = TRUE,
        backgroundColor = "#F0F0F0",
        shared = TRUE, 
        borderWidth = 5
        )
hc 


hc %>% 
    # Adding title
  hc_title(
    text = "This is the title of the chart"
    ) %>% 
    # Adding subtitle 
  hc_subtitle(
    text = "This is an intereseting subtitle to give
    context for the chart or some interesting fact"
    ) %>% 
    # Adding a caption
  hc_caption(
    text = "This is a long text to give some 
    subtle details of the data which can be relevant to the reader. 
    This is usually a long text that's why I'm trying to put a 
    <i>loooooong</i> text.", 
    useHTML = TRUE
    ) %>% 
    # Adding credits 
  hc_credits(
    text = "Chart created by EECA",
    href = "https://www.eeca.govt.nz/",
    enabled = TRUE
    )



# Fixing the colors in highchrter
df <- data.frame(name = c('John Doe','Peter Gynn','Jolie Hope'), y = c(21000, 23400, 26800), color = c('#f0f0f5','#00a1cd','#0058b8'))

highchart() %>%
  hc_chart(type = 'bar', polar = FALSE) %>%
  hc_xAxis(categories = df$name) %>% 
  hc_add_series(df)