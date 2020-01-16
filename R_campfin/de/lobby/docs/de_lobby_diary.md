Deleware Lobbyist Registration
================
Kiernan Nicholls
2020-01-16 14:30:27

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
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
  stringdist, # levenshtein value
  RSelenium, # remote browser
  tidyverse, # data manipulation
  lubridate, # datetime strings
  magrittr, # pipe opperators
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  glue, # combine strings
  here, # relative storage
  httr, # http request
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

Data is obtained from the [Deleware Public Integrity
Commission](https://depic.delaware.gov/) (PIC).

> Registration and authorization laws for those lobbying the General
> Assembly or State agencies, whether paid or not. Quarterly expense
> reports required for direct expenditures on General Assembly members
> or agency employees or officials. Lobbying activity reports with the
> Bill Number of legislation and number or title of administrative
> action must be filed within 5 business days of Lobbying. PIC submits
> weekly reports on that lobbying activity to the General Assembly while
> in session.

## Import

From the PIC search page, we have the option to download the complete
list of registered lobbyists.

> Enter the name of registered Delaware lobbyist to find employer/client
> list, lobbying expenses, and address. Click magnifying glass to
> search.  
> [Download complete
> list](https://egov.delaware.gov/Lobs/Explore/DownloadReport?reportCode=LOB)

We can use `httr::GET()` to submit an HTTP request for the file. Then,
the response content of that request can be parsed as a CSV using
`httr:content()` and `readr::read_csv()`.

``` r
raw_url <- "https://egov.delaware.gov/Lobs/Explore/DownloadReport?reportCode=LOB"
delr <- 
  GET(url = raw_url) %>%
  content(as = "raw") %>%
  read_csv(
    col_types = cols(
      .default = col_character(),
      StartDate = col_date_usa(),
      EndDate = col_date_usa()
    )
  ) %>% 
  clean_names(case = "snake")
```

Some of the variable names will be prepended with `lob_*` or truncated
for simplicity and clarity.

``` r
names(delr)[c(1:8, 13)] <- c(
  "lob_first", 
  "lob_last", 
  "lob_address1", 
  "lob_address2", 
  "lob_city", 
  "lob_state", 
  "lob_zip",
  "emp_name",
  "emp_zip"
)
names(delr) <- str_replace(names(delr), "employer_", "emp_")
```

## Explore

We can `dplyr::glimpse()` to ensure our data was read and parsed
properly.

``` r
head(delr)
#> # A tibble: 6 x 15
#>   lob_first lob_last lob_address1 lob_address2 lob_city lob_state lob_zip emp_name emp_address1
#>   <chr>     <chr>    <chr>        <chr>        <chr>    <chr>     <chr>   <chr>    <chr>       
#> 1 Jennifer  Allen    1675 South … <NA>         Dover    Delaware  19901   FIRST S… 1675 South …
#> 2 Patrick   Allen    Allen Strat… 4250 Lancas… Wilming… Delaware  19805   DELAWAR… P.O. Box 758
#> 3 Patrick   Allen    Allen Strat… 4250 Lancas… Wilming… Delaware  19805   Altria … 6601 West B…
#> 4 Patrick   Allen    Allen Strat… 4250 Lancas… Wilming… Delaware  19805   Delawar… P.O. Box 195
#> 5 Patrick   Allen    Allen Strat… 4250 Lancas… Wilming… Delaware  19805   Dish Ne… 1110 Vermon…
#> 6 Patrick   Allen    Allen Strat… 4250 Lancas… Wilming… Delaware  19805   FIG LLC… 1345 Avenue…
#> # … with 6 more variables: emp_address2 <chr>, emp_city <chr>, emp_state <chr>, emp_zip <chr>,
#> #   start_date <date>, end_date <date>
tail(delr)
#> # A tibble: 6 x 15
#>   lob_first lob_last lob_address1 lob_address2 lob_city lob_state lob_zip emp_name emp_address1
#>   <chr>     <chr>    <chr>        <chr>        <chr>    <chr>     <chr>   <chr>    <chr>       
#> 1 Tarik     Zerrad   109 E Divis… <NA>         Dover    Delaware  19901   FMC Cor… 2929 Walnut…
#> 2 Tarik     Zerrad   109 E Divis… <NA>         Dover    Delaware  19901   Orsted   100 Oliver …
#> 3 Tarik     Zerrad   109 E Divis… <NA>         Dover    Delaware  19901   TPE Dev… 747 South C…
#> 4 Tarik     Zerrad   109 E Divis… <NA>         Dover    Delaware  19901   Delawar… 109 E Divis…
#> 5 Tarik     Zerrad   109 E Divis… <NA>         Dover    Delaware  19901   Associa… 601 New Jer…
#> 6 Tarik     Zerrad   109 E Divis… <NA>         Dover    Delaware  19901   delawar… P.O. Box 80…
#> # … with 6 more variables: emp_address2 <chr>, emp_city <chr>, emp_state <chr>, emp_zip <chr>,
#> #   start_date <date>, end_date <date>
glimpse(sample_frac(delr))
#> Observations: 1,384
#> Variables: 15
#> $ lob_first    <chr> "Christopher V.", "Rhett", "Kim", "Kimberly B.", "Rebecca", "Rhett", "Brian…
#> $ lob_last     <chr> "DiPietro", "Ruggerio", "Willson", "Gomes", "Byrd", "Ruggerio", "McGlinchey…
#> $ lob_address1 <chr> "4411 Sedgwick Road", "Ruggerio Willson & Associates LLC", "Ruggerio Willso…
#> $ lob_address2 <chr> NA, "P.O. Box 481", "PO Box 481", "2 Penns Way Suite 305", "2 Penns Way Sui…
#> $ lob_city     <chr> "Baltimore", "Lewes", "Lewes", "New Castle", "New Castle", "Lewes", "Wilmin…
#> $ lob_state    <chr> "Maryland", "Delaware", "Delaware", "Delaware", "Delaware", "Delaware", "De…
#> $ lob_zip      <chr> "21210", "19958", "19958", "19720", "19720", "19958", "19803", "19801", "19…
#> $ emp_name     <chr> "DELAWARE ASSOCIATION OF NURSE ANESTHETIST", "Town of Henlopen Acres", "Del…
#> $ emp_address1 <chr> "122 Farm Meadows Lane", "104 Tidewaters", "100  West 10th Street", "500 De…
#> $ emp_address2 <chr> NA, NA, "Suite 403", NA, NA, "Suite 325 - North Building", NA, NA, NA, "Sui…
#> $ emp_city     <chr> "Hockessin", "Henlopen Acres", "Wilmington", "Wilmington", "Washington", "W…
#> $ emp_state    <chr> "Delaware", "Delaware", "Delaware", "Delaware", "District of Columbia", "Di…
#> $ emp_zip      <chr> "19707", "19971", "19801", "19801", "20001", "20004", "77002", "19081", "19…
#> $ start_date   <date> 2002-05-01, 2013-05-29, 2012-05-24, 2013-01-01, 2019-07-09, 2015-12-14, 20…
#> $ end_date     <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, 2018-12-31, NA, NA…
```

### Missing

There are no states missing key variables like `last_name` or
`start_date`.

``` r
col_stats(delr, count_na)
#> # A tibble: 15 x 4
#>    col          class      n        p
#>    <chr>        <chr>  <int>    <dbl>
#>  1 lob_first    <chr>      0 0       
#>  2 lob_last     <chr>      0 0       
#>  3 lob_address1 <chr>      0 0       
#>  4 lob_address2 <chr>    509 0.368   
#>  5 lob_city     <chr>      0 0       
#>  6 lob_state    <chr>      1 0.000723
#>  7 lob_zip      <chr>      0 0       
#>  8 emp_name     <chr>      0 0       
#>  9 emp_address1 <chr>      0 0       
#> 10 emp_address2 <chr>    921 0.665   
#> 11 emp_city     <chr>      0 0       
#> 12 emp_state    <chr>      1 0.000723
#> 13 emp_zip      <chr>      0 0       
#> 14 start_date   <date>     0 0       
#> 15 end_date     <date>  1289 0.931
```

### Duplicates

There are a small number of duplicate records, which can be flagged with
a new `dupe_flag` variable using the `campfin::dupe_flag()` function.

``` r
delr <- flag_dupes(delr, everything())
sum(delr$dupe_flag)
#> [1] 7
```

## Wrangle

To improve the searchability of the databse, we will normalize the
variables for both lobbyist and client.

### Address

For addressed, we will use `tidyr::unite()` to create a single variable,
then normalize that new variable with `campfin::normal_address()`.

``` r
packageVersion("tidyr")
#> [1] '1.0.0'
delr <- delr %>% 
  # combine street addr
  unite(
    starts_with("lob_address"),
    col = lob_adress_full,
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  # normalize combined addr
  mutate(
    lob_address_norm = normal_address(
      address = lob_adress_full,
      abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-lob_adress_full)
```

The same process will be performed for `emp_address`.

``` r
delr <- delr %>% 
  unite(
    col = emp_adress_full,
    emp_address1, emp_address2,
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    emp_address_norm = normal_address(
      address = emp_adress_full,
      abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-emp_adress_full)
```

``` r
delr %>% 
  select(starts_with("lob_address")) %>% 
  distinct() %>% 
  sample_frac()
#> # A tibble: 322 x 3
#>    lob_address1                      lob_address2    lob_address_norm                             
#>    <chr>                             <chr>           <chr>                                        
#>  1 385 Blair Shore Road              <NA>            385 BLAIR SHORE ROAD                         
#>  2 136 East Water Street             <NA>            136 EAST WATER STREET                        
#>  3 1255 23rd Street NW               Suite 450       1255 23RD STREET NORTHWEST SUITE 450         
#>  4 Hamilton Goodman Partners LLC     2325 Fells Lane HAMILTON GOODMAN PARTNERS LLC 2325 FELLS LANE
#>  5 1501 N. Walnut Street Ste. 100    <NA>            1501 NORTH WALNUT STREET SUITE 100           
#>  6 2704 Landon Drive                 Chalfonte       2704 LANDON DRIVE CHALFONTE                  
#>  7 4405 Kennett Pike                 <NA>            4405 KENNETT PIKE                            
#>  8 240 N. James Street               Suite B1B       240 NORTH JAMES STREET SUITE B1B             
#>  9 Ruggerio Willson & Associates LLC PO Box 481      RUGGERIO WILLSON ASSOCIATES LLC PO BOX 481   
#> 10 1280 S Governors Ave              <NA>            1280 SOUTH GOVERNORS AVENUE                  
#> # … with 312 more rows
```

### ZIP

``` r
delr <- mutate_at(
  .tbl = delr,
  .vars = vars(ends_with("_zip")),
  .funs = list(norm = normal_zip),
  na_rep = TRUE
)
```

``` r
progress_table(
  delr$lob_zip,
  delr$lob_zip_norm,
  delr$emp_zip,
  delr$emp_zip_norm,
  compare = valid_zip
)
#> # A tibble: 4 x 6
#>   stage        prop_in n_distinct  prop_na n_out n_diff
#>   <chr>          <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 lob_zip        0.983        131 0           23     10
#> 2 lob_zip_norm   1            123 0            0      0
#> 3 emp_zip        0.973        312 0           38     21
#> 4 emp_zip_norm   0.998        297 0.000723     3      2
```

### State

``` r
delr <- mutate_at(
  .tbl = delr,
  .vars = vars(ends_with("_state")),
  .funs = list(norm = normal_state),
  na_rep = TRUE,
  valid = valid_state
)
```

``` r
progress_table(
  delr$lob_state,
  delr$lob_state_norm,
  delr$emp_state,
  delr$emp_state_norm,
  compare = valid_state
)
#> # A tibble: 4 x 6
#>   stage          prop_in n_distinct  prop_na n_out n_diff
#>   <chr>            <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 lob_state            0         22 0.000723  1383     22
#> 2 lob_state_norm       1         22 0.000723     0      1
#> 3 emp_state            0         33 0.000723  1383     33
#> 4 emp_state_norm       1         33 0.000723     0      1
```

``` r
select(delr, contains("state")) %>% 
  distinct() %>% 
  sample_frac()
#> # A tibble: 93 x 4
#>    lob_state            emp_state      lob_state_norm emp_state_norm
#>    <chr>                <chr>          <chr>          <chr>         
#>  1 Connecticut          Minnesota      CT             MN            
#>  2 District of Columbia North Carolina DC             NC            
#>  3 Florida              North Carolina FL             NC            
#>  4 <NA>                 California     <NA>           CA            
#>  5 Delaware             Colorado       DE             CO            
#>  6 Maryland             California     MD             CA            
#>  7 Delaware             Washington     DE             WA            
#>  8 Maryland             New York       MD             NY            
#>  9 Arkansas             Arkansas       AR             AR            
#> 10 Indiana              Indiana        IN             IN            
#> # … with 83 more rows
```

### City

``` r
delr <- mutate_at(
  .tbl = delr,
  .vars = vars(ends_with("_city")),
  .funs = list(norm = normal_city),
  abbs = usps_city,
  states = c("DE", "DC", "DELEWARE"),
  na = invalid_city,
  na_rep = TRUE
)
```

``` r
delr <- delr %>% 
  left_join(
    y = select(zipcodes, -state),
    by = c(
      "lob_zip_norm" = "zip"
    )
  ) %>% 
  rename(lob_city_match = city) %>% 
  mutate(
    lob_match_abb = is_abbrev(lob_city_norm, lob_city_match),
    lob_match_dist = stringdist(lob_city_norm, lob_city_match),
    lob_city_swap = if_else(
      condition = lob_match_abb | lob_match_dist == 1,
      true = lob_city_match,
      false = lob_city_norm
    )
  ) %>% 
  select(
    -lob_city_match,
    -lob_match_abb,
    -lob_match_dist
  )
```

``` r
delr <- delr %>% 
  left_join(
    y = select(zipcodes, -state),
    by = c(
      "emp_zip_norm" = "zip"
    )
  ) %>% 
  rename(emp_city_match = city) %>% 
  mutate(
    emp_match_abb = is_abbrev(emp_city_norm, emp_city_match),
    emp_match_dist = stringdist(emp_city_norm, emp_city_match),
    emp_city_swap = if_else(
      condition = emp_match_abb | emp_match_dist == 1,
      true = emp_city_match,
      false = emp_city_norm
    )
  ) %>% 
  select(
    -emp_city_match,
    -emp_match_abb,
    -emp_match_dist
  )
```

``` r
progress_table(
  str_to_upper(delr$lob_city),
  delr$lob_city_norm,
  delr$lob_city_swap,
  str_to_upper(delr$emp_city),
  delr$emp_city_norm,
  delr$emp_city_swap,
  compare = valid_city
)
#> # A tibble: 6 x 6
#>   stage         prop_in n_distinct prop_na n_out n_diff
#>   <chr>           <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 lob_city)       0.997         87 0           4      3
#> 2 lob_city_norm   0.997         87 0           4      3
#> 3 lob_city_swap   0.997         87 0           4      3
#> 4 emp_city)       0.970        212 0          41     23
#> 5 emp_city_norm   0.978        211 0          30     20
#> 6 emp_city_swap   0.987        205 0.00289    18     14
```

``` r
delr %>% 
  filter(lob_city_swap %out% valid_city) %>% 
  count(
    lob_state_norm, 
    lob_zip_norm, 
    lob_city, 
    lob_city_norm,
    sort = TRUE
  )
#> # A tibble: 3 x 5
#>   lob_state_norm lob_zip_norm lob_city      lob_city_norm     n
#>   <chr>          <chr>        <chr>         <chr>         <int>
#> 1 NJ             08807        West Caldwell WEST CALDWELL     2
#> 2 NJ             07981        P.O. Box 915  P O BOX           1
#> 3 PA             19038        Erdenheim     ERDENHEIM         1
```

### Year

``` r
min(delr$start_date)
#> [1] "1989-01-01"
max(delr$start_date)
#> [1] "2020-01-15"
min(delr$end_date, na.rm = TRUE)
#> [1] "2012-12-31"
max(delr$end_date, na.rm = TRUE)
#> [1] "2023-09-01"
```

``` r
delr <- mutate(
  .data = delr,
  start_year = year(start_date),
  end_year = year(end_date)
)
```

## Conclude

1.  There are 1384 records in the database.
2.  There are 7 duplicate records in the database.
3.  There are zero records missing key date.
4.  Consistency in goegraphic data has been improved with
    `campfin::normal_*()`.
5.  The 5-digit `zip_norm` variable has been created with
    `campfin::normal_zip()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
proc_dir <- dir_create(here("de", "lobby", "data", "processed"))
```

``` r
delr %>% 
  select(
    -lob_city_norm,
    -emp_city_norm,
  ) %>% 
  rename(
    lob_city_norm = lob_city_swap,
    emp_city_norm = emp_city_swap
  ) %>% 
  write_csv(
    path = glue("{proc_dir}/de_lobbyists.csv"),
    na = ""
  )
```
