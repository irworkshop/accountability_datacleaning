Washington Contracts
================
Kiernan Nicholls
2023-02-16 12:41:56

- <a href="#project" id="toc-project">Project</a>
- <a href="#objectives" id="toc-objectives">Objectives</a>
- <a href="#packages" id="toc-packages">Packages</a>
- <a href="#data" id="toc-data">Data</a>
- <a href="#import" id="toc-import">Import</a>
- <a href="#explore" id="toc-explore">Explore</a>
- <a href="#conclude" id="toc-conclude">Conclude</a>
- <a href="#update" id="toc-update">Update</a>
- <a href="#export" id="toc-export">Export</a>
- <a href="#upload" id="toc-upload">Upload</a>

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
  aws.s3, # read from aws s3
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
#> [1] "/home/kiernan/Documents/accountability_datacleaning"
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
#> # A tibble: 2 × 2
#>   vet_owned      n
#>   <chr>      <int>
#> 1 N         171950
#> 2 Y            823
wac <- mutate_at(
  .tbl = wac,
  .vars = vars(12:14),
  .funs = equals, "Y"
)
```

## Explore

``` r
glimpse(wac)
#> Rows: 172,773
#> Columns: 14
#> $ customer_type     <chr> "Cities Including Towns", "Higher Ed (State Agency)", "Higher Ed (State…
#> $ customer_name     <chr> "ISSAQUAH CITY OF", "YAKIMA VALLEY COLLEGE", "COMM COLLEGES OF SPOKANE"…
#> $ contract_number   <chr> "00111", "00111", "00111", "00111", "00111", "00111", "00111", "00111",…
#> $ contract_title    <chr> "Fertilizers", "Fertilizers", "Fertilizers", "Fertilizers", "Fertilizer…
#> $ vendor_name       <chr> "WILBUR-ELLIS COMPANY LLC", "WILBUR-ELLIS COMPANY LLC", "WILBUR-ELLIS C…
#> $ calendar_year     <dbl> 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015,…
#> $ q1_sales_reported <dbl> 0, 0, 0, 271, 0, 3176, 0, 3133, 2694, 0, 135, 0, 0, 0, 0, 480, 36, 0, 0…
#> $ q2_sales_reported <dbl> 975, 0, 1604, 271, 3241, 0, 0, 2089, 0, 103, 196, 0, 0, 6137, 0, 529, 3…
#> $ q3_sales_reported <dbl> 986, 0, 0, 0, 0, 1588, 271, 0, 0, 0, 0, 0, 0, 0, 4360, 1351, 0, 0, 0, 0…
#> $ q4_sales_reported <dbl> 1986, 1239, 0, 0, 2820, 135, 0, 1031, 0, 0, 0, 368, 252, 10004, 0, 1113…
#> $ omwbe             <chr> "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "…
#> $ vet_owned         <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ small_business    <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ diverse_options   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
tail(wac)
#> # A tibble: 6 × 14
#>   customer_…¹ custo…² contr…³ contr…⁴ vendo…⁵ calen…⁶ q1_sa…⁷ q2_sa…⁸ q3_sa…⁹ q4_sa…˟ omwbe vet_o…˟
#>   <chr>       <chr>   <chr>   <chr>   <chr>     <dbl>   <dbl>   <dbl>   <dbl>   <dbl> <chr> <lgl>  
#> 1 Customers   <NA>    13022   Cars, … 72 HOU…    2022       0       0       0       0 N     FALSE  
#> 2 State Agen… TRANSP… 14422   Office… STEELC…    2022       0       0   10708       0 N     FALSE  
#> 3 Cities Inc… FEDERA… 14422   Office… STEELC…    2022       0       0    8796       0 N     FALSE  
#> 4 Customers   <NA>    14422   Office… STEELC…    2022       0       0       0       0 N     FALSE  
#> 5 Cities Inc… VANCOU… 14422   Office… MILLER…    2022       0    5427   20933       0 N     FALSE  
#> 6 Customers   <NA>    14422   Office… MILLER…    2022       0       0       0       0 N     FALSE  
#> # … with 2 more variables: small_business <lgl>, diverse_options <lgl>, and abbreviated variable
#> #   names ¹​customer_type, ²​customer_name, ³​contract_number, ⁴​contract_title, ⁵​vendor_name,
#> #   ⁶​calendar_year, ⁷​q1_sales_reported, ⁸​q2_sales_reported, ⁹​q3_sales_reported,
#> #   ˟​q4_sales_reported, ˟​vet_owned
```

### Missing

``` r
col_stats(wac, count_na)
#> # A tibble: 14 × 4
#>    col               class     n      p
#>    <chr>             <chr> <int>  <dbl>
#>  1 customer_type     <chr>     0 0     
#>  2 customer_name     <chr> 10220 0.0592
#>  3 contract_number   <chr>     0 0     
#>  4 contract_title    <chr>     0 0     
#>  5 vendor_name       <chr>     0 0     
#>  6 calendar_year     <dbl>     0 0     
#>  7 q1_sales_reported <dbl>     0 0     
#>  8 q2_sales_reported <dbl>     0 0     
#>  9 q3_sales_reported <dbl>     0 0     
#> 10 q4_sales_reported <dbl>     0 0     
#> 11 omwbe             <chr>     0 0     
#> 12 vet_owned         <lgl>     0 0     
#> 13 small_business    <lgl>     0 0     
#> 14 diverse_options   <lgl>     0 0
```

About 6% of transactions are missing the customer name.

``` r
wac <- wac %>% flag_na(customer_name, vendor_name)
percent(mean(wac$na_flag), 0.01)
#> [1] "5.92%"
```

### Duplicates

There are also a small handful of duplicate records, all also missing a
name.

``` r
wac <- flag_dupes(wac, everything())
sum(wac$dupe_flag)
#> [1] 4
```

``` r
wac %>% 
  filter(dupe_flag) %>% 
  select(customer_name, vendor_name, calendar_year)
