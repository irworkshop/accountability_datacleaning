#!/usr/bin/env Rscript

# Fri Mar  5 10:27:44 2021 ------------------------------
# Request US spending between two dates
# Investigative Reporting Workshop
# The Accountability Project
# Author: Kiernan Nicholls
#   * kiernan@workshop.org
#   * kiernann@protonmail.com

# load packages -----------------------------------------------------------

suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(campfin))
suppressPackageStartupMessages(library(aws.s3))
suppressPackageStartupMessages(library(httr))
suppressPackageStartupMessages(library(cli))
suppressPackageStartupMessages(library(fs))

cli_h1("Update Federal Spending")

cmd_args <- commandArgs(trailingOnly = TRUE)
suppressMessages(here::i_am("us/spending/us_spend_update.R"))

cli_h2("Preparing request")

# notes -------------------------------------------------------------------

# Award Types: All
# Agency: Awarding Agency, All
# Location: Recipient Location
# Date Type: Action Date
# File Format: TSV (Tab Delimited)

# functions ---------------------------------------------------------------

# with time cli
wt <- function(...) {
  paste(..., cli::col_silver(Sys.time()))
}

# script args -------------------------------------------------------------

# call script from command line with (1) start and (2) end dates
# Rscript --vanilla us_spend_update.R --args 2020-01-01 2020-12-31

if (length(cmd_args) == 2) {
  cli_alert_info("Using date arguments from arguments")
  # capture cmd line args as dates
  end_date   <- as.Date(cmd_args[2], tryFormats = c("%Y-%m-%d", "%m/%d/%Y"))
  start_date <- as.Date(cmd_args[1], tryFormats = c("%Y-%m-%d", "%m/%d/%Y"))
  if (end_date < start_date) {
    cli_alert_danger("End date is before start date")
    stop("When using args, supply (1) start date and (2) end date")
  }
} else if (length(cmd_args) == 0){
  ### !!! define dates here
  end_date <- Sys.Date() - 1
  start_date <- end_date - 7
  ### !!!
} else {
  stop("When using args, supply (1) start date and (2) end date")
}

# prep data ---------------------------------------------------------------

# request all award types
award_types <- GET("https://api.usaspending.gov/api/v2/references/award_types")
# convert to data frame
award_types <-
  content(award_types) %>%
  map_df(enframe, value = "award_type") %>%
  unnest(cols = award_type) %>%
  mutate(across(award_type, str_to_upper))

cli_alert_success(wt("Found {.strong {nrow(award_types)}} award types"))

# make request ============================================================
cli_h2("Request bulk zip")

cli_alert("Making request from {.url https://api.usaspending.gov/}")

