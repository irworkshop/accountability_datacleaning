Wisconsin Contributions
================
Kiernan Nicholls
2020-04-23 12:00:39

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
  - [Export](#export)
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
  gluedown, # print markdown
  magrittr, # pipe operators
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  glue, # combine strings
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

Data is from the Wisconsin Secretary of State’s Campaign Finance System
(CIFS).

> Wyoming’s Campaign Finance Information System (WYCFIS) exists to
> provide a mechanism for online filing of campaign finance information
> and to provide full disclosure to the public. This website contains
> detailed financial records and related information that candidates,
> committees, organizations and parties are required by law to disclose.

## Import

Using the CIFS [contribution search
portal](https://cfis.wi.gov/Public/Registration.aspx?page=ReceiptList#),
we can run a search for all contributions from “All Filing Periods” from
the dates 2000-01-01 to 2020-04-23. Those search results need to be
manually exported as the `ReceiptsList.csv` file.

> To view contributions to a committee, go to the CFIS Home Page, on the
> left hand side, and click View Receipts. A pop up letting you know
> that this information cannot be used for solicitation purposes will
> appear – click Continue. Type in a committee’s ID in the field titled
> ID, or start typing the name of the candidate in the Registrant Name
> field and click on the correct committee name when it appears. Type in
> any additional information you would like to search for, including a
> name of a contributor or amount of contribution. To view all
> contributions, remove the filing period by clicking, in the Filing
> Period Name field, and scroll all the way to the top and select All
> Filing Periods. Click Search and all of the contributions fitting your
> search criteria will appear. If you would like to export these into
> Excel, scroll all the way to the bottom and on the right hand side,
> click the XLS icon.

Infuriatingly, the site only lets users export 65,000 records at a time.
We have manually exported 91 files.

``` r
raw_dir <- dir_create(here("wi", "contribs", "data", "raw"))
raw_files <- as_tibble(dir_info(raw_dir))
sum(raw_files$size)
#> 1.06G
raw_files %>% 
  select(path, size, modification_time) %>% 
  mutate(across(path, basename))
#> # A tibble: 91 x 3
#>    path                                    size modification_time  
#>    <chr>                            <fs::bytes> <dttm>             
#>  1 ReceiptsList_1-65000.csv               12.7M 2020-04-21 12:45:29
#>  2 ReceiptsList_1040001-1105000.csv       10.8M 2020-04-21 16:37:16
#>  3 ReceiptsList_1105001-1170000.csv       11.9M 2020-04-21 16:42:53
#>  4 ReceiptsList_1170001-1235000.csv         11M 2020-04-21 16:49:02
#>  5 ReceiptsList_1235001-1300000.csv       10.8M 2020-04-21 17:13:05
#>  6 ReceiptsList_1300001-1365000.csv       10.9M 2020-04-21 17:38:50
#>  7 ReceiptsList_130001-195000.csv         11.2M 2020-04-21 13:05:47
#>  8 ReceiptsList_1365001-1430000.csv       12.2M 2020-04-21 17:50:38
#>  9 ReceiptsList_1430001-1495000.csv       10.9M 2020-04-21 17:59:44
#> 10 ReceiptsList_1495001-1560000.csv       10.5M 2020-04-21 18:07:38
#> # … with 81 more rows
```

The files can be read into a single data frame with `vroom::vroom()`.

``` r
wic <- vroom(
  file = raw_files$path,
  delim = ",",
  escape_double = FALSE,
  escape_backslash = FALSE,
  col_types = cols(.default = "c")
)
```

We can check the number of rows against the total reported by our empty
search. We can also count the number of distinct values from a discrete
column.

``` r
nrow(wic) == 5866891 # check col count
#> [1] TRUE
count(wic, ContributorType) # check distinct col
#> # A tibble: 9 x 2
#>   ContributorType         n
#>   <chr>               <int>
#> 1 Anonymous           13967
#> 2 Business            15501
#> 3 Ethics Commission     134
#> 4 Individual        5739136
#> 5 Local Candidate      2395
#> 6 Registrant          62483
#> 7 Self                10703
#> 8 Unitemized          18147
#> 9 Unregistered         4425
prop_na(wic$`72 Hr. Reports`) # empty column
#> [1] 0.9978445
```

The file appears to have been read correctly. We just need to parse,
rename, and remove some of the columns.

``` r
raw_names <- names(wic)[c(-19, -21)]
```

``` r
wic <- wic %>% 
  clean_names("snake") %>% 
  remove_empty("cols") %>% 
  select(-x72_hr_reports) %>% 
  mutate(across(transaction_date, mdy)) %>% 
  mutate(across(contribution_amount, parse_double)) %>% 
  mutate(across(segregated_fund_flag, parse_logical)) %>% 
  rename(
    date = transaction_date,
    period = filing_period_name,
    con_name = contributor_name,
    amount = contribution_amount,
    addr1 = address_line1,
    addr2 = address_line2,
    state = state_code,
    emp_name = employer_name,
    emp_addr = employer_address,
    con_type = contributor_type,
    rec_name = receiving_committee_name,
    seg_fund = segregated_fund_flag
  )
```

## Explore

``` r
glimpse(wic)
#> Rows: 5,866,891
#> Columns: 19
#> $ date       <date> 2018-10-05, 2020-03-01, 2020-02-10, 2018-10-05, 2018-10-16, 2018-09-12, 2018…
#> $ period     <chr> "Fall Pre-Election 2018", "Spring Pre-Election 2020", "Spring Pre-Election 20…
#> $ con_name   <chr> "Clark Co Democratic Party", "Kachel  Mike", "Conroy  Laura", "Zich  Joni", "…
#> $ amount     <dbl> 500.00, 300.00, 40.00, 150.00, 100.00, 100.00, 68.00, 20000.00, 10583.64, 700…
#> $ addr1      <chr> "W6329 Timberlane Road", "PO Box 239", "N7681 E. Lakeshore Dr", "3101 36th Av…
#> $ addr2      <chr> NA, NA, NA, NA, NA, NA, NA, NA, "Suite 200", NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ city       <chr> "Neillsville", "Whitewater", "Whitewater", "St. Anthony", NA, "Madison", "Eau…
#> $ state      <chr> "WI", "WI", "WI", "MN", "WI", "WI", "WI", "WI", "WI", "WI", "WI", "WI", "WI",…
#> $ zip        <chr> "54456", "53190", "53190", "55418", NA, "53704", "54701", "54401", "53703", N…
#> $ occupation <chr> NA, "Real Estate", NA, NA, NA, "RETIRED", "RETIRED", NA, NA, NA, NA, NA, NA, …
#> $ emp_name   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ emp_addr   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ con_type   <chr> "Registrant", "Individual", "Individual", "Individual", "Anonymous", "Individ…
#> $ rec_name   <chr> "Wendy Sue for Wisconsin", "Republican Party of Walworth County", "Republican…
#> $ ethcfid    <chr> "0105996", "0300171", "0300171", "0105996", "0105996", "0105996", "0105996", …
#> $ conduit    <chr> NA, NA, NA, "Xcel Energy Conduit Fund", NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ branch     <chr> "State Assembly  District No. 68", NA, NA, "State Assembly  District No. 68",…
#> $ comment    <chr> NA, "Whitewater HQ Rent", "MAGA Wear", NA, "donation to charity $90 April 10 …
#> $ seg_fund   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
tail(wic)
#> # A tibble: 6 x 19
#>   date       period con_name amount addr1 addr2 city  state zip   occupation emp_name emp_addr
#>   <date>     <chr>  <chr>     <dbl> <chr> <chr> <chr> <chr> <chr> <chr>      <chr>    <chr>   
#> 1 2018-10-15 Fall … Huck  J…   20   W611… <NA>  Burn… WI    53922 <NA>       <NA>     <NA>    
#> 2 2018-10-15 Fall … Rohloff…   20   1379… <NA>  Moun… WI    54149 <NA>       <NA>     <NA>    
#> 3 2018-10-15 Fall … Neumann…   20   3535… <NA>  Dodg… WI    53533 <NA>       <NA>     <NA>    
#> 4 2018-10-15 Fall … Pomeran…    2.5 740 … Apt … New … NY    10025 <NA>       <NA>     <NA>    
#> 5 2018-10-15 Fall … Hunting…   25   1100… <NA>  Appl… WI    54914 <NA>       <NA>     <NA>    
#> 6 2018-10-15 Fall … Navis  …   50   1048… <NA>  Sheb… WI    53081 RETIRED    <NA>     <NA>    
#> # … with 7 more variables: con_type <chr>, rec_name <chr>, ethcfid <chr>, conduit <chr>,
#> #   branch <chr>, comment <chr>, seg_fund <lgl>
```

### Missing

Very few important records are missing a value.

``` r
col_stats(wic, count_na)
#> # A tibble: 19 x 4
#>    col        class        n          p
#>    <chr>      <chr>    <int>      <dbl>
#>  1 date       <date>       0 0         
#>  2 period     <chr>        0 0         
#>  3 con_name   <chr>        8 0.00000136
#>  4 amount     <dbl>        0 0         
#>  5 addr1      <chr>    78412 0.0134    
#>  6 addr2      <chr>  5609875 0.956     
#>  7 city       <chr>    65347 0.0111    
#>  8 state      <chr>    38252 0.00652   
#>  9 zip        <chr>    84754 0.0144    
#> 10 occupation <chr>  4248219 0.724     
#> 11 emp_name   <chr>  4887226 0.833     
#> 12 emp_addr   <chr>  5045662 0.860     
#> 13 con_type   <chr>        0 0         
#> 14 rec_name   <chr>        0 0         
#> 15 ethcfid    <chr>        0 0         
#> 16 conduit    <chr>  5364280 0.914     
#> 17 branch     <chr>  3489357 0.595     
#> 18 comment    <chr>  4641101 0.791     
#> 19 seg_fund   <lgl>        0 0
```

We can flag these few records with `campfin::flag_na()`.

``` r
wic <- wic %>% flag_na(date, con_name, amount, rec_name)
percent(mean(wic$na_flag), 0.0001)
#> [1] "0.0001%"
```

``` r
wic %>% 
  filter(na_flag) %>% 
  select(date, con_name, amount, rec_name)
#> # A tibble: 8 x 4
#>   date       con_name amount rec_name                     
#>   <date>     <chr>     <dbl> <chr>                        
#> 1 2008-12-31 <NA>       84.6 Friends of Shirley Krug      
#> 2 2008-11-30 <NA>       81.7 Friends of Shirley Krug      
#> 3 2008-10-31 <NA>       84.3 Friends of Shirley Krug      
#> 4 2008-09-30 <NA>       77.8 Friends of Shirley Krug      
#> 5 2008-08-31 <NA>       80.2 Friends of Shirley Krug      
#> 6 2008-07-31 <NA>       78.2 Friends of Shirley Krug      
#> 7 2008-10-08 <NA>     2500   WI Teamsters Joint Council 39
#> 8 2008-09-10 <NA>     2500   WI Teamsters Joint Council 39
```

### Duplicates

Quite a few more records are duplicated. While it’s possible for the
same person to make a contribution of the same amount on the same day,
we will still flag these records with `campfin::flag_dupes()`.

``` r
wic <- flag_dupes(wic, everything())
percent(mean(wic$dupe_flag), 0.01)
#> [1] "1.63%"
```

``` r
wic %>% 
  filter(dupe_flag) %>% 
  select(date, con_name, amount, rec_name)
#> # A tibble: 95,742 x 4
#>    date       con_name            amount rec_name
#>    <date>     <chr>                <dbl> <chr>   
#>  1 2020-03-23 MICHAUD  PETER J      6    WEAC PAC
#>  2 2020-03-23 MICHAUD  PETER J      6    WEAC PAC
#>  3 2020-03-23 LESSOR  LOUIS W       5.01 WEAC PAC
#>  4 2020-03-23 LESSOR  LOUIS W       5.01 WEAC PAC
#>  5 2020-03-23 GEORGESON  PAMELA L   5.01 WEAC PAC
#>  6 2020-03-23 GEORGESON  PAMELA L   5.01 WEAC PAC
#>  7 2020-03-23 BEHNKE  MICHELLE C    5.01 WEAC PAC
#>  8 2020-03-23 BEHNKE  MICHELLE C    5.01 WEAC PAC
#>  9 2020-03-23 DRESANG  GINA M       5.01 WEAC PAC
#> 10 2020-03-23 DRESANG  GINA M       5.01 WEAC PAC
#> # … with 95,732 more rows
```

### Categorical

``` r
col_stats(wic, n_distinct)
#> # A tibble: 21 x 4
#>    col        class        n           p
#>    <chr>      <chr>    <int>       <dbl>
#>  1 date       <date>    4683 0.000798   
#>  2 period     <chr>      137 0.0000234  
#>  3 con_name   <chr>  1115590 0.190      
#>  4 amount     <dbl>    27192 0.00463    
#>  5 addr1      <chr>  1283597 0.219      
#>  6 addr2      <chr>    26917 0.00459    
#>  7 city       <chr>    36009 0.00614    
#>  8 state      <chr>       58 0.00000989 
#>  9 zip        <chr>   337132 0.0575     
#> 10 occupation <chr>    75754 0.0129     
#> 11 emp_name   <chr>   128858 0.0220     
#> 12 emp_addr   <chr>   225559 0.0384     
#> 13 con_type   <chr>        9 0.00000153 
#> 14 rec_name   <chr>     2564 0.000437   
#> 15 ethcfid    <chr>     2569 0.000438   
#> 16 conduit    <chr>      232 0.0000395  
#> 17 branch     <chr>      380 0.0000648  
#> 18 comment    <chr>    72989 0.0124     
#> 19 seg_fund   <lgl>        2 0.000000341
#> 20 na_flag    <lgl>        2 0.000000341
#> 21 dupe_flag  <lgl>        2 0.000000341
```

``` r
count(wic, seg_fund, sort = TRUE)
#> # A tibble: 2 x 2
#>   seg_fund       n
#>   <lgl>      <int>
#> 1 FALSE    5863178
#> 2 TRUE        3713
count(wic, con_type, sort = TRUE)
#> # A tibble: 9 x 2
#>   con_type                n
#>   <chr>               <int>
#> 1 Individual        5739136
#> 2 Registrant          62483
#> 3 Unitemized          18147
#> 4 Business            15501
#> 5 Anonymous           13967
#> 6 Self                10703
#> 7 Unregistered         4425
#> 8 Local Candidate      2395
#> 9 Ethics Commission     134
```

### Continuous

#### Amounts

``` r
summary(wic$amount)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>       0       3      10     116      47 3250000
mean(wic$amount <= 0)
#> [1] 0.001980606
```

![](../plots/hist_amount-1.png)<!-- -->

#### Dates

We can use `lubridate::year()` to add a calendar year from the date.

``` r
wic <- mutate(wic, year = year(date))
```

The `date` and new `year` columns are very clean.

``` r
min(wic$date)
#> [1] "2000-03-31"
sum(wic$year < 2000)
#> [1] 0
max(wic$date)
#> [1] "2020-04-07"
sum(wic$date > today())
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
wic <- wic %>% 
  unite(
    starts_with("addr"),
    col = addr_full,
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
wic %>% 
  select(starts_with("addr")) %>% 
  distinct() %>% 
  sample_n(10)
#> # A tibble: 10 x 3
#>    addr1                        addr2    addr_norm                      
#>    <chr>                        <chr>    <chr>                          
#>  1 3702 E Martin Avenue         <NA>     3702 E MARTIN AVE              
#>  2 S5075 Lover's Ln             <NA>     S 5075 LOVERS LN               
#>  3 N5354 Saint Helena Road      <NA>     N 5354 SAINT HELENA RD         
#>  4 615 W Main St                Apt 108  615 W MAIN ST APT 108          
#>  5 4415 S 5th Street            <NA>     4415 S 5 TH ST                 
#>  6 2121 N Gooder St             <NA>     2121 N GOODER ST               
#>  7 3005 Haxton Way              <NA>     3005 HAXTON WAY                
#>  8 6  Brightwaters Circle NE    <NA>     6 BRIGHTWATERS CIR NE          
#>  9 N9081 River Rd               <NA>     N 9081 RIV RD                  
#> 10 25161 Sandpiper Greens Court Apt. 304 25161 SANDPIPER GRNS CT APT 304
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
wic <- wic %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  wic$zip,
  wic$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na   n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl>   <dbl>  <dbl>
#> 1 zip        0.708     337132  0.0144 1687471 310954
#> 2 zip_norm   0.997      32680  0.0146   17674   4143
```

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

``` r
wic <- wic %>% 
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
wic %>% 
  filter(state != state_norm) %>% 
  count(state, state_norm, sort = TRUE)
#> # A tibble: 4 x 3
#>   state state_norm     n
#>   <chr> <chr>      <int>
#> 1 Wi    WI            63
#> 2 Mn    MN             6
#> 3 Il    IL             3
#> 4 wi    WI             1
```

``` r
progress_table(
  wic$state,
  wic$state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage      prop_in n_distinct prop_na n_out n_diff
#>   <chr>        <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 state         1.00         58 0.00652    73      5
#> 2 state_norm    1            54 0.00652     0      1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
wic <- mutate(
  .data = wic,
  city_norm = normal_city(
    city = city, 
    abbs = usps_city,
    states = c("WI", "DC", "WISCONSIN"),
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
wic <- wic %>% 
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
    # check for abb or small diff
    match_abb = is_abbrev(city_norm, city_match),
    match_dist = str_dist(city_norm, city_match),
    city_swap = if_else(
      # if nan and either condition
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
good_refine <- wic %>% 
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

    #> [1] 631
    #> # A tibble: 326 x 5
    #>    state_norm zip_norm city_swap        city_refine         n
    #>    <chr>      <chr>    <chr>            <chr>           <int>
    #>  1 WI         54873    SOLON SPRINGSSS  SOLON SPRINGS      35
    #>  2 WI         53051    MENONOMEE FALLS  MENOMONEE FALLS    23
    #>  3 WI         54751    MENOMINEE        MENOMONIE          22
    #>  4 CA         92625    CORONA DALE MAR  CORONA DEL MAR     13
    #>  5 IL         60030    GREYS LAKE       GRAYSLAKE          12
    #>  6 WI         54751    MENONOMIE        MENOMONIE          12
    #>  7 CA         90292    MARINA DALE REY  MARINA DEL REY     11
    #>  8 SC         29406    NORTH CHARLESTON CHARLESTON         10
    #>  9 WI         54956    NEEHAN           NEENAH             10
    #> 10 CA         95060    SANATA CRUZ CA   SANTA CRUZ          9
    #> # … with 316 more rows

Then we can join the refined values back to the database.

``` r
wic <- wic %>% 
  left_join(good_refine) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

There are one or two more very common values we can adjust by hand.

``` r
wic <- wic %>% 
  mutate(
    city_refine = city_refine %>% 
      na_if("WORK AT HOME") %>% 
      na_if("WI") %>% 
      str_replace("^NYC$", "NEW YORK") %>% 
      str_replace("TRIANGLE PA$", "TRIANGLE PARK")
  )
```

#### Progress

| stage        | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :----------- | -------: | ----------: | -------: | -----: | ------: |
| city\_raw)   |    0.981 |       25778 |    0.011 | 111750 |   12025 |
| city\_norm   |    0.988 |       23746 |    0.011 |  70363 |    9951 |
| city\_swap   |    0.996 |       17940 |    0.011 |  24047 |    4140 |
| city\_refine |    0.996 |       17664 |    0.011 |  20790 |    3866 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/bar_progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar_distinct-1.png)<!-- -->

