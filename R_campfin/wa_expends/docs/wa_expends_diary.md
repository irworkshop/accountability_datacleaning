---
title: "Data Diary"
subtitle: "Washington Expenditures"
author: "Kiernan Nicholls"
date: "2019-06-18 12:54:59"
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
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  magrittr, # pipe opperators
  RSocrata, # read SODA APIs
  janitor, # dataframe clean
  zipcode, # clean & databse
  batman, # parse yes & no
  refinr, # cluster & merge
  rvest, # scrape website
  knitr, # knit documents
  here, # locate storage
  fs # search storage 
)
```



This document should be run as part of the `R_campfin` project, which lives as a sub-directory
of the more general, language-agnostic `irworkshop/accountability_datacleaning` 
[GitHub repository](https://github.com/irworkshop/accountability_datacleaning).

The `R_campfin` project uses the 
[RStudio projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects)
feature and should be run as such. The project also uses the dynamic 
[`here::here()`](https://github.com/jennybc/here_here) tool for
file paths relative to _your_ machine.


```r
# where was this document knit?
here::here()
#> [1] "/home/ubuntu/R/accountability_datacleaning/R_campfin"
```

## Data

This dataset comes courtesy of the State of 
[Washington Public Disclosure Commission](http://www.pdc.wa.gov), acces through the [data.wa.gov](https://data.wa.gov) portal.

The resource is named `exenditures_by_candidates_and_political_committees` and covers the last 10
years of data, updates daily. Each records represents a single "Expenditure by a campaign or
committee."

### About

> This dataset contains expenditures made by Washington State Candidates and Political Committees
for the last 10 years as reported to the PDC on forms C3, C4, Schedule C and their electronic
filing equivalents.
> 
> In-kind contributions are included in this data set as they are considered as both a contribution
and expenditure. In-kind contributions are also included in the data set "Contributions to
Candidates and Political Committees."
> 
> For candidates, the number of years is determined by the year of the election, not necessarily the
year the expenditure was reported. For political committees, the number of years is determined by
the calendar year of the reporting period.
> 
> Candidates and political committees choosing to file under "mini reporting" are not included in
this dataset. See WAC 390-16-105 for information regarding eligibility.
> 
> This dataset is a best-effort by the PDC to provide a complete set of records as described
herewith and may contain incomplete or incorrect information. The PDC provides access to the
original reports for the purpose of record verification.
> 
> Descriptions attached to this dataset do not constitute legal definitions; please consult RCW
42.17A and WAC Title 390 for legal definitions and additional information regarding political
finance disclosure requirements.
> 
> CONDITION OF RELEASE: This publication constitutes a list of individuals prepared by the
Washington State Public Disclosure Commission and may not be used for commercial purposes. This
list is provided on the condition and with the understanding that the persons receiving it agree to
this statutorily imposed limitation on its use. See RCW 42.56.070(9) and AGO 1975 No. 15.

### Variables

The [Data.WA API page](https://dev.socrata.com/foundry/data.wa.gov/ukxb-bc7h) provides definitions
for the variables provided in this dataset.

`id`:

> PDC internal identifier that corresponds to a single expenditure record. When combined with the
origin value, this number uniquely identifies a single row.

`report_number`:

> PDC identifier used for tracking the individual form C4 . Multiple expenditures will have the
same report number when they were reported to the PDC at the same time. The report number is unique
to the report it represents. When a report is amended, a new report number is assigned that
supersedes the original version and the original report records are not included in this dataset.

`origin`:

> This field shows from which filed report-type the data originates. A/LE50 refers to non-itemized
expenditures of $50 and less per expenditure. A/GT50 refers to itemized expenditures greater than
$50 per expenditure. A/LE50 and A/GT50 are both reported on schedule A of form C4
>
> To view the different report types and forms browse to:https://www.pdc.wa.gov/learn/forms

`filer_id`:

> The unique id assigned to a candidate or political committee. The filer id is consistent across
election years with the exception that an individual running for a second office in the same
election year will receive a second filer id. There is no correlation between the two filer ids.
For a candidate and single-election-year committee such as a ballot committee, the combination of
filerid and electionyear uniquely identifies a campaign.

`type`:

> Indicates if this record is for a candidate or a political committee. In the case of a political
committee, it may be either a continuing political committee, party committee or single election
year committee.

`filer_name`:

> The candidate or committee name as reported on the form C1 candidate or committee registration
form. The name will be consistent across all records for the same filer id and election year but
may differ across years due to candidates or committees changing their name.

`id`:

> This field represents the first name, as reported by the filer. This field may appear blank if
the name is not reported or if a filing entity has a single name, such as a PAC or other political
committee. Note that this data appears as represented by the filer and may not be consistent from
one reporting period to another.

`last_name`:

> This field represents the last name, as reported by the filer. The field may also contain the
full name of a filing entity that is registered under one name, such as a PAC or other filing
committee. Note that this data appears as represented by the filer and may not be consistent from
one reporting period to another.

`office`:

> The office sought by the candidate. Does not apply to political committees.

`legislative_district`:

> The Washington State legislative district. This field only applies to candidates where the office
is "state senator" or "state representative."

`position`:

> The position associated with an office. This field typically applies to judicial and local office
that have multiple positions or seats. This field does not apply to political committees.

`party`:

> The political party as declared by the candidate or committee on their form C1 registration.
Contains only "Major parties" as recognized by Washington State law.

`ballot_number`:

> If the committee is a Statewide Ballot Initiative Committee a ballot number will appear once a
ballot number is assigned by the Secretary of State. Local Ballot Initiatives will not have a
ballot number. This field will contain a number only if the Secretary of State issues a number.

`for_or_against`:

> Ballot initiative committees are formed to either support or oppose an initiative. This field
represents whether a committee “Supports” or “Opposes” a ballot initiative.

`jurisdiction_*`:

> The political jurisdiction associated with the office of a candidate.

> The county associated with the jurisdiction of a candidate. Multi-county jurisdictions as
reported as the primary county. This field will be empty for political committees and when a
candidate jurisdiction is statewide.

> The type of jurisdiction this office is: Statewide, Local, etc.

`election_year`:

> The election year in the case of candidates and single election committees. The reporting year in
the case of continuing political committees.

`amount`:

> The amount of the expenditure or in-kind contribution. In-kind contributions are both a
contribution and an expenditure and represented in both the contributions and expenditures data.

`itemized_or_non_itemized`:

> A record for an itemized expenditure represents a single expenditure. A record for a non-itemized
expenditure represents one or more expenditures where the individual expenditures are less than the
limit for itemized reporting. In this case the record is the aggregate total for the reporting
period.

`expenditure_date`:

> The date that the expenditure was made or the in-kind contribution was received. See the metadata
for the origin and amount field regarding in-kind contributions.

:`code`

> The type of expenditure. The values displayed are human readable equivalents of the type codes reported on the form C4 schedule A. Please refer to the form for a listing of all codes. Itemized expenditures are generally required to have either a code or a description but may be required to have both. Non-itemized expenditures do not have a description. 

`recipient_name`:

> The name of the individual or vendor paid as reported. The names appearing here have not been normalized and the same entity may be represented by different names in the dataset. Non-itemized expenditures of $50 or less will have a recepient_name of EXPENSES OF $50 OR LESS and origin of A/LE50, and all address fields will be empty.

`recipient_*`"

> The street address of the individual or vendor paid as reported.

> The city of the individual or vendor paid as reported.

> The state of the individual or vendor paid as reported.

> The zip code of the individual or vendor paid as reported.

`url`"

> A link to a PDF version of the original report as it was filed to the PDC.

`recipient_location`"

> The geocoded location of the individual or vendor paid as reported. The quality of the geocoded
location is dependent on how many of the address fields are available and is calculated using a
third-party service. The PDC has not verified the results of the geocoding. Please refer to the
recipient_name field for more information regarding address fields.

## Read

> The [Socrata Open Data API (SODA)](http://dev.socrata.com/) provides programmatic access to this
dataset including the ability to filter, query, and aggregate data. For more more information, view
the [API docs for this dataset](https://dev.socrata.com/foundry/data.wa.gov/ukxb-bc7h) or visit our
[developer portal](http://dev.socrata.com/)

If an _recent_ version of the file doesn't exist locally, the `RSocrata::read.socrate()` function
can read the SODA dataset directly from the API into R.


```r
wa_filename <- here(
  "wa_expends", "data", "raw", 
  "exenditures_by_candidates_and_political_committees.csv"
)  
if (file.exists(wa_filename) & as_date(file.mtime(wa_filename)) == today()) {
  wa <- read_csv(
    file = wa_filename,
    col_types = cols(.default = col_character())
  )
  read_from_soda = FALSE
} else {
  wa <- as_tibble(read.socrata("https://data.wa.gov/resource/ukxb-bc7h.json"))
  read_from_soda = TRUE
}
wa$amount <- parse_number(wa$amount)
wa$election_year <- parse_number(wa$election_year)
wa$expenditure_date <- as_date(wa$expenditure_date)
```

If the file had to be downloaded from the SODA API, save a copy of the raw data locally. Each
`recipient_location.coordinates` value is a list type, so they will have to be converted to
character vectors before being saved as a flat text file.


```r
dir_create(here("wa_expends", "data", "raw"))
if (read_from_soda) {
  wa %>% 
    mutate(recipient_location.coordinates = as.character(recipient_location.coordinates)) %>% 
    write_csv(
      path = wa_filename,
      na = ""
    )
}
```

Before working with the data in R, some binary character type variables will be converted to
logical variables. The coordinates character string will also be seperated and converted to numeric
latitude and longitude variables.s


```r
wa <- wa %>% 
  separate(
    col = recipient_location.coordinates,
    into = c("recipient_longitude", "recipient_latitude"),
    sep = ",\\s",
    remove = TRUE
  ) %>% 
  mutate(
    recipient_longitude = as.double(str_remove(recipient_longitude, "c\\(")),
    recipient_latitude = as.double(str_remove(recipient_latitude, "\\)")),
    expenditure_itemized = itemized_or_non_itemized == "Itemized",
    filer_supports = for_or_against == "For",
  ) %>% 
  select(
    -itemized_or_non_itemized,
    -for_or_against
  )
