## ----setup, include=FALSE------------------------------------------------
library(knitr)
opts_chunk$set(
  echo = TRUE,
  warning = FALSE
)
options(width = 99)


## ----libs, message=FALSE, warning=FALSE, error=FALSE---------------------
# install.packages("pacman")
pacman::p_load(
  tidyverse, 
  lubridate, 
  magrittr, 
  janitor, 
  zipcode, 
  here
)


## ----read_csv------------------------------------------------------------
# create path to file
wa_file <- here("wa_contribs", "data", "Contributions_to_Candidates_and_Political_Committees.csv")
# if a recent version exists where it should, read it
if (file.exists(wa_file) & as_date(file.mtime(wa_file)) == today()) {
  wa <- read_csv(
    file = wa_file,
    na = c("", "NA", "N/A"),
    col_types = cols(
      .default = col_character(),
      amount = col_double(),
      receipt_date = col_date(format = "%m/%d/%Y")
    )
  )
} else { # otherwise read it from the internet
  wa <- read_csv(
    file = "https://data.wa.gov/api/views/kv7h-kjye/rows.csv?accessType=DOWNLOAD",
    na = c("", "NA", "N/A"),
    col_types = cols(
      .default = col_character(),
      amount = col_double(),
      receipt_date = col_date(format = "%m/%d/%Y")
    )
  )
}


## ----dims----------------------------------------------------------------
glimpse(wa)
nrow(distinct(wa)) == nrow(wa)
wa %>% 
  select(-id) %>% 
  distinct() %>% 
  nrow() %>% 
  subtract(nrow(wa))


## ----n_distinct----------------------------------------------------------
wa %>% 
  map(n_distinct) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_distinct") %>% 
  mutate(prop_distinct = round(n_distinct / nrow(wa), 4)) %>% 
  print(n = length(wa))


## ------------------------------------------------------------------------
count_na <- function(v) sum(is.na(v))
wa %>% map(count_na) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_na") %>% 
  mutate(prop_na = n_na / nrow(wa)) %>% 
  print(n = length(wa))


## ------------------------------------------------------------------------
wa %>% tabyl(origin) %>% arrange(desc(n))

wa %>% tabyl(type) %>% arrange(desc(n))

wa %>% tabyl(party) %>% arrange(desc(n))

wa %>% tabyl(for_or_against) %>% arrange(desc(n))

wa %>% tabyl(election_year)

wa %>% tabyl(cash_or_in_kind) %>% arrange(desc(n))

wa %>% tabyl(cash_or_in_kind) %>% arrange(desc(n))

wa %>% tabyl(primary_general) %>% arrange(desc(n))

wa %>%  tabyl(code) %>% arrange(desc(n))

wa %>% tabyl(contributor_state) %>% arrange(desc(n))


## ----log_amount_plot, fig.width=10, fig.align="center", fig.keep="none"----
wa %>% 
  ggplot(mapping = aes(x = amount)) +
  geom_histogram(bins = 30) +
  scale_y_log10() +
  scale_x_log10(labels = scales::dollar, 
                breaks = c(1, 10, 100, 1000, 100000, 1000000)) +
  facet_wrap(~cash_or_in_kind, ncol = 1) +
  labs(title = "Logarithmic Histogram of Contribution Amounts",
       x = "Dollars Contributed",
       y = "Number of Contributions")


## ----summary_amount------------------------------------------------------
summary(wa$amount)
summary(wa$amount[wa$amount < 0])
wa$url[wa$amount == min(wa$amount)]


## ----date_dims-----------------------------------------------------------
min(wa$receipt_date, na.rm = TRUE)
max(wa$receipt_date, na.rm = TRUE)
sum(is.na(wa$receipt_date))


## ----n_weird_dates-------------------------------------------------------
wa %>% 
  filter(receipt_date < "2000-01-01") %>%
  arrange(receipt_date) %>% 
  select(
    id, 
    receipt_date, 
    election_year, 
    contributor_name, 
    amount, filer_name
  )

wa %>% 
  filter(receipt_date > today() + years(1)) %>%
  arrange(desc(receipt_date)) %>% 
  select(
    id, 
    receipt_date, 
    election_year, 
    contributor_name, 
    amount, filer_name
  )


## ----weird_dates---------------------------------------------------------
wa <- wa %>% mutate(date_flag = receipt_date < "1990-01-01" | receipt_date > today())


## ----add_vars------------------------------------------------------------
wa <- wa %>% 
  # create needed cols
  mutate(zip5_clean = clean.zipcodes(contributor_zip)) %>% 
  mutate(year_clean = year(receipt_date)) %>%
  # initialize other cols
  mutate(
    address_clean = str_remove(contributor_address, "[:punct:]"),
    city_clean    = contributor_city,
    state_clean   = contributor_state
  )


