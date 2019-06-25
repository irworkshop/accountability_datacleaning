---
title: "Data Diary"
subtitle: "Washington Contributions"
author: "Kiernan Nicholls"
date: "2019-05-23 17:47:18"
output:
  html_document: 
    df_print: tibble
    fig_caption: yes
    highlight: tango
    keep_md: yes
    max.print: 32
    toc: yes
    toc_float: no
editor_options: 
  chunk_output_type: console
---



## Objectives

1. How many records are in the database?
1. Check for duplicates
1. Check ranges
1. Is there anything blank or missing?
1. Check for consistency issues
1. Create a five-digit ZIP Code called ZIP5
1. Create a YEAR field from the transaction date
1. For campaign donation data, make sure there is both a donor AND recipient

## Data

Retrieved from [data.wa.gov][01], uploaded by the 
[Public Disclosure Commission][02]. Created December 16, 2016. Updated on 
May 23, 2019.

[01]: https://data.wa.gov/Politics/Contributions-to-Candidates-and-Political-Committe/kv7h-kjye/data
[02]: https://www.pdc.wa.gov/

### About

> This dataset contains cash and in-kind contributions, (including unpaid loans) made to Washington
State Candidates and Political Committees for the last 10 years as reported to the PDC on forms C3,
C4, Schedule C and their electronic filing equivalents. It does not include loans which have been
paid or forgiven, pledges or any expenditures.
> 
> For candidates, the number of years is determined by the year of the election, not necessarily
the year the contribution was reported. For political committees, the number of years is determined
by the calendar year of the reporting period.
>
> Candidates and political committees choosing to file under "mini reporting" are not included in
this dataset. See WAC 390-16-105 for information regarding eligibility.
>
> This dataset is a best-effort by the PDC to provide a complete set of records as described
herewith and may contain incomplete or incorrect information. The PDC provides access to the
original reports for the purpose of record verification.
>
> Descriptions attached to this dataset do not constitute legal definitions; please consult RCW
42.17A and WAC Title 390 for legal definitions and additional information political finance
disclosure requirements.
>
> CONDITION OF RELEASE: This publication constitutes a list of individuals prepared by the
Washington State Public Disclosure Commission and may not be used for commercial purposes. This
list is provided on the condition and with the understanding that the persons receiving it agree to
this statutorily imposed limitation on its use. See RCW 42.56.070(9) and AGO 1975 No. 15.

### Variables

The Public Disclosure Commission [provides definitions][03] for each of the variables in the data
set:

* `id`: Corresponds to a single record. Uniquely identifies a single row When combined with the
origin value.
* `report_number`: Used for tracking the individual form. Unique to the report it represents.
* `origin`: The form, schedule or section where the record was reported.
* `filier_id`: The unique id assigned to a candidate or political committee. Consistent across
election years.
* `type`: Indicates if this record is for a candidate or a political committee
* `first_name`: First name, as reported by the filer. Potentially inconsistent.
* `last_name`: Last name or full name of a filing entity that is registered under one name.
* `office`: The office sought by the candidate
* `legislative_district`: The Washington State legislative district
* `position`: The position associated with an office with multiple seats.
* `party`: "Major party" declaration
* `ballot_number`: Initiative ballot number is assigned by the Secretary of State
* `for_or_against`: Ballot initiative committees either supports or opposes
* `jurisdiction`: The political jurisdiction associated with the office of a candidate
* `election_year`: Election year for candidates and single election committees. Reporting year for
continuing committees.
* `amount`: The amount of the cash or in-kind contribution (or adjustment).
* `cash_or_in_kind`: What kind of contribution, if known.
* `receipt_date`: The date that the contribution was received.
* `description`: The reported description of the transaction. This field does not apply to cash
contributions
* `primary_general`: Candidates must specify whether a contribution is designated for the primary
or the general election.
* `code`: Type of entity that made the contribution.
* `contributor_name`:	The name of the individual _or_ organization making the contribution as
reported (where total >$25).
* `contributor_address`: The street address of the individual or organization making the
contribution.
* `contributor_city`: The city of the individual or organization making the contribution.
* `contributor_state`: The state of the individual or organization making the contribution.
* `contributor_zip`: The US zip code of the individual or organization making the contribution.
* `contributor_occupation`: The occupation of the (individual) contributor (where total >$100).
* `contributor_employer_name`: The name of the contributor's employer.
* `contributor_employer_city`: City of the contributor's employer.
* `contributor_employer_state`: State of the contributor's employer.
* `url`: A link to a PDF version of the original report as it was filed to the PDC.
* `contributor_location`: The geocoded location of the contributor as reported. Quality dependent
on how many of the address fields are available and is calculated using a third-party service.

[03]: https://data.wa.gov/Politics/Contributions-to-Candidates-and-Political-Committe/kv7h-kjye

## Packages

This data set will be collected, explored, and saved using the free and open R packages below.


```r
# install.packages("pacman")
pacman::p_load(
  tidyverse, 
  lubridate, 
  magrittr, 
  janitor, 
  zipcode, 
  here
)
```

## Read

The source file is updated, daily so reproducing findings precisely is unlikely. Code here has been
generalized as much as possible. The data in this document was retrieved the day it was created
(see above).

If _today's_ file exists in the project directory, read it into R; otherwise, retrieve the file
directly from the Washington State website. This is done using `readr::read_csv()`

The `receipt_date` strings are converted from their original format (MM/DD/YYYY) to ISO-8601 format
(YYYY-MM-DD) as to be handled as date objects in R. The contribution `amount` values are read as
doubles. All other variables are handled as character strings.


```r
# create path to file
wa_file <- here("wa_contribs", "data", "Contributions_to_Candidates_and_Political_Committees.csv")
# if a recent version exists where it should, read it
if (file.exists(wa_file) & as_date(file.mtime(wa_file)) == today()) {
  wa <- read_csv(
    file = wa_file,
    na = c("", "NA", "N/A"),
    col_types = cols(
      .default = col_character(),
      amount = col_double(),
      receipt_date = col_date(format = "%m/%d/%Y")
    )
  )
} else { # otherwise read it from the internet
  wa <- read_csv(
    file = "https://data.wa.gov/api/views/kv7h-kjye/rows.csv?accessType=DOWNLOAD",
    na = c("", "NA", "N/A"),
    col_types = cols(
      .default = col_character(),
      amount = col_double(),
      receipt_date = col_date(format = "%m/%d/%Y")
    )
  )
}
```

## Explore

There are 4224421 records of 37 variables. There are no duplicate rows.
However, without the unique `id` variable, there are `nrow(wa) - nrow(distinct(select(wa, -id)))` 
rows with repeated information.


```r
glimpse(wa)
```

