United States Health Center Funding Diary
================
Kiernan Nicholls
2020-07-29 11:00:40

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Download](#download)
  - [Read](#read)
  - [Explore](#explore)
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
#> [1] "/home/kiernan/Code/tap/R_campfin"
```

## Data

> The Health Resources and Services Administration \[HRSA\] is an agency
> of the U.S. Department of Health and Human Services located in North
> Bethesda, Maryland. It is the primary federal agency for improving
> access to health care services for people who are uninsured, isolated
> or medically vulnerable.

Per the [HRSA supplemental funding FAQ
page](https://bphc.hrsa.gov/program-opportunities/coronavirus-disease-2019/faq):

> On Wednesday, April 8, HRSA announced the release of more than $1.3
> billion in funding provided by the Coronavirus Aid, Relief, and
> Economic Security (CARES) Act (PDF - 696 KB) (activity code H8D). For
> additional information, see the CARES technical assistance webpage.

## Download

The HRSA website lists all the health center grantees by state on
individual web pages. We can loop through each state and scrape the HTML
table and save it as a local text file.

``` r
raw_dir <- dir_create(here("us", "covid", "hrsa_cares", "data", "raw"))
```

``` r
x <- "https://bphc.hrsa.gov/emergency-response/coronavirus-cares-FY2020-awards/"
for (s in valid_abb) {
  st_url <- str_c(x, str_to_lower(s))
  st_path <- path(raw_dir, path_ext_set(s, "csv"))
  if (file_exists(st_path)) {
    next()
  } else {
    st_get <- GET(st_url)
    if (status_code(st_get) == 200) {
      content(x = st_get) %>% 
        html_node(css = "table") %>% 
        html_table(header = TRUE) %>% 
        write_csv(path = st_path)
    }
  }
}
```

``` r
raw_paths <- dir_ls(raw_dir)
```

## Read

The 59 text files can be read into a single data frame.

``` r
hrsa <- vroom(
  file = raw_paths,
  delim = ",",
  .name_repair = make_clean_names,
  col_types = cols(
    `HEALTH CENTER GRANTEE` = col_character(),
    `CITY` = col_character(),
    `STATE` = col_character(),
    `FUNDING AMOUNT` = col_number()
  )
)
```

## Explore

``` r
glimpse(hrsa)
#> Rows: 1,387
#> Columns: 4
#> $ health_center_grantee <chr> "ALEUTIAN PRIBILOF ISLANDS ASSOCIATION, INC.", "ANCHORAGE NEIGHBOR…
#> $ city                  <chr> "ANCHORAGE", "ANCHORAGE", "BETHEL", "NAKNEK", "DILLINGHAM", "FORT …
#> $ state                 <chr> "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", …
#> $ funding_amount        <dbl> 506660, 755705, 576455, 530675, 613250, 524450, 557165, 600185, 56…
tail(hrsa)
#> # A tibble: 6 x 4
#>   health_center_grantee                            city     state funding_amount
#>   <chr>                                            <chr>    <chr>          <dbl>
#> 1 CHEYENNE HEALTH AND WELLNESS CENTER              CHEYENNE WY            576080
#> 2 COMMUNITY ACTION OF LARAMIE COUNTY INC           CHEYENNE WY            533300
#> 3 COMMUNITY HEALTH CENTER OF CENTRAL WYOMING, INC. CASPER   WY            809795
#> 4 NATRONA, COUNTY OF                               CASPER   WY            535160
#> 5 POWELL HEALTH CARE COALITION                     POWELL   WY            541145
#> 6 UNIVERSITY OF WYOMING                            LARAMIE  WY            752165
```

### Missing

There are no missing values.

``` r
col_stats(hrsa, count_na)
#> # A tibble: 4 x 4
#>   col                   class     n     p
#>   <chr>                 <chr> <int> <dbl>
#> 1 health_center_grantee <chr>     0     0
#> 2 city                  <chr>     0     0
#> 3 state                 <chr>     0     0
#> 4 funding_amount        <dbl>     0     0
```

### Duplicates

There are no duplicate records.

``` r
sum(duplicated(hrsa))
#> [1] 0
```

### Geographical

``` r
count(hrsa, state, sort = TRUE)
#> # A tibble: 59 x 2
#>    state     n
#>    <chr> <int>
#>  1 CA      180
#>  2 TX       72
#>  3 NY       63
#>  4 OH       51
#>  5 FL       47
#>  6 IL       45
#>  7 PA       43
#>  8 MI       39
#>  9 NC       39
#> 10 MA       38
#> # … with 49 more rows
```

``` r
hrsa <- mutate(hrsa, across(city, normal_city, abbs = usps_city))
```

``` r
many_city <- c(valid_city, extra_city)
percent(prop_in(hrsa$city, many_city), 0.01)
#> [1] "98.20%"
```

``` r
hrsa %>% 
  filter(city %out% many_city) %>% 
  count(city, state, sort = TRUE)
#> # A tibble: 23 x 3
#>    city             state     n
#>    <chr>            <chr> <int>
#>  1 JEFFERSONVLLE    IN        2
#>  2 SN BERNRDNO      CA        2
#>  3 BAYOU LABATRE    AL        1
#>  4 CAMDEN ON GLY    WV        1
#>  5 CHRISTIANSBRG    VA        1
#>  6 COLLEGE STA      TX        1
#>  7 CORP CHRISTI     TX        1
#>  8 CPE GIRARDEAU    MO        1
#>  9 DORCHESTR CENTER MA        1
#> 10 EGG HBR TOWNSHIP NJ        1
#> # … with 13 more rows
```

### Amounts

``` r
noquote(map_chr(summary(hrsa$funding_amount), dollar))
#>       Min.    1st Qu.     Median       Mean    3rd Qu.       Max. 
#>    $95,826   $635,472   $772,535   $949,082 $1,043,090 $5,822,300
```

![](../plots/hist_amount-1.png)<!-- -->

### Add

We can add funding agency, date, and year manually.

``` r
hrsa <- mutate(
  .data = hrsa,
  .before = 1,
  date = mdy("04082020"), 
  year = year(date),
  agency = "Health Resources and Services Administration",
  govt = "US"
)
```

## Conclude

``` r
glimpse(sample_n(hrsa, 50))
#> Rows: 50
#> Columns: 8
#> $ date                  <date> 2020-04-08, 2020-04-08, 2020-04-08, 2020-04-08, 2020-04-08, 2020-…
#> $ year                  <dbl> 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, …
#> $ agency                <chr> "Health Resources and Services Administration", "Health Resources …
#> $ govt                  <chr> "US", "US", "US", "US", "US", "US", "US", "US", "US", "US", "US", …
#> $ health_center_grantee <chr> "AMMONOOSUC COMMUNITY HEALTH SERVICES INC", "THUNDER BAY COMMUNITY…
#> $ city                  <chr> "LITTLETON", "HILLMAN", "SAN DIEGO", "MINNEAPOLIS", "RENO", "LEVEL…
#> $ state                 <chr> "NH", "MI", "CA", "MN", "NV", "TX", "PA", "GA", "ND", "NY", "NC", …
#> $ funding_amount        <dbl> 693410, 769850, 601940, 763550, 762275, 811895, 679460, 914330, 63…
```

1.  There are 1,387 records in the database.
2.  There are 0 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 0 records missing key variables.
5.  The 4-digit `year` variable has been created manually.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("us", "covid", "hrsa_cares", "data", "clean"))
clean_path <- path(clean_dir, "us_hrsa_cares.csv")
write_csv(hrsa, clean_path, na = "")
file_size(clean_path)
#> 162K
file_encoding(clean_path) %>% 
  mutate(across(path, path.abbrev))
#> # A tibble: 1 x 3
#>   path                                               mime            charset 
#>   <chr>                                              <chr>           <chr>   
#> 1 ~/us/covid/hrsa_cares/data/clean/us_hrsa_cares.csv application/csv us-ascii
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

| Column                  | Type        | Definition                     |
| :---------------------- | :---------- | :----------------------------- |
| `date`                  | `double`    | Date funding released          |
| `year`                  | `double`    | Year funding released (2020)   |
| `agency`                | `character` | Distributing agency name       |
| `govt`                  | `character` | Agency government abbreviation |
| `health_center_grantee` | `character` | Health center grantee name     |
| `city`                  | `character` | Grantee city name              |
| `state`                 | `character` | Grantee state abbreviation     |
| `funding_amount`        | `double`    | CARES Act funding amount       |
