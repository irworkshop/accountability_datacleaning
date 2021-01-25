Alaska Contributions
================
Kiernan Nicholls
2021-01-25 11:29:17

-   [Project](#project)
-   [Objectives](#objectives)
-   [Packages](#packages)
-   [Data](#data)
-   [Download](#download)
-   [Read](#read)
-   [Explore](#explore)
-   [Wrangle](#wrangle)
-   [Conclude](#conclude)
-   [Export](#export)
-   [Upload](#upload)

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
  magrittr, # pipe operators
  janitor, # dataframe clean
  aws.s3, # upload to aws s3
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  glue, # combine strings
  httr, # http requests
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
#> [1] "/home/kiernan/Code/tap/R_tap"
```

## Data

Data is obtained from the [Alaska Public Offices Commission
(APOC)](https://aws.state.ak.us/ApocReports/Campaign/#).

## Download

Using the [APOC income
search](https://aws.state.ak.us/ApocReports/CampaignDisclosure/CDIncome.aspx),
we need to search for “All Completed Forms”, “Any Names”, and “Any”
type, “Filed *After*” the last update of this data. In this case, that
is September 30, 2020.

``` r
raw_dir <- dir_create(here("ak", "contribs", "data", "raw"))
raw_new <- path(raw_dir, "CD_Transactions_Recent.CSV")
file_size(raw_new)
#> 6.92M
```

## Read

The exported delimited text files have two aspects we need to adjust
for; 1) There is a column called `--------` that is empty in every file,
and 2) there is an extra comma at the end of each line. We can read this
extra column at the end as a new `null` column.

``` r
ak_names <- make_clean_names(read_names(raw_new))
```

All the files can be read into a single data frame using
`vroom::vroom()`.

``` r
akc <- vroom(
  file = raw_new,
  skip = 1,
  delim = ",",
  id = "file",
  num_threads = 1,
  na = c("", "NA", "N/A"),
  escape_double = FALSE,
  escape_backslash = FALSE,
  col_names = c(ak_names, "null"),
  col_types = cols(
    .default = col_character(),
    date = col_date_usa(),
    amount = col_number(),
    report_year = col_integer(),
    submitted = col_date_usa(),
    null = col_logical()
  )
)
```

We successfully read the same number of rows as search results.

``` r
nrow(akc) == 1411206
#> [1] FALSE
```

100% of rows have an “Income” type.

``` r
count(akc, tran_type)
#> # A tibble: 1 x 2
#>   tran_type     n
#>   <chr>     <int>
#> 1 Income    27596
```

## Explore

There are 27,596 rows of 26 columns.

``` r
glimpse(akc)
#> Rows: 27,596
#> Columns: 26
#> $ id            <chr> "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14",…
#> $ date          <date> 2020-10-31, 2020-10-25, 2020-12-31, 2020-12-13, 2020-10-01, 2020-10-01, 2…
#> $ tran_type     <chr> "Income", "Income", "Income", "Income", "Income", "Income", "Income", "Inc…
#> $ pay_type      <chr> "Bank Interest", "Electronic Funds Transfer", "Check", "Bank Interest", "C…
#> $ pay_detail    <chr> NA, NA, "3013", NA, "0093", NA, "Family Vehicle", "Family Computer & Print…
#> $ amount        <dbl> 0.04, 8.99, 350.00, 0.03, 250.00, 250.00, 297.00, 55.00, 55.00, 55.00, 8.2…
#> $ last          <chr> "Alaska USA Federal Credit Union", "Zoom USA", "ABCAlaskaPAC", "MVFCU", "M…
#> $ first         <chr> NA, NA, NA, NA, "Rynnieva", "James", "Bart", "Bart", "Bart", "Bart", "Bart…
#> $ address       <chr> "PO Box 241504", "888-799-9666", "301 Arctic Slope Ave. Suite 100", "1020 …
#> $ city          <chr> "Anchorage", "San Jose", "Anchorage", "Palmer", "Fairbanks", "Fairbanks", …
#> $ state         <chr> "Alaska", "California", "Alaska", "Alaska", "Alaska", "Alaska", "Alaska", …
#> $ zip           <chr> "99524", "none", "99518", "99645", "99711", "99709", "99709", "99709", "99…
#> $ country       <chr> "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA…
#> $ occupation    <chr> NA, NA, "N/a", NA, "Legislative Aide", "Manager", "State Legislator", "Sta…
#> $ employer      <chr> NA, NA, "N/a", NA, "Alaska State Senate", "Fairbanks Economic Development …
#> $ purpose       <chr> NA, "Refund", NA, NA, NA, NA, "Used for Campaign Activities", "Used for Ca…
#> $ report_type   <chr> "Thirty Day Report", "Thirty Day Report", "Year Start Report", "Year Start…
#> $ election_name <chr> "2020 - State General Election", "2020 - State General Election", "2020 - …
#> $ election_type <chr> "State General", "State General", "State Primary", "State Primary", "State…
#> $ municipality  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ office        <chr> NA, NA, "House", "House", "House", "House", "House", "House", "House", "Ho…
#> $ filer_type    <chr> "Group", "Group", "Candidate", "Candidate", "Candidate", "Candidate", "Can…
#> $ filer         <chr> "Abbott Loop Democrats", "Abbott Loop Democrats", "George Rauscher", "Geor…
#> $ report_year   <int> 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 20…
#> $ submitted     <date> 2020-10-12, 2020-10-12, 2020-08-11, 2020-08-11, 2020-10-05, 2020-10-05, 2…
#> $ file          <chr> "CD_Transactions_Recent.CSV", "CD_Transactions_Recent.CSV", "CD_Transactio…
head(akc)
#> # A tibble: 6 x 26
#>   id    date       tran_type pay_type pay_detail amount last  first address city  state zip  
#>   <chr> <date>     <chr>     <chr>    <chr>       <dbl> <chr> <chr> <chr>   <chr> <chr> <chr>
#> 1 1     2020-10-31 Income    Bank In… <NA>         0.04 Alas… <NA>  PO Box… Anch… Alas… 99524
#> 2 2     2020-10-25 Income    Electro… <NA>         8.99 Zoom… <NA>  888-79… San … Cali… none 
#> 3 3     2020-12-31 Income    Check    3013       350    ABCA… <NA>  301 Ar… Anch… Alas… 99518
#> 4 4     2020-12-13 Income    Bank In… <NA>         0.03 MVFCU <NA>  1020 S… Palm… Alas… 99645
#> 5 5     2020-10-01 Income    Check    0093       250    Moss  Rynn… P.O. B… Fair… Alas… 99711
#> 6 6     2020-10-01 Income    Credit … <NA>       250    Dods… James 1325 V… Fair… Alas… 99709
#> # … with 14 more variables: country <chr>, occupation <chr>, employer <chr>, purpose <chr>,
#> #   report_type <chr>, election_name <chr>, election_type <chr>, municipality <chr>, office <chr>,
#> #   filer_type <chr>, filer <chr>, report_year <int>, submitted <date>, file <chr>
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(akc, count_na)
#> # A tibble: 26 x 4
#>    col           class      n         p
#>    <chr>         <chr>  <int>     <dbl>
#>  1 id            <chr>      0 0        
#>  2 date          <date>     0 0        
#>  3 tran_type     <chr>      0 0        
#>  4 pay_type      <chr>      0 0        
#>  5 pay_detail    <chr>  14801 0.536    
#>  6 amount        <dbl>      0 0        
#>  7 last          <chr>      2 0.0000725
#>  8 first         <chr>    895 0.0324   
#>  9 address       <chr>    269 0.00975  
#> 10 city          <chr>    268 0.00971  
#> 11 state         <chr>      1 0.0000362
#> 12 zip           <chr>    268 0.00971  
#> 13 country       <chr>      0 0        
#> 14 occupation    <chr>   7282 0.264    
#> 15 employer      <chr>   2923 0.106    
#> 16 purpose       <chr>  25330 0.918    
#> 17 report_type   <chr>      0 0        
#> 18 election_name <chr>      0 0        
#> 19 election_type <chr>  11236 0.407    
#> 20 municipality  <chr>  27139 0.983    
#> 21 office        <chr>  22694 0.822    
#> 22 filer_type    <chr>      0 0        
#> 23 filer         <chr>      0 0        
#> 24 report_year   <int>      0 0        
#> 25 submitted     <date>     0 0        
#> 26 file          <chr>      0 0
```

We can flag any rows that are missing a name, date, or amount needed to
identify a transaction.

``` r
key_vars <- c("date", "last", "amount", "filer")
akc <- flag_na(akc, all_of(key_vars))
sum(akc$na_flag)
#> [1] 2
```

All of these missing key values are the `last` name of the contributor.

``` r
akc %>% 
  filter(na_flag) %>% 
  select(all_of(key_vars)) %>% 
  sample_frac()
#> # A tibble: 2 x 4
#>   date       last  amount filer      
#>   <date>     <chr>  <dbl> <chr>      
#> 1 2020-12-02 <NA>     3.6 Local367PAC
#> 2 2020-10-15 <NA>     2   Local367PAC
```

``` r
akc %>% 
  filter(na_flag) %>% 
  select(all_of(key_vars)) %>% 
  col_stats(count_na)
#> # A tibble: 4 x 4
#>   col    class      n     p
#>   <chr>  <chr>  <int> <dbl>
#> 1 date   <date>     0     0
#> 2 last   <chr>      2     1
#> 3 amount <dbl>      0     0
#> 4 filer  <chr>      0     0
```

### Duplicates

Ignoring the supposedly unique `id` variable, quite a few records are
entirely duplicated. We will not remove these records, as they may very
well be valid repetitions, but we can flag them with a new logical
variable.

``` r
d1 <- duplicated(akc[, -1], fromLast = TRUE)
d2 <- duplicated(akc[, -1], fromLast = FALSE)
akc <- mutate(akc, dupe_flag = (d1 | d2))
percent(mean(akc$dupe_flag), 0.1)
#> [1] "14.1%"
rm(d1, d2); flush_memory()
```

``` r
akc %>% 
  filter(dupe_flag) %>% 
  select(id, all_of(key_vars))
#> # A tibble: 3,881 x 5
#>    id    date       last                                              amount filer                 
#>    <chr> <date>     <chr>                                              <dbl> <chr>                 
#>  1 571   2020-10-02 Mulder                                              1000 Alaska Republican Par…
#>  2 572   2020-10-02 Mulder                                              1000 Alaska Republican Par…
#>  3 630   2020-10-17 Anchorage Police Department Employees Association   1000 James Allen Canitz, Sr
#>  4 645   2020-10-17 Anchorage Police Department Employees Association   1000 James Allen Canitz, Sr
#>  5 989   2020-10-02 Marathon Alaska PAC                                  250 Christopher Kurka     
#>  6 990   2020-10-01 McCabe                                               100 Christopher Kurka     
#>  7 1013  2020-10-01 McCabe                                               100 Christopher Kurka     
#>  8 1014  2020-10-02 Marathon Alaska PAC                                  250 Christopher Kurka     
#>  9 1041  2020-10-01 Albright                                              19 IAFF Local 1264 PAC   
#> 10 1042  2020-10-01 Albright                                              19 IAFF Local 1264 PAC   
#> # … with 3,871 more rows
```

### Categorical

Columns also vary in their degree of distinctiveness. Some character
columns like `first` name are obviously mostly distinct, others like
`office` only have a few unique values, which we can count.

``` r
col_stats(akc, n_distinct)
#> # A tibble: 28 x 4
#>    col           class      n         p
#>    <chr>         <chr>  <int>     <dbl>
#>  1 id            <chr>  27596 1        
#>  2 date          <date>   108 0.00391  
#>  3 tran_type     <chr>      1 0.0000362
#>  4 pay_type      <chr>      8 0.000290 
#>  5 pay_detail    <chr>   1612 0.0584   
#>  6 amount        <dbl>   2254 0.0817   
#>  7 last          <chr>   6857 0.248    
#>  8 first         <chr>   3555 0.129    
#>  9 address       <chr>   9046 0.328    
#> 10 city          <chr>    597 0.0216   
#> 11 state         <chr>     50 0.00181  
#> 12 zip           <chr>    687 0.0249   
#> 13 country       <chr>      3 0.000109 
#> 14 occupation    <chr>   1714 0.0621   
#> 15 employer      <chr>   1914 0.0694   
#> 16 purpose       <chr>    444 0.0161   
#> 17 report_type   <chr>      7 0.000254 
#> 18 election_name <chr>     21 0.000761 
#> 19 election_type <chr>      7 0.000254 
#> 20 municipality  <chr>     11 0.000399 
#> 21 office        <chr>      7 0.000254 
#> 22 filer_type    <chr>      2 0.0000725
#> 23 filer         <chr>    219 0.00794  
#> 24 report_year   <int>      7 0.000254 
#> 25 submitted     <date>   100 0.00362  
#> 26 file          <chr>      1 0.0000362
#> 27 na_flag       <lgl>      2 0.0000725
#> 28 dupe_flag     <lgl>      2 0.0000725
```

![](../plots/bar_categorical-1.png)<!-- -->![](../plots/bar_categorical-2.png)<!-- -->![](../plots/bar_categorical-3.png)<!-- -->![](../plots/bar_categorical-4.png)<!-- -->![](../plots/bar_categorical-5.png)<!-- -->

### Amounts

``` r
noquote(map_chr(summary(akc$amount), dollar))
#>       Min.    1st Qu.     Median       Mean    3rd Qu.       Max. 
#>         $0         $5        $10    $367.93        $42 $1,968,497
percent(mean(akc$amount <= 0), 0.01)
#> [1] "0.01%"
```

There are only 2,254 values, which is an order of magnitude less than we
might expect from a distribution of values from a dataset of this size.

In fact, more than half of all `amount` values are $2, $5, $50, $100, or
$500 dollars even.

``` r
akc %>% 
  count(amount, sort = TRUE) %>% 
  add_prop(sum = TRUE)
#> # A tibble: 2,254 x 3
#>    amount     n     p
#>     <dbl> <int> <dbl>
#>  1      5  6272 0.227
#>  2      2  3730 0.362
#>  3    100  2176 0.441
#>  4     10  1359 0.491
#>  5     50  1208 0.534
#>  6     25   802 0.563
#>  7    500   788 0.592
#>  8    250   593 0.613
#>  9      1   407 0.628
#> 10    200   361 0.641
#> # … with 2,244 more rows
```

![](../plots/hist_amount-1.png)<!-- -->

### Dates

``` r
akc <- mutate(
  .data = akc,
  date_clean = date %>% 
    # fix bad years with regex
    str_replace("^(210)(?=\\d-)", "201") %>% 
    str_replace("^(202)(?=[13-9])", "201") %>% 
    str_replace("^(29)(?=\\d-)", "20") %>% 
    str_replace("^(291)(?=\\d-)", "201") %>% 
    str_replace("^(301)(?=\\d-)", "201") %>% 
    as_date(),
  year_clean = year(date_clean)
)
```

``` r
min(akc$date_clean)
#> [1] "2011-01-03"
sum(akc$year_clean < 2011)
#> [1] 0
max(akc$date_clean)
#> [1] "3030-10-30"
sum(akc$date_clean > today())
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
akc <- akc %>% 
  mutate(
    address_norm = normal_address(
      address = address,
      abbs = usps_street,
      na_rep = TRUE
    )
  )
```

``` r
akc %>% 
  select(contains("address")) %>% 
  distinct() %>% 
  sample_n(10)
#> # A tibble: 10 x 2
#>    address                   address_norm              
#>    <chr>                     <chr>                     
#>  1 PO BOX 312                PO BOX 312                
#>  2 629 De Pauw Dr            629 DE PAUW DR            
#>  3 2865 MENDENHALL LP RD C13 2865 MENDENHALL LP RD C 13
#>  4 6 N Dolores Rd #1         6 N DOLORES RD 1          
#>  5 6400 EAST 15TH COURT #2   6400 E 15TH CT 2          
#>  6 3240 PENLAND PKWY #123    3240 PENLAND PKWY 123     
#>  7 522 LONG SPUR LOOP        522 LONG SPUR LOOP        
#>  8 Po Box 1466               PO BOX 1466               
#>  9 PO Box 196613             PO BOX 196613             
#> 10 3821 MARCY CT             3821 MARCY CT
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
akc <- akc %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  akc$zip,
  akc$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 zip        0.990        687 0.00971   266    133
#> 2 zip_norm   0.999        577 0.0114     27     16
```

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

``` r
akc <- akc %>% 
  mutate(
    state_norm = normal_state(
      state = state,
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = NULL
    )
  )
```

``` r
akc %>% 
  filter(state != state_norm) %>% 
  count(state, state_norm, sort = TRUE)
#> # A tibble: 47 x 3
#>    state                state_norm     n
#>    <chr>                <chr>      <int>
#>  1 Alaska               AK         26588
#>  2 Washington           WA           158
#>  3 California           CA           147
#>  4 New York             NY            82
#>  5 Texas                TX            52
#>  6 District of Columbia DC            50
#>  7 Florida              FL            49
#>  8 Arizona              AZ            48
#>  9 Colorado             CO            48
#> 10 Oregon               OR            33
#> # … with 37 more rows
```

``` r
akc %>% 
  filter(state_norm %out% valid_state) %>% 
  count(state, state_norm, sort = TRUE) %>% 
  print(n = Inf)
#> # A tibble: 4 x 3
#>   state       state_norm      n
#>   <chr>       <chr>       <int>
#> 1 GET         GET             2
#> 2 IR          IR              2
#> 3 Switzerland SWITZERLAND     1
#> 4 <NA>        <NA>            1
```

``` r
akc <- akc %>% 
  mutate(
    state_norm = state_norm %>% 
      na_in("NONE") %>% 
      str_replace("^ALBERTA$", "AB") %>% 
      str_replace("^BRITISH COLUMBIA$", "BC") %>% 
      str_replace("^NEW ZEALAND$", "NZ") %>% 
      str_replace("^NZL$", "NZ") %>% 
      str_replace("^ONTARIO$", "ON") %>% 
      str_replace("^PHILIPPINES$", "PH") %>% 
      str_replace("^PHILLIPINES$", "PH") %>% 
      str_replace("^SURRY HILLS$", "NSW") %>% 
      str_replace("^EUROPE$", "EU") %>% 
      str_remove("\\s\\w+ CANADA") %>% 
      str_squish()
  )
```

``` r
progress_table(
  akc$state,
  akc$state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage      prop_in n_distinct   prop_na n_out n_diff
#>   <chr>        <dbl>      <dbl>     <dbl> <dbl>  <dbl>
#> 1 state         0            50 0.0000362 27595     50
#> 2 state_norm    1.00         50 0.0000362     5      4
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
akc <- akc %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("AK", "DC", "ALASKA"),
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
akc <- akc %>% 
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

The \[OpenRefine\] algorithms can be used to group similar strings and
replace the less common versions with their most common counterpart.
This can greatly reduce inconsistency, but with low confidence; we will
only keep any refined strings that have a valid city/state/zip
combination.

``` r
good_refine <- akc %>% 
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

    #> # A tibble: 1 x 5
    #>   state_norm zip_norm city_swap    city_refine     n
    #>   <chr>      <chr>    <chr>        <chr>       <int>
    #> 1 AK         99801    JUNEAUJUNEAU JUNEAU          1

Then we can join the refined values back to the database.

``` r
akc <- akc %>% 
  left_join(good_refine, by = names(.)) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

| stage        | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
|:-------------|---------:|------------:|---------:|-------:|--------:|
| city\_raw)   |    0.943 |         499 |     0.01 |   1568 |     101 |
| city\_norm   |    0.944 |         486 |     0.01 |   1519 |      80 |
| city\_swap   |    0.995 |         445 |     0.01 |    140 |      30 |
| city\_refine |    0.995 |         444 |     0.01 |    139 |      29 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/bar_progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar_distinct-1.png)<!-- -->

## Conclude

``` r
akc <- akc %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean"))
```

``` r
glimpse(sample_n(akc, 20))
#> Rows: 20
#> Columns: 34
#> $ id            <chr> "25420", "3600", "22426", "25573", "14464", "13851", "14793", "9174", "930…
#> $ date          <date> 2020-11-20, 2020-10-23, 2020-11-17, 2020-12-09, 2020-10-22, 2020-10-03, 2…
#> $ tran_type     <chr> "Income", "Income", "Income", "Income", "Income", "Income", "Income", "Inc…
#> $ pay_type      <chr> "Payroll Deduction", "Payroll Deduction", "Payroll Deduction", "Payroll De…
#> $ pay_detail    <chr> NA, NA, "Payroll Deduction", NA, "1005", NA, NA, NA, NA, NA, "Payroll Dedu…
#> $ amount        <dbl> 3.00, 12.25, 2.00, 5.00, 50000.00, 100.00, 50.00, 100.00, 100.00, 5.88, 5.…
#> $ last          <chr> "Standridge", "SCHAEFFER", "Parks", "Lee", "Alaska Progressive Donor Table…
#> $ first         <chr> "John", "C", "Jessica", "Jae", NA, "Jeanine", "Isaac", "Jon", "Danielle", …
#> $ address       <chr> "P.O. Box 242041", "1436 DOGWOOD", "713 Maple Dr", "P.O. Box 242041", "112…
#> $ city_raw      <chr> "ANC", "FAIRBANKS", "Kenai", "ANC", "Anchorage", "Eagle River", "Anchorage…
#> $ state         <chr> "Alaska", "Alaska", "Alaska", "Alaska", "Alaska", "Alaska", "Alaska", "Ala…
#> $ zip           <chr> "99524", "99709", "99611", "99524", "99518", "99577", "99507", "99502", "9…
#> $ country       <chr> "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA…
#> $ occupation    <chr> "Fire Fighter", "LABORER", NA, "Fire Fighter", ".", "Director", "Engineer"…
#> $ employer      <chr> "AFD", "EXCLUSIVE PAVING", "SOA", "AFD", ".", "Alaska Miners Association",…
#> $ purpose       <chr> NA, NA, NA, NA, NA, NA, NA, NA, "Contribution", NA, NA, NA, "$140.00", NA,…
#> $ report_type   <chr> "105 Day Report", "Seven Day Report", "105 Day Report", "105 Day Report", …
#> $ election_name <chr> "-", "2020 - State General Election", "-", "-", "2020 - State General Elec…
#> $ election_type <chr> NA, "State General", NA, NA, "State General", "State General", "State Gene…
#> $ municipality  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ office        <chr> NA, NA, NA, NA, NA, NA, "House", NA, NA, NA, NA, "Senate", NA, "House", "H…
#> $ filer_type    <chr> "Group", "Group", "Group", "Group", "Group", "Group", "Candidate", "Group"…
#> $ filer         <chr> "Alaska Professional Fire Fighters Association", "Alaska Laborers' Politic…
#> $ report_year   <int> 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 20…
#> $ submitted     <date> 2021-01-19, 2020-10-26, 2021-01-21, 2021-01-19, 2020-10-28, 2020-10-27, 2…
#> $ file          <chr> "CD_Transactions_Recent.CSV", "CD_Transactions_Recent.CSV", "CD_Transactio…
#> $ na_flag       <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ dupe_flag     <lgl> FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
#> $ date_clean    <date> 2020-11-20, 2020-10-23, 2020-11-17, 2020-12-09, 2020-10-22, 2020-10-03, 2…
#> $ year_clean    <dbl> 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 20…
#> $ address_clean <chr> "PO BOX 242041", "1436 DOGWOOD", "713 MAPLE DR", "PO BOX 242041", "1120 HU…
#> $ zip_clean     <chr> "99524", "99709", "99611", "99524", "99518", "99577", "99507", "99502", "9…
#> $ state_clean   <chr> "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "A…
#> $ city_clean    <chr> "ANCHORAGE", "FAIRBANKS", "KENAI", "ANCHORAGE", "ANCHORAGE", "EAGLE RIVER"…
```

1.  There are 27,596 records in the database.
2.  There are 3,881 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 2 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
clean_dir <- dir_create(here("ak", "contribs", "data", "clean"))
clean_path <- path(clean_dir, "ak_contribs_20210125.csv")
write_csv(akc, clean_path, na = "")
(clean_size <- file_size(clean_path))
#> 8.96M
file_encoding(clean_path) %>% 
  mutate(across(path, path.abbrev))
#> # A tibble: 1 x 3
#>   path                                              mime            charset
#>   <fs::path>                                        <chr>           <chr>  
#> 1 ~/ak/contribs/data/clean/ak_contribs_20210125.csv application/csv utf-8
```

## Upload

We can use the `aws.s3::put_object()` to upload the text file to the IRW
server.

``` r
s3_path <- path("csv", basename(clean_path))
if (!object_exists(s3_path, "publicaccountability")) {
  put_object(
    file = clean_path,
    object = s3_path, 
    bucket = "publicaccountability",
    acl = "public-read",
    multipart = TRUE,
    show_progress = TRUE
  )
}
#>   |                                                                                                 |                                                                                         |   0%  |                                                                                                 |=                                                                                        |   1%  |                                                                                                 |==                                                                                       |   2%  |                                                                                                 |==                                                                                       |   3%  |                                                                                                 |===                                                                                      |   3%  |                                                                                                 |====                                                                                     |   4%  |                                                                                                 |====                                                                                     |   5%  |                                                                                                 |=====                                                                                    |   6%  |                                                                                                 |======                                                                                   |   6%  |                                                                                                 |======                                                                                   |   7%  |                                                                                                 |=======                                                                                  |   8%  |                                                                                                 |========                                                                                 |   9%  |                                                                                                 |=========                                                                                |  10%  |                                                                                                 |==========                                                                               |  11%  |                                                                                                 |===========                                                                              |  12%  |                                                                                                 |===========                                                                              |  13%  |                                                                                                 |============                                                                             |  13%  |                                                                                                 |============                                                                             |  14%  |                                                                                                 |=============                                                                            |  15%  |                                                                                                 |==============                                                                           |  15%  |                                                                                                 |==============                                                                           |  16%  |                                                                                                 |===============                                                                          |  17%  |                                                                                                 |================                                                                         |  17%  |                                                                                                 |================                                                                         |  18%  |                                                                                                 |=================                                                                        |  19%  |                                                                                                 |=================                                                                        |  20%  |                                                                                                 |==================                                                                       |  20%  |                                                                                                 |===================                                                                      |  21%  |                                                                                                 |===================                                                                      |  22%  |                                                                                                 |====================                                                                     |  22%  |                                                                                                 |====================                                                                     |  23%  |                                                                                                 |=====================                                                                    |  24%  |                                                                                                 |======================                                                                   |  24%  |                                                                                                 |======================                                                                   |  25%  |                                                                                                 |=======================                                                                  |  26%  |                                                                                                 |========================                                                                 |  27%  |                                                                                                 |=========================                                                                |  28%  |                                                                                                 |=========================                                                                |  29%  |                                                                                                 |==========================                                                               |  29%  |                                                                                                 |===========================                                                              |  30%  |                                                                                                 |===========================                                                              |  31%  |                                                                                                 |============================                                                             |  31%  |                                                                                                 |=============================                                                            |  32%  |                                                                                                 |=============================                                                            |  33%  |                                                                                                 |==============================                                                           |  33%  |                                                                                                 |==============================                                                           |  34%  |                                                                                                 |===============================                                                          |  35%  |                                                                                                 |================================                                                         |  36%  |                                                                                                 |=================================                                                        |  37%  |                                                                                                 |==================================                                                       |  38%  |                                                                                                 |===================================                                                      |  39%  |                                                                                                 |===================================                                                      |  40%  |                                                                                                 |====================================                                                     |  40%  |                                                                                                 |=====================================                                                    |  41%  |                                                                                                 |=====================================                                                    |  42%  |                                                                                                 |======================================                                                   |  43%  |                                                                                                 |=======================================                                                  |  44%  |                                                                                                 |========================================                                                 |  45%  |                                                                                                 |=========================================                                                |  46%  |                                                                                                 |==========================================                                               |  47%  |                                                                                                 |===========================================                                              |  48%  |                                                                                                 |===========================================                                              |  49%  |                                                                                                 |============================================                                             |  50%  |                                                                                                 |=============================================                                            |  50%  |                                                                                                 |=============================================                                            |  51%  |                                                                                                 |==============================================                                           |  52%  |                                                                                                 |===============================================                                          |  52%  |                                                                                                 |===============================================                                          |  53%  |                                                                                                 |================================================                                         |  54%  |                                                                                                 |=================================================                                        |  55%  |                                                                                                 |==================================================                                       |  56%  |                                                                                                 |===================================================                                      |  57%  |                                                                                                 |====================================================                                     |  58%  |                                                                                                 |====================================================                                     |  59%  |                                                                                                 |=====================================================                                    |  59%  |                                                                                                 |=====================================================                                    |  60%  |                                                                                                 |======================================================                                   |  61%  |                                                                                                 |=======================================================                                  |  61%  |                                                                                                 |=======================================================                                  |  62%  |                                                                                                 |========================================================                                 |  63%  |                                                                                                 |=========================================================                                |  64%  |                                                                                                 |==========================================================                               |  65%  |                                                                                                 |==========================================================                               |  66%  |                                                                                                 |===========================================================                              |  66%  |                                                                                                 |============================================================                             |  67%  |                                                                                                 |============================================================                             |  68%  |                                                                                                 |=============================================================                            |  68%  |                                                                                                 |=============================================================                            |  69%  |                                                                                                 |==============================================================                           |  70%  |                                                                                                 |===============================================================                          |  70%  |                                                                                                 |===============================================================                          |  71%  |                                                                                                 |================================================================                         |  72%  |                                                                                                 |=================================================================                        |  73%  |                                                                                                 |==================================================================                       |  74%  |                                                                                                 |==================================================================                       |  75%  |                                                                                                 |===================================================================                      |  75%  |                                                                                                 |====================================================================                     |  76%  |                                                                                                 |====================================================================                     |  77%  |                                                                                                 |=====================================================================                    |  77%  |                                                                                                 |======================================================================                   |  78%  |                                                                                                 |======================================================================                   |  79%  |                                                                                                 |=======================================================================                  |  80%  |                                                                                                 |========================================================================                 |  81%  |                                                                                                 |=========================================================================                |  82%  |                                                                                                 |==========================================================================               |  83%  |                                                                                                 |==========================================================================               |  84%  |                                                                                                 |===========================================================================              |  84%  |                                                                                                 |============================================================================             |  85%  |                                                                                                 |============================================================================             |  86%  |                                                                                                 |=============================================================================            |  86%  |                                                                                                 |==============================================================================           |  87%  |                                                                                                 |==============================================================================           |  88%  |                                                                                                 |===============================================================================          |  89%  |                                                                                                 |================================================================================         |  90%  |                                                                                                 |=================================================================================        |  91%  |                                                                                                 |==================================================================================       |  92%  |                                                                                                 |===================================================================================      |  93%  |                                                                                                 |====================================================================================     |  94%  |                                                                                                 |====================================================================================     |  95%  |                                                                                                 |=====================================================================================    |  96%  |                                                                                                 |======================================================================================   |  96%  |                                                                                                 |======================================================================================   |  97%  |                                                                                                 |=======================================================================================  |  98%  |                                                                                                 |======================================================================================== |  98%  |                                                                                                 |======================================================================================== |  99%  |                                                                                                 |=========================================================================================| 100%
#> [1] TRUE
```

``` r
r <- head_object(s3_path, "publicaccountability")
(s3_size <- as_fs_bytes(attr(r, "content-length")))
#> 8.96M
unname(s3_size == clean_size)
#> [1] TRUE
```