## Export

``` r
wic <- wic %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  rename(city = city_raw)
```

``` r
glimpse(sample_n(wic, 20))
#> Rows: 20
#> Columns: 26
#> $ date        <date> 2009-05-21, 2016-12-31, 2014-10-12, 2018-03-31, 2012-04-18, 2009-04-13, 201…
#> $ period      <chr> "July Continuing 2009", "January Continuing 2017", "Fall Pre-Election 2014",…
#> $ con_name    <chr> "HORNING  DAVID", "SLOAN  DAVA T", "Partain  Peter", "Hanson  Joshua", "Lond…
#> $ amount      <dbl> 3.00, 1.50, 250.00, 30.00, 25.00, 25.00, 100.00, 25.00, 20.00, 500.00, 4.00,…
#> $ addr1       <chr> "W305 N5200 GAIL LN", "9500 N GREEN BAY RD", "15332 Antioch Street Ste 490",…
#> $ addr2       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ city        <chr> "HARTLAND", "BROWN DEER", "Pacific Palisades", "Beldenville", "Anthem", "Kew…
#> $ state       <chr> "WI", "WI", "CA", "WI", "AZ", "WI", "WI", "OR", "WI", "WI", "WI", "WI", "WI"…
#> $ zip         <chr> "53029", "53209-1075", "90272", "54003", "85086-3920", "53040", "54669", "97…
#> $ occupation  <chr> "Administrative Professional - Telephone", NA, "MANAGER", NA, NA, "Other - R…
#> $ emp_name    <chr> "AT&T Services  Inc.", NA, "Self", NA, NA, NA, NA, NA, "Mark Mand Excavating…
#> $ emp_addr    <chr> "722 N BROADWAY  6M119C  MILWAUKEE  WI 53202", NA, "15332 Antioch Street Ste…
#> $ con_type    <chr> "Individual", "Individual", "Individual", "Individual", "Individual", "Indiv…
#> $ rec_name    <chr> "AT&T Wisconsin Employee PAC", "WEAC PAC", "Friends of Scott Walker", "Wisco…
#> $ ethcfid     <chr> "0500366", "0500189", "0102575", "0300245", "0102575", "0102575", "0300096",…
#> $ conduit     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ branch      <chr> NA, NA, "Governor", NA, "Governor", "Governor", NA, "Governor", NA, NA, NA, …
#> $ comment     <chr> NA, "eDues including EFT  Credit Card and/or Check from 9/1 to 12/31/2016", …
#> $ seg_fund    <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ na_flag     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ dupe_flag   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ year        <dbl> 2009, 2016, 2014, 2018, 2012, 2009, 2017, 2012, 2009, 2018, 2019, 2017, 2017…
#> $ addr_clean  <chr> "W 305 N 5200 GAIL LN", "9500 N GRN BAY RD", "15332 ANTIOCH ST STE 490", "N …
#> $ zip_clean   <chr> "53029", "53209", "90272", "54003", "85086", "53040", "54669", "97035", "530…
#> $ state_clean <chr> "WI", "WI", "CA", "WI", "AZ", "WI", "WI", "OR", "WI", "WI", "WI", "WI", "WI"…
#> $ city_clean  <chr> "HARTLAND", "BROWN DEER", "PACIFIC PALISADES", "BELDENVILLE", "ANTHEM", "KEW…
```

