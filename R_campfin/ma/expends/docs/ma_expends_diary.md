Massachusetts Expenditures
================
Kiernan Nicholls
2019-08-15 17:31:24

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
  RSelenium, # remote browser
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
#> [1] "378 Mb"
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
  col_types = cols(
    .default = col_character(),
    Date = col_date(),
    Amount = col_double()
  )
)
```

Finally, we can standardize the database structure with the `janitor`
package.

``` r
ma <- ma %>% 
  clean_names("snake") %>% 
  remove_empty("cols") %>% 
  mutate_if(is_character, str_to_upper)
```

The `report_id` variable links to the “vUPLOAD\_MASTER” table of the
database, which gives more information on the *filers* of the reports
whose expenditures are listed in “vUPLOAD\_tCURRENT\_EXPENDITURES”.

``` r
master <- read_mdb(
  file = mdb_file,
  table = "vUPLOAD_MASTER",
  na = c("", "NA", "N/A", "Unknown/ N/A"),
  col_types = cols(.default = "c")
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

We can join these two tables together.

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
    #> 1 1333… 707402    13330146      2019-06-17 BOSTO… 1 EXCH… BOST… MA    02109   46.4 NEWSPA…
    #> 2 1333… 707402    13330147      2019-06-18 21ST … 150 BO… BOST… MA    02108  130   DINNER…
    #> 3 1333… 707402    13330148      2019-06-19 THE L… 60 SCH… BOST… MA    02108   63.4 MEETIN…
    #> 4 1333… 707402    13330149      2019-06-24 CVS P… 2 CENT… BOST… MA    02108   31.8 WATER …
    #> 5 1333… 707402    13330150      2019-06-25 KUSHA… 335 MA… STON… MA    02180   15.6 COFFEE…
    #> 6 1333… 707402    13330151      2019-06-26 UNION… 41 UNI… BOST… MA    02108   75.5 DINNER…
    #> # … with 16 more variables: check_number <chr>, candidate_clarification <chr>,
    #> #   recipient_cpf_id <chr>, clarified_name <chr>, clarified_purpose <chr>, guid <chr>,
    #> #   cpf_id <chr>, report_type <chr>, cand_name <chr>, office <chr>, district <chr>,
    #> #   comm_name <chr>, comm_city <chr>, comm_state <chr>, comm_zip <chr>, category <chr>

``` r
glimpse(sample_frac(ma))
```

    #> Observations: 1,136,783
    #> Variables: 27
    #> $ id                      <chr> "12558063", "13235298", "9415413", "9373118", "11716055", "13218…
    #> $ report_id               <chr> "658037", "702415", "37343", "26689", "584852", "701218", "70587…
    #> $ line_sequence           <chr> "12558063", "13235298", "9415413", "9373118", "11716055", "13218…
    #> $ date                    <date> 2017-10-18, 2018-12-21, 2005-12-15, 2003-12-08, 2016-08-12, 201…
    #> $ vendor                  <chr> "RANDOLPH AUTOMOTIVE", "POSTMASTER", "NANCY HAVER", "HINGHAM HIG…
    #> $ address                 <chr> "1245 NORTH MAIN ST", "40 POST OFFICE PARK", "*", "17 UNION STRE…
    #> $ city                    <chr> "RANDOLPH", "WILBRAHAM", "*", "HINGHAM", "DALLAS", NA, NA, "BOST…
    #> $ state                   <chr> "MA", "MA", NA, "MA", "TX", NA, NA, "MA", NA, "CA", "MA", "MA", …
    #> $ zip                     <chr> "02368", "01095", NA, "02043", "75266", NA, NA, "02205", NA, "90…
    #> $ amount                  <dbl> 48.56, 286.80, 175.00, 80.00, 53.12, 141.26, 250.00, 250.00, 227…
    #> $ purpose                 <chr> "GAS", "POSTAGE STAMPS", "DESIGN", "DONATION", "CELL PHONE REPLA…
    #> $ check_number            <chr> NA, NA, "1052", NA, NA, NA, "1229", NA, NA, NA, "000", NA, "115"…
    #> $ candidate_clarification <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ recipient_cpf_id        <chr> NA, NA, NA, NA, NA, "16625", NA, "0", NA, NA, NA, "11421", NA, N…
    #> $ clarified_name          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ clarified_purpose       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ guid                    <chr> "{7720AFD8-8EF0-E711-E880-030050FF326E}", "{DCBE7634-C232-E911-5…
    #> $ cpf_id                  <chr> "13294", "12889", "14181", "13228", "11651", "11035", "80414", "…
    #> $ report_type             <chr> "YEAR-END REPORT (ND)", "MID-YEAR REPORT", "BANK REPORT (DAYS 1-…
    #> $ cand_name               <chr> "WALTER F. TIMILTY", "ANGELO J. PUPPOLO JR.", "PETER VICKERY", "…
    #> $ office                  <chr> "SENATE", "HOUSE", "GOVERNOR'S COUNCIL", "HOUSE", "SHERIFF, MIDD…
    #> $ district                <chr> "NORFOLK, BRISTOL & PLYMOUTH", "12TH HAMPDEN", "DISTRICT, 8TH", …
    #> $ comm_name               <chr> "TIMILTY COMMITTEE", "PUPPOLO JR. COMMITTEE", "VOTE VICKERY COMM…
    #> $ comm_city               <chr> "BOSTON", "SPRINGFIELD", NA, "HINGHAM", NA, "BOSTON", "STOUGHTON…
    #> $ comm_state              <chr> "MA", "MA", NA, "MA", NA, "MA", "MA", "MA", "MA", "MA", "MA", "M…
    #> $ comm_zip                <chr> "02137", "01138", NA, "02043", NA, "02114", "02072", "01453", "0…
    #> $ category                <chr> "N", "N", "D", "N", "D", "D", "P", "N", "D", "N", "D", "P", "N",…

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
    #>  5 vendor                  chr     27355 0.0241     
    #>  6 address                 chr    216613 0.191      
    #>  7 city                    chr    213388 0.188      
    #>  8 state                   chr    209067 0.184      
    #>  9 zip                     chr    294851 0.259      
    #> 10 amount                  dbl         0 0          
    #> 11 purpose                 chr     44941 0.0395     
    #> 12 check_number            chr    753375 0.663      
    #> 13 candidate_clarification chr   1118879 0.984      
    #> 14 recipient_cpf_id        chr    831634 0.732      
    #> 15 clarified_name          chr   1133870 0.997      
    #> 16 clarified_purpose       chr   1118879 0.984      
    #> 17 guid                    chr         0 0          
    #> 18 cpf_id                  chr         0 0          
    #> 19 report_type             chr         0 0          
    #> 20 cand_name               chr         1 0.000000880
    #> 21 office                  chr    178646 0.157      
    #> 22 district                chr    152885 0.134      
    #> 23 comm_name               chr     34549 0.0304     
    #> 24 comm_city               chr    276090 0.243      
    #> 25 comm_state              chr    276645 0.243      
    #> 26 comm_zip                chr    276371 0.243      
    #> 27 category                chr         0 0

``` r
ma <- ma %>% flag_na(date, amount, vendor, cand_name)
sum(ma$na_flag)
#> [1] 27383
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
    #>  1 id                      chr   1136783 1         
    #>  2 report_id               chr    125414 0.110     
    #>  3 line_sequence           chr   1136783 1         
    #>  4 date                    date     6830 0.00601   
    #>  5 vendor                  chr    239701 0.211     
    #>  6 address                 chr    164460 0.145     
    #>  7 city                    chr      6548 0.00576   
    #>  8 state                   chr       185 0.000163  
    #>  9 zip                     chr     13473 0.0119    
    #> 10 amount                  dbl    116543 0.103     
    #> 11 purpose                 chr    226783 0.199     
    #> 12 check_number            chr     18500 0.0163    
    #> 13 candidate_clarification chr      8299 0.00730   
    #> 14 recipient_cpf_id        chr      1793 0.00158   
    #> 15 clarified_name          chr      1602 0.00141   
    #> 16 clarified_purpose       chr      8299 0.00730   
    #> 17 guid                    chr   1136562 1.000     
    #> 18 cpf_id                  chr      4334 0.00381   
    #> 19 report_type             chr        73 0.0000642 
    #> 20 cand_name               chr      4516 0.00397   
    #> 21 office                  chr       131 0.000115  
    #> 22 district                chr       319 0.000281  
    #> 23 comm_name               chr      5876 0.00517   
    #> 24 comm_city               chr       602 0.000530  
    #> 25 comm_state              chr        32 0.0000281 
    #> 26 comm_zip                chr       919 0.000808  
    #> 27 category                chr         7 0.00000616
    #> 28 na_flag                 lgl         2 0.00000176

![](../plots/report_bar-1.png)<!-- -->

![](../plots/office_bar-1.png)<!-- -->

![](../plots/category_bar-1.png)<!-- -->

![](../plots/purpose_bar-1.png)<!-- -->

### Continuous

#### Amounts

``` r
summary(ma$amount)
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#>  -489762       50      125     1098      397 13293721
```

![](../plots/amount_histogram-1.png)<!-- -->

#### Dates

``` r
ma <- mutate(ma, year = year(date))
```

``` r
min(ma$date, na.rm = TRUE)
#> [1] "1943-06-05"
sum(ma$year < 2001, na.rm = TRUE)
#> [1] 15
max(ma$date, na.rm = TRUE)
#> [1] "2706-08-27"
sum(ma$date > today(), na.rm = TRUE)
#> [1] 61
```

``` r
ma <- mutate(ma, date_flag = is.na(date) | date > today() | year < 2001)
sum(ma$date_flag, na.rm = TRUE)
#> [1] 104
```

## Wrangle

### Address

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

    #> # A tibble: 890,070 x 2
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
    #> # … with 890,060 more rows

### ZIP

``` r
n_distinct(ma$zip)
#> [1] 13473
prop_in(ma$zip, geo$zip, na.rm = TRUE)
#> [1] 0.9504865
length(setdiff(ma$zip, geo$zip))
#> [1] 8085
```

``` r
ma <- ma %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
n_distinct(ma$zip_norm)
#> [1] 6987
prop_in(ma$zip_norm, geo$zip, na.rm = TRUE)
#> [1] 0.9949958
length(setdiff(ma$zip_norm, geo$zip))
#> [1] 1435
```

### State

``` r
n_distinct(ma$state)
#> [1] 185
prop_in(ma$state, geo$state, na.rm = TRUE)
#> [1] 0.9955924
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

``` r
ma <- ma %>% 
  mutate(
    state_norm = normal_state(
      state = state,
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

``` r
n_distinct(ma$city)
#> [1] 6548
prop_in(ma$city, geo$city, na.rm = TRUE)
#> [1] 0.9477288
length(setdiff(ma$city, geo$city))
#> [1] 4175
```

#### Normalize

``` r
ma <- ma %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      geo_abbs = usps_city,
      st_abbs = c("MA", "DC"),
      na = na_city,
      na_rep = TRUE
    )
  )
