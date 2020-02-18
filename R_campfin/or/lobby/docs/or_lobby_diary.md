Oregon Lobbying
================
Kiernan Nicholls
2020-02-18 10:30:32

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Missing](#missing)
  - [Duplicates](#duplicates)
  - [Year](#year)
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

The lobbying registration data of Oregon state was obtained by computer
assisted reporting students at the Missouri School of Journalism,
supervised by Prof. David Herzog. Students obtained data via download or
public records request. The dataset is as current as of 2020-02-18.

## Import

``` r
raw_dir <- dir_create(here("or", "lobby", "data", "raw"))
```

``` r
orl <- read_csv(
  file = path(raw_dir, "OREGON_raw.csv"),
  skip = 1,
  col_names = c("period", "pri_biz", "pri_last", "pri_first", "lob_first", 
                "lob_last", "status", "date"),
  col_types = cols(
    .default = col_character(),
    date = col_date_usa()
  )
)
```

## Explore

``` r
head(orl)
#> # A tibble: 6 x 8
#>   period    pri_biz                       pri_last pri_first lob_first lob_last status date      
#>   <chr>     <chr>                         <chr>    <chr>     <chr>     <chr>    <chr>  <date>    
#> 1 2018-2019 Oregon Land Title Association Abbe     Cleve     Milio     Tess     Active 2018-01-04
#> 2 2018-2019 Oregon Land Title Association Abbe     Cleve     Penn      Dale     Active 2018-01-04
#> 3 2018-2019 Oregon Land Title Association Abbe     Cleve     Reeves    Zack     Active 2018-01-04
#> 4 2018-2019 American Beverage Association Abdoli   Elli      Bates     Dan      Active 2018-12-21
#> 5 2018-2019 American Beverage Association Abdoli   Elli      Johnson   Nels     Active 2018-12-24
#> 6 2018-2019 American Beverage Association Abdoli   Elli      Pengilly  Miles    Active 2018-12-24
tail(orl)
#> # A tibble: 6 x 8
#>   period   pri_biz                       pri_last pri_first lob_first  lob_last status   date      
#>   <chr>    <chr>                         <chr>    <chr>     <chr>      <chr>    <chr>    <date>    
#> 1 2018-20… Coos Bay and Yaquina Bay Pil… Zilbert  Todd      Penn       Dale     Active   2018-01-04
#> 2 2018-20… Coos Bay and Yaquina Bay Pil… Zilbert  Todd      Reeves     Zack     Active   2018-01-04
#> 3 2018-20… College of American Patholog… Ziman    Barry     O'Sullivan Patricia Termina… 2018-01-01
#> 4 2018-20… Logos Public Charter School   Zimmerer Sheryl    Chavez     Iris     Active   2018-02-06
#> 5 2018-20… UCB, Inc.                     Zorzoli  Joseph    Cardenas   Natalie  Active   2018-01-01
#> 6 2018-20… SAS Institute Inc.            Zuercher Brian     Hunt       Dave     Active   2019-01-28
glimpse(sample_n(orl, 20))
#> Rows: 20
#> Columns: 8
#> $ period    <chr> "2018-2019", "2018-2019", "2018-2019", "2018-2019", "2018-2019", "2018-2019", …
#> $ pri_biz   <chr> "Oregon Independent Mental Health Professionals", "NAIOP Oregon", "Oregon Envi…
#> $ pri_last  <chr> "Dietlein", "Ross", "Moss", "Rowland", "Duehmig", "Lama", "Halstead", "Stratto…
#> $ pri_first <chr> "Nick", "Kelly", "Ilene", "Rachael", "Robert", "Erin", "Lisa", "Frank", "Genoa…
#> $ lob_first <chr> "Wilson", "Hagedorn", "Durbin", "Bella", "Barber", "Bice", "Warney", "Landauer…
#> $ lob_last  <chr> "JL", "Drew", "Andrea", "Steve", "Doug", "Jordan", "Cassondra", "Mark", "Genoa…
#> $ status    <chr> "Active", "Terminated", "Terminated", "Active", "Active", "Active", "Terminate…
#> $ date      <date> 2018-01-08, 2018-01-02, 2018-01-01, 2018-01-03, 2018-01-02, 2018-08-06, 2019-…
```

## Missing

``` r
col_stats(orl, count_na)
#> # A tibble: 8 x 4
#>   col       class      n      p
#>   <chr>     <chr>  <int>  <dbl>
#> 1 period    <chr>      0 0     
#> 2 pri_biz   <chr>      0 0     
#> 3 pri_last  <chr>      0 0     
#> 4 pri_first <chr>      0 0     
#> 5 lob_first <chr>      0 0     
#> 6 lob_last  <chr>      0 0     
#> 7 status    <chr>      0 0     
#> 8 date      <date>   133 0.0379
```

## Duplicates

``` r
orl <- flag_dupes(orl, everything(), .check = TRUE)
sum(orl$dupe_flag)
#> [1] 26
```

``` r
filter(orl, dupe_flag)
#> # A tibble: 26 x 9
#>    period  pri_biz               pri_last pri_first lob_first lob_last status  date       dupe_flag
#>    <chr>   <chr>                 <chr>    <chr>     <chr>     <chr>    <chr>   <date>     <lgl>    
#>  1 2018-2… Novartis Services, I… Casserly Daniel    Powell    John     Active  2018-01-09 TRUE     
#>  2 2018-2… Novartis Services, I… Casserly Daniel    Powell    John     Active  2018-01-09 TRUE     
#>  3 2018-2… Oregon Life and Heal… Delaney  Justin    Powell    John     Termin… 2019-03-01 TRUE     
#>  4 2018-2… Oregon Life and Heal… Delaney  Justin    Powell    John     Termin… 2019-03-01 TRUE     
#>  5 2018-2… AT&T                  Granger  George    Powell    John     Active  2018-01-17 TRUE     
#>  6 2018-2… AT&T                  Granger  George    Powell    John     Active  2018-01-17 TRUE     
#>  7 2018-2… Consumer Healthcare … Gutierr… Carlos    Powell    John     Active  2018-01-09 TRUE     
#>  8 2018-2… Consumer Healthcare … Gutierr… Carlos    Powell    John     Active  2018-01-09 TRUE     
#>  9 2018-2… Oregon Council for B… Jefferis Heather   Bruske    Cassie   Termin… 2018-01-01 TRUE     
#> 10 2018-2… Oregon Council for B… Jefferis Heather   Bruske    Cassie   Termin… 2018-01-01 TRUE     
#> # … with 16 more rows
```

## Year

``` r
orl <- mutate(orl, year = year(date))
count(orl, year)
#> # A tibble: 4 x 2
#>    year     n
#>   <dbl> <int>
#> 1  2017     6
#> 2  2018  2756
#> 3  2019   612
#> 4    NA   133
```

## Export

``` r
clean_dir <- dir_create(here("or", "lobby", "data", "clean"))
write_csv(
  x = orl,
  path = path(clean_dir, "or_lobby_clean.csv"),
  na = ""
)
```
