Texas Lobbying
================
Kiernan Nicholls
2020-02-14 12:45:27

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
  - [Conclude](#conclude)
  - [Export](#export)

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
  refinr, # cluster and merge
  readxl, # read excel files
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

## Import

### Download

``` r
raw_dir <- dir_create(here("tx", "lobby", "data", "raw"))
```

``` r
txl_urls <- c(
  "https://www.ethics.state.tx.us/data/search/lobby/2016/2016LobbyistGroupByLobbyist.nopag.xlsx",
  "https://www.ethics.state.tx.us/data/search/lobby/2017/2017LobbyistGroupByLobbyist.xlsx",
  "https://www.ethics.state.tx.us/data/search/lobby/2018/2018LobbyGroupByLobbyist.xlsx",
  "https://www.ethics.state.tx.us/data/search/lobby/2019/2019LobbyGroupByLobbyist.xlsx",
  "https://www.ethics.state.tx.us/data/search/lobby/2020/2020LobbyGroupByLobbyist.xlsx"
)

if (!all_files_new(raw_dir)) {
  for (xlsx_url in txl_urls) {
    download.file(
      url = xlsx_url,
      destfile = path(raw_dir, basename(xlsx_url))
    )
  }
}
```

### Read

``` r
txl <- map_df(
  .x = dir_ls(raw_dir), 
  .f = read_excel,
  col_types = "text"
)

txl <- txl %>% 
  clean_names("snake") %>% 
  rename(
    lob_id = filer_id,
    lob_name = filer_name,
    lob_biz = business,
    lob_addr1 = addr_1_4,
    lob_addr2 = addr_2_5,
    lob_city = city_6,
    lob_state = state_7,
    lob_zip = zip_8,
    pri_name = client_name,
    pri_addr1 = addr_1_10,
    pri_addr2 = addr_2_11,
    pri_city = city_12,
    pri_state = state_13,
    pri_zip = zip_14
  )
```

``` r
txl <- mutate_at(txl, vars(begin, stop), ~parse_date(., "%m/%d/%Y"))
txl <- mutate_at(txl, vars(lob_name), ~str_remove(., "\\s\\(.*\\)$"))
```

## Explore

``` r
head(txl)
#> # A tibble: 6 x 20
#>   lob_id lob_name lob_biz lob_addr1 lob_addr2 lob_city lob_state lob_zip pri_name pri_addr1
#>   <chr>  <chr>    <chr>   <chr>     <chr>     <chr>    <chr>     <chr>   <chr>    <chr>    
#> 1 70358  Abbott,… Attorn… 1108 Lav… Suite 510 Austin   TX        78701   Allen B… 3200 Sou…
#> 2 70358  Abbott,… Attorn… 1108 Lav… Suite 510 Austin   TX        78701   Harris … 1980 Pos…
#> 3 52844  Abel, D… health… 1515 Her… <NA>      Houston  TX        77004   Harris … 1515 Her…
#> 4 10044  Acevedo… Manage… 1001 Con… <NA>      Austin   TX        78701   Anadark… 1201 Lak…
#> 5 53651  Acevedo… <NA>    1122 Col… Suite 106 Austin   TX        78701   Beacon … 200 Stat…
#> 6 53651  Acevedo… <NA>    1122 Col… Suite 106 Austin   TX        78701   Capitol… 3705 Med…
#> # … with 10 more variables: pri_addr2 <chr>, pri_city <chr>, pri_state <chr>, pri_zip <chr>,
#> #   reporting_interval <chr>, begin <date>, stop <date>, method <chr>, amount <chr>, exact <chr>
tail(txl)
#> # A tibble: 6 x 20
#>   lob_id lob_name lob_biz lob_addr1 lob_addr2 lob_city lob_state lob_zip pri_name pri_addr1
#>   <chr>  <chr>    <chr>   <chr>     <chr>     <chr>    <chr>     <chr>   <chr>    <chr>    
#> 1 67308  Zapata,…  <NA>   2630 Exp… Suite G-… Austin   TX        78703   The Lum… 2630 Exp…
#> 2 81396  Zeller,… "Blue … 1001 E. … <NA>      Richard… TX        75082   BlueCro… 1001 E. …
#> 3 64083  Zeman, …  <NA>   2775 san… <NA>      northbr… IL        60062   <NA>     <NA>     
#> 4 56328  Zent, L…  <NA>   1616 Rio… <NA>      Austin   TX        78701-… <NA>     <NA>     
#> 5 70726  Zimmer … "Lobby… 13930 Ba… <NA>      Houston  TX        77079   Brazos … 1759 N. …
#> 6 65226  Zolnier… "Texas… 4807 Spi… Bldg. 3,… Austin   TX        78759   Texas N… 4807 Spi…
#> # … with 10 more variables: pri_addr2 <chr>, pri_city <chr>, pri_state <chr>, pri_zip <chr>,
#> #   reporting_interval <chr>, begin <date>, stop <date>, method <chr>, amount <chr>, exact <chr>
glimpse(sample_n(txl, 20))
#> Rows: 20
#> Columns: 20
#> $ lob_id             <chr> "80980", "68851", "63990", "51437", "33567", "60698", "81360", "66710…
#> $ lob_name           <chr> "Ford, Crystal", "Webster, Richard Todd", "Spilman, Johanna", "McGara…
#> $ lob_biz            <chr> "Public Policy Advisor", NA, "Employee of NFIB", "Consultant", "consu…
#> $ lob_addr1          <chr> "600 Congress Ave., Ste 2200", "131 Dashelle Run", "1100B Guadalupe S…
#> $ lob_addr2          <chr> NA, NA, NA, NA, "Suite 900", "Ste 940", NA, NA, NA, NA, NA, "Suite 90…
#> $ lob_city           <chr> "Austin", "Kyle", "Austin", "Austin", "Austin", "Austin", "Austin", "…
#> $ lob_state          <chr> "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX…
#> $ lob_zip            <chr> "78701", "78640", "78701", "78701", "78701", "78701", "78768", "78701…
#> $ pri_name           <chr> "Crown Castle International Corp.", "Responsive Education Solutions S…
#> $ pri_addr1          <chr> "1220 Augusta Dr. Ste 600", "P. O. Box 292730", "1100B Guadalupe St",…
#> $ pri_addr2          <chr> NA, NA, NA, "Suite 1200", NA, NA, NA, NA, NA, NA, NA, NA, "Suite 430"…
#> $ pri_city           <chr> "Houston", "Lewisville", "Austin", "Dallas", "Wichita", "Las Vegas", …
#> $ pri_state          <chr> "TX", "TX", "TX", "TX", "KS", "NV", "TX", "TX", "TX", "MI", "NY", "TX…
#> $ pri_zip            <chr> "77057", "75029", "78701", "75202", "67220", "89128", "77002-3106", "…
#> $ reporting_interval <chr> "REGULAR", "REGULAR", "REGULAR", "REGULAR", "REGULAR", "REGULAR", "RE…
#> $ begin              <date> 2018-01-08, 2016-03-30, 2019-01-03, 2020-01-31, 2017-01-11, 2017-01-…
#> $ stop               <date> 2018-12-31, 2016-12-31, 2019-12-31, 2020-12-31, 2017-12-31, 2017-09-…
#> $ method             <chr> "PROSPECT", "PROSPECT", "PAID", "PAID", "PROSPECT", "PROSPECT", "PROS…
#> $ amount             <chr> "LT24999", "LT99999", "LT149999", "LT10000", "LT10000", "LT49999", "L…
#> $ exact              <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
```

### Missing

``` r
col_stats(txl, count_na)
#> # A tibble: 20 x 4
#>    col                class      n         p
#>    <chr>              <chr>  <int>     <dbl>
#>  1 lob_id             <chr>      0 0        
#>  2 lob_name           <chr>      0 0        
#>  3 lob_biz            <chr>   8567 0.220    
#>  4 lob_addr1          <chr>      3 0.0000771
#>  5 lob_addr2          <chr>  22225 0.571    
#>  6 lob_city           <chr>      3 0.0000771
#>  7 lob_state          <chr>      3 0.0000771
#>  8 lob_zip            <chr>      3 0.0000771
#>  9 pri_name           <chr>    561 0.0144   
#> 10 pri_addr1          <chr>    687 0.0176   
#> 11 pri_addr2          <chr>  28860 0.741    
#> 12 pri_city           <chr>    687 0.0176   
#> 13 pri_state          <chr>    693 0.0178   
#> 14 pri_zip            <chr>    707 0.0182   
#> 15 reporting_interval <chr>   2134 0.0548   
#> 16 begin              <date>   574 0.0147   
#> 17 stop               <date>   573 0.0147   
#> 18 method             <chr>    567 0.0146   
#> 19 amount             <chr>    566 0.0145   
#> 20 exact              <chr>  38634 0.992
```

``` r
txl <- txl %>% flag_na(lob_name, pri_name)
percent(mean(txl$na_flag), 0.1)
#> [1] "1.4%"
```

``` r
txl %>% 
  filter(na_flag) %>% 
  select(lob_name, pri_name) %>% 
  sample_frac()
#> # A tibble: 561 x 2
#>    lob_name                 pri_name
#>    <chr>                    <chr>   
#>  1 Reed, Megan              <NA>    
#>  2 McMahon, Sukyi           <NA>    
#>  3 Chepkauskas, Dan         <NA>    
#>  4 Newton, Chris            <NA>    
#>  5 Levy, Richard            <NA>    
#>  6 Migliaro, Alyse          <NA>    
#>  7 Ballew, Joel D.          <NA>    
#>  8 Thompson III, John David <NA>    
#>  9 Rotkoff, Jeffre W.       <NA>    
#> 10 Colburn, Stuart          <NA>    
#> # … with 551 more rows
```

### Duplicates

Most of the duplicate rows come from a repeated single variable and
missing identifying variables (like the date). We will flag them
nonetheless.

``` r
txl <- flag_dupes(txl, everything(), .check = TRUE)
percent(mean(txl$dupe_flag), 0.1)
#> [1] "4.0%"
```

``` r
txl %>% 
  filter(dupe_flag) %>% 
  select(lob_name, pri_name, begin, stop, na_flag) %>% 
  arrange(lob_name)
#> # A tibble: 1,561 x 5
#>    lob_name          pri_name begin      stop       na_flag
#>    <chr>             <chr>    <date>     <date>     <lgl>  
#>  1 Aguilar, Leonard  <NA>     NA         NA         TRUE   
#>  2 Aguilar, Leonard  <NA>     NA         NA         TRUE   
#>  3 Aleman, Steven R. <NA>     NA         NA         TRUE   
#>  4 Aleman, Steven R. <NA>     NA         NA         TRUE   
#>  5 Aleman, Steven R. <NA>     NA         NA         TRUE   
#>  6 Aleman, Steven R. <NA>     NA         NA         TRUE   
#>  7 Aleman, Steven R. <NA>     NA         NA         TRUE   
#>  8 Alvarado, Aidan   <NA>     NA         NA         TRUE   
#>  9 Alvarado, Aidan   <NA>     NA         NA         TRUE   
#> 10 Alvarado, Aidan   <NA>     NA         NA         TRUE   
#> # … with 1,551 more rows
```

### Categorical

``` r
col_stats(txl, n_distinct)
#> # A tibble: 22 x 4
#>    col                class      n         p
#>    <chr>              <chr>  <int>     <dbl>
#>  1 lob_id             <chr>   2583 0.0664   
#>  2 lob_name           <chr>   2620 0.0673   
#>  3 lob_biz            <chr>   1300 0.0334   
#>  4 lob_addr1          <chr>   2126 0.0546   
#>  5 lob_addr2          <chr>    643 0.0165   
#>  6 lob_city           <chr>    248 0.00637  
#>  7 lob_state          <chr>     34 0.000873 
#>  8 lob_zip            <chr>    632 0.0162   
#>  9 pri_name           <chr>   6559 0.168    
#> 10 pri_addr1          <chr>   7028 0.181    
#> 11 pri_addr2          <chr>    995 0.0256   
#> 12 pri_city           <chr>   1020 0.0262   
#> 13 pri_state          <chr>     45 0.00116  
#> 14 pri_zip            <chr>   2180 0.0560   
#> 15 reporting_interval <chr>      3 0.0000771
#> 16 begin              <date>  1023 0.0263   
#> 17 stop               <date>   601 0.0154   
#> 18 method             <chr>      4 0.000103 
#> 19 amount             <chr>     22 0.000565 
#> 20 exact              <chr>     10 0.000257 
#> 21 na_flag            <lgl>      2 0.0000514
#> 22 dupe_flag          <lgl>      2 0.0000514
```

## Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are tailor made to facilitate this process.

We will also add a single year variable.

``` r
txl <- mutate(txl, year = year(begin))
```

### Address

For the street `addresss` variable, the `campfin::normal_address()`
function will force consistence case, remove punctuation, and abbreviate
official USPS suffixes.

``` r
txl <- txl %>% 
  unite(
    col = lob_addr,
    starts_with("lob_addr"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    lob_addr_norm = normal_address(
      address = lob_addr,
      abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-lob_addr)
```

``` r
txl <- txl %>% 
  unite(
    col = pri_addr,
    starts_with("pri_addr"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    pri_addr_norm = normal_address(
      address = pri_addr,
      abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-pri_addr)
```

``` r
txl %>% 
  select(contains("lob_addr")) %>% 
  distinct() %>% 
  sample_n(10)
#> # A tibble: 10 x 3
#>    lob_addr1                         lob_addr2         lob_addr_norm                               
#>    <chr>                             <chr>             <chr>                                       
#>  1 12 Radnor Dr.                     <NA>              12 RADNOR DR                                
#>  2 1005 Congress Avenue, Suite 1000  <NA>              1005 CONGRESS AVE STE 1000                  
#>  3 701 Brazos                        Suite 1050        701 BRAZOS STE 1050                         
#>  4 c/o Doctors Hospital at Renaissa… 5501 S. McColl R… CO DOCTORS HOSPITAL AT RENAISSANCE LTD 5501…
#>  5 370 N. Carpenter                  <NA>              370 N CARPENTER                             
#>  6 3963 Maple Avenue, Suite 290      <NA>              3963 MAPLE AVE STE 290                      
#>  7 604 W. 14th                       <NA>              604 W 14 TH                                 
#>  8 1221 McKinney                     <NA>              1221 MCKINNEY                               
#>  9 8000 IH10 West, Ste 600           <NA>              8000 IH 10 W STE 600                        
#> 10 2412 Burleson Ct #B               <NA>              2412 BURLESON CT B
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
txl <- mutate_at(
  .tbl = txl,
  .vars = vars(ends_with("zip")),
  .funs = list(norm = normal_zip),
  na_rep = TRUE
)
```

``` r
progress_table(
  txl$lob_zip,
  txl$lob_zip_norm,  
  txl$pri_zip,
  txl$pri_zip_norm,
  compare = valid_zip
)
#> # A tibble: 4 x 6
#>   stage        prop_in n_distinct   prop_na n_out n_diff
#>   <chr>          <dbl>      <dbl>     <dbl> <dbl>  <dbl>
#> 1 lob_zip        0.947        632 0.0000771  2076    155
#> 2 lob_zip_norm   0.999        505 0.0000771    39      4
#> 3 pri_zip        0.928       2180 0.0182     2755    511
#> 4 pri_zip_norm   0.998       1801 0.0182       78     31
```

### State

``` r
prop_in(txl$lob_state, valid_state)
#> [1] 1
prop_in(txl$pri_state, valid_state)
#> [1] 1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
txl <- mutate_at(
  .tbl = txl,
  .vars = vars(ends_with("city")),
  .funs = list(norm = normal_city),
  abbs = usps_city,
  states = c("TX", "DC", "TEXAS"),
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
txl <- txl %>% 
  left_join(
    y = zipcodes,
    by = c(
      "lob_state" = "state",
      "lob_zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(lob_city_norm, city_match),
    match_dist = str_dist(lob_city_norm, city_match),
    lob_city_swap = if_else(
      condition = !is.na(match_dist) & match_abb | match_dist == 1,
      true = city_match,
      false = lob_city_norm
    )
  ) %>% 
  select(
    -city_match,
    -match_dist,
    -match_abb
  )
```

``` r
txl <- txl %>% 
  left_join(
    y = zipcodes,
    by = c(
      "pri_state" = "state",
      "pri_zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(pri_city_norm, city_match),
    match_dist = str_dist(pri_city_norm, city_match),
    pri_city_swap = if_else(
      condition = !is.na(match_dist) & match_abb | match_dist == 1,
      true = city_match,
      false = pri_city_norm
    )
  ) %>% 
  select(
    -city_match,
    -match_dist,
    -match_abb
  )
```

#### Progress

    #> # A tibble: 6 x 6
    #>   stage         prop_in n_distinct   prop_na n_out n_diff
    #>   <chr>           <dbl>      <dbl>     <dbl> <dbl>  <dbl>
    #> 1 lob_city)       0.998        230 0.0000771    64     12
    #> 2 lob_city_norm   0.999        229 0.0000771    32     10
    #> 3 lob_city_swap   0.999        222 0.00146      21      4
    #> 4 pri_city)       0.984        967 0.0176      608    126
    #> 5 pri_city_norm   0.991        954 0.0176      340    110
    #> 6 pri_city_swap   0.996        866 0.0245      140     29

## Conclude

``` r
txl <- txl %>% 
  select(
    -lob_city_norm,
    -pri_city_norm,
  ) %>% 
  rename_all(~str_replace(., "_(norm|swap)", "_clean"))
```

``` r
glimpse(sample_n(txl, 20))
#> Rows: 20
#> Columns: 29
#> $ lob_id             <chr> "14488", "83386", "13745", "70558", "65245", "80804", "70824", "70746…
#> $ lob_name           <chr> "Pope, Clayton", "Milton, Jackson", "Jones Jr., Neal T.", "Hausenfluc…
#> $ lob_biz            <chr> NA, NA, "consultant", NA, "Government Relations", "823 Congress, Suit…
#> $ lob_addr1          <chr> "1115 San Jacinto Blvd", "9800 Centre Pkwy", "823 Congress", "816 Con…
#> $ lob_addr2          <chr> "Suite 275", "Suite 200", "Suite 900", "Ste.940", "Suite 2800", "Suit…
#> $ lob_city           <chr> "Austin", "Houston", "Austin", "Austin", "Houston", "Austin", "Housto…
#> $ lob_state          <chr> "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX…
#> $ lob_zip            <chr> "78701-1413", "77036", "78701", "78701", "77002", "78701", "77021", "…
#> $ pri_name           <chr> "Bruni Properties", "Texas Right to Life Committee", "Marathon Petrol…
#> $ pri_addr1          <chr> "15321 San Pedro", "9800 Centre Pkwy", "19100 Ridgewood Parkway", "10…
#> $ pri_addr2          <chr> "Suite 203", "Suite 200", NA, "Suite 1.20", NA, NA, NA, NA, NA, NA, N…
#> $ pri_city           <chr> "San Antonio", "Houston", "San Antonio", "San Antonio", "Houston", "R…
#> $ pri_state          <chr> "TX", "TX", "TX", "TX", "TX", "TX", "TX", "AL", "TX", "TX", "TX", "TX…
#> $ pri_zip            <chr> "78232", "77036", "78259", "78205", "77252", "75088", "77030", "35226…
#> $ reporting_interval <chr> "REGULAR", NA, "REGULAR", "REGULAR", "REGULAR", "REGULAR", "MODIFIED"…
#> $ begin              <date> 2019-04-02, 2019-01-30, 2020-01-31, 2016-01-06, 2016-01-22, 2017-04-…
#> $ stop               <date> 2019-12-31, 2019-05-31, 2020-12-31, 2016-12-31, 2016-12-31, 2017-08-…
#> $ method             <chr> "PROSPECT", "PAID", "PROSPECT", "PROSPECT", "PROSPECT", "PROSPECT", "…
#> $ amount             <chr> "LT10000", "LT24999", "LT10000", "LT10000", "LT24999", "LT10000", "LT…
#> $ exact              <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ na_flag            <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ dupe_flag          <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ year               <dbl> 2019, 2019, 2020, 2016, 2016, 2017, 2017, 2020, 2019, 2016, 2017, 201…
#> $ lob_addr_clean     <chr> "1115 SAN JACINTO BLVD STE 275", "9800 CTR PKWY STE 200", "823 CONGRE…
#> $ pri_addr_clean     <chr> "15321 SAN PEDRO STE 203", "9800 CTR PKWY STE 200", "19100 RIDGEWOOD …
#> $ lob_zip_clean      <chr> "78701", "77036", "78701", "78701", "77002", "78701", "77021", "78746…
#> $ pri_zip_clean      <chr> "78232", "77036", "78259", "78205", "77252", "75088", "77030", "35226…
#> $ lob_city_clean     <chr> "AUSTIN", "HOUSTON", "AUSTIN", "AUSTIN", "HOUSTON", "AUSTIN", "HOUSTO…
#> $ pri_city_clean     <chr> "SAN ANTONIO", "HOUSTON", "SAN ANTONIO", "SAN ANTONIO", "HOUSTON", "R…
```

1.  There are 38,929 records in the database.
2.  There are 1,561 duplicate records in the database.
3.  There are 561 records missing ….
4.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
5.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
clean_dir <- dir_create(here("tx", "lobby", "data", "clean"))
```

``` r
write_csv(
  x = txl,
  path = path(clean_dir, "tx_lobby_clean.csv"),
  na = ""
)
```