```
## Observations: 4,224,421
## Variables: 37
## $ id                         <chr> "1807811.rcpt", "1807812.rcpt", "1807813.rcpt", "1807814.rcpt…
## $ report_number              <chr> "100218448", "100218449", "100218449", "100218449", "10021844…
## $ origin                     <chr> "C3", "C3", "C3", "C3", "C3", "C3", "C3", "C3", "C3", "C3", "…
## $ filer_id                   <chr> "WASHMH 006", "NOBLP  005", "NOBLP  005", "NOBLP  005", "NOBL…
## $ type                       <chr> "Political Committee", "Candidate", "Candidate", "Candidate",…
## $ filer_name                 <chr> "NW HOUSING ASSN PAC", "NOBLE PHILLIP D", "NOBLE PHILLIP D", …
## $ first_name                 <chr> NA, "PHILLIP", "PHILLIP", "PHILLIP", "PHILLIP", "PHILLIP", "P…
## $ middle_initial             <chr> NA, "D", "D", "D", "D", "D", "D", "D", NA, NA, NA, NA, "C", "…
## $ last_name                  <chr> "NORTHWEST HOUSING ASSN PAC", "NOBLE", "NOBLE", "NOBLE", "NOB…
## $ office                     <chr> NA, "CITY COUNCIL MEMBER", "CITY COUNCIL MEMBER", "CITY COUNC…
## $ legislative_district       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
## $ position                   <chr> NA, "07", "07", "07", "07", "07", "07", "07", NA, NA, NA, NA,…
## $ party                      <chr> NA, "NON PARTISAN", "NON PARTISAN", "NON PARTISAN", "NON PART…
## $ ballot_number              <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
## $ for_or_against             <chr> NA, NA, NA, NA, NA, NA, NA, NA, "For", "For", "For", "For", N…
## $ jurisdiction               <chr> NA, "CITY OF BELLEVUE", "CITY OF BELLEVUE", "CITY OF BELLEVUE…
## $ jurisdiction_county        <chr> NA, "KING", "KING", "KING", "KING", "KING", "KING", "KING", N…
## $ jurisdiction_type          <chr> NA, "Local", "Local", "Local", "Local", "Local", "Local", "Lo…
## $ election_year              <chr> "2007", "2007", "2007", "2007", "2007", "2007", "2007", "2007…
## $ amount                     <dbl> 21.00, 700.00, 5000.00, 250.00, 50.00, 100.00, 50.00, 50.00, …
## $ cash_or_in_kind            <chr> "Cash", "Cash", "Cash", "Cash", "Cash", "Cash", "Cash", "Cash…
## $ receipt_date               <date> 2007-07-11, 2007-07-17, 2007-07-17, 2007-07-17, 2007-07-17, …
## $ description                <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
## $ memo                       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
## $ primary_general            <chr> "Full election cycle", "Full election cycle", "Full election …
## $ code                       <chr> "Other", "Other", "Other", "Individual", "Individual", "Indiv…
## $ contributor_name           <chr> "PALM HARBOR HOMES", "RHA PAC", "HELSELL FETTERMAN LLP", "KIN…
## $ contributor_address        <chr> "3737 PALM HARBOR DRIVE", "PO BOX 99447", "1001 FOURTH AVENUE…
## $ contributor_city           <chr> "MILLERSBURG", "SEATTLE", "SEATTLE", "REDMOND", "BELLEVUE", "…
## $ contributor_state          <chr> "OR", "WA", "WA", "WA", "WA", "WA", "WA", "WA", "WA", "WA", "…
## $ contributor_zip            <chr> "97321", "98199", "98111", "98052", "98004", "98004", "98005"…
## $ contributor_occupation     <chr> NA, NA, NA, "PRINICPAL", NA, NA, NA, NA, NA, NA, "FIREFIGHTER…
## $ contributor_employer_name  <chr> NA, NA, NA, "GLY CONSTRUCTION, INC.", NA, NA, NA, NA, NA, NA,…
## $ contributor_employer_city  <chr> NA, NA, NA, "BELLEVUE", NA, NA, NA, NA, NA, NA, "ELLENSBURG",…
## $ contributor_employer_state <chr> NA, NA, NA, "WA", NA, NA, NA, NA, NA, NA, "WA", "WA", NA, NA,…
## $ url                        <chr> "View report (https://web.pdc.wa.gov/rptimg/default.aspx?batc…
## $ contributor_location       <chr> "(44.68601, -123.05647)", "(47.64955, -122.39489)", "(47.6062…
```

```r
nrow(distinct(wa)) == nrow(wa)
```

```
## [1] TRUE
```

```r
wa %>% 
  select(-id) %>% 
  distinct() %>% 
  nrow() %>% 
  subtract(nrow(wa))
```

```
## [1] -43967
```

Variables range in their degree of distinctness. For example, There are only 10 distinct value of
`origin` and 97 for `ballot_number`; however, there are understandably nearly half a million
distinct values for `contributor_location` and even more for `contributor_name`.


```r
wa %>% 
  map(n_distinct) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_distinct") %>% 
  mutate(prop_distinct = round(n_distinct / nrow(wa), 4)) %>% 
  print(n = length(wa))
```

```
## # A tibble: 37 x 3
##    variable                   n_distinct prop_distinct
##    <chr>                           <int>         <dbl>
##  1 id                            4224421      1       
##  2 report_number                  385838      0.0913  
##  3 origin                             10      0       
##  4 filer_id                         5906      0.0014  
##  5 type                                2      0       
##  6 filer_name                       6107      0.0014  
##  7 first_name                       1189      0.000300
##  8 middle_initial                     27      0       
##  9 last_name                        4711      0.0011  
## 10 office                             44      0       
## 11 legislative_district               52      0       
## 12 position                           65      0       
## 13 party                               9      0       
## 14 ballot_number                      97      0       
## 15 for_or_against                      3      0       
## 16 jurisdiction                      526      0.0001  
## 17 jurisdiction_county                38      0       
## 18 jurisdiction_type                   5      0       
## 19 election_year                      17      0       
## 20 amount                          44757      0.0106  
## 21 cash_or_in_kind                     2      0       
## 22 receipt_date                     5288      0.0013  
## 23 description                     78117      0.0185  
## 24 memo                              283      0.0001  
## 25 primary_general                     3      0       
## 26 code                                8      0       
## 27 contributor_name               836108      0.198   
## 28 contributor_address            796656      0.189   
## 29 contributor_city                13171      0.0031  
## 30 contributor_state                 127      0       
## 31 contributor_zip                 16280      0.0039  
## 32 contributor_occupation          35935      0.0085  
## 33 contributor_employer_name      113423      0.0268  
## 34 contributor_employer_city        7024      0.0017  
## 35 contributor_employer_state        137      0       
## 36 url                            385838      0.0913  
## 37 contributor_location           468489      0.111
```

Variables also range in their degree of missing values. Key variables like `report_number` or
`code` have 0 missing values, while others like `first_name` or `office` are missing over half
(likely PAC/Corp. contributions and issue contributions respectively).


```r
count_na <- function(v) sum(is.na(v))
wa %>% map(count_na) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_na") %>% 
  mutate(prop_na = n_na / nrow(wa)) %>% 
  print(n = length(wa))
```

