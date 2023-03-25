West Virginia Contributions
================
Kiernan Nicholls & Aarushi Sahejpal
2023-03-24 22:43:24

- <a href="#project" id="toc-project">Project</a>
- <a href="#objectives" id="toc-objectives">Objectives</a>
- <a href="#packages" id="toc-packages">Packages</a>
- <a href="#data" id="toc-data">Data</a>
- <a href="#dictionary" id="toc-dictionary">Dictionary</a>
- <a href="#download" id="toc-download">Download</a>
- <a href="#read" id="toc-read">Read</a>
- <a href="#explore" id="toc-explore">Explore</a>
- <a href="#wrangle" id="toc-wrangle">Wrangle</a>
- <a href="#conclude" id="toc-conclude">Conclude</a>
- <a href="#export" id="toc-export">Export</a>
- <a href="#upload" id="toc-upload">Upload</a>
- <a href="#dictionary-1" id="toc-dictionary-1">Dictionary</a>

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
  magrittr, # pipe operators
  janitor, # clean data frames
  batman, # parse logicals
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  rvest, # html scraping
  glue, # combine strings
  here, # relative paths
  httr2, # http requests
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
#> [1] "/Volumes/TAP/accountability_datacleaning"
```

## Data

Contributions data can be obtained in bulk from the West Virginia
Secretary of State [Campaign Finance Reporting System
(CFRS)](https://cfrs.wvsos.gov/index.html#/index). Each record contains
information on a contribution made to a candidate or committee. The CFRS
also provides a [record layout
PDF](https://cfrs.wvsos.gov/CFIS_APIService/Template/KeyDownloads/Contributions%20and%20Loans%20File%20Layout%20Key.pdf),
which we have converted to a text file.

## Dictionary

``` r
key_path <- here("wv", "contribs", "record_layout.csv")
(dict_md <- kable(read_csv(key_path)))
```

| Field Position | Field Name                          | Description                                                                                                                          |
|---------------:|:------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------|
|              1 | `ORG ID`                            | This is the unique ID of the recipient candidate or committee.                                                                       |
|              2 | `RECEIPT AMOUNT`                    | Receipt Amount                                                                                                                       |
|              3 | `RECEIPT DATE`                      | Receipt Date                                                                                                                         |
|              4 | `LAST NAME`                         | Last Name of Receipt Source, if an individual person. If not an individual, the entity full name will be in LAST NAME field.         |
|              5 | `FIRST NAME`                        | Receipt Source First Name                                                                                                            |
|              6 | `MIDDLE NAME`                       | Receipt Source Middle Initial or Name if provided.                                                                                   |
|              7 | `SUFFIX`                            | Receipt Source Name Suffix                                                                                                           |
|              8 | `ADDRESS 1`                         | Receipt Source Street, PO Box, or other directional information                                                                      |
|              9 | `ADDRESS 2`                         | Receipt Source Suite/Apartment number, or other directional information                                                              |
|             10 | `CITY`                              | Receipt Source City                                                                                                                  |
|             11 | `STATE`                             | Receipt Source State                                                                                                                 |
|             12 | `ZIP`                               | Receipt Source Zip Code                                                                                                              |
|             13 | `Description`                       | NA                                                                                                                                   |
|             14 | `RECEIPT ID`                        | This is the Receipt internal ID. This ID is unique.                                                                                  |
|             15 | `FILED DATE`                        | Receipt Filed Date                                                                                                                   |
|             16 | `RECEIPT SOURCE TYPE`               | Type of entity that is the source of the Receipt.                                                                                    |
|             17 | `AMENDED`                           | Y/N indicator to show if an amendment was filed for this record.                                                                     |
|             18 | `RECEIPT TYPE`                      | This is the Receipt Type.                                                                                                            |
|             19 | `COMMITTEE TYPE`                    | The type of Committee.                                                                                                               |
|             20 | `COMMITTEE NAME`                    | This is the name of the recipient committee.                                                                                         |
|             21 | `CANDIDATE NAME`                    | This is the name of the recipient candidate.                                                                                         |
|             22 | `EMPLOYER`                          | Receipt Source’s employer displays in cases where this information is provided. Only used for Individual contributors.               |
|             23 | `OCCUPATION`                        | The Receipt Source’s occupation in cases where this information is provided. Only used for Individual contributors .                 |
|             24 | `OCCUPATION COMMENT`                | This is the receipt source’s occupation description if ‘Other’ is chosen for the occupation. Only used for Individual contributors . |
|             25 | `FORGIVEN LOAN`                     | NA                                                                                                                                   |
|             26 | `RELATED FUNDRAISER EVENT DATE`     | Date of fundraiser event, if the contribution was related to a fundraiser.                                                           |
|             27 | `RELATED FUNDRAISER EVENT TYPE`     | Type of fundraiser event, if the contribution was related to a fundraiser.                                                           |
|             28 | `RELATED FUNDRAISER PLACE OF EVENT` | Name of venue or location where the fundraiser event took place, if the contribution was related to a fundraiser.                    |
|             29 | `REPORT NAME`                       | Indicates Name of the Report                                                                                                         |
|             30 | `CONTRIBUTION TYPE`                 | Indicates Type of Contribution                                                                                                       |

``` r
write_lines(
  x = c("# West Virginia Contracts Data Dictionary\n", dict_md),
  file = here("wv", "contribs", "wv_contribs_dict.md"),
)
```

## Download

The files can be downloaded with an `httr::GET()` request to the CFRS
server.

``` r
raw_dir <- dir_create(here("wv", "contribs", "data", "raw"))
wv_api <- "https://cfrs.wvsos.gov/CFIS_APIService/api"
```

``` r
wv_ls <- request("https://cfrs.wvsos.gov/CFIS_APIService/api/") %>% 
  req_url_path_append("DataDownload", "GetCheckDatadownload") %>% 
  req_url_query(pageNumber = 1, pageSize = 50) %>% 
  req_perform() %>% 
  resp_body_json(
    check_type = FALSE,
    simplifyDataFrame = TRUE
  )
