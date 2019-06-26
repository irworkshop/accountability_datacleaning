Data Diary
================
First Last
`format(Sys.time())`

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
  - [Conclude](#conclude)
  - [Write](#write)

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
# install.packages("pacman")
pacman::p_load(
  stringdist, # levenshtein value
  tidyverse, # data manipulation
  lubridate, # datetime strings
  magrittr, # pipe opperators
  RSocrata, # read soda api
  janitor, # dataframe clean
  zipcode, # clean & database
  explore, # basic exploration
  batman, # parse yes & no
  refinr, # cluster & merge
  rvest, # scrape website
  knitr, # knit documents
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
# where dfs this document knit?
here::here()
```

## Data

Describe *where* the data is coming from. [Link to the data
download](https://example.com "source") page if possible.

Describe the data set that is going to be cleaned. A file name, age, and
unit of observation.

### About

> If the publisher provides any information on the file, you can
> directly quote that here.

### Variables

Often the publisher will provide a dictionary to describe the variables
in the data (and potentially the key pairs between many relational
tables). [Link to the dictionary](https://example.com).

`variable_name`:

> Directly quote the definition given for variables of interest.

## Import

### Download

Download raw, immutable data file.

``` r
raw_dir <- here("df", "type", "data", "raw")
dir_create(raw_dir)
download.file(
  url = url,
  destfile = here(raw_dir, "file_name.zip")
)
```

### Unzip

If needed, unzip into the same directory

``` r
unzip(
  zipfile = here(raw_dir, "file_name.zip"),
  exdir = raw_dir
)
```

### Read

``` r
df <- read_delim(
  file = here(raw_dir, "file_name.csv"),
  delim = ",",
  col_types = cols(
    
  )
)
```

## Explore

There are `nrow(df)` records of `length(df)` variables in the full
database.

``` r
describe(df)
glimpse(sample_frac(df))
```

### Distinct

The variables range in their degree of distinctness.

``` r
df %>% 
  map(n_distinct) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_distinct") %>% 
  mutate(prop_distinct = round(n_distinct / nrow(df), 4)) %>%
  print(n = length(df))
```

We can explore the distribution of the least distinct values with
`ggplot2::geom_bar()`.

Or, filter the data and explore the most frequent discrete data.

### Missing

The variables also vary in their degree of values that are `NA`
(missing).

``` r
df %>% 
  map(function(var) sum(is.na(var))) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_na") %>% 
  mutate(prop_na = n_na / nrow(df)) %>% 
  print(n = length(df))
```

We will flag any records with missing values in the key variables used
to identify an expenditure.

``` r
df <- df %>% mutate(na_flag = is.na(var))
```

### Duplicates

``` r
df_dupes <- df %>% 
  get_dupes(
    
    ) %>% 
  mutate(dupe_flag = TRUE)

nrow(df_dupes)
```

``` r
df <- df %>% 
  left_join(df_dupes, by = "id") %>% 
  mutate(dupe_flag = !is.na(dupe_flag))
```

### Ranges

Explore the continuous variables with `ggplot2::geom_histogram()` and
`base::summary()`

#### Amounts

Below are the smallest and largest expenditures.

``` r
glimpse(df %>% filter(amount == min(amount, na.rm = T)))
glimpse(df %>% filter(amount == max(amount, na.rm = T)))
```

### Dates

``` r
max(df$date, na.rm = TRUE)
sum(df$date > today(), na.rm = T)
```

``` r
min(df$date, na.rm = TRUE)
sum(year(df$date) < 2007, na.rm = T)
```

## Wrangle

### Year

Add a `year` variable from `date` after `col_date()` using
`lubridate::year()`.

``` r
df <- df %>% mutate(year = year(date))
```

### Address

The `address` variable should be minimally cleaned by removing
punctuation and fixing white-space.

``` r
df <- df %>% 
  mutate(
    address_clean = address %>% 
      str_to_upper() %>% 
      str_replace("-", " ") %>% 
      str_remove_all("[:punct:]") %>% 
      str_trim() %>% 
      str_squish() %>% 
      na_if("") %>% 
      na_if("NA")
  )
```

### Zipcode

Use the `zipcodes::clean.zipcodes()` function to strips the ZIP+4 digits
and adds leading zeroes to three or four digit strings. We will also
make some common invalid zips `NA`.

``` r
df <- df %>% 
  mutate(zip_clean = zip %>% 
           clean.zipcodes() %>% 
           na_if("00000") %>% 
           na_if("11111") %>% 
           na_if("99999")
  )

df$zip_clean[which(nchar(df$zip_clean) != 5)] <- NA
```

### State

Using comprehensive list of state abbreviations in the Zipcodes
database, we can isolate invalid `state` values and manually correct
them.

``` r
valid_state <- c(unique(zipcode$state), "AB", "BC", "MB", "NB", "NL", "NS", "ON", "PE", "QC", "SK")
length(valid_state)
setdiff(valid_state, state.abb)
```

``` r
df %>% 
  filter(state %out% valid_state) %>% 
  filter(!is.na(state)) %>% 
  select(
    id,
    address,
    city,
    state,
    zip
  ) %>% 
  print_all()
```

If the `state` abbreviation is invalid, use the `city` and `zip` values
for that record to manually correct the abbreviation where possible. If
it can’t be manually corrected, make the value `NA`.

``` r
df$state_clean <- df$state %>% 
  str_replace("DG", "DF") %>% # add match
  str_remove("[:punct:]") %>% 
  na_if("")   %>% # empty
  na_if("RE") %>% # requested
  na_if("99") %>% # df zip
```

### City

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

#### Prep

``` r
source(here("R", "prep_city.R"))
df <- df %>% 
  mutate(
    city_prep = prep_city(
      cities = city,
      na = read_lines(here("R", "na_city.csv")),
      abbs = c("DF", "OR", "ID", "DC", "BC")
    )
  )
```

#### Swap

``` r
df <- df %>%
  left_join() %>%
  rename() %>%
  mutate(
    match_dist = stringdist(),
    city_swap = if_else(match_dist == 1)
  )
```

#### Refine

``` r
valid_city <- unique(zipcode$city)
```

``` r
df_refined <- df %>%
  filter(var == "") %>% 
  filter(match_dist != 1) %>% 
  mutate(
    city_refine = var %>% 
      key_collision_merge(dict = valid_city) %>% 
      n_gram_merge(numgram = 1),
    refined = (city_swal != city_refine)
  ) %>% 
  filter(refined) %>% 
  select(
    
  ) %>% 
  rename(
    
  )
```

#### Review

``` r
df_refined %>% 
  count(city_swap, city_refine) %>% 
  arrange(desc(n))
```

``` r
refined_values <- unique(df_refined$city_refine)
count_refined <- tibble(
  city_refine = refined_values, 
  refine_count = NA
)

for (i in seq_along(refined_values)) {
  count_refined$refine_count[i] <- sum(str_detect(df$city_swap, refined_values[i]), na.rm = TRUE)
}

swap_values <- unique(df_refined$city_swap)
count_swap <- tibble(
  city_swap = swap_values, 
  swap_count = NA
)

for (i in seq_along(swap_values)) {
  count_swap$swap_count[i] <- sum(str_detect(df$city_swap, swap_values[i]), na.rm = TRUE)
}
```

``` r
df_refined %>% 
  left_join(count_swap) %>% 
  left_join(count_refined) %>%
  select(
    city_match,
    city_swap,
    city_refine,
    swap_count,
    refine_count
  ) %>% 
  mutate(diff_count = refine_count - swap_count) %>%
  mutate(refine_dist = stringdist(city_swap, city_refine)) %>%
  distinct() %>%
  arrange(city_refine) %>% 
  print_all()
```

``` r
df_refined$city_refine <- df_refined$city_refine %>% 
  str_replace("^BAD FIX$", "GOOD FIX") %>% 
  str_replace("^BAD FIX$", "ORIGINAL") %>% 
  na_if("NA")

refine_table <- df_refined %>% 
  select(id, city_refine)
```

#### Merge

``` r
df <- df %>% 
  left_join(refine_table, by = "id") %>% 
  mutate(city_clean = coalesce(city_refine, city_swap))
```

Each step of the cleaning process reduces the number of distinct city
values.

## Conclude

1.  There are `nrow(df)` records in the database
2.  There are `sum(df$dupe_flag)` records with duplicate filer,
    recipient, date, *and* amount (flagged with `dupe_flag`)
3.  The ranges for dates and amounts are reasonable
4.  Consistency in strings has been fixed with `city_prep()` and the
    `stringr` package
5.  The five-digit `zip_clean` variable has been created with
    `zipcode::clean.zipcode()`
6.  The `expenditure_year` variable has been created with
    `lubridate::year()`
7.  There are `sum(is.na(df$name))` records with missing `name` values
    and `sum(is.na(df$date))` records with missing `date` values (both
    flagged with the `na_flag`)

## Write

``` r
df %>% 
  select(
   
  ) %>% 
  write_csv(
    path = here(),
    na = ""
  )
```
