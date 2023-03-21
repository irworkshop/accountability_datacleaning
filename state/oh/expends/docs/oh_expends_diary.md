Ohio Expenditures
================
Kiernan Nicholls & Yanqi Xu
2023-03-20 22:32:18

- <a href="#project" id="toc-project">Project</a>
- <a href="#objectives" id="toc-objectives">Objectives</a>
- <a href="#packages" id="toc-packages">Packages</a>
- <a href="#data" id="toc-data">Data</a>
- <a href="#import" id="toc-import">Import</a>
- <a href="#explore" id="toc-explore">Explore</a>
- <a href="#previous" id="toc-previous">Previous</a>
- <a href="#wrangle" id="toc-wrangle">Wrangle</a>
- <a href="#conclude" id="toc-conclude">Conclude</a>
- <a href="#export" id="toc-export">Export</a>
- <a href="#upload" id="toc-upload">Upload</a>
- <a href="#dictionary" id="toc-dictionary">Dictionary</a>

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
  janitor, # clean data frames
  refinr, # cluster and merge
  scales, # format strings
  aws.s3, # upload to AWS
  knitr, # knit documents
  vroom, # read files fast
  rvest, # html scraping
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
#> [1] "/Users/yanqixu/code/accountability_datacleaning"
raw_dir <- dir_create(here("state","oh", "expends", "data", "raw"))
```

## Data

The data is obtained from the [Ohio Secretary of
State](https://www.ohiosos.gov/). The OH SOS offers a file transfer page
(FTP) to download data in bulk rather than via searches.

> Welcome to the Ohio Secretary of State’s Campaign Finance File
> Transfer Page. This page was developed to allow users to obtain large
> sets of data faster than the normal query process. At this page you
> can download files of pre-queried data, such as all candidate
> Expenditures for a particular year or a list of all active political
> action committees registered with the Secretary of State. In addition,
> campaign finance data filed prior to 2000 is available only on this
> site. These files contain all relevant and frequently requested
> information. If you are looking for smaller or very specific sets of
> data please use the regular Campaign Finance queries listed on the
> tabs above.

## Import

### Download

> On the FTP page, please decide which information you would like to
> download. Click “Download File” on the right hand side. The system
> will then proceed to download the file into Microsoft Excel or provide
> you will an opportunity to download the file to the location on your
> computer (the settings on your computer will dictate this). You may
> see a series of dialog boxes on your screen asking you if you want to
> run or save the zipped `.exe` file. Follow the dialog boxes for
> whichever you chose telling the computer where you want the files
> saved. The end result will be a `.csv` file that you can open in
> Microsoft Excel or some other database application.

We can download all the Expenditure files by reading the FTP website
itself and scraping each of the “Download” links in the table. This
process needs to be repeated for candidates, PACs, and parties.

``` r
ftp_base <- "https://www6.ohiosos.gov/ords/"
#t <- c("CAN", "PAC", "PARTY")
t <- c("CAN")
ftp_url <- glue("f?p=CFDISCLOSURE:73:7027737052457:{t}:NO:RP:P73_TYPE:{t}:")
ftp_url <- str_c(ftp_base, ftp_url)
ftp_params <- character()
ftp_table <- rep(list(NA), length(t))
for (i in seq_along(t)) {
  ftp_page <- read_html(ftp_url[i])
  #table_id <- paste0("#", str_extract(ftp_page, '(?<=id\\=")report_.*(?="\\s)'))
  table_id <- ".info-report > table"
  ftp_table[[i]] <- ftp_page %>%
    html_node(table_id) %>%
    html_table() %>%
    as_tibble() %>%
    select(-last_col()) %>%
    set_names(c("file", "date", "size")) %>%
    mutate_at(vars(2), parse_date_time, "%m/%d/%Y %H:%M:%S %p")
  con_index <- str_which(ftp_table[[i]]$file, "Expenditures\\s-\\s\\d+")
  ftp_params <- ftp_page %>%
    html_node(table_id) %>%
    html_nodes("tr") %>%
    html_nodes("a") %>%
    html_attr("href") %>%
    str_subset("f\\?p") %>%
    `[`(con_index) %>%
    append(ftp_params)
}
```

Then each link can be downloaded to the `/data/raw` directory.

``` r
wget <- function(url, dir) {
  system2(
    command = "wget",
    args = c(
      "--no-verbose",
      "--content-disposition",
      url,
      paste("-P", raw_dir),
      wait = 1
    )
  )
}
```

``` r
raw_urls <- paste0(ftp_base, ftp_params)
if (length(dir_ls(raw_dir)) < 84) {
  map(raw_urls, wget, raw_dir)
}
```

``` r
raw_info <- dir_info(raw_dir)
sum(raw_info$size)
#> 308M
(raw_files <- raw_info %>%
  select(file_path = path, size, modification_time) %>% 
  mutate(file_id = as.character(row_number()), .before = 1) %>% 
  mutate(across(file_path, basename)))
