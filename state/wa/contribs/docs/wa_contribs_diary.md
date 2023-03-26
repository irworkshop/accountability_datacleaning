Washington Contributions
================
Kiernan Nicholls
Sun Mar 26 15:37:18 2023

- <a href="#project" id="toc-project">Project</a>
- <a href="#objectives" id="toc-objectives">Objectives</a>
- <a href="#packages" id="toc-packages">Packages</a>
- <a href="#data" id="toc-data">Data</a>
- <a href="#download" id="toc-download">Download</a>
- <a href="#read" id="toc-read">Read</a>
- <a href="#explore" id="toc-explore">Explore</a>
  - <a href="#missing" id="toc-missing">Missing</a>
  - <a href="#duplicates" id="toc-duplicates">Duplicates</a>
  - <a href="#categorical" id="toc-categorical">Categorical</a>
  - <a href="#amounts" id="toc-amounts">Amounts</a>
  - <a href="#dates" id="toc-dates">Dates</a>
- <a href="#wrangle" id="toc-wrangle">Wrangle</a>
  - <a href="#address" id="toc-address">Address</a>
  - <a href="#zip" id="toc-zip">ZIP</a>
  - <a href="#state" id="toc-state">State</a>
  - <a href="#city" id="toc-city">City</a>
- <a href="#conclude" id="toc-conclude">Conclude</a>
- <a href="#export" id="toc-export">Export</a>
- <a href="#upload" id="toc-upload">Upload</a>

<!-- Place comments regarding knitting here -->

## Project

The Accountability Project is an effort to cut across data silos and
give journalists, policy professionals, activists, and the public at
large a simple way to search across huge volumes of public data about
people and organizations.

