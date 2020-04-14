Massachusetts Contributions
================
Kiernan Nicholls
2020-04-14 11:15:33

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
  - [Conclude](#conclude)
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

The IRW’s `campfin` package will also have to be installed from GitHub.
This package contains functions custom made to help facilitate the
processing of campaign finance data.

``` r
if (!require("pacman")) install.packages("pacman")
pacman::p_load_gh("irworkshop/campfin")
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  magrittr, # pipe operators
  gluedown, # print markdown
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
[`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning)
GitHub repository.

The `R_campfin` project uses the [RStudio
projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects)
feature and should be run as such. The project also uses the dynamic
`here::here()` tool for file paths relative to *your* machine.

``` r
# where does this document knit?
here::here()
#> [1] "/home/kiernan/Code/accountability_datacleaning/R_campfin"
```

## Data

Data is obtained from the Massachusetts \[Office of Campaign and
Political Finance (OCPF)\]\[<https://www.ocpf.us/>\].

> The Office of Campaign and Political Finance is an independent state
> agency that administers Massachusetts General Law
> [Chapter 55](https://www.ocpf.us/Legal/CampaignFinanceLaw) the
> campaign finance law, and
> [Chapter 55C](https://www.ocpf.us/Legal/PublicFinancingLaw), the
> limited public financing program for statewide candidates. Established
> in 1973, OCPF is the depository for disclosure reports filed by
> candidates and political committees under M.G.L. Chapter 55.

## Import

We can import data by downloading "" from the [OCPF Data Download
page](https://www.ocpf.us/Data).

### Download

The data is provided as an archived [Microsoft Access (MDB)
file](http://ocpf2.blob.core.windows.net/downloads/data/campaign-finance-reports.zip).
This file is updated nightly at 3:00am.

> Download a zipped Microsoft Access 2000 format (`.mdb`) database that
> includes report summaries, receipts, expenditures, in-kind
> contributions, liabilities, assets disposed, savings accounts, credit
> card reports, reimbursement reports and subvendor reports.

We can download this archive and extract the file to the
`ma/contribs/data/raw` directory.

``` r
raw_dir <- dir_create(here("ma", "contribs", "data", "raw"))
zip_url <- "http://ocpf2.blob.core.windows.net/downloads/data/campaign-finance-reports.zip"
zip_file <- url2path(zip_url, raw_dir) 
mdb_file <- if (!this_file_new(zip_file)) {
  download.file(zip_url, zip_file)
  unzip(zip_file, exdir = raw_dir)
} else {
  dir_ls(raw_dir, regexp = "mdb")
}
```

Using the `system2()` function, we can utilize the
[`mdbtools`](https://github.com/brianb/mdbtools) command line tool to
list the tables contained in the Access file. The `mdbtools` CLI program
is free, open-source, and can be downloaded on Linux systems using APT.

``` bash
sudo apt install mdbtools
```

``` r
mdb_tables <- system2("mdb-tables", args = mdb_file, stdout = TRUE)
mdb_tables <- str_split(str_trim(mdb_tables), "\\s")[[1]]
md_bullet(md_code(mdb_tables))
```

  - `vUPLOAD_MASTER`
  - `vUPLOAD_tCURRENT_ASSETS_DISPOSED`
  - `vUPLOAD_tCURRENT_BANK_CREDITS`
  - `vUPLOAD_tCURRENT_CPF9_DETAIL`
  - `vUPLOAD_tCURRENT_CPF9_SUMMARIES`
  - `vUPLOAD_tCURRENT_EXPENDITURES`
  - `vUPLOAD_tCURRENT_INKINDS`
  - `vUPLOAD_tCURRENT_LIABILITIES`
  - `vUPLOAD_tCURRENT_R1_DETAIL`
  - `vUPLOAD_tCURRENT_R1_SUMMARIES`
  - `vUPLOAD_tCURRENT_RECEIPTS`
  - `vUPLOAD_tCURRENT_SAVINGS`
  - `vUPLOAD_tCURRENT_SUBVENDOR_ITEMS`
  - `vUPLOAD_tCURRENT_SUBVENDOR_SUMMARIES`

### Read

The using `mdbtools` via `system2(stdout = TRUE)` write the database
table to a local CSV file which is then imported into R with
`readr::read_csv()`.

``` r
read_mdb <- function(file, table, ...) {
  out_file <- fs::path_temp(table)
  system2("mdb-export", c(file, table), stdout = out_file)
  readr::read_csv(out_file, ...)
}
```

We can use this method to first read the `UPLOAD_CURRENT_RECEIPTS` file,
which contains all contributions made to Massachusetts political
committees.

``` r
mac <- read_mdb(
  file = mdb_file,
  table = "vUPLOAD_tCURRENT_RECEIPTS",
  col_types = cols(
    .default = col_character(),
    Date = col_date(),
    Amount = col_double()
  )
)
```

    #>             used  (Mb) gc trigger   (Mb)  max used   (Mb)
    #> Ncells   9402506 502.2   19527687 1042.9   9524747  508.7
    #> Vcells 115618821 882.2  227308690 1734.3 220644084 1683.4

The records of the receipts file are provided to OCPF on reports,
identified by the `rpt_id` variable. The receipt records themselves do
not contain the information on the committee recipients of each
contribution. The information on the recieving committee are contained
in the `UPLOAD_MASTER` database. We can read that table using the same
method as above.

``` r
master <- read_mdb(
  file = mdb_file,
  table = "vUPLOAD_MASTER",
  col_types = cols(
    .default = col_character(),
    Amendment = col_logical(),
    Filing_Date = col_datetime("%m/%d/%y %H:%M:%S"),
    Report_Year = col_integer(),
    Beginning_Date = col_date(),
    Ending_Date = col_date()
  )
)
```

The records of this file contain the identifying information for the
recieving committees making each report. We can use
`dplyr::inner_join()` to join this table with the contributions table
along the `rpt_id` variable.

``` r
mac <- inner_join(mac, master, by = "rpt_id")
```

## Explore

``` r
head(mac)
#> # A tibble: 6 x 33
#>   id    rpt_id line  date       cont_type first last  address city  state zip   occupation employer
#>   <chr> <chr>  <chr> <date>     <chr>     <chr> <chr> <chr>   <chr> <chr> <chr> <chr>      <chr>   
#> 1 5358… 39     5358… 2002-01-02 Individu… E.A.  Drake PO Box… Bedf… MA    01730 <NA>       <NA>    
#> 2 5358… 39     5358… 2002-01-02 Individu… Jacq… Mich… 19 Gou… Bedf… MA    <NA>  <NA>       <NA>    
#> 3 5358… 39     5358… 2002-01-02 Individu… Suza… Beale 8 Aspe… Bedf… MA    <NA>  <NA>       <NA>    
#> 4 5358… 39     5358… 2002-01-02 Individu… Will… Beale 8 Aspe… Bedf… MA    <NA>  <NA>       <NA>    
#> 5 5358… 39     5358… 2002-01-02 Individu… Dave  Hema… 1 Heri… Bedf… MA    <NA>  <NA>       <NA>    
#> 6 5358… 39     5358… 2002-01-02 Individu… Trent Fish… 241 Le… Wobu… MA    01801 <NA>       <NA>    
#> # … with 20 more variables: officer <chr>, cont_id <chr>, amount <dbl>, tender <chr>, guid <chr>,
#> #   rpt_year <int>, filing_date <dttm>, start_date <date>, end_date <date>, cpf_id <chr>,
#> #   report_type <chr>, cand_name <chr>, office <chr>, district <chr>, comm_name <chr>,
#> #   comm_city <chr>, comm_state <chr>, comm_zip <chr>, category <chr>, amendment <lgl>
tail(mac)
#> # A tibble: 6 x 33
#>   id    rpt_id line  date       cont_type first last  address city  state zip   occupation employer
#>   <chr> <chr>  <chr> <date>     <chr>     <chr> <chr> <chr>   <chr> <chr> <chr> <chr>      <chr>   
#> 1 1376… 736487 1376… 2020-03-30 Individu… Jill  Gold… 25 Lar… Newt… MA    02468 Consultant Goldenb…
#> 2 1376… 736487 1376… 2020-03-30 Individu… Judi… Shub… 38 Dov… Well… MA    02482 <NA>       <NA>    
#> 3 1376… 736487 1376… 2020-03-30 Individu… Paul  Nees… 18 Tim… Mill… MA    02054 <NA>       <NA>    
#> 4 1376… 736488 1376… 2020-04-13 Individu… James Mart… 38 Oxf… Long… MA    0110… Attorney   Robinso…
#> 5 1376… 736489 1376… 2020-04-13 Individu… Arle… Rodr… 11 Vis… Cent… MA    0263… Vice Pres… STCC    
#> 6 1376… 736490 1376… 2020-04-13 Individu… Will… Togn… 870 Lo… Long… MA    0110… <NA>       <NA>    
#> # … with 20 more variables: officer <chr>, cont_id <chr>, amount <dbl>, tender <chr>, guid <chr>,
#> #   rpt_year <int>, filing_date <dttm>, start_date <date>, end_date <date>, cpf_id <chr>,
#> #   report_type <chr>, cand_name <chr>, office <chr>, district <chr>, comm_name <chr>,
#> #   comm_city <chr>, comm_state <chr>, comm_zip <chr>, category <chr>, amendment <lgl>
glimpse(sample_n(mac, 20))
#> Rows: 20
#> Columns: 33
#> $ id          <chr> "5525050", "6720886", "12605050", "9037795", "5608601", "7461695", "12059006…
#> $ rpt_id      <chr> "10275", "68960", "661684", "208741", "14950", "109026", "611669", "188874",…
#> $ line        <chr> "5525050", "6720886", "12605050", "9037795", "5608601", "7461695", "12059006…
#> $ date        <date> 2002-10-24, 2006-09-13, 2018-07-05, 2014-08-23, 2002-09-04, 2010-03-11, 201…
#> $ cont_type   <chr> "OTHER", "Individual", "Individual", "Individual", "Individual", "Individual…
#> $ first       <chr> "SEIU Loc 509 Seg", "RICHARD", "Richard A.", "Timothy", "Richard", "Jane", N…
#> $ last        <chr> "Union", "WAITT", "Galvin", "Gonsalves", "Battin", "O'Connor", "Elevator Con…
#> $ address     <chr> "Post Office Box 509", "3 BUTTERWORTH RD", "37 Eagle Dr", "159 South Main St…
#> $ city        <chr> "Cambridge", "Wilmington", "Fairfield", "Milford", "Lexington", "Shrewsbury"…
#> $ state       <chr> "MA", "MA", "CT", "MA", "MA", "MA", "MA", "MA", "RI", "MA", "MA", "MA", "MA"…
#> $ zip         <chr> "02139", "01887-3841", "06825-1965", "01757", "02421", "01545", "02122-2611"…
#> $ occupation  <chr> "Union Segregated Fund", "CIVIL ENGINEER", "Real Estate", "corrections offic…
#> $ employer    <chr> "-------------", "INFO REQ", "Commonwealth Ventures LLC", "Massachusetts Dep…
#> $ officer     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ cont_id     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ amount      <dbl> 15000.00, 250.00, 500.00, 5.00, 30.00, 25.00, 500.00, 300.00, 200.00, 125.00…
#> $ tender      <chr> "Check", "Check", "Credit Card", "Unknown", "Check", "Check", "Unknown", "Un…
#> $ guid        <chr> "{c0dd1523-6227-4b2d-559e-1f456763f279}", "{f9605602-5b0d-4f14-79ad-2a610c95…
#> $ rpt_year    <int> 2002, 2006, 2018, 2014, 2002, 2010, 2016, 2013, 2012, 2011, 2013, 2020, 2013…
#> $ filing_date <dttm> 2002-11-05 12:49:38, 2007-09-04 11:47:27, 2018-07-10 10:13:00, 2014-10-27 1…
#> $ start_date  <date> NA, NA, NA, 2014-08-23, NA, NA, 2016-01-01, 2013-07-01, NA, 2011-07-01, NA,…
#> $ end_date    <date> 2002-10-24, 2006-09-13, 2018-07-05, 2014-10-17, 2002-09-04, 2010-03-11, 201…
#> $ cpf_id      <chr> "30914", "14376", "13173", "80690", "13821", "13256", "11853", "14191", "130…
#> $ report_type <chr> "Deposit Report", "Deposit Report", "Deposit Report", "Pre-election Report (…
#> $ cand_name   <chr> "Shannon P. O'Brien", "Deval L. Patrick", "Martin J. Walsh", "MA Correction …
#> $ office      <chr> "Constitutional", "Constitutional", "Mayoral", "Unknown/ N/A", "Constitution…
#> $ district    <chr> "Governor", "Governor", "Boston", "Unknown/ N/A", "Governor", "Treasurer of …
#> $ comm_name   <chr> "The Shannon O'Brien Committee", "The Deval Patrick Committee", NA, "MA Corr…
#> $ comm_city   <chr> NA, NA, NA, "Milford", NA, "Shrewsbury", "Boston", "W. Springfield", NA, "Wi…
#> $ comm_state  <chr> NA, NA, NA, "MA", NA, "MA", "MA", "MA", NA, "MA", NA, "MA", "MA", "MA", "MA"…
#> $ comm_zip    <chr> NA, NA, NA, "01757", NA, "01545", "02137", "01090", NA, "01095", NA, "01748"…
#> $ category    <chr> "D", "D", "D", "P", "D", "D", "N", "N", "D", "N", "D", "P", "P", "D", "N", "…
#> $ amendment   <lgl> FALSE, TRUE, FALSE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FA…
```

### Missing

We should flag any records missing one of the key variables needed to
properly identify a unique contribution.

``` r
col_stats(mac, count_na)
#> # A tibble: 33 x 4
#>    col         class        n           p
#>    <chr>       <chr>    <int>       <dbl>
#>  1 id          <chr>        0 0          
#>  2 rpt_id      <chr>        0 0          
#>  3 line        <chr>        0 0          
#>  4 date        <date>       0 0          
#>  5 cont_type   <chr>        0 0          
#>  6 first       <chr>   212828 0.0650     
#>  7 last        <chr>    34920 0.0107     
#>  8 address     <chr>   121287 0.0370     
#>  9 city        <chr>   103224 0.0315     
#> 10 state       <chr>    69604 0.0212     
#> 11 zip         <chr>   144847 0.0442     
#> 12 occupation  <chr>  1394838 0.426      
#> 13 employer    <chr>  1400655 0.427      
#> 14 officer     <chr>  3248948 0.992      
#> 15 cont_id     <chr>  3184098 0.972      
#> 16 amount      <dbl>        0 0          
#> 17 tender      <chr>        0 0          
#> 18 guid        <chr>        0 0          
#> 19 rpt_year    <int>        0 0          
#> 20 filing_date <dttm>       0 0          
#> 21 start_date  <date> 1817102 0.555      
#> 22 end_date    <date>       0 0          
#> 23 cpf_id      <chr>        0 0          
#> 24 report_type <chr>        0 0          
#> 25 cand_name   <chr>        1 0.000000305
#> 26 office      <chr>      206 0.0000629  
#> 27 district    <chr>      206 0.0000629  
#> 28 comm_name   <chr>    89267 0.0272     
#> 29 comm_city   <chr>   915428 0.279      
#> 30 comm_state  <chr>   915638 0.279      
#> 31 comm_zip    <chr>   915488 0.279      
#> 32 category    <chr>        0 0          
#> 33 amendment   <lgl>        0 0
```

We can first `dplyr::coalesce()` the contributor and recipient variables
to only flag records missing *any* kind of name.

``` r
mac <- mac %>% 
  mutate(
    contrib_any = coalesce(first, last),
    recip_any = coalesce(comm_name, cand_name)
  ) %>% 
  flag_na(contrib_any, recip_any, date, amount)
```

The only variable missing from theses columns is the coalesced
contributor name.

``` r
mac %>% 
  filter(na_flag) %>% 
  select(contrib_any, recip_any, date, amount) %>% 
  col_stats(count_na)
#> # A tibble: 4 x 4
#>   col         class      n     p
#>   <chr>       <chr>  <int> <dbl>
#> 1 contrib_any <chr>  32370     1
#> 2 recip_any   <chr>      0     0
#> 3 date        <date>     0     0
#> 4 amount      <dbl>      0     0
```

For all records with a `cont_type` of “OTHER”, there is no given
contributor name. We can remove these flags.

``` r
prop_na(mac$contrib_any[which(mac$cont_type != "OTHER")])
#> [1] 0.0003633966
prop_na(mac$contrib_any[which(mac$cont_type == "OTHER")])
#> [1] 0.3176711
mac$na_flag[which(mac$cont_type == "OTHER")] <- FALSE
# very few remain
percent(mean(mac$na_flag), accuracy = 0.01)
#> [1] "0.04%"
```

### Duplicates

On a more powerful computer, we could also flag duplicate rows.

``` r
mac <- flag_dupes(mac, -id, -line, -guid, )
percent(mean(mac$dupe_flag), accuracy = 0.1)
```

``` r
mac %>%
  filter(dupe_flag) %>%
  select(date, last, amount, committee)
```

### Categorical

``` r
col_stats(mac, n_distinct)
#> # A tibble: 36 x 4
#>    col         class        n           p
#>    <chr>       <chr>    <int>       <dbl>
#>  1 id          <chr>  3276608 1          
#>  2 rpt_id      <chr>   151852 0.0463     
#>  3 line        <chr>  3276608 1          
#>  4 date        <date>    7017 0.00214    
#>  5 cont_type   <chr>        3 0.000000916
#>  6 first       <chr>   115600 0.0353     
#>  7 last        <chr>   238464 0.0728     
#>  8 address     <chr>   890959 0.272      
#>  9 city        <chr>    15845 0.00484    
#> 10 state       <chr>      305 0.0000931  
#> 11 zip         <chr>   129225 0.0394     
#> 12 occupation  <chr>    87574 0.0267     
#> 13 employer    <chr>   265231 0.0809     
#> 14 officer     <chr>     7587 0.00232    
#> 15 cont_id     <chr>     6776 0.00207    
#> 16 amount      <dbl>    30555 0.00933    
#> 17 tender      <chr>        8 0.00000244 
#> 18 guid        <chr>  3273342 0.999      
#> 19 rpt_year    <int>       24 0.00000732 
#> 20 filing_date <dttm>  151776 0.0463     
#> 21 start_date  <date>    1560 0.000476   
#> 22 end_date    <date>    6241 0.00190    
#> 23 cpf_id      <chr>     4342 0.00133    
#> 24 report_type <chr>       72 0.0000220  
#> 25 cand_name   <chr>     4565 0.00139    
#> 26 office      <chr>       59 0.0000180  
#> 27 district    <chr>      325 0.0000992  
#> 28 comm_name   <chr>     5812 0.00177    
#> 29 comm_city   <chr>      689 0.000210   
#> 30 comm_state  <chr>       33 0.0000101  
#> 31 comm_zip    <chr>      892 0.000272   
#> 32 category    <chr>        8 0.00000244 
#> 33 amendment   <lgl>        2 0.000000610
#> 34 contrib_any <chr>   156825 0.0479     
#> 35 recip_any   <chr>     5984 0.00183    
#> 36 na_flag     <lgl>        2 0.000000610
```

![](../plots/bar_type-1.png)<!-- -->

![](../plots/bar_method-1.png)<!-- -->

![](../plots/bar_report-1.png)<!-- -->

![](../plots/bar_category-1.png)<!-- -->

![](../plots/bar_amendment-1.png)<!-- -->

### Continuous

#### Amounts

``` r
summary(mac$amount)
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#>   -94729       25      100      382      200 12588840
mean(mac$amount <= 0)
#> [1] 0.007515394
```

![](../plots/amount_histogram-1.png)<!-- -->

#### Dates

The actual year a contribution was made sometimes differs from the year
in which it was reported. The later is identified int eh `rpt_year`
variable but we will create a new `year` variable from `date` using
`lubridate::year()`. This will more accurately identify the
contribution.

``` r
mac <- mutate(mac, year = year(date))
```

``` r
mac %>%
  count(year) %>%
  mutate(even = is_even(year)) %>% 
  ggplot(aes(x = year, y = n)) +
  geom_col(aes(fill = even)) +
  coord_cartesian(xlim = c(2000, 2020)) +
  scale_fill_brewer(palette = "Dark2") +
  scale_x_continuous(breaks = seq(2000, 2020, by = 2)) +
  theme(legend.position = "bottom") +
  labs(
    title = "Massachusetts Contributions by Year",
    caption = "Source: MA OCPF",
    fill = "Election Year",
    x = "Amount",
    y = "Count"
  )
```

![](../plots/unnamed-chunk-3-1.png)<!-- -->

![](../plots/month_grid-1.png)<!-- -->

``` r
min(mac$date)
#> [1] "1916-07-05"
sum(mac$year < 2001)
#> [1] 4
max(mac$date)
#> [1] "2097-05-24"
sum(mac$date > today())
#> [1] 9
```

``` r
mac %>%
  count(year) %>%
  mutate(even = is_even(year)) %>%
  ggplot(aes(x = year, y = n)) +
  geom_col(aes(fill = even)) +
  scale_fill_brewer(palette = "Dark2") +
  scale_y_continuous(labels = comma) +
  scale_x_continuous(breaks = seq(2000, 2020, by = 2)) +
  theme(legend.position = "bottom") +
  labs(
    title = "Massachusetts Contributions by Year",
    caption = "Source: MA OCPF",
    fill = "Election Year",
    x = "Year Made",
    y = "Count"
  )
```

![](../plots/year_bar-1.png)<!-- -->

## Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are taylor made to facilitate this process.

### Address

For the street `addresss` variable, the `campfin::normal_address()`
function will force consistence case, remove punctuation, and abbreviate
official USPS suffixes.

``` r
mac <- mac %>%
  mutate(
    address_norm = normal_address(
      address = address,
      abbs = usps_street,
      na_rep = TRUE
    )
  )
```

``` r
mac %>%
  select(contains("address")) %>%
  distinct() %>%
  sample_n(10)
#> # A tibble: 10 x 2
#>    address                         address_norm              
#>    <chr>                           <chr>                     
#>  1 Po Box 130251                   PO BOX 130251             
#>  2 97 Gulf Road                    97 GULF RD                
#>  3 9 GARDNER RD, 1                 9 GARDNER RD 1            
#>  4 506 Out of the Way Rd           506 OUT OF THE WAY RD     
#>  5 20 Marks Rd.                    20 MARKS RD               
#>  6 1563 Fall River Avenue          1563 FALL RIV AVE         
#>  7 128 Marlborough Street #3       128 MARLBOROUGH ST 3      
#>  8 135 Clarendon Street #10W       135 CLARENDON ST 10 W     
#>  9 30 Rockfeller Plaza, 31st Floor 30 ROCKFELLER PLZ 31 ST FL
#> 10 18 LEE STREET                   18 LEE ST
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valied *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
mac <- mac %>%
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  mac$zip,
  mac$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na  n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl>  <dbl>  <dbl>
#> 1 zip        0.860     129225  0.0442 439922 117699
#> 2 zip_norm   0.999      13769  0.0443   4543   1569
```

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

``` r
mac <- mac %>%
  mutate(
    state_norm = normal_state(
      state = state,
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = NULL
    )
  )
```

``` r
mac %>%
  filter(state != state_norm) %>%
  count(state, sort = TRUE)
#> # A tibble: 128 x 2
#>    state     n
#>    <chr> <int>
#>  1 ma     2057
#>  2 Ma     1679
#>  3 nh      213
#>  4 ri      166
#>  5 ct      165
#>  6 Fl      149
#>  7 ny      117
#>  8 ca      108
#>  9 Ca       89
#> 10 fl       80
#> # … with 118 more rows
```

``` r
progress_table(
  mac$state,
  mac$state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage      prop_in n_distinct prop_na n_out n_diff
#>   <chr>        <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 state        0.998        305  0.0212  6080    243
#> 2 state_norm   1.00         171  0.0213   433    110
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
mac <- mac %>%
  mutate(
    city_norm = normal_city(
      city = city,
      abbs = usps_city,
      states = c("MA", "DC", "MASSACHUSETTS"),
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

#### Swap

We can further improve normalization by comparing our normalized value
agaist the *expected* value for that record’s state abbreviation and ZIP
code. If the normalized value is either an abbreviation for or very
similar to the expected value, we can confidently swap those two.

``` r
mac <- mac %>%
  rename(city_raw = city) %>%
  left_join(
    y = zipcodes,
    by = c(
      "state_norm" = "state",
      "zip_norm" = "zip"
    )
  ) %>%
  rename(city_match = city) %>%
  mutate(
    match_abb = is_abbrev(city_norm, city_match),
    match_dist = str_dist(city_norm, city_match),
    city_swap = if_else(
      condition = !is.na(match_dist) & (match_abb | match_dist == 1),
      true = city_match,
      false = city_norm
    )
  ) %>%
  select(
    -city_match,
    -match_dist,
    -match_abb
  )
```

#### Refine

The \[OpenRefine\] algorithms can be used to group similar strings and
replace the less common versions with their most common counterpart.
This can greatly reduce inconsistency, but with low confidence; we will
only keep any refined strings that have a valid city/state/zip
combination.

``` r
good_refine <- mac %>%
  mutate(
    city_refine = city_swap %>%
      key_collision_merge() %>%
      n_gram_merge(numgram = 1)
  ) %>%
  filter(city_refine != city_swap) %>%
  inner_join(
    y = zipcodes,
    by = c(
      "city_refine" = "city",
      "state_norm" = "state",
      "zip_norm" = "zip"
    )
  ) %>% 
  select(
    id, 
    city_swap, 
    city_refine
  )
```

    #> # A tibble: 107 x 3
    #>    city_swap         city_refine         n
    #>    <chr>             <chr>           <int>
    #>  1 SO BOSTON         BOSTON            296
    #>  2 LITTLETON COMPTON LITTLE COMPTON     18
    #>  3 NO DARTHMOUTH     NORTH DARTMOUTH    17
    #>  4 CINCINATTI        CINCINNATI         16
    #>  5 NEW YORK NY       NEW YORK            8
    #>  6 NORTH HAMPTON     NORTHAMPTON         6
    #>  7 SAN FRANSICO      SAN FRANCISCO       6
    #>  8 HADLEY `          HADLEY              5
    #>  9 CENTER FALLS      CENTRAL FALLS       4
    #> 10 MARRIETA          MARIETTA            4
    #> # … with 97 more rows

Then we can join the refined values back to the database.

``` r
mac <- mac %>%
  left_join(good_refine) %>%
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

| stage        | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :----------- | -------: | ----------: | -------: | -----: | ------: |
| city\_raw)   |    0.983 |       11568 |    0.032 |  53463 |    5560 |
| city\_norm   |    0.988 |       10571 |    0.032 |  37737 |    4533 |
| city\_swap   |    0.992 |        8407 |    0.032 |  26189 |    2381 |
| city\_refine |    0.992 |        8312 |    0.032 |  25696 |    2287 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/progress_bar-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

``` r
progress %>%
  select(
    stage,
    all = n_distinct,
    bad = n_diff
  ) %>%
  mutate(good = all - bad) %>%
  pivot_longer(c("good", "bad")) %>%
  mutate(name = name == "good") %>%
  ggplot(aes(x = stage, y = value)) +
  geom_col(aes(fill = name)) +
  scale_fill_brewer(palette = "Dark2", direction = -1) +
  scale_y_continuous(labels = comma) +
  theme(legend.position = "bottom") +
  labs(
    title = "Massachusetts City Normalization Progress",
    subtitle = "Distinct values, valid and invalid",
    x = "Stage",
    y = "Percent Valid",
    fill = "Valid"
  )
```

![](../plots/distinct_bar-1.png)<!-- -->

## Conclude

``` r
mac <- mac %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean"))
```

``` r
glimpse(sample_n(mac, 20))
#> Rows: 20
#> Columns: 41
#> $ id            <chr> "7183828", "11825706", "7986481", "13732961", "6406880", "5595157", "87909…
#> $ rpt_id        <chr> "96127", "593426", "135568", "733674", "52239", "14087", "193881", "19760"…
#> $ line          <chr> "7183828", "11825706", "7986481", "13732961", "6406880", "5595157", "87909…
#> $ date          <date> 2008-02-29, 2016-12-07, 2010-04-07, 2020-03-09, 2006-07-20, 2002-10-01, 2…
#> $ cont_type     <chr> "Individual", "Individual", "Individual", "Individual", "Individual", "Ind…
#> $ first         <chr> "FRANCIS X", "Christopher C", "Richard", "William", "James", "Harry R", "J…
#> $ last          <chr> "BELLOTTI", "Reed", "Peterson", "Thibeault", "Abreu", "Collings", "Salema"…
#> $ address       <chr> "120 HILLSIDE AVE", "6 Bass River Road", "20 Old Wharf Waye", "85-87 Bosto…
#> $ city_raw      <chr> "WOLLASTON", "Beverly", "Marshfield", "Everett", "Fall River", "Boston", "…
#> $ state         <chr> "MA", "MA", "MA", "MA", "MA", "MA", "MA", "MA", "MA", "MA", "MA", "MA", "M…
#> $ zip           <chr> "02170", "01915", "02050", "02149", "02723", "02116", "01056", "01752", "0…
#> $ occupation    <chr> "LOBBYIST", "SPLICE-SERVICE TECHNICIAN", NA, "Owner", "Social Worker", NA,…
#> $ employer      <chr> "LOBBYIST", "Verizon New England Inc.", NA, "Great Northern Demolition", "…
#> $ officer       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ cont_id       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ amount        <dbl> 100.00, 0.25, 25.00, 1000.00, 200.00, 150.00, 200.00, 100.00, 2.00, 50.00,…
#> $ tender        <chr> "Unknown", "Check", "Unknown", "Check", "Unknown", "Unknown", "Check", "Un…
#> $ guid          <chr> "{8e8599fa-3bb6-4093-d287-4f7c60389958}", "{8d900b05-b7bc-e611-e280-030050…
#> $ rpt_year      <int> 2008, 2016, 2010, 2020, 2006, 2002, 2014, 2004, 2019, 2017, 2010, 2017, 20…
#> $ filing_date   <dttm> 2009-06-26 14:59:36, 2016-12-07 15:00:00, 2011-05-31 12:49:05, 2020-03-09…
#> $ start_date    <date> 2008-01-01, NA, 2010-01-01, NA, 2006-01-01, 2002-08-31, NA, 2004-01-01, N…
#> $ end_date      <date> 2008-08-29, 2016-12-07, 2010-08-27, 2020-03-09, 2006-09-01, 2002-10-18, 2…
#> $ cpf_id        <chr> "13651", "80530", "11677", "15031", "10106", "12530", "12894", "13065", "8…
#> $ report_type   <chr> "Pre-primary Report (ND)", "Deposit Report", "Pre-primary Report (ND)", "D…
#> $ cand_name     <chr> "Paul J. Donato", "Int'l Brotherhood of Electrical Workers Local Union 222…
#> $ office        <chr> "House", "N/A", "Senate", "Senate", "House", "House", "Municipal", "House"…
#> $ district      <chr> "35th Middlesex", "No office", "Plymouth & Norfolk", "Middlesex & Suffolk"…
#> $ comm_name     <chr> "Donato Committee", "Int'l Brotherhood of Electrical Workers Local Union 2…
#> $ comm_city     <chr> "Medford", "Dorchester", "Hingham", "Boston", "Fall River", "Boston", NA, …
#> $ comm_state    <chr> "MA", "MA", "MA", "MA", "MA", "MA", NA, "MA", "MA", NA, NA, "MA", NA, "MA"…
#> $ comm_zip      <chr> "02155", "02124", "02043", "02110", "02724", "02101", NA, "01752", "01752"…
#> $ category      <chr> "N", "P", "N", "N", "N", "N", "D", "N", "P", "D", "D", "N", "D", "B", "N",…
#> $ amendment     <lgl> TRUE, FALSE, TRUE, FALSE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, T…
#> $ contrib_any   <chr> "FRANCIS X", "Christopher C", "Richard", "William", "James", "Harry R", "J…
#> $ recip_any     <chr> "Donato Committee", "Int'l Brotherhood of Electrical Workers Local Union 2…
#> $ na_flag       <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ year          <dbl> 2008, 2016, 2010, 2020, 2006, 2002, 2014, 2004, 2019, 2017, 2010, 2017, 20…
#> $ address_clean <chr> "120 HILLSIDE AVE", "6 BASS RIV RD", "20 OLD WHARF WAYE", "8587 BOSTON ST"…
#> $ zip_clean     <chr> "02170", "01915", "02050", "02149", "02723", "02116", "01056", "01752", "0…
#> $ state_clean   <chr> "MA", "MA", "MA", "MA", "MA", "MA", "MA", "MA", "MA", "MA", "MA", "MA", "M…
#> $ city_clean    <chr> "WOLLASTON", "BEVERLY", "MARSHFIELD", "EVERETT", "FALL RIVER", "BOSTON", "…
```

1.  There are 3,276,608 records in the database.
2.  There are 0 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 1,155 records missing a recipient or date.
5.  Consistency in goegraphic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
clean_dir <- dir_create(here("ma", "contribs", "data", "clean"))
clean_path <- path(clean_dir, "ma_contribs_clean.csv")
write_csv(mac, clean_path, na = "")
file_size(clean_path)
#> 1.28G
guess_encoding(clean_path)
#> # A tibble: 1 x 2
#>   encoding confidence
#>   <chr>         <dbl>
#> 1 ASCII             1
```
