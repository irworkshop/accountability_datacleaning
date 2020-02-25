Pennsylvania Contributions
================
Kiernan Nicholls
2020-02-24 23:01:19

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
  gluedown, # format markdown
  magrittr, # pipe operators
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  glue, # combine strings
  httr, # make http requests
  here, # relative storage
  fs # search storage 
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
#> [1] "/home/kiernan/Code/accountability_datacleaning/R_campfin"
```

## Data

Data is from the [Pennsylvania Election and Campaign Finance System
(ECF)](https://www.dos.pa.gov/VotingElections/CandidatesCommittees/CampaignFinance/Pages/default.aspx).

The ECF provides a [Full Campaign Finance
Export](https://www.dos.pa.gov/VotingElections/CandidatesCommittees/CampaignFinance/Resources/Pages/FullCampaignFinanceExport.aspx).
From this page, files are organized as annual directories containing
files for contributions, debt, expenditures, filer information, and
receipts.

The ECF also provides a `readme.txt` file, which can be

``` r
pa_host <- "https://www.dos.pa.gov/VotingElections"
pa_dir <- "CandidatesCommittees/CampaignFinance/Resources/Documents"
readme_file <- "readme.txt"
readme_url <- paste(pa_host, pa_dir, readme_file, sep = "/")
```

| col           | type         |
| :------------ | :----------- |
| `filerid`     | VARCHAR(20)  |
| `eyear`       | INT          |
| `cycle`       | INT          |
| `section`     | VARCHAR(10)  |
| `contributor` | VARCHAR(255) |
| `address1`    | VARCHAR(50)  |
| `address2`    | VARCHAR(50)  |
| `city`        | VARCHAR(50)  |
| `state`       | VARCHAR(10)  |
| `zipcode`     | VARCHAR(15)  |
| `occupation`  | VARCHAR(255) |
| `ename`       | VARCHAR(255) |
| `eaddress1`   | VARCHAR(50)  |
| `eaddress2`   | VARCHAR(50)  |
| `ecity`       | VARCHAR(50)  |
| `estate`      | VARCHAR(10)  |
| `ezipcode`    | VARCHAR(15)  |
| `contdate1`   | VARCHAR(20)  |
| `contamt1`    | MONEY        |
| `contdate2`   | VARCHAR(20)  |
| `contamt2`    | MONEY        |
| `contdate3`   | VARCHAR(20)  |
| `contamt3`    | MONEY        |
| `contdesc`    | VARCHAR(500) |

| col         | type         |
| :---------- | :----------- |
| `filerid`   | VARCHAR(20)  |
| `eyear`     | INT          |
| `cycle`     | INT          |
| `ammend`    | VARCHAR(1)   |
| `terminate` | VARCHAR(1)   |
| `filertype` | VARCHAR(10)  |
| `filername` | VARCHAR(255) |
| `office`    | VARCHAR(15)  |
| `district`  | VARCHAR(15)  |
| `party`     | VARCHAR(15)  |
| `address1`  | VARCHAR(50)  |
| `address2`  | VARCHAR(50)  |
| `city`      | VARCHAR(50)  |
| `state`     | VARCHAR(10)  |
| `zipcode`   | VARCHAR(15)  |
| `county`    | VARCHAR(15)  |
| `phone`     | VARCHAR(15)  |
| `beginning` | MONEY        |
| `monetary`  | MONEY        |
| `inkind`    | MONEY        |

## Import

To import the files into R, we will have to first download the annual
ZIP archive file containing all campaign finance transactions. Then we
can extract the contributions file and read them all into a single file
for processing.

### Download

Each ZIP archive is simply named as the 4-digit year for the files
within. We can download each ZIP to the `/data/raw` directory.

``` r
zip_names <- paste(2008:2020, "zip", sep = ".")
zip_urls <- paste(pa_host, pa_dir, zip_names, sep = "/")
raw_dir <- dir_create(here("pa", "contribs", "data", "raw"))
zip_paths <- path(raw_dir, zip_names)
fix_check <- here("pa", "contribs", "data", "fixed.txt")
if (length(dir_ls(raw_dir, regexp = "zip")) < 10) {
  download.file(zip_urls, zip_paths)
  file_delete(fix_check)
}
```

Then we will unzip the annual directory from each archive.

``` r
if (all(dir_ls(raw_dir) %in% zip_paths)) {
  for (zip in zip_paths) {
    unzip(zip, exdir = raw_dir)
  }
}
```

For each year, there is a file for contribution and a file for the
information on the recipients of those contributions, who file the
reports containing the data. We will identify the path of each file type
in new vectors, which can then be read together.

``` r
con_paths <- dir_ls(
  path = raw_dir, 
  recurse = TRUE, 
  regexp = "contrib[\\.|_]"
)