```
## # A tibble: 37 x 3
##    variable                      n_na    prop_na
##    <chr>                        <int>      <dbl>
##  1 id                               0 0         
##  2 report_number                    0 0         
##  3 origin                           0 0         
##  4 filer_id                         0 0         
##  5 type                             0 0         
##  6 filer_name                       0 0         
##  7 first_name                 2623057 0.621     
##  8 middle_initial             2791706 0.661     
##  9 last_name                        0 0         
## 10 office                     2623053 0.621     
## 11 legislative_district       3711578 0.879     
## 12 position                   3440229 0.814     
## 13 party                      2622213 0.621     
## 14 ballot_number              4023789 0.953     
## 15 for_or_against             3770023 0.892     
## 16 jurisdiction               2493740 0.590     
## 17 jurisdiction_county        3008678 0.712     
## 18 jurisdiction_type          2623053 0.621     
## 19 election_year                    0 0         
## 20 amount                           0 0         
## 21 cash_or_in_kind                  0 0         
## 22 receipt_date                 12591 0.00298   
## 23 description                3917046 0.927     
## 24 memo                       4133447 0.978     
## 25 primary_general                  0 0         
## 26 code                             0 0         
## 27 contributor_name                27 0.00000639
## 28 contributor_address         180101 0.0426    
## 29 contributor_city            177253 0.0420    
## 30 contributor_state           170263 0.0403    
## 31 contributor_zip             181370 0.0429    
## 32 contributor_occupation     2801286 0.663     
## 33 contributor_employer_name  2972083 0.704     
## 34 contributor_employer_city  3041105 0.720     
## 35 contributor_employer_state 3039095 0.719     
## 36 url                              0 0         
## 37 contributor_location        208755 0.0494
```

We can use `janitor::tablyl()` and `base::summary()` to explore the least distinct and continuous
variables.


```r
wa %>% tabyl(origin) %>% arrange(desc(n))
```

```
## # A tibble: 10 x 3
##    origin       n  percent
##    <chr>    <dbl>    <dbl>
##  1 C3     3916971 0.927   
##  2 C3.1E    92868 0.0220  
##  3 C4       75429 0.0179  
##  4 AUB      40512 0.00959 
##  5 AUD      40512 0.00959 
##  6 C3.1D    29082 0.00688 
##  7 C.1      11037 0.00261 
##  8 C3.1A     9043 0.00214 
##  9 C3.1B     5671 0.00134 
## 10 C.3       3296 0.000780
```

```r
wa %>% tabyl(type) %>% arrange(desc(n))
```

```
## # A tibble: 2 x 3
##   type                      n percent
##   <chr>                 <dbl>   <dbl>
## 1 Political Committee 2623053   0.621
## 2 Candidate           1601368   0.379
```

```r
wa %>% tabyl(party) %>% arrange(desc(n))
```

```
## # A tibble: 9 x 4
##   party                    n    percent valid_percent
##   <chr>                <dbl>      <dbl>         <dbl>
## 1 <NA>               2622213 0.621         NA        
## 2 DEMOCRAT            596549 0.141          0.372    
## 3 NON PARTISAN        511851 0.121          0.319    
## 4 REPUBLICAN          473548 0.112          0.296    
## 5 OTHER                10797 0.00256        0.00674  
## 6 NONE                  4240 0.00100        0.00265  
## 7 INDEPENDENT           3940 0.000933       0.00246  
## 8 LIBERTARIAN           1260 0.000298       0.000786 
## 9 CONSTITUTION PARTY      23 0.00000544     0.0000144
```

```r
wa %>% tabyl(for_or_against) %>% arrange(desc(n))
```

```
## # A tibble: 3 x 4
##   for_or_against       n percent valid_percent
##   <chr>            <dbl>   <dbl>         <dbl>
## 1 <NA>           3770023 0.892         NA     
## 2 For             423537 0.100          0.932 
## 3 Against          30861 0.00731        0.0679
```

```r
wa %>% tabyl(election_year)
```

```
## # A tibble: 17 x 3
##    election_year      n   percent
##    <chr>          <dbl>     <dbl>
##  1 2007          197987 0.0469   
##  2 2008          490708 0.116    
##  3 2009          276754 0.0655   
##  4 2010          298597 0.0707   
##  5 2011          209605 0.0496   
##  6 2012          561683 0.133    
##  7 2013          284077 0.0672   
##  8 2014          337639 0.0799   
##  9 2015          276217 0.0654   
## 10 2016          442068 0.105    
## 11 2017          303533 0.0719   
## 12 2018          411948 0.0975   
## 13 2019          107965 0.0256   
## 14 2020           23361 0.00553  
## 15 2021            1781 0.000422 
## 16 2022             403 0.0000954
## 17 2023              95 0.0000225
```

```r
wa %>% tabyl(cash_or_in_kind) %>% arrange(desc(n))
```

```
## # A tibble: 2 x 3
##   cash_or_in_kind       n percent
##   <chr>             <dbl>   <dbl>
## 1 Cash            4148992  0.982 
## 2 In kind           75429  0.0179
```

```r
wa %>% tabyl(cash_or_in_kind) %>% arrange(desc(n))
```

```
## # A tibble: 2 x 3
##   cash_or_in_kind       n percent
##   <chr>             <dbl>   <dbl>
## 1 Cash            4148992  0.982 
## 2 In kind           75429  0.0179
```

```r
wa %>% tabyl(primary_general) %>% arrange(desc(n))
```

```
## # A tibble: 3 x 3
##   primary_general           n percent
##   <chr>                 <dbl>   <dbl>
## 1 Full election cycle 2890255   0.684
## 2 Primary              812108   0.192
## 3 General              522058   0.124
```

```r
wa %>%  tabyl(code) %>% arrange(desc(n))
```

```
## # A tibble: 8 x 3
##   code                             n  percent
##   <chr>                        <dbl>    <dbl>
## 1 Individual                 3401494 0.805   
## 2 Other                       436363 0.103   
## 3 Business                    259902 0.0615  
## 4 Political Action Committee   92059 0.0218  
## 5 Union                        21449 0.00508 
## 6 Party                         9286 0.00220 
## 7 Self                          1970 0.000466
## 8 Caucus                        1898 0.000449
```

```r
wa %>% tabyl(contributor_state) %>% arrange(desc(n))
```

```
## # A tibble: 127 x 4
##    contributor_state       n percent valid_percent
##    <chr>               <dbl>   <dbl>         <dbl>
##  1 WA                3824238 0.905         0.943  
##  2 <NA>               170263 0.0403       NA      
##  3 CA                  39634 0.00938       0.00978
##  4 OR                  32139 0.00761       0.00793
##  5 ID                  14399 0.00341       0.00355
##  6 NY                  12186 0.00288       0.00301
##  7 TX                  11794 0.00279       0.00291
##  8 DC                   8595 0.00203       0.00212
##  9 FL                   7859 0.00186       0.00194
## 10 VA                   7405 0.00175       0.00183
## # … with 117 more rows
```


```r
wa %>% 
  ggplot(mapping = aes(x = amount)) +
  geom_histogram(bins = 30) +
  scale_y_log10() +
  scale_x_log10(labels = scales::dollar, 
                breaks = c(1, 10, 100, 1000, 100000, 1000000)) +
  facet_wrap(~cash_or_in_kind, ncol = 1) +
  labs(title = "Logarithmic Histogram of Contribution Amounts",
       x = "Dollars Contributed",
       y = "Number of Contributions")
```