```

| TransactionKey          | ElectionYear | NameOfFile     | TransactionType |
|:------------------------|-------------:|:---------------|:----------------|
| Contributions and Loans |         2023 | `CON_2023.csv` | CON             |
| Expenditures            |         2023 | `EXP_2023.csv` | EXP             |
| Expenditures            |         2022 | `EXP_2022.csv` | EXP             |
| Contributions and Loans |         2022 | `CON_2022.csv` | CON             |
| Contributions and Loans |         2021 | `CON_2021.csv` | CON             |
| Expenditures            |         2021 | `EXP_2021.csv` | EXP             |
| Expenditures            |         2020 | `EXP_2020.csv` | EXP             |
| Contributions and Loans |         2020 | `CON_2020.csv` | CON             |
| Contributions and Loans |         2019 | `CON_2019.csv` | CON             |
| Expenditures            |         2019 | `EXP_2019.csv` | EXP             |
| Expenditures            |         2018 | `EXP_2018.csv` | EXP             |
| Contributions and Loans |         2018 | `CON_2018.csv` | CON             |

``` r
wv_ls <- wv_ls %>% 
  filter(TransactionType == "CON") %>% 
  mutate(FilePath = path(raw_dir, NameOfFile))
```

``` r
for (i in seq(nrow(wv_ls))) {
  message(wv_ls$NameOfFile[i])
  if (!file_exists(wv_ls$FilePath[i])) {
    request("https://cfrs.wvsos.gov/CFIS_APIService/api/") %>% 
      req_url_path_append("DataDownload", "GetCSVDownloadReport") %>% 
      req_url_query(
        year = wv_ls$ElectionYear[i],
        transactionType = wv_ls$TransactionType[i],
        reportFormat = "csv",
        fileName = wv_ls$NameOfFile[i]
      ) %>% 
      req_perform(path = wv_ls$FilePath[i])
  }
}
```

    #> # A tibble: 6 × 3
    #>   path                size modification_time  
    #>   <chr>        <fs::bytes> <dttm>             
    #> 1 CON_2023.csv       1.33M 2023-03-24 22:29:27
    #> 2 CON_2022.csv      10.85M 2023-03-24 22:29:34
    #> 3 CON_2021.csv       4.32M 2023-03-24 22:29:36
    #> 4 CON_2020.csv      13.99M 2023-03-24 22:29:45
    #> 5 CON_2019.csv       4.26M 2023-03-24 22:29:48
    #> 6 CON_2018.csv        8.4M 2023-03-24 22:29:54

## Read

While character columns are wrapped in double-quotes (`"`), any
double-quotes *within* those columns are not escaped in any way. We will
have to use regular expressions to replace them with single-quotes
(`'`).

``` r
fix_csv <- path_temp(basename(raw_csv))
for (i in seq_along(raw_csv)) {
  read_lines(raw_csv[i]) %>% 
    str_replace("Report$", "Report,") %>% 
    str_replace_all(",\"([A-z\\. ]+)\"[^,|\"]*", ",'\\1'") %>% 
    str_replace_all("\\s\"([A-z\\. ]+)\"[^,|\"]*", " '\\1'") %>% 
    str_replace_all("(?<!^|,)\"(?!,|$)", r"("""")") %>% 
    write_lines(fix_csv[i])
}
```

