# Mon Mar  1 17:12:09 2021 ------------------------------------------------
# Request US spending between two dates
# Investigative Reporting Workshop
# Public Accountability Project
# Author: Kiernan Nicholls
# For problems:
#   kiernan@irworkshop.org
#   kiernann@protonmail.com


here::i_am("us/spending/us_spend_update.R")

# load packages -----------------------------------------------------------
library(tidyverse)
library(lubridate)
library(jsonlite)
library(gluedown)
library(janitor)
library(campfin)
library(aws.s3)
library(scales)
library(glue)
library(here)
library(httr)
library(fs)

# notes -------------------------------------------------------------------

# Prior to FY19, Financial Assistance awards (grants, direct payments, loans,
# insurance, and other financial assistance) only sporadically include Funding
# Agency data.

# Award Types: Contracts, Contract IDVs, Grants, Direct Payments, Loans,
#   Insurance, Other Financial Assistance, Sub-Contracts, Sub-Grants
# Agency: Awarding Agency, All
# Location: Recipient Location
# Date Type: Action Date
# File Format: TXT (Pipe Delimited)

# functions ---------------------------------------------------------------

spend_api <- function(endpoint) {
  modify_url(
    url = "https://api.usaspending.gov/",
    path = c("api", "v2", endpoint)
  )
}

# script args -------------------------------------------------------------

if (length(args) == 0) {

}

# prep data ---------------------------------------------------------------

# request all award types
award_types <- GET(spend_api("references/award_types"))
# convert to data frame
award_types <-
  content(award_types) %>%
  map_df(enframe) %>%
  unnest(cols = -name)

kable(award_types)

# make request ------------------------------------------------------------

award_post <- POST(
  url = spend_api("bulk_download/awards"),
  encode = "json",
  body = list(
    # pipe delimited
    file_format = "pstxt",
    filters = list(
      # all award types
      prime_award_types = award_types$name,
      sub_award_types = c("procurement", "grant"),
      date_type = "action_date",
      date_range = list(
        # change for last update
        start_date = "2020-10-01",
        end_date = as.character(Sys.Date())
      ),
      # all award agencies
      agencies = list(
        type = "awarding",
        tier = "toptier",
        name = "All"
      )
    )
  )
)

stop_for_status(award_post)
post_date <- award_post$date
award_post <- content(award_post)
award_post$file_name

# check status ------------------------------------------------------------

# All_PrimeTransactionsAndSubawards_2021-03-01_H21M36S10731192.zip

while (!exists("post_status") || post_status == "running") {
  message(sprintf("status: requested (%s)", post_date))
  # request status
  status_get <-GET(
    url = spend_api("bulk_download/status/"),
    query = list(
      file_name = award_post$file_name
    )
  )
  status_get <- content(status_get)
  post_status <- status_get$status
  if (post_status == "running") {
    message(sprintf("status: %s (%s)", post_status, Sys.time()))
    # wait 5 minutes and check again
    Sys.sleep(5 * 60)
  } else {
    message(sprintf("status: %s (%s)", post_status, Sys.time()))
  }
}
# download bulk zip when ready --------------------------------------------

# check file size before download
fs_bytes(paste(status_get$total_size, "KiB"))

# download to a temp file
raw_zip <- file_temp(ext = "zip")
bulk_save <- GET(
  url = award_post$file_url,
  write_disk(path = raw_zip),
  progress(type = "down")
)

# read file ---------------------------------------------------------------

# list the zip contents
unzip(raw_zip, list = TRUE) %>%
  as_tibble() %>%
  transmute(
    path = fs_path(Name),
    size = fs_bytes(Length),
    date = Date
  )

# extract files
raw_tsv <- unzip(raw_zip, exdir = dirname(raw_zip))

# read col types
spend_cols <- read_csv(
  file = "us/spending/update/usa_spend_cols.csv",
  col_types = cols(
    column = col_character(),
    type = col_character()
  )
)

# as.col_spec(deframe(spend_cols))
spend_cols <- str_c(spend_cols$type, collapse = "")

# read data frame
spending <- read_delim(
  file = raw_txt[5],
  delim = "|",
  guess_max = 0,
  col_types =
)

# check rows and year
unique(spending$action_date_fiscal_year)
nrow(spending) == status_get$total_rows
