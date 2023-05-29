Hawaii Contributions
================
Kiernan Nicholls & Aarushi Sahejpal
Mon May 29 11:16:25 2023

- <a href="#project" id="toc-project">Project</a>
- <a href="#objectives" id="toc-objectives">Objectives</a>
- <a href="#packages" id="toc-packages">Packages</a>
- <a href="#data" id="toc-data">Data</a>
- <a href="#download" id="toc-download">Download</a>
- <a href="#read" id="toc-read">Read</a>
- <a href="#explore" id="toc-explore">Explore</a>
  - <a href="#missing" id="toc-missing">Missing</a>
  - <a href="#duplicates" id="toc-duplicates">Duplicates</a>
  - <a href="#categorical" id="toc-categorical">Categorical</a>
  - <a href="#amounts" id="toc-amounts">Amounts</a>
  - <a href="#dates" id="toc-dates">Dates</a>
- <a href="#wrangle" id="toc-wrangle">Wrangle</a>
  - <a href="#address" id="toc-address">Address</a>
  - <a href="#zip" id="toc-zip">ZIP</a>
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
  jsonlite, # parse json data
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
here::i_am("hi/contribs/docs/hi_contribs_diary.Rmd")
```

## Data

Data is obtained from the [Hawaii Campaign Spending
Commission](https://ags.hawaii.gov/campaign/) (CSC). The file can be
found on the \[Hawaii Open Data portal\]\[odp\]. There are two files,
one contributions received by Candidate committees and one for
Non-candidate committees. In both files, each record represents a
campaign contribution made from an individual, political party, or some
other entity.

``` r
cand_about <- fromJSON("https://hicscdata.hawaii.gov/api/views/jexd-xbcg")
comm_about <- fromJSON("https://hicscdata.hawaii.gov/api/views/rajm-32md")
```

``` r
as_datetime(cand_about$createdAt)
#> [1] "2012-10-09 01:25:57 UTC"
as_datetime(cand_about$publicationDate)
#> [1] "2020-05-01 23:12:08 UTC"
as_datetime(cand_about$rowsUpdatedAt)
#> [1] "2023-02-07 20:45:03 UTC"
```

| fieldName                     | name                     | dataTypeName  |
|:------------------------------|:-------------------------|:--------------|
| `candidate_name`              | Candidate Name           | text          |
| `contributor_type`            | Contributor Type         | text          |
| `contributor_name`            | Contributor Name         | text          |
| `date`                        | Date                     | calendar_date |
| `amount`                      | Amount                   | number        |
| `aggregate`                   | Aggregate                | number        |
| `employer`                    | Employer                 | text          |
| `occupation`                  | Occupation               | text          |
| `street_address_1`            | Address 1                | text          |
| `street_address_2`            | Address 2                | text          |
| `city`                        | City                     | text          |
| `state`                       | State                    | text          |
| `zip_code`                    | Zip Code                 | text          |
| `non_resident_yes_or_no_`     | Non-Resident (Yes or No) | text          |
| `non_monetary_yes_or_no`      | Non-Monetary (Yes or No) | text          |
| `non_monetary_category`       | Non-Monetary Category    | text          |
| `non_monetary_description`    | Non-Monetary Description | text          |
| `office`                      | Office                   | text          |
| `district`                    | District                 | text          |
| `county`                      | County                   | text          |
| `party`                       | Party                    | text          |
| `reg_no`                      | Reg No                   | text          |
| `election_period`             | Election Period          | text          |
| `mapping_address`             | Mapping Location         | location      |
| `inoutstate`                  | InOutState               | text          |
| `range`                       | Range                    | text          |
| `:@computed_region_xpdz_s4v8` | Counties                 | number        |

| fieldName                     | name                        | dataTypeName  |
|:------------------------------|:----------------------------|:--------------|
| `noncandidate_committee_name` | Noncandidate Committee Name | text          |
| `contributor_type`            | Contributor Type            | text          |
| `contributor_name`            | Contributor Name            | text          |
| `date`                        | Date                        | calendar_date |
| `amount`                      | Amount                      | number        |
| `aggregate`                   | Aggregate                   | number        |
| `employer`                    | Employer                    | text          |
| `occupation`                  | Occupation                  | text          |
| `address_1`                   | Address 1                   | text          |
| `address_2`                   | Address 2                   | text          |
| `city`                        | City                        | text          |
| `state`                       | State                       | text          |
| `zip_code`                    | Zip Code                    | text          |
| `non_monetary_yes_or_no`      | Non-Monetary (Yes or No)    | text          |
| `non_monetary_category`       | Non-Monetary Category       | text          |
| `non_monetary_description`    | Non-Monetary Description    | text          |
| `reg_no`                      | Reg No                      | text          |
| `election_period`             | Election Period             | text          |
| `location_1`                  | Mapping Location            | location      |
| `:@computed_region_xpdz_s4v8` | Counties                    | number        |

## Download

``` r
raw_dir <- dir_create(here("hi", "contribs", "data", "raw"))
cand_csv <- path(raw_dir, "jexd-xbcg.tsv")
comm_csv <- path(raw_dir, "rajm-32md.tsv")
```

``` r
if (!file_exists(cand_csv)) {
  cand_get <- GET(
    url = "https://hicscdata.hawaii.gov/api/views/jexd-xbcg/rows.tsv",
    query = list(accessType = "DOWNLOAD"),
    write_disk(path = cand_csv),
    progress(type = "down")
  )
}
```

``` r
if (!file_exists(comm_csv)) {
  comm_get <- GET(
    url = "https://hicscdata.hawaii.gov/api/views/rajm-32md/rows.tsv",
    query = list(accessType = "DOWNLOAD"),
    write_disk(path = comm_csv),
    progress(type = "down")
  )
}
```

``` r
raw_tsv <- dir_ls(raw_dir, glob = "*.tsv")
```

## Read

Each file can be ready using the column names from their metadata files.
Both files have overlapping columns with some slightly different names.
Some work can be done to match the names across both files.

``` r
cand_names <- cand_about$columns$fieldName
comm_names <- comm_about$columns$fieldName
```

``` r
cand_names <- cand_names[-length(cand_names)]
comm_names <- comm_names[-length(comm_names)]
```

``` r
cand_names <- str_remove(cand_names, "^street_(?=address)")
cand_names[cand_names == "non_resident_yes_or_no_"] <- "non_resident_yes_or_no"
```

``` r
setdiff(comm_names, cand_names)
#> [1] "noncandidate_committee_name" "location_1"
setdiff(cand_names, comm_names)
#> [1] "candidate_name"         "non_resident_yes_or_no" "office"                 "district"              
#> [5] "county"                 "party"                  "mapping_address"        "inoutstate"            
#> [9] "range"
```

Each file will be read into a list of two data frames.

``` r
hic <- map2(
  .x = list(cand_csv, comm_csv),
  .y = list(cand_names, comm_names),
  .f = ~read_delim(
    file = .x,
    delim = "\t",
    skip = 1,
    na = c("", " ", "-"),
    escape_backslash = FALSE,
    escape_double = FALSE,
    col_names = .y,
    col_types = cols(
      .default = col_character(),
      date = col_date_mdy(),
      amount = col_double(),
      aggregate = col_double()
    )
  )
)
```

Then those two data frames can be combined with overlapping columns
aligned and the unique ones moved into the appropriate position or
removed.

``` r
hic <- bind_rows(hic) %>% 
  mutate(across(ends_with("yes_or_no"), `==`, "Y")) %>% 
  relocate(noncandidate_committee_name, .after = candidate_name) %>% 
  rename(committee_name = noncandidate_committee_name) %>% 
  select(-location_1)
