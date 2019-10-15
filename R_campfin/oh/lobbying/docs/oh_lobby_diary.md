Ohio Lobbyists
================
Kiernan Nicholls
2019-10-15 12:00:34

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
  httr, # query the web
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

Data is obtained from the [Ohio Legislative Inspector
General](http://www.jlec-olig.state.oh.us/) (OLIG) Joint Legislative
Ethics Committee (JLEC)

> JLEC provides access to the database of all currently registered
> legislative agents, executive agency and retirement system lobbyists,
> and their employers. If you want to search the database for a specific
> agent or employer, this can be done in the website’s Search For
> Lobbying Agents and Employers feature. Alternatively, a complete list
> of all currently registered Agents and a separate list of all
> Employers have been created and are updated daily. Please note, the
> lobbying lists include both private and public sector employees.

## Import

### GET

The file can be downloaded directly from the [OLIG-JLEC
website](https://www2.jlec-olig.state.oh.us/olac/Reports/AgentEmployerList.aspx)
using an `httr::GET()` request.

``` r
raw_dir <- here("oh", "lobbying", "data", "raw")
dir_create(raw_dir)
```

``` r
raw_url <- "https://www2.jlec-olig.state.oh.us/olac/Reports/agentList.aspx"
ohlr <- content(GET(raw_url)) %>% clean_names("snake")
```

## Explore

``` r
head(ohlr)
#> # A tibble: 6 x 10
#>   last_name first_name address address_line_2 city  state zipcode phone employer_name
#>   <chr>     <chr>      <chr>   <chr>          <chr> <chr> <chr>   <chr> <chr>        
#> 1 Abbott    Catharine  100 E.… INTEROFFICE -… Colu… OH    43215   614-… Ohio Casino …
#> 2 Abrams    Mike       155 E.… <NA>           Colu… OH    43215   614-… Ohio Hospita…
#> 3 Abu-Absi  Laura      37 W. … <NA>           Colu… OH    43215   614-… Ohio Job and…
#> 4 Acton     Amy        246 N … <NA>           Colu… OH    43215   614-… Department o…
#> 5 Acton     Dan        410 Co… <NA>           Hami… OH    45013   513-… Ohio Real Es…
#> 6 Acton     Dan        410 Co… <NA>           Hami… OH    45013   513-… Investment P…
#> # … with 1 more variable: employer_name_2 <chr>
tail(ohlr)
#> # A tibble: 6 x 10
#>   last_name first_name address address_line_2 city  state zipcode phone employer_name
#>   <chr>     <chr>      <chr>   <chr>          <chr> <chr> <chr>   <chr> <chr>        
#> 1 Zelman    Susan Tave 3168 B… <NA>           Colu… OH    43209   614 … Jason Learni…
#> 2 Zimmerman Robert A   200 Pu… <NA>           Clev… OH    44114   216-… Sisters of C…
#> 3 Zimmerman Robert A   200 Pu… <NA>           Clev… OH    44114   216-… NaphCare     
#> 4 Zimpher   William    30 Eas… INTEROFFICE -… Colu… OH    43215   614-… Office of Bu…
#> 5 Zinn      Jennifer   390 Wo… <NA>           West… OH    43082   614-… OCSEA AFSCME…
#> 6 Zwissler  Catherine… P.O. B… <NA>           Buck… OH    43008   614-… Specialty Co…
#> # … with 1 more variable: employer_name_2 <chr>
glimpse(sample_frac(ohlr))
#> Observations: 4,701
#> Variables: 10
#> $ last_name       <chr> "Siekman", "Lynaugh", "Jones", "Herf", "Sanders", "Gardner", "Weir", "Sh…
#> $ first_name      <chr> "Pamela", "Brandon", "Belinda M", "Lori A", "Joshua", "Randy", "Ian", "B…
#> $ address         <chr> "4597 Neiswander Square", "1299 Avondale Ave.", "37 West Broad Street, S…
#> $ address_line_2  <chr> NA, NA, NA, NA, NA, "INTEROFFICE - BOR", NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ city            <chr> "New Albany", "Columbus", "Columbus", "Columbus", "Columbus", "Columbus"…
#> $ state           <chr> "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", …
#> $ zipcode         <chr> "43054", "43212", "43215", "43215", "43215", "43215", "43220", "43123", …
#> $ phone           <chr> "614-738-5116", "614-946-7965", "614-224-3855", "614-462-2667", "614-621…
#> $ employer_name   <chr> "Community Bus Services, Inc", "Standard Wellness Company, LLC", "Columb…
#> $ employer_name_2 <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
```

### Missing

There are no records missing important information.

``` r
glimpse_fun(ohlr, count_na)
#> # A tibble: 10 x 4
#>    col             type      n     p
#>    <chr>           <chr> <dbl> <dbl>
#>  1 last_name       chr       0 0    
#>  2 first_name      chr       0 0    
#>  3 address         chr       0 0    
#>  4 address_line_2  chr    4486 0.954
#>  5 city            chr       0 0    
#>  6 state           chr       0 0    
#>  7 zipcode         chr       0 0    
#>  8 phone           chr       0 0    
#>  9 employer_name   chr       0 0    
#> 10 employer_name_2 chr    4669 0.993
```

``` r
ohlr <- flag_na(ohlr, last_name, employer_name, zipcode)
if (sum(ohlr$na_flag) == 0) {
  ohlr <- select(ohlr, -na_flag)
}
```

### Duplicates

``` r
ohlr <- flag_dupes(ohlr, everything())
if (sum(ohlr$dupe_flag) == 0) {
  ohlr <- select(ohlr, -dupe_flag)
}
```

## Wrangle

### Address

``` r
packageVersion("tidyr")
#> [1] '1.0.0'
ohlr <- ohlr %>% 
  # combine street addr
  unite(
    col = address_full,
    starts_with("address"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  # normalize combined addr
  mutate(
    address_norm = normal_address(
      address = address_full,
      add_abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-address_full)
```

``` r
ohlr %>% 
  select(starts_with("address")) %>% 
  distinct() %>% 
  sample_frac()
#> # A tibble: 1,275 x 3
#>    address                           address_line_2   address_norm                                 
#>    <chr>                             <chr>            <chr>                                        
#>  1 111 Liberty St., Suite 100        <NA>             111 LIBERTY STREET SUITE 100                 
#>  2 7777 Bainbridge Road              <NA>             7777 BAINBRIDGE ROAD                         
#>  3 41 South High Street, Suite 2240  <NA>             41 SOUTH HIGH STREET SUITE 2240              
#>  4 21 West Broad St., Ste. 800       <NA>             21 WEST BROAD STREET SUITE 800               
#>  5 400 East Campus View Boulevard (… INTEROFFICE - O… 400 EAST CAMPUS VIEW BOULEVARD 3AD INTEROFFI…
#>  6 2201 Townley Road                 <NA>             2201 TOWNLEY ROAD                            
#>  7 100 E. Broad St., 20th Floor      INTEROFFICE - C… 100 EAST BROAD STREET 20TH FLOOR INTEROFFICE…
#>  8 77 South High St., 2nd Flr.       <NA>             77 SOUTH HIGH STREET 2ND FLR                 
#>  9 801 Kingsmill Parkway             <NA>             801 KINGSMILL PARKWAY                        
#> 10 41 S. High St. #2245              <NA>             41 SOUTH HIGH STREET 2245                    
#> # … with 1,265 more rows
```

### ZIP

``` r
ohlr <- ohlr %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zipcode,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  ohlr$zipcode,
  ohlr$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 zipcode    0.884        376       0   546    110
#> 2 zip_norm   0.999        290       0     3      3
```

### State

``` r
ohlr <- ohlr %>% 
  mutate(
    state_norm = normal_state(
      state = state,
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = NULL
    )
  )
```

``` r
progress_table(
  ohlr$state,
  ohlr$state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage      prop_in n_distinct prop_na n_out n_diff
#>   <chr>        <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 state        0.999         28       0     6      2
#> 2 state_norm   1             26       0     0      0
```

### City

``` r
ohlr <- ohlr %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      geo_abbs = usps_city,
      st_abbs = c("OH", "DC", "OHIO"),
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

``` r
ohlr <- ohlr %>%
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
    match_dist = stringdist(city_norm, city_match),
    match_abb = is_abbrev(city_norm, city_match),
    city_swap = if_else(
      condition = match_abb | match_dist == 1,
      true = city_match,
      false = city_norm
    )
  )
```

``` r
progress_table(
  str_to_upper(ohlr$city_raw),
  ohlr$city_norm,
  ohlr$city_swap,
  compare = valid_city
)
#> # A tibble: 3 x 6
#>   stage     prop_in n_distinct  prop_na n_out n_diff
#>   <chr>       <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 city_raw)   0.988        182 0           56     22
#> 2 city_norm   0.989        182 0           54     20
#> 3 city_swap   0.989        180 0.000851    50     17
```

``` r
ohlr %>% 
  filter(city_swap %out% valid_city) %>% 
  count(state_norm, city_swap, city_match, sort = TRUE)
#> # A tibble: 19 x 4
#>    state_norm city_swap            city_match     n
#>    <chr>      <chr>                <chr>      <int>
#>  1 OH         UPPER ARLINGTON      COLUMBUS      16
#>  2 OH         BEXLEY               COLUMBUS       9
#>  3 OH         GAHANNA              COLUMBUS       8
#>  4 OH         FAIRLAWN             AKRON          3
#>  5 OH         LAKELINE             EASTLAKE       2
#>  6 OH         MARBLE CLIFF         COLUMBUS       2
#>  7 OH         <NA>                 <NA>           2
#>  8 CA         <NA>                 <NA>           1
#>  9 MA         BEVERLY FARMS        BEVERLY        1
#> 10 MA         <NA>                 <NA>           1
#> 11 OH         CINNCINATI           CINCINNATI     1
#> 12 OH         COPLEY               AKRON          1
#> 13 OH         FAIRVIEW PARK        CLEVELAND      1
#> 14 OH         LIBERTY TOWNSHIP     HAMILTON       1
#> 15 OH         SOUTH EUCLID         CLEVELAND      1
#> 16 OH         UNIVERSITY HEIGHTS   CLEVELAND      1
#> 17 OH         WARRENSVILLE HEIGHTS CLEVELAND      1
#> 18 PA         MCMURRAY             CANONSBURG     1
#> 19 PA         WYOMISSING           READING        1
```

### Year

``` r
ohlr <- mutate(ohlr, year = year(today()))
```

## Conclude

1.  There are 4,701 records in the database.
2.  There are no duplicate records in the database.
3.  There are no records missing any pertinent information.
4.  Consistency in goegraphic data has been improved with
    `campfin::normal_*()`.
5.  The 5-digit `zip_norm` variable has been created with
    `campfin::normal_zip()`.
6.  There is no date listed in the database. The current `year` was
    added.

## Export

``` r
proc_dir <- here("oh", "lobbying", "reg", "data", "processed")
dir_create(proc_dir)
```

``` r
ohlr %>% 
  select(
    -city_match,
    -match_abb,
    -match_dist
  ) %>% 
  write_csv(
    path = glue("{proc_dir}/oh_lobby_reg_clean.csv"),
    na = ""
  )
```