#> # A tibble: 98 × 4
#>    file_id file_path                   size modification_time  
#>    <chr>   <chr>                <fs::bytes> <dttm>             
#>  1 1       ALL_CAN_EXP_1994.CSV       1.44M 2023-03-20 21:37:38
#>  2 2       ALL_CAN_EXP_1995.CSV       2.01M 2023-03-20 21:37:37
#>  3 3       ALL_CAN_EXP_1996.CSV       4.67M 2023-03-20 21:37:36
#>  4 4       ALL_CAN_EXP_1997.CSV       3.24M 2023-03-20 21:37:33
#>  5 5       ALL_CAN_EXP_1998.CSV       7.41M 2023-03-20 21:37:31
#>  6 6       ALL_CAN_EXP_1999.CSV       3.52M 2023-03-20 21:37:28
#>  7 7       ALL_CAN_EXP_2000.CSV        6.1M 2023-03-20 21:37:26
#>  8 8       ALL_CAN_EXP_2001.CSV       3.03M 2023-03-20 21:37:25
#>  9 9       ALL_CAN_EXP_2002.CSV       6.67M 2023-03-20 21:37:23
#> 10 10      ALL_CAN_EXP_2003.CSV       3.55M 2023-03-20 21:37:22
#> # … with 88 more rows
```

### Read

> The data is in a “comma delimited” format that loads easily into
> Microsoft Excel or Access as well as many other spreadsheet or
> database programs. Many of the available files contain a significant
> quantity of data records. A spreadsheet program, such as Microsoft
> Excel, may not allow all of the data in a file to be loaded because of
> a limit on the number of available rows. For this reason, it is
> advised that a database application be utilized to load and work with
> the data available at this site…

We can read all 98 raw CSV files into a single data frame using
`purrr::map_df()` and `readr::read_csv()`. There are some columns that
only exist in the files containing contributions from a PAC, party, etc.
Most columns are shared across all files, so when we join them together
into a single data frame, empty rows will be created for those unique
columns.

``` r
ohe <- map_df(
  .x = raw_info$path,
  .f = read_csv,
  .id = "file_id",
  na = c("", "NA", "N/A"),
  col_types = cols(
    .default = col_character(),
    MASTER_KEY = col_integer(),
    RPT_YEAR = col_integer(),
    REPORT_KEY = col_integer(),
    EXPEND_DATE = col_date_usa(),
    AMOUNT = col_double(),
    EVENT_DATE = col_date_usa(),
    INKIND = col_logical(),
    DISTRICT = col_integer()
  )
)
```

We can identify the transaction year and filer type from the source file
name.

``` r
fil_types <- ohe %>% 
  count(file_path, sort = TRUE) %>% 
  mutate(
    file_type = case_when(str_detect(file_path,"CAC|CAN") ~ "CANDIDATE",
                          str_detect(file_path,"PAC") ~ "PAC",
                          str_detect(file_path, "PPC|PAR") ~ "PARTY"),
    file_year = str_extract(file_path, "(?=.+)\\d{4}.CSV") %>% str_remove(".CSV") %>% as.numeric()
  )
