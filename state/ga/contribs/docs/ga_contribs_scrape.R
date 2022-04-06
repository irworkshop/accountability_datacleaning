# Kiernan Nicholls
# Wed Oct 20 12:49:47 2021
# Scrape Georgia Contributions

suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(scales))
suppressPackageStartupMessages(library(purrr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(rvest))
suppressPackageStartupMessages(library(here))
suppressPackageStartupMessages(library(httr))
suppressPackageStartupMessages(library(cli))
suppressPackageStartupMessages(library(fs))

cli_h1("Download Georgia Contributions")

ga_dir <- dir_create(here("ga", "contribs", "data", "raw"))

home_pg <- GET(
  url = "https://media.ethics.ga.gov",
  path = c("search", "Campaign", "Campaign_ByContributionsearchresults.aspx")
)

cook <- cookies(home_pg)
sesh_id <- setNames(cook$value, cook$name)
cli_alert_info("SessionId: {sesh_id}")

name_self <- function(x) {
  set_names(x, x)
}

view_names <- c(
  "EVENTTARGET", "EVENTARGUMENT", "VIEWSTATE",
  "VIEWSTATEGENERATOR", "EVENTVALIDATION"
)

# -------------------------------------------------------------------------

# determine start/resume date
exist_csv <- dir_ls(ga_dir, glob = "*.csv")
n_csv <- length(exist_csv) # starting number of files
if (n_csv > 0) {
  cli_alert_info("Resuming from date of last existing file")
  # pull start date from file
  from_dt <- ymd(str_extract(exist_csv[n_csv], "\\d{8}\\.csv")) + 1
} else {
  cli_alert_info("Starting from scratch with manual date")
  # start from Jan 1 2000
  from_dt <- as.Date("2006-01-01")
}

n_csv <- n_csv + 1 # start next file
n_try <- 1 # start from first attempt

# -------------------------------------------------------------------------

while (!exists("thru_dt") || (thru_dt < Sys.Date() & n_try == 1)) {

  cli_h2("File {n_csv}: attempt #{n_try}")

  # try to get 365 days at a time
  # if multiple tries, smaller range
  thru_dt <- from_dt + (365/n_try)

  # identify file with dates
  dt_stamp <- paste(str_remove_all(c(from_dt, thru_dt), "-"), collapse = "-")
  ga_csv <- path(ga_dir, sprintf("ga_contribs_%s.csv", dt_stamp))

  ga_get <- GET(
    url = home_pg$url,
    set_cookies(sesh_id),
    query = list(
      Contributor = "",
      Zip = "",
      City = "",
      ContTypeID = 0,
      PAC = "",
      Employer = "",
      Occupation = "",
      From = format(from_dt, "%m/%d/%Y"),
      To = format(thru_dt, "%m/%d/%Y"),
      Cash = "",
      InK = "",
      Filer = "",
      Candidate = "",
      Committee = ""
    )
  )

  Sys.sleep(runif(1, 5, 10))
  get_status <- http_status(ga_get)
  if (http_error(ga_get)) {
    cli_alert_warning(get_status$message)
    # increment attempt and start from top
    n_try <- n_try + 1
    Sys.sleep(2)
    next
  } else {
    cli_alert_success("Searching {from_dt} thru {thru_dt}")
  }

  # -----------------------------------------------------------------------

  pg_src <- content(ga_get)
  # check the number of results from header
  pg_info <- html_element(pg_src, "#ctl00_ContentPlaceHolder1_lblPageInfo")
  pg_count <- html_text(pg_info)
  if (nzchar(pg_count)) {
    n_pg <- as.integer(str_extract(pg_count, "(\\d+)$"))
    cli_alert_info("Up to {n_pg * 10} results")
  } else {
    stop("Error in search")
  }

  view_state <- map(
    .x = name_self(paste0("__", view_names)),
    .f = ~html_attr(html_element(pg_src, paste0("#", .)), "value")
  )

  ga_post <- POST(
    url = ga_get$url,
    set_cookies(sesh_id),
    write_disk(path = ga_csv),
    body = c(
      view_state,
      list(
        `ctl00$ContentPlaceHolder1$Export.x` = "168",
        `ctl00$ContentPlaceHolder1$Export.y` = "14"
      )
    )
  )
  Sys.sleep(runif(1, 10, 20))

  post_status <- http_status(ga_post)
  if (http_error(ga_post)) {
    cli_alert_warning(post_status$message)
    # increment attempt and start from top
    n_try <- n_try + 1
    Sys.sleep(2)
    next
  } else {
    cli_alert_success("Saved {file_size(ga_csv)}")
  }

  # start from next day
  from_dt <- thru_dt + 1

  # reset file and attempt
  n_csv <- n_csv + 1
  n_try <- 1
}
