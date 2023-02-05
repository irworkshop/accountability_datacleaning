District Of Columbia Contracts
================
Kiernan Nicholls
2023-01-19 13:45:27

- <a href="#project" id="toc-project">Project</a>
- <a href="#objectives" id="toc-objectives">Objectives</a>
- <a href="#packages" id="toc-packages">Packages</a>
- <a href="#data" id="toc-data">Data</a>
- <a href="#read" id="toc-read">Read</a>
- <a href="#explore" id="toc-explore">Explore</a>
- <a href="#wrangle" id="toc-wrangle">Wrangle</a>
- <a href="#conclude" id="toc-conclude">Conclude</a>
- <a href="#export" id="toc-export">Export</a>
- <a href="#upload" id="toc-upload">Upload</a>
- <a href="#dictionary" id="toc-dictionary">Dictionary</a>

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
#> [1] "/home/kiernan/Documents/accountability_datacleaning"
```

## Data

A list of contracts by fiscal year can be obtained from the District of
Columbia [Contracts and Procurement Transparency
Portal](https://contracts.ocp.dc.gov/contracts/search). A search can be
run for results by fiscal years 2016 through 2021. This search can then
be exported as a single CSV file which we can read into R. The same
thing can be done on the [purchase orders
portal](https://contracts.ocp.dc.gov/purchase/search).

## Read

``` r
raw_dir <- dir_create(here("state", "dc", "contracts", "data", "raw"))
```

First, we will read the contract awards file.

``` r
dcc <- read_delim(
  file = path(raw_dir, "ContractAwards.csv"),
  delim = ",",
  locale = locale(date_format = "%m/%d/%Y"),
  col_types = cols(
    .default = col_character(),
    `Start Date` = col_date(),
    `End Date` = col_date(),
    `Award Date` = col_date(),
    `Amount` = col_number()
  )
)
```

Then the we will read the purchase orders file.

``` r
dcp <- read_delim(
  file = path(raw_dir, "PurchaseOrders.csv"),
  delim = ",",
  locale = locale(date_format = "%m/%d/%Y"),
  col_types = cols(
    .default = col_character(),
    `Total Amount` = col_number(),
    `Order Date` = col_date(),
  )
)
```

``` r
dcc <- clean_names(dcc)
dcp <- clean_names(dcp)
```

After making some column names match, the two data frames can be bound
together into a single data frame. For contracts, the `award_date` will
be used as a single date, paired with the `order_date` for purchase
orders. The purchase order `total_amount` will be paired with the
contract’s single `amount`.

``` r
dcc <- rename(
  .data = dcc,
  id = contract_number,
  vendor = vendor_supplier,
  date = award_date
)
```

``` r
dcp <- rename(
  .data = dcp,
  amount = total_amount,
  id = po_number,
  vendor = vendor_supplier,
  date = order_date
)
```

After the two data frames are bound together, columns not found in both
files (e.g., a contract’s `start_date`) will be filed with `NA` for
records from the other data type.

``` r
dcc <- bind_rows(contract = dcc, purchase = dcp, .id = "type")
```

## Explore

``` r
glimpse(dcc)
#> Rows: 48,570
#> Columns: 12
#> $ type          <chr> "contract", "contract", "contract", "contract", "contract", "contract", "co…
#> $ id            <chr> "CW101973", "CW88650", "CW103406", "CW103544", "CW88310", "CW103686", "CW64…
#> $ title         <chr> "Residential Expenses - Wholistic Home & Community Based Services, Inc.", "…
#> $ agency        <chr> "Department on Disability Services (DDS)", "Employment Services (DOES)", NA…
#> $ option_period <chr> "Base Period", "Option 2", "Base Period", "Base Period", "Option 2", "Base …
#> $ start_date    <date> 2023-03-01, 2023-01-13, 2023-01-11, 2023-01-10, 2023-01-08, 2023-01-04, 20…
#> $ end_date      <date> 2024-02-29, 2024-01-12, 2024-01-10, 2024-01-09, 2024-01-07, 2024-01-03, 20…
#> $ date          <date> 2022-08-30, 2021-01-13, 2022-10-25, 2023-01-10, 2021-01-08, 2023-01-04, 20…
#> $ nigp_code     <chr> "9529265", "9247835", "4750540", "9585040", "7159020", "9626941", "9241900"…
#> $ vendor        <chr> "WHOLISTIC HOME AND COMMUNITY", "Constituent Services Worldwide Public Bene…
#> $ amount        <dbl> 1294653.8, 250000.0, 500000.0, 428800.1, 20500.0, 950000.0, 500000.0, 85000…
#> $ fiscal_year   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
tail(dcc)
#> # A tibble: 6 × 12
#>   type    id    title agency optio…¹ start_date end_date date       nigp_code vendor amount fisca…²
#>   <chr>   <chr> <chr> <chr>  <chr>   <date>     <date>   <date>     <chr>     <chr>   <dbl> <chr>  
#> 1 purcha… PO63… <NA>  Small… <NA>    NA         NA       2020-10-01 9614400   H STR… 1.50e5 FY2021 
#> 2 purcha… PO63… <NA>  Small… <NA>    NA         NA       2020-10-01 9614400   NORTH… 1.24e5 FY2021 
#> 3 purcha… PO63… <NA>  Small… <NA>    NA         NA       2020-10-01 9614400   CAREE… 1.08e5 FY2021 
#> 4 purcha… PO63… <NA>  Child… <NA>    NA         NA       2020-10-01 9621600   RHG G… 5.76e4 FY2021 
#> 5 purcha… PO63… <NA>  Attor… <NA>    NA         NA       2020-10-01 6008056   PITNE… 1.05e5 FY2021 
#> 6 purcha… PO63… <NA>  Metro… <NA>    NA         NA       2020-10-01 9204531   FILEO… 5.60e4 FY2021 
#> # … with abbreviated variable names ¹​option_period, ²​fiscal_year
```

### Missing

There are a handful of records missing a name or date needed to properly
identify a transaction, mostly the agency name.

``` r
col_stats(dcc, count_na)
#> # A tibble: 12 × 4
#>    col           class      n        p
#>    <chr>         <chr>  <int>    <dbl>
#>  1 type          <chr>      0 0       
#>  2 id            <chr>      0 0       
#>  3 title         <chr>  46360 0.954   
#>  4 agency        <chr>    222 0.00457 
#>  5 option_period <chr>  46360 0.954   
#>  6 start_date    <date> 46360 0.954   
#>  7 end_date      <date> 46360 0.954   
#>  8 date          <date>     0 0       
#>  9 nigp_code     <chr>     19 0.000391
#> 10 vendor        <chr>      0 0       
#> 11 amount        <dbl>      0 0       
#> 12 fiscal_year   <chr>   2210 0.0455
```

These records can be flagged with `campfin::flag_na()`.

``` r
dcc <- dcc %>% flag_na(date, vendor, amount, agency)
percent(mean(dcc$na_flag), 0.01)
#> [1] "0.46%"
```

``` r
dcc %>% 
  filter(na_flag) %>% 
  select(date, vendor, amount, agency, type)
