---
title: "Data Diary"
subtitle: "New Jersey Contributions"
author: "Kiernan Nicholls"
date: "2019-05-30 20:22:08"
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
  vroom,
  rvest,
  here,
  fs
)
```

## Data

Data comes courtesy of the New Jersey Election Law Enforcement Commission (ELEC)
[website](https://www.elec.state.nj.us/ELECReport/). The data can be downloaded from their 
["Quick Data Downloads"](https://www.elec.state.nj.us/publicinformation/quickdownload.htm) page in
four separate files:

* [`All_GUB_Text.zip`]("https://www.elec.state.nj.us/download/Data/Gubernatorial/All_GUB_Text.zip")
* [`All_LEG_Text.zip`]("https://www.elec.state.nj.us/download/Data/Legislative/All_LEG_Text.zip")
* [`All_CW_Text.zip`]("https://www.elec.state.nj.us/download/Data/Countywide/All_CW_Text.zip")
* [`All_PAC_Text.zip`]("https://www.elec.state.nj.us/download/Data/PAC/All_PAC_Text.zip")

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

The files can be read into R after downloading and unzipping. The delimiter used in each file is inconsistent, with some using tabs and others using commas. The `vroom::vroom()` function will
allow us to read all the unzipped files (~100) at once, with automatic detection of the delimeter.

First, download each file and unzip each into the `nj_contribs/data` directory.


```r
# list all files
nj_zip_files <- c(
  "https://www.elec.state.nj.us/download/Data/Gubernatorial/All_GUB_Text.zip",
  "https://www.elec.state.nj.us/download/Data/Legislative/All_LEG_Text.zip",
  "https://www.elec.state.nj.us/download/Data/Countywide/All_CW_Text.zip",
  "https://www.elec.state.nj.us/download/Data/PAC/All_PAC_Text.zip"
)

# create a direcory for download
dir.create(here("nj_contribs", "data"))

# download each file in the list
for (file in nj_zip_files) {
  download.file(
    url = file,
    destfile = here(
      "nj_contribs",
      "data",
      basename(file)
    )
  )
}

# unzip each file downloaded
here("nj_contribs", "data") %>%
  dir_ls(type = "file", glob = "*.zip") %>%
  map(
    unzip,
    exdir = here("nj_contribs", "data"),
    overwrite = TRUE
  )
```

```
## $`/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/All_CW_Text.zip`
##  [1] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/CWP2013.txt"
##  [2] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/CWG1999.txt"
##  [3] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/CWG2000.txt"
##  [4] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/CWG2009.txt"
##  [5] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/CWG2010.txt"
##  [6] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/CWG2011.txt"
##  [7] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/CWG2012.txt"
##  [8] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/CWG2013.txt"
##  [9] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/CWP2000.txt"
## [10] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/CWP2001.txt"
## [11] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/CWP2009.txt"
## [12] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/CWP2010.txt"
## [13] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/CWP2011.txt"
## [14] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/CWP2012.txt"
## [15] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/CWP2015.txt"
## [16] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/CWG2014.txt"
## [17] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/CWG2015.txt"
## [18] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/CWP2014.txt"
## 
## $`/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/All_GUB_Text.zip`
##  [1] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_P2005.txt"
##  [2] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_G1981.txt"
##  [3] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_G1985.txt"
##  [4] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_G1989.txt"
##  [5] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_G1993.txt"
##  [6] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_G1997.txt"
##  [7] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_G2001.txt"
##  [8] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_G2005.txt"
##  [9] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_I1982.txt"
## [10] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_I1986.txt"
## [11] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_I1990.txt"
## [12] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_I1994.txt"
## [13] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_I1998.txt"
## [14] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_I2002.txt"
## [15] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_I2006.txt"
## [16] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_P1981.txt"
## [17] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_P1985.txt"
## [18] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_P1989.txt"
## [19] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_P1993.txt"
## [20] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_P1997.txt"
## [21] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_P2001.txt"
## [22] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_G2013.txt"
## [23] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_I2014.txt"
## [24] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Gub_P2013.txt"
## 
## $`/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/All_LEG_Text.zip`
##  [1] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/LEG_P1991.txt"
##  [2] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/LEG_P1999.txt"
##  [3] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/LEG_P2001.txt"
##  [4] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/LEG_P2003.txt"
##  [5] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Leg_P2005.txt"
##  [6] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Leg_P2007.txt"
##  [7] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Leg_P2009.txt"
##  [8] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Leg_P2010.txt"
##  [9] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Leg_P2011.txt"
## [10] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Leg_P2012.txt"
## [11] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Leg_P2013.txt"
## [12] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/LEG_P2015.txt"
## [13] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/LEG_G1985.txt"
## [14] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/LEG_G1987.txt"
## [15] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/LEG_G1989.txt"
## [16] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Leg_G1991.txt"
## [17] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Leg_G1993.txt"
## [18] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Leg_G1995.txt"
## [19] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/LEG_G1997.txt"
## [20] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/LEG_G1999.txt"
## [21] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/LEG_G2001.txt"
## [22] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/LEG_G2003.txt"
## [23] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/LEG_G2005.txt"
## [24] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Leg_G2007.txt"
## [25] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Leg_G2009.txt"
## [26] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Leg_G2010.txt"
## [27] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/LEG_G2011.txt"
## [28] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Leg_G2012.txt"
## [29] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/Leg_G2013.txt"
## [30] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/LEG_G2015.txt"
## [31] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/LEG_P1985.txt"
## [32] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/LEG_P1987.txt"
## [33] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/LEG_P1989.txt"
## 
## $`/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/All_PAC_Text.zip`
##  [1] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC2004.txt"
##  [2] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC2005.txt"
##  [3] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC2006.txt"
##  [4] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC2007.txt"
##  [5] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC2008.txt"
##  [6] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC2009.txt"
##  [7] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC2010.txt"
##  [8] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC2011.txt"
##  [9] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC2012.txt"
## [10] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC2013.txt"
## [11] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC1994.txt"
## [12] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC1995.txt"
## [13] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC1996.txt"
## [14] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC1997.txt"
## [15] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC1998.txt"
## [16] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC1999.txt"
## [17] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC2000.txt"
## [18] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC2001.txt"
## [19] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC2002.txt"
## [20] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC2003.txt"
## [21] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC2014.txt"
## [22] "/home/kiernan/R/accountability_datacleaning/R_contribs/nj_contribs/data/PAC2015.txt"
```

While every file has the same structure, the _names_ of those columns vary slightly. In some, there
is an `occupation` variable; in others, that variable is named `occupation_name`. This incongruity
prevents them from all being read together with `vroom::vroom()`. We can solve this by extracting
the variable names from a single file and using those to names for every file.


```r
# extract names from first file
nj_names <-
  here("nj_contribs", "data") %>%
  dir_ls(type = "file", glob = "*.txt") %>%
  extract(1) %>%
  read.table(sep = "\t", nrows = 1, header = FALSE) %>%
  as_vector() %>%
  str_to_lower()
