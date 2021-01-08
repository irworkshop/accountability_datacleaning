Michigan Contracts
================
Kiernan Nicholls
2020-06-18 11:54:49

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
  readxl, # read excel file
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

## Download

``` r
raw_dir <- dir_create(here("mi", "contracts", "data", "raw"))
raw_url <- "https://www.michigan.gov/documents/web_contract_12037_7.xls"
raw_path <- path(raw_dir, basename(raw_url))
download.file(raw_url, raw_path)
raw_sheet <- excel_sheets(raw_path)[2]
```

## Read

``` r
mic <- read_excel(
  path = raw_path,
  sheet = raw_sheet,
  .name_repair = make_clean_names
)
```

``` r
mic <- mic %>% 
  select(-links_to_contracts) %>% 
  mutate(across(expiration_date, as_date)) %>% 
  rename(
    buyer = name,
    vendor = name_2,
    amount = cumulative_amount,
    expire = expiration_date
  )
```

## Explore

``` r
glimpse(mic)
#> Rows: 1,456
#> Columns: 7
#> $ contract_number <chr> "231B7700029", "231B7700021", "200000000679", "200000000675", "200000000…
#> $ buyer           <chr> NA, NA, NA, NA, NA, "Jarrod Barron", "Douglas Glaser", "Douglas Glaser",…
#> $ agency          <chr> "Department Of State", "Department Of State", "Michigan Department of Tr…
#> $ vendor          <chr> NA, NA, NA, NA, NA, "KUNZ LEIGH & ASSOCIATES INC", "U S BANCORP GOVERNME…
#> $ description     <chr> "#187 - N. Genesee County Plus - 4256 W. Vienna Rd.", "#226 - Lansing Ar…
#> $ amount          <dbl> 43348, 40998, 225875, 351765, 170100, 3032540, 2806541, 5733672, 5005000…
#> $ expire          <date> 2022-07-31, 2022-05-31, 2023-04-20, 2023-04-19, 2023-04-19, 2021-11-01,…
tail(mic)
#> # A tibble: 6 x 7
#>   contract_number buyer agency            vendor          description             amount expire    
#>   <chr>           <chr> <chr>             <chr>           <chr>                    <dbl> <date>    
#> 1 591180000000079 <NA>  Michigan Departm… <NA>            Winter Maintenance for… 1.38e6 2020-10-29
#> 2 200000000034    <NA>  Michigan Departm… TRUCK & TRAILE… Winter Maintenance Tru… 1.00e7 2024-11-30
#> 3 751180000000322 <NA>  Department of Na… <NA>            Wireless Guest Service… 3.35e4 2021-01-31
#> 4 591180000000635 <NA>  Michigan Departm… J. RANCK ELECT… Wiring and other Eletr… 1.15e5 2021-04-30
#> 5 472180000000388 <NA>  Michigan Departm… <NA>            Women's Undergarments … 3.50e5 2021-02-22
#> 6 472180000001231 <NA>  Michigan Departm… <NA>            Workbooks and Training… 4.05e5 2021-09-24
```

### Missing

``` r
col_stats(mic, count_na)
#> # A tibble: 7 x 4
#>   col             class      n        p
#>   <chr>           <chr>  <int>    <dbl>
#> 1 contract_number <chr>      0 0       
#> 2 buyer           <chr>    660 0.453   
#> 3 agency          <chr>      0 0       
#> 4 vendor          <chr>    545 0.374   
#> 5 description     <chr>      0 0       
#> 6 amount          <dbl>      1 0.000687
#> 7 expire          <date>     0 0
```

``` r
mic <- mic %>% flag_na(expire, agency, amount, vendor)
sum(mic$na_flag)
#> [1] 545
```

``` r
mic %>% 
  filter(na_flag) %>% 
  select(expire, agency, amount, vendor)
#> # A tibble: 545 x 4
#>    expire     agency                                          amount vendor
#>    <date>     <chr>                                            <dbl> <chr> 
#>  1 2022-07-31 Department Of State                              43348 <NA>  
#>  2 2022-05-31 Department Of State                              40998 <NA>  
#>  3 2023-04-20 Michigan Department of Transportation           225875 <NA>  
#>  4 2023-04-19 Michigan Department of Transportation           351765 <NA>  
#>  5 2023-04-19 Michigan Department of Transportation           170100 <NA>  
#>  6 2020-09-30 Michigan State Police                           134940 <NA>  
#>  7 2020-11-15 Department of Agriculture and Rural Development 204915 <NA>  
#>  8 2020-08-15 Michigan Department of Treasury                 200000 <NA>  
#>  9 2020-07-10 Department Technology, Management and Budget    490000 <NA>  
#> 10 2023-04-23 Department of Natural Resources                  50000 <NA>  
#> # … with 535 more rows
```

### Duplicates

``` r
mic <- flag_dupes(mic, -contract_number)
sum(mic$dupe_flag)
#> [1] 16
```

