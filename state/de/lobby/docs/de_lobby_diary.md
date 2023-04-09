Deleware Lobbyist Registration
================
Kiernan Nicholls & Yanqi Xu
2023-03-26 21:48:15

- <a href="#project" id="toc-project">Project</a>
- <a href="#objectives" id="toc-objectives">Objectives</a>
- <a href="#packages" id="toc-packages">Packages</a>
- <a href="#data" id="toc-data">Data</a>
- <a href="#import" id="toc-import">Import</a>
- <a href="#explore" id="toc-explore">Explore</a>
- <a href="#wrangle" id="toc-wrangle">Wrangle</a>
- <a href="#conclude" id="toc-conclude">Conclude</a>
- <a href="#export" id="toc-export">Export</a>

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
#> [1] "/Users/yanqixu/code/accountability_datacleaning"
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

Since some end dates are marked “Indefinite” when a lobbyist is still
active, we transform the data to make the “indefinite” entries NAs
instead when we are reading this column in as date.

``` r
raw_url <- "https://pirs.delaware.gov/documents/EmployerAuthorizationCsv"
delr <- 
  GET(url = raw_url) %>%
  content(as = "raw") %>%
  read_csv(
    name_repair = make_clean_names,
    col_types = cols(
      .default = col_character(),
      lobbying_start_date = col_date_mdy(),
      lobbying_end_date = col_date_mdy()
    )
  )
```

Some of the variable names will be prepended with `lob_*` or truncated
for simplicity and clarity.

``` r
names(delr) <- str_replace(names(delr), "lobbyist_", "lob_") %>% 
  str_replace("employer_|empl_", "emp_") %>% 
  str_remove("lobbying_") %>% 
  str_remove("_code")
```

## Explore

We can `dplyr::glimpse()` to ensure our data was read and parsed
properly.

``` r
head(delr)
#> # A tibble: 6 × 14
#>   emp_name  emp_a…¹ emp_c…² emp_s…³ emp_zip lob_f…⁴ lob_l…⁵ lob_f…⁶ lob_a…⁷ lob_c…⁸ lob_s…⁹ lob_zip
#>   <chr>     <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>  
#> 1 20/20 GE… 9430 K… Rockvi… MD      20850   Robert  Garagi… Compas… 48 Mar… Annapo… MD      21401  
#> 2 20/20 GE… 9430 K… Rockvi… MD      20850   Lauren… Shull   Compas… 48 Mar… Annapo… MD      21401  
#> 3 302 STRA… 2325 F… Wilmin… DE      19808   Elizab… Lewis … 302 St… 55 Wes… New Ca… DE      19720  
#> 4 3M COMPA… 3M CEN… ST. PA… MN      55144   Patrick Allen   Allen … 4250 L… Wilmin… DE      19805  
#> 5 9-12 DEL… PO Box… Magnol… DE      19962   Ken     Currie  <NA>    132 Ri… Dagsbo… DE      19939  
#> 6 A. PHILI… 309 W.… Wilmin… DE      19802   Richard Korn    Frankl… PO Box… Hockes… DE      19707  
#> # … with 2 more variables: start_date <date>, end_date <date>, and abbreviated variable names
#> #   ¹​emp_address, ²​emp_city, ³​emp_state, ⁴​lob_first_name, ⁵​lob_last_name, ⁶​lob_firm_name,
#> #   ⁷​lob_address, ⁸​lob_city, ⁹​lob_state
tail(delr)
#> # A tibble: 6 × 14
#>   emp_name  emp_a…¹ emp_c…² emp_s…³ emp_zip lob_f…⁴ lob_l…⁵ lob_f…⁶ lob_a…⁷ lob_c…⁸ lob_s…⁹ lob_zip
#>   <chr>     <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>  
#> 1 XEROX BU… 1800 M… Washin… DC      20036   Kim     Willson Rugger… PO Box… Rehobo… DE      19971  
#> 2 YES YOU … 2504 C… Newark  DE      19711   Kate    Cowper… <NA>    1704 N… Wilmin… DE      19806  
#> 3 YMCA OF … 100 W … Wilmin… DE      19801   Nicole  Freedm… <NA>    500 De… Wilmin… DE      19801  
#> 4 YMCA OF … 100 W … Wilmin… DE      19801   Alice   Hoffman <NA>    500 De… Wilmin… DE      19801  
#> 5 YMCA OF … 100 W … Wilmin… DE      19801   Andrew  Wilson  <NA>    500 De… Wilmin… DE      19801  
#> 6 ZOCDOC    568 Br… New Yo… NY      10012   Patrick Allen   Allen … 4250 L… Wilmin… DE      19805  
#> # … with 2 more variables: start_date <date>, end_date <date>, and abbreviated variable names
#> #   ¹​emp_address, ²​emp_city, ³​emp_state, ⁴​lob_first_name, ⁵​lob_last_name, ⁶​lob_firm_name,
#> #   ⁷​lob_address, ⁸​lob_city, ⁹​lob_state
glimpse(sample_frac(delr))
#> Rows: 1,987
#> Columns: 14
#> $ emp_name       <chr> "DELAWARE STATE EDUCATION ASSN.", "UPMC FOR YOU INC.", "DELAWARE FOOD INDU…
#> $ emp_address    <chr> "136 E. Water Street", "600 Grant Street 55th Floor", "4 Cabot Place", "11…
#> $ emp_city       <chr> "Dover", "Pittsburgh", "Newark", "Washington", "New Castle", "Dover", "Den…
#> $ emp_state      <chr> "DE", "PA", "DE", "DC", "DE", "DE", "CO", "DE", "OH", "PA", "FL", "NY", "D…
#> $ emp_zip        <chr> "19901", "15219", "19711", "20036", "19720", "19901", "80209", "19701", "4…
#> $ lob_first_name <chr> "Taylor", "Tyler", "Julie", "David", "Rhett", "Mary", "Kim", "Darrell", "L…
#> $ lob_last_name  <chr> "Hawk", "Maron", "Wenger", "Swayze", "Ruggerio", "McLaughlin", "Willson", …
#> $ lob_firm_name  <chr> "Delaware State Education Association", "Morris James", NA, NA, "Ruggerio …
#> $ lob_address    <chr> "136 E. Water Street", "500 Delaware Avenue", "4 Cabot Place", "1105 North…
#> $ lob_city       <chr> "Dover", "Wilmington", "Newark", "Wilmington", "Rehoboth Beach", "Wilmingt…
#> $ lob_state      <chr> "DE", "DE", "DE", "DE", "DE", "DE", "DE", "DE", "OH", "DE", "MD", "DE", "M…
#> $ lob_zip        <chr> "19901", "19801", "19711", "19801", "19971", "19801", "19971", "19801", "4…
#> $ start_date     <date> 2023-01-30, 2022-01-01, 2006-03-01, 2000-01-19, 2020-01-01, 2020-09-30, 2…
#> $ end_date       <date> NA, NA, NA, 2021-10-22, NA, NA, 2020-04-01, NA, 2019-09-30, NA, 2020-09-3…
```

