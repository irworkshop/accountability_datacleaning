Pennsylvania Contributions
================
Kiernan Nicholls & Yanqi Xu
2023-06-30 23:18:32

- <a href="#project" id="toc-project">Project</a>
- <a href="#objectives" id="toc-objectives">Objectives</a>
- <a href="#packages" id="toc-packages">Packages</a>
- <a href="#data" id="toc-data">Data</a>
- <a href="#import" id="toc-import">Import</a>
- <a href="#explore" id="toc-explore">Explore</a>
- <a href="#wrangle" id="toc-wrangle">Wrangle</a>
- <a href="#conclude" id="toc-conclude">Conclude</a>
- <a href="#export" id="toc-export">Export</a>
- <a href="#upload" id="toc-upload">Upload</a>
- <a href="#dictionary" id="toc-dictionary">Dictionary</a>

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
  gluedown, # format markdown
  magrittr, # pipe operators
  janitor, # dataframe clean
  aws.s3, # aws cloud storage
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  glue, # combine strings
  httr, # make http requests
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
#> [1] "/Users/yanqixu/code/accountability_datacleaning"
```

## Data

Data is from the [Pennsylvania Election and Campaign Finance System
(ECF)](https://www.dos.pa.gov/VotingElections/CandidatesCommittees/CampaignFinance/Pages/default.aspx).

The ECF provides a [Full Campaign Finance
Export](https://www.dos.pa.gov/VotingElections/CandidatesCommittees/CampaignFinance/Resources/Pages/FullCampaignFinanceExport.aspx).
From this page, files are organized as annual directories containing
files for contributions, debt, expenditures, filer information, and
receipts.

The ECF also provides a `readme.txt` file, which we can read to better
understand the data we will be downloading.

``` r
pa_host <- "https://www.dos.pa.gov/VotingElections"
pa_dir <- "CandidatesCommittees/CampaignFinance/Resources/Documents"
readme_file <- "readmepriorto2022.txt"
readme_url_old <- paste(pa_host, pa_dir, readme_file, sep = "/")

readme_new <- "readme2022.txt"
readme_url_new <- paste(pa_host, pa_dir, readme_new, sep = "/")
```

This text file provides the column names and types for the each of the
data files included in the raw download.

Here are the columns included in the contributions data set:

``` r
readme$contribs %>% 
  mutate(col = as.character(md_code(col))) %>% 
  kable(col.names = c("Columns", "Type"))
```

| Columns       | Type         |
|:--------------|:-------------|
| `filerid`     | VARCHAR(20)  |
| `eyear`       | INT          |
| `cycle`       | INT          |
| `section`     | VARCHAR(10)  |
| `contributor` | VARCHAR(255) |
| `address1`    | VARCHAR(50)  |
| `address2`    | VARCHAR(50)  |
| `city`        | VARCHAR(50)  |
| `state`       | VARCHAR(10)  |
| `zipcode`     | VARCHAR(15)  |
| `occupation`  | VARCHAR(255) |
| `ename`       | VARCHAR(255) |
| `eaddress1`   | VARCHAR(50)  |
| `eaddress2`   | VARCHAR(50)  |
| `ecity`       | VARCHAR(50)  |
| `estate`      | VARCHAR(10)  |
| `ezipcode`    | VARCHAR(15)  |
| `contdate1`   | VARCHAR(20)  |
| `contamt1`    | MONEY        |
| `contdate2`   | VARCHAR(20)  |
| `contamt2`    | MONEY        |
| `contdate3`   | VARCHAR(20)  |
| `contamt3`    | MONEY        |
| `contdesc`    | VARCHAR(500) |

There are no variables providing information on the recipients, those
committees which *filed* the reports containing each contribution. That
data is provided in a separate file.

``` r
readme$filer %>% 
  mutate(col = as.character(md_code(col))) %>% 
  kable(col.names = c("Columns", "Type"))
```

| Columns     | Type         |
|:------------|:-------------|
| `filerid`   | VARCHAR(20)  |
| `eyear`     | INT          |
| `cycle`     | INT          |
| `ammend`    | VARCHAR(1)   |
| `terminate` | VARCHAR(1)   |
| `filertype` | VARCHAR(10)  |
| `filername` | VARCHAR(255) |
| `office`    | VARCHAR(15)  |
| `district`  | VARCHAR(15)  |
| `party`     | VARCHAR(15)  |
| `address1`  | VARCHAR(50)  |
| `address2`  | VARCHAR(50)  |
| `city`      | VARCHAR(50)  |
| `state`     | VARCHAR(10)  |
| `zipcode`   | VARCHAR(15)  |
| `county`    | VARCHAR(15)  |
| `phone`     | VARCHAR(15)  |
| `beginning` | MONEY        |
| `monetary`  | MONEY        |
| `inkind`    | MONEY        |

## Import

To import the files into R, we will have to first download the annual
ZIP archive file containing all campaign finance transactions. Then we
can extract the contributions file and read them all into a single file
for processing.

### Download

Each ZIP archive is simply named as the 4-digit year for the files
within. We can download each ZIP to the `/data/raw` directory.

``` r
zip_names <- paste(2000:2022, "zip", sep = ".")
zip_urls <- paste(pa_host, pa_dir, zip_names, sep = "/")
raw_dir <- dir_create(here("state","pa", "contribs", "data", "raw"))
zip_paths <- path(raw_dir, zip_names)
fix_check <- here("state","pa", "contribs", "data", "fixed.txt")
if (length(dir_ls(raw_dir, regexp = "zip")) < 10) {
  for (i in seq_along(zip_urls)) {
  download.file(zip_urls[i], zip_paths[i])
  #file_delete(fix_check)
  }
}
```

Then we will unzip the annual directory from each archive.

``` r
zip_files <- dir_ls(raw_dir, glob = "*.zip")

