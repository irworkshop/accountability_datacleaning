---
title: "Indiana Expenditures"
author: "Kiernan Nicholls & Aarushi Sahejpal"
date: "`r Sys.time()`"
output:
  github_document: 
    df_print: tibble
    toc: true
    toc_dept: 2
editor_options: 
  chunk_output_type: console
---

<!-- Place comments regarding knitting here -->

```{r setup, include=FALSE, purl=FALSE}
library(knitr)
opts_chunk$set(
  eval = TRUE,
  echo = TRUE,
  warning = FALSE,
  message = FALSE,
  error = FALSE,
  # it's nice to un-collapse df print
  collapse = TRUE,
  comment = "#>",
  fig.path = "../plots/",
  fig.width = 10,
  dpi = 300
)
options(width = 99)
set.seed(5)
```

## Project

The Accountability Project is an effort to cut across data silos and give journalists, policy
professionals, activists, and the public at large a simple way to search across huge volumes of
public data about people and organizations.

Our goal is to standardizing public data on a few key fields by thinking of each dataset row as a
transaction. For each transaction there should be (at least) 3 variables:

1. All **parties** to a transaction
2. The **date** of the transaction
3. The **amount** of money involved

## Objectives

This document describes the process used to complete the following objectives:

1. How many records are in the database?
1. Check for duplicates
1. Check ranges
1. Is there anything blank or missing?
1. Check for consistency issues
1. Create a five-digit ZIP Code called `ZIP5`
1. Create a `YEAR` field from the transaction date
1. Make sure there is data on both parties to a transaction

## Packages

The following packages are needed to collect, manipulate, visualize, analyze, and communicate
these results. The `pacman` package will facilitate their installation and attachment.

The IRW's `campfin` package will also have to be installed from GitHub. This package contains
functions custom made to help facilitate the processing of campaign finance data.

```{r load_packages, message=FALSE, dfrning=FALSE, error=FALSE}
if (!require("pacman")) install.packages("pacman")
pacman::p_load_gh("irworkshop/campfin")
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  tidytext, # text analysis
  magrittr, # pipe opperators
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
  rvest, # scrape html pages
  knitr, # knit documents
  vroom, # read files fast
  glue, # combine strings
  here, # relative storage
  fs # search storage 
)
```

This document should be run as part of the `R_campfin` project, which lives as a sub-directory of
the more general, language-agnostic [`irworkshop/accountability_datacleaning`][01] GitHub
repository.

The `R_campfin` project uses the [RStudio projects][02] feature and should be run as such. The
project also uses the dynamic `here::here()` tool for file paths relative to _your_ machine.

```{r where_here, collapse=TRUE}
# where dfs this document knit?
here::here()
```

[01]: https://github.com/irworkshop/accountability_datacleaning "TAP repo"
[02]: https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects "Rproj"

## Data

Data is obtained from the [Indiana Election Division][03] (IED). Their data can be downloaded as
anual files on their [data download page][04].

> The campaign finance database contains detailed financial records that campaigns and committees
are required by law to disclose. Through this database, you can view contribution and expense
records from candidate, PAC, regular party, legislative caucus, and exploratory committees. You can
select specific reports based on the candidate, office, party, caucus, or PAC name or keyword. You
can also search across one or more finance reports according to specific criteria that you choose.
You can review the results on screen, print them, or extract the information for further analysis.

The IDE provides [some background information][05] on their campaign finance database.

> ### What is the quality of the data?  
The information presented in the campaign finance database is, to the best of our ability, an
accurate representation of the reports filed with the Election Division. This information is being
provided as a service to the public, has been processed by the Election Division and should be
cross-referenced with the original report on file with the Election Division.
> 
> Some of the information in the campaign finance database was submitted in electronic form. Most
of the information was key-entered from paper reports. Sometimes items which are inconsistent with
filing requirements, such as incorrect codes or incorrectly formatted or blank items, are present
in the results of a query. They are incorrect or missing in the database because they were
incorrect or missing on the reports submitted to the Election Division. For some incorrect or
missing data in campaign finance reports, the Election Division has requested that the filer supply
an amended report. The campaign finance database will be updated to reflect amendments received.

> ### What does the database contain?  
> By Indiana law, candidates and committees are required to disclose detailed financial records of
contributions received and expenditures made and debts owed by or to the committee. For committees,
the campaign finance database contains all contributions, expenditures, and debts reported to the
Election Division since January 1, 1998.

