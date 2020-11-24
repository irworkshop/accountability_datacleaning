Iowa Contributions
================
Kiernan Nicholls
2020-10-28 14:16:38

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Read](#read)
  - [Explore](#explore)
  - [Categorical](#categorical)
  - [Amounts](#amounts)
  - [Dates](#dates)
  - [Wrangle](#wrangle)
  - [Conclude](#conclude)
  - [Export](#export)
  - [Upload](#upload)
  - [Dictionary](#dictionary)

<!-- Place comments regarding knitting here -->

## Project

The Accountability Project is an effort to cut across data silos and
give journalists, policy professionals, activists, and the public at
large a simple way to search across huge volumes of public data about
people and organizations.

Our goal is to standardizing public data on a few key fields by thinking
of each dataset row as a transaction. For each transaction there should
be (at least) 3 variables:

1.  All **parties** to a transaction.
2.  The **date** of the transaction.
3.  The **amount** of money involved.

## Objectives

This document describes the process used to complete the following
objectives:

1.  How many records are in the database?
2.  Check for entirely duplicated records.
3.  Check ranges of continuous variables.
4.  Is there anything blank or missing?
5.  Check for consistency issues.
6.  Create a five-digit ZIP Code called `zip`.
7.  Create a `year` field from the transaction date.
8.  Make sure there is data on both parties to a transaction.

## Packages

The following packages are needed to collect, manipulate, visualize,
analyze, and communicate these results. The `pacman` package will
facilitate their installation and attachment.

The IRW’s `campfin` package will also have to be installed from GitHub.
This package contains functions custom made to help facilitate the
processing of campaign finance data.

``` r
if (!require("pacman")) install.packages("pacman")
pacman::p_load_gh("irworkshop/campfin")
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  jsonlite, # import json api
  magrittr, # pipe operators
  gluedown, # print markdown
  janitor, # dataframe clean
  refinr, # cluster and merge
  aws.s3, # aws cloud storage
  scales, # format strings
  rvest, # read html pages
  knitr, # knit documents
  vroom, # read files fast
  glue, # combine strings
  here, # relative storage
  fs # search storage 
)
```

This document should be run as part of the `R_campfin` project, which
lives as a sub-directory of the more general, language-agnostic
[`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning)
GitHub repository.

The `R_campfin` project uses the [RStudio
projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects)
feature and should be run as such. The project also uses the dynamic
`here::here()` tool for file paths relative to *your* machine.

``` r
# where does this document knit?
here::here()
#> [1] "/home/kiernan/Code/tap/R_campfin"
```

## Data

Data is obtained from the [Iowa Ethics and Campaign Disclosure
Board](https://ethics.iowa.gov/).

> In order to accomplish its Mission, the Board will enforce the
> provisions of the “Campaign Disclosure Act” in Iowa Code chapter 68A,
> the “Government Ethics and Lobbying Act” in Iowa Code chapter 68B, the
> reporting of gifts and bequests received by agencies under Iowa Code
> section 8.7, and the Board’s administrative rules in Chapter 351 of
> the Iowa Administrative Code.

The Board provides the file through the [state open data
portal](https://data.iowa.gov/) under the title “Iowa Campaign
Contributions Received.” The data can be accessed as a tabular CSV file
or through a number of direct APIs.

The database was created June 18, 2015 and last updated December 10,
2019.

> This dataset contains information on contributions and in kind
> donations made by organizations and individuals to state-wide,
> legislative or local candidate committees, state PACs, county central
> committees, state parties, and state and local ballot issue committees
> in Iowa. Data is available beginning in 2003 for all reports filed
> electronically, and some paper filed reports.

> Data is provided through reports submitted by candidate committees,
> state political committees, federal/out-of-state political committees,
> county central committees, ballot issue committees and organizations
> making contributions or independent expenditures. Quality of the data
> provided in the dataset is dependent upon the accuracy of the data
> reported electronically.

The Board also provides a disclaimer on the completness of the database:

> Data on paper filed reports is not available except for the following:
> contributions to individual candidates between 2003 and 2006 from
> political and party committees; contributions to individual candidates
> 2007 on; contributions to party committees between 2003 and 2007 from
> political and candidate committees; contributions from State Political
> Committees to candidates between 2003 and 2004; contributions from
> Federal/Out-of-State Political Committees over $50 from 2005 on; and
> contributions from county central committees from 2008 on.

The database license is as follows:

> Pursuant to Iowa Code section 68B.32A(7), the information obtained
> from statements or reports filed with the board under Iowa Code
> chapter 68A, Iowa Code chapter 68B, Iowa Code section 8.7, or rules
> adopted by the board shall not be copied or otherwise used for any
> commercial purpose. For purposes of this rule, “commercial purposes”
> shall include solicitations by a business or charitable organization.
> Information used in newspapers, magazines, books, or other similar
> communications, so long as the principal purpose of such
> communications is for providing information to the public and not for
> other commercial purpose, and for soliciting political campaign
> contributions is permissable.

## Read

These fixed files can be read into a single data frame with
`purrr::map_df()` and `readr::read_delim()`.

``` r
raw_dir <- dir_create(here("ia", "contribs", "data", "raw"))
raw_url <- "https://data.iowa.gov/api/views/smfg-ds7h/rows.csv"
raw_path <- path(raw_dir, basename(raw_url))
if (!this_file_new(raw_path)) {
  download.file(raw_url, raw_path)
}
```

``` r
iac <- vroom(
  file = raw_path,
  na = c("", "N/A", "NA", "n/a", "na"),
  col_types = cols(
    .default = col_character(),
    `Date` = col_date_usa(),
    `Contribution Amount` = col_double()
  )
)
```

We can ensure this file was read correctly by counting distinct values
of a known discrete variable.

``` r
n_distinct(iac$type) == 2
#> [1] TRUE
```

## Explore

There are 1,982,775 rows of 14 columns.

``` r
glimpse(iac)
#> Rows: 1,982,775
#> Columns: 14
#> $ tx        <chr> "{14050320-5718-7824-1750-000000000000}", "{15050320-5015-6938-5245-0000000000…
#> $ date      <date> 2003-01-01, 2003-01-01, 2003-01-01, 2003-01-02, 2003-01-02, 2003-01-02, 2003-…
#> $ code      <chr> "6160", "6356", "1040", "6096", "6155", "6063", "9613", "931", "6063", "9613",…
#> $ committee <chr> "Community Bankers of Iowa Political Action Committee", "Planned Parenthood Ad…
#> $ type      <chr> "CON", "CON", "CON", "CON", "CON", "CON", "CON", "CON", "CON", "CON", "CON", "…
#> $ first     <chr> NA, "Alta", NA, "Al", "Steven", "Nancy", "Kathy", NA, "Robert", "Deb", "Jane",…
#> $ mi        <chr> NA, NA, NA, NA, "J", NA, NA, NA, NA, NA, NA, NA, "F", NA, NA, NA, NA, "E", NA,…
#> $ last      <chr> "Unitemized", "Price", "Veridian  Credit Union", "Streb", "Pfannes", "Urbanows…
#> $ addr1     <chr> "123 street", "4888 School House Rd", "1827 Ansborough Ave.", "PO Box 48", "12…
#> $ addr2     <chr> NA, NA, NA, NA, NA, NA, NA, "400 E. Court Ave., Ste 100", "2829 Westown Parkwa…
#> $ city      <chr> "anywhere", "Bettendorf", "Waterloo", "North Liberty", "Boone", "Marshalltown"…
#> $ state     <chr> "IA", "IA", "IA", "IA", "IA", "IA", "IA", "IA", "IA", "IA", "IA", "IA", "NE", …
#> $ zip       <chr> "00000", "52722", "50701", "52317", "50036", "50158", "52403", "50309-2027", "…
#> $ amount    <dbl> 261.00, 50.00, 21.78, 400.00, 25.00, 100.00, 15.00, 250.00, 25.00, 15.00, 20.0…
tail(iac)
#> # A tibble: 6 x 14
#>   tx      date       code  committee   type  first mi    last  addr1 addr2 city  state zip   amount
#>   <chr>   <date>     <chr> <chr>       <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr> <chr>  <dbl>
#> 1 {6DFE1… 2020-05-22 2563  Reichman f… CON   Jeff… D     Reic… P.O.… <NA>  Mont… IA    52639  140  
#> 2 {1B669… 2020-06-01 6125  RPAC Iowa … CON   Renee <NA>  Dunk… 3433… <NA>  Cumm… IA    50061   90.9
#> 3 {7EECA… 2020-06-04 2365  Phil Mille… CON   Barb… <NA>  Royal 4710… <NA>  West… IA    50265   25  
#> 4 {098BE… 2020-06-25 6021  Credit Uni… CON   Mich… <NA>  Ramos 3421… <NA>  East… IL    61244    1  
#> 5 {FB17E… 2020-07-07 6021  Credit Uni… CON   Brit… <NA>  McLa… 2413… <NA>  Urba… IA    50322    4  
#> 6 {C45E7… 2020-05-30 6429  Heavy High… CON   Tracy <NA>  Yans… 3001… <NA>  Bloo… MN    55425   20
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(iac, count_na)
#> # A tibble: 14 x 4
#>    col       class        n        p
#>    <chr>     <chr>    <int>    <dbl>
#>  1 tx        <chr>        0 0       
#>  2 date      <date>       0 0       
#>  3 code      <chr>        0 0       
#>  4 committee <chr>        0 0       
#>  5 type      <chr>        0 0       
#>  6 first     <chr>   234264 0.118   
#>  7 mi        <chr>  1699517 0.857   
#>  8 last      <chr>      280 0.000141
#>  9 addr1     <chr>     7979 0.00402 
#> 10 addr2     <chr>  1901620 0.959   
#> 11 city      <chr>     6663 0.00336 
#> 12 state     <chr>     2819 0.00142 
#> 13 zip       <chr>     1654 0.000834
#> 14 amount    <dbl>        0 0
```

We can flag any record missing a key variable needed to identify a
transaction.

``` r
key_vars <- c("date", "last", "amount", "committee")
iac <- flag_na(iac, all_of(key_vars))
sum(iac$na_flag)
#> [1] 280
```

All of the flagged rows are only missing a contributor `last` name.

``` r
iac %>% 
  filter(na_flag) %>% 
  select(all_of(key_vars)) %>% 
  sample_n(10)
#> # A tibble: 10 x 4
#>    date       last  amount committee                                    
#>    <date>     <chr>  <dbl> <chr>                                        
#>  1 2010-06-29 <NA>   20    Brenna Bird for County Attorney              
#>  2 2010-10-18 <NA>   10    Iowans For Miller                            
#>  3 2010-10-12 <NA>   20    Brenna Bird for County Attorney              
#>  4 2010-11-30 <NA>    0.98 Upmeyer for House                            
#>  5 2011-07-15 <NA>  100    Wayne County Democratic Central Committee    
#>  6 2006-05-03 <NA>   23    Fallon for Governor                          
#>  7 2004-07-28 <NA>   42    Clay County Republican Central Committee     
#>  8 2008-01-09 <NA>  199.   Clay County Democratic Central Committee     
#>  9 2004-10-22 <NA>   55    Clay County Democratic Central Committee     
#> 10 2011-06-06 <NA>  170    Van Buren County Republican Central Committee
```

``` r
iac %>% 
  filter(na_flag) %>% 
  select(all_of(key_vars)) %>% 
  col_stats(count_na)
#> # A tibble: 4 x 4
#>   col       class      n     p
#>   <chr>     <chr>  <int> <dbl>
#> 1 date      <date>     0     0
#> 2 last      <chr>    280     1
#> 3 amount    <dbl>      0     0
#> 4 committee <chr>      0     0
```

### Duplicates

We can create a file containing every duplicate record in the data.

``` r
dupe_file <- path(dirname(raw_dir), "dupes.csv")
if (!file_exists(dupe_file)) {
  write_lines("tx,dupe_flag", dupe_file)
  iac <- mutate(iac, group = str_sub(date, end = 7))
  ia_tx <- split(iac$tx, iac$group)
  ias <- iac %>%
    select(-tx) %>% 
    group_split(group, .keep = FALSE)
  pb <- txtProgressBar(max = length(ias), style = 3)
  for (i in seq_along(ias)) {
    write_csv(
      path = dupe_file,
      append = TRUE,
      x = tibble(
        tx = ia_tx[[i]],
        dupe_flag = or(
          duplicated(ias[[i]], fromLast = FALSE),
          duplicated(ias[[i]], fromLast = TRUE)
        )
      )
    )
    setTxtProgressBar(pb, i)
    ias[i] <- NA
    flush_memory(1)
  }
}
```

``` r
dupes <- read_csv(
  file = dupe_file,
  col_types = cols(
    tx = col_character(),
    dupe_flag = col_logical()
  )
)
```

This file can then be joined against the contributions using the
transaction ID.

``` r
iac <- left_join(iac, dupes)
iac <- mutate(iac, dupe_flag = !is.na(dupe_flag))
percent(mean(iac$dupe_flag), 0.1)
#> [1] "1.6%"
```

``` r
iac %>% 
  filter(dupe_flag) %>% 
  select(all_of(key_vars)) %>% 
  arrange(date, last)
#> # A tibble: 31,894 x 4
#>    date       last                amount committee                                     
#>    <date>     <chr>                <dbl> <chr>                                         
#>  1 2003-01-15 Iowa Health PAC        500 Iowa Democratic Party                         
#>  2 2003-01-15 Iowa Health PAC        500 Iowa Democratic Party                         
#>  3 2003-01-17 Pedersen                10 Black Hawk County Republican Central Committee
#>  4 2003-01-17 Pedersen                10 Black Hawk County Republican Central Committee
#>  5 2003-01-17 unidentified            20 Citizens for Excellence in Government         
#>  6 2003-01-17 unidentified            20 Citizens for Excellence in Government         
#>  7 2003-01-29 Smith                  100 Linn Phoenix Club                             
#>  8 2003-01-29 Smith                  100 Linn Phoenix Club                             
#>  9 2003-01-31 IDP Federal Account  10000 Iowa Democratic Party                         
#> 10 2003-01-31 IDP Federal Account  10000 Iowa Democratic Party                         
#> # … with 31,884 more rows
```

## Categorical

``` r
col_stats(iac, n_distinct)
#> # A tibble: 16 x 4
#>    col       class        n          p
#>    <chr>     <chr>    <int>      <dbl>
#>  1 tx        <chr>  1982775 1         
#>  2 date      <date>    6483 0.00327   
#>  3 code      <chr>     5110 0.00258   
#>  4 committee <chr>     5191 0.00262   
#>  5 type      <chr>        2 0.00000101
#>  6 first     <chr>    88094 0.0444    
#>  7 mi        <chr>       69 0.0000348 
#>  8 last      <chr>   133355 0.0673    
#>  9 addr1     <chr>   531705 0.268     
#> 10 addr2     <chr>     7560 0.00381   
#> 11 city      <chr>    18629 0.00940   
#> 12 state     <chr>       74 0.0000373 
#> 13 zip       <chr>    71787 0.0362    
#> 14 amount    <dbl>    35430 0.0179    
#> 15 na_flag   <lgl>        2 0.00000101
#> 16 dupe_flag <lgl>        2 0.00000101
```

    #> # A tibble: 2 x 3
    #>   type        n      p
    #>   <chr>   <int>  <dbl>
    #> 1 CON   1934948 0.976 
    #> 2 INK     47827 0.0241

## Amounts

``` r
summary(iac$amount)
#>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
#> -106521.5      15.0      40.0     321.1     100.0 1800000.0
mean(iac$amount <= 0)
#> [1] 0.0008876448
```

![](../plots/amount_histogram-1.png)<!-- -->

![](../plots/amount_comm_violin-1.png)<!-- -->

## Dates

``` r
iac <- mutate(iac, year = year(date))
```

``` r
iac %>% 
  count(year) %>% 
  mutate(even = is_even(year)) %>% 
  ggplot(aes(x = year, y = n)) +
  geom_col(aes(fill = even)) + 
  scale_fill_brewer(palette = "Dark2") +
  scale_y_continuous(labels = comma) +
  scale_x_continuous(breaks = seq(1998, 2020, by = 2)) +
  theme(legend.position = "bottom") +
  labs(
    title = "Iowa Contributions by Year",
    caption = "Source: Iowa Election Division",
    fill = "Election Year",
    x = "Year Made",
    y = "Count"
  )
```

![](../plots/year_bar-1.png)<!-- -->

## Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are taylor made to facilitate this process.

### Address

For the street `addresss` variable, the `campfin::normal_address()`
function will force consistence case, remove punctuation, and
abbreviation official USPS suffixes.

``` r
addr_norm <- iac %>%
  select(starts_with("addr")) %>% 
  distinct() %>% 
  unite(
    everything(),
    col = addr_full,
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    addr_norm = normal_address(
      address = addr_full,
      abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-addr_full)
```

``` r
iac <- left_join(iac, addr_norm)
rm(addr_norm)
```

We can see how this process improved consistency.

``` r
iac %>% 
  sample_n(10) %>% 
  select(starts_with("addr"))
#> # A tibble: 10 x 3
#>    addr1                 addr2 addr_norm         
#>    <chr>                 <chr> <chr>             
#>  1 708 Brookridge Ave    <NA>  708 BROOKRIDGE AVE
#>  2 722 NE 10TH ST        <NA>  722 NE 10 TH ST   
#>  3 19548 T AVE           <NA>  19548 T AVE       
#>  4 9713 Mariposa         <NA>  9713 MARIPOSA     
#>  5 609 W Council Dr      <NA>  609 W COUNCIL DR  
#>  6 5661 Fluer Dr         <NA>  5661 FLUER DR     
#>  7 2001 West 10th Street <NA>  2001 W 10 TH ST   
#>  8 307 OHIO AVENUE       <NA>  307 OHIO AVE      
#>  9 2128 262nd Ave        <NA>  2128 262 ND AVE   
#> 10 6919 Vista Drive      <NA>  6919 VIS DR
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valied *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
iac <- iac %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  iac$zip, 
  iac$zip_norm, 
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct  prop_na  n_out n_diff
#>   <chr>      <dbl>      <dbl>    <dbl>  <dbl>  <dbl>
#> 1 zip        0.853      71787 0.000834 290558  57630
#> 2 zip_norm   0.998      16820 0.0147     4697   1137
```

### State

Very little needs to be done to clean the `state` variable.

``` r
x <- iac$state
length(x)
#> [1] 1982775
prop_in(x, valid_state)
#> [1] 0.9999788
count_out(x, valid_state)
#> [1] 42
st_zip <- iac$zip %in% zipcodes$zip[zipcodes$state == "IA"]
st_out <- x %out% valid_state
st_rx <- str_detect(x, "^[Ii]|[Aa]$")
st_na <- !is.na(x)
# has ia zip, ia regex, not valid, not na
x[st_zip & st_rx & st_out & st_na] <- "IA"
length(x)
#> [1] 1982775
iac <- mutate(iac, state_norm = x)
```

``` r
progress_table(
  iac$state, 
  iac$state_norm, 
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage      prop_in n_distinct prop_na n_out n_diff
#>   <chr>        <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 state         1.00         74 0.00142    42     19
#> 2 state_norm    1.00         68 0.00142    32     13
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats. The
`campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
ia_city <- iac %>% 
  count(city, state_norm, zip_norm, sort = TRUE) %>% 
  select(-n) %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("IA", "DC", "IOWA"),
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

Again, we can further improve normalization by comparing our normalized
value against the *expected* value for that record’s state abbreviation
and ZIP code. If the normalized value is either an abbreviation for or
very similar to the expected value, we can confidently swap those two.

``` r
ia_city <- ia_city %>% 
  rename(city_raw = city) %>% 
  left_join(
    y = zipcodes,
    by = c(
      "state_norm" = "state",
      "zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(city_norm, city_match),
    match_dist = str_dist(city_norm, city_match),
    city_swap = if_else(
      condition = !is.na(city_match) & (match_abb | match_dist == 1),
      true = city_match,
      false = city_norm
    )
  ) %>% 
  select(
    -city_match,
    -match_dist,
    -match_abb
  )
```

``` r
many_city <- c(valid_city, extra_city)
ia_city %>% 
  count(city_swap, state_norm, sort = TRUE) %>% 
  filter(!is.na(city_swap), city_swap %out% many_city)
#> # A tibble: 1,545 x 3
#>    city_swap        state_norm     n
#>    <chr>            <chr>      <int>
#>  1 NEW YORK CITY    NY            27
#>  2 NYC              NY            20
#>  3 WASHINGTON D C   DC            17
#>  4 LECLAIRE         IA            15
#>  5 JOHNSTNON        IA            12
#>  6 UNITEMIZED       IA            10
#>  7 FARMINGTON HILLS MI             9
#>  8 IA               IA             8
#>  9 LEMARS           IA             8
#> 10 DESMOINES        IA             7
#> # … with 1,535 more rows
```

``` r
ia_city <- ia_city %>% 
  mutate(
    city_swap = city_swap %>% 
      str_replace("^OVERLAND PARKS$", "OVERLAND PARK") %>% 
      str_replace("^NEW YORK CITY$", "NEW YORK") %>% 
      str_replace("^NYC$", "NEW YORK") %>% 
      str_replace("^WASHINGTON D C$", "WASHINGTON") %>% 
      str_replace("\\sPK$", "PARK") %>% 
      str_remove("\\sD\\sC$") %>% 
      str_remove("\\sIN$") %>% 
      na_if("UNITEMIZED") %>% 
      na_if("IA")
  )
```

``` r
ia_city <- rename(ia_city, city = city_raw)
iac <- left_join(iac, ia_city, by = c("city", "state_norm", "zip_norm"))
```

| stage      | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :--------- | -------: | ----------: | -------: | -----: | ------: |
| city)      |    0.965 |       13652 |    0.003 |  68317 |    5829 |
| city\_norm |    0.986 |       12699 |    0.014 |  26413 |    4819 |
| city\_swap |    0.997 |        9391 |    0.015 |   5887 |    1501 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/progress_bar-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

``` r
progress %>% 
  select(
    stage, 
    all = n_distinct,
    bad = n_diff
  ) %>% 
  mutate(good = all - bad) %>% 
  pivot_longer(c("good", "bad")) %>% 
  mutate(name = name == "good") %>% 
  ggplot(aes(x = stage, y = value)) +
  geom_col(aes(fill = name)) +
  scale_fill_brewer(palette = "Dark2", direction = -1) +
  scale_y_continuous(labels = comma) +
  theme(legend.position = "bottom") +
  labs(
    title = "Iowa City Normalization Progress",
    subtitle = "Distinct values, valid and invalid",
    x = "Stage",
    y = "Percent Valid",
    fill = "Valid"
  )
```

![](../plots/distinct_bar-1.png)<!-- -->

## Conclude

Before exporting, we can remove the intermediary normalization columns
and rename all added variables with the `_clean` suffix.

``` r
iac <- iac %>% 
  select(
    -city_norm,
    city_clean = city_swap
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  rename_all(~str_remove(., "_raw"))
```

``` r
glimpse(sample_n(iac, 50))
#> Rows: 50
#> Columns: 21
#> $ tx          <chr> "{FE701D0F-179A-49C5-84A1-3671C85EF799}", "{84767F03-9A30-44AE-8B2E-524485E7…
#> $ date        <date> 2018-09-04, 2011-10-05, 2016-10-14, 2010-09-09, 2020-01-25, 2013-03-13, 201…
#> $ code        <chr> "2451", "6021", "1229", "5140", "6021", "6072", "1914", "2523", "6021", "236…
#> $ committee   <chr> "Westrich for Iowa", "Credit Union PAC", "Winckler for State House", "Govern…
#> $ type        <chr> "CON", "CON", "CON", "CON", "CON", "CON", "CON", "CON", "CON", "CON", "CON",…
#> $ first       <chr> "Mary Beth", "Beverly", NA, "Jane", "Liliane", "Paul", "Mike", "Jana", "Fern…
#> $ mi          <chr> NA, NA, NA, "B", NA, "C", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "A", N…
#> $ last        <chr> "Hammer", "Long", "Bridge Structural & Ornamental Ironworkers Local 111 PAC"…
#> $ addr1       <chr> "2357 Timberlane Hights", "431 Teakwood Lane N.E.", "8000 29th St, West", "P…
#> $ addr2       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ city        <chr> "Ottumwa", "Cedar Rapids", "Rock Island", "New Providence", "Palo", "Delmar"…
#> $ state       <chr> "IA", "IA", "IL", "IA", "IA", "IA", "IA", "CA", "IA", "IA", "IA", "IA", "NY"…
#> $ zip         <chr> "52501", "52402", "61201", "50206", "52324", "52037-9346", "52732", "90027",…
#> $ amount      <dbl> 20.00, 35.00, 250.00, 25.00, 0.50, 15.00, 100.00, 8.34, 10.00, 100.00, 200.0…
#> $ na_flag     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ dupe_flag   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ year        <dbl> 2018, 2011, 2016, 2010, 2020, 2013, 2010, 2020, 2014, 2017, 2006, 2016, 2014…
#> $ addr_clean  <chr> "2357 TIMBERLANE HIGHTS", "431 TEAKWOOD LN N E", "8000 29 TH ST W", "PO BOX …
#> $ zip_clean   <chr> "52501", "52402", "61201", "50206", "52324", "52037", "52732", "90027", "502…
#> $ state_clean <chr> "IA", "IA", "IL", "IA", "IA", "IA", "IA", "CA", "IA", "IA", "IA", "IA", "NY"…
#> $ city_clean  <chr> "OTTUMWA", "CEDAR RAPIDS", "ROCK ISLAND", "NEW PROVIDENCE", "PALO", "DELMAR"…
```

1.  There are 1,982,775 records in the database.
2.  There are 31,894 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 280 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("ia", "contribs", "data", "clean"))
clean_path <- path(clean_dir, "ia_contribs_clean.csv")
write_csv(iac, clean_path, na = "")
(clean_size <- file_size(clean_path))
#> 382M
file_encoding(clean_path) %>% 
  mutate(across(path, path.abbrev))
#> # A tibble: 1 x 3
#>   path                                           mime            charset 
#>   <chr>                                          <chr>           <chr>   
#> 1 ~/ia/contribs/data/clean/ia_contribs_clean.csv application/csv us-ascii
```

## Upload

We can use the `aws.s3::put_object()` to upload the text file to the IRW
server.

``` r
aws_path <- path("csv", basename(clean_path))
if (!object_exists(aws_path, "publicaccountability")) {
  put_object(
    file = clean_path,
    object = aws_path, 
    bucket = "publicaccountability",
    acl = "public-read",
    show_progress = TRUE,
    multipart = TRUE
  )
}
aws_head <- head_object(aws_path, "publicaccountability")
(aws_size <- as_fs_bytes(attr(aws_head, "content-length")))
#> 382M
unname(aws_size == clean_size)
#> [1] TRUE
```

## Dictionary

The following table describes the variables in our final exported file:

| Column        | Type        | Definition                             |
| :------------ | :---------- | :------------------------------------- |
| `tx`          | `character` | Unique transaction hash                |
| `date`        | `double`    | Date contribution was made             |
| `code`        | `character` | Recipient committee code               |
| `committee`   | `character` | Recipient committee name               |
| `type`        | `character` | Type of contribution (direct, in-kind) |
| `first`       | `character` | Contributor first name                 |
| `mi`          | `character` | Contributor middle initial             |
| `last`        | `character` | Contributor last name or organization  |
| `addr1`       | `character` | Contributor street address             |
| `addr2`       | `character` | Contributor secondary address          |
| `city`        | `character` | Contributor state abbreviation         |
| `state`       | `character` | Contributor city name                  |
| `zip`         | `character` | Contributor ZIP+4 code                 |
| `amount`      | `double`    | Amount or correction                   |
| `na_flag`     | `logical`   | Flag for missing value                 |
| `dupe_flag`   | `logical`   | Flag for duplicate row                 |
| `year`        | `double`    | Calendar year contribution made        |
| `addr_clean`  | `character` | Normalized street address              |
| `zip_clean`   | `character` | Normalized 5-digit ZIP code            |
| `state_clean` | `character` | Normalized 2-letter state abbreviation |
| `city_clean`  | `character` | Normalized city name                   |