if (all_files_new(path = raw_dir, glob = "*.txt")) {
  for (i in seq_along(zip_files)) {
    unzip(
      zipfile = zip_files[i],
      #Matches the csv files that starts with contrib, and trim the "./ " from directory names
      files = grep("(contrib|filer).+", unzip(zip_files[i]), value = TRUE) %>% substring(3,),
      exdir = raw_dir
    )
  }
}
```

For each year, there is a file for contribution and a file for the
information on the recipients of those contributions, who file the
reports containing the data. We will identify the path of each file type
in new vectors, which can then be read together.

``` r
con_paths <- dir_ls(
  path = raw_dir, 
  recurse = TRUE, 
  regexp = "(C|c)ontrib[\\.|_]"
)
```

The file names are a little different year to year, but they all have
the same format.

    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/2000/contrib_2000.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/2001/contrib_2001.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/2002/contrib_2002.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/2003/contrib_2003.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/2004/contrib_2004.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/2005/contrib_2005.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/2006/contrib_2006.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/2007/contrib_2007.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/2008/contrib_2008.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/2009/contrib_2009.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/2010/contrib_2010.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/2011/contrib_2011.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/2012/contrib_2012.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/2013/contrib_2013.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/2014/contrib_2014.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/2015/contrib_2015.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/2016/contrib_2016.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/contrib.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/contrib_2017.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/contrib_2018_03042019.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/contrib_2020.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/contrib_2021.txt`
    #> * `/Users/yanqixu/code/accountability_datacleaning/state/pa/contribs/data/raw/contrib_2022.txt`

### Fix

To properly read so many records, we need to first perform some
manipulation of the text files. Each “cell” of character type columns
are surrounded in double quotation marks (`"`) to help prevent
misreading. However, some of the text in these cells itself contains
double quotes or newline characters (`\n`).

We need to read each file as a character string and use regular
expressions to identify these erroneous characters and remove or replace
them.

``` r
# do not repeat if done
if (!file_exists(fix_check)) {
  # for all contrib and filer files
  for (f in c(con_paths, fil_paths)) {
    # read raw file
    read_file(f) %>% 
      # force conversion to simple
      iconv(to = "ASCII", sub = "") %>% 
      # replace non-carriage newline
      str_replace_all("(?<!\r)\n", " ") %>%
      # replace not-field double quotes
      str_replace_all("(?<!^|,|\r\n)\"(?!,|\r\n|$)", "\'") %>% 
      # replace non-delim commas
      str_remove_all(",(?!\"|\\d|\\.\\d+|-(\\d|\\.))") %>% 
      # overwrite raw file
      write_file(f)
    # check progress
    message(paste(basename(f), "done"))
    # clean garbage memory
    flush_memory()
  }
  # note this has done
  file_create(fix_check)
}
```

### Read

Now that each text file has been cleaned of irregularities, they can
each be properly read into R.

First, we will read all the annual contribution files into a single data
frame using `vroom::vroom()`. We need to use the column names and types
listed in the `readme.txt` file we downloaded earlier.

``` r
pa_2022_path <- dir_ls(raw_dir,regexp = ".+2022.txt")
con_paths <- setdiff(con_paths, pa_2022_path)

pac <- map_df(
  .x = con_paths,
  .f = read_delim,
  delim = ",",
  escape_backslash = FALSE, 
  escape_double = FALSE,
  col_names = readme$contribs$col,
  col_types = cols(
    .default = col_skip(),
    filerid = col_character(),
    eyear = col_integer(),
    cycle = col_integer(),
    section = col_character(),
    contributor = col_character(),
    address1 = col_character(),
    address2 = col_character(),
    city = col_character(),
    state = col_character(),
    zipcode = col_character(),
    occupation = col_character(),
    ename = col_character(),
    contdate1 = col_date("%Y%m%d"),
    contamt1 = col_double(),
  )
)

pac_2022 <- read_delim(
  pa_2022_path,
  delim = ",",
  escape_backslash = FALSE, 
  escape_double = FALSE,
  col_names = readme_new$contribs$col,
  col_types = cols(
    .default = col_skip(),
    filerid = col_character(),
    # reportid = col_character(),
    # timestamp = col_date("%Y-%m-%d"),
    eyear = col_integer(),
    cycle = col_integer(),
    section = col_character(),
    contributor = col_character(),
    address1 = col_character(),
    address2 = col_character(),
    city = col_character(),
    state = col_character(),
    zipcode = col_character(),
    occupation = col_character(),
    ename = col_character(),
    contdate1 = col_date("%Y%m%d"),
    contamt1 = col_double()
  )
)

pac <- pac_2022 %>% bind_rows(pac)
```

Then we can read the fixed filer files to describe the recipients.

``` r
fil_paths <- dir_ls(
  path = raw_dir, 
  recurse = TRUE, 
  regexp = "(F|f)iler[\\.|_]"
) %>% 
c(dir_ls(path = here("state","pa", "expends", "data", "raw"),
                recurse = TRUE, 
  regexp = "(F|f)iler[\\.|_]"))

fil_path_2022 <- glue(here("state","pa", "expends", "data", "raw"), "/filer_2022.txt")

fil_paths <- setdiff(fil_paths, fil_path_2022)
filers <- map_df(
  .x = fil_paths,
  .f = read_delim,
  delim = ",",
  escape_backslash = FALSE, 
  escape_double = FALSE,
  col_names = readme$filer$col,
  col_types = cols(
    .default = col_skip(),
    eyear = col_integer(),
    filerid = col_character(),
    filertype = col_character(),
    filername = col_character(),
    office = col_character(),
    district = col_character(),
    party = col_character(),
    address1 = col_character(),
    address2 = col_character(),
    city = col_character(),
    state = col_character(),
    zipcode = col_character(),
    county = col_character(),
    phone = col_character(),
  )
)

filers2022 <- read_delim(fil_path_2022,
                          delim = ",",
  escape_backslash = FALSE, 
  escape_double = FALSE,
  col_names = readme_new$filer$col,
  col_types = cols(
    .default = col_skip(),
        eyear = col_integer(),
    filerid = col_character(),
    filertype = col_character(),
    filername = col_character(),
    office = col_character(),
    district = col_character(),
    party = col_character(),
    address1 = col_character(),
    address2 = col_character(),
    city = col_character(),
    state = col_character(),
    zipcode = col_character(),
    county = col_character(),
    phone = col_character(),
  ))

filers <- filers2022 %>% bind_rows(filers)
```