[03]: http://campaignfinance.in.gov/PublicSite/Homepage.aspx
[04]: http://campaignfinance.in.gov/PublicSite/Reporting/DataDownload.aspx
[05]: http://campaignfinance.in.gov/PublicSite/AboutDatabase.aspx

## Import

We can import each file into R as a single data frame to be explored, wrangled, and exported
as a single file to be indexed on the TAP database.

### Download

```{r raw_dir}
raw_dir <- here("in", "expends", "data", "raw")
dir_create(raw_dir)
```

> This page provides comma separated value (CSV) downloads of contribution and expenditure data for each reporting year in a zipped file format. These files can be downloaded and imported into other applications (Microsoft Excel, Microsoft Access, etc.). This data was extracted from the Campaign Finance database as it existed as of 2/5/2023 2:48 PM. 

The download URL to each file follows a consistent structure. We can create a URL for each file
by using `glue::glue()` to change the year in the character string.

```{r glue_urls}
base_url <- "http://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads"
exp_urls <- glue("{base_url}/{2000:2023}_ExpenditureData.csv.zip")
```

The files range in size, which we can check before downloading with `campfin::url_file_size()`. 

```{r check_file_sizes}
file_sizes <- map_dbl(exp_urls, url_file_size)
number_bytes(sum(file_sizes))
```

If the files haven't yet been downloaded, we can download each to the `/in/data/raw` subdirectory.

```{r download_raw}
if (!all_files_new(raw_dir, "*.zip$")) {
  for (year_url in exp_urls) {
    year_file <- glue("{raw_dir}/{basename(year_url)}")
    download.file(
      url = year_url,
      destfile = year_file
    )
  }
}
```

### Read

We can read each file as a data frame into a list of data frames by using `purrr::map_df()` and 
`readr::read_delim()`. We don't need to unzip the files.

```{r map_read_raw}
ind <- map_df(
  .x = dir_ls(raw_dir, glob = "*.csv.zip$"),
  .f = read_delim,
  delim = ",",
  escape_backslash = FALSE,
  escape_double = FALSE,
  col_types = cols(
    .default = col_character(),
    Amount = col_double(),
    Expenditure_Date = col_date("%Y-%m-%d %H:%M:%S"),
    Amended = col_logical()
  )
) %>% clean_names("snake")
```

There were about a dozen parsing errors, so we will remove these rows by using `dplyr::filter()` to
remove any record with an invalid `file_number` (typically numeric nominal values) or 
`committee_type`/`expenditure_code` values (fixed categorical).

```{r filter_broken}
ind <- ind %>%
  filter(
    str_detect(file_number, "\\d+"),
    str_detect(committee_type, "^\\d+.\\d+$", negate = TRUE),
    expenditure_code %out% "Thomas Lewis Andrews"
  )
```

## Explore

```{r glimpse}
head(ind)
tail(ind)
glimpse(sample_frac(ind))
```

### Missing

```{r glimpse_na}
glimpse_fun(ind, count_na)
```

There are a fairly significant number of records missing one of the four variables needed to fully
identify a transaction (who, what, and when). We will use `campfin::flag_na()` to flag them with
`TRUE` values in the new `na_flag` variable. Most of these records are missing the payee `name`
value.

```{r flag_na}
ind <- ind %>% flag_na(committee, name, expenditure_date, amount)
sum(ind$na_flag)
percent(mean(ind$na_flag))
```

### Duplicates

There are very few duplicate records in the database. They have `TRUE` values in the new 
`dupe_flag` variable.

```{r flag_dupes}
ind <- mutate(ind, dupe_flag = duplicated(ind))
sum(ind$dupe_flag)
percent(mean(ind$dupe_flag))
```

### Categorical

```{r glimpse_distinct}
glimpse_fun(ind, n_distinct)
```

For categorical variables, we can use `ggplo2::geom_col()` to explore the count of each variable.

```{r comm_type_bar, echo=FALSE}
explore_plot(
  data = ind, 
  var = committee_type,
  title = "Indiana Expenditures by Committe Type",
  caption = "Source: Indiana Election Division"
)
```

