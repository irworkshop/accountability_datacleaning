Minnesota Contributions
================
Kiernan Nicholls
Fri Jan 8 12:24:13 2021

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
      - [Download](#download)
      - [Read](#read)
  - [Explore](#explore)
      - [Missing](#missing)
      - [Duplicates](#duplicates)
      - [Categorical](#categorical)
      - [Continuous](#continuous)
  - [Wrangle](#wrangle)
  - [Conclude](#conclude)
  - [Export](#export)
  - [Upload](#upload)
  - [Dictionary](#dictionary)

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
here::i_am("mn/contribs/docs/mn_contribs_diary.Rmd")
```

## Data

The data is obtained from the [Minnesota Campaign Finance Board
(CFB)](https://cfb.mn.gov/).

> The Campaign Finance and Public Disclosure Board was established by
> the state legislature in 1974 and is charged with the administration
> of Minnesota Statutes, Chapter 10A, the Campaign Finance and Public
> Disclosure Act, as well as portions of Chapter 211B, the Fair Campaign
> Practices act.

> The Board’s four major programs are campaign finance registration and
> disclosure, public subsidy administration, lobbyist registration and
> disclosure, and economic interest disclosure by public officials. The
> Board has six members, appointed by the Governor on a bi-partisan
> basis for staggered four-year terms. The appointments must be
> confirmed by a three-fifths vote of the members of each house of the
> legislature.

The CFB provides [direct data
download](https://cfb.mn.gov/reports-and-data/self-help/data-downloads/campaign-finance/)
for all campaign finance data.

## Import

To import the file for processing, we will first have save the file
locally and then read the flat file.

### Download

We can download the file to disk with the `httr::GET()` and
`httr::write_disk()` functions. These functions make the HTTP requests
one would make when clicking on the download link on the CFB page.

``` r
raw_dir <- dir_create(here("mn", "contribs", "data", "raw"))
raw_file <- path(raw_dir, "all_contribs.csv")
if (!file_exists(raw_file)) {
  GET(
    url = "https://cfb.mn.gov/",
    path = c("reports-and-data", "self-help", "data-downloads", "campaign-finance"),
    query = list(download = -2113865252),
    write_disk(raw_file, overwrite = TRUE),
  )
}
```

### Read

We can read this flat file with the `vroom::vroom()` function.

``` r
mnc <- vroom(
  file = raw_file,
  .name_repair = make_clean_names,
  col_types = cols(
    .default = col_character(),
    `Recipient reg num` = col_integer(),
    Amount = col_double(),
    `Receipt date` = col_date_usa(),
    Year = col_integer(),
    `Contributor ID` = col_integer(),
    `Contrib Reg Num` = col_integer(),
    `Contrib employer ID` = col_integer()
  )
)
```

## Explore

The file has 215,780 records of 16 variables.

``` r
head(mnc)
#> # A tibble: 6 x 16
#>   rec_num rec_name rec_type rec_sub amount date        year con_name con_id con_reg con_type receipt in_kind
#>     <int> <chr>    <chr>    <chr>    <dbl> <date>     <int> <chr>     <int>   <int> <chr>    <chr>   <lgl>  
#> 1   16008 Faust, … PCC      <NA>        50 2015-02-17  2015 Rahm, J…  82091      NA Individ… Contri… FALSE  
#> 2   16777 Utz, Ti… PCC      <NA>       150 2015-05-15  2015 Utz, Ti…   1510      NA Self     Contri… FALSE  
#> 3   17931 Hassan,… PCC      <NA>       300 2016-04-11  2016 Ahmed, …  85772      NA Individ… Contri… FALSE  
#> 4   17931 Hassan,… PCC      <NA>       300 2016-06-06  2016 Hersi, …  85774      NA Individ… Contri… FALSE  
#> 5   40910 Austin … PCF      PC         300 2016-09-20  2016 Forstne…  46231      NA Individ… Contri… FALSE  
#> 6   18043 Abraham… PCC      <NA>       800 2016-09-19  2016 Nobles …   5712   20110 Party U… Contri… FALSE  
#> # … with 3 more variables: in_kind_desc <chr>, con_zip <chr>, con_emp_name <chr>
tail(mnc)
#> # A tibble: 6 x 16
#>   rec_num rec_name rec_type rec_sub amount date        year con_name con_id con_reg con_type receipt in_kind
#>     <int> <chr>    <chr>    <chr>    <dbl> <date>     <int> <chr>     <int>   <int> <chr>    <chr>   <lgl>  
#> 1   17672 Youakim… PCC      <NA>       250 2016-07-26  2016 Domholt…  84414      NA Individ… Contri… FALSE  
#> 2   17672 Youakim… PCC      <NA>       250 2019-12-05  2019 MN Cham…  89684   70001 Politic… Contri… FALSE  
#> 3   17672 Youakim… PCC      <NA>      1000 2020-01-25  2020 Calvert… 100885   18032 Candida… Contri… FALSE  
#> 4   17672 Youakim… PCC      <NA>       450 2016-09-08  2016 MN DFL … 428793   20003 Party U… Contri… TRUE   
#> 5   18553 Zurick,… PCC      <NA>        50 2020-05-13  2020 Reyes, …  97935      NA Individ… Contri… FALSE  
#> 6   18553 Zurick,… PCC      <NA>       200 2020-07-20  2020 Reyes, …  97935      NA Individ… Contri… FALSE  
#> # … with 3 more variables: in_kind_desc <chr>, con_zip <chr>, con_emp_name <chr>
glimpse(sample_n(mnc, 20))
#> Rows: 20
#> Columns: 16
#> $ rec_num      <int> 30331, 17641, 17373, 41256, 30116, 30628, 30556, 30163, 30617, 20222, 40714, 30016, 18135, 41256…
#> $ rec_name     <chr> "IBEW - COPE", "Johnson, Jeff R Gov Committee", "Westrom, Torrey N Senate Committee", "Automobil…
#> $ rec_type     <chr> "PCF", "PCC", "PCC", "PCF", "PCF", "PCF", "PCF", "PCF", "PCF", "PTU", "PCF", "PCF", "PCC", "PCF"…
#> $ rec_sub      <chr> "PF", NA, NA, "PC", "PF", "IEF", "PFN", "PF", "PF", NA, "PC", "PF", NA, "PC", "CAU", NA, "CAU", …
#> $ amount       <dbl> 25.00, 50.00, 250.00, 85.00, 45.83, 1000.00, 500.00, 66.67, 700.00, 55.00, 20.00, 1165.71, 25.00…
#> $ date         <date> 2015-07-20, 2018-05-03, 2016-07-18, 2020-06-19, 2016-11-02, 2018-10-11, 2016-09-15, 2015-06-22,…
#> $ year         <int> 2015, 2018, 2016, 2020, 2016, 2018, 2016, 2015, 2015, 2017, 2015, 2016, 2018, 2020, 2016, 2016, …
#> $ con_name     <chr> "Murray, Arthur D", "Prokott, Michele R", "Fiedler, Jean", "DIVERSTURNER, STACEY", "Jutsen, Mark…
#> $ con_id       <int> 70239, 135613, 57967, 376395, 60427, 535, 55220, 72432, 79086, 53245, 11263, 8297, 140460, 37644…
#> $ con_reg      <int> NA, NA, NA, NA, NA, 15667, NA, NA, NA, NA, 3120, 80031, NA, NA, 30019, 20784, 16703, 20783, NA, …
#> $ con_type     <chr> "Individual", "Individual", "Individual", "Individual", "Individual", "Candidate Committee", "In…
#> $ receipt      <chr> "Contribution", "Contribution", "Contribution", "Contribution", "Contribution", "Contribution", …
#> $ in_kind      <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
#> $ in_kind_desc <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
#> $ con_zip      <chr> "95687", "55449", "56378", "33547", "55402", "55408", "55101", "55402", "55102", "55305", "55425…
#> $ con_emp_name <chr> "IBEW", "Self employed business", "Self employed Agriculture", "Meemic", "Self employed Partner …
```

### Missing

We should flag any variable missing the key variables needed to identify
a unique contribution.

``` r
col_stats(mnc, count_na)
#> # A tibble: 16 x 4
#>    col          class       n         p
#>    <chr>        <chr>   <int>     <dbl>
#>  1 rec_num      <int>       0 0        
#>  2 rec_name     <chr>       0 0        
#>  3 rec_type     <chr>       0 0        
#>  4 rec_sub      <chr>  100010 0.463    
#>  5 amount       <dbl>       0 0        
#>  6 date         <date>      0 0        
#>  7 year         <int>       0 0        
#>  8 con_name     <chr>     142 0.000658 
#>  9 con_id       <int>     142 0.000658 
#> 10 con_reg      <int>  172908 0.801    
#> 11 con_type     <chr>      19 0.0000881
#> 12 receipt      <chr>       0 0        
#> 13 in_kind      <lgl>       0 0        
#> 14 in_kind_desc <chr>  208444 0.966    
#> 15 con_zip      <chr>    2031 0.00941  
#> 16 con_emp_name <chr>   46114 0.214
```

``` r
mnc <- mnc %>% flag_na(rec_name, con_name, date, amount)
sum(mnc$na_flag)
#> [1] 142
```

``` r
mnc %>% 
  filter(na_flag) %>% 
  select(rec_name, con_name, date, amount) %>% 
  sample_frac()
#> # A tibble: 142 x 4
#>    rec_name                                con_name date        amount
#>    <chr>                                   <chr>    <date>       <dbl>
#>  1 IBEW Local 292 Political Education Fund <NA>     2019-06-11   56.7 
#>  2 IBEW Local 292 Political Education Fund <NA>     2019-05-02 9547.  
#>  3 IBEW Local 292 Political Education Fund <NA>     2019-07-31   26.1 
#>  4 IBEW Local 292 Political Education Fund <NA>     2019-03-19    9.21
#>  5 IBEW Local 292 Political Education Fund <NA>     2019-03-20   23.7 
#>  6 IBEW Local 292 Political Education Fund <NA>     2019-11-17  297.  
#>  7 IBEW Local 292 Political Education Fund <NA>     2020-02-29  154.  
#>  8 IBEW Local 292 Political Education Fund <NA>     2019-03-07    1.97
#>  9 IBEW Local 292 Political Education Fund <NA>     2019-01-06   56.8 
#> 10 IBEW Local 292 Political Education Fund <NA>     2019-07-29   98.7 
#> # … with 132 more rows
```

### Duplicates

Similarly, we can flag all records that are duplicated at least one
other time.

``` r
mnc <- flag_dupes(mnc, everything())
sum(mnc$dupe_flag)
#> [1] 3063
```

``` r
mnc %>% 
  filter(dupe_flag) %>% 
  select(rec_name, con_name, date, amount) %>% 
  arrange(rec_name)
#> # A tibble: 3,063 x 4
#>    rec_name                 con_name         date       amount
#>    <chr>                    <chr>            <date>      <dbl>
#>  1 14th Senate District RPM Pederson, John C 2015-01-24     40
#>  2 14th Senate District RPM Pederson, John C 2015-01-24     40
#>  3 14th Senate District RPM Schlangen, Beth  2017-01-13     40
#>  4 14th Senate District RPM Schlangen, Beth  2017-01-13     40
#>  5 16th Senate District DFL Kriegl, Josef A  2018-03-17    100
#>  6 16th Senate District DFL Kriegl, Josef A  2018-03-17    100
#>  7 16th Senate District DFL Hess, Deb        2017-03-18     70
#>  8 16th Senate District DFL Hess, Deb        2017-03-18     70
#>  9 19th Senate District DFL Dimock, Rebecca  2018-04-13     50
#> 10 19th Senate District DFL Filipovitch, A J 2018-04-13     25
#> # … with 3,053 more rows
```

### Categorical

We can explore the distribution of categorical variables.

``` r
col_stats(mnc, n_distinct)
#> # A tibble: 18 x 4
#>    col          class      n          p
#>    <chr>        <chr>  <int>      <dbl>
#>  1 rec_num      <int>   1667 0.00773   
#>  2 rec_name     <chr>   1658 0.00768   
#>  3 rec_type     <chr>      3 0.0000139 
#>  4 rec_sub      <chr>      9 0.0000417 
#>  5 amount       <dbl>  11372 0.0527    
#>  6 date         <date>  2119 0.00982   
#>  7 year         <int>      6 0.0000278 
#>  8 con_name     <chr>  38366 0.178     
#>  9 con_id       <int>  40043 0.186     
#> 10 con_reg      <int>   1984 0.00919   
#> 11 con_type     <chr>     10 0.0000463 
#> 12 receipt      <chr>      5 0.0000232 
#> 13 in_kind      <lgl>      2 0.00000927
#> 14 in_kind_desc <chr>   4707 0.0218    
#> 15 con_zip      <chr>   3871 0.0179    
#> 16 con_emp_name <chr>  19734 0.0915    
#> 17 na_flag      <lgl>      2 0.00000927
#> 18 dupe_flag    <lgl>      2 0.00000927
```

![](../plots/bar_rec_type-1.png)<!-- -->

![](../plots/bar_rec_sub-1.png)<!-- -->

![](../plots/bar_con_type-1.png)<!-- -->

    #> # A tibble: 5 x 2
    #>   receipt                   n
    #>   <chr>                 <int>
    #> 1 Contribution         213376
    #> 2 Loan Payable            234
    #> 3 Loan Receivable           5
    #> 4 Miscellaneous Income   2139
    #> 5 MiscellaneousIncome      26
    #> # A tibble: 2 x 2
    #>   in_kind      n
    #>   <lgl>    <int>
    #> 1 FALSE   208148
    #> 2 TRUE      7632

### Continuous

The range of continuous variables should be checked to identify any
egregious outliers or strange distributions.

#### Amounts

The range of the `amount` variable is reasonable, with very few
contributions at or less than zero dollars.

``` r
summary(mnc$amount)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>    -350      50     200    1567     500 1500000
sum(mnc$amount <= 0)
#> [1] 46
```

As we’d expect, the contribution `amount` are log-normally distributed
around the median value of $200.

![](../plots/hist_amount-1.png)<!-- -->

#### Dates

Since the `year` variable already exists, there is no need to create
one. Any of these which do not match seems to fall near beginning of the
year.

``` r
mean(mnc$year == year(mnc$date))
#> [1] 0.9986282
mnc %>% 
  filter(year != year(date)) %>% 
  count(month = month(date))
#> # A tibble: 5 x 2
#>   month     n
#>   <dbl> <int>
#> 1     1   174
#> 2     2    97
#> 3     3    21
#> 4     4     2
#> 5    12     2
```

No further cleaning of the date variable is needed.

``` r
min(mnc$date)
#> [1] "2015-01-01"
sum(mnc$year < 2000)
#> [1] 0
max(mnc$date)
#> [1] "2020-10-19"
sum(mnc$date > today())
#> [1] 0
```

![](../plots/bar_year-1.png)<!-- -->

## Wrangle

The database does *not* contain the full range of geographic variables
we’d expect. There is only a ZIP code. We can use this `zip` variable to
add the `city` and `state` variables, but not an `address`. These
variables will *not* be accurate to the data provided by the state.

``` r
mnc <- mnc %>% 
  left_join(zipcodes, by = c("con_zip" = "zip")) %>% 
  rename_at(vars(19:20), ~str_replace(., "(.*)$", "cont_\\1_match"))
```

## Conclude

``` r
glimpse(sample_n(mnc, 100))
#> Rows: 100
#> Columns: 20
#> $ rec_num          <int> 20010, 30116, 20011, 70004, 30331, 18237, 17633, 18209, 18125, 30331, 41023, 18336, 18158, 2…
#> $ rec_name         <chr> "HRCC", "Dorsey Political Fund", "DFL Senate Caucus", "MN Business Partnership PAC", "IBEW -…
#> $ rec_type         <chr> "PTU", "PCF", "PTU", "PCF", "PCF", "PCC", "PCC", "PCC", "PCC", "PCF", "PCF", "PCC", "PCC", "…
#> $ rec_sub          <chr> "CAU", "PF", "CAU", "PCN", "PF", NA, NA, NA, NA, "PF", "PC", NA, NA, NA, NA, NA, "PC", "PC",…
#> $ amount           <dbl> 300.00, 24.84, 100.00, 3500.00, 25.00, 35.98, 300.00, 250.00, 250.00, 78.83, 100.00, 250.00,…
#> $ date             <date> 2019-01-07, 2016-12-09, 2020-09-24, 2017-07-25, 2015-09-18, 2018-08-05, 2016-07-05, 2017-12…
#> $ year             <int> 2019, 2016, 2020, 2017, 2015, 2018, 2016, 2017, 2019, 2015, 2018, 2019, 2018, 2016, 2018, 20…
#> $ con_name         <chr> "Ottertail Power PAC", "Genereux, L J", "Brooker, Charlotte Ann", "Black, Archie", "Conway, …
#> $ con_id           <int> 7579, 60388, 43527, 73330, 90170, 135782, 84120, 36718, 8589, 78253, 33725, 151652, 131181, …
#> $ con_reg          <int> 40894, NA, NA, NA, NA, NA, NA, NA, 297, NA, NA, NA, NA, NA, 20105, NA, NA, NA, NA, 70004, NA…
#> $ con_type         <chr> "Political Committee/Fund", "Individual", "Individual", "Individual", "Individual", "Self", …
#> $ receipt          <chr> "Contribution", "Contribution", "Contribution", "Contribution", "Contribution", "Contributio…
#> $ in_kind          <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FA…
#> $ in_kind_desc     <chr> NA, NA, NA, NA, NA, "Printer Ink Cartridges", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ con_zip          <chr> "56537", "55402", "55109", "55422", "55344", "55337", "56058", "55122", "55413", "92868", "5…
#> $ con_emp_name     <chr> NA, "Self employed Partner at law firm of Dorsey & Whit", "Retired", "SPS Commerce, Inc.", "…
#> $ na_flag          <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ dupe_flag        <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ cont_city_match  <chr> "FERGUS FALLS", "MINNEAPOLIS", "SAINT PAUL", "MINNEAPOLIS", "EDEN PRAIRIE", "BURNSVILLE", "L…
#> $ cont_state_match <chr> "MN", "MN", "MN", "MN", "MN", "MN", "MN", "MN", "MN", "CA", "MN", "LA", "MN", "MN", "MN", "M…
```

1.  There are 215,780 records in the database.
2.  There are 3,063 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 142 records missing ….
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("mn", "contribs", "data", "clean"))
clean_path <- path(clean_dir, "mn_contribs_clean.csv")
write_csv(mnc, clean_path, na = "")
(clean_size <- file_size(clean_path))
#> 35.1M
```

## Upload

We can use the `aws.s3::put_object()` to upload the text file to the IRW
server.

``` r
aws_path <- path("csv", basename(clean_path))
if (!object_exists(aws_path, "publicaccountability")) {
  put_object(
    file = clean_path,
    object = aws_path, 
    bucket = "publicaccountability",
    acl = "public-read",
    show_progress = TRUE,
    multipart = TRUE
  )
}
aws_head <- head_object(aws_path, "publicaccountability")
(aws_size <- as_fs_bytes(attr(aws_head, "content-length")))
unname(aws_size == clean_size)
```

## Dictionary

The following table describes the variables in our final exported file:

| Column             | Type        | Definition                                 |
| :----------------- | :---------- | :----------------------------------------- |
| `rec_num`          | `integer`   | Recipient ID                               |
| `rec_name`         | `character` | **Recipient name**                         |
| `rec_type`         | `character` | Recipeint type                             |
| `rec_sub`          | `character` | Recipient sub-type                         |
| `amount`           | `double`    | **Amount** of contribution                 |
| `date`             | `double`    | **Date** contribution made                 |
| `year`             | `integer`   | **Year** contribution made                 |
| `con_name`         | `character` | **Contributor name**                       |
| `con_id`           | `integer`   | Contributor ID                             |
| `con_reg`          | `integer`   | Contributor registration                   |
| `con_type`         | `character` | Contributor type                           |
| `receipt`          | `character` | Receipt type                               |
| `in_kind`          | `logical`   | Flag indicating in-kind contribution       |
| `in_kind_desc`     | `character` | Description of in-kind contribution        |
| `con_zip`          | `character` | Contributor ZIP code                       |
| `con_emp_name`     | `character` | Contributor employer name                  |
| `na_flag`          | `logical`   | Flag indicating missing value              |
| `dupe_flag`        | `logical`   | Flag indicating duplicate record           |
| `cont_city_match`  | `character` | City name from *matched* ZIP code          |
| `cont_state_match` | `character` | State abbreviation from *matched* ZIP code |
