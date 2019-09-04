Pennsylvania Campaign Expenditures Data Diary
================
Yanqi Xu
2019-09-04 13:17:55

-   [Project](#project)
-   [Objectives](#objectives)
-   [Packages](#packages)
-   [Data](#data)
-   [Import](#import)
-   [Explore](#explore)
-   [Wrangle](#wrangle)
-   [Conclude](#conclude)
-   [Export](#export)

Project
-------

The Accountability Project is an effort to cut across data silos and give journalists, policy professionals, activists, and the public at large a simple way to search across huge volumes of public data about people and organizations.

Our goal is to standardizing public data on a few key fields by thinking of each dataset row as a transaction. For each transaction there should be (at least) 3 variables:

1.  All **parties** to a transaction
2.  The **date** of the transaction
3.  The **amount** of money involved

Objectives
----------

This document describes the process used to complete the following objectives:

1.  How many records are in the database?
2.  Check for duplicates
3.  Check ranges
4.  Is there anything blank or missing?
5.  Check for consistency issues
6.  Create a five-digit ZIP Code called `ZIP5`
7.  Create a `YEAR` field from the transaction date
8.  Make sure there is data on both parties to a transaction

Packages
--------

The following packages are needed to collect, manipulate, visualize, analyze, and communicate these results. The `pacman` package will facilitate their installation and attachment.

``` r
if (!require("pacman")) install.packages("pacman")
pacman::p_load_current_gh("kiernann/campfin")
pacman::p_load(
  stringdist, # levenshtein value
  tidyverse, # data manipulation
  lubridate, # datetime strings
  tidytext, # string analysis
  magrittr, # pipe opperators
  janitor, # dataframe clean
  zipcode, # clean & database
  refinr, # cluster and merge
  knitr, # knit documents
  glue, # combine strings
  scales, #format strings
  here, # relative storage
  fs, # search storage 
  vroom, #read deliminated files
  fuzzyjoin #fuzzy-join 
)
```

This document should be run as part of the `R_campfin` project, which lives as a sub-directory of the more general, language-agnostic [`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning "TAP repo") GitHub repository.

The `R_campfin` project uses the [RStudio projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects "Rproj") feature and should be run as such. The project also uses the dynamic `here::here()` tool for file paths relative to *your* machine.

``` r
# where dfs this document knit?
here::here()
#> [1] "/Users/soc/accountability/accountability_datacleaning/R_campfin"
```

Data
----

### About

More information about the record layout can be found here <https://www.dos.pa.gov/VotingElections/CandidatesCommittees/CampaignFinance/Resources/Documents/readme.txt>.

### Variables

Import
------

### Download

Download raw, **immutable** data file. Go to <https://www.dos.pa.gov/VotingElections/CandidatesCommittees/CampaignFinance/Resources/Pages/FullCampaignFinanceExport.aspx>. We'll download the files from 2015 to 2019 (file format: zip file) with the script.

``` r
# create a directory for the raw data
raw_dir <- here("pa", "expends", "data", "raw")
dir_create(raw_dir)
```

Download all the file packages containing all campaign-finance-related files.

``` r
#download the files into the directory
pa_exp_urls <- glue("https://www.dos.pa.gov//VotingElections/CandidatesCommittees/CampaignFinance/Resources/Documents/{2015:2019}.zip")

if (!all_files_new(raw_dir)) {
  for (url in pa_exp_urls) {
    download.file(
      url = url,
      destfile = glue("{raw_dir}/{basename(url)}")
    )
  }
}
```

### Read

Read individual csv files from the downloaded zip files

``` r
zip_files <- dir_ls(raw_dir, glob = "*.zip")

if (all_files_new(path = raw_dir, glob = "*.txt")) {
  for (i in seq_along(zip_files)) {
    unzip(
      zipfile = zip_files[i],
      #Matches the csv files that starts with expense, and trim the "./ " from directory names
      files = grep("expense.+", unzip(zip_files[i]), value = TRUE) %>% substring(3,),
      exdir = raw_dir
    )
  }
}
```

Read multiple csvs into R

``` r
#recursive set to true because 2016 and 2015 have subdirectories under "raw"
expense_files <- list.files(raw_dir, pattern = ".txt", recursive = TRUE, full.names = TRUE)
#pa_lines <- list.files(raw_dir, pattern = ".txt", recursive = TRUE) %>% map(read_lines) %>% unlist()
pa_col_names <- c("FILERID","EYEAR","CYCLE","EXPNAME","ADDRESS1","ADDRESS2","CITY","STATE","ZIPCODE","EXPDATE","EXPAMT","EXPDESC")


pa <- expense_files %>% 
  map(read_delim, delim = ",", escape_double = FALSE,
      escape_backslash = FALSE, col_names = pa_col_names, 
      col_types = cols(.default = col_character())) %>% 
bind_rows()
```

There are 4 parsing failures. We'll move along the information in rows that were read incorrectly due to double quotes in the address column.

``` r
nudge <- which(nchar(pa$STATE) > 2)
# However, the information in the last column EXPDESC for these columns has been lost at the time of data import.
for (index in nudge) {
  for (column in c(7:11)){
    pa[[index, column]] <- pa[[index, column+1]]
  }
}
#All the fields are converted to strings. Convert to date and double.
pa$EXPDATE <- as.Date(pa$EXPDATE, "%Y%m%d")
pa$EXPAMT <- as.double(pa$EXPAMT)
pa$ADDRESS1 <- normal_address(pa$ADDRESS1)
pa$ADDRESS2 <- normal_address(pa$ADDRESS2)
```

The text fields contain both lower-case and upper-case letters. The for loop converts them to all upper-case letters unifies the encoding to "UTF-8", replaces the "&", the HTML expression of "An ampersand".

``` r
for (i in c(4:7)) {
  pa[[i]] <- iconv(pa[[i]], 'UTF-8', 'ASCII') %>% 
    toupper() %>% 
   str_replace("&AMP;", "&") 
}

pa$EXPDESC <- toupper(pa$EXPDESC)
```

Explore
-------

There are `nrow(pa)` records of `length(pa)` variables in the full database.

``` r
head(pa)
```

    #> # A tibble: 6 x 12
    #>   FILERID  EYEAR CYCLE EXPNAME    ADDRESS1   ADDRESS2 CITY  STATE ZIPCODE EXPDATE    EXPAMT EXPDESC
    #>   <chr>    <chr> <chr> <chr>      <chr>      <chr>    <chr> <chr> <chr>   <date>      <dbl> <chr>  
    #> 1 20140199 2015  2     VALLEY DE… 1321 FREE… <NA>     CHES… PA    15024   2015-02-16  250   DONATI…
    #> 2 20140199 2015  2     OFFICE MAX 4080 WILA… <NA>     MONR… PA    15146   2015-02-18   16.6 OFFICE…
    #> 3 20140199 2015  2     GATEWAY C… PARKING    <NA>     PITT… PA    15222   2015-02-18   20   PARKING
    #> 4 20140199 2015  2     USPS       KILBUCK    <NA>     PITT… PA    15290   2015-02-18  980   POSTAGE
    #> 5 20140199 2015  2     EDDIE MER… GATEWAY C… <NA>     PITT… PA    15222   2015-02-18  102.  CAMPAI…
    #> 6 20140199 2015  2     CASTLE SH… CO EILEEN… <NA>     PITT… PA    15234   2015-02-23  100   DONATI…

``` r
tail(pa)
```

    #> # A tibble: 6 x 12
    #>   FILERID  EYEAR CYCLE EXPNAME  ADDRESS1  ADDRESS2 CITY  STATE ZIPCODE EXPDATE    EXPAMT EXPDESC   
    #>   <chr>    <chr> <chr> <chr>    <chr>     <chr>    <chr> <chr> <chr>   <date>      <dbl> <chr>     
    #> 1 2019C02… 2019  2     VISTA P… 95 HAYDE… <NA>     LEXI… MA    02421   2019-03-17   36.0 PRINTING …
    #> 2 2019C02… 2019  2     VISTA P… 95 HAYDE… <NA>     LEXI… MA    02421   2019-03-28   36.3 PRINTED C…
    #> 3 20190018 2019  1     VISTA P… 95 HAYDE… <NA>     LEXI… MA    02421   2019-01-29  121.  CAMPAIGN …
    #> 4 2019C02… 2019  2     VISTA P… ONLINE    <NA>     <NA>  <NA>  <NA>    2019-04-30  604.  5.5 X 8.5…
    #> 5 2019C02… 2019  2     VISTA P… ONLINE    <NA>     <NA>  <NA>  <NA>    2019-05-01  165.  4X6 POSTC…
    #> 6 20170137 2019  2     VISTA P… ONLINE    <NA>     <NA>  <NA>  <NA>    2019-05-01  165.  4X6 POSTC…

``` r
glimpse(pa)
```

    #> Observations: 493,025
    #> Variables: 12
    #> $ FILERID  <chr> "20140199", "20140199", "20140199", "20140199", "20140199", "20140199", "201401…
    #> $ EYEAR    <chr> "2015", "2015", "2015", "2015", "2015", "2015", "2015", "2015", "2015", "2015",…
    #> $ CYCLE    <chr> "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2",…
    #> $ EXPNAME  <chr> "VALLEY DEMOCRATIC COMM", "OFFICE MAX", "GATEWAY CENTER", "USPS", "EDDIE MERIOT…
    #> $ ADDRESS1 <chr> "1321 FREEPORT RD", "4080 WILAM PENN HIGHWAY", "PARKING", "KILBUCK", "GATEWAY C…
    #> $ ADDRESS2 <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
    #> $ CITY     <chr> "CHESWICK", "MONROEVILLE", "PITTSBURGH", "PITTSBURGH", "PITTSBURGH", "PITTSBURG…
    #> $ STATE    <chr> "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "…
    #> $ ZIPCODE  <chr> "15024", "15146", "15222", "15290", "15222", "15234", "15219", "15209", "15045"…
    #> $ EXPDATE  <date> 2015-02-16, 2015-02-18, 2015-02-18, 2015-02-18, 2015-02-18, 2015-02-23, 2015-0…
    #> $ EXPAMT   <dbl> 250.00, 16.63, 20.00, 980.00, 101.53, 100.00, 1000.00, 100.00, 100.00, 68.00, 6…
    #> $ EXPDESC  <chr> "DONATION", "OFFICE SUPPLIES", "PARKING", "POSTAGE", "CAMPAIGN - MEAL", "DONATI…

### Distinct

The variables range in their degree of distinctness.

``` r
pa %>% glimpse_fun(n_distinct)
```

    #> # A tibble: 12 x 4
    #>    var      type       n         p
    #>    <chr>    <chr>  <int>     <dbl>
    #>  1 FILERID  chr     4137 0.00839  
    #>  2 EYEAR    chr        7 0.0000142
    #>  3 CYCLE    chr        9 0.0000183
    #>  4 EXPNAME  chr   101285 0.205    
    #>  5 ADDRESS1 chr    94272 0.191    
    #>  6 ADDRESS2 chr     4412 0.00895  
    #>  7 CITY     chr     6218 0.0126   
    #>  8 STATE    chr       56 0.000114 
    #>  9 ZIPCODE  chr    20786 0.0422   
    #> 10 EXPDATE  date    1820 0.00369  
    #> 11 EXPAMT   dbl    66564 0.135    
    #> 12 EXPDESC  chr    79862 0.162

### Missing

The variables also vary in their degree of values that are `NA` (missing).

``` r
pa %>% glimpse_fun(count_na)
```

    #> # A tibble: 12 x 4
    #>    var      type       n        p
    #>    <chr>    <chr>  <int>    <dbl>
    #>  1 FILERID  chr        0 0       
    #>  2 EYEAR    chr        0 0       
    #>  3 CYCLE    chr        0 0       
    #>  4 EXPNAME  chr      124 0.000252
    #>  5 ADDRESS1 chr    14918 0.0303  
    #>  6 ADDRESS2 chr   457826 0.929   
    #>  7 CITY     chr    11556 0.0234  
    #>  8 STATE    chr    11015 0.0223  
    #>  9 ZIPCODE  chr    15654 0.0318  
    #> 10 EXPDATE  date    1450 0.00294 
    #> 11 EXPAMT   dbl        0 0       
    #> 12 EXPDESC  chr     9492 0.0193

We will flag any records with missing values in the key variables used to identify an expenditure. There are 0 elements that are flagged as missing at least one value.

``` r
pa <- pa %>% flag_na(EXPNAME, EXPDATE, EXPDESC, EXPAMT, CITY)
```

### Duplicates

``` r
pa <- flag_dupes(pa, dplyr::everything())
sum(pa$dupe_flag)
#> [1] 6999
```

### Ranges

#### Amounts

``` r
summary(pa$EXPAMT)
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#>   -67500       60      250     2613      752 12147387
sum(pa$EXPAMT < 0 , na.rm = TRUE)
#> [1] 538
```

See how the campaign expenditures were distributed

``` r
pa %>% 
  ggplot(aes(x = EXPAMT)) + 
  geom_histogram() +
  scale_x_continuous(
    trans = "log10", labels = dollar)
```

![](../plots/amount%20distribution-1.png)

Expenditures out of state

``` r
sum(pa$STATE != "PA", na.rm = TRUE)
```

    #> [1] 78926

Top spending purposes ![](../plots/unnamed-chunk-5-1.png)

### Dates

Some of the dates are too far back and some are past the current dates.

``` r
summary(pa$EXPDATE)
```

    #>         Min.      1st Qu.       Median         Mean      3rd Qu.         Max.         NA's 
    #> "1825-04-20" "2016-03-01" "2017-04-08" "2017-04-02" "2018-05-15" "5018-09-15"       "1450"

### Year

Add a `year` variable from `date` after `col_date()` using `lubridate::year()`.

``` r
pa <- pa %>% mutate(year = year(EXPDATE), on_year = is_even(year))
```

Turn some year and date values to NAs.

``` r
pa <- pa %>% mutate(date_flag = year < 2000 | year > format(Sys.Date(), "%Y"), 
                    date_clean = ifelse(
                    date_flag, NA, EXPDATE),
                    year_clean = ifelse(
                    date_flag, NA, year))
```

![](../plots/year_count_bar-1.png)

![](../plots/amount_year_bar-1.png)

![](../plots/amount_month_line-1.png)

``` r
pa %>% group_by(EXPDESC) %>% summarize(total = sum(EXPAMT)) %>% arrange(desc(total))
```

    #> # A tibble: 79,862 x 2
    #>    EXPDESC                                       total
    #>    <chr>                                         <dbl>
    #>  1 <NA>                                     266672765.
    #>  2 CONTRIBUTION                             185395743.
    #>  3 NON PA DISBURSEMENTS                      95018717.
    #>  4 DONATION                                  26623333.
    #>  5 MEDIA BUY                                 26199723.
    #>  6 NON-PENNSYLVANIA EXPENDITURES             21187323.
    #>  7 POLITICAL CONTRIBUTION                    15977415.
    #>  8 BALANCE OF DISBURSEMENTS FROM FEC REPORT  15574849.
    #>  9 AD BUY                                    15494933.
    #> 10 CAMPAIGN CONTRIBUTION                     14995155.
    #> # … with 79,852 more rows

Wrangle
-------

The state column is now pretty clean, as all non-NA columns have two characters.

### Indexing

``` r
pa <- tibble::rowid_to_column(pa, "index")
```

### Zipcode

The Zipcode column can range from 1 to 13 columns.

``` r
table(nchar(pa$ZIPCODE))
#> 
#>      1      2      3      4      5      6      7      8      9     10     13 
#>     11     33    114    309 389524    783     26    118  84633   1818      2
```

``` r
pa <- pa %>% 
  mutate(
    zip_clean = ZIPCODE %>% 
      normal_zip(na_rep = TRUE))
sample(pa$zip_clean, 10)
#>  [1] "19146" "16823" "17101" "15238" "98108" "18052" "15501" "19110" "15824" "19012"
```

### State

View values in the STATE field is not a valid state abbreviation

``` r
{pa$STATE[pa$STATE %out% zipcode$state]}[!is.na(pa$STATE[pa$STATE %out% zipcode$state])]
#> [1] "CN" "CN" "CN" "CN"

pa %>% filter(STATE == "CN")
#> # A tibble: 4 x 21
#>    index FILERID EYEAR CYCLE EXPNAME ADDRESS1 ADDRESS2 CITY  STATE ZIPCODE EXPDATE    EXPAMT
#>    <int> <chr>   <chr> <chr> <chr>   <chr>    <chr>    <chr> <chr> <chr>   <date>      <dbl>
#> 1   3445 7900257 2015  1     CSA BA… 1500 NO… <NA>     QUEB… CN    J4B 5H3 2015-03-18   5.11
#> 2   3446 7900257 2015  1     CSA BA… 1500 NO… <NA>     QUEB… CN    J4B 5H3 2015-03-18 511.  
#> 3 296601 201700… 2017  6     ISTOCK  1240 20… <NA>     CALG… CN    00000   2017-10-27  35.0 
#> 4 400304 2009450 2018  6     HOOTSU… 5 EAST … <NA>     VANC… CN    V5T 1R6 2018-10-31  47.7 
#> # … with 9 more variables: EXPDESC <chr>, na_flag <lgl>, dupe_flag <lgl>, year <dbl>,
#> #   on_year <lgl>, date_flag <lgl>, date_clean <dbl>, year_clean <dbl>, zip_clean <chr>
```

These are expenditures in Canada, which we can leave in. \#\#\# City

Cleaning city values is the most complicated. This process involves four steps:

1.  Prepare raw city values by removing invalid data and reducing inconsistencies
2.  Match prepared city values with the *actual* city name of that record's ZIP code
3.  swap prepared city values with the ZIP code match *if* only 1 edit is needed
4.  Refine swapped city values with key collision and n-gram fingerprints

#### Prep

481469 distinct cities were in the original dataset in column

``` r
pa <- pa %>% mutate(city_prep = normal_city(city = CITY,
                                            geo_abbs = usps_city,
                                            st_abbs = c(valid_state),
                                            na = invalid_city,
                                            na_rep = TRUE))
n_distinct(pa$city_prep)
#> [1] 5760
```

#### Match

``` r
pa <- pa %>%
  left_join(
    y = zipcode,
    by = c(
      "zip_clean" = "zip",
      "STATE" = "state"
    )
  ) %>% 
  rename(city_match = city)
```

#### Swap

To replace city names with expected city names from zipcode when the two variables are no more than two characters different

``` r
pa <- pa %>% 
  mutate(
    match_dist = stringdist(city_prep, city_match),
    city_swap = if_else(condition = is.na(city_match) == FALSE,
                        if_else(
      condition = match_dist <= 2,
      true = city_match,
      false = city_prep
    ),
      false = city_prep
  ))


summary(pa$match_dist)
```

    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
    #>   0.000   0.000   0.000   0.583   0.000  22.000   20605

``` r
sum(pa$match_dist == 1, na.rm = TRUE)
```

    #> [1] 5073

``` r
n_distinct(pa$city_swap)
```

    #> [1] 4349

#### Refine

``` r
valid_city <- campfin::valid_city
```

Use the OpenRefine algorithms to cluster similar values and merge them together. This can be done using the refinr::key\_collision\_merge() and refinr::n\_gram\_merge() functions on our prepared and swapped city data.

``` r
pa_refined <- pa %>%
  filter(match_dist != 1) %>% 
  filter(STATE =="PA") %>% 
  mutate(
    city_refine = city_swap %>% 
      key_collision_merge(dict = valid_city) %>% 
      n_gram_merge(numgram = 2),
    refined = (city_swap != city_refine)
  ) %>% 
  filter(refined) %>% 
  select(
    index,
    FILERID, 
    CITY,
    city_prep,
    city_match,
    city_swap,
    match_dist,
    city_refine,
    STATE, 
    ZIPCODE,
    zip_clean
  )

pa_refined %>% 
  count(city_swap, city_refine) %>% 
  arrange(desc(n))
```

    #> # A tibble: 81 x 3
    #>    city_swap        city_refine      n
    #>    <chr>            <chr>        <int>
    #>  1 GREENVILLE       E GREENVILLE   322
    #>  2 W NEWTON         NEWTOWN        310
    #>  3 N HUNTINGDON     HUNTINGDON     128
    #>  4 BERLIN           E BERLIN        72
    #>  5 W LAWN           LAWN            46
    #>  6 E MCKEESPORT     MCKEESPORT      29
    #>  7 E FREEDOM        FREEDOM         26
    #>  8 SINKING SPGS     SINKING SPG     23
    #>  9 SOUTHERN EASTERN SOUTHEASTERN    18
    #> 10 E WATERFORD      WATERFORD       15
    #> # … with 71 more rows

``` r
refined_values <- unique(pa_refined$city_refine)
count_refined <- tibble(
  city_refine = refined_values, 
  refine_count = NA
)

for (i in seq_along(refined_values)) {
  count_refined$refine_count[i] <- sum(str_detect(pa$city_swap, refined_values[i]), na.rm = TRUE)
}

swap_values <- unique(pa_refined$city_swap)
count_swap <- tibble(
  city_swap = swap_values, 
  swap_count = NA
)

for (i in seq_along(swap_values)) {
  count_swap$swap_count[i] <- sum(str_detect(pa$city_swap, swap_values[i]), na.rm = TRUE)
}

pa_refined %>% 
  left_join(count_swap) %>% 
  left_join(count_refined) %>%
  select(
    FILERID,
    city_match,
    city_swap,
    city_refine,
    swap_count,
    refine_count
  ) %>% 
  mutate(diff_count = refine_count - swap_count) %>%
  mutate(refine_dist = stringdist(city_swap, city_refine)) %>%
  distinct() %>%
  arrange(city_refine) %>% 
  print_all()
```

    #> # A tibble: 377 x 8
    #>     FILERID  city_match   city_swap    city_refine   swap_count refine_count diff_count refine_dist
    #>     <chr>    <chr>        <chr>        <chr>              <int>        <int>      <int>       <dbl>
    #>   1 2002093  PITTSBURGH   ADDRESSON F… ADDRESS ON F…          1           26         25           1
    #>   2 9500250  BRIDGEVILLE  ALISON PRK   ALLISON PRK            1          321        320           1
    #>   3 7900321  PITTSTON     AVOCO        AVOCA                  1          501        500           1
    #>   4 20170352 WILKES BARRE BEARCREEK    BEAR CREEK             1           10          9           1
    #>   5 8100217  MARCUS HOOK  BOOTHWYNN    BOOTHWYN               1          184        183           1
    #>   6 2017C01… HARRISBURG   BRESLER      BRESSLER               1           63         62           1
    #>   7 20130207 NEWTOWN SQU… BROMALL      BROOMALL               4          407        403           1
    #>   8 20150282 NEWTOWN SQU… BROMALL      BROOMALL               4          407        403           1
    #>   9 2000115  E BUTLER     E BUTLER     BUTLER                 4         1335       1331           2
    #>  10 20170314 S LONDONDER… CARSLISLE    CARLISLE               4          689        685           1
    #>  11 8900208  BROCKWAY     DUBOIS       DU BOIS                7          430        423           1
    #>  12 20170387 SCRANTON     DUNMMORE     DUNMORE                1          454        453           1
    #>  13 2002291  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  14 8000638  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  15 20150034 BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  16 2015C03… BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  17 20150080 BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  18 2000169  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  19 7900405  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  20 20150062 BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  21 2008133  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  22 8000674  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  23 9000335  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  24 9200347  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  25 2007003  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  26 7900321  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  27 20140023 BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  28 20140116 BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  29 2010377  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  30 9300188  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  31 8400378  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  32 7900442  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  33 7900337  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  34 8200616  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  35 8800219  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  36 8600110  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  37 2001148  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  38 9100045  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  39 7900366  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  40 9000307  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  41 2000081  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  42 9700250  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  43 8500209  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  44 2002077  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  45 7900264  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  46 7900364  BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  47 20180088 BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  48 8000674  SOMERSET     BERLIN       E BERLIN             233          106       -127           2
    #>  49 20150366 BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  50 20130289 BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  51 20180136 BERLIN       BERLIN       E BERLIN             233          106       -127           2
    #>  52 20150020 GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  53 9000319  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  54 20140414 GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  55 20150067 GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  56 2005203  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  57 9700164  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  58 9500042  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  59 8600238  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  60 8000367  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  61 9500250  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  62 2015C04… GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  63 2015C04… MERCER       GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  64 2006340  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  65 9000035  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  66 20140300 GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  67 2007049  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  68 8200157  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  69 9100286  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  70 7900504  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  71 2009450  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  72 20110252 GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  73 20140099 GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  74 2016C01… GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  75 7900443  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  76 8600109  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  77 9400239  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  78 7900369  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  79 2002017  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  80 7900444  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  81 2002152  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  82 2000081  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  83 7900403  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  84 7900366  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  85 8000121  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  86 2002121  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  87 2011139  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  88 2007224  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  89 2008225  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  90 2002077  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  91 2004106  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  92 20140001 GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  93 2000127  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  94 9900209  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  95 8200085  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  96 2003193  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  97 2016C12… GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  98 9000307  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #>  99 7900500  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 100 20170105 GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 101 20160149 GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 102 8300175  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 103 8600316  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 104 9400126  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 105 2004037  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 106 2000115  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 107 20170192 GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 108 8200278  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 109 8400088  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 110 9900137  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 111 20180094 GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 112 20150154 GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 113 2005249  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 114 2008336  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 115 2003196  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 116 2008026  NEW CASTLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 117 2002358  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 118 2018C04… GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 119 2001144  GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 120 2019C01… GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 121 2019C00… GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 122 20190022 GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 123 2019C02… GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 124 20190017 GREENVILLE   GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 125 9000319  MERCER       GREENVILLE   E GREENVILLE         658          328       -330           2
    #> 126 20130154 PETERSBURG   PETERSBURG   E PETERSBURG         273          193        -80           2
    #> 127 2005249  PETERSBURG   PETERSBURG   E PETERSBURG         273          193        -80           2
    #> 128 7900374  PETERSBURG   PETERSBURG   E PETERSBURG         273          193        -80           2
    #> 129 2008219  SOUTHEASTERN S EASTON     EASTON                 7         1034       1027           2
    #> 130 8300005  SOUTHEASTERN S EASTON     EASTON                 7         1034       1027           2
    #> 131 8300005  WESTTOWN     S EASTON     EASTON                 7         1034       1027           2
    #> 132 7900243  CRUM LYNNE   EDDYSTON     EDDYSTONE             38           31         -7           1
    #> 133 2010095  LEVITTOWN    FALSINGTON   FALLSINGTON            1           57         56           1
    #> 134 20180378 LEVITTOWN    FALSSINGTON  FALLSINGTON            1           57         56           1
    #> 135 8100217  KINGSTON     FORTY FORTY  FORTY FT               1           29         28           3
    #> 136 20130305 E FREEDOM    E FREEDOM    FREEDOM               26          105         79           2
    #> 137 8000635  E FREEDOM    E FREEDOM    FREEDOM               26          105         79           2
    #> 138 2015C01… E FREEDOM    E FREEDOM    FREEDOM               26          105         79           2
    #> 139 7900383  E FREEDOM    E FREEDOM    FREEDOM               26          105         79           2
    #> 140 7900139  E FREEDOM    E FREEDOM    FREEDOM               26          105         79           2
    #> 141 20160351 E FREEDOM    E FREEDOM    FREEDOM               26          105         79           2
    #> 142 2018C08… E FREEDOM    E FREEDOM    FREEDOM               26          105         79           2
    #> 143 20180045 E FREEDOM    E FREEDOM    FREEDOM               26          105         79           2
    #> 144 20170318 E FREEDOM    E FREEDOM    FREEDOM               26          105         79           2
    #> 145 2005249  E FREEDOM    E FREEDOM    FREEDOM               26          105         79           2
    #> 146 8100217  GLN LYON     GLN OLDEN    GLENOLDEN              1          334        333           2
    #> 147 9600227  CARBONDALE   GREENFIELD … GREENFIELD T…          1           21         20           1
    #> 148 2004037  HARRISBURG   W HANOVER T… HANOVER TOWN…          2           41         39           2
    #> 149 20150043 HARRISBURG   W HANOVER T… HANOVER TOWN…          2           41         39           2
    #> 150 9000060  HARRISBURG   W HANOVER T… HANOVER TWP            1           28         27           2
    #> 151 9500133  SOUTHAMPTON  HOLAND       HOLLAND                1          343        342           1
    #> 152 7900134  DUNCANSVILLE HOLIDAYSBURG HOLLIDAYSBURG          5          599        594           1
    #> 153 7900366  IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 154 20140462 IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 155 20150064 IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 156 2008336  IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 157 2010427  IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 158 20140416 IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 159 2015C01… IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 160 2004105  IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 161 20140421 IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 162 20150064 JEANNETTE    N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 163 20120153 IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 164 20150284 IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 165 2008336  LATROBE      N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 166 2008047  IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 167 20160071 IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 168 20170100 IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 169 2010444  IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 170 20170320 IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 171 20160359 IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 172 2010389  IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 173 20180122 IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 174 2005249  IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 175 20180085 IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 176 20180097 MCKEESPORT   N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 177 7900079  IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 178 20180097 IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 179 20180374 IRWIN        N HUNTINGDON HUNTINGDON           129          762        633           2
    #> 180 2002171  NORRISTOWN   JEFFERSONVI… JEFFERSONVIL…          2          310        308           1
    #> 181 2006168  NORRISTOWN   JEFFERSONVI… JEFFERSONVIL…          2          310        308           1
    #> 182 7900259  LANCASTER    LANCASTERTER LANCASTER              1         5607       5606           3
    #> 183 2015C02… READING      W LAWN       LAWN                  46          198        152           2
    #> 184 20150015 READING      W LAWN       LAWN                  46          198        152           2
    #> 185 20150078 READING      W LAWN       LAWN                  46          198        152           2
    #> 186 20140445 READING      W LAWN       LAWN                  46          198        152           2
    #> 187 9000335  READING      W LAWN       LAWN                  46          198        152           2
    #> 188 7900405  READING      W LAWN       LAWN                  46          198        152           2
    #> 189 7900263  READING      W LAWN       LAWN                  46          198        152           2
    #> 190 20140117 READING      W LAWN       LAWN                  46          198        152           2
    #> 191 8100246  READING      W LAWN       LAWN                  46          198        152           2
    #> 192 9700164  READING      W LAWN       LAWN                  46          198        152           2
    #> 193 8300256  READING      W LAWN       LAWN                  46          198        152           2
    #> 194 2000081  READING      W LAWN       LAWN                  46          198        152           2
    #> 195 9100219  READING      W LAWN       LAWN                  46          198        152           2
    #> 196 9500243  READING      W LAWN       LAWN                  46          198        152           2
    #> 197 2006014  READING      W LAWN       LAWN                  46          198        152           2
    #> 198 7900442  READING      W LAWN       LAWN                  46          198        152           2
    #> 199 2018C07… READING      W LAWN       LAWN                  46          198        152           2
    #> 200 2006211  READING      W LAWN       LAWN                  46          198        152           2
    #> 201 8600281  READING      W LAWN       LAWN                  46          198        152           2
    #> 202 20150020 PITTSBURGH   E LIBERTY    LIBERTY                2           24         22           2
    #> 203 2002072  NEW KENSING… LOWER BURER… LOWER BURRELL          1           74         73           1
    #> 204 9600321  AMBLER       LOWER GWYNE… LOWER GWYNEDD          3          109        106           1
    #> 205 9800210  PITTSBURGH   MC CANDLESS  MCCANDLESS             1            8          7           1
    #> 206 8200038  MCCONNELLSB… MC CBG       MCCBG                  2           18         16           1
    #> 207 7900343  MCCONNELLSB… MC BG        MCCBG                 13           18          5           1
    #> 208 7900343  FT LITTLETON MC BG        MCCBG                 13           18          5           1
    #> 209 7900343  MARION       MC BG        MCCBG                 13           18          5           1
    #> 210 7900343  NEEDMORE     MC CONNELLS… MCCONNELLSBU…          3          209        206           1
    #> 211 7900343  MARION       MC CONNELLS… MCCONNELLSBU…          3          209        206           1
    #> 212 7900343  SALTILLO     MC CONNELLS… MCCONNELLSBU…          3          209        206           1
    #> 213 2010389  E MCKEESPORT E MCKEESPORT MCKEESPORT            30         1280       1250           2
    #> 214 9500250  E MCKEESPORT E MCKEESPORT MCKEESPORT            30         1280       1250           2
    #> 215 20140199 FREDERICKTO… E MCKEESPORT MCKEESPORT            30         1280       1250           2
    #> 216 9800084  E MCKEESPORT E MCKEESPORT MCKEESPORT            30         1280       1250           2
    #> 217 20170068 E MCKEESPORT E MCKEESPORT MCKEESPORT            30         1280       1250           2
    #> 218 2017C03… CANONSBURG   MC MURRAY    MCMURRAY              15          586        571           1
    #> 219 20180183 CANONSBURG   MC MURRAY    MCMURRAY              15          586        571           1
    #> 220 8000629  CANONSBURG   MC MURRAY    MCMURRAY              15          586        571           1
    #> 221 7900298  CANONSBURG   MC MURRAY    MCMURRAY              15          586        571           1
    #> 222 20170137 CANONSBURG   MC MURRAY    MCMURRAY              15          586        571           1
    #> 223 8200637  ORVISTON     MILHEIM      MILLHEIM               1          135        134           1
    #> 224 8000474  FOLSOM       MILMONT      MILLMONT              76            9        -67           1
    #> 225 8100217  FOLSOM       MILMONT      MILLMONT              76            9        -67           1
    #> 226 2016C03… PITTSBURGH   MT LEBANNON  MT LEBANON             1           64         63           1
    #> 227 20150064 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 228 9700309  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 229 20140421 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 230 2010427  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 231 2008336  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 232 20140201 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 233 2005226  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 234 8400326  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 235 20150138 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 236 2016C09… W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 237 8600238  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 238 9500250  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 239 20160071 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 240 20160071 PITTSBURGH   W NEWTON     NEWTOWN              317         1995       1678           3
    #> 241 8200237  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 242 20130205 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 243 8600169  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 244 9600257  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 245 20160129 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 246 8000488  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 247 2010389  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 248 8600398  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 249 9300158  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 250 8900170  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 251 7900369  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 252 7900006  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 253 7900188  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 254 20160050 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 255 7900117  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 256 7900456  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 257 7900202  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 258 8200660  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 259 2016C04… W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 260 7900160  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 261 9200410  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 262 7900650  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 263 2006260  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 264 2010427  WEBSTER      W NEWTON     NEWTOWN              317         1995       1678           3
    #> 265 8000568  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 266 2006101  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 267 9400089  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 268 20130191 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 269 9500243  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 270 8100158  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 271 7900366  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 272 20120373 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 273 2002204  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 274 20140200 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 275 8100304  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 276 8400338  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 277 8200047  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 278 2002265  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 279 9000335  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 280 7900387  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 281 9000164  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 282 7900079  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 283 8000703  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 284 20130237 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 285 20110243 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 286 20140166 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 287 2007295  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 288 9700285  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 289 2006085  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 290 8200529  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 291 2000142  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 292 20170058 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 293 20160166 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 294 2017C02… W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 295 20160352 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 296 20160071 GREENSBURG   W NEWTON     NEWTOWN              317         1995       1678           3
    #> 297 2018C11… W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 298 2018C11… HARRISBURG   W NEWTON     NEWTOWN              317         1995       1678           3
    #> 299 8600109  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 300 2010310  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 301 8600065  W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 302 20190098 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 303 20190058 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 304 20190016 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 305 20140113 W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 306 2019C03… W NEWTON     W NEWTON     NEWTOWN              317         1995       1678           3
    #> 307 20160056 ONO          ONO          NON                  606         3250       2644           2
    #> 308 2018C07… LOYSVILLE    ON           NON                55595         3250     -52345           1
    #> 309 2010095  LANGHORNE    PENDEL       PENNDEL                2           85         83           1
    #> 310 9500165  PHILADELPHIA PHIILA       PHILA                  1        83313      83312           1
    #> 311 2010025  PHILADELPHIA PHILLA       PHILA                  1        83313      83312           1
    #> 312 20180008 PHILADELPHIA PHILADEL     PHILADE            73984        73986          2           1
    #> 313 7900117  PITTSBURGH   PITT         PIT                33711        33761         50           1
    #> 314 2010389  PITTSBURGH   PLUMBORO     PLUM BORO              1            3          2           1
    #> 315 2011150  NEW PROVIDE… QUARYVILLE   QUARRYVILLE            1          383        382           1
    #> 316 2018C01… WELLSVILLE   E RED LION   RED LION               1          595        594           2
    #> 317 9400092  BANGOR       ROSETTO      ROSETO                 2           21         19           1
    #> 318 20120110 BELLE VERNON ROS TRAVER … ROSTRAVER TWP          1           34         33           1
    #> 319 7900366  BELLE VERNON ROOSTRAVER … ROSTRAVER TWP          1           34         33           1
    #> 320 20160233 WILLIAMSPORT WMSPT        S WMSPT                2            1         -1           2
    #> 321 8800271  READING      SINKING SPGS SINKING SPG           24          199        175           1
    #> 322 2007012  READING      SINKING SPGS SINKING SPG           24          199        175           1
    #> 323 2004017  READING      SINKING SPGS SINKING SPG           24          199        175           1
    #> 324 9700250  READING      SINKING SPGS SINKING SPG           24          199        175           1
    #> 325 9700144  READING      SINKING SPGS SINKING SPG           24          199        175           1
    #> 326 20120083 READING      SINKING SPGS SINKING SPG           24          199        175           1
    #> 327 7900300  READING      SINKING SP   SINKING SPG          200          199         -1           1
    #> 328 7900443  READING      SINKING SPGS SINKING SPG           24          199        175           1
    #> 329 7900364  READING      SINKING SPGS SINKING SPG           24          199        175           1
    #> 330 7900302  READING      SINKING SPGS SINKING SPG           24          199        175           1
    #> 331 9200410  READING      SINKING SPGS SINKING SPG           24          199        175           1
    #> 332 8400128  READING      SINKING SPGS SINKING SPG           24          199        175           1
    #> 333 7900202  READING      SINKING SPGS SINKING SPG           24          199        175           1
    #> 334 9700178  READING      SINKING SPGS SINKING SPG           24          199        175           1
    #> 335 2000081  READING      SINKING SPGS SINKING SPG           24          199        175           1
    #> 336 2002336  READING      SINKING SPGS SINKING SPG           24          199        175           1
    #> 337 8600110  READING      SINKING SPGS SINKING SPG           24          199        175           1
    #> 338 8000639  E SMETHPORT  E SMETHPORT  SMETHPORT              5           30         25           2
    #> 339 2002121  E SMETHPORT  E SMETHPORT  SMETHPORT              5           30         25           2
    #> 340 2015C01… E SMITHFIELD E SMITHFIELD SMITHFIELD            11           43         32           2
    #> 341 9100275  E SMITHFIELD E SMITHFIELD SMITHFIELD            11           43         32           2
    #> 342 8400421  MILAN        E SMITHFIELD SMITHFIELD            11           43         32           2
    #> 343 20180026 E SMITHFIELD E SMITHFIELD SMITHFIELD            11           43         32           2
    #> 344 7900491  SOUTHEASTERN SOUTHERN EA… SOUTHEASTERN          18         1578       1560           4
    #> 345 9500250  SPG HOUSE    SSPRING HOU… SPRINGHOUSE            1           17         16           2
    #> 346 9700178  HARRISBURG   STEELLTON    STEELTON               2          660        658           1
    #> 347 9500250  HARRISBURG   STEELLTON    STEELTON               2          660        658           1
    #> 348 20120153 CANONSBURG   N STRABANE   STRABANE               1            4          3           2
    #> 349 2000213  PITTSBURGH   SWISVALE     SWISSVALE              1           58         57           1
    #> 350 2004037  RUSSELL      TITTUSVILLE  TITUSVILLE             1           31         30           1
    #> 351 9500237  MARCUS HOOK  UPPER HICHE… UPPER CHICHE…          1          263        262           1
    #> 352 8100217  SPRINGFIELD  UPPERCHICHE… UPPER CHICHE…          1          263        262           1
    #> 353 7900444  ASTON        UPPER CHICH… UPPER CHICHE…        264          263         -1           1
    #> 354 9500250  PITTSBURGH   UPER ST CLA… UPPER ST CLA…          1          195        194           1
    #> 355 7900443  PITTSBURGH   UPPER ST CL… UPPER ST CLA…          1          195        194           1
    #> 356 7900406  PITTSBURGH   UPPER STCLA… UPPER ST CLA…          1          195        194           1
    #> 357 20160062 E VANDERGRI… E VANDERGRI… VANDERGRIFT            3          177        174           2
    #> 358 9400098  E VANDERGRI… E VANDERGRI… VANDERGRIFT            3          177        174           2
    #> 359 20120022 WYOMING      W W          W                     31        85851      85820           2
    #> 360 20160111 WILKES BARRE WB           W B                  118          427        309           1
    #> 361 20120022 WILKES BARRE WB           W B                  118          427        309           1
    #> 362 20170211 WILKES BARRE WB           W B                  118          427        309           1
    #> 363 2019C00… N WASHINGTON N WASHINGTON WASHINGTON             1        11748      11747           2
    #> 364 2002017  E WATERFORD  E WATERFORD  WATERFORD             15          102         87           2
    #> 365 7900419  E WATERFORD  E WATERFORD  WATERFORD             15          102         87           2
    #> 366 2018C09… E WATERFORD  E WATERFORD  WATERFORD             15          102         87           2
    #> 367 7900374  E WATERFORD  E WATERFORD  WATERFORD             15          102         87           2
    #> 368 9800029  E WATERFORD  E WATERFORD  WATERFORD             15          102         87           2
    #> 369 20180125 E WATERFORD  E WATERFORD  WATERFORD             15          102         87           2
    #> 370 20180134 E WATERFORD  E WATERFORD  WATERFORD             15          102         87           2
    #> 371 8300167  ALLENTOWN    WESCOESVILLE WESCOSVILLE            8           45         37           1
    #> 372 7900433  GRN LN       WESCOESVILLE WESCOSVILLE            8           45         37           1
    #> 373 20120381 ALLENTOWN    WESCOESVILLE WESCOSVILLE            8           45         37           1
    #> 374 7900433  CATASAUQUA   WESCOESVILLE WESCOSVILLE            8           45         37           1
    #> 375 9400092  ALLENTOWN    WESCOESVILLE WESCOSVILLE            8           45         37           1
    #> 376 9700250  PITTSBURGH   WILKES TOWN… WILKENS TOWN…          1            1          0           1
    #> 377 7900488  ANTES FT     S WILLIAMSP… WILLIAMSPORT           1          913        912           2

Manually change the city\_refine fields due to overcorrection.

``` r
st_pattern <- str_c("\\s",unique(zipcode$state), "$", collapse = "|")


pa_refined$city_refine <- pa_refined$city_refine %>% 
  str_replace("^DU BOIS$", "DUBOIS") %>% 
  str_replace("^PIT$", "PITTSBURGH") %>% 
  str_replace("^MCCBG$", "MCCONNELLSBURG") %>% 
  str_replace("^PLUM BORO$", "PLUM") %>% 
  str_replace("^GREENVILLE$", "EAST GREENVILLE") %>% 
  str_replace("^NON$", "ONO") %>% 
  str_replace("^FORD CLIFF$", "CLIFFORD") %>% 
  str_replace("^W\\sB$", "WILKES BARRE") 

  

refined_table <-pa_refined %>% 
  select(index, city_refine)
```

#### Merge

``` r
pa <- pa %>% 
  left_join(refined_table, by ="index") %>% 
  mutate(city = coalesce(city_refine, city_swap)) 

pa$city <- pa$city %>% 
  str_replace("^MT PLEASANT$", "MOUNT PLEASANT") %>% 
  str_replace("^ST\\s", "SAINT ") %>% 
  str_replace("^MT\\s", "MOUNT ") %>%  
  str_replace("^FT\\s", "FORT ") %>% 
  str_replace("^W\\sB$|WB", "WILKES BARRE") %>% 
  str_replace("\\sHTS$|\\sHGTS$", " HEIGHTS") %>% 
  str_replace("\\sSQ$", " SQUARE") %>% 
  str_replace("\\sSPGS$|\\sSPR$|\\sSPRG$", "  SPRINGS") %>% 
  str_replace("\\sJCT$", " JUNCTION") %>% 
  str_replace("^E\\s", "EAST ") %>% 
  str_replace("^N\\s", "NORTH ") %>% 
  str_replace("^W\\s", "WEST ") %>% 
  str_remove(st_pattern) %>% 
  str_remove("^X+$")
```

``` r
pa_match_table <- pa %>% 
  filter(str_sub(pa$city, 1,1) == str_sub(pa$city_match, 1,1)) %>% 
  filter(city %out% valid_city)  %>% 
  mutate(string_dis = stringdist(city, city_match)) %>% 
  select (index, zip_clean, STATE, city, city_match, string_dis) %>% 
  distinct() %>% 
  add_count(city_match) %>% 
  rename("sec_city_match" = "city_match")

# Manually change overcorrected city names to original 
pa_match_table$sec_city_match <- pa_match_table$sec_city_match %>% 
  str_replace("^ARLINGTON$", "ALEXANDRIA") %>% 
  str_replace("^BROWNSVILLE$", "BENTLEYVILLE") %>% 
  str_replace("^FEASTERVILLE\\sTREVOSE", "FEASTERVILLE") %>% 
  str_replace("LEES SUMMIT", "LAKE LOTAWANA") %>% 
  str_replace("HAZLETON", "HAZLE TOWNSHIP") %>% 
  str_replace("DANIA", "DANIA BEACH") %>% 
  str_replace("CRANBERRY TWP", "CRANBERRY TOWNSHIP")

pa_match_table[pa_match_table$city == "HOLLIDASBURG", "city_match"] <- "HOLLIDAYSBURG"
pa_match_table[pa_match_table$city == "PENN HELLE", "city_match"] <- "PENN HILLS"
pa_match_table[pa_match_table$city == "PHUM", "city_match"] <- "PLUM"
pa_match_table[pa_match_table$city == "CLARKSGREEN", "city_match"] <- "CLARKS GREEN"
pa_match_table[pa_match_table$city == "SANFRANCISCO", "city_match"] <- "SAN FRANCISCO"
pa_match_table[pa_match_table$city == "RIEFFTON", "city_match"] <- "REIFFTON"
pa_match_table[pa_match_table$city == "SHOREVILLE", "city_match"] <- "SHOREVIEW"
pa_match_table[pa_match_table$city == "PITTSBURGH PLUM", "city_match"] <- "PLUM"
pa_match_table[pa_match_table$city == "MOUNTVIEW", "city_match"] <- "MOUNT VIEW"
pa_match_table[pa_match_table$city == "PLUM BORO", "city_match"] <- "PLUM"
pa_match_table[pa_match_table$city == "HAZELTON CITY", "city_match"] <- "HAZLE TOWNSHIP"
pa_match_table[pa_match_table$city == "BARNSVILLE", "city_match"] <- "BARNESVILLE"

keep_original <- c( "SHOREVIEW" ,
   "CUYAHOGA" ,
   "MEDFORD LAKES" ,
   "WEST GOSHEN" ,
   "CLEVELAND HEIGHTS" ,
   "LAHORNE" ,
   "ROCHESTER HILLS" ,
   "PENLLYN" ,
   "SOUTHERN" ,
   "WEST DEPTFORD" ,
   "SEVEN FIELDS" ,
   "LORDS VALLEY" ,
   "WILDWOOD CREST" ,
   "BETHLEHEM TOWNSHIP" ,
   "MOON TOWNSHIP" ,
   "BELFONTE" ,
   "NEWPORT TOWNSHIP" , 
   "LINTHICUM" , 
   "WARRIOR RUN" ,
   "PRIMOS SECANE" ,
   "COOKPORT" , 
   "MANASSAS PARK" ,
   "MCMURRAY" ,
   "MOYLAN" ,
   "BELMONT HILLS" ,
   "THORNBURY" ,
   "HANOVER TOWNSHIP" ,
   "MIAMI SPRINGS" ,
   "BROOKLYN PARK" )

pa_match_table[pa_match_table$city %in% keep_original,"sec_city_match"] <-
  pa_match_table[pa_match_table$city %in% keep_original,"city"]


pa <-pa %>% 
  left_join(select(pa_match_table, index, sec_city_match), by = "index") %>% mutate(city_clean = coalesce(sec_city_match, city))

pa$city_clean <- pa$city_clean %>% str_replace("\\sTWP$", " TOWNSHIP")

n_distinct(pa$city_clean[pa$city_clean %out% valid_city])
```

    #> [1] 934

``` r
valid_city <- unique(c(valid_city, pa_match_table$sec_city_match))

pa_city_lookup <- read_csv(file = here("pa", "expends", "data", "raw", "pa_city_lookup.csv"), col_names = c("city", "city_lookup", "changed", "count"))

pa_out <- pa %>% 
  count( city_clean, sort = TRUE) %>% 
  filter(city_clean %out% valid_city) 

pa_out <- pa_out %>% left_join(pa_city_lookup, by = c("city_clean" = "city")) %>% filter(city_clean != city_lookup | is.na(city_lookup) == T ) %>% drop_na(city_clean)


pa <- pa %>% left_join(pa_out, by = "city_clean") %>% mutate(city_final = ifelse(
  is.na(city_lookup) == TRUE,
  NA,
  coalesce(city_lookup, city_clean))) 

pa$city_final <- pa$city_final %>% str_replace("^\\sTWP$", " TOWNSHIP")

pa[pa$index == which(pa$city_final == "MA"),8:9] <- c("LEXINGTON", "MA")
pa[pa$index == which(pa$city_final == "L"),8] <- c("LOS ANGELES")
pa[pa$index %in% which(pa$city_final %in% c("PA", "NJ")), 8] <- ""
pa[pa$index == "319505", 8] <- "HARRISBURG"
```

Each process also increases the percent of valid city names.

``` r
prop_in(pa$CITY, valid_city, na.rm = TRUE)
#> [1] 0.8692647
prop_in(pa$city_prep, valid_city, na.rm = TRUE)
#> [1] 0.9435455
prop_in(pa$city_swap, valid_city, na.rm = TRUE)
#> [1] 0.9549554
prop_in(pa$city, valid_city, na.rm = TRUE)
#> [1] 0.9323915
prop_in(pa$city_clean, valid_city, na.rm = TRUE)
#> [1] 0.9774069
prop_in(pa$city_final, valid_city, na.rm = TRUE)
#> [1] 0.7707594
```

Each step of the cleaning process reduces the number of distinct city values. There are 481469 with 6218 distinct values, after the swap and refine processes, there are 480546 entries with 4053 distinct values.

Conclude
--------

1.  There are 493025 records in the database
2.  There are 6999 records with suspected duplicate filerID, recipient, date, *and* amount (flagged with `dupe_flag`)
3.  The ranges for dates and amounts are reasonable
4.  Consistency has been improved with `stringr` package and custom `normal_*()` functions.
5.  The five-digit `zip_clean` variable has been created with `zipcode::clean.zipcode()`
6.  The `year` variable has been created with `lubridate::year()`
7.  There are 11556 records with missing `city` values and 124 records with missing `payee` values (both flagged with the `na_flag`).

Export
------

``` r
clean_dir <- here("pa", "expends", "data", "processed")
dir_create(clean_dir)
pa %>% 
  rename(ZIP5 = zip_clean, YEAR = year, CITY_CLEAN = city_final) %>% 
  select(
    -city_prep,
    -on_year,
    -city_match,
    -city_clean,
    -match_dist,
    -city_swap,
    -city_refine,
    -city_clean,
    -city_lookup,
    -sec_city_match,
    -n,
    -changed,
    -city,
    -count
  ) %>% 
  write_csv(
    path = glue("{clean_dir}/pa_expends_clean.csv"),
    na = ""
  )
```