```{r expend_code_bar, echo=FALSE}
explore_plot(
  data = ind,
  var = expenditure_code,
  title = "Indiana Expenditures by Committe Type",
  caption = "Source: Indiana Election Division"
)
```

```{r occupation_bar, echo=FALSE}
explore_plot(
  data = ind %>% drop_na(occupation) %>% filter(occupation != "Other"),
  var = occupation,
  flip = TRUE,
  title = "Indiana Expenditures by Payee Occupation",
  subtitle = "Without Missing or 'Other'",
  caption = "Source: Indiana Election Division"
)
```

```{r expend_type_bar, echo=FALSE}
explore_plot(
  data = ind,
  var = expenditure_type,
  flip = TRUE,
  title = "Indiana Expenditures by Expenditure Use",
  caption = "Source: Indiana Election Division"
)
```

```{r purpose_word_bar, echo=FALSE, fig.height=10}
ind %>% 
  drop_na(purpose) %>% 
  unnest_tokens(word, purpose) %>% 
  count(word, sort = TRUE) %>% 
  anti_join(stop_words, by = "word") %>% 
  filter(word != "contribution") %>% 
  head(35) %>%
  ggplot(aes(x = reorder(word, n), y = n)) +
  geom_col(aes(fill = n)) +
  scale_fill_gradient(guide = FALSE) +
  coord_flip() +
  labs(
    title = "Indiana Operational Expenditure Purpose (Words)",
    caption = "Source: Indiana Election Division",
    x = "Word",
    y = "Count"
  )
```

### Continuous

For continuous variables, we should explore both the range and distribution. This can be done with
visually with `ggplot2::geom_histogram()` and `ggplot2::geom_violin()`.

#### Amounts

```{r summary_amount}
summary(ind$amount)
sum(ind$amount < 0, na.rm = TRUE)
sum(ind$amount > 100000, na.rm = TRUE)
```

```{r amount_histogram, echo=FALSE}
brewer_dark2 <- RColorBrewer::brewer.pal(n = 8, name = "Dark2")
ind %>%
  ggplot(aes(amount)) +
  geom_histogram(fill = brewer_dark2[1]) +
  geom_vline(xintercept = median(ind$amount, na.rm = TRUE)) +
  scale_x_continuous(
    breaks = c(1 %o% 10^(0:6)),
    labels = dollar,
    trans = "log10"
  ) +
  labs(
    title = "Indiana Expenditures Amount Distribution",
    caption = "Source: Indiana Election Division",
    x = "Amount",
    y = "Count"
  )
```

#### Dates

```{r add_year}
ind <- mutate(ind, expenditure_year = year(expenditure_date))
```

```{r date_range, collapse=TRUE}
count_na(ind$expenditure_date)
min(ind$expenditure_date, na.rm = TRUE)
sum(ind$expenditure_year < 1998, na.rm = TRUE)
max(ind$expenditure_date, na.rm = TRUE)
sum(ind$expenditure_date > today(), na.rm = TRUE)
```

```{r count_year}
count(ind, expenditure_year) %>% print(n = 52)
```

```{r flag_fix_dates}
ind <- ind %>% 
  mutate(
    date_flag = expenditure_year < 1998 | expenditure_date > today(),
    date_clean = case_when(
      date_flag~ as.Date(NA),
      not(date_flag) ~ expenditure_date
    ),
    year_clean = year(date_clean)
  )

sum(ind$date_flag, na.rm = TRUE)
```

```{r year_bar_count, echo=FALSE}
ind %>% 
  count(year_clean) %>% 
  mutate(even = is_even(year_clean)) %>% 
  filter(n > 100) %>% 
  ggplot(aes(x = year_clean, y = n)) +
  geom_col(aes(fill = even)) +
  scale_fill_brewer(type = "qual", palette = "Dark2") +
  labs(
    title = "Indiana Expenditures Count by Year",
    caption = "Source: Indiana Election Division",
    fill = "Election Year",
    x = "Year Made",
    y = "Number of Expenditures"
  ) +
  theme(legend.position = "bottom")
```

```{r year_bar_sum, echo=FALSE}
ind %>% 
  group_by(year_clean) %>% 
  summarise(sum = sum(amount, na.rm = TRUE)) %>% 
  mutate(even = is_even(year_clean)) %>% 
  ggplot(aes(x = year_clean, y = sum)) +
  geom_col(aes(fill = even)) +
  scale_fill_brewer(type = "qual", palette = "Dark2") +
  scale_y_continuous(labels = dollar) +
  labs(
    title = "Indiana Expenditures Total by Year",
    caption = "Source: Indiana Election Division",
    fill = "Election Year",
    x = "Year Made",
    y = "Total Amount"
  ) +
  theme(legend.position = "bottom")
```

