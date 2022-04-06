South Carolina Lobbying Registration Data Diary
================
Yanqi Xu
2020-03-18 17:22:15

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
  httr, # interact with http responses
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
#> [1] "/Users/yanqixu/code/accountability_datacleaning/R_campfin"
```

## Data

Lobbyist data is obtained from the [South Carolina State Ethics
Commission](https://apps.sc.gov/PublicReporting/Index.aspx).

> #### Welcome
> 
> Registrations for both lobbyists and their respective lobbyist’s
> principals are available online for viewing. Disclosure for both
> lobbyists and their respective lobbyist’s principals will also be
> available at the conclusion of the first disclosure period, June 30,
> 2009, for the period, January 1, 2009 through May 31, 2009.

The [lobbying activity
page](https://apps.sc.gov/LobbyingActivity/LAIndex.aspx), we can see the
files that can be retrieved:

> #### Lobbying Activity
> 
> Welcome to the State Ethics Commission Online Public Disclosure and
> Accountability Reporting System for Lobbying Activity. Registrations
> for both lobbyists and their respective lobbyist’s principals are
> available online for viewing.
> 
> Disclosure for both lobbyists and their respective lobbyist’s
> principals are available for the period June 30, 2009 through the
> present.
> 
> These filings can be accessed by searching individual reports by
> lobbyist and lobbyist’s principal names and by complete list of
> current lobbyist and lobbyist’s principal registrations.

> #### List Reports
> 
> View a list of lobbyists, lobbyists’ principals or their contact
> information.
> 
>   - [Lobbyists and Their
>     Principals](https://apps.sc.gov/LobbyingActivity/SelectLobbyistGroup.aspx)
>   - [Download Lobbyist Contacts (CSV
>     file)](https://apps.sc.gov/LobbyingActivity/DisplayCsv.aspx)
>   - [Individual Lobbyist
>     Lookup](https://apps.sc.gov/LobbyingActivity/SearchLobbyistContact.aspx)
>   - [Lobbyists’ Principals and Their
>     Lobbyists](https://apps.sc.gov/LobbyingActivity/SelectLobbyistPrincipalGroup.aspx)
>   - [Download Lobbyist’s Principal Contacts (CSV
>     file)](https://apps.sc.gov/LobbyingActivity/DisplayCsv.aspx)
>   - [Individual Lobbyist’s Principal
>     Lookup](https://apps.sc.gov/LobbyingActivity/SearchLPContact.aspx)
>   - [Year End Compilation
>     Report](https://apps.sc.gov/LobbyingActivity/CompilationReport.aspx)

First, we must download a reporting linking lobbyists to their
principals. We will download the `Lobbyists and Their Principals` table.
Go to Public Disclosure \> Lobbying Activity \> List of Lobbyist \>
Type: All Lobbyist, and then hit Continue. A csv file is available for
download. We’ll name it `lob_prin.csv`.

Then we can download the `Lobbyists' Principals and Their Lobbyists` Go
to Public Disclosure \> Lobbying Activity \> List of Lobbyists’
Principals \> Type: All Lobbyists’ Principals, and then hit Continue. A
csv file is available for download. We’ll name it `prin_lob.csv`.

Both tables are downloaded on March 18, 2020.

``` r
raw_dir <- here("sc", "lobby", "data", "raw", "reg")
dir_create(raw_dir)
```

``` r
sclr <- read_csv(dir_ls(raw_dir))
```

### Import

Using these three files, we can create a single data frame listing
lobbyists and those for whom they lobby.

``` r
lobs <- 
  # read as string
  read_lines(file = path(raw_dir, "lob_prin.csv")) %>%
  extract(-2) %>% 
  # fix quote enclosure
  str_replace("\"Eye\"", "'Eye'") %>%
  # pass as delim file
  read_delim(
    delim = ",",
    escape_backslash = FALSE,
    escape_double = FALSE,
    na = c("", " ")
  ) %>%
  # clean shape
  remove_empty("cols") %>% 
  clean_names("snake")

# clarify col names
names(lobs) <- names(lobs) %>% 
  str_remove("_(.*)") %>% 
  str_remove("code$") %>% 
  str_c("lob", ., sep = "_")
```

``` r
pris <- 
  read_delim(
    file = path(raw_dir, "prin_lob.csv"),
    delim = ",",
    escape_backslash = FALSE,
    escape_double = FALSE,
    na = c("", " ")
  ) %>% 
  remove_empty("cols") %>% 
  clean_names("snake")

names(pris) <- names(pris) %>% 
  str_remove("_(.*)") %>% 
  str_remove("code$") %>%
  str_replace("^lpname$", "name") %>% 
  str_c("pri", ., sep = "_")
```

