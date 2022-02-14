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

# 2014 ====================================================================

# The data from 1974-2014 is in a fixed width format
# Column names and widths come from the FOIA response pdf
# Dynamic files list accessions and separations

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

# order text files by date
opm_txt_tbl <- tibble(file = basename(opm_txt_14))
opm_txt_tbl <- opm_txt_tbl %>%
  extract(
    col = file,
    into = c("month", "year"),
    regex = "^(\\w{3})(\\d{4})\\.",
    convert = TRUE,
    remove = FALSE
  ) %>%
  mutate(
    month = factor(month, levels = toupper(month.abb))
  ) %>%
  arrange(year, month)

opm_txt_14 <- opm_txt_14[match(opm_txt_tbl$file, basename(opm_txt_14))]

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

sct_tran <- sct_tran %>%
  rename(
    date_from = date_trans_in_use_from,
    date_until = date_trans_in_use_until
  ) %>%
  # shift end date to be exclusive w/ no overlap
  mutate(date_until = date_until - 1)

# agency codes ------------------------------------------------------------

#> AG - Agency with Subelement
agency_tran <- sct_tran %>%
  filter(sct_table_id == "AG") %>%
  select(-sct_table_id)

# pull distinct code/date combos to match and rejoin later
# our translations must match 1:1 (972,790)
agency_dates <- opm_14 %>%
  distinct(agency_subelement, effective_date)

# start by matching codes with a single translation
single_tran <- agency_tran %>%
  group_by(data_code) %>%
  # find codes with one one translation
  filter(n_distinct(translation) == 1) %>%
  # keep only one of repeat translations
  slice(1) %>%
  ungroup() %>%
  # remove unneeded dates
  select(data_code, translation)

# set aside matching translations
tran_alpha <- inner_join(
  x = agency_dates,
  y = single_tran,
  by = c("agency_subelement" = "data_code")
)

# remove matched dates before continue
multi_tran <- anti_join(
  x = agency_dates,
  y = tran_alpha,
  by = "agency_subelement"
)

nrow(tran_alpha) + nrow(multi_tran) == 972790

x <- multi_tran %>%
  rename(date_from = effective_date) %>%
  mutate(date_until = date_from) %>%
  group_split(agency_subelement)

length(x)

out <- rep(list(NA), length(x))
# for each data code...
for (i in seq_along(x)) {
  message(i)
  # find all translations for code
  code <- unique(x[[i]]$agency_subelement)
  tran <- agency_tran %>%
    filter(data_code == str_remove_all(code, "\\*")) %>%
    select(-data_code, -tran_num) %>%
    distinct()
  if (any(table(tran$date_from) > 1) | any(table(tran$date_until) > 1)) {
    # fix date overlaps
    tran <- tran %>%
      group_by(date_from) %>%
      # keep longest interval if same start date
      filter(date_until == max(date_until)) %>%
      ungroup()
    tran <- tran %>%
      group_by(date_until) %>%
      # keep longest interval if same end date
      filter(date_from == min(date_from)) %>%
      ungroup()
  }
  # join possible tran by date overlap
  y <- interval_left_join(
    x = x[[i]],
    y = tran,
    by = c("date_from", "date_until")
  )
  stopifnot(nrow(y) == nrow(x[[i]]))
  # isolate code, date, tran
  out[[i]] <- y %>%
    select(
      -ends_with(".y"),
      -date_until.x,
      effective_date = date_from.x
    )
}

tran_bravo <- bind_rows(out)

all_tran <- bind_rows(tran_alpha, tran_bravo)
nrow(all_tran) == nrow(agency_dates)

rm(tran_alpha, tran_bravo, x, out, multi_tran, single_tran)

# repeat for AH codes -----------------------------------------------------

# find missing translations
noagency_date <- all_tran %>%
  filter(is.na(translation)) %>%
  mutate(agency_withoutsub = str_remove_all(agency_subelement, "\\*")) %>%
  select(-translation)

has_tran <- all_tran %>%
  filter(!is.na(translation))

#> AH - Agency without Subelement
noagency_tran <- sct_tran %>%
  filter(sct_table_id == "AH") %>%
  select(-sct_table_id)

# start by matching codes with a single translation
single_tran <- noagency_tran %>%
  group_by(data_code) %>%
  # find codes with one one translation
  filter(n_distinct(translation) == 1) %>%
  # keep only one of repeat translations
  slice(1) %>%
  ungroup() %>%
  # remove unneeded dates
  select(data_code, translation)

# set aside matching translations
tran_charlie <- inner_join(
  x = noagency_date,
  y = single_tran,
  by = c("agency_withoutsub" = "data_code")
)

# remove matched dates before continue
multi_tran <- anti_join(
  x = noagency_date,
  y = tran_charlie,
  by = "agency_subelement"
)

nrow(tran_charlie) + nrow(multi_tran) == 3163

x <- multi_tran %>%
  rename(date_from = effective_date) %>%
  mutate(date_until = date_from) %>%
  group_split(agency_subelement)

length(x)

