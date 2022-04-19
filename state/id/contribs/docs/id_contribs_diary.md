Idaho Contributions
================
Kiernan Nicholls
2020-10-26 13:45:53

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Join](#join)
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
  aws.s3, # upload to aws s3
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
#> [1] "/home/kiernan/Code/tap/R_campfin"
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
idc <- bind_rows(idc, .id = "source_file")
idc <- relocate(idc, source_file, .after = last_col())
idc$source_file <- basename(raw_paths)[as.integer(idc$source_file)]
```

Then, we can use `readr::type_convert()` to parse our character columns.

``` r
idc <- type_convert(
  df = idc,
  col_types = cols(
    .default = col_character(),
    amount = col_double()
  )
)
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

## Join

Contributions for 2020 can be downloaded as an Excel file from the Idaho
Secretary of State’s office [campaign public
portal](https://elections.sos.idaho.gov/TED/CampaignPublicPortal/Contributions.aspx).

``` r
idn <- read_excel(
  path = path(raw_dir, "2020_Contributions.xlsx"),
  .name_repair = make_clean_names
)
```

Most of the columns in this data overlap with the columns in the older
data.

``` r
prop_in(names(idn), names(idc))
#> [1] 0.8333333
setdiff(names(idn), names(idc))
#> [1] "amend"    "con_type"
```

We can combine the two data sources into a single dataframe.

``` r
idc <- bind_rows(idc, idn, .id = "source_type")
idc <- relocate(idc, source_type, .after = last_col())
idc$source_type <- c("old", "new")[as.integer(idc$source_type)]
count(idc, source_type)
#> # A tibble: 2 x 2
#>   source_type      n
#>   <chr>        <int>
#> 1 new          42228
#> 2 old         475132
rm(idn)
```

## Explore

``` r
glimpse(idc)
#> Rows: 517,360
#> Columns: 26
#> $ party       <chr> "DEM", "DEM", "DEM", "DEM", "DEM", "DEM", "DEM", "DEM", "DEM", "DEM", "DEM",…
#> $ cand_first  <chr> "CHRISTOPHER", "CHRISTOPHER", "CHRISTOPHER", "CHRISTOPHER", "CHRISTOPHER", "…
#> $ cand_mi     <chr> "G", "G", "G", "G", "G", "G", "G", "G", "G", "G", "G", "G", "G", "G", "G", "…
#> $ cand_last   <chr> "ABERNATHY", "ABERNATHY", "ABERNATHY", "ABERNATHY", "ABERNATHY", "ABERNATHY"…
#> $ cand_suffix <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ committee   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ office      <chr> "STATE REP., POSITION A", "STATE REP., POSITION A", "STATE REP., POSITION A"…
#> $ district    <chr> "29", "29", "29", "29", "29", "29", "29", "29", "29", "29", "29", "29", "29"…
#> $ type        <chr> NA, NA, NA, NA, NA, NA, "I", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ amount      <dbl> 1000, 950, 2000, 200, 286, 500, 25, 1000, 750, 500, 500, 500, 325, 325, 503,…
#> $ date        <dttm> 2018-08-31, 2018-09-02, 2018-07-25, 2018-10-26, 2018-10-26, 2018-09-11, 201…
#> $ last        <chr> "AFL-CIO", "AFL-CIO", "BANNOCK COUNTY DEMOCRATIC", "BROTHER OF LOCOMOTIVE 70…
#> $ first       <chr> NA, NA, NA, NA, "JENNIFER", "MATHEW", "UNKNOWN", NA, NA, NA, NA, NA, "RODNEY…
#> $ mi          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "E", NA, NA, NA, NA, NA, NA,…
#> $ suffix      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ address_1   <chr> "PO BOX 2238", "PO BOX 2238", "P.O. BOX 1563", "7061 E PLEASANT VALEEY RD", …
#> $ address_2   <chr> NA, NA, NA, NA, NA, "ID", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ city        <chr> "BOISE", "BOISE", "POCATELLO", "INDEPENDENCE", "POCATELLO", "BOISE", "PUEBLO…
#> $ state       <chr> "ID", "ID", "ID", "OH", "ID", "ID", "CO", "WA", "ID", "WA", "OR", "OR", "ID"…
#> $ zip         <chr> "83701-2238", "83701-2238", "83204", "44131", "83204", "83702", "81007", "98…
#> $ country     <chr> "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA",…
#> $ election    <chr> "G", "G", "G", "G", "G", "G", "G", "G", "G", "G", "G", "G", "G", "G", "G", "…
#> $ source_file <chr> "2018_CANDIDATE_CONTRIBUTIONS.XLSX", "2018_CANDIDATE_CONTRIBUTIONS.XLSX", "2…
#> $ amend       <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ con_type    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ source_type <chr> "old", "old", "old", "old", "old", "old", "old", "old", "old", "old", "old",…
head(idc)
#> # A tibble: 6 x 26
#>   party cand_first cand_mi cand_last cand_suffix committee office district type  amount
#>   <chr> <chr>      <chr>   <chr>     <chr>       <chr>     <chr>  <chr>    <chr>  <dbl>
#> 1 DEM   CHRISTOPH… G       ABERNATHY <NA>        <NA>      STATE… 29       <NA>    1000
#> 2 DEM   CHRISTOPH… G       ABERNATHY <NA>        <NA>      STATE… 29       <NA>     950
#> 3 DEM   CHRISTOPH… G       ABERNATHY <NA>        <NA>      STATE… 29       <NA>    2000
#> 4 DEM   CHRISTOPH… G       ABERNATHY <NA>        <NA>      STATE… 29       <NA>     200
#> 5 DEM   CHRISTOPH… G       ABERNATHY <NA>        <NA>      STATE… 29       <NA>     286
#> 6 DEM   CHRISTOPH… G       ABERNATHY <NA>        <NA>      STATE… 29       <NA>     500
#> # … with 16 more variables: date <dttm>, last <chr>, first <chr>, mi <chr>, suffix <chr>,
#> #   address_1 <chr>, address_2 <chr>, city <chr>, state <chr>, zip <chr>, country <chr>,
#> #   election <chr>, source_file <chr>, amend <lgl>, con_type <chr>, source_type <chr>
tail(idc)
#> # A tibble: 6 x 26
#>   party cand_first cand_mi cand_last cand_suffix committee office district type   amount
#>   <chr> <chr>      <chr>   <chr>     <chr>       <chr>     <chr>  <chr>    <chr>   <dbl>
#> 1 <NA>  <NA>       <NA>    Nicholas… <NA>        <NA>      <NA>   <NA>     Dona…    0.01
#> 2 <NA>  <NA>       <NA>    Nicholas… <NA>        <NA>      <NA>   <NA>     Dona…  500   
#> 3 <NA>  <NA>       <NA>    Nicholas… <NA>        <NA>      <NA>   <NA>     Dona…  300   
#> 4 <NA>  <NA>       <NA>    Robert B… <NA>        <NA>      <NA>   <NA>     Loan  4500   
#> 5 <NA>  <NA>       <NA>    Nicholas… <NA>        <NA>      <NA>   <NA>     Dona…   15   
#> 6 <NA>  <NA>       <NA>    Russell … <NA>        <NA>      <NA>   <NA>     In-K…  300   
#> # … with 16 more variables: date <dttm>, last <chr>, first <chr>, mi <chr>, suffix <chr>,
#> #   address_1 <chr>, address_2 <chr>, city <chr>, state <chr>, zip <chr>, country <chr>,
#> #   election <chr>, source_file <chr>, amend <lgl>, con_type <chr>, source_type <chr>
```

We should first identify which columns are missing the kinds of key
information we need to properly identify all parties to a contribution.
We can do this with `campfin::flag_na()` after creating a new

``` r
col_stats(idc, count_na)
#> # A tibble: 26 x 4
#>    col         class       n       p
#>    <chr>       <chr>   <int>   <dbl>
#>  1 party       <chr>   42945 0.0830 
#>  2 cand_first  <chr>  313239 0.605  
#>  3 cand_mi     <chr>  451266 0.872  
#>  4 cand_last   <chr>  270975 0.524  
#>  5 cand_suffix <chr>  516780 0.999  
#>  6 committee   <chr>  246385 0.476  
#>  7 office      <chr>  313203 0.605  
#>  8 district    <chr>  387790 0.750  
#>  9 type        <chr>  263670 0.510  
#> 10 amount      <dbl>       0 0      
#> 11 date        <dttm>    782 0.00151
#> 12 last        <chr>    2123 0.00410
#> 13 first       <chr>  110538 0.214  
#> 14 mi          <chr>  481747 0.931  
#> 15 suffix      <chr>  516599 0.999  
#> 16 address_1   <chr>    3294 0.00637
#> 17 address_2   <chr>  502247 0.971  
#> 18 city        <chr>    2882 0.00557
#> 19 state       <chr>    1993 0.00385
#> 20 zip         <chr>    4812 0.00930
#> 21 country     <chr>  249074 0.481  
#> 22 election    <chr>  433122 0.837  
#> 23 source_file <chr>   42228 0.0816 
#> 24 amend       <lgl>  475132 0.918  
#> 25 con_type    <chr>  475132 0.918  
#> 26 source_type <chr>       0 0
```

``` r
idc <- idc %>% 
  # combine cand and comm names in new col
  mutate(recip = coalesce(cand_last, committee)) %>% 
  flag_na(last, recip, date, amount)

sum(idc$na_flag)
#> [1] 2723
mean(idc$na_flag)
#> [1] 0.00526326
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
#> [1] 8121
mean(idc$dupe_flag)
#> [1] 0.015697
idc %>% 
  filter(dupe_flag) %>% 
  select(recip, last, date, amount)
#> # A tibble: 8,121 x 4
#>    recip     last                                                   date                amount
#>    <chr>     <chr>                                                  <dttm>               <dbl>
#>  1 ABERNATHY IRON WORKERS DISTRICT COUNCIL OF THE PACIFIC NORTHWEST 2018-07-05 00:00:00    500
#>  2 ABERNATHY IRON WORKERS DISTRICT COUNCIL OF THE PACIFIC NORTHWEST 2018-07-05 00:00:00    500
#>  3 ABERNATHY LANDON                                                 2018-06-12 00:00:00    500
#>  4 ABERNATHY LANDON                                                 2018-06-12 00:00:00    500
#>  5 ADDIS     ADDIS                                                  2018-09-30 00:00:00      0
#>  6 ADDIS     ADDIS                                                  2018-09-30 00:00:00      0
#>  7 AHLQUIST  SCARLETT IV                                            2017-09-14 00:00:00   1000
#>  8 AHLQUIST  SCARLETT IV                                            2017-09-14 00:00:00   1000
#>  9 AHLQUIST  WRIGHT                                                 2017-08-24 00:00:00   1000
#> 10 AHLQUIST  WRIGHT                                                 2017-08-24 00:00:00   1000
#> # … with 8,111 more rows
```

### Categorical

``` r
col_stats(idc, n_distinct)
#> # A tibble: 29 x 4
#>    col         class       n          p
#>    <chr>       <chr>   <int>      <dbl>
#>  1 party       <chr>      13 0.0000251 
#>  2 cand_first  <chr>     648 0.00125   
#>  3 cand_mi     <chr>     137 0.000265  
#>  4 cand_last   <chr>    1648 0.00319   
#>  5 cand_suffix <chr>       5 0.00000966
#>  6 committee   <chr>     517 0.000999  
#>  7 office      <chr>      16 0.0000309 
#>  8 district    <chr>      36 0.0000696 
#>  9 type        <chr>      13 0.0000251 
#> 10 amount      <dbl>   12851 0.0248    
#> 11 date        <dttm>   8319 0.0161    
#> 12 last        <chr>   56369 0.109     
#> 13 first       <chr>   23180 0.0448    
#> 14 mi          <chr>    1020 0.00197   
#> 15 suffix      <chr>      12 0.0000232 
#> 16 address_1   <chr>  123650 0.239     
#> 17 address_2   <chr>    1526 0.00295   
#> 18 city        <chr>    4606 0.00890   
#> 19 state       <chr>     122 0.000236  
#> 20 zip         <chr>   10650 0.0206    
#> 21 country     <chr>       8 0.0000155 
#> 22 election    <chr>       3 0.00000580
#> 23 source_file <chr>      21 0.0000406 
#> 24 amend       <lgl>       3 0.00000580
#> 25 con_type    <chr>       3 0.00000580
#> 26 source_type <chr>       2 0.00000387
#> 27 recip       <chr>    2158 0.00417   
#> 28 na_flag     <lgl>       2 0.00000387
#> 29 dupe_flag   <lgl>       2 0.00000387
```

![](../plots/bar_office-1.png)<!-- -->

![](../plots/bar_party-1.png)<!-- -->

![](../plots/type_party-1.png)<!-- -->

### Amounts

``` r
summary(idc$amount)
#>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
#> -100000.0      20.0      80.0     339.5     200.0 2000000.0
mean(idc$amount <= 0)
#> [1] 0.002505026
```

``` r
glimpse(idc[c(which.min(idc$amount), which.max(idc$amount)), ])
#> Rows: 2
#> Columns: 29
#> $ party       <chr> "OTH", "NON"
#> $ cand_first  <chr> NA, NA
#> $ cand_mi     <chr> NA, NA
#> $ cand_last   <chr> NA, NA
#> $ cand_suffix <chr> NA, NA
#> $ committee   <chr> "PARENTS FOR EDUCATION REFORM", "IDAHO UNITED AGAINST PROP 1"
#> $ office      <chr> NA, NA
#> $ district    <chr> NA, NA
#> $ type        <chr> NA, NA
#> $ amount      <dbl> -1e+05, 2e+06
#> $ date        <dttm> 2012-10-19, 2018-09-12
#> $ last        <chr> "ENGAGE IDAHO", "COEUR D'ALENE TRIBE"
#> $ first       <chr> NA, NA
#> $ mi          <chr> NA, NA
#> $ suffix      <chr> NA, NA
#> $ address_1   <chr> "PO BOX 9925", "PO BOX 408"
#> $ address_2   <chr> NA, NA
#> $ city        <chr> "BOISE", "PLUMMER"
#> $ state       <chr> "ID", "ID"
#> $ zip         <chr> "83707", "83851"
#> $ country     <chr> "USA", "USA"
#> $ election    <chr> NA, NA
#> $ source_file <chr> "2012_2012_COMM_CONT.XLSX", "2018_COMMITTEE_CONTRIBUTIONS.XLSX"
#> $ amend       <lgl> NA, NA
#> $ con_type    <chr> NA, NA
#> $ source_type <chr> "old", "old"
#> $ recip       <chr> "PARENTS FOR EDUCATION REFORM", "IDAHO UNITED AGAINST PROP 1"
#> $ na_flag     <lgl> FALSE, FALSE
#> $ dupe_flag   <lgl> FALSE, FALSE
```

![](../plots/amount_histogram-1.png)<!-- -->

![](../plots/amount_violin-1.png)<!-- -->

### Dates

``` r
idc <- mutate(idc, year = year(date))
```

``` r
min(idc$date, na.rm = TRUE)
#> [1] "1930-07-06 UTC"
max(idc$date, na.rm = TRUE)
#> [1] "3831-12-01 UTC"
idc <- mutate(idc, date_flag = date > today() | year < 1999 | is.na(date))
count_na(idc$date) # 782
#> [1] 782
sum(idc$date_flag) # 835 = 53
#> [1] 831
mean(idc$date_flag)
#> [1] 0.001606232
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
#> # A tibble: 124,937 x 3
#>    address_1                address_2 address_norm          
#>    <chr>                    <chr>     <chr>                 
#>  1 3787 N 3575 E            <NA>      3787 N 3575 E         
#>  2 1582 CASSEOPEIA ST       <NA>      1582 CASSEOPEIA ST    
#>  3 433 N C ST               <NA>      433 N C ST            
#>  4 501 WEST 123RD ST APT MG <NA>      501 W 123 RD ST APT MG
#>  5 PO BOX 4392              <NA>      PO BOX 4392           
#>  6 596 PEWAUKEE RD          <NA>      596 PEWAUKEE RD       
#>  7 3333 GEM AVE             <NA>      3333 GEM AVE          
#>  8 2402 W JEFFERSON         <NA>      2402 W JEFFERSON      
#>  9 3733 N SAWGRASS WAY      <NA>      3733 N SAWGRASS WAY   
#> 10 55 SW 5th Ave St 100     <NA>      55 SW 5 TH AVE ST 100 
#> # … with 124,927 more rows
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
#> 1 zip        0.947      10650 0.00930 27299   5617
#> 2 zip_norm   0.999       5698 0.00935   653    389
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
#>   stage      prop_in n_distinct prop_na n_out n_diff
#>   <chr>        <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 state        0.999        122 0.00385   390     68
#> 2 state_norm   1.00          81 0.00396    64     26
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
#> 1 city_raw    0.890       4606 0.00557 56583   1949
#> 2 city_norm   0.994       3633 0.00561  3215    805
#> 3 city_swap   0.997       3063 0.0124   1575    265
```

``` r
idc %>% 
  filter(city_swap %out% many_city) %>% 
  count(city_swap, sort = TRUE)
#> # A tibble: 265 x 2
#>    city_swap                  n
#>    <chr>                  <int>
#>  1 <NA>                    6398
#>  2 HAYDEN LAKE              663
#>  3 DALTON GARDENS           349
#>  4 PRIEST LAKE               50
#>  5 HIDDEN SPRINGS            37
#>  6 RESEARCH TRIANGLE PARK    26
#>  7 CHUBUCK                   20
#>  8 MULTNOMAH                 16
#>  9 SEATAC                    12
#> 10 SYMMS TOWNSHIP            11
#> # … with 255 more rows
```

## Conclude

Before exporting, we can remove the intermediary normalization columns
and rename all added variables with the `_clean` suffix.

``` r
idc <- idc %>% 
  select(
    -city_norm,
    city_clean = city_swap
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  rename_all(~str_remove(., "_raw"))
```

``` r
glimpse(sample_n(idc, 50))
#> Rows: 50
#> Columns: 35
#> $ party         <chr> "REP", "REP", "REP", NA, "OTH", NA, "OTH", "OTH", "DEM", "OTH", "OTH", "DE…
#> $ cand_first    <chr> "BRAD", "MIKE", "CELIA", NA, NA, NA, NA, NA, "BRENDA", NA, NA, "PHYLIS", "…
#> $ cand_mi       <chr> NA, NA, "R.", NA, NA, NA, NA, NA, NA, NA, NA, "K", NA, NA, NA, NA, NA, NA,…
#> $ cand_last     <chr> "LITTLE", "MOYLE", "GOULD", "Marianna Davis", NA, "Ryan Kerby", NA, NA, "L…
#> $ cand_suffix   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ committee     <chr> NA, NA, NA, NA, "IDAHO ASSOCIATION OF CHIROPRACTIC PHYSICIANS", NA, "PACE …
#> $ office        <chr> "GOVERNOR", "STATE REP., POSITION A", "LIEUTENANT GOVERNOR", NA, NA, NA, N…
#> $ district      <chr> NA, "14", NA, NA, NA, NA, NA, NA, "15", NA, NA, "18", "15", "10", "29", NA…
#> $ type          <chr> NA, "C", "C", "Donation", NA, "Donation", NA, NA, "C", NA, NA, "C", "C", "…
#> $ amount        <dbl> 25.00, 100.00, 50.00, 200.00, 25.00, 50.00, 10.00, 5.00, 1000.00, 60.00, 5…
#> $ date          <dttm> 2018-05-08 00:00:00, 2002-05-22 00:00:00, 2002-06-04 00:00:00, 2020-08-16…
#> $ last          <chr> "ALEX CREEK RENTAL PROPERTIES", "IDAHO OUTFITTERS & GUIDES ASSN. (IOGA PAC…
#> $ first         <chr> NA, NA, "NORMAN", NA, "LANCE", "Nate", "SARAH", "CINDY", NA, "SETH", "MATT…
#> $ mi            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ suffix        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ address_1     <chr> "656 11TH ST", "PO BOX 95", "4791 N 700 E", "1220 W. Hayes Street", "104 S…
#> $ address_2     <chr> NA, NA, NA, NA, "STE A", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ city          <chr> "IDAHO FALLS", "BOISE", "BUHL", "Boise", "SALMON", "Weiser", "IDAHO FALLS"…
#> $ state         <chr> "ID", "ID", "ID", "ID", "ID", "ID", "ID", "ID", "DC", "ID", "ID", "ID", "I…
#> $ zip           <chr> "83404", "83702", "83316", "83702", "83467", "83672", "83404", "83646", "2…
#> $ country       <chr> "USA", NA, NA, NA, "USA", NA, "USA", "USA", NA, "USA", "USA", NA, NA, NA, …
#> $ election      <chr> "P", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "P", NA, …
#> $ source_file   <chr> "2018_CANDIDATE_CONTRIBUTIONS.XLSX", "2001_CAND_CONTRIBUTIONS.XLS", "2001_…
#> $ amend         <lgl> NA, NA, NA, FALSE, NA, FALSE, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ con_type      <chr> NA, NA, NA, "Company", NA, "Individual", NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ source_type   <chr> "old", "old", "old", "new", "old", "new", "old", "old", "old", "old", "old…
#> $ recip         <chr> "LITTLE", "MOYLE", "GOULD", "Marianna Davis", "IDAHO ASSOCIATION OF CHIROP…
#> $ na_flag       <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ dupe_flag     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ year          <dbl> 2018, 2002, 2002, 2020, 2013, 2020, 2015, 2015, 2010, 2017, 2016, 2008, 20…
#> $ date_flag     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ address_clean <chr> "656 11 TH ST", "PO BOX 95", "4791 N 700 E", "1220 W HAYES ST", "104 S DAI…
#> $ zip_clean     <chr> "83404", "83702", "83316", "83702", "83467", "83672", "83404", "83646", "2…
#> $ state_clean   <chr> "ID", "ID", "ID", "ID", "ID", "ID", "ID", "ID", "DC", "ID", "ID", "ID", "I…
#> $ city_clean    <chr> "IDAHO FALLS", "BOISE", "BUHL", "BOISE", "SALMON", "WEISER", "IDAHO FALLS"…
```

1.  There are 517,360 records in the database.
2.  There are 8,121 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 2,723 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("id", "contribs", "data", "clean"))
clean_path <- path(clean_dir, "id_contribs_clean.csv")
write_csv(idc, clean_path, na = "")
(clean_size <- file_size(clean_path))
#> 117M
file_encoding(clean_path) %>% 
  mutate(across(path, path.abbrev))
#> # A tibble: 1 x 3
#>   path                                           mime            charset 
#>   <chr>                                          <chr>           <chr>   
#> 1 ~/id/contribs/data/clean/id_contribs_clean.csv application/csv us-ascii
```

## Upload

We can use the `aws.s3::put_object()` to upload the text file to the IRW
server.

``` r
aws_path <- path("csv", basename(clean_path))
if (!object_exists(aws_path, "publicaccountability")) {
  put_object(
    file = clean_path,
    object = aws_path, 
    bucket = "publicaccountability",
    acl = "public-read",
    show_progress = TRUE,
    multipart = TRUE
  )
}
aws_head <- head_object(aws_path, "publicaccountability")
(aws_size <- as_fs_bytes(attr(aws_head, "content-length")))
#> 117M
unname(aws_size == clean_size)
#> [1] TRUE
```

## Dictionary

The following table describes the variables in our final exported file:

| Column          | Type        | Definition                            |
| :-------------- | :---------- | :------------------------------------ |
| `party`         | `character` | Candidate party                       |
| `cand_first`    | `character` | Candidate first name                  |
| `cand_mi`       | `character` | Candidate middle name                 |
| `cand_last`     | `character` | Candidate last name                   |
| `cand_suffix`   | `character` | Candidate name suffix                 |
| `committee`     | `character` | Recieving committee name              |
| `office`        | `character` | Office sought by candidate            |
| `district`      | `character` | District of election held             |
| `type`          | `character` | Type of contribution made             |
| `amount`        | `double`    | Amount of contribution                |
| `date`          | `double`    | Date contribution made                |
| `last`          | `character` | Contributor last name                 |
| `first`         | `character` | Contributor first name                |
| `mi`            | `character` | Contributor middle name               |
| `suffix`        | `character` | Contributor name suffix               |
| `address_1`     | `character` | Contributor street address            |
| `address_2`     | `character` | Contributor secondary address         |
| `city`          | `character` | Contributor city name                 |
| `state`         | `character` | Contributor state abbreviation        |
| `zip`           | `character` | Contributor ZIP+4 code                |
| `country`       | `character` | Contributor country code              |
| `election`      | `character` | Election type code (primary, general) |
| `source_file`   | `character` | Source file name                      |
| `amend`         | `logical`   | Flag for amended record (*NEW*)       |
| `con_type`      | `character` | Contributor type (*NEW*)              |
| `source_type`   | `character` | Source file type (old, new)           |
| `recip`         | `character` | Coalesced recipient name              |
| `na_flag`       | `logical`   | Flag indicating missing value         |
| `dupe_flag`     | `logical`   | Flag indicating duplicate value       |
| `year`          | `double`    | Cleaned contribution date             |
| `date_flag`     | `logical`   | Calendar year contribution made       |
| `address_clean` | `character` | Normalized combined address           |
| `zip_clean`     | `character` | Normalized 5-digit ZIP code           |
| `state_clean`   | `character` | Normalized 2-letter state code        |
| `city_clean`    | `character` | Normalized city name                  |
