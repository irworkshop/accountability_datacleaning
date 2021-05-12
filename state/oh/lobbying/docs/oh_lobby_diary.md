Ohio Lobbyists
================
Kiernan Nicholls
2020-01-21 16:36:58

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
#> 3 Abrams    Mike       155 E.… <NA>           Colu… OH    43215   614-… Ohio Hospita…
#> 4 Abu-Absi  Laura      37 W. … <NA>           Colu… OH    43215   614-… Ohio Job and…
#> 5 Abu-Absi  Laura      37 W. … <NA>           Colu… OH    43215   614-… Ohio Job and…
#> 6 Acton     Amy        246 N … <NA>           Colu… OH    43215   614-… Department o…
#> # … with 1 more variable: employer_name_2 <chr>
tail(ohlr)
#> # A tibble: 6 x 10
#>   last_name first_name address address_line_2 city  state zipcode phone employer_name
#>   <chr>     <chr>      <chr>   <chr>          <chr> <chr> <chr>   <chr> <chr>        
#> 1 Zimmerman Robert A   200 Pu… <NA>           Clev… OH    44114   216-… Sisters of C…
#> 2 Zimpher   William    30 Eas… INTEROFFICE -… Colu… OH    43215   614-… Office of Bu…
#> 3 Zinn      Jennifer   390 Wo… <NA>           West… OH    43082   614-… OCSEA AFSCME…
#> 4 Zucal     Ethan      2045 M… <NA>           Colu… OH    43229   614-… Ohio Departm…
#> 5 Zwissler  Catherine… P.O. B… <NA>           Buck… OH    43008   614-… Specialty Co…
#> 6 Zwissler  Catherine… P.O. B… <NA>           Buck… OH    43008   614-… Specialty Co…
#> # … with 1 more variable: employer_name_2 <chr>
glimpse(sample_frac(ohlr))
#> Observations: 6,939
#> Variables: 10
#> $ last_name       <chr> "Davidson", "O'Donnell", "Tucker", "Fiore", "Brinkman", "O'Reilly", "Kov…
#> $ first_name      <chr> "Drew", "Terrence", "Mark D", "Anthonio C", "Kristen L", "Kelly C", "Rob…
#> $ address         <chr> "37 W. Broad Street, Suite 325", "150 E. Gay Street, Suite 2400", "41 So…
#> $ address_line_2  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ city            <chr> "Columbus", "Columbus", "Columbus", "Columbus", "Granville", "Columbus",…
#> $ state           <chr> "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", …
#> $ zipcode         <chr> "43215", "43215-4291", "43215-3506", "43215", "43023", "43215-3413", "43…
#> $ phone           <chr> "614-228-9800", "614-744-2583", "614-223-9300", "614-462-5428", "614-271…
#> $ employer_name   <chr> "CNA", "Compton Point, Inc.", "Ohio State Building & Construction Trades…
#> $ employer_name_2 <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
```

### Missing

There are no records missing important information.

``` r
glimpse_fun(ohlr, count_na)
#> # A tibble: 10 x 4
#>    col             type      n     p
#>    <chr>           <chr> <dbl> <dbl>
#>  1 last_name       <chr>     0 0    
#>  2 first_name      <chr>     0 0    
#>  3 address         <chr>     0 0    
#>  4 address_line_2  <chr>  6718 0.968
#>  5 city            <chr>     0 0    
#>  6 state           <chr>     0 0    
#>  7 zipcode         <chr>     0 0    
#>  8 phone           <chr>     0 0    
#>  9 employer_name   <chr>     0 0    
#> 10 employer_name_2 <chr>  6896 0.994
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
      abbs = usps_street,
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
#> # A tibble: 1,240 x 3
#>    address                      address_line_2             address_norm                            
#>    <chr>                        <chr>                      <chr>                                   
#>  1 600 Superior Avenue E., Ste… <NA>                       600 SUPERIOR AVE E STE 2100             
#>  2 213 W. Liberty St., Ste. 200 <NA>                       213 W LIBERTY ST STE 200                
#>  3 10 W Broad Street #1150      <NA>                       10 W BROAD ST 1150                      
#>  4 8591 Woodbury Rd             <NA>                       8591 WOODBURY RD                        
#>  5 545 East Town Street         <NA>                       545 E TOWN ST                           
#>  6 24000 Honda Parkway          <NA>                       24000 HONDA PKWY                        
#>  7 250 E. Broad St., #1400      INTEROFFICE - Public Defe… 250 E BROAD ST 1400 INTEROFFICE PUBLIC …
#>  8 37 W. Broad St., Ste. 325    <NA>                       37 W BROAD ST STE 325                   
#>  9 180 East Broad St. 12th Flo… INTEROFFICE - PUCO         180 E BROAD ST 12TH FL INTEROFFICE PUCO 
#> 10 36 East Seventh Street, Ste… <NA>                       36 E SEVENTH ST STE 1510                
#> # … with 1,230 more rows
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
#> 1 zipcode    0.882        360       0   816    103
#> 2 zip_norm   0.999        276       0     5      3
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
#> 1 state            1         25       0     0      0
#> 2 state_norm       1         25       0     0      0
```

### Citye

``` r
ohlr <- ohlr %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("OH", "DC", "OHIO"),
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
#>   stage     prop_in n_distinct prop_na n_out n_diff
#>   <chr>       <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 city_raw)   0.988        171 0          83     20
#> 2 city_norm   0.973        171 0         188     37
#> 3 city_swap   0.988        171 0.00101    80     18
```

``` r
ohlr %>% 
  filter(city_swap %out% valid_city) %>% 
  count(state_norm, city_swap, city_match, sort = TRUE)
#> # A tibble: 20 x 4
#>    state_norm city_swap        city_match        n
#>    <chr>      <chr>            <chr>         <int>
#>  1 OH         UPPER ARLINGTON  COLUMBUS         28
#>  2 OH         BEXLEY           COLUMBUS         14
#>  3 OH         GAHANNA          COLUMBUS         11
#>  4 OH         MORELAND HLS     CHAGRIN FALLS     9
#>  5 OH         FAIRLAWN         AKRON             4
#>  6 OH         <NA>             <NA>              4
#>  7 MA         <NA>             <NA>              2
#>  8 OH         BRK PARK         BROOKPARK         2
#>  9 OH         LAKELINE         EASTLAKE          2
#> 10 CA         <NA>             <NA>              1
#> 11 MA         BEVERLY FARMS    BEVERLY           1
#> 12 OH         COPLEY           AKRON             1
#> 13 OH         FAIRVIEW PARK    CLEVELAND         1
#> 14 OH         GRV CITY         COLUMBUS          1
#> 15 OH         LIBERTY TWP      HAMILTON          1
#> 16 OH         S EUCLID         CLEVELAND         1
#> 17 OH         UNIVERSITY HTS   CLEVELAND         1
#> 18 OH         WARRENSVILLE HTS CLEVELAND         1
#> 19 PA         MCMURRAY         CANONSBURG        1
#> 20 PA         WYOMISSING       READING           1
```

### Year

``` r
ohlr <- mutate(ohlr, year = year(today()))
```

## Conclude

1.  There are 6,939 records in the database.
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
proc_dir <- here("oh", "lobbying", "data", "processed")
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
    path = glue("{proc_dir}/oh_lobby_reg.csv"),
    na = ""
  )
```