We only want to join a single filer to each contribution listed in the
data. We can group by the unique filer ID and a filing year and select
only one copy of the data.

``` r
nrow(filers)
#> [1] 169391
filers <- filers %>% 
  group_by(filerid, eyear) %>% 
  slice(1) %>% 
  ungroup()
nrow(filers)
#> [1] 60408
```

Now the filer information can be added to the contribution data with a
`dplyr::left_join()` along the unique filer ID and election year.

``` r
# 21,761,034
pac <- left_join(
  x = pac,
  y = filers,
  by = c("filerid", "eyear"),
  suffix = c("_con", "_fil")
)

rm(filers)

pac <- rename_prefix(
  df = pac,
  suffix = c("_con", "_fil"),
  punct = TRUE
)
```

``` r
pac <- pac %>% 
  rename_with(~str_replace(., "address", "addr")) %>% 
  rename(
    con_zip = con_zipcode,
    date = contdate1,
    amount = contamt1,
    fil_type = filertype,
    filer = filername,
    fil_zip = fil_zipcode,
    fil_phone = phone
  )
```

We will also add a temporary unique ID for each transaction.

``` r
pac <- mutate(pac, tx = row_number())
```

## Explore

We should first check the top and bottom of the read data frame to
ensure the file was read correctly. This view also helps simply
understand the format.

There are 21,761,034 rows of 27 columns.

``` r
glimpse(pac)
#> Rows: 21,761,034
#> Columns: 27
#> $ filerid     <chr> "365777", "365777", "373735", "370869", "373735", "375237", "373735", "375285…
#> $ eyear       <int> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ cycle       <int> 1, 1, 4, 3, 4, 5, 4, 5, 7, 7, 3, 7, 7, 5, 2, 7, 2, 7, 7, 5, 7, 5, 2, 7, 2, 7,…
#> $ section     <chr> "IC", "IC", "IC", "IC", "IC", "IC", "IC", "IC", "IC", "IA", "IA", "IA", "IB",…
#> $ contributor <chr> "Ben Shaevitz", "T Storm Heter", "Ben Shaevitz", "James Jones", "Calvin Walke…
#> $ con_addr1   <chr> "141 Porter Road", "512 Fulmer Ave", "141 Porter Road", "26 Wakefield Dr", "2…
#> $ con_addr2   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ con_city    <chr> "Harrisville", "Stroudsburg", "Harrisville", "Newark", "Cranbury", "West Ches…
#> $ con_state   <chr> "PA", "PA", "PA", "DE", "NJ", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA",…
#> $ con_zip     <chr> "16038", "18360", "16038", "19711", "08512", "19380", "18360", "19038", "1903…
#> $ occupation  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ ename       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ date        <date> 2022-02-28, 2022-02-28, 2022-08-29, 2022-05-27, 2022-06-10, 2022-09-30, 2022…
#> $ amount      <dbl> 260, 260, 312, 300, 300, 542, 364, 1000, 2500, 60, 60, 50, 120, 50, 150, 120,…
#> $ fil_type    <chr> "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2…
#> $ filer       <chr> "APSCUF/CAP(ASSN PA ST COL/UNIV FACL)                        ", "APSCUF/CAP(A…
#> $ office      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ district    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ party       <chr> NA, NA, NA, NA, NA, NA, NA, "DEM", "DEM", "REP", "REP", "REP", "REP", "REP", …
#> $ fil_addr1   <chr> "319 N FRONT ST      ", "319 N FRONT ST      ", "319 N FRONT ST      ", "319 …
#> $ fil_addr2   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "927 IRVIN ROAD", "927 IRVIN ROAD", "927 …
#> $ fil_city    <chr> "HARRISBURG       ", "HARRISBURG       ", "HARRISBURG       ", "HARRISBURG   …
#> $ fil_state   <chr> "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA",…
#> $ fil_zip     <chr> "17101-", "17101-", "17101-", "17101-", "17101-", "17101-", "17101-", "19046-…
#> $ county      <chr> NA, NA, NA, NA, NA, NA, NA, "46", "46", "46", "46", "46", "46", "46", "46", "…
#> $ fil_phone   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, "2156262907", "2156262907", "2156262907",…
#> $ tx          <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22…
head(pac)
#> # A tibble: 6 × 27
#>   filerid eyear cycle section contributor    con_ad…¹ con_a…² con_c…³ con_s…⁴ con_zip occup…⁵ ename
#>   <chr>   <int> <int> <chr>   <chr>          <chr>    <chr>   <chr>   <chr>   <chr>   <chr>   <chr>
#> 1 365777     NA     1 IC      Ben Shaevitz   141 Por… <NA>    Harris… PA      16038   <NA>    <NA> 
#> 2 365777     NA     1 IC      T Storm Heter  512 Ful… <NA>    Stroud… PA      18360   <NA>    <NA> 
#> 3 373735     NA     4 IC      Ben Shaevitz   141 Por… <NA>    Harris… PA      16038   <NA>    <NA> 
#> 4 370869     NA     3 IC      James Jones    26 Wake… <NA>    Newark  DE      19711   <NA>    <NA> 
#> 5 373735     NA     4 IC      Calvin Walker  27 Hage… <NA>    Cranbu… NJ      08512   <NA>    <NA> 
#> 6 375237     NA     5 IC      Margaret Ervin 190 Phe… <NA>    West C… PA      19380   <NA>    <NA> 
#> # … with 15 more variables: date <date>, amount <dbl>, fil_type <chr>, filer <chr>, office <chr>,
#> #   district <chr>, party <chr>, fil_addr1 <chr>, fil_addr2 <chr>, fil_city <chr>,
#> #   fil_state <chr>, fil_zip <chr>, county <chr>, fil_phone <chr>, tx <int>, and abbreviated
#> #   variable names ¹​con_addr1, ²​con_addr2, ³​con_city, ⁴​con_state, ⁵​occupation
```