fil_paths <- dir_ls(
  path = raw_dir, 
  recurse = TRUE, 
  regexp = "filer[\\.|_]"
)
```

### Fix

To properly read so many records, we need to first perform some
manipulation of the text files. Each “cell” of character type columns
are surrounded in double quotation marks (`"`) to help prevent
misreading. Howver, some of the text in these cells itself contains
double quotes or newline characters (`\n`).

We need to read each file as a character string and use regular
expressions to identify these erroneous characters and remove or replace
them.

``` r
# do not repeat if done
if (!file_exists(fix_check)) {
  # for all contrib and filer files
  for (file in c(con_paths, fil_paths)) {
    # read raw file
    read_file(file) %>% 
      # force conversion to simple
      str_conv(encoding = "ASCII") %>% 
      # replace non-carriage newline
      str_replace_all("(?<!\r)\n", " ") %>%
      # replace not-field double quotes
      str_replace_all("(?<!^|,|\r\n)\"(?!,|\r\n|$)", "\'") %>% 
      # replace non-delim commas
      str_remove_all(",(?!\"|\\d|\\.\\d+|-(\\d|\\.))") %>% 
      # overwrite raw file
      write_file(file)
    # check progress
    message(paste(basename(file), "done"))
    # clean garbage memory
    gc()
  }
  # note this has done
  file_create(fix_check)
}
```

### Read

Now that each text file has been cleaned of irregularies, they can each
be properly read into R.

If this has already beem done, it’s easier to read the single file that
was written at the end of the initial process. If we read this single
file, we can skip the chunks below reading for the first time.

``` r
pac_files <- path(raw_dir, sprintf("pac%s.csv", 1:10))
no_pac <- !all(file_exists(pac_files))
if (!no_pac) {
  pac <- vroom(
    file = pac_files,
    delim = "|",
    escape_backslash = TRUE, 
    col_names = TRUE,
    col_types = cols(
      filerid = col_double(),
      eyear = col_double(),
      cycle = col_double(),
      date = col_date(),
      amount = col_double(),
      fil_type = col_double(),
      district = col_integer(),
      fil_address2 = col_logical(),
      fil_phone = col_logical()
    )
  )
}
```

First, we will read all the annual contribution files into a single data
frame using `vroom::vroom()`. We need to use the column names and types
listed in the `readme.txt` file we downloaded earlier.

``` r
pac <- map_df(
  .x = con_paths,
  .f = read_delim,
  delim = ",",
  escape_backslash = FALSE, 
  escape_double = FALSE,
  col_names = readme$contribs$col,
  col_types = cols(
    .default = col_skip(),
    filerid = col_character(),
    eyear = col_integer(),
    cycle = col_integer(),
    section = col_character(),
    contributor = col_character(),
    address1 = col_character(),
    address2 = col_character(),
    city = col_character(),
    state = col_character(),
    zipcode = col_character(),
    occupation = col_character(),
    ename = col_character(),
    contdate1 = col_date("%Y%m%d"),
    contamt1 = col_double()
  )
)
```

Then we can read the fixed filers files.

