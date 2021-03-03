# Wed Mar  3 17:45:59 2021 ------------------------------
# Request US spending between two dates
# Investigative Reporting Workshop
# Public Accountability Project
# Author: Kiernan Nicholls
#   kiernan@irworkshop.org
#   kiernann@protonmail.com

#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
here::i_am("us/spending/us_spend_update.R")

cli::cli_h1("update federal spending")
cli::cli_h2("preparing request")

# load packages -----------------------------------------------------------

if (!require("pacman")) {
  install.packages("pacman")
}
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  aws.s3, # aws cloud storage
  glue, # code strings
  here, # project paths
  httr, # http requests
  here, # local paths
  cli, # command line
  fs # local storage
)

cli_alert_success("attached 10 additional packages")

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

if (length(args) == 2) {
  cli_alert_info("using date arguments from command line")
  end_date <- as.Date(args[2], tryFormats = c("%Y-%m-%d", "%m/%d/%Y"))
  start_date <- as.Date(args[1], tryFormats = c("%Y-%m-%d", "%m/%d/%Y"))
} else if (length(args) == 0){
  cli_alert_info("using supplied date variables")
  # define dates here w/out args
  end_date <- Sys.Date()
  start_date <- end_date - 7
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

cli_alert_success(paste(
  "obtained {style_bold(nrow(award_types))} award codes",
  "{col_silver(Sys.time())}"
))

# make request ============================================================
cli_h2("request bulk zip")

cli_alert(paste(
  "making request from",
  "{col_blue('https://api.usaspending.gov/')}",
  "{col_silver(Sys.time())}"
))
cli_alert_info("data between {start_date} and {end_date}")

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

if (http_error(award_post)) {
  cli_alert_danger(http_status(award_post)$message)
  stop_for_status(award_post)
}

post_date <- award_post$date
post_info <- content(award_post)

cli_alert_success("status: {col_green('requested')} {col_silver(post_date)}")

# check status ------------------------------------------------------------
# cli_h3("check file status")

# All_PrimeTransactions_2021-03-02_H16M49S35586986.zip

cli_alert("wait for file to be ready for download")
while (!exists("post_status") || post_status == "running") {
  # request status
  status_get <- content(GET(
    url = spend_api("bulk_download/status/"),
    query = list(file_name = post_info$file_name)
  ))
  post_status <- status_get$status
  if (post_status == "running") {
    cli_alert_info(paste(
      "status: {col_cyan(post_status)}, waiting 5 min",
      "{col_silver(Sys.time())}"
    ))
    # wait 5 minutes and check again
    Sys.sleep(time = 300)
  } else {
    cli_alert_success(paste(
      "status: {col_green(post_status)}",
      "{col_silver(Sys.time())}"
    ))
  }
}

# download bulk zip when ready --------------------------------------------
# cli_h3("download bulk zip")

# check size before download
# kilobytes to total bytes
bulk_length <- status_get$total_size * 1000

raw_zip <- here("us", "spending", post_info$file_name)

cli_alert(paste(
  "starting downloading:",
  "{col_blue(str_trunc(post_info$file_url, 50, 'center'))}",
  "{col_silver(Sys.time())}"
))

cli_alert_info("file size: {col_silver(fs_bytes(bulk_length))}")

# download locally
if (file_exists(raw_zip)) {
  cli_alert_warning("file already exists on disk")
} else {
  bulk_save <- GET(
    url = post_info$file_url,
    write_disk(path = raw_zip),
    progress(type = "down")
  )
}

cli_alert_success(paste(
  "download complete:",
  "{col_blue(str_trunc(raw_zip, 50, 'center'))}",
  "{col_silver(Sys.time())}"
))


# extract files -----------------------------------------------------------
# cli_h3("extract bulk zip")

# list the zip contents
zip_list <-
  unzip(raw_zip, list = TRUE) %>%
  as_tibble() %>%
  transmute(
    path = fs_path(Name),
    size = fs_bytes(Length),
    date = Date
  )

cli_alert(paste(
  "extracting files to",
  "{col_blue(usa_dir)}",
  "{col_silver(Sys.time())}"
))

# extract all files
all_tsv <- unzip(
  zipfile = raw_zip,
  exdir = usa_dir
)

cli_alert_success(paste(
  "extracted {col_green(nrow(zip_list))} files",
  "{col_silver(Sys.time())}"
))

quit()

# contracts ===============================================================

# list the contract files from zip
con_tsv <- str_subset(all_tsv, "All_Contracts")
con_n <- length(con_tsv)

col_file <- here("us", "spending", "con_cols.csv")
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

if (FALSE) {
  for (file_name in done_files) {
    put_object(
      file = file_name,
      object = path("csv", file_name),
      bucket = "publicaccountability",
      acl = "public-read",
      multipart = TRUE
    )
  }
}
