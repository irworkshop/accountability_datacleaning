
# campfin

This folder contains the [R
project](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects)
for collecting and cleaning state-level campaign finance records.

## Structure

To begin working on the R project, clone the `campfin` branch of this
repository.

    $ git clone -b campfin git@github.com:irworkshop/accountability_datacleaning.git

Then in [RStudio](https://www.rstudio.com/), open the `R_campfin.Rproj`
file.

Data is organized by state at the top level of the R project, with files
organized by data type subdirectories (contributions, expenditures,
lobbyists, etc). The [`fs`](https://github.com/r-lib/fs) package is used
to create and explore the additional subdirectories.

1.  `docs/` for diaries and keys
2.  `data/raw` for *immutable* raw data
3.  `data/clean` for processed data
4.  `plots/` for exploratory graphics

<!-- end list -->

``` r
fs::dir_tree("dc/contribs")
```

    ## dc/contribs
    ## ├── data
    ## │   ├── processed
    ## │   │   └── dc_contribs_clean.csv
    ## │   └── raw
    ## ├── docs
    ## │   ├── dc_contribs_diary.Rmd
    ## │   └── dc_contribs_diary.md
    ## └── plots
    ##     ├── amount_bar_median_year-1.png
    ##     ├── amount_box_how-1.png
    ##     ├── amount_box_who-1.png
    ##     ├── amount_hist-1.png
    ##     ├── amount_hist_how-1.png
    ##     ├── amount_line_month-1.png
    ##     ├── distinct_val_bar-1.png
    ##     ├── how_bar-1.png
    ##     ├── prop_valid_bar-1.png
    ##     ├── size_point_map-1.png
    ##     ├── ward_bar-1.png
    ##     ├── who_bar-1.png
    ##     └── year_bar-1.png

## Data

Data is collected from the individual states. All data is public record,
but not all data is easily accessible from the internet; some states
provided data in bulk downloads while others deliver them in hard copy.

## Process

We are standardizing public data on a few key fields by thinking of each
dataset row as a transaction. For each transaction there should be (at
least) 3 variables:

1.  All **parties** to a transaction
2.  The **date** of the transaction
3.  Any **amount** of money involved

Data manipulation follows the [IRW data cleaning
guide](https://github.com/irworkshop/accountability_datacleaning/blob/campfin/IRW_guides/data_check_guide.md)
to achieve the following objectives:

1.  How many records are in the database? Does it seem to be in the
    correct range?
2.  Check for duplicates in cases where true duplicates would be a
    problem.
3.  Check ranges: Are numeric fields in ranges that make sense. Anything
    too high or too low?
4.  Is there anything blank or missing?
5.  Is there information in the wrong field?
6.  Check for consistency issues - particularly on city, state and ZIP.
7.  Create a five-digit ZIP Code if one does not exist.
8.  Create a four-digit `year` field from the transaction `date`.
9.  For campaign donation data, make sure there is both a donor *and*
    recipient.

The documents in each state’s `docs/` folder record the entire process
to promote for reproducibility and transparency. The
`template_diary.Rmd` file can be used as a template for the typical
process, which has the following steps:

1.  Describe
2.  Import
3.  Explore
4.  Wrangle
5.  Export

## Software

Software used is free and open source. R can be downloaded from a [CRAN
mirror](https://cran.r-project.org/mirrors.html).

The [`campfin`](https://github.com/irworkshop/campfin) R package has
been written by IRW to facilitate exploration and wrangling of campaign
finance data. As of now, package needs to be installed directly from
GitHub.

``` r
# install.packages("remotes")
remotes::install_github("irworkshp/campfin")
```

Most cleaning is done using the
[tidyverse](https://github.com/tidyverse), an opinionated collection of
R packages which can be easily downloaded with:

``` r
install.packages("tidyverse")
```

## Help

If you know of a dataset that you think belongs here, [suggest it for
inclusion](https://www.publicaccountability.org/static/apps/submit/index.html).
We’re especially interested in the data that agencies have hidden behind
“search portals” or state legislative exemptions. Have you scraped a
gnarly records site? Share it with us and we’ll credit you. And more
importantly, other people may benefit from your hard work.
