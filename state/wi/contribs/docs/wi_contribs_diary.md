Wisconsin Contributions
================
Kiernan Nicholls & Yanqi Xu
2023-06-07 22:45:33

- <a href="#project" id="toc-project">Project</a>
- <a href="#objectives" id="toc-objectives">Objectives</a>
- <a href="#packages" id="toc-packages">Packages</a>
- <a href="#data" id="toc-data">Data</a>
- <a href="#download" id="toc-download">Download</a>
- <a href="#read" id="toc-read">Read</a>
- <a href="#explore" id="toc-explore">Explore</a>
- <a href="#wrangle" id="toc-wrangle">Wrangle</a>
- <a href="#conclude" id="toc-conclude">Conclude</a>
- <a href="#export" id="toc-export">Export</a>
- <a href="#upload" id="toc-upload">Upload</a>

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
  gluedown, # print markdown
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
#> [1] "/Users/yanqixu/code/accountability_datacleaning"
```

## Data

Data is from the Wisconsin Secretary of State’s Campaign Finance System
(CIFS).

> Wyoming’s Campaign Finance Information System (WYCFIS) exists to
> provide a mechanism for online filing of campaign finance information
> and to provide full disclosure to the public. This website contains
> detailed financial records and related information that candidates,
> committees, organizations and parties are required by law to disclose.

## Download

Using the CIFS [contribution search
portal](https://cfis.wi.gov/Public/Registration.aspx?page=ReceiptList#),
we can run a search for all contributions from “All Filing Periods” from
the dates 2000-01-01 to 2023-06-07. Those search results need to be
manually exported as the `ReceiptsList.csv` file. A total of 8,385,580
entries were generated based on the query accessed on June 4, 2023.

> To view contributions to a committee, go to the CFIS Home Page, on the
> left hand side, and click View Receipts. A pop up letting you know
> that this information cannot be used for solicitation purposes will
> appear – click Continue. Type in a committee’s ID in the field titled
> ID, or start typing the name of the candidate in the Registrant Name
> field and click on the correct committee name when it appears. Type in
> any additional information you would like to search for, including a
> name of a contributor or amount of contribution. To view all
> contributions, remove the filing period by clicking, in the Filing
> Period Name field, and scroll all the way to the top and select All
> Filing Periods. Click Search and all of the contributions fitting your
> search criteria will appear. If you would like to export these into
> Excel, scroll all the way to the bottom and on the right hand side,
> click the XLS icon.

Infuriatingly, the site only lets users export 65,000 records at a time.
I have written a scrip that will use Selenium to open a remote browser,
submit a search for all contributions and download the row-limited files
one by one.

``` r
source(
  file = here("state","wi", "contribs", "docs", "scrape_wi_contribs.R")
)
```

The files are downloaded to the `scrape/` directory.

``` r
raw_dir <- dir_create(here("state","wi", "contribs", "data", "scrape"))
raw_info <- as_tibble(dir_info(raw_dir))
sum(raw_info$size)
#> 1.48G
raw_info %>% 
  select(path, size, modification_time) %>% 
  mutate(across(path, basename))
#> # A tibble: 130 × 3
#>    path                                   size modification_time  
#>    <chr>                           <fs::bytes> <dttm>             
#>  1 wi_contribs_1-65000.csv               13.8M 2023-06-04 20:50:52
#>  2 wi_contribs_1040001-1105000.csv       12.3M 2023-06-06 09:10:40
#>  3 wi_contribs_1105001-1170000.csv       11.2M 2023-06-06 09:14:34
#>  4 wi_contribs_1170001-1235000.csv       10.7M 2023-06-06 09:18:32
#>  5 wi_contribs_1235001-1300000.csv       11.1M 2023-06-06 09:22:31
#>  6 wi_contribs_1300001-1365000.csv       10.5M 2023-06-06 09:42:37
#>  7 wi_contribs_130001-195000.csv           13M 2023-06-04 23:55:59
#>  8 wi_contribs_1365001-1430000.csv       10.9M 2023-06-06 09:46:34
#>  9 wi_contribs_1430001-1495000.csv       11.4M 2023-06-06 09:50:28
#> 10 wi_contribs_1495001-1560000.csv       11.5M 2023-06-06 09:54:24
#> # … with 120 more rows
raw_csv <- raw_info$path
```

We should check the file names to ensure we were able to download every
batch of 65,000. If we count the distance between each of the sorted
numbers in the row ranges we should be left with only 1, 64999, and
however many are in the last range (the only one below 65,000).

``` r
row_range <- raw_csv %>% 
  str_extract(pattern = "(\\d+)-(\\d+)") %>% 
  str_split(pattern = "-") %>% 
  map(as.numeric) %>% 
  unlist() %>% 
  sort() 

