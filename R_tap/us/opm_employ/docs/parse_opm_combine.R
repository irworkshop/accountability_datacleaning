# Kiernan Nicholls
# Investigative Reporting Workshop
# Combine OPM employee data
# 2021-12-07

library(tidyverse)
library(fuzzyjoin)
library(lubridate)
library(campfin)
library(janitor)
library(readxl)
library(rvest)
library(httr)
library(usa)
library(fs)

# functions ---------------------------------------------------------------


# 2014 non-dod ------------------------------------------------------------

# The data from 1974-2014 is in a fixed width format
# Column names and widths come from the FOIA response
# Dynamic files list ascensions and separations

opm_readme <- read_lines("us/opm_employ/data/FOIA_2017-04762/docs/2015-02-11-opm-foia-response_djvu.txt")

# read the README txt and parse the record format lines
opm_fwf <- str_squish(str_subset(opm_readme[340:458], "."))

# each column is on alternating lines
opm_fwf <- tibble(
  element = opm_fwf[seq(1, 57, by = 4)],
  start   = as.integer(opm_fwf[seq(2, 58, by = 4)]),
  end     = as.integer(opm_fwf[seq(3, 59, by = 4)]),
  length  = as.integer(opm_fwf[seq(4, 60, by = 4)])
)

# convert element names to column names
opm_fwf$element <- str_remove(opm_fwf$element, "\\s\\(.*\\)")
opm_fwf$element <- make_clean_names(opm_fwf$element)
opm_fwf$element[4] <- "type_indicator"

# list all opm dynamic files
opm_txt_14 <- dir_ls("us/opm_employ/data/FOIA_2017-04762/data/1973-09-to-2014-06/non-dod/dynamic/")

opm_14 <- lapply(
  X = opm_txt_14,
  FUN = function(x) {
    message(basename(x))
    y <- read.fwf(
      file = x,
      widths = opm_fwf$length,
      col.names = opm_fwf$element,
      colClasses = "character",
      strip.white = TRUE,
      na.strings = c("", "NA"),
      comment.char = ""
    )
    y$effective_date <- as.Date(y$effective_date, "%Y%m%d")
    as_tibble(y)
  }
)

names(opm_14) <- basename(names(opm_14))
opm_14 <- bind_rows(opm_14, .id = "source_file")
opm_14 <- relocate(opm_14, source_file, .after = last_col())

# geographic locator codes ------------------------------------------------

# download excel file from gsa
glc_url <- "https://www.gsa.gov/cdnstatic/FRPP_GLC_-_United_StatesNov42021.xlsx"
glc_xls <- file_temp(ext = path_ext(glc_url))
download.file(glc_url, glc_xls)

# read and convert cols
glc <- read_excel(
  path = glc_xls,
  col_types = "text"
)

glc <- clean_names(glc)
glc$date_record_added <- excel_numeric_to_date(as.double(glc$date_record_added))

# leading zeroes dropped
glc <- glc %>%
  mutate(across(state_name, abbrev_state)) %>%
  select(
    duty_station = duty_station_code,
    duty_state = state_name,
    duty_city = city_name,
    duty_county = county_name
  ) %>%
  distinct()

# find bad ----------------------------------------------------------------

# find most common bad codes
bad_duty <- opm_14 %>%
  filter(duty_station %out% glc$duty_station) %>%
  count(duty_station, sort = TRUE) %>%
  add_prop() %>%
  mutate(p2 = cumsum(p))

# ignore NA values
bad_code <- bad_duty$duty_station
bad_code <- na.omit(na_rep(bad_code))

# write codes and check if exist
duty_csv <- "us/opm_employ/data/duty_lookup.csv"
has_duty <- file_exists(duty_csv)
if (has_duty) {
  duty_info <- read_csv(duty_csv)
} else {
  duty_info <- tibble(Code = NA_character_)
}

# don't recheck saved codes
bad_code <- bad_code[bad_code %out% duty_info$Code]
length(bad_code)

pb <- txtProgressBar(max = length(bad_code) + 1, style = 3)
for (i in seq_along(bad_code)) {
  a <- GET( # make request to OPM server
    url = "https://dw.opm.gov/datastandards/dutystation/searchbycode",
    query = list(code = bad_code[i])
  )
  b <- content(a) # check for table
  c <- html_element(b, ".DataTable")
  if (!is.na(c)) { # save existing tables
    d <- html_table(c, convert = FALSE)
  } else {
    d <- tibble(Code = bad_code[i])
  }
  write_csv(
    x = d,
    file = duty_csv,
    append = !has_duty,
    progress = FALSE
  )
  Sys.sleep(runif(1, 1, 2))
  setTxtProgressBar(pb, i)
}

# all stations ------------------------------------------------------------

duty_info <- read_csv(duty_csv)

duty_info <- duty_info %>%
  select(
    duty_station = Code,
    duty_state = State,
    duty_city = City,
    duty_county = County
  )

