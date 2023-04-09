North Carolina Lobbyists
================
Yanqi Xu
2023-03-29 23:24:30

- <a href="#project" id="toc-project">Project</a>
- <a href="#objectives" id="toc-objectives">Objectives</a>
- <a href="#packages" id="toc-packages">Packages</a>
- <a href="#data" id="toc-data">Data</a>
- <a href="#import" id="toc-import">Import</a>
- <a href="#explore" id="toc-explore">Explore</a>
- <a href="#wrangle" id="toc-wrangle">Wrangle</a>
- <a href="#export" id="toc-export">Export</a>

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
pacman::p_load_current_gh("irworkshop/campfin")
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
#> [1] "/Users/yanqixu/code/accountability_datacleaning"
```

## Data

The data is obtained from the North Carolina Secretary of State’s office
[Lobbying Download
webpage](https://www.sosnc.gov/online_services/lobbying/download). From
there, we can download the database for all terms including resigned
lobbyists in a a rich text file. We’ll make a `httr::GET()` request on
the file to download and write the text file to disk.

It was downloaded on March 29, 2023. 

Accoding to the North Carolina Secretary of State’s office website, \>
Lobbying is the influencing or attempting to influence legislative or
executive branch action. Lobbyists, lobbyist principals, state and local
liaisons (those representing state and local governments), must register
annually to lobby certain elected and appointed governmental officials.
All must report quarterly and all of this information is accessible in
our Directory.

``` r
raw_dir <- here("state","nc", "lobby", "data", "raw")
dir_create(raw_dir)

lob_relative_url <- read_html("https://www.sosnc.gov/online_services/lobbying/lobbying_download_results") %>% html_nodes(xpath="//a[contains(text(),'Click Here To Download Text Only')]") %>% html_attr("href")

lob_url <- str_replace(lob_relative_url, "../../", "https://www.sosnc.gov/")

lob_file <- "nc_lob_master.txt"

lob_path <- str_c(raw_dir, lob_file, sep = "/")
if (!this_file_new(lob_path)) {
  GET(lob_url, write_disk(lob_path, overwrite = TRUE))
  #unzip(lob_path, exdir = raw_dir)
}
```

## Import

The rich text file doesn’t specify its delimiter, but we can determine
that the delimiter is tabs after a little bit of tinkering with
`read_lines()`.

First, we will use `readr::read_delim()` to read the data frame of
lobbyists. There will be some parsing errors resulting in the fact that
every line except for the headers ended with an extraneous `\t`, which
we can safely disregard.

``` r
nc_lob <- read_delim(dir_ls(raw_dir, regexp = "nc_lob_master.txt"),
    "\t", escape_double = FALSE, trim_ws = TRUE, col_types = cols(
      .default = col_character()
    )) %>% clean_names()
