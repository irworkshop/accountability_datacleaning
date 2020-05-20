Kansas Contracts
================
Kiernan Nicholls
2020-05-18 13:06:10

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Download](#download)
  - [Read](#read)
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
  batman, # parse logicals
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

A list of statewide contracts can be obtained from the Kansas Department
of Administration’s [Office of Facilities and Procurement Management
(OFPM)](https://www.admin.ks.gov/offices/ofpm).

## Download

The HTML table of contracts can be requested with `httr::GET()`.

``` r
raw_dir <- dir_create(here("ks", "contracts", "data", "raw"))
ks_get <- GET("https://da.ks.gov/purch/Contracts/Default.aspx/statewide")
ks_table <- html_table(html_nodes(content(ks_get), "table")[[9]])
```

## Read

That HTML table can then be parsed into a data frame of contracts.

``` r
ksc <- ks_table %>%
  as_tibble(.name_repair = make_clean_names) %>% 
  na_if("") %>% 
  mutate(across(ends_with("date"), parse_date, "%m/%d/%Y")) %>% 
  rename(available = political_subdivision_availability) %>% 
  mutate(across(available, to_logical))
```

## Explore

``` r
glimpse(ksc)
#> Rows: 946
#> Columns: 7
#> $ contract_number <chr> "0000000000000000000045232", "0000000000000000000046981", "0000000000000…
#> $ contract_title  <chr> "0000000000000000000045232", "0000000000000000000046981", "0000000000000…
#> $ vendor          <chr> "SNAP ON INCORPORATED DBA SNAP ON INDUSTRIAL DIV OF IDSC HOLDG", "UNIFOR…
#> $ expire_date     <date> 2020-06-30, 2020-10-31, 2024-08-31, 2021-06-29, 2025-04-30, 2025-04-30,…
#> $ agency          <chr> "Department of Administration", "Department of Administration", NA, "Dep…
#> $ contract_type   <chr> "Statewide Optional", "Statewide Optional", "Statewide Optional", "State…
#> $ available       <lgl> TRUE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE…
tail(ksc)
#> # A tibble: 6 x 7
#>   contract_number   contract_title     vendor       expire_date agency     contract_type  available
#>   <chr>             <chr>              <chr>        <date>      <chr>      <chr>          <lgl>    
#> 1 12344AA           Wireless Communic… AT&T MOBILI… 2020-06-30  Departmen… Statewide Man… TRUE     
#> 2 0000000000000000… Wireless Communic… CELLCO PART… 2020-06-30  Departmen… Statewide Opt… TRUE     
#> 3 12317AB           WIRELESS LOCAL AR… AT&T DATACO… 2021-07-31  Departmen… Statewide Opt… TRUE     
#> 4 0000000000000000… Wireless Manageme… WIRELESS WA… 2021-05-31  Departmen… Statewide Opt… TRUE     
#> 5 0000000000000000… Wireless, Data & … T-MOBILE US… 2024-06-30  Departmen… Statewide Man… TRUE     
#> 6 0000000000000000… Wireless, Data & … DISCOUNTCEL… 2024-06-30  Departmen… Statewide Man… TRUE
```
