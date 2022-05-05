Connecticut Licenses
================
Kiernan Nicholls
Thu May 5 15:15:11 2022

-   <a href="#project" id="toc-project">Project</a>
-   <a href="#objectives" id="toc-objectives">Objectives</a>
-   <a href="#packages" id="toc-packages">Packages</a>
-   <a href="#source" id="toc-source">Source</a>
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
  jsonlite, # read json data
  gluedown, # printing markdown
  janitor, # clean data frames
  campfin, # custom irw tools
  aws.s3, # aws cloud storage
  refinr, # cluster & merge
  scales, # format strings
  knitr, # knit documents
  vroom, # fast reading
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
here::i_am("state/ct/licenses/docs/ct_licenses_diary.Rmd")
```

## Source

We can obtain Connecticut licenses data from the state’s [open data
portal](https://data.ct.gov/Business/State-Licenses-and-Credentials/ngch-56tr).
The data is published from the Department of Consumer Protection.

> Licenses and Credentials recorded in Connecticut’s eLicensing system.

The dataset was created on April 23, 2015 and is updated daily.

| position | name                  | dataTypeName  |
|---------:|:----------------------|:--------------|
|        1 | CredentialId          | number        |
|        2 | Name                  | text          |
|        3 | Type                  | text          |
|        4 | BusinessName          | text          |
|        5 | DBA                   | text          |
|        6 | FullCredentialCode    | text          |
|        7 | CredentialType        | text          |
|        8 | CredentialNumber      | text          |
|        9 | CredentialSubCategory | text          |
|       10 | Credential            | text          |
|       11 | Status                | text          |
|       12 | StatusReason          | text          |
|       13 | Active                | number        |
|       14 | IssueDate             | calendar_date |
|       15 | EffectiveDate         | calendar_date |
|       16 | ExpirationDate        | calendar_date |
|       17 | Address               | text          |
|       18 | City                  | text          |
|       19 | State                 | text          |
|       20 | Zip                   | text          |
|       21 | RecordRefreshedOn     | calendar_date |

## Download

``` r
raw_url <- "https://data.ct.gov/api/views/ngch-56tr/rows.tsv"
raw_dir <- dir_create(here("state", "ct", "licenses", "data", "raw"))
raw_csv <- path(raw_dir, basename(raw_url))
```

``` r
if (!file_exists(raw_csv)) {
  GET(
    url = raw_url,
    body = list(accessType = "DOWNLOAD"),
    write_disk(raw_csv),
    progress("down")
  )
}
```

## Read

``` r
ctl <- read_tsv(
  file = raw_csv,
  locale = locale(date_format = "%m/%d/%Y"),
  col_types = cols(
    .default = col_character(),
    Active = col_logical(),
    IssueDate = col_date(),
    EffectiveDate = col_date(),
    ExpirationDate= col_date()
  )
)
```

``` r
ctl <- clean_names(ctl, case = "snake")
```

## Explore

There are 2,128,738 rows of 21 columns. Each record represents a single
license or credential.

``` r
glimpse(ctl)
#> Rows: 2,128,738
#> Columns: 21
#> $ credential_id           <chr> "10", "100", "1000", "10000", "100000", "1000000", "1000001", "1000002", "1000004", "1…
#> $ name                    <chr> "SEMYON RODKIN", "RAILROAD SALVAGE OF CT INC", "ROBERT MCMAHON JR", "CHARLES L DAVENPO…
#> $ type                    <chr> "INDIVIDUAL", "CORPORATION", "INDIVIDUAL", "INDIVIDUAL", "INDIVIDUAL", "INDIVIDUAL", "…
#> $ business_name           <chr> NA, "RAILROAD SALVAGE OF CT INC", NA, "JAMES L PUTNAM", NA, NA, NA, NA, NA, NA, NA, NA…
#> $ dba                     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ full_credential_code    <chr> "PEN.0018966", "PME.0003731", "RCG.0000413", "HIC.0512350", "ELC.0012234-E2", "90.0122…
#> $ credential_type         <chr> "PEN", "PME", "RCG", "HIC", "ELC", "90", "70", "70", "90", "65", "91", "65", "65", "91…
#> $ credential_number       <chr> "18966", "3731", "413", "512350", "12234", "12240", "13732", "13733", "12241", "3351",…
#> $ credential_sub_category <chr> NA, NA, NA, NA, "E2", NA, NA, NA, NA, NA, NA, NA, NA, NA, "E2", NA, NA, NA, NA, NA, NA…
#> $ credential              <chr> "PROFESSIONAL ENGINEER", "NON LEGEND DRUG PERMIT", "CERTIFIED GENERAL REAL ESTATE APPR…
#> $ status                  <chr> "INACTIVE", "INACTIVE", "INACTIVE", "INACTIVE", "INACTIVE", "INACTIVE", "INACTIVE", "I…
#> $ status_reason           <chr> "FAILED TO RENEW", NA, NA, "EXPIRED MORE THAN 3 YEARS - MUST REAPPLY", NA, "LAPSED DUE…
#> $ active                  <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FA…
#> $ issue_date              <date> 1995-03-13, NA, NA, NA, NA, 2011-05-31, 2011-06-09, 2011-06-09, 2011-05-31, 2011-06-0…
#> $ effective_date          <date> 2007-02-01, NA, 1995-05-01, 2005-12-01, NA, 2014-04-01, 2011-06-09, 2013-08-05, 2011-…
#> $ expiration_date         <date> 2008-01-31, 1995-12-31, 1995-04-30, 2006-11-30, NA, 2015-04-30, 2014-03-31, 2016-12-3…
#> $ address                 <chr> "214 WEST 29TH ST", "70 BRITANNIA ST", "40 Birchwood Heights Road", "34 SHERRY DR", "8…
#> $ city                    <chr> "NEW YORK", "MERIDEN", "Storrs", "SOUTHINGTON", "GROTON", "LAWRENCE", "NORWALK", "SIMS…
#> $ state                   <chr> "NY", "CT", "CT", "CT", "CT", "MA", "CT", "CT", "NY", "CT", "CT", "CT", "CT", "CT", "C…
#> $ zip                     <chr> "10001", "06450", "06268", "06489", "06340", "018431043", "068552011", "060702487", "1…
#> $ record_refreshed_on     <chr> "06/23/2009", "04/23/2004", "02/05/2009", "08/16/2018", "04/23/2004", "08/05/2015", "0…
tail(ctl)
#> # A tibble: 6 × 21
#>   credential_id name        type  business_name dba   full_credential… credential_type credential_numb… credential_sub_…
#>   <chr>         <chr>       <chr> <chr>         <chr> <chr>            <chr>           <chr>            <chr>           
#> 1 998767        BRITTANY W… INDI… <NA>          <NA>  14.009117        14              9117             <NA>            
#> 2 999018        JACQUELINE… INDI… <NA>          <NA>  10.100923        10              100923           <NA>            
#> 3 999280        HAO-CHEN H… INDI… <NA>          <NA>  PEN.0028341      PEN             28341            <NA>            
#> 4 999302        JAN A GEOT… INDI… <NA>          <NA>  10.099997        10              99997            <NA>            
#> 5 999409        ARMANDO MA… INDI… <NA>          <NA>  90.012283        90              12283            <NA>            
#> 6 999771        NICOLE A P… INDI… <NA>          <NA>  10.100897        10              100897           <NA>            
#> # … with 12 more variables: credential <chr>, status <chr>, status_reason <chr>, active <lgl>, issue_date <date>,
#> #   effective_date <date>, expiration_date <date>, address <chr>, city <chr>, state <chr>, zip <chr>,
#> #   record_refreshed_on <chr>
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(ctl, count_na)
#> # A tibble: 21 × 4
#>    col                     class        n           p
#>    <chr>                   <chr>    <int>       <dbl>
#>  1 credential_id           <chr>        0 0          
#>  2 name                    <chr>       67 0.0000315  
#>  3 type                    <chr>        0 0          
#>  4 business_name           <chr>  1544954 0.726      
#>  5 dba                     <chr>  1970979 0.926      
#>  6 full_credential_code    <chr>        1 0.000000470
#>  7 credential_type         <chr>        0 0          
#>  8 credential_number       <chr>    51656 0.0243     
#>  9 credential_sub_category <chr>  1896260 0.891      
#> 10 credential              <chr>        0 0          
#> 11 status                  <chr>        0 0          
#> 12 status_reason           <chr>   610065 0.287      
#> 13 active                  <lgl>        0 0          
#> 14 issue_date              <date>  462974 0.217      
#> 15 effective_date          <date>  218765 0.103      
#> 16 expiration_date         <date>  250034 0.117      
#> 17 address                 <chr>     8343 0.00392    
#> 18 city                    <chr>     8207 0.00386    
#> 19 state                   <chr>    12980 0.00610    
#> 20 zip                     <chr>    11986 0.00563    
#> 21 record_refreshed_on     <chr>        0 0
```

We can flag any record missing a key variable needed to identify a
transaction.

``` r
ctl <- flag_na(ctl, "name")
sum(ctl$na_flag)
#> [1] 67
```

``` r
ctl %>% 
  filter(na_flag) %>% 
  select(name, credential, effective_date, address)