```

## Explore

There are 327,734 rows of 27 columns. Each record represents a single
campaign contribution received by Hawaii state and county candidates
from November 8, 2006 through January 1, 2023.

``` r
glimpse(hic)
#> Rows: 327,734
#> Columns: 27
#> $ candidate_name           <chr> "Abercrombie, Neil", "Ahu, Elwin", "Ahu, Elwin", "Ahu-Isa, Lei", "Aiona, James", "Aio…
#> $ committee_name           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ contributor_type         <chr> "Individual", "Individual", "Individual", "Other Entity", "Individual", "Individual",…
#> $ contributor_name         <chr> "Warner, Sherman", "Layaoen, Margie", "Fale, Erin", "Anonymous", "Aki, Pearl M.", "Ai…
#> $ date                     <date> 2010-08-03, 2014-07-17, 2014-08-06, 2012-06-18, 2009-02-09, 2008-06-19, 2010-07-14, …
#> $ amount                   <dbl> 250, 200, 30, 100, 2000, 200, 200, 200, 25, 200, 200, 200, 100, 500, 250, 250, 50, 50…
#> $ aggregate                <dbl> 350, 200, 120, 110, 5000, 400, 200, 200, 820, 200, 400, 400, 150, 500, 750, 250, 150,…
#> $ employer                 <chr> "N/A", "Retired", NA, NA, "Hawaii Pa", NA, NA, NA, "Retired", NA, "Retired", NA, "USA…
#> $ occupation               <chr> "Retired", "Retired", NA, NA, "Secretary", NA, NA, NA, "Retired", NA, "Retired", NA, …
#> $ address_1                <chr> "P.O. Box 1185", "PO Box 63", "PO Box 316", "Hanapepe BOH Branch", "PO Box 378", "136…
#> $ address_2                <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ city                     <chr> "Kameula", "Kilauea", "Hauula", "Hanapepe Town", "Lawai", "Hilo", "Keaau", "Kula", "K…
#> $ state                    <chr> "HI", "HI", "HI", "HI", "HI", "HI", "HI", "HI", "HI", "HI", "HI", "HI", "HI", "HI", "…
#> $ zip_code                 <chr> "96743", "96754", "96717", "96716", "96765", "96720", "96749", "96790", "96756", "967…
#> $ non_resident_yes_or_no   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ non_monetary_yes_or_no   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ non_monetary_category    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ non_monetary_description <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ office                   <chr> "Governor", "Lt. Governor", "Lt. Governor", "House", "Governor", "Governor", "Governo…
#> $ district                 <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ county                   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ party                    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ reg_no                   <chr> "CC10529", "CC11035", "CC11035", "CC10864", "CC10162", "CC10162", "CC10162", "CC10162…
#> $ election_period          <chr> "2006-2010", "2010-2014", "2010-2014", "2010-2012", "2006-2010", "2006-2010", "2006-2…
#> $ mapping_address          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ inoutstate               <chr> "HI", "HI", "HI", "HI", "HI", "HI", "HI", "HI", "HI", "HI", "HI", "HI", "HI", "HI", "…
#> $ range                    <chr> "0-1000", "0-1000", "0-1000", "0-1000", "> 1000", "0-1000", "0-1000", "0-1000", "0-10…
tail(hic)
#> # A tibble: 6 × 27
#>   candidate_name committee_name        contributor_type contributor_name date       amount aggregate employer occupation
#>   <chr>          <chr>                 <chr>            <chr>            <date>      <dbl>     <dbl> <chr>    <chr>     
#> 1 <NA>           Plumbers & Pipefitte… Individual       WONG-LEONG, STE… 2019-12-31  157.       363. REGENT … PLUMBER   
#> 2 <NA>           Republican Governors… Vendor / Busine… Hefter Industri… 2010-10-20  500        500  <NA>     <NA>      
#> 3 <NA>           Seafarers Political … Individual       Wilson, Chris    2014-04-30  122        122  Various… Merchant …
#> 4 <NA>           Plumbers & Pipefitte… Individual       VILLALBA, PATRI… 2017-06-30  166.       208. HEIDE &… REFRIGERA…
#> 5 <NA>           Plumbers & Pipefitte… Individual       YOSHIMOTO, RYAN… 2020-08-08   26.5      583. ALAKA'I… PLUMBER   
#> 6 <NA>           United Public Worker… Other Entity     United Public W… 2018-07-13 2520     253520  <NA>     <NA>      
#> # ℹ 18 more variables: address_1 <chr>, address_2 <chr>, city <chr>, state <chr>, zip_code <chr>,
#> #   non_resident_yes_or_no <lgl>, non_monetary_yes_or_no <lgl>, non_monetary_category <chr>,
#> #   non_monetary_description <chr>, office <chr>, district <chr>, county <chr>, party <chr>, reg_no <chr>,
#> #   election_period <chr>, mapping_address <chr>, inoutstate <chr>, range <chr>
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(hic, count_na)
#> # A tibble: 27 × 4
#>    col                      class       n          p
#>    <chr>                    <chr>   <int>      <dbl>
#>  1 candidate_name           <chr>  125000 0.381     
#>  2 committee_name           <chr>  202734 0.619     
#>  3 contributor_type         <chr>       0 0         
#>  4 contributor_name         <chr>       0 0         
#>  5 date                     <date>      0 0         
#>  6 amount                   <dbl>       0 0         
#>  7 aggregate                <dbl>       0 0         
#>  8 employer                 <chr>  128053 0.391     
#>  9 occupation               <chr>  125049 0.382     
#> 10 address_1                <chr>     598 0.00182   
#> 11 address_2                <chr>  310619 0.948     
#> 12 city                     <chr>     568 0.00173   
#> 13 state                    <chr>       1 0.00000305
#> 14 zip_code                 <chr>       0 0         
#> 15 non_resident_yes_or_no   <lgl>  125000 0.381     
#> 16 non_monetary_yes_or_no   <lgl>      39 0.000119  
#> 17 non_monetary_category    <chr>  317778 0.970     
#> 18 non_monetary_description <chr>  317781 0.970     
#> 19 office                   <chr>  125000 0.381     
#> 20 district                 <chr>  297873 0.909     
#> 21 county                   <chr>  310075 0.946     
#> 22 party                    <chr>  279507 0.853     
#> 23 reg_no                   <chr>       0 0         
#> 24 election_period          <chr>     846 0.00258   
#> 25 mapping_address          <chr>  159239 0.486     
#> 26 inoutstate               <chr>  125000 0.381     
#> 27 range                    <chr>  125000 0.381
```

We can flag any record missing a key variable needed to identify a
transaction.

``` r
key_vars <- c("date", "contributor_name", "amount", 
              "committee_name","candidate_name")
