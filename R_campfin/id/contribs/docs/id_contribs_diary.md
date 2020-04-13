Idaho Contributions
================
Kiernan Nicholls
2020-04-13 17:00:33

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
6.  Create a five-digit ZIP Code called `zip`
7.  Create a `year` field from the transaction date
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
  tidyverse, # data manipulation
  snakecase, # column naming
  lubridate, # datetime strings
  magrittr, # pipe opperators
  gluedown, # printing markdown
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
  readxl, # read excel files
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

This data is obtained from the Michigan [Board of Elections
(BOE)](https://www.michigan.gov/sos/0,4670,7-127-1633---,00.html)
[Campaign Finance Reporting
(CFR)](https://www.michigan.gov/sos/0,4670,7-127-1633_8723---,00.html)
system. The data is provided as [annual ZIP archive
files](https://miboecfr.nictusa.com/cfr/dumpall/cfrdetail/) for the
years 1998 through 2020. These files are updated nightly.

## Import

To import the data for processing, we will have to download each archive
file and read them together into a single data frame object.

### Download

We will scrape the download page for every archive link, then
downloading each to a local directory.

``` r
raw_dir <- dir_create(here("id", "contribs", "data", "raw"))
raw_base <- "https://sos.idaho.gov/elect/finance/downloads.html"
raw_page <- read_html(raw_base)
raw_urls <- raw_page %>% 
  html_node("table") %>% 
  html_nodes("a") %>% 
  html_attr("href") %>% 
  str_subset("con") %>%
  str_subset("^2") %>% 
  str_c(dirname(raw_base), ., sep = "/")
raw_paths <- basename(str_replace(raw_urls, "(?<=\\d)/", "_"))
raw_paths <- path(raw_dir, raw_paths)
if (!all_files_new(raw_dir)) {
  download.file(raw_urls, raw_paths)
}
```

### Read

Each file has a different column order and names. We will first use
`purrr::map()` to use `readxl::read_excel()` and create a list of data
frames.

``` r
idc <- map(
  .x = raw_paths,
  .f = read_excel,
  col_types = "text"
)
```

Since the variety of column names is so great, we will have to chain
together a number of `stringr::str_replace()` functions to create some
consistency.

``` r
consistent_names <- function(nm) {
  nm %>% 
    to_snake_case() %>% 
    str_replace("contributor_", "contr_") %>% 
    str_replace("contrib_", "contr_") %>% 
    str_replace("contr_name", "contr_last") %>% 
    str_replace("^first_name$", "cand_first") %>% 
    str_replace("^last_name$", "cand_last") %>% 
    str_replace("^middle_name$", "cand_mi") %>% 
    str_replace("suf$", "suffix") %>% 
    str_replace("_mid$", "_mi") %>% 
    str_replace("middle", "mi") %>% 
    str_replace("_cp$", "_type") %>% 
    str_remove("_name$") %>% 
    str_replace("zipcode", "zip") %>% 
    str_replace("_st$", "_state") %>% 
    str_replace("mailing", "address") %>% 
    str_replace("line_1", "address_1") %>% 
    str_replace("line_2", "address_2") %>% 
    str_remove("^contr_") %>% 
    str_remove("^contributing_") %>% 
    str_remove("^contribution_") %>% 
    str_replace("^address$", "address_1") %>% 
    str_replace("^election_type$", "election")
}

new_names <- idc %>% 
  map(names) %>% 
  map(consistent_names)

for (i in seq_along(idc)) {
  names(idc[[i]]) <- new_names[[i]]
}
```

Now that each individual data frame has similar column names, we can use
`dplyr::bind_rows()` to bind all 20 data frames together.

``` r
idc <- bind_rows(idc, .id = "file")
```

Then, we can apply `readr::parse_guess()` to every column that were
previously all read as character vectors.

``` r
idc <- mutate_all(idc, parse_guess)
```

We also need to reorder and recode these variables to be consistent
across each year.

``` r
idc <- idc %>% 
  mutate_if(is_character, str_to_upper) %>% 
  mutate(
    office = office %>% 
      str_replace("REPRESENTATIVE", "REP."),
    cand_suffix = cand_suffix %>% 
      str_remove_all("[:punct:]"),
    party = party %>% 
      str_replace("OTHER", "OTH") %>% 
      str_replace("REPUBLICAN", "REP") %>% 
      str_replace("DEMOCRATIC", "DEM") %>% 
      str_replace("INDEPENDENT", "IND") %>% 
      str_replace("LIBERTARIAN", "LIB") %>% 
      str_replace("CONSTITUTION", "CON") %>% 
      str_replace("NON-PARTISAN", "NON"),
    type = type %>% 
      str_replace("COMPANY", "C") %>% 
      str_replace("PERSON", "P") %>% 
      str_replace("LOAN", "L") %>% 
      str_replace("IN KIND", "I"),
    election = election %>% 
      str_replace("GENERAL", "G") %>% 
      str_replace("PRIMARY", "P")
  )
```

``` r
count(idc, election)
#> # A tibble: 3 x 2
#>   election      n
#>   <chr>     <int>
#> 1 G         38147
#> 2 P         46091
#> 3 <NA>     390894
```

``` r
count_na(idc$date) # 782
#> [1] 782
slash_dates <- str_which(idc$date, "\\d+/\\d+/\\d{4}")
idc$date[slash_dates] <- as.character(mdy(idc$date[slash_dates]))
excel_dates <- str_which(idc$date, "[:punct:]", negate = TRUE)
idc$date[excel_dates] %>% 
  as.numeric() %>% 
  excel_numeric_to_date() %>% 
  as.character() -> idc$date[excel_dates]

idc$date <- as_date(idc$date)
count_na(idc$date) # 782
#> [1] 782
```

## Explore

``` r
head(idc)
#> # A tibble: 6 x 23
#>    file party cand_first cand_mi cand_last cand_suffix committee office district type  amount
#>   <dbl> <chr> <chr>      <chr>   <chr>     <chr>       <chr>     <chr>     <dbl> <chr>  <dbl>
#> 1     1 DEM   CHRISTOPH… G       ABERNATHY <NA>        <NA>      STATE…       29 <NA>    1000
#> 2     1 DEM   CHRISTOPH… G       ABERNATHY <NA>        <NA>      STATE…       29 <NA>     950
#> 3     1 DEM   CHRISTOPH… G       ABERNATHY <NA>        <NA>      STATE…       29 <NA>    2000
#> 4     1 DEM   CHRISTOPH… G       ABERNATHY <NA>        <NA>      STATE…       29 <NA>     200
#> 5     1 DEM   CHRISTOPH… G       ABERNATHY <NA>        <NA>      STATE…       29 <NA>     286
#> 6     1 DEM   CHRISTOPH… G       ABERNATHY <NA>        <NA>      STATE…       29 <NA>     500
#> # … with 12 more variables: date <date>, last <chr>, first <chr>, mi <chr>, suffix <chr>,
#> #   address_1 <chr>, address_2 <chr>, city <chr>, state <chr>, zip <chr>, country <chr>,
#> #   election <chr>
tail(idc)
#> # A tibble: 6 x 23
#>    file party cand_first cand_mi cand_last cand_suffix committee office district type  amount
#>   <dbl> <chr> <chr>      <chr>   <chr>     <chr>       <chr>     <chr>     <dbl> <chr>  <dbl>
#> 1    20 UNK   <NA>       <NA>    <NA>      <NA>        WELLS FA… <NA>         NA C         10
#> 2    20 UNK   <NA>       <NA>    <NA>      <NA>        WELLS FA… <NA>         NA C         10
#> 3    20 UNK   <NA>       <NA>    <NA>      <NA>        WELLS FA… <NA>         NA C         10
#> 4    20 UNK   <NA>       <NA>    <NA>      <NA>        WELLS FA… <NA>         NA C       2000
#> 5    20 UNK   <NA>       <NA>    <NA>      <NA>        WELLS FA… <NA>         NA C          0
#> 6    20 UNK   <NA>       <NA>    <NA>      <NA>        WELLS FA… <NA>         NA C          0
#> # … with 12 more variables: date <date>, last <chr>, first <chr>, mi <chr>, suffix <chr>,
#> #   address_1 <chr>, address_2 <chr>, city <chr>, state <chr>, zip <chr>, country <chr>,
#> #   election <chr>
glimpse(sample_frac(idc))
#> Rows: 475,132
#> Columns: 23
#> $ file        <dbl> 4, 1, 6, 2, 11, 17, 5, 2, 10, 10, 5, 13, 6, 11, 2, 1, 13, 8, 16, 5, 13, 1, 4…
#> $ party       <chr> "OTH", "REP", "OTH", "OTH", "DEM", "REP", "DEM", "OTH", "UNK", "UNK", "DEM",…
#> $ cand_first  <chr> NA, "TOM", NA, NA, "BOB", "JOHN", "JANIE", NA, NA, NA, "BRANDEN", "DEAN", NA…
#> $ cand_mi     <chr> NA, NA, NA, NA, NA, "C.", NA, NA, NA, NA, "J", "L.", NA, "L.", NA, NA, NA, N…
#> $ cand_last   <chr> NA, "KEALEY", NA, NA, "SOLOMON", "ANDREASON", "WARD-ENGELKING", NA, NA, NA, …
#> $ cand_suffix <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ committee   <chr> "FEAPAC (FARMERS EMPLOYEES AND AGENTS POLITICAL ACTION COMMITTEE)", NA, "BOI…
#> $ office      <chr> NA, "STATE TREASURER", NA, NA, "STATE REP., POSITION A", "STATE SENATOR", "S…
#> $ district    <dbl> NA, NA, NA, NA, 11, 15, 18, NA, NA, NA, NA, 26, NA, 26, NA, NA, 17, NA, NA, …
#> $ type        <chr> "P", NA, "P", NA, "C", "C", "P", NA, "C", "C", "P", "C", "P", "C", NA, NA, "…
#> $ amount      <dbl> 5.0, 250.0, 10.0, 200.0, 500.0, 100.0, 60.0, 10.0, 30.0, 10.0, 709.8, 300.0,…
#> $ date        <date> 2015-10-15, 2017-12-27, 2013-10-01, 2017-07-04, 2008-11-01, 2002-05-31, 201…
#> $ last        <chr> "NOORDA-STRADINGER", "CREIGHTON", "MCCULLOGH", "WEIBER", "FAMILIES FOR A BET…
#> $ first       <chr> "DEVERY", "SKIP", "JJ", "TRISHA", NA, NA, "BETTY", "BENJAMIN", "ROBERT", "LO…
#> $ mi          <chr> NA, NA, NA, NA, NA, NA, NA, "ROBERT", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ suffix      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ address_1   <chr> "804 REDMAN ST", "2181 S. PEBBLECREEK LN", "9989 W DYLAN CT", "4980 COLLISET…
#> $ address_2   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ city        <chr> "CHUBBUCK", "BOISE", "STAR", "BOISE", "BOISE", "BOISE", "BOISE", "HAYDEN", "…
#> $ state       <chr> "ID", "ID", "ID", "ID", "ID", "ID", "ID", "ID", "ID", "ID", "ID", "DC", "ID"…
#> $ zip         <chr> "83202", "83706", "83669", "83703", "83703", "83702", "83713", "83835", "838…
#> $ country     <chr> "USA", "USA", "USA", "USA", NA, NA, "USA", "USA", NA, NA, "USA", NA, "USA", …
#> $ election    <chr> NA, "P", NA, NA, NA, NA, "G", NA, NA, NA, "P", NA, NA, NA, NA, "P", NA, NA, …
```

We should first identify which columns are missing the kinds of key
information we need to properly identify all parties to a contribution.
We can do this with `campfin::flag_na()` after creating a new

``` r
col_stats(idc, count_na)
#> # A tibble: 23 x 4
#>    col         class       n        p
#>    <chr>       <chr>   <int>    <dbl>
#>  1 file        <dbl>       0 0       
#>  2 party       <chr>     717 0.00151 
#>  3 cand_first  <chr>  271011 0.570   
#>  4 cand_mi     <chr>  409038 0.861   
#>  5 cand_last   <chr>  270975 0.570   
#>  6 cand_suffix <chr>  474552 0.999   
#>  7 committee   <chr>  204157 0.430   
#>  8 office      <chr>  270975 0.570   
#>  9 district    <dbl>  345562 0.727   
#> 10 type        <chr>   75127 0.158   
#> 11 amount      <dbl>       0 0       
#> 12 date        <date>    782 0.00165 
#> 13 last        <chr>     208 0.000438
#> 14 first       <chr>  103142 0.217   
#> 15 mi          <chr>  439519 0.925   
#> 16 suffix      <chr>  474371 0.998   
#> 17 address_1   <chr>    1379 0.00290 
#> 18 address_2   <chr>  460019 0.968   
#> 19 city        <chr>     967 0.00204 
#> 20 state       <chr>      78 0.000164
#> 21 zip         <chr>    2897 0.00610 
#> 22 country     <chr>  206846 0.435   
#> 23 election    <chr>  390894 0.823
```

``` r
idc <- idc %>% 
  # combine cand and comm names in new col
  mutate(recip = coalesce(cand_last, committee)) %>% 
  flag_na(last, recip, date, amount)

sum(idc$na_flag)
#> [1] 808
mean(idc$na_flag)
#> [1] 0.00170058
```

Records that are entirely duplicated at least once across all columns
should also be identified with `campfin::flag_dupes()`. The first
occurrence of the record is not flagged, but all subsequent duplicates
are. Not all these records are true duplicates, since it is technically
possible to make the same contribution to the same person on the same
day for the same amount.

``` r
idc <- flag_dupes(idc, everything(), .check = TRUE)
sum(idc$dupe_flag)
#> [1] 5986
mean(idc$dupe_flag)
#> [1] 0.0125986
idc %>% 
  filter(dupe_flag) %>% 
  select(recip, last, date, amount)
#> # A tibble: 5,986 x 4
#>    recip     last                                                   date       amount
#>    <chr>     <chr>                                                  <date>      <dbl>
#>  1 ABERNATHY IRON WORKERS DISTRICT COUNCIL OF THE PACIFIC NORTHWEST 2018-07-05    500
#>  2 ABERNATHY IRON WORKERS DISTRICT COUNCIL OF THE PACIFIC NORTHWEST 2018-07-05    500
#>  3 ABERNATHY LANDON                                                 2018-06-12    500
#>  4 ABERNATHY LANDON                                                 2018-06-12    500
#>  5 ADDIS     ADDIS                                                  2018-09-30      0
#>  6 ADDIS     ADDIS                                                  2018-09-30      0
#>  7 AHLQUIST  SCARLETT IV                                            2017-09-14   1000
#>  8 AHLQUIST  SCARLETT IV                                            2017-09-14   1000
#>  9 AHLQUIST  WRIGHT                                                 2017-08-24   1000
#> 10 AHLQUIST  WRIGHT                                                 2017-08-24   1000
#> # … with 5,976 more rows
```

### Categorical

``` r
col_stats(idc, n_distinct)
#> # A tibble: 26 x 4
#>    col         class       n          p
#>    <chr>       <chr>   <int>      <dbl>
#>  1 file        <dbl>      20 0.0000421 
#>  2 party       <chr>      13 0.0000274 
#>  3 cand_first  <chr>     648 0.00136   
#>  4 cand_mi     <chr>     137 0.000288  
#>  5 cand_last   <chr>    1091 0.00230   
#>  6 cand_suffix <chr>       5 0.0000105 
#>  7 committee   <chr>     517 0.00109   
#>  8 office      <chr>      16 0.0000337 
#>  9 district    <dbl>      36 0.0000758 
#> 10 type        <chr>       7 0.0000147 
#> 11 amount      <dbl>   12111 0.0255    
#> 12 date        <date>   7182 0.0151    
#> 13 last        <chr>   47290 0.0995    
#> 14 first       <chr>   19848 0.0418    
#> 15 mi          <chr>    1020 0.00215   
#> 16 suffix      <chr>      12 0.0000253 
#> 17 address_1   <chr>  108191 0.228     
#> 18 address_2   <chr>    1526 0.00321   
#> 19 city        <chr>    3372 0.00710   
#> 20 state       <chr>      91 0.000192  
#> 21 zip         <chr>   10006 0.0211    
#> 22 country     <chr>       8 0.0000168 
#> 23 election    <chr>       3 0.00000631
#> 24 recip       <chr>    1606 0.00338   
#> 25 na_flag     <lgl>       2 0.00000421
#> 26 dupe_flag   <lgl>       2 0.00000421
```

![](../plots/bar_office-1.png)<!-- -->

![](../plots/bar_party-1.png)<!-- -->

![](../plots/type_party-1.png)<!-- -->

### Amounts

``` r
summary(idc$amount)
#>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
#> -100000.0      20.0      90.0     352.1     200.0 2000000.0
mean(idc$amount <= 0)
#> [1] 0.002727663
```

![](../plots/amount_histogram-1.png)<!-- -->

![](../plots/amount_violin-1.png)<!-- -->

### Dates

``` r
idc <- mutate(idc, year = year(date))
```

``` r
min(idc$date, na.rm = TRUE)
#> [1] "1930-07-06"
max(idc$date, na.rm = TRUE)
#> [1] "3831-12-01"
idc <- mutate(idc, date_flag = date > today() | year < 1999 | is.na(date))
count_na(idc$date) # 782
#> [1] 782
sum(idc$date_flag) # 835 = 53
#> [1] 835
mean(idc$date_flag)
#> [1] 0.001757406
```

``` r
x <- idc$date[idc$date_flag & !is.na(idc$date)]
x <- str_replace(x, "^202(?=[^2])", "201")
x <- str_replace(x, "^19([^9])", "199")
x <- str_replace(x, "^2([^2])", "20")
x <- str_replace(x, "2061", "2016")
x[which(x > today() | year(x) < 1999)] <- NA
idc$date[idc$date_flag & !is.na(idc$date)] <- as_date(x)
idc <- mutate(
  .data = idc,
  date_flag = date > today() | year < 1999 | is.na(date),
  year = year(date)
)
count_na(idc$date) # 807
#> [1] 807
sum(idc$date_flag) # 807
#> [1] 807
```

For some reason there no records from 2005 to 2010.

![](../plots/year_bar-1.png)<!-- -->![](../plots/year_bar-2.png)<!-- -->

We know these files were read by comparing the `file` variable to the
urls downloaded. For the records loaded from the file downloaded from
2008, the year of the `date` variable seems to primarily be from 2003
and 2004.

``` r
idc %>% 
  filter(file %in% str_which(raw_urls, "2008")) %>% 
  count(year = year(date))
#> # A tibble: 8 x 2
#>    year     n
#>   <dbl> <int>
#> 1  2002     2
#> 2  2004     9
#> 3  2005     5
#> 4  2006     8
#> 5  2007  8642
#> 6  2008 22103
#> 7  2009    51
#> 8    NA    32
```

## Wrangle

### Address

``` r
idc <- idc %>% 
  # combine street addr
  unite(
    col = address_full,
    starts_with("address_"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  # normalize combined addr
  mutate(
    address_norm = normal_address(
      address = address_full,
      abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-address_full)
```

``` r
idc %>% 
  select(contains("address")) %>% 
  distinct() %>% 
  sample_frac()
#> # A tibble: 109,474 x 3
#>    address_1             address_2 address_norm       
#>    <chr>                 <chr>     <chr>              
#>  1 3706 SHERWOOD DR.     <NA>      3706 SHERWOOD DR   
#>  2 2025 E 17TH           <NA>      2025 E 17 TH       
#>  3 1384 E GRIFFITH CT    <NA>      1384 E GRIFFITH CT 
#>  4 HC 75 BOX 139 B       <NA>      HC 75 BOX 139 B    
#>  5 5400 N RIFFLE WAY     <NA>      5400 N RIFFLE WAY  
#>  6 753 HOMER AVE.        <NA>      753 HOMER AVE      
#>  7 4304 W DEER TRAIL LN  <NA>      4304 W DEER TRL LN 
#>  8 36 HILLSIDE RANCH RD  <NA>      36 HILLSIDE RNCH RD
#>  9 9901 GLENROCK         <NA>      9901 GLENROCK      
#> 10 2375 E. REMINSTON RD. <NA>      2375 E REMINSTON RD
#> # … with 109,464 more rows
```

### ZIP

``` r
idc <- idc %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  idc$zip,
  idc$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 zip        0.945      10006 0.00610 26136   5348
#> 2 zip_norm   0.999       5293 0.00610   551    356
```

### State

``` r
idc <- idc %>% 
  mutate(
    state_norm = normal_state(
      state = state,
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = NULL
    )
  )
```

``` r
progress_table(
  idc$state,
  idc$state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage      prop_in n_distinct  prop_na n_out n_diff
#>   <chr>        <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 state         1.00         91 0.000164   114     36
#> 2 state_norm    1.00         79 0.000276    61     24
```

### City

``` r
idc <- idc %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("ID", "DC", "IDAHO"),
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

``` r
idc <- idc %>%
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
      condition = match_abb | match_dist == 1,
      true = city_match,
      false = city_norm
    )
  ) %>% 
  select(
    -match_abb,
    -match_dist,
    -city_match
  )
```

``` r
many_city <- c(valid_city, extra_city)
progress_table(
  idc$city_raw,
  idc$city_norm,
  idc$city_swap,
  compare = many_city
)
#> # A tibble: 3 x 6
#>   stage     prop_in n_distinct prop_na n_out n_diff
#>   <chr>       <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 city_raw    0.954       3372 0.00204 21885    717
#> 2 city_norm   0.957       3275 0.00204 20515    610
#> 3 city_swap   0.997       2805 0.00884  1381    167
```

``` r
idc %>% 
  filter(city_swap %out% many_city) %>% 
  count(city_swap, sort = TRUE)
#> # A tibble: 167 x 2
#>    city_swap                  n
#>    <chr>                  <int>
#>  1 <NA>                    4199
#>  2 HAYDEN LAKE              630
#>  3 DALTON GARDENS           285
#>  4 PRIEST LAKE               49
#>  5 WINSTONSALEM              34
#>  6 HIDDEN SPRINGS            33
#>  7 RESEARCH TRIANGLE PARK    26
#>  8 CHUBUCK                   20
#>  9 COEUR DALENE              17
#> 10 COUER DALENE              16
#> # … with 157 more rows
```

## Conclude

1.  There are 475,132 records in the database.
2.  There are 5,986 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 808 records missing either recipient or date.
5.  Consistency in goegraphic data has been improved with
    `campfin::normal_*()`.
6.  The 5-digit `zip_norm` variable has been created with
    `campfin::normal_zip(df$zip)`.
7.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
idc <- idc %>% 
  select(
    -city_norm,
    city_norm = city_swap
  ) %>%
  rename_at(
    .vars = vars(ends_with("norm")),
    .funs = ~str_replace(., "_(.*)", "_clean")
  ) %>% 
  rename(city = city_raw)
```

``` r
clean_dir <- dir_create(here("id", "contribs", "data", "clean"))
clean_path <- path(clean_dir, "id_contribs_clean.csv")
write_csv(idc, path = clean_path, na = "")
file_size(clean_path)
#> 90.8M
```
