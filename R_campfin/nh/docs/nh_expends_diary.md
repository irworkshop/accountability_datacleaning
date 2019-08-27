New Hampshire Expenditures
================
Kiernan Nicholls
2019-08-27 16:09:54

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

``` r
if (!require("pacman")) install.packages("pacman")
pacman::p_load_current_gh("kiernann/campfin")
pacman::p_load(
  stringdist, # levenshtein value
  snakecase, # change string case
  RSelenium, # remote browser
  tidyverse, # data manipulation
  lubridate, # datetime strings
  tidytext, # text analysis
  magrittr, # pipe opperators
  janitor, # dataframe clean
  batman, # rep(NA, 8) Batman!
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

New Hampshire campaign finance data from before 2016 can only be
ontained in hand-written PDF format. Data from after 2016 can be
obtained from the [NH Campaign Finance System
(CFS)](https://cfs.sos.nh.gov/ "source").

### About

The [CFS FAQ page](https://cfs.sos.nh.gov/Public/FAQ#Expenditures "FAQ")
defines the data we will be downloading:

> RSA 664:2, IX defines “expenditure” as follows: the disbursement of
> money or thing of value or the making of a legally binding commitment
> to make such a disbursement in the future or the transfer of funds by
> a political committee to another political committee or to a candidate
> for the purpose of promoting the success or defeat of a candidate or
> candidates or measure or measures. “Expenditures” includes
> disbursement constituting independent expenditures, as defined in
> paragraph XI. It dos not include: (a) the candidate’s filing fee or
> his/her expenses for personal travel and subsistence; (b) activity
> designed to encourage individuals to register to vote or to vote, if
> that activity or communication does not mention a clearly identified
> candidate; (c) any communication by any membership organization or
> corporation to its members or stockholders, if the primary purpose of
> that membership organization or corporation is not for the purpose of
> promoting the success or defeat of a candidate or candidate and
> measure or measures; or (d) any communication by a political committee
> member that is not made for the purpose of promoting the success or
> defeat of a candidate or candidates or measure or measures.

> **What is an independent expenditure?**  
> RSA 664:2, XI defines “Independent Expenditures” as follows:
> Expenditure that pay for the development and distribution of a
> communication that expressly advocates the election or defeat of a
> clearly identified candidate or candidates or the success or defeat of
> a measure or measures, which are made without cooperation or
> consultation with any candidate, or any authorized committee or agent
> of such candidate, and which are not made in concert with, or at the
> request or suggestion of, any candidates, or any authorized committee
> or agent of such candidate…
> 
> **Is there a separate independent expenditure report?**
> 
> There is no specific form. The information submitted must be in
> accordance with RSA 664:6, IV-a. Any political committee whose
> independent expenditure, in aggregate, exceeds $500, shall file an
> itemized statement which shall be received by the Secretary of State
> not later than 48 hours after such expenditure is made. NOTE: In
> addition to this 48 hour notification, the independent expenditure
> will be reported on the next report of receipts and expenditures that
> is due.

## Import

To download the bulk data format, one needs to navigate to the
[Expenditures search page](https://cfs.sos.nh.gov/Public/ExpensesList).
From there, remove “2020 General Election” from the “Election Cycle”
drop down menu. Enter “01/01/2010” in the “Transaction Date Range” input
box. After searching with these parameters, download the file by
clicking the “CSV” button at the bottom of the page.

We will automate this using the `RSelenium` package.

``` r
raw_dir <- here("nh", "expends", "data", "raw")
dir_create(raw_dir)
```

``` r
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

# navigate to the NH download site
remote_browser <- remote_driver$client
remote_browser$navigate("https://cfs.sos.nh.gov/Public/ExpensesList")

# chose "All" from elections list
cycle_menu <- "/html/body/div[1]/div[3]/table/tbody/tr/td[4]/div[2]/table[1]/tbody/tr[3]/td/table/tbody/tr[6]/td[2]/select/option[1]"
remote_browser$findElement("xpath", cycle_menu)$clickElement()

# enter Jan 1 2008 as start date
remote_browser$findElement("css", "#dtStartDate")$sendKeysToElement(list("01/01/2008"))
remote_browser$findElement("css", "#dtEndDate")$sendKeysToElement(list(format(today(), "%m/%d/%Y")))