The fixed text files can be read into a single data frame.

``` r
wvc <- read_delim(
  file = fix_csv,
  delim = ",",
  escape_backslash = FALSE, 
  escape_double = TRUE,
  na = c("", " "),
  col_types = cols(
    .default = col_character(),
    `Receipt Amount` = col_double(),
    `Receipt Date` = col_date("%m/%d/%Y %H:%M:%S %p"),
    `Filed Date` = col_datetime("%m/%d/%Y %H:%M:%S %p"),
    `Fundraiser Event Date` = col_datetime("%m/%d/%Y %H:%M:%S %p")
  )
)
```

``` r
problems(wvc)
#> # A tibble: 42 × 5
#>      row   col expected                       actual     file                                      
#>    <int> <int> <chr>                          <chr>      <chr>                                     
#>  1 21326    15 date like %m/%d/%Y %H:%M:%S %p Individual /private/var/folders/kn/rwt3lmvn7gs3vl38b…
#>  2 21326    29 30 columns                     29 columns /private/var/folders/kn/rwt3lmvn7gs3vl38b…
#>  3 23094    29 30 columns                     29 columns /private/var/folders/kn/rwt3lmvn7gs3vl38b…
#>  4 27816    29 30 columns                     29 columns /private/var/folders/kn/rwt3lmvn7gs3vl38b…
#>  5 29495    29 30 columns                     29 columns /private/var/folders/kn/rwt3lmvn7gs3vl38b…
#>  6 30378    29 30 columns                     29 columns /private/var/folders/kn/rwt3lmvn7gs3vl38b…
#>  7 31904    29 30 columns                     29 columns /private/var/folders/kn/rwt3lmvn7gs3vl38b…
#>  8 32469    29 30 columns                     29 columns /private/var/folders/kn/rwt3lmvn7gs3vl38b…
#>  9 33466    29 30 columns                     29 columns /private/var/folders/kn/rwt3lmvn7gs3vl38b…
#> 10 33475    29 30 columns                     29 columns /private/var/folders/kn/rwt3lmvn7gs3vl38b…
#> # … with 32 more rows
```

Column names can be converted to snake case and simplified.

``` r
wvc <- wvc %>% 
  clean_names("snake") %>% 
  mutate(across(c(amended, occupation_comment), to_logical))
```

We can check whether the files were properly read by counting the number
of distinct values in a discrete variable like the `contribution_type`.

``` r
count(wvc, contribution_type)
#> # A tibble: 5 × 2
#>   contribution_type                        n
#>   <chr>                                <int>
#> 1 In-Kind                               4865
#> 2 Monetary                            179328
#> 3 Other Income                          2058
#> 4 Receipt of Transfer of Excess Funds    711
#> 5 <NA>                                  1163
```

## Explore

