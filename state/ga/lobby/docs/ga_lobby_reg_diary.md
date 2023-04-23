Georgia Lobbyying Registration
================
Yanqi Xu
2023-04-23 13:24:35

- <a href="#project" id="toc-project">Project</a>
- <a href="#objectives" id="toc-objectives">Objectives</a>
- <a href="#packages" id="toc-packages">Packages</a>
- <a href="#data" id="toc-data">Data</a>
- <a href="#download" id="toc-download">Download</a>
- <a href="#explore" id="toc-explore">Explore</a>
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
  readxl, #read excel files
  lubridate, # datetime strings
  gluedown, # printing markdown
  magrittr, # pipe operators
  janitor, # clean data frames
  refinr, # cluster and merge
  scales, # format strings
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
```

## Data

Lobbying data is obtained from the [Georgia Government Transparency and
Campaign Finance
Commission](https://media.ethics.ga.gov/search/Lobbyist/Lobbyist_Menu.aspx).
We use the Lobbyist Roster under the **Search Lobbyist** feature to
return a list of lobbyists. There’re two options for the data output,
organized by group or lobbyist. We will use the Lobbyist Group Roster so
that the data is organized by clients in relation to the lobbyists they
employed.

Note that the data is separated by year, and we will use `httr` to
obtain each year’s data via a `POST` request, whose parameters can be
found from network activities.w

There are two types of rosters, lobbying groups and lobbyists. We’ll
download both for each year.

For this update, we downloaded all the files from 2004 to the end of
2022. THe next update should start with 2023.

## Download

We can set up the raw directory.

``` r
raw_dir <- dir_create(here("state","ga", "lobby", "data", "raw","reg"))
raw_lob_paths <- path(raw_dir, glue("ga_lob_{2006:2022}.csv"))
```

The curl command is preprocessed to include `listGroup={c(LGR,LR)}` and
`listYear={2004:2020}`

``` r
ga_lob_curls <- glue(read_file(path(raw_dir,"ga_lob_curl.sh")))

ga_lob_download <- function(ga_curl,curl_type) { 
  #listGroup=LGR for lobbyist roster, and listGroup=LR for group roster
  #curl_type <- ifelse(test = str_detect(ga_curl,"listGroup=LGR"),yes = "lob", no = "grp")
  this_year <- ga_curl %>% str_extract("(?<=listYear=)\\d{4}")
  raw_path <- path(raw_dir, glue("ga_{curl_type}_{this_year}.xls"))
  if (!this_file_new(raw_path)) {
  write_lines(
  # x = system(paste("bash", path(raw_dir,"ga_curl.sh")), intern = TRUE),
  x = system(ga_curl, intern = TRUE),
  path = raw_path
)
  }
}

map2(ga_lob_curls,"lob",ga_lob_download)

### the 2001-2003 xls file can be accessed via a GET request
download.file("https://media.ethics.ga.gov/search/Lobbyist/Exp/Ros_2003_2001.xls", path(raw_dir,"ga_lob_0103.xls"))
```

We can view the file details here.

``` r
dir_info(raw_dir)
#> # A tibble: 58 × 18
#>    path        type   size permiss…¹ modification_time   user  group devic…² hard_…³ speci…⁴  inode
#>    <fs::path>  <fct> <fs:> <fs::per> <dttm>              <chr> <chr>   <dbl>   <dbl>   <dbl>  <dbl>
#>  1 …p_2004.xls file      0 rw-r--r-- 2020-09-04 09:50:34 yanq… staff  1.68e7       1       0 2.36e7
#>  2 …p_2005.xls file      0 rw-r--r-- 2020-09-04 09:50:34 yanq… staff  1.68e7       1       0 2.36e7
#>  3 …p_2006.csv file  1.05M rw-r--r-- 2020-09-09 13:42:14 yanq… staff  1.68e7       1       0 2.41e7
#>  4 …p_2006.xls file  2.27M rw-r--r-- 2020-09-04 09:50:35 yanq… staff  1.68e7       1       0 2.36e7
#>  5 …p_2007.csv file  3.29M rw-r--r-- 2020-09-09 13:46:08 yanq… staff  1.68e7       1       0 2.41e7
#>  6 …p_2007.xls file  7.18M rw-r--r-- 2020-09-04 09:50:37 yanq… staff  1.68e7       1       0 2.36e7
#>  7 …p_2008.csv file  3.31M rw-r--r-- 2020-09-09 13:50:08 yanq… staff  1.68e7       1       0 2.41e7
#>  8 …p_2008.xls file  7.22M rw-r--r-- 2020-09-04 09:50:39 yanq… staff  1.68e7       1       0 2.36e7
#>  9 …p_2009.csv file  3.33M rw-r--r-- 2020-09-09 13:53:37 yanq… staff  1.68e7       1       0 2.41e7
#> 10 …p_2009.xls file  7.28M rw-r--r-- 2020-09-04 09:31:01 yanq… staff  1.68e7       1       0 2.36e7
#> # … with 48 more rows, 7 more variables: block_size <dbl>, blocks <dbl>, flags <int>,
#> #   generation <dbl>, access_time <dttm>, change_time <dttm>, birth_time <dttm>, and abbreviated
#> #   variable names ¹​permissions, ²​device_id, ³​hard_links, ⁴​special_device_id
```

We can see that for year 2004 and 2005 the files are actually empty, so
we’ll disregard these two when reading.

### Read

The 2001—2003 data has rows to escape. So we’ll read the two datasets
separately. The file’s also not in a standard Excel format, so we will
use `rvest` to scrape the html content. We’ll also add the year to each
dataframe.

We will also read in the group rosters separately, which contain
addresses of principals/clients.

``` r
ga_lob_read <- function(ga_path){
  year_from_file <- str_extract(ga_path,"20\\d{2}")
  lob_type <- str_extract(ga_path,"(?<=_)\\w{3}(?=_\\d+)")
  lob_file <- path(raw_dir, glue("ga_{lob_type}_{year_from_file}.csv"))
if (file_exists(lob_file)) {
  message("File for year {year_from_file} already converted, skipping")
} else {
  message(glue("Start converting file for year {year_from_file}"))
  ga_html <- ga_path %>% read_html()
  ga_node <- ga_html %>% html_node("table")
  ga_table <- ga_node %>% html_table()
  names(ga_table) <- ga_table[1,] %>% unlist()
  ga_table <- ga_table[2:nrow(ga_table),]
  ga_table <- ga_table %>% 
    mutate(Year = year_from_file)
    write_csv(
    x = ga_table,
    file = lob_file
  )
    message(glue("Conversion completed for year {year_from_file}"))
}
}