```

## Explore

    #> # A tibble: 6 × 23
    #>   term      lobby…¹ lobby…² lobby…³ lobby…⁴ lobby…⁵ lobby…⁶ lobby…⁷ lobby…⁸ lobby…⁹ lobby…˟ lobby…˟
    #>   <chr>     <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>  
    #> 1 1993-1994 J. All… <NA>    J.      Allen   Adams   <NA>    Parker… P.O. B… <NA>    Raleigh NC     
    #> 2 1993-1994 J. All… <NA>    J.      Allen   Adams   <NA>    Parker… P.O. B… <NA>    Raleigh NC     
    #> 3 1993-1994 J. All… <NA>    J.      Allen   Adams   <NA>    Parker… P.O. B… <NA>    Raleigh NC     
    #> 4 1993-1994 J. All… <NA>    J.      Allen   Adams   <NA>    Parker… P.O. B… <NA>    Raleigh NC     
    #> 5 1993-1994 J. All… <NA>    J.      Allen   Adams   <NA>    Parker… P.O. B… <NA>    Raleigh NC     
    #> 6 1993-1994 J. All… <NA>    J.      Allen   Adams   <NA>    Parker… P.O. B… <NA>    Raleigh NC     
    #> # … with 11 more variables: lobby_zip <chr>, lobby_phone <chr>, principal <chr>,
    #> #   prin_officer <chr>, prin_title <chr>, prin_address1 <chr>, prin_address2 <chr>,
    #> #   prin_city <chr>, prin_state <chr>, prin_zip <chr>, prin_phone <chr>, and abbreviated variable
    #> #   names ¹​lobby_name, ²​lobby_prefix, ³​lobby_first, ⁴​lobby_mid, ⁵​lobby_last, ⁶​lobby_suffix,
    #> #   ⁷​lobby_firm, ⁸​lobby_address1, ⁹​lobby_address2, ˟​lobby_city, ˟​lobby_state
    #> # A tibble: 6 × 23
    #>   term  lobby_name  lobby…¹ lobby…² lobby…³ lobby…⁴ lobby…⁵ lobby…⁶ lobby…⁷ lobby…⁸ lobby…⁹ lobby…˟
    #>   <chr> <chr>       <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>  
    #> 1 2023  Richard A.… <NA>    Richard A.      Zechini <NA>    Willia… 421 Fa… <NA>    Raleigh NC     
    #> 2 2023  Richard A.… <NA>    Richard A.      Zechini <NA>    Willia… 421 Fa… <NA>    Raleigh NC     
    #> 3 2023  Fred  Zeyt… <NA>    Fred    <NA>    Zeytoo… <NA>    <NA>    C/O Po… <NA>    Sausal… CA     
    #> 4 2023  Mark  Zimm… <NA>    Mark    <NA>    Zimmer… <NA>    North … 309 N … <NA>    Raleigh NC     
    #> 5 2023  Lauren  Zi… <NA>    Lauren  <NA>    Zingra… <NA>    <NA>    412 Mo… <NA>    Raleigh NC     
    #> 6 2023  Ana  Zivan… <NA>    Ana     <NA>    Zivano… <NA>    North … 3609 H… <NA>    Newport NC     
    #> # … with 11 more variables: lobby_zip <chr>, lobby_phone <chr>, principal <chr>,
    #> #   prin_officer <chr>, prin_title <chr>, prin_address1 <chr>, prin_address2 <chr>,
    #> #   prin_city <chr>, prin_state <chr>, prin_zip <chr>, prin_phone <chr>, and abbreviated variable
    #> #   names ¹​lobby_prefix, ²​lobby_first, ³​lobby_mid, ⁴​lobby_last, ⁵​lobby_suffix, ⁶​lobby_firm,
    #> #   ⁷​lobby_address1, ⁸​lobby_address2, ⁹​lobby_city, ˟​lobby_state
    #> Rows: 44,009
    #> Columns: 23
    #> $ term           <chr> "1993-1994", "1993-1994", "1993-1994", "1993-1994", "1993-1994", "1993-199…
    #> $ lobby_name     <chr> "J. Allen Adams", "J. Allen Adams", "J. Allen Adams", "J. Allen Adams", "J…
    #> $ lobby_prefix   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
    #> $ lobby_first    <chr> "J.", "J.", "J.", "J.", "J.", "J.", "J.", "J.", "J.", "J.", "J.", "J.", "J…
    #> $ lobby_mid      <chr> "Allen", "Allen", "Allen", "Allen", "Allen", "Allen", "Allen", "Allen", "A…
    #> $ lobby_last     <chr> "Adams", "Adams", "Adams", "Adams", "Adams", "Adams", "Adams", "Adams", "A…
    #> $ lobby_suffix   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
    #> $ lobby_firm     <chr> "Parker, Poe, Adams & Bernstein", "Parker, Poe, Adams & Bernstein", "Parke…
    #> $ lobby_address1 <chr> "P.O. Box 389", "P.O. Box 389", "P.O. Box 389", "P.O. Box 389", "P.O. Box …
    #> $ lobby_address2 <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
    #> $ lobby_city     <chr> "Raleigh", "Raleigh", "Raleigh", "Raleigh", "Raleigh", "Raleigh", "Raleigh…
    #> $ lobby_state    <chr> "NC", "NC", "NC", "NC", "NC", "NC", "NC", "NC", "NC", "NC", "NC", "NC", "N…
    #> $ lobby_zip      <chr> "27602-0389", "27602-0389", "27602-0389", "27602-0389", "27602-0389", "276…
    #> $ lobby_phone    <chr> "(919) 828-0564", "(919) 828-0564", "(919) 828-0564", "(919) 828-0564", "(…
    #> $ principal      <chr> "NC Council of Community MH/DD/SA Programs", "National Institute of Statis…
    #> $ prin_officer   <chr> "Schanzenbach, Janet", "Sacks, Jerome", "Welch, Glenda", "Goodson, Sharon …
    #> $ prin_title     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
    #> $ prin_address1  <chr> "505 Oberlin Road, Ste 100", "PO Box 14162", "1200 Arlington St.", "4428 L…
    #> $ prin_address2  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "Ste. 1000", NA, NA, N…
    #> $ prin_city      <chr> "Raleigh", "RTP", "Greensboro", "Raleigh", "Research Triangle Park", "Rale…
    #> $ prin_state     <chr> "NC", "NC", "NC", "NC", "NC", "NC", "RI", "OH", "NC", "NC", "NC", "NC", "N…
    #> $ prin_zip       <chr> "27605", "27709-4162", "27406-2499", "27616", "27709-0152", "27612", "0290…
    #> $ prin_phone     <chr> "(919) 327-1500", "(919) 541-6255", "(336) 378-7750", "(919) 790-5757", "(…

#### Duplicates

As you’d expect, some columns are more distinct than others. In our
original lobbyist and organization tables, the respect `*_id` variables
are 100% distinct, but lobbyists are repeated for every client
organization in our joined data frame.

``` r
nc_lob <- flag_dupes(nc_lob, dplyr::everything())
```

#### Missing

3 lobbyists are missing names, 37 and 34 we flag these instances with
`campfin::flag_na()`

``` r
col_stats(nc_lob, count_na)
#> # A tibble: 24 × 4
#>    col            class     n         p
#>    <chr>          <chr> <int>     <dbl>
#>  1 term           <chr>     0 0        
#>  2 lobby_name     <chr>     3 0.0000682
#>  3 lobby_prefix   <chr> 42831 0.973    
#>  4 lobby_first    <chr>     3 0.0000682
#>  5 lobby_mid      <chr> 14357 0.326    
#>  6 lobby_last     <chr>     3 0.0000682
#>  7 lobby_suffix   <chr> 39385 0.895    
#>  8 lobby_firm     <chr>  7414 0.168    
#>  9 lobby_address1 <chr>     0 0        
#> 10 lobby_address2 <chr> 42097 0.957    
#> 11 lobby_city     <chr>    37 0.000841 
#> 12 lobby_state    <chr>    37 0.000841 
#> 13 lobby_zip      <chr>    37 0.000841 
#> 14 lobby_phone    <chr>    58 0.00132  
#> 15 principal      <chr>     0 0        
#> 16 prin_officer   <chr>    51 0.00116  
#> 17 prin_title     <chr> 44009 1        
#> 18 prin_address1  <chr>     7 0.000159 
#> 19 prin_address2  <chr> 42255 0.960    
#> 20 prin_city      <chr>    34 0.000773 
#> 21 prin_state     <chr>    40 0.000909 
#> 22 prin_zip       <chr>    54 0.00123  
#> 23 prin_phone     <chr>  2438 0.0554   
#> 24 dupe_flag      <lgl>     0 0
nc_lob <- nc_lob %>% flag_na(lobby_name, lobby_city, prin_city)
```

## Wrangle

To improve the consistency and search ability of our accountability
database, we will perform some simple and **confident** manipulations to
the original data and create new, normalized variables.

### Phone

We can use `campfin::normal_phone()` to convert the numeric phone
numbers into an unambiguous character format. This prevents the column
from being read as a numeric variable.

``` r
nc_lob <- mutate_at(
  .tbl  = nc_lob,
  .vars = vars(ends_with("phone")),
  .funs = list(norm = normal_phone)
)
```

    #> # A tibble: 11,757 × 4
    #>    lobby_phone    prin_phone          lobby_phone_norm prin_phone_norm    
    #>    <chr>          <chr>               <chr>            <chr>              
    #>  1 (919) 787-8880 (608) 630-4686      (919) 787-8880   (608) 630-4686     
    #>  2 (910) 323-0415 (336) 770-2000      (910) 323-0415   (336) 770-2000     
    #>  3 (919) 836-4008 (919) 828-4199      (919) 836-4008   (919) 828-4199     
    #>  4 (919) 783-2847 (212) 255-0200      (919) 783-2847   (212) 255-0200     
    #>  5 (919) 452-6086 (919) 774-4511      (919) 452-6086   (919) 774-4511     
    #>  6 (919) 836-4015 (984) 480-3199 x101 (919) 836-4015   (984) 480-3199 x101
    #>  7 (919) 899-3045 (919) 478-4661      (919) 899-3045   (919) 478-4661     
    #>  8 (919) 653-7803 (252) 436-2040      (919) 653-7803   (252) 436-2040     
    #>  9 <NA>           (972) 764-9319      <NA>             (972) 764-9319     
    #> 10 (212) 455-6393 (202) 496-5652      (212) 455-6393   (202) 496-5652     
    #> # … with 11,747 more rows

### Address

To normalize the street addresses, we will first `tidyr::unite()` each
address column into a single column and then pass that string to
`campfin::normal_address()`.

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
      abbs = usps_street,
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
      abbs = usps_street,
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
#> # A tibble: 1 × 0
```