1.  There are 5,866,895 records in the database.
2.  There are 95,746 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 8 records missing a key variable.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

<!-- end list -->

``` r
clean_dir <- dir_create(here("wi", "contribs", "data", "clean"))
clean_path <- path(clean_dir, "wi_contribs_clean.csv")
write_csv(wic, clean_path, na = "")
file_size(clean_path)
#> 1.32G
guess_encoding(clean_path)
#> # A tibble: 1 x 2
#>   encoding confidence
#>   <chr>         <dbl>
#> 1 ASCII             1
```

## Dictionary

| Column        | Type     | Definition                                  |
| :------------ | :------- | :------------------------------------------ |
| `date`        | `<date>` | Date contribution was made                  |
| `period`      | `<chr>`  | Election during which contribution was made |
| `con_name`    | `<chr>`  | Contributor full name                       |
| `amount`      | `<dbl>`  | Contribution amount or correction           |
| `addr1`       | `<chr>`  | Contributor street address                  |
| `addr2`       | `<chr>`  | Contributor secondary address               |
| `city`        | `<chr>`  | Contributor city name                       |
| `state`       | `<chr>`  | Contributor 2-digit state abbreviation      |
| `zip`         | `<chr>`  | Contributor ZIP+4 code                      |
| `occupation`  | `<chr>`  | Contributor occupation                      |
| `emp_name`    | `<chr>`  | Contributor employer name                   |
| `emp_addr`    | `<chr>`  | Contributor employer address                |
| `con_type`    | `<chr>`  | Contributor type                            |
| `rec_name`    | `<chr>`  | Recipient committee name                    |
| `ethcfid`     | `<chr>`  | Recipient ethics & campaign finance ID      |
| `conduit`     | `<chr>`  | Contribution condiut (method)               |
| `branch`      | `<chr>`  | Recipient election office sought            |
| `comment`     | `<chr>`  | Comment (typically check date)              |
| `seg_fund`    | `<lgl>`  | PAC segregated fund sourced                 |
| `na_flag`     | `<lgl>`  | Flag for missing date, amount, or name      |
| `dupe_flag`   | `<lgl>`  | Flag for completely duplicated record       |
| `year`        | `<dbl>`  | Calendar year of contribution date          |
| `addr_clean`  | `<chr>`  | Normalized combined street address          |
| `zip_clean`   | `<chr>`  | Normalized 5-digit ZIP code                 |
| `state_clean` | `<chr>`  | Normalized 2-digit state abbreviation       |
| `city_clean`  | `<chr>`  | Normalized city name                        |

``` r
write_lines(
  x = c("# Wisconsin Contributions Data Dictionary\n", dict_md),
  path = here("wi", "contribs", "wi_contribs_dict.md"),
)
```
