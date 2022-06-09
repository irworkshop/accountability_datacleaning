# Kiernan Nicholls
library(tidyverse)
library(janitor)
library(rvest)
library(httr)
library(cli)
library(fs)

find_attr <- function(html, name) {
  html_attr(html_element(html, sprintf("#__%s", name)), "value")
}

cli_list <- function(x) {
  cli::cli_ul()
  cli::cli_li(x)
  cli::cli_end()
}

cli_http <- function(x, msg) {
  y <- httr::http_status(x)
  if (httr::http_error(x)) {
    cli::cli_alert_danger(paste(msg))
  } else {
    cli::cli_alert_success(paste(msg))
  }
}

raw_dir <- dir_create(here("state", "nj", "licenses", "data", "raw"))

# open the home page ------------------------------------------------------

get_home <- GET(
  url = "https://newjersey.mylicense.com/verification/Search.aspx"
)

cli_http(get_home, "Search home page read")
cook <- cookies(get_home)
sesh_id <- set_names(cook$value, cook$name)

home_html <- content(get_home)
all_types <- home_html %>%
  html_elements("#t_web_lookup__profession_name option") %>%
  html_text()

# remove the "All" option
all_types <- all_types[-1]

i <- 2

# load the dropdown -------------------------------------------------------

post_type <- POST(
  url = "https://newjersey.mylicense.com/verification/Search.aspx",
  set_cookies(sesh_id),
  body = list(
    `__EVENTTARGET` = "t_web_lookup__profession_name",
    `__EVENTARGUMENT` = find_attr(home_html, "EVENTARGUMENT"),
    `__LASTFOCUS` = find_attr(home_html, "LASTFOCUS"),
    `__VIEWSTATE` = find_attr(home_html, "VIEWSTATE"),
    `__VIEWSTATEGENERATOR` = find_attr(home_html, "VIEWSTATEGENERATOR"),
    `__EVENTVALIDATION` = find_attr(home_html, "EVENTVALIDATION"),
    `t_web_lookup__profession_name` = all_types[i],
    `t_web_lookup__license_type_name` = "",
    `t_web_lookup__first_name` = "",
    `t_web_lookup__last_name` = "",
    `t_web_lookup__license_no` = "",
    `t_web_lookup__addr_city` = ""
  )
)

cli_http(post_type, "Licensee sub-types requested")
type_html <- content(post_type)
sub_types <- type_html %>%
  html_elements("#t_web_lookup__license_type_name option") %>%
  html_text()

cli_list(sub_types[-1])

# click search button -----------------------------------------------------

post_search <- POST(
  url = "https://newjersey.mylicense.com/verification/Search.aspx",
  set_cookies(sesh_id),
  body = list(
    `__EVENTTARGET` = find_attr(type_html, "EVENTTARGET"),
    `__EVENTARGUMENT` = find_attr(type_html, "EVENTARGUMENT"),
    `__LASTFOCUS` = find_attr(type_html, "LASTFOCUS"),
    `__VIEWSTATE` = find_attr(type_html, "VIEWSTATE"),
    `__VIEWSTATEGENERATOR` = find_attr(type_html, "VIEWSTATEGENERATOR"),
    `__EVENTVALIDATION` = find_attr(type_html, "EVENTVALIDATION"),
    `t_web_lookup__profession_name` = all_types[i],
    `t_web_lookup__license_type_name` = "",
    `t_web_lookup__first_name` = "",
    `t_web_lookup__last_name` = "",
    `t_web_lookup__license_no` = "",
    `t_web_lookup__addr_city` = "",
    `sch_button` = "Search"
  )
)

cli_http(post_search, "All licenses of type searched")
search_html <- content(post_search)

# load the results --------------------------------------------------------

get_results <- GET(
  url = "https://newjersey.mylicense.com/verification/SearchResults.aspx",
  set_cookies(sesh_id)
)

cli_http(get_results, "Search results returned")
results_html <- content(get_results)

result_head <- results_html %>%
  html_element("#datagrid_results") %>%
  html_table(na.strings = "")

result_head <- result_head %>%
  select(
    full_name = 2,
    license_number = 5,
    profession = 6,
    license_type = 7,
    license_status = 8,
    city = 9,
    state = 10
  ) %>%
  filter(!is.na(full_name)) %>%
  head(-1)

result_tsv <- path(raw_dir, sprintf("%s-0.csv", all_types[i]))

write_tsv(result_head, result_tsv)
cli_alert_success("Page 1 of results written to file")

grid_results <- results_html %>%
  html_elements("#datagrid_results tr") %>%
  last() %>%
  html_elements("a") %>%
  html_attr("href") %>%
  str_extract("(?<=')(.*)(?=',)")

cli_alert_info("Found {length(grid_results)} more pages of results")

for (j in seq_along(grid_results)) {
  post_next <- POST(
    url = "https://newjersey.mylicense.com/verification/SearchResults.aspx",
    set_cookies(sesh_id),
    body = list(
      `__EVENTTARGET` = grid_results[1],
      `__EVENTARGUMENT` = find_attr(results_html, "EVENTARGUMENT"),
      `__VIEWSTATE` = find_attr(results_html, "VIEWSTATE"),
      `__VIEWSTATEGENERATOR` = find_attr(results_html, "VIEWSTATEGENERATOR"),
      `__EVENTVALIDATION` = find_attr(results_html, "EVENTVALIDATION")
    )
  )
  next_html <- content(post_next)
  next_html %>%
    html_element("#datagrid_results")

  next_tsv <- path(raw_dir, sprintf("%s-%i.csv", all_types[i], j))
}
