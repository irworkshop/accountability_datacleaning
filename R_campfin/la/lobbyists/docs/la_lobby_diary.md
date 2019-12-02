Louisiana Lobbying
================
Yanqi Xu
2019-11-26 12:25:47

Project
-------

The Accountability Project is an effort to cut across data silos and give journalists, policy professionals, activists, and the public at large a simple way to search across huge volumes of public data about people and organizations.

Our goal is to standardizing public data on a few key fields by thinking of each dataset row as a transaction. For each transaction there should be (at least) 3 variables:

1.  All **parties** to a transaction
2.  The **date** of the transaction
3.  The **amount** of money involved

Objectives
----------

This document describes the process used to complete the following objectives:

1.  How many records are in the database?
2.  Check for duplicates
3.  Check ranges
4.  Is there anything blank or missing?
5.  Check for consistency issues
6.  Create a five-digit ZIP Code called `ZIP5`
7.  Create a `YEAR` field from the transaction date
8.  Make sure there is data on both parties to a transaction

Packages
--------

The following packages are needed to collect, manipulate, visualize, analyze, and communicate these results. The `pacman` package will facilitate their installation and attachment.

``` r
if (!require("pacman")) install.packages("pacman")
pacman::p_load_gh("irworkshop/campfin")
pacman::p_load(
  stringdist, # levenshtein value
  tidyverse, # data manipulation
  readxl, # import excel files
  lubridate, # datetime strings
  tidytext, # string analysis
  magrittr, # pipe opperators
  janitor, # dataframe clean
  refinr, # cluster and merge
  knitr, # knit documents
  glue, # combine strings
  scales, #format strings
  here, # relative storage
  fs, # search storage 
  vroom, #read deliminated files
  readxl #read excel files
)
```

This document should be run as part of the `R_campfin` project, which lives as a sub-directory of the more general, language-agnostic \[`irworkshop/accountability_datacleaning`\]\[01\] GitHub repository.

The `R_campfin` project uses the \[RStudio projects\]\[02\] feature and should be run as such. The project also uses the dynamic `here::here()` tool for file paths relative to *your* machine.

``` r
# where dfs this document knit?
here::here()
#> [1] "/Users/soc/accountability/accountability_datacleaning/R_campfin"
```

Download
--------

Set the data directory first.

``` r
# create a directory for the raw data
reg_dir <- here("la", "lobbyists", "data", "raw", "reg")
dir_create(reg_dir)
```

