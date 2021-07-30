# Kiernan Nicholls
# Fri Jul 30 09:49:29 2021
# Scrape Arizona Contracts

library(tidyverse)
library(lubridate)
library(rvest)
library(httr)
library(cli)
library(fs)

# request home page without filters
home_get <- GET("https://app.az.gov/page.aspx/en/ctr/contract_browse_public")
home_dat <- content(home_get)

# get ASP session ID
home_cook <- cookies(home_get)
sesh_id <- setNames(home_cook$value, nm = home_cook$name)

# determine page count
home_dat %>%
  html_elements(".iv button")

# locate contract table
con_table <- html_element(home_dat, "#body_x_grid_upgrid")

# contract to data frame
azc <- con_table %>%
  html_table(na.strings = "") %>%
  select(-`Editing column`) %>%
  clean_names("snake") %>%
  type_convert(
    na = "",
    col_types = cols(
      effective_date = col_date("%m/%d/%Y"),
      initial_end_date = col_date("%m/%d/%Y")
    )
  )

check <- con_table %>%
  html_elements(".checkbox") %>%
  html_element(".checked")

azc$statewide_contract <- !is.na(check[c(TRUE, FALSE)])