#> # A tibble: 67 × 4
#>    name  credential             effective_date address                       
#>    <chr> <chr>                  <date>         <chr>                         
#>  1 <NA>  AIRLINE LIQUOR         2011-09-21     BRADLEY INT'L AIRPORT         
#>  2 <NA>  NON LEGEND DRUG PERMIT 2011-08-31     361 NEW PARK AVE              
#>  3 <NA>  LIQUOR BRAND LABEL     1998-06-22     CONNECTICUT BRAND REGISTRATION
#>  4 <NA>  LIQUOR BRAND LABEL     1997-12-11     CONNECTICUT BRAND REGISTRATION
#>  5 <NA>  LIQUOR BRAND LABEL     2000-08-30     CONNECTICUT BRAND REGISTRATION
#>  6 <NA>  LIQUOR BRAND LABEL     1998-05-14     CONNECTICUT BRAND REGISTRATION
#>  7 <NA>  LIQUOR BRAND LABEL     1998-04-22     CONNECTICUT BRAND REGISTRATION
#>  8 <NA>  LIQUOR BRAND LABEL     2001-02-13     CONNECTICUT BRAND REGISTRATION
#>  9 <NA>  LIQUOR BRAND LABEL     2001-02-05     CONNECTICUT BRAND REGISTRATION
#> 10 <NA>  LIQUOR BRAND LABEL     NA             CONNECTICUT BRAND REGISTRATION
#> # … with 57 more rows
```

### Duplicates

We can also flag any record completely duplicated across every column.

``` r
ctl <- flag_dupes(ctl, -credential_id)
sum(ctl$dupe_flag)
#> [1] 194
```

``` r
ctl %>% 
  filter(dupe_flag) %>% 
  select(name, credential, effective_date, address) %>% 
  arrange(effective_date)
