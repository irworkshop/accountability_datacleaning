California Expenditures
================
Kiernan Nicholls
2019-08-20 15:39:09

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)

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
  magrittr, # pipe opperators
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  glue, # combine strings
  here, # relative storage
  httr, # http query
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

Data is obtained from the California Secretary of State’s [Cal-Access
database](https://www.sos.ca.gov/).

> Cal-Access provides financial information supplied by state
> candidates, donors, lobbyists, and others. Simply start by selecting
> either Campaign Finance Activity, Lobbying Activity, or Cal-Access
> Resources and we will guide you to the information.

The [Political Reform
Division](https://www.sos.ca.gov/campaign-lobbying/about-political-reform-division/)
(PRD) collects the data regarding expenditures made.

> The Political Reform Division administers provisions of California’s
> Political Reform Act, including the law’s most fundamental purpose of
> ensuring that “receipts and expenditures in election campaigns should
> be fully and truthfully disclosed in order that the voters may be
> fully informed and the activities of lobbyists should be regulated and
> their finances disclosed…”

>   - Receive campaign disclosure statements (itemizing contributions
>     received and expenditures made) filed by individuals and
>     committees raising or spending campaign funds to support or oppose
>     state candidates or ballot measures. (Local campaign committees
>     file their itemized disclosure statements with local filing
>     officers).

### About

All California campaign finance data can be downloaded in a single file.
As described on PRD website:

> ### Raw Data for Campaign Finance and Lobbying Activity
> 
> In addition to presenting California campaign finance and lobbying
> activity on the user-friendly [CAL-ACCESS
> website](http://cal-access.sos.ca.gov/), the Secretary of State
> provides the raw data to allow people with technical expertise to
> create their own databases.
> 
> The raw data is presented in tab-delimited text files from
> corresponding tables in the CAL-ACCESS database. Users can uncompress
> and extract the data with standard software such as PKZIP, WinZip, or
> MacZip. The Secretary of State does not provide technical support to
> users who want to download and analyze CAL-ACCESS data in this
> advanced way. However, the Secretary of State offers guides to the
> CAL-ACCESS data structure and fields.

> ### Download Files
> 
>   - [Guides to CAL-ACCESS data structure and fields
>     (ZIP)](https://campaignfinance.cdn.sos.ca.gov/calaccess-documentation.zip)
>   - [CAL-ACCESS raw data
>     (ZIP)](https://campaignfinance.cdn.sos.ca.gov/dbwebexport.zip)
> 
> All CAL-ACCESS users should keep in mind that campaign finance and
> lobbying activity information changes often. The raw data extracts are
> updated once a day. Campaign finance and lobbying activity filings can
> also be obtained in hard copy by contacting the Secretary of State’s
> Political Reform Division.

We will download the file to the `/raw` directory.

``` r
raw_dir <- here("ca", "expends", "data", "raw")
dir_create(raw_dir)
```

### Variables

Using the data key provided by Cal-Access, we can find the expenditure
file and understand it’s contents.

``` r
key_url <- "https://campaignfinance.cdn.sos.ca.gov/calaccess-documentation.zip"
key_file <- str_c(raw_dir, basename(key_url), sep = "/")
url_file_size(key_url, format = TRUE)
#> [1] "4 Mb"
```

If they ZIP file containing the documentation files has not yet been
downloaded, we can do so now.

``` r
if (!this_file_new(key_file)) {
  download.file(
    url = key_url,
    destfile = key_file
  )
}
```

Before we unzip the file, we can view it’s contents.

``` r
key_content <- as_tibble(
  .name_repair = make_clean_names,
  x = unzip(
    zipfile = key_file,
    list = TRUE
  )
)
```

``` r
key_exists <- dir_exists(glue("{raw_dir}/CalAccess-Documentation"))
if (!key_exists) {
  unzip(
    zipfile = key_file,
    exdir = raw_dir
  )
}
```

## Import

From the documentation, we know the `EXPN` table is the one containing
the expenditures we are interested in.

### Download

If the CAL-ACCESS raw data hasn’t yet been downloaded, we can do so.

``` r
zip_url <- "https://campaignfinance.cdn.sos.ca.gov/dbwebexport.zip"
zip_file <- str_c(raw_dir, basename(zip_url), sep = "/")
url_file_size(zip_url, format = TRUE)
#> [1] "935 Mb"
```

``` r
if (!this_file_new(zip_file)) {
  download.file(
    url = zip_url,
    destfile = zip_file
  )
}
```

We can use `unzip(list = TRUE)` to view the contents of the ZIP file.

``` r
zip_contents <- as_tibble(
  .name_repair = make_clean_names,
  x = unzip(
    zipfile = zip_file,
    list = TRUE
  )
)
```

``` r
expn_file <- zip_contents %>% 
  filter(name %>% str_detect("EXPN")) %>% 
  pull(name)
```

``` r
zip_exists <- dir_exists(glue("{raw_dir}/CalAccess"))
if (!zip_exists) {
  unzip(
    zipfile = zip_file,
    exdir = raw_dir,
    files = expn_file
  )
}
```

### Read

``` r
expn_file <- str_c(raw_dir, expn_file, sep = "/")
ca <- read_tsv(
  file = expn_file,
  col_types = cols(
    .default = col_character(),
    EXPN_DATE = col_date("%m/%d/%Y %H:%M:%S %p"),
    AMOUNT = col_double(),
    CUM_YTD = col_double(),
    CUM_OTH = col_double()
  )
)
```

## Explore

``` r
head(ca)
#> # A tibble: 6 x 53
#>   FILING_ID AMEND_ID LINE_ITEM REC_TYPE FORM_TYPE TRAN_ID ENTITY_CD PAYEE_NAML PAYEE_NAMF
#>   <chr>     <chr>    <chr>     <chr>    <chr>     <chr>   <chr>     <chr>      <chr>     
#> 1 578414    0        2         EXPN     E         EXP34   IND       Plotkin    Laura     
#> 2 578415    0        1         EXPN     E         EXP20   OTH       CEWAER     <NA>      
#> 3 578415    0        2         EXPN     E         EXP18   OTH       Californi… <NA>      
#> 4 578415    0        3         EXPN     E         EXP19   OTH       Californi… <NA>      
#> 5 578415    0        4         EXPN     E         EXP28   IND       Eichman    J. Richard
#> 6 578415    0        5         EXPN     E         EXP24   OTH       Five Star… <NA>      
#> # … with 44 more variables: PAYEE_NAMT <chr>, PAYEE_NAMS <chr>, PAYEE_CITY <chr>, PAYEE_ST <chr>,
#> #   PAYEE_ZIP4 <chr>, EXPN_DATE <date>, AMOUNT <dbl>, CUM_YTD <dbl>, CUM_OTH <dbl>,
#> #   EXPN_CHKNO <chr>, EXPN_CODE <chr>, EXPN_DSCR <chr>, AGENT_NAML <chr>, AGENT_NAMF <chr>,
#> #   AGENT_NAMT <chr>, AGENT_NAMS <chr>, CMTE_ID <chr>, TRES_NAML <chr>, TRES_NAMF <chr>,
#> #   TRES_NAMT <chr>, TRES_NAMS <chr>, TRES_CITY <chr>, TRES_ST <chr>, TRES_ZIP4 <chr>,
#> #   CAND_NAML <chr>, CAND_NAMF <chr>, CAND_NAMT <chr>, CAND_NAMS <chr>, OFFICE_CD <chr>,
#> #   OFFIC_DSCR <chr>, JURIS_CD <chr>, JURIS_DSCR <chr>, DIST_NO <chr>, OFF_S_H_CD <chr>,
#> #   BAL_NAME <chr>, BAL_NUM <chr>, BAL_JURIS <chr>, SUP_OPP_CD <chr>, MEMO_CODE <chr>,
#> #   MEMO_REFNO <chr>, BAKREF_TID <chr>, G_FROM_E_F <chr>, XREF_SCHNM <chr>, XREF_MATCH <chr>
tail(ca)
#> # A tibble: 6 x 53
#>   FILING_ID AMEND_ID LINE_ITEM REC_TYPE FORM_TYPE TRAN_ID ENTITY_CD PAYEE_NAML PAYEE_NAMF
#>   <chr>     <chr>    <chr>     <chr>    <chr>     <chr>   <chr>     <chr>      <chr>     
#> 1 2297123   1        16        EXPN     E         EXP2250 OTH       Sprinkler… <NA>      
#> 2 2297123   1        17        EXPN     E         EXP2254 OTH       Sprinkler… <NA>      
#> 3 2297123   1        18        EXPN     E         EXP2237 OTH       United Bu… <NA>      
#> 4 2297123   1        19        EXPN     E         EXP2238 OTH       United Bu… <NA>      
#> 5 2297123   1        20        EXPN     E         EXP2240 COM       Wicks for… Buffy     
#> 6 2297123   1        21        EXPN     E         EXP2239 COM       Wiener fo… Re-Elect …
#> # … with 44 more variables: PAYEE_NAMT <chr>, PAYEE_NAMS <chr>, PAYEE_CITY <chr>, PAYEE_ST <chr>,
#> #   PAYEE_ZIP4 <chr>, EXPN_DATE <date>, AMOUNT <dbl>, CUM_YTD <dbl>, CUM_OTH <dbl>,
#> #   EXPN_CHKNO <chr>, EXPN_CODE <chr>, EXPN_DSCR <chr>, AGENT_NAML <chr>, AGENT_NAMF <chr>,
#> #   AGENT_NAMT <chr>, AGENT_NAMS <chr>, CMTE_ID <chr>, TRES_NAML <chr>, TRES_NAMF <chr>,
#> #   TRES_NAMT <chr>, TRES_NAMS <chr>, TRES_CITY <chr>, TRES_ST <chr>, TRES_ZIP4 <chr>,
#> #   CAND_NAML <chr>, CAND_NAMF <chr>, CAND_NAMT <chr>, CAND_NAMS <chr>, OFFICE_CD <chr>,
#> #   OFFIC_DSCR <chr>, JURIS_CD <chr>, JURIS_DSCR <chr>, DIST_NO <chr>, OFF_S_H_CD <chr>,
#> #   BAL_NAME <chr>, BAL_NUM <chr>, BAL_JURIS <chr>, SUP_OPP_CD <chr>, MEMO_CODE <chr>,
#> #   MEMO_REFNO <chr>, BAKREF_TID <chr>, G_FROM_E_F <chr>, XREF_SCHNM <chr>, XREF_MATCH <chr>
glimpse(sample_frac(ca))
#> Observations: 6,774,266
#> Variables: 53
#> $ FILING_ID  <chr> "1936434", "1679743", "2039018", "1437309", "2192220", "645002", "1694940", "…
#> $ AMEND_ID   <chr> "0", "0", "0", "0", "0", "1", "0", "0", "0", "2", "0", "1", "0", "0", "0", "0…
#> $ LINE_ITEM  <chr> "6224", "54", "7886", "42", "40479", "890", "164", "2", "56", "114", "77", "7…
#> $ REC_TYPE   <chr> "EXPN", "EXPN", "EXPN", "EXPN", "EXPN", "EXPN", "EXPN", "EXPN", "EXPN", "EXPN…
#> $ FORM_TYPE  <chr> "E", "F461P5", "D", "E", "E", "E", "D", "D", "D", "E", "F461P5", "G", "E", "E…
#> $ TRAN_ID    <chr> "D659537", "EXP7146", "DD725971", "EXP1458", "D980807", "FSV40638", "EXP14320…
#> $ ENTITY_CD  <chr> "COM", "COM", "COM", "COM", "COM", "OTH", "COM", NA, "COM", "OTH", "OTH", "OT…
#> $ PAYEE_NAML <chr> "STAND WITH SANDRA FLUKE FOR STATE SENATE 2014", "Bosetti for Assembly 2012",…
#> $ PAYEE_NAMF <chr> NA, NA, NA, NA, NA, NA, NA, NA, "Leland", NA, NA, NA, NA, NA, NA, "Henry", NA…
#> $ PAYEE_NAMT <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ PAYEE_NAMS <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ PAYEE_CITY <chr> "LOS ANGELES", "Sacramento", "SACRAMENTO", "Los Angeles", "SACRAMENTO", "San …
#> $ PAYEE_ST   <chr> NA, "CA", NA, "CA", NA, "CA", "CA", NA, "CA", "CA", "CA", "CA", NA, "CA", "CA…
#> $ PAYEE_ZIP4 <chr> "90048", "95814", "95815", "90004", "95815", "94145-5210", "93449", NA, "9581…
#> $ EXPN_DATE  <date> NA, 2012-03-02, 2016-03-31, 2009-05-06, NA, NA, 2012-09-17, 2011-09-22, 2004…
#> $ AMOUNT     <dbl> 5.00, 1000.00, 25.00, 859.06, 25.00, 61.17, 500.00, 750.00, 1000.00, 600.00, …
#> $ CUM_YTD    <dbl> 0.00, 3900.00, 394566.86, 0.00, 0.00, NA, 500.00, 750.00, 3200.00, 4200.00, 2…
#> $ CUM_OTH    <dbl> 0, NA, 0, NA, 0, NA, NA, NA, NA, NA, 0, NA, 0, NA, NA, NA, 0, NA, NA, NA, 0, …
#> $ EXPN_CHKNO <chr> NA, NA, "3000259282", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "30…
#> $ EXPN_CODE  <chr> "CTB", "MON", "MON", "CTB", "CTB", NA, "MON", "MON", "MON", "OFC", "IKD", "LI…
#> $ EXPN_DSCR  <chr> "Earmarked Contribution from: ROGAN, ROBERT", NA, "Earmarked Contribution fro…
#> $ AGENT_NAML <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "Chase Card Services", NA, NA, NA…
#> $ AGENT_NAMF <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ AGENT_NAMT <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ AGENT_NAMS <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ CMTE_ID    <chr> "1363476", "1342849", NA, "1313572", "1375287", NA, "1350744", NA, "1250804",…
#> $ TRES_NAML  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ TRES_NAMF  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ TRES_NAMT  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ TRES_NAMS  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ TRES_CITY  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ TRES_ST    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ TRES_ZIP4  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ CAND_NAML  <chr> NA, "Rick Bosetti", "NEWSOM FOR CALIFORNIA GOVERNOR 2018", NA, NA, NA, "ERIK …
#> $ CAND_NAMF  <chr> NA, NA, NA, NA, NA, NA, NA, "Sam", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ CAND_NAMT  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ CAND_NAMS  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ OFFICE_CD  <chr> NA, "ASM", NA, NA, NA, NA, "CCM", "SEN", "ASM", NA, NA, NA, NA, NA, NA, "SEN"…
#> $ OFFIC_DSCR <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ JURIS_CD   <chr> NA, "ASM", NA, NA, NA, NA, "OTH", "SEN", "ASM", NA, NA, NA, NA, NA, NA, "SEN"…
#> $ JURIS_DSCR <chr> NA, NA, NA, NA, NA, NA, "CITY OF PISMO BEACH", NA, NA, NA, NA, NA, NA, NA, NA…
#> $ DIST_NO    <chr> NA, "1", NA, NA, NA, NA, NA, "15", "12", NA, NA, NA, NA, NA, NA, "27", NA, NA…
#> $ OFF_S_H_CD <chr> NA, "S", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ BAL_NAME   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "Proposition 86-Tobacco Tax", NA, NA,…
#> $ BAL_NUM    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ BAL_JURIS  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "City of …
#> $ SUP_OPP_CD <chr> NA, "S", "S", NA, NA, NA, "S", "S", "S", NA, "S", NA, NA, NA, NA, "S", "S", "…
#> $ MEMO_CODE  <chr> NA, NA, NA, NA, NA, "X", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ MEMO_REFNO <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ BAKREF_TID <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ G_FROM_E_F <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "E", NA, NA, NA, NA, NA, NA, NA, …
#> $ XREF_SCHNM <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ XREF_MATCH <chr> NA, NA, "X", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "X", NA, NA,…
```
