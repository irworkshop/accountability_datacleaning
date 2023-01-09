#!/usr/bin/env Rscript

# Tue Mar 9 13:22:23 2021 -------------------------------------------------
# Request US spending between two dates
# Investigative Reporting Workshop
# The Accountability Project
# Author: Kiernan Nicholls
#   * kiernan@workshop.org
#   * kiernann@protonmail.com

# load packages -----------------------------------------------------------

pkg <- c("aws.s3", "readr", "httr", "here", "cli", "fs")
pkg <- pkg[!(pkg %in% rownames(installed.packages()))]
if (length(pkg) > 0) {
  message(
    sprintf("Please install %s additional package(s):\n", length(pkg)),
    paste("  -", pkg, collapse = "\n")
  )
  quit(save = "no", status = 1)
}

suppressPackageStartupMessages(library(aws.s3))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(httr))
suppressPackageStartupMessages(library(here))
suppressPackageStartupMessages(library(cli))
suppressPackageStartupMessages(library(fs))

# misc --------------------------------------------------------------------

cli_h1("Update Federal Spending")

# check working directory for here::here()
suppressMessages(here::i_am("national/omb_spending/spend_update.R"))
if (!grepl("accountability_datacleaning", getwd())) {
  cli_alert_danger("Please set working directory to {.path R_tap/}")
  quit(save = "no", status = 0)
}

# change cli theme
t <- builtin_theme()
t$span.code[1:2] <- list(`background-color` = "#232323", color = "#ffffff")
options(cli.user_theme = t)

# notes -------------------------------------------------------------------

# for multiple fiscal years, use `spend_history.R`

# Award Types: All
# Agency: Awarding Agency, All
# Location: Recipient Location
# Date Type: Action Date
# File Format: CSV (Comma Delimited)

# There are four file types:
#   1. Contracts
#   2. Financial Assistance
#   3. Sub-Contracts
#   3. Sub-Assistance

# functions ---------------------------------------------------------------

# add time to message
wt <- function(...) {
  paste(..., cli::col_silver(Sys.time()))
}

cli_bytes <- function(x) {
  if (is.character(x) && file.exists(x)) {
    x <- file_size(x)
  }
  style_italic(as.character(as_fs_bytes(x)))
}

# script args -------------------------------------------------------------

# call script from command line with (1) start and (2) end dates
# Rscript --vanilla us_spend_update.R --args 2020-01-01 2020-12-31

# capture command line arguments
cmd_args <- commandArgs(trailingOnly = TRUE)

if (length(cmd_args) == 2) {
  cli_alert_info("Using date range from arguments")
  # capture cmd line args as dates
  end_dt <- as.Date(cmd_args[2], tryFormats = c("%Y-%m-%d", "%m/%d/%Y"))
  start_dt <- as.Date(cmd_args[1], tryFormats = c("%Y-%m-%d", "%m/%d/%Y"))
  if (end_dt < start_dt) {
    cli_alert_danger("End date must come after start date")
    quit(save = "no", status = 1)
  }
} else if (length(cmd_args) == 0){
  ### !!! define dates here
  end_dt <- Sys.Date() - 1
  start_dt <- end_dt - 7
  ### !!!!!!!!!!!!!!!!!!!!!
  cli_alert_info("Using default or user supplied dates")
} else {
  cli_alert_danger("When using args, supply (1) start date & (2) end date")
  quit(save = "no", status = 1)
}

cli_alert("{format(start_dt, '%b %d, %Y')} to {format(end_dt, '%b %d, %Y')}")

# prep data ---------------------------------------------------------------
cli_h2("Prepare request")

# request all award types
award_types <- GET("https://api.usaspending.gov/api/v2/references/award_types")
# convert to data vector of abbreviations
award_types <- unlist(lapply(content(award_types), names))
cli_alert_success(wt("Found {length(award_types)} award types"))

# make request ============================================================
cli_h2("Request bulk download")

cli_alert("Making request from {.url https://api.usaspending.gov/}")
award_post <- POST(
  user_agent("https://publicaccountability.org/"), # identify to server
  url = "https://api.usaspending.gov/api/v2/bulk_download/awards/",
  encode = "json", # send post body as json
  body = list(
    filters = list(
      prime_award_types = award_types, # all award types from above
      sub_award_types = c("procurement", "grant"), # all sub-awards
      date_type = "action_date",
      date_range = list( # dates from cmd or user
        start_date = start_dt,
        end_date = end_dt
      ),
      def_codes = list(),
      agencies = list(
        list( # all agencies
          name = "All",
          tier = "toptier",
          type = "awarding"
        )
      )
    ),
    # columns = list(),
    # CSV with double escape
    # can also be TSV or PIPE
    file_format = "csv"
  )
)

# stop if the POST failed
post_check <- http_status(award_post)
if (http_error(award_post)) {
  cli_alert_danger(wt(post_check$message))
  quit(save = "no", status = 1)
} else {
  cli_alert_success(wt(post_check$message))
}

post_data <- content(award_post)

# check status ------------------------------------------------------------
cli_h2("Check file status")

