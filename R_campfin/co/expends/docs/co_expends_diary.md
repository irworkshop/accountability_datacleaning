Colorado Expenditures
================
Kiernan Nicholls
2019-07-23 17:27:57

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
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
  janitor, # dataframe clean
  batman, # parse NA and LGL
  scales, # text formatting
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

write_csv(
  x = co,
  path = glue("{proc_dir}/co_expends.csv"),
  na = ""
)
```

## Explore

``` r
head(co)
```

    #> # A tibble: 6 x 26
    #>   co_id expenditure_amo… expenditure_date last_name first_name mi    suffix address_1 address_2
    #>   <chr>            <dbl> <date>           <chr>     <chr>      <chr> <chr>  <chr>     <chr>    
    #> 1 2000…            500   2003-01-01       COMMITTE… <NA>       <NA>  <NA>   2181 S. … <NA>     
    #> 2 2000…            500   2003-01-01       COMMITTE… <NA>       <NA>  <NA>   2015 E. … <NA>     
    #> 3 2000…           1000   2003-01-01       COMMITTE… <NA>       <NA>  <NA>   P.O. BOX… <NA>     
    #> 4 1999…            605   2003-01-01       JDS PROF… <NA>       <NA>  <NA>   5655 S Y… <NA>     
    #> 5 2001…            322.  2003-01-01       AMERICAN… <NA>       <NA>  <NA>   PO BOX 0… <NA>     
    #> 6 2002…             48.8 2003-01-01       CRICKET   <NA>       <NA>  <NA>   P.O. BOX… <NA>     
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

    #> Observations: 601,732
    #> Variables: 26
    #> $ co_id              <chr> "20095622264", "20095608268", "20165030251", "20125025190", "20085600…
    #> $ expenditure_amount <dbl> 33.00, 23.76, 150.44, 496.13, 32.00, 4.95, 50000.00, 203.00, 294.55, …
    #> $ expenditure_date   <date> 2016-04-30, 2011-09-08, 2016-12-17, 2016-10-24, 2008-01-12, 2015-09-…
    #> $ last_name          <chr> "CO DEPARTMENT OF REVENUE", "USPS", "OFFICE DEPOT", "PAGOSA SUN", "CL…
    #> $ first_name         <chr> NA, NA, NA, NA, NA, NA, NA, NA, "SANFORD", NA, NA, NA, NA, NA, NA, NA…
    #> $ mi                 <chr> NA, NA, NA, NA, NA, NA, NA, NA, "E", NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ suffix             <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
    #> $ address_1          <chr> "1375 SHERMAN ST", "1719 SHERIDAN BLVD", "8051 S BROADWAY", "PO BOX 9…
    #> $ address_2          <chr> NA, NA, NA, NA, NA, NA, "SUITE 400", NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ city               <chr> "DENVER", "EDGEWATER", "LITTLETON", "PAGOSA SPRINGS", "FORT COLLINS",…
    #> $ state              <chr> "CO", "CO", "CO", "CO", "CO", "CA", "VA", "CO", "CO", "CO", "CO", "CO…
    #> $ zip                <chr> "80261", "80214", "80122", "81147", "80524", "95131", "22209", "80103…
    #> $ explanation        <chr> NA, NA, "SUPPLIES, PRINTER INK, PRINTER", NA, "CAMP. PHOTO", NA, "611…
    #> $ record_id          <chr> "1003614", "739419", "1050886", "1042968", "544014", "965672", "93933…
    #> $ filed_date         <date> 2016-06-08, 2011-10-14, 2017-04-15, 2016-11-04, 2008-07-22, 2015-10-…
    #> $ expenditure_type   <chr> "EMPLOYEE SERVICES", "ADVERTISING", "OFFICE EQUIPMENT & SUPPLIES", "A…
    #> $ payment_type       <chr> "CREDIT/DEBIT CARD", "CREDIT/DEBIT CARD", "CREDIT/DEBIT CARD", "CHECK…
    #> $ disbursement_type  <chr> "MONETARY (ITEMIZED)", "MONETARY (ITEMIZED)", "MONETARY (ITEMIZED)", …
    #> $ electioneering     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
    #> $ committee_type     <chr> "POLITICAL PARTY COMMITTEE", "CANDIDATE COMMITTEE", "CANDIDATE COMMIT…
    #> $ committee_name     <chr> "DENVER DEMOCRATIC CENTRAL COMMITTEE", "FRIENDS OF MAX TYLER", "ELECT…
    #> $ candidate_name     <chr> NA, "MAX TYLER", "SUSAN BECKMAN", "STEVEN WADLEY", "TOM DONNELLY", "M…
    #> $ amended            <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
    #> $ amendment          <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
    #> $ amended_record_id  <chr> "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",…
    #> $ jurisdiction       <chr> "DENVER", "STATEWIDE", "STATEWIDE", "ARCHULETA", "LARIMER", "DENVER",…

### Distinct

The variables range in their degree of distinctness.

``` r
glimpse_fun(co, n_distinct)
```

    #> # A tibble: 26 x 4
    #>    var                type       n          p
    #>    <chr>              <chr>  <int>      <dbl>
    #>  1 co_id              chr     9079 0.0151    
    #>  2 expenditure_amount dbl    88374 0.147     
    #>  3 expenditure_date   date    6232 0.0104    
    #>  4 last_name          chr    86950 0.144     
    #>  5 first_name         chr     3444 0.00572   
    #>  6 mi                 chr       31 0.0000515 
    #>  7 suffix             chr      119 0.000198  
    #>  8 address_1          chr   115278 0.192     
    #>  9 address_2          chr     3266 0.00543   
    #> 10 city               chr     4890 0.00813   
    #> 11 state              chr      123 0.000204  
    #> 12 zip                chr     7606 0.0126    
    #> 13 explanation        chr   127016 0.211     
    #> 14 record_id          chr   601731 1.000     
    #> 15 filed_date         date    4240 0.00705   
    #> 16 expenditure_type   chr       18 0.0000299 
    #> 17 payment_type       chr        7 0.0000116 
    #> 18 disbursement_type  chr        7 0.0000116 
    #> 19 electioneering     chr        2 0.00000332
    #> 20 committee_type     chr       10 0.0000166 
    #> 21 committee_name     chr     8858 0.0147    
    #> 22 candidate_name     chr     3629 0.00603   
    #> 23 amended            lgl        2 0.00000332
    #> 24 amendment          lgl        2 0.00000332
    #> 25 amended_record_id  chr    11287 0.0188    
    #> 26 jurisdiction       chr       66 0.000110

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
    #>    var                type       n       p
    #>    <chr>              <chr>  <int>   <dbl>
    #>  1 co_id              chr        0 0      
    #>  2 expenditure_amount dbl        0 0      
    #>  3 expenditure_date   date       0 0      
    #>  4 last_name          chr    19078 0.0317 
    #>  5 first_name         chr   545600 0.907  
    #>  6 mi                 chr   592166 0.984  
    #>  7 suffix             chr   600848 0.999  
    #>  8 address_1          chr    25253 0.0420 
    #>  9 address_2          chr   569562 0.947  
    #> 10 city               chr    23082 0.0384 
    #> 11 state              chr    19731 0.0328 
    #> 12 zip                chr    26436 0.0439 
    #> 13 explanation        chr   173749 0.289  
    #> 14 record_id          chr        0 0      
    #> 15 filed_date         date       0 0      
    #> 16 expenditure_type   chr   157003 0.261  
    #> 17 payment_type       chr   157068 0.261  
    #> 18 disbursement_type  chr     4994 0.00830
    #> 19 electioneering     chr   573212 0.953  
    #> 20 committee_type     chr        0 0      
    #> 21 committee_name     chr        0 0      
    #> 22 candidate_name     chr   275632 0.458  
    #> 23 amended            lgl        0 0      
    #> 24 amendment          lgl        0 0      
    #> 25 amended_record_id  chr        0 0      
    #> 26 jurisdiction       chr        0 0

It’s important to note that there are zero missing values in important
rows like `co_id`, `expenditure_amount`, or `expenditure_date`.

There are 3.17% of records missing a `last_name` value used to identify
every individual or entity. If the record has no name whatsoever, we
will flag it with a new `na_flag` variable.

``` r
co <- co %>% 
  mutate(
    na_flag = is.na(last_name) & is.na(first_name) & is.na(mi)
  )
