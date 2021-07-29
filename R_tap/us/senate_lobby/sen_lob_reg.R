# Kiernan Nicholls
# Tue Jul 27 14:21:30 2021
# find all senate lobbyists
# https://lda.senate.gov/api/

library(readr)
library(httr)
library(cli)
library(fs)

cli_h1("Save senate lobbyist registrants")

# capture output file from command line
cmd_args <- commandArgs(trailingOnly = TRUE)
if (length(cmd_args) > 1) {
  cli_alert_danger("Only one output file may be provided")
  quit(save = "no", status = 1)
} else if (length(cmd_args) == 1 && grepl("csv$", cmd_args)) {
  cli_alert_info("Saving lobbyists to {.path {cmd_args}}")
  lob_csv <- cmd_args
} else {
  lob_csv <- file.path(getwd(), "senate_lobbyists.csv")
  cli_alert_warning("No output file provided, saving to {.path {lob_csv}}")
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

# functions ---------------------------------------------------------------

#> For clients to authenticate using an API Key, the token key must be included
#> in the Auhtorization HTTP header and must be prefixed by the string literal
#> "Token", with whitespace separating the two strings...

#> For clients without an API Key, no special authentication is required,
#> however anonymous clients are subject to more strict request throttling.

# Sys.setenv(LDA_API_KEY = "")
# usethis::edit_r_environ()
auth_lda <- function() {
  # add the key as HTTP header from environment per docs
  httr::add_headers(Authorization = paste("Token", Sys.getenv("LDA_API_KEY")))
}

# get filings -------------------------------------------------------------
# filing contains data on registrant and client

pg_num <- 1
n_row <- 0

# request first page
cli_h3("Page number: {pg_num}")
fil_get <- GET("https://lda.senate.gov/api/v1/filings/", auth_lda())

# convert request to dataframe
fil_dat <- content(fil_get, "parsed", simplifyDataFrame = TRUE, flatten = TRUE)
n_all <- fil_dat$count
res <- fil_dat$results

cli_alert_info("Total record count: {n_all} ({n_all/25} pages)")

# update progress check
n_row <- n_row + nrow(res)
prop_row <- paste0(round(100 * (n_row/n_all), 2), "%")

# write results to file
write_csv(res, file = lob_csv)
cli_alert_success("Total results written: {n_row} ({prop_row})")

# check for next page and repeat
has_next <- is.character(fil_dat[["next"]])
while (has_next) {
  pg_num <- pg_num + 1
  cli_h3("Page number: {pg_num}")
  # request next page if exists
  nx_get <- GET(fil_dat[["next"]], auth_lda())
  # repeat binding
  nx_dat <- content(nx_get, "parsed", simplifyDataFrame = TRUE, flatten = TRUE)
  has_next <- is.character(nx_dat[["next"]])
  nx <- nx_dat$results
  # append to previous page results
  write_csv(nx, file = lob_csv, append = TRUE)
  n_row <- n_row + nrow(nx)
  prop_row <- paste0(round(100 * (n_row/n_all), 2), "%")
  cli_alert_success("Total results written: {n_row} ({prop_row})")
}
