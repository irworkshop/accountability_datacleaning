{State} {Type}
================
First Last
2020-03-13 17:04:00

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Download](#download)
  - [Layout](#layout)
  - [Read](#read)
  - [Explore](#explore)
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
#> [1] "/home/kiernan/Code/accountability_datacleaning/us_spending"
```

## Data

The data is obtained from the [USA Spending Award Data
Archive](https://www.usaspending.gov/#/download_center/award_data_archive).

> Welcome to the Award Data Archive, which features major agencies’
> award transaction data for full fiscal years. They’re a great way to
> get a view into broad spending trends and, best of all, the files are
> already prepared — you can access them instantaneously.

## Download

If the zip archive has not been downloaded, we can do so now.

``` r
archive_url <- "https://files.usaspending.gov/award_data_archive/"
hhs_files <- glue("FY{2008:2020}_075_Contracts_Full_20200205.zip")
hhs_urls <- paste0(archive_url, hhs_files)
raw_dir <- dir_create(here("hhs", "data", "raw"))
hhs_paths <- path(raw_dir, hhs_files)
if (!all(file_exists(hhs_paths))) {
  download.file(hhs_urls, hhs_paths)
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
  mutate_at(vars(definition), str_trunc, 69) %>% 
  kable()
```

| award\_element                       | definition                                                          |
| :----------------------------------- | :------------------------------------------------------------------ |
| award\_id\_piid                      | The unique identifier of the specific award being reported.         |
| modification\_number                 | The identifier of an action being reported that indicates the spec… |
| transaction\_number                  | Tie Breaker for legal, unique transactions that would otherwise ha… |
| parent\_award\_agency\_id            | Identifier used to link agency in FPDS-NG to referenced IDV inform… |
| parent\_award\_agency\_name          | Name of the agency associated with the code in the Referenced IDV … |
| parent\_award\_modification\_number  | When reporting orders under Indefinite Delivery Vehicles (IDV) suc… |
| federal\_action\_obligation          | Amount of Federal government’s obligation, de-obligation, or liabi… |
| total\_dollars\_obligated            | This is a system generated element providing the sum of all the am… |
| base\_and\_exercised\_options\_value | The change (from this transaction only) to the current contract va… |
| current\_total\_value\_of\_award     | Total amount obligated to date on an award. For a contract, this a… |

## Read

This archive file can be directly read as a data frame with
`vroom::vroom()`.

``` r
hhs <- vroom(
  file = hhs_paths,
  delim = ",",
  escape_backslash = FALSE,
  escape_double = FALSE,
  col_types = cols(
    .default = col_skip(),
    action_date_fiscal_year = col_integer(),
    action_date = col_date(),
    modification_number = col_integer(),
    parent_award_agency_id = col_integer(),
    parent_award_agency_name = col_character(),
    total_dollars_obligated = col_double(),
    awarding_agency_code = col_integer(),
    awarding_agency_name = col_character(),
    awarding_sub_agency_code = col_integer(),
    awarding_sub_agency_name = col_character(),
    awarding_office_code = col_integer(),
    awarding_office_name = col_character(),
    recipient_name = col_character(),
    recipient_parent_name = col_character(),
    recipient_country_name = col_character(),
    recipient_address_line_1 = col_character(),
    recipient_city_name = col_character(),
    recipient_state_code = col_character(),
    recipient_zip_4_code = col_character(),
    recipient_phone_number = col_character(),
    primary_place_of_performance_city_name = col_character(),
    primary_place_of_performance_state_code = col_character(),
    primary_place_of_performance_zip_4 = col_character(),
    award_type_code = col_character(),
    award_description = col_character()
  )
)
```

``` r
# properly read
count(hhs, awarding_sub_agency_name, sort = TRUE)
#> # A tibble: 17 x 2
#>    awarding_sub_agency_name                                             n
#>    <chr>                                                            <int>
#>  1 NATIONAL INSTITUTES OF HEALTH                                   420971
#>  2 INDIAN HEALTH SERVICE                                           240478
#>  3 CENTERS FOR DISEASE CONTROL AND PREVENTION                      133245
#>  4 OFFICE OF THE ASSISTANT SECRETARY FOR ADMINISTRATION (ASA)       75625
#>  5 FOOD AND DRUG ADMINISTRATION                                     69285
#>  6 CENTERS FOR MEDICARE AND MEDICAID SERVICES                       38918
#>  7 HEALTH RESOURCES AND SERVICES ADMINISTRATION                     31746
#>  8 AGENCY FOR HEALTHCARE RESEARCH AND QUALITY                        5309
#>  9 OFFICE OF ASSISTANT SECRETARY FOR PREPAREDNESS AND RESPONSE       4878
#> 10 SUBSTANCE ABUSE AND MENTAL HEALTH SERVICES ADMINISTRATION         4007
#> 11 OFFICE OF ASSISTANT SECRETARY FOR ADMINISTRATION AND MANAGEMENT   3873
#> 12 OFFICE OF THE INSPECTOR GENERAL                                    472
#> 13 PROGRAM SUPPORT CENTER                                             118
#> 14 OFFICE OF ASST SECRETARY FOR HEALTH EXCEPT NATIONAL CENTERS         15
#> 15 AGENCY FOR HEALTH CARE POLICY AND RESEARCH                           3
#> 16 OFFICE OF THE SECRETARY OF HEALTH AND HUMAN SERVICES                 2
#> 17 HEALTH AND HUMAN SERVICES, DEPARTMENT OF                             1
```

``` r
# filter to only cdc
# cdc <- filter(cdc, parent_award_agency_id == 7523)
```

## Explore

``` r
head(hhs)
#> # A tibble: 6 x 25
#>   modification_nu… parent_award_ag… parent_award_ag… total_dollars_o… action_date action_date_fis…
#>              <int>            <int> <chr>                       <dbl> <date>                 <int>
#> 1               21               NA <NA>                    33640675. 2008-09-30              2008
#> 2               25               NA <NA>                          NA  2008-09-30              2008
#> 3                0             7530 CENTERS FOR MED…              NA  2008-09-30              2008
#> 4                0               NA <NA>                          NA  2008-09-30              2008
#> 5                2               NA <NA>                          NA  2008-09-30              2008
#> 6                7               NA <NA>                          NA  2008-09-30              2008
#> # … with 19 more variables: awarding_agency_code <int>, awarding_agency_name <chr>,
#> #   awarding_sub_agency_code <int>, awarding_sub_agency_name <chr>, awarding_office_code <int>,
#> #   awarding_office_name <chr>, recipient_name <chr>, recipient_parent_name <chr>,
#> #   recipient_country_name <chr>, recipient_address_line_1 <chr>, recipient_city_name <chr>,
#> #   recipient_state_code <chr>, recipient_zip_4_code <chr>, recipient_phone_number <chr>,
#> #   primary_place_of_performance_city_name <chr>, primary_place_of_performance_state_code <chr>,
#> #   primary_place_of_performance_zip_4 <chr>, award_type_code <chr>, award_description <chr>
tail(hhs)
#> # A tibble: 6 x 25
#>   modification_nu… parent_award_ag… parent_award_ag… total_dollars_o… action_date action_date_fis…
#>              <int>            <int> <chr>                       <dbl> <date>                 <int>
#> 1               NA               NA <NA>                       54396. 2019-10-01              2020
#> 2                0               NA <NA>                           0  2019-10-01              2020
#> 3               NA               NA <NA>                           0  2019-10-01              2020
#> 4               NA             7529 NATIONAL INSTIT…        38614662. 2019-10-01              2020
#> 5               NA             4732 FEDERAL ACQUISI…            2923. 2019-10-01              2020
#> 6               NA               NA <NA>                      452641. 2019-10-01              2020
#> # … with 19 more variables: awarding_agency_code <int>, awarding_agency_name <chr>,
#> #   awarding_sub_agency_code <int>, awarding_sub_agency_name <chr>, awarding_office_code <int>,
#> #   awarding_office_name <chr>, recipient_name <chr>, recipient_parent_name <chr>,
#> #   recipient_country_name <chr>, recipient_address_line_1 <chr>, recipient_city_name <chr>,
#> #   recipient_state_code <chr>, recipient_zip_4_code <chr>, recipient_phone_number <chr>,
#> #   primary_place_of_performance_city_name <chr>, primary_place_of_performance_state_code <chr>,
#> #   primary_place_of_performance_zip_4 <chr>, award_type_code <chr>, award_description <chr>
glimpse(sample_n(hhs, 20))
#> Observations: 20
#> Variables: 25
#> $ modification_number                     <int> 6, 14, 0, 0, 1, 1, 0, 0, 0, 8, 0, 0, 5, 0, 1, 8,…
#> $ parent_award_agency_id                  <int> NA, 7529, 7529, 7529, 7527, NA, NA, NA, NA, NA, …
#> $ parent_award_agency_name                <chr> NA, "NATIONAL INSTITUTES OF HEALTH", "NATIONAL I…
#> $ total_dollars_obligated                 <dbl> NA, NA, 81547.07, 0.00, 5626.50, NA, NA, NA, NA,…
#> $ action_date                             <date> 2009-04-07, 2014-04-29, 2016-08-04, 2013-12-06,…
#> $ action_date_fiscal_year                 <int> 2009, 2014, 2016, 2014, 2018, 2013, 2010, 2015, …
#> $ awarding_agency_code                    <int> 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, …
#> $ awarding_agency_name                    <chr> "DEPARTMENT OF HEALTH AND HUMAN SERVICES (HHS)",…
#> $ awarding_sub_agency_code                <int> 7570, 7529, 7527, 7529, 7527, 7527, 7527, 7523, …
#> $ awarding_sub_agency_name                <chr> "OFFICE OF THE ASSISTANT SECRETARY FOR ADMINISTR…
#> $ awarding_office_code                    <int> 233, 271, NA, 263, NA, 244, 239, 200, 200, 267, …
#> $ awarding_office_name                    <chr> "DEPT OF HHS/OFF AST SEC HLTH EXPT NATL CNTR", "…
#> $ recipient_name                          <chr> "WV HEALTH INFORMATION NETWORK", "KELLY SERVICES…
#> $ recipient_parent_name                   <chr> "WV HEALTH INFORMATION NETWORK", "KELLY SERVICES…
#> $ recipient_country_name                  <chr> "UNITED STATES OF AMERICA", "UNITED STATES OF AM…
#> $ recipient_address_line_1                <chr> "100 DEE DRIVE", "999 W BIG BEAVER RD", "4179 BU…
#> $ recipient_city_name                     <chr> "CHARLESTON", "TROY", "FREMONT", "PHILADELPHIA",…
#> $ recipient_state_code                    <chr> "WV", "MI", "CA", "PA", "CA", "MT", "MN", "OH", …
#> $ recipient_zip_4_code                    <chr> "25311", "48084", "945386355", "191042857", "921…
#> $ recipient_phone_number                  <chr> NA, "2482445257", "5103534070", "2155683100", "2…
#> $ primary_place_of_performance_city_name  <chr> "CHARLESTON", "TROY", "POLACCA", "PHILADELPHIA",…
#> $ primary_place_of_performance_state_code <chr> "WV", "MI", "AZ", "PA", "AZ", "MT", "MN", "OH", …
#> $ primary_place_of_performance_zip_4      <chr> "253111600", "480844716", "860424000", "19104285…
#> $ award_type_code                         <chr> "D", "C", "C", "C", "C", "B", "B", "B", NA, "D",…
#> $ award_description                       <chr> "OTHER ADMINISTRATIVE SUPPORT SVCS", "IGF::OT::I…
```

``` r
hhs %>%
  mutate(y = year(action_date), q = quarter(action_date)) %>%
  group_by(y, q) %>%
  summarise(sum = sum(total_dollars_obligated, na.rm = TRUE) / 1e9) %>% 
  ggplot(aes(x = q, y = sum)) +
  geom_col(aes(fill = sum)) +
  scale_fill_viridis_c(end = 0.75, guide = FALSE) +
  scale_y_continuous(labels = dollar) +
  facet_wrap(~y, nrow = 1) +
  theme(
    panel.grid.minor.x = element_blank()
  ) +
  labs(
    title = "Department of Health and Human Services Spending",
    caption = "Source: USASpending.gov",
    x = "Quarter",
    y = "Obligated Spending (Billion USD)"
  )
```

![](../plots/unnamed-chunk-3-1.png)<!-- -->

## Conclude

``` r
# glimpse(sample_n(hhs, 20))
```

1.  There are 1028946 records in the database.
2.  There are 0 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 0 records missing either recipient or date.
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
