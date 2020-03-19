library(tidyverse)
library(lubridate)
library(campfin)
library(vroom)
library(here)
library(fs)

### Variable `f` is imported from diary local env loop
y <- as.integer(str_extract(f, "(?<=FY)\\d{4}"))
new_dir <- fs::dir_create(here::here("contracts", "data", "new"))
new_path <- str_replace(basename(f), "All_Contracts_Full_\\d+", "trim")
new_path <- fs::path(new_dir, new_path)
n <- basename(new_path)

if (file_exists(new_path)) {
  message(sprintf("%s exists", n))
  next()
} else {
  message(sprintf("%s starting", n))
}

# read files for year -----------------------------------------------------

# read split files together
usac <- vroom::vroom(
  file = f,
  delim = ",",
  escape_backslash = FALSE,
  escape_double = FALSE,
  guess_max = 0,
  na = c("", "NA", "NAN", "*"),
  # add file column
  id = "file",
  # read only the needed cols
  col_types = vroom::cols(
    .default = col_character(),
    contract_transaction_unique_key = col_character(),
    award_id_piid = col_character(),
    action_date_fiscal_year = col_integer(),
    action_date = col_date(),
    federal_action_obligation = col_double(),
    awarding_agency_name = col_character(),
    awarding_sub_agency_name = col_character(),
    awarding_office_name = col_character(),
    recipient_name = col_character(),
    recipient_parent_name = col_character(),
    recipient_address_line_1 = col_character(),
    recipient_address_line_2 = col_character(),
    recipient_city_name = col_character(),
    recipient_state_code = col_character(),
    recipient_zip_4_code = col_character(),
    primary_place_of_performance_zip_4 = col_character(),
    award_type_code = col_character(),
    award_description = col_character()
  )
)

# add calendar year
usac <- dplyr::mutate(usac, year = lubridate::year(action_date))

# rename and reorder cols
usac <- dplyr::select(
  .data = usac,
  key = contract_transaction_unique_key,
  id = award_id_piid,
  year,
  fiscal = action_date_fiscal_year,
  date = action_date,
  amount = federal_action_obligation,
  agency = awarding_agency_name,
  sub_agency = awarding_sub_agency_name,
  office = awarding_office_name,
  recipient = recipient_name,
  parent = recipient_parent_name,
  address1 = recipient_address_line_1,
  address2 = recipient_address_line_2,
  city = recipient_city_name,
  state = recipient_state_code,
  zip = recipient_zip_4_code,
  place = primary_place_of_performance_zip_4,
  type = award_type_code,
  desc = award_description,
  file
)

gc(reset = TRUE, full = TRUE)

# shorten file name
usac <- dplyr::mutate_at(
  .tbl = usac,
  .vars = vars(file),
  .funs = ~stringr::str_remove(basename(.), "_All_Contracts_Full_\\d+")
)

# check the file ----------------------------------------------------------

# flag all missing key values
usac <- campfin::flag_na(usac, date, agency, amount, recipient)

# flag all duplicate values
# usac <- campfin::flag_dupes(usac, -key)
gc(reset = TRUE, full = TRUE)

checks <- tibble::tibble(
  f = n,
  year = y,
  rows = nrow(usac),
  cols = ncol(usac),
  types = length(unique(usac$type)),
  na = sum(usac$na_flag, na.rm = TRUE),
  # dupe = sum(usac$dupe_flag, na.rm = TRUE),
  zero = sum(usac$amount <= 0, na.rm = TRUE),
)

check_path <- here("us_con_checks.csv")
readr::write_csv(checks, path = check_path, append = TRUE)
message(sprintf("%s check done: %s", n, basename(check_path)))

# check geo ---------------------------------------------------------------

# trim zip codes
usac <- dplyr::mutate_at(usac, vars(zip, place), stringr::str_sub, end = 5)

geo <- dplyr::bind_rows(
  campfin::progress_table(usac$state, compare = valid_state),
  campfin::progress_table(usac$zip, usac$place, compare = valid_zip),
  campfin::progress_table(usac$city, compare = c(valid_city, extra_city))
)

# add year to progress
geo <- dplyr::mutate(geo, n, y, .before = "stage")
geo <- dplyr::mutate_if(geo, is.numeric, round, 4)

geo_path <- here("us_con_geo.csv")
readr::write_csv(geo, path = geo_path, append = TRUE)
message(sprintf("%s geo done: %s", n, basename(geo_path)))

# save file ---------------------------------------------------------------

readr::write_csv(usac, path = new_path, na = "")
message(sprintf("%s all done", n))
rm(usac, geo, checks)
gc(reset = TRUE, full = TRUE)
