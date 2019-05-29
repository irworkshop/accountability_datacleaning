---
title: "Data Diary"
subtitle: "Illinois Contributions"
author: "Kiernan Nicholls"
date: "2019-05-29 11:53:40"
output:
  html_document: 
    df_print: tibble
    fig_caption: yes
    highlight: tango
    keep_md: yes
    max.print: 32
    toc: yes
    toc_float: no
editor_options: 
  chunk_output_type: console
---



## Packages


```r
# install.packages("pacman")
pacman::p_load(
  tidyverse,
  lubridate,
  magrittr,
  janitor,
  zipcode, 
  here
)
```

## Read

The files can be easily located and listed using the `here` package.


```r
il_files <- list.files(
  full.names = TRUE,
  path = here("il_contribs", "data", "raw")
)
```

### Repair

Three files contain delimiter errors that result in imperfect parsing by `readr::read_delim()`.

* `2010Receipts.txt`
* `2015Receipts.txt`
* `2016Receipts.txt`

All together, there are only a dozen broken lines out of a million but they prevent perfect parsing
of their respective files.

These errors can be removed by reading in the file as a vector of character string using
`readr::read_lines()`, each element containing the raw text of the line.

Broken lines are combined into their proper form and the leftovers are removed.

The repaired vectors are then read as rectangles with `readr::read_delim()` making each element a
row and splitting each row into columns by `\t`.


```r
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
```

```
## [1] 156210
```


```r
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
```

```
## [1] 119696
```


```r
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
```

```
## [1] 137772
```

### Automated

They "perfect" files can all be read at once by applying the `readr::read_delim()` function using
`purrr:map()`.

The files are combined into one with `dplyr::bind_rows()`.


```r
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
```

## Explore


```r
nrow(il)
```

```
## [1] 1387108
```

```r
nrow(distinct(il)) == nrow(il) # no duplicate rows
```

```
## [1] TRUE
```

```r
n_distinct(il$RctNum) == nrow(il) # no duplicate recipt numbers
```

```
## [1] TRUE
```


```r
il %>% tabyl(RedactionRequested)
```

```
## # A tibble: 2 x 3
##   RedactionRequested       n percent
##   <lgl>                <dbl>   <dbl>
## 1 FALSE              1383949 0.998  
## 2 TRUE                  3159 0.00228
```

```r
summary(il$RptPdBegDate)
```

```
##         Min.      1st Qu.       Median         Mean      3rd Qu.         Max.         NA's 
## "2008-01-01" "2010-07-01" "2013-01-01" "2012-12-26" "2015-10-01" "2018-06-26"        "312"
```

```r
summary(il$LoanAmount)
```

```
##     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
## 0.00e+00 0.00e+00 0.00e+00 6.99e+01 0.00e+00 1.00e+06
```

```r
summary(il$Amount)
```

```
##     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
##        0      200      300     1654      803 50000000
```

```r
il %>% tabyl(D2Part)
```

```
## # A tibble: 5 x 3
##   D2Part                        n percent
##   <chr>                     <dbl>   <dbl>
## 1 In-kind                   74662  0.0538
## 2 Individual Contribution 1041022  0.750 
## 3 Loan Received             19383  0.0140
## 4 Other Receipt             27373  0.0197
## 5 Transfer In              224668  0.162
```

```r
il %>% tabyl(ElectionType)
```

```
## # A tibble: 5 x 4
##   ElectionType       n   percent valid_percent
##   <chr>          <dbl>     <dbl>         <dbl>
## 1 CE                50 0.0000360       0.0216 
## 2 CP               319 0.000230        0.138  
## 3 GE              1927 0.00139         0.832  
## 4 GP                21 0.0000151       0.00906
## 5 <NA>         1384791 0.998          NA
```

```r
summary(il$RptPdBegDate)
```

```
##         Min.      1st Qu.       Median         Mean      3rd Qu.         Max.         NA's 
## "2008-01-01" "2010-07-01" "2013-01-01" "2012-12-26" "2015-10-01" "2018-06-26"        "312"
```

```r
summary(il$RptPdEndDate)
```

```
##         Min.      1st Qu.       Median         Mean      3rd Qu.         Max.         NA's 
## "2008-01-14" "2010-12-31" "2013-03-31" "2013-04-23" "2015-12-31" "2018-06-30"        "312"
```

```r
il %>% 
  tabyl(CmteName) %>% 
  as_tibble() %>% 
  arrange(desc(n))
```

