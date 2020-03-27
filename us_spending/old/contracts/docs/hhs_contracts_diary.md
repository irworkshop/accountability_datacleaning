Health and Human Services Spending
================
Kiernan Nicholls
2020-03-19 13:51:45

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Download](#download)
  - [Layout](#layout)
  - [Read](#read)
  - [Delta](#delta)
  - [Explore](#explore)
  - [Missing](#missing)
  - [Duplicates](#duplicates)
  - [Amount](#amount)
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
  gluedown, # print markdown
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
    federal_action_obligation = col_double(),
    last_modified_date = col_datetime()
  )
)
```

We can count a discrete categorical variable to ensure the file was read
properly. If there was an error reading one of the text files, the
columns will likely shift.

``` r
count(hhs, foreign_funding, sort = TRUE)
#> # A tibble: 4 x 2
#>   foreign_funding      n
#>   <chr>            <int>
#> 1 <NA>            583355
#> 2 X               439958
#> 3 B                 5484
#> 4 A                  149
```

## Delta

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
    federal_action_obligation = col_double(),
    last_modified_date = col_datetime()
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

Using the dictionary above, we can rename some of the most important
variables and put them in a new data frame for exploration. Then we can
add back the other couple hundred variables after exploration.

First, we want to `coalesce()` some variables which contain different
kinds of the same variable.

``` r
hhs <- mutate(
  .data = hhs,
  recipient = coalesce(
    recipient_name, 
    recipient_parent_name, 
    recipient_doing_business_as_name
  )
)
```

``` r
hhs <- hhs %>% 
  select(
    key = contract_transaction_unique_key,
    id = award_id_piid,
    fiscal = action_date_fiscal_year,
    date = action_date,
    amount = federal_action_obligation,
    agency = awarding_agency_name,
    sub_agency = awarding_sub_agency_name,
    office = awarding_office_name,
    recipient,
    parent = recipient_parent_name,
    address1 = recipient_address_line_1,
    address2 = recipient_address_line_2,
    city = recipient_city_name,
    state = recipient_state_code,
    zip = recipient_zip_4_code,
    place = primary_place_of_performance_zip_4,
    type = award_type_code,
    desc = award_description,
    correction = correction_delete_ind,
    modified = last_modified_date,
    source,
    everything()
  )
```

Now we can use the `key`, `correction`, and `modified`, variables to
update the older records with the delta file.

Here we can see how one record is included in our database three times,
finally being months later.

``` r
ex_key <- "7523_7523_75D30120F07253_0_75D30120A04957_0"
hhs %>% 
  filter(key == ex_key) %>% 
  select(id, date, amount, agency, recipient, correction, modified, source)
#> # A tibble: 3 x 8
#>   id       date       amount agency            recipient      correction modified            source
#>   <chr>    <date>      <dbl> <chr>             <chr>          <chr>      <dttm>              <chr> 
#> 1 75D3012… 2020-01-16 293742 DEPARTMENT OF HE… BIOSEARCH TEC… <NA>       2020-01-16 16:31:14 full  
#> 2 75D3012… 2020-01-16 293742 DEPARTMENT OF HE… BIOSEARCH TEC… <NA>       2020-01-16 16:31:14 delta 
#> 3 75D3012… NA             NA <NA>              <NA>           D          2020-03-13 00:00:00 delta
```

We can `group_by()` the unique `key` and keep only the most recent,
non-deleted version of each transaction.

``` r
old_rows <- nrow(hhs)
hhs <- hhs %>% 
  group_by(key) %>% 
  arrange(desc(modified)) %>% 
  slice(1) %>% 
  filter(correction != "D" | is.na(correction)) %>% 
  ungroup()
nrow(hhs) - old_rows # row diff
#> [1] -19032
```

Now we can split the key variables into a new data frame for processing
of the clean transactions.

``` r
last_col <- which(names(hhs) == "source")
other_vars <- select(hhs, key, last_col:ncol(hhs))
hhs <- select(hhs, 1:last_col)
```

## Explore

``` r
head(hhs)
#> # A tibble: 6 x 21
#>   key   id    fiscal date        amount agency sub_agency office recipient parent address1 address2
#>   <chr> <chr>  <int> <date>       <dbl> <chr>  <chr>      <chr>  <chr>     <chr>  <chr>    <chr>   
#> 1 1615… HHSM…   2008 2008-02-25  7.59e4 DEPAR… CENTERS F… DEPT … TOTAL SO… TOTAL… 12179 B… SUITE 1…
#> 2 2001… 0023…   2010 2010-05-27  0.     DEPAR… OFFICE OF… DEPT … STG INTE… STG I… 4900 SE… <NA>    
#> 3 2001… 0023…   2010 2010-06-28 -2.11e5 DEPAR… OFFICE OF… DEPT … STG INTE… STG I… 4900 SE… <NA>    
#> 4 2050… HHSM…   2010 2010-09-30  3.30e6 DEPAR… CENTERS F… DEPT … THE MITR… THE M… 7515 CO… <NA>    
#> 5 2050… HHSM…   2011 2011-09-15  3.33e6 DEPAR… CENTERS F… DEPT … THE MITR… THE M… 7515 CO… <NA>    
#> 6 2050… HHSM…   2012 2012-02-03  0.     DEPAR… CENTERS F… DEPT … THE MITR… THE M… 7515 CO… <NA>    
#> # … with 9 more variables: city <chr>, state <chr>, zip <chr>, place <chr>, type <chr>,
#> #   desc <chr>, correction <chr>, modified <dttm>, source <chr>
tail(hhs)
#> # A tibble: 6 x 21
#>   key   id    fiscal date       amount agency sub_agency office recipient parent address1 address2
#>   <chr> <chr>  <int> <date>      <dbl> <chr>  <chr>      <chr>  <chr>     <chr>  <chr>    <chr>   
#> 1 9100… EDOS…   2015 2015-05-13      0 DEPAR… OFFICE OF… DEPT … NEW EDIT… NEW E… 6858 OL… <NA>    
#> 2 9100… EDOS…   2015 2015-05-13      0 DEPAR… OFFICE OF… DEPT … HEITECH … HEITE… 8400 CO… <NA>    
#> 3 9100… 0001    2015 2015-05-29 384600 DEPAR… OFFICE OF… DEPT … RESEARCH… RESEA… 3040 CO… <NA>    
#> 4 9100… 0001    2015 2015-07-10  90107 DEPAR… OFFICE OF… DEPT … RESEARCH… RESEA… 3040 CO… <NA>    
#> 5 9100… 0001    2015 2015-05-13      0 DEPAR… OFFICE OF… DEPT … RESEARCH… RESEA… 3040 CO… <NA>    
#> 6 9100… EDOS…   2015 2015-05-13      0 DEPAR… OFFICE OF… DEPT … INSTITUT… INSTI… 323 HAR… <NA>    
#> # … with 9 more variables: city <chr>, state <chr>, zip <chr>, place <chr>, type <chr>,
#> #   desc <chr>, correction <chr>, modified <dttm>, source <chr>
glimpse(sample_n(hhs, 20))
#> Observations: 20
#> Variables: 21
#> $ key        <chr> "7523_7523_HHSD2002004073230020_2_HHSD200200407323I_0", "7529_-NONE-_HHSN2632…
#> $ id         <chr> "HHSD2002004073230020", "HHSN263200600063606B", "HHSN272201600299U", "HHSN268…
#> $ fiscal     <int> 2015, 2016, 2016, 2009, 2013, 2013, 2011, 2016, 2015, 2010, 2011, 2015, 2016,…
#> $ date       <date> 2014-10-07, 2016-09-12, 2016-08-02, 2009-09-25, 2013-07-31, 2013-08-30, 2011…
#> $ amount     <dbl> -403.00, 0.00, 49382.00, -0.80, -141.34, 300.00, 4613.50, -40483.61, 30078.84…
#> $ agency     <chr> "DEPARTMENT OF HEALTH AND HUMAN SERVICES (HHS)", "DEPARTMENT OF HEALTH AND HU…
#> $ sub_agency <chr> "CENTERS FOR DISEASE CONTROL AND PREVENTION", "NATIONAL INSTITUTES OF HEALTH"…
#> $ office     <chr> "DEPT OF HHS/CENTERS FOR DISEASE CONTROL", "NATIONAL INSTITUTES OF HEALTH OLA…
#> $ recipient  <chr> "DANYA INTERNATIONAL INC.", "SPARKS PERSONNEL SERVICES", "PANASONIC HEALTHCAR…
#> $ parent     <chr> "DANYA INTERNATIONAL INC.", "SPARKS PERSONNEL SERVICES INC", "PANASONIC HEALT…
#> $ address1   <chr> "8737 COLESVILLE RD STE 1100", "700 KING FARM BLVD # 100", "1300 N MICHAEL DR…
#> $ address2   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
#> $ city       <chr> "SILVER SPRING", "ROCKVILLE", "WOOD DALE", "SAN DIEGO", "GAITHERSBURG", "ALBU…
#> $ state      <chr> "MD", "MD", "IL", "CA", "MD", "NM", "VA", "MD", "AZ", "CA", "CA", "AZ", "VA",…
#> $ zip        <chr> "209103928", "208505747", "601911082", "92121", "20877", "871094306", "201097…
#> $ place      <chr> "303292020", NA, "601911082", "921211975", "208920001", "874200160", "2010973…
#> $ type       <chr> "C", NA, "C", "D", "C", "C", "B", "D", "B", "B", "B", NA, "C", "B", "B", NA, …
#> $ desc       <chr> "MOD", "OFFICE SUPPORT/TEMPORARY HELP", "CO2 INCUBATORS&ACESSORIES", "FINAL_C…
#> $ correction <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
#> $ modified   <dttm> 2018-09-28 12:09:54, 2016-09-14 09:10:41, 2016-08-03 10:14:41, 2016-02-16 00…
#> $ source     <chr> "full", "full", "full", "full", "full", "full", "full", "full", "full", "full…
```

## Missing

There are only a handful of records missing one of the key variables we
need to identify a unique spending transaction.

``` r
col_stats(hhs, count_na)
#> # A tibble: 21 x 4
#>    col        class        n          p
#>    <chr>      <chr>    <int>      <dbl>
#>  1 key        <chr>        0 0         
#>  2 id         <chr>        0 0         
#>  3 fiscal     <int>        0 0         
#>  4 date       <date>       0 0         
#>  5 amount     <dbl>        0 0         
#>  6 agency     <chr>        0 0         
#>  7 sub_agency <chr>        0 0         
#>  8 office     <chr>        5 0.00000482
#>  9 recipient  <chr>       39 0.0000376 
#> 10 parent     <chr>     2171 0.00209   
#> 11 address1   <chr>     1089 0.00105   
#> 12 address2   <chr>  1024503 0.988     
#> 13 city       <chr>      837 0.000807  
#> 14 state      <chr>    12068 0.0116    
#> 15 zip        <chr>     1898 0.00183   
#> 16 place      <chr>    86016 0.0829    
#> 17 type       <chr>    79551 0.0767    
#> 18 desc       <chr>     3529 0.00340   
#> 19 correction <chr>  1031185 0.994     
#> 20 modified   <dttm>       0 0         
#> 21 source     <chr>        0 0
```

``` r
hhs <- hhs %>% flag_na(date, agency, amount, recipient)
sum(hhs$na_flag)
#> [1] 39
mean(hhs$na_flag)
#> [1] 3.759362e-05
```

Only the recipient name is missing for these few values.

``` r
hhs %>% 
  filter(na_flag) %>% 
  select(date, agency, amount, recipient, parent) %>% 
  sample_frac()
#> # A tibble: 39 x 5
#>    date       agency                                         amount recipient parent
#>    <date>     <chr>                                           <dbl> <chr>     <chr> 
#>  1 2008-04-03 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HHS)   -110  <NA>      <NA>  
#>  2 2008-04-25 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HHS)  -1326  <NA>      <NA>  
#>  3 2011-09-28 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HHS) -25753. <NA>      <NA>  
#>  4 2008-04-07 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HHS)  -3000  <NA>      <NA>  
#>  5 2008-04-03 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HHS)  -2500  <NA>      <NA>  
#>  6 2010-04-23 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HHS)      0  <NA>      <NA>  
#>  7 2015-07-30 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HHS)   -144  <NA>      <NA>  
#>  8 2012-08-24 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HHS)  10176. <NA>      <NA>  
#>  9 2013-09-09 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HHS)      0  <NA>      <NA>  
#> 10 2008-05-02 DEPARTMENT OF HEALTH AND HUMAN SERVICES (HHS)  -6684. <NA>      <NA>  
#> # … with 29 more rows
```

## Duplicates

There are a number of records that could potentially be duplicates of
one another. Much of them have an `amount` value of zero, so they might
not be true duplicates. We can flag them nonetheless.

``` r
hhs <- flag_dupes(hhs, -key)
sum(hhs$dupe_flag)
#> [1] 2269
```

``` r
hhs %>% 
  filter(dupe_flag) %>% 
  select(date, agency, amount, recipient)
#> # A tibble: 2,269 x 4
#>    date       agency                            amount recipient                                   
#>    <date>     <chr>                              <dbl> <chr>                                       
#>  1 2008-08-12 DEPARTMENT OF HEALTH AND HUMAN S…  65000 SIEMENS HEALTHCARE DIAGNOSTICS INC          
#>  2 2008-08-12 DEPARTMENT OF HEALTH AND HUMAN S…  65000 SIEMENS HEALTHCARE DIAGNOSTICS INC          
#>  3 2010-03-19 DEPARTMENT OF HEALTH AND HUMAN S… 100000 JOINT COMMISSION ON ACCREDITATION OF HEALTH…
#>  4 2010-03-19 DEPARTMENT OF HEALTH AND HUMAN S… 100000 JOINT COMMISSION ON ACCREDITATION OF HEALTH…
#>  5 2008-07-28 DEPARTMENT OF HEALTH AND HUMAN S…      0 DELMARVA FOUNDATION FOR MEDICAL CARE INCORP…
#>  6 2010-06-17 DEPARTMENT OF HEALTH AND HUMAN S…      0 HEALTHCARE MANAGEMENT SOLUTIONS, L.L.C.     
#>  7 2010-06-17 DEPARTMENT OF HEALTH AND HUMAN S…      0 HEALTHCARE MANAGEMENT SOLUTIONS, L.L.C.     
#>  8 2008-12-24 DEPARTMENT OF HEALTH AND HUMAN S…      0 MATHEMATICA POLICY RESEARCH INCORPORATED    
#>  9 2008-12-24 DEPARTMENT OF HEALTH AND HUMAN S…      0 MATHEMATICA POLICY RESEARCH INCORPORATED    
#> 10 2012-01-17 DEPARTMENT OF HEALTH AND HUMAN S…      0 CANGENE CORPORATION                         
#> # … with 2,259 more rows
```

![](../plots/dupe_hist-1.png)<!-- -->

## Amount

*Many* spending transactions have an `amount` value of zero. The
`amount` variable being used here is the federal action obligated for
that transaction.

``` r
md_quote(dict$definition[dict$award_element == "federal_action_obligation"])
```

> Amount of Federal government’s obligation, de-obligation, or liability
> for an award transaction.

``` r
summary(hhs$amount)
#>       Min.    1st Qu.     Median       Mean    3rd Qu.       Max. 
#> -309023311          0       5953     252893      31046  690144920
mean(hhs$amount <= 0)
#> [1] 0.3565668
```

We’ll add a calendar `year` variable in addition to the `fiscal` year
variable.

``` r
hhs <- mutate(hhs, year = year(date))
mean(hhs$year == hhs$fiscal)
#> [1] 0.8216867
```

Here we can see the annual spending patterns of HHS.

![](../plots/bar_quart_spend-1.png)<!-- -->

## Wrangle

We do not need to normaliza any of the geographic variable much. We can
trim the `zip` variable and that is it.

``` r
sample(hhs$address1, 6)
#> [1] "100 COLUMBIA STE, 200"        "2100 WASHINGTON BLVD STE 100" "11811 WILLOWS RD NE"         
#> [4] "5 PILGRIM PARK RD STE 5"      "26 MARKET ST"                 "605 N 5600 W"
hhs <- mutate_at(hhs, vars(zip, place), stringr::str_sub, end = 5)
bind_rows(
  progress_table(hhs$state, compare = valid_state),
  progress_table(hhs$zip, compare = valid_zip),
  progress_table(hhs$city, compare = c(valid_city, extra_city))
)
#> # A tibble: 3 x 6
#>   stage prop_in n_distinct  prop_na n_out n_diff
#>   <chr>   <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 state   1             57 0.0116       0      1
#> 2 zip     0.992      10174 0.00183   7846   1273
#> 3 city    0.986       5178 0.000807 14751    790
```

## Export

1.  There are 1,037,410 records in the database.
2.  There are 2,269 duplicate records in the database.
3.  There are 39 records missing either recipient or date.
4.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

Now we need to add the additional 245 variables back on to the data.

``` r
pre_rows <- nrow(hhs) # 1037410
hhs <- left_join(hhs, other_vars)
nrow(hhs) == pre_rows
#> [1] TRUE
```

``` r
clean_dir <- dir_create(here("hhs", "data", "clean"))
clean_path <- path(clean_dir, "hhs_contracts_clean.csv")
```

``` r
write_csv(hhs, clean_path, na = "")
file_size(clean_path)
#> 1.83G
guess_encoding(clean_path)
#> # A tibble: 1 x 2
#>   encoding confidence
#>   <chr>         <dbl>
#> 1 ASCII             1
```