The [Louisiana Board of Ethics](http://ethics.la.gov/LobbyistLists.aspx) makes available a listing of all current lobbyists (2019). The Accountability Project obtained records of previous years through a public record request.

[La. Stat. Ann. § 24:53.](http://ethics.la.gov/Pub/Laws/Title24LegislativeLobbying.pdf) regulates lobbyists registration as such. &gt; Each lobbyist shall register with the board as soon as possible after employment as a lobbyist or after the first action requiring his registration as a lobbyist, whichever occurs first, and in any event not later than five days after employment as a lobbyist or not later than five days after the first action requiring his registration as a lobbyist, whichever occurs first.

Reading
=======

``` r
la_reg <- read_xlsx(dir_ls(reg_dir, glob = "*.xlsx"), col_types = "text") %>% 
  clean_names() 
la_reg <- la_reg %>% mutate_at(.vars = vars(ends_with("date")),
  .funs = ~ excel_numeric_to_date(as.numeric(.),date_system = "modern"))
la_reg <- la_reg %>% 
  rename_at(.vars = vars(starts_with("m_")), 
                               .funs = ~str_replace(.,"m_","mailing_")) %>% 
  rename_at(.vars = vars(starts_with("e_")), 
            .funs = ~str_replace(.,"e_","employer_")) %>% 
  rename_at(.vars = vars(starts_with("l_")), 
            .funs = ~str_replace(.,"l_","lobbyist_"))

la_reg <- la_reg %>% mutate_if(is.character, str_to_upper)
```

Duplicates
----------

We'll use the `flag_dupes()` function to see if there are records identical to one another and flag the duplicates. A new variable `dupe_flag` will be created.

``` r
la_reg <- flag_dupes(la_reg, dplyr::everything())
```

Missing
-------

``` r
col_stats(la_reg, count_na)
#> # A tibble: 21 x 4
#>    col                        class      n       p
#>    <chr>                      <chr>  <int>   <dbl>
#>  1 unique_id                  <chr>      0 0      
#>  2 first_name                 <chr>      0 0      
#>  3 middle                     <chr>   2383 0.316  
#>  4 last_name                  <chr>      0 0      
#>  5 mailing_street             <chr>      0 0      
#>  6 mailing_city               <chr>      0 0      
#>  7 mailing_state              <chr>      0 0      
#>  8 mailing_zip_string         <chr>      0 0      
#>  9 lobbyist_phone             <chr>     11 0.00146
#> 10 lobbyist_phone_ext         <chr>   7178 0.952  
#> 11 lobbyist_fax               <chr>   3450 0.458  
#> 12 employer_name              <chr>      0 0      
#> 13 employer_street            <chr>      0 0      
#> 14 employer_city              <chr>      0 0      
#> 15 employer_state             <chr>      0 0      
#> 16 employer_zip_string        <chr>      0 0      
#> 17 year_registered            <chr>      0 0      
#> 18 branches                   <chr>      0 0      
#> 19 earliest_registration_date <date>     0 0      
#> 20 latest_termination_date    <date>     0 0      
#> 21 dupe_flag                  <lgl>      0 0
```

Explore
-------

``` r
summary(la_reg$earliest_registration_date)
#>         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
#> "2009-01-01" "2011-01-01" "2014-01-01" "2013-12-18" "2017-01-01" "2019-11-14"
summary(la_reg$latest_termination_date)
#>         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
#> "2009-01-31" "2011-12-31" "2014-12-31" "2014-11-09" "2017-12-31" "2019-12-31"
```

### Year

![](../plots/bar%20reg%20year-1.png)

Wrangling
---------

### ZIP

Running the following commands tells us the zipcode fields are mostly clean.

``` r
prop_in(la_reg$mailing_zip_string , valid_zip, na.rm = TRUE) %>% percent()
#> [1] "98.4%"
prop_in(la_reg$employer_zip_string , valid_zip, na.rm = TRUE) %>% percent()
#> [1] "95.6%"
la_reg <- la_reg %>% 
  mutate_at(
    .vars = vars(contains("zip")),
    .fun = list(norm = normal_zip),
    na_rep = TRUE
  )

progress_table(la_reg$mailing_zip_string,
               la_reg$mailing_zip_string_norm,
               la_reg$employer_zip_string,
               la_reg$employer_zip_string_norm,
               compare = valid_zip)
#> # A tibble: 4 x 6
#>   stage                    prop_in n_distinct prop_na n_out n_diff
#>   <chr>                      <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 mailing_zip_string         0.984        522       0   118     22
#> 2 mailing_zip_string_norm    1            522       0     0      0
#> 3 employer_zip_string        0.956        409       0   331     41
#> 4 employer_zip_string_norm   0.999        409       0     7      4
```

### State

The state fields use the regular spelling of states, and we'll use `normal_state` to transform them into two-letter abbreviations.

``` r
la_reg <- la_reg %>% 
    mutate_at(
    .vars = vars(ends_with("state")),
    .fun = list(norm = normal_state),
    na_rep = TRUE
  )

progress_table(la_reg$mailing_state,
               la_reg$mailing_state_norm,
               la_reg$employer_state,
               la_reg$employer_state_norm,
               compare = valid_state)
#> # A tibble: 4 x 6
#>   stage               prop_in n_distinct prop_na n_out n_diff
#>   <chr>                 <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 mailing_state             0         40       0  7540     40
#> 2 mailing_state_norm        1         40       0     0      0
#> 3 employer_state            0         37       0  7540     37
#> 4 employer_state_norm       1         37       0     0      0
```

### City

#### Prep

``` r
la_reg <- la_reg %>% mutate_at(
    .vars = vars(ends_with("city")),
    .fun = list(norm = normal_city),
    st_abbs = usps_state,
    geo_abbs = usps_city,
    na = invalid_city,
    na_rep = TRUE
  )
```

#### Swap

Then, we will compare these normalized `city_norm` values to the *expected* city value for that vendor's ZIP code. If the [levenshtein distance](https://en.wikipedia.org/wiki/Levenshtein_distance) is less than 3, we can confidently swap these two values.

``` r
la_reg <- la_reg %>% 
  left_join(
    y = zipcodes,
    by = c(
      "employer_state_norm" = "state",
      "employer_zip_string_norm" = "zip"
    )
  ) %>% 
  rename(employer_city_match = city) %>% 
  mutate(
  match_abb = is_abbrev(employer_city_norm, employer_city_match),
    match_dist = str_dist(employer_city_norm, employer_city_match),
    employer_city_swap = if_else(
      condition = match_abb | match_dist == 1,
      true = employer_city_match,
      false = employer_city_norm
    )
  ) %>% 
  select(
    -employer_city_match,
    -match_dist,
    -match_abb
  )

prop_in(la_reg$employer_city_swap, valid_city, na.rm = TRUE)
#> [1] 0.9898815
```

``` r
la_reg <- la_reg %>% 
  left_join(
    y = zipcodes,
    by = c(
      "mailing_state_norm" = "state",
      "mailing_zip_string_norm" = "zip"
    )
  ) %>% 
  rename(mailing_city_match = city) %>% 
  mutate(
  match_abb = is_abbrev(mailing_city_norm, mailing_city_match),
    match_dist = str_dist(mailing_city_norm, mailing_city_match),
    mailing_city_swap = if_else(
      condition = match_abb | match_dist == 1,
      true = mailing_city_match,
      false = mailing_city_norm
    )
  ) %>% 
  select(
    -mailing_city_match,
    -match_dist,
    -match_abb
  )
prop_in(la_reg$mailing_city_swap, valid_city, na.rm = TRUE)
#> [1] 0.9868683
```

This is a very fast way to increase the valid proportion of modified `mailing_city` to 98.7% and reduce the number of distinct *invalid* values from 26 to only 20

#### Check

``` r
api_key <- Sys.getenv("GEOCODING_API")

valid_place <-  c(valid_city, extra_city) %>% unique()

la_mail_check <- la_reg %>% 
  filter(mailing_city_swap %out% valid_place) %>% 
  drop_na(mailing_city_swap, mailing_state_norm) %>% 
  count(mailing_city_swap, mailing_state_norm)

la_mail_check_result <- 
  pmap_dfr(.l = list(city = la_mail_check$mailing_city_swap, state = la_mail_check$mailing_state_norm), .f = check_city, key = api_key, guess = T)

la_mail_check <- la_mail_check %>% 
  left_join(la_mail_check_result %>% select(-original_zip), by = c("mailing_city_swap" = "original_city", "mailing_state_norm" = "original_state"))
```

``` r
la_emp_check <- la_reg %>% 
  filter(employer_city_swap %out% valid_place) %>% 
  drop_na(employer_city_swap, employer_state_norm) %>% 
  count(employer_city_swap, employer_state_norm)

la_emp_check_result <- 
  pmap_dfr(.l = list(city = la_emp_check$employer_city_swap, state = la_emp_check$employer_state_norm), .f = check_city, key = api_key, guess = T)

la_emp_check <- la_emp_check %>% 
  left_join(la_emp_check_result %>% select(-original_zip), by = c("employer_city_swap" = "original_city", "employer_state_norm" = "original_state"))
```

``` r
extra_city_gs <- gs_title("extra_city")

extra_city_gs <- extra_city_gs %>% 
  gs_add_row(ws = 1, input = la_mail_check %>% filter(check_city_flag) %>% select(mailing_city_swap)) %>% 
  gs_add_row(ws = 1, input = la_emp_check %>% filter(check_city_flag) %>% select(mailing_city_swap))
```

``` r
valid_place <-  c(valid_place,la_mail_check$mailing_city_swap[la_mail_check$check_city_flag]) %>% unique()

la_reg <- la_mail_check %>% select(mailing_city_swap, mailing_state_norm, guess_place) %>% 
  right_join(la_reg, by = c("mailing_city_swap","mailing_state_norm"))
  
la_reg <-  la_reg %>% mutate(mailing_city_clean = coalesce(guess_place, mailing_city_swap)) %>% select(-guess_place)
```

``` r
valid_place <-  c(valid_place,la_emp_check$employer_city_swap[la_emp_check$check_city_flag]) %>% unique()

la_reg <- la_emp_check %>% select(employer_city_swap, employer_state_norm, guess_place) %>% 
  right_join(la_reg, by = c("employer_city_swap","employer_state_norm"))
  
la_reg <-  la_reg %>% mutate(employer_city_clean = coalesce(guess_place, employer_city_swap)) %>% select(-guess_place)
```

We've now increased the percentage of clean city names in valid city names.

``` r
prop_in(la_reg$mailing_city_clean, valid_place, na.rm = TRUE)
#> [1] 1
prop_in(la_reg$employer_city_clean, valid_place, na.rm = TRUE)
#> [1] 0.9998669
```

Export
------

``` r
clean_reg_dir <- here("la", "lobbyists", "data", "processed", "reg")
dir_create(clean_reg_dir)
la_reg %>%
  select(-c(mailing_city_norm,
            employer_city_norm)) %>%
  write_csv(path = glue("{clean_reg_dir}/la_reg_clean.csv"),
            na = "")
```
