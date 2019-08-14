State Data
================
First Last
2019-08-13 23:11:03

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
  - [Conclude](#conclude)
  - [Export](#export)

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
#> [1] "/home/kiernan/R/accountability_datacleaning/R_campfin"
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
unzip(
  zipfile = zip_file,
  files = zip_expends,
  exdir = raw_dir
)
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

We can use this information as the arguments to `vroom::vroom()` and
read all 8 files at once into a single data frame.

``` r
tx <- vroom(
  file = dir_ls(raw_dir, glob = "*\\d+.csv"),
  .name_repair = make_clean_names,
  na = c("", "NA", "N/A", "UNKNOWN"),
  delim = ",",
  col_names = TRUE,
  escape_double = TRUE,
  escape_backslash = FALSE,
  id = "file",
  locale = locale(tz = "US/Central"),
  col_types = cols(
    .default = col_character(),
    receivedDt = col_date("%Y%m%d"),
    expendDt = col_date("%Y%m%d"),
    expendAmount = col_double()
  )
)

tx <- tx %>%
  filter(expend_dt > "2008-01-01") %>% 
  mutate(
    capital_livingexp_flag = capital_livingexp_flag %>% 
      str_remove_all("X") %>%
      str_remove_all(",") %>%
      na_if("")
  ) %>% 
  # turn Y/N to T/F
  mutate_if(is_binary, to_logical) %>% 
  # shorten file var
  mutate(file = basename(file)) %>%
  # move to end of file
  select(everything(), file)
```

## Explore

``` r
head(tx)
```

    #> # A tibble: 6 x 37
    #>   file  record_type form_type_cd sched_form_type… report_info_ide… received_dt info_only_flag
    #>   <chr> <chr>       <chr>        <chr>            <chr>            <date>      <lgl>         
    #> 1 expe… EXPN        MPAC         F1               527709           2012-05-02  FALSE         
    #> 2 expe… EXPN        MPAC         F1               527709           2012-05-02  FALSE         
    #> 3 expe… EXPN        MPAC         F1               527709           2012-05-02  FALSE         
    #> 4 expe… EXPN        MPAC         F1               527709           2012-05-02  FALSE         
    #> 5 expe… EXPN        MPAC         F1               527709           2012-05-02  FALSE         
    #> 6 expe… EXPN        MPAC         F1               527709           2012-05-02  FALSE         
    #> # … with 30 more variables: filer_ident <chr>, filer_type_cd <chr>, filer_name <chr>,
    #> #   expend_info_id <chr>, expend_dt <date>, expend_amount <dbl>, expend_descr <chr>,
    #> #   expend_cat_cd <chr>, expend_cat_descr <chr>, itemize_flag <chr>, travel_flag <lgl>,
    #> #   political_expend_cd <lgl>, reimburse_intended_flag <lgl>, src_corp_contrib_flag <lgl>,
    #> #   capital_livingexp_flag <lgl>, payee_persent_type_cd <lgl>, payee_name_organization <chr>,
    #> #   payee_name_last <chr>, payee_name_suffix_cd <chr>, payee_name_first <chr>,
    #> #   payee_name_prefix_cd <chr>, payee_name_short <chr>, payee_street_addr1 <chr>,
    #> #   payee_street_addr2 <chr>, payee_street_city <chr>, payee_street_state_cd <chr>,
    #> #   payee_street_county_cd <chr>, payee_street_country_cd <chr>, payee_street_postal_code <chr>,
    #> #   payee_street_region <chr>

``` r
tail(tx)
```

    #> # A tibble: 6 x 37
    #>   file  record_type form_type_cd sched_form_type… report_info_ide… received_dt info_only_flag
    #>   <chr> <chr>       <chr>        <chr>            <chr>            <date>      <lgl>         
    #> 1 expe… EXPN        CORCOH       F1               100757289        2019-08-09  FALSE         
    #> 2 expe… EXPN        CORCOH       F1               100757289        2019-08-09  FALSE         
    #> 3 expe… EXPN        CORCOH       F1               100757289        2019-08-09  FALSE         
    #> 4 expe… EXPN        CORCOH       F1               100757289        2019-08-09  FALSE         
    #> 5 expe… EXPN        COHFR        F1               100757394        2019-08-12  FALSE         
    #> 6 expe… EXPN        GPAC         F1               100757413        2019-08-12  FALSE         
    #> # … with 30 more variables: filer_ident <chr>, filer_type_cd <chr>, filer_name <chr>,
    #> #   expend_info_id <chr>, expend_dt <date>, expend_amount <dbl>, expend_descr <chr>,
    #> #   expend_cat_cd <chr>, expend_cat_descr <chr>, itemize_flag <chr>, travel_flag <lgl>,
    #> #   political_expend_cd <lgl>, reimburse_intended_flag <lgl>, src_corp_contrib_flag <lgl>,
    #> #   capital_livingexp_flag <lgl>, payee_persent_type_cd <lgl>, payee_name_organization <chr>,
    #> #   payee_name_last <chr>, payee_name_suffix_cd <chr>, payee_name_first <chr>,
    #> #   payee_name_prefix_cd <chr>, payee_name_short <chr>, payee_street_addr1 <chr>,
    #> #   payee_street_addr2 <chr>, payee_street_city <chr>, payee_street_state_cd <chr>,
    #> #   payee_street_county_cd <chr>, payee_street_country_cd <chr>, payee_street_postal_code <chr>,
    #> #   payee_street_region <chr>

``` r
glimpse(sample_n(tx, 10))
```

    #> Observations: 10
    #> Variables: 37
    #> $ file                     <chr> "expend_03.csv", "expend_06.csv", "expend_08.csv", "expend_04.c…
    #> $ record_type              <chr> "EXPN", "EXPN", "EXPN", "EXPN", "EXPN", "EXPN", "EXPN", "EXPN",…
    #> $ form_type_cd             <chr> "COH", "GPAC", "GPAC", "CORPAC", "MPAC", "SCCOH", "JCOH", "COH"…
    #> $ sched_form_type_cd       <chr> "F1", "F1", "F1", "F1", "F1", "F1", "F1", "F1", "I", "F1"
    #> $ report_info_ident        <chr> "643302", "100627037", "100722595", "583457", "544138", "100626…
    #> $ received_dt              <date> 2015-01-15, 2016-03-17, 2018-10-08, 2013-08-13, 2012-09-26, 20…
    #> $ info_only_flag           <lgl> FALSE, FALSE, FALSE, TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, FA…
    #> $ filer_ident              <chr> "00030098", "00015649", "00062747", "00051153", "00018754", "00…
    #> $ filer_type_cd            <chr> "COH", "GPAC", "GPAC", "SPAC", "MPAC", "SCC", "JCOH", "COH", "G…
    #> $ filer_name               <chr> "Craddick, Christi L.", "Dallas Fire Fighters Public Safety Com…
    #> $ expend_info_id           <chr> "101045052", "102853407", "103676252", "101532417", "100506394"…
    #> $ expend_dt                <date> 2014-12-31, 2016-02-25, 2018-08-14, 2013-05-23, 2012-09-19, 20…
    #> $ expend_amount            <dbl> 2111.84, 1000.00, 500.00, 79.06, 500.00, 84.00, 10000.00, 20.15…
    #> $ expend_descr             <chr> "Schedule G reimbursement", " State Representative", " Politica…
    #> $ expend_cat_cd            <chr> "LOAN", "DONATIONS", "DONATIONS", "FOOD", "DONATIONS", "FOOD", …
    #> $ expend_cat_descr         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
    #> $ itemize_flag             <chr> "Y", "Y", "Y", "Y", "Y", "Y", "Y", "Y", "Y", "Y"
    #> $ travel_flag              <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
    #> $ political_expend_cd      <lgl> TRUE, NA, NA, TRUE, TRUE, NA, TRUE, NA, NA, TRUE
    #> $ reimburse_intended_flag  <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
    #> $ src_corp_contrib_flag    <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
    #> $ capital_livingexp_flag   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
    #> $ payee_persent_type_cd    <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
    #> $ payee_name_organization  <chr> NA, "Lance Gooden Campaign", NA, "The Carillon", "Sylvester Tur…
    #> $ payee_name_last          <chr> "Craddick", NA, "Lozano", NA, NA, NA, NA, NA, NA, NA
    #> $ payee_name_suffix_cd     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
    #> $ payee_name_first         <chr> "Christi L.", NA, "Jose (JM)", NA, NA, NA, NA, NA, NA, NA
    #> $ payee_name_prefix_cd     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
    #> $ payee_name_short         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
    #> $ payee_street_addr1       <chr> "1500 Dillman St", "PO Box 2125", "635 E King Ave", "1900 Unive…
    #> $ payee_street_addr2       <chr> NA, NA, NA, NA, "Suite 250", NA, NA, NA, NA, "PO Box 20"
    #> $ payee_street_city        <chr> "Austin", "Terrell", "Kingsville", "Austin", "Houston", "Fort W…
    #> $ payee_street_state_cd    <chr> "TX", "TX", "TX", "TX", "TX", "TX", "TX", "CA", "TX", "TX"
    #> $ payee_street_county_cd   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
    #> $ payee_street_country_cd  <chr> "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", …
    #> $ payee_street_postal_code <chr> "78703-2720", "75160", "78363", "78705", "77002", "76185", "770…
    #> $ payee_street_region      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA

### Missing

``` r
glimpse_fun(tx, count_na)
```

    #> # A tibble: 37 x 4
    #>    var                      type        n        p
    #>    <chr>                    <chr>   <int>    <dbl>
    #>  1 file                     chr         0 0       
    #>  2 record_type              chr         0 0       
    #>  3 form_type_cd             chr         0 0       
    #>  4 sched_form_type_cd       chr         0 0       
    #>  5 report_info_ident        chr         0 0       
    #>  6 received_dt              date      510 0.000211
    #>  7 info_only_flag           lgl         0 0       
    #>  8 filer_ident              chr         0 0       
    #>  9 filer_type_cd            chr         0 0       
    #> 10 filer_name               chr       551 0.000228
    #> 11 expend_info_id           chr         0 0       
    #> 12 expend_dt                date        0 0       
    #> 13 expend_amount            dbl         0 0       
    #> 14 expend_descr             chr      1838 0.000761
    #> 15 expend_cat_cd            chr    482411 0.200   
    #> 16 expend_cat_descr         chr   2332525 0.966   
    #> 17 itemize_flag             chr         0 0       
    #> 18 travel_flag              lgl         0 0       
    #> 19 political_expend_cd      lgl    575755 0.238   
    #> 20 reimburse_intended_flag  lgl         0 0       
    #> 21 src_corp_contrib_flag    lgl     14990 0.00621 
    #> 22 capital_livingexp_flag   lgl    286152 0.118   
    #> 23 payee_persent_type_cd    lgl   2415267 1       
    #> 24 payee_name_organization  chr    497173 0.206   
    #> 25 payee_name_last          chr   1917161 0.794   
    #> 26 payee_name_suffix_cd     chr   2409791 0.998   
    #> 27 payee_name_first         chr   1917858 0.794   
    #> 28 payee_name_prefix_cd     chr   2266336 0.938   
    #> 29 payee_name_short         chr   2415267 1       
    #> 30 payee_street_addr1       chr     15774 0.00653 
    #> 31 payee_street_addr2       chr   2179340 0.902   
    #> 32 payee_street_city        chr     10577 0.00438 
    #> 33 payee_street_state_cd    chr      7749 0.00321 
    #> 34 payee_street_county_cd   chr   2415267 1       
    #> 35 payee_street_country_cd  chr       768 0.000318
    #> 36 payee_street_postal_code chr     14864 0.00615 
    #> 37 payee_street_region      chr   2414318 1.000

We can use `campfin::flag_na()` to create a new `na_flag` variable to
identify any record missing one of the values needed to identify the
transaction.

``` r
tx <- tx %>%
  mutate(
    payee_name = coalesce(
      payee_name_last, 
      payee_name_organization
    )
  ) %>% 
  flag_na(
    filer_name,
    expend_dt,
    expend_amount,
    payee_name
  ) %>% 
  select(-payee_name)

sum(tx$na_flag)
#> [1] 610
mean(tx$na_flag)
#> [1] 0.0002525601
```

### Duplicates

``` r
tx <- flag_dupes(tx, -expend_info_id)

sum(tx$dupe_flag)
#> [1] 42751
mean(tx$dupe_flag)
#> [1] 0.01770032
```

### Categorical

``` r
glimpse_fun(tx, n_distinct)
```

    #> # A tibble: 39 x 4
    #>    var                      type        n           p
    #>    <chr>                    <chr>   <int>       <dbl>
    #>  1 file                     chr         8 0.00000331 
    #>  2 record_type              chr         1 0.000000414
    #>  3 form_type_cd             chr        24 0.00000994 
    #>  4 sched_form_type_cd       chr        11 0.00000455 
    #>  5 report_info_ident        chr    101121 0.0419     
    #>  6 received_dt              date     3615 0.00150    
    #>  7 info_only_flag           lgl         2 0.000000828
    #>  8 filer_ident              chr      6640 0.00275    
    #>  9 filer_type_cd            chr        14 0.00000580 
    #> 10 filer_name               chr     10081 0.00417    
    #> 11 expend_info_id           chr   2415267 1          
    #> 12 expend_dt                date     4225 0.00175    
    #> 13 expend_amount            dbl    168793 0.0699     
    #> 14 expend_descr             chr    549528 0.228      
    #> 15 expend_cat_cd            chr        21 0.00000869 
    #> 16 expend_cat_descr         chr     15906 0.00659    
    #> 17 itemize_flag             chr         1 0.000000414
    #> 18 travel_flag              lgl         2 0.000000828
    #> 19 political_expend_cd      lgl         3 0.00000124 
    #> 20 reimburse_intended_flag  lgl         2 0.000000828
    #> 21 src_corp_contrib_flag    lgl         3 0.00000124 
    #> 22 capital_livingexp_flag   lgl         3 0.00000124 
    #> 23 payee_persent_type_cd    lgl         1 0.000000414
    #> 24 payee_name_organization  chr    215923 0.0894     
    #> 25 payee_name_last          chr     31163 0.0129     
    #> 26 payee_name_suffix_cd     chr        26 0.0000108  
    #> 27 payee_name_first         chr     20407 0.00845    
    #> 28 payee_name_prefix_cd     chr        30 0.0000124  
    #> 29 payee_name_short         chr         1 0.000000414
    #> 30 payee_street_addr1       chr    369931 0.153      
    #> 31 payee_street_addr2       chr     18763 0.00777    
    #> 32 payee_street_city        chr     13575 0.00562    
    #> 33 payee_street_state_cd    chr        84 0.0000348  
    #> 34 payee_street_county_cd   chr         1 0.000000414
    #> 35 payee_street_country_cd  chr        58 0.0000240  
    #> 36 payee_street_postal_code chr     35199 0.0146     
    #> 37 payee_street_region      chr       148 0.0000613  
    #> 38 na_flag                  lgl         2 0.000000828
    #> 39 dupe_flag                lgl         2 0.000000828

![](../plots/filer_bar-1.png)<!-- -->

![](../plots/category_bar-1.png)<!-- -->

### Continuous

#### Amounts

``` r
summary(tx$expend_amount)
```

    #>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
    #>     -350       43      157     1286      575 16151362

![](../plots/amount_histogram-1.png)<!-- -->

![](../plots/amount_violin_what-1.png)<!-- -->

![](../plots/amount_violin_who-1.png)<!-- -->

#### Dates

To better explore and search the database, we will create a `expend_yr`
variable from `expend_dt` using `lubridate::year()`

``` r
tx <- mutate(tx, expend_yr = year(expend_dt))
```

The date range is fairly clean, with 0 values after 2019-08-13 and only
0 before the year 2000.

``` r
min(tx$expend_dt, na.rm = TRUE)
#> [1] "2008-01-02"
sum(tx$expend_yr < 2000, na.rm = TRUE)
#> [1] 0
max(tx$expend_dt, na.rm = TRUE)
#> [1] "2019-08-05"
sum(tx$expend_dt > today(), na.rm = TRUE)
#> [1] 0
```

We can see that the few expenditures in 1994 and 1999 seem to be
outliers, with the vast majority of expenditures coming from 2000
through 2019. We will flag these records.

``` r
count(tx, expend_yr, sort = FALSE)
```

    #> # A tibble: 12 x 2
    #>    expend_yr      n
    #>        <dbl>  <int>
    #>  1      2008 213268
    #>  2      2009 154416
    #>  3      2010 262524
    #>  4      2011 154829
    #>  5      2012 243059
    #>  6      2013 182011
    #>  7      2014 265769
    #>  8      2015 158690
    #>  9      2016 220081
    #> 10      2017 181985
    #> 11      2018 300476
    #> 12      2019  78159

``` r
tx <- mutate(tx, date_flag = is_less_than(expend_yr, 2000))
sum(tx$date_flag, na.rm = TRUE)
#> [1] 0
```

## Wrangle

We can use the `campfin::normal_*()` functions to perform some basic and
*confident* programatic text normalization to the geographic data for
payees. This helps improve the searchability of the database and more
confidently links records.

### Address

``` r
# need version 0.8.99.9
packageVersion("tidyr")
#> [1] '0.8.99.9000'
tx <- tx %>% 
  # combine street addr
  unite(
    col = payee_street_addr_comb,
    starts_with("payee_street_addr"),
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  # normalize combined addr
  mutate(
    address_norm = normal_address(
      address = payee_street_addr_comb,
      add_abbs = NULL,
      na_rep = TRUE
    )
  )
```

``` r
select(tx, payee_street_addr_comb, address_norm)
```

    #> # A tibble: 2,415,267 x 2
    #>    payee_street_addr_comb          address_norm                   
    #>    <chr>                           <chr>                          
    #>  1 228 S Washington St Ste B-20    228 S WASHINGTON ST STE B 20   
    #>  2 900 19th Street N.W. 8th Floor  900 19TH STREET NW 8TH FLOOR   
    #>  3 1420 West Canal Court Ste 10    1420 WEST CANAL COURT STE 10   
    #>  4 201 Massachusetts Ave NE Ste C3 201 MASSACHUSETTS AVE NE STE C3
    #>  5 213 Ashby ST                    213 ASHBY ST                   
    #>  6 900 19th Street NW_8th Floor    900 19TH STREET NW 8TH FLOOR   
    #>  7 PO Box 8166                     PO BOX 8166                    
    #>  8 104 Hume Avenue                 104 HUME AVENUE                
    #>  9 104 Hume Ave                    104 HUME AVE                   
    #> 10 12535 Cedar Key Trail           12535 CEDAR KEY TRAIL          
    #> # … with 2,415,257 more rows

### ZIP

``` r
n_distinct(tx$payee_street_postal_code)
#> [1] 35199
prop_in(tx$payee_street_postal_code, geo$zip, na.rm = TRUE)
#> [1] 0.8993798
length(setdiff(tx$payee_street_postal_code, geo$zip))
#> [1] 23997
```

``` r
tx <- tx %>% 
  mutate(
    zip_norm = normal_zip(
      zip = payee_street_postal_code,
      na_rep = TRUE
    )
  )
```

``` r
n_distinct(tx$zip_norm)
#> [1] 13455
prop_in(tx$zip_norm, geo$zip, na.rm = TRUE)
#> [1] 0.9958842
length(setdiff(tx$zip_norm, geo$zip))
#> [1] 1696
```

### State

``` r
n_distinct(tx$payee_street_state_cd)
#> [1] 84
prop_in(tx$payee_street_state_cd, geo$state, na.rm = TRUE)
#> [1] 0.9989537
length(setdiff(tx$payee_street_state_cd, geo$state))
#> [1] 25
```

``` r
tx <- tx %>% 
  mutate(
    state_norm = normal_state(
      state = payee_street_state_cd,
      abbreviate = FALSE,
      na_rep = TRUE
    )
  )
```

``` r
n_distinct(tx$state_norm)
#> [1] 64
prop_in(tx$state_norm, geo$state, na.rm = TRUE)
#> [1] 0.9999942
setdiff(tx$state_norm, geo$state)
#> [1] NA   "BE" "X"  "UN" "T"  "RZ"
tx$state_norm[which(tx$state_norm %out% geo$state)] <- NA
```

### City

``` r
n_distinct(tx$payee_street_city)
#> [1] 13575
prop_in(str_to_upper(tx$payee_street_city), geo$city, na.rm = TRUE)
#> [1] 0.964887
length(setdiff(str_to_upper(tx$payee_street_city), geo$city))
#> [1] 6130
```

#### Normalize

``` r
tx <- tx %>% 
  mutate(
    city_norm = normal_city(
      city = payee_street_city, 
      geo_abbs = usps_city,
      st_abbs = c("TX", "DC", "TEXAS"),
      na = na_city,
      na_rep = TRUE
    )
  )
```

``` r
n_distinct(tx$city_norm)
#> [1] 9399
prop_in(tx$city_norm, geo$city, na.rm = TRUE)
#> [1] 0.9762946
length(setdiff(tx$city_norm, geo$city))
#> [1] 4693
```

#### Swap

``` r
tx <- tx %>% 
  left_join(
    y = geo,
    by = c(
      "state_norm" = "state",
      "zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_dist = stringdist(city_norm, city_match),
    city_swap = if_else(
      condition = equals(match_dist, 1),
      true = city_match,
      false = city_norm
    )
  )
```

``` r
n_distinct(tx$city_swap)
#> [1] 6270
prop_in(tx$city_swap, geo$city, na.rm = TRUE)
#> [1] 0.9861505
length(setdiff(tx$city_swap, geo$city))
#> [1] 1658
```

#### Refine

## Conclude

1.  There are 2415267 records in the database.
2.  There are 42751 duplicate records in the database.
3.  The range and distribution of `expend_amount` and `expend_dt` seem
    reasonable.
4.  There are 610 records missing either recipient or date.
5.  Consistency in goegraphic data has been improved with
    `campfin::normal_*()`.
6.  The 5-digit `zip_norm` variable has been created with
    `campfin::normal_zip()`.
7.  The 4-digit `expend_yr` variable has been created with
    `lubridate::year()`.

## Export

``` r
proc_dir <- here("tx", "expends", "data", "processed")
dir_create(proc_dir)
```

``` r
tx %>% 
  write_csv(
    path = glue("{proc_dir}/tx_expends_clean.csv"),
    na = ""
  )
```