Checking the number of distinct values of a discrete variable is another
good way to ensure the file was read properly.

``` r
count(pac, fil_type)
#> # A tibble: 6 × 2
#>   fil_type                       n
#>   <chr>                      <int>
#> 1 1                          81170
#> 2 2                       21572472
#> 3 3                          11825
#> 4 4                           4096
#> 5 THE RED BRICK COMMITTEE       10
#> 6 <NA>                       91461
```

### Missing

We should first check the number of missing values in each column.

``` r
col_stats(pac, count_na)
#> # A tibble: 27 × 4
#>    col         class         n            p
#>    <chr>       <chr>     <int>        <dbl>
#>  1 filerid     <chr>         0 0           
#>  2 eyear       <int>   1320470 0.0607      
#>  3 cycle       <int>        10 0.000000460 
#>  4 section     <chr>      4318 0.000198    
#>  5 contributor <chr>       470 0.0000216   
#>  6 con_addr1   <chr>    106057 0.00487     
#>  7 con_addr2   <chr>  19750414 0.908       
#>  8 con_city    <chr>    108713 0.00500     
#>  9 con_state   <chr>    117370 0.00539     
#> 10 con_zip     <chr>    152082 0.00699     
#> 11 occupation  <chr>  10884677 0.500       
#> 12 ename       <chr>  12360300 0.568       
#> 13 date        <date>    38073 0.00175     
#> 14 amount      <dbl>         1 0.0000000460
#> 15 fil_type    <chr>     91461 0.00420     
#> 16 filer       <chr>     82747 0.00380     
#> 17 office      <chr>  20398765 0.937       
#> 18 district    <chr>  21087290 0.969       
#> 19 party       <chr>  17414480 0.800       
#> 20 fil_addr1   <chr>   1140697 0.0524      
#> 21 fil_addr2   <chr>  16409251 0.754       
#> 22 fil_city    <chr>   1136522 0.0522      
#> 23 fil_state   <chr>   1136225 0.0522      
#> 24 fil_zip     <chr>   1138240 0.0523      
#> 25 county      <chr>  19036029 0.875       
#> 26 fil_phone   <chr>  14430491 0.663       
#> 27 tx          <int>         0 0
```

Any record missing a date, name, or amount should be flagged. These
variables are key to identifying transactions.

``` r
key_vars <- c("date", "contributor", "amount", "filer")
pac <- flag_na(pac, all_of(key_vars))
percent(mean(pac$na_flag), 0.01)
#> [1] "0.56%"
```

``` r
pac %>% 
  filter(na_flag) %>% 
  select(all_of(key_vars)) %>% 
  sample_n(10)
#> # A tibble: 10 × 4
#>    date       contributor                               amount filer                               
#>    <date>     <chr>                                      <dbl> <chr>                               
#>  1 NA         DEPOSIT FOR SPRING DANCE $35 - PER COUPLE   70   GUY K BARD DEM CLUB - TREAS. KATHY …
#>  2 2001-06-01 Stephen K Shadwick                         100   <NA>                                
#>  3 2001-02-26 Dennis W Quesenberry                        20   <NA>                                
#>  4 2001-09-26 Jeffrey A JONES                             10   <NA>                                
#>  5 2001-02-14 JOHN R. CHISOM                             100   <NA>                                
#>  6 2001-02-26 Peter D FRANCO                              10   <NA>                                
#>  7 2001-01-26 Alan M RUNDLE                               12   <NA>                                
#>  8 2001-10-26 Steven L Smith                              76.9 <NA>                                
#>  9 2001-03-26 Michael D TURNER                            10   <NA>                                
#> 10 NA         EDWARD VARNIS III                          165.  INT. LONGSHOREMEN'S ASSOC (ILA) LOC…
```

All of the records missing a value are missing a `date`.

``` r
pac %>% 
  filter(na_flag) %>% 
  select(all_of(key_vars)) %>% 
  col_stats(count_na)
#> # A tibble: 4 × 4
#>   col         class      n          p
#>   <chr>       <chr>  <int>      <dbl>
#> 1 date        <date> 38073 0.314     
#> 2 contributor <chr>    470 0.00388   
#> 3 amount      <dbl>      1 0.00000825
#> 4 filer       <chr>  82747 0.683
```

### Duplicates

We can check for records that are entirely duplicated across every
variable using `duplicated()`. This process is memory inefficient, so we
will split our data frame into a list of 100,000 row chunks and check
each chunk at a time, appending our duplicate rows to a local text file.

``` r
pac <- mutate(pac, tx = row_number())
```

``` r
dupe_file <- here("state","pa", "contribs", "dupes.txt")
if (!file_exists(dupe_file)) {
  file_create(dupe_file)
  pac <- mutate(pac, group = str_sub(date, end = 7))
  pa_ids <- split(pac$tx, pac$group)
  pas <- pac %>% 
    select(-tx) %>% 
    group_split(group)
  pb <- txtProgressBar(max = length(pas), style = 3)
  pac <- select(pac, -group)
  flush_memory(1)
  for (i in seq_along(pas)) {
    d1 <- duplicated(pas[[i]], fromLast = FALSE) # check from front
    d2 <- duplicated(pas[[i]], fromLast = TRUE) # check from back
    dupes <- tibble(tx = pa_ids[[i]], dupe_flag = d1 | d2)
    dupes <- filter(dupes, dupe_flag == TRUE) # remove non dupes
    write_csv(dupes, dupe_file, append = TRUE) # append to disk
    rm(d1, d2, dupes); pas[[i]] <- NA # remove for memory
    Sys.sleep(10)
    flush_memory(1)
    setTxtProgressBar(pb, i)
  }
  rm(pas, pb)
  flush_memory()
}
```

