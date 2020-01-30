Michigan Contributions
================
Kiernan Nicholls
2020-01-29 23:23:21

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
  lubridate, # datetime strings
  magrittr, # pipe opperators
  gluedown, # printing markdown
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

This data is obtained from the Michigan Board of Elections (BOE)
Campaign Finance Reporting (CFR) system. The data is provided as annual
ZIP archives.

> Record layout of contributions. Files are named by statement year.
> Larger files are split and numbered to make them easier to work with.
> In these cases the column header row will only exist in the first (00)
> file.

| Variable          | Description                                                                                      |
| :---------------- | :----------------------------------------------------------------------------------------------- |
| `doc_seq_no`      | Unique BOE document sequence number of the filed campaign statement                              |
| `page_no`         | If filed on paper, the physical page number the transaction appears on, otherwise zero           |
| `contribution_id` | Unique number of the transaction, within the campaign statement and amendments                   |
| `cont_detail_id`  | Unique number used to further break down some types of transactions with supplemental informati… |
| `doc_stmnt_year`  | The calendar year that this statement was required by the BOE                                    |
| `doc_type_desc`   | The type of statement that this contribution is attached to                                      |
| `com_legal_name`  | Legal Name of the committee receiving the contribution                                           |
| `common_name`     | Commonly known shorter name of the committee. May be deprecated in the future.                   |
| `cfr_com_id`      | Unique committee ID\# of the receiving committee in the BOE database                             |
| `com_type`        | Type of committee receiving the contribution                                                     |
| `can_first_name`  | First name of the candidate (if applicable) benefitting from the contribution                    |
| `can_last_name`   | Last name of the candidate (if applicable) benefitting from the contribution                     |
| `contribtype`     | Type of contribution received                                                                    |
| `f_name`          | First name of the individual contributor                                                         |
| `l_name`          | Last name of the contributor OR the name of the organization that made the contribution          |
| `address`         | Street address of the contributor                                                                |
| `city`            | City of the contributor                                                                          |
| `state`           | State of the contributor                                                                         |
| `zip`             | Zipcode of the contributor                                                                       |
| `occupation`      | Occupation of the contributor                                                                    |
| `employer`        | Employer of the contributor                                                                      |
| `received_date`   | Date the contribution was received                                                               |
| `amount`          | Dollar amount or value of the contribution                                                       |
| `aggregate`       | Cumulative dollar amount of contributions made to this committee during this period up to the d… |
| `extra_desc`      | Extra descriptive information for the transaction                                                |
| `RUNTIME`         | Indicates the time these transactions were exported from the BOE database. Header only.          |

## Import

### Download

``` r
raw_dir <- dir_create(here("mi", "contribs", "data", "raw"))
raw_base <- "https://miboecfr.nictusa.com/cfr/dumpall/cfrdetail/"
raw_page <- read_html(raw_base)
raw_urls <- raw_page %>% 
  html_node("table") %>% 
  html_nodes("a") %>% 
  html_attr("href") %>% 
  str_subset("contributions") %>% 
  str_c(raw_base, ., sep = "/")
raw_paths <- path(raw_dir, basename(raw_urls))
if (!all(this_file_new(raw_paths))) {
  download.file(raw_urls, raw_paths)
}
```

### Read

``` r
mic_names <- str_split(read_lines(raw_paths[1])[1], "\t")[[1]]
mic_names <- mic_names[-length(mic_names)]
mic_names[length(mic_names)] <- "runtime"
```

``` r
mic <- vroom(
  file = raw_paths,
  delim = "\t",
  skip = 1,
  col_names = mic_names,
  col_types = cols(
    .default = col_character(),
    page_no = col_integer(),
    doc_stmnt_year = col_integer(),
    received_date = col_date_usa(),
    amount = col_double(),
    aggregate = col_double(),
    runtime = col_skip()
  )
)
```

``` r
mic <- map_dfr(
  .x = raw_paths,
  .f = read_delim,
  escape_double = FALSE,
  escape_backslash = FALSE,
  delim = "\t",
  skip = 1,
  col_names = mic_names,
  col_types = cols(
    .default = col_character(),
    page_no = col_integer(),
    doc_stmnt_year = col_integer(),
    received_date = col_date_usa(),
    amount = col_double(),
    aggregate = col_double(),
    runtime = col_skip()
  )
)
```

## Explore

