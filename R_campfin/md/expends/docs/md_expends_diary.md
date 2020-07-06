Maryland Expenditures
================
Kiernan Nicholls
2020-07-01 16:33:19

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Download](#download)
  - [Convert](#convert)
  - [Read](#read)
  - [Explore](#explore)
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
pacman::p_load_gh("irworkshop/campfin")
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  gluedown, # printing markdown
  magrittr, # pipe operators
  janitor, # clean data frames
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
#> [1] "/home/kiernan/Code/accountability_datacleaning/R_campfin"
```

## Data

Data is taken from the [Maryland Campaign Reporting Information
System](https://campaignfinance.maryland.gov/Home/Logout).

As explained by this [CRIS help
page](https://campaignfinance.maryland.gov/home/viewpage?title=View%20Expenditures%20/%20Outstanding%20Obligations&link=Public/ViewExpenses):

> ## General Information on Expenditures and Outstanding Obligations
> 
> An ***expenditure*** is defined as a gift, transfer, disbursement, or
> promise of money or valuable thing by or on behalf of a political
> committee to promote or assist in promoting the success or defeat of a
> candidate, political party, or question at an election.
> 
> Expenditures must be election related; that is, they must enhance the
> candidates election chances, such that they would not have been
> incurred if there had been no candidacy. Furthermore, expenditures,
> including loans, may not be for the personal use of the candidate or
> any other individual.
> 
> An outstanding obligation is any unpaid debt that the committee has
> incurred at the end of a reporting period.

## Download

``` r
raw_dir <- dir_create(here("md", "expends", "data", "raw"))
raw_path <- path(raw_dir, "ExpenseInfo.xls")
raw_gone <- !file_exists(raw_path)
```

To download a copy of the search results locally, we can first `POST()`
our form information, leaving everything blank but a start date. This is
the same as filling out the form manually on the website and clicking
“Search”.

``` r
md_post <- POST(
  url = "https://campaignfinance.maryland.gov/Public/OtherSearch?theme=vista",
  body = list(
    txtPayeeLastName = "",
    txtPayeeFirstName = "",
    ddlPayeeType = "",
    MemberId = "",
    txtRegistrant = "",
    CommitteeType = "",
    txtStreet = "",
    txtTown = "",
    ddlState = "",
    txtZipCode = "",
    txtZipExt = "",
    ddlCountyofResidences = "",
    ddlExpenCategory = "",
    ddlExpensePurpose = "",
    FilingYear = "",
    FilingPeriodName = "",
    ddlFundType = "",
    dtStartDate = "01/01/2005",
    dtEndDate = format(today(), "%m/%d/%Y"),
    txtAmountfrom = "",
    txtAmountto = "",
    Submit = "Search"
  )
)
```

From this `POST()`, we can extract the cookies needed to then submit the
corresponding `GET()` request, essentially telling the server to then
click the “Export” button on our previously searched results.

``` r
md_cookie <- cookies(md_post)$value
names(md_cookie) <- cookies(md_post)$name
```

While we *could* export to a CSV file, the formatting they use has no
quotation escapes which makes it difficult to read the entire file
properly. While more troublesome than CSV, we can export as a Microsoft
Excel file and then *convert* that file to CSV.

``` r
md_get <- GET(
  url = "https://campaignfinance.maryland.gov/Public/ExportExpensestoExcel",
  set_cookies(md_cookie),
  write_disk(raw_path, overwrite = TRUE),
  query = list(
    page = "1",
    orderBy = "~",
    filter = "~",
    `Grid-size` = "15",
    theme = "vista"
  )
)
```

This `GET()` created a local file.

``` r
file_info(raw_path) %>% 
  select(path, size, modification_time) %>% 
  mutate(across(path, path.abbrev))
#> # A tibble: 1 x 3
#>   path                                         size modification_time  
#>   <chr>                                 <fs::bytes> <dttm>             
#> 1 ~/md/expends/data/raw/ExpenseInfo.xls        206M 2020-07-01 15:42:36
```

## Convert

The `libreoffice` command is a free, open-source alternative to
Microsoft Office. We can run the program headless-ly (without a GUI) and
convert the file.

``` bash
sudo apt install libreoffice
libreoffice --headless --convert-to csv path.xsl --outdir /tmp/
```

``` r
libre_convert(raw_path, raw_dir)
```

``` r
raw_convert <- dir_ls(raw_dir, glob = "*.csv")
```

## Read

``` r
mde <- vroom(
  file = raw_convert,
  delim = ",",
  quote = "\"",
  escape_backslash = FALSE,
  escape_double = FALSE,
  guess_max = 0,
  num_threads = 1,
  col_types = cols(
    .default = col_character(),
    `Expenditure Date` = col_date("%m/%d/%Y"),
    `Amount($)` = col_double()
  )
)
```

The read data frame should have the same number of rows as results
returned from the CRIS web portal, which we’ll have to check manually.
We can also count the distinct values of a discrete variable like
`method`.

``` r
nrow(mde) # 668245 from search
#> [1] 667722
count(mde, method, sort = TRUE)
#> # A tibble: 9 x 2
#>   method                n
#>   <chr>             <int>
#> 1 <NA>             276297
#> 2 Check            238564
#> 3 EFT               84174
#> 4 Debit Card        51737
#> 5 Electronic Check   7153
#> 6 Cash               5660
#> 7 Wire Transfer      3280
#> 8 Credit Card         613
#> 9 Money Order         244
```

## Explore

``` r
glimpse(mde)
#> Rows: 667,722
#> Columns: 13
#> $ date      <date> 2010-08-05, 2010-03-12, 2010-09-13, 2010-10-18, 2010-10-20, 2006-12-16, 2010-…
#> $ payee     <chr> "Scott Block", "Michael N Stavlas", "Erik Robey", "Erik Robey", "Robert Bradsh…
#> $ address   <chr> "6333 Morning Time Lane, Columbia, MD 21044", "615 Shipley Road, Linthicum, MD…
#> $ type      <chr> "Individual", "Individual", "Individual", "Individual", "Individual", "Individ…
#> $ amount    <dbl> 500.00, 4000.00, 1090.00, 2473.80, 1500.00, 1304.33, 60.00, 14.95, 1000.00, 10…
#> $ committee <chr> "Leopold, John Campaign Committee", "Leopold, John Campaign Committee", "Leopo…
#> $ category  <chr> "Media", "Return Contributions", "Other Expenses", "Other Expenses", "Return C…
#> $ purpose   <chr> "Media", "Return Contributions", "Other", "Other", "Return Contributions", "Pu…
#> $ toward    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ method    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "Check…
#> $ vendor    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ fundtype  <chr> "Electoral", "Electoral", "Electoral", "Electoral", "Electoral", "Electoral", …
#> $ comments  <chr> "Website development", "Charged with illegal immigration violations", "reimbur…
tail(mde)
#> # A tibble: 6 x 13
#>   date       payee address type  amount committee category purpose toward method vendor fundtype
#>   <date>     <chr> <chr>   <chr>  <dbl> <chr>     <chr>    <chr>   <chr>  <chr>  <chr>  <chr>   
#> 1 2016-10-26 Fait… 500 N.… Busi…  239.  Fraley, … Printin… Printi… <NA>   <NA>   <NA>   Elector…
#> 2 2016-10-26 Fait… 500 N.… Busi…  239.  Fraley, … Printin… Printi… <NA>   <NA>   <NA>   Elector…
#> 3 2016-10-26 Fait… 500 N.… Busi…  564.  Fraley, … Printin… Billbo… <NA>   <NA>   <NA>   Elector…
#> 4 2016-10-26 Fait… 500 N.… Busi…  384.  Fraley, … Other E… Billbo… <NA>   <NA>   <NA>   Elector…
#> 5 2016-10-26 Fait… 500 N.… Busi…   92.3 Fraley, … Printin… Printi… <NA>   <NA>   <NA>   Elector…
#> 6 2016-11-07 WCBC… PO Box… Busi…   75   Fraley, … Media    Radio   <NA>   Check  <NA>   Elector…
#> # … with 1 more variable: comments <chr>
```

### Missing

``` r
col_stats(mde, count_na)
#> # A tibble: 13 x 4
#>    col       class       n       p
#>    <chr>     <chr>   <int>   <dbl>
#>  1 date      <date>      0 0      
#>  2 payee     <chr>    1648 0.00247
#>  3 address   <chr>   23741 0.0356 
#>  4 type      <chr>       0 0      
#>  5 amount    <dbl>       0 0      
#>  6 committee <chr>       0 0      
#>  7 category  <chr>       0 0      
#>  8 purpose   <chr>   11285 0.0169 
#>  9 toward    <chr>  666201 0.998  
#> 10 method    <chr>  276297 0.414  
#> 11 vendor    <chr>  624340 0.935  
#> 12 fundtype  <chr>    3080 0.00461
#> 13 comments  <chr>  274978 0.412
```

``` r
mde <- mutate(mde, payee = coalesce(payee, vendor))
mde <- mde %>% flag_na(date, payee, amount, committee)
percent(mean(mde$na_flag), 0.01)
#> [1] "0.25%"
```

``` r
mde %>% 
  filter(na_flag) %>% 
  select(date, payee, amount, committee)
#> # A tibble: 1,648 x 4
#>    date       payee amount committee                                        
#>    <date>     <chr>  <dbl> <chr>                                            
#>  1 2010-07-12 <NA>   5000  Busch, Mike Friends Of                           
#>  2 2008-02-25 <NA>    150  MSEA's Fund For Children And Public Education PAC
#>  3 2008-03-20 <NA>    403. MSEA's Fund For Children And Public Education PAC
#>  4 2008-03-31 <NA>    255  MSEA's Fund For Children And Public Education PAC
#>  5 2008-03-31 <NA>   1000  MSEA's Fund For Children And Public Education PAC
#>  6 2008-03-31 <NA>    200  MSEA's Fund For Children And Public Education PAC
#>  7 2008-05-05 <NA>    140  MSEA's Fund For Children And Public Education PAC
#>  8 2008-02-25 <NA>    150  MSEA's Fund For Children And Public Education PAC
#>  9 2008-03-20 <NA>    403. MSEA's Fund For Children And Public Education PAC
#> 10 2008-03-31 <NA>    255  MSEA's Fund For Children And Public Education PAC
#> # … with 1,638 more rows
```

``` r
mde %>% 
  filter(na_flag) %>% 
  select(date, payee, amount, committee) %>% 
  col_stats(count_na)
#> # A tibble: 4 x 4
#>   col       class      n     p
#>   <chr>     <chr>  <int> <dbl>
#> 1 date      <date>     0     0
#> 2 payee     <chr>   1648     1
#> 3 amount    <dbl>      0     0
#> 4 committee <chr>      0     0
```

### Duplicates

``` r
d1 <- duplicated(mde, fromLast = FALSE)
d2 <- duplicated(mde, fromLast = TRUE)
mde <- mutate(mde, dupe_flag = d1 | d2)
percent(mean(mde$dupe_flag), 0.01)
#> [1] "2.51%"
rm(d1, d2); flush_memory()
```

``` r
mde %>% 
  filter(dupe_flag) %>% 
  select(date, payee, amount, committee)
#> # A tibble: 16,778 x 4
#>    date       payee                     amount committee                                       
#>    <date>     <chr>                      <dbl> <chr>                                           
#>  1 2014-12-22 Constant Contact             95  Carr, Alfred Friends Of                         
#>  2 2014-12-22 Constant Contact             95  Carr, Alfred Friends Of                         
#>  3 2014-03-11 JOSEPH MICHAEL STANALONIS     0  Stanalonis, Joe Committee To Elect              
#>  4 2014-03-11 JOSEPH MICHAEL STANALONIS     0  Stanalonis, Joe Committee To Elect              
#>  5 2014-03-11 JOSEPH MICHAEL STANALONIS     0  Stanalonis, Joe Committee To Elect              
#>  6 2014-04-26 Vic Bernson                   0  Bernson, Vic For Maryland                       
#>  7 2014-04-26 Vic Bernson                   0  Bernson, Vic For Maryland                       
#>  8 2015-06-26 LAURIE SEARS DEPPA            0  Deppa, Laurie Sears The Committee to Elect      
#>  9 2014-09-28 Kipke, Nic Friends of      1000  State Farm Agents And Associates Of Maryland PAC
#> 10 2007-01-06 BuzzMaker, LLC             5058. Dixon, Sheila Friends For                       
#> # … with 16,768 more rows
```

A significant amount of these duplicate values have an `amount` of zero.

``` r
mean(mde$amount == 0, na.rm = TRUE)
#> [1] 0.01255013
mean(mde$amount[mde$dupe_flag] == 0, na.rm = TRUE)
#> [1] 0.2282155
```

### Categorical

``` r
col_stats(mde, n_distinct)
#> # A tibble: 15 x 4
#>    col       class       n          p
#>    <chr>     <chr>   <int>      <dbl>
#>  1 date      <date>   5636 0.00844   
#>  2 payee     <chr>  115742 0.173     
#>  3 address   <chr>  147581 0.221     
#>  4 type      <chr>      21 0.0000315 
#>  5 amount    <dbl>   89275 0.134     
#>  6 committee <chr>    5398 0.00808   
#>  7 category  <chr>      19 0.0000285 
#>  8 purpose   <chr>     106 0.000159  
#>  9 toward    <chr>     116 0.000174  
#> 10 method    <chr>       9 0.0000135 
#> 11 vendor    <chr>   11487 0.0172    
#> 12 fundtype  <chr>       3 0.00000449
#> 13 comments  <chr>  183807 0.275     
#> 14 na_flag   <lgl>       2 0.00000300
#> 15 dupe_flag <lgl>       2 0.00000300
```

``` r
explore_plot(mde, type)
```

![](../plots/distinct_plots-1.png)<!-- -->

``` r
explore_plot(mde, category) + scale_x_truncate()
```

![](../plots/distinct_plots-2.png)<!-- -->

``` r
explore_plot(mde, purpose) + scale_x_truncate()
```

![](../plots/distinct_plots-3.png)<!-- -->

``` r
explore_plot(mde, method)
```

![](../plots/distinct_plots-4.png)<!-- -->

``` r
explore_plot(mde, fundtype)
```

![](../plots/distinct_plots-5.png)<!-- -->

### Amounts

``` r
summary(mde$amount)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>  -14000      40     150    1266     500 5019519
mean(mde$amount <= 0)
#> [1] 0.01311624
```

![](../plots/hist_amount-1.png)<!-- -->

### Dates

We can add the calendar year from `date` with `lubridate::year()`

``` r
mde <- mutate(mde, year = year(date))
```

``` r
min(mde$date)
#> [1] "2005-01-01"
sum(mde$year < 2000)
#> [1] 0
max(mde$date)
#> [1] "2020-06-30"
sum(mde$date > today())
#> [1] 0
```

![](../plots/bar_year-1.png)<!-- -->

## Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are tailor made to facilitate this process.

The `address` variable contains all geographic information in a single
string.

``` r
md_bullet(head(mde$address))
```

  - 6333 Morning Time Lane, Columbia, MD 21044
  - 615 Shipley Road, Linthicum, MD 21090
  - 7654 Bush Avenue, Pasadena, MD 21122
  - 7654 Bush Avenue, Pasadena, MD 21122
  - P.O. Box 36, Edgewater, MD 21037
  - One Dell Way, Round Rock, TX 78682

By using `tidyr::separate()` and `tidyr::unite()`, we can split this
single string into it’s component pieced in new variables ending in
`_sep`.

``` r
mde <- mde %>% 
  separate(
    col = address,
    into = c(glue("addr_sep{1:10}"), "city_sep", "state_zip"),
    sep = ",\\s",
    remove = FALSE,
    fill = "left",
    extra = "merge"
  ) %>% 
  unite(
    starts_with("addr_sep"),
    col = "addr_sep",
    sep = " ",
    na.rm = TRUE,
    remove = TRUE
  ) %>% 
  mutate(across(where(is.character), na_if, "")) %>%
  separate(
    col = state_zip,
    into = c("state_sep", "zip_sep"),
    sep = "\\s(?=\\d|-|x)",
    remove = TRUE,
    fill = "right"
  )
```

### Address

For the street `addresss` variable, the `campfin::normal_address()`
function will force consistence case, remove punctuation, and abbreviate
official USPS suffixes.

``` r
mde <- mde %>% 
  mutate(
    addr_norm = normal_address(
      address = addr_sep,
      abbs = usps_street,
      na_rep = TRUE
    )
  )
```

``` r
mde %>% 
  select(contains("addr_")) %>% 
  distinct() %>% 
  sample_n(10)
#> # A tibble: 10 x 2
#>    addr_sep                      addr_norm              
#>    <chr>                         <chr>                  
#>  1 170 Frank Custer Drive        170 FRANK CUSTER DR    
#>  2 550 Highland Street Suite 115 550 HIGHLAND ST STE 115
#>  3 123 W. Edgevale Rd            123 W EDGEVALE RD      
#>  4 P.O. BOX 1991                 PO BOX 1991            
#>  5 1220 Race Street              1220 RACE ST           
#>  6 PO Box 1661                   PO BOX 1661            
#>  7 5th St.                       5 TH ST                
#>  8 1609 Virginia St.             1609 VIRGINIA ST       
#>  9 158 Main St                   158 MAIN ST            
#> 10 10710 Tucker Street           10710 TUCKER ST
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
mde <- mde %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip_sep,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  mde$zip_sep,
  mde$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 zip_sep    0.930      10600  0.0572 43997   5944
#> 2 zip_norm   0.997       5455  0.0578  1894    622
```

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

``` r
mde <- mde %>% 
  mutate(
    state_norm = normal_state(
      state = state_sep,
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = NULL
    )
  )
```

``` r
mde %>% 
  filter(state_sep != state_norm) %>% 
  count(state_sep, state_norm, sort = TRUE)
#> # A tibble: 121 x 3
#>    state_sep            state_norm      n
#>    <chr>                <chr>       <int>
#>  1 Maryland             MD         136169
#>  2 California           CA          19421
#>  3 District Of Columbia DC           7987
#>  4 Massachusetts        MA           6229
#>  5 Virginia             VA           4130
#>  6 Pennsylvania         PA           3703
#>  7 New York             NY           2641
#>  8 Texas                TX           2556
#>  9 Ohio                 OH           2545
#> 10 Louisiana            LA           1726
#> # … with 111 more rows
```

``` r
progress_table(
  mde$state_sep,
  mde$state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage      prop_in n_distinct prop_na  n_out n_diff
#>   <chr>        <dbl>      <dbl>   <dbl>  <dbl>  <dbl>
#> 1 state_sep    0.685        227  0.0356 202620    172
#> 2 state_norm   0.999        148  0.0356    541     92
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
mde <- mde %>% 
  mutate(
    city_norm = normal_city(
      city = city_sep, 
      abbs = usps_city,
      states = c("MD", "DC", "MARYLAND"),
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
mde <- mde %>% 
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
good_refine <- mde %>% 
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

    #> # A tibble: 93 x 5
    #>    state_norm zip_norm city_swap         city_refine         n
    #>    <chr>      <chr>    <chr>             <chr>           <int>
    #>  1 MD         21042    EILLOTT CITY      ELLICOTT CITY      19
    #>  2 CA         94105    SAN FRANSICO      SAN FRANCISCO      13
    #>  3 OH         45209    CINCINATTI        CINCINNATI         10
    #>  4 MD         20785    HYSTTAVILLE       HYATTSVILLE         9
    #>  5 MD         21784    SKYEVILLE         SYKESVILLE          9
    #>  6 AZ         85038    PHONIEX           PHOENIX             8
    #>  7 CA         94103    SAN FRANSICO      SAN FRANCISCO       8
    #>  8 MD         21666    SETEVENSILLE      STEVENSVILLE        7
    #>  9 MD         21794    WEST FRIENDERSHIP WEST FRIENDSHIP     7
    #> 10 MD         21201    BALTIMORE CO      BALTIMORE           6
    #> # … with 83 more rows

Then we can join the refined values back to the database.

``` r
mde <- mde %>% 
  left_join(good_refine) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

``` r
many_city <- c(valid_city, extra_city)
mde %>% 
  filter(city_refine %out% many_city) %>% 
  count(city_refine, sort = TRUE)
#> # A tibble: 1,107 x 2
#>    city_refine         n
#>    <chr>           <int>
#>  1 <NA>            32317
#>  2 PRINCE GEORGES    942
#>  3 ANNE ARUNDEL      459
#>  4 BALTIMORE CITY    455
#>  5 BALTO             317
#>  6 BERWYN HEIGHTS    297
#>  7 BALTIMORE CO      292
#>  8 COLMAR MANOR      188
#>  9 DC                173
#> 10 MOUNT LAKE PARK   122
#> # … with 1,097 more rows
```

``` r
mde <- mde %>% 
  mutate(
    city_refine = city_refine %>% 
      str_replace("^DC$", "WASHINGTON") %>% 
      str_replace("^BALTO$", "BALTIMORE") %>% 
      str_replace("^BALTIMORE CITY$", "BALTIMORE") %>% 
      str_replace("^BALTIMORE CO$", "BALTIMORE") %>% 
      str_replace("^BALTIMORE CO$", "BALTIMORE")
  )
```

``` r
many_city <- c(many_city, "COLMAR MANOR", "ANNE ARUNDEL", "PRINCE GEORGES")
```

| stage        | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :----------- | -------: | ----------: | -------: | -----: | ------: |
| city\_sep)   |    0.959 |        5378 |    0.047 |  25922 |    3001 |
| city\_norm   |    0.970 |        4890 |    0.048 |  18944 |    2485 |
| city\_swap   |    0.989 |        3560 |    0.048 |   6833 |    1174 |
| city\_refine |    0.992 |        3485 |    0.048 |   5305 |    1100 |

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
mde <- mde %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine,
    -ends_with("_sep")
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  rename_all(~str_remove(., "_raw"))
```

``` r
glimpse(sample_n(mde, 20))
#> Rows: 20
#> Columns: 20
#> $ date        <date> 2013-10-30, 2014-02-16, 2011-08-08, 2007-10-24, 2017-05-05, 2018-08-13, 201…
#> $ payee       <chr> "AT&T", "La Cucina", "United States Postal Service", "Diane Fink", "M&T Bank…
#> $ address     <chr> NA, "103 N. Washington St., Havre de Grace, MD 21078", NA, "11025 Gray Marsh…
#> $ type        <chr> "Reimburse", "Business/Group/Organization", "Business/Group/Organization", "…
#> $ amount      <dbl> 11.20, 664.48, 1320.00, 50.00, 5.00, 12.00, 1.67, 27.15, 600.00, 200.00, 34.…
#> $ committee   <chr> "Gansler, Doug Friends Of", "Smith, Joseph C Citizens for", "Klausmeier, Kat…
#> $ category    <chr> "Rent and Other Office expenses", "Fund Raiser", "Postage", "Fund Raiser", "…
#> $ purpose     <chr> "Utilities - Phone / Cell Phone", "Fundraiser - Food & Beverage", "Postage",…
#> $ toward      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ method      <chr> "Check", "Check", "Check", NA, "EFT", "EFT", "EFT", NA, "Debit Card", "Check…
#> $ vendor      <chr> "AT&T", NA, NA, NA, NA, NA, NA, NA, NA, NA, "Alfred Carr", NA, NA, "Quarry H…
#> $ fundtype    <chr> "Electoral", "Electoral", "Electoral", "Electoral", "Electoral", "Administra…
#> $ comments    <chr> "Phone cards", "Food and Beverage for Campaign Kickoff", NA, "Reimbursement …
#> $ na_flag     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ dupe_flag   <lgl> TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
#> $ year        <dbl> 2013, 2014, 2011, 2007, 2017, 2018, 2017, 2006, 2016, 2016, 2016, 2010, 2012…
#> $ addr_clean  <chr> NA, "103 N WASHINGTON ST", NA, "11025 GRAY MARSH PLACE", "25 S CHARLES ST", …
#> $ zip_clean   <chr> NA, "21078", NA, "21754", "21201", "95054", "94107", "21404", "21401", "2122…
#> $ state_clean <chr> NA, "MD", NA, "MD", "MD", "CA", "CA", "MD", "MD", "MD", "MD", "MD", "MD", NA…
#> $ city_clean  <chr> NA, "HAVRE DE GRACE", NA, "IJAMSVILLE", "BALTIMORE", "SANTA CLARA", "SAN FRA…
```

1.  There are 667,782 records in the database.
2.  There are 16,838 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 1,648 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("md", "expends", "data", "clean"))
clean_path <- path(clean_dir, "md_expends_clean.csv")
write_csv(mde, clean_path, na = "")
file_size(clean_path)
#> 168M
file_encoding(clean_path) %>% 
  mutate(across(path, path.abbrev))
#> # A tibble: 1 x 3
#>   path                                         mime                     charset
#>   <chr>                                        <chr>                    <chr>  
#> 1 ~/md/expends/data/clean/md_expends_clean.csv application/octet-stream binary
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

## Dictionary

The following table describes the variables in our final exported file:

| Column        | Original name      | Type        | Definition                                    |
| :------------ | :----------------- | :---------- | :-------------------------------------------- |
| `date`        | `Expenditure Date` | `double`    | Date expenditure was made                     |
| `payee`       | `Payee Name`       | `character` | Payee name                                    |
| `address`     | `Address`          | `character` | Payee full address                            |
| `type`        | `Payee Type`       | `character` | Payee type                                    |
| `amount`      | `Amount($)`        | `double`    | Expenditure amount or correction              |
| `committee`   | `Committee Name`   | `character` | Spending committee name                       |
| `category`    | `Expense Category` | `character` | Expenditure category                          |
| `purpose`     | `Expense Purpose`  | `character` | Expenditure method                            |
| `toward`      | `Expense Toward`   | `character` | Expenditure purpose                           |
| `method`      | `Expense Method`   | `character` | Expenditure helping other committee           |
| `vendor`      | `Vendor`           | `character` | Payee vendor name (unused)                    |
| `fundtype`    | `Fundtype`         | `character` | Funds source type (Electoral, Administrative) |
| `comments`    | `Comments`         | `character` | Freeform comment text                         |
| `na_flag`     |                    | `logical`   | Flag for missing date, amount, or name        |
| `dupe_flag`   |                    | `logical`   | Flag for completely duplicated record         |
| `year`        |                    | `double`    | Calendar year of contribution date            |
| `addr_clean`  |                    | `character` | Normalized combined street address            |
| `zip_clean`   |                    | `character` | Normalized 5-digit ZIP code                   |
| `state_clean` |                    | `character` | Normalized 2-digit state abbreviation         |
| `city_clean`  |                    | `character` | Normalized city name                          |
