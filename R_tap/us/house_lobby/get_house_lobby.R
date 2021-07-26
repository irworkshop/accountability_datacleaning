library(tidyverse)
library(jsonlite)
library(rvest)
library(httr)
library(cli)
library(fs)

# Hits: 692,206?

# SSL certificate problem: unable to get local issuer certificate
httr::set_config(config(ssl_verifypeer = FALSE))

# where to download files
lob_dir <- dir_create("~/Desktop/lob")

# get state filters -------------------------------------------------------

# request the search dropdown options
state_post <- POST(
  url = "https://clerkapi.house.gov/Elastic/search",
  encode = "json",
  body = list(
    applicationName = "disclosures.house.gov",
    index = "lobbying-disclosures",
    aggregations = list(
      list(
        name = "Filing Year",
        field = "reportYear",
        sort = "desc",
        filterable = FALSE,
        scrolling = FALSE,
        position = 1
      ),
      list(
        name = "Client's State/Province",
        field = "client.address.state",
        sort = "asc",
        filterable = TRUE,
        scrolling = TRUE,
        toggled = TRUE,
        position = 5
      )
    )
  )
)

# convert dropdown options to tables
state_body <- content(state_post)

# report years: 2000 to 2021
all_report_yr <- state_body$aggregations[[1]]$reportYear[[2]]$buckets
all_report_yr <- do.call("rbind", lapply(all_report_yr, as_tibble))

# client state: 50 + territory + Canada
all_client_st <- state_body$aggregations[[1]]$client.address.state[[2]]$buckets
all_client_st <- do.call("rbind", lapply(all_client_st, as_tibble))
nrow(all_client_st)

# download combos ---------------------------------------------------------

for (report_yr in sort(all_report_yr$key)) {
  Sys.sleep(runif(1, 1, 2))
  cli_h2("Report year: {report_yr}")
  for (client_st in sort(all_client_st$key)) {
    Sys.sleep(runif(1, 0, 1))
    # cli_h3("Client state: {client_st}")
    alt_st <- ifelse(nzchar(client_st), client_st, "NA")
    csv_name <- sprintf("house-lobby_%s_%s.csv", alt_st, report_yr)
    csv_path <- path(lob_dir, csv_name)
    down_post <- RETRY(
      verb = "POST",
      url = "https://clerkapi.house.gov/Elastic/download",
      user_agent("https://publicaccountability.org/"),
      write_disk(csv_path, overwrite = TRUE),
      encode = "json",
      body = list(
        index = "lobbying-disclosures",
        applicationName = "disclosures.house.gov",
        keyword = "",
        filters = list(
          reportYear = report_yr,
          client.address.state = client_st
        ),
        type = "CSV"
      )
    )
    if (!http_error(down_post)) {
      if (file_size(csv_path) > 0) {
        cli_alert_success("{alt_st}: Saved")
      } else {
        file_delete(csv_path)
        cli_alert_warning("{alt_st}: Empty")
      }
    } else {
      cli_alert_danger("{alt_st}: Failed")
    }
  }
}

# view files --------------------------------------------------------------

lob_csv <- dir_info(lob_dir)
x <- map(
  .x = lob_csv$path,
  .f = read_csv,
  col_types = cols(
    .default = col_character(),
    filingYear = col_integer(),
    amountReported = col_double(),
  )
)

z <- bind_rows(x)