# click search button
remote_browser$findElement("css", "#btnSearch")$clickElement()

csv_button <- "td.bgfooter:nth-child(2) > a:nth-child(2)"
remote_browser$findElement("css", csv_button)$clickElement()

# close the browser and driver
remote_browser$close()
remote_driver$server$stop()
```

``` r
nh <- 
  read_csv(
    file = glue("{raw_dir}/ViewExpenditureList.csv"),
    col_types = cols(
      .default = col_character(),
      `Transaction Date` = col_date("%m/%d/%Y %H:%M:%S %p"),
      `Expenditure Amount` = col_double()
    )
  )
```

We will remove completely empty rows, clean names, uppcercase characters
variables, and separate some columns into their true underlying
variables.

``` r
nh <- nh %>%
  remove_empty("rows") %>% 
  clean_names() %>% 
  mutate_if(is_character, str_to_upper) %>% 
  separate(
    col = reporting_period, 
    remove = FALSE,
    into = c("reporting_date", "reporting_type"), 
    sep = "\\s-\\s"
  ) %>% 
  mutate(reporting_date = parse_date(reporting_date, "%m/%d/%Y")) %>% 
  separate(
    col = office,
    remove = FALSE,
    into = c("office_clean", "district_clean"),
    sep = "\\s-\\s",
    convert = TRUE
  )