We can now read that file and join it against the contributions.

``` r
dupes <- read_csv(
  file = dupe_file,
  col_names = c("tx", "dupe_flag"),
  col_types = cols(
    tx = col_double(),
    dupe_flag = col_logical()
  )
)
comma(nrow(dupes))
#> [1] "472,908"
```

``` r
pac <- left_join(pac, dupes, by = "tx")
pac <- mutate(pac, dupe_flag = !is.na(dupe_flag))
percent(mean(pac$dupe_flag), 0.01)
#> [1] "2.17%"
```

``` r
pac %>% 
  filter(dupe_flag) %>% 
  select(tx, all_of(key_vars))
#> # A tibble: 472,908 × 5
#>       tx date       contributor         amount filer                                               
#>    <dbl> <date>     <chr>                <dbl> <chr>                                               
#>  1  1474 2022-02-18 Jay M. Copenhaver     20   GAI CONSULTANTS INC- POLITICAL ACTION COMMITTEE     
#>  2  1475 2022-11-28 R. Scott Burnsworth   48   GAI CONSULTANTS INC- POLITICAL ACTION COMMITTEE     
#>  3  1630 2022-06-13 Matthew Sickles       40   GAI CONSULTANTS INC- POLITICAL ACTION COMMITTEE     
#>  4  1631 2022-02-07 George T. Reese       48.1 GAI CONSULTANTS INC- POLITICAL ACTION COMMITTEE     
#>  5  2416 2022-07-21 Lisa D. Henley        25   Conduent Incorporated Political Action Committee (C…
#>  6  2417 2022-10-06 Brian D. Humphreys    41.7 Conduent Incorporated Political Action Committee (C…
#>  7  3227 2022-09-27 Jean Thomas           10   Shapiro for Pennsylvania                            
#>  8  3228 2022-11-07 Betty Semel           10   Shapiro for Pennsylvania                            
#>  9  3229 2022-05-18 Jerry Fitzgibbon     100   Shapiro for Pennsylvania                            
#> 10  3230 2022-04-21 Donald Schindler      50   Shapiro for Pennsylvania                            
#> # … with 472,898 more rows
```

``` r
pac <- pac %>% select(-tx)
```

### Amounts

The range and distribution of the contribution `amount` should be
checked. We also want to note what percentage of the values are zero or
below.

``` r
summary(pac$amount)
#>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max.      NA's 
#>    -18000        10        22       217        75 114201950         1
mean(pac$amount <= 0)
#> [1] NA
```

``` r
glimpse(pac[c(which.min(pac$amount), which.max(pac$amount)), ])
#> Rows: 2
#> Columns: 28
#> $ filerid     <chr> "7900211", "20170217"
#> $ eyear       <int> 2003, 2019
#> $ cycle       <int> 6, 7
#> $ section     <chr> "ID", "IB"
#> $ contributor <chr> "JOHN J GALLAGHER", "CHARLOTTE SWENSON"
#> $ con_addr1   <chr> "1760 MARKET ST STE 1100", "212 IDRIS RD"
#> $ con_addr2   <chr> NA, "APT H1"
#> $ con_city    <chr> "PHILA", "MERION STATION"
#> $ con_state   <chr> "PA", "PA"
#> $ con_zip     <chr> "19103", "190661635"
#> $ occupation  <chr> NA, NA
#> $ ename       <chr> NA, NA
#> $ date        <date> 2003-10-30, 2019-11-14
#> $ amount      <dbl> -18000, 114201950
#> $ fil_type    <chr> "2", "2"
#> $ filer       <chr> "SPRINGFIELD REP PARTY", "FRIENDS OF JENNIFER O'MARA"
#> $ office      <chr> NA, "STH"
#> $ district    <chr> NA, "165"
#> $ party       <chr> NA, "DEM"
#> $ fil_addr1   <chr> "359 SEDGEWOOD ROAD", "618 PROSPECT ROAD"
#> $ fil_addr2   <chr> NA, NA
#> $ fil_city    <chr> "SPRINGFIELD", "SPRINGFIELD"
#> $ fil_state   <chr> "PA", "PA"
#> $ fil_zip     <chr> "19064", "19064"
#> $ county      <chr> NA, "23"
#> $ fil_phone   <chr> NA, "2672299356"
#> $ na_flag     <lgl> FALSE, FALSE
#> $ dupe_flag   <lgl> FALSE, FALSE
```

![](../plots/hist_amount-1.png)<!-- -->

### Dates

We can add the calendar year a contribution was made using
`lubridate::year()`.

``` r
pac <- mutate(pac, year = year(date))
```

There are a handful of missing or irregular dates.

``` r
percent(prop_na(pac$date), 0.01)
#> [1] "0.17%"
min(pac$date, na.rm = TRUE)
#> [1] "1900-01-16"
sum(pac$year < 2000, na.rm = TRUE)
#> [1] 298
max(pac$date, na.rm = TRUE)
#> [1] "9201-01-12"
sum(pac$date > today(), na.rm = TRUE)
#> [1] 57
```

The bulk of transactions occur between 2000 and 2022.

![](../plots/bar_year-1.png)<!-- -->

## Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are tailor made to facilitate this process.

### Address

For the street `*_addresss` variables, the `campfin::normal_address()`
function will force consistence case, remove punctuation, and abbreviate
official USPS suffixes.

``` r
norm_addr <- pac %>%
  count(con_addr1, con_addr2, sort = TRUE) %>% 
  select(-n) %>% 
  unite(
    col = con_addr_full,
    starts_with("con_addr"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    con_addr_norm = normal_address(
      address = con_addr_full,
      abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-con_addr_full)
```