award_post <- POST(
  url = "https://api.usaspending.gov/api/v2/bulk_download/awards/",
  # send post body as json
  encode = "json",
  body = list(
    columns = list(),
    file_format = "tsv",
    filters = list(
      prime_award_types = award_types$name,
      sub_award_types = c(), # "procurement", "grant"
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

# stop if the POST failed
post_check <- http_status(award_post)
if (http_error(award_post)) {
  cli_alert_danger(wt(post_check$message))
  stop_for_status(award_post)
} else {
  cli_alert_success(wt(post_check$message))
}

post_data <- content(award_post)

# check status ------------------------------------------------------------
cli_h2("Check file status")

# All_PrimeTransactions_2021-03-02_H16M49S35586986.zip

cli_alert("Wait for file to be ready for download")
while (!exists("post_status") || post_status == "running") {
  # request status
  status_get <- content(GET(
    url = "https://api.usaspending.gov/api/v2/bulk_download/status/",
    query = list(file_name = post_data$file_name)
  ))
  post_status <- status_get$status
  if (post_status == "running") {
    n <- 300 # adjust wait in seconds
    m <- round(n/60, digits = 1)
    cli_alert_info(wt("Status: {col_cyan(post_status)}, waiting {m} min"))
    Sys.sleep(time = n)
  } else if (post_status == "failed") {
    cli_alert_danger(wt("Status: {col_red(post_status)}"))
    stop("Download failed")
  } else {
    cli_alert_success(wt("Status: {col_green(post_status)}"))
  }
}
# download bulk zip when ready --------------------------------------------
cli_h2("Download bulk file")

data_dir <- dir_create(here("us", "spending", "data"))
raw_zip <- path(data_dir, post_data$file_name)

bulk_size <- fs_bytes(status_get$total_size * 1000)
cli_alert(wt("Starting download {.emph ({bulk_size})}"))
cli_text("{.url {ansi_strtrim(post_data$file_url)}}")

# download locally
if (file_exists(raw_zip)) {
  cli_alert_warning("File already exists on disk")
} else {
  bulk_save <- GET(
    url = post_data$file_url,
    write_disk(path = raw_zip),
    progress(type = "down")
  )
  cli_alert_success(wt("Download complete {.emph ({file_size(raw_zip)})}"))
}

cli_text("{.file {ansi_strtrim(raw_zip)}}")

# extract files -----------------------------------------------------------
cli_h2("Extract text files")

# list the zip contents
zip_list <-
  unzip(raw_zip, list = TRUE) %>%
  transmute(
    path = fs_path(Name),
    size = fs_bytes(Length),
    date = Date
  )

cli_alert_info("Bulk zip contains {nrow(zip_list)} text files:")
cli_ol()
cli_li(paste(zip_list$path, col_grey(zip_list$size)))
cli_end()

cli_process_start("Extracting all files")
all_tsv <- unzip(raw_zip, exdir = data_dir, overwrite = FALSE)
cli_process_done(msg_done = wt("Extracting all files... done"))
n_tsv <- length(all_tsv)

quit() # go no futher!

check_file <- here("us", "spending", "update_check.csv")

# read and check ----------------------------------------------------------

cli_h2("Checking {n_tsv} text file{?s}")

con_col_file <- here("us", "spending", "con_cols.csv")
ass_col_file <- here("us", "spending", "ass_cols.csv")
if (file_exists(con_col_file) && file_exists(ass_col_file)) {
  # read col types
  con_cols <- read_csv(con_col_file, col_types = cols())
  con_cols <- str_c(con_cols$type, collapse = "")
  ## as.col_spec(deframe(con_cols))
  ass_cols <- read_csv(ass_col_file, col_types = cols())
  ass_cols <- str_c(ass_cols$type, collapse = "")
} else {
  con_cols <- NULL
  ass_cols <- NULL
}

cli_alert("Looping through each file")
for (i in seq_along(all_tsv)) {
  # read contract ---------------------------------------------------------
  cli_h3("Reading contract file {i}/{n_con}")
  file_type <- str_detect(all_tsv[i], "All_Contracts") %>%
    if_else("contract", "assist")

  # read data frame
  us <- read_delim(
    file = all_tsv[i],
    delim = "\t",
    guess_max = 0,
    col_types = con_cols,
    progress = TRUE
  )

  # tweak cols ------------------------------------------------------------
  cli_alert("Manipulating new columns")


  # flag missing values
  sub_data <- us %>%
    select(
      action_date, # date
      federal_action_obligation, # amount
      awarding_sub_agency_name, # agency
      recipient_name # company
    )
  us$na_flag <- !complete.cases(sub_data)
  rm(sub_data)
  invisible(gc(reset = TRUE, full = TRUE))
  cli_alert_success("Missing values flagged in {.code na_flag} column")

  # trim zip codes to 5 digits
  us <- mutate(us, zip_clean = str_sub(recipient_zip_4_code, end = 5))
  cli_alert_success("Trimmed ZIP codes added in {.code zip_clean} column")

  # add calendar year from action date
  us <- mutate(us, action_year = year(action_date))
  cli_alert_success("Calendar year added in {.code action_year} column")

  # save checks -----------------------------------------------------------
  cli_alert("Checking data frame structure")

  check <- tibble(
    file = basename(con_tsv[i]),
    type = "contract",
    start_date = start_date,
    end_date = end_date,
    min_date = min(us$action_date, na.rm = TRUE),
    max_date = max(us$action_date, na.rm = TRUE),
    n_row = nrow(us),
    n_col = ncol(us),
    sum_amt = sum(us$federal_action_obligation, na.rm = TRUE),
    na_flags = sum(us$na_flag, na.rm = TRUE),
    zero_amt = sum(us$federal_action_obligation <= 0, na.rm = TRUE)
  )

  write_csv(check, check_file, append = file_exists(check_file))
  cli_alert_success("Checks saved as row in {.path update_check.csv}")

  # save contract ---------------------------------------------------------

  cli_process_start("Overwriting contract file {i}/{n_con}")
  write_delim(
    x = us,
    file = ,
    delim = ",",
    na = "",
    quote_escape = "double",
  )
  rm(us)
  Sys.sleep(time = 2)
  invisible(gc(reset = TRUE, full = TRUE))
  cli_process_done()

}

# upload ==================================================================

file_stamp <- c(start_date, end_date) %>%
  str_remove_all(pattern = "-") %>%
  str_c(collapse = "-")

if (FALSE) {
  for (i in seq_along(all_tsv)) {
    file_type <- all_tsv[i] %>%
      str_detect("Contracts") %>%
      if_else("contracts", "assist")
    cli_process_start("Uploading {i}/{n_tsv}")
    put_object(
      file = raw_tsv[i],
      object = sprintf("csv/us_%s_%s_%i.csv", file_type, file_stamp, i),
      bucket = "publicaccountability",
      acl = "public-read",
      multipart = TRUE,
      verbose = FALSE,
      show_progress = FALSE
    )
    cli_process_done()
  }
}
