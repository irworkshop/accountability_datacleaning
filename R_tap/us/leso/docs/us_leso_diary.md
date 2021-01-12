United States Law Enforcement 1033 Transfers
================
Kiernan Nicholls
2020-06-17 11:21:18

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
raw_name <- c(
  "DISP_AllStatesAndTerritories_03312020.xlsx",
  "DISP_AllStatesAndTerritories_12312019.xlsx",
  "DISP_AllStatesAndTerritories_09302019.xlsx"
)
raw_url <- str_c(raw_url, raw_name)
raw_path <- path(raw_dir, raw_name)
```

``` r
if (!all(file_exists(raw_path))) {
  download.file(raw_url, raw_path)
}
```

## Read

The Excel spreadsheet lists transfers to police departments to each
state in separate states. We can combine `purrr::map_df()` and
`readxl::read_excel()` to read all the sheets into a single data frame
of transfers.

``` r
leso <- rep(list(NA), length(raw_path))
for (i in seq_along(raw_path)) {
  leso[[i]] <- raw_path[i] %>%
    readxl::excel_sheets() %>%
    purrr::set_names() %>%
    purrr::map_df(
      .f = read_excel,
      .name_repair = make_clean_names,
      path = raw_path[i]
    )
}
```

``` r
leso <- map(
  .x = leso,
  .f = rename,
  to_station = station_name_lea,
  to_state = state,
  item = item_name,
  value = acquisition_value,
  date = ship_date
)
```

Some equipment transfers are represented with a single row and a larger
`quantity` value. Others have many rows with a `quantity` of 1
(particularly) with items like “RIFLE,5.56 MILLIMETER” (the most common
item transferred).

``` r
leso[[i]] %>% 
  filter(quantity == 1) %>% 
  arrange(to_station, date, item)
