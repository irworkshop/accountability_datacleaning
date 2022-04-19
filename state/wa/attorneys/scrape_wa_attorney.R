library(tidyverse)
library(rvest)
library(httr)
library(here)
library(fs)

ctl_css <- function(x) {
  paste0("#dnn_ctr2972_DNNWebControlContainer_ctl00_", x)
}

search_home <- read_html("https://www.mywsba.org/PersonifyEbusiness/Default.aspx?TabID=1536")
status_types <- search_home %>%
  html_element(ctl_css("ddlLicenseStatus")) %>%
  html_elements("option") %>%
  html_text()

status_types <- status_types[status_types != "Any"]

clean_dir <- dir_create(here("wa", "attorneys", "data", "clean"))
clean_csv <- path(clean_dir, "wa_attorneys.csv")

if (!file_exists(clean_csv)) {
  out <- rep(list(tibble()), length(status_types))
  for (i in seq_along(status_types)) {
    cli_h2(status_types[i])
    pg <- 0
    while(nrow(out[[i]]) == 0 || nrow(out[[i]]) < n_type) {
      a <- GET(
        url = "https://www.mywsba.org/PersonifyEbusiness/LegalDirectory.aspx",
        query = list(
          ShowSearchResults = TRUE,
          Status = status_types[i],
          Page = pg
        )
      )
      b <- content(a)
      if (pg == 0) {
        n_type <- b %>%
          html_element(".results-count") %>%
          html_text() %>%
          parse_number()
      }
      c <- b %>%
        html_element("table") %>%
        html_table() %>%
        head(20) %>%
        remove_empty("cols")
      out[[i]] <- bind_rows(out[[i]], c)
      message(sprintf("%i (%s)", pg, percent(nrow(out[[i]])/n_type, 0.001)))
      pg <- pg + 1
      Sys.sleep(runif(1, 0, 2))
    }
  }
  wal <- select(bind_rows(out) , -`...7`, -`...8`)
  wal <- clean_names(wal, "snake")
  write_csv(wal, clean_csv, na = "")
} else {
  wal <- read_csv(
    file = clean_csv,
    col_types = cols(
      .default = col_character()
    )
  )
}

wal %>%
  count(status, sort = TRUE) %>%
  add_prop()
