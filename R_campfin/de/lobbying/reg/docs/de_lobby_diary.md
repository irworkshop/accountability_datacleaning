Deleware Lobbyist Registration
================
Kiernan Nicholls
2019-10-15 15:42:41

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

Some of the variable names will be prepended with `lobby_*` or truncated
for simplicity and clarity.

``` r
names(delr)[c(1:8, 13)] <- c(
  "lobby_first", 
  "lobby_last", 
  "lobby_address1", 
  "lobby_address2", 
  "lobby_city", 
  "lobby_state", 
  "lobby_zip",
  "employer_name",
  "employer_zip"
)
```

## Explore

We can `dplyr::glimpse()` to ensure our data was read and parsed
properly.

``` r
head(delr)
#> # A tibble: 6 x 15
#>   lobby_first lobby_last lobby_address1 lobby_address2 lobby_city lobby_state lobby_zip
#>   <chr>       <chr>      <chr>          <chr>          <chr>      <chr>       <chr>    
#> 1 Jennifer    Allen      1675 South St… <NA>           Dover      Delaware    19901    
#> 2 Patrick     Allen      Allen Strateg… 4250 Lancaste… Wilmington Delaware    19805    
#> 3 Patrick     Allen      Allen Strateg… 4250 Lancaste… Wilmington Delaware    19805    
#> 4 Patrick     Allen      Allen Strateg… 4250 Lancaste… Wilmington Delaware    19805    
#> 5 Patrick     Allen      Allen Strateg… 4250 Lancaste… Wilmington Delaware    19805    
#> 6 Patrick     Allen      Allen Strateg… 4250 Lancaste… Wilmington Delaware    19805    
#> # … with 8 more variables: employer_name <chr>, employer_address1 <chr>, employer_address2 <chr>,
#> #   employer_city <chr>, employer_state <chr>, employer_zip <chr>, start_date <date>,
#> #   end_date <date>
tail(delr)
#> # A tibble: 6 x 15
#>   lobby_first lobby_last lobby_address1 lobby_address2 lobby_city lobby_state lobby_zip
#>   <chr>       <chr>      <chr>          <chr>          <chr>      <chr>       <chr>    
#> 1 Tarik       Zerrad     109 E Divisio… <NA>           Dover      Delaware    19901    
#> 2 Tarik       Zerrad     109 E Divisio… <NA>           Dover      Delaware    19901    
#> 3 Tarik       Zerrad     109 E Divisio… <NA>           Dover      Delaware    19901    
#> 4 Tarik       Zerrad     109 E Divisio… <NA>           Dover      Delaware    19901    
#> 5 Tarik       Zerrad     109 E Divisio… <NA>           Dover      Delaware    19901    
#> 6 Tarik       Zerrad     109 E Divisio… <NA>           Dover      Delaware    19901    
#> # … with 8 more variables: employer_name <chr>, employer_address1 <chr>, employer_address2 <chr>,
#> #   employer_city <chr>, employer_state <chr>, employer_zip <chr>, start_date <date>,
#> #   end_date <date>
glimpse(sample_frac(delr))
#> Observations: 1,447
#> Variables: 15
#> $ lobby_first       <chr> "Mary Kate", "Angela", "Robert L.", "Elizabeth", "James", "Verity", "M…
#> $ lobby_last        <chr> "McLaughlin", "LaManna", "Byrd", "Lewis", "Nutter Esq.", "Watson", "Sh…
#> $ lobby_address1    <chr> "222 Delaware Avenue", "296 Churchmans Road", "The Byrd Group LLC", "1…
#> $ lobby_address2    <chr> "Suite 1410", NA, "2 Penns Way Suite 305", NA, "19354C Miller Road", N…
#> $ lobby_city        <chr> "Wilmington", "New Castle", "New Castle", "New Castle", "Rehoboth Beac…
#> $ lobby_state       <chr> "Delaware", "Delaware", "Delaware", "Delaware", "Delaware", "Delaware"…
#> $ lobby_zip         <chr> "19801", "19720", "19720", "19720", "19971", "19901", "19702", "19901"…
#> $ employer_name     <chr> "Delaware State Education Association", "Delaware Public Employees Uni…
#> $ employer_address1 <chr> "136 East Water Street", "296 Churchman's Rd.", "5400 Legacy H1-41-66"…
#> $ employer_address2 <chr> NA, NA, NA, NA, NA, NA, "Suite 104", NA, "2nd Floor", "Ste.  201", NA,…
#> $ employer_city     <chr> "Dover", "New Castle", "Plano", "Louisville", "Wilmington", "Dover", "…
#> $ employer_state    <chr> "Delaware", "Delaware", "Texas", "Kentucky", "Delaware", "Delaware", "…
#> $ employer_zip      <chr> "19901", "19720", "75024", "402224904", "19801", "19903", "19702", "19…
#> $ start_date        <date> 2016-01-01, 2014-02-14, 2017-04-01, 2018-01-11, 2017-05-10, 2016-07-1…
#> $ end_date          <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, 2013-…
```

