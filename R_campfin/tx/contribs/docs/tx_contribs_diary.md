Texas Contributions
================
Kiernan Nicholls
2020-02-27 14:30:12

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
      - [Download](#download)
      - [Unzip](#unzip)
      - [Read](#read)
  - [Explore](#explore)
      - [Missing](#missing)
      - [Categorical](#categorical)
      - [Amounts](#amounts)
      - [Dates](#dates)
  - [Wrangle](#wrangle)
      - [ZIP](#zip)
      - [State](#state)
      - [City](#city)
  - [Conclude](#conclude)
  - [Export](#export)

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

The IRW’s `campfin` package will also have to be installed from GitHub.
This package contains functions custom made to help facilitate the
processing of campaign finance data.

``` r
if (!require("pacman")) install.packages("pacman")
pacman::p_load_gh("irworkshop/campfin")
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  gluedown, # printing markdown
  magrittr, # pipe operators
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
[`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning)
GitHub repository.

The `R_campfin` project uses the [RStudio
projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects)
feature and should be run as such. The project also uses the dynamic
`here::here()` tool for file paths relative to *your* machine.

``` r
# where does this document knit?
here::here()
#> [1] "/home/kiernan/Code/accountability_datacleaning/R_campfin"
```

## Data

Data is obtained from the [Texas Ethics Commission
(TEC)](https://www.ethics.state.tx.us/search/cf/). According to [a TEC
brochure](https://www.ethics.state.tx.us/data/about/Bethic.pdf):

> Statutory duties of the Ethics Commission are in Chapter 571 of the
> Government Code. The agency is responsible for administering these
> laws: (1) Title 15, Election Code, concerning political contributions
> and expenditures, and political advertising…

> The Ethics Commission serves as a repository of required disclosure
> statements for state officials, candidates, political committees,
> lobbyists, and certain district and county judicial officers.

Data is ontained from the [Campaign Finance section of the TEC
website](https://www.ethics.state.tx.us/search/cf/). The entire database
can be downloaded as [a ZIP
archive](https://www.ethics.state.tx.us/data/search/cf/TEC_CF_CSV.zip).
The contents of that ZIP and the layout of the files within are outlined
in the
[`CFS-ReadMe.txt`](https://www.ethics.state.tx.us/data/search/cf/CFS-ReadMe.txt)
file.

> This zip package contains detailed information from campaign finance
> reports filed electronically with the Texas Ethics Commission
> beginning July 1, 2000. Flat File Architecture Record Listing –
> Generated 06/11/2016 12:38:08 PM

``` r
readme <- read_lines("https://www.ethics.state.tx.us/data/search/cf/CFS-ReadMe.txt")
```

At the top of this file is a table of contents.

| record\_name     | file\_contents                                     | file\_name\_s                        |
| :--------------- | :------------------------------------------------- | :----------------------------------- |
| AssetData        | Assets - Schedule M                                | `assets.csv`                         |
| CandidateData    | Direct Campaign Expenditure Candidates             | `cand.csv`                           |
| ContributionData | Contributions - Schedules A/C                      | `contribs_##.csv`, `cont_ss.cs...`   |
| CoverSheet1Data  | Cover Sheet 1 - Cover sheet information and totals | `cover.csv`, `cover_ss.csv`, `co...` |
| CoverSheet2Data  | Cover Sheet 2 - Notices received by candidates/…   | `notices.csv`                        |
| CoverSheet3Data  | Cover Sheet 3 - Committee purpose                  | `purpose.csv`                        |
| CreditData       | Credits - Schedule K                               | `credits.csv`                        |
| DebtData         | Debts - Schedule L                                 | `debts.csv`                          |
| ExpendData       | Expenditures - Schedules F/G/H/I                   | `expend_##.csv`, `expn_t.csv`        |
| ExpendCategory   | Expenditure category codes                         | `expn_catg.csv`                      |
| FilerData        | Filer index                                        | `filers.csv`                         |
| FinalData        | Final reports                                      | `final.csv`                          |
| LoanData         | Loans - Schedule E                                 | `loans.csv`                          |
| PledgeData       | Pledges - Schedule B                               | `pledges.csv`, `pldg_ss.csv`, `p...` |
| SpacData         | Index of Specific-purpose committees               | `spacs.csv`                          |
| TravelData       | Travel outside the State of Texas - Schedule T     | `travel.csv`                         |

From this table, we know the “ContributionData” record
(`contribs_##.csv`) contains the data we want.

> Contributions - Schedules A/C - Contributions from special session and
> special pre-election (formerly Telegram) reports are stored in the
> file cont\_ss and cont\_t. These records are kept separate from the
> contribs files to avoid creating duplicates, because they are supposed
> to be re-reported on the next regular campaign finance report. Files:
> `contribs_##.csv`, `cont_ss.csv`, `cont_t.csv`

| number | field\_name                        | type       | mask          | len | description                                                       |
| -----: | :--------------------------------- | :--------- | :------------ | --: | :---------------------------------------------------------------- |
|      1 | `record_type`                      | String     |               |  20 | Record type code - always RCPT                                    |
|      2 | `form_type_cd`                     | String     |               |  20 | TEC form used                                                     |
|      3 | `sched_form_type_cd`               | String     |               |  20 | TEC Schedule Used                                                 |
|      4 | `report_info_ident`                | Long       | 00000000000   |  11 | Unique report \#                                                  |
|      5 | `received_dt`                      | Date       | yyyyMMdd      |   8 | Date report received by TEC                                       |
|      6 | `info_only_flag`                   | String     |               |   1 | Superseded by other report                                        |
|      7 | `filer_ident`                      | String     |               | 100 | Filer account \#                                                  |
|      8 | `filer_type_cd`                    | String     |               |  30 | Type of filer                                                     |
|      9 | `filer_name`                       | String     |               | 200 | Filer name                                                        |
|     10 | `contribution_info_id`             | Long       | 00000000000   |  11 | Contribution unique identifier                                    |
|     11 | `contribution_dt`                  | Date       | yyyyMMdd      |   8 | Contribution date                                                 |
|     12 | `contribution_amount`              | BigDecimal | 0000000000.00 |  12 | Contribution amount                                               |
|     13 | `contribution_descr`               | String     |               | 100 | Contribution description                                          |
|     14 | `itemize_flag`                     | String     |               |   1 | Y indicates that the contribution is itemized                     |
|     15 | `travel_flag`                      | String     |               |   1 | Y indicates that the contribution has associated travel           |
|     16 | `contributor_persent_type_cd`      | String     |               |  30 | Type of contributor name data - INDIVIDUAL or ENTITY              |
|     17 | `contributor_name_organization`    | String     |               | 100 | For ENTITY, the contributor organization name                     |
|     18 | `contributor_name_last`            | String     |               | 100 | For INDIVIDUAL, the contributor last name                         |
|     19 | `contributor_name_suffix_cd`       | String     |               |  30 | For INDIVIDUAL, the contributor name suffix (e.g. JR, MD, II)     |
|     20 | `contributor_name_first`           | String     |               |  45 | For INDIVIDUAL, the contributor first name                        |
|     21 | `contributor_name_prefix_cd`       | String     |               |  30 | For INDIVIDUAL, the contributor name prefix (e.g. MR, MRS, MS)    |
|     22 | `contributor_name_short`           | String     |               |  25 | For INDIVIDUAL, the contributor short name (nickname)             |
|     23 | `contributor_street_city`          | String     |               |  30 | Contributor street address - city                                 |
|     24 | `contributor_street_state_cd`      | String     |               |   2 | Contributor street address - state code (e.g. TX, CA) - for       |
|     25 | `contributor_street_county_cd`     | String     |               |   5 | Contributor street address - Texas county                         |
|     26 | `contributor_street_country_cd`    | String     |               |   3 | Contributor street address - country (e.g. USA, UMI, MEX, CAN)    |
|     27 | `contributor_street_postal_code`   | String     |               |  20 | Contributor street address - postal code - for USA addresses only |
|     28 | `contributor_street_region`        | String     |               |  30 | Contributor street address - region for country other than USA    |
|     29 | `contributor_employer`             | String     |               |  60 | Contributor employer                                              |
|     30 | `contributor_occupation`           | String     |               |  60 | Contributor occupation                                            |
|     31 | `contributor_job_title`            | String     |               |  60 | Contributor job title                                             |
|     32 | `contributor_pac_fein`             | String     |               |  12 | FEC ID of out-of-state PAC contributor                            |
|     33 | `contributor_oos_pac_flag`         | String     |               |   1 | Indicates if contributor is an out-of-state PAC                   |
|     34 | `contributor_spouse_law_firm_name` | String     |               |  60 | Contributor spouse law firm name                                  |
|     35 | `contributor_parent1law_firm_name` | String     |               |  60 | Contributor parent \#1 law firm name                              |
|     36 | `contributor_parent2law_firm_name` | String     |               |  60 | Contributor parent \#2 law firm name                              |

### Download

``` r
raw_dir <- dir_create(here("tx", "contribs", "data", "raw"))
zip_url <- "https://www.ethics.state.tx.us/data/search/cf/TEC_CF_CSV.zip"
zip_path <- path(raw_dir, basename(zip_url))
```

The ZIP file is fairly large, so check the file size before downloading.

``` r
# size of file
(zip_size <- url_file_size(zip_url))
#> 541M
```

If you have the `speedtest` package, we can automatically calulcate how
long it will take to download such a large file.

``` r
# install.packages("remotes")
# remotes::install_github("hrbrmstr/speedtest")
if (require("speedtest", quietly = TRUE)) {
  # test download speec
  config <- spd_config()
  servers <- spd_servers(config = config)
  closest_servers <- spd_closest_servers(servers, config = config)
  speed <- spd_download_test(closest_servers[1, ], config = config)
  # seconds to download
  ((as.numeric(zip_size)/1e+6) / (speed$mean / 8))
}
```

If the file hasn’t been downloaded yet, do so now.

``` r
if (!this_file_new(zip_path)) {
  download.file(zip_url, zip_path)
}
```

### Unzip

There are 72 CSV files inside the ZIP archive. We can list the content
and extract only those pertaining to contributions.

``` r
(zip_contents <- 
  unzip(zip_path, list = TRUE) %>% 
  as_tibble() %>% 
  clean_names() %>% 
  mutate(
    length = as_fs_bytes(length),
    date = as_date(date)
  ))
#> # A tibble: 72 x 3
#>    name                 length date      
#>    <chr>           <fs::bytes> <date>    
#>  1 ReadMe.txt          130.01K 2020-02-27
#>  2 assets.csv          355.83K 2020-02-27
#>  3 cand.csv             36.41M 2020-02-27
#>  4 cont_ss.csv          16.22M 2020-02-27
#>  5 cont_t.csv            3.63M 2020-02-27
#>  6 contribs_01.csv       98.2M 2020-02-27
#>  7 contribs_02.csv      106.3M 2020-02-27
#>  8 contribs_03.csv     113.69M 2020-02-27
#>  9 contribs_04.csv     107.36M 2020-02-27
#> 10 contribs_05.csv      98.22M 2020-02-27
#> # … with 62 more rows

zip_contribs <- str_subset(zip_contents$name, "contribs_\\d{2}")
length(zip_contribs)
#> [1] 41
```

If the files haven’t been extracted, we can do so now. There are 41
contribution files to extract.

``` r
if (not(all(file_exists(path(raw_dir, zip_contribs))))) {
  unzip(
    zipfile = zip_path,
    files = zip_contribs,
    exdir = raw_dir
  )
}

raw_paths <- dir_ls(raw_dir, glob = "*.csv")
```

### Read

The 41 files can be read into a single data frame using
`vroom::vroom()`. We will consult the `CFS-ReadMe.txt` file for the
column types.

``` r
txc <- vroom(
  file = raw_paths,
  delim = ",",
  escape_backslash = FALSE,
  escape_double = FALSE,
  .name_repair = make_clean_names,
  col_types = cols(
    .default = col_character(),
    reportInfoIdent = col_integer(),
    receivedDt = col_date("%Y%m%d"),
    contributionInfoId = col_integer(),
    contributionDt = col_date("%Y%m%d"),
    contributionAmount = col_double()
  )
)
```

To ensure the file has been read correctly, we can check that a
categorical variable has very few distinct values.

``` r
n_distinct(txc$record_type)
#> [1] 1
```

## Explore

``` r
head(txc)
#> # A tibble: 6 x 28
#>   form  shced rpt_info received_date info_only fil_ident fil_type filer info_id date       amount
#>   <chr> <chr>    <int> <date>        <lgl>     <chr>     <chr>    <chr>   <int> <date>      <dbl>
#> 1 MPAC  A1         730 2000-07-05    FALSE     00010883  MPAC     El P…  1.00e8 2000-05-30   90  
#> 2 MPAC  A1      188853 2002-01-28    FALSE     00010883  MPAC     EL P…  1.00e8 2001-12-28  105  
#> 3 MPAC  A1         730 2000-07-05    FALSE     00010883  MPAC     El P…  1.00e8 2000-06-14   90  
#> 4 MPAC  A1      178424 2001-07-30    TRUE      00010883  MPAC     EL P…  1.00e8 2001-07-19 1500  
#> 5 MPAC  A1         730 2000-07-05    FALSE     00010883  MPAC     El P…  1.00e8 2000-05-30   20.8
#> 6 MPAC  A1      188853 2002-01-28    FALSE     00010883  MPAC     EL P…  1.00e8 2002-01-14  105  
#> # … with 17 more variables: descr <chr>, itemize <lgl>, travel <lgl>, type <chr>, org <chr>,
#> #   last <chr>, suffix <chr>, first <chr>, prefix <chr>, city <chr>, state <chr>, country <chr>,
#> #   zip <chr>, employer <chr>, occupation <chr>, job <chr>, pac <lgl>
tail(txc)
#> # A tibble: 6 x 28
#>   form  shced rpt_info received_date info_only fil_ident fil_type filer info_id date       amount
#>   <chr> <chr>    <int> <date>        <lgl>     <chr>     <chr>    <chr>   <int> <date>      <dbl>
#> 1 JCOH  AJ1     1.01e8 2020-02-26    FALSE     00069769  JCOH     Andr…  1.20e8 2020-01-27   1000
#> 2 CORC… A1      1.01e8 2020-02-26    FALSE     00032740  COH      Whit…  1.20e8 2020-01-29    250
#> 3 CORC… A1      1.01e8 2020-02-26    FALSE     00032740  COH      Whit…  1.20e8 2020-01-30   1000
#> 4 CORC… A1      1.01e8 2020-02-26    FALSE     00032740  COH      Whit…  1.20e8 2020-02-13    500
#> 5 CORC… A1      1.01e8 2020-02-26    FALSE     00032740  COH      Whit…  1.20e8 2020-02-20    200
#> 6 MPAC  A1      1.01e8 2020-02-26    FALSE     00042837  MPAC     Raba…  1.20e8 2020-02-12  20000
#> # … with 17 more variables: descr <chr>, itemize <lgl>, travel <lgl>, type <chr>, org <chr>,
#> #   last <chr>, suffix <chr>, first <chr>, prefix <chr>, city <chr>, state <chr>, country <chr>,
#> #   zip <chr>, employer <chr>, occupation <chr>, job <chr>, pac <lgl>
glimpse(txc)
#> Observations: 17,848,603
#> Variables: 28
#> $ form          <chr> "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "M…
#> $ shced         <chr> "A1", "A1", "A1", "A1", "A1", "A1", "A1", "A1", "A1", "A1", "A1", "A1", "A…
#> $ rpt_info      <int> 730, 188853, 730, 178424, 730, 188853, 730, 179422, 730, 179422, 730, 1794…
#> $ received_date <date> 2000-07-05, 2002-01-28, 2000-07-05, 2001-07-30, 2000-07-05, 2002-01-28, 2…
#> $ info_only     <lgl> FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
#> $ fil_ident     <chr> "00010883", "00010883", "00010883", "00010883", "00010883", "00010883", "0…
#> $ fil_type      <chr> "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "MPAC", "M…
#> $ filer         <chr> "El Paso Energy Corp. PAC", "EL PASO CORPORATION PAC", "El Paso Energy Cor…
#> $ info_id       <int> 100000001, 100000002, 100000003, 100000004, 100000005, 100000006, 10000000…
#> $ date          <date> 2000-05-30, 2001-12-28, 2000-06-14, 2001-07-19, 2000-05-30, 2002-01-14, 2…
#> $ amount        <dbl> 90.00, 105.00, 90.00, 1500.00, 20.84, 105.00, 20.84, 104.17, 65.00, 63.00,…
#> $ descr         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ itemize       <lgl> TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TR…
#> $ travel        <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ type          <chr> "INDIVIDUAL", "INDIVIDUAL", "INDIVIDUAL", "INDIVIDUAL", "INDIVIDUAL", "IND…
#> $ org           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ last          <chr> "LYTAL", "MURRAY", "LYTAL", "ALPERIN", "MACDOUGALL", "MURRAY", "MACDOUGALL…
#> $ suffix        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ first         <chr> "JAMES H.", "STEVEN M", "JAMES H.", "JANICE", "KATHERINE H.", "STEVEN M", …
#> $ prefix        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ city          <chr> "HOUSTON", "PINEHURST", "HOUSTON", "WHEATON", "HOUSTON", "PINEHURST", "HOU…
#> $ state         <chr> "TX", "TX", "TX", "MD", "TX", "TX", "TX", "TX", "TX", "TX", "TX", "TX", "T…
#> $ country       <chr> "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA…
#> $ zip           <chr> "77024", "77362", "77024", "20902", "77024", "77362", "77024", "77024", "7…
#> $ employer      <chr> "THE EL PASO ENERGY CORPORATION", "EL PASO PRODUCTION COMPANY", "THE EL PA…
#> $ occupation    <chr> "MANAGER", "VP OFFSHORE EXPLORATION", "MANAGER", "ASSOCIATE GENERAL COUNSE…
#> $ job           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ pac           <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
```

### Missing

``` r
col_stats(txc, count_na)
#> # A tibble: 28 x 4
#>    col           class         n           p
#>    <chr>         <chr>     <int>       <dbl>
#>  1 form          <chr>         0 0          
#>  2 shced         <chr>         0 0          
#>  3 rpt_info      <int>         0 0          
#>  4 received_date <date>     4466 0.000250   
#>  5 info_only     <lgl>         0 0          
#>  6 fil_ident     <chr>         0 0          
#>  7 fil_type      <chr>         0 0          
#>  8 filer         <chr>     28642 0.00160    
#>  9 info_id       <int>         0 0          
#> 10 date          <date>       17 0.000000952
#> 11 amount        <dbl>         0 0          
#> 12 descr         <chr>  16893063 0.946      
#> 13 itemize       <lgl>         0 0          
#> 14 travel        <lgl>         0 0          
#> 15 type          <chr>        71 0.00000398 
#> 16 org           <chr>  16847689 0.944      
#> 17 last          <chr>   1000268 0.0560     
#> 18 suffix        <chr>  17543437 0.983      
#> 19 first         <chr>    949147 0.0532     
#> 20 prefix        <chr>  15531636 0.870      
#> 21 city          <chr>     17622 0.000987   
#> 22 state         <chr>     12951 0.000726   
#> 23 country       <chr>     10244 0.000574   
#> 24 zip           <chr>     18506 0.00104    
#> 25 employer      <chr>   5755783 0.322      
#> 26 occupation    <chr>   2218068 0.124      
#> 27 job           <chr>  17362618 0.973      
#> 28 pac           <lgl>        71 0.00000398
```

``` r
txc <- txc %>% 
  unite(
    prefix, first, last, suffix, org,
    col = contributor,
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  flag_na(contributor, filer, date, amount)

mean(txc$na_flag)
#> [1] 0.001605672
```

### Categorical

``` r
col_stats(txc, n_distinct)
#> # A tibble: 30 x 4
#>    col           class         n            p
#>    <chr>         <chr>     <int>        <dbl>
#>  1 form          <chr>        23 0.00000129  
#>  2 shced         <chr>        15 0.000000840 
#>  3 rpt_info      <int>    126815 0.00711     
#>  4 received_date <date>     5686 0.000319    
#>  5 info_only     <lgl>         2 0.000000112 
#>  6 fil_ident     <chr>      7667 0.000430    
#>  7 fil_type      <chr>        14 0.000000784 
#>  8 filer         <chr>     12113 0.000679    
#>  9 info_id       <int>  17848603 1           
#> 10 date          <date>     7374 0.000413    
#> 11 amount        <dbl>     59000 0.00331     
#> 12 descr         <chr>     87136 0.00488     
#> 13 itemize       <lgl>         1 0.0000000560
#> 14 travel        <lgl>         2 0.000000112 
#> 15 type          <chr>         3 0.000000168 
#> 16 contributor   <chr>   1842709 0.103       
#> 17 org           <chr>    198043 0.0111      
#> 18 last          <chr>    251412 0.0141      
#> 19 suffix        <chr>        51 0.00000286  
#> 20 first         <chr>    266754 0.0149      
#> 21 prefix        <chr>        33 0.00000185  
#> 22 city          <chr>     33000 0.00185     
#> 23 state         <chr>       178 0.00000997  
#> 24 country       <chr>        49 0.00000275  
#> 25 zip           <chr>    380854 0.0213      
#> 26 employer      <chr>    329830 0.0185      
#> 27 occupation    <chr>    223084 0.0125      
#> 28 job           <chr>     21021 0.00118     
#> 29 pac           <lgl>         3 0.000000168 
#> 30 na_flag       <lgl>         2 0.000000112
```

``` r
explore_plot(
  data = filter(txc, !is.na(form)),
  var = form,
  title = "Texas Contributions by Form",
  caption = "Source: TEC"
)
```

![](../plots/bar_form-1.png)<!-- -->

``` r
explore_plot(
  data = filter(txc, !is.na(shced)),
  var = shced,
  title = "Texas Contributions by Schedule",
  caption = "Source: TEC"
)
```

![](../plots/bar_sched-1.png)<!-- -->

``` r
explore_plot(
  data = filter(txc, !is.na(fil_type)),
  var = fil_type,
  title = "Texas Contributions by Filer Type",
  caption = "Source: TEC"
)
```

![](../plots/bar_filer-1.png)<!-- -->

``` r
explore_plot(
  data = filter(txc, !is.na(type)),
  var = type,
  title = "Texas Contributions by Contributor Type",
  caption = "Source: TEC"
)
```

![](../plots/bar_contributor-1.png)<!-- -->

### Amounts

0.45% of contrbutions have an `amount` less than or euqal to zero.

``` r
summary(txc$amount)
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#>     -325       10       25      242       77 16996410
percent(mean(txc$amount <= 0), 0.01)
#> [1] "0.45%"
```

![](../plots/hist_amount-1.png)<!-- -->

![](../plots/violin_amount_fil-1.png)<!-- -->

![](../plots/violin_amount_con-1.png)<!-- -->

### Dates

We can create a new `year` variable from `date` using
`lubridate::year()`.

``` r
txc <- mutate(txc, year = year(date))
```

The `date` column is very clean, with no dates out of the expected
range.

``` r
count_na(txc$date)
#> [1] 17
min(txc$date, na.rm = TRUE)
#> [1] "1994-10-07"
sum(txc$year < 2000, na.rm = TRUE)
#> [1] 266
max(txc$date, na.rm = TRUE)
#> [1] "2020-02-25"
sum(txc$date > today(), na.rm = TRUE)
#> [1] 0
```

![](../plots/bar_year-1.png)<!-- -->

## Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are tailor made to facilitate this process.

For this database, there are no street addresses.

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
txc <- txc %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  txc$zip,
  txc$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na   n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl>   <dbl>  <dbl>
#> 1 zip        0.667     380854 0.00104 5944539 361888
#> 2 zip_norm   0.998      23756 0.00122   30740   2557
```

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

``` r
txc <- txc %>% 
  mutate(
    state_norm = normal_state(
      state = state,
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = NULL
    )
  )
```

``` r
txc %>% 
  filter(state != state_norm) %>% 
  count(state, state_norm, sort = TRUE)
#> # A tibble: 78 x 3
#>    state state_norm     n
#>    <chr> <chr>      <int>
#>  1 Tx    TX         11984
#>  2 tx    TX           367
#>  3 Te    TE           102
#>  4 Fl    FL            94
#>  5 Ok    OK            61
#>  6 ca    CA            35
#>  7 tX    TX            33
#>  8 Ca    CA            30
#>  9 ny    NY            26
#> 10 va    VA            24
#> # … with 68 more rows
```

``` r
progress_table(
  txc$state,
  txc$state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage      prop_in n_distinct  prop_na n_out n_diff
#>   <chr>        <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 state        0.999        178 0.000726 17069    119
#> 2 state_norm   1.00          89 0.000899  1014     31
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
txc <- txc %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("TX", "DC", "TEXAS"),
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
txc <- txc %>% 
  rename(city_raw = city) %>% 
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

#### Refine

The [OpenRefine](https://openrefine.org/) algorithms can be used to
group similar strings and replace the less common versions with their
most common counterpart. This can greatly reduce inconsistency, but with
low confidence; we will only keep any refined strings that have a valid
city/state/ZIP combination.

``` r
good_refine <- txc %>% 
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

    #> # A tibble: 323 x 5
    #>    state_norm zip_norm city_swap           city_refine              n
    #>    <chr>      <chr>    <chr>               <chr>                <int>
    #>  1 SC         29406    NORTH CHARLESTON    CHARLESTON             180
    #>  2 SC         29419    NORTH CHARLESTON    CHARLESTON              92
    #>  3 GA         31405    SAVAHHAN            SAVANNAH                64
    #>  4 TX         78259    SAN ANONTIO         SAN ANTONIO             47
    #>  5 CA         94583    SAN ROMAN           SAN RAMON               28
    #>  6 TX         77720    BEAMOUNT            BEAUMONT                28
    #>  7 TX         78850    DHANNIS             D HANIS                 26
    #>  8 TX         76180    NORTH RICHARD HILLS NORTH RICHLAND HILLS    25
    #>  9 TX         79938    EL PASO CO          EL PASO                 24
    #> 10 TX         76844    GOLDWAITHE          GOLDTHWAITE             23
    #> # … with 313 more rows

Then we can join the refined values back to the database.

``` r
txc <- txc %>% 
  left_join(good_refine) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Check

We can use the `campfin::check_city()` function to pass the remaining
unknown `city_refine` values (and their `state_norm`) to the Google
Geocode API. The function returns the name of the city or locality which
most associated with those values.

This is an easy way to both check for typos and check whether an unknown
`city_refine` value is actually a completely acceptable neighborhood,
census designated place, or some other locality not found in our
`valid_city` vector from our `zipcodes` database.

First, we’ll filter out any known valid city and aggregate the remaining
records by their city and state. Then, we will only query those unknown
cities which appear at least ten times.

``` r
tac_out <- txc %>% 
  filter(city_refine %out% c(valid_city, extra_city)) %>% 
  count(city_refine, state_norm, sort = TRUE) %>% 
  drop_na() %>% 
  filter(n > 1)
```

Passing these values to `campfin::check_city()` with `purrr::pmap_dfr()`
will return a single tibble of the rows returned by each city/state
combination.

First, we’ll check to see if the API query has already been done and a
file exist on disk. If such a file exists, we can read it using
`readr::read_csv()`. If not, the query will be sent and the file will be
written using `readr::write_csv()`.

``` r
check_file <- here("tx", "contribs", "data", "api_check.csv")
if (file_exists(check_file)) {
  check <- read_csv(
    file = check_file
  )
} else {
  check <- pmap_dfr(
    .l = list(
      tac_out$city_refine, 
      tac_out$state_norm
    ), 
    .f = check_city, 
    key = Sys.getenv("GEOCODE_KEY"), 
    guess = TRUE
  ) %>% 
    mutate(guess = coalesce(guess_city, guess_place)) %>% 
    select(-guess_city, -guess_place)
  write_csv(
    x = check,
    path = check_file
  )
}
```

Any city/state combination with a `check_city_flag` equal to `TRUE`
returned a matching city string from the API, indicating this
combination is valid enough to be ignored.

``` r
valid_locality <- check$guess[check$check_city_flag]
```

Then we can perform some simple comparisons between the queried city and
the returned city. If they are extremely similar, we can accept those
returned locality strings and add them to our list of accepted
additional localities.

``` r
valid_locality <- check %>% 
  filter(!check_city_flag) %>% 
  mutate(
    abb = is_abbrev(original_city, guess),
    dist = str_dist(original_city, guess)
  ) %>%
  filter(abb | dist <= 3) %>% 
  pull(guess) %>% 
  append(valid_locality)
```

#### Progress

| stage        | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :----------- | -------: | ----------: | -------: | -----: | ------: |
| city\_raw)   |   0.9800 |       22627 |   0.0010 | 355870 |   12396 |
| city\_norm   |   0.9891 |       19582 |   0.0011 | 193784 |    9302 |
| city\_swap   |   0.9955 |       14071 |   0.0011 |  80032 |    3799 |
| city\_refine |   0.9956 |       13831 |   0.0011 |  79069 |    3559 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/bar_progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar_distinct-1.png)<!-- -->

## Conclude

``` r
txc <- txc %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean"))
```

``` r
glimpse(sample_n(txc, 20))
#> Observations: 20
#> Variables: 34
#> $ form          <chr> "CORPAC", "CORPAC", "GPAC", "MPAC", "MPAC", "MPAC", "JCOH", "GPAC", "MPAC"…
#> $ shced         <chr> "A1", "A1", "A1", "A2", "A1", "A1", "AJ1", "A1", "A1", "AJ1", "A1", "A1", …
#> $ rpt_info      <int> 100607535, 100645183, 100680249, 318245, 414657, 503198, 395792, 351214, 1…
#> $ received_date <date> 2015-11-05, 2016-09-29, 2018-01-08, 2006-09-01, 2009-06-03, 2011-10-03, 2…
#> $ info_only     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE…
#> $ fil_ident     <chr> "00016847", "00055117", "00066814", "00015540", "00015590", "00017120", "0…
#> $ fil_type      <chr> "MPAC", "MPAC", "GPAC", "MPAC", "MPAC", "MPAC", "JCOH", "GPAC", "MPAC", "J…
#> $ filer         <chr> "United Services Automobile Association Employee PAC", "RNDC Political Act…
#> $ info_id       <int> 112733132, 114259968, 115728720, 101038473, 101719039, 105578306, 10737253…
#> $ date          <date> 2015-04-23, 2016-06-17, 2017-09-14, 2006-07-31, 2009-05-21, 2011-09-16, 2…
#> $ amount        <dbl> 8.00, 1.00, 52.00, 26.72, 10.00, 10.00, 500.00, 152.68, 30.40, 100.00, 50.…
#> $ descr         <chr> NA, NA, NA, "Payroll Deduction", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ itemize       <lgl> TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TR…
#> $ travel        <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ type          <chr> "INDIVIDUAL", "INDIVIDUAL", "INDIVIDUAL", "INDIVIDUAL", "INDIVIDUAL", "IND…
#> $ contributor   <chr> "Jason Scalf", "MARSHALL JACKSON", "Larry Duncan", "Gary Reiley", "THOMAS …
#> $ org           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ last          <chr> "Scalf", "JACKSON", "Duncan", "Reiley", "CANNA", "Huie", "Sams", "KIENTZ",…
#> $ suffix        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "JR", NA, NA, NA, NA, …
#> $ first         <chr> "Jason", "MARSHALL", "Larry", "Gary", "THOMAS L", "Steven L", "John G", "T…
#> $ prefix        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "MR", NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ city_raw      <chr> "San Antonio", "HOUSTON", "Dallas", "San Antonio", "HOUSTON", "Tulsa", "Fo…
#> $ state         <chr> "TX", "TX", "TX", "TX", "TX", "OK", "TX", "CO", "TX", "TX", "TX", "TX", "T…
#> $ country       <chr> "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA", "USA…
#> $ zip           <chr> "782311715", "77043", "75227", "78249", "77067-1025", "74103-4334", "76109…
#> $ employer      <chr> "USAA Fin Plng Svcs Ins Agency", "RNDC", "Self", "Valero Energy Corp", "So…
#> $ occupation    <chr> "Fin Foundations Sr Splst", "SPECIALIST", "Computer Consultant", "Manager …
#> $ job           <chr> NA, NA, NA, NA, NA, NA, "attorney", NA, NA, "Attorney", NA, NA, NA, NA, NA…
#> $ pac           <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ na_flag       <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ year          <dbl> 2015, 2016, 2017, 2006, 2009, 2011, 2008, 2007, 2018, 2013, 2004, 2012, 20…
#> $ zip_clean     <chr> "78231", "77043", "75227", "78249", "77067", "74103", "76109", "80120", "7…
#> $ state_clean   <chr> "TX", "TX", "TX", "TX", "TX", "OK", "TX", "CO", "TX", "TX", "TX", "TX", "T…
#> $ city_clean    <chr> "SAN ANTONIO", "HOUSTON", "DALLAS", "SAN ANTONIO", "HOUSTON", "TULSA", "FO…
```

1.  There are 17,848,603 records in the database.
2.  The range and distribution of `amount` and `date` seem reasonable.
3.  There are 28,659 records missing key variables.
4.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
5.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
clean_dir <- dir_create(here("tx", "contribs", "data", "clean"))
```

``` r
write_csv(
  x = txc,
  path = path(clean_dir, "tx_contribs_clean.csv"),
  na = ""
)
```