#> # A tibble: 194 × 4
#>    name                    credential                                       effective_date address                      
#>    <chr>                   <chr>                                            <date>         <chr>                        
#>  1 SONIA V MEHTA           Speech and Language Pathologist Temporary Permit 2015-02-23     230 MURRAY LN                
#>  2 SONIA V MEHTA           Speech and Language Pathologist Temporary Permit 2015-02-23     230 MURRAY LN                
#>  3 ALICIA A BERG           Hairdresser/Cosmetician                          NA             30 West Chestnut Street      
#>  4 ALICIA A BERG           Hairdresser/Cosmetician                          NA             30 West Chestnut Street      
#>  5 MARIA GARCIA            Hairdresser/Cosmetician                          NA             108 Hawthorne Dr North Apt 2f
#>  6 MARIA GARCIA            Hairdresser/Cosmetician                          NA             108 Hawthorne Dr North Apt 2f
#>  7 ANDREA MARTINEZ         Hairdresser/Cosmetician                          NA             54 HILLCREST PARK RD         
#>  8 ANDREA MARTINEZ         Hairdresser/Cosmetician                          NA             54 HILLCREST PARK RD         
#>  9 SHANNON M SMIRNOW CLARK Emergency Medical Technician                     NA             412 Allegheny Way, Apt. 102  
#> 10 SHANNON M SMIRNOW CLARK Emergency Medical Technician                     NA             412 Allegheny Way, Apt. 102  
#> # … with 184 more rows
```

Almost all “duplicate” licenses are missing an `effective_date`,
indicating they could just be repeat submissions.

``` r
prop_na(ctl$effective_date[ctl$dupe_flag])
#> [1] 0.9896907
```

### Categorical

``` r
col_stats(ctl, n_distinct)
#> # A tibble: 23 × 4
#>    col                     class        n           p
#>    <chr>                   <chr>    <int>       <dbl>
#>  1 credential_id           <chr>  2128738 1          
#>  2 name                    <chr>  1611603 0.757      
#>  3 type                    <chr>       22 0.0000103  
#>  4 business_name           <chr>   450793 0.212      
#>  5 dba                     <chr>   106077 0.0498     
#>  6 full_credential_code    <chr>  2076369 0.975      
#>  7 credential_type         <chr>      472 0.000222   
#>  8 credential_number       <chr>   692922 0.326      
#>  9 credential_sub_category <chr>      177 0.0000831  
#> 10 credential              <chr>      599 0.000281   
#> 11 status                  <chr>       19 0.00000893 
#> 12 status_reason           <chr>      245 0.000115   
#> 13 active                  <lgl>        2 0.000000940
#> 14 issue_date              <date>   26525 0.0125     
#> 15 effective_date          <date>   18970 0.00891    
#> 16 expiration_date         <date>   13034 0.00612    
#> 17 address                 <chr>  1153015 0.542      
#> 18 city                    <chr>    33873 0.0159     
#> 19 state                   <chr>      146 0.0000686  
#> 20 zip                     <chr>   335806 0.158      
#> 21 record_refreshed_on     <chr>     5532 0.00260    
#> 22 na_flag                 <lgl>        2 0.000000940
#> 23 dupe_flag               <lgl>        2 0.000000940
```

![](../plots/distinct-plots-1.png)<!-- -->![](../plots/distinct-plots-2.png)<!-- -->![](../plots/distinct-plots-3.png)<!-- -->![](../plots/distinct-plots-4.png)<!-- -->

### Dates

``` r
min(ctl$effective_date, na.rm = TRUE)
#> [1] "1800-12-27"
max(ctl$effective_date, na.rm = TRUE)
#> [1] "2025-09-30"
```

There are many licenses with an `effective_date` of December 27, 1800.
This is most likely a default or minimum date, perhaps one entered for
those with existing licenses when the system was created.

``` r
sum(ctl$effective_date == "1800-12-27", na.rm = TRUE)
#> [1] 1092
```

We will make these dates invalid entries.

``` r
ctl$effective_date[ctl$effective_date < "1900-01-01"] <- NA
```

We can add the calendar year from `date` with `lubridate::year()`

``` r
ctl <- mutate(ctl, effective_year = year(effective_date))
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
addr_norm <- ctl %>% 
  distinct(address) %>% 
  mutate(
    address_norm = normal_address(
      address = address,
      abbs = usps_street,
      na_rep = TRUE
    )
  )