```

``` r
mean(is.na(hic$candidate_name) & is.na(hic$candidate_name))
#> [1] 0.3814069
```

``` r
hic <- hic %>% 
  mutate(any_recip = coalesce(candidate_name, committee_name)) %>% 
  flag_na(date, amount, contributor_name, any_recip) %>% 
  select(-any_recip)
```

``` r
sum(hic$na_flag)
#> [1] 0
```

``` r
if (sum(hic$na_flag) == 0) {
  hic <- select(hic, -na_flag)
}
```

### Duplicates

We can also flag any record completely duplicated across every column.

``` r
hic <- flag_dupes(hic, everything())
sum(hic$dupe_flag)
#> [1] 451
```

``` r
hic %>% 
  filter(dupe_flag) %>% 
  select(all_of(key_vars)) %>% 
  arrange(date, contributor_name)
#> # A tibble: 451 × 5
#>    date       contributor_name   amount committee_name             candidate_name
#>    <date>     <chr>               <dbl> <chr>                      <chr>         
#>  1 2008-02-21 Dowling, Everett     1000 Democratic Party of Hawaii <NA>          
#>  2 2008-02-21 Dowling, Everett     1000 Democratic Party of Hawaii <NA>          
#>  3 2008-02-21 Engesser, Thea J.     100 Democratic Party of Hawaii <NA>          
#>  4 2008-02-21 Engesser, Thea J.     100 Democratic Party of Hawaii <NA>          
#>  5 2008-03-25 Hawaii Link           100 Democratic Party of Hawaii <NA>          
#>  6 2008-03-25 Hawaii Link           100 Democratic Party of Hawaii <NA>          
#>  7 2008-03-26 Morey, Lee F.         100 Democratic Party of Hawaii <NA>          
#>  8 2008-03-26 Morey, Lee F.         100 Democratic Party of Hawaii <NA>          
#>  9 2008-03-30 Kong Kee, FLorence    100 Democratic Party of Hawaii <NA>          
#> 10 2008-03-30 Kong Kee, FLorence    100 Democratic Party of Hawaii <NA>          
#> # ℹ 441 more rows
```

### Categorical

``` r
col_stats(hic, n_distinct)
#> # A tibble: 28 × 4
#>    col                      class      n          p
#>    <chr>                    <chr>  <int>      <dbl>
#>  1 candidate_name           <chr>   1109 0.00338   
#>  2 committee_name           <chr>    828 0.00253   
#>  3 contributor_type         <chr>      9 0.0000275 
#>  4 contributor_name         <chr>  87746 0.268     
#>  5 date                     <date>  5511 0.0168    
#>  6 amount                   <dbl>  20177 0.0616    
#>  7 aggregate                <dbl>  39234 0.120     
#>  8 employer                 <chr>  21404 0.0653    
#>  9 occupation               <chr>  10028 0.0306    
#> 10 address_1                <chr>  89956 0.274     
#> 11 address_2                <chr>   4966 0.0152    
#> 12 city                     <chr>   4252 0.0130    
#> 13 state                    <chr>     58 0.000177  
#> 14 zip_code                 <chr>   7454 0.0227    
#> 15 non_resident_yes_or_no   <lgl>      3 0.00000915
#> 16 non_monetary_yes_or_no   <lgl>      3 0.00000915
#> 17 non_monetary_category    <chr>     34 0.000104  
#> 18 non_monetary_description <chr>   6630 0.0202    
#> 19 office                   <chr>     13 0.0000397 
#> 20 district                 <chr>     66 0.000201  
#> 21 county                   <chr>      5 0.0000153 
#> 22 party                    <chr>      8 0.0000244 
#> 23 reg_no                   <chr>   2057 0.00628   
#> 24 election_period          <chr>     26 0.0000793 
#> 25 mapping_address          <chr>  64172 0.196     
#> 26 inoutstate               <chr>      3 0.00000915
#> 27 range                    <chr>      3 0.00000915
#> 28 dupe_flag                <lgl>      2 0.00000610
```

![](../plots/distinct-plots-1.png)<!-- -->![](../plots/distinct-plots-2.png)<!-- -->![](../plots/distinct-plots-3.png)<!-- -->![](../plots/distinct-plots-4.png)<!-- -->![](../plots/distinct-plots-5.png)<!-- -->![](../plots/distinct-plots-6.png)<!-- -->![](../plots/distinct-plots-7.png)<!-- -->

### Amounts

``` r
hic$amount <- round(hic$amount, digits = 2)
```

``` r
summary(hic$amount)
#>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
#>  -59078.3      80.0     200.0     828.5     500.0 3000000.0
mean(hic$amount <= 0)
#> [1] 0.0003203818
```

These are the records with the minimum and maximum amounts.

``` r
glimpse(hic[c(which.max(hic$amount), which.min(hic$amount)), ])
#> Rows: 2
#> Columns: 28
#> $ candidate_name           <chr> NA, NA
#> $ committee_name           <chr> "Be Change Now", "Plumbers & Pipefitters Political Action Committee"
#> $ contributor_type         <chr> "Other Entity", "Noncandidate Committee"
#> $ contributor_name         <chr> "Hawaii Regional Council of Carpenters", "Plumbers & Pipefitters Political Action Com…
#> $ date                     <date> 2018-05-11, 2009-12-31
#> $ amount                   <dbl> 3000000.00, -59078.35
#> $ aggregate                <dbl> 3000000.0, 25396.2
#> $ employer                 <chr> NA, NA
#> $ occupation               <chr> NA, NA
#> $ address_1                <chr> "1311 Houghtailing St", "1109 Bethel Street"
#> $ address_2                <chr> NA, "Lower Level"
#> $ city                     <chr> "Honolulu", "Honolulu"
#> $ state                    <chr> "HI", "HI"
#> $ zip_code                 <chr> "96817-2759", "96813"
#> $ non_resident_yes_or_no   <lgl> NA, NA
#> $ non_monetary_yes_or_no   <lgl> FALSE, FALSE
#> $ non_monetary_category    <chr> NA, NA
#> $ non_monetary_description <chr> NA, NA
#> $ office                   <chr> NA, NA
#> $ district                 <chr> NA, NA
#> $ county                   <chr> NA, NA
#> $ party                    <chr> NA, NA
#> $ reg_no                   <chr> "NC20760", "NC20134"
#> $ election_period          <chr> "2016-2018", "2008-2010"
#> $ mapping_address          <chr> NA, NA
#> $ inoutstate               <chr> NA, NA
#> $ range                    <chr> NA, NA
#> $ dupe_flag                <lgl> FALSE, FALSE
```

![](../plots/hist-amount-1.png)<!-- -->

### Dates

We can add the calendar year from `date` with `lubridate::year()`

``` r
hic <- mutate(hic, year = year(date))
```

``` r
min(hic$date)
#> [1] "2006-11-08"
sum(hic$year < 2000)
#> [1] 0
max(hic$date)
#> [1] "2023-11-12"
sum(hic$date > today())
#> [1] 1
```

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
addr_norm <- hic %>% 
  distinct(address_1, address_2) %>% 
  mutate(
    xaddress_1 = address_1 %>%
      na_rep(n = 0) %>% 
      # keep hyphen in address number?
      str_replace("(?<=\\d)-(?=\\d)", "XYX") %>% 
      normal_address(abbs = usps_street) %>% 
      str_replace("XYX", "-")
    ,
    xaddress_2 = normal_address(
      address = address_2,
      abbs = usps_street,
      na_rep = TRUE,
      abb_end = FALSE
    )
  ) %>% 
  unite(
    col = address_norm,
    starts_with("xaddress_"),
    sep = " ",
    remove = TRUE,
    na.rm = TRUE
  )
```

    #> # A tibble: 10 × 3
    #>    address_1                  address_2  address_norm                
    #>    <chr>                      <chr>      <chr>                       
    #>  1 38 S. JUDD ST., # 13A      <NA>       38 S JUDD ST # 13A          
    #>  2 322 Naniakea Street        <NA>       322 NANIAKEA ST             
    #>  3 6122 Kalanianole Hwy.      <NA>       6122 KALANIANOLE HWY        
    #>  4 2800 OLINDA RD             <NA>       2800 OLINDA RD              
    #>  5 1495 Kiukee St             <NA>       1495 KIUKEE ST              
    #>  6 1667 S. Kihei Road, Unit D <NA>       1667 S KIHEI ROAD UNIT D    
    #>  7 2014 PUNA STREET           <NA>       2014 PUNA ST                
    #>  8 1500 Kapiolani Blvd        Suite 101A 1500 KAPIOLANI BLVD STE 101A
    #>  9 PO BOX 823                 <NA>       PO BOX 823                  
    #> 10 1927 Homerule St           <NA>       1927 HOMERULE ST

