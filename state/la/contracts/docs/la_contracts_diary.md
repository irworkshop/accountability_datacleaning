Louisiana Contracts
================
Kiernan Nicholls
2023-02-02 16:05:36

- <a href="#project" id="toc-project">Project</a>
- <a href="#objectives" id="toc-objectives">Objectives</a>
- <a href="#packages" id="toc-packages">Packages</a>
- <a href="#data" id="toc-data">Data</a>
- <a href="#download" id="toc-download">Download</a>
- <a href="#read" id="toc-read">Read</a>
- <a href="#explore" id="toc-explore">Explore</a>
- <a href="#wrangle" id="toc-wrangle">Wrangle</a>
- <a href="#conclude" id="toc-conclude">Conclude</a>
- <a href="#export" id="toc-export">Export</a>
- <a href="#upload" id="toc-upload">Upload</a>
- <a href="#dictionary" id="toc-dictionary">Dictionary</a>

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
  readxl, # read excel files
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
#> [1] "/home/kiernan/Documents/accountability_datacleaning"
```

## Data

Contracts data can be obtained from the [Louisiana Checkbook
website](https://checkbook.la.gov/contracts/index.cfm). We can download
“Annual Report Source Data” in Microsoft Excel format. This data was
last updated June 1, 2020.

## Download

Data is available from 2016 through 2019.

``` r
raw_dir <- dir_create(here("state", "la", "contracts", "data", "raw"))
raw_urls <- glue(
  "https://checkbook.la.gov/Reports/AnnualSource/",
  "FY{20:22}AnnualReportSourceData.xlsx"
)
raw_paths <- path(raw_dir, basename(raw_urls))
if (!all(file_exists(raw_paths))) {
  download.file(raw_urls, raw_paths)
}
```

## Read

The four Excel spreadsheets can be read into a single data frame using
`purrr::map_df()` and `readxl::read_excel()`.

``` r
lac <- map_df(
  .x = raw_paths,
  .f = read_excel,
  .id = "source",
  skip = 3,
  col_types = "text"
)
```

After reading every column as text, we can clean the variable names and
parse the numeric columns accordingly. We can also change the `source`
variable from combining files into the corresponding fiscal year.

``` r
lac <- lac %>% 
  clean_names("snake") %>% 
  filter(vendor_name != "Sum:") %>% 
  mutate(across(total_amount, parse_double)) %>% 
  mutate(across(total_count, parse_integer)) %>% 
  mutate(
    source = basename(raw_paths[as.integer(source)]),
    year = source %>% 
      str_extract("(?<=FY)\\d{2}") %>% 
      str_c("20", .) %>% 
      as.integer()
  ) %>% 
  rename(description = published_text)
```

Records belonging to contracts have a `contract_no` and single purchase
orders have a `po_number` variable and the inverse is missing for each.
We will create a new variable indicating the record *type*, combine
these two numbers as a new single `id` variable, and then remove the two
original number columns.

``` r
lac <- lac %>% 
  mutate(
    .before = contract_no,
    id = coalesce(po_number, contract_no)
  ) %>% 
  mutate(
    .after = id,
    .keep = "unused",
    type = case_when(
      is.na(contract_no) ~ "purchase",
      is.na(po_number) ~ "contract"
    )
  )