## ------------------------------------------------------------------------
n_distinct(wa$contributor_zip)
n_distinct(wa$zip5_clean)
sum(nchar(wa$zip5_clean) < 5, na.rm = T)
unique(wa$zip5_clean[nchar(wa$zip5_clean) < 5 & !is.na(wa$zip5_clean)])
wa$zip5_clean[nchar(wa$zip5_clean) < 5 & !is.na(wa$zip5_clean)] <- NA
wa$zip5_clean <- wa$zip5_clean %>% na_if("00000|11111|99999")


## ------------------------------------------------------------------------
n_distinct(wa$contributor_state)


## ----make_valid_abbs, collapse=TRUE--------------------------------------
data("zipcode")
zipcode <- 
  tribble(
    ~city,           ~state,
    "Toronto",       "ON",
    "Quebec City",   "QC",
    "Montreal",      "QC",
    "Halifax",       "NS",
    "Fredericton",   "NB",
    "Moncton",       "NB",
    "Winnipeg",      "MB",
    "Victoria",      "BC",
    "Vancouver",     "BC",
    "Surrey",        "BC",
    "Richmond",      "BC",
    "Charlottetown", "PE",
    "Regina",        "SK",
    "Saskatoon",     "SK",
    "Edmonton",      "AB",
    "Calgary",       "AB",
    "St. John's",    "NL") %>% 
  bind_rows(zipcode) %>%
  mutate(city = str_to_upper(city) %>% str_remove_all("[:punct:]")) %>% 
  arrange(zip)

valid_abbs   <- sort(unique(zipcode$state))
invalid_abbs <- setdiff(wa$contributor_state, valid_abbs)


## ----see_invalid_abbs----------------------------------------------------
wa %>% 
  filter(!(contributor_state %in% valid_abbs)) %>% 
  group_by(contributor_state) %>% 
  count() %>%
  arrange(desc(n))


## ----see_zz_city---------------------------------------------------------
wa %>%
  filter(contributor_state == "ZZ") %>% 
  pull(contributor_city) %>% 
  unique()


## ----fix_zz_state--------------------------------------------------------
wa$state_clean[wa$contributor_state == "ZZ" & 
                 wa$contributor_city == "VANCOUVER BC" & 
                   !is.na(wa$contributor_state)] <- "BC"

wa$state_clean[wa$contributor_state == "ZZ" & 
                 wa$contributor_city == "RICHMOND, BC" & 
                   !is.na(wa$contributor_state)] <- "BC"

wa$state_clean[wa$contributor_state == "ZZ" & 
                 wa$contributor_city == "SURREY BC" & 
                   !is.na(wa$contributor_state)] <- "BC"


## ----fix_xx_state--------------------------------------------------------
wa$state_clean <- wa$state_clean %>% na_if("ZZ")
wa$state_clean <- wa$state_clean %>% na_if("XX") # also foreign


## ----fix_comma_state-----------------------------------------------------
if (
  wa %>% 
  filter(state_clean == ",") %>% 
  pull(contributor_city) %>% 
  unique() %>% 
  equals("SEATTLE")
) {
  wa$state_clean[wa$state_clean == "," & !is.na(wa$state_clean)] <- "WA"
}


## ----fix_re_state--------------------------------------------------------
wa %>% 
  filter(address_clean == "REQUESTED") %>%
  filter(state_clean == "RE") %>% 
  select(
    id,
    contributor_name,
    contributor_address,
    contributor_state,
    contributor_zip,
    amount,
    filer_name
  )

wa$state_clean[wa$address_clean == "REQUESTED" & wa$state_clean == "RE"] <- NA

wa %>% 
  filter(state_clean == "RE") %>% 
  pull(contributor_city) %>% 
  unique()

# if the city is REDMOND and state RE, make WA
wa$state_clean[wa$state_clean == "RE" & 
                 wa$city_clean == "REDMOND" & 
                  !is.na(wa$state_clean)] <- "WA"

# if the city is LAKE FOREST PARK and state RE, make WA
wa$state_clean[wa$state_clean == "RE" & 
                 wa$city_clean == "LAKE FOREST PARK" & 
                  !is.na(wa$state_clean)] <- "WA"



## ----fix_ot_state--------------------------------------------------------
wa %>% 
  filter(state_clean == "OT") %>% 
  select(
    contributor_name,
    contributor_address,
    contributor_city,
    contributor_state,
    contributor_zip,
    filer_name
  )

wa$state_clean %<>% na_if("OT")


## ----fix_digit_state-----------------------------------------------------
if (
  wa %>% 
  filter(state_clean %>% str_detect("[\\d+]")) %>% 
  left_join(
    y = (zipcode %>% 
      select(city, zip, state) %>% 
      drop_na()), 
    by = c("zip5_clean" = "zip")) %>%
  pull(state) %>%
  na.omit() %>% 
  unique() %>% 
  equals("WA")
) {
  wa$state_clean[str_detect(wa$state_clean, "[\\d+]") & !is.na(wa$state_clean)] <- "WA"
}


