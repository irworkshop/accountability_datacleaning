California Lobbyists
================
Kiernan Nicholls
2020-01-06 16:29:11

  - [Project](#project)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
  - [Export](#export)

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

## Packages

The following packages are needed to collect, manipulate, visualize,
analyze, and communicate these results. The `pacman` package will
facilitate their installation and attachment.

The IRW’s `campfin` package will also have to be installed from GitHub.
This package contains functions custom made to help facilitate the
processing of campaign finance data.

``` r
if (!require("pacman")) install.packages("pacman")
pacman::p_load_gh("irworkshop/campfin")
pacman::p_load(
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
# where does this document knit?
here::here()
#> [1] "/home/kiernan/R/accountability_datacleaning/R_campfin"
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
> Political Reform Act, including… that the voters may be fully informed
> and the activities of lobbyists should be regulated and their finances
> disclosed…"

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

### Variables

Using the data key provided by Cal-Access, we can find the expenditure
file and understand it’s contents.

``` r
key_url <- "https://campaignfinance.cdn.sos.ca.gov/calaccess-documentation.zip"
url_file_size(key_url, format = TRUE)
#> [1] "4 MiB"
```

If they ZIP file containing the documentation files has not yet been
downloaded, we can do so now.

``` r
raw_dir <- dir_create(here("ca", "lobby", "data", "raw"))
key_file <- str_c(raw_dir, basename(key_url), sep = "/")
if (!this_file_new(key_file)) {
  download.file(
    url = key_url,
    destfile = key_file
  )
}
```

Before we unzip the file, we can view it’s contents.

``` r
key_content <- key_file %>% 
  unzip(list = TRUE) %>% 
  as_tibble(.name_repair = make_clean_names)
```

``` r
key_dir <- str_c(raw_dir, "CalAccess-Documentation", sep = "/")
if (!dir_exists(key_dir)) {
  unzip(
    zipfile = key_file,
    exdir = raw_dir
  )
}
```

## Import

### Download

``` r
zip_url <- "https://campaignfinance.cdn.sos.ca.gov/dbwebexport.zip"
zip_file <- str_c(raw_dir, basename(zip_url), sep = "/")
```

The ZIP file is extremelly large, and will take quite some time

``` r
url_file_size(zip_url, format = TRUE)
#> [1] "944 MiB"
if (requireNamespace("speedtest", quietly = TRUE)) {
  speedtest::spd_test()
}
#> Gathering test configuration information...
#> Gathering server list...
#> Determining best server...
#> XInitiating test from Leaseweb USA (23.82.10.115) to AT&T (Washington, DC)
#> 
#> Analyzing download speed..........
#> Download: 419 Mbit/s
#> 
#> Analyzing upload speed......
#> Upload: 185 Mbit/s
```

If the most recent version of the file has not yet been downloaded, we
can do so now.

``` r
if (!this_file_new(zip_file)) {
  download.file(
    url = zip_url,
    destfile = zip_file
  )
}
```

We don’t need to unzip every file, only those pertaining to lobbying.

``` r
zip_content <- unzip(zip_file, list = TRUE) 
zip_lobby <- zip_content$Name[str_which(zip_content$Name, "LOBBY")]
cal_dir <- str_c(raw_dir, unique(dirname(zip_lobby)), sep = "/")
```

Then, if those files have not yet been unzipped, we can do so now.

``` r
if (!dir_exists(cal_dir)) {
  unzip(
    zipfile = zip_file,
    files = zip_lobby,
    exdir = raw_dir
  )
}
```

### Read

Much of the data is split into multiple files. We will list all the
files of a similar name and read them into a single data frame with
`purrr::map_dfr()` and `readr::read_tsv()`.

``` r
if (packageVersion("vroom") < "1.0.2.9000") {
  stop("vroom version of at least 1.0.2.9000 is needed")
}
```

> Lobbyist contribution disclosure table. Temporary table used to
> generate disclosure table (Lobbyist Contributions 3).

``` r
lob_conts <- map_dfr(
  .x = dir_ls(
    path = cal_dir, 
    type = "file", 
    glob = "*LOBBYIST_CONTRIBUTIONS\\d_CD.TSV$"
  ),
  .f = read_tsv,
  col_types = cols(
    FILER_ID = col_character(),
    FILING_PERIOD_START_DT = col_date("%m/%d/%Y %H:%M:%S %p"),
    FILING_PERIOD_END_DT = col_date("%m/%d/%Y %H:%M:%S %p"),
    CONTRIBUTION_DT = col_character(),
    RECIPIENT_NAME = col_character(),
    RECIPIENT_ID = col_character(),
    AMOUNT = col_double()
  )
) %>% 
  clean_names("snake") %>% 
  remove_empty("cols")
```

Every yearly relationship between lobbyists and their principal clients.

``` r
cal_emp_lob <- 
  dir_ls(
    path = cal_dir, 
    type = "file", 
    glob = "*LOBBYIST_EMP_LOBBYIST\\d_CD.TSV"
  ) %>% 
  vroom(
    col_types = cols(
      .default = col_character(),
      SESSION_ID = col_double()
    )
  ) %>% 
  clean_names("snake")
```

Quarterly and annual employee compensation amounts.

``` r
cal_emp_total <- map_df(
  .x = dir_ls(
    path = cal_dir, 
    type = "file", 
    glob = "*LOBBYIST_EMPLOYER\\d_CD.TSV$"
  ),
  .f = read_tsv,
  col_types = cols(
    .default = col_character(),
    SESSION_ID = col_double(),
    CURRENT_QTR_AMT = col_double(),
    SESSION_TOTAL_AMT = col_double(),
    SESSION_YR_1 = col_double(),
    SESSION_YR_2 = col_double(),
    YR_1_YTD_AMT = col_double(),
    YR_2_YTD_AMT = col_double(),
    QTR_1 = col_double(),
    QTR_2 = col_double(),
    QTR_3 = col_double(),
    QTR_4 = col_double(),
    QTR_5 = col_double(),
    QTR_6 = col_double(),
    QTR_7 = col_double(),
    QTR_8 = col_double()
  )
) %>% 
  clean_names("snake") %>% 
  remove_empty("cols")
```

``` r
cal_emp_total <- cal_emp_total %>% 
  select(
    session_id,
    employer_id,
    interest_cd,
    interest_name,
    session_total_amt,
  )
```

``` r
cal_emp_firms <- 
  dir_ls(
    path = cal_dir, 
    type = "file", 
    glob = "*LOBBYIST_EMPLOYER_FIRMS\\d_CD.TSV$"
  ) %>% 
  vroom(
    col_types = cols(
      .default = col_character(),
      SESSION_ID = col_double()
    )
  ) %>% 
  clean_names("snake") %>% 
  remove_empty("cols")
```

``` r
# empty file
file_size(
  dir_ls(
    path = cal_dir, 
    type = "file", 
    glob = "*LOBBYIST_EMPLOYER_HISTORY_CD.TSV$"
  )
)
#> 0
```

``` r
cal_firm_totals <- 
  dir_ls(
    path = cal_dir, 
    type = "file", 
    glob = "*LOBBYIST_FIRM\\d_CD.TSV$"
  ) %>% 
  vroom(
    col_types = cols(
      .default = col_character(),
      CURRENT_QTR_AMT = col_double(),
      SESSION_TOTAL_AMT = col_double(),
      SESSION_YR_1 = col_double(),
      SESSION_YR_2 = col_double(),
      YR_1_YTD_AMT = col_double(),
      YR_2_YTD_AMT = col_double(),
      QTR_1 = col_double(),
      QTR_2 = col_double(),
      QTR_3 = col_double(),
      QTR_4 = col_double(),
      QTR_5 = col_double(),
      QTR_6 = col_double(),
      QTR_7 = col_double(),
      QTR_8 = col_double()
    )
  ) %>% 
  clean_names("snake")
```

``` r
cal_firm_totals <- cal_firm_totals %>% 
  select(
    session_id,
    firm_id,
    firm_name,
    session_total_amt,
  )
```

``` r
calr <- read_delim(
  file = str_c(cal_dir, "CVR_LOBBY_DISCLOSURE_CD.TSV", sep = "/"),
  delim = "\t",
  escape_backslash = FALSE,
  escape_double = FALSE,
  na = c("", "NA", "none", "NONE", "None", "n/a", "N/A"),
  col_types = cols(
    .default = col_character(),
    AMEND_ID = col_double(),
    RPT_DATE = col_date("%m/%d/%Y %H:%M:%S %p"),
    FROM_DATE = col_date("%m/%d/%Y %H:%M:%S %p"),
    THRU_DATE = col_date("%m/%d/%Y %H:%M:%S %p"),
    CUM_BEG_DT = col_date("%m/%d/%Y %H:%M:%S %p"),
    CUM_BEG_DT = col_date("%m/%d/%Y %H:%M:%S %p"),
    SIG_DATE = col_date("%m/%d/%Y %H:%M:%S %p"),
  )
)

calr <- clean_names(calr, "snake")
```

## Explore

``` r
head(calr)
#> # A tibble: 6 x 52
#>   filing_id amend_id rec_type form_type sender_id filer_id entity_cd filer_naml filer_namf
#>   <chr>        <dbl> <chr>    <chr>     <chr>     <chr>    <chr>     <chr>      <chr>     
#> 1 624359           0 CVR      F615      E24542    L25430   LBY       Dinno      Rachel    
#> 2 624360           0 CVR      F615      L24721    L24721   LBY       Farabee    David R.  
#> 3 624361           0 CVR      F615      L23112    L23112   LBY       Rosegay    Margaret …
#> 4 624362           0 CVR      F615      L23330    L23330   LBY       Whitlock   Wayne M.  
#> 5 624363           0 CVR      F615      L23346    L23346   LBY       Maas       Brian W.  
#> 6 624364           0 CVR      F635      E22568    E22568   LEM       Californi… <NA>      
#> # … with 43 more variables: filer_namt <chr>, filer_nams <chr>, report_num <chr>, rpt_date <date>,
#> #   from_date <date>, thru_date <date>, cum_beg_dt <date>, firm_id <chr>, firm_name <chr>,
#> #   firm_city <chr>, firm_st <chr>, firm_zip4 <chr>, firm_phon <chr>, mail_city <chr>,
#> #   mail_st <chr>, mail_zip4 <chr>, mail_phon <chr>, sig_date <date>, sig_loc <chr>,
#> #   sig_naml <chr>, sig_namf <chr>, sig_namt <chr>, sig_nams <chr>, prn_naml <chr>,
#> #   prn_namf <chr>, prn_namt <chr>, prn_nams <chr>, sig_title <chr>, nopart1_cb <chr>,
#> #   nopart2_cb <chr>, part1_1_cb <chr>, part1_2_cb <chr>, ctrib_n_cb <chr>, ctrib_y_cb <chr>,
#> #   lby_actvty <chr>, lobby_n_cb <chr>, lobby_y_cb <chr>, major_naml <chr>, major_namf <chr>,
#> #   major_namt <chr>, major_nams <chr>, rcpcmte_nm <chr>, rcpcmte_id <chr>
tail(calr)
#> # A tibble: 6 x 52
#>   filing_id amend_id rec_type form_type sender_id filer_id entity_cd filer_naml filer_namf
#>   <chr>        <dbl> <chr>    <chr>     <chr>     <chr>    <chr>     <chr>      <chr>     
#> 1 2415709          0 CVR      F635      1400705   1400705  LEM       SIGHTWAY … <NA>      
#> 2 2415710          0 CVR      F635      1402307   1402307  LEM       PARAMOUNT… <NA>      
#> 3 2415711          0 CVR      F625      F00743    F00743   FRM       Pillsbury… <NA>      
#> 4 2415770          0 CVR      F635      1255072   1255072  LEM       MONTEREY … <NA>      
#> 5 2415862          0 CVR      F615      F00854    1375480  LBY       Noland-Ha… Lauren M. 
#> 6 2415864          0 CVR      F615      F00854    L00514   LBY       Soares     George H. 
#> # … with 43 more variables: filer_namt <chr>, filer_nams <chr>, report_num <chr>, rpt_date <date>,
#> #   from_date <date>, thru_date <date>, cum_beg_dt <date>, firm_id <chr>, firm_name <chr>,
#> #   firm_city <chr>, firm_st <chr>, firm_zip4 <chr>, firm_phon <chr>, mail_city <chr>,
#> #   mail_st <chr>, mail_zip4 <chr>, mail_phon <chr>, sig_date <date>, sig_loc <chr>,
#> #   sig_naml <chr>, sig_namf <chr>, sig_namt <chr>, sig_nams <chr>, prn_naml <chr>,
#> #   prn_namf <chr>, prn_namt <chr>, prn_nams <chr>, sig_title <chr>, nopart1_cb <chr>,
#> #   nopart2_cb <chr>, part1_1_cb <chr>, part1_2_cb <chr>, ctrib_n_cb <chr>, ctrib_y_cb <chr>,
#> #   lby_actvty <chr>, lobby_n_cb <chr>, lobby_y_cb <chr>, major_naml <chr>, major_namf <chr>,
#> #   major_namt <chr>, major_nams <chr>, rcpcmte_nm <chr>, rcpcmte_id <chr>
glimpse(sample_frac(calr))
#> Observations: 376,010
#> Variables: 52
#> $ filing_id  <chr> "2100002", "1796327", "1324886", "1104647", "2377707", "1556674", "1841957", …
#> $ amend_id   <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
#> $ rec_type   <chr> "CVR", "CVR", "CVR", "CVR", "CVR", "CVR", "CVR", "CVR", "CVR", "CVR", "CVR", …
#> $ form_type  <chr> "F635", "F635", "F615", "F635", "F635", "F635", "F615", "F635", "F635", "F635…
#> $ sender_id  <chr> "C27258", "1292927", "E00679", "1266294", "1342232", "C00131", "F00074", "C00…
#> $ filer_id   <chr> "C27258", "1292927", "1276466", "1266294", "1342232", "C00131", "L00669", "C0…
#> $ entity_cd  <chr> "LEM", "LEM", "LBY", "LEM", "LEM", "LEM", "LBY", "LEM", "LEM", "LEM", "LBY", …
#> $ filer_naml <chr> "Peace Officers Research Association of California ", "HI-DESERT WATER DISTRI…
#> $ filer_namf <chr> NA, NA, "ANN MARIE", NA, NA, NA, "Stephen E.", NA, NA, NA, "MANOLO ", NA, "RO…
#> $ filer_namt <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ filer_nams <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ report_num <chr> "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", "000", …
#> $ rpt_date   <date> 2016-10-22, 2013-10-21, 2008-04-16, 2005-04-29, 2019-04-26, 2011-01-04, 2014…
#> $ from_date  <date> 2016-07-01, 2013-07-01, 2008-01-01, 2005-01-01, 2019-01-01, 2010-10-01, 2014…
#> $ thru_date  <date> 2016-09-30, 2013-09-30, 2008-03-31, 2005-03-31, 2019-03-31, 2010-12-31, 2014…
#> $ cum_beg_dt <date> 2015-01-01, 2013-01-01, NA, 2003-01-01, 2019-01-01, 2009-01-01, NA, 2017-01-…
#> $ firm_id    <chr> "C27258", "1292927", "E00679", NA, NA, NA, "F00074", NA, "C22049", "C21144", …
#> $ firm_name  <chr> "Peace Officers Research Association of California ", "HI-DESERT WATER DISTRI…
#> $ firm_city  <chr> "Sacramento", "YUCCA VALLEY", "Sacramento", "SAN FRANCISCO", "NEW YORK", "SAN…
#> $ firm_st    <chr> "CA", "CA", "CA", "CA", "NY", "CA", "CA", "CA", "CA", "DC", "CA", "CA", "CA",…
#> $ firm_zip4  <chr> "95834", "92284", "95814", "94103", "10111", "92111", "95864", "95814", "9581…
#> $ firm_phon  <chr> "(916) 928-3777", "(760) 365-8333", "9164465247", "4154950349", "2127150300",…
#> $ mail_city  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ mail_st    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ mail_zip4  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ mail_phon  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ sig_date   <date> 2016-10-22, 2013-10-21, 2008-04-16, 2005-04-29, 2019-04-26, 2011-01-04, 2014…
#> $ sig_loc    <chr> "Sacramento CA", "SACRAMENTO, CA", "Sacramento CA", "San Francisco, CA", "New…
#> $ sig_naml   <chr> "Durant", "EICHMAN, AGENT", "Benitez", "Roland-Nawi", "Benner", "Hynum", "Car…
#> $ sig_namf   <chr> "Michael", "J. RICHARD", "Ann Marie", "Carol", "Michael B.", "Ron", "Stephen …
#> $ sig_namt   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "Mr.", NA, NA…
#> $ sig_nams   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ prn_naml   <chr> "Durant", "EICHMAN, AGENT", NA, "Roland-Nawi", "Benner", "Hynum", NA, "Finley…
#> $ prn_namf   <chr> "Michael", "J. RICHARD", NA, "Carol", "Michael B.", "Ron", NA, "Rob", "STEVE"…
#> $ prn_namt   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "Mr.", NA, NA…
#> $ prn_nams   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ sig_title  <chr> "President", "CERTIFIED PUBLIC ACCOUNTANT,  410100SB", NA, "Vice-President", …
#> $ nopart1_cb <chr> NA, NA, "X", NA, NA, NA, "X", NA, NA, NA, "X", NA, "X", NA, "X", NA, NA, NA, …
#> $ nopart2_cb <chr> NA, NA, "X", NA, NA, NA, "X", NA, NA, NA, "X", NA, "X", NA, "X", NA, NA, NA, …
#> $ part1_1_cb <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ part1_2_cb <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ ctrib_n_cb <chr> NA, "X", NA, "X", "X", NA, NA, NA, NA, "X", NA, NA, NA, "X", NA, "X", NA, "X"…
#> $ ctrib_y_cb <chr> "X", NA, NA, NA, NA, "X", NA, "X", "X", NA, NA, "X", NA, NA, NA, NA, "X", NA,…
#> $ lby_actvty <chr> "AB 898, 953, 1072, 1104, 2028, 2164, 2165; SB 6, 61, 294, 303, 1046", "LEGIS…
#> $ lobby_n_cb <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ lobby_y_cb <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ major_naml <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ major_namf <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ major_namt <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ major_nams <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ rcpcmte_nm <chr> "Peace Officers Research Association of California Political Action Committee…
#> $ rcpcmte_id <chr> "810830", NA, NA, NA, NA, "801218", NA, "860692", "1239772", NA, NA, NA, NA, …
```

``` r
col_stats(calr, count_na)
#> # A tibble: 52 x 4
#>    col        class       n         p
#>    <chr>      <chr>   <int>     <dbl>
#>  1 filing_id  <chr>       0 0        
#>  2 amend_id   <dbl>       0 0        
#>  3 rec_type   <chr>       0 0        
#>  4 form_type  <chr>       0 0        
#>  5 sender_id  <chr>     664 0.00177  
#>  6 filer_id   <chr>       0 0        
#>  7 entity_cd  <chr>    2170 0.00577  
#>  8 filer_naml <chr>       0 0        
#>  9 filer_namf <chr>  267078 0.710    
#> 10 filer_namt <chr>  372633 0.991    
#> 11 filer_nams <chr>  375672 0.999    
#> 12 report_num <chr>     664 0.00177  
#> 13 rpt_date   <date>      0 0        
#> 14 from_date  <date>     11 0.0000293
#> 15 thru_date  <date>     11 0.0000293
#> 16 cum_beg_dt <date> 101032 0.269    
#> 17 firm_id    <chr>  115675 0.308    
#> 18 firm_name  <chr>  108950 0.290    
#> 19 firm_city  <chr>     208 0.000553 
#> 20 firm_st    <chr>    2747 0.00731  
#> 21 firm_zip4  <chr>    2697 0.00717  
#> 22 firm_phon  <chr>    3555 0.00945  
#> 23 mail_city  <chr>  344173 0.915    
#> 24 mail_st    <chr>  344009 0.915    
#> 25 mail_zip4  <chr>  344204 0.915    
#> 26 mail_phon  <chr>  367535 0.977    
#> 27 sig_date   <date>   2235 0.00594  
#> 28 sig_loc    <chr>    1479 0.00393  
#> 29 sig_naml   <chr>    3825 0.0102   
#> 30 sig_namf   <chr>    3712 0.00987  
#> 31 sig_namt   <chr>  346811 0.922    
#> 32 sig_nams   <chr>  373825 0.994    
#> 33 prn_naml   <chr>   33403 0.0888   
#> 34 prn_namf   <chr>   33242 0.0884   
#> 35 prn_namt   <chr>  352548 0.938    
#> 36 prn_nams   <chr>  374282 0.995    
#> 37 sig_title  <chr>   62826 0.167    
#> 38 nopart1_cb <chr>  270631 0.720    
#> 39 nopart2_cb <chr>  267826 0.712    
#> 40 part1_1_cb <chr>  345711 0.919    
#> 41 part1_2_cb <chr>  374952 0.997    
#> 42 ctrib_n_cb <chr>  156763 0.417    
#> 43 ctrib_y_cb <chr>  329308 0.876    
#> 44 lby_actvty <chr>  180393 0.480    
#> 45 lobby_n_cb <chr>  344652 0.917    
#> 46 lobby_y_cb <chr>  375918 1.00     
#> 47 major_naml <chr>  367866 0.978    
#> 48 major_namf <chr>  374488 0.996    
#> 49 major_namt <chr>  375769 0.999    
#> 50 major_nams <chr>  375686 0.999    
#> 51 rcpcmte_nm <chr>  347713 0.925    
#> 52 rcpcmte_id <chr>  350186 0.931
```

``` r
distinct_counts <- col_stats(calr, n_distinct, print = FALSE)
print(distinct_counts)
#> # A tibble: 52 x 4
#>    col        class      n          p
#>    <chr>      <chr>  <int>      <dbl>
#>  1 filing_id  <chr> 346254 0.921     
#>  2 amend_id   <dbl>     11 0.0000293 
#>  3 rec_type   <chr>      1 0.00000266
#>  4 form_type  <chr>      4 0.0000106 
#>  5 sender_id  <chr>  13811 0.0367    
#>  6 filer_id   <chr>  16414 0.0437    
#>  7 entity_cd  <chr>      8 0.0000213 
#>  8 filer_naml <chr>  22362 0.0595    
#>  9 filer_namf <chr>   4699 0.0125    
#> 10 filer_namt <chr>     30 0.0000798 
#> # … with 42 more rows
x_cols <- which(distinct_counts$n <= 4)
x_cols <- x_cols[which(x_cols > 5)]
```

``` r
# parse checkbox cols
calr <- mutate_at(
  .tbl = calr,
  .vars = vars(x_cols),
  .funs = equals, "X"
)
```

``` r
# capitalize all
calr <- mutate_if(
  .tbl = calr,
  .predicate = is_character,
  .funs = str_to_upper
)
```

``` r
# `sender_id` = ID# of Lobbyist Entity that is SUBMITTING this report.
# `filer_id` = ID# of Lobbyist Entity that is SUBJECT of this report.
inner_join(
  x = calr,
  y = cal_emp_lob,
  by = c("filer_id" = "lobbyist_id")
)
#> # A tibble: 9,096 x 57
#>    filing_id amend_id rec_type form_type sender_id filer_id entity_cd filer_naml filer_namf
#>    <chr>        <dbl> <chr>    <chr>     <chr>     <chr>    <chr>     <chr>      <chr>     
#>  1 624398           0 CVR      F615      E00122    1222954  LBY       NIXON      DARRYL    
#>  2 624398           0 CVR      F615      E00122    1222954  LBY       NIXON      DARRYL    
#>  3 624398           0 CVR      F615      E00122    1222954  LBY       NIXON      DARRYL    
#>  4 624398           0 CVR      F615      E00122    1222954  LBY       NIXON      DARRYL    
#>  5 624445           0 CVR      F615      E00243    1222906  LBY       ROTHROCK   DOROTHY   
#>  6 624445           0 CVR      F615      E00243    1222906  LBY       ROTHROCK   DOROTHY   
#>  7 624445           0 CVR      F615      E00243    1222906  LBY       ROTHROCK   DOROTHY   
#>  8 624445           0 CVR      F615      E00243    1222906  LBY       ROTHROCK   DOROTHY   
#>  9 650665           0 CVR      F615      E00559    1223153  LBY       BROWN      AMY L.    
#> 10 650665           0 CVR      F615      E00559    1223153  LBY       BROWN      AMY L.    
#> # … with 9,086 more rows, and 48 more variables: filer_namt <chr>, filer_nams <chr>,
#> #   report_num <chr>, rpt_date <date>, from_date <date>, thru_date <date>, cum_beg_dt <date>,
#> #   firm_id <chr>, firm_name <chr>, firm_city <chr>, firm_st <chr>, firm_zip4 <chr>,
#> #   firm_phon <chr>, mail_city <chr>, mail_st <chr>, mail_zip4 <chr>, mail_phon <chr>,
#> #   sig_date <date>, sig_loc <chr>, sig_naml <chr>, sig_namf <chr>, sig_namt <chr>,
#> #   sig_nams <chr>, prn_naml <chr>, prn_namf <chr>, prn_namt <chr>, prn_nams <chr>,
#> #   sig_title <chr>, nopart1_cb <lgl>, nopart2_cb <lgl>, part1_1_cb <lgl>, part1_2_cb <lgl>,
#> #   ctrib_n_cb <lgl>, ctrib_y_cb <lgl>, lby_actvty <chr>, lobby_n_cb <chr>, lobby_y_cb <chr>,
#> #   major_naml <chr>, major_namf <chr>, major_namt <chr>, major_nams <chr>, rcpcmte_nm <chr>,
#> #   rcpcmte_id <chr>, employer_id <chr>, lobbyist_last_name <chr>, lobbyist_first_name <chr>,
#> #   employer_name <chr>, session_id <dbl>
```

## Wrangle

### ZIP

``` r
calr <- mutate_at(
  .tbl = calr,
  .vars = vars(ends_with("_zip4")),
  .funs = list(norm = normal_zip),
  na_rep = TRUE
)
```

``` r
progress_table(
  calr$firm_zip4,
  calr$mail_zip4,
  calr$firm_zip4_norm,
  calr$mail_zip4_norm,
  compare = valid_zip
)
#> # A tibble: 4 x 6
#>   stage          prop_in n_distinct prop_na n_out n_diff
#>   <chr>            <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 firm_zip4        0.938       4556 0.00717 23309   1580
#> 2 mail_zip4        0.826       1029 0.915    5525    257
#> 3 firm_zip4_norm   0.997       3254 0.00748  1303    145
#> 4 mail_zip4_norm   0.997        865 0.915      93     15
```

### States

``` r
calr <- mutate_at(
  .tbl = calr,
  .vars = vars(ends_with("_st")),
  .funs = list(norm = normal_state),
  na_rep = TRUE
)
```

``` r
progress_table(
  calr$firm_st,
  calr$mail_st,
  calr$firm_st_norm,
  calr$mail_st_norm,
  compare = valid_state
)
#> # A tibble: 4 x 6
#>   stage        prop_in n_distinct prop_na n_out n_diff
#>   <chr>          <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 firm_st        0.995         90 0.00731  1695     39
#> 2 mail_st        0.999         48 0.915      36      6
#> 3 firm_st_norm   0.999         76 0.0110    321     25
#> 4 mail_st_norm   0.999         47 0.915      28      5
```

### City

``` r
calr <- mutate_at(
  .tbl = calr,
  .vars = vars(ends_with("_city")),
  .funs = list(norm = normal_city),
  states = c("CA", "DC"),
  na = invalid_city,
  na_rep = TRUE
)
```

``` r
# firm city
calr <- calr %>% 
  left_join(
    y = zipcodes,
    by = c(
      "firm_st_norm" = "state",
      "firm_zip4_norm" = "zip"
    )
  ) %>% 
  rename(firm_city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(firm_city_norm, firm_city_match),
    match_dist = str_dist(firm_city_norm, firm_city_match),
    firm_city_swap = if_else(
      condition = match_abb | match_dist == 1,
      true = firm_city_match,
      false = firm_city_norm
    )
  ) %>% 
  select(
    -match_abb,
    -match_dist,
  )
```

``` r
# mail city
calr <- calr %>% 
  left_join(
    y = zipcodes,
    by = c(
      "firm_st_norm" = "state",
      "firm_zip4_norm" = "zip"
    )
  ) %>% 
  rename(mail_city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(mail_city_norm, mail_city_match),
    match_dist = str_dist(mail_city_norm, mail_city_match),
    mail_city_swap = if_else(
      condition = match_abb | match_dist == 1,
      true = mail_city_match,
      false = mail_city_norm
    )
  ) %>% 
  select(
    -match_abb,
    -match_dist,
  )
```

``` r
progress_table(
  calr$firm_city,
  calr$firm_city_norm,
  calr$firm_city_swap,
  calr$mail_city,
  calr$mail_city_norm,
  calr$mail_city_swap,
  compare = valid_city
)
#> # A tibble: 6 x 6
#>   stage          prop_in n_distinct  prop_na n_out n_diff
#>   <chr>            <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 firm_city        0.972       2151 0.000553 10478    759
#> 2 firm_city_norm   0.977       1962 0.000558  8690    566
#> 3 firm_city_swap   0.992       1537 0.0169    3116    150
#> 4 mail_city        0.982        530 0.915      578     47
#> 5 mail_city_norm   0.984        528 0.915      498     44
#> 6 mail_city_swap   0.989        505 0.917      343     27
```

## Export

``` r
proc_dir <- dir_create(here("ca", "lobby", "data", "processed"))
write_csv(
  x = calr,
  path = glue("{proc_dir}/ca_lobby_reg.csv"),
  na = ""
)
```
