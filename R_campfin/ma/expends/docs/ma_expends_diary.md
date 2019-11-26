Massachusetts Expenditures
================
Kiernan Nicholls
2019-11-19 16:29:45

<!-- Need to install mdbtools -->

## Project

The Accountability Project is an effort to cut across data silos and
give journalists, policy professionals, activists, and the public at
large a simple way to search across huge volumes of public data about
people and organizations.

Our goal is to standardizing public data on a few key fields by thinking
of each dataset row as a transaction. For each transaction there should
be (at least) 3 variables:

1.  All **parties** to a transaction
2.  The **date** of the transaction
3.  The **amount** of money involved

## Objectives

This document describes the process used to complete the following
objectives:

1.  How many records are in the database?
2.  Check for duplicates
3.  Check ranges
4.  Is there anything blank or missing?
5.  Check for consistency issues
6.  Create a five-digit ZIP Code called `ZIP5`
7.  Create a `YEAR` field from the transaction date
8.  Make sure there is data on both parties to a transaction

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
  snakecase, # change string case
  tidyverse, # data manipulation
  lubridate, # datetime strings
  tidytext, # text analysis
  magrittr, # pipe opperators
  janitor, # dataframe clean
  batman, # rep(NA, 8) Batman!
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  glue, # combine strings
  here, # relative storage
  httr, # http query
  fs # search storage 
)
```

This document should be run as part of the `R_campfin` project, which
lives as a sub-directory of the more general, language-agnostic
[`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning "TAP repo")
GitHub repository.

The `R_campfin` project uses the [RStudio
projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects "Rproj")
feature and should be run as such. The project also uses the dynamic
`here::here()` tool for file paths relative to *your* machine.

``` r
# where dfs this document knit?
here::here()
#> [1] "/home/kiernan/R/accountability_datacleaning/R_campfin"
```

## Data

