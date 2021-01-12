Wyoming Contributions
================
Kiernan Nicholls
2020-04-14 15:05:29

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

Data is obtained from the Wyoming Secretary of State’s Campaign Finance
System (WYCIFS).

> Wyoming’s Campaign Finance Information System (WYCFIS) exists to
> provide a mechanism for online filing of campaign finance information
> and to provide full disclosure to the public. This website contains
> detailed financial records and related information that candidates,
> committees, organizations and parties are required by law to disclose.

## Import

Using the WYCIFS [contribution search
portal](https://www.wycampaignfinance.gov/WYCFWebApplication/GSF_SystemConfiguration/SearchContributions.aspx),
we can run an empty search and return all contributions from “All”
sources. Those search results need to be manually exported as the
`ExportContributions` file.

``` r
raw_dir <- dir_create(here("wy", "contribs", "data", "raw"))
raw_file <- path(raw_dir, "ExportContributions")
```

``` r
wyc <- vroom(
  file = raw_file,
  .name_repair = make_clean_names,
  col_types = cols(
    .default = col_character(),
    Date = col_date_usa(),
    Amount = col_double(),
  )
)
```

## Explore

``` r
head(wyc)
#> # A tibble: 6 x 8
#>   contributor_name recipient_name recipient_type contribution_ty… date       filing_status amount
#>   <chr>            <chr>          <chr>          <chr>            <date>     <chr>          <dbl>
#> 1 ESCH, AMANDA  (… COMMITTEE TO … CANDIDATE COM… MONETARY         2019-12-30 FILED            200
#> 2 UNION PACIFIC C… JIM ANDERSON … CANDIDATE COM… MONETARY         2019-12-30 FILED            300
#> 3 WALLESCH, BRITN… COMMITTEE TO … CANDIDATE COM… MONETARY         2019-12-30 FILED            200
#> 4 WILMETTI, JENNI… COMMITTEE TO … CANDIDATE COM… MONETARY         2019-12-30 FILED            250
#> 5 SHINKLE, LEVI J… COMMITTEE TO … CANDIDATE COM… LOAN             2019-12-27 AMEND - ADD      100
#> 6 UNION PACIFIC C… PERKINS FOR S… CANDIDATE COM… MONETARY         2019-12-27 FILED            300
#> # … with 1 more variable: city_state_zip <chr>
tail(wyc)
#> # A tibble: 6 x 8
#>   contributor_name recipient_name recipient_type contribution_ty… date       filing_status amount
#>   <chr>            <chr>          <chr>          <chr>            <date>     <chr>          <dbl>
#> 1 BUNCE, WILLIAM … MICHELI FOR G… CANDIDATE COM… MONETARY         2009-04-08 FILED           1000
#> 2 COSNER, BARNEY … MICHELI FOR G… CANDIDATE COM… MONETARY         2009-04-08 FILED           1000
#> 3 MICHELI, MATTHE… MICHELI FOR G… CANDIDATE COM… MONETARY         2009-04-08 FILED           4010
#> 4 PARK, GORDON L … MICHELI FOR G… CANDIDATE COM… MONETARY         2009-04-08 FILED            100
#> 5 THOMPSON, DOUGL… MICHELI FOR G… CANDIDATE COM… MONETARY         2009-04-08 FILED            100
#> 6 MICHELI, RON  (… MICHELI FOR G… CANDIDATE COM… MONETARY         2009-03-15 FILED           1000
#> # … with 1 more variable: city_state_zip <chr>
glimpse(sample_n(wyc, 20))
#> Rows: 20
#> Columns: 8
#> $ contributor_name  <chr> "MCCOMB, THEO  (DOUG;AS)", "WY EDUCATION ASSN. PAC FOR EDUCATION (CHEY…
#> $ recipient_name    <chr> "MEAD FOR GOVERNOR", "DAVE CLARENDON ", "RUTH ANN FOR HOUSE", "KATHLEE…
#> $ recipient_type    <chr> "CANDIDATE COMMITTEE", "CANDIDATE", "CANDIDATE COMMITTEE", "CANDIDATE"…
#> $ contribution_type <chr> "MONETARY", "MONETARY", "MONETARY", "MONETARY", "MONETARY", "MONETARY"…
#> $ date              <date> 2014-08-27, 2018-06-18, 2010-10-07, 2010-07-23, 2016-08-03, 2016-06-1…
#> $ filing_status     <chr> "FILED", "FILED", "FILED", "FILED", "FILED", "FILED", "FILED", "FILED"…
#> $ amount            <dbl> 50, 600, 125, 250, 100, 100, 100, 50, 1000, 200, 25, 200, 500, 25, 100…
#> $ city_state_zip    <chr> "DOUG;AS, WY 82633", "CHEYENNE, WY 82001", "WILSON, WY 83014", "WRIGHT…
```

### Missing

``` r
col_stats(wyc, count_na)
#> # A tibble: 8 x 4
#>   col               class      n      p
#>   <chr>             <chr>  <int>  <dbl>
#> 1 contributor_name  <chr>    790 0.0178
#> 2 recipient_name    <chr>      0 0     
#> 3 recipient_type    <chr>      0 0     
#> 4 contribution_type <chr>      0 0     
#> 5 date              <date>     0 0     
#> 6 filing_status     <chr>      0 0     
#> 7 amount            <dbl>      0 0     
#> 8 city_state_zip    <chr>    757 0.0171
```

``` r
wyc <- wyc %>% flag_na(date, contributor_name, amount, recipient_name)
mean(wyc$na_flag)
#> [1] 0.01779961
```

### Duplicates

``` r
wyc <- flag_dupes(wyc, everything(), .check = TRUE)
mean(wyc$dupe_flag)
#> [1] 0.009665863
```

``` r
wyc %>% 
  filter(dupe_flag) %>% 
  select(date, contributor_name, amount, recipient_name)
#> # A tibble: 429 x 4
#>    date       contributor_name                                amount recipient_name          
#>    <date>     <chr>                                            <dbl> <chr>                   
#>  1 2018-10-11 FFFWY FIRE PAC (CHEYENNE)                         500  "RYAN FOR WYOMING"      
#>  2 2018-10-11 FFFWY FIRE PAC (CHEYENNE)                         500  "RYAN FOR WYOMING"      
#>  3 2018-10-11 FFFWY FIRE PAC (CHEYENNE)                         500  "RYAN FOR WYOMING"      
#>  4 2018-10-05 SCHNEIDER, DIANE  (DENVER)                         25  "FRIENDS OF MARK GORDON"
#>  5 2018-10-05 SCHNEIDER, DIANE  (DENVER)                         25  "FRIENDS OF MARK GORDON"
#>  6 2018-10-04 CAMPBELL (GILLETTE)                               257. "TIMOTHY HALLINAN "     
#>  7 2018-10-04 CAMPBELL (GILLETTE)                               257. "TIMOTHY HALLINAN "     
#>  8 2018-10-04 CAMPBELL (GILLETTE)                               257. "TIMOTHY HALLINAN "     
#>  9 2018-10-04 WYOMING MINING ASSOCIATION PAC (WMA) (CHEYENNE)   100  "TOM WALTERS "          
#> 10 2018-10-04 WYOMING MINING ASSOCIATION PAC (WMA) (CHEYENNE)   100  "TOM WALTERS "          
#> # … with 419 more rows
```

### Categorical

``` r
col_stats(wyc, n_distinct)
#> # A tibble: 10 x 4
#>    col               class      n         p
#>    <chr>             <chr>  <int>     <dbl>
#>  1 contributor_name  <chr>  21554 0.486    
#>  2 recipient_name    <chr>    591 0.0133   
#>  3 recipient_type    <chr>      2 0.0000451
#>  4 contribution_type <chr>      5 0.000113 
#>  5 date              <date>  2026 0.0456   
#>  6 filing_status     <chr>      4 0.0000901
#>  7 amount            <dbl>   1872 0.0422   
#>  8 city_state_zip    <chr>   2768 0.0624   
#>  9 na_flag           <lgl>      2 0.0000451
#> 10 dupe_flag         <lgl>      2 0.0000451
```

### Continuous

#### Amounts

``` r
summary(wyc$amount)
#>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
#>       0.0      50.0     100.0     678.7     300.0 2177032.0
mean(wyc$amount <= 0)
#> [1] 2.253115e-05
```

![](../plots/hist_amount-1.png)<!-- -->

#### Dates

``` r
wyc <- mutate(wyc, year = year(date))
```

``` r
min(wyc$date)
#> [1] "2009-03-15"
sum(wyc$year < 2000)
#> [1] 0
max(wyc$date)
#> [1] "2019-12-30"
sum(wyc$date > today())
#> [1] 0
```

![](../plots/bar_year-1.png)<!-- -->

## Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are tailor made to facilitate this process.

The `city_state_zip` valriable contains all three geographic variables,
aside from a street address, which is not present.

We can split these three variables using `tidyr::separate()` and regular
expressions.

``` r
wyc <- wyc %>% 
  separate(
    col = city_state_zip,
    into = c("city", "state_zip"),
    sep = ",\\s(?=[:upper:]{2}\\s\\d+)",
    fill = "right",
    extra = "merge"
  ) %>% 
  separate(
    col = state_zip,
    into = c("state", "zip"),
    sep = "\\s(?=\\d+)",
    extra = "merge"
  )
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
wyc <- wyc %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  wyc$zip,
  wyc$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 zip        0.996       2050  0.0182   155    121
#> 2 zip_norm   0.996       2049  0.0183   154    120
```

This new variable does not improve anything on the original, so it does
not need to be created.

``` r
wyc <- select(wyc, -zip_norm)
```

### State

``` r
prop_in(wyc$state, valid_state)
#> [1] 1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
wyc <- wyc %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("WY", "DC", "WYOMING"),
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
wyc <- wyc %>% 
  rename(city_raw = city) %>% 
  left_join(
    y = zipcodes,
    by = c("state", "zip")
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

#### Refine

The \[OpenRefine\] algorithms can be used to group similar strings and
replace the less common versions with their most common counterpart.
This can greatly reduce inconsistency, but with low confidence; we will
only keep any refined strings that have a valid city/state/zip
combination.

``` r
good_refine <- wyc %>% 
  mutate(
    city_refine = city_swap %>% 
      key_collision_merge() %>% 
      n_gram_merge(numgram = 1)
  ) %>% 
  filter(city_refine != city_swap) %>% 
  inner_join(
    y = zipcodes,
    by = c("city_refine" = "city", "state", "zip")
  )
```

    #> # A tibble: 3 x 5
    #>   state zip   city_swap             city_refine          n
    #>   <chr> <chr> <chr>                 <chr>            <int>
    #> 1 WI    54494 WISCONSIN RAPIDSAOIDS WISCONSIN RAPIDS     1
    #> 2 WY    82001 CHENEYHE              CHEYENNE             1
    #> 3 WY    82633 OUGLASD               DOUGLAS              1

Then we can join the refined values back to the database.

``` r
wyc <- wyc %>% 
  left_join(good_refine) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

| stage      | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :--------- | -------: | ----------: | -------: | -----: | ------: |
| city\_raw) |    0.961 |        1595 |    0.017 |   1700 |     424 |
| city\_norm |    0.980 |        1493 |    0.018 |    877 |     307 |
| city\_swap |    0.991 |        1283 |    0.018 |    383 |      83 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/bar_progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar_distinct-1.png)<!-- -->

