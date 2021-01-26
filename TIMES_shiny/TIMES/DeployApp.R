library(rsconnect)

deployApp(appFiles = c("deployApp.R", "global.R", "server.R", "ui.R", "data\\data_for_shiny.rda"),
          account = "times-nz-model-eeca",
          forceUpdate = TRUE)

