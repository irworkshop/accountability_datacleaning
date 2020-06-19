District Of Columbia Contracts
================
Kiernan Nicholls
2020-05-28 12:04:29

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Read](#read)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
  - [Conclude](#conclude)
  - [Export](#export)
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

A list of contracts by fiscal year can be obtained from the District of
Columbia [Contracts and Procurement Transparency
Portal](https://contracts.ocp.dc.gov/contracts/search). A search can be
run for results by fiscal years 2016 through 2021. This search can then
be exported as a single CSV file which we can read into R. The same
thing can be done on the [purchase orders
portal](https://contracts.ocp.dc.gov/purchase/search).

## Read

``` r
raw_dir <- dir_create(here("dc", "contracts", "data", "raw"))
```

First, we will read the contract awards file.

``` r
dcc <- vroom(
  file = path(raw_dir, "ContractAwards.csv"),
  delim = ",",
  .name_repair = make_clean_names,
  col_types = cols(
    .default = col_character(),
    `Start Date` = col_date_usa(),
    `End Date` = col_date_usa(),
    `Award Date` = col_date_usa(),
    `Amount` = col_number()
  )
)
```

Then the we will read the purchase orders file.

``` r
dcp <- vroom(
  file = path(raw_dir, "PurchaseOrders.csv"),
  delim = ",",
  .name_repair = make_clean_names,
  col_types = cols(
    .default = col_character(),
    `Total Amount` = col_number(),
    `Order Date` = col_date_usa(),
  )
)
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
#> Rows: 154,293
#> Columns: 12
#> $ type          <chr> "contract", "contract", "contract", "contract", "contract", "contract", "c…
#> $ id            <chr> "CW70783", "CW70787", "CW82327", "CW60738", "CW68706", "DCRL-2019-C4-0019"…
#> $ title         <chr> "FY19 - CF0 - OYP - MBSYEP Work Readiness and Job Placement 22-24 YO - Com…
#> $ agency        <chr> "Contracting and Procurement (OCP),Employment Services (DOES)", "Contracti…
#> $ option_period <chr> "Option 1", "Option 1", "Base Period", "Option 2", "Option 1", "Base Year"…
#> $ start_date    <date> 2020-05-02, 2020-05-02, 2020-05-01, 2020-05-01, 2020-05-01, 2020-04-29, 2…
#> $ end_date      <date> 2021-05-01, 2021-05-01, 2020-09-30, 2021-04-30, 2021-04-30, 2021-04-28, 2…
#> $ date          <date> 2019-04-29, 2019-04-29, 2020-04-28, 2018-04-27, 2019-02-08, 2020-04-23, 2…
#> $ nigp_code     <chr> "9183822", "9183822", "9462010", "9529265", "9183800,9183822", "948-47-00"…
#> $ vendor        <chr> "Community Tech", "Community Tech", "Bayne LLC", "BEE-HOMES SOUTH", "Const…
#> $ amount        <dbl> 150000.0, 100000.0, 64485.0, 42000.0, 100000.0, 706237.2, 500000.0, 950000…
#> $ fiscal_year   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
tail(dcc)
#> # A tibble: 6 x 12
#>   type  id    title agency option_period start_date end_date   date       nigp_code vendor amount
#>   <chr> <chr> <chr> <chr>  <chr>         <date>     <date>     <date>     <chr>     <chr>   <dbl>
#> 1 purc… PO44… <NA>  Behav… <NA>          NA         NA         2012-10-01 9625800   CAREC… 93622.
#> 2 purc… PO44… <NA>  Commi… <NA>          NA         NA         2012-10-01 9620700   ASSOC…  7250 
#> 3 purc… PO44… <NA>  Commi… <NA>          NA         NA         2012-10-01 9620700   SPRIN…  7250 
#> 4 purc… PO44… <NA>  Child… <NA>          NA         NA         2012-10-01 9524300   NADIN… 68224 
#> 5 purc… PO44… <NA>  Behav… <NA>          NA         NA         2012-10-01 9625800   LATIN… 96000 
#> 6 purc… PO44… <NA>  Behav… <NA>          NA         NA         2012-10-01 9625800   SUSAN… 31725 
#> # … with 1 more variable: fiscal_year <chr>
```

### Missing

There are a handful of records missing a name or date needed to properly
identify a transaction, mostly the agency name.

``` r
col_stats(dcc, count_na)
#> # A tibble: 12 x 4
#>    col           class       n          p
#>    <chr>         <chr>   <int>      <dbl>
#>  1 type          <chr>       0 0         
#>  2 id            <chr>       3 0.0000194 
#>  3 title         <chr>  148194 0.960     
#>  4 agency        <chr>     592 0.00384   
#>  5 option_period <chr>  148193 0.960     
#>  6 start_date    <date> 148193 0.960     
#>  7 end_date      <date> 148193 0.960     
#>  8 date          <date>      2 0.0000130 
#>  9 nigp_code     <chr>      72 0.000467  
#> 10 vendor        <chr>       1 0.00000648
#> 11 amount        <dbl>       0 0         
#> 12 fiscal_year   <chr>    6100 0.0395
```

These records can be flagged with `campfin::flag_na()`.

``` r
dcc <- dcc %>% flag_na(date, vendor, amount, agency)
percent(mean(dcc$na_flag), 0.01)
#> [1] "0.39%"
```

``` r
dcc %>% 
  filter(na_flag) %>% 
  select(date, vendor, amount, agency, type)
#> # A tibble: 595 x 5
#>    date       vendor                              amount agency type    
#>    <date>     <chr>                                <dbl> <chr>  <chr>   
#>  1 2019-04-26 Cura Concepts                       500000 <NA>   contract
#>  2 2018-04-24 Capital Consulting LLC              950000 <NA>   contract
#>  3 2019-04-22 Market Me Consulting                900000 <NA>   contract
#>  4 2019-04-22 KoVais Innovative Solutions         950000 <NA>   contract
#>  5 2018-10-25 DIGI DOCS INC DOCUMENT MGERS        750000 <NA>   contract
#>  6 2018-04-18 Business Development Associates LLC 950000 <NA>   contract
#>  7 2019-04-18 Clearly Innovative, Inc.            500000 <NA>   contract
#>  8 2018-04-12 ROBINSON ASSOCIATES LLC             900000 <NA>   contract
#>  9 2018-04-11 Sol Support LLC                     950000 <NA>   contract
#> 10 2019-04-10 Empowerment Enterprise Group, LLC   500000 <NA>   contract
#> # … with 585 more rows
```

### Duplicates

Ignoring the `id` variable, there are a handful of completely duplicated
records. These can be flagged with `campfin::flag_dupes()`.

``` r
dcc <- flag_dupes(dcc, -id)
percent(mean(dcc$dupe_flag), 0.01)
#> [1] "2.95%"
```

``` r
dcc %>% 
  filter(dupe_flag) %>% 
  select(date, vendor, amount, agency, type) %>% 
  arrange(date)
#> # A tibble: 4,547 x 5
#>    date       vendor                      amount agency                                  type    
#>    <date>     <chr>                        <dbl> <chr>                                   <chr>   
#>  1 2012-10-01 ANNA HEALTHCARE, INC.      169425. Department on Disability Services (DDS) contract
#>  2 2012-10-01 ANNA HEALTHCARE, INC.      169425. Department on Disability Services (DDS) contract
#>  3 2012-10-03 OST, INC.                   56376  Chief Technology Officer (OCTO)         purchase
#>  4 2012-10-03 OST, INC.                   56376  Chief Technology Officer (OCTO)         purchase
#>  5 2012-10-04 OST, INC.                   38981. Chief Technology Officer (OCTO)         purchase
#>  6 2012-10-04 CHL BUSINESS INTERIORS LLC      0  General Services (DGS)                  purchase
#>  7 2012-10-04 CHL BUSINESS INTERIORS LLC      0  General Services (DGS)                  purchase
#>  8 2012-10-04 OST, INC.                   20438. Chief Technology Officer (OCTO)         purchase
#>  9 2012-10-04 OST, INC.                   20438. Chief Technology Officer (OCTO)         purchase
#> 10 2012-10-04 OST, INC.                   38981. Chief Technology Officer (OCTO)         purchase
#> # … with 4,537 more rows
```

### Categorical

``` r
col_stats(dcc, n_distinct)
#> # A tibble: 14 x 4
#>    col           class       n         p
#>    <chr>         <chr>   <int>     <dbl>
#>  1 type          <chr>       2 0.0000130
#>  2 id            <chr>  151975 0.985    
#>  3 title         <chr>    3734 0.0242   
#>  4 agency        <chr>     126 0.000817 
#>  5 option_period <chr>      29 0.000188 
#>  6 start_date    <date>   1443 0.00935  
#>  7 end_date      <date>   1442 0.00935  
#>  8 date          <date>   2238 0.0145   
#>  9 nigp_code     <chr>    7326 0.0475   
#> 10 vendor        <chr>   15720 0.102    
#> 11 amount        <dbl>   75733 0.491    
#> 12 fiscal_year   <chr>       9 0.0000583
#> 13 na_flag       <lgl>       2 0.0000130
#> 14 dupe_flag     <lgl>       2 0.0000130
```

``` r
add_prop(count(dcc, agency, sort = TRUE))
#> # A tibble: 126 x 3
#>    agency                                         n      p
#>    <chr>                                      <int>  <dbl>
#>  1 District of Columbia Public Schools (DCPS) 29118 0.189 
#>  2 General Services (DGS)                     10220 0.0662
#>  3 Chief Technology Officer (OCTO)             7111 0.0461
#>  4 Behavioral Health (DBH)                     6700 0.0434
#>  5 Health (DOH)                                6594 0.0427
#>  6 Employment Services (DOES)                  6080 0.0394
#>  7 Commission on Arts and Humanities (CAH)     5609 0.0364
#>  8 State Superintendent of Education (OSSE)    5394 0.0350
#>  9 Attorney General (OAG)                      5058 0.0328
#> 10 Transportation (DDOT)                       4422 0.0287
#> # … with 116 more rows
add_prop(count(dcc, option_period, sort = TRUE))
#> # A tibble: 29 x 3
#>    option_period      n         p
#>    <chr>          <int>     <dbl>
#>  1 <NA>          148193 0.960    
#>  2 Base Period     3412 0.0221   
#>  3 Option 1        1241 0.00804  
#>  4 Option 2         752 0.00487  
#>  5 Option 3         443 0.00287  
#>  6 Option 4         196 0.00127  
#>  7 Base Year         14 0.0000907
#>  8 Base               7 0.0000454
#>  9 Option Year 2      5 0.0000324
#> 10 Option Year 3      5 0.0000324
#> # … with 19 more rows
```

### Continuous

#### Amounts

``` r
noquote(map_chr(summary(dcc$amount), dollar))
#>            Min.         1st Qu.          Median            Mean         3rd Qu.            Max. 
#>              $0          $3,500         $14,083        $640,399         $73,800 $10,000,000,000
sum(dcc$amount <= 0)
#> [1] 3580
```

``` r
glimpse(dcc[c(which.min(dcc$amount), which.max(dcc$amount)), ])
#> Rows: 2
#> Columns: 14
#> $ type          <chr> "contract", "contract"
#> $ id            <chr> "CW53678", "CW66904"
#> $ title         <chr> "Procurememt Card Services", "DCSS Application for Stockbridge for MOBIS"
#> $ agency        <chr> "Contracting and Procurement (OCP)", "Contracting and Procurement (OCP)"
#> $ option_period <chr> "Option 2", "Base Period"
#> $ start_date    <date> 2019-10-05, 2019-06-25
#> $ end_date      <date> 2020-10-04, 2020-06-24
#> $ date          <date> 2017-10-05, 2019-06-25
#> $ nigp_code     <chr> "9463550", "9180000"
#> $ vendor        <chr> "JP MORGAN CHASE BANK, NA", "Stockbridge Consulting LLC"
#> $ amount        <dbl> 0e+00, 1e+10
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
#> [1] 2
min(dcc$date, na.rm = TRUE)
#> [1] "2009-12-15"
sum(dcc$year < 2012, na.rm = TRUE)
#> [1] 8
max(dcc$date, na.rm = TRUE)
#> [1] "2020-05-09"
sum(dcc$date > today(), na.rm = TRUE)
#> [1] 0
```

![](../plots/bar_year-1.png)<!-- -->

## Wrangle

There are no geographic variables, but we can add a 2-digit state
abbreviation for the spending agency.

``` r
dcc <- mutate(dcc, state = "DC", .after = agency)
```

## Conclude

1.  There are 154,293 records in the database.
2.  There are 4,547 duplicate records in the database.
3.  The range and distribution of `amount` and `award_date` seem
    reasonable.
4.  There are 595 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `award_year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("dc", "contracts", "data", "clean"))
clean_path <- path(clean_dir, "dc_contracts_clean.csv")
write_csv(dcc, clean_path, na = "")
file_size(clean_path)
#> 19.7M
mutate(file_encoding(clean_path), across(path, path.abbrev))
#> # A tibble: 1 x 3
#>   path                                             mime            charset
#>   <chr>                                            <chr>           <chr>  
#> 1 ~/dc/contracts/data/clean/dc_contracts_clean.csv application/csv utf-8
```

## Dictionary

The following table describes the variables in our final exported file:

| Column          | Found in both | Type  | Definition                                         |
| :-------------- | :------------ | :---- | :------------------------------------------------- |
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
  path = here("dc", "contracts", "dc_contracts_dict.md"),
)
```
