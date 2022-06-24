Alaska Businesses
================
Kiernan Nicholls
Fri Jun 24 14:12:26 2022

-   <a href="#project" id="toc-project">Project</a>
-   <a href="#objectives" id="toc-objectives">Objectives</a>
-   <a href="#packages" id="toc-packages">Packages</a>
-   <a href="#source" id="toc-source">Source</a>
    -   <a href="#disclaimer" id="toc-disclaimer">Disclaimer</a>
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
here::i_am("state/ak/businesses/docs/ak_businesses_diary.Rmd")
```

## Source

Alaskan business licenses are available from the Alaska Department of
Commerce, Community, and Economic Development which provides \[direct
downloads\]\[dd\] to listings of Corporations, Business & Professional
Licensing.

> The Division of Corporations, Business and Professional Licensing
> provides access to thousands of license records online as a service to
> the public. Use the links below to search specific license types,
> including corporations, business licenses, endorsements, and
> professional licenses.

### Disclaimer

> The Division has attempted to insure that the information contained in
> these electronic documents is as accurate as possible. Only authorized
> staff from the Division of Corporations, Business and Professional
> Licensing has access to modify the data provided.
>
> For individuals who have had a licensing action, a notation should be
> reflected on their website record as “This license has been the
> subject of a formal agreement, order or disciplinary action. Contact
> the Division for more information.” The Division makes no guarantee
> that such action will appear on this website and further, we make no
> warranty or guarantee of the accuracy or reliability of the content of
> this website or the content of any other website to which it may link.
>
> Assessing the accuracy and reliability of the information obtained
> from this website is solely the responsibility of the user. The
> Division shall not be responsible or liable for any errors contained
> herein or for any damages resulting from the use of the information
> contained herein.

## Download

> The Division also allows for full downloads of our corporations,
> business, and professional licensing databases in .CSV format. Select
> one of the links below to download an Excel spreadsheet of all
> licenses on record with the state. Please note that these downloads
> may require some manipulation and further investigation via NAICS
> code, Entity Type, zip code, dates, etc., in order to properly
> organize the data provided.

``` r
raw_url <- "https://www.commerce.alaska.gov/cbp/DBDownloads/BusinessLicenseDownload.CSV"
raw_dir <- dir_create(here("state", "ak", "businesses", "data", "raw"))
raw_csv <- path(raw_dir, basename(raw_url))
```

``` r
if (!file_exists(raw_csv)) {
  download.file(raw_url, raw_csv)
}
```

## Read

``` r
akl <- read_delim(
  file = raw_csv,
  delim = ",",
  locale = locale(date_format = "%m/%d/%Y"),
  escape_backslash = FALSE,
  escape_double = FALSE,
  col_types = cols(
    .default = col_character()
    # DateEffective = col_date(),
    # DateExpired = col_date(),
  )
)
```

``` r
sub_date <- function(x) {
  readr::parse_date(
    x = stringr::str_remove(x, "\\s.*$"),
    format = "%m/%d/%Y"
  )
}
```

``` r
akl <- akl %>% 
  clean_names(case = "snake") %>% 
  mutate(
    across(ends_with("_date"), sub_date),
    across(where(is_character), ~na_if(str_squish(.), ""))
  )