```

![](../plots/fil_plot-1.png)<!-- -->

``` r
ohe <- left_join(ohe, fil_types %>% select(-n), by = "file_path")
```

## Explore

There are 1,568,911 rows of 28 columns.

``` r
glimpse(ohe)
#> Rows: 1,568,911
#> Columns: 28
#> $ com_name   <chr> "OHIOANS WITH SHERROD BROWN", "OHIOANS WITH SHERROD BROWN", "FRIENDS OF GOVERN…
#> $ master_key <int> 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, …
#> $ rpt_year   <int> 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, …
#> $ rpt_key    <int> 126484, 126484, 133054, 133090, 133090, 133135, 133054, 133054, 133054, 133072…
#> $ rpt_desc   <chr> "ANNUAL   (JANUARY)", "ANNUAL   (JANUARY)", "PRE-PRIMARY", "PRE-GENERAL", "PRE…
#> $ desc       <chr> "31-B  Stmt of Expenditures", "31-B  Stmt of Expenditures", "31-B  Stmt of Exp…
#> $ first      <chr> NA, NA, NA, NA, NA, "TIMOTHY", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ middle     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ last       <chr> NA, NA, NA, NA, NA, "ALEXANDER", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ suffix     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ non_ind    <chr> "DECISION RESEARCH CORP.", "MCTIGUE & BROOKS", "A.G. HAUCK CO.", "ABSOLUTE SCR…
#> $ address    <chr> "1127 EUCLID AVE. #1100", "4921 DIERKER RD.", "9888 READING RD.", "762 S. FRON…
#> $ city       <chr> "CLEVELAND", "COLUMBUS", "CINCINNATI", "COLUMBUS", "AKRON", "MANSFIELD", "COLU…
#> $ state      <chr> "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", …
#> $ zip        <chr> "44115", "43220", "45241", "43206", "44309", "44903", "43218", "43218", "43218…
#> $ date       <date> 1994-01-27, 1994-01-27, 1994-01-26, 1994-08-30, 1994-09-30, 1994-10-20, 1994-…
#> $ amount     <dbl> 1000.00, 874.30, 100.00, 634.50, 721.50, 75.00, 176.87, 221.87, 296.12, 280.37…
#> $ event      <date> NA, NA, NA, NA, 1994-10-10, 1994-10-13, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ purpose    <chr> "LEGAL SERVICES", "LEGAL SERVICES", "REFUND CONTRIBUTION", "T-SHIRTS", "ADVERT…
#> $ inkind     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ cand_first <chr> "SHERROD", "SHERROD", "BOB", "BOB", "BOB", "BOB", "BOB", "BOB", "BOB", "BOB", …
#> $ cand_last  <chr> "BROWN", "BROWN", "TAFT", "TAFT", "TAFT", "TAFT", "TAFT", "TAFT", "TAFT", "TAF…
#> $ office     <chr> "SECRETARY OF STATE", "SECRETARY OF STATE", "SECRETARY OF STATE", "SECRETARY O…
#> $ district   <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ party      <chr> "DEMOCRAT", "DEMOCRAT", "REPUBLICAN", "REPUBLICAN", "REPUBLICAN", "REPUBLICAN"…
#> $ file_path  <chr> "ALL_CAN_EXP_1994.CSV", "ALL_CAN_EXP_1994.CSV", "ALL_CAN_EXP_1994.CSV", "ALL_C…
#> $ file_type  <chr> "CANDIDATE", "CANDIDATE", "CANDIDATE", "CANDIDATE", "CANDIDATE", "CANDIDATE", …
#> $ file_year  <dbl> 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, …
tail(ohe)
#> # A tibble: 6 × 28
#>   com_name    maste…¹ rpt_y…² rpt_key rpt_d…³ desc  first middle last  suffix non_ind address city 
#>   <chr>         <int>   <int>   <int> <chr>   <chr> <chr> <chr>  <chr> <chr>  <chr>   <chr>   <chr>
#> 1 OHIO HOUSE…   15461    2022  4.22e8 ANNUAL… 31-B… <NA>  <NA>   <NA>  <NA>   MOHICA… 1098 A… PERR…
#> 2 OHIO HOUSE…   15461    2022  4.22e8 ANNUAL… 31-B… <NA>  <NA>   <NA>  <NA>   WELLS … PO BOX… ATLA…
#> 3 OHIO HOUSE…   15461    2022  4.22e8 ANNUAL… 31-B… <NA>  <NA>   <NA>  <NA>   WELLS … PO BOX… ATLA…
#> 4 OHIO HOUSE…   15461    2022  4.22e8 ANNUAL… 31-B… <NA>  <NA>   <NA>  <NA>   WELLS … PO BOX… ATLA…
#> 5 OHIO HOUSE…   15461    2022  4.22e8 ANNUAL… 31-B… <NA>  <NA>   <NA>  <NA>   WELLS … PO BOX… ATLA…
#> 6 OHIO HOUSE…   15461    2022  4.22e8 ANNUAL… 31-B… <NA>  <NA>   <NA>  <NA>   WESTER… PO BOX… WOOS…
#> # … with 15 more variables: state <chr>, zip <chr>, date <date>, amount <dbl>, event <date>,
#> #   purpose <chr>, inkind <lgl>, cand_first <chr>, cand_last <chr>, office <chr>, district <int>,
#> #   party <chr>, file_path <chr>, file_type <chr>, file_year <dbl>, and abbreviated variable names
#> #   ¹​master_key, ²​rpt_year, ³​rpt_desc
```

## Previous

Another way is to read in the previous update and filter out the rows
already in the old file.

``` r
prev_file <- here("state","oh","expends","data","previous")

oh_prev <- read_csv(prev_file %>% dir_ls())

