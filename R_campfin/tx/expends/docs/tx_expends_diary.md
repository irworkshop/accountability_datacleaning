State Data
================
First Last
2019-08-13 13:06:11

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Explore](#explore)

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

Data is obtained from the [Texas Ethics Commission
(TEC)](https://www.ethics.state.tx.us/search/cf/). According to [a TEC
brochure](https://www.ethics.state.tx.us/data/about/Bethic.pdf),

> tatutory duties of the Ethics Commission are in Chapter 571 of the
> Government Code. The agency is responsible for administering these
> laws: (1) Title 15, Election Code, concerning political contributions
> and expenditures, and political advertising…

> The Ethics Commission serves as a repository of required disclosure
> statements for state officials, candidates,political committees,
> lobbyists, and certain district and county judicial officers.

Data is ontained from the [Campaign Finance section of the TEC
website](https://www.ethics.state.tx.us/search/cf/). An entire database
can be downloaded as [a ZIP
file](https://www.ethics.state.tx.us/data/search/cf/TEC_CF_CSV.zip). The
contents of that ZIP and the layout of the files within are outlined in
the [`CFS-ReadMe.txt`
file](https://www.ethics.state.tx.us/data/search/cf/CFS-ReadMe.txt).

> This zip package contains detailed information from campaign finance
> reports filed electronically with the Texas Ethics Commission
> beginning July 1, 2000. Flat File Architecture Record Listing –
> Generated 06/11/2016 12:38:08 PM

``` r
readme <- read_lines(file = "https://www.ethics.state.tx.us/data/search/cf/CFS-ReadMe.txt")
```

At the top of this file is a table of contents.

| Record Name      | File Contents                 | File Name(s)                                            |
| :--------------- | :---------------------------- | :------------------------------------------------------ |
| AssetData        | Assets - Schedule M           | `assets.csv`                                            |
| CandidateData    | Direct Campaign Expenditure…  | `cand.csv`                                              |
| ContributionData | Contributions - Schedules A/C | `contribs_##.csv, cont_ss.csv, cont_t.csv, returns.csv` |
| CoverSheet1Data  | Cover Sheet 1 - Cover sheet…  | `cover.csv, cover_ss.csv, cover_t.csv`                  |
| CoverSheet2Data  | Cover Sheet 2 - Notices rec…  | `notices.csv`                                           |
| CoverSheet3Data  | Cover Sheet 3 - Committee p…  | `purpose.csv`                                           |
| CreditData       | Credits - Schedule K          | `credits.csv`                                           |
| DebtData         | Debts - Schedule L            | `debts.csv`                                             |
| ExpendData       | Expenditures - Schedules F/…  | `expend_##.csv, expn_t.csv`                             |
| ExpendCategory   | Expenditure category codes    | `expn_catg.csv`                                         |
| FilerData        | Filer index                   | `filers.csv`                                            |
| FinalData        | Final reports                 | `final.csv`                                             |
| LoanData         | Loans - Schedule E            | `loans.csv`                                             |
| PledgeData       | Pledges - Schedule B          | `pledges.csv, pldg_ss.csv, pldg_t.csv`                  |
| SpacData         | Index of Specific-purpose c…  | `spacs.csv`                                             |
| TravelData       | Travel outside the State of…  | `travel.csv`                                            |

From this table, we know the ExpendData record (`contribs_##.csv`)
contains the data we want.

> Expenditures - Schedules F/G/H/I - Expenditures from special
> pre-election (formerly Telegram) reports are stored in the file
> `expn_t`. They are kept separate from the expends file to avoid
> creating duplicates, because they are supposed to be re-reported on
> the next regular campaign finance report.

| Field Name              | Type                     | Mask                                                           | Len | Description                   |
| :---------------------- | :----------------------- | :------------------------------------------------------------- | :-- | :---------------------------- |
| `recordType`            | String                   | 20 Record type code - always EXPN                              |     |                               |
| `formTypeCd`            | String                   | 20 TEC form used                                               |     |                               |
| `schedFormTypeCd`       | String                   | 20 TEC Schedule Used                                           |     |                               |
| `reportInfoIdent`       | Long                     | 00000000000                                                    | 11  | Unique report                 |
| `receivedDt`            | Date                     | yyyyMMdd                                                       | 8   | Date report received by TEC   |
| `infoOnlyFlag`          | String                   | 1 Superseded by other report                                   |     |                               |
| `filerIdent`            | String                   | 100 Filer account                                              |     |                               |
| `filerTypeCd`           | String                   | 30 Type of filer                                               |     |                               |
| `filerName`             | String                   | 200 Filer name                                                 |     |                               |
| `expendInfoId`          | Long                     | 00000000000                                                    | 11  | Expenditure unique identifier |
| `expendDt`              | Date                     | yyyyMMdd                                                       | 8   | Expenditure date              |
| `expendAmount`          | BigDecimal 0000000000.00 | 12 Expenditure amount                                          |     |                               |
| `expendDescr`           | String                   | 100 Expenditure description                                    |     |                               |
| `expendCatCd`           | String                   | 30 Expenditure category code                                   |     |                               |
| `expendCatDescr`        | String                   | 100 Expenditure category description                           |     |                               |
| `itemizeFlag`           | String                   | 1 Y indicates that the expenditure is itemized                 |     |                               |
| `travelFlag`            | String                   | 1 Y indicates that the expenditure has associated travel       |     |                               |
| `politicalExpendCd`     | String                   | 30 Political expenditure indicator                             |     |                               |
| `reimburseIntendedFlag` | String                   | 1 Reimbursement intended indicator                             |     |                               |
| `srcCorpContribFlag`    | String                   | 1 Expenditure from corporate funds indicator                   |     |                               |
| `capitalLivingexpFlag`  | String                   | 1 Austin living expense indicator                              |     |                               |
| `payeePersentTypeCd`    | String                   | 30 Type of payee name data - INDIVIDUAL or ENTITY              |     |                               |
| `payeeNameOrganization` | String                   | 100 For ENTITY, the payee organization name                    |     |                               |
| `payeeNameLast`         | String                   | 100 For INDIVIDUAL, the payee last name                        |     |                               |
| `payeeNameSuffixCd`     | String                   | 30 For INDIVIDUAL, the payee name suffix (e.g. JR, MD, II)     |     |                               |
| `payeeNameFirst`        | String                   | 45 For INDIVIDUAL, the payee first name                        |     |                               |
| `payeeNamePrefixCd`     | String                   | 30 For INDIVIDUAL, the payee name prefix (e.g. MR, MRS, MS)    |     |                               |
| `payeeNameShort`        | String                   | 25 For INDIVIDUAL, the payee short name (nickname)             |     |                               |
| `payeeStreetAddr1`      | String                   | 55 Payee street address - line 1                               |     |                               |
| `payeeStreetAddr2`      | String                   | 55 Payee street address - line 2                               |     |                               |
| `payeeStreetCity`       | String                   | 30 Payee street address - city                                 |     |                               |
| `payeeStreetStateCd`    | String                   | 2 Payee street address - state code (e.g. TX, CA) - for        |     |                               |
| `payeeStreetCountyCd`   | String                   | 5 Payee street address - Texas county                          |     |                               |
| `payeeStreetCountryCd`  | String                   | 3 Payee street address - country (e.g. USA, UMI, MEX, CAN)     |     |                               |
| `payeeStreetPostalCode` | String                   | 20 Payee street address - postal code - for USA addresses only |     |                               |
| `payeeStreetRegion`     | String                   | 30 Payee street address - region for country other than USA    |     |                               |

The ExpendCategory record is a small table explaing the expenditure
category codes used.

| Field Name              | Type   | Len | Description                      |
| :---------------------- | :----- | --: | :------------------------------- |
| recordType              | String |  20 | Record type code - always EXCAT  |
| expendCategoryCodeValue | String |  30 | Expenditure category code        |
| expendCategoryCodeLabel | String | 100 | Expenditure category description |

### Download

``` r
raw_dir <- here("tx", "expends", "data", "raw")
dir_create(raw_dir)
zip_url <- "https://www.ethics.state.tx.us/data/search/cf/TEC_CF_CSV.zip"
zip_file <- str_c(raw_dir, basename(zip_url), sep = "/")
```

The ZIP file is fairly large, check the file size before downloading.

``` r
zip_head <- HEAD(zip_url)
zip_size <- as.numeric(headers(zip_head)["content-length"])
number_bytes(zip_size)
#> [1] "518 Mb"
```

If the file hasn’t been downloaded yet, do so now.

``` r
if (!all_files_new(raw_dir, "*.zip$")) {
  download.file(
    url = zip_url, 
    destfile = zip_file
  )
}
```

### Unzip

There are 69 CSV files inside the ZIP archive.

    #> # A tibble: 10 x 3
    #>    name          length date      
    #>    <chr>         <chr>  <date>    
    #>  1 expend_01.csv 114 Mb 2019-08-13
    #>  2 expend_02.csv 102 Mb 2019-08-13
    #>  3 expend_03.csv 106 Mb 2019-08-13
    #>  4 expend_04.csv 105 Mb 2019-08-13
    #>  5 expend_05.csv 105 Mb 2019-08-13
    #>  6 expend_06.csv 78 Mb  2019-08-13
    #>  7 expend_07.csv 77 Mb  2019-08-13
    #>  8 expend_08.csv 72 Mb  2019-08-13
    #>  9 expn_catg.csv 0 Mb   2019-08-13
    #> 10 expn_t.csv    2 Mb   2019-08-13

If the files haven’t been extracted, we can do so now.

``` r
if (!all_files_new(raw_dir, "exp*.csv$")) {
  unzip(
    zipfile = zip_file,
    files = zip_expends,
    exdir = raw_dir
  )
}
```

### Read

The TEC provides a helpful [record layout
key](https://www.ethics.state.tx.us/data/search/cf/CampaignFinanceCSVFileFormat.pdf)
describing the structure of their flat files. We can use the details in
this key to properly read the files into R.

> The CSV file contains comma-delimited records –one line per record.
> Each record consists of fields separated by commas.The following
> characters constitute the permitted list. The space characterand
> commaarenotin this list. `! @ # $ % * -_ + : ; . / 0-9 A-Z a-z`

> If a raw data field contains any character other than these permitted
> characters, then the field is surrounded by double-quotesin the CSV.
> Space is notin the above list–meaning that data containing spaces will
> be double-quoted. Raw field data containing double-quotes will have
> doubled double-quotes in the CSV encoding.In both raw dataand CSV
> encoding, new lines are represented with the escape notation `\n`.

``` r
tx <- vroom(
  file = dir_ls(raw_dir, glob = "*0*.csv"),
  .name_repair = make_clean_names,
  na = c("", "NA", "N/A", "UNKNOWN"),
  delim = ",",
  col_names = TRUE,
  escape_double = TRUE,
  escape_backslash = TRUE,
  col_types = cols(
    .default = col_character(),
    receivedDt = col_date("%Y%m%d"),
    expendDt = col_date("%Y%m%d"),
    expendAmount = col_double()
  )
)

# 3,223,841
problems(tx)
#> # A tibble: 0 x 4
#> # … with 4 variables: row <int>, col <int>, expected <chr>, actual <chr>
```

## Explore

``` r
head(tx)
```

    #> # A tibble: 6 x 36
    #>   record_type form_type_cd sched_form_type… report_info_ide… received_dt info_only_flag filer_ident
    #>   <chr>       <chr>        <chr>            <chr>            <date>      <chr>          <chr>      
    #> 1 EXPN        MPAC         F1               157773           2000-10-12  N              00010883   
    #> 2 EXPN        MPAC         F1               323134           2006-11-01  N              00010883   
    #> 3 EXPN        MPAC         F1               157773           2000-10-12  N              00010883   
    #> 4 EXPN        MPAC         F1               311114           2006-06-01  N              00010883   
    #> 5 EXPN        MPAC         F1               157773           2000-10-12  N              00010883   
    #> 6 EXPN        MPAC         F1               235729           2004-01-02  N              00010883   
    #> # … with 29 more variables: filer_type_cd <chr>, filer_name <chr>, expend_info_id <chr>,
    #> #   expend_dt <date>, expend_amount <dbl>, expend_descr <chr>, expend_cat_cd <chr>,
    #> #   expend_cat_descr <chr>, itemize_flag <chr>, travel_flag <chr>, political_expend_cd <chr>,
    #> #   reimburse_intended_flag <chr>, src_corp_contrib_flag <chr>, capital_livingexp_flag <chr>,
    #> #   payee_persent_type_cd <chr>, payee_name_organization <chr>, payee_name_last <chr>,
    #> #   payee_name_suffix_cd <chr>, payee_name_first <chr>, payee_name_prefix_cd <chr>,
    #> #   payee_name_short <chr>, payee_street_addr1 <chr>, payee_street_addr2 <chr>,
    #> #   payee_street_city <chr>, payee_street_state_cd <chr>, payee_street_county_cd <chr>,
    #> #   payee_street_country_cd <chr>, payee_street_postal_code <chr>, payee_street_region <chr>

``` r
tail(tx)
```

    #> # A tibble: 6 x 36
    #>   record_type form_type_cd sched_form_type… report_info_ide… received_dt info_only_flag filer_ident
    #>   <chr>       <chr>        <chr>            <chr>            <date>      <chr>          <chr>      
    #> 1 103954890   20190626     10.05            Processing Fees  NA          <NA>           Y          
    #> 2 103954891   20190628     12.50            Processing Fees  NA          <NA>           Y          
    #> 3 103954892   20190629     2.70             Processing Fees  NA          <NA>           Y          
    #> 4 103954893   20190629     5.15             Processing Fees  NA          <NA>           Y          
    #> 5 103954894   20190630     12.50            Processing Fees  NA          <NA>           Y          
    #> 6 103954981   20190717     134734.12        Charitable cont… NA          <NA>           Y          
    #> # … with 29 more variables: filer_type_cd <chr>, filer_name <chr>, expend_info_id <chr>,
    #> #   expend_dt <date>, expend_amount <dbl>, expend_descr <chr>, expend_cat_cd <chr>,
    #> #   expend_cat_descr <chr>, itemize_flag <chr>, travel_flag <chr>, political_expend_cd <chr>,
    #> #   reimburse_intended_flag <chr>, src_corp_contrib_flag <chr>, capital_livingexp_flag <chr>,
    #> #   payee_persent_type_cd <chr>, payee_name_organization <chr>, payee_name_last <chr>,
    #> #   payee_name_suffix_cd <chr>, payee_name_first <chr>, payee_name_prefix_cd <chr>,
    #> #   payee_name_short <chr>, payee_street_addr1 <chr>, payee_street_addr2 <chr>,
    #> #   payee_street_city <chr>, payee_street_state_cd <chr>, payee_street_county_cd <chr>,
    #> #   payee_street_country_cd <chr>, payee_street_postal_code <chr>, payee_street_region <chr>

``` r
glimpse(sample_n(tx, 10))
```

    #> Observations: 10
    #> Variables: 36
    #> $ record_type              <chr> NA, NA, "EXPN", "EXPN", "Elliott", "101167103", "EXPN", "EXPN",…
    #> $ form_type_cd             <chr> NA, NA, "GPAC", "JCOH", NA, "20130102", "COH", "GPAC", "SPAC", …
    #> $ sched_form_type_cd       <chr> NA, NA, "F1", "F1", NA, "638.64", "F1", "F1", "F1", "F1"
    #> $ report_info_ident        <chr> "605 Water Lily", "Austin", "100658637", "360212", "840 Voltamp…
    #> $ received_dt              <date> NA, NA, 2017-01-17, 2008-01-14, NA, NA, 2016-01-15, 2012-10-29…
    #> $ info_only_flag           <chr> "McAllen", NA, "N", "N", "Fort Worth", "SALES TAX EXPENSE", "N"…
    #> $ filer_ident              <chr> "TX", "USA", "00054591", "00061232", "TX", "Y", "00057767", "00…
    #> $ filer_type_cd            <chr> NA, NA, "GPAC", "JCOH", NA, "N", "COH", "GPAC", "SPAC", "GPAC"
    #> $ filer_name               <chr> "USA", NA, "Galveston Republican Women - PAC", "Ozmun, Scott (M…
    #> $ expend_info_id           <chr> "78504", "EXPN", "103107189", "102095439", "76108", "N", "10271…
    #> $ expend_dt                <date> NA, NA, 2016-12-29, 2007-11-08, NA, NA, 2015-07-06, 2012-10-26…
    #> $ expend_amount            <dbl> NA, NA, 45.00, 750.00, NA, NA, 54.67, 850.00, 270.62, 0.57
    #> $ expend_descr             <chr> "GPAC", "213576", "Reimbursement for expenditures for the Presi…
    #> $ expend_cat_cd            <chr> "F1", "20030113", "GIFTS", NA, "F1", "Texas Comptroller of Publ…
    #> $ expend_cat_descr         <chr> "515829", "N", NA, NA, "206632", NA, NA, NA, NA, NA
    #> $ itemize_flag             <chr> "20120117", "00020737", "Y", "Y", "20021021", NA, "Y", "Y", "Y"…
    #> $ travel_flag              <chr> "N", "COH", "N", "N", "N", NA, "N", "N", "N", "N"
    #> $ political_expend_cd      <chr> "00015666", "Ratliff, William R.", NA, "Y", "00015741", NA, NA,…
    #> $ reimburse_intended_flag  <chr> "GPAC", "100763157", "N", "N", "SPAC", NA, "N", "N", "N", "N"
    #> $ src_corp_contrib_flag    <chr> "Texas Trial Lawyers Association PAC", "20021105", "N", "N", "T…
    #> $ capital_livingexp_flag   <chr> "100132082", "309.98", "N", "N", "100189618", NA, "N", "N", "N"…
    #> $ payee_persent_type_cd    <chr> "20110929", "Telephone & Mileage", "ENTITY", "INDIVIDUAL", "200…
    #> $ payee_name_organization  <chr> "1000.00", NA, "Texas Federation of Republican Women (TFRW)", N…
    #> $ payee_name_last          <chr> "Campaign Contribution", NA, NA, "Crow", "Constituent Gifts", N…
    #> $ payee_name_suffix_cd     <chr> "DONATIONS", "Y", NA, NA, NA, "USA", NA, NA, NA, NA
    #> $ payee_name_first         <chr> NA, "N", NA, "Pat", NA, "78714-9355", NA, NA, NA, NA
    #> $ payee_name_prefix_cd     <chr> "Y", "N", NA, "MS", "Y", NA, NA, NA, NA, NA
    #> $ payee_name_short         <chr> "N", "N", NA, NA, "N", "EXPN", NA, NA, NA, NA
    #> $ payee_street_addr1       <chr> "Y", "N", "515 Capital of Texas Hwy Suite 133", "1914 Patton La…
    #> $ payee_street_addr2       <chr> "N", "N", NA, NA, "N", "F1", NA, NA, NA, NA
    #> $ payee_street_city        <chr> "N", "ENTITY", "Austin", "Austin", "N", "514703", "South Padre …
    #> $ payee_street_state_cd    <chr> "N", "Ratliff Company", "TX", "TX", "N", "20120114", "TX", "TX"…
    #> $ payee_street_county_cd   <chr> "ENTITY", NA, NA, NA, "ENTITY", "Y", NA, NA, NA, NA
    #> $ payee_street_country_cd  <chr> "Rep. Yvonne Davis Campaign", NA, "USA", "USA", "McPhail Floris…
    #> $ payee_street_postal_code <chr> NA, NA, "78746", "78723", NA, "GPAC", "78597", "77256", "78714-…
    #> $ payee_street_region      <chr> NA, NA, NA, NA, NA, "Bay Area Republican Women PAC", NA, NA, NA…
