Florida Lobbyist Registration
================
Kiernan Nicholls
2019-10-14 14:33:05

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
pacman::p_load_gh("kiernann/gluedown")
pacman::p_load(
  stringdist, # levenshtein value
  RSelenium, # remote browser
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

Data is obtained as tab-delinated files from the [Florida Lobbying
Registration Office](https://floridalobbyist.gov/) (LRO).

> Legislative and Executive branch lobbyist/principal registration
> datasets can be downloaded free of charge. Each dataset contains basic
> information about lobbyists, the principals they register to
> represent, and any associated firm information. Click on the File
> Definition Description link below to view the file format. The
> datasets are updated daily.

``` r
key_url <- "https://floridalobbyist.gov/reports/disk%20file%20definition.pdf?cp=0.3379601757893852"
download.file(key_url, destfile = url2path(key_url, here("fl", "lobbying", "reg", "docs")))
```

## Import

### Download

The LRO provides the datasets in tab-delimited format.

> The tab-delimited files below are in the (.TXT) format and can be
> imported into any word processor, spreadsheet, or database program.
> 
>   - [Legislative Lobbyist
>     File](https://floridalobbyist.gov/reports/llob.txt)
>   - [Executive Lobbyist
>     File](https://floridalobbyist.gov/reports/llob.txt)

We can download these two files to our raw directory.

``` r
raw_dir <- here("fl", "lobbying", "reg", "data", "raw")
dir_create(raw_dir)
```

``` r
llob_url <- "https://floridalobbyist.gov/reports/llob.txt"
llob_file <- url2path(llob_url, raw_dir)
download.file(url = llob_url, destfile = llob_file)

elob_url <- "https://floridalobbyist.gov/reports/elob.txt"
elob_file <- url2path(elob_url, raw_dir)
download.file(url = elob_url, destfile = elob_file)
```

### Read

We can read both files at once with the `vroom::vroom()` function.

``` r
fllr <- vroom(
  file = dir_ls(raw_dir),
  .name_repair = make_clean_names,
  delim = "\t",
  escape_backslash = FALSE,
  escape_double = FALSE,
  id = "source",
  skip = 2,
  col_types = cols(
    .default = col_character(),
    `Eff Date` = col_date_usa(),
    `WD Date` = col_date_usa(),
  )
)
```

The original file contains *three* different types of data, with the
type specified in the second row of the spreadsheet.

1.  Lobbyist
2.  Registration
3.  Lobby Firm

This resuled in most column names being repeated for each entity type,
with `vroom::vroom()` and `janitor::make_clean_names()` appending each
repeated name with a unique digit. We will replace these unique digits
with a meaningful prefix identifying the entity type.

``` r
fllr_names <- names(fllr)
fllr_prefix <- c("lobby", "client", "firm")
```

``` r
fllr_names[02:14] <- str_c(fllr_prefix[1], str_remove(fllr_names[02:14], "_(.*)$"), sep = "_")
fllr_names[15]    <- str_c(fllr_prefix[2], str_remove(fllr_names[15],    "^(.*)_"), sep = "_")
fllr_names[16:24] <- str_c(fllr_prefix[2], str_remove(fllr_names[16:24], "_(.*)$"), sep = "_")
fllr_names[26:36] <- str_c(fllr_prefix[3], str_remove(fllr_names[26:36], "_(.*)$"), sep = "_")
which_address <- str_which(fllr_names, "address")
fllr_names[which_address] <- str_c(fllr_names[which_address], c(1:3, 1:2, 1:2))
all(fllr_names == tidy_names(fllr_names))
#> [1] TRUE
```

We can see how this process made the variable names much more useful.

    #> # A tibble: 10 x 2
    #>    origial        fixed          
    #>    <chr>          <chr>          
    #>  1 address_5      client_address2
    #>  2 country        client_country 
    #>  3 principal_name client_name    
    #>  4 state_2        client_state   
    #>  5 zip_3          firm_zip       
    #>  6 address        lobby_address1 
    #>  7 address_2      lobby_address2 
    #>  8 first_name     lobby_first    
    #>  9 last_name      lobby_last     
    #> 10 zip            lobby_zip

So we can overwrite the orignal names with this new vector.

``` r
fllr <- set_names(fllr, fllr_names)
```

Some columns are actually completely empty. We can remove those columns
now.

``` r
fllr <- remove_empty(fllr, "cols")
```

## Explore

``` r
head(fllr)
#> # A tibble: 6 x 31
#>   source lobby_last lobby_first lobby_middle lobby_suffix lobby_address1 lobby_address2 lobby_city
#>   <chr>  <chr>      <chr>       <chr>        <chr>        <chr>          <chr>          <chr>     
#> 1 /home… Aaron      Lisa        <NA>         <NA>         7101 Sleepy H… <NA>           Tallahass…
#> 2 /home… Aaron      Lisa        <NA>         <NA>         7101 Sleepy H… <NA>           Tallahass…
#> 3 /home… Aaron      Lisa        <NA>         <NA>         7101 Sleepy H… <NA>           Tallahass…
#> 4 /home… Aaron      Lisa        <NA>         <NA>         7101 Sleepy H… <NA>           Tallahass…
#> 5 /home… Aaron      Lisa        <NA>         <NA>         7101 Sleepy H… <NA>           Tallahass…
#> 6 /home… Aaron      Lisa        <NA>         <NA>         7101 Sleepy H… <NA>           Tallahass…
#> # … with 23 more variables: lobby_state <chr>, lobby_zip <chr>, lobby_phone <chr>,
#> #   lobby_suspended <chr>, client_name <chr>, client_eff <date>, client_wd <date>,
#> #   client_address1 <chr>, client_address2 <chr>, client_city <chr>, client_state <chr>,
#> #   client_zip <chr>, client_country <chr>, client_naics <chr>, firm_name <chr>,
#> #   firm_address1 <chr>, firm_address2 <chr>, firm_city <chr>, firm_state <chr>, firm_zip <chr>,
#> #   firm_phone <chr>, firm_eff <date>, firm_wd <date>
tail(fllr)
#> # A tibble: 6 x 31
#>   source lobby_last lobby_first lobby_middle lobby_suffix lobby_address1 lobby_address2 lobby_city
#>   <chr>  <chr>      <chr>       <chr>        <chr>        <chr>          <chr>          <chr>     
#> 1 /home… Zauder     Stephanie   Grutman      <NA>         401 E. Las Ol… Suite 1400     Ft. Laude…
#> 2 /home… Zauder     Stephanie   Grutman      <NA>         401 E. Las Ol… Suite 1400     Ft. Laude…
#> 3 /home… Zauder     Stephanie   Grutman      <NA>         401 E. Las Ol… Suite 1400     Ft. Laude…
#> 4 /home… Zepp       Victoria    Vangalis     DPL          411 E College… <NA>           Tallahass…
#> 5 /home… Zingale    James       A.           <NA>         Post Office 5… <NA>           Tallahass…
#> 6 /home… Zubaly     Amy         S.           <NA>         Po Box 10114   <NA>           Tallahass…
#> # … with 23 more variables: lobby_state <chr>, lobby_zip <chr>, lobby_phone <chr>,
#> #   lobby_suspended <chr>, client_name <chr>, client_eff <date>, client_wd <date>,
#> #   client_address1 <chr>, client_address2 <chr>, client_city <chr>, client_state <chr>,
#> #   client_zip <chr>, client_country <chr>, client_naics <chr>, firm_name <chr>,
#> #   firm_address1 <chr>, firm_address2 <chr>, firm_city <chr>, firm_state <chr>, firm_zip <chr>,
#> #   firm_phone <chr>, firm_eff <date>, firm_wd <date>
glimpse(sample_frac(fllr))
#> Observations: 24,184
#> Variables: 31
#> $ source          <chr> "/home/kiernan/R/accountability_datacleaning/R_campfin/fl/lobbying/reg/d…
#> $ lobby_last      <chr> "Hartley", "Bowen", "Dorworth", "Sharkey", "Coker", "Cannon", "Cruz", "R…
#> $ lobby_first     <chr> "Jeff", "Marsha", "Chris", "Jeffrey", "Robert", "Roy", "Carlos", "Robert…
#> $ lobby_middle    <chr> NA, "L.", NA, "B.", "E.", "Dean", "M.", "F.", "L.", "L.", "C.", NA, "J."…
#> $ lobby_suffix    <chr> NA, NA, NA, NA, NA, "Jr.", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ lobby_address1  <chr> "311 E Park Ave", "1400 Village Square Blvd", "618 E. South Street", "10…
#> $ lobby_address2  <chr> NA, "Suite #3-330", "Suite 500", "Ste 640", NA, "Ste 600", "Suite 101", …
#> $ lobby_city      <chr> "Tallahassee", "Tallahassee", "Orlando", "Tallahassee", "Clewiston", "Ta…
#> $ lobby_state     <chr> "FL", "FL", "FL", "FL", "FL", "FL", "FL", "FL", "FL", "FL", "FL", "Flori…
#> $ lobby_zip       <chr> "32301", "32309", "32801", "32301", "33440", "32301", "32301", "32301-17…
#> $ lobby_phone     <chr> "(850) 224-5081", "(850) 228-3904", "(407) 803-3878", "(850) 224-1660", …
#> $ lobby_suspended <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ client_name     <chr> "Duke Energy Corporation", "University Area Community Development Corpor…
#> $ client_eff      <date> 2019-01-06, 2019-02-05, 2019-01-03, 2019-01-02, 2019-01-03, 2019-10-10,…
#> $ client_wd       <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, 2019-09-30, NA, NA,…
#> $ client_address1 <chr> "550 S Tryon St", "14013 N 22nd St", "1111 N Congress Ave", "106 E Colle…
#> $ client_address2 <chr> NA, NA, NA, "Ste 640", NA, "2nd Floor", NA, NA, "University of Florida",…
#> $ client_city     <chr> "Charlotte", "Tampa", "West Palm Beach", "Tallahassee", "Clewiston", "Mi…
#> $ client_state    <chr> "NC", "FL", "FL", "FL", "FL", "FL", "FL", "FL", "FL", "Florida", "KS", "…
#> $ client_zip      <chr> "28202", "33613", "33409", "32301", "33440", "33145", "33440-3032", "323…
#> $ client_country  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ client_naics    <chr> "221123", "813319", "711212", "236116", "111421", "624229", "111421", "5…
#> $ firm_name       <chr> "Smith Bryan & Myers Inc", "ML Bowen Advisors LLC", "Ballard Partners", …
#> $ firm_address1   <chr> "311 E Park Ave", "1400 Village Square Blvd #3-330", "201 East Park Aven…
#> $ firm_address2   <chr> NA, NA, "5th Floor", NA, NA, "Ste 600", "Suite 305", "2nd floor", "5th F…
#> $ firm_city       <chr> "Tallahassee", "Tallahassee", "Tallahassee", "Tallahassee", NA, "Tallaha…
#> $ firm_state      <chr> "FL", "FL", "FL", "FL", NA, "FL", "FL", "florida", "FL", "FL", "FL", NA,…
#> $ firm_zip        <chr> "32301", "32312", "32301", "32301", NA, "32301", "33137", "32301", "3230…
#> $ firm_phone      <chr> "(850) 224-5081", "(850) 228-3904", "(850) 577-0444", "(850) 224-1660", …
#> $ firm_eff        <date> 2019-01-06, 2019-02-05, 2019-01-03, 2019-01-02, NA, 2019-10-10, 2019-03…
#> $ firm_wd         <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
```

### Missing

``` r
glimpse_fun(fllr, count_na)
#> # A tibble: 31 x 4
#>    col             type      n        p
#>    <chr>           <chr> <dbl>    <dbl>
#>  1 source          chr       0 0       
#>  2 lobby_last      chr       0 0       
#>  3 lobby_first     chr       0 0       
#>  4 lobby_middle    chr    6094 0.252   
#>  5 lobby_suffix    chr   22640 0.936   
#>  6 lobby_address1  chr       0 0       
#>  7 lobby_address2  chr   11578 0.479   
#>  8 lobby_city      chr       0 0       
#>  9 lobby_state     chr       0 0       
#> 10 lobby_zip       chr       4 0.000165
#> 11 lobby_phone     chr       0 0       
#> 12 lobby_suspended chr   24178 1.000   
#> 13 client_name     chr       0 0       
#> 14 client_eff      date      0 0       
#> 15 client_wd       date  22083 0.913   
#> 16 client_address1 chr       0 0       
#> 17 client_address2 chr   15428 0.638   
#> 18 client_city     chr       0 0       
#> 19 client_state    chr      10 0.000413
#> 20 client_zip      chr      16 0.000662
#> 21 client_country  chr   24152 0.999   
#> 22 client_naics    chr       0 0       
#> 23 firm_name       chr    2301 0.0951  
#> 24 firm_address1   chr    2301 0.0951  
#> 25 firm_address2   chr   13720 0.567   
#> 26 firm_city       chr    2301 0.0951  
#> 27 firm_state      chr    2301 0.0951  
#> 28 firm_zip        chr    2332 0.0964  
#> 29 firm_phone      chr    2301 0.0951  
#> 30 firm_eff        date   2309 0.0955  
#> 31 firm_wd         date  23980 0.992
```

``` r
fllr <- flag_na(fllr, ends_with("name"))
sum(fllr$na_flag)
#> [1] 2301
mean(fllr$na_flag)
#> [1] 0.09514555
```

### Duplicates

There are no duplicate records in the database.

``` r
fllr <- flag_dupes(fllr, everything())
sum(fllr$dupe_flag)
#> [1] 0
mean(fllr$dupe_flag)
#> [1] 0
```

### Dates

The database only contains registrants for the current year.

``` r
fllr <- mutate(fllr, client_year = year(client_eff))
unique(fllr$client_year == year(today()))
#> [1] TRUE
```

``` r
min(fllr$client_eff) == today() %>% floor_date("year")
#> [1] TRUE
max(fllr$client_eff) == today()
#> [1] TRUE
```

## Wrangle

For each of three entity types (lobbyists, client, firm) there are: 1-3
`*_address*` variables, `*_city`, `*_state`, `*_zip`, `*_phone`, and
`*_ext`. We will wrangle each variable type for all three entity types
at a time.

### Addresses

We will begin with address normalization. First, we can use
`tidyr::unite()` to combine each separate variable into a single string
for each registrant.

``` r
fllr <- fllr %>% 
  unite(
    starts_with("lobby_address"),
    col = lobby_address_full,
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  unite(
    starts_with("client_address"),
    col = client_address_full,
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  unite(
    starts_with("firm_address"),
    col = firm_address_full,
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  )
```

Then, each of these full address variables can be passed to
`campfin::normal_address()` to create new normalized variables with
improved consistency.

``` r
fllr <- fllr %>% 
  mutate(
    lobby_address_norm = normal_address(
      address = lobby_address_full,
      add_abbs = usps_street,
      na_rep = TRUE
    ),
    client_address_norm = normal_address(
      address = client_address_full,
      add_abbs = usps_street,
      na_rep = TRUE
    ),
    client_address_norm = normal_address(
      address = client_address_full,
      add_abbs = usps_street,
      na_rep = TRUE
    )
  )
```

Finally, remove the intermediary combined variables.

``` r
fllr <- select(fllr, -ends_with("address_full"))
```

From this, we can see the kind of normalization that was performed.

    #> # A tibble: 1,697 x 3
    #>    lobby_address1           lobby_address2          lobby_address_norm                             
    #>    <chr>                    <chr>                   <chr>                                          
    #>  1 315 S Calhoun St         Ste 830                 315 SOUTH CALHOUN STREET SUITE 830             
    #>  2 601 South Lake Destiny … suite 200               601 SOUTH LAKE DESTINY ROAD SUITE 200          
    #>  3 State Board of Administ… 1801 Hermitage Blvd St… STATE BOARD OF ADMINISTRATION 1801 HERMITAGE B…
    #>  4 4365 N Andromeda Loop    315 Millican Hall       4365 NORTH ANDROMEDA LOOP 315 MILLICAN HALL    
    #>  5 6850 SW 24th Street      403                     6850 SOUTHWEST 24TH STREET 403                 
    #>  6 401 North Main Street    <NA>                    401 NORTH MAIN STREET                          
    #>  7 150 W University Blvd    <NA>                    150 WEST UNIVERSITY BOULEVARD                  
    #>  8 215 South Monroe Street  Suite 601               215 SOUTH MONROE STREET SUITE 601              
    #>  9 1319 Airport Dr          Apt. F4                 1319 AIRPORT DRIVE APARTMENT F4                
    #> 10 400 South Monroe         The Capitol Building    400 SOUTH MONROE THE CAPITOL BUILDING          
    #> # … with 1,687 more rows

### ZIP

Similarly, we can use `campfin::normal_zip()` to create a normalized
five-digit ZIP code and remove invalid values.

``` r
fllr <- fllr %>% 
  mutate(
    lobby_zip_norm = normal_zip(
      zip = lobby_zip,
      na_rep = TRUE
    ),
    client_zip_norm = normal_zip(
      zip = client_zip,
      na_rep = TRUE
    ),
    firm_zip_norm = normal_zip(
      zip = firm_zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(fllr$lobby_zip,  fllr$lobby_zip_norm,  compare = valid_zip)
#> # A tibble: 2 x 6
#>   stage          prop_in n_distinct  prop_na n_out n_diff
#>   <chr>            <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 lobby_zip        0.683        891 0.000165  7675    540
#> 2 lobby_zip_norm   1.000        483 0.000165     2      3
progress_table(fllr$client_zip, fllr$client_zip_norm, compare = valid_zip)
#> # A tibble: 2 x 6
#>   stage           prop_in n_distinct  prop_na n_out n_diff
#>   <chr>             <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 client_zip        0.711       2847 0.000662  6991   1639
#> 2 client_zip_norm   0.997       1495 0.00145     79     23
progress_table(fllr$firm_zip,   fllr$firm_zip_norm,   compare = valid_zip)
#> # A tibble: 2 x 6
#>   stage         prop_in n_distinct prop_na n_out n_diff
#>   <chr>           <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 firm_zip        0.914        204  0.0964  1880     44
#> 2 firm_zip_norm   1            173  0.0964     0      1
```

### States

Below, we can see the inconsistency in `*_state` variable format.

``` r
fllr %>% 
  select(ends_with("state")) %>% 
  distinct() %>% 
  sample_frac()
#> # A tibble: 312 x 3
#>    lobby_state client_state firm_state
#>    <chr>       <chr>        <chr>     
#>  1 FL          florida      FL        
#>  2 FL          CA           Florida   
#>  3 FL          CA           FL        
#>  4 Florida     MD           FL        
#>  5 Florida     OH           FL        
#>  6 SW1A 1DH    SW1A 1DH     <NA>      
#>  7 LA          IL           LA        
#>  8 Florida     Florida      FL        
#>  9 Florida     MA           FL        
#> 10 DC          Virginia     DC        
#> # … with 302 more rows
```

We can use `campfin::normal_state()` to create valid two-letter state
abbreviations.

``` r
fllr <- fllr %>% 
  mutate(
    lobby_state_norm = normal_state(
      state = lobby_state,
      abbreviate = TRUE,
      valid = NULL
    ),
    client_state_norm = normal_state(
      state = client_state,
      abbreviate = TRUE,
      valid = NULL
    ),
    firm_state_norm = normal_state(
      state = firm_state,
      abbreviate = TRUE,
      valid = NULL
    )
  )
```

``` r
progress_table(fllr$lobby_state,  fllr$lobby_state_norm,  compare = valid_state)
#> # A tibble: 2 x 6
#>   stage            prop_in n_distinct prop_na n_out n_diff
#>   <chr>              <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 lobby_state        0.980         54       0   493     19
#> 2 lobby_state_norm   1.000         39       0     6      4
progress_table(fllr$client_state, fllr$client_state_norm, compare = valid_state)
#> # A tibble: 2 x 6
#>   stage             prop_in n_distinct  prop_na n_out n_diff
#>   <chr>               <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 client_state        0.965         82 0.000413   842     37
#> 2 client_state_norm   0.999         56 0.000455    25     11
progress_table(fllr$firm_state,   fllr$firm_state_norm,   compare = valid_state)
#> # A tibble: 2 x 6
#>   stage           prop_in n_distinct prop_na n_out n_diff
#>   <chr>             <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 firm_state        0.966         23  0.0951   744      6
#> 2 firm_state_norm   1             18  0.0951     0      1
```

### City

The `*_city` variables are the hardest to clean. We can make consistent
and *confident* improvements in normalization by combining
`campfin::normal_city()`, `campfin::is_abbrev()`, `campfin::str_dist()`,
and `refinr::n_gram_merge()`.

First, we will normalize the `*_city` variable for each entity.

``` r
fllr <- fllr %>% 
  mutate(
    lobby_city_norm = normal_city(
      city = lobby_city,
      geo_abbs = usps_city,
      st_abbs = c("FL", "DC", "FLORIDA"),
      na = invalid_city,
      na_rep = TRUE
    ),
    client_city_norm = normal_city(
      city = client_city,
      geo_abbs = usps_city,
      st_abbs = c("FL", "DC", "FLORIDA"),
      na = invalid_city,
      na_rep = TRUE
    ),
    firm_city_norm = normal_city(
      city = firm_city,
      geo_abbs = usps_city,
      st_abbs = c("FL", "DC", "FLORIDA"),
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

Then, we can match each normalized city against the *expected* city for
that registrant’s `*_zip_normal` and `*_state_normal` variables. If the
two city strings, normalized and exptected, have an extremelly similar
string distance *or* if the normalized string appears to be an
abbreviation of the matched expected string, then we can confidently
rely on the matched value.

``` r
fllr <- fllr %>% 
  left_join(
    y = zipcodes,
    by = c(
      "lobby_zip_norm" = "zip",
      "lobby_state_norm" = "state"
    )
  ) %>% 
  rename(lobby_city_match = city) %>% 
  left_join(
    y = zipcodes,
    by = c(
      "client_zip_norm" = "zip",
      "client_state_norm" = "state"
    )
  ) %>% 
  rename(client_city_match = city) %>% 
  left_join(
    y = zipcodes,
    by = c(
      "firm_zip_norm" = "zip",
      "firm_state_norm" = "state"
    )
  ) %>% 
  rename(firm_city_match = city)
```

``` r
fllr <- fllr %>% 
  mutate(
    lobby_city_abb = is_abbrev(lobby_city_norm, lobby_city_match),
    lobby_city_dist = str_dist(lobby_city_norm, lobby_city_match),
    lobby_city_swap = if_else(
      condition = lobby_city_abb | lobby_city_dist == 1,
      true = lobby_city_match,
      false = lobby_city_norm
    )
  ) %>% 
  mutate(
    client_city_abb = is_abbrev(client_city_norm, client_city_match),
    client_city_dist = str_dist(client_city_norm, client_city_match),
    client_city_swap = if_else(
      condition = client_city_abb | client_city_dist == 1,
      true = client_city_match,
      false = client_city_norm
    )
  ) %>% 
  mutate(
    firm_city_abb = is_abbrev(firm_city_norm, firm_city_match),
    firm_city_dist = str_dist(firm_city_norm, firm_city_match),
    firm_city_swap = if_else(
      condition = firm_city_abb | firm_city_dist == 1,
      true = firm_city_match,
      false = firm_city_norm
    )
  )
```

``` r
progress_table(
  str_to_upper(fllr$lobby_city), 
  fllr$lobby_city_norm,
  fllr$lobby_city_swap,
  compare = valid_city
)
#> # A tibble: 3 x 6
#>   stage           prop_in n_distinct  prop_na n_out n_diff
#>   <chr>             <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 lobby_city)       0.928        252 0         1743     50
#> 2 lobby_city_norm   0.965        242 0          847     34
#> 3 lobby_city_swap   0.966        238 0.000372   833     29

progress_table(
  str_to_upper(fllr$client_city), 
  fllr$client_city_norm,
  fllr$client_city_swap,
  compare = valid_city
)
#> # A tibble: 3 x 6
#>   stage            prop_in n_distinct prop_na n_out n_diff
#>   <chr>              <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 client_city)       0.877        838 0        2978    212
#> 2 client_city_norm   0.919        807 0        1956    166
#> 3 client_city_swap   0.928        761 0.00649  1735    125

progress_table(
  str_to_upper(fllr$firm_city), 
  fllr$firm_city_norm,
  fllr$firm_city_swap,
  compare = valid_city
)
#> # A tibble: 3 x 6
#>   stage          prop_in n_distinct prop_na n_out n_diff
#>   <chr>            <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 firm_city)       0.901        105  0.0951  2156     19
#> 2 firm_city_norm   0.965        100  0.0951   772     11
#> 3 firm_city_swap   0.965        100  0.0966   772     11
```

``` r
fllr %>% 
  filter(client_city_swap %out% valid_city) %>% 
  count(client_city_norm, sort = TRUE)
#> # A tibble: 163 x 2
#>    client_city_norm       n
#>    <chr>              <int>
#>  1 CORAL GABLES         216
#>  2 SUNRISE              133
#>  3 MIAMI LAKES           95
#>  4 DORAL                 83
#>  5 HALLANDALE BEACH      77
#>  6 LAKE BUENA VISTA      72
#>  7 PALM BEACH GARDENS    61
#>  8 DC                    59
#>  9 COCONUT CREEK         53
#> 10 PLANTATION            53
#> # … with 153 more rows
```

## Export

``` r
proc_dir <- here("fl", "lobbying", "reg", "data", "processed")
dir_create(proc_dir)
```

``` r
fllr %>%
  # remove intermediary columns
  select(
    -lobby_city_match,
    -lobby_city_dist,
    -lobby_city_abb,
    -lobby_city_norm,
    -client_city_match,
    -client_city_dist,
    -client_city_abb,
    -client_city_norm,
    -firm_city_match,
    -firm_city_dist,
    -firm_city_abb,
    -firm_city_norm
  ) %>% 
  write_csv(
    path = glue("{proc_dir}/fl_lobby_reg_clean.csv"),
    na = ""
  )
```