``` r
glimpse(wvc)
#> Rows: 188,125
#> Columns: 30
#> $ org_id                 <chr> "24", "24", "24", "95", "95", "95", "95", "144", "149", "1181", "1…
#> $ receipt_amount         <dbl> 1.92, 1.99, 2.09, 0.01, 0.05, 0.05, 0.05, 500.00, 2414.80, 10.00, …
#> $ receipt_date           <date> 2022-11-30, 2022-12-31, 2022-10-31, 2022-11-25, 2022-10-05, 2022-…
#> $ last_name              <chr> "WVCCU", "WVCCU", "WVCCU", "First Exchange Bank", "First Exchange …
#> $ first_name             <chr> NA, NA, NA, NA, NA, NA, NA, NA, "Jason", NA, NA, "Lisa", "Teri", "…
#> $ middle_name            <chr> NA, NA, NA, NA, NA, NA, NA, NA, "A.", NA, NA, NA, NA, NA, NA, NA, …
#> $ suffix                 <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ address1               <chr> "1306 Murdoch Ave", "1306 Murdoch Ave", "1306 Murdoch Ave", "11 We…
#> $ address2               <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ city                   <chr> "Parkersburg", "Parkersburg", "Parkersburg", "Mannington", "Mannin…
#> $ state                  <chr> "WV", "WV", "WV", "WV", "WV", "WV", "WV", "ME", "WV", "WV", "WV", …
#> $ zip                    <chr> "26101", "26101", "26101", "26582", "26582", "26582", "26582", NA,…
#> $ description            <chr> "Interest", "Interest", "Interest", "Interest on Checking Account"…
#> $ receipt_id             <chr> "442380", "442381", "442378", "418044", "406541", "417752", "41804…
#> $ filed_date             <dttm> 2023-01-06 14:35:15, 2023-01-06 14:35:15, 2023-01-06 14:35:15, 20…
#> $ receipt_source_type    <chr> "Business or Organization", "Business or Organization", "Business …
#> $ amended                <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ receipt_type           <chr> "Contributions", "Contributions", "Contributions", "Contributions"…
#> $ committee_type         <chr> "State Candidate", "State Candidate", "State Candidate", "State Ca…
#> $ committee_name         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ candidate_name         <chr> "Lissa Lucas", "Lissa Lucas", "Lissa Lucas", "David Pethtel", "Dav…
#> $ employer               <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "retired", NA,…
#> $ occupation             <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ occupation_comment     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ forgiven_loan          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ fundraiser_event_date  <dttm> NA, NA, NA, NA, NA, NA, NA, NA, NA, 2022-11-11 05:00:00, 2022-11-…
#> $ fundraiser_event_type  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "Eisenhower Dinner", "Eisenhow…
#> $ fundraiser_event_place <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "Eisenhower Dinner 2022", "Eis…
#> $ report_name            <chr> "2022 4th Quarter Report", "2022 4th Quarter Report", "2022 4th Qu…
#> $ contribution_type      <chr> "Other Income", "Other Income", "Other Income", "Other Income", "O…
tail(wvc)
#> # A tibble: 6 × 30
#>   org_id receipt_amount receipt_…¹ last_…² first…³ middl…⁴ suffix addre…⁵ addre…⁶ city  state zip  
#>   <chr>           <dbl> <date>     <chr>   <chr>   <chr>   <chr>  <chr>   <chr>   <chr> <chr> <chr>
#> 1 40776            500  2018-11-05 Coca-C… <NA>    <NA>    <NA>   4100 C… <NA>    Char… NC    28711
#> 2 40776           1000  2018-11-01 Adams   Richard <NA>    <NA>   53 Mea… <NA>    Park… WV    26101
#> 3 40776           1200  2018-10-30 Azinger Thomas  Albert  <NA>   1310 7… <NA>    Vien… WV    26105
#> 4 40776           2300  2018-10-18 Azinger Thomas  Albert  <NA>   1310 7… <NA>    Vien… WV    26105
#> 5 42375           4778. 2018-12-12 Roger … <NA>    <NA>    <NA>   331 To… <NA>    Morg… WV    26508
#> 6 42375           5000  2016-07-16 Roger … <NA>    <NA>    <NA>   331 To… <NA>    Morg… WV    26508
#> # … with 18 more variables: description <chr>, receipt_id <chr>, filed_date <dttm>,
#> #   receipt_source_type <chr>, amended <lgl>, receipt_type <chr>, committee_type <chr>,
#> #   committee_name <chr>, candidate_name <chr>, employer <chr>, occupation <chr>,
#> #   occupation_comment <lgl>, forgiven_loan <chr>, fundraiser_event_date <dttm>,
#> #   fundraiser_event_type <chr>, fundraiser_event_place <chr>, report_name <chr>,
#> #   contribution_type <chr>, and abbreviated variable names ¹​receipt_date, ²​last_name,
#> #   ³​first_name, ⁴​middle_name, ⁵​address1, ⁶​address2
```

### Missing

Columns range in their degree of missing values.

``` r
col_stats(wvc, count_na)
#> # A tibble: 30 × 4
#>    col                    class       n         p
#>    <chr>                  <chr>   <int>     <dbl>
#>  1 org_id                 <chr>       0 0        
#>  2 receipt_amount         <dbl>       0 0        
#>  3 receipt_date           <date>      0 0        
#>  4 last_name              <chr>    5340 0.0284   
#>  5 first_name             <chr>   25846 0.137    
#>  6 middle_name            <chr>  162433 0.863    
#>  7 suffix                 <chr>  185032 0.984    
#>  8 address1               <chr>   89544 0.476    
#>  9 address2               <chr>  183847 0.977    
#> 10 city                   <chr>   88565 0.471    
#> 11 state                  <chr>       0 0        
#> 12 zip                    <chr>   89248 0.474    
#> 13 description            <chr>  180282 0.958    
#> 14 receipt_id             <chr>       0 0        
#> 15 filed_date             <dttm>      2 0.0000106
#> 16 receipt_source_type    <chr>       0 0        
#> 17 amended                <lgl>       2 0.0000106
#> 18 receipt_type           <chr>       0 0        
#> 19 committee_type         <chr>       2 0.0000106
#> 20 committee_name         <chr>  188125 1        
#> 21 candidate_name         <chr>   61572 0.327    
#> 22 employer               <chr>  105135 0.559    
#> 23 occupation             <chr>  114727 0.610    
#> 24 occupation_comment     <lgl>       2 0.0000106
#> 25 forgiven_loan          <chr>  188125 1        
#> 26 fundraiser_event_date  <dttm> 156110 0.830    
#> 27 fundraiser_event_type  <chr>  156273 0.831    
#> 28 fundraiser_event_place <chr>  156108 0.830    
#> 29 report_name            <chr>       0 0        
#> 30 contribution_type      <chr>    1163 0.00618
```