```

## Explore

There are 768420 records of 34 variables in the full database.


```r
sample_frac(wa)
```

```
#> # A tibble: 768,420 x 34
#>    id    report_number origin filer_id type  filer_name first_name middle_initial last_name office
#>    <chr> <chr>         <chr>  <chr>    <chr> <chr>      <chr>      <chr>          <chr>     <chr> 
#>  1 9686… 100632154     A/GT50 INSLJ  … Cand… INSLEE JA… JAY        R              INSLEE    GOVER…
#>  2 9308… 100607890     A/LE50 ORMST  … Cand… ORMSBY TI… TIMM       S              ORMSBY    STATE…
#>  3 1339… 100910786     A/GT50 CLALDC … Poli… CLALLAM C… <NA>       <NA>           CLALLAM … <NA>  
#>  4 4361… 100274273     A/GT50 ROSSD  … Cand… ROSSI DIN… DINO       J              ROSSI     GOVER…
#>  5 4598… 100282058     A/GT50 NASSC  … Cand… ROLFES CH… CHRISTINE  N              ROLFES    STATE…
#>  6 1152… 100777925     A/GT50 LEVEH  … Cand… LEVER HAR… HARLEY     <NA>           LEVER     MAYOR 
#>  7 9558… 100620152     A/GT50 SERVA  … Cand… SERVICE A… ANSON      L              SERVICE   STATE…
#>  8 6635… 100421521     A/GT50 CLALRP … Poli… CLALLAM C… <NA>       <NA>           CLALLAM … <NA>  
#>  9 3672… 100481201     B.1    PIDGS  … Cand… PIDGEON S… STEPHEN    W              PIDGEON   ATTOR…
#> 10 7796… 100498744     A/GT50 BIG IP … Poli… BIG I PAC  <NA>       <NA>           BIG I PAC <NA>  
#> # … with 768,410 more rows, and 24 more variables: position <chr>, party <chr>,
#> #   jurisdiction <chr>, jurisdiction_county <chr>, jurisdiction_type <chr>, election_year <dbl>,
#> #   amount <dbl>, expenditure_date <date>, description <chr>, recipient_name <chr>,
#> #   recipient_address <chr>, recipient_city <chr>, recipient_state <chr>, recipient_zip <chr>,
#> #   url_description <chr>, url <chr>, recipient_location.type <chr>, recipient_longitude <dbl>,
#> #   recipient_latitude <dbl>, legislative_district <chr>, code <chr>, ballot_number <chr>,
#> #   expenditure_itemized <lgl>, filer_supports <lgl>
```

```r
glimpse(sample_frac(wa))
```

```
#> Observations: 768,420
#> Variables: 34
#> $ id                      <chr> "752945.expn", "697271.expn", "734569.expn", "664109.expn", "337…
#> $ report_number           <chr> "100487202", "100446182", "100477099", "100421675", "100219685",…
#> $ origin                  <chr> "A/GT50", "A/GT50", "A/GT50", "A/GT50", "A/GT50", "A/LE50", "A/G…
#> $ filer_id                <chr> "WOLFC  501", "WORKWP 103", "WRIGL  223", "STUCB  201", "PLACH  …
#> $ type                    <chr> "Candidate", "Political Committee", "Candidate", "Candidate", "C…
#> $ filer_name              <chr> "WOLFE CATHY M", "WORKING WA PAC", "WRIGHT LINDA M", "STUCKART B…
#> $ first_name              <chr> "CATHY", NA, "LINDA", "BEN", "HOLLY", "BAATSEBA", NA, NA, "ROBER…
#> $ middle_initial          <chr> "M", NA, "M", "T", "A", "D", NA, NA, "M", NA, "R", "C", NA, "E",…
#> $ last_name               <chr> "WOLFE", "WORKING WA PAC", "WRIGHT", "STUCKART", "PLACKETT", "KO…
#> $ office                  <chr> "COUNTY COMMISSIONER", NA, "STATE REPRESENTATIVE", "CITY COUNCIL…
#> $ position                <chr> "01", NA, "01", NA, NA, "01", NA, NA, NA, NA, "02", "02", NA, "0…
#> $ party                   <chr> "DEMOCRAT", NA, "DEMOCRAT", "NON PARTISAN", "NON PARTISAN", "REP…
#> $ jurisdiction            <chr> "THURSTON CO", NA, "LEG DISTRICT 39 - HOUSE", "CITY OF SPOKANE",…
#> $ jurisdiction_county     <chr> "THURSTON", NA, "SNOHOMISH", "SPOKANE", "KING", "COWLITZ", NA, N…
#> $ jurisdiction_type       <chr> "Local", NA, "Legislative", "Local", "Local", "Legislative", NA,…
#> $ election_year           <dbl> 2012, 2011, 2012, 2011, 2007, 2012, 2010, 2019, 2012, 2018, 2014…
#> $ amount                  <dbl> 100.00, 2844.00, 71.11, 550.00, 100.00, 199.66, 800.00, 3000.00,…
#> $ expenditure_date        <date> 2012-08-06, 2011-12-07, 2012-06-17, 2011-06-07, 2007-07-05, 201…
#> $ description             <chr> "MISAPPLIED DONATION, REDOING TO INDIVIDUAL CONTACT.", "IE-DIREC…
#> $ recipient_name          <chr> "SANDRA AND FRED ROMERO", "WINPOWER STRATEGIES", "STAPLES", "SPO…
#> $ recipient_address       <chr> "2023 WESTLAKE DRIVE SE", "1402 THIRD AVENUE, #505", "105 - 4TH …
#> $ recipient_city          <chr> "LACEY", "SEATTLE", "MARYSVILLE", "SPOKANE", "BELLEVUE", NA, "SP…
#> $ recipient_state         <chr> "WA", "WA", "WA", "WA", "WA", NA, "WA", "WA", "VT", "GA", "WA", …
#> $ recipient_zip           <chr> "98503", "98101", "98270", "99260", "98004", NA, "99201", "98501…
#> $ url_description         <chr> "View report", "View report", "View report", "View report", "Vie…
#> $ url                     <chr> "https://web.pdc.wa.gov/rptimg/default.aspx?batchnumber=10048720…
#> $ recipient_location.type <chr> "Point", "Point", "Point", "Point", "Point", NA, "Point", "Point…
#> $ recipient_longitude     <dbl> -122.83767, -122.33679, -122.17655, -117.42971, -122.20067, NA, …
#> $ recipient_latitude      <dbl> 47.02734, 47.60909, 48.05183, 47.66716, 47.61038, NA, 47.65641, …
#> $ legislative_district    <chr> NA, NA, "39", NA, NA, "19", NA, NA, NA, NA, "26", "27", NA, "45"…
#> $ code                    <chr> NA, "Independent Expenditures", NA, NA, NA, NA, NA, "Broadcast A…
#> $ ballot_number           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "940", NA, NA, NA, NA, NA, N…
#> $ expenditure_itemized    <lgl> TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, TRU…
#> $ filer_supports          <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, TRUE, NA, NA, NA, NA, NA, NA…
```

### Distinct

The variables range in their degree of distinctness.

The `id` is 100% distinct and can be used to
identify a unique transaction.


```r
wa %>% 
  map(n_distinct) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_distinct") %>% 
  mutate(prop_distinct = round(n_distinct / nrow(wa), 4)) %>%
  print(n = length(wa))
