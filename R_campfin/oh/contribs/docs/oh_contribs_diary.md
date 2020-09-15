Ohio Contributions
================
Kiernan Nicholls
2020-09-14 23:01:07

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
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
#> [1] "/home/kiernan/Code/tap/R_campfin"
```

## Data

The data is obtained from the [Ohio Secretary of
State](https://www.ohiosos.gov/). The OH SOS offers a file transfer page
(FTP) to download data in bulk rather than via searches.

> Welcome to the Ohio Secretary of State’s Campaign Finance File
> Transfer Page. This page was developed to allow users to obtain large
> sets of data faster than the normal query process. At this page you
> can download files of pre-queried data, such as all candidate
> Contributions for a particular year or a list of all active political
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
      paste("-P", raw_dir)
    )
  )
}
```

``` r
raw_dir <- dir_create(here("oh", "contribs", "data", "raw"))
raw_urls <- paste0(ftp_base, ftp_params)
if (length(dir_ls(raw_dir)) < 84) {
  map(raw_urls, wget, raw_dir)
}
```

``` r
raw_info <- dir_info(raw_dir)
sum(raw_info$size)
#> 2.04G
(raw_files <- raw_info %>%
  select(file_path = path, size, modification_time) %>% 
  mutate(file_id = as.character(row_number()), .before = 1) %>% 
  mutate(across(file_path, basename)))
#> # A tibble: 92 x 4
#>    file_id file_path                   size modification_time  
#>    <chr>   <chr>                <fs::bytes> <dttm>             
#>  1 1       ALL_CAN_CON_1994.CSV       8.62M 2020-04-14 14:03:08
#>  2 2       ALL_CAN_CON_1995.CSV       5.89M 2020-04-14 14:03:06
#>  3 3       ALL_CAN_CON_1996.CSV       14.4M 2020-04-14 14:03:05
#>  4 4       ALL_CAN_CON_1997.CSV       8.25M 2020-04-14 14:03:02
#>  5 5       ALL_CAN_CON_1998.CSV      21.56M 2020-04-14 14:03:00
#>  6 6       ALL_CAN_CON_1999.CSV       8.31M 2020-04-14 14:02:56
#>  7 7       ALL_CAN_CON_2000.CSV      16.49M 2020-04-14 14:02:54
#>  8 8       ALL_CAN_CON_2001.CSV       9.03M 2020-04-14 14:02:51
#>  9 9       ALL_CAN_CON_2002.CSV      20.57M 2020-04-14 14:02:48
#> 10 10      ALL_CAN_CON_2003.CSV       8.71M 2020-04-14 14:02:45
#> # … with 82 more rows
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

We can read all 92 raw CSV files into a single data frame using
`purrr::map_df()` and `readr::read_csv()`. There are some columns that
only exist in the files containing contributions from a PAC, party, etc.
Most columns are shared across all files, so when we join them together
into a single data frame, empty rows will be created for those unique
columns.

``` r
ohc <- map_df(
  .x = raw_info$path,
  .f = read_csv,
  .id = "file_id",
  na = c("", "NA", "N/A"),
  col_types = cols(
    .default = col_character(),
    MASTER_KEY = col_integer(),
    RPT_YEAR = col_integer(),
    REPORT_KEY = col_integer(),
    FILE_DATE = col_date_usa(),
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
fil_types <- ohc %>% 
  count(file_path, sort = TRUE) %>% 
  extract(
    col = file_path,
    into = c("file_type", "file_year"),
    regex = "(?:ALL_)?(\\w{3})_CON_(\\d{4})\\.CSV",
    remove = FALSE,
    convert = TRUE
  ) %>% 
  mutate(
    file_type = file_type %>% 
      str_replace("CAC", "CAN") %>% 
      str_replace("PPC", "PAR")
  )
```

![](../plots/fil_plot-1.png)<!-- -->

``` r
ohc <- left_join(ohc, fil_types[, -4], by = "file_path")
```

## Explore

There are 10,780,321 rows of 31 columns.

``` r
glimpse(ohc)
#> Rows: 10,780,321
#> Columns: 31
#> $ com_name           <chr> "FRIENDS OF GOVERNOR TAFT", "FRIENDS OF GOVERNOR TAFT", "FRIENDS OF G…
#> $ master_key         <int> 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, …
#> $ rpt_desc           <chr> "PRE-GENERAL", "PRE-GENERAL", "PRE-PRIMARY", "PRE-GENERAL", "PRE-GENE…
#> $ rpt_year           <int> 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, 199…
#> $ rpt_key            <int> 133090, 133090, 133054, 133090, 133090, 133090, 133090, 133090, 13313…
#> $ desc               <chr> "31-E FR Contributions", "31-E FR Contributions", "31-A  Stmt of Cont…
#> $ first              <chr> "LAWRENCE", "GLENN", "PETE", "BARBARA", "BARBARA", "MARLIN", "ROGER",…
#> $ middle             <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ last               <chr> "ABBOTT", "ABEL", "ABELE", "ABER", "ABER", "ACH", "ACH", "ACHTERMAN",…
#> $ suffix             <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ non_ind            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ pac_reg_no         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ address            <chr> "2400 HARRISON RD.", "1482 KREBS DR.", "502 N. MARKET ST.", "1720 HAR…
#> $ city               <chr> "COLUMBUS", "NEWARK", "MCARTHUR", "COLUMBUS", "COLUMBUS", "CINCINNATI…
#> $ state              <chr> "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH…
#> $ zip                <chr> "43204", "43055", "45651", "43229", "43229", "45246", "45206", "43015…
#> $ date               <date> 1994-06-14, 1994-09-15, 1994-03-25, 1994-06-21, 1994-10-03, 1994-06-…
#> $ amount             <dbl> 500.00, 25.00, 100.00, 100.00, 50.00, 496.63, 500.00, 150.00, 350.00,…
#> $ event              <date> 1994-06-30, 1994-09-14, NA, 1994-06-30, 1994-10-02, NA, NA, 1994-10-…
#> $ emp_occupation     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ inkind_description <chr> NA, NA, NA, NA, NA, "FOOD & BEVERAGE", NA, NA, NA, NA, NA, NA, NA, NA…
#> $ other_income_type  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ rcv_event          <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ cand_first         <chr> "BOB", "BOB", "BOB", "BOB", "BOB", "BOB", "BOB", "BOB", "BOB", "BOB",…
#> $ cand_last          <chr> "TAFT", "TAFT", "TAFT", "TAFT", "TAFT", "TAFT", "TAFT", "TAFT", "TAFT…
#> $ office             <chr> "SECRETARY OF STATE", "SECRETARY OF STATE", "SECRETARY OF STATE", "SE…
#> $ district           <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ party              <chr> "REPUBLICAN", "REPUBLICAN", "REPUBLICAN", "REPUBLICAN", "REPUBLICAN",…
#> $ file_path          <chr> "ALL_CAN_CON_1994.CSV", "ALL_CAN_CON_1994.CSV", "ALL_CAN_CON_1994.CSV…
#> $ file_type          <chr> "CAN", "CAN", "CAN", "CAN", "CAN", "CAN", "CAN", "CAN", "CAN", "CAN",…
#> $ file_year          <int> 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, 1994, 199…
tail(ohc)
#> # A tibble: 6 x 31
#>   com_name master_key rpt_desc rpt_year rpt_key desc  first middle last  suffix non_ind pac_reg_no
#>   <chr>         <int> <chr>       <int>   <int> <chr> <chr> <chr>  <chr> <chr>  <chr>   <chr>     
#> 1 LIBERTA…      12841 PRE-PRI…     2020  3.61e8 31-A… MATT… <NA>   YODER <NA>   <NA>    <NA>      
#> 2 LIBERTA…      12841 PRE-PRI…     2020  3.61e8 31-A… MATT… <NA>   YODER <NA>   <NA>    <NA>      
#> 3 LIBERTA…      12841 PRE-PRI…     2020  3.61e8 31-A… DAN   <NA>   ZINK  <NA>   <NA>    <NA>      
#> 4 LIBERTA…      12842 PRE-PRI…     2020  3.61e8 31-A… PATR… <NA>   GLAS… <NA>   <NA>    <NA>      
#> 5 LIBERTA…      12842 PRE-PRI…     2020  3.61e8 31-A… PATR… <NA>   GLAS… <NA>   <NA>    <NA>      
#> 6 MAHONIN…      13141 PRE-PRI…     2020  3.62e8 31-C… <NA>  <NA>   <NA>  <NA>   CHEMIC… <NA>      
#> # … with 19 more variables: address <chr>, city <chr>, state <chr>, zip <chr>, date <date>,
#> #   amount <dbl>, event <date>, emp_occupation <chr>, inkind_description <chr>,
#> #   other_income_type <chr>, rcv_event <lgl>, cand_first <chr>, cand_last <chr>, office <chr>,
#> #   district <int>, party <chr>, file_path <chr>, file_type <chr>, file_year <int>
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(ohc, count_na)
#> # A tibble: 31 x 4
#>    col                class         n           p
#>    <chr>              <chr>     <int>       <dbl>
#>  1 com_name           <chr>         4 0.000000371
#>  2 master_key         <int>         0 0          
#>  3 rpt_desc           <chr>         0 0          
#>  4 rpt_year           <int>         0 0          
#>  5 rpt_key            <int>         0 0          
#>  6 desc               <chr>         0 0          
#>  7 first              <chr>    571061 0.0530     
#>  8 middle             <chr>   5671173 0.526      
#>  9 last               <chr>    551882 0.0512     
#> 10 suffix             <chr>  10613187 0.984      
#> 11 non_ind            <chr>  10226470 0.949      
#> 12 pac_reg_no         <chr>   2120300 0.197      
#> 13 address            <chr>     83858 0.00778    
#> 14 city               <chr>     80341 0.00745    
#> 15 state              <chr>     72450 0.00672    
#> 16 zip                <chr>     69272 0.00643    
#> 17 date               <date>     8019 0.000744   
#> 18 amount             <dbl>      3115 0.000289   
#> 19 event              <date>  9836080 0.912      
#> 20 emp_occupation     <chr>   3835061 0.356      
#> 21 inkind_description <chr>  10703295 0.993      
#> 22 other_income_type  <chr>  10719160 0.994      
#> 23 rcv_event          <lgl>   8031974 0.745      
#> 24 cand_first         <chr>   8641470 0.802      
#> 25 cand_last          <chr>   8641067 0.802      
#> 26 office             <chr>   8641049 0.802      
#> 27 district           <int>   8685144 0.806      
#> 28 party              <chr>   8641456 0.802      
#> 29 file_path          <chr>         0 0          
#> 30 file_type          <chr>         0 0          
#> 31 file_year          <int>         0 0
```

We can flag records missing a name, date, or amount after uniting the
multiple contributor name columns into a single variable.

``` r
ohc <- ohc %>% 
  unite(
    first, middle, last, suffix, non_ind,
    col = pay_name,
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(across(pay_name, na_if, "")) %>% 
  relocate(pay_name, .after = last_col()) %>% 
  flag_na(date, pay_name, amount, com_name)
```

0.11% of rows are missing a key variable.

``` r
mean(ohc$na_flag)
#> [1] 0.001067779
ohc %>% 
  filter(na_flag) %>% 
  select(date, pay_name, amount, com_name)
#> # A tibble: 11,511 x 4
#>    date       pay_name                      amount com_name                                 
#>    <date>     <chr>                          <dbl> <chr>                                    
#>  1 1995-01-27 BERNARD JENKINS                 62.4 <NA>                                     
#>  2 1995-01-27 BERNARD JENKINS                235   <NA>                                     
#>  3 1995-04-27 BERNARD JENKINS                500   <NA>                                     
#>  4 NA         JOHN GRIFFIN                    80   JOHN W. GRIFFIN COMMITTEE                
#>  5 NA         STARK COUNTY REPUBLICAN PARTY  434.  HARPER FOR JUSTICE COMMITTEE             
#>  6 NA         STARK COUNTY REPUBLICAN PARTY  630.  HARPER FOR JUSTICE COMMITTEE             
#>  7 1995-12-31 <NA>                            18.5 FRIENDS OF MARTHA W. WISE                
#>  8 1995-08-16 <NA>                           450   LATELL FOR STATE REPRESENTATIVE          
#>  9 1995-03-10 <NA>                            10   INDEPENDENT-CHRISTIAN COMMITTEE-TIRBOVICH
#> 10 NA         TRANSFER FROM 31-C            2290.  BARRY LEVEY OHIO SENATE COMMITTEE        
#> # … with 11,501 more rows
```

### Duplicate

There are actually quite a few duplicate values in the data. While it’s
possible for the same person to contribute the same amount to the same
committee on the same day, we can flag these values anyway.

``` r
ohc <- mutate(ohc, row = row_number(), .before = 1)
```

``` r
dupe_file <- here("oh", "contribs", "dupes.txt")
if (!file_exists(dupe_file)) {
  ohs <- keep(group_split(ohc, date), ~nrow(.) > 1)
  pb <- txtProgressBar(max = length(ohs), style = 3)
  for (i in seq_along(ohs)) {
    # check dupes from both ends
    d1 <- duplicated(ohs[[i]][, -1], fromLast = FALSE)
    d2 <- duplicated(ohs[[i]][, -1], fromLast = TRUE)
    # append to disk
    dupes <- tibble(row = ohs[[i]]$row, dupe_flag = d1 | d2)
    dupes <- filter(dupes, dupe_flag)
    write_csv(dupes, dupe_file, append = file_exists(dupe_file))
    rm(d1, d2, dupes)
    ohs[[i]] <- NA
    if (i %% 100 == 0) {
      Sys.sleep(1)
      flush_memory(1)
    }
    setTxtProgressBar(pb, value = i)
  }
  rm(ohs)
}
```

``` r
dupes <- read_csv(dupe_file)
ohc <- ohc %>% 
  left_join(dupes) %>% 
  select(-row) %>% 
  mutate(dupe_flag = !is.na(dupe_flag))
```

After all that work, there are 593,799 duplicate records

5.5% of rows are duplicated at least once.

``` r
ohc %>% 
  filter(dupe_flag, date > "2010-01-01") %>% 
  arrange(pay_name) %>% 
  select(date, pay_name, amount, com_name)
#> # A tibble: 247,060 x 4
#>    date       pay_name               amount com_name                                               
#>    <date>     <chr>                   <dbl> <chr>                                                  
#>  1 2018-02-15 |DEBRA G. SMITH            15 CORDRAY/SUTTON COMMITTEE                               
#>  2 2018-02-15 |DEBRA G. SMITH            15 CORDRAY/SUTTON COMMITTEE                               
#>  3 2015-02-05 5/3 BANK                   11 REPUBLICANS FOR A NEW LUCAS COUNTY PAC (RNLCPAC)       
#>  4 2015-02-05 5/3 BANK                   11 REPUBLICANS FOR A NEW LUCAS COUNTY PAC (RNLCPAC)       
#>  5 2015-02-05 5/3 BANK                   11 REPUBLICANS FOR A NEW LUCAS COUNTY PAC (RNLCPAC)       
#>  6 2015-10-28 76826773 LLC (RG1 LLC) 100000 RESPONSIBLE OHIO PAC                                   
#>  7 2015-10-28 76826773 LLC (RG1 LLC) 100000 RESPONSIBLE OHIO PAC                                   
#>  8 2013-01-09 A A                         5 FREEDOM OHIO                                           
#>  9 2013-01-09 A A                         5 FREEDOM OHIO                                           
#> 10 2017-01-05 A HILARIE MAGISTRALE        1 OHIO EDUCATION ASSOC FUND FOR CHILDREN AND PUBLIC EDUC…
#> # … with 247,050 more rows
```

### Amounts

``` r
summary(ohc$amount)
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max.     NA's 
#>   -50000        2        6      253       35 17295083     3115
prop_na(ohc$amount)
#> [1] 0.0002889524
mean(ohc$amount <= 0, na.rm = TRUE)
#> [1] 0.0007730204
```

There are the smallest and largest transactions.

``` r
glimpse(ohc[c(which.min(ohc$amount), which.max(ohc$amount)), ])
#> Rows: 2
#> Columns: 34
#> $ com_name           <chr> "REPUBLICAN NATIONAL STATE ELECTIONS COMMITTEE - OPERATING", "OHIOANS…
#> $ master_key         <int> 5009, 14664
#> $ rpt_desc           <chr> "TERMINATION", "PRE-GENERAL"
#> $ rpt_year           <int> 2003, 2017
#> $ rpt_key            <int> 440032, 308467282
#> $ desc               <chr> "31-A  Stmt of Contribution", "31-A  Stmt of Contribution"
#> $ first              <chr> "A.J.", NA
#> $ middle             <chr> NA, NA
#> $ last               <chr> "DE COSTER", NA
#> $ suffix             <chr> NA, NA
#> $ non_ind            <chr> NA, "OHIOANS AGAINST THE DECEPTIVE RX BALLOT ISSUE LLC (A WHOLLY-OWNE…
#> $ pac_reg_no         <chr> NA, "BI1760"
#> $ address            <chr> "PO BOX 342", "100 S. THIRD ST."
#> $ city               <chr> "CLARION", "COLUMBUS"
#> $ state              <chr> "IA", "OH"
#> $ zip                <chr> "50525", "43215"
#> $ date               <date> 2002-12-31, 2017-07-28
#> $ amount             <dbl> -50000, 17295083
#> $ event              <date> NA, NA
#> $ emp_occupation     <chr> "DE COSTER FARMS/ PRESIDENT", NA
#> $ inkind_description <chr> NA, NA
#> $ other_income_type  <chr> NA, NA
#> $ rcv_event          <lgl> FALSE, NA
#> $ cand_first         <chr> NA, NA
#> $ cand_last          <chr> NA, NA
#> $ office             <chr> NA, NA
#> $ district           <int> NA, NA
#> $ party              <chr> NA, NA
#> $ file_path          <chr> "ALL_PAR_CON_2003.CSV", "PAC_CON_2017.CSV"
#> $ file_type          <chr> "PAR", "PAC"
#> $ file_year          <int> 2003, 2017
#> $ pay_name           <chr> "A.J. DE COSTER", "OHIOANS AGAINST THE DECEPTIVE RX BALLOT ISSUE LLC …
#> $ na_flag            <lgl> FALSE, FALSE
#> $ dupe_flag          <lgl> FALSE, FALSE
```

The `amount` values are logarithmically normally distributed.

![](../plots/hist_amount-1.png)<!-- -->

### Dates

We can create a new column with a 4-digit year from the `date`.

``` r
ohc <- mutate(ohc, year = year(date))
```

There are few `date` values with typos making them really small or
large.

``` r
min(ohc$date, na.rm = TRUE)
#> [1] "10-05-07"
sum(ohc$year < 1990, na.rm = TRUE)
#> [1] 1210
max(ohc$date, na.rm = TRUE)
#> [1] "9999-03-31"
sum(ohc$date > today(), na.rm = TRUE)
#> [1] 1446
```

For dates outside the expected range, we will rely instead on the file
year.

``` r
ohc <- mutate(
  .data = ohc, 
  date_flag = is.na(date) | date > today() | year < 1990,
  year = if_else(date_flag, file_year, as.integer(year))
)
mean(ohc$date_flag)
#> [1] 0.0009902303
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
  address = unique(ohc$address),
  address_norm = normal_address(
    address = address,
    abbs = usps_street,
    na_rep = TRUE
  )
)
```

``` r
ohc <- left_join(ohc, oh_addr_norm, by = "address")
```

    #> # A tibble: 1,828,406 x 2
    #>    address            address_norm     
    #>    <chr>              <chr>            
    #>  1 2400 HARRISON RD.  2400 HARRISON RD 
    #>  2 1482 KREBS DR.     1482 KREBS DR    
    #>  3 502 N. MARKET ST.  502 N MARKET ST  
    #>  4 1720 HARRINGTON    1720 HARRINGTON  
    #>  5 45 E. FOUNTAIN     45 E FOUNTAIN    
    #>  6 5 BEECHREST LN.    5 BEECHREST LN   
    #>  7 5245 DUBLIN RD.    5245 DUBLIN RD   
    #>  8 227 PRESTON RD.    227 PRESTON RD   
    #>  9 695 KENWICK RD.    695 KENWICK RD   
    #> 10 1201 EDGECLIFF PL. 1201 EDGECLIFF PL
    #> # … with 1,828,396 more rows

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
ohc <- mutate(
  .data = ohc,
  zip_norm = normal_zip(
    zip = zip,
    na_rep = TRUE
  )
)
```

``` r
progress_table(
  ohc$zip,
  ohc$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na   n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl>   <dbl>  <dbl>
#> 1 zip        0.826     350584 0.00643 1861644 329986
#> 2 zip_norm   0.998      27515 0.0206    15889   3063
```

### State

``` r
prop_in(ohc$state, valid_state)
#> [1] 0.9997051
ohc <- mutate(ohc, state_norm = normal_state(state))
ohc$state_norm[which(ohc$state == "0H")] <- "OH"
ohc$state_norm[which(ohc$state == "IH")] <- "OH"
ohc$state_norm[which(ohc$state == "PH")] <- "OH"
ohc$state_norm[which(ohc$state == "O")]  <- "OH"
ohc$state_norm[str_which(ohc$state, "^O\\W$")]  <- "OH"
ohc$state_norm[str_which(ohc$state, "^\\WH$")]  <- "OH"
prop_in(ohc$state_norm, valid_state)
#> [1] 0.9998159
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
ohc <- mutate(
  .data = ohc,
  city_norm = normal_city(
    city = city, 
    abbs = usps_city,
    states = c("OH", "DC", "OHIO"),
    na = c(invalid_city, "UNAVAILABLE"),
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
ohc <- ohc %>% 
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
good_refine <- ohc %>% 
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
  ) %>% 
  distinct()
```

    #> # A tibble: 520 x 5
    #>    state_norm zip_norm city_swap       city_refine        n
    #>    <chr>      <chr>    <chr>           <chr>          <int>
    #>  1 OH         45245    CINCINATTI      CINCINNATI       126
    #>  2 OH         45239    CINCINATTI      CINCINNATI       101
    #>  3 OH         44094    WILLOUGHBY HI   WILLOUGHBY        96
    #>  4 OH         44657    MINVERA         MINERVA           55
    #>  5 OH         44094    WILLOUGHBY HILL WILLOUGHBY        46
    #>  6 NY         11733    SETAUKET        EAST SETAUKET     42
    #>  7 OH         44721    NO CANTON       CANTON            38
    #>  8 OH         43334    MERANGO         MARENGO           23
    #>  9 OH         45247    CINCINATTI      CINCINNATI        21
    #> 10 OH         44413    PALESTINE       EAST PALESTINE    20
    #> # … with 510 more rows

Then we can join the refined values back to the database.

``` r
row_pre <- nrow(ohc)
ohc <- ohc %>% 
  left_join(good_refine, by = names(ohc)) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

``` r
if (row_pre != nrow(ohc)) {
  stop("extra rows were added")
}
```

#### Progress

``` r
many_city <- c(valid_city, extra_city)
ohc %>% 
  filter(city_refine %out% many_city) %>% 
  count(city_refine, state_norm, zip_norm, sort = TRUE) %>% 
  drop_na() %>% 
  left_join(
    y = zipcodes, 
    by = c(
      "zip_norm" = "zip", 
      "state_norm" = "state"
    )
  )
#> # A tibble: 8,821 x 5
#>    city_refine       state_norm zip_norm     n city          
#>    <chr>             <chr>      <chr>    <int> <chr>         
#>  1 SAGAMORE HILLS    OH         44067     6493 NORTHFIELD    
#>  2 OLMSTED TOWNSHIP  OH         44138     5352 OLMSTED FALLS 
#>  3 EAST CLEVELAND    OH         44112     5016 CLEVELAND     
#>  4 SHEFFIELD VILLAGE OH         44054     3345 SHEFFIELD LAKE
#>  5 WILLOUGHBY HILLS  OH         44094     3319 WILLOUGHBY    
#>  6 BEDFORD HEIGHTS   OH         44146     2968 BEDFORD       
#>  7 MAYFIELD VILLAGE  OH         44143     2113 CLEVELAND     
#>  8 WILLOUGHBY HILLS  OH         44092     1551 WICKLIFFE     
#>  9 WEST WORTHINGTON  OH         43235     1444 COLUMBUS      
#> 10 SOUTH AMHERST     OH         44001     1123 AMHERST       
#> # … with 8,811 more rows
```

| stage        | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :----------- | -------: | ----------: | -------: | -----: | ------: |
| city\_raw    |    0.960 |       32685 |    0.007 | 430857 |   20839 |
| city\_norm   |    0.983 |       30242 |    0.011 | 183526 |   18329 |
| city\_swap   |    0.991 |       21477 |    0.011 |  91333 |    9569 |
| city\_refine |    0.992 |       21063 |    0.011 |  89752 |    9156 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/bar_progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar_distinct-1.png)<!-- -->

## Conclude

``` r
ohc <- ohc %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_remove(., "_raw")) %>% 
  rename_all(~str_replace(., "_norm", "_clean"))
```

``` r
glimpse(sample_n(ohc, 50))
#> Rows: 50
#> Columns: 40
#> $ com_name           <chr> "OHIO EDUCATION ASSOC FUND FOR CHILDREN AND PUBLIC EDUCATION", "REALT…
#> $ master_key         <int> 1814, 1515, 2050, 1577, 1780, 10285, 1683, 2047, 1814, 12856, 1477, 1…
#> $ rpt_desc           <chr> "PRE-PRIMARY", "PRE-PRIMARY", "PRE-GENERAL", "POST-PRIMARY", "PRE-GEN…
#> $ rpt_year           <int> 2006, 2002, 2013, 2005, 2004, 2009, 1998, 2009, 2010, 2010, 2018, 200…
#> $ rpt_key            <int> 866809, 696520, 141348298, 811093, 834430, 280957, 584986, 1013395, 8…
#> $ desc               <chr> "31-A  Stmt of Contribution", "31-A  Stmt of Contribution", "31-A  St…
#> $ first              <chr> "ROBYN", "WARREN D", "MATTHEW", "DONALD", "MARY ANN", "JEAN", "DAPHNE…
#> $ middle             <chr> "L", NA, NA, "H", NA, "B.", NA, NA, "A", NA, NA, "J", NA, "W", NA, NA…
#> $ last               <chr> "SCHMIEDEBUSCH", "MILLER", "SPARLING", "JOHNSON", "WRIGHT", "JOHNS", …
#> $ suffix             <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "JR", NA, NA, NA,…
#> $ non_ind            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ pac_reg_no         <chr> "OH299", "CP401", "OH729", "CP718", "OH214", NA, "LA766", "OH723", "O…
#> $ address            <chr> "223 OTTAWA GLANDORF RD", "2277 ANNANDALE PL", "950 ORCHARD AVE", "84…
#> $ city               <chr> "OTTAWA", "XENIA", "AURORA", "CINCINNATI", "HUBBARD", "CINCINNATI", "…
#> $ state              <chr> "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH…
#> $ zip                <chr> "45875", "45385-9122", "44202", "45247", "44425", "45226-2013", "4322…
#> $ date               <date> 2006-01-23, 2002-02-05, 2013-10-11, 2005-05-19, 2004-05-03, 2009-05-…
#> $ amount             <dbl> 1.00, 20.00, 18.00, 20.00, 14.00, 25.00, 1.00, 50.00, 1.00, 50.00, 25…
#> $ event              <date> NA, NA, NA, NA, NA, 2009-05-15, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ emp_occupation     <chr> "OEA", "REAL ESTATE SALESPERSON", "CITY OF PARMA HEIGHTS", "COCA-COLA…
#> $ inkind_description <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ other_income_type  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ rcv_event          <lgl> NA, NA, NA, NA, NA, NA, FALSE, FALSE, NA, NA, NA, NA, NA, NA, FALSE, …
#> $ cand_first         <chr> NA, NA, NA, NA, NA, "TED", NA, NA, NA, "JOHN", NA, NA, NA, "JOHN", NA…
#> $ cand_last          <chr> NA, NA, NA, NA, NA, "STRICKLAND", NA, NA, NA, "KASICH", NA, NA, NA, "…
#> $ office             <chr> NA, NA, NA, NA, NA, "GOVERNOR", NA, NA, NA, "GOVERNOR", NA, NA, NA, "…
#> $ district           <int> NA, NA, NA, NA, NA, 0, NA, NA, NA, 0, NA, NA, NA, 38, NA, 24, NA, 33,…
#> $ party              <chr> NA, NA, NA, NA, NA, "DEMOCRAT", NA, NA, NA, "REPUBLICAN", NA, NA, NA,…
#> $ file_path          <chr> "ALL_PAC_CON_2006.CSV", "ALL_PAC_CON_2002.CSV", "PAC_CON_2013.CSV", "…
#> $ file_type          <chr> "PAC", "PAC", "PAC", "PAC", "PAC", "CAN", "PAC", "PAC", "PAC", "CAN",…
#> $ file_year          <int> 2006, 2002, 2013, 2005, 2004, 2009, 1998, 2009, 2010, 2010, 2018, 200…
#> $ pay_name           <chr> "ROBYN L SCHMIEDEBUSCH", "WARREN D MILLER", "MATTHEW SPARLING", "DONA…
#> $ na_flag            <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ dupe_flag          <lgl> TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
#> $ year               <int> 2006, 2002, 2013, 2005, 2004, 2009, 1998, 2009, 2010, 2010, 2018, 200…
#> $ date_flag          <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ address_clean      <chr> "223 OTTAWA GLANDORF RD", "2277 ANNANDALE PL", "950 ORCH AVE", "8428 …
#> $ zip_clean          <chr> "45875", "45385", "44202", "45247", "44425", "45226", "43227", "43113…
#> $ state_clean        <chr> "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH", "OH…
#> $ city_clean         <chr> "OTTAWA", "XENIA", "AURORA", "CINCINNATI", "HUBBARD", "CINCINNATI", "…
```

1.  There are 10,780,321 records in the database.
2.  The range and distribution of `amount` and `date` seem reasonable.
3.  There are 11,511 records missing a key variable.
4.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
5.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
clean_dir <- dir_create(here("oh", "contribs", "data", "clean"))
clean_path <- path(clean_dir, "oh_expends_clean.csv")
write_csv(ohc, clean_path, na = "")
file_size(clean_path)
#> 3.11G
file_encoding(clean_path) %>% 
  mutate(across(path, path.abbrev))
#> # A tibble: 1 x 3
#>   path                                          mime            charset 
#>   <chr>                                         <chr>           <chr>   
#> 1 ~/oh/contribs/data/clean/oh_expends_clean.csv application/csv us-ascii
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
r <- head_object(s3_path, "publicaccountability")
as_fs_bytes(attr(r, "content-length"))
#> 3.11G
```

## Dictionary

The following table describes the variables in our final exported file:

| Column               | Original               | Type        | Definition                                    |
| :------------------- | :--------------------- | :---------- | :-------------------------------------------- |
| `com_name`           | `COM_NAME`             | `character` | Spending committee name                       |
| `master_key`         | `MASTER_KEY`           | `integer`   | Master key                                    |
| `rpt_desc`           | `REPORT_DESCRIPTION`   | `character` | Year report filed                             |
| `rpt_year`           | `RPT_YEAR`             | `integer`   | Unique report key                             |
| `rpt_key`            | `REPORT_KEY`           | `integer`   | Type of report filed                          |
| `desc`               | `SHORT_DESCRIPTION`    | `character` | Description of report                         |
| `first`              | `FIRST_NAME`           | `character` | Full contributor name                         |
| `middle`             | `MIDDLE_NAME`          | `character` | Contributor first name                        |
| `last`               | `LAST_NAME`            | `character` | Contributor middle name                       |
| `suffix`             | `SUFFIX_NAME`          | `character` | Contributor last name                         |
| `non_ind`            | `NON_INDIVIDUAL`       | `character` | Contributor name suffix                       |
| `pac_reg_no`         | `PAC_REG_NO`           | `character` | Contributor non-individual name               |
| `address`            | `ADDRESS`              | `character` | PAC registration number                       |
| `city`               | `CITY`                 | `character` | Contributor street address                    |
| `state`              | `STATE`                | `character` | Contributor city name                         |
| `zip`                | `ZIP`                  | `character` | Contributor state abbreviation                |
| `date`               | `FILE_DATE`            | `double`    | Contributor ZIP+4 code                        |
| `amount`             | `AMOUNT`               | `double`    | Date contribution made                        |
| `event`              | `EVENT_DATE`           | `double`    | Contribution amount                           |
| `emp_occupation`     | `EMP_OCCUPATION`       | `character` | Date fundraising event hosted                 |
| `inkind_description` | `INKIND_DESCRIPTION`   | `character` | Employeer occupation                          |
| `other_income_type`  | `OTHER_INCOME_TYPE`    | `character` | Non-contribution income type                  |
| `rcv_event`          | `RCV_EVENT`            | `logical`   | Flag indicating RCV(?) event                  |
| `cand_first`         | `CANDIDATE_FIRST_NAME` | `character` | Receiving candidate first name                |
| `cand_last`          | `CANDIDATE_LAST_NAME`  | `character` | Receiving candidate last name                 |
| `office`             | `OFFICE`               | `character` | Office sought by candidate                    |
| `district`           | `DISTRICT`             | `integer`   | District sought by candidate                  |
| `party`              | `PARTY`                | `character` | Candidate political party                     |
| `file_path`          |                        | `character` | Data source file name                         |
| `file_type`          |                        | `character` | Data source file type (Candidate, PAC, Party) |
| `file_year`          |                        | `integer`   | Data source file year                         |
| `pay_name`           |                        | `character` | Combined paying contributior name             |
| `na_flag`            |                        | `logical`   | Flag for missing date, amount, or name        |
| `dupe_flag`          |                        | `logical`   | Flag for completely duplicated record         |
| `year`               |                        | `integer`   | Calendar year of contribution date            |
| `date_flag`          |                        | `logical`   | Flag indicating past or future date           |
| `address_clean`      |                        | `character` | Normalized combined street address            |
| `zip_clean`          |                        | `character` | Normalized 5-digit ZIP code                   |
| `state_clean`        |                        | `character` | Normalized state abbreviation                 |
| `city_clean`         |                        | `character` | Normalized city name                          |