```

## Explore

There are 99,030 rows of 19 columns. Each record represents a single
business license issued to a business in Alaska.

``` r
glimpse(akl)
#> Rows: 99,030
#> Columns: 19
#> $ owners           <chr> "A AND A ROOFING CO, INC.", "A AND W WHOLESALE COMPANY INC", "ELAINE S. BAKER & ASSOCIATES, I…
#> $ license_number   <chr> "5", "11", "34", "44", "173", "237", "256", "257", "265", "316", "322", "355", "363", "401", …
#> $ business_name    <chr> "A & A ROOFING CO, INC", "A AND W WHOLESALE COMPANY INC", "ELAINE S. BAKER & ASSOCIATES, INC.…
#> $ status           <chr> "Active", "Active", "Active", "Active", "Active", "Active", "Active", "Active", "Active", "Ac…
#> $ issue_date       <date> 1969-07-15, 1990-12-21, 1990-12-28, 1990-12-27, 1991-01-03, 1991-01-03, 1991-01-10, 1991-01-…
#> $ renew_date       <date> 2020-10-05, 2020-11-29, 2020-12-19, 2020-11-09, 2020-12-11, 2021-12-22, 2021-08-09, 2021-10-…
#> $ expire_date      <date> 2022-12-31, 2022-12-31, 2022-12-31, 2022-12-31, 2022-12-31, 2023-12-31, 2022-12-31, 2023-12-…
#> $ physical_city    <chr> "FAIRBANKS", "Fairbanks", "ANCHORAGE", "JUNEAU", "SEATTLE", "ANCHORAGE", "HAINES", "ANCHORAGE…
#> $ physical_country <chr> "UNITED STATES", "UNITED STATES", "UNITED STATES", "UNITED STATES", "UNITED STATES", "UNITED …
#> $ physical_line1   <chr> "925 ASPEN ST.", "717 2nd Avenue", "811 W 8th Avenue", "9999 GLACIER HIGHWAY", "19300 INTERNA…
#> $ physical_line2   <chr> NA, NA, NA, NA, NA, NA, NA, NA, "9072990570", NA, NA, NA, NA, NA, NA, NA, NA, NA, "8587352176…
#> $ physical_state   <chr> "AK", "AK", "AK", "AK", "WA", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "KS", "AK…
#> $ physical_zip_out <chr> "99709", "99701", "99501", "99801", "98188", "99508", "99827", "99501-1731", "99603", "99502"…
#> $ mailing_city     <chr> "FAIRBANKS", "FAIRBANKS", "ANCHORAGE", "JUNEAU", "SEATTLE", "ANCHORAGE", "HAINES", "ANCHORAGE…
#> $ mailing_country  <chr> "UNITED STATES", "UNITED STATES", "UNITED STATES", "UNITED STATES", "UNITED STATES", "UNITED …
#> $ mailing_line1    <chr> "P O BOX 70314", "PO BOX 72385", "811 W 8th Avenue", "9999 GLACIER HIGHWAY", "PO BOX 68900", …
#> $ mailing_line2    <chr> NA, NA, NA, NA, "ATTN:LICENSING-SEAZL", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "…
#> $ mailing_state    <chr> "AK", "AK", "AK", "AK", "WA", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "KS", "AK…
#> $ mailing_zip_out  <chr> "99707", "99707", "99501", "99801", "98168", "99508", "99827", "99503-3958", "99603", "99502"…
tail(akl)
#> # A tibble: 6 × 19
#>   owners            license_number business_name status issue_date renew_date expire_date physical_city physical_country
#>   <chr>             <chr>          <chr>         <chr>  <date>     <date>     <date>      <chr>         <chr>           
#> 1 randy mcfarland   2159606        JOVY'S E-BIK… Active 2022-06-23 NA         2023-12-31  seward        UNITED STATES   
#> 2 Prince William S… 2159607        Prince Willi… Active 2022-06-23 NA         2023-12-31  Anchorage     UNITED STATES   
#> 3 Kody Worley       2159608        AK Shock Wor… Active 2022-06-23 NA         2023-12-31  Wasilla       UNITED STATES   
#> 4 Jaime Sorrow      2159609        Affordable L… Active 2022-06-23 NA         2023-12-31  Wasilla       UNITED STATES   
#> 5 Lauryn Oliver-Fr… 2159610        Ashlee Olive… Active 2022-06-23 NA         2023-12-31  Soldotna      UNITED STATES   
#> 6 Michael Assan; R… 2159611        Sparkle Clea… Active 2022-06-23 NA         2023-12-31  Fort wainwri… UNITED STATES   
#> # … with 10 more variables: physical_line1 <chr>, physical_line2 <chr>, physical_state <chr>, physical_zip_out <chr>,
#> #   mailing_city <chr>, mailing_country <chr>, mailing_line1 <chr>, mailing_line2 <chr>, mailing_state <chr>,
#> #   mailing_zip_out <chr>
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(akl, count_na)
#> # A tibble: 19 × 4
#>    col              class      n         p
#>    <chr>            <chr>  <int>     <dbl>
#>  1 owners           <chr>      0 0        
#>  2 license_number   <chr>      0 0        
#>  3 business_name    <chr>      1 0.0000101
#>  4 status           <chr>      0 0        
#>  5 issue_date       <date>  1719 0.0174   
#>  6 renew_date       <date> 40697 0.411    
#>  7 expire_date      <date>     0 0        
#>  8 physical_city    <chr>     25 0.000252 
#>  9 physical_country <chr>      2 0.0000202
#> 10 physical_line1   <chr>      4 0.0000404
#> 11 physical_line2   <chr>  77842 0.786    
#> 12 physical_state   <chr>    139 0.00140  
#> 13 physical_zip_out <chr>    170 0.00172  
#> 14 mailing_city     <chr>      1 0.0000101
#> 15 mailing_country  <chr>      0 0        
#> 16 mailing_line1    <chr>      1 0.0000101
#> 17 mailing_line2    <chr>  88838 0.897    
#> 18 mailing_state    <chr>    127 0.00128  
#> 19 mailing_zip_out  <chr>    132 0.00133
```

We can flag any record missing a key variable needed to identify a
transaction.

``` r
key_vars <- c("business_name", "owners", "issue_date")
akl <- flag_na(akl, all_of(key_vars))
sum(akl$na_flag)
#> [1] 1720
```

``` r
akl %>% 
  filter(na_flag) %>% 
  select(all_of(key_vars))
