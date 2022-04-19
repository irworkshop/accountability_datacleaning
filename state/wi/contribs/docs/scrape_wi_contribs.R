# Kiernan Nicholls
# Fri Oct 1 11:40 2021
# Scrape Wisconsin Contributions

suppressPackageStartupMessages(library(RSelenium))
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(scales))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(rvest))
suppressPackageStartupMessages(library(here))
suppressPackageStartupMessages(library(cli))
suppressPackageStartupMessages(library(fs))

cli_h1("Download Wisconsin Contributions")

# define the directory to save files
wi_dir <- commandArgs(trailingOnly = TRUE)
if (length(wi_dir) != 1 || !is_dir(wi_dir)) {
  # create new directory if none supplied
  wi_dir <- dir_create(here("wi", "contribs", "data", "scrape"))
}

# functions ---------------------------------------------------------------

# this function helps easily identify buttons and boxes
wi_css <- function(browser, css) {
  browser$findElement("id", css)
}

# this function helps wait for browser to download
file_wait <- function(file, wait = 1) {
  cli::cli_process_start("Downloading {.path {basename(file)}}")
  while(!fs::file_exists(file)) Sys.sleep(time = wait)
  cli::cli_process_done()
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

# navigate to the WI contribution search page
chrome$navigate("https://cfis.wi.gov/Public/PublicNote.aspx?Page=ReceiptList")
Sys.sleep(5)
wi_css(chrome, "btnContinue")$clickElement()

# filing period
wi_css(chrome, "cmbFilingCalenderName")$clickElement()
period_box <- wi_css(chrome, "cmbFilingCalenderName_Input")
period_box$clearElement()
period_box$sendKeysToElement(list("All Filing Periods"))

# dates
wi_html <- read_html(chrome$getPageSource()[[1]])
wi_dt_box <- html_element(wi_html, "#dtpDateStart_dateInput_ClientState")
wi_dt_box <- fromJSON(html_attr(wi_dt_box, "value"))

from_dt <- as.Date(str_sub(wi_dt_box$minDateStr, end = 10))
thru_dt <- as.Date(str_sub(wi_dt_box$maxDateStr, end = 10))

# find the boxes to enter to and thru dates
wi_css(chrome, "dtpDateStart_dateInput")$sendKeysToElement(out_mdy(from_dt))
wi_css(chrome, "dtpDateEnd_dateInput")$sendKeysToElement(out_mdy(thru_dt))
Sys.sleep(1)

# submit search with only date range
wi_css(chrome, "btnSearch")$clickElement()
cli_alert_success("Searching {from_dt} thru {thru_dt}")
Sys.sleep(300)

# -------------------------------------------------------------------------

pg_src <- read_html(chrome$getPageSource()[[1]])

# read the 65,000 ranges from drop down list
n_range <- html_text(html_elements(pg_src, "#cmbExportRecords_DropDown ul li"))

n_all <- as.integer(strsplit(n_range[length(n_range)], "-")[[1]][2])
ceiling(n_all / 65000) == length(n_range)

# -------------------------------------------------------------------------

wi_csv <- path(wi_dir, sprintf("wi_contribs_%s.csv", n_range))

# this is the default chrome download file
dl_csv <- path_home("Downloads", "ReceiptsList.csv")

for (i in seq_along(n_range)) {
  cli_h3("Get rows {n_range[i]}")
  if (file_exists(wi_csv[i])) {
    cli_alert_success("File {.path {basename(wi_csv[i])}} already saved")
    next
  }
  n_drop <- wi_css(chrome, "cmbExportRecords_Input")
  n_drop$clearElement()
  n_drop$sendKeysToElement(list(n_range[i]))
  wi_css(chrome, "btnTextextra")$clickElement()
  Sys.sleep(10)
  file_wait(dl_csv)
  file_move(dl_csv, wi_csv[i])
  cli_alert_success("File moved to {.path {basename(wi_csv[i])}}")
  Sys.sleep(10)
}

# close browser -----------------------------------------------------------

# close the browser and driver
chrome$close()
remote_driver$server$stop()
