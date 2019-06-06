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


## ----list_files----------------------------------------------------------
il_files <- list.files(
  full.names = TRUE,
  path = here("il_contribs", "data", "raw")
)


## ----fix_il_10-----------------------------------------------------------
il_broken_10 <- read_lines(file = il_files[3])

# Where there is a erronous line break, combine the two false lines
il_broken_10[[98510]] <- str_c(il_broken_10[98510:98511], collapse = TRUE)
# Remove leftover line
il_broken_10 <- il_broken_10[-98511]

il_fixed_10 <- il_broken_10 %>% read_delim(
  delim = "\t",
  trim_ws = TRUE,
  quoted_na = TRUE,
  escape_double = FALSE,
  locale = locale(tz = "US/Central"),
  col_types = cols(
    .default           = col_character(),
    RedactionRequested = col_logical(),
    LoanAmount         = col_double(),
    Amount             = col_double(),
    RcvDate            = col_date(format = "%m/%d/%Y"),
    RptPdBegDate       = col_date(format = "%m/%d/%Y"),
    RptPdEndDate       = col_date(format = "%m/%d/%Y"))
)

nrow(il_fixed_10)


## ----fix_il_15-----------------------------------------------------------
il_broken_15 <- read_lines(file = il_files[8])

il_broken_15[12379] <- str_c(il_broken_15[12379] %>% str_sub(end = -2),
                             il_broken_15[12380],
                             il_broken_15[12385])

il_broken_15[28155] <- str_c(il_broken_15[28155] %>% str_sub(end = -24),
                             il_broken_15[28157])

il_broken_15[56695] <- str_c(il_broken_15[56695], il_broken_15[56697])

il_broken_15[56701] <- str_c(il_broken_15[56701], il_broken_15[56703])

il_broken_15[61683] <- str_c(il_broken_15[61683], il_broken_15[61685])

il_broken_15[61686] <- str_c(il_broken_15[61686], il_broken_15[61688])

il_broken_15[61690] <- str_c(il_broken_15[61690], il_broken_15[61692])

il_broken_15[100263] <- str_c(il_broken_15[100263], il_broken_15[100264])

il_broken_15 <- il_broken_15[-c(12380:12385,
                                28156, 28157,
                                56696, 56697,
                                56702, 56703,
                                61684, 61685,
                                61687, 61688,
                                61691, 61692,
                                100264)]

il_fixed_15 <- il_broken_15 %>%
  read_delim(
    delim = "\t",
    trim_ws = TRUE,
    quoted_na = TRUE,
    escape_double = FALSE,
    locale = locale(tz = "US/Central"),
    col_types = cols(
      .default           = col_character(),
      RedactionRequested = col_logical(),
      LoanAmount         = col_double(),
      Amount             = col_double(),
      RcvDate            = col_date(format = "%m/%d/%Y"),
      RptPdBegDate       = col_date(format = "%m/%d/%Y"),
      RptPdEndDate       = col_date(format = "%m/%d/%Y"))
  )

nrow(il_fixed_15)


## ----fix_il_16-----------------------------------------------------------
il_broken_16 <- read_lines(file = il_files[9])

il_broken_16[12315] <- str_c(il_broken_16[12315],
                             il_broken_16[12317],
                             il_broken_16[12319])

# remove erroneous \t column
il_broken_16[22095] <- il_broken_16[22095] %>%
  str_split("\t") %>%
  unlist() %>%
  extract(-5) %>%
  str_c(collapse = "\t")

il_broken_16[79935] <- str_c(il_broken_16[79935], il_broken_16[79937])

il_broken_16[118771] <- str_c(il_broken_16[118771], il_broken_16[118772])

il_broken_16 <- il_broken_16[-c(12316:12319, 79936, 79937, 118772)]

il_fixed_16 <- il_broken_16 %>%
  read_delim(
    delim = "\t",
    trim_ws = TRUE,
    quoted_na = TRUE,
    escape_double = FALSE,
    locale = locale(tz = "US/Central"),
    col_types = cols(
      .default           = col_character(),
      RedactionRequested = col_logical(),
      LoanAmount         = col_double(),
      Amount             = col_double(),
      RcvDate            = col_date(format = "%m/%d/%Y"),
      RptPdBegDate       = col_date(format = "%m/%d/%Y"),
      RptPdEndDate       = col_date(format = "%m/%d/%Y"))
  )

nrow(il_fixed_16)


