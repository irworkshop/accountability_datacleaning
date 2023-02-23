Mississippi Contributions
================
Kiernan Nicholls & Yanqi Xu
Tue Feb 21 23:51:11 2023

- <a href="#project" id="toc-project">Project</a>
- <a href="#objectives" id="toc-objectives">Objectives</a>
- <a href="#packages" id="toc-packages">Packages</a>
- <a href="#data" id="toc-data">Data</a>
- <a href="#download" id="toc-download">Download</a>
- <a href="#read" id="toc-read">Read</a>
- <a href="#explore" id="toc-explore">Explore</a>
  - <a href="#missing" id="toc-missing">Missing</a>
  - <a href="#duplicates" id="toc-duplicates">Duplicates</a>
  - <a href="#categorical" id="toc-categorical">Categorical</a>
  - <a href="#amounts" id="toc-amounts">Amounts</a>
  - <a href="#dates" id="toc-dates">Dates</a>
- <a href="#wrangle" id="toc-wrangle">Wrangle</a>
  - <a href="#address" id="toc-address">Address</a>
  - <a href="#zip" id="toc-zip">ZIP</a>
  - <a href="#state" id="toc-state">State</a>
  - <a href="#city" id="toc-city">City</a>
- <a href="#conclude" id="toc-conclude">Conclude</a>
- <a href="#export" id="toc-export">Export</a>
- <a href="#upload" id="toc-upload">Upload</a>

<!-- Place comments regarding knitting here -->

## Project

The Accountability Project is an effort to cut across data silos and
give journalists, policy professionals, activists, and the public at
large a simple way to search across huge volumes of public data about
people and organizations.

Our goal is to standardize public data on a few key fields by thinking
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

``` r
if (!require("pacman")) {
  install.packages("pacman")
}
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  gluedown, # printing markdown
  jsonlite, # convert json table
  janitor, # clean data frames
  campfin, # custom irw tools
  aws.s3, # aws cloud storage
  refinr, # cluster & merge
  scales, # format strings
  knitr, # knit documents
  vroom, # fast reading
  rvest, # scrape html
  glue, # code strings
  here, # project paths
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
here::i_am("state/ms/contribs/docs/ms_contribs_diary.Rmd")
```

## Data

