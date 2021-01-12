---
title: "Data Diary"
subtitle: "Nevada Contributions"
author: "Kiernan Nicholls"
date: "2019-06-11 15:11:49"
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
  refinr, # cluster and merge
  rvest, # scrape web pages
  knitr, # knit documents
  here, # navigate local storage
  fs # search local storage 
)
```



## Data

If the raw data has not been downloaded, it can be retrieved from the 
[Oklahoma Ethics Commision's website](https://www.ok.gov/ethics/public/login.php) as a ZIP archive.

> Everyone has access to the public disclosure system, the only secured access point is the
downloadable raw data option. This option provides an entire database dump in comma separated value
(.csv) or tab delimited (.txt) formats. This secure area is intended for use by the media and
import into an existing database.




```r
if (here("ok_contribs", "data", "raw") %>% any_old_files("*.zip")) {
  download.file(
    url = "https://www.ok.gov/ethics/public/dfile.php?action=csv",
    destfile = here("ok_contribs", "data", "raw", "ethicscsvfile.zip")
  )
}
```

There are 48 individual CSV files contained within the ZIP archive. Many of these files are not
relevant to this project, but all will be unzipped into the `data/raw` directory.


```
#> # A tibble: 48 x 3
#>    Name                         Length Date               
#>    <chr>                         <dbl> <dttm>             
#>  1 affiliation.csv              441445 2019-06-11 01:23:00
#>  2 ballot_measure.csv             1220 2019-06-11 01:23:00
#>  3 business_cont.csv            742467 2019-06-11 01:23:00
#>  4 c1r.csv                     8293148 2019-06-11 01:15:00
#>  5 c3r.csv                       88981 2019-06-11 01:23:00
#>  6 c4r.csv                       91436 2019-06-11 01:15:00
#>  7 c5r.csv                        1311 2019-06-11 01:15:00
#>  8 c6r_basic_info.csv            39081 2019-06-11 01:24:00
#>  9 c6r_electioneering_comm.csv    6752 2019-06-11 01:24:00
#> 10 c6r_receipts.csv             119477 2019-06-11 01:24:00
#> # … with 38 more rows
```

If these files have not yet been unzipped, they will be now.


```r
if (here("ok_contribs", "data", "raw") %>% any_old_files("*.csv")) {
  unzip(
    zipfile = here("ok_contribs", "data", "raw", "ethicscsvfile.zip"),
    exdir = here("ok_contribs", "data", "raw"),
    overwrite = TRUE
  )
}
```

## Read

The data of interest is spread across a number of different files than can be joined along their
respective `*_id` variables. The `transaction.csv` contains the list of contributions and expenses,
and data on those transactions is spread across other tables. 

The relationship between these files is described in the `data/relations_db.xls` Excel file.
Descriptions for each of these files is provided int the `data/descriptions.doc` Word file.

In general, there are three _types_ of files that need to be read and joined together

1. All transactions
    * `transaction.csv`
1. Contributor information
    * `contributor.csv`
      * `cont_type.csv`
    * `individual_cont.csv`
    * `business_cont.csv`
    * `committee_cont.csv`
    * `vendor_cont.csv`
1. Recipient information
    * `so1.csv`
    * `so2.csv`
    * `party.csv`
    * `district.csv`
    * `office.csv`
    * `affiliation.csv`
    * `report.csv`
    * `lump_fund.csv`
    * `surplus.csv`
    * `refund.csv`

They will each be read as data frames using `readr::read_csv()`. All files contain an erroneous
trailing column in the header resulting in an empty column that will be removed. All variable names
will be made "clean" (lowercase and snake_case) using `janitor::clean_names()`.

### Transactions

> Holds all the contribution and expenditure transactions. Has the transaction date, amount, the contributor id and report number (report_num) that it ties back to in the report table.


```r
transactions <- read_csv(
  file = "ok_contribs/data/raw/transaction.csv",
  col_types = cols(
    TRANS_INDEX = col_character(),
    TRANSACTION_DATE = col_date("%d-%b-%y"),
    CONTRIBUTOR_ID = col_character(),
    TRANS_AMOUNT = col_double(),
    REP_NUM = col_character()
  )
)