``` r
hic <- left_join(hic, addr_norm, by = c("address_1", "address_2"))
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
hic <- hic %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip_code,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  hic$zip_code,
  hic$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 × 6
#>   stage        prop_in n_distinct prop_na n_out n_diff
#>   <chr>          <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 hic$zip_code   0.961       7454 0       12648   3573
#> 2 hic$zip_norm   0.998       4266 0.00186   603    212
```

### State

All the `state` values are known to be valid abbreviations.

``` r
prop_in(hic$state, valid_state)
#> [1] 1
```

``` r
count(hic, state, sort = TRUE)
#> # A tibble: 58 × 2
#>    state      n
#>    <chr>  <int>
#>  1 HI    303492
#>  2 CA      7694
#>  3 DC      2058
#>  4 MO      1534
#>  5 WA      1432
#>  6 VA      1252
#>  7 TX      1246
#>  8 FL       928
#>  9 NY       926
#> 10 IL       760
#> # ℹ 48 more rows
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
norm_city <- hic %>% 
  distinct(city, state, zip_norm) %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("HI", "DC", "HAWAII"),
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
hic <- left_join(
  x = hic,
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
good_refine <- hic %>% 
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

    #> # A tibble: 28 × 5
    #>    state zip_norm city_swap      city_refine        n
    #>    <chr> <chr>    <chr>          <chr>          <int>
    #>  1 MA    01983    TOPFIELDS      TOPSFIELD          5
    #>  2 CA    94103    SAN FRANSICO   SAN FRANCISCO      2
    #>  3 HI    96741    KAHALEO        KALAHEO            2
    #>  4 HI    96792    WAINEAE        WAIANAE            2
    #>  5 HI    96797    WAIPUHA        WAIPAHU            2
    #>  6 HI    96821    HONOLULULU     HONOLULU           2
    #>  7 CA    91367    WOODLAWN HILLS WOODLAND HILLS     1
    #>  8 CA    94549    LAYAFETTE      LAFAYETTE          1
    #>  9 HI    96703    AHANOLA        ANAHOLA            1
    #> 10 HI    96712    HALEIWAHI      HALEIWA            1
    #> # ℹ 18 more rows

Then we can join the refined values back to the database.

``` r
hic <- hic %>% 
  left_join(good_refine, by = names(.)) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