There are 13916 records with `amount` values less than zero, which seem to
indicate corrections or refunds.

The median negative amount is only \$100, but 86 are less than $10,000 and
one is a correction of \$2.5 million. That report can be found at the URL below.


```r
summary(wa$amount)
```

```
##     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
## -2500000       10       35      308      100  8929810
```

```r
summary(wa$amount[wa$amount < 0])
```

```
##       Min.    1st Qu.     Median       Mean    3rd Qu.       Max. 
## -2500000.0     -300.0     -100.0     -862.2      -30.0        0.0
```

```r
wa$url[wa$amount == min(wa$amount)]
```

```
## [1] "View report (https://web.pdc.wa.gov/rptimg/default.aspx?batchnumber=100441590)"
```

There seems to be a number of broken date strings in the `receipt_date` variable. The earliest and
latest dates do not make sense. The earliest date was listed on a form from 2007, but records the
receiving date as 1900.


```r
min(wa$receipt_date, na.rm = TRUE)
```

```
## [1] "1900-01-01"
```

```r
max(wa$receipt_date, na.rm = TRUE)
```

```
## [1] "2041-06-06"
```

```r
sum(is.na(wa$receipt_date))
```

```
## [1] 12591
```

There should only be reports for the last 10 years, but over 100,000 are more than 12 years old.
There are 15 records with dates from before the year 2000. There are also 34 record with receipt
dates more than a year from today.


```r
wa %>% 
  filter(receipt_date < "2000-01-01") %>%
  arrange(receipt_date) %>% 
  select(
    id, 
    receipt_date, 
    election_year, 
    contributor_name, 
    amount, filer_name
  )
```

```
## # A tibble: 15 x 6
##    id         receipt_date election_year contributor_name         amount filer_name                
##    <chr>      <date>       <chr>         <chr>                     <dbl> <chr>                     
##  1 1712756.r… 1900-01-01   2007          BOOKKEEPING            23862.   THE LEADERSHIP COUNCIL    
##  2 5133549.r… 1916-06-08   2016          STEPHENS LARRY           100    YAKIMA CO DEMO CENT COMM …
##  3 2895778.r… 1964-06-11   2010          MURPHY MARY              500    MURPHY EDMUND M           
##  4 20638.corr 1964-06-11   2010          CORRECTION TO CONTRIB…  -500    MURPHY EDMUND M           
##  5 5985281.r… 1968-07-31   2018          BARTZ PATRICIA            50    WHATCOM CO DEMO CENT COMM…
##  6 7574185.s… 1968-07-31   2018          SMALL CONTRIBUTIONS       50    WHATCOM CO DEMO CENT COMM…
##  7 7574215.s… 1968-07-31   2018          SMALL CONTRIBUTIONS       45    WHATCOM CO DEMO CENT COMM…
##  8 5985290.r… 1968-08-01   2018          SCHWARTZ COLLEEN         100    WHATCOM CO DEMO CENT COMM…
##  9 7574221.s… 1968-08-01   2018          SMALL CONTRIBUTIONS       20    WHATCOM CO DEMO CENT COMM…
## 10 5937348.r… 1970-06-28   2018          STOKES LARRY             100    WALLIS JEFFREY J          
## 11 6597810.s… 1975-11-18   2016          MISCELLANEOUS RECEIPTS     0.53 SNOHOMISH CO DEMO CENT CO…
## 12 4479226.r… 1994-08-06   2016          THORN TERRY              150    BENTON DONALD M           
## 13 4479227.r… 1994-08-06   2016          CHAPMAN ROBERT           200    BENTON DONALD M           
## 14 4479228.r… 1994-08-07   2016          RASMUSSEN JOAN           100    BENTON DONALD M           
## 15 4479229.r… 1994-08-07   2016          PEMCO                    500    BENTON DONALD M
```

```r
wa %>% 
  filter(receipt_date > today() + years(1)) %>%
  arrange(desc(receipt_date)) %>% 
  select(
    id, 
    receipt_date, 
    election_year, 
    contributor_name, 
    amount, filer_name
  )
```

```
## # A tibble: 34 x 6
##    id        receipt_date election_year contributor_name       amount filer_name                   
##    <chr>     <date>       <chr>         <chr>                   <dbl> <chr>                        
##  1 4409700.… 2041-06-06   2014          MUNRO RALPH D              50 BURRAGE JEANETTE R           
##  2 4409701.… 2041-06-06   2014          KLEINER WALTER H          100 BURRAGE JEANETTE R           
##  3 4409702.… 2041-06-06   2014          HUGHES LARRY R            100 BURRAGE JEANETTE R           
##  4 3685495.… 2031-07-29   2012          KENNICOTT ELAINE E        100 WONG YOSHIE                  
##  5 5180900.… 2031-07-22   2016          SEIU HEALTHCARE            50 HANSEN DREW D                
##  6 5180901.… 2031-07-22   2016          MUCLESHOOT INDIAN TRI…    250 HANSEN DREW D                
##  7 5901063.… 2031-05-27   2018          TURNER BRUCE              500 FELICI RICKY (RICK) J        
##  8 3662698.… 2030-07-29   2012          ROBBINS BONNIE            250 WONG YOSHIE                  
##  9 39015.co… 2029-12-28   2016          CORRECTION TO CONTRIB…      0 AMERICAN INSTITUTE OF ARCHIT…
## 10 6241247.… 2029-02-23   2019          CAIRNS JOANNA              50 DAVIS KHALIA                 
## # … with 24 more rows
```

Looking at the original report source for a few of them (found through the `url` value), we can see
normal looking contribution dates alongside the weird ones. Writing "06/06/14" as "06/06/41" is an
example of a likely error.

There are nearly 200 records with egregious dates older than 1990 or from the future. I will flag
these dates with a new `date_flag` logical variable.


```r
wa <- wa %>% mutate(date_flag = receipt_date < "1990-01-01" | receipt_date > today())
```

## Clean

We can now clean the data to reach our objectives. All original columns and rows are preserved. New
cleaned columns are suffixed with `*_clean`.

### Mutate

Add new variables using `dplyr::mutate()` and string functions from: `zipcode`, `lubridate`, and
`stringr`.


```r
wa <- wa %>% 
  # create needed cols
  mutate(zip5_clean = clean.zipcodes(contributor_zip)) %>% 
  mutate(year_clean = year(receipt_date)) %>%
  # initialize other cols
  mutate(
    address_clean = str_remove(contributor_address, "[:punct:]"),
    city_clean    = contributor_city,
    state_clean   = contributor_state
  )
```

### ZIP Codes

After `zipcode::clean.zipcodes()` runs, there are still,
108 ZIP codes less than 5 characters. We can make these
`NA` rather than try to figure them out. We can also make some common erroneous ZIPs `NA`.


```r
n_distinct(wa$contributor_zip)
```

```
## [1] 16280
```

```r
n_distinct(wa$zip5_clean)
```

```
## [1] 15377
```