### ZIP

Our database uses 5-digit ZIP codes, so we can pass the original postal
code variables to `campfin::normal_zip()` to trim the strings and try
and repair and broken formats.

``` r
nc_lob <- mutate_at(
  .tbl  = nc_lob,
  .vars = vars(ends_with("zip")),
  .funs = list(norm = normal_zip),
  na_rep = TRUE
)
```

    #> # A tibble: 3,706 × 4
    #>    lobby_zip  prin_zip   lobby_zip_norm prin_zip_norm
    #>    <chr>      <chr>      <chr>          <chr>        
    #>  1 27602      27511-6372 27602          27511        
    #>  2 27608      27301-9752 27608          27301        
    #>  3 27601-1891 20171      27601          20171        
    #>  4 27601-2998 21202      27601          21202        
    #>  5 23452      27709-2195 23452          27709        
    #>  6 27608      28445-6985 27608          28445        
    #>  7 27602-2611 30339      27602          30339        
    #>  8 28806-4550 27406      28806          27406        
    #>  9 27611-7404 27605-0918 27611          27605        
    #> 10 27602      27102-3199 27602          27102        
    #> # … with 3,696 more rows

This makes out new ZIP variables very clean.

    #> # A tibble: 4 × 6
    #>   stage                 prop_in n_distinct  prop_na n_out n_diff
    #>   <chr>                   <dbl>      <dbl>    <dbl> <dbl>  <dbl>
    #> 1 nc_lob$lobby_zip        0.834       1080 0.000841  7310    422
    #> 2 nc_lob$lobby_zip_norm   0.998        728 0.00102     68     12
    #> 3 nc_lob$prin_zip         0.750       2116 0.00123  11009    770
    #> 4 nc_lob$prin_zip_norm    0.997       1559 0.00177    119     25