Our goal for normalization was to increase the proportion of city values
known to be valid and reduce the total distinct values by correcting
misspellings.

| stage                    | prop_in | n_distinct | prop_na | n_out | n_diff |
|:-------------------------|--------:|-----------:|--------:|------:|-------:|
| `str_to_upper(hic$city)` |   0.968 |       3233 |   0.002 | 10548 |   1183 |
| `hic$city_norm`          |   0.971 |       3045 |   0.002 |  9468 |    983 |
| `hic$city_swap`          |   0.993 |       2459 |   0.002 |  2201 |    389 |
| `hic$city_refine`        |   0.993 |       2434 |   0.002 |  2164 |    364 |

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
hic <- hic %>% 
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
glimpse(sample_n(hic, 50))
#> Rows: 50
#> Columns: 32
#> $ candidate_name           <chr> "Turbin, Richard", NA, "English, Kalani", "Abercrombie, Neil", NA, "Machado, Colette"…
#> $ committee_name           <chr> NA, "Plumbers & Pipefitters Political Action Committee", NA, NA, "Central Pacific Ban…
#> $ contributor_type         <chr> "Individual", "Individual", "Individual", "Individual", "Individual", "Individual", "…
#> $ contributor_name         <chr> "SMITH, JOHN V.", "WONG, TODD M.", "McCrory, Lynn P.", "Lentile, Steven S.", "Seta, J…
#> $ date                     <date> 2009-12-31, 2019-06-30, 2014-03-13, 2011-08-25, 2016-02-26, 2008-10-03, 2010-06-21, …
#> $ amount                   <dbl> 200.00, 71.17, 250.00, 500.00, 41.66, 200.00, 100.00, 250.00, 10.00, 41.66, 4700.00, …
#> $ aggregate                <dbl> 200.00, 229.71, 500.00, 500.00, 666.56, 200.00, 150.00, 250.00, 430.00, 166.64, 4700.…
#> $ employer                 <chr> NA, "YORK A JOHNSON CONTROLS COMPANY", "Pulama Lanai", "Bowers & Kubota", "Central Pa…
#> $ occupation               <chr> NA, "REFRIGERATION FITTER", "Senior Vice President, Government Affairs", "Project Man…
#> $ address_1                <chr> "7007 HAWAII KAI DR #L21", "45-628 HALEKOU ROAD", "5140 Hanalei Plantation Rd.", "401…
#> $ address_2                <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ city                     <chr> "HONOLULU", "KANEOHE", "Princeville", "Lihue", "Honolulu", "Honolulu", "Honolulu", "H…
#> $ state                    <chr> "HI", "HI", "HI", "HI", "HI", "HI", "HI", "HI", "HI", "HI", "NY", "CA", "HI", "HI", "…
#> $ zip_code                 <chr> "96825", "96744", "96722", "96766", "96821", "96821-2209", "96810", "96816", "96846",…
#> $ non_resident_yes_or_no   <lgl> FALSE, NA, FALSE, FALSE, NA, FALSE, FALSE, FALSE, NA, NA, NA, NA, NA, FALSE, FALSE, F…
#> $ non_monetary_yes_or_no   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ non_monetary_category    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ non_monetary_description <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ office                   <chr> "Honolulu Council", NA, "Senate", "Governor", NA, "OHA", "Governor", "Mayor", NA, NA,…
#> $ district                 <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "7", …
#> $ county                   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "Hono…
#> $ party                    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "Demo…
#> $ reg_no                   <chr> "CC10550", "NC20134", "CC10140", "CC10529", "NC20024", "CC10317", "CC10162", "CC10377…
#> $ election_period          <chr> "2006-2010", "2018-2020", "2012-2014", "2010-2014", "2014-2016", "2004-2008", "2006-2…
#> $ mapping_address          <chr> "7007 HAWAII KAI DR #L21\nHONOLULU, HI 96825\n(21.28671, -157.70345)", NA, "5140 Hana…
#> $ inoutstate               <chr> "HI", NA, "HI", "HI", NA, "HI", "HI", "HI", NA, NA, NA, NA, NA, "HI", "HI", "HI", NA,…
#> $ range                    <chr> "0-1000", NA, "0-1000", "0-1000", NA, "0-1000", "0-1000", "0-1000", NA, NA, NA, NA, N…
#> $ dupe_flag                <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ year                     <dbl> 2009, 2019, 2014, 2011, 2016, 2008, 2010, 2018, 2016, 2009, 2022, 2020, 2021, 2013, 2…
#> $ address_clean            <chr> "7007 HAWAII KAI DR #L21", "45-628 HALEKOU RD", "5140 HANALEI PLANTATION RD", "4019 K…
#> $ city_clean               <chr> "HONOLULU", "KANEOHE", "PRINCEVILLE", "LIHUE", "HONOLULU", "HONOLULU", "HONOLULU", "H…
#> $ zip_clean                <chr> "96825", "96744", "96722", "96766", "96821", "96821", "96810", "96816", "96846", "968…
```

1.  There are 327,734 records in the database.
2.  There are 451 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 0 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
min_yr <- min(hic$year[sum(hic$year == min(hic$year)) > 100])
min_dt <- str_remove_all(min(hic$date[hic$year == min_yr]), "-")
max_dt <- str_remove_all(max(hic$date[hic$year == year(today())]), "-")
```

``` r
clean_dir <- dir_create(here("hi", "contribs", "data", "clean"))
clean_path <- path(clean_dir, glue("hi_contribs_{min_dt}-{max_dt}.csv"))
write_csv(hic, clean_path, na = "")
(clean_size <- file_size(clean_path))
#> 83.9M
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