``` r
filers <- map_df(
  .x = fil_paths,
  .f = read_delim,
  delim = ",",
  escape_backslash = FALSE, 
  escape_double = FALSE,
  col_names = readme$filer$col,
  col_types = cols(
    .default = col_skip(),
    eyear = col_integer(),
    filerid = col_character(),
    filertype = col_character(),
    filername = col_character(),
    office = col_character(),
    district = col_character(),
    party = col_character(),
    address1 = col_character(),
    address2 = col_character(),
    city = col_character(),
    state = col_character(),
    zipcode = col_character(),
    county = col_character(),
    phone = col_character(),
  )
)
```

``` r
filers <- filers %>% 
  group_by(filerid, eyear) %>% 
  slice(1) %>% 
  ungroup()
```

``` r
# 13,135,695
pac <- left_join(
  x = pac,
  y = filers,
  by = c("filerid", "eyear"),
  suffix = c("_con", "_fil")
)

rm(filers)

pac <- rename_prefix(
  df = pac,
  suffix = c("_con", "_fil"),
  punct = TRUE
)
```

``` r
pac <- pac %>% 
  rename(
    con_zip = con_zipcode,
    date = contdate1,
    amount = contamt1,
    fil_type = filertype,
    filer = filername,
    fil_zip = fil_zipcode,
    fil_phone = phone
  )
```

We will save a copy of this new file to the disk that can easily be read
if needed.

``` r
n <- 10
x <- nrow(pac)/n
for (i in seq(1, n)) {
  write_delim(
    x = pac[1:x, ],
    path = path(raw_dir, sprintf("pac%s.csv", i)),
    delim = "|",
    quote_escape = "backslash"
  )
  pac <- pac[-(1:x), ]
  gc(full = TRUE)
  Sys.sleep(60)
  message(percent(i/n))
}
```

## Explore

