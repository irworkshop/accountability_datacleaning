Mississippi Contracts
================
Kiernan Nicholls
2020-05-29 14:32:14

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

## Import

### Download

``` r
raw_dir <- dir_create(here("ms", "contracts", "data", "raw"))
raw_json <- path(raw_dir, "ms_contracts.json")
```

``` r
ms_post <- POST(
  url = "https://www.ms.gov/dfa/contract_bid_search/Contract/ContractData",
  set_cookies(BIGipServerpl_msi_prod_https = "rd1o00000000000000000000ffff0a0df71fo443"),
  write_disk(raw_json, overwrite = TRUE),
  query = list(
    sEcho = 2,
    iColumns = 8,
    sColumns = ",,,,,,,",
    iDisplayStart = 0,
    iDisplayLength = 9999,
    mDataProp_0 = "ContractNumber",
    bSortable_0 = TRUE,
    mDataProp_1 = "ObjectID",
    bSortable_1 = TRUE,
    mDataProp_2 = "PrimaryVendor",
    bSortable_2 = TRUE,
    mDataProp_3 = "Attachments",
    bSortable_3 = TRUE,
    mDataProp_4 = "StartDate",
    bSortable_4 = TRUE,
    mDataProp_5 = "EndDate",
    bSortable_5 = TRUE,
    mDataProp_6 = "PCardEnabled",
    bSortable_6 = TRUE,
    mDataProp_7 = 7,
    bSortable_7 = FALSE,
    iSortCol_0 = 0,
    sSortDir_0 = "asc",
    iSortingCols = 1
  )
)
```

### Read

This the raw JSON content from this `POST()` can be converted to a list.

``` r
ms_list <- content(ms_post)
```

For each element of the list, we can convert it to a single tibble row.

``` r
list2tibble <- function(list_element) {
  list_element %>% 
    extract(-11) %>% 
    unlist(recursive = FALSE) %>% 
    compact() %>% 
    as_tibble() %>% 
    na_if("")
}
```

Calling this function on every element of the list and binding them
together produces a single data frame.

``` r
msc <- map_df(ms_list$aaData, list2tibble)
rm(ms_list)
```

Then we can parse the data frame columns into R objects.

``` r
mili_date <- function(x) {
  as_datetime(as.numeric(str_extract(x, "\\d+"))/1000)
}
msc <- msc %>% 
  mutate(across(ends_with("Date"), mili_date))
```

## Explore

``` r
glimpse(msc)
#> Rows: 387
#> Columns: 15
#> $ BuyerEmail         <chr> "STEPHEN.TUCKER@DFA.MS.GOV", "STEPHEN.TUCKER@DFA.MS.GOV", "STEPHEN.TU…
#> $ BuyerFax           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ BuyerName          <chr> "Stephen Tucker", "Stephen Tucker", "Stephen Tucker", "Stephen Tucker…
#> $ BuyerPhone         <chr> "6013593107", "6013593107", "6013593107", "6013593107", "6013593107",…
#> $ CatalogURL         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ ContractID         <int> 6178, 6061, 6389, 6353, 6427, 6405, 6060, 6249, 6339, 6369, 6429, 647…
#> $ ContractNumber     <chr> "1130-14-C-SWCT-00566-V008", "1130-15-C-SWCT-00186-V007", "1130-15-C-…
#> $ EndDate            <dttm> 2020-07-31 05:00:00, 2020-06-30 05:00:00, 2021-02-28 06:00:00, 2020-…
#> $ ObjectID           <chr> "8200035961", "8200012602", "8200013181", "8200013359", "8200015348",…
#> $ PCardEnabled       <chr> "01", "01", "01", "01", "01", "01", "01", "01", "01", "01", "01", "01…
#> $ PDFUrl             <chr> "https://SRM.MAGIC.MS.GOV:443/SAP/EBP/DOCSERVER/SYN%5FCTR%5FFORM%5F82…
#> $ PrimaryVendor.ID   <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ PrimaryVendor.Name <chr> "STAPLES ADVANTAGE", "SANOFI PASTEUR INC", "OFFICE DEPOT - CINCINNATI…
#> $ ShortDescription   <chr> "OFFICE SUPPLIES/STAPLES INC.\n", "MMCAP Vaccines", "Region 4 Office …
#> $ StartDate          <dttm> 2014-06-28 05:00:00, 2014-07-28 05:00:00, 2014-08-12 05:00:00, 2014-…
tail(msc)
#> # A tibble: 6 x 15
#>   BuyerEmail BuyerFax BuyerName BuyerPhone CatalogURL ContractID ContractNumber EndDate            
#>   <chr>      <chr>    <chr>     <chr>      <chr>           <int> <chr>          <dttm>             
#> 1 PAULA.CON… <NA>     Paula Co… 6014328046 <NA>             5538 1601-19-C-EPL… 2026-09-15 05:00:00
#> 2 PAULA.CON… <NA>     Paula Co… 6014328046 <NA>             5539 1601-19-C-EPL… 2026-09-15 05:00:00
#> 3 PAULA.CON… <NA>     Paula Co… 6014328046 <NA>             5540 1601-19-C-EPL… 2026-09-15 05:00:00
#> 4 PAULA.CON… <NA>     Paula Co… 6014328046 <NA>             5541 1601-19-C-EPL… 2026-09-15 05:00:00
#> 5 PAULA.CON… <NA>     Paula Co… 6014328046 <NA>             5542 1601-19-C-EPL… 2026-09-15 05:00:00
#> 6 PAULA.CON… <NA>     Paula Co… 6014328046 <NA>             6462 1601-20-C-EPL… 2021-04-07 05:00:00
#> # … with 7 more variables: ObjectID <chr>, PCardEnabled <chr>, PDFUrl <chr>,
#> #   PrimaryVendor.ID <int>, PrimaryVendor.Name <chr>, ShortDescription <chr>, StartDate <dttm>
```