```

One we have this vector of column names, we can read each file into a single data fram. Every
column will be read as character strings and parsed after the fact using the `dplyr::parse_*()`
functions. Normally we would use `col_types = cols(cont_date = col_date())`, but this seems to
introduce a number of `NA` values from some unknown parsing error that is does not happen with
`dplyr::parse_date()`.


```r
nj <-
  here("nj_contribs", "data") %>%
  dir_ls(type = "file", glob = "*.txt") %>%
  vroom(
    delim = NULL,
    col_names = nj_names,
    col_types = cols(.default = "c"),
    id = "source",
    skip = 1,
    trim_ws = TRUE,
    locale = locale(tz = "US/Eastern"),
    progress = FALSE
  ) %>%
  mutate(
    source    = basename(source),
    cont_date = parse_date(cont_date, "%m/%d/%Y"),
    cont_amt  = parse_number(cont_amt)
  )
```

## Explore

Below is the structure of the data arranged randomly by row. There are 879485 rows of 
34 variables.


```r
glimpse(sample_frac(nj))
```

```
## Observations: 879,485
## Variables: 34
## $ source             <chr> "Leg_P2007.txt", "PAC2013.txt", "LEG_G2005.txt", "LEG_G2015.txt", "CW…
## $ cont_lname         <chr> NA, "BONACCI", "HUBLER", NA, NA, "BEEN", "DAGGETT", NA, NA, "SCARINCI…
## $ cont_fname         <chr> NA, "JOSEPH", "ELIZABETH", NA, NA, "STANLEY", "CHRISTOPHER", NA, NA, …
## $ cont_mname         <chr> NA, "D", NA, NA, NA, "L", NA, NA, NA, NA, "B", NA, NA, "M", NA, "A", …
## $ cont_suffix        <chr> NA, "III", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
## $ cont_non_ind_name  <chr> "ALLIED BEVERAGE GROUP LLC", NA, NA, "NJ CAMPS PAC", "MORRIS COUNTY R…
## $ cont_non_ind_name2 <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
## $ cont_street1       <chr> "600 WASHINGTON AVE PO BOX 0838", "1014 KENNEDY BLVD APT 2", "1109 LI…
## $ cont_street2       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
## $ cont_city          <chr> "CARLSTADT", "UNION CITY", "COLLINGSWOOD", "COLUMBUS", "MORRISTOWN", …
## $ cont_state         <chr> "NJ", "NJ", "NJ", "NJ", "NJ", "NJ", "NJ", "NJ", "NJ", "NJ", "NY", "NJ…
## $ cont_zip           <chr> "07072", "07087", "08108", "08022", "07963", "07712", "07920", "08543…
## $ cont_type          <chr> "BUSINESS/CORP", "INDIVIDUAL", "INDIVIDUAL", "PROFESSIONAL/ TRADE ASS…
## $ cont_amt           <dbl> 1000, 400, 5, 1000, 1074, 100, 250, 1500, 150, 1000, 15000, 6200, 300…
## $ receipt_type       <chr> "MONETARY", "MONETARY", "MONETARY", "MONETARY", "IN-KIND", "N/SUBMITT…
## $ cont_date          <date> 2004-06-10, 2013-04-01, 2005-08-10, 2015-10-24, 2015-10-30, 1981-06-…
## $ occupation         <chr> NA, "PROFESSORS/TEACHERS", "RETIRED", NA, NA, NA, NA, NA, NA, "LEGAL"…
## $ emp_name           <chr> NA, "UNION CITY BOE", NA, NA, NA, NA, NA, NA, NA, "SCARINCI & HOLLENB…
## $ emp_street1        <chr> NA, "2500 KENNEDY BLVD", NA, NA, NA, NA, NA, NA, NA, "1100 VALLEY BRO…
## $ emp_street2        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
## $ emp_city           <chr> NA, "UNION CITY", NA, NA, NA, NA, NA, NA, NA, "LYNDHURST", "NEW YORK"…
## $ emp_state          <chr> NA, "NJ", NA, NA, NA, NA, NA, NA, NA, "NJ", "NY", NA, "NJ", NA, NA, N…
## $ emp_zip            <chr> NA, "07087", NA, NA, NA, NA, NA, NA, NA, "07071", "10036", NA, "07047…
## $ rec_lname          <chr> "SARLO", NA, "GREENWALD", "BUCCO", "WILLIAMS", "FLORIO(P81)", "WHITMA…
## $ rec_fname          <chr> "PAUL", NA, "LOUIS", "ANTHONY", "SIDNEY", "JAMES", "CHRISTINE", "JOSE…
## $ rec_mname          <chr> "A", NA, "D", "M", "S", "J", "T", "F", NA, "P", NA, "P", NA, "A", "F"…
## $ rec_suffix         <chr> NA, NA, NA, NA, "JR", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
## $ rec_non_ind_name   <chr> NA, "UNION CITY FIRST", NA, NA, NA, NA, NA, NA, "COMMITTEE TO RE ELEC…
## $ rec_non_ind_name2  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
## $ office             <chr> "STATE SENATE", "MUNICIPAL DEM PARTY", "STATE ASSEMBLY", "STATE ASSEM…
## $ party              <chr> "DEMOCRAT", "DEMOCRAT", "DEMOCRAT", "REPUBLICAN", "REPUBLICAN", "DEMO…
## $ location           <chr> "36TH LEGISLATIVE DISTRICT", "UNION CITY", "6TH LEGISLATIVE DISTRICT"…
## $ election_year      <chr> "2007", "2013", "2005", "2015", "2015", "1981", "1993", "2013", "1987…
## $ election_type      <chr> "PRIMARY", "POLITICAL ACTION COMMITTEE", "GENERAL", "GENERAL", "GENER…
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