``` r
head(pac)
#> # A tibble: 6 x 27
#>   filerid eyear cycle section contributor con_address1 con_address2 con_city con_state con_zip
#>     <dbl> <dbl> <dbl> <chr>   <chr>       <chr>        <chr>        <chr>    <chr>     <chr>  
#> 1 2000083  2008     4 IB      ROBERT CAR… 6100 LYTLE … <NA>         OKLAHOM… OK        73127  
#> 2 2000083  2008     4 IB      WILLIAM CA… 11 FERRIN P… <NA>         AMARILLO TX        79124  
#> 3 2000083  2008     4 IB      DAVID CARR… 923 LOCUST   <NA>         PEOTONE  IL        60468  
#> 4 2000083  2008     4 IB      MICHAEL CA… 104 KELSEY … <NA>         CLAYTON  NC        27520  
#> 5 2000083  2008     4 IB      TIMOTHY CA… 4516 SARATO… <NA>         LOUISVI… KY        40299  
#> 6 2000083  2008     4 IB      DANIEL CAR… 2601 WOODSD… <NA>         LOUISVI… KY        40220  
#> # … with 17 more variables: occupation <chr>, ename <chr>, date <date>, amount <dbl>,
#> #   fil_type <dbl>, filer <chr>, office <chr>, district <int>, party <chr>, fil_address1 <chr>,
#> #   fil_address2 <lgl>, fil_city <chr>, fil_state <chr>, fil_zip <chr>, county <chr>,
#> #   fil_phone <lgl>, na_flag <lgl>
tail(pac)
#> # A tibble: 6 x 27
#>   filerid eyear cycle section contributor con_address1 con_address2 con_city con_state con_zip
#>     <dbl> <dbl> <dbl> <chr>   <chr>       <chr>        <chr>        <chr>    <chr>     <chr>  
#> 1 9600042  2020     8 ID      JOHN ONDER… 150 PARK AVE <NA>         PORTAGE  PA        15946  
#> 2 9600042  2020     8 ID      CORI DAVIS  2106 W. COV… <NA>         ENOLA    PA        17025  
#> 3 9600042  2020     8 IIG     MATTHEW PL… 228 GREEN L… <NA>         CAMP HI… PA        17011  
#> 4 9600042  2020     8 IIG     DAVID THOM… 1052 BRANDT… <NA>         LEMOYNE  PA        17043  
#> 5 9600087  2020     9 IC      CHESAPEAKE… PO BOX 18496 <NA>         OKLAHOM… OK        73154  
#> 6 9600087  2020     9 IC      NISOURCE I… 290 W. NATI… <NA>         COLUMBUS OH        43215  
#> # … with 17 more variables: occupation <chr>, ename <chr>, date <date>, amount <dbl>,
#> #   fil_type <dbl>, filer <chr>, office <chr>, district <int>, party <chr>, fil_address1 <chr>,
#> #   fil_address2 <lgl>, fil_city <chr>, fil_state <chr>, fil_zip <chr>, county <chr>,
#> #   fil_phone <lgl>, na_flag <lgl>
glimpse(sample_n(pac, 20))
#> Observations: 20
#> Variables: 27
#> $ filerid      <dbl> 9300041, 2002222, 9700229, 20130296, 2002281, 8800318, 2000083, 9000192, 89…
#> $ eyear        <dbl> 2012, 2018, 2010, 2016, 2012, 2011, 2009, 2009, 2013, 2015, 2017, 2014, 201…
#> $ cycle        <dbl> 2, 7, 3, 7, 2, 4, 7, 7, 7, 2, 7, 5, 7, 4, 7, 7, 4, 2, 1, 5
#> $ section      <chr> "IB", "ID", "IB", "ID", "IB", "IB", "IB", "IB", "IB", "ID", "IB", "IA", "IB…
#> $ contributor  <chr> "KATHRYN FREEBORN", "Mark J Denton", "STEVEN BLINN", "Michael  Schubert", "…
#> $ con_address1 <chr> "ONE HEALTH PLAZA", "420 Throckmorton St", "18028 ARTHUR DR", "5995 Windwar…
#> $ con_address2 <chr> NA, "TX1-1329", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ con_city     <chr> "EAST HANOVER", "Fort Worth", "ORLAND PARK", "Alpharetta", "Sherman Oaks", …
#> $ con_state    <chr> "NJ", "TX", "IL", "GA", "CA", "FL", "MD", "TN", "NC", "PA", "ME", "PA", "NC…
#> $ con_zip      <chr> "07936", "761023700", "60467", "300054184", "914033302", "335788349", "2120…
#> $ occupation   <chr> "SR ONCOLOGY SPECIALIST", "Banker", "DIR SALES", "Web Technologist 5", NA, …
#> $ ename        <chr> "NOVARTIS PHARMACEUTICALS", "JPMorgan Chase Bank NA", "NORFOLK SOUTHERN COR…
#> $ date         <date> 2012-04-09, 2018-02-15, 2010-06-07, 2016-05-31, 2012-03-30, 2011-05-13, 20…
#> $ amount       <dbl> 55.38, 63.00, 100.00, 20.83, 31.25, 4.27, 60.00, 16.40, 5.00, 1000.00, 5.00…
#> $ fil_type     <dbl> 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2
#> $ filer        <chr> "Novartis Corporation Political Action Committee", "JPMorgan Chase Co. PAC"…
#> $ office       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "CPJ", NA, "STH", NA, NA, NA, NA, NA, N…
#> $ district     <int> NA, NA, NA, NA, NA, NA, NA, NA, NA, 19, NA, 121, NA, NA, NA, NA, NA, NA, NA…
#> $ party        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "DEM", "OTH", "DEM", NA, NA, NA, NA, NA…
#> $ fil_address1 <chr> "701 Pennsylvania Ave. NW Suite 725", "601 Pennsylvania Avenue NW", "3 COMM…
#> $ fil_address2 <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ fil_city     <chr> "Washington", "Washington", "NORFOLK", "San Francisco", "St. Louis", "Atlan…
#> $ fil_state    <chr> "DC", "DC", "VA", "CA", "MO", "GA", "GA", "DC", "NC", "PA", "DC", "PA", "NC…
#> $ fil_zip      <chr> "20004", "20004", "23510", "94104", "63105", "303132420", "30328", "20036",…
#> $ county       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "67", NA, "40", NA, NA, NA, NA, NA, NA,…
#> $ fil_phone    <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ na_flag      <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
```

