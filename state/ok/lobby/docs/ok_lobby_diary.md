Oklahoma Lobbying
================
Kiernan Nicholls
2020-02-18 10:41:21

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
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
  readxl, # read excel files
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

``` r
raw_dir <- dir_create(here("ok", "lobby", "data", "raw"))
```

``` r
okl <- read_excel(
  path = path(raw_dir, "OK_lobbyreports.xlsx"),
  skip = 1,
  col_names = c("pri_name", "lob_name", "status")
)
```

## Explore

``` r
head(okl)
#> # A tibble: 6 x 3
#>   pri_name       lob_name              status    
#>   <chr>          <chr>                 <chr>     
#> 1 <NA>           STOWERS, KYLIE M'LYNN Terminated
#> 2 1-800 CONTACTS WATSON, LARITA DAWN   Active    
#> 3 1-800 CONTACTS SNYDER, MARK          Active    
#> 4 1-800 CONTACTS NICHOLS, ROBERT MARK  Active    
#> 5 1-800 CONTACTS SCHILLIGO, NICK       Terminated
#> 6 1-800 CONTACTS CASTANEDA, ERIK       Active
tail(okl)
#> # A tibble: 6 x 3
#>   pri_name                               lob_name              status    
#>   <chr>                                  <chr>                 <chr>     
#> 1 XCALIBER INTERNATIONAL LTD., L.L.C.    MAXWELL, MICHAEL D    Active    
#> 2 XCALIBER INTERNATIONAL LTD., L.L.C.    PATTEN, DANIEL FARLEY Active    
#> 3 YOU IMPACT CAPITAL AND MANAGEMENT, LLC POWELL, ROBERT TYLER  Active    
#> 4 YOUTH VILLAGES, INC.                   BLOOD, HALEY          Active    
#> 5 YOUTH VILLAGES, INC.                   ADKINS, DENNIS        Active    
#> 6 YOUTH VILLAGES, INC.                   SMITH, LYNN GOLD      Terminated
glimpse(sample_n(okl, 20))
#> Rows: 20
#> Columns: 3
#> $ pri_name <chr> "HISTORICAL SOCIETY, OKLAHOMA BOARD OF DIRECTORS", "UNITED HEALTHCARE SERVICES,…
#> $ lob_name <chr> "DICKSON, KATHY", "BUNTEN, BRIAN", "ENGEN, RACHELLE", "FRIED, JIM", "BARNHOUSE,…
#> $ status   <chr> "Terminated", "Active", "Active", "Terminated", "Active", "Active", "Non-Renewe…
```

### Missing

``` r
col_stats(okl, count_na)
#> # A tibble: 3 x 4
#>   col      class     n        p
#>   <chr>    <chr> <int>    <dbl>
#> 1 pri_name <chr>     1 0.000424
#> 2 lob_name <chr>     0 0       
#> 3 status   <chr>     0 0
```

### Duplicates

``` r
okl <- flag_dupes(okl, everything(), .check = TRUE)
sum(okl$dupe_flag)
#> [1] 14
```

``` r
filter(okl, dupe_flag)
#> # A tibble: 14 x 4
#>    pri_name                                           lob_name                 status     dupe_flag
#>    <chr>                                              <chr>                    <chr>      <lgl>    
#>  1 AMERICANS UNITED FOR SEPARATION OF CHURCH AND STA… SINGH, AMRITA            Terminated TRUE     
#>  2 AMERICANS UNITED FOR SEPARATION OF CHURCH AND STA… SINGH, AMRITA            Terminated TRUE     
#>  3 ASSOCIATION OF PROFESSIONAL OKLAHOMA EDUCATORS     FURLONG, CARMEN THOMPSON Terminated TRUE     
#>  4 ASSOCIATION OF PROFESSIONAL OKLAHOMA EDUCATORS     FURLONG, CARMEN THOMPSON Terminated TRUE     
#>  5 CHILDREN & YOUTH, COMMISSION ON                    SMITH, LISA              Terminated TRUE     
#>  6 CHILDREN & YOUTH, COMMISSION ON                    SMITH, LISA              Terminated TRUE     
#>  7 OKLAHOMA MUNICIPAL LEAGUE                          DEAN, MELISSA            Terminated TRUE     
#>  8 OKLAHOMA MUNICIPAL LEAGUE                          DEAN, MELISSA            Terminated TRUE     
#>  9 OKLAHOMA OPTOMETRIC ASSOCIATION                    GOODWIN, CAROL           Terminated TRUE     
#> 10 OKLAHOMA OPTOMETRIC ASSOCIATION                    GOODWIN, CAROL           Terminated TRUE     
#> 11 REINSURANCE ASSOCIATION OF AMERICA                 KERNS, ADAM E            Non-Renew… TRUE     
#> 12 REINSURANCE ASSOCIATION OF AMERICA                 KERNS, ADAM E            Non-Renew… TRUE     
#> 13 WAL-MART STORES, INC.                              MCEWEN, KEILI            Terminated TRUE     
#> 14 WAL-MART STORES, INC.                              MCEWEN, KEILI            Terminated TRUE
```

### Categorical

``` r
col_stats(okl, n_distinct)
#> # A tibble: 4 x 4
#>   col       class     n        p
#>   <chr>     <chr> <int>    <dbl>
#> 1 pri_name  <chr>  1103 0.467   
#> 2 lob_name  <chr>  1044 0.442   
#> 3 status    <chr>     3 0.00127 
#> 4 dupe_flag <lgl>     2 0.000847
```

## Export

``` r
clean_dir <- dir_create(here("ok", "lobby", "data", "clean"))
write_csv(
  x = okl,
  path = path(clean_dir, "ok_lobby_clean.csv"),
  na = ""
)
```
