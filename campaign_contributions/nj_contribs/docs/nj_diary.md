---
title: "Data Diary"
subtitle: "New Jersey Contributions"
author: "Kiernan Nicholls"
date: "2019-05-28 14:59:43"
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


```r
# install.packages("pacman")
pacman::p_load(
  tidyverse,
  RSelenium,
  lubridate,
  magrittr,
  janitor,
  zipcode, 
  here
)
```

## Data

Data comes courtesy of the New Jersey Election Law Enforcement Commission (ELEC)
[website](https://www.elec.state.nj.us/ELECReport/). The data can be downloaded after a search
of the database.

The website is organized by filing report. A search returns a list of R-1 reports, each report
containing the information on the various contributors. Each report must be downloaded 
individually. As of right now, there are 11310 "rows" (reports), each with a number of records.

We can use an `RSelenium` browser to automate the collection of data. Here, we will search for
reports from 2008 through 2018, then download the first report.


```r
# open rselenium client
rs_driver <- rsDriver(port = 4444L, browser = "firefox",)
remote_driver <- rs_driver$client
# naviate to the ELEC portal
remote_driver$navigate("https://www.elec.state.nj.us/ELECReport/searchcontribcandidate.aspx")
# type in our search fields
remote_driver$findElement(using = "css", "#txtStartDate")$sendKeysToElement(list("01/01/2008"))
remote_driver$findElement(using = "css", "#txtEndDate")$sendKeysToElement(list("12/31/2008"))
# load the search parameters
remote_driver$findElement(using = "css", "#btnSearch")$clickElement()
# download the top report
remote_driver$findElement(
  using = "css","#ContentPlaceHolder1_BITSReportViewer1_btnDownloadData")$clickElement()
# close the remote browser
remote_driver$close()
rs_driver$server$stop()
```

Below is the structure of this downloaded report:


```r
# list files
files <- list.files(
  path = here("nj_contribs", "data"), 
  pattern = "csv$", 
  full.names = TRUE
)

# read the latest file
nj_sample <- files[file.mtime(files) == max(file.mtime(files))] %>% 
  read_csv(col_types = cols(
    .default = col_character(),
    `RECIPIENT ELECTION YEAR` = col_double(),
    `CONT AMT` = col_double(),
    `CONT DATE` = col_date("%m/%d/%Y"))) %>% 
  clean_names()

# view structure
glimpse(nj_sample)
```

```
## Observations: 1
## Variables: 23
## $ contributor             <chr> "GILMORE & MONAHAN"
## $ street1                 <chr> "10 ALLEN ST"
## $ street2                 <chr> NA
## $ city                    <chr> "TOMS RIVER"
## $ state                   <chr> "NJ"
## $ zip                     <chr> "08753"
## $ emp_address             <chr> NA
## $ emp_name                <chr> NA
## $ emp_street1             <chr> NA
## $ emp_city                <chr> NA
## $ emp_state               <chr> NA
## $ emp_zip                 <chr> NA
## $ occupation_name         <chr> NA
## $ recipient_name          <chr> "ACROPOLIS  STEPHEN C"
## $ recipient_election_type <chr> "PRIMARY"
## $ recipient_election_year <dbl> 2009
## $ recipient_office        <chr> "MAYOR"
## $ recipient_location      <chr> "BRICK TOWNSHIP"
## $ recipient_party         <chr> "REPUBLICAN"
## $ cont_amt                <dbl> 3000
## $ cont_date               <date> 2008-12-30
## $ contributor_type        <chr> "BUSINESS/CORP"
## $ contribution_short_type <chr> "MONETARY"
```

We might eventually automate the collection of many reports in a similar manner, but for now the
rest of this document will rely on hard copy files given to IRW straight from ELEC.

## Read

The files are divided into three folders:

* `data/legislative`
* `data/ALL_gubernatorial`
* `data/ALL_PACs`

We will start with gubernatorial data, then do the same for legislative and PAC contributions.

We can read all the files at once with a combination of `purrr:map()` and `readr::read_delim()`.
Then, the files can be combined into a single table with `dplyr::bind_rows()`.

The delimiter is not consistent across all files, so they will have to be read in groups and then
combined.


```r
# list the gubernatorial files
nj_gub_files <- list.files(
  path = here("nj_contribs", "data", "ALL_gubernatorial"), 
  full.names = TRUE,
  recursive = TRUE
)

# read those with tab delims
nj_gub_tsv <- map(
  nj_gub_files[-c(8, 16, 24)], 
  read_delim,
  # args to read_delim
  delim = "\t",
  escape_double = FALSE,
  # with new jersey time
  locale = locale(tz = "US/Eastern"),
  col_types = cols(
    # all as char but date & amount
    .default = col_character(),
    CONT_DATE = col_date(format = "%m/%d/%Y"),
    CONT_AMT = col_double()
  )
)

# read those with comma delims
nj_gub_csv <- map(
  nj_gub_files[c(8, 16, 24)], 
  read_delim,
  delim = ",",
  escape_double = FALSE,
  locale = locale(tz = "US/Eastern"),
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_date(format = "%m/%d/%Y"),
    CONT_AMT = col_double()
  )
)

# bind both types of delims
nj_gub <- bind_rows(nj_gub_tsv, nj_gub_csv)

# remove intermediary files
rm(nj_gub_tsv, nj_gub_csv, nj_gub_files)
```


```r
nj_leg_files <- list.files(
  path = here("nj_contribs", "data", "ALL_legislative"), 
  full.names = TRUE,
  recursive = TRUE
)

nj_leg_tsv <- map(
  nj_leg_files[-c(16:18, 31:33)], 
  read_delim,
  delim = "\t",
  escape_double = FALSE,
  locale = locale(tz = "US/Eastern"),
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_date(format = "%m/%d/%Y"),
    CONT_AMT = col_double()
  )
)

nj_leg_csv <- map(
  nj_leg_files[c(16:18, 31:33)], 
  read_delim,
  delim = ",",
  escape_double = FALSE,
  locale = locale(tz = "US/Eastern"),
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_date(format = "%m/%d/%Y"),
    CONT_AMT = col_double()
  )
)

nj_leg <- bind_rows(nj_leg_tsv, nj_leg_csv)

rm(nj_leg_tsv, nj_leg_csv, nj_leg_files)
```


```r
nj_pac_files <- list.files(
  path = here("nj_contribs", "data", "ALL_PACs"), 
  full.names = TRUE,
  recursive = TRUE
)

nj_pac_tsv <- map(
  nj_pac_files[-c(19, 21:22)], 
  read_delim,
  delim = "\t",
  escape_double = FALSE,
  locale = locale(tz = "US/Eastern"),
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_date(format = "%m/%d/%Y"),
    CONT_AMT = col_double()
  )
)

nj_pac_csv <- map(
  nj_pac_files[c(19, 21:22)], 
  read_delim,
  delim = ",",
  escape_double = FALSE,
  locale = locale(tz = "US/Eastern"),
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_date(format = "%m/%d/%Y"),
    CONT_AMT = col_double()
  )
)

nj_pac <-  bind_rows(nj_pac_tsv, nj_pac_csv)

rm(nj_pac_tsv, nj_pac_csv, nj_pac_files)
```

All three file groups have the same columns structure, so they can be combined rowsise.


```r
# check for matching names
sum(names(nj_gub) == names(nj_leg)) == length(nj_gub)
## [1] TRUE
sum(names(nj_leg) == names(nj_pac)) == length(nj_leg)
## [1] TRUE

# bind all rows
nj <- 
  bind_rows(nj_gub, nj_leg, nj_pac, .id = "source") %>% 
  clean_names() %>% 
  arrange(election_year) %>% 
  mutate(source = source %>% recode(
    "1" = "gub", 
    "2" = "leg", 
    "3" = "pac")
  )

# remove intermediary files
rm(nj_gub, nj_leg, nj_pac)
```

## Explore

Below is the structure of the data arranged randomly by row. There are 785891 rows of 
35 variables.


```r
glimpse(sample_frac(nj))
```

```
## Observations: 785,891
## Variables: 35
## $ source             <chr> "leg", "leg", "leg", "pac", "gub", "pac", "gub", "gub", "pac", "gub",…
## $ cont_lname         <chr> NA, NA, NA, NA, NA, "BOTTI", "MINTZ", NA, NA, "MARSHALL", "MECCA", "M…
## $ cont_fname         <chr> NA, NA, NA, NA, NA, "JOSEPH", "HERMAN", NA, NA, "PATRICIA", "JOSEPH",…
## $ cont_mname         <chr> NA, NA, NA, NA, NA, "J", NA, NA, NA, NA, "A", NA, NA, NA, NA, NA, NA,…
## $ cont_suffix        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
## $ cont_non_ind_name  <chr> "ACE PAC", "UNITED PARCEL SERVICE", "REALTORS PAC", "JAMES NOLAN INC"…
## $ cont_non_ind_name2 <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "ARCH…
## $ cont_street1       <chr> "P O BOX 454", "643 W 43RD ST", "295 PIERSON AVE", "4500 BERGEN TPKE"…
## $ cont_street2       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
## $ cont_city          <chr> "SOMERS POINT", "NEW YORK", "EDISON", "NORTH BERGEN", "LANCASTER", "H…
## $ cont_state         <chr> "NJ", "NY", "NJ", "NJ", "NY", "NJ", "NJ", "NJ", "NJ", "NJ", "NJ", "NJ…
## $ cont_zip           <chr> "08244", "10036", "08837", "07047", "14086", "07731", "08618", "07501…
## $ cont_type          <chr> "BUSINESS/ CORP ASSOC/ PAC", "BUSINESS/CORP", "PROFESSIONAL/ TRADE AS…
## $ cont_amt           <dbl> 500.00, 1000.00, 3500.00, 2400.00, 800.00, 1500.00, 5.00, 500.00, 500…
## $ receipt_type       <chr> "MONETARY", "MONETARY", "MONETARY", "MONETARY", "N/SUBMITTED", "MONET…
## $ cont_date          <date> 2009-03-01, 2003-03-04, 2013-10-26, 2010-10-18, 1981-07-03, 2015-04-…
## $ occupation         <chr> NA, NA, NA, NA, NA, NA, "RETIRED", NA, NA, NA, NA, "RETIRED", NA, NA,…
## $ emp_name           <chr> NA, NA, NA, NA, NA, "CITY OF UNION CITY", NA, NA, NA, NA, NA, NA, NA,…
## $ emp_street1        <chr> NA, NA, NA, NA, NA, "3715 PALISADE AVE", NA, NA, NA, NA, NA, NA, NA, …
## $ emp_street2        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
## $ emp_city           <chr> NA, NA, NA, NA, NA, "UNION CITY", NA, NA, NA, NA, NA, NA, NA, NA, NA,…
## $ emp_state          <chr> NA, NA, NA, NA, NA, "NJ", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
## $ emp_zip            <chr> NA, NA, NA, NA, NA, "07087", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
## $ rec_lname          <chr> "LAMPITT", "WATSON-COLEMAN", "SINGLETON", NA, "ROE", NA, "SCHUNDLER",…
## $ rec_fname          <chr> "PAMELA", "BONNIE", "TROY", NA, "ROBERT", NA, "BRET", "LAWRENCE", NA,…
## $ rec_mname          <chr> "R", NA, NA, NA, "A", NA, NA, "F", NA, NA, "A", NA, "W", NA, "T", NA,…
## $ rec_suffix         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
## $ rec_non_ind_name   <chr> NA, NA, NA, "NORTH BERGEN DEMOCRATIC MUNICIPAL COMMITTEE", NA, "UNION…
## $ rec_non_ind_name2  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
## $ office             <chr> "STATE ASSEMBLY", "STATE ASSEMBLY", "STATE ASSEMBLY", "MUNICIPAL DEM …
## $ party              <chr> "DEMOCRAT", "DEMOCRAT", "DEMOCRAT", "DEMOCRAT", "DEMOCRAT", "DEMOCRAT…
## $ location           <chr> " 6TH LEGISLATIVE DISTRICT", "15TH LEGISLATIVE DISTRICT", " 7TH LEGIS…
## $ election_year      <chr> "2009", "2003", "2013", "2010", "1981", "2015", "2001", "1981", "2003…
## $ election_type      <chr> "PRIMARY", "PRIMARY", "GENERAL", "POLITICAL ACTION COMMITTEE", "PRIMA…
## $ occupation_name    <chr> NA, NA, NA, NA, NA, "PROTECTIVE/ARMED SERVICES", NA, NA, NA, NA, NA, …
```

The hard copy files span from 1981 to 2015. When you
filter out those records from before 2008, you are left with much less data.


```r
nj2 <- nj %>% filter(cont_date > "2008-01-01")
nrow(nj2)
```

```
## [1] 188741
```

```r
min(nj2$cont_date)
```

```
## [1] "2008-01-02"
```

```r
max(nj2$cont_date)
```

```
## [1] "5013-10-05"
```

There are a little under 2,000 rows with duplicates values in every variable. Over 1% of rows
are complete duplicates.


```r
nj2 %>% 
  distinct() %>% 
  nrow() %>% 
  subtract(nrow(nj2))
```

```
## [1] -1981
```