We should flag any record missing a key variable, those needed to
identify a transaction and all parties, with `campfin::flag_na()`.

After combining these rows, we have no records missing key variables.

``` r
key_vars <- c("receipt_date", "last_name", "receipt_amount", "candidate_name")
```

``` r
wvc <- flag_na(wvc, all_of(key_vars))
mean(wvc$na_flag)
#> [1] 0.3525581
```

### Duplicates

We can also flag records that are entirely duplicated across every row,
save for the supposedly unique `id`.

``` r
wvc <- flag_dupes(wvc, -receipt_id)
percent(mean(wvc$dupe_flag), 0.01)
#> [1] "3.96%"
```

``` r
wvc %>% 
  filter(dupe_flag) %>% 
  select(all_of(key_vars)) %>% 
  arrange(receipt_date)
#> # A tibble: 7,459 × 4
#>    receipt_date last_name         receipt_amount candidate_name
#>    <date>       <chr>                      <dbl> <chr>         
#>  1 2017-04-04   Douglas  McKinney            100 <NA>          
#>  2 2017-04-04   Douglas  McKinney            100 <NA>          
#>  3 2017-04-10   Trickett                     100 <NA>          
#>  4 2017-04-10   Trickett                     100 <NA>          
#>  5 2017-04-23   Totten                        25 <NA>          
#>  6 2017-04-23   Totten                        25 <NA>          
#>  7 2017-07-18   Floyd                          5 <NA>          
#>  8 2017-07-18   Floyd                          5 <NA>          
#>  9 2017-08-21   Tarr                        1000 Ryan Ferns    
#> 10 2017-08-21   Tarr                        1000 Ryan Ferns    
#> # … with 7,449 more rows
```

### Categorical

``` r
col_stats(wvc, n_distinct)
#> # A tibble: 32 × 4
#>    col                    class       n          p
#>    <chr>                  <chr>   <int>      <dbl>
#>  1 org_id                 <chr>    1471 0.00782   
#>  2 receipt_amount         <dbl>    6758 0.0359    
#>  3 receipt_date           <date>   2128 0.0113    
#>  4 last_name              <chr>   34228 0.182     
#>  5 first_name             <chr>    8629 0.0459    
#>  6 middle_name            <chr>    1012 0.00538   
#>  7 suffix                 <chr>       9 0.0000478 
#>  8 address1               <chr>   32596 0.173     
#>  9 address2               <chr>     890 0.00473   
#> 10 city                   <chr>    4043 0.0215    
#> 11 state                  <chr>      74 0.000393  
#> 12 zip                    <chr>    5411 0.0288    
#> 13 description            <chr>    3287 0.0175    
#> 14 receipt_id             <chr>  188124 1.00      
#> 15 filed_date             <dttm>   9668 0.0514    
#> 16 receipt_source_type    <chr>       8 0.0000425 
#> 17 amended                <lgl>       2 0.0000106 
#> 18 receipt_type           <chr>       5 0.0000266 
#> 19 committee_type         <chr>       5 0.0000266 
#> 20 committee_name         <chr>       1 0.00000532
#> 21 candidate_name         <chr>     881 0.00468   
#> 22 employer               <chr>   12690 0.0675    
#> 23 occupation             <chr>      35 0.000186  
#> 24 occupation_comment     <lgl>       2 0.0000106 
#> 25 forgiven_loan          <chr>       1 0.00000532
#> 26 fundraiser_event_date  <dttm>    830 0.00441   
#> 27 fundraiser_event_type  <chr>     408 0.00217   
#> 28 fundraiser_event_place <chr>    1182 0.00628   
#> 29 report_name            <chr>      81 0.000431  
#> 30 contribution_type      <chr>       5 0.0000266 
#> 31 na_flag                <lgl>       2 0.0000106 
#> 32 dupe_flag              <lgl>       2 0.0000106
```

![](../plots/distinct_plot-1.png)<!-- -->![](../plots/distinct_plot-2.png)<!-- -->![](../plots/distinct_plot-3.png)<!-- -->![](../plots/distinct_plot-4.png)<!-- -->![](../plots/distinct_plot-5.png)<!-- -->

### Amounts

``` r
wvc$receipt_amount <- round(wvc$receipt_amount, digits = 2)
```

The range of contribution amounts seems reasonable.

