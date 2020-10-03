Arkansas Contributions
================
Kiernan Nicholls
2020-09-30 14:22:09

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
  aws.s3, # upload to aws s3
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
#> [1] "/home/kiernan/Code/tap/R_campfin"
```

## Data

Data is obtained from the Arkansas Secretary of State’s [Financial
Disclosure
portal](https://financial-disclosures.sos.arkansas.gov/index.html#/dataDownload).

> This page provides comma separated value (CSV) downloads of
> contribution, expenditure, and loan data for each reporting year in a
> zipped file format. These files can be downloaded and imported into
> other applications (Microsoft Excel, Microsoft Access, etc.)
> 
> This data is extracted from the Arkansas Campaign Finance database as
> it existed as of 06/24/2020 12:02 PM.

The AR SOS also provides a [data layout
key](https://financial-disclosures.sos.arkansas.gov//CFISAR_Service/Template/KeyDownloads/Expenditures,%20Debts,%20and%20Payments%20to%20Workers%20File%20Layout%20Key.pdf):

| Field | Field Name           | Description                                     |
| :---- | :------------------- | :---------------------------------------------- |
| A     | `ORG ID`             | Unique ID of the paying candidate or committee. |
| B     | `EXPENDITURE AMOUNT` | Expenditure Amount.                             |
| C     | `EXPENDITURE  DATE`  | Expenditure Date.                               |
| D     | `LAST NAME`          | Payee Last or Full Name.                        |
| E     | `FIRST NAME`         | Payee First Name.                               |
| F     | `MIDDLE NAME`        | Payee Middle Initial or Name if provided.       |
| G     | `SUFFIX`             | Payee Name Suffix.                              |
| H     | `ADDRESS 1`          | Payee Street, PO Box, etc.                      |
| I     | `ADDRESS 2`          | Payee Suite/Apartment number.                   |
| J     | `CITY`               | Payee City                                      |
| K     | `STATE`              | Payee State                                     |
| L     | `ZIP`                | Payee Zip Code                                  |
| M     | `EXPLANATION`        | Explanation provided for the expenditure.       |
| N     | `EXPENDITURE ID`     | Unique Expenditure internal ID.                 |
| O     | `FILED DATE`         | Expenditure Filed Date                          |
| P     | `PURPOSE`            | Purpose of the Expenditure.                     |
| Q     | `EXPENDITURE TYPE`   | Indicates Type of Expenditure.                  |
| R     | `COMMITTEE TYPE`     | Indicates Type of Committee                     |
| S     | `COMMITTEE NAME`     | Name of the paying committee.                   |
| T     | `CANDIDATE NAME`     | Name of the paying candidate.                   |
| U     | `AMENDED`            | Y/N if an amendment was filed.                  |

## Download

To download the expenditure files, we can make a series of direct
`httr::GET()` requests to the AR SOS server, downloaded the CSV files
locally.

``` r
raw_dir <- dir_create(here("ar", "contribs", "data", "raw"))
raw_url <- str_c(
  base = "https://financial-disclosures.sos.arkansas.gov",
  path = "/CFISAR_Service/api/DataDownload/GetCSVDownloadReport"
)
```

``` r
ys <- seq(2017, year(today()))
fix_dir <- dir_create(path(dirname(raw_dir), "fix"))
for (y in ys) {
  # download raw file
  raw_file <- glue("CON_{y}.csv")
  raw_path <- path(raw_dir, raw_file)
  GET(
    url = raw_url,
    write_disk(raw_path, overwrite = TRUE),
    query = list(
      year = "2017",
      transactionType = "CON",
      reportFormat = "csv",
      fileName = raw_file
    )
  )
  # fix downloaded file
  read_file(raw_path) %>% 
    str_replace_all("(?<!,|^)\"(?!,|$)", "'") %>% 
    str_remove_all(",\\s(?=\r\n)") %>% 
    write_file(path(fix_dir, basename(raw_path)))
  message(paste("finished", y))
}
```

``` r
fix_paths <- dir_ls(fix_dir)
```

## Read

``` r
arc <- map_df(
  .x = fix_paths,
  .f = read_delim,
  delim = ",",
  escape_backslash = FALSE,
  escape_double = FALSE,
  col_types = cols(
    .default = col_character(),
    `Receipt Amount` = col_double(),
    `Receipt Date` = col_date("%m/%d/%Y %H:%M:%S %p"),
    `Filed Date` = col_date("%m/%d/%Y %H:%M:%S %p")
  )
)
```

We can count the distinct values of a discrete variable to check file
reading.

``` r
count(arc, type)
#> # A tibble: 3 x 2
#>   type                      n
#>   <chr>                 <int>
#> 1 Contributions        333097
#> 2 Loan                   2074
#> 3 Returned Expenditure    109
```

## Explore

``` r
glimpse(arc)
#> Rows: 335,280
#> Columns: 22
#> $ org_id      <chr> "219790", "219790", "219790", "219790", "219790", "220792", "220792", "22079…
#> $ amount      <dbl> 500.00, 500.00, 1000.00, 1000.00, 1000.00, 50.00, 50.00, 200.00, 250.00, 250…
#> $ date        <date> 2017-07-17, 2017-08-17, 2017-07-17, 2017-07-18, 2017-08-01, 2017-07-10, 201…
#> $ last        <chr> "Walker", "Dunk", "Stephens", "Stephens Energy PAC", "Cella", "Bazzelle", "F…
#> $ first       <chr> "William", "Ken", "W.", NA, "Charles", "Chirie", "Charlene", NA, NA, NA, NA,…
#> $ middle      <chr> NA, NA, "R.", NA, NA, "L", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ suffix      <chr> NA, NA, "JR.", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ address1    <chr> "21 Riverlyn Drive", "4387 Catherine Street", "9 Sunset Circle", "623 Garris…
#> $ address2    <chr> NA, NA, NA, NA, NA, NA, NA, "Ste 205", NA, NA, NA, "1401 W Capitol Ave, Suit…
#> $ city        <chr> "Fort Smith", "Springdale", "Little Rock", "Fort Smith", "St. Louis", "Bento…
#> $ state       <chr> "AR", "AR", "AR", "AR", "MO", "AR", "AR", "AR", "AR", "AR", "AR", "AR", "AR"…
#> $ zip         <chr> "72903", "72764", "72207", "72901", "63105", "72019-6667", "72956", "72201",…
#> $ description <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ id          <chr> "3149", "3150", "3147", "3148", "3350", "7446", "7447", "7456", "7462", "746…
#> $ filed_date  <date> 2017-10-09, 2017-10-09, 2017-10-09, 2017-10-09, 2017-10-09, 2017-10-11, 201…
#> $ source_type <chr> "Individual", "Individual", "Individual", "Bus, Org, or Unlisted PAC", "Indi…
#> $ type        <chr> "Contributions", "Contributions", "Contributions", "Contributions", "Contrib…
#> $ com_type    <chr> "Candidate (CC&E)", "Candidate (CC&E)", "Candidate (CC&E)", "Candidate (CC&E…
#> $ candidate   <chr> "Gary Don Stubblefield", "Gary Don Stubblefield", "Gary Don Stubblefield", "…
#> $ amended     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ employer    <chr> "The Stephens Group, LLC", "Simplex Grinnell Security Systems", "The Stephen…
#> $ occupation  <chr> "Financial/Investment", "General Business", "Financial/Investment", NA, "Fin…
tail(arc)
#> # A tibble: 6 x 22
#>   org_id amount date       last  first middle suffix address1 address2 city  state zip  
#>   <chr>   <dbl> <date>     <chr> <chr> <chr>  <chr>  <chr>    <chr>    <chr> <chr> <chr>
#> 1 374811    500 2020-03-11 Amer… <NA>  <NA>   <NA>   8700 We… Suite 1… Chic… IL    6063…
#> 2 374811    500 2020-04-06 Unio… <NA>  <NA>   <NA>   700 13t… <NA>     Wash… DC    20005
#> 3 374811    500 2020-07-09 Demi… Clai… P.     <NA>   P.O. Bo… <NA>     El D… AR    71731
#> 4 374811    500 2020-07-13 Pula… <NA>  <NA>   <NA>   P.O. Bo… <NA>     Litt… AR    72217
#> 5 374811   1000 2020-04-23 BNSF… <NA>  <NA>   <NA>   2500 Lo… <NA>     Fort… TX    76131
#> 6 374811   1000 2020-07-17 AT&T… <NA>  <NA>   <NA>   1401 W.… <NA>     Litt… AR    72201
#> # … with 10 more variables: description <chr>, id <chr>, filed_date <date>, source_type <chr>,
#> #   type <chr>, com_type <chr>, candidate <chr>, amended <lgl>, employer <chr>, occupation <chr>
```

### Missing

Variables differ in the degree of values they are missing.

``` r
col_stats(arc, count_na)
#> # A tibble: 22 x 4
#>    col         class       n         p
#>    <chr>       <chr>   <int>     <dbl>
#>  1 org_id      <chr>       0 0        
#>  2 amount      <dbl>       0 0        
#>  3 date        <date>      0 0        
#>  4 last        <chr>  211227 0.630    
#>  5 first       <chr>  222578 0.664    
#>  6 middle      <chr>  298163 0.889    
#>  7 suffix      <chr>  333641 0.995    
#>  8 address1    <chr>  211252 0.630    
#>  9 address2    <chr>  325445 0.971    
#> 10 city        <chr>  211195 0.630    
#> 11 state       <chr>      19 0.0000567
#> 12 zip         <chr>  211196 0.630    
#> 13 description <chr>  333578 0.995    
#> 14 id          <chr>       0 0        
#> 15 filed_date  <date>      0 0        
#> 16 source_type <chr>       0 0        
#> 17 type        <chr>       0 0        
#> 18 com_type    <chr>       0 0        
#> 19 candidate   <chr>  259417 0.774    
#> 20 amended     <lgl>       0 0        
#> 21 employer    <chr>  223857 0.668    
#> 22 occupation  <chr>  249391 0.744
```

With `campfin::flag_na()`, we can flag any record missing a key
variable.

``` r
arc <- arc %>% 
  flag_na(date, last, amount, candidate)
