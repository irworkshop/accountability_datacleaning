Nursing Home Compare Data Diary – infection
================
Yanqi Xu
<<<<<<< HEAD
2020-03-19 12:31:27
=======
2020-03-19 12:19:14
>>>>>>> 6353ae7a0c8672ecd3918f3c6f4c7bd714609298

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
  readxl, # read excel
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
#> [1] "/Users/yanqixu/code/accountability_datacleaning/R_campfin"
```

## Data

<<<<<<< HEAD
The master flat file is obtained from the
[Medicare.gov](https://www.medicare.gov/nursinghomecompare/Data/About.html).
The data is as current as March 16, 2020.
=======
The Emergency Preparedness file is obtained from the
[Medicare.gov](https://data.medicare.gov/Nursing-Home-Compare/Emergency-Preparedness-Deficiencies/9ezk-fzua).
The data is as current as March 16, 2020. First, we will read the
infectionship data. We can also view the record layout from the
`infectionship` sheet `DataMedicareGov_MetadataAllTabs_v23.xlsx`.
>>>>>>> 6353ae7a0c8672ecd3918f3c6f4c7bd714609298

``` r
raw_dir <- dir_create(here("nursing_home","data", "raw"))
```

We can also generate a table of Deficiency Tag Number (`tag`) and Text
definition of deficiency (`tag_desc`).

Tag numbers corresponding to infection-control deficiencies include
`0441` (Have a program that investigates, controls and keeps infection
from spreading), which later became `0880` (Provide and implement an
infection prevention and control program), and a related code `0882`.
See [USA Today’s OpenNews Post explaning the
code](https://source.opennews.org/articles/covid-19-story-recipe-analyzing-nursing-home-data/)

``` r
health <- read_csv(file = dir_ls(raw_dir, recurse = T, regexp = "Health+")) %>% clean_names()

health_dict <- read_xlsx(dir_ls(docs, recurse = T,regexp = "DataMedicareGov.+"),
                        sheet = "HealthDeficiencies")

kable(health_dict)
```

| Variable Name (column headers on ACCESS tables and CSV Downloadable files) | Label (column headers on CSV Display files) | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Format / Values                                                      |
| :------------------------------------------------------------------------- | :------------------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :------------------------------------------------------------------- |
| PROVNUM                                                                    | Federal Provider Number                     | Provider Number                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | 6 alphanumeric characters                                            |
| PROVNAME                                                                   | Provider Name                               | Provider Name                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | text                                                                 |
| address                                                                    | Provider Address                            | Provider Address                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | text                                                                 |
| city                                                                       | Provider City                               | Provider City                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | text                                                                 |
| state                                                                      | Provider State                              | Provider State                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | 2-character postal abbreviation                                      |
| zip                                                                        | Provider Zip Code                           | Provider Zip Code                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | 5-digit zip code                                                     |
| survey\_date\_output                                                       | Survey Date                                 | Date of Health Inspection Survey                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | date                                                                 |
| SurveyType                                                                 | Survey Type                                 | Type of survey: Health or Fire Safety                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | text (Health)                                                        |
| DEFPREF                                                                    | Deficiency Prefix                           | The alphabetic character that is assigned to a series of data tags that apply to a provider                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | text (F)                                                             |
| CATEGORY                                                                   | Deficiency Category                         | Category of Health Deficiency                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | text                                                                 |
| TAG                                                                        | Deficiency Tag Number                       | Deficiency Tag Number                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | 4-digit tag code                                                     |
| TAG\_DESC                                                                  | Deficiency Description                      | Text definition of deficiency                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | text                                                                 |
| SCOPE                                                                      | Scope Severity Code                         | Indicates the level of harm to the resident(s) involved and the scope of the problem within the nursing home.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | text                                                                 |
| DEFSTAT                                                                    | Deficiency Corrected                        | Indicates whether the deficiency has been corrected, a plan of correction has been devised, or the deficiency has yet to be corrected                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | text                                                                 |
| statdate                                                                   | Correction Date                             | Date the deficiency was corrected                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | date                                                                 |
| cycle                                                                      | Inspection Cycle                            | The inspection cycle of deficiency for display on Nursing Home Compare, where 1 is the most recent cycle. Standard inspection cycles are counted sequentially into the past, complaint inspection cycles are counted annually into the past. If a defiency is found on a co-occurring standard and complaint inspection, it is assigned to the standard cycle. Citations from Health Inspections occurring on or after 11/28/2017 are not currently used in calculating the health inspection rating; thus, the “cycle” on this table may be different from the rating cycle. Please refer to the 5-star Technical Users Guide for further information. | integer                                                              |
| standard                                                                   | Standard Deficiency                         | Indicates that the deficiency was found on a standard inspection                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | Y/N                                                                  |
| complaint                                                                  | Complaint Deficiency                        | Indicates that the deficiency was found on a complaint inspection                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | Y/N                                                                  |
| LOCATION                                                                   | Location                                    | Location of facility                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | only on displayed version of file; renders as latitude and longitude |
| FILEDATE                                                                   | Processing Date                             | Date the data were retrieved                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | date                                                                 |

``` r