### Missing

There are no states missing key variables like `last_name` or
`start_date`.

``` r
col_stats(delr, count_na)
#> # A tibble: 14 × 4
#>    col            class      n        p
#>    <chr>          <chr>  <int>    <dbl>
#>  1 emp_name       <chr>      0 0       
#>  2 emp_address    <chr>      1 0.000503
#>  3 emp_city       <chr>      1 0.000503
#>  4 emp_state      <chr>      1 0.000503
#>  5 emp_zip        <chr>      5 0.00252 
#>  6 lob_first_name <chr>      0 0       
#>  7 lob_last_name  <chr>      0 0       
#>  8 lob_firm_name  <chr>   1073 0.540   
#>  9 lob_address    <chr>      2 0.00101 
#> 10 lob_city       <chr>      2 0.00101 
#> 11 lob_state      <chr>      2 0.00101 
#> 12 lob_zip        <chr>      2 0.00101 
#> 13 start_date     <date>     0 0       
#> 14 end_date       <date>  1127 0.567
```

### Duplicates

There are a small number of duplicate records, which can be flagged with
a new `dupe_flag` variable using the `campfin::dupe_flag()` function.

``` r
delr <- flag_dupes(delr, everything())
sum(delr$dupe_flag)
#> [1] 30
```

## Wrangle

To improve the searchability of the databse, we will normalize the
variables for both lobbyist and client.

### Address

For addressed, we will use `tidyr::unite()` to create a single variable,
then normalize that new variable with `campfin::normal_address()`.

``` r
packageVersion("tidyr")
#> [1] '1.3.0'
delr <- delr %>% 
  mutate(
    lob_address_norm = normal_address(
      address = lob_address,
      abbs = usps_street,
      na_rep = TRUE
    )
  )
```

The same process will be performed for `emp_address`.

``` r
delr <- delr %>% 
  mutate(
    emp_address_norm = normal_address(
      address = emp_address,
      abbs = usps_street,
      na_rep = TRUE
    )
  )
```

