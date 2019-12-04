Michigan Lobbyists
================
Kiernan Nicholls
2019-12-04 16:10:11

<!-- Place comments regarding knitting here -->

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
  tidyverse, # data manipulation
  lubridate, # datetime strings
  magrittr, # pipe opperators
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
[`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning "TAP repo")
GitHub repository.

The `R_campfin` project uses the [RStudio
projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects "Rproj")
feature and should be run as such. The project also uses the dynamic
`here::here()` tool for file paths relative to *your* machine.

``` r
# where does this document knit?
here::here()
#> [1] "/home/kiernan/R/accountability_datacleaning/R_campfin"
```

## Data

Data is obtained from the [Michigan Secretary of
State](https://www.michigan.gov/sos/). The data is provided by NICUSA,
Inc., which provides information technology services for the SOS.

> Use this page to search for information concerning individuals and
> organizations registered under the Michigan Lobby Registration Act, as
> well as expenditures disclosed by these registrants on required
> financial reports. The record for each registrant will also include a
> listing of any reported employees compensated by each registrant for
> lobbying, as well as employers who report the registrant as an
> employee compensated for lobbying on behalf of the employer.
> 
> You may download the entire list of Michigan registrants by clicking
> on the Spreadsheet Format box and following the instructions provided.

The website certificates are out of date, so we can only obtain the file
by using `curl` with the `--insecure` option.

``` r
raw_dir <- here("mi", "lobby", "data", "raw")
dir_create(raw_dir)
```

``` r
lob_url <- "https://miboecfr.nicusa.com/cfr/dumpdata/aaa4NaO5g/mi_lobby.sh"
lob_path <- url2path(lob_url, raw_dir)
download.file(
  url = lob_url,
  destfile = lob_path,
  method = "curl",
  extra = "--insecure"
)
```

## Import

As described on the [data
website](https://miboecfr.nicusa.com/cgi-bin/cfr/lobby_srch_res.cgi):

> #### Other Notes:…
> 
> The file is TAB delimited and NO quotes surround string text.
> 
> The first record DOES contain the field names.
> 
> The second record is a ‘dummy’ record used primarily to clue database
> programs like Access in as to how to import the data, as well as some
> other useful information. You may want to delete this record AND the
> record(s) at the end of the file containing counts once you have
> gotten any use from them.
> 
> When saving the mi\_lobby.sh file, you may want to rename it with an
> extension of .txt, so that certain database programs will import it
> correctly. The Bureau of Elections makes every effort to provide
> accurate information to the public. However, any data taken from the
> database should be verified against the actual report filed by the
> lobby. The information provided here is deemed reliable but not
> guaranteed.

We can use this information to define the parameters of
`readr::read_delim()`.

``` r
milr <- read_delim(
  file = lob_path,
  delim = "\t",
  skip = 2,
  col_names = c(
    "id", "type", "last", "first", "mi", "sig", "addr", 
    "city", "state", "zip", "phone", "reg", "term"
  ),
  col_types = cols(
    .default = col_character(),
    type = col_factor(),
    reg = col_date_usa(),
    term = col_date_usa()
  )
)
```

## Explore

``` r
head(milr)
#> # A tibble: 6 x 13
#>   id     type  last    first mi    sig     addr       city  state zip   phone reg        term      
#>   <chr>  <fct> <chr>   <chr> <chr> <chr>   <chr>      <chr> <chr> <chr> <chr> <date>     <date>    
#> 1 014673 A     (RADKE… JODI  L     <NA>    PO BOX 784 LOVE… CO    80539 9702… 2019-09-12 NA        
#> 2 009995 L     2630 F… <NA>  <NA>  RICHAR… 721 NORTH… LANS… MI    4890… 5173… 2006-09-01 2008-11-30
#> 3 011388 L     3 CLIC… <NA>  <NA>  A EDWI… 805 15TH … WASH… DC    20005 2026… 2010-07-12 2010-12-31
#> 4 012438 L     3 REAS… <NA>  <NA>  RENAE … 201 TOWNS… LANS… MI    48933 5173… 2013-05-15 2014-07-31
#> 5 011813 L     3D ETC… <NA>  <NA>  RICHAR… 22482 ORC… FARM… MI    48336 2489… 2011-08-15 2012-05-04
#> 6 009088 L     3M COM… <NA>  <NA>  DAVID … 515 KING … ALEX… VA    22314 7036… 2003-01-01 NA
tail(milr)
#> # A tibble: 6 x 13
#>   id     type  last   first  mi     sig      addr     city  state zip   phone reg        term      
#>   <chr>  <fct> <chr>  <chr>  <chr>  <chr>    <chr>    <chr> <chr> <chr> <chr> <date>     <date>    
#> 1 000151 A     ZURVA… DAVID  S      <NA>     620 S C… LANS… MI    4890… 5174… 1983-10-17 2009-01-30
#> 2 012240 A     ZWART  STEVEN J      <NA>     PO BOX … BAY … MI    4870… 9896… 2012-09-18 2013-12-31
#> 3 009589 A     ZWARTZ ROBERT <NA>   <NA>     175 W J… CHIC… IL    60604 3124… 2005-06-21 2010-08-05
#> 4 006811 A     ZYBLE  DAVID  A      <NA>     1 CORPO… LANS… MI    48951 5173… 1996-12-09 NA        
#> 5 <NA>   <NA>  <NA>   <NA>   End o… 7,166 t… <NA>     <NA>  <NA>  <NA>  <NA>  NA         NA        
#> 6 <NA>   <NA>  <NA>   <NA>   <NA>   <NA>     <NA>     <NA>  <NA>  <NA>  <NA>  NA         NA
glimpse(sample_frac(milr))
#> Observations: 7,168
#> Variables: 13
#> $ id    <chr> "005063", "000322", "012244", "012088", "007872", "011002", "001413", "008789", "0…
#> $ type  <fct> A, A, A, A, L, L, L, L, L, A, L, A, A, A, A, A, A, A, A, A, A, L, L, A, L, A, A, L…
#> $ last  <chr> "NIEMELA", "MATHEWSON", "HEMOND", "FULTS", "WAYNE WESTLAND COMMUNITY SCHOOLS", "NO…
#> $ first <chr> "JOHN", "WILLIAM", "ADRIAN", "PAIGE", NA, NA, NA, NA, NA, "JEFF", NA, "KEN", "MURR…
#> $ mi    <chr> "D", "C", NA, NA, NA, NA, NA, NA, NA, NA, NA, "J", "E", "J", "H", "MELVILLE", "G",…
#> $ sig   <chr> NA, NA, NA, NA, "DENNIS O CAWTHORNE", "JAY DUPREY", "LEIGH GREDEN", "LINDA PIERCE"…
#> $ addr  <chr> "417 SEYMOUR, STE 1 %COUNTY ROAD ASSOC OF MI", "1675 GREEN RD", "712 HALL BLVD", "…
#> $ city  <chr> "LANSING", "ANN ARBOR", "MASON", "LANSING", "LANSING", "NOVI", "LANSING", "NOVI", …
#> $ state <chr> "MI", "MI", "MI", "MI", "MI", "MI", "MI", "MI", NA, "MI", "MI", "NJ", "MI", "MI", …
#> $ zip   <chr> "48933", "48105", "48854", "48933", "48933", "48376", "48933", "48375", "00000", "…
#> $ phone <chr> "5174821189", "7346623246", "5178976016", "5177038601", "5173711400", "2483802111"…
#> $ reg   <date> 1991-01-15, 1983-10-20, 2012-09-27, 2012-04-23, 2000-02-24, 2009-04-22, 1984-01-1…
#> $ term  <date> 2013-10-31, 2018-08-28, 2012-12-31, NA, NA, 2010-01-20, NA, 2008-01-02, NA, 2018-…
```

As we can see from `tail()`, the last two rows still need to be removed.

The `id` variable is unique to each lobbyist, so we can use it to remove
the invalid rows.

``` r
col_stats(milr, n_distinct)
#> # A tibble: 13 x 4
#>    col   class      n        p
#>    <chr> <chr>  <int>    <dbl>
#>  1 id    <chr>   7167 1.000   
#>  2 type  <fct>      3 0.000419
#>  3 last  <chr>   6103 0.851   
#>  4 first <chr>    906 0.126   
#>  5 mi    <chr>    189 0.0264  
#>  6 sig   <chr>   2606 0.364   
#>  7 addr  <chr>   4554 0.635   
#>  8 city  <chr>    726 0.101   
#>  9 state <chr>     44 0.00614 
#> 10 zip   <chr>   1361 0.190   
#> 11 phone <chr>   3787 0.528   
#> 12 reg   <date>  3528 0.492   
#> 13 term  <date>  1260 0.176
```

``` r
milr <- filter(milr, !is.na(id))
```

Now, there are no rows missing the key information needed to identify
lobbyists.

``` r
col_stats(milr, count_na)
#> # A tibble: 13 x 4
#>    col   class      n        p
#>    <chr> <chr>  <int>    <dbl>
#>  1 id    <chr>      0 0       
#>  2 type  <fct>      0 0       
#>  3 last  <chr>      0 0       
#>  4 first <chr>   3489 0.487   
#>  5 mi    <chr>   5501 0.768   
#>  6 sig   <chr>   3680 0.514   
#>  7 addr  <chr>      0 0       
#>  8 city  <chr>      0 0       
#>  9 state <chr>     20 0.00279 
#> 10 zip   <chr>     17 0.00237 
#> 11 phone <chr>    491 0.0685  
#> 12 reg   <date>     2 0.000279
#> 13 term  <date>  3015 0.421
```

There are no duplicate rows in the database.

``` r
sum(duplicated(milr))
#> [1] 0
```

The database contains both outside lobbyist and lobbying agents.

![](../plots/plot_agent-1.png)<!-- -->

42% of lobbyists in the database have a termination date, meaning only
58% of the records identify active lobbyists.

``` r
prop_na(milr$term)
#> [1] 0.4207368
```

We can add the registration year using `lubridate::year()` on the date
column.

``` r
milr <- mutate(milr, year = year(reg))
```

![](../plots/year_plot-1.png)<!-- -->

## Wrangle

To improve the searchability and consistency of the database, we can
perform some very basic and confident text normalization.

### Phone

We can convert the phone numbers into a standard charatcer (i.e.,
non-numeric) format.

``` r
milr <- mutate(milr, phone_norm = normal_phone(phone))
```

    #> # A tibble: 3,787 x 2
    #>    phone      phone_norm    
    #>    <chr>      <chr>         
    #>  1 3177687078 (317) 768-7078
    #>  2 3126517932 (312) 651-7932
    #>  3 2486452000 (248) 645-2000
    #>  4 8109873101 (810) 987-3101
    #>  5 2123763112 (212) 376-3112
    #>  6 7038718500 (703) 871-8500
    #>  7 5174841525 (517) 484-1525
    #>  8 2485590840 (248) 559-0840
    #>  9 8006764065 (800) 676-4065
    #> 10 5187962769 (518) 796-2769
    #> # … with 3,777 more rows

### Address

We can use `campfin::normal_address()` to improve the consistency in the
`addr`
variable.

``` r
milr <- mutate(milr, addr_norm = normal_address(addr, abbs = usps_street))
```

    #> # A tibble: 4,553 x 2
    #>    addr                                            addr_norm                                       
    #>    <chr>                                           <chr>                                           
    #>  1 7031 ORCHARD LAKE RD STE 105                    7031 ORCHARD LAKE ROAD SUITE 105                
    #>  2 110 W MICHIGAN AVE SUITE 700                    110 WEST MICHIGAN AVENUE SUITE 700              
    #>  3 ONE KELLOGG SQUARE 5S                           ONE KELLOGG SQUARE 5S                           
    #>  4 2164 COMMONS PKWY %MI ACADEMY OF FMLY PHYSICIA… 2164 COMMONS PARKWAY MI ACADEMY OF FMLY PHYSICI…
    #>  5 1118 E CHAMBERS ST                              1118 EAST CHAMBERS STREET                       
    #>  6 11727 FRUEHAUF DR % DEANNA DUKE                 11727 FRUEHAUF DRIVE DEANNA DUKE                
    #>  7 8118 CUTLER RD                                  8118 CUTLER ROAD                                
    #>  8 110 W MICHIGAN AVE, STE 1200                    110 WEST MICHIGAN AVENUE SUITE 1200             
    #>  9 301 ARMSTRONG RD ATTN: JACK BRUSEWITZ           301 ARMSTRONG ROAD ATTN JACK BRUSEWITZ          
    #> 10 2591 ALDEN COURT                                2591 ALDEN COURT                                
    #> # … with 4,543 more rows

### ZIP

``` r
milr <- mutate(milr, zip_norm = normal_zip(zip, na_rep = TRUE))
```

    #> # A tibble: 1,361 x 2
    #>    zip       zip_norm
    #>    <chr>     <chr>   
    #>  1 33308     33308   
    #>  2 48179     48179   
    #>  3 97415     97415   
    #>  4 28217     28217   
    #>  5 48309     48309   
    #>  6 75201     75201   
    #>  7 49707     49707   
    #>  8 46410     46410   
    #>  9 488643986 48864   
    #> 10 33408     33408   
    #> # … with 1,351 more rows

``` r
progress_table(
  milr$zip,
  milr$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 zip        0.920       1361 0.00237   571    299
#> 2 zip_norm   0.999       1114 0.00293     9      9
```

### State

The `state` variable does not need to be cleaned.

``` r
prop_in(milr$state, valid_state)
#> [1] 1
```

### City

``` r
milr <- mutate(milr, city_norm = normal_city(city, abbs = usps_city, na = invalid_city))
```

``` r
milr <- milr %>% 
  rename(city_raw = city) %>% 
  left_join(
    y = zipcodes,
    by = c(
      "state" = "state",
      "zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(city_norm, city_match),
    match_dist = str_dist(city_norm, city_match),
    city_swap = if_else(
      condition = match_abb | match_dist == 1,
      true = city_match,
      false = city_norm
    )
  )
```

``` r
out <- milr %>% 
  filter(city_swap %out% valid_city) %>% 
  count(city_swap, state, sort = TRUE) %>% 
  drop_na()
```

``` r
check_file <- here("mi", "lobby", "data", "api_check.csv")
if (file_exists(check_file)) {
  check <- read_csv(
    file = check_file
  )
} else {
  check <- pmap_dfr(
    .l = list(
      out$city_swap, 
      out$state
    ), 
    .f = check_city, 
    key = Sys.getenv("GEOCODE_KEY"), 
    guess = TRUE
  ) %>% 
    mutate(guess = coalesce(guess_city, guess_place)) %>% 
    select(-guess_city, -guess_place)
  write_csv(
    x = check,
    path = check_file
  )
}
```

``` r
valid_locality <- check$guess[check$check_city_flag]
```

``` r
valid_locality <- check %>% 
  filter(!check_city_flag) %>% 
  mutate(
    abb = is_abbrev(original_city, guess),
    dist = str_dist(original_city, guess)
  ) %>%
  filter(abb | dist <= 3) %>% 
  pull(guess) %>% 
  c(valid_locality)
```

``` r
many_city <- c(valid_city, extra_city, valid_locality)
```

| stage      | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :--------- | -------: | ----------: | -------: | -----: | ------: |
| city\_raw  |    0.982 |         725 |    0.000 |    126 |      71 |
| city\_norm |    0.991 |         715 |    0.000 |     61 |      50 |
| city\_swap |    0.998 |         678 |    0.005 |     14 |      12 |

## Export

``` r
proc_dir <- here("mi", "lobby", "data", "processed")
dir_create(proc_dir)
```

``` r
write_csv(
  x = milr,
  path = glue("{proc_dir}/mi_lobby_reg.csv"),
  na = ""
)
```
