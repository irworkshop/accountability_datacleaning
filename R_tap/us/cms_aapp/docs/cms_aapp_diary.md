CMS AAP Program COVID-19 Payments
================
Kiernan Nicholls
Wed Feb 17 13:15:00 2021

-   [Project](#project)
-   [Objectives](#objectives)
-   [Packages](#packages)
-   [Data](#data)
-   [Download](#download)
-   [Read](#read)
-   [Explore](#explore)
    -   [Missing](#missing)
    -   [Duplicates](#duplicates)
    -   [Amounts](#amounts)

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

``` r
if (!require("pacman")) {
  install.packages("pacman")
}
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  tabulizer, # read pdf tables
  gluedown, # printing markdown
  janitor, # clean data frames
  campfin, # custom irw tools
  aws.s3, # aws cloud storage
  refinr, # cluster & merge
  scales, # format strings
  knitr, # knit documents
  vroom, # fast reading
  rvest, # scrape html
  glue, # code strings
  here, # project paths
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
here::i_am("us/covid/cms_aapp/docs/cms_aapp_diary.Rmd")
```

## Data

Centers for Medicare & Medicaid Services (CMS) Accelerated and Advance
Payment (AAP) Program [Fact
Sheet](https://www.cms.gov/files/document/accelerated-and-advanced-payments-fact-sheet.pdf):

> On March 28 2020, CMS expanded the existing Accelerated and Advance
> Payments Program to a broader group of Medicare Part A providers and
> Part B suppliers. An accelerated or advance payment is a payment
> intended to provide necessary funds when there is a disruption in
> claims submission and/or claims processing. CMS can also offer these
> payments in circumstances such as national emergencies, or natural
> disasters in order to accelerate cash flow to the impacted health care
> providers and suppliers.
>
> The subsequent passage of the Coronavirus Aid, Relief, and Economic
> Security (CARES) Act (P.L. 116-136) on March 27, 2020, amended the
> existing Accelerated Payments Program to provideadditional benefits
> and flexibilit ies, including extended repayment timeframes, to the
> subset ofproviders specifically referenced in the CARES Act, including
> inpatient hospitals, children’s hospitals,certain cancer hospitals,
> and critical access hospitals.
>
> The Continuing Appropriations Act, 2021 and Other Extensions Act (P.L.
> 116-159), enacted on October 1, 2020,amended the repayment terms for
> allproviders and suppliers who requested and received accelerated and
> advance payment(s) during the COVID-19 Public Health Emergency (PHE).
> Details on repayment terms are provided below.
>
> Although we announced the pause of the Accelerated Payments Program
> and the suspension of the Advance Payments Program on April 26, 2020,
> CMS continued to accept applications from providers as they related to
> the COVID-19 public health emergency (PHE). Please note that, as of
> October 8, 2020, CMS will no longer accept applications for
> accelerated or advance payments as they relate to the COVID-19 PHE,
> although CMS will continue to monitor the ongoing impacts of COVID-19
> on the Medicare provider and supplier community.

## Download

The PDF containing the AAP Program payments can be downloaded from the
CMS.

``` r
raw_url <- "https://www.cms.gov/files/document/covid-medicare-accelerated-and-advance-payments-program-covid-19-public-health-emergency-payment.pdf"
raw_dir <- dir_create(here("us", "covid", "cms_aapp", "data", "raw"))
raw_path <- path(raw_dir, basename(raw_url))
```

``` r
if (!file_exists(raw_path)) {
  download.file(raw_url, raw_path)
}
```

## Read

The tables from that PDF are extracted using the free
[Tabula](https://tabula.technology/) tool.

``` r
raw_zip <- path(raw_dir, "tabula-extract.zip")
raw_csv <- unzip(raw_zip, exdir = raw_dir)
```

The extracted CSV files can be read into a single data frame.

``` r
aapp <- map_df(
  .x = raw_csv,
  .f = read_csv,
  col_types = "ccn",
  col_names = c(
    "National Provider Identifier",
    "Provider/Supplier Name",
    "Payment Amount "
  )
)
```

``` r
aapp[nrow(aapp), ]
#> # A tibble: 1 x 3
#>   `National Provider Identifier` `Provider/Supplier Name` `Payment Amount `
#>   <chr>                          <chr>                                <dbl>
#> 1 <NA>                           Total                         107291936099
aapp <- aapp[-nrow(aapp), ]
names(aapp) <- c("npi", "name", "amount")
```

``` r
aapp$name <- str_replace_all(aapp$name, "\r", " ")
```

## Explore

There are 47,878 rows of 3 columns. Each record represents a single
payment made to a provider/supplier under the AAP program.

``` r
glimpse(aapp)
#> Rows: 47,878
#> Columns: 3
#> $ npi    <chr> "1063688844", "1083870406", "1932365350", "1962743146", "1093101743", "1699956110", "1053592576", "103…
#> $ name   <chr> "021808 LLC", "022808 KENWOOD LLC", "022808 LLC", "1 & 1 HOME HEALTH, INC.", "1 BETHESDA DRIVE OPERATI…
#> $ amount <dbl> 661018, 422151, 466512, 164550, 420549, 104803, 590296, 690618, 390713, 494642, 252680, 178868, 376292…
tail(aapp)
#> # A tibble: 6 x 3
#>   npi        name                                   amount
#>   <chr>      <chr>                                   <dbl>
#> 1 1770993446 ZUBAIR FAROOQUI MD LLC                  41101
#> 2 1093882680 ZUMO LAWRENCE                           25000
#> 3 1952328866 ZUNIGA GOLDWATER ADONIS                 13382
#> 4 1477523413 ZWANGER & PESIRI RADIOLOGY GROUP, LLP 9679471
#> 5 1578987368 ZWEMER SURGICAL PLC                      4333
#> 6 1912375148 ZYWIE INC                               98979
```

### Missing

No records are missing any values.

``` r
col_stats(aapp, count_na)
#> # A tibble: 3 x 4
#>   col    class     n     p
#>   <chr>  <chr> <int> <dbl>
#> 1 npi    <chr>     0     0
#> 2 name   <chr>     0     0
#> 3 amount <dbl>     0     0
```

### Duplicates

There are no entirely duplicate rows, but there are a few duplicate IDs.
These are multiple payments to the same provider/supplier. Without a
date value, it’s not clear what’s the cause.

``` r
aapp <- aapp %>% 
  group_by(npi) %>% 
  mutate(dupe_flag = n() > 1) %>% 
  ungroup()
```

``` r
filter(aapp, dupe_flag)
#> # A tibble: 193 x 4
#>    npi        name                                                     amount dupe_flag
#>    <chr>      <chr>                                                     <dbl> <lgl>    
#>  1 1548409626 ACTIVCARE PHYSICAL THERAPY, LLC                          905296 TRUE     
#>  2 1548409626 ACTIVCARE PHYSICAL THERAPY, LLC                            6533 TRUE     
#>  3 1235434283 ADVANCE REHABILITATION & CONSULTING LIMITED PARTNERSHIP 1152177 TRUE     
#>  4 1235434283 ADVANCE REHABILITATION & CONSULTING LIMITED PARTNERSHIP    6140 TRUE     
#>  5 1518020361 ADVANCED FOOT CARE LLP                                   127079 TRUE     
#>  6 1518020361 ADVANCED FOOT CARE LLP                                     1516 TRUE     
#>  7 1962501551 ADVANCED UROLOGY, PLLC                                   932501 TRUE     
#>  8 1962501551 ADVANCED UROLOGY, PLLC                                     9059 TRUE     
#>  9 1578900668 AGAPE PHYSICAL THERAPY & SPORTS REHABILITATION LP        376529 TRUE     
#> 10 1578900668 AGAPE PHYSICAL THERAPY & SPORTS REHABILITATION LP          7870 TRUE     
#> # … with 183 more rows
```

### Amounts

``` r
summary(aapp$amount)
#>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
#>         8     44880    191714   2202374    584772 441276234
mean(aapp$amount <= 0)
#> [1] 0
```

These are the records with the minimum and maximum amounts.

``` r
glimpse(aapp[c(which.max(aapp$amount), which.min(aapp$amount)), ])
#> Rows: 2
#> Columns: 4
#> $ npi       <chr> "1801992631", "1093095184"
#> $ name      <chr> "NYU LANGONE HOSPITALS", "MONTCLAIR HOSPITAL LLC"
#> $ amount    <dbl> 441276234, 8
#> $ dupe_flag <lgl> FALSE, FALSE
```

![](../plots/hist_amount-1.png)<!-- -->