```r
sum(nchar(wa$zip5_clean) < 5, na.rm = T)
```

```
## [1] 108
```

```r
unique(wa$zip5_clean[nchar(wa$zip5_clean) < 5 & !is.na(wa$zip5_clean)])
```

```
##  [1] "98" "26" "75" "35" "25" "3"  "10" "50" "86" "60" "15" "99" "7"  "09" "03" "9"  "00" "4"  "67"
## [20] "32" "90" "13" "92" "30" "6"  "0"  "04"
```

```r
wa$zip5_clean[nchar(wa$zip5_clean) < 5 & !is.na(wa$zip5_clean)] <- NA
wa$zip5_clean <- wa$zip5_clean %>% na_if("00000|11111|99999")
```

### Sate Abbreviations

There are 127 distinct state abbreviations in the
`contributor_state` variable.


```r
n_distinct(wa$contributor_state)
```

```
## [1] 127
```

The `zipcode` package contains a useful list of zip codes and their accompanying states and cities.
This package has a list of state abbreviations that includes armed forces postal addresses and
American territories. We can add Canadian provinces to make it even more useful (compared to
`base::state.abb`).


```r
data("zipcode")
zipcode <- 
  tribble(
    ~city,           ~state,
    "Toronto",       "ON",
    "Quebec City",   "QC",
    "Montreal",      "QC",
    "Halifax",       "NS",
    "Fredericton",   "NB",
    "Moncton",       "NB",
    "Winnipeg",      "MB",
    "Victoria",      "BC",
    "Vancouver",     "BC",
    "Surrey",        "BC",
    "Richmond",      "BC",
    "Charlottetown", "PE",
    "Regina",        "SK",
    "Saskatoon",     "SK",
    "Edmonton",      "AB",
    "Calgary",       "AB",
    "St. John's",    "NL") %>% 
  bind_rows(zipcode) %>%
  mutate(city = str_to_upper(city) %>% str_remove_all("[:punct:]")) %>% 
  arrange(zip)

valid_abbs   <- sort(unique(zipcode$state))
invalid_abbs <- setdiff(wa$contributor_state, valid_abbs)
```

From this list, we know there are 72 valid abbreviations across the 50 states,
DC, territories, military bases, and Canadian provinces.

There are 325 records with 
58 invalid abbreviations.


```r
wa %>% 
  filter(!(contributor_state %in% valid_abbs)) %>% 
  group_by(contributor_state) %>% 
  count() %>%
  arrange(desc(n))
```

```
## # A tibble: 58 x 2
##    contributor_state      n
##    <chr>              <int>
##  1 <NA>              170263
##  2 ZZ                    55
##  3 RE                    41
##  4 ,                     35
##  5 OT                    32
##  6 OL                    30
##  7 98                    19
##  8 UK                    11
##  9 TE                     8
## 10 SE                     6
## # … with 48 more rows
```

"ZZ" is used to represent contributions from foreign countries. Some Canadian contributions have
valid `contributor_state` values (e.g., "BC", "ON"). There are 55 "ZZ" records with 14
distinct `contributor_city` values.


```r
wa %>%
  filter(contributor_state == "ZZ") %>% 
  pull(contributor_city) %>% 
  unique()
```

```
##  [1] "TOKYO"             "JAPAN"             "KAMAKURA 248-0016" "SURREY BC"        
##  [5] "VANCOUVER BC"      "SHIBUYA-KU  TOKYO" "RICHMOND, BC"      "SAI WAN HO"       
##  [9] "OSAKA"             "OHTSU SHIGA"       "KOWLOON"           "TSING YI"         
## [13] "IBARAKI"
```


```r
wa$state_clean[wa$contributor_state == "ZZ" & 
                 wa$contributor_city == "VANCOUVER BC" & 
                   !is.na(wa$contributor_state)] <- "BC"

wa$state_clean[wa$contributor_state == "ZZ" & 
                 wa$contributor_city == "RICHMOND, BC" & 
                   !is.na(wa$contributor_state)] <- "BC"

wa$state_clean[wa$contributor_state == "ZZ" & 
                 wa$contributor_city == "SURREY BC" & 
                   !is.na(wa$contributor_state)] <- "BC"
```

Once those "ZZ" values are made into Canadian abbreviations, we can make the rest of the "ZZ"
values `NA`.


```r
wa$state_clean <- wa$state_clean %>% na_if("ZZ")
wa$state_clean <- wa$state_clean %>% na_if("XX") # also foreign
```

All the records with a `state_clean` value of `,` have a `contributor_city` value of "SEATTLE",
so we can make them all "WA".


```r
if (
  wa %>% 
  filter(state_clean == ",") %>% 
  pull(contributor_city) %>% 
  unique() %>% 
  equals("SEATTLE")
) {
  wa$state_clean[wa$state_clean == "," & !is.na(wa$state_clean)] <- "WA"
}
```

Most of the records with a `contributor_state` value of "RE" have "REQUESTED" in the fields as a
placeholder. We will have to make them `NA`. Two records can be fixed manually based on their
`contributor_city` value.


```r
wa %>% 
  filter(address_clean == "REQUESTED") %>%
  filter(state_clean == "RE") %>% 
  select(
    id,
    contributor_name,
    contributor_address,
    contributor_state,
    contributor_zip,
    amount,
    filer_name
  )
```

```
## # A tibble: 13 x 7
##    id       contributor_name contributor_addre… contributor_sta… contributor_zip amount filer_name 
##    <chr>    <chr>            <chr>              <chr>            <chr>            <dbl> <chr>      
##  1 4742264… REISBERG LEAH    REQUESTED          RE               REQUE               20 BRADY WHIT…
##  2 4742265… NADASKY JULIE    REQUESTED          RE               REQUE              150 BRADY WHIT…
##  3 4742266… JOHNSON RON      REQUESTED          RE               REQUE               60 BRADY WHIT…
##  4 4742268… ROSS KELLIE      REQUESTED          RE               REQUE              100 BRADY WHIT…
##  5 4742269… WILLIAMS KERRY   REQUESTED          RE               REQUE               80 BRADY WHIT…
##  6 4742270… GREEN JONELL     REQUESTED          RE               REQUE               40 BRADY WHIT…
##  7 4742271… THOMAS DION      REQUESTED          RE               REQUE               40 BRADY WHIT…
##  8 4742272… REQUESTED ILLIZM REQUESTED          RE               REQUE               40 BRADY WHIT…
##  9 4742273… REQUESTED NATHAN REQUESTED          RE               REQUE               40 BRADY WHIT…
## 10 4742274… REISBERG LEAH    REQUESTED          RE               REQUE              120 BRADY WHIT…
## 11 4742278… ROBERTS MICHAEL  REQUESTED          RE               REQUE               40 BRADY WHIT…
## 12 4742252… TREVIGNE ERICH   REQUESTED          RE               REQUE               30 BRADY WHIT…
## 13 4742254… REISBERG LEAH    REQUESTED          RE               REQUE               40 BRADY WHIT…
```