``` r
norm_addr
#> # A tibble: 1,823,347 × 3
#>    con_addr1                 con_addr2 con_addr_norm        
#>    <chr>                     <chr>     <chr>                
#>  1 929 Long Bridge Drive     <NA>      929 LONG BRIDGE DR   
#>  2 1719 SPRING GARDEN STREET <NA>      1719 SPRING GARDEN ST
#>  3 1601 Chestnut St          <NA>      1601 CHESTNUT ST     
#>  4 Lilly Corporate Center    <NA>      LILLY CORPORATE CTR  
#>  5 1719 Spring Garden Street <NA>      1719 SPRING GARDEN ST
#>  6 One Amgen Center Drive    <NA>      ONE AMGEN CENTER DR  
#>  7 PO Box 15437              <NA>      PO BOX 15437         
#>  8 135 Easton Turnpike       <NA>      135 EASTON TPKE      
#>  9 538 S MAIN ST             <NA>      538 S MAIN ST        
#> 10 100 N Riverside           <NA>      100 N RIVERSIDE      
#> # … with 1,823,337 more rows
pac <- left_join(pac, norm_addr)
rm(norm_addr); flush_memory(1)
```

We will repeat the process for filer addresses.

``` r
norm_addr <- pac %>% 
  count(fil_addr1, fil_addr2, sort = TRUE) %>% 
  select(-n) %>% 
  unite(
    col = fil_addr_full,
    starts_with("fil_addr"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    fil_addr_norm = normal_address(
      address = fil_addr_full,
      abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-fil_addr_full)
```

``` r
norm_addr
#> # A tibble: 10,351 × 3
#>    fil_addr1                 fil_addr2                      fil_addr_norm                          
#>    <chr>                     <chr>                          <chr>                                  
#>  1 <NA>                      <NA>                           <NA>                                   
#>  2 929 Long Bridge Drive     <NA>                           929 LONG BRIDGE DR                     
#>  3 1719 Spring Garden Street <NA>                           1719 SPRING GARDEN ST                  
#>  4 702 SW 8TH                <NA>                           702 SW 8TH                             
#>  5 539 S. Main Street        <NA>                           539 S MAIN ST                          
#>  6 501 Third Street NW       <NA>                           501 THIRD STREET NW                    
#>  7 101 Constitution Ave NW   Suite 400W                     101 CONSTITUTION AVE NW SUITE 400W     
#>  8 1200 WILSON BLVD          <NA>                           1200 WILSON BLVD                       
#>  9 c/o Zeneca Inc.           1800 Concord Pike PO Box 15437 C/O ZENECA INC 1800 CONCORD PIKE PO BO…
#> 10 LILLY CORPORATE CENTER    <NA>                           LILLY CORPORATE CTR                    
#> # … with 10,341 more rows
pac <- left_join(pac, norm_addr)
rm(norm_addr); flush_memory(1)
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
pac <- mutate_at(
  .tbl = pac,
  .vars = vars(ends_with("zip")),
  .funs = list(norm = normal_zip),
  na_rep = TRUE
)
```

``` r
progress_table(
  pac$con_zip,
  pac$con_zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 × 6
#>   stage            prop_in n_distinct prop_na    n_out n_diff
#>   <chr>              <dbl>      <dbl>   <dbl>    <dbl>  <dbl>
#> 1 pac$con_zip        0.424     633665 0.00699 12436932 608105
#> 2 pac$con_zip_norm   0.994      35404 0.00788   121685   6121
```

### State

There is no need to clean the two state variables.

