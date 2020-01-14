Louisiana Lobbying Registration Data Diary
================
Yanqi Xu
2020-01-14 12:18:12

-   [Project](#project)
-   [Objectives](#objectives)
-   [Packages](#packages)
-   [Data sources](#data-sources)
-   [Reading](#reading)
    -   [Duplicates](#duplicates)
    -   [Missing](#missing)
    -   [Explore](#explore)
    -   [Wrangling](#wrangling)
    -   [Address](#address)
    -   [Export](#export)

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

Data sources
------------

Set the data directory first.

``` r
# create a directory for the raw data
reg_dir <- here("la", "lobbyists", "data", "raw", "reg")
dir_create(reg_dir)
```

The [Louisiana Board of Ethics](http://ethics.la.gov/LobbyistLists.aspx) makes available a listing of all current lobbyists (2019). For more detailed representation data, the Accountability Project obtained records of previous years through a public record request.

[La. Stat. Ann. § 24:53.](http://ethics.la.gov/Pub/Laws/Title24LegislativeLobbying.pdf) regulates lobbyists registration as such. &gt; Each lobbyist shall register with the board as soon as possible after employment as a lobbyist or after the first action requiring his registration as a lobbyist, whichever occurs first, and in any event not later than five days after employment as a lobbyist or not later than five days after the first action requiring his registration as a lobbyist, whichever occurs first.

The authorization data is obtained by IRW through an open record request to the Louisiana Ethics Administration Program. The data is as current as July 10, 2020.

Reading
=======

We will notice that some rows were delimited incorrectly, as a supposedly single rows is separated into two lines with the first row of the overflow line an invalid forward slash.

``` r
reg_dir <- dir_create(here("la", "lobbyists", "data", "raw", "reg"))

la_lines <- read_lines(glue("{reg_dir}/lobby_reg.csv"))
la_cols <- str_split(la_lines[1], ",", simplify = TRUE)
la_lines <- la_lines[-1]

sum(str_detect(la_lines, "^\\D"))
#> [1] 1092
#> 1092

for (i in rev(seq_along(la_lines))) {
  if (is.na(la_lines[i])) {
    next()
  }
  if (str_detect(la_lines[i], "^\\D")) {
    la_lines[i - 1] <- str_c(la_lines[i - 1], la_lines[i], collapse = ",")
    la_lines[i] <- NA_character_
  }
}

la_lines <- na.omit(la_lines)

la_reg <- read_csv(la_lines, col_names = la_cols) %>% clean_names() %>% 
  mutate_if(is.character, str_to_upper) %>% 
  mutate_if(is.character, na_if, "NULL")
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
#> # A tibble: 24 x 4
#>    col             class      n     p
#>    <chr>           <chr>  <int> <dbl>
#>  1 unique_id       <dbl>      0 0    
#>  2 first_name      <chr>      0 0    
#>  3 middle          <chr>  24235 0.280
#>  4 last_name       <chr>      0 0    
#>  5 m_street        <chr>      0 0    
#>  6 m_city          <chr>      0 0    
#>  7 m_state         <chr>      0 0    
#>  8 m_zip_string    <dbl>      0 0    
#>  9 year_registered <dbl>      0 0    
#> 10 branches        <chr>      0 0    
#> 11 id              <dbl>      0 0    
#> 12 rep_name        <chr>      0 0    
#> 13 rep_street      <chr>      0 0    
#> 14 rep_city        <chr>      0 0    
#> 15 rep_state       <chr>      0 0    
#> 16 rep_zip         <dbl>      0 0    
#> 17 branch          <chr>      0 0    
#> 18 rep_paid        <chr>      0 0    
#> 19 other_paid      <chr>  71069 0.821
#> 20 rep_cat_pay     <chr>      0 0    
#> 21 start_date      <dttm>     0 0    
#> 22 term_date       <chr>  27489 0.318
#> 23 status          <dbl>      0 0    
#> 24 dupe_flag       <lgl>      0 0
```

Explore
-------

### Year

We'll take a look at the range of start date and termination date here.So far, every column is read in as charcater, so we'll turn them into dates.

``` r
la_reg <- la_reg %>% 
  mutate(start_date = as_date(start_date),
         term_date_clean = term_date %>% na_if("NULL") %>% as_date())

summary(la_reg$start_date)
#>         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
#> "1974-01-01" "2009-05-26" "2012-04-26" "2013-01-11" "2016-02-01" "3017-05-08"
summary(la_reg$term_date)
#>    Length     Class      Mode 
#>     86576 character character
```

![](../plots/bar%20reg%20year-1.png)

Wrangling
---------

### ZIP

Running the following commands tells us the zipcode fields for lobbyists are mostly clean. The `rep_zip` fields need a bit of cleaning.

``` r
la_reg <- la_reg %>% rename(m_zip = m_zip_string)

prop_in(la_reg$m_zip, valid_zip, na.rm = TRUE) %>% percent()
#> [1] "100%"
prop_in(la_reg$rep_zip, valid_zip, na.rm = TRUE) %>% percent()
#> [1] "96%"
la_reg <- la_reg %>% 
  mutate(rep_zip_norm = normal_zip(zip = rep_zip, na_rep = TRUE))

progress_table(
               la_reg$rep_zip,
               la_reg$rep_zip_norm,
               compare = valid_zip)
#> # A tibble: 2 x 6
#>   stage        prop_in n_distinct  prop_na n_out n_diff
#>   <chr>          <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 rep_zip        0.961       1140 0         3350    117
#> 2 rep_zip_norm   0.995       1140 0.000277   418     32
```

### State

The state fields use the regular spelling of states, and we'll use `normal_state` to transform them into two-letter abbreviations.

``` r
la_reg <- la_reg %>% 
    mutate_at(
    .vars = vars(ends_with("state")),
    .fun = list(norm = normal_state),
    abbreviate = TRUE,
    na_rep = FALSE
  )

prop_in(la_reg$m_state_norm, valid_state, na.rm = TRUE) %>% percent()
#> [1] "100%"
prop_in(la_reg$rep_state_norm, valid_state, na.rm = TRUE) %>% percent()
#> [1] "100%"

progress_table(la_reg$m_state,
               la_reg$m_state_norm,
               la_reg$rep_state,
               la_reg$rep_state_norm,
               compare = valid_state)
#> # A tibble: 4 x 6
#>   stage          prop_in n_distinct prop_na n_out n_diff
#>   <chr>            <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 m_state          0             40       0 86576     40
#> 2 m_state_norm     1             40       0     0      0
#> 3 rep_state        0             52       0 86576     52
#> 4 rep_state_norm   0.998         52       0   131      4
```

### City

First, we can quickly see the percentage of cities in our valid\_city data frame.

``` r
prop_in(la_reg$m_city, valid_city, na.rm = TRUE) %>% percent()
#> [1] "99%"
prop_in(la_reg$rep_city, valid_city, na.rm = TRUE) %>% percent()
#> [1] "95%"
```

#### Prep

``` r
la_reg <- la_reg %>% mutate_at(
    .vars = vars(ends_with("city")),
    .fun = list(norm = normal_city),
    states = usps_state,
    abbs = usps_city,
    na = invalid_city,
    na_rep = TRUE
  )
prop_in(la_reg$m_city_norm, valid_city, na.rm = TRUE)
#> [1] 0.993139
prop_in(la_reg$rep_city_norm, valid_city, na.rm = TRUE) 
#> [1] 0.9670845
```

#### Swap

Then, we will compare these normalized `city_norm` values to the *expected* city value for that vendor's ZIP code. If the [levenshtein distance](https://en.wikipedia.org/wiki/Levenshtein_distance) is less than 3, we can confidently swap these two values.

``` r
la_reg <- la_reg %>% 
  left_join(
    y = zipcodes,
    by = c(
      "rep_state_norm" = "state",
      "rep_zip_norm" = "zip"
    )
  ) %>% 
  rename(rep_city_match = city) %>% 
  mutate(
  match_abb = is_abbrev(rep_city_norm, rep_city_match),
    match_dist = str_dist(rep_city_norm, rep_city_match),
    rep_city_swap = if_else(
      condition = match_abb | match_dist == 1,
      true = rep_city_match,
      false = rep_city_norm
    )
  ) %>% 
  select(
    -rep_city_match,
    -match_dist,
    -match_abb
  )

prop_in(la_reg$rep_city_swap, valid_city, na.rm = TRUE)
#> [1] 0.9804184
```

``` r
la_reg <- la_reg %>% 
  mutate(m_zip = as.character(m_zip)) %>% 
  left_join(
    y = zipcodes,
    by = c(
      "m_state_norm" = "state",
      "m_zip" = "zip"
    )
  ) %>% 
  rename(m_city_match = city) %>% 
  mutate(
  match_abb = is_abbrev(m_city_norm, m_city_match),
    match_dist = str_dist(m_city_norm, m_city_match),
    m_city_swap = if_else(
      condition = match_abb | match_dist == 1,
      true = m_city_match,
      false = m_city_norm
    )
  ) %>% 
  select(
    -m_city_match,
    -match_dist,
    -match_abb
  )
prop_in(la_reg$m_city_swap, valid_city, na.rm = TRUE)
#> [1] 0.9934153
```

This is a very fast way to increase the valid proportion of modified `m_city` to 99% and reduce the number of distinct *invalid* values from 26 to only 20

Besides the `valid_city` from the USPS dataframe, IRW has also collected valid localities based on our previous `check_city`

#### Check

We can use the `check_city` function to pull fuzzy matching results for the `rep_city_norm` from Geocoding API. We will find out that the

``` r
valid_place <-  c(valid_city, extra_city) %>% unique()
prop_in(la_reg$rep_city_swap, valid_place, na.rm = TRUE)
#> [1] 0.992632
```

We've now increased the percentage of clean city names in valid city names.

``` r
la_reg <- la_reg %>% 
  rename(
        m_city_clean      =  m_city_swap,
          rep_city_clean =  rep_city_swap
  )

prop_in(la_reg$m_city_clean, valid_place, na.rm = TRUE)
#> [1] 0.9949892
prop_in(la_reg$rep_city_clean, valid_place, na.rm = TRUE)
#> [1] 0.992632
```

Address
-------

``` r
la_reg <- la_reg %>% 
  mutate_at(
    .vars = vars(ends_with("street")),
    .fun = list(norm = normal_address),
    abbs = usps_street,
    na_rep = TRUE
  )
```

Export
------

``` r
clean_reg_dir <- here("la", "lobbyists", "data", "processed", "reg")
dir_create(clean_reg_dir)
la_reg %>% 
  select(-c(m_city_norm,
            rep_city_norm)) %>%
  write_csv(path = glue("{clean_reg_dir}/la_reg_clean.csv"),
            na = "")
```
