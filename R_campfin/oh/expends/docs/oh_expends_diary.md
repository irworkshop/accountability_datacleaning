Ohio Expenditures
================
Kiernan Nicholls
2019-07-31 17:09:58

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
  - [Conclude](#conclude)
  - [Export](#export)

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

Data is obtained from the [Ohio Secretary of State Campaign Finance
site](https://www.sos.state.oh.us/campaign-finance/search/).

> Search, view and download campaign finance data filed with the
> Secretary of State’s office. Under Ohio Revised Code 3517.106(E),
> information will be provided within five days of an entity filing data
> with the Secretary of State’s office.

The OH SOS provides an FTP (File Transfer Page) option for obtaining
bulk data.

> Welcome to the Ohio Secretary of State’s Campaign Finance File
> Transfer Page. This page was developed to allow users to obtain large
> sets of data faster than the normal query process. At this page you
> can download files of pre-queried data, such as all candidate
> contributions for a particular year or a list of all active political
> action committees registered with the Secretary of State. In addition,
> campaign finance data filed prior to 2000 is available only on this
> site. These files contain all relevant and frequently requested
> information. If you are looking for smaller or very specific sets of
> data please use the regular Campaign Finance queries listed on the
> tabs above.
> 
> The data is in a “comma delimited” format that loads easily into
> Microsoft Excel or Access as well as many other spreadsheet or
> database programs. Many of the available files contain a significant
> quantity of data records. A spreadsheet program, such as Microsoft
> Excel, may not allow all of the data in a file to be loaded because of
> a limit on the number of available rows. For this reason, it is
> advised that a database application be utilized to load and work with
> the data available at this site. For more information please contact
> the Campaign Finance unit at (614) 466-3111 or
> <CFINANCE@SOS.STATE.OH.US>

## Import

### Download

To download the annual files, we need to manually click on the download
link for each.

> On the FTP page, please decide which information you would like to
> download. Click “Download File” on the right hand side. The system
> will then proceed to download the file into Microsoft Excel or provide
> you will an opportunity to download the file to the location on your
> computer (the settings on your computer will dictate this). You may
> see a series of dialog boxes on your screen asking you if you want to
> run or save the zipped .exe file. Follow the dialog boxes for
> whichever you chose telling the computer where you want the files
> saved. The end result will be a .csv file that you can open in
> Microsoft Excel or some other database application.

We can automate this process with the RSelenium package.

``` r
raw_dir <- here("oh", "expends", "data", "raw")
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
      browser.helperApps.neverAsk.saveToDisk = "text/CSV"
    )
  )
)

# navigate to the OH FTP site for candidates
remote_browser <- remote_driver$client
can_url <- "https://www6.sos.state.oh.us/ords/f?p=CFDISCLOSURE:73:16499944485586:CAN:NO:RP:P73_TYPE:CAN:"
remote_browser$navigate(can_url)

# create the CSS selectors for the expends links
childs <- seq(from = 5, to = 43, by = 2)
css_selectors <- glue("tr.highlight-row:nth-child({childs}) > td:nth-child(4) > a:nth-child(1)")

# click on every CSS selector
for (selector in css_selectors) {
  remote_browser$findElement("css", selector)$clickElement()
}

# navigate to the OH FTP site for committees
pac_url <- "https://www6.sos.state.oh.us/ords/f?p=CFDISCLOSURE:73:13908331107877:PAC:NO:RP:P73_TYPE:PAC:"
remote_browser$navigate(pac_url)

# click on every CSS selector
for (selector in css_selectors) {
  remote_browser$findElement("css", selector)$clickElement()
}

# close the browser and driver
remote_browser$close()
remote_driver$server$stop()
```

### Read

We can combine each annual file into a single data frame by using
`purrr::map()` to read each file with `readr::read_csv()` into a single
list, then bind each list element with `dplyr::bind_rows()`.

``` r
oh <- 
  dir_ls(
    path = raw_dir, 
    glob = "*EXP*.CSV$"
  ) %>% 
  map(
    read_csv,
    col_types = cols(
      .default = col_character(),
      RPT_YEAR = col_integer(),
      EXPEND_DATE = col_date("%m/%d/%Y"),
      AMOUNT = col_number(),
      EVENT_DATE = col_date("%m/%d/%Y"),
      INKIND = col_logical(),
      DISTRICT = col_integer()
    )
  ) %>% 
  bind_rows(.id = "file") %>%
  mutate(file = basename(file)) %>%
  clean_names()
```

## Explore

``` r
head(oh)
```

    #> # A tibble: 6 x 26
    #>   file  com_name master_key rpt_year report_key report_descript… short_descripti… first_name
    #>   <chr> <chr>    <chr>         <int> <chr>      <chr>            <chr>            <chr>     
    #> 1 ALL_… FRIENDS… 2              2000 123946     ANNUAL   (JANUA… 31-F  FR Expend… <NA>      
    #> 2 ALL_… FRIENDS… 2              2000 123946     ANNUAL   (JANUA… 31-B  Stmt of E… <NA>      
    #> 3 ALL_… FRIENDS… 2              2000 123946     ANNUAL   (JANUA… 31-B  Stmt of E… <NA>      
    #> 4 ALL_… FRIENDS… 2              2000 123946     ANNUAL   (JANUA… 31-B  Stmt of E… THEODORA  
    #> 5 ALL_… FRIENDS… 2              2000 123946     ANNUAL   (JANUA… 31-B  Stmt of E… <NA>      
    #> 6 ALL_… FRIENDS… 2              2000 123946     ANNUAL   (JANUA… 31-B  Stmt of E… <NA>      
    #> # … with 18 more variables: middle_name <chr>, last_name <chr>, suffix_name <chr>,
    #> #   non_individual <chr>, address <chr>, city <chr>, state <chr>, zip <chr>, expend_date <date>,
    #> #   amount <dbl>, event_date <date>, purpose <chr>, inkind <lgl>, candidate_first_name <chr>,
    #> #   candidate_last_name <chr>, office <chr>, district <int>, party <chr>

``` r
tail(oh)
```

    #> # A tibble: 6 x 26
    #>   file  com_name master_key rpt_year report_key report_descript… short_descripti… first_name
    #>   <chr> <chr>    <chr>         <int> <chr>      <chr>            <chr>            <chr>     
    #> 1 PAC_… OHIOANS… 15142          2019 348934018  SEMIANNUAL   (J… 31-B  Stmt of E… <NA>      
    #> 2 PAC_… THE JM … 15154          2019 348983053  MAY 20TH MONTHLY 31-B  Stmt of E… <NA>      
    #> 3 PAC_… OHIOANS… 15170          2019 350645149  SEMIANNUAL   (J… 31-B  Stmt of E… <NA>      
    #> 4 PAC_… OHIOANS… 15170          2019 350645149  SEMIANNUAL   (J… 31-B  Stmt of E… <NA>      
    #> 5 PAC_… OHIOANS… 15170          2019 350645149  SEMIANNUAL   (J… 31-B  Stmt of E… <NA>      
    #> 6 PAC_… OHIOANS… 15170          2019 350645149  SEMIANNUAL   (J… 31-B  Stmt of E… <NA>      
    #> # … with 18 more variables: middle_name <chr>, last_name <chr>, suffix_name <chr>,
    #> #   non_individual <chr>, address <chr>, city <chr>, state <chr>, zip <chr>, expend_date <date>,
    #> #   amount <dbl>, event_date <date>, purpose <chr>, inkind <lgl>, candidate_first_name <chr>,
    #> #   candidate_last_name <chr>, office <chr>, district <int>, party <chr>

``` r
glimpse(sample_frac(oh))
```

    #> Observations: 889,140
    #> Variables: 26
    #> $ file                 <chr> "PAC_EXP_2010.CSV", "ALL_PAC_EXP_2000.CSV", "ALL_CAN_EXP_2008.CSV",…
    #> $ com_name             <chr> "AFSCME OHIO COUNCIL 8  AFL-CIO PAC", "NATIONAL CITY CORPORATION PA…
    #> $ master_key           <chr> "11422", "1488", "12116", "13180", "6665", "1159", "9095", "13511",…
    #> $ rpt_year             <int> 2010, 2000, 2008, 2015, 2011, 2018, 2008, 2011, 2004, 2000, 2002, 2…
    #> $ report_key           <chr> "86716921", "653365", "235384", "189288406", "100454023", "32573087…
    #> $ report_description   <chr> "PRE-GENERAL", "POST-PRIMARY", "POST-PRIMARY", "ANNUAL   (JANUARY)"…
    #> $ short_description    <chr> "31-B  Stmt of Expenditures", "31-B  Stmt of Expenditures", "31-B  …
    #> $ first_name           <chr> NA, NA, NA, NA, NA, NA, NA, "MIKE", NA, NA, NA, NA, NA, NA, NA, "RO…
    #> $ middle_name          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "L", NA…
    #> $ last_name            <chr> NA, NA, NA, NA, NA, NA, NA, "NICHOLAS", NA, NA, NA, NA, NA, NA, NA,…
    #> $ suffix_name          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
    #> $ non_individual       <chr> "EDNA BROWN CAMPAIGN COMMITTEE", "GILB SATE REPRESENTATIVE COMM TO …
    #> $ address              <chr> "2461 WARREN STREET", "1034 TWP RD 293", "PO BOX 143", "130 HARBOUR…
    #> $ city                 <chr> "TOLEDO", "FOSTORIA", "MIAMIVILLE", "DAVIDSON", "BATAVIA", NA, "COL…
    #> $ state                <chr> "OH", "OH", "OH", "NC", "OH", NA, "OH", "OH", "OH", "OH", "OH", "OH…
    #> $ zip                  <chr> "43620", "44830", "45147", "28036", "45103", NA, "43215", "44471", …
    #> $ expend_date          <date> 2010-10-05, 2000-04-04, 2008-04-01, 2015-07-12, 2011-04-05, 2018-0…
    #> $ amount               <dbl> 11395.56, 500.00, 35.00, 165.66, 100.00, 500.00, 946.33, 1500.00, 1…
    #> $ event_date           <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
    #> $ purpose              <chr> "CONTRIBUTION - CHECK OUTSTANDING", "CONTRIBUTION TO NON-FEDERAL CA…
    #> $ inkind               <lgl> NA, NA, FALSE, NA, NA, NA, NA, NA, FALSE, NA, NA, NA, NA, FALSE, NA…
    #> $ candidate_first_name <chr> NA, NA, "LAURA", "WILLIAM", NA, NA, "STEVE", NA, "CYRUS", NA, NA, "…
    #> $ candidate_last_name  <chr> NA, NA, "CURLISS", "BEAGLE", NA, NA, "STIVERS", NA, "RICHARDSON", N…
    #> $ office               <chr> NA, NA, "COURT OF APPEALS JUDGE", "SENATE", NA, NA, "SENATE", NA, "…
    #> $ district             <int> NA, NA, 12, 5, NA, NA, 16, NA, 88, NA, NA, 4, NA, 0, 5, 46, NA, NA,…
    #> $ party                <chr> NA, NA, "DEMOCRAT", "REPUBLICAN", NA, NA, "REPUBLICAN", NA, "DEMOCR…

### Missing

``` r
glimpse_fun(oh, count_na)
```

    #> # A tibble: 26 x 4
    #>    var                  type       n        p
    #>    <chr>                <chr>  <int>    <dbl>
    #>  1 file                 chr        0 0       
    #>  2 com_name             chr        0 0       
    #>  3 master_key           chr        0 0       
    #>  4 rpt_year             int        0 0       
    #>  5 report_key           chr        0 0       
    #>  6 report_description   chr        0 0       
    #>  7 short_description    chr        0 0       
    #>  8 first_name           chr   800767 0.901   
    #>  9 middle_name          chr   872936 0.982   
    #> 10 last_name            chr   799729 0.899   
    #> 11 suffix_name          chr   885918 0.996   
    #> 12 non_individual       chr    91270 0.103   
    #> 13 address              chr    72301 0.0813  
    #> 14 city                 chr    58430 0.0657  
    #> 15 state                chr    56755 0.0638  
    #> 16 zip                  chr    68645 0.0772  
    #> 17 expend_date          date    1481 0.00167 
    #> 18 amount               dbl      400 0.000450
    #> 19 event_date           date  857776 0.965   
    #> 20 purpose              chr    52266 0.0588  
    #> 21 inkind               lgl   786537 0.885   
    #> 22 candidate_first_name chr   394875 0.444   
    #> 23 candidate_last_name  chr   394656 0.444   
    #> 24 office               chr   394656 0.444   
    #> 25 district             int   398309 0.448   
    #> 26 party                chr   394742 0.444

There are 0 missing values for the `com_name` variable, used to identify
the giving party to the expenditure. The payee is identified by either
`last_name` for individuals or `non_individual` for, well, non
individuals. There are some records without wither payee name, which we
will now flag with `na_flag`. We will also flag any record missing an
`amount` value. However, there 0.167% of records are missing an
`expend_date`, too usefully many to flag.

``` r
oh <- mutate(oh, na_flag = (is.na(last_name) & is.na(non_individual)) | is.na(amount))
sum(oh$na_flag)
```

    #> [1] 2493

### Duplicates

There are many duplicated records, 1.22% of the entire database.

``` r
nrow(oh) - nrow(distinct(oh))
```

    #> [1] 10876

### Categorical

``` r
glimpse_fun(oh, n_distinct)
```

    #> # A tibble: 27 x 4
    #>    var                  type       n          p
    #>    <chr>                <chr>  <int>      <dbl>
    #>  1 file                 chr       39 0.0000439 
    #>  2 com_name             chr     4159 0.00468   
    #>  3 master_key           chr     4175 0.00470   
    #>  4 rpt_year             int       20 0.0000225 
    #>  5 report_key           chr    58226 0.0655    
    #>  6 report_description   chr       61 0.0000686 
    #>  7 short_description    chr       14 0.0000157 
    #>  8 first_name           chr     4777 0.00537   
    #>  9 middle_name          chr      336 0.000378  
    #> 10 last_name            chr    12054 0.0136    
    #> 11 suffix_name          chr      189 0.000213  
    #> 12 non_individual       chr   133963 0.151     
    #> 13 address              chr   174155 0.196     
    #> 14 city                 chr     7048 0.00793   
    #> 15 state                chr      136 0.000153  
    #> 16 zip                  chr    16159 0.0182    
    #> 17 expend_date          date    7791 0.00876   
    #> 18 amount               dbl    84179 0.0947    
    #> 19 event_date           date    4725 0.00531   
    #> 20 purpose              chr   148833 0.167     
    #> 21 inkind               lgl        3 0.00000337
    #> 22 candidate_first_name chr      689 0.000775  
    #> 23 candidate_last_name  chr     1742 0.00196   
    #> 24 office               chr       17 0.0000191 
    #> 25 district             int      102 0.000115  
    #> 26 party                chr       12 0.0000135 
    #> 27 na_flag              lgl        2 0.00000225

![](../plots/words_bar-1.png)<!-- -->

### Continuous

#### Amounts

``` r
summary(oh$amount)
```

    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
    #> -150000      48     200    1595     500 9715708     400

``` r
sum(oh$amount < 0, na.rm = TRUE)
```

    #> [1] 2953

``` r
oh %>% 
  ggplot(aes(amount)) +
  geom_histogram() +
  scale_x_continuous(
    trans = "log10", 
    labels = dollar,
    breaks = c(1, 10, 100, 1000, 10000, 100000, 1000000)
  ) +
  labs(
    title = "Ohio Expenditures Amount Distribution",
    x = "Amount",
    y = "Count",
    caption = "Source: OH SOS"
  )
```

![](../plots/unnamed-chunk-2-1.png)<!-- -->

![](../plots/amount_box_party-1.png)<!-- -->

#### Dates

``` r
oh <- mutate(oh, expend_year = year(expend_date))
min_year <- min(as.double(str_extract(dir_ls(raw_dir) , "\\d{4}")))
```

``` r
min(oh$expend_date, na.rm = TRUE)
#> [1] "10-03-02"
sum(oh$expend_year < min_year, na.rm = TRUE)
#> [1] 915
max(oh$expend_date, na.rm = TRUE)
#> [1] "5555-05-05"
sum(oh$expend_date > today(), na.rm = TRUE)
#> [1] 318
```

``` r
oh <- mutate(oh, date_flag = expend_year < min_year | expend_date > today())
sum(oh$date_flag, na.rm = TRUE)
```

    #> [1] 1233

``` r
oh <- oh %>% 
  mutate(
    date_clean = as_date(ifelse(date_flag, NA, expend_date)),
    year_clean = year(date_clean)
  )
```

![](../plots/report_year_bar-1.png)<!-- -->

![](../plots/year_count_bar-1.png)<!-- -->

![](../plots/year_amount_bar-1.png)<!-- -->

![](../plots/month_amount_line-1.png)<!-- -->

![](../plots/month_total_line-1.png)<!-- -->

## Wrangle

### Address

### ZIP

### State

### City

## Conclude

## Export