cli_alert("File name: {.path {post_data$file_name}}")

cli_alert("Wait for file to be ready for download")
while (!exists("post_status") || post_status == "running") {
  # check request download status
  status_get <- content(GET(
    url = "https://api.usaspending.gov/api/v2/bulk_download/status/",
    query = list(file_name = post_data$file_name)
  ))
  post_status <- status_get$status
  ## TODO: Add spinner for waiting
  ## TODO: Change wait time by file size
  if (post_status == "running") {
    n <- 300 # adjust wait in seconds
    m <- round(n/60, digits = 1)
    cli_alert_info(wt("Status: {col_cyan(post_status)}, waiting {m} min"))
    Sys.sleep(time = n)
  } else if (post_status == "failed") {
    cli_alert_danger(wt("Status: {col_red(post_status)}"))
    quit(save = "no", status = 1)
  } else {
    cli_alert_success(wt("Status: {col_green(post_status)}"))
  }
}

# download bulk zip when ready --------------------------------------------
cli_h2("Download bulk file")

# two directories to put raw and final data
data_dir <- dir_create(here("national", "omb_spending", "data", "raw"))
clean_dir <- dir_create(here("national", "omb_spending", "data", "clean"))

raw_zip <- path(data_dir, post_data$file_name)

bulk_size <- fs_bytes(status_get$total_size * 1000)
cli_alert(wt("Starting download ({cli_bytes(bulk_size)})"))
cli_text("{.url {ansi_strtrim(post_data$file_url, console_width() - 3)}}")

# download locally
if (file_exists(raw_zip)) {
  cli_alert_warning("File already exists on disk")
} else {
  bulk_save <- GET(
    url = post_data$file_url,
    write_disk(path = raw_zip),
    progress(type = "down")
  )
  cli_alert_success(wt("Download complete ({cli_bytes(raw_zip)})"))
}

cli_text("{.file {ansi_strtrim(raw_zip, console_width() - 3)}}")

# extract files -----------------------------------------------------------
cli_h2("Extract text files")

# list the zip contents
zip_list <- unzip(raw_zip, list = TRUE)
zip_list$Length <- fs_bytes(zip_list$Length)

cli_alert_info("Bulk zip contains {nrow(zip_list)} text files:")
cli_ol(paste(col_blue(zip_list$Name), col_grey(zip_list$Length)))

cli_process_start("Extracting all files")
all_csv <- unzip(raw_zip, exdir = dirname(raw_zip))
cli_process_done(msg_done = wt("Extracting all files... done"))
n_csv <- length(all_csv)

if (n_csv < 4) {
  cli_alert_danger("Bulk file should contain at least 4 text files")
  quit(save = "no", status = 1)
}

check_file <- here("national", "omb_spending", "spend_check.csv")
all_checks <- data.frame()

# read and check ==========================================================

cli_h2("Checking {n_csv} text file{?s}")

us_cols <- read_csv(
  file = here("national", "omb_spending", "spend_cols.csv"),
  col_types = cols(
    is_con = col_logical(),
    is_sub = col_logical(),
    column = col_character(),
    type = col_character()
  )
)

# previous data -----------------------------------------------------------

read_aws <- function(object, bucket = "publicaccountability") {
  aws.s3::s3read_using(
    FUN = readr::read_csv,
    object = object,
    bucket = bucket,
    col_types = readr::cols(
      .default = readr::col_character()
    )
  )
}

# read the smallest files for contract prime and sub
old_con_prime <- read_aws("csv/us_contract-prime_2004-3.csv")
old_con_sub <- read_aws("csv/us_contract-sub_2002-1.csv")

# repeat for assistance to check column types
old_assist_prime <- read_aws("csv/us_assist-prime_2007-2.csv")
old_assist_sub <- read_aws("csv/us_assist-sub_2001-1.csv")

# the files are hosted on the site as downloaded
# no files need to be read or columns added
# there are date and year columns
# addresses are very clear
# rows are rarely missing values
# only issue is the ZIP+4 in contracts