ga_lob <- map_dfr(raw_lob_paths[1], ga_lob_read)
```

``` r
galr <- dir_ls(raw_dir,regexp = ".*lob_.*.csv") %>% 
  map_dfr(read_csv,col_types = cols(.default = col_character(),
                                    DateRegistered = col_date("%m/%d/%Y %H:%M:%S %p"),
                                    DateTerminated = col_date("%m/%d/%Y %H:%M:%S %p"),
                                    PaymentExceeds = col_logical()
          )) %>% 
          clean_names()

galr_early <- dir_ls(raw_dir, regexp = ".+0103.xls") %>% read_xls(skip = 1,col_types = "text") %>% clean_names()
```

``` r
galr_grp <- dir_ls(raw_dir, regexp = ".*grp_.*.csv") %>% 
    map_dfr(read_csv,col_types = cols(.default = col_character(),
                                    DateRegistered = col_date("%m/%d/%Y %H:%M:%S %p"),
                                    DateTerminated = col_date("%m/%d/%Y %H:%M:%S %p"),
                                    PaymentExceeds = col_logical()
          )) %>% 
          clean_names()

galr_grp <- galr_grp %>% select(association,filer_id,address1, address2, phone, city, state,zip,phone, date_registered, year) %>% unique()
```

According to the website, the `PaymentExceeds` column is a logical
vector indicating whether payments have exceeded \$10,000.

We will also need to rename some columns in the 01-03 files to keep it
consistent with the later files.

``` r
galr_early <- galr_early %>% 
  mutate(year = str_sub(docket_year, start = 1L, end = 4L),
         registered = excel_numeric_to_date(as.numeric(registered))) %>% 
  rename(association= association_name,
         date_registered = registered,
         first_name = first,
         middle_name = middle,
         last_name = last)
