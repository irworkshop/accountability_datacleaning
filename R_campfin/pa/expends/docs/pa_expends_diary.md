Pennsylvania Campaign Expenditures Data Diary
================
Yanqi Xu
2019-09-09 16:58:03

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

The Pennsylvania campaign expenditure data is made available by the [Pennsylvania Department of State's website](https://www.dos.pa.gov/VotingElections/CandidatesCommittees/CampaignFinance/Resources/Pages/FullCampaignFinanceExport.aspx "website").

### About

More information about the record layout can be found [here](https://www.dos.pa.gov/VotingElections/CandidatesCommittees/CampaignFinance/Resources/Documents/readme.txt. "here") as well as at [FAQs](https://www.dos.pa.gov/VotingElections/CandidatesCommittees/CampaignFinance/Documents/FAQ/CampaignFinanceFAQ.pdf "FAQs") about Pennsylvania Campaign Finance regulations

### Variables

Import
------

### Download

Download raw, **immutable** data file. Go to [Pennsylvania Department of State's website](https://www.dos.pa.gov/VotingElections/CandidatesCommittees/CampaignFinance/Resources/Pages/FullCampaignFinanceExport.aspx "website"). [05](https://www.dos.pa.gov/VotingElections/CandidatesCommittees/CampaignFinance/Resources/Pages/FullCampaignFinanceExport.aspx "website"): <https://www.dos.pa.gov/VotingElections/CandidatesCommittees/CampaignFinance/Resources/Pages/FullCampaignFinanceExport.aspx> "website" We'll download the files from 2015 to 2019 (file format: zip file) with the following code.

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
expense_files <- dir_ls(raw_dir, regexp = "expense.+", recurse = TRUE)
#pa_lines <- list.files(raw_dir, pattern = ".txt", recursive = TRUE) %>% map(read_lines) %>% unlist()
pa_col_names <- c("FILERID","EYEAR","CYCLE","EXPNAME","ADDRESS1","ADDRESS2","CITY","STATE","ZIPCODE","EXPDATE","EXPAMT","EXPDESC")


pa <- expense_files %>% 
  map(read_delim, delim = ",", escape_double = FALSE,
      escape_backslash = FALSE, col_names = pa_col_names, 
      col_types = cols(.default = col_character(),
                       EYEAR = col_integer(),
                       CYCLE = col_integer())) %>% 
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
    #>   <chr>    <int> <int> <chr>      <chr>      <chr>    <chr> <chr> <chr>   <date>      <dbl> <chr>  
    #> 1 20140199  2015     2 VALLEY DE… 1321 FREE… <NA>     CHES… PA    15024   2015-02-16  250   DONATI…
    #> 2 20140199  2015     2 OFFICE MAX 4080 WILA… <NA>     MONR… PA    15146   2015-02-18   16.6 OFFICE…
    #> 3 20140199  2015     2 GATEWAY C… PARKING    <NA>     PITT… PA    15222   2015-02-18   20   PARKING
    #> 4 20140199  2015     2 USPS       KILBUCK    <NA>     PITT… PA    15290   2015-02-18  980   POSTAGE
    #> 5 20140199  2015     2 EDDIE MER… GATEWAY C… <NA>     PITT… PA    15222   2015-02-18  102.  CAMPAI…
    #> 6 20140199  2015     2 CASTLE SH… CO EILEEN… <NA>     PITT… PA    15234   2015-02-23  100   DONATI…

``` r
tail(pa)
```

    #> # A tibble: 6 x 12
    #>   FILERID  EYEAR CYCLE EXPNAME  ADDRESS1  ADDRESS2 CITY  STATE ZIPCODE EXPDATE    EXPAMT EXPDESC   
    #>   <chr>    <int> <int> <chr>    <chr>     <chr>    <chr> <chr> <chr>   <date>      <dbl> <chr>     
    #> 1 2019C02…  2019     2 VISTA P… 95 HAYDE… <NA>     LEXI… MA    02421   2019-03-17   36.0 PRINTING …
    #> 2 2019C02…  2019     2 VISTA P… 95 HAYDE… <NA>     LEXI… MA    02421   2019-03-28   36.3 PRINTED C…
    #> 3 20190018  2019     1 VISTA P… 95 HAYDE… <NA>     LEXI… MA    02421   2019-01-29  121.  CAMPAIGN …
    #> 4 2019C02…  2019     2 VISTA P… ONLINE    <NA>     <NA>  <NA>  <NA>    2019-04-30  604.  5.5 X 8.5…
    #> 5 2019C02…  2019     2 VISTA P… ONLINE    <NA>     <NA>  <NA>  <NA>    2019-05-01  165.  4X6 POSTC…
    #> 6 20170137  2019     2 VISTA P… ONLINE    <NA>     <NA>  <NA>  <NA>    2019-05-01  165.  4X6 POSTC…

``` r
glimpse(pa)
```

    #> Observations: 493,025
    #> Variables: 12
    #> $ FILERID  <chr> "20140199", "20140199", "20140199", "20140199", "20140199", "20140199", "201401…
    #> $ EYEAR    <int> 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2…
    #> $ CYCLE    <int> 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2…
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
    #>    col      type       n         p
    #>    <chr>    <chr>  <dbl>     <dbl>
    #>  1 FILERID  chr     4137 0.00839  
    #>  2 EYEAR    int        7 0.0000142
    #>  3 CYCLE    int        9 0.0000183
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
    #>    col      type       n        p
    #>    <chr>    <chr>  <dbl>    <dbl>
    #>  1 FILERID  chr        0 0       
    #>  2 EYEAR    int        0 0       
    #>  3 CYCLE    int        0 0       
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
#>  [1] "19149" NA      "16141" "17401" "19101" "15230" "15347" "17512" "16823" "17013"
```

### State

View values in the STATE field is not a valid state abbreviation

``` r
{pa$STATE[pa$STATE %out% zipcode$state]}[!is.na(pa$STATE[pa$STATE %out% zipcode$state])]
#> [1] "CN" "CN" "CN" "CN"


pa %>% filter(STATE == "CN")
#> # A tibble: 4 x 21
#>    index FILERID EYEAR CYCLE EXPNAME ADDRESS1 ADDRESS2 CITY  STATE ZIPCODE EXPDATE    EXPAMT
#>    <int> <chr>   <int> <int> <chr>   <chr>    <chr>    <chr> <chr> <chr>   <date>      <dbl>
#> 1   3445 7900257  2015     1 CSA BA… 1500 NO… <NA>     QUEB… CN    J4B 5H3 2015-03-18   5.11
#> 2   3446 7900257  2015     1 CSA BA… 1500 NO… <NA>     QUEB… CN    J4B 5H3 2015-03-18 511.  
#> 3 296601 201700…  2017     6 ISTOCK  1240 20… <NA>     CALG… CN    00000   2017-10-27  35.0 
#> 4 400304 2009450  2018     6 HOOTSU… 5 EAST … <NA>     VANC… CN    V5T 1R6 2018-10-31  47.7 
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
    match_dist = stringdist(city_match, city_prep),
    city_swap = if_else(
      condition = !is.na(match_dist) & match_dist <= 2,
      true = city_match,
      false = city_prep
    )
  )


summary(pa$match_dist)
```

    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
    #>   0.000   0.000   0.000   0.601   0.000  22.000   20598

``` r
sum(pa$match_dist == 1, na.rm = TRUE)
```

    #> [1] 5425

``` r
n_distinct(pa$city_swap)
```

    #> [1] 4351

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

    #> # A tibble: 70 x 3
    #>    city_swap        city_refine        n
    #>    <chr>            <chr>          <int>
    #>  1 SINKING SPRINGS  SINKING SPRING    23
    #>  2 SOUTHERN EASTERN SOUTHEASTERN      18
    #>  3 MC MURRAY        MCMURRAY          15
    #>  4 MC BG            MCCBG             13
    #>  5 PLEASANT MOUNT   MOUNT PLEASANT    12
    #>  6 CLIFFORD         FORD CLIFF         8
    #>  7 WESCOESVILLE     WESCOSVILLE        8
    #>  8 EDDYSTON         EDDYSTONE          7
    #>  9 BROMALL          BROOMALL           4
    #> 10 CARSLISLE        CARLISLE           4
    #> # … with 60 more rows

Manually change the city\_refine fields due to overcorrection.

``` r
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

    #> [1] 917

Lastly, we'll make some manual changes to the data.

``` r
pa_out <- pa %>% filter(city %out% valid_city) 


pa_city_lookup <- read_csv(file = here("pa", "expends", "data", "raw", "pa_city_lookup.csv"), col_names = c("city", "city_lookup", "changed", "count"))


pa_out <- pa_out %>% select(index, CITY) %>% 
  inner_join(pa_city_lookup, by = c("CITY" = "city")) %>% 
  drop_na(CITY) %>% 
  select(-changed, -CITY, -count) %>% 
  distinct() 


pa <- pa %>% left_join(pa_out, by = "index") %>% mutate(city_final = ifelse(pa$index %in% pa_out$index, city_lookup,city))

pa$city_final <- pa$city_final %>% str_replace("^\\sTWP$", " TOWNSHIP")

pa[pa$index == which(pa$city_final == "MA"),8:9] <- c("LEXINGTON", "MA")
pa[pa$index == {which(pa$city_final == "L")[1]},8] <- c("LOS ANGELES")
pa[pa$index == {which(pa$city_final == "L")[2]},8] <- c("LOS ANGELES")
pa[pa$index %in% which(pa$city_final %in% c("PA", "NJ")), 8] <- ""
pa[pa$index == "319505", 8] <- "HARRISBURG"
```

Each process also increases the percent of valid city names.

``` r
prop_in(pa$CITY, valid_city, na.rm = TRUE)
#> [1] 0.9308741
prop_in(pa$city_prep, valid_city, na.rm = TRUE)
#> [1] 0.9397328
prop_in(pa$city_swap, valid_city, na.rm = TRUE)
#> [1] 0.9496889
prop_in(pa$city, valid_city, na.rm = TRUE)
#> [1] 0.9499012
prop_in(pa$city_clean, valid_city, na.rm = TRUE)
#> [1] 0.971376
prop_in(pa$city_final, valid_city, na.rm = TRUE)
#> [1] 0.9715765
```

``` r
if (all_files_new(path = raw_dir, glob = "*.txt")) {
  for (i in seq_along(zip_files)) {
    unzip(
      zipfile = zip_files[i],
      #Matches the csv files that start with "filer", and trim the "./ " from directory names
      files = grep("filer.+", unzip(zip_files[i]), value = TRUE) %>% substring(3,),
      exdir = glue(raw_dir,"/filer")
    )
  }
}


filer_files <- list.files(raw_dir, pattern = "filer.+", recursive = TRUE, full.names = TRUE)

filer_fields <- c("FILERID", "EYEAR", "CYCLE", "AMMEND", "TERMINATE", "FILERTYPE", "FILERNAME", "OFFICE", "DISTRICT", "PARTY", "ADDRESS1", "ADDRESS2", "CITY", "STATE", "ZIPCODE", "COUNTY", "PHONE", "BEGINNING", "MONETARY", "INKIND")

pa_filer <- filer_files %>% 
  map(read_delim, delim = ",", escape_double = FALSE,
      escape_backslash = TRUE, col_names = filer_fields, 
      col_types = cols(.default = col_character(),
                       CYCLE = col_integer(),
                       EYEAR = col_integer(),
                       BEGINNING = col_double(),
                       MONETARY = col_double(),
                       INKIND = col_double()
                       )) %>% 
  bind_rows() %>% 
  mutate_if(is_character, str_to_upper)

pa_filer <- pa_filer %>% mutate(zip_clean = normal_zip(pa_filer$ZIPCODE))

glimpse(pa_filer)
```

    #> Observations: 33,986
    #> Variables: 21
    #> $ FILERID   <chr> "2008291", "20150285", "2006371", "2007295", "8000489", "8700115", "2002295", …
    #> $ EYEAR     <int> 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, 2015, …
    #> $ CYCLE     <int> 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 6, 7, 7, 7, 7, 7, 7, 7, 7, …
    #> $ AMMEND    <chr> "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N"…
    #> $ TERMINATE <chr> "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N", "N"…
    #> $ FILERTYPE <chr> "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2", "2"…
    #> $ FILERNAME <chr> "FRANKLIN COUNTY REAGAN COALITION", "NEXTGEN CLIMATE ACTION COMMITTEE", "ZARWI…
    #> $ OFFICE    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
    #> $ DISTRICT  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
    #> $ PARTY     <chr> NA, NA, NA, NA, NA, NA, NA, "REP", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
    #> $ ADDRESS1  <chr> "P.O. BOX 240", "700 13TH STREET NW", "1818 MARKET STREET", "C/O TREASURER BRI…
    #> $ ADDRESS2  <chr> NA, "SUITE 600", "13TH FLOOR", "ONE FREEDOM SQUARE, 11951 FREEDOM DRIVE, 13TH …
    #> $ CITY      <chr> "MARION", "WASHINGTON", "PHILADELPHIA", "RESTON", "HORSHAM", "WASHINGTON", "PH…
    #> $ STATE     <chr> "PA", "DC", "PA", "VA", "PA", "DC", "PA", "PA", "PA", "PA", "PA", "PA", "PA", …
    #> $ ZIPCODE   <chr> "17235", "20005", "19103", "20190", "19044", "20001", "191541003", "17901", "1…
    #> $ COUNTY    <chr> NA, NA, NA, NA, NA, NA, NA, "54", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ PHONE     <chr> "7172670032", NA, "2155692800", "7038604194", "2159388000", "2024197053", "215…
    #> $ BEGINNING <dbl> 22116.63, 0.00, 736.77, 885319.13, 206155.84, 274293.06, 34693.91, 9565.69, 14…
    #> $ MONETARY  <dbl> 8.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1531.00, 375.00, 0.00, 0.00, 0.00, 5165.00…
    #> $ INKIND    <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
    #> $ zip_clean <chr> "17235", "20005", "19103", "20190", "19044", "20001", "19154", "17901", "19047…

``` r
tabyl(pa_filer$STATE)
```

    #> # A tibble: 34 x 4
    #>    `pa_filer$STATE`     n  percent valid_percent
    #>    <chr>            <dbl>    <dbl>         <dbl>
    #>  1 AL                   5 0.000147      0.000147
    #>  2 AR                   7 0.000206      0.000206
    #>  3 AZ                  11 0.000324      0.000324
    #>  4 CA                  68 0.00200       0.00200 
    #>  5 CO                  23 0.000677      0.000678
    #>  6 CT                  36 0.00106       0.00106 
    #>  7 DC                1020 0.0300        0.0301  
    #>  8 DE                  51 0.00150       0.00150 
    #>  9 FL                  29 0.000853      0.000855
    #> 10 GA                  21 0.000618      0.000619
    #> # … with 24 more rows

``` r
pa_filer <- pa_filer %>% mutate(city_prep = normal_city(city = CITY, 
                                                          geo_abbs = usps_city,
                                            st_abbs = c(valid_state),
                                            na = invalid_city,
                                            na_rep = TRUE))
pa_filer <- tibble::rowid_to_column(pa_filer, "index")

pa_filer$FILERNAME <- pa_filer$FILERNAME %>%  str_replace("&AMP;", "&") 

# Match
pa_filer <- pa_filer %>%
  left_join(
    y = zipcode,
    by = c(
      "zip_clean" = "zip",
      "STATE" = "state"
    )
  ) %>% 
  rename(city_match = city)
# Swap
pa_filer <- pa_filer %>% 
mutate(
    match_dist = stringdist(city_match, city_prep),
    city_swap = if_else(
      condition = !is.na(match_dist) & match_dist <= 2,
      true = city_match,
      false = city_prep
    )
  )

# Refine
pa_filer_refined <- pa_filer %>%
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

pa_filer_refined %>% 
  count(city_swap, city_refine) %>% 
  arrange(desc(n))
```

    #> # A tibble: 4 x 3
    #>   city_swap     city_refine        n
    #>   <chr>         <chr>          <int>
    #> 1 CHESTER BROOK CHESTERBROOK       7
    #> 2 MC CBG        MCCBG              2
    #> 3 MILLMONT PARK MILMONT PARK       1
    #> 4 NEW           NEW ENTERPRISE     1

``` r
pa_filer_refined$city_refine <- pa_filer_refined$city_refine %>% 
  str_replace("^MCCBG$", "MCCONNELLSBURG")


filer_refined_table <-pa_filer_refined %>% 
  select(index, city_refine)

pa_filer <- pa_filer %>% 
  left_join(filer_refined_table, by ="index") %>% 
  mutate(city = coalesce(city_refine, city_swap)) 

prop_in(pa_filer$CITY, valid_city, na.rm = TRUE)
```

    #> [1] 0.7217363

``` r
prop_in(pa_filer$f_city_prep, valid_city, na.rm = TRUE)
```

    #> [1] NaN

``` r
prop_in(pa_filer$city_swap, valid_city, na.rm = TRUE)
```

    #> [1] 0.9621286

``` r
prop_in(pa_filer$city, valid_city, na.rm = TRUE)
```

    #> [1] 0.9622169

``` r
pa_filer <- pa_filer %>% 
  unite(
    ADDRESS1, ADDRESS2,
    col = address_clean,
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    address_clean = normal_address(
      address = address_clean,
      add_abbs = usps_city,
      na_rep = TRUE
    )
  ) %>% 
  select(
    everything(),
    address_clean
  )



pa <- pa_filer %>% 
  select(FILERID, EYEAR, CYCLE, FILERNAME, address_clean, zip_clean, city, STATE) %>% 
  rename(filer_address_clean = address_clean,
         filer_zip_clean = zip_clean,
         filer_city = city,
         filer_state = STATE) %>% 
  right_join(pa, pa_filer, by = c("FILERID", "EYEAR", "CYCLE"))
```

Each step of the cleaning process reduces the number of distinct city values. There are 487014 with 6215 distinct values, after the swap and refine processes, there are 486155 entries with 4051 distinct values.

Conclude
--------

1.  There are 498582 records in the database
2.  There are 7801 records with suspected duplicate filerID, recipient, date, *and* amount (flagged with `dupe_flag`)
3.  The ranges for dates and amounts are reasonable
4.  Consistency has been improved with `stringr` package and custom `normal_*()` functions.
5.  The five-digit `zip_clean` variable has been created with `zipcode::clean.zipcode()`
6.  The `year` variable has been created with `lubridate::year()`
7.  There are 11568 records with missing `city` values and 125 records with missing `payee` values (both flagged with the `na_flag`).

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
    -city
  ) %>% 
  write_csv(
    path = glue("{clean_dir}/pa_expends_clean.csv"),
    na = ""
  )
```