out <- rep(list(NA), length(x))
# for each data code...
for (i in seq_along(x)) {
  message(i)
  # find all translations for code
  code <- unique(x[[i]]$agency_subelement)
  tran <- agency_tran %>%
    filter(data_code == str_remove_all(code, "\\*")) %>%
    select(-data_code, -tran_num) %>%
    distinct()
  if (any(table(tran$date_from) > 1) | any(table(tran$date_until) > 1)) {
    # fix date overlaps
    tran <- tran %>%
      group_by(date_from) %>%
      # keep longest interval if same start date
      filter(date_until == max(date_until)) %>%
      ungroup()
    tran <- tran %>%
      group_by(date_until) %>%
      # keep longest interval if same end date
      filter(date_from == min(date_from)) %>%
      ungroup()
  }
  # join possible tran by date overlap
  y <- interval_left_join(
    x = x[[i]],
    y = tran,
    by = c("date_from", "date_until")
  )
  stopifnot(nrow(y) == nrow(x[[i]]))
  # isolate code, date, tran
  out[[i]] <- y %>%
    select(
      -ends_with(".y"),
      -date_until.x,
      effective_date = date_from.x
    )
}

tran_delta <- bind_rows(out)

more_tran <- bind_rows(tran_charlie, tran_delta)
nrow(more_tran) == nrow(noagency_date)

more_tran <- select(more_tran, -agency_withoutsub)

all_tran <- bind_rows(has_tran, more_tran)
nrow(all_tran) == nrow(agency_dates)

rm(more_tran, tran_charlie, tran_delta, x, out, multi_tran, single_tran)

# apply recent code to rest -----------------------------------------------

still_no_tran <- all_tran %>%
  filter(is.na(translation)) %>%
  mutate(agency_withoutsub = str_remove_all(agency_subelement, "\\*")) %>%
  select(-translation)

has_tran <- all_tran %>%
  filter(!is.na(translation))

# use most recent without any date match
recent_tran <- sct_tran %>%
  filter(sct_table_id %in% c("AG", "AH")) %>%
  group_by(data_code) %>%
  arrange(desc(date_until)) %>%
  slice(1) %>%
  ungroup() %>%
  select(data_code, translation)

last_tran <- left_join(
  x = still_no_tran,
  y = recent_tran,
  by = c("agency_withoutsub" = "data_code")
)

last_tran <- last_tran %>%
  select(-agency_withoutsub)

all_tran <- bind_rows(has_tran, last_tran)
rm(last_tran, recent_tran, still_no_tran, has_tran)

# fix one remaining code with no direct translation
all_tran$translation[all_tran$agency_subelement == "JL**"] <- "U.S. COURTS"

all_tran <- rename(all_tran, agency_name = translation)


# type indicators ---------------------------------------------------------

accend_type <- tibble(
  type_indicator = c("A", str_subset(opm_readme[463:471], ".")),
  type_name = c("Accession", str_subset(opm_readme[475:482], "."))
)

depart_type <- tibble(
  type_indicator = c("S", str_subset(opm_readme[494:516], ".")),
  type_name = c("Separation", str_subset(opm_readme[520:535], "."))
)

type_ind <- bind_rows(accend_type, depart_type)
type_ind <- mutate(type_ind, across(everything(), str_trim))

# join codes to data ------------------------------------------------------

opm_14 <- left_join(
  x = opm_14,
  y = all_duty,
  by = "duty_station"
)

opm_14 <- left_join(
  x = opm_14,
  y = all_tran,
  by = c("agency_subelement", "effective_date")
)

opm_14 <- left_join(
  x = opm_14,
  y = type_ind,
  by = "type_indicator"
)

# select columns ----------------------------------------------------------

a <- opm_14

# 2016 ====================================================================

# The data from 2014-2016 is in many pipe delim files
# data column names and translations in separate files
# some variable have combined codes to separate

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
    into = c("agency_cd", "agency"),
    sep = "-",
    extra = "merge",
    fill = "left"
  ) %>%
  separate(
    col = sub_agency,
    into = c("sub_cd", "sub_agency"),
    sep = "-",
    extra = "merge",
    fill = "left"
  ) %>%
  separate(
    col = occupation,
    into = c("occupation_cd", "occupation"),
    sep = "-",
    extra = "merge",
    fill = "left"
  )

# clean -------------------------------------------------------------------

link_delete(dir_link)

b <- opm_16

# 2022 ====================================================================

# Data from 2017-2022 are in pipe delim text files
# Tables finally contain all names and translations

opm_txt_2022 <- dir_ls("us/opm_employ/data/FOIA_2022-00300/non-dod/dynamics/")

opm_21 <- read_delim(
  file = opm_txt_2022,
  delim = "|",
  col_types = cols(
    .default = col_character(),
    EffectiveDate = col_date("%Y%m")
    # LengthOfService = col_number()
  )
)

opm_21 <- clean_names(opm_21, case = "snake")

opm_21$length_of_service <- parse_number(opm_21$length_of_service, na = ".")
opm_21$length_of_service <- round(opm_21$length_of_service, 2)

opm_21 <- separate(
  data = opm_21,
  col = name,
  into = c("family_name", "given_name"),
  sep = ",\\s",
  fill = "right",
  extra = "merge"
)

c <- opm_21