```

### Duplicates

There are some duplicate records.

``` r
galr <- flag_dupes(galr, everything())
galr_early <- flag_dupes(galr_early, everything())
galr_grp <- flag_dupes(galr_grp, everything())
#> Warning in flag_dupes(galr_grp, everything()): no duplicate rows, column not created
sum(galr$dupe_flag)
#> [1] 841
sum(galr_early$dupe_flag)
#> [1] 22
```

## Explore

``` r
glimpse(galr)
#> Rows: 243,615
#> Columns: 21
#> $ filer_id        <chr> "L20050485", "L20050485", "L20050272", "L20050601", "L20051071", "L200502…
#> $ last_name       <chr> "ABERCROMBIE", "ABERCROMBIE", "ADAMS", "ADAMS", "ADAMS", "ADAMS", "ADAMS"…
#> $ suffix          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ first_name      <chr> "ALYSON", "ALYSON", "ALEXANDRA", "BILLY", "JUDITH", "NORMER", "PAMELA", "…
#> $ middle_name     <chr> "B.", "B.", NA, "L.", "M.", "M.", "LYNN", "COOGLE", "ANTHONY", "SUK", "B.…
#> $ address1        <chr> "1940 THE EXCHANGE SUITE 100", "1940 THE EXCHANGE SUITE 100", "3 PURITAN …
#> $ address2        <chr> NA, NA, "916 JOSEPH LOWERY BLVD.", NA, NA, NA, NA, NA, NA, "SUITE 130", N…
#> $ city            <chr> "ATLANTA", "ATLANTA", "ATLANTA", "DUBLIN", "MARIETTA", "FAYETTEVILLE", "F…
#> $ state           <chr> "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "…
#> $ zip             <chr> "30339", "30339", "30318", "31021", "30062", "30214", "30214", "30204", "…
#> $ phone           <chr> "6782984100", "6782984100", "4043529828", "(478) 272 - 5400", "7705654531…
#> $ phone_ext       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ phone2          <chr> NA, NA, NA, NA, NA, "(770) 461 - 2778", NA, NA, NA, "(770) 925 - 0112", N…
#> $ public_e_mail   <chr> NA, NA, "aadams@ucriverkeeper.org", NA, NA, "normer@gahsc.org", "pamela@g…
#> $ association     <chr> "GEORGIA BRANCH, ASSOCIATED GENERAL CONTRACTORS", "GEORGIA BRANCH, ASSOCI…
#> $ payment_exceeds <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ date_registered <date> 2006-01-01, 2006-01-01, 2006-01-01, 2006-01-01, 2006-01-01, 2006-01-01, …
#> $ date_terminated <date> 2006-12-31, 2006-12-31, 2008-12-31, 2012-12-31, 2006-12-31, 2014-07-01, …
#> $ lobbying_level  <chr> "STATE", "LOCAL", "STATE", "STATE", "STATE", "STATE", "VENDOR", "STATE", …
#> $ year            <chr> "2006", "2006", "2006", "2006", "2006", "2006", "2006", "2006", "2006", "…
#> $ dupe_flag       <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
tail(galr)
#> # A tibble: 6 × 21
#>   filer_id  last_name suffix first…¹ middl…² addre…³ addre…⁴ city  state zip   phone phone…⁵ phone2
#>   <chr>     <chr>     <chr>  <chr>   <chr>   <chr>   <chr>   <chr> <chr> <chr> <chr> <chr>   <chr> 
#> 1 L20200137 ZANDO     <NA>   CHERYL  <NA>    9450 S… #57224  BEAV… OR    97008 (202… <NA>    <NA>  
#> 2 L20200137 ZANDO     <NA>   CHERYL  <NA>    9450 S… #57224  BEAV… OR    97008 (202… <NA>    <NA>  
#> 3 L20110012 ZAUNER    <NA>   JOHN    FRANCIS 9 JEFF… <NA>    NEWN… GA    30263 (678… <NA>    <NA>  
#> 4 L20220109 ZOLLER    <NA>   MARTHA  M       4921 R… <NA>    GAIN… GA    30506 (770… <NA>    <NA>  
#> 5 L20220109 ZOLLER    <NA>   MARTHA  M       4921 R… <NA>    GAIN… GA    30506 (770… <NA>    <NA>  
#> 6 L20210094 ZORC      <NA>   LAURA   <NA>    111 K … STE. 6… WASH… DC    20002 (202… <NA>    <NA>  
#> # … with 8 more variables: public_e_mail <chr>, association <chr>, payment_exceeds <lgl>,
#> #   date_registered <date>, date_terminated <date>, lobbying_level <chr>, year <chr>,
#> #   dupe_flag <lgl>, and abbreviated variable names ¹​first_name, ²​middle_name, ³​address1,
#> #   ⁴​address2, ⁵​phone_ext
glimpse(galr_early)
#> Rows: 8,244
#> Columns: 16
#> $ docket_year     <chr> "20010001", "20010002", "20010003", "20010004", "20010005", "20010006", "…
#> $ first_name      <chr> "Gloria", "Jerry", "Ralph", "Missy", "Secundina", "Raymon", "Raymon", "Ra…
#> $ middle_name     <chr> "Kemp", "R", "T", NA, "Angelic", "E.", "E.", "E.", "E.", "E.", "E.", "E."…
#> $ last_name       <chr> "Engelke", "Gossett", "Bowden", "Moore", "Moore", "White", "White", "Whit…
#> $ suffix          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ address         <chr> "P.o.box 7021", "9570 Medlock Bridge Rd.", "One Decatur Towncenter Suite …
#> $ address_1       <chr> NA, "Suite 201", "150 E. Ponce De Leon Ave.", NA, NA, "Suite 3493", "Suit…
#> $ city            <chr> "Atlanta", "Duluth", "Decatur", "Atlanta", "Atlanta", "Atlanta", "Atlanta…
#> $ state           <chr> "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "…
#> $ zip             <chr> "30357", "30097", "300302547", "30329", "30305", "30339", "30339", "30339…
#> $ phone           <chr> "4048761720", "6784730012", "4043733131", "7703179458", "4049325482", "77…
#> $ date_registered <date> 2000-12-27, 2000-12-27, 2000-12-27, 2000-12-27, 2000-12-27, 2000-12-27, …
#> $ association     <chr> "Ga Citizens For The Arts", "Ga. Crushed Stone Association", "Georgia Equ…
#> $ level           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ year            <chr> "2001", "2001", "2001", "2001", "2001", "2001", "2001", "2001", "2001", "…
#> $ dupe_flag       <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
tail(galr_early)
#> # A tibble: 6 × 16
#>   docke…¹ first…² middl…³ last_…⁴ suffix address addre…⁵ city  state zip   phone date_reg…⁶ assoc…⁷
#>   <chr>   <chr>   <chr>   <chr>   <chr>  <chr>   <chr>   <chr> <chr> <chr> <chr> <date>     <chr>  
#> 1 200313… TAMARA  K.      YOUNG   <NA>   <NA>    3723 R… DECA… GA    30034 4042… 2003-11-03 CITY O…
#> 2 200313… RAY     A.      BARREN… <NA>   <NA>    1191 G… LOUI… GA    30434 4786… 2003-10-28 GA. PO…
#> 3 200313… WILLIAM DON     CHASTA… <NA>   <NA>    P.O.BO… ATLA… GA    3037… 4046… 2003-10-15 GA. ST…
#> 4 200313… WALTER  <NA>    DUKES   <NA>   <NA>    1607 W… AUGU… GA    3090… 7067… 2003-10-28 GA. PO…
#> 5 200313… E.      LANIER  FINCH   <NA>   8010 R… SUITE … ATLA… GA    30350 7703… 2003-11-03 GA. AS…
#> 6 200313… MICHAEL A.      CADGER  <NA>   1311 M… <NA>    DUNW… GA    30338 7708… 2003-12-05 THE GA…
#> # … with 3 more variables: level <chr>, year <chr>, dupe_flag <lgl>, and abbreviated variable
#> #   names ¹​docket_year, ²​first_name, ³​middle_name, ⁴​last_name, ⁵​address_1, ⁶​date_registered,
#> #   ⁷​association
glimpse(galr_grp)
#> Rows: 129,164
#> Columns: 10
#> $ association     <chr> "ALTRIA CLIENT SERVICES INC. AND ITS AFFILIATES", "ALTRIA CLIENT SERVICES…
#> $ filer_id        <chr> "L20050927", "L20050697", "L20050666", "L20060123", "L20050529", "L200506…
#> $ address1        <chr> "333 NORTH POINT CENTER EAST, SUITE 615", "333 N. POINT CENTER E", "333 N…
#> $ address2        <chr> NA, "SUITE 615", "SUITE 600", NA, NA, NA, NA, NA, NA, "3000", "52", "1859…
#> $ phone           <chr> "(800) 367 - 7998", "(800) 367 - 7998", "(800) 367 - 7998", "(404) 949 - …
#> $ city            <chr> "ALPHARETTA", "ALPHARETTA", "ALPHARETTA", "ATLANTA", "MASON", "DRAPER", "…
#> $ state           <chr> "GA", "GA", "GA", "GA", "OH", "UT", "UT", "UT", "UT", "GA", "GA", "GA", "…
#> $ zip             <chr> "30022", "30022", "30022", "30343", "45040", "84020", "84020", "84020", "…
#> $ date_registered <date> 2006-01-05, 2006-01-01, 2006-01-01, 2006-01-06, 2006-01-01, 2006-02-07, …
#> $ year            <chr> "2006", "2006", "2006", "2006", "2006", "2006", "2006", "2006", "2006", "…
tail(galr_grp)
#> # A tibble: 6 × 10
#>   association      filer_id  address1              addre…¹ phone city  state zip   date_reg…² year 
#>   <chr>            <chr>     <chr>                 <chr>   <chr> <chr> <chr> <chr> <date>     <chr>
#> 1 ZELIS HEALTHCARE L20050590 TWO CONCOURSE PARKWAY 300     4046… ATLA… GA    30303 2018-02-21 2020 
#> 2 ZILLOW GROUP     L20080329 1301 SECOND AVENUE    31ST F… 2063… SEAT… WA    98101 2018-08-21 2020 
#> 3 ZILLOW GROUP     L20050034 1301 SECOND AVENUE    31ST F… 206-… SEAT… WA    98101 2019-10-04 2020 
#> 4 ZILLOW GROUP     L20130011 1301 SECOND AVENUE    31ST F… 2063… SEAT… WA    98101 2018-08-21 2020 
#> 5 ZOO ATLANTA      L20050688 800 CHEROKEE AVENUE,… <NA>    (404… ATLA… GA    30315 2006-01-01 2020 
#> 6 ZOO ATLANTA      L20190131 800 CHEROKEE AVE., SE <NA>    (404… ATLA… GA    30315 2020-01-22 2020 
#> # … with abbreviated variable names ¹​address2, ²​date_registered
```

### Missing

``` r
col_stats(galr, count_na)
#> # A tibble: 21 × 4
#>    col             class       n          p
#>    <chr>           <chr>   <int>      <dbl>
#>  1 filer_id        <chr>       0 0         
#>  2 last_name       <chr>       0 0         
#>  3 suffix          <chr>  235440 0.966     
#>  4 first_name      <chr>       0 0         
#>  5 middle_name     <chr>   61113 0.251     
#>  6 address1        <chr>       6 0.0000246 
#>  7 address2        <chr>   97046 0.398     
#>  8 city            <chr>       0 0         
#>  9 state           <chr>       2 0.00000821
#> 10 zip             <chr>      15 0.0000616 
#> 11 phone           <chr>      50 0.000205  
#> 12 phone_ext       <chr>  243615 1         
#> 13 phone2          <chr>  225435 0.925     
#> 14 public_e_mail   <chr>  121877 0.500     
#> 15 association     <chr>       0 0         
#> 16 payment_exceeds <lgl>       0 0         
#> 17 date_registered <date>      0 0         
#> 18 date_terminated <date>  95897 0.394     
#> 19 lobbying_level  <chr>       0 0         
#> 20 year            <chr>       0 0         
#> 21 dupe_flag       <lgl>       0 0
col_stats(galr_early, count_na)
#> # A tibble: 16 × 4
#>    col             class      n        p
#>    <chr>           <chr>  <int>    <dbl>
#>  1 docket_year     <chr>      0 0       
#>  2 first_name      <chr>     10 0.00121 
#>  3 middle_name     <chr>   2150 0.261   
#>  4 last_name       <chr>      2 0.000243
#>  5 suffix          <chr>   8135 0.987   
#>  6 address         <chr>   1971 0.239   
#>  7 address_1       <chr>   1236 0.150   
#>  8 city            <chr>      0 0       
#>  9 state           <chr>      0 0       
#> 10 zip             <chr>      0 0       
#> 11 phone           <chr>      3 0.000364
#> 12 date_registered <date>    30 0.00364 
#> 13 association     <chr>      0 0       
#> 14 level           <chr>   5184 0.629   
#> 15 year            <chr>      0 0       
#> 16 dupe_flag       <lgl>      0 0
col_stats(galr_grp, count_na)
#> # A tibble: 10 × 4
#>    col             class      n       p
#>    <chr>           <chr>  <int>   <dbl>
#>  1 association     <chr>      0 0      
#>  2 filer_id        <chr>      0 0      
#>  3 address1        <chr>    321 0.00249
#>  4 address2        <chr>  72491 0.561  
#>  5 phone           <chr>   4237 0.0328 
#>  6 city            <chr>    313 0.00242
#>  7 state           <chr>    341 0.00264
#>  8 zip             <chr>    668 0.00517
#>  9 date_registered <date>     0 0      
#> 10 year            <chr>      0 0
```

``` r
galr <- galr %>% flag_na(filer_id,first_name,last_name,date_registered,association)
galr_early <- galr_early %>% flag_na(first_name,last_name,date_registered, association)
sum(galr$na_flag)
#> [1] 0
sum(galr_early$na_flag)
#> [1] 42
```

``` r
galr %>% 
  filter(na_flag) %>% 
  select(filer_id, first_name,last_name, date_registered,association)
