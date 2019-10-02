Colorado Expenditures
================
Kiernan Nicholls
2019-09-30 12:23:53

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
  - [Conclude](#conclude)
  - [Lookup](#lookup)

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
  tidyverse, # data manipulation
  snakecase, # change string case
  lubridate, # datetime strings
  tidytext, # text analysis
  magrittr, # pipe opperators
  pdftools, # extract pdf text
  janitor, # dataframe clean
  batman, # parse NA and LGL
  scales, # text formatting
  refinr, # cluster and merge
  vroom, # quick file read
  knitr, # knit documents
  glue, # combine strings
  here, # relative storage
  fs # search storage 
)
```

The IRW’s `campfin` package will also have to be installed from GitHub.
This package contains functions custom made to help facilitate the
processing of campaign finance data.

``` r
pacman::p_load_gh("kiernann/campfin")
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
#> [1] "/home/kiernan/R/accountability_datacleaning/R_campfin"
```

## Data

Colorado campaign expenditures data comes courtesy of Colorado Campaign
Finance Disclosure Website, which is managed by the TRACER reporting
system (**Tra**nsparency in **C**ontribution and **E**xpenditure
**R**eporting). Files can be found on the [Data
Download](http://tracer.sos.colorado.gov/PublicSite/DataDownload.aspx "source")
page.

### Access

> You can access the Campaign Finance Data Download page to download
> contribution and expenditure data for import into other applications
> such as Microsoft Excel or Access. A weekly batch process is run that
> captures the year-to-date information for the current year. The data
> is available for each calendar year. The file is downloaded in CSV
> format.

> This page provides comma separated value (CSV) downloads of
> contribution/donation, expenditure, and loan data for each reporting
> year in a zipped file format. These files can be downloaded and
> imported into other applications (Microsoft Excel, Microsoft Access,
> etc.). This data is extracted from the Department of State database as
> it existed as of 7/20/2019 3:01 AM

### Quality

In the [TRACER FAQ
file](http://tracer.sos.colorado.gov/PublicSite/FAQ.aspx), the Secretary
of State explains:

> The information presented in the campaign finance database is, to the
> best of the ability of the Secretary of State, an accurate
> representation of the disclosure reports filed with the applicable
> office.It is suggested that the information found from reports
> data-entered by the Secretary of State or County Clerks (which
> includes reports filed prior to 2010) be cross-checked with the
> original document or scanned image of the original document.
> 
> Beginning in 2010, all candidates, committees, and political parties
> who file disclosure reports with the Secretary of State must do so
> electronically using the TRACER system. Therefore, all data contained
> in the database dated January 2010 onward reflects that data as
> entered by the reporting person or entity.
> 
> Prior to 2010, filers had the option of filing manual disclosure
> reports. Therefore, some of the information in the campaign finance
> database dated prior to 2010was submitted in electronic form by the
> candidate, committee or party, and some of the information was
> data-entered from paper reports filed with the appropriate office.
> Sometimes items which are not consistent with filing requirements,
> such as missing names and addresses or contributions that exceed the
> allowable limits, are displayed when data is viewed online. Incorrect
> entries in the database typically reflect incorrect or incomplete
> entries on manually filed reports submitted to the Secretary of State
> or County Clerk. If you believe that there is a discrepancy in data
> dated prior to January 2010, please contact the appropriate filing
> officer for that data—the Secretary of State for statewide candidates,
> committees, and parties; or the County Clerk for county candidates and
> committees.

### Variables

TRACER also provides a [spreadsheet
key](http://tracer.sos.colorado.gov/PublicSite/Resources/DownloadDataFileKey.pdf).

## Import

To wrangle the expenditures files in R, we will download the data
locally and read everything into a single tabular data frame.

### Download

To download the **immutable** raw data files, we first have to create
the URLs. Files are split annually, with only the 4-digit year differing
in each the URL.

``` r
co_exp_urls <- glue(
  "http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/{2000:2019}_ExpenditureData.csv.zip"
)
```

  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2000_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2001_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2002_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2003_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2004_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2005_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2006_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2007_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2008_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2009_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2010_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2011_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2012_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2013_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2014_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2015_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2016_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2017_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2018_ExpenditureData.csv.zip>
  - <http://tracer.sos.colorado.gov/PublicSite/Docs/BulkDataDownloads/2019_ExpenditureData.csv.zip>

If the files have not yet been downloaded to the Colorado `/data/raw`
directory, we can do so now.

``` r
raw_dir <- here("co", "expends", "data", "raw")
dir_create(raw_dir)
if (!all_files_new(raw_dir)) {
  for (url in co_exp_urls) {
    download.file(
      url = url,
      destfile = glue("{raw_dir}/{basename(url)}")
    )
  }
}
```

### Read

Reading these files into a single data frame is not easy. First, we will
unzip each file.

``` r
zip_files <- dir_ls(raw_dir, glob = "*.zip")
if (!all_files_new(path = raw_dir, glob = "*.csv")) {
  for (i in seq_along(zip_files)) {
    unzip(
      zipfile = zip_files[i],
      exdir = raw_dir
    )
  }
}
```

Then we have to read the lines of each file (without separating the
columns). We need to extract a header from one file, remove the headers
from the rest, and filter out any row with an unexpected number of
delimiters.

``` r
# read as unlisted lines
co_lines <- dir_ls(raw_dir, glob = "*ExpenditureData.csv") %>% map(read_lines) %>% unlist()
# extract header line
col_names <- co_lines[1]
# remove other headers
co_lines <- co_lines[-str_which(co_lines, col_names)]
# count expected delims
n_delim <- str_count(co_lines[1], "\",")
# convert header line
col_names <- to_snake_case(unlist(str_split(col_names, ",")))
# remove if unexpected num of delims
co_lines <- co_lines[-which(str_count(co_lines, "\",") != n_delim)]
```

Then, we replace all comma delimiters with a `\v` (vertical tab) to use
as the delimiter.

``` r
co <- co_lines %>% 
  str_replace_all("\",", "\"\v") %>% 
  str_remove_all("\"") %>% 
  str_c(collapse = "\n") %>% 
  read_delim(
    delim = "\v",
    col_names = col_names,
    col_types = cols(
      .default = col_character(),
      expenditure_amount = col_double(),
      expenditure_date = col_date("%Y-%m-%d %H:%M:%S"),
      filed_date = col_date("%Y-%m-%d %H:%M:%S")
    )
  )

rm(col_names)
```

Then we should parse some quasi-logical values.

``` r
co <- co %>% 
  mutate_if(is_character, str_to_upper) %>% 
  mutate_if(is_character, na_if, "UNKNOWN") %>%
  remove_empty("cols") %>%
  remove_empty("rows") %>% 
  mutate(
    amended = to_logical(amended),
    amendment = to_logical(amendment),
  )
```

And finally save the formatted single data frame to disc.

``` r
proc_dir <- here("co", "expends", "data", "processed")
dir_create(proc_dir)

if (!all_files_new(proc_dir)) {
  write_csv(
    x = co,
    path = glue("{proc_dir}/co_expends.csv"),
    na = ""
  )
}
```

## Explore

``` r
head(co)
```

    #> # A tibble: 6 x 26
    #>   co_id expenditure_amo… expenditure_date last_name first_name mi    suffix address_1 address_2
    #>   <chr>            <dbl> <date>           <chr>     <chr>      <chr> <chr>  <chr>     <chr>    
    #> 1 1999…           100    2000-01-01       LACY ELS… <NA>       <NA>  <NA>   11637 E … <NA>     
    #> 2 2001…           100    1998-01-05       OWENS, B… <NA>       <NA>  <NA>   PO BOX 4… <NA>     
    #> 3 2000…            24    2000-01-11       PIZZA HUT <NA>       <NA>  <NA>   1355 SAN… <NA>     
    #> 4 1999…            20    2000-01-12       AURORA R… <NA>       <NA>  <NA>   UNKNOWNS… <NA>     
    #> 5 2000…             3.96 2000-01-13       OFFICEMAX <NA>       <NA>  <NA>   343 S BR… <NA>     
    #> 6 2000…            22.0  2000-01-13       HARLAND … <NA>       <NA>  <NA>   PO BOX 8… <NA>     
    #> # … with 17 more variables: city <chr>, state <chr>, zip <chr>, explanation <chr>,
    #> #   record_id <chr>, filed_date <date>, expenditure_type <chr>, payment_type <chr>,
    #> #   disbursement_type <chr>, electioneering <chr>, committee_type <chr>, committee_name <chr>,
    #> #   candidate_name <chr>, amended <lgl>, amendment <lgl>, amended_record_id <chr>,
    #> #   jurisdiction <chr>

``` r
tail(co)
```

    #> # A tibble: 6 x 26
    #>   co_id expenditure_amo… expenditure_date last_name first_name mi    suffix address_1 address_2
    #>   <chr>            <dbl> <date>           <chr>     <chr>      <chr> <chr>  <chr>     <chr>    
    #> 1 2013…             50   2018-12-31       THE ROCK… <NA>       <NA>  <NA>   675 PONC… <NA>     
    #> 2 2018…             14.5 2018-12-31       <NA>      <NA>       <NA>  <NA>   <NA>      <NA>     
    #> 3 2017…             75   2018-12-31       CHRISTEN… REBECCA    <NA>  <NA>   1850 BAS… <NA>     
    #> 4 2017…              4   2018-12-31       FIRST BA… <NA>       <NA>  <NA>   PO BOX 1… <NA>     
    #> 5 2016…              6   2018-12-31       FIRST BA… <NA>       <NA>  <NA>   3190 YOU… <NA>     
    #> 6 2017…             12   2018-12-31       FIRSTBAN… <NA>       <NA>  <NA>   PO BOX 7… <NA>     
    #> # … with 17 more variables: city <chr>, state <chr>, zip <chr>, explanation <chr>,
    #> #   record_id <chr>, filed_date <date>, expenditure_type <chr>, payment_type <chr>,
    #> #   disbursement_type <chr>, electioneering <chr>, committee_type <chr>, committee_name <chr>,
    #> #   candidate_name <chr>, amended <lgl>, amendment <lgl>, amended_record_id <chr>,
    #> #   jurisdiction <chr>

``` r
glimpse(sample_frac(co))
```

    #> Observations: 649,679
    #> Variables: 26
    #> $ co_id              <chr> "20165031331", "20105017993", "20115022040", "20175033164", "20065644…
    #> $ expenditure_amount <dbl> 460.15, 270.00, 4.59, 800.00, 20.00, 25.00, 1045.00, 64.40, 135.00, 2…
    #> $ expenditure_date   <date> 2016-11-24, 2010-08-26, 2016-09-06, 2018-06-25, 2010-10-28, 2006-12-…
    #> $ last_name          <chr> "HERTZ RENTAL CAR", "COLORADO CHINESE NEWS", "KING SOOPERS", "VISUAL …
    #> $ first_name         <chr> NA, NA, NA, NA, NA, NA, NA, NA, "GLENN", NA, NA, NA, NA, NA, NA, NA, …
    #> $ mi                 <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
    #> $ suffix             <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
    #> $ address_1          <chr> "2001 WELTON ST", "1548 WEST ALAMEDA AVENUE, #A", "2712 S 11TH AVE.",…
    #> $ address_2          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
    #> $ city               <chr> "DENVER", "DENVER", "GREELEY", "LOVELAND", "SAGUACHE", "PARKER", "DEN…
    #> $ state              <chr> "CO", "CO", "CO", "CO", "CO", "CO", "CO", "CO", "CO", "CO", "CO", "ON…
    #> $ zip                <chr> "80205", "80223", "80631", "80537", "81149", "80134", "80231", "81101…
    #> $ explanation        <chr> "TRAVEL AND LODGING", NA, NA, NA, "ADVERTISING", "CREDIT AUTO PAY", "…
    #> $ record_id          <chr> "1045718", "698671", "1022856", "1143789", "720880", "488636", "75667…
    #> $ filed_date         <date> 2016-12-08, 2010-09-21, 2016-09-16, 2018-07-26, 2010-11-30, 2007-04-…
    #> $ expenditure_type   <chr> "TRAVEL & LODGING", "ADVERTISING", "OFFICE EQUIPMENT & SUPPLIES", "CO…
    #> $ payment_type       <chr> "OTHER", "CHECK", "CREDIT/DEBIT CARD", "CHECK", "CHECK", NA, "CHECK",…
    #> $ disbursement_type  <chr> "MONETARY (ITEMIZED)", "MONETARY (ITEMIZED)", "MONETARY (ITEMIZED)", …
    #> $ electioneering     <chr> NA, NA, NA, NA, NA, NA, NA, "YES", NA, NA, NA, NA, NA, NA, NA, NA, NA…
    #> $ committee_type     <chr> "ISSUE COMMITTEE", "CANDIDATE COMMITTEE", "CANDIDATE COMMITTEE", "CAN…
    #> $ committee_name     <chr> "YES ON COLORADO END OF LIFE OPTIONS", "ROCK THE HOUSE - DOC MILLER F…
    #> $ candidate_name     <chr> NA, "THOMAS C. DOC MILLER", "DAVID L. YOUNG", "SCOTT KENT JAMES", NA,…
    #> $ amended            <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, …
    #> $ amendment          <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
    #> $ amended_record_id  <chr> "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",…
    #> $ jurisdiction       <chr> "STATEWIDE", "STATEWIDE", "STATEWIDE", "WELD", "SAGUACHE", "STATEWIDE…

### Distinct

The variables range in their degree of distinctness.

``` r
glimpse_fun(co, n_distinct)
```

    #> # A tibble: 26 x 4
    #>    col                type       n          p
    #>    <chr>              <chr>  <dbl>      <dbl>
    #>  1 co_id              chr     9563 0.0147    
    #>  2 expenditure_amount dbl    94094 0.145     
    #>  3 expenditure_date   date    7194 0.0111    
    #>  4 last_name          chr    98195 0.151     
    #>  5 first_name         chr     3477 0.00535   
    #>  6 mi                 chr       31 0.0000477 
    #>  7 suffix             chr      119 0.000183  
    #>  8 address_1          chr   126745 0.195     
    #>  9 address_2          chr     3286 0.00506   
    #> 10 city               chr     5436 0.00837   
    #> 11 state              chr      124 0.000191  
    #> 12 zip                chr     8207 0.0126    
    #> 13 explanation        chr   135544 0.209     
    #> 14 record_id          chr   649678 1.000     
    #> 15 filed_date         date    4779 0.00736   
    #> 16 expenditure_type   chr       18 0.0000277 
    #> 17 payment_type       chr        7 0.0000108 
    #> 18 disbursement_type  chr        7 0.0000108 
    #> 19 electioneering     chr        2 0.00000308
    #> 20 committee_type     chr       10 0.0000154 
    #> 21 committee_name     chr     9322 0.0143    
    #> 22 candidate_name     chr     3870 0.00596   
    #> 23 amended            lgl        2 0.00000308
    #> 24 amendment          lgl        2 0.00000308
    #> 25 amended_record_id  chr    11379 0.0175    
    #> 26 jurisdiction       chr       66 0.000102

We can use `ggplot::geom_col()` to explore the distribution of the least
distinct categorical variables.

![](../plots/expend_type_bar-1.png)<!-- -->

![](../plots/payment_type_bar-1.png)<!-- -->

![](../plots/disburse_type_bar-1.png)<!-- -->

![](../plots/committee_type_bar-1.png)<!-- -->

![](../plots/jurisdiction_bar-1.png)<!-- -->

![](../plots/explanation_bar-1.png)<!-- -->

### Missing

The variables also differ in their degree of missing values.

``` r
glimpse_fun(co, count_na)
```

    #> # A tibble: 26 x 4
    #>    col                type       n       p
    #>    <chr>              <chr>  <dbl>   <dbl>
    #>  1 co_id              chr        0 0      
    #>  2 expenditure_amount dbl        0 0      
    #>  3 expenditure_date   date       0 0      
    #>  4 last_name          chr    19189 0.0295 
    #>  5 first_name         chr   592809 0.912  
    #>  6 mi                 chr   640091 0.985  
    #>  7 suffix             chr   648789 0.999  
    #>  8 address_1          chr    27314 0.0420 
    #>  9 address_2          chr   617320 0.950  
    #> 10 city               chr    23975 0.0369 
    #> 11 state              chr    19841 0.0305 
    #> 12 zip                chr    26833 0.0413 
    #> 13 explanation        chr   174847 0.269  
    #> 14 record_id          chr        0 0      
    #> 15 filed_date         date       0 0      
    #> 16 expenditure_type   chr   202257 0.311  
    #> 17 payment_type       chr   202322 0.311  
    #> 18 disbursement_type  chr     4998 0.00769
    #> 19 electioneering     chr   621025 0.956  
    #> 20 committee_type     chr        0 0      
    #> 21 committee_name     chr        0 0      
    #> 22 candidate_name     chr   298609 0.460  
    #> 23 amended            lgl        0 0      
    #> 24 amendment          lgl        0 0      
    #> 25 amended_record_id  chr        0 0      
    #> 26 jurisdiction       chr        0 0

It’s important to note that there are zero missing values in important
rows like `co_id`, `expenditure_amount`, or `expenditure_date`.

There are 2.95% of records missing a `last_name` value used to identify
every individual or entity. If the record has no name whatsoever, we
will flag it with a new `na_flag` variable.

``` r
co <- co %>% 
  mutate(payee = coalesce(first_name, mi, last_name)) %>% 
  flag_na(expenditure_amount, expenditure_date, payee, committee_name) %>% 
  select(-payee)

sum(co$na_flag)
```

    #> [1] 19043

``` r
mean(co$na_flag)
```

    #> [1] 0.0293114

### Ranges

For continuous variables, we should check the ranges.

#### Amount

``` r
summary(co$expenditure_amount)
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#> -3566408       25      100     1578      400  6916000
sum(co$expenditure_amount < 0)
#> [1] 11959
mean(co$expenditure_amount < 0)
#> [1] 0.01840755
```

From this summary, we can see the median of $100 and mean of $1,577.83
are reasonable, but the minimum and maximum should be explored.

``` r
glimpse(filter(co, expenditure_amount == min(expenditure_amount)))
```

    #> Observations: 1
    #> Variables: 27
    #> $ co_id              <chr> "20145026709"
    #> $ expenditure_amount <dbl> -3566408
    #> $ expenditure_date   <date> 2014-08-13
    #> $ last_name          <chr> "PACWEST"
    #> $ first_name         <chr> NA
    #> $ mi                 <chr> NA
    #> $ suffix             <chr> NA
    #> $ address_1          <chr> "8600 SW ST HELENS DR., SUITE 100"
    #> $ address_2          <chr> NA
    #> $ city               <chr> "WILSONVILLE"
    #> $ state              <chr> "OR"
    #> $ zip                <chr> "97070"
    #> $ explanation        <chr> "CAMPAIGN STRATEGY & MANAGEMENT, PROFESSIONAL FEES FOR PRECISION, VOT…
    #> $ record_id          <chr> "932714"
    #> $ filed_date         <date> 2014-10-14
    #> $ expenditure_type   <chr> "CONSULTANT & PROFESSIONAL SERVICES"
    #> $ payment_type       <chr> "MONEY ORDER"
    #> $ disbursement_type  <chr> "MONETARY (ITEMIZED)"
    #> $ electioneering     <chr> NA
    #> $ committee_type     <chr> "ISSUE COMMITTEE"
    #> $ committee_name     <chr> "PROTECTING COLORADO�S ENVIRONMENT, ECONOMY, AND ENERGY INDEPENDENCE"
    #> $ candidate_name     <chr> NA
    #> $ amended            <lgl> TRUE
    #> $ amendment          <lgl> TRUE
    #> $ amended_record_id  <chr> "912031"
    #> $ jurisdiction       <chr> "STATEWIDE"
    #> $ na_flag            <lgl> FALSE

> CAMPAIGN STRATEGY & MANAGEMENT, PROFESSIONAL FEES FOR PRECISION, VOTER
> FILE MAINTENANCE, WEBSITE, RESEARCH & TRACKING, MARKETING, DIGITAL AND
> TV/RADIO

``` r
glimpse(filter(co, expenditure_amount == max(expenditure_amount)))
```

    #> Observations: 1
    #> Variables: 27
    #> $ co_id              <chr> "20145027021"
    #> $ expenditure_amount <dbl> 6916000
    #> $ expenditure_date   <date> 2014-05-30
    #> $ last_name          <chr> "COLORADO MEDIA & MAIL"
    #> $ first_name         <chr> NA
    #> $ mi                 <chr> NA
    #> $ suffix             <chr> NA
    #> $ address_1          <chr> "P.O. BOX 18459"
    #> $ address_2          <chr> NA
    #> $ city               <chr> "DENVER"
    #> $ state              <chr> "CO"
    #> $ zip                <chr> "80218"
    #> $ explanation        <chr> NA
    #> $ record_id          <chr> "898464"
    #> $ filed_date         <date> 2014-06-16
    #> $ expenditure_type   <chr> "ADVERTISING"
    #> $ payment_type       <chr> "CHECK"
    #> $ disbursement_type  <chr> "MONETARY (ITEMIZED)"
    #> $ electioneering     <chr> NA
    #> $ committee_type     <chr> "ISSUE COMMITTEE"
    #> $ committee_name     <chr> "DON'T TURN RACETRACKS INTO CASINOS"
    #> $ candidate_name     <chr> NA
    #> $ amended            <lgl> FALSE
    #> $ amendment          <lgl> FALSE
    #> $ amended_record_id  <chr> "0"
    #> $ jurisdiction       <chr> "STATEWIDE"
    #> $ na_flag            <lgl> FALSE

We can use `ggplot2:geom_histogram()` and `ggplot2:geom_boxplot()` to
explore the distribution of the amount.

``` r
co %>% 
  ggplot(aes(x = expenditure_amount)) +
  geom_histogram() +
  scale_x_continuous(
    trans = "log10",
    labels = dollar
  )
```

![](../plots/amount_hist_log-1.png)<!-- -->

``` r
co %>% 
  ggplot(aes(y = expenditure_amount)) +
  geom_boxplot(aes(x = payment_type), outlier.alpha = 0.01) +
  scale_y_continuous(
    trans = "log10",
    labels = dollar,
    breaks = c(0, 1, 10, 100, 1000, 1000000)
  ) +
  coord_flip() +
  labs(
    title = "CO Expends Amount",
    subtitle = "by Payment Type",
    x = "Payment Type",
    y = "Amount (log)"
  )
```

![](../plots/amount_box_pay-1.png)<!-- -->

![](../plots/amount_box_type-1.png)<!-- -->

### Dates

From the minimum and maximum expenditure dates, we can see that
something is wrong.

``` r
min(co$expenditure_date)
#> [1] "1900-01-31"
max(co$expenditure_date)
#> [1] "5200-10-10"

sum(co$expenditure_date > today())
#> [1] 38
sum(co$expenditure_date < "2002-01-01")
#> [1] 23516
```

First, we will create a new `expenditure_year` variable from the
`expenditure_date` using `lubridate::year()` (after parsing with
`readr::col_date()`).

``` r
co <- co %>% mutate(expenditure_year = year(expenditure_date))
```

Then we can see that there are a handful of expenditures supposedly made
before 2002 and after 2019.

``` r
co %>% 
  count(expenditure_year) %>% 
  print(n = n_distinct(co$expenditure_year))
```

    #> # A tibble: 44 x 2
    #>    expenditure_year     n
    #>               <dbl> <int>
    #>  1             1900     1
    #>  2             1930     1
    #>  3             1980     1
    #>  4             1993     4
    #>  5             1994     1
    #>  6             1995     1
    #>  7             1996    48
    #>  8             1997     1
    #>  9             1998     3
    #> 10             1999    30
    #> 11             2000 17204
    #> 12             2001  6221
    #> 13             2002 23131
    #> 14             2003  6993
    #> 15             2004 22976
    #> 16             2005 11054
    #> 17             2006 44457
    #> 18             2007 14074
    #> 19             2008 43571
    #> 20             2009 18423
    #> 21             2010 58069
    #> 22             2011 20163
    #> 23             2012 55597
    #> 24             2013 30605
    #> 25             2014 59022
    #> 26             2015 26097
    #> 27             2016 57488
    #> 28             2017 34125
    #> 29             2018 86256
    #> 30             2019 14024
    #> 31             2020    20
    #> 32             2022     1
    #> 33             2026     3
    #> 34             2028     1
    #> 35             2055     1
    #> 36             2066     1
    #> 37             2110     1
    #> 38             2202     1
    #> 39             2203     1
    #> 40             2205     1
    #> 41             2206     4
    #> 42             2900     1
    #> 43             3004     1
    #> 44             5200     1

We can flag these broken dates with a new `date_flag` variable.

``` r
co <- co %>% mutate(date_flag = !between(expenditure_date, as_date("2002-01-01"), today()))
sum(co$date_flag)
#> [1] 23554
```

We can also explore the intersection of `expenditure_date` and
`expenditure_anount`.

![](../plots/amount_month_line-1.png)<!-- -->

![](../plots/amount_type_bar-1.png)<!-- -->

## Wrangle

### Address

``` r
co <- co %>% 
  unite(
    address_1, address_2,
    col = address_clean,
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    address_clean = normal_address(
      address = address_clean,
      add_abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(
    everything(),
    address_clean
  )

co %>%
  sample_n(10) %>% 
  select(
    address_1, 
    address_2, 
    address_clean
  )
```

    #> # A tibble: 10 x 3
    #>    address_1                  address_2 address_clean                 
    #>    <chr>                      <chr>     <chr>                         
    #>  1 10457 VAUGHN ST.           <NA>      10457 VAUGHN STREET           
    #>  2 6500 LOOKOUT ROAD          <NA>      6500 LOOKOUT ROAD             
    #>  3 951 20TH ST                <NA>      951 20TH STREET               
    #>  4 10452 DALE CIRLCE          <NA>      10452 DALE CIRLCE             
    #>  5 PO BOX 5328                <NA>      PO BOX 5328                   
    #>  6 11831 GRAPE COURT          <NA>      11831 GRAPE COURT             
    #>  7 PO BOX 9477                <NA>      PO BOX 9477                   
    #>  8 401 W 15TH STREET  STE 520 <NA>      401 WEST 15TH STREET SUITE 520
    #>  9 6372 W. COALMINE RD        <NA>      6372 WEST COALMINE ROAD       
    #> 10 1601 TRAPELO ROAD          <NA>      1601 TRAPELO ROAD

### ZIP

``` r
mean(co$zip %in% valid_zip)
#> [1] 0.9298808

co <- co %>% 
  mutate(
    zip_clean = normal_zip(
      zip = zip,
      na_rep = TRUE,
    )
  )

# percent changed
mean(co$zip != co$zip_clean, na.rm = TRUE)
#> [1] 0.0196831
# percent valid
mean(co$zip_clean %in% valid_zip)
#> [1] 0.9471
```

### State

The `state` values appear to already be trimmed, or are otherwise
nonsense. We can make them `NA`. 99.8% of `state` values are already
valid.

``` r
n_distinct(co$state)
#> [1] 124
prop_in(co$state, valid_state, na.rm = TRUE)
#> [1] 0.9981297
setdiff(co$state, valid_state)
#>  [1] "ON" "AB" "NS" "QC" NA   "NB" "MY" "LU" "BC" "SO" "DI" "C0" "UN" "UK" "N/" "HA" "D." "CP" "BE"
#> [20] "IO" "KE" "NO" "PE" "TE" "LO" "EU" "KA" "XX" "IR" "GE" "BR" "R." "DU" "BO" "AU" "PU" "OT" "CH"
#> [39] "00" "WE" "GB" "2"  "CC" "C)" "ST" "FR" "IS" "WS" "SU" "EN" "TH" "SP" "EL" "QU" "LI" "OM" "HU"
#> [58] "L-" "C"  "QL" "`C" "H2" "EA" "UI" "SW" "0"  "CS" "HK" "M"

co <- co %>% 
  mutate(
  state_clean = normal_state(
    state = state,
    abbreviate = TRUE,
    na_rep = TRUE
  )
)

prop_in(co$state_clean, valid_state, na.rm = TRUE)
#> [1] 0.9982644
```

### City

First, we should expand our list of valid cities. The Colorado state
government provides a PDF list of Colorado’s “Incorporated Cities and
Towns.”

> Below is a list of the incorporated cities and towns in Colorado.
> Included in this list is the municipality’s county location and its
> incorporation date. The information below primarily comes from the
> Colorado Gazetteer of Cities and Towns, published by the Colorado
> State Planning Division for inclusion in the Colorado Year Book, 1958.
> For incorporations after 1958, the information comes from The
> Directory of Municipal and County Officials in Colorado 1999-2000,
> published by the Colorado Municipal League, 1999.

``` r
co_city <- pdf_text("https://www.colorado.gov/pacific/sites/default/files/List%20of%20Incorporated%20Cities%20and%20Towns%20in%20CO.pdf")
# split and trim white text
co_city <- str_trim(unlist(str_split(co_city, "\n"))[-c(1:7)])
# remove empties
co_city <- co_city[which(co_city != "")]
# remove all after two spaces
co_city <- str_remove(co_city, "\\s{2,}(.*)")
# normalize
co_city <- normal_city(co_city, geo_abbs = usps_city)
# combine with others
valid_city <- unique(c(co_city, valid_city))
```

Our aim here is to reduce the number of distinct city names by
normalizing text and correcting *obvious* mispellings.

``` r
n_distinct(co$city)
#> [1] 5436
prop_in(co$city, valid_city, na.rm = TRUE)
#> [1] 0.9530689
sum(unique(co$city) %out% valid_city)
#> [1] 3016
```

#### Normalize

``` r
co <- co %>% 
  mutate(
    city_norm = normal_city(
      city = city %>% 
        str_replace("\\bCOLO\\b", "COLORADO") %>% 
        str_replace("\\bCO\\b",   "COLORADO") %>% 
        str_replace("^COS$", "COLORADO SPRINGS") %>% 
        str_replace("^LA$", "LOS ANGELES") %>% 
        str_replace("^MPLS$", "MINNEAPOLIS") %>% 
        str_replace("^SLC$", "SALT LAKE CITY") %>% 
        str_replace("^GWS$", "GLENWOOD SPRINGS"),
      geo_abbs = usps_city,
      st_abbs = c("CO", "DC", "COLORADO"),
      na = c(invalid_city, "UNKNOWNCITY", "REDACTED", "TBD"),
      na_rep = TRUE
    )
  )

n_distinct(co$city_norm)
#> [1] 4879
prop_in(co$city_norm, valid_city, na.rm = TRUE)
#> [1] 0.974059
sum(unique(co$city_norm) %out% valid_city)
#> [1] 2432
```

#### Match

``` r
co <- co %>%
  left_join(
    zipcodes,
    by = c(
      "zip_clean" = "zip",
      "state_clean" = "state"
    )
  ) %>%
  rename(
    city = city.x,
    city_match = city.y
  ) %>%
  mutate(match_dist = stringdist(city_norm, city_match))

n_distinct(co$city_match)
#> [1] 2417
prop_in(co$city_match, valid_city, na.rm = TRUE)
#> [1] 1
summary(co$match_dist)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
#>    0.00    0.00    0.00    0.81    0.00   26.00   39856
```

#### Swap

``` r
co <- co %>% 
  mutate(
    city_swap = if_else(
      condition = match_dist <= 2 | is.na(match_dist), 
      true = city_match, 
      false = city_norm
    )
  )

# changes made
sum(co$city_swap != co$city_norm, na.rm = TRUE)
#> [1] 6772
n_distinct(co$city_swap)
#> [1] 3161
prop_in(co$city_swap, valid_city, na.rm = TRUE)
#> [1] 0.9856199
# remaining bad
sum(unique(co$city_swap) %out% valid_city)
#> [1] 778
# average dist for good and bad
mean(co$match_dist[which(co$city_swap %in%  valid_city)], na.rm = TRUE)
#> [1] 0.6885546
mean(co$match_dist[which(co$city_swap %out% valid_city)], na.rm = TRUE)
#> [1] 9.359348
```

This ZIP match swapping made 6772 changes.

``` r
co %>% 
  select(
    city,
    state_clean,
    zip_clean,
    city_norm,
    city_match,
    match_dist,
    city_swap
  ) %>% 
  filter(!is.na(city_swap)) %>% 
  filter(city_swap != city_norm) %>% 
  distinct() %>% 
  sample_frac()
```

    #> # A tibble: 1,921 x 7
    #>    city            state_clean zip_clean city_norm       city_match      match_dist city_swap      
    #>    <chr>           <chr>       <chr>     <chr>           <chr>                <dbl> <chr>          
    #>  1 HAGZMAN         NY          12086     HAGZMAN         HAGAMAN                  1 HAGAMAN        
    #>  2 CLARK LAKE      MI          49234     CLARK LAKE      CLARKLAKE                1 CLARKLAKE      
    #>  3 STEAMBOAT SPRI… CO          80487     STEAMBOAT SPRI… STEAMBOAT SPRI…          1 STEAMBOAT SPRI…
    #>  4 DEVER           CO          80223     DEVER           DENVER                   1 DENVER         
    #>  5 MANITAL SPRINGS CO          80829     MANITAL SPRINGS MANITOU SPRINGS          2 MANITOU SPRINGS
    #>  6 SLIDA           CO          81201     SLIDA           SALIDA                   1 SALIDA         
    #>  7 ESTES PARL      CO          80517     ESTES PARL      ESTES PARK               1 ESTES PARK     
    #>  8 PUBLO           CO          81001     PUBLO           PUEBLO                   1 PUEBLO         
    #>  9 CANYON CITY     CO          81215     CANYON CITY     CANON CITY               1 CANON CITY     
    #> 10 WESTCLUIFFE     CO          81252     WESTCLUIFFE     WESTCLIFFE               1 WESTCLIFFE     
    #> # … with 1,911 more rows

There are still many valid cities not captured by our list.

``` r
co %>% 
  count(state_clean, city_swap, sort = TRUE) %>% 
  filter(city_swap %out% valid_city) %>% 
  drop_na()
```

    #> # A tibble: 784 x 3
    #>    state_clean city_swap           n
    #>    <chr>       <chr>           <int>
    #>  1 CO          HIGHLANDS RANCH  3786
    #>  2 CO          PUEBLO WEST      1080
    #>  3 CO          CASTLE PINES      241
    #>  4 MA          WEST SOMERVILLE   179
    #>  5 MN          SHOREVIEW         149
    #>  6 CO          THRONTON          140
    #>  7 PA          CHESTERBROOK      135
    #>  8 CO          WESTMINISTER      132
    #>  9 CO          THORTON            99
    #> 10 CO          BLACK FOREST       79
    #> # … with 774 more rows

#### Refine

We can use the [OpenRefine cluster and merge
algorithms](https://github.com/OpenRefine/OpenRefine/wiki/Clustering-In-Depth)
to further disambiguate the city values.

``` r
co_refine <- co %>%
  # only refine CO city
  filter(state_clean == "CO") %>% 
  mutate(
    # cluster and merge
    city_refine = city_swap %>% 
      key_collision_merge(dict = unique(c(co_city, valid_city[valid_state == "CO"]))) %>% 
      n_gram_merge(numgram = 2),
    # undo refine if match
    city_refine = if_else(
      condition = match_dist <= 2,
      true = city_swap,
      false = city_refine
    )
  ) %>%
  # filter out unchanged
  filter(city_swap != city_refine)

mean(co_refine$city_norm %in% valid_city)
#> [1] 0.2212121
mean(co_refine$city_refine %in% valid_city)
#> [1] 0.8333333
```

``` r
co_refine %>% 
  count(
    state_clean,
    city_swap,
    city_refine,
    sort = TRUE
  ) %>% 
  mutate(made_valid = city_refine %in% valid_city)
```

    #> # A tibble: 77 x 5
    #>    state_clean city_swap   city_refine     n made_valid
    #>    <chr>       <chr>       <chr>       <int> <lgl>     
    #>  1 CO          WHEATRIDGE  WHEAT RIDGE    67 TRUE      
    #>  2 CO          LONETREE    LONE TREE      47 TRUE      
    #>  3 CO          NORTHGLEN   NORTHGLENN     26 TRUE      
    #>  4 CO          CENTENIAL   CENTENNIAL     23 TRUE      
    #>  5 CO          CENNTENNIAL CENTENNIAL     15 TRUE      
    #>  6 CO          CENNTENIAL  CENTENNIAL     12 TRUE      
    #>  7 CO          WEST PUEBLO PUEBLO WEST    10 FALSE     
    #>  8 CO          G J         GJ              8 FALSE     
    #>  9 CO          LAKEWOD     LAKEWOOD        8 TRUE      
    #> 10 CO          NEED        DEN             8 FALSE     
    #> # … with 67 more rows

If the new `city_refine` *and* the `state_clean` values match a valid
city in the geo table, we can fairly confident that these new city names
are valid.

``` r
co_refine <- co_refine %>% 
  select(
    city_swap,
    city_refine,
    state_clean,
    zip_clean
  ) %>% 
  inner_join(
    zipcodes,
    by = c(
      "city_refine" = "city",
      "state_clean" = "state"
    )
  ) %>% 
  select(-zip)
```

And we can join this table back to the original.

``` r
co <- co %>% 
  left_join(co_refine) %>% 
  mutate(city_clean = coalesce(city_refine, city_swap))
```

We can see this process reduces the number of distinct city values by
2296.

``` r
n_distinct(co$city)
#> [1] 5436
n_distinct(co$city_norm)
#> [1] 4879
n_distinct(co$city_swap)
#> [1] 3161
n_distinct(co$city_clean)
#> [1] 3140
```

We also increased the percent of valid city names by 3.53%, from 95.0%
to 98.6%

``` r
prop_in(co$city, valid_city, na.rm = TRUE)
#> [1] 0.9504918
prop_in(co$city_norm, valid_city, na.rm = TRUE)
#> [1] 0.9713596
prop_in(co$city_swap, valid_city, na.rm = TRUE)
#> [1] 0.9828021
prop_in(co$city_clean, valid_city, na.rm = TRUE)
#> [1] 0.9858118
```

## Conclude

1.  There are 653002 records in the database

2.  
3.  Ranges for continuous variables are reasonable.

4.  There are 19043 records with missing data, flagged with `na_flag`.

5.  Consistency issues in geographic strings has been improved with the
    `campfin` package.

6.  The 5-digit `zip_clean` variable has been created from `zip`.

7.  The 4-digit `expenditure_year` variable has been created from
    `expenditure_date`.

8.  Not all files have both parties (see `na_flag`).

## Lookup

``` r
lookup <- read_csv("co/expends/data/co_city_lookup.csv") %>% select(1:2)
co <- left_join(co, lookup)

progress_table(
  co$city, 
  co$city_swap,
  co$city_clean, 
  co$city_clean2, 
  compare = valid_city
)
```

    #> # A tibble: 4 x 6
    #>   stage       prop_in n_distinct prop_na n_out n_diff
    #>   <chr>         <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 city          0.950       5436  0.0367 31142   3016
    #> 2 city_swap     0.983       3161  0.0602 10554    778
    #> 3 city_clean    0.986       3140  0.0602  8707    760
    #> 4 city_clean2   0.988       2746  0.0605  7292    377

``` r
clean_file <- glue("{proc_dir}/co_expends_clean.csv")

if (!this_file_new(clean_file)) {
  write_csv(
    x = co,
    path = clean_file,
    na = ""
  )
}
```