```

``` r
addr_norm
#> # A tibble: 1,153,015 × 2
#>    address                   address_norm           
#>    <chr>                     <chr>                  
#>  1 214 WEST 29TH ST          214 WEST 29TH ST       
#>  2 70 BRITANNIA ST           70 BRITANNIA ST        
#>  3 40 Birchwood Heights Road 40 BIRCHWOOD HEIGHTS RD
#>  4 34 SHERRY DR              34 SHERRY DR           
#>  5 84 BUDDINGTON RD #4       84 BUDDINGTON RD #4    
#>  6 2 ANDOVER TER             2 ANDOVER TER          
#>  7 18 LUDLOW MNR             18 LUDLOW MNR          
#>  8 1 CANDLEWOOD CT           1 CANDLEWOOD CT        
#>  9 88 RENNERT LN             88 RENNERT LN          
#> 10 722 TOWER AVE             722 TOWER AVE          
#> # … with 1,153,005 more rows
```

``` r
ctl <- left_join(ctl, addr_norm, by = "address")
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
ctl <- ctl %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  ctl$zip,
  ctl$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 × 6
#>   stage        prop_in n_distinct prop_na  n_out n_diff
#>   <chr>          <dbl>      <dbl>   <dbl>  <dbl>  <dbl>
#> 1 ctl$zip        0.608     335806 0.00563 829549 318015
#> 2 ctl$zip_norm   0.988      25485 0.00625  25965   3972
```

### State

All of the invalid `state` values seem to be foreign with a `zip` code
value not matching any US code with a similar corresponding state.

``` r
ctl |> 
  filter(state %out% valid_state) |> 
  count(state_raw = state, zip_norm, sort = TRUE) |> 
  add_prop(sum = TRUE) |> 
  left_join(
    y = zipcodes,
    by = c("zip_norm" = "zip")
  )