Our goal is to standardize public data on a few key fields by thinking
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
  jsonlite, # parse json data
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
here::i_am("wa/contribs/docs/wa_contribs_diary.Rmd")
```

## Data

``` r
wa_meta <- fromJSON("https://data.wa.gov/api/views/kv7h-kjye")
```

[Contributions](https://data.wa.gov/d/kv7h-kjye) for the state of
Washington can be obtained from the state’s [Public Disclosure
Commission](http://pdc.wa.gov/) on their [Open Data
portal](https://data.wa.gov/). The data is titled “Contributions to
Candidates and Political Committees” and was created on December 16,
2016 and was last updated at March 26, 2023.

#### Description

> This dataset contains cash and in-kind contributions, (including
> unpaid loans) made to Washington State Candidates and Political
> Committees for the last 10 years as reported to the PDC on forms C3,
> C4, Schedule C and their electronic filing equivalents. It does not
> include loans which have been paid or forgiven, pledges or any
> expenditures.
>
> For candidates, the number of years is determined by the year of the
> election, not necessarily the year the contribution was reported. For
> political committees, the number of years is determined by the
> calendar year of the reporting period.
>
> Candidates and political committees choosing to file under “mini
> reporting” are not included in this dataset. See WAC 390-16-105 for
> information regarding eligibility.
>
> This dataset is a best-effort by the PDC to provide a complete set of
> records as described herewith and may contain incomplete or incorrect
> information. The PDC provides access to the original reports for the
> purpose of record verification.
>
> Descriptions attached to this dataset do not constitute legal
> definitions; please consult RCW 42.17A and WAC Title 390 for legal
> definitions and additional information political finance disclosure
> requirements.
>
> CONDITION OF RELEASE: This publication constitutes a list of
> individuals prepared by the Washington State Public Disclosure
> Commission and may not be used for commercial purposes. This list is
> provided on the condition and with the understanding that the persons
> receiving it agree to this statutorily imposed limitation on its use.
> See RCW 42.56.070(9) and AGO 1975 No. 15.

#### Dictionary

| fieldName                    | dataTypeName  | description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
|:-----------------------------|:--------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`                         | text          | PDC internal identifier that corresponds to a single contribution or correction record. When combined with the origin value, this number uniquely identifies a single row.                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `report_number`              | text          | PDC identifier used for tracking the individual form C3, C4 or C4 schedule C. Multiple contributions or corrections will correspond to the same report number when they were reported to the PDC at the same time. The report number is unique to the report it represents. When a report is amended, a new report number is assigned that supersedes the original version of the amended report and the original report records are not included in this dataset.                                                                                                                                          |
| `origin`                     | text          | The form, schedule or section where the record was reported. Please see <https://www.pdc.wa.gov/learn/forms> for a list of forms and instructions.<br/><br/>AUB (Form C3, schedule AU, auction buyer);<br/>AUD (Form C3, schedule AU, auction donor);<br/>C.1 (Form C4, schedule C1 correction);<br/>C3 (Form C3 cash contribution);<br/>C3.1A (Form C3, anonymous contributions);<br/>C3.1B (Form C3, candidate personal funds);<br/>C3.1D (Form C3, miscellaneous receipts)<br/>C3.1E (Form C3, small contributions);<br/>C4 (Form C4, in-kind contribution);<br/><br/>                                   |
| `committee_id`               | text          | The unique identifier of a committee. For a continuing committee, this id will be the same for all the years that the committee is registered. Single year committees and candidate committees will have a unique id for each year even though the candidate or committee organization might be the same across years. Surplus accounts will have a single committee id across all years.                                                                                                                                                                                                                   |
| `filer_id`                   | text          | The unique id assigned to a candidate or political committee. The filer id is consistent across election years with the exception that an individual running for a second office in the same election year will receive a second filer id. There is no correlation between the two filer ids. For a candidate and single-election-year committee such as a ballot committee, the combination of filer_id and election_year uniquely identifies a campaign.                                                                                                                                                  |
| `type`                       | text          | Indicates if this record is for a candidate or a political committee. In the case of a political committee, it may be either a continuing political committee, party committee or single election year committee.                                                                                                                                                                                                                                                                                                                                                                                           |
| `filer_name`                 | text          | The candidate or committee name as reported on the form C1 candidate or committee registration form. The name will be consistent across all records for the same filer id and election year but may differ across years due to candidates or committees changing their name.                                                                                                                                                                                                                                                                                                                                |
| `office`                     | text          | The office sought by the candidate. Does not apply to political committees.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `legislative_district`       | text          | The Washington State legislative district. This field only applies to candidates where the office is “state senator” or “state representative.”                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `position`                   | text          | The position associated with an office. This field typically applies to judicial and local office that have multiple positions or seats. This field does not apply to political committees.                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `party`                      | text          | The political party as declared by the candidate or committee on their form C1 registration. Contains only “Major parties” as recognized by Washington State law.                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `ballot_number`              | text          | If the committee is a Statewide Ballot Initiative Committee a ballot number will appear once a ballot number is assigned by the Secretary of State. Local Ballot Initiatives will not have a ballot number. This field will contain a number only if the Secretary of State issues a number.                                                                                                                                                                                                                                                                                                                |
| `for_or_against`             | text          | Ballot initiative committees are formed to either support or oppose an initiative. This field represents whether a committee “supports” (for) or “opposes” (against) a ballot initiative.                                                                                                                                                                                                                                                                                                                                                                                                                   |
| `jurisdiction`               | text          | <br/>The political jurisdiction associated with the office of a candidate.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `jurisdiction_county`        | text          | The county associated with the jurisdiction of a candidate. Multi-county jurisdictions as reported as the primary county. This field will be empty for political committees and when a candidate jurisdiction is statewide.                                                                                                                                                                                                                                                                                                                                                                                 |
| `jurisdiction_type`          | text          | The type of jurisdiction this office is: Statewide, Local, etc.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `election_year`              | number        | The election year in the case of candidates and single election committees. The reporting year in the case of continuing political committees.                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `amount`                     | number        | The amount of the cash or in-kind contribution. On corrections records, this field is the amount of the adjustment.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `cash_or_in_kind`            | text          | What kind of contribution this is, if known.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `receipt_date`               | calendar_date | <br/>The date that the contribution was received.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `description`                | text          | <br/>The reported description of the transaction. This field does not apply to cash contributions. Not all in-kind contributions and corrections will contain a description. In the case of corrections, the PDC has added a notation regarding the amounts reported on the form Schedule C. A C3 contains not only detailed contributions it also contains none detailed cash - this column will contain the descriptions: ‘Anonymous - Cash’; ‘Candidates Personal Funds - Does not include candidate loans’; ‘Miscellaneous Receipts’, ‘Contributions of \$25 or less contributed by: \_\_\_\_ persons’. |
| `memo`                       | text          | The optional memo field associated with the transaction. In most cases this field will be blank.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `primary_general`            | text          | <br/>Candidates subject to contribution limits must specify whether a contribution is designated for the primary or the general election. Contributions to candidates not subject to limits, political committees and continuing political committees apply to the full election cycle.                                                                                                                                                                                                                                                                                                                     |
| `code`                       | text          | When a contribution is received, the code field denotes the type of entity that made the contribution. These types are determined by the filer. The field values correspond to the selected code: A: Anonymous; B: Business; C: PAC; I: Individual; L: Caucus; O: Other; P: Bona Fide Party; S: Self Pers. Fund; T: Minor Party; U: Union.                                                                                                                                                                                                                                                                  |
| `contributor_category`       | text          | Indicates if the contributor is an “Individual” or “Organization”. When a contribution is received, the code field denotes the type of entity that made the contribution. These types are determined by the filer. The field values correspond to the selected code: A: Anonymous; B: Business; C: PAC; I: Individual; L: Caucus; O: Other; P: Bona Fide Party; S: Self Pers. Fund; T: Minor Party; U: Union. Codes B, C, F, L, O, P, M and U are assigned the category “Organization” and all others are assigned the category “Individual”.                                                               |
| `contributor_name`           | text          | <br/>The name of the individual or organization making the contribution as reported. The names appearing here have not been normalized and the same entity may be represented by different names in the dataset. This field only applies to contributions where the aggregate total of all contributions from this contributor to this candidate or committee exceeds \$25 for the election cycle (calendar year for continuing committees).                                                                                                                                                                |
| `contributor_address`        | text          | The street address of the individual or organization making the contribution. Refer to the contributor name field for more information on when this information is required.                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `contributor_city`           | text          | The city of the individual or organization making the contribution. Refer to the contributor name field for more information on when this information is required.                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `contributor_state`          | text          | The state of the individual or organization making the contribution. Contributions from outside the United States may contain foreign postal region codes in this field. Refer to the contributor name field for more information on when this information is required.                                                                                                                                                                                                                                                                                                                                     |
| `contributor_zip`            | text          | The US zip code of the individual or organization making the contribution. Contributions from outside the United States may contain foreign postal codes in this field. Refer to the contributor name field for more information on when this information is required.                                                                                                                                                                                                                                                                                                                                      |
| `contributor_occupation`     | text          | The occupation of the contributor. This field only applies to contributions by individuals and only when an individual gives a campaign or committee more than \$100 in the aggregate for the election cycle (calendar year for continuing political committees).                                                                                                                                                                                                                                                                                                                                           |
| `contributor_employer_name`  | text          | The name of the contributor’s employer. The names appearing here have not been normalized and the same entity may be represented by different names in the dataset. Refer to the contributor occupation field to see when this field applies.                                                                                                                                                                                                                                                                                                                                                               |
| `contributor_employer_city`  | text          | City of the contributor’s employer. Refer to the contributor occupation field to see when this field applies.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `contributor_employer_state` | text          | State of the contributor’s employer. Refer to the contributor occupation field to see when this field applies.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `url`                        | url           | A link to a PDF version of the original report as it was filed to the PDC.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `contributor_location`       | point         | The geocoded location of the contributor as reported. The quality of the geocoded location is dependent on how many of the address fields are available and is calculated using a third-party service. The PDC has not verified the results of the geocoding. Please refer to the recipient_name field for more information regarding address fields.                                                                                                                                                                                                                                                       |