#> # A tibble: 1,720 × 3
#>    business_name                               owners                                      issue_date
#>    <chr>                                       <chr>                                       <date>    
#>  1 JUNEAU FOOT AND ANKLE CLINIC                FRANK MESDAG                                NA        
#>  2 BRADFORD'S APARTMENTS                       GARY BRADFORD                               NA        
#>  3 KENNETH P EGGERS                            KENNETH EGGERS                              NA        
#>  4 BRECHAN ENTERPRISES INC                     BRECHAN ENTERPRISES INC                     NA        
#>  5 BRICE INC                                   BRICE INC                                   NA        
#>  6 ONEILL PROPERTIES, INC                      O'NEILL PROPERTIES, INC.                    NA        
#>  7 DENTON CIVIL AND MINERAL                    STEPHEN DENTON                              NA        
#>  8 ALASKA SALMON BAKE                          INTRA SEA INC                               NA        
#>  9 BURNS & MCDONNELL ENGINEERING COMPANY, INC. BURNS & MCDONNELL ENGINEERING COMPANY, INC. NA        
#> 10 TIKCHIK NARROWS LODGE INC                   TIKCHIK NARROWS LODGE INC                   NA        
#> # … with 1,710 more rows
```

### Duplicates

We can also flag any record completely duplicated across every column.

``` r
akl <- flag_dupes(akl, -license_number)
sum(akl$dupe_flag)
#> [1] 198
```

``` r
akl %>% 
  filter(dupe_flag) %>% 
  select(license_number, all_of(key_vars)) %>% 
  arrange(issue_date)
