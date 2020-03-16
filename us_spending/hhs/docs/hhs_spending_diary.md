Health and Human Services Spending
================
Kiernan Nicholls
2020-03-16 14:48:20

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Download](#download)
  - [Layout](#layout)
  - [Read](#read)
  - [Explore](#explore)
  - [Missing](#missing)
  - [Duplicates](#duplicates)
  - [Amount](#amount)
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
  scales, # format strings
  readxl, # read excel
  knitr, # knit documents
  vroom, # read files fast
  glue, # combine strings
  here, # relative storage
  fs # search storage 
)
```

This document should be run as part of the `us_spending` project, which
lives as a sub-directory of the more general, language-agnostic
[`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning)
GitHub repository.

The `us_spending` project uses the [RStudio
projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects)
feature and should be run as such. The project also uses the dynamic
`here::here()` tool for file paths relative to *your* machine.

``` r
# where does this document knit?
here::here()
#> [1] "/home/kiernan/Code/accountability_datacleaning/us_spending"
```

## Data

The data is obtained from the [USA Spending Award Data
Archive](https://www.usaspending.gov/#/download_center/award_data_archive).

> Welcome to the Award Data Archive, which features major agencies’
> award transaction data for full fiscal years. They’re a great way to
> get a view into broad spending trends and, best of all, the files are
> already prepared — you can access them instantaneously.

Data can be obtained from the archive as annual files for each agency.

## Download

If the zip archives have not been downloaded, we can do so now.

``` r
spend_url <- "https://files.usaspending.gov/award_data_archive/"
hhs_files <- glue("FY{2008:2020}_075_Contracts_Full_20200205.zip")
hhs_urls <- str_c(spend_url, hhs_files)
raw_dir <- dir_create(here("hhs", "data", "raw"))
hhs_paths <- path(raw_dir, hhs_files)
```

We also need to add the records for spending made since this file was
last updated. This information can be found in the “delta” file released
alongside the “full” spending file.

``` r
delta_url <- str_c(spend_url, "FY(All)_075_Contracts_Delta_20200313.zip")
delta_path <- path(raw_dir, basename(delta_url))
```

``` r
if (!all(file_exists(c(hhs_paths, delta_path)))) {
  download.file(hhs_urls, hhs_paths)
  download.file(delta_url, delta_path)
}
```

## Layout

The USA Spending website also provides a comprehensive data dictionary
which covers the many variables in this file.

``` r
dict_file <- file_temp(ext = "xlsx")
download.file(
  url = "https://files.usaspending.gov/docs/Data_Dictionary_Crosswalk.xlsx",
  destfile = dict_file
)
dict <- read_excel(
  path = dict_file, 
  range = "A2:L414",
  na = "N/A",
  .name_repair = make_clean_names
)

hhs_names <- names(read_csv(last(hhs_paths), n_max = 0))
# get cols from hhs data
mean(hhs_names %in% dict$award_element)
#> [1] 0.923913
dict <- dict %>% 
  filter(award_element %in% hhs_names) %>% 
  select(award_element, definition) %>% 
  mutate_at(vars(definition), str_replace_all, "\"", "\'") %>% 
  arrange(match(award_element, hhs_names))

dict %>% 
  head(10) %>% 
  mutate_at(vars(definition), str_trunc, 75) %>% 
  kable()
```

| award\_element                       | definition                                                                |
| :----------------------------------- | :------------------------------------------------------------------------ |
| award\_id\_piid                      | The unique identifier of the specific award being reported.               |
| modification\_number                 | The identifier of an action being reported that indicates the specific s… |
| transaction\_number                  | Tie Breaker for legal, unique transactions that would otherwise have the… |
| parent\_award\_agency\_id            | Identifier used to link agency in FPDS-NG to referenced IDV information.  |
| parent\_award\_agency\_name          | Name of the agency associated with the code in the Referenced IDV Agency… |
| parent\_award\_modification\_number  | When reporting orders under Indefinite Delivery Vehicles (IDV) such as a… |
| federal\_action\_obligation          | Amount of Federal government’s obligation, de-obligation, or liability f… |
| total\_dollars\_obligated            | This is a system generated element providing the sum of all the amounts … |
| base\_and\_exercised\_options\_value | The change (from this transaction only) to the current contract value (i… |
| current\_total\_value\_of\_award     | Total amount obligated to date on an award. For a contract, this amount … |

## Read

This archive file can be directly read as a data frame with
`vroom::vroom()`.

``` r
hhs <- vroom(
  file = hhs_paths,
  delim = ",",
  escape_backslash = FALSE,
  escape_double = FALSE,
  guess_max = 0,
  na = c("", "NA", "NAN", "*"),
  col_types = cols(
    .default = col_character(),
    action_date_fiscal_year = col_integer(),
    action_date = col_date(),
    federal_action_obligation = col_double()
  )
)
```

We need to read the delta file separately because it has a few
additional variables.

``` r
delta <- vroom(
  file = delta_path,
  delim = ",",
  escape_backslash = FALSE,
  escape_double = FALSE,
  guess_max = 0,
  na = c("", "NA", "NAN", "*"),
  col_types = cols(
    .default = col_character(),
    action_date_fiscal_year = col_integer(),
    action_date = col_date(),
    federal_action_obligation = col_double()
  )
)
```

Then the two data frames can be bound together into a single file.

``` r
setdiff(names(delta), names(hhs))
#>  [1] "correction_delete_ind"                       "agency_id"                                  
#>  [3] "government_furnished_property_code"          "government_furnished_property"              
#>  [5] "alaskan_native_corporation_owned_firm"       "native_hawaiian_organization_owned_firm"    
#>  [7] "tribally_owned_firm"                         "receives_financial_assistance"              
#>  [9] "receives_contracts_and_financial_assistance" "foreign_owned"
```

``` r
hhs <- bind_rows(list(full = hhs, delta = delta), .id = "source")
rm(delta)
```

We can count a discrete categorical variable to ensure the file was read
properly. If there was an error reading one of the text files, the
columns will likely shift.

``` r
count(hhs, foreign_funding, sort = TRUE)
#> # A tibble: 4 x 2
#>   foreign_funding      n
#>   <chr>            <int>
#> 1 <NA>            583448
#> 2 X               466935
#> 3 B                 5904
#> 4 A                  155
```

Using the dictionary, we can select and rename only the 19 variables we
want.

``` r
hhs <- hhs %>% 
  select(
    key = contract_transaction_unique_key,
    id = award_id_piid,
    fy = action_date_fiscal_year,
    date = action_date,
    amount = federal_action_obligation,
    # agency_code = awarding_agency_code,
    agency = awarding_agency_name,
    # sub_code = awarding_sub_agency_code,
    sub_agency = awarding_sub_agency_name,
    # office_code = awarding_office_code,
    office = awarding_office_name,
    recipient = recipient_name,
    parent = recipient_parent_name,
    address1 = recipient_address_line_1,
    address2 = recipient_address_line_2,
    city = recipient_city_name,
    state = recipient_state_code,
    zip = recipient_zip_4_code,
    place = primary_place_of_performance_zip_4,
    type = award_type_code,
    desc = award_description,
    correct_delete = correction_delete_ind,
    source,
  )
```

## Explore

``` r
head(hhs)
#> # A tibble: 6 x 20
#>   key   id       fy date        amount agency sub_agency office recipient parent address1 address2
#>   <chr> <chr> <int> <date>       <dbl> <chr>  <chr>      <chr>  <chr>     <chr>  <chr>    <chr>   
#> 1 7529… HHSN…  2008 2008-09-30  1.95e5 DEPAR… NATIONAL … OD OM… TRIANGLE… TRIAN… 505 20T… <NA>    
#> 2 7529… HHSN…  2008 2008-09-30  1.19e3 DEPAR… NATIONAL … OD OM… TRIANGLE… TRIAN… 505 20T… <NA>    
#> 3 7530… HHSM…  2008 2008-09-30  2.98e5 DEPAR… CENTERS F… DEPT … GROUP HE… EMBLE… 441 9TH… <NA>    
#> 4 7530… HHSM…  2008 2008-09-30  1.00e3 DEPAR… CENTERS F… DEPT … QUALITY … VIRGI… 3001 CH… <NA>    
#> 5 7529… HHSN…  2008 2008-09-30  1.09e6 DEPAR… NATIONAL … NIDDK… CSR, INC. CSR  … 2107 WI… <NA>    
#> 6 7555… HHSP…  2008 2008-09-30 -1.86e5 DEPAR… OFFICE OF… DEPT … HEALTHCA… HEALT… 63 MIDD… <NA>    
#> # … with 8 more variables: city <chr>, state <chr>, zip <chr>, place <chr>, type <chr>,
#> #   desc <chr>, correct_delete <chr>, source <chr>
tail(hhs)
#> # A tibble: 6 x 20
#>   key   id       fy date       amount agency sub_agency office recipient parent address1 address2
#>   <chr> <chr> <int> <date>      <dbl> <chr>  <chr>      <chr>  <chr>     <chr>  <chr>    <chr>   
#> 1 7523… 75D3…    NA NA             NA <NA>   <NA>       <NA>   <NA>      <NA>   <NA>     <NA>    
#> 2 7523… 75D3…    NA NA             NA <NA>   <NA>       <NA>   <NA>      <NA>   <NA>     <NA>    
#> 3 7530… 75FC…    NA NA             NA <NA>   <NA>       <NA>   <NA>      <NA>   <NA>     <NA>    
#> 4 7530… 75FC…    NA NA             NA <NA>   <NA>       <NA>   <NA>      <NA>   <NA>     <NA>    
#> 5 7555… HHSP…    NA NA             NA <NA>   <NA>       <NA>   <NA>      <NA>   <NA>     <NA>    
#> 6 7555… HHSP…    NA NA             NA <NA>   <NA>       <NA>   <NA>      <NA>   <NA>     <NA>    
#> # … with 8 more variables: city <chr>, state <chr>, zip <chr>, place <chr>, type <chr>,
#> #   desc <chr>, correct_delete <chr>, source <chr>
glimpse(sample_n(hhs, 20))
#> Observations: 20
#> Variables: 20
#> $ key            <chr> "7555_-NONE-_HHSP23320074107EC_6_-NONE-_0", "7527_7529_HHSI247201600037W_…
#> $ id             <chr> "HHSP23320074107EC", "HHSI247201600037W", "HHSN26300822", "HHSI2392010004…
#> $ fy             <int> 2009, 2016, 2014, 2010, 2020, 2011, 2019, 2019, 2015, 2018, 2020, 2015, 2…
#> $ date           <date> 2009-04-07, 2016-08-04, 2013-12-06, 2010-07-19, 2019-12-17, 2010-11-10, …
#> $ amount         <dbl> 184003.17, 81547.07, 5115.00, 20000.00, -374.00, 0.00, 0.00, 22555.00, 12…
#> $ agency         <chr> "DEPARTMENT OF HEALTH AND HUMAN SERVICES (HHS)", "DEPARTMENT OF HEALTH AN…
#> $ sub_agency     <chr> "OFFICE OF THE ASSISTANT SECRETARY FOR ADMINISTRATION (ASA)", "INDIAN HEA…
#> $ office         <chr> "DEPT OF HHS/OFF AST SEC HLTH EXPT NATL CNTR", "PHOENIX AREA INDIAN HEALT…
#> $ recipient      <chr> "WV HEALTH INFORMATION NETWORK", "NEW TECH SOLUTIONS, INC.", "WOODCOCK WA…
#> $ parent         <chr> "WV HEALTH INFORMATION NETWORK", "NEW TECH SOLUTIONS  INC.", "WOODCOCK WA…
#> $ address1       <chr> "100 DEE DRIVE", "4179 BUSINESS CENTER DR", "2929 ARCH ST 12TH FL", "1095…
#> $ address2       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ city           <chr> "CHARLESTON", "FREMONT", "PHILADELPHIA", "PARK RAPIDS", "TROY", "SALT LAK…
#> $ state          <chr> "WV", "CA", "PA", "MN", "MI", "UT", "AK", "MD", "NC", "CA", "UT", "IL", "…
#> $ zip            <chr> "25311", "945386355", "191042857", "564704580", "480844716", "841129023",…
#> $ place          <chr> "253111600", "860424000", "191042851", "565699612", "480844718", "8410218…
#> $ type           <chr> "D", "C", "C", "B", "C", "D", "C", "A", "B", "C", "C", "C", "A", NA, "C",…
#> $ desc           <chr> "OTHER ADMINISTRATIVE SUPPORT SVCS", "IGF::OT::IGF IT/SERVER EQUIPMENT FO…
#> $ correct_delete <chr> NA, NA, NA, NA, NA, NA, "C", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ source         <chr> "full", "full", "full", "full", "delta", "full", "delta", "full", "full",…
```

## Missing

There are only a handful of records missing one of the key variables we
need to identify a unique spending transaction.

``` r
col_stats(hhs, count_na)
#> # A tibble: 20 x 4
#>    col            class        n         p
#>    <chr>          <chr>    <int>     <dbl>
#>  1 key            <chr>        0 0        
#>  2 id             <chr>        0 0        
#>  3 fy             <int>       93 0.0000880
#>  4 date           <date>      93 0.0000880
#>  5 amount         <dbl>       93 0.0000880
#>  6 agency         <chr>       93 0.0000880
#>  7 sub_agency     <chr>       93 0.0000880
#>  8 office         <chr>       98 0.0000928
#>  9 recipient      <chr>      409 0.000387 
#> 10 parent         <chr>     2296 0.00217  
#> 11 address1       <chr>     1184 0.00112  
#> 12 address2       <chr>  1043507 0.988    
#> 13 city           <chr>      932 0.000882 
#> 14 state          <chr>    12235 0.0116   
#> 15 zip            <chr>     1994 0.00189  
#> 16 place          <chr>    86978 0.0823   
#> 17 type           <chr>    80491 0.0762   
#> 18 desc           <chr>     3624 0.00343  
#> 19 correct_delete <chr>  1041743 0.986    
#> 20 source         <chr>        0 0
```

``` r
hhs <- hhs %>% flag_na(date, agency, amount, recipient)
sum(hhs$na_flag)
#> [1] 409
mean(hhs$na_flag)
#> [1] 0.0003871486
```

## Duplicates

There are a number of records that could potentially be duplicates of
one another. Much of them have an `amount` value of zero, so they might
not be true duplicates. We can flag them nonetheless.

``` r
hhs <- flag_dupes(hhs, -key)
sum(hhs$dupe_flag)
#> [1] 3369
```

``` r
hhs %>% 
  filter(dupe_flag) %>% 
  select(date, agency, amount, recipient)
#> # A tibble: 3,369 x 4
#>    date       agency                                       amount recipient                        
#>    <date>     <chr>                                         <dbl> <chr>                            
#>  1 2008-09-30 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HH…      0 ADVERTISING IDEAS, INC           
#>  2 2008-09-30 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HH…      0 UNIFIRST CORPORATION             
#>  3 2008-09-30 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HH…      0 ADVERTISING IDEAS, INC           
#>  4 2008-09-30 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HH…      0 EN POINTE TECHNOLOGIES INCORPORA…
#>  5 2008-09-30 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HH…      0 MATHESON TRI-GAS, INC            
#>  6 2008-09-30 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HH…      0 INX INC                          
#>  7 2008-09-30 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HH…      0 EN POINTE TECHNOLOGIES INCORPORA…
#>  8 2008-09-30 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HH…      0 INX INC                          
#>  9 2008-09-30 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HH…      0 MATHESON TRI-GAS, INC            
#> 10 2008-09-30 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HH…      0 UNIFIRST CORPORATION             
#> # … with 3,359 more rows
```

![](../plots/dupe_hist-1.png)<!-- -->

## Amount

*Many* spending transactions have a value of zero.

``` r
summary(hhs$amount)
#>       Min.    1st Qu.     Median       Mean    3rd Qu.       Max.       NA's 
#> -309023311          0       5950     252181      31108  690144920         93
mean(hhs$amount <= 0)
#> [1] NA
```

![](../plots/bar_quart_spend-1.png)<!-- -->

## Wrangle

We do not need to normaliza any of the geographic variable much. We can
trim the `zip` variable and that is it.

``` r
sample(hhs$address1, 6)
#> [1] "350 MAIN ST RM 427"                     "6440 S MILLROCK DR STE 175"            
#> [3] "1295 WALT WHITMAN RD"                   "12111 PKLAWN DR"                       
#> [5] "3400 N CHARLES ST W400 WYMAN PARK BLDG" "1400 NORTH GILBERT RD"
progress_table(hhs$state, compare = valid_state)
#> # A tibble: 1 x 6
#>   stage prop_in n_distinct prop_na n_out n_diff
#>   <chr>   <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 state       1         57  0.0116     0      1
hhs <- mutate_at(hhs, vars(zip, place), normal_zip)
progress_table(hhs$zip, compare = valid_zip)
#> # A tibble: 1 x 6
#>   stage prop_in n_distinct prop_na n_out n_diff
#>   <chr>   <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 zip     0.994       9741 0.00189  6607    711
progress_table(hhs$city, compare = c(valid_city, extra_city))
#> # A tibble: 1 x 6
#>   stage prop_in n_distinct  prop_na n_out n_diff
#>   <chr>   <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 city    0.986       5178 0.000882 14856    790
```

## Conclude

1.  There are 1056442 records in the database.
2.  There are 3369 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 409 records missing either recipient or date.
5.  Consistency in goegraphic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
clean_dir <- dir_create(here("hhs", "spending", "data", "clean"))
```

``` r
write_csv(
  x = hhs,
  path = path(clean_dir, "hhs_contracts_clean.csv"),
  na = ""
)
```