## Download

``` r
raw_dir <- dir_create(here("wa", "contribs", "data", "raw"))
raw_tsv <- path(raw_dir, path_ext_set(wa_meta$resourceName, "tsv"))
```

``` r
if (!file_exists(raw_tsv)) {
  wa_head <- GET(
    url = "https://data.wa.gov/api/views/kv7h-kjye/rows.tsv",
    query = list(accessType = "DOWNLOAD"),
    write_disk(path = raw_tsv),
    progress("down")
  )
}
```

## Read

``` r
wac <- read_delim(
  file = raw_tsv,
  delim = "\t",
  escape_backslash = FALSE,
  escape_double = FALSE,
  col_types = cols(
    .default = col_character(),
    id = col_integer(),
    election_year = col_integer(),
    amount = col_double(),
    receipt_date = col_date("%m/%d/%Y")
  )
)
```

## Explore

There are 5,952,878 rows of 36 columns. Each record represents a single
cash or in-kind contribution or correction.

``` r
glimpse(wac)
#> Rows: 5,952,878
#> Columns: 36
#> $ id                         <int> 16417211, 16417210, 16417209, 16417208, 16417207, 16417226, 16417240, 16417279, 164…
#> $ report_number              <chr> "110108190", "110108190", "110108190", "110108190", "110108190", "110108192", "1101…
#> $ origin                     <chr> "C3", "C3", "C3", "C3", "C3", "C3", "C3", "C3", "C3", "C3", "C3", "C3", "C3", "C3",…
#> $ committee_id               <chr> "30904", "30904", "30904", "30904", "30904", "29766", "30614", "15022", "30614", "3…
#> $ filer_id                   <chr> "BHAGH  570", "BHAGH  570", "BHAGH  570", "BHAGH  570", "BHAGH  570", "HALLM  516",…
#> $ type                       <chr> "Candidate", "Candidate", "Candidate", "Candidate", "Candidate", "Candidate", "Cand…
#> $ filer_name                 <chr> "Harry O. Bhagwandin", "Harry O. Bhagwandin", "Harry O. Bhagwandin", "Harry O. Bhag…
#> $ office                     <chr> "COUNTY COMMISSIONER", "COUNTY COMMISSIONER", "COUNTY COMMISSIONER", "COUNTY COMMIS…
#> $ legislative_district       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "26", NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ position                   <chr> "County Commissioner Position 3", "County Commissioner Position 3", "County Commiss…
#> $ party                      <chr> "REPUBLICAN", "REPUBLICAN", "REPUBLICAN", "REPUBLICAN", "REPUBLICAN", "DEMOCRATIC",…
#> $ ballot_number              <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ for_or_against             <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ jurisdiction               <chr> "LEWIS CO", "LEWIS CO", "LEWIS CO", "LEWIS CO", "LEWIS CO", "THURSTON CO", "CHELAN …
#> $ jurisdiction_county        <chr> "LEWIS", "LEWIS", "LEWIS", "LEWIS", "LEWIS", "THURSTON", "CHELAN", NA, "CHELAN", "C…
#> $ jurisdiction_type          <chr> "Local", "Local", "Local", "Local", "Local", "Local", "Local", NA, "Local", "Local"…
#> $ election_year              <int> 2022, 2022, 2022, 2022, 2022, 2022, 2022, 2022, 2022, 2022, 2022, 2010, 2022, 2022,…
#> $ amount                     <dbl> 500.0, 500.0, 200.0, 1000.0, 150.0, 10.0, 50.0, 525.0, 250.0, 100.0, 400.0, 50.0, 2…
#> $ cash_or_in_kind            <chr> "Cash", "Cash", "Cash", "Cash", "Cash", "Cash", "Cash", "Cash", "Cash", "Cash", "Ca…
#> $ receipt_date               <date> 2022-08-10, 2022-08-10, 2022-08-10, 2022-08-09, 2022-08-09, 2022-08-19, 2022-08-15…
#> $ description                <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "Contributions of $25 or less contr…
#> $ memo                       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ primary_general            <chr> "General", "General", "General", "General", "General", "General", "General", "Full …
#> $ code                       <chr> "Individual", "Individual", "Individual", "Individual", "Individual", "Individual",…
#> $ contributor_category       <chr> "Individual", "Individual", "Individual", "Individual", "Individual", "Individual",…
#> $ contributor_name           <chr> "M REMUND SUSAN", "J REMUND RENE", "RUSSELL ROBERT", "M FENN TERESA", "D KRABBE PET…
#> $ contributor_address        <chr> "213 Boistfort Road", "213 Boistfort Road", "PO Box 902", "126 Hideaway Lane", "PO …
#> $ contributor_city           <chr> "Chehalis", "Chehalis", "Chehalis", "Packwood", "Randle", "LACEY", "Leavenworth", "…
#> $ contributor_state          <chr> "WA", "WA", "WA", "WA", "WA", "WA", "WA", "WA", "WA", "WA", "WA", "WA", NA, "WA", "…
#> $ contributor_zip            <chr> "98532", "98532", "98532", "98361", "98377", "98516", "98826", "98516", "98826", "9…
#> $ contributor_occupation     <chr> "RETIRED", "RETIRED", "RETIRED", "RETIRED", "RETIRED", NA, NA, NA, "RETIRED", NA, "…
#> $ contributor_employer_name  <chr> NA, NA, NA, NA, NA, NA, NA, NA, "N/A", NA, "Snowgrass Lodge", "RETIRED", NA, NA, NA…
#> $ contributor_employer_city  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "Leavenworth", "VAUGHN", NA, NA, NA, NA, NA…
#> $ contributor_employer_state <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "WA", "WA", NA, NA, NA, NA, NA, NA, "WA", N…
#> $ url                        <chr> "https://apollo.pdc.wa.gov/public/registrations/campaign-finance-report/110108190",…
#> $ contributor_location       <chr> NA, NA, "POINT (-122.96691 46.66112)", NA, NA, "POINT (-122.76746 47.10356)", NA, "…
tail(wac)
#> # A tibble: 6 × 36
#>         id report_number origin committee_id filer_id   type       filer_name office legislative_district position party
#>      <int> <chr>         <chr>  <chr>        <chr>      <chr>      <chr>      <chr>  <chr>                <chr>    <chr>
#> 1 17145908 110139988     C3     31451        SIMMJ--210 Candidate  Justin Fl… CITY … <NA>                 CITY CO… <NA> 
#> 2 17145907 110139988     C3     31451        SIMMJ--210 Candidate  Justin Fl… CITY … <NA>                 CITY CO… <NA> 
#> 3 17145906 110139988     C3     31451        SIMMJ--210 Candidate  Justin Fl… CITY … <NA>                 CITY CO… <NA> 
#> 4 17145905 110139988     C3     31451        SIMMJ--210 Candidate  Justin Fl… CITY … <NA>                 CITY CO… <NA> 
#> 5 17145904 110139988     C3     31451        SIMMJ--210 Candidate  Justin Fl… CITY … <NA>                 CITY CO… <NA> 
#> 6 17145922 110139989     C3     31906        FIREC--701 Political… Committee… <NA>   <NA>                 <NA>     <NA> 
#> # ℹ 25 more variables: ballot_number <chr>, for_or_against <chr>, jurisdiction <chr>, jurisdiction_county <chr>,
#> #   jurisdiction_type <chr>, election_year <int>, amount <dbl>, cash_or_in_kind <chr>, receipt_date <date>,
#> #   description <chr>, memo <chr>, primary_general <chr>, code <chr>, contributor_category <chr>,
#> #   contributor_name <chr>, contributor_address <chr>, contributor_city <chr>, contributor_state <chr>,
#> #   contributor_zip <chr>, contributor_occupation <chr>, contributor_employer_name <chr>,
#> #   contributor_employer_city <chr>, contributor_employer_state <chr>, url <chr>, contributor_location <chr>
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(wac, count_na)
#> # A tibble: 36 × 4
#>    col                        class        n        p
#>    <chr>                      <chr>    <int>    <dbl>
#>  1 id                         <int>        0 0       
#>  2 report_number              <chr>        0 0       
#>  3 origin                     <chr>        0 0       
#>  4 committee_id               <chr>        0 0       
#>  5 filer_id                   <chr>        0 0       
#>  6 type                       <chr>        0 0       
#>  7 filer_name                 <chr>        0 0       
#>  8 office                     <chr>  3658261 0.615   
#>  9 legislative_district       <chr>  5248667 0.882   
#> 10 position                   <chr>  5576880 0.937   
#> 11 party                      <chr>  3412007 0.573   
#> 12 ballot_number              <chr>  5821716 0.978   
#> 13 for_or_against             <chr>  5610416 0.942   
#> 14 jurisdiction               <chr>  3458923 0.581   
#> 15 jurisdiction_county        <chr>  4216294 0.708   
#> 16 jurisdiction_type          <chr>  3548596 0.596   
#> 17 election_year              <int>        0 0       
#> 18 amount                     <dbl>        0 0       
#> 19 cash_or_in_kind            <chr>        0 0       
#> 20 receipt_date               <date>    2018 0.000339
#> 21 description                <chr>  5622182 0.944   
#> 22 memo                       <chr>  5888660 0.989   
#> 23 primary_general            <chr>   282651 0.0475  
#> 24 code                       <chr>        0 0       
#> 25 contributor_category       <chr>        0 0       
#> 26 contributor_name           <chr>        0 0       
#> 27 contributor_address        <chr>   216802 0.0364  
#> 28 contributor_city           <chr>   213707 0.0359  
#> 29 contributor_state          <chr>   206114 0.0346  
#> 30 contributor_zip            <chr>   219579 0.0369  
#> 31 contributor_occupation     <chr>  4028855 0.677   
#> 32 contributor_employer_name  <chr>  4262670 0.716   
#> 33 contributor_employer_city  <chr>  4391052 0.738   
#> 34 contributor_employer_state <chr>  4391679 0.738   
#> 35 url                        <chr>        0 0       
#> 36 contributor_location       <chr>  3757707 0.631
```

