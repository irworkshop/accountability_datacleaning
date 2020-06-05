Washington Contracts
================
Kiernan Nicholls
2020-06-05 12:21:11

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Conclude](#conclude)
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
  jsonlite, # parse json files
  janitor, # data frame clean
  batman, # parse logicals
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

The contracts
[data](https://data.wa.gov/Procurements-and-Contracts/Master-Contract-Sales-Data-by-Customer-Contract-Ve/n8q6-4twj)
is from the Washington state [Department of Enterprise
Services](https://des.wa.gov/). The data can be retrieved from the
Washington OpenData portal under the title “Master Contract Sales Data
by Customer, Contract, Vendor” in the “Procurement and Contracts”
category. The data file was last updated on January 21, 2020. As of
writing, due to the ongoing Covid-19 pandemic, our typical efforts to
verify this OpenData source as the most updated were not made.

## Import

We can import the text file directly into R from the OpenData portal
URL.

``` r
wac <- vroom(
  file = "https://data.wa.gov/api/views/n8q6-4twj/rows.csv",
  .name_repair = make_clean_names,
  col_types = cols(
    `Calendar Year` = col_integer(),
    `Q1 Sales Reported` = col_double(),
    `Q2 Sales Reported` = col_double(),
    `Q3 Sales Reported` = col_double(),
    `Q4 Sales Reported` = col_double(),
  )
)
```

Then we can convert some quasi-logical variables to a true logical type.

``` r
count(wac, vet_owned)
#> # A tibble: 2 x 2
#>   vet_owned      n
#>   <chr>      <int>
#> 1 N         124778
#> 2 Y            578
wac <- mutate_at(
  .tbl = wac,
  .vars = vars(12:14),
  .funs = equals, "Y"
)
```

## Explore

``` r
glimpse(wac)
#> Rows: 125,356
#> Columns: 14
#> $ customer_type     <chr> "School Districts", "Cities Including Towns", "County", "County", "Cit…
#> $ customer_name     <chr> "AUBURN SCHOOL DISTRICT 408", "EAST WENATCHEE, CITY OF", "KING COUNTY"…
#> $ contract_number   <chr> "00111", "00111", "00111", "00111", "00111", "00111", "00111", "00111"…
#> $ contract_title    <chr> "Fertilizers", "Fertilizers", "Fertilizers", "Fertilizers", "Fertilize…
#> $ vendor_name       <chr> "WILBUR-ELLIS COMPANY", "WILBUR-ELLIS COMPANY", "WILBUR-ELLIS COMPANY"…
#> $ calendar_year     <int> 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015…
#> $ q1_sales_reported <dbl> 0, 0, 480, 435, 271, 3176, 135, 3133, 36, 2694, 0, 0, 0, 0, 0, 0, 0, 0…
#> $ q2_sales_reported <dbl> 0, 0, 529, 0, 271, 0, 196, 2089, 30, 0, 3241, 794, 1604, 6137, 1181, 1…
#> $ q3_sales_reported <dbl> 271, 4360, 1351, 0, 0, 1588, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 986, 0, 0, …
#> $ q4_sales_reported <dbl> 0, 0, 11131, 1034, 0, 135, 0, 1031, 0, 0, 2820, 189, 0, 10004, 413, 0,…
#> $ omwbe             <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ vet_owned         <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
#> $ small_business    <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
#> $ diverse_options   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
tail(wac)
#> # A tibble: 6 x 14
#>   customer_type customer_name contract_number contract_title vendor_name calendar_year
#>   <chr>         <chr>         <chr>           <chr>          <chr>               <int>
#> 1 Customers     <NA>          09712           ESRI - Softwa… ENVIRONMEN…          2020
#> 2 Districts, O… FERRY COUNTY… 09712           ESRI - Softwa… ENVIRONMEN…          2020
#> 3 County        FRANKLIN COU… 09712           ESRI - Softwa… ENVIRONMEN…          2020
#> 4 Cities Inclu… MAPLE VALLEY… 09712           ESRI - Softwa… ENVIRONMEN…          2020
#> 5 Cities Inclu… OAK HARBOR, … 09712           ESRI - Softwa… ENVIRONMEN…          2020
#> 6 Customers     <NA>          09712           ESRI - Softwa… ENVIRONMEN…          2020
#> # … with 8 more variables: q1_sales_reported <dbl>, q2_sales_reported <dbl>,
#> #   q3_sales_reported <dbl>, q4_sales_reported <dbl>, omwbe <chr>, vet_owned <lgl>,
#> #   small_business <lgl>, diverse_options <lgl>
```

### Missing

``` r
col_stats(wac, count_na)
#> # A tibble: 14 x 4
#>    col               class      n     p
#>    <chr>             <chr>  <int> <dbl>
#>  1 customer_type     <chr>      0 0    
#>  2 customer_name     <chr>  15739 0.126
#>  3 contract_number   <chr>      0 0    
#>  4 contract_title    <chr>      0 0    
#>  5 vendor_name       <chr>      0 0    
#>  6 calendar_year     <int>      0 0    
#>  7 q1_sales_reported <dbl>      0 0    
#>  8 q2_sales_reported <dbl>      0 0    
#>  9 q3_sales_reported <dbl>      0 0    
#> 10 q4_sales_reported <dbl>      0 0    
#> 11 omwbe             <chr> 121988 0.973
#> 12 vet_owned         <lgl>      0 0    
#> 13 small_business    <lgl>      0 0    
#> 14 diverse_options   <lgl>      0 0
```

About 6% of transactions are missing the customer name.

``` r
wac <- wac %>% flag_na(customer_name, vendor_name)
percent(mean(wac$na_flag), 0.01)
#> [1] "12.56%"
```

### Duplicates

There are also a small handful of duplicate records, all also missing a
name.

``` r
wac <- flag_dupes(wac, everything())
sum(wac$dupe_flag)
#> [1] 54
```

``` r
wac %>% 
  filter(dupe_flag) %>% 
  select(customer_name, vendor_name, calendar_year)
#> # A tibble: 54 x 3
#>    customer_name vendor_name          calendar_year
#>    <chr>         <chr>                        <int>
#>  1 <NA>          US ARMOR CORPORATION          2015
#>  2 <NA>          US ARMOR CORPORATION          2015
#>  3 <NA>          PITNEY BOWES INC              2015
#>  4 <NA>          PITNEY BOWES INC              2015
#>  5 <NA>          PITNEY BOWES INC              2015
#>  6 <NA>          PITNEY BOWES INC              2015
#>  7 <NA>          PITNEY BOWES INC              2015
#>  8 <NA>          PITNEY BOWES INC              2015
#>  9 <NA>          PITNEY BOWES INC              2015
#> 10 <NA>          PITNEY BOWES INC              2015
#> # … with 44 more rows
```

### Categorical

``` r
col_stats(wac, n_distinct)
#> # A tibble: 16 x 4
#>    col               class     n         p
#>    <chr>             <chr> <int>     <dbl>
#>  1 customer_type     <chr>    19 0.000152 
#>  2 customer_name     <chr>  1328 0.0106   
#>  3 contract_number   <chr>   415 0.00331  
#>  4 contract_title    <chr>   383 0.00306  
#>  5 vendor_name       <chr>  2075 0.0166   
#>  6 calendar_year     <int>     6 0.0000479
#>  7 q1_sales_reported <dbl> 25099 0.200    
#>  8 q2_sales_reported <dbl> 24017 0.192    
#>  9 q3_sales_reported <dbl> 22497 0.179    
#> 10 q4_sales_reported <dbl> 22210 0.177    
#> 11 omwbe             <chr>     4 0.0000319
#> 12 vet_owned         <lgl>     2 0.0000160
#> 13 small_business    <lgl>     2 0.0000160
#> 14 diverse_options   <lgl>     2 0.0000160
#> 15 na_flag           <lgl>     2 0.0000160
#> 16 dupe_flag         <lgl>     2 0.0000160
```

``` r
wac %>% 
  select(12:15) %>% 
  map(~mutate(count(data.frame(x = .x), x), p = n/sum(n)))
#> $vet_owned
#>       x      n           p
#> 1 FALSE 124778 0.995389132
#> 2  TRUE    578 0.004610868
#> 
#> $small_business
#>       x      n         p
#> 1 FALSE 111345 0.8882303
#> 2  TRUE  14011 0.1117697
#> 
#> $diverse_options
#>       x     n         p
#> 1 FALSE 85315 0.6805817
#> 2  TRUE 40041 0.3194183
#> 
#> $na_flag
#>       x      n         p
#> 1 FALSE 109617 0.8744456
#> 2  TRUE  15739 0.1255544
```

### Amounts

The amount paid to each vendor for a contract is broken up into fiscal
quarters. We will sum the quarters to find the total annual spending.

``` r
wac <- wac %>% 
  rowwise() %>% 
  mutate(amount = sum(c_across(ends_with("sales_reported"))))
```

``` r
summary(wac$amount)
#>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
#>   -338208       657      3749     81534     20576 127182875
percent(mean(wac$amount <= 0), 0.01)
#> [1] "6.21%"
```

![](../plots/hist_amount-1.png)<!-- -->

### Dates

The data goes back to 2015 and the number of contracts is extremely
consistent year to year.

![](../plots/bar_year-1.png)<!-- -->

## Conclude

``` r
glimpse(wac)
#> Rows: 125,356
#> Columns: 17
#> Rowwise: 
#> $ customer_type     <chr> "School Districts", "Cities Including Towns", "County", "County", "Cit…
#> $ customer_name     <chr> "AUBURN SCHOOL DISTRICT 408", "EAST WENATCHEE, CITY OF", "KING COUNTY"…
#> $ contract_number   <chr> "00111", "00111", "00111", "00111", "00111", "00111", "00111", "00111"…
#> $ contract_title    <chr> "Fertilizers", "Fertilizers", "Fertilizers", "Fertilizers", "Fertilize…
#> $ vendor_name       <chr> "WILBUR-ELLIS COMPANY", "WILBUR-ELLIS COMPANY", "WILBUR-ELLIS COMPANY"…
#> $ calendar_year     <int> 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015…
#> $ q1_sales_reported <dbl> 0, 0, 480, 435, 271, 3176, 135, 3133, 36, 2694, 0, 0, 0, 0, 0, 0, 0, 0…
#> $ q2_sales_reported <dbl> 0, 0, 529, 0, 271, 0, 196, 2089, 30, 0, 3241, 794, 1604, 6137, 1181, 1…
#> $ q3_sales_reported <dbl> 271, 4360, 1351, 0, 0, 1588, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 986, 0, 0, …
#> $ q4_sales_reported <dbl> 0, 0, 11131, 1034, 0, 135, 0, 1031, 0, 0, 2820, 189, 0, 10004, 413, 0,…
#> $ omwbe             <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ vet_owned         <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
#> $ small_business    <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
#> $ diverse_options   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
#> $ na_flag           <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
#> $ dupe_flag         <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
#> $ amount            <dbl> 271, 4360, 13491, 1469, 542, 4899, 331, 6253, 66, 2694, 6061, 983, 160…
```

1.  There are 125,356 records in the database.
2.  There are 54 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 15,739 records missing a name.
5.  There is no geographic data to normalize.
6.  The 4-digit `calendar_year` variable already exists.

## Export

``` r
clean_dir <- dir_create(here("wa", "contracts", "data", "clean"))
clean_path <- path(clean_dir, "wa_Contracts_clean.csv")
write_csv(wac, clean_path, na = "")
file_size(clean_path)
#> 18.6M
guess_encoding(clean_path)
#> # A tibble: 2 x 2
#>   encoding   confidence
#>   <chr>           <dbl>
#> 1 UTF-8            1   
#> 2 ISO-8859-1       0.35
```