Mississippi contributions can be found from the Secretary of State’s
online [campaign finance
portal](https://cfportal.sos.ms.gov/online/portal/cf/page/cf-search/Portal.aspx).

The portal makes two notes:

1.  Only contributions in excess of \$200.00 are required to be
    itemized.
2.  (Disclosures submitted prior to 10/1/2016 are located on the
    [Secretary of State’s Campaign Finance Filings
    Search.](http://www.sos.ms.gov/Elections-Voting/Pages/Campaign-Finance-Search.aspx))

These two factors will limit the overall number of contributions we will
be able to download. Prior to FY2017, all contributions were filed in
paper format and can only be found in electronic scans. No bulk data is
available before 2016.

> #### Reliability and Quality of Data
>
> While campaign finance reports filed manually by paper, as opposed to
> electronically through the website, may be accessed and reviewed, the
> data and contents are not searchable by specific criteria. Only the
> data and contents of campaign finance reports filed electronically
> through the website are searchable by specific criteria such as by
> candidate or political committee name, office, expenditure or
> contribution.
>
> The information available on the Campaign Finance filing website is
> provided by the individual candidates, political committees or their
> designated representatives who file campaign finance disclosure
> reports with the Mississippi Secretary of State’s Office. The
> Secretary of State is without the legal authority or obligation to
> verify the data or investigate its accuracy.
>
> Data anticipated to be published or publicly disseminated should be
> confirmed with the candidate or political committee.
>
> \*For questions, contact the Elections Division at
> <CampaignFinance@sos.ms.gov> or 601-576-2550.

While all candidates must file a disclosure, it appears as if campaigns
still have the option of filing their reports in person.

> All candidates for public office, and political committees supporting
> or opposing a candidate or balloted measure, must file campaign
> finance disclosure reports in accordance with the applicable schedule.
> Candidates for statewide, state-district, legislative and judicial
> office, and political committees supporting or opposing those
> candidates or statewide balloted measures, file campaign finance
> disclosure reports with the Secretary of State. These reports either
> may be filed electronically through the Secretary of State’s campaign
> finance online filing system or by paper, filed with the Secretary of
> State by mail, email or fax prior to the applicable reporting
> deadline.

## Download

``` r
raw_dir <- dir_create(here("state","ms", "contribs", "data", "raw"))
raw_json <- path(raw_dir, "ms_contribs.json")
```

``` r
ms_home <- GET("https://cfportal.sos.ms.gov/online/portal/cf/page/cf-search/Portal.aspx")
ms_cook <- cookies(ms_home)
sesh_id <- setNames(ms_cook$value, nm = ms_cook$name)
```

``` r
if (!file_exists(raw_json)) {
  ms_post <- POST(
    "https://cfportal.sos.ms.gov/online/Services/MS/CampaignFinanceServices.asmx/ContributionSearch",
    write_disk(raw_json, overwrite = TRUE),
    set_cookies(sesh_id),
    encode = "json",
    body = list(
      AmountPaid = "",
      BeginDate = "",
      CandidateName = "",
      CommitteeName = "",
      ContributionType = "Any",
      Description = "",
      EndDate = "",
      EntityName = "",
      InKindAmount = ""
    )
  )
}
```

## Read

``` r
msc <- fromJSON(raw_json, simplifyDataFrame = TRUE)
msc <- fromJSON(msc$d)[[1]]
msc <- type_convert(
  df = as_tibble(msc),
  na = "",
  col_types = cols(
    Date = col_datetime("%m/%d/%Y %I:%M:%S %p"),
    Amount = col_number()
  )
)

msc %>% write_csv(path(raw_dir, "ms_contribs.csv"))
```

``` r
msc <- read_csv(path(raw_dir, "ms_contribs.csv"))
msc <- clean_names(msc, case = "snake")
msc <- msc %>% mutate(date = as.Date(date, format = "%Y-%m-%d"))
```

## Explore

There are 80,864 rows of 14 columns. Each record represents a single
contribution made from an individual to a committee.

``` r
glimpse(msc)
#> Rows: 80,864
#> Columns: 14
#> $ recipient        <chr> "Theresa Gillespie Isom for State Rep District 7 Desoto County", "Shane Barnett", "Friends of…
#> $ reference_number <chr> "CF201915576", "CF20187220", "CF201915574", "CF201915596", "CF202325926", "CF202222946", "CF2…
#> $ filing_desc      <chr> "Theresa Gillespie Isom for State Rep Dist 7 Desoto County 7/30/2019 Primary Pre-Election For…
#> $ filing_id        <chr> "ad3e429a-bac7-48b0-811d-985000b0f84a", "728df378-2bd1-4676-8c6c-ffcd2b5af491", "e57a19cf-5d6…
#> $ contributor      <chr> "Phillip Bowden", "Contene", "Dawn McLeod", "Dawn McLeod", "Dr James Nicholson", "Jo P Deal",…
#> $ contributor_type <chr> "Individual", "Corporation", "Individual", "Individual", "Individual", "Corporation", "Indivi…
#> $ address_line1    <chr> "6005 Willow Oaks Dr", "7700 Forsyth Boulevard", "12224 Rebekah Drive", "12224 Rebekah Drive"…
#> $ city             <chr> "Memphis", "St Louis", "Gulfport", "Gulfport", "Hattiesburg", "Jackson", "Zephyr Cove", "Jack…
#> $ state_code       <chr> "TN", "MO", "MS", "MS", "MS", "MS", "NV", "MS", "MS", "TX", "MS", "MS", "MS", "MS", "MS", "MS…
#> $ postal_code      <chr> "38120", "39367", "39503", "39503", "39401-7151", "39216", "89448", "39216", "38732", "77077"…
#> $ in_kind          <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ occupation       <chr> "Doctor", "N/A", "Coast Waterworks, Inc.", "Coast Waterworks, Inc.", "Self-Employed", "St Dom…
#> $ date             <date> 2019-07-23, 2018-11-14, 2019-07-22, 2019-07-22, 2022-12-02, 2021-10-05, 2019-07-28, 2021-06-…
#> $ amount           <dbl> 2.50e+02, 5.00e+02, 5.00e+02, 5.00e+02, 5.00e+02, 2.00e+02, 1.47e+00, 2.50e+02, 2.00e+02, 2.5…
tail(msc)
#> # A tibble: 6 × 14
#>   recipient      refer…¹ filin…² filin…³ contr…⁴ contr…⁵ addre…⁶ city  state…⁷ posta…⁸ in_kind occup…⁹ date       amount
#>   <chr>          <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr> <chr>   <chr>   <lgl>   <chr>   <date>      <dbl>
#> 1 Tate for Gove… CF2020… Tate f… 54b0b8… Zurich… Corpor… 1299 Z… Scha… IL      60196-… NA      <NA>    2019-10-11   1000
#> 2 Tate for Gove… CF2019… Tate f… 12a4c8… Zurich… Corpor… 1299 Z… Scha… IL      60196-… NA      <NA>    2019-10-11   1000
#> 3 ActBlue Missi… CF2019… ActBlu… b74199… ZVOSEC… Indivi… 4741 H… MINN… MN      55419   NA      MEDICA… 2019-10-29     10
#> 4 ActBlue Missi… CF2019… ActBlu… b74199… ZWEGO,… Indivi… 15032 … OLAT… KS      66062   NA      ENGINE… 2019-11-01     10
#> 5 ActBlue Missi… CF2019… ActBlu… 01d433… ZWIEBE… Indivi… 5311 E… CENT… CO      80122   NA      RN      2019-10-23     50
#> 6 ActBlue Missi… CF2019… ActBlu… 01d433… ZWIER-… Indivi… 322 GI… WAUK… IL      60085   NA      PIANO … 2019-10-23     18
#> # … with abbreviated variable names ¹​reference_number, ²​filing_desc, ³​filing_id, ⁴​contributor, ⁵​contributor_type,
#> #   ⁶​address_line1, ⁷​state_code, ⁸​postal_code, ⁹​occupation
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(msc, count_na)
#> # A tibble: 14 × 4
#>    col              class      n        p
#>    <chr>            <chr>  <int>    <dbl>
#>  1 recipient        <chr>      0 0       
#>  2 reference_number <chr>      0 0       
#>  3 filing_desc      <chr>      0 0       
#>  4 filing_id        <chr>      0 0       
#>  5 contributor      <chr>      0 0       
#>  6 contributor_type <chr>      0 0       
#>  7 address_line1    <chr>     52 0.000643
#>  8 city             <chr>     94 0.00116 
#>  9 state_code       <chr>     96 0.00119 
#> 10 postal_code      <chr>    157 0.00194 
#> 11 in_kind          <lgl>  80864 1       
#> 12 occupation       <chr>   8952 0.111   
#> 13 date             <date>     0 0       
#> 14 amount           <dbl>      0 0
```

We can flag any record missing a key variable needed to identify a
transaction.

``` r
key_vars <- c("date", "contributor", "amount", "recipient")
msc <- flag_na(msc, all_of(key_vars))
sum(msc$na_flag)
#> [1] 0
```

### Duplicates

We can also flag any record completely duplicated across every column.

``` r
msc <- flag_dupes(msc, everything())
sum(msc$dupe_flag)
#> [1] 1599
```

``` r
msc %>% 
  filter(dupe_flag) %>% 
  select(all_of(key_vars)) %>% 
  arrange(date)
#> # A tibble: 1,599 × 4
#>    date       contributor                amount recipient             
#>    <date>     <chr>                       <dbl> <chr>                 
#>  1 2009-06-22 Gouras & Associates           250 Friends of Phil Bryant
#>  2 2009-06-22 Gouras & Associates           250 Friends of Phil Bryant
#>  3 2009-07-16 MS Assoc of Realtors         1000 Friends of Phil Bryant
#>  4 2009-07-16 MS Assoc of Realtors         1000 Friends of Phil Bryant
#>  5 2009-07-17 Desoto Co Republican Party    525 Friends of Phil Bryant
#>  6 2009-07-17 Desoto Co Republican Party    525 Friends of Phil Bryant
#>  7 2009-07-17 Dr. Jason K. Coleman         1000 Friends of Phil Bryant
#>  8 2009-07-17 Dr. Jason K. Coleman         1000 Friends of Phil Bryant
#>  9 2009-07-31 Denbury Resources PAC        2000 Friends of Phil Bryant
#> 10 2009-07-31 Denbury Resources PAC        2000 Friends of Phil Bryant
#> # … with 1,589 more rows
```

### Categorical

``` r
col_stats(msc, n_distinct)
#> # A tibble: 16 × 4
#>    col              class      n         p
#>    <chr>            <chr>  <int>     <dbl>
#>  1 recipient        <chr>    400 0.00495  
#>  2 reference_number <chr>   2299 0.0284   
#>  3 filing_desc      <chr>   1987 0.0246   
#>  4 filing_id        <chr>   2299 0.0284   
#>  5 contributor      <chr>  36962 0.457    
#>  6 contributor_type <chr>     80 0.000989 
#>  7 address_line1    <chr>  35257 0.436    
#>  8 city             <chr>   4797 0.0593   
#>  9 state_code       <chr>     77 0.000952 
#> 10 postal_code      <chr>  10777 0.133    
#> 11 in_kind          <lgl>      1 0.0000124
#> 12 occupation       <chr>   8052 0.0996   
#> 13 date             <date>  2722 0.0337   
#> 14 amount           <dbl>   1911 0.0236   
#> 15 na_flag          <lgl>      1 0.0000124
#> 16 dupe_flag        <lgl>      2 0.0000247
```

### Amounts

As noted on the portal page, only contributions above \$200 need to be
itemized. Just over half of all contributions in the data are over
\$200.

``` r
summary(msc$amount)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>       0      20     208    1750     500 3200000
mean(msc$amount <= 0)
#> [1] 0.0002102295
mean(msc$amount >= 200)
#> [1] 0.5212084
```

These are the records with the minimum and maximum amounts.

``` r
glimpse(msc[c(which.max(msc$amount), which.min(msc$amount)), ])
#> Rows: 2
#> Columns: 16
#> $ recipient        <chr> "Tate for Governor", "CWA-COPE PAC"
#> $ reference_number <chr> "CF201916965", "CF202224856"
#> $ filing_desc      <chr> "Tate for Governor 8/20/2019 Primary Runoff Pre-Election Form Filing- Amended", "CWA-COPE PAC…
#> $ filing_id        <chr> "3852a8ff-1848-491b-8d54-24dc19dfed89", "616cf54a-e662-4239-bc9e-05fe7f5de87d"
#> $ contributor      <chr> "Tate Reeves", "ALLYSON GALLOWAY"
#> $ contributor_type <chr> "Other", "Individual"
#> $ address_line1    <chr> "PO Box 24355", "5336 SPORTSMAN DR."
#> $ city             <chr> "Jackson", "NESBIT"
#> $ state_code       <chr> "MS", "MS"
#> $ postal_code      <chr> "39225-4355", "38651"
#> $ in_kind          <lgl> NA, NA
#> $ occupation       <chr> "Unknown", "ATT MOBILITY/ CINGULAR"
#> $ date             <date> 2019-08-09, 2022-08-16
#> $ amount           <dbl> 3200000, 0
#> $ na_flag          <lgl> FALSE, FALSE
#> $ dupe_flag        <lgl> FALSE, FALSE
```

![](../plots/hist_amount-1.png)<!-- -->

### Dates

We can add the calendar year from `date` with `lubridate::year()`

``` r
msc <- mutate(msc, year = year(date))
```

``` r
min(msc$date)
#> [1] "2001-01-29"
sum(msc$year < 2000)
#> [1] 0
max(msc$date)
#> [1] "2025-03-26"
sum(msc$date > today())
#> [1] 2
```

``` r
msc <- msc %>% filter(date <= as.Date("2023-01-28"))
```

![](../plots/bar_year-1.png)<!-- -->

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
msc <- msc %>% 
  mutate(
    address_norm = normal_address(
      address = address_line1,
      abbs = usps_street,
      na_rep = TRUE
    )
  )
```

``` r
msc %>% 
  select(contains("address")) %>% 
  distinct() %>% 
  sample_n(10)
#> # A tibble: 10 × 2
#>    address_line1                address_norm                
#>    <chr>                        <chr>                       
#>  1 5182 DORY COURT NORTH        5182 DORY COURT N           
#>  2 169 Pine Hill Drive          169 PINE HILL DR            
#>  3 2734 Quail Run Road          2734 QUAIL RUN RD           
#>  4 6721 WASHINGTON AVE APT 25 E 6721 WASHINGTON AVE APT 25 E
#>  5 240 Westover Dr              240 WESTOVER DR             
#>  6 5255 MANHATTAN RD.           5255 MANHATTAN RD           
#>  7 1490 Highland Colony Pkwy    1490 HIGHLAND COLONY PKWY   
#>  8 16164 HWY 432                16164 HWY 432               
#>  9 P. O. Box 441887             P O BOX 441887              
#> 10 4792 MILITARY ROAD           4792 MILITARY RD
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
msc <- msc %>% 
  mutate(
    zip_norm = normal_zip(
      zip = postal_code,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  msc$postal_code,
  msc$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 × 6
#>   stage           prop_in n_distinct prop_na n_out n_diff
#>   <chr>             <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 msc$postal_code   0.717      10777 0.00194 22820   5797
#> 2 msc$zip_norm      0.968       6864 0.00276  2541   1196
```

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

``` r
msc <- msc %>% 
  mutate(
    state_norm = normal_state(
      state = state_code,
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = valid_state
    )
  )
```

``` r
msc %>% 
  filter(state_code != state_norm) %>% 
  count(state_code, state_norm, sort = TRUE)
#> # A tibble: 3 × 3
#>   state_code state_norm     n
#>   <chr>      <chr>      <int>
#> 1 Ms         MS             6
#> 2 Arkansas   AR             1
#> 3 Tx         TX             1
```

``` r
progress_table(
  msc$state_code,
  msc$state_norm,
  compare = valid_state
)
#> # A tibble: 2 × 6
#>   stage          prop_in n_distinct prop_na n_out n_diff
#>   <chr>            <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 msc$state_code    1.00         77 0.00119    32     19
#> 2 msc$state_norm    1            59 0.00148     0      1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
norm_city <- msc %>% 
  distinct(city, state_norm, zip_norm) %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("MS", "DC", "MISSISSIPPI"),
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

#### Swap

We can further improve normalization by comparing our normalized value
against the *expected* value for that record’s state abbreviation and
ZIP code. If the normalized value is either an abbreviation for or very
similar to the expected value, we can confidently swap those two.

``` r
norm_city <- norm_city %>% 
  rename(city_raw = city) %>% 
  left_join(
    y = zipcodes,
    by = c(
      "state_norm" = "state",
      "zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(city_norm, city_match),
    match_dist = str_dist(city_norm, city_match),
    city_swap = if_else(
      condition = !is.na(match_dist) & (match_abb | match_dist == 1),
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

``` r
msc <- left_join(
  x = msc,
  y = norm_city,
  by = c(
    "city" = "city_raw", 
    "state_norm", 
    "zip_norm"
  )
)
```

#### Refine

The [OpenRefine](https://openrefine.org/) algorithms can be used to
group similar strings and replace the less common versions with their
most common counterpart. This can greatly reduce inconsistency, but with
low confidence; we will only keep any refined strings that have a valid
city/state/zip combination.

``` r
good_refine <- msc %>% 
  mutate(
    city_refine = city_swap %>% 
      key_collision_merge() %>% 
      n_gram_merge(numgram = 1)
  ) %>% 
  filter(city_refine != city_swap) %>% 
  inner_join(
    y = zipcodes,
    by = c(
      "city_refine" = "city",
      "state_norm" = "state",
      "zip_norm" = "zip"
    )
  )
```

    #> # A tibble: 13 × 5
    #>    state_norm zip_norm city_swap                city_refine           n
    #>    <chr>      <chr>    <chr>                    <chr>             <int>
    #>  1 MS         39167    STARSTAR                 STAR                  3
    #>  2 OH         45209    CINCINATTI               CINCINNATI            2
    #>  3 CA         94117    SAN FRANSICO             SAN FRANCISCO         1
    #>  4 FL         32082    PONTE VERDE BEACH        PONTE VEDRA BEACH     1
    #>  5 FL         33483    DELRAY BEACHDELRAY BEACH DELRAY BEACH          1
    #>  6 GA         30005    ALPHARARETTA             ALPHARETTA            1
    #>  7 GA         30577    TOCCATA                  TOCCOA                1
    #>  8 LA         70119    NEW ORLEANS LA           NEW ORLEANS           1
    #>  9 MO         65201    COLUMBIA MO              COLUMBIA              1
    #> 10 MS         38664    ROBBINSVILLE             ROBINSONVILLE         1
    #> 11 MS         39465    PATEL                    PETAL                 1
    #> 12 PA         19130    PHILADELPHIA PA          PHILADELPHIA          1
    #> 13 VA         22309    ALEXANDRIA NDRIA         ALEXANDRIA            1

Then we can join the refined values back to the database.

``` r
msc <- msc %>% 
  left_join(good_refine, by = names(.)) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

Our goal for normalization was to increase the proportion of city values
known to be valid and reduce the total distinct values by correcting
misspellings.

| stage                    | prop_in | n_distinct | prop_na | n_out | n_diff |
|:-------------------------|--------:|-----------:|--------:|------:|-------:|
| `str_to_upper(msc$city)` |   0.975 |       3772 |   0.001 |  2009 |    641 |
| `msc$city_norm`          |   0.978 |       3690 |   0.001 |  1777 |    544 |
| `msc$city_swap`          |   0.990 |       3399 |   0.001 |   768 |    234 |
| `msc$city_refine`        |   0.991 |       3386 |   0.001 |   753 |    222 |

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
msc <- msc %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  rename_all(~str_remove(., "_raw")) %>% 
  relocate(address_clean, city_clean, state_clean, zip_clean, .after = last_col())
```

``` r
glimpse(sample_n(msc, 50))
#> Rows: 50
#> Columns: 21
#> $ recipient        <chr> "MADA AUTOPAC", "ActBlue Mississippi", "Tate for Governor", "Friends of Phil Bryant", "ActBlu…
#> $ reference_number <chr> "CF201911454", "CF201910417", "CF201918472", "CFL0004769", "CF201910417", "CF201918867", "CF2…
#> $ filing_desc      <chr> "MADA AUTOPAC State/District 10/10/2019 Periodic Report", "ActBlue Mississippi State/District…
#> $ filing_id        <chr> "11b68637-7f67-4f1a-a9e2-7b77b10e55d4", "01d43326-d40b-45ec-abbf-2792a5fd74bf", "12a4c851-e77…
#> $ contributor      <chr> "David Kelly", "BASS, STEPHANIE", "Dennis Debar", "Tony Jeff", "CHILDERS, TRAVIS", "Ronald Da…
#> $ contributor_type <chr> "Individual", "Individual", "Campaign Committee", "Individual", "Individual", "Individual", "…
#> $ address_line1    <chr> "11619 Bobby Eleuterius Blvd.", "7831 WING SPAN DR", "PO Box 1090", "3 East Bluff Drive", "10…
#> $ city             <chr> "D'Iberville", "SAN DIEGO", "Leakesville", "Brandon", "BOONEVILLE", "Oklahoma City", "Madison…
#> $ state_code       <chr> "MS", "CA", "MS", "MS", "MS", "OK", "MS", "MS", "AL", "MA", "UT", "MS", "MS", "WA", "CA", "MS…
#> $ postal_code      <chr> "39540", "92119", "39451-1090", "39047", "38829", "73134-2632", "39130-1909", "39402", "36693…
#> $ in_kind          <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ occupation       <chr> "Dealer Principle", "NOT EMPLOYED", NA, "COO", "REAL ESTATE BROKER", "Director, Distribution"…
#> $ date             <date> 2019-07-17, 2019-10-26, 2019-10-12, 2008-11-07, 2019-10-11, 2019-08-16, 2020-02-28, 2022-03-…
#> $ amount           <dbl> 50.00, 5.00, 1000.00, 500.00, 250.00, 39.84, 6.00, 10.00, 25.00, 159.81, 195.00, 5.00, 50.00,…
#> $ na_flag          <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FA…
#> $ dupe_flag        <lgl> FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
#> $ year             <dbl> 2019, 2019, 2019, 2008, 2019, 2019, 2020, 2022, 2019, 2019, 2019, 2018, 2019, 2019, 2019, 201…
#> $ address_clean    <chr> "11619 BOBBY ELEUTERIUS BLVD", "7831 WING SPAN DR", "PO BOX 1090", "3 EAST BLUFF DR", "100 GR…
#> $ city_clean       <chr> "DIBERVILLE", "SAN DIEGO", "LEAKESVILLE", "BRANDON", "BOONEVILLE", "OKLAHOMA CITY", "MADISON"…
#> $ state_clean      <chr> "MS", "CA", "MS", "MS", "MS", "OK", "MS", "MS", "AL", "MA", "UT", "MS", "MS", "WA", "CA", "MS…
#> $ zip_clean        <chr> "39540", "92119", "39451", "39047", "38829", "73134", "39130", "39402", "36693", "02116", "84…
```

1.  There are 80,862 records in the database.
2.  There are 1,599 duplicate records in the database.
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
clean_dir <- dir_create(here("state","ms", "contribs", "data", "clean"))
clean_path <- path(clean_dir, "ms_contribs_20161001-20230128.csv")
write_csv(msc, clean_path, na = "")
(clean_size <- file_size(clean_path))
#> 22.1M
```

## Upload

We can use the `aws.s3::put_object()` to upload the text file to the IRW
server.

``` r
aws_path <- path("csv", basename(clean_path))
if (!object_exists(aws_path, "publicaccountability")) {
  put_object(
    file = clean_path,
    object = aws_path, 
    bucket = "publicaccountability",
    acl = "public-read",
    show_progress = TRUE,
    multipart = TRUE
  )
}
aws_head <- head_object(aws_path, "publicaccountability")
(aws_size <- as_fs_bytes(attr(aws_head, "content-length")))
unname(aws_size == clean_size)
```
