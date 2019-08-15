# campfin

This folder contains the [R project][rproj] for collecting and cleaning state-level campaign
finance records.

[rproj]: https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects

## Structure

To begin working on the R project, clone the `campfin` branch of this repository.

```
git clone -b campfin git@github.com:irworkshop/accountability_datacleaning.git
```

Then in [RStudio](https://www.rstudio.com/), open the `R_campfin.Rproj` file.

Data is organized by state at the top level of the R project, with data organized by data type
(contributions or expenditures). The [`fs`][fs] package is used to create and explore the
additional subdirectories:

1. `/docs` for diaries and keys
1. `/data/raw` for _immutable_ raw data
1. `/data/clean` for processed data
1. `/plots` for exploratory graphics

```
├── tn
├── tx
│   └── data
│       ├── raw
│       │   ├── TEC_CF_CSV.zip
│   └── contribs
│   └── expends
│       ├── data
│       │   ├── clean
│       │   │   └── tx_expendS_clean.csv
│       │   └── raw
│       │       ├── expend_01.csv
│       │       ├── expend_02.csv
│       │       ├── expn_catg.csv
│       │       └── expn_t.csv
│       ├── docs
│       │   ├── CFS-ReadMe.txt
│       │   ├── CampaignFinanceCSVFileFormat.pdf
│       │   ├── tx_expends_diary.Rmd
│       │   └── tx_expends_diary.md
│       └── plots
│           ├── amount_histogram-1.png
│           ├── amount_violin-1.png
│           ├── category_bar-1.png
│           └── year_bar-1.png

```

[fs]: https://github.com/r-lib/fs

## Data

Data is collected from the individual states. All data is public record, but not all data is easily
accessible from the internet; some states provided data in bulk downloads while others deliver them
in hard copy after a FOIA request.

## Process

We've are standardizing public data on a few key fields by thinking of each dataset row as a
transaction. For each transaction there should be (at least) 3 variables:

1. All **parties** to a transaction
1. The **date** of the transaction
1. The **amount** of money involved

Data manipulation follows the [IRW data cleaning guide][guide] to achieve the following objectives: 

[guide]: https://github.com/irworkshop/accountability_datacleaning/blob/campfin/IRW_guides/data_check_guide.md

1. How many records are in the database? Does it seem to be in the correct range?
1. Check for duplicates in cases where true duplicates would be a problem. 
1. Check ranges: Are numeric fields in ranges that make sense. Anything too high or too low?
1. Is there anything blank or missing?
1. Is there information in the wrong field?
1. Check for consistency issues - particularly on city, state and ZIP.
1. Create a five-digit ZIP Code if one does not exist.
1. Create a four-digit `year` field from the transaction date.
1. For campaign donation data, make sure there is both a donor AND recipient.

The documents in each state's `/docs` folder record the entire process to allow for reproducibility
and transparency. The `template_diary.Rmd` file can be used as a template for the typical process,
which has the following steps:

1. **Import**
    1. Download with `download.file()` or `RSelenium::rsDriver()`
    1. Read with `readr::read_delim()` or `vroom::vroom()`
1. **Explore**
    1. Missing values with `campfin::flag_na()`
    1. Duplicate records with `campfin::flag_dupes()`
    1. Categorical value counts with `ggplot2::geom_bar()`
    1. Continuous value ranges with `ggplot2::geom_histogram()`
1. **Wrangle**
    1. Addresses with `campfin::normal_address()`
    1. ZIP codes with `campfin::normal_zip()`
    1. State abbreviations with `campfin::normal_state()`
    1. City names
        1. Normalize with `campfin::normal_city()`
        1. Match with `dplyr::left_join()`
        1. Swap with `stringdist::stringdist()`
        1. Refine with `refinr::n_gram_merge()`
1. **Export** with `readr::write_csv()`

## Software

Software used is free and open source. R can be downloaded from a CRAN mirror. 

The [`campfin`][campfin] R package has been written to facilitate exploration and wrangling. This
package needs to be installed directly from GitHub.

```R
if (!require("pacman")) install.packages("pacman")
pacman::p_load_current_gh("kiernann/campfin")
```

[campfin]: https://github.com/kiernann/campfin

The following additional R packages should be installed to reproduce our processing:

```R
pacman::p_load(
  stringdist, # find levenshtein distance
  snakecase, # convert a string case
  RSelenium, # naviagte a remote browser
  tidyverse, # perform data manipulation
  lubridate, # manipulate datetime strings
  tidytext, # perform tokenized text analysis
  magrittr, # improve readability with pipes
  janitor, # simple tools for cleaning
  batman, # c(rep(NA, 8), "Batman!")
  refinr, # cluster and merge siliar values
  scales, # format strings for readability
  knitr, # knit and explore markdown files
  vroom, # read many files quickly
  glue, # combine strings and code
  here, # keep paths relative to project
  httr, # query modern web APIs
  fs # create and search local storage 
)
```

## Help

If you know of a dataset that you think belongs here, [suggest it for inclusion][help]. We're
especially interested in the data that agencies have hidden behind "search portals" or state
legislative exemptions. Have you scraped a gnarly records site? Share it with us and we'll credit
you. And more importantly, other people may benefit from your hard work.

[help]: https://www.publicaccountability.org/static/apps/submit/index.html