sort(table(diff(row_range)))
#> 
#>   579     1 64999 
#>     1   129   129
```

## Read

The files can be read into a single data frame with `read_delim()`.

``` r
wic <- read_delim( # 8,385,580
  file = raw_csv,
  delim = ",",
  escape_double = FALSE,
  escape_backslash = FALSE,
  col_types = cols(
    .default = col_character(),
    TransactionDate = col_date_mdy(),
    ContributionAmount = col_double(),
    ETHCFID = col_integer(),
    `72 Hr. Reports` = col_date_mdy(),
    SegregatedFundFlag = col_logical()
  )
)
```

We can check the number of rows against the total reported by our empty
search. We can also count the number of distinct values from a discrete
column.

``` r
nrow(wic) == 8385580 # check col count
#> [1] TRUE
count(wic, ContributorType) # check distinct col
#> # A tibble: 9 × 2
#>   ContributorType         n
#>   <chr>               <int>
#> 1 Anonymous           20834
#> 2 Business            22150
#> 3 Ethics Commission     152
#> 4 Individual        8212018
#> 5 Local Candidate      3389
#> 6 Registrant          86657
#> 7 Self                13648
#> 8 Unitemized          18521
#> 9 Unregistered         8211
prop_na(wic[[length(wic)]]) # empty column
#> [1] 1
```

The file appears to have been read correctly. We just need to parse,
rename, and remove some of the columns.

``` r
raw_names <- names(wic)[-length(wic)]
```

``` r
wic <- wic %>% 
  clean_names("snake") %>% 
  select(-last_col()) # empty
```

The `contributor_name` columns is in a “LAST FIRST” format, which might
complicate searches on the TAP database. Each name is separated with two
spaces, so we can separate each name into its own column so they can be
properly ordered when mapped in the database.

``` r
name_split <- wic %>% 
  distinct(contributor_name) %>% 
  separate(
    col = contributor_name,
    into = c(
      "contributor_last", 
      "contributor_first"
    ),
    sep = "\\s{2}",
    remove = FALSE,
    extra = "merge",
    fill = "right"
  )
```

``` r
wic <- wic %>% 
  left_join(name_split, by = "contributor_name") %>% 
  relocate(contributor_first, contributor_last, .after = contributor_name) %>%  
  select(-contributor_name)