#> # A tibble: 0 × 5
#> # … with 5 variables: filer_id <chr>, first_name <chr>, last_name <chr>, date_registered <date>,
#> #   association <chr>

galr_early %>% 
  filter(na_flag) %>% 
  select(first_name,last_name, date_registered,association)
#> # A tibble: 42 × 4
#>    first_name last_name date_registered association                                                
#>    <chr>      <chr>     <date>          <chr>                                                      
#>  1 Saralyn    <NA>      2002-01-08      Secretary Of State,elections Division                      
#>  2 KAREN      <NA>      2002-07-11      Progressive Insurance                                      
#>  3 RANDY      CRAWFORD  NA              BAKERY CONFECTIONARY TOBACCO & GRAIN MILLERS INTERNATIONAL…
#>  4 RICKEY     CRAWFORD  NA              BAKERY CONFECTIONARY TOBACCO & GRAIN MILLER INTERNATIONAL …
#>  5 J.         ALLEN     NA              GA. FORESTRY COMMISSION                                    
#>  6 ROBERT     FARRIS    NA              GA. FORESTRY COMMISSION                                    
#>  7 WILLIAM    LAZENBY   NA              GA. FORESTRY COMMISSION                                    
#>  8 MIKE       VAQUER    NA              INTERNATIONAL PAPER                                        
#>  9 CARLOTTA   FRANKLIN  NA              METRO ATLANTA CHAMBER OF COMMERCE                          
#> 10 SAMUEL     GARDNER   NA              SPALDING COUNTY                                            
#> # … with 32 more rows
```

``` r
galr_grp <- galr_grp %>% rename_at(.vars = vars(3:8), .funs = ~ str_c("grp_",.))
galr_grp$grp_address1[which(galr_grp$grp_address1 == "2400 WEST LLYOD EXPRESSWAY")] <- "2400 WEST LLOYD EXPRESSWAY"

