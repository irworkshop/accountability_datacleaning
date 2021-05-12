Texas Expenditures
================
Kiernan Nicholls
2020-07-13 17:55:51

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
  - [Conclude](#conclude)
  - [Export](#export)
  - [Upload](#upload)

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
  batman, # convert to logical
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
#> [1] "/home/kiernan/Code/tap/R_campfin"
```

## Data

Data is obtained from the [Texas Ethics Commission
(TEC)](https://www.ethics.state.tx.us/search/cf/). According to [a TEC
brochure](https://www.ethics.state.tx.us/data/about/Bethic.pdf),

> tatutory duties of the Ethics Commission are in Chapter 571 of the
> Government Code. The agency is responsible for administering these
> laws: (1) Title 15, Election Code, concerning political contributions
> and expenditures, and political advertising…

> The Ethics Commission serves as a repository of required disclosure
> statements for state officials, candidates,political committees,
> lobbyists, and certain district and county judicial officers.

Data is obtained from the [Campaign Finance section of the TEC
website](https://www.ethics.state.tx.us/search/cf/). An entire database
can be downloaded as [a ZIP
file](https://www.ethics.state.tx.us/data/search/cf/TEC_CF_CSV.zip). The
contents of that ZIP and the layout of the files within are outlined in
the [`CFS-ReadMe.txt`
file](https://www.ethics.state.tx.us/data/search/cf/CFS-ReadMe.txt).

> This zip package contains detailed information from campaign finance
> reports filed electronically with the Texas Ethics Commission
> beginning July 1, 2000. Flat File Architecture Record Listing –
> Generated 06/11/2016 12:38:08 PM

``` r
readme_url <- "https://www.ethics.state.tx.us/data/search/cf/CFS-ReadMe.txt"
readme <- read_lines(here("tx", "expends", "CFS-ReadMe.txt"))
```

At the top of this file is a table of contents.

``` r
read_table(readme[seq(13, 47, 2)][-2]) %>% 
  unite(`File Contents`, 2:3, sep = " ") %>% 
  mutate(
    `File Name(s)` = `File Name(s)` %>% 
      str_split(",\\s") %>% 
      map(md_code) %>% 
      map_chr(str_c, collapse = ", "),
    `File Contents` = str_trunc(`File Contents`, width = 30)
  ) %>% 
  kable()
```

| Record Name      | File Contents                 | File Name(s)                                    |
| :--------------- | :---------------------------- | :---------------------------------------------- |
| AssetData        | Assets - Schedule M           | `assets.csv`                                    |
| CandidateData    | Direct Campaign Expenditure…  | `cand.csv`                                      |
| ContributionData | Contributions - Schedules A/C | `contribs_##.csv`, `cont_ss.csv`, `cont_t.csv,` |
| CoverSheet1Data  | Cover Sheet 1 - Cover sheet…  | `cover.csv`, `cover_ss.csv`, `cover_t.csv`      |
| CoverSheet2Data  | Cover Sheet 2 - Notices rec…  | `notices.csv`                                   |
| CoverSheet3Data  | Cover Sheet 3 - Committee p…  | `purpose.csv`                                   |
| CreditData       | Credits - Schedule K          | `credits.csv`                                   |
| DebtData         | Debts - Schedule L            | `debts.csv`                                     |
| ExpendData       | Expenditures - Schedules F/…  | `expend_##.csv`, `expn_t.csv`                   |
| ExpendCategory   | Expenditure category codes    | `expn_catg.csv`                                 |
| FilerData        | Filer index                   | `filers.csv`                                    |
| FinalData        | Final reports                 | `final.csv`                                     |
| LoanData         | Loans - Schedule E            | `loans.csv`                                     |
| PledgeData       | Pledges - Schedule B          | `pledges.csv`, `pldg_ss.csv`, `pldg_t.csv`      |
| SpacData         | Index of Specific-purpose c…  | `spacs.csv`                                     |
| TravelData       | Travel outside the State of…  | `travel.csv`                                    |

From this table, we know the ExpendData record (`contribs_##.csv`)
contains the data we want.

> Expenditures - Schedules F/G/H/I - Expenditures from special
> pre-election (formerly Telegram) reports are stored in the file
> `expn_t`. They are kept separate from the expends file to avoid
> creating duplicates, because they are supposed to be re-reported on
> the next regular campaign finance report.

| Pos | Field                      | Type       | Mask          | Len | Description                                                                |
| --: | :------------------------- | :--------- | :------------ | --: | :------------------------------------------------------------------------- |
|   1 | `record_type`              | String     |               |  20 | Record type code - always EXPN                                             |
|   2 | `form_type_cd`             | String     |               |  20 | TEC form used                                                              |
|   3 | `sched_form_type_cd`       | String     |               |  20 | TEC Schedule Used                                                          |
|   4 | `report_info_ident`        | Long       | 00000000000   |  11 | Unique report \#                                                           |
|   5 | `received_dt`              | Date       | yyyyMMdd      |   8 | Date report received by TEC                                                |
|   6 | `info_only_flag`           | String     |               |   1 | Superseded by other report                                                 |
|   7 | `filer_ident`              | String     |               | 100 | Filer account \#                                                           |
|   8 | `filer_type_cd`            | String     |               |  30 | Type of filer                                                              |
|   9 | `filer_name`               | String     |               | 200 | Filer name                                                                 |
|  10 | `expend_info_id`           | Long       | 00000000000   |  11 | Expenditure unique identifier                                              |
|  11 | `expend_dt`                | Date       | yyyyMMdd      |   8 | Expenditure date                                                           |
|  12 | `expend_amount`            | BigDecimal | 0000000000.00 |  12 | Expenditure amount                                                         |
|  13 | `expend_descr`             | String     |               | 100 | Expenditure description                                                    |
|  14 | `expend_cat_cd`            | String     |               |  30 | Expenditure category code                                                  |
|  15 | `expend_cat_descr`         | String     |               | 100 | Expenditure category description                                           |
|  16 | `itemize_flag`             | String     |               |   1 | Y indicates that the expenditure is itemized                               |
|  17 | `travel_flag`              | String     |               |   1 | Y indicates that the expenditure has associated travel                     |
|  18 | `political_expend_cd`      | String     |               |  30 | Political expenditure indicator                                            |
|  19 | `reimburse_intended_flag`  | String     |               |   1 | Reimbursement intended indicator                                           |
|  20 | `src_corp_contrib_flag`    | String     |               |   1 | Expenditure from corporate funds indicator                                 |
|  21 | `capital_livingexp_flag`   | String     |               |   1 | Austin living expense indicator                                            |
|  22 | `payee_persent_type_cd`    | String     |               |  30 | Type of payee name data - INDIVIDUAL or ENTITY                             |
|  23 | `payee_name_organization`  | String     |               | 100 | For ENTITY, the payee organization name                                    |
|  24 | `payee_name_last`          | String     |               | 100 | For INDIVIDUAL, the payee last name                                        |
|  25 | `payee_name_suffix_cd`     | String     |               |  30 | For INDIVIDUAL, the payee name suffix (e.g. JR, MD, II)                    |
|  26 | `payee_name_first`         | String     |               |  45 | For INDIVIDUAL, the payee first name                                       |
|  27 | `payee_name_prefix_cd`     | String     |               |  30 | For INDIVIDUAL, the payee name prefix (e.g. MR, MRS, MS)                   |
|  28 | `payee_name_short`         | String     |               |  25 | For INDIVIDUAL, the payee short name (nickname)                            |
|  29 | `payee_street_addr1`       | String     |               |  55 | Payee street address - line 1                                              |
|  30 | `payee_street_addr2`       | String     |               |  55 | Payee street address - line 2                                              |
|  31 | `payee_street_city`        | String     |               |  30 | Payee street address - city                                                |
|  32 | `payee_street_state_cd`    | String     |               |   2 | Payee street address - state code (e.g. TX, CA) - for country=USA/UMI only |
|  33 | `payee_street_county_cd`   | String     |               |   5 | Payee street address - Texas county                                        |
|  34 | `payee_street_country_cd`  | String     |               |   3 | Payee street address - country (e.g. USA, UMI, MEX, CAN)                   |
|  35 | `payee_street_postal_code` | String     |               |  20 | Payee street address - postal code - for USA addresses only                |
|  36 | `payee_street_region`      | String     |               |  30 | Payee street address - region for country other than USA                   |

The ExpendCategory record is a small table explaining the expenditure
category codes used.

| Pos | Field                        | Type   | Mask | Len | Description                      |
| --: | :--------------------------- | :----- | :--- | --: | :------------------------------- |
|   1 | `record_type`                | String |      |  20 | Record type code - always EXCAT  |
|   2 | `expend_category_code_value` | String |      |  30 | Expenditure category code        |
|   3 | `expend_category_code_label` | String |      | 100 | Expenditure category description |

### Download

``` r
raw_dir <- dir_create(here("tx", "expends", "data", "raw"))
zip_url <- "https://www.ethics.state.tx.us/data/search/cf/TEC_CF_CSV.zip"
zip_file <- path(raw_dir, basename(zip_url))
```

If the file hasn’t been downloaded yet, do so now.

``` r
if (!file_exists(zip_file)) {
  download.file(
    url = zip_url, 
    destfile = zip_file,
    method = "curl"
  )
}
```

### Extract

There are 80 CSV files inside the ZIP archive.

``` r
zip_contents <- 
  unzip(zip_file, list = TRUE) %>% 
  as_tibble(.name_repair = make_clean_names) %>%
  mutate(across(length, as_fs_bytes)) %>% 
  filter(str_detect(name, "expend_\\d{2}"))
```

``` r
zip_expends <- str_subset(zip_contents$name, "expend_\\d{2}.csv")
```

If the files haven’t been extracted, we can do so now.

``` r
zip_expends <- as_fs_path(unzip(
  zipfile = zip_file,
  files = zip_expends,
  exdir = raw_dir
))
```

### Read

The TEC provides a helpful [record layout
key](https://www.ethics.state.tx.us/data/search/cf/CampaignFinanceCSVFileFormat.pdf)
describing the structure of their flat files. We can use the details in
this key to properly read the files into R.

> The CSV file contains comma-delimited records –one line per record.
> Each record consists of fields separated by commas.The following
> characters constitute the permitted list. The space characterand
> commaarenotin this list. `! @ # $ % * -_ + : ; . / 0-9 A-Z a-z`

> If a raw data field contains any character other than these permitted
> characters, then the field is surrounded by double-quotesin the CSV.
> Space is notin the above list–meaning that data containing spaces will
> be double-quoted. Raw field data containing double-quotes will have
> doubled double-quotes in the CSV encoding.In both raw dataand CSV
> encoding, new lines are represented with the escape notation `\n`.

We can use this information as the arguments to `vroom::vroom()` and
read all 8 files at once into a single data frame.

``` r
txe <- vroom(
  file = zip_expends,
  .name_repair = make_clean_names,
  na = c("", "NA", "N/A", "UNKNOWN"),
  delim = ",",
  col_names = TRUE,
  escape_double = TRUE,
  escape_backslash = FALSE,
  num_threads = 1,
  locale = locale(tz = "US/Central"),
  col_types = cols(
    .default = col_character(),
    receivedDt = col_date("%Y%m%d"),
    expendDt = col_date("%Y%m%d"),
    expendAmount = col_double()
  )
)
```

## Explore

``` r
glimpse(txe)
#> Rows: 3,676,011
#> Columns: 32
#> $ form           <chr> "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "…
#> $ schedule       <chr> "F1", "F1", "F1", "F1", "F1", "F1", "F1", "F1", "F1", "F1", "F1", "F1", "…
#> $ report_id      <chr> "157773", "323134", "157773", "311114", "157773", "235729", "207492", "29…
#> $ received       <date> 2000-10-12, 2006-11-01, 2000-10-12, 2006-06-01, 2000-10-12, 2004-01-02, …
#> $ info_flag      <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ filer_id       <chr> "00010883", "00010883", "00010883", "00010883", "00010883", "00010883", "…
#> $ filer_type     <chr> "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "…
#> $ filer          <chr> "THE EL PASO ENERGY CORPORATION PAC", "El Paso Corporation PAC", "THE EL …
#> $ id             <chr> "100000001", "100000002", "100000003", "100000004", "100000005", "1000000…
#> $ date           <date> 2000-09-14, 2006-10-10, 2000-09-12, 2006-05-02, 2000-09-01, 2003-12-17, …
#> $ amount         <dbl> 1000.00, 1000.00, 500.00, 1000.00, 2500.00, 250.00, 1000.00, 1000.00, 200…
#> $ describe       <chr> "CONTRIBUTION TO POLITICAL COMMITTEE", "Desc:Direct Contribution", "CONTR…
#> $ category       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ description    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ itemize_flag   <lgl> TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, T…
#> $ travel_flag    <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ politics_flag  <lgl> TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, T…
#> $ reimburse_flag <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ corp_flag      <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ liveexp_flag   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ payee_type     <chr> "ENTITY", "ENTITY", "ENTITY", "ENTITY", "ENTITY", "ENTITY", "ENTITY", "EN…
#> $ vendor         <chr> "WARREN CHISUM CAMPAIGN", "Alaskans For Don Young", "GARNET COLEMAN CAMPA…
#> $ last           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "RICHARDS…
#> $ suffix         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "III", NA…
#> $ first          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "JOEL", N…
#> $ prefix         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ addr1          <chr> "P.O. BOX 1512", "2504 Fairbanks Street", "P. O. BOX 88140", "1331 H Stre…
#> $ addr2          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "Suite A", NA, "104 Hume Avenue", NA,…
#> $ city           <chr> "PAMPA", "Anchorage", "HOUSTON", "Washington", "HOUSTON", "WACO", "VICTOR…
#> $ state          <chr> "TX", "AK", "TX", "DC", "TX", "TX", "TX", "LA", "TX", "DC", "TX", "VA", "…
#> $ zip            <chr> "79066-1512", "99503", "77288", "20005", "77098", "76702", "77402", "7001…
#> $ region         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
tail(txe)
#> # A tibble: 6 x 32
#>   form  schedule report_id received   info_flag filer_id filer_type filer id    date       amount
#>   <chr> <chr>    <chr>     <date>     <lgl>     <chr>    <chr>      <chr> <chr> <date>      <dbl>
#> 1 JCOH  F1       100789564 2020-07-12 FALSE     00081704 JCOH       Mays… 1042… 2020-05-29   12  
#> 2 JCOH  F1       100789564 2020-07-12 FALSE     00081704 JCOH       Mays… 1042… 2020-06-30   12  
#> 3 JCOH  F1       100789564 2020-07-12 FALSE     00081704 JCOH       Mays… 1042… 2020-02-21  108. 
#> 4 JCOH  F1       100789564 2020-07-12 FALSE     00081704 JCOH       Mays… 1042… 2020-02-26   49.6
#> 5 JCOH  F1       100789564 2020-07-12 FALSE     00081704 JCOH       Mays… 1042… 2020-02-27   46.2
#> 6 GPAC  F1       100789781 2020-07-12 FALSE     00016824 GPAC       Waco… 1042… 2020-03-24 2396. 
#> # … with 21 more variables: describe <chr>, category <chr>, description <chr>, itemize_flag <lgl>,
#> #   travel_flag <lgl>, politics_flag <lgl>, reimburse_flag <lgl>, corp_flag <lgl>,
#> #   liveexp_flag <lgl>, payee_type <chr>, vendor <chr>, last <chr>, suffix <chr>, first <chr>,
#> #   prefix <chr>, addr1 <chr>, addr2 <chr>, city <chr>, state <chr>, zip <chr>, region <chr>
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(txe, count_na)
#> # A tibble: 32 x 4
#>    col            class        n        p
#>    <chr>          <chr>    <int>    <dbl>
#>  1 form           <chr>        0 0       
#>  2 schedule       <chr>        0 0       
#>  3 report_id      <chr>        0 0       
#>  4 received       <date>     520 0.000141
#>  5 info_flag      <lgl>        0 0       
#>  6 filer_id       <chr>        0 0       
#>  7 filer_type     <chr>        0 0       
#>  8 filer          <chr>      559 0.000152
#>  9 id             <chr>        0 0       
#> 10 date           <date>   21282 0.00579 
#> 11 amount         <dbl>    21275 0.00579 
#> 12 describe       <chr>    25154 0.00684 
#> 13 category       <chr>  1574259 0.428   
#> 14 description    <chr>  3586682 0.976   
#> 15 itemize_flag   <lgl>        0 0       
#> 16 travel_flag    <lgl>        0 0       
#> 17 politics_flag  <lgl>   670044 0.182   
#> 18 reimburse_flag <lgl>        0 0       
#> 19 corp_flag      <lgl>    14990 0.00408 
#> 20 liveexp_flag   <lgl>   349203 0.0950  
#> 21 payee_type     <chr>    20092 0.00547 
#> 22 vendor         <chr>   812041 0.221   
#> 23 last           <chr>  2883096 0.784   
#> 24 suffix         <chr>  3666975 0.998   
#> 25 first          <chr>  2886387 0.785   
#> 26 prefix         <chr>  3434303 0.934   
#> 27 addr1          <chr>    57490 0.0156  
#> 28 addr2          <chr>  3340151 0.909   
#> 29 city           <chr>    39237 0.0107  
#> 30 state          <chr>    31176 0.00848 
#> 31 zip            <chr>    53305 0.0145  
#> 32 region         <chr>  3674794 1.00
```

We can use `campfin::flag_na()` to create a new `na_flag` variable to
identify any record missing one of the values needed to identify the
transaction.

We will have to create a temporary single variable with names for both
individual and entity payees.

``` r
txe <- txe %>%
  mutate(payee = coalesce(last, vendor)) %>% 
  flag_na(payee, date, amount, filer) %>% 
  select(-payee)
```

``` r
percent(mean(txe$na_flag), 0.01)
#> [1] "0.60%"
```

``` r
txe %>% 
  filter(na_flag) %>% 
  select(last, vendor, date, amount, filer) %>% 
  distinct() %>% 
  sample_frac()
#> # A tibble: 1,671 x 5
#>    last  vendor                     date       amount filer                                        
#>    <chr> <chr>                      <date>      <dbl> <chr>                                        
#>  1 <NA>  <NA>                       NA             NA Grimes County Republican Party               
#>  2 <NA>  <NA>                       2008-05-13    100 GREEN PARTY OF TEXAS                         
#>  3 <NA>  <NA>                       NA             NA Corpus Christi Police Officers' Association  
#>  4 <NA>  <NA>                       NA             NA Mitchell, Monte M. (Dr.)                     
#>  5 <NA>  <NA>                       NA             NA Baytown Fire Fighters Political Action Commi…
#>  6 <NA>  U--Haul Moving & Storage   NA             NA Turner, Scott (The Honorable)                
#>  7 <NA>  Dewhurst Campaign Committ… 2008-09-29   1000 <NA>                                         
#>  8 <NA>  Whit-Co Printing           NA             NA Price IV, Walter T. (The Honorable)          
#>  9 <NA>  Southwest Airlines         NA             NA Parker IV, Nathaniel W. (The Honorable)      
#> 10 <NA>  <NA>                       NA             NA Texas Vote Environment                       
#> # … with 1,661 more rows
```

### Duplicates

We can also create a new `dupe_flag` variable to identify any record
which is duplicated at least once across all variables.

``` r
d1 <- duplicated(select(txe, -id), fromLast = FALSE)
d2 <- duplicated(select(txe, -id), fromLast = TRUE)
txe <- mutate(txe, dupe_flag = d1 | d2)
percent(mean(txe$dupe_flag), 0.01)
#> [1] "2.81%"
rm(d1, d2); flush_memory()
```

``` r
txe %>% 
  filter(dupe_flag) %>% 
  select(last, vendor, date, amount, filer)
#> # A tibble: 103,189 x 5
#>    last    vendor                                 date       amount filer                       
#>    <chr>   <chr>                                  <date>      <dbl> <chr>                       
#>  1 <NA>    Mike Ross for Congress                 2007-10-18 5000   El Paso Corporation PAC     
#>  2 <NA>    Mike Ross for Congress                 2007-10-18 5000   El Paso Corporation PAC     
#>  3 <NA>    Democratic Congressional Campaign Cmte 2006-12-21 5000   El Paso Corporation PAC     
#>  4 <NA>    Democratic Congressional Campaign Cmte 2006-12-21 5000   El Paso Corporation PAC     
#>  5 Patrick <NA>                                   2014-05-20 5000   Texas Chiropractic Assn. PAC
#>  6 Patrick <NA>                                   2014-05-20 5000   Texas Chiropractic Assn. PAC
#>  7 <NA>    Dell Financial Services                2009-05-20   28.6 Texas Democratic Party      
#>  8 <NA>    Dell Financial Services                2009-05-20   28.6 Texas Democratic Party      
#>  9 <NA>    IBEW Building                          2012-09-06 3831.  Texas Democratic Party      
#> 10 <NA>    IBEW Building                          2012-09-06 3831.  Texas Democratic Party      
#> # … with 103,179 more rows
```

Much of these duplicate variables are also missing values

``` r
percent(mean(txe$na_flag[txe$dupe_flag]), 0.01)
#> [1] "19.36%"
```

``` r
txe %>% 
  filter(dupe_flag) %>% 
  select(last, vendor, date, amount, filer) %>% 
  col_stats(count_na)
#> # A tibble: 5 x 4
#>   col    class      n         p
#>   <chr>  <chr>  <int>     <dbl>
#> 1 last   <chr>  94227 0.913    
#> 2 vendor <chr>  28587 0.277    
#> 3 date   <date> 19970 0.194    
#> 4 amount <dbl>  19970 0.194    
#> 5 filer  <chr>      2 0.0000194
```

### Categorical

``` r
col_stats(txe, n_distinct)
#> # A tibble: 34 x 4
#>    col            class        n           p
#>    <chr>          <chr>    <int>       <dbl>
#>  1 form           <chr>       27 0.00000734 
#>  2 schedule       <chr>       12 0.00000326 
#>  3 report_id      <chr>   149863 0.0408     
#>  4 received       <date>    6041 0.00164    
#>  5 info_flag      <lgl>        2 0.000000544
#>  6 filer_id       <chr>     8222 0.00224    
#>  7 filer_type     <chr>       14 0.00000381 
#>  8 filer          <chr>    13698 0.00373    
#>  9 id             <chr>  3676011 1          
#> 10 date           <date>    7540 0.00205    
#> 11 amount         <dbl>   212245 0.0577     
#> 12 describe       <chr>   770492 0.210      
#> 13 category       <chr>       21 0.00000571 
#> 14 description    <chr>    17236 0.00469    
#> 15 itemize_flag   <lgl>        1 0.000000272
#> 16 travel_flag    <lgl>        2 0.000000544
#> 17 politics_flag  <lgl>        3 0.000000816
#> 18 reimburse_flag <lgl>        2 0.000000544
#> 19 corp_flag      <lgl>        3 0.000000816
#> 20 liveexp_flag   <lgl>        3 0.000000816
#> 21 payee_type     <chr>        3 0.000000816
#> 22 vendor         <chr>   311119 0.0846     
#> 23 last           <chr>    43309 0.0118     
#> 24 suffix         <chr>       33 0.00000898 
#> 25 first          <chr>    28395 0.00772    
#> 26 prefix         <chr>       31 0.00000843 
#> 27 addr1          <chr>   527871 0.144      
#> 28 addr2          <chr>    28726 0.00781    
#> 29 city           <chr>    17318 0.00471    
#> 30 state          <chr>      101 0.0000275  
#> 31 zip            <chr>    46457 0.0126     
#> 32 region         <chr>      180 0.0000490  
#> 33 na_flag        <lgl>        2 0.000000544
#> 34 dupe_flag      <lgl>        2 0.000000544
```

``` r
txe %>% 
  select(ends_with("_flag")) %>% 
  map_dbl(mean) %>% 
  enframe(
    name = "lgl_var",
    value = "prop_true"
  ) %>% 
  kable(digits = 2)
```

| lgl\_var        | prop\_true |
| :-------------- | ---------: |
| info\_flag      |       0.16 |
| itemize\_flag   |       1.00 |
| travel\_flag    |       0.00 |
| politics\_flag  |         NA |
| reimburse\_flag |       0.04 |
| corp\_flag      |         NA |
| liveexp\_flag   |         NA |
| na\_flag        |       0.01 |
| dupe\_flag      |       0.03 |

### Amounts

The `amount` value ranges from a -$5,000 minimum to $16,996,410, with
only 15 records having a value less than $0.

``` r
noquote(map_chr(summary(txe$amount), dollar))
#>        Min.     1st Qu.      Median        Mean     3rd Qu.        Max.        NA's 
#>     -$5,000      $47.57     $161.10   $1,258.26        $550 $16,996,410     $21,275
sum(txe$amount <= 0, na.rm = TRUE)
#> [1] 319
```

The logarithm of `expend_amount` is normally distributed around the
median value of .

![](../plots/amount_histogram-1.png)<!-- -->

We can explore the distribution and range of `expend_amount` by
expenditure category and filer type to better understand how Texans are
spending money during different kinds of campaigns.

![](../plots/amount_violin_what-1.png)<!-- -->

![](../plots/amount_violin_who-1.png)<!-- -->

### Dates

To better explore and search the database, we will create a `year`
variable from `date` using `lubridate::year()`

``` r
txe <- mutate(txe, year = year(date))
```

The date range is fairly clean, with 0 values after 2020-07-13 and only
91 before the year 2000.

``` r
percent(prop_na(txe$date), 0.01)
#> [1] "0.58%"
min(txe$date, na.rm = TRUE)
#> [1] "1994-10-01"
sum(txe$year < 2000, na.rm = TRUE)
#> [1] 91
max(txe$date, na.rm = TRUE)
#> [1] "2020-07-12"
sum(txe$date > today(), na.rm = TRUE)
#> [1] 0
```

We can see that the few expenditures in 1994 and 1999 seem to be
outliers, with the vast majority of expenditures coming from 2000
through 2019. We will flag these records.

``` r
count(txe, year, sort = FALSE) %>% print(n = 23)
#> # A tibble: 24 x 2
#>     year      n
#>    <dbl>  <int>
#>  1  1994     14
#>  2  1999     77
#>  3  2000  83693
#>  4  2001  80415
#>  5  2002 177322
#>  6  2003  86667
#>  7  2004 149801
#>  8  2005 150066
#>  9  2006 208488
#> 10  2007 132657
#> 11  2008 213552
#> 12  2009 154416
#> 13  2010 262524
#> 14  2011 154846
#> 15  2012 243062
#> 16  2013 182038
#> 17  2014 265798
#> 18  2015 158825
#> 19  2016 220242
#> 20  2017 182422
#> 21  2018 302170
#> 22  2019 187425
#> 23  2020  58209
#> # … with 1 more row
```

![](../plots/year_bar-1.png)<!-- -->

![](../plots/amount_line_month-1.png)<!-- -->

## Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are tailor made to facilitate this process.

### Address

For the street `addr1` and `addr2` variables, the
`campfin::normal_address()` function will force consistence case, remove
punctuation, and abbreviate official USPS suffixes.

``` r
txe <- txe %>% 
  unite(
    col = addr_full,
    starts_with("addr"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    addr_norm = normal_address(
      address = addr_full,
      abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-addr_full)
```

``` r
txe %>% 
  select(starts_with("addr")) %>% 
  distinct() %>% 
  sample_n(10)
#> # A tibble: 10 x 3
#>    addr1                                           addr2     addr_norm                             
#>    <chr>                                           <chr>     <chr>                                 
#>  1 300 S A.W. Grimes Blvd #20205                   <NA>      300 S A W GRIMES BLVD 20205           
#>  2 7305 Golden Hawk                                <NA>      7305 GOLDEN HAWK                      
#>  3 2805 Business Center Drive                      <NA>      2805 BUSINESS CTR DR                  
#>  4 2911 TURTLE CREEK BLVD                          14TH FLO… 2911 TURTLE CRK BLVD 14 TH FL         
#>  5 316 College Street                              <NA>      316 COLLEGE ST                        
#>  6 925 N. Bibb Street No. 43                       <NA>      925 N BIBB ST NO 43                   
#>  7 301 6th Avenue North, Suite 109 War Memorial B… <NA>      301 6 TH AVE N STE 109 WAR MEMORIAL B…
#>  8 2973 Crockett Street                            <NA>      2973 CROCKETT ST                      
#>  9 10604 Buccaneer Pt.                             <NA>      10604 BUCCANEER PT                    
#> 10 7694 Alameda                                    <NA>      7694 ALAMEDA
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
txe <- txe %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  txe$zip,
  txe$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na  n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl>  <dbl>  <dbl>
#> 1 zip        0.900      46457  0.0145 361371  32954
#> 2 zip_norm   0.996      16418  0.0153  14984   2376
```

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

``` r
txe <- txe %>% 
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
txe %>% 
  filter(state != state_norm) %>% 
  count(state, state_norm, sort = TRUE)
#> # A tibble: 32 x 3
#>    state state_norm     n
#>    <chr> <chr>      <int>
#>  1 Tx    TX          6420
#>  2 tx    TX           213
#>  3 Ca    CA           113
#>  4 Il    IL            34
#>  5 Mo    MO            33
#>  6 Va    VA            21
#>  7 Fl    FL            13
#>  8 Ct    CT             8
#>  9 Wi    WI             8
#> 10 Oh    OH             7
#> # … with 22 more rows
```

``` r
progress_table(
  txe$state,
  txe$state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage      prop_in n_distinct prop_na n_out n_diff
#>   <chr>        <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 state        0.998        101 0.00848  8828     43
#> 2 state_norm   1             58 0.00901     0      1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
txe <- txe %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("TX", "DC", "TEXAS"),
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
txe <- txe %>% 
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

The [OpenRefine](https://openrefine.org/) algorithms can be used to
group similar strings and replace the less common versions with their
most common counterpart. This can greatly reduce inconsistency, but with
low confidence; we will only keep any refined strings that have a valid
city/state/zip combination.

``` r
good_refine <- txe %>% 
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

    #> # A tibble: 246 x 5
    #>    state_norm zip_norm city_swap     city_refine       n
    #>    <chr>      <chr>    <chr>         <chr>         <int>
    #>  1 AZ         85072    PHENIOX       PHOENIX         125
    #>  2 IL         60197    CORAL STREAM  CAROL STREAM     74
    #>  3 CA         94105    SAN FRANSICO  SAN FRANCISCO    63
    #>  4 CA         94103    SAN FRANSCICO SAN FRANCISCO    62
    #>  5 TX         75098    WILEY         WYLIE            62
    #>  6 NM         87190    ALBURQUEQUE   ALBUQUERQUE      52
    #>  7 TX         76844    GOLDWAITHE    GOLDTHWAITE      45
    #>  8 AZ         85072    PHENOIX       PHOENIX          43
    #>  9 CA         94128    SAN FRANSICO  SAN FRANCISCO    38
    #> 10 OH         45280    CINCINATTI    CINCINNATI       27
    #> # … with 236 more rows

Then we can join the refined values back to the database.

``` r
txe <- txe %>% 
  left_join(good_refine) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

| stage        | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :----------- | -------: | ----------: | -------: | -----: | ------: |
| city\_raw)   |    0.975 |       13524 |    0.011 |  92349 |    7770 |
| city\_norm   |    0.985 |       11870 |    0.011 |  52738 |    6075 |
| city\_swap   |    0.994 |        8545 |    0.011 |  20600 |    2754 |
| city\_refine |    0.995 |        8359 |    0.011 |  19403 |    2570 |

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
txe <- txe %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  rename_all(~str_remove(., "_raw"))
```

``` r
glimpse(sample_n(txe, 20))
#> Rows: 20
#> Columns: 39
#> $ form           <chr> "COH", "COH", "COH", "PTYCORP", "MPAC", "CORCOH", "MPAC", "JCOH", "GPAC",…
#> $ schedule       <chr> "F1", "F1", "F1", "F4", "F1", "F4", "F1", "G", "F1", "F1", "F1", "F1", "F…
#> $ report_id      <chr> "100638095", "100752865", "579176", "100748312", "554986", "100620182", "…
#> $ received       <date> 2016-07-15, 2020-01-15, 2013-07-11, 2019-07-12, 2013-01-03, 2016-01-28, …
#> $ info_flag      <lgl> FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, FALSE,…
#> $ filer_id       <chr> "00051407", "00020493", "00069137", "00023868", "00028329", "00020493", "…
#> $ filer_type     <chr> "COH", "COH", "COH", "PTYCORP", "MPAC", "COH", "MPAC", "JCOH", "GPAC", "C…
#> $ filer          <chr> "Paxton Jr., W. Kenneth (The Honorable)", "Hunter, Todd A. (The Honorable…
#> $ id             <chr> "102905339", "103956686", "102520395", "103872630", "101032804", "1028125…
#> $ date           <date> 2016-05-31, 2019-08-20, 2013-06-27, 2019-05-15, 2012-11-28, 2015-10-25, …
#> $ amount         <dbl> 9.40, 500.00, 1.03, 15.23, 1000.00, 128.31, 250.00, 130.00, 99.59, 500.00…
#> $ describe       <chr> "postage for campaign mailing materials", "Reception sponsor for fundrais…
#> $ category       <chr> "OVERHEAD", "EVENT", "FEES", "OVERHEAD", "DONATIONS", "OTHER", NA, "OTHER…
#> $ description    <chr> NA, NA, NA, NA, NA, "Hotel expense", NA, "labor", NA, NA, NA, NA, NA, NA,…
#> $ itemize_flag   <lgl> TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, T…
#> $ travel_flag    <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ politics_flag  <lgl> TRUE, NA, TRUE, NA, TRUE, TRUE, TRUE, NA, TRUE, TRUE, TRUE, NA, TRUE, TRU…
#> $ reimburse_flag <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ corp_flag      <lgl> FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ liveexp_flag   <lgl> NA, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, NA, FALSE, FA…
#> $ payee_type     <chr> "ENTITY", "ENTITY", "ENTITY", "ENTITY", "ENTITY", "ENTITY", "ENTITY", "IN…
#> $ vendor         <chr> "USPS", "Texans for Greg Abbott", "PayPal", "Amazon.com", "Joe Straus Cam…
#> $ last           <chr> NA, NA, NA, NA, NA, NA, NA, "Ugalde", "STALLINGS", NA, NA, NA, "Ngo", "MA…
#> $ suffix         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ first          <chr> NA, NA, NA, NA, NA, NA, NA, "Artimeo", "LANDON", NA, NA, NA, "Vanna", "CR…
#> $ prefix         <chr> NA, NA, NA, NA, NA, NA, NA, "MR", "MR", NA, NA, NA, NA, "MR", NA, NA, NA,…
#> $ addr1          <chr> "601 Cross Timbers, Suite 118", "P.O. 308", "1840 Embarcadero Road", "120…
#> $ addr2          <chr> NA, NA, NA, "#12T", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "Suit…
#> $ city           <chr> "Flower Mound", "Austin", "Palo Alto", "Seattle", "San Antonio", "McAllen…
#> $ state          <chr> "TX", "TX", "CA", "WA", "TX", "TX", "TX", "TX", "TX", "CA", "TX", "TX", "…
#> $ zip            <chr> "75028", "78767", "94303", "98101", "78209", "78503", "77098", "75401", "…
#> $ region         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ na_flag        <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ dupe_flag      <lgl> FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ year           <dbl> 2016, 2019, 2013, 2019, 2012, 2015, 2001, 2016, 2011, 2018, 2013, 2018, 2…
#> $ addr_clean     <chr> "601 CROSS TIMBERS STE 118", "PO 308", "1840 EMBARCADERO RD", "1200 STEWA…
#> $ zip_clean      <chr> "75028", "78767", "94303", "98101", "78209", "78503", "77098", "75401", "…
#> $ state_clean    <chr> "TX", "TX", "CA", "WA", "TX", "TX", "TX", "TX", "TX", "CA", "TX", "TX", "…
#> $ city_clean     <chr> "FLOWER MOUND", "AUSTIN", "PALO ALTO", "SEATTLE", "SAN ANTONIO", "MCALLEN…
```

1.  There are 3,676,011 records in the database.
2.  There are 103,189 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 21,911 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("tx", "expends", "data", "clean"))
clean_path <- path(clean_dir, "tx_expends_clean.csv")
write_csv(txe, clean_path, na = "")
file_size(clean_path)
#> 1001M
file_encoding(clean_path) %>% 
  mutate(across(path, path.abbrev))
#> # A tibble: 1 x 3
#>   path                                         mime            charset 
#>   <chr>                                        <chr>           <chr>   
#> 1 ~/tx/expends/data/clean/tx_expends_clean.csv application/csv us-ascii
```

## Upload

Using the [duckr](https://github.com/kiernann/duckr) R package, we can
wrap around the [duck](https://duck.sh/) command line tool to upload the
file to the IRW server.

``` r
# remotes::install_github("kiernann/duckr")
s3_dir <- "s3:/publicaccountability/csv/"
s3_path <- path(s3_dir, basename(clean_path))
if (require(duckr)) {
  duckr::duck_upload(clean_path, s3_path)
}
```