``` r
sclr <- lobs %>% 
  left_join(pris, by = c("lob_principal" = "pri_principal",
                         "lob_lastname" = "pri_last",
                         "lob_firstname" = "pri_first",
                         "lob_middle" = "pri_middle",
                         "lob_suffix" = "pri_suffix"))
```

By examining the count of `NA` before and after the join, we can see
that all lobbyist records were accounted for from the `pris` dataframe.

``` r
col_stats(lobs, count_na)
#> # A tibble: 10 x 4
#>    col           class     n     p
#>    <chr>         <chr> <int> <dbl>
#>  1 lob_lastname  <chr>     0 0    
#>  2 lob_firstname <chr>     0 0    
#>  3 lob_address   <chr>     0 0    
#>  4 lob_city      <chr>     0 0    
#>  5 lob_state     <chr>     0 0    
#>  6 lob_zip       <chr>     0 0    
#>  7 lob_phone     <dbl>     0 0    
#>  8 lob_principal <chr>     0 0    
#>  9 lob_middle    <chr>   474 0.383
#> 10 lob_suffix    <chr>  1155 0.934
col_stats(sclr, count_na)
#> # A tibble: 15 x 4
#>    col           class     n     p
#>    <chr>         <chr> <int> <dbl>
#>  1 lob_lastname  <chr>     0 0    
#>  2 lob_firstname <chr>     0 0    
#>  3 lob_address   <chr>     0 0    
#>  4 lob_city      <chr>     0 0    
#>  5 lob_state     <chr>     0 0    
#>  6 lob_zip       <chr>     0 0    
#>  7 lob_phone     <dbl>     0 0    
#>  8 lob_principal <chr>     0 0    
#>  9 lob_middle    <chr>   474 0.383
#> 10 lob_suffix    <chr>  1155 0.934
#> 11 pri_address   <chr>     0 0    
#> 12 pri_city      <chr>     0 0    
#> 13 pri_state     <chr>     0 0    
#> 14 pri_zip       <chr>     0 0    
#> 15 pri_phone     <dbl>     0 0

prop_in(
  x = str_normal(paste(lobs$lob_firstname, lobs$lob_lastname)),
  y = str_normal(paste(sclr$lob_firstname, sclr$lob_lastname)),
)
#> [1] 1
```

## Explore

### Duplicaes

We can see that there’s no duplicate rows in this dataset.

``` r
sclr %>% flag_dupes(dplyr::everything())
#> # A tibble: 1,237 x 15
#>    lob_lastname lob_firstname lob_address lob_city lob_state lob_zip lob_phone lob_principal
#>    <chr>        <chr>         <chr>       <chr>    <chr>     <chr>       <dbl> <chr>        
#>  1 Adams        Stevenson     605 Founta… Columbia SC        29209      8.04e9 Conservation…
#>  2 Adkins       Todd          11250 Wapl… Fairfax  VA        22030      7.03e9 National Rif…
#>  3 Allen        Fred          PO Box 120… Columbia SC        29211      8.03e9 AT & T Servi…
#>  4 Allen        Fred          PO Box 120… Columbia SC        29211      8.03e9 BMW Manufact…
#>  5 Allen        Fred          PO Box 120… Columbia SC        29211      8.03e9 Ducks Unlimi…
#>  6 Allen        Fred          PO Box 120… Columbia SC        29211      8.03e9 Outdoor Adve…
#>  7 Allen        Fred          PO Box 120… Columbia SC        29211      8.03e9 RAI Services…
#>  8 Allen        Fred          PO Box 120… Columbia SC        29211      8.03e9 Southern Win…
#>  9 Allen        Fred          PO Box 120… Columbia SC        29211      8.03e9 Wine & Spiri…
#> 10 Allman       Melissa       454 South … Rock Hi… SC        29730      8.03e9 BAYADA Home …
#> # … with 1,227 more rows, and 7 more variables: lob_middle <chr>, lob_suffix <chr>,
#> #   pri_address <chr>, pri_city <chr>, pri_state <chr>, pri_zip <chr>, pri_phone <dbl>
```

## Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are taylor made to facilitate this process.

### Address

For the street `addresss` variable, the `campfin::normal_address()`
function will force consistence case, remove punctuation, and
abbreviation official USPS suffixes.

``` r
sclr <- sclr %>% 
  mutate_at(.vars = vars(ends_with('address')), 
            .funs = list(norm = ~ normal_address(.,
,abbs = usps_street,
      na_rep = TRUE)))
```