# combine GLC with OPM checks
all_duty <- bind_rows(glc, duty_info)

opm_14 %>%
  filter(
    # remove rows with ##### or **** duty
    # str_detect(duty_station, "^(.)\\1{0,}$", negate = TRUE),
    # remove rows with duty still unknown
    duty_station %out% all_duty$duty_station
  ) %>%
  count(duty_station, sort = T)

opm_14 %>%
  select(duty_station) %>%
  left_join(all_duty, by = "duty_station")

# use FIPS to add state, etc when missing
bad_duty <- all_duty[!complete.cases(all_duty), ]
no_state <- bad_duty[is.na(bad_duty$duty_state), ]
no_state$duty_state <- str_sub(no_state$duty_station, end = 2)

# find bad states with fips that can be identified
num_st <- no_state[str_detect(no_state$duty_state, "^\\d{2}$"), ]
wrd_st <- no_state[!str_detect(no_state$duty_state, "^\\d{2}$"), ]
num_st$duty_state <- states$abb[match(num_st$duty_state, states$fips)]

# add back to all bad
bad_duty <- bind_rows(
  bad_duty[!is.na(bad_duty$duty_state), ],
  num_st,
  wrd_st
)

# add back to all duty
all_duty <- bind_rows(
  all_duty[complete.cases(all_duty), ],
  bad_duty
)

# SCTFILE.TXT -------------------------------------------------------------

sct_fwf <- str_squish(str_subset(opm_readme[557:787], "."))
sct_fwf <- str_subset(sct_fwf, "yyyymm", negate = TRUE)

# each column is on alternating lines
sct_fwf <- tibble(
  element  = sct_fwf[seq(1, 96, by = 4)],
  type     = sct_fwf[seq(2, 96, by = 4)],
  length   = as.integer(sct_fwf[seq(3, 96, by = 4)]),
  position = sct_fwf[seq(4, 96, by = 4)]
)

sct <- read_fwf(
  file = "us/opm_employ/data/FOIA_2017-04762/data/1973-09-to-2014-06/SCTFILE.TXT",
  col_positions = fwf_widths(
    widths = sct_fwf$length,
    col_names = sct_fwf$element
  ),
  col_types = cols(
    .default = col_character()
  )
)

# convert SCT codes to dates
sct_date <- function(x) {
  #> values are zeros ... do not use Data Code validity date ranges: GF, VM.
  x[x == "000000"] <- NA
  #> A value of "999999" ... indicates the code is currently valid.
  x[x == "999999"] <- format(Sys.Date(), "%Y%m")
  parse_date(x, format = "%Y%m") # yyyymm (no day)
}

# pull out the codes
sct_codes <- sct %>%
  select(1:6) %>%
  clean_names("snake") %>%
  mutate(across(starts_with("Date"), sct_date))

# the older codes come 2nd
codes_1 <- sct_codes %>%
  select(1:2, 3:4) %>%
  drop_na(starts_with("date")) %>%
  rename(date_from = 3, date_until = 4) %>%
  mutate(code_period = 2, .after = 2)

codes_2 <- sct_codes %>%
  select(1:2, 5:6) %>%
  drop_na(starts_with("date")) %>%
  rename(date_from = 3, date_until = 4) %>%
  mutate(code_period = 1, .after = 2)

# recombine 1 and 2 code periods
sct_codes <- bind_rows(codes_1, codes_2)
rm(codes_1, codes_2)
sct_codes <- sct_codes %>%
  arrange(sct_table_id, data_code, code_period)

# pull out the translations and combine vertically
sct_tran <- sct %>%
  select(-contains("Code in Use")) %>%
  mutate(across(starts_with("Date"), sct_date)) %>%
  clean_names("snake")

# take each n group and separate
tran_n <- as.integer(unique(str_extract(names(sct_tran)[-c(1:2)], "\\d$")))

out <- rep(list(NA), length(tran_n))
for (i in tran_n) {
  message(i)
  out[[i]] <- sct_tran %>%
    select(1:2, matches(sprintf("%i$", i))) %>%
    mutate(tran_num = i, .after = 2) %>%
    rename_all(str_remove, "_\\d$") %>%
    drop_na(contains("date"))
}

# recombine with new num column
sct_tran <- bind_rows(out)

# agency codes ------------------------------------------------------------

agency_tran <- sct_tran %>%
  filter(sct_table_id == "AG")

agency_dt <- opm_14 %>%
  distinct(agency_subelement, effective_date)

all_agency <- agency_dt %>%
  left_join(
    y = agency_tran,
    by = c("agency_subelement" = "data_code")
  ) %>%
  filter(
    effective_date %within% interval(
      start = date_trans_in_use_from,
      end = date_trans_in_use_until
    )
  ) %>%
  select(1:2, agency_name = translation) %>%
  distinct()
