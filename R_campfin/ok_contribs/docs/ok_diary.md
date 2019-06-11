---
title: "Data Diary"
subtitle: "Nevada Contributions"
author: "Kiernan Nicholls"
date: "2019-06-10 12:43:35"
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
  conflicted, # function conflictions
  tidyverse, # data manipulation
  lubridate, # date strings
  magrittr, # pipe opperators
  janitor, # data cleaning
  refinr, # cluster and merge
  vroom, # read files fast
  rvest, # scrape web pages
  knitr, # knit documents
  here, # navigate local storage
  fs # search local storage 
)
```



## Data

If the raw data has not been downloaded, it can be retrieved from the 
[Oklahoma Ethics Commision's website](https://www.ok.gov/ethics/public/login.php) as a ZIP archive.




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
#>  1 affiliation.csv              441445 2019-06-10 01:23:00
#>  2 ballot_measure.csv             1220 2019-06-10 01:23:00
#>  3 business_cont.csv            742467 2019-06-10 01:23:00
#>  4 c1r.csv                     8293148 2019-06-10 01:15:00
#>  5 c3r.csv                       88981 2019-06-10 01:24:00
#>  6 c4r.csv                       91436 2019-06-10 01:15:00
#>  7 c5r.csv                        1311 2019-06-10 01:15:00
#>  8 c6r_basic_info.csv            39081 2019-06-10 01:25:00
#>  9 c6r_electioneering_comm.csv    6752 2019-06-10 01:25:00
#> 10 c6r_receipts.csv             119477 2019-06-10 01:25:00
#> # … with 38 more rows
```

If these files have not yet been unzipped, they will be now.


```r
if (here("ok_contribs", "data", "raw") %>% any_old_files("*.zip")) {
  unzip(
    zipfile = here("ok_contribs", "data", "raw", "ethicscsvfile.zip"),
    exdir = here("ok_contribs", "data", "raw")
  )
}
```

### Descriptions

Descriptions for each of these files is provided int the `data/descriptions.doc` Word file. Some of
those relevant descriptions are copied below. The relationship between these files is described in
the `data/relations_db.xls` Excel file.

Affiliation

> Contains the banking information for the SO1 or SO2 that is filed. The rep_num refers to the
appropriate SO1 or SO2 in the Report table. The name, address, street, city, state and zip for the
bank are contained in this table.

Ballot Measure

> Holds the ballot year for the appropriate SO1 or SO2 that is filed. The `rep_num` refers to the
appropriate SO1 or SO2 in the Report table.

Business Cont

> Holds the business name (`cont_name`) and business activity of a business contributor.
Contributor id is the key that goes back to the contributor table and into either the transaction
table for a transaction list or contributor aggregate table for tie ins to the ethics_num
(committee) with aggregate totals.

C3R

> Has the report number and SO report number for a filed C3R (all relates back to the appropriate
`rep_num`  in the Report table)

C4R

> Has the report number of the C4R and SO report number and C1R report number from the report table
that the C4R was reported on.

Cont Type

> Holds the different contributor types available (Individual, Business, Committee, Vendor)

Party

> Has the different party affiliation types

Schedule A

> Holds the nature and transaction id for a schedule A transaction

Schedule A1

> Holds the transaction id for a schedule a1 transaction.

Schedule B

>Holds the transaction id, lending instutition id (relates to the Affiliation table), guarantor id
(contributor id) of the loan, repay information, amount guaranteed, balance owed, and if it is a
debt transfer for Schedule B transactions.

Schedule C

> Holds the transaction id, receipt type and other description for schedule C transactions.

Schedule D1

> Holds the transaction id, promise date, nature, status and a referenced transaction id for
schedule D1 transactions.

Schedule F

> Holds the transaction id, purpose, description and beneficiary information for schedule F
transactions.

Schedule H

> Holds the transaction id, description of goods for Schedule H transactions.

C1R

