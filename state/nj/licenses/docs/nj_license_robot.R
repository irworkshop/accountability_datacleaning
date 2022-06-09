# Kiernan Nicholls
# Wed Jun  8 13:31:01 2022
# Scrape New Jersey Licenses

suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(RSelenium))
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(scales))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(rvest))
suppressPackageStartupMessages(library(here))
suppressPackageStartupMessages(library(cli))
suppressPackageStartupMessages(library(fs))

cli_h1("Download New Jersey Contributions")

# define the directory to save files
nj_dir <- commandArgs(trailingOnly = TRUE)
if (length(nj_dir) != 1 || !is_dir(nj_dir)) {
  # create new directory if none supplied
  nj_dir <- dir_create("~/Desktop/nj")
}

# functions ---------------------------------------------------------------

# this function helps wait for browser to download
file_wait <- function(file, wait = 1) {
  cli::cli_process_start("Downloading")
  while(!fs::file_exists(file)) Sys.sleep(time = wait)
  cli::cli_process_done(paste("Downloading ...", fs::file_size(file)))
}

# start remote browser ----------------------------------------------------

# open a remote chrome browser
cli_alert_info("Opening remote chrome browser")
remote_driver <- rsDriver(
  port = 4444L,
  browser = "chrome",
  version = "3.141.59",
  chromever = "103.0.5060.24",
  verbose = TRUE,
  extraCapabilities = list(
    profile.default_content_settings.popups = 0L,
    download.prompt_for_download = FALSE
  )
)

chrome <- remote_driver$client

# navigate to the NJ license search page
chrome$navigate("https://newjersey.mylicense.com/verification/Search.aspx")

i <- 1

prof_drop <- chrome$findElement("css", "#t_web_lookup__profession_name")
prof_drop$clickElement()
prof_drop$sendKeysToElement(rep(list(selKeys$down_arrow), i))
prof_drop$sendKeysToElement(list(selKeys$return))

sch_button <- chrome$findElement("css", "#sch_button")
sch_button$clickElement()

pg_src <- read_html(chrome$getPageSource()[[1]])

read_datagrid <- function(html) {
  tbl <- html %>%
    html_element("#datagrid_results") %>%
    html_table(na.strings = "")
  tbl %>%
    select(
      full_name = 2,
      license_number = 5,
      profession = 6,
      license_type = 7,
      license_status = 8,
      city = 9,
      state = 10
    ) %>%
    filter(!is.na(full_name)) %>%
    head(-1)
}

read_datagrid(pg_src)

pg_src %>%
  html_elements("#datagrid_results tr") %>%
  last() %>%
  html_elements("a")

next_css <- paste(
  "#datagrid_results > tbody > tr:nth-child(42) > td >",
  sprintf("a:nth-child(%i)", i + 1)
)

next_btn <- chrome$findElement("css", next_css)
next_btn$clickElement()

pg_src <- read_html(chrome$getPageSource()[[1]])
read_datagrid(pg_src)

# close the browser and driver
chrome$close()
remote_driver$server$stop()
