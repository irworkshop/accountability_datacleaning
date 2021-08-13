library(tidyverse)
library(janitor)
library(campfin)
library(rvest)
library(httr)
library(cli)
library(fs)

tn_dir <- "~/Desktop/tn_contribs/"

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

tn_csv <- dir_ls(tn_dir, glob = "*.csv")

# read together -----------------------------------------------------------

tnc <- map_df(
  .x = tn_csv,
  .f = function(x) {
    with_edition(
      edition = 1,
      code = read_delim(
        file = x,
        delim = ",",
        escape_backslash = TRUE,
        escape_double = FALSE,
        col_types = cols(
          .default = col_character(),
          `Amount` = col_number(),
          `Date` = col_date("%m/%d/%Y"),
          `Election Year` = col_integer()
        )
      )
    )
  }
)

tnc <- clean_names(tnc, case = "snake")
n_distinct(tnc$type) == 2

# split address -----------------------------------------------------------

x3 <- tnc %>%
  distinct(contributor_address) %>%
  separate(
    col = contributor_address,
    into = c("addr_city", "state_zip"),
    sep = "\\s,\\s(?=[^,]*,[^,]*$)",
    remove = FALSE,
    extra = "merge",
    fill = "left"
  ) %>%
  separate(
    col = state_zip,
    into = c("state", "zip"),
    sep = ",\\s(?=\\d)",
    extra = "merge",
    fill = "left"
  )

good_split <- filter(x3, state %in% valid_abb)
bad_split <- filter(x3, state %out% valid_abb)

# fix split ---------------------------------------------------------------


# mising something in the middle, move and re-split
no_zip <- bad_split %>%
  filter(is.na(state) & is.na(addr_city) & str_detect(zip, "\\s\\w{2}$")) %>%
  select(-addr_city, -state) %>%
  separate(
    col = zip,
    into = c("addr_city", "state"),
    sep = "\\s?,\\s?(?=[^,]*$)",
    extra = "merge",
    fill = "right"
  )

# remove fixed from bad
bad_split <- bad_split %>%
  filter(contributor_address %out% no_zip$contributor_address)

# no zip, city-state moved to end, split-merge city into addr
no_zip <- bad_split %>%
  filter(!is.na(addr_city) & is.na(state) & str_detect(zip, "\\s\\w{2}$")) %>%
  separate(
    col = zip,
    into = c("city", "state"),
    sep = "\\s+,\\s"
  ) %>%
  unite(
    col = addr_city,
    ends_with("city"),
    sep = ", "
  ) %>%
  bind_rows(no_zip)

bad_split <- bad_split %>%
  filter(contributor_address %out% no_zip$contributor_address)

# no state, addr moved to state, move to addr and remove state
no_state <- bad_split %>%
  filter(is.na(addr_city) & !is.na(state) & str_detect(zip, "^\\d{5,}")) %>%
  select(-addr_city) %>%
  rename(addr_city = state)

bad_split <- bad_split %>%
  filter(contributor_address %out% no_state$contributor_address)

# combine everything and extract states
full_bad <- bad_split %>%
  filter(is.na(state) | nchar(state) != 2) %>%
  unite(
    -contributor_address,
    col = addr_city,
    sep = ", ",
    na.rm = TRUE
  ) %>%
  mutate(
    state = str_extract(addr_city, "^[A-Z]{2}$"),
    addr_city = na_if(str_remove(addr_city, "^[A-Z]{2}$"), "")
  )

bad_split <- bad_split %>%
  filter(contributor_address %out% full_bad$contributor_address)

# remaining just have bad states in general
bad_split %>%
  count(state, sort = TRUE)

# recombine fixes and fill with empty cols
bad_fix <- bind_rows(no_zip, no_state, full_bad, bad_split)
bad_fix <- mutate(bad_fix, across(.fns = str_squish))

sample_n(bad_fix, 20)

# recombine with good splits
tn_addr <- bind_rows(good_split, bad_fix)

write_tsv(tn_addr, file = "~/Desktop/tn_addr.tsv")