#> # A tibble: 198 × 4
#>    license_number business_name                                  owners                                       issue_date
#>    <chr>          <chr>                                          <chr>                                        <date>    
#>  1 595            ANCHORAGE SAND AND GRAVEL COMPANY, INC.        ANCHORAGE SAND AND GRAVEL COMPANY INC        1996-11-15
#>  2 31932          ANCHORAGE SAND AND GRAVEL COMPANY, INC.        ANCHORAGE SAND AND GRAVEL COMPANY INC        1996-11-15
#>  3 278512         SWISSPORT USA INC                              SWISSPORT USA INC                            2000-09-13
#>  4 278513         SWISSPORT USA INC                              SWISSPORT USA INC                            2000-09-13
#>  5 706685         NUSHAGAK ELECTRIC & TELEPHONE COOPERATIVE, INC NUSHAGAK ELECTRIC & TELEPHONE COOPERATIVE, … 2001-11-30
#>  6 706686         NUSHAGAK ELECTRIC & TELEPHONE COOPERATIVE, INC NUSHAGAK ELECTRIC & TELEPHONE COOPERATIVE, … 2001-11-30
#>  7 706687         NUSHAGAK ELECTRIC & TELEPHONE COOPERATIVE, INC NUSHAGAK ELECTRIC & TELEPHONE COOPERATIVE, … 2001-11-30
#>  8 288565         KINGFISHER CHARTERS AND LODGE, LLC             KINGFISHER CHARTERS & LODGE, LLC             2002-04-12
#>  9 288566         KINGFISHER CHARTERS AND LODGE, LLC             KINGFISHER CHARTERS & LODGE, LLC             2002-04-12
#> 10 721801         NORTH PACIFIC FUEL (CAPTAIN'S BAY)             PETRO STAR INC.                              2004-07-21
#> # … with 188 more rows
```

### Categorical

``` r
col_stats(akl, n_distinct)
#> # A tibble: 21 × 4
#>    col              class      n         p
#>    <chr>            <chr>  <int>     <dbl>
#>  1 owners           <chr>  88456 0.893    
#>  2 license_number   <chr>  99030 1        
#>  3 business_name    <chr>  97450 0.984    
#>  4 status           <chr>      1 0.0000101
#>  5 issue_date       <date>  8418 0.0850   
#>  6 renew_date       <date>   643 0.00649  
#>  7 expire_date      <date>     6 0.0000606
#>  8 physical_city    <chr>   4553 0.0460   
#>  9 physical_country <chr>     46 0.000465 
#> 10 physical_line1   <chr>  81813 0.826    
#> 11 physical_line2   <chr>  13533 0.137    
#> 12 physical_state   <chr>     69 0.000697 
#> 13 physical_zip_out <chr>  14014 0.142    
#> 14 mailing_city     <chr>   4437 0.0448   
#> 15 mailing_country  <chr>     44 0.000444 
#> 16 mailing_line1    <chr>  74608 0.753    
#> 17 mailing_line2    <chr>   5085 0.0513   
#> 18 mailing_state    <chr>     70 0.000707 
#> 19 mailing_zip_out  <chr>  16610 0.168    
#> 20 na_flag          <lgl>      2 0.0000202
#> 21 dupe_flag        <lgl>      2 0.0000202
```

``` r
mean(akl$status == "Active")
#> [1] 1
```

### Dates

We can add the calendar year from `date` with `lubridate::year()`

``` r
akl <- mutate(akl, issue_year = year(issue_date))
```

``` r
min(akl$issue_date, na.rm = TRUE)
#> [1] "1969-07-15"
sum(akl$issue_year < 2000, na.rm = TRUE)
#> [1] 3082
max(akl$issue_date, na.rm = TRUE)
#> [1] "2022-06-23"
sum(akl$issue_date > today(), na.rm = TRUE)
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
addr_norm <- akl %>% 
  distinct(physical_line1, physical_line2) %>%  
  mutate(
    norm_address1 = normal_address(
      address = physical_line1,
      abbs = usps_street,
      na_rep = TRUE
    ),
    norm_address3 = normal_address(
      address = physical_line2,
      abbs = usps_street,
      na_rep = TRUE,
      abb_end = FALSE
    )
  ) %>% 
  unite(
    col = address_norm,
    starts_with("norm_address"),
    sep = " ",
    remove = TRUE,
    na.rm = TRUE
  )
```

``` r
addr_norm %>% 
  filter(!is.na(physical_line2)) %>% 
  sample_n(10)
