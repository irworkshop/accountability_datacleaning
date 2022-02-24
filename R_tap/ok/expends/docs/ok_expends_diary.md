Oklahoma Expenditures
================
Kiernan Nicholls
Thu Feb 24 11:52:34 2022

-   [Project](#project)
-   [Objectives](#objectives)
-   [Packages](#packages)
-   [Source](#source)
-   [Download](#download)
-   [Fix](#fix)
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
-   [Dictionary](#dictionary)

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

This diary was run using `campfin` version 1.0.8.9201.

``` r
packageVersion("campfin")
#> [1] '1.0.8.9201'
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
here::i_am("ok/expends/docs/ok_expends_diary.Rmd")
```

## Source

The [Oklahoma Ethics
Commission](https://guardian.ok.gov/PublicSite/Homepage.aspx#) provides
a [data download
page](https://guardian.ok.gov/PublicSite/DataDownload.aspx) where users
can download campaign finance records by year.

> ### Data Download
>
> This page provides comma separated value (CSV) downloads of
> contribution, loan, and expenditure data for each reporting year in a
> zipped file format. These files can be downloaded and imported into
> other applications (Microsoft Excel, Microsoft Access, etc.)
>
> This data is extracted from the state of Oklahoma database as it
> existed as of 9/9/2021 12:08 AM

> ### Downloading Contribution and Expenditure Data
>
> You can access the Campaign Finance Data Download page to download
> contribution and expenditure data for import into other applications
> such as Microsoft Excel or Access. A weekly batch process is run that
> captures the year-to-date information for the current year. The data
> is available for each calendar year. The file is downloaded in CSV
> format.

The OEC also provides a [PDF file layout
key](https://guardian.ok.gov/PublicSite/Resources/PublicDocuments/OKReceiptsAndTransfersInFileLayout.pdf).

|     | Field Name     | Description                                          |
|:----|:---------------|:-----------------------------------------------------|
| A   | RECEIPT ID     | This is the Receipt internal ID. This ID is unique.  |
| B   | ORG ID         | Unique ID of the receiving candidate or committee.   |
| C   | RECEIPT TYPE   | This is the Receipt Type.                            |
| D   | RECEIPT DATE   | Receipt Date                                         |
| E   | RECEIPT AMOUNT | Receipt Amount                                       |
| F   | DESCRIPTION    | This is the description provided for the receipt.    |
| G   | SOURCE TYPE    | Type of entity that is the source of the Receipt.    |
| H   | FIRST NAME     | Source First Name                                    |
| I   | MIDDLE NAME    | Source Middle Initial or Name if provided.           |
| J   | LAST NAME      | Source Last Name                                     |
| K   | SUFFIX         | Source Name Suffix                                   |
| L   | SPOUSE NAME    | Source Spouse Name                                   |
| M   | ADDRESS 1      | Source , PO Box, or other directional information    |
| N   | ADDRESS 2      | Source Suite/Apartment number                        |
| O   | CITY           | Source City                                          |
| P   | STATE          | Source State                                         |
| Q   | ZIP            | Source Zip Code                                      |
| R   | FILED DATE     | Receipt Filed Date                                   |
| S   | COMMITTEE TYPE | Indicates Type of receiving committee                |
| T   | COMMITTEE NAME | This is the name of the receiving committee.         |
| U   | CANDIDATE NAME | This is the name of the receiving candidate          |
| V   | AMENDED        | Y/N indicator to show if an amendment was filed…     |
| W   | EMPLOYER       | Source’s employer…                                   |
| X   | OCCUPATION     | The Source’s occupation… used for Individual donors. |

## Download

The annual ZIP archives provided by OEC have unique URLs and can be
downloaded.

``` r
ok_url <- "https://guardian.ok.gov/PublicSite/Docs/BulkDataDownloads/"
raw_url <- str_c(ok_url, glue("{2014:2022}_ExpenditureExtract.csv.zip"))
raw_dir <- dir_create(here("ok", "contribs", "data", "raw"))
raw_zip <- path(raw_dir, basename(raw_url))
```

    #> 1. `https://guardian.ok.gov/PublicSite/Docs/BulkDataDownloads/2014_ExpenditureExtract.csv.zip`
    #> 2. `https://guardian.ok.gov/PublicSite/Docs/BulkDataDownloads/2015_ExpenditureExtract.csv.zip`
    #> 3. `https://guardian.ok.gov/PublicSite/Docs/BulkDataDownloads/2016_ExpenditureExtract.csv.zip`
    #> 4. `https://guardian.ok.gov/PublicSite/Docs/BulkDataDownloads/2017_ExpenditureExtract.csv.zip`
    #> 5. `https://guardian.ok.gov/PublicSite/Docs/BulkDataDownloads/2018_ExpenditureExtract.csv.zip`
    #> 6. `https://guardian.ok.gov/PublicSite/Docs/BulkDataDownloads/2019_ExpenditureExtract.csv.zip`
    #> 7. `https://guardian.ok.gov/PublicSite/Docs/BulkDataDownloads/2020_ExpenditureExtract.csv.zip`
    #> 8. `https://guardian.ok.gov/PublicSite/Docs/BulkDataDownloads/2021_ExpenditureExtract.csv.zip`
    #> 9. `https://guardian.ok.gov/PublicSite/Docs/BulkDataDownloads/2022_ExpenditureExtract.csv.zip`

``` r
if (!all(file_exists(raw_zip))) {
  download.file(raw_url, raw_zip)
}
```

    #> # A tibble: 9 × 3
    #>   path                                   size modification_time  
    #>   <chr>                           <fs::bytes> <dttm>             
    #> 1 2014_ExpenditureExtract.csv.zip       2.43K 2022-02-24 11:01:22
    #> 2 2015_ExpenditureExtract.csv.zip     313.04K 2022-02-24 11:01:22
    #> 3 2016_ExpenditureExtract.csv.zip       1.35M 2022-02-24 11:01:22
    #> 4 2017_ExpenditureExtract.csv.zip     845.14K 2022-02-24 11:01:22
    #> 5 2018_ExpenditureExtract.csv.zip       2.19M 2022-02-24 11:01:22
    #> 6 2019_ExpenditureExtract.csv.zip     658.86K 2022-02-24 11:01:22
    #> 7 2020_ExpenditureExtract.csv.zip       1.03M 2022-02-24 11:01:22
    #> 8 2021_ExpenditureExtract.csv.zip      596.4K 2022-02-24 11:01:22
    #> 9 2022_ExpenditureExtract.csv.zip       2.16K 2022-02-24 11:01:22

``` r
raw_csv <- map_chr(raw_zip, unzip, exdir = raw_dir)
```

## Fix

The double-quotes (`"`) in this file are not properly escaped. We can
read the lines of each text file and replace double-quotes in the middle
of “columns” with *two* double-quotes, which can be properly ignored
when reading the data.

``` r
fix_csv <- path_temp(basename(raw_csv))
for (i in seq_along(raw_csv)) {
  message(basename(raw_csv[i]))
  read_lines(raw_csv[i]) %>% 
    # double quote in middle of string
    str_replace_all("(?<!^|,)\"(?!,|$)", r"("")") %>% 
    write_lines(fix_csv[i])
  flush_memory()
}
```

## Read

``` r
oke <- read_delim(
  file = fix_csv,
  delim = ",",
  escape_backslash = FALSE,
  escape_double = TRUE,
  locale = locale(date_format = "%m/%d/%Y"),
  col_types = cols(
    .default = col_character(),
    `Expenditure Date` = col_date(),
    `Expenditure Amount` = col_double(),
    `Filed Date` = col_date()
  )
)
```

``` r
oke <- clean_names(oke, case = "snake")
```

## Explore

There are 182,980 rows of 23 columns. Each record represents a single
expenditure from a campaign to a vendor.

``` r
glimpse(oke)
#> Rows: 182,980
#> Columns: 23
#> $ expenditure_id     <chr> "33469", "33475", "76870", "45265", "44568", "47680", "64128", "71982", "76869", "76868", "…
#> $ org_id             <chr> "8462", "8462", "8033", "8043", "7513", "7513", "7513", "7513", "8033", "8033", "8214", "82…
#> $ expenditure_type   <chr> "Contribution to Candidate Committee", "Operating Expense", "Ordinary and Necessary Campaig…
#> $ expenditure_date   <date> 2014-01-27, 2014-02-01, 2014-03-23, 2014-03-31, 2014-04-14, 2014-04-14, 2014-04-14, 2014-0…
#> $ expenditure_amount <dbl> 500.00, 1.85, 66.47, 3500.00, 5.00, 5.00, -5.00, -5.00, 71.97, 288.51, 73.59, -73.59, 73.59…
#> $ description        <chr> NA, NA, "RECONCILIATION - FUEL EXPENSE NOT PREVIOUSLY POSTED", "GENERAL CAMPAIGN CONSULTING…
#> $ purpose            <chr> "Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Un…
#> $ last_name          <chr> "DON BARRINGTON", "NON-ITEMIZED RECIPIENT", "PARK", "CARGILL", "NON-ITEMIZED RECIPIENT", "B…
#> $ first_name         <chr> NA, NA, "RICHARD", "LANCE", NA, NA, NA, NA, "RICHARD", "RICHARD", NA, NA, NA, NA, NA, NA, N…
#> $ middle_name        <chr> NA, NA, "(", NA, NA, NA, NA, NA, "(", "(", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ suffix             <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ address_1          <chr> "4506 NE HIGHLANDER CIRCLE", NA, "247906 E 1920 RD", "1854 CHURCH AVENUE", NA, "P. O. BOX 2…
#> $ address_2          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ city               <chr> "LAWTON", NA, "DEVOL", "HARRAH", NA, "TULSA", "TULSA", NA, "DEVOL", "DEVOL", "OKLAHOMA CITY…
#> $ state              <chr> "OK", NA, "OK", "OK", NA, "OK", "OK", NA, "OK", "OK", "OK", "OK", "OK", "OK", "OK", NA, "OK…
#> $ zip                <chr> "73507", NA, "73531", "73045", NA, "74192", "74192", NA, "73531", "73531", "73105", "73105"…
#> $ filed_date         <date> 2016-07-26, 2016-07-26, 2017-10-09, 2016-10-28, 2016-10-27, 2017-01-10, 2017-06-22, 2017-0…
#> $ committee_type     <chr> "Political Action Committee", "Political Action Committee", "Candidate Committee", "Candida…
#> $ committee_name     <chr> "OKLAHOMA FUNERAL HOME OWNERS", "OKLAHOMA FUNERAL HOME OWNERS", NA, NA, "UNIT CORPORATION P…
#> $ candidate_name     <chr> NA, NA, "SCOOTER PARK", "JUSTIN FREELAND WOOD", NA, NA, NA, NA, "SCOOTER PARK", "SCOOTER PA…
#> $ amended            <chr> "N", "N", "N", "N", "Y", "Y", "Y", "Y", "N", "N", "Y", "Y", "Y", "Y", "N", "N", "N", "N", "…
#> $ employer           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ occupation         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
tail(oke)
#> # A tibble: 6 × 23
#>   expenditure_id org_id expenditure_type      expenditure_date expenditure_amo… description purpose last_name first_name
#>   <chr>          <chr>  <chr>                 <date>                      <dbl> <chr>       <chr>   <chr>     <chr>     
#> 1 248798         8963   Ordinary and Necessa… 2022-02-03                   30   <NA>        Unknown NON-ITEM… <NA>      
#> 2 249334         9937   Ordinary and Necessa… 2022-02-04                    3.2 PROCESSING… Unknown STRIPE    <NA>      
#> 3 249335         9937   Ordinary and Necessa… 2022-02-04                    3.2 PROCESSING… Unknown STRIPE    <NA>      
#> 4 249319         9893   Transfer-Out of Fund… 2022-02-15                71414.  <NA>        Unknown MILLER, … NICOLE    
#> 5 249337         9937   Transfer-Out of Fund… 2022-02-15                44710.  TRANSFER O… Unknown MARTI, T… T.J.      
#> 6 249456         9915   Transfer-Out of Fund… 2022-02-18                 2140.  TRANSFERRI… Unknown BURNS, T… TY        
#> # … with 14 more variables: middle_name <chr>, suffix <chr>, address_1 <chr>, address_2 <chr>, city <chr>, state <chr>,
#> #   zip <chr>, filed_date <date>, committee_type <chr>, committee_name <chr>, candidate_name <chr>, amended <chr>,
#> #   employer <chr>, occupation <chr>
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(oke, count_na)
#> # A tibble: 23 × 4
#>    col                class       n         p
#>    <chr>              <chr>   <int>     <dbl>
#>  1 expenditure_id     <chr>    1104 0.00603  
#>  2 org_id             <chr>    1104 0.00603  
#>  3 expenditure_type   <chr>       0 0        
#>  4 expenditure_date   <date>      0 0        
#>  5 expenditure_amount <dbl>       4 0.0000219
#>  6 description        <chr>   72195 0.395    
#>  7 purpose            <chr>    1104 0.00603  
#>  8 last_name          <chr>      37 0.000202 
#>  9 first_name         <chr>  144963 0.792    
#> 10 middle_name        <chr>  174015 0.951    
#> 11 suffix             <chr>  182800 0.999    
#> 12 address_1          <chr>   60824 0.332    
#> 13 address_2          <chr>  173581 0.949    
#> 14 city               <chr>   60811 0.332    
#> 15 state              <chr>   60800 0.332    
#> 16 zip                <chr>   60800 0.332    
#> 17 filed_date         <date>      0 0        
#> 18 committee_type     <chr>    1104 0.00603  
#> 19 committee_name     <chr>  132811 0.726    
#> 20 candidate_name     <chr>   50169 0.274    
#> 21 amended            <chr>       0 0        
#> 22 employer           <chr>  180983 0.989    
#> 23 occupation         <chr>  181005 0.989
```

There are two columns for the recipient name; one for candidates and one
for committees. Neither column is missing any values without a
corresponding value in other column.

``` r
oke %>% 
  group_by(committee_type) %>% 
  summarise(
    no_cand_name = prop_na(candidate_name),
    no_comm_name = prop_na(committee_name)
  )
#> # A tibble: 5 × 3
#>   committee_type             no_cand_name no_comm_name
#>   <chr>                             <dbl>        <dbl>
#> 1 Candidate Committee                   0            1
#> 2 Political Action Committee            1            0
#> 3 Political Party Committee             1            0
#> 4 Special Function Committee            1            0
#> 5 <NA>                                  1            0
```

Of the other key variables, only a few hundred `last_name` values are
missing.

``` r
key_vars <- c(
  "expenditure_date", "last_name", "expenditure_amount", 
  "candidate_name", "committee_name"
)
```

``` r
prop_na(oke$candidate_name[!is.na(oke$committee_name)])
#> [1] 1
prop_na(oke$committee_name[!is.na(oke$candidate_name)])
#> [1] 1
```

We can flag any record missing a key variable needed to identify a
transaction.

``` r
count_na(oke$expenditure_date)
#> [1] 0
count_na(oke$expenditure_amount)
#> [1] 4
count_na(oke$last_name)
#> [1] 37
oke <- mutate(oke, na_flag = is.na(last_name) | is.na(expenditure_amount))
sum(oke$na_flag)
#> [1] 41
```

### Duplicates

We can also flag any record completely duplicated across every column.

``` r
oke <- flag_dupes(oke, -expenditure_id)
sum(oke$dupe_flag)
#> [1] 4674
mean(oke$dupe_flag)
#> [1] 0.02554378
```

``` r
oke %>% 
  filter(dupe_flag) %>% 
  select(all_of(key_vars)) %>% 
  arrange(expenditure_date)
#> # A tibble: 4,674 × 5
#>    expenditure_date last_name              expenditure_amount candidate_name committee_name                             
#>    <date>           <chr>                               <dbl> <chr>          <chr>                                      
#>  1 2014-12-15       INMAN                               1000  <NA>           COMMITTEE FOR THE INAUGURATION OF GOVERNOR…
#>  2 2014-12-15       INMAN                               1000  <NA>           COMMITTEE FOR THE INAUGURATION OF GOVERNOR…
#>  3 2015-01-09       COLLINS                              110. <NA>           COMMITTEE FOR THE INAUGURATION OF GOVERNOR…
#>  4 2015-01-09       COLLINS                              110. <NA>           COMMITTEE FOR THE INAUGURATION OF GOVERNOR…
#>  5 2015-01-19       NON-ITEMIZED RECIPIENT               400  <NA>           THOROUGHBRED PAC                           
#>  6 2015-01-19       NON-ITEMIZED RECIPIENT               400  <NA>           THOROUGHBRED PAC                           
#>  7 2015-01-19       NON-ITEMIZED RECIPIENT               250  <NA>           THOROUGHBRED PAC                           
#>  8 2015-01-19       NON-ITEMIZED RECIPIENT               400  <NA>           THOROUGHBRED PAC                           
#>  9 2015-01-19       NON-ITEMIZED RECIPIENT               250  <NA>           THOROUGHBRED PAC                           
#> 10 2015-01-19       NON-ITEMIZED RECIPIENT               225  <NA>           THOROUGHBRED PAC                           
#> # … with 4,664 more rows
```

### Categorical

``` r
col_stats(oke, n_distinct)
#> # A tibble: 25 × 4
#>    col                class       n         p
#>    <chr>              <chr>   <int>     <dbl>
#>  1 expenditure_id     <chr>  181877 0.994    
#>  2 org_id             <chr>    2064 0.0113   
#>  3 expenditure_type   <chr>      22 0.000120 
#>  4 expenditure_date   <date>   2580 0.0141   
#>  5 expenditure_amount <dbl>   40041 0.219    
#>  6 description        <chr>   48771 0.267    
#>  7 purpose            <chr>       4 0.0000219
#>  8 last_name          <chr>   17506 0.0957   
#>  9 first_name         <chr>    1307 0.00714  
#> 10 middle_name        <chr>     236 0.00129  
#> 11 suffix             <chr>       8 0.0000437
#> 12 address_1          <chr>   20734 0.113    
#> 13 address_2          <chr>    1097 0.00600  
#> 14 city               <chr>    1464 0.00800  
#> 15 state              <chr>      57 0.000312 
#> 16 zip                <chr>    2535 0.0139   
#> 17 filed_date         <date>   1637 0.00895  
#> 18 committee_type     <chr>       5 0.0000273
#> 19 committee_name     <chr>     598 0.00327  
#> 20 candidate_name     <chr>    1210 0.00661  
#> 21 amended            <chr>       2 0.0000109
#> 22 employer           <chr>     425 0.00232  
#> 23 occupation         <chr>     293 0.00160  
#> 24 na_flag            <lgl>       2 0.0000109
#> 25 dupe_flag          <lgl>       2 0.0000109
```

![](../plots/distinct-plots-1.png)<!-- -->![](../plots/distinct-plots-2.png)<!-- -->![](../plots/distinct-plots-3.png)<!-- -->

### Amounts

``` r
# fix floating point precision
oke$expenditure_amount <- round(oke$expenditure_amount, digits = 2)
```

``` r
summary(oke$expenditure_amount)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
#> -581275      29     150    1196     500 1281370       4
mean(oke$expenditure_amount <= 0, na.rm = TRUE)
#> [1] 0.03834929
```

These are the records with the minimum and maximum amounts.

``` r
glimpse(oke[c(which.max(oke$expenditure_amount), which.min(oke$expenditure_amount)), ])
#> Rows: 2
#> Columns: 25
#> $ expenditure_id     <chr> "136099", "144592"
#> $ org_id             <chr> "8840", "9196"
#> $ expenditure_type   <chr> "Operating Expense", "State Question Communication"
#> $ expenditure_date   <date> 2018-07-31, 2018-09-10
#> $ expenditure_amount <dbl> 1281370.0, -581275.2
#> $ description        <chr> "MEDIA ADVERTISING", NA
#> $ purpose            <chr> "Unknown", "Unknown"
#> $ last_name          <chr> "STRATEGIC MEDIA PLACEMENT INC", "NON-ITEMIZED RECIPIENT"
#> $ first_name         <chr> NA, NA
#> $ middle_name        <chr> NA, NA
#> $ suffix             <chr> NA, NA
#> $ address_1          <chr> "7669 STAGERS LOOP", NA
#> $ address_2          <chr> NA, NA
#> $ city               <chr> "DELAWARE", NA
#> $ state              <chr> "OH", NA
#> $ zip                <chr> "43015", NA
#> $ filed_date         <date> 2018-10-31, 2018-10-30
#> $ committee_type     <chr> "Political Action Committee", "Political Action Committee"
#> $ committee_name     <chr> "MARSY'S LAW FOR OKLAHOMA SQ 794", "OKLAHOMANS AGAINST SQ 793"
#> $ candidate_name     <chr> NA, NA
#> $ amended            <chr> "N", "Y"
#> $ employer           <chr> NA, NA
#> $ occupation         <chr> NA, NA
#> $ na_flag            <lgl> FALSE, FALSE
#> $ dupe_flag          <lgl> FALSE, FALSE
```

The distribution of amount values are typically log-normal.

![](../plots/hist-amount-1.png)<!-- -->

### Dates

We can add the calendar year from `date` with `lubridate::year()`

``` r
oke <- mutate(oke, expenditure_year = year(expenditure_date))
```

``` r
min(oke$expenditure_date)
#> [1] "2014-01-27"
sum(oke$expenditure_year < 2000)
#> [1] 0
max(oke$expenditure_date)
#> [1] "2022-02-18"
sum(oke$expenditure_date > today())
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

### Address

For the street `addresss` variable, the `campfin::normal_address()`
function will force consistence case, remove punctuation, and abbreviate
official USPS suffixes.

``` r
addr_norm <- oke %>% 
  distinct(address_1, address_2) %>% 
  unite(
    col = address_full,
    starts_with("address"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
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
addr_norm
#> # A tibble: 21,367 × 3
#>    address_1                 address_2 address_norm          
#>    <chr>                     <chr>     <chr>                 
#>  1 4506 NE HIGHLANDER CIRCLE <NA>      4506 NE HIGHLANDER CIR
#>  2 <NA>                      <NA>      <NA>                  
#>  3 247906 E 1920 RD          <NA>      247906 E 1920 RD      
#>  4 1854 CHURCH AVENUE        <NA>      1854 CHURCH AVE       
#>  5 P. O. BOX 2300            <NA>      P O BOX 2300          
#>  6 4709 N LINCOLN BLVD       <NA>      4709 N LINCOLN BLVD   
#>  7 511 E LEE                 <NA>      511 E LEE             
#>  8 678 KICKAPOO SPUR         <NA>      678 KICKAPOO SPUR     
#>  9 305 NW 5TH                <NA>      305 NW 5TH            
#> 10 2010 RAMONA DRIVE         <NA>      2010 RAMONA DR        
#> # … with 21,357 more rows
```

``` r
oke <- left_join(oke, addr_norm, by = c("address_1", "address_2"))
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
oke <- oke %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  oke$zip,
  oke$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 × 6
#>   stage        prop_in n_distinct prop_na n_out n_diff
#>   <chr>          <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 oke$zip        0.968       2535   0.332  3939    551
#> 2 oke$zip_norm   0.997       2127   0.334   340    124
```

### State

The state values to not need to be normalized.

``` r
prop_in(oke$state, valid_state)
#> [1] 0.9997054
unique(what_out(oke$state, valid_state))
#> [1] "ON" "BC" "AB" "NS" "SK" "MB"
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
norm_city <- oke %>% 
  distinct(city, state, zip_norm) %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("OK", "DC", "OKLAHOMA"),
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
      "state" = "state",
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
oke <- left_join(
  x = oke,
  y = norm_city,
  by = c(
    "city" = "city_raw", 
    "state", 
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
good_refine <- oke %>% 
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
      "state" = "state",
      "zip_norm" = "zip"
    )
  )
```

    #> # A tibble: 13 × 5
    #>    state zip_norm city_swap         city_refine        n
    #>    <chr> <chr>    <chr>             <chr>          <int>
    #>  1 CA    94107    SAN FRANSICO      SAN FRANCISCO      4
    #>  2 CA    94043    MOUTIAN VIEW      MOUNTAIN VIEW      3
    #>  3 CA    94103    SAN FRANCISON     SAN FRANCISCO      3
    #>  4 OH    45271    CINCINATTI        CINCINNATI         2
    #>  5 OK    73096    WEATHORDFORD      WEATHERFORD        2
    #>  6 VA    23454    VIRGINIA BEACH VA VIRGINIA BEACH     2
    #>  7 CA    94103    SAN FRANSICO      SAN FRANCISCO      1
    #>  8 CA    94105    SAN FRANSICO      SAN FRANCISCO      1
    #>  9 CA    94110    SAN FRANSICO      SAN FRANCISCO      1
    #> 10 OH    45202    CINCINATTI        CINCINNATI         1
    #> 11 OK    73069    NORMANAN          NORMAN             1
    #> 12 OK    74571    TAHILINA          TALIHINA           1
    #> 13 OK    74604    PONCA CITYITY     PONCA CITY         1

Then we can join the refined values back to the database.

``` r
oke <- oke %>% 
  left_join(good_refine, by = names(.)) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

Our goal for normalization was to increase the proportion of city values
known to be valid and reduce the total distinct values by correcting
misspellings.

| stage                    | prop_in | n_distinct | prop_na | n_out | n_diff |
|:-------------------------|--------:|-----------:|--------:|------:|-------:|
| `str_to_upper(oke$city)` |   0.953 |       1464 |   0.332 |  5694 |    397 |
| `oke$city_norm`          |   0.960 |       1390 |   0.334 |  4917 |    319 |
| `oke$city_swap`          |   0.992 |       1212 |   0.334 |  1002 |    139 |
| `oke$city_refine`        |   0.992 |       1203 |   0.334 |   979 |    130 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/bar-progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar-distinct-1.png)<!-- -->

Before exporting, we can remove the intermediary normalization columns
and rename all added variables with the `_clean` suffix.

``` r
oke <- oke %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  rename_all(~str_remove(., "_raw")) %>% 
  relocate(address_clean, city_clean, .before = zip_clean)
```

## Conclude

``` r
glimpse(sample_n(oke, 1000))
#> Rows: 1,000
#> Columns: 29
#> $ expenditure_id     <chr> "135387", "32735", "237185", "72723", "112332", "213376", "226994", "111270", "176511", "65…
#> $ org_id             <chr> "9379", "8043", "10421", "8386", "9218", "7616", "7447", "8866", "8872", "8762", "9943", "8…
#> $ expenditure_type   <chr> "Ordinary and Necessary Campaign Expense", "Officeholder Expense", "Officeholder Expense", …
#> $ expenditure_date   <date> 2018-10-11, 2016-05-23, 2021-09-17, 2017-06-24, 2018-03-11, 2020-10-28, 2021-01-19, 2018-0…
#> $ expenditure_amount <dbl> 50.00, 570.24, 80.00, 240.00, 55.00, 709.28, 2000.00, 1061.18, -24.50, 799.00, 100.00, 85.8…
#> $ description        <chr> "EVENT ADVERTISING", "MILEAGE FOR TRAVEL TO AND FROM THE STATE CAPITOL FOR THE MONTH OF APR…
#> $ purpose            <chr> "Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Un…
#> $ last_name          <chr> "LAMAR SR. CITIZENS CENTER", "WOOD", "NON-ITEMIZED RECIPIENT", "ELKS LODGE", "FACEBOOK", "N…
#> $ first_name         <chr> NA, "JUSTIN", NA, NA, NA, NA, "CODY", "MICHAEL", NA, NA, NA, NA, NA, "MICHAEL", NA, NA, NA,…
#> $ middle_name        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ suffix             <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ address_1          <chr> "3238 WALNUT", "4013 N CHAPMAN", NA, "US 70 WEST", "1601 S. CALIFORNIA AVE", NA, "1819 W 89…
#> $ address_2          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ city               <chr> "LAMAR", "SHAWNEE", NA, "DURANT", "PALO ALTO", NA, "TULSA", "LAWTON", "KREBS", "BROKEN ARRO…
#> $ state              <chr> "OK", "OK", NA, "OK", "CA", NA, "OK", "OK", "OK", "OK", NA, NA, "OK", "OK", "OK", NA, "MD",…
#> $ zip                <chr> "74850", "74804", NA, "74701", "94304", NA, "74132", "73505", "74554", "74014", NA, NA, "73…
#> $ filed_date         <date> 2018-10-28, 2016-08-15, 2021-10-11, 2017-07-26, 2018-06-16, 2020-10-29, 2021-04-27, 2018-0…
#> $ committee_type     <chr> "Candidate Committee", "Candidate Committee", "Candidate Committee", "Candidate Committee",…
#> $ committee_name     <chr> NA, NA, NA, NA, NA, "OKLAHOMA FEDERATION FOR CHILDREN ACTION FUND", "REALTORS PAC OF OKLAHO…
#> $ candidate_name     <chr> "PAUL B SMITH", "JUSTIN FREELAND WOOD", "ANTHONY MOORE", "DUSTIN DWAYNE ROBERTS", "GLEN ALL…
#> $ amended            <chr> "N", "N", "N", "N", "N", "N", "N", "N", "Y", "N", "N", "N", "N", "N", "N", "Y", "N", "N", "…
#> $ employer           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ occupation         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ na_flag            <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
#> $ dupe_flag          <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
#> $ expenditure_year   <dbl> 2018, 2016, 2021, 2017, 2018, 2020, 2021, 2018, 2017, 2017, 2020, 2018, 2017, 2018, 2015, 2…
#> $ address_clean      <chr> "3238 WALNUT", "4013 N CHAPMAN", NA, "US 70 W", "1601 S CALIFORNIA AVE", NA, "1819 W 89TH S…
#> $ city_clean         <chr> "LAMAR", "SHAWNEE", NA, "DURANT", "PALO ALTO", NA, "TULSA", "LAWTON", "KREBS", "BROKEN ARRO…
#> $ zip_clean          <chr> "74850", "74804", NA, "74701", "94304", NA, "74132", "73505", "74554", "74014", NA, NA, "73…
```

1.  There are 182,980 records in the database.
2.  There are 4,674 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 41 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server. We will name the object using a date range of the records
included.

``` r
min_dt <- str_remove_all(min(oke$expenditure_date), "-")
max_dt <- str_remove_all(max(oke$expenditure_date), "-")
csv_ts <- paste(min_dt, max_dt, sep = "-")
```

``` r
clean_dir <- dir_create(here("ok", "expends", "data", "clean"))
clean_csv <- path(clean_dir, glue("ok_expends_{csv_ts}.csv"))
clean_rds <- path_ext_set(clean_csv, "rds")
basename(clean_csv)
#> [1] "ok_expends_20140127-20220218.csv"
```

``` r
write_csv(oke, clean_csv, na = "")
write_rds(oke, clean_rds, compress = "xz")
(clean_size <- file_size(clean_csv))
#> 42.4M
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

## Dictionary

The following table describes the variables in our final exported file:

| Column               | Type        | Definition |
|:---------------------|:------------|:-----------|
| `expenditure_id`     | `character` |            |
| `org_id`             | `character` |            |
| `expenditure_type`   | `character` |            |
| `expenditure_date`   | `double`    |            |
| `expenditure_amount` | `double`    |            |
| `description`        | `character` |            |
| `purpose`            | `character` |            |
| `last_name`          | `character` |            |
| `first_name`         | `character` |            |
| `middle_name`        | `character` |            |
| `suffix`             | `character` |            |
| `address_1`          | `character` |            |
| `address_2`          | `character` |            |
| `city`               | `character` |            |
| `state`              | `character` |            |
| `zip`                | `character` |            |
| `filed_date`         | `double`    |            |
| `committee_type`     | `character` |            |
| `committee_name`     | `character` |            |
| `candidate_name`     | `character` |            |
| `amended`            | `character` |            |
| `employer`           | `character` |            |
| `occupation`         | `character` |            |
| `na_flag`            | `logical`   |            |
| `dupe_flag`          | `logical`   |            |
| `expenditure_year`   | `double`    |            |
| `address_clean`      | `character` |            |
| `city_clean`         | `character` |            |
| `zip_clean`          | `character` |            |
