Health and Human Services Spending
================
Kiernan Nicholls
2020-03-20 11:51:09

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
hhs_files <- glue("FY{2008:2020}_075_Assistance_Full_20200313.zip")
hhs_urls <- str_c(spend_url, hhs_files)
raw_dir <- dir_create(here("hhs", "assist", "data", "raw"))
hhs_paths <- path(raw_dir, hhs_files)
```

We also need to add the records for spending made since this file was
last updated. This information can be found in the “delta” file released
alongside the “full” spending file.

``` r
delta_url <- str_c(spend_url, "FY(All)_075_Assistance_Delta_20200313.zip")
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
#> [1] 0.7444444
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

| award\_element                              | definition                                                                |
| :------------------------------------------ | :------------------------------------------------------------------------ |
| award\_id\_fain                             | The Federal Award Identification Number (FAIN) is the unique ID within t… |
| modification\_number                        | The identifier of an action being reported that indicates the specific s… |
| award\_id\_uri                              | Unique Record Identifier. An agency defined identifier that (when provid… |
| sai\_number                                 | A number assigned by state (as opposed to federal) review agencies to th… |
| federal\_action\_obligation                 | Amount of Federal government’s obligation, de-obligation, or liability f… |
| non\_federal\_funding\_amount               | The amount of the award funded by non-Federal source(s), in dollars. Pro… |
| face\_value\_of\_loan                       | The face value of the direct loan or loan guarantee.                      |
| action\_date                                | The date the action being reported was issued / signed by the Government… |
| period\_of\_performance\_start\_date        | The date on which, for the award referred to by the action being reporte… |
| period\_of\_performance\_current\_end\_date | The current date on which, for the award referred to by the action being… |

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
count(hhs, business_types_code, sort = TRUE)
#> # A tibble: 37 x 2
#>    business_types_code      n
#>    <chr>                <int>
#>  1 06                  309562
#>  2 12                  268970
#>  3 00                  254220
#>  4 20                  210730
#>  5 H                   112083
#>  6 X                   103252
#>  7 O                    91433
#>  8 M                    84469
#>  9 11                   78124
#> 10 A                    70395
#> # … with 27 more rows
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
#> [1] "correction_delete_ind"
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
    recipient_parent_name
  )
)
```

``` r
hhs <- hhs %>% 
  select(
    key = assistance_transaction_unique_key,
    id = award_id_fain,
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
    zip = recipient_zip_code,
    place = primary_place_of_performance_zip_4,
    type = assistance_type_code,
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
ex_key <- "7505_ESREP100003_ESREP100003-3693290749_93.089_04"
hhs %>% 
  filter(key == ex_key) %>% 
  select(id, date, amount, agency, recipient, correction, modified, source)
#> # A tibble: 2 x 8
#>   id      date       amount agency              recipient     correction modified            source
#>   <chr>   <date>      <dbl> <chr>               <chr>         <chr>      <dttm>              <chr> 
#> 1 ESREP1… 2019-10-15      0 DEPARTMENT OF HEAL… LOS ANGELES,… <NA>       2020-02-20 16:25:54 full  
#> 2 ESREP1… 2019-10-15      0 DEPARTMENT OF HEAL… LOS ANGELES,… <NA>       2020-02-20 16:25:54 delta
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
#> [1] -30816
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
#> 1 7500… DEFC…   2009 2009-09-15  -79919 DEPAR… DEPARTMEN… <NA>   UNIVERSI… <NA>   <NA>     <NA>    
#> 2 7500… DEFC…   2009 2009-08-03 1593000 DEPAR… DEPARTMEN… <NA>   UNIVERSI… <NA>   <NA>     <NA>    
#> 3 7500… DEFC…   2009 2009-02-13   42000 DEPAR… DEPARTMEN… <NA>   UNIVERSI… <NA>   <NA>     <NA>    
#> 4 7500… DEFG…   2011 2011-05-17   -2605 DEPAR… DEPARTMEN… <NA>   FLORIDA … BOARD… 11200 S… SPONSOR…
#> 5 7500… DEFG…   2009 2009-08-03  229356 DEPAR… DEPARTMEN… <NA>   LELAND S… <NA>   <NA>     <NA>    
#> 6 7500… DEFG…   2009 2009-06-26  300000 DEPAR… DEPARTMEN… <NA>   UNIVERSI… <NA>   <NA>     <NA>    
#> # … with 9 more variables: city <chr>, state <chr>, zip <chr>, place <chr>, type <chr>,
#> #   desc <chr>, correction <chr>, modified <dttm>, source <chr>
tail(hhs)
#> # A tibble: 6 x 21
#>   key   id    fiscal date       amount agency sub_agency office recipient parent address1 address2
#>   <chr> <chr>  <int> <date>      <dbl> <chr>  <chr>      <chr>  <chr>     <chr>  <chr>    <chr>   
#> 1 7590… KPG0…   2020 2019-10-02      0 DEPAR… ADMINISTR… ACF O… PRAIRIE … PRAIR… 16281 Q… <NA>    
#> 2 7590… KPG0…   2019 2019-09-27 451683 DEPAR… ADMINISTR… ACF O… PRAIRIE … PRAIR… 16281 Q… <NA>    
#> 3 7590… KPG0…   2019 2019-09-27 537114 DEPAR… ADMINISTR… ACF O… PONCA TR… PONCA… 20 WHIT… <NA>    
#> 4 7590… KPG0…   2020 2019-10-02      0 DEPAR… ADMINISTR… ACF O… PONCA TR… PONCA… 20 WHIT… <NA>    
#> 5 7590… KPG0…   2020 2019-10-31 632017 DEPAR… ADMINISTR… ACF O… RED LAKE… RED L… 24200 C… <NA>    
#> 6 7590… KPG0…   2020 2019-12-18  96021 DEPAR… ADMINISTR… ACF O… KEWEENAW… KEWEE… 16429 B… <NA>    
#> # … with 9 more variables: city <chr>, state <chr>, zip <chr>, place <chr>, type <chr>,
#> #   desc <chr>, correction <chr>, modified <dttm>, source <chr>
glimpse(sample_n(hhs, 20))
#> Observations: 20
#> Variables: 21
#> $ key        <chr> "7523_NU59EH000507_NU59EH000507-288343953_93.070_01", "7577_2001HIPAVA_2001HI…
#> $ id         <chr> "NU59EH000507", "2001HIPAVA", "R01AI090818", "K22AI093789", NA, "U65PS002074"…
#> $ fiscal     <int> 2019, 2020, 2011, 2011, 2010, 2009, 2009, 2010, 2009, 2011, 2014, 2008, 2019,…
#> $ date       <date> 2018-11-13, 2019-12-06, 2011-06-23, 2011-08-24, 2010-03-31, 2009-09-03, 2009…
#> $ amount     <dbl> 0, 7779, 1019120, 162000, 530441, 152655, 785719, 136898, 434634, 465763, 157…
#> $ agency     <chr> "DEPARTMENT OF HEALTH AND HUMAN SERVICES (HHS)", "DEPARTMENT OF HEALTH AND HU…
#> $ sub_agency <chr> "CENTERS FOR DISEASE CONTROL AND PREVENTION", "ADMINISTRATION FOR COMMUNITY L…
#> $ office     <chr> "CDC OFFICE OF FINANCIAL RESOURCES", "ACL CENTER FOR MANAGEMENT AND BUDGET/OF…
#> $ recipient  <chr> "INDIANA STATE DEPARTMENT OF HEALTH", "HAWAII DISABILITY RIGHTS CENTER", "UNI…
#> $ parent     <chr> "INDIANA, STATE OF", NA, "UNIVERSITY OF NOTRE DAME DU LAC", NA, NA, NA, NA, "…
#> $ address1   <chr> "2 NORTH MERIDIAN STREET FLOOR 1ST", "1132 BISHOP ST STE 2102", "801 GRACE HA…
#> $ address2   <chr> "-DUP2", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ city       <chr> "INDIANAPOLIS", "HONOLULU", "NOTRE DAME", "SEATTLE", NA, "LINCOLNWOOD", "MONT…
#> $ state      <chr> "IN", "HI", "IN", "WA", "ID", "IL", "CO", "OH", "NC", "NY", "OK", "SD", "VA",…
#> $ zip        <chr> "46204", "96813", "46556", "98109", NA, "60712", "81144", "45221", "27708", "…
#> $ place      <chr> NA, NA, "46556", "981091024", NA, "0", "0", "45220", "27705", NA, "743446317"…
#> $ type       <chr> "05", "03", "04", "04", "06", "05", "04", "05", "04", "04", "02", "06", "03",…
#> $ desc       <chr> "INDIANA COMPREHENSIVE ASTHMA CONTROL THROUGH EVIDENCE-BASED STRATEGIES AND P…
#> $ correction <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
#> $ modified   <dttm> 2019-10-18 16:03:58, 2020-01-06 17:37:23, 2011-07-05 00:00:00, 2012-08-16 00…
#> $ source     <chr> "full", "full", "full", "full", "full", "full", "full", "full", "full", "full…
```

## Missing

There are barely any key variables missing values.

``` r
col_stats(hhs, count_na)
#> # A tibble: 21 x 4
#>    col        class        n          p
#>    <chr>      <chr>    <int>      <dbl>
#>  1 key        <chr>        0 0         
#>  2 id         <chr>   125936 0.0695    
#>  3 fiscal     <int>        0 0         
#>  4 date       <date>       0 0         
#>  5 amount     <dbl>        3 0.00000165
#>  6 agency     <chr>        0 0         
#>  7 sub_agency <chr>        0 0         
#>  8 office     <chr>  1511811 0.834     
#>  9 recipient  <chr>        0 0         
#> 10 parent     <chr>   573321 0.316     
#> 11 address1   <chr>   129077 0.0712    
#> 12 address2   <chr>  1753961 0.967     
#> 13 city       <chr>   140234 0.0773    
#> 14 state      <chr>    20873 0.0115    
#> 15 zip        <chr>   164299 0.0906    
#> 16 place      <chr>   513296 0.283     
#> 17 type       <chr>        0 0         
#> 18 desc       <chr>   101177 0.0558    
#> 19 correction <chr>  1813115 1         
#> 20 modified   <dttm>       0 0         
#> 21 source     <chr>        0 0
```

## Duplicates

There are a number of records that could potentially be duplicates of
one another.

``` r
hhs <- flag_dupes(hhs, -key)
sum(hhs$dupe_flag)
#> [1] 10422
percent(mean(hhs$dupe_flag), 0.01)
#> [1] "0.57%"
```

These duplicate values are found in the full data, not just changed
delta files.

``` r
hhs %>% 
  filter(dupe_flag) %>% 
  select(date, agency, amount, recipient, source)
#> # A tibble: 10,422 x 5
#>    date       agency                               amount recipient                          source
#>    <date>     <chr>                                 <dbl> <chr>                              <chr> 
#>  1 2015-09-22 DEPARTMENT OF HEALTH AND HUMAN SER…   25000 WORLD HEALTH ORGANIZATION          full  
#>  2 2015-09-22 DEPARTMENT OF HEALTH AND HUMAN SER…   25000 WORLD HEALTH ORGANIZATION          full  
#>  3 2012-09-25 DEPARTMENT OF HEALTH AND HUMAN SER… -734199 VERMONT DEPARTMENT OF MENTAL HEAL… full  
#>  4 2012-09-25 DEPARTMENT OF HEALTH AND HUMAN SER… -734199 VERMONT DEPARTMENT OF MENTAL HEAL… full  
#>  5 2012-09-26 DEPARTMENT OF HEALTH AND HUMAN SER…  734199 VERMONT AGENCY OF HUMAN SERVICES   full  
#>  6 2012-09-26 DEPARTMENT OF HEALTH AND HUMAN SER…  734199 VERMONT AGENCY OF HUMAN SERVICES   full  
#>  7 2013-11-25 DEPARTMENT OF HEALTH AND HUMAN SER… -999837 NH ST DIV OF MENTAL HEALTH/DEV SV… full  
#>  8 2013-11-27 DEPARTMENT OF HEALTH AND HUMAN SER…  999837 NH ST DEPARTMENT OF HEALTH & HUMA… full  
#>  9 2013-11-25 DEPARTMENT OF HEALTH AND HUMAN SER… -999837 NH ST DIV OF MENTAL HEALTH/DEV SV… full  
#> 10 2013-11-27 DEPARTMENT OF HEALTH AND HUMAN SER…  999837 NH ST DEPARTMENT OF HEALTH & HUMA… full  
#> # … with 10,412 more rows
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
#>       Min.    1st Qu.     Median       Mean    3rd Qu.       Max.       NA's 
#> -6.476e+09  2.084e+04  1.906e+05  6.391e+06  4.533e+05  1.953e+10          3
mean(hhs$amount <= 0, na.rm = TRUE)
#> [1] 0.1739065
```

We’ll add a calendar `year` variable in addition to the `fiscal` year
variable.

``` r
hhs <- mutate(hhs, year = year(date))
mean(hhs$year == hhs$fiscal)
#> [1] 0.8503118
```

Here we can see the annual spending patterns of HHS.

![](../plots/bar_quart_spend-1.png)<!-- -->

## Wrangle

We do not need to normaliza any of the geographic variable much. We can
trim the `zip` variable and that is it.

``` r
sample(hhs$address1, 6)
#> [1] "2301 S 3RD ST"                  "440 WEST FRANKLIN ST, CB #1350"
#> [3] "4755 KINGSWAY DR STE 318"       "1855 FOLSOM ST STE 425"        
#> [5] "3181 SW SAM JACKSON PARK RD"    "7703 FLOYD CURL DR"
hhs <- mutate_at(hhs, vars(zip, place), stringr::str_sub, end = 5)
bind_rows(
  progress_table(hhs$state, compare = valid_state),
  progress_table(hhs$zip, compare = valid_zip),
  progress_table(hhs$city, compare = c(valid_city, extra_city))
)
#> # A tibble: 3 x 6
#>   stage prop_in n_distinct prop_na n_out n_diff
#>   <chr>   <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 state   0.998         63  0.0115  3271      4
#> 2 zip     0.999       9465  0.0906  1349     82
#> 3 city    0.973       5121  0.0773 44578    787
```

## Export

1.  There are 1,813,115 records in the database.
2.  There are 10,422 duplicate records in the database.
3.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

Now we need to add the additional 51 variables back on to the data.

``` r
pre_rows <- nrow(hhs) # 1037410
hhs <- left_join(hhs, other_vars)
nrow(hhs) == pre_rows
#> [1] TRUE
```

``` r
clean_dir <- dir_create(here("hhs", "assist", "data", "clean"))
clean_path <- path(clean_dir, "hhs_assist_clean.csv")
```

``` r
write_csv(hhs, clean_path, na = "")
file_size(clean_path)
#> 1.6G
guess_encoding(clean_path)
#> # A tibble: 3 x 2
#>   encoding   confidence
#>   <chr>           <dbl>
#> 1 UTF-8            1   
#> 2 ISO-8859-1       0.49
#> 3 ISO-8859-2       0.22
```