```

## Explore

There are 12053 records of 19 variables in the full database.

``` r
head(nh)
```

    #> # A tibble: 6 x 19
    #>   transaction_date cf_id payee_type payee_name payee_address registrant_name registrant_type office
    #>   <date>           <chr> <chr>      <chr>      <chr>         <chr>           <chr>           <chr> 
    #> 1 2018-10-18       0500… INDIVIDUAL GAGYI, PE… 817 CROSS CO… NEW HAMPSHIRE … POLITICAL ADVO… <NA>  
    #> 2 2018-10-18       0500… INDIVIDUAL DILORENZO… 193 SOUTH MA… NEW HAMPSHIRE … POLITICAL ADVO… <NA>  
    #> 3 2018-10-18       0500… INDIVIDUAL TERRIO, R… 130 SOUTH CY… NEW HAMPSHIRE … POLITICAL ADVO… <NA>  
    #> 4 2018-11-06       0300… POLITICAL… BARNSTEAD… 13 HARTSHORN… ACTBLUE NEW HA… POLITICAL COMM… <NA>  
    #> 5 2018-11-06       0300… POLITICAL… BELKNAP C… 24 OAK ISLAN… ACTBLUE NEW HA… POLITICAL COMM… <NA>  
    #> 6 2018-11-06       0300… POLITICAL… NASHUA DE… PO BOX 632, … ACTBLUE NEW HA… POLITICAL COMM… <NA>  
    #> # … with 11 more variables: office_clean <chr>, district_clean <int>, county <chr>,
    #> #   election_cycle <chr>, reporting_period <chr>, reporting_date <date>, reporting_type <chr>,
    #> #   expenditure_type <chr>, expenditure_purpose <chr>, expenditure_amount <dbl>, comments <chr>

``` r
tail(nh)
```

    #> # A tibble: 6 x 19
    #>   transaction_date cf_id payee_type payee_name payee_address registrant_name registrant_type office
    #>   <date>           <chr> <chr>      <chr>      <chr>         <chr>           <chr>           <chr> 
    #> 1 2018-12-31       0900… BUSINESS/… SQUARESPA… 225 VARICK S… WEEKS FOR NH    CANDIDATE COMM… EXECU…
    #> 2 2019-05-07       0900… BUSINESS/… NH WOMEN'… 18 LOW AVE S… WEEKS FOR NH    CANDIDATE COMM… EXECU…
    #> 3 2019-05-07       0900… BUSINESS/… OPEN DEMO… 4 PARK ST #3… WEEKS FOR NH    CANDIDATE COMM… EXECU…
    #> 4 2019-05-07       0900… BUSINESS/… NEW HAMPS… 105 N STATE … WEEKS FOR NH    CANDIDATE COMM… EXECU…
    #> 5 2019-05-07       0900… CANDIDATE… FRIENDS O… PO BOX 623, … WEEKS FOR NH    CANDIDATE COMM… EXECU…
    #> 6 2019-05-07       0900… BUSINESS/… *NOTE ON … NA, NA, NH 0… WEEKS FOR NH    CANDIDATE COMM… EXECU…
    #> # … with 11 more variables: office_clean <chr>, district_clean <int>, county <chr>,
    #> #   election_cycle <chr>, reporting_period <chr>, reporting_date <date>, reporting_type <chr>,
    #> #   expenditure_type <chr>, expenditure_purpose <chr>, expenditure_amount <dbl>, comments <chr>

``` r
glimpse(sample_frac(nh))
```

    #> Observations: 12,053
    #> Variables: 19
    #> $ transaction_date    <date> 2018-09-23, 2019-07-07, 2016-09-08, 2018-10-31, 2018-10-14, 2017-03…
    #> $ cf_id               <chr> "03004273", "03004273", "01000104", "01001093", "01001068", "0300005…
    #> $ payee_type          <chr> "CANDIDATE COMMITTEE", "POLITICAL COMMITTEE", "BUSINESS/GROUP/ORGANI…
    #> $ payee_name          <chr> "KATHERINE ROGERS FOR NH STATE REPRESENTATIVE", "COMMITTEE TO ELECT …
    #> $ payee_address       <chr> "804 ALTON WOODS DRIVE, CONCORD, NH 03301", "PO BOX 1292, CONCORD, N…
    #> $ registrant_name     <chr> "ACTBLUE NEW HAMPSHIRE", "ACTBLUE NEW HAMPSHIRE", "SCHLEIEN, ERIC", …
    #> $ registrant_type     <chr> "POLITICAL COMMITTEE", "POLITICAL COMMITTEE", "CANDIDATE", "CANDIDAT…
    #> $ office              <chr> NA, NA, "STATE REPRESENTATIVE - 37", "STATE REPRESENTATIVE - 33", "S…
    #> $ office_clean        <chr> NA, NA, "STATE REPRESENTATIVE", "STATE REPRESENTATIVE", "STATE REPRE…
    #> $ district_clean      <int> NA, NA, 37, 33, 29, NA, NA, 5, NA, NA, 9, NA, NA, NA, NA, 18, NA, 5,…
    #> $ county              <chr> NA, NA, "HILLSBOROUGH", "ROCKINGHAM", "HILLSBOROUGH", NA, NA, NA, NA…
    #> $ election_cycle      <chr> "2018 ELECTION CYCLE", "ROCKINGHAM DIST. 9 - EPPING", "2016 ELECTION…
    #> $ reporting_period    <chr> "10/17/2018 - GENERAL", "07/31/2019 - PRIMARY", "09/21/2016 - PRIMAR…
    #> $ reporting_date      <date> 2018-10-17, 2019-07-31, 2016-09-21, 2018-11-14, 2018-10-17, 2017-06…
    #> $ reporting_type      <chr> "GENERAL", "PRIMARY", "PRIMARY", "GENERAL", "GENERAL", "GENERAL", "G…
    #> $ expenditure_type    <chr> "MONETARY", "MONETARY", "MONETARY", "MONETARY", "MONETARY", "MONETAR…
    #> $ expenditure_purpose <chr> "OTHER", "OTHER", "PRINTING - COPIES", "PARADE EXPENSES - FEES, CAND…
    #> $ expenditure_amount  <dbl> 67.23, 190.33, 900.08, 19.70, 46.72, 500.00, 100.00, 461.79, 300.00,…
    #> $ comments            <chr> "POLITICAL CONTRIBUTION", "POLITICAL CONTRIBUTION", NA, "FLAGS", NA,…

### Distinct

The variables range in their degree of distinctness.

``` r
glimpse_fun(nh, n_distinct)
```

    #> # A tibble: 19 x 4
    #>    var                 type      n        p
    #>    <chr>               <chr> <int>    <dbl>
    #>  1 transaction_date    date   1144 0.0949  
    #>  2 cf_id               chr     470 0.0390  
    #>  3 payee_type          chr       6 0.000498
    #>  4 payee_name          chr    3161 0.262   
    #>  5 payee_address       chr    3862 0.320   
    #>  6 registrant_name     chr     447 0.0371  
    #>  7 registrant_type     chr       4 0.000332
    #>  8 office              chr      75 0.00622 
    #>  9 office_clean        chr       9 0.000747
    #> 10 district_clean      int      45 0.00373 
    #> 11 county              chr      11 0.000913
    #> 12 election_cycle      chr       8 0.000664
    #> 13 reporting_period    chr      36 0.00299 
    #> 14 reporting_date      date     36 0.00299 
    #> 15 reporting_type      chr       3 0.000249
    #> 16 expenditure_type    chr       6 0.000498
    #> 17 expenditure_purpose chr      82 0.00680 
    #> 18 expenditure_amount  dbl    4400 0.365   
    #> 19 comments            chr    2040 0.169

![](../plots/payee_type_bar-1.png)<!-- -->

![](../plots/registrant_type_bar-1.png)<!-- -->

![](../plots/office_bar-1.png)<!-- -->

![](../plots/county_bar-1.png)<!-- -->

![](../plots/cycle_bar-1.png)<!-- -->

![](../plots/report_type_bar-1.png)<!-- -->

![](../plots/expend_type_bar-1.png)<!-- -->

### Missing

The variables also vary in their degree of values that are `NA`
(missing).

``` r
glimpse_fun(nh, count_na)
```

    #> # A tibble: 19 x 4
    #>    var                 type      n       p
    #>    <chr>               <chr> <int>   <dbl>
    #>  1 transaction_date    date      0 0      
    #>  2 cf_id               chr       0 0      
    #>  3 payee_type          chr       0 0      
    #>  4 payee_name          chr      61 0.00506
    #>  5 payee_address       chr       0 0      
    #>  6 registrant_name     chr       0 0      
    #>  7 registrant_type     chr       0 0      
    #>  8 office              chr    5861 0.486  
    #>  9 office_clean        chr    5861 0.486  
    #> 10 district_clean      int    6336 0.526  
    #> 11 county              chr    7782 0.646  
    #> 12 election_cycle      chr       0 0      
    #> 13 reporting_period    chr       0 0      
    #> 14 reporting_date      date      0 0      
    #> 15 reporting_type      chr       0 0      
    #> 16 expenditure_type    chr       0 0      
    #> 17 expenditure_purpose chr       0 0      
    #> 18 expenditure_amount  dbl       0 0      
    #> 19 comments            chr    7088 0.588

We will flag any records with missing values in the key variables used
to identify an expenditure.

``` r
nh <- flag_na(nh, payee_name)
sum(nh$na_flag)
```

    #> [1] 61

### Duplicates

``` r
nh <- flag_dupes(nh, everything())
sum(nh$dupe_flag)
#> [1] 144
```

### Ranges

#### Amounts

``` r
summary(nh$expenditure_amount)
```

    #>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
    #>       0.0      27.2     100.0    1867.5     340.2 1656456.7

``` r
sum(nh$expenditure_amount <= 0)
```

    #> [1] 0

``` r
nh %>% 
  ggplot(aes(expenditure_amount)) +
  geom_histogram() +
  scale_y_log10() +
  scale_x_continuous(labels = scales::dollar)