```

### Ranges

For continuous variables, we should check the ranges.

#### Amount

``` r
summary(co$expenditure_amount)
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#> -3566408       24      100     1562      400  6916000
sum(co$expenditure_amount < 0)
#> [1] 11796
```

From this summary, we can see the median of $100 and mean of $1,561.93
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
#> [1] "3004-07-25"

sum(co$expenditure_date > today())
#> [1] 31
sum(co$expenditure_date < "2002-01-01")
#> [1] 40
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

    #> # A tibble: 37 x 2
    #>    expenditure_year     n
    #>               <dbl> <int>
    #>  1             1900     1
    #>  2             1930     1
    #>  3             1980     1
    #>  4             1993     4
    #>  5             1994     1
    #>  6             1995     1
    #>  7             1999     1
    #>  8             2000    17
    #>  9             2001    13
    #> 10             2002  1407
    #> 11             2003  6983
    #> 12             2004 22976
    #> 13             2005 11046
    #> 14             2006 44432
    #> 15             2007 14074
    #> 16             2008 43570
    #> 17             2009 18423
    #> 18             2010 58067
    #> 19             2011 20163
    #> 20             2012 55596
    #> 21             2013 30604
    #> 22             2014 58971
    #> 23             2015 26095
    #> 24             2016 57484
    #> 25             2017 34124
    #> 26             2018 86207
    #> 27             2019 11439
    #> 28             2020    17
    #> 29             2022     1
    #> 30             2026     3
    #> 31             2028     1
    #> 32             2055     1
    #> 33             2066     1
    #> 34             2203     1
    #> 35             2205     1
    #> 36             2206     4
    #> 37             3004     1

We can flag these broken dates with a new `date_flag` variable.

``` r
co <- co %>% mutate(date_flag = !between(expenditure_date, as_date("2002-01-01"), today()))
sum(co$date_flag)
#> [1] 71
```

We can also explore the intersection of `expenditure_date` and
`expenditure_anount`.

![](../plots/amount_month_line-1.png)<!-- -->

![](../plots/amount_type_bar-1.png)<!-- -->

## Wrangle

### Address

``` r
co <- co %>% 
  mutate(
    address_clean = 
      paste(address_1, address_2) %>% 
      normal_address(
        add_abbs = usps,
        na_rep = TRUE
      )
  )
