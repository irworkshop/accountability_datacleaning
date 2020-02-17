Iowa Lobbying Data Diary
================
Yanqi Xu
2020-02-05 20:46:58

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

``` r
if (!require("pacman")) install.packages("pacman")
pacman::p_load_current_gh("irworkshop/campfin")
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
  readxl #read excel files
)
```

This document should be run as part of the `R_campfin` project, which
lives as a sub-directory of the more general, language-agnostic
\[`irworkshop/accountability_datacleaning`\]\[01\] GitHub repository.

The `R_campfin` project uses the \[RStudio projects\]\[02\] feature and
should be run as such. The project also uses the dynamic `here::here()`
tool for file paths relative to *your* machine.

``` r
# where dfs this document knit?
here::here()
## [1] "/Users/enjoytina/Data-Viz-18/accountability_datacleaning/R_campfin"
```

## Download

Set the download directory first.

``` r
# create a directory for the raw data
raw_dir_lb <- here("ia", "lobbying", "data", "raw", "lobbyists")
raw_dir_cl <- here("ia", "lobbying", "data", "raw", "clients")
dir_create(raw_dir_lb)
dir_create(raw_dir_cl)
```

The \[Iowa Legislature\]
[03](https://www.legis.iowa.gov/lobbyist/reports/searchLobby?type=lobbyist)
makes available lobbyist information through a database for each
session. First, we need to download all the lobbyists registration
records associated with each session and combine them into a single
preadsheet.

``` r
lb_url_1 <- glue("https://www.legis.iowa.gov/lobbyist/reports/searchLobby?action=generateExcel&ga={83:88}")

lb_url_2 <- glue("&type=lobbyist&personID=&clientID=&name=&session={1:2}")

ia_lobby_lb_urls <- NULL

for (i in lb_url_1) {
  for (j in lb_url_2){
    if (str_detect(i, "88") & str_detect(j, "session=2")){
      break}
    ia_lobby_lb_urls = c(ia_lobby_lb_urls,str_c(i,j))
  }
}

if (!all_files_new(raw_dir_lb)) {
  for (url in ia_lobby_lb_urls) {
    download.file(
      url = url,
      destfile = glue("{raw_dir_lb}/ia_lobby_by_lobbyists_{str_extract_all(url, '[[:digit:]]') %>% unlist() %>% str_c(collapse = '')}.xlsx")
    )
  }
}

cl_url_1 <- glue("https://www.legis.iowa.gov/lobbyist/reports/searchLobby?action=generateExcel&ga={83:88}")

cl_url_2 <- glue("&type=client&personID=&clientID=&name=&session={1:2}")

ia_lobby_cl_urls <- NULL

for (i in cl_url_1) {
  for (j in cl_url_2){
    if (str_detect(i, "88") & str_detect(j, "session=2")){
      break}
    ia_lobby_cl_urls = c(ia_lobby_cl_urls,str_c(i,j))
  }
}

if (!all_files_new(raw_dir_cl)) {
  for (url in ia_lobby_cl_urls) {
    download.file(
      url = url,
      destfile = glue("{raw_dir_cl}/ia_lobby_by_clients_{str_extract_all(url, '[[:digit:]]') %>% unlist() %>% str_c(collapse = '')}.xlsx")
    )
  }
}
```

Then, we’ll merge each dataset into a master dataset. Note that there is
no date or year field in the individual databases, and we will need to
create such fields in the master file retaining the legislative period
information. [Iowa Code Ann.
§ 68B.36.](https://www.legis.iowa.gov/docs/ico/chapter/68B.pdf#page=24)
regulates lobbyists and clients reporting.  
\> All lobbyists shall, on or before the day their lobbying activity
begins, register by electronically filing a lobbyist’s registration
statement…Registration shall be valid from the date of registration
until the end of the calendar year. On or before July 31 of each year, a
lobbyist’s client shall electronically file with the general assembly a
report that contains information on all salaries, fees, retainers, and
reimbursement of expenses paid by the lobbyist’s client to the lobbyist
for lobbying purposes during the preceding twelve calendar months,
concluding on June 30 of each year.

## Clients

### Reading

``` r
ia_lobby_cl <- dir_ls(raw_dir_cl, glob = "*.xlsx")  %>% 
  map(read_xlsx) %>% 
  bind_rows(.id = "file") %>% 
  clean_names() %>% 
  # create a column with the original file info
  mutate(session_1 = as.numeric(str_sub(basename(file), start = -8, end = -7)),
          session_2 = as.numeric(str_sub(basename(file), start = -6, end = -6))) %>% 
  mutate_if(is_character, str_to_upper) %>% 
  rename(address_raw = address) %>% 
  na_if("NULL")
```

### Wrangling

Since all the lobbyists were jumbled together, we turn the lobbyists
column into a vector, and then use `unnest_longer()` to unnest all the
elements in the vector to keep each in individual row.

``` r
ia_lobby_cl <- ia_lobby_cl %>% 
  mutate(lobbyist = str_split(lobbyists, pattern = ", ")) %>% 
  unnest_longer(lobbyist)
```

### Duplicates

We’ll use the `flag_dupes()` function to see if there are records
identical to one another and flag the duplicates. A new variable
`dupe_flag` will be created.

``` r
ia_lobby_cl <- flag_dupes(ia_lobby_cl, dplyr::everything())
```

##### Year

``` r
ia_lobby_cl <- ia_lobby_cl %>% 
  mutate(year = 1842 + session_1 *2 + session_2)
```

#### Address

Separate the address, city, state and zip columns.

``` r
ia_lobby_cl <- ia_lobby_cl %>% 
  separate(address_raw,  into = c("address", "state_zip"), 
           #the separator is written in regex, to use the city as the separator for address and state_zip
           sep = ";.+,\\s", remove = FALSE) %>% 
  separate(state_zip, into = c("state", "zip"), sep = "\\s", remove = FALSE) %>% 
  mutate(city_raw = str_match(address_raw, ";\\s([^;]+),\\s")[,2]) %>% 
  select(-state_zip)
```

#### ZIP

``` r
ia_lobby_cl <- ia_lobby_cl %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE)
  )
```

#### State

Some of the state fields were not filled even though the city and
zipcodes were given. We’ll join the dataframe with the zipcodes
dataframe to make safe guesses.

``` r
ia_lobby_cl <- ia_lobby_cl %>% 
  mutate(state_clean = normal_state(state, na = c("","NA", "NULL"))) 
```

#### City

Now we turn on zen
mode.

###### Prep

``` r
ia_lobby_cl <- ia_lobby_cl %>% mutate(city_norm = normal_city(city = city_raw,
                                            abbs = usps_city,
                                            states = c(valid_state),
                                            na = invalid_city,
                                            na_rep = TRUE))
n_distinct(ia_lobby_cl$city_raw)
## [1] 476
n_distinct(ia_lobby_cl$city_norm)
## [1] 445

prop_in(ia_lobby_cl$city_raw, valid_city, na.rm = TRUE)
## [1] 0.9626853
prop_in(ia_lobby_cl$city_norm, valid_city, na.rm = TRUE)
## [1] 0.9865707
```

###### State interpolation

Some of the state fields were not filled even though the city and
zipcodes were given. After normalizing city and state, we’ll join the
dataframe with the zipcodes dataframe to make safe guesses.

``` r
ia_lobby_cl <- ia_lobby_cl %>% 
  left_join(zipcodes, by = c("zip_norm" = "zip", "city_norm" = "city")) %>% 
  mutate(state_clean= if_else(
    condition = is.na(state_clean),
    true = state.y,
    false = state_clean
  )) %>% 
  select(-state.y) %>% 
  rename(state = state.x)
```

###### Swap

Then, we will compare these normalized `city_norm` values to the
*expected* city value for the client’s ZIP code. If the [levenshtein
distance](https://en.wikipedia.org/wiki/Levenshtein_distance) is less
than 3, we can confidently swap these two values.

``` r
ia_lobby_cl <- ia_lobby_cl %>% 
  left_join(
    y = zipcodes,
    by = c(
      "state" = "state",
      "zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_dist = stringdist(city_norm, city_match),
city_swap = if_else(condition = is.na(city_match) == FALSE,
                        if_else(
      condition = match_dist <= 2,
      true = city_match,
      false = city_norm
    ),
      false = city_norm
  ))

prop_in(ia_lobby_cl$city_swap, valid_city, na.rm = TRUE)
```

    ## [1] 0.9929761

This is a very fast way to increase the valid proportion to 99% and
reduce the number of distinct *invalid* values from 44 to only 18

#### Missing

``` r
ia_lobby_cl  %>% col_stats(count_na)
```

    ## # A tibble: 20 x 4
    ##    col           class     n         p
    ##    <chr>         <chr> <int>     <dbl>
    ##  1 file          <chr>     0 0        
    ##  2 client        <chr>     0 0        
    ##  3 address_raw   <chr>     0 0        
    ##  4 address       <chr>     0 0        
    ##  5 state         <chr>     2 0.0000881
    ##  6 zip           <chr>     5 0.000220 
    ##  7 lobbyists     <chr>     5 0.000220 
    ##  8 session_1     <dbl>     0 0        
    ##  9 session_2     <dbl>     0 0        
    ## 10 lobbyist      <chr>     5 0.000220 
    ## 11 dupe_flag     <lgl>     0 0        
    ## 12 year          <dbl>     0 0        
    ## 13 city_raw      <chr>    17 0.000749 
    ## 14 address_clean <chr>    23 0.00101  
    ## 15 zip_norm      <chr>  1724 0.0760   
    ## 16 state_clean   <chr>    16 0.000705 
    ## 17 city_norm     <chr>    52 0.00229  
    ## 18 city_match    <chr>  2140 0.0943   
    ## 19 match_dist    <dbl>  2140 0.0943   
    ## 20 city_swap     <chr>    52 0.00229

Few values are missing from the lobbyists database.

### Lobbyists

We’ll join the lobbyists data back to the client database to add the
address.

#### Reading

``` r
ia_lobby_lb <- dir_ls(raw_dir_lb, glob = "*.xlsx")  %>% 
  map(read_xlsx) %>% 
  bind_rows(.id = "file") %>% 
  clean_names() %>% 
  # create a column with the original file info
  mutate(session_1 = as.numeric(str_sub(basename(file), start = -8, end = -7)),
          session_2 = as.numeric(str_sub(basename(file), start = -6, end = -6))) %>% 
  mutate_if(is_character, str_to_upper) %>% 
  rename(address_raw = address) %>% 
  na_if("NULL")
```

#### Duplicates

We’ll use the `flag_dupes` function to see if there are records
identical to one another and flag the duplicates. A new variable
`dupe_flag` will be created.

``` r
ia_lobby_lb <- flag_dupes(ia_lobby_lb, dplyr::everything())
```

#### Wrangling

##### Year

``` r
ia_lobby_lb <- ia_lobby_lb %>% 
  mutate(year = 1842 + session_1 *2 + session_2)
```

##### Address

Separate the address, city, state and zip columns.

``` r
ia_lobby_lb <- ia_lobby_lb %>% 
  separate(address_raw,  into = c("address", "state_zip"), 
           #the separator is written in regex, to use the city as the separator for address and state_zip
           sep = ";.+,\\s", remove = FALSE) %>% 
  separate(state_zip, into = c("state", "zip"), sep = "\\s", remove = FALSE) %>% 
  mutate(city_raw = str_match(address_raw, ";\\s([^;]+),\\s")[,2]) %>% 
  select(-state_zip)
```

##### ZIP

``` r
ia_lobby_lb <- ia_lobby_lb %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE)
  )
```

#### State

``` r
ia_lobby_lb <- ia_lobby_lb %>% 
  mutate(state_normal = normal_state(state, na = c("","NA", "NULL"))) 
```

#### City

Same thing as
bove.

###### Prep

``` r
ia_lobby_lb <- ia_lobby_lb %>% mutate(city_norm = normal_city(city = city_raw,
                                            abbs = usps_city,
                                            states = c(valid_state),
                                            na = invalid_city,
                                            na_rep = TRUE))
n_distinct(ia_lobby_lb$city_raw)
## [1] 338
n_distinct(ia_lobby_lb$city_norm)
## [1] 313

prop_in(ia_lobby_lb$city_raw, valid_city, na.rm = TRUE)
## [1] 0.9607359
prop_in(ia_lobby_lb$city_norm, valid_city, na.rm = TRUE)
## [1] 0.9925712
```

``` r
ia_cities <- zipcodes %>% filter(state == "IA")

ia_lobby_lb <- ia_lobby_lb %>% 
  left_join(zipcodes, by = c("zip_norm" = "zip", "city_norm" = "city")) %>% 
  mutate(state_normal = if_else(
    condition = is.na(state_normal),
    true = state.y,
    false = state_normal)) %>% 
  select(-state.y) %>% 
  rename(state = state.x)

ia_lobby_lb <- ia_lobby_lb %>% mutate(state_clean = if_else(condition = is.na(state_normal) & city_norm %in% ia_cities$city,
              true = "IA",
              false = state_normal))
```

###### Swap

Then, we will compare these normalized `city_norm` values to the
*expected* city value for that lobbyist’s ZIP code. If the [levenshtein
distance](https://en.wikipedia.org/wiki/Levenshtein_distance) is less
than 3, we can confidently swap these two values.

``` r
ia_lobby_lb <- ia_lobby_lb %>% 
  left_join(
    y = zipcodes,
    by = c(
      "state" = "state",
      "zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_dist = stringdist(city_norm, city_match),
city_swap = if_else(condition = is.na(city_match) == FALSE,
                        if_else(
      condition = match_dist <= 2,
      true = city_match,
      false = city_norm
    ),
      false = city_norm
  )) %>% 
  rename(city_clean = city_swap)

prop_in(ia_lobby_lb$city_clean, valid_city, na.rm = TRUE)
```

    ## [1] 0.9939469

#### Missing

``` r
ia_lobby_lb  %>% col_stats(count_na)
```

    ## # A tibble: 24 x 4
    ##    col                   class     n        p
    ##    <chr>                 <chr> <int>    <dbl>
    ##  1 file                  <chr>     0 0       
    ##  2 name                  <chr>     0 0       
    ##  3 address_raw           <chr>     0 0       
    ##  4 address               <chr>     0 0       
    ##  5 state                 <chr>     0 0       
    ##  6 zip                   <chr>     3 0.000412
    ##  7 represent_govs_office <chr>     0 0       
    ##  8 executive_branch      <chr>     0 0       
    ##  9 legislative_branch    <chr>     0 0       
    ## 10 comments              <chr>  7136 0.979   
    ## 11 clients               <chr>   288 0.0395  
    ## 12 session_1             <dbl>     0 0       
    ## 13 session_2             <dbl>     0 0       
    ## 14 dupe_flag             <lgl>     0 0       
    ## 15 year                  <dbl>     0 0       
    ## 16 city_raw              <chr>     3 0.000412
    ## 17 address_clean         <chr>     0 0       
    ## 18 zip_norm              <chr>   198 0.0272  
    ## 19 state_normal          <chr>   319 0.0438  
    ## 20 city_norm             <chr>    18 0.00247 
    ## 21 state_clean           <chr>    78 0.0107  
    ## 22 city_match            <chr>  3112 0.427   
    ## 23 match_dist            <dbl>  3113 0.427   
    ## 24 city_clean            <chr>    18 0.00247

Few values are missing from the lobbyists database.

## Join

In order to get lobbyists’ addresses, we will join by lobbyists names
from these two dataframes. But first, we’ll need to clean up the two
data tables a bit by getting rid of some iterative columns that we
created and join them by common fields.

``` r
ia_lobby_lb <- ia_lobby_lb %>% 
  select(-c(city_norm,
            city_match,
            file,
            state_normal,
            clients, 
            match_dist))

colnames(ia_lobby_lb) <- str_c("lb_", colnames(ia_lobby_lb))
```

``` r
ia_lobby_cl <- ia_lobby_cl %>% 
  rename(city_clean = city_swap) %>% 
  select(-c(city_norm,
            file,
            city_match,
            match_dist))
colnames(ia_lobby_cl) <- str_c("cl_", colnames(ia_lobby_cl))
```

To avoid confusion and extraneous records, we only join the
non-duplicate rows.

``` r
ia_lobby <- ia_lobby_cl %>% 
  rename(lobbyist = cl_lobbyist) %>% 
  filter(!cl_dupe_flag) %>% 
  left_join(ia_lobby_lb %>% filter(!lb_dupe_flag), by = c("lobbyist" = "lb_name",
                                                          "cl_session_1" = "lb_session_1",
                                                          "cl_session_2" = "lb_session_2",
                                                          "cl_year" = "lb_year")) %>% 
  select(-c(cl_dupe_flag, lb_dupe_flag, 
            ends_with("_raw"))) %>% 
  rename(client = cl_client,
         lb_zip5 = lb_zip_norm,
         cl_zip5 = cl_zip_norm) 

ia_lobby %>% col_stats(count_na)
```

    ## # A tibble: 24 x 4
    ##    col                      class     n         p
    ##    <chr>                    <chr> <int>     <dbl>
    ##  1 client                   <chr>     0 0        
    ##  2 cl_address               <chr>     0 0        
    ##  3 cl_state                 <chr>     2 0.0000894
    ##  4 cl_zip                   <chr>     5 0.000224 
    ##  5 cl_lobbyists             <chr>     5 0.000224 
    ##  6 cl_session_1             <dbl>     0 0        
    ##  7 cl_session_2             <dbl>     0 0        
    ##  8 lobbyist                 <chr>     5 0.000224 
    ##  9 cl_year                  <dbl>     0 0        
    ## 10 cl_address_clean         <chr>    23 0.00103  
    ## 11 cl_zip5                  <chr>  1709 0.0764   
    ## 12 cl_state_clean           <chr>    16 0.000715 
    ## 13 cl_city_clean            <chr>    52 0.00233  
    ## 14 lb_address               <chr>   152 0.00680  
    ## 15 lb_state                 <chr>   152 0.00680  
    ## 16 lb_zip                   <chr>   155 0.00693  
    ## 17 lb_represent_govs_office <chr>   152 0.00680  
    ## 18 lb_executive_branch      <chr>   152 0.00680  
    ## 19 lb_legislative_branch    <chr>   152 0.00680  
    ## 20 lb_comments              <chr> 21975 0.983    
    ## 21 lb_address_clean         <chr>   152 0.00680  
    ## 22 lb_zip5                  <chr>   397 0.0178   
    ## 23 lb_state_clean           <chr>   217 0.00970  
    ## 24 lb_city_clean            <chr>   171 0.00765

## Export

``` r
clean_dir <- here("ia", "lobbying", "data", "processed")
dir_create(clean_dir)
ia_lobby %>% 
  na_if("NULL") %>% 
  write_csv(
    path = glue("{clean_dir}/ia_lobby_reg_clean.csv"),
    na = ""
  )
```