## ----fix_ol_state--------------------------------------------------------
wa %>% 
  filter(state_clean == "OL") %>% 
  pull(city_clean) %>% 
  unique()

wa$state_clean[wa$state_clean == "OL"] <- "WA"
wa$state_clean[wa$city_clean == "SELFOSS"] <- NA


## ----see_invalid_state_city----------------------------------------------
sum(na.omit(wa$state_clean) %in% invalid_abbs)

wa %>% 
  filter(state_clean %in% invalid_abbs) %>% 
  filter(!is.na(state_clean)) %>% 
  pull(city_clean) %>% 
  unique()


## ----fix_seattle_state---------------------------------------------------
seattle_ids <- wa %>%
  filter(city_clean == "SEATTLE") %>% 
  filter(state_clean %in% invalid_abbs) %>% 
  select(
    id, 
    contributor_name,
    address_clean,
    city_clean,
    state_clean,
    zip5_clean,
    filer_name) %>% 
  left_join(
    (zipcode %>% select(city, zip, state) %>% drop_na()), 
    by = c("zip5_clean" = "zip", "city_clean" = "city")) %>% 
  pull(id)

wa$state_clean[wa$id %in% seattle_ids] <- "WA"
rm(seattle_ids)


## ----fix_di_state--------------------------------------------------------
wa$state_clean[wa$state_clean == "DI" & 
                 wa$city_clean == "WASHINGTON" & 
                   wa$zip5_clean == "20016" & 
                     !is.na(wa$state_clean)] <- "DC"


## ----make_invalid_na, collapse=TRUE--------------------------------------
n_distinct(wa$state_clean)
length(valid_abbs)
sum(na.omit(wa$state_clean) %in% invalid_abbs)
wa$state_clean[wa$state_clean %in% invalid_abbs] <- NA


## ----final_diff, collapse=TRUE-------------------------------------------
n_distinct(wa$state_clean)
setdiff(valid_abbs, sort(unique(wa$state_clean)))


## ----confirm_misspell----------------------------------------------------
n_distinct(wa$contributor_city)
wa %>% tabyl(state_clean) %>% arrange(desc(n))


## ----view_seat_bad-------------------------------------------------------
unique(wa$city_clean[str_detect(wa$city_clean, "SEAT")])


## ----count_weird_city----------------------------------------------------
length(setdiff(wa$city_clean, zipcode$city))


## ----source_refine-------------------------------------------------------
source(here("wa_contribs", "code", "fix_wa_city.R"))
sample_n(city_fix_table, 10)


## ----join_refine---------------------------------------------------------
wa <- wa %>% 
  left_join(city_fix_table, by = c("zip5_clean", "city_clean", "state_clean")) %>% 
  mutate(city_clean = ifelse(is.na(city_fix), city_clean, city_fix)) %>% 
  select(-city_fix)


## ----check_dupes---------------------------------------------------------
wa %>% 
  # select for the important vars
  select(
    id, 
    report_number, 
    contributor_name, 
    amount, 
    filer_name) %>% 
  # drop any row with missing data
  drop_na() %>% 
  # count the rows
  nrow() %>% 
  # check if equal to total total
  subtract(nrow(wa))


## ----flag_missing--------------------------------------------------------
wa %>% 
  select(
    id, 
    report_number,
    contributor_name, 
    amount, 
    filer_name) %>% 
  map(count_na) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_na") %>% 
  mutate(prop_na = n_na / nrow(wa)) %>% 
  print(n = length(wa))

wa %>% 
  # select for the important vars
  select(
    id, 
    report_number,
    contributor_name, 
    amount, 
    filer_name,
    receipt_date) %>% 
  filter(is.na(contributor_name)) %>% 
  print(n = 27)

wa <- wa %>% mutate(missing_flag = is.na(contributor_name))


## ----confirm_n_distinct, collapse=TRUE-----------------------------------
n_distinct(wa$address_clean) - n_distinct(wa$contributor_address)
n_distinct(wa$city_clean)    - n_distinct(wa$contributor_city)  
n_distinct(wa$state_clean)   - n_distinct(wa$contributor_state) 
n_distinct(wa$zip5_clean)    - n_distinct(wa$contributor_zip)   


## ----write_csv, eval=FALSE-----------------------------------------------
## # all data, original and cleaned
## wa %>% write_csv(
##   path = here("wa_contribs", "data", "wa_contribs_all.csv"),
##   na = "",
##   col_names = TRUE,
##   quote_escape = "backslash"
## )
## 
## wa %>%
##   # remove the original contributor_* columns for space
##   select(
##     -contributor_address,
##     -contributor_city,
##     -contributor_state,
##     -contributor_zip
##   ) %>%
##   write_csv(
##     path = here("wa_contribs", "data", "wa_contribs_clean.csv"),
##     na = "",
##     col_names = TRUE,
##     quote_escape = "backslash"
##   )