```r
wa$state_clean[wa$address_clean == "REQUESTED" & wa$state_clean == "RE"] <- NA

wa %>% 
  filter(state_clean == "RE") %>% 
  pull(contributor_city) %>% 
  unique()
```

```
## [1] "LAKE FOREST PARK" "REDMOND"          "REQUESTED"
```

```r
# if the city is REDMOND and state RE, make WA
wa$state_clean[wa$state_clean == "RE" & 
                 wa$city_clean == "REDMOND" & 
                  !is.na(wa$state_clean)] <- "WA"

# if the city is LAKE FOREST PARK and state RE, make WA
wa$state_clean[wa$state_clean == "RE" & 
                 wa$city_clean == "LAKE FOREST PARK" & 
                  !is.na(wa$state_clean)] <- "WA"
```

Many of the records with a `contributor_state` value of "OT" seem to be located in Australia, and
all of them appear to be from foreign countries. Perhaps "OT" is an abbreviation for "Overseas
Territory"? We can make these values `NA`.


```r
wa %>% 
  filter(state_clean == "OT") %>% 
  select(
    contributor_name,
    contributor_address,
    contributor_city,
    contributor_state,
    contributor_zip,
    filer_name
  )
```

```
## # A tibble: 32 x 6
##    contributor_name  contributor_add… contributor_city contributor_sta… contributor_zip filer_name 
##    <chr>             <chr>            <chr>            <chr>            <chr>           <chr>      
##  1 HOLLING ANDREAS   MAXIMILIANSTR 1… MNNSTER          OT               48147           ORGANIC CO…
##  2 NAISMITH AUDREY   5 COOLAROO PLACE CHURCHILL        OT               3842            ORGANIC CO…
##  3 NEAL JODIE        2260 KALANG RD   BELLINGEN NSW    OT               2454            ORGANIC CO…
##  4 SWIFT MARILYN     PO BOX 7592      SAIPAN           OT               96950           ORGANIC CO…
##  5 BUYS KAREN        351 KEES RD      YARRAM           OT               03971           ORGANIC CO…
##  6 PIGGOTT ROGER     26 ROACH RD      BADDAGINNIE      OT               03670           ORGANIC CO…
##  7 SUTHERLAND DIANE  44 RUE E VAN DR… BRUSSELS         OT               01050           ORGANIC CO…
##  8 MARIT-WILLMANN A… REITA            MEISINGSET       OT               06628           ORGANIC CO…
##  9 ZUCCHI KARL       MIDDENKAMP 45    OSNABRUECK       OT               49082           ORGANIC CO…
## 10 BOYDELL RUTH      132 MARSHALL ST  AUSTRALIA        OT               02289           ORGANIC CO…
## # … with 22 more rows
```

```r
wa$state_clean %<>% na_if("OT")
```

There are 26 records with numeric state abbreviations. Using the `contributor_city` and
`contributor_zip` variables and comparing those in our `zipcode` table, we can see these should all
have state abbreviations of "WA."


```r
if (
  wa %>% 
  filter(state_clean %>% str_detect("[\\d+]")) %>% 
  left_join(
    y = (zipcode %>% 
      select(city, zip, state) %>% 
      drop_na()), 
    by = c("zip5_clean" = "zip")) %>%
  pull(state) %>%
  na.omit() %>% 
  unique() %>% 
  equals("WA")
) {
  wa$state_clean[str_detect(wa$state_clean, "[\\d+]") & !is.na(wa$state_clean)] <- "WA"
}
```

There are 30 records with a `contributor_state` value of
"OL." Each of these records has a `contributor_state` value of "OLYMPIA" and a `contributor_zip`
value in Washington. We can give all these records a `state_clean` value of "WA."

One is from Selfoss, a city in Iceland. The `contributor_name` value for that record has many
missing characters, as one from Iceland would. We will make that state record `NA`.


```r
wa %>% 
  filter(state_clean == "OL") %>% 
  pull(city_clean) %>% 
  unique()
```

```
## [1] "OLYMPIA" "SELFOSS"
```

```r
wa$state_clean[wa$state_clean == "OL"] <- "WA"
wa$state_clean[wa$city_clean == "SELFOSS"] <- NA
```

After fixing these most common `contributor_state` errors, there are a little over 100 records
still with invalid state abbreviations. Looking at the city names, most of these abbreviations
stand for other countries and can be made `NA`. We can fix records with `contributor_city` values
that look American.


```r
sum(na.omit(wa$state_clean) %in% invalid_abbs)
```

```
## [1] 105
```

```r
wa %>% 
  filter(state_clean %in% invalid_abbs) %>% 
  filter(!is.na(state_clean)) %>% 
  pull(city_clean) %>% 
  unique()
```

```
##  [1] "KATY"                 "SPRING"               "LONDON"               "SAITAMA"             
##  [5] "WALLINGTON"           "PADBURY"              "AMSTERDAM, HOLLAND"   "DURHAM"              
##  [9] "OSMO"                 "MANILA"               "VERDUN"               "COMOX"               
## [13] "SINGAPORE"            "COURTENAY"            "BERGEN"               "VOULA"               
## [17] "HURST GREEN"          "MORTSEL"              "RIBEIRO PRETO"        "TAURANGA"            
## [21] "ROSNY SOUS BOIS"      "WHITEHORSE"           "MURI"                 "MILAN"               
## [25] "TANUNDA AUSTRALIA"    "PEARLAND"             "AUSTIN"               "TUMWATER"            
## [29] "4600 36TH AVE SW"     "SEATTLE"              "ELLENSBURG"           "RAINIER"             
## [33] "TACOMA"               "REQUESTED"            "TOKOROZAWA CITY, SAI" "D.N. GALILHATACHTONE"
## [37] "CAMBRIDGE"            "INDIANOLA"            "MARYVILLE"            "BERLIN"              
## [41] "COPENHAGEN"           "ORGIVA"               "SOLIHULL"             "AUCKLAND"            
## [45] "YELLOWKNIFE"          "KOLBOTN"              "LIMOGES"              "AALBORG"             
## [49] "MILL BAY"             "EINDHOVEN"            "GWERN-Y-BRENIN"       "WASHINGTON"          
## [53] "HILLSBORO"            "ATLANTA"              "HENLEY-ON-THAMES"     "1410-WATERLOO"       
## [57] "BERN -3018"           "VILNIUS 08220"        "\"GLENBANE,"          "\"BAINBRIDGE"        
## [61] "\"LONG"               "15/2003"              "SAN DIEGO"            "FEDERAL WAY"         
## [65] "CHINA"                "SOUTH KOREA"          "AUSTRALIA"            "ICELAND"             
## [69] "HONG KONG"            "PARIS"                "PRALON"               "KAMAGAWA-SHI"
```

There are over 50 records with a `contributor_city` value of "SEATTLE" and Washington state ZIP
codes with invalid `contributor_state` values. We can make these "WA".


```r
seattle_ids <- wa %>%
  filter(city_clean == "SEATTLE") %>% 
  filter(state_clean %in% invalid_abbs) %>% 
  select(
    id, 
    contributor_name,
    address_clean,
    city_clean,
    state_clean,
    zip5_clean,
    filer_name) %>% 
  left_join(
    (zipcode %>% select(city, zip, state) %>% drop_na()), 
    by = c("zip5_clean" = "zip", "city_clean" = "city")) %>% 
  pull(id)

wa$state_clean[wa$id %in% seattle_ids] <- "WA"
rm(seattle_ids)
```

