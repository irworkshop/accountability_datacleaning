Texas Lobbying
================
Kiernan Nicholls & Yanqi Xu
2023-07-09 16:20:29

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
#> [1] "/Users/yanqixu/code/accountability_datacleaning"
```

## Data

The data can be obtained from the [Texas Ethics
Commission](https://www.ethics.state.tx.us/data/search/lobby/). The
download page lists data files from 2001 and on. Since the older files
are in a format relatively hard to wrangle. We here include only
lobbying records from 2016 on. The 2023 file was updated on 2023-07-09.

## Import

### Download

``` r
raw_dir <- dir_create(here("state","tx", "lobby", "data", "raw"))
```

``` r
txl_urls <- c(
  "https://www.ethics.state.tx.us/data/search/lobby/2016/2016LobbyistGroupByLobbyist.nopag.xlsx",
  "https://www.ethics.state.tx.us/data/search/lobby/2017/2017LobbyistGroupByLobbyist.xlsx",
  glue("https://www.ethics.state.tx.us/data/search/lobby/{2018:2023}/{2018:2023}LobbyGroupByLobbyist.xlsx")
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
#> # A tibble: 6 × 20
#>   lob_id lob_name   lob_biz lob_a…¹ lob_a…² lob_c…³ lob_s…⁴ lob_zip pri_n…⁵ pri_a…⁶ pri_a…⁷ pri_c…⁸
#>   <chr>  <chr>      <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>  
#> 1 70358  Abbott, S… Attorn… 1108 L… Suite … Austin  TX      78701   Allen … 3200 S… Suite … Houston
#> 2 70358  Abbott, S… Attorn… 1108 L… Suite … Austin  TX      78701   Harris… 1980 P… Suite … Houston
#> 3 52844  Abel, Dou… health… 1515 H… <NA>    Houston TX      77004   Harris… 1515 H… <NA>    Houston
#> 4 10044  Acevedo, … Manage… 1001 C… <NA>    Austin  TX      78701   Anadar… 1201 L… <NA>    The Wo…
#> 5 53651  Acevedo, … <NA>    1122 C… Suite … Austin  TX      78701   Beacon… 200 St… <NA>    Boston 
#> 6 53651  Acevedo, … <NA>    1122 C… Suite … Austin  TX      78701   Capito… 3705 M… <NA>    Austin 
#> # … with 8 more variables: pri_state <chr>, pri_zip <chr>, reporting_interval <chr>, begin <date>,
#> #   stop <date>, method <chr>, amount <chr>, exact <chr>, and abbreviated variable names
#> #   ¹​lob_addr1, ²​lob_addr2, ³​lob_city, ⁴​lob_state, ⁵​pri_name, ⁶​pri_addr1, ⁷​pri_addr2, ⁸​pri_city
tail(txl)
#> # A tibble: 6 × 20
#>   lob_id lob_name   lob_biz lob_a…¹ lob_a…² lob_c…³ lob_s…⁴ lob_zip pri_n…⁵ pri_a…⁶ pri_a…⁷ pri_c…⁸
#>   <chr>  <chr>      <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>  
#> 1 86099  Zaykowski… "Corpo… 816 Co… <NA>    Austin  TX      78701   Drax    Drax P… <NA>    Selby  
#> 2 86099  Zaykowski… "Corpo… 816 Co… <NA>    Austin  TX      78701   McGuir… 816 Co… Suite … Ausitn 
#> 3 81396  Zeller, L… "Blue … 1001 E… <NA>    Richar… TX      75082   BlueCr… 1001 E… <NA>    Richar…
#> 4 56328  Zent, Lar… "Execu… 1616 R… <NA>    Austin  TX      78701-… <NA>    <NA>    <NA>    <NA>   
#> 5 70726  Zimmer Cr… "Lobby… 2211 A… #24     Houston TX      77057   Brazos… 1759 N… <NA>    Bryan  
#> 6 86033  Zinsmeist… "Direc… 1001 C… <NA>    Austin  TX      78701   Charte… 601 Ma… <NA>    Washin…
#> # … with 8 more variables: pri_state <chr>, pri_zip <chr>, reporting_interval <chr>, begin <date>,
#> #   stop <date>, method <chr>, amount <chr>, exact <chr>, and abbreviated variable names
#> #   ¹​lob_addr1, ²​lob_addr2, ³​lob_city, ⁴​lob_state, ⁵​pri_name, ⁶​pri_addr1, ⁷​pri_addr2, ⁸​pri_city
glimpse(sample_n(txl, 20))
#> Rows: 20
#> Columns: 20
#> $ lob_id             <chr> "80980", "84874", "51002", "63990", "13737", "50826", "37179", "60698"…
#> $ lob_name           <chr> "Ford, Crystal", "Mazuca, Anne", "Haley, Anthony", "Spilman, Johanna",…
#> $ lob_biz            <chr> "Public Policy Advisor", "Consultant", "HMWK, LLC", "Employee of NFIB"…
#> $ lob_addr1          <chr> "600 Congress Ave., Ste 2200", "919 Congress Ave., Ste. 510", "1212 Gu…
#> $ lob_addr2          <chr> NA, NA, "Ste. 1003", NA, NA, NA, NA, "Ste 940", NA, "Suite 900", NA, N…
#> $ lob_city           <chr> "Austin", "Austin", "Austin", "Austin", "Austin", "Austin", "Austin", …
#> $ lob_state          <chr> "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX"…
#> $ lob_zip            <chr> "78701", "78701", "78701", "78701", "78701", "78767", "78701", "78701"…
#> $ pri_name           <chr> "Crown Castle International Corp.", "Secure Democracy", "Adelanto Heal…
#> $ pri_addr1          <chr> "1220 Augusta Dr. Ste 600", "611 Pennsylvania Ave., SE #143", "401 W. …
#> $ pri_addr2          <chr> NA, NA, "Suite 840", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ pri_city           <chr> "Houston", "Washington", "Austin", "Austin", "Santa Monica", "Weatherf…
#> $ pri_state          <chr> "TX", "DC", "TX", "TX", "CA", "TX", "TX", "NV", "TX", "FL", "TX", "NY"…
#> $ pri_zip            <chr> "77057", "20003", "78701-4078", "78701", "90405", "76086", "77477", "8…
#> $ reporting_interval <chr> "REGULAR", "REGULAR", "MODIFIED", "REGULAR", "REGULAR", "MODIFIED", "R…
#> $ begin              <date> 2018-01-08, 2021-01-13, 2022-12-08, 2019-01-03, 2020-10-13, 2022-04-2…
#> $ stop               <date> 2018-12-31, 2021-12-31, 2022-12-31, 2019-12-31, 2020-12-31, 2022-12-3…
#> $ method             <chr> "PROSPECT", "PROSPECT", "PROSPECT", "PAID", "PROSPECT", "PROSPECT", "P…
#> $ amount             <chr> "LT24999", "LOBBCOMP03", "LOBBCOMP03", "LT149999", "LOBBCOMP02", "LOBB…
#> $ exact              <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
```

### Missing

``` r
col_stats(txl, count_na)
#> # A tibble: 20 × 4
#>    col                class      n         p
#>    <chr>              <chr>  <int>     <dbl>
#>  1 lob_id             <chr>      0 0        
#>  2 lob_name           <chr>      0 0        
#>  3 lob_biz            <chr>   7783 0.113    
#>  4 lob_addr1          <chr>      7 0.000102 
#>  5 lob_addr2          <chr>  39865 0.580    
#>  6 lob_city           <chr>      7 0.000102 
#>  7 lob_state          <chr>      6 0.0000873
#>  8 lob_zip            <chr>      7 0.000102 
#>  9 pri_name           <chr>    853 0.0124   
#> 10 pri_addr1          <chr>   1014 0.0148   
#> 11 pri_addr2          <chr>  50302 0.732    
#> 12 pri_city           <chr>   1015 0.0148   
#> 13 pri_state          <chr>   1038 0.0151   
#> 14 pri_zip            <chr>   1036 0.0151   
#> 15 reporting_interval <chr>   1541 0.0224   
#> 16 begin              <date>   866 0.0126   
#> 17 stop               <date>   865 0.0126   
#> 18 method             <chr>    864 0.0126   
#> 19 amount             <chr>    863 0.0126   
#> 20 exact              <chr>  68125 0.992
```

``` r
txl <- txl %>% flag_na(lob_name, pri_name)
percent(mean(txl$na_flag), 0.1)
#> [1] "1.2%"
```

``` r
txl %>% 
  filter(na_flag) %>% 
  select(lob_name, pri_name) %>% 
  sample_frac()
#> # A tibble: 853 × 2
#>    lob_name                 pri_name
#>    <chr>                    <chr>   
#>  1 Migliaro, Alyse          <NA>    
#>  2 Ballew, Joel D.          <NA>    
#>  3 Thompson III, John David <NA>    
#>  4 Rotkoff, Jeffre W.       <NA>    
#>  5 Wallace, Blair Ruth      <NA>    
#>  6 Burner, Burnie           <NA>    
#>  7 Rogers Jr., Johnnie B.   <NA>    
#>  8 Boutilier, Bruce         <NA>    
#>  9 Newell, Stephanie M.     <NA>    
#> 10 Adair, Bobby Glenn       <NA>    
#> # … with 843 more rows
```

### Duplicates

Most of the duplicate rows come from a repeated single variable and
missing identifying variables (like the date). We will flag them
nonetheless.

``` r
txl <- flag_dupes(txl, everything(), .check = TRUE)
percent(mean(txl$dupe_flag), 0.1)
#> [1] "3.8%"
```

``` r
txl %>% 
  filter(dupe_flag) %>% 
  select(lob_name, pri_name, begin, stop, na_flag) %>% 
  arrange(lob_name)
#> # A tibble: 2,621 × 5
#>    lob_name          pri_name begin  stop   na_flag
#>    <chr>             <chr>    <date> <date> <lgl>  
#>  1 Aguilar, Leonard  <NA>     NA     NA     TRUE   
#>  2 Aguilar, Leonard  <NA>     NA     NA     TRUE   
#>  3 Aguilar, Leonard  <NA>     NA     NA     TRUE   
#>  4 Aguilar, Leonard  <NA>     NA     NA     TRUE   
#>  5 Akins, Dwain A.   <NA>     NA     NA     TRUE   
#>  6 Akins, Dwain A.   <NA>     NA     NA     TRUE   
#>  7 Aleman, Steven R. <NA>     NA     NA     TRUE   
#>  8 Aleman, Steven R. <NA>     NA     NA     TRUE   
#>  9 Aleman, Steven R. <NA>     NA     NA     TRUE   
#> 10 Aleman, Steven R. <NA>     NA     NA     TRUE   
#> # … with 2,611 more rows
```

### Categorical

``` r
col_stats(txl, n_distinct)
#> # A tibble: 22 × 4
#>    col                class      n         p
#>    <chr>              <chr>  <int>     <dbl>
#>  1 lob_id             <chr>   3339 0.0486   
#>  2 lob_name           <chr>   3400 0.0495   
#>  3 lob_biz            <chr>   1974 0.0287   
#>  4 lob_addr1          <chr>   2986 0.0435   
#>  5 lob_addr2          <chr>    835 0.0122   
#>  6 lob_city           <chr>    339 0.00493  
#>  7 lob_state          <chr>     39 0.000568 
#>  8 lob_zip            <chr>    813 0.0118   
#>  9 pri_name           <chr>   9755 0.142    
#> 10 pri_addr1          <chr>  10702 0.156    
#> 11 pri_addr2          <chr>   1508 0.0220   
#> 12 pri_city           <chr>   1356 0.0197   
#> 13 pri_state          <chr>     50 0.000728 
#> 14 pri_zip            <chr>   2850 0.0415   
#> 15 reporting_interval <chr>      3 0.0000437
#> 16 begin              <date>  1950 0.0284   
#> 17 stop               <date>  1149 0.0167   
#> 18 method             <chr>      4 0.0000582
#> 19 amount             <chr>     36 0.000524 
#> 20 exact              <chr>     14 0.000204 
#> 21 na_flag            <lgl>      2 0.0000291
#> 22 dupe_flag          <lgl>      2 0.0000291
```

![](../plots/bar_distinct-1.png)<!-- -->![](../plots/bar_distinct-2.png)<!-- -->![](../plots/bar_distinct-3.png)<!-- -->

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
#> # A tibble: 10 × 3
#>    lob_addr1                    lob_addr2  lob_addr_norm               
#>    <chr>                        <chr>      <chr>                       
#>  1 1700 Rio Grande              Suite 100  1700 RIO GRANDE SUITE 100   
#>  2 130 East Kaliste Saloom Road <NA>       130 EAST KALISTE SALOOM RD  
#>  3 2450 Holcombe Blvd           Suite 24L  2450 HOLCOMBE BLVD SUITE 24L
#>  4 919 Congress Ave.            Suite 1400 919 CONGRESS AVE SUITE 1400 
#>  5 103 Point Street             <NA>       103 POINT ST                
#>  6 600 Travis                   Suite 4200 600 TRAVIS SUITE 4200       
#>  7 1108 Lavaca St               Suite 500  1108 LAVACA ST SUITE 500    
#>  8 400 W. 15th St. #150         <NA>       400 W 15TH ST #150          
#>  9 1155 F Street N.W            Suite 1200 1155 F STREET NW SUITE 1200 
#> 10 105 W. Riverside Dr.         #105       105 W RIVERSIDE DR #105
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
#> # A tibble: 4 × 6
#>   stage            prop_in n_distinct  prop_na n_out n_diff
#>   <chr>              <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 txl$lob_zip        0.957        813 0.000102  2980    183
#> 2 txl$lob_zip_norm   1.00         661 0.000102    29      6
#> 3 txl$pri_zip        0.937       2850 0.0151    4286    646
#> 4 txl$pri_zip_norm   0.997       2359 0.0154     183     61
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

    #> # A tibble: 6 × 6
    #>   stage                      prop_in n_distinct  prop_na n_out n_diff
    #>   <chr>                        <dbl>      <dbl>    <dbl> <dbl>  <dbl>
    #> 1 str_to_upper(txl$lob_city)   0.998        318 0.000102   104     23
    #> 2 txl$lob_city_norm            0.999        316 0.000102    75     20
    #> 3 txl$lob_city_swap            0.999        305 0.000771    49     10
    #> 4 str_to_upper(txl$pri_city)   0.983       1276 0.0148    1149    191
    #> 5 txl$pri_city_norm            0.986       1263 0.0148     954    176
    #> 6 txl$pri_city_swap            0.995       1120 0.0225     333     50

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
#> $ lob_id             <chr> "65392", "12905", "83343", "13484", "34739", "13768", "83262", "70459"…
#> $ lob_name           <chr> "Taylor, Gregory", "McGarry, Mignon", "Saldana, Amanda", "Fickel, Ann"…
#> $ lob_biz            <chr> "Consultant", NA, "Lawyer", "Texas Classroom Teachers Association", "C…
#> $ lob_addr1          <chr> "10 Strecker Road", "504 West 14th Street", "1508 S Lone Star Way Unit…
#> $ lob_addr2          <chr> NA, NA, NA, NA, "Ste 113-205", NA, NA, NA, NA, NA, "Ste. 200", "One De…
#> $ lob_city           <chr> "Ellisville", "Austin", "Edinburg", "Austin", "Dallas", "Austin", "Aus…
#> $ lob_state          <chr> "MO", "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX"…
#> $ lob_zip            <chr> "63011", "78701", "78539", "78767-1489", "75248", "78763", "78701", "7…
#> $ pri_name           <chr> "Hatada Enterprises, Inc.", "Vistra Energy Corp.", "AT&T", "Texas Clas…
#> $ pri_addr1          <chr> "150 FM 854", "1601 Bryan Street", "208 S Akard St.", "P.O. Box 1489",…
#> $ pri_addr2          <chr> NA, NA, NA, NA, NA, NA, NA, "100 Congress Ave., Ste. 1300", NA, NA, NA…
#> $ pri_city           <chr> "Valley Mills", "Dallas", "Dallas", "Austin", "Plano", "Baltimore", "W…
#> $ pri_state          <chr> "TX", "TX", "TX", "TX", "TX", "MD", "TX", "TX", "TX", "TX", NA, "TX", …
#> $ pri_zip            <chr> "76689", "75201", "75202", "78767", "75026", "21236", "76708", "78701"…
#> $ reporting_interval <chr> "MODIFIED", "MODIFIED", "REGULAR", "MODIFIED", "MODIFIED", "REGULAR", …
#> $ begin              <date> 2023-01-03, 2017-01-06, 2021-01-15, 2023-01-01, 2017-01-04, 2017-12-1…
#> $ stop               <date> 2023-12-31, 2017-12-31, 2021-12-31, 2023-12-31, 2017-12-31, 2017-12-3…
#> $ method             <chr> "PROSPECT", "PROSPECT", "PROSPECT", "PROSPECT", "PROSPECT", "PAID", "P…
#> $ amount             <chr> "LOBBCOMP01", "LT149999", "LOBBCOMP01", "LOBBCOMP03", "LT99999", "LT10…
#> $ exact              <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ na_flag            <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
#> $ dupe_flag          <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
#> $ year               <dbl> 2023, 2017, 2021, 2023, 2017, 2017, 2020, 2019, 2019, 2019, 2021, 2023…
#> $ lob_addr_clean     <chr> "10 STRECKER RD", "504 WEST 14TH ST", "1508 S LONE STAR WAY UNIT 1", "…
#> $ pri_addr_clean     <chr> "150 FM 854", "1601 BRYAN ST", "208 S AKARD ST", "PO BOX 1489", "PO BO…
#> $ lob_zip_clean      <chr> "63011", "78701", "78539", "78767", "75248", "78763", "78701", "78701"…
#> $ pri_zip_clean      <chr> "76689", "75201", "75202", "78767", "75026", "21236", "76708", "78701"…
#> $ lob_city_clean     <chr> "ELLISVILLE", "AUSTIN", "EDINBURG", "AUSTIN", "DALLAS", "AUSTIN", "AUS…
#> $ pri_city_clean     <chr> "VALLEY MILLS", "DALLAS", "DALLAS", "AUSTIN", "PLANO", "BALTIMORE", "W…
```

1.  There are 68,700 records in the database.
2.  There are 2,621 duplicate records in the database.
3.  There are 853 records missing ….
4.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
5.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
clean_dir <- dir_create(here("state","tx", "lobby", "data", "clean"))
```

``` r
write_csv(
  x = txl,
  path = path(clean_dir, "tx_lobby_reg_2016-2023.csv"),
  na = ""
)
```