```

![](../plots/amount_hist-1.png)<!-- -->

``` r
nh %>% 
  ggplot(aes(payee_type, expenditure_amount)) +
  geom_boxplot(varwidth = TRUE) +
  scale_y_continuous(labels = scales::dollar, trans = "log10") +
  coord_flip()
```

![](../plots/amount_box_to-1.png)<!-- -->

``` r
nh %>% 
  ggplot(aes(registrant_type, expenditure_amount)) +
  geom_boxplot(varwidth = TRUE) +
  scale_y_continuous(labels = scales::dollar, trans = "log10") +
  coord_flip()
```

![](../plots/amount_box_from-1.png)<!-- -->

``` r
nh %>% 
  ggplot(aes(expenditure_type, expenditure_amount)) +
  geom_boxplot(varwidth = TRUE) +
  scale_y_continuous(labels = scales::dollar, trans = "log10") +
  coord_flip()
```

![](../plots/amount_box_how-1.png)<!-- -->

### Dates

``` r
summary(nh$transaction_date)
#>         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
#> "2014-06-16" "2016-11-06" "2018-08-08" "2018-02-03" "2018-10-18" "2019-08-18"
sum(nh$transaction_date > today())
#> [1] 0
```

``` r
nh %>% 
  ggplot(aes(year(transaction_date))) +
  geom_bar()
