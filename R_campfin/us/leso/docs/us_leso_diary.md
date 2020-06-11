United States Law Enforcement 1033 Transfers
================
Kiernan Nicholls
2020-06-10 14:21:47

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Download](#download)
  - [Read](#read)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
  - [Conclude](#conclude)
  - [Export](#export)
  - [Upload](#upload)
  - [Dictionary](#dictionary)

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
  gluedown, # printing markdown
  magrittr, # pipe operators
  janitor, # clean data frames
  refinr, # cluster and merge
  readxl, # read excel files
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  rvest, # html scraping
  usmap, # plot us maps
  glue, # combine strings
  here, # relative paths
  httr, # http requests
  fs # local storage 
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

Per [Wikipedia](https://en.wikipedia.org/wiki/1033_program):

> In the United States, the 1033 Program transfers excess military
> equipment to civilian law enforcement agencies. The program legally
> requires the Department of Defense to make various items of equipment
> available to local law enforcement. The 1033 program was instituted
> per Bill Clinton’s 1997 National Defense Authorization Act, though
> precedents to it existed following World War II.

The Defense Logistics Agency (DLA) [electronic reading
room](https://www.dla.mil/DispositionServices/FOIA/EFOIALibrary/)
contains electronic versions of the hard copy documents with data
regarding 1033 transfers.

> DLA’s Law Enforcement Support Office transfers excess Department of
> Defense property to federal, state, and local law enforcement agencies
> within the United States and its Territories

There are two files pertaining to the 1033 program:

1.  [LESO Property Transferred to Participating
    Agencies](https://www.dla.mil/Portals/104/Documents/DispositionServices/LESO/DISP_AllStatesAndTerritories_06302018.xlsx)
      - By state and agency name as of June 30, 2018. This is the most
        recent quarterly update of the accountable property held by
        participating agencies:
2.  [LESO Information for Shipments and Cancellations of
    Property](https://www.dla.mil/Portals/104/Documents/DispositionServices/LESO/DISP_Shipments_Cancellations_04012018_06302018.xlsx)
      - The information includes all requests made during the time
        period of April 1 - June 30, 2018.

## Download

We will be downloading the first file for now.

``` r
raw_dir <- dir_create(here("us", "leso", "data", "raw"))
raw_url <- "https://www.dla.mil/Portals/104/Documents/DispositionServices/LESO/"
raw_name <- "DISP_AllStatesAndTerritories_03312020.xlsx"
raw_url <- str_c(raw_url, raw_name)
raw_path <- path(raw_dir, raw_name)
```

``` r
if (!file_exists(raw_path)) {
  download.file(raw_url, raw_path)
}
```

## Read

The Excel spreadsheet lists transfers to police departments to each
state in separate states. We can combine `purrr::map_df()` and
`readxl::read_excel()` to read all the sheets into a single data frame
of transfers.

``` r
leso <- raw_path %>%
  readxl::excel_sheets() %>%
  purrr::set_names() %>%
  purrr::map_df(
    .f = read_excel,
    .name_repair = make_clean_names,
    path = raw_path
  )
```

``` r
leso <- rename(
  .data = leso,
  to_station = station_name_lea,
  to_state = state,
  item = item_name,
  value = acquisition_value,
  date = ship_date
)
```

## Explore

``` r
glimpse(leso)
#> Rows: 141,068
#> Columns: 11
#> $ to_state     <chr> "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL", "AL…
#> $ to_station   <chr> "ABBEVILLE POLICE DEPT", "ABBEVILLE POLICE DEPT", "ABBEVILLE POLICE DEPT", …
#> $ nsn          <chr> "2320-01-371-9584", "1005-01-587-7175", "2320-01-371-9584", "2355-01-553-46…
#> $ item         <chr> "TRUCK,UTILITY", "MOUNT,RIFLE", "TRUCK,UTILITY", "MINE RESISTANT VEHICLE", …
#> $ quantity     <dbl> 1, 10, 1, 1, 9, 1, 1, 10, 10, 1, 1, 1, 1, 1, 10, 3, 12, 5, 11, 1, 1, 10, 1,…
#> $ ui           <chr> "Each", "Each", "Each", "Each", "Each", "Each", "Each", "Each", "Kit", "Eac…
#> $ value        <dbl> 62627.00, 1626.00, 62627.00, 658000.00, 321.00, 245.88, 600.00, 884.00, 146…
#> $ demil_code   <chr> "C", "D", "C", "C", "D", "D", "D", "D", "D", "A", "A", "Q", "D", "D", "D", …
#> $ demil_ic     <chr> "1", "1", "1", "1", "1", NA, "7", "1", "1", NA, NA, "3", "1", "1", "1", "1"…
#> $ date         <dttm> 2016-09-29, 2016-09-19, 2016-09-29, 2016-11-09, 2016-09-14, 2016-06-02, 20…
#> $ station_type <chr> "State", "State", "State", "State", "State", "State", "State", "State", "St…
tail(leso)
#> # A tibble: 6 x 11
#>   to_state to_station nsn   item  quantity ui    value demil_code demil_ic date               
#>   <chr>    <chr>      <chr> <chr>    <dbl> <chr> <dbl> <chr>      <chr>    <dttm>             
#> 1 PR       VILLALBA … 2320… TRUC…        1 Each  41447 C          1        2011-11-01 00:00:00
#> 2 VI       VIRGIN IS… 1005… RIFL…        1 Each    138 D          1        1996-08-20 00:00:00
#> 3 VI       VIRGIN IS… 1005… RIFL…        1 Each    138 D          1        1996-08-20 00:00:00
#> 4 VI       VIRGIN IS… 1005… RIFL…        1 Each    138 D          1        1996-08-20 00:00:00
#> 5 VI       VIRGIN IS… 1005… RIFL…        1 Each    138 D          1        1996-08-20 00:00:00
#> 6 VI       VIRGIN IS… 1005… RIFL…        1 Each    138 D          1        1996-08-20 00:00:00
#> # … with 1 more variable: station_type <chr>
```

### Missing

Only one variable is missing any values. Nothing needs to be flagged.

``` r
col_stats(leso, count_na)
#> # A tibble: 11 x 4
#>    col          class      n      p
#>    <chr>        <chr>  <int>  <dbl>
#>  1 to_state     <chr>      0 0     
#>  2 to_station   <chr>      0 0     
#>  3 nsn          <chr>      0 0     
#>  4 item         <chr>      0 0     
#>  5 quantity     <dbl>      0 0     
#>  6 ui           <chr>      0 0     
#>  7 value        <dbl>      0 0     
#>  8 demil_code   <chr>      0 0     
#>  9 demil_ic     <chr>   8905 0.0631
#> 10 date         <dttm>     0 0     
#> 11 station_type <chr>      0 0
```

### Duplicates

There are quite a lot of duplicate records in the database. We can find
and flag these records with `campfin::flag_dupes()`.

``` r
leso <- flag_dupes(leso, everything())
mean(leso$dupe_flag)
#> [1] 0.7121246
```

It looks like most of these duplicates are simply multiple items
transferred in the same shipment with a `quantity` of 1.

``` r
leso %>% 
  filter(dupe_flag) %>% 
  select(date, to_station, value, quantity, item) %>% 
  arrange(date)
#> # A tibble: 100,458 x 5
#>    date                to_station               value quantity item                 
#>    <dttm>              <chr>                    <dbl>    <dbl> <chr>                
#>  1 1990-05-03 00:00:00 BLAINE CTY SHERIFF DEPT    138        1 RIFLE,7.62 MILLIMETER
#>  2 1990-05-03 00:00:00 BLAINE CTY SHERIFF DEPT    138        1 RIFLE,7.62 MILLIMETER
#>  3 1990-05-03 00:00:00 BLAINE CTY SHERIFF DEPT    138        1 RIFLE,7.62 MILLIMETER
#>  4 1990-05-03 00:00:00 BLAINE CTY SHERIFF DEPT    138        1 RIFLE,7.62 MILLIMETER
#>  5 1990-05-03 00:00:00 BLAINE CTY SHERIFF DEPT    138        1 RIFLE,7.62 MILLIMETER
#>  6 1990-05-03 00:00:00 DANIELS CTY SHERIFF DEPT   138        1 RIFLE,7.62 MILLIMETER
#>  7 1990-05-03 00:00:00 DANIELS CTY SHERIFF DEPT   138        1 RIFLE,7.62 MILLIMETER
#>  8 1990-05-03 00:00:00 DANIELS CTY SHERIFF DEPT   138        1 RIFLE,7.62 MILLIMETER
#>  9 1990-05-03 00:00:00 DILLON POLICE DEPT         138        1 RIFLE,7.62 MILLIMETER
#> 10 1990-05-03 00:00:00 DILLON POLICE DEPT         138        1 RIFLE,7.62 MILLIMETER
#> # … with 100,448 more rows
```

``` r
leso %>% 
  filter(dupe_flag) %>% 
  count(quantity, sort = TRUE) %>% 
  add_prop()
#> # A tibble: 38 x 3
#>    quantity     n        p
#>       <dbl> <int>    <dbl>
#>  1        1 99206 0.988   
#>  2        2   353 0.00351 
#>  3       10   252 0.00251 
#>  4        4   153 0.00152 
#>  5        3   104 0.00104 
#>  6        5    87 0.000866
#>  7        6    62 0.000617
#>  8       20    39 0.000388
#>  9        8    26 0.000259
#> 10       12    20 0.000199
#> # … with 28 more rows
```

We will remove the `dupe_flag` variable for any record with a `quantity`
of 1.

``` r
leso$dupe_flag[which(leso$quantity == 1)] <- FALSE
mean(leso$dupe_flag)
#> [1] 0.008875152
```

### Categorical

``` r
col_stats(leso, n_distinct)
#> # A tibble: 12 x 4
#>    col          class      n          p
#>    <chr>        <chr>  <int>      <dbl>
#>  1 to_state     <chr>     53 0.000376  
#>  2 to_station   <chr>   5682 0.0403    
#>  3 nsn          <chr>  10287 0.0729    
#>  4 item         <chr>   4911 0.0348    
#>  5 quantity     <dbl>    280 0.00198   
#>  6 ui           <chr>     33 0.000234  
#>  7 value        <dbl>   9356 0.0663    
#>  8 demil_code   <chr>      7 0.0000496 
#>  9 demil_ic     <chr>      8 0.0000567 
#> 10 date         <dttm>  4773 0.0338    
#> 11 station_type <chr>      1 0.00000709
#> 12 dupe_flag    <lgl>      2 0.0000142
```

``` r
explore_plot(leso, demil_code)
```

![](../plots/distinct_plots-1.png)<!-- -->

``` r
explore_plot(leso, demil_ic)
```

![](../plots/distinct_plots-2.png)<!-- -->

### Amounts

``` r
summary(leso$value)
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#>        0      138      499    11592      749 22000000
mean(leso$value <= 0)
#> [1] 0.001084583
```

![](../plots/hist_amount-1.png)<!-- -->

![](../plots/amount_map-1.png)<!-- -->

### Dates

We can add the calendar year from `date` with `lubridate::year()`

``` r
leso <- mutate(leso, year = year(date))
```

``` r
min(leso$date)
#> [1] "1980-01-01 09:07:07 UTC"
sum(leso$year < 1990)
#> [1] 1
max(leso$date)
#> [1] "2020-04-21 UTC"
sum(leso$date > today())
#> [1] 0
```

![](../plots/bar_year-1.png)<!-- -->

## Wrangle

The raw data does not include a variable indicating the source of each
transfer, but we know all transfers come from the United States
Military. We can manually add a new column so transfers can be searches.

``` r
leso <- mutate(
  .data = leso, 
  .before = 1,
  from_state = "US",
  from_dept = "Department of Defense"
)
```

## Conclude

1.  There are 141,068 records in the database.
2.  There are 1,252 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 0 records missing key variables.
5.  There are no geographic variables other than the 2-letter state
    abbreviation.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("us", "leso", "data", "clean"))
clean_path <- path(clean_dir, "us_1033_transfers.csv")
write_csv(leso, clean_path, na = "")
file_size(clean_path)
#> 19.9M
mutate(file_encoding(clean_path), across(path, path.abbrev))
#> # A tibble: 1 x 3
#>   path                                       mime            charset 
#>   <chr>                                      <chr>           <chr>   
#> 1 ~/us/leso/data/clean/us_1033_transfers.csv application/csv us-ascii
```

## Upload

Using the [duckr](https://github.com/kiernann/duckr) R package, we can
wrap around the [duck](https://duck.sh/) command line tool to upload the
file to the IRW server.

``` r
# remotes::install_github("kiernann/duckr")
s3_dir <- "s3:/publicaccountability/csv/"
s3_path <- path(s3_dir, basename(clean_path))
if (require(duckr)) {
  duckr::duck_upload(clean_path, s3_path)
}
```

## Dictionary

The following table describes the variables in our final exported file:

| Column         | Type        | Definition                                      |
| :------------- | :---------- | :---------------------------------------------- |
| `from_state`   | `character` | Manually added department “styate”              |
| `from_dept`    | `character` | Manually added department name                  |
| `to_state`     | `character` | Recieving station state                         |
| `to_station`   | `character` | Recieving station name                          |
| `nsn`          | `character` | Item’s unique “National Stock Number”           |
| `item`         | `character` | Item name                                       |
| `quantity`     | `double`    | Quantity of items transfered                    |
| `ui`           | `character` | Units of item transfered                        |
| `value`        | `double`    | Value of equipment transfered†                  |
| `demil_code`   | `character` | Required level of destruction before transfer\* |
| `demil_ic`     | `character` | Integrity Code\*                                |
| `date`         | `double`    | Date transfer was shipped                       |
| `station_type` | `character` | Recieving station type (all “State”)            |
| `dupe_flag`    | `logical`   | Flag indicating duplicate non-single transfer   |
| `year`         | `double`    | Calendar year shipped                           |

> †That figure can be misleading. The cost associated with the LESO/1033
> Program property is based on original acquisition value, i.e. what the
> procuring agency, normally a branch of the military, paid for the item
> at the time it was procured. Many of the items available in the excess
> property inventory were procured decades ago, so the current value,
> with depreciation, would be difficult (and not cost-effective) to
> determine. The original acquisition value is the only cost component
> available in current data systems. Using the initial acquisition
> value, the total amount transferred since the program’s inception in
> 1990 is $7.4 billion.

> \*DEMIL code indicates the degree of required physical destruction,
> identifies items requiring specialized capabilities or procedures, and
> identifies items which do not require DEMIL but may require Trade
> Security Controls. It is used throughout the life-cycle to identify
> control requirements required before release from DoD control. The
> DEMIL codes below are listed as the Highest Severity to the Lowest
> Severity in DEMIL coding. DEMIL Integrity Code appear adjacent to the
> DEMIL Code in FLIS that identify the validity of an item’s DEMIL code.
> For additional information on DEMIL codes or DEMIL Integrity Codes,
> see DOD 4160.28 DEMIL Program or DOD 4100.39M FLIS Manual.
