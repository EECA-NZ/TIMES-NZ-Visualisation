api_key <- Sys.getenv("Pendo_API_key_EECA")

if (api_key == "") {
  stop("Pendo_API_key_EECA environment variable not set!")
}

# Read template
js_template <- readLines("www/js/pendo-analytics-template.js")

# Replace placeholder
js_ready <- gsub("__PENDO_API_KEY__", api_key, js_template, fixed = TRUE)

# Write actual file
writeLines(js_ready, "www/js/pendo-analytics.js")