```

![](../plots/year_bar-1.png)<!-- -->

``` r
nh %>% 
  group_by(month = month(transaction_date)) %>% 
  summarise(median_amount = median(expenditure_amount)) %>% 
  ggplot(aes(x = month, y = median_amount)) +
  geom_line(size = 2)
```

![](../plots/unnamed-chunk-1-1.png)<!-- -->

## Wrangle

### Year

Add a `transaction_year` variable from `transaction_date` using
`lubridate::year()`.

``` r
nh <- nh %>% mutate(transaction_year = year(transaction_date))
```

### Address

We need to extract the ZIP code and state abbreviation from the
`payee_address` string.

``` r
sample(nh$payee_address, 10) %>% cat(sep = "\n")
```

    #> PO BOX 177, RUMNEY, NH 03266
    #> PO BOX 999, HANOVER, NH 03755
    #> 520 S. GRAND AVE., 2ND FLOOR,  LOS ANGELES, CA 90071
    #> PO BOX 84314, BATON ROUGE, LA 70884
    #> 510 D.W. HIGHWAY, MERRIMACK, NH 03054
    #> ONE MEDICAL CENTER DRIVE  , LEBANON, NH 03756
    #> 1383 HATFIELD ROAD, HOPKINTON, NH 03229
    #> 11 DELAWARE RD, NASHUA, NH 03062
    #> PO BOX 45950, OMAHA, NE 68145
    #> 323 MAIN ST, SANDOWN, NH 03873

First, we will extract the ZIP digits from the end of the `address`
string.

``` r
nh <- nh %>% 
  mutate(
    zip_clean = payee_address %>% 
      str_extract(rx_zip) %>% 
      normal_zip(na_rep = TRUE)
  )

sample(nh$zip_clean, 10)
#>  [1] "03102" "03302" "03784" "03103" "03755" "03103" "03885" "03258" "02191" "10001"
```

Then we can get the two digit state abbreviation preceding those digits.

``` r
nh <- nh %>% 
  mutate(
    state_clean = payee_address %>% 
      str_extract(rx_state) %>%
      normal_state(abbreviate = TRUE, na_rep = TRUE)
  )

n_distinct(nh$state_clean)
#> [1] 44
sample(nh$state_clean, 10)
#>  [1] "NH" "PA" "NH" "NH" "NH" "MA" "NH" "NH" "MA" "AR"
prop_in(nh$state_clean, valid_state)
#> [1] 1
```

## Conclude

``` r
min_amount <- scales::dollar(min(nh$expenditure_amount, na.rm = TRUE))
max_amount <- scales::dollar(max(nh$expenditure_amount, na.rm = TRUE))

min_date <- as.character(min(nh$transaction_date, na.rm = TRUE))
max_date <- as.character(max(nh$transaction_date, na.rm = TRUE))
```

1.  There are 12053 records in the database
2.  There are 144 records with duplicate rows(flagged with `dupe_flag`)
3.  The `expenditure_amount` values range from $0.01 to $1,656,457; the
    `transaction_date` values range from 2014-06-16 to 2019-08-18
4.  Consistency has been improved with `stringr` package and custom
    `normalize_*()` functions
5.  The ZIP code and state abbreviation have been extracted fromt the
    `address` variable
6.  The `transaction_year` variable has been created with
    `lubridate::year()`
7.  There are 61 records with missing `payee_name` values

## Export

``` r
dir_proc <- here("nh", "expends", "data", "processed")
dir_create(dir_proc)

write_csv(
  x = nh,
  path = glue("{dir_proc}/nh_expends_clean.csv"),
  na = ""
)
```