transactions <- transactions %>% 
  select(-X6) %>% 
  clean_names() %>% 
  rename(
    cont_id = contributor_id,
    trans_date = transaction_date
    )

print(transactions)
```

```
#> # A tibble: 1,729,262 x 5
#>    trans_index trans_date cont_id trans_amount rep_num
#>    <chr>       <date>     <chr>          <dbl> <chr>  
#>  1 13894       2003-05-30 3228             5   1063   
#>  2 13895       2003-05-30 3939            25   1063   
#>  3 13898       2003-05-16 3235            57.0 1063   
#>  4 13899       2003-05-30 3235            57.0 1063   
#>  5 13900       2003-05-30 3675             7   1063   
#>  6 13901       2003-05-16 3246            10   1063   
#>  7 13902       2003-05-30 3246            10   1063   
#>  8 13903       2003-05-30 3249             1   1063   
#>  9 13904       2003-05-16 3251            25   1063   
#> 10 13905       2003-05-30 3251            25   1063   
#> # … with 1,729,252 more rows
```

### Contributors

> Holds address, phone and type of any contributor using [`contributor_id`] as its identifier in
other tables.


```r
contributors <- read_csv(
  file = "ok_contribs/data/raw/contributor.csv",
  col_types = cols(.default = col_character())
)

contributors <- contributors %>%
  select(-X9, -PHONE, -EXT) %>% 
  clean_names() %>% 
  rename(
    cont_id = contributor_id,
    cont_type = type,
    cont_street = street,
    cont_city = city,
    cont_state = state,
    cont_zip = zip
  )

print(contributors)
```

```
#> # A tibble: 402,235 x 6
#>    cont_id cont_type cont_street           cont_city  cont_state cont_zip  
#>    <chr>   <chr>     <chr>                 <chr>      <chr>      <chr>     
#>  1 9892    1         651 Angus Rd          Wilson     OK         73463-9525
#>  2 30273   1         3931 Rolling Hills Dr Ardmore    OK         73401     
#>  3 30274   1         196 High Chaparal Dr  Ardmore    OK         73401     
#>  4 30277   1         2209 Oakglen          Ardmore    OK         73401     
#>  5 30282   1         1614 Southern Hills   Ardmore    OK         73401     
#>  6 30283   1         PO Box 271            Mannsville OK         73447-0271
#>  7 30285   1         504 Portico Ave       Ardmore    OK         73401     
#>  8 10112   1         RR 3 Box 177          Ardmore    OK         73401-9682
#>  9 10113   1         828 Pershing Dr W     Ardmore    OK         73401-3411
#> 10 10132   1         716 Campbell St       Ardmore    OK         73401-1508
#> # … with 402,225 more rows
```

> Holds the different contributor types available (Individual, Business, Committee, Vendor)


```r
cont_types <- read_csv(
  file = "ok_contribs/data/raw/cont_type.csv",
  col_types = cols(.default = col_character())
)

cont_types <- cont_types %>%
  select(-X3) %>% 
  clean_names()
```

#### Individual Contributors

> Holds information relating to any individual contributor. Name, employer and occupation. Contributor id is the key that goes back to the contributor table and into either the transaction table for a transaction list or contributor aggregate table for tie ins to the `ethics_num` (committee) with aggregate totals.


```r
individual_conts <- read_csv(
  file = "ok_contribs/data/raw/individual_cont.csv",
  col_types = cols(.default = col_character())
)

individual_conts <- individual_conts %>% 
  select(-X7) %>% 
  clean_names() %>% 
  rename(
    cont_id = contributor_id,
    cont_employer = employer,
    cont_occupation = occupation
  )