galr_grp <- galr_grp %>% group_by(association) %>% 
  filter(date_registered == min(date_registered))

galr_grp <- galr_grp %>% select(-date_registered)

galr_grp <- galr_grp %>% flag_dupes(everything())

galr_grp <- galr_grp %>% filter(!dupe_flag)

galr <- galr %>% left_join(galr_grp)
```

### Categorical

``` r
col_stats(galr, n_distinct)
#> # A tibble: 28 × 4
#>    col             class      n          p
#>    <chr>           <chr>  <int>      <dbl>
#>  1 filer_id        <chr>   5064 0.0208    
#>  2 last_name       <chr>   3061 0.0126    
#>  3 suffix          <chr>      9 0.0000369 
#>  4 first_name      <chr>   1523 0.00625   
#>  5 middle_name     <chr>   1057 0.00434   
#>  6 address1        <chr>   4110 0.0169    
#>  7 address2        <chr>   1158 0.00475   
#>  8 city            <chr>    481 0.00197   
#>  9 state           <chr>     42 0.000172  
#> 10 zip             <chr>    833 0.00342   
#> 11 phone           <chr>   4375 0.0180    
#> 12 phone_ext       <chr>      1 0.00000410
#> 13 phone2          <chr>    167 0.000686  
#> 14 public_e_mail   <chr>    805 0.00330   
#> 15 association     <chr>   8459 0.0347    
#> 16 payment_exceeds <lgl>      2 0.00000821
#> 17 date_registered <date>  3218 0.0132    
#> 18 date_terminated <date>  2513 0.0103    
#> 19 lobbying_level  <chr>      6 0.0000246 
#> 20 year            <chr>     17 0.0000698 
#> 21 dupe_flag       <lgl>      2 0.00000821
#> 22 na_flag         <lgl>      1 0.00000410
#> 23 grp_address1    <chr>   6376 0.0262    
#> 24 grp_address2    <chr>   1288 0.00529   
#> 25 grp_phone       <chr>   6418 0.0263    
#> 26 grp_city        <chr>    905 0.00371   
#> 27 grp_state       <chr>     50 0.000205  
#> 28 grp_zip         <chr>   1562 0.00641
```

### Dates

We can examine the validity of `date_clean`. It looks pretty clean.

``` r
min(galr$date_registered)
#> [1] "2006-01-01"
max(galr$date_registered)
#> [1] "2023-04-14"
sum(galr$date_registered > today())
#> [1] 0
```

``` r
min(galr_early$date_registered)
#> [1] NA
max(galr_early$date_registered)
#> [1] NA
sum(galr_early$date_registered > today())
#> [1] NA
```

![](../plots/bar_year-1.png)<!-- -->

## Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are tailor made to facilitate this process. To normalize the
lobbyist phone number variable, will will combine the number and
extension with `tidyr::unite()` and pass the united string to
`campfin::normal_phone()`.

``` r
galr <- galr %>% 
  unite(
    phone, phone_ext,
    col = "phone_norm",
    sep = "x",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    phone_norm = normal_phone(
      number = "phone_norm",
      na_bad = FALSE,
      rm_ext = FALSE
    ),
      grp_phone_norm = normal_phone(
      number = "grp_phone",
      na_bad = FALSE,
      rm_ext = FALSE
    )
  )

galr_early <- galr_early %>% 
  mutate(
    phone_norm = normal_phone(
      number = "Phone",
      na_bad = FALSE,
      rm_ext = FALSE
    )
  )