We can flag any record missing a key variable needed to identify a
transaction.

``` r
key_vars <- c("receipt_date", "contributor_name", "amount", "filer_name")
wac <- flag_na(wac, all_of(key_vars))
sum(wac$na_flag)
#> [1] 2018
```

``` r
wac %>% 
  filter(na_flag) %>% 
  select(all_of(key_vars))
#> # A tibble: 2,018 × 4
#>    receipt_date contributor_name    amount filer_name                                                 
#>    <date>       <chr>                <dbl> <chr>                                                      
#>  1 NA           SMALL CONTRIBUTIONS   25   18TH LEG DIST DEMO CENT COMM NON EXEMPT                    
#>  2 NA           SMALL CONTRIBUTIONS   40.2 WASHINGTON EDUCATION ASSOCIATION POLITICAL ACTION COMMITTEE
#>  3 NA           SMALL CONTRIBUTIONS   78.7 ALICIA J RULE (Alicia Rule)                                
#>  4 NA           SMALL CONTRIBUTIONS   31.3 Matthew T. Macklin (Matthew Macklin)                       
#>  5 NA           SMALL CONTRIBUTIONS   24.3 Sandra Kaiser                                              
#>  6 NA           SMALL CONTRIBUTIONS   65   Sue W. Forde (Sue Forde)                                   
#>  7 NA           SMALL CONTRIBUTIONS  230.  48TH DISTRICT DEMOCRATIC ORGANIZATION                      
#>  8 NA           SMALL CONTRIBUTIONS   70   Steven L. Saunders (Steven L Saunders)                     
#>  9 NA           SMALL CONTRIBUTIONS  135   Brian L Pruiett (Brian Pruiett)                            
#> 10 NA           SMALL CONTRIBUTIONS  149   Brian James King (Brian King)                              
#> # ℹ 2,008 more rows
```

