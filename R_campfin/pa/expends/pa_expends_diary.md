Pennsylvania Campaign Expenditures Data Diary
================
Yanqi Xu
2019-08-15 13:12:40

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
  vroom #read deliminated files
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

Download raw, **immutable** data file. Go to <https://www.dos.pa.gov/VotingElections/CandidatesCommittees/CampaignFinance/Resources/Pages/FullCampaignFinanceExport.aspx>. We'll download the files from 2015 to 2019 (file format: zip file).

``` r
# create a directory for the raw data
raw_dir <- here("pa", "expends", "data", "raw")
dir_create(raw_dir)
```

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
      files = grep("expense.+", unzip(zip_files[i]), value = FALSE) %>% substring(3,),
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

We will flag any records with missing values in the key variables used to identify an expenditure. There are 0 columns in city\_state\_zip that are NAs

``` r
pa <- pa %>% mutate(na_flag = is.na(EXPNAME))
```

### Duplicates

``` r
pa_dupes <- get_dupes(pa)
glimpse(pa_dupes)
#> Observations: 12,314
#> Variables: 14
#> $ FILERID    <chr> "2000081", "2000081", "2000081", "2000081", "2000081", "2000081", "2000081", …
#> $ EYEAR      <chr> "2016", "2016", "2017", "2017", "2017", "2017", "2017", "2017", "2018", "2018…
#> $ CYCLE      <chr> "5", "5", "3", "3", "4", "4", "4", "4", "1", "1", "6", "6", "1", "1", "1", "1…
#> $ EXPNAME    <chr> "CITIZENS FOR MACKENZIE", "CITIZENS FOR MACKENZIE", "CAMERA FOR SENATE", "CAM…
#> $ ADDRESS1   <chr> "3620 LINCOLN AVE", "3620 LINCOLN AVE", "CO MJM STRATEGIES LLC", "CO MJM STRA…
#> $ ADDRESS2   <chr> NA, NA, "PO BOX 624", "PO BOX 624", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ CITY       <chr> "ALLENTOWN", "ALLENTOWN", "HARRISBURG", "HARRISBURG", "HARRISBURG", "HARRISBU…
#> $ STATE      <chr> "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA",…
#> $ ZIPCODE    <chr> "18103", "18103", "17108", "17108", "17108", "17108", "15425", "15425", "1590…
#> $ EXPDATE    <date> 2016-09-27, 2016-09-27, 2017-05-04, 2017-05-04, 2017-06-12, 2017-06-12, 2017…
#> $ EXPAMT     <dbl> 300.00, 300.00, 500.00, 500.00, 1000.00, 1000.00, 500.00, 500.00, 250.00, 250…
#> $ EXPDESC    <chr> "RYAN MACKENZIE, STATE HOUSE 134TH PA", "RYAN MACKENZIE, STATE HOUSE 134TH PA…
#> $ na_flag    <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, …
#> $ dupe_count <int> 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 6, 6,…
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

The dates seem to be reasonable, with records dating back to 0 till NULL, NULL

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
#>  [1] "19382" "17108" "17108" "19525" "17107" "19134" "15222" "08065" "17372" NA
```

### State

View values in the STATE field is not a valid state abbreviation