```

    #> # A tibble: 4,375 × 3
    #>    phone            phone_ext phone_norm
    #>    <chr>            <chr>     <chr>     
    #>  1 (770) 627 - 7501 <NA>      phone_norm
    #>  2 (404) 506 - 6084 <NA>      phone_norm
    #>  3 (404) 506 - 7915 <NA>      phone_norm
    #>  4 (404) 506 - 7740 <NA>      phone_norm
    #>  5 (404) 975 - 8176 <NA>      phone_norm
    #>  6 (678) 595 - 9326 <NA>      phone_norm
    #>  7 (706) 272 - 6173 <NA>      phone_norm
    #>  8 (770) 617 - 9913 <NA>      phone_norm
    #>  9 (478) 993 - 4521 <NA>      phone_norm
    #> 10 (706) 846 - 2592 <NA>      phone_norm
    #> # … with 4,365 more rows
    #> # A tibble: 1,590 × 2
    #>    phone      phone_norm
    #>    <chr>      <chr>     
    #>  1 2298884750 Phone     
    #>  2 7704916343 Phone     
    #>  3 4046107452 Phone     
    #>  4 8506812591 Phone     
    #>  5 4046563508 Phone     
    #>  6 7703957200 Phone     
    #>  7 7709921874 Phone     
    #>  8 7709937896 Phone     
    #>  9 4042921551 Phone     
    #> 10 4049310969 Phone     
    #> # … with 1,580 more rows

### Address

For the street `addresss` variable, the `campfin::normal_address()`
function will force consistence case, remove punctuation, and abbreviate
official USPS suffixes.

``` r
galr <- galr %>% 
  # combine street addr
  unite(
    col = address_full,
    starts_with("address"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
    unite(
    col = grp_address_full,
    starts_with("grp_address"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
   address_norm = normal_address(
     address = address_full,
     abbs = usps_street,
     na = invalid_city
   ),
    grp_address_norm = normal_address(
     address = grp_address_full,
     abbs = usps_street,
     na = invalid_city
   ),
 ) 

galr_early <- galr_early %>% 
  # combine street addr
  unite(
    col = address_full,
    starts_with("Address"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
   address_norm = normal_address(
     address = address_full,
     abbs = usps_street,
     na = invalid_city
   )
 )
```

``` r
galr %>% 
  select(address_full, address_norm) %>% 
  distinct() %>% 
  sample_n(10)
#> # A tibble: 10 × 2
#>    address_full                   address_norm                 
#>    <chr>                          <chr>                        
#>  1 1425 MARKET BLVD. SUITE 530-90 1425 MARKET BLVD SUITE 53090 
#>  2 7642 GARLAND CIRCLE            7642 GARLAND CIR             
#>  3 575 PHARR RD.                  575 PHARR RD                 
#>  4 2875 HILTON CR.                2875 HILTON CR               
#>  5 11600HAZELBRAND RD.            11600HAZELBRAND RD           
#>  6 2605 CIRCLE 75 PARKWAY         2605 CIRCLE 75 PKWY          
#>  7 1500 BAY RD. #424              1500 BAY RD #424             
#>  8 530 PIEDMONT AVENUE SUITE 607  530 PIEDMONT AVENUE SUITE 607
#>  9 1100 MCLYNN AVE                1100 MCLYNN AVE              
#> 10 300 JIM MORAN BLVD.            300 JIM MORAN BLVD

galr_early %>% 
  select(address_full, address_norm) %>% 
  distinct() %>% 
  sample_n(10)
#> # A tibble: 10 × 2
#>    address_full                       address_norm                   
#>    <chr>                              <chr>                          
#>  1 Gsba 5120 Sugarloaf Pkwy.          GSBA 5120 SUGARLOAF PKWY       
#>  2 485 ELLESMERE WAY                  485 ELLESMERE WAY              
#>  3 191 Peachtree Street NE 16th Floor 191 PEACHTREE STREET NE 16TH FL
#>  4 1280 Star Dr.                      1280 STAR DR                   
#>  5 100 Cherokee Street Suite 312      100 CHEROKEE STREET SUITE 312  
#>  6 50 HURT PLAZA SUITE 1000           50 HURT PLAZA SUITE 1000       
#>  7 433 Greencove Lane                 433 GREENCOVE LN               
#>  8 175 CARNEGIE PL. SUITE 133         175 CARNEGIE PL SUITE 133      
#>  9 955 Manchester Place               955 MANCHESTER PL              
#> 10 482 Huntcliff Green                482 HUNTCLIFF GRN

galr <- galr %>% 
  select(-c(address_full, grp_address_full))

galr_early <- galr_early %>% 
  select(-address_full)
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
galr <- mutate(
  .data = galr,
  zip_norm = normal_zip(
    zip = zip,
    na_rep = TRUE
  ),
  grp_zip_norm = normal_zip(zip = grp_zip,
                            na_rep = TRUE)
)

galr_early <- mutate(
  .data = galr_early,
  zip_norm = normal_zip(
    zip = zip,
    na_rep = TRUE
  )
)
```

``` r
progress_table(
  galr$zip,
  galr$grp_zip,
  galr_early$zip,
  galr$zip_norm,
  galr$grp_zip_norm,
  galr_early$zip_norm,
  compare = valid_zip
)
#> # A tibble: 6 × 6
#>   stage               prop_in n_distinct   prop_na n_out n_diff
#>   <chr>                 <dbl>      <dbl>     <dbl> <dbl>  <dbl>
#> 1 galr$zip              0.997        833 0.0000616   785     18
#> 2 galr$grp_zip          0.982       1562 0.478      2224     95
#> 3 galr_early$zip        0.862        525 0          1139    166
#> 4 galr$zip_norm         1.00         831 0.0000616    49     16
#> 5 galr$grp_zip_norm     0.989       1534 0.478      1363     57
#> 6 galr_early$zip_norm   0.999        384 0            10      8
```

### State

The two-letter state abbreviations are almost valid and don’t need to be
normalized.

``` r
prop_in(galr$state, valid_state, na.rm = T)
#> [1] 0.9999425
prop_in(galr_early$state, valid_state, na.rm = T)
#> [1] 0.9969675
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
galr <- galr %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = usps_state,
      na = invalid_city,
      na_rep = TRUE
    ),
      grp_city_norm = normal_city(
      city = grp_city, 
      abbs = usps_city,
      states = usps_state,
      na = invalid_city,
      na_rep = TRUE
    ),
  )

galr_early <- galr_early %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = usps_state,
      na = invalid_city,
      na_rep = TRUE
    )
  )
many_city <- c(valid_city, extra_city)
prop_in(galr_early$city_norm,many_city)
#> [1] 0.9916303
```

#### Progress

| stage                                                             | prop_in | n_distinct | prop_na | n_out | n_diff |
|:------------------------------------------------------------------|--------:|-----------:|--------:|------:|-------:|
| str_to_upper(galr$city) | 0.997| 481| 0| 635| 55| |galr$city_norm |   0.997 |        478 |       0 |   618 |     49 |

## Conclude

Before exporting, we can remove the intermediary normalization columns
and rename all added variables with the `_clean` suffix.

``` r
galr <- galr %>% 
  rename_all(~str_replace(., "_norm", "_clean")
             )