### Duplicates

We can also flag any entirely duplicate rows. To keep memory usage low
with such a large data frame, we will split our data into a list and
check each element of the list. For each chunk, we will write the
duplicate `id` to a text file.

``` r
prop_distinct(wac$id)
#> [1] 1
```

``` r
dupe_file <- here("il", "contribs", "data", "dupe_ids.txt")
if (!file_exists(dupe_file)) {
  tmp <- file_temp(ext = "rds")
  write_rds(wac, file = tmp)
  file_size(tmp)
  wa_id <- split(wac$id, wac$receipt_date)
  was <- wac %>%
    select(-id) %>% 
    group_split(receipt_date)
  if (file_exists(tmp)) {
    rm(wac)
    Sys.sleep(5)
    flush_memory(2)
  }
  pb <- txtProgressBar(max = length(was), style = 3)
  for (i in seq_along(was)) {
    if (nrow(was[[i]]) < 2) {
      next
    }
    d1 <- duplicated(was[[i]], fromLast = FALSE)
    d2 <- duplicated(was[[i]], fromLast = TRUE)
    dupe_vec <- d1 | d2
    rm(d1, d2)
    if (any(dupe_vec)) {
      write_lines(
        x = wa_id[[i]][dupe_vec], 
        file = dupe_file, 
        append = file_exists(dupe_file),
        na = ""
      )
    }
    rm(dupe_vec)
    was[[i]] <- NA
    wa_id[[i]] <- NA
    if (i %% 100 == 0) {
      Sys.sleep(2)
      flush_memory()
    }
    setTxtProgressBar(pb, i)
  }
  rm(was, wa_id)
  Sys.sleep(5)
  flush_memory()
  wac <- read_rds(tmp)
}
```

``` r
dupe_id <- tibble(
  id = as.integer(read_lines(dupe_file, skip_empty_rows = TRUE)),
  dupe_flag = TRUE
)
wac <- left_join(wac, dupe_id, by = "id")
wac <- mutate(wac, across(dupe_flag, Negate(is.na)))
```

0.1% of rows are duplicates.

``` r
wac %>% 
  filter(dupe_flag) %>% 
  count(receipt_date, contributor_name, amount, filer_name, sort = TRUE)
#> # A tibble: 6,952 × 5
#>    receipt_date contributor_name           amount filer_name                                                 n
#>    <date>       <chr>                       <dbl> <chr>                                                  <int>
#>  1 2017-11-21   KALISPEL TRIBE OF INDIANS 1000    Mark Schoesler (MARK SCHOESLER)                            2
#>  2 2019-12-16   SCOTT PETER                 15    CITIZENS FOR EVERETT PUBLIC SCHOOLS                        2
#>  3 2020-04-30   ACLU OF WASHINGTON        1000    Commit to Change WA (sponsored by ACLU of Washington)      2
#>  4 2020-06-19   SARGENT EUGENE               6.25 BRIAN SMILEY                                               2
#>  5 2020-07-28   ELI LILLY AND COMPANY      500    TAKKO DEAN A                                               2
#>  6 2020-09-20   VOSS EMILY                  75    Loren D. Culp (Loren Culp)                                 2
#>  7 2020-09-22   EVANS JULIE                100    REPUBLICAN STATE LEADERSHIP COMMITTEE - WASHINGTON PAC     2
#>  8 2020-09-22   FOXWINCHELL CLAUDIA         25    REPUBLICAN STATE LEADERSHIP COMMITTEE - WASHINGTON PAC     2
#>  9 2020-09-29   MURRAY EVAN                 15    REPUBLICAN STATE LEADERSHIP COMMITTEE - WASHINGTON PAC     2
#> 10 2020-10-23   HO ANTHONY                  15    Gael D Tarleton (Gael Tarleton)                            2
#> # ℹ 6,942 more rows
```

### Categorical