### Missing

There are no states missing key variables like `last_name` or
`start_date`.

``` r
glimpse_fun(delr, count_na)
#> # A tibble: 15 x 4
#>    col               type      n        p
#>    <chr>             <chr> <dbl>    <dbl>
#>  1 lobby_first       chr       0 0       
#>  2 lobby_last        chr       0 0       
#>  3 lobby_address1    chr       0 0       
#>  4 lobby_address2    chr     526 0.364   
#>  5 lobby_city        chr       0 0       
#>  6 lobby_state       chr       1 0.000691
#>  7 lobby_zip         chr       0 0       
#>  8 employer_name     chr       0 0       
#>  9 employer_address1 chr       0 0       
#> 10 employer_address2 chr     946 0.654   
#> 11 employer_city     chr       0 0       
#> 12 employer_state    chr       1 0.000691
#> 13 employer_zip      chr       0 0       
#> 14 start_date        date      0 0       
#> 15 end_date          date   1382 0.955
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
    col = lobby_adress_full,
    starts_with("lobby_address"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  # normalize combined addr
  mutate(
    lobby_address_norm = normal_address(
      address = lobby_adress_full,
      add_abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-lobby_adress_full)
```

The same process will be performed for `employer_address`.

``` r
delr <- delr %>% 
  unite(
    col = employer_adress_full,
    employer_address1, employer_address2,
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    employer_address_norm = normal_address(
      address = employer_adress_full,
      add_abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-employer_adress_full)
```

``` r
delr %>% 
  select(starts_with("lobby_address")) %>% 
  distinct() %>% 
  sample_frac()
#> # A tibble: 316 x 3
#>    lobby_address1                 lobby_address2      lobby_address_norm                           
#>    <chr>                          <chr>               <chr>                                        
#>  1 300 Exelon Way                 <NA>                300 EXELON WAY                               
#>  2 200 Sandy Beach Dr             <NA>                200 SANDY BEACH DRIVE                        
#>  3 700 13th Street NW             Suite 600           700 13TH STREET NORTHWEST SUITE 600          
#>  4 c/o 2350 Kerner Blvd.          Ste. 250            CO 2350 KERNER BOULEVARD SUITE 250           
#>  5 Laird Stabler & Associates LLC P.O. Box 523        LAIRD STABLER ASSOCIATES LLC PO BOX 523      
#>  6 100 Matsonford Rd Bld 4        Suite 201           100 MATSONFORD ROAD BLD 4 SUITE 201          
#>  7 3326 North Rockfield Dr        <NA>                3326 NORTH ROCKFIELD DRIVE                   
#>  8 Medical Society of Delaware    900 Prides Crossing MEDICAL SOCIETY OF DELAWARE 900 PRIDES CROSS…
#>  9 48 Colonial Lane               <NA>                48 COLONIAL LANE                             
#> 10 91 Christiana Rd               <NA>                91 CHRISTIANA ROAD                           
#> # … with 306 more rows
```

### ZIP

``` r
delr <- delr %>% 
  mutate(
    lobby_zip_norm = normal_zip(
      zip = lobby_zip,
      na_rep = TRUE
    ),
    employer_zip_norm = normal_zip(
      zip = employer_zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  delr$lobby_zip,
  delr$lobby_zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage          prop_in n_distinct prop_na n_out n_diff
#>   <chr>            <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 lobby_zip        0.983        131       0    25      9
#> 2 lobby_zip_norm   1            124       0     0      0
progress_table(
  delr$employer_zip,
  delr$employer_zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage             prop_in n_distinct  prop_na n_out n_diff
#>   <chr>               <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 employer_zip        0.973        322 0           39     21
#> 2 employer_zip_norm   0.998        308 0.000691     3      2
```

### State

``` r
delr <- delr %>% 
  mutate(
    lobby_state_norm = normal_state(
      state = lobby_state,
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = valid_state
    ),
    employer_state_norm = normal_state(
      state = employer_state,
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = valid_state
    )
  )
```

``` r
progress_table(
  delr$lobby_state,
  delr$lobby_state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage            prop_in n_distinct  prop_na n_out n_diff
#>   <chr>              <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 lobby_state            0         23 0.000691  1446     23
#> 2 lobby_state_norm       1         23 0.000691     0      1
progress_table(
  delr$employer_state,
  delr$employer_state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage               prop_in n_distinct  prop_na n_out n_diff
#>   <chr>                 <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 employer_state            0         34 0.000691  1446     34
#> 2 employer_state_norm       1         34 0.000691     0      1
```