There are 2284 rows with duplicates values in every variable. Over 1% of
rows are complete duplicates.


```r
nrow(distinct(nj)) - nrow(nj)
```

```
## [1] -2284
```

### Distinct

The variables vary in their degree of distinctiveness.


```r
nj %>% 
  map(n_distinct) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_distinct") %>% 
  mutate(prop_distinct = round(n_distinct / nrow(nj), 4)) %>%
  print(n = length(nj))
```

```
## # A tibble: 34 x 3
##    variable           n_distinct prop_distinct
##    <chr>                   <int>         <dbl>
##  1 source                     44      0.0002  
##  2 cont_lname              25916      0.0948  
##  3 cont_fname               9859      0.036   
##  4 cont_mname                 53      0.0002  
##  5 cont_suffix                28      0.0001  
##  6 cont_non_ind_name       27590      0.101   
##  7 cont_non_ind_name2       1534      0.0056  
##  8 cont_street1            69169      0.253   
##  9 cont_street2             1164      0.0043  
## 10 cont_city                3029      0.0111  
## 11 cont_state                 58      0.0002  
## 12 cont_zip                 4535      0.0166  
## 13 cont_type                  14      0.0001  
## 14 cont_amt                11067      0.0405  
## 15 receipt_type               23      0.0001  
## 16 cont_date                2919      0.0107  
## 17 occupation                 88      0.000300
## 18 emp_name                33942      0.124   
## 19 emp_street1             27742      0.101   
## 20 emp_street2               715      0.0026  
## 21 emp_city                 1894      0.0069  
## 22 emp_state                  56      0.0002  
## 23 emp_zip                  2945      0.0108  
## 24 rec_lname                1879      0.0069  
## 25 rec_fname                 772      0.0028  
## 26 rec_mname                  29      0.0001  
## 27 rec_suffix                  6      0       
## 28 rec_non_ind_name         2173      0.0079  
## 29 rec_non_ind_name2         858      0.0031  
## 30 office                     21      0.0001  
## 31 party                       5      0       
## 32 location                  478      0.0017  
## 33 election_year              11      0       
## 34 election_type               4      0
```

For the least distinct variables, we can explore the most common values.


```r
nj %>% tabyl(source) %>% arrange(desc(n))
```

```
## # A tibble: 44 x 3
##    source            n percent
##    <chr>         <dbl>   <dbl>
##  1 Leg_P2011.txt 25471  0.0931
##  2 Leg_P2013.txt 17703  0.0647
##  3 PAC2010.txt   11970  0.0438
##  4 LEG_G2011.txt 11850  0.0433
##  5 Leg_G2013.txt 11449  0.0419
##  6 LEG_P2015.txt 11419  0.0418
##  7 PAC2011.txt   11226  0.0410
##  8 PAC2013.txt   10340  0.0378
##  9 PAC2012.txt   10294  0.0376
## 10 Leg_P2009.txt 10143  0.0371
## # … with 34 more rows
```