```

``` r
n_distinct(ma$city_norm)
#> [1] 5788
prop_in(ma$city_norm, geo$city, na.rm = TRUE)
#> [1] 0.9739444
length(setdiff(ma$city_norm, geo$city))
#> [1] 3393
```

#### Swap

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

``` r
n_distinct(ma$city_swap)
#> [1] 3169
prop_in(ma$city_swap, geo$city, na.rm = TRUE)
#> [1] 0.9888623
length(setdiff(ma$city_swap, geo$city))
#> [1] 932
```

#### Refine

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

``` r
ma <- ma %>% 
  left_join(good_refine) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

``` r
n_distinct(ma$city_refine)
#> [1] 3142
prop_in(ma$city_refine, geo$city, na.rm = TRUE)
#> [1] 0.9895233
length(setdiff(ma$city_refine, geo$city))
#> [1] 905
```

#### Progress

Still, our progress is significant without having to make a single
manual or unconfident change. The percent of valid cities increased from
94.8% to 99.0%. The number of total distinct city values descreased from
6,548 to 3,142. The number of distinct invalid city names decreased from
4,175 to only 905, a change of -78.3%.

| Normalization Stage | Total Distinct | Percent Valid | Unique Invalid |
| :------------------ | -------------: | ------------: | -------------: |
| raw                 |           6548 |        0.9477 |           4175 |
| norm                |           5788 |        0.9739 |           3393 |
| swap                |           3169 |        0.9889 |            932 |
| refine              |           3142 |        0.9895 |            905 |

## Conclude

1.  There are 1136783 records in the database.
2.  There are `sum(ma$dupe_flag)` duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 27383 records missing either recipient or date.
5.  Consistency in goegraphic data has been improved with
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
