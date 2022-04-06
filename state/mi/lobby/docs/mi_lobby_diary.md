Michigan Lobbyists
================
Kiernan Nicholls
2020-04-06 16:57:06

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Registration](#registration)
  - [Contributions](#contributions)

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
  gluedown, # printing markdown
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
#> [1] "/home/kiernan/Code/accountability_datacleaning/R_campfin"
```

## Registration

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
# changes from time to time
lob_url <- "https://miboecfr.nictusa.com/cfr/dumpdata/aaaMxayCb/mi_lobby.sh"
lob_path <- url2path(lob_url, raw_dir)
if (!file_exists(lob_path)) {
  download.file(
    url = lob_url,
    destfile = lob_path,
    method = "curl",
    extra = "--insecure"
  )
}
```

### Vars

| Variable | Description                                               |
| :------- | :-------------------------------------------------------- |
| `id`     | Unique Bureau ID\# of this Lobbyist or Agent              |
| `type`   | Type of Lobby (A = Agent, L = Lobbyist)                   |
| `last`   | Last or Full Name of the Individual or Lobby Organization |
| `first`  | First Name of the Individual Lobbyist or Agent            |
| `mi`     | Middle Name of the Individual Lobbyist or Agent           |
| `sig`    | Official Signatory or Contact Person for this Lobby       |
| `addr`   | Mailing Street Address of this Lobby                      |
| `city`   | Mailing City of this Lobby                                |
| `state`  | Mailing State of this Lobby                               |
| `zip`    | Mailing Zipcode of this Lobby                             |
| `phone`  | Phone Number of this Lobby                                |
| `reg`    | Date this Lobby became an Active Lobbyist or Agent        |
| `term`   | Date this Lobby Terminated all Lobbying activity          |

### Import

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
  col_names = var_names,
  col_types = cols(
    .default = col_character(),
    type = col_factor(),
    reg = col_date_usa(),
    term = col_date_usa()
  )
)
```

### Explore

``` r
head(milr)
#> # A tibble: 6 x 13
#>   id     type  last      first  mi    sig   addr      city  state zip   phone reg        term      
#>   <chr>  <fct> <chr>     <chr>  <chr> <chr> <chr>     <chr> <chr> <chr> <chr> <date>     <date>    
#> 1 014673 A     (RADKE) … JODI   L     <NA>  PO BOX 7… LOVE… CO    80539 9702… 2019-09-12 NA        
#> 2 012102 A     A L CANA… <NA>   <NA>  ALAN… PO BOX 3… EAST… MI    48826 5172… 2012-05-01 NA        
#> 3 013358 A     AARON     RICHA… <NA>  <NA>  201 TOWN… LANS… MI    48933 5173… 2016-04-12 NA        
#> 4 013523 A     AASHEIM   JOHAN  <NA>  <NA>  101 S WA… LANS… MI    48933 5178… 2016-09-20 NA        
#> 5 013910 A     ABLER     GREGO… M     <NA>  110 W MI… LANS… MI    48933 5173… 2017-11-06 NA        
#> 6 012557 A     ABOOD     JEFFR… LANCE <NA>  470 NORT… BIRM… MI    48009 2486… 2013-11-01 NA
tail(milr)
#> # A tibble: 6 x 13
#>   id     type  last   first  mi     sig       addr    city  state zip   phone reg        term      
#>   <chr>  <fct> <chr>  <chr>  <chr>  <chr>     <chr>   <chr> <chr> <chr> <chr> <date>     <date>    
#> 1 009479 A     ZIMNY  TABIT… <NA>   <NA>      121 W … LANS… MI    48933 5174… 2005-03-14 NA        
#> 2 014039 A     ZUBAR… ILYA   <NA>   <NA>      777 WO… DETR… MI    48226 3136… 2018-02-14 NA        
#> 3 010290 A     ZUHLKE DAVID  J      <NA>      826 MU… LANS… MI    48917 5174… 2007-07-23 NA        
#> 4 006811 A     ZYBLE  DAVID  A      <NA>      1 CORP… LANS… MI    48951 5173… 1996-12-09 NA        
#> 5 <NA>   <NA>  <NA>   <NA>   End o… 1,473 to… <NA>    <NA>  <NA>  <NA>  <NA>  NA         NA        
#> 6 <NA>   <NA>  <NA>   <NA>   <NA>   <NA>      <NA>    <NA>  <NA>  <NA>  <NA>  NA         NA
glimpse(sample_frac(milr))
#> Rows: 1,475
#> Columns: 13
#> $ id    <chr> "014243", "013214", "014806", "000009", "004393", "010122", "012745", "010764", "0…
#> $ type  <fct> A, A, A, A, A, A, A, A, A, A, A, A, A, A, A, A, A, A, A, A, A, A, A, A, A, A, A, A…
#> $ last  <chr> "MADDIPATI", "KAPLAN RUDOLPH", "BZDOK", "KHEDER", "MCLAUCHLAN", "SIKKEMA", "RABENO…
#> $ first <chr> "SRIKANTH", "ROCHELLE", "CHRISTOPHER", "NOBLE", "MICHAEL", "KENNETH", "JOHN", "BRA…
#> $ mi    <chr> NA, NA, NA, "P", "D", "R", NA, NA, "S", NA, NA, NA, "E", NA, NA, "D", NA, NA, NA, …
#> $ sig   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "GABRIEL TS SCHNEI…
#> $ addr  <chr> "ONE ENERGY PLAZA", "550 W MERRILL STREET SUITE 200", "420 E FRONT ST", "201 N WAS…
#> $ city  <chr> "JACKSON", "BIRMINGHAM", "TRAVERSE CITY", "LANSING", "DETROIT", "GRANDVILLE", "LAN…
#> $ state <chr> "MI", "MI", "MI", "MI", "MI", "MI", "MI", "MI", "MI", "MI", "CA", "IL", "MI", "MI"…
#> $ zip   <chr> "49201", "48009", "49686", "48933", "48201", "49418", "48933", "48933", "48906", "…
#> $ phone <chr> "5177880635", "2485590840", "2319460044", "5174822896", "3134716082", "6165341879"…
#> $ reg   <date> 2018-10-03, 2015-10-19, 2020-01-20, 1983-10-07, 1988-10-28, 2007-02-05, 2014-06-0…
#> $ term  <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
```

As we can see from `tail()`, the last two rows still need to be removed.

The `id` variable is unique to each lobbyist, so we can use it to remove
the summary rows at the bottom of the file.

``` r
col_stats(milr, n_distinct)
#> # A tibble: 13 x 4
#>    col   class      n        p
#>    <chr> <chr>  <int>    <dbl>
#>  1 id    <chr>   1474 0.999   
#>  2 type  <fct>      2 0.00136 
#>  3 last  <chr>   1284 0.871   
#>  4 first <chr>    530 0.359   
#>  5 mi    <chr>     80 0.0542  
#>  6 sig   <chr>    104 0.0705  
#>  7 addr  <chr>    999 0.677   
#>  8 city  <chr>    198 0.134   
#>  9 state <chr>     30 0.0203  
#> 10 zip   <chr>    338 0.229   
#> 11 phone <chr>    883 0.599   
#> 12 reg   <date>  1110 0.753   
#> 13 term  <date>     1 0.000678
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
#>  4 first <chr>    106 0.0720  
#>  5 mi    <chr>    914 0.621   
#>  6 sig   <chr>   1368 0.929   
#>  7 addr  <chr>      0 0       
#>  8 city  <chr>      0 0       
#>  9 state <chr>      1 0.000679
#> 10 zip   <chr>      1 0.000679
#> 11 phone <chr>    102 0.0692  
#> 12 reg   <date>     1 0.000679
#> 13 term  <date>  1473 1
```

There are no duplicate rows in the database.

``` r
sum(duplicated(milr))
#> [1] 0
```

The database contains both outside lobbyist and lobbying agents.

![](../plots/plot_agent-1.png)<!-- -->

100% of lobbyists in the database have a termination date, meaning only
0% of the records identify active lobbyists.

``` r
prop_na(milr$term)
#> [1] 1
```

We can add the registration year using `lubridate::year()` on the date
column.

``` r
milr <- mutate(milr, year = year(reg))
```

![](../plots/year_plot-1.png)<!-- -->

### Wrangle

To improve the searchability and consistency of the database, we can
perform some very basic and confident text normalization.

#### Phone

We can convert the phone numbers into a standard charatcer (i.e.,
non-numeric) format.

``` r
milr <- mutate(milr, phone_norm = normal_phone(phone))
```

    #> # A tibble: 883 x 2
    #>    phone      phone_norm    
    #>    <chr>      <chr>         
    #>  1 6468228057 (646) 822-8057
    #>  2 2482983425 (248) 298-3425
    #>  3 3175653274 (317) 565-3274
    #>  4 7349452636 (734) 945-2636
    #>  5 5179995414 (517) 999-5414
    #>  6 5174873376 (517) 487-3376
    #>  7 6467431330 (646) 743-1330
    #>  8 8012623942 (801) 262-3942
    #>  9 2487374477 (248) 737-4477
    #> 10 <NA>       <NA>          
    #> # … with 873 more rows

#### Address

We can use `campfin::normal_address()` to improve the consistency in the
`addr` variable.

``` r
milr <- mutate(milr, addr_norm = normal_address(addr, abbs = usps_street))
```

    #> # A tibble: 998 x 2
    #>    addr                                          addr_norm                                 
    #>    <chr>                                         <chr>                                     
    #>  1 108 WILMOT RD  MS #1844                       108 WILMOT RD MS 1844                     
    #>  2 120 W OTTAWA ST                               120 W OTTAWA ST                           
    #>  3 332 TOWNSEND ST                               332 TOWNSEND ST                           
    #>  4 PO BOX 63                                     PO BOX 63                                 
    #>  5 185 CALAIS COURT SE                           185 CALAIS CT SE                          
    #>  6 111 S CAPITOL AVE 6TH FL %STATE BUDGET OFFICE 111 S CAPITOL AVE 6 TH FL STATE BUDGET OFC
    #>  7 4647 MERIDIAN RD                              4647 MERIDIAN RD                          
    #>  8 200 RENAISSANCE CENTER STE 3900               200 RENAISSANCE CTR STE 3900              
    #>  9 347 N WEST TORCH LAKE DRIVE                   347 N W TORCH LK DR                       
    #> 10 PO BOX 8647 % CITY OF ANN ARBOR               PO BOX 8647 CITY OF ANN ARBOR             
    #> # … with 988 more rows

#### ZIP

``` r
milr <- mutate(milr, zip_norm = normal_zip(zip, na_rep = TRUE))
```

    #> # A tibble: 338 x 2
    #>    zip   zip_norm
    #>    <chr> <chr>   
    #>  1 60091 60091   
    #>  2 77002 77002   
    #>  3 63040 63040   
    #>  4 48909 48909   
    #>  5 89128 89128   
    #>  6 49083 49083   
    #>  7 48864 48864   
    #>  8 46204 46204   
    #>  9 48875 48875   
    #> 10 48603 48603   
    #> # … with 328 more rows

``` r
progress_table(
  milr$zip,
  milr$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct  prop_na n_out n_diff
#>   <chr>      <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 zip        0.951        338 0.000679    72     48
#> 2 zip_norm   0.999        300 0.000679     2      3
```

#### State

The `state` variable does not need to be cleaned.

``` r
prop_in(milr$state, valid_state)
#> [1] 1
```

#### City

``` r
milr <- mutate(
  .data = milr, 
  city_norm = normal_city(
    city = city, 
    abbs = usps_city, 
    na = invalid_city
  )
)
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
      condition = !is.na(city_match) & (match_abb | match_dist == 1),
      true = city_match,
      false = city_norm
    )
  ) %>% 
  select(
    -city_match,
    -match_abb,
    -match_dist
  )
