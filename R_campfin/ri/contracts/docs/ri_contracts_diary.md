Rhode Island Contracts
================
Kiernan Nicholls
2020-05-29 14:27:26

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Download](#download)
  - [Read](#read)
  - [Explore](#explore)
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

Rhode Island contracts data can be obtained from the [transparency
portal](http://www.transparency.ri.gov/contracts/). The portal only
lists contracts over $1 million.

> RI Purchasing Awards over $1M - (Since July 1, 2012)  
> Use this form to search awarded bids.

## Download

Using `httr::POST()`, we can submit and empty search query.

``` r
ri_post <- POST(
  url = "http://www.transparency.ri.gov/contracts/verify.php",
  query = list(
    bidno = "",
    vendname = "",
    start_date = "",
    end_date = "",
    agencyName = "0",
    Submited = "True",
    submit = "Search"
  )
)
```

## Read

This query returns an HTML page which can be scraped with
`rvest::html_table()`.

``` r
ric <- ri_post %>% 
  content() %>% 
  html_node("table") %>% 
  html_table() %>% 
  as_tibble() %>% 
  clean_names() %>% 
  na_if("N/A") %>% 
  mutate(across(date, mdy)) %>% 
  mutate(across(amount, parse_number))
```

## Explore

``` r
glimpse(ric)
#> Rows: 567
#> Columns: 7
#> $ po_no       <int> 3578947, 3400284, 3676476, 3652019, 3648722, 3675747, 3645828, 3645584, 3644…
#> $ bid_no      <chr> NA, "COOP-19", "7599794", "7598903", "7598902", "7598885", "7598875", "75988…
#> $ vendor_name <chr> "SSL HOLDCO LLC", "NCS PEARSON INC", "LOCAL INITIATIVES SUPPORT CORPORATION"…
#> $ date        <date> 2018-07-23, 2014-10-29, 2020-05-06, 2019-10-21, 2019-09-30, 2020-04-29, 201…
#> $ agency      <chr> "Higher Education, Board Of Governors For", "Elementary And Secondary Educat…
#> $ description <chr> "RINEC OPERATING EXPENSES JULY 2018 - JUNE 2019 - HE", "PARCC OPERATIONAL AS…
#> $ amount      <dbl> 1287671, 9190147, 2585911, 2074000, 1469311, 1419708, 1885958, 2799752, 2074…
tail(ric)
#> # A tibble: 6 x 7
#>     po_no bid_no  vendor_name          date       agency             description             amount
#>     <int> <chr>   <chr>                <date>     <chr>              <chr>                    <dbl>
#> 1 3481275 3481275 SKILLS FOR RHODE IS… 2016-08-19 Labor And Trainin… SKILLS FOR RHODE ISLAN… 1.45e6
#> 2 3480025 3480025 RHODE ISLAND PARENT… 2016-08-12 Health, Departmen… Diabetes Prevention Pr… 2.03e6
#> 3 3478742 3478742 MOTOROLA SOLUTIONS … 2016-08-03 RI Emergency Mana… PURCHASE AND INSTALLAT… 1.99e6
#> 4 3476686 3476686 MERCK SHARP & DOHME… 2016-07-26 Health, Departmen… PREVNAR 13 (PCV 13-Ad)… 3.27e6
#> 5 3471565 3471565 RI HOUSING & MORTGA… 2016-06-24 Behavioral Health… RICAP THRESHOLD FUNDIN… 1.00e6
#> 6 3438613 3438613 APPLIED MANAGEMENT … 2015-09-28 Behavioral Health… ESH HOSPITAL MANAGEMEN… 4.68e6
```

### Missing

There is only 1 mission value in the entire database.

``` r
col_stats(ric, count_na)
#> # A tibble: 7 x 4
#>   col         class      n       p
#>   <chr>       <chr>  <int>   <dbl>
#> 1 po_no       <int>      0 0      
#> 2 bid_no      <chr>      1 0.00176
#> 3 vendor_name <chr>      0 0      
#> 4 date        <date>     0 0      
#> 5 agency      <chr>      0 0      
#> 6 description <chr>      0 0      
#> 7 amount      <dbl>      0 0
```

### Duplicates

There are no duplicate records in the databse.

``` r
ric <- flag_dupes(ric, everything())
#> Warning in flag_dupes(ric, everything()): no duplicate rows, column not created
```

### Categorical

``` r
col_stats(ric, n_distinct)
#> # A tibble: 7 x 4
#>   col         class      n      p
#>   <chr>       <chr>  <int>  <dbl>
#> 1 po_no       <int>    567 1     
#> 2 bid_no      <chr>    480 0.847 
#> 3 vendor_name <chr>    221 0.390 
#> 4 date        <date>   385 0.679 
#> 5 agency      <chr>     24 0.0423
#> 6 description <chr>    556 0.981 
#> 7 amount      <dbl>    483 0.852
```

Most of the contract records in this database are made from the Rhode
Island Department of Transportation, probably due to the $1 million
floor.

``` r
explore_plot(ric, agency) + scale_x_truncate()
```

![](../plots/distinct_plots-1.png)<!-- -->

### Amounts

We can also confirm this floor with the `amount` value.

``` r
noquote(map_chr(summary(ric$amount), dollar))
#>         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
#>   $1,000,000   $1,708,689   $2,741,280   $7,524,369   $6,000,000 $380,000,000
mean(ric$amount <= 0)
#> [1] 0
```

![](../plots/hist_amount-1.png)<!-- -->

### Dates

We can add the calendar year from `date` with `lubridate::year()`

``` r
ric <- mutate(ric, year = year(date))
```

The date range is extremelly clean.

``` r
min(ric$date)
#> [1] "2012-07-03"
sum(ric$year < 2000)
#> [1] 0
max(ric$date)
#> [1] "2020-05-06"
sum(ric$date > today())
#> [1] 0
```

![](../plots/bar_year-1.png)<!-- -->

## Conclude

1.  There are 567 records in the database.
2.  There are 0 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 0 records missing key variables.
5.  There are no geographic variables to normalize.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("ri", "contracts", "data", "clean"))
clean_path <- path(clean_dir, "ri_contracts_clean.csv")
write_csv(ric, clean_path, na = "")
file_size(clean_path)
#> 85.6K
mutate(file_encoding(clean_path), across(path, path.abbrev))
#> # A tibble: 1 x 3
#>   path                                             mime            charset 
#>   <chr>                                            <chr>           <chr>   
#> 1 ~/ri/contracts/data/clean/ri_contracts_clean.csv application/csv us-ascii
```

## Upload

Using the duckr R package, we can wrap around the \[duck\] commnand line
tool to upload the file to the IRW S3 server.

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

| Column        | Type        | Definition            |
| :------------ | :---------- | :-------------------- |
| `po_no`       | `integer`   | Purchase order number |
| `bid_no`      | `character` | Bid number            |
| `vendor_name` | `character` | Vendor name           |
| `date`        | `double`    | Contract award date   |
| `agency`      | `character` | Awarding agency       |
| `description` | `character` | Contract description  |
| `amount`      | `double`    | Contract amount       |
| `year`        | `double`    | Contract award year   |