galr_early <- galr_early %>% 
  rename_all(~str_replace(., "_norm", "_clean")
             )
```

``` r
glimpse(sample_n(galr, 20))
#> Rows: 20
#> Columns: 36
#> $ filer_id          <chr> "L20050101", "L20080329", "L20070025", "L20060034", "L20050642", "L2005…
#> $ last_name         <chr> "SLOAT", "ALEXANDER", "MYERS", "CHIVERS", "HAYDON", "WATSON", "BOLLER",…
#> $ suffix            <chr> NA, NA, "JR", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ first_name        <chr> "HELEN", "BRAD", "BEN", "PATRICIA", "CHANDLER", "JOHN", "THOMAS", "LOUI…
#> $ middle_name       <chr> "L.", "L.", "E", "M.", "CARTER", "K.", "M.", "S", "E.", "JAMES", NA, NA…
#> $ address1          <chr> "201 17TH STREET , SUITE 1700", "233 PEACHTREE STREET NE", "10875 PARSO…
#> $ address2          <chr> NA, "SUITE 1225", NA, NA, "#550", "SUITE 860", "BUILDING 5---2ND FLOOR"…
#> $ city              <chr> "ATLANTA", "ATLANTA", "JOHNS CREEK", "SMYRNA", "ATLANTA", "ATLANTA", "A…
#> $ state             <chr> "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA",…
#> $ zip               <chr> "30363", "30303", "30097", "30080", "30327", "30303", "30327", "30064",…
#> $ phone_clean       <chr> "phone_norm", "phone_norm", "phone_norm", "phone_norm", "phone_norm", "…
#> $ phone             <chr> "(404) 322 - 6170", "(404) 375 - 2849", "(404) 630 - 5440", "(678) 480 …
#> $ phone_ext         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ phone2            <chr> NA, NA, NA, "(770) 667-0020", NA, NA, NA, NA, "(404) 429 - 7113", "(404…
#> $ public_e_mail     <chr> NA, NA, "benmyers@ibew613.org", "pchivers@archatl.com", "chandler@haydo…
#> $ association       <chr> "TIAA", "THE WALT DISNEY COMPANY", "GEORGIA STATE BUILDING AND CONSTRUC…
#> $ payment_exceeds   <lgl> TRUE, TRUE, FALSE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRU…
#> $ date_registered   <date> 2011-07-22, 2011-09-06, 2013-01-10, 2006-07-26, 2020-02-19, 2016-12-19…
#> $ date_terminated   <date> 2018-12-31, NA, 2014-12-31, 2014-12-17, NA, 2018-12-31, 2012-12-31, 20…
#> $ lobbying_level    <chr> "LOCAL", "STATE", "STATE", "STATE", "SA", "VENDOR", "STATE", "STATE", "…
#> $ year              <int> 2018, 2016, 2009, 2008, 2019, 2018, 2009, 2011, 2014, 2016, 2015, 2020,…
#> $ dupe_flag         <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ na_flag           <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ grp_address1      <chr> "8500 ANDREW CARNEGIE BLVD.", "425 3RD STREET SW", "501 PULLIAM ST. S.W…
#> $ grp_address2      <chr> NA, NA, "SUITE 511", NA, NA, NA, "SUITE 220", "SUITE 490", NA, NA, NA, …
#> $ grp_phone         <chr> "7049884623", "202-222-4700", "4046305440", "(404) 885 - 7420", "615-29…
#> $ grp_city          <chr> "CHARLOTTE", "WASHINGTON", "ATLANTA", "ATLANTA", "NASHVILLE", NA, "ATLA…
#> $ grp_state         <chr> "NC", "DC", "GA", "GA", "TN", NA, "GA", "GA", "WI", "TN", NA, NA, "GA",…
#> $ grp_zip           <chr> "28262", "20024", "30312", "30308", "37215", NA, "30328", "30030", "530…
#> $ grp_phone_clean   <chr> "grp_phone", "grp_phone", "grp_phone", "grp_phone", "grp_phone", "grp_p…
#> $ address_clean     <chr> "201 17TH STREET SUITE 1700", "233 PEACHTREE STREET NE SUITE 1225", "10…
#> $ grp_address_clean <chr> "8500 ANDREW CARNEGIE BLVD", "425 3RD STREET SW", "501 PULLIAM ST SW SU…
#> $ zip_clean         <chr> "30363", "30303", "30097", "30080", "30327", "30303", "30327", "30064",…
#> $ grp_zip_clean     <chr> "28262", "20024", "30312", "30308", "37215", NA, "30328", "30030", "530…
#> $ city_clean        <chr> "ATLANTA", "ATLANTA", "JOHNS CREEK", "SMYRNA", "ATLANTA", "ATLANTA", "A…
#> $ grp_city_clean    <chr> "CHARLOTTE", "WASHINGTON", "ATLANTA", "ATLANTA", "NASHVILLE", NA, "ATLA…
glimpse(sample_n(galr_early, 20))
#> Rows: 20
#> Columns: 21
#> $ docket_year     <chr> "20031094", "20030672", "20020862", "20010344", "20020734", "20030534", "…
#> $ first_name      <chr> "MO", "JANE", "Mary", "Wes", "J.", "JIM", "Haydon", "Patroski", "Raymon",…
#> $ middle_name     <chr> NA, "M.", "Susan", "E.", "Scott", NA, NA, "J.", "E.", "DOUGLAS", "E.", NA…
#> $ last_name       <chr> "THRASH", "LANGLEY", "Manning", "Goodroe", "Tanner", "HAMMOCK", "Stanley,…
#> $ suffix          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ address         <chr> NA, "1175 PEACHTREE ST., N.E.", "1275 Peachtree St. Ne.", "11205 Alpharet…
#> $ address_1       <chr> "1544 OLD ALABAMA RD.", "SUITE 1660", "7th Floor", "Suite F1", "Suite 930…
#> $ city            <chr> "ROSWELL", "ATLANTA", "Atlanta", "Roswell", "Atlanta", "ATLANTA", "Newnan…
#> $ state           <chr> "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "GA", "…
#> $ zip             <chr> "30076", "30361", "30309", "30076", "30303", "30361", "30264", "30062", "…
#> $ phone           <chr> "7708040251", "4048920100", "4049626129", "7707516373", "4046594663", "40…
#> $ date_registered <date> 2003-01-06, 2002-12-11, 2002-01-22, 2001-01-03, 2002-01-11, 2002-12-23, …
#> $ association     <chr> "GA. DENTAL ASSOCIATION", "DOWLING, LANGLEY & ASSOCS.", "Mid-Georgia Coge…
#> $ level           <chr> "State", "Both", NA, NA, NA, "State", NA, NA, NA, "City/County", "City/Co…
#> $ year            <int> 2003, 2003, 2002, 2001, 2002, 2003, 2001, 2002, 2001, 2003, 2003, 2002, 2…
#> $ dupe_flag       <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ na_flag         <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ phone_clean     <chr> "Phone", "Phone", "Phone", "Phone", "Phone", "Phone", "Phone", "Phone", "…
#> $ address_clean   <chr> "1544 OLD ALABAMA RD", "1175 PEACHTREE ST NE SUITE 1660", "1275 PEACHTREE…
#> $ zip_clean       <chr> "30076", "30361", "30309", "30076", "30303", "30361", "30264", "30062", "…
#> $ city_clean      <chr> "ROSWELL", "ATLANTA", "ATLANTA", "ROSWELL", "ATLANTA", "ATLANTA", "NEWNAN…
```

``` r
nrow(galr)
#> [1] 243615
nrow(galr_early)
#> [1] 8244
```

1.  There are 251,859 records in the database.
2.  There are 841 duplicate records in the database.
3.  The range and distribution of `date` seem reasonable.
4.  There are 0 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("state","ga", "lobby", "data", "clean","reg"))
clean_path <- path(clean_dir, "ga_lobby_reg_clean_2006_2022.csv")
early_path <- path(clean_dir, "ga_lobby_reg_clean_2001_2003.csv")
write_csv(galr, clean_path, na = "")
write_csv(galr_early, early_path, na = "")
file_size(clean_path)
#> 70M
file_size(early_path)
#> 1.48M
```

