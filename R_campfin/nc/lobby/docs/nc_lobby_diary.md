North Carolina Lobbyists
================
Yanqi Xu
2019-12-09 14:13:27

-   [Project](#project)
-   [Objectives](#objectives)
-   [Packages](#packages)
-   [Data](#data)
-   [Import](#import)
-   [Explore](#explore)
-   [Wrangle](#wrangle)
-   [Export](#export)

<!-- Place comments regarding knitting here -->
Project
-------

The Accountability Project is an effort to cut across data silos and give journalists, policy professionals, activists, and the public at large a simple way to search across huge volumes of public data about people and organizations.

Our goal is to standardizing public data on a few key fields by thinking of each dataset row as a transaction. For each transaction there should be (at least) 3 variables:

1.  All **parties** to a transaction
2.  The **date** of the transaction
3.  The **amount** of money involved

Objectives
----------

This document describes the process used to complete the following objectives:

1.  How many records are in the database?
2.  Check for duplicates
3.  Check ranges
4.  Is there anything blank or missing?
5.  Check for consistency issues
6.  Create a five-digit ZIP Code called `ZIP5`
7.  Create a `YEAR` field from the transaction date
8.  Make sure there is data on both parties to a transaction

Packages
--------

The following packages are needed to collect, manipulate, visualize, analyze, and communicate these results. The `pacman` package will facilitate their installation and attachment.

The IRW's `campfin` package will also have to be installed from GitHub. This package contains functions custom made to help facilitate the processing of campaign finance data.

``` r
if (!require("pacman")) install.packages("pacman")
pacman::p_load_gh("irworkshop/campfin")
pacman::p_load(
  rvest, # used to scrape website and get html elements
  tidyverse, # data manipulation
  stringdist, # calculate distances between strings
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

This document should be run as part of the `R_campfin` project, which lives as a sub-directory of the more general, language-agnostic [`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning "TAP repo") GitHub repository.

The `R_campfin` project uses the [RStudio projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects "Rproj") feature and should be run as such. The project also uses the dynamic `here::here()` tool for file paths relative to *your* machine.

``` r
# where does this document knit?
here::here()
#> [1] "/Users/soc/accountability/accountability_datacleaning/R_campfin"
```

Data
----

Data is obtained from the North Carolina Secretary of State's office \[Lobbying Download webpage\]\[03\]. From there, we can download the database for all terms including resigned lobbyists in a a rich text file. We'll make a `httr::GET()` request on the file to download write the text file to disk. \[03\]: <https://www.sosnc.gov/online_services/lobbying/download> Accoding to the North Carolina Secretary of State's office website, &gt; Lobbying is the influencing or attempting to influence legislative or executive branch action. Lobbyists, lobbyist principals, state and local liaisons (those representing state and local governments), must register annually to lobby certain elected and appointed governmental officials. All must report quarterly and all of this information is accessible in our Directory.

``` r
raw_dir <- here("nc", "lobby", "data", "raw")
dir_create(raw_dir)

lob_relative_url <- read_html("https://www.sosnc.gov/online_services/lobbying/lobbying_download_results") %>% html_nodes(xpath="//a[contains(text(),'Click Here To Download Text Only')]") %>% html_attr("href")

lob_url <- str_replace(lob_relative_url, "../../", "https://www.sosnc.gov/")

lob_file <- "nc_lob_master.txt"

lob_path <- str_c(raw_dir, lob_file, sep = "/")
if (!this_file_new(lob_path)) {
  GET(lob_url, write_disk(lob_path, overwrite = TRUE))
  unzip(lob_path, exdir = raw_dir)
}
```

Import
------

The rich text file doesn't specify its delimiter, but we can determine that the delimiter is tabs after a little bit of tinkering with `read_lines()`.

First, we will use `readr::read_delim()` to read the data frame of lobbyists. There will be some parsing errors resulting in the fact that every line except for the headers ended with an extraneous `\t`, which we can safely disregard.

``` r
nc_lob <- read_delim(dir_ls(raw_dir, glob = "*.txt"),
    "\t", escape_double = FALSE, trim_ws = TRUE, col_types = cols(
      .default = col_character()
    )) %>% clean_names()
```

Explore
-------

    #> # A tibble: 6 x 23
    #>   term  lobby_name lobby_prefix lobby_first lobby_mid lobby_last lobby_suffix lobby_firm
    #>   <chr> <chr>      <chr>        <chr>       <chr>     <chr>      <chr>        <chr>     
    #> 1 1993… J. Allen … <NA>         J.          Allen     Adams      <NA>         Parker, P…
    #> 2 1993… J. Allen … <NA>         J.          Allen     Adams      <NA>         Parker, P…
    #> 3 1993… J. Allen … <NA>         J.          Allen     Adams      <NA>         Parker, P…
    #> 4 1993… J. Allen … <NA>         J.          Allen     Adams      <NA>         Parker, P…
    #> 5 1993… J. Allen … <NA>         J.          Allen     Adams      <NA>         Parker, P…
    #> 6 1993… J. Allen … <NA>         J.          Allen     Adams      <NA>         Parker, P…
    #> # … with 15 more variables: lobby_address1 <chr>, lobby_address2 <chr>, lobby_city <chr>,
    #> #   lobby_state <chr>, lobby_zip <chr>, lobby_phone <chr>, principal <chr>, prin_officer <chr>,
    #> #   prin_title <chr>, prin_address1 <chr>, prin_address2 <chr>, prin_city <chr>, prin_state <chr>,
    #> #   prin_zip <chr>, prin_phone <chr>
    #> # A tibble: 6 x 23
    #>   term  lobby_name lobby_prefix lobby_first lobby_mid lobby_last lobby_suffix lobby_firm
    #>   <chr> <chr>      <chr>        <chr>       <chr>     <chr>      <chr>        <chr>     
    #> 1 2019  Richard A… <NA>         Richard     A.        Zechini    <NA>         Williams …
    #> 2 2019  Richard A… <NA>         Richard     A.        Zechini    <NA>         Williams …
    #> 3 2019  Fred  Zey… <NA>         Fred        <NA>      Zeytoonji… <NA>         <NA>      
    #> 4 2019  Emily  Zi… <NA>         Emily       <NA>      Ziegler    <NA>         <NA>      
    #> 5 2019  Mark  Zim… <NA>         Mark        <NA>      Zimmerman  <NA>         North Car…
    #> 6 2019  Ana  Ziva… <NA>         Ana         <NA>      Zivanovic… <NA>         NC Coasta…
    #> # … with 15 more variables: lobby_address1 <chr>, lobby_address2 <chr>, lobby_city <chr>,
    #> #   lobby_state <chr>, lobby_zip <chr>, lobby_phone <chr>, principal <chr>, prin_officer <chr>,
    #> #   prin_title <chr>, prin_address1 <chr>, prin_address2 <chr>, prin_city <chr>, prin_state <chr>,
    #> #   prin_zip <chr>, prin_phone <chr>
    #> Observations: 33,281
    #> Variables: 23
    #> $ term           <chr> "1993-1994", "1993-1994", "1993-1994", "1993-1994", "1993-1994", "1993-19…
    #> $ lobby_name     <chr> "J. Allen Adams", "J. Allen Adams", "J. Allen Adams", "J. Allen Adams", "…
    #> $ lobby_prefix   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
    #> $ lobby_first    <chr> "J.", "J.", "J.", "J.", "J.", "J.", "J.", "J.", "J.", "J.", "J.", "J.", "…
    #> $ lobby_mid      <chr> "Allen", "Allen", "Allen", "Allen", "Allen", "Allen", "Allen", "Allen", "…
    #> $ lobby_last     <chr> "Adams", "Adams", "Adams", "Adams", "Adams", "Adams", "Adams", "Adams", "…
    #> $ lobby_suffix   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
    #> $ lobby_firm     <chr> "Parker, Poe, Adams & Bernstein", "Parker, Poe, Adams & Bernstein", "Park…
    #> $ lobby_address1 <chr> "P.O. Box 389", "P.O. Box 389", "P.O. Box 389", "P.O. Box 389", "P.O. Box…
    #> $ lobby_address2 <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
    #> $ lobby_city     <chr> "Raleigh", "Raleigh", "Raleigh", "Raleigh", "Raleigh", "Raleigh", "Raleig…
    #> $ lobby_state    <chr> "NC", "NC", "NC", "NC", "NC", "NC", "NC", "NC", "NC", "NC", "NC", "NC", "…
    #> $ lobby_zip      <chr> "27602-0389", "27602-0389", "27602-0389", "27602-0389", "27602-0389", "27…
    #> $ lobby_phone    <chr> "(919) 828-0564", "(919) 828-0564", "(919) 828-0564", "(919) 828-0564", "…
    #> $ principal      <chr> "Substance Abuse Professional Certification Board, NC", "NC Council of Co…
    #> $ prin_officer   <chr> "Davis, Ann", "Schanzenbach, Janet", "Alexandre, Leslie", "Anderson, Ray"…
    #> $ prin_title     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
    #> $ prin_address1  <chr> "PO Box 1636", "505 Oberlin Road, Ste 100", "15 TW Alexander Drive", "555…
    #> $ prin_address2  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "Ste. 1000", NA, NA, NA, NA, NA, …
    #> $ prin_city      <chr> "New Bern", "Raleigh", "Research Triangle Park", "Dublin", "Durham", "Cha…
    #> $ prin_state     <chr> "NC", "NC", "NC", "OH", "NC", "NC", "NC", "NC", "RI", "NC", "KY", "NC", "…
    #> $ prin_zip       <chr> "28562", "27605", "27709-0152", "43017-3586", "27717-1565", "28217", "274…
    #> $ prin_phone     <chr> "(910) 636-1510", "(919) 327-1500", "(919) 549-8805", "(614) 793-2005", "…

#### Duplicates

As you'd expect, some columns are more distinct than others. In our original lobbyist and organization tables, the respect `*_id` variables are 100% distinct, but lobbyists are repeated for every client organization in our joined data frame.

``` r
nc_lob <- flag_dupes(nc_lob, dplyr::everything())
```

#### Missing

3 lobbyists are missing names, 37 and 24 we flag these instances with `campfin::flag_na()`

``` r
col_stats(nc_lob, count_na)
#> # A tibble: 24 x 4
#>    col            class     n         p
#>    <chr>          <chr> <int>     <dbl>
#>  1 term           <chr>     0 0        
#>  2 lobby_name     <chr>     3 0.0000901
#>  3 lobby_prefix   <chr> 32285 0.970    
#>  4 lobby_first    <chr>     3 0.0000901
#>  5 lobby_mid      <chr>  9912 0.298    
#>  6 lobby_last     <chr>     3 0.0000901
#>  7 lobby_suffix   <chr> 29801 0.895    
#>  8 lobby_firm     <chr>  5947 0.179    
#>  9 lobby_address1 <chr>     0 0        
#> 10 lobby_address2 <chr> 31538 0.948    
#> 11 lobby_city     <chr>    37 0.00111  
#> 12 lobby_state    <chr>    37 0.00111  
#> 13 lobby_zip      <chr>    37 0.00111  
#> 14 lobby_phone    <chr>    54 0.00162  
#> 15 principal      <chr>     0 0        
#> 16 prin_officer   <chr>    36 0.00108  
#> 17 prin_title     <chr> 33281 1        
#> 18 prin_address1  <chr>     0 0        
#> 19 prin_address2  <chr> 31750 0.954    
#> 20 prin_city      <chr>    24 0.000721 
#> 21 prin_state     <chr>    30 0.000901 
#> 22 prin_zip       <chr>    44 0.00132  
#> 23 prin_phone     <chr>  2566 0.0771   
#> 24 dupe_flag      <lgl>     0 0
nc_lob <- nc_lob %>% flag_na(lobby_name, lobby_city, prin_city)
```

Wrangle
-------

To improve the consistency and search ability of our accountability database, we will perform some simple and **confident** manipulations to the original data and create new, normalized variables.

### Phone

We can use `campfin::normal_phone()` to convert the numeric phone numbers into an unambiguous character format. This prevents the column from being read as a numeric variable.

``` r
nc_lob <- mutate_at(
  .tbl  = nc_lob,
  .vars = vars(ends_with("phone")),
  .funs = list(norm = normal_phone)
)
```

    #> # A tibble: 9,798 x 4
    #>    lobby_phone    prin_phone     lobby_phone_norm prin_phone_norm
    #>    <chr>          <chr>          <chr>            <chr>          
    #>  1 (972) 652-4525 (972) 652-4344 (972) 652-4525   (972) 652-4344 
    #>  2 (919) 981-4007 630-963-5547   (919) 981-4007   (630) 963-5547 
    #>  3 (919) 783-2847 (608) 255-0231 (919) 783-2847   (608) 255-0231 
    #>  4 (919) 747-9988 (800) 247-7791 (919) 747-9988   (800) 247-7791 
    #>  5 (704) 372-9000 (919) 246-3413 (704) 372-9000   (919) 246-3413 
    #>  6 (919) 934-0530 (919) 715-1276 (919) 934-0530   (919) 715-1276 
    #>  7 (919) 836-4005 (703) 288-8360 (919) 836-4005   (703) 288-8360 
    #>  8 (919) 828-0564 (704) 655-7294 (919) 828-0564   (704) 655-7294 
    #>  9 (919) 523-4085 (202) 682-8219 (919) 523-4085   (202) 682-8219 
    #> 10 (919) 836-4009 (919) 589-9843 (919) 836-4009   (919) 589-9843 
    #> # … with 9,788 more rows

### Address

To normalize the street addresses, we will first `tidyr::unite()` each address column into a single column and then pass that string to `campfin::normal_address()`.

``` r
nc_lob <- nc_lob %>% 
  unite(
    starts_with("lobby_address"),
    col = "lobby_address_full",
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    lobby_address_norm = normal_address(
      address = lobby_address_full,
      add_abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-ends_with("address_full"))
```

``` r
nc_lob <- nc_lob %>% 
  unite(
    starts_with("prin_addr"),
    col = "prin_address_full",
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    prin_addr_norm = normal_address(
      address = prin_address_full,
      add_abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-ends_with("address_full"))
```

``` r
nc_lob %>% 
  select(starts_with("lob_addr")) %>% 
  distinct() %>% 
  sample_frac()
#> # A tibble: 1 x 0
```

### ZIP

Our database uses 5-digit ZIP codes, so we can pass the original postal code variables to `campfin::normal_zip()` to trim the strings and try and repair and broken formats.

``` r
nc_lob <- mutate_at(
  .tbl  = nc_lob,
  .vars = vars(ends_with("zip")),
  .funs = list(norm = normal_zip),
  na_rep = TRUE
)
```

    #> # A tibble: 3,834 x 4
    #>    lobby_zip  prin_zip   lobby_zip_norm prin_zip_norm
    #>    <chr>      <chr>      <chr>          <chr>        
    #>  1 27605      H3C3G9     27605          00339        
    #>  2 30328      20001-6441 30328          20001        
    #>  3 27601      20004-2601 27601          20004        
    #>  4 28204      28217-1738 28204          28217        
    #>  5 27612      27612-4934 27612          27612        
    #>  6 27605-0463 27605-0463 27605          27605        
    #>  7 27605-2197 27609      27605          27609        
    #>  8 27602      27702-2291 27602          27702        
    #>  9 27606-3365 27603      27606          27603        
    #> 10 27612-2966 27709      27612          27709        
    #> # … with 3,824 more rows

This makes out new ZIP variables very clean.

    #> # A tibble: 4 x 6
    #>   stage          prop_in n_distinct prop_na n_out n_diff
    #>   <chr>            <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 lobby_zip        0.785       1028 0.00111  7161    442
    #> 2 lobby_zip_norm   0.998        660 0.00150    62      8
    #> 3 prin_zip         0.672       1963 0.00132 10897    830
    #> 4 prin_zip_norm    0.998       1365 0.00189    63     18

### State

This database contains a mix of full state names and 2-letter abbreviations; we can pass these variables to `campfin::normal_state()` to try and convert them all the abbreviations. After normalization, we can see all lobbyist states are valid with some principal states with invalid values. We will manually correct them and substitute with `NA`.

``` r
nc_lob <- mutate_at(
  .tbl  = nc_lob,
  .vars = vars(ends_with("state")),
  .funs = list(norm = normal_state),
  abbreviate = TRUE
)

prop_in(nc_lob$lobby_state_norm, valid_state, na.rm = T)
#> [1] 1
prop_in(nc_lob$prin_state_norm, valid_state, na.rm = T)
#> [1] 0.9987369

nc_lob <- nc_lob %>% 
  mutate_at(
    .vars = vars(ends_with("state_norm")),
    .funs = na_if, "XX" 
  ) %>% 
  mutate(prin_state_norm = prin_state_norm %>% na_if("XX") %>% str_replace("LO", "LA"))
```

    #> # A tibble: 308 x 4
    #>    lobby_state prin_state lobby_state_norm prin_state_norm
    #>    <chr>       <chr>      <chr>            <chr>          
    #>  1 CA          CA         CA               CA             
    #>  2 CT          CT         CT               CT             
    #>  3 DC          TX         DC               TX             
    #>  4 GA          OH         GA               OH             
    #>  5 GA          DC         GA               DC             
    #>  6 LA          WA         LA               WA             
    #>  7 MD          WA         MD               WA             
    #>  8 DC          TN         DC               TN             
    #>  9 NY          GA         NY               GA             
    #> 10 <NA>        TX         <NA>             TX             
    #> # … with 298 more rows

    #> # A tibble: 4 x 6
    #>   stage            prop_in n_distinct  prop_na n_out n_diff
    #>   <chr>              <dbl>      <dbl>    <dbl> <dbl>  <dbl>
    #> 1 lobby_state        1.000         42 0.00111      8      4
    #> 2 lobby_state_norm   1             39 0.00111      0      1
    #> 3 prin_state         0.998         57 0.000901    60     11
    #> 4 prin_state_norm    0.999         50 0.00138     24      4

### City

#### Normalize

The city values are typically the hardest to normalize due to the variety of valid formats. Again, the `campfin::normal_city()` function reduces inconsistencies and removes invalid values.

``` r
nc_lob <- mutate_at(
  .tbl  = nc_lob,
  .vars = vars(ends_with("city")),
  .funs = list(norm = normal_city),
  geo_abbs = usps_city,
  st_abbs = usps_state,
  na = invalid_city,
  na_rep = TRUE
)
```

#### Swap

Then, we can compare these normalized values to the *expected* values for that record's ZIP code. If the two values are similar, we can confidently assume a typo was made and default to the expected value.

``` r
nc_lob <- nc_lob %>% 
  left_join(
    y = zipcodes,
    by = c(
      "prin_state_norm" = "state",
      "prin_zip_norm" = "zip"
    )
  ) %>% 
  rename(prin_city_match = city) %>% 
  mutate(
    prin_match_abb = is_abbrev(prin_city_norm, prin_city_match),
    prin_match_dist = str_dist(prin_city_norm, prin_city_match),
    prin_city_swap = if_else(
      condition = prin_match_abb | prin_match_dist == 1,
      true = prin_city_match,
      false = prin_city_norm
    )
  ) %>% 
  select(
    -prin_city_match,
    -prin_match_abb,
    -prin_match_dist
  )
```

Our relatively few city values were already very clean, but this process was able to make some quick and easy improvements.

    #> # A tibble: 5 x 6
    #>   stage           prop_in n_distinct  prop_na n_out n_diff
    #>   <chr>             <dbl>      <dbl>    <dbl> <dbl>  <dbl>
    #> 1 lobby_city)       0.987        370 0.00111    432     36
    #> 2 lobby_city_norm   0.991        362 0.00111    303     24
    #> 3 prin_city)        0.967        778 0.000721  1098     90
    #> 4 prin_city_norm    0.978        764 0.000721   747     68
    #> 5 prin_city_swap    0.981        722 0.0140     609     37

Now we can remove the normalized city column in favor of our improved compared value.

``` r
nc_lob <- nc_lob %>% 
  select(-prin_city_norm) %>% 
  rename(prin_city_norm = prin_city_swap)
```

#### Check

``` r
api_key <- Sys.getenv("GEOCODING_API")

valid_place <-  c(valid_city, extra_city) %>% unique()

nc_check <- nc_lob %>% 
  filter(prin_city_norm %out% valid_place) %>% 
  drop_na(prin_city_norm, prin_state_norm) %>% 
  count(prin_city_norm, prin_state_norm)

nc_check_result <- 
  pmap_dfr(.l = list(city = nc_check$prin_city_norm, state = nc_check$prin_state_norm), 
           .f = check_city, 
           key = api_key, 
           guess = T)

nc_check <- nc_check %>% 
  left_join(nc_check_result %>% 
              select(-original_zip), 
            by = c("prin_city_norm" = "original_city", 
                   "prin_state_norm" = "original_state"))
```

    #> # A tibble: 6 x 6
    #>   prin_city_norm   prin_state_norm     n check_city_flag guess_city       guess_place     
    #>   <chr>            <chr>           <dbl> <lgl>           <chr>            <chr>           
    #> 1 ARCHDALE         NC                  1 TRUE            ARCHDALE         ARCHDALE        
    #> 2 AVENTURA         FL                  2 TRUE            AVENTURA         AVENTURA        
    #> 3 BALD HEAD ISLAND NC                 28 TRUE            BALD HEAD ISLAND BALD HEAD ISLAND
    #> 4 BANNOCKBURN      IL                  8 TRUE            BANNOCKBURN      BANNOCKBURN     
    #> 5 BEECH MOUNTAIN   NC                  4 TRUE            BEECH MOUNTAIN   BEECH MOUNTAIN  
    #> 6 CASWELL BEACH    NC                  6 TRUE            CASWELL BEACH    CASWELL BEACH

``` r
nc_check <- nc_check %>% 
  mutate(string_dist = stringdist(guess_place, prin_city_norm)) %>% 
  mutate(check_swap = if_else(condition = string_dist > 2,
                              true = prin_city_norm,
                              false = guess_place)) %>% 
  select(-string_dist)
```

If the string distances between `guess_place` and `prin_city_norm` is no more than two characters, we can make a confident swap to use the `guess_place` results in the new column named `check_swap`.

``` r
nc_lob <- nc_check %>% select(prin_city_norm, prin_state_norm, check_swap) %>% 
  right_join(nc_lob, by = c("prin_city_norm", "prin_state_norm")) %>% 
  mutate(prin_city_clean = coalesce(check_swap, prin_city_norm)) %>% 
  select(-check_swap)

nc_lob <- nc_lob %>% 
  mutate(prin_city_clean = prin_city_clean %>% str_replace("RTP", "RESEARCH TRIANGLE PARK"))
```

``` r
extra_city_df <- gs_title("extra_city")

extra_city_df <- extra_city_df %>% 
  gs_add_row(ws = 1, input = nc_check %>% filter(check_city_flag) %>% select(guess_place))
```

``` r
valid_place <- c(valid_city, extra_city) %>% unique()

valid_place <-  c(valid_place,"RESEARCH TRIANGLE PARK",
                  nc_check$prin_city_norm[nc_check$check_city_flag]) %>% unique() 

progress_table(
  nc_lob$prin_city,
  nc_lob$prin_city_norm,
  nc_lob$prin_city_clean,
  compare = valid_place
)
#> # A tibble: 3 x 6
#>   stage           prop_in n_distinct  prop_na n_out n_diff
#>   <chr>             <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 prin_city       0.00159        785 0.000721 33204    779
#> 2 prin_city_norm  0.998          722 0.0140      82     10
#> 3 prin_city_clean 0.999          720 0.0140      36      7
```

Export
------

``` r
nc_lob <- nc_lob %>% 
  rename(prin_zip5 = prin_zip_norm,
         lobby_zip5 = lobby_zip_norm,
         lobby_state_clean = lobby_state_norm,
         prin_state_clean = prin_state_norm)
```

``` r
proc_dir <- here("nc", "lobby", "data", "processed")
dir_create(proc_dir)
```

``` r
write_csv(
  x = nc_lob,
  path = glue("{proc_dir}/nc_lobby_reg_clean.csv"),
  na = ""
)
```