```

``` r
percent(mean(arc$na_flag), 0.1)
#> [1] "80.1%"
```

These records are missing either the `last` or `candidate` names.

``` r
arc %>% 
  filter(na_flag) %>% 
  select(date, last, amount, candidate) %>%
  col_stats(count_na)
#> # A tibble: 4 x 4
#>   col       class       n     p
#>   <chr>     <chr>   <int> <dbl>
#> 1 date      <date>      0 0    
#> 2 last      <chr>  211227 0.787
#> 3 amount    <dbl>       0 0    
#> 4 candidate <chr>  259417 0.966
```

Records missing a contributor `last` name are non-itemized.

``` r
arc %>% 
  filter(is.na(last)) %>% 
  count(source_type, sort = TRUE) %>% 
  add_prop()
#> # A tibble: 4 x 3
#>   source_type       n        p
#>   <chr>         <int>    <dbl>
#> 1 Non-itemized 210416 0.996   
#> 2 Interest        743 0.00352 
#> 3 Individual       41 0.000194
#> 4 Anonymous        27 0.000128
```

Records missing the receiving `candidate` name are given to PACs.

``` r
arc %>% 
  filter(is.na(candidate)) %>% 
  count(com_type, sort = TRUE) %>% 
  add_prop()
#> # A tibble: 4 x 3
#>   com_type                               n        p
#>   <chr>                              <int>    <dbl>
#> 1 Political Action Committee        257376 0.992   
#> 2 Political Party                     1572 0.00606 
#> 3 County Political Party               405 0.00156 
#> 4 Independent Expenditure Committee     64 0.000247
```

### Duplicates

If we ignore the supposedly unique `id` variable, there are a number of
duplicate records.

``` r
arc <- flag_dupes(arc, -id)
percent(mean(arc$dupe_flag), 0.1)
#> [1] "56.9%"
```

``` r
arc %>% 
  filter(dupe_flag) %>% 
  select(date, last, address1, amount, candidate) %>% 
  drop_na()