``` r
col_stats(wac, n_distinct)
#> # A tibble: 38 × 4
#>    col                        class        n           p
#>    <chr>                      <chr>    <int>       <dbl>
#>  1 id                         <int>  5952878 1          
#>  2 report_number              <chr>   557793 0.0937     
#>  3 origin                     <chr>        5 0.000000840
#>  4 committee_id               <chr>    11258 0.00189    
#>  5 filer_id                   <chr>     7719 0.00130    
#>  6 type                       <chr>        2 0.000000336
#>  7 filer_name                 <chr>     9102 0.00153    
#>  8 office                     <chr>       44 0.00000739 
#>  9 legislative_district       <chr>       50 0.00000840 
#> 10 position                   <chr>      219 0.0000368  
#> 11 party                      <chr>       12 0.00000202 
#> 12 ballot_number              <chr>      132 0.0000222  
#> 13 for_or_against             <chr>        3 0.000000504
#> 14 jurisdiction               <chr>      588 0.0000988  
#> 15 jurisdiction_county        <chr>       39 0.00000655 
#> 16 jurisdiction_type          <chr>        5 0.000000840
#> 17 election_year              <int>       20 0.00000336 
#> 18 amount                     <dbl>    54142 0.00910    
#> 19 cash_or_in_kind            <chr>        2 0.000000336
#> 20 receipt_date               <date>    6720 0.00113    
#> 21 description                <chr>    71678 0.0120     
#> 22 memo                       <chr>        3 0.000000504
#> 23 primary_general            <chr>        4 0.000000672
#> 24 code                       <chr>        8 0.00000134 
#> 25 contributor_category       <chr>        2 0.000000336
#> 26 contributor_name           <chr>  1133067 0.190      
#> 27 contributor_address        <chr>  1160748 0.195      
#> 28 contributor_city           <chr>    21307 0.00358    
#> 29 contributor_state          <chr>      200 0.0000336  
#> 30 contributor_zip            <chr>    20178 0.00339    
#> 31 contributor_occupation     <chr>    49736 0.00835    
#> 32 contributor_employer_name  <chr>   155183 0.0261     
#> 33 contributor_employer_city  <chr>    10929 0.00184    
#> 34 contributor_employer_state <chr>      158 0.0000265  
#> 35 url                        <chr>   557793 0.0937     
#> 36 contributor_location       <chr>   214078 0.0360     
#> 37 na_flag                    <lgl>        2 0.000000336
#> 38 dupe_flag                  <lgl>        2 0.000000336
```

![](../plots/distinct_plots-1.png)<!-- -->

### Amounts

``` r
summary(wac$amount)
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#> -2500000        9       35      287      100  8929810
mean(wac$amount <= 0)
#> [1] 0.003589692
```

These are the records with the minimum and maximum amounts.

``` r
glimpse(wac[c(which.max(wac$amount), which.min(wac$amount)), ])
#> Rows: 2
#> Columns: 38
#> $ id                         <int> 10644750, 10645096
#> $ report_number              <chr> "100433945", "100441590"
#> $ origin                     <chr> "C3", "C.1"
#> $ committee_id               <chr> "22059", "22059"
#> $ filer_id                   <chr> "YES1183109", "YES1183109"
#> $ type                       <chr> "Political Committee", "Political Committee"
#> $ filer_name                 <chr> "YES ON 1183 COALITION", "YES ON 1183 COALITION"
#> $ office                     <chr> NA, NA
#> $ legislative_district       <chr> NA, NA
#> $ position                   <chr> NA, NA
#> $ party                      <chr> NA, NA
#> $ ballot_number              <chr> NA, NA
#> $ for_or_against             <chr> NA, NA
#> $ jurisdiction               <chr> NA, NA
#> $ jurisdiction_county        <chr> NA, NA
#> $ jurisdiction_type          <chr> NA, NA
#> $ election_year              <int> 2011, 2011
#> $ amount                     <dbl> 8929810, -2500000
#> $ cash_or_in_kind            <chr> "Cash", "Cash"
#> $ receipt_date               <date> 2011-10-17, 2011-10-17
#> $ description                <chr> NA, "CORRECTION TO CONTRIBUTIONS (Reported amount: 8929810.00; Corrected amount: 64…
#> $ memo                       <chr> NA, NA
#> $ primary_general            <chr> "Full Election", NA
#> $ code                       <chr> "Business", "Other"
#> $ contributor_category       <chr> "Organization", "Individual"
#> $ contributor_name           <chr> "COSTCO", "COSTCO"
#> $ contributor_address        <chr> "999 LAKE DR", NA
#> $ contributor_city           <chr> "ISSAQUAH", NA
#> $ contributor_state          <chr> "WA", NA
#> $ contributor_zip            <chr> "98027", NA
#> $ contributor_occupation     <chr> NA, NA
#> $ contributor_employer_name  <chr> NA, NA
#> $ contributor_employer_city  <chr> NA, NA
#> $ contributor_employer_state <chr> NA, NA
#> $ url                        <chr> "https://web.pdc.wa.gov/rptimg/default.aspx?repno=100433945", "https://web.pdc.wa.g…
#> $ contributor_location       <chr> "POINT (-122.05221 47.5493)", NA
#> $ na_flag                    <lgl> FALSE, FALSE
#> $ dupe_flag                  <lgl> FALSE, FALSE
```

![](../plots/hist_amount-1.png)<!-- -->

### Dates

We can add the calendar year from `receipt_date` with
`lubridate::year()`

``` r
wac <- mutate(wac, receipt_year = year(receipt_date))
```

``` r
min(wac$receipt_date)
#> [1] NA
sum(wac$receipt_year < 2000)
#> [1] NA
max(wac$receipt_date)
#> [1] NA
sum(wac$receipt_date > today())
#> [1] NA
```

![](../plots/bar_year-1.png)<!-- -->

## Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are tailor made to facilitate this process.

### Address

The `contributor_address` variable is already sufficiently normalized.

``` r
sample(wac$contributor_address, 5)
#> [1] "4304 OREGON DR"     "3200 62ND AVE SW"   "5407 N SULLIVAN RD" "1401 S SPRAGUE AVE" "2314 N HARMON"
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
wac <- wac %>% 
  mutate(
    zip_norm = normal_zip(
      zip = contributor_zip %>% 
        str_remove_all("-\\d{4}$"),
      na_rep = TRUE
    )
  )
```

