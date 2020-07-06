New Jersey Lobbyying Expenditures
================
Yanqi Xu
2020-07-05 23:33:32

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
  - [Conclude](#conclude)
  - [Export](#export)
  - [Upload](#upload)

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
  readxl, #read excel files
  lubridate, # datetime strings
  gluedown, # printing markdown
  magrittr, # pipe operators
  janitor, # clean data frames
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  rvest, # html scraping
  glue, # combine strings
  here, # relative paths
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
here::here()
#> [1] "/Users/yanqixu/code/accountability_datacleaning/R_campfin"
```

## Data

Lobbying data is obtained from the [Election Law Enforcement
Commission](https://www.elec.state.nj.us/).

> The Election Law Enforcement Commission (ELEC) is dedicated to
> administering “The New Jersey Campaign Contributions and Expenditures
> Reporting Act‚” “The Gubernatorial‚ Legislative Disclosure Statement
> Act‚” “Legislative and Governmental Process Activities Disclosure
> Act‚” and parts of several other laws.

According to ELEC, the overall expenditures associated with lobbying
were reported by year, and can be found in the annual reports.

ELEC [provides a
portal](https://www.elec.state.nj.us/publicinformation/gaa_annual.htm)
for each year’s summary data. We can download [“All 2019 Summary Data
Download Excel
Spreadsheet”](https://www.elec.state.nj.us/pdffiles/Lobby2019/Lobby2019.xlsx)
and for [previous years on the archive
page](https://www.elec.state.nj.us/publicinformation/lobby_statistics_archive.htm).

### Download

We can set up the raw directory.

``` r
raw_dir <- dir_create(here("nj", "lobby", "data", "raw","exp"))
```

``` r
exp_xlsx_urls <- glue("https://www.elec.state.nj.us/pdffiles/Lobby{c(1997:1998,2014:2019)}/Lobby{c(1997:1998,2014:2019)}.xlsx")
exp_xls_urls <- glue("https://www.elec.state.nj.us/pdffiles/Lobby{c(1999:2013)}/Lobby{str_sub(c(1999:2013),start = 3L, end = 4L)}.xls")

exp_urls <- c(exp_xls_urls, exp_xlsx_urls)
wget <- function(url, dir) {
  system2(
    command = "wget",
    args = c(
      "--no-verbose",
      "--content-disposition",
      url,
      paste("-P", raw_dir)
    )
  )
}

if (!all_files_new(raw_dir)) {
  map(exp_urls, wget, raw_dir)
}
```

We can view the file details here.

``` r
raw_info <- as_tibble(dir_info(raw_dir))
```

### Read

There are a lot of individual sheets in each spreadsheet for each year.
These tables are generated from different schedules of disclosure forms
filed by lobbyists. According to the ELEC forms
[factsheet](https://www.elec.state.nj.us/pdffiles/Lobbying/quickfacts.pdf)

> Form L1-L Annual Report for use by a Represented Entity. A Represented
> Entity is any person, partnership, committee, association, trade
> association, corporation, labor union, or any other organization that
> employs, retains, designates, engages, or otherwise uses the services
> of a Governmental Affairs Agent to influence legislation, regulations,
> governmental processes, or to communicate with the general public.
> Form L1-A Annual Report for use by a lobbying firm, a law firm, a
> public relations firm, or other business that employs or engages a
> Governmental Affairs Agent(s). A Governmental Affairs Agent is the
> individual(s) who communicates with, or provides a benefit to, the
> State officials covered by the Act. Form L1-G Annual Report for use by
> a person whose only lobbying activity is communication with the
> general public, referred to as “grassroots lobbying.” Note that
> “person” includes an individual, partnership, committee,
> association, corporation, and any other organization or group of
> persons. Form L-2 For use by a Represented Entity designating a
> Governmental Affairs Agent to file an Annual Report on its behalf.
> Also for use by a person who engages in communication with the general
> public who designates a Governmental Affairs Agent to file an Annual
> Report on its behalf. Note that “person” includes an individual,
> partnership, committee, association, corporation, and any other
> organization or group of persons. The compensation paid to the
> Governmental Affairs Agent or Governmental Affairs Agent Firm must be
> reported. Form L-3 For use by an out-of-state person or entity for the
> purpose of consenting to service of process.

Since the data structure is consistent for each year and we will combine
all the records into a single table, we will create a function to work
with a table first and map that function to each year’s spreadsheets.

#### Expenditures

We’ll deal with “Summary Expend by Category” tables first, which
captures expenditures of different categories.

> SCHEDULE B - SALARY & COMPENSATION PURPOSE: To report the salary and
> compensation paid by the Represented Entity to its Governmental
> Affairs Agent(s). Include the reimbursement of an Agent’s expenses in
> amounts reported. For the Governmental Affairs Agents who are
> employees of the Represented Entity named on page 1, question 1,
> please report the salary and other compensation paid. NOTE: Only the
> pro rata share of each employee’s salary and compensation need be
> included if the employee spends only a portion of his/her time
> lobbying.

> SCHEDULE C - SUPPORT PERSONNEL PURPOSE: To report the costs of support
> personnel who, over the course of the reporting year, individually
> spend 450 or more hours supporting the activities of the Represented
> Entity or Governmental Affairs Agent(s). After determining to which
> person(s) this applies, report the pro rata share of those costs which
> are attributable to supporting the activities of the Represented
> Entity or Governmental Affairs Agent(s) in influencing legislation,
> regulations, governmental processes, or communicating with the general
> public.

> SCHEDULES D-1 & D-2 - ASSESSMENTS (A), MEMBERSHIP FEES (M), OR DUES
> (D) Schedule D-1 - Specific Intent PURPOSE: To report the amount of
> assessments, membership fees, or dues paid by the Represented Entity.
> If the assessments, membership fees, or dues were paid by the
> Represented Entity with the specific intent to influence legislation,
> regulations, governmental processes, or to communicate with the
> general public, please provide the information below: PART I – For
> assessments, membership fees, or dues exceeding $100 for the calendar
> year: PART II – For assessments, membership fees, or dues $100 or less
> for the calendar year:

> Schedule D-2 - Major Purpose PURPOSE: To report the pro rata amount of
> assessments, membership fees, or dues paid by the Represented Entity.
> If the assessments, membership fees, or dues were paid by the
> Represented Entity to an entity whose major purpose is to influence
> legislation, regulations, governmental processes, or to communicate
> with the general public, and, was not reported on Schedule D-1,
> ‘’Specific Intent,’’ please provide the information below: PART I
> – For assessments, membership fees, or dues exceeding $100 for the
> calendar year: PART II – For assessments, membership fees, or dues
> $100 or less for the calendar year:

> SCHEDULE E - COMMUNICATION EXPENSES PURPOSE: To report the costs of
> the preparation and distribution of materials related to influencing
> legislation, regulations, governmental processes, and conducting
> communications with the general public.

> SCHEDULE F - TRAVEL/LODGING NAME OF GOVERNMENTAL AFFAIRS AGENT AMOUNT
> PURPOSE: To report the travel and lodging costs of the Governmental
> Affairs Agents who are employees of the Represented Entity named on
> page 1, question 1, related to influencing legislation, regulations,
> governmental processes, or communicating with the general public.

> SCHEDULE G-1 ITEMIZATION OF BENEFITS WHICH EXCEEDED $25 PER DAY OR
> $200 PER CALENDAR YEAR TO STATE OFFICIALS AND THEIR IMMEDIATE FAMILY
> MEMBERS PURPOSE: To report detailed information concerning benefits
> passed to State officials covered by the Act, as well as the immediate
> family members of these officials. If the value of a benefit exceeded
> $25 per day or $200 per calendar year, report below. (Select one
> description item for each entry from the drop down list. When
> selecting “O - Other”, enter a description in the space provided.

Schedule G-1 is represented in the data as “benefits passing”. The
summary expenditure table is, according to the spreadsheet,an \>
ALPHABETICAL LISTING OF REPRESENTED ENTITIES, GOVERNMENTAL AFFAIRS
AGENTS AND PERSONS COMMUNICATING WITH THE GENERAL PUBLIC - SUMMARY OF
EXPENDITURES BY CATEGORY

According to NJ ELEC, the `total_expenditures` field is the sum of
`in-house salaries`, `support_personnel`,
`assessments_membership_fees_and_dues`, `communication_expenses`,
`travel_and_lodging` as well as `benefits_passing`. The `total_receipts`
captures the amount paid to lobbying firms for their lobbying efforts,
and the compensation to each individual lobbyist also likely come from
such receipts.

In the past, the L form likely corresponds to the L1-L forms, which are
forms filed by lobbying entities(clients), while the A form likely
corresponds to the L1-A forms, which are filed by lobbying firms.

Note that due to the particular structure of the original data, it’s not
possible to determine one-to-one relationship between the client and
lobbying firms. We’ll just arrange the data by filer, which can contain
both clients(usually with a 0 or NA `total_receipts` amount.

``` r
read_exp <- function(short_path){
  path <- path(raw_dir,short_path)
  year_on_file <- str_extract(short_path,"(?<=by)\\d{2,}(?=.xls)")
  year <- if_else(condition = nchar(year_on_file) == 2,
                  true = case_when(
                    year_on_file == "99" ~ "1999",
                    TRUE ~ paste0("20",year_on_file)
                  ),
                  false = year_on_file)
# spreadsheet lob00's data structure is slightly different from others
  target_sheet <- if_else(condition = year %in% c("2000","1997","1999"), true = 1L, false = 4L)
    # we use the "Summary Expend by Category" tab
  if (year %in% c("2016","2018","2019")) {
    
  df <- read_excel(path, sheet = target_sheet,col_types = "text",skip = 2) %>% clean_names()
  } else if(year == "1998"){
    df <- read_excel(path, sheet = target_sheet,col_types = "text",skip = 7,col_names = c("form","date","lobbyist_or_legislative_agent`","in_house_salaries","support_personnel","assessments_membership_fees_dues","communication_expenses","travel_and_lodging","benefit_passing","total_expenditures","reimbursed","compensation_paid_to_outside_agents")) %>% clean_names()
  } else{
    df <- read_excel(path, sheet = target_sheet,col_types = "text") %>% clean_names()
  }
  #the last row is the total value, and we will remove that.
  #df <-  df[1:nrow(df)-1,] 
  df <- df %>% mutate(year = year)
  if (year == "1998"){
    df <- df %>% rename(reimbursed_benefits = reimbursed)
  } else if (year %in% as.character(c(2001:2010))){
    df <- df %>% rename(assessments_membership_fees_dues = assessment_membership_fees_dues,
                        travel_and_lodging = travel_lodging)
  } else if (year %in% as.character(c(2011:2019))) {
    df <- df %>% rename(assessments_membership_fees_dues = assesments_membership_fees_dues,
                        support_personnel = support_personel)
  }
if (year %in% as.character(c(1997:2005))) {
  df <- df %>% rename(
                      filer = lobbyist_or_legislative_agent)
}
  if (year %in% as.character(c(2001:2005))) {
  df <- df %>% rename(
                      compensation_paid_to_outside_agents = out_of_house_salaries)
  }

  
  if (year %in% c("2000","1999")) {
  df <- df %>% rename(
    reimbursed_benefits = reimbursed,
    in_house_salaries = in_house,
    compensation_paid_to_outside_agents = out_of_house,
    support_personnel = support,
    communication_expense = communi,
    travel_and_lodging = travel,
    benefit_passing = benefit,
    total_expenditures = e_total,
    total_receipts = r_total,
    assessments_membership_fees_dues = assessment
  )  
    #select(-c(r_total, e_total,address))
  } else if(year == "1997") {
     df <- df %>% rename(
    in_house_salaries = in_house,
    total_receipts = receipts,
    compensation_paid_to_outside_agents= out_of_house,
    support_personnel = support,
    travel_and_lodging = travel_lodging,
    communication_expenses = communications,
    total_expenditures = expenditures,
    assessments_membership_fees_dues = assessment
  )
  }
      if (year %in% as.character(c(1999:2010))) {
  df <- df %>% rename(communication_expenses = communication_expense
                      )
}
  return(df)
}

njle <- list.files(raw_dir)%>% map_dfr(read_exp) %>% rename(filing_date = date)
```

NJ ELEC also provides a
[guide](https://www.elec.state.nj.us/download/lobby/Annual_Lobbying.pdf)
to each form.

We’ll need to convert the years in excel numeric format to dates

``` r
  njle <- njle %>% mutate(
                      date_clean = if_else(nchar(filing_date)==5,
                                     true = excel_numeric_to_date(as.numeric(filing_date)),
                                     false = as.Date(filing_date, format = "%m/%d/%y")))
```

We also need to remove the rows of total values.

``` r
njle <- njle %>% filter(!is.na(form))
```

## Explore

``` r
glimpse(njle)
#> Rows: 10,339
#> Columns: 16
#> $ form                                <chr> "L00", "L00", "L00", "A00", "A00", "A00", "A00", "L0…
#> $ filing_date                         <chr> "2/13/01", "2/15/01", "2/16/01", "2/16/01", "2/21/01…
#> $ filer                               <chr> "AARP", "AETNA US HEALTHCARE - SEE AMENDMENT - 2/16/…
#> $ address                             <chr> "ONE BOSTON PLACE #1900,BOSTON,MA,02108", "980 JOLLY…
#> $ reimbursed_benefits                 <chr> "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0…
#> $ in_house_salaries                   <chr> "24000", "0", "20000", "0", "12133", "0", "280000", …
#> $ compensation_paid_to_outside_agents <chr> "0", "0", "276619.98999999999", "0", "0", "0", "0", …
#> $ support_personnel                   <chr> "0", "0", "0", "0", "0", "0", "15500", "0", "14066",…
#> $ assessments_membership_fees_dues    <chr> "0", "0", "18000", "0", "0", "0", "0", "0", "1310", …
#> $ communication_expenses              <chr> "450", "0", "0", "0", "2504", "0", "4850", "393.3999…
#> $ travel_and_lodging                  <chr> "6500", "0", "1500", "0", "312", "0", "0", "0", "470…
#> $ benefit_passing                     <chr> "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0…
#> $ total_expenditures                  <chr> "30950", "0", "39500", "0", "14949", "0", "300350", …
#> $ total_receipts                      <chr> "0", "0", "0", "0", "12133", "0", "280000", "0", "0"…
#> $ year                                <chr> "2000", "2000", "2000", "2000", "2000", "2000", "200…
#> $ date_clean                          <date> 2001-02-13, 2001-02-15, 2001-02-16, 2001-02-16, 200…
tail(njle)
#> # A tibble: 6 x 16
#>   form  filing_date filer address reimbursed_bene… in_house_salari… compensation_pa…
#>   <chr> <chr>       <chr> <chr>   <chr>            <chr>            <chr>           
#> 1 A99   36584       O'BR… 120 RT… 0                0                0               
#> 2 A99   36580       ROGE… 115 3R… 0                60000            0               
#> 3 L99   36586       STAT… 1 STAT… 0                46900            136360.70000000…
#> 4 L99   36586       NJ C… 150 W … 0                14000            21000           
#> 5 L99   36587       LUCE… 600 MO… 0                3780             44206.519999999…
#> 6 L99   36588       ASSN… 35 HAL… 0                8923.2000000000… 0               
#> # … with 9 more variables: support_personnel <chr>, assessments_membership_fees_dues <chr>,
#> #   communication_expenses <chr>, travel_and_lodging <chr>, benefit_passing <chr>,
#> #   total_expenditures <chr>, total_receipts <chr>, year <chr>, date_clean <date>
```

### Missing

``` r
col_stats(njle, count_na)
#> # A tibble: 16 x 4
#>    col                                 class      n        p
#>    <chr>                               <chr>  <int>    <dbl>
#>  1 form                                <chr>      0 0       
#>  2 filing_date                         <chr>    253 0.0245  
#>  3 filer                               <chr>      0 0       
#>  4 address                             <chr>   9555 0.924   
#>  5 reimbursed_benefits                 <chr>    255 0.0247  
#>  6 in_house_salaries                   <chr>     54 0.00522 
#>  7 compensation_paid_to_outside_agents <chr>    167 0.0162  
#>  8 support_personnel                   <chr>    176 0.0170  
#>  9 assessments_membership_fees_dues    <chr>    224 0.0217  
#> 10 communication_expenses              <chr>     78 0.00754 
#> 11 travel_and_lodging                  <chr>    131 0.0127  
#> 12 benefit_passing                     <chr>    207 0.0200  
#> 13 total_expenditures                  <chr>      3 0.000290
#> 14 total_receipts                      <chr>   9723 0.940   
#> 15 year                                <chr>      0 0       
#> 16 date_clean                          <date>   253 0.0245
```

``` r
njl <- njle %>% flag_na(filer, filing_date, total_expenditures)
sum(njle$na_flag)
#> [1] 0
```

``` r
njl %>% 
  filter(na_flag) %>% 
  select(filer, filing_date, total_expenditures)
#> # A tibble: 254 x 3
#>    filer                                            filing_date total_expenditures
#>    <chr>                                            <chr>       <chr>             
#>  1 NJ EDUCATION ASSN - SEE AMENDMENT DATED 4-4-03   2/6/03      <NA>              
#>  2 ASSN OF JEWISH FEDERATIONS OF NEW JERSEY         <NA>        35975             
#>  3 AETNA US HEALTHCARE                              <NA>        223573.67999999999
#>  4 AFFORDABLE HOUSING NETWORK OF NJ                 <NA>        3716              
#>  5 AIR BAG & SEATBELT SAFETY CAMPAIGN               <NA>        34000             
#>  6 ALBANESE, GEORGE J - ALMAN MANAGEMENT GROUP INC. <NA>        72525             
#>  7 ALLIANCE OF AMERICAN INSURERS                    <NA>        33115             
#>  8 ALLIEDSIGNAL INC                                 <NA>        64010.5           
#>  9 AMERICAN AUTOMOBILE MANUFACTURERS ASSOC          <NA>        8000              
#> 10 AMERICAN COUNCIL OF LIFE INSURANCE               <NA>        15681.799999999999
#> # … with 244 more rows
```

### Duplicates

There are no duplicate records.

``` r
njl <- flag_dupes(njle, everything())
```

### Categorical

``` r
col_stats(njle, n_distinct)
#> # A tibble: 16 x 4
#>    col                                 class      n       p
#>    <chr>                               <chr>  <int>   <dbl>
#>  1 form                                <chr>     39 0.00377
#>  2 filing_date                         <chr>   1059 0.102  
#>  3 filer                               <chr>   4358 0.422  
#>  4 address                             <chr>    549 0.0531 
#>  5 reimbursed_benefits                 <chr>    163 0.0158 
#>  6 in_house_salaries                   <chr>   4218 0.408  
#>  7 compensation_paid_to_outside_agents <chr>   2468 0.239  
#>  8 support_personnel                   <chr>   1092 0.106  
#>  9 assessments_membership_fees_dues    <chr>    845 0.0817 
#> 10 communication_expenses              <chr>   3176 0.307  
#> 11 travel_and_lodging                  <chr>   2770 0.268  
#> 12 benefit_passing                     <chr>    568 0.0549 
#> 13 total_expenditures                  <chr>   6901 0.667  
#> 14 total_receipts                      <chr>    226 0.0219 
#> 15 year                                <chr>     23 0.00222
#> 16 date_clean                          <date>  1059 0.102
```

### Dates

We can examine the validity of `date_clean`

``` r
min(njle$date_clean)
#> [1] NA
max(njle$date_clean)
#> [1] NA
sum(njle$date_clean > today())
#> [1] NA
```

![](../plots/bar_year-1.png)<!-- -->

## Wrangle

The address field only exists in certain datasets of certain years, but
we can separate them by the comma delimiter.

``` r
njle <- njle %>% 
  separate(
    col = address,
    into = c("addr_sep", "city_sep", "state_zip"),
    sep = "([:blank:]+)?,",
    remove = FALSE,
    extra = "merge",
    fill = "left"
  )

st_regex <- valid_state %>% paste0(collapse = "|")

njle <- njle %>% 
  mutate(state_sep = 
    str_extract(state_zip,st_regex),
    zip_sep = str_remove(state_zip, state_sep) %>% str_remove(",") %>% str_trim()
  )
```

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are tailor made to facilitate this process.

### Address

For the street `addresss` variable, the `campfin::normal_address()`
function will force consistence case, remove punctuation, and abbreviate
official USPS suffixes.

``` r
njle <- mutate(
   .data = njle,
   addr_norm = normal_address(
     address = addr_sep,
     abbs = usps_street,
     na = invalid_city
   )
 )
```

``` r
njle %>% 
  select(addr_sep, addr_norm) %>% 
  distinct() %>% 
  sample_n(10)
#> # A tibble: 10 x 2
#>    addr_sep                    addr_norm                  
#>    <chr>                       <chr>                      
#>  1 15 WASHINGTON VALLEY RD     15 WASHINGTON VLY RD       
#>  2 100 SOUTHGATE PARKWAY       100 SOUTHGATE PKWY         
#>  3 ONE STATE FARM PLZ          ONE STATE FARM PLZ         
#>  4 414 RIVER VIEW PLZ          414 RIV VW PLZ             
#>  5 6 EAST MAIN ST STE 6E       6 E MAIN ST STE 6 E        
#>  6 1901 US HWY 130 S           1901 US HWY 130 S          
#>  7 P O BOX 76 A 150 AIRPORT RD PO BOX 76 A 150 AIRPORT RD 
#>  8 125 HALF MILE RD PO BOX 190 125 HALF MILE RD PO BOX 190
#>  9 200 METROPLEX DR            200 METROPLEX DR           
#> 10 19 8TH AVE                  19 8 TH AVE
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
njle <- mutate(
  .data = njle,
  zip_norm = normal_zip(
    zip = zip_sep,
    na_rep = TRUE
  )
)
```

``` r
progress_table(
  njle$zip_sep,
  njle$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 zip_sep    0.768        198   0.924   182     40
#> 2 zip_norm   0.997        164   0.935     2      3
```

### State

The two-letter state abbreviations are all valid and don’t need to be
normalized.

``` r
prop_in(njle$state_sep, valid_state, na.rm = T)
#> [1] 1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
njle <- njle %>% 
  mutate(
    city_norm = normal_city(
      city = city_sep, 
      abbs = usps_city,
      states = usps_state,
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

#### Progress

| stage      | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :--------- | -------: | ----------: | -------: | -----: | ------: |
| city\_sep) |    0.462 |         277 |    0.924 |    422 |     135 |
| city\_norm |    0.954 |         182 |    0.924 |     36 |      24 |

## Conclude

Before exporting, we can remove the intermediary normalization columns
and rename all added variables with the `_clean` suffix.

``` r
njle <- njle %>% 
  rename_all(~str_replace(., "_norm", "_clean")
             ) %>%
  rename(state_clean = state_sep) %>% 
  select(-state_zip)
```

``` r
glimpse(sample_n(njle, 20))
#> Rows: 20
#> Columns: 23
#> $ form                                <chr> "L-2", "L-2", "L09", "L98", "L-2", "L-2", "L-2", "A1…
#> $ filing_date                         <chr> "43507", "43509", "40227", "2/16/99", "43867", "4386…
#> $ filer                               <chr> "STATE TROOPERS FRATERNAL ASSN OF NJ INC", "TERADATA…
#> $ address                             <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ addr_sep                            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ city_sep                            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ reimbursed_benefits                 <chr> "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0…
#> $ in_house_salaries                   <chr> "0", "0", "31250", "5000", "0", "0", "0", "260000", …
#> $ compensation_paid_to_outside_agents <chr> "36097", "55000", "0", "48000", "58650", "57950.83",…
#> $ support_personnel                   <chr> "0", "0", "12956", "0", "0", "0", "0", "15500", "100…
#> $ assessments_membership_fees_dues    <chr> "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0…
#> $ communication_expenses              <chr> "0", "0", "160", "0", "0", "0", "0", "2150", "169", …
#> $ travel_and_lodging                  <chr> "0", "0", "300", "0", "0", "0", "0", "0", "2500", "0…
#> $ benefit_passing                     <chr> "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0…
#> $ total_expenditures                  <chr> "36097", "55000", "44666", "5000", "58650", "57950.8…
#> $ total_receipts                      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ year                                <int> 2018, 2018, 2009, 1998, 2019, 2019, 2019, 2010, 2005…
#> $ date_clean                          <date> 2019-02-11, 2019-02-13, 2010-02-18, 1999-02-16, 202…
#> $ state_clean                         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ zip_sep                             <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ addr_clean                          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ zip_clean                           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ city_clean                          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
```

1.  There are 10,339 records in the database.
2.  There are 0 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 0 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("nj", "lobby", "data", "clean"))
clean_path <- path(clean_dir, "nj_lobby_exp_clean.csv")
write_csv(njle, clean_path, na = "")
file_size(clean_path)
#> 1.1M
```

## Upload

Using the [duckr](https://github.com/kiernann/duckr) R package, we can
wrap around the [duck](https://duck.sh/) command line tool to upload the
file to the IRW server.

``` r
# remotes::install_github("kiernann/duckr")
s3_dir <- "s3:/publicaccountability/csv/"
s3_path <- path(s3_dir, basename(clean_path))
if (require(duckr)) {
  duckr::duck_upload(clean_path, s3_path)
}
```