``` r
prop_in(pac$con_state, valid_state)
#> [1] 0.9999991
prop_in(pac$fil_state, valid_state)
#> [1] 0.9999995
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
con_norm_city <- pac %>% 
  count(con_city, con_state, con_zip_norm, sort = TRUE) %>% 
  select(-n) %>% 
  mutate(
    across(
      .cols = con_city, 
      .fns = list(norm = normal_city), 
      abbs = usps_city,
      states = c("PA", "DC", "PENNSYLVANIA"),
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

``` r
fil_norm_city <- pac %>% 
  count(fil_city, fil_state, fil_zip_norm, sort = TRUE) %>% 
  select(-n) %>% 
  mutate(
    across(
      .cols = fil_city, 
      .fns = list(norm = normal_city), 
      abbs = usps_city,
      states = c("PA", "DC", "PENNSYLVANIA"),
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
con_norm_city <- con_norm_city %>% 
  left_join(
    y = zipcodes,
    by = c(
      "con_state" = "state",
      "con_zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(con_city_norm, city_match),
    match_dist = str_dist(con_city_norm, city_match),
    con_city_swap = if_else(
      condition = !is.na(match_dist) & (match_abb | match_dist == 1),
      true = city_match,
      false = con_city_norm
    )
  ) %>% 
  select(
    -city_match,
    -match_dist,
    -match_abb
  )
```

``` r
fil_norm_city <- fil_norm_city %>% 
  left_join(
    y = zipcodes,
    by = c(
      "fil_state" = "state",
      "fil_zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(fil_city_norm, city_match),
    match_dist = str_dist(fil_city_norm, city_match),
    fil_city_swap = if_else(
      condition = !is.na(match_dist) & (match_abb | match_dist == 1),
      true = city_match,
      false = fil_city_norm
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
city/state/zip combination.

``` r
good_refine <- con_norm_city %>% 
  mutate(
    con_city_refine = con_city_swap %>% 
      key_collision_merge() %>% 
      n_gram_merge(numgram = 1)
  ) %>% 
  filter(con_city_refine != con_city_swap) %>% 
  inner_join(
    y = zipcodes,
    by = c(
      "con_city_refine" = "city",
      "con_state" = "state",
      "con_zip_norm" = "zip"
    )
  )
```

    #> # A tibble: 573 × 5
    #>    con_state con_zip_norm con_city_swap     con_city_refine       n
    #>    <chr>     <chr>        <chr>             <chr>             <int>
    #>  1 SC        29406        NORTH CHARLESTON  CHARLESTON            4
    #>  2 PA        17702        SO WILLIAMSPORT   WILLIAMSPORT          3
    #>  3 CA        92563        MURIETTA          MURRIETA              2
    #>  4 FL        32082        PONTE VERDE BEACH PONTE VEDRA BEACH     2
    #>  5 IL        60429        EAST HAZEL CREST  HAZEL CREST           2
    #>  6 IL        62257        MARRISA           MARISSA               2
    #>  7 IN        46184        NEW WHITELAND     WHITELAND             2
    #>  8 MD        21078        HARV DE GRACE     HAVRE DE GRACE        2
    #>  9 MI        48094        WASHINGTON TW     WASHINGTON            2
    #> 10 MI        48095        WASHINGTON TN     WASHINGTON            2
    #> # … with 563 more rows

Then we can join the refined values back to the database.

``` r
con_norm_city <- con_norm_city %>% 
  left_join(good_refine, by = names(.)) %>% 
  mutate(con_city_refine = coalesce(con_city_refine, con_city_swap))
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
pac_out <- con_norm_city %>% 
  filter(con_city_refine %out% c(valid_city, extra_city)) %>% 
  count(con_city_refine, con_state, sort = TRUE) %>% 
  drop_na() %>% 
  head(1000)
```

Passing these values to `campfin::check_city()` with `purrr::pmap_dfr()`
will return a single tibble of the rows returned by each city/state
combination.

First, we’ll check to see if the API query has already been done and a
file exist on disk. If such a file exists, we can read it using
`readr::read_csv()`. If not, the query will be sent and the file will be
written using `readr::write_csv()`.

``` r
check_file <- here("state","pa", "contribs", "data", "api_check.csv")
if (file_exists(check_file)) {
  check <- read_csv(
    file = check_file,
    col_types = cols(
      .default = col_character(),
      check_city_flag = col_logical()
    )
  )
} else {
  check <- pmap_dfr(
    .l = list(
      pac_out$con_city_refine, 
      pac_out$con_state
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
  c(valid_locality)
```

``` r
valid_locality <- c(valid_locality, "ABBOTT PARK", "RESEARCH TRIANGLE PARK")
```

#### Progress

``` r
con_norm_city <- con_norm_city %>% 
  mutate(
    con_city_refine = con_city_refine %>% 
      na_if("ILLEGIBLE") %>% 
      str_replace("^PHILA$", "PHILADELPHIA") %>% 
      str_replace("^PGH$", "PITTSBURGH") %>% 
      str_replace("^NEW YORK CITY$", "NEW YORK") %>% 
      str_replace("^H\\sBURG$", "HARRISBURG") %>% 
      str_replace("^HBG$", "HARRISBURG") %>% 
      str_replace("^NYC$", "NEW YORK")
  )
```

``` r
pac <- left_join(pac, con_norm_city)
pac <- left_join(pac, fil_norm_city)
```

| stage                                                                               | prop_in | n_distinct | prop_na |  n_out | n_diff |
|:------------------------------------------------------------------------------------|--------:|-----------:|--------:|-------:|-------:|
| str_to_upper(pac$con_city) | 0.972| 39240| 0.005| 613557| 24580| |pac$con_city_norm |   0.983 |      34844 |   0.007 | 356781 |  20105 |
| pac$con_city_swap | 0.994| 23639| 0.007| 127612| 8866| |pac$con_city_refine         |   0.994 |      23148 |   0.007 | 121533 |   8376 |

You can see how the percentage of valid values increased with each
stage.

``` r
prop_in(pac$con_city_refine, many_city)
#> [1] 0.9943758
prop_in(pac$fil_city_swap, many_city)
#> [1] 0.9908933
```

![](../plots/bar_progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar_distinct-1.png)<!-- -->

## Conclude

``` r
pac <- pac %>% 
  select(
    -con_city_norm,
    -con_city_swap,
    con_city_clean = con_city_refine
  ) %>% 
  select(
    -fil_city_norm,
    fil_city_clean = fil_city_swap
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  relocate(ends_with("city_clean"), .after = fil_addr_clean)
```

``` r
glimpse(sample_n(pac, 100))
#> Rows: 100
#> Columns: 35
#> $ filerid        <chr> "8200358", "8300256", "2008381", "9900235", "2004206", "2007003", "2008362…
#> $ eyear          <int> 2001, 2007, 2009, 2007, 2019, 2012, 2020, 2009, NA, 2016, 2008, 2012, 2005…
#> $ cycle          <int> 6, 6, 7, 4, 7, 6, 4, 4, 3, 2, 7, 4, 7, 5, 1, 5, 5, 5, 7, 3, 7, 5, 5, 4, 5,…
#> $ section        <chr> "IB", "IB", "IB", "IB", "ID", "IB", "IB", "IB", "IB", "ID", "IB", "IB", "I…
#> $ contributor    <chr> "WILLIAM COCOLIS", "CHARLES J BOYTIN", "JOSEPHINE A TACK", "KIMBERLY D GAL…
#> $ con_addr1      <chr> "14 JAMIANNA LN", "215 CALLENDER ROAD", "20 STONE HOUSE DRIVE", "7183 WHIT…
#> $ con_addr2      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "OR1-2277", NA, NA, NA, NA, NA…
#> $ con_city       <chr> "MONROE", "HUNLOCK CREEK", "WHITE HOUSE STATION", "W BLOOMFIELD", "Thousan…
#> $ con_state      <chr> "CT", "PA", "NJ", "MI", "CA", "OH", "TN", "PA", "TX", "TN", "CA", "OR", "N…
#> $ con_zip        <chr> "06468", "18621", "08889", "48324-247", "913201730", "44240", "380173583",…
#> $ occupation     <chr> "ASST DIR FMS HUMAN RESOUR", NA, NA, "Operator Services As", "Director", N…
#> $ ename          <chr> "CIGNA CORPORATION", NA, NA, NA, "Amgen Inc.", NA, "WALGREEN CO", NA, NA, …
#> $ date           <date> 2001-11-06, 2007-04-27, 2009-05-28, 2007-03-20, 2019-01-22, 2012-11-15, 2…
#> $ amount         <dbl> 6.82, 7.19, 2.50, 20.00, 93.70, 50.00, 25.00, 69.85, 25.00, 50.00, 37.50, …
#> $ fil_type       <chr> "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2",…
#> $ filer          <chr> "CIGNA Corporation Political Action Committee", "PA PPL PEOPLE FOR GOOD GO…
#> $ office         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ district       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ party          <chr> NA, NA, NA, NA, NA, NA, "OTH", "OTH", NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ fil_addr1      <chr> "174 WATERFRONT ST ST #500", "2 N 9TH STREET", "100 ABBOTT PARK RD D312AP6…
#> $ fil_addr2      <chr> NA, NA, NA, NA, "Suite 1100 North", NA, "Suite 725", NA, "Suite 1100", NA,…
#> $ fil_city       <chr> "NATION HARBOR", "ALLENTOWN", "ABBOTT PARK", "WASHINGTON", "Washington", "…
#> $ fil_state      <chr> "MD", "PA", "IL", "DC", "DC", "TN", "DC", "PA", "DC", "TN", "DC", "IL", NA…
#> $ fil_zip        <chr> "20745", "18101", "60064", "20001-2797", "20005", "381204117", "20005", "1…
#> $ county         <chr> "51", NA, NA, NA, NA, NA, NA, "51", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ fil_phone      <chr> NA, NA, NA, NA, "2025859500", "9018187407", "8473154653", NA, "2027725600"…
#> $ na_flag        <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ dupe_flag      <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE…
#> $ year           <dbl> 2001, 2007, 2009, 2007, 2019, 2012, 2020, 2009, 2022, 2016, 2008, 2012, 20…
#> $ con_addr_clean <chr> "14 JAMIANNA LN", "215 CALLENDER RD", "20 STONE HOUSE DR", "7183 WHITE OAK…
#> $ fil_addr_clean <chr> "174 WATERFRONT ST ST #500", "2 N 9TH ST", "100 ABBOTT PARK RD D312AP6D2",…
#> $ con_city_clean <chr> "MONROE", "HUNLOCK CREEK", "WHITEHOUSE STATION", "WEST BLOOMFIELD", "THOUS…
#> $ fil_city_clean <chr> "NATION HARBOR", "ALLENTOWN", "ABBOTT PARK", "WASHINGTON", "WASHINGTON", "…
#> $ con_zip_clean  <chr> "06468", "18621", "08889", "48324", "91320", "44240", "38017", "19130", "7…
#> $ fil_zip_clean  <chr> "20745", "18101", "60064", "20001", "20005", "38120", "20005", "19130", "2…
```

1.  There are 21,761,034 records in the database.
2.  The range and distribution of `amount` and `date` seem reasonable.
3.  There are 0.56% records missing key variables.
4.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
5.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("state","pa", "contribs", "data", "clean"))
clean_path <- path(clean_dir, "pa_contribs_clean.csv")
write_csv(pac, clean_path, na = "")
(clean_size <- file_size(clean_path))
#> 6.12G
file_encoding(clean_path) %>% 
  mutate(across(path, path.abbrev))
#> # A tibble: 1 × 3
#>   path                                                                                mime  charset
#>   <fs::path>                                                                          <chr> <chr>  
#> 1 …ode/accountability_datacleaning/state/pa/contribs/data/clean/pa_contribs_clean.csv <NA>  <NA>
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

## Dictionary

The following table describes the variables in our final exported file:

| Column           | Type        | Definition                             |
|:-----------------|:------------|:---------------------------------------|
| `filerid`        | `character` | Filer unique filer ID                  |
| `eyear`          | `integer`   | Election year                          |
| `cycle`          | `integer`   | Election cycle                         |
| `section`        | `character` | Election section                       |
| `contributor`    | `character` | Contributor full name                  |
| `con_addr1`      | `character` | Contributor street address             |
| `con_addr2`      | `character` | Contributor secondary address          |
| `con_city`       | `character` | Contributor city name                  |
| `con_state`      | `character` | Contributor state abbreviation         |
| `con_zip`        | `character` | Contributor ZIP+4 code                 |
| `occupation`     | `character` | Contributor occupation                 |
| `ename`          | `character` | Contributor employer name              |
| `date`           | `double`    | Date contribution made                 |
| `amount`         | `double`    | Contribution amount or correction      |
| `fil_type`       | `character` | Filer type                             |
| `filer`          | `character` | Filer committee name                   |
| `office`         | `character` | Filer office sought                    |
| `district`       | `character` | District election held                 |
| `party`          | `character` | Filer political party                  |
| `fil_addr1`      | `character` | Filer street address                   |
| `fil_addr2`      | `character` | Filer secondary address                |
| `fil_city`       | `character` | Filer city name                        |
| `fil_state`      | `character` | Filer 2-digit state abbreviation       |
| `fil_zip`        | `character` | Filer ZIP+4 code                       |
| `county`         | `character` | County election held in                |
| `fil_phone`      | `character` | Filer telephone number                 |
| `na_flag`        | `logical`   | Flag for missing date, amount, or name |
| `dupe_flag`      | `logical`   | Flag for completely duplicated record  |
| `year`           | `double`    | Calendar year of contribution date     |
| `con_addr_clean` | `character` | Normalized contributor street address  |
| `fil_addr_clean` | `character` | Normalized Filer street address        |
| `con_city_clean` | `character` | Normalized Filer 5-digit ZIP code      |
| `fil_city_clean` | `character` | Normalized Filer state abbreviation    |
| `con_zip_clean`  | `character` | Normalized Filer city name             |
| `fil_zip_clean`  | `character` | Normalized contributor city name       |