oh_prev <- oh_prev %>% select(intersect(oh_prev %>% names(), ohe %>% names())) %>% filter(file_year == 2020)

ohe <- ohe %>% setdiff(oh_prev)
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(ohe, count_na)
#> # A tibble: 28 × 4
#>    col        class        n        p
#>    <chr>      <chr>    <int>    <dbl>
#>  1 com_name   <chr>        0 0       
#>  2 master_key <int>        0 0       
#>  3 rpt_year   <int>        0 0       
#>  4 rpt_key    <int>        0 0       
#>  5 rpt_desc   <chr>        0 0       
#>  6 desc       <chr>        0 0       
#>  7 first      <chr>  1349876 0.860   
#>  8 middle     <chr>  1540982 0.982   
#>  9 last       <chr>  1348835 0.860   
#> 10 suffix     <chr>  1562422 0.996   
#> 11 non_ind    <chr>   222787 0.142   
#> 12 address    <chr>   112759 0.0719  
#> 13 city       <chr>    90222 0.0575  
#> 14 state      <chr>    87926 0.0560  
#> 15 zip        <chr>    99657 0.0635  
#> 16 date       <date>    1739 0.00111 
#> 17 amount     <dbl>      416 0.000265
#> 18 event      <date> 1518523 0.968   
#> 19 purpose    <chr>    81696 0.0521  
#> 20 inkind     <lgl>  1340310 0.854   
#> 21 cand_first <chr>   857820 0.547   
#> 22 cand_last  <chr>   857820 0.547   
#> 23 office     <chr>   857820 0.547   
#> 24 district   <int>   864314 0.551   
#> 25 party      <chr>   644061 0.411   
#> 26 file_path  <chr>        0 0       
#> 27 file_type  <chr>        0 0       
#> 28 file_year  <dbl>        0 0
```

We can flag records missing a name, date, or amount after uniting the
multiple contributor name columns into a single variable.

``` r
ohe <- ohe %>% 
  unite(
    first, middle, last, suffix, non_ind,
    col = pay_name,
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(across(where(is.character), na_if, "")) %>% 
  relocate(pay_name, .after = last_col()) %>% 
  flag_na(date, pay_name, amount, com_name)
```

0.27% of rows are missing a key variable.

``` r
sum(ohe$na_flag)
#> [1] 4186
ohe %>% 
  filter(na_flag) %>% 
  select(date, pay_name, amount, com_name)
#> # A tibble: 4,186 × 4
#>    date       pay_name   amount com_name                      
#>    <date>     <chr>       <dbl> <chr>                         
#>  1 1994-03-31 <NA>         0.6  KEST CAMPAIGN COMMITTEE       
#>  2 1994-11-02 <NA>        12.0  BYRNE FOR STATE SCHOOL BOARD  
#>  3 NA         PETTY CASH  57.2  LEIGH HERINGTON COMMITTEE     
#>  4 1995-02-17 <NA>         3    BERNS FOR STATE REPRESENTATIVE
#>  5 1995-03-17 <NA>         3    BERNS FOR STATE REPRESENTATIVE
#>  6 1995-06-17 <NA>        15    BERNS FOR STATE REPRESENTATIVE
#>  7 1995-06-17 <NA>         1.85 BERNS FOR STATE REPRESENTATIVE
#>  8 1995-09-30 <NA>        25    BURKE FOR SENATE              
#>  9 1995-03-09 <NA>         3.5  FRIENDS OF BOB HAGAN          
#> 10 1995-05-11 <NA>        40    BOB BOGGS LEGISLATIVE FUND    
#> # … with 4,176 more rows
```

### Duplicate

There are actually quite a few duplicate values in the data. While it’s
possible for the same person to contribute the same amount to the same
committee on the same day, we can flag these values anyway.

``` r
# d1 <- duplicated(ohe, fromLast = FALSE)
# d2 <- duplicated(ohe, fromLast = TRUE)
# ohe <- mutate(ohe, dupe_flag = d1 | d2)
# rm(d1, d2); 
ohe <- ohe %>% flag_dupes(dplyr::everything())
flush_memory()
```

2.4% of rows are duplicated at least once.

``` r
ohe %>% 
  filter(dupe_flag) %>% 
  arrange(date, pay_name) %>% 
  select(date, pay_name, amount, com_name)
#> # A tibble: 37,369 × 4
#>    date       pay_name                amount com_name                         
#>    <date>     <chr>                    <dbl> <chr>                            
#>  1 1990-01-02 DOLPHIN COMPUTER SYSTEM   64.2 VOINOVICH COMMITTEE  THE         
#>  2 1990-01-02 DOLPHIN COMPUTER SYSTEM   64.2 VOINOVICH COMMITTEE  THE         
#>  3 1990-02-06 GARICK & ASSOCITES        70   VOINOVICH COMMITTEE  THE         
#>  4 1990-02-06 GARICK & ASSOCITES        70   VOINOVICH COMMITTEE  THE         
#>  5 1990-02-06 GARICK & ASSOCITES        70   VOINOVICH COMMITTEE  THE         
#>  6 1990-02-22 ACE                      246.  VOINOVICH COMMITTEE  THE         
#>  7 1990-02-22 ACE                      246.  VOINOVICH COMMITTEE  THE         
#>  8 1990-03-01 MARGO ROTH              1000   FRIENDS OF FISHER COMMITTEE (LEE)
#>  9 1990-03-01 MARGO ROTH              1000   FRIENDS OF FISHER COMMITTEE (LEE)
#> 10 1990-03-19 FIFTH THIRD BANK          12.2 FRIENDS OF GOVERNOR TAFT         
#> # … with 37,359 more rows
```

### Amounts

``` r
summary(ohe$amount)
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max.     NA's 
#>  -150000       50      200     1943      567 23916946      416
prop_na(ohe$amount)
#> [1] 0.0002651521
mean(ohe$amount <= 0, na.rm = TRUE)
#> [1] 0.003558188
```

There are the smallest and largest transactions.

``` r
glimpse(ohe[c(which.min(ohe$amount), which.max(ohe$amount)), ])
#> Rows: 2
#> Columns: 31
#> $ com_name   <chr> "UNITED FOOD & COMMERCIAL WORKERS ACTIVE BALLOT CLUB", "REPUBLICAN NATIONAL ST…
#> $ master_key <int> 1011, 5009
#> $ rpt_year   <int> 2008, 2000
#> $ rpt_key    <int> 984274, 450475
#> $ rpt_desc   <chr> "FEDERAL5", "PRE-GENERAL"
#> $ desc       <chr> "31-B  Stmt of Expenditures", "31-B  Stmt of Expenditures"
#> $ first      <chr> NA, NA
#> $ middle     <chr> NA, NA
#> $ last       <chr> NA, NA
#> $ suffix     <chr> NA, NA
#> $ non_ind    <chr> "OHIO DEMOCRATIC PARTY", "EXPENDITURES NET PERTAINING TO OHIO"
#> $ address    <chr> "340 E FULTON ST", NA
#> $ city       <chr> "COLUMBUS", NA
#> $ state      <chr> "OH", "OH"
#> $ zip        <chr> "43215", NA
#> $ date       <date> 2008-09-17, NA
#> $ amount     <dbl> -150000, 23916946
#> $ event      <date> NA, NA
#> $ purpose    <chr> "CONTRIBUTION", NA
#> $ inkind     <lgl> NA, NA
#> $ cand_first <chr> NA, NA
#> $ cand_last  <chr> NA, NA
#> $ office     <chr> NA, NA
#> $ district   <int> NA, NA
#> $ party      <chr> NA, "5"
#> $ file_path  <chr> "ALL_PAC_EXP_2008.CSV", "ALL_PAR_EXP_2000.CSV"
#> $ file_type  <chr> "PAC", "PARTY"
#> $ file_year  <dbl> 2008, 2000
#> $ pay_name   <chr> "OHIO DEMOCRATIC PARTY", "EXPENDITURES NET PERTAINING TO OHIO"
#> $ na_flag    <lgl> FALSE, TRUE
#> $ dupe_flag  <lgl> FALSE, FALSE
```

The `amount` values are logarithmically normally distributed.

![](../plots/hist_amount-1.png)<!-- -->

### Dates

We can create a new column with a 4-digit year from the `date`.

``` r
ohe <- mutate(ohe, year = year(date))
```

There are few `date` values with typos making them really small or
large.

``` r
min(ohe$date, na.rm = TRUE)
#> [1] "0010-03-02"
sum(ohe$year < 1990, na.rm = TRUE)
#> [1] 474
max(ohe$date, na.rm = TRUE)
#> [1] "9898-08-21"
sum(ohe$date > today(), na.rm = TRUE)
#> [1] 365
```

![](../plots/bar_year-1.png)<!-- -->

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
oh_addr_norm <- tibble(
  address = unique(ohe$address),
  address_norm = normal_address(
    address = address,
    abbs = usps_street,
    na_rep = TRUE
  )
)
```

``` r
ohe <- left_join(ohe, oh_addr_norm, by = "address")
```

    #> # A tibble: 262,617 × 2
    #>    address                address_norm         
    #>    <chr>                  <chr>                
    #>  1 1127 EUCLID AVE. #1100 1127 EUCLID AVE #1100
    #>  2 4921 DIERKER RD.       4921 DIERKER RD      
    #>  3 9888 READING RD.       9888 READING RD      
    #>  4 762 S. FRONT ST.       762 S FRONT ST       
    #>  5 PO BOX 610             PO BOX 610           
    #>  6 106 STURGES AVE.       106 STURGES AVE      
    #>  7 PO BOX 182375          PO BOX 182375        
    #>  8 P.O. BOX 182375        PO BOX 182375        
    #>  9 457 MORGAN ST.         457 MORGAN ST        
    #> 10 1638 TANGLEWOOD DR.    1638 TANGLEWOOD DR   
    #> # … with 262,607 more rows

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
ohe <- mutate(
  .data = ohe,
  zip_norm = normal_zip(
    zip = zip,
    na_rep = TRUE
  )
)
```

``` r
progress_table(
  ohe$zip,
  ohe$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 × 6
#>   stage        prop_in n_distinct prop_na  n_out n_diff
#>   <chr>          <dbl>      <dbl>   <dbl>  <dbl>  <dbl>
#> 1 ohe$zip        0.918      21608  0.0635 120839  13430
#> 2 ohe$zip_norm   0.989      10352  0.0777  16262   1884
```

### State

``` r
prop_in(ohe$state, valid_state)
#> [1] 0.9992059
ohe <- mutate(ohe, state_norm = state)
ohe$state_norm[which(ohe$state == "0H")] <- "OH"
ohe$state_norm[which(ohe$state == "IH")] <- "OH"
ohe$state_norm[which(ohe$state == "PH")] <- "OH"
ohe$state_norm[which(ohe$state == "O")]  <- "OH"
ohe$state_norm[str_which(ohe$state, "^O\\W$")]  <- "OH"
ohe$state_norm[str_which(ohe$state, "^\\WH$")]  <- "OH"
prop_in(ohe$state_norm, valid_state)
#> [1] 0.9993855
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
ohe <- mutate(
  .data = ohe,
  city_norm = normal_city(
    city = city, 
    abbs = usps_city,
    states = c("OH", "DC", "OHIO"),
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
ohe <- ohe %>% 
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
good_refine <- ohe %>% 
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
      "state_norm" = "state",
      "zip_norm" = "zip"
    )
  )
```

    #> # A tibble: 150 × 5
    #>    state_norm zip_norm city_swap    city_refine       n
    #>    <chr>      <chr>    <chr>        <chr>         <int>
    #>  1 OH         45263    CINCINATTI   CINCINNATI       40
    #>  2 CA         94107    SAN FRANSICO SAN FRANCISCO    26
    #>  3 OH         45249    CINCINATTI   CINCINNATI       26
    #>  4 OH         45208    CINCINATTI   CINCINNATI       24
    #>  5 OH         45202    CINCINATTI   CINCINNATI       17
    #>  6 OH         45177    WILLIMGTON   WILMINGTON       15
    #>  7 AZ         85260    SCTOSSDALE   SCOTTSDALE       13
    #>  8 CA         94103    SAN FRANSICO SAN FRANCISCO    13
    #>  9 OH         45214    CINCINATTI   CINCINNATI       13
    #> 10 CA         94110    SAN FRANSICO SAN FRANCISCO    11
    #> # … with 140 more rows

Then we can join the refined values back to the database.

``` r
ohe <- ohe %>% 
  left_join(good_refine, by = names(.)) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

| stage                                                             | prop_in | n_distinct | prop_na | n_out | n_diff |
|:------------------------------------------------------------------|--------:|-----------:|--------:|------:|-------:|
| ohe$city_raw | 0.965| 9082| 0.058| 51986| 5374| |ohe$city_norm    |   0.978 |       8410 |   0.058 | 32507 |   4661 |
| ohe$city_swap | 0.992| 6119| 0.058| 12023| 2367| |ohe$city_refine |   0.992 |       6027 |   0.058 | 11517 |   2276 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/bar_progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar_distinct-1.png)<!-- -->

## Conclude

``` r
ohe <- ohe %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_remove(., "_raw")) %>% 
  rename_all(~str_replace(., "_norm", "_clean"))
```

``` r
glimpse(sample_n(ohe, 20))
#> Rows: 20
#> Columns: 36
#> $ com_name      <chr> "CITIZENS FOR JIM PETRO", "CHARTER COMMUNICATIONS OHIO PAC", "OHIO OSTEOPAT…
#> $ master_key    <int> 30, 11764, 1502, 6167, 568, 14286, 14770, 10285, 1508, 1167, 562, 1557, 654…
#> $ rpt_year      <int> 2000, 2009, 2004, 2012, 2002, 2018, 2018, 2007, 2021, 2019, 2019, 2021, 201…
#> $ rpt_key       <int> 129166, 1045426, 788815, 129138697, 169666, 325592794, 315899113, 236806, 3…
#> $ rpt_desc      <chr> "ANNUAL   (JANUARY)", "PRE-PRIMARY", "PRE-GENERAL", "PRE-GENERAL", "PRE-GEN…
#> $ desc          <chr> "31-F  FR Expenditures", "31-B  Stmt of Expenditures", "31-B  Stmt of Expen…
#> $ first         <chr> NA, NA, "ELWOOD WOODY SIMON  TREASURER", NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ middle        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ last          <chr> NA, NA, "JACOBSON FOR STATE SENATE", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ suffix        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ non_ind       <chr> "FRIENDS OF BILL BUNNING", "FRIENDS OF JAY GOYAL", NA, "PAYCHEX", "HARDIN C…
#> $ address       <chr> "361 HILLTOP BLVD.", "2584 WAHL DR", "211 S MAIN ST  SUITE 610", "5450 FRAN…
#> $ city          <chr> "CANFIELD", "MANSFIELD", "DAYTON", "DUBLIN", "ADA", NA, "LEWIS CENTER", "MA…
#> $ state         <chr> "OH", "OH", "OH", "OH", "OH", NA, "OH", "WI", "CA", NA, "NY", "OH", "OH", "…
#> $ zip           <chr> "44406", "449041544", "45402", "43017", "45810", NA, "43035", "53707-1042",…
#> $ date          <date> 2000-11-15, 2009-04-07, 2004-08-06, 2012-07-10, 2002-07-19, 2018-07-06, 20…
#> $ amount        <dbl> 75.00, 2500.00, 200.00, 40.92, 125.00, 200.00, 7.25, 12.70, 3.20, 500.00, 9…
#> $ event         <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ purpose       <chr> "TICKETS", "CONTRIBUTION", "CONTRIBUTION TO CANDIDATE", "LOCAL WITHHOLDING"…
#> $ inkind        <lgl> NA, NA, NA, NA, FALSE, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ cand_first    <chr> "JIM", NA, NA, NA, "JAMES", NA, "BRIAN", "TED", NA, NA, "RICHARD", NA, "JON…
#> $ cand_last     <chr> "PETRO", NA, NA, NA, "HOOPS", NA, "LORENZ", "STRICKLAND", NA, NA, "CORDRAY"…
#> $ office        <chr> "AUDITOR", NA, NA, NA, "HOUSE", NA, "HOUSE", "GOVERNOR", NA, NA, "GOVERNOR"…
#> $ district      <int> 0, NA, NA, NA, 75, NA, 67, 0, NA, NA, 0, NA, 0, NA, 4, 0, NA, NA, NA, 0
#> $ party         <chr> "REPUBLICAN", NA, NA, "1", "REPUBLICAN", NA, "REPUBLICAN", "DEMOCRAT", NA, …
#> $ file_path     <chr> "ALL_CAN_EXP_2000.CSV", "ALL_PAC_EXP_2009.CSV", "ALL_PAC_EXP_2004.CSV", "PP…
#> $ file_type     <chr> "CANDIDATE", "PAC", "PAC", "PARTY", "CANDIDATE", "PAC", "CANDIDATE", "CANDI…
#> $ file_year     <dbl> 2000, 2009, 2004, 2012, 2002, 2018, 2018, 2007, 2021, 2019, 2019, 2021, 201…
#> $ pay_name      <chr> "FRIENDS OF BILL BUNNING", "FRIENDS OF JAY GOYAL", "ELWOOD WOODY SIMON  TRE…
#> $ na_flag       <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
#> $ dupe_flag     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE,…
#> $ year          <dbl> 2000, 2009, 2004, 2012, 2002, 2018, 2018, 2007, 2021, 2019, 2019, 2021, 201…
#> $ address_clean <chr> "361 HILLTOP BLVD", "2584 WAHL DR", "211 S MAIN ST SUITE 610", "5450 FRANTZ…
#> $ zip_clean     <chr> "44406", "44904", "45402", "43017", "45810", NA, "43035", "53707", "94106",…
#> $ state_clean   <chr> "OH", "OH", "OH", "OH", "OH", NA, "OH", "WI", "CA", NA, "NY", "OH", "OH", "…
#> $ city_clean    <chr> "CANFIELD", "MANSFIELD", "DAYTON", "DUBLIN", "ADA", NA, "LEWIS CENTER", "MA…
```

1.  There are 1,568,931 records in the database.
2.  The range and distribution of `amount` and `date` seem reasonable.
3.  There are 4,186 records missing a key variable.
4.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
5.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
clean_dir <- dir_create(here("state","oh", "expends", "data", "clean"))
clean_path <- path(clean_dir, "oh_expends_clean.csv")
write_csv(ohe, clean_path, na = "")
file_size(clean_path)
#> 468M
file_encoding(clean_path) %>% 
  mutate(across(path, path.abbrev))
#> # A tibble: 1 × 3
#>   path                                                                                mime  charset
#>   <fs::path>                                                                          <chr> <chr>  
#> 1 …/code/accountability_datacleaning/state/oh/expends/data/clean/oh_expends_clean.csv <NA>  <NA>
```

## Upload

We can use the `aws.s3::put_object()` to upload the text file to the IRW
server.

``` r
s3_path <- path("csv", basename(clean_path))
if (!object_exists(s3_path, "publicaccountability")) {
  put_object(
    file = clean_path,
    object = s3_path, 
    bucket = "publicaccountability",
    acl = "public-read",
    multipart = TRUE,
    show_progress = TRUE
  )
}
```

``` r
as_fs_bytes(object_size(s3_path, "publicaccountability"))
```

## Dictionary

The following table describes the variables in our final exported file:

| Column          | Original               | Type        | Definition                             |
|:----------------|:-----------------------|:------------|:---------------------------------------|
| `com_name`      | `COM_NAME`             | `character` | Spending committee name                |
| `master_key`    | `MASTER_KEY`           | `integer`   | Master key                             |
| `rpt_year`      | `RPT_YEAR`             | `integer`   | Year report filed                      |
| `rpt_key`       | `REPORT_KEY`           | `integer`   | Unique report key                      |
| `rpt_desc`      | `REPORT_DESCRIPTION`   | `character` | Type of report filed                   |
| `desc`          | `SHORT_DESCRIPTION`    | `character` | Description of report                  |
| `first`         | `FIRST_NAME`           | `character` | Full contributor name                  |
| `middle`        | `MIDDLE_NAME`          | `character` | Contributor first name                 |
| `last`          | `LAST_NAME`            | `character` | Contributor middle name                |
| `suffix`        | `SUFFIX_NAME`          | `character` | Contributor last name                  |
| `non_ind`       | `NON_INDIVIDUAL`       | `character` | Contributor name suffix                |
| `address`       | `ADDRESS`              | `character` | Contributor non-individual name        |
| `city`          | `CITY`                 | `character` | Contributor street address             |
| `state`         | `STATE`                | `character` | Contributor city name                  |
| `zip`           | `ZIP`                  | `character` | Contributor state abbreviation         |
| `date`          | `EXPEND_DATE`          | `double`    | Contributor ZIP+4 code                 |
| `amount`        | `AMOUNT`               | `double`    | Date contribution made                 |
| `event`         | `EVENT_DATE`           | `double`    | Contribution amount                    |
| `purpose`       | `PURPOSE`              | `character` | Date fundraising event hosted          |
| `inkind`        | `INKIND`               | `logical`   | Contribution purpose                   |
| `cand_first`    | `CANDIDATE FIRST NAME` | `character` | Flag indicating in-kind contribution   |
| `cand_last`     | `CANDIDATE LAST NAME`  | `character` | Receiving candidate first name         |
| `office`        | `OFFICE`               | `character` | Receiving candidate last name          |
| `district`      | `DISTRICT`             | `integer`   | Office sought by candidate             |
| `party`         | `PARTY`                | `character` | District sought by candidate           |
| `file_path`     |                        | `character` | Candidate political party              |
| `file_type`     |                        | `character` | Data source file name                  |
| `file_year`     |                        | `double`    | Data source file type                  |
| `pay_name`      |                        | `character` | Data source file year                  |
| `na_flag`       |                        | `logical`   | Flag for missing date, amount, or name |
| `dupe_flag`     |                        | `logical`   | Flag for completely duplicated record  |
| `year`          |                        | `double`    | Calendar year of contribution date     |
| `address_clean` |                        | `character` | Normalized combined street address     |
| `zip_clean`     |                        | `character` | Normalized 5-digit ZIP code            |
| `state_clean`   |                        | `character` | Normalized state abbreviation          |
| `city_clean`    |                        | `character` | Normalized city name                   |
