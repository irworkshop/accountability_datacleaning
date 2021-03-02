# Tue Mar  2 14:49:34 2021 ------------------------------
# Request US spending between two dates
# Investigative Reporting Workshop
# Public Accountability Project
# Author: Kiernan Nicholls
#   kiernan@irworkshop.org
#   kiernann@protonmail.com

#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
here::i_am("us/spending/us_spend_update.R")

# load packages -----------------------------------------------------------

library(tidyverse)
library(lubridate)
library(janitor)
library(campfin)
library(aws.s3)
library(glue)
library(here)
library(httr)
library(fs)

# notes -------------------------------------------------------------------

# Award Types: All
# Agency: Awarding Agency, All
# Location: Recipient Location
# Date Type: Action Date
# File Format: TSV (Tab Delimited)

# functions ---------------------------------------------------------------

spend_api <- function(endpoint, ...) {
  httr::modify_url(
    url = "https://api.usaspending.gov/",
    path = c("api", "v2", endpoint),
    ...
  )
}

# script args -------------------------------------------------------------

# call script from command line with (1) start and (2) end dates
# Rscript --vanilla us_spend_update.R --args 2020-01-01 2020-12-31

if (length(args) == 0) {
  ### !!!!!!!!!!!!!!!!!!
  # define dates here w/out args
  # end_date <- "2020-10-01"
  # start_date <- "2021-09-30"
  end_date <- Sys.Date()
  start_date <- end_date - 7
  ### !!!!!!!!!!!!!!!!!!
} else if (length(args) == 2){
  end_date <- as.Date(args[2], tryFormats = c("%Y-%m-%d", "%m/%d/%Y"))
  start_date <- as.Date(args[1], tryFormats = c("%Y-%m-%d", "%m/%d/%Y"))
} else {
  stop("when using args, use both start date then end date", call. = FALSE)
}

# prep data ---------------------------------------------------------------

# request all award types
award_types <- GET(spend_api("references/award_types"))
# convert to data frame
award_types <-
  content(award_types) %>%
  map_df(enframe, value = "award_type") %>%
  unnest(cols = award_type) %>%
  mutate(across(award_type, str_to_upper))

# make request ============================================================

message(sprintf("requesting spending between %s and %s", start_date, end_date))

award_post <- POST(
  url = spend_api("bulk_download/awards/"),
  encode = "json",
  body = list(
    columns = list(),
    file_format = "tsv",
    filters = list(
      prime_award_types = award_types$name,
      sub_award_types = c("procurement", "grant"),
      date_type = "action_date",
      date_range = list(
        start_date = start_date,
        end_date = end_date
      ),
      agencies = list(
        list(
          type = "awarding",
          tier = "toptier",
          name = "All"
        )
      )
    )
  )
)

stop_for_status(award_post)
post_date <- award_post$date
award_post <- content(award_post)
raw_file <- award_post$file_name

message(sprintf("status: requested (%s)", post_date))

# check status ------------------------------------------------------------

# All_PrimeTransactionsAndSubawards_2021-03-01_H21M36S10731192.zip

while (!exists("post_status") || post_status == "running") {
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
    message(glue("status: {post_status} ({Sys.time()}), waiting 5 min"))
    # wait 5 minutes and check again
    Sys.sleep(time = 5 * 60)
  } else {
    message(sprintf("status: {post_status} ({Sys.time()})"))
  }
}

# download bulk zip when ready --------------------------------------------

# check size before download
# kilobytes to total bytes
bulk_length <- status_get$total_size * 1000

# calculate download time
if (isTRUE(requireNamespace("speedtest", quietly = TRUE))) {
  speed <- speedtest::speedtest_cli(progress = FALSE)
  dl <- speed$result[[7]]$download$bytes
  dseconds(round(bulk_length / dl, 3))
}

raw_dir <- dir_create(here("us", "spending", "update", "data"))
raw_zip <- path(raw_dir, raw_file)
message(glue("downloading bulk file: {raw_file} ({fs_bytes(bulk_length)})"))

# download locally
if (!file_exists(raw_zip)) {
  bulk_save <- GET(
    url = award_post$file_url,
    write_disk(path = raw_zip),
    progress(type = "down")
  )
}

# extract files -----------------------------------------------------------

message(glue("extracting zip archive to: {raw_dir}"))

# list the zip contents
unzip(raw_zip, list = TRUE) %>%
  as_tibble() %>%
  transmute(
    path = fs_path(Name),
    size = fs_bytes(Length),
    date = Date
  )

# extract files
all_tsv <- unzip(raw_zip, exdir = raw_dir)

# contracts ===============================================================

# list the contract files from zip
con_tsv <- str_subset(all_tsv, "All_Contracts")
con_n <- length(con_tsv)

col_file <- here("us", "spending", "update", "con_cols.csv")
if (file_exists(col_file)) {
  # read col types
  con_cols <- read_csv(col_file, col_types = cols())
  con_cols <- str_c(con_cols$type, collapse = "")
  ## as.col_spec(deframe(spend_cols))
} else {
  con_cols <- NULL
}

for (i in seq_along(con_tsv)) {
  # read contract ---------------------------------------------------------
  message(glue("reading contract file {i}/{con_n}"))

  # read data frame
  usc <- read_delim(
    file = con_tsv[i],
    delim = "\t",
    guess_max = 0,
    col_types = con_cols
  )

  # tweak cols ------------------------------------------------------------

  # flag missing values
  usc <- flag_na(
    data = usc,
    action_date, # date
    federal_action_obligation, # amount
    awarding_sub_agency_name, # agency
    recipient_name # company
  )

  # trim zip codes to 5 digits
  usc <- mutate(usc, zip_clean = str_sub(recipient_zip_4_code, end = 5))

  # add calendar year from action date
  usc <- mutate(usc, action_year = year(action_date))

  # save checks -----------------------------------------------------------
  message(glue("checking contract file {i}/{con_n}"))

  check <- tibble(
    file = basename(con_tsv[i]),
    start_date = min(usc$action_date, na.rm = TRUE),
    end_date = max(usc$action_date, na.rm = TRUE),
    nrow = nrow(usc),
    ncol = ncol(usc),
    n_types = n_distinct(usc$award_type_code),
    fiscal_year = unique(usc$action_date_fiscal_year)[1],
    sum_amt = sum(usc$federal_action_obligation, na.rm = TRUE),
    na_flags = sum(usc$na_flag, na.rm = TRUE),
    zero_amt = sum(usc$federal_action_obligation <= 0, na.rm = TRUE),
    city_good = round(prop_in(usc$recipient_city_name, valid_city), 4),
    state_good = round(prop_in(usc$recipient_state_code, valid_state), 4),
    zip_good = round(prop_in(usc$zip_clean, valid_zip), 4)
  )

  # save contract ---------------------------------------------------------
  con_out <- glue("us_contract_{start_date}-{end_date}-{i}.csv")
  message(glue("writing contract file {i}/{con_n} to: {con_out}"))

  write_delim(
    x = usc,
    file = ,
    delim = ",",
    na = "",
    quote_escape = "double",
  )
  rm(usc)
  Sys.sleep(time = 10)
  flush_memory(n = 2)

}

# assistance ==============================================================

# upload ==================================================================