## Upload

Using the `aws.s3` package, we can upload the file to the IRW server.

``` r
s3_path <- path("csv", basename(clean_path))
s3_path_early <- path("csv", basename(early_path))
put_object(
  file = clean_path,
  object = s3_path, 
  bucket = "publicaccountability",
  acl = "public-read",
  multipart = TRUE,
  show_progress = TRUE
)
put_object(
  file = early_path,
  object = s3_path_early, 
  bucket = "publicaccountability",
  acl = "public-read",
  multipart = TRUE,
  show_progress = TRUE
)
as_fs_bytes(object_size(s3_path, "publicaccountability"))
as_fs_bytes(object_size(s3_path_early, "publicaccountability"))
```

## Dictionary

The following table describes the variables in our final exported file:

| Column              | Type        | Definition                                               |
|:--------------------|:------------|:---------------------------------------------------------|
| `filer_id`          | `character` | ID of the filer (lobbyist)                               |
| `last_name`         | `character` | Lobbyist last name                                       |
| `suffix`            | `character` | Lobbyist name suffix                                     |
| `first_name`        | `character` | Lobbyist first name                                      |
| `middle_name`       | `character` | Lobbyist middle name                                     |
| `address1`          | `character` | Lobbyist street address line 1                           |
| `address2`          | `character` | Lobbyist street address line 2                           |
| `city`              | `character` | Lobbyist City                                            |
| `state`             | `character` | Lobbyis State                                            |
| `zip`               | `character` | Lobbyist ZIP code                                        |
| `phone_clean`       | `character` | Normalized Lobbyist phone                                |
| `phone`             | `character` | Lobbyist phone                                           |
| `phone_ext`         | `character` | Lobbyist phone extension                                 |
| `phone2`            | `character` | Secondary lobbyist phone                                 |
| `public_e_mail`     | `character` | Lobbyist email                                           |
| `association`       | `character` | Organization to which lobbyists were associated          |
| `payment_exceeds`   | `logical`   | Payment exceeds \$10,000                                 |
| `date_registered`   | `double`    | Date registered                                          |
| `date_terminated`   | `double`    | Date terminated                                          |
| `lobbying_level`    | `character` | Level of lobbying activity                               |
| `year`              | `integer`   | Year of data publication                                 |
| `dupe_flag`         | `logical`   | Flag for missing date, organization, or, filerID or name |
| `na_flag`           | `logical`   | Flag for completely duplicated record                    |
| `grp_address1`      | `character` | Lobbying group street address line 1                     |
| `grp_address2`      | `character` | Lobbying group street address line 2                     |
| `grp_phone`         | `character` | Lobbying group phone                                     |
| `grp_city`          | `character` | Lobbying group city                                      |
| `grp_state`         | `character` | Lobbying group state                                     |
| `grp_zip`           | `character` | Lobbying group zip                                       |
| `grp_phone_clean`   | `character` | Normalized lobbying group phone number                         |
| `address_clean`     | `character` | Normalized lobbying group street address                 |
| `grp_address_clean` | `character` | Normalized lobbyist street address                       |
| `zip_clean`         | `character` | Normalized 5-digit lobbyist ZIP code                     |
| `grp_zip_clean`     | `character` | Normalized 5-digit lobbying group ZIP code               |
| `city_clean`        | `character` | Normalized lobbyist city name                            |
| `grp_city_clean`    | `character` | Normalized lobbying group city name                      |

``` r
write_lines(
  x = c("# Georgia Lobbying Registration Data Dictionary\n", dict_md),
  path = here("state","ga", "lobby", "ga_contribs_dict.md"),
)
```