```

### ZIP

``` r
mean(co$zip %in% geo$zip)
#> [1] 0.9736993

co <- co %>% 
  mutate(
    zip_clean = normal_zip(
      zip = zip,
      na_rep = TRUE,
    )
  )

# percent changed
mean(co$zip != co$zip_clean, na.rm = TRUE)
#> [1] 0.02088861
# percent valid
mean(co$zip_clean %in% geo$zip)
#> [1] 0.9951673
```

### State

The `state` values appear to already be trimmed, or are otherwise
nonsense. We can make them `NA`.

``` r
n_distinct(co$state)
#> [1] 123
mean(co$state %in% geo$state)
#> [1] 0.9657572
setdiff(co$state, geo$state)
#>  [1] NA   "MY" "LU" "SO" "DI" "C0" "UN" "UK" "N/" "HA" "D." "CP" "BE" "IO" "KE" "NO" "TE" "LO" "EU"
#> [20] "KA" "XX" "IR" "GE" "BR" "R." "DU" "BO" "AU" "PU" "OT" "CH" "00" "WE" "GB" "2"  "CC" "C)" "ST"
#> [39] "FR" "IS" "WS" "SU" "EN" "TH" "SP" "EL" "QU" "LI" "OM" "HU" "L-" "C"  "QL" "`C" "H2" "EA" "UI"
#> [58] "SW" "0"  "CS" "M"
co$state[which(co$state %out% geo$state)] <- NA
```

### City
