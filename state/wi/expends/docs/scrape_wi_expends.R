# Kiernan Nicholls & Yanqi Xu
# Sun May 28 12:24 2023
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

cli_h1("Download Wisconsin Expenditures")

# define the directory to save files
wi_dir <- commandArgs(trailingOnly = TRUE)
if (length(wi_dir) != 1 || !is_dir(wi_dir)) {
  # create new directory if none supplied
  wi_dir <- dir_create(here("state","wi", "expends", "data", "scrape"))
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
  while(grepl(pattern, unlist(firefox$getCurrentUrl()))) Sys.sleep(time = wait)
  cli::cli_process_done()
}

out_mdy <- function(date) {
  list(format(date, "%m/%d/%Y"))
}

# start remote browser ----------------------------------------------------

# open a remove firebox browser
cli_alert_info("Opening remote firefox browser")
# remote_driver <- rsDriver(
#   port = 4444L,
#   browser = "firefox",
#   iedrver = NULL,
#   verbose = FALSE,
#   extraCapabilities = list(
#     profile.default_content_settings.popups = 0L,
#     download.prompt_for_download = FALSE
#   )
# )

remote_driver <- rsDriver(
  port = 4566L,
  browser = "firefox",
  version = "latest",
  chromever = NULL,
  geckover = "latest",
  iedrver = NULL,
  verbose = FALSE,
  extraCapabilities = makeFirefoxProfile(
    list(
      profile.default_content_settings.popups = 0L,
      download.prompt_for_download = FALSE
    )
  )
)


firefox <- remote_driver$client

# navigate to the WI contribution search page
firefox$navigate("https://cfis.wi.gov/Public/PublicNote.aspx?Page=ExpenseList")
Sys.sleep(5)
wi_css(firefox, "btnContinue")$clickElement()

# filing period
wi_css(firefox, "cmbPayeeCommittee")$clickElement()
period_box <- wi_css(firefox, "cmbFilingCalenderName_Input")
period_box$clearElement()
period_box$sendKeysToElement(list("All Filing Periods"))

# dates
wi_html <- read_html(firefox$getPageSource()[[1]])
wi_dt_box <- html_element(wi_html, "#dtpFromDate_dateInput_ClientState")
wi_dt_box <- fromJSON(html_attr(wi_dt_box, "value"))

from_dt <- as.Date(str_sub(wi_dt_box$minDateStr, end = 10))
#thru_dt <- as.Date(str_sub(wi_dt_box$maxDateStr, end = 10))
thru_date <- as.Date("2023-05-27")

# find the boxes to enter to and thru dates
wi_css(firefox, "dtpFromDate_dateInput_ClientState")$sendKeysToElement(out_mdy(from_dt))
wi_css(firefox, "dtpToDate_dateInput_ClientState")$sendKeysToElement(out_mdy(thru_dt))
Sys.sleep(1)

# submit search with only date range
wi_css(firefox, "btnSearch")$clickElement()
cli_alert_success("Searching {from_dt} thru {thru_dt}")
Sys.sleep(300)

# -------------------------------------------------------------------------
#items 1 to 25 of 664843
pg_src <- read_html(firefox$getPageSource()[[1]])

# read the 65,000 ranges from drop down list
n_range <- html_text(html_elements(pg_src, "#cmbExportRecords_DropDown ul li"))

n_all <- as.integer(strsplit(n_range[length(n_range)], "-")[[1]][2])
ceiling(n_all / 65000) == length(n_range)

# -------------------------------------------------------------------------

wi_csv <- path(wi_dir, sprintf("wi_expends_%s.csv", n_range))

# this is the default firefox download file
dl_csv <- path_home("Downloads", "ExpenseList.csv")

for (i in seq_along(n_range)) {
  cli_h3("Get rows {n_range[i]}")
  if (file_exists(wi_csv[i])) {
    cli_alert_success("File {.path {basename(wi_csv[i])}} already saved")
    next
  }
  n_drop <- wi_css(firefox, "cmbExportRecords_Input")
  n_drop$clearElement()
  n_drop$sendKeysToElement(list(n_range[i]))
  wi_css(firefox, "btnTextextra")$clickElement()
  Sys.sleep(10)
  file_wait(dl_csv)
  file_move(dl_csv, wi_csv[i])
  cli_alert_success("File moved to {.path {basename(wi_csv[i])}}")
  Sys.sleep(10)
}

# close browser -----------------------------------------------------------

# close the browser and driver
firefox$close()
remote_driver$server$stop()
