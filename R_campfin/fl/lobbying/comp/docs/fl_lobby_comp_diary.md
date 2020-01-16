Florida Lobbyist Compensation
================
Kiernan Nicholls
2020-01-16 17:09:38

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
      - [About](#about)
      - [Variables](#variables)
  - [Import](#import)
      - [Download](#download)
      - [Read](#read)

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
  tidyverse, # data manipulation
  lubridate, # datetime strings
  gluedown, # printing markdown
  magrittr, # pipe opperators
  janitor, # dataframe clean
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  rvest, # read web pages
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

Data is obtained as tab-delinated files from the [Florida Lobbying
Registration Office](https://floridalobbyist.gov/) (LRO).

### About

> Delimited data files are made available below for compensation reports
> submitted online, beginning in 2007. Data files for the last eight
> quarters will be retained for each branch. The tab-delimited files
> below are in the (.TXT) format and can be imported into any word
> processor, spreadsheet, or database program.

### Variables

The LRO provides a variable key with definitions for each column in the
data sets.

| Data Element                   | Definition                                                                     |
| :----------------------------- | :----------------------------------------------------------------------------- |
| `report_quarter`               | Reporting period for the year                                                  |
| `report_year`                  | Reporting year for the report                                                  |
| `record_type`                  | Firm, Lobbyist or Principal                                                    |
| `firm_name`                    | Name of the lobbying firm                                                      |
| `certification_name`           | Name of the officer, owner or person responsible for certifying the compensat… |
| `title`                        | Title of the officer, owner or person responsible for certifying the compensa… |
| `address_line_1`               | First line of the address for the firm                                         |
| `address_line_2`               | Second line of the address for the firm                                        |
| `city`                         | City on record for the firm                                                    |
| `state`                        | State on record for the firm                                                   |
| `postal_code`                  | Postal code of address for the firm                                            |
| `zip_4`                        | Plus four (4) of postal code                                                   |
| `country`                      | Country code of where the firm is located                                      |
| `phone_number`                 | Phone number for the firm format:country code (area code) prefix-suffix exten… |
| `submission_date`              | Date the compensation report was submitted                                     |
| `total_compensation_range`     | Range of reported compensation on the report                                   |
| `lobbyist_name`                | Lobbyist name Last, First Middle, Suffix                                       |
| `principal_name`               | Principal’s name                                                               |
| `principal_address_line_1`     | First line of the principal’s address                                          |
| `principal_address_line_2`     | Second line of the principal’s address                                         |
| `principal_city_name`          | City where the principal is located                                            |
| `principal_state_name`         | State where the principal is located                                           |
| `principal_postal_code`        | Postal Code where the principal is located                                     |
| `principal_zip_ext`            | Plus four(+4) of the postal code where the principal is located                |
| `principal_country_name`       | Country code where the principal is located                                    |
| `principal_phone_number`       | Phone number for the principal format:country code (area code) prefix-suffix … |
| `principal_compensation_range` | Compensation received from an individual principal (range or specific amount … |
| `prime_firm_name`              | Name of prime contracting firm                                                 |
| `prime_firm_address_line_1`    | First line of the prime contractor’s address                                   |
| `prime_firm_address_line_2`    | Second line of prime contractor’s address                                      |
| `prime_firm_city_name`         | City where the prime contractor is located                                     |
| `prime_firm_state_name`        | State where the prime contractor is located                                    |
| `prime_firm_postal_code`       | Postal code where the prime contractor is located                              |
| `prime_firm_zip_ext`           | Plus four(+4) of the postal code where the prime contractor is located         |
| `prime_firm_country_name`      | Country code of where the prime contractor is located                          |
| `prime_firm_phone_number`      | Phone number for the prime contractor format:country code (area code) prefix-… |

## Import

To create a single clean data file of lobbyist activity, we will first
download each file locally and read as a single data frame.

### Download

The data is separated into quarterly files by year. The URL for each
file takes a consistent format. With the `tidyr::expand_grid()` and
`glue::glue()` functions, we can create a URL for all bombinations of
year, quarter, and branch.

``` r
urls <- 
  expand_grid(
    year = 2008:2019,
    quarter = 1:4,
    branch = c("Executive", "Legislative")
  ) %>% 
  mutate(
    url = glue("https://floridalobbyist.gov/reports/{year}_Quarter{quarter}_{branch}.txt")
  )
```

    #> # A tibble: 96 x 4
    #>     year quarter branch      url                                                              
    #>    <int>   <int> <chr>       <glue>                                                           
    #>  1  2008       1 Executive   https://floridalobbyist.gov/reports/2008_Quarter1_Executive.txt  
    #>  2  2008       1 Legislative https://floridalobbyist.gov/reports/2008_Quarter1_Legislative.txt
    #>  3  2008       2 Executive   https://floridalobbyist.gov/reports/2008_Quarter2_Executive.txt  
    #>  4  2008       2 Legislative https://floridalobbyist.gov/reports/2008_Quarter2_Legislative.txt
    #>  5  2008       3 Executive   https://floridalobbyist.gov/reports/2008_Quarter3_Executive.txt  
    #>  6  2008       3 Legislative https://floridalobbyist.gov/reports/2008_Quarter3_Legislative.txt
    #>  7  2008       4 Executive   https://floridalobbyist.gov/reports/2008_Quarter4_Executive.txt  
    #>  8  2008       4 Legislative https://floridalobbyist.gov/reports/2008_Quarter4_Legislative.txt
    #>  9  2009       1 Executive   https://floridalobbyist.gov/reports/2009_Quarter1_Executive.txt  
    #> 10  2009       1 Legislative https://floridalobbyist.gov/reports/2009_Quarter1_Legislative.txt
    #> # … with 86 more rows

``` r
urls <- pull(urls)
```

This creates 96 distinct URLs, each corresponding to a separate file.

``` r
md_bullet(head(urls))
```

  - <https://floridalobbyist.gov/reports/2008_Quarter1_Executive.txt>
  - <https://floridalobbyist.gov/reports/2008_Quarter1_Legislative.txt>
  - <https://floridalobbyist.gov/reports/2008_Quarter2_Executive.txt>
  - <https://floridalobbyist.gov/reports/2008_Quarter2_Legislative.txt>
  - <https://floridalobbyist.gov/reports/2008_Quarter3_Executive.txt>
  - <https://floridalobbyist.gov/reports/2008_Quarter3_Legislative.txt>

We can download each TXT file to the `/fl/data/raw` directory.

``` r
raw_dir <- here("fl", "lobbying", "comp", "data", "raw")
dir_create(raw_dir)
```

``` r
if (!all_files_new(raw_dir, glob = "*.txt$")) {
  for (url in urls) {
    download.file(url, destfile = str_c(raw_dir, basename(url), sep = "/"))
  }
}
```

    #> # A tibble: 96 x 4
    #>    path                                                     type         size birth_time         
    #>    <chr>                                                    <fct> <fs::bytes> <dttm>             
    #>  1 /fl/lobbying/comp/data/raw/2008_Quarter1_Executive.txt   file         653K 2020-01-16 14:43:40
    #>  2 /fl/lobbying/comp/data/raw/2008_Quarter1_Legislative.txt file         789K 2020-01-16 14:43:41
    #>  3 /fl/lobbying/comp/data/raw/2008_Quarter2_Executive.txt   file         667K 2020-01-16 14:43:42
    #>  4 /fl/lobbying/comp/data/raw/2008_Quarter2_Legislative.txt file         801K 2020-01-16 14:43:43
    #>  5 /fl/lobbying/comp/data/raw/2008_Quarter3_Executive.txt   file         694K 2020-01-16 14:43:44
    #>  6 /fl/lobbying/comp/data/raw/2008_Quarter3_Legislative.txt file         815K 2020-01-16 14:43:45
    #>  7 /fl/lobbying/comp/data/raw/2008_Quarter4_Executive.txt   file         713K 2020-01-16 14:43:46
    #>  8 /fl/lobbying/comp/data/raw/2008_Quarter4_Legislative.txt file         830K 2020-01-16 14:43:47
    #>  9 /fl/lobbying/comp/data/raw/2009_Quarter1_Executive.txt   file         684K 2020-01-16 14:43:48
    #> 10 /fl/lobbying/comp/data/raw/2009_Quarter1_Legislative.txt file         813K 2020-01-16 14:43:50
    #> # … with 86 more rows

### Read

``` r
read_quiet <- function(...) {
  suppressWarnings(suppressMessages(read_delim(...)))
}
fllc <- map_dfr(
  .x = dir_ls(raw_dir),
  .f = read_quiet,
  delim = "\t",
  escape_backslash = FALSE,
  escape_double = FALSE,
  .id = "SOURCE",
  col_types = cols(
    .default = col_character(),
    REPORT_QUARTER = col_factor(
      levels = c(
        "January - March",
        "April - June",
        "July - September",
        "October - December"
      )
    ),
    REPORT_YEAR = col_double(),
    TOTAL_COMPENSATION_RANGE = col_factor(
      levels = c(
        "$0.00", 
        "$1.00-$49,999.00",
        "$50,000.00-$99,999.00", 
        "$100,000.00-$249,999.00", 
        "$250,000.00-$499,999.00", 
        "$500,000.00-$999,999.00",
        "$1,000,000.00"
      )
    )
  )
)

fllc <- fllc %>% 
  clean_names("snake") %>% 
  mutate(source = str_extract(source, "([^_]+(?=.txt$))")) %>% 
  rename(branch = source)
```

Despite each quarterly file ostensibly containing all data of the same
type, the files really contain *three* types of records, each with a
different number of columns. We can split the combined data frame into a
list of data frames and then remove from each the empty columns.

``` r
fllc <- fllc %>% 
  group_split(record_type) %>% 
  map(remove_empty, "cols") %>% 
  set_names(c("firm", "lob", "pri"))
```

``` r
glimpse(fllc, max.level = 1)
#> List of 3
#>  $ firm:Classes 'tbl_df', 'tbl' and 'data.frame':    37379 obs. of  16 variables:
#>  $ lob :Classes 'tbl_df', 'tbl' and 'data.frame':    70061 obs. of  6 variables:
#>  $ pri :Classes 'tbl_df', 'tbl' and 'data.frame':    347719 obs. of  24 variables:
```

The data with a `record_type` of “LOBBYIST” contains one row for every
lobbyist alongside the firm for which they work. There is no information
on which particular clients that lobbyist is assigned.

``` r
glimpse(fllc$lob)
#> Observations: 70,061
#> Variables: 6
#> $ branch         <chr> "Executive", "Executive", "Executive", "Executive", "Executive", "Executi…
#> $ report_quarter <fct> January - March, January - March, January - March, January - March, Janua…
#> $ report_year    <dbl> 2008, 2008, 2008, 2008, 2008, 2008, 2008, 2008, 2008, 2008, 2008, 2008, 2…
#> $ record_type    <chr> "LOBBYIST", "LOBBYIST", "LOBBYIST", "LOBBYIST", "LOBBYIST", "LOBBYIST", "…
#> $ firm_name      <chr> "4th Floor Advocacy", "A. B. Dudley & Associates, Inc", "A. Stephen Hill …
#> $ lobbyist_name  <chr> "Kari B. Hebrank", "Alison B. Dudley", "A. Stephen Hill", "L. Carl Adams"…
```

For “FIRM” records, there are not 16 variables for every firm listed,
including geographic information and the range of total compensation
they have earned.

``` r
glimpse(fllc$firm)
#> Observations: 37,379
#> Variables: 16
#> $ branch                   <chr> "Executive", "Executive", "Executive", "Executive", "Executive"…
#> $ report_quarter           <fct> January - March, January - March, January - March, January - Ma…
#> $ report_year              <dbl> 2008, 2008, 2008, 2008, 2008, 2008, 2008, 2008, 2008, 2008, 200…
#> $ record_type              <chr> "FIRM", "FIRM", "FIRM", "FIRM", "FIRM", "FIRM", "FIRM", "FIRM",…
#> $ firm_name                <chr> "4th Floor Advocacy", "A. B. Dudley & Associates, Inc", "A. Ste…
#> $ certification_name       <chr> "Kari  Hebrank", "Alison B Dudley", "A. Stephen Hill", "L. Carl…
#> $ title                    <chr> "Owner", "Owner", "Owner", "Owner", "Owner", "Senior Partner", …
#> $ address_line_1           <chr> "7711 Deepwood Trail", "PO Box 428", "1373 Lloyd's Cove Rd", "P…
#> $ address_line_2           <chr> NA, NA, NA, NA, NA, "106 East College Ave Ste 1200", NA, NA, NA…
#> $ city                     <chr> "TALLAHASSEE", "TALLAHASSEE", "TALLAHASSEE", "TALLAHASSEE", "TA…
#> $ state                    <chr> "FLORIDA", "FLORIDA", "FLORIDA", "FLORIDA", "FLORIDA", "FLORIDA…
#> $ postal_code              <chr> "32317", "32302", "32312", "32302", "32301", "32301", "33187", …
#> $ country                  <chr> "US        ", "US        ", "US        ", "US        ", "US    …
#> $ phone_number             <chr> "(850)681-3290", "(850)556-6517", "(850)668-3900", "(850)224-08…
#> $ submission_date          <chr> "05/16/2008", "04/23/2008", "05/11/2008", "05/05/2008", "04/28/…
#> $ total_compensation_range <fct> "$1.00-$49,999.00", "$1.00-$49,999.00", "$50,000.00-$99,999.00"…
```

The “PRINCIPAL” records are the clients hiring firms (and their
lobbyist) to conduct lobbying work. The exact lobbyists working for each
client account are *not* listed, only the overal lobbying firm hired.

``` r
glimpse(fllc$pri)
#> Observations: 347,719
#> Variables: 24
#> $ branch                       <chr> "Executive", "Executive", "Executive", "Executive", "Execut…
#> $ report_quarter               <fct> January - March, January - March, January - March, January …
#> $ report_year                  <dbl> 2008, 2008, 2008, 2008, 2008, 2008, 2008, 2008, 2008, 2008,…
#> $ record_type                  <chr> "PRINCIPAL", "PRINCIPAL", "PRINCIPAL", "PRINCIPAL", "PRINCI…
#> $ firm_name                    <chr> "4th Floor Advocacy", "4th Floor Advocacy", "4th Floor Advo…
#> $ principal_name               <chr> "Florida Building Material Association", "Florida Fire Mars…
#> $ principal_address_line_1     <chr> "1303 Limit Ave", "225 Newburyport Ave", "1718 Main St # 30…
#> $ principal_address_line_2     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ principal_city_name          <chr> "MOUNT DORA", "ALTAMONTE SPRINGS", "SARASOTA", "NOKOMIS", "…
#> $ principal_state_name         <chr> "FLORIDA", "FLORIDA", "FLORIDA", "FLORIDA", "TEXAS", "FLORI…
#> $ principal_postal_code        <chr> "32757", "32701", "34236", "34274", "75069", "33543", "9458…
#> $ principal_zip_ext            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ principal_country_name       <chr> "US        ", "US        ", "US        ", "US        ", "US…
#> $ principal_phone_number       <chr> "(352)383-0366", "(865)467-8991", "(941)952-9294", "(941)48…
#> $ principal_compensation_range <chr> "$1.00-$9,999.00", "$1.00-$9,999.00", "$1.00-$9,999.00", "$…
#> $ prime_firm_name              <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ prime_firm_address_line_1    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ prime_firm_address_line_2    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ prime_firm_city_name         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ prime_firm_state_name        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ prime_firm_postal_code       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ prime_firm_zip_ext           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ prime_firm_country_name      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ prime_firm_phone_number      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
```