#> # A tibble: 5,386 × 6
#>    state_raw zip_norm     n     p city     state
#>    <chr>     <chr>    <int> <dbl> <chr>    <chr>
#>  1 <NA>      <NA>      7579 0.357 <NA>     <NA> 
#>  2 PH        1634       403 0.376 <NA>     <NA> 
#>  3 CH        <NA>       277 0.389 <NA>     <NA> 
#>  4 OC        <NA>       154 0.396 <NA>     <NA> 
#>  5 PH        1605       120 0.402 <NA>     <NA> 
#>  6 VN        <NA>       104 0.407 <NA>     <NA> 
#>  7 CY        <NA>        92 0.411 <NA>     <NA> 
#>  8 I2        20130       90 0.415 PARIS    VA   
#>  9 <NA>      010         90 0.419 <NA>     <NA> 
#> 10 I2        13210       75 0.423 SYRACUSE NY   
#> # … with 5,376 more rows
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
norm_city <- ctl %>% 
  distinct(city, state, zip_norm) %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("CT", "DC", "CONNECTICUT"),
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
ctl <- left_join(
  x = ctl,
  y = norm_city,
  by = c(
    "city" = "city_raw", 
    "state", 
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
good_refine <- ctl %>% 
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
      "state" = "state",
      "zip_norm" = "zip"
    )
  )
```

    #> # A tibble: 124 × 5
    #>    state zip_norm city_swap        city_refine          n
    #>    <chr> <chr>    <chr>            <chr>            <int>
    #>  1 WV    25303    SO CHARLESTON    CHARLESTON          56
    #>  2 NY    11733    SETAUKET         EAST SETAUKET       50
    #>  3 IL    60606    CHIGACO          CHICAGO             18
    #>  4 MA    01060    NORTH HAMPTON    NORTHAMPTON         16
    #>  5 CT    06081    TARRIFVILLE      TARIFFVILLE         11
    #>  6 SC    29406    NORTH CHARLESTON CHARLESTON          11
    #>  7 RI    02904    NO PROVIDENCE    PROVIDENCE           7
    #>  8 MA    01073    SOUTH HAMPTON    SOUTHAMPTON          6
    #>  9 CA    92879    CORONA CA        CORONA               4
    #> 10 NY    10520    CROTON/HUDSON    CROTON ON HUDSON     4
    #> # … with 114 more rows

Then we can join the refined values back to the database.

``` r
ctl <- ctl %>% 
  left_join(good_refine, by = names(.)) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

Our goal for normalization was to increase the proportion of city values
known to be valid and reduce the total distinct values by correcting
misspellings.

