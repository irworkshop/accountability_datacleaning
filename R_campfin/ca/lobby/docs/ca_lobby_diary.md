State Data
================
First Last
2019-10-07 13:20:46

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
  stringdist, # levenshtein value
  RSelenium, # remote browser
  tidyverse, # data manipulation
  lubridate, # datetime strings
  magrittr, # pipe opperators
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

### About

### Variables

## Import

### Download

``` r
raw_dir <- here("ca", "lobbying", "data", "raw")
dir_create(raw_dir)
```

``` r
zip_url <- "https://campaignfinance.cdn.sos.ca.gov/dbwebexport.zip"
zip_file <- str_c(raw_dir, basename(zip_url), sep = "/")
```

``` r
if (!this_file_new(zip_file)) {
  download.file(
    url = zip_url,
    destfile = zip_file
  )
}
```

``` r
cal_dir <- dir_ls(raw_dir, recurse = TRUE, type = "directory", glob = "*DATA$")
if (is_empty(cal_dir)) {
  unzip(zip_file, exdir = raw_dir)
  cal_dir <- dir_ls(raw_dir, recurse = TRUE, type = "directory", glob = "*DATA$")
}
```

### Read

``` r
if (packageVersion("vroom") < "1.0.2.9000") {
  warning("vroom version greater than 1.0.2.9000 is needed")
}
```

``` r
cal_conts <- 
  dir_ls(
    path = cal_dir, 
    type = "file", 
    glob = "*LOBBYIST_CONTRIBUTIONS\\d_CD.TSV$"
  ) %>% 
  vroom(
    col_types = cols(
      FILER_ID = col_character(),
      FILING_PERIOD_START_DT = col_date("%m/%d/%Y %H:%M:%S %p"),
      FILING_PERIOD_END_DT = col_date("%m/%d/%Y %H:%M:%S %p"),
      CONTRIBUTION_DT = col_character(),
      RECIPIENT_NAME = col_character(),
      RECIPIENT_ID = col_character(),
      AMOUNT = col_double()
    )
  ) %>% 
  clean_names("snake") %>% 
  remove_empty("cols")
```

``` r
cal <- cal_emp_lob <- 
  dir_ls(
    path = cal_dir, 
    type = "file", 
    glob = "*LOBBYIST_EMP_LOBBYIST\\d_CD.TSV"
  ) %>% 
  vroom(
    col_types = cols(
      .default = col_character(),
      SESSION_ID = col_double()
    )
  ) %>% 
  clean_names("snake")
```

``` r
cal_emp_total <- 
  dir_ls(
    path = cal_dir, 
    type = "file", 
    glob = "*LOBBYIST_EMPLOYER\\d_CD.TSV$"
  ) %>% 
  vroom(
    col_types = cols(
      .default = col_character(),
      CURRENT_QTR_AMT = col_double(),
      SESSION_TOTAL_AMT = col_double(),
      SESSION_YR_1 = col_double(),
      SESSION_YR_2 = col_double(),
      YR_1_YTD_AMT = col_double(),
      YR_2_YTD_AMT = col_double(),
      QTR_1 = col_double(),
      QTR_2 = col_double(),
      QTR_3 = col_double(),
      QTR_4 = col_double(),
      QTR_5 = col_double(),
      QTR_6 = col_double(),
      QTR_7 = col_double(),
      QTR_8 = col_double()
    )
  ) %>% 
  clean_names("snake") %>% 
  remove_empty("cols")
```

``` r
cal_emp_firms <- 
  dir_ls(
    path = cal_dir, 
    type = "file", 
    glob = "*LOBBYIST_EMPLOYER_FIRMS\\d_CD.TSV$"
  ) %>% 
  vroom(
    col_types = cols(
      .default = col_character(),
      SESSION_ID = col_double()
    )
  ) %>% 
  clean_names("snake") %>% 
  remove_empty("cols")
```