#> # A tibble: 491 x 5
#>    date       last                                       address1         amount candidate         
#>    <date>     <chr>                                      <chr>             <dbl> <chr>             
#>  1 2017-08-19 Arkansas Conservative Legislative PAC      PO Box 85          2700 Linda Collins-Smi…
#>  2 2017-08-19 Arkansas Conservative Legislative PAC      PO Box 85          2700 Linda Collins-Smi…
#>  3 2017-08-24 Smith                                      2222 Madison 65…     10 Bob Ballinger     
#>  4 2017-08-24 Smith                                      2222 Madison 65…     10 Bob Ballinger     
#>  5 2017-09-23 Pownall                                    6 Martz Circle       15 Bob Ballinger     
#>  6 2017-09-23 Pownall                                    6 Martz Circle       15 Bob Ballinger     
#>  7 2017-07-20 Arkansas Pharmacists Political Action Com… 417 South victo…    500 Clinton Joseph Pe…
#>  8 2017-07-20 Arkansas Pharmacists Political Action Com… 417 South victo…    500 Clinton Joseph Pe…
#>  9 2017-07-25 Cameron                                    P.O. Box 21440     2700 Leslie Rutledge   
#> 10 2017-07-25 Cameron                                    P.O. Box 21440     2700 Leslie Rutledge   
#> # … with 481 more rows
```

Even more of these duplicate records are missing a `last` name.

``` r
percent(mean(is.na(arc$last[arc$dupe_flag])), 0.1)
#> [1] "99.7%"
```

### Categorical

``` r
col_stats(arc, n_distinct)
#> # A tibble: 24 x 4
#>    col         class       n          p
#>    <chr>       <chr>   <int>      <dbl>
#>  1 org_id      <chr>    1003 0.00299   
#>  2 amount      <dbl>    9056 0.0270    
#>  3 date        <date>   1098 0.00327   
#>  4 last        <chr>   18900 0.0564    
#>  5 first       <chr>    7330 0.0219    
#>  6 middle      <chr>    1083 0.00323   
#>  7 suffix      <chr>      10 0.0000298 
#>  8 address1    <chr>   44450 0.133     
#>  9 address2    <chr>    1334 0.00398   
#> 10 city        <chr>    4297 0.0128    
#> 11 state       <chr>      82 0.000245  
#> 12 zip         <chr>    8546 0.0255    
#> 13 description <chr>     979 0.00292   
#> 14 id          <chr>  335267 1.00      
#> 15 filed_date  <date>    657 0.00196   
#> 16 source_type <chr>      10 0.0000298 
#> 17 type        <chr>       3 0.00000895
#> 18 com_type    <chr>       6 0.0000179 
#> 19 candidate   <chr>     594 0.00177   
#> 20 amended     <lgl>       2 0.00000597
#> 21 employer    <chr>   15641 0.0467    
#> 22 occupation  <chr>      33 0.0000984 
#> 23 na_flag     <lgl>       2 0.00000597
#> 24 dupe_flag   <lgl>       2 0.00000597
```

``` r
explore_plot(arc, type)
```

![](../plots/distinct_plots-1.png)<!-- -->

``` r
explore_plot(arc, com_type)
```

![](../plots/distinct_plots-2.png)<!-- -->

### Amounts

``` r
summary(arc$amount)
#>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
#>       0.0       4.0      15.4     198.2     100.0 1877602.4
mean(arc$amount <= 0)
#> [1] 0
```

The `amount` values for records missing a contributor name are much
smaller on average, however their doesn’t appear to be a firm upper
limit. Could still possibly be related to itemization.

![](../plots/hist_amount-1.png)<!-- -->

``` r
arc %>% 
  count(cents = amount %% 1, sort = TRUE) %>% 
  add_prop()
