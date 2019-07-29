Arkansas Expenditures
================
Kiernan Nicholls
2019-07-29 12:34:08

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Explore](#explore)

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
pacman::p_load(
  stringdist, # levenshtein value
  RSelenium, # remote browsing
  tidyverse, # data manipulation
  lubridate, # datetime strings
  magrittr, # pipe opperators
  janitor, # dataframe clean
  zipcode, # clean & database
  vroom, # ready many files
  knitr, # knit documents
  here, # relative storage
  fs # search storage 
)
```

The IRW’s `campfin` package will also have to be installed from GitHub.
This package contains functions custom made to help facilitate the
processing of campaign finance data.

``` r
pacman::p_load_current_gh("kiernann/campfin")
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

Data is obtained from the Arkansas Secretary of State’s [Financial
Disclosure
portal](https://financial-disclosures.sos.arkansas.gov/index.html#/dataDownload).

> This page provides comma separated value (CSV) downloads of
> contribution, expenditure, and loan data for each reporting year in a
> zipped file format. These files can be downloaded and imported into
> other applications (Microsoft Excel, Microsoft Access, etc.) This data
> is extracted from the Arkansas Campaign Finance database as it existed
> as of 07/29/2019 11:11 AM.

The AK SOS also provides a [data
key](https://financial-disclosures.sos.arkansas.gov//CFISAR_Service/Template/KeyDownloads/Expenditures,%20Debts,%20and%20Payments%20to%20Workers%20File%20Layout%20Key.pdf).

### Download

We can only download the data by navigating to the website and manually
clicking the “Download File” button next to each expenditures file. We
can automate this process somewhat with the RSelenium package.

``` r
raw_dir <- here("ar", "expends", "data", "raw")
dir_create(raw_dir)
```

``` r
# open the driver with auto download options
remote_driver <- rsDriver(
  port = 4444L,
  browser = "firefox",
  extraCapabilities = makeFirefoxProfile(
    list(
      browser.download.dir = raw_dir,
      browser.download.folderList = 2L,
      browser.helperApps.neverAsk.saveToDisk = "text/csv"
    )
  )
)

# navigate to the FL DOE download site
remote_browser <- remote_driver$client
remote_browser$navigate("https://financial-disclosures.sos.arkansas.gov/index.html#/dataDownload")

link_2019 <- "tbody.md-body:nth-child(4) > tr:nth-child(1) > td:nth-child(3) > a:nth-child(1)"
link_2018 <- "tbody.md-body:nth-child(5) > tr:nth-child(1) > td:nth-child(3) > a:nth-child(1)"
link_2017 <- "tbody.md-body:nth-child(8) > tr:nth-child(1) > td:nth-child(3) > a:nth-child(1)"

remote_browser$findElement("css", link_2019)$clickElement()
remote_browser$findElement("css", link_2018)$clickElement()
remote_browser$findElement("css", link_2017)$clickElement()

# close the browser and driver
remote_browser$close()
remote_driver$server$stop()
```

### Read

``` r
ar <- 
  vroom(
    file = dir_ls(raw_dir),
    delim = ",",
    escape_backslash = FALSE,
    escape_double = FALSE,
    col_types = cols(.default = "c")
  ) %>% 
  clean_names() %>%
  mutate_at(
    vars(expenditure_amount), 
    parse_double
  ) %>% 
  mutate_at(
    vars(expenditure_date, filed_date),
    parse_date, format = "%m/%d/%Y %H:%M:%S %p"
  )
```

## Explore

``` r
head(ar)
```

    #> # A tibble: 6 x 21
    #>   org_id expenditure_amo… expenditure_date last_name first_name middle_name suffix address1
    #>   <chr>             <dbl> <date>           <chr>     <chr>      <chr>       <chr>  <chr>   
    #> 1 219790              125 2017-09-27       KXIO Rad… <NA>       <NA>        <NA>   901 Sou…
    #> 2 219790              140 2017-08-03       KXIO Rad… <NA>       <NA>        <NA>   901 Sou…
    #> 3 219790              350 2017-09-27       Johnson … <NA>       <NA>        <NA>   1586 Oa…
    #> 4 219790             1470 2017-09-09       South Lo… <NA>       <NA>        <NA>   1105 Ca…
    #> 5 219790             1550 2017-08-19       North Lo… <NA>       <NA>        <NA>   PO Box …
    #> 6 219790             1820 2017-09-09       Yell Cou… <NA>       <NA>        <NA>   PO Box …
    #> # … with 13 more variables: address2 <chr>, city <chr>, state <chr>, zip <chr>, explanation <chr>,
    #> #   expenditure_id <chr>, filed_date <date>, purpose <chr>, expenditure_type <chr>,
    #> #   committee_type <chr>, committee_name <chr>, candidate_name <chr>, amended <chr>

``` r
tail(ar)
```

    #> # A tibble: 6 x 21
    #>   org_id expenditure_amo… expenditure_date last_name first_name middle_name suffix address1
    #>   <chr>             <dbl> <date>           <chr>     <chr>      <chr>       <chr>  <chr>   
    #> 1 333026             11.3 2019-05-27       Go Daddy  <NA>       <NA>        <NA>   1445 N.…
    #> 2 333026             51   2019-05-17       Betsy Ha… <NA>       <NA>        <NA>   215 Eas…
    #> 3 333026             51   2019-05-28       Betsy Ha… <NA>       <NA>        <NA>   215 Eas…
    #> 4 333026             67.7 2019-05-30       Go Daddy  <NA>       <NA>        <NA>   1445 N.…
    #> 5 333026            450   2019-06-21       The Canc… <NA>       <NA>        <NA>   5835 W.…
    #> 6 333026           2332   2019-06-04       NWA Bran… <NA>       <NA>        <NA>   21922 W…
    #> # … with 13 more variables: address2 <chr>, city <chr>, state <chr>, zip <chr>, explanation <chr>,
    #> #   expenditure_id <chr>, filed_date <date>, purpose <chr>, expenditure_type <chr>,
    #> #   committee_type <chr>, committee_name <chr>, candidate_name <chr>, amended <chr>

``` r
glimpse(sample_frac(ar))
```

    #> Observations: 25,580
    #> Variables: 21
    #> $ org_id             <chr> "223358", "228858", "242282", "230985", "230073", "242222", "222522",…
    #> $ expenditure_amount <dbl> 12.50, 3.00, 1848.80, 12.00, 106.92, 5000.00, 5.45, 350.00, 75.00, 22…
    #> $ expenditure_date   <date> 2017-11-30, 2018-08-31, 2018-06-30, 2018-08-22, 2019-02-08, 2019-02-…
    #> $ last_name          <chr> NA, "Collins", "Ellington", NA, NA, "67 Florida", NA, "JCD Consulting…
    #> $ first_name         <chr> NA, "Charlie", "Scott", NA, NA, NA, NA, NA, NA, NA, "Tim", NA, NA, NA…
    #> $ middle_name        <chr> NA, "S", "Anthony", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
    #> $ suffix             <chr> NA, NA, "Esq.", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
    #> $ address1           <chr> NA, "3225 East Piper Glen", "3203 Village Cove", NA, NA, "1103 Hays S…
    #> $ address2           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
    #> $ city               <chr> NA, "Fayetteville", "Jonesboro", NA, NA, "Tallahassee", NA, "Beebe", …
    #> $ state              <chr> NA, "AR", "AR", NA, NA, "FL", NA, "AR", "AR", NA, "AR", "AR", "DC", N…
    #> $ zip                <chr> NA, "72703", "72404", NA, NA, "32301", NA, "72012", "71852", NA, "722…
    #> $ explanation        <chr> NA, NA, "Repayment", NA, "Print HSVRW Membership Directories", "Contr…
    #> $ expenditure_id     <chr> "70352", "796447", "495134", "787625", "1496994", "1604279", "117459"…
    #> $ filed_date         <date> 2018-01-15, 2018-09-17, 2018-07-02, 2018-09-13, 2019-04-02, 2019-04-…
    #> $ purpose            <chr> "Other (list)", NA, NA, "Other (list)", NA, NA, "Office Supplies", "F…
    #> $ expenditure_type   <chr> "Expenditures", "Loan Payment", "Loan Payment", "Expenditures", "Expe…
    #> $ committee_type     <chr> "Candidate (CC&E)", "Candidate (CC&E)", "Candidate (CC&E)", "Candidat…
    #> $ committee_name     <chr> "Andrea Woods Campaign Committee", "Wayne G Story", "Scott Anthony El…
    #> $ candidate_name     <chr> "Woods, Andrea", "Collins, Charles S", "Ellington, Scott Anthony", "W…
    #> $ amended            <chr> "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N",…