This record should be placed in Washington, D.C.


```r
wa$state_clean[wa$state_clean == "DI" & 
                 wa$city_clean == "WASHINGTON" & 
                   wa$zip5_clean == "20016" & 
                     !is.na(wa$state_clean)] <- "DC"
```

Finally, we can make all remaining invalid abbreviations `NA`.


```r
n_distinct(wa$state_clean)
## [1] 116
length(valid_abbs)
## [1] 72
sum(na.omit(wa$state_clean) %in% invalid_abbs)
## [1] 95
wa$state_clean[wa$state_clean %in% invalid_abbs] <- NA
```

This brings our total distinct abbreviations to 70. There are records
from every state except for American Samoa, the Marshall Islands, and Palau.


```r
n_distinct(wa$state_clean)
## [1] 70
setdiff(valid_abbs, sort(unique(wa$state_clean)))
## [1] "AS" "MH" "PW"
```

### Clean City

Cities are the most challenging. There are 13171 distinct values of
`contributor_city`. There are 756 Washington state
cities in the fairly comprehensive `zipcode` list. Since only 5% of records are from outside the
state, there are clearly many misspelled `contributor_city` values.


```r
n_distinct(wa$contributor_city)
```

```
## [1] 13171
```

```r
wa %>% tabyl(state_clean) %>% arrange(desc(n))
```

```
## # A tibble: 70 x 4
##    state_clean       n percent valid_percent
##    <chr>         <dbl>   <dbl>         <dbl>
##  1 WA          3824411 0.905         0.943  
##  2 <NA>         170404 0.0403       NA      
##  3 CA            39634 0.00938       0.00978
##  4 OR            32139 0.00761       0.00793
##  5 ID            14399 0.00341       0.00355
##  6 NY            12186 0.00288       0.00301
##  7 TX            11794 0.00279       0.00291
##  8 DC             8596 0.00203       0.00212
##  9 FL             7859 0.00186       0.00194
## 10 VA             7405 0.00175       0.00183
## # … with 60 more rows
```

Looking at just values starting with "SEAT", we can see how many different ways people can misspell
their city.


```r
unique(wa$city_clean[str_detect(wa$city_clean, "SEAT")])
```

```
##  [1] "SEATTLE"              NA                     "SEATAC"               "SEATTEL"             
##  [5] "SEATRLE"              "SEATTTLE"             "SEATTLE, WA"          "SEATTL"              
##  [9] "SEATTLEW="            "SEATTLE W"            "SEATTLE,"             "SEATATLE"            
## [13] "SEATT;LE"             "SEATTE"               "SEATLE"               "SEATTLTE"            
## [17] "SEATTLER"             "SEATT;E"              "SEATTKE"              "WEST SEATTLE"        
## [21] "SEATTLE, WA 98104"    "SEATTLE WA"           "SEATTLEL"             "SEATLLE"             
## [25] "SEATTLE."             "SEATTLEQ"             "SEATTAC"              "SEATTYLE"            
## [29] "SEATGTLE"             "SEATTLLE"             "W-SEATTLE"            "SEATTLW"             
## [33] "SEATTLED"             "SEATTLE, WA  98103"   "SEATTLE`"             "SEATTLR"             
## [37] "SEATTLOE"             "SEATTLEW"             "SEATTALE"             "SEATTLEE"            
## [41] "SEATTPE"              "`SEATTLE"             "SEATTLE P"            "SEAT TLE"            
## [45] "WSEATTLE"             "SEATYTLE"             "SEATTLKE"             "SEATTLE, WA  98168"  
## [49] "SEATT"                "SEATTLE4"             "SEATTTE"              "SEATAC,"             
## [53] "SEATTLEC"             "SOUTH SEATTLE"        "SEATTLESEATTLE"       "SEATTLE WA 98118"    
## [57] "SEATTLE, WA  98115"   "SEATTLE WA 98102"     "SEATTLE, WA 98112"    "SEATTLE, WA 98102"   
## [61] "SEATTLE E"            "SEATTLE WA 98104"     "SEATTILE"             "SILVER SEATTLE"      
## [65] "SEATTLE 98116-2201"   "SEATBACK"             "EDMONDSSEATTLE"       "SEATTELE"            
## [69] "SEATTRLE"             "SEATLTE"              "SEATTLE WA 98105"     "SEATTLWASHINGTON"    
## [73] "SSEATTLE"             "SEATTLELE"            "SEATTLE, WA 98119-17" "\"SEATTLE,"          
## [77] "SEATTLETTLE"          "SEATTLET"             "SEATTLEA"             "SEAT"                
## [81] "SEATAK"               "SEATTTL"              "SEATCA"               "SEATTLE TACOMA, WASH"
## [85] "SEATAX"
```

There are 6769 of 
`contributor_city` values not contained in the `zipcodes` data base; not all are misspellings, but
there are still too many to correct by hand.


```r
length(setdiff(wa$city_clean, zipcode$city))
```

```
## [1] 6769
```

I am going to create a separate table of spelling corrections. We can then join this table onto
the original data to create a new column of correct city names. The bulk of the work will be done
using key collision and ngram fingerprint algorithms from the open source tool Open Refine. These
algorithms are ported to R in the package `refinr`. These tools are able to correct most of the 
common errors, but I will be double checking the table and making changes in R.

There is a separate file in `wa_contribs/code/` which creates the lookup table needed to correct
spelling. That file has more detailed comments on the process. Below you can see some of the
changes made.


```r
source(here("wa_contribs", "code", "fix_wa_city.R"))
sample_n(city_fix_table, 10)
```

```
## # A tibble: 10 x 4
##    state_clean zip5_clean city_clean        city_fix        
##    <chr>       <chr>      <chr>             <chr>           
##  1 WA          99115      COULE CITY        COULEE CITY     
##  2 KS          67401      SALINA            SALINAS         
##  3 WA          98328      EATONVILL         EATONVILLE      
##  4 WA          98155      LAKE FORREST PARK LAKE FOREST PARK
##  5 WA          99344      OTHELLE           OTHELLO         
##  6 NE          68317      BENNET            BENNET          
##  7 OR          97753      POWELL-BUTTE      POWELL BUTTE    
##  8 WA          98827      LOMIS             LOOMIS          
##  9 WA          98022      ENUMCCLAW         ENUMCLAW        
## 10 ID          83814      COEUR D ALENE     COEUR DALENE
```

Join the original data set with the table of corrected city spellings. For every record, 
make `city_clean` either the original spelling or the corrected spelling.


```r
wa <- wa %>% 
  left_join(city_fix_table, by = c("zip5_clean", "city_clean", "state_clean")) %>% 
  mutate(city_clean = ifelse(is.na(city_fix), city_clean, city_fix)) %>% 
  select(-city_fix)