``` r
delr %>% 
  select(starts_with("lob_address")) %>% 
  distinct() %>% 
  sample_frac()
#> # A tibble: 574 × 2
#>    lob_address                          lob_address_norm                    
#>    <chr>                                <chr>                               
#>  1 1704 N. Park Drive 317               1704 N PARK DRIVE 317               
#>  2 1502 Delaware Avenue apartment 4     1502 DELAWARE AVENUE APARTMENT 4    
#>  3 1 North Trail                        1 NORTH TRL                         
#>  4 601 New Jersey Ave. Suite 850        601 NEW JERSEY AVE SUITE 850        
#>  5 901 N. Glebe Road #1000              901 N GLEBE ROAD #1000              
#>  6 601 New Jersey Avenue NW Suite 900   601 NEW JERSEY AVENUE NW SUITE 900  
#>  7 409 7th St NW Suite 350              409 7TH ST NW SUITE 350             
#>  8 100 West Commons Boulevard Suite 415 100 WEST COMMONS BOULEVARD SUITE 415
#>  9 One Main Street Unit 700             ONE MAIN STREET UNIT 700            
#> 10 c/o 2350 Kerner Blvd. Suite 250      C/O 2350 KERNER BLVD SUITE 250      
#> # … with 564 more rows
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
#> # A tibble: 4 × 6
#>   stage             prop_in n_distinct prop_na n_out n_diff
#>   <chr>               <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 delr$lob_zip        1            216 0.00101     0      1
#> 2 delr$lob_zip_norm   1            216 0.00101     0      1
#> 3 delr$emp_zip        0.997        357 0.00252     6      3
#> 4 delr$emp_zip_norm   0.997        357 0.00252     6      3
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
#> # A tibble: 4 × 6
#>   stage               prop_in n_distinct  prop_na n_out n_diff
#>   <chr>                 <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 delr$lob_state            1         27 0.00101      0      1
#> 2 delr$lob_state_norm       1         27 0.00101      0      1
#> 3 delr$emp_state            1         33 0.000503     0      1
#> 4 delr$emp_state_norm       1         33 0.000503     0      1
```

``` r
select(delr, contains("state")) %>% 
  distinct() %>% 
  sample_frac()
#> # A tibble: 134 × 4
#>    emp_state lob_state emp_state_norm lob_state_norm
#>    <chr>     <chr>     <chr>          <chr>         
#>  1 OR        NC        OR             NC            
#>  2 FL        FL        FL             FL            
#>  3 UT        DE        UT             DE            
#>  4 MA        FL        MA             FL            
#>  5 MD        MD        MD             MD            
#>  6 MO        DE        MO             DE            
#>  7 NV        DE        NV             DE            
#>  8 DC        VT        DC             VT            
#>  9 DC        GA        DC             GA            
#> 10 VA        MD        VA             MD            
#> # … with 124 more rows
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
#> # A tibble: 6 × 6
#>   stage                       prop_in n_distinct  prop_na n_out n_diff
#>   <chr>                         <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 str_to_upper(delr$lob_city)   0.993        156 0.00101     13     13
#> 2 delr$lob_city_norm            0.994        154 0.00151     11     11
#> 3 delr$lob_city_swap            0.995        154 0.00151     10     10
#> 4 str_to_upper(delr$emp_city)   0.975        247 0.000503    49     24
#> 5 delr$emp_city_norm            0.976        246 0.000503    48     23
#> 6 delr$emp_city_swap            0.983        243 0.00554     33     16
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
#> # A tibble: 11 × 5
#>    lob_state_norm lob_zip_norm lob_city             lob_city_norm            n
#>    <chr>          <chr>        <chr>                <chr>                <int>
#>  1 PA             19038        Erdenheim            ERDENHEIM                2
#>  2 <NA>           <NA>         <NA>                 <NA>                     2
#>  3 CA             94920        Tiburon              TIBURON                  1
#>  4 DC             20036        District of Columbia DISTRICT OF COLUMBIA     1
#>  5 DE             19701        Test                 <NA>                     1
#>  6 DE             19702        sdfds                SDFDS                    1
#>  7 DE             19702        wetwet               WETWET                   1
#>  8 GA             30097        Johns Creek          JOHNS CREEK              1
#>  9 NJ             07712        Tinton Falls         TINTON FALLS             1
#> 10 NJ             08807        West Caldwell        WEST CALDWELL            1
#> 11 OH             44143        Mayfield Village     MAYFIELD VILLAGE         1
```

### Year

``` r
min(delr$start_date)
#> [1] "1989-01-01"
max(delr$start_date)
#> [1] "2023-03-29"
min(delr$end_date, na.rm = TRUE)
#> [1] "2019-01-01"
max(delr$end_date, na.rm = TRUE)
#> [1] "2026-05-01"
```

``` r
delr <- mutate(
  .data = delr,
  start_year = year(start_date),
  end_year = year(end_date)
)
```

## Conclude

1.  There are 1987 records in the database.
2.  There are 30 duplicate records in the database.
3.  There are zero records missing key date.
4.  Consistency in goegraphic data has been improved with
    `campfin::normal_*()`.
5.  The 5-digit `zip_norm` variable has been created with
    `campfin::normal_zip()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
proc_dir <- dir_create(here("state","de", "lobby", "data", "processed"))
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
    path = glue("{proc_dir}/de_lobby_reg.csv"),
    na = ""
  )
```