#> # A tibble: 222 × 5
#>    date       vendor                                                            amount agency type 
#>    <date>     <chr>                                                              <dbl> <chr>  <chr>
#>  1 2022-10-25 BOCALJE SERVICES, INC.                                             5  e5 <NA>   cont…
#>  2 2023-01-04 A Digital Solutions Inc.                                           9.5e5 <NA>   cont…
#>  3 2019-01-03 Center for Innovation, Research, and Transformation in Education   5  e5 <NA>   cont…
#>  4 2022-12-19 Calvin Price Group                                                 9  e5 <NA>   cont…
#>  5 2022-12-15 Lincoln Square Group                                               9.5e5 <NA>   cont…
#>  6 2022-12-09 Deon Samad LLC                                                     9.5e5 <NA>   cont…
#>  7 2021-12-01 Chaise Management Group, LLC                                       9.5e5 <NA>   cont…
#>  8 2019-11-28 V TECH SOLUTIONS INC                                               1  e7 <NA>   cont…
#>  9 2017-11-16 The Robert Bobb Group LLC                                          7.5e5 <NA>   cont…
#> 10 2022-07-15 Engineering Project Management Construction Management Consultin…  9  e5 <NA>   cont…
#> # … with 212 more rows
```

### Duplicates

Ignoring the `id` variable, there are a handful of completely duplicated
records. These can be flagged with `campfin::flag_dupes()`.

``` r
dcc <- flag_dupes(dcc, -id)
percent(mean(dcc$dupe_flag), 0.01)
#> [1] "2.81%"
```

``` r
dcc %>% 
  filter(dupe_flag) %>% 
  select(date, vendor, amount, agency, type) %>% 
  arrange(date)
