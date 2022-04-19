Oklahoma Contributions
================
Kiernan Nicholls
Fri Sep 10 16:42:30 2021

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
    -   [Reorganize](#reorganize)
-   [Conclude](#conclude)
-   [Export](#export)
-   [Upload](#upload)

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
here::i_am("ok/contribs/docs/ok_contribs_diary.Rmd")
```

## Data

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
ok_name <- glue("{2014:2021}_ContributionLoanExtract.csv.zip")
raw_url <- str_c(ok_url, ok_name)
raw_dir <- dir_create(here("ok", "contribs", "data", "raw"))
raw_zip <- path(raw_dir, basename(raw_url))
```

    #> 1. `https://guardian.ok.gov/PublicSite/Docs/BulkDataDownloads/2014_ContributionLoanExtract.csv.zip`
    #> 2. `https://guardian.ok.gov/PublicSite/Docs/BulkDataDownloads/2015_ContributionLoanExtract.csv.zip`
    #> 3. `https://guardian.ok.gov/PublicSite/Docs/BulkDataDownloads/2016_ContributionLoanExtract.csv.zip`
    #> 4. `https://guardian.ok.gov/PublicSite/Docs/BulkDataDownloads/2017_ContributionLoanExtract.csv.zip`
    #> 5. `https://guardian.ok.gov/PublicSite/Docs/BulkDataDownloads/2018_ContributionLoanExtract.csv.zip`
    #> 6. `https://guardian.ok.gov/PublicSite/Docs/BulkDataDownloads/2019_ContributionLoanExtract.csv.zip`
    #> 7. `https://guardian.ok.gov/PublicSite/Docs/BulkDataDownloads/2020_ContributionLoanExtract.csv.zip`
    #> 8. `https://guardian.ok.gov/PublicSite/Docs/BulkDataDownloads/2021_ContributionLoanExtract.csv.zip`

``` r
if (!all(file_exists(raw_zip))) {
  download.file(raw_url, raw_zip)
}
```

    #> # A tibble: 8 × 3
    #>   path                                        size modification_time  
    #>   <chr>                                <fs::bytes> <dttm>             
    #> 1 2014_ContributionLoanExtract.csv.zip       5.06K 2021-09-10 14:18:49
    #> 2 2015_ContributionLoanExtract.csv.zip       2.68M 2021-09-10 14:18:49
    #> 3 2016_ContributionLoanExtract.csv.zip       3.88M 2021-09-10 14:18:49
    #> 4 2017_ContributionLoanExtract.csv.zip       3.71M 2021-09-10 14:18:49
    #> 5 2018_ContributionLoanExtract.csv.zip       6.17M 2021-09-10 14:18:49
    #> 6 2019_ContributionLoanExtract.csv.zip       3.37M 2021-09-10 14:18:49
    #> 7 2020_ContributionLoanExtract.csv.zip       4.06M 2021-09-10 14:18:49
    #> 8 2021_ContributionLoanExtract.csv.zip       1.46M 2021-09-10 14:18:49

``` r
raw_csv <- map_chr(raw_zip, unzip, exdir = raw_dir)
```

## Read

``` r
okc <- read_delim(
  file = raw_csv,
  delim = ",",
  escape_backslash = FALSE,
  escape_double = TRUE,
  col_types = cols(
    .default = col_character(),
    `Receipt ID` = col_integer(),
    `Org ID` = col_integer(),
    `Receipt Amount` = col_double(),
    `Receipt Date` = col_date_mdy(),
    `Filed Date` = col_date_mdy()
  )
)
```

``` r
okc <- okc %>% 
  clean_names(case = "snake") %>% 
  mutate(across(amended, function(x) x == "Y"))
```

``` r
count(okc, amended)
#> # A tibble: 2 × 2
#>   amended       n
#>   <lgl>     <int>
#> 1 FALSE   1226758
#> 2 TRUE      19201
prop_distinct(na.omit(okc$receipt_id))
#> [1] 1
```

## Explore

There are 1,245,959 rows of 23 columns. Each record represents a single
contribution made from an individual to a committee.

``` r
glimpse(okc)
#> Rows: 1,245,959
#> Columns: 23
#> $ receipt_id          <int> 5142, 4412, 12516, 748077, 869720, 752266, 808869, 282463, 412349, 10229, 10231, 10233, 10…
#> $ org_id              <int> 7615, 7641, 7497, 9081, 8214, 7451, 7451, 7513, 7513, 7497, 7497, 7497, 7497, 7497, 7497, …
#> $ receipt_type        <chr> "Monetary", "Other Funds Accepted", "Monetary", "Loan", "In-Kind", "Monetary", "Monetary",…
#> $ receipt_date        <date> 2014-01-15, 2014-01-20, 2014-03-17, 2014-05-01, 2014-06-10, 2014-10-11, 2014-10-11, 2014-…
#> $ receipt_amount      <dbl> 5.00, 1.87, 3.00, 7500.00, 73.59, 4.00, -4.00, 500.00, -500.00, 3.00, 3.00, 3.00, 2.00, 2.…
#> $ description         <chr> NA, NA, NA, NA, "PLANNING MEETING", NA, "Offset due to update of filed item", "10/23/14 CO…
#> $ receipt_source_type <chr> NA, "Business", NA, "Candidate (Self)", "Candidate (Self)", "Individual", "Individual", "C…
#> $ last_name           <chr> "NON-ITEMIZED CONTRIBUTOR", "STILLWATER NATIONAL BANK", "NON-ITEMIZED CONTRIBUTOR", "BALLA…
#> $ first_name          <chr> NA, NA, NA, "MATTHEW", "JASON", "WILLIAM", "WILLIAM", NA, NA, NA, NA, NA, NA, NA, NA, "DAV…
#> $ middle_name         <chr> NA, NA, NA, "J", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "L", "L",…
#> $ suffix              <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ address_1           <chr> NA, "308 S MAIN STREET", NA, "3304 BIRDIE CT.", "25 1/2 NE 632RD STREET", "1418 SHERWOOD L…
#> $ address_2           <chr> NA, NA, NA, NA, NA, NA, NA, "#222", "#222", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ city                <chr> NA, "STILLWATER", NA, "CLAREMORE", "OKLAHOMA CITY", "BROKEN ARROW", "BROKEN ARROW", "EDMON…
#> $ state               <chr> NA, "OK", NA, "OK", "OK", "OK", "OK", "OK", "OK", NA, NA, NA, NA, NA, NA, "OK", NA, NA, "O…
#> $ zip                 <chr> NA, "74074", NA, "74019", "73105", "74011", "74011", "73013", "73013", NA, NA, NA, NA, NA,…
#> $ filed_date          <date> 2015-04-24, 2015-04-14, 2015-04-27, 2018-10-23, 2019-02-20, 2019-01-07, 2019-01-07, 2016-…
#> $ committee_type      <chr> "Political Action Committee", "Political Action Committee", "Political Action Committee", …
#> $ committee_name      <chr> "TULSA FRATERNAL ORDER OF POLICE 93 PAC", "OKLAHOMA AGRICULTURE EDUCATION TEACHERS ASSOCIA…
#> $ candidate_name      <chr> NA, NA, NA, "MATTHEW J BALLARD", "JASON LOWE", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ amended             <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FA…
#> $ employer            <chr> NA, NA, NA, NA, NA, "AMERICO", "AMERICO", NA, NA, NA, NA, NA, NA, NA, NA, "PROFESSOR UNIVE…
#> $ occupation          <chr> NA, NA, NA, NA, NA, "GENERAL AGENT", "GENERAL AGENT", NA, NA, NA, NA, NA, NA, NA, NA, "PRO…
tail(okc)
#> # A tibble: 6 × 23
#>   receipt_id org_id receipt_type         receipt_date receipt_amount description   receipt_source_… last_name first_name
#>        <int>  <int> <chr>                <date>                <dbl> <chr>         <chr>            <chr>     <chr>     
#> 1    1428204   9841 Monetary             2021-07-17             25   <NA>          Individual       ELLIOTT   CODY      
#> 2    1424326  10180 Other Funds Accepted 2021-07-21             48.2 BOOK KEEPING… Candidate (Self) SANGIRAR… NANCY     
#> 3    1450681   9823 Monetary             2021-08-04           1000   <NA>          Indian Tribe     CHICKASA… <NA>      
#> 4    1448353   9841 Monetary             2021-08-05           1000   <NA>          Indian Tribe     CHICKASA… <NA>      
#> 5    1453037  10142 Other Funds Accepted 2021-09-08            256.  RECONSILIATI… Candidate (Self) ALFONSO   MARGARET  
#> 6    1451943   9088 Other Funds Accepted 2021-09-30            486.  CHECK FOR CA… Business         DSIGNZ C… <NA>      
#> # … with 14 more variables: middle_name <chr>, suffix <chr>, address_1 <chr>, address_2 <chr>, city <chr>, state <chr>,
#> #   zip <chr>, filed_date <date>, committee_type <chr>, committee_name <chr>, candidate_name <chr>, amended <lgl>,
#> #   employer <chr>, occupation <chr>
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(okc, count_na)
#> # A tibble: 23 × 4
#>    col                 class        n        p
#>    <chr>               <chr>    <int>    <dbl>
#>  1 receipt_id          <int>      272 0.000218
#>  2 org_id              <int>      272 0.000218
#>  3 receipt_type        <chr>        0 0       
#>  4 receipt_date        <date>       0 0       
#>  5 receipt_amount      <dbl>        0 0       
#>  6 description         <chr>  1216948 0.977   
#>  7 receipt_source_type <chr>   637109 0.511   
#>  8 last_name           <chr>      240 0.000193
#>  9 first_name          <chr>   674870 0.542   
#> 10 middle_name         <chr>  1122610 0.901   
#> 11 suffix              <chr>  1236807 0.993   
#> 12 address_1           <chr>   637452 0.512   
#> 13 address_2           <chr>  1221343 0.980   
#> 14 city                <chr>   637357 0.512   
#> 15 state               <chr>   637342 0.512   
#> 16 zip                 <chr>   637342 0.512   
#> 17 filed_date          <date>       0 0       
#> 18 committee_type      <chr>      272 0.000218
#> 19 committee_name      <chr>   226839 0.182   
#> 20 candidate_name      <chr>  1019120 0.818   
#> 21 amended             <lgl>        0 0       
#> 22 employer            <chr>   683015 0.548   
#> 23 occupation          <chr>   683589 0.549
```

There are two columns for the recipient name; one for candidates and one
for committees. Neither column is missing any values without a
corresponding value in other column.

``` r
okc %>% 
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
  "receipt_date", "last_name", "receipt_amount", 
  "candidate_name", "committee_name"
)
```

``` r
prop_na(okc$candidate_name[!is.na(okc$committee_name)])
#> [1] 1
prop_na(okc$committee_name[!is.na(okc$candidate_name)])
#> [1] 1
```

We can flag any record missing a key variable needed to identify a
transaction.

``` r
count_na(okc$receipt_date)
#> [1] 0
count_na(okc$receipt_amount)
#> [1] 0
count_na(okc$last_name)
#> [1] 240
okc <- mutate(okc, na_flag = is.na(last_name))
sum(okc$na_flag)
#> [1] 240
```

### Duplicates

We can also flag any record completely duplicated across every column.

``` r
okc <- flag_dupes(okc, -receipt_id)
mean(okc$dupe_flag)
#> [1] 0.4696736
```

``` r
okc %>% 
  filter(dupe_flag) %>% 
  select(receipt_id, all_of(key_vars))
#> # A tibble: 585,194 × 6
#>    receipt_id receipt_date last_name                receipt_amount candidate_name committee_name                   
#>         <int> <date>       <chr>                             <dbl> <chr>          <chr>                            
#>  1      10229 2014-12-01   NON-ITEMIZED CONTRIBUTOR              3 <NA>           OK AG FUND                       
#>  2      10231 2014-12-01   NON-ITEMIZED CONTRIBUTOR              3 <NA>           OK AG FUND                       
#>  3      10233 2014-12-01   NON-ITEMIZED CONTRIBUTOR              3 <NA>           OK AG FUND                       
#>  4        378 2015-01-02   NON-ITEMIZED CONTRIBUTOR             10 <NA>           FRATERNAL ORDER OF POLICE 123 PAC
#>  5        379 2015-01-02   NON-ITEMIZED CONTRIBUTOR             10 <NA>           FRATERNAL ORDER OF POLICE 123 PAC
#>  6        380 2015-01-02   NON-ITEMIZED CONTRIBUTOR             10 <NA>           FRATERNAL ORDER OF POLICE 123 PAC
#>  7        381 2015-01-02   NON-ITEMIZED CONTRIBUTOR             10 <NA>           FRATERNAL ORDER OF POLICE 123 PAC
#>  8        383 2015-01-02   NON-ITEMIZED CONTRIBUTOR              4 <NA>           FRATERNAL ORDER OF POLICE 123 PAC
#>  9        385 2015-01-02   NON-ITEMIZED CONTRIBUTOR              2 <NA>           FRATERNAL ORDER OF POLICE 123 PAC
#> 10        391 2015-01-02   NON-ITEMIZED CONTRIBUTOR              4 <NA>           FRATERNAL ORDER OF POLICE 123 PAC
#> # … with 585,184 more rows
```

A huge proportion of contributions are duplicates because more than half
of all contributions have the `last_name` value of “NON-ITEMIZED
CONTRIBUTOR”.

``` r
count(okc, last_name, sort = TRUE)
#> # A tibble: 25,159 × 2
#>    last_name                     n
#>    <chr>                     <int>
#>  1 NON-ITEMIZED CONTRIBUTOR 637108
#>  2 SMITH                      6189
#>  3 BROWN                      4061
#>  4 WILLIAMS                   3767
#>  5 JOHNSON                    3155
#>  6 JONES                      3079
#>  7 DAVIS                      2757
#>  8 WILSON                     2646
#>  9 TAYLOR                     2522
#> 10 MILLER                     2512
#> # … with 25,149 more rows
```

These non-itemized contributions are missing a `receipt_source_type`
value.

``` r
unique(okc$last_name[is.na(okc$receipt_source_type)])
#> [1] "NON-ITEMIZED CONTRIBUTOR" NA
```

For the sake of flagging duplicates, we will ignore these values.

``` r
okc$dupe_flag[is.na(okc$receipt_source_type)] <- FALSE
```

``` r
mean(okc$dupe_flag)
#> [1] 0.0133327
okc %>% 
  filter(dupe_flag) %>% 
  select(receipt_id, all_of(key_vars)) %>% 
  arrange(receipt_date, last_name)
#> # A tibble: 16,612 × 6
#>    receipt_id receipt_date last_name receipt_amount candidate_name committee_name  
#>         <int> <date>       <chr>              <dbl> <chr>          <chr>           
#>  1       3533 2015-01-02   AMACHER             12.5 <NA>           SOONER STATE PAC
#>  2       3708 2015-01-02   AMACHER             12.5 <NA>           SOONER STATE PAC
#>  3       3484 2015-01-02   BANDY               12.5 <NA>           SOONER STATE PAC
#>  4       3652 2015-01-02   BANDY               12.5 <NA>           SOONER STATE PAC
#>  5       3508 2015-01-02   BIAS                25   <NA>           SOONER STATE PAC
#>  6       3693 2015-01-02   BIAS                25   <NA>           SOONER STATE PAC
#>  7       3337 2015-01-02   BOURLAND            12.5 <NA>           SOONER STATE PAC
#>  8       3617 2015-01-02   BOURLAND            12.5 <NA>           SOONER STATE PAC
#>  9       3375 2015-01-02   BROBSTON            12.5 <NA>           SOONER STATE PAC
#> 10       3642 2015-01-02   BROBSTON            12.5 <NA>           SOONER STATE PAC
#> # … with 16,602 more rows
```

### Categorical

``` r
col_stats(okc, n_distinct)
#> # A tibble: 25 × 4
#>    col                 class        n          p
#>    <chr>               <chr>    <int>      <dbl>
#>  1 receipt_id          <int>  1245688 1.00      
#>  2 org_id              <int>     1918 0.00154   
#>  3 receipt_type        <chr>       15 0.0000120 
#>  4 receipt_date        <date>    2403 0.00193   
#>  5 receipt_amount      <dbl>     9694 0.00778   
#>  6 description         <chr>     5955 0.00478   
#>  7 receipt_source_type <chr>       13 0.0000104 
#>  8 last_name           <chr>    25159 0.0202    
#>  9 first_name          <chr>     9315 0.00748   
#> 10 middle_name         <chr>     1099 0.000882  
#> 11 suffix              <chr>       31 0.0000249 
#> 12 address_1           <chr>    84577 0.0679    
#> 13 address_2           <chr>     2370 0.00190   
#> 14 city                <chr>     3372 0.00271   
#> 15 state               <chr>       61 0.0000490 
#> 16 zip                 <chr>    12759 0.0102    
#> 17 filed_date          <date>    1493 0.00120   
#> 18 committee_type      <chr>        5 0.00000401
#> 19 committee_name      <chr>      553 0.000444  
#> 20 candidate_name      <chr>     1125 0.000903  
#> 21 amended             <lgl>        2 0.00000161
#> 22 employer            <chr>    38947 0.0313    
#> 23 occupation          <chr>    15959 0.0128    
#> 24 na_flag             <lgl>        2 0.00000161
#> 25 dupe_flag           <lgl>        2 0.00000161
```

### Amounts

``` r
summary(okc$receipt_amount)
#>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
#> -500000.0       2.5       5.0     173.7      25.0 2600000.0
mean(okc$receipt_amount <= 0)
#> [1] 0.01149877
```

These are the records with the minimum and maximum amounts.

``` r
glimpse(okc[c(which.max(okc$receipt_amount), which.min(okc$receipt_amount)), ])
#> Rows: 2
#> Columns: 25
#> $ receipt_id          <int> 748744, 698205
#> $ org_id              <int> 8840, 9196
#> $ receipt_type        <chr> "Monetary", "Monetary"
#> $ receipt_date        <date> 2018-07-30, 2018-03-26
#> $ receipt_amount      <dbl> 2600000, -500000
#> $ description         <chr> NA, "Offset due to update of filed item"
#> $ receipt_source_type <chr> "Business", "Business"
#> $ last_name           <chr> "MARSY'S LAW FOR ALL FOUNDATION", "OKLAHOMA ASSOCIATION OF OPTOMETRIC PHYSICIANS"
#> $ first_name          <chr> NA, NA
#> $ middle_name         <chr> NA, NA
#> $ suffix              <chr> NA, NA
#> $ address_1           <chr> "15 ENTERPRISE", "4850 N LINCOLN BLVD, STE A"
#> $ address_2           <chr> "SUITE 550", NA
#> $ city                <chr> "ALISO VIEJO", "OKLAHOMA CITY"
#> $ state               <chr> "CA", "OK"
#> $ zip                 <chr> "92656", "73105"
#> $ filed_date          <date> 2018-10-31, 2018-07-31
#> $ committee_type      <chr> "Political Action Committee", "Political Action Committee"
#> $ committee_name      <chr> "MARSY'S LAW FOR OKLAHOMA SQ 794", "OKLAHOMANS AGAINST SQ 793"
#> $ candidate_name      <chr> NA, NA
#> $ amended             <lgl> FALSE, TRUE
#> $ employer            <chr> NA, NA
#> $ occupation          <chr> NA, NA
#> $ na_flag             <lgl> FALSE, FALSE
#> $ dupe_flag           <lgl> FALSE, FALSE
```

![](../plots/hist_amount-1.png)<!-- -->

Negative `receipt_amount` values are for refunds and offsets.

``` r
okc %>% 
  filter(receipt_amount < 0) %>% 
  count(description, sort = TRUE)
#> # A tibble: 249 × 2
#>    description                                            n
#>    <chr>                                              <int>
#>  1 Offset due to update of filed item                  5943
#>  2 <NA>                                                4707
#>  3 Offset due to deletion of filed item                 699
#>  4 REFUND                                               228
#>  5 CONTRIBUTION REFUND                                  112
#>  6 REFUND 73% CONTRIBUTION                               98
#>  7 CAMPAIGN SUSPENDED UNTIL FUTURE NOTICE                26
#>  8 REFUND FOR FOR OVERPAYMENT FROM PAYROLL DEDUCTIONS    13
#>  9 CADIDATE UNOPPOSED                                    12
#> 10 REFUND OF CONTRIBUTION                                 9
#> # … with 239 more rows
```

### Dates

We can add the calendar year from `receipt_date` with
`lubridate::year()`

``` r
okc <- mutate(okc, receipt_year = year(receipt_date))
```

``` r
min(okc$receipt_date)
#> [1] "2014-01-15"
sum(okc$receipt_year < 2000)
#> [1] 0
max(okc$receipt_date)
#> [1] "2021-09-30"
sum(okc$receipt_date > today())
#> [1] 1
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
addr_norm <- okc %>%
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
sample_n(addr_norm, 10)
#> # A tibble: 10 × 3
#>    address_1               address_2   address_norm                   
#>    <chr>                   <chr>       <chr>                          
#>  1 600 CASA ALLEGRE        <NA>        600 CASA ALLEGRE               
#>  2 2737 NW 140TH ST        APT 808     2737 NW 140TH ST APT 808       
#>  3 441 NW 35TH ST          <NA>        441 NW 35TH ST                 
#>  4 P.O. BOX 797            <NA>        PO BOX 797                     
#>  5 901 NW 63RD, SUITE 101  <NA>        901 NW 63RD SUITE 101          
#>  6 20164 E COUNTY ROAD 175 <NA>        20164 E COUNTY ROAD 175        
#>  7 15015 WEST GIDEON RD    <NA>        15015 WEST GIDEON RD           
#>  8 909 E WRANGLER BLVD     PO BOX 1482 909 E WRANGLER BLVD PO BOX 1482
#>  9 3248 ROCK HOLLOW RD.    <NA>        3248 ROCK HOLLOW RD            
#> 10 4009 SHENANDOAH         <NA>        4009 SHENANDOAH
```

``` r
okc <- left_join(okc, addr_norm, by = c("address_1", "address_2"))
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
okc <- okc %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  okc$zip,
  okc$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 × 6
#>   stage        prop_in n_distinct prop_na n_out n_diff
#>   <chr>          <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 okc$zip        0.912      12759   0.512 53598   8487
#> 2 okc$zip_norm   0.998       4758   0.512  1167    328
```

### State

The only invalid `state` values are either missing or Canadian
provinces.

``` r
okc %>% 
  count(state, sort = TRUE) %>% 
  filter(state %out% valid_state)
#> # A tibble: 5 × 2
#>   state      n
#>   <chr>  <int>
#> 1 <NA>  637342
#> 2 ON        15
#> 3 AB         6
#> 4 BC         1
#> 5 QC         1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
norm_city <- okc %>% 
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
      "state",
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
okc <- left_join(
  x = okc,
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
good_refine <- okc %>% 
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
      "state",
      "zip_norm" = "zip"
    )
  )
```

    #> # A tibble: 18 × 5
    #>    state zip_norm city_swap         city_refine       n
    #>    <chr> <chr>    <chr>             <chr>         <int>
    #>  1 OK    73557    MEDICIAN PARK     MEDICINE PARK     5
    #>  2 OK    74135    TULSATULSA        TULSA             4
    #>  3 NM    87111    ALBURQURQUE       ALBUQUERQUE       2
    #>  4 OK    74027    DELAWAREDELAWARE  DELAWARE          2
    #>  5 CA    93619    CLOVISCLOVIS      CLOVIS            1
    #>  6 DC    20005    WASHINGONT        WASHINGTON        1
    #>  7 NJ    08807    BRIDGEWATER DR    BRIDGEWATER       1
    #>  8 OK    73018    CHICKASAHS        CHICKASHA         1
    #>  9 OK    73116    OKLAOAHOMA CITY   OKLAHOMA CITY     1
    #> 10 OK    73120    OKLAHOMA CITY OKC OKLAHOMA CITY     1
    #> 11 OK    73438    HEADLETON         HEALDTON          1
    #> 12 OK    73543    GENORIMO          GERONIMO          1
    #> 13 OK    73564    ROOSELVET         ROOSEVELT         1
    #> 14 OK    74006    BATRLETSVILLE     BARTLESVILLE      1
    #> 15 OK    74501    MCALALESTER       MCALESTER         1
    #> 16 OK    74571    TAHILINA          TALIHINA          1
    #> 17 OK    74953    POTEAU U          POTEAU            1
    #> 18 VA    22201    ARARLINGTON       ARLINGTON         1

Then we can join the refined values back to the database.

``` r
okc <- okc %>% 
  left_join(good_refine, by = names(.)) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

Our goal for normalization was to increase the proportion of city values
known to be valid and reduce the total distinct values by correcting
misspellings.

| stage                    | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
|:-------------------------|---------:|------------:|---------:|-------:|--------:|
| `str_to_upper(okc$city)` |    0.973 |        3372 |    0.512 |  16562 |     986 |
| `okc$city_norm`          |    0.976 |        3153 |    0.512 |  14832 |     754 |
| `okc$city_swap`          |    0.996 |        2639 |    0.512 |   2428 |     234 |
| `okc$city_refine`        |    0.996 |        2621 |    0.512 |   2401 |     216 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/bar_progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar_distinct-1.png)<!-- -->

### Reorganize

Before exporting, we can remove the intermediary normalization columns
and rename all added variables with the `_clean` suffix.

``` r
okc <- okc %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  rename_all(~str_remove(., "_raw")) %>% 
  relocate(address_clean, city_clean, zip_clean, .after = last_col())
```

``` r
glimpse(sample_n(okc, 50))
#> Rows: 50
#> Columns: 29
#> $ receipt_id          <int> 1163305, 1074818, 718902, 972233, 1162605, 686461, 500258, 904711, 464055, 1150605, 180224…
#> $ org_id              <int> 9931, 7447, 7730, 7743, 9640, 9280, 7565, 7565, 7615, 7447, 7524, 10301, 7461, 7510, 7472,…
#> $ receipt_type        <chr> "Monetary", "Monetary", "Monetary", "Monetary", "Monetary", "Monetary", "Monetary", "Monet…
#> $ receipt_date        <date> 2020-06-18, 2019-11-29, 2018-08-06, 2019-09-01, 2020-04-24, 2018-06-11, 2017-12-26, 2019-…
#> $ receipt_amount      <dbl> 1000.00, 50.00, 80.00, 49.00, 100.00, 10.00, 0.00, 2.00, 5.00, 10.50, 3.00, 1.75, 5.95, 4.…
#> $ description         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "GRAPHICS", NA, NA, NA, NA…
#> $ receipt_source_type <chr> "Political Action Committee (Registered)", NA, "Individual", NA, "Individual", NA, NA, NA,…
#> $ last_name           <chr> "REALTORS PAC OF OKLAHOMA", "NON-ITEMIZED CONTRIBUTOR", "LEGGETT", "NON-ITEMIZED CONTRIBUT…
#> $ first_name          <chr> NA, NA, "CHARLES", NA, "RODNEY", NA, NA, NA, "THOMAS", NA, NA, "STEPHANIE", "CHARLES S", N…
#> $ middle_name         <chr> NA, NA, "R", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "F.", NA,…
#> $ suffix              <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ address_1           <chr> "9807 N BROADWAY EXT.", NA, "1251 S 94TH ST W", NA, "10508 CONCORD DR", NA, NA, NA, "11945…
#> $ address_2           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ city                <chr> "OKLAHOMA CITY", NA, "MUSKOGEE", NA, "OKLAHOMA CITY", NA, NA, NA, "OWASSO", NA, NA, "EDMON…
#> $ state               <chr> "OK", NA, "OK", NA, "OK", NA, NA, NA, "OK", NA, NA, "OK", "OK", NA, NA, NA, "TX", NA, NA, …
#> $ zip                 <chr> "73114", NA, "74401", NA, "73151", NA, NA, NA, "74055", NA, NA, "73003-5934", "73112", NA,…
#> $ filed_date          <date> 2020-08-17, 2020-01-31, 2018-10-01, 2019-10-19, 2020-07-31, 2018-07-26, 2018-01-10, 2019-…
#> $ committee_type      <chr> "Candidate Committee", "Political Action Committee", "Political Action Committee", "Politi…
#> $ committee_name      <chr> NA, "REALTORS PAC OF OKLAHOMA", "OKLAHOMA QUARTER HORSE RACING PAC", "SOUTHWEST LABORERS D…
#> $ candidate_name      <chr> "MARK LAWSON", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "KEVIN STITT", NA, NA, NA, NA, "BRO…
#> $ amended             <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ employer            <chr> NA, NA, "SELF", NA, "MODERN ABODE REALTY", NA, NA, NA, "CITY OF TULSA", NA, NA, "RETIRED",…
#> $ occupation          <chr> NA, NA, "HORSE RACING", NA, "REALTOR", NA, NA, NA, "POLICE OFFICER", NA, NA, "RETIRED", "P…
#> $ na_flag             <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ dupe_flag           <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ receipt_year        <dbl> 2020, 2019, 2018, 2019, 2020, 2018, 2017, 2019, 2017, 2020, 2015, 2021, 2020, 2017, 2021, …
#> $ address_clean       <chr> "9807 N BROADWAY EXT", NA, "1251 S 94TH ST W", NA, "10508 CONCORD DR", NA, NA, NA, "11945 …
#> $ city_clean          <chr> "OKLAHOMA CITY", NA, "MUSKOGEE", NA, "OKLAHOMA CITY", NA, NA, NA, "OWASSO", NA, NA, "EDMON…
#> $ zip_clean           <chr> "73114", NA, "74401", NA, "73151", NA, NA, NA, "74055", NA, NA, "73003", "73112", NA, NA, …
```

## Conclude

1.  There are 1,245,959 records in the database.
2.  There are 16,612 duplicate records in the database.
3.  Checked the range and distribution of `receipt_amount` and
    `receipt_date`.
4.  There are 240 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `receipt_year` variable has been created.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("ok", "contribs", "data", "clean"))
clean_path <- path(clean_dir, "ok_contribs_2015-20210910.csv")
write_csv(okc, clean_path, na = "")
(clean_size <- file_size(clean_path))
#> 258M
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
