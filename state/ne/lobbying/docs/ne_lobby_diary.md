Nebraska Lobbyists
================
Kiernan Nicholls & Yanqi Xu
2023-08-04 22:27:50

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
  pdftools, # read pdf file text
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

The data is obtained via a public records request fulfilled on July 27,
2023. A zip archive was provided by the legislative clerk’s office. The
data includes records from 2000 to July 21, 2023.

> The following reports identify lobbyists registered in Nebraska with
> the Office of the Clerk of the Legislature.
>
> ##### Lists of Registered Lobbyists
>
> - [Lobby Registration Report by
>   Principal](https://nebraskalegislature.gov/FloorDocs/Current/PDF/Lobby/principallist.pdf)
> - [Lobby Registration Report by
>   Lobbyist](https://nebraskalegislature.gov/FloorDocs/Current/PDF/Lobby/lobbyistlist.pdf)
> - [Lobbyist/Principal Expenditures
>   Report](https://nebraskalegislature.gov/FloorDocs/Current/PDF/Lobby/expense.pdf)
> - [Lobbyist/Principal Statement of
>   Activity](https://nebraskalegislature.gov/FloorDocs/Current/PDF/Lobby/activity_final_by_bill.pdf)
> - [Counts of
>   Lobbyists/Principals](https://nebraskalegislature.gov/FloorDocs/Current/PDF/Lobby/counts.pdf)

## Import

``` r
raw_dir <- dir_create(here::here("state","ne", "lobbying", "data","raw"))

nelr <- read_csv(dir_ls(raw_dir, glob = "*.csv"))

nelr <- nelr %>% clean_names()
```

``` r
nelr <- nelr %>% mutate(across(.cols = ends_with("_date"), mdy))
```

## Explore

``` r
glimpse(nelr)
#> Rows: 18,586
#> Columns: 14
#> $ lobbyist_name     <chr> "Abboud, Chris - Public Affairs Group", "Abboud, Chris - Public Affairs…
#> $ lobbyist_address  <chr> "8700 Executive Woods Dr", "8700 Executive Woods Dr", "8700 Executive W…
#> $ lobbyist_city     <chr> "Lincoln", "Lincoln", "Lincoln", "Lincoln", "Lincoln", "Lincoln", "Linc…
#> $ lobbyist_state    <chr> "NE", "NE", "NE", "NE", "NE", "NE", "NE", "NE", "NE", "NE", "NE", "NE",…
#> $ lobbyist_zip      <chr> "68512", "68512", "68512", "68512", "68512", "68512", "68512", "68512",…
#> $ lobbyist_phone    <chr> "(402)968-4798", "(402)968-4798", "(402)968-4798", "(402)968-4798", "(4…
#> $ principal_name    <chr> "Bayer U.S. LLC", "City of Omaha Mayor's Office", "Kelley Plucker, LLC"…
#> $ principal_address <chr> "700 Chesterfield Parkway West, Building FF4339A", "1819 Farnam Street,…
#> $ principal_city    <chr> "Chesterfield", "Omaha", "Omaha", "Omaha", "Lincoln", "Omaha", "Omaha",…
#> $ principal_state   <chr> "MO", "NE", "NE", "NE", "NE", "NE", "NE", "NE", "TX", "NE", "NE", "NE",…
#> $ principal_zip     <chr> "63017", "68183", "68124", "68102", "68512", "68105", "68144", "68760",…
#> $ principal_phone   <chr> "(636)737-9522", "(402)444-3518", "(402)397-1898", "(402)341-7560", "(4…
#> $ registration_date <date> 2000-01-20, 2000-12-20, 2000-02-09, 2000-12-20, 2000-01-10, 2000-01-10…
#> $ termination_date  <date> NA, NA, NA, NA, NA, 2000-10-13, NA, NA, NA, NA, NA, NA, 2000-07-07, NA…
tail(nelr)
#> # A tibble: 6 × 14
#>   lobbyis…¹ lobby…² lobby…³ lobby…⁴ lobby…⁵ lobby…⁶ princ…⁷ princ…⁸ princ…⁹ princ…˟ princ…˟ princ…˟
#>   <chr>     <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>  
#> 1 Zulkoski… 725 S … Lincoln NE      68508   (402)9… Nebras… PO Box… Lyndon  KS      66541   (402)4…
#> 2 Zulkoski… 725 S … Lincoln NE      68508   (402)9… NetCho… 1401 K… Washin… DC      20005   (202)4…
#> 3 Zulkoski… 725 S … Lincoln NE      68508   (402)9… Novo N… 800 Sc… Plains… NJ      08536   (609)9…
#> 4 Zulkoski… 725 S … Lincoln NE      68508   (402)9… Viaero… 1224 W… Fort M… CO      80701   (970)4…
#> 5 Zulkoski… 725 S … Lincoln NE      68508   (402)9… Women'… 1111 N… Omaha   NE      68102   (402)8…
#> 6 Zulkoski… 725 S … Lincoln NE      68508   (402)9… Zulkos… 725 S … Lincoln NE      68508   (402)9…
#> # … with 2 more variables: registration_date <date>, termination_date <date>, and abbreviated
#> #   variable names ¹​lobbyist_name, ²​lobbyist_address, ³​lobbyist_city, ⁴​lobbyist_state,
#> #   ⁵​lobbyist_zip, ⁶​lobbyist_phone, ⁷​principal_name, ⁸​principal_address, ⁹​principal_city,
#> #   ˟​principal_state, ˟​principal_zip, ˟​principal_phone
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(nelr, count_na)
#> # A tibble: 14 × 4
#>    col               class      n         p
#>    <chr>             <chr>  <int>     <dbl>
#>  1 lobbyist_name     <chr>      1 0.0000538
#>  2 lobbyist_address  <chr>      0 0        
#>  3 lobbyist_city     <chr>      0 0        
#>  4 lobbyist_state    <chr>      0 0        
#>  5 lobbyist_zip      <chr>      0 0        
#>  6 lobbyist_phone    <chr>      6 0.000323 
#>  7 principal_name    <chr>      0 0        
#>  8 principal_address <chr>      5 0.000269 
#>  9 principal_city    <chr>      5 0.000269 
#> 10 principal_state   <chr>      5 0.000269 
#> 11 principal_zip     <chr>      5 0.000269 
#> 12 principal_phone   <chr>     84 0.00452  
#> 13 registration_date <date>     0 0        
#> 14 termination_date  <date> 17382 0.935
```

### Duplicates

We can also flag any record completely duplicated across every column.

``` r
nelr <- flag_dupes(nelr, everything())
sum(nelr$dupe_flag)
#> [1] 32
mean(nelr$dupe_flag)
#> [1] 0.001721726
```

## Wrangle

First, we will rename some columns.

``` r
nelr <- nelr %>% rename_with(~str_replace(., "principal_", "pri_")) %>% 
  rename_with(~str_replace(., "lobbyist_", "lob_"))
```

### Phone

``` r
nelr <- nelr %>% 
  mutate_at(
    .vars = vars(ends_with("phone")),
    .fun = list(norm = normal_phone)
  )
```

### Address

``` r
nelr <- nelr %>% 
  mutate_at(
    .vars = vars(ends_with("address")),
    .fun = list(norm = normal_address),
    abbs = usps_street,
    na_rep = TRUE
  )
```

    #> # A tibble: 3,467 × 4
    #>    pri_address                              pri_address_norm                        lob_a…¹ lob_a…²
    #>    <chr>                                    <chr>                                   <chr>   <chr>  
    #>  1 660 W Germantown Pike                    660 W GERMANTOWN PIKE                   625 S.… 625 S …
    #>  2 401 N. Main St.                          401 N MAIN ST                           2744 S… 2744 S…
    #>  3 6688 North Central Expressway, Suite 500 6688 NORTH CENTRAL EXPRESSWAY SUITE 500 1700 F… 1700 F…
    #>  4 4361 Lafayette Avenue, PO Box 31031      4361 LAFAYETTE AVENUE PO BOX 31031      1125 Q… 1125 Q…
    #>  5 One Takeda Parkway                       ONE TAKEDA PKWY                         1030 N… 1030 N…
    #>  6 5201 Interchange Way                     5201 INTERCHANGE WAY                    635 S … 635 S …
    #>  7 2200 Dodge Stree                         2200 DODGE STREE                        6035 B… 6035 B…
    #>  8 1327 H Street, Suite 303                 1327 H STREET SUITE 303                 5400 S… 5400 S…
    #>  9 850 Lincoln Ctr Dr                       850 LINCOLN CTR DR                      1201 P… 1201 P…
    #> 10 1620 Dodge Street, Mail Stop 3395        1620 DODGE STREET MAIL STOP 3395        1220 L… 1220 L…
    #> # … with 3,457 more rows, and abbreviated variable names ¹​lob_address, ²​lob_address_norm

### ZIP

``` r
nelr <- nelr %>% 
  mutate_at(
    .vars = vars(ends_with("zip")),
    .fun = list(norm = normal_zip),
    na_rep = TRUE
  )
```

    #> # A tibble: 4 × 6
    #>   stage             prop_in n_distinct  prop_na n_out n_diff
    #>   <chr>               <dbl>      <dbl>    <dbl> <dbl>  <dbl>
    #> 1 nelr$lob_zip        0.958        470 0          779     76
    #> 2 nelr$lob_zip_norm   1.00         410 0            2      2
    #> 3 nelr$pri_zip        0.915        717 0.000269  1574    118
    #> 4 nelr$pri_zip_norm   0.997        637 0.000269    49      7

### State

The `*_state` components do not need to be wrangled.

``` r
prop_in(nelr$lob_state, valid_state)
#> [1] 0.9986011
prop_in(nelr$pri_state, valid_state)
#> [1] 0.9983854
```

### City

``` r
nelr <- nelr %>% 
  mutate_at(
    .vars = vars(ends_with("city")),
    .fun = list(norm = normal_city),
    na_rep = TRUE
  )
```

``` r
nelr <- nelr %>% 
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
      condition = !is.na(match_dist) & (match_abb | match_dist == 1),
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
nelr <- nelr %>% 
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
      condition = !is.na(match_dist) & (match_abb | match_dist == 1),
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

    #> # A tibble: 3 × 6
    #>   stage               prop_in n_distinct prop_na n_out n_diff
    #>   <chr>                 <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 nelr$lob_city      0.000108        249       0 18584    247
    #> 2 nelr$lob_city_norm 0.995           246       0    94     10
    #> 3 nelr$lob_city_swap 0.999           246       0    25      5

    #> # A tibble: 3 × 6
    #>   stage              prop_in n_distinct  prop_na n_out n_diff
    #>   <chr>                <dbl>      <dbl>    <dbl> <dbl>  <dbl>
    #> 1 nelr$pri_city      0.00393        394 0.000269 18508    389
    #> 2 nelr$pri_city_norm 0.981          382 0.000269   351     19
    #> 3 nelr$pri_city_swap 0.999          380 0.000269    25      9

## Export

``` r
nelr <- nelr %>% 
  select(-c(
    lob_city_clean = lob_city_swap,
    pri_city_clean = pri_city_swap
  )) %>% 
  mutate(
    year = year(registration_date),
    .before = lob_name
  ) %>% 
  rename_with(~str_replace(., "_norm", "_clean"))
```

``` r
clean_dir <- dir_create(here("state","ne", "lobbying", "data", "clean"))
clean_path <- path(clean_dir, "ne_lobby_reg.csv")
write_csv(nelr, clean_path, na = "")
```

``` r
nrow(nelr)
#> [1] 18586
file_size(clean_path)
#> 5.27M
guess_encoding(clean_path)
#> # A tibble: 1 × 2
#>   encoding confidence
#>   <chr>         <dbl>
#> 1 ASCII             1
```
