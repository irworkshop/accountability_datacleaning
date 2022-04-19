Alabama Expenditures
================
Kiernan Nicholls
Mon Jan 25 12:22:12 2021

-   [Project](#project)
-   [Objectives](#objectives)
-   [Packages](#packages)
-   [Data](#data)
-   [Download](#download)
-   [Read](#read)
-   [Explore](#explore)
    -   [Missing](#missing)
    -   [Duplicates](#duplicates)
    -   [Categorical](#categorical)
    -   [Amounts](#amounts)
    -   [Dates](#dates)
-   [Wrangle](#wrangle)
    -   [Address](#address)
    -   [ZIP](#zip)
    -   [State](#state)
    -   [City](#city)
-   [Conclude](#conclude)
-   [Export](#export)
-   [Upload](#upload)

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
here::i_am("al/expends/docs/al_expends_diary.Rmd")
```

## Data

Alabama expenditures data can be retrieved from the Alabama Electronic
Fair Campaign Practices Act (FCPA) [Reporting System
website](https://fcpa.alabamavotes.gov/PublicSite/Homepage.aspx). We can
find the files of interest on the [Data Download
page](https://fcpa.alabamavotes.gov/PublicSite/DataDownload.aspx), which
has a table of files available.

> This page provides comma separated value (CSV) downloadable files
> which contain annual data for Cash Contributions, In-Kind
> Contributions, Other Receipts, and Expenditures in a zipped file
> format. These files can be downloaded and imported into other
> applications (Microsoft Excel, Microsoft Access, etc.) for your use.

> This data is extracted from the Alabama Electronic FCPA Reporting
> System database as it existed as of 12/28/2020 1:35 AM

``` r
fcpa_home <- "https://fcpa.alabamavotes.gov/PublicSite"
al_table <- fcpa_home %>% 
  str_c("DataDownload.aspx", sep = "/") %>% 
  read_html(encoding = "UTF-8") %>% 
  html_node("#_ctl0_Content_dlstDownloadFiles")
```

| Data Type             | Year | Download                                                                                                                 |
|:----------------------|:-----|:-------------------------------------------------------------------------------------------------------------------------|
| Cash Contributions    | 2020 | [Download File](https://fcpa.alabamavotes.gov/PublicSite/Docs/BulkDataDownloads/2020_CashContributionsExtract.csv.zip)   |
| Expenditures          | 2020 | [Download File](https://fcpa.alabamavotes.gov/PublicSite/Docs/BulkDataDownloads/2020_ExpendituresExtract.csv.zip)        |
| In-Kind Contributions | 2020 | [Download File](https://fcpa.alabamavotes.gov/PublicSite/Docs/BulkDataDownloads/2020_InKindContributionsExtract.csv.zip) |
| Other Receipts        | 2020 | [Download File](https://fcpa.alabamavotes.gov/PublicSite/Docs/BulkDataDownloads/2020_OtherReceiptsExtract.csv.zip)       |
| Cash Contributions    | 2019 | [Download File](https://fcpa.alabamavotes.gov/PublicSite/Docs/BulkDataDownloads/2019_CashContributionsExtract.csv.zip)   |
| Expenditures          | 2019 | [Download File](https://fcpa.alabamavotes.gov/PublicSite/Docs/BulkDataDownloads/2019_ExpendituresExtract.csv.zip)        |
| In-Kind Contributions | 2019 | [Download File](https://fcpa.alabamavotes.gov/PublicSite/Docs/BulkDataDownloads/2019_InKindContributionsExtract.csv.zip) |
| Other Receipts        | 2019 | [Download File](https://fcpa.alabamavotes.gov/PublicSite/Docs/BulkDataDownloads/2019_OtherReceiptsExtract.csv.zip)       |
| Cash Contributions    | 2018 | [Download File](https://fcpa.alabamavotes.gov/PublicSite/Docs/BulkDataDownloads/2018_CashContributionsExtract.csv.zip)   |
| Expenditures          | 2018 | [Download File](https://fcpa.alabamavotes.gov/PublicSite/Docs/BulkDataDownloads/2018_ExpendituresExtract.csv.zip)        |

The Secretary of State also provides a file layout
[key](https://fcpa.alabamavotes.gov/PublicSite/Resources/AL_OtherReceiptsFileLayout.pdf).

| Field | Field Name           | Description                                    |
|:------|:---------------------|:-----------------------------------------------|
| A     | `ORG ID`             | This is the unique ID of the paying committee. |
| B     | `EXPENDITURE AMOUNT` | Dollar amount of the expenditure.              |
| C     | `EXPENDITURE DATE`   | Date of the expenditure.                       |
| D     | `LAST NAME`          | Last Name of Payee (entity paid).              |
| E     | `FIRST NAME`         | Payee First Name.                              |
| F     | `MI`                 | Payee Middle Name.                             |
| G     | `SUFFIX`             | Payee Name Suffix.                             |
| H     | `ADDRESS`            | Payee Address Number, Street, PO Box, etc.     |
| I     | `CITY`               | Payee City                                     |
| J     | `STATE`              | Payee State                                    |
| K     | `ZIP`                | Payee Zip Code                                 |
| L     | `EXPLANATION`        | Explanation provided if “Other” purpose.       |
| M     | `EXPENDITURE ID`     | Expenditure internal ID. This ID is unique.    |
| N     | `FILED DATE`         | Date the Expenditure was filed.                |
| O     | `PURPOSE`            | Purpose of the Expenditure.                    |
| P     | `EXPENDITURE TYPE`   | Indicates the Type of Expenditure.             |
| Q     | `COMMITTEE TYPE`     | Type of committee (PCC or PAC).                |
| R     | `COMMITTEE NAME`     | Name of the Committee if a PAC.                |
| S     | `CANDIDATE NAME`     | Name of the Candidate if a PCC.                |
| T     | `AMENDED`            | Y/N if this record has been amended.           |

## Download

We can construct a URL for each yearly file.

``` r
zip_dir <- dir_create(here("al", "expends", "data", "zip"))
raw_files <- glue("{2013:2020}_ExpendituresExtract.csv.zip")
raw_url <- str_c(fcpa_home, "/Docs/BulkDataDownloads/", raw_files)
raw_zip <- path(zip_dir, raw_files)
```

The URLs can be used to download the ZIP archives.

``` r
if (!all(file_exists(raw_zip))) {
  download.file(raw_url, raw_zip)
}
```

And the CSV files from those archives can be extracted.

``` r
csv_dir <- dir_create(here("al", "expends", "data", "csv"))
raw_csv <- map_chr(raw_zip, unzip, exdir = csv_dir)
```

``` r
for (f in raw_csv) {
  message(f)
  rx <- "(?<!(^|,|\"))\"(?!(,|$|\"))"
  x <- read_lines(f) 
  x <- str_replace_all(x, rx, "\'") 
  write_lines(x, f)
  rm(x)
  flush_memory(1)
  Sys.sleep(1)
}
```

## Read

``` r
ale <- map_df(
  .x = raw_csv,
  .f = read_delim,
  .id = "source_file",
  delim = ",",
  na = c("", " "),
  escape_backslash = FALSE,
  escape_double = FALSE,
  col_types = cols(
    .default = col_character(),
    ExpenditureDate = col_date_mdy(),
    ExpenditureAmount = col_double(),
    FiledDate = col_date_mdy()
  )
)
```

``` r
ale <- ale %>% 
  rename_with(.fn = str_remove, .cols = everything(), "^Expenditure") %>% 
  mutate(
    Amended = (Amended == "Y"),
    source_file = basename(raw_csv)[as.integer(source_file)]
  ) %>% 
  relocate(source_file, .after = last_col()) %>% 
  clean_names("snake")
```

## Explore

There are now 257,800 rows of 21 columns. Each column represents a
single expenditure made by a candidate or committee to a vendor.

``` r
glimpse(ale)
#> Rows: 257,800
#> Columns: 21
#> $ org_id         <chr> "25144", "25189", "25156", "25382", "25033", "25032", "24965", "24965", "24965", "25142", "250…
#> $ amount         <dbl> 50.00, 100.00, 235.00, 10.00, 1.00, 45.00, 1228.15, 750.00, 2500.00, 200.00, 630.00, 1035.00, …
#> $ date           <date> 2013-01-01, 2013-01-01, 2013-01-01, 2013-01-01, 2013-01-01, 2013-01-02, 2013-01-02, 2013-01-0…
#> $ last_name      <chr> "CULLMAN COUNTY SPORTS HALL OF FAME", "AL.WILDLIFE FEDERATION", NA, NA, NA, NA, "DELTA PRINTIN…
#> $ first_name     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ mi             <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ suffix         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ address1       <chr> "510 5TH ST SW", "3050 LANARK ROAD", NA, NA, NA, NA, "6001 MONTICELLO DRIVE", "P.O. BOX 2663",…
#> $ city           <chr> "CULLMAN", "WETUMPKA", NA, NA, NA, NA, "MONTGOMERY", "TUSCALOOSA", "MONTGOMERY", "MONTGOMERY",…
#> $ state          <chr> "AL", "AL", NA, NA, NA, NA, "AL", "AL", "AL", "AL", "AL", "AL", "GA", "AL", "AL", "AL", "AL", …
#> $ zip            <chr> "35055", "36054", NA, NA, NA, NA, "36117", "35403", "36104", "36104", "36702", "36702", "30353…
#> $ explanation    <chr> "AD IN PROGRAM", NA, "ADVERTISING AND TICKET", "BANK FEE", NA, NA, NA, NA, NA, NA, NA, NA, "IN…
#> $ id             <chr> "1050", "3499", "4728", "7957", "712", "763", "900", "901", "897", "1157", "123", "124", "125"…
#> $ filed_date     <date> 2013-07-15, 2013-10-02, 2013-10-02, 2013-11-01, 2013-07-01, 2013-07-01, 2013-07-02, 2013-07-0…
#> $ purpose        <chr> "Advertising", "Charitable Contribution", "Other", "Administrative", "Administrative", "Admini…
#> $ type           <chr> "Itemized", "Itemized", "Non-Itemized", "Non-Itemized", "Non-Itemized", "Non-Itemized", "Itemi…
#> $ committee_type <chr> "Principal Campaign Committee", "Principal Campaign Committee", "Principal Campaign Committee"…
#> $ committee_name <chr> NA, NA, NA, "GULF PAC", "STORMING THE STATE HOUSE POLITICAL ACTION COMMITTEE", NA, NA, NA, NA,…
#> $ candidate_name <chr> "MARVIN MCDANIEL BUTTRAM", "RANDALL (RANDY) M DAVIS", "JAMES EDWARD BUSKEY", NA, NA, "MICHAEL …
#> $ amended        <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ source_file    <chr> "2013_ExpendituresExtract.csv", "2013_ExpendituresExtract.csv", "2013_ExpendituresExtract.csv"…
tail(ale)
#> # A tibble: 6 x 21
#>   org_id amount date       last_name first_name mi    suffix address1 city  state zip   explanation id    filed_date
#>   <chr>   <dbl> <date>     <chr>     <chr>      <chr> <chr>  <chr>    <chr> <chr> <chr> <chr>       <chr> <date>    
#> 1 24905     5   2019-12-31 SOUTHERN… <NA>       <NA>  <NA>   101 WES… SYLA… AL    35150 BANK CHARGE 2486… 2020-01-02
#> 2 25243    93.1 2019-12-31 RENASANT… <NA>       <NA>  <NA>   8 COMME… MONT… AL    36104 <NA>        2521… 2020-01-24
#> 3 25249    90   2019-12-31 RENASANT… <NA>       <NA>  <NA>   8 COMME… MONT… AL    36104 <NA>        2521… 2020-01-24
#> 4 29204  3800   2020-12-31 BUCKMAST… <NA>       <NA>  <NA>   P.O. BO… MONT… AL    36124 <NA>        2742… 2020-12-31
#> 5 29204   320   2020-12-31 DEEP SOU… <NA>       <NA>  <NA>   438 1ST… ALAB… AL    35007 <NA>        2742… 2020-12-31
#> 6 29204   500   2020-12-31 THOMPSON… <NA>       <NA>  <NA>   1921 WA… ALAB… AL    35007 CAMPAIGN S… 2742… 2020-12-31
#> # … with 7 more variables: purpose <chr>, type <chr>, committee_type <chr>, committee_name <chr>, candidate_name <chr>,
#> #   amended <lgl>, source_file <chr>
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(ale, count_na)
#> # A tibble: 21 x 4
#>    col            class       n     p
#>    <chr>          <chr>   <int> <dbl>
#>  1 org_id         <chr>       0 0    
#>  2 amount         <dbl>       0 0    
#>  3 date           <date>      0 0    
#>  4 last_name      <chr>   36239 0.141
#>  5 first_name     <chr>  214884 0.834
#>  6 mi             <chr>  251798 0.977
#>  7 suffix         <chr>  257096 0.997
#>  8 address1       <chr>   36442 0.141
#>  9 city           <chr>   36443 0.141
#> 10 state          <chr>   36442 0.141
#> 11 zip            <chr>   36590 0.142
#> 12 explanation    <chr>  165678 0.643
#> 13 id             <chr>       0 0    
#> 14 filed_date     <date>      0 0    
#> 15 purpose        <chr>       0 0    
#> 16 type           <chr>       0 0    
#> 17 committee_type <chr>       0 0    
#> 18 committee_name <chr>  197517 0.766
#> 19 candidate_name <chr>   60283 0.234
#> 20 amended        <lgl>       0 0    
#> 21 source_file    <chr>       0 0
```

We can flag any record missing a key variable needed to identify a
transaction.

``` r
ale <- mutate(ale, committee = coalesce(committee_name, candidate_name))
key_vars <- c("date", "last_name", "amount", "committee")
geo_vars <- c("address1", "city", "state", "zip")
ale <- flag_na(ale, all_of(key_vars))
sum(ale$na_flag)
#> [1] 36239
```

14.1% of records are missing a key variable.

``` r
ale %>% 
  filter(na_flag) %>% 
  select(all_of(key_vars))
#> # A tibble: 36,239 x 4
#>    date       last_name amount committee                                              
#>    <date>     <chr>      <dbl> <chr>                                                  
#>  1 2013-01-01 <NA>       235   JAMES EDWARD BUSKEY                                    
#>  2 2013-01-01 <NA>        10   GULF PAC                                               
#>  3 2013-01-01 <NA>         1   STORMING THE STATE HOUSE POLITICAL ACTION COMMITTEE    
#>  4 2013-01-02 <NA>        45   MICHAEL G. HUBBARD                                     
#>  5 2013-01-02 <NA>        10.4 TALLADEGA COUNTY REPUBLICAN PARTY                      
#>  6 2013-01-03 <NA>        10   MIKE BALL                                              
#>  7 2013-01-03 <NA>        95.6 ALABAMA HOSPITAL ASSOCIATION POLITICAL ACTION COMMITTEE
#>  8 2013-01-03 <NA>        50   TALLADEGA COUNTY REPUBLICAN PARTY                      
#>  9 2013-01-05 <NA>        42   JOHNNY MACK MORROW                                     
#> 10 2013-01-08 <NA>        36.0 UNITED TRANSPORTATION UNION                            
#> # … with 36,229 more rows
```

All of these records missing variables belong to a non-itemized `type`.

``` r
ale %>% 
  mutate(non_item = str_detect(type, "Non-Itemized")) %>% 
  group_by(na_flag) %>% 
  summarise(non_item = mean(non_item))
#> # A tibble: 2 x 2
#>   na_flag non_item
#>   <lgl>      <dbl>
#> 1 FALSE    0.00158
#> 2 TRUE     0.999
```

We can remove the flag from such records, they should be missing this
data.

``` r
ale$na_flag[str_which(ale$type, "Non-Itemized")] <- FALSE
sum(ale$na_flag)
#> [1] 30
```

This leaves us with very few records.

``` r
ale %>% 
  filter(na_flag) %>% 
  select(all_of(key_vars), type)
#> # A tibble: 30 x 5
#>    date       last_name   amount committee                                                                type    
#>    <date>     <chr>        <dbl> <chr>                                                                    <chr>   
#>  1 2013-03-19 <NA>        100    TALLADEGA COUNTY REPUBLICAN PARTY                                        Itemized
#>  2 2013-11-08 <NA>         93.7  SUZELLE MARIE JOSEY                                                      Itemized
#>  3 2013-11-12 <NA>         24.4  SUZELLE MARIE JOSEY                                                      Itemized
#>  4 2015-02-09 <NA>       5000    ALABAMA AMERICAN PHYSICAL THERAPY ASSOCIATION POLITICAL ACTION COMMITTEE Itemized
#>  5 2016-06-01 <NA>        100    MERCERIA LAVONNE LUDGOOD                                                 Itemized
#>  6 2014-07-15 <NA>        180    LAWRENCE CONAWAY                                                         Itemized
#>  7 2016-08-22 <NA>       1174.   MICHAEL MILLICAN                                                         Itemized
#>  8 2017-09-08 <NA>          7.73 JOSEPH BARLOW                                                            Itemized
#>  9 2018-02-28 <NA>       1500    ALABAMA PHARMACY ASSOCIATION POLITICAL ACTION COMMITTEE                  Itemized
#> 10 2018-02-28 <NA>      -1500    ALABAMA PHARMACY ASSOCIATION POLITICAL ACTION COMMITTEE                  Itemized
#> # … with 20 more rows
```

### Duplicates

We can also flag any record completely duplicated across every column.

``` r
ale <- flag_dupes(ale, -id)
sum(ale$dupe_flag)
#> [1] 3111
```

1.2% of records are duplicates.

``` r
ale %>% 
  filter(dupe_flag) %>% 
  select(id, all_of(key_vars))
#> # A tibble: 3,111 x 5
#>    id    date       last_name amount committee                      
#>    <chr> <date>     <chr>      <dbl> <chr>                          
#>  1 2908  2013-01-28 BARTON      1000 ENPAC                          
#>  2 2916  2013-01-28 BARTON      1000 ENPAC                          
#>  3 11601 2013-02-08 <NA>          17 CULLMAN COUNTY REPUBLICAN WOMEN
#>  4 11602 2013-02-08 <NA>          17 CULLMAN COUNTY REPUBLICAN WOMEN
#>  5 11603 2013-02-08 <NA>          17 CULLMAN COUNTY REPUBLICAN WOMEN
#>  6 11604 2013-02-08 <NA>          17 CULLMAN COUNTY REPUBLICAN WOMEN
#>  7 11605 2013-02-08 <NA>          17 CULLMAN COUNTY REPUBLICAN WOMEN
#>  8 11590 2013-02-11 <NA>          17 CULLMAN COUNTY REPUBLICAN WOMEN
#>  9 11591 2013-02-11 <NA>          17 CULLMAN COUNTY REPUBLICAN WOMEN
#> 10 11592 2013-02-11 <NA>          17 CULLMAN COUNTY REPUBLICAN WOMEN
#> # … with 3,101 more rows
```

Similar to the missing values, much of these are non-itemized.

``` r
ale %>% 
  mutate(non_item = str_detect(type, "Non-Itemized")) %>% 
  group_by(dupe_flag) %>% 
  summarise(non_item = mean(non_item))
#> # A tibble: 2 x 2
#>   dupe_flag non_item
#>   <lgl>        <dbl>
#> 1 FALSE        0.136
#> 2 TRUE         0.581
```

``` r
ale$dupe_flag[str_which(ale$type, "Non-Itemized")] <- FALSE
sum(ale$dupe_flag)
#> [1] 1303
```

This removes most, but not all, duplicate records.

``` r
ale %>% 
  filter(dupe_flag) %>% 
  select(id, all_of(key_vars), type)
#> # A tibble: 1,303 x 6
#>    id    date       last_name        amount committee             type    
#>    <chr> <date>     <chr>             <dbl> <chr>                 <chr>   
#>  1 2908  2013-01-28 BARTON            1000  ENPAC                 Itemized
#>  2 2916  2013-01-28 BARTON            1000  ENPAC                 Itemized
#>  3 3366  2013-02-27 FASTSPRING         180. BRYAN MCDANIEL TAYLOR Itemized
#>  4 3367  2013-02-27 CONSTANT CONTACT    35  BRYAN MCDANIEL TAYLOR Itemized
#>  5 3373  2013-02-27 CONSTANT CONTACT    35  BRYAN MCDANIEL TAYLOR Itemized
#>  6 3376  2013-02-27 FASTSPRING         180. BRYAN MCDANIEL TAYLOR Itemized
#>  7 220   2013-05-08 SAHR GROUP        2000  ALABAMA 2014 PAC      Itemized
#>  8 221   2013-05-08 SAHR GROUP        2000  ALABAMA 2014 PAC      Itemized
#>  9 222   2013-05-08 SAHR GROUP        2000  ALABAMA 2014 PAC      Itemized
#> 10 4308  2013-08-01 WHALEY             200  RAY BRYAN             Itemized
#> # … with 1,293 more rows
```

### Categorical

``` r
col_stats(ale, n_distinct)
#> # A tibble: 24 x 4
#>    col            class       n          p
#>    <chr>          <chr>   <int>      <dbl>
#>  1 org_id         <chr>    3138 0.0122    
#>  2 amount         <dbl>   47164 0.183     
#>  3 date           <date>   2930 0.0114    
#>  4 last_name      <chr>   43745 0.170     
#>  5 first_name     <chr>    3829 0.0149    
#>  6 mi             <chr>      32 0.000124  
#>  7 suffix         <chr>       9 0.0000349 
#>  8 address1       <chr>   57511 0.223     
#>  9 city           <chr>    3384 0.0131    
#> 10 state          <chr>      71 0.000275  
#> 11 zip            <chr>    4766 0.0185    
#> 12 explanation    <chr>   39055 0.151     
#> 13 id             <chr>  257793 1.00      
#> 14 filed_date     <date>   1824 0.00708   
#> 15 purpose        <chr>      16 0.0000621 
#> 16 type           <chr>       4 0.0000155 
#> 17 committee_type <chr>       2 0.00000776
#> 18 committee_name <chr>     528 0.00205   
#> 19 candidate_name <chr>    2522 0.00978   
#> 20 amended        <lgl>       2 0.00000776
#> 21 source_file    <chr>       8 0.0000310 
#> 22 committee      <chr>    3048 0.0118    
#> 23 na_flag        <lgl>       2 0.00000776
#> 24 dupe_flag      <lgl>       2 0.00000776
```

![](../plots/distinct_plots-1.png)<!-- -->![](../plots/distinct_plots-2.png)<!-- -->![](../plots/distinct_plots-3.png)<!-- -->

### Amounts

``` r
summary(ale$amount)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#> -431800      50     164    1208     639 1000000
mean(ale$amount <= 0)
#> [1] 0.02236618
```

These are the records with the minimum and maximum amounts.

``` r
glimpse(ale[c(which.max(ale$amount), which.min(ale$amount)), ])
#> Rows: 2
#> Columns: 24
#> $ org_id         <chr> "25003", "26544"
#> $ amount         <dbl> 1000000, -431800
#> $ date           <date> 2014-03-03, 2018-05-21
#> $ last_name      <chr> "ALABAMA EDUCATION ASSOCIATION", "TARGET ENTERPRISES, LLC"
#> $ first_name     <chr> NA, NA
#> $ mi             <chr> NA, NA
#> $ suffix         <chr> NA, NA
#> $ address1       <chr> "P.O. BOX 4177", "15260 VENTURA BLVD., SUITE 1240"
#> $ city           <chr> "MONTGOMERY", "SHERMAN OAKS"
#> $ state          <chr> "AL", "CA"
#> $ zip            <chr> "36103", "91403"
#> $ explanation    <chr> "LOAN", "Offset due to deletion of filed item"
#> $ id             <chr> "21321", "203057"
#> $ filed_date     <date> 2014-04-02, 2018-09-01
#> $ purpose        <chr> "Other", "Advertising"
#> $ type           <chr> "Itemized", "Itemized"
#> $ committee_type <chr> "Political Action Committee", "Principal Campaign Committee"
#> $ committee_name <chr> "ALABAMA VOICE OF TEACHERS FOR EDUCATION", NA
#> $ candidate_name <chr> NA, "KAY E. IVEY"
#> $ amended        <lgl> FALSE, FALSE
#> $ source_file    <chr> "2014_ExpendituresExtract.csv", "2018_ExpendituresExtract.csv"
#> $ committee      <chr> "ALABAMA VOICE OF TEACHERS FOR EDUCATION", "KAY E. IVEY"
#> $ na_flag        <lgl> FALSE, FALSE
#> $ dupe_flag      <lgl> FALSE, FALSE
```

![](../plots/hist_amount-1.png)<!-- -->

### Dates

We can add the calendar year from `date` with `lubridate::year()`

``` r
ale <- mutate(ale, year = year(date))
```

``` r
min(ale$date)
#> [1] "2010-02-09"
sum(ale$year < 2000)
#> [1] 0
max(ale$date)
#> [1] "2020-12-31"
sum(ale$date > today())
#> [1] 0
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
addr_norm <- ale %>% 
  distinct(address1) %>% 
  mutate(
    address_norm = normal_address(
      address = address1,
      abbs = usps_street,
      na_rep = TRUE
    )
  )
```

``` r
addr_norm
#> # A tibble: 57,511 x 2
#>    address1                       address_norm           
#>    <chr>                          <chr>                  
#>  1 510 5TH ST SW                  510 5TH ST SW          
#>  2 3050 LANARK ROAD               3050 LANARK RD         
#>  3 <NA>                           <NA>                   
#>  4 6001 MONTICELLO DRIVE          6001 MONTICELLO DR     
#>  5 P.O. BOX 2663                  PO BOX 2663            
#>  6 60 COMMERCE STREET, SUITE 1400 60 COMMERCE ST STE 1400
#>  7 201 TALLAPOOSA STREET          201 TALLAPOOSA ST      
#>  8 PO BOX 2080                    PO BOX 2080            
#>  9 PO BOX 536126                  PO BOX 536126          
#> 10 101 TALLAPOOSA STREET          101 TALLAPOOSA ST      
#> # … with 57,501 more rows
```

``` r
ale <- left_join(ale, addr_norm, by = "address1")
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
ale <- ale %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  ale$zip,
  ale$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 zip        0.977       4766   0.142  5093   1149
#> 2 zip_norm   0.995       4080   0.143  1135    413
```

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

``` r
ale <- ale %>% 
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
ale %>% 
  filter(state != state_norm) %>% 
  count(state, state_norm, sort = TRUE)
#> # A tibble: 0 x 3
#> # … with 3 variables: state <chr>, state_norm <chr>, n <int>
```

``` r
progress_table(
  ale$state,
  ale$state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage      prop_in n_distinct prop_na n_out n_diff
#>   <chr>        <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 state         1.00         71   0.141    88     17
#> 2 state_norm    1            54   0.142     0      1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
norm_city <- ale %>% 
  distinct(city, state_norm, zip_norm) %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("AL", "DC", "ALABAMA"),
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
norm_city <- norm_city %>% 
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

``` r
ale <- left_join(
  x = ale,
  y = norm_city,
  by = c(
    "city" = "city_raw", 
    "state_norm", 
    "zip_norm"
  )
)
```

#### Refine

The [OpenRefine](https://openrefine.org/) algorithms can be used to
group similar strings and replace the less common versions with their
most common counterpart. This can greatly reduce inconsistency, but with
low confidence; we will only keep any refined strings that have a valid
city/state/zip combination.

``` r
good_refine <- ale %>% 
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

    #> # A tibble: 47 x 5
    #>    state_norm zip_norm city_swap      city_refine       n
    #>    <chr>      <chr>    <chr>          <chr>         <int>
    #>  1 AL         36104    MONTOMGERY     MONTGOMERY       63
    #>  2 CA         94107    SAN FRANSICO   SAN FRANCISCO    20
    #>  3 IL         60197    CARROLL STREAM CAROL STREAM     17
    #>  4 OH         45249    CINNCINATI     CINCINNATI       13
    #>  5 AL         35121    OENOTA         ONEONTA           8
    #>  6 AL         35234    BMINGHAMIR     BIRMINGHAM        5
    #>  7 OH         45274    CINCINATTI     CINCINNATI        3
    #>  8 OH         45274    CINNCINATA     CINCINNATI        3
    #>  9 AL         35208    BIMINGHAMR     BIRMINGHAM        2
    #> 10 AL         35565    HAYLEVILLE     HALEYVILLE        2
    #> # … with 37 more rows

Then we can join the refined values back to the database.

``` r
ale <- ale %>% 
  left_join(good_refine) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

Our goal for normalization was to increase the proportion of city values
known to be valid and reduce the total distinct values by correcting
misspellings.

| stage        | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
|:-------------|---------:|------------:|---------:|-------:|--------:|
| city)        |    0.972 |        3384 |    0.141 |   6180 |    1531 |
| city\_norm   |    0.978 |        3108 |    0.142 |   4915 |    1232 |
| city\_swap   |    0.992 |        2291 |    0.142 |   1693 |     410 |
| city\_refine |    0.993 |        2250 |    0.142 |   1513 |     369 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/bar_progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar_distinct-1.png)<!-- -->

## Conclude

Before exporting, we can remove the intermediary normalization columns
and rename all added variables with the `_clean` suffix.

``` r
ale <- ale %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  rename_all(~str_remove(., "_raw")) %>% 
  relocate(state_clean, zip_clean, .after = city_clean)
```

``` r
glimpse(sample_n(ale, 50))
#> Rows: 50
#> Columns: 29
#> $ org_id         <chr> "26586", "25328", "27977", "25737", "25433", "26605", "26682", "26016", "25603", "26408", "257…
#> $ amount         <dbl> -550.00, 300.00, 363.31, 220.00, 69.63, 60.00, 500.00, 82.50, 213.86, 12.00, 49.35, 150.00, 2.…
#> $ date           <date> 2017-08-31, 2014-03-13, 2018-06-27, 2014-10-02, 2014-11-24, 2018-05-19, 2018-05-30, 2016-02-1…
#> $ last_name      <chr> "MAGIC CITY CLASSIC PARADE", "TALISI HISTORICAL PRESERVATION SOCIETY", "BOOSTERS INCORPORATED"…
#> $ first_name     <chr> NA, NA, NA, NA, NA, "ANDRES", "JAMES", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ mi             <chr> NA, NA, NA, NA, NA, NA, "E", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ suffix         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ address1       <chr> "100 GRANDVIEW PLACE, SUITE 110", "650 GILMER AVENUE", "P.O. BOX 70156", "2350 AVALON AVE.", "…
#> $ city           <chr> "BIRMINGHAM", "TALLASSEE", "MONTGOMERY", "MUSCLE SHOALS", "CITY OF INDUSTRY", "MADISON", "BESS…
#> $ state          <chr> "AL", "AL", "AL", "AL", "CA", "AL", "AL", "AL", "AL", "CA", NA, "AL", "AL", "MA", "AL", NA, NA…
#> $ zip            <chr> "35243", "36078", "35107", "35661", "91716-0599", "35756", "35022", "36104", "36608", "94043",…
#> $ explanation    <chr> "Offset due to deletion of filed item", NA, "ROLL TAPE STICKERS", "POSTAGE", "ADVERTISING- LOW…
#> $ id             <chr> "126449", "21291", "187772", "57488", "67705", "180544", "183425", "91617", "62158", "257663",…
#> $ filed_date     <date> 2017-12-04, 2014-04-02, 2018-07-02, 2014-10-10, 2015-01-26, 2018-05-29, 2018-06-01, 2016-02-1…
#> $ purpose        <chr> "Advertising", "Charitable Contribution", "Other", "Advertising", "Other", "Consultants/Pollin…
#> $ type           <chr> "Itemized", "Itemized", "Itemized", "Itemized", "Itemized", "Itemized", "Itemized", "Itemized"…
#> $ committee_type <chr> "Principal Campaign Committee", "Principal Campaign Committee", "Principal Campaign Committee"…
#> $ committee_name <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "PROGRESSPAC", NA, NA, NA, NA, NA,…
#> $ candidate_name <chr> "MARSHELL RENA JACKSON HATCHER", "MIKE HOLMES", "STEVEN BURTON AMMONS", "RICHARD KEITH COATES"…
#> $ amended        <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ source_file    <chr> "2017_ExpendituresExtract.csv", "2014_ExpendituresExtract.csv", "2018_ExpendituresExtract.csv"…
#> $ committee      <chr> "MARSHELL RENA JACKSON HATCHER", "MIKE HOLMES", "STEVEN BURTON AMMONS", "RICHARD KEITH COATES"…
#> $ na_flag        <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ dupe_flag      <lgl> FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ year           <dbl> 2017, 2014, 2018, 2014, 2014, 2018, 2018, 2016, 2014, 2019, 2014, 2018, 2015, 2018, 2015, 2015…
#> $ address_clean  <chr> "100 GRANDVIEW PLACE STE 110", "650 GILMER AVE", "PO BOX 70156", "2350 AVALON AVE", "PO BOX 60…
#> $ city_clean     <chr> "BIRMINGHAM", "TALLASSEE", "MONTGOMERY", "MUSCLE SHOALS", "CITY OF INDUSTRY", "MADISON", "BESS…
#> $ state_clean    <chr> "AL", "AL", "AL", "AL", "CA", "AL", "AL", "AL", "AL", "CA", NA, "AL", "AL", "MA", "AL", NA, NA…
#> $ zip_clean      <chr> "35243", "36078", "35107", "35661", "91716", "35756", "35022", "36104", "36608", "94043", NA, …
```

1.  There are 257,800 records in the database.
2.  There are 1,303 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 30 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("al", "expends", "data", "clean"))
clean_path <- path(clean_dir, "al_expends_clean.csv")
write_csv(ale, clean_path, na = "")
(clean_size <- file_size(clean_path))
#> 68.5M
file_encoding(clean_path) %>% 
  mutate(across(path, path.abbrev))
#> # A tibble: 1 x 3
#>   path                                         mime            charset 
#>   <fs::path>                                   <chr>           <chr>   
#> 1 ~/al/expends/data/clean/al_expends_clean.csv application/csv us-ascii
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
unname(aws_size == clean_size)
```
