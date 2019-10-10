Florida Lobbyists
================
Kiernan Nicholls
2019-10-09 16:39:01

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Wrangle](#wrangle)

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
    escape_backslash = FALSE,
    escape_double = TRUE,
    id = "source_file",
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
#> #   total_compensation_range <fct>, lobbyist_name <chr>, principal_name <chr>,
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
#> #   total_compensation_range <fct>, lobbyist_name <chr>, principal_name <chr>,
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
#> $ total_compensation_range     <fct> NA, NA, NA, NA, NA, NA, NA, NA, "$250,000.00-$499,999.00", …
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

## Wrangle

To improve the searchability of the database, we can normalize much of
the data using the `campfin` package. Much of the data is repeated for
both the principal lobbyist and then their firm.

### Firm

#### Address

``` r
packageVersion("tidyr")
#> [1] '1.0.0'
fll <- fll %>%
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

    #> # A tibble: 2,699 x 3
    #>    address_line_1              address_line_2 address_norm                      
    #>    <chr>                       <chr>          <chr>                             
    #>  1 1450 Brickell Avenue        Suite 2300     1450 BRICKELL AVENUE SUITE 2300   
    #>  2 3600 Maclay Boulevard       Suite 101      3600 MACLAY BOULEVARD SUITE 101   
    #>  3 Po Box 98                   <NA>           PO BOX 98                         
    #>  4 633 Sunflower Rd            <NA>           633 SUNFLOWER ROAD                
    #>  5 PO Box 1231                 <NA>           PO BOX 1231                       
    #>  6 2822 Remington Green Circle <NA>           2822 REMINGTON GREEN CIRCLE       
    #>  7 PRINCIPAL                   Wendy Bitner   PRINCIPAL WENDY BITNER            
    #>  8 1101 West Swann Avenue      <NA>           1101 WEST SWANN AVENUE            
    #>  9 693 Forest Lair             <NA>           693 FOREST LAIR                   
    #> 10 200 S Orange Ave Ste 2300   <NA>           200 SOUTH ORANGE AVENUE SUITE 2300
    #> # … with 2,689 more rows

#### Postal

``` r
fll <- fll %>% 
  mutate(
    zip_norm = normal_zip(
      zip = postal_code,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  fll$postal_code,
  fll$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage       prop_in n_distinct prop_na n_out n_diff
#>   <chr>         <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 postal_code   0.854        979   0.917  5062    544
#> 2 zip_norm      0.999        504   0.917    44     35
```

#### State

``` r
fll <- fll %>% 
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
  fll$state,
  fll$state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage      prop_in n_distinct prop_na n_out n_diff
#>   <chr>        <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 state        0.363         64   0.917 22153     44
#> 2 state_norm   0.998         36   0.917    60      8
```

#### City

``` r
fll <- fll %>% 
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
good_refine <- fll %>% 
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
    #>  3 FL         SILVER SPRINGS     SILVER SPRINGS        11
    #>  4 FL         SAINT AUGUSTINE    SAINT AUGUSTINE        8
    #>  5 FL         FERNANDINA BEACH   FERNANDINA BEACH       7
    #>  6 FL         NEW PORT RICHEY    NEW PORT RICHEY        6
    #>  7 FL         ALTAMONTE SPRINGS  ALTAMONTE SPRINGS      5
    #>  8 FL         JACKSONVILLE BEACH JACKSONVILLE BEACH     5
    #>  9 FL         SAINT PETERSBURG   SAINT PETERSBURG       5
    #> 10 FL         SANTA ROSA BEACH   SANTA ROSA BEACH       2
    #> 11 FL         BOCA RATON         BOCA RATON             1

``` r
fll <- fll %>% 
  left_join(good_refine, by = names(fll)) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

``` r
progress_table(
  fll$city_raw,
  fll$city_norm,
  fll$city_swap,
  fll$city_refine,
  compare = valid_city
)
#> # A tibble: 4 x 6
#>   stage       prop_in n_distinct prop_na n_out n_diff
#>   <chr>         <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 city_raw      0.579        436   0.917 14643    287
#> 2 city_norm     0.968        289   0.917  1110     92
#> 3 city_swap     0.972        229   0.918   963     31
#> 4 city_refine   0.972        229   0.918   963     31
```

#### Phone

``` r
fll %>%
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
#>  1 (813)831-1500 (813) 831-1500
#>  2 (904)612-3589 (904) 612-3589
#>  3 (305)698-7992 (305) 698-7992
#>  4 (305)342-6111 (305) 342-6111
#>  5 (850)421-9100 (850) 421-9100
#>  6 (813)421-3797 (813) 421-3797
#>  7 (850)212-8870 (850) 212-8870
#>  8 (850)222-7718 (850) 222-7718
#>  9 (850)561-3503 (850) 561-3503
#> 10 (850)222-5155 (850) 222-5155
#> # … with 1,164 more rows
```

### Principal

#### Address

``` r
fll <- fll %>%
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

    #> # A tibble: 15,931 x 3
    #>    principal_address_line_1         principal_address_line… principal_address_norm                 
    #>    <chr>                            <chr>                   <chr>                                  
    #>  1 1 N Ft Lauderdale Beach Blvd #1… <NA>                    1 NORTH FORT LAUDERDALE BEACH BOULEVAR…
    #>  2 3250 Lacey Road                  <NA>                    3250 LACEY ROAD                        
    #>  3 c/o 110 Paces Run                <NA>                    CO 110 PACES RUN                       
    #>  4 204 S Monroe St ste 105          <NA>                    204 SOUTH MONROE STREET SUITE 105      
    #>  5 631 US Hwy One Ste 304           <NA>                    631 US HIGHWAY ONE SUITE 304           
    #>  6 6 City Place Dr 10th Floor       <NA>                    6 CITY PLACE DRIVE 10TH FLOOR          
    #>  7 341 North Matiland Avenue        Suite 115               341 NORTH MATILAND AVENUE SUITE 115    
    #>  8 4209 Baymeadows Rd               <NA>                    4209 BAYMEADOWS ROAD                   
    #>  9 1990 Central Ave                 <NA>                    1990 CENTRAL AVENUE                    
    #> 10 7777 NW 72 Avenue                <NA>                    7777 NORTHWEST 72 AVENUE               
    #> # … with 15,921 more rows

#### Postal

``` r
fll <- fll %>% 
  mutate(
    principal_zip_norm = normal_zip(
      zip = principal_postal_code,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  fll$principal_postal_code,
  fll$principal_zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage                 prop_in n_distinct prop_na n_out n_diff
#>   <chr>                   <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 principal_postal_code   0.904       4715   0.239 30690   2359
#> 2 principal_zip_norm      0.992       2995   0.240  2450    370
```

#### State

``` r
fll <- fll %>% 
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
  fll$principal_state_name,
  fll$principal_state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage                prop_in n_distinct prop_na  n_out n_diff
#>   <chr>                  <dbl>      <dbl>   <dbl>  <dbl>  <dbl>
#> 1 principal_state_name   0.424        733   0.238 184822    687
#> 2 principal_state_norm   0.996        609   0.238   1226    560
```

#### City

``` r
fll <- fll %>% 
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
  fll$principal_city_name,
  fll$principal_city_norm,
  fll$principal_city_swap,
  compare = valid_city
)
#> # A tibble: 3 x 6
#>   stage               prop_in n_distinct prop_na  n_out n_diff
#>   <chr>                 <dbl>      <dbl>   <dbl>  <dbl>  <dbl>
#> 1 principal_city_name   0.483       2561   0.239 165630   1686
#> 2 principal_city_norm   0.922       1593   0.239  25101    511
#> 3 principal_city_swap   0.933       1293   0.248  21094    228
```

#### Phone

``` r
fll <- fll %>% 
  mutate(
    principal_phone_norm = normal_phone(
      number = principal_phone_number,
      format = "(%a) %e-%l",
      na_bad = FALSE,
      rm_ext = TRUE
    )
  )
```

    #> # A tibble: 13,629 x 2
    #>    principal_phone_number principal_phone_norm
    #>    <chr>                  <chr>               
    #>  1 (650)859-5548          (650) 859-5548      
    #>  2 (909)483-2444          (909) 483-2444      
    #>  3 (305)593-6100          (305) 593-6100      
    #>  4 (215)299-6000          (215) 299-6000      
    #>  5 (202)223-8204          (202) 223-8204      
    #>  6 (863)938-8121          (863) 938-8121      
    #>  7 (302)674-4089          (302) 674-4089      
    #>  8 (954)382-8229          (954) 382-8229      
    #>  9 (800)241-1853          (800) 241-1853      
    #> 10 (305)222-1212          (305) 222-1212      
    #> # … with 13,619 more rows

### Firm

#### Address

``` r
fll <- fll %>%
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

    #> # A tibble: 2,055 x 3
    #>    prime_firm_address_line_1 prime_firm_address_line_2 prime_firm_address_norm              
    #>    <chr>                     <chr>                     <chr>                                
    #>  1 215 South Monroe          Suite 200                 215 SOUTH MONROE SUITE 200           
    #>  2 713 E Park Ave            <NA>                      713 EAST PARK AVENUE                 
    #>  3 215 S. Monroe Street      2nd Floor                 215 SOUTH MONROE STREET 2ND FLOOR    
    #>  4 108 S. Monroe St., #200   <NA>                      108 SOUTH MONROE STREET 200          
    #>  5 519 E. Park Ave.          <NA>                      519 EAST PARK AVENUE                 
    #>  6 301 E. Pine Street        <NA>                      301 EAST PINE STREET                 
    #>  7 110 E. Broward Blvd.      Suite 1700                110 EAST BROWARD BOULEVARD SUITE 1700
    #>  8 301 East Pine Street      Suite 1400                301 EAST PINE STREET SUITE 1400      
    #>  9 US                        (305) 569-0015            US 305 569 0015                      
    #> 10 123 S> Calhoun St         <NA>                      123 SOUTH> CALHOUN STREET            
    #> # … with 2,045 more rows

#### Postal

``` r
fll <- fll %>% 
  mutate(
    prime_firm_zip_norm = normal_zip(
      zip = prime_firm_postal_code,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  fll$prime_firm_postal_code,
  fll$prime_firm_zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage                  prop_in n_distinct prop_na n_out n_diff
#>   <chr>                    <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 prime_firm_postal_code   0.964        229   0.971   434     97
#> 2 prime_firm_zip_norm      0.997        172   0.971    35     25
```

#### State

``` r
fll <- fll %>% 
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
  fll$prime_firm_state_name,
  fll$prime_firm_state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage                 prop_in n_distinct prop_na n_out n_diff
#>   <chr>                   <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 prime_firm_state_name   0.592         71   0.970  5131     62
#> 2 prime_firm_state_norm   0.993         43   0.970    82     32
```

#### City

``` r
fll <- fll %>% 
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
  fll$prime_firm_city_name,
  fll$prime_firm_city_norm,
  fll$prime_firm_city_swap,
  compare = valid_city
)
#> # A tibble: 3 x 6
#>   stage                prop_in n_distinct prop_na n_out n_diff
#>   <chr>                  <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 prime_firm_city_name  0.0887        178   0.969 11933    164
#> 2 prime_firm_city_norm  0.909         115   0.969  1186     61
#> 3 prime_firm_city_swap  0.958          77   0.971   508     24
```

#### Phone

``` r
fll <- fll %>% 
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
    #>  1 (813)527-0172           (813) 527-0172       
    #>  2 (850)841-1726           (850) 841-1726       
    #>  3 (305)529-9492           (305) 529-9492       
    #>  4 (202)783-6800           (202) 783-6800       
    #>  5 (850)224-9634           (850) 224-9634       
    #>  6 (305)433-6300           (305) 433-6300       
    #>  7 (850)509-6999           (850) 509-6999       
    #>  8 (866)330-1355           (866) 330-1355       
    #>  9 (850)570-2778           (850) 570-2778       
    #> 10 (850)205-9000           (850) 205-9000       
    #> # … with 334 more rows
