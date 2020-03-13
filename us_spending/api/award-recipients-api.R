library(tidyverse)
library(magrittr)
library(jsonlite)
library(httr)

# define functions --------------------------------------------------------

get_spending <- function(api = NULL, ...) {
  httr::GET(
    url = paste("https://api.usaspending.gov", api, sep = "/"),
    query = list(...)
  )
}

# award_spending/recipient
get_awards <- function(id, fy, pg = 0, ...) {
  # make initial requent
  r <- httr::GET(
    # Returns all award spending by recipient for a given fiscal year and agency
    url = "https://api.usaspending.gov/api/v2/award_spending/recipient/",
    query = list(fiscal_year = fy, awarding_agency_id = id, page = pg, ...)
  )
  if (httr::status_code(r) != 200) stop("Status code not 200")
  # convert response to json
  c <- content(r, as = "text", encoding = "UTF-8")
  if (is.na(c) | nchar(c) == 0) stop("No JSON text")
  # convert json to data frame
  jsonlite::fromJSON(c, flatten = TRUE)
}

from_awards <- function(list) {
  # re-define id and year
  id <- list$page_metadata$current %>%
    stringr::str_extract("(?<=awarding_agency_id\\=)\\d+")
  fy <- list$page_metadata$current %>%
    stringr::str_extract("(?<=fiscal_year\\=)\\d+")
  # shape data frame
  list %>%
    magrittr::use_series("results") %>%
    dplyr::rename_all(str_extract, "(?<=_)(.*)") %>%
    dplyr::mutate_all(parse_guess) %>%
    dplyr::mutate(agency = as.integer(id), year = as.integer(fy)) %>%
    dplyr::select(year, agency, recipient = name, category, amount) %>%
    tibble::as_tibble()
}

# scrape one agency/year --------------------------------------------------

years <- 1970:2020
all_dat <- rep(list(tibble()), length(years))
for (y in years) {
  # get page 0 initial
  awards <- get_awards(id = 183, fy = y)
  if (length(awards$results) == 0) {
    next()
  }
  dat <- from_awards(awards)
  i <- 1
  # if each page has next page, keep GETing
  while (awards$page_metadata$has_next_page) {
    # get next page
    awards <- get_awards(id = 183, fy = y, pg = i)
    # add to previous pages
    dat <- dplyr::bind_rows(dat, from_awards(awards))
    i <- i + 1
    message(sprintf("Loop %s of %s, %s rows collected", i, y, nrow(dat)))
  }
  all_dat[[match(y, years)]] <- dat
}

all_dat <- bind_rows(all_dat)

# check amount disttribution
ggplot2::quickplot(x = dat$amount, log = "x")