```

#### Business Contributors

> Holds the business name (`cont_name`) and business activity of a business contributor.
Contributor id is the key that goes back to the contributor table and into either the transaction
table for a transaction list or contributor aggregate table for tie ins to the `ethics_num`
(committee) with aggregate totals.


```r
business_conts <- read_csv(
  file = "ok_contribs/data/raw/business_cont.csv",
  col_types = cols(.default = col_character())
)

business_conts <- business_conts %>% 
  select(-X4) %>% 
  clean_names() %>% 
  rename(
    cont_bname = cont_name,
    cont_activity = business_activity
    )
```

#### Committee Contributors

> Holds the principal interest, contributor committee name and contributor FEC number and
committees ethics number for any committee contributors (`contributor_id`). Contributor id is the
key that goes back to the contributor table and into either the transaction table for a transaction
list or contributor aggregate table for tie ins to the ethics_num (committee) with aggregate
totals.


```r
committee_conts <- read_csv(
  file = "ok_contribs/data/raw/committee_cont.csv",
  col_types = cols(.default = col_character())
)

committee_conts <- committee_conts %>% 
  select(-X6) %>% 
  clean_names() %>% 
  rename(
    cont_interest = principal_interest,
    cont_id = id,
    ethics_id = ethics_num,
    cont_cname = committee_name
  )
```

#### Vendor Contributors

> Holds the Vendor Contributor name for any expenditure transaction


```r
vendor_conts <- read_csv(
  file = "ok_contribs/data/raw/vendor_cont.csv",
  col_types = cols(.default = col_character())
)

vendor_conts <- vendor_conts %>% 
  select(-X3) %>% 
  clean_names() %>% 
  rename(cont_vname = cont_name)
```

### Recipients

The information on the recipients of each transaction are held in other databases.

### Statement of Organization

The "SO-1" form applies to committees formed to support a political candidate.


```r
so1 <- read_csv(
  file = "ok_contribs/data/raw/so1.csv",
  col_types = cols(
    .default = col_character(),
    STRICKEN_WITHDRAWN = col_logical(),
    ORGANIZATION_DATE = col_date("%m/%d/%Y")
    )
  )

so1 <- so1 %>% 
  select(-X27) %>% 
  clean_names() %>% 
  rename(ethics_id = ethics_num)

# fix logical parse
so1$special_election <- 
  so1$special_election %>% 
  str_replace("yes", "1") %>% 
  str_replace("no", "0") %>% 
  parse_logical()
```

The "SO-2" form applies to committees formed to support non-candidate issues.


```r
so2 <- read_csv(
  file = "ok_contribs/data/raw/so2.csv",
  col_types = cols(
    .default = col_character(),
    ORGANIZATION_DATE = col_date("%m/%d/%Y")
  )
)

so2 <- so2 %>% 
  select(-X15) %>% 
  clean_names() %>% 
  rename(ethics_id = ethics_num)

# fix logical parse
so2$stmnt_of_intent <- 
  so2$stmnt_of_intent %>%
  recode("y" = "1", "n" = "0") %>% 
  parse_logical()
```

#### Affiliation

> Contains the banking information for the SO1 or SO2 that is filed. The rep_num refers to the
appropriate SO1 or SO2 in the Report table. The name, address, street, city, state and zip for the
bank are contained in this table.


```r
affiliations <- read_csv(
  file = "ok_contribs/data/raw/affiliation.csv",
  col_types = cols(.default = col_character())
)

affiliations <- affiliations %>% 
  select(-X8) %>% 
  clean_names()
```

#### Ballot Measures

> Holds the ballot year for the appropriate SO1 or SO2 that is filed. The rep_num refers to the
appropriate SO1 or SO2 in the Report table.


```r
ballot_measures <- read_csv(
  file = "ok_contribs/data/raw/ballot_measure.csv",
  col_types = cols(.default = col_character())
)

ballot_measures <- ballot_measures %>% 
  select(-X3) %>% 
  clean_names()