``` r
{pa$STATE[pa$STATE %out% zipcode$state]}[!is.na(pa$STATE[pa$STATE %out% zipcode$state])]
#> [1] "CN" "CN" "CN" "CN"

pa %>% filter(STATE == "CN")
#> # A tibble: 4 x 17
#>    index FILERID EYEAR CYCLE EXPNAME ADDRESS1 ADDRESS2 CITY  STATE ZIPCODE EXPDATE    EXPAMT
#>    <int> <chr>   <chr> <chr> <chr>   <chr>    <chr>    <chr> <chr> <chr>   <date>      <dbl>
#> 1   3445 7900257 2015  1     CSA BA… 1500 NO… <NA>     QUEB… CN    J4B 5H3 2015-03-18   5.11
#> 2   3446 7900257 2015  1     CSA BA… 1500 NO… <NA>     QUEB… CN    J4B 5H3 2015-03-18 511.  
#> 3 296601 201700… 2017  6     ISTOCK  1240 20… <NA>     CALG… CN    00000   2017-10-27  35.0 
#> 4 400304 2009450 2018  6     HOOTSU… 5 EAST … <NA>     VANC… CN    V5T 1R6 2018-10-31  47.7 
#> # … with 5 more variables: EXPDESC <chr>, na_flag <lgl>, year <dbl>, on_year <lgl>,
#> #   zip_clean <chr>
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
pa <- pa %>% mutate(city_prep = normal_city(CITY))
n_distinct(pa$city_prep)
#> [1] 5913
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
    #>   0.000   0.000   0.000   0.615   0.000  22.000   20403

``` r
sum(pa$match_dist == 1, na.rm = TRUE)
```

    #> [1] 5417

``` r
n_distinct(pa$city_swap)
```

    #> [1] 4492

#### Refine

``` r
valid_city <- unique(zipcode$city)
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

    #> # A tibble: 95 x 3
    #>    city_swap        city_refine        n
    #>    <chr>            <chr>          <int>
    #>  1 N HUNTINGDON     HUNTINGDON        32
    #>  2 SINKING SPRINGS  SINKING SPRING    23
    #>  3 SOUTHERN EASTERN SOUTHEASTERN      18
    #>  4 MC MURRAY        MCMURRAY          15
    #>  5 ONLIINE          ONLINE            14
    #>  6 E GREENVILLE     GREENVILLE        13
    #>  7 MC BG            MCCBG             13
    #>  8 WB               W B               12
    #>  9 PLEASANT MOUNT   MOUNT PLEASANT    11
    #> 10 CLIFFORD         FORD CLIFF         8
    #> # … with 85 more rows

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

    #> # A tibble: 157 x 8
    #>     FILERID  city_match   city_swap    city_refine   swap_count refine_count diff_count refine_dist
    #>     <chr>    <chr>        <chr>        <chr>              <int>        <int>      <int>       <dbl>
    #>   1 2002093  PITTSBURGH   ADDRESSON F… ADDRESS ON F…          1           26         25           1
    #>   2 9500250  BRIDGEVILLE  ALISON PARK  ALLISON PARK           1          321        320           1
    #>   3 7900321  PITTSTON     AVOCO        AVOCA                  1          501        500           1
    #>   4 20170352 WILKES BARRE BEARCREEK    BEAR CREEK             1           10          9           1
    #>   5 20170070 EAST BERLIN  E BERLIN     BERLIN                 2          233        231           2
    #>   6 8100217  MARCUS HOOK  BOOTHWYNN    BOOTHWYN               1          184        183           1
    #>   7 2017C01… HARRISBURG   BRESLER      BRESSLER               1           63         62           1
    #>   8 20130207 NEWTOWN SQU… BROMALL      BROOMALL               4          407        403           1
    #>   9 20150282 NEWTOWN SQU… BROMALL      BROOMALL               4          407        403           1
    #>  10 20170314 SOUTH LONDO… CARSLISLE    CARLISLE               4          689        685           1
    #>  11 20150001 WAYNE        CHESTER BRO… CHESTERBROOK           1          104        103           1
    #>  12 8900208  BROCKWAY     DUBOIS       DU BOIS                7          430        423           1
    #>  13 20170387 SCRANTON     DUNMMORE     DUNMORE                1          454        453           1
    #>  14 9100189  NORRISTOWN   EAST NORRIT… EAST NORRIST…          1            2          1           1
    #>  15 7900243  CRUM LYNNE   EDDYSTON     EDDYSTONE             38           31         -7           1
    #>  16 2010095  LEVITTOWN    FALSINGTON   FALLSINGTON            1           57         56           1
    #>  17 20180378 LEVITTOWN    FALSSINGTON  FALLSINGTON            1           57         56           1
    #>  18 2015C00… CLIFFORD     CLIFFORD     FORD CLIFF             8           17          9           8
    #>  19 2002199  CLIFFORD     CLIFFORD     FORD CLIFF             8           17          9           8
    #>  20 8400100  CLIFFORD     CLIFFORD     FORD CLIFF             8           17          9           8
    #>  21 8400100  MOSCOW       CLIFFORD     FORD CLIFF             8           17          9           8
    #>  22 8400100  CARBONDALE   CLIFFORD     FORD CLIFF             8           17          9           8
    #>  23 8100217  KINGSTON     FORTY FORTY  FORTY FORT             1           30         29           1
    #>  24 8100217  GLEN LYON    GLEN OLDEN   GLENOLDEN              1          334        333           1
    #>  25 9600227  CARBONDALE   GREENFIELD … GREENFIELD T…          1           21         20           1
    #>  26 2000207  EAST GREENV… E GREENVILLE GREENVILLE            13          658        645           2
    #>  27 8600109  EAST GREENV… E GREENVILLE GREENVILLE            13          658        645           2
    #>  28 7900610  EAST GREENV… E GREENVILLE GREENVILLE            13          658        645           2
    #>  29 7900152  EAST GREENV… E GREENVILLE GREENVILLE            13          658        645           2
    #>  30 2011158  EAST GREENV… E GREENVILLE GREENVILLE            13          658        645           2
    #>  31 9400040  EAST GREENV… E GREENVILLE GREENVILLE            13          658        645           2
    #>  32 9100209  EAST GREENV… E GREENVILLE GREENVILLE            13          658        645           2
    #>  33 9800204  EAST GREENV… E GREENVILLE GREENVILLE            13          658        645           2
    #>  34 20110229 EAST GREENV… E GREENVILLE GREENVILLE            13          658        645           2
    #>  35 9500133  SOUTHAMPTON  HOLAND       HOLLAND                1          343        342           1
    #>  36 7900134  DUNCANSVILLE HOLIDAYSBURG HOLLIDAYSBURG          5          599        594           1
    #>  37 20140462 IRWIN        N HUNTINGDON HUNTINGDON            33          763        730           2
    #>  38 2010427  IRWIN        N HUNTINGDON HUNTINGDON            33          763        730           2
    #>  39 2004105  IRWIN        N HUNTINGDON HUNTINGDON            33          763        730           2
    #>  40 20120153 IRWIN        N HUNTINGDON HUNTINGDON            33          763        730           2
    #>  41 2008336  IRWIN        N HUNTINGDON HUNTINGDON            33          763        730           2
    #>  42 2008336  LATROBE      N HUNTINGDON HUNTINGDON            33          763        730           2
    #>  43 2010389  IRWIN        N HUNTINGDON HUNTINGDON            33          763        730           2
    #>  44 2002171  NORRISTOWN   JEFFERSONVI… JEFFERSONVIL…          2          310        308           1
    #>  45 2006168  NORRISTOWN   JEFFERSONVI… JEFFERSONVIL…          2          310        308           1
    #>  46 7900259  LANCASTER    LANCASTERTER LANCASTER              1         5607       5606           3
    #>  47 2006030  HAWLEY       LORDS VALEY  LORDS VALLEY           1           30         29           1
    #>  48 2002072  NEW KENSING… LOWER BURER… LOWER BURRELL          1           74         73           1
    #>  49 9600321  AMBLER       LOWER GWYNE… LOWER GWYNEDD          3          109        106           1
    #>  50 9800210  PITTSBURGH   MC CANDLESS  MCCANDLESS             1            8          7           1
    #>  51 8200038  MCCONNELLSB… MC CBG       MCCBG                  2           18         16           1
    #>  52 7900343  MCCONNELLSB… MC BG        MCCBG                 13           18          5           1
    #>  53 7900343  FORT LITTLE… MC BG        MCCBG                 13           18          5           1
    #>  54 7900343  MARION       MC BG        MCCBG                 13           18          5           1
    #>  55 7900343  NEEDMORE     MC CONNELLS… MCCONNELLSBU…          3          209        206           1
    #>  56 7900343  MARION       MC CONNELLS… MCCONNELLSBU…          3          209        206           1
    #>  57 7900343  SALTILLO     MC CONNELLS… MCCONNELLSBU…          3          209        206           1
    #>  58 9500250  EAST MCKEES… E MCKEESPORT MCKEESPORT             2         1280       1278           2
    #>  59 9800084  EAST MCKEES… E MCKEESPORT MCKEESPORT             2         1280       1278           2
    #>  60 2017C03… CANONSBURG   MC MURRAY    MCMURRAY              15          586        571           1
    #>  61 20180183 CANONSBURG   MC MURRAY    MCMURRAY              15          586        571           1
    #>  62 8000629  CANONSBURG   MC MURRAY    MCMURRAY              15          586        571           1
    #>  63 7900298  CANONSBURG   MC MURRAY    MCMURRAY              15          586        571           1
    #>  64 20170137 CANONSBURG   MC MURRAY    MCMURRAY              15          586        571           1
    #>  65 20120168 ELKINS PARK  MELROSE PAA… MELROSE PARK           1           25         24           1
    #>  66 8200637  ORVISTON     MILHEIM      MILLHEIM               1          135        134           1
    #>  67 8000474  FOLSOM       MILMONT      MILLMONT              76            9        -67           1
    #>  68 8100217  FOLSOM       MILMONT      MILLMONT              76            9        -67           1
    #>  69 2005279  PLEASANT MO… PLEASANT MO… MOUNT PLEASA…         11          178        167          12
    #>  70 8000616  PLEASANT MO… PLEASANT MO… MOUNT PLEASA…         11          178        167          12
    #>  71 20170074 PLEASANT MO… PLEASANT MO… MOUNT PLEASA…         11          178        167          12
    #>  72 2010296  PLEASANT MO… PLEASANT MO… MOUNT PLEASA…         11          178        167          12
    #>  73 8800087  WILKES BARRE MOUNTAINTOP  MOUNTAIN TOP           2          140        138           1
    #>  74 2010090  WILKES BARRE MOUNTAINTOP  MOUNTAIN TOP           2          140        138           1
    #>  75 7900524  MOUNT CARMEL MTCARMEL     MT CARMEL              1            8          7           1
    #>  76 2002171  MOUNT JOY    MTJOY        MT JOY                 2           41         39           1
    #>  77 2016C03… PITTSBURGH   MT LEBANNON  MT LEBANON             1           61         60           1
    #>  78 2008047  MOUNT PLEAS… MTPLEASANT   MT PLEASANT            2          307        305           1
    #>  79 9200410  MOUNT PLEAS… MT PLEASANT… MT PLEASANT            1          307        306           3
    #>  80 2008047  MOUNT PLEAS… MTPLEASANTP  MT PLEASANT            1          307        306           2
    #>  81 20160035 PLEASANT MO… PLEASANT MT  MT PLEASANT            1          307        306           6
    #>  82 20160241 MOUNT PLEAS… MT PLEASEANT MT PLEASANT            1          307        306           1
    #>  83 8600238  WEST NEWTON  W NEWTON     NEWTOWN                5         1995       1990           3
    #>  84 7900188  WEST NEWTON  W NEWTON     NEWTOWN                5         1995       1990           3
    #>  85 20160056 ONO          ONO          NON                  606         3266       2660           2
    #>  86 2018C07… LOYSVILLE    ON           NON                55818         3266     -52552           1
    #>  87 20130205 IRWIN        NORTH UNTIN… NORTH HUNTIN…          1           96         95           1
    #>  88 20140458 KENNETT SQU… ONLIINE      ONLINE                14          104         90           1
    #>  89 8000109  PRIMOS       ON LINE      ONLINE                14          104         90           1
    #>  90 7900254  PALMYRA      PALMYRA PA   PALMYRA                1          428        427           3
    #>  91 2010095  LANGHORNE    PENDEL       PENNDEL                2           85         83           1
    #>  92 20140314 EAST PETERS… E PETERSBURG PETERSBURG             3          272        269           2
    #>  93 2003053  EAST PETERS… E PETERSBURG PETERSBURG             3          272        269           2
    #>  94 9500165  PHILADELPHIA PHIILA       PHILA                  1        83313      83312           1
    #>  95 2010025  PHILADELPHIA PHILLA       PHILA                  1        83313      83312           1
    #>  96 20180008 PHILADELPHIA PHILADEL     PHILADE            73984        73986          2           1
    #>  97 7900117  PITTSBURGH   PITT         PIT                33711        33761         50           1
    #>  98 2010389  PITTSBURGH   PLUMBORO     PLUM BORO              1            3          2           1
    #>  99 8100217  POTTSVILLE   POTTSGROVE   POTTS GROVE            1            2          1           1
    #> 100 2011150  NEW PROVIDE… QUARYVILLE   QUARRYVILLE            1          383        382           1
    #> 101 9400092  BANGOR       ROSETTO      ROSETO                 2           21         19           1
    #> 102 20120110 BELLE VERNON ROS TRAVER … ROSTRAVER TWP          1           34         33           1
    #> 103 7900366  BELLE VERNON ROOSTRAVER … ROSTRAVER TWP          1           34         33           1
    #> 104 2010427  RECTOR       RUFFSDALE    RUFFS DALE             1           23         22           1
    #> 105 20160233 WILLIAMSPORT WMSPT        S WMSPT                2            1         -1           2
    #> 106 8800271  READING      SINKING SPR… SINKING SPRI…         24          199        175           1
    #> 107 2007012  READING      SINKING SPR… SINKING SPRI…         24          199        175           1
    #> 108 2004017  READING      SINKING SPR… SINKING SPRI…         24          199        175           1
    #> 109 9700250  READING      SINKING SPR… SINKING SPRI…         24          199        175           1
    #> 110 9700144  READING      SINKING SPR… SINKING SPRI…         24          199        175           1
    #> 111 20120083 READING      SINKING SPR… SINKING SPRI…         24          199        175           1
    #> 112 7900443  READING      SINKING SPR… SINKING SPRI…         24          199        175           1
    #> 113 7900364  READING      SINKING SPR… SINKING SPRI…         24          199        175           1
    #> 114 7900302  READING      SINKING SPR… SINKING SPRI…         24          199        175           1
    #> 115 9200410  READING      SINKING SPR… SINKING SPRI…         24          199        175           1
    #> 116 8400128  READING      SINKING SPR… SINKING SPRI…         24          199        175           1
    #> 117 7900202  READING      SINKING SPR… SINKING SPRI…         24          199        175           1
    #> 118 9700178  READING      SINKING SPR… SINKING SPRI…         24          199        175           1
    #> 119 2000081  READING      SINKING SPR… SINKING SPRI…         24          199        175           1
    #> 120 2002336  READING      SINKING SPR… SINKING SPRI…         24          199        175           1
    #> 121 8600110  READING      SINKING SPR… SINKING SPRI…         24          199        175           1
    #> 122 8000639  EAST SMETHP… E SMETHPORT  SMETHPORT              2           30         28           2
    #> 123 8400421  MILAN        E SMITHFIELD SMITHFIELD             3           43         40           2
    #> 124 7900491  SOUTHEASTERN SOUTHERN EA… SOUTHEASTERN          18         1599       1581           4
    #> 125 8300005  CHATHAM      SOUTH EASTE… SOUTHEASTERN           4         1599       1595           1
    #> 126 8300005  WESTTOWN     SOUTH EASTE… SOUTHEASTERN           4         1599       1595           1
    #> 127 7900434  MOSCOW       SPRINGBROOK… SPRING BROOK…          1            1          0           1
    #> 128 8000444  PHILADELPHIA SPRINGHOUSE  SPRING HOUSE           3          282        279           1
    #> 129 2010310  AMBLER       SPRINGHOUSE  SPRING HOUSE           3          282        279           1
    #> 130 20170091 SPRING HOUSE SPRINGMILL   SPRING MILLS           2           45         43           2
    #> 131 9700178  HARRISBURG   STEELLTON    STEELTON               2          660        658           1
    #> 132 9500250  HARRISBURG   STEELLTON    STEELTON               2          660        658           1
    #> 133 2000213  PITTSBURGH   SWISVALE     SWISSVALE              1           58         57           1
    #> 134 2004037  RUSSELL      TITTUSVILLE  TITUSVILLE             1           31         30           1
    #> 135 9500237  MARCUS HOOK  UPPER HICHE… UPPER CHICHE…          1          263        262           1
    #> 136 8100217  SPRINGFIELD  UPPERCHICHE… UPPER CHICHE…          1          263        262           1
    #> 137 7900444  ASTON        UPPER CHICH… UPPER CHICHE…        264          263         -1           1
    #> 138 9500250  PITTSBURGH   UPER ST CLA… UPPER ST CLA…          1          192        191           1
    #> 139 7900443  PITTSBURGH   UPPER ST CL… UPPER ST CLA…          1          192        191           1
    #> 140 7900406  PITTSBURGH   UPPER STCLA… UPPER ST CLA…          1          192        191           1
    #> 141 20120022 WYOMING      W W          W                     31        87002      86971           2
    #> 142 20160111 WILKES BARRE WB           W B                  118          408        290           1
    #> 143 20120022 WILKES BARRE WB           W B                  118          408        290           1
    #> 144 20170211 WILKES BARRE WB           W B                  118          408        290           1
    #> 145 8300167  ALLENTOWN    WESCOESVILLE WESCOSVILLE            8           45         37           1
    #> 146 7900433  GREEN LANE   WESCOESVILLE WESCOSVILLE            8           45         37           1
    #> 147 20120381 ALLENTOWN    WESCOESVILLE WESCOSVILLE            8           45         37           1
    #> 148 7900433  CATASAUQUA   WESCOESVILLE WESCOSVILLE            8           45         37           1
    #> 149 9400092  ALLENTOWN    WESCOESVILLE WESCOSVILLE            8           45         37           1
    #> 150 9700250  PITTSBURGH   WILKES TOWN… WILKENS TOWN…          1            1          0           1
    #> 151 8000763  DINGMANS FE… XXXXXXX      XXXX                   2           13         11           3
    #> 152 2004017  CAMP HILL    XXX          XXXX                  17           13         -4           1
    #> 153 8000763  MILFORD      XXXXX        XXXX                   4           13          9           1
    #> 154 8000763  DINGMANS FE… XXX          XXXX                  17           13         -4           1
    #> 155 8000763  DINGMANS FE… XXXXXXXXX    XXXX                   1           13         12           5
    #> 156 9200358  CHAMBERSBURG XXX          XXXX                  17           13         -4           1
    #> 157 2009342  HARRISBURG   XX           XXXX                  20           13         -7           2