```

```
#> # A tibble: 34 x 3
#>    variable                n_distinct prop_distinct
#>    <chr>                        <int>         <dbl>
#>  1 id                          768420        1     
#>  2 report_number               109018        0.142 
#>  3 origin                           6        0     
#>  4 filer_id                      5977        0.0078
#>  5 type                             2        0     
#>  6 filer_name                    6253        0.0081
#>  7 first_name                    1187        0.0015
#>  8 middle_initial                  27        0     
#>  9 last_name                     4785        0.0062
#> 10 office                          44        0.0001
#> 11 position                        67        0.0001
#> 12 party                            8        0     
#> 13 jurisdiction                   527        0.0007
#> 14 jurisdiction_county             39        0.0001
#> 15 jurisdiction_type                5        0     
#> 16 election_year                   17        0     
#> 17 amount                      118028        0.154 
#> 18 expenditure_date              5088        0.0066
#> 19 description                 203508        0.265 
#> 20 recipient_name              105715        0.138 
#> 21 recipient_address           108901        0.142 
#> 22 recipient_city                3977        0.0052
#> 23 recipient_state                 72        0.0001
#> 24 recipient_zip                 4983        0.0065
#> 25 url_description                  1        0     
#> 26 url                         109018        0.142 
#> 27 recipient_location.type          2        0     
#> 28 recipient_longitude          45234        0.0589
#> 29 recipient_latitude           44240        0.0576
#> 30 legislative_district            51        0.0001
#> 31 code                            15        0     
#> 32 ballot_number                  101        0.0001
#> 33 expenditure_itemized             2        0     
#> 34 filer_supports                   3        0
```

The `*_id` variables have as many distinct values as the length of their respective tables.




```
#> # A tibble: 6 x 4
#>   origin      n    percent valid_percent
#>   <chr>   <dbl>      <dbl>         <dbl>
#> 1 A/GT50 571130 0.743            0.743  
#> 2 A/LE50 107058 0.139            0.139  
#> 3 B.1     76230 0.0992           0.0992 
#> 4 C.2     10682 0.0139           0.0139 
#> 5 C.3      3319 0.00432          0.00432
#> 6 <NA>        1 0.00000130      NA
```

```
#> # A tibble: 2 x 3
#>   type                     n percent
#>   <chr>                <dbl>   <dbl>
#> 1 Candidate           424713   0.553
#> 2 Political Committee 343707   0.447
```

```
#> # A tibble: 44 x 4
#>    office                     n percent valid_percent
#>    <chr>                  <dbl>   <dbl>         <dbl>
#>  1 <NA>                  343710  0.447        NA     
#>  2 STATE REPRESENTATIVE  118408  0.154         0.279 
#>  3 CITY COUNCIL MEMBER    67525  0.0879        0.159 
#>  4 STATE SENATOR          50190  0.0653        0.118 
#>  5 COUNTY COMMISSIONER    24058  0.0313        0.0566
#>  6 GOVERNOR               20805  0.0271        0.0490
#>  7 MAYOR                  19765  0.0257        0.0465
#>  8 COUNTY COUNCIL MEMBER  19412  0.0253        0.0457
#>  9 SUPERIOR COURT JUDGE   13514  0.0176        0.0318
#> 10 PORT COMMISSIONER       9315  0.0121        0.0219
#> # … with 34 more rows
```

```
#> # A tibble: 67 x 4
#>    position      n percent valid_percent
#>    <chr>     <dbl>   <dbl>         <dbl>
#>  1 <NA>     494698 0.644         NA     
#>  2 01        91647 0.119          0.335 
#>  3 02        87353 0.114          0.319 
#>  4 03        25182 0.0328         0.0920
#>  5 05        13204 0.0172         0.0482
#>  6 04        13099 0.0170         0.0479
#>  7 06        12559 0.0163         0.0459
#>  8 07         9291 0.0121         0.0339
#>  9 08         5527 0.00719        0.0202
#> 10 09         3953 0.00514        0.0144
#> # … with 57 more rows
```

```
#> # A tibble: 8 x 4
#>   party                   n   percent valid_percent
#>   <chr>               <dbl>     <dbl>         <dbl>
#> 1 <NA>               346482 0.451        NA        
#> 2 NON PARTISAN       160340 0.209         0.380    
#> 3 DEMOCRAT           135835 0.177         0.322    
#> 4 REPUBLICAN         119699 0.156         0.284    
#> 5 OTHER                3497 0.00455       0.00829  
#> 6 INDEPENDENT          1967 0.00256       0.00466  
#> 7 LIBERTARIAN           566 0.000737      0.00134  
#> 8 CONSTITUTION PARTY     34 0.0000442     0.0000806
```

```
#> # A tibble: 5 x 4
#>   jurisdiction_type      n percent valid_percent
#>   <chr>              <dbl>   <dbl>         <dbl>
#> 1 <NA>              343710  0.447        NA     
#> 2 Local             189067  0.246         0.445 
#> 3 Legislative       168598  0.219         0.397 
#> 4 Statewide          39718  0.0517        0.0935
#> 5 Judicial           27327  0.0356        0.0643
```

```
#> # A tibble: 17 x 3
#>    election_year     n   percent
#>            <dbl> <dbl>     <dbl>
#>  1          2012 90675 0.118    
#>  2          2018 84131 0.109    
#>  3          2008 83804 0.109    
#>  4          2016 83113 0.108    
#>  5          2010 74598 0.0971   
#>  6          2014 72166 0.0939   
#>  7          2017 51529 0.0671   
#>  8          2013 44444 0.0578   
#>  9          2009 44200 0.0575   
#> 10          2015 43251 0.0563   
#> 11          2007 38201 0.0497   
#> 12          2011 36414 0.0474   
#> 13          2019 17008 0.0221   
#> 14          2020  3986 0.00519  
#> 15          2021   564 0.000734 
#> 16          2022   290 0.000377 
#> 17          2023    46 0.0000599
```

```
#> # A tibble: 2 x 3
#>   expenditure_itemized      n percent
#>   <lgl>                 <dbl>   <dbl>
#> 1 TRUE                 661362   0.861
#> 2 FALSE                107058   0.139
```

```
#> # A tibble: 51 x 4
#>    legislative_district      n percent valid_percent
#>    <chr>                 <dbl>   <dbl>         <dbl>
#>  1 <NA>                 599745 0.780         NA     
#>  2 26                     7446 0.00969        0.0441
#>  3 45                     6496 0.00845        0.0385
#>  4 28                     5810 0.00756        0.0344
#>  5 30                     5797 0.00754        0.0344
#>  6 17                     5726 0.00745        0.0339
#>  7 47                     5229 0.00680        0.0310
#>  8 06                     5111 0.00665        0.0303
#>  9 44                     4834 0.00629        0.0287
#> 10 10                     4584 0.00597        0.0272
#> # … with 41 more rows
```

```
#> # A tibble: 15 x 4
#>    code                          n  percent valid_percent
#>    <chr>                     <dbl>    <dbl>         <dbl>
#>  1 <NA>                     581768 0.757         NA      
#>  2 Independent Expenditures  51811 0.0674         0.278  
#>  3 Operation and Overhead    40160 0.0523         0.215  
#>  4 Broadcast Advertising     17863 0.0232         0.0957 
#>  5 Contributions             14928 0.0194         0.0800 
#>  6 Wages and Salaries        13120 0.0171         0.0703 
#>  7 Management Services       11667 0.0152         0.0625 
#>  8 Other Advertising          8721 0.0113         0.0467 
#>  9 Travel                     7726 0.0101         0.0414 
#> 10 Postage                    7220 0.00940        0.0387 
#> 11 Literature                 5597 0.00728        0.0300 
#> 12 Fundraising                4611 0.00600        0.0247 
#> 13 Surveys and Polls          1669 0.00217        0.00894
#> 14 Printed Advertising        1102 0.00143        0.00590
#> 15 Signature Gathering         457 0.000595       0.00245
```

```
#> # A tibble: 3 x 4
#>   filer_supports      n percent valid_percent
#>   <lgl>           <dbl>   <dbl>         <dbl>
#> 1 NA             705825  0.919         NA    
#> 2 TRUE            52725  0.0686         0.842
#> 3 FALSE            9870  0.0128         0.158
```

![](../plots/plot_origin_bar-1.png)<!-- -->

![](../plots/plot_type_bar-1.png)<!-- -->

![](../plots/plot_party_bar-1.png)<!-- -->

![](../plots/plot_jurisdiction_bar-1.png)<!-- -->

![](../plots/plot_election_year_bar-1.png)<!-- -->

![](../plots/plot_itemized_bar-1.png)<!-- -->

![](../plots/plot_code_bar-1.png)<!-- -->

![](../plots/plot_supports_bar-1.png)<!-- -->

### Missing

The variables also vary in their degree of values that are `NA` (missing).


```r
wa %>% 
  map(function(var) sum(is.na(var))) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_na") %>% 
  mutate(prop_na = n_na / nrow(wa)) %>% 
  print(n = length(wa))