```

#### Depository

> Holds the full name and address for the depository information for the SO1 or SO2 from the
report_num field that relates to the report table.


```r
depositories <- read_csv(
  file = "ok_contribs/data/raw/depository.csv",
  col_types = cols(.default = col_character())
)

depositories <- depositories %>% 
  select(-X8) %>% 
  clean_names()
```

#### Parties

> Has the different party affiliation types


```r
parties <- read_csv(
  file = "ok_contribs/data/raw/party.csv",
  col_types = cols(
    VIEWABLE = col_logical(),
    PARTY_ID = col_character(),
    PARTY_DESC = col_character()
  )
)

parties <- parties %>% 
  select(-X4) %>% 
  clean_names()
```

#### Offices

> Description of office types (mainly for elections)


```r
offices <- read_csv(
  file = "ok_contribs/data/raw/office.csv",
  col_types = cols(.default = col_character())
)

offices <- offices %>% 
  select(-X3) %>% 
  clean_names() %>% 
  rename(office_id = id)
```

#### Districts

> List of the districts for elections


```r
districts <- read_csv(
  file = "ok_contribs/data/raw/district.csv",
  col_types = cols(.default = col_character())
)

districts <- districts %>% 
  select(-X3) %>% 
  clean_names()
```

#### Candidates

> Holds the candidate name and birthdate tied to the specific ethics_num (committee)


```r
candidates <- read_csv(
  file = "ok_contribs/data/raw/candidate.csv",
  col_types = cols(.default = col_character())
)

candidates <- candidates %>% 
  select(-X6, -BIRTHDATE) %>% 
  clean_names() %>% 
  rename(ethics_id = ethics_num)
```

#### Lump Funds

> Holds lump fund information for the respective report_num


```r
lump_funds <- read_csv(
  file = "ok_contribs/data/raw/lump_fund.csv",
  col_types = cols(
    .default = col_character(),
    LUMP_AMOUNT = col_double(),
    LUMP_DATE = col_date("%d-%b-%y")
    )
)

lump_funds <- lump_funds %>% 
  select(-X8) %>% 
  clean_names()
```

### Report

> Holds all the `report_num` for all filed reports in the system from the SO1, SO2s to all the C1R,
C3R, C4R, and C5R reports. C6R reports are stored in the c6r_report table. Contains the date the
report was submitted, the `ethics_num` (committee) that it ties to, period id, the report type,
signature field, admin entered (means the report was filed by administrator), the amended reference
(if null, is the latest report, if not then that report was amended to the `report_num` that is
displayed in that field.), the final flag determines if that was the final report they will be
filing and `supp_year` is just a field on the form to show the year.


```r
reports <- read_csv(
  file = "ok_contribs/data/raw/report.csv",
  col_types = cols(
    .default = col_character(),
    SUBMITTED_DATE = col_date("%d-%b-%y"),
    FINAL = col_logical()
  )
)

reports <- reports %>% 
  select(-X11) %>% 
  clean_names() %>% 
  rename(ethics_id = ethics_num)
```

> Description of each type of report available  (SO1, SO2, C1R, C3R, C4R, C5R, C6R)


```r
rep_types <- read_csv(
  file = "ok_contribs/data/raw/report_type.csv",
  col_types = cols(.default = col_character())
)

rep_types <- rep_types %>%
  select(-X3) %>% 
  clean_names()
```

## Join

Our primary interest is when a transaction was made, for how much, from whom, and to whom. The
transaction database contains the when and how much, but uses keys to identify the who.

The contributor of a transaction (giving mondey) is identified by the `cont_id` variable.

The recipeint of a transaction (getting money) are the ones filing the report on which each
transaction appears, identifying by the `rep_num` variable. In the database of reports, the filer
of each report is identified with their `ethics_id`.

By joining each transaction with ther filer of the respective report, we can identify the filer.


```r
ok <- transactions %>% 
  left_join(reports %>% select(rep_num, ethics_id))

