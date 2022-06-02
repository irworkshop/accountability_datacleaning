# Kiernan Nicholls
# Wed Jun  1 11:49:08 2022

library(tidyverse)
library(rvest)
library(httr)
library(fs)

get_home <- GET("https://madph.mylicense.com/verification/Search.aspx")
cook <- cookies(get_home)
sesh_id <- set_names(cook$value, cook$name)

home_html <- content(get_home)
all_types <- home_html %>%
  html_elements("#t_web_lookup__profession_name option") %>%
  html_text()

# remove the "All" option
all_types <- all_types[-1]

find_attr <- function(html, name) {
  html_attr(html_element(home, sprintf("#__%s", name)), "value")
}

i <- 2

post_search <- POST(
  url = "https://madph.mylicense.com/verification/Search.aspx",
  set_cookies(sesh_id),
  body = list(
    `__EVENTTARGET` = find_attr(home, "EVENTTARGET"),
    `__EVENTARGUMENT` = find_attr(home, "EVENTARGUMENT"),
    `__LASTFOCUS` = find_attr(home, "LASTFOCUS"),
    `__VIEWSTATEGENERATOR` = find_attr(home, "VIEWSTATEGENERATOR"),
    `__EVENTVALIDATION` = find_attr(home, "EVENTVALIDATION"),
    t_web_lookup__profession_name = "",
    t_web_lookup__license_type_name = all_types[i],
    t_web_lookup__first_name = "",
    t_web_lookup__last_name = "",
    t_web_lookup__license_no = "",
    t_web_lookup__license_status_name = "",
    t_web_lookup__addr_city = "",
    t_web_lookup__addr_state = "",
    t_web_lookup__addr_zipcode = "",
    sch_button = "Search"
  )
)

get_results <- GET(
  url = "https://madph.mylicense.com/verification/SearchResults.aspx",
  set_cookies(sesh_id)
)
results_html <- content(get_results)

result_head <- results_html %>%
  html_element("#datagrid_results") %>%
  html_table()

post_save <- POST(
  url = "https://madph.mylicense.com/verification/SearchResults.aspx",
  set_cookies(sesh_id),
  body = list(
    `__EVENTTARGET` = find_attr(results_html, "EVENTTARGET"),
    `__EVENTARGUMENT` = find_attr(results_html, "EVENTARGUMENT"),
    `__VIEWSTATE` = find_attr(results_html, "VIEWSTATE"),
    `__VIEWSTATEGENERATOR` = find_attr(results_html, "VIEWSTATEGENERATOR"),
    `__EVENTVALIDATION` = find_attr(results_html, "EVENTVALIDATION"),
    # click the download file button
    btnBulkDownLoad	= "Download+File"
  )
)

get_confirm <- GET(
  url = "https://madph.mylicense.com/verification/Confirmation.aspx",
  query = list(from_page = "SearchResults.aspx"),
  set_cookies(sesh_id)
)

get_login <- GET(
  url = "https://madph.mylicense.com/verification/Login.aspx",
  query = list(from_page = "Confirmation.aspx"),
  set_cookies(sesh_id)
)

get_verify <- GET(
  url = "https://madph.mylicense.com/verification/Confirmation.aspx",
  query = list(from_page = "Login.aspx"),
  set_cookies(sesh_id)
)
verify_html <- content(get_verify)

post_verify <- POST(
  url = "https://madph.mylicense.com/verification/Confirmation.aspx",
  query = list(from_page = "Login.aspx"),
  set_cookies(sesh_id),
  body = list(
    `__VIEWSTATE` = find_attr(verify_html, "VIEWSTATE"),
    `__VIEWSTATEGENERATOR` = find_attr(verify_html, "VIEWSTATEGENERATOR"),
    `__EVENTVALIDATION` = find_attr(verify_html, "EVENTVALIDATION"),
    # click the download file button
    btnBulkDownLoad	= "Continue"
  )
)

get_pref <- GET(
  url = "https://madph.mylicense.com/verification/PrefDetails.aspx",
  set_cookies(sesh_id)
)
pref_html <- content(get_pref)

post_down <- POST(
  url = "https://madph.mylicense.com/verification/PrefDetails.aspx",
  set_cookies(sesh_id),
  body = list(
    `__VIEWSTATE` = find_attr(pref_html, "VIEWSTATE"),
    `__VIEWSTATEGENERATOR` = find_attr(pref_html, "VIEWSTATEGENERATOR"),
    `__EVENTVALIDATION` = find_attr(pref_html, "EVENTVALIDATION"),
    # click the download file button
    filetype = "delimitedtext",
    sch_button = "Download"
  )
)

content(post_down, as = "text")
