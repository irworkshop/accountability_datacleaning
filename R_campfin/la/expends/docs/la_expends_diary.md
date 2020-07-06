Louisiana Expenditures
================
Kiernan Nicholls
2020-07-02 14:30:41

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Download](#download)
  - [Read](#read)
  - [Explore](#explore)
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
  gluedown, # printing markdown
  magrittr, # pipe operators
  janitor, # clean data frames
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  rvest, # html scraping
  glue, # combine strings
  here, # relative paths
  httr, # http requests
  fs # local storage 
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
#> [1] "/home/kiernan/Code/accountability_datacleaning/R_campfin"
```

## Data

Expenditures records is from the [Louisiana Ethics
Administration’s](http://ethics.la.gov/AboutTheBoard.aspx):

> The mission of the Ethics Administration Program is to administer and
> to enforce Louisiana’s conflicts of interest legislation, campaign
> finance registration and reporting requirements and lobbyist
> registration and disclosure laws to achieve compliance by governmental
> officials, public employees, candidates, and lobbyists and to provide
> public access to disclosed information.

We can search expenditure records from the LEA’s expenditures search
portal:

>   - [Campaign Finance
>     Expenditures](http://www.ethics.la.gov/CampaignFinanceSearch/SearchEfilingExpenditures.aspx)  
>     Choose this option to sort and view campaign expense records.  
>     Expenditures may appear multiple times in the search.

## Download

We can search for expenditures between two dates, however the number of
results that can be returned at a time is 100,000.

> Due to the high volume of contribution receipts, these search results
> are limited to the top 100,000 of 1,285,753 records that match your
> search criteria and sorting selection.

To circumvent this cap, we perform multiple searches between the start
and end of the years between 2000 and 2020. The
[cURL](https://en.wikipedia.org/wiki/CURL) commands to download these
chunks are stored in the `raw_curl.sh` text file. We can run these
commands one by one and save the returned files locally.

``` r
raw_dir <- dir_create(here("la", "expends", "data", "raw"))
raw_path <- path(raw_dir, "la_exp_raw.csv")
raw_curl <- read_lines(here("la", "expends", "raw_curl.sh"))
```

``` r
for (i in seq_along(raw_curl)) {
  out_path <- path(raw_dir, glue("SearchResults-{seq(2000, 2020)[i]}.csv"))
  write_lines(system(raw_curl[i], intern = TRUE), out_path)
  flush_memory(); Sys.sleep(5)
}
```

``` r
raw_info <- dir_info(raw_dir)
nrow(raw_info)
#> [1] 27
sum(raw_info$size)
#> 250M
as_tibble(raw_info) %>% 
  select(path, size, modification_time) %>% 
  mutate(across(path, path.abbrev))
#> # A tibble: 27 x 3
#>    path                                                size modification_time  
#>    <chr>                                        <fs::bytes> <dttm>             
#>  1 ~/la/expends/data/raw/SearchResults-2000.csv       3.56M 2020-07-02 12:27:13
#>  2 ~/la/expends/data/raw/SearchResults-2001.csv       3.18M 2020-07-02 12:30:16
#>  3 ~/la/expends/data/raw/SearchResults-2002.csv       7.69M 2020-07-02 12:31:06
#>  4 ~/la/expends/data/raw/SearchResults-2003.csv      19.79M 2020-07-02 12:33:02
#>  5 ~/la/expends/data/raw/SearchResults-2004.csv       6.76M 2020-07-02 12:33:47
#>  6 ~/la/expends/data/raw/SearchResults-2005.csv       4.07M 2020-07-02 12:34:42
#>  7 ~/la/expends/data/raw/SearchResults-2006.csv       7.99M 2020-07-02 12:35:27
#>  8 ~/la/expends/data/raw/SearchResults-2007.csv      18.98M 2020-07-02 12:36:55
#>  9 ~/la/expends/data/raw/SearchResults-2008.csv        9.1M 2020-07-02 12:38:10
#> 10 ~/la/expends/data/raw/SearchResults-2009.csv      12.57M 2020-07-02 12:39:00
#> # … with 17 more rows
```

## Read

All of these yearly files can be read into a single data frame with
`vroom()`.

``` r
lae <- vroom(
  file = raw_info$path,
  escape_backslash = FALSE,
  escape_double = FALSE,
  trim_ws = TRUE,
  id = "file",
  num_threads = 1,
  .name_repair = make_clean_names,
  col_types = cols(
    .default = col_character(),
    ExpenditureDate = col_date_usa(),
    ExpenditureAmt = col_number()
  )
)
```

``` r
old_names <- names(lae)
lae <- lae %>% 
  mutate(across(file, path.abbrev)) %>% 
  mutate(across(where(is.character), str_squish)) %>% 
  rename_all(str_remove, "_name$") %>% 
  rename_all(str_remove, "^filer_") %>% 
  rename_all(str_remove, "^report_") %>% 
  rename_all(str_remove, "^recipient_") %>% 
  rename_all(str_remove, "^expenditure_") %>% 
  rename_all(str_remove, "^candidate_") %>% 
  rename(amount = amt)
```

## Explore

``` r
glimpse(lae)
#> Rows: 1,259,656
#> Columns: 17
#> $ file        <chr> "~/la/expends/data/raw/SearchResults-2000.csv", "~/la/expends/data/raw/Searc…
#> $ last        <chr> "ABC Pelican PAC", "ABC Pelican PAC", "ABC Pelican PAC", "ABC Pelican PAC", …
#> $ first       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ code        <chr> "F202", "F202", "F202", "F202", "F202", "F202", "F202", "F202", "F202", "F20…
#> $ type        <chr> "ANN", "ANN", "ANN", "ANN", "ANN", "ANN", "ANN", "ANN", "ANN", "ANN", "ANN",…
#> $ number      <chr> "LA-1860", "LA-1860", "LA-1860", "LA-1860", "LA-1860", "LA-1860", "LA-1860",…
#> $ schedule    <chr> "E-4", "E-4", "E-1", "E-1", "E-3", "E-3", "E-3", "E-3", "E-3", "E-4", "E-3",…
#> $ recipient   <chr> "IRS", "ABC PELICAN CHAPTER", "SPAULDING GROUP INC.", "LOUISIANA SENATE DEMO…
#> $ addr1       <chr> NA, "19251 Highland Road", NA, "P.O. Box 4385", "1995 Nonconnah Blvd.", NA, …
#> $ addr2       <chr> NA, NA, NA, NA, NA, NA, NA, "Suite 203", NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ city        <chr> "Memphis", "Baton Rouge", "Louisville", "Baton Rouge", "Memphis", NA, "Jeffe…
#> $ state       <chr> "TN", "LA", "KY", "LA", "TN", NA, "LA", "LA", "LA", "LA", "LA", "LA", "LA", …
#> $ zip         <chr> NA, "70809", NA, "70801-4385", "38132", NA, "70181", "70122", "71483", "7081…
#> $ description <chr> NA, "Administrative Fees for 2000", "Bush/Cheney Buttons Signs and Bumper St…
#> $ beneficiary <chr> NA, NA, NA, NA, "COMMITTEE TO ELECT PAUL STANLEY", "FRIENDS OF MIKE FUTRELL"…
#> $ date        <date> 2000-03-08, 2000-11-17, 2000-11-03, 2000-05-02, 2000-07-24, 2000-05-10, 200…
#> $ amount      <dbl> 2199.00, 2000.00, 515.00, 500.00, 500.00, 500.00, 500.00, 500.00, 500.00, 41…
tail(lae)
#> # A tibble: 6 x 17
#>   file  last  first code  type  number schedule recipient addr1 addr2 city  state zip   description
#>   <chr> <chr> <chr> <chr> <chr> <chr>  <chr>    <chr>     <chr> <chr> <chr> <chr> <chr> <chr>      
#> 1 ~/la… Zuck… Jason F102  30P   LA-88… E-1      ERIC MCV… 304 … <NA>  Mand… LA    70448 Campaign M…
#> 2 ~/la… Zuck… Jason F102  30P   LA-88… E-1      ERIC MCV… 304 … <NA>  Mand… LA    70448 Campaign M…
#> 3 ~/la… Zuck… Jason F102  30P   LA-88… E-1      COVINGTO… 2144… <NA>  Abit… LA    70420 Campaign S…
#> 4 ~/la… Zuck… Jason F102  10P   LA-88… E-1      BOURGEOI… 127 … <NA>  Covi… LA    70433 Marketing …
#> 5 ~/la… Zuck… Jason F102  30P   LA-88… E-1      MELE PRI… 619 … <NA>  Covi… LA    70433 Printing s…
#> 6 ~/la… Zuck… Jason F102  30P   LA-88… E-1      CAPLAND   3334… Suit… Meta… LA    70002 Hats with …
#> # … with 3 more variables: beneficiary <chr>, date <date>, amount <dbl>
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(lae, count_na)
#> # A tibble: 17 x 4
#>    col         class        n        p
#>    <chr>       <chr>    <int>    <dbl>
#>  1 file        <chr>        0 0       
#>  2 last        <chr>        0 0       
#>  3 first       <chr>   194386 0.154   
#>  4 code        <chr>        0 0       
#>  5 type        <chr>      131 0.000104
#>  6 number      <chr>        0 0       
#>  7 schedule    <chr>        0 0       
#>  8 recipient   <chr>      248 0.000197
#>  9 addr1       <chr>    60597 0.0481  
#> 10 addr2       <chr>  1172090 0.930   
#> 11 city        <chr>    32881 0.0261  
#> 12 state       <chr>    26564 0.0211  
#> 13 zip         <chr>    77644 0.0616  
#> 14 description <chr>   109365 0.0868  
#> 15 beneficiary <chr>  1186702 0.942   
#> 16 date        <date>       0 0       
#> 17 amount      <dbl>        0 0
```

We can flag any record missing a key variable like a name or date.

``` r
lae <- lae %>% flag_na(date, last, amount, recipient)
sum(lae$na_flag)
#> [1] 248
```

All such records are missing a beneficiary.

``` r
lae %>% 
  filter(na_flag) %>% 
  select(date, last, amount, recipient)
#> # A tibble: 248 x 4
#>    date       last                      amount recipient
#>    <date>     <chr>                      <dbl> <chr>    
#>  1 2002-04-22 Entergy Corp. PAC (ENPAC)  3000  <NA>     
#>  2 2003-12-29 Blanco                     1500  <NA>     
#>  3 2003-12-19 Blanco                     1473. <NA>     
#>  4 2003-12-27 Blanco                      647. <NA>     
#>  5 2003-12-26 Blanco                      579. <NA>     
#>  6 2003-12-26 Blanco                      297. <NA>     
#>  7 2003-12-26 Blanco                      279. <NA>     
#>  8 2003-12-31 Blanco                      185. <NA>     
#>  9 2003-01-08 Entergy Corp. PAC (ENPAC)   100  <NA>     
#> 10 2004-08-23 Blanco                    25000  <NA>     
#> # … with 238 more rows
```

``` r
lae %>% 
  filter(na_flag) %>% 
  select(date, last, amount, recipient) %>% 
  col_stats(count_na)
#> # A tibble: 4 x 4
#>   col       class      n     p
#>   <chr>     <chr>  <int> <dbl>
#> 1 date      <date>     0     0
#> 2 last      <chr>      0     0
#> 3 amount    <dbl>      0     0
#> 4 recipient <chr>    248     1
```

### Duplicates

We can flag any record that’s duplicated at least once across all
variables.

``` r
d1 <- duplicated(lae, fromLast = FALSE)
d2 <- duplicated(lae, fromLast = TRUE)
lae <- mutate(lae, dupe_flag = d1 | d2)
rm(d1, d2); flush_memory()
```

Over 1% of records are such duplicates

``` r
percent(mean(lae$dupe_flag), 0.01)
#> [1] "1.07%"
```

``` r
lae %>% 
  filter(dupe_flag) %>% 
  select(date, last, amount, recipient, number)
#> # A tibble: 13,459 x 5
#>    date       last         amount recipient           number 
#>    <date>     <chr>         <dbl> <chr>               <chr>  
#>  1 2000-11-07 Addison, Jr.    150 STERLING COLLINS    LA-1619
#>  2 2000-11-07 Addison, Jr.    150 STERLING COLLINS    LA-1619
#>  3 2000-11-07 Addison, Jr.     75 MR DON KELLY        LA-1619
#>  4 2000-11-07 Addison, Jr.     75 MR DON KELLY        LA-1619
#>  5 2000-11-07 Addison, Jr.     75 TAREN MACK          LA-1619
#>  6 2000-11-07 Addison, Jr.     75 TAREN MACK          LA-1619
#>  7 2000-11-07 Addison, Jr.     75 ASHLEY SPOTSVILLE   LA-1619
#>  8 2000-11-07 Addison, Jr.     75 ASHLEY SPOTSVILLE   LA-1619
#>  9 2000-11-07 Addison, Jr.     75 MR ALLEN S MERCHANT LA-1619
#> 10 2000-11-07 Addison, Jr.     75 MR ALLEN S MERCHANT LA-1619
#> # … with 13,449 more rows
```

### Categorical

``` r
col_stats(lae, n_distinct)
#> # A tibble: 19 x 4
#>    col         class       n          p
#>    <chr>       <chr>   <int>      <dbl>
#>  1 file        <chr>      27 0.0000214 
#>  2 last        <chr>    2967 0.00236   
#>  3 first       <chr>    2560 0.00203   
#>  4 code        <chr>      12 0.00000953
#>  5 type        <chr>      16 0.0000127 
#>  6 number      <chr>   44754 0.0355    
#>  7 schedule    <chr>      10 0.00000794
#>  8 recipient   <chr>  265395 0.211     
#>  9 addr1       <chr>  279295 0.222     
#> 10 addr2       <chr>   14644 0.0116    
#> 11 city        <chr>    8530 0.00677   
#> 12 state       <chr>      62 0.0000492 
#> 13 zip         <chr>   29321 0.0233    
#> 14 description <chr>  312103 0.248     
#> 15 beneficiary <chr>   14824 0.0118    
#> 16 date        <date>   7476 0.00593   
#> 17 amount      <dbl>  113178 0.0898    
#> 18 na_flag     <lgl>       2 0.00000159
#> 19 dupe_flag   <lgl>       2 0.00000159
```

![](../plots/distinct_plots-1.png)<!-- -->![](../plots/distinct_plots-2.png)<!-- -->![](../plots/distinct_plots-3.png)<!-- -->![](../plots/distinct_plots-4.png)<!-- -->

### Amounts

``` r
summary(lae$amount)
#>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
#>       0.0      60.6     110.3     848.8     427.8 2000000.0
mean(lae$amount <= 0)
#> [1] 0
```

![](../plots/hist_amount-1.png)<!-- -->

### Dates

We can add the calendar year from `date` with `lubridate::year()`

``` r
lae <- mutate(lae, year = year(date))
```

``` r
min(lae$date)
#> [1] "2000-01-01"
sum(lae$year < 2000)
#> [1] 0
max(lae$date)
#> [1] "2020-11-19"
sum(lae$date > today())
#> [1] 1
```

![](../plots/bar_year-1.png)<!-- -->

## Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are tailor made to facilitate this process.

### Address

For the street `addresss` variable, the `campfin::normal_address()`
function will force consistence case, remove punctuation, and abbreviate
official USPS suffixes.

``` r
lae <- lae %>% 
  unite(
    col = addr_full,
    starts_with("addr"),
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
lae %>% 
  select(contains("addr")) %>% 
  distinct() %>% 
  sample_n(10)
#> # A tibble: 10 x 3
#>    addr1                addr2       addr_norm           
#>    <chr>                <chr>       <chr>               
#>  1 408 Holy Cross Place <NA>        408 HOLY CROSS PLACE
#>  2 719-A South Burnside <NA>        719 A S BURNSIDE    
#>  3 2431 Rue Beauregard  <NA>        2431 RUE BEAUREGARD 
#>  4 912 Maine Street     <NA>        912 MAINE ST        
#>  5 4919 DESIRE DRIVE    <NA>        4919 DESIRE DR      
#>  6 PO BOX 1983          <NA>        PO BOX 1983         
#>  7 150 Melacon Drive    <NA>        150 MELACON DR      
#>  8 37321 Mindy Way      <NA>        37321 MINDY WAY     
#>  9 605 W St Mary Blvd   <NA>        605 W ST MARY BLVD  
#> 10 C/O                  PO BOX 3268 CO PO BOX 3268
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
lae <- lae %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  lae$zip,
  lae$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na  n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl>  <dbl>  <dbl>
#> 1 zip        0.895      29321  0.0616 124026  22541
#> 2 zip_norm   0.997       8249  0.0627   4108    900
```

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

``` r
lae <- lae %>% 
  mutate(
    state_norm = normal_state(
      state = state,
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = NULL
    )
  )
```

``` r
lae %>% 
  filter(state != state_norm) %>% 
  count(state, state_norm, sort = TRUE)
#> # A tibble: 0 x 3
#> # … with 3 variables: state <chr>, state_norm <chr>, n <int>
```

``` r
progress_table(
  lae$state,
  lae$state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage      prop_in n_distinct prop_na n_out n_diff
#>   <chr>        <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 state        0.997         62  0.0211  4191     10
#> 2 state_norm   1.00          59  0.0244     7      7
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
lae <- lae %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("LA", "DC", "LOUISIANA"),
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

#### Swap

We can further improve normalization by comparing our normalized value
against the *expected* value for that record’s state abbreviation and
ZIP code. If the normalized value is either an abbreviation for or very
similar to the expected value, we can confidently swap those two.

``` r
lae <- lae %>% 
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
      condition = !is.na(match_dist) & (match_abb | match_dist == 1),
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

#### Refine

The [OpenRefine](https://openrefine.org/) algorithms can be used to
group similar strings and replace the less common versions with their
most common counterpart. This can greatly reduce inconsistency, but with
low confidence; we will only keep any refined strings that have a valid
city/state/zip combination.

``` r
good_refine <- lae %>% 
  mutate(
    city_refine = city_swap %>% 
      key_collision_merge() %>% 
      n_gram_merge(numgram = 1)
  ) %>% 
  filter(city_refine != city_swap) %>% 
  inner_join(
    y = zipcodes,
    by = c(
      "city_refine" = "city",
      "state_norm" = "state",
      "zip_norm" = "zip"
    )
  )
```

    #> # A tibble: 104 x 5
    #>    state_norm zip_norm city_swap       city_refine       n
    #>    <chr>      <chr>    <chr>           <chr>         <int>
    #>  1 CA         94103    SAN FRANSICO    SAN FRANCISCO    22
    #>  2 OH         45202    CINCINATTI      CINCINNATI       22
    #>  3 LA         70068    LAPALCE         LA PLACE         18
    #>  4 LA         71110    BARKSDALE A F B BARKSDALE AFB    14
    #>  5 LA         71457    NACTITOCHES     NATCHITOCHES     12
    #>  6 LA         70001    METIAIRE        METAIRIE          8
    #>  7 LA         70119    NEW ORLEANSLA   NEW ORLEANS       8
    #>  8 OH         45274    CINCINATTI      CINCINNATI        8
    #>  9 LA         70390    NOPOLEANVILLE   NAPOLEONVILLE     6
    #> 10 CA         94102    SAN FRANSICO    SAN FRANCISCO     5
    #> # … with 94 more rows

Then we can join the refined values back to the database.

``` r
lae <- lae %>% 
  left_join(good_refine) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

| stage        | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :----------- | -------: | ----------: | -------: | -----: | ------: |
| city\_raw)   |    0.972 |        6437 |    0.026 |  34744 |    3290 |
| city\_norm   |    0.983 |        6084 |    0.027 |  21030 |    2911 |
| city\_swap   |    0.995 |        4382 |    0.027 |   6575 |    1210 |
| city\_refine |    0.995 |        4298 |    0.027 |   6294 |    1127 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/bar_progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar_distinct-1.png)<!-- -->

## Conclude

Before exporting, we can remove the intermediary normalization columns
and rename all added variables with the `_clean` suffix.

``` r
lae <- lae %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  rename_all(~str_remove(., "_raw"))
```

``` r
glimpse(sample_frac(lae))
#> Rows: 1,259,656
#> Columns: 24
#> $ file        <chr> "~/la/expends/data/raw/SearchResults-2016.csv", "~/la/expends/data/raw/Searc…
#> $ last        <chr> "LA Association of Wholesalers PAC", "Chabert", "LA Democrats (formerly Demo…
#> $ first       <chr> NA, "Norbert (Norby)", NA, "Candyce", "Joseph A.", "James", "Regina Ashford"…
#> $ code        <chr> "F202", "F102", "F202", "F102", "F102", "F102", "F102", "F102", "F102", "F10…
#> $ type        <chr> "ANN", "ANN", "40G", "40G", "ANN", "10P", "10P", "30P", "40G", "SUP", "EDAY"…
#> $ number      <chr> "LA-58981", "LA-48190", "LA-55643", "LA-68479", "LA-39561", "LA-31859", "LA-…
#> $ schedule    <chr> "E-3", "E-1", "E-1", "E-1", "E-1", "E-1", "E-1", "E-1", "E-1", "E-1", "B", "…
#> $ recipient   <chr> "JOSEPH BOUIE CAMPAIGN FUND", "LOUISIANA SMALL BUSINESS ASSOCIATION", "SHYAM…
#> $ addr1       <chr> "6305", "P.O. Box 44367", "714 N Mulberry St", "312 S Anderson", NA, "P.O. B…
#> $ addr2       <chr> "Elysian Fields Ave. Ste 400", NA, NA, NA, NA, NA, NA, NA, "Apt 102", NA, NA…
#> $ city        <chr> "New Orleans", "Baton Rouge", "Tallulah", "Washington", "Houma", "New Orlean…
#> $ state       <chr> "LA", "LA", "LA", "LA", "LA", "LA", "LA", "LA", "LA", "LA", "LA", "LA", "LA"…
#> $ zip         <chr> "70122", "70804", "71282-3330", "70589", "70360", "70181-1305", "70807", "70…
#> $ description <chr> "Oct 2019 Primary", "Directory", "Democratic Party Slate Card Distribution",…
#> $ beneficiary <chr> "JOSEPH BOUIE CAMPAIGN FUND", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ date        <date> 2016-03-13, 2014-01-24, 2015-11-21, 2017-04-29, 2013-12-12, 2011-09-26, 201…
#> $ amount      <dbl> 1000.00, 7.63, 100.00, 100.00, 49.18, 1457.64, 25.00, 50.00, 720.00, 119.97,…
#> $ na_flag     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ dupe_flag   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ year        <dbl> 2016, 2014, 2015, 2017, 2013, 2011, 2015, 2011, 2017, 2004, 2019, 2017, 2011…
#> $ addr_clean  <chr> "6305 ELYSIAN FLDS AVE STE 400", "PO BOX 44367", "714 N MULBERRY ST", "312 S…
#> $ zip_clean   <chr> "70122", "70804", "71282", "70589", "70360", "70181", "70807", "70528", "701…
#> $ state_clean <chr> "LA", "LA", "LA", "LA", "LA", "LA", "LA", "LA", "LA", "LA", "LA", "LA", "LA"…
#> $ city_clean  <chr> "NEW ORLEANS", "BATON ROUGE", "TALLULAH", "WASHINGTON", "HOUMA", "NEW ORLEAN…
```

1.  There are 1,259,656 records in the database.
2.  There are 13,459 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 248 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("la", "expends", "data", "clean"))
clean_path <- path(clean_dir, "la_expends_clean.csv")
write_csv(lae, clean_path, na = "")
file_size(clean_path)
#> 282M
file_encoding(clean_path) %>% 
  mutate(across(path, path.abbrev))
#> # A tibble: 1 x 3
#>   path                                         mime            charset 
#>   <chr>                                        <chr>           <chr>   
#> 1 ~/la/expends/data/clean/la_expends_clean.csv application/csv us-ascii
```

## Upload

Using the [duckr](https://github.com/kiernann/duckr) R package, we can
wrap around the [duck](https://duck.sh/) command line tool to upload the
file to the IRW server.

``` r
# remotes::install_github("kiernann/duckr")
s3_dir <- "s3:/publicaccountability/csv/"
s3_path <- path(s3_dir, basename(clean_path))
if (require(duckr)) {
  duckr::duck_upload(clean_path, s3_path)
}
```

## Dictionary

The following table describes the variables in our final exported file:

| Column        | Original name             | Type        | Definition                             |
| :------------ | :------------------------ | :---------- | :------------------------------------- |
| `file`        | `file`                    | `character` | Source file path                       |
| `last`        | `filer_last_name`         | `character` | Spending candidate last name           |
| `first`       | `filer_first_name`        | `character` | Spending candidate first name          |
| `code`        | `report_code`             | `character` | Expenditure code                       |
| `type`        | `report_type`             | `character` | Expenditure type                       |
| `number`      | `report_number`           | `character` | Expenditure number                     |
| `schedule`    | `schedule`                | `character` | Schedule reported on                   |
| `recipient`   | `recipient_name`          | `character` | Recipient vendor name                  |
| `addr1`       | `recipient_addr1`         | `character` | Recipient street address               |
| `addr2`       | `recipient_addr2`         | `character` | Recipient secondary address            |
| `city`        | `recipient_city`          | `character` | Recipient city name                    |
| `state`       | `recipient_state`         | `character` | Recipient state abbreviation           |
| `zip`         | `recipient_zip`           | `character` | Recipient ZIP+4 code                   |
| `description` | `expenditure_description` | `character` | Expenditure description                |
| `beneficiary` | `candidate_beneficiary`   | `character` | Expenditure other beneficiary name     |
| `date`        | `expenditure_date`        | `double`    | Date contribution was made             |
| `amount`      | `expenditure_amt`         | `double`    | Contribution amount or correction      |
| `na_flag`     |                           | `logical`   | Flag for missing date, amount, or name |
| `dupe_flag`   |                           | `logical`   | Flag for completely duplicated record  |
| `year`        |                           | `double`    | Calendar year of contribution date     |
| `addr_clean`  |                           | `character` | Normalized combined street address     |
| `zip_clean`   |                           | `character` | Normalized 5-digit ZIP code            |
| `state_clean` |                           | `character` | Normalized 2-digit state abbreviation  |
| `city_clean`  |                           | `character` | Normalized city name                   |