```

``` r
wic <- mutate(wic, across(where(is.character), str_squish))
```

## Explore

There are 8,385,580 rows of 21 columns. Each record represents a single
contribution from an individual to a political committee.

``` r
glimpse(wic)
#> Rows: 8,385,580
#> Columns: 21
#> $ transaction_date         <date> 2022-12-31, 2022-07-21, 2020-04-14, 2020-04-09, 2020-04-06, 202…
#> $ filing_period_name       <chr> "January Continuing 2023", "September Report 2022", "July Contin…
#> $ contributor_first        <chr> NA, "Becky", "Adrienne", "Thomas", "Anne", "Karla", "Bill", "Dan…
#> $ contributor_last         <chr> "Assembly Democratic Camp Comm", "Stewart", "Widell", "Mallery",…
#> $ contribution_amount      <dbl> 22061.68, 157.00, 100.00, 100.00, 50.00, 1000.00, 100.00, 30.00,…
#> $ address_line1            <chr> "P.O. Box 814", "740 Jacquelyn Dr", "4113 N. Lake Drive", "2299 …
#> $ address_line2            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "Suite 200",…
#> $ city                     <chr> "Madison", "Baraboo", "Shorewood", "Mosinee", "Pewaukee", "Wausa…
#> $ state_code               <chr> "WI", "WI", "WI", "WI", "WI", "WI", "WI", "WI", "WI", "WI", "WI"…
#> $ zip                      <chr> "53701", "53913", "53211", "54455", "53072", "54403", "53092", "…
#> $ occupation               <chr> NA, "Clerical", "Retired", "Retired", NA, "Co-Owner Sun Printing…
#> $ employer_name            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ employer_address         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ contributor_type         <chr> "Registrant", "Individual", "Individual", "Individual", "Individ…
#> $ receiving_committee_name <chr> "Friends Of Steve Doyle", "Democratic Party of Sauk County", "Ju…
#> $ ethcfid                  <int> 101856, 300184, 106123, 106123, 106123, 106123, 106123, 106123, …
#> $ conduit                  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ branch                   <chr> "State Assembly District No. 94", NA, "Milwaukee County Circuit …
#> $ comment                  <chr> NA, "Cash contributions Fair jar", NA, NA, NA, NA, NA, NA, NA, N…
#> $ x72_hr_reports           <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ segregated_fund_flag     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
tail(wic)
#> # A tibble: 6 × 21
#>   transaction…¹ filin…² contr…³ contr…⁴ contr…⁵ addre…⁶ addre…⁷ city  state…⁸ zip   occup…⁹ emplo…˟
#>   <date>        <chr>   <chr>   <chr>     <dbl> <chr>   <chr>   <chr> <chr>   <chr> <chr>   <chr>  
#> 1 2022-03-21    Spring… SARA    ERICKS…    2.34 1015 L… <NA>    WAUN… WI      5359… <NA>    <NA>   
#> 2 2022-03-21    Spring… SHARON… THOMPS…    2.34 2305 H… <NA>    MADI… WI      5372… <NA>    <NA>   
#> 3 2022-03-21    Spring… MELANIE TRAINO…    2.34 7197 H… <NA>    WAUN… WI      5359… <NA>    <NA>   
#> 4 2022-03-21    Spring… STACY E HANKINS    2.34 814 TW… <NA>    MADI… WI      5370… <NA>    <NA>   
#> 5 2022-03-21    Spring… ANGELA… ROBERTS    2.34 N4293 … <NA>    COLU… WI      5392… <NA>    <NA>   
#> 6 2022-03-21    Spring… LORI A  GALLAG…    2.34 6502 B… <NA>    WAUN… WI      5359… <NA>    <NA>   
#> # … with 9 more variables: employer_address <chr>, contributor_type <chr>,
#> #   receiving_committee_name <chr>, ethcfid <int>, conduit <chr>, branch <chr>, comment <chr>,
#> #   x72_hr_reports <date>, segregated_fund_flag <lgl>, and abbreviated variable names
#> #   ¹​transaction_date, ²​filing_period_name, ³​contributor_first, ⁴​contributor_last,
#> #   ⁵​contribution_amount, ⁶​address_line1, ⁷​address_line2, ⁸​state_code, ⁹​occupation, ˟​employer_name
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(wic, count_na)
#> # A tibble: 21 × 4
#>    col                      class        n           p
#>    <chr>                    <chr>    <int>       <dbl>
#>  1 transaction_date         <date>       0 0          
#>  2 filing_period_name       <chr>        0 0          
#>  3 contributor_first        <chr>   156294 0.0186     
#>  4 contributor_last         <chr>        6 0.000000716
#>  5 contribution_amount      <dbl>        0 0          
#>  6 address_line1            <chr>   141356 0.0169     
#>  7 address_line2            <chr>  7932830 0.946      
#>  8 city                     <chr>    77575 0.00925    
#>  9 state_code               <chr>    47124 0.00562    
#> 10 zip                      <chr>   101722 0.0121     
#> 11 occupation               <chr>  6348827 0.757      
#> 12 employer_name            <chr>  7405585 0.883      
#> 13 employer_address         <chr>  7563929 0.902      
#> 14 contributor_type         <chr>        0 0          
#> 15 receiving_committee_name <chr>        0 0          
#> 16 ethcfid                  <int>        0 0          
#> 17 conduit                  <chr>  7856181 0.937      
#> 18 branch                   <chr>  5291869 0.631      
#> 19 comment                  <chr>  6362530 0.759      
#> 20 x72_hr_reports           <date> 8367867 0.998      
#> 21 segregated_fund_flag     <lgl>        0 0
```

We can flag any record missing a key variable needed to identify a
transaction.

``` r
key_vars <- c("transaction_date", "contributor_last", 
              "contribution_amount", "receiving_committee_name")
