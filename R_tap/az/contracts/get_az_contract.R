# Kiernan Nicholls
# Fri Jul 30 09:49:29 2021
# Scrape Arizona Contracts

library(tidyverse)
library(RSelenium)
library(lubridate)
library(rvest)
library(httr)
library(cli)
library(fs)

# -------------------------------------------------------------------------

az_dir <- dir_create("~/Desktop/az")

remote_driver <- rsDriver(
  port = 4444L,
  browser = "firefox",
  extraCapabilities = makeFirefoxProfile(
    list(
      browser.download.dir = "~/Downloads/",
      browser.download.folderList = 2L,
      browser.helperApps.neverAsk.saveToDisk = "text/csv"
    )
  )
)

# navigate to the NH download site
remote_browser <- remote_driver$client
home_url <- "https://app.az.gov/page.aspx/en/ctr/contract_browse_public"
remote_browser$navigate(home_url)

pg <- 1

src_html <- remote_browser$getPageSource()[[1]]
html_path <- path(az_dir, sprintf("az_contract-%i.html", pg))
write_lines(src_html, html_path)

# check for next button
no_next <- str_detect(src_html, "ui button disabled icon")
while (!no_next) {
  btn_next <- remote_browser$findElement("css", "#body_x_grid_PagerBtnNextPage")
  btn_next <- btn_next$clickElement()
  message(pg)
  src_html <- remote_browser$getPageSource()[[1]]
  html_path <- path(az_dir, sprintf("az_contract-%i.html", pg))
  write_lines(src_html, html_path)
  no_next <- str_detect(src_html, "ui button disabled icon")
  pg <- pg + 1
  Sys.sleep(1)
}

# close the browser and driver
remote_browser$close()
remote_driver$server$stop()

# -------------------------------------------------------------------------

az_html <- dir_ls(az_dir, glob = "*.html")
az_all <- rep(list(NA), length(az_html))

# -------------------------------------------------------------------------

for (i in seq_along(az_html)) {
  message(i)
  az_all[[i]] <- html_table(html_element(read_html(az_html[i]), "#body_x_grid_upgrid"))
}

for (i in seq_along(az_html)) {
  message(i)
  body <- read_html(az_html[i])
  # locate contract table
  con_table <- html_element(body, "#body_x_grid_upgrid")

  # contract to data frame
  azc <- con_table %>%
    html_table(na.strings = "") %>%
    select(-`Editing column`) %>%
    clean_names("snake") %>%
    type_convert(
      na = "",
      col_types = cols(
        effective_date = col_date("%m/%d/%Y"),
        extended_end_date = col_date("%m/%d/%Y"),
        initial_end_date = col_date("%m/%d/%Y")
      )
    )

  # extract statewide checkbox
  # check <- con_table %>%
  #   html_elements(".checkbox") %>%
  #   html_element(".checked")

  # azc$statewide_contract <- !is.na(check[c(TRUE, FALSE)])

  # extract links
  # con_table %>%
  #   html_elements("td a") %>%
  #   html_attr("href") %>%
  #   str_subset("/ctr/") %>%
  #   unique()

  az_all[[i]] <- azc
}

azc <- bind_rows(az_all)
