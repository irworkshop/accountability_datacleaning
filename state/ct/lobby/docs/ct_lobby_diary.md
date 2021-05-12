Connecticut Lobbying Registration Data Diary
================
Yanqi Xu
2020-01-07 13:48:45

-   [Project](#project)
-   [Objectives](#objectives)
-   [Packages](#packages)
-   [Download](#download)
-   [Reading](#reading)
-   [Explore](#explore)
-   [Wrangling](#wrangling)
-   [Join](#join)
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
pacman::p_load_current_gh("irworkshop/campfin")
pacman::p_load(
  rvest, # read html tables
  httr, # interact with http requests
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

This document should be run as part of the `R_campfin` project, which lives as a sub-directory of the more general, language-agnostic \[`irworkshop/accountability_datacleaning`\]\[01\] GitHub repository.

The `R_campfin` project uses the \[RStudio projects\]\[02\] feature and should be run as such. The project also uses the dynamic `here::here()` tool for file paths relative to *your* machine.

Download
--------

Set the download directory first.

``` r
# create a directory for the raw data
raw_dir <- here("ct", "lobby", "data", "raw","reg")

dir_create(raw_dir)
```

According to [CT Office of State Ethics](https://www.oseapps.ct.gov/NewLobbyist/PublicReports/LobbyistFAQ.aspx),

> Lobbying in Connecticut is defined as "communicating directly or soliciting others to communicate with any official or his or her staff in the legislative or executive branch of government or in a quasi-public agency, for the purpose of influencing any legislative or administrative action."

Lobbyist terms:
&gt; A Client Lobbyist is the party paying for lobbying services on its behalf. In other words, the client lobbyist is expending or agreeing to expend the threshold amount of $3,000 in a calendar year. A Communicator Lobbyist receives payment and does the actual lobbying legwork (i.e., communicating or soliciting others to communicate).
&gt; A Communicator Lobbyist receives or agrees to receive $3,000 for lobbying activities in a calendar year. A communicator lobbyist can be:
1. An individual; or 2. A member of a Business Organization (e.g., a firm or association that is owned by or employs a number of lobbyists), Conn. Gen. Stat. § 1-91 (t); or 3. An In-house Communicator (a lobbyist who is a salaried employee of a client lobbyist).

Registration and Filing Specifics:

> Individuals or entities are required by law to register as a lobbyist with the Office of State Ethics (OSE) if they:
> 1. Expend or agree to expend $3,000 or more in a calendar year in lobbying; OR 2. Receive or agree to receive $3,000 or more in a calendar year in lobbying. Once the $3,000 threshold is met, registration with the OSE is required. Registration occurs biennially (every two years) by January 15, or prior to the commencement of lobbying, whichever is later.

Client Lobbyists:
&gt; 1. Client lobbyists file quarterly financial reports, with the third and fourth quarters combined. These reports are filed between the 1st and 10th days of April, July and January.
2. To ensure timely transparency, if a client lobbyist spends or agrees to spend more than $100 in legislative lobbying while the Legislature is in regular session, that lobbyist must file monthly financial reports.
3. The quarterly and monthly reports gather information such as compensation, sales tax and money expended in connection with lobbying; expenditures benefiting a public official or his/her staff or immediate family; all other lobbying expenditures; and the fundamental terms of any lobbying contract or agreement.

Communicator Lobbyists:
&gt; Communicator lobbyists also register upon meeting the threshold amount. Communicator lobbyists generally file a financial report once a year, due by January 10. These reports capture compensation, reimbursements from the client lobbyist and sales tax for the previous year.
If a communicator lobbyist makes unreimbursed expenditures of $10 or more for the benefit of a public official, a member of his/her staff, or his/her immediate family, that lobbyist must also file on the client lobbyists schedule (either monthly or quarterly).

This Rmd file documents the CT registration data only, whereas the expenditure data is wrangled in a separate data diary.

To generate a master dataset, we will need to download four kinds of data tables from [Office of State Ethics](https://www.oseapps.ct.gov/NewLobbyist/PublicReports/AdditionalReports.aspx), *Communicator Lobbyist List* for information about lobbyists, *All Registrants - Client* for information about clients, *Registration by Client, Communicator, Bus Org and Registration Date* for their relationships, as well as the *Combined Lobbyist List by Registrant with Type of Lobbying and Issues*. There will be overlapping and missing fields, but we will use the *Registration by Client, Communicator, Bus Org and Registration Date* as the base table since it captures the relationship between the lobbyists and their clients.

Reading
-------

We discovered that the xls files are actually structured as html tables. We'll use the `rvest` package to read these files.

``` r
ct_lob <- list.files(raw_dir, pattern = "Client.*", recursive = TRUE, full.names = TRUE) %>% 
  map_dfr(read_csv) %>% clean_names() %>% mutate_if(is.character, str_to_upper) %>% 
  mutate(street_address_2 = street_address_2 %>% na_if("-"))
  
ct_cl <- list.files(raw_dir, pattern = "ct_cl.*", recursive = TRUE, full.names = TRUE) %>% 
  map_dfr(read_csv, col_types = cols(.default = col_character())) %>% clean_names() %>% mutate_if(is.character, str_to_upper) 

ct_reg <- dir_ls(raw_dir, regexp = "reg_by") %>% 
  map_dfr(read_csv, col_types = cols(.default = col_character())) %>%  clean_names() %>% mutate_if(is.character, str_to_upper) %>% 
  mutate(business_organization = business_organization %>% na_if("-"))
```

### Columns

#### Year

Here we read everything as strings, and we will need to convert them back to numeric or datetime objects.

``` r
ct_reg <- ct_reg %>% mutate (registration_date = registration_date %>% as.Date(format = "%m/%d/%Y"),
                                       year = year(registration_date))
                             

ct_lob <- ct_lob %>% mutate (registration_date = registration_date %>% as.Date(format = "%m/%d/%Y"),
                                       year = year(registration_date))

ct_cl <- ct_cl %>% mutate(registration_date = registration_date %>% as.Date(format = "%m/%d/%Y"),
                          year = year(registration_date),
                          term_date = as.Date(term_date, format = "%m/%d/%Y"))
```

#### Name

We will replace the fields that said `1` for `communicator_name` and `comm_type` in `ct_reg` with `NA`s.

``` r
ct_reg <- ct_reg %>% mutate(communicator_status = str_match(communicator_name, " [(]TERMINATED: .+[)]") %>% 
                              str_remove("[(]") %>% str_remove("[)]"),
                            communicator_name_clean = str_remove(communicator_name,  " [(]TERMINATED: .+[)]"),
                            communicator_status = communicator_status %>% trimws())

ct_reg <- ct_reg %>% 
  mutate(first_name = str_match(communicator_name_clean, ",(.[^,]+$)")[,2],
         last_name = str_remove(communicator_name_clean, str_c(",",first_name)))

ct_reg <- ct_reg %>% 
  mutate(comm_type = na_if(x = comm_type, y = "1"),
         communicator_name = na_if(x = communicator_name, y = "1"))
```

Explore
-------

### Duplicates

We'll use the `flag_dupes()` function to see if there are records identical to one another and flag the duplicates. A new variable `dupe_flag` will be created.

``` r
ct_lob <- flag_dupes(ct_lob, dplyr::everything())
ct_cl <- flag_dupes(ct_cl, dplyr::everything())
ct_reg <- flag_dupes(ct_reg, dplyr::everything())
```

``` r
ct_reg %>% 
  group_by(year) %>% 
  ggplot(aes(year)) +
  scale_x_continuous(breaks = 2013:2019) +
  geom_bar(fill = RColorBrewer::brewer.pal(3, "Dark2")[1]) +
  labs(
    title = "Connecticut Lobbyists Registration by Year",
    caption = "Source: CT Office of State Ethics",
    x = "Year",
    y = "Count"
  )
```

![](../plots/unnamed-chunk-1-1.png)

### Missing

There's almost no empty fields in the two data frames.

``` r
ct_lob  %>% col_stats(count_na)
#> # A tibble: 14 x 4
#>    col               class      n     p
#>    <chr>             <chr>  <int> <dbl>
#>  1 last_name         <chr>      0 0    
#>  2 first_name        <chr>      0 0    
#>  3 street_address_1  <chr>      0 0    
#>  4 street_address_2  <chr>   2658 0.680
#>  5 city              <chr>      0 0    
#>  6 state             <chr>      0 0    
#>  7 zip               <chr>      0 0    
#>  8 email             <chr>      0 0    
#>  9 registration_date <date>     0 0    
#> 10 member_type       <chr>      0 0    
#> 11 status            <chr>   2926 0.749
#> 12 organisation_name <chr>      0 0    
#> 13 year              <dbl>      0 0    
#> 14 dupe_flag         <lgl>      0 0
ct_cl  %>% col_stats(count_na)
#> # A tibble: 13 x 4
#>    col               class      n        p
#>    <chr>             <chr>  <int>    <dbl>
#>  1 client_name       <chr>      0 0       
#>  2 address_1         <chr>      0 0       
#>  3 address_2         <chr>   3002 0.684   
#>  4 city              <chr>      0 0       
#>  5 state             <chr>      0 0       
#>  6 zip               <chr>      0 0       
#>  7 phone             <chr>      0 0       
#>  8 email             <chr>      0 0       
#>  9 registration_date <date>     1 0.000228
#> 10 term_date         <date>  4039 0.920   
#> 11 communicator_type <chr>   4392 1       
#> 12 year              <dbl>      1 0.000228
#> 13 dupe_flag         <lgl>      0 0
```

Few values are missing from the lobbyists database.

Wrangling
---------

We'll wrangle the two datasets to extract information such as address, city, ZIP, state, phone for both lobbyists and their clients, as well as authorization date. The lobbyists registry has the one-to-one relationship between lobbyists and clients, so we will use `ct_cl` as the main data frame and join the clients' information from the `ct_lob` data frame.

### Phone

``` r
ct_cl <- ct_cl %>% mutate(phone_norm = normal_phone(phone))
```

### Address

``` r
ct_cl <- ct_cl %>%
  unite(
  address_1,
  address_2,
  col = address_combined,
  sep = " ",
  remove = FALSE,
  na.rm = TRUE
  ) %>%
  mutate(address_clean = normal_address(
  address = address_combined,
  abbs = usps_city,
  na_rep = TRUE
  )) %>% 
  select(-address_combined)
  
  ct_lob <- ct_lob %>%
unite(
  street_address_1,
  street_address_2,
  col = address_combined,
  sep = " ",
  remove = FALSE,
  na.rm = TRUE
  ) %>% 
    mutate(address_clean = normal_address(
      address = address_combined,
  abbs = usps_city,
  na_rep = TRUE
  )) %>% 
    select(-address_combined)
```

### ZIP

The ZIP code fields are pretty clean.

``` r
prop_in(ct_cl$zip, valid_zip, na.rm = TRUE) %>% percent()
#> [1] "100%"
prop_in(ct_lob$zip, valid_zip, na.rm = TRUE) %>% percent()
#> [1] "100%"
```

### State

Running the following commands tells us the state fields are clean.

``` r
prop_in(ct_cl$state, valid_state, na.rm = TRUE) %>% percent()
#> [1] "100%"
prop_in(ct_lob$state, valid_state, na.rm = TRUE) %>% percent()
#> [1] "100%"
```

### City

The city fields in both data frames use upper-case letters and lower-case letters inconsistently. We'll convert everything to upper case.

``` r
prop_in(ct_cl$city, valid_city, na.rm = TRUE) %>% percent()
#> [1] "97%"
prop_in(ct_lob$city, valid_city, na.rm = TRUE) %>% percent()
#> [1] "99%"
```

#### Normalize

``` r
ct_cl <- ct_cl %>% mutate(city_norm = normal_city(city = city,
                                            abbs = usps_city,
                                            states = c(valid_state),
                                            na = invalid_city,
                                            na_rep = TRUE))
n_distinct(ct_cl$city)
#> [1] 465
n_distinct(ct_cl$city_norm)
#> [1] 461

prop_in(ct_cl$city, valid_city, na.rm = TRUE)
#> [1] 0.9749545
prop_in(ct_cl$city_norm, valid_city, na.rm = TRUE)
#> [1] 0.9806466
```

``` r
ct_lob <- ct_lob %>% mutate(city_norm = normal_city(city = city,
                                            abbs = usps_city,
                                            states = c(valid_state),
                                            na = invalid_city,
                                            na_rep = TRUE))
n_distinct(ct_lob$city)
#> [1] 237
n_distinct(ct_lob$city_norm)
#> [1] 235

prop_in(ct_lob$city, valid_city, na.rm = TRUE)
#> [1] 0.9938572
prop_in(ct_lob$city_norm, valid_city, na.rm = TRUE)
#> [1] 0.9959048
```

#### Swap

Then, we will compare these normalized `city_norm` values to the *expected* city value for that vendor's ZIP code. If the [levenshtein distance](https://en.wikipedia.org/wiki/Levenshtein_distance) is less than 3, we can confidently swap these two values.

``` r
ct_lob <- ct_lob %>% 
  left_join(
    y = zipcodes,
    by = c(
      "state" = "state",
      "zip" = "zip"
    )
  ) %>% 
  rename(city_match = city.y,
         city = city.x) %>% 
  mutate(
    match_abb = is_abbrev(city_norm, city_match),
    match_dist = str_dist(city_norm, city_match),
    city_swap = if_else(
      condition = match_abb | match_dist == 1,
      true = city_match,
      false = city_norm
    )
  ) %>% 
  select(
    -city_match,
    -match_dist,
    -match_abb
  )

prop_in(ct_lob$city_swap, valid_city, na.rm = TRUE) %>% percent()
#> [1] "100%"
```

``` r
ct_cl <- ct_cl %>% 
  left_join(
    y = zipcodes,
    by = c(
      "state" = "state",
      "zip" = "zip"
    )
  ) %>% 
  rename(city_match = city.y,
         city = city.x) %>% 
  mutate(
    match_abb = is_abbrev(city_norm, city_match),
    match_dist = str_dist(city_norm, city_match),
    city_swap = if_else(
      condition = match_abb | match_dist == 1,
      true = city_match,
      false = city_norm
    )
  ) %>% 
  select(
    -city_match,
    -match_dist,
    -match_abb
  )

prop_in(ct_cl$city_swap, valid_city, na.rm = TRUE) %>% percent()
#> [1] "99%"
```

Besides the `valid_city` vector, there is another vector of `extra_city` that contains other locales. We'll incorporate that in our comparison.

    #> # A tibble: 3 x 6
    #>   stage     prop_in n_distinct prop_na n_out n_diff
    #>   <chr>       <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 city        0.994        237 0          24     10
    #> 2 city_norm   0.996        235 0          15      6
    #> 3 city_swap   1            231 0.00282     0      1
    #> # A tibble: 3 x 6
    #>   stage     prop_in n_distinct prop_na n_out n_diff
    #>   <chr>       <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 city        0.978        465  0         95     37
    #> 2 city_norm   0.984        461  0         69     28
    #> 3 city_swap   0.996        447  0.0102    17      8

This is a very fast way to increase the valid proportion in the lobbyist data frame to 0% and reduce the number of distinct *invalid* values from 28 to only 8

Similarly, the valid proportion in the clients data frame was bumped up to 0% and reduce the number of distinct *invalid* values from 6 to only 1

Join
----

We'll join the two data frames together. Since there're no duplicate columns, we will delete the `dupe_flag` columns and add suffixes to each dataset's column names.

``` r
ct_cl$dupe_flag %>% tabyl()
#> # A tibble: 1 x 3
#>   .         n percent
#>   <lgl> <dbl>   <dbl>
#> 1 FALSE  4392       1
ct_lob$dupe_flag %>% tabyl()
#> # A tibble: 2 x 3
#>   .         n  percent
#>   <lgl> <dbl>    <dbl>
#> 1 FALSE  3906 1.000   
#> 2 TRUE      1 0.000256

ct_lob <- ct_lob %>% 
  filter(!dupe_flag) %>% 
  select(-c(dupe_flag,
            city_norm)) %>% 
  rename(city_clean = city_swap) %>% 
  rename_all(.funs = ~str_c("lobbyist_",.))

ct_cl <- ct_cl %>% 
  select(-c(city_norm, dupe_flag)) %>% 
  rename(city_clean = city_swap) %>% 
  rename_at(.vars = vars(-starts_with("client_"))
            ,.funs = ~ str_c("client_", .))

ct_cl <- ct_cl %>% flag_dupes(client_name, client_registration_date)
ct_lob <- ct_lob %>% flag_dupes(lobbyist_first_name, lobbyist_last_name, lobbyist_year, lobbyist_organisation_name)
```

After the join, we can see that all the clients' id information is accounted for. After the join, we can see the total numbers of NA columns are consistent, and we are not introducting extraneous entries. The numbers of NA columns are also consistent.

``` r
ct_reg <- ct_reg %>% select(-dupe_flag)

ct_reg <- ct_cl %>% 
  filter(!dupe_flag) %>% 
  right_join(ct_reg,
            by = c("client_name" = "client_name",
            "client_registration_date" = "registration_date"))

col_stats(ct_reg, count_na)
#> # A tibble: 25 x 4
#>    col                      class      n         p
#>    <chr>                    <chr>  <int>     <dbl>
#>  1 client_name              <chr>      0 0        
#>  2 client_address_1         <chr>      0 0        
#>  3 client_address_2         <chr>   8218 0.687    
#>  4 client_city              <chr>      0 0        
#>  5 client_state             <chr>      0 0        
#>  6 client_zip               <chr>      0 0        
#>  7 client_phone             <chr>      0 0        
#>  8 client_email             <chr>      0 0        
#>  9 client_registration_date <date>     1 0.0000836
#> 10 client_term_date         <date> 10931 0.914    
#> 11 client_communicator_type <chr>  11965 1        
#> 12 client_year              <dbl>      1 0.0000836
#> 13 client_phone_norm        <chr>      0 0        
#> 14 client_address_clean     <chr>      0 0        
#> 15 client_city_clean        <chr>    106 0.00886  
#> 16 dupe_flag                <lgl>      0 0        
#> 17 comm_type                <chr>   1877 0.157    
#> 18 communicator_name        <chr>   1877 0.157    
#> 19 business_organization    <chr>   3685 0.308    
#> 20 client_status            <chr>      0 0        
#> 21 year                     <dbl>      1 0.0000836
#> 22 communicator_status      <chr>  11060 0.924    
#> 23 communicator_name_clean  <chr>      0 0        
#> 24 first_name               <chr>   1877 0.157    
#> 25 last_name                <chr>   1877 0.157

ct_reg <- ct_reg %>% mutate(join = coalesce(business_organization, client_name))
  #the lobbyhist_organisation name usually reflects the business organization field in ct_reg, but corresponds to client_name when they are in-house lobbyists


ct_join<- ct_lob %>% 
  filter(!dupe_flag) %>% 
  select(-dupe_flag) %>%
  right_join(ct_reg,
            by = c( 'lobbyist_last_name' ='last_name',
                    'lobbyist_first_name' ='first_name',
                   'lobbyist_year' = 'year',
                   'lobbyist_organisation_name' = "join"))

col_stats(ct_join, count_na)
#> # A tibble: 37 x 4
#>    col                        class      n         p
#>    <chr>                      <chr>  <int>     <dbl>
#>  1 lobbyist_last_name         <chr>   1877 0.157    
#>  2 lobbyist_first_name        <chr>   1877 0.157    
#>  3 lobbyist_street_address_1  <chr>   2733 0.228    
#>  4 lobbyist_street_address_2  <chr>   9277 0.775    
#>  5 lobbyist_city              <chr>   2733 0.228    
#>  6 lobbyist_state             <chr>   2733 0.228    
#>  7 lobbyist_zip               <chr>   2733 0.228    
#>  8 lobbyist_email             <chr>   2733 0.228    
#>  9 lobbyist_registration_date <date>  2733 0.228    
#> 10 lobbyist_member_type       <chr>   2733 0.228    
#> 11 lobbyist_status            <chr>  10997 0.919    
#> 12 lobbyist_organisation_name <chr>      0 0        
#> 13 lobbyist_year              <dbl>      1 0.0000836
#> 14 lobbyist_address_clean     <chr>   2733 0.228    
#> 15 lobbyist_city_clean        <chr>   2743 0.229    
#> 16 client_name                <chr>      0 0        
#> 17 client_address_1           <chr>      0 0        
#> 18 client_address_2           <chr>   8218 0.687    
#> 19 client_city                <chr>      0 0        
#> 20 client_state               <chr>      0 0        
#> 21 client_zip                 <chr>      0 0        
#> 22 client_phone               <chr>      0 0        
#> 23 client_email               <chr>      0 0        
#> 24 client_registration_date   <date>     1 0.0000836
#> 25 client_term_date           <date> 10931 0.914    
#> 26 client_communicator_type   <chr>  11965 1        
#> 27 client_year                <dbl>      1 0.0000836
#> 28 client_phone_norm          <chr>      0 0        
#> 29 client_address_clean       <chr>      0 0        
#> 30 client_city_clean          <chr>    106 0.00886  
#> 31 dupe_flag                  <lgl>      0 0        
#> 32 comm_type                  <chr>   1877 0.157    
#> 33 communicator_name          <chr>   1877 0.157    
#> 34 business_organization      <chr>   3685 0.308    
#> 35 client_status              <chr>      0 0        
#> 36 communicator_status        <chr>  11060 0.924    
#> 37 communicator_name_clean    <chr>      0 0

sample_frac(ct_join)
#> # A tibble: 11,965 x 37
#>    lobbyist_last_n… lobbyist_first_… lobbyist_street… lobbyist_street… lobbyist_city lobbyist_state
#>    <chr>            <chr>            <chr>            <chr>            <chr>         <chr>         
#>  1 SHEA             TIMOTHY          185 ASYLUM STRE… 38TH FLOOR       HARTFORD      CT            
#>  2 ROSE             DAVID            <NA>             <NA>             <NA>          <NA>          
#>  3 GALLO            BETTY            227 LAWRENCE ST… <NA>             HARTFORD      CT            
#>  4 MCDONOUGH        DANIEL           737 NORTH MICHI… SUITE 1700       CHICAGO       IL            
#>  5 <NA>             <NA>             <NA>             <NA>             <NA>          <NA>          
#>  6 LUTZ             KATHERINE        21 OAK ST        SUITE 207        HARTFORD      CT            
#>  7 DUGAN            MICHAEL          23 VIOLA DRIVE   <NA>             EAST HAMPTON  CT            
#>  8 <NA>             <NA>             <NA>             <NA>             <NA>          <NA>          
#>  9 CRONIN           JEAN             700 PLAZA MIDDL… <NA>             MIDDLETOWN    CT            
#> 10 SULLIVAN         PATRICK          287 CAPITOL AVE… <NA>             HARTFORD      CT            
#> # … with 11,955 more rows, and 31 more variables: lobbyist_zip <chr>, lobbyist_email <chr>,
#> #   lobbyist_registration_date <date>, lobbyist_member_type <chr>, lobbyist_status <chr>,
#> #   lobbyist_organisation_name <chr>, lobbyist_year <dbl>, lobbyist_address_clean <chr>,
#> #   lobbyist_city_clean <chr>, client_name <chr>, client_address_1 <chr>, client_address_2 <chr>,
#> #   client_city <chr>, client_state <chr>, client_zip <chr>, client_phone <chr>,
#> #   client_email <chr>, client_registration_date <date>, client_term_date <date>,
#> #   client_communicator_type <chr>, client_year <dbl>, client_phone_norm <chr>,
#> #   client_address_clean <chr>, client_city_clean <chr>, dupe_flag <lgl>, comm_type <chr>,
#> #   communicator_name <chr>, business_organization <chr>, client_status <chr>,
#> #   communicator_status <chr>, communicator_name_clean <chr>
```

Export
------

``` r
clean_dir <- here("ct", "lobby", "data", "processed","reg")
dir_create(clean_dir)
ct_join %>% 
  select(-c(dupe_flag)) %>% 
  mutate_if(is.character, str_to_upper) %>% 
  write_csv(
    path = glue("{clean_dir}/ct_lobby_reg.csv"),
    na = ""
  )
```