print(ok)
```

```
#> # A tibble: 1,729,262 x 6
#>    trans_index trans_date cont_id trans_amount rep_num ethics_id
#>    <chr>       <date>     <chr>          <dbl> <chr>   <chr>    
#>  1 13894       2003-05-30 3228             5   1063    203041   
#>  2 13895       2003-05-30 3939            25   1063    203041   
#>  3 13898       2003-05-16 3235            57.0 1063    203041   
#>  4 13899       2003-05-30 3235            57.0 1063    203041   
#>  5 13900       2003-05-30 3675             7   1063    203041   
#>  6 13901       2003-05-16 3246            10   1063    203041   
#>  7 13902       2003-05-30 3246            10   1063    203041   
#>  8 13903       2003-05-30 3249             1   1063    203041   
#>  9 13904       2003-05-16 3251            25   1063    203041   
#> 10 13905       2003-05-30 3251            25   1063    203041   
#> # … with 1,729,252 more rows
```

To improve the searchability of this database of transactions, we will add the name and location
of each contributor and recipient.

### Contributors

First, we will join the `contributors` table, which contains geographic data on each contributor
(city, state, zip), which the full tables of each contributor type.

There are four types of contributors, each identified with different `cont_*name` variables:

1. Individuals with `cont_fname` (first), `cont_mname` (middle), and `cont_lname` (last)
    * With `cont_employer` and `cont_occupation`
1. Businesses with a `cont_bname`
    * With `cont_activity`
1. Committees with a `cont_cname`
    * with `cont_interest` and `ethics_id`
1. Vendors with a `cont_vname`
    * With OK Ethics Commission `ethics_id`
    
It's important to note that the transactions database contains both contributions _and_
expenditures reported by the filer. For expenditures, the "contributor" is actually the vendor
recipient of the money


```r
nrow(contributors)
#> [1] 402235
nrow(individual_conts)
#> [1] 425011
nrow(business_conts)
#> [1] 14718
nrow(committee_conts)
#> [1] 89658
nrow(vendor_conts)
#> [1] 97215

contributors2 <- contributors %>% 
  left_join(individual_conts, by = "cont_id") %>% 
  left_join(business_conts, by = "cont_id") %>% 
  left_join(committee_conts, by = "cont_id") %>% 
  left_join(vendor_conts, by = "cont_id") %>% 
  left_join(cont_types, by = "cont_type")

nrow(contributors2)
#> [1] 402235
```

There appears to be more total contributors than listed in the contributors database. There are
22776 more _individual_ contributors alone than there are
total records in the contributors database.


```r
nrow(individual_conts) - nrow(contributors)
#> [1] 22776
mean(individual_conts$cont_id %in% contributors$cont_id)
#> [1] 0.555868
```

### Recipients

When a committee is formed to recieve contributions, the file a "Stament of Organization" report.
Committees formed to recieve funds on behalf of a candidate file an "SO-1" form, and non-candidate
organizations file an "SO-2" form.

These formn contain a lot of information, but we will extract only the geographic information of
each, so that we can better search the contributions and expenditures in the transactions database.

First, we will create a new table of candidate committee information from the SO-1 database.


```r
candidate_rec <- so1 %>%
  left_join(candidates, by = "ethics_id") %>% 
  left_join(parties, by = c("party_num" = "party_id")) %>% 
  left_join(offices, by = c("office_num" = "office_id")) %>% 
  rename(
    rec_street   = street,
    rec_city     = city,
    rec_state    = state, 
    rec_zip      = zip,
    rec_cname    = comname,
    rec_party    = party_desc,
    rec_office   = office_desc
  ) %>% 
  select(ethics_id, starts_with("rec_")) %>%
  # multiple entries per ethics id
  # make all upper
  mutate_if(is_character, str_to_upper) %>% 
  # take only the first
  group_by(ethics_id) %>% 
  slice(1) %>% 
  ungroup() %>% 
  distinct()

