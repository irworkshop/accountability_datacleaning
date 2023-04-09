Colorado Lobbying Expenditure Data Diary
================
Yanqi Xu
2023-03-26 19:42:18

- <a href="#project" id="toc-project">Project</a>
- <a href="#objectives" id="toc-objectives">Objectives</a>
- <a href="#packages" id="toc-packages">Packages</a>
- <a href="#data" id="toc-data">Data</a>
- <a href="#import" id="toc-import">Import</a>
- <a href="#explore" id="toc-explore">Explore</a>
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
pacman::p_load_current_gh("irworkshop/campfin")
pacman::p_load(
  readxl, # read excel files
  rvest, # used to scrape website and get html elements
  tidyverse, # data manipulation
  stringdist, # calculate distances between strings
  lubridate, # datetime strings
  magrittr, # pipe opperators
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  httr, # http queries
  glue, # combine strings
  here, # relative storage
  fs # search storage 
)
```

This document should be run as part of the `R_campfin` project, which
lives as a sub-directory of the more general, language-agnostic
[`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning)
GitHub repository.

The `R_campfin` project uses the [Rstudio
projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects "Rproj")
feature and should be run as such. The project also uses the dynamic
`here::here()` tool for file paths relative to *your* machine.

``` r
# where does this document knit?
here::here()
#> [1] "/Users/yanqixu/code/accountability_datacleaning"
```

## Data

