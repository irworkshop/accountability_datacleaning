Arizona Licenses
================
Kiernan Nicholls
Tue Jun 14 12:34:24 2022

-   <a href="#project" id="toc-project">Project</a>
-   <a href="#objectives" id="toc-objectives">Objectives</a>
-   <a href="#packages" id="toc-packages">Packages</a>
-   <a href="#source" id="toc-source">Source</a>
-   <a href="#download" id="toc-download">Download</a>
-   <a href="#read" id="toc-read">Read</a>
-   <a href="#explore" id="toc-explore">Explore</a>
    -   <a href="#missing" id="toc-missing">Missing</a>
    -   <a href="#duplicates" id="toc-duplicates">Duplicates</a>
    -   <a href="#categorical" id="toc-categorical">Categorical</a>
    -   <a href="#dates" id="toc-dates">Dates</a>
-   <a href="#wrangle" id="toc-wrangle">Wrangle</a>
    -   <a href="#address" id="toc-address">Address</a>
    -   <a href="#zip" id="toc-zip">ZIP</a>
    -   <a href="#state" id="toc-state">State</a>
    -   <a href="#city" id="toc-city">City</a>
-   <a href="#conclude" id="toc-conclude">Conclude</a>
-   <a href="#export" id="toc-export">Export</a>
-   <a href="#upload" id="toc-upload">Upload</a>

<!-- Place comments regarding knitting here -->

## Project

The Accountability Project is an effort to cut across data silos and
give journalists, policy professionals, activists, and the public at
large a simple way to search across huge volumes of public data about
people and organizations.

Our goal is to standardize public data on a few key fields by thinking
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

``` r
if (!require("pacman")) {
  install.packages("pacman")
}
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  gluedown, # printing markdown
  janitor, # clean data frames
  campfin, # custom irw tools
  aws.s3, # aws cloud storage
  refinr, # cluster & merge
  scales, # format strings
  knitr, # knit documents
  vroom, # fast reading
  rvest, # scrape html
  glue, # code strings
  here, # project paths
  httr, # http requests
  fs # local storage 
)
```

This diary was run using `campfin` version 1.0.8.9300.

``` r
packageVersion("campfin")
#> [1] '1.0.8.9300'
```