``` r
mic %>% 
  filter(dupe_flag) %>% 
  select(expire, agency, amount, vendor)
#> # A tibble: 16 x 4
#>    expire     agency                                        amount vendor           
#>    <date>     <chr>                                          <dbl> <chr>            
#>  1 2022-06-30 Department of Natural Resources               499000 <NA>             
#>  2 2022-06-30 Department of Natural Resources               499000 <NA>             
#>  3 2021-02-28 Department of Insurance and Financial Service 180000 <NA>             
#>  4 2021-02-28 Department of Insurance and Financial Service 180000 <NA>             
#>  5 2021-02-28 Department of Insurance and Financial Service 180000 <NA>             
#>  6 2021-02-28 Department of Insurance and Financial Service 180000 <NA>             
#>  7 2021-02-28 Department of Insurance and Financial Service 180000 <NA>             
#>  8 2024-03-14 Department Technology, Management and Budget   90000 SEQIRUS USA, INC.
#>  9 2024-03-14 Department Technology, Management and Budget   90000 SEQIRUS USA, INC.
#> 10 2021-09-30 Department of Insurance and Financial Service 300000 <NA>             
#> 11 2021-09-30 Department of Insurance and Financial Service 300000 <NA>             
#> 12 2021-09-30 Department of Insurance and Financial Service 300000 <NA>             
#> 13 2020-07-31 Department of Military and Veterans Affairs   886800 <NA>             
#> 14 2020-07-31 Department of Military and Veterans Affairs   886800 <NA>             
#> 15 2021-03-31 Department of Military and Veterans Affairs   901515 <NA>             
#> 16 2021-03-31 Department of Military and Veterans Affairs   901515 <NA>
```

### Categorical

``` r
col_stats(mic, n_distinct)
#> # A tibble: 9 x 4
#>   col             class      n       p
#>   <chr>           <chr>  <int>   <dbl>
#> 1 contract_number <chr>   1455 0.999  
#> 2 buyer           <chr>     24 0.0165 
#> 3 agency          <chr>     23 0.0158 
#> 4 vendor          <chr>    689 0.473  
#> 5 description     <chr>   1162 0.798  
#> 6 amount          <dbl>   1169 0.803  
#> 7 expire          <date>   386 0.265  
#> 8 na_flag         <lgl>      2 0.00137
#> 9 dupe_flag       <lgl>      2 0.00137
```

``` r
count(mic, agency, sort = TRUE)
#> # A tibble: 23 x 2
#>    agency                                               n
#>    <chr>                                            <int>
#>  1 Michigan Department of Transportation              207
#>  2 Department Technology, Management and Budget       156
#>  3 Michigan Department of Health and Human Services   144
#>  4 Michigan Department of Corrections                 134
#>  5 Department of Natural Resources                    130
#>  6 Statewide                                          118
#>  7 Multiple                                            91
#>  8 Department of Military and Veterans Affairs         86
#>  9 Department Of State                                 78
#> 10 Michigan Department of Education                    67
#> # … with 13 more rows
```

### Amounts

``` r
summary(mic$amount)
#>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max.      NA's 
#> 0.000e+00 1.408e+05 6.466e+05 4.580e+07 4.402e+06 1.098e+10         1
mean(mic$amount <= 0, na.rm = TRUE)
#> [1] 0.0137457
```

![](../plots/hist_amount-1.png)<!-- -->

### Dates

We can add the calendar year from `date` with `lubridate::year()`

``` r
mic <- mutate(mic, year = year(expire))
unique(mic$year)
#>  [1] 2022 2023 2021 2020 2024 2025 2026 2029 2028 2027 2030
```

``` r
min(mic$expire)
#> [1] "2020-06-16"
sum(mic$year < 2020)
#> [1] 0
max(mic$expire)
#> [1] "2030-06-01"
sum(mic$expire > today())
#> [1] 1455
```

![](../plots/bar_year-1.png)<!-- -->

## Conclude

1.  There are 1,456 records in the database.
2.  There are 16 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 545 records missing key variables.
5.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("mi", "contracts", "data", "clean"))
clean_path <- path(clean_dir, "mi_contracts_clean.csv")
write_csv(mic, clean_path, na = "")
file_size(clean_path)
#> 221K
file_encoding(clean_path) %>% 
  mutate(across(path, path.abbrev))
#> # A tibble: 1 x 3
#>   path                                             mime            charset
#>   <chr>                                            <chr>           <chr>  
#> 1 ~/mi/contracts/data/clean/mi_contracts_clean.csv application/csv utf-8
```

## Upload

Using the [duckr](https://github.com/kiernann/duckr) R package, we can
wrap around the [duck](https://duck.sh/) command line tool to upload the
file to the IRW server.

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

| Column            | Type        | Definition                     |
| :---------------- | :---------- | :----------------------------- |
| `contract_number` | `character` | Unique contract number         |
| `buyer`           | `character` | Purchasing buyer name          |
| `agency`          | `character` | Purchasing agency name         |
| `vendor`          | `character` | Supplying vendor name          |
| `description`     | `character` | Contract description           |
| `amount`          | `double`    | Cumulative contract amount     |
| `expire`          | `double`    | Contract expiration date       |
| `na_flag`         | `logical`   | Flag indicating missing values |
| `dupe_flag`       | `logical`   | Flag indicating duplicate rows |
| `year`            | `double`    | Calendar year contract expires |