```

```
#> # A tibble: 34 x 3
#>    variable                  n_na    prop_na
#>    <chr>                    <int>      <dbl>
#>  1 id                           0 0         
#>  2 report_number                0 0         
#>  3 origin                       1 0.00000130
#>  4 filer_id                     0 0         
#>  5 type                         0 0         
#>  6 filer_name                   0 0         
#>  7 first_name              343878 0.448     
#>  8 middle_initial          388147 0.505     
#>  9 last_name                   95 0.000124  
#> 10 office                  343710 0.447     
#> 11 position                494698 0.644     
#> 12 party                   346482 0.451     
#> 13 jurisdiction            326336 0.425     
#> 14 jurisdiction_county     379250 0.494     
#> 15 jurisdiction_type       343710 0.447     
#> 16 election_year                0 0         
#> 17 amount                       0 0         
#> 18 expenditure_date           351 0.000457  
#> 19 description             109666 0.143     
#> 20 recipient_name              20 0.0000260 
#> 21 recipient_address       137007 0.178     
#> 22 recipient_city          130571 0.170     
#> 23 recipient_state         127214 0.166     
#> 24 recipient_zip           134427 0.175     
#> 25 url_description              0 0         
#> 26 url                          0 0         
#> 27 recipient_location.type 158199 0.206     
#> 28 recipient_longitude     158199 0.206     
#> 29 recipient_latitude      158199 0.206     
#> 30 legislative_district    599745 0.780     
#> 31 code                    581768 0.757     
#> 32 ballot_number           732677 0.953     
#> 33 expenditure_itemized         0 0         
#> 34 filer_supports          705825 0.919
```

We will flag any records with missing values in the key variables used to identify an expenditure.


```r
sum(is.na(wa$filer_name))
```

```
#> [1] 0
```

```r
sum(is.na(wa$recipient_name))
```

```
#> [1] 20
```

```r
sum(is.na(wa$amount))
```

```
#> [1] 0
```

```r
sum(is.na(wa$expenditure_date))
```

```
#> [1] 351
```

```r
wa <- wa %>% 
  mutate(
    na_flag = is.na(expenditure_date) | is.na(recipient_name)
  )

