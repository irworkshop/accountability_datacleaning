District Of Columbia Voters
================
Kiernan Nicholls
2020-12-07 13:37:13

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
      - [Columns](#columns)
      - [Status](#status)
      - [History](#history)
  - [Read](#read)
  - [Explore](#explore)
      - [Missing](#missing)
      - [Duplicates](#duplicates)
      - [Categorical](#categorical)
      - [Dates](#dates)
  - [Wrangle](#wrangle)
  - [Conclude](#conclude)
  - [Export](#export)
  - [Upload](#upload)
  - [Dictionary](#dictionary)

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
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  gluedown, # printing markdown
  janitor, # clean data frames
  campfin, # custom irw tools
  aws.s3, # aws cloud storage
  readxl, # read excel files
  refinr, # cluster & merge
  scales, # format strings
  digest, # hash strings
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
here::dr_here(show_reason = FALSE)
```

## Data

The DC voter registration database can be requested from the Board of
Elections by filling out the [Data Request
Form](https://www.dcboe.org/dcboe/media/PDFFiles/Data_Request_Form.pdf)
PDF and submitting it alongside a small fee, depending on the requested
format.

Data was requested by the Investigative Reporting Workshop and received
on September 28, 2020.

Two files were provided to the IRW:

1.  `D.C. Registered Voters (All).xlsx`
2.  `Read Me.txt`

The README file contains a number of tables to describe the data.

``` r
raw_dir <- here("dc", "voters", "data", "raw")
readme <- read_lines(file = path(raw_dir, "Read Me.txt"))
```

#### Columns

``` r
raw_cols <- read_tsv(
  file = readme[3:22],
  col_names = str_split(readme[1], "\t", simplify = TRUE)
)
kable(raw_cols)
```

| COL | FIELDNAME  | TYPE     | MAX LENGTH |
| --: | :--------- | :------- | :--------- |
|   1 | REGISTERED | DATETIME | 0          |
|   2 | LASTNAME   | VARCHAR  | 20         |
|   3 | FIRSTNAME  | VARCHAR  | 20         |
|   4 | MIDDLE     | VARCHAR  | 1          |
|   5 | SUFFIX     | VARCHAR  | 3          |
|   6 | STATUS     | VARCHAR  | 1          |
|   7 | PARTY      | VARCHAR  | 20         |
|   8 | RES\_HOUSE | VARCHAR  | 10         |
|   9 | RES\_FRAC  | VARCHAR  | 10         |
|  10 | RES\_APT   | VARCHAR  | 15         |
|  11 | RES STREET | VARCHAR  | 25         |
|  12 | RES\_CITY  | VARCHAR  | 25         |
|  13 | RES\_STATE | VARCHAR  | 2          |
|  14 | RES\_ZIP   | VARCHAR  | 5          |
|  15 | RES\_ZIP4  | VARCHAR  | 4          |
|  16 | PRECINCT   | FLOAT    | \*         |
|  17 | WARD       | VARCHAR  | 10         |
|  18 | ANC        | VARCHAR  | 2          |
|  19 | SMD        | VARCHAR  | 4          |
|  20 | VOTER ID   | VARCHAR  | 15         |

#### Status

| Code | Meaning         |
| :--- | :-------------- |
| `A`  | ACTIVE          |
| `X`  | ACTIVE (ID REQ) |
| `F`  | FEDERAL ONLY    |

#### History

``` r
hist_codes <- tribble(
  ~code, ~action,
  NA,  "NO VOTING HISTORY",
  "V", "POLL",
  "A", "ABSENTEE",
  "N", "NOT ELIGIBLE TO VOTE",
  "E", "ELIGIBLE BUT DID NOT VOTE",
  "Y", "EARLY VOTER"
)
```

| code | action                    |
| :--- | :------------------------ |
| NA   | NO VOTING HISTORY         |
| V    | POLL                      |
| A    | ABSENTEE                  |
| N    | NOT ELIGIBLE TO VOTE      |
| E    | ELIGIBLE BUT DID NOT VOTE |
| Y    | EARLY VOTER               |

## Read

``` r
raw_path <- dir_ls(raw_dir, regexp = "xlsx$")
```

This text file can then be easily read as a data frame.

``` r
dcv <- read_excel(raw_path, col_types = "text")
```

We can ensure the data was properly read by checking the unique values
of the city column, which should obviously all be Washington.

``` r
n_distinct(dcv$RES_CITY)
#> [1] 1
unique(dcv$RES_CITY)
#> [1] "WASHINGTON"
```

``` r
dcv <- mutate(dcv, across(REGISTERED, ~excel_numeric_to_date(as.numeric(.))))
```

The last 50 columns of the file are the voter’s behavior in past
elections. This data will be moved to a new object and converted to a
more format that is more easily analyzed.

``` r
hist_file <- path(raw_dir, "dc_vote_hist.tsv.xz")
if (!file_exists(hist_file)) {
  dcv %>% 
    select(FIRSTNAME, LASTNAME, REGISTERED, matches("^\\d")) %>%
    pivot_longer(
      cols = !1:3,
      names_to = "date_type",
      values_to = "vote_code",
      values_drop_na = TRUE
    ) %>% 
    separate(
      col = date_type,
      into = c("elect_date", "elect_type"),
      sep = "-"
    ) %>% 
    mutate(across(elect_date, mdy)) %>% 
    clean_names("snake") %>% 
    write_tsv(xzfile(hist_file))
  rm(vote_hist)
  flush_memory(1)
}
```

## Explore

There are 503,316 rows of 19 columns.

``` r
glimpse(dcv)
#> Rows: 503,316
#> Columns: 19
#> $ reg_date <date> 1984-10-09, 1984-10-09, 1984-10-09, 1984-10-09, 1984-10-09, 1984-10-09, 1984-1…
#> $ last     <chr> "MCINTOSH", "MCLAREN", "MCLAUGHLIN", "MCLELLAN", "MCMANUS", "MCMANUS", "MCQUIRT…
#> $ first    <chr> "WILLIAM", "DOUGLAS", "VERSEY", "DOUGLAS", "JOSEPH", "SEAN", "TRACYE", "LAURIE"…
#> $ middle   <chr> "F", "E", "L", "C", "M", "G", "L", "S", "M", "M", "A", "G", NA, "L", "H", "B", …
#> $ suffix   <chr> "JR", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ status   <chr> "A", "A", "A", "A", "A", "A", "A", "A", "A", "A", "A", "A", "A", "A", "A", "A",…
#> $ party    <chr> "DEMOCRATIC", "DEMOCRATIC", "DEMOCRATIC", "REPUBLICAN", "REPUBLICAN", "DEMOCRAT…
#> $ house    <chr> "4735", "1825", "5610", "636", "4530", "608", "2120", "6544", "6544", "4420", "…
#> $ frac     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ apt      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "405", "1", "302", "3", NA, NA, NA, NA,…
#> $ street   <chr> "NEBRASKA AVE NW", "TULIP ST NW", "CLAY PL NE", "12TH ST NE", "29TH ST NW", "3R…
#> $ city     <chr> "WASHINGTON", "WASHINGTON", "WASHINGTON", "WASHINGTON", "WASHINGTON", "WASHINGT…
#> $ state    <chr> "DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC", "…
#> $ zip      <chr> "20016", "20012", "20019", "20002", "20008", "20024", "20001", "20012", "20012"…
#> $ zip4     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ precinct <chr> "33", "62", "96", "82", "138", "128", "135", "64", "64", "10", "13", "55", "10"…
#> $ ward     <chr> "3", "4", "7", "6", "3", "6", "5", "4", "4", "3", "2", "4", "3", "1", "3", "3",…
#> $ anc      <chr> "[3E]", "[4A]", "[7C]", "[6A]", "[3F]", "[6D]", "[5E]", "[4B]", "[4B]", "[3D]",…
#> $ smd      <chr> "[3E04]", "[4A01]", "[7C05]", "[6A02]", "[3F03]", "[6D02]", "[5E08]", "[4B07]",…
tail(dcv)
#> # A tibble: 6 x 19
#>   reg_date   last  first middle suffix status party house frac  apt   street city  state zip  
#>   <date>     <chr> <chr> <chr>  <chr>  <chr>  <chr> <chr> <chr> <chr> <chr>  <chr> <chr> <chr>
#> 1 1984-10-09 MCCR… GRACE L      <NA>   A      DEMO… 5021  <NA>  <NA>  AMES … WASH… DC    20019
#> 2 1984-10-09 MCDO… MICH… L      <NA>   A      DEMO… 1415  <NA>  <NA>  44TH … WASH… DC    20019
#> 3 1984-10-09 MCFA… KATH… P      <NA>   A      DEMO… 4318  <NA>  <NA>  E ST … WASH… DC    20019
#> 4 1984-10-09 MCGEE JAMES M      SR     A      DEMO… 1834  <NA>  <NA>  VALLE… WASH… DC    20032
#> 5 1984-10-09 MCGEE MARY  F      <NA>   A      DEMO… 1834  <NA>  <NA>  VALLE… WASH… DC    20032
#> 6 1984-10-09 MCGU… PATR… J      <NA>   A      REPU… 5452  <NA>  <NA>  NEBRA… WASH… DC    20015
#> # … with 5 more variables: zip4 <chr>, precinct <chr>, ward <chr>, anc <chr>, smd <chr>
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(dcv, count_na)
#> # A tibble: 19 x 4
#>    col      class       n          p
#>    <chr>    <chr>   <int>      <dbl>
#>  1 reg_date <date>      0 0         
#>  2 last     <chr>       0 0         
#>  3 first    <chr>       0 0         
#>  4 middle   <chr>   71181 0.141     
#>  5 suffix   <chr>  481274 0.956     
#>  6 status   <chr>       0 0         
#>  7 party    <chr>       0 0         
#>  8 house    <chr>      11 0.0000219 
#>  9 frac     <chr>  501918 0.997     
#> 10 apt      <chr>  250919 0.499     
#> 11 street   <chr>      19 0.0000377 
#> 12 city     <chr>       0 0         
#> 13 state    <chr>       0 0         
#> 14 zip      <chr>      12 0.0000238 
#> 15 zip4     <chr>  503135 1.00      
#> 16 precinct <chr>       1 0.00000199
#> 17 ward     <chr>       1 0.00000199
#> 18 anc      <chr>       1 0.00000199
#> 19 smd      <chr>       1 0.00000199
```

No columns are missing the registration date or last name needed to
identify a voter.

### Duplicates

We can also flag any record completely duplicated across every column.

``` r
d1 <- duplicated(dcv, fromLast = FALSE)
d2 <- duplicated(dcv, fromLast = TRUE)
dcv <- mutate(dcv, dupe_flag = d1 | d2)
sum(dcv$dupe_flag)
#> [1] 56
```

``` r
dcv %>% 
  filter(dupe_flag) %>% 
  select(reg_date, last, party, smd) %>% 
  arrange(reg_date)
#> # A tibble: 56 x 4
#>    reg_date   last        party      smd   
#>    <date>     <chr>       <chr>      <chr> 
#>  1 2017-08-10 ROBERTS     DEMOCRATIC [7E07]
#>  2 2017-08-10 ROBERTS     DEMOCRATIC [7E07]
#>  3 2017-08-25 NEWMAN-WISE DEMOCRATIC [3C06]
#>  4 2017-08-25 NEWMAN-WISE DEMOCRATIC [3C06]
#>  5 2018-11-06 BRAVO DIAZ  NO PARTY   [6C06]
#>  6 2018-11-06 BRAVO DIAZ  NO PARTY   [6C06]
#>  7 2018-11-06 DORSEY      DEMOCRATIC [8E01]
#>  8 2018-11-06 DORSEY      DEMOCRATIC [8E01]
#>  9 2018-11-06 KEANE       REPUBLICAN [6D02]
#> 10 2018-11-06 KEANE       REPUBLICAN [6D02]
#> # … with 46 more rows
```

### Categorical

``` r
col_stats(dcv, n_distinct)
#> # A tibble: 20 x 4
#>    col       class       n          p
#>    <chr>     <chr>   <int>      <dbl>
#>  1 reg_date  <date>  11937 0.0237    
#>  2 last      <chr>  101962 0.203     
#>  3 first     <chr>   58388 0.116     
#>  4 middle    <chr>      31 0.0000616 
#>  5 suffix    <chr>      58 0.000115  
#>  6 status    <chr>       3 0.00000596
#>  7 party     <chr>       6 0.0000119 
#>  8 house     <chr>    6511 0.0129    
#>  9 frac      <chr>      47 0.0000934 
#> 10 apt       <chr>   15161 0.0301    
#> 11 street    <chr>    1623 0.00322   
#> 12 city      <chr>       1 0.00000199
#> 13 state     <chr>       1 0.00000199
#> 14 zip       <chr>      42 0.0000834 
#> 15 zip4      <chr>     166 0.000330  
#> 16 precinct  <chr>     145 0.000288  
#> 17 ward      <chr>       9 0.0000179 
#> 18 anc       <chr>      41 0.0000815 
#> 19 smd       <chr>     297 0.000590  
#> 20 dupe_flag <lgl>       2 0.00000397
```

![](../plots/distinct_plots-1.png)<!-- -->![](../plots/distinct_plots-2.png)<!-- -->

### Dates

We can add the registration year from `reg_date` with
`lubridate::year()`.

``` r
dcv <- mutate(dcv, reg_year = year(reg_date))
```

``` r
min(dcv$reg_date)
#> [1] "1942-08-04"
max(dcv$reg_date)
#> [1] "7480-12-03"
sum(dcv$reg_date > today())
#> [1] 5
```

![](../plots/bar_year-1.png)<!-- -->

## Wrangle

The `address` variable is already sufficiently normalized and
abbreviated, we can simply map together all the individual columns.

``` r
dcv %>% 
  select(house, frac, street, apt) %>% 
  sample_n(20)
#> # A tibble: 20 x 4
#>    house frac  street              apt   
#>    <chr> <chr> <chr>               <chr> 
#>  1 115   <NA>  URELL PL NE         <NA>  
#>  2 2611  <NA>  RANDOLPH ST NE      <NA>  
#>  3 1441  <NA>  RHODE ISLAND AVE NW 911   
#>  4 621   <NA>  CONDON TER SE       <NA>  
#>  5 1325  <NA>  13TH ST NW          50    
#>  6 4021  <NA>  9TH ST NW           104   
#>  7 1615  <NA>  RIDGE PL SE         <NA>  
#>  8 2500  <NA>  VIRGINIA AVE NW     707S  
#>  9 2900  <NA>  NELSON PL SE        3     
#> 10 1     <NA>  DC VILLAGE LN SW    <NA>  
#> 11 3503  <NA>  10TH ST NE          <NA>  
#> 12 2320  <NA>  MINNESOTA AVE SE    <NA>  
#> 13 415   <NA>  L ST NW             # 531 
#> 14 3801  <NA>  PORTER ST NW        302   
#> 15 2911  <NA>  FESSENDEN ST NW     <NA>  
#> 16 912   <NA>  46TH ST NE          <NA>  
#> 17 1631  <NA>  A ST SE             APT# 1
#> 18 615   <NA>  VAN BUREN ST NW     <NA>  
#> 19 46    <NA>  GALVESTON ST SW     T1    
#> 20 2247  <NA>  15TH ST NE          <NA>
```

The city, state, and ZIP code variables are easy because it’s a single
city.

``` r
unique(dcv$city)
#> [1] "WASHINGTON"
unique(dcv$state)
#> [1] "DC"
prop_in(dcv$zip, valid_zip)
#> [1] 1
```

## Conclude

``` r
glimpse(sample_n(dcv, 50))
#> Rows: 50
#> Columns: 21
#> $ reg_date  <date> 2017-09-23, 1983-07-24, 1986-08-19, 2003-10-17, 2012-08-10, 2011-12-10, 2014-…
#> $ last      <chr> "ANDERSON", "MCBRIDE", "CARON-SCHULER", "GUERRERO", "GOLDEN", "HILL", "HILL", …
#> $ first     <chr> "JOHN", "JAMES", "ALEXANDER", "ROLANDO", "IESHA", "SOPHIA", "STEVE", "MICHELLE…
#> $ middle    <chr> "A", "W", NA, NA, "M", "D", "M", "D", NA, "S", "A", "A", "W", "M", NA, "T", "K…
#> $ suffix    <chr> NA, NA, NA, NA, NA, NA, "SR", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ status    <chr> "A", "A", "A", "A", "A", "A", "A", "X", "A", "X", "A", "A", "A", "A", "A", "A"…
#> $ party     <chr> "DEMOCRATIC", "DEMOCRATIC", "DEMOCRATIC", "DEMOCRATIC", "DEMOCRATIC", "DEMOCRA…
#> $ house     <chr> "3100", "5701", "404", "433", "5024", "2645", "1301", "1346", "1230", "1828", …
#> $ frac      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ apt       <chr> "320", NA, NA, NA, NA, "101", "402", "608", NA, "2", NA, "B", "#33", "C", "505…
#> $ street    <chr> "CONNECTICUT AVE NW", "27TH ST NW", "PEABODY ST NE", "KENYON ST NW", "KIMI GRA…
#> $ city      <chr> "WASHINGTON", "WASHINGTON", "WASHINGTON", "WASHINGTON", "WASHINGTON", "WASHING…
#> $ state     <chr> "DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC", …
#> $ zip       <chr> "20008", "20015", "20011", "20010", "20019", "20020", "20005", "20003", "20002…
#> $ zip4      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ precinct  <chr> "26", "52", "65", "38", "104", "134", "17", "131", "78", "14", "19", "16", "40…
#> $ ward      <chr> "3", "4", "4", "1", "7", "8", "2", "6", "5", "2", "5", "2", "1", "8", "5", "6"…
#> $ anc       <chr> "[3C]", "[3G]", "[4B]", "[1A]", "[7E]", "[8B]", "[2F]", "[6D]", "[5D]", "[2B]"…
#> $ smd       <chr> "[3C03]", "[3G02]", "[4B08]", "[1A10]", "[7E04]", "[8B01]", "[2F03]", "[6D07]"…
#> $ dupe_flag <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ reg_year  <dbl> 2017, 1983, 1986, 2003, 2012, 2011, 2014, 2020, 2014, 2020, 2016, 2006, 2009, …
```

1.  There are 503,316 records in the database.
2.  There are 56 duplicate records in the database.
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
clean_dir <- dir_create(here("dc", "voters", "data", "clean"))
clean_path <- path(clean_dir, "dc_voters_clean.csv")
write_csv(dcv, clean_path, na = "")
(clean_size <- file_size(clean_path))
#> 53.6M
file_encoding(clean_path) %>% 
  mutate(across(path, path.abbrev))
#> # A tibble: 1 x 3
#>   path                                                                      mime            charset
#>   <fs::path>                                                                <chr>           <chr>  
#> 1 /home/kiernan/Code/tap/R_campfin/dc/voters/data/clean/dc_voters_clean.csv application/csv us-asc…
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

| Column      | Type        | Definition                              |
| :---------- | :---------- | :-------------------------------------- |
| `reg_date`  | `double`    | Date registered                         |
| `last`      | `character` | Voter last name                         |
| `first`     | `character` | Voter first name                        |
| `middle`    | `character` | Voter middle name                       |
| `suffix`    | `character` | Voter name suffix                       |
| `status`    | `character` | Voter status (Active, Fed, ID Required) |
| `party`     | `character` | Political party                         |
| `house`     | `character` | House number                            |
| `frac`      | `character` | House fraction                          |
| `apt`       | `character` | Apartment number                        |
| `street`    | `character` | Street name                             |
| `city`      | `character` | City name (Washington)                  |
| `state`     | `character` | State (DC)                              |
| `zip`       | `character` | ZIP code                                |
| `zip4`      | `character` | ZIP+4 code                              |
| `precinct`  | `character` | Precinct number                         |
| `ward`      | `character` | Ward number (1-8)                       |
| `anc`       | `character` | Advisory Neighborhood Commission code   |
| `smd`       | `character` | Single Member District code             |
| `dupe_flag` | `logical`   | Flag indicating duplicate record        |
| `reg_year`  | `double`    | Calendar year registered                |