```
## # A tibble: 7,083 x 3
##    CmteName                                                  n percent
##    <chr>                                                 <dbl>   <dbl>
##  1 REALTORS® Political Action Committee                  15430 0.0111 
##  2 Health Care Council of IL PAC                         14360 0.0104 
##  3 IUOE Local 399 Political Education Fund               14279 0.0103 
##  4 Commonwealth Edison Co- Affiliate of Exelon Corp, PAC 14246 0.0103 
##  5 Citizens for Rauner, Inc                              13125 0.00946
##  6 Illinois Federation of Teachers COPE                  12510 0.00902
##  7 Taxpayers for Quinn                                   10458 0.00754
##  8 Personal PAC Inc                                      10155 0.00732
##  9 Illinois Health Care Assn PAC                          9990 0.00720
## 10 Citizens for Lisa Madigan                              9920 0.00715
## # … with 7,073 more rows
```

## Clean Data

Objectives:

* Check for consistency issues.
* Create a five-digit ZIP Code called `ZIP5`. 
* Create a `YEAR` field from the transaction date.
* For campaign donation data, make sure there is both a donor _and_ recipient.

### Clean Zip codes

The `zipcode` package contains a `clean.zipcodes()` function that performs a few simple common
fixes (e.g., makes character, removes spaces, restores leading zeroes). It also contains a data
frame of all valid US zip codes along with state and city information.

> This data.frame contains city, state, latitude, and longitude for U.S. ZIP codes from the
CivicSpace Database (August 2004) augmented by Daniel Coven's federalgovernmentzipcodes.us web site
(updated on January 22, 2012).


```r
data("zipcode")
zipcode <- as_tibble(zipcode)

il$Zip5_clean <- clean.zipcodes(il$Zip) %>% str_sub(1, 5)

il$Zip5_clean %<>% na_if("00000")
il$Zip5_clean %<>% na_if("11111")
il$Zip5_clean %<>% na_if("99999")
```

### Extract Year


```r
il <- il %>% mutate(Year_clean = year(RcvDate))
```

### Clean States

There are `length(sort(unique(il$State)))` unique `State` variables. All values are 2 characters or
less.


```r
sort(unique(il$State))
```

```
##   [1] "`"  "60" "61" "A"  "AE" "Ak" "AK" "AL" "Ar" "AR" "AZ" "Ca" "CA" "ch" "Co" "CO" "CR" "ct"
##  [19] "CT" "D." "DC" "De" "DE" "F"  "fl" "Fl" "FL" "Ga" "GA" "HI" "I"  "Ia" "IA" "ID" "il" "iL"
##  [37] "Il" "IL" "IN" "io" "Io" "KS" "ky" "KY" "LA" "ll" "Lo" "Ma" "MA" "MD" "ME" "Mi" "MI" "MM"
##  [55] "Mn" "MN" "mo" "Mo" "MO" "MS" "MT" "MY" "NB" "NC" "ND" "Ne" "NE" "NH" "NJ" "NM" "NV" "NY"
##  [73] "OH" "OK" "ON" "OR" "pa" "Pa" "PA" "PR" "q"  "QC" "RI" "SC" "SD" "Se" "Tn" "TN" "tx" "Tx"
##  [91] "TX" "UT" "Va" "VA" "VI" "VT" "W9" "WA" "wi" "Wi" "WI" "WV" "WY" "ZZ"
```

```r
max(nchar(il$State), na.rm = TRUE)
```

```
## [1] 2
```

These can be cleaned with comprehensive list of state abbreviations in the `zipcodes` package data
set. Most of them are case errors, so we will make all values uppercase. We will also add in the
Canadian province abbreviations.


```r
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
```

There are some 60 rows with bad `State` values. By comparing against the data in the `zipcodes`
package and Google Searching a few `Address1` values, we can fix nearly all of them.


```r
il$State_clean <- str_to_upper(il$State)

bad_states <- setdiff(x = il$State_clean, zipcode$state)

il %>% 
  filter(!(State_clean %in% zipcode$state)) %>%
  filter(State_clean != "ZZ") %>% 
  select(RctNum, Address1, City, State_clean, Zip5_clean) %>%
  sample_n(10)