wic <- flag_na(wic, all_of(key_vars))
sum(wic$na_flag)
#> [1] 6
```

Very, very few records are missing the contributor name.

``` r
wic %>% 
  filter(na_flag) %>% 
  select(all_of(key_vars))
#> # A tibble: 6 × 4
#>   transaction_date contributor_last contribution_amount receiving_committee_name
#>   <date>           <chr>                          <dbl> <chr>                   
#> 1 2008-12-31       <NA>                            84.6 Friends of Shirley Krug 
#> 2 2008-11-30       <NA>                            81.7 Friends of Shirley Krug 
#> 3 2008-10-31       <NA>                            84.3 Friends of Shirley Krug 
#> 4 2008-09-30       <NA>                            77.8 Friends of Shirley Krug 
#> 5 2008-08-31       <NA>                            80.2 Friends of Shirley Krug 
#> 6 2008-07-31       <NA>                            78.2 Friends of Shirley Krug
```

### Duplicates

We can also flag any entirely duplicate rows. To keep memory usage low
with such a large data frame, we will split our data into a list and
check each element of the list. For each chunk, we will write the
duplicate `id` to a text file.

``` r
wic <- wic %>% 
  group_split(
    q = quarter(transaction_date),
    y = year(transaction_date),
    .keep = FALSE
  ) %>% 
  map_dfr(
    .f = function(x) {
      message(x$transaction_date[1])
      if (nrow(x) > 1) {
        x <- flag_dupes(x, everything(), .check = FALSE)
        if (runif(1) > 0.75) {
          flush_memory(1)
        }
      } else {
        x$dupe_flag <- FALSE
      }
      return(x)
    }
  )
```

3.2% of rows are duplicates.

``` r
wic %>% 
  filter(dupe_flag) %>% 
  select(key_vars) %>% 
  arrange(transaction_date)
#> # A tibble: 266,268 × 4
#>    transaction_date contributor_last contribution_amount receiving_committee_name         
#>    <date>           <chr>                          <dbl> <chr>                            
#>  1 2004-09-27       PFAFF                         20000  Pfaff for State Senate           
#>  2 2004-09-27       PFAFF                         20000  Pfaff for State Senate           
#>  3 2004-09-27       PFAFF                         20000  Pfaff for State Senate           
#>  4 2006-12-01       Parker                          220  Greg Parker for District Attorney
#>  5 2006-12-01       Parker                          220  Greg Parker for District Attorney
#>  6 2006-12-28       Jardine                        6486. Jardine for Wisconsin            
#>  7 2006-12-28       Jardine                        6486. Jardine for Wisconsin            
#>  8 2007-01-29       Clair                          3000  Christine Clair for Judge        
#>  9 2007-01-29       Clair                          3000  Christine Clair for Judge        
#> 10 2007-01-31       Hahn                            200  People for Hahn                  
#> # … with 266,258 more rows
```

``` r
wic %>% 
  filter(dupe_flag) %>% 
  count(transaction_date, contributor_last, 
        contribution_amount, receiving_committee_name, 
        sort = TRUE)
