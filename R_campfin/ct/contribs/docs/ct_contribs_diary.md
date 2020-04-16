Connecticut Contributions
================
Kiernna Nicholls
2020-04-16 16:07:02

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
  - [Conclude](#conclude)
  - [Export](#export)

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
  magrittr, # pipe operators
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
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
#> [1] "/home/kiernan/Code/accountability_datacleaning/R_campfin"
```

## Data

## Import

### Download

``` r
raw_dir <- dir_create(here("ct", "contribs", "data", "raw"))
seec <- "http://seec.ct.gov/ecrisreporting/Data/eCrisDownloads/exportdatafiles/"
raw_names <- glue("Receipts{2008:2020}CalendarYearPartyPACCommittees.CSV")
raw_urls <- str_c(seec, raw_names)
raw_paths <- path(raw_dir, raw_names)
if (!all(this_file_new(raw_paths))) {
  download.file(raw_urls, raw_paths)
}
```

### Read

``` r
ctc <- map_dfr(
  .x = raw_paths,
  .f = vroom,
  delim = ",",
  .name_repair = make_clean_names,
  na = c("", "NA", "N/A", "NULL"),
  escape_backslash = FALSE,
  escape_double = FALSE,
  col_types = cols(
    .default = col_character(),
    Amount = col_double(),
    `Transaction Date` = col_date_usa(),
    `File To State` = col_date_usa(),
    `Period Start` = col_date_usa(),
    `Period End` = col_date_usa(),
  )
)
```

## Explore

``` r
head(ctc)
#> # A tibble: 6 x 35
#>   committee contributor district office employer rec_type fil_type date       filed      amount
#>   <chr>     <chr>       <chr>    <chr>  <chr>    <chr>    <chr>    <date>     <date>      <dbl>
#> 1 12Th Dis… <NA>        <NA>     <NA>   <NA>     Total C… Politic… NA         2008-10-28    850
#> 2 12Th Dis… Peter R Su… <NA>     <NA>   Freedom… Itemize… Politic… 2008-10-01 2008-10-28    250
#> 3 12Th Dis… Marijean M… <NA>     <NA>   State O… Itemize… Politic… 2008-10-01 2008-10-28    250
#> 4 12Th Dis… Danita Sul… <NA>     <NA>   Mulberr… Itemize… Politic… 2008-10-01 2008-10-28     50
#> 5 12Th Dis… Jim Sulick  <NA>     <NA>   Self Em… Itemize… Politic… 2008-10-01 2008-10-28    250
#> 6 12Th Dis… Dawn Babin… <NA>     <NA>   Law Off… Itemize… Politic… 2008-10-01 2008-10-28     50
#> # … with 25 more variables: receipt <chr>, occupation <chr>, election_year <chr>,
#> #   contract_exec <chr>, contract_leg <chr>, contractor <chr>, lobbyist <chr>, source <chr>,
#> #   refiled <chr>, city <chr>, state <chr>, address <chr>, zip <chr>, event <chr>, report <chr>,
#> #   fil_id <chr>, sec_letter <chr>, sec_name <chr>, period_start <date>, period_end <date>,
#> #   first <chr>, middle <chr>, last <chr>, report_id <chr>, method <chr>
tail(ctc)
#> # A tibble: 6 x 35
#>   committee contributor district office employer rec_type fil_type date       filed      amount
#>   <chr>     <chr>       <chr>    <chr>  <chr>    <chr>    <chr>    <date>     <date>      <dbl>
#> 1 House Re… CT Assoc. … <NA>     <NA>   <NA>     Contrib… Politic… 2020-01-03 2020-01-07   2000
#> 2 House Re… George Col… <NA>     <NA>   Retired  Itemize… Politic… 2020-01-05 2020-01-07     75
#> 3 House Re… Dori Wollen <NA>     <NA>   Retired  Itemize… Politic… 2020-01-05 2020-01-07     20
#> 4 House Re… Roger Sayl… <NA>     <NA>   Church … Itemize… Politic… 2020-01-05 2020-01-07    350
#> 5 Windham … SEIU Conne… <NA>     <NA>   <NA>     Contrib… Party C… 2020-01-03 2020-01-07    500
#> 6 Windham … Connecticu… <NA>     <NA>   <NA>     Contrib… Party C… 2020-01-03 2020-01-07    125
#> # … with 25 more variables: receipt <chr>, occupation <chr>, election_year <chr>,
#> #   contract_exec <chr>, contract_leg <chr>, contractor <chr>, lobbyist <chr>, source <chr>,
#> #   refiled <chr>, city <chr>, state <chr>, address <chr>, zip <chr>, event <chr>, report <chr>,
#> #   fil_id <chr>, sec_letter <chr>, sec_name <chr>, period_start <date>, period_end <date>,
#> #   first <chr>, middle <chr>, last <chr>, report_id <chr>, method <chr>
glimpse(sample_n(ctc, 20))
#> Rows: 20
#> Columns: 35
#> $ committee     <chr> "Willow Cedar PAC", "House Republican Campaign Committee", "House Republic…
#> $ contributor   <chr> "Jose Velez", "Alan E Gilbert", "PETER CRUMBINE", "PAUL A BATES", "Edward …
#> $ district      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ office        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ employer      <chr> "City of Waterbury", "Amherst Securities", "TOWN OF GREENWICH", "NEW RIVER…
#> $ rec_type      <chr> "Itemized Contributions from Individuals", "Itemized Contributions from In…
#> $ fil_type      <chr> "Political Action Committee", "Political Action Committee", "Political Act…
#> $ date          <date> 2010-04-08, 2008-08-08, 2012-09-20, NA, 2016-08-15, 2018-10-20, NA, NA, 2…
#> $ filed         <date> 2010-07-02, 2008-10-10, 2012-10-10, 2009-01-12, 2016-10-11, 2018-10-30, 2…
#> $ amount        <dbl> 2.00, 1000.00, 76.00, 26.02, 125.00, 100.00, 15.00, 48.00, 20.00, 60.00, 1…
#> $ receipt       <chr> "Original", "Original", "Original", "Original", "Original", "Original", "O…
#> $ occupation    <chr> "Fire Fighter", "Investment", "SELECTMAN", "JOURNEYMAN TECHNICIAN", "na", …
#> $ election_year <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "2008", NA, NA, NA…
#> $ contract_exec <chr> NA, "NO", NA, "NO", NA, NA, "NO", "NO", NA, NA, NA, NA, NA, NA, NA, "NO", …
#> $ contract_leg  <chr> NA, "NO", NA, "NO", NA, NA, "NO", "NO", NA, NA, NA, NA, NA, NA, NA, "NO", …
#> $ contractor    <chr> "NO", NA, "NO", NA, "NO", "NO", NA, NA, "NO", "NO", "NO", "NO", NA, "NO", …
#> $ lobbyist      <chr> "NO", "NO", "NO", NA, "NO", "NO", NA, NA, "NO", "NO", "NO", "NO", NA, "NO"…
#> $ source        <chr> "eFILE", "Data Entry", "eFILE", "Data Entry", "eFILE", "eFILE", "Data Entr…
#> $ refiled       <chr> "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "N…
#> $ city          <chr> "Wolcott", "GREENWICH", "Greenwich", "COLCHESTER", "Madison", "Putnam", "N…
#> $ state         <chr> "CT", "CT", "CT", "CT", "CT", "CT", "CT", "CT", "CT", "CT", "CT", "CT", "C…
#> $ address       <chr> "79 Harrison Rd", NA, "3 Copper Beech Rd", NA, "81 Flintlock Rd", "116 Woo…
#> $ zip           <chr> "06716-", NA, "06830-", NA, "06443-", "06260-", "06511", "06010", "06770-"…
#> $ event         <chr> NA, NA, NA, NA, "09102016A", "10202018A", NA, NA, NA, "06042015A", NA, NA,…
#> $ report        <chr> NA, NA, NA, NA, "October 10 Filing", "7th Day Preceding General Election",…
#> $ fil_id        <chr> NA, NA, NA, NA, "2062", "2147", NA, NA, "957", "2203", NA, "4503", NA, "19…
#> $ sec_letter    <chr> NA, NA, NA, NA, "B", "B", NA, NA, "B", "B", NA, "B", NA, "M", NA, NA, "B",…
#> $ sec_name      <chr> NA, NA, NA, NA, "Itemized Contributions from Individuals", "Itemized Contr…
#> $ period_start  <date> NA, NA, NA, NA, 2016-07-01, 2018-10-01, NA, NA, 2016-07-01, 2015-04-01, N…
#> $ period_end    <date> NA, NA, NA, NA, 2016-09-30, 2018-10-28, NA, NA, 2016-09-30, 2015-06-30, N…
#> $ first         <chr> NA, NA, NA, NA, "Edward", "Connor", NA, NA, "Ingrid", "Steven", NA, "Alber…
#> $ middle        <chr> NA, NA, NA, NA, "H", NA, NA, NA, "S", "L", NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ last          <chr> NA, NA, NA, NA, "Raff", "Duffy", NA, NA, "June", "Wakefield", NA, "Barnes"…
#> $ report_id     <chr> NA, NA, NA, NA, "E40090", "E63604", NA, NA, "E39616", "E34151", NA, "E5200…
#> $ method        <chr> NA, NA, NA, NA, "Personal Check", "Cash", NA, NA, "Payroll Deduction", NA,…
```

### Missing

While most of the files from 2008 to 2020 share the same \~20 columns,
some of the more recent files have an additional \~10 columns. Those
files will contribute empty columns for rows from the earlier files.

``` r
col_stats(ctc, count_na)
#> # A tibble: 35 x 4
#>    col           class       n         p
#>    <chr>         <chr>   <int>     <dbl>
#>  1 committee     <chr>       0 0        
#>  2 contributor   <chr>    9616 0.0200   
#>  3 district      <chr>  480483 1        
#>  4 office        <chr>  480483 1        
#>  5 employer      <chr>  194701 0.405    
#>  6 rec_type      <chr>       0 0        
#>  7 fil_type      <chr>       0 0        
#>  8 date          <date>  47347 0.0985   
#>  9 filed         <date>      0 0        
#> 10 amount        <dbl>     782 0.00163  
#> 11 receipt       <chr>      31 0.0000645
#> 12 occupation    <chr>  188429 0.392    
#> 13 election_year <chr>  451290 0.939    
#> 14 contract_exec <chr>  344898 0.718    
#> 15 contract_leg  <chr>  344940 0.718    
#> 16 contractor    <chr>  113992 0.237    
#> 17 lobbyist      <chr>   95003 0.198    
#> 18 source        <chr>       0 0        
#> 19 refiled       <chr>       0 0        
#> 20 city          <chr>   11716 0.0244   
#> 21 state         <chr>   12789 0.0266   
#> 22 address       <chr>   79938 0.166    
#> 23 zip           <chr>   83159 0.173    
#> 24 event         <chr>  305869 0.637    
#> 25 report        <chr>  237038 0.493    
#> 26 fil_id        <chr>  237038 0.493    
#> 27 sec_letter    <chr>  237038 0.493    
#> 28 sec_name      <chr>  237038 0.493    
#> 29 period_start  <date> 237462 0.494    
#> 30 period_end    <date> 237462 0.494    
#> 31 first         <chr>  266672 0.555    
#> 32 middle        <chr>  413506 0.861    
#> 33 last          <chr>  266003 0.554    
#> 34 report_id     <chr>  237038 0.493    
#> 35 method        <chr>  336857 0.701
```

We know the variables like `first` and `last` exist for only the more
recent files but simply repeat the information from `contributor`.

Even from the main variables, quite a few are missing values.

``` r
ctc <- ctc %>% flag_na(date, contributor, amount, committee)
percent(mean(ctc$na_flag), 0.1)
#> [1] "11.8%"
```

### Duplicates

``` r
ctc <- flag_dupes(ctc, everything())
percent(mean(ctc$dupe_flag), 0.1)
#> [1] "1.0%"
```

``` r
ctc %>% 
  filter(dupe_flag) %>% 
  select(date, contributor, amount, committee)
#> # A tibble: 4,889 x 4
#>    date       contributor     amount committee                       
#>    <date>     <chr>            <dbl> <chr>                           
#>  1 2008-12-05 Holly S Martin     3   AT & T Connecticut Employees PAC
#>  2 2008-12-05 Holly S Martin     3   AT & T Connecticut Employees PAC
#>  3 2008-11-05 Ralph E Nied       2.5 AT & T Connecticut Employees PAC
#>  4 2008-11-05 Ralph E Nied       2.5 AT & T Connecticut Employees PAC
#>  5 2008-05-20 MICHELE MACAUDA   21   AT & T Connecticut Employees PAC
#>  6 2008-05-20 MICHELE MACAUDA   21   AT & T Connecticut Employees PAC
#>  7 2008-05-05 MARK J SCHAIRER   10   AT & T Connecticut Employees PAC
#>  8 2008-05-05 MARK J SCHAIRER   10   AT & T Connecticut Employees PAC
#>  9 NA         <NA>            7613   AT & T Connecticut Employees PAC
#> 10 NA         <NA>            7613   AT & T Connecticut Employees PAC
#> # … with 4,879 more rows
```

### Continuous

#### Amounts

``` r
summary(ctc$amount)
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max.     NA's 
#>  -1000.0     20.0     50.0    144.6    100.0 275000.0      782
mean(ctc$amount <= 0, na.rm = TRUE)
#> [1] 0.002307687
```

![](../plots/hist_amount-1.png)<!-- -->

#### Dates

``` r
ctc <- ctc %>% 
  mutate(
    date = date %>% 
      as.character() %>% 
      str_replace("^2(\\d{2}-)", "20\\1") %>% 
      str_replace("^(1)(?=\\d{3}-)", "2") %>% 
      as.Date(),
    year = year(date)
  )
```

``` r
min(ctc$date, na.rm = TRUE)
#> [1] "2001-01-16"
sum(ctc$year < 2000, na.rm = TRUE)
#> [1] 0
max(ctc$date, na.rm = TRUE)
#> [1] "2465-03-09"
sum(ctc$date > today(), na.rm = TRUE)
#> [1] 1
ctc$year[which(ctc$year > 2020)] <- NA
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
ctc <- ctc %>%
  mutate(
    address_norm = normal_address(
      address = address,
      abbs = usps_street,
      na_rep = TRUE
    )
  )
```

``` r
ctc %>% 
  select(contains("address")) %>% 
  distinct() %>% 
  sample_n(10)
#> # A tibble: 10 x 2
#>    address               address_norm       
#>    <chr>                 <chr>              
#>  1 130 N Riverside Ave . 130 N RIVERSIDE AVE
#>  2 27 W Point Ter        27 W PT TER        
#>  3 35 Fawn Ridge Dr      35 FAWN RDG DR     
#>  4 166 Grindle Brook Rd  166 GRINDLE BRK RD 
#>  5 4 Deepdene Rd         4 DEEPDENE RD      
#>  6 39 Tomlinson Ave      39 TOMLINSON AVE   
#>  7 70 Trout Stream Dr    70 TROUT STRM DR   
#>  8 7 SHULTAS PL          7 SHULTAS PL       
#>  9 296 Timrod Road       296 TIMROD RD      
#> 10 35 Quail Run          35 QUAIL RUN
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
ctc <- ctc %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  ctc$zip,
  ctc$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na  n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl>  <dbl>  <dbl>
#> 1 zip        0.215      12260   0.173 311932  10597
#> 2 zip_norm   0.997       4098   0.207   1126    414
```

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

``` r
ctc <- ctc %>% 
  mutate(
    state_norm = normal_state(
      state = state,
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = valid_state
    )
  )
```

``` r
ctc %>% 
  filter(state != state_norm) %>% 
  count(state, state_norm, sort = TRUE)
#> # A tibble: 25 x 3
#>    state state_norm     n
#>    <chr> <chr>      <int>
#>  1 Ct    CT          4584
#>  2 ct    CT           747
#>  3 CT.   CT            72
#>  4 cT    CT            36
#>  5 ny    NY            18
#>  6 Va    VA            18
#>  7 nc    NC            16
#>  8 Fl    FL             5
#>  9 nj    NJ             5
#> 10 CT5   CT             4
#> # … with 15 more rows
```

``` r
progress_table(
  ctc$state,
  ctc$state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage      prop_in n_distinct prop_na n_out n_diff
#>   <chr>        <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 state        0.988        167  0.0266  5671    113
#> 2 state_norm   1             54  0.0269     0      1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
ctc <- ctc %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("CT", "DC", "CONNECTICUT"),
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
ctc <- ctc %>% 
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

The \[OpenRefine\] algorithms can be used to group similar strings and
replace the less common versions with their most common counterpart.
This can greatly reduce inconsistency, but with low confidence; we will
only keep any refined strings that have a valid city/state/zip
combination.

``` r
good_refine <- ctc %>% 
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

    #> # A tibble: 13 x 5
    #>    state_norm zip_norm city_swap             city_refine             n
    #>    <chr>      <chr>    <chr>                 <chr>               <int>
    #>  1 CT         06896    REDDING RIDGE         REDDING                13
    #>  2 MA         01073    SOUTH HAMPTON         SOUTHAMPTON             8
    #>  3 CT         06037    KENGINSTON            KENSINGTON              1
    #>  4 CT         06052    NEW BARITAN           NEW BRITAIN             1
    #>  5 CT         06109    WETHERSIFLED          WETHERSFIELD            1
    #>  6 CT         06255    NORTH GROS VERNONDALE NORTH GROSVENORDALE     1
    #>  7 CT         06419    H KILLINGWORTH        KILLINGWORTH            1
    #>  8 CT         06489    SOUTHINTONG           SOUTHINGTON             1
    #>  9 CT         06515    NENEW HAVEN           NEW HAVEN               1
    #> 10 CT         06614    STAFFORD              STRATFORD               1
    #> 11 FL         32082    PONTE VERDE BEACH     PONTE VEDRA BEACH       1
    #> 12 MA         01061    NORTH HAMPTON         NORTHAMPTON             1
    #> 13 MA         01566    STURBRIDGE RD         STURBRIDGE              1

Then we can join the refined values back to the database.

``` r
ctc <- ctc %>% 
  left_join(good_refine) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

| stage      | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :--------- | -------: | ----------: | -------: | -----: | ------: |
| city\_raw) |    0.989 |        3493 |    0.024 |   5112 |    1160 |
| city\_norm |    0.992 |        3335 |    0.025 |   3864 |     984 |
| city\_swap |    0.996 |        2920 |    0.025 |   1947 |     538 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/bar_progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar_distinct-1.png)<!-- -->

## Conclude

``` r
ctc <- ctc %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean"))
```

``` r
glimpse(sample_n(ctc, 20))
#> Rows: 20
#> Columns: 42
#> $ committee     <chr> "Communication Workers Of America Local 1298", "North Haven Democratic Tow…
#> $ contributor   <chr> "Tashamakia E Hall", "Daniel P FLEMING", "Louis Golden", "LAWRENCE LUNDEN"…
#> $ district      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ office        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ employer      <chr> "Frontier", NA, "JA of SW New England", NA, "reitred", "Levin, Powers & Br…
#> $ rec_type      <chr> "Itemized Contributions from Individuals", "Itemized Contributions from In…
#> $ fil_type      <chr> "Political Action Committee", "Party Committee", "Political Action Committ…
#> $ date          <date> 2016-10-03, 2011-05-13, 2012-12-06, NA, 2017-09-15, 2015-11-20, 2019-04-1…
#> $ filed         <date> 2016-11-01, 2011-07-10, 2013-01-10, 2011-01-07, 2017-10-01, 2016-01-05, 2…
#> $ amount        <dbl> 10.00, 50.00, 100.00, 200.00, 80.00, 100.00, 70.00, 3.00, 35.00, 7500.00, …
#> $ receipt       <chr> "Original", "Original", "Original", "Original", "Original", "Original", "O…
#> $ occupation    <chr> NA, NA, "Executive", NA, "retired", "lobbyist", "Real Estate Broker", "TEC…
#> $ election_year <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "2017", NA, NA…
#> $ contract_exec <chr> NA, NA, NA, "NO", NA, NA, NA, NA, NA, NA, NA, "NO", NA, "NO", "NO", NA, NA…
#> $ contract_leg  <chr> NA, NA, NA, "NO", NA, NA, NA, NA, NA, NA, NA, "NO", NA, "NO", "NO", NA, NA…
#> $ contractor    <chr> "NO", "NO", "NO", NA, "NO", "NO", "NO", "NO", "NO", NA, "NO", "NO", "NO", …
#> $ lobbyist      <chr> "NO", "NO", "NO", "NO", "NO", "YES", "NO", "NO", "NO", NA, "NO", "NO", "NO…
#> $ source        <chr> "eFILE", "eFILE", "eFILE", "Data Entry", "eFILE", "eFILE", "eFILE", "eFILE…
#> $ refiled       <chr> "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "N…
#> $ city_raw      <chr> "Derby", "North Haven", "West Hartford", "WEST HARTFORD", "Madison", "New …
#> $ state         <chr> "CT", "CT", "CT", "CT", "CT", "CT", "CT", "CT", "CT", "CT", "CT", NA, "CT"…
#> $ address       <chr> "11 Emmett Ave", "107 Pool Rd", "295 N Quaker Ln", "65 W Beacon Apt B5", "…
#> $ zip           <chr> "06418-", "06473-", "06119-", "06119", "06443-", "06320-", "06824-6713", "…
#> $ event         <chr> NA, NA, "12062012A", NA, NA, "11182015a", "04112019A", NA, NA, NA, "060520…
#> $ report        <chr> "7th Day Preceding General Election", NA, NA, NA, "October 10 Filing", "Ja…
#> $ fil_id        <chr> "957", NA, NA, NA, "3457", "9361", "12161", "4871", NA, "2333", NA, NA, NA…
#> $ sec_letter    <chr> "B", NA, NA, NA, "B", "B", "B", "B", NA, "C1", NA, NA, NA, NA, "B", "B", N…
#> $ sec_name      <chr> "Itemized Contributions from Individuals", NA, NA, NA, "Itemized Contribut…
#> $ period_start  <date> 2016-10-01, NA, NA, NA, 2017-07-01, 2015-10-01, 2019-04-01, 2018-08-06, N…
#> $ period_end    <date> 2016-10-30, NA, NA, NA, 2017-09-30, 2015-12-31, 2019-06-30, 2018-09-30, N…
#> $ first         <chr> "Tashamakia", NA, NA, NA, "Peter", "Jay", "Nancy", "FRANK", NA, NA, NA, NA…
#> $ middle        <chr> "E", NA, NA, NA, NA, "B", NA, "G", NA, NA, NA, NA, NA, NA, "G", NA, NA, NA…
#> $ last          <chr> "Hall", NA, NA, NA, "Parisi", "Levin", "Freedman", "OVERLOCK", NA, NA, NA,…
#> $ report_id     <chr> "E43462", NA, NA, NA, "E51071", "E35314", "E69428", "E60778", NA, "E29801"…
#> $ method        <chr> "Payroll Deduction", NA, NA, NA, "Personal Check", NA, "Credit/Debit Card"…
#> $ na_flag       <lgl> FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
#> $ dupe_flag     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ year          <dbl> 2016, 2011, 2012, NA, 2017, 2015, 2019, 2018, 2013, 2014, 2010, 2008, 2011…
#> $ address_clean <chr> "11 EMMETT AVE", "107 POOL RD", "295 N QUAKER LN", "65 W BEACON APT B 5", …
#> $ zip_clean     <chr> "06418", "06473", "06119", "06119", "06443", "06320", "06824", "06770", "0…
#> $ state_clean   <chr> "CT", "CT", "CT", "CT", "CT", "CT", "CT", "CT", "CT", "CT", "CT", NA, "CT"…
#> $ city_clean    <chr> "DERBY", "NORTH HAVEN", "WEST HARTFORD", "WEST HARTFORD", "MADISON", "NEW …
```

1.  There are 480,483 records in the database.
2.  There are 4,889 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 56,497 records missing ….
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
clean_dir <- dir_create(here("ct", "contribs", "data", "clean"))
clean_path <- path(clean_dir, "ct_contribs_clean.csv")
write_csv(ctc, clean_path, na = "")
file_size(clean_path)
#> 152M
guess_encoding(clean_path)
#> # A tibble: 1 x 2
#>   encoding confidence
#>   <chr>         <dbl>
#> 1 ASCII             1
```
