Michigan Contributions
================
Kiernan Nicholls
2020-01-29 13:29:27

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)

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
6.  Create a five-digit ZIP Code called `zip`
7.  Create a `year` field from the transaction date
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
  gluedown, # printing markdown
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  rvest, # read html pages
  vroom, # read files fast
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

This data is obtained from the Michigan Board of Elections (BOE)
Campaign Finance Reporting (CFR) system. The data is provided as annual
ZIP archives.

> Record layout of contributions. Files are named by statement year.
> Larger files are split and numbered to make them easier to work with.
> In these cases the column header row will only exist in the first (00)
> file.

| Variable          | Description                                                                                      |
| :---------------- | :----------------------------------------------------------------------------------------------- |
| `doc_seq_no`      | Unique BOE document sequence number of the filed campaign statement                              |
| `page_no`         | If filed on paper, the physical page number the transaction appears on, otherwise zero           |
| `contribution_id` | Unique number of the transaction, within the campaign statement and amendments                   |
| `cont_detail_id`  | Unique number used to further break down some types of transactions with supplemental informati… |
| `doc_stmnt_year`  | The calendar year that this statement was required by the BOE                                    |
| `doc_type_desc`   | The type of statement that this contribution is attached to                                      |
| `com_legal_name`  | Legal Name of the committee receiving the contribution                                           |
| `common_name`     | Commonly known shorter name of the committee. May be deprecated in the future.                   |
| `cfr_com_id`      | Unique committee ID\# of the receiving committee in the BOE database                             |
| `com_type`        | Type of committee receiving the contribution                                                     |
| `can_first_name`  | First name of the candidate (if applicable) benefitting from the contribution                    |
| `can_last_name`   | Last name of the candidate (if applicable) benefitting from the contribution                     |
| `contribtype`     | Type of contribution received                                                                    |
| `f_name`          | First name of the individual contributor                                                         |
| `l_name`          | Last name of the contributor OR the name of the organization that made the contribution          |
| `address`         | Street address of the contributor                                                                |
| `city`            | City of the contributor                                                                          |
| `state`           | State of the contributor                                                                         |
| `zip`             | Zipcode of the contributor                                                                       |
| `occupation`      | Occupation of the contributor                                                                    |
| `employer`        | Employer of the contributor                                                                      |
| `received_date`   | Date the contribution was received                                                               |
| `amount`          | Dollar amount or value of the contribution                                                       |
| `aggregate`       | Cumulative dollar amount of contributions made to this committee during this period up to the d… |
| `extra_desc`      | Extra descriptive information for the transaction                                                |
| `RUNTIME`         | Indicates the time these transactions were exported from the BOE database. Header only.          |

## Import

### Download

``` r
raw_dir <- dir_create(here("mi", "contribs", "data", "raw"))
raw_base <- "https://miboecfr.nictusa.com/cfr/dumpall/cfrdetail/"
raw_page <- read_html(raw_base)
raw_urls <- raw_page %>% 
  html_node("table") %>% 
  html_nodes("a") %>% 
  html_attr("href") %>% 
  str_subset("contributions") %>% 
  str_c(raw_base, ., sep = "/")
raw_paths <- path(raw_dir, basename(raw_urls))
if (!all(this_file_new(raw_paths))) {
  download.file(raw_urls, raw_paths)
}
```