wa %>% 
  filter(na_flag) %>%
  sample_frac() %>% 
  select(
    na_flag,
    id, 
    report_number,
    filer_name,
    recipient_name,
    amount,
    expenditure_date
    )
```

```
#> # A tibble: 365 x 7
#>    na_flag id        report_number filer_name           recipient_name      amount expenditure_date
#>    <lgl>   <chr>     <chr>         <chr>                <chr>                <dbl> <date>          
#>  1 TRUE    426518.e… 1001268229    LJUNGHAMMAR KEITH N  SWEENEY JOHN          37   NA              
#>  2 TRUE    955786.e… 1001290548    MCPHEETERS LESTER A… Expenses of $50 or…  309.  NA              
#>  3 TRUE    495586.e… 100301580     WA ASSN MORTGAGE BR… Expenses of $50 or…    0   NA              
#>  4 TRUE    525067.e… 1001272964    FLEET HUGO A         Expenses of $50 or…    0   NA              
#>  5 TRUE    428986.e… 100268733     RICHTER DENNIS L     Expenses of $50 or…    0   NA              
#>  6 TRUE    872378.e… 1001288728    MORTON ROBERT H      Expenses of $50 or…    0   NA              
#>  7 TRUE    763220.e… 1001284295    HERDE ERIC P         Expenses of $50 or…   12.9 NA              
#>  8 TRUE    558773.e… 1001275639    YANEZ RODRIGO M      Expenses of $50 or…    0   NA              
#>  9 TRUE    494909.e… 100272741     WA INDEPENDENT BANK… Expenses of $50 or…    0   NA              
#> 10 TRUE    893736.e… 1001289852    EDWARDS FRANKLIN E … Expenses of $50 or…   71.8 NA              
#> # … with 355 more rows
```

### Ranges

The range of continuous variables will need to be checked for data integrity. There are only two
quasi-continuous variables, the `amount` and `expenditure_date`

#### Transaction Amounts

The middle range for `amount` seems reasonable enough.
1.79% percent of `amount` values are less than zero. 


```r
summary(wa$amount)
```

```
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#> -2500000       53      195     1667      729  5000000
```

```r
tabyl(wa$amount > 0)
```

```
#> # A tibble: 2 x 3
#>   `wa$amount > 0`      n percent
#>   <lgl>            <dbl>   <dbl>
#> 1 FALSE            75080  0.0977
#> 2 TRUE            693340  0.902
```


```r
ggplot(wa, aes(amount)) + 
  geom_histogram() + 
  scale_y_log10() +
  scale_x_continuous(labels = scales::dollar) +
  geom_hline(yintercept = 10)
