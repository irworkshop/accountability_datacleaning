Vermont Contracts
================
Kiernan Nicholls
2020-06-10 12:03:09

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Read](#read)
  - [Explore](#explore)
  - [State](#state)
  - [City](#city)
  - [Conclude](#conclude)
  - [Export](#export)
  - [Upload](#upload)
  - [Dictionary](#dictionary)

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
  gluedown, # printing markdown
  magrittr, # pipe operators
  janitor, # clean data frames
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  rvest, # html scraping
  glue, # combine strings
  here, # relative paths
  httr, # http requests
  fs # local storage 
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

Contracts data can be obtained from the [Vermont Department of
Finance](http://finance.vermont.gov/), hosted on the state [Open Data
portal](https://data.vermont.gov/) under the title “Vermont Vendor
Payments” in the finance category. The data file was originally uploaded
on October 13, 2016 and was last updated May 15, 2020.

> The payments shown here are exclusive of direct payments to state
> employees for salaries, benefits, and, prior to May 2013, employee
> reimbursable expenses. The payments are also exclusive of any payments
> deemed confidential by state and/or federal statutes and rules, or the
> confidential nature of the recipients of certain payments, like direct
> program benefit payments. (Approximately 1% of all non-employee
> payments are excluded under these guidelines.)
> 
> Payments are made through the VISION statewide financial system.
> Agencies and departments are responsible for entering their
> transactions into VISION. While VISION is the state’s principal
> financial system, it is not the sole financial system in use by the
> state.
> 
> This data is not intended to be legal advice nor is it designed or
> intended to be relied upon as authoritative financial, investment, or
> professional advice. No entity affiliated with, employed by, or
> constituting part of the state of Vermont warrants, endorses, assures
> the accuracy of, or accepts liability for the content of any
> information on this site.

## Read

The data file can be read directly from the portal with
`vroom::vroom()`.

``` r
vtc <- vroom(
  file = "https://data.vermont.gov/api/views/786x-sbp3/rows.tsv",
  .name_repair = make_clean_names,
  delim = "\t",
  col_types = cols(
    .default = col_character(),
    `Quarter Ending` = col_date_usa(),
    `Amount` = col_number()
  )
)
```

## Explore

There are 1,680,169 rows of 14 columns.

``` r
glimpse(vtc)
#> Rows: 1,680,169
#> Columns: 14
#> $ quarter_ending      <date> 2009-09-30, 2009-09-30, 2009-09-30, 2009-09-30, 2009-09-30, 2009-09…
#> $ department          <chr> "Environmental Conservation", "Environmental Conservation", "Vermont…
#> $ unit_no             <chr> "06140", "06140", "03300", "03300", "03480", "03480", "02140", "0220…
#> $ vendor_number       <chr> "0000276016", "0000276016", "0000284121", "0000284121", "0000207719"…
#> $ vendor              <chr> "1st Run Computer Services Inc", "1st Run Computer Services Inc", "2…
#> $ city                <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ state               <chr> "NY", "NY", "CT", "CT", "PA", "PA", "PA", "TX", "TX", "PA", "TX", "P…
#> $ dept_id_description <chr> "WQD - Waterbury", "Water Supply Division - Wtby", "MAINTENANCE", "M…
#> $ dept_id             <chr> "6140040206", "6140040406", "3300010300", "3300010300", "3480004630"…
#> $ amount              <dbl> 930.00, 930.00, 24.00, 420.00, 270.80, 35.00, 971.40, 60.59, 541.62,…
#> $ account             <chr> "Rep&Maint-Info Tech Hardware", "Rep&Maint-Info Tech Hardware", "Fre…
#> $ acct_no             <chr> "513000", "513000", "517300", "520200", "516659", "516659", "520500"…
#> $ fund_description    <chr> "Environmental Permit Fund", "Environmental Permit Fund", "Vermont M…
#> $ fund                <chr> "21295", "21295", "21782", "21782", "10000", "10000", "10000", "1000…
tail(vtc)
#> # A tibble: 6 x 14
#>   quarter_ending department unit_no vendor_number vendor city  state dept_id_descrip… dept_id
#>   <date>         <chr>      <chr>   <chr>         <chr>  <chr> <chr> <chr>            <chr>  
#> 1 2020-03-31     Fish & Wi… 06120   0000000902    r. k.… Manc… VT    Wildlife - Barre 612002…
#> 2 2020-03-31     Fish & Wi… 06120   0000000902    r. k.… Manc… VT    Wildlife - Barre 612002…
#> 3 2020-03-31     Forests, … 06130   0000000902    r. k.… Manc… VT    Parks            613003…
#> 4 2020-03-31     Transport… 08100   0000341336    van Z… Farm… CT    Program Develop… 810000…
#> 5 2020-03-31     Tourism &… 07130   0000359028    xAd, … New … NY    Tourism-Mkting-… 713000…
#> 6 2020-03-31     Tourism &… 07130   0000359028    xAd, … New … NY    Tourism-Mkting-… 713000…
#> # … with 5 more variables: amount <dbl>, account <chr>, acct_no <chr>, fund_description <chr>,
#> #   fund <chr>
```

### Missing

The columns vary in their degree of missing values, but none are missing
from the variables we need to identify transaction parties.

``` r
col_stats(vtc, count_na)
#> # A tibble: 14 x 4
#>    col                 class       n          p
#>    <chr>               <chr>   <int>      <dbl>
#>  1 quarter_ending      <date>      0 0         
#>  2 department          <chr>       0 0         
#>  3 unit_no             <chr>       0 0         
#>  4 vendor_number       <chr>       0 0         
#>  5 vendor              <chr>       0 0         
#>  6 city                <chr>  742323 0.442     
#>  7 state               <chr>      48 0.0000286 
#>  8 dept_id_description <chr>     537 0.000320  
#>  9 dept_id             <chr>       0 0         
#> 10 amount              <dbl>       0 0         
#> 11 account             <chr>       0 0         
#> 12 acct_no             <chr>       0 0         
#> 13 fund_description    <chr>       3 0.00000179
#> 14 fund                <chr>       0 0
```

``` r
vtc <- vtc %>% flag_na(quarter_ending, vendor, amount, department)
if (sum(vtc$na_flag) == 0) {
  vtc <- select(vtc, -na_flag)
} else {
  vtc %>% 
    filter(na_flag) %>% 
    select(quarter_ending, vendor, amount, department)
}
```

### Duplicates

There are a number of records that are entirely duplicated across every
column. These records can be flagged with `campfin::flag_na()`.

``` r
vtc <- flag_dupes(vtc, everything())
sum(vtc$dupe_flag)
#> [1] 1199
```

These may be legitimate contracts/payments made on the same day for the
same amount, but they are flagged nonetheless.

``` r
vtc %>% 
  filter(dupe_flag) %>% 
  select(quarter_ending, vendor, amount, department)
#> # A tibble: 1,199 x 4
#>    quarter_ending vendor                   amount department                 
#>    <date>         <chr>                     <dbl> <chr>                      
#>  1 2017-06-30     Konstantin,Gladys             7 Vermont Health Access      
#>  2 2017-06-30     Konstantin,Gladys             7 Vermont Health Access      
#>  3 2017-06-30     Perkin Elmer Genetics        50 Health                     
#>  4 2017-06-30     Perkin Elmer Genetics        50 Health                     
#>  5 2017-06-30     National Law Enforcement   4000 Public Safety              
#>  6 2017-06-30     National Law Enforcement   4000 Public Safety              
#>  7 2017-06-30     Loring,Dawn E.                6 Secretary of State's Office
#>  8 2017-06-30     Loring,Dawn E.                6 Secretary of State's Office
#>  9 2017-06-30     Pitney Bowes Inc            500 Children and Families      
#> 10 2017-06-30     Pitney Bowes Inc            500 Children and Families      
#> # … with 1,189 more rows
```

### Categorical

``` r
col_stats(vtc, n_distinct)
#> # A tibble: 15 x 4
#>    col                 class       n          p
#>    <chr>               <chr>   <int>      <dbl>
#>  1 quarter_ending      <date>     43 0.0000256 
#>  2 department          <chr>     110 0.0000655 
#>  3 unit_no             <chr>      70 0.0000417 
#>  4 vendor_number       <chr>   57965 0.0345    
#>  5 vendor              <chr>  164686 0.0980    
#>  6 city                <chr>    6126 0.00365   
#>  7 state               <chr>      94 0.0000559 
#>  8 dept_id_description <chr>    2797 0.00166   
#>  9 dept_id             <chr>    2853 0.00170   
#> 10 amount              <dbl>  456833 0.272     
#> 11 account             <chr>    1063 0.000633  
#> 12 acct_no             <chr>    1040 0.000619  
#> 13 fund_description    <chr>     354 0.000211  
#> 14 fund                <chr>     352 0.000210  
#> 15 dupe_flag           <lgl>       2 0.00000119
```

![](../plots/distinct_plots-1.png)<!-- -->![](../plots/distinct_plots-2.png)<!-- -->![](../plots/distinct_plots-3.png)<!-- -->

### Amounts

A small percentage of `amount` values are less than or equal to zero,
but the range appears otherwise normal.

``` r
noquote(map_chr(summary(vtc$amount), dollar))
#>         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
#>  -$2,880,183       $68.49      $371.46   $28,350.63       $2,252 $228,176,819
percent(mean(vtc$amount <= 0), 0.01)
#> [1] "0.64%"
```

These are the largest and smallest contract `amount` values:

``` r
glimpse(mutate(vtc[which.min(vtc$amount), ], across(amount, dollar)))
#> Rows: 1
#> Columns: 15
#> $ quarter_ending      <date> 2012-03-31
#> $ department          <chr> "Department of VT Health Access"
#> $ unit_no             <chr> "03410"
#> $ vendor_number       <chr> "0000279742"
#> $ vendor              <chr> "HP Enterprise Services LLC"
#> $ city                <chr> NA
#> $ state               <chr> "VT"
#> $ dept_id_description <chr> "DVHA-Programs-ST-Only Funded G"
#> $ dept_id             <chr> "3410017000"
#> $ amount              <chr> "-$2,880,183"
#> $ account             <chr> "Medical Services Grants"
#> $ acct_no             <chr> "604250"
#> $ fund_description    <chr> "General Fund"
#> $ fund                <chr> "10000"
#> $ dupe_flag           <lgl> FALSE
glimpse(mutate(vtc[which.max(vtc$amount), ], across(amount, dollar)))
#> Rows: 1
#> Columns: 15
#> $ quarter_ending      <date> 2020-03-31
#> $ department          <chr> "Vermont Health Access"
#> $ unit_no             <chr> "03410"
#> $ vendor_number       <chr> "0000366045"
#> $ vendor              <chr> "DXC Technology Services LLC"
#> $ city                <chr> "Tysons"
#> $ state               <chr> "VA"
#> $ dept_id_description <chr> "DVHA-Medicaid Prog/Global Comm"
#> $ dept_id             <chr> "3410015000"
#> $ amount              <chr> "$228,176,819"
#> $ account             <chr> "Medical Services Grants"
#> $ acct_no             <chr> "604250"
#> $ fund_description    <chr> "Global Commitment Fund"
#> $ fund                <chr> "20405"
#> $ dupe_flag           <lgl> FALSE
```

The distribution of `amount` values is log-normal, as we would expect.

![](../plots/hist_amount-1.png)<!-- -->

### Dates

We can add the calendar year from `date` with `lubridate::year()`

``` r
vtc <- mutate(vtc, year = year(quarter_ending))
```

``` r
min(vtc$quarter_ending)
#> [1] "2009-09-30"
sum(vtc$year < 2000)
#> [1] 0
max(vtc$quarter_ending)
#> [1] "2020-03-31"
sum(vtc$quarter_ending > today())
#> [1] 0
```

![](../plots/bar_year-1.png)<!-- -->

## State

We can manually add the department state.

``` r
vtc <- mutate(vtc, dept_state = "VT", .after = department)
```

We can count the `state` abbreviation values that are not American or
Canadian.

``` r
vtc %>% 
  filter(state %out% valid_state) %>% 
  count(state, sort = TRUE) %>% 
  print(n = Inf)
#> # A tibble: 27 x 2
#>    state      n
#>    <chr>  <int>
#>  1 CD       221
#>  2 0         91
#>  3 <NA>      48
#>  4 BERKS     43
#>  5 ZZ        30
#>  6 PQ        27
#>  7 NSW       23
#>  8 BE        21
#>  9 NF         5
#> 10 KENT       3
#> 11 WILTS      3
#> 12 YY         3
#> 13 75         2
#> 14 CAMBS      2
#> 15 MDDSX      2
#> 16 SURREY     2
#> 17 EN         1
#> 18 ESSEX      1
#> 19 GE         1
#> 20 GT LON     1
#> 21 IE         1
#> 22 N YORK     1
#> 23 SOMER      1
#> 24 SP         1
#> 25 VIC        1
#> 26 W GLAM     1
#> 27 WYORKS     1
```

Those records with the `state` value of “CD” are Canadian cities with
the proper state/province abbreviation in the `city` name value.

``` r
vtc %>% 
  filter(state == "CD") %>% 
  count(city, sort = TRUE)
#> # A tibble: 18 x 2
#>    city                 n
#>    <chr>            <int>
#>  1 <NA>               169
#>  2 FREDERICTON NB      22
#>  3 MILTON ON            7
#>  4 EDMONTON AB          4
#>  5 CHICOUTIMI           2
#>  6 NAPIERVILLE PQ       2
#>  7 ST JOSEPH PQ         2
#>  8 ST PAMPHILE PQ       2
#>  9 WINNIPEG MB          2
#> 10 CALGARY AB           1
#> 11 FREDERICTION NB      1
#> 12 PIKE RIVER PQ        1
#> 13 SAINT JACQUES NB     1
#> 14 SAINTE FOY QC        1
#> 15 SAINTE-JULIE PQ      1
#> 16 ST ADALBERT PQ       1
#> 17 ST GEDEON PQ         1
#> 18 ST JOHNS NF          1
```

``` r
vtc <- mutate(
  .data = vtc,
  state_norm = normal_state(
    state = state,
    abbreviate = TRUE,
    na_rep = TRUE,
    valid = valid_state
  )
)
```

``` r
progress_table(
  vtc$state, 
  vtc$state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage      prop_in n_distinct   prop_na n_out n_diff
#>   <chr>        <dbl>      <dbl>     <dbl> <dbl>  <dbl>
#> 1 state         1.00         94 0.0000286   489     27
#> 2 state_norm    1            68 0.000320      0      1
```

## City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
vtc <- vtc %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("VT", "DC", "VERMONT"),
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

#### Progress

| stage      | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :--------- | -------: | ----------: | -------: | -----: | ------: |
| city)      |    0.876 |        4673 |    0.442 | 115894 |    1115 |
| city\_norm |    0.980 |        4388 |    0.442 |  19108 |     711 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/bar_progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar_distinct-1.png)<!-- -->

## Conclude

Before exporting, we can remove the intermediary normalization columns
and rename all added variables with the `_clean` suffix.

``` r
vtc <- vtc %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  rename_all(~str_remove(., "_raw"))
```

``` r
glimpse(sample_n(vtc, 20))
#> Rows: 20
#> Columns: 19
#> $ quarter_ending      <date> 2010-03-31, 2019-06-30, 2013-09-30, 2013-06-30, 2018-09-30, 2010-06…
#> $ department          <chr> "Agency of Transportation", "Crime Victims' Services Center", "Judic…
#> $ dept_state          <chr> "VT", "VT", "VT", "VT", "VT", "VT", "VT", "VT", "VT", "VT", "VT", "V…
#> $ unit_no             <chr> "08100", "02160", "02120", "03440", "01160", "05100", "08100", "0342…
#> $ vendor_number       <chr> "0000040414", "0000001802", "0000019257", "0000283499", "0000316689"…
#> $ vendor              <chr> "Newport City Treasurer", "Vermont Network Against Domestic", "Words…
#> $ city                <chr> NA, "Montpelier", NA, NA, "Williston", NA, "Franklin", "Burlington",…
#> $ state               <chr> "VT", "VT", "NH", "GA", "VT", "VT", "NH", "VT", "VT", "VT", "GA", "V…
#> $ dept_id_description <chr> "Town Highway Bridge", "Victims Assistance", "Chittenden Family Divi…
#> $ dept_id             <chr> "8100002800", "2160010200", "2120270400", "3440010500", "1160550080"…
#> $ amount              <dbl> 0.50, 87298.75, 720.00, 1509.36, 33871.60, 120.00, 1025.00, 6500.00,…
#> $ account             <chr> "Registration & Identification", "Grants", "Interpreters", "Telecom-…
#> $ acct_no             <chr> "523640", "550220", "507615", "516659", "521100", "550020", "522800"…
#> $ fund_description    <chr> "Transportation Local Fund", "Domestic & Sexual Violence", "General …
#> $ fund                <chr> "20160", "21926", "10000", "22005", "58800", "22005", "20191", "2200…
#> $ dupe_flag           <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
#> $ year                <dbl> 2010, 2019, 2013, 2013, 2018, 2010, 2020, 2016, 2015, 2011, 2016, 20…
#> $ state_clean         <chr> "VT", "VT", "NH", "GA", "VT", "VT", "NH", "VT", "VT", "VT", "GA", "V…
#> $ city_clean          <chr> NA, "MONTPELIER", NA, NA, "WILLISTON", NA, "FRANKLIN", "BURLINGTON",…
```

1.  There are 1,680,169 records in the database.
2.  There are 1,199 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 0 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("vt", "contracts", "data", "clean"))
clean_path <- path(clean_dir, "vt_contracts_clean.csv")
write_csv(vtc, clean_path, na = "")
file_size(clean_path)
#> 328M
file_encoding(clean_path)
#> # A tibble: 1 x 3
#>   path                                                                        mime          charset
#>   <fs::path>                                                                  <chr>         <chr>  
#> 1 /home/kiernan/Code/accountability_datacleaning/R_campfin/vt/contracts/data… application/… us-asc…
```

## Upload

Using the [duckr](https://github.com/kiernann/duckr) R package, we can
wrap around the [duck](https://duck.sh/) command line tool to upload the
file to the IRW server.

``` r
# remotes::install_github("kiernann/duckr")
s3_dir <- "s3:/publicaccountability/csv/"
s3_path <- path(s3_dir, basename(clean_path))
if (require(duckr)) {
  duckr::duck_upload(clean_path, s3_path)
}
```

## Dictionary

The following table describes the variables in our final exported file:

| Column                | Type        | Definition                       |
| :-------------------- | :---------- | :------------------------------- |
| `quarter_ending`      | `double`    | End date of fiscal quarter made  |
| `department`          | `character` | Spending department name         |
| `dept_state`          | `character` | Spending department state (VT)   |
| `unit_no`             | `character` | Department unit number           |
| `vendor_number`       | `character` | Unique vendor number             |
| `vendor`              | `character` | Full vendor name                 |
| `city`                | `character` | Vendor city                      |
| `state`               | `character` | Vendor state                     |
| `dept_id_description` | `character` | Department subdivision           |
| `dept_id`             | `character` | Department ID                    |
| `amount`              | `double`    | Contract/payment amount          |
| `account`             | `character` | Spending account                 |
| `acct_no`             | `character` | Source account number            |
| `fund_description`    | `character` | Fund name                        |
| `fund`                | `character` | Fund number                      |
| `dupe_flag`           | `logical`   | Flag indicating duplicate record |
| `year`                | `double`    | Fiscal quarter calendar year     |
| `state_clean`         | `character` | Normalized vendor state          |
| `city_clean`          | `character` | Normalized vendor city           |