```{r year_bar_mean, echo=FALSE}
ind %>% 
  group_by(year_clean) %>% 
  summarise(mean = mean(amount, na.rm = TRUE)) %>% 
  mutate(even = is_even(year_clean)) %>% 
  ggplot(aes(x = year_clean, y = mean)) +
  geom_col(aes(fill = even)) +
  scale_fill_brewer(type = "qual", palette = "Dark2") +
  scale_y_continuous(labels = dollar) +
  labs(
    title = "Indiana Expenditures Mean by Year",
    caption = "Source: Indiana Election Division",
    fill = "Election Year",
    x = "Year Made",
    y = "Mean Amount"
  ) +
  theme(legend.position = "bottom")
```

```{r month_line_count, echo=FALSE}
ind %>% 
  mutate(month = month(date_clean), even = is_even(year_clean)) %>% 
  group_by(month, even) %>% 
  summarize(n = n()) %>% 
  ggplot(aes(x = month, y = n)) +
  geom_line(aes(color = even), size = 2) +
  scale_color_brewer(type = "qual", palette = "Dark2") +
  scale_y_continuous(labels = dollar)+
  labs(
    title = "Indiana Expenditures Count by Month",
    caption = "Source: Indiana Election Division",
    fill = "Election Year",
    x = "Year Made",
    y = "Number of Expenditures"
  ) +
  theme(legend.position = "bottom")
```

## Wrangle

We should use the `campfin::normal_*()` functions to perform some basic, high-confidence text
normalization to improve the searchability of the database.

### Address

First, we will normalize the street address by removing punctuation and expanding abbreviations.

```{r address_normal}
ind <- ind %>% 
  mutate(
    address_norm = normal_address(
      address = address,
      abbs = usps_street,
      na_rep = TRUE
    )
  )
```

We can see how this improves consistency across the `address` field.

```{r address_view, echo=FALSE}
ind %>% 
  select(starts_with("address")) %>% 
  drop_na() %>% 
  sample_n(10)
```

### ZIP

The `zip` address is already pretty good, with 
`r percent(prop_in(ind$zip, valid_zip, na.rm = TRUE))` of the values already in our 95% 
comprehensive `valid_zip` list.

We can improve this further by lopping off the uncommon four-digit extensions and removing common
invalid codes like 00000 and 99999.

```{r zip_normal}
ind <- ind %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

This brings our valid percentage to `r percent(prop_in(ind$zip_norm, valid_zip, na.rm = TRUE))`.

```{r zip_progress}
progress_table(
  ind$zip,
  ind$zip_norm,
  compare = valid_zip
)
```

### State

The `state` variable is also very clean, already at 
`r percent(prop_in(ind$state, valid_state, na.rm = TRUE))`.

There are still `r length(setdiff(ind$state, valid_state))` invalid values which we can remove.

```{r state_normal}
ind <- ind %>% 
  mutate(
    state_norm = normal_state(
      state = str_replace(str_trim(state), "^I$", "IN"),
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = valid_state
    )
  )
