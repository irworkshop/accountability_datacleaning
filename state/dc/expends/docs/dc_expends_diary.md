District Of Columbia Expenditures
================
Kiernan Nicholls & Aarushi Sahejpal
Mon May 29 10:13:00 2023

- <a href="#project" id="toc-project">Project</a>
- <a href="#objectives" id="toc-objectives">Objectives</a>
- <a href="#packages" id="toc-packages">Packages</a>
- <a href="#source" id="toc-source">Source</a>
- <a href="#data" id="toc-data">Data</a>
- <a href="#download" id="toc-download">Download</a>
- <a href="#read" id="toc-read">Read</a>
- <a href="#explore" id="toc-explore">Explore</a>
  - <a href="#missing" id="toc-missing">Missing</a>
  - <a href="#categorical" id="toc-categorical">Categorical</a>
  - <a href="#amounts" id="toc-amounts">Amounts</a>
  - <a href="#dates" id="toc-dates">Dates</a>
- <a href="#wrangle" id="toc-wrangle">Wrangle</a>
  - <a href="#state" id="toc-state">State</a>
  - <a href="#city" id="toc-city">City</a>
- <a href="#conclude" id="toc-conclude">Conclude</a>
- <a href="#export" id="toc-export">Export</a>
- <a href="#upload" id="toc-upload">Upload</a>

<!-- Place comments regarding knitting here -->

## Project

The Accountability Project is an effort to cut across data silos and
give journalists, policy professionals, activists, and the public at
large a simple way to search across huge volumes of public data about
people and organizations.

Our goal is to standardize public data on a few key fields by thinking
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

``` r
if (!require("pacman")) {
  install.packages("pacman")
}
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  gluedown, # printing markdown
  janitor, # clean data frames
  campfin, # custom irw tools
  aws.s3, # aws cloud storage
  refinr, # cluster & merge
  scales, # format strings
  knitr, # knit documents
  vroom, # fast reading
  rvest, # scrape html
  glue, # code strings
  here, # project paths
  httr, # http requests
  fs # local storage 
)
```

This diary was run using `campfin` version 1.0.10.9001.

``` r
packageVersion("campfin")
#> [1] '1.0.10.9001'
```