Data is obtained from the [Massachusetts Office of Campaign and
Political Finance (OCPF)](https://www.ocpf.us/Home/Index).

> #### The Agency
> 
> The Office of Campaign and Political Finance is an independent state
> agency that administers Massachusetts General Law Chapter 55, the
> campaign finance law, and Chapter 55C, the limited public financing
> program for statewide candidates. Established in 1973, OCPF is the
> depository for disclosure reports filed by candidates and political
> committees under M.G.L. Chapter 55.
> 
> Specifically, candidates who report to OCPF are those seeking
> statewide, legislative, county and district office, Governor’s Council
> candidates and two groups of municipal candidates: Candidates for
> mayor, city council or alderman in the state’s 14 cities with
> populations of 65,000 or more… Candidates for mayor in cities with
> populations of less than 65,000
> 
> OCPF receives reports filed by hundreds of candidates and committees,
> reviews them to ensure accurate disclosure and legal compliance, and,
> where appropriate, conducts legal reviews of campaign finance
> activity.

> #### Our Mission
> 
> The fundamental purpose of the Massachusetts campaign finance law is
> to assist in maintaining the integrity of the Commonwealth’s electoral
> system. OCPF’s primary mission is to ensure that accurate and complete
> disclosure of campaign finance activity by those involved in the
> electoral process is available in a transparent, easily accessible and
> timely manner and that stakeholders in the process fully understand
> and comply with the statute. Stakeholders must have full confidence in
> the integrity of OCPF’s procedures in transmittal and disclosure of
> activity. OCPF is committed to providing easily accessed resources,
> both in the form of disclosure and education, to all participants
> seeking to influence the outcome of political campaigns. OCPF is also
> committed to analyzing developments in campaign finance regulation and
> reform at the federal level and in other jurisdictions, so that OCPF
> can suggest legislative amendments to strengthen Chapters 55 and 55C.

## Import

We will obtain raw immutable data and import it into R as a data frame.

``` r
raw_dir <- here("ma", "expends", "data", "raw")
dir_create(raw_dir)
```

### Download

Data can be obtained from the OCPF in one of two ways: (1) Up to 250,000
search results can be downloaded in text format from the [OCPF search
page](https://www.ocpf.us/Reports/SearchItems); (2) A single [`.zip`
file](http://ocpf2.blob.core.windows.net/downloads/data/campaign-finance-reports.zip)
containing a `.mdb` file can be downloaded from the [OCPF data
page](https://www.ocpf.us/Data). We will use the later.

> Download a zipped Microsoft Access 2000 format (.mdb) database that
> includes report summaries, receipts, expenditures, in-kind
> contributions, liabilities, assets disposed, savings accounts, credit
> card reports, reimbursement reports and subvendor
reports.

``` r
zip_url <- "http://ocpf2.blob.core.windows.net/downloads/data/campaign-finance-reports.zip"
zip_path <- url2path(zip_url, raw_dir)
```

First, check the file size before downloading.

``` r
url_file_size(zip_url, format = TRUE)
#> [1] "391 MiB"
```

Then download the file to the `/data/raw` directory and unzip.

``` r
if (!all_files_new(raw_dir, "*.zip$")) {
  download.file(url = zip_url, destfile = zip_path)
}

if (!all_files_new(raw_dir, "*.mdb$")) {
  unzip(zipfile = zip_path, exdir = raw_dir)
}
```

### Read

To read this file, we will use `campfin::read_mdb()`, which wraps around
`readr::read_csv()` and the `mdb-export` command from [MDB
Tools](https://github.com/brianb/mdbtools), which must first be
installed from GitHub or your package manager.

``` bash
$ sudo apt install mdbtools
```

We can use the `mdb-tools` command line tool to find the table name we
are interested in from the database.

``` r
# get file name
mdb_file <- dir_ls(raw_dir, glob = "*.mdb$")
# list tables in file
system(paste("mdb-tables -1", mdb_file), intern = TRUE)
#>  [1] "vUPLOAD_MASTER"                       "vUPLOAD_tCURRENT_ASSETS_DISPOSED"    
#>  [3] "vUPLOAD_tCURRENT_BANK_CREDITS"        "vUPLOAD_tCURRENT_CPF9_DETAIL"        
#>  [5] "vUPLOAD_tCURRENT_CPF9_SUMMARIES"      "vUPLOAD_tCURRENT_EXPENDITURES"       
#>  [7] "vUPLOAD_tCURRENT_INKINDS"             "vUPLOAD_tCURRENT_LIABILITIES"        
#>  [9] "vUPLOAD_tCURRENT_R1_DETAIL"           "vUPLOAD_tCURRENT_R1_SUMMARIES"       
#> [11] "vUPLOAD_tCURRENT_RECEIPTS"            "vUPLOAD_tCURRENT_SAVINGS"            
#> [13] "vUPLOAD_tCURRENT_SUBVENDOR_ITEMS"     "vUPLOAD_tCURRENT_SUBVENDOR_SUMMARIES"
```

Then, use `campfin::read_mdb()` to read the table as a data
frame.

``` r
ma <- paste("mdb-export", mdb_file, "vUPLOAD_tCURRENT_EXPENDITURES") %>% 
  system(intern = TRUE) %>% 
  read_csv(
    na = c("", "NA", "N/A"),
    locale = locale(tz = "US/Eastern"),
    col_types = cols(
      .default = col_character(),
      Date = col_date(),
      Amount = col_double()
    )
  )
```

Finally, we can standardize the data frame structure with the `janitor`
package.

``` r
ma <- ma %>% 
  clean_names("snake") %>% 
  remove_empty("cols") %>% 
  mutate_if(is_character, str_to_upper)
```

The `report_id` variable links to the “vUPLOAD\_MASTER” table of the
database, which gives more information on the *filers* of the reports,
whose expenditures are listed in “vUPLOAD\_tCURRENT\_EXPENDITURES”.

``` r
master <- paste("mdb-export", mdb_file, "vUPLOAD_MASTER") %>% 
  system(intern = TRUE) %>% 
  read_csv(
    na = c("", "NA", "N/A", "Unknown/ N/A"),
    col_types = cols(.default = col_character())
  )

master <- master %>%
  clean_names("snake") %>% 
  filter(report_id %in% ma$report_id) %>% 
  mutate_all(str_to_upper) %>% 
  select(
    report_id,
    cpf_id,
    report_type = report_type_description,
    cand_name = full_name,
    office,
    district,
    comm_name = report_comm_name,
    comm_city = report_comm_city,
    comm_state = report_comm_state,
    comm_zip = report_comm_zip,
    category
  )
```

Then join these two tables together.

``` r
ma <- left_join(ma, master)
```

## Explore

``` r
head(ma)
```

    #> # A tibble: 6 x 27
    #>   id    report_id line_sequence date       vendor address city  state zip   amount purpose
    #>   <chr> <chr>     <chr>         <date>     <chr>  <chr>   <chr> <chr> <chr>  <dbl> <chr>  
    #> 1 9181… 60        9181367       2001-12-30 DONEL… 217 EA… ORAN… MA    01364   83   SUPPLI…
    #> 2 1067… 60        10676858      2001-12-31 <NA>   <NA>    <NA>  <NA>  <NA>    49.8 <NA>   
    #> 3 9181… 63        9181368       2001-06-10 WILBR… <NA>    <NA>  MA    <NA>    22.8 DINNER 
    #> 4 9181… 63        9181369       2001-01-13 WILLI… <NA>    <NA>  MA    <NA>   100   DONATI…
    #> 5 9181… 63        9181370       2001-06-06 WNEC   <NA>    <NA>  MA    <NA>   100   DONALD…
    #> 6 9181… 63        9181371       2001-02-07 WOMEN… <NA>    <NA>  MA    <NA>    50   1/2 PA…
    #> # … with 16 more variables: check_number <chr>, candidate_clarification <chr>,
    #> #   recipient_cpf_id <chr>, clarified_name <chr>, clarified_purpose <chr>, guid <chr>,
    #> #   cpf_id <chr>, report_type <chr>, cand_name <chr>, office <chr>, district <chr>,
    #> #   comm_name <chr>, comm_city <chr>, comm_state <chr>, comm_zip <chr>, category <chr>

``` r
tail(ma)
```

    #> # A tibble: 6 x 27
    #>   id    report_id line_sequence date       vendor address city  state zip   amount purpose
    #>   <chr> <chr>     <chr>         <date>     <chr>  <chr>   <chr> <chr> <chr>  <dbl> <chr>  
    #> 1 1350… 720280    13502121      2019-11-05 EXPRE… <NA>    <NA>  <NA>  <NA>  1000   NO REA…
    #> 2 1350… 720280    13502122      2019-11-05 WSAR   <NA>    <NA>  <NA>  <NA>   165   ADS    
    #> 3 1350… 720280    13502123      2019-11-07 CMEFR  <NA>    <NA>  <NA>  <NA>   100   AD FOR…
    #> 4 1350… 720280    13502124      2019-11-07 WSAR   <NA>    <NA>  <NA>  <NA>   160   NO REA…
    #> 5 1350… 720287    13502164      2019-11-19 ACTBL… <NA>    <NA>  <NA>  <NA>    10.1 <NA>   
    #> 6 1350… 720287    13502165      2019-11-19 ACTBL… <NA>    <NA>  <NA>  <NA>    18.7 <NA>   
    #> # … with 16 more variables: check_number <chr>, candidate_clarification <chr>,
    #> #   recipient_cpf_id <chr>, clarified_name <chr>, clarified_purpose <chr>, guid <chr>,
    #> #   cpf_id <chr>, report_type <chr>, cand_name <chr>, office <chr>, district <chr>,
    #> #   comm_name <chr>, comm_city <chr>, comm_state <chr>, comm_zip <chr>, category <chr>

``` r
glimpse(sample_frac(ma))
```

    #> Observations: 1,156,973
    #> Variables: 27
    #> $ id                      <chr> "9358834", "10315890", "10146373", "9447202", "12863787", "10982…
    #> $ report_id               <chr> "23914", "203658", "163308", "40312", "675455", "84483", "680097…
    #> $ line_sequence           <chr> "9358834", "10315890", "10146373", "9447202", "12863787", "10982…
    #> $ date                    <date> 2004-12-28, 2014-05-09, 2011-11-09, 2004-07-25, 2018-01-22, 200…
    #> $ vendor                  <chr> "WELLINGTON NEWS SERVICE", "COMMITTEE TO ELECT JOSEPH PACHECO", …
    #> $ address                 <chr> "P.O. BOX 15727", "775 ORCHARD STREET", "26 ORCHARD LN.", NA, "1…
    #> $ city                    <chr> "BOSTON", "RAYNHAM", "NORWOOD", "EASTON", "CHARLESTOWN", "WILMIN…
    #> $ state                   <chr> "MA", "MA", "MA", "MA", "MA", "DE", NA, NA, NA, "MA", "MA", "DE"…
    #> $ zip                     <chr> "02115", "02767", "02062", "02356", "02129", "19886", NA, NA, NA…
    #> $ amount                  <dbl> 84.09, 500.00, 1000.00, 475.00, 11.83, 724.53, 67.68, 100.00, 95…
    #> $ purpose                 <chr> "SUBSCRIPTION", "CONTRIBUTION FOR 2014 GENERAL", "CONSULTING", "…
    #> $ check_number            <chr> NA, NA, NA, NA, NA, NA, "0", "3818", "0", "DEBIT", "1367", "2139…
    #> $ candidate_clarification <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ recipient_cpf_id        <chr> NA, "0", "0", NA, NA, "0", NA, NA, NA, NA, NA, NA, "0", "0", "0"…
    #> $ clarified_name          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ clarified_purpose       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ guid                    <chr> "{96B8D07F-8EB1-44D8-44A6-2637EB03DD66}", "{F3B8515F-F8A7-4E47-4…
    #> $ cpf_id                  <chr> "13802", "80527", "15396", "10633", "15544", "10130", "13256", "…
    #> $ report_type             <chr> "YEAR-END REPORT (ND)", "PRE-PRIMARY REPORT (PAC)", "PRE-PRIMARY…
    #> $ cand_name               <chr> "STEVEN A. BADDOUR", "BROTHERHOOD OF LOCOMOTIVE ENG LEGISLATIVE …
    #> $ office                  <chr> "SENATE", NA, "SENATE", "SENATE", "HOUSE", "HOUSE", "STATEWIDE",…
    #> $ district                <chr> "1ST ESSEX", NA, "2ND SUFFOLK & MIDDLESEX", "2ND PLYMOUTH & BRIS…
    #> $ comm_name               <chr> "COMMITTEE TO ELECT STEVEN A. BADDOUR", "BROTHERHOOD OF LOCOMOTI…
    #> $ comm_city               <chr> "METHUEN", "CLEVELAND", "WATERTOWN", "BROCKTON", "CHARLESTOWN", …
    #> $ comm_state              <chr> "MA", "OH", "MA", "MA", "MA", "MA", "MA", "MA", NA, "MA", "MA", …
    #> $ comm_zip                <chr> "01844", "44113-1702", "02472", "02301", "02129", "02108", "0191…
    #> $ category                <chr> "N", "P", "N", "N", "N", "N", "D", "D", "D", "N", "N", "D", "N",…

### Missing

``` r
glimpse_fun(ma, count_na)
```

    #> # A tibble: 27 x 4
    #>    col                     type         n           p
    #>    <chr>                   <chr>    <dbl>       <dbl>
    #>  1 id                      <chr>        0 0          
    #>  2 report_id               <chr>        0 0          
    #>  3 line_sequence           <chr>        0 0          
    #>  4 date                    <date>      28 0.0000242  
    #>  5 vendor                  <chr>    28091 0.0243     
    #>  6 address                 <chr>   228907 0.198      
    #>  7 city                    <chr>   225701 0.195      
    #>  8 state                   <chr>   220909 0.191      
    #>  9 zip                     <chr>   307992 0.266      
    #> 10 amount                  <dbl>        0 0          
    #> 11 purpose                 <chr>    47670 0.0412     
    #> 12 check_number            <chr>   765670 0.662      
    #> 13 candidate_clarification <chr>  1138997 0.984      
    #> 14 recipient_cpf_id        <chr>   851556 0.736      
    #> 15 clarified_name          <chr>  1154035 0.997      
    #> 16 clarified_purpose       <chr>  1138997 0.984      
    #> 17 guid                    <chr>        0 0          
    #> 18 cpf_id                  <chr>        0 0          
    #> 19 report_type             <chr>        0 0          
    #> 20 cand_name               <chr>        1 0.000000864
    #> 21 office                  <chr>   181108 0.157      
    #> 22 district                <chr>   154290 0.133      
    #> 23 comm_name               <chr>    34864 0.0301     
    #> 24 comm_city               <chr>   276420 0.239      
    #> 25 comm_state              <chr>   276933 0.239      
    #> 26 comm_zip                <chr>   276692 0.239      
    #> 27 category                <chr>        0 0

``` r
ma <- ma %>% flag_na(date, amount, vendor, cand_name)
sum(ma$na_flag)
#> [1] 28119
mean(ma$na_flag)
#> [1] 0.02430394
```

### Duplicates

``` r
# repeated variable
all(ma$id == ma$line_sequence)
n_distinct(ma$id) == n_distinct(ma$line_sequence)
ma <- select(ma, -line_sequence)
ma <- ma %>% flag_dupes(-id, -line_sequence, -guid)
sum(ma$dupe_flag)
mean(ma$dupe_flag)
```

### Categorical

``` r
glimpse_fun(ma, n_distinct)
```

    #> # A tibble: 28 x 4
    #>    col                     type         n          p
    #>    <chr>                   <chr>    <dbl>      <dbl>
    #>  1 id                      <chr>  1156973 1         
    #>  2 report_id               <chr>   130017 0.112     
    #>  3 line_sequence           <chr>  1156973 1         
    #>  4 date                    <date>    6917 0.00598   
    #>  5 vendor                  <chr>   243960 0.211     
    #>  6 address                 <chr>   165499 0.143     
    #>  7 city                    <chr>     6611 0.00571   
    #>  8 state                   <chr>      186 0.000161  
    #>  9 zip                     <chr>    13542 0.0117    
    #> 10 amount                  <dbl>   117615 0.102     
    #> 11 purpose                 <chr>   230823 0.200     
    #> 12 check_number            <chr>    18656 0.0161    
    #> 13 candidate_clarification <chr>     8339 0.00721   
    #> 14 recipient_cpf_id        <chr>     1824 0.00158   
    #> 15 clarified_name          <chr>     1616 0.00140   
    #> 16 clarified_purpose       <chr>     8339 0.00721   
    #> 17 guid                    <chr>  1156356 0.999     
    #> 18 cpf_id                  <chr>     4420 0.00382   
    #> 19 report_type             <chr>       75 0.0000648 
    #> 20 cand_name               <chr>     4617 0.00399   
    #> 21 office                  <chr>      131 0.000113  
    #> 22 district                <chr>      319 0.000276  
    #> 23 comm_name               <chr>     5937 0.00513   
    #> 24 comm_city               <chr>      605 0.000523  
    #> 25 comm_state              <chr>       32 0.0000277 
    #> 26 comm_zip                <chr>      925 0.000800  
    #> 27 category                <chr>        7 0.00000605
    #> 28 na_flag                 <lgl>        2 0.00000173

![](../plots/report_bar-1.png)<!-- -->

![](../plots/office_bar-1.png)<!-- -->

![](../plots/category_bar-1.png)<!-- -->

![](../plots/purpose_bar-1.png)<!-- -->

### Continuous

#### Amounts

``` r
summary(ma$amount) %>% map_chr(dollar)
#>          Min.       1st Qu.        Median          Mean       3rd Qu.          Max. 
#>   "-$489,762"         "$50"     "$124.99"   "$1,088.17"     "$395.95" "$13,293,721"
sum(ma$amount <= 0)
#> [1] 1834
sum(ma$amount >= 1000000)
#> [1] 132
```

We can view the smallest and largest expenditures to check for range
issues.

From this, we can see the minimum `amount` value from an expenditure
with a `purpose` of TRANSFERS BETWEEN CHECKING AND SAVING. This isn’t
really an expenditure in the normal sense.

``` r
glimpse(filter(ma, amount == min(amount)))
#> Observations: 1
#> Variables: 28
#> $ id                      <chr> "9361212"
#> $ report_id               <chr> "24047"
#> $ line_sequence           <chr> "9361212"
#> $ date                    <date> 2002-01-01
#> $ vendor                  <chr> NA
#> $ address                 <chr> NA
#> $ city                    <chr> NA
#> $ state                   <chr> "MA"
#> $ zip                     <chr> NA
#> $ amount                  <dbl> -489761.5
#> $ purpose                 <chr> "TRANSFERS BETWEEN CHECKING AND SAVING"
#> $ check_number            <chr> NA
#> $ candidate_clarification <chr> NA
#> $ recipient_cpf_id        <chr> NA
#> $ clarified_name          <chr> NA
#> $ clarified_purpose       <chr> NA
#> $ guid                    <chr> "{96FD26BB-D325-4968-6091-F2885683571B}"
#> $ cpf_id                  <chr> "20585"
#> $ report_type             <chr> "YEAR-END REPORT (D102)"
#> $ cand_name               <chr> "WARREN  E. TOLMAN"
#> $ office                  <chr> "CONSTITUTIONAL"
#> $ district                <chr> "GOVERNOR"
#> $ comm_name               <chr> "THE TOLMAN COMMITTEE -- CLEAN ELECTIONS ACCOUNT"
#> $ comm_city               <chr> "WATERTOWN"
#> $ comm_state              <chr> "MA"
#> $ comm_zip                <chr> "02471"
#> $ category                <chr> "D"
#> $ na_flag                 <lgl> TRUE
```

The maximum `amount` of $13,293,721 was made by the THE KERRY HEALEY
COMMITTEE on 2006-12-31. However, both the `vendor` and `purpose` values
for that expenditure are missing. Searching the OCPF database online
does not return this expenditure.

``` r
glimpse(filter(ma, amount == max(amount)))
#> Observations: 1
#> Variables: 28
#> $ id                      <chr> "10682105"
#> $ report_id               <chr> "61089"
#> $ line_sequence           <chr> "10682105"
#> $ date                    <date> 2006-12-31
#> $ vendor                  <chr> NA
#> $ address                 <chr> NA
#> $ city                    <chr> NA
#> $ state                   <chr> NA
#> $ zip                     <chr> NA
#> $ amount                  <dbl> 13293721
#> $ purpose                 <chr> NA
#> $ check_number            <chr> NA
#> $ candidate_clarification <chr> NA
#> $ recipient_cpf_id        <chr> NA
#> $ clarified_name          <chr> NA
#> $ clarified_purpose       <chr> NA
#> $ guid                    <chr> "{419AF33B-D19C-4CDF-47B9-1E37E8EB0B36}"
#> $ cpf_id                  <chr> "13911"
#> $ report_type             <chr> "YEAR-END REPORT (D102)"
#> $ cand_name               <chr> "KERRY MURPHY HEALEY"
#> $ office                  <chr> "CONSTITUTIONAL"
#> $ district                <chr> "GOVERNOR"
#> $ comm_name               <chr> "THE KERRY HEALEY COMMITTEE"
#> $ comm_city               <chr> "MELROSE"
#> $ comm_state              <chr> "MA"
#> $ comm_zip                <chr> "02176"
#> $ category                <chr> "D"
#> $ na_flag                 <lgl> TRUE
```

We can use `ggplot2::geom_histogram()` to ensure a typical log-normal
distribution of expenditures.

![](../plots/amount_histogram-1.png)<!-- -->

#### Dates

We can add a `year` variable from `date` using `lubridate::year()`.

``` r
ma <- mutate(ma, year = year(date))
```

There are a number of `date` values from the distant past or future.

``` r
min(ma$date, na.rm = TRUE)
#> [1] "1943-06-05"
sum(ma$year < 2001, na.rm = TRUE)
#> [1] 15
max(ma$date, na.rm = TRUE)
#> [1] "2706-08-27"
sum(ma$date > today(), na.rm = TRUE)
#> [1] 50
count_na(ma$date)
#> [1] 28
```

We can flag these dates with a new `date_flag` variable.

``` r
ma <- mutate(ma, date_flag = is.na(date) | date > today() | year < 2001)
sum(ma$date_flag, na.rm = TRUE)
#> [1] 93
```

Using this new flag, we can create a `date_clean` variable that’s
missing these erronous dates.

``` r
ma <- ma %>% 
  mutate(
    date_clean = as_date(ifelse(date_flag, NA, date)),
    year_clean = year(date_clean)
    )
```

The Massachusetts Governor serves four-year terms, and we can see the
number of expenditures spike every four years.

![](../plots/year_bar_count-1.png)<!-- -->

If we look at the *total* amount spent, we can spot a fairly regular
spike in the total cost of expenditures made. One outlier seems to be
2016, when there was no Governor’s race but there was still $116,189,457
spent, similar to 2018.

![](../plots/year_bar_sum-1.png)<!-- -->

![](../plots/month_line-1.png)<!-- -->

## Wrangle

We should use the `campfin::normal_*()` functions to perform some basic,
high-confidence text normalization to improve the searchability of the
database.

### Address

First, we will normalize the street address by removing punctuation and
expanding abbreviations.

``` r
ma <- ma %>% 
  mutate(
    address_norm = normal_address(
      address = address,
      abbs = usps_street,
      na_rep = TRUE
    )
  )
```

We can see how this improves consistency across the `address` field.

    #> # A tibble: 897,914 x 2
    #>    address                        address_norm                
    #>    <chr>                          <chr>                       
    #>  1 27 ROSE GLEN                   27 ROSE GLEN                
    #>  2 130 BOWDOIN STREET   UNIT 1606 130 BOWDOIN STREET UNIT 1606
    #>  3 PO BOX 6                       PO BOX 6                    
    #>  4 P.O. BOX 15123                 PO BOX 15123                
    #>  5 PO BOX 55819                   PO BOX 55819                
    #>  6 2 KEITH WAY UNIT 5             2 KEITH WAY UNIT 5          
    #>  7 P.O. BOX 51014                 PO BOX 51014                
    #>  8 P.O. BOX 2969                  PO BOX 2969                 
    #>  9 1883 MAIN STREET               1883 MAIN STREET            
    #> 10 5 CHANEY STREET                5 CHANEY STREET             
    #> # … with 897,904 more rows

### ZIP

The `zip` address is already fairly clean, with 95% of the values
already in our comprehensive `valid_zip` list.

We can improve this further by lopping off the uncommon four-digit
extensions and removing common invalid codes like 00000 and 99999.

``` r
ma <- ma %>% 
  mutate_at(
    .vars = vars(ends_with("zip")),
    .funs = list(norm = normal_zip),
    na_rep = TRUE
  )
```

This brings our valid percentage to 100%.

``` r
progress_table(
  ma$zip,
  ma$zip_norm,
  ma$comm_zip,
  ma$comm_zip_norm,
  compare = valid_zip
)
#> # A tibble: 4 x 6
#>   stage         prop_in n_distinct prop_na n_out n_diff
#>   <chr>           <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 zip             0.950      13542   0.266 42097   8136
#> 2 zip_norm        0.995       7024   0.270  4216   1449
#> 3 comm_zip        0.967        925   0.239 29330    295
#> 4 comm_zip_norm   0.999        675   0.239  1312     34
```

### State

The `state` variable is also very clean, already at 100%.

There are still 126 invalid values which we can remove.

``` r
ma <- ma %>%
  mutate_at(
    .vars = vars(ends_with("state")),
    .funs = list(norm = normal_state),
    abbreviate = TRUE,
    na_rep = TRUE,
    valid = NULL
  )
```

``` r
progress_table(
  ma$state,
  ma$state_norm,
  ma$comm_state,
  ma$comm_state_norm,
  compare = valid_state
)
#> # A tibble: 4 x 6
#>   stage           prop_in n_distinct prop_na n_out n_diff
#>   <chr>             <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 state             0.995        186   0.191  4396    126
#> 2 state_norm        0.999        166   0.194   595    107
#> 3 comm_state        1.000         32   0.239   119      3
#> 4 comm_state_norm   1.000         32   0.239   119      3
```

``` r
ma %>% 
  filter(state_norm %out% valid_state) %>% 
  count(state_norm, sort = TRUE)
#> # A tibble: 107 x 2
#>    state_norm      n
#>    <chr>       <int>
#>  1 <NA>       224711
#>  2 IR             78
#>  3 M              52
#>  4 BC             35
#>  5 QC             30
#>  6 GB             26
#>  7 AU             25
#>  8 ON             23
#>  9 A              21
#> 10 GR             20
#> # … with 97 more rows
```

All records with the `state_norm` value of `M` or `A` have a `zip_norm`
value which matches MA.

``` r
ma %>% 
  filter(state_norm == "M" | state_norm == "A") %>% 
  count(zip_norm, state_norm) %>% 
  left_join(zipcodes, by = c("zip_norm" = "zip")) %>% 
  count(state)
#> # A tibble: 2 x 2
#>   state     n
#>   <chr> <int>
#> 1 MA       37
#> 2 <NA>      3
```

``` r
ma$state_norm[which(ma$state_norm == "M" | ma$state_norm == "A")] <- "MA"
```

``` r
ma$state_norm <- na_out(ma$state_norm, valid_state)
```

### City

The `city` value(s) is the hardest to normalize. We can use a four-step
system to functionally improve the searchablity of the database.

1.  **Normalize** the raw values with `campfin::normal_city()`
2.  **Match** the normal values with the *expected* value for that ZIP
    code
3.  **Swap** the normal values with the expected value if they are
    *very* similar
4.  **Refine** the swapped values the [OpenRefine
    algorithms](https://github.com/OpenRefine/OpenRefine/wiki/Clustering-In-Depth)
    and keep good changes

The raw `city` values are relatively normal, with 95% already in
`valid_city` (which is not comprehensive). We will aim to get this
number over 99%.

#### Normalize

``` r
ma <- ma %>%
  mutate_at(
    .vars = vars(ends_with("city")),
    .funs = list(norm = normal_city),
    abbs = usps_city,
    states = c("MA", "DC", "MASSACHUSETTS"),
    na = invalid_city,
    na_rep = TRUE
  )
```

This process brought us to 97% valid.

It also increased the proportion of `NA` values by 2%. These new `NA`
values were either a single (possibly repeating) character, or contained
in the `na_city` vector.

    #> # A tibble: 132 x 4
    #>    zip_norm state_norm city    city_norm
    #>    <chr>    <chr>      <chr>   <chr>    
    #>  1 <NA>     <NA>       WEB     <NA>     
    #>  2 30101    GA         ?       <NA>     
    #>  3 02124    MA         *       <NA>     
    #>  4 <NA>     CA         ON LINE <NA>     
    #>  5 <NA>     <NA>       UNKNOWN <NA>     
    #>  6 <NA>     MA         1024    <NA>     
    #>  7 <NA>     <NA>       D       <NA>     
    #>  8 01062    MA         UNKNOWN <NA>     
    #>  9 01850    MA         *       <NA>     
    #> 10 02109    <NA>       XXX     <NA>     
    #> # … with 122 more rows

#### Swap

Then, we will compare these normalized `city_norm` values to the
*expected* city value for that vendor’s ZIP code. If the [levenshtein
distance](https://en.wikipedia.org/wiki/Levenshtein_distance) is less
than 3, we can confidently swap these two values.

``` r
ma <- ma %>% 
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
      condition = match_abb | match_dist < 3,
      true = city_match,
      false = city_norm
    )
  )
```

``` r
ma <- ma %>%
  select(-city_match) %>% 
  left_join(
    y = zipcodes,
    by = c(
      "comm_state_norm" = "state",
      "comm_zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(comm_city_norm, city_match),
    match_dist = str_dist(comm_city_norm, city_match),
    comm_city_swap = if_else(
      condition = match_abb | match_dist < 3,
      true = city_match,
      false = city_norm
    )
  ) %>% 
  select(-match_abb, -match_dist)
```

#### Refine

Finally, we can pass these swapped `city_swap` values to the OpenRefine
cluster and merge algorithms. These two algorithms cluster similar
values and replace infrequent values with their more common
counterparts. This process can be harmful by making *incorrect* changes.
We will only keep changes where the state, ZIP code, *and* new city
value all match a valid combination.

``` r
good_refine <- ma %>% 
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

    #> # A tibble: 42 x 5
    #>    state_norm zip_norm city_swap     city_refine        n
    #>    <chr>      <chr>    <chr>         <chr>          <int>
    #>  1 MA         02127    SO BOSTON     BOSTON           346
    #>  2 MA         01810    NO ANDOVER    ANDOVER           25
    #>  3 MA         02139    CAMBRIDGE ID  CAMBRIDGE         11
    #>  4 MA         02138    CAMBRIDGE ID  CAMBRIDGE          7
    #>  5 CA         94025    MELENO PARK   MENLO PARK         5
    #>  6 MA         02128    SO BOSTON     BOSTON             3
    #>  7 NY         10087    NEW YORK NY   NEW YORK           3
    #>  8 FL         32708    WEST SPRINGS  WINTER SPRINGS     2
    #>  9 MA         01201    PITTSFIELD ID PITTSFIELD         2
    #> 10 MA         01202    PITTSFIELD ID PITTSFIELD         2
    #> # … with 32 more rows

We can join these good refined values back to the original data and use
them over their incorrect `city_swap` counterparts in a new
`city_refine` variable.

``` r
ma <- ma %>% 
  left_join(good_refine) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

This brings us to 99% valid values.

#### Manual

We can make very few manual changes to capture the last few big invalid
values. Local city abbreviations (BOS, DORC, WORD, CAMB) often need to
be changed by hand.

``` r
ma %>%
  filter(city_refine %out% valid_city) %>% 
  count(state_norm, zip_norm, city_refine, sort = TRUE) %>% 
  drop_na(city_refine) %>% 
  print(n = 20)
#> # A tibble: 1,029 x 4
#>    state_norm zip_norm city_refine            n
#>    <chr>      <chr>    <chr>              <int>
#>  1 MA         02125    DORC                 946
#>  2 MA         02171    NORTH QUINCY         498
#>  3 MA         02346    MIDDLEBOROUGH        473
#>  4 MA         02144    WEST SOMERVILLE      300
#>  5 MA         02532    BOURNE               257
#>  6 MA         02760    NORTH ATTLEBOROUGH   241
#>  7 MA         02190    SOUTH WEYMOUTH       237
#>  8 MA         02127    SO BOS               234
#>  9 MA         02191    NORTH WEYMOUTH       184
#> 10 MA         01237    LANESBOROUGH         177
#> 11 MA         01879    TYNGSBOROUGH         163
#> 12 MN         55126    SHOREVIEW            145
#> 13 MA         02536    WAQUOIT              106
#> 14 PA         19087    CHESTERBROOK          94
#> 15 MA         01331    PHILLIPSTON           90
#> 16 MA         02494    NEEDHAM HEIGHTS       89
#> 17 MA         02568    TISBURY               88
#> 18 MA         02703    SOUTH ATTLEBORO       86
#> 19 MA         02536    TEATICKET             83
#> 20 MA         02124    DORC                  61
#> # … with 1,009 more rows
```

``` r
ma <- ma %>% 
  mutate(
    city_manual = city_refine %>% 
      str_replace("\bBOS\b", "BOSTON") %>% 
      str_replace("^DORC$", "DORCHESTER") %>% 
      str_replace("^WORC$", "WORCHESTER") %>% 
      str_replace("^HP$", "HYDE PARK") %>% 
      str_replace("^JP$", "JAMAICA PLAIN") %>% 
      str_replace("^NY$", "NEW YORK") %>% 
      str_replace("^CRLSTRM$", "CAROL STREAM") %>% 
      str_replace("^SPFLD$", "SPRINGFIELD") %>% 
      str_replace("^SPGFLD$", "SPRINGFIELD") %>% 
      str_replace("^PLY$", "PLYMOUTH") %>% 
      str_replace("^CAMB$", "CAMBRIDGE")
  )
```

## Conclude

1.  There are 1156973 records in the database.
2.  There are `sum(ma$dupe_flag)` duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 28119 records missing either recipient or date.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 5-digit `zip_norm` variable has been created with
    `campfin::normal_zip(ma$zip)`.
7.  The 4-digit `year` variable has been created with
    `lubridate::year(ma$date)`.

## Lookup

``` r
lookup_file <- here("ma", "expends", "data", "ma_city_lookup.csv")
if (file_exists(lookup_file)) {
  lookup <- read_csv(lookup_file) %>% select(1:2)
  ma <- left_join(ma, lookup, by = c("city_manual" = "city_final"))
  progress_table(
    ma$city_raw,
    ma$city_norm,
    ma$city_swap,
    ma$city_manual,
    ma$city_clean,
    compare = valid_city
  )
}
#> # A tibble: 5 x 6
#>   stage       prop_in n_distinct prop_na n_out n_diff
#>   <chr>         <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 city_raw      0.924       6611   0.305 78378   4230
#> 2 city_norm     0.966       5833   0.330 33831   3426
#> 3 city_swap     0.991       3102   0.438  7811    849
#> 4 city_manual   0.992       3070   0.438  6285    817
#> 5 city_clean    0.994       2620   0.438  5232    409
```

``` r
progress <- progress_table(
  ma$city_raw,
  ma$city_norm,
  ma$city_swap,
  ma$city_manual,
  ma$city_clean,
  compare = valid_city
) %>% mutate(stage = as_factor(stage))
```

| stage        | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :----------- | -------: | ----------: | -------: | -----: | ------: |
| city\_raw    |    0.924 |        6611 |    0.305 |  78378 |    4230 |
| city\_norm   |    0.966 |        5833 |    0.330 |  33831 |    3426 |
| city\_swap   |    0.991 |        3102 |    0.438 |   7811 |     849 |
| city\_manual |    0.992 |        3070 |    0.438 |   6285 |     817 |
| city\_clean  |    0.994 |        2620 |    0.438 |   5232 |     409 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/progress_bar-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivilent.

``` r
progress %>% 
  select(
    stage, 
    all = n_distinct,
    bad = n_diff
  ) %>% 
  mutate(good = all - bad) %>% 
  pivot_longer(c("good", "bad")) %>% 
  mutate(name = name == "good") %>% 
  ggplot(aes(x = stage, y = value)) +
  geom_col(aes(fill = name)) +
  scale_fill_brewer(palette = "Dark2") +
  scale_y_continuous(labels = comma) +
  theme(legend.position = "bottom") +
  labs(
    title = "Massachusetts City Normalization Progress",
    subtitle = "Distinct values, valid and invalid",
    x = "Stage",
    y = "Percent Valid",
    fill = "Valid"
  )
```

![](../plots/distinct_bar-1.png)<!-- -->

## Export

``` r
proc_dir <- here("ma", "expends", "data", "processed")
dir_create(proc_dir)
```

``` r
ma %>%
  select(
    -city_norm,
    -city_swap,
    -city_match,
    -city_swap,
    -city_refine,
    -city_manual,
    -comm_city_norm
  ) %>% 
  rename(
    address_clean = address_norm,
    zip_clean = zip_norm,
    state_clean = state_norm,
    comm_zip_clean = comm_zip_norm,
    comm_state_clean = comm_state_norm,
    comm_city_clean = comm_city_swap
  ) %>% 
  write_csv(
    path = glue("{proc_dir}/ma_expends_clean.csv"),
    na = ""
  )
```
