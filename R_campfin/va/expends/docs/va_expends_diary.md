Data Diary
================
First Last
`format(Sys.time())`

  - [Project](#project)
  - [Objectives](#objectives)
  - [Prerequisites](#prerequisites)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Wrangle](#wrangle)

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

## Prerequisites

The following packages are needed to collect, manipulate, visualize,
analyze, and communicate these results. The `pacman` package will
facilitate their installation and attachment.

``` r
pacman::p_load_gh("VerbalExpressions/RVerbalExpressions")
pacman::p_load(
  stringdist, # levenshtein value
  tidyverse, # data manipulation
  lubridate, # datetime strings
  tidytext, # text mining tools
  magrittr, # pipe opperators
  janitor, # dataframe clean
  zipcode, # clean & databse
  batman, # parse logicals
  refinr, # cluster & merge
  rvest, # scrape website
  skimr, # summary stats
  vroom, # quickly read
  glue, # combine strings
  here, # locate storage
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
#> [1] "/home/ubuntu/R/accountability_datacleaning/R_campfin"
```

## Data

Data is provided by the Virginia Department of Elections (ELECT). From
the campaign finance reporting home page, we can navigate to “Download
Campaign Finance Data” which takes us to the
[`SBE_CSV/CF/`](https://apps.elections.virginia.gov/SBE_CSV/CF/ "source")
subdirectory of the ELECT website.

On this page, there are additional subdirectories for each year from
1999 until 2012. There are additional subdirectories for each month from
January 2012 to June 2019.

Inside each subdirectory of `/SBE_CSV/CF/`, there are separate CSV files
for each form submitted by committees. Expenditure data is reported by
candidates and committees using “Schedule D” forms, as described by the
[ELECT
website](https://www.elections.virginia.gov/candidatepac-info/campaign-finance-disclosure-forms/index.html):

> Schedule D – Itemization of Expenditures Use to report all
> expenditures incurred by a committee.

From the [instructions on how to fill our Schedule D
forms](https://www.elections.virginia.gov/media/formswarehouse/Campaign-Finance/2018/CampaignFinance/Schedules/2014Schedule-D-Instructions.pdf "instructions"),
we know the following data is included:

1.  The full name of person or company paid and the complete mailing
    address of payee
2.  The description of the item or service purchased
3.  The name of the individual who authorized the expenditure
4.  The date the expense was incurred
5.  The amount of the expenditure

## Import

Schedule D bulk downloads are saved as CSV files, which can easily be
imported once downloaded.

### Download

In the yearly subdirectories (e.g., `/SBE_CSV/CF/2010/`), schedule D
data is separated into two files:

1.  `SBE_CSV/CF/2010/ScheduleD.csv` (5MB)
2.  `SBE_CSV/CF/2010/ScheduleD_PAC.csv` (115KB)

For years after 2011, the files are organized by month and are not
separated:

1.  `SBE_CSV/CF/2013_02/ScheduleD.csv`

We will have to download and read the two types of files differently.

#### Singular

We will start by downloading all the files separated by month from 2012
to 2019.

First we need to create the URLs for each year/month combination.

``` r
sub_dirs <- unlist(map(2012:2019, str_c, str_pad(1:12, 2, side = "left", pad = "0"), sep = "_"))
exp_urls <- sort(glue("https://apps.elections.virginia.gov/SBE_CSV/CF/{sub_dirs}/ScheduleD.csv"))
head(exp_urls)
```

    #> https://apps.elections.virginia.gov/SBE_CSV/CF/2012_01/ScheduleD.csv
    #> https://apps.elections.virginia.gov/SBE_CSV/CF/2012_02/ScheduleD.csv
    #> https://apps.elections.virginia.gov/SBE_CSV/CF/2012_03/ScheduleD.csv
    #> https://apps.elections.virginia.gov/SBE_CSV/CF/2012_04/ScheduleD.csv
    #> https://apps.elections.virginia.gov/SBE_CSV/CF/2012_05/ScheduleD.csv
    #> https://apps.elections.virginia.gov/SBE_CSV/CF/2012_06/ScheduleD.csv

Then we can download these files to our `/data/raw/single/` directory.

``` r
dir_raw_single <- here("va", "expends", "data", "raw", "single")
dir_create(dir_raw_single)

if (!all_files_new(dir_raw_single)) {
  for (url in exp_urls[3:90]) {
    download.file(
      url = url,
      destfile = str_c(
        dir_raw_single,
        url %>% 
          str_extract("(\\d{4}_\\d{2})/ScheduleD.csv$") %>% 
          str_replace_all("/", "_"),
        sep = "/"
      )
    )
  }
}
```

#### Separated

For the years 1999 through 2011, the Schedule D data is held in two
anual files, one for expenditures by PACs and another for all others.

We can download each yearly file to the `/data/raw/separated/`
directory.

``` r
dir_raw_sep <- here("va", "expends", "data", "raw", "separated")
dir_create(dir_raw_sep)

if (!all_files_new(dir_raw_sep)) {
  for (year in 1999:2011) {
    download.file(
      url = glue("https://apps.elections.virginia.gov/SBE_CSV/CF/{year}/ScheduleD.csv"),
      destfile = glue("{dir_raw_sep}/{year}_ScheduleD.csv")
    )
    download.file(
      url = glue("https://apps.elections.virginia.gov/SBE_CSV/CF/{year}/ScheduleD_PAC.csv"),
      destfile = glue("{dir_raw_sep}/{year}_ScheduleD_PAC.csv")
    )
  }
}
```

### Read

Since all files are located in the same directory with the same
structure, we can read them all at once by using `purrr::map()` to apply
`readr::read_csv()` to each file in the directory, then binding each
file into a single data frame using `dplyr::bind_rows()`.

``` r
va <- 
  dir_ls(dir_raw_single, glob = "*.csv") %>% 
  map(
    read_delim,
    delim = ",",
    na = c("NA", "N/A", ""),
    escape_double = FALSE,
    col_types = cols(
      .default = col_character(),
      IsIndividual = col_logical(),
      TransactionDate = col_date("%m/%d/%Y"),
      Amount = col_double()
    )
  ) %>% 
  bind_rows() %>% 
  clean_names()
```

    #> Warning: 2 parsing failures.
    #>  row col   expected     actual                                                                                                    file
    #> 3991  -- 20 columns 22 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2012_04_ScheduleD.csv'
    #> 4567  -- 20 columns 22 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2012_04_ScheduleD.csv'

    #> Warning: 1 parsing failure.
    #> row col   expected     actual                                                                                                    file
    #>  26  -- 20 columns 22 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2012_05_ScheduleD.csv'

    #> Warning: 3 parsing failures.
    #>  row col   expected     actual                                                                                                    file
    #> 8925  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2012_07_ScheduleD.csv'
    #> 8931  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2012_07_ScheduleD.csv'
    #> 8936  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2012_07_ScheduleD.csv'

    #> Warning: 3 parsing failures.
    #>  row col   expected     actual                                                                                                    file
    #>  831  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2012_10_ScheduleD.csv'
    #> 3274  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2012_10_ScheduleD.csv'
    #> 3453  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2012_10_ScheduleD.csv'

    #> Warning: 1 parsing failure.
    #>  row col   expected     actual                                                                                                    file
    #> 2208  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2013_01_ScheduleD.csv'

    #> Warning: 1 parsing failure.
    #>  row col   expected     actual                                                                                                    file
    #> 9115  -- 20 columns 22 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2013_06_ScheduleD.csv'

    #> Warning: 2 parsing failures.
    #>  row col   expected     actual                                                                                                    file
    #> 2601  -- 20 columns 22 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2013_07_ScheduleD.csv'
    #> 4794  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2013_07_ScheduleD.csv'

    #> Warning: 3 parsing failures.
    #> row col   expected     actual                                                                                                    file
    #> 100  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2013_09_ScheduleD.csv'
    #> 103  -- 20 columns 18 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2013_09_ScheduleD.csv'
    #> 104  -- 20 columns 3 columns  '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2013_09_ScheduleD.csv'

    #> Warning: 1 parsing failure.
    #>  row col   expected     actual                                                                                                    file
    #> 6123  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2014_07_ScheduleD.csv'

    #> Warning: 6 parsing failures.
    #>   row col   expected     actual                                                                                                    file
    #>  1861  -- 20 columns 19 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2015_09_ScheduleD.csv'
    #>  1862  -- 20 columns 3 columns  '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2015_09_ScheduleD.csv'
    #> 12485  -- 20 columns 18 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2015_09_ScheduleD.csv'
    #> 12486  -- 20 columns 1 columns  '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2015_09_ScheduleD.csv'
    #> 12487  -- 20 columns 3 columns  '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2015_09_ScheduleD.csv'
    #> ..... ... .......... .......... .......................................................................................................
    #> See problems(...) for more details.

    #> Warning: 9 parsing failures.
    #>  row col   expected     actual                                                                                                    file
    #> 1806  -- 20 columns 19 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2015_10_ScheduleD.csv'
    #> 1807  -- 20 columns 3 columns  '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2015_10_ScheduleD.csv'
    #> 2608  -- 20 columns 22 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2015_10_ScheduleD.csv'
    #> 3034  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2015_10_ScheduleD.csv'
    #> 3274  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2015_10_ScheduleD.csv'
    #> .... ... .......... .......... .......................................................................................................
    #> See problems(...) for more details.

    #> Warning: 2 parsing failures.
    #>  row col   expected     actual                                                                                                    file
    #> 1006  -- 20 columns 19 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2015_11_ScheduleD.csv'
    #> 1007  -- 20 columns 3 columns  '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2015_11_ScheduleD.csv'

    #> Warning: 6 parsing failures.
    #>   row col   expected     actual                                                                                                    file
    #>  8479  -- 20 columns 18 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2015_12_ScheduleD.csv'
    #>  8480  -- 20 columns 1 columns  '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2015_12_ScheduleD.csv'
    #>  8481  -- 20 columns 3 columns  '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2015_12_ScheduleD.csv'
    #> 10212  -- 20 columns 18 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2015_12_ScheduleD.csv'
    #> 10213  -- 20 columns 1 columns  '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2015_12_ScheduleD.csv'
    #> ..... ... .......... .......... .......................................................................................................
    #> See problems(...) for more details.

    #> Warning: 3 parsing failures.
    #>  row col   expected     actual                                                                                                    file
    #> 3938  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2016_07_ScheduleD.csv'
    #> 3939  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2016_07_ScheduleD.csv'
    #> 3940  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2016_07_ScheduleD.csv'

    #> Warning: 16 parsing failures.
    #>  row col   expected     actual                                                                                                    file
    #> 3314  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2016_10_ScheduleD.csv'
    #> 5429  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2016_10_ScheduleD.csv'
    #> 5430  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2016_10_ScheduleD.csv'
    #> 5431  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2016_10_ScheduleD.csv'
    #> 5432  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2016_10_ScheduleD.csv'
    #> .... ... .......... .......... .......................................................................................................
    #> See problems(...) for more details.

    #> Warning: 1 parsing failure.
    #>   row col   expected     actual                                                                                                    file
    #> 12812  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2017_01_ScheduleD.csv'

    #> Warning: 3 parsing failures.
    #>   row col   expected     actual                                                                                                    file
    #> 10723  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2017_07_ScheduleD.csv'
    #> 12373  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2017_07_ScheduleD.csv'
    #> 20702  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2017_07_ScheduleD.csv'

    #> Warning: 11 parsing failures.
    #>   row col   expected     actual                                                                                                    file
    #>  1122  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2017_10_ScheduleD.csv'
    #>  1465  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2017_10_ScheduleD.csv'
    #> 12851  -- 20 columns 19 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2017_10_ScheduleD.csv'
    #> 12852  -- 20 columns 4 columns  '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2017_10_ScheduleD.csv'
    #> 17639  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2017_10_ScheduleD.csv'
    #> ..... ... .......... .......... .......................................................................................................
    #> See problems(...) for more details.

    #> Warning: 2 parsing failures.
    #>  row col   expected     actual                                                                                                    file
    #> 6800  -- 20 columns 18 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2017_12_ScheduleD.csv'
    #> 6801  -- 20 columns 3 columns  '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2017_12_ScheduleD.csv'

    #> Warning: 1 parsing failure.
    #>   row col   expected     actual                                                                                                    file
    #> 11632  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_01_ScheduleD.csv'

    #> Warning: 8 parsing failures.
    #>  row             col               expected     actual                                                                                                    file
    #> 1153 IsIndividual    1/0/T/F/TRUE/FALSE     10014      '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_06_ScheduleD.csv'
    #> 1153 TransactionDate date like %m/%d/%Y     False      '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_06_ScheduleD.csv'
    #> 1153 Amount          no trailing characters /06/2018   '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_06_ScheduleD.csv'
    #> 1153 NA              20 columns             21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_06_ScheduleD.csv'
    #> 1154 IsIndividual    1/0/T/F/TRUE/FALSE     10014      '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_06_ScheduleD.csv'
    #> .... ............... ...................... .......... .......................................................................................................
    #> See problems(...) for more details.

    #> Warning: 13 parsing failures.
    #> row col   expected     actual                                                                                                    file
    #> 888  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_09_ScheduleD.csv'
    #> 889  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_09_ScheduleD.csv'
    #> 890  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_09_ScheduleD.csv'
    #> 891  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_09_ScheduleD.csv'
    #> 892  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_09_ScheduleD.csv'
    #> ... ... .......... .......... .......................................................................................................
    #> See problems(...) for more details.

    #> Warning: 12 parsing failures.
    #>   row col   expected     actual                                                                                                    file
    #>  4102  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_10_ScheduleD.csv'
    #>  7826  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_10_ScheduleD.csv'
    #> 10189  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_10_ScheduleD.csv'
    #> 10190  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_10_ScheduleD.csv'
    #> 10191  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_10_ScheduleD.csv'
    #> ..... ... .......... .......... .......................................................................................................
    #> See problems(...) for more details.

    #> Warning: 116 parsing failures.
    #> row col   expected     actual                                                                                                    file
    #>   1  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_12_ScheduleD.csv'
    #>   2  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_12_ScheduleD.csv'
    #>   3  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_12_ScheduleD.csv'
    #>   4  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_12_ScheduleD.csv'
    #>   5  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2018_12_ScheduleD.csv'
    #> ... ... .......... .......... .......................................................................................................
    #> See problems(...) for more details.

    #> Warning: 101 parsing failures.
    #>  row col   expected     actual                                                                                                    file
    #> 2620  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2019_01_ScheduleD.csv'
    #> 2621  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2019_01_ScheduleD.csv'
    #> 2622  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2019_01_ScheduleD.csv'
    #> 2623  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2019_01_ScheduleD.csv'
    #> 2624  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2019_01_ScheduleD.csv'
    #> .... ... .......... .......... .......................................................................................................
    #> See problems(...) for more details.

    #> Warning: 3 parsing failures.
    #>  row col   expected     actual                                                                                                    file
    #> 1207  -- 20 columns 18 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2019_02_ScheduleD.csv'
    #> 1208  -- 20 columns 1 columns  '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2019_02_ScheduleD.csv'
    #> 1209  -- 20 columns 3 columns  '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2019_02_ScheduleD.csv'

    #> Warning: 6 parsing failures.
    #>   row col   expected     actual                                                                                                    file
    #>  3984  -- 20 columns 22 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2019_04_ScheduleD.csv'
    #>  7075  -- 20 columns 22 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2019_04_ScheduleD.csv'
    #> 18637  -- 20 columns 18 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2019_04_ScheduleD.csv'
    #> 18638  -- 20 columns 4 columns  '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2019_04_ScheduleD.csv'
    #> 22082  -- 20 columns 18 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2019_04_ScheduleD.csv'
    #> ..... ... .......... .......... .......................................................................................................
    #> See problems(...) for more details.

    #> Warning: 2 parsing failures.
    #>   row col   expected     actual                                                                                                    file
    #>   249  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2019_06_ScheduleD.csv'
    #> 16630  -- 20 columns 21 columns '/home/ubuntu/R/accountability_datacleaning/R_campfin/va/expends/data/raw/single/2019_06_ScheduleD.csv'

## Explore

There are 705142 records of 20 variables in the full database.

``` r
glimpse(sample_frac(va))
```

    #> Observations: 705,142
    #> Variables: 20
    #> $ schedule_d_id        <chr> "723980", "1274180", "1156016", "2492842", "1025198", "1256159", "1…
    #> $ report_id            <chr> "44387", "87748", "75034", "164252", "65521", "86096", "119055", "1…
    #> $ committee_contact_id <chr> "161611", NA, "281572", "561549", "65899", "298902", "290838", "537…
    #> $ first_name           <chr> NA, "Katherine", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
    #> $ middle_name          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
    #> $ last_or_company_name <chr> "PayPal", "Buchanan", "Party City", "Leadership for Educational Equ…
    #> $ prefix               <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
    #> $ suffix               <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
    #> $ address_line1        <chr> "2211 North 1st Street", "1751 Potomac Greens Dr", "4107 Portsmouth…
    #> $ address_line2        <chr> NA, NA, NA, NA, NA, NA, NA, NA, "Suite 104", NA, NA, NA, NA, NA, NA…
    #> $ city                 <chr> "San Jose", "Alexandria", "Chesapeake", "Washington", "Virginia Bea…
    #> $ state_code           <chr> "CA", "VA", "VA", "DC", "VA", "VA", "VA", "VA", "FL", "CA", "VA", "…
    #> $ zip_code             <chr> "95131", "22314-6233", "23321", "20001", "23456", "23601", "20153",…
    #> $ is_individual        <lgl> FALSE, TRUE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE,…
    #> $ transaction_date     <date> 2014-04-09, 2015-12-09, 2015-09-11, 2019-04-03, 2015-06-01, 2015-1…
    #> $ amount               <dbl> 8.15, 500.00, 49.11, 300.00, 15.00, 500.00, 500.00, 1000.00, 3700.0…
    #> $ authorizing_name     <chr> "Sandra Phillips", "Scott Remley", "Marcia Price", "Nathanael Swans…
    #> $ item_or_service      <chr> "PayPal fees", "Compliance Services", "items for event", "Consultin…
    #> $ schedule_id          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
    #> $ report_uid           <chr> "{482C483B-2806-BA91-2613-681A2F96BEF0}", "{209A44BC-6B1B-C2D4-14F0…

### Distinct

The variables range in their degree of distinctness.

``` r
va %>% 
  map(n_distinct) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_distinct") %>% 
  mutate(prop_distinct = round(n_distinct / nrow(va), 4)) %>%
  print(n = length(va))
```

    #> # A tibble: 20 x 3
    #>    variable             n_distinct prop_distinct
    #>    <chr>                     <int>         <dbl>
    #>  1 schedule_d_id            705132        1     
    #>  2 report_id                 37736        0.0535
    #>  3 committee_contact_id     126512        0.179 
    #>  4 first_name                 7347        0.0104
    #>  5 middle_name                 918        0.0013
    #>  6 last_or_company_name      66841        0.0948
    #>  7 prefix                        1        0     
    #>  8 suffix                        1        0     
    #>  9 address_line1             82752        0.117 
    #> 10 address_line2              4908        0.007 
    #> 11 city                       5824        0.0083
    #> 12 state_code                   59        0.0001
    #> 13 zip_code                  18476        0.0262
    #> 14 is_individual                 3        0     
    #> 15 transaction_date           2775        0.0039
    #> 16 amount                    76332        0.108 
    #> 17 authorizing_name           7414        0.0105
    #> 18 item_or_service           99137        0.141 
    #> 19 schedule_id                  72        0.0001
    #> 20 report_uid                29866        0.0424

We can explore the distribution of the least distinct values with
`ggplot2::geom_bar()`.

![](../plots/type_bar-1.png)<!-- -->

Or, filter the data and explore the most frequent discrete data.

![](../plots/state_bar-1.png)<!-- -->

The `item_or_service` variable is an open-ended text field, so we can
only analyze it by frequency or word tokens.

``` r
va %>% 
  unnest_tokens(word, item_or_service) %>% 
  mutate(word = str_to_lower(word)) %>%
  count(word, sort = TRUE) %>% 
  anti_join(stop_words) %>% 
  head(20) %>% 
  ggplot() + 
  geom_col(aes(reorder(word, n), n)) +
  coord_flip() +
  labs(x = "Word", y = "count")
```

![](../plots/words_bar-1.png)<!-- -->

### Missing

The variables also vary in their degree of values that are `NA`
(missing).

``` r
va %>% 
  map(function(var) sum(is.na(var))) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_na") %>% 
  mutate(prop_na = n_na / nrow(va)) %>% 
  print(n = length(va))
```

    #> # A tibble: 20 x 3
    #>    variable               n_na   prop_na
    #>    <chr>                 <int>     <dbl>
    #>  1 schedule_d_id             0 0        
    #>  2 report_id                17 0.0000241
    #>  3 committee_contact_id 211245 0.300    
    #>  4 first_name           562378 0.798    
    #>  5 middle_name          678115 0.962    
    #>  6 last_or_company_name     27 0.0000383
    #>  7 prefix               705142 1        
    #>  8 suffix               705142 1        
    #>  9 address_line1          4966 0.00704  
    #> 10 address_line2        604108 0.857    
    #> 11 city                   1310 0.00186  
    #> 12 state_code             1630 0.00231  
    #> 13 zip_code               2796 0.00397  
    #> 14 is_individual            24 0.0000340
    #> 15 transaction_date         24 0.0000340
    #> 16 amount                   24 0.0000340
    #> 17 authorizing_name      18241 0.0259   
    #> 18 item_or_service        3427 0.00486  
    #> 19 schedule_id          704845 1.000    
    #> 20 report_uid              322 0.000457

### Duplicates

### Ranges

We can explore the continuous variables with `ggplot2::geom_histogram()`
and `base::summary()`

#### Amounts

    #> Warning: Transformation introduced infinite values in continuous x-axis

    #> Warning: Removed 74 rows containing non-finite values (stat_bin).

![](../plots/amount_hist-1.png)<!-- -->

    #> Warning: Transformation introduced infinite values in continuous x-axis

    #> Warning: Removed 50 rows containing non-finite values (stat_bin).

![](../plots/amount_hist_ind-1.png)<!-- -->

    #> Warning: Transformation introduced infinite values in continuous y-axis

    #> Warning: Removed 50 rows containing non-finite values (stat_boxplot).

![](../plots/amount_box_ind-1.png)<!-- -->

    #> Warning: Removed 1 rows containing missing values (geom_path).

![](../plots/mean_month_line-1.png)<!-- -->

### Dates

``` r
max(va$transaction_date, na.rm = TRUE)
#> [1] "2019-06-28"
min(va$transaction_date, na.rm = TRUE)
#> [1] "2009-10-01"
```

    #> Warning: Removed 1 rows containing missing values (position_stack).

![](../plots/n_year_bar-1.png)<!-- -->

    #> Warning: Removed 1 rows containing missing values (geom_path).

![](../plots/n_month_line-1.png)<!-- -->

## Wrangle

### Year

Add a `year` variable from `date` after `col_date()` using
`lubridate::year()`.

``` r
va <- va %>% mutate(transaction_year = year(transaction_date))
```

### Address

The `address` variable should be minimally cleaned by removing
punctuation and fixing white-space.

``` r
va <- va %>% 
  mutate(
    address1_clean = address_line1 %>% 
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

``` r
va <- va %>% 
  mutate(
    zip_clean = zip_code %>% 
      str_remove_all(rx_whitespace()) %>%
      str_remove_all(rx_digit(inverse = TRUE)) %>% 
      str_pad(width = 5, pad = "0") %>% 
      str_sub(1, 5) %>%
      na_if("00000") %>% 
      na_if("11111") %>% 
      na_if("99999") %>% 
      na_if("")
  )
```

### State

Using comprehensive list of state abbreviations in the Zipcodes
database, we can isolate invalid `state` values and manually correct
them.

``` r
valid_state <- c(unique(zipcode$state), "AB", "BC", "MB", "NB", "NL", "NS", "ON", "PE", "QC", "SK")
length(valid_state)
#> [1] 72
setdiff(valid_state, state.abb)
#>  [1] "PR" "VI" "AE" "DC" "AA" "AP" "AS" "GU" "PW" "FM" "MP" "MH" "AB" "BC" "MB" "NB" "NL" "NS" "ON"
#> [20] "PE" "QC" "SK"
```

``` r
setdiff(va$state_code, valid_state)
```

    #> [1] NA         "New York"

``` r
va <- va %>% mutate(state_clean = state_code %>% str_replace("New York", "NY"))
```

### City

``` r
valid_city <- unique(zipcode$city)
n_distinct(va$city)
#> [1] 5824
mean(va$city %in% zipcode$city)
#> [1] 0.05339492
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

#### Prep

``` r
va <- va %>%
  rename(city_raw = city) %>% 
  mutate(
    city_prep = prep_city(
      cities = city_raw,
      na = read_lines(here("R", "na_city.csv")),
      abbs = c("VA", "MA", "DC", "VIRGINIA")
    ) %>% 
      str_replace("^VA\\b", "VIRGINIA")
  )

n_distinct(va$city_prep)
```

    #> [1] 4273

``` r
mean(va$city_prep %in% zipcode$city)
```

    #> [1] 0.9705166

#### Swap

``` r
va <- va %>%
  left_join(
    zipcode,
    by = c(
      "state_clean" = "state",
      "zip_clean" = "zip"
    )
  ) %>%
  rename(city_match = city) %>%
  mutate(
    match_dist = stringdist(city_prep, city_match),
    city_swap = if_else(match_dist < 3, city_match, city_prep)
  )

summary(va$match_dist)
```

    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
    #>   0.000   0.000   0.000   0.348   0.000  32.000   12984

``` r
tabyl(va$match_dist == 0)
```

    #> # A tibble: 3 x 4
    #>   `va$match_dist == 0`      n percent valid_percent
    #>   <lgl>                 <dbl>   <dbl>         <dbl>
    #> 1 FALSE                 34152  0.0484        0.0493
    #> 2 TRUE                 658006  0.933         0.951 
    #> 3 NA                    12984  0.0184       NA

``` r
va %>% 
  filter(city_swap %out% valid_city) %>%
  count(city_swap, sort = TRUE)
```

    #> # A tibble: 481 x 2
    #>    city_swap              n
    #>    <chr>              <int>
    #>  1 <NA>               12984
    #>  2 WEST SOMERVILLE     2449
    #>  3 NORTH CHESTERFIELD  1968
    #>  4 SOUTH RIDING        1011
    #>  5 DALE CITY            806
    #>  6 MANASSAS PARK        368
    #>  7 GLENN ALLAN          249
    #>  8 POTOMAC FALLS        238
    #>  9 LAKE RIDGE           211
    #> 10 SAN FRANSICO         206
    #> # … with 471 more rows

#### Refine

``` r
va_refined <- va %>%
  filter(state_clean == "VA") %>% 
  filter(match_dist != 1) %>% 
  mutate(
    city_refine = if_else(
      condition = match_dist > 2,
      true = city_swap %>% 
        key_collision_merge() %>% 
        n_gram_merge(),
      false = city_swap
    )
  ) %>% 
  filter(city_refine != city_swap) %>% 
  select(
    schedule_d_id,
    state_clean,
    zip_clean,
    city_raw,
    city_prep,
    city_match,
    city_swap,
    city_refine
  )
```

#### Review

``` r
va_refined %>% 
  select(-schedule_d_id) %>%
  distinct()
```

    #> # A tibble: 13 x 7
    #>    state_clean zip_clean city_raw       city_prep      city_match      city_swap     city_refine   
    #>    <chr>       <chr>     <chr>          <chr>          <chr>           <chr>         <chr>         
    #>  1 VA          22041     Baileys Cross… BAILEYS CROSS… FALLS CHURCH    BAILEYS CROS… BAILEYS CROSS…
    #>  2 VA          22314     Carrolton      CARROLTON      ALEXANDRIA      CARROLTON     CARROLLTON    
    #>  3 VA          22973     Sommerville    SOMMERVILLE    STANARDSVILLE   SOMMERVILLE   SOMERVILLE    
    #>  4 VA          20178     Manasssas      MANASSSAS      LEESBURG        MANASSSAS     MANASSAS      
    #>  5 VA          22201     ArlingtonArli… ARLINGTONARLI… ARLINGTON       ARLINGTONARL… ARLINGTON     
    #>  6 VA          23454     Culpepper      CULPEPPER      VIRGINIA BEACH  CULPEPPER     CULPEPER      
    #>  7 VA          22546     Rutherford Gl… RUTHERFORD GL… RUTHER GLEN     RUTHERFORD G… RUTHERFORD GL…
    #>  8 VA          22456     Ruther Glenn   RUTHER GLENN   EDWARDSVILLE    RUTHER GLENN  RUTHER GLEN   
    #>  9 VA          23002     Amellia        AMELLIA        AMELIA COURT H… AMELLIA       AMELIA        
    #> 10 VA          23963     Crew           CREW           RED HOUSE       CREW          CREWE         
    #> 11 VA          22307     ALEXA          ALEXA          ALEXANDRIA      ALEXA         ALEX          
    #> 12 VA          23323     Carrolton      CARROLTON      CHESAPEAKE      CARROLTON     CARROLLTON    
    #> 13 VA          20111     Mansassas Park MANSASSAS PARK MANASSAS        MANSASSAS PA… MANASSAS PARK

``` r
va_refined %>% 
  count(state_clean, city_refine, sort = TRUE)
```

    #> # A tibble: 12 x 3
    #>    state_clean city_refine            n
    #>    <chr>       <chr>              <int>
    #>  1 VA          CREWE                  8
    #>  2 VA          BAILEYS CROSSROADS     4
    #>  3 VA          RUTHER GLEN            4
    #>  4 VA          AMELIA                 2
    #>  5 VA          CARROLLTON             2
    #>  6 VA          CULPEPER               2
    #>  7 VA          SOMERVILLE             2
    #>  8 VA          ALEX                   1
    #>  9 VA          ARLINGTON              1
    #> 10 VA          MANASSAS               1
    #> 11 VA          MANASSAS PARK          1
    #> 12 VA          RUTHERFORD GLENN       1