### Missing

``` r
col_stats(pac, count_na)
#> # A tibble: 27 x 4
#>    col          class         n          p
#>    <chr>        <chr>     <int>      <dbl>
#>  1 filerid      <dbl>         0 0         
#>  2 eyear        <dbl>         0 0         
#>  3 cycle        <dbl>         0 0         
#>  4 section      <chr>      2857 0.000217  
#>  5 contributor  <chr>        76 0.00000579
#>  6 con_address1 <chr>     63816 0.00486   
#>  7 con_address2 <chr>  11835907 0.901     
#>  8 con_city     <chr>     61948 0.00472   
#>  9 con_state    <chr>     63729 0.00485   
#> 10 con_zip      <chr>     75152 0.00572   
#> 11 occupation   <chr>   7278550 0.554     
#> 12 ename        <chr>   7882675 0.600     
#> 13 date         <date>    12813 0.000975  
#> 14 amount       <dbl>         0 0         
#> 15 fil_type     <dbl>      5844 0.000445  
#> 16 filer        <chr>      1031 0.0000785 
#> 17 office       <chr>  12529715 0.954     
#> 18 district     <int>  12756933 0.971     
#> 19 party        <chr>  10912304 0.831     
#> 20 fil_address1 <chr>    187582 0.0143    
#> 21 fil_address2 <lgl>  13135690 1         
#> 22 fil_city     <chr>    187560 0.0143    
#> 23 fil_state    <chr>    187131 0.0142    
#> 24 fil_zip      <chr>    189422 0.0144    
#> 25 county       <chr>  11876991 0.904     
#> 26 fil_phone    <lgl>  12523087 0.953     
#> 27 na_flag      <lgl>        16 0.00000122
```

``` r
pac <- pac %>% flag_na(date, contributor, amount, filer)
percent(mean(pac$na_flag), 0.01)
#> [1] "0.11%"
```

### Amounts

``` r
summary(pac$amount)
#>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
#>     -5000        10        21       198        72 114201950
mean(pac$amount <= 0)
#> [1] 0.0005163033
```

![](../plots/hist_amount-1.png)<!-- -->

### Dates

``` r
pac <- mutate(pac, year = year(date))
```

``` r
min(pac$date, na.rm = TRUE)
#> [1] "1900-01-16"
sum(pac$year < 2008, na.rm = TRUE)
#> [1] 894
max(pac$date, na.rm = TRUE)
#> [1] "9201-01-12"
sum(pac$date > today(), na.rm = TRUE)
#> [1] 35
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
pac <- pac %>% 
  unite(
    col = con_address_full,
    starts_with("con_address"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    con_address_norm = normal_address(
      address = con_address_full,
      abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-con_address_full)
```

``` r
pac %>% 
  select(contains("address")) %>% 
  distinct() %>% 
  sample_n(10)
#> # A tibble: 10 x 5
#>    con_address1          con_address2    fil_address1     fil_address2 con_address_norm            
#>    <chr>                 <chr>           <chr>            <lgl>        <chr>                       
#>  1 5505 N RIDGE CIR      <NA>            One John Deere … NA           5505 N RDG CIR              
#>  2 13055 Lindsay St.     <NA>            15041 KELVIN AV… NA           13055 LINDSAY ST            
#>  3 2732 ANN STREET       <NA>            213 LEONA AVE    NA           2732 ANN ST                 
#>  4 1608 S RIVER CREEK L… <NA>            60 Boulevard of… NA           1608 S RIV CRK LNDG         
#>  5 437 GRANT ST. STE. 2… FRICK BLDG.     121 S. BROAD ST. NA           437 GRANT ST STE 200 FRICK …
#>  6 ORRICK HERRINGTON &a… 51 WEST 52ND S… PO BOX 2020      NA           ORRICK HERRINGTON ANDAMP SU…
#>  7 2553 MONTROSE ST      <NA>            2217 KIMBALL ST… NA           2553 MONTROSE ST            
#>  8 4115 WOODLYN TER      <NA>            400 N THIRD STR… NA           4115 WOODLYN TER            
#>  9 629 Valley View Road  <NA>            121 S BROAD ST … NA           629 VLY VW RD               
#> 10 2739 Cranston Cir     <NA>            1200 Urban Cent… NA           2739 CRANSTON CIR
```