``` r
noquote(map_chr(summary(wvc$receipt_amount), dollar))
#>       Min.    1st Qu.     Median       Mean    3rd Qu.       Max. 
#>      $0.01        $20        $50    $506.45       $250 $1,000,000
sum(wvc$receipt_amount <= 0.01)
#> [1] 112
```

Here is the largest contribution of \$1,000,000:

``` r
glimpse(wvc[which.max(wvc$receipt_amount), ])
#> Rows: 1
#> Columns: 32
#> $ org_id                 <chr> "26155"
#> $ receipt_amount         <dbl> 1e+06
#> $ receipt_date           <date> 2020-07-06
#> $ last_name              <chr> "WV State Building & Construction Trades Council"
#> $ first_name             <chr> NA
#> $ middle_name            <chr> NA
#> $ suffix                 <chr> NA
#> $ address1               <chr> "600 Leon Sullivan Way"
#> $ address2               <chr> NA
#> $ city                   <chr> "Charleston"
#> $ state                  <chr> "WV"
#> $ zip                    <chr> "25301"
#> $ description            <chr> NA
#> $ receipt_id             <chr> "253475"
#> $ filed_date             <dttm> 2020-10-07 09:18:16
#> $ receipt_source_type    <chr> "Business or Organization"
#> $ amended                <lgl> FALSE
#> $ receipt_type           <chr> "Contributions"
#> $ committee_type         <chr> "Independent Expenditure Committee"
#> $ committee_name         <chr> NA
#> $ candidate_name         <chr> NA
#> $ employer               <chr> NA
#> $ occupation             <chr> NA
#> $ occupation_comment     <lgl> FALSE
#> $ forgiven_loan          <chr> NA
#> $ fundraiser_event_date  <dttm> NA
#> $ fundraiser_event_type  <chr> NA
#> $ fundraiser_event_place <chr> NA
#> $ report_name            <chr> "2020 3rd Quarter Report"
#> $ contribution_type      <chr> "Monetary"
#> $ na_flag                <lgl> TRUE
#> $ dupe_flag              <lgl> FALSE
```

![](../plots/hist_amount-1.png)<!-- -->

### Dates

We can add the calendar year from `receipt_date` with
`lubridate::year()`

``` r
wvc <- mutate(wvc, receipt_year = year(receipt_date))
```

The range of dates is completely normal.

``` r
min(wvc$receipt_date)
#> [1] "2016-03-01"
sum(wvc$receipt_year < 2016)
#> [1] 0
max(wvc$receipt_date)
#> [1] "2023-02-14"
sum(wvc$receipt_date > today())
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
addr_norm <- wvc %>%
  distinct(address1) %>% 
  mutate(
    norm_address1 = normal_address(
      address = address1,
      abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  unite(
    col = address_norm,
    starts_with("norm_address"),
    sep = " ",
    remove = TRUE,
    na.rm = TRUE
  ) %>% 
  mutate(across(address_norm, na_if, ""))
```

``` r
sample_n(addr_norm, 10)
#> # A tibble: 10 × 2
#>    address1              address_norm      
#>    <chr>                 <chr>             
#>  1 405 N. Capitol St     405 N CAPITOL ST  
#>  2 713 Brightridge Drive 713 BRIGHTRIDGE DR
#>  3 1014 3rd Street West  1014 3RD STREET W 
#>  4 116 Tazewell ST       116 TAZEWELL ST   
#>  5 2003 Park Ave         2003 PARK AVE     
#>  6 3316 Nina V Lane      3316 NINA V LN    
#>  7 104 Putnam Court      104 PUTNAM CT     
#>  8 832 Broadway          832 BROADWAY      
#>  9 104 Creekside Ct      104 CREEKSIDE CT  
#> 10 P.O.Box 6266          POBOX 6266
```

``` r
wvc <- left_join(wvc, addr_norm)
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
wvc <- wvc %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  wvc$zip,
  wvc$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 × 6
#>   stage        prop_in n_distinct prop_na n_out n_diff
#>   <chr>          <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 wvc$zip        0.970       5411   0.474  2967   1067
#> 2 wvc$zip_norm   0.996       4603   0.474   374    193
```

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

``` r
wvc <- wvc %>% 
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
wvc %>% 
  filter(state != state_norm) %>% 
  count(state, state_norm, sort = TRUE)
#> # A tibble: 20 × 3
#>    state state_norm     n
#>    <chr> <chr>      <int>
#>  1 wv    WV           591
#>  2 Wv    WV            68
#>  3 dc    DC            47
#>  4 wV    WV            38
#>  5 tx    TX            31
#>  6 ca    CA            21
#>  7 ky    KY            18
#>  8 mA    MA             9
#>  9 ny    NY             8
#> 10 ma    MA             6
#> 11 oh    OH             4
#> 12 vA    VA             4
#> 13 md    MD             3
#> 14 Ok    OK             3
#> 15 co    CO             2
#> 16 in    IN             2
#> 17 va    VA             2
#> 18 il    IL             1
#> 19 nC    NC             1
#> 20 Va    VA             1
```

