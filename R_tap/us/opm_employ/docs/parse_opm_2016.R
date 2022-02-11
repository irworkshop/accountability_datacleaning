# Kiernan Nicholls
# Investigative Reporting Workshop
# Combine OPM employee data
# 2022-02-10

library(tidyverse)
library(campfin)
library(janitor)
library(readxl)
library(fs)

# documentation -----------------------------------------------------------

dir_link <- link_create(
  path = "us/opm_employ/data/FOIA_2017-04762/data/2014-09-to-2016-09/non-dod/",
  new_path = "data_2016"
)

opm_cols_16 <- read_excel(
  path = "data_2016/documentation/Jeremy Singer-Vine Data Record Format.xls",
  sheet = "Dynamics Format",
  range = "A5:B24"
)

opm_cols_16 <- opm_cols_16[[1]] %>%
  str_remove("\\(.*\\)") %>%
  str_trim() %>%
  make_clean_names()

# accessions --------------------------------------------------------------

opm_16_acc <- read_delim(
  file = dir_ls("data_2016/accessions/"),
  delim = "|",
  na = c("############", "."),
  col_names = opm_cols_16,
  col_types = cols(
    .default = col_character(),
    effective_date = col_date("%Y%m%d"),
    adjusted_basic_pay = col_number()
  )
)

# separations -------------------------------------------------------------

opm_16_sep <- read_delim(
  file = dir_ls("data_2016/separations/"),
  delim = "|",
  na = c("############", "."),
  col_names = opm_cols_16,
  col_types = cols(
    .default = col_character(),
    effective_date = col_date("%Y%m%d"),
    adjusted_basic_pay = col_number()
  )
)

# combine -----------------------------------------------------------------

opm_16 <- bind_rows(opm_16_acc, opm_16_sep)

# translate ---------------------------------------------------------------

# read the translations for ACC/SEP code
acc_sep <- read_fwf(
  file = "data_2016/translations/AccSep Translation.txt",
  col_positions = fwf_empty(
    file = "data_2016/translations/AccSep Translation.txt",
    col_names = c("acc_sep", "acc_sep_name"),
    skip = 1
  )
)

# join to end of table
opm_16 <- left_join(
  x = opm_16,
  y = acc_sep,
  by = "acc_sep"
)

opm_16 <- relocate(opm_16, acc_sep_name, .after = acc_sep)

# separate codes from string variables
opm_16 <- opm_16 %>%
  separate(
    col = agency,
    into = c("agency_code", "agency"),
    sep = "-",
    extra = "merge",
    fill = "left"
  ) %>%
  separate(
    col = sub_agency,
    into = c("sub_code", "sub_agency"),
    sep = "-",
    extra = "merge",
    fill = "left"
  ) %>%
  separate(
    col = occupation,
    into = c("occupation_code", "occupation"),
    sep = "-",
    extra = "merge",
    fill = "left"
  )

# clean -------------------------------------------------------------------

link_delete(dir_link)