``` r
# empty file
cal_lob_hist <- 
dir_ls(
    path = cal_dir, 
    type = "file", 
    glob = "*LOBBYIST_EMPLOYER_HISTORY_CD.TSV$"
  ) %>% 
  file_size()
```

``` r
cal_firm_totals <- 
  dir_ls(
    path = cal_dir, 
    type = "file", 
    glob = "*LOBBYIST_FIRM\\d_CD.TSV$"
  ) %>% 
  vroom(
    col_types = cols(
      .default = col_character(),
      CURRENT_QTR_AMT = col_double(),
      SESSION_TOTAL_AMT = col_double(),
      SESSION_YR_1 = col_double(),
      SESSION_YR_2 = col_double(),
      YR_1_YTD_AMT = col_double(),
      YR_2_YTD_AMT = col_double(),
      QTR_1 = col_double(),
      QTR_2 = col_double(),
      QTR_3 = col_double(),
      QTR_4 = col_double(),
      QTR_5 = col_double(),
      QTR_6 = col_double(),
      QTR_7 = col_double(),
      QTR_8 = col_double()
    )
  ) %>% 
  clean_names("snake")
```

## Explore

``` r
head(cal)
#> # A tibble: 6 x 6
#>   lobbyist_id employer_id lobbyist_last_na… lobbyist_first_n… employer_name              session_id
#>   <chr>       <chr>       <chr>             <chr>             <chr>                           <dbl>
#> 1 1148125     1147032     HORTON            VICTORIA G.       CALIFORNIA BEER & BEVERAG…       1999
#> 2 1148126     1146796     WASHINGTON        WILLIE            CALIFORNIA MANUFACTURERS …       1995
#> 3 1148126     1146796     WASHINGTON        WILLIE            CALIFORNIA MANUFACTURERS …       1997
#> 4 1148126     1146796     WASHINGTON        WILLIE            CALIFORNIA MANUFACTURERS …       1999
#> 5 1148126     1146796     WASHINGTON        WILLIE            CALIFORNIA MANUFACTURERS …       2001
#> 6 1148127     1146810     DOERR             DAVID R.          CALIFORNIA TAXPAYERS' ASS…       1995
tail(cal)
#> # A tibble: 6 x 6
#>   lobbyist_id employer_id lobbyist_last_na… lobbyist_first_n… employer_name              session_id
#>   <chr>       <chr>       <chr>             <chr>             <chr>                           <dbl>
#> 1 1231856     1146953     CIMENT            SCOTT P.          CALIFORNIA ATTORNEYS FOR …       2001
#> 2 1231875     1147199     HUGHES            MICHAEL T.        HUGHES                           2001
#> 3 1231880     1231878     DE MAROIS         SUSAN A.          CALIFORNIA COUNCIL OF THE…       2001
#> 4 1231883     1146926     PECK              JUDY E.           PECK                             2001
#> 5 1231906     1147052     SNYDER            JULIE M.          SNYDER                           2001
#> 6 1231914     1147109     HERNANDEZ         CONSUELO A.       HERNANDEZ                        2001
glimpse(sample_frac(cal))
#> Observations: 3,000
#> Variables: 6
#> $ lobbyist_id         <chr> "1148426", "1149297", "1234328", "1149454", "1148000", "1148426", "1…
#> $ employer_id         <chr> "1146823", "1146794", "1234326", "1146785", "1146874", "1146823", "1…
#> $ lobbyist_last_name  <chr> "GREENE", "ECKS", "MC CULLOUGH", "WANNER", "KILBOURN", "GREENE", "FA…
#> $ lobbyist_first_name <chr> "JAMES P.", "LISA", "DONALD A.", "LINDA", "MICHAEL B.", "JAMES P.", …
#> $ employer_name       <chr> "VERIZON COMMUNICATIONS INC.", "CALIFORNIA LABOR FEDERATION, AFL-CIO…
#> $ session_id          <dbl> 1999, 2001, 2001, 2001, 1997, 1997, 1995, 1995, 1999, 1997, 1997, 20…
```