``` r
pac <- pac %>% 
  unite(
    col = fil_address_full,
    starts_with("fil_address"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    fil_address_norm = normal_address(
      address = fil_address_full,
      abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-fil_address_full)
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
pac <- mutate_at(
  .tbl = pac,
  .vars = vars(ends_with("zip")),
  .funs = list(norm = normal_zip),
  na_rep = TRUE
)
```

``` r
progress_table(
  pac$con_zip,
  pac$con_zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage        prop_in n_distinct prop_na   n_out n_diff
#>   <chr>          <dbl>      <dbl>   <dbl>   <dbl>  <dbl>
#> 1 con_zip        0.440     363880 0.00572 7312896 340929
#> 2 con_zip_norm   0.998      28983 0.00678   22253   2775
```

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

``` r
pac <- mutate_at(
  .tbl = pac,
  .vars = vars(ends_with("state")),
  .funs = list(norm = normal_state),
  abbreviate = TRUE,
  na_rep = TRUE,
  valid = valid_state
)
```

``` r
pac %>% 
  count(con_state, con_state_norm, sort = TRUE) %>% 
  filter(con_state != con_state_norm)
#> # A tibble: 0 x 3
#> # … with 3 variables: con_state <chr>, con_state_norm <chr>, n <int>
```

``` r
progress_table(
  pac$con_state,
  pac$con_state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage          prop_in n_distinct prop_na n_out n_diff
#>   <chr>            <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 con_state         1.00         67 0.00485    17     12
#> 2 con_state_norm    1            56 0.00485     0      1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
pac <- mutate_at(
  .tbl = pac,
  .vars = vars(ends_with("city")),
  .funs = list(norm = normal_city),
  abbs = usps_city,
  states = c("PA", "DC", "PENNSYLVANIA"),
  na = invalid_city,
  na_rep = TRUE
)
```

#### Swap

We can further improve normalization by comparing our normalized value
against the *expected* value for that record’s state abbreviation and
ZIP code. If the normalized value is either an abbreviation for or very
similar to the expected value, we can confidently swap those two.

``` r
pac <- pac %>% 
  left_join(
    y = zipcodes,
    by = c(
      "con_state_norm" = "state",
      "con_zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(con_city_norm, city_match),
    match_dist = str_dist(con_city_norm, city_match),
    con_city_swap = if_else(
      condition = !is.na(match_dist) & match_abb | match_dist == 1,
      true = city_match,
      false = con_city_norm
    )
  ) %>% 
  select(
    -city_match,
    -match_dist,
    -match_abb
  )
```

``` r
pac <- pac %>% 
  left_join(
    y = zipcodes,
    by = c(
      "fil_state_norm" = "state",
      "fil_zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(fil_city_norm, city_match),
    match_dist = str_dist(fil_city_norm, city_match),
    fil_city_swap = if_else(
      condition = !is.na(match_dist) & match_abb | match_dist == 1,
      true = city_match,
      false = fil_city_norm
    )
  ) %>% 
  select(
    -city_match,
    -match_dist,
    -match_abb
  )
```

#### Refine

The \[OpenRefine\] algorithms can be used to group similar strings and
replace the less common versions with their most common counterpart.
This can greatly reduce inconsistency, but with low confidence; we will
only keep any refined strings that have a valid city/state/zip
combination.