### State

This database contains a mix of full state names and 2-letter
abbreviations; we can pass these variables to `campfin::normal_state()`
to try and convert them all the abbreviations. After normalization, we
can see all lobbyist states are valid with some principal states with
invalid values. We will manually correct them and substitute with `NA`.

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
#> [1] 0.9986809

nc_lob <- nc_lob %>% 
  mutate_at(
    .vars = vars(ends_with("state_norm")),
    .funs = na_if, "XX" 
  ) %>% 
  mutate(prin_state_norm = prin_state_norm %>% na_if("XX") %>% str_replace("LO", "LA"))
```

    #> # A tibble: 304 × 4
    #>    lobby_state prin_state lobby_state_norm prin_state_norm
    #>    <chr>       <chr>      <chr>            <chr>          
    #>  1 VA          MO         VA               MO             
    #>  2 NC          IL         NC               IL             
    #>  3 LA          CA         LA               CA             
    #>  4 FL          RI         FL               RI             
    #>  5 NC          NM         NC               NM             
    #>  6 MA          NC         MA               NC             
    #>  7 MO          LA         MO               LA             
    #>  8 NY          IL         NY               IL             
    #>  9 NC          ON         NC               ON             
    #> 10 NC          MA         NC               MA             
    #> # … with 294 more rows

    #> # A tibble: 4 × 6
    #>   stage                   prop_in n_distinct  prop_na n_out n_diff
    #>   <chr>                     <dbl>      <dbl>    <dbl> <dbl>  <dbl>
    #> 1 nc_lob$lobby_state        1.00          43 0.000841     8      4
    #> 2 nc_lob$lobby_state_norm   1             40 0.000841     0      1
    #> 3 nc_lob$prin_state         0.998         57 0.000909    78     11
    #> 4 nc_lob$prin_state_norm    1.00          50 0.00195     10      4

### City

#### Normalize

The city values are typically the hardest to normalize due to the
variety of valid formats. Again, the `campfin::normal_city()` function
reduces inconsistencies and removes invalid values.

``` r
nc_lob <- mutate_at(
  .tbl  = nc_lob,
  .vars = vars(ends_with("city")),
  .funs = list(norm = normal_city),
  abbs = usps_city,
  states = usps_state,
  na = invalid_city,
  na_rep = TRUE
)
```

#### Swap

Then, we can compare these normalized values to the *expected* values
for that record’s ZIP code. If the two values are similar, we can
confidently assume a typo was made and default to the expected value.

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
      #condition = !is.na(prin_match_dist) & prin_match_abb | prin_match_dist == 1,
      condition = prin_match_abb | prin_match_dist == 1 & !is.na(prin_match_dist),
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

Our relatively few city values were already very clean, but this process
was able to make some quick and easy improvements.

    #> # A tibble: 5 × 6
    #>   stage                           prop_in n_distinct  prop_na n_out n_diff
    #>   <chr>                             <dbl>      <dbl>    <dbl> <dbl>  <dbl>
    #> 1 str_to_upper(nc_lob$lobby_city)   0.991        417 0.000841   388     33
    #> 2 nc_lob$lobby_city_norm            0.991        412 0.000841   374     26
    #> 3 str_to_upper(nc_lob$prin_city)    0.970        880 0.000773  1307     78
    #> 4 nc_lob$prin_city_norm             0.971        870 0.000795  1258     62
    #> 5 nc_lob$prin_city_swap             0.984        846 0.000795   717     31

Now we can remove the normalized city column in favor of our improved
compared value.

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

    #> # A tibble: 6 × 6
    #>   prin_city_norm   prin_state_norm     n check_city_flag guess_city       guess_place     
    #>   <chr>            <chr>           <dbl> <lgl>           <chr>            <chr>           
    #> 1 ABBOTT PARK      IL                 43 TRUE            GREEN OAKS       ABBOTT PARK     
    #> 2 BALD HEAD ISLAND NC                 34 TRUE            BALD HEAD ISLAND BALD HEAD ISLAND
    #> 3 BEECH MOUNTAIN   NC                  4 TRUE            BEECH MOUNTAIN   BEECH MOUNTAIN  
    #> 4 CASWELL BEACH    NC                  6 TRUE            CASWELL BEACH    CASWELL BEACH   
    #> 5 CREAM CITY       NJ                  2 FALSE           <NA>             NEW JERSEY      
    #> 6 FARMINGTON HILLS MI                  2 TRUE            FARMINGTON HILLS FARMINGTON HILLS

``` r
nc_check <- nc_check %>% 
  mutate(string_dist = stringdist(guess_place, prin_city_norm)) %>% 
  mutate(check_swap = if_else(condition = string_dist > 2,
                              true = prin_city_norm,
                              false = guess_place)) %>% 
  select(-string_dist)
```

If the string distances between `guess_place` and `prin_city_norm` is no
more than two characters, we can make a confident swap to use the
`guess_place` results in the new column named `check_swap`.

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
#> # A tibble: 3 × 6
#>   stage                   prop_in n_distinct  prop_na n_out n_diff
#>   <chr>                     <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 nc_lob$prin_city       0.000682        890 0.000773 43945    882
#> 2 nc_lob$prin_city_norm  0.997           846 0.000795   123     15
#> 3 nc_lob$prin_city_clean 0.998           844 0.000795    86     12
```

## Export

``` r
nc_lob <- nc_lob %>% 
  rename(prin_zip5 = prin_zip_norm,
         lobby_zip5 = lobby_zip_norm,
         lobby_state_clean = lobby_state_norm,
         prin_state_clean = prin_state_norm,
         lobby_city_clean = lobby_city_norm)
```

``` r
proc_dir <- here("state","nc", "lobby", "data", "processed")
dir_create(proc_dir)
```

``` r
write_csv(
  x = nc_lob %>% select(-prin_city_norm),
  path = glue("{proc_dir}/nc_lobby_reg_clean.csv"),
  na = ""
)
```
