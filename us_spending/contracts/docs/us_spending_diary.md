Health and Human Services Contracts
================
Kiernan Nicholls
2020-03-19 11:26:55

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Download](#download)
  - [Extract](#extract)
  - [Layout](#layout)
  - [Read](#read)
  - [Check](#check)

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
  gluedown, # print markdown
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

Contracts data is obtained from the [USA Spending Award Data
Archive](https://www.usaspending.gov/#/download_center/award_data_archive).

> Welcome to the Award Data Archive, which features major agencies’
> award transaction data for full fiscal years. They’re a great way to
> get a view into broad spending trends and, best of all, the files are
> already prepared — you can access them instantaneously.

Data can be obtained from archive files for each agency and a given
fiscal year; archived text files are split to include up to one million
records.

## Download

We first need to construct both the URLs and local paths of the archive
files.

``` r
zip_dir <- dir_create(here("contracts", "data", "zip"))
base_url <- "https://files.usaspending.gov/award_data_archive/"
con_files <- glue("FY{2008:2020}_All_Contracts_Full_20200313.zip")
con_urls <- str_c(base_url, con_files)
con_zips <- path(zip_dir, con_files)
```

    #> [1] "https://files.usaspending.gov/award_data_archive/FY2008_All_Contracts_Full_20200313.zip"
    #> [2] "https://files.usaspending.gov/award_data_archive/FY2009_All_Contracts_Full_20200313.zip"
    #> [3] "https://files.usaspending.gov/award_data_archive/FY2010_All_Contracts_Full_20200313.zip"
    #> [1] "~/contracts/data/zip/FY2008_All_Contracts_Full_20200313.zip"
    #> [2] "~/contracts/data/zip/FY2009_All_Contracts_Full_20200313.zip"
    #> [3] "~/contracts/data/zip/FY2010_All_Contracts_Full_20200313.zip"

We also need to add the record for spending made since this file was
last updated. This information can be found in the “delta” file released
alongside the “full” spending files.

> New files are uploaded by the 15th of each month. Check the Data As Of
> column to see the last time files were generated. Full files feature
> data for the fiscal year up until the date the file was prepared, and
> delta files feature only new, modified, and deleted data since the
> date the last month’s files were generated. The
> `correction_delete_ind` column in the delta files indicates whether a
> record has been modified (C), deleted (D), or added (blank). To
> download data prior to FY 2008, visit our Custom Award Data page.

``` r
delta_file <- "FY(All)_All_Contracts_Delta_20200313.zip"
delta_url <- str_c(base_url, delta_file)
delta_zip <- path(zip_dir, delta_file)
```

If the archive files have not been downloaded, we can do so now.

``` r
if (!all(file_exists(c(con_zips, delta_zip)))) {
  download.file(con_urls, con_zips)
  download.file(delta_url, delta_zip)
}
```

## Extract

We can extract the text files from the annual archives into a new
directory.

``` r
csv_dir <- dir_create(here("contracts", "data", "csv"))
if (length(dir_ls(csv_dir)) == 0) {
  map(c(con_zips, delta_zip), unzip, exdir = csv_dir)
}
con_paths <- dir_ls(csv_dir, regexp = "FY\\d+.*csv")
delta_paths <- dir_ls(csv_dir, regexp = "FY\\(All\\).*csv")
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

usa_names <- read_csv(con_paths[which.min(file_size(con_paths))], n_max = 0)
usa_names <- names(usa_names)
# get cols from hhs data
mean(usa_names %in% dict$award_element)
#> [1] 0.8949275
dict <- dict %>% 
  filter(award_element %in% usa_names) %>% 
  select(award_element, definition) %>% 
  mutate_at(vars(definition), str_replace_all, "\"", "\'") %>% 
  arrange(match(award_element, usa_names))

dict %>% 
  head(10) %>% 
  mutate_at(vars(definition), str_trunc, 75) %>% 
  kable()
```

| award\_element                       | definition                                                                |
| :----------------------------------- | :------------------------------------------------------------------------ |
| award\_id\_piid                      | The unique identifier of the specific award being reported.               |
| modification\_number                 | The identifier of an action being reported that indicates the specific s… |
| transaction\_number                  | Tie Breaker for legal, unique transactions that would otherwise have the… |
| parent\_award\_agency\_id            | Identifier used to link agency in FPDS-NG to referenced IDV information.  |
| parent\_award\_agency\_name          | Name of the agency associated with the code in the Referenced IDV Agency… |
| parent\_award\_modification\_number  | When reporting orders under Indefinite Delivery Vehicles (IDV) such as a… |
| federal\_action\_obligation          | Amount of Federal government’s obligation, de-obligation, or liability f… |
| total\_dollars\_obligated            | This is a system generated element providing the sum of all the amounts … |
| base\_and\_exercised\_options\_value | The change (from this transaction only) to the current contract value (i… |
| current\_total\_value\_of\_award     | Total amount obligated to date on an award. For a contract, this amount … |

## Read

Due to the sheer size and number of files in question, we can’t read
them all at once into a single data file for exploration and wrangling.
Instead, we will read together all the files for a given year, select
the columns we want, and write them to a new single file.

These condensed and trimmed files can each be explored individually. We
can read the subset of files, run some analysis, save the explroation to
a new file, and proceed to the next year of files.

This whole process is found in the `us_spending_read.R` script in this
same directory, which can be executed as an R script.

``` r
if (!file_exists("done.txt") | !file_exists("us_con_checks.csv")) {
  for (f in con_paths) {
    source(here("contracts", "docs", "us_spending_read.R"), local = FALSE)
  }
  file_create("done.txt")
}
```

We can count a discrete categorical variable to ensure the file was read
properly. If there was an error reading one of the text files, the
columns will likely shift.

## Check

The `us_spending_read.R` script creates a number of progress files while
looping through each raw file. We can read these files now the check
variuous stats about the individual files.

First we will read `us_con_checks.csv`, which contains information on
the number of rows, columns, unique types, missing, and zero values.

In total, there are 50,870,104 rows of 21 columns.

``` r
checks %>% 
  group_by(year) %>% 
  summarise(
    rows = sum(rows),
    cols = unique(cols),
    types = unique(types),
    na = sum(na),
    zero = sum(zero)/rows
  ) %>% 
  kable(digits = 4)
```

| year |    rows | cols | types |  na |   zero |
| ---: | ------: | ---: | ----: | --: | -----: |
| 2008 | 4505268 |   21 |     5 | 166 | 0.1311 |
| 2009 | 3496839 |   21 |     5 | 146 | 0.1898 |
| 2010 | 3541480 |   21 |     5 |  94 | 0.2016 |
| 2011 | 3406172 |   21 |     5 | 229 | 0.2322 |
| 2012 | 3126167 |   21 |     5 | 313 | 0.2528 |
| 2013 | 2511812 |   21 |     5 | 296 | 0.3094 |
| 2014 | 2526703 |   21 |     5 | 190 | 0.2991 |
| 2015 | 4372832 |   21 |     5 | 107 | 0.1786 |
| 2016 | 4819495 |   21 |     5 |  93 | 0.1674 |
| 2017 | 4907838 |   21 |     5 | 109 | 0.1793 |
| 2018 | 5610232 |   21 |     5 | 129 | 0.1429 |
| 2019 | 6461152 |   21 |     5 | 101 | 0.1201 |
| 2020 | 1584114 |   21 |     5 |  46 | 0.1565 |

We also checked the normalization of the various geograophic variables
and saved the data to a `us_con_geo.csv` file.

In total, there are 50,870,104 rows of 21 columns.

``` r
geo %>% 
  group_by(col) %>% 
  summarise(
    valid = mean(valid),
    unique = mean(unique),
    na = mean(na),
    out = mean(out),
    diff = mean(diff)
  ) %>% 
  kable(digits = 3)
```

| col   | valid |    unique |    na |       out |     diff |
| :---- | ----: | --------: | ----: | --------: | -------: |
| city  | 0.966 |  8849.825 | 0.000 | 30072.386 | 1626.333 |
| place | 0.995 | 14879.175 | 0.094 |  3921.561 |  409.684 |
| state | 1.000 |    59.789 | 0.033 |     0.140 |    1.140 |
| zip   | 0.982 | 16552.684 | 0.008 | 16004.526 | 1895.421 |