```

## Confirm

The key variables for this project are:

* `id` and `record_number` to identify the form
* `contributor_name` for who is giving money
* `amount` for how much was given
* `filer_name` for who it was given to

We need to ensure every row in the cleaned table contains that information.


```r
wa %>% 
  # select for the important vars
  select(
    id, 
    report_number, 
    contributor_name, 
    amount, 
    filer_name) %>% 
  # drop any row with missing data
  drop_na() %>% 
  # count the rows
  nrow() %>% 
  # check if equal to total total
  subtract(nrow(wa))
```

```
## [1] -27
```

The cleaned data set has 27 rows missing key information. Many of them are from a single auction,
held on April 29, 2008. Looking at the report for that auction, these auction rows were items
donated _by_ the Washington State Republican part that did not sell (hence the \$0 `amount`
values). Since there was no buyer, there is no `contributor_name` value.

I will flag these reports with a new `missing_flag` logical variable.


```r
wa %>% 
  select(
    id, 
    report_number,
    contributor_name, 
    amount, 
    filer_name) %>% 
  map(count_na) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_na") %>% 
  mutate(prop_na = n_na / nrow(wa)) %>% 
  print(n = length(wa))
```

```
## # A tibble: 5 x 3
##   variable          n_na    prop_na
##   <chr>            <int>      <dbl>
## 1 id                   0 0         
## 2 report_number        0 0         
## 3 contributor_name    27 0.00000639
## 4 amount               0 0         
## 5 filer_name           0 0
```

```r
wa %>% 
  # select for the important vars
  select(
    id, 
    report_number,
    contributor_name, 
    amount, 
    filer_name,
    receipt_date) %>% 
  filter(is.na(contributor_name)) %>% 
  print(n = 27)
```

```
## # A tibble: 27 x 6
##    id          report_number contributor_name amount filer_name                        receipt_date
##    <chr>       <chr>         <chr>             <dbl> <chr>                             <date>      
##  1 1743538.rc… 100207821     <NA>                36  SNOHOMISH CO DEMO CENT COMM NON … 2007-03-31  
##  2 2147780.rc… 100259580     <NA>              4732. WA AFFORDABLE HOUSING COUNCIL     2008-06-19  
##  3 2321311.rc… 100274694     <NA>                20  COALITION AGAINST ASSISTED SUICI… 2008-09-15  
##  4 2346433.rc… 100276695     <NA>                10  COALITION AGAINST ASSISTED SUICI… 2008-10-03  
##  5 2387991.rc… 100280141     <NA>                 5  COALITION AGAINST ASSISTED SUICI… 2008-10-17  
##  6 2388003.rc… 100280141     <NA>               250  COALITION AGAINST ASSISTED SUICI… 2008-10-17  
##  7 3032586.rc… 100385917     <NA>                35  KILMER DEREK C                    2010-10-15  
##  8 30583.auctd 1001267717    <NA>                 0  REEVES AUBREY C JR                NA          
##  9 29356.auctb 100252646     <NA>                 0  WA ST REPUB PARTY EXEMPT          2008-04-29  
## 10 29357.auctb 100252646     <NA>                 0  WA ST REPUB PARTY EXEMPT          2008-04-29  
## 11 29359.auctb 100252646     <NA>                 0  WA ST REPUB PARTY EXEMPT          2008-04-29  
## 12 29365.auctb 100252646     <NA>                 0  WA ST REPUB PARTY EXEMPT          2008-04-29  
## 13 29293.auctb 100252646     <NA>                 0  WA ST REPUB PARTY EXEMPT          2008-04-29  
## 14 29295.auctb 100252646     <NA>                 0  WA ST REPUB PARTY EXEMPT          2008-04-29  
## 15 29317.auctb 100252646     <NA>                 0  WA ST REPUB PARTY EXEMPT          2008-04-29  
## 16 29290.auctb 100252646     <NA>                 0  WA ST REPUB PARTY EXEMPT          2008-04-29  
## 17 29330.auctb 100252646     <NA>                 0  WA ST REPUB PARTY EXEMPT          2008-04-29  
## 18 29328.auctb 100252646     <NA>                 0  WA ST REPUB PARTY EXEMPT          2008-04-29  
## 19 29322.auctb 100252646     <NA>                 0  WA ST REPUB PARTY EXEMPT          2008-04-29  
## 20 29326.auctb 100252646     <NA>                 0  WA ST REPUB PARTY EXEMPT          2008-04-29  
## 21 29258.auctb 100252646     <NA>                 0  WA ST REPUB PARTY EXEMPT          2008-04-29  
## 22 29224.auctb 100252646     <NA>                 0  WA ST REPUB PARTY EXEMPT          2008-04-29  
## 23 29333.auctb 100252646     <NA>                 0  WA ST REPUB PARTY EXEMPT          2008-04-29  
## 24 29303.auctb 100252646     <NA>                 0  WA ST REPUB PARTY EXEMPT          2008-04-29  
## 25 29345.auctb 100252646     <NA>                 0  WA ST REPUB PARTY EXEMPT          2008-04-29  
## 26 29368.auctb 100252646     <NA>                 0  WA ST REPUB PARTY EXEMPT          2008-04-29  
## 27 30583.auctb 1001267717    <NA>                 0  REEVES AUBREY C JR                NA
```

```r
wa <- wa %>% mutate(missing_flag = is.na(contributor_name))
```

## Conclusion

The final data set now meets all our objectives:

1. There are 4224421 records.
1. There are no duplicated records.
1. `amount` has a large range due to corrections, while `receipt_date` has a few
erroneous values do to entry errors (flagged with `date_flag`).
1. Missing data varies by nature of variable.
1. The `state_clean`, `city_clean`, and `address_clean` are all consistently uppercase without punctuation. Many spelling errors have been corrected in the first two.
1. The `zip5_clean` variable contains clean ZIP codes.
1. the `year_clean` variable contains clean receipt year values.
1. The 27 records missing contributor names have been flagged with the
`missing_flag` variable.

The overall number of distinct values has been reduced, allowing for better searching.


```r
n_distinct(wa$address_clean) - n_distinct(wa$contributor_address)
## [1] -43500
n_distinct(wa$city_clean)    - n_distinct(wa$contributor_city)  
## [1] -1251
n_distinct(wa$state_clean)   - n_distinct(wa$contributor_state) 
## [1] -57
n_distinct(wa$zip5_clean)    - n_distinct(wa$contributor_zip)   
## [1] -930
```

We can write two versions of the document. The first has all original columns along with cleaned
data in the `*_clean` columns. The second remove the original columns for file size reasons.


```r
# all data, original and cleaned
wa %>% write_csv(
  path = here("wa_contribs", "data", "wa_contribs_all.csv"),
  na = "",
  col_names = TRUE,
  quote_escape = "backslash"
)

wa %>%
  # remove the original contributor_* columns for space
  select(
    -contributor_address,
    -contributor_city,
    -contributor_state,
    -contributor_zip
  ) %>% 
  write_csv(
    path = here("wa_contribs", "data", "wa_contribs_clean.csv"),
    na = "",
    col_names = TRUE,
    quote_escape = "backslash"
  )
```