infection <- health %>% 
  filter(tag == "0880" | tag == "0441")
```

### Missing

The infection-control table has ost of the information available.

``` r
col_stats(infection, count_na)
#> # A tibble: 19 x 4
#>    col                class      n       p
#>    <chr>              <chr>  <int>   <dbl>
#>  1 provnum            <chr>      0 0      
#>  2 provname           <chr>      0 0      
#>  3 address            <chr>      0 0      
#>  4 city               <chr>      0 0      
#>  5 state              <chr>      0 0      
#>  6 zip                <dbl>      0 0      
#>  7 survey_date_output <date>     0 0      
#>  8 surveytype         <chr>      0 0      
#>  9 defpref            <lgl>      0 0      
#> 10 category           <chr>      0 0      
#> 11 tag                <chr>      0 0      
#> 12 tag_desc           <chr>      0 0      
#> 13 scope              <chr>      0 0      
#> 14 defstat            <chr>      0 0      
#> 15 statdate           <date>    61 0.00298
#> 16 cycle              <dbl>      0 0      
#> 17 standard           <chr>      0 0      
#> 18 complaint          <chr>      0 0      
#> 19 filedate           <date>     0 0
```

### Duplicates

We can see there’s no duplicate entry.

``` r
infection <- flag_dupes(infection, dplyr::everything())
```

## Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are taylor made to facilitate this process.

### Address

For the street `addresss` variable, the `campfin::normal_address()`
function will force consistence case, remove punctuation, and
abbreviation official USPS suffixes.

``` r
infection <- infection %>% 
    mutate(address_norm = normal_address(address,abbs = usps_street,
      na_rep = TRUE))
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valied *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
prop_in(infection$zip, valid_zip, na.rm = T)
#> [1] 0.9402416

infection <- infection %>% 
    mutate(zip5 = normal_zip(zip, na_rep = T))

prop_in(infection$zip5, valid_zip, na.rm = T)
#> [1] 0.9995109
```

### State

The two digit state abbreviations are all valid.

``` r
prop_in(infection$state, valid_state, na.rm = T)
#> [1] 1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats. \#\#\#\# Normal

The `campfin::normal_city()` function is a good infectionart, again
converting case, removing punctuation, but *expanding* USPS
abbreviations. We can also remove `invalid_city` values.

``` r
infection <- infection %>% 
      mutate(city_norm = normal_city(city,abbs = usps_city,
      states = usps_state,
      na = invalid_city,
      na_rep = TRUE))

prop_in(infection$city_norm, valid_city, na.rm = T)
#> [1] 0.9764292
```

#### Swap

We can further improve normalization by comparing our normalized value
against the *expected* value for that record’s state abbreviation and
ZIP code. If the normalized value is either an abbreviation for or very
similar to the expected value, we can confidently swap those two.

``` r
infection <- infection %>% 
  rename(city_raw = city) %>% 
  left_join(
    y = zipcodes,
    by = c(
      "state" = "state",
      "zip5" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(city_norm, city_match),
    match_dist = str_dist(city_norm, city_match),
    city_swap = if_else(
      condition = !is.na(match_dist) & match_abb | match_dist == 1,
      true = city_match,
      false = city_norm
    )
  ) %>% 
  select(
    -city_match,
    -match_dist,
    -match_abb
  )
```

After the two normalization steps, the percentage of valid cities is at
100%. \#\#\#\# Progress

| stage      | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :--------- | -------: | ----------: | -------: | -----: | ------: |
| city\_raw  |    0.990 |        4420 |    0.000 |    205 |      84 |
| city\_norm |    0.993 |        4409 |    0.000 |    143 |      62 |
| city\_swap |    0.996 |        4403 |    0.002 |     88 |      40 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/progress_bar-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

``` r
progress %>% 
  select(
    stage, 
    all = n_distinct,
    bad = n_diff
  ) %>% 
  mutate(good = all - bad) %>% 
  pivot_longer(c("good", "bad")) %>% 
  mutate(name = name == "good") %>% 
  ggplot(aes(x = stage, y = value)) +
  geom_col(aes(fill = name)) +
  scale_fill_brewer(palette = "Dark2", direction = -1) +
  scale_y_continuous(labels = comma) +
  theme(legend.position = "bottom") +
  labs(
    title = "Nursing Home Compare Health Deficiency Citations Table City Normalization Progress",
    subtitle = "Distinct values, valid and invalid",
    x = "stage",
    y = "Percent Valid",
    fill = "Valid"
  )
```