#> # A tibble: 1,366 × 5
#>    date       vendor                        amount agency                                     type 
#>    <date>     <chr>                          <dbl> <chr>                                      <chr>
#>  1 2020-10-01 BRAILSFORD & DUNLAVEY, INC.    34000 General Services (DGS)                     purc…
#>  2 2020-10-01 BRAILSFORD & DUNLAVEY, INC.    34000 General Services (DGS)                     purc…
#>  3 2020-10-01 KBEC GROUP  INC.                   0 Department on Disability Services (DDS)    purc…
#>  4 2020-10-01 KBEC GROUP  INC.                   0 Department on Disability Services (DDS)    purc…
#>  5 2020-10-01 EDUCATIONAL NETWORKS  INC       3060 District of Columbia Public Schools (DCPS) purc…
#>  6 2020-10-01 SAVING OUR NEXT GENERATION    100000 Small and Local Business Development (DSL… purc…
#>  7 2020-10-01 SAVING OUR NEXT GENERATION    100000 Small and Local Business Development (DSL… purc…
#>  8 2020-10-01 SAVING OUR NEXT GENERATION    100000 Small and Local Business Development (DSL… purc…
#>  9 2020-10-01 EAST RIVER FAMILY STRENGTHENG 325000 Child and Family Services Agency (CFSA)    purc…
#> 10 2020-10-01 EAST RIVER FAMILY STRENGTHENG 325000 Child and Family Services Agency (CFSA)    purc…
#> # … with 1,356 more rows
```

### Categorical

``` r
col_stats(dcc, n_distinct)
#> # A tibble: 14 × 4
#>    col           class      n         p
#>    <chr>         <chr>  <int>     <dbl>
#>  1 type          <chr>      2 0.0000412
#>  2 id            <chr>  48024 0.989    
#>  3 title         <chr>   1675 0.0345   
#>  4 agency        <chr>    114 0.00235  
#>  5 option_period <chr>     19 0.000391 
#>  6 start_date    <date>   663 0.0137   
#>  7 end_date      <date>   670 0.0138   
#>  8 date          <date>  1211 0.0249   
#>  9 nigp_code     <chr>   3628 0.0747   
#> 10 vendor        <chr>   7275 0.150    
#> 11 amount        <dbl>  27864 0.574    
#> 12 fiscal_year   <chr>      4 0.0000824
#> 13 na_flag       <lgl>      2 0.0000412
#> 14 dupe_flag     <lgl>      2 0.0000412
```

``` r
add_prop(count(dcc, agency, sort = TRUE))
#> # A tibble: 114 × 3
#>    agency                                         n      p
#>    <chr>                                      <int>  <dbl>
#>  1 District of Columbia Public Schools (DCPS)  6849 0.141 
#>  2 General Services (DGS)                      3870 0.0797
#>  3 Commission on Arts and Humanities (CAH)     2992 0.0616
#>  4 Chief Technology Officer (OCTO)             2471 0.0509
#>  5 Behavioral Health (DBH)                     2236 0.0460
#>  6 Health (DOH)                                2184 0.0450
#>  7 Health Care Finance (DHCF)                  1606 0.0331
#>  8 Attorney General (OAG)                      1601 0.0330
#>  9 Department on Disability Services (DDS)     1525 0.0314
#> 10 Employment Services (DOES)                  1389 0.0286
#> # … with 104 more rows
add_prop(count(dcc, option_period, sort = TRUE))
#> # A tibble: 19 × 3
#>    option_period                          n         p
#>    <chr>                              <int>     <dbl>
#>  1 <NA>                               46360 0.954    
#>  2 Base Period                          870 0.0179   
#>  3 Option 1                             405 0.00834  
#>  4 Option 2                             374 0.00770  
#>  5 Option 3                             286 0.00589  
#>  6 Option 4                             223 0.00459  
#>  7 Base Year                             14 0.000288 
#>  8 Option Year 1                          6 0.000124 
#>  9 Option Year 2                          6 0.000124 
#> 10 Option Year 3                          5 0.000103 
#> 11 Option Year 4                          5 0.000103 
#> 12 Option 5                               4 0.0000824
#> 13 Base                                   3 0.0000618
#> 14 Base year + Option Year 4              2 0.0000412
#> 15 Option Year                            2 0.0000412
#> 16 Option Year Two                        2 0.0000412
#> 17 Base Year 1                            1 0.0000206
#> 18 Partial Exercise of  Option Year 4     1 0.0000206
#> 19 Partial Exercise of Option Year 2      1 0.0000206
```

### Continuous

#### Amounts

``` r
noquote(map_chr(summary(dcc$amount), dollar))
#>           Min.        1st Qu.         Median           Mean        3rd Qu.           Max. 
#>             $0      $7,434.05     $30,390.04       $510,298       $125,000 $1,010,514,069
sum(dcc$amount <= 0)
#> [1] 967
```

``` r
glimpse(dcc[c(which.min(dcc$amount), which.max(dcc$amount)), ])
#> Rows: 2
#> Columns: 14
#> $ type          <chr> "contract", "contract"
#> $ id            <chr> "CW101352", "CW83146"
#> $ title         <chr> "OPTION YEAR ONE DC Economic Strategy ? Reimagining Downtown", "Managed Car…
#> $ agency        <chr> "Deputy Mayor for Planning and Economic Development (DMPED)", "Health Care …
#> $ option_period <chr> "Option 1", "Option 1"
#> $ start_date    <date> 2022-10-01, 2021-10-01
#> $ end_date      <date> 2023-09-30, 2022-09-30
#> $ date          <date> 2022-08-02, 2020-05-26
#> $ nigp_code     <chr> "9184914", "9585600"
#> $ vendor        <chr> "McKinsey & Company, Inc. Washington D.C.", "Trusted Health Plan (District …
#> $ amount        <dbl> 0, 1010514069
#> $ fiscal_year   <chr> NA, NA
#> $ na_flag       <lgl> FALSE, FALSE
#> $ dupe_flag     <lgl> FALSE, FALSE
```

![](../plots/hist_amount-1.png)<!-- -->

#### Dates

We can add the calendar year from `date` with `lubridate::year()`

``` r
dcc <- mutate(dcc, year = year(date))
```

Aside from a few of contracts awarded much earlier, the date columns are
clean.

``` r
count_na(dcc$date)
#> [1] 0
min(dcc$date, na.rm = TRUE)
#> [1] "2016-01-01"
sum(dcc$year < 2012, na.rm = TRUE)
#> [1] 0
max(dcc$date, na.rm = TRUE)
#> [1] "2023-01-19"
sum(dcc$date > today(), na.rm = TRUE)
#> [1] 0
```

![](../plots/bar_year-1.png)<!-- -->

## Wrangle

There are no geographic variables, but we can add a 2-digit state
abbreviation for the spending agency.

``` r
dcc <- mutate(dcc, state = "dc", .after = agency)
```

## Conclude

1.  There are 48,570 records in the database.
2.  There are 1,366 duplicate records in the database.
3.  The range and distribution of `amount` and `award_date` seem
    reasonable.
4.  There are 222 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `award_year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("state", "dc", "contracts", "data", "clean"))
clean_csv <- path(clean_dir, "dc_contracts_20200701-20230119.csv")
write_csv(dcc, clean_csv, na = "")
file_size(clean_csv)
#> 6.18M
mutate(file_encoding(clean_csv), across(path, path.abbrev))
#> # A tibble: 1 × 3
#>   path                                                                                mime  charset
#>   <fs::path>                                                                          <chr> <chr>  
#> 1 …lity_datacleaning/state/dc/contracts/data/clean/dc_contracts_20200701-20230119.csv text… us-asc…
```

## Upload

We can use the `aws.s3::put_object()` to upload the text file to the IRW
server.

``` r
aws_key <- path("csv", basename(clean_csv))
if (!object_exists(aws_key, "publicaccountability")) {
  put_object(
    file = clean_csv,
    object = aws_key, 
    bucket = "publicaccountability",
    acl = "public-read",
    show_progress = TRUE,
    multipart = TRUE
  )
}
aws_head <- head_object(aws_key, "publicaccountability")
(aws_size <- as_fs_bytes(attr(aws_head, "content-length")))
```

## Dictionary

The following table describes the variables in our final exported file:

| Column          | Found in both | Type  | Definition                                         |
|:----------------|:--------------|:------|:---------------------------------------------------|
| `type`          | `character`   | TRUE  | Transaction type (contract or purchae)             |
| `id`            | `character`   | TRUE  | Unique contract number                             |
| `title`         | `character`   | TRUE  | Contract title                                     |
| `agency`        | `character`   | TRUE  | Awarding agency name                               |
| `state`         | `character`   | FALSE | Awarding agency state location                     |
| `option_period` | `character`   | FALSE | Option period awarded                              |
| `start_date`    | `double`      | FALSE | Contract start date                                |
| `end_date`      | `double`      | TRUE  | Contract end date                                  |
| `date`          | `double`      | TRUE  | Contract awarded date, purchase made date          |
| `nigp_code`     | `character`   | TRUE  | National Institute of Governmental Purchasing code |
| `vendor`        | `character`   | TRUE  | Recipient vendor name                              |
| `amount`        | `double`      | FALSE | Contract amount awarded, total purchase amount     |
| `fiscal_year`   | `character`   | NA    | Purchase order fiscal year                         |
| `na_flag`       | `logical`     | NA    | Flag for missing date, amount, or name             |
| `dupe_flag`     | `logical`     | NA    | Flag for completely duplicated record              |
| `year`          | `double`      | TRUE  | Calendar year contract awarded                     |

``` r
write_lines(
  x = c("# District Of Columbia Contracts Data Dictionary\n", dict_md),
  file = here("state", "dc", "contracts", "dc_contracts_dict.md"),
)
```
