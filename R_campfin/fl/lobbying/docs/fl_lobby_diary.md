Florida Lobbyists
================
Kiernan Nicholls
2019-10-08 17:34:46

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)

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
| `REPORT_QUARTER`               | Reporting period for the year                                                  |
| `REPORT_YEAR`                  | Reporting year for the report                                                  |
| `RECORD_TYPE`                  | Firm, Lobbyist or Principal                                                    |
| `FIRM_NAME`                    | Name of the lobbying firm                                                      |
| `CERTIFICATION_NAME`           | Name of the officer, owner or person responsible for certifying the compensat… |
| `TITLE`                        | Title of the officer, owner or person responsible for certifying the compensa… |
| `ADDRESS_LINE_1`               | First line of the address for the firm                                         |
| `ADDRESS_LINE_2`               | Second line of the address for the firm                                        |
| `CITY`                         | City on record for the firm                                                    |
| `STATE`                        | State on record for the firm                                                   |
| `POSTAL_CODE`                  | Postal code of address for the firm                                            |
| `ZIP_+4`                       | Plus four (4) of postal code                                                   |
| `COUNTRY`                      | Country code of where the firm is located                                      |
| `PHONE_NUMBER`                 | Phone number for the firm format:country code (area code) prefix-suffix exten… |
| `SUBMISSION_DATE`              | Date the compensation report was submitted                                     |
| `TOTAL_COMPENSATION_RANGE`     | Range of reported compensation on the report                                   |
| `LOBBYIST_NAME`                | Lobbyist name Last, First Middle, Suffix                                       |
| `PRINCIPAL_NAME`               | Principal’s name                                                               |
| `PRINCIPAL_ADDRESS_LINE_1`     | First line of the principal’s address                                          |
| `PRINCIPAL_ADDRESS_LINE_2`     | Second line of the principal’s address                                         |
| `PRINCIPAL_CITY_NAME`          | City where the principal is located                                            |
| `PRINCIPAL_STATE_NAME`         | State where the principal is located                                           |
| `PRINCIPAL_POSTAL_CODE`        | Postal Code where the principal is located                                     |
| `PRINCIPAL_ZIP_EXT`            | Plus four(+4) of the postal code where the principal is located                |
| `PRINCIPAL_COUNTRY_NAME`       | Country code where the principal is located                                    |
| `PRINCIPAL_PHONE_NUMBER`       | Phone number for the principal format:country code (area code) prefix-suffix … |
| `PRINCIPAL_COMPENSATION_RANGE` | Compensation received from an individual principal (range or specific amount … |
| `PRIME_FIRM_NAME`              | Name of prime contracting firm                                                 |
| `PRIME_FIRM_ADDRESS_LINE_1`    | First line of the prime contractor’s address                                   |
| `PRIME_FIRM_ADDRESS_LINE_2`    | Second line of prime contractor’s address                                      |
| `PRIME_FIRM_CITY_NAME`         | City where the prime contractor is located                                     |
| `PRIME_FIRM_STATE_NAME`        | State where the prime contractor is located                                    |
| `PRIME_FIRM_POSTAL_CODE`       | Postal code where the prime contractor is located                              |
| `PRIME_FIRM_ZIP_EXT`           | Plus four(+4) of the postal code where the prime contractor is located         |
| `PRIME_FIRM_COUNTRY_NAME`      | Country code of where the prime contractor is located                          |
| `PRIME_FIRM_PHONE_NUMBER`      | Phone number for the prime contractor format:country code (area code) prefix-… |

## Import

To create a single clean data file of lobbyist activity, we will first
download each file locally and read as a single data frame.

### Download

The data is separated into quarterly files by year. With the
`glue::glue()` function, we can create the URL for each file.

``` r
years <- rep(2008:2019, each = 8, length.out = 88)
quarters <- rep(1:4, length = 88)
branches <- rep(c("Executive", "Legislative"), each = 4, length.out = 88)
urls <- glue("https://floridalobbyist.gov/reports/{years}_Quarter{quarters}_{branches}.txt")
n_distinct(urls) == 11 * 4 * 2
#> [1] TRUE
```

This creates 88 distinct URLs, each corresponding to a separate file.

``` r
cat(paste("*", head(urls)), sep = "\n")
```

  - <https://floridalobbyist.gov/reports/2008_Quarter1_Executive.txt>
  - <https://floridalobbyist.gov/reports/2008_Quarter2_Executive.txt>
  - <https://floridalobbyist.gov/reports/2008_Quarter3_Executive.txt>
  - <https://floridalobbyist.gov/reports/2008_Quarter4_Executive.txt>
  - <https://floridalobbyist.gov/reports/2008_Quarter1_Legislative.txt>
  - <https://floridalobbyist.gov/reports/2008_Quarter2_Legislative.txt>

We can download each TXT file to the `/fl/data/raw` directory.

``` r
raw_dir <- here("fl", "lobbying", "data", "raw")
dir_create(raw_dir)
```

``` r
if (!all_files_new(raw_dir, glob = "*.txt$")) {
  for (url in urls) {
    download.file(url, destfile = str_c(raw_dir, basename(url), sep = "/"))
  }
}
```

    #> # A tibble: 88 x 4
    #>    path                                                type         size birth_time         
    #>    <chr>                                               <fct> <fs::bytes> <dttm>             
    #>  1 /fl/lobbying/data/raw/2008_Quarter1_Executive.txt   file         653K 2019-10-08 17:26:36
    #>  2 /fl/lobbying/data/raw/2008_Quarter1_Legislative.txt file         789K 2019-10-08 17:26:44
    #>  3 /fl/lobbying/data/raw/2008_Quarter2_Executive.txt   file         667K 2019-10-08 17:26:37
    #>  4 /fl/lobbying/data/raw/2008_Quarter2_Legislative.txt file         801K 2019-10-08 17:26:45
    #>  5 /fl/lobbying/data/raw/2008_Quarter3_Executive.txt   file         694K 2019-10-08 17:26:39
    #>  6 /fl/lobbying/data/raw/2008_Quarter3_Legislative.txt file         815K 2019-10-08 17:26:46
    #>  7 /fl/lobbying/data/raw/2008_Quarter4_Executive.txt   file         713K 2019-10-08 17:26:40
    #>  8 /fl/lobbying/data/raw/2008_Quarter4_Legislative.txt file         830K 2019-10-08 17:26:50
    #>  9 /fl/lobbying/data/raw/2009_Quarter1_Executive.txt   file         684K 2019-10-08 17:26:51
    #> 10 /fl/lobbying/data/raw/2009_Quarter1_Legislative.txt file         813K 2019-10-08 17:26:56
    #> # … with 78 more rows

### Read

``` r
fll <- dir_ls(raw_dir) %>% 
  vroom(
    delim = "\t",
    .name_repair = make_clean_names,
    id = "source_file",
    col_types = cols(
      .default = col_character(),
      REPORT_YEAR = col_double()
    )
  )
```

``` r
head(fll)
#> # A tibble: 6 x 37
#>   source_file report_quarter report_year record_type firm_name certification_n… title
#>   <chr>       <chr>                <dbl> <chr>       <chr>     <chr>            <chr>
#> 1 /home/kier… January - Mar…        2008 FIRM        4th Floo… Kari  Hebrank    Owner
#> 2 /home/kier… January - Mar…        2008 LOBBYIST    4th Floo… <NA>             <NA> 
#> 3 /home/kier… January - Mar…        2008 PRINCIPAL   4th Floo… <NA>             <NA> 
#> 4 /home/kier… January - Mar…        2008 PRINCIPAL   4th Floo… <NA>             <NA> 
#> 5 /home/kier… January - Mar…        2008 PRINCIPAL   4th Floo… <NA>             <NA> 
#> 6 /home/kier… January - Mar…        2008 PRINCIPAL   4th Floo… <NA>             <NA> 
#> # … with 30 more variables: address_line_1 <chr>, address_line_2 <chr>, city <chr>, state <chr>,
#> #   postal_code <chr>, zip_4 <chr>, country <chr>, phone_number <chr>, submission_date <chr>,
#> #   total_compensation_range <chr>, lobbyist_name <chr>, principal_name <chr>,
#> #   principal_address_line_1 <chr>, principal_address_line_2 <chr>, principal_city_name <chr>,
#> #   principal_state_name <chr>, principal_postal_code <chr>, principal_zip_ext <chr>,
#> #   principal_country_name <chr>, principal_phone_number <chr>,
#> #   principal_compensation_range <chr>, prime_firm_name <chr>, prime_firm_address_line_1 <chr>,
#> #   prime_firm_address_line_2 <chr>, prime_firm_city_name <chr>, prime_firm_state_name <chr>,
#> #   prime_firm_postal_code <chr>, prime_firm_zip_ext <chr>, prime_firm_country_name <chr>,
#> #   prime_firm_phone_number <chr>
tail(fll)
#> # A tibble: 6 x 37
#>   source_file report_quarter report_year record_type firm_name certification_n… title
#>   <chr>       <chr>                <dbl> <chr>       <chr>     <chr>            <chr>
#> 1 /home/kier… October - Dec…        2018 PRINCIPAL   Wilson &… <NA>             <NA> 
#> 2 /home/kier… October - Dec…        2018 PRINCIPAL   Wilson &… <NA>             <NA> 
#> 3 /home/kier… October - Dec…        2018 FIRM        Young Qu… Senior Partner … Seni…
#> 4 /home/kier… October - Dec…        2018 LOBBYIST    Young Qu… <NA>             <NA> 
#> 5 /home/kier… October - Dec…        2018 LOBBYIST    Young Qu… <NA>             <NA> 
#> 6 /home/kier… October - Dec…        2018 PRINCIPAL   Young Qu… <NA>             <NA> 
#> # … with 30 more variables: address_line_1 <chr>, address_line_2 <chr>, city <chr>, state <chr>,
#> #   postal_code <chr>, zip_4 <chr>, country <chr>, phone_number <chr>, submission_date <chr>,
#> #   total_compensation_range <chr>, lobbyist_name <chr>, principal_name <chr>,
#> #   principal_address_line_1 <chr>, principal_address_line_2 <chr>, principal_city_name <chr>,
#> #   principal_state_name <chr>, principal_postal_code <chr>, principal_zip_ext <chr>,
#> #   principal_country_name <chr>, principal_phone_number <chr>,
#> #   principal_compensation_range <chr>, prime_firm_name <chr>, prime_firm_address_line_1 <chr>,
#> #   prime_firm_address_line_2 <chr>, prime_firm_city_name <chr>, prime_firm_state_name <chr>,
#> #   prime_firm_postal_code <chr>, prime_firm_zip_ext <chr>, prime_firm_country_name <chr>,
#> #   prime_firm_phone_number <chr>
glimpse(sample_frac(fll))
#> Observations: 420,825
#> Variables: 37
#> $ source_file                  <chr> "/home/kiernan/R/accountability_datacleaning/R_campfin/fl/l…
#> $ report_quarter               <chr> "January - March", "July - September", "October - December"…
#> $ report_year                  <dbl> 2011, 2008, 2012, 2009, 2016, 2012, 2010, 2016, 2016, 2012,…
#> $ record_type                  <chr> "PRINCIPAL", "PRINCIPAL", "PRINCIPAL", "PRINCIPAL", "PRINCI…
#> $ firm_name                    <chr> "Ronald L. Book, P.A.", "Garrison Consulting Group", "Johns…
#> $ certification_name           <chr> NA, NA, NA, NA, NA, NA, NA, NA, "Senior Partner Al Cardenas…
#> $ title                        <chr> NA, NA, NA, NA, NA, NA, NA, NA, "Senior Partner", NA, "Owne…
#> $ address_line_1               <chr> NA, NA, NA, NA, NA, NA, NA, NA, "215 S Monroe St", NA, "Po …
#> $ address_line_2               <chr> NA, NA, NA, NA, NA, NA, NA, NA, "Ste 602", NA, NA, NA, NA, …
#> $ city                         <chr> NA, NA, NA, NA, NA, NA, NA, NA, "Tallahassee", NA, "Cocoa",…
#> $ state                        <chr> NA, NA, NA, NA, NA, NA, NA, NA, "FL", NA, "FL", NA, NA, NA,…
#> $ postal_code                  <chr> NA, NA, NA, NA, NA, NA, NA, NA, "32301", NA, "32923-0098", …
#> $ zip_4                        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ country                      <chr> NA, NA, NA, NA, NA, NA, NA, NA, "US", NA, "US", NA, NA, NA,…
#> $ phone_number                 <chr> NA, NA, NA, NA, NA, NA, NA, NA, "(850) 222-8900", NA, "(321…
#> $ submission_date              <chr> NA, NA, NA, NA, NA, NA, NA, NA, "08/11/2016", NA, "11/14/20…
#> $ total_compensation_range     <chr> NA, NA, NA, NA, NA, NA, NA, NA, "$250,000.00-$499,999.00", …
#> $ lobbyist_name                <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "Ch…
#> $ principal_name               <chr> "University Area Community Development Corporation", "Garri…
#> $ principal_address_line_1     <chr> "14013 N 22nd St", "2390 Sunset Bluff Dr", "Stephanie A. Le…
#> $ principal_address_line_2     <chr> NA, NA, "12780 Waterford Lakes Pky Ste 115", NA, "1947 Lee …
#> $ principal_city_name          <chr> "TAMPA", "JACKSONVILLE", "ORLANDO", "NEPTUNE BEACH", "Winte…
#> $ principal_state_name         <chr> "FLORIDA", "FLORIDA", "FLORIDA", "FLORIDA", "FL", "CALIFORN…
#> $ principal_postal_code        <chr> "33613", "32216", "32828", "32266", "32789", "94063", "3340…
#> $ principal_zip_ext            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ principal_country_name       <chr> "US", "US", "US", "US", "US", "US", "US", "US", NA, "US", N…
#> $ principal_phone_number       <chr> "(813)558-5216", "(904)725-7926", "(904)645-9936 x114", "(9…
#> $ principal_compensation_range <chr> "$20,000.00-$29,999.00", "$0.00", "$1.00-$9,999.00", "$0.00…
#> $ prime_firm_name              <chr> "Robert M. Levy & Associates", NA, NA, NA, NA, NA, NA, NA, …
#> $ prime_firm_address_line_1    <chr> "780 NE 69th Street", NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ prime_firm_address_line_2    <chr> "Suite 1703", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ prime_firm_city_name         <chr> "Miami", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ prime_firm_state_name        <chr> "FL", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ prime_firm_postal_code       <chr> "33138", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ prime_firm_zip_ext           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ prime_firm_country_name      <chr> "US", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ prime_firm_phone_number      <chr> "(305)758-1194", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
```