#> # A tibble: 4 × 3
#>   customer_name vendor_name           calendar_year
#>   <chr>         <chr>                         <dbl>
#> 1 <NA>          CLARK NUBER P.S.               2015
#> 2 <NA>          CLARK NUBER P.S.               2015
#> 3 <NA>          PACWEST MACHINERY LLC          2016
#> 4 <NA>          PACWEST MACHINERY LLC          2016
```

### Categorical

``` r
col_stats(wac, n_distinct)
#> # A tibble: 16 × 4
#>    col               class     n         p
#>    <chr>             <chr> <int>     <dbl>
#>  1 customer_type     <chr>    19 0.000110 
#>  2 customer_name     <chr>  2042 0.0118   
#>  3 contract_number   <chr>   472 0.00273  
#>  4 contract_title    <chr>   437 0.00253  
#>  5 vendor_name       <chr>  2263 0.0131   
#>  6 calendar_year     <dbl>     8 0.0000463
#>  7 q1_sales_reported <dbl> 30821 0.178    
#>  8 q2_sales_reported <dbl> 32536 0.188    
#>  9 q3_sales_reported <dbl> 30958 0.179    
#> 10 q4_sales_reported <dbl> 27825 0.161    
#> 11 omwbe             <chr>     4 0.0000232
#> 12 vet_owned         <lgl>     2 0.0000116
#> 13 small_business    <lgl>     2 0.0000116
#> 14 diverse_options   <lgl>     2 0.0000116
#> 15 na_flag           <lgl>     2 0.0000116
#> 16 dupe_flag         <lgl>     2 0.0000116
```

``` r
wac %>% 
  select(12:15) %>% 
  map(~mutate(count(data.frame(x = .x), x), p = n/sum(n)))
