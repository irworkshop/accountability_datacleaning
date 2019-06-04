---
title: "Data Diary"
subtitle: "Nevada Contributions"
author: "Kiernan Nicholls"
date: "2019-06-04 17:28:27"
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

## Packages

The following packages are needed to collect, manipulate, visualize, analyze, and communicate
these results. The `pacman` package will facilitate their installation and attachment.


```r
# install.packages("pacman")
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # date strings
  magrittr, # pipe opperators
  janitor, # data cleaning
  zipcode, # clean and compare
  refinr, # cluster and merge
  vroom, # read files fast
  rvest, # scrape web pages
  knitr, # knit documents
  httr, # acess web API
  here, # navigate local storage
  fs # search local storage 
)
```

## Data

The Nevada Secretary of State (NVSOS) office requires that one register for an account to access 
"[bulk data download](https://www.nvsos.gov/sos/online-services/data-download)" service page.

> Welcome to the Nevada Secretary of State online unified login system.  Here you may access the following systems all with one login account:
>
> * Document Preparation Service *New
> * Commercial Registered Agent Tools
> * Bulk Data Download
> * NV SOS Trust Account
> * Nevada Ministers Database
> * Notary Class / Notary Address Change

The process for downloaded a report is [outlined here](https://www.nvsos.gov/SoSServices/AnonymousAccess/HelpGuides/DataDownloadUserGuide.aspx):

In brief, we will be downloading a "Full Unabridged Database Dump" of "Campaign Finance" data,
which will be delivered via email. We have chosen the file to be in the CSV format with column
names in the first row. When selected a report with this criteria, the NVSOS website provides
the following message: 

> This report will expose Contributions and Expenses report data filed within our “Aurora” Campaign
Financial Disclosure system.  This would not include data filed in a Financial Disclosure report.
This bulk data report tool here should be used to pull the entire database or slightly smaller
subsets of data such as all contributions filed after 1/1/2016 by groups of type “PAC”.  For more
detailed searches such as looking up all contributions filed by candidate “John Doe” or looking up
all expenses filed between $100,000 and $300,000 use the free public search here.

The website also provides a brief message regarding the age of the data:

> The data being reported off of is no more than 24 hours old. This data is copied very late each night from live data to minimize the large burden of bulk reporting on the production system.

This report was generated on 2019-06-04.

The report data is partitioned into multiple files, as explained on the 
[NVSOS FAQ page](https://www.nvsos.gov/SOSServices/AnonymousAccess/HelpGuides/FAQ.aspx#5):

> This is what is referred to as a normalized relational structure in the database world.  Data
items such as business entities and officers have a direct relation to one another.  There can be
any number of officers to one business entity.  Because of this many to one relationship, the
officers data is stored in a different data table (or file) than the business entities.  Then we
relate officer records to a business entity record by a common key data column, in this case the
CorporationID... By separating officers and entities into separate records we can eliminate the
redundancy and added size associated with putting the business entity data on each officer record
or eliminate the complexity of allocating an undeterminable amount of officers on the one business
entity record.  This same many-to-one relationship is true of voter history records to voter
records, UCC actions to UCC liens or Corporation Stocks to Corporations, to name a few.

Specifically, a campaign finance report is partitioned into six individual reports:

1. Candidates
1. Contributions
1. Contributors-Payees
1. Expenses
1. Groups
1. Reports

NVSOS provides information on some variables in the "Result Field" tab of the report generator:

In the "Candidates" report:

* `Jurisdiction` = 

> This will be name of the city or county for city/county offices currently held by the candidate
(e.g. “CITY OF YERINGTON”, “DOUGLAS COUNTY”).  This will be set to “NV SOS” for statewide offices
such as Governor, State Controller or State assemblymen.  An office assigned to a candidate could
be updated by the NV SOS Elections staff as necessary when that candidate files for a new office.

In the "Contributions" report:

* `Contribution Type` = 

> Use this column to differentiate which one of four contribution types this contribution record
is: Monetary Contribution, In Kind Contribution, In Kind Written Commitment, or Written Commitment.

In the "Contributors-Payees" report:

* `Last Name` = 

> When the contributor or payee is an organization as opposed to an individual, the entire
organization name will be in the Last Name field only.

In the "Expenses" report:

* `Expense Type` = 

> Use this column to differentiate which type of expense record this is: Monetary Expense or In
Kind Expense.

In the "Groups" report:

* `Active`

> A value of F (False) indicates the group has been marked as inactive by the NV Secretary of
State's office Elections division due to submission of a "notice of inactivity" or for failure to
renew annual registration.

In the "Reports" report:

* `Amended` = 

> A value of T (True) indicates this contributions and expense report has been marked as an amended
report by the original filer implying this report supersedes a report for this same period, filed
earlier.   An amended report is to be full comprehensive for that report period and in essence
replaces all contributions and expenses filed in the earlier report.

* `Election Cycle` = 

> The Election Cycle is the 4 digit filing or reporting year defining a filing period grouping
together a collection of contribution and expenses reports...

* `Superseded` = 

> A report is Superseded when an amended report was filed later by the same filer for the same
reporting period.  In this case the Superseded field for the older report record will be set to T
(True)...

## Read

The following link was sent via email and downloaded to the `data/` directory:

```
https://www.nvsos.gov/yourreports/CampaignFinance.43993.060419121813.zip
```

The ZIP file contains six individual files:


```
#> # A tibble: 6 x 3
#>   name                                               length date               
#>   <chr>                                               <dbl> <dttm>             
#> 1 CampaignFinance.Cnddt.43898.060419073713.csv       598979 2019-06-04 07:37:00
#> 2 CampaignFinance.Cntrbt.43898.060419073713.csv    32805188 2019-06-04 07:37:00
#> 3 CampaignFinance.Cntrbtrs-.43898.060419073713.csv  6375270 2019-06-04 07:37:00
#> 4 CampaignFinance.Expn.43898.060419073713.csv      16972004 2019-06-04 07:37:00
#> 5 CampaignFinance.Grp.43898.060419073713.csv         118074 2019-06-04 07:37:00
#> 6 CampaignFinance.Rpr.43898.060419073713.csv        2415840 2019-06-04 07:37:00
```

The files will be unzipped into the `data/` directory.


```r
dir_create(here("nv_contribs", "data"))
here("nv_contribs", "data") %>% 
  dir_ls(, glob = "*.zip") %>% 
  unzip(
    exdir = here("nv_contribs", "data"),
    overwrite = TRUE
  )
```

Each file can be read using the `vroom::vroom()` function:


```r
nv_candidates <- 
  here("nv_contribs", "data") %>% 
  dir_ls(glob = "*.csv") %>% 
  extract(1) %>% 
  vroom(col_types = cols(.default = "c")) %>% 
  clean_names()

print(nv_candidates)
```

```
#> # A tibble: 6,659 x 6
#>    candidate_id first_name last_name  party         office                          jurisdiction   
#>    <chr>        <chr>      <chr>      <chr>         <chr>                           <chr>          
#>  1 28           Michael    Douglas    Nonpartisan   Supreme Court Justice, Seat F   NV SOS         
#>  2 30           Richard    Ziser      Republican P… U.S. Senate                     NV SOS         
#>  3 31           Carlo      Poliak     Unspecified   City Council, Las Vegas         CITY OF LAS VE…
#>  4 32           Lynn       Hettrick   Republican P… State Assembly, District 39     NV SOS         
#>  5 33           James      Gibbons    Republican P… Governor                        NV SOS         
#>  6 34           Bonnie     Parnell    Democratic P… State Assembly, District 40     NV SOS         
#>  7 35           Marcia     Washington Nonpartisan   State Senate, District 4        CLARK COUNTY   
#>  8 36           Harry      Reid       Democratic P… U.S. Senate                     NV SOS         
#>  9 37           Kenneth    Wegner     Republican P… U.S. Senate                     NV SOS         
#> 10 38           Cynthia    Steel      Nonpartisan   District Court Judge, District… CLARK COUNTY   
#> # … with 6,649 more rows
```


```r
nv_contribs <- 
  here("nv_contribs", "data") %>% 
  dir_ls(glob = "*.csv") %>% 
  extract(2) %>% 
  vroom(
    .name_repair = make_clean_names,
    col_types = cols(
      .default = col_character(),
      `Contribution Date` = col_date("%m/%d/%Y"),
      `Contribution Amount` = col_number()
    )
  )

print(nv_contribs)
```

```
#> # A tibble: 456,976 x 8
#>    contribution_id report_id candidate_id group_id contribution_da… contribution_am…
#>    <chr>           <chr>     <chr>        <chr>    <date>                      <dbl>
#>  1 2               6980      <NA>         1220     2006-06-28                  35000
#>  2 3               6983      <NA>         1332     2006-03-29                      2
#>  3 4               6983      <NA>         1332     2006-03-31                      1
#>  4 5               6983      <NA>         1332     2006-04-10                    200
#>  5 6               6983      <NA>         1332     2006-01-01                      0
#>  6 7               6983      <NA>         1332     2006-01-01                      0
#>  7 8               6983      <NA>         1332     2006-01-01                      0
#>  8 9               6987      <NA>         1364     2006-01-13                   1000
#>  9 10              6991      2360         <NA>     2006-02-07                    100
#> 10 11              6991      2360         <NA>     2006-02-08                    500
#> # … with 456,966 more rows, and 2 more variables: contribution_type <chr>, contributor_id <chr>
```


```r
nv_groups <- 
 here("nv_contribs", "data") %>% 
  dir_ls(glob = "*.csv") %>% 
  extract(5) %>% 
  vroom(
    .name_repair = make_clean_names,
    col_types = cols(
      .default = col_character(),
      Active = col_logical()
    )
  )

print(nv_groups)
```

```
#> # A tibble: 1,196 x 6
#>    group_id group_name                               group_type       contact_name  active city    
#>    <chr>    <chr>                                    <chr>            <chr>         <lgl>  <chr>   
#>  1 598      Allstate Insurance Company Political Ac… Political Actio… Shirlanda Wa… TRUE   Northbr…
#>  2 600      American Insurance Association PAC - Ne… Political Actio… James L. Wad… FALSE  Sacrame…
#>  3 601      Board of Realtors Political Action Comm… Political Actio… Wendy DiVecc… TRUE   Las Veg…
#>  4 603      Churchill County Education Association   Political Actio… Sue S Matuska TRUE   Fallon  
#>  5 607      Carriers Allied for Responsible Governm… Political Actio… Daryl E. Cap… FALSE  SPARKS  
#>  6 610      P.A.C. 357   (fka IBEW LOCAL 357 PAC)    Political Actio… James Halsey  TRUE   Las Veg…
#>  7 615      Southwest Regional Council of Carpenter… Political Actio… Frank Hawk    TRUE   Sacrame…
#>  8 616      Construction Industry Committee          Political Actio… Craig Madole  TRUE   Reno    
#>  9 617      Douglas County Professional Education A… Political Actio… Sue S Matuska TRUE   South L…
#> 10 621      International Union of Painters and All… Political Actio… Jason Lamber… TRUE   Hanover 
#> # … with 1,186 more rows
```


```r
nv_reports <- 
 here("nv_contribs", "data") %>% 
  dir_ls(glob = "*.csv") %>% 
  extract(6) %>% 
  vroom(
    .name_repair = make_clean_names,
    col_types = cols(
      .default = col_character(),
      `Filing Due Date` = col_date("%m/%d/%Y"),
      `Filed Date` = col_date("%m/%d/%Y"),
      Amended = col_logical(),
      Superseded = col_logical()
    )
  )

print(nv_reports)
```

```
#> # A tibble: 37,580 x 9
#>    report_id candidate_id group_id report_name election_cycle filing_due_date filed_date amended
#>    <chr>     <chr>        <chr>    <chr>       <chr>          <date>          <date>     <lgl>  
#>  1 6980      <NA>         1220     CE Report 1 2006           NA              2006-08-08 FALSE  
#>  2 6981      1988         <NA>     CE Report 1 2006           NA              2006-10-30 FALSE  
#>  3 6982      1988         <NA>     CE Report 1 2006           NA              2006-08-07 FALSE  
#>  4 6983      <NA>         1332     CE Report 1 2006           NA              2006-08-07 FALSE  
#>  5 6984      1992         <NA>     CE Report 1 2006           NA              2006-08-07 FALSE  
#>  6 6985      1165         <NA>     CE Report 1 2006           NA              2006-08-07 FALSE  
#>  7 6986      155          <NA>     CE Report 1 2006           NA              2006-08-07 FALSE  
#>  8 6987      <NA>         1364     CE Report 1 2006           NA              2006-08-08 FALSE  
#>  9 6990      2368         <NA>     CE Report 1 2006           NA              2006-08-08 FALSE  
#> 10 6991      2360         <NA>     CE Report 1 2006           NA              2006-08-08 FALSE  
#> # … with 37,570 more rows, and 1 more variable: superseded <lgl>
```

We are primarily interested in the file containing data on contributions. To make the data base
more searchable on the Accountability Project database, we will be joining together the various
normalized relational tables using their respective `*_id` variables.


```r
nv <- nv_contribs %>%
  # join with relational tables
  left_join(nv_candidates, by = "candidate_id") %>% 
  left_join(nv_reports, by = c("report_id", "candidate_id", "group_id")) %>%
  left_join(nv_groups, by = "group_id") %>% 
  # add origin table info to ambiguous variables
  rename(
    candidate_first = first_name,
    candidate_last = last_name,
    candidate_party = party,
    seeking_office = first_name,
    report_amended = amended, 
    report_superseded = superseded,
    group_contact = contact_name,
    group_active = active,
    group_city = city
  )

nrow(nv) == nrow(nv_contribs)
#> [1] TRUE
```

This expands our primary table from 8 variables to 24
without changing the number or records included.

## Explore

Below is the structure of the data arranged randomly by row. There are 456976 rows of 
24 variables.


```r
glimpse(sample_frac(nv))
```

```
#> Observations: 456,976
#> Variables: 24
#> $ contribution_id     <chr> "473248", "7354", "301643", "300814", "209520", "197154", "162470", …
#> $ report_id           <chr> "73145", "19346", "49425", "49425", "42399", "42393", "41571", "4010…
#> $ candidate_id        <chr> "6808", "3424", "1643", "1643", NA, NA, NA, NA, NA, "5033", "419", N…
#> $ group_id            <chr> NA, NA, NA, NA, "1616", "837", "1177", "987", "826", NA, NA, "1444",…
#> $ contribution_date   <date> 2017-09-11, 2008-08-02, 2014-09-10, 2014-09-09, 2013-09-20, 2013-09…
#> $ contribution_amount <dbl> 4.58, 101.91, 4.00, 2.00, 25.00, 60.00, 1.20, 9.00, 5.00, 1000.00, 5…
#> $ contribution_type   <chr> "In Kind Contribution", "Monetary Contribution", "Monetary Contribut…
#> $ contributor_id      <chr> "201222", "4300", "174273", "174767", "121193", "110589", "78359", "…
#> $ seeking_office      <chr> "Nicole", "Terry", "Kate", "Kate", NA, NA, NA, NA, NA, "Lawrence", "…
#> $ candidate_last      <chr> "Cannizzaro", "Tiernay", "Marshall", "Marshall", NA, NA, NA, NA, NA,…
#> $ candidate_party     <chr> "Democratic Party", "Nonpartisan", "Democratic Party", "Democratic P…
#> $ office              <chr> "State Board of Education, District 6", "Washoe County Commissioner,…
#> $ jurisdiction        <chr> "CLARK COUNTY", "WASHOE COUNTY", "NV SOS", "NV SOS", NA, NA, NA, NA,…
#> $ report_name         <chr> "2018 Annual CE Filing", "CE Report 2", "CE Report 3", "CE Report 3"…
#> $ election_cycle      <chr> "2017", "2008", "2014", "2014", "2013", "2013", "2013", "2013", "201…
#> $ filing_due_date     <date> NA, 2008-10-28, 2014-10-14, 2014-10-14, NA, NA, NA, NA, NA, 2012-10…
#> $ filed_date          <date> 2018-01-16, 2008-10-24, 2014-10-14, 2014-10-14, 2014-01-15, 2014-01…
#> $ report_amended      <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
#> $ report_superseded   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
#> $ group_name          <chr> NA, NA, NA, NA, "The Travelers Companies, Inc. PAC (TPAC)", "Citigro…
#> $ group_type          <chr> NA, NA, NA, NA, "Political Action Committee", "Political Action Comm…
#> $ group_contact       <chr> NA, NA, NA, NA, "Michele Balady", "Barbara Mulholland", "Sue Matuska…
#> $ group_active        <lgl> NA, NA, NA, NA, TRUE, TRUE, TRUE, TRUE, TRUE, NA, NA, TRUE, NA, TRUE…
#> $ group_city          <chr> NA, NA, NA, NA, "Hartford", "Washington", "Washington", "Wilmington"…
```

### Distinct

The variables vary in their degree of distinctiveness.


```r
nv %>% 
  map(n_distinct) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_distinct") %>% 
  mutate(prop_distinct = round(n_distinct / nrow(nv), 4)) %>%
  print(n = length(nv))
```

```
#> # A tibble: 24 x 3
#>    variable            n_distinct prop_distinct
#>    <chr>                    <int>         <dbl>
#>  1 contribution_id         456976       1      
#>  2 report_id                13040       0.0285 
#>  3 candidate_id              1795       0.0039 
#>  4 group_id                   640       0.0014 
#>  5 contribution_date         4441       0.0097 
#>  6 contribution_amount      13277       0.0291 
#>  7 contribution_type            4       0      
#>  8 contributor_id          145126       0.318  
#>  9 seeking_office             762       0.0017 
#> 10 candidate_last            1476       0.0032 
#> 11 candidate_party             13       0      
#> 12 office                     537       0.00120
#> 13 jurisdiction                36       0.0001 
#> 14 report_name                 80       0.0002 
#> 15 election_cycle              14       0      
#> 16 filing_due_date             10       0      
#> 17 filed_date                1177       0.0026 
#> 18 report_amended               2       0      
#> 19 report_superseded            2       0      
#> 20 group_name                 639       0.0014 
#> 21 group_type                   7       0      
#> 22 group_contact              474       0.001  
#> 23 group_active                 3       0      
#> 24 group_city                  89       0.0002
```

For the least distinct variables, we can explore the most common values.




```r
print_tabyl(nv, contribution_type)
```

```
#> # A tibble: 4 x 3
#>   contribution_type               n  percent
#>   <chr>                       <dbl>    <dbl>
#> 1 Monetary Contribution      443084 0.970   
#> 2 In Kind Contribution        13643 0.0299  
#> 3 In Kind Written Commitment    128 0.000280
#> 4 Written Commitment            121 0.000265
```

```r
print_tabyl(nv, candidate_party)
```

```
#> # A tibble: 13 x 4
#>    candidate_party                   n    percent valid_percent
#>    <chr>                         <dbl>      <dbl>         <dbl>
#>  1 <NA>                         197465 0.432         NA        
#>  2 Democratic Party             119072 0.261          0.459    
#>  3 Republican Party              69135 0.151          0.266    
#>  4 Nonpartisan                   36205 0.0792         0.140    
#>  5 Unspecified                   33549 0.0734         0.129    
#>  6 Independent                     814 0.00178        0.00314  
#>  7 Independent American Party      409 0.000895       0.00158  
#>  8 Test Party Name 5               153 0.000335       0.000590 
#>  9 Libertarian Party of Nevada     127 0.000278       0.000489 
#> 10 Nevada Green Party               25 0.0000547      0.0000963
#> 11 Tea Party                        13 0.0000284      0.0000501
#> 12 DuoFreedomist Party               5 0.0000109      0.0000193
#> 13 Constitution Party of Nevada      4 0.00000875     0.0000154
```

```r
print_tabyl(nv, seeking_office)
```

```
#> # A tibble: 762 x 4
#>    seeking_office      n percent valid_percent
#>    <chr>           <dbl>   <dbl>         <dbl>
#>  1 <NA>           197465 0.432         NA     
#>  2 Steve           18271 0.0400         0.0704
#>  3 Kate            13277 0.0291         0.0512
#>  4 Adam            12409 0.0272         0.0478
#>  5 Chris           11878 0.0260         0.0458
#>  6 Aaron            6573 0.0144         0.0253
#>  7 John             5290 0.0116         0.0204
#>  8 Richard          4906 0.0107         0.0189
#>  9 James            4904 0.0107         0.0189
#> 10 Justin           4205 0.00920        0.0162
#> # … with 752 more rows
```

```r
print_tabyl(nv, jurisdiction)
```

```
#> # A tibble: 36 x 4
#>    jurisdiction                 n percent valid_percent
#>    <chr>                    <dbl>   <dbl>         <dbl>
#>  1 <NA>                    197465 0.432        NA      
#>  2 NV SOS                   96253 0.211         0.371  
#>  3 CLARK COUNTY             94874 0.208         0.366  
#>  4 WASHOE COUNTY            26706 0.0584        0.103  
#>  5 CITY OF LAS VEGAS        11966 0.0262        0.0461 
#>  6 CITY OF RENO              7589 0.0166        0.0292 
#>  7 CITY OF HENDERSON         3255 0.00712       0.0125 
#>  8 CARSON CITY               3188 0.00698       0.0123 
#>  9 CITY OF NORTH LAS VEGAS   3180 0.00696       0.0123 
#> 10 UNKNOWN                   2489 0.00545       0.00959
#> # … with 26 more rows
```

```r
print_tabyl(nv, report_name)
```

```
#> # A tibble: 80 x 3
#>    report_name               n percent
#>    <chr>                 <dbl>   <dbl>
#>  1 CE Report 1           75902  0.166 
#>  2 CE Report 3           71187  0.156 
#>  3 2014 Annual CE Filing 70831  0.155 
#>  4 CE Report 1 (Amended) 30016  0.0657
#>  5 CE Report 3 (Amended) 26267  0.0575
#>  6 CE Report 4           24566  0.0538
#>  7 CE Report 2           19083  0.0418
#>  8 2012 Annual CE Filing 16192  0.0354
#>  9 2018 Annual CE Filing 15378  0.0337
#> 10 CE Report 5           15354  0.0336
#> # … with 70 more rows
```

```r
print_tabyl(nv, election_cycle)
```

```
#> # A tibble: 14 x 3
#>    election_cycle     n percent
#>    <chr>          <dbl>   <dbl>
#>  1 2013           90111 0.197  
#>  2 2018           88975 0.195  
#>  3 2014           77793 0.170  
#>  4 2012           55131 0.121  
#>  5 2016           50722 0.111  
#>  6 2017           27855 0.0610 
#>  7 2015           21103 0.0462 
#>  8 2011           20006 0.0438 
#>  9 2010           11796 0.0258 
#> 10 2008            6113 0.0134 
#> 11 2019            2863 0.00627
#> 12 2009            2045 0.00448
#> 13 2006            1546 0.00338
#> 14 2007             917 0.00201
```

```r
print_tabyl(nv, report_amended)
```

```
#> # A tibble: 2 x 3
#>   report_amended      n percent
#>   <lgl>           <dbl>   <dbl>
#> 1 FALSE          372463   0.815
#> 2 TRUE            84513   0.185
```

```r
print_tabyl(nv, report_superseded)
```

```
#> # A tibble: 2 x 3
#>   report_superseded      n percent
#>   <lgl>              <dbl>   <dbl>
#> 1 FALSE             380687   0.833
#> 2 TRUE               76289   0.167
```

```r
print_tabyl(nv, group_type)
```

```
#> # A tibble: 7 x 4
#>   group_type                      n   percent valid_percent
#>   <chr>                       <dbl>     <dbl>         <dbl>
#> 1 <NA>                       259511 0.568         NA       
#> 2 Political Action Committee 152199 0.333          0.771   
#> 3 Political Party Committee   41845 0.0916         0.212   
#> 4 PAC Ballot Advocacy Group    2988 0.00654        0.0151  
#> 5 Recall Committee              270 0.000591       0.00137 
#> 6 Non-Profit Corporation        135 0.000295       0.000684
#> 7 Independent Expenditure        28 0.0000613      0.000142
```

```r
print_tabyl(nv, group_active)
```

```
#> # A tibble: 3 x 4
#>   group_active      n percent valid_percent
#>   <lgl>         <dbl>   <dbl>         <dbl>
#> 1 NA           259511  0.568        NA     
#> 2 TRUE         181224  0.397         0.918 
#> 3 FALSE         16241  0.0355        0.0822
```

```r
print_tabyl(nv, group_city)
```

```
#> # A tibble: 89 x 4
#>    group_city       n percent valid_percent
#>    <chr>        <dbl>   <dbl>         <dbl>
#>  1 <NA>        259511 0.568         NA     
#>  2 Washington   57513 0.126          0.291 
#>  3 Las Vegas    46687 0.102          0.236 
#>  4 Reno         43772 0.0958         0.222 
#>  5 Wilmington   12815 0.0280         0.0649
#>  6 Hartford     11433 0.0250         0.0579
#>  7 Northbrook    8521 0.0186         0.0432
#>  8 Carson City   5381 0.0118         0.0273
#>  9 Henderson     3013 0.00659        0.0153
#> 10 New York      2019 0.00442        0.0102
#> # … with 79 more rows
```

### Ranges

For continuous variables, the ranges should be checked.


```r
summary(nv$contribution_date)
```

```
#>         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
#> "2006-01-01" "2013-03-28" "2014-08-14" "2014-12-13" "2017-03-16" "2019-04-19"
```

```r
summary(nv$contribution_amount)
```

```
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#>   -25000       25      200     1883     1000 20700000
```

```r
summary(nv$filing_due_date)
```

```
#>         Min.      1st Qu.       Median         Mean      3rd Qu.         Max.         NA's 
#> "2006-10-31" "2012-10-16" "2014-10-31" "2015-06-02" "2018-10-16" "2018-10-16"     "343350"
```

```r
summary(nv$filed_date)
```

```
#>         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
#> "2006-08-07" "2014-01-06" "2014-10-14" "2015-03-27" "2017-12-09" "2019-05-21"
```

The date variables all seem to make sense. There are no dates before 
2006-01-01 and none from the future (aside from the upcoming filing dates). The
maximum contribution is for $20,700,000.


```r
nv %>% 
  filter(contribution_amount == max(contribution_amount)) %>% 
  glimpse()
```

```
#> Observations: 1
#> Variables: 24
#> $ contribution_id     <chr> "544130"
#> $ report_id           <chr> "80598"
#> $ candidate_id        <chr> NA
#> $ group_id            <chr> "3708"
#> $ contribution_date   <date> 2018-09-21
#> $ contribution_amount <dbl> 20700000
#> $ contribution_type   <chr> "Monetary Contribution"
#> $ contributor_id      <chr> "268234"
#> $ seeking_office      <chr> NA
#> $ candidate_last      <chr> NA
#> $ candidate_party     <chr> NA
#> $ office              <chr> NA
#> $ jurisdiction        <chr> NA
#> $ report_name         <chr> "CE Report 3"
#> $ election_cycle      <chr> "2018"
#> $ filing_due_date     <date> 2018-10-16
#> $ filed_date          <date> 2018-10-16
#> $ report_amended      <lgl> FALSE
#> $ report_superseded   <lgl> FALSE
#> $ group_name          <chr> "Coalition to Defeat Question 3"
#> $ group_type          <chr> "Political Action Committee"
#> $ group_contact       <chr> "Daniel Bravo"
#> $ group_active        <lgl> TRUE
#> $ group_city          <chr> "Las Vegas"
```

### Plot


```r
nv %>% 
  filter(candidate_party == "Democratic Party" |
           candidate_party == "Republican Party" |
             candidate_party == "Nonpartisan" |
                candidate_party == "Unspecified") %>% 
  ggplot(aes(contribution_amount)) +
  geom_histogram(aes(fill = candidate_party)) +
  scale_x_log10() +
  scale_y_log10() +
  scale_fill_manual(values = c("blue", "purple", "red", "black")) +
  theme(legend.position = "none") +
  facet_wrap(~candidate_party) +
  labs(
    title = "Contribution Distribution",
    subtitle = "by political Party",
    y = "Number of Contributions",
    x = "Amount ($USD)"
  )
```

![](../plots/plot_amt_party-1.png)<!-- -->

### Missing

### Duplicates

## Clean

## Conclusion

## Write


```r
write_csv(
  x = nv,
  path = here("nv-contribs", "data", "nv_contribs_clean.csv"),
  na = ""
)
```