> Holds the summary report totals from transactions and either the campaign to date or year to date
totals for main the C1R report for any ethics number. The report_num ties back to the report table
to get the latest C1R for any ethics_num (committee)

Depository

> Holds the full name and address for the depository information for the SO1 or SO2 from the
`report_num` field that relates to the report table.

Period Type

> List of all period types available

Refund

> Transaction id and reason for any refund transaction

Schedule D

> Holds the transaction id, nature and percent of ownership information for any Schedule D
transaction.

Schedule E

> Holds the transaction id, description and purpose for any Schedule E transaction.

Schedule G

> Holds the transaction id for any schedule G transaction

Vendor Cont

> Holds the Vendor Contributor name for any expenditure transaction

Candidate

> Holds the candidate name and birthdate tied to the specific ethics_num (committee)

Committee

> Holds the FEC number for any ethics_num (ethics committee)

Committee Cont

> Holds the principal interest, contributor committee name and contributor FEC number and
committees ethics number for any committee contributors (contributor_id).
> 
> Contributor id is the key that goes back to the contributor table and into either the transaction
table for a transaction list or contributor aggregate table for tie ins to the ethics_num
(committee) with aggregate totals.

Contributor

> Holds address, phone and type of any contributor using contributor id as its identifier in other
tables.

Contributor Aggregate


> Is a list of all contributors for each ethics_num (committee) along with their aggregate amounts
for the campaign or year to date and the date of their last transaction.

District

> List of the districts for elections

Report Type

> Description of each type of report available  (SO1, SO2, C1R, C3R, C4R, C5R, C6R)

Schedule I

> Holds transaction information for all schedule I transactions (Description)

Schedule J

> Holds transaction information for all schecule J transactions (Loan transaction id – from
schedule B)

C6R Basic Info

> Holds basic information for a C6R report 

C6R Electioneering Comm

> Holds information relating to an electioneering communication.

C6R Receipts

> All receipts related to a C6R electioneering communication.

C6R Report

> Holds all the `c6r_report_num` for any C6R report filed. Has the date it was submitted, the
election date it relates to, reg_id (ethics number) and an amended reference flag. Basically if
there is a number in the amended reference column, then that report has been amended. If the
amended reference flag is null, then that is the latest report for that specific reg_id (ethics
number)

Reporting Period

> Has list of all the reporting periods that can be used for filing reports. Contains date ranges
for Quarterly, Annual, Monthly and special election reporting periods. Period ID is the primary key
of the table that is related to the period id in the Report table.

Report

> Holds all the report_num for all filed reports in the system from the SO1, SO2s to all the C1R,
C3R, C4R, and C5R reports. C6R reports are stored in the `c6r_report` table. Contains the date the
report was submitted, the `ethics_num` (committee) that it ties to, period id, the report type,
signature field, admin entered (means the report was filed by administrator), the amended reference
(if null, is the latest report, if not then that report was amended to the `report_num` that is
displayed in that field.), the final flag determines if that was the final report they will be
filing and `supp_year` is just a field on the form to show the year.

Officer Type

> Description of different officer types

Officer

> Officer information tied to the SO1 and SO2 report_num, also where the responsible officer field
is set for signature information.

Office

> Description of office types (mainly for elections)

Lump Fund

> Holds lump fund information for the respective report_num

Individual Cont

> Holds information relating to any individual contributor. Name, employer and occupation.
Contributor id is the key that goes back to the contributor table and into either the transaction
table for a transaction list or contributor aggregate table for tie ins to the ethics_num
(committee) with aggregate totals.

SO1

> Holds the SO1 report information (report_num is the key on this table back to the report table)

SO2

> Holds the SO2 report information (report_num is the key on this table back to the report table)
Surplus
> 
> Holds information relating to the surplus of funds (report_num is the key back to the SO1 or SO2
table back to the report table)

Surplus Funds

> List of all the different types of surplus funds (surp_id is the key)

Transaction

> Holds all the contribution and expenditure transactions. Has the transaction date, amount, the
contributor id and report number (report_num) that it ties back to in the report table.