```r
nj %>% tabyl(party) %>% arrange(desc(n))
```

```
## # A tibble: 5 x 3
##   party                                       n   percent
##   <chr>                                   <dbl>     <dbl>
## 1 DEMOCRAT                               169199 0.619    
## 2 REPUBLICAN                              98417 0.360    
## 3 NONPARTISAN                              3561 0.0130   
## 4 INDEPENDENT                              2299 0.00841  
## 5 OTHER (ANY COMBINATION OF DEM/REP/IND)     10 0.0000366
```

```r
nj %>% tabyl(election_year)
```

```
## # A tibble: 11 x 3
##    election_year     n   percent
##    <chr>         <dbl>     <dbl>
##  1 2001              3 0.0000110
##  2 2003              6 0.0000219
##  3 2007             23 0.0000841
##  4 2008           7702 0.0282   
##  5 2009          35621 0.130    
##  6 2010          29207 0.107    
##  7 2011          60115 0.220    
##  8 2012          19671 0.0719   
##  9 2013          60955 0.223    
## 10 2014          22092 0.0808   
## 11 2015          38091 0.139
```

```r
nj %>% tabyl(election_type) %>% arrange(desc(n))
```

```
## # A tibble: 4 x 3
##   election_type                   n percent
##   <chr>                       <dbl>   <dbl>
## 1 PRIMARY                    106814 0.391  
## 2 GENERAL                     88951 0.325  
## 3 POLITICAL ACTION COMMITTEE  76215 0.279  
## 4 INAUGURAL                    1506 0.00551
```

```r
nj %>% tabyl(cont_type) %>% arrange(desc(n))
```

```
## # A tibble: 14 x 3
##    cont_type                           n   percent
##    <chr>                           <dbl>     <dbl>
##  1 INDIVIDUAL                     134872 0.493    
##  2 BUSINESS/CORP                   52225 0.191    
##  3 PROFESSIONAL/ TRADE ASSOC/ PAC  18358 0.0671   
##  4 CAMPAIGN FUND                   18022 0.0659   
##  5 UNION PAC                       14231 0.0520   
##  6 POLITICAL PARTY CMTE            11056 0.0404   
##  7 UNION                            8226 0.0301   
##  8 BUSINESS/ CORP ASSOC/ PAC        7676 0.0281   
##  9 IDEOLOGICAL ASSOC/ PAC           3378 0.0124   
## 10 INTEREST                         2855 0.0104   
## 11 LEGISLATIVE LEADERSHIP CMTE      1690 0.00618  
## 12 MISC/ OTHER                       454 0.00166  
## 13 POLITICAL CMTE                    440 0.00161  
## 14 PRIOR ELECTION TRANSFER             3 0.0000110
```

```r
nj %>% tabyl(receipt_type) %>% arrange(desc(n))
```

```
## # A tibble: 23 x 3
##    receipt_type      n  percent
##    <chr>         <dbl>    <dbl>
##  1 MONETARY     235640 0.862   
##  2 CURRENCY      13815 0.0505  
##  3 IN-KIND       11177 0.0409  
##  4 N/SUBMITTED    3322 0.0121  
##  5 INTEREST       2864 0.0105  
##  6 REBURS/REFD    2216 0.00810 
##  7 LOAN           1980 0.00724 
##  8 ADJUSTMENTS    1525 0.00558 
##  9 LOAN PAY        373 0.00136 
## 10 CASH N/SUBM     229 0.000837
## # … with 13 more rows
```

```r
nj %>% tabyl(office) %>% arrange(desc(n))
```

```
## # A tibble: 21 x 3
##    office                    n percent
##    <chr>                 <dbl>   <dbl>
##  1 STATE ASSEMBLY        60342  0.221 
##  2 STATE SENATE          36731  0.134 
##  3 JOINT CANDIDATES CMTE 35043  0.128 
##  4 MUNICIPAL DEM PARTY   23234  0.0850
##  5 COUNTY DEM PARTY      18789  0.0687
##  6 COUNTY REP PARTY      14696  0.0537
##  7 MUNICIPAL OFFICE      12850  0.0470
##  8 MAYOR                 12713  0.0465
##  9 COUNTY SHERIFF        11212  0.0410
## 10 COUNTY FREEHOLDER     11159  0.0408
## # … with 11 more rows
```

```r
nj %>% tabyl(cont_state) %>% arrange(desc(n))
```

```
## # A tibble: 58 x 4
##    cont_state      n percent valid_percent
##    <chr>       <dbl>   <dbl>         <dbl>
##  1 NJ         245038 0.896         0.916  
##  2 <NA>         5848 0.0214       NA      
##  3 PA           5837 0.0213        0.0218 
##  4 NY           5730 0.0210        0.0214 
##  5 DC           2654 0.00970       0.00992
##  6 CA           1124 0.00411       0.00420
##  7 FL            974 0.00356       0.00364
##  8 TX            836 0.00306       0.00312
##  9 NC            649 0.00237       0.00242
## 10 VA            625 0.00229       0.00234
## # … with 48 more rows
```