#> # A tibble: 109,244 × 5
#>    transaction_date contributor_last    contribution_amount receiving_committee_name              n
#>    <date>           <chr>                             <dbl> <chr>                             <int>
#>  1 2023-04-23       JOHNSON                            2    WEAC PAC                            144
#>  2 2022-05-16       Anonymous                         10    Mueller for Attorney General Com…   130
#>  3 2023-04-23       JOHNSON                            1.67 WEAC PAC                            128
#>  4 2008-10-30       Unitemized                        20    Assembly Democratic Camp Comm       120
#>  5 2022-08-25       Anonymous under $10               10    Leah Spicer for 51st                 93
#>  6 2023-04-23       MILLER                             1.67 WEAC PAC                             88
#>  7 2023-04-23       SMITH                              2    WEAC PAC                             86
#>  8 2023-04-23       SMITH                              1.67 WEAC PAC                             84
#>  9 2023-04-23       ANDERSON                           2    WEAC PAC                             82
#> 10 2023-04-23       ANDERSON                           1.67 WEAC PAC                             76
#> # … with 109,234 more rows
```

### Categorical

``` r
col_stats(wic, n_distinct)
#> # A tibble: 23 × 4
#>    col                      class        n           p
#>    <chr>                    <chr>    <int>       <dbl>
#>  1 transaction_date         <date>    5820 0.000694   
#>  2 filing_period_name       <chr>      173 0.0000206  
#>  3 contributor_first        <chr>   160823 0.0192     
#>  4 contributor_last         <chr>   289869 0.0346     
#>  5 contribution_amount      <dbl>    32053 0.00382    
#>  6 address_line1            <chr>  1529558 0.182      
#>  7 address_line2            <chr>    38632 0.00461    
#>  8 city                     <chr>    38778 0.00462    
#>  9 state_code               <chr>       58 0.00000692 
#> 10 zip                      <chr>   353486 0.0422     
#> 11 occupation               <chr>    88830 0.0106     
#> 12 employer_name            <chr>   126139 0.0150     
#> 13 employer_address         <chr>   222872 0.0266     
#> 14 contributor_type         <chr>        9 0.00000107 
#> 15 receiving_committee_name <chr>     3054 0.000364   
#> 16 ethcfid                  <int>     3061 0.000365   
#> 17 conduit                  <chr>      236 0.0000281  
#> 18 branch                   <chr>      415 0.0000495  
#> 19 comment                  <chr>    87900 0.0105     
#> 20 x72_hr_reports           <date>     946 0.000113   
#> 21 segregated_fund_flag     <lgl>        2 0.000000239
#> 22 na_flag                  <lgl>        2 0.000000239
#> 23 dupe_flag                <lgl>        2 0.000000239
```

![](../plots/distinct-plots-1.png)<!-- -->

### Amounts

``` r
wic$contribution_amount <- round(wic$contribution_amount, digits = 2)
```

``` r
summary(wic$contribution_amount)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>       0       2       8     130      35 3250000
mean(wic$contribution_amount <= 0)
#> [1] 0.002224772
```

These are the records with the minimum and maximum amounts.

``` r
glimpse(wic[c(
  which.max(wic$contribution_amount), 
  which.min(wic$contribution_amount)
), ])
#> Rows: 2
#> Columns: 23
#> $ transaction_date         <date> 2020-02-28, 2007-03-26
#> $ filing_period_name       <chr> "Spring Pre-Election 2020", "July Continuing 2007"
#> $ contributor_first        <chr> NA, "Annette K."
#> $ contributor_last         <chr> "Marsy's Law for All Foundation", "Ziegler"
#> $ contribution_amount      <dbl> 3250000, 0
#> $ address_line1            <chr> "15 Enterprise Suite 550", "PO Box 620066"
#> $ address_line2            <chr> NA, NA
#> $ city                     <chr> "Aliso Viejo", "Middleton"
#> $ state_code               <chr> "CA", "WI"
#> $ zip                      <chr> "92656", "53562"
#> $ occupation               <chr> NA, NA
#> $ employer_name            <chr> NA, NA
#> $ employer_address         <chr> NA, NA
#> $ contributor_type         <chr> "Business", "Self"
#> $ receiving_committee_name <chr> "Marsy's Law for Wisconsin LLC", "Justice Ziegler For Supreme C…
#> $ ethcfid                  <int> 700120, 103567
#> $ conduit                  <chr> NA, NA
#> $ branch                   <chr> NA, "Supreme Court"
#> $ comment                  <chr> NA, "All personal loans were forgiven 10/27/2007 when the commit…
#> $ x72_hr_reports           <date> NA, NA
#> $ segregated_fund_flag     <lgl> FALSE, FALSE
#> $ na_flag                  <lgl> FALSE, FALSE
#> $ dupe_flag                <lgl> FALSE, FALSE
```

![](../plots/hist-amount-1.png)<!-- -->

### Dates

We can add the calendar year from `date` with `lubridate::year()`

``` r
wic <- mutate(wic, transaction_year = year(transaction_date))
```

``` r
min(wic$transaction_date)
#> [1] "1995-12-31"
sum(wic$transaction_year < 2008)
#> [1] 473
max(wic$transaction_date)
#> [1] "2023-05-03"
sum(wic$transaction_date > today())
#> [1] 0
```

![](../plots/bar-year-1.png)<!-- -->

## Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are tailor made to facilitate this process.

### Address

For the street `addresss` variable, the `campfin::normal_address()`
function will force consistence case, remove punctuation, and abbreviate
official USPS suffixes.

``` r
addr_norm <- wic %>% 
  distinct(address_line1, address_line2) %>% 
  mutate(
    across(
      starts_with("address_"),
      list(anorm = normal_address),
      abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  unite(
    col = address_norm,
    ends_with("_anorm"),
    sep = " ",
    remove = TRUE,
    na.rm = TRUE
  )
```

``` r
addr_norm
#> # A tibble: 1,585,934 × 3
#>    address_line1                 address_line2 address_norm               
#>    <chr>                         <chr>         <chr>                      
#>  1 W269 S3244 Merrill Hills Road <NA>          W269 S3244 MERRILL HILLS RD
#>  2 7633 Geralayne Circle         <NA>          7633 GERALAYNE CIR         
#>  3 8819 Whispering Oaks Court    <NA>          8819 WHISPERING OAKS CT    
#>  4 N26779 County Road T          <NA>          N26779 COUNTY ROAD T       
#>  5 3032 Walden Circle            <NA>          3032 WALDEN CIR            
#>  6 2845 North 68th Street        <NA>          2845 NORTH 68TH ST         
#>  7 3033 W. Spencer St.           <NA>          3033 W SPENCER ST          
#>  8 823 East Sunset Avenue        <NA>          823 EAST SUNSET AVE        
#>  9 2520 Settlement Road          <NA>          2520 SETTLEMENT RD         
#> 10 8348 South 68th Street        <NA>          8348 SOUTH 68TH ST         
#> # … with 1,585,924 more rows
```

``` r
wic <- left_join(wic, addr_norm, by = c("address_line1", "address_line2"))
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
wic <- wic %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  wic$zip,
  wic$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 × 6
#>   stage        prop_in n_distinct prop_na   n_out n_diff
#>   <chr>          <dbl>      <dbl>   <dbl>   <dbl>  <dbl>
#> 1 wic$zip        0.696     353486  0.0121 2520996 326432
#> 2 wic$zip_norm   0.998      33649  0.0122   19592   4463
```

### State

``` r
wic$state_code <- str_to_upper(wic$state_code)
prop_in(wic$state_code, valid_state)
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
norm_city <- wic %>% 
  distinct(city, state_code, zip_norm) %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("WI", "DC", "WISCONSIN"),
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
norm_city <- norm_city %>% 
  rename(city_raw = city) %>% 
  left_join(
    y = zipcodes,
    by = c(
      "state_code" = "state",
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

``` r
wic <- left_join(
  x = wic,
  y = norm_city,
  by = c(
    "city" = "city_raw", 
    "state_code", 
    "zip_norm"
  )
)
```

#### Refine

The [OpenRefine](https://openrefine.org/) algorithms can be used to
group similar strings and replace the less common versions with their
most common counterpart. This can greatly reduce inconsistency, but with
low confidence; we will only keep any refined strings that have a valid
city/state/zip combination.

``` r
good_refine <- wic %>% 
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
      "state_code" = "state",
      "zip_norm" = "zip"
    )
  )
```

    #> # A tibble: 411 × 5
    #>    state_code zip_norm city_swap        city_refine         n
    #>    <chr>      <chr>    <chr>            <chr>           <int>
    #>  1 WI         54873    SOLON SPRINGSSS  SOLON SPRINGS      35
    #>  2 WI         54751    MENOMINEE        MENOMONIE          28
    #>  3 WI         53051    MENONOMEE FALLS  MENOMONEE FALLS    25
    #>  4 CA         90292    MARINA DALE REY  MARINA DEL REY     21
    #>  5 WI         54751    MENONOMIE        MENOMONIE          15
    #>  6 WI         53566    MNRO MONROE      MONROE             14
    #>  7 CA         92625    CORONA DALE MAR  CORONA DEL MAR     12
    #>  8 IL         60030    GREYS LAKE       GRAYSLAKE          12
    #>  9 SC         29406    NORTH CHARLESTON CHARLESTON         12
    #> 10 WI         54956    NEEHAN           NEENAH             10
    #> # … with 401 more rows

Then we can join the refined values back to the database.

``` r
wic <- wic %>% 
  left_join(good_refine, by = names(.)) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

Our goal for normalization was to increase the proportion of city values
known to be valid and reduce the total distinct values by correcting
misspellings.

| stage                    | prop_in | n_distinct | prop_na |  n_out | n_diff |
|:-------------------------|--------:|-----------:|--------:|-------:|-------:|
| `str_to_upper(wic$city)` |   0.981 |      27683 |   0.009 | 158161 |  13618 |
| `wic$city_norm`          |   0.986 |      25786 |   0.009 | 116680 |  11695 |
| `wic$city_swap`          |   0.996 |      19072 |   0.009 |  35863 |   4979 |
| `wic$city_refine`        |   0.996 |      18731 |   0.009 |  35114 |   4641 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/bar-progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar-distinct-1.png)<!-- -->

Before exporting, we can remove the intermediary normalization columns
and rename all added variables with the `_clean` suffix.

``` r
wic <- wic %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  rename_all(~str_remove(., "_raw")) %>% 
  relocate(address_clean, city_clean, .before = zip_clean)
```

## Conclude

``` r
glimpse(sample_n(wic, 50))
#> Rows: 50
#> Columns: 27
#> $ transaction_date         <date> 2014-10-23, 2022-03-25, 2014-06-06, 2011-03-17, 2020-01-31, 201…
#> $ filing_period_name       <chr> "January Continuing 2015", "July Continuing 2022", "July Continu…
#> $ contributor_first        <chr> "Sandra", "Gerald D.", "Kathleen M.", "William", "SILVESTRE", "N…
#> $ contributor_last         <chr> "Canter", "Anderson", "Cummings", "Atwood", "ROCHA", "Davidson",…
#> $ contribution_amount      <dbl> 25.00, 2.50, 68.32, 25.00, 0.50, 50.00, 50.00, 50.00, 50.00, 5.0…
#> $ address_line1            <chr> "3100 dona Susana Dr.", "9199 N. Bethanne Drive", "1325 East Rob…
#> $ address_line2            <chr> NA, NA, NA, NA, "1717 FRANKLIN ST", NA, NA, NA, "418 E Main St",…
#> $ city                     <chr> "Studio City", "Brown Deer", "Waukesha", "Christiansburg", "RACI…
#> $ state_code               <chr> "CA", "WI", "WI", "VA", "WI", "DE", "WI", "TX", "WI", "WI", "WI"…
#> $ zip                      <chr> "91604", "53223", "53186", "24073", "53403", "19947", "53129", "…
#> $ occupation               <chr> NA, "SCIENCE & TECHNOLOGY - UTILITIES", NA, "TEACHER", NA, "RETI…
#> $ employer_name            <chr> NA, NA, NA, "Pulaski County Public Schools", NA, NA, NA, NA, NA,…
#> $ employer_address         <chr> NA, NA, NA, "500 Pico Terrace Pulaski VA 24301", NA, NA, NA, NA,…
#> $ contributor_type         <chr> "Individual", "Individual", "Self", "Individual", "Individual", …
#> $ receiving_committee_name <chr> "Burke for Wisconsin", "WEC Energy Group PAC (WEC PAC)", "Commit…
#> $ ethcfid                  <int> 105459, 500313, 104049, 300054, 500394, 102575, 106544, 102575, …
#> $ conduit                  <chr> NA, NA, NA, "ActBlue Wisconsin", NA, NA, NA, NA, NA, "Kwik Trip …
#> $ branch                   <chr> "Governor", NA, "State Assembly District No. 97", NA, NA, "Gover…
#> $ comment                  <chr> NA, NA, "Candidate used personal funds for Thomas Press Invoice …
#> $ x72_hr_reports           <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ segregated_fund_flag     <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ na_flag                  <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ dupe_flag                <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ transaction_year         <dbl> 2014, 2022, 2014, 2011, 2020, 2015, 2022, 2012, 2020, 2010, 2021…
#> $ address_clean            <chr> "3100 DONA SUSANA DR", "9199 N BETHANNE DR", "1325 EAST ROBERTA …
#> $ city_clean               <chr> "STUDIO CITY", "BROWN DEER", "WAUKESHA", "CHRISTIANSBURG", "RACI…
#> $ zip_clean                <chr> "91604", "53223", "53186", "24073", "53403", "19947", "53129", "…
```

1.  There are 8,385,586 records in the database.
2.  There are 266,274 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 6 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("state","wi", "contribs", "data", "clean"))
clean_path <- path(clean_dir, "wi_contribs_2008-20230604.csv")
write_csv(wic, clean_path, na = "")
(clean_size <- file_size(clean_path))
#> 1.82G
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