for (i in seq_along(all_csv)) {
  # read file -------------------------------------------------------------
  cli_h3("Spending file {i}/{n_csv}")
  cli_alert("{.file {basename(all_csv[i])}}")

  # check and indicate file type
  # types can have different names for columns
  xis_con <- grepl("All_Contracts", all_csv[i])
  file_type <- ifelse(xis_con, "contract", "assist")
  xis_sub <- grepl("Subawards", all_csv[i])
  file_type <- paste(file_type, ifelse(xis_sub, "sub", "prime"), sep = "-")
  cli_alert_info("file type: {file_type}")

  type_cols <- us_cols %>%
    filter(
      is_con == xis_con,
      is_sub == xis_sub
    )

  us_spec <- paste(
    # col type string based on file type
    us_cols$type[us_cols$is_con == xis_con & us_cols$is_sub == xis_sub],
    collapse = ""
  )

  # read data frame
  us <- read_delim(
    file = all_csv[i],
    delim = ",",
    escape_double = TRUE,
    na = "",
    # col_names = type_cols$column,
    # col_types = paste(type_cols$type, collapse = ""),
    col_types = cols(.default = col_character()),
    guess_max = 0,
    progress = TRUE
  )

  # change column names based on file type
  dt_col  <- ifelse(xis_sub, "subaward_action_date", "action_date")
  zip_col <- ifelse(xis_sub, "subawardee_zip_code", "recipient_zip_4_code")
  amt_col <- ifelse(xis_sub, "subaward_amount", "federal_action_obligation")
  giv_col <- ifelse(xis_sub, "prime_awardee_name", "awarding_sub_agency_name")
  rec_col <- ifelse(xis_sub, "subawardee_name", "recipient_name")

  n_prob <- nrow(problems(us))
  if (n_prob > 0) {
    cli_alert_warning("Found {n_prob} problem{?s} when reading")
  } else {
    cli_alert_success("File read without any problems")
  }

  invisible(gc(reset = TRUE, full = TRUE))

  # save checks -----------------------------------------------------------
  # cli_h3("Checking data frame structure")

  check <- data.frame(
    file_nm = basename(all_csv[i]),
    file_type = file_type,
    check_dt = Sys.time(),
    start_dt = start_dt,
    end_dt = end_dt,
    min_dt = min(us[[dt_col]], na.rm = TRUE),
    max_dt = max(us[[dt_col]], na.rm = TRUE),
    n_row = nrow(us),
    n_col = ncol(us),
    sum_amt = sum(as.numeric(us[[amt_col]]), na.rm = TRUE),
    zero_amt = sum(as.numeric(us[[amt_col]]) <= 0, na.rm = TRUE)
  )

  all_checks <- do.call("rbind", list(all_checks, check))

  write_csv(check, check_file, append = file_exists(check_file))
  cli_alert_success("Checks saved as row in {.path update_check.csv}")
  row_check <- format(nrow(us), big.mark = ",")

  # adjust columns for new data -------------------------------------------
  if (xis_con) {
    if (xis_sub) {
      us <- us %>%
        select(
          -prime_awardee_uei,
          -prime_awardee_parent_uei,
          -subawardee_uei,
          -subawardee_parent_uei,
          prime_award_description = prime_award_base_transaction_description
        )
      name_check <- all(names(us) == names(old_con_sub))
    } else {
      us <- us %>%
        select(
          -recipient_uei,
          -recipient_parent_uei,
          -transaction_description,
          award_description = prime_award_base_transaction_description
        )
      name_check <- all(names(us) == names(old_con_prime))
    }
  } else {
    if (xis_sub) {
      us <- us %>%
        separate(
          col = prime_award_cfda_numbers_and_titles,
          into = c("prime_award_cfda_number", "prime_award_cfda_title"),
          sep = "(?<=\\d):\\s",
          remove = TRUE,
          extra = "merge"
        ) %>%
        select(
          -prime_awardee_uei,
          -prime_awardee_parent_uei,
          -subawardee_uei,
          -subawardee_parent_uei,
          prime_award_description = prime_award_base_transaction_description
        )
      name_check <- all(names(us) == names(old_assist_sub))
    } else {
      us <- us %>%
        select(
          -indirect_cost_federal_share_amount,
          -recipient_uei,
          -recipient_parent_uei,
          -funding_opportunity_number,
          -funding_opportunity_goals_text,
          -transaction_description,
          award_description = prime_award_base_transaction_description
        )
      name_check <- all(names(us) == names(old_assist_prime))
    }
  }

  if (isTRUE(name_check)) {
    cli_alert_success("New file names match old file names")
  } else {
    cli_alert_danger("New file names mismatch old file names")
    quit(save = "no", status = 1)
  }

  # save new file ---------------------------------------------------------
  cli_h3("Save file after checking and changing")
  # append dates to file names
  file_dates <- paste(gsub("-", "", c(start_dt, end_dt)), collapse = "-")

  file_n <- regmatches(
    x = all_csv[i],
    m = regexpr(pattern = "\\d+\\.csv", text = all_csv[i])
  )

  new_name <- paste("us", file_type, file_dates, file_n, sep = "_")

  cli_process_start("Overwriting file {i}/{n_csv}")
  # save as csv with empty cells and double quotes
  write_csv(us, file = path(clean_dir, new_name), na = "")
  rm(us)
  Sys.sleep(time = 2)
  invisible(gc(reset = TRUE, full = TRUE))
  cli_process_done(msg_done = wt("Overwriting file {i}/{n_csv}"))

  # upload to aws -----------------------------------------------------------
  # only try upload if set to TRUE and AWS key is found
  if (nzchar(Sys.getenv("AWS_SECRET_ACCESS_KEY"))) {
    cli_process_start("Uploading file {i}/{n_csv}")
    suppressMessages(
      expr = put_object(
        file = path(clean_dir, new_name),
        object = path("csv", new_name),
        bucket = "publicaccountability",
        acl = "public-read",
        multipart = TRUE,
        verbose = FALSE,
        show_progress = FALSE
      )
    )
    cli_process_done()
  }
}
