Maryland Lobbying Registration Diary
================
Yanqi Xu
2020-02-21 11:28:57

-   [Project](#project)
-   [Objectives](#objectives)
-   [Packages](#packages)
-   [Data](#data)
-   [Import](#import)
-   [Explore](#explore)
-   [Wrangle](#wrangle)
-   [Conclude](#conclude)
-   [Export](#export)

<!-- Place comments regarding knitting here -->
Project
-------

The Accountability Project is an effort to cut across data silos and give journalists, policy professionals, activists, and the public at large a simple way to search across huge volumes of public data about people and organizations.

Our goal is to standardizing public data on a few key fields by thinking of each dataset row as a transaction. For each transaction there should be (at least) 3 variables:

1.  All **parties** to a transaction.
2.  The **date** of the transaction.
3.  The **amount** of money involved.

Objectives
----------

This document describes the process used to complete the following objectives:

1.  How many records are in the database?
2.  Check for entirely duplicated records.
3.  Check ranges of continuous variables.
4.  Is there anything blank or missing?
5.  Check for consistency issues.
6.  Create a five-digit ZIP Code called `zip`.
7.  Create a `year` field from the transaction date.
8.  Make sure there is data on both parties to a transaction.

Packages
--------

The following packages are needed to collect, manipulate, visualize, analyze, and communicate these results. The `pacman` package will facilitate their installation and attachment.

The IRW's `campfin` package will also have to be installed from GitHub. This package contains functions custom made to help facilitate the processing of campaign finance data.

``` r
if (!require("pacman")) install.packages("pacman")
pacman::p_load_current_gh("irworkshop/campfin")
pacman::p_load(
  readxl, # read excel files
  rvest, # used to scrape website and get html elements
  tidyverse, # data manipulation
  stringdist, # calculate distances between strings
  lubridate, # datetime strings
  magrittr, # pipe opperators
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  httr, # http queries
  glue, # combine strings
  here, # relative storage
  fs # search storage 
)
```

This document should be run as part of the `R_campfin` project, which lives as a sub-directory of the more general, language-agnostic [`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning) GitHub repository.

The `R_campfin` project uses the [Rstudio projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects "Rproj") feature and should be run as such. The project also uses the dynamic `here::here()` tool for file paths relative to *your* machine.

``` r
# where does this document knit?
here::here()
#> [1] "/Users/soc/accountability/accountability_datacleaning/R_campfin"
```

Data
----

The current lobbyist data is available for download at [Maryland Ethics Commission](https://lobby-ethics.maryland.gov/public_access/current_lobbyist_list) for registrations after Nov. 2019. Data prior to Nov. 2019 has a different data structures (missing address fields), and can be accessed at a different [endpoint](https://lobby-ethics.maryland.gov/public_access?utf8=%E2%9C%93&filters%5Breport_type%5D=Registrations+for+Lobbying+Years+ending+October+31%2C+2019+and+earlier&filters%5Bdate_selection%5D=Lobbying+Year&filters%5Blr_lobbying_year%5D=&filters%5Blr_date_start%5D_date=&filters%5Blr_date_start%5D=&filters%5Blr_date_end%5D_date=&filters%5Blr_date_end%5D=&filters%5Bsearch_query%5D=&commit=Search).

Import
------

### Setting up Raw Data Directory

``` r
raw_dir <- dir_create(here("md", "lobby", "data", "raw", "reg"))
```

### Read

``` r
md_lob_reg <- read_csv(
  file = dir_ls(raw_dir, regexp = "Current.+")
) %>% clean_names()

md_lob_reg_early <- read_csv(
  file = dir_ls(raw_dir, regexp = "registrations+")
) %>% clean_names()
```

Explore
-------

``` r
head(md_lob_reg)
#> # A tibble: 6 x 10
#>   type  name_of_lobbyist organization organization_ad… office_phone direct_phone employer
#>   <chr> <chr>            <chr>        <chr>            <chr>        <chr>        <chr>   
#> 1 Indi… Abbruzzese, Ric… KO Public A… 111 South Calve… 410-685-7080 410-685-7080 Bird Ri…
#> 2 Indi… Abbruzzese, Ric… KO Public A… 111 South Calve… 410-685-7080 410-685-7080 Marylan…
#> 3 Indi… Abbruzzese, Ric… KO Public A… 111 South Calve… 410-685-7080 410-685-7080 Pharmac…
#> 4 Indi… Abbruzzese, Ric… KO Public A… 111 South Calve… 410-685-7080 410-685-7080 Share O…
#> 5 Indi… Abbruzzese, Ric… KO Public A… 111 South Calve… 410-685-7080 410-685-7080 Transou…
#> 6 Indi… Adams, Doug Fol… Capitol Str… 1 State Circle,… 410-268-3099 not availab… Capitol…
#> # … with 3 more variables: employer_address <chr>, reg_period_start <date>, reg_period_end <date>
tail(md_lob_reg)
#> # A tibble: 6 x 10
#>   type  name_of_lobbyist organization organization_ad… office_phone direct_phone employer
#>   <chr> <chr>            <chr>        <chr>            <chr>        <chr>        <chr>   
#> 1 Indi… Zektick, Barbara Alexander &… 54 State Circle… 410-974-9000 not availab… Sensus …
#> 2 Indi… Zektick, Barbara Alexander &… 54 State Circle… 410-974-9000 not availab… Sherwin…
#> 3 Indi… Zektick, Barbara Alexander &… 54 State Circle… 410-974-9000 not availab… Workday 
#> 4 Indi… Zellers, Susan   Marine Trad… P.O. Box 3148 ,… 410-269-0741 not availab… Marine …
#> 5 Indi… Zinsmeister, Ro… Associated … 6901 Muirkirk M… 301-595-9711 301-595-9711 Associa…
#> 6 Indi… Zwerling, Saman… Maryland St… 140 Main Street… 410-263-6600 443-433-3671 Marylan…
#> # … with 3 more variables: employer_address <chr>, reg_period_start <date>, reg_period_end <date>
glimpse(sample_n(md_lob_reg, 20))
#> Observations: 20
#> Variables: 10
#> $ type                 <chr> "Individual Registrant", "Individual Registrant", "Individual Regis…
#> $ name_of_lobbyist     <chr> "Favazza, John F", "Sidh, Sushant", "Pounds, Eddie L.", "Silverman,…
#> $ organization         <chr> "Manis Canning & Associates", "Capitol Strategies, LLC", "O'Malley,…
#> $ organization_address <chr> "12 Francis Street, Annapolis, MD, 21401", "1 State Circle , Annapo…
#> $ office_phone         <chr> "410-263-7882", "410-268-3099", "301-572-7900", "301-529-7996", "41…
#> $ direct_phone         <chr> "not available", "not available", "not available", "301-529-7996", …
#> $ employer             <chr> "Toyota Motor North America, Inc.", "MGT of America Consulting, LLC…
#> $ employer_address     <chr> "601 Thirteenth Street, NW, 910 South, Washington, DC, 20005", "380…
#> $ reg_period_start     <date> 2020-01-20, 2020-01-27, 2019-11-01, 2020-02-03, 2019-11-01, 2020-0…
#> $ reg_period_end       <date> 2020-10-31, 2020-10-31, 2020-10-31, 2020-10-31, 2020-10-31, 2020-1…

head(md_lob_reg_early)
#> # A tibble: 6 x 5
#>   form_id lobbyist_registrant     organization_firm       employer                 registration_pe…
#>   <chr>   <chr>                   <chr>                   <chr>                    <chr>           
#> 1 LR43103 MD Women's Coalition f… MD Women's Coalition f… MD Women's Coalition fo… 11/01/15-10/31/…
#> 2 LR54547 Aanenson, Karalyn       The Artemis Group, LLC  Food & Friends           01/08/16-04/30/…
#> 3 LR54642 Aanenson, Karalyn       The Artemis Group, LLC  Maryland Dental Hygieni… 01/13/16-04/30/…
#> 4 LR44211 Aanenson, Karalyn       Community Law in Action Community Law in Action  11/30/15-10/31/…
#> 5 LR41171 Abban, Gerald           Fidelity Brokerage Ser… Fidelity Brokerage Serv… 11/01/15-10/31/…
#> 6 LR55082 Abbruzzese, Rick        KOFA Public Affairs LLC Strategic Elements LLC … 03/01/16-10/31/…
tail(md_lob_reg_early)
#> # A tibble: 6 x 5
#>   form_id  lobbyist_registra… organization_firm employer                          registration_per…
#>   <chr>    <chr>              <chr>             <chr>                             <chr>            
#> 1 LR95520  Quinn, Brian M     Venable, LLP      Community Blight Solutions        09/01/16-10/31/16
#> 2 LR43318  Quinn, Brian M     Venable, LLP      Domtar Corporation                11/01/15-10/31/16
#> 3 LR43329  Quinn, Brian M     Venable, LLP      Maryland CASH Campaign / Job Opp… 11/01/15-10/31/16
#> 4 LR43337  Quinn, Brian M     Venable, LLP      AstraZeneca Pharmaceuticals, LP   11/01/15-10/31/16
#> 5 LR54486  Quinn, Brian M     Venable, LLP      Pew Charitable Trusts, The        01/01/16-10/31/16
#> 6 LR141348 Quinn, Brian M     Venable, LLP      AES Warrior Run                   11/01/17-10/31/18
glimpse(sample_n(md_lob_reg_early, 20))
#> Observations: 20
#> Variables: 5
#> $ form_id             <chr> "LR54938", "LR139846", "LR97290", "LR139782", "LR98082", "LR41286", …
#> $ lobbyist_registrant <chr> "Pica, Jr., John A", "Fesche, Camille G.", "Bryant, Eric L", "Cannin…
#> $ organization_firm   <chr> "Pica and Associates, LLC", "Alexander & Cleaver, P.A.", "Rifkin Wei…
#> $ employer            <chr> "HarborRock", "Center for Secure and Modern Elections", "Mid-Atlanti…
#> $ registration_period <chr> "02/19/16-04/12/16", "11/01/17-12/08/17", "11/01/16-10/31/17", "11/0…
```

### Missing

There are four records missing organizations. We will flag these entries with `flag_na()`.

``` r
col_stats(md_lob_reg, count_na)
#> # A tibble: 10 x 4
#>    col                  class      n       p
#>    <chr>                <chr>  <int>   <dbl>
#>  1 type                 <chr>      0 0      
#>  2 name_of_lobbyist     <chr>      0 0      
#>  3 organization         <chr>      4 0.00126
#>  4 organization_address <chr>      0 0      
#>  5 office_phone         <chr>      0 0      
#>  6 direct_phone         <chr>      0 0      
#>  7 employer             <chr>      0 0      
#>  8 employer_address     <chr>      0 0      
#>  9 reg_period_start     <date>     0 0      
#> 10 reg_period_end       <date>     0 0
col_stats(md_lob_reg_early, count_na)
#> # A tibble: 5 x 4
#>   col                 class     n        p
#>   <chr>               <chr> <int>    <dbl>
#> 1 form_id             <chr>     0 0       
#> 2 lobbyist_registrant <chr>     0 0       
#> 3 organization_firm   <chr>     6 0.000600
#> 4 employer            <chr>     0 0       
#> 5 registration_period <chr>     0 0
```

``` r
md_lob_reg <- md_lob_reg %>% flag_na(organization)
sum(md_lob_reg$na_flag)
#> [1] 4
md_lob_reg_early <- md_lob_reg_early %>% flag_na(organization_firm)
sum(md_lob_reg_early$na_flag)
#> [1] 6
```

### Duplicates

There isn't any duplicate column.

``` r
md_lob_reg <- flag_dupes(md_lob_reg, dplyr::everything())

md_lob_reg_early <- flag_dupes(md_lob_reg_early, dplyr::everything())
```

### Categorical

Since this registration is good for Oct 2019 to Oct. 2020, we will create a year column.

``` r
md_lob_reg <- md_lob_reg %>% 
  mutate(year = 2020L)
```

#### Dates

Since the registration period in the early file has a start and finish. We'll separate the column into two.

``` r
md_lob_reg_early <- md_lob_reg_early %>% 
  separate(col = registration_period, 
           sep = "-",
           into = c("reg_date","end_date"), remove = F)

min(md_lob_reg_early$reg_date)
#> [1] "01/01/16"
max(md_lob_reg_early$end_date)
#> [1] "12/31/18"
```

#### Year

We can add a year variable to the dataframe based on the registration date. Generally, if the registration date is later than Nov.01 of a year, the year active will be the majority of the next year.

``` r
md_lob_reg_early <- md_lob_reg_early %>% 
  mutate_at(.vars = vars(ends_with("date")), .funs = as.Date, format = "%m/%d/%y") %>% 
  mutate(year = if_else(condition = month(reg_date) < 10,
                        true = year(reg_date),
                        false = year(reg_date) +1 ))
```

![](../plots/year%20count-1.png)

Wrangle
-------

To improve the searchability of the database, we will perform some consistent, confident string normalization. For geographic variables like city names and ZIP codes, the corresponding `campfin::normal_*()` functions are taylor made to facilitate this process. \#\#\# Phone We can normalize the phone numbers.

``` r
md_lob_reg <- md_lob_reg %>% 
      mutate_at(.vars = vars(ends_with('phone')), .funs = list(norm = ~ normal_phone(.)))
```

### Address

We can see that the `address` variable is the full address including city, state and ZIP codes. We will separate them with regex.

``` r
md_lob_reg <- md_lob_reg %>% 
 mutate(organization_zip = str_extract(organization_address, "\\d{5}$"),
        organization_state = str_match(organization_address,
                                         "\\s([A-Z]{2}),\\s\\d{5}$")[,2])

count_na(md_lob_reg$organization_state)
#> [1] 0

md_lob_reg <- md_lob_reg %>% 
 mutate(organization_city = {str_remove(organization_address, "\\s[A-Z]{2},\\s\\d{5}$") %>% 
          str_match(",\\s(\\D[^,]+),$")}[,2],
        organization_address_sep = str_remove(organization_address, ",\\s(\\D[^,]+),\\s[A-Z]{2},\\s\\d{5}$")
          )
```

``` r
md_lob_reg <- md_lob_reg %>% 
  mutate(employer_zip = str_extract(employer_address, "\\d{5}$"),
         employer_state = str_match(employer_address,
                                        "\\s([A-Z]{2}),\\s\\d{5}$")[,2])

count_na(md_lob_reg$employer_state)
#> [1] 1

md_lob_reg <- md_lob_reg %>% 
  mutate(employer_city = {str_remove(employer_address, "\\s[A-Z]{2},\\s\\d{5}$") %>% 
      str_match(",\\s(\\D[^,]+),$")}[,2],
      employer_address_sep = str_remove(employer_address, ",\\s(\\D[^,]+),\\s[A-Z]{2},\\s\\d{5}$")
  )
```

For the street `addresss` variable, the `campfin::normal_address()` function will force consistence case, remove punctuation, and abbreviation official USPS suffixes.

``` r
md_lob_reg <-  md_lob_reg %>% 
    mutate_at(.vars = vars(ends_with('sep')), ~ normal_address(.,abbs = usps_street,
      na_rep = TRUE)) %>% 
  rename(employer_address_norm = employer_address_sep,
         organization_address_norm = organization_address_sep)
```

``` r
md_lob_reg %>% 
  select(contains("address")) %>% 
  distinct() %>% 
  sample_n(10)
#> # A tibble: 10 x 4
#>    organization_address        employer_address          organization_address_… employer_address_n…
#>    <chr>                       <chr>                     <chr>                  <chr>              
#>  1 12 Francis Street, Annapol… 1235 South Clark Street,… 12 FRANCIS ST          1235 S CLARK ST ST…
#>  2 15 School Street, Suite 30… 333 Lakeside Drive, Fost… 15 SCHOOL ST STE 300   333 LAKESIDE DR    
#>  3 c/o Unitarian Universalist… 333 Dubois Rd, Annapolis… CO UNITARIAN UNIVERSA… 333 DUBOIS RD      
#>  4 15 School Street 3rd Floor… 330 N. Howard Street, Ba… 15 SCHOOL ST 3 RD FL   330 N HOWARD ST    
#>  5 20 West Street , Annapolis… 550M Ritchie Hwy, Suite … 20 W ST                550 M RITCHIE HWY …
#>  6 29 Francis Street , Annapo… 8600 LaSalle Road, Suite… 29 FRANCIS ST          8600 LASALLE RD ST…
#>  7 41 State Circle Suite #2, … 2101 Webster St. Suite 1… 41 STATE CIR STE 2     2101 WEBSTER ST ST…
#>  8 1155 W. Rio Salado Parkway… 1155 W. Rio Salado Parkw… 1155 W RIO SALADO PKWY 1155 W RIO SALADO …
#>  9 638 5th Street NE, Washing… PO Box 8782, Silver Spri… 638 5 TH ST NE         PO BOX 8782        
#> 10 48 Maryland Avenue, Suite … 2273 Research Place, Sui… 48 MARYLAND AVE STE 4… 2273 RESEARCH PLAC…
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to create valied *five* digit codes by removing the ZIP+4 suffix and returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
prop_in(md_lob_reg$organization_zip, valid_zip, na.rm = T)
#> [1] 0.9996841
prop_in(md_lob_reg$employer_zip, valid_zip, na.rm = T)
#> [1] 0.9990521

md_lob_reg <- md_lob_reg %>% 
  mutate_at(.vars = vars(ends_with('zip')), .funs = list(norm = ~ normal_zip(.,
      na_rep = TRUE))) %>% 
  rename(organization_zip5 = organization_zip_norm,
         employer_zip5 = employer_zip_norm)

prop_in(md_lob_reg$organization_zip5, valid_zip, na.rm = T)
#> [1] 0.9996841
prop_in(md_lob_reg$employer_zip5, valid_zip, na.rm = T)
#> [1] 0.9993679
```

### State

After checking the percentage of state fields that are valid, we can see that these fields are clean.

``` r
prop_in(md_lob_reg$organization_state, valid_state, na.rm = T)
#> [1] 1
prop_in(md_lob_reg$employer_state, valid_state, na.rm = T)
#> [1] 1
```

### City

Cities are the most difficult geographic variable to normalize, simply due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting case, removing punctuation, but *expanding* USPS abbreviations. We can also remove `invalid_city` values.

``` r
prop_in(md_lob_reg$organization_city, valid_city, na.rm = T)
#> [1] 0.003820439
prop_in(md_lob_reg$employer_city, valid_city, na.rm = T)
#> [1] 0.005376344

md_lob_reg <- md_lob_reg %>% 
  mutate_at(.vars = vars(ends_with('city')), .funs = list(norm = ~ normal_city(.,abbs = usps_city,
                                                                               states = usps_state,
                                                                               na = invalid_city,
                                                                               na_rep = TRUE)))
prop_in(md_lob_reg$organization_city_norm, valid_city, na.rm = T)
#> [1] 0.9917224
prop_in(md_lob_reg$employer_city_norm, valid_city, na.rm = T)
#> [1] 0.944339
```

#### Swap

We can further improve normalization by comparing our normalized value against the *expected* value for that record's state abbreviation and ZIP code. If the normalized value is either an abbreviation for or very similar to the expected value, we can confidently swap those two.

``` r
md_lob_reg <- md_lob_reg %>% 
  left_join(
    y = zipcodes,
    by = c(
      "organization_state" = "state",
      "organization_zip5" = "zip"
    )
  ) %>% 
  rename(organization_city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(organization_city_norm, organization_city_match),
    match_dist = str_dist(organization_city_norm, organization_city_match),
    organization_city_swap = if_else(
      condition = !is.na(match_dist) & match_abb | match_dist == 1,
      true = organization_city_match,
      false = organization_city_norm
    )
  ) %>% 
  select(
    -organization_city_match,
    -match_dist,
    -match_abb
  )
```

``` r
md_lob_reg <- md_lob_reg %>% 
  left_join(
    y = zipcodes,
    by = c(
      "employer_state" = "state",
      "employer_zip5" = "zip"
    )
  ) %>% 
  rename(employer_city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(employer_city_norm, employer_city_match),
    match_dist = str_dist(employer_city_norm, employer_city_match),
    employer_city_swap = if_else(
      condition = !is.na(match_dist) & match_abb | match_dist == 1,
      true = employer_city_match,
      false = employer_city_norm
    )
  ) %>% 
  select(
    -employer_city_match,
    -match_dist,
    -match_abb
  )
```

After the two normalization steps, the percentage of valid cities is at 100%. \#\#\#\# Progress

| stage                    |  prop\_in|  n\_distinct|  prop\_na|  n\_out|  n\_diff|
|:-------------------------|---------:|------------:|---------:|-------:|--------:|
| organization\_city       |     0.004|          138|     0.008|    3129|      130|
| employer\_city           |     0.005|          359|     0.001|    3145|      353|
| organization\_city\_norm |     0.996|          121|     0.008|      11|        8|
| employer\_city\_norm     |     0.975|          327|     0.001|      78|       21|
| organization\_city\_swap |     0.999|          119|     0.009|       3|        3|
| employer\_city\_swap     |     0.992|          315|     0.010|      26|        6|

You can see how the percentage of valid values increased with each stage.

![](../plots/progress_bar-1.png)

More importantly, the number of distinct values decreased each stage. We were able to confidently change many distinct invalid values to their valid equivalent.

``` r
progress %>% 
  select(
    stage, 
    all = n_distinct,
    bad = n_diff
  ) %>% 
  mutate(good = all - bad) %>% 
  pivot_longer(c("good", "bad")) %>% 
  mutate(name = name == "good") %>% 
  ggplot(aes(x = stage, y = value)) +
  geom_col(aes(fill = name)) +
  scale_fill_brewer(palette = "Dark2", direction = -1) +
  scale_y_continuous(labels = comma) +
  theme(legend.position = "bottom") +
  labs(
    title = "MD City Normalization Progress",
    subtitle = "Distinct values, valid and invalid",
    x = "stage",
    y = "Percent Valid",
    fill = "Valid"
  )
```

![](../plots/distinct_bar-1.png)

Conclude
--------

``` r
glimpse(sample_n(md_lob_reg, 20))
#> Observations: 20
#> Variables: 28
#> $ type                      <chr> "Individual Registrant", "Individual Registrant", "Individual …
#> $ name_of_lobbyist          <chr> "Perry, Timothy  A", "Frome, Brad", "Hammen, Pete A", "McLaugh…
#> $ organization              <chr> "Perry White Ross & Jacobson", "Perry White Ross & Jacobson", …
#> $ organization_address      <chr> "125 Cathedral Street, Annapolis, MD, 21401", "125 Cathedral S…
#> $ office_phone              <chr> "410-919-8483", "410-919-8483", "443-321-9988", "410-919-8483"…
#> $ direct_phone              <chr> "443-739-9346", "240-354-1924", "443-332-9988", "410-271-6939"…
#> $ employer                  <chr> "Ernst & Young", "IWP (Injured Workers Pharmacy)", "Maryland A…
#> $ employer_address          <chr> "621 East Pratt Street, Baltimore, MD, 21202", "PO Box 338, Me…
#> $ reg_period_start          <date> 2019-11-01, 2019-11-01, 2019-12-13, 2019-11-01, 2020-01-07, 2…
#> $ reg_period_end            <date> 2020-10-31, 2020-10-31, 2020-10-31, 2020-10-31, 2020-10-31, 2…
#> $ na_flag                   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,…
#> $ year                      <int> 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 20…
#> $ office_phone_norm         <chr> "(410) 919-8483", "(410) 919-8483", "(443) 321-9988", "(410) 9…
#> $ direct_phone_norm         <chr> "(443) 739-9346", "(240) 354-1924", "(443) 332-9988", "(410) 2…
#> $ organization_zip          <chr> "21401", "21401", "21401", "21401", "21401", "21401", "21401",…
#> $ organization_state        <chr> "MD", "MD", "MD", "MD", "MD", "MD", "MD", "MD", "MD", "MD", "M…
#> $ organization_city         <chr> "Annapolis", "Annapolis", "annapolis", "Annapolis", "Annapolis…
#> $ organization_address_norm <chr> "125 CATHEDRAL ST", "125 CATHEDRAL ST", "92 MARKET ST", "125 C…
#> $ employer_zip              <chr> "21202", "01844", "21234", "20723", "21401", "21201", "21201",…
#> $ employer_state            <chr> "MD", "MA", "MD", "MD", "MD", "MD", "MD", "MD", "OH", "MD", "M…
#> $ employer_city             <chr> "Baltimore", "Methuen", "Baltimore", "Laurel", "Annapolis", "B…
#> $ employer_address_norm     <chr> "621 E PRATT ST", "PO BOX 338", "3601 E JOPPA RD", "9590 LYNN …
#> $ organization_zip5         <chr> "21401", "21401", "21401", "21401", "21401", "21401", "21401",…
#> $ employer_zip5             <chr> "21202", "01844", "21234", "20723", "21401", "21201", "21201",…
#> $ organization_city_norm    <chr> "ANNAPOLIS", "ANNAPOLIS", "ANNAPOLIS", "ANNAPOLIS", "ANNAPOLIS…
#> $ employer_city_norm        <chr> "BALTIMORE", "METHUEN", "BALTIMORE", "LAUREL", "ANNAPOLIS", "B…
#> $ organization_city_swap    <chr> "ANNAPOLIS", "ANNAPOLIS", "ANNAPOLIS", "ANNAPOLIS", "ANNAPOLIS…
#> $ employer_city_swap        <chr> "BALTIMORE", "METHUEN", "BALTIMORE", "LAUREL", "ANNAPOLIS", "B…
```

1.  There are 3166 records in the database.
2.  There's no duplicate record in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 4 records missing either recipient or date.
5.  Consistency in goegraphic data has been improved with `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with `lubridate::year()`.

Export
------

``` r
clean_dir <- dir_create(here("md", "lobby", "data", "reg","clean"))
```

``` r
write_csv(
  x = md_lob_reg %>% rename(employer_city_clean = employer_city_swap) %>% rename( organization_city_clean = organization_city_swap),
  path = path(clean_dir, "md_lob_reg_clean_current.csv"),
  na = ""
)

write_csv(
  x = md_lob_reg_early,
  path = path(clean_dir, "md_lob_reg_clean_16-19.csv"),
  na = ""
)
```