``` r
select(delr, contains("state"))
#> # A tibble: 1,447 x 4
#>    lobby_state employer_state       lobby_state_norm employer_state_norm
#>    <chr>       <chr>                <chr>            <chr>              
#>  1 Delaware    Delaware             DE               DE                 
#>  2 Delaware    Delaware             DE               DE                 
#>  3 Delaware    Virginia             DE               VA                 
#>  4 Delaware    Delaware             DE               DE                 
#>  5 Delaware    District of Columbia DE               DC                 
#>  6 Delaware    New York             DE               NY                 
#>  7 Delaware    Minnesota            DE               MN                 
#>  8 Delaware    Delaware             DE               DE                 
#>  9 Delaware    New York             DE               NY                 
#> 10 Delaware    Massachusetts        DE               MA                 
#> # … with 1,437 more rows
```

### City

``` r
delr <- delr %>% 
  mutate(
    lobby_city_norm = normal_city(
      city = lobby_city, 
      geo_abbs = usps_city,
      st_abbs = c("DE", "DC", "DELEWARE"),
      na = invalid_city,
      na_rep = TRUE
    ),
    employer_city_norm = normal_city(
      city = employer_city, 
      geo_abbs = usps_city,
      st_abbs = c("DE", "DC", "DELEWARE"),
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

``` r
delr <- delr %>% 
  left_join(
    y = select(zipcodes, -state),
    by = c(
      "lobby_zip_norm" = "zip"
    )
  ) %>% 
  rename(lobby_city_match = city) %>% 
  mutate(
    lobby_match_abb = is_abbrev(lobby_city_norm, lobby_city_match),
    lobby_match_dist = stringdist(lobby_city_norm, lobby_city_match),
    lobby_city_swap = if_else(
      condition = lobby_match_abb | lobby_match_dist == 1,
      true = lobby_city_match,
      false = lobby_city_norm
    )
  )
```

``` r
delr <- delr %>% 
  left_join(
    y = select(zipcodes, -state),
    by = c(
      "employer_zip_norm" = "zip"
    )
  ) %>% 
  rename(employer_city_match = city) %>% 
  mutate(
    employer_match_abb = is_abbrev(employer_city_norm, employer_city_match),
    employer_match_dist = stringdist(employer_city_norm, employer_city_match),
    employer_city_swap = if_else(
      condition = employer_match_abb | employer_match_dist == 1,
      true = employer_city_match,
      false = employer_city_norm
    )
  )
```

``` r
progress_table(
  str_to_upper(delr$lobby_city),
  delr$lobby_city_norm,
  delr$lobby_city_swap,
  compare = valid_city
)
#> # A tibble: 3 x 6
#>   stage           prop_in n_distinct  prop_na n_out n_diff
#>   <chr>             <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 lobby_city)       0.997         88 0            4      3
#> 2 lobby_city_norm   0.998         88 0.000691     3      3
#> 3 lobby_city_swap   0.998         88 0.000691     3      3
progress_table(
  str_to_upper(delr$employer_city),
  delr$employer_city_norm,
  delr$employer_city_swap,
  compare = valid_city
)
#> # A tibble: 3 x 6
#>   stage              prop_in n_distinct prop_na n_out n_diff
#>   <chr>                <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 employer_city)       0.970        219 0          43     23
#> 2 employer_city_norm   0.978        218 0          32     20
#> 3 employer_city_swap   0.988        212 0.00276    17     13
```

``` r
delr %>% 
  filter(lobby_city_swap %out% valid_city) %>% 
  count(
    lobby_state_norm, 
    lobby_zip_norm, 
    lobby_city, 
    lobby_city_norm,
    lobby_city_match, 
    sort = TRUE
  )
#> # A tibble: 3 x 6
#>   lobby_state_norm lobby_zip_norm lobby_city    lobby_city_norm lobby_city_match     n
#>   <chr>            <chr>          <chr>         <chr>           <chr>            <int>
#> 1 NJ               08807          West Caldwell WEST CALDWELL   BRIDGEWATER          2
#> 2 NJ               07981          P.O. Box 915  <NA>            WHIPPANY             1
#> 3 PA               19038          Erdenheim     ERDENHEIM       GLENSIDE             1
```

### Year

``` r
min(delr$start_date)
#> [1] "1989-01-01"
max(delr$start_date)
#> [1] "2019-10-07"
min(delr$end_date, na.rm = TRUE)
#> [1] "2013-06-30"
max(delr$end_date, na.rm = TRUE)
#> [1] "2023-09-01"
```

``` r
delr <- delr %>% 
  mutate(
    start_year = year(start_date),
    end_year = year(end_date)
  )
```

## Conclude

1.  There are 1447 records in the database.
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
proc_dir <- here("de", "lobbying", "reg", "data", "processed")
dir_create(proc_dir)
```

``` r
delr %>% 
  select(
    -lobby_city_norm,
    -lobby_city_match,
    -lobby_match_abb,
    -lobby_match_dist,
    -employer_city_norm,
    -employer_city_match,
    -employer_match_abb,
    -employer_match_dist
  ) %>% 
  write_csv(
    path = glue("{proc_dir}/df_type_clean.csv"),
    na = ""
  )
```