``` r
sclr %>% 
  select(contains("address")) %>% 
  distinct() %>% 
  sample_n(10) %>% 
  glimpse()
#> Observations: 10
#> Variables: 4
#> $ lob_address      <chr> "1901 Main St", "1855 East Main Street, Suite 14, PMB 104", "701 Gervai…
#> $ pri_address      <chr> "720 Gracern Rd., Suite 106", "1020 N. French St., DE5-002-03-11", "675…
#> $ lob_address_norm <chr> "1901 MAIN ST", "1855 E MAIN ST STE 14 PMB 104", "701 GERVAIS ST STE 15…
#> $ pri_address_norm <chr> "720 GRACERN RD STE 106", "1020 N FRENCH ST DE 50020311", "675 W PEACHT…
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valied *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
sclr <- sclr %>% 
    mutate_at(.vars = vars(ends_with('zip')), .funs = list(norm = ~ normal_zip(.,na_rep = T))) %>% 
    rename(lob_zip5 = lob_zip_norm,
           pri_zip5 = pri_zip_norm)
```

``` r
progress_table(
  sclr$lob_zip,
  sclr$lob_zip5,
  sclr$pri_zip,
  sclr$pri_zip5,
  compare = valid_zip
)
#> # A tibble: 4 x 6
#>   stage    prop_in n_distinct prop_na n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 lob_zip    0.969        155       0    38     13
#> 2 lob_zip5   1            145       0     0      0
#> 3 pri_zip    0.988        316       0    15     10
#> 4 pri_zip5   0.999        312       0     1      1
```

### State

By examining the percentage of lobbyist\_state that are considered
valid, we can see that the `state` variable in both datasets doesn’t
need to be normalized.

``` r
prop_in(sclr$lob_state, valid_state, na.rm = T)
#> [1] 1
prop_in(sclr$pri_state, valid_state, na.rm = T)
#> [1] 1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats. \#\#\#\# Normal

The `campfin::normal_city()` function is a good sclrart, again
converting case, removing punctuation, but *expanding* USPS
abbreviations. We can also remove `invalid_city` values.

``` r
sclr <- sclr %>% 
  mutate_at(.vars = vars(ends_with('city')), .funs = list(norm = ~ normal_city(.,
      abbs = usps_city,
      states = usps_state,
      na = invalid_city,
      na_rep = TRUE)))

prop_in(sclr$lob_city_norm, valid_city, na.rm = T)
#> [1] 0.9967664
prop_in(sclr$pri_city_norm, valid_city, na.rm = T)
#> [1] 0.9692805
```

#### Swap

We can further improve normalization by comparing our normalized value
against the *expected* value for that record’s state abbreviation and
ZIP code. If the normalized value is either an abbreviation for or very
similar to the expected value, we can confidently swap those two.

``` r
sclr <- sclr %>% 
  left_join(
    y = zipcodes,
    by = c(
      "lob_state" = "state",
      "lob_zip5" = "zip"
    )
  ) %>% 
  rename(lob_city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(lob_city_norm, lob_city_match),
    match_dist = str_dist(lob_city_norm, lob_city_match),
    lob_city_swap = if_else(
      condition = !is.na(match_dist) & match_abb | match_dist == 1,
      true = lob_city_match,
      false = lob_city_norm
    )
  ) %>% 
  select(
    -lob_city_match,
    -match_dist,
    -match_abb
  )

sclr <- sclr %>% 
  left_join(
    y = zipcodes,
    by = c(
      "pri_state" = "state",
      "pri_zip5" = "zip"
    )
  ) %>% 
  rename(pri_city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(pri_city_norm, pri_city_match),
    match_dist = str_dist(pri_city_norm, pri_city_match),
    pri_city_swap = if_else(
      condition = !is.na(match_dist) & match_abb | match_dist == 1,
      true = pri_city_match,
      false = pri_city_norm
    )
  ) %>% 
  select(
    -pri_city_match,
    -match_dist,
    -match_abb
  )
```

### Manual

There are still some remaining `pri_city_swap` fields that don’t match
our list of known cities.

``` r
many_city <- c(valid_city, extra_city)

sclr_out <- sclr %>% 
  filter(pri_city_swap %out% many_city) %>% 
  count(pri_city_swap, pri_state, sort = TRUE) %>% 
  drop_na()
```

``` r
sclr <- sclr %>% 
  mutate(pri_city_swap = str_replace(pri_city_swap,"^COLUMBIA SC$", "COLUMBIA"))