``` r
progress_table(
  wvc$state,
  wvc$state_norm,
  compare = valid_state
)
#> # A tibble: 2 × 6
#>   stage          prop_in n_distinct   prop_na n_out n_diff
#>   <chr>            <dbl>      <dbl>     <dbl> <dbl>  <dbl>
#> 1 wvc$state        0.995         74 0           863     22
#> 2 wvc$state_norm   1             53 0.0000159     0      1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
norm_city <- wvc %>% 
  distinct(city, state_norm, zip_norm) %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("WV", "DC", "WEST VIRGINIA"),
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
wvc <- left_join(
  x = wvc,
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
good_refine <- wvc %>% 
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

    #> # A tibble: 18 × 5
    #>    state_norm zip_norm city_swap          city_refine           n
    #>    <chr>      <chr>    <chr>              <chr>             <int>
    #>  1 WV         25303    SO CHARLESTON      CHARLESTON           16
    #>  2 OH         45237    CINCINATTI         CINCINNATI           11
    #>  3 WV         26845    OIL FIELDS         OLD FIELDS            7
    #>  4 WV         25311    EAST CHARLESTON    CHARLESTON            6
    #>  5 WV         25309    SO CHARLESTON      CHARLESTON            4
    #>  6 WV         26416    PHILLIPI           PHILIPPI              4
    #>  7 WV         25301    EAST CHARLESTON    CHARLESTON            3
    #>  8 CA         90272    PACIFIC PALLASADES PACIFIC PALISADES     2
    #>  9 CA         94118    SAN FRANSCISO      SAN FRANCISCO         2
    #> 10 WV         25719    HUNGINTON          HUNTINGTON            2
    #> 11 NC         28231    CHAROLETTE         CHARLOTTE             1
    #> 12 WV         24970    RONCERVERT         RONCEVERTE            1
    #> 13 WV         25414    CHARLESTON TOWN    CHARLES TOWN          1
    #> 14 WV         25420    GERRARDSTOWN RD    GERRARDSTOWN          1
    #> 15 WV         25701    HUNGINTON          HUNTINGTON            1
    #> 16 WV         25826    CORRINE            CORINNE               1
    #> 17 WV         26187    WILLIAMSOTN        WILLIAMSTOWN          1
    #> 18 WV         26501    MORGNTANTOWN       MORGANTOWN            1

Then we can join the refined values back to the database.

``` r
wvc <- wvc %>% 
  left_join(good_refine) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

Our goal for normalization was to increase the proportion of city values
known to be valid and reduce the total distinct values by correcting
misspellings.

| stage                    | prop_in | n_distinct | prop_na | n_out | n_diff |
|:-------------------------|--------:|-----------:|--------:|------:|-------:|
| `str_to_upper(wvc$city)` |   0.965 |       3557 |   0.471 |  3514 |    933 |
| `wvc$city_norm`          |   0.975 |       3394 |   0.471 |  2491 |    757 |
| `wvc$city_swap`          |   0.994 |       2885 |   0.471 |   550 |    240 |
| `wvc$city_refine`        |   0.995 |       2870 |   0.471 |   494 |    226 |

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
wvc <- wvc %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  rename_all(~str_remove(., "_raw")) %>% 
  relocate(address_clean, city_clean, state_clean, .before = zip_clean)
