Missouri Expenditures
================
Kiernan Nicholls
2019-08-22 11:37:45

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)

<!-- Place comments regarding knitting here -->

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

The IRW’s `campfin` package will also have to be installed from GitHub.
This package contains functions custom made to help facilitate the
processing of campaign finance data.

``` r
if (!require("pacman")) install.packages("pacman")
pacman::p_load_current_gh("kiernann/campfin")
pacman::p_load(
  stringdist, # levenshtein value
  RSelenium, # remote browser
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

Data is obtained from the [New York Board of
Elections](https://www.elections.ny.gov/INDEX.html) (SBOE).

> The State Board of Elections was established in the Executive
> Department June 1, 1974 as a bipartisan agency vested with the
> responsibility for administration and enforcement of all laws relating
> to elections in New York State. The Board is also responsible for
> regulating disclosure and limitations of a Fair Campaign Code intended
> to govern campaign practices. In conducting these wide-ranging
> responsibilities, the Board offers assistance to local election boards
> and investigates complaints of possible statutory violations. In
> addition to the regulatory and enforcement responsibilities the board
> is charged with the preservation of citizen confidence in the
> democratic process and enhancement in voter participation in
> elections.

The SBOE database can be obstained from their Campaign Finance
[discolure reports
page](https://www.elections.ny.gov/CFViewReports.html). On that page,
they elaborate on the availability and accuracy of the website.

> ### Data Availability
> 
> This database contains all financial disclosure reports filed with
> NYSBOE from July of 1999 to the present. Financial disclosure reports
> filed prior to the 1999 July Periodic report are either on file with
> the New York State Archives or in storage with the New York State
> Board of Elections. For further information or to obtain copies of
> these archived or stored filings, please call 1-800-458-3453. Each
> page costs 25¢ plus postage and copy orders must be prepaid.
> 
> Electronically filed disclosure reports are generally available in the
> database on the day they are received. A small number of candidates
> and committees are either statutorily exempt or have applied for and
> obtained exemptions from electronic filing. These filers will continue
> filing on paper and their disclosure reports will become available as
> they are manually entered into the database by NYSBOE staff.

> ### Data Accuracy
> 
> The majority of financial disclosure reports filed at NYSBOE are
> entered into the database directly from e-mail, diskette, CD or DVD
> filings submitted by committee treasurers or candidates. The
> information contained in paper filings will be entered into the
> database exactly as it appears on the forms. Because database searches
> retrieve information exactly the way it is reported and then entered
> into the database, search results may be inaccurate and/or incomplete.
> This will occur, for example, if filers do not adhere to the required
> format, do not use the proper codes, misspell words or leave items
> blank. Although NYSBOE carefully reviews disclosure reports and
> requires treasurers to submit amended reports as needed, there will
> necessarily be delays before the review process is completed and the
> information in the database is corrected.

The page also describes the format of their campaign finance database.

> ### Database Files in ASCII Delimited Format
> 
> **Updated data files are uploaded during active filing periods after
> 4:00 P.M. daily until the filing is complete.**
> 
> **Note:** To match the filing data files to Filer Names by filer ID
> you will need to Download the Filer data file. Commcand.zip is a
> zipped file containing the data file (commcand.asc) in ASCII delimited
> and two text files. (filerec.txt contains the data file layout -
> codes.txt explains the codes used in the data file).
> 
> **All downloadable files are zipped files containing a data file in
> ASCII delimited format and two text files. (efsrecb.txt contains the
> data file layout - efssched.txt explains the different schedules as
> they apply to the database).**
> 
> [Download Data file containing ALL
> filings](https://www.elections.ny.gov/NYSBOE/download/ZipDataFiles/ALL_REPORTS.zip).
> **Note:** This file is a large file (238, 994 KB) that contains over 6
> million records. Do not attempt to download this file unless you have
> a database to download the file to.

## Import

We can import each file into R as a single data frame to be explored,
wrangled, and exported as a single file to be indexed on the TAP
database.