print(candidate_rec)
```

```
#> # A tibble: 2,949 x 8
#>    ethics_id rec_street        rec_city   rec_state rec_zip rec_cname          rec_party rec_office
#>    <chr>     <chr>             <chr>      <chr>     <chr>   <chr>              <chr>     <chr>     
#>  1 100000    TEST              TEST       OK        99999   TEST ACCOUNT       REPUBLIC… SENATE    
#>  2 100001    520 W 8TH ST      EDMOND     OK        73003   SNYDER FOR SENATE… REPUBLIC… SENATE    
#>  3 100002    1010 W QUEEN PL   TULSA      OK        74127   HORNER-RE-ELECTIO… DEMOCRAT  SENATE    
#>  4 100003    2809 N.E. BEL AI… LAWTON     OK        73507   HELTON FOR SENATE… DEMOCRAT  SENATE    
#>  5 100006    2010 W 136TH ST   GLENPOOL   OK        74033   FRIENDS OF L. LON… DEMOCRAT  SENATE    
#>  6 100007    615 TYRONE        WAUKOMIS   OK        73773   ROBERT MILACEK FO… REPUBLIC… SENATE    
#>  7 100008    1700 CHEROKEE PL  BARTLESVI… OK        74003   JIM DUNLAP CAMPAI… REPUBLIC… SENATE    
#>  8 100021    1416 W OKMULGEE   MUSKOGEE   OK        74401   ROBINSON FOR SENA… DEMOCRAT  SENATE    
#>  9 100058    3421 E. 63RD      TULSA      OK        74135   FORD FOR SENATE 2… REPUBLIC… SENATE    
#> 10 100083    3717 NW 125TH ST  OKLAHOMA … OK        73120   MIKE FAIR CAMPAIG… REPUBLIC… SENATE    
#> # … with 2,939 more rows
```

The same can be done with non-candidate committee recipients from SO-2 filings.


```r
committee_rec <- so2 %>% 
  rename(
    rec_cname    = comname,
    rec_street   = street,
    rec_city     = city,
    rec_state    = state,
    rec_zip      = zip
  ) %>% 
  select(ethics_id, starts_with("rec_")) %>%
  mutate_if(is_character, str_to_upper) %>% 
  group_by(ethics_id) %>% 
  slice(1) %>% 
  ungroup() %>% 
  distinct()

print(committee_rec)
```

```
#> # A tibble: 952 x 6
#>    ethics_id rec_cname                          rec_street           rec_city    rec_state rec_zip 
#>    <chr>     <chr>                              <chr>                <chr>       <chr>     <chr>   
#>  1 200003    LEFLORE COUNTY DEMOCRAT WOMEN      22638 BLUEBIRD LN    POTEAU      OK        74953   
#>  2 200009    PHILLIPS MCFALL POLITICAL ACTION … ONE LEADERSHIP SQ 1… OKLAHOMA C… OK        73102   
#>  3 200018    OKLAHOMA THOROUGHBRED ASSOCIATION… 2000 SE 15TH BLDG 4… EDMOND      OK        73013   
#>  4 200026    REPUBLICAN SENATE VICTORY PAC - R… 7308 N NORMAN RD     OKLAHOMA C… OK        73132   
#>  5 200028    SMALL LOAN COUNCIL OF OKLAHOMA PAC 3806 S VICTOR        TULSA       OK        74105   
#>  6 200031    OKLAHOMA CITY RETIRED FIREFIGHTER… 1427 SW 137TH TER    OKLAHOMA C… OK        73170   
#>  7 201011    PRO OK PAC                         PO BOX 85            BURBANK     OK        74633   
#>  8 201012    THE REPUBLICAN BUSINESS COUNCIL    120 N ROBINSON STE … OKLAHOMA C… OK        73102   
#>  9 201013    UICI PAC                           PO BOX 12267         OKLAHOMA C… OK        73157-2…
#> 10 201014    CENTER FOR LEGISLATIVE EXCELLENCE  PO BOX 35743         TULSA       OK        74153-0…
#> # … with 942 more rows
```

Combine the two types of recipients into a single table that can be joined to the transactions
database along the `ethics_id` of each transaction's report filer.


```r
recipients <- bind_rows(candidate_rec, committee_rec)
dim(recipients)
#> [1] 3901    8
n_distinct(recipients$ethics_id) == nrow(recipients)
#> [1] TRUE
```

There are 3901 unique committees that have filed SO-1 or S0-2 reports, each
identified by their unique `ethics_id` variable.

### Total Join

With our new tables of unique contributors and unique recipients, we can better identify the
parties to each transaction. We will join all three tables by their respective `*_id` variables.


```r
ok <- ok %>% 
  left_join(contributors2 %>% select(-ethics_id), by = "cont_id") %>% 
  left_join(recipients, by = "ethics_id")