```

```
## # A tibble: 10 x 5
##    RctNum  Address1                        City         State_clean Zip5_clean
##    <chr>   <chr>                           <chr>        <chr>       <chr>     
##  1 2961359 14 Conti Parkway                Elmwood Park 60          60707     
##  2 2793002 14 Conti Parkway                Elmwood Park 60          60707     
##  3 2961358 14 Conti Parkway                Elmwood Park 60          60707     
##  4 2872445 141 W. Jackson Blvd.-Suite 1901 <NA>         CH          <NA>      
##  5 4893897 104 Wilmot Rd.   MS #1415       Deerfield    `           60015     
##  6 3475399 393 S. Arlington Ave.           Elmhurst     60          60126     
##  7 2961356 14 Conti Parkway                Elmwood Park 60          60707     
##  8 4691727 1340 W. Washington Blvd.        Chicago      I           60607     
##  9 3998860 3508 Roosevelt Road             Taylorville  LL          62568     
## 10 3617671 309 E Maple St.                 Villa Park   I           60181
```

Most of the irregular `State` values are `NA`, "ZZ", or "60". Based off the `City` variable, we can
tell "ZZ" is used to indicate a foreign country. Based off the `Zip` variable, we can tell "60"
(and "61") should all be "IL" (All Zip codes in Illinois start with 6----).

First, we will check `State_clean` against the `city`, `zip`, and `state` values in the `zipcodes`
table. From this info, we can fix most bad `State_clean` values.


```r
il %>% 
  filter(State_clean == "ZZ") %>% 
  count(City) %>% 
  arrange(desc(n))
```

```
## # A tibble: 67 x 2
##    City                    n
##    <chr>               <int>
##  1 Brampton                7
##  2 San Juan                6
##  3 <NA>                    5
##  4 Brampton, Ontario       5
##  5 Brampton Ontario        4
##  6 Mississauga Ontario     4
##  7 Concord Ontario         3
##  8 London                  3
##  9 Mississauga             3
## 10 Montreal                3
## # … with 57 more rows
```

```r
# "60" states have zips in IL
il %>% 
  filter(State_clean == "60") %>% 
  pull(Zip5_clean) %>% 
  unique() %>% 
  sort() %in% 
  zipcode$zip[zipcode$state == "IL"] %>% 
  mean() %>% 
  equals(1)
```

```
## [1] TRUE
```

```r
# "61" states have cities in IL with "61---" zips
il %>% 
  filter(State_clean == "61") %>% 
  pull(City) %>% 
  unique() %in% 
  zipcode$city[zipcode$state == "IL"]
```

```
## [1] TRUE TRUE
```

```r
zipcode$zip[zipcode$city == "Bloomington" & zipcode$state == "IL"]
```

```
## [1] "61701" "61702" "61704" "61705" "61709" "61710" "61791" "61799" "61901"
```

```r
zipcode$zip[zipcode$city == "Champaign" & zipcode$state == "IL"]
```

```
## [1] "61820" "61821" "61822" "61824" "61825" "61826"
```

```r
il %>% 
  filter(State_clean == "F") %>% 
  pull(City) %>% 
  unique()
```

```
## [1] "Crawfordville"
```

```r
# "I" states have zipcodes from IL
il %>% 
  filter(State_clean == "I") %>% 
  pull(Zip5_clean) %in% 
  zipcode$zip[zipcode$state == "IL"] %>% 
  mean() %>% 
  equals(1)
```

```
## [1] TRUE
```

```r
# "IO" states with zipcodes place them in IA
il %>% 
  filter(State_clean == "IO", !is.na(Zip5_clean)) %>% 
  pull(Zip) %in% 
  zipcode$zip[zipcode$state == "IA"] %>% 
  mean() %>% 
  equals(1)
```

```
## [1] TRUE
```

```r
# "NB" states with zipcodes place them in NE
il %>% 
  filter(State_clean == "NB", !is.na(Zip5_clean)) %>% 
  pull(Zip) %in% 
  zipcode$zip[zipcode$state == "NE"] %>% 
  mean() %>% 
  equals(1)
```

```
## [1] TRUE
```

```r
zipcode %>% filter(
  zip == "62568" | 
    zip == "60015" | 
    city == "Mamaroneck"
) 
```

```
## # A tibble: 3 x 5
##   city        state zip   latitude longitude
##   <chr>       <chr> <chr>    <dbl>     <dbl>
## 1 Mamaroneck  NY    10543     41.0     -73.7
## 2 Deerfield   IL    60015     42.2     -87.9
## 3 Taylorville IL    62568     39.5     -89.3
```

Once the correct values are identified, they can be manually replaced.


```r
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
```


```r
il %>% 
  filter(!(State_clean %in% zipcode$state)) %>%
  filter(State_clean != "ZZ") %>% 
  select(RctNum, Address1, City, State_clean, Zip5_clean)