``` r
head(mic)
#> # A tibble: 6 x 25
#>   doc_seq_no page_no contribution_id cont_detail_id doc_stmnt_year doc_type_desc com_legal_name
#>   <chr>        <int> <chr>           <chr>                   <int> <chr>         <chr>         
#> 1 148736           1 1               0                        1998 ANNUAL CS     COMMITTEE TO …
#> 2 148736           1 2               0                        1998 ANNUAL CS     COMMITTEE TO …
#> 3 148736           1 3               0                        1998 ANNUAL CS     COMMITTEE TO …
#> 4 148736           1 4               0                        1998 ANNUAL CS     COMMITTEE TO …
#> 5 148736           2 1               0                        1998 ANNUAL CS     COMMITTEE TO …
#> 6 148736           2 2               0                        1998 ANNUAL CS     COMMITTEE TO …
#> # … with 18 more variables: common_name <chr>, cfr_com_id <chr>, com_type <chr>,
#> #   can_first_name <chr>, can_last_name <chr>, contribtype <chr>, f_name <chr>,
#> #   l_name_or_org <chr>, address <chr>, city <chr>, state <chr>, zip <chr>, occupation <chr>,
#> #   employer <chr>, received_date <date>, amount <dbl>, aggregate <dbl>, extra_desc <chr>
tail(mic)
#> # A tibble: 6 x 25
#>   doc_seq_no page_no contribution_id cont_detail_id doc_stmnt_year doc_type_desc com_legal_name
#>   <chr>        <int> <chr>           <chr>                   <int> <chr>         <chr>         
#> 1 490075           0 4221            0                        2020 ANNUAL CS     COMMITTEE TO …
#> 2 490075           0 4223            0                        2020 ANNUAL CS     COMMITTEE TO …
#> 3 490075           0 4226            0                        2020 ANNUAL CS     COMMITTEE TO …
#> 4 490075           0 4229            0                        2020 ANNUAL CS     COMMITTEE TO …
#> 5 490075           0 4232            0                        2020 ANNUAL CS     COMMITTEE TO …
#> 6 490075           0 4235            0                        2020 ANNUAL CS     COMMITTEE TO …
#> # … with 18 more variables: common_name <chr>, cfr_com_id <chr>, com_type <chr>,
#> #   can_first_name <chr>, can_last_name <chr>, contribtype <chr>, f_name <chr>,
#> #   l_name_or_org <chr>, address <chr>, city <chr>, state <chr>, zip <chr>, occupation <chr>,
#> #   employer <chr>, received_date <date>, amount <dbl>, aggregate <dbl>, extra_desc <chr>
glimpse(mic)
#> Observations: 15,998,081
#> Variables: 25
#> $ doc_seq_no      <chr> "148736", "148736", "148736", "148736", "148736", "148736", "148736", "1…
#> $ page_no         <int> 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 1, 1, …
#> $ contribution_id <chr> "1", "2", "3", "4", "1", "2", "3", "4", "1", "2", "3", "4", "1", "2", "3…
#> $ cont_detail_id  <chr> "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0…
#> $ doc_stmnt_year  <int> 1998, 1998, 1998, 1998, 1998, 1998, 1998, 1998, 1998, 1998, 1998, 1998, …
#> $ doc_type_desc   <chr> "ANNUAL CS", "ANNUAL CS", "ANNUAL CS", "ANNUAL CS", "ANNUAL CS", "ANNUAL…
#> $ com_legal_name  <chr> "COMMITTEE TO ELECT JUD GILBERT", "COMMITTEE TO ELECT JUD GILBERT", "COM…
#> $ common_name     <chr> "COMM TO ELECT JUD GILBERT", "COMM TO ELECT JUD GILBERT", "COMM TO ELECT…
#> $ cfr_com_id      <chr> "506799", "506799", "506799", "506799", "506799", "506799", "506799", "5…
#> $ com_type        <chr> "CAN", "CAN", "CAN", "CAN", "CAN", "CAN", "CAN", "CAN", "CAN", "CAN", "C…
#> $ can_first_name  <chr> "JUDSON", "JUDSON", "JUDSON", "JUDSON", "JUDSON", "JUDSON", "JUDSON", "J…
#> $ can_last_name   <chr> "GILBERT II", "GILBERT II", "GILBERT II", "GILBERT II", "GILBERT II", "G…
#> $ contribtype     <chr> "DIRECT                        ", "DIRECT                        ", "DIR…
#> $ f_name          <chr> "JUDSON              ", "MARY                ", NA, "DAN                …
#> $ l_name_or_org   <chr> "GILBERT                             ", "GILBERT                        …
#> $ address         <chr> "1405 ST CLAIR RIVER DR", "1405 ST CLAIR RIVER DR", "PO BO 27158", "9780…
#> $ city            <chr> "ALGONAC             ", "ALGONAC             ", "LASNING             ", …
#> $ state           <chr> "MI", "MI", "MI", "MI", "MI", "MI", "MI", "MI", "MI", "MI", "MI", "MI", …
#> $ zip             <chr> "48001     ", "48001     ", "48909     ", "48001     ", "48054     ", "4…
#> $ occupation      <chr> "FUNERAL DIRECTOR", "RETIRED", NA, "RETIRED", NA, "FUNERAL DIRECTOR", "R…
#> $ employer        <chr> "GILBERT FUNERAL HOME INC", NA, NA, NA, NA, "GILBERT FUNERAL HOME INC", …
#> $ received_date   <date> 1997-07-17, 1997-07-17, 1997-08-29, 1997-09-08, 1997-09-07, 1997-09-09,…
#> $ amount          <dbl> 500, 500, 1000, 500, 500, 3500, 100, 500, 500, 100, 100, 100, 100, 250, …
#> $ aggregate       <dbl> 500, 500, 1000, 500, 500, 3500, 100, 500, 500, 100, 200, 100, 100, 250, …
#> $ extra_desc      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
```

