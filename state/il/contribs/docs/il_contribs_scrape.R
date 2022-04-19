# Kiernan Nicholls
# Wed Sep 15 09:22 2021
# Scrape Illinois Contributions

suppressPackageStartupMessages(library(RSelenium))
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(scales))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(rvest))
suppressPackageStartupMessages(library(here))
suppressPackageStartupMessages(library(cli))
suppressPackageStartupMessages(library(fs))

cli_h1("Download Illinois Contributions")

# define the directory to save files
il_dir <- commandArgs(trailingOnly = TRUE)
if (length(il_dir) != 1 || !is_dir(il_dir)) {
  # create new directory if none supplied
  il_dir <- dir_create(here("il", "contribs", "data", "scrape"))
}

# functions ---------------------------------------------------------------

# this function helps easily identify buttons and boxes
il_css <- function(browser, cph) {
  browser$findElement("css", paste0("#ContentPlaceHolder1_", cph))
}

# this function helps wait for browser to download
file_wait <- function(file, wait = 1) {
  cli::cli_process_start("Downloading")
  while(!fs::file_exists(file)) Sys.sleep(time = wait)
  cli::cli_process_done(paste("Downloading ...", fs::file_size(file)))
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
    "https://elections.il.gov",
    "CampaignDisclosure",
    "ContributionSearchByAllContributions.aspx",
    sep = "/"
  )
)

# loop through dates ------------------------------------------------------

# this is the default chrome download file
dl_tsv <- path_home("Downloads", "Receipts.txt")

# determine start/resume date
exist_tsv <- dir_ls(il_dir, glob = "*.tsv")
n_tsv <- length(exist_tsv) # starting number of files
if (n_tsv > 0) {
  cli_alert_info("Resuming from date of last existing file")
  # pull start date from file
  from_dt <- ymd(str_extract(exist_tsv[n_tsv], "\\d{8}\\.tsv")) + 1
} else {
  cli_alert_info("Starting from scratch with manual date")
  # start from Jan 1 2000
  from_dt <- as.Date("2000-01-01")
}

n_tsv <- n_tsv + 1 # start next file
n_try <- 1 # start from first attempt

while (!exists("thru_dt") || thru_dt < Sys.Date()) {

  cli_h2("File {n_tsv}: attempt #{n_try}")

  # try to get 28 days at a time
  # if multiple tries, smaller range
  thru_dt <- from_dt + (28/n_try)

  # find the boxes to enter to and thru dates
  il_css(chrome, "txtRcvDate")$sendKeysToElement(out_mdy(from_dt))
  il_css(chrome, "txtRcvDateThru")$sendKeysToElement(out_mdy(thru_dt))
  Sys.sleep(1)

  # submit search with only date range
  il_css(chrome, "btnContribSubmit")$clickElement()
  Sys.sleep(1)
  cli_alert_success("Searching {from_dt} thru {thru_dt}")

  # -----------------------------------------------------------------------

  pg_src <- read_html(chrome$getPageSource()[[1]])

  # check the number of results from footer
  foot_div <- html_element(pg_src, "#ContentPlaceHolder1_gvContributions_pnlTotalRecords_phPagerTemplate_gvContributions")
  n_row <- parse_number(html_text(foot_div))
  # if the footer hits max 5000 check page top
  if (n_row >= 5000) {
    top_txt <- html_text(html_element(pg_src, "#ContentPlaceHolder1_lblTotals"))
    n_row <- parse_number(str_extract(top_txt, "all (.*) search results"))
  }
  n_over <- n_row > 25000 # max results per download
  if (n_over) {
    cli_alert_warning("{comma(n_row)} results: retry with new dates")
    # increment attempt and start from top
    n_try <- n_try + 1
    chrome$goBack()
    Sys.sleep(2)
    next
  } else {
    cli_alert_success("{comma(n_row)} results: proceed to download")
  }

  # navigate to the download page
  il_css(chrome, "lnkDownloadList")$clickElement()

  # -----------------------------------------------------------------------

  # download to default directory
  if (file_exists(dl_tsv)) file_delete(dl_tsv)
  il_css(chrome, "btnText")$clickElement()
  file_wait(dl_tsv) # wait for download

  # move from default to dir with timestamp file name
  dt_stamp <- paste(str_remove_all(c(from_dt, thru_dt), "-"), collapse = "-")
  il_tsv <- path(il_dir, sprintf("il_contribs_%s.tsv", dt_stamp))
  file_move(dl_tsv, il_tsv)
  cli_alert_success("File moved to {.path {basename(il_tsv)}}")

  # -----------------------------------------------------------------------

  # leave the download page
  chrome$goBack()
  Sys.sleep(2)

  # leave the search results page
  il_css(chrome, "HyperLink1")$clickElement()
  Sys.sleep(runif(1, 3, 5))

  # start from next day
  from_dt <- thru_dt + 1

  # reset file and attempt
  n_tsv <- n_tsv + 1
  n_try <- 1
}

# close browser -----------------------------------------------------------

# close the browser and driver
chrome$close()
remote_driver$server$stop()