```

## Explore

``` r
glimpse(lac)
#> Rows: 11,485
#> Columns: 14
#> $ source            <chr> "FY20AnnualReportSourceData.xlsx", "FY20AnnualReportSourceData.xlsx", "…
#> $ id                <chr> "2000077857", "2000077857", "2000077857", "2000084119", "2000084119", "…
#> $ type              <chr> "purchase", "purchase", "purchase", "purchase", "purchase", "purchase",…
#> $ service_type      <chr> "COP", "COP", "COP", "COP", "COP", "CON", "CON", "SOC", "SOC", "CON", "…
#> $ service_type_name <chr> "Cooperative Agreement", "Cooperative Agreement", "Cooperative Agreemen…
#> $ dept              <chr> "019", "019", "019", "019", "019", "013", "013", "013", "013", "013", "…
#> $ department_name   <chr> "DEPT OF WILDLIFE AND FISHERIES", "DEPT OF WILDLIFE AND FISHERIES", "DE…
#> $ common_vendor     <chr> "310055601", "310055601", "310055601", "310007221", "310007221", "31006…
#> $ vendor            <chr> "310055601", "310055601", "310055601", "310007221", "310007221", "31006…
#> $ vendor_name       <chr> "DUCKS UNLIMITED", "DUCKS UNLIMITED", "DUCKS UNLIMITED", "KEEP LOUISIAN…
#> $ description       <chr> NA, "Gulf Coast Joint Venture leader position to coordinate conservatio…
#> $ total_amount      <dbl> 0.0, 0.0, 30000.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.…
#> $ total_count       <int> 0, 0, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1,…
#> $ year              <int> 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020,…
tail(lac)
#> # A tibble: 6 × 14
#>   source   id    type  servi…¹ servi…² dept  depar…³ commo…⁴ vendor vendo…⁵ descr…⁶ total…⁷ total…⁸
#>   <chr>    <chr> <chr> <chr>   <chr>   <chr> <chr>   <chr>   <chr>  <chr>   <chr>     <dbl>   <int>
#> 1 FY22Ann… 2000… purc… SOC     Social… 015   DEPT O… 310178… 31017… JULIE … Provid… -7.8 e4       1
#> 2 FY22Ann… 2000… purc… SOC     Social… 013   DEPT O… 310007… 31008… TULANE… Provid… -9.01e4       1
#> 3 FY22Ann… 2000… purc… SOC     Social… 013   DEPT O… 310081… 31008… SOUTHE… Suppor… -2.13e5       1
#> 4 FY22Ann… 2000… purc… SOC     Social… 013   DEPT O… 310081… 31008… SOUTHE… Provid… -2.73e5       1
#> 5 FY22Ann… 2000… purc… SOC     Social… 013   DEPT O… 310083… 31008… LOUISI… Contra… -7.80e5       2
#> 6 FY22Ann… 2000… purc… SOC     Social… 013   DEPT O… 310081… 31008… SOUTHE… Suppor… -1.43e6       2
#> # … with 1 more variable: year <int>, and abbreviated variable names ¹​service_type,
#> #   ²​service_type_name, ³​department_name, ⁴​common_vendor, ⁵​vendor_name, ⁶​description,
#> #   ⁷​total_amount, ⁸​total_count
```

### Missing

The only variables missing any values are the `description` variable and
similar free-form text cells at the end of each spreadsheets. They do
not need to be flagged.

``` r
col_stats(lac, count_na)
#> # A tibble: 14 × 4
#>    col               class     n      p
#>    <chr>             <chr> <int>  <dbl>
#>  1 source            <chr>     0 0     
#>  2 id                <chr>     0 0     
#>  3 type              <chr>     0 0     
#>  4 service_type      <chr>     0 0     
#>  5 service_type_name <chr>     0 0     
#>  6 dept              <chr>     0 0     
#>  7 department_name   <chr>     0 0     
#>  8 common_vendor     <chr>     0 0     
#>  9 vendor            <chr>     0 0     
#> 10 vendor_name       <chr>     0 0     
#> 11 description       <chr>   662 0.0576
#> 12 total_amount      <dbl>     0 0     
#> 13 total_count       <int>     0 0     
#> 14 year              <int>     0 0
```

### Duplicates

If we ignore the supposedly unique `id` variable, there are a few
records that are entirely duplicated at least once across every
variable. Without an exact data column, these could very well be
contracts or purchase orders made for the same amount in the same year.

``` r
lac <- flag_dupes(lac, -id)
sum(lac$dupe_flag)
#> [1] 432
```

``` r
lac %>% 
  filter(dupe_flag) %>% 
  select(id, year, vendor_name, department_name, total_amount)
#> # A tibble: 432 × 5
#>    id          year vendor_name                        department_name                      total…¹
#>    <chr>      <int> <chr>                              <chr>                                  <dbl>
#>  1 2000114252  2020 GRTR LAFAYETTE CHMBR OF CMMRCE     DEPT OF ECONOMIC DEVELOPMENT               0
#>  2 2000119708  2020 GREATER BATON ROUGE                DEPT OF ECONOMIC DEVELOPMENT               0
#>  3 2000149142  2020 WESTED                             DEPT OF EDUCATION                          0
#>  4 2000149667  2020 WESTED                             DEPT OF EDUCATION                          0
#>  5 2000236313  2020 DELOITTE CONSULTING LLP            ANCILLARY APPROPRIATIONS                   0
#>  6 2000253505  2020 SHOWS, CALI & BURNS                EXECUTIVE DEPT                             0
#>  7 2000261954  2020 POSTLETHWAITE AND NETTERVILLE APAC DEPT OF PUBLIC SAFETY AND CORRECTIO…       0
#>  8 2000262487  2020 IEM INC                            EXECUTIVE DEPT                             0
#>  9 2000265762  2020 LOUISIANA PUBLIC HEALTH            DEPT OF HEALTH AND HOSPITALS               0
#> 10 2000283813  2020 TULANE UNIVERSITY                  DEPT OF HEALTH AND HOSPITALS               0
#> # … with 422 more rows, and abbreviated variable name ¹​total_amount
```

### Categorical

``` r
col_stats(lac, n_distinct)
#> # A tibble: 15 × 4
#>    col               class     n        p
#>    <chr>             <chr> <int>    <dbl>
#>  1 source            <chr>     3 0.000261
#>  2 id                <chr>  7113 0.619   
#>  3 type              <chr>     2 0.000174
#>  4 service_type      <chr>     8 0.000697
#>  5 service_type_name <chr>    13 0.00113 
#>  6 dept              <chr>    28 0.00244 
#>  7 department_name   <chr>    49 0.00427 
#>  8 common_vendor     <chr>  2926 0.255   
#>  9 vendor            <chr>  3211 0.280   
#> 10 vendor_name       <chr>  3392 0.295   
#> 11 description       <chr>  6592 0.574   
#> 12 total_amount      <dbl>  3744 0.326   
#> 13 total_count       <int>     9 0.000784
#> 14 year              <int>     3 0.000261
#> 15 dupe_flag         <lgl>     2 0.000174
```

``` r
explore_plot(lac, type)
```

![](../plots/distinct_plots-1.png)<!-- -->

``` r
explore_plot(lac, service_type_name)
```

![](../plots/distinct_plots-2.png)<!-- -->

``` r
explore_plot(lac, department_name) + scale_x_truncate()
```

![](../plots/distinct_plots-3.png)<!-- -->

### Amounts

A significant portion of the `total_amount` variable are less than or
equal to zero.

``` r
summary(lac$total_amount)
#>       Min.    1st Qu.     Median       Mean    3rd Qu.       Max. 
#>  -57224191          0      34999    4020329     150000 3908812314
percent(mean(lac$total_amount < 0), 0.1)
#> [1] "1.3%"
percent(mean(lac$total_amount == 0), 0.1)
#> [1] "33.8%"
```

![](../plots/hist_amount-1.png)<!-- -->

It’s not clear what the `total_count` variable represents. Perhaps the
total number of each contract ordered.

``` r
lac %>% 
  group_by(total_count) %>% 
  summarise(mean_amount = mean(total_amount))