## ----read_good-----------------------------------------------------------
il <- map(
  
  # read the unchanged files
  il_files[-c(3, 8, 9)], 
  read_delim, 
  
  # arguments for read_delim()
  delim = "\t",
  trim_ws = TRUE,
  quoted_na = TRUE,
  escape_double = FALSE,
  locale = locale(tz = "US/Central"),
  col_types = cols(
    .default           = col_character(),
    RedactionRequested = col_logical(),
    LoanAmount         = col_double(),
    Amount             = col_double(),
    RcvDate            = col_date(format = "%m/%d/%Y"),
    RptPdBegDate       = col_date(format = "%m/%d/%Y"),
    RptPdEndDate       = col_date(format = "%m/%d/%Y"))
)

# combine back with fixed frames and remove empty col
il <- il %>% 
  bind_rows(il_fixed_10, il_fixed_15, il_fixed_16) %>% 
  select(-X31)

# remove individual objects
rm(il_broken_10, il_broken_15, il_broken_16)
rm(il_fixed_10, il_fixed_15, il_fixed_16)


## ----confirm_size--------------------------------------------------------
nrow(il)
nrow(distinct(il)) == nrow(il) # no duplicate rows
n_distinct(il$RctNum) == nrow(il) # no duplicate recipt numbers


## ----explore_cols--------------------------------------------------------
il %>% tabyl(RedactionRequested)

summary(il$RptPdBegDate)

summary(il$LoanAmount)

summary(il$Amount)

il %>% tabyl(D2Part)

il %>% tabyl(ElectionType)

summary(il$RptPdBegDate)

summary(il$RptPdEndDate)

il %>% 
  tabyl(CmteName) %>% 
  as_tibble() %>% 
  arrange(desc(n))


## ----zips----------------------------------------------------------------
data("zipcode")
zipcode <- as_tibble(zipcode)

il$ZIP5 <- clean.zipcodes(il$Zip) %>% str_sub(1, 5)

il$ZIP5 %<>% na_if("00000")
il$ZIP5 %<>% na_if("11111")
il$ZIP5 %<>% na_if("99999")


## ----year----------------------------------------------------------------
il <- il %>% mutate(YEAR = year(RcvDate))


## ----states--------------------------------------------------------------
sort(unique(il$State))
max(nchar(il$State), na.rm = TRUE)


## ------------------------------------------------------------------------
zipcode <- tribble(
  ~city,           ~state,
  "Toronto",       "ON",
  "Quebec City",   "QC",
  "Montreal",      "QC",
  "Halifax",       "NS",
  "Fredericton",   "NB",
  "Moncton",       "NB",
  "Winnipeg",      "MB",
  "Victoria",      "BC",
  "Charlottetown", "PE",
  "Regina",        "SK",
  "Saskatoon",     "SK",
  "Edmonton",      "AB",
  "Calgary",       "AB",
  "St. John's",    "NL"
) %>% 
  bind_rows(zipcode) %>% 
  arrange(zip)


## ------------------------------------------------------------------------
il$State_clean <- str_to_upper(il$State)

bad_states <- setdiff(x = il$State_clean, zipcode$state)

il %>% 
  filter(!(State_clean %in% zipcode$state)) %>%
  filter(State_clean != "ZZ") %>% 
  select(RctNum, Address1, City, State_clean, ZIP5) %>%
  sample_n(10)


## ----confirm_bad_states, message=FALSE-----------------------------------
il %>% 
  filter(State_clean == "ZZ") %>% 
  count(City) %>% 
  arrange(desc(n))

# "60" states have zips in IL
il %>% 
  filter(State_clean == "60") %>% 
  pull(ZIP5) %>% 
  unique() %>% 
  sort() %in% 
  zipcode$zip[zipcode$state == "IL"] %>% 
  mean() %>% 
  equals(1)

# "61" states have cities in IL with "61---" zips
il %>% 
  filter(State_clean == "61") %>% 
  pull(City) %>% 
  unique() %in% 
  zipcode$city[zipcode$state == "IL"]

zipcode$zip[zipcode$city == "Bloomington" & zipcode$state == "IL"]
zipcode$zip[zipcode$city == "Champaign" & zipcode$state == "IL"]

il %>% 
  filter(State_clean == "F") %>% 
  pull(City) %>% 
  unique()

# "I" states have zipcodes from IL
il %>% 
  filter(State_clean == "I") %>% 
  pull(ZIP5) %in% 
  zipcode$zip[zipcode$state == "IL"] %>% 
  mean() %>% 
  equals(1)

# "IO" states with zipcodes place them in IA
il %>% 
  filter(State_clean == "IO", !is.na(ZIP5)) %>% 
  pull(Zip) %in% 
  zipcode$zip[zipcode$state == "IA"] %>% 
  mean() %>% 
  equals(1)

