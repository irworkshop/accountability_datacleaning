---
title: "Data Diary"
subtitle: "New Jersey Contributions"
author: "Kiernan Nicholls"
date: "2019-05-29 15:14:49"
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
[website](https://www.elec.state.nj.us/ELECReport/). The data can be downloaded from their 
["Quick Data Downloads"](https://www.elec.state.nj.us/publicinformation/quickdownload.htm) page in
four separate files:

* `All_GUB_Text.zip`
* `All_LEG_Text.zip`
* `All_CW_Text.zip`
* `All_PAC_Text.zip`

Each ZIP file contains a number of individual TXT files separated by year.

ELEC makes the following disclaimer at the bottom of the download page:

> The data contained in the ELEC database includes information as reported by candidates and
committees. Although ELEC has taken all reasonable precautions to prevent data entry errors, the
possibility that some exist cannot be entirely eliminated. Contributor and Expenditure types are
coded by ELEC staff members and are subjective according to the information provided by the filer.
Additionally, this information is subject to change as amendments are filed by candidates and
committees. For the most up-to-date information, please go to the “Search for Contributions” pages
to search for the most recent contributor information.

## Read

Each of the ZIP files can be read using the following process:

1. Download from ELEC with `utils::download.file()`
1. Unzip the file into a local directory with `utils::unzip()`
1. Create a vector of new file names with `base::list.files()`
1. Read all the files into a list by mapping `readr::read_delim()` to each file with `purrr:map()`
    * All files have `.txt` extension, but some are really `.tsv` and others `.csv`. Use the
    appropriate `readr::read_*` function for each deliminator type
    * Read all columns as character except for `CONT_DATE` and `CONT_AMT`
1. Combined the rows from each list element into a single table with `dplyr::bind_rows()`
1. Repeat for other ZIP files


```r
# download the file
download.file(
  url = "https://www.elec.state.nj.us/download/Data/Gubernatorial/All_GUB_Text.zip",
  destfile = here("nj_contribs", "data", "All_GUB_Text.zip")
)

# unzip into a folder
unzip(
  zipfile = here("nj_contribs", "data", "All_GUB_Text.zip"),
  overwrite = TRUE,
  exdir = here("nj_contribs", "data", "All_GUB")
)

# list the new files
nj_gub_files <- list.files(
  path = here("nj_contribs", "data", "All_GUB"),
  full.names = TRUE
)

# read files with tab delims
nj_gub_tsv <- map(
  nj_gub_files[-c(8, 16, 24)],
  read_tsv,
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_date("%m/%d/%Y"),
    CONT_AMT = col_double()
  )
)

# read files with comma delims
nj_gub_csv <- map(
  nj_gub_files[c(8, 16, 24)],
  read_csv,
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_date("%m/%d/%Y"),
    CONT_AMT = col_double()
  )
)

# combined all year tables
nj_gub <- bind_rows(nj_gub_tsv, nj_gub_csv)

# remove intermediate data
rm(nj_gub_files, nj_gub_tsv, nj_gub_csv)
```


```r
download.file(
  url = "https://www.elec.state.nj.us/download/Data/Legislative/All_LEG_Text.zip",
  destfile = here("nj_contribs", "data", "All_LEG_Text.zip")
)

unzip(
  zipfile = here("nj_contribs", "data", "All_LEG_Text.zip"),
  overwrite = TRUE,
  exdir = here("nj_contribs", "data", "All_LEG")
)

nj_leg_files <- list.files(
  path = here("nj_contribs", "data", "All_LEG"),
  full.names = TRUE
)

nj_leg_tsv <- map(
  nj_leg_files[-c(16:18, 31:33)],
  read_tsv,
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_date("%m/%d/%Y"),
    CONT_AMT = col_double()
  )
)

nj_leg_csv <- map(
  nj_leg_files[c(16:18, 31:33)],
  read_csv,
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_date("%m/%d/%Y"),
    CONT_AMT = col_double()
  )
)

nj_leg <- bind_rows(nj_leg_tsv, nj_leg_csv)

rm(nj_leg_files, nj_leg_tsv, nj_leg_csv)
```


```r
download.file(
  url = "https://www.elec.state.nj.us/download/Data/Countywide/All_CW_Text.zip",
  destfile = here("nj_contribs", "data", "All_CW_Text.zip")
)

unzip(
  zipfile = here("nj_contribs", "data", "All_CW_Text.zip"),
  overwrite = TRUE,
  exdir = here("nj_contribs", "data", "All_CW")
)

nj_cw_files <- list.files(
  path = here("nj_contribs", "data", "All_CW"),
  full.names = TRUE
)

nj_cw_tsv <- map(
  nj_cw_files[-c(5:9, 14:18)],
  read_tsv,
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_date("%m/%d/%Y"),
    CONT_AMT = col_number()
  )
)

nj_cw_csv <- map(
  nj_cw_files[c(5:9, 14:18)],
  read_csv,
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_date("%m/%d/%Y"),
    CONT_AMT = col_double()
  )
)

nj_cw <- bind_rows(nj_cw_tsv, nj_cw_csv)

rm(nj_cw_files, nj_cw_tsv, nj_cw_csv)
```


```r
download.file(
  url = "https://www.elec.state.nj.us/download/Data/PAC/All_PAC_Text.zip",
  destfile = here("nj_contribs", "data", "All_PAC_Text.zip")
)

unzip(
  zipfile = here("nj_contribs", "data", "All_PAC_Text.zip"),
  overwrite = TRUE,
  exdir = here("nj_contribs", "data", "All_PAC")
)

nj_pac_files <- list.files(
  path = here("nj_contribs", "data", "All_PAC"),
  full.names = TRUE
)

nj_pac_tsv <- map(
  nj_pac_files[-c(19, 21, 22)],
  read_tsv,
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_date("%m/%d/%Y"),
    CONT_AMT = col_number()
  )
)

nj_pac_csv <- map(
  nj_pac_files[c(19, 21, 22)],
  read_csv,
  col_types = cols(
    .default = col_character(),
    CONT_DATE = col_date("%m/%d/%Y"),
    CONT_AMT = col_double()
  )
)

nj_pac <- bind_rows(nj_pac_tsv, nj_pac_csv)

rm(nj_pac_files, nj_pac_tsv, nj_pac_csv)
```

Since each file has the same structure, we can bind them all into a single data frame.


```r
nj <-
  bind_rows(nj_gub, nj_leg, nj_cw, nj_pac, .id = "source") %>%
  clean_names() %>%
  arrange(desc(election_year)) %>%
  mutate(
    source = source %>%
      recode(
        "1" = "gub",
        "2" = "leg",
        "3" = "cw",
        "4" = "pac"
      )
  )

rm(nj_gub, nj_leg, nj_cw, nj_pac)
```

## Explore

Below is the structure of the data arranged randomly by row. There are 879485 rows of 
35 variables.


```r
glimpse(sample_frac(nj))
```

```
## Observations: 879,485
## Variables: 35
## $ source             <chr> "leg", "pac", "gub", "leg", "leg", "gub", "leg", "leg", "leg", "leg",…
## $ cont_lname         <chr> "KISSANE", NA, NA, "MORGADO", NA, NA, NA, NA, NA, "PAGANO", "EVENCHIC…
## $ cont_fname         <chr> "MARYANNE", NA, NA, "ANTONIO", NA, NA, NA, NA, NA, "J KENNETH", "BARR…
## $ cont_mname         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "H", NA, NA, NA, NA, "G", NA,…
## $ cont_suffix        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "DDS", NA…
## $ cont_non_ind_name  <chr> NA, "PARAMUS DEMOCRATIC MUNICIPAL CMTE", "ALUMINUM SHAPES INC", NA, "…
## $ cont_non_ind_name2 <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
## $ cont_street1       <chr> "14 EXPLORER RD", "101 IONA PL", "9000 RIVER RD", "300 GEORGE RD", "4…
## $ cont_street2       <chr> NA, NA, NA, NA, NA, NA, NA, "STE 201", NA, NA, NA, NA, NA, NA, NA, NA…
## $ cont_city          <chr> "BRIGANTINE", "PARAMUS", "DELAIR", "CLIFFSIDE PARK", "NORTH BRUNSWICK…
## $ cont_state         <chr> "NJ", "NJ", "NJ", "NJ", "NJ", "NJ", "NJ", "NJ", "NJ", "NJ", "NJ", "NJ…
## $ cont_zip           <chr> "08203", "07652", "08110", "07010", "08902", "99999", "07033", "08053…
## $ cont_type          <chr> "INDIVIDUAL", "POLITICAL PARTY CMTE", "BUSINESS/CORP", "INDIVIDUAL", …
## $ cont_amt           <dbl> 100.0, 232.0, 1300.0, 1000.0, 300.0, 22075.6, 350.0, 7200.0, 200.0, 1…
## $ receipt_type       <chr> "MONETARY", "MONETARY", "N/SUBMITTED", "MONETARY", "MONETARY", "PUB F…
## $ cont_date          <date> 1987-04-30, 2012-02-07, 1997-09-30, 2007-03-28, 2002-04-17, 1981-05-…
## $ occupation         <chr> NA, NA, NA, "HEALTH/PHYSICIANS", NA, NA, NA, NA, NA, "MGMT/EXECUTIVES…
## $ emp_name           <chr> NA, NA, NA, "PALISADES MEDICAL CENTER", NA, NA, NA, NA, NA, "ESSEX PL…
## $ emp_street1        <chr> NA, NA, NA, "7600 RIVER RD", NA, NA, NA, NA, NA, "1060 BROAD ST", "1 …
## $ emp_street2        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
## $ emp_city           <chr> NA, NA, NA, "NORTH BERGEN", NA, NA, NA, NA, NA, "NEWARK", "NEWARK", "…
## $ emp_state          <chr> NA, NA, NA, "NJ", NA, NA, NA, NA, NA, "NJ", "NJ", "NJ", NA, NA, NA, "…
## $ emp_zip            <chr> NA, NA, NA, "07047", NA, NA, NA, NA, NA, "07102", "07102", "07924", N…
## $ rec_lname          <chr> "KLINE", NA, "WHITMAN", "CODEY", "PREVITE", "MCGLYNN", "BECK", "SWEEN…
## $ rec_fname          <chr> "J EDWARD", NA, "CHRISTINE", "RICHARD", "MARY", "RICHARD", "JENNIFER"…
## $ rec_mname          <chr> NA, NA, "T", "J", "T", NA, NA, "M", NA, "J", NA, "M", NA, NA, NA, "M"…
## $ rec_suffix         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
## $ rec_non_ind_name   <chr> NA, "DEMOCRATIC COMMITTEE OF BERGEN COUNTY", NA, NA, NA, NA, NA, NA, …
## $ rec_non_ind_name2  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "EFO", NA, NA, NA, NA…
## $ office             <chr> "STATE ASSEMBLY", "COUNTY DEM PARTY", "GOVERNOR", "STATE SENATE", "ST…
## $ party              <chr> "REPUBLICAN", "DEMOCRAT", "REPUBLICAN", "DEMOCRAT", "DEMOCRAT", "REPU…
## $ location           <chr> "2ND LEGISLATIVE DISTRICT", "BERGEN COUNTY", "STATEWIDE", "27TH LEGIS…
## $ election_year      <chr> "1987", "2012", "1997", "2007", "2003", "1981", "2011", "2013", "1991…
## $ election_type      <chr> "PRIMARY", "POLITICAL ACTION COMMITTEE", "GENERAL", "PRIMARY", "PRIMA…
## $ occupation_name    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
```

The hard files contain data on elections from 1981 to `r
max(nj$election_year)`. When you filter out those contributions made before 2008, about
$\frac{2}{3}$ of the data is remove.


```r
nj <- nj %>% filter(cont_date > "2008-01-01")
nrow(nj)
```

```
## [1] 273486
```

```r
min(nj$cont_date)
```

```
## [1] "2008-01-02"
```

```r
max(nj$cont_date)
```

```
## [1] "5013-10-05"
```

There are 2297 rows with duplicates values in every variable. Over 1% of
rows are complete duplicates.


```r
nrow(distinct(nj)) - nrow(nj)
```

```
## [1] -2297
```

The variables vary in their degree of distinctedness.


```r
nj %>% 
  map(n_distinct) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_distinct") %>% 
  mutate(prop_distinct = round(n_distinct / nrow(nj), 4)) %>%
  print(n = length(nj))
```

```
## # A tibble: 35 x 3
##    variable           n_distinct prop_distinct
##    <chr>                   <int>         <dbl>
##  1 source                      4      0       
##  2 cont_lname              25915      0.0948  
##  3 cont_fname               9857      0.036   
##  4 cont_mname                 53      0.0002  
##  5 cont_suffix                28      0.0001  
##  6 cont_non_ind_name       27576      0.101   
##  7 cont_non_ind_name2       1534      0.0056  
##  8 cont_street1            69168      0.253   
##  9 cont_street2             1067      0.0039  
## 10 cont_city                3029      0.0111  
## 11 cont_state                 58      0.0002  
## 12 cont_zip                 4535      0.0166  
## 13 cont_type                  14      0.0001  
## 14 cont_amt                11178      0.0409  
## 15 receipt_type               23      0.0001  
## 16 cont_date                2919      0.0107  
## 17 occupation                 81      0.000300
## 18 emp_name                33942      0.124   
## 19 emp_street1             27739      0.101   
## 20 emp_street2               715      0.0026  
## 21 emp_city                 1879      0.0069  
## 22 emp_state                  56      0.0002  
## 23 emp_zip                  2945      0.0108  
## 24 rec_lname                1877      0.0069  
## 25 rec_fname                 737      0.0027  
## 26 rec_mname                  28      0.0001  
## 27 rec_suffix                  5      0       
## 28 rec_non_ind_name         2172      0.0079  
## 29 rec_non_ind_name2         858      0.0031  
## 30 office                     21      0.0001  
## 31 party                       5      0       
## 32 location                  468      0.0017  
## 33 election_year              11      0       
## 34 election_type               4      0       
## 35 occupation_name            84      0.000300
```

There are nearly 1,300 records with values across every variable duplicated at least once more.


```r
# create dupes df
nj_dupes <- nj %>% 
  get_dupes() %>%
  distinct() %>% 
  mutate(dupe_flag = TRUE)
```

```
## No variable names specified - using all columns.
```

```r
# show dupes
nj_dupes %>% 
  mutate(rec = coalesce(rec_lname, rec_non_ind_name)) %>% 
  select(
    cont_lname,
    cont_amt,
    cont_date,
    rec,
    dupe_count
  ) %>% 
  print()
```

```
## # A tibble: 1,426 x 5
##    cont_lname cont_amt cont_date  rec                                        dupe_count
##    <chr>         <dbl> <date>     <chr>                                           <int>
##  1 ALAIMO         2000 2010-08-23 ZIMMERMAN & SIMMONS                                 2
##  2 BARONE          150 2009-09-01 PEREZ                                               2
##  3 BATE             75 2010-01-22 SPEZIALE                                            2
##  4 BATTAGLIA       319 2009-06-23 GOODWIN                                             2
##  5 BEAUZYL         200 2010-02-10 DOMINGUEZ DASILVA LUCIO PADILLA & ABITANTO          3
##  6 BELLERO         300 2008-05-23 PEREZ                                               2
##  7 BENNETT        1000 2010-03-01 KELLY & LACEY                                       2
##  8 BODMAN          750 2010-06-10 GOODWIN                                             2
##  9 BOSWELL         200 2009-05-15 PIGNATELLI & VISCONTI                               2
## 10 BRANCATO        160 2010-10-10 BERDNIK                                             2
## # … with 1,416 more rows
```

Flag these duplicate rows by joining the duplicate table with the original data.


```r
nj <- left_join(nj, nj_dupes)
```

```
## Joining, by = c("source", "cont_lname", "cont_fname", "cont_mname", "cont_suffix", "cont_non_ind_name", "cont_non_ind_name2", "cont_street1", "cont_street2", "cont_city", "cont_state", "cont_zip", "cont_type", "cont_amt", "receipt_type", "cont_date", "occupation", "emp_name", "emp_street1", "emp_street2", "emp_city", "emp_state", "emp_zip", "rec_lname", "rec_fname", "rec_mname", "rec_suffix", "rec_non_ind_name", "rec_non_ind_name2", "office", "party", "location", "election_year", "election_type", "occupation_name")
```

Since there is no entirely unique variable to track contributions, we will create one.


```r
nj <- nj %>% rownames_to_column(var = "id")
n_distinct(nj$id) == nrow(nj)
## [1] TRUE
```



```r
nj %>% map(function(v) sum(is.na(v))) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_na") %>% 
  mutate(prop_na = n_na / nrow(nj)) %>% 
  print(n = length(nj))
```

```
## # A tibble: 38 x 3
##    variable             n_na prop_na
##    <chr>               <int>   <dbl>
##  1 id                      0  0     
##  2 source                  0  0     
##  3 cont_lname         138762  0.507 
##  4 cont_fname         138744  0.507 
##  5 cont_mname         236920  0.866 
##  6 cont_suffix        268911  0.983 
##  7 cont_non_ind_name  134874  0.493 
##  8 cont_non_ind_name2 269503  0.985 
##  9 cont_street1         7154  0.0262
## 10 cont_street2       270530  0.989 
## 11 cont_city            5857  0.0214
## 12 cont_state           5848  0.0214
## 13 cont_zip             6986  0.0255
## 14 cont_type               0  0     
## 15 cont_amt                0  0     
## 16 receipt_type            0  0     
## 17 cont_date               0  0     
## 18 occupation         225674  0.825 
## 19 emp_name           175796  0.643 
## 20 emp_street1        182478  0.667 
## 21 emp_street2        271831  0.994 
## 22 emp_city           180199  0.659 
## 23 emp_state          180159  0.659 
## 24 emp_zip            181070  0.662 
## 25 rec_lname          113182  0.414 
## 26 rec_fname          113182  0.414 
## 27 rec_mname          192033  0.702 
## 28 rec_suffix         263343  0.963 
## 29 rec_non_ind_name   160304  0.586 
## 30 rec_non_ind_name2  242331  0.886 
## 31 office                  0  0     
## 32 party                   0  0     
## 33 location                0  0     
## 34 election_year           0  0     
## 35 election_type           0  0     
## 36 occupation_name    205070  0.750 
## 37 dupe_count         269763  0.986 
## 38 dupe_flag          269763  0.986
```

## Clean

### Year


```r
# extract year variable
nj <- nj %>% mutate(year = year(nj$cont_date))

# print all years
sort(unique(nj$year))
```

```
##  [1] 2008 2009 2010 2011 2012 2013 2014 2015 2016 2018 2020 2024 2033 2098 2111 2207 3007 5013
```

```r
# view futures contribs
nj %>% 
  filter(cont_date > today()) %>% 
  arrange(cont_date) %>% 
  mutate(cont = coalesce(cont_lname, cont_non_ind_name)) %>% 
  mutate(rec = coalesce(rec_lname, rec_non_ind_name)) %>% 
  select(cont_date, cont, cont_amt, rec, source)
```

```
## # A tibble: 11 x 5
##    cont_date  cont                         cont_amt rec                                      source
##    <date>     <chr>                           <dbl> <chr>                                    <chr> 
##  1 2020-01-08 ALLIANCE OF LIQUORS RETAILE…      500 CODEY                                    leg   
##  2 2020-05-08 DEGROOT                           500 GREENWALD                                leg   
##  3 2020-08-01 PLUMBERS LU 24 PAC                600 ESSEX COUNTY DEMOCRATIC CMTE             pac   
##  4 2020-10-12 DAMINGER                          500 GLOUCESTER COUNTY DEMOCRAT EXECUTIVE CM… pac   
##  5 2024-01-01 ESPOSITO                            5 SCHUNDLER                                gub   
##  6 2033-10-18 MAIER                            2000 SWEENEY                                  leg   
##  7 2098-09-13 CALDWELL                           20 GATTO & SILVA FOR TWP COMMITTEE          cw    
##  8 2111-11-09 KEARNS                            150 NORTH BERGEN DEMOCRATIC MUNICIPAL COMMI… pac   
##  9 2207-09-23 OKEEFIE                            10 SCHEURER                                 leg   
## 10 3007-07-31 GOETZ                              10 VAINIERI HUTTLE                          leg   
## 11 5013-10-05 UA PLUMBERS LOCAL 24             1000 MORRIS COUNTY REPUBLICAN CMTE            pac
```

```r
# flag future contribs
nj <- nj %>% 
  filter(cont_date > today()) %>% 
  mutate(date_flag = TRUE) %>% 
  right_join(nj)
```

```
## Joining, by = c("id", "source", "cont_lname", "cont_fname", "cont_mname", "cont_suffix", "cont_non_ind_name", "cont_non_ind_name2", "cont_street1", "cont_street2", "cont_city", "cont_state", "cont_zip", "cont_type", "cont_amt", "receipt_type", "cont_date", "occupation", "emp_name", "emp_street1", "emp_street2", "emp_city", "emp_state", "emp_zip", "rec_lname", "rec_fname", "rec_mname", "rec_suffix", "rec_non_ind_name", "rec_non_ind_name2", "office", "party", "location", "election_year", "election_type", "occupation_name", "dupe_count", "dupe_flag", "year")
```

### Zips


```r
data("zipcode")
nj <- nj %>% mutate(zip5 = clean.zipcodes(cont_zip))
```


```r
nj %>% 
  filter(nchar(zip5) != 5) %>% 
  select(cont_city, cont_state, cont_zip, zip5) %>% 
  print(n = nrow(.))
```

```
## # A tibble: 21 x 4
##    cont_city       cont_state cont_zip zip5  
##    <chr>           <chr>      <chr>    <chr> 
##  1 BRIDGETON       NJ         080302   080302
##  2 UNION           NJ         070083   070083
##  3 <NA>            <NA>       008816   008816
##  4 JERSEY CITY     NJ         07       07    
##  5 OGDEN           UT         084201   084201
##  6 NORTH BRUNSWICK NJ         008902   008902
##  7 CINNAMINSON     NJ         089077   089077
##  8 HAMILTON        NJ         086914   086914
##  9 FLORHAM         NJ         079325   079325
## 10 GLASSBORO       NJ         08       08    
## 11 TEANECK         NJ         076666   076666
## 12 BOISE           ID         083713   083713
## 13 NORTH BRUNSWICK NJ         008902   008902
## 14 SAINT LOUIS     MO         631053   631053
## 15 NEW YORK        NY         100313   100313
## 16 MAHWAH          NJ         0        0     
## 17 MANALAPAN       NJ         0        0     
## 18 MILLVILLE       NJ         0        0     
## 19 SAYREVILLE      NJ         088872   088872
## 20 BEAR            DE         0        0     
## 21 WOODLAND PARK   NJ         0        0
```

### States


```r
nj %>% 
  filter(cont_state %in% setdiff(cont_state, c(state.abb, "DC"))) %>% 
  select(cont_city, cont_state, cont_zip) %>% 
  filter(!is.na(cont_state)) %>% 
  left_join(
    y = zipcode %>% select(zip, city, state), 
    by = c("cont_zip" = "zip")
  )
```

```
## # A tibble: 17 x 5
##    cont_city        cont_state cont_zip city             state
##    <chr>            <chr>      <chr>    <chr>            <chr>
##  1 KENVIL           MJ         07847    Kenvil           NJ   
##  2 NEWARK           N          07114    Newark           NJ   
##  3 CEDAR KNOLLS     NK         07929    <NA>             <NA> 
##  4 RED BANK         NK         07701    Red Bank         NJ   
##  5 RED BANK         NK         07701    Red Bank         NJ   
##  6 NASHVILLE        TE         37215    Nashville        TN   
##  7 BAYONNE          N          07002    Bayonne          NJ   
##  8 DILLSBURG        P          17019    Dillsburg        PA   
##  9 EDISON           N          08837    Edison           NJ   
## 10 WEST LONG BRANCH N          07764    West Long Branch NJ   
## 11 SAINT THOMAS     VI         00802    St Thomas        VI   
## 12 DILLSBURG        P          17019    Dillsburg        PA   
## 13 PHILADELPHIA     7          19134    Philadelphia     PA   
## 14 DILLSBURG        P          17019    Dillsburg        PA   
## 15 DILLSBURG        P          17019    Dillsburg        PA   
## 16 PHILADELPHIA     P          19149    Philadelphia     PA   
## 17 WYCKOFF          N          07481    Wyckoff          NJ
```

