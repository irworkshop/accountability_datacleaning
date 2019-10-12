Florida Lobbyist Registration
================
Kiernan Nicholls
2019-10-10 16:49:27

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)

<!-- Place comments regarding knitting here -->

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
pacman::p_load_gh("irworkshop/campfin")
pacman::p_load_gh("kiernann/gluedown")
pacman::p_load(
  stringdist, # levenshtein value
  RSelenium, # remote browser
  tidyverse, # data manipulation
  lubridate, # datetime strings
  magrittr, # pipe opperators
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
[`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning "TAP repo")
GitHub repository.

The `R_campfin` project uses the [RStudio
projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects "Rproj")
feature and should be run as such. The project also uses the dynamic
`here::here()` tool for file paths relative to *your* machine.

``` r
# where does this document knit?
here::here()
#> [1] "/home/kiernan/R/accountability_datacleaning/R_campfin"
```

## Data

Data is obtained as tab-delinated files from the [Florida Lobbying
Registration Office](https://floridalobbyist.gov/) (LRO).

> Legislative and Executive branch lobbyist/principal registration
> datasets can be downloaded free of charge. Each dataset contains basic
> information about lobbyists, the principals they register to
> represent, and any associated firm information. Click on the File
> Definition Description link below to view the file format. The
> datasets are updated daily.

``` r
key_url <- "https://floridalobbyist.gov/reports/disk%20file%20definition.pdf?cp=0.3379601757893852"
download.file(key_url, destfile = url2path(key_url, here("fl", "lobbying", "reg", "docs")))
```

## Import

### Download

The LRO provides the datasets in tab-delimited format.

> The tab-delimited files below are in the (.TXT) format and can be
> imported into any word processor, spreadsheet, or database program.
> 
>   - [Legislative Lobbyist
>     File](https://floridalobbyist.gov/reports/llob.txt)
>   - [Executive Lobbyist
>     File](https://floridalobbyist.gov/reports/llob.txt)

We can download these two files to our raw directory.

``` r
raw_dir <- here("fl", "lobbying", "reg", "data", "raw")
dir_create(raw_dir)
```

``` r
llob_url <- "https://floridalobbyist.gov/reports/llob.txt"
llob_file <- url2path(llob_url, raw_dir)
download.file(url = llob_url, destfile = llob_file)

elob_url <- "https://floridalobbyist.gov/reports/elob.txt"
elob_file <- url2path(elob_url, raw_dir)
download.file(url = elob_url, destfile = elob_file)
```

### Read

We can read both files at once with the `vroom::vroom()` function.

``` r
fllr <- vroom(
  file = dir_ls(raw_dir),
  .name_repair = make_clean_names,
  delim = "\t",
  escape_backslash = FALSE,
  escape_double = FALSE,
  id = "source",
  skip = 2,
  col_types = cols(
    .default = col_character(),
    `Eff Date` = col_date_usa(),
    `WD Date` = col_date_usa(),
  )
)
```

The original file contains *three* different types of data, with the
type specified in the second row of the spreadsheet.

1.  Lobbyist
2.  Registration
3.  Lobby Firm

This resuled in most column names being repeated for each entity type,
with `vroom::vroom()` and `janitor::make_clean_names()` appending each
repeated name with a unique digit. We will replace these unique digits
with a meaningful prefix identifying the entity type.

``` r
fllr_names <- names(fllr)
fllr_prefix <- c("lobby", "client", "firm")
```

``` r
fllr_names[02:14] <- str_c(fllr_prefix[1], str_remove(fllr_names[02:14], "_(.*)$"), sep = "_")
fllr_names[15]    <- str_c(fllr_prefix[2], str_remove(fllr_names[15],    "^(.*)_"), sep = "_")
fllr_names[16:24] <- str_c(fllr_prefix[2], str_remove(fllr_names[16:24], "_(.*)$"), sep = "_")
fllr_names[26:36] <- str_c(fllr_prefix[3], str_remove(fllr_names[26:36], "_(.*)$"), sep = "_")
which_address <- str_which(fllr_names, "address")
fllr_names[which_address] <- str_c(fllr_names[which_address], c(1:3, 1:2, 1:2))
all(fllr_names == tidy_names(fllr_names))
#> [1] TRUE
```

We can see how this process made the variable names much more useful.

    #> # A tibble: 10 x 2
    #>    origial        fixed          
    #>    <chr>          <chr>          
    #>  1 address_5      client_address2
    #>  2 country        client_country 
    #>  3 principal_name client_name    
    #>  4 state_2        client_state   
    #>  5 zip_3          firm_zip       
    #>  6 address        lobby_address1 
    #>  7 address_2      lobby_address2 
    #>  8 first_name     lobby_first    
    #>  9 last_name      lobby_last     
    #> 10 zip            lobby_zip

So we can overwrite the orignal names with this new vector.

``` r
fllr <- set_names(fllr, fllr_names)
```

## Explore

``` r
head(fllr)
#> # A tibble: 6 x 36
#>   source lobby_last lobby_first lobby_middle lobby_suffix lobby_address1 lobby_address2
#>   <chr>  <chr>      <chr>       <chr>        <chr>        <chr>          <chr>         
#> 1 /home… Aaron      Lisa        <NA>         <NA>         7101 Sleepy H… <NA>          
#> 2 /home… Aaron      Lisa        <NA>         <NA>         7101 Sleepy H… <NA>          
#> 3 /home… Aaron      Lisa        <NA>         <NA>         7101 Sleepy H… <NA>          
#> 4 /home… Aaron      Lisa        <NA>         <NA>         7101 Sleepy H… <NA>          
#> 5 /home… Aaron      Lisa        <NA>         <NA>         7101 Sleepy H… <NA>          
#> 6 /home… Aaron      Lisa        <NA>         <NA>         7101 Sleepy H… <NA>          
#> # … with 29 more variables: lobby_address3 <chr>, lobby_city <chr>, lobby_state <chr>,
#> #   lobby_zip <chr>, lobby_phone <chr>, lobby_ext <chr>, lobby_suspended <chr>, client_name <chr>,
#> #   client_eff <date>, client_wd <date>, client_address1 <chr>, client_address2 <chr>,
#> #   client_city <chr>, client_state <chr>, client_zip <chr>, client_country <chr>,
#> #   client_naics <chr>, firm_name <chr>, firm_address1 <chr>, firm_address2 <chr>,
#> #   firm_city <chr>, firm_state <chr>, firm_zip <chr>, firm_country <chr>, firm_cntry <chr>,
#> #   firm_phone <chr>, firm_ext <chr>, firm_eff <date>, firm_wd <date>
tail(fllr)
#> # A tibble: 6 x 36
#>   source lobby_last lobby_first lobby_middle lobby_suffix lobby_address1 lobby_address2
#>   <chr>  <chr>      <chr>       <chr>        <chr>        <chr>          <chr>         
#> 1 /home… Zauder     Stephanie   Grutman      <NA>         401 E. Las Ol… Suite 1400    
#> 2 /home… Zauder     Stephanie   Grutman      <NA>         401 E. Las Ol… Suite 1400    
#> 3 /home… Zauder     Stephanie   Grutman      <NA>         401 E. Las Ol… Suite 1400    
#> 4 /home… Zepp       Victoria    Vangalis     DPL          411 E College… <NA>          
#> 5 /home… Zingale    James       A.           <NA>         Post Office 5… <NA>          
#> 6 /home… Zubaly     Amy         S.           <NA>         Po Box 10114   <NA>          
#> # … with 29 more variables: lobby_address3 <chr>, lobby_city <chr>, lobby_state <chr>,
#> #   lobby_zip <chr>, lobby_phone <chr>, lobby_ext <chr>, lobby_suspended <chr>, client_name <chr>,
#> #   client_eff <date>, client_wd <date>, client_address1 <chr>, client_address2 <chr>,
#> #   client_city <chr>, client_state <chr>, client_zip <chr>, client_country <chr>,
#> #   client_naics <chr>, firm_name <chr>, firm_address1 <chr>, firm_address2 <chr>,
#> #   firm_city <chr>, firm_state <chr>, firm_zip <chr>, firm_country <chr>, firm_cntry <chr>,
#> #   firm_phone <chr>, firm_ext <chr>, firm_eff <date>, firm_wd <date>
glimpse(sample_frac(fllr))
#> Observations: 24,084
#> Variables: 36
#> $ source          <chr> "/home/kiernan/R/accountability_datacleaning/R_campfin/fl/lobbying/reg/d…
#> $ lobby_last      <chr> "Haskins", "Bracy", "Dorworth", "Shepp", "Conforme", "Cannon", "Daniel",…
#> $ lobby_first     <chr> "Alan", "Carol", "Chris", "David", "Jorge", "Roy", "David", "Sydney", "S…
#> $ lobby_middle    <chr> NA, "L.", NA, "A.", "Luis", "Dean", "T.", "P.", "L.", "K.", "Scott", "S.…
#> $ lobby_suffix    <chr> NA, NA, NA, NA, NA, "Jr.", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ lobby_address1  <chr> "1111 E Touhy Ave", "201 East Park Avenue", "618 E. South Street", "Po B…
#> $ lobby_address2  <chr> "Ste 400", "5th Floor", "Suite 500", NA, "Suite 315", "Ste 600", NA, NA,…
#> $ lobby_address3  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ lobby_city      <chr> "Des Plaines", "Tallahassee", "Orlando", "Tallahassee", "Miami", "Tallah…
#> $ lobby_state     <chr> "IL", "FL", "FL", "FL", "FL", "FL", "FL", "FL", "FL", "FL", "FL", "FL", …
#> $ lobby_zip       <chr> "60018", "32301", "32801", "32302-2570", "33145-2784", "32301", "32301",…
#> $ lobby_phone     <chr> "(847) 544-7075", "(850) 577-0444", "(407) 803-3878", "(850) 671-4401", …
#> $ lobby_ext       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ lobby_suspended <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ client_name     <chr> "National Insurance Crime Bureau (NICB)", "Resorts World Miami, LLC", "S…
#> $ client_eff      <date> 2019-01-11, 2019-01-03, 2019-03-07, 2019-01-07, 2019-01-31, 2019-02-13,…
#> $ client_wd       <date> NA, NA, NA, 2019-01-07, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ client_address1 <chr> "1111 E Touhy Ave", "1501 Biscayne Blvd", "1600 NW 163rd Street", "901 S…
#> $ client_address2 <chr> "Ste 400", "Ste 107", NA, NA, "Suite 700", NA, NA, NA, NA, NA, NA, NA, "…
#> $ client_city     <chr> "Des Plaines", "Miami", "Miami", "Lakeland", "Chicago", "Miami", "Pensac…
#> $ client_state    <chr> "IL", "FL", "FL", "FL", "IL", "FL", "FL", "FL", "FL", "FL", "FL", "FL", …
#> $ client_zip      <chr> "60018", "33132", "33160", "33803", "60607-3015", "33142-6812", "32522-7…
#> $ client_country  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ client_naics    <chr> "524298", "721120", "424820", "812320", "621111", "237310", "622110", "3…
#> $ firm_name       <chr> NA, "Ballard Partners", "Ballard Partners", "Southern Strategy Group", "…
#> $ firm_address1   <chr> NA, "201 East Park Avenue", "201 East Park Avenue", "PO Box 10570", "180…
#> $ firm_address2   <chr> NA, "5th Floor", "5th Floor", NA, "Suite 315", "Ste 600", NA, NA, "Ste 5…
#> $ firm_city       <chr> NA, "Tallahassee", "Tallahassee", "Tallahassee", "Miami", "Tallahassee",…
#> $ firm_state      <chr> NA, "FL", "FL", "FL", "FL", "FL", "FL", "FL", "FL", NA, "FL", "FL", "FL"…
#> $ firm_zip        <chr> NA, "32301", "32301", "32302", "33145", "32301", "32301", "32302", "3230…
#> $ firm_country    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ firm_cntry      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ firm_phone      <chr> NA, "(850) 577-0444", "(850) 577-0444", "(850) 671-4401", "(786) 618-918…
#> $ firm_ext        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ firm_eff        <date> NA, 2019-01-03, 2019-03-07, 2019-01-07, 2019-01-31, 2019-02-13, 2019-01…
#> $ firm_wd         <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, 2019-08-06, NA, NA, NA, NA, NA,…
```

### Missing

``` r
glimpse_fun(fllr, count_na)
#> # A tibble: 36 x 4
#>    col             type      n        p
#>    <chr>           <chr> <dbl>    <dbl>
#>  1 source          chr       0 0       
#>  2 lobby_last      chr       0 0       
#>  3 lobby_first     chr       0 0       
#>  4 lobby_middle    chr    6063 0.252   
#>  5 lobby_suffix    chr   22553 0.936   
#>  6 lobby_address1  chr       0 0       
#>  7 lobby_address2  chr   11546 0.479   
#>  8 lobby_address3  chr   24084 1       
#>  9 lobby_city      chr       0 0       
#> 10 lobby_state     chr       0 0       
#> 11 lobby_zip       chr       4 0.000166
#> 12 lobby_phone     chr       0 0       
#> 13 lobby_ext       chr   24084 1       
#> 14 lobby_suspended chr   24078 1.000   
#> 15 client_name     chr       0 0       
#> 16 client_eff      date      0 0       
#> 17 client_wd       date  21986 0.913   
#> 18 client_address1 chr       0 0       
#> 19 client_address2 chr   15369 0.638   
#> 20 client_city     chr       0 0       
#> 21 client_state    chr      10 0.000415
#> 22 client_zip      chr      16 0.000664
#> 23 client_country  chr   24052 0.999   
#> 24 client_naics    chr       0 0       
#> 25 firm_name       chr    2296 0.0953  
#> 26 firm_address1   chr    2296 0.0953  
#> 27 firm_address2   chr   13676 0.568   
#> 28 firm_city       chr    2296 0.0953  
#> 29 firm_state      chr    2296 0.0953  
#> 30 firm_zip        chr    2327 0.0966  
#> 31 firm_country    chr   24084 1       
#> 32 firm_cntry      chr   24084 1       
#> 33 firm_phone      chr    2296 0.0953  
#> 34 firm_ext        chr   24084 1       
#> 35 firm_eff        date   2304 0.0957  
#> 36 firm_wd         date  23880 0.992
```

``` r
fllr <- flag_na(fllr, ends_with("name"))
sum(fllr$na_flag)
#> [1] 2296
mean(fllr$na_flag)
#> [1] 0.095333
```

### Duplicates

``` r
fllr <- flag_dupes(fllr, everything())
sum(fllr$na_flag)
#> [1] 2296
mean(fllr$na_flag)
#> [1] 0.095333
```

### Dates

The database only contains registrants for the current year.

``` r
fllr <- mutate(fllr, client_year = year(client_eff))
unique(fllr$client_year == year(today()))
#> [1] TRUE
```

``` r
min(fllr$client_eff)
#> [1] "2019-01-01"
max(fllr$client_eff)
#> [1] "2019-10-10"
```