## Conclude

``` r
wyc <- wyc %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean"))
```

``` r
glimpse(sample_n(wyc, 20))
#> Rows: 20
#> Columns: 14
#> $ contributor_name  <chr> "BLACK, SUZI  (BUFFALO)", "ACTBLUE (SOMERVILLE)", "RAY, ROBERT  (CHEYE…
#> $ recipient_name    <chr> "MARY FOR WYOMING", "AMY SIMPSON 4 HOUSE", "MARY FOR WYOMING", "DOUGLA…
#> $ recipient_type    <chr> "CANDIDATE COMMITTEE", "CANDIDATE COMMITTEE", "CANDIDATE COMMITTEE", "…
#> $ contribution_type <chr> "MONETARY", "MONETARY", "MONETARY", "MONETARY", "MONETARY", "MONETARY"…
#> $ date              <date> 2018-03-24, 2016-10-04, 2017-08-26, 2014-07-28, 2018-07-15, 2018-09-0…
#> $ filing_status     <chr> "FILED", "FILED", "FILED", "FILED", "FILED", "FILED", "FILED", "FILED"…
#> $ amount            <dbl> 50.00, 25.00, 50.00, 100.00, 50.00, 50.00, 100.00, 100.00, 100.00, 200…
#> $ city_raw          <chr> "BUFFALO", "SOMERVILLE", "CHEYEN", "DOUGLAS", "GILLETTE", "SHERIDAN", …
#> $ state             <chr> "WY", "MA", "WY", "WY", "WY", "WY", "WY", "WY", "WY", "TX", "WY", "WY"…
#> $ zip               <chr> "82834", "02144", "82009", "82633", "82718", "82801", "82939", "82003"…
#> $ na_flag           <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
#> $ dupe_flag         <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
#> $ year              <dbl> 2018, 2016, 2017, 2014, 2018, 2018, 2010, 2014, 2012, 2010, 2012, 2012…
#> $ city_clean        <chr> "BUFFALO", "SOMERVILLE", "CHEYENNE", "DOUGLAS", "GILLETTE", "SHERIDAN"…
```

1.  There are 44,383 records in the database.
2.  There are 429 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 790 records missing ….
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
clean_dir <- dir_create(here("wy", "contribs", "data", "clean"))
clean_path <- path(clean_dir, "wy_contribs_clean.csv")
write_csv(wyc, clean_path, na = "")
file_size(clean_path)
#> 6.15M
guess_encoding(clean_path)
#> # A tibble: 3 x 2
#>   encoding   confidence
#>   <chr>           <dbl>
#> 1 UTF-8            0.8 
#> 2 ISO-8859-1       0.35
#> 3 ISO-8859-2       0.26
```
