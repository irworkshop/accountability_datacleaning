Indiana Contributions
================
Kiernan Nicholls
2020-02-04 17:35:40

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
  magrittr, # pipe operators
  gluedown, # print markdown
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
  rvest, # read html pages
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

Data is obtained from the [Indiana Election
Division](https://campaignfinance.in.gov/PublicSite/Homepage.aspx).

> ##### What is the quality of the data?
> 
> The information presented in the campaign finance database is, to the
> best of our ability, an accurate representation of the reports filed
> with the Election Division. This information is being provided as a
> service to the public, has been processed by the Election Division and
> should be cross-referenced with the original report on file with the
> Election Division.
> 
> Some of the information in the campaign finance database was submitted
> in electronic form. Most of the information was key-entered from paper
> reports. Sometimes items which are inconsistent with filing
> requirements, such as incorrect codes or incorrectly formatted or
> blank items, are present in the results of a query. They are incorrect
> or missing in the database because they were incorrect or missing on
> the reports submitted to the Election Division. For some incorrect or
> missing data in campaign finance reports, the Election Division has
> requested that the filer supply an amended report. The campaign
> finance database will be updated to reflect amendments received.

> ##### What does the database contain?
> 
> By Indiana law, candidates and committees are required to disclose
> detailed financial records of contributions received and expenditures
> made and debts owed by or to the committee. For committees, the
> campaign finance database contains all contributions, expenditures,
> and debts reported to the Election Division since January 1, 1998.

## Import

The IED provides annuel files for both campaign contributions and
expenditures.

> This page provides comma separated value (CSV) downloads of
> contribution and expenditure data for each reporting year in a zipped
> file format. These files can be downloaded and imported into other
> applications (Microsoft Excel, Microsoft Access, etc.).
> 
> This data was extracted from the Campaign Finance database as it
> existed as of 2/4/2020 1:00 AM.

### Download

We can read the [IED download
page](https://campaignfinance.in.gov/PublicSite/Reporting/DataDownload.aspx)
to get the list of URLs to each file.

``` r
raw_dir <- dir_create(here("in", "contribs", "data", "raw"))
```

``` r
aspx <- "https://campaignfinance.in.gov/PublicSite/Reporting/DataDownload.aspx"
raw_urls <- aspx %>% 
  read_html() %>% 
  html_node("#_ctl0_Content_dlstDownloadFiles") %>% 
  html_nodes("a") %>% 
  html_attr("href") %>% 
  str_subset("Contribution") %>% 
  str_replace("\\\\", "/")

md_bullet(raw_urls)
```

  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2000_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2001_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2002_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2003_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2004_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2005_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2006_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2007_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2008_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2009_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2010_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2011_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2012_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2013_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2014_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2015_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2016_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2017_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2018_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2019_ContributionData.csv.zip>
  - <https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/2020_ContributionData.csv.zip>

We can download each of these files to the raw directory.

``` r
raw_paths <- path(raw_dir, basename(raw_urls))
if (!all(this_file_new(raw_paths))) {
  download.file(raw_urls, raw_paths, method = "libcurl")
}
```

Then, we will unzip each file and delete the original.

``` r
raw_paths <- as_fs_path(map_chr(raw_paths, unzip, exdir = raw_dir))
dir_ls(raw_dir, regexp = ".zip$") %>% file_delete()
```

### Read

There are two problems with each of these files: 1. When the second line
of an address was entered, a `\n` newline character was enteted between
the two lines *within the same field*. The fields are surrounded in
double-quotes, but when reading the files these newlines mess things up.
2. Whenever a string itself contains `"` double-quotes, the first
occurance is registered as the end of the field itself, which begun with
a `"`.

To fix these issues, we will read each file as a single character string
and use regular expressions to find and replace these errant `\n` and
`"` characters. We will then write the edited strings to a new file.

``` r
fix_dir <- dir_create(here("in", "contribs", "data", "fix"))
if (!any(file_exists(dir_ls(fix_dir)))) {
  for (file in raw_paths) {
    read_file(file) %>% 
      # find newlines not at end of line
      str_replace_all("(?<!\"(\r|1|0)\")\n(?!\"\\d{1,10}\")", " ") %>%
      # find quotes not at end of field
      str_replace_all("(?<!(\n|^|,))\"(?!(,(?=\"))|$|\r)", "\'") %>% 
      str_trim(side = "both") %>% 
      # save to disk
      write_file(path = path(fix_dir, basename(file)))
    gc()
  }
}
fix_paths <- dir_ls(fix_dir)
```

These fixed files can be read into a single data frame with
`purrr::map_df()` and `readr::read_delim()`.

``` r
inc <- map_df(
  fix_paths,
  read_delim,
  delim = ",",
  quote = "\"",
  na = c("", "n/a", "NA", "N/A"),
  escape_backslash = FALSE,
  escape_double = FALSE,
  col_types = cols(
    .default = col_character(),
    FileNumber = col_integer(),
    Amount = col_double(),
    ContributionDate = col_datetime(),
    Amended = col_logical()
  )
)
```

``` r
inc <- inc %>% 
  clean_names("snake") %>% 
  rename(
    file = file_number,
    type = contributor_type,
    date = contribution_date,
    method = type
  )
```

## Explore

``` r
head(inc)
#> # A tibble: 6 x 17
#>    file committee_type committee candidate_name type  name  address city  state zip   occupation
#>   <int> <chr>          <chr>     <chr>          <chr> <chr> <chr>   <chr> <chr> <chr> <chr>     
#> 1    17 Regular Party  Indiana … <NA>           Borr… Sue … <NA>    <NA>  <NA>  <NA>  <NA>      
#> 2    17 Regular Party  Indiana … <NA>           Borr… Sue … 200 So… Indi… IN    46227 <NA>      
#> 3    17 Regular Party  Indiana … <NA>           Corp… 4 Ma… 9800 C… Indi… IN    46256 <NA>      
#> 4    17 Regular Party  Indiana … <NA>           Corp… Accr… 118 Ko… LaPo… IN    46350 <NA>      
#> 5    17 Regular Party  Indiana … <NA>           Corp… Accu… Mr. Jo… LaPo… IN    46350 <NA>      
#> 6    17 Regular Party  Indiana … <NA>           Corp… Ad-V… 712 11… Lawr… IL    62439 <NA>      
#> # … with 6 more variables: method <chr>, description <chr>, amount <dbl>, date <dttm>,
#> #   received_by <chr>, amended <lgl>
tail(inc)
#> # A tibble: 6 x 17
#>    file committee_type committee candidate_name type  name  address city  state zip   occupation
#>   <int> <chr>          <chr>     <chr>          <chr> <chr> <chr>   <chr> <chr> <chr> <chr>     
#> 1  7329 Candidate      Friends … Ian Russell G… Indi… Bria… 1519 w… Prin… IN    4760  <NA>      
#> 2  7329 Candidate      Friends … Ian Russell G… Indi… Ian … 1201 E… Prin… IN    47670 Teacher/E…
#> 3  7329 Candidate      Friends … Ian Russell G… Indi… Ian … 1201 E… Prin… IN    47670 Teacher/E…
#> 4  7329 Candidate      Friends … Ian Russell G… Indi… Ian … 1201 E… Prin… IN    47670 Teacher/E…
#> 5  7329 Candidate      Friends … Ian Russell G… Indi… Ian … 1201 E… Prin… IN    47670 Teacher/E…
#> 6  7329 Candidate      Friends … Ian Russell G… Indi… Jaco… 412 w … Prin… IN    47670 <NA>      
#> # … with 6 more variables: method <chr>, description <chr>, amount <dbl>, date <dttm>,
#> #   received_by <chr>, amended <lgl>
glimpse(sample_n(inc, 20))
#> Observations: 20
#> Variables: 17
#> $ file           <int> 439, 363, 3222, 7054, 4697, 396, 374, 4960, 3970, 790, 1772, 4019, 5429, …
#> $ committee_type <chr> "Regular Party", "Regular Party", "Political Action", "Candidate", "Polit…
#> $ committee      <chr> "Marion County Republican Central Committee", "Marion County Democratic C…
#> $ candidate_name <chr> NA, NA, NA, "Amie Lynne Neiling", NA, NA, NA, "Mitchell Elias Daniels, Jr…
#> $ type           <chr> "Individual", "Individual", "Individual", "Individual", "Individual", "In…
#> $ name           <chr> "Bryan J. Collins", "Russell L. Brown", "Dale C Adams", "Mary Lynda Child…
#> $ address        <chr> "6150 Autumn Ln", "6637 Meadowgreen Dr", "1017 Sunflower Trail", "498 Kno…
#> $ city           <chr> "Indianapolis", "Indianapolis", "Orlando", "Evans", "Zionsville", "Indian…
#> $ state          <chr> "IN", "IN", "Fl", "GA", "IN", "IN", "IN", "IN", "IN", "IN", "IN", "IN", "…
#> $ zip            <chr> "46220", "46236-8004", "32828", "30809", "46077", "46226", "46814", "4681…
#> $ occupation     <chr> NA, NA, NA, "Not Currently Employed", NA, NA, "Other", NA, NA, "Science/T…
#> $ method         <chr> "Direct", "Direct", "Direct", "Direct", "Direct", "Direct", "Direct", "Di…
#> $ description    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ amount         <dbl> 250.0, 10.0, 20.0, 10.0, 60.0, 250.0, 1000.0, 10.0, 100.0, 15.0, 36.0, 5.…
#> $ date           <dttm> 2001-05-31, 2009-03-26, 2008-02-26, 2018-07-16, 2001-12-27, 2017-08-28, …
#> $ received_by    <chr> "Buell", "Leslie Barnes", "Bruce McDivitt", "Amie Lynne Neiling", "S. Sho…
#> $ amended        <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FAL…
```

### Missing

``` r
col_stats(inc, count_na)
#> # A tibble: 17 x 4
#>    col            class        n         p
#>    <chr>          <chr>    <int>     <dbl>
#>  1 file           <int>        0 0        
#>  2 committee_type <chr>        0 0        
#>  3 committee      <chr>       33 0.0000211
#>  4 candidate_name <chr>   962859 0.614    
#>  5 type           <chr>    17342 0.0111   
#>  6 name           <chr>    17644 0.0113   
#>  7 address        <chr>    44350 0.0283   
#>  8 city           <chr>    40100 0.0256   
#>  9 state          <chr>    35839 0.0229   
#> 10 zip            <chr>    51335 0.0328   
#> 11 occupation     <chr>  1294427 0.826    
#> 12 method         <chr>        0 0        
#> 13 description    <chr>  1521771 0.971    
#> 14 amount         <dbl>        0 0        
#> 15 date           <dttm>    4154 0.00265  
#> 16 received_by    <chr>   102507 0.0654   
#> 17 amended        <lgl>        0 0
```

``` r
inc <- inc %>% flag_na(committee, name, amount, date)
mean(inc$na_flag)
#> [1] 0.01384448
```

### Duplicates

``` r
inc <- flag_dupes(inc, everything())
mean(inc$dupe_flag)
#> [1] 0.004561231
```

### Categorical

``` r
col_stats(inc, n_distinct)
#> # A tibble: 19 x 4
#>    col            class       n          p
#>    <chr>          <chr>   <int>      <dbl>
#>  1 file           <int>    2702 0.00172   
#>  2 committee_type <chr>       4 0.00000255
#>  3 committee      <chr>    4262 0.00272   
#>  4 candidate_name <chr>    1762 0.00112   
#>  5 type           <chr>      13 0.00000829
#>  6 name           <chr>  420065 0.268     
#>  7 address        <chr>  404270 0.258     
#>  8 city           <chr>   17757 0.0113    
#>  9 state          <chr>     284 0.000181  
#> 10 zip            <chr>   38859 0.0248    
#> 11 occupation     <chr>      33 0.0000211 
#> 12 method         <chr>      11 0.00000702
#> 13 description    <chr>    9992 0.00638   
#> 14 amount         <dbl>   45701 0.0292    
#> 15 date           <dttm>   9676 0.00617   
#> 16 received_by    <chr>    7698 0.00491   
#> 17 amended        <lgl>       2 0.00000128
#> 18 na_flag        <lgl>       2 0.00000128
#> 19 dupe_flag      <lgl>       2 0.00000128
```

![](../plots/comm_type_bar-1.png)<!-- -->

![](../plots/cont_type_bar-1.png)<!-- -->

![](../plots/method_bar-1.png)<!-- -->

### Continuous

#### Amounts

``` r
summary(inc$amount)
#>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
#> -12301513        15        50       718       250  55452555
mean(inc$amount <= 0)
#> [1] 0.009021655
```

![](../plots/amount_histogram-1.png)<!-- -->

![](../plots/amount_comm_violin-1.png)<!-- -->