```r
nj %>% tabyl(occupation) %>% arrange(desc(n))
```

```
## # A tibble: 88 x 4
##    occupation                     n percent valid_percent
##    <chr>                      <dbl>   <dbl>         <dbl>
##  1 <NA>                      157258  0.575        NA     
##  2 LEGAL                      21322  0.0780        0.183 
##  3 RETIRED                    12118  0.0443        0.104 
##  4 MGMT/EXECUTIVES            11079  0.0405        0.0953
##  5 PROTECTIVE/ARMED SERVICES   4955  0.0181        0.0426
##  6 PROFESSORS/TEACHERS         3833  0.0140        0.0330
##  7 SERVICE OCCUPATIONS         3752  0.0137        0.0323
##  8 PUBLIC SECTOR               3713  0.0136        0.0319
##  9 OTHER                       3654  0.0134        0.0314
## 10 OWNERS                      3605  0.0132        0.0310
## # … with 78 more rows
```

### Duplicates

There are nearly 1,300 records with values across every variable duplicated at least once more.


```r
# create dupes df
nj_dupes <- nj %>% 
  get_dupes() %>%
  distinct() %>% 
  mutate(dupe_flag = TRUE)

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
## # A tibble: 1,413 x 5
##    cont_lname cont_amt cont_date  rec                                     dupe_count
##    <chr>         <dbl> <date>     <chr>                                        <int>
##  1 BATTAGLIA     319   2009-06-23 GOODWIN                                          2
##  2 BREZA          35   2009-06-23 GOODWIN                                          2
##  3 BUMBERNICK     62.8 2009-09-20 BUMBERNICK                                       2
##  4 CAMERINO      500   2009-10-20 SCAGLLIONE                                       2
##  5 CHAMBERLIN     70   2009-06-23 GOODWIN                                          2
##  6 COSTANTINO     60   2009-07-30 GONNELLI BUECKNER COSTANTINO & MCKEEVER          2
##  7 GOTTESHAM    2600   2009-10-26 GARGANIO & OBRIEN                                2
##  8 MASER         500   2009-10-13 SCAGLLIONE                                       2
##  9 OLSEN         500   2009-05-09 GONNELLI BUECKNER COSTANTINO & MCKEEVER          2
## 10 OSWALD         35   2009-06-23 GOODWIN                                          2
## # … with 1,403 more rows
```

Flag these duplicate rows by joining the duplicate table with the original data.


```r
nj <- left_join(nj, nj_dupes)
```

Since there is no entirely unique variable to track contributions, we will create one.


```r
nj <- nj %>%
  # unique row num id
  rownames_to_column(var = "id") %>% 
  # make all same width
  mutate(id = str_pad(
    string = id, 
    width = max(nchar(id)), 
    side = "left", 
    pad = "0")
  )

n_distinct(nj$id) == nrow(nj)
## [1] TRUE
```

### `NA`


```r
nj %>% map(function(var) sum(is.na(var))) %>% 
  unlist() %>% 
  enframe(name = "variable", value = "n_na") %>% 
  mutate(prop_na = n_na / nrow(nj)) %>% 
  print(n = length(nj))
```

```
## # A tibble: 37 x 3
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
## 10 cont_street2       267186  0.977 
## 11 cont_city            5857  0.0214
## 12 cont_state           5848  0.0214
## 13 cont_zip             6986  0.0255
## 14 cont_type               0  0     
## 15 cont_amt                0  0     
## 16 receipt_type            0  0     
## 17 cont_date               0  0     
## 18 occupation         157258  0.575 
## 19 emp_name           175796  0.643 
## 20 emp_street1        182478  0.667 
## 21 emp_street2        271831  0.994 
## 22 emp_city           180198  0.659 
## 23 emp_state          180159  0.659 
## 24 emp_zip            181070  0.662 
## 25 rec_lname          113182  0.414 
## 26 rec_fname          113182  0.414 
## 27 rec_mname          192031  0.702 
## 28 rec_suffix         263338  0.963 
## 29 rec_non_ind_name   160304  0.586 
## 30 rec_non_ind_name2  242331  0.886 
## 31 office                  0  0     
## 32 party                   0  0     
## 33 location                0  0     
## 34 election_year           0  0     
## 35 election_type           0  0     
## 36 dupe_count         269789  0.986 
## 37 dupe_flag          269789  0.986
```

## Clean

