Wyoming Campaign Expenditures Data Diary
================
Yanqi Xu
2020-10-22 12:37:36

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Conclude](#conclude)
  - [Export](#export)
  - [Upload](#upload)
  - [Dictionary](#dictionary)

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

``` r
if (!require("pacman")) install.packages("pacman")
pacman::p_load_gh("irworkshop/campfin")
pacman::p_load(
  gluedown, # printing markdown
  stringdist, # levenshtein value
  tidyverse, # data manipulation
  lubridate, # datetime strings
  tidytext, # string analysis
  magrittr, # pipe opperators
  janitor, # dataframe clean
  zipcode, # clean & database
  refinr, # cluster and merge
  knitr, # knit documents
  glue, # combine strings
  scales, #format strings
  here, # relative storage
  fs, # search storage 
  rvest # scrape html
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
# where dfs this document knit?
here::here()
#> [1] "/Users/yanqixu/code/accountability_datacleaning/R_campfin"
```

## Data

The data comes from the Wyoming Secretary of State. [Link to the data
download](https://www.wycampaignfinance.gov/WYCFWebApplication/GSF_SystemConfiguration/SearchExpenditures.aspx "source").

In our last update, we downloaded 11 years worth of data (2008-2018) in
8 columns, Filer Type, Filer Name, Payee, Purpose, Date, City,State &
ZIP, Filing Status and Amount. This time we’ll download the data for the
2020 election cycle.

### About

> Wyoming’s Campaign Finance Information System (WYCFIS) exists to
> provide a mechanism for online filing of campaign finance information
> and to provide full disclosure to the public. This website contains
> detailed financial records and related information that candidates,
> committees, organizations and parties are required by law to disclose.
> Wyoming requires all statewide candidates, candidate committees,
> political action committees, organizations and political parties to
> file electronically online using this system.

## Import

### Download

Download raw, **immutable** data file. Go to [the download
site](https://www.wycampaignfinance.gov/WYCFWebApplication/GSF_SystemConfiguration/SearchExpenditures.aspx),
leave the fields blank, and click the “All” tab and hit “Search”. After
the table is populated, click “Export”

``` r
# create a directory for the raw data
raw_dir <- here("wy", "expends", "data", "raw")
dir_create(raw_dir)
```

### Read

## Explore

There are `nrow(wy)` records of `length(wy)` variables in the full
database.

``` r
head(wy)
```

    #> # A tibble: 6 x 8
    #>   filer_type   filer_name      payee      purpose   date       city_state_zip  filing_status amount
    #>   <chr>        <chr>           <chr>      <chr>     <date>     <chr>           <chr>          <dbl>
    #> 1 CANDIDATE    "CLARK STITH "  APG OF TH… ADVERTIS… 2020-10-20 ROCK SPRINGS, … FILED            257
    #> 2 CANDIDATE C… "FRIENDS OF MI… KAIROS CO… ADVERTIS… 2020-10-20 RIVERTON, WY 8… FILED             50
    #> 3 CANDIDATE    "ALBERT SOMMER… WIND RIVE… IT SERVI… 2020-10-16 PINEDALE, WY 8… FILED            175
    #> 4 CANDIDATE C… "COMMITTEE TO … UNITED ST… RENT      2020-10-15 <NA>            FILED             46
    #> 5 CANDIDATE    "JACQUELIN REN… RAWLINS D… ADVERTIS… 2020-10-13 RAWLINS, WY 82… FILED            500
    #> 6 CANDIDATE    "ALBERT SOMMER… PINEDALE … ADVERTIS… 2020-10-05 PINEDALE, WY 8… FILED            325

``` r
tail(wy)
```

    #> # A tibble: 6 x 8
    #>   filer_type   filer_name     payee     purpose     date       city_state_zip  filing_status amount
    #>   <chr>        <chr>          <chr>     <chr>       <date>     <chr>           <chr>          <dbl>
    #> 1 CANDIDATE C… COMMITTEE TO … DEPARTME… TAXES       2019-01-02 CHEYENNE, WY 8… FILED           51.2
    #> 2 CANDIDATE C… FRIENDS OF MA… BLACK HI… UTILITIES … 2019-01-02 RAPID CITY, SD… FILED          244. 
    #> 3 CANDIDATE C… FRIENDS OF MA… GOOGLE A… IT SERVICES 2019-01-02 MOUNTAIN VIEW,… FILED           70  
    #> 4 CANDIDATE C… FRIENDS OF MA… SPECTRUM… PHONE       2019-01-02 CINCINNATI, OH… FILED          190. 
    #> 5 CANDIDATE C… LANDEN FOR LE… BIG O TI… OTHER: VEH… 2019-01-02 CASPER, WY 826… FILED         1232. 
    #> 6 CANDIDATE C… PERKINS FOR S… DREW PER… OTHER: GIF… 2019-01-01 CASPER, WY 826… FILED           66.2

``` r
glimpse(wy)
```

    #> Rows: 2,630
    #> Columns: 8
    #> $ filer_type     <chr> "CANDIDATE", "CANDIDATE COMMITTEE", "CANDIDATE", "CANDIDATE COMMITTEE", "…
    #> $ filer_name     <chr> "CLARK STITH ", "FRIENDS OF MICHAEL V. BAILEY", "ALBERT SOMMERS ", "COMMI…
    #> $ payee          <chr> "APG OF THE ROCKIES", "KAIROS COMMUNICATIONS", "WIND RIVER WEB SERVICES",…
    #> $ purpose        <chr> "ADVERTISING - NEWSPAPER", "ADVERTISING - MISC.", "IT SERVICES", "RENT", …
    #> $ date           <date> 2020-10-20, 2020-10-20, 2020-10-16, 2020-10-15, 2020-10-13, 2020-10-05, …
    #> $ city_state_zip <chr> "ROCK SPRINGS, WY 82901", "RIVERTON, WY 82501", "PINEDALE, WY 82941", NA,…
    #> $ filing_status  <chr> "FILED", "FILED", "FILED", "FILED", "FILED", "FILED", "FILED", "FILED", "…
    #> $ amount         <dbl> 257.00, 50.00, 175.00, 46.00, 500.00, 325.00, 525.00, 12.60, 6.00, 300.00…

### Distinct

The variables range in their degree of distinctness.

``` r
wy %>% col_stats(n_distinct)
```

    #> # A tibble: 8 x 4
    #>   col            class      n        p
    #>   <chr>          <chr>  <int>    <dbl>
    #> 1 filer_type     <chr>      2 0.000760
    #> 2 filer_name     <chr>    167 0.0635  
    #> 3 payee          <chr>    971 0.369   
    #> 4 purpose        <chr>    131 0.0498  
    #> 5 date           <date>   379 0.144   
    #> 6 city_state_zip <chr>    245 0.0932  
    #> 7 filing_status  <chr>      4 0.00152 
    #> 8 amount         <dbl>   1649 0.627

We can explore the distribution of the least distinct values with
`ggplot2::geom_bar()`.

![](../plots/plot_bar-1.png)<!-- -->

Or, filter the data and explore the most frequent discrete data.

![](../plots/plot_bar2-1.png)<!-- -->

### Missing

We will flag the entries with an empty `city_state_zip` column.

``` r
wy %>% col_stats(count_na)
```

    #> # A tibble: 8 x 4
    #>   col            class      n      p
    #>   <chr>          <chr>  <int>  <dbl>
    #> 1 filer_type     <chr>      0 0     
    #> 2 filer_name     <chr>      0 0     
    #> 3 payee          <chr>      0 0     
    #> 4 purpose        <chr>      0 0     
    #> 5 date           <date>     0 0     
    #> 6 city_state_zip <chr>     81 0.0308
    #> 7 filing_status  <chr>      0 0     
    #> 8 amount         <dbl>      0 0

We will flag any records with missing values in the key variables used
to identify an expenditure. There are 0 columns in city\_state\_zip that
are NAs.

``` r
wy <- wy %>% flag_na(city_state_zip)
```

### Duplicates

There are no duplicates.

``` r
wy_dupes <- flag_dupes(wy)
```

### Ranges

#### Amounts

``` r
summary(wy$amount)
```

    #>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
    #>     0.45    27.76   100.00   395.51   423.06 55000.00

See how the campaign expenditures were distributed

``` r
wy %>% 
  ggplot(aes(x = amount)) + 
  geom_histogram(fill = dark2[1]) +
  scale_x_continuous(
    trans = "log10", labels = dollar) +
  labs(title = "Wyoming Campaign Expenditures ")
```

![](../plots/unnamed-chunk-2-1.png)<!-- -->

Distribution of expenses by filer
![](../plots/box_plot_by_type-1.png)<!-- -->

### Dates

The dates seem to be reasonable, with records dating back to 1.7897^{4}
till 1.8414^{4}, 1.8445^{4}, 1.8402289^{4}, 1.847^{4}, 1.8555^{4}

``` r
summary(wy$date)
```

    #>         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
    #> "2019-01-01" "2020-06-01" "2020-07-02" "2020-05-20" "2020-07-27" "2020-10-20"

``` r
sum(wy$date > today())
```

    #> [1] 0

### Year

Add a `year` variable from `date` after `col_date()` using
`lubridate::year()`.

``` r
wy <- wy %>% mutate(year = year(date))
```

![](../plots/year_count_bar-1.png)<!-- -->

![](../plots/amount_year_bar-1.png)<!-- -->

``` r
wy %>% 
  mutate(month = month(date)) %>% 
  mutate(on_year = is_even(year)) %>%
  group_by(on_year, month) %>% 
  summarize(mean = mean(amount)) %>% 
  ggplot(aes(month, mean)) +
  geom_line(aes(color = on_year), size = 2) +
  scale_y_continuous(labels = dollar) +
  scale_x_continuous(labels = month.abb, breaks = 1:12) +
  scale_color_brewer(
    type = "qual",
    palette = "Dark2"
  ) +
  labs(
    title = "Wyoming Mean Expenditure Amount by Month",
    caption = "Source: Wyoming Secretary of State",
    color = "Election Year",
    x = "Month",
    y = "Amount"
  )
```

![](../plots/amount_month_line-1.png)<!-- --> \#\# Wrangle \#\#\#
Indexing

``` r
wy <- tibble::rowid_to_column(wy, "id")
```

The lengths of city\_state\_zip column differ, and regular expressions
can be used to separate the components.

The original data the city, state, and ZIP all in one column. The
following code separates them.

### Zipcode

First, we’ll extract any numbers whose lengths range from 1 to 5 to
`zip`, whose proportion of valid zip is pretty high and doesn’t need
further normalization.

``` r
wy <- wy %>% 
  mutate(
    zip = city_state_zip %>% 
      str_extract("\\d{2,5}") %>% 
      normal_zip(na_rep = TRUE))
sample(wy$zip, 10)
```

    #>  [1] "82401" NA      "20001" NA      NA      NA      NA      "82401" "82801" "82072"

``` r
prop_in(wy$zip, valid_zip, na.rm = T)
```

    #> [1] 0.9960578

### State

In this regex, state is considered to consist of two upper-case letters
following a space, or two upper-case letters with a trailing space at
the end.

``` r
wy <- wy %>% 
  mutate( state =
            trimws(str_extract(wy$city_state_zip, "\\s([A-Z]{2})\\s|^([A-Z]{2})\\s$")))
count_na(wy$state)
```

    #> [1] 81

``` r
prop_in(wy$state, valid_state, na.rm = T)
```

    #> [1] 0.9984308

The states are mostly valid and don’t need to be cleaned.

### City

First, we can get a list of incorporated cities and towns in Wyoming.
The Wyoming State Archives provided the list in a web table. We use the
`rvest` package to scrape the names of Wyoming cities and towns.
<http://wyoarchives.state.wy.us/index.php/incorporated-cities>.

``` r
wyoming_cities_page <- read_html("http://wyoarchives.state.wy.us/index.php/incorporated-cities")

wy_city <- wyoming_cities_page %>%  html_nodes("tr") %>% 
  html_text()

wy_city <- str_match(wy_city[2:100],"(^\\D{2,})\\r")[,2]
wy_city <- toupper(wy_city[!is.na(wy_city)])
```

``` r
valid_city <- unique(c(wy_city,valid_city))
```

Cleaning city values is the most complicated. This process involves four
steps:

1.  Prepare raw city values by removing invalid data and reducing
    inconsistencies
2.  Match prepared city values with the *actual* city name of that
    record’s ZIP code
3.  swap prepared city values with the ZIP code match *if* only 1 edit
    is needed
4.  Refine swapped city values with key collision and n-gram
    fingerprints

#### Normalize

Find the cities before a comma first, if not, find the non-numeric
string.

``` r
wy <- wy %>% 
  mutate(
    city_raw = str_match(wy$city_state_zip,"(^\\D{3,}),")[,2]) 

wy <- wy %>% mutate(city_raw=ifelse(is.na(city_raw)==TRUE, 
               str_extract(city_state_zip, "[A-Z]{4,}"), paste(city_raw)))

wy$city_raw <- wy$city_raw %>% 
  str_replace("^ROCK$", "ROCK SPRING") 
```

``` r
count_na(wy$city_raw)
#> [1] 1038
n_distinct(wy$city_raw)
#> [1] 160
prop_in(wy$city_raw, valid_city, na.rm = TRUE)
#> [1] 0.9717337
sum(unique(wy$city_raw) %out% valid_city)
#> [1] 30
```

1592 cities were found.

``` r
wy <- wy %>% mutate(city_norm = normal_city(city_raw))
```

#### Swap

We can further improve normalization by comparing our normalized value
against the *expected* value for that record’s state abbreviation and
ZIP code. If the normalized value is either an abbreviation for or very
similar to the expected value, we can confidently swap those two.

``` r
wy <- wy %>% 
  left_join(
    y = zipcodes,
    by = c(
      "state" = "state",
      "zip" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(city_norm, city_match),
    match_dist = str_dist(city_norm, city_match),
    city_swap = if_else(
      condition = !is.na(match_dist) & (match_abb | match_dist) == 1,
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

### Lookup

This process is manual lookup and correction

``` r
wy$city_swap <- wy$city_swap %>% 
  str_replace("^CAS$", "CASPER") %>% 
  str_replace("^CA$", "CASPER") %>% 
  str_replace("^RS$","ROCK SPRINGS") %>% 
  str_replace("^AF$", "AFTON") %>% 
  str_replace("^M$", "MOUNTAIN VIEW") %>% 
  str_replace("^GR$", "GREEN RIVER") %>% 
  na_if("WY") %>% 
  str_replace(" WYOMING","") %>% 
  str_replace("^SLC$", "SALT LAKE CITY") %>% 
  str_replace("^COD$", "CODY") 

n_distinct(wy$city_swap)
```

    #> [1] 141

#### Refine

The [OpenRefine](https://openrefine.org/) algorithms can be used to
group similar strings and replace the less common versions with their
most common counterpart. This can greatly reduce inconsistency, but with
low confidence; we will only keep any refined strings that have a valid
city/state/zip combination.

``` r
good_refine <- wy %>% 
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
      "state" = "state",
      "zip" = "zip"
    )
  )
```

    #> # A tibble: 0 x 5
    #> # … with 5 variables: state <chr>, zip <chr>, city_swap <chr>, city_refine <chr>, n <int>

Then we can join the refined values back to the database.

``` r
wy <- wy %>% 
  left_join(good_refine) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

| stage        | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :----------- | -------: | ----------: | -------: | -----: | ------: |
| city\_raw)   |    0.972 |         160 |    0.395 |     44 |      29 |
| city\_norm   |    0.975 |         157 |    0.395 |     40 |      26 |
| city\_swap   |    0.997 |         141 |    0.395 |      5 |       6 |
| city\_refine |    0.997 |         141 |    0.395 |      5 |       6 |

Manually change the city\_refine fields due to
overcorrection/undercorrection.

``` r
wy$city_refine <- wy$city_refine %>% 
  str_replace("^RIO VISTA$", "LAGO VISTA") %>% 
  str_replace("^OGEN$", "OGDEN") %>%
  str_replace("^ANNIPOLIS$", "ANNAPOLIS") %>% 
  str_replace("^LAR$", "LARAMIE") %>%
  str_replace("^LARA$", "LARAMIE") %>%
  str_replace("^CHE$", "CHEYENNE") %>%
  str_replace("^COLO SPGS$", "COLORADO SPRINGS") %>%
  str_replace("^WASHNGTON$", "WASHINGTON") %>% 
  str_replace("^WASHINGTON DC$", "WASHINGTON") %>% 
  str_replace("^ST.\\s", "SAINT " ) %>% 
  str_replace("^PINE$", "PINEDALE")
```

This process reduces the number of distinct city value by 19

``` r
n_distinct(wy$city_raw)
#> [1] 160
n_distinct(wy$city_norm)
#> [1] 157
n_distinct(wy$city_swap)
#> [1] 141
n_distinct(wy$city_refine)
#> [1] 141
```

Each step of the cleaning process reduces the number of distinct city
values. There are 1592 entries of cities identified in the original data
matching the regex with 160 distinct values, after the swap and refine
processes, there are 1592 entries with 141 distinct values.

## Conclude

1.  There are 2630 records in the database
2.  There are 0 records with duplicate filer, recipient, date, *and*
    amount (flagged with `dupe_flag`)
3.  The ranges for dates and amounts are reasonable
4.  Consistency has been improved with `stringr` package and custom
    `normal_*()` functions.
5.  The five-digit `zip_clean` variable has been created with
    `zipcode::clean.zipcode()`
6.  The `year` variable has been created with `lubridate::year()`
7.  There are 0 records with missing `name` values and 0 records with
    missing `date` values (both flagged with the `na_flag`)

## Export

``` r
wy <- wy %>% 
  rename(city_clean = city_refine) %>% 
  select(
    -city_raw,
    -city_norm,
    -city_swap,
    -id
  )
```

``` r
clean_dir <- here("wy", "expends", "data", "processed")
clean_path <- glue("{clean_dir}/wy_expends_clean.csv")

dir_create(clean_dir)
wy %>% 
  write_csv(
    path = clean_path,
    na = ""
  )

file_size(clean_path)
```

    #> 349K

``` r
file_encoding(clean_path)
```

    #> # A tibble: 1 x 3
    #>   path                                                                                mime  charset
    #>   <fs::path>                                                                          <chr> <chr>  
    #> 1 /Users/yanqixu/code/accountability_datacleaning/R_campfin/wy/expends/data/processe… <NA>  <NA>

## Upload

Using the `aws.s3` package, we can upload the file to the IRW server.

``` r
s3_path <- path("csv", basename(clean_path))
put_object(
  file = clean_path,
  object = s3_path, 
  bucket = "publicaccountability",
  acl = "public-read",
  multipart = TRUE,
  show_progress = TRUE
)
as_fs_bytes(object_size(s3_path, "publicaccountability"))
```

## Dictionary

The following table describes the variables in our final exported file:

| Column           | Type        | Definition                             |
| :--------------- | :---------- | :------------------------------------- |
| `filer_type`     | `character` | Type of filer                          |
| `filer_name`     | `character` | Name of filer                          |
| `payee`          | `character` | Payee name                             |
| `purpose`        | `character` | Expenditure purpose                    |
| `date`           | `double`    | Expenditure date                       |
| `city_state_zip` | `character` | Expenditure city, state and zip        |
| `filing_status`  | `character` | Filing status                          |
| `amount`         | `double`    | Expenditure amount                     |
| `na_flag`        | `logical`   | Flag for missing name, city or address |
| `year`           | `double`    | Calendar year of expenditure date      |
| `zip`            | `character` | 5-digit ZIP code                       |
| `state`          | `character` | 2-letter state abbreviation            |
| `city_clean`     | `character` | Normalized city name                   |
