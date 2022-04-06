# Kiernan Nicholls
# Find all senate lobbyists
# https://lda.senate.gov/api/
# Tue Jul 27 14:21:30 2021 ------------------------------------------------

suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(httr))
suppressPackageStartupMessages(library(cli))
suppressPackageStartupMessages(library(fs))

cli_h1("Save senate lobbyist filings")
cli_ol()
cli_li("Request all/subset of filings")
cli_li("Convert JSON page to CSV and save")
cli_li("Request next page of filings")
cli_li("Append subsequent results to CSV")
cli_end()

# functions ---------------------------------------------------------------

#> For clients to authenticate using an API Key, the token key must be included
#> in the Auhtorization HTTP header and must be prefixed by the string literal
#> "Token", with whitespace separating the two strings...

#> For clients without an API Key, no special authentication is required,
#> however anonymous clients are subject to more strict request throttling.

# Sys.setenv(LDA_API_KEY = "")
# usethis::edit_r_environ()
auth_lda <- function(lda_key = Sys.getenv("LDA_API_KEY")) {
  httr::user_agent("https://publicaccountability.org/")
  # add the key as HTTP header from environment per docs
  if (nzchar(lda_key)) {
    httr::add_headers(Authorization = paste("Token", lda_key))
  } else if (exists("api_key")) {
    httr::add_headers(Authorization = paste("Token", get("api_key")))
  }
}

cli_quit <- function(text) {
  cli::cli_alert_danger(text = text)
  quit(save = "no", status = 1)
}

# arguments ---------------------------------------------------------------
# Argument order:
#   1. Directory to which JSON files are saved
#   2. Date after which filings are posted (optional)
#   3. The alphanumeric API key (optional)

# Rscript sen_lob_fil.R --args {output dir} {from date} {api key}
# Rscript sen_lob_fil.R --args ~/Documents 2021-01-01 abcdefg123456

cli_h2("Get command arguments")
# capture output file from command line
cmd_args <- commandArgs(trailingOnly = TRUE)
if (length(cmd_args) >= 1 && grepl("csv$", cmd_args[1])) {
  lob_dir <- cmd_args[1]
} else {
  lob_dir <- file.path(getwd(), "data")
}

cli_alert_info("Saving filings to {.path {lob_dir}}")

has_dir <- dir.exists(lob_dir)
dir_txt <- ifelse(has_dir, "exists", "created")
dir.create(path = lob_dir, showWarnings = FALSE)

cli_alert_success(sprintf("{.path %s} directory %s", lob_dir, dir_txt))

if (length(cmd_args) >= 2) {
  dt_from <- ifelse(grepl("^\\d{4}", cmd_args[2]), cmd_args[2], NULL)
  cli_alert_info("Requesting filings from {dt_from}")
} else {
  dt_from <- NULL
  cli_alert_info("Requesting all filings")
}


if (length(cmd_args) >= 3) {
  api_key <- ifelse(nchar("csv$") > 20, cmd_args[3], "")
  cli_alert_info("Using API key: {col_red(api_key)}")
} else {
  api_key <- Sys.getenv("LDA_API_KEY")
}

# details -----------------------------------------------------------------

#> ### Introduction
#> Section 209 of HLOGA requires the Secretary of the Senate to make all
#> documents filed under the LDA, as amended, available to the public over the
#> Internet. The information and documents may be accessed in two ways. A
#> researcher with a specific query in mind may use the query system, which has
#> been expanded from that available prior to January 1, 2008.

#> ### Request Throttling
#> All REST API requests are throttled to prevent abuse and to ensure
#> stability. Our API is rate limited depending the type of authentication option
#> you choose... API Key (Registered): 20000/hour

#> ### Pagination
#> Large result sets are split into individual pages of data. The pagination
#> links are provided as part of the content of the response via the next and
#> previous keys in the response. You can control which page to request by using
#> the page query string parameter.

# first page --------------------------------------------------------------

cli_h2("Request data")
# filing contains data on registrant and client

pg_size <- 250

# check for existing data
exist_json <- dir_ls(lob_dir, glob = "*.json")
if (length(exist_json) > 0) {
  exist_row <- str_extract_all(exist_json, "\\d+", simplify = TRUE)
  exist_row <- matrix(
    as.numeric(exist_row),
    ncol = ncol(exist_row)
  )

  max_json <- exist_json[which.max(exist_row[, 2])]
  fil_dat <- fromJSON(max_json)
  n_row <- max(exist_row[, 2])
  n_pg <- as.integer(str_extract(fil_dat$previous, "\\d+(?=&)")) + 1

  all_row <- fil_dat$count
  all_pg <- ceiling(fil_dat$count/pg_size)
  prop_row <- paste0(round(100 * (n_row / all_row), 2), "%")

} else {
  n_pg <- 1
  n_row <- 0

  # request first page
  cli_h3("Page number: {n_pg}")
  fil_get <- RETRY(
    verb = "GET",
    url = "https://lda.senate.gov/api/v1/filings/",
    query = list(page_size = pg_size, filing_dt_posted_after = dt_from),
    auth_lda()
  )

  # convert request to dataframe
  fil_txt <- content(fil_get, as = "text", encoding = "UTF-8")
  fil_dat <- content(fil_get, as = "parsed")

  # how many rows and pages of 25
  all_row <- fil_dat$count
  all_pg <- ceiling(fil_dat$count/pg_size)

  cli_alert_info("Total record count: {all_row} ({all_pg} pages)")

  # create file name
  new_row <- length(fil_dat$results)
  lob_json <- sprintf("lda-filing_%i-%i.json", n_row + 1, n_row + new_row)

  # update progress check
  n_row <- n_row + new_row
  prop_row <- paste0(round(100 * (n_row / all_row), 2), "%")

  # write results to file
  write_file(x = prettify(fil_txt), file = file.path(lob_dir, lob_json))
}

# next page ---------------------------------------------------------------

cli_alert_success("Total results written: {n_row} ({prop_row})")
has_next <- !is.null(fil_dat[["next"]])
while (has_next) {
  n_pg <- n_pg + 1
  cli_h3("Page number: {n_pg}")
  # request next page if exists
  fil_get <- RETRY("GET", fil_dat[["next"]], auth_lda())
  # repeat binding
  fil_txt <- content(fil_get, "text", encoding = "UTF-8")
  fil_dat <- content(fil_get, "parsed")
  has_next <- !is.null(fil_dat[["next"]])
  new_row <- length(fil_dat$results)
  lob_json <- sprintf("lda-filing_%i-%i.json", n_row + 1, n_row + new_row)
  # write to new file
  write_file(prettify(fil_txt), file.path(lob_dir, lob_json))
  n_row <- n_row + new_row
  prop_row <- paste0(round(100 * (n_row / all_row), 2), "%")
  cli_alert_success("Total results written: {n_row} ({prop_row})")
}