```

```{r state_progress}
progress_table(
  ind$state,
  ind$state_norm,
  compare = valid_state
)
```

### City

The `city` value is the hardest to normalize. We can use a four-step system to functionally improve
the searchablity of the database.

1. **Normalize** the raw values with `campfin::normal_city()`
1. **Match** the normal values with the _expected_ value for that ZIP code
1. **Swap** the normal values with the expected value if they are _very_ similar
1. **Refine** the swapped values the [OpenRefine algorithms][08] and keep good changes

[08]: https://github.com/OpenRefine/OpenRefine/wiki/Clustering-In-Depth

The raw `city` values are not very normal, with only
`r percent(prop_in(ind$city, valid_city, na.rm = TRUE))` already in `valid_city`, mostly due to case difference. If we simply convert to uppcase that numbers increases to 
`r percent(prop_in(str_to_upper(ind$city), valid_city, na.rm = TRUE))`. We will aim to get this number over 99% using the other steps in the process.

#### Normalize

```{r normal_city}
ind <- ind %>% 
  mutate(
    city_norm = normal_city(
      city = city %>% str_replace(rx_break("Indianapol;is"), "INDIANAPOLIS"), 
      abbs = usps_city,
      states = c("IN", "DC", "INDIANA"),
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

This process brought us to `r percent(prop_in(ind$city_norm, valid_city, na.rm = TRUE))` valid.

It also increased the proportion of `NA` values by 
`r percent(prop_na(ind$city_norm) - prop_na(ind$city))`. These new `NA` values were either a single
(possibly repeating) character, or contained in the `na_city` vector.

```{r new_city_na, echo=FALSE}
ind %>% 
  filter(is.na(city_norm) & !is.na(city)) %>% 
  select(zip_norm, state_norm, city, city_norm) %>% 
  distinct() %>% 
  sample_frac()
```

#### Swap

Then, we will compare these normalized `city_norm` values to the _expected_ city value for that
vendor's ZIP code. If the [levenshtein distance][09] is less than 3, we can confidently swap these
two values.

[09]: https://en.wikipedia.org/wiki/Levenshtein_distance

```{r swap_city}
ind <- ind %>% 
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
      condition = match_dist < 3 | match_abb,
      true = city_match,
      false = city_norm
    )
  )
```

This is a very fast way to increase the valid proportion to
`r percent(prop_in(ind$city_swap, valid_city, na.rm = TRUE))` and reduce the number of distinct
_invalid_ values from `r count_diff(ind$city_norm, valid_city)` to only
`r count_diff(ind$city_swap, valid_city)`

#### Refine

Additionally, we can pass these swapped `city_swap` values to the OpenRefine cluster and merge 
algorithms. These two algorithms cluster similar values and replace infrequent values with their
more common counterparts. This process can be harmful by making _incorrect_ changes. We will only
keep changes where the state, ZIP code, _and_ new city value all match a valid combination.

```{r refine_city}
good_refine <- ind %>% 
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

```{r view_city_refines, echo=FALSE}
good_refine %>%
  count(
    state_norm, 
    zip_norm, 
    city_swap, 
    city_refine,
    sort = TRUE
  )
```

We can join these good refined values back to the original data and use them over their incorrect
`city_swap` counterparts in a new `city_refine` variable.

```{r join_refine}
ind <- ind %>% 
  left_join(good_refine) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

This brings us to `r percent(prop_in(ind$city_refine, valid_city, na.rm = TRUE))` valid values.

We can make very few manual changes to capture the last few big invalid values. Local city
abbreviations (e.g., INDPLS) often need to be changed by hand.

```{r view_final_bad}
ind %>%
  filter(city_refine %out% valid_city) %>% 
  count(state_norm, city_refine, sort = TRUE) %>% 
  drop_na(city_refine)
```

```{r city_final}
ind <- ind %>% 
  mutate(
    city_refine = city_refine %>% 
      str_replace("^INDPLS$", "INDIANAPOLIS") %>% 
      str_replace("^EC$", "EAST CHICAGO") %>% 
      str_replace("^INDY$", "INDIANAPOLIS") %>% 
      str_replace("^MERR$", "MERRILLVILLE")
  )
```

#### Check

We can use the `check_city()` function to pass the remaining unknown `city_refine` values (and
their `state_norm`) to the Google Geocode API. The function returns the name of the city or
locality which most associated with those values.

This is an easy way to both check for typos and check whether an unknown `city_refine` value is
actually a completely acceptable neighborhood, census designated place, or some other locality not
found in our `valid_city` vector from our `zipcodes` database.

First, we'll filter out any known valid city and aggregate the remaining records by their city and
state. Then, we will only query those unknown cities which appear at least ten times.

```{r check_filter}
ind_out <- ind %>% 
  filter(city_refine %out% c(valid_city, extra_city)) %>% 
  count(city_refine, state_norm, sort = TRUE) %>% 
  drop_na() %>% 
  filter(n > 1)
```

Passing these values to `check_city()` with `purrr::pmap_dfr()` will return a single tibble of the
rows returned by each city/state combination.

First, we'll check to see if the API query has already been done and a file exist on disk. If such
a file exists, we can read it using `readr::read_csv()`. If not, the query will be sent and the
file will be written using `readr::write_csv()`.

```{r check_send}
check_file <- here("in", "expends", "data", "api_check.csv")
if (file_exists(check_file)) {
  check <- read_csv(
    file = check_file
  )
} else {
  check <- pmap_dfr(
    .l = list(
      ind_out$city_refine, 
      ind_out$state_norm
    ), 
    .f = check_city, 
    key = Sys.getenv("GEOCODE_KEY"), 
    guess = TRUE
  ) %>% 
    mutate(guess = coalesce(guess_city, guess_place)) %>% 
    select(-guess_city, -guess_place)
  write_csv(
    x = check,
    path = check_file
  )
}
```

Any city/state combination with a `check_city_flag` equal to `TRUE` returned a matching city string
from the API, indicating this combination is valid enough to be ignored.

```{r check_accept}
valid_locality <- check$guess[check$check_city_flag]
```

Then we can perform some simple comparisons between the queried city and the returned city. If they
are extremely similar, we can accept those returned locality strings and add them to our list of
accepted additional localities.

```{r check_compare}
valid_locality <- check %>% 
  filter(!check_city_flag) %>% 
  mutate(
    abb = is_abbrev(original_city, guess),
    dist = str_dist(original_city, guess)
  ) %>%
  filter(abb | dist <= 3) %>% 
  pull(guess) %>% 
  c(valid_locality)
```

This list of acceptable localities can be added with our `valid_city` and `extra_city` vectors
from the `campfin` package. The cities checked will eventually be added to `extra_city`.

```{r check_combine}
many_city <- c(valid_city, extra_city, valid_locality)
```

```{r check_diff}
prop_in(ind$city_refine, valid_city)
prop_in(ind$city_refine, many_city)
```

```{r city_progress, echo=FALSE}
progress <- progress_table(
  str_to_upper(ind$city_raw),
  ind$city_norm,
  ind$city_swap,
  ind$city_refine,
  compare = many_city
) %>% mutate(stage = as_factor(stage))
```

```{r progress_print, echo=FALSE}
kable(progress, digits = 4)
```

You can see how the percentage of valid values increased with each stage.

```{r progress_bar, echo=FALSE}
progress %>% 
  ggplot(aes(x = stage, y = prop_in)) +
  geom_hline(yintercept = 0.99) +
  geom_col(fill = RColorBrewer::brewer.pal(3, "Dark2")[3]) +
  coord_cartesian(ylim = c(0.75, 1)) +
  scale_y_continuous(labels = percent) +
  labs(
    title = "Indiana City Normalization Progress",
    x = "Stage",
    y = "Percent Valid"
  )
```

More importantly, the number of distinct values decreased each stage. We were
able to confidently change many distinct invalid values to their valid
equivilent.

```{r distinct_bar}
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
  scale_fill_brewer(palette = "Dark2") +
  scale_y_continuous(labels = comma) +
  theme(legend.position = "bottom") +
  labs(
    title = "Indiana City Normalization Progress",
    subtitle = "Distinct values, valid and invalid",
    x = "Stage",
    y = "Distinct Values",
    fill = "Valid"
  )
```

## Conclude

1. There are `r nrow(ind)` records in the database.
1. There are `r sum(ind$dupe_flag)` duplicate records in the database.
1. The range and distribution of `amount` seems reasomable, and `date` has been cleaned by removing
`r sum(ind$date_flag, na.rm = T)` values from the distance past or future.
1. There are `r sum(ind$na_flag)` records missing either recipient or date.
1. Consistency in geographic data has been improved with `campfin::normal_*()`.
1. The 5-digit `zip_norm` variable has been created with `campfin::normal_zip()`.
1. The 4-digit `year_clean` variable has been created with `lubridate::year()`.

## Export

```{r create_proc_dir}
proc_dir <- here("in", "expends", "data", "processed")
dir_create(proc_dir)
```

```{r write_clean}
ind %>% 
  select(
    -city_norm,
    -city_swap,
    -city_match,
    -city_swap,
    -match_abb,
    -match_dist,
    -expenditure_year
  ) %>% 
  rename(
    city = city_raw,
    address_clean = address_norm,
    zip_clean = zip_norm,
    state_clean = state_norm,
    city_clean = city_refine
  ) %>% 
  write_csv(
    path = glue("{proc_dir}/in_expends_clean.csv"),
    na = ""
  )
```