```

![](../plots/plot_amt_nonlog-1.png)<!-- -->

Below are the smallest and largest expenditures.


```r
glimpse(wa %>% filter(amount == min(amount, na.rm = T)))
```

```
#> Observations: 1
#> Variables: 35
#> $ id                      <chr> "23405.corr"
#> $ report_number           <chr> "100441590"
#> $ origin                  <chr> "C.2"
#> $ filer_id                <chr> "YES1183109"
#> $ type                    <chr> "Political Committee"
#> $ filer_name              <chr> "YES ON 1183 COALITION"
#> $ first_name              <chr> NA
#> $ middle_initial          <chr> NA
#> $ last_name               <chr> "YES ON 1183 COALITION"
#> $ office                  <chr> NA
#> $ position                <chr> NA
#> $ party                   <chr> NA
#> $ jurisdiction            <chr> NA
#> $ jurisdiction_county     <chr> NA
#> $ jurisdiction_type       <chr> NA
#> $ election_year           <dbl> 2011
#> $ amount                  <dbl> -2500000
#> $ expenditure_date        <date> 2011-10-17
#> $ description             <chr> "(Reported amount: 8,929,810.00; Corrected amount: 6,429,810.00)…
#> $ recipient_name          <chr> "CORRECTION TO EXPENDITURES"
#> $ recipient_address       <chr> NA
#> $ recipient_city          <chr> NA
#> $ recipient_state         <chr> NA
#> $ recipient_zip           <chr> NA
#> $ url_description         <chr> "View report"
#> $ url                     <chr> "https://web.pdc.wa.gov/rptimg/default.aspx?batchnumber=10044159…
#> $ recipient_location.type <chr> NA
#> $ recipient_longitude     <dbl> NA
#> $ recipient_latitude      <dbl> NA
#> $ legislative_district    <chr> NA
#> $ code                    <chr> NA
#> $ ballot_number           <chr> "1183"
#> $ expenditure_itemized    <lgl> TRUE
#> $ filer_supports          <lgl> TRUE
#> $ na_flag                 <lgl> FALSE
```

```r
glimpse(wa %>% filter(amount == max(amount, na.rm = T)))
```

```
#> Observations: 1
#> Variables: 35
#> $ id                      <chr> "1106020.expn"
#> $ report_number           <chr> "100736208"
#> $ origin                  <chr> "A/GT50"
#> $ filer_id                <chr> "GROCMA 005"
#> $ type                    <chr> "Political Committee"
#> $ filer_name              <chr> "GROCERY MANUFACTURERS ASSN AGAINST I-522"
#> $ first_name              <chr> NA
#> $ middle_initial          <chr> NA
#> $ last_name               <chr> "GROCERY MANUFACTURERS ASSN AGAINST I-522"
#> $ office                  <chr> NA
#> $ position                <chr> NA
#> $ party                   <chr> NA
#> $ jurisdiction            <chr> NA
#> $ jurisdiction_county     <chr> NA
#> $ jurisdiction_type       <chr> NA
#> $ election_year           <dbl> 2013
#> $ amount                  <dbl> 5e+06
#> $ expenditure_date        <date> 2013-09-27
#> $ description             <chr> "CONTRIBUTION"
#> $ recipient_name          <chr> "NO ON I-522 COMMITTEE"
#> $ recipient_address       <chr> "PO BOX 7325"
#> $ recipient_city          <chr> "OLYMPIA"
#> $ recipient_state         <chr> "WA"
#> $ recipient_zip           <chr> "98507"
#> $ url_description         <chr> "View report"
#> $ url                     <chr> "https://web.pdc.wa.gov/rptimg/default.aspx?batchnumber=10073620…
#> $ recipient_location.type <chr> "Point"
#> $ recipient_longitude     <dbl> -122.896
#> $ recipient_latitude      <dbl> 47.04087
#> $ legislative_district    <chr> NA
#> $ code                    <chr> NA
#> $ ballot_number           <chr> "522"
#> $ expenditure_itemized    <lgl> TRUE
#> $ filer_supports          <lgl> FALSE
#> $ na_flag                 <lgl> FALSE
```

We can vew the link provided in the `url` variable to see the smallest expenditure is a correction
to an expenditure to Costco previously reported as \$8,929,810 that should have been \$6,429,810.
Interestingly, this same report shows a _contribution_ from the same Costco for the exact same
amount with the exact same correction. There is no description for the correction.

Using the `url` from the maximum report, the \$5,000,000 expenditure has "contribution" listed in
the "Purpose of Expense" box with nothing put in the spot for "Code" meant to identify the record
as a contribution or expenditure.

These two sample reports can be found as PDF files in the `data/` directory.

### Transaction Dates

There are a number of records with incorrect `expenditure_date` variables. There are no records
with expenditures made in the future, but there are a number of suspicuously old expenditures.


```r
max(wa$expenditure_date, na.rm = TRUE)
```

```
#> [1] "2019-06-17"
```

```r
sum(wa$expenditure_date > today(), na.rm = T)
```

```
#> [1] 0
```

PDC claims that the dataset covers the last 10 years of data, but there are thousands of records
older than that, with one from 1964. The report
containing that expenditure was filed in 2010 and can be found as PDF in the `data/` directory.
That one report is the only one with an expenditure date before 2000, the rest appear to be
correct dates simply outside the expected timespan.


```r
min(wa$expenditure_date, na.rm = TRUE)
```

```
#> [1] "1964-06-11"
```

```r
sum(year(wa$expenditure_date) < 2007, na.rm = T)
```

```
#> [1] 2480
```

![](../plots/plot_exp_year-1.png)<!-- -->

## Clean

## Write