```

``` r
out <- milr %>% 
  filter(city_swap %out% valid_city) %>% 
  count(city_swap, state, sort = TRUE) %>% 
  drop_na()
```

``` r
many_city <- c(valid_city, extra_city)
```

| stage      | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :--------- | -------: | ----------: | -------: | -----: | ------: |
| city\_raw  |    0.988 |         197 |        0 |     17 |      11 |
| city\_norm |    0.993 |         195 |        0 |     10 |       5 |
| city\_swap |    0.994 |         194 |        0 |      9 |       4 |

### Export

``` r
clean_dir <- dir_create(here("mi", "lobby", "data", "clean"))
clean_path <- path(clean_dir, "mi_lobby_reg.csv")
write_csv(milr, path = clean_path, na = "")
```

``` r
file_size(clean_path)
#> 248K
guess_encoding(clean_path)
#> # A tibble: 1 x 2
#>   encoding confidence
#>   <chr>         <dbl>
#> 1 ASCII             1
```

## Contributions

``` r
exp_url <- "https://miboecfr.nictusa.com/cfr/dumpall/miloball.sh"
exp_path <- url2path(exp_url, raw_dir)
if (!file_exists(exp_path)) {
  download.file(
    url = exp_url,
    destfile = exp_path,
    method = "curl",
    extra = "--insecure"
  )
}
```

``` r
mile <- read_delim(
  file = exp_path,
  delim = "\t",
  skip = 2,
  col_names = exp_names,
  escape_backslash = FALSE,
  escape_double = FALSE,
  col_types = cols(
    .default = col_character(),
    rpt_year = col_integer(),
    exp_date = col_date_usa(),
    exp_amt = col_double(),
    ytd_fb = col_double()
  )
) %>% 
  filter(!is.na(rpt_year))
