# Kiernan Nicholls
# Mon Sep 27 11:29 2021
# Scrape 3,381,933 Louisiana Contributions

suppressPackageStartupMessages(library(RSelenium))
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(scales))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(rvest))
suppressPackageStartupMessages(library(here))
suppressPackageStartupMessages(library(cli))
suppressPackageStartupMessages(library(fs))

cli_h1("Download Louisiana Contributions")

# define the directory to save files
la_dir <- commandArgs(trailingOnly = TRUE)
if (length(la_dir) != 1 || !is_dir(la_dir)) {
  # create new directory if none supplied
  la_dir <- dir_create(here("la", "contribs", "data", "scrape"))
}

# functions ---------------------------------------------------------------

# this function helps easily identify buttons and boxes
la_css <- function(browser, cph) {
  browser$findElement("css", paste0("#ctl00_ContentPlaceHolder1_", cph))
}

# this function helps wait for browser to download
file_wait <- function(file, wait = 1) {
  cli::cli_process_start("Downloading")
  while(!fs::file_exists(file)) Sys.sleep(time = wait)
  cli::cli_process_done(paste("Downloading ...", fs::file_size(file)))
}

# this function helps wait for browser to download
page_wait <- function(pattern, wait = 1) {
  cli::cli_process_start("Loading")
  while(grepl(pattern, unlist(chrome$getCurrentUrl()))) Sys.sleep(time = wait)
  cli::cli_process_done()
}

out_mdy <- function(date) {
  list(format(date, "%m/%d/%Y"))
}

# start remote browser ----------------------------------------------------

# open a remove firebox browser
cli_alert_info("Opening remote chrome browser")
remote_driver <- rsDriver(
  port = 4444L,
  browser = "chrome",
  verbose = FALSE,
  extraCapabilities = list(
    profile.default_content_settings.popups = 0L,
    download.prompt_for_download = FALSE
  )
)

chrome <- remote_driver$client

# navigate to the IL contribution search page
chrome$navigate(
  url = paste(
    "https://www.ethics.la.gov",
    "CampaignFinanceSearch",
    "SearchEfilingContributors.aspx",
    sep = "/"
  )
)

# loop through dates ------------------------------------------------------

# this is the default chrome download file
dl_csv <- path_home(
  "Downloads",
  sprintf("SearchResults_%s.csv", format(Sys.Date(), "%Y_%-m_%d"))
)

# determine start/resume date
exist_csv <- dir_ls(la_dir, glob = "*.csv")
n_csv <- length(exist_csv) # starting number of files
if (n_csv > 0) {
  cli_alert_info("Resuming from date of last existing file")
  # pull start date from file
  from_dt <- ymd(str_extract(exist_csv[n_csv], "\\d{8}\\.csv")) + 1
} else {
  cli_alert_info("Starting from scratch with manual date")
  # start from Jan 1 1997
  from_dt <- as.Date("1997-01-01")
}

n_csv <- n_csv + 1 # start next file
n_try <- 1 # start from first attempt

while (!exists("thru_dt") || thru_dt < Sys.Date()) {

  cli_h2("File {n_csv}: attempt #{n_try}")

  # try to get 365 days at a time
  # if multiple tries, smaller range
  n_thru <- ifelse(leap_year(from_dt), 365, 364)
  thru_dt <- from_dt + (n_thru / n_try)

  # find the boxes to enter to and thru dates
  la_css(chrome, "DateFromRadDateInput")$sendKeysToElement(out_mdy(from_dt))
  la_css(chrome, "DateToRadDateInput")$sendKeysToElement(out_mdy(thru_dt))
  Sys.sleep(1)

  # submit search with only date range
  la_css(chrome, "PerformSearchLinkButton")$clickElement()
  page_wait("SearchEfiling|LoadSearch", 10)
  cli_alert_success("Searching {from_dt} thru {thru_dt}")

  # -----------------------------------------------------------------------

  pg_src <- read_html(chrome$getPageSource()[[1]])

  # check the number of results from footer
  count_lbl <-
    html_text(html_element(pg_src, "#ctl00_ContentPlaceHolder1_CountLabel"))
  n_row <- str_extract_all(count_lbl, "[0-9]{1,3}(,[0-9]{3})*", TRUE)
  n_row <- parse_number(n_row[length(n_row)])
  # if the search returns more than 100,000
  n_over <- n_row > 1e5 # max results per download
  if (n_over) {
    cli_alert_warning("{comma(n_row)} results: retry with new dates")
    # increment attempt and start from top
    n_try <- n_try + 1
    la_css(chrome, "ContrHyperLink")$clickElement()
    page_wait("SearchResults", 10)
    Sys.sleep(5)
    next
  } else {
    cli_alert_success("{comma(n_row)} results: proceed to download")
  }

  # -----------------------------------------------------------------------

  # download to default directory
  if (file_exists(dl_csv)) file_delete(dl_csv)
  la_css(chrome, "ExportToCSVLinkButton")$clickElement()
  file_wait(dl_csv) # wait for download

  # if (read_names(dl_csv)[1] != "FilerLastName") {
  #   stop("File download error")
  # }

  # move from default to dir with timestamp file name
  dt_stamp <- paste(str_remove_all(c(from_dt, thru_dt), "-"), collapse = "-")
  la_csv <- path(la_dir, sprintf("la_contribs_%s.csv", dt_stamp))
  file_move(dl_csv, la_csv)
  cli_alert_success("File moved to {.path {basename(la_csv)}}")

  # -----------------------------------------------------------------------

  # leave the download page
  la_css(chrome, "ContrHyperLink")$clickElement()
  page_wait("SearchResults", 10)
  Sys.sleep(10)

  # start from next day
  from_dt <- thru_dt + 1

  # reset file and attempt
  n_csv <- n_csv + 1
  n_try <- 1
  Sys.sleep(runif(1, 5, 10))
}

# close browser -----------------------------------------------------------

# close the browser and driver
chrome$close()
remote_driver$server$stop()