#> # A tibble: 116,469 x 10
#>    to_state to_station   nsn    item   quantity ui    value demil_code demil_ic date               
#>    <chr>    <chr>        <chr>  <chr>     <dbl> <chr> <dbl> <chr>      <chr>    <dttm>             
#>  1 AR       14TH JUDICI… 1005-… RIFLE…        1 Each    499 D          1        1998-08-24 00:00:00
#>  2 AR       14TH JUDICI… 1005-… RIFLE…        1 Each    499 D          1        1998-08-24 00:00:00
#>  3 AR       14TH JUDICI… 1005-… RIFLE…        1 Each    499 D          1        1998-08-24 00:00:00
#>  4 AR       14TH JUDICI… 1005-… RIFLE…        1 Each    499 D          1        1998-08-24 00:00:00
#>  5 AR       14TH JUDICI… 1005-… RIFLE…        1 Each    499 D          1        1998-08-24 00:00:00
#>  6 AR       14TH JUDICI… 1005-… RIFLE…        1 Each    499 D          1        1998-08-24 00:00:00
#>  7 SC       ABBEVILLE C… 1005-… RIFLE…        1 Each    749 D          1        2017-09-18 00:00:00
#>  8 SC       ABBEVILLE C… 1005-… RIFLE…        1 Each    749 D          1        2017-09-18 00:00:00
#>  9 SC       ABBEVILLE C… 1005-… RIFLE…        1 Each    749 D          1        2017-09-18 00:00:00
#> 10 SC       ABBEVILLE C… 1005-… RIFLE…        1 Each    749 D          1        2017-09-18 00:00:00
#> # … with 116,459 more rows
```

We can group these single rows together and create a new `quant_sum`
value by counting all the single rows together. The same applies for the
`value` variable.

This will reduce the number of rows but the total quantity and value
should be the same before and after.

``` r
sum(map_dbl(leso, nrow))
#> [1] 429088
for (i in seq_along(leso)) {
  pre <- sum(leso[[i]]$value)
  leso[[i]] <- leso[[i]] %>% 
    group_by_all() %>% 
    mutate(
      quantity = sum(quantity, na.rm = TRUE),
      value = sum(value, na.rm = TRUE)
    ) %>% 
    slice(1) %>% 
    ungroup()
  post <- sum(leso[[i]]$value)
  message(pre == post)
}
```

Now that we have been able to group together these single-quantity
records, we can bind together the three different files and remove
duplicate rows.

``` r
leso <- distinct(bind_rows(leso))
```

## Explore

``` r
glimpse(leso)
#> Rows: 128,802
#> Columns: 11
#> $ to_state     <chr> "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK…
#> $ to_station   <chr> "ALASKA DEPT OF PUBLIC SAFETY", "ALASKA DEPT OF PUBLIC SAFETY", "ALASKA DEP…
#> $ nsn          <chr> "1005-00-073-9421", "1005-00-073-9421", "1005-00-589-1271", "1005-01-630-95…
#> $ item         <chr> "RIFLE,5.56 MILLIMETER", "RIFLE,5.56 MILLIMETER", "RIFLE,7.62 MILLIMETER", …
#> $ quantity     <dbl> 4, 56, 4, 8, 50, 1, 1, 58, 2, 5, 1, 3, 2, 1, 2, 4, 1, 1, 4, 3, 2, 1, 8, 5, …
#> $ ui           <chr> "Each", "Each", "Each", "Each", "Each", "Each", "Each", "Each", "Kit", "Eac…
#> $ value        <dbl> 1996.00, 27944.00, 552.00, 13.56, 13.56, 10508.00, 129477.00, 2280.00, 450.…
#> $ demil_code   <chr> "D", "D", "D", "D", "D", "F", "D", "C", "B", "Q", "A", "A", "A", "A", "A", …
#> $ demil_ic     <chr> "1", "1", "1", "1", "1", "1", NA, "1", "3", "3", "1", "1", NA, NA, NA, "1",…
#> $ date         <dttm> 2002-08-26, 1998-01-22, 2000-04-04, 2017-04-04, 2017-04-04, 2016-09-26, 20…
#> $ station_type <chr> "State", "State", "State", "State", "State", "State", "State", "State", "St…
tail(leso)
#> # A tibble: 6 x 11
#>   to_state to_station nsn   item  quantity ui     value demil_code demil_ic date               
#>   <chr>    <chr>      <chr> <chr>    <dbl> <chr>  <dbl> <chr>      <chr>    <dttm>             
#> 1 WY       WASHAKIE … 2320… TRUC…        1 Each  192513 C          1        2018-03-12 00:00:00
#> 2 WY       WESTON CO… 1005… RIFL…        7 Each     966 D          1        1993-09-01 00:00:00
#> 3 WY       WY GAME  … 1005… RIFL…       10 Each    2060 D          1        2008-06-09 00:00:00
#> 4 WY       WY STATE … 1005… RIFL…        1 Each     138 D          1        1993-10-12 00:00:00
#> 5 WY       WY STATE … 1005… RIFL…        1 Each     138 D          1        1995-01-10 00:00:00
#> 6 WY       WY STATE … 1005… RIFL…        5 Each     690 D          1        1991-09-16 00:00:00
#> # … with 1 more variable: station_type <chr>
```

### Missing

Only one variable is missing any values. Nothing needs to be flagged.

``` r
col_stats(leso, count_na)
#> # A tibble: 11 x 4
#>    col          class      n     p
#>    <chr>        <chr>  <int> <dbl>
#>  1 to_state     <chr>      0 0    
#>  2 to_station   <chr>      0 0    
#>  3 nsn          <chr>      0 0    
#>  4 item         <chr>      0 0    
#>  5 quantity     <dbl>      0 0    
#>  6 ui           <chr>      0 0    
#>  7 value        <dbl>      0 0    
#>  8 demil_code   <chr>      0 0    
#>  9 demil_ic     <chr>  16655 0.129
#> 10 date         <dttm>     0 0    
#> 11 station_type <chr>  54810 0.426
```

### Categorical

``` r
col_stats(leso, n_distinct)
#> # A tibble: 11 x 4
#>    col          class      n         p
#>    <chr>        <chr>  <int>     <dbl>
#>  1 to_state     <chr>     53 0.000411 
#>  2 to_station   <chr>   6397 0.0497   
#>  3 nsn          <chr>  12927 0.100    
#>  4 item         <chr>   5846 0.0454   
#>  5 quantity     <dbl>    331 0.00257  
#>  6 ui           <chr>     37 0.000287 
#>  7 value        <dbl>  15988 0.124    
#>  8 demil_code   <chr>      7 0.0000543
#>  9 demil_ic     <chr>      9 0.0000699
#> 10 date         <dttm>  4870 0.0378   
#> 11 station_type <chr>      2 0.0000155
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
#>        0      120      584    28394     4493 51000000
mean(leso$value <= 0)
#> [1] 0.001645937
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
#> [1] 2
max(leso$date)
#> [1] "2020-12-30 UTC"
sum(leso$date > today())
#> [1] 1
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

1.  There are 128,802 records in the database.
2.  There are 0 duplicate records in the database.
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
#> 17.2M
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

| Column         | Type        | Definition                            |
| :------------- | :---------- | :------------------------------------ |
| `from_state`   | `character` | Manually added department “state”     |
| `from_dept`    | `character` | Manually added department name        |
| `to_state`     | `character` | Recieving station state               |
| `to_station`   | `character` | Recieving station name                |
| `nsn`          | `character` | Item’s unique “National Stock Number” |
| `item`         | `character` | Item name                             |
| `quantity`     | `double`    | Quantity of items transfered          |
| `ui`           | `character` | Units of item transfered              |
| `value`        | `double`    | Value of equipment transfered†        |
| `demil_code`   | `character` | Required level of destruction\*       |
| `demil_ic`     | `character` | Integrity Code\*                      |
| `date`         | `double`    | Date transfer was shipped             |
| `station_type` | `character` | Recieving station type                |
| `year`         | `double`    | Calendar year shipped                 |

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