```

## Explore


```r
nrow(ok)
```

```
#> [1] 1729262
```

```r
length(ok)
```

```
#> [1] 30
```

```r
names(ok)
```

```
#>  [1] "trans_index"     "trans_date"      "cont_id"         "trans_amount"    "rep_num"        
#>  [6] "ethics_id"       "cont_type"       "cont_street"     "cont_city"       "cont_state"     
#> [11] "cont_zip"        "cont_fname"      "cont_mname"      "cont_lname"      "cont_employer"  
#> [16] "cont_occupation" "cont_bname"      "cont_activity"   "cont_interest"   "cont_cname"     
#> [21] "cont_fec"        "cont_vname"      "cont_desc"       "rec_street"      "rec_city"       
#> [26] "rec_state"       "rec_zip"         "rec_cname"       "rec_party"       "rec_office"
```

```r
sample_frac(ok)
```

```
#> # A tibble: 1,729,262 x 30
#>    trans_index trans_date cont_id trans_amount rep_num ethics_id cont_type cont_street cont_city
#>    <chr>       <date>     <chr>          <dbl> <chr>   <chr>     <chr>     <chr>       <chr>    
#>  1 1257088     2010-12-31 212175         10    67773   597256    1         12130 JAYC… MIDWEST …
#>  2 1351749     2011-09-29 346082          1    70670   504008    1         31300 S 67… Grove    
#>  3 1253466     2010-05-13 471162        100    67694   110084    1         609 SW 103… Oklahoma…
#>  4 2191582     2015-02-18 658804       5187.   91674   114224    4         4020 N. Li… Oklahoma…
#>  5 1591586     2012-09-28 580664         30    77446   512001    1         2708 Elmhu… Oklahoma…
#>  6 1924578     2014-05-08 674816         50    85653   714032    1         914 Hoover  Norman   
#>  7 1110588     2010-06-18 478918       2500    62932   110465    1         P. O. Box … Okmulgee 
#>  8 2181664     2014-12-08 718972       1000    91299   114114    1         14901 LAUR… Oklahoma…
#>  9 338545      2006-07-07 100615         12    41847   297247    4         NONE        NONE     
#> 10 1228783     2010-11-29 77841           4.62 66749   297314    1         PO BOX 577  VINITA   
#> # … with 1,729,252 more rows, and 21 more variables: cont_state <chr>, cont_zip <chr>,
#> #   cont_fname <chr>, cont_mname <chr>, cont_lname <chr>, cont_employer <chr>,
#> #   cont_occupation <chr>, cont_bname <chr>, cont_activity <chr>, cont_interest <chr>,
#> #   cont_cname <chr>, cont_fec <chr>, cont_vname <chr>, cont_desc <chr>, rec_street <chr>,
#> #   rec_city <chr>, rec_state <chr>, rec_zip <chr>, rec_cname <chr>, rec_party <chr>,
#> #   rec_office <chr>
```

```r
glimpse(sample_frac(ok))
```

```
#> Observations: 1,729,262
#> Variables: 30
#> $ trans_index     <chr> "1147891", "1004583", "150270", "841389", "1002346", "1522442", "1351910…
#> $ trans_date      <date> 2010-07-29, 2009-08-14, 2006-01-18, 2008-09-16, 2009-12-21, 2012-06-15,…
#> $ cont_id         <chr> "488294", "426449", "67857", "387956", "104179", "599791", "527119", "10…
#> $ trans_amount    <dbl> 2500.00, 100.00, 100.00, 1000.00, 2.50, 400.00, 5.00, 100.00, 5.00, 193.…
#> $ rep_num         <chr> "64439", "60080", "36980", "55683", "58731", "75481", "70670", "44938", …
#> $ ethics_id       <chr> "297244", "110084", "106087", "597246", "297312", "114013", "504008", "1…
#> $ cont_type       <chr> "3", "1", "1", "3", "1", "4", "1", "1", "1", "1", "1", "4", "1", "1", "4…
#> $ cont_street     <chr> "PO Box 886", "804 Rosehaven Dr", "P O Box 943", "4 May Flower", "13805 …
#> $ cont_city       <chr> "Sulphur", "Altus", "Elk City", "Altus", "EDMOND", "Sapulpa", "Muskogee"…
#> $ cont_state      <chr> "OK", "OK", "OK", "OK", "OK", "OK", "OK", "OK", "OK", "OK", "OK", "OK", …
#> $ cont_zip        <chr> "73086", "73521", "73648", "73521", "73013", "74066", "74401-2341", "731…
#> $ cont_fname      <chr> NA, "BOB", "BRENT & PAM", NA, "VICTOR", NA, "JAVIER", "MR. & MRS. WILLIA…
#> $ cont_mname      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "W.", "G…
#> $ cont_lname      <chr> NA, "JONES", "GREGORY", NA, "WIBLE", NA, "ESCOBAR", "VEAZEY", "DANIEL", …
#> $ cont_employer   <chr> NA, "WOSC", "Self-employed", NA, "SOUTHWESTERN BELL VIDEO SERVICES, INC"…
#> $ cont_occupation <chr> NA, "WELLNESS CENTER", "Farmer", NA, "FIELD SERVICE MANAGER", NA, "NON-M…
#> $ cont_bname      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ cont_activity   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ cont_interest   <chr> "Candidate", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ cont_cname      <chr> "Friends For Wes Hilliard 2010", NA, NA, "Friends Of Charles Ortega 2008…
#> $ cont_fec        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ cont_vname      <chr> NA, NA, NA, NA, NA, "Sapulpa Touchdown Club", NA, NA, NA, NA, NA, "Lake …
#> $ cont_desc       <chr> "Committee", "Individual", "Individual", "Committee", "Individual", "Ven…
#> $ rec_street      <chr> "13 NW 28TH ST", "1505 NW 145TH", "RT 1 BOX 1660", "4031 N LINCOLN BLVD"…
#> $ rec_city        <chr> "OKLAHOMA CITY", "EDMOND", "CANUTE", "OKLAHOMA CITY", "OKLAHOMA CITY", "…
#> $ rec_state       <chr> "OK", "OK", "OK", "OK", "OK", "OK", "AR", "OK", "OK", "OK", "OH", "OK", …
#> $ rec_zip         <chr> "73105", "73013", "73626", "73106", "72102", "74066", "72716", "73132-64…
#> $ rec_cname       <chr> "OKLAHOMA STATE EMPLOYEES ASSOCIATION PAC", "TODD LAMB FOR LT GOVERNOR 2…
#> $ rec_party       <chr> NA, "REPUBLICAN", "DEMOCRAT", NA, NA, "REPUBLICAN", NA, "REPUBLICAN", NA…
#> $ rec_office      <chr> NA, "LIEUTENANT GOVERNOR", "SENATE", NA, NA, "SENATE", NA, "GOVERNOR", N…
```