#> # A tibble: 9 × 2
#>   total_count mean_amount
#>         <int>       <dbl>
#> 1           0          0 
#> 2           1    2586078.
#> 3           2    6180951.
#> 4           3   70893752.
#> 5           4    6031518.
#> 6           5    1678375.
#> 7           6     475000 
#> 8           7 1534471112.
#> 9           8 2466221529.
```

### Dates

We already added the fiscal year based on the source file. Without a
start date, we can’t add the calendar year.

![](../plots/bar_year-1.png)<!-- -->

## Wrangle

There are no geographic variables that require normalization. At the
very least, we know that each `department_name` value has an associated
state in Louisiana.

``` r
lac <- mutate(lac, state = "LA", .after = department_name)
```

## Conclude

1.  There are 11,485 records in the database.
2.  There are 432 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 0 records missing key variables.
5.  There are no geographic variables to normalize, `state` was added
    manually.
6.  The 4-digit fiscal `year` was determined from source file.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("state", "la", "contracts", "data", "clean"))
clean_csv <- path(clean_dir, "la_contracts_2020-2022.csv")
write_csv(lac, clean_csv, na = "")
file_size(clean_csv)
#> 3.19M
mutate(file_encoding(clean_csv), across(path, path.abbrev))
#> # A tibble: 1 × 3
#>   path                                                                                mime  charset
#>   <fs::path>                                                                          <chr> <chr>  
#> 1 …countability_datacleaning/state/la/contracts/data/clean/la_contracts_2020-2022.csv text… utf-8
```

## Upload

We can use the `aws.s3::put_object()` to upload the text file to the IRW
server.

``` r
aws_key <- path("csv", basename(clean_csv))
if (!object_exists(aws_key, "publicaccountability")) {
  put_object(
    file = clean_csv,
    object = aws_key, 
    bucket = "publicaccountability",
    acl = "public-read",
    show_progress = TRUE,
    multipart = TRUE
  )
}
aws_head <- head_object(aws_key, "publicaccountability")
(aws_size <- as_fs_bytes(attr(aws_head, "content-length")))
unname(aws_size == clean_size)
```

## Dictionary

The following table describes the variables in our final exported file:

| Column              | Type        | Definition                              |
|:--------------------|:------------|:----------------------------------------|
| `source`            | `character` | Source Excel file name                  |
| `id`                | `character` | Unique contract or purchase ID          |
| `type`              | `character` | Contract or single purchase order       |
| `service_type`      | `character` | Service type code                       |
| `service_type_name` | `character` | Service type full name                  |
| `dept`              | `character` | Spending department code                |
| `department_name`   | `character` | Spending department name                |
| `state`             | `character` | Spending department state abbreviation  |
| `common_vendor`     | `character` | Common vendor ID                        |
| `vendor`            | `character` | Unique vendor ID                        |
| `vendor_name`       | `character` | Vendor full name                        |
| `description`       | `character` | Total contract or purchase amount       |
| `total_amount`      | `double`    | Total number of contracts ordered       |
| `total_count`       | `integer`   | Free-form text description of contracts |
| `year`              | `integer`   | Fiscal year ordered from source file    |
| `dupe_flag`         | `logical`   | Flag indicating duplicate record        |