``` r
summary(mic$amount)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
#> -195000       3       7      95      20 9175000    4664
```

![](../plots/amount_histogram-1.png)<!-- -->

``` r
mic <- mutate(mic, received_year = year(received_date))
```

``` r
min(mic$received_date, na.rm = TRUE)
#> [1] "999-01-14"
sum(mic$received_year < 1998, na.rm = TRUE)
#> [1] 27478
max(mic$received_date, na.rm = TRUE)
#> [1] "2206-06-01"
sum(mic$received_date > today(), na.rm = TRUE)
#> [1] 4
```

![](../plots/year_bar-1.png)<!-- -->

## Wrangle

### Address

``` r
mic <- mic %>% 
  mutate(
    address_norm = normal_address(
      address = address,
      abbs = usps_street,
      na_rep = TRUE
    )
  )
```

``` r
mic %>% 
  select(contains("address")) %>% 
  distinct() %>% 
  sample_n(10)
#> # A tibble: 10 x 2
#>    address              address_norm                 
#>    <chr>                <chr>                        
#>  1 1885 S COLLEGE       1885 SOUTH COLLEGE           
#>  2 1912 LARDIE RD       1912 LARDIE ROAD             
#>  3 28 S MICHIGAN RD     28 SOUTH MICHIGAN ROAD       
#>  4 3261 S. SHOREVIEW    3261 SOUTH SHOREVIEW         
#>  5 501 HAROLD STREET    501 HAROLD STREET            
#>  6 1784 STANWICK CT SE  1784 STANWICK COURT SOUTHEAST
#>  7 2530 DEEP OAK CT     2530 DEEP OAK COURT          
#>  8 5267 WRIGHT WAY E    5267 WRIGHT WAY EAST         
#>  9 2749 EAST M-21       2749 EAST M 21               
#> 10 3000 DUNE RIDGE PATH 3000 DUNE RIDGE PATH
```

### ZIP

``` r
mic <- mic %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  mic$zip,
  mic$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na    n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl>    <dbl>  <dbl>
#> 1 zip        0         487271 0.00159 15972619 487271
#> 2 zip_norm   0.997      27123 0.00163    40151   2136
```

### State

``` r
mic <- mic %>% 
  mutate(
    state_norm = normal_state(
      state = state,
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = valid_state
    )
  )
```

``` r
progress_table(
  mic$state,
  mic$state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage      prop_in n_distinct prop_na n_out n_diff
#>   <chr>        <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 state         1.00        129 0.00107  4996     70
#> 2 state_norm    1            59 0.00138     0      1
```

### City

``` r
mic <- mic %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("MI", "DC", "MICHIGAN"),
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

``` r
mic <- mic %>% 
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
  )
```

``` r
progress_table(
  mic$city_raw,
  mic$city_norm,
  mic$city_swap,
  compare = valid_city
)
#> # A tibble: 3 x 6
#>   stage       prop_in n_distinct  prop_na    n_out n_diff
#>   <chr>         <dbl>      <dbl>    <dbl>    <dbl>  <dbl>
#> 1 city_raw  0.0000126      27298 0.000989 15982052  27284
#> 2 city_norm 0.944          25282 0.00148    895070  13435
#> 3 city_swap 0.955          17194 0.00531    720512   5367
```

## Conclude

1.  There are `nrow(df)` records in the database.
2.  There are `sum(mic$dupe_flag)` duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are `sum(mic$na_flag)` records missing either recipient or
    date.
5.  Consistency in goegraphic data has been improved with
    `campfin::normal_*()`.
6.  The 5-digit `zip_norm` variable has been created with
    `campfin::normal_zip(mic$zip)`.
7.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
proc_dir <- dir_create(here("mi", "contribs", "data", "processed"))
```

``` r
mic %>% 
  write_csv(
    path = glue("{proc_dir}/df_type_clean.csv"),
    na = ""
  )
```