```

## Conclude

``` r
glimpse(sample_n(wvc, 50))
#> Rows: 50
#> Columns: 37
#> $ org_id                 <chr> "143", "352", "1893", "1889", "136045", "25799", "42091", "25627",…
#> $ receipt_amount         <dbl> 200.0, 500.0, 5.0, 200.0, 100.0, 50.0, 100.0, 577.0, 25.0, 3.0, 10…
#> $ receipt_date           <date> 2018-02-08, 2018-10-17, 2020-08-27, 2020-11-30, 2022-02-09, 2019-…
#> $ last_name              <chr> "Karlin", "Jackson Co Democratic Exec Comm", "Ward", "Sims", "K Oq…
#> $ first_name             <chr> "Allan", NA, "Glen", "David", "Joyce", "Erica", "Edward", NA, "W",…
#> $ middle_name            <chr> NA, NA, NA, "A.", NA, NA, NA, NA, "Jefferson", NA, "P.", NA, NA, N…
#> $ suffix                 <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ address1               <chr> "41 Wilson Ave.", NA, "407 Keeney Mountain Rd.", "P. O. Box 5349",…
#> $ address2               <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ city                   <chr> "Morgantown", "Ripley", "Sandstone", "Vienna", NA, NA, "Washington…
#> $ state                  <chr> "WV", "WV", "WV", "WV", "ME", "ME", "DC", "WV", "NC", "ME", "ME", …
#> $ zip                    <chr> "26501", "25271", "25985-9249", "26105", NA, "91011", "20016", "25…
#> $ description            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ receipt_id             <chr> "14684", "89705", "252266", "297644", "348333", "124054", "265650"…
#> $ filed_date             <dttm> 2018-04-05 00:00:00, 2018-10-29 11:34:35, 2020-10-07 10:31:13, 20…
#> $ receipt_source_type    <chr> "Individual", "Business or Organization", "Individual", "Individua…
#> $ amended                <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ receipt_type           <chr> "Contributions", "Contributions", "Contributions", "Contributions"…
#> $ committee_type         <chr> "State Candidate", "State Candidate", "State Political Action Comm…
#> $ committee_name         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ candidate_name         <chr> "Mike Caputo", "Missy Sue Morris", NA, NA, "Sydnee Smirl McElroy",…
#> $ employer               <chr> NA, NA, NA, "Law Offices of David A. Sims", NA, NA, "E.M Rahal and…
#> $ occupation             <chr> NA, NA, NA, "Attorney/Legal", NA, NA, "Other", NA, NA, "General Bu…
#> $ occupation_comment     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ forgiven_loan          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ fundraiser_event_date  <dttm> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ fundraiser_event_type  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ fundraiser_event_place <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ report_name            <chr> "2018 Precandidate Annual Report", "Pre-General Report", "2020 3rd…
#> $ contribution_type      <chr> "Monetary", "Monetary", "Monetary", "Monetary", "Monetary", "Monet…
#> $ na_flag                <lgl> FALSE, FALSE, TRUE, TRUE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, T…
#> $ dupe_flag              <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ receipt_year           <dbl> 2018, 2018, 2020, 2020, 2022, 2019, 2020, 2021, 2020, 2022, 2019, …
#> $ address_clean          <chr> "41 WILSON AVE", NA, "407 KEENEY MOUNTAIN RD", "PO BOX 5349", NA, …
#> $ city_clean             <chr> "MORGANTOWN", "RIPLEY", "SANDSTONE", "VIENNA", NA, NA, "WASHINGTON…
#> $ state_clean            <chr> "WV", "WV", "WV", "WV", "ME", "ME", "DC", "WV", "NC", "ME", "ME", …
#> $ zip_clean              <chr> "26501", "25271", "25985", "26105", NA, "91011", "20016", "25311",…
```

1.  There are 188,125 records in the database.
2.  There are 7,459 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 66,325 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("wv", "contribs", "data", "clean"))
clean_path <- path(clean_dir, "wv_contribs_20160301-2023.csv")
write_csv(wvc, clean_path, na = "")
(clean_size <- file_size(clean_path))
#> 47.3M
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

## Dictionary

The following table describes the variables in our final exported file:

| Column                   | Type        | Definition |
|:-------------------------|:------------|:-----------|
| `org_id`                 | `character` |            |
| `receipt_amount`         | `double`    |            |
| `receipt_date`           | `double`    |            |
| `last_name`              | `character` |            |
| `first_name`             | `character` |            |
| `middle_name`            | `character` |            |
| `suffix`                 | `character` |            |
| `address1`               | `character` |            |
| `address2`               | `character` |            |
| `city`                   | `character` |            |
| `state`                  | `character` |            |
| `zip`                    | `character` |            |
| `description`            | `character` |            |
| `receipt_id`             | `character` |            |
| `filed_date`             | `double`    |            |
| `receipt_source_type`    | `character` |            |
| `amended`                | `logical`   |            |
| `receipt_type`           | `character` |            |
| `committee_type`         | `character` |            |
| `committee_name`         | `character` |            |
| `candidate_name`         | `character` |            |
| `employer`               | `character` |            |
| `occupation`             | `character` |            |
| `occupation_comment`     | `logical`   |            |
| `forgiven_loan`          | `character` |            |
| `fundraiser_event_date`  | `double`    |            |
| `fundraiser_event_type`  | `character` |            |
| `fundraiser_event_place` | `character` |            |
| `report_name`            | `character` |            |
| `contribution_type`      | `character` |            |
| `na_flag`                | `logical`   |            |
| `dupe_flag`              | `logical`   |            |
| `receipt_year`           | `double`    |            |
| `address_clean`          | `character` |            |
| `city_clean`             | `character` |            |
| `state_clean`            | `character` |            |
| `zip_clean`              | `character` |            |