``` r
wac %>% 
  count(contributor_zip, zip_norm, sort = TRUE) %>% 
  filter(contributor_zip != zip_norm)
#> # A tibble: 427 × 3
#>    contributor_zip zip_norm     n
#>    <chr>           <chr>    <int>
#>  1 V6J 1           61          83
#>  2 -9-81           981         55
#>  3 V6Z 2           62          19
#>  4 100.0           1000        18
#>  5 98---           98          11
#>  6 9834-           9834        11
#>  7 +9116           9116        10
#>  8 WA989           989          9
#>  9 500.0           5000         8
#> 10 98,16           9816         8
#> # ℹ 417 more rows
```

``` r
progress_table(
  wac$contributor_zip,
  wac$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 × 6
#>   stage               prop_in n_distinct prop_na n_out n_diff
#>   <chr>                 <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 wac$contributor_zip   0.995      20178  0.0369 30912   3237
#> 2 wac$zip_norm          0.998      19756  0.0397 13904   2815
```

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

``` r
wac <- wac %>% 
  mutate(
    state_norm = normal_state(
      state = contributor_state,
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = valid_state
    )
  )
```

``` r
wac %>% 
  count(contributor_state, state_norm, sort = TRUE) %>% 
  filter(contributor_state != state_norm)
#> # A tibble: 40 × 3
#>    contributor_state state_norm     n
#>    <chr>             <chr>      <int>
#>  1 Washington        WA           159
#>  2 wa                WA           117
#>  3 Wa                WA           115
#>  4 or                OR            31
#>  5 WASHINGTON        WA            19
#>  6 ca                CA             8
#>  7 wA                WA             5
#>  8 Or                OR             4
#>  9 Ca                CA             3
#> 10 Tx                TX             3
#> # ℹ 30 more rows
```

``` r
progress_table(
  wac$contributor_state,
  wac$state_norm,
  compare = valid_state
)
#> # A tibble: 2 × 6
#>   stage                 prop_in n_distinct prop_na n_out n_diff
#>   <chr>                   <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 wac$contributor_state    1.00        200  0.0346  1493    141
#> 2 wac$state_norm           1            60  0.0348     0      1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
norm_city <- wac %>% 
  distinct(contributor_city, state_norm, zip_norm) %>% 
  mutate(
    city_norm = normal_city(
      city = contributor_city, 
      abbs = usps_city,
      states = c("WA", "DC", "WASHINGTON"),
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

#### Swap

We can further improve normalization by comparing our normalized value
against the *expected* value for that record’s state abbreviation and
ZIP code. If the normalized value is either an abbreviation for or very
similar to the expected value, we can confidently swap those two.

``` r
norm_city <- norm_city %>% 
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

``` r
wac <- left_join(
  x = wac,
  y = norm_city,
  by = c(
    "contributor_city",
    "state_norm", 
    "zip_norm"
  )
)
```

#### Refine

