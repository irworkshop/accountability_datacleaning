Health and Human Services Spending
================
Kiernan Nicholls
2020-03-27 13:51:42

  - [Project](#project)
  - [Objectives](#objectives)
  - [Software](#software)
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

## Software

This data is processed using the free, open-source statistical computing
language R, which can be [installed from
CRAN](https://cran.r-project.org/) for various opperating systems. For
example, R can be installed from the apt package repository on Ubuntu.

``` bash
sudo apt update
sudo apt -y upgrade
sudo apt -y install r-base
```

The following additional R packages are needed to collect, manipulate,
visualize, analyze, and communicate these results. The `pacman` package
will facilitate their installation and attachment.

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
  furrr, # parallel map
  glue, # combine strings
  here, # relative storage
  pryr, # memory usage
  fs # search storage 
)
```

This document should be run as part of the `us_spending` project, which
lives as a sub-directory of the more general, language-agnostic
[`irworkshop/tap`](https://github.com/irworkshop/accountability_datacleaning)
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

Federal spending data is obtained from
[USASpending.gov](https://www.usaspending.gov/#/), a site run by the
Department of the Treasury.

> \[Many\] sources of information support USAspending.gov, linking data
> from a variety of government systems to improve transparency on
> federal spending for the public. Data is uploaded directly from more
> than a hundred federal agencies’ financial systems. Data is also
> pulled or derived from other government systems… In the end, more than
> 400 points of data are collected…

> Federal agencies submit contract, grant, loan, direct payment, and
> other award data at least twice a month to be published on
> USAspending.gov. Federal agencies upload data from their financial
> systems and link it to the award data quarterly. This quarterly data
> must be certified by the agency’s Senior Accountable Official before
> it is displayed on USAspending.gov.

Flat text files containing all spending data can be found on the [Award
Data
Archive](https://www.usaspending.gov/#/download_center/award_data_archive).

> Welcome to the Award Data Archive, which features major agencies’
> award transaction data for full fiscal years. They’re a great way to
> get a view into broad spending trends and, best of all, the files are
> already prepared — you can access them instantaneously.

Data can be obtained from the archive as annual `.zip` files each
containing a number of comma-delimited text files with a maximum one
million records to reduce size.

Archives can be obtained for individual agencies or for *all* agencies.

## Download

We first need to construct both the URLs and local paths to the archive
files.

``` r
zip_dir <- dir_create(here("data", "zip"))
base_url <- "https://files.usaspending.gov/award_data_archive/"
con_files <- glue("FY{2008:2020}_All_Contracts_Full_20200313.zip")
con_urls <- str_c(base_url, con_files)
con_zips <- path(zip_dir, con_files)
```

    #> [1] "https://files.usaspending.gov/award_data_archive/FY2008_All_Contracts_Full_20200313.zip"
    #> [2] "https://files.usaspending.gov/award_data_archive/FY2009_All_Contracts_Full_20200313.zip"
    #> [3] "https://files.usaspending.gov/award_data_archive/FY2010_All_Contracts_Full_20200313.zip"
    #> [1] "~/data/zip/FY2008_All_Contracts_Full_20200313.zip"
    #> [2] "~/data/zip/FY2009_All_Contracts_Full_20200313.zip"
    #> [3] "~/data/zip/FY2010_All_Contracts_Full_20200313.zip"

We also need to add the records for spending and corrections made since
this file was last updated. This is information is crucial, as it
contains the most recent data. This information can be found in the
“delta” file released alongside the “full” spending files.

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
raw_dir <- dir_create(here("data", "raw"))
if (length(dir_ls(raw_dir)) == 0) {
  future_map(con_zips, unzip, exdir = raw_dir)
  future_map(delta_zip, unzip, exdir = raw_dir)
}
```

``` r
con_paths <- dir_ls(raw_dir, regexp = "FY\\d+.*csv")
delta_paths <- dir_ls(raw_dir, regexp = "FY\\(All\\).*csv")
```

## Layout

The USA Spending website also provides a comprehensive data dictionary
which covers the many variables in this file.

``` r
dict_file <- path(here("data"), "dict.xlsx")
if (!file_exists(dict_file)) {
  download.file(
    url = "https://files.usaspending.gov/docs/Data_Dictionary_Crosswalk.xlsx",
    destfile = dict_file
  )
}
dict <- read_excel(
  path = dict_file, 
  range = "A2:L414",
  na = "N/A",
  .name_repair = make_clean_names
)

usa_names <- names(vroom(con_paths[which.min(file_size(con_paths))], n_max = 0))
# get cols from hhs data
mean(usa_names %in% dict$award_element)
#> [1] 0.8949275
dict %>% 
  filter(award_element %in% usa_names) %>% 
  select(award_element, definition) %>% 
  mutate_at(vars(definition), str_replace_all, "\"", "\'") %>% 
  arrange(match(award_element, usa_names)) %>% 
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

``` r
length(con_paths)
#> [1] 57
# total file sizes
sum(file_size(con_paths))
#> 84.9G
# avail local memory
as_fs_bytes(str_extract(system("free", intern = TRUE)[2], "\\d+"))
#> 31.4M
```

What we will instead do is read each file individually and perform the
type of exploratory analysis we need to ensure the data is well
structured and normal. This will be done with a lengthy `for` loop and
appending the checks to a new text file on disk.

We are not going to use the delta file to correct, delete, and update
the original transactions. We are instead going to upload the separetely
so that the changed versions appear alongside the original in all search
results. We will tag all records with the file they originate from.

``` r
clear_memory <- function(n = 10) {
  for (i in 1:n) {
    gc(reset = TRUE, full = TRUE)
  }
}
```

``` r
read_start <- Sys.time()
# track progress in text file
prog_path <- file_create("read_prog.txt")
for (f in c(con_paths, delta_paths)) {
  loop_start <- Sys.time()
  prog_files <- read_lines(prog_path)
  n <- str_remove(basename(f), "_All_Contracts_(Full|Delta)_\\d+")
  if (f %in% prog_files) {
    message(paste(n, "already done"))
    next()
  } else {
    message(paste(n, "starting"))
  }
  # read contracts ------------------------------------------------------------
  usc <- vroom(
    file = f,
    delim = ",",
    guess_max = 0,
    escape_backslash = FALSE,
    escape_double = FALSE,
    progress = FALSE,
    id = "file",
    col_types = cols(
      .default = col_character(),
      action_date_fiscal_year = col_integer(),
      action_date = col_date(),
      federal_action_obligation = col_double()
    )
  )
  usc <- select(
    .data = usc,
    key = contract_transaction_unique_key,
    piid = award_id_piid,
    fiscal = action_date_fiscal_year,
    date = action_date,
    amount = federal_action_obligation,
    agency = awarding_agency_name,
    sub_id = awarding_sub_agency_code,
    sub_agency = awarding_sub_agency_name,
    office = awarding_office_name,
    rec_id = recipient_duns,
    address1 = recipient_address_line_1,
    address2 = recipient_address_line_2,
    city = recipient_city_name,
    state = recipient_state_code,
    zip = recipient_zip_4_code,
    place = primary_place_of_performance_zip_4,
    type = award_type_code,
    desc = award_description,
    file,
    everything()
  )
  # tweak cols ---------------------------------------------------------------
  # create single recip col
  usc <- mutate(
    .data = usc,
    .after = "rec_id", 
    file = basename(file),
    rec_name = coalesce(
      recipient_name,
      recipient_parent_name,
      recipient_doing_business_as_name
    )
  )
  # flag missing vals
  usc <- flag_na(usc, date, amount, sub_agency, rec_name)
  # trim zip codes
  usc <- mutate_at(usc, vars("zip", "place"), iconv, to = "ASCII")
  usc <- mutate_at(usc, vars("zip", "place"), str_sub, end = 5)
  # add calendar year
  usc <- mutate(usc, year = year(date), .after = "fiscal")
  clear_memory()
  # if delta remove rows
  if ("correction_delete_ind" %in% names(usc)) {
    usc <- rename(usc, change = correction_delete_ind)
    usc <- relocate(usc, change, .after = "file")
    usc <- filter(usc, change != "D" | is.na(change))
  }
  # save checks --------------------------------------------------------------
  if (n_distinct(usc$fiscal) > 1) {
    fy <- NA_character_
  } else {
    fy <- unique(usc$fiscal)
  }
  check <- tibble(
    file = n,
    nrow = nrow(usc),
    ncol = ncol(usc),
    types = n_distinct(usc$type),
    fiscal = fy,
    start = min(usc$date, na.rm = TRUE),
    end = max(usc$date, na.rm = TRUE),
    miss = sum(usc$na_flag, na.rm = TRUE),
    zero = sum(usc$amount <= 0, na.rm = TRUE),
    city = round(mean(usc$city %in% c(valid_city, extra_city)), 4),
    state = round(mean(usc$state %in% valid_state), 4),
    zip = round(mean(usc$zip %in% valid_zip), 4)
  )
  message(paste(n, "checking done"))
  # save tweaked file
  vroom_write(usc, f)
  # save the checks as line in csv
  write_csv(check[1, ], "spend_check.csv", append = TRUE)
  # save the file as line in txt
  write_lines(f, prog_path, append = TRUE)
  # reset for next
  rm(usc, check)
  Sys.sleep(60)
  clear_memory()
  p <- paste(match(f, con_paths), length(con_paths), sep = "/")
  message(paste(n, "writing done:", p, file_size(f)))
  # check progress
  Sys.time() - read_start
  Sys.time() - loop_start
}
```

## Check

In the end, 61 files were read and checked.

``` r
all_paths <- dir_ls(raw_dir)
length(all_paths)
#> [1] 61
sum(file_size(all_paths))
#> 91.6G
```

Now we can read the `spend_check.csv` text file to see the statistics
saved from each file.

We can `summarise()` across all files to find the typical statistic
across all raw data.

``` r
all_checks %>% 
  summarise(
    nrow = sum(nrow),
    ncol = mean(ncol),
    type = mean(types),
    start = min(start),
    end = max(end),
    missing = sum(missing)/sum(nrow),
    zero = sum(zero)/sum(nrow),
    city = mean(city),
    state = mean(state),
    zip = mean(zip)
  )
#> # A tibble: 1 x 10
#>       nrow  ncol  type start      end           missing  zero  city state   zip
#>      <dbl> <dbl> <dbl> <date>     <date>          <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1 54409745  280.  4.97 2000-10-01 2020-03-11 0.00000443 0.176 0.964 0.966 0.972
```

And here we have the total checks for every file.

| file            |    nrow | ncol | start      | end        | missing |   zero | city | state | zip |
| :-------------- | ------: | ---: | :--------- | :--------- | ------: | -----: | :--- | :---- | :-- |
| `FY2008_1.csv`  | 1000000 |  280 | 2008-07-31 | 2008-09-30 |       6 | 139765 | 96%  | 97%   | 98% |
| `FY2008_2.csv`  | 1000000 |  280 | 2008-05-08 | 2008-07-31 |       6 | 124307 | 97%  | 98%   | 98% |
| `FY2008_3.csv`  | 1000000 |  280 | 2008-02-19 | 2008-05-08 |      18 | 125978 | 97%  | 98%   | 98% |
| `FY2008_4.csv`  | 1000000 |  280 | 2007-11-14 | 2008-02-19 |      12 | 129646 | 97%  | 98%   | 98% |
| `FY2008_5.csv`  |  505268 |  280 | 2007-10-01 | 2007-11-14 |      10 |  70954 | 96%  | 98%   | 98% |
| `FY2009_1.csv`  | 1000000 |  280 | 2009-07-15 | 2009-09-30 |      10 | 189319 | 96%  | 96%   | 97% |
| `FY2009_2.csv`  | 1000000 |  280 | 2009-04-01 | 2009-07-15 |      28 | 179973 | 96%  | 96%   | 98% |
| `FY2009_3.csv`  | 1000000 |  280 | 2008-12-03 | 2009-04-01 |       5 | 192704 | 96%  | 96%   | 98% |
| `FY2009_4.csv`  |  496839 |  280 | 2008-10-01 | 2008-12-03 |       9 | 101839 | 95%  | 96%   | 98% |
| `FY2010_1.csv`  | 1000000 |  280 | 2010-07-14 | 2010-09-30 |      11 | 210439 | 96%  | 96%   | 97% |
| `FY2010_2.csv`  | 1000000 |  280 | 2010-03-31 | 2010-07-14 |       2 | 194652 | 96%  | 97%   | 97% |
| `FY2010_3.csv`  | 1000000 |  280 | 2009-12-07 | 2010-03-31 |      10 | 196387 | 96%  | 96%   | 98% |
| `FY2010_4.csv`  |  541480 |  280 | 2009-10-01 | 2009-12-07 |       4 | 112399 | 96%  | 96%   | 97% |
| `FY2011_1.csv`  | 1000000 |  280 | 2011-07-14 | 2011-09-30 |       6 | 219885 | 96%  | 96%   | 97% |
| `FY2011_2.csv`  | 1000000 |  280 | 2011-03-23 | 2011-07-14 |       2 | 239645 | 96%  | 96%   | 97% |
| `FY2011_3.csv`  | 1000000 |  280 | 2010-11-18 | 2011-03-23 |       9 | 238440 | 96%  | 96%   | 97% |
| `FY2011_4.csv`  |  406172 |  280 | 2010-10-01 | 2010-11-18 |       7 |  92961 | 96%  | 96%   | 97% |
| `FY2012_1.csv`  | 1000000 |  280 | 2012-06-25 | 2012-09-30 |      13 | 249742 | 96%  | 96%   | 96% |
| `FY2012_2.csv`  | 1000000 |  280 | 2012-03-01 | 2012-06-25 |       4 | 244172 | 96%  | 96%   | 96% |
| `FY2012_3.csv`  | 1000000 |  280 | 2011-10-19 | 2012-03-01 |      11 | 265818 | 96%  | 96%   | 96% |
| `FY2012_4.csv`  |  126167 |  280 | 2011-10-01 | 2011-10-19 |       1 |  30613 | 96%  | 96%   | 96% |
| `FY2013_1.csv`  | 1000000 |  280 | 2013-06-02 | 2013-09-30 |       8 | 283619 | 96%  | 96%   | 97% |
| `FY2013_2.csv`  | 1000000 |  280 | 2012-12-28 | 2013-06-02 |       2 | 327008 | 96%  | 96%   | 96% |
| `FY2013_3.csv`  |  511812 |  280 | 2012-10-01 | 2012-12-28 |       2 | 166547 | 95%  | 95%   | 96% |
| `FY2014_1.csv`  | 1000000 |  280 | 2014-06-09 | 2014-09-30 |       8 | 272017 | 96%  | 96%   | 97% |
| `FY2014_2.csv`  | 1000000 |  280 | 2014-01-08 | 2014-06-09 |       2 | 309379 | 96%  | 96%   | 97% |
| `FY2014_3.csv`  |  526703 |  280 | 2013-10-01 | 2014-01-08 |       3 | 174443 | 96%  | 95%   | 96% |
| `FY2015_1.csv`  | 1000000 |  280 | 2015-07-24 | 2015-09-30 |       1 | 179800 | 97%  | 97%   | 98% |
| `FY2015_2.csv`  | 1000000 |  280 | 2015-04-28 | 2015-07-24 |       3 | 182205 | 97%  | 97%   | 98% |
| `FY2015_3.csv`  | 1000000 |  280 | 2015-02-05 | 2015-04-28 |       1 | 180669 | 97%  | 97%   | 98% |
| `FY2015_4.csv`  | 1000000 |  280 | 2014-11-01 | 2015-02-05 |       2 | 175839 | 96%  | 96%   | 96% |
| `FY2015_5.csv`  |  372832 |  280 | 2014-10-01 | 2014-11-01 |       1 |  62338 | 96%  | 96%   | 96% |
| `FY2016_1.csv`  | 1000000 |  280 | 2015-10-01 | 2016-09-30 |       1 | 167992 | 96%  | 96%   | 97% |
| `FY2016_2.csv`  | 1000000 |  280 | 2015-10-01 | 2016-09-30 |       1 | 166226 | 97%  | 96%   | 97% |
| `FY2016_3.csv`  | 1000000 |  280 | 2015-10-01 | 2016-09-30 |       0 | 168498 | 96%  | 96%   | 97% |
| `FY2016_4.csv`  | 1000000 |  280 | 2015-10-01 | 2016-09-30 |       0 | 166662 | 96%  | 96%   | 97% |
| `FY2016_5.csv`  |  819495 |  280 | 2015-10-01 | 2016-09-30 |       1 | 137490 | 96%  | 96%   | 97% |
| `FY2017_1.csv`  | 1000000 |  280 | 2016-10-01 | 2017-09-30 |       0 | 181126 | 97%  | 97%   | 97% |
| `FY2017_2.csv`  | 1000000 |  280 | 2016-10-01 | 2017-09-30 |       0 | 179122 | 97%  | 97%   | 97% |
| `FY2017_3.csv`  | 1000000 |  280 | 2016-10-01 | 2017-09-30 |       0 | 178768 | 97%  | 96%   | 97% |
| `FY2017_4.csv`  | 1000000 |  280 | 2016-10-01 | 2017-09-30 |       1 | 178920 | 97%  | 97%   | 97% |
| `FY2017_5.csv`  |  907838 |  280 | 2016-10-01 | 2017-09-30 |       1 | 161891 | 97%  | 97%   | 97% |
| `FY2018_1.csv`  | 1000000 |  280 | 2017-10-01 | 2018-09-30 |       1 | 144190 | 97%  | 97%   | 98% |
| `FY2018_2.csv`  | 1000000 |  280 | 2017-10-01 | 2018-09-30 |       0 | 142962 | 97%  | 97%   | 98% |
| `FY2018_3.csv`  | 1000000 |  280 | 2017-10-01 | 2018-09-30 |       0 | 142963 | 97%  | 97%   | 98% |
| `FY2018_4.csv`  | 1000000 |  280 | 2017-10-01 | 2018-09-30 |       0 | 142400 | 97%  | 97%   | 98% |
| `FY2018_5.csv`  | 1000000 |  280 | 2017-10-01 | 2018-09-30 |       0 | 141790 | 97%  | 97%   | 98% |
| `FY2018_6.csv`  |  610232 |  280 | 2017-10-01 | 2018-09-30 |       0 |  87202 | 97%  | 97%   | 98% |
| `FY2019_1.csv`  | 1000000 |  280 | 2018-10-01 | 2019-09-30 |       0 | 121318 | 98%  | 98%   | 98% |
| `FY2019_2.csv`  | 1000000 |  280 | 2018-10-01 | 2019-09-30 |       0 | 120689 | 98%  | 98%   | 98% |
| `FY2019_3.csv`  | 1000000 |  280 | 2018-10-01 | 2019-09-30 |       1 | 119310 | 98%  | 98%   | 98% |
| `FY2019_4.csv`  | 1000000 |  280 | 2018-10-01 | 2019-09-30 |       0 | 119682 | 98%  | 98%   | 98% |
| `FY2019_5.csv`  | 1000000 |  280 | 2018-10-01 | 2019-09-30 |       0 | 119254 | 98%  | 98%   | 98% |
| `FY2019_6.csv`  | 1000000 |  280 | 2018-10-01 | 2019-09-30 |       0 | 120508 | 98%  | 98%   | 98% |
| `FY2019_7.csv`  |  461152 |  280 | 2018-10-01 | 2019-09-30 |       0 |  55192 | 98%  | 98%   | 98% |
| `FY2020_1.csv`  | 1000000 |  280 | 2019-11-11 | 2020-03-11 |       0 | 166648 | 99%  | 98%   | 99% |
| `FY2020_2.csv`  |  584114 |  280 | 2019-10-01 | 2019-11-11 |       0 |  81279 | 98%  | 98%   | 98% |
| `FY(All)_1.csv` | 1000000 |  282 | 2000-10-19 | 2020-03-11 |       0 | 134497 | 98%  | 98%   | 98% |
| `FY(All)_2.csv` | 1000000 |  282 | 2000-10-01 | 2020-03-11 |       9 |  49397 | 89%  | 89%   | 90% |
| `FY(All)_3.csv` | 1000000 |  282 | 2000-10-01 | 2020-01-08 |       6 |  16524 | 94%  | 95%   | 96% |
| `FY(All)_4.csv` |  539641 |  282 | 2000-10-01 | 2020-01-08 |       2 |  17118 | 97%  | 96%   | 97% |

We are going to rename the files for clarity on the source.

``` r
new_paths <- str_replace(all_paths, "_All_", "_US_")
file_move(all_paths, new_paths)
```
