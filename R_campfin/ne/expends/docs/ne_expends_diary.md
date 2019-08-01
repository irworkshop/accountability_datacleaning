Nebraska Expenditures
================
Kiernan Nicholls
2019-08-01 16:43:12

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

Data is obtained by from the Nebraska Board of Examiners’ [Open Data
portal](http://www.nebraska.gov/government/open-data/). From this
portal, we will download the [Campaign Statements
Data](http://www.nebraska.gov/nadc_data/nadc_data.zip) from the
Accountability and Disclosure Commission (NADC).

> A weekly export of the campaign filings based upon the paper records
> filed with the Nebraska Accountability and Disclosure Commission.

## Import

The campaign finance data is provided as a series of text file organized
in a relational database management system (DRMS).

### Download

The data is provided as a ZIP file, which can be downloaded locally.

``` r
raw_dir <- here("ne", "expends", "data", "raw")
dir_create(raw_dir)
```

``` r
if (!all_files_new(raw_dir, "*.zip$")) {
  download.file(
    url = "http://www.nebraska.gov/nadc_data/nadc_data.zip",
    destfile = glue("{raw_dir}/nadc_data.zip")
  )
}
```

We can then unzip the file to the same `/raw` directory.

``` r
if (!all_files_new(glue("{raw_dir}/nadc_data"), "*.txt$")) {
  unzip(
    zipfile = glue("{raw_dir}/nadc_data.zip"),
    exdir = raw_dir
  )
}
```

There are 63 files contained in the unzipped folder.

``` r
raw_files <- dir_ls(glue("{raw_dir}/nadc_data"))
for (file in str_remove(raw_files, raw_dir)) {
    cat("*", file, "\n")
}
```

  - /nadc\_data/DATE\_UPDATED.TXT
  - /nadc\_data/commlatefile.txt
  - /nadc\_data/corplatefile.txt
  - /nadc\_data/forma1.txt
  - /nadc\_data/forma1cand.txt
  - /nadc\_data/forma1misc.txt
  - /nadc\_data/formb1.txt
  - /nadc\_data/formb10.txt
  - /nadc\_data/formb10exp.txt
  - /nadc\_data/formb11.txt
  - /nadc\_data/formb1ab.txt
  - /nadc\_data/formb1c.txt
  - /nadc\_data/formb1c2.txt
  - /nadc\_data/formb1d.txt
  - /nadc\_data/formb1d2.txt
  - /nadc\_data/formb2.txt
  - /nadc\_data/formb2a.txt
  - /nadc\_data/formb2b.txt
  - /nadc\_data/formb3.txt
  - /nadc\_data/formb4.txt
  - /nadc\_data/formb4a.txt
  - /nadc\_data/formb4b1.txt
  - /nadc\_data/formb4b2.txt
  - /nadc\_data/formb4b3.txt
  - /nadc\_data/formb4c.txt
  - /nadc\_data/formb5.txt
  - /nadc\_data/formb6.txt
  - /nadc\_data/formb6cont.txt
  - /nadc\_data/formb6expend.txt
  - /nadc\_data/formb7.txt
  - /nadc\_data/formb72.txt
  - /nadc\_data/formb73.txt
  - /nadc\_data/formb9.txt
  - /nadc\_data/formb9a.txt
  - /nadc\_data/formb9b.txt
  - /nadc\_data/formc1.txt
  - /nadc\_data/formc1inc.txt
  - /nadc\_data/formc1prop.txt
  - /nadc\_data/formc2.txt
  - /nadc\_data/formcfla1.txt
  - /nadc\_data/formcfla2.txt
  - /nadc\_data/formcfla3.txt
  - /nadc\_data/formcfla4.txt
  - /nadc\_data/formcfla5.txt
  - /nadc\_data/formcfla6.txt
  - /nadc\_data/formcfla7.txt
  - /nadc\_data/formcfla8.txt
  - /nadc\_data/formcfla8a.txt
  - /nadc\_data/formcfla8b.txt
  - /nadc\_data/formcfla8c.txt
  - /nadc\_data/formcfla9.txt
  - /nadc\_data/formcfla9ex.txt
  - /nadc\_data/lforma.txt
  - /nadc\_data/lformar.txt
  - /nadc\_data/lformb.txt
  - /nadc\_data/lformbb.txt
  - /nadc\_data/lformc.txt
  - /nadc\_data/lformcc.txt
  - /nadc\_data/lformd.txt
  - /nadc\_data/lforme.txt
  - /nadc\_data/lformf.txt
  - /nadc\_data/loblatefile.txt
  - /nadc\_data/nadc\_tables.rtf

### Read

We can use `purrr::map()` to read each file with `readr::read_delim()`
into a single list.

``` r
ne_files <- 
  map(
    raw_files[2:62],
    read_delim,
    delim = "|",
    col_types = cols(.default = "c"),
    escape_backslash = FALSE,
    escape_double = FALSE
  ) %>% 
  map(clean_names) %>% 
  map(map_dfr, str_trim) %>% 
  set_names(value = tools::file_path_sans_ext(basename(names(.))))
```

## Explore

This list contains 61 data frames, ranging from 2 rows to 121443. The
contents and structure of each data frame is described in the
`/nadc_data/nadc_tables.rtf` text file.

From this file, we know the primary file of interest is named
`/nadc_data/formb1d.txt`. This file contains “Form B-1 Schedule D
Section 1, Expenditures.” The [NADC Form
B-1](http://www.nadc.nebraska.gov/docs/B-1-2018.doc) is used by
candidate and campaign committee’s to report their financial
transactions. Schedule D of that form is used to report expenses, with
Section 1 being finalized expenditures.

> List all payees who were paid more than $250 during this reporting
> period. If multiple payments to the same payee totaled more than $250
> throughout this reporting period, those expenditures must be listed.
> Reporting period refers to your entry on Page 1 under Item 4.
> Expenditures to the same payee over separate reporting periods should
> not be accumulated. Expenditures to the same payee must be listed
> under the same name. If the committee reimburses the candidate or
> engages the services of an advertising agency or another agent of the
> committee for expenses they incurred on behalf of the committee, list
> the payments the committee made to the candidate or agent and also
> list the payments which were made by the candidate or agent on behalf
> of the committee. (E.g., If the candidate makes payments to a
> newspaper for advertising and is reimbursed by the committee, report
> the payments made to the candidate but also list the payments made by
> the candidate to the newspaper. Include the name of the newspaper, and
> the date of each of the expenditures by the candidate and list the
> amount only in the “purpose” box along with the description of the
> expenditure.)

To better understand these expenditures, we can join this table with the
other tables containing information on the reporting committee and
payee.

``` r
ne <- 
  left_join(
    x = ne_files$formb1d,
    y = select(ne_files$formb1, 1:18),
    by = c(
      "committee_id" = "committee_id_number",
      "date_received",
      "committee_name"
    )
  ) %>% 
  mutate(
    date_received = parse_date(date_received, "%m/%d/%Y"),
    expenditure_date = parse_date(expenditure_date, "%m/%d/%Y"),
    amount = parse_number(amount),
    in_kind = parse_number(in_kind),
    date_last_revised = parse_date(date_last_revised, "%m/%d/%Y"),
    postmark_date = parse_date(postmark_date, "%m/%d/%Y"),
    election_date = parse_date(election_date, "%m/%d/%Y"),
    report_start_date = parse_date(report_start_date, "%m/%d/%Y"),
    report_end_date = parse_date(report_end_date, "%m/%d/%Y")
  )
```

``` r
head(ne)
```

    #> # A tibble: 6 x 24
    #>   committee_name committee_id date_received payee_name payee_address expenditure_pur…
    #>   <chr>          <chr>        <date>        <chr>      <chr>         <chr>           
    #> 1 NEBRASKANS FO… 99BQC00006   2000-06-30    SMITH, LES RT 1 BOX 266… <NA>            
    #> 2 NEBRASKANS FO… 99BQC00006   2000-06-30    SUTTON, C… 904 S 153RD … <NA>            
    #> 3 NEBRASKANS FO… 99BQC00006   2000-06-30    TERRELL, … 5209 S 8TH P… <NA>            
    #> 4 NEBRASKANS FO… 99BQC00006   2000-06-30    TIPPERY, … 2000 NORTHRI… <NA>            
    #> 5 NEBRASKANS FO… 99BQC00006   2000-06-30    VON RIEUT… 4221 MARY CI… <NA>            
    #> 6 NEBRASKANS FO… 99BQC00006   2000-06-30    WILSON, R… 3825 SWIFT #… <NA>            
    #> # … with 18 more variables: expenditure_date <date>, amount <dbl>, in_kind <dbl>,
    #> #   committee_address <chr>, committee_type <chr>, committee_city <chr>, committee_state <chr>,
    #> #   committee_zip <chr>, date_last_revised <date>, last_revised_by <chr>, postmark_date <date>,
    #> #   microfilm_number <chr>, election_date <date>, type_of_filing <chr>, nature_of_filing <chr>,
    #> #   additional_ballot_question <chr>, report_start_date <date>, report_end_date <date>

``` r
tail(ne)
```

    #> # A tibble: 6 x 24
    #>   committee_name committee_id date_received payee_name payee_address expenditure_pur…
    #>   <chr>          <chr>        <date>        <chr>      <chr>         <chr>           
    #> 1 RAYBOULD FOR … 15CAC02035   2019-04-01    LAMAR ADV… 5201 SOUTH 1… BILLBOARDS      
    #> 2 CITIZENS FOR … 18CAC02582   2019-04-29    MAVERICK … 19608 HARNEY… MEDIA BUY       
    #> 3 LEIRION FOR L… 18CAC02577   2019-06-17    ADAMS, CH… 661 W. LAKES… PHONE BANKING   
    #> 4 NEBRASKANS FO… 18BQC00475   2019-07-01    EMMA CRAIG 3235 FOLKWAY… SIGNATURE GATHE…
    #> 5 NEBRASKANS FO… 18BQC00475   2019-07-01    MARIJUANA… P.O. BOX 774… STAFF TIME ASSI…
    #> 6 NEBRASKANS FO… 18BQC00475   2019-07-01    RILEY SLE… 4455 N. 1ST … SIGNATURE GATHE…
    #> # … with 18 more variables: expenditure_date <date>, amount <dbl>, in_kind <dbl>,
    #> #   committee_address <chr>, committee_type <chr>, committee_city <chr>, committee_state <chr>,
    #> #   committee_zip <chr>, date_last_revised <date>, last_revised_by <chr>, postmark_date <date>,
    #> #   microfilm_number <chr>, election_date <date>, type_of_filing <chr>, nature_of_filing <chr>,
    #> #   additional_ballot_question <chr>, report_start_date <date>, report_end_date <date>

``` r
glimpse(sample_frac(ne))
```

    #> Observations: 79,402
    #> Variables: 24
    #> $ committee_name             <chr> "JOHNSON FOR MAYOR (DISSOLVED)", "HOEGER FOR COUNTY BOARD", "…
    #> $ committee_id               <chr> "99CAC00002", "99CAC00500", "13CAC01804", "13CAC01828", "99CA…
    #> $ date_received              <date> 1999-03-29, 2000-10-13, 2014-10-28, 2018-04-16, 2004-10-26, …
    #> $ payee_name                 <chr> "SIGNS NOW", "CABLE REP", "GRIFFIN, RYAN", "IMGE", "MAIL SOLU…
    #> $ payee_address              <chr> "5571 S 48TH LINCOLN NE 68516", "11505 WEST DODGE ROAD, OMAHA…
    #> $ expenditure_purpose        <chr> "BUMPER STICKERS, SIGNS", "CABLE TV SPOTS", "PAYROLL", "DIGIT…
    #> $ expenditure_date           <date> 1999-03-05, 2000-09-07, 2014-10-01, 2018-03-13, 2004-04-29, …
    #> $ amount                     <dbl> 367.36, 4078.00, 1011.93, 17470.79, 1533.38, 818.40, NA, 0.00…
    #> $ in_kind                    <dbl> 588.00, 0.00, NA, NA, 0.00, 0.00, 57.80, 57.20, 0.00, NA, 0.0…
    #> $ committee_address          <chr> "4710 NORTH 25TH STREET", "5201 DAVENPORT STREET", "250 N. 3R…
    #> $ committee_type             <chr> "C", "C", "C", "C", "C", "C", "C", "C", "C", "C", "C", "C", "…
    #> $ committee_city             <chr> "LINCOLN", "OMAHA", "LYONS", "LINCOLN", "OMAHA", "COLUMBUS", …
    #> $ committee_state            <chr> "NE", "NE", "NE", "NE", "NE", "NE", "NE", "NE", "NE", "NE", "…
    #> $ committee_zip              <chr> "68521", "68132", "68038", "68508", "68164", "68601", "68503"…
    #> $ date_last_revised          <date> 2007-02-16, 2007-02-16, 2017-07-31, 2019-04-04, 2007-02-16, …
    #> $ last_revised_by            <chr> "nadc03", "nadc03", "nadc04", "nadc04", "nadc03", "nadc03", "…
    #> $ postmark_date              <date> 1999-03-29, 2000-10-11, 2014-10-27, 2018-04-16, 2004-10-25, …
    #> $ microfilm_number           <chr> "5680201", "5980142", "9240084", "1100015", "6860210", "63801…
    #> $ election_date              <date> 1999-04-06, 2000-11-07, 2014-11-04, 2018-05-15, 2004-11-02, …
    #> $ type_of_filing             <chr> "P", "G", "G", "P", "G", "P", "O", "G", "P", "A", "P", "A", "…
    #> $ nature_of_filing           <chr> "10", "30", "10", "30", "10", "30", "FS", "30", "40", NA, "40…
    #> $ additional_ballot_question <chr> "L", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ report_start_date          <date> 1999-03-03, 2000-04-01, 2014-10-01, 2018-01-01, 2004-09-29, …
    #> $ report_end_date            <date> 1999-03-22, 2000-10-03, 2014-10-20, 2018-04-10, 2004-10-18, …

### Missing

``` r
glimpse_fun(ne, count_na)
```

    #> # A tibble: 24 x 4
    #>    var                        type      n        p
    #>    <chr>                      <chr> <int>    <dbl>
    #>  1 committee_name             chr       8 0.000101
    #>  2 committee_id               chr       0 0       
    #>  3 date_received              date      0 0       
    #>  4 payee_name                 chr      56 0.000705
    #>  5 payee_address              chr   11951 0.151   
    #>  6 expenditure_purpose        chr    2827 0.0356  
    #>  7 expenditure_date           date      0 0       
    #>  8 amount                     dbl    9981 0.126   
    #>  9 in_kind                    dbl   42298 0.533   
    #> 10 committee_address          chr     951 0.0120  
    #> 11 committee_type             chr     950 0.0120  
    #> 12 committee_city             chr     950 0.0120  
    #> 13 committee_state            chr     950 0.0120  
    #> 14 committee_zip              chr     950 0.0120  
    #> 15 date_last_revised          date    950 0.0120  
    #> 16 last_revised_by            chr     950 0.0120  
    #> 17 postmark_date              date  14930 0.188   
    #> 18 microfilm_number           chr   11255 0.142   
    #> 19 election_date              date    976 0.0123  
    #> 20 type_of_filing             chr    2339 0.0295  
    #> 21 nature_of_filing           chr   25022 0.315   
    #> 22 additional_ballot_question chr   77120 0.971   
    #> 23 report_start_date          date    951 0.0120  
    #> 24 report_end_date            date    950 0.0120

### Duplicates

``` r
ne_dupes <- distinct(get_dupes(ne))
```

``` r
ne <- ne %>% 
  left_join(ne_dupes) %>% 
  mutate(dupe_flag = !is.na(dupe_count)) %>% 
  select(-dupe_count)
```

### Categorical

### Continuous

## Wrangle