``` r
good_refine <- pac %>% 
  mutate(
    con_city_refine = con_city_swap %>% 
      key_collision_merge() %>% 
      n_gram_merge(numgram = 1)
  ) %>% 
  filter(con_city_refine != con_city_swap) %>% 
  inner_join(
    y = zipcodes,
    by = c(
      "con_city_refine" = "city",
      "con_state_norm" = "state",
      "con_zip_norm" = "zip"
    )
  )
```

    #> # A tibble: 307 x 5
    #>    con_state_norm con_zip_norm con_city_swap        con_city_refine            n
    #>    <chr>          <chr>        <chr>                <chr>                  <int>
    #>  1 OH             45202        CINNCINATI           CINCINNATI               112
    #>  2 IN             46184        NEW WHITELAND        WHITELAND                 82
    #>  3 MI             48094        WASHINGTON TW        WASHINGTON                68
    #>  4 SC             29406        NORTH CHARLESTON     CHARLESTON                61
    #>  5 NY             11746        HUNTINGTON SAINT     HUNTINGTON STATION        58
    #>  6 MD             20772        UPPER MARLOBOR       UPPER MARLBORO            57
    #>  7 PA             17036        HUNNMELSTOWN         HUMMELSTOWN               50
    #>  8 IL             61853        MOHAMET              MAHOMET                   48
    #>  9 VA             23454        VIRGNINA BEACH       VIRGINIA BEACH            45
    #> 10 NY             11776        PORT JEFFERSON SAINT PORT JEFFERSON STATION    44
    #> # … with 297 more rows

Then we can join the refined values back to the database.

``` r
pac <- pac %>% 
  left_join(good_refine) %>% 
  mutate(city_refine = coalesce(con_city_refine, con_city_swap))
```

#### Progress

| stage             | prop\_in | n\_distinct | prop\_na |  n\_out | n\_diff |
| :---------------- | -------: | ----------: | -------: | ------: | ------: |
| con\_city         |    0.269 |       39227 |    0.005 | 9558821 |   27609 |
| con\_city\_norm   |    0.976 |       24705 |    0.005 |  312854 |   11420 |
| con\_city\_swap   |    0.984 |       17281 |    0.012 |  204620 |    4004 |
| con\_city\_refine |    1.000 |         211 |    1.000 |       0 |       1 |

You can see how the percentage of valid values increased with each
stage.

``` r
prop_in(pac$con_city_refine, valid_city)
#> [1] 1
prop_in(pac$fil_city_swap, valid_city)
#> [1] 0.9387927
```

![](../plots/bar_progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar_distinct-1.png)<!-- -->

## Conclude

``` r
pac <- pac %>% 
  select(
    -con_city_norm,
    -con_city_swap,
    con_city_clean = con_city_refine
  ) %>% 
  select(
    -fil_city_norm,
    fil_city_clean = fil_city_swap
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean"))
```

