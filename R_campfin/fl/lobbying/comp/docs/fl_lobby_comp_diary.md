Florida Lobbyist Compensation
================
Kiernan Nicholls
2019-10-10 14:20:37

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
      - [About](#about)
      - [Variables](#variables)
  - [Import](#import)
      - [Download](#download)
      - [Read](#read)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
      - [Firm](#firm)
      - [Principal](#principal)
      - [Firm](#firm-1)

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
pacman::p_load_gh("kiernann/gluedown")
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
md_bullet(head(urls), cat = TRUE)
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
    #>  1 /fl/lobbying/comp/data/raw/2008_Quarter1_Executive.txt   file         653K 2019-10-10 12:31:52
    #>  2 /fl/lobbying/comp/data/raw/2008_Quarter1_Legislative.txt file         789K 2019-10-10 12:31:53
    #>  3 /fl/lobbying/comp/data/raw/2008_Quarter2_Executive.txt   file         667K 2019-10-10 12:31:55
    #>  4 /fl/lobbying/comp/data/raw/2008_Quarter2_Legislative.txt file         801K 2019-10-10 12:31:57
    #>  5 /fl/lobbying/comp/data/raw/2008_Quarter3_Executive.txt   file         694K 2019-10-10 12:31:59
    #>  6 /fl/lobbying/comp/data/raw/2008_Quarter3_Legislative.txt file         815K 2019-10-10 12:32:00
    #>  7 /fl/lobbying/comp/data/raw/2008_Quarter4_Executive.txt   file         713K 2019-10-10 12:32:02
    #>  8 /fl/lobbying/comp/data/raw/2008_Quarter4_Legislative.txt file         830K 2019-10-10 12:32:03
    #>  9 /fl/lobbying/comp/data/raw/2009_Quarter1_Executive.txt   file         684K 2019-10-10 12:32:06
    #> 10 /fl/lobbying/comp/data/raw/2009_Quarter1_Legislative.txt file         813K 2019-10-10 12:32:09
    #> # … with 86 more rows

### Read

``` r
fllc <- map_dfr(
  .x = dir_ls(raw_dir),
  .f = read_delim,
  delim = "\t",
  escape_backslash = FALSE,
  escape_double = FALSE,
  .id = "source_file",
  col_types = cols(
    .default = col_character(),
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

fllc <- clean_names(fllc)
```

## Explore

``` r
head(fllc)
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
#> #   total_compensation_range <fct>, lobbyist_name <chr>, principal_name <chr>,
#> #   principal_address_line_1 <chr>, principal_address_line_2 <chr>, principal_city_name <chr>,
#> #   principal_state_name <chr>, principal_postal_code <chr>, principal_zip_ext <chr>,
#> #   principal_country_name <chr>, principal_phone_number <chr>,
#> #   principal_compensation_range <chr>, prime_firm_name <chr>, prime_firm_address_line_1 <chr>,
#> #   prime_firm_address_line_2 <chr>, prime_firm_city_name <chr>, prime_firm_state_name <chr>,
#> #   prime_firm_postal_code <chr>, prime_firm_zip_ext <chr>, prime_firm_country_name <chr>,
#> #   prime_firm_phone_number <chr>
tail(fllc)
#> # A tibble: 6 x 37
#>   source_file report_quarter report_year record_type firm_name certification_n… title
#>   <chr>       <chr>                <dbl> <chr>       <chr>     <chr>            <chr>
#> 1 /home/kier… October - Dec…        2019 LOBBYIST    Theresa … <NA>             <NA> 
#> 2 /home/kier… October - Dec…        2019 PRINCIPAL   Theresa … <NA>             <NA> 
#> 3 /home/kier… October - Dec…        2019 PRINCIPAL   Theresa … <NA>             <NA> 
#> 4 /home/kier… October - Dec…        2019 PRINCIPAL   Theresa … <NA>             <NA> 
#> 5 /home/kier… October - Dec…        2019 PRINCIPAL   Theresa … <NA>             <NA> 
#> 6 /home/kier… October - Dec…        2019 PRINCIPAL   Theresa … <NA>             <NA> 
#> # … with 30 more variables: address_line_1 <chr>, address_line_2 <chr>, city <chr>, state <chr>,
#> #   postal_code <chr>, zip_4 <chr>, country <chr>, phone_number <chr>, submission_date <chr>,
#> #   total_compensation_range <fct>, lobbyist_name <chr>, principal_name <chr>,
#> #   principal_address_line_1 <chr>, principal_address_line_2 <chr>, principal_city_name <chr>,
#> #   principal_state_name <chr>, principal_postal_code <chr>, principal_zip_ext <chr>,
#> #   principal_country_name <chr>, principal_phone_number <chr>,
#> #   principal_compensation_range <chr>, prime_firm_name <chr>, prime_firm_address_line_1 <chr>,
#> #   prime_firm_address_line_2 <chr>, prime_firm_city_name <chr>, prime_firm_state_name <chr>,
#> #   prime_firm_postal_code <chr>, prime_firm_zip_ext <chr>, prime_firm_country_name <chr>,
#> #   prime_firm_phone_number <chr>
glimpse(sample_frac(fllc))
#> Observations: 443,915
#> Variables: 37
#> $ source_file                  <chr> "/home/kiernan/R/accountability_datacleaning/R_campfin/fl/l…
#> $ report_quarter               <chr> "January - March", "July - September", "October - December"…
#> $ report_year                  <dbl> 2011, 2008, 2012, 2009, 2016, 2019, 2012, 2010, 2016, 2016,…
#> $ record_type                  <chr> "PRINCIPAL", "PRINCIPAL", "PRINCIPAL", "PRINCIPAL", "PRINCI…
#> $ firm_name                    <chr> "Ronald L. Book, P.A.", "Garrison Consulting Group", "Johns…
#> $ certification_name           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "Senior Partner Al Card…
#> $ title                        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "Senior Partner", NA, "…
#> $ address_line_1               <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "215 S Monroe St", NA, …
#> $ address_line_2               <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "Ste 602", NA, NA, NA, …
#> $ city                         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "Tallahassee", NA, "Coc…
#> $ state                        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "FL", NA, "FL", NA, NA,…
#> $ postal_code                  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "32301", NA, "32923-009…
#> $ zip_4                        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ country                      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "US        ", NA, "US  …
#> $ phone_number                 <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "(850) 222-8900", NA, "…
#> $ submission_date              <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "08/11/2016", NA, "11/1…
#> $ total_compensation_range     <fct> NA, NA, NA, NA, NA, NA, NA, NA, NA, "$250,000.00-$499,999.0…
#> $ lobbyist_name                <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ principal_name               <chr> "University Area Community Development Corporation", "Garri…
#> $ principal_address_line_1     <chr> "14013 N 22nd St", "2390 Sunset Bluff Dr", "Stephanie A. Le…
#> $ principal_address_line_2     <chr> NA, NA, "12780 Waterford Lakes Pky Ste 115", NA, "1947 Lee …
#> $ principal_city_name          <chr> "TAMPA", "JACKSONVILLE", "ORLANDO", "NEPTUNE BEACH", "Winte…
#> $ principal_state_name         <chr> "FLORIDA", "FLORIDA", "FLORIDA", "FLORIDA", "FL", "FL", "CA…
#> $ principal_postal_code        <chr> "33613", "32216", "32828", "32266", "32789", "32792", "9406…
#> $ principal_zip_ext            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ principal_country_name       <chr> "US        ", "US        ", "US        ", "US        ", "US…
#> $ principal_phone_number       <chr> "(813)558-5216", "(904)725-7926", "(904)645-9936 x114", "(9…
#> $ principal_compensation_range <chr> "$20,000.00-$29,999.00", "$0.00", "$1.00-$9,999.00", "$0.00…
#> $ prime_firm_name              <chr> "Robert M. Levy & Associates", NA, NA, NA, NA, NA, NA, NA, …
#> $ prime_firm_address_line_1    <chr> "780 NE 69th Street", NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ prime_firm_address_line_2    <chr> "Suite 1703", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ prime_firm_city_name         <chr> "Miami", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ prime_firm_state_name        <chr> "FL", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ prime_firm_postal_code       <chr> "33138", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ prime_firm_zip_ext           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ prime_firm_country_name      <chr> "US        ", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ prime_firm_phone_number      <chr> "(305)758-1194", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
```

``` r
fllc <- distinct(fllc)
```

![](../plots/year_bar_quarter-1.png)<!-- -->

## Wrangle

To improve the searchability of the database, we can normalize much of
the data using the `campfin` package. Much of the data is repeated for
both the principal lobbyist and then their firm.

### Firm

#### Address

``` r
packageVersion("tidyr")
#> [1] '1.0.0'
fllc <- fllc %>%
  unite(
    starts_with("address_line"),
    col = "address_full",
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    address_norm = normal_address(
      address = address_full,
      add_abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-address_full)
```

    #> # A tibble: 2,685 x 3
    #>    address_line_1               address_line_2 address_norm                  
    #>    <chr>                        <chr>          <chr>                         
    #>  1 1520 Oldfield Dr             <NA>           1520 OLDFIELD DRIVE           
    #>  2 31 W Adams St Ste 204        <NA>           31 WEST ADAMS STREET SUITE 204
    #>  3 315 Kentuckey Ave            <NA>           315 KENTUCKEY AVENUE          
    #>  4 8161 SW 170Th Ter            <NA>           8161 SOUTHWEST 170TH TERRACE  
    #>  5 1431 Lloyd's Cove Rd         <NA>           1431 LLOYDS COVE ROAD         
    #>  6 115 East Park Avenue, Suite1 <NA>           115 EAST PARK AVENUE SUITE1   
    #>  7 111 Llano Cove               <NA>           111 LLANO COVE                
    #>  8 PO Box 111488                <NA>           PO BOX 111488                 
    #>  9 110 E College Ave            <NA>           110 EAST COLLEGE AVENUE       
    #> 10 437 Opal Court               <NA>           437 OPAL COURT                
    #> # … with 2,675 more rows

#### Postal

``` r
fllc <- fllc %>% 
  mutate(
    zip_norm = normal_zip(
      zip = postal_code,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  fllc$postal_code,
  fllc$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage       prop_in n_distinct prop_na n_out n_diff
#>   <chr>         <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 postal_code   0.829       1011   0.918  6245    569
#> 2 zip_norm      1.000        481   0.918    12      5
```

#### State

``` r
fllc <- fllc %>% 
  mutate(
    state_norm = normal_state(
      state = state,
      abbreviate = TRUE,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  fllc$state,
  fllc$state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage      prop_in n_distinct prop_na n_out n_diff
#>   <chr>        <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 state        0.394         69   0.918 22185     44
#> 2 state_norm   1.000         37   0.918    14      5
```

#### City

``` r
fllc <- fllc %>% 
  rename(city_raw = city) %>% 
  mutate(
    city_norm = normal_city(
      city = city_raw,
      geo_abbs = usps_city,
      na_rep = TRUE
    )
  ) %>% 
  left_join(
    y = zipcodes,
    by = c(
      "zip_norm" = "zip",
      "state_norm" = "state"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_dist = str_dist(city_norm, city_match),
    match_abb = is_abbrev(city_norm, city_match),
    city_swap = if_else(
      condition = match_abb | match_dist == 1,
      true = city_match,
      false = city_norm
    )
  )
```

``` r
good_refine <- fllc %>% 
  filter(state_norm == "FL") %>% 
  mutate(
    city_refine = city_swap %>% 
      refinr::key_collision_merge() %>% 
      refinr::n_gram_merge(numgram = 1)
  ) %>% 
  filter(city_norm != city_refine) %>% 
  inner_join(
    y = zipcodes,
    by = c(
      "city_refine" = "city",
      "zip_norm" = "zip",
      "state_norm" = "state"
    )
  )
```

    #> # A tibble: 11 x 4
    #>    state_norm city_swap          city_refine            n
    #>    <chr>      <chr>              <chr>              <int>
    #>  1 FL         TALLAHASSEE        TALLAHASSEE           38
    #>  2 FL         CLEARWATER BEACH   CLEARWATER BEACH      19
    #>  3 FL         NEW PORT RICHEY    NEW PORT RICHEY       12
    #>  4 FL         FERNANDINA BEACH   FERNANDINA BEACH      11
    #>  5 FL         SILVER SPRINGS     SILVER SPRINGS        11
    #>  6 FL         ALTAMONTE SPRINGS  ALTAMONTE SPRINGS      8
    #>  7 FL         SAINT AUGUSTINE    SAINT AUGUSTINE        8
    #>  8 FL         JACKSONVILLE BEACH JACKSONVILLE BEACH     5
    #>  9 FL         SAINT PETERSBURG   SAINT PETERSBURG       5
    #> 10 FL         SANTA ROSA BEACH   SANTA ROSA BEACH       2
    #> 11 FL         BOCA RATON         BOCA RATON             1

``` r
fllc <- fllc %>% 
  left_join(good_refine, by = names(fllc)) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

``` r
progress_table(
  fllc$city_raw,
  fllc$city_norm,
  fllc$city_swap,
  fllc$city_refine,
  compare = valid_city
)
#> # A tibble: 4 x 6
#>   stage       prop_in n_distinct prop_na n_out n_diff
#>   <chr>         <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 city_raw      0.551        408   0.918 16426    258
#> 2 city_norm     0.968        252   0.918  1162     48
#> 3 city_swap     0.972        238   0.918  1040     33
#> 4 city_refine   0.972        238   0.918  1040     33
```

#### Phone

``` r
fllc %>%
  filter(phone_number != phone_norm) %>% 
  select(
    phone_number,
    phone_norm
  ) %>% 
  drop_na() %>% 
  distinct() %>% 
  sample_frac()
#> # A tibble: 1,174 x 2
#>    phone_number  phone_norm    
#>    <chr>         <chr>         
#>  1 (239)425-2815 (239) 425-2815
#>  2 (813)477-2105 (813) 477-2105
#>  3 (813)931-3125 (813) 931-3125
#>  4 (850)222-1988 (850) 222-1988
#>  5 (850)769-7714 (850) 769-7714
#>  6 (850)222-2300 (850) 222-2300
#>  7 (863)287-5076 (863) 287-5076
#>  8 (850)668-3068 (850) 668-3068
#>  9 (813)777-5578 (813) 777-5578
#> 10 (407)835-0020 (407) 835-0020
#> # … with 1,164 more rows
```

### Principal

#### Address

``` r
fllc <- fllc %>%
  unite(
    starts_with("principal_address_line"),
    col = "principal_address_full",
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    principal_address_norm = normal_address(
      address = principal_address_full,
      add_abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-principal_address_full)
```

    #> # A tibble: 16,617 x 3
    #>    principal_address_line_1      principal_address_line… principal_address_norm                    
    #>    <chr>                         <chr>                   <chr>                                     
    #>  1 100 N Tampa St Ste 3620       <NA>                    100 NORTH TAMPA STREET SUITE 3620         
    #>  2 1201 S McCall Rd              <NA>                    1201 SOUTH MCCALL ROAD                    
    #>  3 11710 Olde English Drive      Unit K                  11710 OLDE ENGLISH DRIVE UNIT K           
    #>  4 901 New York Ave NW 3rd Floor <NA>                    901 NEW YORK AVENUE NORTHWEST 3RD FLOOR   
    #>  5 150 Headquarters Plaza        5th Floor - East Tower  150 HEADQUARTERS PLAZA 5TH FLOOR EAST TOW…
    #>  6 1901 L St NW Ste 800          <NA>                    1901 L STREET NORTHWEST SUITE 800         
    #>  7 7000 Cardinal Place           <NA>                    7000 CARDINAL PLACE                       
    #>  8 5256 Peachtree Road           Suite 135               5256 PEACHTREE ROAD SUITE 135             
    #>  9 10880 Lin Page Pl             <NA>                    10880 LIN PAGE PLACE                      
    #> 10 399 Park Avenue - 16th Floor  Attn: Bradley Tusk      399 PARK AVENUE 16TH FLOOR ATTN BRADLEY T…
    #> # … with 16,607 more rows

#### Postal

``` r
fllc <- fllc %>% 
  mutate(
    principal_zip_norm = normal_zip(
      zip = principal_postal_code,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  fllc$principal_postal_code,
  fllc$principal_zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage                 prop_in n_distinct prop_na n_out n_diff
#>   <chr>                   <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 principal_postal_code   0.892       4665   0.238 36653   2270
#> 2 principal_zip_norm      0.994       2702   0.239  2155    126
```

#### State

``` r
fllc <- fllc %>% 
  mutate(
    principal_state_norm = normal_state(
      state = principal_state_name,
      abbreviate = TRUE,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  fllc$principal_state_name,
  fllc$principal_state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage                prop_in n_distinct prop_na  n_out n_diff
#>   <chr>                  <dbl>      <dbl>   <dbl>  <dbl>  <dbl>
#> 1 principal_state_name   0.454        246   0.237 184856    200
#> 2 principal_state_norm   0.998        116   0.237    735     67
```

#### City

``` r
fllc <- fllc %>% 
  mutate(
    principal_city_norm = normal_city(
      city = principal_city_name,
      geo_abbs = usps_city,
      na_rep = TRUE
    )
  ) %>% 
  left_join(
    y = zipcodes,
    by = c(
      "principal_zip_norm" = "zip",
      "principal_state_norm" = "state"
    )
  ) %>% 
  rename(principal_city_match = city) %>% 
  mutate(
    principal_match_dist = str_dist(principal_city_norm, principal_city_match),
    principal_match_abb = is_abbrev(principal_city_norm, principal_city_match),
    principal_city_swap = if_else(
      condition = principal_match_abb | principal_match_dist == 1,
      true = principal_city_match,
      false = principal_city_norm
    )
  )
```

``` r
progress_table(
  fllc$principal_city_name,
  fllc$principal_city_norm,
  fllc$principal_city_swap,
  compare = valid_city
)
#> # A tibble: 3 x 6
#>   stage               prop_in n_distinct prop_na  n_out n_diff
#>   <chr>                 <dbl>      <dbl>   <dbl>  <dbl>  <dbl>
#> 1 principal_city_name   0.457       2596   0.237 183795   1720
#> 2 principal_city_norm   0.921       1567   0.237  26647    447
#> 3 principal_city_swap   0.933       1338   0.245  22553    237
```

#### Phone

``` r
fllc <- fllc %>% 
  mutate(
    principal_phone_norm = normal_phone(
      number = principal_phone_number,
      format = "(%a) %e-%l",
      na_bad = FALSE,
      rm_ext = TRUE
    )
  )
```

    #> # A tibble: 13,617 x 2
    #>    principal_phone_number principal_phone_norm
    #>    <chr>                  <chr>               
    #>  1 (850)521-4918          (850) 521-4918      
    #>  2 (813)287-5032          (813) 287-5032      
    #>  3 (414)343-4056          (414) 343-4056      
    #>  4 (561)994-8366          (561) 994-8366      
    #>  5 +1 8509267003          (850) 926-7003      
    #>  6 (561)775-1125          (561) 775-1125      
    #>  7 (305)891-8811          (305) 891-8811      
    #>  8 (941)444-1440          (941) 444-1440      
    #>  9 (813)223-0800          (813) 223-0800      
    #> 10 (850)357-7357          (850) 357-7357      
    #> # … with 13,607 more rows

### Firm

#### Address

``` r
fllc <- fllc %>%
  unite(
    starts_with("prime_firm_address_line"),
    col = "prime_firm_address_full",
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    prime_firm_address_norm = normal_address(
      address = prime_firm_address_full,
      add_abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-prime_firm_address_full)
```

    #> # A tibble: 1,786 x 3
    #>    prime_firm_address_line_1          prime_firm_address_line… prime_firm_address_norm             
    #>    <chr>                              <chr>                    <chr>                               
    #>  1 Post Office box 10909              <NA>                     POST OFFICE BOX 10909               
    #>  2 108 South Monroe St.               <NA>                     108 SOUTH MONROE STREET             
    #>  3 600 Grant Street                   Suite 5010               600 GRANT STREET SUITE 5010         
    #>  4 2350 Coral Way                     "301 "                   2350 CORAL WAY 301                  
    #>  5 450 E. Las Olas Blvd.              1250                     450 EAST LAS OLAS BOULEVARD 1250    
    #>  6 P.O. Box 3068                      <NA>                     PO BOX 3068                         
    #>  7 2999 N.E. 191st Street, Penthouse… <NA>                     2999 NORTHEAST 191ST STREET PENTHOU…
    #>  8 215 S/ Monroe, 2nd floor           <NA>                     215 SOUTH MONROE 2ND FLOOR          
    #>  9 "301 South Bronough Street "       <NA>                     301 SOUTH BRONOUGH STREET           
    #> 10 PO Box 10011                       <NA>                     PO BOX 10011                        
    #> # … with 1,776 more rows

#### Postal

``` r
fllc <- fllc %>% 
  mutate(
    prime_firm_zip_norm = normal_zip(
      zip = prime_firm_postal_code,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  fllc$prime_firm_postal_code,
  fllc$prime_firm_zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage                  prop_in n_distinct prop_na n_out n_diff
#>   <chr>                    <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 prime_firm_postal_code   0.963        234   0.971   480     94
#> 2 prime_firm_zip_norm      0.998        169   0.971    22     17
```

#### State

``` r
fllc <- fllc %>% 
  mutate(
    prime_firm_state_norm = normal_state(
      state = prime_firm_state_name,
      abbreviate = TRUE,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  fllc$prime_firm_state_name,
  fllc$prime_firm_state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage                 prop_in n_distinct prop_na n_out n_diff
#>   <chr>                   <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 prime_firm_state_name   0.598         66   0.970  5383     56
#> 2 prime_firm_state_norm   0.994         32   0.970    76     20
```

#### City

``` r
fllc <- fllc %>% 
  mutate(
    prime_firm_city_norm = normal_city(
      city = prime_firm_city_name,
      geo_abbs = usps_city,
      na_rep = TRUE
    )
  ) %>% 
  left_join(
    y = zipcodes,
    by = c(
      "prime_firm_zip_norm" = "zip",
      "prime_firm_state_norm" = "state"
    )
  ) %>% 
  rename(prime_firm_city_match = city) %>% 
  mutate(
    prime_firm_match_dist = str_dist(prime_firm_city_norm, prime_firm_city_match),
    prime_firm_match_abb = is_abbrev(prime_firm_city_norm, prime_firm_city_match),
    prime_firm_city_swap = if_else(
      condition = prime_firm_match_abb | prime_firm_match_dist == 1,
      true = prime_firm_city_match,
      false = prime_firm_city_norm
    )
  )
```

``` r
progress_table(
  fllc$prime_firm_city_name,
  fllc$prime_firm_city_norm,
  fllc$prime_firm_city_swap,
  compare = valid_city
)
#> # A tibble: 3 x 6
#>   stage                prop_in n_distinct prop_na n_out n_diff
#>   <chr>                  <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 prime_firm_city_name  0.0900        200   0.970 12181    186
#> 2 prime_firm_city_norm  0.948         123   0.970   692     63
#> 3 prime_firm_city_swap  0.959          84   0.971   532     25
```

#### Phone

``` r
fllc <- fllc %>% 
  mutate(
    prime_firm_phone_norm = normal_phone(
      number = prime_firm_phone_number,
      format = "(%a) %e-%l",
      na_bad = FALSE,
      rm_ext = TRUE
    )
  )
```

    #> # A tibble: 344 x 2
    #>    prime_firm_phone_number prime_firm_phone_norm
    #>    <chr>                   <chr>                
    #>  1 (850)777-0444           (850) 777-0444       
    #>  2 (865)637-6055           (865) 637-6055       
    #>  3 (850)513-3379           (850) 513-3379       
    #>  4 (850)878-2411           (850) 878-2411       
    #>  5 (850)224-6789           (850) 224-6789       
    #>  6 (954)788-7934           (954) 788-7934       
    #>  7 (305)374-5600           (305) 374-5600       
    #>  8 (850)224-5081           (850) 224-5081       
    #>  9 (305)935-1866           (305) 935-1866       
    #> 10 +1 8502518898           (850) 251-8898       
    #> # … with 334 more rows
