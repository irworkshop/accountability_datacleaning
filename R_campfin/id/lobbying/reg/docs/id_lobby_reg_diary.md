Idaho Lobbyists
================
Kiernan Nicholls
2019-10-16 14:14:03

<!-- Place comments regarding knitting here -->

## Project

The Accountability Project is an effort to cut across data silos and
give journalists, policy professionals, activists, and the public at
large a simple way to search across huge volumes of public data about
people and organizations.

Our goal is to standardizing public data on a few key fields by thinking
of each dataset row as a transaction. For each transaction there should
be (at least) 3 variables:

1.  All **parties** to a transaction
2.  The **date** of the transaction
3.  The **amount** of money involved

## Objectives

This document describes the process used to complete the following
objectives:

1.  How many records are in the database?
2.  Check for duplicates
3.  Check ranges
4.  Is there anything blank or missing?
5.  Check for consistency issues
6.  Create a five-digit ZIP Code called `ZIP5`
7.  Create a `YEAR` field from the transaction date
8.  Make sure there is data on both parties to a transaction

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
  magrittr, # pipe opperators
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
  readxl, # read excel files
  knitr, # knit documents
  glue, # combine strings
  here, # relative storage
  fs # search storage 
)
```

This document should be run as part of the `R_campfin` project, which
lives as a sub-directory of the more general, language-agnostic
[`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning "TAP repo")
GitHub repository.

The `R_campfin` project uses the [RStudio
projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects "Rproj")
feature and should be run as such. The project also uses the dynamic
`here::here()` tool for file paths relative to *your* machine.

``` r
# where does this document knit?
here::here()
#> [1] "/home/kiernan/R/accountability_datacleaning/R_campfin"
```

## Data

> All registered lobbyists must file financial reports showing the
> totals of all expenditures made by the lobbyist or incurred on behalf
> of such lobbyist‘s employer (not including payments made directly to
> the lobbyist) during the period covered by the report, the totals are
> segregated according to financial category i.e., entertainment, food
> and refreshment, advertising, living accommodations, travel,
> telephone, office expenses, and other expenses or services.

### Download

``` r
raw_dir <- here("id", "lobbying", "reg", "data", "raw")
dir_create(raw_dir)
```

``` r
idlr_base <- "https://sos.idaho.gov/elect/lobbyist"
idlr_urls <- c(
  "https://sos.idaho.gov/elect/lobbyist/2008/08lob_exp.xls",
  "https://sos.idaho.gov/elect/lobbyist/2009/2009_lobbyist_exp.xls",
  "https://sos.idaho.gov/elect/lobbyist/2010/2010_lobbyist_exp.xls",
  "https://sos.idaho.gov/elect/lobbyist/2011/2011_Lob_Exp.xls",
  "https://sos.idaho.gov/elect/lobbyist/2012/2012LobbyistExpensesAnnual.xls",
  "https://sos.idaho.gov/elect/lobbyist/2013/2013LobbyistExpensesAnnual.xlsx",
  "https://sos.idaho.gov/elect/lobbyist/2014/2014LobbyistExpensesAnnual.xlsx",
  "https://sos.idaho.gov/elect/lobbyist/2015/LobbyistExpensesAnnual-2015.xlsx",
  "https://sos.idaho.gov/elect/lobbyist/2016/LobbyistExpensesAnnual-2016.xlsx",
  "https://sos.idaho.gov/elect/lobbyist/2017/LobbyistExpensesAnnual-2017.xlsx",
  "https://sos.idaho.gov/elect/lobbyist/2018/Sorted-By-Lobbyist-2018.xlsx"
)

for (url in idlr_urls) {
  download.file(
    url = url,
    destfile = url2path(url, raw_dir)
  )
}
```

### Read

``` r
idlr <- map_dfr(
  .x = dir_ls(raw_dir),
  .f = read_excel,
  col_types = "text"
)
```
