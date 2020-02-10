Massachusetts Contributions
================
Kiernan Nicholls
2020-02-10 17:12:28

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
  gluedown, # print markdown
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
raw_dir <- dir_create(here("ma", "contribs", "data", "raw"))
```

``` r
zip_url <- "http://ocpf2.blob.core.windows.net/downloads/data/campaign-finance-reports.zip"
zip_file <- url2path(zip_url, raw_dir) 
mdb_file <- if (!this_file_new(zip_file)) {
  download.file(zip_url, zip_file)
  unzip(zip_file, exdir = raw_dir)
} else {
  dir_ls(raw_dir, regexp = "mdb")
}
```

``` r
mdb_tables <- system2("mdb-tables", args = mdb_file, stdout = TRUE)
mdb_tables <- str_split(mdb_tables, "\\s")[[1]]
md_bullet(mdb_tables)
```

  - vUPLOAD\_MASTER
  - vUPLOAD\_tCURRENT\_ASSETS\_DISPOSED
  - vUPLOAD\_tCURRENT\_BANK\_CREDITS
  - vUPLOAD\_tCURRENT\_CPF9\_DETAIL
  - vUPLOAD\_tCURRENT\_CPF9\_SUMMARIES
  - vUPLOAD\_tCURRENT\_EXPENDITURES
  - vUPLOAD\_tCURRENT\_INKINDS
  - vUPLOAD\_tCURRENT\_LIABILITIES
  - vUPLOAD\_tCURRENT\_R1\_DETAIL
  - vUPLOAD\_tCURRENT\_R1\_SUMMARIES
  - vUPLOAD\_tCURRENT\_RECEIPTS
  - vUPLOAD\_tCURRENT\_SAVINGS
  - vUPLOAD\_tCURRENT\_SUBVENDOR\_ITEMS
  - vUPLOAD\_tCURRENT\_SUBVENDOR\_SUMMARIES
  - 
### Read

``` r
read_mdb <- function(file, table, ...) {
  readr::read_csv(
    file = system2("mdb-export", args = c(file, table), stdout = TRUE),
    ...
  )
}
```

``` r
mac <- read_mdb(
  file = mdb_file,
  table = "vUPLOAD_tCURRENT_RECEIPTS",
  col_types = cols(
    .default = col_character(),
    Date = col_date(),
    Amount = col_double()
  )
)
```

    #>             used  (Mb) gc trigger   (Mb)  max used   (Mb)
    #> Ncells   9270343 495.1   21125534 1128.3  12743136  680.6
    #> Vcells 113785978 868.2  540857303 4126.5 673732596 5140.2

``` r
master <- read_mdb(
  file = mdb_file,
  table = "vUPLOAD_MASTER",
  col_types = cols(
    .default = col_character(),
    Amendment = col_logical(),
    Filing_Date = col_datetime("%m/%d/%y %H:%M:%S"),
    Report_Year = col_integer(),
    Beginning_Date = col_date(),
    Ending_Date = col_date()
  )
)
```

``` r
mac <- inner_join(mac, master, by = "rpt_id")
```

## Explore

``` r
head(mac)
#> # A tibble: 6 x 33
#>   id    rpt_id line  date       cont_type first last  address city  state zip   occupation employer
#>   <chr> <chr>  <chr> <date>     <chr>     <chr> <chr> <chr>   <chr> <chr> <chr> <chr>      <chr>   
#> 1 5358… 39     5358… 2002-01-02 Individu… E.A.  Drake PO Box… Bedf… MA    01730 <NA>       <NA>    
#> 2 5358… 39     5358… 2002-01-02 Individu… Jacq… Mich… 19 Gou… Bedf… MA    <NA>  <NA>       <NA>    
#> 3 5358… 39     5358… 2002-01-02 Individu… Suza… Beale 8 Aspe… Bedf… MA    <NA>  <NA>       <NA>    
#> 4 5358… 39     5358… 2002-01-02 Individu… Will… Beale 8 Aspe… Bedf… MA    <NA>  <NA>       <NA>    
#> 5 5358… 39     5358… 2002-01-02 Individu… Dave  Hema… 1 Heri… Bedf… MA    <NA>  <NA>       <NA>    
#> 6 5358… 39     5358… 2002-01-02 Individu… Trent Fish… 241 Le… Wobu… MA    01801 <NA>       <NA>    
#> # … with 20 more variables: officer <chr>, cont_id <chr>, amount <dbl>, tender <chr>, guid <chr>,
#> #   rpt_year <int>, filing_date <dttm>, start_date <date>, end_date <date>, cpf_id <chr>,
#> #   report_type <chr>, cand_name <chr>, office <chr>, district <chr>, comm_name <chr>,
#> #   comm_city <chr>, comm_state <chr>, comm_zip <chr>, category <chr>, amendment <lgl>
tail(mac)
#> # A tibble: 6 x 33
#>   id    rpt_id line  date       cont_type first last  address city  state zip   occupation employer
#>   <chr> <chr>  <chr> <date>     <chr>     <chr> <chr> <chr>   <chr> <chr> <chr> <chr>      <chr>   
#> 1 1368… 730739 1368… 2019-12-19 OTHER     Dani… Salv… 34a La… Whit… MA    02382 <NA>       <NA>    
#> 2 1368… 730739 1368… 2019-12-19 OTHER     Denn… Chick 36 Lan… Whit… MA    02382 <NA>       <NA>    
#> 3 1368… 730739 1368… 2019-12-23 OTHER     Gerr… Eaton 5 Old … Whit… MA    02382 <NA>       <NA>    
#> 4 1368… 730739 1368… 2019-12-31 OTHER     Joyce Anne… 5 Rebe… Whit… MA    02382 <NA>       <NA>    
#> 5 1368… 730740 1368… 2020-02-08 Individu… Step… Dris… 47 Sho… Pemb… MA    02359 Actor      Self-em…
#> 6 1368… 730740 1368… 2020-02-08 Individu… Jose… Tuti… 76 Bar… Taun… MA    02780 Communica… U.S. Ho…
#> # … with 20 more variables: officer <chr>, cont_id <chr>, amount <dbl>, tender <chr>, guid <chr>,
#> #   rpt_year <int>, filing_date <dttm>, start_date <date>, end_date <date>, cpf_id <chr>,
#> #   report_type <chr>, cand_name <chr>, office <chr>, district <chr>, comm_name <chr>,
#> #   comm_city <chr>, comm_state <chr>, comm_zip <chr>, category <chr>, amendment <lgl>
glimpse(sample_n(mac, 20))
#> Observations: 20
#> Variables: 33
#> $ id          <chr> "5525050", "6720886", "12605049", "9037831", "5608601", "7461900", "12059504…
#> $ rpt_id      <chr> "10275", "68960", "661683", "208741", "14950", "109030", "611669", "188874",…
#> $ line        <chr> "5525050", "6720886", "12605049", "9037831", "5608601", "7461900", "12059504…
#> $ date        <date> 2002-10-24, 2006-09-13, 2018-07-09, 2014-10-04, 2002-09-04, 2010-03-11, 201…
#> $ cont_type   <chr> "OTHER", "Individual", "Individual", "Individual", "Individual", "Individual…
#> $ first       <chr> "SEIU Loc 509 Seg", "RICHARD", "Brian", "Francis", "Richard", "SUZANNE", "Ro…
#> $ last        <chr> "Union", "WAITT", "Cady", "Landry", "Battin", "SUPPA", "Trombley", "Welch", …
#> $ address     <chr> "Post Office Box 509", "3 BUTTERWORTH RD", "50 Atherton St", "159 South Main…
#> $ city        <chr> "Cambridge", "Wilmington", "Roxbury", "Milford", "Lexington", "CAMBRIDGE", "…
#> $ state       <chr> "MA", "MA", "MA", "MA", "MA", "MA", "MA", "MA", "MA", "MA", "MA", "MA", "MA"…
#> $ zip         <chr> "02139", "01887-3841", "02118", "01757", "02421", "02139", "01921-2019", "01…
#> $ occupation  <chr> "Union Segregated Fund", "CIVIL ENGINEER", NA, "corrections officer", "senio…
#> $ employer    <chr> "-------------", "INFO REQ", NA, "Massachusetts Dept of Corrections", "MIT",…
#> $ officer     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ cont_id     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ amount      <dbl> 15000.00, 250.00, 75.00, 5.00, 30.00, 200.00, 500.00, 50.00, 200.00, 150.00,…
#> $ tender      <chr> "Check", "Check", "Check", "Unknown", "Check", "Check", "Unknown", "Unknown"…
#> $ guid        <chr> "{c0dd1523-6227-4b2d-559e-1f456763f279}", "{f9605602-5b0d-4f14-79ad-2a610c95…
#> $ rpt_year    <int> 2002, 2006, 2018, 2014, 2002, 2010, 2016, 2013, 2012, 2011, 2013, 2020, 2013…
#> $ filing_date <dttm> 2002-11-05 12:49:38, 2007-09-04 11:47:27, 2018-07-10 10:01:26, 2014-10-27 1…
#> $ start_date  <date> NA, NA, NA, 2014-08-23, NA, NA, 2016-01-01, 2013-07-01, NA, 2011-07-01, NA,…
#> $ end_date    <date> 2002-10-24, 2006-09-13, 2018-07-09, 2014-10-17, 2002-09-04, 2010-03-11, 201…
#> $ cpf_id      <chr> "30914", "14376", "17006", "80690", "13821", "14376", "11853", "14191", "130…
#> $ report_type <chr> "Deposit Report", "Deposit Report", "Deposit Report", "Pre-election Report (…
#> $ cand_name   <chr> "Shannon P. O'Brien", "Deval L. Patrick", "Edward J. Stamas", "MA Correction…
#> $ office      <chr> "Constitutional", "Constitutional", "Statewide", "Unknown/ N/A", "Constituti…
#> $ district    <chr> "Governor", "Governor", "Auditor", "Unknown/ N/A", "Governor", "Governor", "…
#> $ comm_name   <chr> "The Shannon O'Brien Committee", "The Deval Patrick Committee", "Stamas Comm…
#> $ comm_city   <chr> NA, NA, "North Amherst", "Milford", NA, NA, "Boston", "W. Springfield", NA, …
#> $ comm_state  <chr> NA, NA, "MA", "MA", NA, NA, "MA", "MA", NA, "MA", NA, "MA", "MA", "MA", "MA"…
#> $ comm_zip    <chr> NA, NA, "01059", "01757", NA, NA, "02137", "01090", NA, "01095", NA, "01748"…
#> $ category    <chr> "D", "D", "D", "P", "D", "D", "N", "N", "D", "N", "D", "P", "P", "D", "N", "…
#> $ amendment   <lgl> FALSE, TRUE, FALSE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FA…
```