This document should be run as part of the `R_tap` project, which lives
as a sub-directory of the more general, language-agnostic
[`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning)
GitHub repository.

The `R_tap` project uses the [RStudio
projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects)
feature and should be run as such. The project also uses the dynamic
`here::here()` tool for file paths relative to *your* machine.

``` r
# where does this document knit?
setwd("/Volumes/TAP/accountability_datacleaning/state")
here::here()
#> [1] "/Volumes/TAP/accountability_datacleaning"
```

## Source

## Data

Data comes courtesy of the [DC Office of Campaign Finance
(OCF)](https://ocf.dc.gov/).

As the [OCF
website](https://ocf.dc.gov/service/view-contributions-expenditures)
explains:

> The Office of Campaign Finance (OCF) provides easy access to all
> contributions and expenditures reported from 2003, through the current
> reporting period. Because the system is updated on a daily basis, you
> may be able to retrieve data received by OCF after the latest
> reporting period. This data is as reported, but may not be complete.

The data is found on the dc.gov [OpenData
website](https://opendata.dc.gov/datasets/campaign-financial-expenditures).
The file abstract reads:

> The Office of Campaign Finance (OCF) is pleased to publicly share
> election campaign contribution data. The Campaign Finance Office is
> charged with administering and enforcing the District of Columbia laws
> pertaining to campaign finance operations, lobbying activities,
> conflict of interest matters, the ethical conduct of public officials,
> and constituent service and statehood fund programs. OCF provides easy
> access to all contributions and expenditures reported from 2003,
> through the current reporting period. Because the system is updated on
> a daily basis, you may be able to retrieve data received by OCF after
> the latest reporting period. This data is as reported, but may not be
> complete. Visit the <http://ocf.dc.gov> for more information.

## Download

``` r
raw_dir <- dir_create(here("dc", "expends", "data", "raw"))
```

## Read

``` r
raw_paths <- dir_ls(raw_dir)
md_bullet(md_code(path.abbrev(raw_paths)))
```

- `/Volumes/TAP/accountability_datacleaning/dc/expends/data/raw/Campaign_Financial_Expenditures (1).csv`

These files have a troublesome encoding. We can read and re-write them.

``` r
library(readr)

dce <- read_csv("/Volumes/TAP/accountability_datacleaning/dc/expends/data/raw/Campaign_Financial_Expenditures (1).csv")
```

``` r
dce <- dce %>% 
  clean_names("snake") 
```

``` r
dce <- dce %>% 
  rename(date = transactiondate)
```

## Explore

There are 114,088 rows of 15 columns. Each record represents a single
Expenditures…

``` r
glimpse(dce)
#> Rows: 114,088
#> Columns: 15
#> $ objectid          <dbl> 19010569, 19010570, 19010571, 19010572, 19010573, 19010574, 19010575, 19010576, 19010881, 19…
#> $ candidatename     <chr> "Sandra Allen", "Sandra Allen", "Sandra Allen", "Sandra Allen", "Sandra Allen", "Sandra Alle…
#> $ payee             <chr> "Adenike  Banjo Banjo", "Benjamin & Johnson", "Bob Bethea", "Frederick Hill", "Willie Mayer"…
#> $ address           <chr> "6115 Marlboro Pike, District Heights, MD 20747", "c/o 1428 R. St. NW.#2, Washington, DC 200…
#> $ purpose           <chr> "Consultant", "Equipment Purchases", "Consultant", "Travel", "Consultant", "Equipment Purcha…
#> $ amount            <dbl> 500, 400, 500, 400, 400, 275, 250, 400, 680, 49, 250, 50, 200, 236, 98, 135, 432, 2000, 1503…
#> $ date              <chr> "2004/08/27 04:00:00+00", "2004/08/27 04:00:00+00", "2004/08/27 04:00:00+00", "2004/08/27 04…
#> $ address_id        <dbl> NA, 240209, 811823, NA, 147179, NA, 67435, 79579, NA, NA, NA, 289588, NA, NA, 35208, NA, 336…
#> $ xcoord            <dbl> NA, 397094.2, 397228.7, NA, 399301.1, NA, 400790.8, 400467.3, NA, NA, NA, 400583.8, NA, NA, …
#> $ ycoord            <dbl> NA, 138277.7, 137931.8, NA, 128983.2, NA, 132575.6, 128841.0, NA, NA, NA, 140550.2, NA, NA, …
#> $ latitude          <dbl> NA, 38.91236, 38.90924, NA, 38.82863, NA, 38.86100, 38.82735, NA, NA, NA, 38.93283, NA, NA, …
#> $ longitude         <dbl> NA, -77.03350, -77.03195, NA, -77.00805, NA, -76.99089, -76.99462, NA, NA, NA, -76.99327, NA…
#> $ fulladdress       <chr> NA, "1428 R STREET NW", "1400 - 1499 BLOCK OF 14TH STREET NW", NA, "6 CHESAPEAKE STREET SW",…
#> $ gis_last_mod_dttm <chr> "2023/05/29 10:54:52+00", "2023/05/29 10:54:52+00", "2023/05/29 10:54:52+00", "2023/05/29 10…
#> $ ward              <chr> NA, "Ward 2", "Ward 2", NA, "Ward 8", NA, "Ward 8", "Ward 8", NA, NA, NA, "Ward 5", NA, NA, …
tail(dce)
#> # A tibble: 6 × 15
#>   objectid candidatename  payee     address purpose amount date  address_id xcoord ycoord latitude longitude fulladdress
#>      <dbl> <chr>          <chr>     <chr>   <chr>    <dbl> <chr>      <dbl>  <dbl>  <dbl>    <dbl>     <dbl> <chr>      
#> 1 19127377 Adrian Fenty   The Luci… c/o Sa… **Plaq…    150 2006…     223624 3.98e5 1.41e5     38.9     -77.0 1229 SHEPH…
#> 2 19127378 Muriel Bowser  DC Cameo… c/o Sh… **2 ti…     50 2013…      53132 4.02e5 1.42e5     38.9     -77.0 2000 UPSHU…
#> 3 19127379 Adrian Fenty   Giant Fo… c/o Sh… **Sr. …    125 2006…     223624 3.98e5 1.41e5     38.9     -77.0 1229 SHEPH…
#> 4 19127380 Lankward Smith U. S.Pos… c/o Te… <NA>       348 2016…     218759 3.98e5 1.37e5     38.9     -77.0 800 K STRE…
#> 5 19127381 Jim Graham     Bernstei… c/o Th… Rental      43 2003…     232041 3.97e5 1.39e5     38.9     -77.0 2505 13TH …
#> 6 19127382 Vincent Gray   Rrecreat… unk701… **dona…    250 2012…     295830 4.00e5 1.30e5     38.8     -77.0 701 MISSIS…
#> # ℹ 2 more variables: gis_last_mod_dttm <chr>, ward <chr>
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(dce, count_na)
#> # A tibble: 15 × 4
#>    col               class     n       p
#>    <chr>             <chr> <int>   <dbl>
#>  1 objectid          <dbl>     0 0      
#>  2 candidatename     <chr> 15863 0.139  
#>  3 payee             <chr>  1727 0.0151 
#>  4 address           <chr>  1730 0.0152 
#>  5 purpose           <chr> 33220 0.291  
#>  6 amount            <dbl>   518 0.00454
#>  7 date              <chr>     0 0      
#>  8 address_id        <dbl> 45433 0.398  
#>  9 xcoord            <dbl> 45433 0.398  
#> 10 ycoord            <dbl> 45433 0.398  
#> 11 latitude          <dbl> 45433 0.398  
#> 12 longitude         <dbl> 45433 0.398  
#> 13 fulladdress       <chr> 45433 0.398  
#> 14 gis_last_mod_dttm <chr>     0 0      
#> 15 ward              <chr> 45639 0.400
```

We can flag any record missing a key variable needed to identify a
transaction.

``` r
key_vars <- c("date", "candidatename", "amount", "payee")
dce <- flag_na(dce, all_of(key_vars))
sum(dce$na_flag)
#> [1] 15922
```

``` r
dce %>% 
  filter(na_flag) %>% 
  select(all_of(key_vars))
#> # A tibble: 15,922 × 4
#>    date                   candidatename amount payee                               
#>    <chr>                  <chr>          <dbl> <chr>                               
#>  1 2013/06/19 04:00:00+00 <NA>              25 Deluxe Checks                       
#>  2 2011/02/16 05:00:00+00 <NA>             500 Friends of Hans Riemer              
#>  3 2011/02/16 05:00:00+00 <NA>             250 Progressive Leaders for South County
#>  4 2010/03/23 04:00:00+00 <NA>             500 Re-Elect Tommy Wells                
#>  5 2010/03/23 04:00:00+00 <NA>             500 Michael A. Brown Community Fund     
#>  6 2010/03/31 04:00:00+00 <NA>             250 Catania 2010                        
#>  7 2013/07/01 04:00:00+00 <NA>             205 Carr Workplace                      
#>  8 2013/08/01 04:00:00+00 <NA>             205 Carr Workplace                      
#>  9 2015/07/06 04:00:00+00 <NA>              12 EagleBank                           
#> 10 2015/07/06 04:00:00+00 <NA>            1000 SP Associates III, LLC              
#> # ℹ 15,912 more rows
```

### Categorical

``` r
col_stats(dce, n_distinct)
#> # A tibble: 16 × 4
#>    col               class      n          p
#>    <chr>             <chr>  <int>      <dbl>
#>  1 objectid          <dbl> 114088 1         
#>  2 candidatename     <chr>    475 0.00416   
#>  3 payee             <chr>  33899 0.297     
#>  4 address           <chr>  41726 0.366     
#>  5 purpose           <chr>   8092 0.0709    
#>  6 amount            <dbl>   5423 0.0475    
#>  7 date              <chr>   6941 0.0608    
#>  8 address_id        <dbl>  12328 0.108     
#>  9 xcoord            <dbl>  12229 0.107     
#> 10 ycoord            <dbl>  12255 0.107     
#> 11 latitude          <dbl>  12317 0.108     
#> 12 longitude         <dbl>  12319 0.108     
#> 13 fulladdress       <chr>  12329 0.108     
#> 14 gis_last_mod_dttm <chr>      1 0.00000877
#> 15 ward              <chr>      9 0.0000789 
#> 16 na_flag           <lgl>      2 0.0000175
```

![](../plots/distinct-plots-1.png)<!-- -->

### Amounts

``` r
# fix floating point precision
dce$amount <- round(dce$amount, digits = 2)
```

``` r
summary(dce$amount)
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max.     NA's 
#> -96038.0     37.0    130.0    984.4    500.0 513240.0      518
mean(dce$amount <= 0)
#> [1] NA
```

These are the records with the minimum and maximum amounts.

``` r
glimpse(dce[c(which.max(dce$amount), which.min(dce$amount)), ])
#> Rows: 2
#> Columns: 16
#> $ objectid          <dbl> 19024451, 19112546
#> $ candidatename     <chr> "Linda  Cropp", "Vincent Gray"
#> $ payee             <chr> "Media Production LUC", "EXPENDITURES NOT NEGOTIATED"
#> $ address           <chr> "Georgian Bank, Powder Spring, GA 32134", "2000 14TH STREET, NW SUITE 433, WASHINGTON, DC 20…
#> $ purpose           <chr> "Advertising", "**PER AUDIT"
#> $ amount            <dbl> 513240, -96038
#> $ date              <chr> "2006/08/23 04:00:00+00", "2011/01/31 05:00:00+00"
#> $ address_id        <dbl> NA, 239976
#> $ xcoord            <dbl> NA, 397180.2
#> $ ycoord            <dbl> NA, 138856.1
#> $ latitude          <dbl> NA, 38.91757
#> $ longitude         <dbl> NA, -77.03251
#> $ fulladdress       <chr> NA, "2000 14TH STREET NW"
#> $ gis_last_mod_dttm <chr> "2023/05/29 10:54:52+00", "2023/05/29 10:54:52+00"
#> $ ward              <chr> NA, "Ward 1"
#> $ na_flag           <lgl> FALSE, FALSE
```

The distribution of amount values are typically log-normal.

![](../plots/hist-amount-1.png)<!-- -->

### Dates

We can add the calendar year from `date` with `lubridate::year()`

``` r
dce <- mutate(dce, payment_year = year(date))
dce <- dce %>%
  mutate(date = as.Date(date, format = "%Y/%m/%d %H:%M:%S+00")) %>%
  mutate(date = format(date, "%Y-%m-%d"))
```

``` r
min(dce$date)
#> [1] "2003-01-01"
sum(dce$payment_year < 2000)
#> [1] 0
max(dce$date)
#> [1] "2023-05-04"
sum(dce$date > today())
#> [1] 0
```

It’s common to see an increase in the number of expenditures in
elections years.

![](../plots/bar-year-1.png)<!-- -->

## Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are tailor made to facilitate this process.

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

## Conclude

``` r
glimpse(sample_n(dce, 1000))
#> Rows: 1,000
#> Columns: 17
#> $ objectid          <dbl> 19123656, 19030363, 19058308, 19065371, 19085390, 19044130, 19048727, 19091516, 19070629, 19…
#> $ candidatename     <chr> "Adrian Fenty", NA, "Lankward Smith", "David A Catania", "Dave Oberting", "Muriel Bowser", "…
#> $ payee             <chr> "Mark Smith", "The Sexton Group", "William O'Field", "Duane Haneckow", "Stripe", "Malik Will…
#> $ address           <chr> "6130 Banks Pl NE, Washington, DC 20018", "405 West Superior STE 703, Chicago, IL 60654", "2…
#> $ purpose           <chr> "**assistance w/  food for Stop the Violence event", NA, "Computer Expenses", "**Laptop and …
#> $ amount            <dbl> 79, 48, 36, 424, 79, 4250, 301, 2000, 35, 2, 8, 89, 100, 6, 250, 160, 1150, 200, 8, 485, 150…
#> $ date              <chr> "2010-06-09", "2020-11-19", "2012-10-19", "2014-02-17", "2016-01-29", "2017-10-06", "2008-07…
#> $ address_id        <dbl> 4419, NA, 297623, 242761, 813901, 50284, NA, NA, 239905, 252851, NA, 301099, NA, 302006, 288…
#> $ xcoord            <dbl> 407568.6, NA, 395773.5, 397948.9, 401791.8, 402305.5, NA, NA, 397940.9, 397624.1, NA, 397207…
#> $ ycoord            <dbl> 136037.4, NA, 139067.4, 136400.2, 140185.7, 140902.0, NA, NA, 137733.7, 142381.0, NA, 140193…
#> $ latitude          <dbl> 38.89215, NA, 38.91947, 38.89545, 38.92955, 38.93600, NA, NA, 38.90746, 38.94932, NA, 38.929…
#> $ longitude         <dbl> -76.91276, NA, -77.04874, -77.02364, -76.97934, -76.97341, NA, NA, -77.02374, -77.02741, NA,…
#> $ fulladdress       <chr> "6130 BANKS PLACE NE", NA, "2070 BELMONT ROAD NW", "401 9TH STREET NW", "3100 - 3199 BLOCK O…
#> $ gis_last_mod_dttm <chr> "2023/05/29 10:54:52+00", "2023/05/29 10:54:52+00", "2023/05/29 10:54:52+00", "2023/05/29 10…
#> $ ward              <chr> "Ward 7", NA, "Ward 1", "Ward 2", "Ward 5", "Ward 5", NA, NA, "Ward 2", "Ward 4", NA, "Ward …
#> $ na_flag           <lgl> FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FAL…
#> $ payment_year      <dbl> 2010, 2020, 2012, 2014, 2016, 2017, 2008, 2010, 2012, 2022, 2015, 2014, 2003, 2014, 2011, 20…
```

1.  There are 114,088 records in the database.
2.  There are 0 duplicate records in the database.
3.  The range and distribution of `amount` and `payment_date` seem
    reasonable.
4.  There are 15,922 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server. We will name the object using a date range of the records
included.

``` r
min_dt <- str_remove_all(min(dce$date), "-")
max_dt <- str_remove_all(max(dce$date), "-")
csv_ts <- paste(min_dt, max_dt, sep = "-")
```

``` r
clean_dir <- dir_create(here("dc", "expends", "data", "clean"))
clean_csv <- path(clean_dir, glue("dc_expends_{csv_ts}.csv"))
clean_rds <- path_ext_set(clean_csv, "rds")
basename(clean_csv)
#> [1] "dc_expends_20030101-20230504.csv"
```

``` r
write_csv(dce, clean_csv, na = "")
write_rds(dce, clean_rds, compress = "xz")
(clean_size <- file_size(clean_csv))
#> 20.9M
```

## Upload

We can use the `aws.s3::put_object()` to upload the text file to the IRW
server.

``` r
aws_key <- path("csv", basename(clean_csv))
if (!object_exists(aws_key, "publicaccountability")) {
  put_object(
    file = clean_csv,
    object = aws_key, 
    bucket = "publicaccountability",
    acl = "public-read",
    show_progress = TRUE,
    multipart = TRUE
  )
}
aws_head <- head_object(aws_key, "publicaccountability")
(aws_size <- as_fs_bytes(attr(aws_head, "content-length")))
unname(aws_size == clean_size)
```