```

``` r
head(mile)
#> # A tibble: 6 x 17
#>   rpt_year rpt_type lob_last lob_first lob_mi lob_type lob_id exp_type po_title po_last po_first
#>      <int> <chr>    <chr>    <chr>     <chr>  <chr>    <chr>  <chr>    <chr>    <chr>   <chr>   
#> 1     2001 SR       MICHIGA… <NA>      <NA>   L        1519   Financi… REPRESE… MORTIM… MICKEY  
#> 2     2001 SR       APPLE I… <NA>      <NA>   L        8030   Financi… EXECUTI… BRANDE… JIM     
#> 3     2001 SR       DETROIT… <NA>      <NA>   L        2349   Financi… REPRESE… ALLEN   JASON   
#> 4     2001 SR       DETROIT… <NA>      <NA>   L        2349   Financi… REPRESE… BISBEE  CLARK   
#> 5     2001 SR       DETROIT… <NA>      <NA>   L        2349   Financi… SENATOR  BULLARD WILLIS  
#> 6     2001 SR       DETROIT… <NA>      <NA>   L        2349   Financi… SENATOR  BENNETT LOREN   
#> # … with 6 more variables: po_mi <chr>, lob_why <chr>, exp_date <date>, exp_amt <dbl>,
#> #   ytd_fb <dbl>, doc_id <chr>
tail(mile)
#> # A tibble: 6 x 17
#>   rpt_year rpt_type lob_last lob_first lob_mi lob_type lob_id exp_type po_title po_last po_first
#>      <int> <chr>    <chr>    <chr>     <chr>  <chr>    <chr>  <chr>    <chr>    <chr>   <chr>   
#> 1     2019 WR       KELLEY … <NA>      <NA>   L        7414   Group F… SENATOR… <NA>    <NA>    
#> 2     2019 WR       KELLEY … <NA>      <NA>   L        7414   Group F… SENATOR… <NA>    <NA>    
#> 3     2019 WR       KELLEY … <NA>      <NA>   L        7414   Group F… SENATOR… <NA>    <NA>    
#> 4     2019 WR       KELLEY … <NA>      <NA>   L        7414   Group F… SENATOR… <NA>    <NA>    
#> 5     2019 WR       BRESLIN  MATTHEW   T      A        11498  Group F… REPRESE… <NA>    <NA>    
#> 6     2019 WR       TAYLOR … MORENO    <NA>   A        14647  Group F… REPRESE… <NA>    <NA>    
#> # … with 6 more variables: po_mi <chr>, lob_why <chr>, exp_date <date>, exp_amt <dbl>,
#> #   ytd_fb <dbl>, doc_id <chr>
glimpse(sample_frac(mile))
#> Rows: 15,122
#> Columns: 17
#> $ rpt_year  <int> 2013, 2019, 2008, 2013, 2001, 2008, 2007, 2004, 2016, 2013, 2007, 2011, 2014, …
#> $ rpt_type  <chr> "SR", "WR", "SR", "SR", "SR", "WR", "WR", "SR", "SR", "WR", "WR", "WR", "SR", …
#> $ lob_last  <chr> "MICHIGAN BELL TELEPHONE (AT AND T MICHIGAN)", "MICHIGAN BELL TELEPHONE (AT AN…
#> $ lob_first <chr> NA, NA, NA, NA, NA, NA, NA, NA, "JAMES", NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ lob_mi    <chr> NA, NA, NA, NA, NA, NA, NA, NA, "L", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ lob_type  <chr> "L", "L", "A", "L", "L", "A", "A", "A", "A", "A", "L", "L", "L", "L", "L", "L"…
#> $ lob_id    <chr> "346", "346", "27", "346", "2349", "119", "119", "27", "7397", "27", "325", "8…
#> $ exp_type  <chr> "Individual Food & Beverage", "Individual Food & Beverage", "Individual Food &…
#> $ po_title  <chr> "REPRESENTATIVE", "REPRESENTATIVE", "REPRESENTATIVE", "REPRESENTATIVE", "REPRE…
#> $ po_last   <chr> "VICTORY", "COLEMAN", "CORRIVEAU", "NATHAN", "GODCHAUX", "ANGERER", "MELTZER",…
#> $ po_first  <chr> "ROGER", "KEVIN", "MARC", "DAVID", "PATRICIA", "KATHY", "KIMBERLY", "JASON", "…
#> $ po_mi     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ lob_why   <chr> NA, NA, NA, NA, "ROUNDTABLE DISCUSSION", NA, NA, NA, NA, NA, NA, NA, NA, "LUNC…
#> $ exp_date  <date> NA, NA, NA, NA, 2001-05-31, NA, NA, NA, NA, NA, NA, NA, NA, 2010-12-14, NA, 2…
#> $ exp_amt   <dbl> 20.39, NA, 435.07, 45.82, 939.35, 78.00, 156.00, 176.23, 74.86, 233.65, 4.50, …
#> $ ytd_fb    <dbl> NA, 18.18, 435.07, NA, NA, 78.00, 156.00, 176.23, 74.86, 708.74, 4.50, 146.77,…
#> $ doc_id    <chr> "194195", "254702", "152954", "194195", "96839", "156326", "148826", "120145",…
```

``` r
col_stats(mile, count_na)
#> # A tibble: 17 x 4
#>    col       class      n       p
#>    <chr>     <chr>  <int>   <dbl>
#>  1 rpt_year  <int>      0 0      
#>  2 rpt_type  <chr>      0 0      
#>  3 lob_last  <chr>      0 0      
#>  4 lob_first <chr>  11754 0.777  
#>  5 lob_mi    <chr>  13157 0.870  
#>  6 lob_type  <chr>      0 0      
#>  7 lob_id    <chr>      0 0      
#>  8 exp_type  <chr>      0 0      
#>  9 po_title  <chr>     54 0.00357
#> 10 po_last   <chr>   2269 0.150  
#> 11 po_first  <chr>   2313 0.153  
#> 12 po_mi     <chr>  15016 0.993  
#> 13 lob_why   <chr>  12272 0.812  
#> 14 exp_date  <date> 12280 0.812  
#> 15 exp_amt   <dbl>    317 0.0210 
#> 16 ytd_fb    <dbl>   3110 0.206  
#> 17 doc_id    <chr>      0 0
```

``` r
col_stats(mile, n_distinct)
#> # A tibble: 17 x 4
#>    col       class      n        p
#>    <chr>     <chr>  <int>    <dbl>
#>  1 rpt_year  <int>     19 0.00126 
#>  2 rpt_type  <chr>      2 0.000132
#>  3 lob_last  <chr>    593 0.0392  
#>  4 lob_first <chr>    130 0.00860 
#>  5 lob_mi    <chr>     32 0.00212 
#>  6 lob_type  <chr>      2 0.000132
#>  7 lob_id    <chr>    611 0.0404  
#>  8 exp_type  <chr>      4 0.000265
#>  9 po_title  <chr>   1314 0.0869  
#> 10 po_last   <chr>    950 0.0628  
#> 11 po_first  <chr>    520 0.0344  
#> 12 po_mi     <chr>     33 0.00218 
#> 13 lob_why   <chr>   1239 0.0819  
#> 14 exp_date  <date>  1496 0.0989  
#> 15 exp_amt   <dbl>   8955 0.592   
#> 16 ytd_fb    <dbl>   7629 0.504   
#> 17 doc_id    <chr>   2583 0.171
```

![](../plots/lob_exp_amt-1.png)<!-- -->

![](../plots/lob_exp_year-1.png)<!-- -->

``` r
write_csv(
  x = mile,
  path = path(clean_dir, "mi_lobby_exp.csv"),
  na = ""
)
```
