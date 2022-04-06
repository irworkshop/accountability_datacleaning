New Mexico Lobbying
================
Kiernan Nicholls
2020-02-18 11:30:34

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
  - [Conclude](#conclude)

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

The lobbying registration data of New Mexico state was obtained by
computer-assisted-reporting students at the Missouri School of
Journalism, supervised by Prof. David Herzog. Students obtained data via
download or public records request. The dataset is as current as of
2020-02-18.

## Import

``` r
raw_dir <- dir_create(here("nm", "lobby", "data", "raw"))
```

``` r
nml <- read_csv(
  file = path(raw_dir, "NM_LobbyistIndex-3.csv"),
  col_types = cols(
    .default = col_character(),
    `Registration Year` = col_integer()
  )
)
```

## Explore

``` r
head(nml)
#> # A tibble: 6 x 15
#>   reg_year lob_last lob_first lob_email lob_phone lob_addr lob_city lob_state lob_zip employer
#>      <int> <chr>    <chr>     <chr>     <chr>     <chr>    <chr>    <chr>     <chr>   <chr>   
#> 1     2019 Abram    Daniel    Daniel@A… 505.265.… P.O. Bo… Albuque… New Mexi… 87192   Animal …
#> 2     2019 Acton    Doug      480busin… (505) 92… 1418 Ce… Santa Fe New Mexi… 87502   IATSE L…
#> 3     2019 Adondak… Sandra    sandra.a… 505.262.… 8500 Me… Albuque… New Mexi… 87112   America…
#> 4     2019 Aguilar  Michael   maguilar… <NA>      4301 Th… Albuque… New Mexi… 87109   America…
#> 5     2019 Alarid   Gabriel   gabe@you… 505-470-… 6240 Ri… Albuque… New Mexi… 87120   New Mex…
#> 6     2019 Alarid   Vanessa   valarid@… 505.503.… PO Box … Albuque… New Mexi… 87176   Alarid …
#> # … with 5 more variables: emp_addr <chr>, emp_city <chr>, emp_state <chr>, emp_zip <chr>,
#> #   emp_phone <chr>
tail(nml)
#> # A tibble: 6 x 15
#>   reg_year lob_last lob_first lob_email lob_phone lob_addr lob_city lob_state lob_zip employer
#>      <int> <chr>    <chr>     <chr>     <chr>     <chr>    <chr>    <chr>     <chr>   <chr>   
#> 1     2019 Wurzel   Geoffrey  apple2@p… 415-903-… C/O 28 … Sausali… Californ… 94965   Apple I…
#> 2     2019 Yamada   Sayuri    sayuri.y… 505-438-… 528 Don… Santa Fe New Mexi… 87505   Public …
#> 3     2019 Yates    Janet     adobecas… 505.869.… 9 Blueb… Los Lun… New Mexi… 87031   NM Asso…
#> 4     2019 Yepa     Jasmine   jasmine@… 505-255-… 924 C P… Albuque… New Mexi… 87102   New Mex…
#> 5     2019 Zamora   Rudy      zamora69… 50544056… 2217 Ra… Albuque… New Mexi… 87105   Los Cua…
#> 6     2019 Zendel   Edwin     ezendel@… 505-982-… P.O. Bo… Santa Fe New Mexi… 87504-… New Mex…
#> # … with 5 more variables: emp_addr <chr>, emp_city <chr>, emp_state <chr>, emp_zip <chr>,
#> #   emp_phone <chr>
glimpse(sample_n(nml, 20))
#> Rows: 20
#> Columns: 15
#> $ reg_year  <int> 2019, 2019, 2019, 2019, 2019, 2019, 2019, 2019, 2019, 2019, 2019, 2019, 2019, …
#> $ lob_last  <chr> "McGonagle", "Koob", "Carreon", "Leach", "Moon", "Setter", "Romero", "Weaks", …
#> $ lob_first <chr> "Minda", "Julianna", "Lorenzo", "Carol", "Catherine", "Drew", "Bernice", "Dan"…
#> $ lob_email <chr> "minda@mcgonagle.com", "Juliannakoob@gmail.com", "larry@demingRealty.com", "cl…
#> $ lob_phone <chr> "505-228-3755", "505-920-6002", "575-494-0707", "505-780-8001", "505-795-3773"…
#> $ lob_addr  <chr> "823 Silver Ave SW", "PO Box 26952", "220 S. Gold Avenue", "1048 Paseo De Pera…
#> $ lob_city  <chr> "Albuquerque", "Albuquerque", "Deming", "Santa Fe", "Angel Fire", "Albuquerque…
#> $ lob_state <chr> "New Mexico", "New Mexico", "New Mexico", "New Mexico", "New Mexico", "New Mex…
#> $ lob_zip   <chr> "87102", "87125-6952", "88030", "87501", "87710-0521", "87104", "87121", "8718…
#> $ employer  <chr> "Penn National Gaming, Inc.", "New Mexico Coalition of Sexual Assault Programs…
#> $ emp_addr  <chr> "825 Berkshire Blvd. Suite 200", "3909 Juan Tabo NE; Ste. 6", "220 S. Gold Ave…
#> $ emp_city  <chr> "Wyoming", "Albuquerque", "Deming", "Midland", "Santa Fe", "Washington", "Albu…
#> $ emp_state <chr> "Pennsylvania", "New Mexico", "New Mexico", "Texas", "New Mexico", "District O…
#> $ emp_zip   <chr> "19610", "87111", "88030", "79701", "87505", "20005", "87111", "87107", "15317…
#> $ emp_phone <chr> "610.373.2400", "505.883.8020", "575-546-8818", "432-683-7443", "505-982-2442"…
```

### Missing

``` r
col_stats(nml, count_na)
#> # A tibble: 15 x 4
#>    col       class     n      p
#>    <chr>     <chr> <int>  <dbl>
#>  1 reg_year  <int>     0 0     
#>  2 lob_last  <chr>     0 0     
#>  3 lob_first <chr>     0 0     
#>  4 lob_email <chr>     0 0     
#>  5 lob_phone <chr>   154 0.0975
#>  6 lob_addr  <chr>     0 0     
#>  7 lob_city  <chr>     0 0     
#>  8 lob_state <chr>     0 0     
#>  9 lob_zip   <chr>     0 0     
#> 10 employer  <chr>     0 0     
#> 11 emp_addr  <chr>     0 0     
#> 12 emp_city  <chr>     0 0     
#> 13 emp_state <chr>     0 0     
#> 14 emp_zip   <chr>     0 0     
#> 15 emp_phone <chr>     0 0
```

### Duplicates

``` r
nml <- flag_dupes(nml, everything(), .check = TRUE)
```

### Categorical

``` r
col_stats(nml, n_distinct)
#> # A tibble: 15 x 4
#>    col       class     n        p
#>    <chr>     <chr> <int>    <dbl>
#>  1 reg_year  <int>     1 0.000633
#>  2 lob_last  <chr>   582 0.369   
#>  3 lob_first <chr>   474 0.300   
#>  4 lob_email <chr>   711 0.450   
#>  5 lob_phone <chr>   567 0.359   
#>  6 lob_addr  <chr>   635 0.402   
#>  7 lob_city  <chr>   112 0.0709  
#>  8 lob_state <chr>    20 0.0127  
#>  9 lob_zip   <chr>   196 0.124   
#> 10 employer  <chr>   895 0.567   
#> 11 emp_addr  <chr>   884 0.560   
#> 12 emp_city  <chr>   236 0.149   
#> 13 emp_state <chr>    38 0.0241  
#> 14 emp_zip   <chr>   379 0.240   
#> 15 emp_phone <chr>   861 0.545
unique(nml$reg_year)
#> [1] 2019
```

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
nml <- mutate_at(
  .tbl = nml,
  .vars = vars(ends_with("addr")),
  .funs = list(norm = normal_address),
  abbs = usps_street,
  na_rep = TRUE
)
```

``` r
nml %>% 
  select(contains("addr")) %>% 
  distinct() %>% 
  sample_n(10)
#> # A tibble: 10 x 4
#>    lob_addr                     emp_addr               lob_addr_norm             emp_addr_norm     
#>    <chr>                        <chr>                  <chr>                     <chr>             
#>  1 2007 Botulph Rd              2007 Botulph Rd.       2007 BOTULPH RD           2007 BOTULPH RD   
#>  2 P.O. Box 32616               1327 N. Riverside Dri… PO BOX 32616              1327 N RIVERSIDE …
#>  3 13244 Twilight Trail Place … 211 Blue Ski Lane      13244 TWILIGHT TRL PLACE… 211 BLUE SKI LN   
#>  4 1458 Miracerros Lane N.      5300 Seqoia NW #204    1458 MIRACERROS LN N      5300 SEQOIA NW 204
#>  5 POB 720                      P.O. Box 21100         POB 720                   PO BOX 21100      
#>  6 P.O. Box 1864                P.O. Box 1864          PO BOX 1864               PO BOX 1864       
#>  7 P.O. Box 1067                705 St. Francis Drive  PO BOX 1067               705 ST FRANCIS DR 
#>  8 PO Box 66433                 PO Box 66433           PO BOX 66433              PO BOX 66433      
#>  9 800 Lomas Blvd. NW, Suite 2… 3821 Menaul Blvd. NE   800 LOMAS BLVD NW STE 200 3821 MENAUL BLVD …
#> 10 605 Galisteo C               HC 33 Box 178          605 GALISTEO C            HC 33 BOX 178
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
nml <- mutate_at(
  .tbl = nml,
  .vars = vars(ends_with("zip")),
  .funs = list(norm = normal_zip),
  na_rep = TRUE
)
```

``` r
progress_table(
  nml$lob_zip,
  nml$lob_zip_norm,
  nml$emp_zip,
  nml$emp_zip_norm,
  compare = valid_zip
)
#> # A tibble: 4 x 6
#>   stage        prop_in n_distinct prop_na n_out n_diff
#>   <chr>          <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 lob_zip        0.927        196 0         116     21
#> 2 lob_zip_norm   0.996        183 0           6      4
#> 3 emp_zip        0.939        379 0          97     55
#> 4 emp_zip_norm   0.994        348 0.00127     9      7
```

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

``` r
nml <- mutate_at(
  .tbl = nml,
  .vars = vars(ends_with("state")),
  .funs = list(norm = normal_state),
  abbreviate = TRUE,
  na_rep = TRUE,
  valid = valid_state
)
```

``` r
count(nml, lob_state, lob_state_norm, sort = TRUE)
#> # A tibble: 20 x 3
#>    lob_state                    lob_state_norm     n
#>    <chr>                        <chr>          <int>
#>  1 New Mexico                   NM              1447
#>  2 California                   CA                29
#>  3 Texas                        TX                28
#>  4 District Of Columbia         DC                19
#>  5 Colorado                     CO                18
#>  6 Arizona                      AZ                 6
#>  7 Outside of the United States <NA>               5
#>  8 Virginia                     VA                 5
#>  9 New York                     NY                 4
#> 10 Massachusetts                MA                 3
#> 11 Tennessee                    TN                 3
#> 12 Georgia                      GA                 2
#> 13 Illinois                     IL                 2
#> 14 Indiana                      IN                 2
#> 15 Minnesota                    MN                 1
#> 16 North Carolina               NC                 1
#> 17 Oklahoma                     OK                 1
#> 18 Pennsylvania                 PA                 1
#> 19 South Carolina               SC                 1
#> 20 Washington                   WA                 1
```

``` r
progress_table(
  nml$lob_state,
  nml$lob_state_norm,
  nml$emp_state,
  nml$emp_state_norm,
  compare = valid_state
)
#> # A tibble: 4 x 6
#>   stage          prop_in n_distinct prop_na n_out n_diff
#>   <chr>            <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 lob_state            0         20 0        1579     20
#> 2 lob_state_norm       1         20 0.00317     0      1
#> 3 emp_state            0         38 0        1579     38
#> 4 emp_state_norm       1         37 0.00443     0      1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
nml <- mutate_at(
  .tbl = nml,
  .vars = vars(ends_with("city")),
  .funs = list(norm = normal_city),
  abbs = usps_city,
  states = c("NM", "DC", "NEW MEXICO"),
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
nml <- nml %>% 
  left_join(
    y = zipcodes,
    by = c(
      "lob_state_norm" = "state",
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
nml <- nml %>% 
  left_join(
    y = zipcodes,
    by = c(
      "emp_state_norm" = "state",
      "emp_zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(emp_city_norm, city_match),
    match_dist = str_dist(emp_city_norm, city_match),
    emp_city_swap = if_else(
      condition = !is.na(match_dist) & match_abb | match_dist == 1,
      true = city_match,
      false = emp_city_norm
    )
  ) %>% 
  select(
    -city_match,
    -match_dist,
    -match_abb
  )
```

#### Progress

| stage           | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :-------------- | -------: | ----------: | -------: | -----: | ------: |
| lob\_city)      |    0.977 |         109 |    0.000 |     36 |       9 |
| lob\_city\_norm |    0.977 |         109 |    0.000 |     36 |       9 |
| lob\_city\_swap |    0.994 |         103 |    0.009 |      9 |       4 |
| emp\_city)      |    0.968 |         233 |    0.000 |     51 |      31 |
| emp\_city\_norm |    0.975 |         231 |    0.000 |     39 |      25 |
| emp\_city\_swap |    0.987 |         217 |    0.021 |     20 |      12 |

## Conclude

``` r
nml <- nml %>% 
  select(
    -lob_city_norm,
    -emp_city_norm
  ) %>% 
  rename(
    lob_city_clean = lob_city_swap,
    emp_city_clean = emp_city_swap
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean"))
```

``` r
glimpse(sample_n(nml, 20))
#> Rows: 20
#> Columns: 23
#> $ reg_year        <int> 2019, 2019, 2019, 2019, 2019, 2019, 2019, 2019, 2019, 2019, 2019, 2019, …
#> $ lob_last        <chr> "Najjar", "Bradley", "Valverde", "Scanland", "Kimble", "Evans", "Martine…
#> $ lob_first       <chr> "Jared", "Walter", "Randi", "Scott", "David", "Gail", "Severo", "Michael…
#> $ lob_email       <chr> "jared.d.najjar@gmail.com", "wbradley@dfamilk.com", "rvalverde@montand.c…
#> $ lob_phone       <chr> "505-660-4370", "505.763.4528", "505-982-3873", "505-280-2122", "575-382…
#> $ lob_addr        <chr> "2200 Brothers Rd", "917 B Norris Street", "PO Box 2307", "P.O. Box 3261…
#> $ lob_city        <chr> "Santa Fe", "Clovis", "Santa Fe", "Santa Fe", "Las Cruces", "Albuquerque…
#> $ lob_state       <chr> "New Mexico", "New Mexico", "New Mexico", "New Mexico", "New Mexico", "N…
#> $ lob_zip         <chr> "87505", "88101", "87504-2307", "87594", "88011", "87102", "87505", "882…
#> $ employer        <chr> "Intel Corporation", "Dairy Farmers of America Inc.", "Exxon Mobil Corpo…
#> $ emp_addr        <chr> "4100 Sara Road, SE-MS: F9-607", "3500 William D., Tate Ave. Suite 100",…
#> $ emp_city        <chr> "Rio Rancho", "Grapevine", "San Rafael", "Farmington", "Washington", "Sa…
#> $ emp_state       <chr> "New Mexico", "Texas", "California", "New Mexico", "District Of Columbia…
#> $ emp_zip         <chr> "87124", "76051-7102", "94901", "87401", "20001", "87501", "87505", "871…
#> $ emp_phone       <chr> "893-3750", "817.410.4504", "415-389-6800", "325-5011", "703-328-4994", …
#> $ lob_addr_clean  <chr> "2200 BROTHERS RD", "917 B NORRIS ST", "PO BOX 2307", "PO BOX 32616", "4…
#> $ emp_addr_clean  <chr> "4100 SARA RD SEMS F 9607", "3500 WILLIAM D TATE AVE STE 100", "2350 KER…
#> $ lob_zip_clean   <chr> "87505", "88101", "87504", "87594", "88011", "87102", "87505", "88253", …
#> $ emp_zip_clean   <chr> "87124", "76051", "94901", "87401", "20001", "87501", "87505", "87102", …
#> $ lob_state_clean <chr> "NM", "NM", "NM", "NM", "NM", "NM", "NM", "NM", "NM", "NM", "DC", "NM", …
#> $ emp_state_clean <chr> "NM", "TX", "CA", "NM", "DC", "NM", "NM", "NM", "NM", "DC", "CA", "NM", …
#> $ lob_city_clean  <chr> "SANTA FE", "CLOVIS", "SANTA FE", "SANTA FE", "LAS CRUCES", "ALBUQUERQUE…
#> $ emp_city_clean  <chr> "RIO RANCHO", "GRAPEVINE", "SAN RAFAEL", "FARMINGTON", "WASHINGTON", "SA…
```

``` r
clean_dir <- dir_create(here("nm", "lobby", "data", "clean"))
```

``` r
write_csv(
  x = nml,
  path = path(clean_dir, "nm_lobby_clean.csv"),
  na = ""
)
```