```

```
## # A tibble: 5 x 5
##   RctNum  Address1                City        State_clean Zip5_clean
##   <chr>   <chr>                   <chr>       <chr>       <chr>     
## 1 2665312 300 West Edwards        Springfield Q           <NA>      
## 2 3333619 1020 Constable Drive    Mamaroneck  MY          <NA>      
## 3 3675863 702 SW 8th St           Bentonville A           <NA>      
## 4 4736799 C/O Red Curve Solutions Beverly     MM          <NA>      
## 5 4907046 Flat 4 5 Eton Ave       <NA>        LO          <NA>
```

The last five rows can be figured out based on a combination of their `Address1` and `City` values.


```r
il$State_clean %<>% str_replace_all("^Q$", "IL")
il$State_clean %<>% str_replace_all("MY",  "NY")
il$State_clean %<>% str_replace_all("^A$", "AR")
il$State_clean %<>% str_replace_all("MM",  "MA")
il$State_clean %<>% str_replace_all("LO`", "ZZ")
```

### Clean Cities

Read in a lookup table to correct common City misspellings. Perform a left join and replace bad
names with the good ones from the table. This cuts the number of distinct city names almost in
half.


```r
il_city_lookup <- read_csv(
  file = here("il_contribs", "data", "il_city_lookup.csv"),
  col_types = "cc",
  col_names = c("bad_city", "good_city"),
  skip = 1
)

n_distinct(il$City)
## [1] 10723

# IL contains all lookup
mean(il_city_lookup$bad_city %in% il$City) == 1
## [1] TRUE

il <- il %>% 
  left_join(distinct(il_city_lookup), by = c("City" = "bad_city")) %>%
  rename(City_clean = good_city)

# reduced by half
n_distinct(il$City_clean)
## [1] 5500

# confirm changes
il %>%
  arrange(City) %>% 
  select(
    RctNum, 
    State_clean, 
    Zip5_clean, 
    City, 
    City_clean
  )
## # A tibble: 1,387,108 x 5
##    RctNum  State_clean Zip5_clean City          City_clean 
##    <chr>   <chr>       <chr>      <chr>         <chr>      
##  1 3507110 IL          60662      , Orland Park ORLAND PARK
##  2 4381796 IL          60085      , Waukegan    WAUKEGAN   
##  3 4642016 IL          60441      ;ockport      ROCKPORT   
##  4 3323272 IL          61615      :Peoria       PEORIA     
##  5 3487322 AZ          85054      :Phoenix      PHOENIX    
##  6 3739493 AZ          85054      :Phoenix      PHOENIX    
##  7 3248564 IL          60473      ?             <NA>       
##  8 4930411 IL          60473      ?             <NA>       
##  9 4930312 IL          60473      ?             <NA>       
## 10 3427171 IL          60423      ?Frankfort    FRANKFORT  
## # … with 1,387,098 more rows
```

### Clean Address

First, make all redacted addresses `NA` based off `RedactionRequested`. Then, make useless
information `NA` based on a custom list of non-valuable patterns.


```r
il$Address1_clean <- str_to_upper(il$Address1)

il$Address1_clean[il$RedactionRequested] <- NA

il %>%
  filter(is.na(Zip)) %>%
  select(Address1_clean) %>%
  count(Address1_clean) %>%
  arrange(desc(n))
```

```
## # A tibble: 1,048 x 2
##    Address1_clean             n
##    <chr>                  <int>
##  1 <NA>                    5992
##  2 BEST FAITH EFFORT         39
##  3 BEST EFFORT               28
##  4 INFORMATION REQUESTED     28
##  5 GOOD FAITH EFFORT         25
##  6 GOOD FAITH EFFORT MADE    20
##  7 UNKNOWN                   14
##  8 EFFORT MADE               11
##  9 312 BLUE RIDGE DR         10
## 10 3100 E JACKSON ST          9
## # … with 1,038 more rows
```

```r
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
```

## Check Names

There are no rows without both a donor and recipient.


```r
il %>%
  # select key cols
  select(LastOnlyName, CmteName) %>%
  # drop any row with an NA
  drop_na() %>%
  # check to see if any were dropped
  nrow() %>% 
  equals(nrow(il))
```

```
## [1] TRUE
```

## Write

Before writing to the disk, we will replace all `"` characters with `'` to make nested quotes
easier to deal with across software. `NA` values will be written as empty strings to save space.


```r
il <- il %>% 
  # apply to each column
  map(str_replace_all, "\"", "\'") %>% 
  # recombine columbs
  as_tibble()

# write to disk
write_csv(
  x = il,
  path = here("il_contribs", "data", "il_contribs_clean.csv"),
  na = "",
  col_names = TRUE,
)
```