Manually change the city\_refine fields due to overcorrection.

``` r
pa_refined$city_refine <- pa_refined$city_refine %>% 
  str_replace("^DU BOIS$", "DUBOIS") %>% 
  str_replace("^PIT$", "PITSSBURGH") %>% 
  str_replace("^MCCBG$", "MCCONNELLSBURG") %>% 
  str_replace("^PLUM BORO$", "PLUM") %>% 
  str_replace("^GREENVILLE$", "EAST GREENVILLE") %>% 
  str_replace("^NON$", "ONO") %>% 
  str_replace("^FORD CLIFF$", "CLIFFORD") %>% 
  str_replace("^W B$", "WILKES BARRE") 

refined_table <-pa_refined %>% 
  select(index, FILERID, city_refine)
```

#### Merge

``` r
pa <- pa %>% 
  left_join(refined_table, by ="index") %>% 
  mutate(city = coalesce(city_refine, city_swap)) 

pa$city <- pa$city %>% 
  str_replace("^MT PLEASANT$", "MOUNT PLEASANT") %>% 
  str_replace("^MT ", "MOUNT ") %>% 
  str_replace("^ST\\s", "SAINT ") %>% 
  str_replace("^PHILA$", "PHILADELPHIA") %>% 
  str_replace("\\sTWP$", "") %>% 
  str_replace("\\sPA$", "")
  
pa_sec_refine <- pa %>% 
  filter(city %out% valid_city) %>%
  mutate(sec_match_dis = stringdist(city, city_match)) 

sec_refined_table <- pa_sec_refine %>% 
  filter(sec_match_dis < 5 ) %>% 
  select(index, city_match) %>% 
  rename (sec_city_match = city_match)

pa <-pa %>% 
  left_join(sec_refined_table, by = "index") %>% 
  mutate(city_clean = coalesce(sec_city_match, city))
```

Each process also increases the percent of valid city names.

``` r
prop_in(pa$CITY, valid_city, na.rm = TRUE)
#> [1] 0.9308824
prop_in(pa$city_prep, valid_city, na.rm = TRUE)
#> [1] 0.9344652
prop_in(pa$city_swap, valid_city, na.rm = TRUE)
#> [1] 0.9448504
prop_in(pa$city, valid_city, na.rm = TRUE)
#> [1] 0.9685762
prop_in(pa$city_clean, valid_city, na.rm = TRUE)
#> [1] 0.9695904
```

Each step of the cleaning process reduces the number of distinct city values. There are 481469 with 6218 distinct values, after the swap and refine processes, there are 481164 entries with 4206 distinct values.

Conclude
--------

1.  There are 493025 records in the database
2.  There are 0 records with suspected duplicate filerID, recipient, date, *and* amount (flagged with `dupe_flag`)
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
  select(
    -city_prep,
    -on_year,
    -city_match,
    -city_clean,
    -match_dist,
    -city_swap,
    -city_refine
  ) %>% 
  write_csv(
    path = glue("{clean_dir}/pa_expends_clean.csv"),
    na = ""
  )
```