Lobbyist data is obtained from the [Colorado Open Data
Portal](https://data.colorado.gov/Lobbyist/Directory-of-Lobbyists-in-Colorado/bqa5-gr84).
The data is as current as March 26, 2023.

> About:  
> Information for each registered lobbyist, including contact details,
> and their associated income and expenses as summarized by month and
> associated report date for the State of Colorado dating back to 1995
> provided by the Colorado Department of State (CDOS).

## Import

### Setting up Raw Data Directory

``` r
raw_dir <- dir_create(here("state","co", "lobby", "data", "raw", "exp"))
```

### Download from web

``` r
summary_url <- 'https://data.colorado.gov/api/views/bqa5-gr84/rows.csv?accessType=DOWNLOAD'
exp_url <- 'https://data.colorado.gov/api/views/eqsm-7ah7/rows.csv?accessType=DOWNLOAD'
  
urls <- c(summary_url, exp_url)
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

if (!all_files_new(raw_dir)) {
  map(urls, wget, raw_dir)
}
```

### Read

> Description:  
> Expenses and income summarized by month associated with lobbying
> activities. In a reporting month, income is reported based on the date
> that it is actually received. For example, in the event that a payment
> is made cumulatively over a three month period, they must report the
> full three month payment when the payment was received. If a lobbyist
> has multiple payments received by various clients, each dollar amount
> is reported separately by each client. If a lobbyist receives multiple
> payments on multiple bills from a single client, the monthly income
> report will be the total of what the client is paying the lobbyist for
> all of lobbying activities on the multiple bills. The statute
> specifies that lobbyists report the total amount they receive from the
> client, so in some cases the monthly dollar amount reported by a
> lobbyist is the total amount received may reflect a payment paid for a
> number of bills and activities. The payments are not itemized by bills
> or activities. In this dataset income is summarized by month.

> Each row represents: Lobbyist name, id, address, and income and
> expense by month

According to Colorado data portal, this dataset can be joined to: \>
Bill Information and Position with Income of Lobbyist in Colorado,
Characterization of Lobbyist Clients in Colorado, Directory of Lobbyist
Clients in Colorado, Expenses for Lobbyists in Colorado, Subcontractors
for Lobbyists in Colorado based on “primaryLobbyistId”

``` r
cole <- read_csv(dir_ls(raw_dir, regexp = "Directory.+"), 
                 col_types = cols(.default = col_character())) %>% 
  clean_names()

co_exp <- read_csv(dir_ls(raw_dir, regexp = "Expenses.+"), 
                 col_types = cols(.default = col_character())) %>% 
  clean_names()
```

## Explore

``` r
head(cole)
#> # A tibble: 6 × 18
#>   lobbyis…¹ lobby…² lobby…³ lobby…⁴ lobby…⁵ lobby…⁶ lobby…⁷ offic…⁸ prima…⁹ annua…˟ date_…˟ date_…˟
#>   <chr>     <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>  
#> 1 Jim Dris… James   8396 E… <NA>    Denver  CO      80238   <NA>    201750… 202250… <NA>    <NA>   
#> 2 Olson     Emilie  1010 V… <NA>    Washin… DC      20005   <NA>    201950… 202150… 04/04/… 04/04/…
#> 3 Wallace   Rebecca PO Box… <NA>    Denver  CO      80206   <NA>    202150… 202150… 04/09/… 04/09/…
#> 4 Staberg   Christ… 1580 L… <NA>    DENVER  CO      80203   <NA>    200350… 201050… 11/05/… 11/05/…
#> 5 Adelson   Shawnee 1616 1… <NA>    Denver  CO      80202   <NA>    202050… 202150… 04/07/… 04/07/…
#> 6 BARRETT   JOHN    10513 … <NA>    AUSTIN  TX      78759   <NA>    200750… 202150… 04/04/… 04/04/…
#> # … with 6 more variables: business_associated_with_pending_legislation <chr>,
#> #   total_monthly_income <chr>, total_monthly_expenses <chr>, report_month <chr>,
#> #   fiscal_year <chr>, report_due_date <chr>, and abbreviated variable names ¹​lobbyist_last_name,
#> #   ²​lobbyist_first_name, ³​lobbyist_address1, ⁴​lobbyist_address2, ⁵​lobbyist_city, ⁶​lobbyist_state,
#> #   ⁷​lobbyist_zip, ⁸​official_state_lobbyist, ⁹​primary_lobbyist_id,
#> #   ˟​annual_lobbyist_registration_id, ˟​date_disclosure_filed, ˟​date_disclosure_last_modified
tail(cole)
#> # A tibble: 6 × 18
#>   lobbyis…¹ lobby…² lobby…³ lobby…⁴ lobby…⁵ lobby…⁶ lobby…⁷ offic…⁸ prima…⁹ annua…˟ date_…˟ date_…˟
#>   <chr>     <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>  
#> 1 Mallory   Jesse   789 Sh… <NA>    Denver  CO      80203   <NA>    201750… 202250… <NA>    <NA>   
#> 2 Hunsaker  Shelbe  601 Ne… <NA>    Washin… DC      20001   <NA>    202150… 202250… 03/15/… 03/15/…
#> 3 Ehrett    Alexan… 532 Go… <NA>    Golden  CO      80401   <NA>    202250… 202250… 03/14/… 03/14/…
#> 4 Bailey    Grier   1410 G… <NA>    DENVER  CO      80203   <NA>    200750… 202250… 03/15/… 03/15/…
#> 5 Recht Ko… <NA>    1600 S… <NA>    Denver  CO      80202   <NA>    201950… 202250… 03/15/… 03/15/…
#> 6 Amaha     Naomi   1009 G… <NA>    Denver  CO      80203   <NA>    202250… 202250… 03/15/… 03/15/…
#> # … with 6 more variables: business_associated_with_pending_legislation <chr>,
#> #   total_monthly_income <chr>, total_monthly_expenses <chr>, report_month <chr>,
#> #   fiscal_year <chr>, report_due_date <chr>, and abbreviated variable names ¹​lobbyist_last_name,
#> #   ²​lobbyist_first_name, ³​lobbyist_address1, ⁴​lobbyist_address2, ⁵​lobbyist_city, ⁶​lobbyist_state,
#> #   ⁷​lobbyist_zip, ⁸​official_state_lobbyist, ⁹​primary_lobbyist_id,
#> #   ˟​annual_lobbyist_registration_id, ˟​date_disclosure_filed, ˟​date_disclosure_last_modified

head(co_exp)
#> # A tibble: 6 × 18
#>   lobbyis…¹ lobby…² lobby…³ lobby…⁴ lobby…⁵ lobby…⁶ lobby…⁷ prima…⁸ annua…⁹ offic…˟ expen…˟ expen…˟
#>   <chr>     <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>  
#> 1 WESTFALL  RICHARD <NA>    <NA>    <NA>    <NA>    <NA>    199670… 199670… N       NONE    0      
#> 2 YOUNG     LYNN    5345 U… <NA>    ARVADA  CO      80001   199070… 199770… N       NONE    0      
#> 3 YATES     ALBERT  102 AD… <NA>    FORT C… CO      80523-… 199770… 200070… Y       NONE    0      
#> 4 WILSON    GEOFFR… 1144 S… <NA>    DENVER  CO      80203   199070… 199870… N       NONE    0      
#> 5 WEIST     KELLY   9289 B… <NA>    CONIFER CO      80433   200170… 200170… N       NONE    0      
#> 6 WILLIAMS  GREGORY <NA>    <NA>    <NA>    <NA>    <NA>    199070… 199670… N       NONE    0      
#> # … with 6 more variables: expenditure_receipt_date <chr>, expenditure_purpose <chr>,
#> #   expenditure_for_media_flag <chr>, report_month <chr>, fiscal_year <chr>,
#> #   report_due_date <chr>, and abbreviated variable names ¹​lobbyist_last_name,
#> #   ²​lobbyist_first_name, ³​lobbyist_address1, ⁴​lobbyist_address2, ⁵​lobbyist_city, ⁶​lobbyist_state,
#> #   ⁷​lobbyist_zip, ⁸​primary_lobbyist_id, ⁹​annual_lobbyist_registration_id,
#> #   ˟​official_state_lobbyist, ˟​expenditure_name, ˟​expenditure_amount
tail(co_exp)
#> # A tibble: 6 × 18
#>   lobbyis…¹ lobby…² lobby…³ lobby…⁴ lobby…⁵ lobby…⁶ lobby…⁷ prima…⁸ annua…⁹ offic…˟ expen…˟ expen…˟
#>   <chr>     <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>  
#> 1 Castaneda Milena  789 Sh… #300    Denver  CO      80203   202350… 202350… N       Milena… 15.96  
#> 2 Colorado… <NA>    1144 S… <NA>    DENVER  CO      80203   200750… 202250… N       Heathe… 2703.43
#> 3 Couture-… Travis  11250 … c/o Of… Fairfax VA      22030   201550… 202250… N       Grassr… 286    
#> 4 Conventi… <NA>    7670 O… <NA>    San Di… CA      92111   202050… 202250… N       Printi… 15.7   
#> 5 Blumenfe… Austin  PO Box… <NA>    Denver  CO      80206   202250… 202250… N       <NA>    25000  
#> 6 Conventi… <NA>    7670 O… <NA>    San Di… CA      92111   202050… 202250… N       Social… 34.84  
#> # … with 6 more variables: expenditure_receipt_date <chr>, expenditure_purpose <chr>,
#> #   expenditure_for_media_flag <chr>, report_month <chr>, fiscal_year <chr>,
#> #   report_due_date <chr>, and abbreviated variable names ¹​lobbyist_last_name,
#> #   ²​lobbyist_first_name, ³​lobbyist_address1, ⁴​lobbyist_address2, ⁵​lobbyist_city, ⁶​lobbyist_state,
#> #   ⁷​lobbyist_zip, ⁸​primary_lobbyist_id, ⁹​annual_lobbyist_registration_id,
#> #   ˟​official_state_lobbyist, ˟​expenditure_name, ˟​expenditure_amount
```

### Missing

All records seem to be pretty complete.

``` r
col_stats(cole, count_na)
#> # A tibble: 18 × 4
#>    col                                          class      n      p
#>    <chr>                                        <chr>  <int>  <dbl>
#>  1 lobbyist_last_name                           <chr>      0 0     
#>  2 lobbyist_first_name                          <chr>   8630 0.0461
#>  3 lobbyist_address1                            <chr>  11568 0.0618
#>  4 lobbyist_address2                            <chr> 187254 1     
#>  5 lobbyist_city                                <chr>  11568 0.0618
#>  6 lobbyist_state                               <chr>  11568 0.0618
#>  7 lobbyist_zip                                 <chr>  11568 0.0618
#>  8 official_state_lobbyist                      <chr> 187254 1     
#>  9 primary_lobbyist_id                          <chr>      0 0     
#> 10 annual_lobbyist_registration_id              <chr>      0 0     
#> 11 date_disclosure_filed                        <chr>   3478 0.0186
#> 12 date_disclosure_last_modified                <chr>  48574 0.259 
#> 13 business_associated_with_pending_legislation <chr> 187053 0.999 
#> 14 total_monthly_income                         <chr>  74218 0.396 
#> 15 total_monthly_expenses                       <chr> 140178 0.749 
#> 16 report_month                                 <chr>      0 0     
#> 17 fiscal_year                                  <chr>      0 0     
#> 18 report_due_date                              <chr>      0 0
col_stats(co_exp, count_na)
#> # A tibble: 18 × 4
#>    col                             class     n       p
#>    <chr>                           <chr> <int>   <dbl>
#>  1 lobbyist_last_name              <chr>     0 0      
#>  2 lobbyist_first_name             <chr>  3253 0.0468 
#>  3 lobbyist_address1               <chr> 10082 0.145  
#>  4 lobbyist_address2               <chr> 57418 0.827  
#>  5 lobbyist_city                   <chr> 10082 0.145  
#>  6 lobbyist_state                  <chr> 10140 0.146  
#>  7 lobbyist_zip                    <chr> 10140 0.146  
#>  8 primary_lobbyist_id             <chr>   162 0.00233
#>  9 annual_lobbyist_registration_id <chr>   162 0.00233
#> 10 official_state_lobbyist         <chr>   162 0.00233
#> 11 expenditure_name                <chr>  4366 0.0629 
#> 12 expenditure_amount              <chr>   163 0.00235
#> 13 expenditure_receipt_date        <chr> 31708 0.456  
#> 14 expenditure_purpose             <chr> 49695 0.715  
#> 15 expenditure_for_media_flag      <chr>   220 0.00317
#> 16 report_month                    <chr>   220 0.00317
#> 17 fiscal_year                     <chr>   220 0.00317
#> 18 report_due_date                 <chr>   220 0.00317
```

We’ll flag records without lobbyists’ addresses.

``` r
cole <- cole %>% 
  flag_na(lobbyist_address1)

co_exp <- co_exp %>% 
  flag_na(lobbyist_address1, expenditure_amount)
```

### Duplicates

There isn’t any duplicate column.

``` r
cole <- flag_dupes(cole, dplyr::everything())
sum(cole$dupe_flag)
#> [1] 612

co_exp <- flag_dupes(co_exp, dplyr::everything())
sum(co_exp$dupe_flag)
#> [1] 1017
```

### Categorical

#### Dates

Since the dates are all read as characters, we will convert them back in
to date objects. We can add a year variable to the dataframe based on
the registration date.

After examining the results, we can clearly see that there’re some human
errors when entering the date.

``` r
cole <- cole%>% 
   mutate_at(.vars = vars(ends_with('date')), as.Date, format = "%m/%d/%Y %H:%M:%S %p") %>% 
   mutate(year = year(report_due_date))

co_exp <- co_exp%>% 
   mutate_at(.vars = vars(ends_with('date')), as.Date, format = "%m/%d/%Y %H:%M:%S %p") %>% 
   mutate(year = year(report_due_date))

min(co_exp$expenditure_receipt_date, na.rm = T)
#> [1] "0002-05-03"
max(co_exp$expenditure_receipt_date, na.rm = T)
#> [1] "4014-03-11"
```

#### Year

We can see the distribution of the `year` variable as such.

``` r
tabyl(co_exp$fiscal_year)
#> # A tibble: 30 × 4
#>    `co_exp$fiscal_year`     n percent valid_percent
#>    <chr>                <int>   <dbl>         <dbl>
#>  1 1995                  3743  0.0539        0.0541
#>  2 1996                  6855  0.0987        0.0990
#>  3 1997                  6898  0.0993        0.0996
#>  4 1998                  6784  0.0977        0.0980
#>  5 1999                  6252  0.0900        0.0903
#>  6 2000                  6535  0.0941        0.0944
#>  7 2001                  6475  0.0932        0.0935
#>  8 2002                  4080  0.0587        0.0589
#>  9 2003                  2751  0.0396        0.0397
#> 10 2004                  2797  0.0403        0.0404
#> # … with 20 more rows
```

![](../plots/year%20count-1.png)<!-- -->

### Continuous

We can examine the amounts in both the summary and the expenditure
database

``` r
cole <- cole %>% 
  mutate_at(.vars = vars(starts_with('total_monthly')), .funs = as.numeric)

co_exp <- co_exp %>% 
  mutate(expenditure_amount = as.numeric(expenditure_amount))

summary(cole$total_monthly_income)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
#>       0     580    2708    7419    7500  346923   74218
summary(cole$total_monthly_expenses)
#>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max.      NA's 
#>       0.0       0.0       0.0     995.4     112.1 2865427.0    140178

summary(co_exp$expenditure_amount)
#>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max.      NA's 
#>       0.0       0.0      10.3     676.2      93.5 2752833.5       163
```

### Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are taylor made to facilitate this process.

### Address

For the street `addresss` variable, the `campfin::normal_address()`
function will force consistence case, remove punctuation, and
abbreviation official USPS suffixes.

``` r
cole <- cole %>% 
    # combine street addr
  unite(
    col = lobbyist_address,
    starts_with("lobbyist_address"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  # normalize combined addr
    mutate(lobbyist_address_norm = normal_address(lobbyist_address,abbs = usps_street,
      na_rep = TRUE)) %>% 
  select(-ends_with("address"))

co_exp <- co_exp %>% 
    # combine street addr
  unite(
    col = lobbyist_address,
    starts_with("lobbyist_address"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  # normalize combined addr
    mutate(lobbyist_address_norm = normal_address(lobbyist_address,abbs = usps_street,
      na_rep = TRUE)) %>% 
  select(-ends_with("address"))
```

``` r
cole %>% 
  select(contains("address")) %>% 
  distinct() %>% 
  sample_n(10) %>% 
  glimpse()
#> Rows: 10
#> Columns: 3
#> $ lobbyist_address1     <chr> "3333 S. BANNOCK ST", "7606 N Union Blvd", "350 KIMBARK ST", "P.O. …
#> $ lobbyist_address2     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
#> $ lobbyist_address_norm <chr> "3333 S BANNOCK ST", "7606 N UNION BLVD", "350 KIMBARK ST", "PO BOX…

co_exp %>% 
  select(contains("address")) %>% 
  distinct() %>% 
  sample_n(10) %>% 
  glimpse()
#> Rows: 10
#> Columns: 3
#> $ lobbyist_address1     <chr> "4676 Broadway", "1580 Logan Street", "1597 COLE BLVD STE 310", "30…
#> $ lobbyist_address2     <chr> NA, "Suite 510", NA, "Suite 400", NA, NA, NA, "Suite B206", NA, NA
#> $ lobbyist_address_norm <chr> "4676 BROADWAY", "1580 LOGAN STREET SUITE 510", "1597 COLE BLVD STE…
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valied *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
cole <- cole %>% 
    mutate(lobbyist_zip_norm = normal_zip(lobbyist_zip, na_rep = T)) %>% 
  rename(lobbyist_zip5 = lobbyist_zip_norm)

co_exp <- co_exp %>% 
    mutate(lobbyist_zip_norm = normal_zip(lobbyist_zip, na_rep = T)) %>% 
  rename(lobbyist_zip5 = lobbyist_zip_norm)
```

``` r
progress_table(
  cole$lobbyist_zip,
  cole$lobbyist_zip5,
  compare = valid_zip
)
#> # A tibble: 2 × 6
#>   stage              prop_in n_distinct prop_na n_out n_diff
#>   <chr>                <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 cole$lobbyist_zip    0.974        732  0.0618  4652    104
#> 2 cole$lobbyist_zip5   0.998        650  0.0618   339     12

progress_table(
  co_exp$lobbyist_zip,
  co_exp$lobbyist_zip5,
  compare = valid_zip
)
#> # A tibble: 2 × 6
#>   stage                prop_in n_distinct prop_na n_out n_diff
#>   <chr>                  <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 co_exp$lobbyist_zip    0.964        401   0.146  2146     72
#> 2 co_exp$lobbyist_zip5   1.00         342   0.146     3      3
```

### State

By examining the percentage of lobbyist_state that are considered valid,
we can see that the variable in both datasets doesn’t need to be
normalized.

``` r
prop_in(cole$lobbyist_state, valid_state, na.rm = T)
#> [1] 0.9999943
prop_in(co_exp$lobbyist_state, valid_state, na.rm = T)
#> [1] 1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats. \#### Normal

The `campfin::normal_city()` function is a good coleart, again
converting case, removing punctuation, but *expanding* USPS
abbreviations. We can also remove `invalid_city` values.

``` r
cole <- cole %>% 
      mutate(lobbyist_city_norm = normal_city(lobbyist_city,abbs = usps_city,
      states = usps_state,
      na = invalid_city,
      na_rep = TRUE))

prop_in(cole$lobbyist_city_norm, valid_city, na.rm = T)
#> [1] 0.9599057

co_exp <- co_exp %>% 
      mutate(lobbyist_city_norm = normal_city(lobbyist_city,abbs = usps_city,
      states = usps_state,
      na = invalid_city,
      na_rep = TRUE))

prop_in(co_exp$lobbyist_city_norm, valid_city, na.rm = T)
#> [1] 0.968613
```

#### Swap

We can further improve normalization by comparing our normalized value
against the *expected* value for that record’s state abbreviation and
ZIP code. If the normalized value is either an abbreviation for or very
similar to the expected value, we can confidently swap those two.

``` r
cole <- cole %>% 
  left_join(
    y = zipcodes,
    by = c(
      "lobbyist_state" = "state",
      "lobbyist_zip5" = "zip"
    )
  ) %>% 
  rename(lobbyist_city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(lobbyist_city_norm, lobbyist_city_match),
    match_dist = str_dist(lobbyist_city_norm, lobbyist_city_match),
    lobbyist_city_swap = if_else(
      condition = !is.na(match_dist) & match_abb | match_dist == 1,
      true = lobbyist_city_match,
      false = lobbyist_city_norm
    )
  ) %>% 
  select(
    -lobbyist_city_match,
    -match_dist,
    -match_abb
  )

co_exp <- co_exp %>% 
  left_join(
    y = zipcodes,
    by = c(
      "lobbyist_state" = "state",
      "lobbyist_zip5" = "zip"
    )
  ) %>% 
  rename(lobbyist_city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(lobbyist_city_norm, lobbyist_city_match),
    match_dist = str_dist(lobbyist_city_norm, lobbyist_city_match),
    lobbyist_city_swap = if_else(
      condition = !is.na(match_dist) & match_abb | match_dist == 1,
      true = lobbyist_city_match,
      false = lobbyist_city_norm
    )
  ) %>% 
  select(
    -lobbyist_city_match,
    -match_dist,
    -match_abb
  )
```

After the two normalization steps, the percentage of valid cities is
close to 100% for both datasets.

#### Progress

| stage                                                                        | prop_in | n_distinct | prop_na | n_out | n_diff |
|:-----------------------------------------------------------------------------|--------:|-----------:|--------:|------:|-------:|
| cole$lobbyist_city | 0.611| 463| 0.062| 68321| 298| |cole$lobbyist_city_norm |   0.994 |        350 |   0.062 |  1000 |     26 |
| cole\$lobbyist_city_swap                                                     |   0.997 |        338 |   0.064 |   564 |     11 |

CO Lobbyists Summary Data Normalization Progress

| stage                                                                           | prop_in | n_distinct | prop_na | n_out | n_diff |
|:--------------------------------------------------------------------------------|--------:|-----------:|--------:|------:|-------:|
| co_exp$lobbyist_city | 0.860| 247| 0.145| 8316| 130| |co_exp$lobbyist_city_norm |   0.998 |        178 |   0.146 |    95 |      9 |
| co_exp\$lobbyist_city_swap                                                      |   0.999 |        175 |   0.146 |    33 |      5 |

CO Lobbyists Expenditure Data Normalization Progress

You can see how the percentage of valid values increased with each
stage.

![](../plots/progress_bar-1.png)<!-- -->![](../plots/progress_bar-2.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

## Conclude

``` r
glimpse(sample_n(cole, 20))
#> Rows: 20
#> Columns: 25
#> $ lobbyist_last_name                           <chr> "STREAMER", "COLORADO COMMUNIQUE INC", "LAW"…
#> $ lobbyist_first_name                          <chr> "CAROL", NA, "DANIEL", "Brad", "Wesley", "BA…
#> $ lobbyist_address1                            <chr> "1705 14TH ST #357", "98 Wadsworth Blvd", "1…
#> $ lobbyist_address2                            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ lobbyist_city                                <chr> "BOULDER", "LAKEWOOD", "DENVER", "Brentwood"…
#> $ lobbyist_state                               <chr> "CO", "CO", "CO", "TN", "CO", "CA", "CO", "C…
#> $ lobbyist_zip                                 <chr> "80302-6321", "80226", "80203", "37027", "80…
#> $ official_state_lobbyist                      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ primary_lobbyist_id                          <chr> "19897000207", "20017000750", "19907000251",…
#> $ annual_lobbyist_registration_id              <chr> "19967000305", "20065003203", "19997000901",…
#> $ date_disclosure_filed                        <chr> "08/08/1996 12:00:00 AM", "11/13/2006 12:00:…
#> $ date_disclosure_last_modified                <chr> NA, "11/13/2006 12:00:00 AM", NA, NA, "02/14…
#> $ business_associated_with_pending_legislation <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ total_monthly_income                         <dbl> 772.81, 18083.33, NA, NA, 3195.00, 2112.00, …
#> $ total_monthly_expenses                       <dbl> 0, 126, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ report_month                                 <chr> "July", "October", "December", "April", "Jan…
#> $ fiscal_year                                  <chr> "1997", "2007", "2000", "2023", "2018", "201…
#> $ report_due_date                              <date> 1996-08-15, 2006-11-15, 2000-01-15, 2023-05…
#> $ na_flag                                      <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FA…
#> $ dupe_flag                                    <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FA…
#> $ year                                         <dbl> 1996, 2006, 2000, 2023, 2018, 2012, 2019, 20…
#> $ lobbyist_address_norm                        <chr> "1705 14TH ST #357", "98 WADSWORTH BLVD", "1…
#> $ lobbyist_zip5                                <chr> "80302", "80226", "80203", "37027", "80202",…
#> $ lobbyist_city_norm                           <chr> "BOULDER", "LAKEWOOD", "DENVER", "BRENTWOOD"…
#> $ lobbyist_city_swap                           <chr> "BOULDER", "LAKEWOOD", "DENVER", "BRENTWOOD"…
glimpse(sample_n(co_exp, 20))
#> Rows: 20
#> Columns: 25
#> $ lobbyist_last_name              <chr> "BUECHE", "DAVIES", "Legacy Consulting Colorado, LLC", "P…
#> $ lobbyist_first_name             <chr> "KENNETH", "JEANNE", "Lacey", "LINDA", "ROBERT", "JAMES",…
#> $ lobbyist_address1               <chr> "1144 SHERMAN ST", "PO BOX 159", "1192 Xenophon St", "859…
#> $ lobbyist_address2               <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "Suite 300", NA, NA, …
#> $ lobbyist_city                   <chr> "DENVER", "DEER TRAIL", "Golden", "DENVER", NA, "DENVER",…
#> $ lobbyist_state                  <chr> "CO", "CO", "CO", "CO", NA, "CO", "CO", "CO", NA, "CO", "…
#> $ lobbyist_zip                    <chr> "80203", "80105", "80401", "80238", NA, "80203", "80203",…
#> $ primary_lobbyist_id             <chr> "19907000131", "19897000033", "20195023409", "19987000312…
#> $ annual_lobbyist_registration_id <chr> "19987000078", "19977000166", "20205114613", "20045002910…
#> $ official_state_lobbyist         <chr> "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N…
#> $ expenditure_name                <chr> "NONE", "NONE", NA, "REP MARK CLOER", "RED ROCKS COLLEGE"…
#> $ expenditure_amount              <dbl> 0.00, 0.00, 110.43, 64.00, 83.00, 0.00, 0.00, 13.09, 0.00…
#> $ expenditure_receipt_date        <date> NA, NA, 2021-02-27, 2004-10-22, 1996-06-01, NA, NA, 1996…
#> $ expenditure_purpose             <chr> NA, NA, "General Business Expenses", "ARTHRITIS DINNER", …
#> $ expenditure_for_media_flag      <chr> "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N…
#> $ report_month                    <chr> "January", "May", "February", "October", "June", "August"…
#> $ fiscal_year                     <chr> "1998", "1997", "2021", "2005", "1996", "1999", "1998", "…
#> $ report_due_date                 <date> 1998-02-15, 1997-06-15, 2021-03-15, 2004-11-15, 1996-07-…
#> $ na_flag                         <lgl> FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, TR…
#> $ dupe_flag                       <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ year                            <dbl> 1998, 1997, 2021, 2004, 1996, 1998, 1997, 1996, 1996, 199…
#> $ lobbyist_address_norm           <chr> "1144 SHERMAN ST", "PO BOX 159", "1192 XENOPHON ST", "859…
#> $ lobbyist_zip5                   <chr> "80203", "80105", "80401", "80238", NA, "80203", "80203",…
#> $ lobbyist_city_norm              <chr> "DENVER", "DEER TRAIL", "GOLDEN", "DENVER", NA, "DENVER",…
#> $ lobbyist_city_swap              <chr> "DENVER", "DEER TRAIL", "GOLDEN", "DENVER", NA, "DENVER",…
```

1.  There are 187254 records in the summary database and 69464 in the
    expenditure database.
2.  There’re 612 duplicate records in the summary database and 1017 in
    the expenditure database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 10141 records missing either address or expenditure
    amount.
5.  Consistency in goegraphic data has been improved with
    `campfin::normal_*()`.

## Export

``` r
clean_dir <- dir_create(here("state","co", "lobby", "data", "exp","clean"))
```

``` r
write_csv(
  x = cole %>% rename( lobbyist_city_clean = lobbyist_city_swap),
  path = path(clean_dir, "co_lob_summary_clean.csv"),
  na = ""
)


write_csv(
  x = co_exp %>% rename(lobbyist_city_clean = lobbyist_city_swap),
  path = path(clean_dir, "co_lob_exp_clean.csv"),
  na = ""
)
```
