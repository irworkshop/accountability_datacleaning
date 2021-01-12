New Mexico Contributions
================
Kiernan Nicholls
2020-02-18 16:02:04

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)

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

Data is obtained from the [New Mexico Campaign Finance Information
System](https://www.cfis.state.nm.us/).

From the \[CFIS data download page\]\[dl\], we can download transaction
reports from candidates, PACs, and lobbyists.

## Import

The three types of files can be downloaded separately and read into a
single data frame for processing.

### Download

``` r
raw_dir <- dir_create(here("nm", "contribs", "data", "raw"))
```

``` r
# not working without cookie params
# download manually to raw dir for now
for (type in c("Candidates", "PACs", "Lobbyists")) {
  httr::GET(
    url = "https://www.cfis.state.nm.us/media/CFIS_Data_Download.aspx",
    write_disk(path = path(raw_dir, paste0(type, ".csv")))
    query = list(
      ddlCSVSelect = "Transactions",
      ddlRegisrationYear = "0",
      ddlViewBy = type,
      hfFilePeriodFilter = "ALL",
      ddlLookFor = type,
      ddlFilePeriodYear = "0",
      ddlFPCan = "ALL",
      hfLobbyistFilingPeriod = "ALL",
      ddlTransRegYear = "0",
      ddlFPLob = "ALL",
      Button3 = "Download+Data"
    )
  )
}
```

### Read

We can then read each file into a list and bind them together by
combining `purrr::map_df()` and `readr::read_delim()`.

``` r
nmc <- map_df(
  .x = dir_ls(raw_dir),
  .f = readr::read_delim,
  delim = ",",
  na = c("", "NA", "NULL", "N/A"),
  escape_backslash = FALSE, 
  escape_double = FALSE,
  col_types = cols(
    .default = col_character(),
    IsContribution = col_integer(),
    IsAnonymous = col_integer(),
    Amount = col_double(),
    `Date Contribution` = col_date(),
    `Date Added` = col_datetime()
  )
)
```

The file contains all transactions, both contributions and expenditures.
We will filter out the expenditures. Then we can remove any un-needed
columns.

``` r
nmc <- nmc %>% 
  filter(is_con == 1) %>% 
  select(-is_con)
```

## Explore

``` r
head(nmc)
#> # A tibble: 6 x 25
#>   first last  desc  is_anon  amount date       memo  rec_desc rec_first rec_mi rec_last suffix
#>   <chr> <chr> <chr>   <int>   <dbl> <date>     <chr> <chr>    <chr>     <chr>  <chr>    <chr> 
#> 1 "Cat… Bega… Mone…       0    0.03 2019-12-27 To r… <NA>     Catherine <NA>   Begaye   <NA>  
#> 2 "Mic… Luja… Mone…       0 5000    2019-08-15 <NA>  <NA>     <NA>      <NA>   <NA>     <NA>  
#> 3 "Cla… Rodr… In K…       0  150    2019-11-06 <NA>  Rudy�s … Rick      <NA>   Cartwri… <NA>  
#> 4 "Cla… Rodr… In K…       0   22.4  2019-10-24 <NA>  Flyers   Toni      <NA>   Jacquez  <NA>  
#> 5 "Cla… Rodr… Mone…       0  100    2019-11-06 <NA>  <NA>     <NA>      <NA>   <NA>     <NA>  
#> 6 "Cla… Rodr… Mone…       0  250    2019-10-29 <NA>  <NA>     <NA>      <NA>   <NA>     <NA>  
#> # … with 13 more variables: company <chr>, address <chr>, city <chr>, state <chr>, zip <chr>,
#> #   occupation <chr>, filing_period <chr>, added <dttm>, behalf_of <chr>, ballot_issue <chr>,
#> #   exp_why <chr>, beneficiary <chr>, pac_name <chr>
tail(nmc)
#> # A tibble: 6 x 25
#>   first last  desc  is_anon amount date       memo  rec_desc rec_first rec_mi rec_last suffix
#>   <chr> <chr> <chr>   <int>  <dbl> <date>     <chr> <chr>    <chr>     <chr>  <chr>    <chr> 
#> 1 <NA>  <NA>  In K…       0 4.49e1 2009-08-19 <NA>  <NA>     Ed        <NA>   Pack     <NA>  
#> 2 <NA>  <NA>  In K…       0 3.00e3 2009-07-01 <NA>  <NA>     <NA>      <NA>   <NA>     <NA>  
#> 3 <NA>  <NA>  In K…       0 1.00e4 2009-08-27 <NA>  <NA>     <NA>      <NA>   <NA>     <NA>  
#> 4 <NA>  <NA>  In K…       0 3.00e2 2009-05-30 <NA>  <NA>     <NA>      <NA>   <NA>     <NA>  
#> 5 <NA>  <NA>  In K…       0 3.00e2 2009-06-30 <NA>  <NA>     <NA>      <NA>   <NA>     <NA>  
#> 6 <NA>  <NA>  In K…       0 3.00e2 2009-07-31 <NA>  <NA>     <NA>      <NA>   <NA>     <NA>  
#> # … with 13 more variables: company <chr>, address <chr>, city <chr>, state <chr>, zip <chr>,
#> #   occupation <chr>, filing_period <chr>, added <dttm>, behalf_of <chr>, ballot_issue <chr>,
#> #   exp_why <chr>, beneficiary <chr>, pac_name <chr>
glimpse(sample_n(nmc, 20))
#> Rows: 20
#> Columns: 25
#> $ first         <chr> "Michelle", NA, NA, NA, NA, "William 'Bill'", "Lonnie", NA, "Diane", "Susa…
#> $ last          <chr> "Lujan Grisham", NA, NA, NA, NA, "Richardson-", "Talbert", NA, "Denish", "…
#> $ desc          <chr> "Monetary contribution", "Monetary contribution", "Monetary contribution",…
#> $ is_anon       <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
#> $ amount        <dbl> 250.0, 25.0, 75.0, 25.0, 193.3, 20.0, 250.0, 5.0, 50.0, 100.0, 2.0, 250.0,…
#> $ date          <date> 2017-04-28, 2018-06-08, 2015-04-13, 2018-01-08, 2010-12-28, 2006-07-05, 2…
#> $ memo          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "Flag Day", NA, NA, NA, NA…
#> $ rec_desc      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ rec_first     <chr> "Margaret", "JOSHUA", "George", "AARON", NA, "Ann", NA, "BOBBIE", "Virgini…
#> $ rec_mi        <chr> NA, NA, "W", NA, NA, NA, NA, NA, "S.", NA, NA, NA, NA, NA, NA, NA, NA, "J"…
#> $ rec_last      <chr> "Grubbs", "GARCIA", "Weeth", "VIGIL", NA, "Bean", NA, "BENZAQUEN", "Lawren…
#> $ suffix        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ company       <chr> NA, NA, NA, NA, "Connection Strategy LLC", NA, "AGC New Mexico", NA, NA, N…
#> $ address       <chr> "1382 Newtown Langhorne Rd Apt M-05", "4112 AVON ST NW", "PO Box 91478", "…
#> $ city          <chr> "Newtown", "ALBUQUERQUE", "Albuquerque", "RIO RANCHO", "Arlington", "Merce…
#> $ state         <chr> "PA", "NM", "NM", "NM", "VA", "California", "NM", "NM", "NM", "NM", "NM", …
#> $ zip           <chr> "18940", "87107", "87199-1478", "87144", "22202", "95340-8660", "87102", "…
#> $ occupation    <chr> "Artist", "HEALTHCARE", "Lawyer", "DEPUTY WARDEN", NA, NA, "pac", "NOT EMP…
#> $ filing_period <chr> "2017 Second Biannual", "2018 Fourth Primary", "2015 Second Biannual", "20…
#> $ added         <dttm> 2017-10-09 13:19:25, 2018-07-02 08:13:40, 2015-05-07 16:08:52, 2018-04-04…
#> $ behalf_of     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ ballot_issue  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ exp_why       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ beneficiary   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ pac_name      <chr> NA, "ActBlue New Mexico", "Committee on Individual Responsibility", "ActBl…
```

### Missing

``` r
col_stats(nmc, count_na)
#> # A tibble: 25 x 4
#>    col           class       n         p
#>    <chr>         <chr>   <int>     <dbl>
#>  1 first         <chr>  478005 0.507    
#>  2 last          <chr>  478005 0.507    
#>  3 desc          <chr>       0 0        
#>  4 is_anon       <int>    4891 0.00518  
#>  5 amount        <dbl>       0 0        
#>  6 date          <date>    665 0.000705 
#>  7 memo          <chr>  897622 0.951    
#>  8 rec_desc      <chr>  930097 0.986    
#>  9 rec_first     <chr>  163546 0.173    
#> 10 rec_mi        <chr>  793855 0.841    
#> 11 rec_last      <chr>  163812 0.174    
#> 12 suffix        <chr>  934244 0.990    
#> 13 company       <chr>  749159 0.794    
#> 14 address       <chr>   18424 0.0195   
#> 15 city          <chr>   17610 0.0187   
#> 16 state         <chr>   17201 0.0182   
#> 17 zip           <chr>   17168 0.0182   
#> 18 occupation    <chr>  446642 0.473    
#> 19 filing_period <chr>    9007 0.00955  
#> 20 added         <dttm>     18 0.0000191
#> 21 behalf_of     <chr>  942706 0.999    
#> 22 ballot_issue  <chr>  938809 0.995    
#> 23 exp_why       <chr>  938722 0.995    
#> 24 beneficiary   <chr>  938837 0.995    
#> 25 pac_name      <chr>  465595 0.493
```

``` r
nmc <- nmc %>% 
  unite(
    rec_first, rec_mi, rec_last, company,
    col = rec_name,
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  flag_na(date, last, amount, rec_last)
nmc %>% 
  select(date, last, amount, rec_last) %>% 
  col_stats(count_na)
#> # A tibble: 4 x 4
#>   col      class       n        p
#>   <chr>    <chr>   <int>    <dbl>
#> 1 date     <date>    665 0.000705
#> 2 last     <chr>  478005 0.507   
#> 3 amount   <dbl>       0 0       
#> 4 rec_last <chr>  163812 0.174
nmc %>% 
  filter(na_flag) %>% 
  select(date, last, amount, rec_last) %>% 
  sample_frac()
#> # A tibble: 580,980 x 4
#>    date       last  amount rec_last 
#>    <date>     <chr>  <dbl> <chr>    
#>  1 2006-04-18 <NA>   25    Garcia   
#>  2 2017-09-07 <NA>    4    GAMBOA   
#>  3 2009-08-20 <NA>   60    <NA>     
#>  4 2011-09-16 <NA>    0.18 Bernal   
#>  5 2015-12-18 <NA>   40    Frank    
#>  6 2018-11-01 <NA>   25    FAYERBERG
#>  7 2018-05-22 <NA>  100    Lipschitz
#>  8 2010-05-20 <NA>   25    Valencia 
#>  9 2019-03-11 <NA>  320.   Salazar  
#> 10 2018-03-23 <NA>    3.75 FINLEY   
#> # … with 580,970 more rows
```

### Duplicates

``` r
nmc <- flag_dupes(nmc, everything())
sum(nmc$dupe_flag)
#> [1] 13921
```

``` r
nmc %>% 
  filter(dupe_flag) %>% 
  select(date, last, amount, rec_last)
#> # A tibble: 13,921 x 4
#>    date       last          amount rec_last
#>    <date>     <chr>          <dbl> <chr>   
#>  1 2019-09-05 Jones            100 Jones   
#>  2 2019-09-05 Jones            100 Jones   
#>  3 2019-09-06 Ferrary           20 Kurtz   
#>  4 2019-09-06 Ferrary           20 Kurtz   
#>  5 2019-09-06 Ferrary          100 Cote    
#>  6 2019-09-06 Ferrary          100 Cote    
#>  7 2019-08-30 Lujan Grisham  10000 <NA>    
#>  8 2019-08-30 Lujan Grisham  10000 <NA>    
#>  9 2019-08-02 Lujan Grisham  10000 <NA>    
#> 10 2019-08-02 Lujan Grisham  10000 <NA>    
#> # … with 13,911 more rows
```