# "NB" states with zipcodes place them in NE
il %>% 
  filter(State_clean == "NB", !is.na(ZIP5)) %>% 
  pull(Zip) %in% 
  zipcode$zip[zipcode$state == "NE"] %>% 
  mean() %>% 
  equals(1)

zipcode %>% filter(
  zip == "62568" | 
    zip == "60015" | 
    city == "Mamaroneck"
) 


## ------------------------------------------------------------------------
il$State_clean %<>% str_replace_all("^F$", "FL")
il$State_clean %<>% str_replace_all("^I$", "IL")
il$State_clean %<>% str_replace_all("60",  "IL")
il$State_clean %<>% str_replace_all("61",  "IL")
il$State_clean %<>% str_replace_all("IO",  "IA")
il$State_clean %<>% str_replace_all("NB",  "NE")
il$State_clean %<>% str_replace_all("CH",  "IL")
il$State_clean %<>% str_replace_all("D.",  "DC")
il$State_clean %<>% str_replace_all("W9",  "ZZ")
il$State_clean %<>% str_replace_all("SE",  "ZZ")
il$State_clean %<>% str_replace_all("CR",  "ZZ")
il$State_clean %<>% str_replace_all("LL",  "IL")
il$State_clean %<>% str_replace_all("\`",  "IL")


## ------------------------------------------------------------------------
il %>% 
  filter(!(State_clean %in% zipcode$state)) %>%
  filter(State_clean != "ZZ") %>% 
  select(RctNum, Address1, City, State_clean, ZIP5)


## ------------------------------------------------------------------------
il$State_clean %<>% str_replace_all("^Q$", "IL")
il$State_clean %<>% str_replace_all("MY",  "NY")
il$State_clean %<>% str_replace_all("^A$", "AR")
il$State_clean %<>% str_replace_all("MM",  "MA")
il$State_clean %<>% str_replace_all("LO`", "ZZ")


## ----fix_city, collapse=TRUE---------------------------------------------
il_city_lookup <- read_csv(
  file = here("il_contribs", "data", "il_city_lookup.csv"),
  col_types = "cc",
  col_names = c("bad_city", "good_city"),
  skip = 1
)

n_distinct(il$City)

# IL contains all lookup
mean(il_city_lookup$bad_city %in% il$City) == 1

il <- il %>% 
  left_join(distinct(il_city_lookup), by = c("City" = "bad_city")) %>%
  rename(City_clean = good_city)

# reduced by half
n_distinct(il$City_clean)

# confirm changes
il %>%
  arrange(City) %>% 
  select(
    RctNum, 
    State_clean, 
    ZIP5, 
    City, 
    City_clean
  )


## ----na_addresses--------------------------------------------------------
il$Address1_clean <- str_to_upper(il$Address1)

il$Address1_clean[il$RedactionRequested] <- NA

il %>%
  filter(is.na(Zip)) %>%
  select(Address1_clean) %>%
  count(Address1_clean) %>%
  arrange(desc(n))

na_patterns <- c(
  "GOOD FAITH",
  "BEST FAITH",
  "BEST EFFORT",
  "GOOD EFFORT",
  "EFFORT MADE",
  "NO ADDRESS",
  "NONE PROVIDED",
  "PRIVATE ADDRESS",
  "AWAITING",
  "FOLLOW UP",
  "UNKNOWN",
  "UMKNOWN",
  "ATTEMPT",
  "REDACTION",
  "REQUESTED",
  "VARIOUS",
  "MISCELLANEOUS",
  "DID NOT PROVIDE",
  "ACTION FUND",
  "(^|\\b)NA(\\b|$)",
  "XXX",
  "WWW"
)

# if the address matches any pattern, make NA
il$Address1_clean[str_detect(il$Address1_clean, paste(na_patterns, collapse = "|"))] <- NA


## ----no_dupes------------------------------------------------------------
il %>%
  # select key cols
  select(LastOnlyName, CmteName) %>%
  # drop any row with an NA
  drop_na() %>%
  # check to see if any were dropped
  nrow() %>% 
  equals(nrow(il))


## ----write_csv, eval=FALSE-----------------------------------------------
## il <- il %>%
##   # apply to each column
##   map(str_replace_all, "\"", "\'") %>%
##   # recombine columbs
##   as_tibble()
## 
## il %>%
##   # remove unclean cols
##   select(
##     -Address1,
##     -City,
##     -State,
##     -Zip
##   ) %>%
##   # write to disk
##   write_csv(
##     x = il,
##     path = here("il_contribs", "data", "il_contribs_clean.csv"),
##     na = "",
##     col_names = TRUE,
##   )