New variables will be added with _cleaned_ versions of the original data. Cleaning follows the
[IRW data cleaning guide](https://github.com/irworkshop/accountability_datacleaning/blob/master/R_contribs/accountability_datacleaning/IRW_guides/data_check_guide.md). Cleaned variables will all
match the `*_clean` name syntax.

This primarily means correcting obvious spelling and structure mistakes in Address, City, State,
and ZIP variables. Steps will also be taken to remove punctuation and make strings consistently
uppercase. New variables will also be made from the original data to match the searching parameters
of the Accountability Project database. Rows with unresolvable errors in `*_clean` will be flagged
with a logical `*_flag` variable.

Ultimately, each cleaned variable should contain less distinct values. This would indicate typos
have been corrected and invalid values made `NA`.

### Year

Since the `cont_date` variable was parsed as an R date object through `readr::read_delim()`, the
`lubridate::year()` function makes this step easy.


```r
# extract year variable
nj <- nj %>% mutate(year = year(cont_date))
```

There are a number of year variables that don't make any sense. Since we previously filtered any
date before 2008-01-01, the only erroneous dates are from the future. There are 11 records with
date values from the future. They can be flagged with a new `date_flag` variable.


```r
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
  select(cont_date, cont, cont_amt, rec, source) %>% 
  print()
```

```
## # A tibble: 11 x 5
##    cont_date  cont                       cont_amt rec                                   source     
##    <date>     <chr>                         <dbl> <chr>                                 <chr>      
##  1 2020-01-08 ALLIANCE OF LIQUORS RETAI…      500 CODEY                                 LEG_P2003.…
##  2 2020-05-08 DEGROOT                         500 GREENWALD                             LEG_P2003.…
##  3 2020-08-01 PLUMBERS LU 24 PAC              600 ESSEX COUNTY DEMOCRATIC CMTE          PAC2011.txt
##  4 2020-10-12 DAMINGER                        500 GLOUCESTER COUNTY DEMOCRAT EXECUTIVE… PAC2001.txt
##  5 2024-01-01 ESPOSITO                          5 SCHUNDLER                             Gub_G2001.…
##  6 2033-10-18 MAIER                          2000 SWEENEY                               LEG_G2003.…
##  7 2098-09-13 CALDWELL                         20 GATTO & SILVA FOR TWP COMMITTEE       CWG2013.txt
##  8 2111-11-09 KEARNS                          150 NORTH BERGEN DEMOCRATIC MUNICIPAL CO… PAC2014.txt
##  9 2207-09-23 OKEEFIE                          10 SCHEURER                              Leg_G2007.…
## 10 3007-07-31 GOETZ                            10 VAINIERI HUTTLE                       Leg_G2007.…
## 11 5013-10-05 UA PLUMBERS LOCAL 24           1000 MORRIS COUNTY REPUBLICAN CMTE         PAC2015.txt
```

```r
# flag future contribs
nj <- nj %>% mutate(date_flag = cont_date > today())
```

### ZIPs

The `zipcodes::clean.zipcodes()` function automates many of the required steps to clean US Zip code
strings. From the function documentation:

> Attempts to detect and clean up suspected ZIP codes. Will strip "ZIP+4" suffixes to match format
of zipcode data.frame. Restores leading zeros, converts invalid entries to NAs, and returns
character vector. Note that this function does not attempt to find a matching ZIP code in the
database, but rather examines formatting alone.

The `zipcode` package also contains a useful `zipcode` database: 

> This package contains a database of city, state, latitude, and longitude information for U.S. ZIP
codes from the CivicSpace Database (August 2004) and augmented by Daniel Coven's
federalgovernmentzipcodes.us web site (updated January 22, 2012).


```r
data("zipcode")

zipcode <- zipcode %>% 
  as_tibble() %>% 
  select(city, state, zip) %>% 
  mutate(city = str_to_upper(city))

zipcode %>% sample_n(10)
```

```
## # A tibble: 10 x 3
##    city       state zip  
##    <chr>      <chr> <chr>
##  1 CERES      CA    95307
##  2 EDMON      PA    15630
##  3 BOONTON    NJ    07005
##  4 CASMALIA   CA    93429
##  5 SEDGWICK   ME    04676
##  6 MANCHESTER TN    37349
##  7 SAINT PAUL MN    55104
##  8 KIRWIN     KS    67644
##  9 MUKILTEO   WA    98275
## 10 GAINES     MI    48436
```


```r
nj <- nj %>% mutate(zip5 = clean.zipcodes(cont_zip))

nj$zip5 <- nj$zip5 %>% 
  na_if("0") %>% 
  na_if("000000") %>% 
  na_if("999999")

n_distinct(nj$cont_zip)
## [1] 4535
n_distinct(nj$zip5)
## [1] 3766
```

We can filter for zip codes that are not five characters long and compare them against the first valid zipcode for that contributor's city and state. If need be, the `cont_street1` can be looked
up to get an exact ZIP.


```r
nj_bad_zip <- nj %>% 
  filter(nchar(zip5) != 5) %>% 
  select(id, cont_street1, cont_city, cont_state, cont_zip, zip5) %>% 
  left_join(zipcode, by = c("cont_city" = "city", "cont_state" = "state")) %>% 
  group_by(cont_city, cont_state) %>% 
  slice(1) %>% 
  rename(clean_zip = zip5, valid_zip = zip)

print(nj_bad_zip)
```

```
## # A tibble: 15 x 7
## # Groups:   cont_city, cont_state [15]
##    id     cont_street1               cont_city       cont_state cont_zip clean_zip valid_zip
##    <chr>  <chr>                      <chr>           <chr>      <chr>    <chr>     <chr>    
##  1 078916 1 ASHGROVE CT              <NA>            <NA>       008816   008816    <NA>     
##  2 179554 3572 N CHATTERTON WAY      BOISE           ID         083713   083713    83701    
##  3 082309 2 LAURA CT                 BRIDGETON       NJ         080302   080302    08302    
##  4 137753 P O BOX 2374               CINNAMINSON     NJ         089077   089077    <NA>     
##  5 187741 37 VILLAGE RD              FLORHAM         NJ         079325   079325    <NA>     
##  6 188589 702 DIGIOVANI LN           GLASSBORO       NJ         08       08        08028    
##  7 139227 4 AAA DR STE 204           HAMILTON        NJ         086914   086914    <NA>     
##  8 258254 2175 KENNEDY BLVD          JERSEY CITY     NJ         07       07        07097    
##  9 165661 101 AVENUE OF THE AMERICAS NEW YORK        NY         100313   100313    10001    
## 10 238983 1295 LIVINGSTON AVE        NORTH BRUNSWICK NJ         008902   008902    08902    
## 11 259238 <NA>                       OGDEN           UT         084201   084201    84201    
## 12 098051 600 CORPORATE PARK DR      SAINT LOUIS     MO         631053   631053    63101    
## 13 146304 99 WINKLER RD              SAYREVILLE      NJ         088872   088872    08871    
## 14 253099 901 TEANECK RD             TEANECK         NJ         076666   076666    07666    
## 15 038095 540 NORTH AVE              UNION           NJ         070083   070083    07083
```

Then some of these typo ZIPs can be corrected explicitly using their unique `id`. Most either
contain an erroneous leading zero or trailing digit.


```r
nj$zip5[nj$id == "078916"] <- "08816" # valid NJ
nj$zip5[nj$id == "179554"] <- "83713" # valid boise
nj$zip5[nj$id == "082309"] <- "08302" # valid bridgeton
nj$zip5[nj$id == "137753"] <- "08077" # valid cinnaminson
nj$zip5[nj$id == "187741"] <- "07932" # valid florham
nj$zip5[nj$id == "188589"] <- NA      # can't say
nj$zip5[nj$id == "139227"] <- "08691" # valid hamilton
nj$zip5[nj$id == "258254"] <- NA      # can't say
nj$zip5[nj$id == "165661"] <- "10013" # valid nyc
nj$zip5[nj$id == "238983"] <- "08902" # valid n brunswick
nj$zip5[nj$id == "261083"] <- "08902" # valid n brunswick
nj$zip5[nj$id == "259238"] <- "84201" # valid ogden
nj$zip5[nj$id == "098051"] <- "63105" # valid stl
nj$zip5[nj$id == "146304"] <- "08872" # valid sayreville
nj$zip5[nj$id == "253099"] <- "07666" # valid teaneck
nj$zip5[nj$id == "038095"] <- "07083" # valid union
n_distinct(nj$zip5)
## [1] 3752
sum(nchar(nj$zip5) != 5, na.rm = TRUE)
## [1] 0
```

### States

We can clean states abbreviations by comparing the `cont_state` variable values against a
comprehensive list of valid abbreviations.

The `zipcode` database also contains many city names and the full list of abbreviations for all US
states, territories, and military mail codes (as opposed to `datasets::state.abb`).

I will add rows for the Canadian provinces from Wikipedia. The capital city and largest city are
included alongside the proper provincial abbreviation. Canada uses a different ZIP code convention,
so that data cannot be included.


```r
canadian_zips <-
  # read in page source code
  read_html("https://en.Wikipedia.org/wiki/Provinces_and_territories_of_Canada") %>%
  # select the table node
  html_node("table.wikitable:nth-child(12)") %>% 
  # read as data frame
  html_table(fill = TRUE) %>% 
  # clean name and format
  as_tibble(.name_repair = make_clean_names) %>% 
  # remove top and bottom
  slice(-1, -nrow(.)) %>% 
  # remove extra rows
  select(postalabbrev, capital_1, largestcity_2) %>%
  rename(state = postalabbrev,
         capital = capital_1, 
         queen = largestcity_2) %>% 
  # gather city names
  gather(-state, capital, queen,
         key = type,
         value = city) %>% 
  select(-type) %>% 
  # keep one if capital == queen
  distinct()
```

We can use this database to locate records with invalid values and compare them against possible
valid values. Here, we can see most invalid `cont_state` values are reasonable typos that can be
corrected.


```r
zipcode <- zipcode %>% 
  bind_rows(canadian_zips) %>%
  mutate(city = str_to_upper(city))

valid_abb <- sort(unique(zipcode$state))
setdiff(valid_abb, state.abb)
```

```
##  [1] "AA" "AB" "AE" "AP" "AS" "BC" "DC" "FM" "GU" "MB" "MH" "MP" "NB" "NL" "NS" "ON" "PE" "PR" "PW"
## [20] "QC" "SK" "VI"
```


```r
sum(!(na.omit(nj$cont_state) %in% valid_abb))
## [1] 16
n_distinct(nj$cont_state)
## [1] 58

nj %>% 
  filter(!(cont_state %in% valid_abb)) %>% 
  select(id, cont_city, cont_state, cont_zip) %>% 
  filter(!is.na(cont_state)) %>% 
  left_join(
    y = zipcode %>% select(zip, city, state), 
    by = c("cont_zip" = "zip")
  )
## # A tibble: 16 x 6
##    id     cont_city        cont_state cont_zip city             state
##    <chr>  <chr>            <chr>      <chr>    <chr>            <chr>
##  1 051463 WYCKOFF          N          07481    WYCKOFF          NJ   
##  2 068533 WEST LONG BRANCH N          07764    WEST LONG BRANCH NJ   
##  3 088904 CEDAR KNOLLS     NK         07929    <NA>             <NA> 
##  4 089950 RED BANK         NK         07701    RED BANK         NJ   
##  5 089977 RED BANK         NK         07701    RED BANK         NJ   
##  6 093373 NASHVILLE        TE         37215    NASHVILLE        TN   
##  7 099423 DILLSBURG        P          17019    DILLSBURG        PA   
##  8 104859 PHILADELPHIA     7          19134    PHILADELPHIA     PA   
##  9 114616 KENVIL           MJ         07847    KENVIL           NJ   
## 10 118885 NEWARK           N          07114    NEWARK           NJ   
## 11 132948 BAYONNE          N          07002    BAYONNE          NJ   
## 12 169672 DILLSBURG        P          17019    DILLSBURG        PA   
## 13 174031 DILLSBURG        P          17019    DILLSBURG        PA   
## 14 175304 PHILADELPHIA     P          19149    PHILADELPHIA     PA   
## 15 184063 DILLSBURG        P          17019    DILLSBURG        PA   
## 16 193673 EDISON           N          08837    EDISON           NJ

nj$state_clean <- nj$cont_state %>% 
  str_replace_all(pattern = "MJ", replacement = "NJ") %>% 
  str_replace_all("^N$",  "NJ") %>% 
  str_replace_all("NK", "NJ") %>% 
  str_replace_all("TE", "TN") %>% 
  str_replace_all("^P$",  "PA") %>% 
  str_replace_all("^7$",  "PA")

sum(!(na.omit(nj$state_clean) %in% valid_abb))
## [1] 0
n_distinct(nj$state_clean)
## [1] 52
```


```r
nj %>% 
  tabyl(state_clean) %>% 
  arrange(desc(n)) %>% 
  as_tibble() %>% 
  mutate(cum_percent = cumsum(percent))
```

```
## # A tibble: 52 x 5
##    state_clean      n percent valid_percent cum_percent
##    <chr>        <dbl>   <dbl>         <dbl>       <dbl>
##  1 NJ          245047 0.896         0.916         0.896
##  2 <NA>          5848 0.0214       NA             0.917
##  3 PA            5843 0.0214        0.0218        0.939
##  4 NY            5730 0.0210        0.0214        0.960
##  5 DC            2654 0.00970       0.00992       0.969
##  6 CA            1124 0.00411       0.00420       0.974
##  7 FL             974 0.00356       0.00364       0.977
##  8 TX             836 0.00306       0.00312       0.980
##  9 NC             649 0.00237       0.00242       0.983
## 10 VA             625 0.00229       0.00234       0.985
## # … with 42 more rows
```

### Cities

The State of New Jersey publishes a comprehensive list of all municipalities in the state. We can
read that file from the internet to check the `cont_city` variable values.

Not all conributions come from New Jersey, but 9/10 do so this list is a good start.


```r
nj_muni <- 
  read_tsv(
    file = "https://www.nj.gov/infobank/muni.dat", 
    col_names = c("muni", "county", "old_code", "tax_code", "district", "fed_code", "county_code"),
    col_types = cols(.default = col_character())
  ) %>% 
  # remove muni type suffix
  mutate(county = str_to_upper(county),
         muni = muni %>% 
           str_to_upper() %>% 
           str_remove_all("\\sTWP.$") %>% 
           str_remove_all("\\sBORO$") %>% 
           str_remove_all("\\sCITY$")
  )

valid_muni <- sort(unique(nj_muni$muni))
```

With this list and the fairly comprehensive list of cities from other states, we can isolate only
the most suspicious `cont_city` values.


```r
n_distinct(nj$cont_city)
```

```
## [1] 3029
```

```r
nj %>%
  filter(!(cont_city %in% c(valid_muni, zipcode$city))) %>% 
  filter(!is.na(cont_city)) %>% 
  group_by(cont_city) %>% 
  count() %>% 
  arrange(desc(n))
```

```
## # A tibble: 1,083 x 2
##    cont_city               n
##    <chr>               <int>
##  1 MONROE TOWNSHIP      1681
##  2 WEST TRENTON          567
##  3 MERCERVILLE           352
##  4 WINSTON-SALEM         314
##  5 TURNERSVILLE          249
##  6 WASHINGTON TOWNSHIP   234
##  7 HAMILTON SQUARE       230
##  8 WHITE HOUSE STATION   215
##  9 MILLSTONE TOWNSHIP    192
## 10 WALL TOWNSHIP         167
## # … with 1,073 more rows
```


## Write


```r
nj %>% 
  # remove unclean cols
  select(
    -cont_state,
    -cont_zip
  ) %>% 
  # write to disk
  write_csv(
    path = here("nj_contribs", "data", "nj_contribs_clean.csv"),
    na = ""
  )
```

