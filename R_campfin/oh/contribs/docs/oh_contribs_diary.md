Ohio Contributions
================
Kiernan Nicholls
2020-02-18 16:16:41

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)

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

The data is obtained from the [Ohio Secretary of
State](https://www.ohiosos.gov/). The OH SOS offers a file transfer page
(FTP) to download data in bulk rather than via searches.

> Welcome to the Ohio Secretary of State’s Campaign Finance File
> Transfer Page. This page was developed to allow users to obtain large
> sets of data faster than the normal query process. At this page you
> can download files of pre-queried data, such as all candidate
> contributions for a particular year or a list of all active political
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

We can download all the contribution files by reading the FTP website
itself and scraping each of the “Download” links in the table. This
process needs to be repeated for candidates, PACs, and parties.

``` r
ftp_base <- "https://www6.ohiosos.gov/ords/"
t <- c("CAN", "PAC", "PARTY")
ftp_url <- glue("f?p=CFDISCLOSURE:73:7027737052457:{t}:NO:RP:P73_TYPE:{t}:")
ftp_url <- str_c(ftp_base, ftp_url)
ftp_params <- character()
ftp_table <- rep(list(NA), length(t))
for (i in seq_along(t)) {
  ftp_page <- read_html(ftp_url[i])
  table_id <- paste0("#", str_extract(ftp_page, '(?<=id\\=")report_.*(?="\\s)'))
  ftp_table[[i]] <- ftp_page %>%
    html_node(table_id) %>%
    html_table() %>%
    as_tibble() %>%
    select(-last_col()) %>%
    set_names(c("file", "date", "size")) %>%
    mutate_at(vars(2), parse_date_time, "%m/%d/%Y %H:%M:%S %p")
  con_index <- str_which(ftp_table[[i]]$file, "Contributions\\s-\\s\\d+")
  ftp_params <- ftp_page %>%
    html_node(table_id) %>%
    html_nodes("tr") %>%
    html_nodes("a") %>%
    html_attr("href") %>%
    str_subset("f\\?p") %>%
    extract(con_index) %>%
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
      paste("-P", raw_dir)
    )
  )
}

quiet_wget <- quietly(wget)
```

``` r
raw_dir <- dir_create(here("oh", "contribs", "data", "raw"))
raw_urls <- paste0(ftp_base, ftp_params)
if (length(dir_ls(raw_dir)) < 82) {
  map(raw_urls, quiet_wget, raw_dir)
}
raw_paths <- dir_ls(raw_dir)
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

We can read all 82 raw CSV files into a single data frame using
`purrr::map_df()` and `readr::read_csv()`.

``` r
ohc <- map_df(
  .x = sample(raw_paths, 2),
  .f = read_csv,
  na = c("", "NA", "N/A"),
  col_types = cols(.default = "c")
)

# ohc <- ohc %>% 
#   mutate_at(vars(FILE_DATE), parse_date, "%m/%d/%Y") %>% 
#   mutate_at(vars(AMOUNT), parse_double) %>% 
#   mutate_at(vars(MASTER_KEY, RPT_YEAR, REPORT_KEY, DISTRICT), parse_integer) 
```

## Explore

``` r
head(ohc)
#> # A tibble: 6 x 28
#>   com_name pac_no master_key rpt_year rpt_key rpt_desc desc  first middle last  suffix non_ind
#>   <chr>    <chr>  <chr>      <chr>    <chr>   <chr>    <chr> <chr> <chr>  <chr> <chr>  <chr>  
#> 1 ALLSTAT… C0004… 1096       1993     274228  FEDERAL  31-A… <NA>  <NA>   <NA>  <NA>   ARONOF…
#> 2 REYNOLD… C0004… 1108       1993     279724  FEDERAL  31-A… <NA>  <NA>   <NA>  <NA>   CITIZE…
#> 3 REYNOLD… C0004… 1108       1993     279724  FEDERAL  31-A… <NA>  <NA>   <NA>  <NA>   SENATO…
#> 4 BAYER C… C0004… 1109       1993     271834  FEDERAL  31-A… <NA>  <NA>   <NA>  <NA>   DRAKE …
#> 5 NRA POL… C0005… 1117       1993     262396  FEDERAL  31-A… <NA>  <NA>   <NA>  <NA>   SCHMIT…
#> 6 WASTE M… C0011… 1213       1993     257725  FEDERAL  31-A… <NA>  <NA>   <NA>  <NA>   CORDRA…
#> # … with 16 more variables: address <chr>, city <chr>, state <chr>, zip <chr>, date <chr>,
#> #   amount <chr>, event <chr>, occupation <chr>, inkind <chr>, other_type <chr>, rcv_event <chr>,
#> #   cand_first <chr>, cand_last <chr>, office <chr>, district <chr>, party <chr>
tail(ohc)
#> # A tibble: 6 x 28
#>   com_name pac_no master_key rpt_year rpt_key rpt_desc desc  first middle last  suffix non_ind
#>   <chr>    <chr>  <chr>      <chr>    <chr>   <chr>    <chr> <chr> <chr>  <chr> <chr>  <chr>  
#> 1 FRIENDS… <NA>   14303      2014     181258… ANNUAL … 31-A… GARY  S      HORT… <NA>   <NA>   
#> 2 FRIENDS… <NA>   14303      2014     181258… ANNUAL … 31-A… GARY  S      HORT… <NA>   <NA>   
#> 3 FRIENDS… <NA>   14303      2014     181258… ANNUAL … 31-A… PATR… A      LIPPS <NA>   <NA>   
#> 4 FRIENDS… <NA>   14303      2014     181258… ANNUAL … 31-A… PHIL… SCOTT  LIPPS <NA>   <NA>   
#> 5 FRIENDS… <NA>   14303      2014     181258… ANNUAL … 31-A… FRANK R      MCCA… <NA>   <NA>   
#> 6 FRIENDS… <NA>   14303      2014     181258… ANNUAL … 31-A… HOLLY M      TODD  <NA>   <NA>   
#> # … with 16 more variables: address <chr>, city <chr>, state <chr>, zip <chr>, date <chr>,
#> #   amount <chr>, event <chr>, occupation <chr>, inkind <chr>, other_type <chr>, rcv_event <chr>,
#> #   cand_first <chr>, cand_last <chr>, office <chr>, district <chr>, party <chr>
glimpse(sample_n(ohc, 20))
#> Rows: 20
#> Columns: 28
#> $ com_name   <chr> "REALTORS PAC", "FRIENDS OF FITZGERALD", "CITIZENS FOR PEPPER COMMITTEE", "OH…
#> $ pac_no     <chr> "CP401", NA, NA, "OH534", "CP127", NA, "OH259", "OH299", NA, "OH259", "OH607"…
#> $ master_key <chr> "1515", "8069", "12865", "1925", "1467", "12856", "1793", "1814", "8069", "17…
#> $ rpt_year   <chr> "1993", "2014", "2014", "1993", "1993", "2014", "1993", "1993", "2014", "1993…
#> $ rpt_key    <chr> "327763", "170249284", "173190694", "513943", "321037", "169565554", "476563"…
#> $ rpt_desc   <chr> "PRE-GENERAL", "AUGUST MONTHLY", "SEPTEMBER MONTHLY", "PRE-GENERAL", "ANNUAL …
#> $ desc       <chr> "31-A  Stmt of Contribution", "31-A  Stmt of Contribution", "31-A  Stmt of Co…
#> $ first      <chr> "CHARYL", "CATHERINE", "GUS", "GEORGE", "LINDA", "LINDA", "HOWAN", "LINDA", "…
#> $ middle     <chr> NA, "R.", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "J", "H", NA, "ROBERT", NA,…
#> $ last       <chr> "HYRE", "MATISI", "PERDIKAKIS", "MAIER", "WENSOLE", "STARSKY", "HSU", "HORWAT…
#> $ suffix     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
#> $ non_ind    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
#> $ address    <chr> "25 S. PLUM ST.", "PO BOX 87", "8306 SUNFISH LN", "1122 ORRVILLE N.W.", "1051…
#> $ city       <chr> "TROY", "STEWART", "MAINEVILLE", "MASSILLON", "LIMA", "AVENTURA", "DUBLIN", "…
#> $ state      <chr> "OH", "OH", "OH", "OH", "OH", "FL", "OH", "OH", "OH", "OH", "OH", "OH", "OH",…
#> $ zip        <chr> "45373", "45778-0087", "45039-8980", "44647", "0", "33180-2404", "43017", "44…
#> $ date       <chr> "06/28/1993", "08/11/2014", "10/02/2014", "05/15/1993", "12/17/1993", "06/16/…
#> $ amount     <chr> "10", "500", "250", "12", "1", "150", "3.75", "28", "15", "3.75", "1000", "6.…
#> $ event      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "01/21/1993", NA, "04/14/2014", NA, N…
#> $ occupation <chr> NA, "WORTHINGTON CENTER PSYCHIATRIST", "GUS PERDIKAKIS ASSOCIATES INC PRESIDE…
#> $ inkind     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
#> $ other_type <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
#> $ rcv_event  <chr> "N", NA, NA, "N", "N", NA, "N", "N", NA, "N", "N", "N", NA, NA, NA, NA, NA, N…
#> $ cand_first <chr> NA, "EDWARD", "DAVID", NA, NA, "JOHN", NA, NA, "EDWARD", NA, NA, NA, "MICHELE…
#> $ cand_last  <chr> NA, "FITZGERALD", "PEPPER", NA, NA, "KASICH", NA, NA, "FITZGERALD", NA, NA, N…
#> $ office     <chr> NA, "GOVERNOR", "ATTORNEY GENERAL", NA, NA, "GOVERNOR", NA, NA, "GOVERNOR", N…
#> $ district   <chr> NA, "0", "0", NA, NA, "0", NA, NA, "0", NA, NA, NA, "58", "0", "0", "19", "33…
#> $ party      <chr> NA, "DEMOCRAT", "DEMOCRAT", NA, NA, "REPUBLICAN", NA, NA, "DEMOCRAT", NA, NA,…
```

### Missing

``` r
col_stats(ohc, count_na)
#> # A tibble: 28 x 4
#>    col        class      n        p
#>    <chr>      <chr>  <int>    <dbl>
#>  1 com_name   <chr>      0 0       
#>  2 pac_no     <chr> 136703 0.499   
#>  3 master_key <chr>      0 0       
#>  4 rpt_year   <chr>      0 0       
#>  5 rpt_key    <chr>      0 0       
#>  6 rpt_desc   <chr>      0 0       
#>  7 desc       <chr>      0 0       
#>  8 first      <chr>  21501 0.0785  
#>  9 middle     <chr> 238700 0.872   
#> 10 last       <chr>  21605 0.0789  
#> 11 suffix     <chr> 270081 0.986   
#> 12 non_ind    <chr> 252185 0.921   
#> 13 address    <chr>   4376 0.0160  
#> 14 city       <chr>   4269 0.0156  
#> 15 state      <chr>   4510 0.0165  
#> 16 zip        <chr>   1426 0.00521 
#> 17 date       <chr>     66 0.000241
#> 18 amount     <chr>     35 0.000128
#> 19 event      <chr> 226632 0.828   
#> 20 occupation <chr> 163510 0.597   
#> 21 inkind     <chr> 268513 0.981   
#> 22 other_type <chr> 271324 0.991   
#> 23 rcv_event  <chr> 144755 0.529   
#> 24 cand_first <chr> 127356 0.465   
#> 25 cand_last  <chr> 127340 0.465   
#> 26 office     <chr> 127340 0.465   
#> 27 district   <chr> 127340 0.465   
#> 28 party      <chr> 127340 0.465
```

``` r
ohc <- ohc %>% 
  unite(
    first, middle, last, non_ind,
    col = con_name,
    sep = " ",
    na.rm = TRUE
  ) %>% 
  flag_na(date, con_name, amount, com_name)

sum(ohc$na_flag)
#> [1] 101
percent(mean(ohc$na_flag), 0.01)
#> [1] "0.04%"
```