The [OpenRefine](https://openrefine.org/) algorithms can be used to
group similar strings and replace the less common versions with their
most common counterpart. This can greatly reduce inconsistency, but with
low confidence; we will only keep any refined strings that have a valid
city/state/zip combination.

``` r
good_refine <- wac %>% 
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
  )
```

    #> # A tibble: 298 × 5
    #>    state_norm zip_norm city_swap     city_refine       n
    #>    <chr>      <chr>    <chr>         <chr>         <int>
    #>  1 WA         98374    PUAYLLP       PUYALLUP         74
    #>  2 ID         83815    COUER DALENE  COEUR D ALENE    56
    #>  3 WA         98537    COSMPOLOLIS   COSMOPOLIS       35
    #>  4 WA         98284    SEDROWOOLLLEY SEDRO WOOLLEY    33
    #>  5 ID         83816    COUER DALENE  COEUR D ALENE    22
    #>  6 WA         98638    NASSEL        NASELLE          22
    #>  7 WA         98275    MULKITEO      MUKILTEO         18
    #>  8 WA         98065    SNOAUQLMIE    SNOQUALMIE       16
    #>  9 NY         11733    SETAUKET      EAST SETAUKET    15
    #> 10 OH         45202    CINCINATTI    CINCINNATI       15
    #> # ℹ 288 more rows

Then we can join the refined values back to the database.

``` r
wac <- wac %>% 
  left_join(good_refine, by = names(.)) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

Our goal for normalization was to increase the proportion of city values
known to be valid and reduce the total distinct values by correcting
misspellings.

| stage                                | prop_in | n_distinct | prop_na | n_out | n_diff |
|:-------------------------------------|--------:|-----------:|--------:|------:|-------:|
| `str_to_upper(wac$contributor_city)` |   0.984 |      16403 |   0.036 | 92489 |   8054 |
| `wac$city_norm`                      |   0.986 |      15218 |   0.036 | 77709 |   6847 |
| `wac$city_swap`                      |   0.993 |      11323 |   0.036 | 42122 |   2950 |
| `wac$city_refine`                    |   0.993 |      11071 |   0.036 | 41322 |   2699 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/bar_progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar_distinct-1.png)<!-- -->

Before exporting, we can remove the intermediary normalization columns
and rename all added variables with the `_clean` suffix.

``` r
wac <- wac %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  rename_all(~str_remove(., "_raw")) %>% 
  relocate(city_clean, state_clean, .before = zip_clean)
```

``` r
glimpse(sample_n(wac, 50))
#> Rows: 50
#> Columns: 42
#> $ id                         <int> 15713639, 12921313, 5030974, 13034145, 1605044, 16127223, 14415376, 9221402, 257381…
#> $ report_number              <chr> "110072239", "100245795", "100714164", "100273743", "100837191", "110091708", "1100…
#> $ origin                     <chr> "C3", "C3", "C3", "C3", "C3", "C3", "C3", "C3", "C3", "C3", "C3", "C3", "C3", "C3",…
#> $ committee_id               <chr> "15340", "10379", "4163", "13094", "3127", "2573", "26199", "10485", "68", "17554",…
#> $ filer_id                   <chr> "PIERDC 411", "KINGRC 109", "CONDC  807", "MIELT  209", "CITICE 372", "CANDP  507",…
#> $ type                       <chr> "Political Committee", "Political Committee", "Candidate", "Candidate", "Political …
#> $ filer_name                 <chr> "Pierce County Democratic Central Committee (PCDCC)", "KING COUNTY REPUBLICAN CENTR…
#> $ office                     <chr> NA, NA, "STATE REPRESENTATIVE", "COUNTY COMMISSIONER", NA, NA, NA, NA, NA, NA, NA, …
#> $ legislative_district       <chr> NA, NA, "12", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "28", NA, NA, "32", NA, NA, "…
#> $ position                   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "State Representative Pos. 1", …
#> $ party                      <chr> "DEMOCRATIC", "REPUBLICAN", "REPUBLICAN", "REPUBLICAN", NA, NA, NA, "REPUBLICAN", "…
#> $ ballot_number              <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ for_or_against             <chr> NA, NA, NA, NA, "For", NA, "For", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ jurisdiction               <chr> NA, NA, "LEG DISTRICT 12 - HOUSE", "SPOKANE CO", "PUYALLUP SD 003", NA, "SPOKANE SD…
#> $ jurisdiction_county        <chr> NA, NA, "CHELAN", "SPOKANE", NA, NA, "SPOKANE", NA, NA, NA, NA, NA, NA, "PIERCE", N…
#> $ jurisdiction_type          <chr> NA, NA, "Legislative", "Local", NA, NA, "Local", NA, NA, NA, NA, "Statewide", NA, "…
#> $ election_year              <int> 2022, 2008, 2016, 2008, 2019, 2022, 2021, 2012, 2018, 2019, 2008, 2008, 2011, 2022,…
#> $ amount                     <dbl> 27.00, 25.00, 100.00, 250.00, 25.00, 35.00, 3.00, 100.00, 20.00, 5.00, 5.70, 50.00,…
#> $ cash_or_in_kind            <chr> "Cash", "Cash", "Cash", "Cash", "Cash", "Cash", "Cash", "Cash", "Cash", "Cash", "Ca…
#> $ receipt_date               <date> 2022-01-06, 2008-02-13, 2016-07-27, 2008-09-09, 2018-05-31, 2022-05-06, 2021-02-01…
#> $ description                <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ memo                       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ primary_general            <chr> "Full Election", "Full Election", "Primary", "General", "Full Election", "Full Elec…
#> $ code                       <chr> "Individual", "Individual", "Individual", "Individual", "Individual", "Individual",…
#> $ contributor_category       <chr> "Individual", "Individual", "Individual", "Individual", "Individual", "Individual",…
#> $ contributor_name           <chr> "SELLERS DRENA", "GLEDHILL MIYAKO", "SULLIVAN SEAN O", "IMPECOVEN MARJORIE", "NOSWO…
#> $ contributor_address        <chr> "3556 S MADISON ST", "15509 61ST AVE NE", "11825 28TH SE", "P.O. BOX 141142", "4121…
#> $ contributor_city           <chr> "TACOMA", "KENMORE", "LAKE STEVENS", "SPOKANE VALLEY", "TACOMA", "Yakima", "SPOKANE…
#> $ contributor_state          <chr> "WA", "WA", "WA", "WA", "WA", "WA", "WA", "WA", "WA", "WA", "WA", "CA", "WA", "WA",…
#> $ contributor_zip            <chr> "98409", "98028", "98258", "99214", "98407", "98908", "99208", "98310", "98446", "9…
#> $ contributor_occupation     <chr> NA, NA, NA, "BUSINESS OWNER", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "LANDLORD", N…
#> $ contributor_employer_name  <chr> NA, NA, NA, "BLASINGAME INSURANCE", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "SELF",…
#> $ contributor_employer_city  <chr> NA, NA, NA, "SPOKANE VALLEY", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "KENT", NA, N…
#> $ contributor_employer_state <chr> NA, NA, NA, "WA", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "WA", NA, NA, NA, NA, NA,…
#> $ url                        <chr> "https://web.pdc.wa.gov/rptimg/default.aspx?repno=110072239", "https://web.pdc.wa.g…
#> $ contributor_location       <chr> "POINT (-122.49006 47.227)", NA, NA, NA, "POINT (-122.49323 47.27793)", "POINT (-12…
#> $ na_flag                    <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ dupe_flag                  <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ receipt_year               <dbl> 2022, 2008, 2016, 2008, 2018, 2022, 2021, 2012, 2018, 2019, 2008, 2007, 2011, 2022,…
#> $ city_clean                 <chr> "TACOMA", "KENMORE", "LAKE STEVENS", "SPOKANE VALLEY", "TACOMA", "YAKIMA", "SPOKANE…
#> $ state_clean                <chr> "WA", "WA", "WA", "WA", "WA", "WA", "WA", "WA", "WA", "WA", "WA", "CA", "WA", "WA",…
#> $ zip_clean                  <chr> "98409", "98028", "98258", "99214", "98407", "98908", "99208", "98310", "98446", "9…
```

## Conclude

1.  There are 5,952,878 records in the database.
2.  There are 6,962 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 2,018 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("wa", "contribs", "data", "clean"))
clean_path <- path(clean_dir, "wa_contribs_20040101-2023.csv")
write_csv(wac, clean_path, na = "")
(clean_size <- file_size(clean_path))
#> 2G
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