#> $vet_owned
#>       x      n           p
#> 1 FALSE 171950 0.995236524
#> 2  TRUE    823 0.004763476
#> 
#> $small_business
#>       x      n         p
#> 1 FALSE 154563 0.8946016
#> 2  TRUE  18210 0.1053984
#> 
#> $diverse_options
#>       x      n         p
#> 1 FALSE 152520 0.8827768
#> 2  TRUE  20253 0.1172232
#> 
#> $na_flag
#>       x      n          p
#> 1 FALSE 162553 0.94084724
#> 2  TRUE  10220 0.05915276
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
#>  -1696864       752      4298     86892     23178 127182875
percent(mean(wac$amount <= 0), 0.01)
#> [1] "5.90%"
```

![](../plots/hist_amount-1.png)<!-- -->

### Dates

The data goes back to 2015 and the number of contracts is extremely
consistent year to year.

![](../plots/bar_year-1.png)<!-- -->

## Conclude

``` r
glimpse(wac)
#> Rows: 172,773
#> Columns: 17
#> Rowwise: 
#> $ customer_type     <chr> "Cities Including Towns", "Higher Ed (State Agency)", "Higher Ed (State…
#> $ customer_name     <chr> "ISSAQUAH CITY OF", "YAKIMA VALLEY COLLEGE", "COMM COLLEGES OF SPOKANE"…
#> $ contract_number   <chr> "00111", "00111", "00111", "00111", "00111", "00111", "00111", "00111",…
#> $ contract_title    <chr> "Fertilizers", "Fertilizers", "Fertilizers", "Fertilizers", "Fertilizer…
#> $ vendor_name       <chr> "WILBUR-ELLIS COMPANY LLC", "WILBUR-ELLIS COMPANY LLC", "WILBUR-ELLIS C…
#> $ calendar_year     <dbl> 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015,…
#> $ q1_sales_reported <dbl> 0, 0, 0, 271, 0, 3176, 0, 3133, 2694, 0, 135, 0, 0, 0, 0, 480, 36, 0, 0…
#> $ q2_sales_reported <dbl> 975, 0, 1604, 271, 3241, 0, 0, 2089, 0, 103, 196, 0, 0, 6137, 0, 529, 3…
#> $ q3_sales_reported <dbl> 986, 0, 0, 0, 0, 1588, 271, 0, 0, 0, 0, 0, 0, 0, 4360, 1351, 0, 0, 0, 0…
#> $ q4_sales_reported <dbl> 1986, 1239, 0, 0, 2820, 135, 0, 1031, 0, 0, 0, 368, 252, 10004, 0, 1113…
#> $ omwbe             <chr> "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "…
#> $ vet_owned         <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ small_business    <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ diverse_options   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ na_flag           <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ dupe_flag         <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ amount            <dbl> 3947, 1239, 1604, 542, 6061, 4899, 271, 6253, 2694, 103, 331, 368, 252,…
```

1.  There are 172,773 records in the database.
2.  There are 4 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 10,220 records missing a name.
5.  There is no geographic data to normalize.
6.  The 4-digit `calendar_year` variable already exists.

## Update

``` r
wac_old <- s3read_using(
  FUN = read_csv,
  object = "csv/wa_contracts.csv",
  bucket = "publicaccountability"
)

wac_old$omwbe[is.na(wac_old$omwbe)] <- "N"
```

``` r
wac_new <- wac %>% 
  filter(calendar_year > 2020)
```

``` r
wac_old_2020 <- wac_old %>% 
  filter(calendar_year == 2020)

wac_new_2020 <- wac %>% 
  filter(calendar_year == 2020)
```

``` r
wac_new <- bind_rows(wac_new, wac_new_2020)
```

## Export

Now the file can be saved on disk for upload to the Accountability
server. We will name the object using a date range of the records
included.

``` r
clean_dir <- dir_create(here("state", "wa", "contracts", "data", "clean"))
clean_csv <- path(clean_dir, "wa_contracts_2015-20221129.csv")
clean_rds <- path_ext_set(clean_csv, "rds")
basename(clean_csv)
#> [1] "wa_contracts_2015-20221129.csv"
```

``` r
write_csv(wac, clean_csv, na = "")
write_rds(wac, clean_rds, compress = "xz")
(clean_size <- file_size(clean_csv))
#> 25.4M
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
unname(aws_size == clean_size)
```
