District Of Columbia Contracts
================
Kiernan Nicholls
2020-05-11 12:43:28

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Read](#read)
  - [Explore](#explore)
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
be exported as a single CSV file which we can read into R.

## Read

``` r
raw_dir <- dir_create(here("dc", "contracts", "data", "raw"))
raw_path <- path(raw_dir, "ContractAwards.csv")
```

``` r
dcc <- vroom(
  file = raw_path,
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

## Explore

``` r
glimpse(dcc)
#> Rows: 6,100
#> Columns: 10
#> $ contract_number <chr> "CW70783", "CW70787", "CW82327", "CW60738", "CW68706", "DCRL-2019-C4-001…
#> $ title           <chr> "FY19 - CF0 - OYP - MBSYEP Work Readiness and Job Placement 22-24 YO - C…
#> $ agency          <chr> "Contracting and Procurement (OCP),Employment Services (DOES)", "Contrac…
#> $ option_period   <chr> "Option 1", "Option 1", "Base Period", "Option 2", "Option 1", "Base Yea…
#> $ start_date      <date> 2020-05-02, 2020-05-02, 2020-05-01, 2020-05-01, 2020-05-01, 2020-04-29,…
#> $ end_date        <date> 2021-05-01, 2021-05-01, 2020-09-30, 2021-04-30, 2021-04-30, 2021-04-28,…
#> $ award_date      <date> 2019-04-29, 2019-04-29, 2020-04-28, 2018-04-27, 2019-02-08, 2020-04-23,…
#> $ nigp_code       <chr> "9183822", "9183822", "9462010", "9529265", "9183800,9183822", "948-47-0…
#> $ vendor          <chr> "Community Tech", "Community Tech", "Bayne LLC", "BEE-HOMES SOUTH", "Con…
#> $ amount          <dbl> 150000.0, 100000.0, 64485.0, 42000.0, 100000.0, 706237.2, 500000.0, 9500…
tail(dcc)
#> # A tibble: 6 x 10
#>   contract_number title agency option_period start_date end_date   award_date nigp_code vendor
#>   <chr>           <chr> <chr>  <chr>         <date>     <date>     <date>     <chr>     <chr> 
#> 1 CW40872         Deaf… Depar… Base Period   2015-10-01 2016-09-30 2015-10-01 9616730   DEAF …
#> 2 CW38640         FY15… Foren… Option 1      2015-10-01 2016-09-30 2015-08-19 9614000   MICHA…
#> 3 CW44410         DDS-… Depar… Base Period   2015-10-01 2016-09-30 2014-10-01 9529265   Apex …
#> 4 CW46071         Resi… Depar… Base Period   2015-10-01 2016-09-30 2012-10-01 9529265   TOTAL…
#> 5 DCRL-2013-H-00… Fami… CHILD… Option 2      2015-10-01 2016-09-30 2014-09-29 948-47-00 Luthe…
#> 6 CW38652         FY15… Foren… Option 1      2015-10-01 2016-09-30 2015-08-27 9614000   RON S…
#> # … with 1 more variable: amount <dbl>
```

### Missing

There are a handful of records missing a name or date needed to properly
identify a transaction, mostly the agency name.

``` r
col_stats(dcc, count_na)
#> # A tibble: 10 x 4
#>    col             class      n        p
#>    <chr>           <chr>  <int>    <dbl>
#>  1 contract_number <chr>      0 0       
#>  2 title           <chr>      1 0.000164
#>  3 agency          <chr>    592 0.0970  
#>  4 option_period   <chr>      0 0       
#>  5 start_date      <date>     0 0       
#>  6 end_date        <date>     0 0       
#>  7 award_date      <date>     2 0.000328
#>  8 nigp_code       <chr>     72 0.0118  
#>  9 vendor          <chr>      1 0.000164
#> 10 amount          <dbl>      0 0
```

These records can be flagged with `campfin::flag_na()`.

``` r
dcc <- dcc %>% flag_na(award_date, vendor, amount, agency)
percent(mean(dcc$na_flag), 0.01)
#> [1] "9.75%"
```

``` r
dcc %>% 
  filter(na_flag) %>% 
  select(award_date, vendor, amount, agency)
#> # A tibble: 595 x 4
#>    award_date vendor                              amount agency
#>    <date>     <chr>                                <dbl> <chr> 
#>  1 2019-04-26 Cura Concepts                       500000 <NA>  
#>  2 2018-04-24 Capital Consulting LLC              950000 <NA>  
#>  3 2019-04-22 Market Me Consulting                900000 <NA>  
#>  4 2019-04-22 KoVais Innovative Solutions         950000 <NA>  
#>  5 2018-10-25 DIGI DOCS INC DOCUMENT MGERS        750000 <NA>  
#>  6 2018-04-18 Business Development Associates LLC 950000 <NA>  
#>  7 2019-04-18 Clearly Innovative, Inc.            500000 <NA>  
#>  8 2018-04-12 ROBINSON ASSOCIATES LLC             900000 <NA>  
#>  9 2018-04-11 Sol Support LLC                     950000 <NA>  
#> 10 2019-04-10 Empowerment Enterprise Group, LLC   500000 <NA>  
#> # … with 585 more rows
```

### Duplicates

Ignoring the `contract_number` variable, there are a handful of
completely duplicated records. These can be flagged with
`campfin::flag_dupes()`.

``` r
dcc <- flag_dupes(dcc, -contract_number)
sum(dcc$dupe_flag)
#> [1] 10
```

``` r
dcc %>% 
  filter(dupe_flag) %>% 
  select(award_date, vendor, amount, agency) %>% 
  arrange(award_date)
#> # A tibble: 10 x 4
#>    award_date vendor                             amount agency                                     
#>    <date>     <chr>                               <dbl> <chr>                                      
#>  1 2012-10-01 ANNA HEALTHCARE, INC.             169425. Department on Disability Services (DDS)    
#>  2 2012-10-01 ANNA HEALTHCARE, INC.             169425. Department on Disability Services (DDS)    
#>  3 2014-10-01 MT&G ENTERPRISE, LLC              262387. Department on Disability Services (DDS)    
#>  4 2014-10-01 MT&G ENTERPRISE, LLC              262387. Department on Disability Services (DDS)    
#>  5 2015-06-01 Ward and Ward Mental Health Ser… 1425436. Department on Disability Services (DDS)    
#>  6 2015-06-01 Ward and Ward Mental Health Ser… 1425436. Department on Disability Services (DDS)    
#>  7 2016-04-01 University Behavioral Center      148596  CHILD AND FAMILY SERVICES                  
#>  8 2016-04-01 University Behavioral Center      148596  CHILD AND FAMILY SERVICES                  
#>  9 2017-08-09 FUSE                              200000  Deputy Mayor for Planning and Economic Dev…
#> 10 2017-08-09 FUSE                              200000  Deputy Mayor for Planning and Economic Dev…
```

### Categorical

``` r
col_stats(dcc, n_distinct)
#> # A tibble: 12 x 4
#>    col             class      n        p
#>    <chr>           <chr>  <int>    <dbl>
#>  1 contract_number <chr>   3784 0.620   
#>  2 title           <chr>   3734 0.612   
#>  3 agency          <chr>    100 0.0164  
#>  4 option_period   <chr>     28 0.00459 
#>  5 start_date      <date>  1442 0.236   
#>  6 end_date        <date>  1441 0.236   
#>  7 award_date      <date>  1358 0.223   
#>  8 nigp_code       <chr>   1199 0.197   
#>  9 vendor          <chr>   1699 0.279   
#> 10 amount          <dbl>   2354 0.386   
#> 11 na_flag         <lgl>      2 0.000328
#> 12 dupe_flag       <lgl>      2 0.000328
```

``` r
add_prop(count(dcc, agency, sort = TRUE))
#> # A tibble: 100 x 3
#>    agency                                                                                  n      p
#>    <chr>                                                                               <int>  <dbl>
#>  1 Department on Disability Services (DDS)                                               737 0.121 
#>  2 Contracting and Procurement (OCP)                                                     624 0.102 
#>  3 <NA>                                                                                  592 0.0970
#>  4 Chief Technology Officer (OCTO)                                                       418 0.0685
#>  5 Health (DOH)                                                                          334 0.0548
#>  6 Public Works (DPW)                                                                    294 0.0482
#>  7 Human Services (DHS)                                                                  291 0.0477
#>  8 State Superintendent of Education (OSSE)                                              280 0.0459
#>  9 Contracting and Procurement (OCP),Deputy Mayor for Greater Economic Opportunity (D…   239 0.0392
#> 10 Employment Services (DOES)                                                            220 0.0361
#> # … with 90 more rows
add_prop(count(dcc, option_period, sort = TRUE))
#> # A tibble: 28 x 3
#>    option_period     n        p
#>    <chr>         <int>    <dbl>
#>  1 Base Period    3412 0.559   
#>  2 Option 1       1241 0.203   
#>  3 Option 2        752 0.123   
#>  4 Option 3        443 0.0726  
#>  5 Option 4        196 0.0321  
#>  6 Base Year        14 0.00230 
#>  7 Base              7 0.00115 
#>  8 Option Year 2     5 0.000820
#>  9 Option Year 3     5 0.000820
#> 10 Option Year 1     3 0.000492
#> # … with 18 more rows
```

### Continuous

#### Amounts

``` r
noquote(map_chr(summary(dcc$amount), dollar))
#>            Min.         1st Qu.          Median            Mean         3rd Qu.            Max. 
#>              $0        $106,777        $308,652     $12,170,531        $950,000 $10,000,000,000
sum(dcc$amount <= 0)
#> [1] 20
```

``` r
glimpse(dcc[c(which.min(dcc$amount), which.max(dcc$amount)), ])
#> Rows: 2
#> Columns: 12
#> $ contract_number <chr> "CW53678", "CW66904"
#> $ title           <chr> "Procurememt Card Services", "DCSS Application for Stockbridge for MOBIS"
#> $ agency          <chr> "Contracting and Procurement (OCP)", "Contracting and Procurement (OCP)"
#> $ option_period   <chr> "Option 2", "Base Period"
#> $ start_date      <date> 2019-10-05, 2019-06-25
#> $ end_date        <date> 2020-10-04, 2020-06-24
#> $ award_date      <date> 2017-10-05, 2019-06-25
#> $ nigp_code       <chr> "9463550", "9180000"
#> $ vendor          <chr> "JP MORGAN CHASE BANK, NA", "Stockbridge Consulting LLC"
#> $ amount          <dbl> 0e+00, 1e+10
#> $ na_flag         <lgl> FALSE, FALSE
#> $ dupe_flag       <lgl> FALSE, FALSE
```

![](../plots/hist_amount-1.png)<!-- -->

#### Dates

We can add the calendar year from `award_date` with `lubridate::year()`

``` r
dcc <- mutate(dcc, award_year = year(award_date))
```

Aside from a few of contracts awarded much earlier, the date columns are
clean.

``` r
count_na(dcc$award_date)
#> [1] 2
min(dcc$award_date, na.rm = TRUE)
#> [1] "2009-12-15"
sum(dcc$award_year < 2016, na.rm = TRUE)
#> [1] 1384
max(dcc$award_date, na.rm = TRUE)
#> [1] "2020-04-28"
sum(dcc$award_date > today(), na.rm = TRUE)
#> [1] 0
```

![](../plots/bar_year-1.png)<!-- -->

## Conclude

1.  There are 6,100 records in the database.
2.  There are 10 duplicate records in the database.
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
#> 1.12M
```

The encoding of the exported file should be UTF-8 or ASCII.

``` r
enc <- system2("file", args = paste("-i", clean_path), stdout = TRUE)
str_replace_all(enc, clean_path, basename)
#> [1] "dc_contracts_clean.csv: application/csv; charset=utf-8"
```

## Dictionary

The following table describes the variables in our final exported file:

| Column            | Type        | Definition                                         |
| :---------------- | :---------- | :------------------------------------------------- |
| `contract_number` | `character` | Unique contract number                             |
| `title`           | `character` | Contract title                                     |
| `agency`          | `character` | Awarding agency name                               |
| `option_period`   | `character` | Option period awarded                              |
| `start_date`      | `double`    | Contract start date                                |
| `end_date`        | `double`    | Contract end date                                  |
| `award_date`      | `double`    | Contract awarded date                              |
| `nigp_code`       | `character` | National Institute of Governmental Purchasing code |
| `vendor`          | `character` | Recipient vendor name                              |
| `amount`          | `double`    | Contract amount awarded                            |
| `na_flag`         | `logical`   | Flag for missing date, amount, or name             |
| `dupe_flag`       | `logical`   | Flag for completely duplicated record              |
| `award_year`      | `double`    | Calendar year contract awarded                     |

``` r
write_lines(
  x = c("# District Of Columbia Contracts Data Dictionary\n", dict_md),
  path = here("dc", "contracts", "dc_contracts_dict.md"),
)
```
