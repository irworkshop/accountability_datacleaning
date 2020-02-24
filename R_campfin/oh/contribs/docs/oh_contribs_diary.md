Ohio Contributions
================
Kiernan Nicholls
2020-02-19 16:56:01

<!-- Place comments regarding knitting here -->

## Project

The Accountability Project is an effort to cut across data silos and
give journalists, policy professionals, activists, and the public at
large a simple way to search across huge volumes of public data about
people and organizations.

Our goal is to standardizing public data on a few key fields by thinking
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

The IRW’s `campfin` package will also have to be installed from GitHub.
This package contains functions custom made to help facilitate the
processing of campaign finance data.

``` r
if (!require("pacman")) install.packages("pacman")
pacman::p_load_gh("irworkshop/campfin")
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  magrittr, # pipe operators
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  rvest, # read html pages
  vroom, # read files fast
  glue, # combine strings
  here, # relative storage
  fs # search storage 
)
```

This document should be run as part of the `R_campfin` project, which
lives as a sub-directory of the more general, language-agnostic
[`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning)
GitHub repository.

The `R_campfin` project uses the [RStudio
projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects)
feature and should be run as such. The project also uses the dynamic
`here::here()` tool for file paths relative to *your* machine.

``` r
# where does this document knit?
here::here()
#> [1] "/home/kiernan/Code/accountability_datacleaning/R_campfin"
```

## Data

The data is obtained from the [Ohio Secretary of
State](https://www.ohiosos.gov/). The OH SOS offers a file transfer page
(FTP) to download data in bulk rather than via searches.

> Welcome to the Ohio Secretary of State’s Campaign Finance File
> Transfer Page. This page was developed to allow users to obtain large
> sets of data faster than the normal query process. At this page you
> can download files of pre-queried data, such as all candidate
> contributions for a particular year or a list of all active political
> action committees registered with the Secretary of State. In addition,
> campaign finance data filed prior to 2000 is available only on this
> site. These files contain all relevant and frequently requested
> information. If you are looking for smaller or very specific sets of
> data please use the regular Campaign Finance queries listed on the
> tabs above.

## Import

### Download

> On the FTP page, please decide which information you would like to
> download. Click “Download File” on the right hand side. The system
> will then proceed to download the file into Microsoft Excel or provide
> you will an opportunity to download the file to the location on your
> computer (the settings on your computer will dictate this). You may
> see a series of dialog boxes on your screen asking you if you want to
> run or save the zipped `.exe` file. Follow the dialog boxes for
> whichever you chose telling the computer where you want the files
> saved. The end result will be a `.csv` file that you can open in
> Microsoft Excel or some other database application.

We can download all the contribution files by reading the FTP website
itself and scraping each of the “Download” links in the table. This
process needs to be repeated for candidates, PACs, and parties.

``` r
ftp_base <- "https://www6.ohiosos.gov/ords/"
t <- c("CAN", "PAC", "PARTY")
ftp_url <- glue("f?p=CFDISCLOSURE:73:7027737052457:{t}:NO:RP:P73_TYPE:{t}:")
ftp_url <- str_c(ftp_base, ftp_url)
ftp_params <- character()
ftp_table <- rep(list(NA), length(t))
for (i in seq_along(t)) {
  ftp_page <- read_html(ftp_url[i])
  table_id <- paste0("#", str_extract(ftp_page, '(?<=id\\=")report_.*(?="\\s)'))
  ftp_table[[i]] <- ftp_page %>%
    html_node(table_id) %>%
    html_table() %>%
    as_tibble() %>%
    select(-last_col()) %>%
    set_names(c("file", "date", "size")) %>%
    mutate_at(vars(2), parse_date_time, "%m/%d/%Y %H:%M:%S %p")
  con_index <- str_which(ftp_table[[i]]$file, "Contributions\\s-\\s\\d+")
  ftp_params <- ftp_page %>%
    html_node(table_id) %>%
    html_nodes("tr") %>%
    html_nodes("a") %>%
    html_attr("href") %>%
    str_subset("f\\?p") %>%
    extract(con_index) %>%
    append(ftp_params)
}
```

Then each link can be downloaded to the `/data/raw` directory.

``` r
wget <- function(url, dir) {
  system2(
    command = "wget",
    args = c(
      "--no-verbose", 
      "--content-disposition", 
      url, 
      paste("-P", raw_dir)
    )
  )
}
```

``` r
raw_dir <- dir_create(here("oh", "contribs", "data", "raw"))
raw_urls <- paste0(ftp_base, ftp_params)
if (length(dir_ls(raw_dir)) < 82) {
  map(raw_urls, wget, raw_dir)
}
raw_paths <- dir_ls(raw_dir)
```

### Read

> The data is in a “comma delimited” format that loads easily into
> Microsoft Excel or Access as well as many other spreadsheet or
> database programs. Many of the available files contain a significant
> quantity of data records. A spreadsheet program, such as Microsoft
> Excel, may not allow all of the data in a file to be loaded because of
> a limit on the number of available rows. For this reason, it is
> advised that a database application be utilized to load and work with
> the data available at this site…

We can read all 82 raw CSV files into a single data frame using
`purrr::map_df()` and `readr::read_csv()`.

``` r
ohc <- map_df(
  .x = raw_paths,
  .f = read_csv,
  na = c("", "NA", "N/A"),
  col_types = cols(.default = "c")
)
```

``` r
ohc <- ohc %>% 
  mutate_at(vars(FILE_DATE), parse_date, "%m/%d/%Y") %>% 
  mutate_at(vars(AMOUNT), parse_double) %>% 
  mutate_at(vars(MASTER_KEY, RPT_YEAR, REPORT_KEY, DISTRICT), parse_integer) 
```

## Explore

``` r
head(ohc)
#> # A tibble: 6 x 28
#>   com_name master_key rpt_desc rpt_year rpt_key desc  first middle last  suffix non_ind pac_no
#>   <chr>         <int> <chr>       <int>   <int> <chr> <chr> <chr>  <chr> <chr>  <chr>   <chr> 
#> 1 FRIENDS…          2 PRE-GEN…     1994  133090 31-E… LAWR… <NA>   ABBO… <NA>   <NA>    <NA>  
#> 2 FRIENDS…          2 PRE-GEN…     1994  133090 31-E… GLENN <NA>   ABEL  <NA>   <NA>    <NA>  
#> 3 FRIENDS…          2 PRE-PRI…     1994  133054 31-A… PETE  <NA>   ABELE <NA>   <NA>    <NA>  
#> 4 FRIENDS…          2 PRE-GEN…     1994  133090 31-E… BARB… <NA>   ABER  <NA>   <NA>    <NA>  
#> 5 FRIENDS…          2 PRE-GEN…     1994  133090 31-E… BARB… <NA>   ABER  <NA>   <NA>    <NA>  
#> 6 FRIENDS…          2 PRE-GEN…     1994  133090 31-J… MARL… <NA>   ACH   <NA>   <NA>    <NA>  
#> # … with 16 more variables: address <chr>, city <chr>, state <chr>, zip <chr>, date <date>,
#> #   amount <dbl>, event <chr>, occupation <chr>, inkind <chr>, other_type <chr>, rcv_event <chr>,
#> #   cand_first <chr>, cand_last <chr>, office <chr>, district <int>, party <chr>
tail(ohc)
#> # A tibble: 6 x 28
#>   com_name master_key rpt_desc rpt_year rpt_key desc  first middle last  suffix non_ind pac_no
#>   <chr>         <int> <chr>       <int>   <int> <chr> <chr> <chr>  <chr> <chr>  <chr>   <chr> 
#> 1 SHELBY …      15088 SEMIANN…     2019  3.52e8 31-C… <NA>  <NA>   <NA>  <NA>   MUTUAL… <NA>  
#> 2 SHELBY …      15088 SEMIANN…     2019  3.52e8 31-C… <NA>  <NA>   <NA>  <NA>   MUTUAL… <NA>  
#> 3 SHELBY …      15088 SEMIANN…     2019  3.52e8 31-C… <NA>  <NA>   <NA>  <NA>   OHIO D… <NA>  
#> 4 SHELBY …      15088 SEMIANN…     2019  3.52e8 31-C… <NA>  <NA>   <NA>  <NA>   OHIO D… <NA>  
#> 5 WARREN …      15222 SEMIANN…     2019  3.55e8 31-A… DON   <NA>   MAGEE <NA>   <NA>    <NA>  
#> 6 WARREN …      15222 SEMIANN…     2019  3.55e8 31-A… DON   <NA>   MAGEE <NA>   <NA>    <NA>  
#> # … with 16 more variables: address <chr>, city <chr>, state <chr>, zip <chr>, date <date>,
#> #   amount <dbl>, event <chr>, occupation <chr>, inkind <chr>, other_type <chr>, rcv_event <chr>,
#> #   cand_first <chr>, cand_last <chr>, office <chr>, district <int>, party <chr>
glimpse(sample_n(ohc, 20))
#> Observations: 20
#> Variables: 28
#> $ com_name   <chr> "OHIO EDUCATION ASSOC FUND FOR CHILDREN AND PUBLIC EDUCATION", "REALTORS PAC"…
#> $ master_key <int> 1814, 1515, 6542, 1577, 1780, 10285, 1683, 2047, 1814, 12856, 1745, 1527, 715…
#> $ rpt_desc   <chr> "ANNUAL   (JANUARY)", "PRE-PRIMARY", "POST-PRIMARY", "POST-GENERAL", "PRE-GEN…
#> $ rpt_year   <int> 2006, 2002, 2017, 2005, 2004, 2009, 1998, 2009, 2010, 2010, 2002, 2011, 2002,…
#> $ rpt_key    <int> 881980, 696520, 308242843, 928573, 834430, 280957, 584986, 1013395, 75248659,…
#> $ desc       <chr> "31-A  Stmt of Contribution", "31-A  Stmt of Contribution", "31-A  Stmt of Co…
#> $ first      <chr> "TANYA", "VICTORIA S", "CHANDLER", "CARL", "BOB", "JEAN", "DAPHNE", "ELIZABET…
#> $ middle     <chr> "R", NA, NA, "J", NA, "B.", NA, NA, "R", NA, "C", NA, "W", NA, NA, NA, NA, NA…
#> $ last       <chr> "SCHMIDT", "MILLER", "MYERS", "JOHNSON", "WRIGHT", "JOHNS", "REAVES", "SOLOSA…
#> $ suffix     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "JR", NA, NA, NA, NA, NA, NA,…
#> $ non_ind    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
#> $ pac_no     <chr> "OH299", "CP401", "PCE", "CP718", "OH214", NA, "LA766", "OH723", "OH299", NA,…
#> $ address    <chr> "2911 LATONIA BLVD", "265 EAST JEFFERSON STREET", "1245 KEVROB DR.", "1219 LE…
#> $ city       <chr> "TOLEDO", "JEFFERSON", "ZANESVILLE", "THIBODAUX", "GEORGETOWN", "CINCINNATI",…
#> $ state      <chr> "OH", "OH", "OH", "LA", "KY", "OH", "OH", "ID", "OH", "NY", "OH", "OH", "OH",…
#> $ zip        <chr> "43606", "44047", "43701", "70301", "40324", "45226-2013", "43227", "83705-11…
#> $ date       <date> 2006-12-15, 2002-02-25, 2017-04-26, 2005-11-09, 2004-09-07, 2009-05-26, 1998…
#> $ amount     <dbl> 1.00, 10.00, 1.00, 5.00, 2.00, 25.00, 1.00, 25.00, 1.00, 50.00, 8.06, 1.00, 2…
#> $ event      <chr> NA, NA, NA, NA, NA, "05/15/2009", NA, NA, NA, NA, NA, NA, NA, NA, NA, "02/18/…
#> $ occupation <chr> "SYLVANIA CITY SD", "REAL ESTATE SALESPERSON", NA, "THE LOUISIANA COCA-COLA B…
#> $ inkind     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "SNACKS",…
#> $ other_type <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
#> $ rcv_event  <chr> NA, NA, NA, NA, NA, NA, "N", "N", NA, NA, NA, NA, NA, "N", NA, NA, NA, "N", N…
#> $ cand_first <chr> NA, NA, NA, NA, NA, "TED", NA, NA, NA, "JOHN", NA, NA, "JOHN", NA, "CATHERINE…
#> $ cand_last  <chr> NA, NA, NA, NA, NA, "STRICKLAND", NA, NA, NA, "KASICH", NA, NA, "WHITE", NA, …
#> $ office     <chr> NA, NA, NA, NA, NA, "GOVERNOR", NA, NA, NA, "GOVERNOR", NA, NA, "HOUSE", NA, …
#> $ district   <int> NA, NA, NA, NA, NA, 0, NA, NA, NA, 0, NA, NA, 38, NA, 24, 33, NA, NA, 17, NA
#> $ party      <chr> NA, NA, NA, NA, NA, "DEMOCRAT", NA, NA, NA, "REPUBLICAN", NA, NA, "REPUBLICAN…
```

### Missing

``` r
col_stats(ohc, count_na)
#> # A tibble: 28 x 4
#>    col        class        n           p
#>    <chr>      <chr>    <int>       <dbl>
#>  1 com_name   <chr>        4 0.000000427
#>  2 master_key <int>        0 0          
#>  3 rpt_desc   <chr>        0 0          
#>  4 rpt_year   <int>        0 0          
#>  5 rpt_key    <int>        0 0          
#>  6 desc       <chr>        0 0          
#>  7 first      <chr>   550651 0.0588     
#>  8 middle     <chr>  5152147 0.550      
#>  9 last       <chr>   530994 0.0567     
#> 10 suffix     <chr>  9211439 0.984      
#> 11 non_ind    <chr>  8829315 0.943      
#> 12 pac_no     <chr>  2091508 0.223      
#> 13 address    <chr>    80516 0.00860    
#> 14 city       <chr>    76745 0.00820    
#> 15 state      <chr>    68728 0.00734    
#> 16 zip        <chr>    65148 0.00696    
#> 17 date       <date>    7991 0.000854   
#> 18 amount     <dbl>     3112 0.000332   
#> 19 event      <chr>  8434654 0.901      
#> 20 occupation <chr>  3596587 0.384      
#> 21 inkind     <chr>  9288439 0.992      
#> 22 other_type <chr>  9307540 0.994      
#> 23 rcv_event  <chr>  6615014 0.707      
#> 24 cand_first <chr>  7232931 0.773      
#> 25 cand_last  <chr>  7232528 0.772      
#> 26 office     <chr>  7232510 0.772      
#> 27 district   <int>  7276605 0.777      
#> 28 party      <chr>  7232917 0.773
```

``` r
ohc <- ohc %>% 
  unite(
    first, middle, last, non_ind,
    col = con_name,
    sep = " ",
    na.rm = TRUE
  ) %>% 
  flag_na(date, con_name, amount, com_name)

sum(ohc$na_flag)
#> [1] 10708
percent(mean(ohc$na_flag), 0.01)
#> [1] "0.11%"
```

### Continuous

#### Amounts

``` r
summary(ohc$amount)
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max.     NA's 
#>   -50000        2        8      270       50 17295083     3112
mean(ohc$amount <= 0, na.rm = TRUE)
#> [1] 0.0008497321
```

![](../plots/hist_amount-1.png)<!-- -->

#### Dates

``` r
ohc <- mutate(ohc, year = year(date))
```

``` r
min(ohc$date, na.rm = TRUE)
#> [1] "10-05-07"
sum(ohc$year < 1990, na.rm = TRUE)
#> [1] 1025
max(ohc$date, na.rm = TRUE)
#> [1] "9999-03-31"
sum(ohc$date > today(), na.rm = TRUE)
#> [1] 1331
```

![](../plots/bar_year-1.png)<!-- -->

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
ohc <- mutate(
  .data = ohc,
  address_norm = normal_address(
    address = address,
    abbs = usps_street,
    na_rep = TRUE
  )
)
```

``` r
ohc %>% 
  select(contains("address")) %>% 
  distinct() %>% 
  sample_n(10)
#> # A tibble: 10 x 2
#>    address               address_norm       
#>    <chr>                 <chr>              
#>  1 1789 S.R. 412         1789 S R 412       
#>  2 9875 WATKINS RD       9875 WATKINS RD    
#>  3 1462 S. PLAINVIEW DR. 1462 S PLAINVIEW DR
#>  4 313 COOPER AVE        313 COOPER AVE     
#>  5 5545 SAXON DR.        5545 SAXON DR      
#>  6 36 MARIGOLD CT.       36 MARIGOLD CT     
#>  7 216 SPRUCEWOOD        216 SPRUCEWOOD     
#>  8 2230 PATTERSON        2230 PATTERSON     
#>  9 2540 FENWICK RD       2540 FENWICK RD    
#> 10 5185 HAMPTON COURT    5185 HAMPTON CT
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
ohc <- mutate(
  .data = ohc,
  zip_norm = normal_zip(
    zip = zip,
    na_rep = TRUE
  )
)
```

``` r
progress_table(
  ohc$zip,
  ohc$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na   n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl>   <dbl>  <dbl>
#> 1 zip        0.822     331160 0.00696 1658540 310775
#> 2 zip_norm   0.998      26999 0.0232    14459   2978
```

### State

``` r
ohc <- mutate(ohc, state_norm = state)
ohc$state_norm[which(ohc$state == "0H")] <- "OH"
ohc$state_norm[which(ohc$state == "IH")] <- "OH"
ohc$state_norm[which(ohc$state == "PH")] <- "OH"
ohc$state_norm[which(ohc$state == "O")]  <- "OH"
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
ohc <- mutate(
  .data = ohc,
  city_norm = normal_city(
    city = city, 
    abbs = usps_city,
    states = c("OH", "DC", "OHIO"),
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
ohc <- ohc %>% 
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
      condition = !is.na(match_dist) & match_abb | match_dist == 1,
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

#### Refine

The \[OpenRefine\] algorithms can be used to group similar strings and
replace the less common versions with their most common counterpart.
This can greatly reduce inconsistency, but with low confidence; we will
only keep any refined strings that have a valid city/state/zip
combination.

``` r
good_refine <- ohc %>% 
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

    #> # A tibble: 496 x 5
    #>    state_norm zip_norm city_swap       city_refine        n
    #>    <chr>      <chr>    <chr>           <chr>          <int>
    #>  1 MI         48177    SAMIARA         SAMARIA          107
    #>  2 OH         45239    CINCINATTI      CINCINNATI       101
    #>  3 OH         44094    WILLOUGHBY HI   WILLOUGHBY        98
    #>  4 OH         45245    CINCINATTI      CINCINNATI        61
    #>  5 OH         44094    WILLOUGHBY HILL WILLOUGHBY        48
    #>  6 NY         11733    SETAUKET        EAST SETAUKET     42
    #>  7 OH         44721    NO CANTON       CANTON            33
    #>  8 OH         43334    MERANGO         MARENGO           23
    #>  9 OH         45247    CINCINATTI      CINCINNATI        21
    #> 10 OH         44413    PALESTINE       EAST PALESTINE    20
    #> # … with 486 more rows

Then we can join the refined values back to the database.

``` r
ohc <- ohc %>% 
  left_join(good_refine) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Check

We can use the `campfin::check_city()` function to pass the remaining
unknown `city_refine` values (and their `state_norm`) to the Google
Geocode API. The function returns the name of the city or locality which
most associated with those values.

This is an easy way to both check for typos and check whether an unknown
`city_refine` value is actually a completely acceptable neighborhood,
census designated place, or some other locality not found in our
`valid_city` vector from our `zipcodes` database.

First, we’ll filter out any known valid city and aggregate the remaining
records by their city and state. Then, we will only query those unknown
cities which appear at least ten times.

``` r
ohc_out <- ohc %>% 
  filter(city_refine %out% c(valid_city, extra_city)) %>% 
  count(city_refine, state_norm, sort = TRUE) %>% 
  drop_na() %>% 
  slice(1:1000)

sum(ohc_out$n) / nrow(ohc)
#> [1] 0.01065614
```

Passing these values to `campfin::check_city()` with `purrr::pmap_dfr()`
will return a single tibble of the rows returned by each city/state
combination.

First, we’ll check to see if the API query has already been done and a
file exist on disk. If such a file exists, we can read it using
`readr::read_csv()`. If not, the query will be sent and the file will be
written using `readr::write_csv()`.

``` r
check_file <- here("oh", "contribs", "data", "api_check.csv")
if (file_exists(check_file)) {
  # checked for saved file
  check <- read_csv(check_file)
} else {
  check <- pmap_dfr(
    .l = list(
      ohc_out$city_refine, 
      ohc_out$state_norm
    ), 
    .f = check_city, 
    key = Sys.getenv("GEOCODE_KEY"), 
    guess = TRUE
  ) %>% 
    mutate(guess = coalesce(guess_city, guess_place)) %>% 
    select(-guess_city, -guess_place)
  # save for replication
  write_csv(check, check_file)
}
```

Any city/state combination with a `check_city_flag` equal to `TRUE`
returned a matching city string from the API, indicating this
combination is valid enough to be ignored.

``` r
valid_locality <- unique(check$guess[check$check_city_flag])
```

Then we can perform some simple comparisons between the queried city and
the returned city. If they are extremely similar, we can accept those
returned locality strings and add them to our list of accepted
additional localities.

``` r
valid_locality <- check %>% 
  filter(!check_city_flag) %>% 
  mutate(
    abb = is_abbrev(original_city, guess),
    dist = str_dist(original_city, guess)
  ) %>%
  filter(abb | dist <= 3) %>% 
  pull(guess) %>% 
  c(valid_locality)
```

#### Progress

| stage        | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :----------- | -------: | ----------: | -------: | -----: | ------: |
| city\_raw    |    0.961 |       31944 |    0.008 | 362468 |   20132 |
| city\_norm   |    0.982 |       29555 |    0.008 | 165110 |   17657 |
| city\_swap   |    0.992 |       18550 |    0.026 |  74484 |    6738 |
| city\_refine |    0.992 |       18147 |    0.026 |  72761 |    6336 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/bar_progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar_distinct-1.png)<!-- -->

## Conclude

``` r
ohc <- ohc %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean"))
```

``` r
glimpse(sample_n(ohc, 20))
#> Observations: 20
#> Variables: 31
#> $ com_name      <chr> "FRIENDS OF ARMOND BUDISH", "OHIO EDUCATION ASSOC FUND FOR CHILDREN AND PU…
#> $ master_key    <int> 10794, 1814, 1814, 1814, 1814, 11818, 1515, 7100, 104, 1814, 1806, 2047, 7…
#> $ rpt_desc      <chr> "ANNUAL   (JANUARY)", "PRE-GENERAL", "PRE-PRIMARY", "PRE-PRIMARY", "POST-P…
#> $ rpt_year      <int> 2009, 2010, 2005, 2018, 2011, 2009, 2006, 2019, 1998, 2008, 2001, 2008, 20…
#> $ rpt_key       <int> 253984, 89637310, 951322, 317571556, 104952505, 82716199, 856306, 34917184…
#> $ desc          <chr> "31-A  Stmt of Contribution", "31-A  Stmt of Contribution", "31-A  Stmt of…
#> $ con_name      <chr> "BERTHA M WEIL", "JENNIFER A MCMAHON", "PHIL A UNKEFER", "PATRICIA R NAEEM…
#> $ suffix        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ pac_no        <chr> NA, "OH299", "OH299", "OH299", "OH299", NA, "CP401", "CP1037", NA, "OH299"…
#> $ address       <chr> "23511 CHAGRIN BLVD.", "3845 LOGAN THORNVILLE RD NE", "8100 ALBERTA BEACH …
#> $ city_raw      <chr> "BEACHWOOD", "RUSHVILLE", "LOUISVILLE", "COLUMBUS", "ELYRIA", "STRONGSVILL…
#> $ state         <chr> "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "WA", "O…
#> $ zip           <chr> "44122", "43150", "44641", "43224", "44035", "44136", "43606-2570", "43065…
#> $ date          <date> 2009-12-19, 2010-08-06, 2005-01-04, 2018-03-02, 2011-05-09, 2009-09-19, 2…
#> $ amount        <dbl> 50.00, 1.00, 1.00, 2.00, 2.00, 1000.00, 20.00, 2.00, 250.00, 2.00, 25.00, …
#> $ event         <chr> NA, NA, NA, NA, NA, NA, NA, NA, "08/18/1998", NA, NA, NA, NA, NA, NA, NA, …
#> $ occupation    <chr> "RETIRED", "PICKERINGTON LOCAL SD", "OEA", "GROVEPORT MADISON LOCAL SD", "…
#> $ inkind        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ other_type    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ rcv_event     <chr> "N", NA, NA, NA, NA, NA, NA, NA, "N", NA, NA, "N", NA, NA, "N", NA, "N", N…
#> $ cand_first    <chr> "ARMOND", NA, NA, NA, NA, "SUSAN", NA, NA, "BETTY", NA, NA, NA, "CHRISTOPH…
#> $ cand_last     <chr> "BUDISH", NA, NA, NA, NA, "HAVERKOS", NA, NA, "MONTGOMERY", NA, NA, NA, "W…
#> $ office        <chr> "HOUSE", NA, NA, NA, NA, "STATE BOARD OF EDUCATION", NA, NA, "ATTORNEY GEN…
#> $ district      <int> 8, NA, NA, NA, NA, 3, NA, NA, 0, NA, NA, NA, 10, NA, NA, NA, NA, NA, NA, NA
#> $ party         <chr> "DEMOCRAT", NA, NA, NA, NA, "NON-PARTISAN", NA, NA, "REPUBLICAN", NA, NA, …
#> $ na_flag       <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ year          <dbl> 2009, 2010, 2005, 2018, 2011, 2009, 2006, 2019, 1998, 2008, 2001, 2008, 20…
#> $ address_clean <chr> "23511 CHAGRIN BLVD", "3845 LOGAN THORNVILLE RD NE", "8100 ALBERTA BCH ST …
#> $ zip_clean     <chr> "44122", "43150", "44641", "43224", "44035", "44136", "43606", "43065", "4…
#> $ state_clean   <chr> "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "WA", "O…
#> $ city_clean    <chr> "BEACHWOOD", "RUSHVILLE", "LOUISVILLE", "COLUMBUS", "ELYRIA", "STRONGSVILL…
```

1.  There are 9,362,773 records in the database.
2.  The range and distribution of `amount` and `date` seem reasonable.
3.  There are 10,708 records missing a key variable.
4.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
5.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
clean_dir <- dir_create(here("oh", "contribs", "data", "clean"))
```

``` r
write_csv(
  x = ohc,
  path = path(clean_dir, "oh_contribs_clean.csv"),
  na = ""
)
```