``` r
glimpse(sample_n(pac, 20))
#> Observations: 20
#> Variables: 37
#> $ filerid           <dbl> 8600316, 2003062, 2007272, 2005315, 20160286, 2000081, 2008343, 200420…
#> $ eyear             <dbl> 2016, 2008, 2017, 2008, 2017, 2009, 2018, 2019, 2015, 2012, 2016, 2015…
#> $ cycle             <dbl> 4, 4, 5, 1, 7, 7, 4, 7, 2, 7, 4, 3, 7, 6, 7, 7, 7, 4, 7, 7
#> $ section           <chr> "IB", "ID", "IB", "IC", "IB", "ID", "ID", "ID", "IB", "IB", "ID", "ID"…
#> $ contributor       <chr> "Gretchen M Korff", "Paul T Schwab", "Cynthia  Hauer", "EXELON PAC", "…
#> $ con_address1      <chr> "3484 Wedgewood", "1735 Market St. Ste. Ll", "525 Vine Street", "PO BO…
#> $ con_address2      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "OH1-1208", NA, NA, NA…
#> $ con_city          <chr> "Rochester Hills", "Philadelphia", "Cincinnati", "CHICAGO", "RIVERHEAD…
#> $ con_state         <chr> "MI", "PA", "OH", "IL", "NY", "OH", "OK", "CA", "PA", "TX", "PA", "VA"…
#> $ con_zip           <chr> "483063772", "19103", "45202", "60680-537", "11901", "44514", "7300321…
#> $ occupation        <chr> NA, "Mgr Pricing - Marketing", NA, NA, "RETIRED CARRIER", "VP Fossil O…
#> $ ename             <chr> NA, "Sunoco Inc. (r&m)", NA, NA, "USPS", "FirstEnergy", "Chesapeake En…
#> $ date              <date> 2016-09-01, 2008-06-06, 2017-09-29, 2008-02-13, 2017-12-31, 2009-11-2…
#> $ amount            <dbl> 41.76, 62.50, 7.00, 1000.00, 60.00, 192.00, 83.33, 128.85, 21.43, 8.00…
#> $ fil_type          <dbl> 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2
#> $ filer             <chr> "ELI LILLY AND COMPANY POLITICAL ACTION COMMITTEE", "SUN PAC", "Huntin…
#> $ office            <chr> NA, NA, NA, "STS", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ district          <int> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, 186, NA, NA, NA, N…
#> $ party             <chr> NA, NA, NA, "REP", NA, NA, "OTH", NA, NA, NA, "OTH", NA, NA, "DEM", NA…
#> $ fil_address1      <chr> "LILLY CORPORATE CENTER", "1735 MARKET ST  STE LL", "41 S. High Street…
#> $ fil_address2      <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ fil_city          <chr> "INDIANAPOLIS", "PHILADELPHIA", "Columbus", "JONESTOWN", "Washington",…
#> $ fil_state         <chr> "IN", "PA", "OH", "PA", "DC", "OH", "OK", "DC", "PA", "MI", "PA", "VA"…
#> $ fil_zip           <chr> "46285", "19103-7583", "43287", "17038", "20001", "44308", "73154", "2…
#> $ county            <chr> NA, NA, NA, "38", NA, NA, NA, NA, NA, NA, NA, NA, NA, "51", NA, NA, "0…
#> $ fil_phone         <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ na_flag           <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
#> $ year              <dbl> 2016, 2008, 2017, 2008, 2017, 2009, 2018, 2019, 2015, 2012, 2016, 2015…
#> $ con_address_clean <chr> "3484 WEDGEWOOD", "1735 MARKET ST STE LL", "525 VINE ST", "PO BOX 8053…
#> $ fil_address_clean <chr> "LILLY CORPORATE CTR NA", "1735 MARKET ST STE LL NA", "41 S HIGH ST NA…
#> $ con_zip_clean     <chr> "48306", "19103", "45202", "60680", "11901", "44514", "73003", "91320"…
#> $ fil_zip_clean     <chr> "46285", "19103", "43287", "17038", "20001", "44308", "73154", "20005"…
#> $ con_state_clean   <chr> "MI", "PA", "OH", "IL", "NY", "OH", "OK", "CA", "PA", "TX", "PA", "VA"…
#> $ fil_state_clean   <chr> "IN", "PA", "OH", "PA", "DC", "OH", "OK", "DC", "PA", "MI", "PA", "VA"…
#> $ fil_city_clean    <chr> "INDIANAPOLIS", "PHILADELPHIA", "COLUMBUS", "JONESTOWN", "WASHINGTON",…
#> $ con_city_clean    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ city_refine       <chr> "ROCHESTER HILLS", "PHILADELPHIA", "CINCINNATI", "CHICAGO", "RIVERHEAD…
```

1.  There are 13,135,742 records in the database.
2.  The range and distribution of `amount` and `date` seem reasonable.
3.  There are 0.11% records missing key variables.
4.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
5.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
clean_dir <- dir_create(here("pa", "contribs", "data", "clean"))
```

``` r
write_csv(
  x = pac,
  path = path(clean_dir, "pa_contribs_clean.csv"),
  na = ""
)
```