![](../plots/distinct_bar-1.png)<!-- -->

## Explore

### Categorical

#### Year

``` r
infection <- infection %>% 
  mutate(year = year(survey_date_output))
tabyl(infection$year)
#> # A tibble: 7 x 3
#>   `infection$year`     n  percent
#>              <dbl> <dbl>    <dbl>
#> 1             2014     4 0.000196
#> 2             2015    33 0.00161 
#> 3             2016  1446 0.0707  
#> 4             2017  6127 0.300   
#> 5             2018  6619 0.324   
#> 6             2019  6206 0.303   
#> 7             2020    14 0.000685
```

## Conclude

``` r
glimpse(sample_n(infection, 20))
#> Observations: 20
#> Variables: 24
#> $ provnum            <chr> "365594", "335398", "555623", "175334", "365658", "056272", "676281",…
#> $ provname           <chr> "EUCLID BEACH HEALTHCARE", "SANS SOUCI REHABILITATION AND NURSING CEN…
#> $ address            <chr> "16101 EUCLID BEACH BLVD", "115 PARK AVENUE", "371 NORTH WESTON PL", …
#> $ city_raw           <chr> "CLEVELAND", "YONKERS", "HEMET", "LIBERAL", "MADISON", "SAN FRANCISCO…
#> $ state              <chr> "OH", "NY", "CA", "KS", "OH", "CA", "TX", "KY", "WI", "GA", "WA", "OH…
#> $ zip                <dbl> 44110, 10703, 92543, 67901, 44057, 94117, 78251, 40205, 54848, 31545,…
#> $ survey_date_output <date> 2019-10-09, 2018-08-07, 2018-09-20, 2019-02-20, 2019-05-16, 2017-04-…
#> $ surveytype         <chr> "Health", "Health", "Health", "Health", "Health", "Health", "Health",…
#> $ defpref            <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ category           <chr> "Environmental Deficiencies", "Environmental Deficiencies", "Environm…
#> $ tag                <chr> "0880", "0880", "0880", "0880", "0880", "0441", "0880", "0880", "0880…
#> $ tag_desc           <chr> "Provide and implement an infection prevention and control program.",…
#> $ scope              <chr> "F", "D", "E", "F", "D", "E", "E", "D", "F", "D", "D", "F", "F", "E",…
#> $ defstat            <chr> "Deficient, Provider has date of correction", "Deficient, Provider ha…
#> $ statdate           <date> 2019-12-11, 2018-10-09, 2018-10-18, 2019-03-22, 2019-06-15, 2017-06-…
#> $ cycle              <dbl> 1, 1, 2, 1, 1, 3, 2, 2, 1, 2, 1, 1, 3, 3, 3, 3, 1, 2, 1, 1
#> $ standard           <chr> "Y", "Y", "Y", "N", "Y", "N", "N", "N", "Y", "Y", "Y", "Y", "Y", "Y",…
#> $ complaint          <chr> "N", "N", "N", "Y", "N", "Y", "Y", "Y", "N", "N", "N", "N", "N", "N",…
#> $ filedate           <date> 2020-02-01, 2020-02-01, 2020-02-01, 2020-02-01, 2020-02-01, 2020-02-…
#> $ address_norm       <chr> "16101 EUCLID BCH BLVD", "115 PARK AVE", "371 N WESTON PL", "2160 ZIN…
#> $ zip5               <chr> "44110", "10703", "92543", "67901", "44057", "94117", "78251", "40205…
#> $ city_norm          <chr> "CLEVELAND", "YONKERS", "HEMET", "LIBERAL", "MADISON", "SAN FRANCISCO…
#> $ city_swap          <chr> "CLEVELAND", "YONKERS", "HEMET", "LIBERAL", "MADISON", "SAN FRANCISCO…
#> $ year               <dbl> 2019, 2018, 2018, 2019, 2019, 2017, 2018, 2018, 2019, 2018, 2019, 201…
```

1.  There are 20449 records in the database.
2.  There are 0 duplicate records in the database.
3.  The range and distribution of `year` seems mostly reasonable except
    for a few entries.
4.  There are 0 records missing either recipient or date.
5.  Consistency in goegraphic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
clean_dir <- dir_create(here("nursing_home","data", "processed"))
```

``` r
write_csv(
  x = infection %>% 
    mutate_if(is.character, str_to_upper) %>% 
    select(-city_norm) %>% 
    rename(city_clean = city_swap),
  path = path(clean_dir, "nursing_infection_clean.csv"),
  na = ""
)

write_csv(
  x = health_dict %>% clean_names(),
  path = path(docs, "nursing_infection_dict.csv"),
  na = ""
)
```