#> # A tibble: 10 × 3
#>    physical_line1                    physical_line2     address_norm                         
#>    <chr>                             <chr>              <chr>                                
#>  1 6424 E Greenway Pkwy              Suite 118          6424 E GREENWAY PKWY STE 118         
#>  2 101 E. International Airport Road Suite B            101 E INTERNATIONAL AIRPORT RD STE B 
#>  3 7051 Lake O the Hills Cir         9074402111         7051 LAKE O THE HILLS CIR 9074402111 
#>  4 301 Calista Court                 Ste 102            301 CALISTA CT STE 102               
#>  5 9449 Dinaaka Cir, N/A             9076940557         9449 DINAAKA CIR N/A 9076940557      
#>  6 Aleknagik Lake road 5 Mile        9078431502         ALEKNAGIK LAKE ROAD 5 MILE 9078431502
#>  7 1200 Woodside Dr.                 B-6                1200 WOODSIDE DR B6                  
#>  8 432 S. Franklin St                9077232004         432 S FRANKLIN ST 9077232004         
#>  9 1600 West 11th Avenue             Apartment 24       1600 WEST 11TH AVE APT 24            
#> 10 14090 Southwest Freeway           Suite 300 room 361 14090 SOUTHWEST FWY STE 300 RM 361
```

``` r
akl <- left_join(akl, addr_norm, by = c("physical_line1", "physical_line2"))
```

### ZIP

``` r
prop_in(akl$physical_zip_out, valid_zip)
#> [1] 0.8715557
```

``` r
akl <- akl %>% 
  mutate(
    zip_norm = normal_zip(
      zip = physical_zip_out,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  akl$physical_zip_out,
  akl$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 × 6
#>   stage                prop_in n_distinct prop_na n_out n_diff
#>   <chr>                  <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 akl$physical_zip_out   0.872      14014 0.00172 12698  10333
#> 2 akl$zip_norm           0.998       4153 0.00172   223    162
```

### State

``` r
prop_in(akl$physical_state, valid_state)
#> [1] 0.9987764
```

The unknown state values are Canadian provinces and will be left alone.

``` r
akl %>% 
  count(physical_state, sort = TRUE) %>% 
  filter(physical_state %out% valid_state)
#> # A tibble: 10 × 2
#>    physical_state     n
#>    <chr>          <int>
#>  1 <NA>             139
#>  2 BC                49
#>  3 AB                26
#>  4 ON                19
#>  5 YT                12
#>  6 SK                 5
#>  7 QC                 4
#>  8 MB                 3
#>  9 NS                 2
#> 10 NB                 1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
norm_city <- akl %>% 
  distinct(city = physical_city, state = physical_state, zip_norm) %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("AK", "DC", "ALASKA"),
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
      "state" = "state",
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
akl <- left_join(
  x = akl,
  y = norm_city,
  by = c(
    "physical_city" = "city_raw", 
    "physical_state" = "state", 
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
good_refine <- akl %>% 
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
      "physical_state" = "state",
      "zip_norm" = "zip"
    )
  )
```

    #> # A tibble: 18 × 5
    #>    physical_state zip_norm city_swap           city_refine       n
    #>    <chr>          <chr>    <chr>               <chr>         <int>
    #>  1 AK             99901    AK KETCHIKAN        KETCHIKAN         3
    #>  2 AK             99623    WASILLAWASILLA      WASILLA           2
    #>  3 AK             99707    FAIRBANKSAK         FAIRBANKS         2
    #>  4 AK             99517    ANCHORAGEANCHORAGE  ANCHORAGE         1
    #>  5 AK             99518    ANCHORAGE ANCHORAGE ANCHORAGE         1
    #>  6 AK             99610    KASOLIF             KASILOF           1
    #>  7 AK             99611    KENAI AK            KENAI             1
    #>  8 AK             99635    NINKSKI             NIKISKI           1
    #>  9 AK             99645    PALERM              PALMER            1
    #> 10 AK             99652    BIG LAKE AK         BIG LAKE          1
    #> 11 AK             99701    FAIRBANKS AK        FAIRBANKS         1
    #> 12 AK             99701    FAIRBANKSAK         FAIRBANKS         1
    #> 13 AK             99709    FAIRBANKS FAI       FAIRBANKS         1
    #> 14 AK             99709    FAIRBANKSBANKS      FAIRBANKS         1
    #> 15 AK             99801    JUNEAU A            JUNEAU            1
    #> 16 AK             99901    KETCHIKAN/AK        KETCHIKAN         1
    #> 17 CA             94122    SAN FRANCISCO CA    SAN FRANCISCO     1
    #> 18 OH             45249    CINCINATTI          CINCINNATI        1

Then we can join the refined values back to the database.

``` r
akl <- akl %>% 
  left_join(good_refine, by = names(.)) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

Our goal for normalization was to increase the proportion of city values
known to be valid and reduce the total distinct values by correcting
misspellings.

``` r
many_city <- c(valid_city, extra_city)
akl %>% 
  count(city_refine, sort = TRUE) %>% 
  filter(city_refine %out% many_city)
#> # A tibble: 454 × 2
#>    city_refine      n
#>    <chr>        <int>
#>  1 AK             500
#>  2 JBER           139
#>  3 FRITZ CREEK     62
#>  4 <NA>            60
#>  5 MCCARTHY        49
#>  6 CHICKALOON      34
#>  7 BIRD CREEK      26
#>  8 UTQIAGVIK       26
#>  9 HALIBUT COVE    24
#> 10 EDNA BAY        20
#> # … with 444 more rows
```

| stage                             | prop_in | n_distinct | prop_na | n_out | n_diff |
|:----------------------------------|--------:|-----------:|--------:|------:|-------:|
| `str_to_upper(akl$physical_city)` |   0.971 |       3275 |   0.000 |  2882 |    958 |
| `akl$city_norm`                   |   0.975 |       3101 |   0.001 |  2496 |    773 |
| `akl$city_swap`                   |   0.982 |       2821 |   0.001 |  1781 |    471 |
| `akl$city_refine`                 |   0.982 |       2804 |   0.001 |  1759 |    454 |

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
akl <- akl %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  rename_all(~str_remove(., "_raw")) %>% 
  relocate(address_clean, city_clean, .before = zip_clean)
```

## Conclude

``` r
glimpse(sample_n(akl, 1000))
#> Rows: 1,000
#> Columns: 25
#> $ owners           <chr> "Dennis Vecera", "Chelsea Ballard", "LISA CARLON", "Sultan Insurance Services, LLC", "Chad La…
#> $ license_number   <chr> "2116018", "2091429", "936471", "2157540", "2121930", "2121148", "2128539", "147878", "215802…
#> $ business_name    <chr> "Salty Nut Publishing", "Chelsea Ballard", "GLASS-NOST", "M.J. Hall & Company Insurance Broke…
#> $ status           <chr> "Active", "Active", "Active", "Active", "Active", "Active", "Active", "Active", "Active", "Ac…
#> $ issue_date       <date> 2020-10-20, 2019-08-19, 2009-11-30, 2022-05-24, 2021-01-13, 2021-01-05, 2021-04-01, 1992-02-…
#> $ renew_date       <date> 2021-10-04, 2020-12-30, 2020-12-28, NA, NA, NA, NA, 2022-02-28, NA, 2020-12-07, 2021-10-27, …
#> $ expire_date      <date> 2023-12-31, 2022-12-31, 2022-12-31, 2023-12-31, 2022-12-31, 2022-12-31, 2022-12-31, 2023-12-…
#> $ physical_city    <chr> "Anchorage", "Big Lake", "Soldotna", "Stockton", "Fairbanks", "Fairbanks", "Palmer", "ANCHORA…
#> $ physical_country <chr> "UNITED STATES", "UNITED STATES", "UNITED STATES", "UNITED STATES", "UNITED STATES", "UNITED …
#> $ physical_line1   <chr> "3000 Dawson Street", "722 S. Melozzi HotSprings Rd", "46285 Roosevelt Circle", "1550 W. Frem…
#> $ physical_line2   <chr> NA, NA, "9072620894", NA, NA, NA, NA, NA, NA, NA, NA, "8002433839", NA, NA, NA, NA, NA, NA, N…
#> $ physical_state   <chr> "AK", "AK", "AK", "CA", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "FL", "AK", "MO", "AK", "AK…
#> $ physical_zip_out <chr> "99503", "99654", "99669-1941", "95203", "99712", "99709", "99645", "99501", "99723", "99645"…
#> $ mailing_city     <chr> "Anchorage", "wasilla", "SOLDOTNA", "Grand Rapids", "Fairbanks", "Fairbanks", "Palmer", "ANCH…
#> $ mailing_country  <chr> "UNITED STATES", "UNITED STATES", "UNITED STATES", "UNITED STATES", "UNITED STATES", "UNITED …
#> $ mailing_line1    <chr> "3000 Dawson Street", "7362 w parks highway #746", "PO BOX 1941", "100 Ottawa Avenue SW", "13…
#> $ mailing_line2    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "ATTN: FACILITIES DEVELOPMENT", NA, NA, NA, NA, N…
#> $ mailing_state    <chr> "AK", "AK", "AK", "MI", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "FL", "AK", "MO", "AK", "AK…
#> $ mailing_zip_out  <chr> "99503", "99654", "99669-1941", "49504", "99712", "99709", "99645", "99501", "99723", "99654-…
#> $ na_flag          <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FA…
#> $ dupe_flag        <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FA…
#> $ issue_year       <dbl> 2020, 2019, 2009, 2022, 2021, 2021, 2021, 1992, 2022, 2015, 2010, 1998, 2022, 2011, 2021, 200…
#> $ address_clean    <chr> "3000 DAWSON ST", "722 S MELOZZI HOTSPRINGS RD", "46285 ROOSEVELT CIR 9072620894", "1550 W FR…
#> $ city_clean       <chr> "ANCHORAGE", "BIG LAKE", "SOLDOTNA", "STOCKTON", "FAIRBANKS", "FAIRBANKS", "PALMER", "ANCHORA…
#> $ zip_clean        <chr> "99503", "99654", "99669", "95203", "99712", "99709", "99645", "99501", "99723", "99645", "99…
```

1.  There are 99,030 records in the database.
2.  There are 198 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 1,720 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server. We will name the object using a date range of the records
included.

``` r
clean_dir <- dir_create(here("state", "ak", "businesses", "data", "clean"))
clean_ts <- str_remove_all(Sys.Date(), '-')
clean_csv <- path(clean_dir, glue("ak_businesses_{clean_ts}.csv"))
clean_rds <- path_ext_set(clean_csv, "rds")
basename(clean_csv)
#> [1] "ak_businesses_20220624.csv"
```

``` r
write_csv(akl, clean_csv, na = "")
write_rds(akl, clean_rds, compress = "xz")
(clean_size <- file_size(clean_csv))
#> 23.5M
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