```

After the two normalization steps, the percentage of valid cities is
close to 100% for both
datasets.

#### Progress

| stage           | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :-------------- | -------: | ----------: | -------: | -----: | ------: |
| lob\_city       |    0.010 |          98 |    0.000 |   1225 |      95 |
| lob\_city\_norm |    0.997 |          93 |    0.000 |      4 |       2 |
| lob\_city\_swap |    0.997 |          94 |    0.001 |      4 |       3 |
| pri\_city       |    0.008 |         197 |    0.000 |   1227 |     192 |
| pri\_city\_norm |    0.976 |         187 |    0.000 |     30 |       8 |
| pri\_city\_swap |    0.998 |         182 |    0.006 |      3 |       2 |

SC Lobbyists Registration City Normalization Progress

You can see how the percentage of valid values increased with each
stage.

![](../plots/progress_bar-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

## Conclude

``` r
glimpse(sample_n(sclr, 20))
#> Observations: 20
#> Variables: 23
#> $ lob_lastname     <chr> "DeWorken", "Parker", "Scott", "Parker", "Phan", "Smith", "Brown", "Fly…
#> $ lob_firstname    <chr> "John", "Vicki", "Darrell", "Vicki", "Stacie", "Stephen", "Herbert", "B…
#> $ lob_address      <chr> "PO Box 9793", "PO Box 12244", "1411 Gervais Street, Suite 500", "PO Bo…
#> $ lob_city         <chr> "Greenville", "Columbia", "Columbia", "Columbia", "Ridgefield", "Sparta…
#> $ lob_state        <chr> "SC", "SC", "SC", "SC", "CT", "SC", "SC", "SC", "SC", "DC", "SC", "SC",…
#> $ lob_zip          <chr> "29604", "29211", "29201", "29211", "06877", "29307", "29211", "29201",…
#> $ lob_phone        <dbl> 8649055529, 8032538662, 8642470548, 8032538662, 2037787917, 8645800029,…
#> $ lob_principal    <chr> "SC Retail Association", "University Center of Greenville, Inc.", "Next…
#> $ lob_middle       <chr> "M", "C", "T", "C", NA, "H", "B", NA, "F", NA, NA, "C", NA, NA, "K", "D…
#> $ lob_suffix       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ pri_address      <chr> "PO Box 1030", "225 S. Pleasantburg Drive", "9600 Escarpment Blvd", "P.…
#> $ pri_city         <chr> "Raleigh", "Greenville", "Austin", "Columbia", "Ridgefield", "Wilmingto…
#> $ pri_state        <chr> "NC", "SC", "TX", "SC", "CT", "DE", "SC", "SC", "SC", "DC", "SC", "SC",…
#> $ pri_zip          <chr> "27602", "29607", "78749", "29211", "06877", "19884", "29210", "29169",…
#> $ pri_phone        <dbl> 9198320811, 8642501111, 5122843074, 8039331259, 2037985303, 3024320956,…
#> $ lob_address_norm <chr> "PO BOX 9793", "PO BOX 12244", "1411 GERVAIS ST STE 500", "PO BOX 12244…
#> $ pri_address_norm <chr> "PO BOX 1030", "225 S PLEASANTBURG DR", "9600 ESCARPMENT BLVD", "PO BOX…
#> $ lob_zip5         <chr> "29604", "29211", "29201", "29211", "06877", "29307", "29211", "29201",…
#> $ pri_zip5         <chr> "27602", "29607", "78749", "29211", "06877", "19884", "29210", "29169",…
#> $ lob_city_norm    <chr> "GREENVILLE", "COLUMBIA", "COLUMBIA", "COLUMBIA", "RIDGEFIELD", "SPARTA…
#> $ pri_city_norm    <chr> "RALEIGH", "GREENVILLE", "AUSTIN", "COLUMBIA", "RIDGEFIELD", "WILMINGTO…
#> $ lob_city_swap    <chr> "GREENVILLE", "COLUMBIA", "COLUMBIA", "COLUMBIA", "RIDGEFIELD", "SPARTA…
#> $ pri_city_swap    <chr> "RALEIGH", "GREENVILLE", "AUSTIN", "COLUMBIA", "RIDGEFIELD", "WILMINGTO…
```

1.  There are 1237 records in the database.
2.  There’re 0 duplicate records.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 0 records missing either address or expenditure amount.
5.  Consistency in goegraphic data has been improved with
    `campfin::normal_*()`.
6.  This dataset doesn’t contain `date` columns.

## Export

``` r
clean_dir <- dir_create(here("sc", "lobby", "data", "reg","clean"))
```

``` r
write_csv(
  x = sclr %>% 
    select(-c(lob_city_norm, pri_city_norm)) %>% 
    rename( lob_city_clean = lob_city_swap,
                       pri_city_clean = pri_city_swap),
  path = path(clean_dir, "sc_lob_reg_clean.csv"),
  na = ""
)
```
