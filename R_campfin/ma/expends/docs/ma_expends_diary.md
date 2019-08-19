Massachusetts Expenditures
================
Kiernan Nicholls
2019-08-19 15:44:04

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
  - [Conclude](#conclude)
  - [Export](#export)

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
pacman::p_load_current_gh("kiernann/campfin")
pacman::p_load(
  stringdist, # levenshtein value
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
#> [1] "/home/ubuntu/R/accountability_datacleaning/R_campfin"
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
> card reports, reimbursement reports and subvendor reports.

``` r
zip_url <- "http://ocpf2.blob.core.windows.net/downloads/data/campaign-finance-reports.zip"
zip_path <- glue("{raw_dir}/{basename(zip_url)}")
```

First, check the file size before downloading.

``` r
zip_head <- headers(HEAD(zip_url))
zip_length <- as.numeric(zip_head$`content-length`)
number_bytes(zip_length)
#> [1] "380 Mb"
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

We can use `campfin:::mdb_tables()` to find the table name we are
interested in from the database.

``` r
# get file name
mdb_file <- dir_ls(raw_dir, glob = "*.mdb$")
# list tables in file
campfin:::mdb_tables(file = mdb_file)
#>  [1] "vUPLOAD_MASTER"                       "vUPLOAD_tCURRENT_ASSETS_DISPOSED"    
#>  [3] "vUPLOAD_tCURRENT_BANK_CREDITS"        "vUPLOAD_tCURRENT_CPF9_DETAIL"        
#>  [5] "vUPLOAD_tCURRENT_CPF9_SUMMARIES"      "vUPLOAD_tCURRENT_EXPENDITURES"       
#>  [7] "vUPLOAD_tCURRENT_INKINDS"             "vUPLOAD_tCURRENT_LIABILITIES"        
#>  [9] "vUPLOAD_tCURRENT_R1_DETAIL"           "vUPLOAD_tCURRENT_R1_SUMMARIES"       
#> [11] "vUPLOAD_tCURRENT_RECEIPTS"            "vUPLOAD_tCURRENT_SAVINGS"            
#> [13] "vUPLOAD_tCURRENT_SUBVENDOR_ITEMS"     "vUPLOAD_tCURRENT_SUBVENDOR_SUMMARIES"
```

Then, use `campfin::read_mdb()` to read the table as a data frame.

``` r
ma <- read_mdb(
  file = mdb_file,
  table = "vUPLOAD_tCURRENT_EXPENDITURES",
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
master <- read_mdb(
  file = mdb_file,
  table = "vUPLOAD_MASTER",
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
    #> 1 1333… 708208    13334266      2019-08-16 ACTBL… <NA>    <NA>  <NA>  <NA>    3.96 PROCES…
    #> 2 1333… 708209    13334270      2019-08-08 TARGE… <NA>    <NA>  <NA>  <NA>   55.8  PROCES…
    #> 3 1333… 708223    13334402      2019-08-18 ACTBL… <NA>    <NA>  <NA>  <NA>   56.7  CREDIT…
    #> 4 1333… 708223    13334403      2019-08-18 ACTBL… <NA>    <NA>  <NA>  <NA>    6.14 CREDIT…
    #> 5 1333… 708223    13334404      2019-08-18 ACTBL… <NA>    <NA>  <NA>  <NA>   20.8  CREDIT…
    #> 6 1333… 708224    13334409      2019-08-15 ACTBL… <NA>    <NA>  <NA>  <NA>   20.2  PROCES…
    #> # … with 16 more variables: check_number <chr>, candidate_clarification <chr>,
    #> #   recipient_cpf_id <chr>, clarified_name <chr>, clarified_purpose <chr>, guid <chr>,
    #> #   cpf_id <chr>, report_type <chr>, cand_name <chr>, office <chr>, district <chr>,
    #> #   comm_name <chr>, comm_city <chr>, comm_state <chr>, comm_zip <chr>, category <chr>

``` r
glimpse(sample_frac(ma))
```

    #> Observations: 1,138,235
    #> Variables: 27
    #> $ id                      <chr> "9358834", "10315890", "10146386", "9447264", "12856156", "10982…
    #> $ report_id               <chr> "23914", "203658", "163309", "40316", "675115", "84483", "679304…
    #> $ line_sequence           <chr> "9358834", "10315890", "10146386", "9447264", "12856156", "10982…
    #> $ date                    <date> 2004-12-28, 2014-05-09, 2011-12-01, 2004-09-07, 2018-10-12, 200…
    #> $ vendor                  <chr> "WELLINGTON NEWS SERVICE", "COMMITTEE TO ELECT JOSEPH PACHECO", …
    #> $ address                 <chr> "P.O. BOX 15727", "775 ORCHARD STREET", "56 CREIGHTON ST.", "235…
    #> $ city                    <chr> "BOSTON", "RAYNHAM", "CAMBRIDGE", "BROCKTON", "HULL", "WILMINGTG…
    #> $ state                   <chr> "MA", "MA", "MA", "MA", "MA", "DE", NA, NA, NA, "MA", NA, "MA", …
    #> $ zip                     <chr> "02115", "02767", "02140", "02301", "02045", "19886", NA, NA, NA…
    #> $ amount                  <dbl> 84.09, 500.00, 7025.66, 100.00, 100.00, 724.53, 313.00, 100.00, …
    #> $ purpose                 <chr> "SUBSCRIPTION", "CONTRIBUTION FOR 2014 GENERAL", "MAILING/PRINTI…
    #> $ check_number            <chr> NA, NA, NA, NA, "194", NA, NA, "3818", "0", "109", NA, "2251", N…
    #> $ candidate_clarification <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ recipient_cpf_id        <chr> NA, "0", "0", NA, "16293", "0", NA, NA, NA, NA, NA, NA, "0", "0"…
    #> $ clarified_name          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ clarified_purpose       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ guid                    <chr> "{96B8D07F-8EB1-44D8-44A6-2637EB03DD66}", "{F3B8515F-F8A7-4E47-4…
    #> $ cpf_id                  <chr> "13802", "80527", "15396", "10633", "70250", "10130", "13783", "…
    #> $ report_type             <chr> "YEAR-END REPORT (ND)", "PRE-PRIMARY REPORT (PAC)", "PRE-ELECTIO…
    #> $ cand_name               <chr> "STEVEN A. BADDOUR", "BROTHERHOOD OF LOCOMOTIVE ENG LEGISLATIVE …
    #> $ office                  <chr> "SENATE", NA, "SENATE", "SENATE", NA, "HOUSE", "CITY COUNCILOR",…
    #> $ district                <chr> "1ST ESSEX", NA, "2ND SUFFOLK & MIDDLESEX", "2ND PLYMOUTH & BRIS…
    #> $ comm_name               <chr> "COMMITTEE TO ELECT STEVEN A. BADDOUR", "BROTHERHOOD OF LOCOMOTI…
    #> $ comm_city               <chr> "METHUEN", "CLEVELAND", "WATERTOWN", "BROCKTON", "HULL", "BOSTON…
    #> $ comm_state              <chr> "MA", "OH", "MA", "MA", "MA", "MA", "MA", "MA", NA, "MA", "MA", …
    #> $ comm_zip                <chr> "01844", "44113-1702", "02472", "02301", "02045", "02108", "0213…
    #> $ category                <chr> "N", "P", "N", "N", "W", "N", "D", "D", "D", "N", "N", "D", "N",…

### Missing

``` r
glimpse_fun(ma, count_na)
```

    #> # A tibble: 27 x 4
    #>    var                     type        n           p
    #>    <chr>                   <chr>   <int>       <dbl>
    #>  1 id                      chr         0 0          
    #>  2 report_id               chr         0 0          
    #>  3 line_sequence           chr         0 0          
    #>  4 date                    date       28 0.0000246  
    #>  5 vendor                  chr     27380 0.0241     
    #>  6 address                 chr    217639 0.191      
    #>  7 city                    chr    214203 0.188      
    #>  8 state                   chr    209873 0.184      
    #>  9 zip                     chr    295781 0.260      
    #> 10 amount                  dbl         0 0          
    #> 11 purpose                 chr     45140 0.0397     
    #> 12 check_number            chr    754323 0.663      
    #> 13 candidate_clarification chr   1120322 0.984      
    #> 14 recipient_cpf_id        chr    833082 0.732      
    #> 15 clarified_name          chr   1135319 0.997      
    #> 16 clarified_purpose       chr   1120322 0.984      
    #> 17 guid                    chr         0 0          
    #> 18 cpf_id                  chr         0 0          
    #> 19 report_type             chr         0 0          
    #> 20 cand_name               chr         1 0.000000879
    #> 21 office                  chr    178902 0.157      
    #> 22 district                chr    153060 0.134      
    #> 23 comm_name               chr     34559 0.0304     
    #> 24 comm_city               chr    276091 0.243      
    #> 25 comm_state              chr    276646 0.243      
    #> 26 comm_zip                chr    276372 0.243      
    #> 27 category                chr         0 0

``` r
ma <- ma %>% flag_na(date, amount, vendor, cand_name)
sum(ma$na_flag)
#> [1] 27408
```

### Duplicates

``` r
ma <- ma %>% flag_dupes(-id, -line_sequence, -guid)
sum(ma$dupe_flag)
```

### Categorical

``` r
glimpse_fun(ma, n_distinct)
```

    #> # A tibble: 28 x 4
    #>    var                     type        n          p
    #>    <chr>                   <chr>   <int>      <dbl>
    #>  1 id                      chr   1138235 1         
    #>  2 report_id               chr    125741 0.110     
    #>  3 line_sequence           chr   1138235 1         
    #>  4 date                    date     6834 0.00600   
    #>  5 vendor                  chr    240002 0.211     
    #>  6 address                 chr    164492 0.145     
    #>  7 city                    chr      6551 0.00576   
    #>  8 state                   chr       185 0.000163  
    #>  9 zip                     chr     13475 0.0118    
    #> 10 amount                  dbl    116572 0.102     
    #> 11 purpose                 chr    226952 0.199     
    #> 12 check_number            chr     18510 0.0163    
    #> 13 candidate_clarification chr      8305 0.00730   
    #> 14 recipient_cpf_id        chr      1793 0.00158   
    #> 15 clarified_name          chr      1604 0.00141   
    #> 16 clarified_purpose       chr      8305 0.00730   
    #> 17 guid                    chr   1137618 0.999     
    #> 18 cpf_id                  chr      4337 0.00381   
    #> 19 report_type             chr        73 0.0000641 
    #> 20 cand_name               chr      4523 0.00397   
    #> 21 office                  chr       131 0.000115  
    #> 22 district                chr       319 0.000280  
    #> 23 comm_name               chr      5877 0.00516   
    #> 24 comm_city               chr       602 0.000529  
    #> 25 comm_state              chr        32 0.0000281 
    #> 26 comm_zip                chr       920 0.000808  
    #> 27 category                chr         7 0.00000615
    #> 28 na_flag                 lgl         2 0.00000176

![](../plots/report_bar-1.png)<!-- -->

![](../plots/office_bar-1.png)<!-- -->

![](../plots/category_bar-1.png)<!-- -->

![](../plots/purpose_bar-1.png)<!-- -->

### Continuous

#### Amounts

``` r
summary(ma$amount) %>% map_chr(dollar)
#>          Min.       1st Qu.        Median          Mean       3rd Qu.          Max. 
#>   "$-489,762"         "$50"        "$125"   "$1,096.90"     "$396.26" "$13,293,721"
sum(ma$amount <= 0)
#> [1] 1821
sum(ma$amount >= 1000000)
#> [1] 131
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
#> [1] 61
count_na(ma$date)
#> [1] 28
```

We can flag these dates with a new `date_flag` variable.

``` r
ma <- mutate(ma, date_flag = is.na(date) | date > today() | year < 2001)
sum(ma$date_flag, na.rm = TRUE)
#> [1] 104
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
2016, when there was no Governor’s race but there was still $116,189,334
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
      add_abbs = usps,
      na_rep = TRUE
    )
  )
```

We can see how this improves consistency across the `address` field.

    #> # A tibble: 890,496 x 2
    #>    address                               address_norm                        
    #>    <chr>                                 <chr>                               
    #>  1 217 EAST MAIN ST.                     217 EAST MAIN STREET                
    #>  2 ONE ASHBURTON PLACE                   ONE ASHBURTON PLACE                 
    #>  3 1874 MASSACHUSETTS AVE                1874 MASSACHUSETTS AVENUE           
    #>  4 126 HIGH ST                           126 HIGH STREET                     
    #>  5 PO BOX 170305                         PO BOX 170305                       
    #>  6 30 GERMANIA ST                        30 GERMANIA STREET                  
    #>  7 1557 MASSACHUSETTS AVE                1557 MASSACHUSETTS AVENUE           
    #>  8 11 ALCOTT RD                          11 ALCOTT ROAD                      
    #>  9 PERMIT FEE WINDON, FORT POINT STATION PERMIT FEE WINDON FORT POINT STATION
    #> 10 304 SILVER HILL ROAD                  304 SILVER HILL ROAD                
    #> # … with 890,486 more rows

### ZIP

The `zip` address is already fairly clean, with 95.1% of the values
already in our comprehensive `geo$zip` list.

``` r
n_distinct(ma$zip)
#> [1] 13475
prop_in(ma$zip, geo$zip, na.rm = TRUE)
#> [1] 0.9505172
length(setdiff(ma$zip, geo$zip))
#> [1] 8085
```

We can improve this further by lopping off the uncommon four-digit
extensions and removing common invalid codes like 00000 and 99999.

``` r
ma <- ma %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

This brings our valid percentage to 99.5%.

``` r
n_distinct(ma$zip_norm)
#> [1] 6989
prop_in(ma$zip_norm, geo$zip, na.rm = TRUE)
#> [1] 0.994999
length(setdiff(ma$zip_norm, geo$zip))
#> [1] 1435
```

### State

The `state` variable is also very clean, already at 99.6%.

``` r
n_distinct(ma$state)
#> [1] 185
prop_in(ma$state, geo$state, na.rm = TRUE)
#> [1] 0.9955944
length(setdiff(ma$state, geo$state))
#> [1] 117
setdiff(ma$state, geo$state)
#>   [1] NA   "IO" "AM" "CN" "ML" "CH" "MC" "RO" "NA" "EN" "IR" "IE" "GB" "02" "M"  "KE" "IW" "TZ"
#>  [19] "NK" "D." "BR" "WS" "KA" "LI" "ST" "VY" "UK" "`"  "X"  "XX" "RU" "S"  "MQ" "CR" "HP" "D" 
#>  [37] "PK" "WU" "QU" "IS" "TA" "TW" "LE" "MM" "JP" "TF" "VJ" "HA" "CI" "ZA" "SZ" "*"  "AX" "NZ"
#>  [55] "AU" "HT" "CC" "YN" "2"  "9A" "PO" "TY" "C"  "MY" "FR" "II" "NT" "N." "*C" "I"  "WZ" "CV"
#>  [73] "`M" "*M" "NW" "G"  "SP" "01" "RD" "GM" "SW" "L"  "DK" "S." "?`" "PS" "PH" "TE" "QA" ",A"
#>  [91] "WO" "A*" "*A" "N"  "CU" "UA" "W"  "MV" "PT" "PI" "NG" "GR" "DR" "]]" "U"  "MG" "BV" "0H"
#> [109] "OC" "Q"  "TH" "MX" "CS" "AC" "RE" "HK" "DV"
```

There are still 117 invalid values which we can remove.

``` r
ma <- ma %>% 
  mutate(
    state_norm = normal_state(
      state = str_replace(state, "^M$", "MA"),
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = geo$state
    )
  )
```

``` r
n_distinct(ma$state_norm)
#> [1] 52
prop_in(ma$state_norm, geo$state, na.rm = TRUE)
#> [1] 1
```

### City

The `city` value is the hardest to normalize. We can use a four-step
system to functionally improve the searchablity of the database.

1.  **Normalize** the raw values with `campfin::normal_city()`
2.  **Match** the normal values with the *expected* value for that ZIP
    code
3.  **Swap** the normal values with the expected value if they are
    *very* similar
4.  **Refine** the swapped values the [OpenRefine
    algorithms](https://github.com/OpenRefine/OpenRefine/wiki/Clustering-In-Depth)
    and keep good changes

The raw `city` values are relatively normal, with 94.8% already in
`geo$city` (which is not comprehensive). We will aim to get this number
over 99%.

``` r
n_distinct(ma$city)
#> [1] 6551
prop_in(ma$city, geo$city, na.rm = TRUE)
#> [1] 0.947741
length(setdiff(ma$city, geo$city))
#> [1] 4178
prop_na(ma$city)
#> [1] 0.1881887
```

#### Normalize

``` r
ma <- ma %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      geo_abbs = usps_city,
      st_abbs = c("MA", "DC", "MASSACHUSETTS"),
      na = na_city,
      na_rep = TRUE
    )
  )
```

This process brought us to 97.4% valid.

``` r
n_distinct(ma$city_norm)
#> [1] 5790
prop_in(ma$city_norm, geo$city, na.rm = TRUE)
#> [1] 0.9739725
length(setdiff(ma$city_norm, geo$city))
#> [1] 3395
prop_na(ma$city_norm)
#> [1] 0.2045342
```

It also increased the proportion of `NA` values by 1.63%. These new `NA`
values were either a single (possibly repeating) character, or contained
in the `na_city` vector.

    #> # A tibble: 118 x 4
    #>    zip_norm state_norm city     city_norm
    #>    <chr>    <chr>      <chr>    <chr>    
    #>  1 94040    <NA>       XXX      <NA>     
    #>  2 <NA>     MA         ONLINE   <NA>     
    #>  3 <NA>     MA         N/A      <NA>     
    #>  4 <NA>     <NA>       *        <NA>     
    #>  5 <NA>     <NA>       NONE     <NA>     
    #>  6 <NA>     MA         *        <NA>     
    #>  7 <NA>     <NA>       ??       <NA>     
    #>  8 01211    MA         *        <NA>     
    #>  9 02062    MA         ONLINE   <NA>     
    #> 10 <NA>     <NA>       INTERNET <NA>     
    #> # … with 108 more rows

#### Swap

Then, we will compare these normalized `city_norm` values to the
*expected* city value for that vendor’s ZIP code. If the [levenshtein
distance](https://en.wikipedia.org/wiki/Levenshtein_distance) is less
than 3, we can confidently swap these two values.

``` r
ma <- ma %>% 
  rename(city_raw = city) %>% 
  left_join(
    y = geo,
    by = c(
      "state_norm" = "state",
      "zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_dist = stringdist(city_norm, city_match),
    city_swap = if_else(
      condition = is_less_than(match_dist, 3),
      true = city_match,
      false = city_norm
    )
  )
```

This is a very fast way to increase the valid proportion to 98.9% and
reduce the number of distinct *invalid* values from 3395 to only 932

``` r
n_distinct(ma$city_swap)
#> [1] 3169
prop_in(ma$city_swap, geo$city, na.rm = TRUE)
#> [1] 0.9888953
length(setdiff(ma$city_swap, geo$city))
#> [1] 932
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
    y = geo,
    by = c(
      "city_refine" = "city",
      "state_norm" = "state",
      "zip_norm" = "zip"
    )
  )
```

    #> # A tibble: 68 x 5
    #>    state_norm zip_norm city_raw              city_refine         n
    #>    <chr>      <chr>    <chr>                 <chr>           <int>
    #>  1 MA         02140    CAMBRIDGE ID#13738    CAMBRIDGE           1
    #>  2 MA         01201    PITTSFIELD (ID#14515) PITTSFIELD          1
    #>  3 NY         10279    NEW YORK, N.Y.        NEW YORK            1
    #>  4 MA         01201    PITTSFIELD (ID 13009) PITTSFIELD          1
    #>  5 MA         02176    "MELROSE\r\nELROSE"   MELROSE             1
    #>  6 TX         78682    ROCK ROUND            ROUND ROCK          1
    #>  7 MA         02120    SO. BOSTON            BOSTON              1
    #>  8 MA         02748    SO DARMOUTH           SOUTH DARTMOUTH     2
    #>  9 NH         03105    MANCHESTER NH         MANCHESTER          1
    #> 10 MA         02128    SO. BOSTON            BOSTON              3
    #> # … with 58 more rows

We can join these good refined values back to the original data and use
them over their incorrect `city_swap` counterparts in a new
`city_refine` variable.

``` r
ma <- ma %>% 
  left_join(good_refine) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

This brings us to 99.0% valid values.

``` r
n_distinct(ma$city_refine)
#> [1] 3142
prop_in(ma$city_refine, geo$city, na.rm = TRUE)
#> [1] 0.9895558
length(setdiff(ma$city_refine, geo$city))
#> [1] 905
```

#### Progress

We can make very few manual changes to capture the last few big invalid
values. Local city abbreviations (BOS, DORC, WORD, CAMB) often need to
be changed by hand.

``` r
ma %>%
  filter(city_refine %out% geo$city) %>% 
  count(state_norm, zip_norm, city_refine, sort = TRUE) %>% 
  drop_na(city_refine) %>% 
  print(n = 20)
#> # A tibble: 1,220 x 4
#>    state_norm zip_norm city_refine            n
#>    <chr>      <chr>    <chr>              <int>
#>  1 MA         02125    DORC                 946
#>  2 MA         02171    NORTH QUINCY         492
#>  3 MA         02346    MIDDLEBOROUGH        472
#>  4 MA         02144    WEST SOMERVILLE      300
#>  5 MA         02532    BOURNE               252
#>  6 MA         02760    NORTH ATTLEBOROUGH   235
#>  7 MA         02127    SO BOS               234
#>  8 MA         02190    SOUTH WEYMOUTH       231
#>  9 MA         02191    NORTH WEYMOUTH       182
#> 10 MA         01237    LANESBOROUGH         176
#> 11 MA         01879    TYNGSBOROUGH         163
#> 12 MN         55126    SHOREVIEW            143
#> 13 MA         02536    WAQUOIT              106
#> 14 MA         01654    WORC                 104
#> 15 PA         19087    CHESTERBROOK          94
#> 16 MA         01331    PHILLIPSTON           90
#> 17 MA         02494    NEEDHAM HEIGHTS       89
#> 18 MA         02568    TISBURY               87
#> 19 MA         02703    SOUTH ATTLEBORO       86
#> 20 MA         02536    TEATICKET             83
#> # … with 1,200 more rows
```

``` r
ma <- ma %>% 
  mutate(
    city_final = city_refine %>% 
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

By making less than a dozen manual string replacements, we bring our
final valid percentage to 99.1%, above our 99% goal. There are still 896
different *invalid* values that could be checked, but they make up less
than 1% of records. Many of these values are actually valid and simply
not in our list (which doesn’t contain very small towns and census
desginated places).

Still, our progress is significant without having to make a single
manual or unconfident change. The percent of valid cities increased from
94.8% to 99.1%. The number of total distinct city values decreased from
6,551 to 3,133. The number of distinct invalid city names decreased from
4,178 to only 896, a change of -78.6%.

| Normalization Stage | Total Distinct | Percent Valid | Unique Invalid |
| :------------------ | -------------: | ------------: | -------------: |
| raw                 |           6551 |        0.9477 |           4178 |
| norm                |           5790 |        0.9740 |           3395 |
| swap                |           3169 |        0.9889 |            932 |
| refine              |           3142 |        0.9896 |            905 |
| final               |           3133 |        0.9914 |            896 |

## Conclude

1.  There are 1138235 records in the database.
2.  There are `sum(ma$dupe_flag)` duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 27408 records missing either recipient or date.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 5-digit `zip_norm` variable has been created with
    `campfin::normal_zip(ma$zip)`.
7.  The 4-digit `year` variable has been created with
    `lubridate::year(ma$date)`.

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
    -match_dist
  ) %>% 
  write_csv(
    path = glue("{proc_dir}/ma_expends_clean.csv"),
    na = ""
  )
```
