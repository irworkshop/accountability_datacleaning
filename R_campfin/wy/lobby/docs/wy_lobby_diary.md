Wyoming Lobbyists
================
Kiernan Nicholls
2019-12-03 14:54:26

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
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
  httr, # http queries
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

Data is obtained from the Wyoming Secretary of State’s office [Lobbying
Center](https://lobbyist.wyo.gov/Lobbyist/Default.aspx). From their, we
can download “a zip file containing the lobbyist data files for the
current period.” We’ll make a `httr::GET()` request on the file to
download write the raw ZIP archive to disk.

``` r
raw_dir <- here("wy", "lobby", "data", "raw")
dir_create(raw_dir)
lob_url <- "https://lobbyist.wyo.gov/Lobbyist/Download.aspx"
lob_head <- headers(HEAD(lob_url))
lob_file <- str_remove(lob_head[["content-disposition"]], "(.*);\\sfilename=")
lob_path <- str_c(raw_dir, lob_file, sep = "/")
if (!this_file_new(lob_path)) {
  GET(lob_url, write_disk(lob_path, overwrite = TRUE))
  unzip(lob_path, exdir = raw_dir)
}
```

## Import

The `schemaLobbyist.pdf` file outlines the relationship between the
three text files included in the ZIP archive. Using this guide, we can
add the principal organizations to each lobbyist.

First, we will use `vroom::vroom()` to read the data frame of lobbyists.

``` r
lobs <- vroom(
  .name_repair = make_clean_names,
  file = glue("{raw_dir}/LOBBYIST.txt"),
  delim = "|",
  col_types = cols(
    .default = col_character(),
    REGISTRATION_DATE = col_date_usa(),
    EXPIRATION_DATE = col_date_usa(),
    TERMINATED_DATE = col_date_usa()
  )
)

lobs <- lobs %>% 
  rename(
    lob_id = lobbyist_id,
    lob_num = lobbyist_num,
    lob_status = status_id,
    lob_reg = registration_date,
    lob_exp = expiration_date,
    lob_badge = name_on_badge,
    lob_first = first_name,
    lob_middle = middle_name,
    lob_last = last_name,
    zip = postal_code,
    lob_email = email,
    lob_term = terminated_date
  )

lobs <- lobs %>%
  mutate(lob_status = equals(lob_status, "Active")) %>% 
  rename(lob_active = lob_status)
```

Then, we will read the `LOBBYIST_ORGANIZATION_XREF.txt` file to get the
relational keys needed to add the information from
`LOBBYIST_ORGANIZATION.txt` to our lobbyists data frame.

``` r
xref <- vroom(
  .name_repair = make_clean_names,
  file = glue("{raw_dir}/LOBBYIST_ORGANIZATION_XREF.txt"),
  delim = "|",
  col_types = cols(
    .default = col_character()
  )
)

xref <- xref %>%
  remove_empty("cols") %>% 
  rename(
    xref_id = lobbyist_organization_xref_id,
    lob_id = lobbyist_id,
    org_id = lobbyist_organization_id
  )
```

``` r
orgs <- vroom(
  .name_repair = make_clean_names,
  file = glue("{raw_dir}/LOBBYIST_ORGANIZATION.txt"),
  delim = "|",
  col_types = cols(
    .default = col_character()
  )
)

orgs <- orgs %>% 
  rename(
    org_id = lobbyist_organization_id,
    org_num = lobbyist_organization_num,
    org_name = name,
    zip = postal_code
  ) %>% 
  mutate_at(vars(phone), str_remove, "\\|$") %>% 
  na_if("")
```

Finally, we can use `dplyr::*_join()` to combine these three tables into
a single data frame with the full record of a lobbyist and a client
relationship.

``` r
wylr <- lobs %>% 
  left_join(xref, by = "lob_id") %>% 
  left_join(orgs, by = "org_id", suffix = c("_lob", "_org")) %>% 
  rename_prefix(suffix = c("_lob", "_org"))
```

## Explore

    #> # A tibble: 6 x 31
    #>   lob_id lob_num lob_active lob_reg    lob_exp    lob_badge lob_first lob_middle lob_last lob_addr1
    #>   <chr>  <chr>   <lgl>      <date>     <date>     <chr>     <chr>     <chr>      <chr>    <chr>    
    #> 1 1002   102124  TRUE       2002-11-07 2020-04-30 Jan Stal… Jan       <NA>       Stalcup  Wyoming …
    #> 2 1004   102126  TRUE       2013-01-08 2020-04-30 Peter Il… Peter     S.         Illoway  839 Ridg…
    #> 3 1004   102126  TRUE       2013-01-08 2020-04-30 Peter Il… Peter     S.         Illoway  839 Ridg…
    #> 4 1004   102126  TRUE       2013-01-08 2020-04-30 Peter Il… Peter     S.         Illoway  839 Ridg…
    #> 5 1004   102126  TRUE       2013-01-08 2020-04-30 Peter Il… Peter     S.         Illoway  839 Ridg…
    #> 6 1004   102126  TRUE       2013-01-08 2020-04-30 Peter Il… Peter     S.         Illoway  839 Ridg…
    #> # … with 21 more variables: lob_addr2 <chr>, lob_addr3 <chr>, lob_city <chr>, lob_state <chr>,
    #> #   lob_zip <chr>, lob_country <chr>, lob_phone <chr>, lob_email <chr>, lob_term <date>,
    #> #   xref_id <chr>, org_id <chr>, org_num <chr>, org_name <chr>, org_addr1 <chr>, org_addr2 <chr>,
    #> #   org_addr3 <chr>, org_city <chr>, org_state <chr>, org_zip <chr>, org_country <chr>,
    #> #   org_phone <chr>
    #> # A tibble: 6 x 31
    #>   lob_id lob_num lob_active lob_reg    lob_exp    lob_badge lob_first lob_middle lob_last lob_addr1
    #>   <chr>  <chr>   <lgl>      <date>     <date>     <chr>     <chr>     <chr>      <chr>    <chr>    
    #> 1 990    102112  TRUE       2012-11-28 2020-04-30 Marianne… Marianne  K.         Shanor   2515 War…
    #> 2 990    102112  TRUE       2012-11-28 2020-04-30 Marianne… Marianne  K.         Shanor   2515 War…
    #> 3 990    102112  TRUE       2012-11-28 2020-04-30 Marianne… Marianne  K.         Shanor   2515 War…
    #> 4 990    102112  TRUE       2012-11-28 2020-04-30 Marianne… Marianne  K.         Shanor   2515 War…
    #> 5 990    102112  TRUE       2012-11-28 2020-04-30 Marianne… Marianne  K.         Shanor   2515 War…
    #> 6 995    102117  TRUE       2002-11-07 2020-04-30 Kathy Ve… Kathy     <NA>       Vetter   115 E 22…
    #> # … with 21 more variables: lob_addr2 <chr>, lob_addr3 <chr>, lob_city <chr>, lob_state <chr>,
    #> #   lob_zip <chr>, lob_country <chr>, lob_phone <chr>, lob_email <chr>, lob_term <date>,
    #> #   xref_id <chr>, org_id <chr>, org_num <chr>, org_name <chr>, org_addr1 <chr>, org_addr2 <chr>,
    #> #   org_addr3 <chr>, org_city <chr>, org_state <chr>, org_zip <chr>, org_country <chr>,
    #> #   org_phone <chr>
    #> Observations: 385
    #> Variables: 31
    #> $ lob_id      <chr> "1002", "1004", "1004", "1004", "1004", "1004", "107", "107", "107", "107", …
    #> $ lob_num     <chr> "102124", "102126", "102126", "102126", "102126", "102126", "101229", "10122…
    #> $ lob_active  <lgl> TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE…
    #> $ lob_reg     <date> 2002-11-07, 2013-01-08, 2013-01-08, 2013-01-08, 2013-01-08, 2013-01-08, 200…
    #> $ lob_exp     <date> 2020-04-30, 2020-04-30, 2020-04-30, 2020-04-30, 2020-04-30, 2020-04-30, 202…
    #> $ lob_badge   <chr> "Jan Stalcup", "Peter Illoway", "Peter Illoway", "Peter Illoway", "Peter Ill…
    #> $ lob_first   <chr> "Jan", "Peter", "Peter", "Peter", "Peter", "Peter", "Sherlyn", "Sherlyn", "S…
    #> $ lob_middle  <chr> NA, "S.", "S.", "S.", "S.", "S.", NA, NA, NA, NA, NA, NA, NA, NA, NA, "Pete"…
    #> $ lob_last    <chr> "Stalcup", "Illoway", "Illoway", "Illoway", "Illoway", "Illoway", "Kaiser", …
    #> $ lob_addr1   <chr> "Wyoming School Boards Association", "839 Ridgeland Street", "839 Ridgeland …
    #> $ lob_addr2   <chr> "2323 Pioneer Ave", NA, NA, NA, NA, NA, NA, NA, NA, NA, "1580 Logan St., Sui…
    #> $ lob_addr3   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ lob_city    <chr> "Cheyenne", "Cheyenne", "Cheyenne", "Cheyenne", "Cheyenne", "Cheyenne", "Che…
    #> $ lob_state   <chr> "WY", "WY", "WY", "WY", "WY", "WY", "WY", "WY", "WY", "WY", "CO", "WY", "WY"…
    #> $ lob_zip     <chr> "82001", "82009", "82009", "82009", "82009", "82009", "82009", "82009", "820…
    #> $ lob_country <chr> "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA",…
    #> $ lob_phone   <chr> "3076341112", "3076352973", "3076352973", "3076352973", "3076352973", "30763…
    #> $ lob_email   <chr> NA, "peters1940@gmail.com", "peters1940@gmail.com", "peters1940@gmail.com", …
    #> $ lob_term    <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
    #> $ xref_id     <chr> "2243", "2496", "2497", "2498", "2499", "2500", "2227", "2228", "2229", "223…
    #> $ org_id      <chr> "2243", "2496", "2497", "2498", "2499", "2500", "2227", "2228", "2229", "223…
    #> $ org_num     <chr> "003380", "003633", "003634", "003635", "003636", "003637", "003364", "00336…
    #> $ org_name    <chr> "Wyoming School Boards Association", "Cameco Resources", "Cheyenne Regional …
    #> $ org_addr1   <chr> "Wyoming School Boards Association", "P O Box 1210", "P O Box 2210", "8305 O…
    #> $ org_addr2   <chr> "2323 Pioneer Ave", NA, NA, NA, NA, NA, NA, NA, NA, NA, "Suite 520", NA, NA,…
    #> $ org_addr3   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ org_city    <chr> "Cheyenne", "Glenrock", "Cheyenne", "Cheyenne", "Cheyenne", "Laramie", "Casp…
    #> $ org_state   <chr> "WY", "WY", "WY", "WY", "WY", "WY", "WY", "NC", "WY", "WY", "CO", "WY", "WY"…
    #> $ org_zip     <chr> "82001", "82637", "82003", "82007", "82009", "82070", "82601", "27101", "829…
    #> $ org_country <chr> "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA",…
    #> $ org_phone   <chr> "3076341112", "3073586541", "3076347071", "3076372700", "3076352973", NA, "3…

Most columns do not contain any missing information. Only 52 lobbyists
are missing either their phone number of email address. These variables
do not need to be flagged.

``` r
col_stats(wylr, count_na)
#> # A tibble: 31 x 4
#>    col         class      n      p
#>    <chr>       <chr>  <int>  <dbl>
#>  1 lob_id      <chr>      0 0     
#>  2 lob_num     <chr>      0 0     
#>  3 lob_active  <lgl>      0 0     
#>  4 lob_reg     <date>     0 0     
#>  5 lob_exp     <date>     0 0     
#>  6 lob_badge   <chr>      0 0     
#>  7 lob_first   <chr>      0 0     
#>  8 lob_middle  <chr>    305 0.792 
#>  9 lob_last    <chr>      0 0     
#> 10 lob_addr1   <chr>      0 0     
#> 11 lob_addr2   <chr>    321 0.834 
#> 12 lob_addr3   <chr>    380 0.987 
#> 13 lob_city    <chr>      0 0     
#> 14 lob_state   <chr>      0 0     
#> 15 lob_zip     <chr>      0 0     
#> 16 lob_country <chr>      0 0     
#> 17 lob_phone   <chr>     16 0.0416
#> 18 lob_email   <chr>     36 0.0935
#> 19 lob_term    <date>   384 0.997 
#> 20 xref_id     <chr>      0 0     
#> 21 org_id      <chr>      0 0     
#> 22 org_num     <chr>      0 0     
#> 23 org_name    <chr>      0 0     
#> 24 org_addr1   <chr>      0 0     
#> 25 org_addr2   <chr>    272 0.706 
#> 26 org_addr3   <chr>    381 0.990 
#> 27 org_city    <chr>      0 0     
#> 28 org_state   <chr>      0 0     
#> 29 org_zip     <chr>      0 0     
#> 30 org_country <chr>      0 0     
#> 31 org_phone   <chr>    119 0.309
```

As you’d expect, some columns are more distinct than others. In our
original lobbyist and organization tables, the respect `*_id` variables
are 100% distinct, but lobbyists are repeated for every client
organization in our joined data frame.

``` r
col_stats(wylr, n_distinct)
#> # A tibble: 31 x 4
#>    col         class      n       p
#>    <chr>       <chr>  <int>   <dbl>
#>  1 lob_id      <chr>    191 0.496  
#>  2 lob_num     <chr>    191 0.496  
#>  3 lob_active  <lgl>      2 0.00519
#>  4 lob_reg     <date>   125 0.325  
#>  5 lob_exp     <date>     2 0.00519
#>  6 lob_badge   <chr>    191 0.496  
#>  7 lob_first   <chr>    154 0.4    
#>  8 lob_middle  <chr>     31 0.0805 
#>  9 lob_last    <chr>    175 0.455  
#> 10 lob_addr1   <chr>    173 0.449  
#> 11 lob_addr2   <chr>     44 0.114  
#> 12 lob_addr3   <chr>      5 0.0130 
#> 13 lob_city    <chr>     43 0.112  
#> 14 lob_state   <chr>     24 0.0623 
#> 15 lob_zip     <chr>     58 0.151  
#> 16 lob_country <chr>      1 0.00260
#> 17 lob_phone   <chr>    168 0.436  
#> 18 lob_email   <chr>    168 0.436  
#> 19 lob_term    <date>     2 0.00519
#> 20 xref_id     <chr>    385 1      
#> 21 org_id      <chr>    385 1      
#> 22 org_num     <chr>    385 1      
#> 23 org_name    <chr>    294 0.764  
#> 24 org_addr1   <chr>    301 0.782  
#> 25 org_addr2   <chr>     74 0.192  
#> 26 org_addr3   <chr>      4 0.0104 
#> 27 org_city    <chr>     88 0.229  
#> 28 org_state   <chr>     37 0.0961 
#> 29 org_zip     <chr>    122 0.317  
#> 30 org_country <chr>      1 0.00260
#> 31 org_phone   <chr>    196 0.509
```

All but one of the lobbyists listed in the database have an “Active”
status. That lobbyist is the only one to have a termination date, as
we’d expect.

``` r
sum(!wylr$lob_active)
#> [1] 1
prop_na(wylr$lob_term)
#> [1] 0.9974026
prop_na(wylr$lob_term[wylr$lob_active])
#> [1] 1
```

## Wrangle

To improve the consistency and search ability of our accountability
database, we will perform some simple and **confident** manipulations to
the original data and create new, normalized variables.

### Year

First, we will add the year in which each lobbyist was registered.

``` r
wylr <- mutate(wylr, lob_year = year(lob_reg))
```

![](../plots/plot_reg_year-1.png)<!-- -->

### Phone

We can use `campfin::normal_phone()` to convert the numeric phone
numbers into an unambiguous character format. This prevents the column
from being read as a numeric variable.

``` r
wylr <- mutate_at(
  .tbl  = wylr,
  .vars = vars(ends_with("phone")),
  .funs = list(norm = normal_phone)
)
```

    #> # A tibble: 275 x 4
    #>    lob_phone  org_phone  lob_phone_norm org_phone_norm
    #>    <chr>      <chr>      <chr>          <chr>         
    #>  1 8015242767 8015242767 (801) 524-2767 (801) 524-2767
    #>  2 4062564047 4062564047 (406) 256-4047 (406) 256-4047
    #>  3 3078514895 <NA>       (307) 851-4895 <NA>          
    #>  4 3076352424 3076308602 (307) 635-2424 (307) 630-8602
    #>  5 3076346484 3072348142 (307) 634-6484 (307) 234-8142
    #>  6 3075090538 3076303466 (307) 509-0538 (307) 630-3466
    #>  7 2066216205 <NA>       (206) 621-6205 <NA>          
    #>  8 3077782000 3078723351 (307) 778-2000 (307) 872-3351
    #>  9 3074325802 3074325814 (307) 432-5802 (307) 432-5814
    #> 10 3076346484 <NA>       (307) 634-6484 <NA>          
    #> # … with 265 more rows

### Address

To normalize the street addresses, we will first `tidyr::unite()` each
address column into a single column and then pass that string to
`campfin::normal_address()`.

``` r
wylr <- wylr %>% 
  unite(
    starts_with("lob_addr"),
    col = "lob_addr_full",
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    lob_addr_norm = normal_address(
      address = lob_addr_full,
      abbs = usps_street
    )
  ) %>% 
  select(-ends_with("addr_full"))
```

``` r
wylr <- wylr %>% 
  unite(
    starts_with("org_addr"),
    col = "org_addr_full",
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    org_addr_norm = normal_address(
      address = org_addr_full,
      abbs = usps_street
    )
  ) %>% 
  select(-ends_with("addr_full"))
```

``` r
wylr %>% 
  select(starts_with("lob_addr")) %>% 
  distinct() %>% 
  sample_frac()
#> # A tibble: 177 x 4
#>    lob_addr1                 lob_addr2            lob_addr3 lob_addr_norm                          
#>    <chr>                     <chr>                <chr>     <chr>                                  
#>  1 2323 Pioneer Ave          <NA>                 <NA>      2323 PIONEER AVENUE                    
#>  2 1007 HOY ROAD             <NA>                 <NA>      1007 HOY ROAD                          
#>  3 1501 Stampede Ave.        #9019                <NA>      1501 STAMPEDE AVENUE 9019              
#>  4 PO Box 1894               <NA>                 <NA>      PO BOX 1894                            
#>  5 5 Wild Rose Ln.           <NA>                 <NA>      5 WILD ROSE LANE                       
#>  6 1675 Broadway St.         Suite 1250           <NA>      1675 BROADWAY STREET SUITE 1250        
#>  7 1800 Glenarm Place        Suite 950            <NA>      1800 GLENARM PLACE SUITE 950           
#>  8 200 East 8th Ave Suite 2… <NA>                 <NA>      200 EAST 8TH AVENUE SUITE 203          
#>  9 The Burron Firm, P.C.     1695 Morningstar Ro… <NA>      THE BURRON FIRM P C 1695 MORNINGSTAR R…
#> 10 64 Summer Hill Rd.        <NA>                 <NA>      64 SUMMER HILL ROAD                    
#> # … with 167 more rows
```

### ZIP

Our database uses 5-digit ZIP codes, so we can pass the original postal
code variables to `campfin::normal_zip()` to trim the strings and try
and repair and broken formats.

``` r
wylr <- mutate_at(
  .tbl  = wylr,
  .vars = vars(ends_with("zip")),
  .funs = list(norm = normal_zip),
  na_rep = TRUE
)
```

    #> # A tibble: 15 x 4
    #>    lob_zip    org_zip    lob_zip_norm org_zip_norm
    #>    <chr>      <chr>      <chr>        <chr>       
    #>  1 82003-1347 84145      82003        84145       
    #>  2 82003-1347 80112      82003        80112       
    #>  3 82601-1351 82601      82601        82601       
    #>  4 82003-1347 84093      82003        84093       
    #>  5 82003-0085 82003      82003        82003       
    #>  6 82003-1347 75201      82003        75201       
    #>  7 82003-1347 20171      82003        20171       
    #>  8 82003-1347 57109      82003        57109       
    #>  9 82003-1224 82003-1224 82003        82003       
    #> 10 82003-0965 82003      82003        82003       
    #> 11 82003-1347 80111      82003        80111       
    #> 12 82003-1347 83025      82003        83025       
    #> 13 82003-1347 84106      82003        84106       
    #> 14 82003-1347 82003-1347 82003        82003       
    #> 15 82003-1347 58503      82003        58503

This makes out new ZIP variables very clean.

    #> # A tibble: 4 x 6
    #>   stage        prop_in n_distinct prop_na n_out n_diff
    #>   <chr>          <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 lob_zip        0.932         58       0    26      5
    #> 2 lob_zip_norm   1             53       0     0      0
    #> 3 org_zip        0.979        122       0     8      7
    #> 4 org_zip_norm   1            115       0     0      0

### State

This database contains a mix of full state names and 2-letter
abbreviations; we can pass these variables to `campfin::normal_state()`
to try and convert them all the abbreviations.

``` r
wylr <- mutate_at(
  .tbl  = wylr,
  .vars = vars(ends_with("state")),
  .funs = list(norm = normal_state),
  abbreviate = TRUE
)

wylr <- wylr %>% 
  mutate_at(
    .vars = vars(ends_with("state_norm")),
    .funs = str_replace, 
    "WY WY", "WY"
  )
```

    #> # A tibble: 59 x 4
    #>    lob_state    org_state    lob_state_norm org_state_norm
    #>    <chr>        <chr>        <chr>          <chr>         
    #>  1 WY           NC           WY             NC            
    #>  2 WY           WA           WY             WA            
    #>  3 WY           MD           WY             MD            
    #>  4 WY           WI           WY             WI            
    #>  5 WASHINGTON   Washington   WA             WA            
    #>  6 WY - Wyoming WY - Wyoming WY             WY            
    #>  7 WY           MA           WY             MA            
    #>  8 WY           IL           WY             IL            
    #>  9 MN           CA           MN             CA            
    #> 10 DC           DC           DC             DC            
    #> # … with 49 more rows

    #> # A tibble: 4 x 6
    #>   stage          prop_in n_distinct prop_na n_out n_diff
    #>   <chr>            <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 lob_state        0.969         24       0    12      6
    #> 2 lob_state_norm   1             19       0     0      0
    #> 3 org_state        0.932         37       0    26      7
    #> 4 org_state_norm   1             30       0     0      0

### City

The city values are typically the hardest to normalize due to the
variety of valid formats. Again, the `campfin::normal_city()` function
reduces inconsistencies and removes invalid values.

``` r
wylr <- mutate_at(
  .tbl  = wylr,
  .vars = vars(ends_with("city")),
  .funs = list(norm = normal_city),
  abbs = usps_city,
  na = invalid_city
)
```

Then, we can compare these normalized values to the *expected* values
for that record’s ZIP code. If the two values are similar, we can
confidently assume a typo was made and default to the expected value.

``` r
wylr <- wylr %>% 
  left_join(
    y = zipcodes,
    by = c(
      "org_state_norm" = "state",
      "org_zip_norm" = "zip"
    )
  ) %>% 
  rename(org_city_match = city) %>% 
  mutate(
    org_match_abb = is_abbrev(org_city_norm, org_city_match),
    org_match_dist = str_dist(org_city_norm, org_city_match),
    org_city_swap = if_else(
      condition = org_match_abb | org_match_dist == 1,
      true = org_city_match,
      false = org_city_norm
    )
  ) %>% 
  select(
    -org_city_match,
    -org_match_abb,
    -org_match_dist
  )
```

Our relatively few city values were already very clean, but this process
was able to make some quick and easy improvements.

    #> # A tibble: 5 x 6
    #>   stage         prop_in n_distinct prop_na n_out n_diff
    #>   <chr>           <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 lob_city)       1             40 0           0      0
    #> 2 lob_city_norm   1             40 0           0      0
    #> 3 org_city)       0.961         84 0          15      7
    #> 4 org_city_norm   0.966         83 0          13      5
    #> 5 org_city_swap   0.977         83 0.00260     9      4

Now we can remove the normalized city column in favor of our improved
compared value.

``` r
wylr <- wylr %>% 
  select(-org_city_norm) %>% 
  rename(org_city_norm = org_city_swap)
```

Even the few remaining values are actually valid and are just absent
from our list.

``` r
wylr %>% 
  filter(org_city_norm %out% valid_city) %>% 
  count(org_zip_norm, org_city_norm, sort = TRUE)
#> # A tibble: 4 x 3
#>   org_zip_norm org_city_norm         n
#>   <chr>        <chr>             <int>
#> 1 80111        GREENWOOD VILLAGE     7
#> 2 22306        <NA>                  1
#> 3 33408        JUNO BEACH            1
#> 4 80122        ENGELWOOD             1
```

## Export

``` r
proc_dir <- here("wy", "lobby", "data", "processed")
dir_create(proc_dir)
```

``` r
write_csv(
  x = wylr,
  path = glue("{proc_dir}/wy_lobby_reg.csv"),
  na = ""
)
```
