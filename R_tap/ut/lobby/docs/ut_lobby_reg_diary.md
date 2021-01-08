Utah Lobbying Registration Data Diary
================
Yanqi Xu
2020-01-14 17:22:58

-   [Project](#project)
-   [Objectives](#objectives)
-   [Packages](#packages)
-   [Download](#download)
-   [Reading](#reading)
-   [Explore](#explore)
-   [Wrangling](#wrangling)
-   [Join](#join)
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
pacman::p_load_current_gh("irworkshop/campfin")
pacman::p_load(
  rvest, # read html tables
  httr, # interact with http requests
  stringdist, # levenshtein value
  tidyverse, # data manipulation
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

This document should be run as part of the `R_campfin` project, which lives as a sub-directory of the more general, language-agnostic [`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning "TAP repo") GitHub repository.

The `R_campfin` project uses the [RStudio projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects "Rproj") feature and should be run as such. The project also uses the dynamic `here::here()` tool for file paths relative to *your* machine.

Download
--------

Set the download directory first.

``` r
# create a directory for the raw data
raw_dir <- here("ut", "lobby", "data", "raw","reg")
# create a docs directory for this diary
doc_dir <- here("ut", "lobby", "docs")
dir_create(c(raw_dir, doc_dir))
```

According to [Utah Code 36-11 & Utah Code 36-11a](https://elections.utah.gov/Media/Default/Lobbyist/2019%20Lobbyist/Lobbyist%20Frequently%20Asked%20Questions%202019%20(updated%20after%20session).pdf),

Definition of a lobbyist: &gt; Generally, you are a lobbyist if you get paid to communicate with a public official, local official, or education official for the purpose of influencing legislative, executive, local, or education action.

There are two types of lobbyists, a) state lobbyist b)local and education lobbyist. &gt; You are a state lobbyist if you lobby state legislators, elected state executive branch officials (such as the governor), and non-elected officials within the state executive or legislative branch with certain decisionmaking powers. &gt; You are a local and education lobbyist if you lobby:
 Elected members in local governments and non-elected officials within local governments that have certain decision-making powers.  Education officials, including elected members of the State Board of Education, State Charter School Board, local school boards, charter school governing boards, and non-elected officials within these organizations that have certain decision-making powers. If you lobby officials in both categories, register as a state lobbyist.

Reporting Requirements: &gt; A lobbyist is not required to file a quarterly financial report (Q1, Q2, Q3) if he or she has not made an expenditure during that reporting period. All lobbyists – state, local, and education – are still required to file the Quarter 4 (Year End) Report by January 10 of each year.

This Rmd file documents the wrangling process of UT registration data only, whereas the expenditure data is wrangled in a separate data diary.

IRW obtained a copy of lobbying registration data from Utah Lieutenant Governor's Office. The data is as current as Jan. 9 ,2020.

Reading
-------

We can read the xls file here.

``` r
ut_reg <- dir_ls(raw_dir, glob = "*.xlsx") %>% read_xlsx() %>% clean_names() %>% mutate_if(is.character, str_to_upper)
glimpse(ut_reg)
#> Observations: 5,609
#> Variables: 10
#> $ address_1                 <chr> "355 NORTH 300 WEST", "355 NORTH 300 WEST", "1050 17TH ST NW",…
#> $ address_2                 <chr> NA, NA, "STE 1150", "STE 1150", "SUITE 200", "SUITE 200", "800…
#> $ city                      <chr> "SALT LAKE CITY", "SALT LAKE CITY", "WASHINGTON", "WASHINGTON"…
#> $ date_organization_created <dttm> 2018-01-22 12:10:24, 2018-01-22 12:10:24, 2015-01-27 10:53:21…
#> $ date_organization_removed <dttm> NA, NA, 2017-01-30 16:54:35, 2017-01-30 16:54:35, 2014-07-09 …
#> $ organization_name         <chr> "RACIALLY JUST UTAH", "RACIALLY JUST UTAH", "R STREET INSTITUT…
#> $ organization_type         <chr> "PRINCIPAL", "BUSINESS", "PRINCIPAL", "BUSINESS", "PRINCIPAL",…
#> $ phone                     <chr> "(323) 788-4203", "(323) 788-4203", "(202) 525-5717", "(202) 5…
#> $ lobbyist_name             <chr> "ABARCA, KATHERINE", "ABARCA, KATHERINE", "ADAMS, IAN", "ADAMS…
#> $ zip                       <chr> "84103", "84103", "20036", "20036", "78746", "78746", "84111",…
```

### Columns

#### Year

Here we read everything as strings, and we will need to convert them back to numeric or datetime objects.

``` r
ut_reg <- ut_reg %>% mutate (year = year(date_organization_created))
```

#### Date

``` r
ut_reg <- ut_reg %>% mutate (date = as_date(date_organization_created))
```

#### Name

We'll separate first and last names from the name field.

``` r
ut_reg <- ut_reg %>% 
  mutate(first_name = str_match(lobbyist_name, ",\\s*(.[^,]+$)")[,2],
         last_name = str_remove(lobbyist_name, first_name) %>% str_remove(",") %>% str_trim())
```

Explore
-------

### Duplicates

We'll use the `flag_dupes()` function to see if there are records identical to one another and flag the duplicates. A new variable `dupe_flag` will be created.

``` r
ut_reg <- flag_dupes(ut_reg, dplyr::everything())
```

We can see that there's no duplicates in the data. \#\#\# Missing

``` r
ut_reg  %>% col_stats(count_na)
#> # A tibble: 15 x 4
#>    col                       class      n     p
#>    <chr>                     <chr>  <int> <dbl>
#>  1 address_1                 <chr>      0 0    
#>  2 address_2                 <chr>   3600 0.642
#>  3 city                      <chr>      0 0    
#>  4 date_organization_created <dttm>     0 0    
#>  5 date_organization_removed <dttm>  2781 0.496
#>  6 organization_name         <chr>      0 0    
#>  7 organization_type         <chr>      0 0    
#>  8 phone                     <chr>   2617 0.467
#>  9 lobbyist_name             <chr>      0 0    
#> 10 zip                       <chr>      0 0    
#> 11 year                      <dbl>      0 0    
#> 12 date                      <date>     0 0    
#> 13 first_name                <chr>      0 0    
#> 14 last_name                 <chr>      0 0    
#> 15 dupe_flag                 <lgl>      0 0
```

We'll flag entries where the `name`, `organization_name`, and `city` fields are missing.

``` r
ut_reg <- ut_reg %>% flag_na(lobbyist_name, organization_name, city)
```

``` r
ut_reg %>% 
  group_by(year) %>% 
  ggplot(aes(year)) +
  scale_x_continuous(breaks = 2012:2020) +
  geom_bar(fill = RColorBrewer::brewer.pal(3, "Dark2")[1]) +
  labs(
    title = "Utah Lobbyists Registration by Year",
    caption = "Source : Utah Lieutenant Governor's Office",
    x = "Year",
    y = "Count"
  )
```

![](../plots/unnamed-chunk-1-1.png)

Wrangling
---------

### Phone

``` r
ut_reg <- ut_reg %>% mutate(phone_norm = normal_phone(phone))
```

### Address

``` r
ut_reg <- ut_reg %>%
  unite(
  address_1,
  address_2,
  col = address_combined,
  sep = " ",
  remove = FALSE,
  na.rm = TRUE
  ) %>%
  mutate(address_clean = normal_address(
  address = address_combined,
  abbs = usps_city,
  na_rep = TRUE
  )) %>% 
  select(-address_combined)
```

### ZIP

We can use the `norm_zip` function to clean up the ZIP code fields.

``` r
prop_in(ut_reg$zip, valid_zip, na.rm = TRUE) %>% percent()
#> [1] "96%"

ut_reg <- ut_reg %>% 
  mutate(zip5 = normal_zip(zip, na_rep = TRUE))

prop_in(ut_reg$zip5, valid_zip, na.rm = TRUE) %>% percent()
#> [1] "99%"
```

### City

``` r
prop_in(ut_reg$city, valid_city, na.rm = TRUE) %>% percent()
#> [1] "91%"

ut_reg <- ut_reg %>% 
 mutate(city_norm = normal_city(city = city,
                                            abbs = usps_city,
                                            states = c(valid_state),
                                            na = invalid_city,
                                            na_rep = TRUE))
```

### State

We'll see that although information about cities and zips are present, the data file is missing a `state` column. We'll create a data column and determine the states based on `zip`.

``` r
ut_reg <- ut_reg %>% 
  left_join(zipcodes, by = c("zip5" = "zip")) %>% 
    rename(city_match = city.y,
         city = city.x)
prop_in(ut_reg$city_norm, valid_city, na.rm = TRUE)
#> [1] 0.9246698
```

#### Swap

Then, we will compare these normalized `city_norm` values to the *expected* city value for that vendor's ZIP code. If the [levenshtein distance](https://en.wikipedia.org/wiki/Levenshtein_distance) is less than 3, we can confidently swap these two values.

``` r
ut_reg <- ut_reg %>% 
  mutate(
    match_abb = is_abbrev(city_norm, city_match),
    match_dist = str_dist(city_norm, city_match),
    city_swap = if_else(
      condition = match_abb | match_dist == 1,
      true = city_match,
      false = city_norm
    )
  ) %>% 
  select(
    -city_match,
    -match_dist,
    -match_abb
  )

prop_in(ut_reg$city_swap, valid_city, na.rm = TRUE) %>% percent()
#> [1] "97%"
```

Besides the `valid_city` vector, there is another vector of `extra_city` that contains other locales. We'll incorporate that in our comparison.

    #> [1] "99%"

The `campfin` package uses the `check_city` function to check for misspelled cities by matching the returned results of the misspelled cities from the Google Maps Geocoding API. The function also pulls the clean city and place names in the `lobbyist_city_fetch` column for us to inspect and approve.

``` r
api_key <- Sys.getenv("GEOCODING_API")

ut_reg_out <- ut_reg %>% 
  filter(city_swap %out% valid_place) %>% 
  drop_na(city_swap,state) %>% 
  count(city_swap, state) 

ut_reg_out <- ut_reg_out %>% cbind(
  pmap_dfr(.l = list(ut_reg_out$city_swap, ut_reg_out$state), .f = check_city, key = api_key, guess = T))

ut_reg_out <- ut_reg_out %>%
  mutate(guess_place = str_replace(guess_place,"^WEST$", "SALT LAKE CITY"))
```

Then we'll join the results back to the original dataframe.

``` r
ut_reg_out <- ut_reg_out %>% mutate(city_fetch = coalesce(guess_city, guess_place))

ut_reg <- ut_reg_out %>% 
  filter(!check_city_flag) %>% 
  select(city_swap, state, city_fetch) %>% 
  right_join(ut_reg, by = c("city_swap","state")) 

ut_reg <- ut_reg %>% mutate(city_clean = coalesce(city_fetch, city_swap))
```

We can view the normalization progress here.

| stage       |   prop\_in|  n\_distinct|   prop\_na|  n\_out|  n\_diff|
|:------------|----------:|------------:|----------:|-------:|--------:|
| city        |  0.9299340|          432|  0.0000000|     393|       75|
| city\_norm  |  0.9439486|          419|  0.0012480|     314|       59|
| city\_swap  |  0.9856270|          388|  0.0076663|      80|       30|
| city\_clean |  0.9965864|          367|  0.0076663|      19|        6|

We can now get rid of the iterative columns generated while we were processing the data.

``` r
ut_reg <- ut_reg %>% 
  select(-c(city_norm,city_fetch,city_swap))
```

This is a very fast way to increase the valid proportion in the lobbyist data frame to 100% and reduce the number of distinct *invalid* values from 75 to only 6

Join
----

We'll see that the data frame includes both the business organizations that they work for (lobbying firms), and the clients they represent. Running the following commands tells us that the lobbyists' affiliationn is unique for each year. Thus we can separate registration to clients and organizations into two (BUSINESS and PRINCIPAL) and bind them back together.

``` r
freq_tb <- ut_reg %>% count(lobbyist_name,organization_type, year)
bus <- freq_tb %>% filter(organization_type == "BUSINESS") %>% arrange(desc(n))
prin <- freq_tb %>% filter(organization_type == "PRINCIPAL") %>% arrange(desc(n))
```

``` r
ut_business <- ut_reg %>% 
  filter(organization_type == "BUSINESS") %>% 
  rename(business = organization_name) %>% 
  select(-organization_type)

ut_prin <- ut_reg %>% 
  filter(organization_type == "PRINCIPAL") %>% 
  rename(principal = organization_name) %>% 
  select(-organization_type)
# names(ut_business) %>% setdiff(names(ut_prin))just captures what's inside business but not in prin, and we only need to eliminate this column when we apply left_join to ut_prin.  
ut_bind <- ut_prin %>% 
  left_join(ut_business, by = names(ut_business) %>% setdiff(names(ut_business) %>% setdiff(names(ut_prin))))

sample_frac(ut_bind)
#> # A tibble: 4,467 x 21
#>    state address_1 address_2 city  date_organization_… date_organization_… principal phone
#>    <chr> <chr>     <chr>     <chr> <dttm>              <dttm>              <chr>     <chr>
#>  1 NY    433 PUGS… <NA>      AMEN… 2014-03-03 11:14:39 2014-03-24 09:59:32 NATIONAL… <NA> 
#>  2 PA    1 DISCOV… <NA>      SWIF… 2012-12-18 09:32:37 2014-01-03 14:43:58 SANOFI P… (570…
#>  3 CA    4100 MAC… SUITE 200 NEWP… 2015-12-17 11:45:49 2018-02-25 14:45:12 OUTLETS … (949…
#>  4 OR    528 COTT… SUITE 1-B SALEM 2014-12-30 16:01:06 NA                  KOCH COM… <NA> 
#>  5 UT    824 S 40… A105      SALT… 2017-10-23 16:56:47 2019-11-21 15:18:31 UTAH CHA… (801…
#>  6 UT    230 SOUT… <NA>      SALT… 2017-01-24 08:33:16 2018-11-01 13:27:09 INSURE-R… <NA> 
#>  7 UT    3600 CON… <NA>      WVC   2013-12-23 09:45:56 NA                  WEST VAL… <NA> 
#>  8 TN    6100 TOW… <NA>      NASH… 2019-02-28 20:33:55 NA                  ACADIA    <NA> 
#>  9 UT    323 S 60… <NA>      SALT… 2014-08-01 02:04:21 2017-01-08 21:29:21 IDEAL FO… (801…
#> 10 UT    9602 S. … <NA>      SANDY 2013-11-04 12:07:57 NA                  UTAH CAB… <NA> 
#> # … with 4,457 more rows, and 13 more variables: lobbyist_name <chr>, zip <chr>, year <dbl>,
#> #   date <date>, first_name <chr>, last_name <chr>, dupe_flag <lgl>, na_flag <lgl>,
#> #   phone_norm <chr>, address_clean <chr>, zip5 <chr>, city_clean <chr>, business <chr>
```

Export
------

``` r
clean_dir <- here("ut", "lobby", "data", "processed","reg")
dir_create(clean_dir)
ut_bind %>% 
  mutate_if(is.character, str_to_upper) %>% 
  write_csv(
    path = glue("{clean_dir}/ut_lobby_reg.csv"),
    na = ""
  )
```