This document should be run as part of the `R_tap` project, which lives
as a sub-directory of the more general, language-agnostic
[`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning)
GitHub repository.

The `R_tap` project uses the [RStudio
projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects)
feature and should be run as such. The project also uses the dynamic
`here::here()` tool for file paths relative to *your* machine.

``` r
# where does this document knit?
here::i_am("state/az/licenses/docs/az_licenses_diary.Rmd")
```

## Source

> Last Updated 06/14/2022.
>
> For the best results finding a specific registrant, please enter only
> their license number and hit apply.
>
> Registrants, if you believe the information regarding your license on
> this search is inaccurate or missing, please email <news@azbtr.gov>
> citing the discrepancy.
>
> In-Training Designations are NOT included in this search.
>
> Do not use abbreviations in the State Field (type Arizona, not AZ).
>
> A spreadsheet of the results of a search can be downloaded by
> selecting the Export CSV box to the right.
>
> Please note that Board staff cannot make recommendations regarding the
> procurement of registrant services.

## Download

``` r
raw_url <- modify_url(
  url = "https://btr.az.gov/",
  path = c(
    "sites/default/files/views_data_export",
    "registered_professional_search_data_export_1",
    "1655222496/Registered_proffessional_list.csv"
  )
)
```

``` r
raw_dir <- dir_create(here("state", "az", "licenses", "data", "raw"))
raw_csv <- path(raw_dir, basename(raw_url))
```

``` r
if (!file_exists(raw_csv)) {
  GET(raw_url, write_disk(raw_csv), progress("down"))
}
```

## Read

``` r
azl <- read_delim(
  file = raw_csv,
  delim = ",",
  escape_backslash = FALSE,
  escape_double = FALSE,
  locale = locale(date_format = "%d %b %Y"),
  col_types = cols(
    .default = col_character(),
    `License Number` = col_integer(),
    `Board Action Date` = col_date(),
    `Expiration Date` = col_date()
  )
)
```

``` r
azl <- clean_names(azl, case = "snake")
```

## Explore

There are 70,696 rows of 13 columns. Each record represents a single
professional or occupation license.

``` r
glimpse(azl)
#> Rows: 70,696
#> Columns: 13
#> $ license_number    <int> 9999, 9997, 9972, 9968, 9930, 9928, 9921, 9919, 9918, 9896, 9892, 9883, 9881, 9819, 9793, 97…
#> $ first_name        <chr> "JOHN", "HJALMAR", "ALAN", "HOWARD", "HOWARD", "ALAN", "JOE", "JOSEPH", "JAMES", "Henry", "R…
#> $ last_name         <chr> "KUHN", "HJALMARSON", "MEAD", "PARSELL", "PARSELL", "MEAD", "HILL", "HAYNES", "HAWTHORNE", "…
#> $ license_status    <chr> "Active", "Delinquent", "Delinquent", "Delinquent", "Delinquent", "Inactive", "Active", "Ina…
#> $ discipline        <chr> "ENGINEER/CIVIL", "ENGINEER/CIVIL", "LAND SURVEYOR", "ENGINEER/STRUCTURAL", "ENGINEER/CIVIL"…
#> $ board_action_date <date> 1975-10-10, 1975-10-10, 1975-12-20, 1975-01-27, 1975-01-27, 1975-12-20, 1975-10-10, 1975-10…
#> $ expiration_date   <date> 2024-06-30, 2021-03-31, 2021-09-30, 2021-12-31, 2021-12-31, NA, 2024-03-31, NA, 2024-03-31,…
#> $ address_line_1    <chr> NA, "1381 S. Saddleback Drive", "4734 B  LA VILLA MARINA, UNIT B4734", "4854 MAIN ST", "4854…
#> $ address_line_2    <chr> NA, NA, NA, NA, NA, NA, "Suite 440", NA, NA, NA, NA, NA, NA, NA, "Suite 600", NA, NA, NA, NA…
#> $ city              <chr> NA, "Cottonwood,", "MARINA DEL REY,", "YORBA LINDA,", "YORBA LINDA,", "MARINA DEL REY,", "De…
#> $ state             <chr> NA, "Arizona", "California", "California", "California", "California", "Texas", "Texas", "Ar…
#> $ zip               <chr> NA, "86326", "90292", "92886", "92886", "90292", "75115", "79606", "85718", "86442", "86442"…
#> $ phone             <chr> NA, "9286340278", "3108211715", "714-777-3765", "7146420511", "310211715", "972-283-5111", "…
tail(azl)
#> # A tibble: 6 × 13
#>   license_number first_name last_name license_status discipline     board_action_date expiration_date address_line_1    
#>            <int> <chr>      <chr>     <chr>          <chr>          <date>            <date>          <chr>             
#> 1            483 ROBERT     RUPKEY    Expired        ENGINEER/CIVIL 1929-10-10        1998-03-31      1726 E GRANADA RD 
#> 2            470 ORVILLE    BELL      Cancelled      ARCHITECT      1929-10-10        1987-03-31      WRONG ADDRESS     
#> 3            453 JOSEPH     FRAPS     Cancelled      ENGINEER/CIVIL 1928-10-10        1987-12-31      WRONG ADDRESS     
#> 4            373 DWIGHT     CHENAULT  Expired        ARCHITECT      1927-10-10        1993-06-30      1571 FAIR PARK AVE
#> 5            359 GLENTON    SYKES     Cancelled      ENGINEER/CIVIL 1926-10-10        1986-06-30      480 RUDASILL RD   
#> 6            232 E          HERRERAS  Cancelled      ARCHITECT      1924-10-10        1991-03-31      1331 E WAVERLY ST 
#> # … with 5 more variables: address_line_2 <chr>, city <chr>, state <chr>, zip <chr>, phone <chr>
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(azl, count_na)
#> # A tibble: 13 × 4
#>    col               class      n        p
#>    <chr>             <chr>  <int>    <dbl>
#>  1 license_number    <int>      0 0       
#>  2 first_name        <chr>      0 0       
#>  3 last_name         <chr>      0 0       
#>  4 license_status    <chr>      0 0       
#>  5 discipline        <chr>     14 0.000198
#>  6 board_action_date <date>    20 0.000283
#>  7 expiration_date   <date> 13452 0.190   
#>  8 address_line_1    <chr>   1128 0.0160  
#>  9 address_line_2    <chr>  59076 0.836   
#> 10 city              <chr>   1061 0.0150  
#> 11 state             <chr>   2269 0.0321  
#> 12 zip               <chr>   1127 0.0159  
#> 13 phone             <chr>  10868 0.154
```

We can flag any record missing a key variable needed to identify a
transaction.

``` r
key_vars <- c("board_action_date", "last_name", "discipline")
azl <- flag_na(azl, all_of(key_vars))
sum(azl$na_flag)
#> [1] 34
```

``` r
azl %>% 
  filter(na_flag) %>% 
  select(all_of(key_vars))
#> # A tibble: 34 × 3
#>    board_action_date last_name  discipline    
#>    <date>            <chr>      <chr>         
#>  1 NA                Skinner    ENGINEER/CIVIL
#>  2 NA                Yorgason   ALARM AGENT   
#>  3 NA                Viramontes ALARM AGENT   
#>  4 NA                Saul       ALARM AGENT   
#>  5 NA                Barajas    ALARM AGENT   
#>  6 NA                Edmison    ALARM AGENT   
#>  7 NA                Ives       ALARM AGENT   
#>  8 NA                Kochheiser ALARM AGENT   
#>  9 NA                Ruh        ALARM AGENT   
#> 10 NA                Sorcinelli ALARM AGENT   
#> # … with 24 more rows
```

### Duplicates

We can also flag any record completely duplicated across every column.

``` r
azl <- flag_dupes(azl, -license_number)
sum(azl$dupe_flag)
#> [1] 245
```

``` r
azl %>% 
  filter(dupe_flag) %>% 
  select(all_of(key_vars)) %>% 
  arrange(board_action_date)
#> # A tibble: 245 × 3
#>    board_action_date last_name  discipline         
#>    <date>            <chr>      <chr>              
#>  1 1955-10-10        GRUNDSTEDT ENGINEER/MINING    
#>  2 1955-10-10        GRUNDSTEDT ENGINEER/MINING    
#>  3 1959-10-10        SARVIS     ENGINEER/CIVIL     
#>  4 1959-10-10        SARVIS     ENGINEER/CIVIL     
#>  5 1963-10-10        GERVASIO   ENGINEER/STRUCTURAL
#>  6 1963-10-10        GERVASIO   ENGINEER/CIVIL     
#>  7 1963-10-10        GERVASIO   ENGINEER/STRUCTURAL
#>  8 1963-10-10        GERVASIO   ENGINEER/CIVIL     
#>  9 1964-03-13        CORLEY     ENGINEER/CIVIL     
#> 10 1964-03-13        CORLEY     ENGINEER/CIVIL     
#> # … with 235 more rows
```

### Categorical

``` r
col_stats(azl, n_distinct)
#> # A tibble: 15 × 4
#>    col               class      n         p
#>    <chr>             <chr>  <int>     <dbl>
#>  1 license_number    <int>  70369 0.995    
#>  2 first_name        <chr>   8549 0.121    
#>  3 last_name         <chr>  34814 0.492    
#>  4 license_status    <chr>     18 0.000255 
#>  5 discipline        <chr>     26 0.000368 
#>  6 board_action_date <date>  4279 0.0605   
#>  7 expiration_date   <date>  2624 0.0371   
#>  8 address_line_1    <chr>  54841 0.776    
#>  9 address_line_2    <chr>   4469 0.0632   
#> 10 city              <chr>   7665 0.108    
#> 11 state             <chr>     94 0.00133  
#> 12 zip               <chr>  11271 0.159    
#> 13 phone             <chr>  50218 0.710    
#> 14 na_flag           <lgl>      2 0.0000283
#> 15 dupe_flag         <lgl>      2 0.0000283
```

![](../plots/distinct-plots-1.png)<!-- -->![](../plots/distinct-plots-2.png)<!-- -->

### Dates

We can add the calendar year from `date` with `lubridate::year()`

``` r
azl <- mutate(azl, year = year(board_action_date))
```

``` r
count_na(azl$board_action_date)
#> [1] 20
min(azl$board_action_date, na.rm = TRUE)
#> [1] "1924-10-10"
mean(azl$year < 2000, na.rm = TRUE)
#> [1] 0.4059794
max(azl$board_action_date, na.rm = TRUE)
#> [1] "2022-06-13"
sum(azl$board_action_date > today(), na.rm = TRUE)
#> [1] 0
```

![](../plots/bar-year-1.png)<!-- -->

## Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are tailor made to facilitate this process.

### Address

For the street `addresss` variable, the `campfin::normal_address()`
function will force consistence case, remove punctuation, and abbreviate
official USPS suffixes.

``` r
addr_norm <- azl %>% 
  distinct(address_line_1, address_line_2) %>% 
  mutate(
    address_norm_line_1 = normal_address(
      address = address_line_1,
      abbs = usps_street,
      na_rep = TRUE
    ),
    address_norm_line_2 = normal_address(
      address = address_line_2,
      abbs = usps_street,
      na_rep = TRUE,
      abb_end = FALSE
    )
  ) %>% 
  unite(
    col = address_norm,
    starts_with("address_norm"),
    sep = " ",
    remove = TRUE,
    na.rm = TRUE
  ) %>% 
  mutate(across(address_norm, na_if, ""))
```

``` r
addr_norm
#> # A tibble: 56,458 × 3
#>    address_line_1                      address_line_2 address_norm                     
#>    <chr>                               <chr>          <chr>                            
#>  1 <NA>                                <NA>           <NA>                             
#>  2 1381 S. Saddleback Drive            <NA>           1381 S SADDLEBACK DR             
#>  3 4734 B  LA VILLA MARINA, UNIT B4734 <NA>           4734 B LA VILLA MARINA UNIT B4734
#>  4 4854 MAIN ST                        <NA>           4854 MAIN ST                     
#>  5 4734 LA VILLA MARINA UNIT B         <NA>           4734 LA VILLA MARINA UNIT B      
#>  6 1801 N. Hampton Rd                  Suite 440      1801 N HAMPTON RD STE 440        
#>  7 5066 SUE LOOKOUT                    <NA>           5066 SUE LOOKOUT                 
#>  8 5700 N PLACITA DEL TRUENO           <NA>           5700 N PLACITA DEL TRUENO        
#>  9 303 Thunderbird Ln                  <NA>           303 THUNDERBIRD LN               
#> 10 1301 LOUSE RD                       <NA>           1301 LOUSE RD                    
#> # … with 56,448 more rows
```

``` r
azl <- left_join(azl, addr_norm, by = c("address_line_1", "address_line_2"))
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
azl <- azl %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  azl$zip,
  azl$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 × 6
#>   stage        prop_in n_distinct prop_na n_out n_diff
#>   <chr>          <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 azl$zip        0.952      11271  0.0159  3335   2643
#> 2 azl$zip_norm   0.989       9407  0.0195   796    535
```

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

``` r
azl <- azl %>% 
  mutate(
    state_norm = normal_state(
      state = state,
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = valid_state
    )
  )
```

``` r
azl %>% 
  filter(state != state_norm) %>% 
  count(state, state_norm, sort = TRUE)
#> # A tibble: 55 × 3
#>    state      state_norm     n
#>    <chr>      <chr>      <int>
#>  1 Arizona    AZ         25417
#>  2 California CA         10020
#>  3 Texas      TX          3589
#>  4 Colorado   CO          3068
#>  5 Utah       UT          2783
#>  6 Washington WA          1459
#>  7 Illinois   IL          1388
#>  8 Nevada     NV          1372
#>  9 Florida    FL          1300
#> 10 Missouri   MO          1212
#> # … with 45 more rows
```

``` r
progress_table(
  azl$state,
  azl$state_norm,
  compare = valid_state
)
#> # A tibble: 2 × 6
#>   stage           prop_in n_distinct prop_na n_out n_diff
#>   <chr>             <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 azl$state      0.000175         94  0.0321 68415     92
#> 2 azl$state_norm 1                57  0.0365     0      1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
norm_city <- azl %>% 
  distinct(city, state_norm, zip_norm) %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("AZ", "DC", "ARIZONA"),
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

#### Swap

We can further improve normalization by comparing our normalized value
against the *expected* value for that record’s state abbreviation and
ZIP code. If the normalized value is either an abbreviation for or very
similar to the expected value, we can confidently swap those two.

``` r
norm_city <- norm_city %>% 
  rename(city_raw = city) %>% 
  left_join(
    y = zipcodes,
    by = c(
      "state_norm" = "state",
      "zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(city_norm, city_match),
    match_dist = str_dist(city_norm, city_match),
    city_swap = if_else(
      condition = !is.na(match_dist) & (match_abb | match_dist == 1),
      true = city_match,
      false = city_norm
    )
  ) %>% 
  select(
    -city_match,
    -match_dist,
    -match_abb
  )
```

``` r
azl <- left_join(
  x = azl,
  y = norm_city,
  by = c(
    "city" = "city_raw", 
    "state_norm", 
    "zip_norm"
  )
)
```

#### Refine

The [OpenRefine](https://openrefine.org/) algorithms can be used to
group similar strings and replace the less common versions with their
most common counterpart. This can greatly reduce inconsistency, but with
low confidence; we will only keep any refined strings that have a valid
city/state/zip combination.

``` r
good_refine <- azl %>% 
  mutate(
    city_refine = city_swap %>% 
      key_collision_merge() %>% 
      n_gram_merge(numgram = 1)
  ) %>% 
  filter(city_refine != city_swap) %>% 
  inner_join(
    y = zipcodes,
    by = c(
      "city_refine" = "city",
      "state_norm" = "state",
      "zip_norm" = "zip"
    )
  )
```

    #> # A tibble: 23 × 5
    #>    state_norm zip_norm city_swap         city_refine          n
    #>    <chr>      <chr>    <chr>             <chr>            <int>
    #>  1 SC         29406    NORTH CHARLESTON  CHARLESTON           2
    #>  2 AZ         85138    MARICOPA #        MARICOPA             1
    #>  3 CA         90042    LOS ANGELSA       LOS ANGELES          1
    #>  4 CA         90045    LOS ANGELES #     LOS ANGELES          1
    #>  5 CA         90266    MAHANTTAN BEACH   MANHATTAN BEACH      1
    #>  6 CA         91730    RANCHO CUMCAMOUGA RANCHO CUCAMONGA     1
    #>  7 CA         91745    HACIENDA HGTHS    HACIENDA HEIGHTS     1
    #>  8 CA         92648    HUNGTINTON BEACH  HUNTINGTON BEACH     1
    #>  9 CA         92805    ANAHEMIN          ANAHEIM              1
    #> 10 CA         94577    SAN LEONARDO      SAN LEANDRO          1
    #> # … with 13 more rows

Then we can join the refined values back to the database.

``` r
azl <- azl %>% 
  left_join(good_refine, by = names(.)) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

Our goal for normalization was to increase the proportion of city values
known to be valid and reduce the total distinct values by correcting
misspellings.

| stage                                      | prop_in | n_distinct | prop_na | n_out | n_diff |
|:-------------------------------------------|--------:|-----------:|--------:|------:|-------:|
| `str_to_upper(str_remove(azl$city, ",$"))` |   0.957 |       5669 |   0.015 |  3022 |   1691 |
| `azl$city_norm`                            |   0.967 |       5317 |   0.016 |  2292 |   1296 |
| `azl$city_swap`                            |   0.986 |       4766 |   0.016 |   972 |    695 |
| `azl$city_refine`                          |   0.986 |       4744 |   0.016 |   951 |    674 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/bar-progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar-distinct-1.png)<!-- -->

Before exporting, we can remove the intermediary normalization columns
and rename all added variables with the `_clean` suffix.

``` r
azl <- azl %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  rename_all(~str_remove(., "_raw")) %>% 
  relocate(address_clean, city_clean, state_clean, .before = zip_clean)
```

## Conclude

``` r
glimpse(sample_n(azl, 1000))
#> Rows: 1,000
#> Columns: 20
#> $ license_number    <int> 57812, 30375, 23154, 44282, 39754, 17860, 29086, 61644, 12532, 13304, 4781, 74376, 50448, 61…
#> $ first_name        <chr> "David", "BRUCE", "EDMUND", "MARK", "JEFFREY", "MARY", "RICHARD", "Noah", "JAMES", "JOHN", "…
#> $ last_name         <chr> "Partida", "JUDD", "MAZUR", "LAVEER", "ERICSON", "PARKE", "HEDRICK", "Lewkowitz", "CORSARO",…
#> $ license_status    <chr> "Cancelled", "Cancelled", "Retired", "Inactive", "Cancelled", "Active", "Inactive", "Cancell…
#> $ discipline        <chr> "ALARM AGENT", "ARCHITECT", "ARCHITECT", "HOME INSPECTOR", "ARCHITECT", "ENGINEER/SANITARY",…
#> $ board_action_date <date> 2014-04-21, 1996-07-10, 1989-07-12, 2006-04-12, 2003-08-13, 1984-10-30, 1995-05-10, 2016-02…
#> $ expiration_date   <date> 2016-04-21, 2011-09-30, NA, NA, 2018-09-30, 2025-06-30, NA, 2019-03-31, 2017-06-30, NA, NA,…
#> $ address_line_1    <chr> "307 Butterfield Trail", "PIER 9 THE EMBARCADERO", "1529 QUEEN PALM DR", "INSPECT TECHNOLOGI…
#> $ address_line_2    <chr> NA, NA, NA, "5264 W BOBWHITE WAY", NA, NA, NA, NA, NA, NA, NA, "Suite 250", NA, NA, NA, "#50…
#> $ city              <chr> "Imperial,", "SAN FRANCISCO,", "EDGEWATER,", "TUCSON,", "Pittsburg,", "Scottsdale,", "LITTLE…
#> $ state             <chr> "California", "California", "Florida", "Arizona", "Pennsylvania", "Arizona", "Colorado", "Ar…
#> $ zip               <chr> "92251", "94111", "32132", "85742", "15206", "85254", "801201910", "85012", "85256", "85749"…
#> $ phone             <chr> "(760) 355-0420", "(415) 421-1680", "(904) 423-2362", "(520) 572-6346", "6022937414", "480-2…
#> $ na_flag           <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ dupe_flag         <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ year              <dbl> 2014, 1996, 1989, 2006, 2003, 1984, 1995, 2016, 1979, 1980, 1960, 2021, 2009, 2015, 2020, 20…
#> $ address_clean     <chr> "307 BUTTERFIELD TRL", "PIER 9 THE EMBARCADERO", "1529 QUEEN PALM DR", "INSPECT TECHNOLOGIES…
#> $ city_clean        <chr> "IMPERIAL", "SAN FRANCISCO", "EDGEWATER", "TUCSON", "PITTSBURGH", "SCOTTSDALE", "LITTLETON",…
#> $ state_clean       <chr> "CA", "CA", "FL", "AZ", "PA", "AZ", "CO", "AZ", "AZ", "AZ", "AZ", "AZ", "CA", "GA", "AZ", "C…
#> $ zip_clean         <chr> "92251", "94111", "32132", "85742", "15206", "85254", "80120", "85012", "85256", "85749", "8…
```

1.  There are 70,696 records in the database.
2.  There are 245 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 34 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server. We will name the object using a date range of the records
included.

``` r
min_dt <- str_remove_all(min(azl$board_action_date, na.rm = TRUE), "-")
max_dt <- str_remove_all(max(azl$board_action_date, na.rm = TRUE), "-")
csv_ts <- paste(min_dt, max_dt, sep = "-")
```

``` r
clean_dir <- dir_create(here("state", "az", "licenses", "data", "clean"))
clean_csv <- path(clean_dir, glue("az_licenses_{csv_ts}.csv"))
clean_rds <- path_ext_set(clean_csv, "rds")
basename(clean_csv)
#> [1] "az_licenses_19241010-20220613.csv"
```

``` r
write_csv(azl, clean_csv, na = "")
write_rds(azl, clean_rds, compress = "xz")
(clean_size <- file_size(clean_csv))
#> 12.2M
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
