library(tidyverse)
library(janitor)
library(rvest)
library(here)
library(httr)
library(cli)
library(fs)

cli_h1("Scrape Maryland Licenses")

raw_dir <- dir_create(here("state", "md", "licenses", "data", "raw"))

form_info <- function(html) {
  val <- html_attr(html_elements(html, "form input"), "value")
  names(val) <- html_attr(html_elements(html, "form input"), "name")
  as.list(val)
}

# -------------------------------------------------------------------------

get_home <- GET(
  url = "https://www.dllr.state.md.us",
  path = c("cgi-bin", "ElectronicLicensing", "OP_Search", "OP_search.cgi"),
  query = list(
    calling_app = "ALL::ALL_personal_name"
  )
)

home_cook <- cookies(get_home)

# -------------------------------------------------------------------------

l <- "A"
pg <- 0

cli_h2("{l}: Page {pg}")

raw_csv <- path(raw_dir, sprintf("md-licenses_%s.csv", l))

get_first <- POST(
  url = "https://www.dllr.state.md.us",
  path = c("cgi-bin", "ElectronicLicensing", "OP_Search", "OP_search.cgi"),
  body = list(
    calling_app = "ALL::ALL_personal_name",
    search_page = "ALL::ALL_personal_name",
    from_self = "true",
    unit = "",
    html_title = "LABOR+Boards+&+Commissions",
    error_contact = "Division+of+Occupational+and+Professional+Licensing",
    lastname = l,
    city = "",
    Submit = "Search"
  )
)

first_html <- content(get_first, as = "parsed", encoding = "UTF-8")

n_row <- first_html %>%
  html_element("h3") %>%
  html_text() %>%
  str_extract("\\d+") %>%
  parse_number()

cli_alert_info("Found {n_row} results")

first_df <- first_html %>%
  html_element("table") %>%
  html_table() %>%
  row_to_names(1)

write_csv(first_df, raw_csv)

# -------------------------------------------------------------------------

form_body <- form_info(first_html)
has_next <- TRUE

while (has_next) {
  Sys.sleep(runif(1, 2, 5))
  pg <- pg + 1
  cli_h2("{l}: Page {pg}")

  get_next <- POST(
    url = "https://www.dllr.state.md.us",
    path = c("cgi-bin", "ElectronicLicensing", "OP_Search", "OP_search.cgi"),
    body = form_body
  )

  next_html <- content(get_next, as = "parsed", encoding = "UTF-8")

  next_df <- next_html %>%
    html_element("table") %>%
    html_table() %>%
    row_to_names(1)

  write_csv(next_df, raw_csv, append = TRUE)
  form_body <- form_info(next_html)
  # form_body$results_index <- as.numeric(form_body$results_index) + 50
}