#> # A tibble: 795 x 3
#>    cents      n       p
#>    <dbl>  <int>   <dbl>
#>  1  0    164299 0.490  
#>  2  0.5    4969 0.0148 
#>  3  0.3    4797 0.0143 
#>  4  0.01   4381 0.0131 
#>  5  0.02   3523 0.0105 
#>  6  0.33   2960 0.00883
#>  7  0.17   2951 0.00880
#>  8  0.03   2934 0.00875
#>  9  0.62   2781 0.00829
#> 10  0.46   2638 0.00787
#> # … with 785 more rows
```

### Dates

We can add the calendar year from `date` with `lubridate::year()`

``` r
arc <- mutate(arc, year = year(date))
```

``` r
min(arc$date)
#> [1] "2015-01-06"
sum(arc$year < 2017)
#> [1] 3
max(arc$date)
#> [1] "2020-09-11"
sum(arc$date > today())
#> [1] 0
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
arc <- arc %>% 
  unite(
    col = address_full,
    starts_with("address"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    address_norm = normal_address(
      address = address_full,
      abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-address_full)
```

``` r
arc %>% 
  select(contains("address")) %>% 
  distinct() %>% 
  sample_n(10)
#> # A tibble: 10 x 3
#>    address1                     address2 address_norm              
#>    <chr>                        <chr>    <chr>                     
#>  1 200 River Market Ave Ste 200 <NA>     200 RIV MARKET AVE STE 200
#>  2 1600 Cantrel lRoad           <NA>     1600 CANTREL LROAD        
#>  3 PO Box 1302                  <NA>     PO BOX 1302               
#>  4 5406 W. Main St              <NA>     5406 W MAIN ST            
#>  5 112 Orchard                  <NA>     112 ORCH                  
#>  6 2010 Crafts Dr               <NA>     2010 CRAFTS DR            
#>  7 5111 Llano Dr                <NA>     5111 LLANO DR             
#>  8 5431 Country Club            <NA>     5431 COUNTRY CLB          
#>  9 2511 Belair Dr               <NA>     2511 BELAIR DR            
#> 10 1519 S 1900 E                <NA>     1519 S 1900 E
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
arc <- mutate(
  .data = arc,
  zip_norm = normal_zip(
    zip = zip,
    na_rep = TRUE
  )
)
```

``` r
progress_table(
  arc$zip,
  arc$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 zip        0.854       8546   0.630 18138   3924
#> 2 zip_norm   0.997       5811   0.630   332    122
```

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

``` r
arc <- mutate(
  .data = arc,
  state_norm = normal_state(
    state = state,
    abbreviate = TRUE,
    na_rep = TRUE,
    valid = valid_state
  )
)
```

``` r
arc %>% 
  filter(state != state_norm) %>% 
  count(state, state_norm, sort = TRUE)
#> # A tibble: 17 x 3
#>    state state_norm     n
#>    <chr> <chr>      <int>
#>  1 Ar    AR           138
#>  2 oH    OH            44
#>  3 aR    AR            30
#>  4 dc    DC            30
#>  5 fL    FL             7
#>  6 oK    OK             5
#>  7 ar    AR             3
#>  8 Ne    NE             3
#>  9 dC    DC             2
#> 10 Fl    FL             1
#> 11 iN    IN             1
#> 12 In    IN             1
#> 13 oh    OH             1
#> 14 pa    PA             1
#> 15 rI    RI             1
#> 16 tx    TX             1
#> 17 Wa    WA             1
```

``` r
progress_table(
  arc$state,
  arc$state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage      prop_in n_distinct   prop_na n_out n_diff
#>   <chr>        <dbl>      <dbl>     <dbl> <dbl>  <dbl>
#> 1 state        0.999         82 0.0000567   306     28
#> 2 state_norm   1             55 0.000164      0      1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
arc <- mutate(
  .data = arc,
  city_norm = normal_city(
    city = city, 
    abbs = usps_city,
    states = c("AR", "DC", "ARKANSAS"),
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
arc <- arc %>% 
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
good_refine <- arc %>% 
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

    #> # A tibble: 10 x 5
    #>    state_norm zip_norm city_swap              city_refine                   n
    #>    <chr>      <chr>    <chr>                  <chr>                     <int>
    #>  1 AR         71901    HOT SPRINGS NAT L PARK HOT SPRINGS NATIONAL PARK     3
    #>  2 SC         29406    NORTH CHARLESTON       CHARLESTON                    3
    #>  3 AR         72002    ALEXANDRA              ALEXANDER                     1
    #>  4 AR         72120    SHERWOOD DR            SHERWOOD                      1
    #>  5 AR         72173    VOLNIA                 VILONIA                       1
    #>  6 AR         72455    POCOHANTAS             POCAHONTAS                    1
    #>  7 AR         72801    RUSSLEVILLE            RUSSELLVILLE                  1
    #>  8 FL         33309    FORT LAUDERDEL         FORT LAUDERDALE               1
    #>  9 NJ         08807    BRIDGEWATWATER         BRIDGEWATER                   1
    #> 10 TX         75089    ROWLLET                ROWLETT                       1

Then we can join the refined values back to the database.

``` r
arc <- arc %>% 
  left_join(good_refine, by = names(.)) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

``` r
arc %>% 
  filter(city_refine %out% valid_city) %>% 
  count(city_refine, state_norm, sort = TRUE)
#> # A tibble: 325 x 3
#>    city_refine     state_norm      n
#>    <chr>           <chr>       <int>
#>  1 <NA>            ME         211189
#>  2 ROCHESTER HILLS MI            142
#>  3 HOLIDAY ISLAND  AR            127
#>  4 GREERS FERRY    AR            117
#>  5 HOOVER          AL             98
#>  6 THE WOODLANDS   TX             98
#>  7 TEXAS           TX             90
#>  8 MOUNTAIN BROOK  AL             85
#>  9 CAMMACK VILLAGE AR             78
#> 10 VESTAVIA        AL             77
#> # … with 315 more rows
```

``` r
extra_city <- c(extra_city, "ROCHESTER HILLS", "HOLIDAY ISLAND", "GREERS FERRY")
```

| stage        | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :----------- | -------: | ----------: | -------: | -----: | ------: |
| city\_raw)   |    0.972 |        3655 |     0.63 |   3443 |     606 |
| city\_norm   |    0.983 |        3530 |     0.63 |   2081 |     469 |
| city\_swap   |    0.989 |        3240 |     0.63 |   1366 |     174 |
| city\_refine |    0.989 |        3231 |     0.63 |   1355 |     165 |

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
arc <- arc %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  rename_all(~str_remove(., "_raw"))
```

``` r
glimpse(sample_frac(arc))
#> Rows: 335,280
#> Columns: 29
#> $ org_id        <chr> "240609", "242205", "220821", "242205", "240609", "232402", "242177", "242…
#> $ amount        <dbl> 20.00, 8.78, 250.00, 2.00, 10.00, 110.00, 38.46, 5.00, 3.09, 7.75, 100.00,…
#> $ date          <date> 2020-03-02, 2019-01-18, 2017-12-05, 2019-01-18, 2020-06-01, 2020-04-30, 2…
#> $ last          <chr> NA, NA, "Jones", NA, NA, "Staudenmier", "CHOATE", NA, "Riner", NA, "Harper…
#> $ first         <chr> NA, NA, "William", NA, NA, "Julie", "THOMAS", NA, "James", NA, "Jannifer",…
#> $ middle        <chr> NA, NA, "M.", NA, NA, NA, NA, NA, "Andrew", NA, NA, NA, NA, "C", NA, NA, N…
#> $ suffix        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ address1      <chr> NA, NA, "3408 North Hills Blvd.", NA, NA, "235 E 42nd St", "8222 STONE MAS…
#> $ address2      <chr> NA, NA, NA, NA, NA, "Pfizer Inc", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ city          <chr> NA, NA, "North Little Rock", NA, NA, "New York", "WINDERMERE", NA, "Mena",…
#> $ state         <chr> "ME", "ME", "AR", "ME", "ME", "NY", "FL", "ME", "AR", "ME", "GA", "ME", "M…
#> $ zip           <chr> NA, NA, "72116", NA, NA, "10017", "34786-5624", NA, "71953", NA, "30214", …
#> $ description   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ id            <chr> "2370289", "1616626", "81542", "1627975", "2468734", "2404892", "2359689",…
#> $ filed_date    <date> 2020-04-15, 2019-04-17, 2018-01-15, 2019-04-17, 2020-07-15, 2020-07-07, 2…
#> $ source_type   <chr> "Non-itemized", "Non-itemized", "Individual", "Non-itemized", "Non-itemize…
#> $ type          <chr> "Contributions", "Contributions", "Contributions", "Contributions", "Contr…
#> $ com_type      <chr> "Political Action Committee", "Political Action Committee", "Candidate (CC…
#> $ candidate     <chr> NA, NA, "Melanie Martin", NA, NA, NA, NA, NA, "Andy Riner", NA, NA, NA, NA…
#> $ amended       <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ employer      <chr> NA, NA, "State of Arkansas - Attorney General", NA, NA, NA, "United Health…
#> $ occupation    <chr> NA, NA, "Attorney/Legal", NA, NA, NA, "Other", NA, "Attorney/Legal", NA, N…
#> $ na_flag       <lgl> TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, …
#> $ dupe_flag     <lgl> TRUE, TRUE, FALSE, TRUE, TRUE, FALSE, FALSE, TRUE, FALSE, TRUE, FALSE, TRU…
#> $ year          <dbl> 2020, 2019, 2017, 2019, 2020, 2020, 2020, 2020, 2019, 2019, 2020, 2019, 20…
#> $ address_clean <chr> NA, NA, "3408 N HLS BLVD", NA, NA, "235 E 42 ND ST PFIZER INC", "8222 STON…
#> $ zip_clean     <chr> NA, NA, "72116", NA, NA, "10017", "34786", NA, "71953", NA, "30214", NA, N…
#> $ state_clean   <chr> "ME", "ME", "AR", "ME", "ME", "NY", "FL", "ME", "AR", "ME", "GA", "ME", "M…
#> $ city_clean    <chr> NA, NA, "NORTH LITTLE ROCK", NA, NA, "NEW YORK", "WINDERMERE", NA, "MENA",…
```

1.  There are 335,280 records in the database.
2.  There are 190,821 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 268,498 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("ar", "contribs", "data", "clean"))
clean_path <- path(clean_dir, "ar_contribs_clean.csv")
write_csv(arc, clean_path, na = "")
file_size(clean_path)
#> 56.8M
file_encoding(clean_path) %>% 
  mutate(across(path, path.abbrev))
#> # A tibble: 1 x 3
#>   path                                           mime            charset
#>   <chr>                                          <chr>           <chr>  
#> 1 ~/ar/contribs/data/clean/ar_contribs_clean.csv application/csv utf-8
```

## Upload

We can use the `aws.s3::put_object()` to upload the text file to the IRW
server.

``` r
s3_path <- path("csv", basename(clean_path))
if (!object_exists(s3_path, "publicaccountability")) {
  put_object(
    file = clean_path,
    object = s3_path, 
    bucket = "publicaccountability",
    acl = "public-read",
    show_progress = TRUE
  )
}
```

``` r
as_fs_bytes(object_size(s3_path, "publicaccountability"))
#> 56.8M
```

## Dictionary

The following table describes the variables in our final exported file:

| Column          | Original              | Type     | Definition                                     |
| :-------------- | :-------------------- | :------- | :--------------------------------------------- |
| `org_id`        | `OrgID`               | `<chr>`  | Unique ID of the paying candidate or committee |
| `amount`        | `Receipt Amount`      | `<dbl>`  | Contribution Amount                            |
| `date`          | `Receipt Date`        | `<date>` | Contribution Date                              |
| `last`          | `Last Name`           | `<chr>`  | Payee Last or Full Name                        |
| `first`         | `First Name`          | `<chr>`  | Payee First Name                               |
| `middle`        | `Middle Name`         | `<chr>`  | Payee Middle Initial or Name if provided       |
| `suffix`        | `Suffix`              | `<chr>`  | Payee Name Suffix                              |
| `address1`      | `Address1`            | `<chr>`  | Payee Street, PO Box, etc                      |
| `address2`      | `Address2`            | `<chr>`  | Payee Suite/Apartment number                   |
| `city`          | `City`                | `<chr>`  | Payee City                                     |
| `state`         | `State`               | `<chr>`  | Payee State                                    |
| `zip`           | `Zip`                 | `<chr>`  | Payee Zip Code                                 |
| `description`   | `Description`         | `<chr>`  | Description of Contribution                    |
| `id`            | `Receipt ID`          | `<chr>`  | Unique Contribution internal ID                |
| `filed_date`    | `Filed Date`          | `<date>` | Contribution Filed Date                        |
| `source_type`   | `Receipt Source Type` | `<chr>`  | Cobtribution source                            |
| `type`          | `Receipt Type`        | `<chr>`  | Indicates Type of Contribution                 |
| `com_type`      | `Committee Type`      | `<chr>`  | Indicates Type of Committee                    |
| `candidate`     | `Committee Name`      | `<chr>`  | Name of the paying candidate                   |
| `amended`       | `Candidate Name`      | `<lgl>`  | Y/N if an amendment was filed                  |
| `employer`      | `Amended`             | `<chr>`  | Contributor employer name                      |
| `occupation`    | `Employer`            | `<chr>`  | Contributor occupation                         |
| `na_flag`       | `Occupation`          | `<lgl>`  | Flag for missing date, amount, or name         |
| `dupe_flag`     | `Occupation Comment`  | `<lgl>`  | Flag for completely duplicated record          |
| `year`          |                       | `<dbl>`  | Calendar year of contribution date             |
| `address_clean` |                       | `<chr>`  | Normalized combined street address             |
| `zip_clean`     |                       | `<chr>`  | Normalized 5-digit ZIP code                    |
| `state_clean`   |                       | `<chr>`  | Normalized 2-digit state abbreviation          |
| `city_clean`    |                       | `<chr>`  | Normalized city name                           |