| stage                    | prop_in | n_distinct | prop_na | n_out | n_diff |
|:-------------------------|--------:|-----------:|--------:|------:|-------:|
| `str_to_upper(ctl$city)` |   0.976 |      25147 |   0.004 | 50751 |  14617 |
| `ctl$city_norm`          |   0.982 |      22540 |   0.004 | 38450 |  11967 |
| `ctl$city_swap`          |   0.988 |      18913 |   0.004 | 25424 |   8299 |
| `ctl$city_refine`        |   0.988 |      18806 |   0.004 | 25132 |   8192 |

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
ctl <- ctl %>% 
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
glimpse(sample_n(ctl, 1000))
#> Rows: 1,000
#> Columns: 27
#> $ credential_id           <chr> "2176436", "1769586", "975106", "1165432", "2137296", "789141", "479295", "445369", "7…
#> $ name                    <chr> "JUSTIN MACDOUGALL", "Franklin Fund Allocator Series", "STEVEN WALLACH", "MICHELLE M W…
#> $ type                    <chr> "INDIVIDUAL", "BUSINESS", "INDIVIDUAL", "INDIVIDUAL", "BUSINESS", "INDIVIDUAL", "INDIV…
#> $ business_name           <chr> NA, "Franklin Fund Allocator Series", NA, NA, "SYNGENTA CROP PROTECTION. LLC", NA, NA,…
#> $ dba                     <chr> NA, NA, "STEVEN WALLACH LANDSCAPES", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ full_credential_code    <chr> "PMCO.0044203", "ICOE.1091084", "HIC.0628899", "PCT.0012706", "PMPR.0010223", "8.00065…
#> $ credential_type         <chr> "PMCO", "ICOE", "HIC", "PCT", "PMPR", "8", "CSP", "HIC", "20", "70", "HIS", "LBD", "10…
#> $ credential_number       <chr> "44203", "1091084", "628899", "12706", "10223", "657", "42234", "612113", "23090", "99…
#> $ credential_sub_category <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "RES", NA, NA, NA, NA, NA,…
#> $ credential              <chr> "Pesticide Commercial Operator Certification", "Investment Company - Open End", "HOME …
#> $ status                  <chr> "INACTIVE", "INACTIVE", "INACTIVE", "INACTIVE", "ACTIVE", "INACTIVE", "INACTIVE", "INA…
#> $ status_reason           <chr> "LAPSED RENEWAL", "TERMINATED", "EXPIRED MORE THAN 3 YEARS - MUST REAPPLY", NA, "REGIS…
#> $ active                  <lgl> FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ issue_date              <date> 2015-06-12, NA, 2010-11-12, 2013-09-05, NA, 1978-01-25, 2007-09-28, 2006-08-04, 1981-…
#> $ effective_date          <date> 2015-02-01, 2019-12-31, 2014-12-01, 2016-02-01, 2021-01-01, 2018-11-01, 2008-03-01, 2…
#> $ expiration_date         <date> 2020-01-31, 2020-08-14, 2015-11-30, 2018-01-31, 2025-12-31, 2019-10-31, 2009-02-28, 2…
#> $ address                 <chr> "501 PEPPER STREET", NA, "277 NEWFIELD ST", "10 MCGINNIS ST", "P O BOX 18300", "11 MEA…
#> $ city                    <chr> "MONROE", "SAN MATEO", "MIDDLETOWN", "EAST BRUNSWICK", "GREENSBORO", "GALES FERRY", "N…
#> $ state                   <chr> "CT", "CA", "CT", "NJ", "NC", "CT", "CT", "CT", "CT", "RI", "CT", "CT", "NC", "CT", "C…
#> $ zip                     <chr> "06468", "944031906", "064576473", "088162672", "274198300", "06335", "06513", "06786"…
#> $ record_refreshed_on     <chr> "02/14/2022", "09/08/2020", "12/04/2018", "01/01/2019", "01/04/2021", "02/03/2020", "0…
#> $ na_flag                 <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FA…
#> $ dupe_flag               <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FA…
#> $ effective_year          <dbl> 2015, 2019, 2014, 2016, 2021, 2018, 2008, 2008, 2016, 2005, 2020, 2019, 2013, 1994, NA…
#> $ address_clean           <chr> "501 PEPPER ST", NA, "277 NEWFIELD ST", "10 MCGINNIS ST", "P O BOX 18300", "11 MEADOW …
#> $ city_clean              <chr> "MONROE", "SAN MATEO", "MIDDLETOWN", "EAST BRUNSWICK", "GREENSBORO", "GALES FERRY", "N…
#> $ zip_clean               <chr> "06468", "94403", "06457", "08816", "27419", "06335", "06513", "06786", "06082", "0289…
```

1.  There are 2,128,738 records in the database.
2.  There are 194 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 67 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server. We will name the object using a date range of the records
included.

``` r
clean_dir <- dir_create(here("state", "ct", "licenses", "data", "clean"))
clean_csv <- path(clean_dir, glue("ct_licenses_19900101-20220505.csv"))
clean_rds <- path_ext_set(clean_csv, "rds")
basename(clean_csv)
#> [1] "ct_licenses_19900101-20220505.csv"
```

``` r
write_csv(ctl, clean_csv, na = "")
write_rds(ctl, clean_rds, compress = "xz")
(clean_size <- file_size(clean_csv))
#> 519M
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
