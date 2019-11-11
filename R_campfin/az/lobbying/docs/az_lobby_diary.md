Arizona Lobbyists
================
Kiernan Nicholls
2019-11-11 15:47:09

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
  tidyverse, # data manipulation
  lubridate, # datetime strings
  magrittr, # pipe opperators
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
  readxl, # read excel files
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

Data is obtained fromt the [Arizona Secretary of
States](https://azsos.gov). The data was obtained personally from a
contanct at the SOS office. The data is only available publically in PDF
format.

## Import

The data was provided to IRW as a `.zip` archives of 12 `.csv` files and
one `.xlsx` file with a key describing each of the individual files.

``` r
raw_dir <- here("az", "lobbying", "data", "raw")
dir_exists(raw_dir)
#> /home/kiernan/R/accountability_datacleaning/R_campfin/az/lobbying/data/raw 
#>                                                                       TRUE
```

We can read the excel file with `readxl::read_excel()` and list the
rows.

``` r
here("az", "lobbying", "data", "raw", "LOB Database Key.xlsx") %>% 
  read_excel(col_names = FALSE) %>% 
  select(1) %>% 
  as_vector() %>% 
  unname() %>% 
  map_md(md_code, 1) %>% 
  md_bullet()
```

  - `BEN` – Beneficiaries table – Individuals who have been listed as
    benefiting from an expenditure
  - `EMP` – Employees table – Individuals who were listed as employees
    on a lobbyist registration
  - `LOB` – Lobbyist table – Lobbyist information
  - `LOB_REG` – Lobbyist Registration table – Registration status and
    filing dates
  - `LOB_REP` – Lobbyist Reporting table – Quarterly Expenditure
    information
  - `PPB` – Principal & Public Body table – Principal & Public Body
    information
  - `PPB_REG` - Principal & Public Body Registration table –
    Registration status and filing dates for P/PB’s
  - `PPB_REP` - Principal & Public Body Reporting table – Annual
    Expenditure information
  - `REF` – Reference table – Links the P/PB’s to the Lobbyists
  - `TRN` – Transactions table – Tracks expenditures made by lobbyists
    on behalf of P/PB’s
  - `TRN_CAT` – Transaction Categories – Reference table for TRN\_CAT
    column in TRN table
  - `TRN_CODE` – Transaction Code – Reference table for TRN\_CODE\_ID
    column in TRN table

Then, we can `unzip()` the file and list the `.csv` files within.

``` r
zip_file <- dir_ls(raw_dir, glob = "*.zip$")
unzip(
  zipfile = zip_file,
  exdir = raw_dir
)
```

``` r
lob_dir <- dir_ls(raw_dir, type = "dir")
dir_ls(lob_dir) %>% 
  str_remove("^.*(az)") %>% 
  md_code() %>% 
  md_bullet()
```

  - `/lobbying/data/raw/Lobbyist/BEN.CSV`
  - `/lobbying/data/raw/Lobbyist/EMP.CSV`
  - `/lobbying/data/raw/Lobbyist/LOB.CSV`
  - `/lobbying/data/raw/Lobbyist/LOB_REG.CSV`
  - `/lobbying/data/raw/Lobbyist/LOB_REP.CSV`
  - `/lobbying/data/raw/Lobbyist/PPB.CSV`
  - `/lobbying/data/raw/Lobbyist/PPB_REG.CSV`
  - `/lobbying/data/raw/Lobbyist/PPB_REP.CSV`
  - `/lobbying/data/raw/Lobbyist/REF.CSV`
  - `/lobbying/data/raw/Lobbyist/TRN.CSV`
  - `/lobbying/data/raw/Lobbyist/TRN_CAT.CSV`
  - `/lobbying/data/raw/Lobbyist/TRN_CODE.CSV`

We will join together these various tables into a single database of
lobbyists, their employers, and their clients. First, we will have to
read each file.

The `LOB.csv` file contains the base information on each lobbyist (name,
phone, address, etc).

``` r
lob <- read_csv(
  file = str_c(lob_dir, "LOB.CSV", sep = "/"),
  col_types = cols(.default = col_character()),
)
```

    #> Observations: 17,176
    #> Variables: 9
    #> $ lob_id        <chr> "3607399", "3606359", "3206530", "3607459", "3107308", "3040118", "3504608…
    #> $ lob_lastname  <chr> "HUGHES", "SCHMIDBAUER", "MCKINNEY", "MATEKOVIC", "GAMBLE", "RIDGE ANS ISA…
    #> $ lob_firstname <chr> "MICHAEL", "KATIE", "DAN", "MICHAEL", "GERALDINE", "P.C.", "EL J", "JACK",…
    #> $ lob_phone     <chr> "928-474-5242", "480-635-3608", "480-991-3300", "215-238-3657", "520-672-2…
    #> $ lob_addr1     <chr> "303 N BEELINE HWY", "PO BOX 9000", "6238 E ROSE CIRCLE DR", "1101 MARKET …
    #> $ lob_addr2     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "AT&T GLOB…
    #> $ lob_city      <chr> "PAYSON", "HIGLEY", "SCOTTSDALE", "PHILADELPHIA", "SHONTO", NA, "LUBBOCK",…
    #> $ lob_state     <chr> "AZ", "AZ", "AZ", "PA", "AZ", NA, "TX", "AZ", "AZ", "AZ", "AZ", "AZ", "AZ"…
    #> $ lob_zip       <chr> "85541-", "85236-", "85614", "19107-", "86054-7900", NA, "79401", "85296-"…

The `LOG_REG.csv` file contains the information regarding each
lobbyist’s registration status for *every* term for which they were
registered.

``` r
lob_reg <- read_csv(
  file = str_c(lob_dir, "LOB_REG.CSV", sep = "/"),
  col_types = cols(
    .default = col_character(),
    LOB_TERM = col_integer(),
    REQUIRED = col_logical(),
    RECEIVED = col_date("%m/%d/%Y %H:%M %p"),
    STARTED = col_date("%m/%d/%Y %H:%M %p"),
    TERMINATED = col_date("%m/%d/%Y %H:%M %p")
  )
)
```

    #> # A tibble: 10 x 6
    #>    lob_id  lob_term required received   started    terminated
    #>    <chr>      <int> <lgl>    <date>     <date>     <date>    
    #>  1 3609989     2012 TRUE     NA         2013-12-11 NA        
    #>  2 3100166     2000 FALSE    NA         2000-01-01 NA        
    #>  3 3600684     2004 FALSE    NA         NA         NA        
    #>  4 3500174     2004 FALSE    NA         2004-01-01 NA        
    #>  5 3104654     1996 FALSE    NA         1997-01-01 NA        
    #>  6 3206788     2000 TRUE     1999-11-24 2000-01-01 NA        
    #>  7 3107160     2002 FALSE    NA         NA         NA        
    #>  8 3602578     2004 FALSE    NA         NA         NA        
    #>  9 3103175     1996 FALSE    NA         1997-01-01 NA        
    #> 10 3107284     2002 FALSE    NA         2002-01-01 NA

The `lob_reg` data frame can be joined with the base `lob` using the
`lob_id` variable as a relational key. When we perform a
`dplyr::left_join()`, new rows will be created. In the `lob` data frame,
each lobbyist is only listed once. After joining, those single rows will
be repeated with new distinct rows from `lob_reg`.

``` r
# lob <- left_join(lob, lob_reg, by = "lob_id")
```

The next data set to add will be the client (pincipal) represented by
each lobbyist. The names of each lobbist are contained in `PPB.csv` and
their registration is included in `PPB_REG.csv`.

``` r
ppb <- read_csv(
  file = str_c(lob_dir, "PPB.CSV", sep = "/"),
  col_types = cols(
    .default = col_character(),
    PPB_REP.REP_YEAR = col_integer(),
    PPB_REP.REQUIRED = col_logical(),
    PPB_REP.EXEMPTED = col_logical(),
  )
)
```

    #> # A tibble: 10 x 5
    #>    ppb_id ppb_name                           ppb_phone    ppb_email                        rep_year
    #>    <chr>  <chr>                              <chr>        <chr>                               <int>
    #>  1 105599 WHITE MOUNTAIN APACHE TRIBE        928-338-4346 jimpalmer@wmat.us                    2017
    #>  2 900331 AZ STATE BOARD OF ACCOUNTANCY      602-364-0804 velliott@azaccountancy.gov           2017
    #>  3 106574 VALLE DEL SOL                      602-258-6797 kurts@valledelsol.com                2017
    #>  4 105613 GEORGE A. WILLIS - UPS             949-643-6693 atl1gaw@ups.com                      2017
    #>  5 106994 THE CENTERS FOR HABILITATION (TCH) 480-730-4114 shanaellis@tch-az.com                2017
    #>  6 900053 AZ STATE BOARD OF OPTOMETRY        602-542-8155 margaret.whelan@optometry.az.gov     2017
    #>  7 100099 AZ AUTOMOBILE DEALERS ASSN         602-468-0888 bobbi@aada.com                       2017
    #>  8 100155 AZ ASSOCIATION OF CHIROPRACTIC     602-246-0664 aarons1231@aol.com                   2017
    #>  9 100254 NATURE CONSERVANCY AZ CHAPTER      602-712-0048 clombard@tnc.org                     2017
    #> 10 105292 UNITED PHOENIX FIRE FIGHTERS ASSN  602-277-1500 clevinus@gmail.com                   2017

The `ppb` data frame can be linked to `lob` using the data in `REF.csv`.

``` r
ref <- read_csv(
  file = str_c(lob_dir, "REF.CSV", sep = "/"),
  col_types = cols(
    .default = col_character(),
    DESIGNATED = col_logical(),
    STARTED = col_date("%m/%d/%Y %H:%M %p"),
    TERMINATED = col_date("%m/%d/%Y %H:%M %p"),
    COMPENSATED = col_logical()
  )
)
```

Since each lobbyist in `lob` represents *multiple* principals in `ppb`,
when we join these list together, some rows of `lob` will be duplicated
aside from the unique `ppb_id`. Many of the principals (IDs) listed in
`ref` do not exist in `ppb` and would create useless empty rows when
joined to `lob` (along the `lob_id` in ref). We will filter out these
rows.

``` r
azl <- lob %>%
  # add all the principals of a lobbyist
  left_join(ref, by = "lob_id") %>% 
  # add the names of those principals
  left_join(ppb, by = "ppb_id")
```

``` r
azl %>% 
  arrange(
    lob_lastname,
    desc(rep_year),
    ppb_name
  )
#> # A tibble: 31,028 x 19
#>    lob_id lob_lastname lob_firstname lob_phone lob_addr1 lob_addr2 lob_city lob_state lob_zip
#>    <chr>  <chr>        <chr>         <chr>     <chr>     <chr>     <chr>    <chr>     <chr>  
#>  1 36099… 5THIRTY5     <NA>          480-389-… PO BOX 1… <NA>      PHOENIX  AZ        85064- 
#>  2 36099… 5THIRTY5     <NA>          480-389-… PO BOX 1… <NA>      PHOENIX  AZ        85064- 
#>  3 36099… 5THIRTY5     <NA>          480-389-… PO BOX 1… <NA>      PHOENIX  AZ        85064- 
#>  4 31001… AARONS       BARRY M.      602-315-… 4315 N 1… SUITE 200 PHOENIX  AZ        85014- 
#>  5 31001… AARONS       BARRY M.      602-315-… 4315 N 1… SUITE 200 PHOENIX  AZ        85014- 
#>  6 31001… AARONS       BARRY M.      602-315-… 4315 N 1… SUITE 200 PHOENIX  AZ        85014- 
#>  7 31001… AARONS       BARRY M.      602-315-… 4315 N 1… SUITE 200 PHOENIX  AZ        85014- 
#>  8 31001… AARONS       BARRY M.      602-315-… 4315 N 1… SUITE 200 PHOENIX  AZ        85014- 
#>  9 31001… AARONS       BARRY M.      602-315-… 4315 N 1… SUITE 200 PHOENIX  AZ        85014- 
#> 10 31001… AARONS       BARRY M.      602-315-… 4315 N 1… SUITE 200 PHOENIX  AZ        85014- 
#> # … with 31,018 more rows, and 10 more variables: ref_id <chr>, ppb_id <chr>, designated <lgl>,
#> #   started <date>, terminated <date>, compensated <lgl>, ppb_name <chr>, ppb_phone <chr>,
#> #   ppb_email <chr>, rep_year <int>
```

## Explore

After these various joins, our new data frame contains one row per
client, per lobbyist, per year.

``` r
azl %>% 
  select(
    lob_id,
    lob_lastname,
    ppb_id,
    ppb_name,
    rep_year
  ) %>% 
  sample_frac()
#> # A tibble: 31,028 x 5
#>    lob_id  lob_lastname                   ppb_id ppb_name                                 rep_year
#>    <chr>   <chr>                          <chr>  <chr>                                       <int>
#>  1 3105660 BAIER                          107655 <NA>                                           NA
#>  2 3502155 JUSTICE                        100483 AZ SCHOOL BOARDS ASSOCIATION                 2017
#>  3 3107263 SIMON                          100567 <NA>                                           NA
#>  4 3606841 COOK                           105977 <NA>                                           NA
#>  5 3500603 SEVIGNY                        100362 <NA>                                           NA
#>  6 3606715 BEATTY                         105921 <NA>                                           NA
#>  7 3604427 FLORES                         900036 <NA>                                           NA
#>  8 3602871 HAMILTON CONSULTING, INC       106936 <NA>                                           NA
#>  9 3100743 COUGHLIN                       900164 REGIONAL PUBLIC TRANSPORTATION AUTHORITY     2017
#> 10 3100148 MEYER HENDRICKS BIVENS & MOYES 101232 <NA>                                           NA
#> # … with 31,018 more rows

glimpse(sample_frac(azl))
#> Observations: 31,028
#> Variables: 19
#> $ lob_id        <chr> "3607501", "3100625", "3205830", "3610943", "3500092", "3101512", "3608275…
#> $ lob_lastname  <chr> "RICHINS", "HERSTAM", "SCARAMAZZO", "PADRES", "BROWN", "MILLER", "RANIERI"…
#> $ lob_firstname <chr> "DAVE", "CHRIS", "GARY", "JUAN FRANCISCO", "GREGORY S", "DEAN", "DANIEL", …
#> $ lob_phone     <chr> "602-393-4310", "602-262-0801", "928-606-6817", "520-837-4079", "480-345-0…
#> $ lob_addr1     <chr> "11010 N TATUM BLVD STE D-101", "201 E. WASHINGTON STREET", "518 E ROUTE 6…
#> $ lob_addr2     <chr> NA, "SUITE 1200", NA, NA, "BROWN & HERRICK", NA, NA, "U OF A SOUTH", "SUIT…
#> $ lob_city      <chr> "PHOENIX", "PHOENIX", "WILLIAMS", "TUCSON", "MESA", "PHOENIX", "TUCSON", "…
#> $ lob_state     <chr> "AZ", "AZ", "AZ", "AZ", "AZ", "AZ", "AZ", "AZ", "AZ", "AZ", "AZ", "AZ", "A…
#> $ lob_zip       <chr> "85028-", "85004-", "86046-2704", "85701-", "85274", "85032-", "85713-", "…
#> $ ref_id        <chr> "125940", "118723", "121192", "134401", "106091", "104996", "127813", "107…
#> $ ppb_id        <chr> "105914", "105142", "105610", "900007", "101313", "100863", "106469", "900…
#> $ designated    <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ started       <date> 2009-01-01, 2003-03-13, 2005-01-01, 2016-01-12, 1997-01-01, 1997-01-01, 2…
#> $ terminated    <date> 2013-01-01, 2004-05-26, 2007-04-23, NA, 1997-01-01, 1997-01-01, NA, 2009-…
#> $ compensated   <lgl> FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
#> $ ppb_name      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "A…
#> $ ppb_phone     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "6…
#> $ ppb_email     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "l…
#> $ rep_year      <int> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, 20…
```

### Missing

The *vast* majority of entries are missing the `ppb_name`, as only
*current* Principal names are listed in the `ppb` data frame.

``` r
count(ppb, rep_year)
#> # A tibble: 1 x 2
#>   rep_year     n
#>      <int> <int>
#> 1     2017   151
```

However, the `lob` and `ref` data frames contain lobbyists and
relationships dating back to Nov 22, 1994. For all those lobbyists and
relationships without corresponding names in `ppb`, rows are created
with missing `ppb_*` values.

``` r
glimpse_fun(azl, count_na)
#> # A tibble: 19 x 4
#>    col           type      n         p
#>    <chr>         <chr> <dbl>     <dbl>
#>  1 lob_id        chr       0 0        
#>  2 lob_lastname  chr       1 0.0000322
#>  3 lob_firstname chr    4752 0.153    
#>  4 lob_phone     chr     487 0.0157   
#>  5 lob_addr1     chr      89 0.00287  
#>  6 lob_addr2     chr   24331 0.784    
#>  7 lob_city      chr      73 0.00235  
#>  8 lob_state     chr      74 0.00238  
#>  9 lob_zip       chr     103 0.00332  
#> 10 ref_id        chr     359 0.0116   
#> 11 ppb_id        chr     359 0.0116   
#> 12 designated    lgl     359 0.0116   
#> 13 started       date    359 0.0116   
#> 14 terminated    date   3981 0.128    
#> 15 compensated   lgl    1336 0.0431   
#> 16 ppb_name      chr   28788 0.928    
#> 17 ppb_phone     chr   28793 0.928    
#> 18 ppb_email     chr   29040 0.936    
#> 19 rep_year      int   28788 0.928
```

``` r
azl <- azl %>% flag_na(lob_lastname, ppb_name)
noquote(comma(sum(azl$na_flag)))
#> [1] 28,788
noquote(percent(mean(azl$na_flag)))
#> [1] 92.8%
```

### Duplicates

``` r
azl <- flag_dupes(azl, everything())
sum(azl$dupe_flag)
#> [1] 0
```

### Categorical

``` r
glimpse_fun(azl, n_distinct)
#> # A tibble: 21 x 4
#>    col           type      n         p
#>    <chr>         <chr> <dbl>     <dbl>
#>  1 lob_id        chr   17176 0.554    
#>  2 lob_lastname  chr   10003 0.322    
#>  3 lob_firstname chr    5068 0.163    
#>  4 lob_phone     chr   10379 0.335    
#>  5 lob_addr1     chr    9336 0.301    
#>  6 lob_addr2     chr    1387 0.0447   
#>  7 lob_city      chr     633 0.0204   
#>  8 lob_state     chr      53 0.00171  
#>  9 lob_zip       chr    2200 0.0709   
#> 10 ref_id        chr   30670 0.988    
#> 11 ppb_id        chr    4584 0.148    
#> 12 designated    lgl       3 0.0000967
#> 13 started       date   3925 0.126    
#> 14 terminated    date   3619 0.117    
#> 15 compensated   lgl       3 0.0000967
#> 16 ppb_name      chr     152 0.00490  
#> 17 ppb_phone     chr     147 0.00474  
#> 18 ppb_email     chr     121 0.00390  
#> 19 rep_year      int       2 0.0000645
#> 20 na_flag       lgl       2 0.0000645
#> 21 dupe_flag     lgl       1 0.0000322
```

## Wrangle

### Address

``` r
packageVersion("tidyr")
#> [1] '1.0.0'
azl <- azl %>% 
  # combine street addr
  unite(
    col = lob_addr_full,
    starts_with("lob_addr"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  # normalize combined addr
  mutate(
    lob_addr_norm = normal_address(
      address = lob_addr_full,
      add_abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-lob_addr_full)
```

``` r
select(azl, starts_with("lob_addr")) %>% distinct() %>% sample_frac()
#> # A tibble: 9,914 x 3
#>    lob_addr1                   lob_addr2              lob_addr_norm                                
#>    <chr>                       <chr>                  <chr>                                        
#>  1 PO BOX 53999 STA 9042       <NA>                   PO BOX 53999 STATION 9042                    
#>  2 8601 N SCOTTSDALE RD        SUITE 300              8601 NORTH SCOTTSDALE ROAD SUITE 300         
#>  3 ONE EAST CAMELBACK RD STE … <NA>                   ONE EAST CAMELBACK ROAD SUITE 660            
#>  4 2102 W ENCANTO BLVD, MD 10… <NA>                   2102 WEST ENCANTO BOULEVARD MD 1000          
#>  5 CHILDRENS ACTION ALLIANCE   15 N BULLMOOSE CIR     CHILDRENS ACTION ALLIANCE 15 NORTH BULLMOOSE…
#>  6 1300 W WASHINGTON ST        <NA>                   1300 WEST WASHINGTON STREET                  
#>  7 305 S SECOND AVE            COMMUNITY LEGAL SERVI… 305 SOUTH SECOND AVENUE COMMUNITY LEGAL SERV…
#>  8 100 N. 15TH AVENUE          SUITE 103              100 NORTH 15TH AVENUE SUITE 103              
#>  9 P O BOX 440                 <NA>                   PO BOX 440                                   
#> 10 P.O. BOX 33335              <NA>                   PO BOX 33335                                 
#> # … with 9,904 more rows
```

### ZIP

``` r
azl <- azl %>% 
  mutate(
    lob_zip_norm = normal_zip(
      zip = lob_zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  azl$lob_zip,
  azl$lob_zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage        prop_in n_distinct prop_na n_out n_diff
#>   <chr>          <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 lob_zip        0.402       2200 0.00332 18501   1535
#> 2 lob_zip_norm   0.997       1137 0.00342   107     39
```

### State

``` r
azl <- azl %>% 
  mutate(
    lob_state_norm = normal_state(
      state = lob_state,
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = valid_state
    )
  )
```

``` r
progress_table(
  azl$lob_state,
  azl$lob_state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage          prop_in n_distinct prop_na n_out n_diff
#>   <chr>            <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 lob_state        1.000         53 0.00238     7      7
#> 2 lob_state_norm   1             47 0.00261     0      1
```

### City

``` r
azl <- azl %>% 
  mutate(
    lob_city_norm = normal_city(
      city = lob_city, 
      geo_abbs = usps_city,
      st_abbs = c("AZ", "DC", "ARIZONA"),
      na = c(invalid_city, ""),
      na_rep = TRUE
    )
  )
```

``` r
azl <- azl %>% 
  left_join(
    y = zipcodes,
    by = c(
      "lob_state_norm" = "state",
      "lob_zip_norm" = "zip"
    )
  ) %>% 
  rename(lob_city_match = city) %>% 
  mutate(
    lob_match_abb = is_abbrev(lob_city_norm, lob_city_match),
    lob_match_dist = str_dist(lob_city_norm, lob_city_match),
    lob_city_swap = if_else(
      condition = lob_match_abb | lob_match_dist == 1,
      true = lob_city_match,
      false = lob_city_norm
    )
  )
```

``` r
azl %>%
  filter(lob_city_swap %out% valid_city) %>%
  count(lob_city_swap, lob_city_match, lob_state_norm, sort = TRUE) %>% 
  drop_na() %>% 
  print(n = Inf)
#> # A tibble: 33 x 4
#>    lob_city_swap           lob_city_match  lob_state_norm     n
#>    <chr>                   <chr>           <chr>          <int>
#>  1 SUN LAKES               CHANDLER        AZ               121
#>  2 ORO VALLEY              TUCSON          AZ                80
#>  3 PINETOP LAKESIDE        LAKESIDE        AZ                18
#>  4 SOUTH TUCSON            TUCSON          AZ                 6
#>  5 CORAL GABLES            MIAMI           FL                 4
#>  6 HIGHLAND RANCH          LITTLETON       CO                 4
#>  7 OVERLAND PARK           SHAWNEE MISSION KS                 4
#>  8 ABBOTT PARK             NORTH CHICAGO   IL                 3
#>  9 HIGHLANDS RANCH         LITTLETON       CO                 3
#> 10 NORTH ALMA SCHOOL RD CH CHANDLER        AZ                 3
#> 11 OVERLAND PK             SHAWNEE MISSION KS                 3
#> 12 BANNOCKBURN             DEERFIELD       IL                 2
#> 13 CHANLDER                TEMPE           AZ                 2
#> 14 EDIN                    MINNEAPOLIS     MN                 2
#> 15 GILBERT RD              GILBERT         AZ                 2
#> 16 NEW JERSEY              EAST HANOVER    NJ                 2
#> 17 WACHUCA CITY            HUACHUCA CITY   AZ                 2
#> 18 WEST ATLANTIC CITY      PLEASANTVILLE   NJ                 2
#> 19 BOOMINGTON              MINNEAPOLIS     MN                 1
#> 20 CAMERON PK              SHINGLE SPRINGS CA                 1
#> 21 CORDES LAKE             RIMROCK         AZ                 1
#> 22 GOLD RIVER              RANCHO CORDOVA  CA                 1
#> 23 LAKE LOTAWANA           LEES SUMMIT     MO                 1
#> 24 MERRIAM                 SHAWNEE MISSION KS                 1
#> 25 MOON TOWNSHIP           CORAOPOLIS      PA                 1
#> 26 RANCHO DOMINGUEZ        COMPTON         CA                 1
#> 27 SAINT LOUIS PARK        MINNEAPOLIS     MN                 1
#> 28 SAN FRANSICO            SAN FRANCISCO   CA                 1
#> 29 SAN FRANSISCO           DALY CITY       CA                 1
#> 30 SHELBY TOWNSHIP         UTICA           MI                 1
#> 31 SOUTH CHICAGO HGTS      CHICAGO HEIGHTS IL                 1
#> 32 SUN CITY GRAND          SURPRISE        AZ                 1
#> 33 WEST LAKE HILLS         AUSTIN          TX                 1
```

``` r
many_city <- c(
  valid_city,
  extra_city,
  "ORO VALLEY",
  "SUN LAKES",
  "PINETOP LAKESIDE",
  "CORAL GABLES"
)
```

``` r
progress_table(
  azl$lob_city,
  azl$lob_city_norm,
  compare = many_city
)
#> # A tibble: 2 x 6
#>   stage         prop_in n_distinct prop_na n_out n_diff
#>   <chr>           <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 lob_city        0.986        633 0.00235   435    119
#> 2 lob_city_norm   0.991        611 0.00251   276     89
```

## Conclude

1.  There are 31028 records in the database.
2.  There are 0 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 28788 records missing either the lobbyist or principal
    name.
5.  Consistency in goegraphic data has been improved with
    `campfin::normal_*()`.
6.  The 5-digit `lob_zip_norm` variable has been created with
    `campfin::normal_zip()`.
7.  The 4-digit `rep_year` was taken from the `ppb` data frame.

## Export

``` r
proc_dir <- here("az", "lobbying", "data", "processed")
dir_create(proc_dir)
```

``` r
azl %>% 
  select(
    -lob_city_norm,
    -lob_city_match,
    -lob_match_abb,
    -lob_match_dist
  ) %>%
  rename(
    lob_addr_clean = lob_addr_norm,
    lob_zip_clean = lob_zip_norm,
    lob_state_clean = lob_state_norm,
    lob_city_clean = lob_city_swap
  ) %>% 
  write_csv(
    path = glue("{proc_dir}/az_type_clean.csv"),
    na = ""
  )
```
