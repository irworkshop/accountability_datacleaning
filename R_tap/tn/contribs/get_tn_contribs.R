library(tidyverse)
library(rvest)
library(httr)
library(cli)
library(fs)

tn_dir <- "~/Desktop/tn"

for (y in 2000:2021) {
  cli_h2("Year: {y}")
  # request data ------------------------------------------------------------

  # visit home page for session ID cookies
  search_home <- GET("https://apps.tn.gov/tncamp-app/public/cesearch.htm")

  sesh_id <- cookies(search_home)
  sesh_id <- setNames(sesh_id$value, sesh_id$name)

  # submit POST request for all FROM for year Y
  search_post <- POST(
    url = "https://apps.tn.gov/tncamp-app/public/cesearch.htm",
    set_cookies(sesh_id),
    body = list(
      searchType = "contributions",
      toType = "both", # to both candidates and committees
      fromCandidate = TRUE, # from all types
      fromPAC = TRUE,
      fromIndividual = TRUE,
      fromOrganization = TRUE,
      electionYearSelection = "",
      yearSelection = y, # for given year
      recipientName = "", # no name filters
      contributorName = "",
      employer = "",
      occupation = "",
      zipCode = "",
      candName = "",
      vendorName = "",
      vendorZipCode = "",
      purpose = "",
      typeOf = "all",
      amountSelection = "equal",
      amountDollars = "",
      amountCents = "",
      typeField = TRUE, # add all available fields
      adjustmentField = TRUE,
      amountField = TRUE,
      dateField = TRUE,
      electionYearField = TRUE,
      reportNameField = TRUE,
      recipientNameField = TRUE,
      contributorNameField = TRUE,
      contributorAddressField = TRUE,
      contributorOccupationField = TRUE,
      contributorEmployerField = TRUE,
      descriptionField = TRUE,
      `_continue` = "Continue",
      `_continue` = "Search"
    )
  )


  # read search results -----------------------------------------------------
  search_get <- GET(
    url = "https://apps.tn.gov/tncamp-app/public/ceresults.htm",
    set_cookies(sesh_id)
  )

  search_list <- content(search_get)

  # find csv export link at bottom of page
  csv_link <- search_list %>%
    html_element(".exportlinks > a") %>%
    html_attr("href")

  csv_link <- str_c("https://apps.tn.gov", csv_link)

  # set initial loop numbers
  more_loop <- 1
  n_all <- 0

  # find initial number of results
  n_row <- parse_number(html_text(html_element(search_list, ".pagebanner")))
  n_all <- n_all + n_row
  cli_h3("First results: {n_row} results")

  # define first file name
  csv_path <- path(tn_dir, sprintf("tn_contrib_%i-%i.csv", y, more_loop))

  # download the first list of results as CSV
  csv_get <- GET(csv_link, write_disk(csv_path), progress("down"))

  # check for the "More" button
  has_more <- !is.na(html_element(search_list, ".btn-blue"))

  while (has_more) {
    Sys.sleep(runif(1, 1, 3))
    cli_alert_warning("More records available")
    more_loop <- more_loop + 1 # increment loop number
    more_get <- GET( # follow the more button link
      url = "https://apps.tn.gov/tncamp-app/public/ceresultsnext.htm",
      set_cookies(sesh_id)
    )
    more_list <- content(more_get)

    # find number of more results found
    n_row <- parse_number(html_text(html_element(more_list, ".pagebanner")))
    n_all <- n_all + n_row
    cli_h3("More results page {more_loop}: {n_row} results")

    # create new path and save CSV file
    csv_path <- path(tn_dir, sprintf("tn_contrib_%i-%i.csv", y, more_loop))
    csv_get <- GET(csv_link, write_disk(csv_path), progress("down"))

    # check for more button
    has_more <- !is.na(html_element(more_list, ".btn-blue"))
  }
  # finish when button disappears
  cli_alert_success("No more results this year")

  Sys.sleep(runif(1, 10, 30))
}
