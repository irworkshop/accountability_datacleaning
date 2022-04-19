Wisconsin Lobbying Data Diary
================
Yanqi Xu
2019-12-11 14:47:01

Project
-------

The Accountability Project is an effort to cut across data silos and give journalists, policy professionals, activists, and the public at large a simple way to search across huge volumes of public data about people and organizations.

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
#pacman::p_load_gh("irworkshop/campfin")
#uncooment the line above if you need to download IRW's package campfin from GitHub.
pacman::p_load(
  campfin, # wrangle campaign finance data
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

This document should be run as part of the `R_campfin` project, which lives as a sub-directory of the more general, language-agnostic [`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning "TAP repo") GitHub repository.

The `R_campfin` project uses the [RStudio projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects "Rproj") feature and should be run as such. The project also uses the dynamic `here::here()` tool for file paths relative to *your* machine.

``` r
# where dfs this document knit?
here::here()
## [1] "/Users/soc/accountability/accountability_datacleaning/R_campfin"
```

Download
--------

[WIS. STAT. § 13.64](https://docs.legis.wisconsin.gov/statutes/statutes/13/III/64) regulates lobbyists registration as such.

> “Lobbyist" means an individual who is employed by a principal, or contracts for or receives economic consideration, other than reimbursement for actual expenses, from a principal and whose duties include lobbying on behalf of the principal. If an individual's duties on behalf of a principal are not limited exclusively to lobbying, the individual is a lobbyist only if he or she makes lobbying communications on each of at least 5 days within a reporting period. An applicant for a license to act as a lobbyist may obtain an application from and file the application with the commission. The registration shall expire on December 31 of each even-numbered year.

> Every principal who makes expenditures or incurs obligations in an aggregate amount exceeding $500 in a calendar year for the purpose of engaging in lobbying which is not exempt under s. 13.621 shall, within 10 days after exceeding $500, cause to be filed with the commission a registration statement specifying the principal's name, business address, the general areas of legislative and administrative action which the principal is attempting to influence, the names of any agencies in which the principal seeks to influence administrative action, and information sufficient to identify the nature and interest of the principal.The registration shall expire on December 31 of each even-numbered year.

According to[WIS. STAT. § 13.62(10)](http://docs.legis.wisconsin.gov/statutes/statutes/13/III/62/10),

> Attempting to influence legislative or administrative action; • by oral or written communication; • with any elective state official, agency official or legislative employee; and • includes time spent in preparation for such communications and appearances at public hearings or meetings or service on a committee in which such preparation or communication occurs. Does not include seeking a contract or grant, or quasi-judicial decisions.

The [State of Wisconsin Ethics Commission](https://lobbying.wi.gov/Directories/DirectoryOfLicensedLobbyists/2019REG) makes available directories of lobbyists, principals (otehrwise known as lobbying organizations, any person who employs a lobbyist) and state agency officials (legislative liaisons) that lobbying for their agency.

Two sets of data were acquired, analyzed and processed: registration data and expenditure data. The Accountability Project obtained the Wisconsin lobbying registration and authorization data from the Wisconsin Ethics Commission from 2013 to 2019 through an open records request.In this diary, we specifically deal with the registration data.

> WIS. STAT. § 13.65. speicifies: Before engaging in lobbying on behalf of a principal, a lobbyist or the organization who employs a lobbyist shall file with the commission a written authorization for the lobbyist to represent the principal, signed by or on behalf of the principal. A lobbyist or principal shall file a separate authorization for each principal represented by a lobbyist. If an individual’s duties on behalf of the principal are exclusively limited to attempting to influence legislative or administrative action, the individual must be registered as a lobbyist and authorized to lobby on behalf of that principal prior to engaging in any lobbying communication. For these individuals, lobbying communication is not allowed before authorization.

> If an individual’s duties are not exclusively limited to attempting to influence legislative or administrative action, the individual must be registered as a lobbyist and authorized to lobby on behalf of that principal prior to her or his fifth day of lobbying communication. For these individuals, lobbying communication is permitted on four separate days before being required to obtain a lobbyist license and authorization from a principal.

> An organization employing a lobbyist for compensation in Wisconsin must do four things:
> 1) license its lobbyist(s),
> 2) register the lobbying principal,
> 3) authorize its lobbyist(s), and
> 4) pay all applicable fees.

Contract lobbyists authorization must be finished within a certain timeframe, according to \[WIS. STAT. § 13.75(d).\]\[<https://ethics.wi.gov/Resources/UnauthorizedLobbyingReport_20180111.pdf#page=3>\]:

> The written authorization requirement is satisfied through the Eye on Lobbying website (<https://lobbying.wi.gov>), as are all other registration and reporting requirements since the site’s launch in 2010. When a principal initially registers or subsequently amends their registration to update information they can give a licensed lobbyist authorization to lobby on their behalf. The Eye on Lobbying website also asks the principal to designate if the lobbyist is an in-house or contract lobbyist so that the correct types of expenditures can be reported by the principal. That same designation also determines precisely when a lobbyist must have their authorization. As stated above, contract lobbyists whose only duties on behalf of the principal are lobbying must be authorized before any lobbying communication while in-house lobbyists who commonly have other duties are not required to register until their fifth instance of communication. Instances of communication are not defined in statute, however in practice and in all relevant documentation the Commission treats dates as instances of communication. For example, an in-house lobbyist which is has not yet received their lobbyist license or principal authorization has eight hours of communication on November 15, one hour on November 16 and one phone call lasting 15 minutes on November 17. This would count as three instances of communication in terms of the four instance threshold. Wisconsin law also requires the payment of a $125 fee for each authorization.

In an email communication, a staff member of with the commission wrote:

> The WithdrawnDate column exists if the lobbyists authorization was ever removed. A “null” entry here means that the authorization was active from the AuthorizedDate until the end of the session (December 31 of the even numbered year). The Employer column the name of the organization that employs the lobbyist. In some cases, this is the same as the principal. However, when a lobbyist is employed by a lobbying firm then the name of the lobbying firm will be listed here.

> The WithdrawnDate column exists if the lobbyists authorization was ever removed. A “null” entry here means that the authorization was active from the AuthorizedDate until the end of the session (December 31 of the even numbered year). This dataset shows all lobbyist authorizations for the 2013, 2015, 2017 sessions, and the 2019 session as of today’s date (Oct 28, 2019).

Set the raw file directory first.

``` r
# create a directory for the raw data
reg_dir <- here("wi", "lobbyists", "data", "raw", "registration")
dir_create(reg_dir)
```

Reading
-------

The data obtained by the Investigative Reporting Workshop is an Excel spreasheet. The worksheet 1 contains all the records from 2013 to 2019.

``` r
wi_lobby <- read_xlsx(glue("{reg_dir}/wi_lobbyists.xlsx"), sheet = 1, col_types = "text") %>% 
  clean_names() %>% 
  mutate_if(is_character, str_to_upper) %>% 
  mutate(authorized_date = as.numeric(authorized_date))
  
  
wi_lobby <-  wi_lobby %>% mutate_at(.vars = vars(ends_with('date')),
                                    as.numeric) %>% 
                          mutate_at(.vars = vars(ends_with('date')),
                                    excel_numeric_to_date,date_system = "modern")
```

Duplicates
----------

We'll use the `flag_dupes()` function to see if there are records identical to one another and flag the duplicates. A new variable `dupe_flag` will be created.

``` r
wi_lobby <- flag_dupes(wi_lobby, dplyr::everything())
#Since no duplicate was present, we'll delete this column
wi_lobby <- wi_lobby %>% select(-dupe_flag)
```

Missing
-------

``` r
wi_lobby %>% col_stats(count_na)
```

    ## # A tibble: 21 x 4
    ##    col                       class      n        p
    ##    <chr>                     <chr>  <int>    <dbl>
    ##  1 principal                 <chr>      0 0       
    ##  2 principal_email           <chr>      0 0       
    ##  3 principal_mailing_address <chr>      0 0       
    ##  4 principal_mailing_city    <chr>      0 0       
    ##  5 principal_mailing_state   <chr>      0 0       
    ##  6 principal_mailing_zip     <chr>      0 0       
    ##  7 principal_phone1          <chr>      0 0       
    ##  8 lobbyist_first_name       <chr>      0 0       
    ##  9 lobbyist_last_name        <chr>      0 0       
    ## 10 licensed_date             <date>     5 0.000740
    ## 11 authorized_date           <date>     0 0       
    ## 12 withdrawn_date            <date>  5957 0.882   
    ## 13 surrendered_date          <date>  6437 0.953   
    ## 14 organization              <chr>      0 0       
    ## 15 lobbyist_email            <chr>      0 0       
    ## 16 lobbyist_address          <chr>      0 0       
    ## 17 lobbyist_city             <chr>      0 0       
    ## 18 lobbyist_state            <chr>      0 0       
    ## 19 lobbyist_zip              <chr>      0 0       
    ## 20 lobbyist_phone            <chr>      0 0       
    ## 21 legislative_session       <chr>      0 0

Few values are missing from the database.

Wrangle
-------

### Year

There are many dates involved, including `licensed_date`, `authorized_date`, `withdrawn_date` and `surrendered_date`. We'll use the year corresponding to the authorization date.

``` r
wi_lobby <- wi_lobby %>% 
  mutate(authorized_year = year(authorized_date))
```

### Phone

``` r
wi_lobby <- wi_lobby %>% 
  mutate_at(.vars = vars(contains('phone')),
            .funs = list(norm = ~normal_phone(.)))
```

### Address

### ZIP

Running the following commands tells us the zipcode fields are mostly clean.

``` r
wi_lobby %>% select(ends_with('zip')) %>% 
  map_dbl(prop_in, valid_zip, na.rm = TRUE) %>% map_chr(percent) %>% glimpse()
##  Named chr [1:2] "89%" "92%"
##  - attr(*, "names")= chr [1:2] "principal_mailing_zip" "lobbyist_zip"

wi_lobby <- wi_lobby %>% 
  mutate_at(.vars = vars(ends_with('zip')), .funs = list(norm = ~ normal_zip(.)))

wi_lobby %>% select(contains('zip')) %>% 
  map_dbl(prop_in, valid_zip, na.rm = TRUE) %>%  map_chr(percent)
##      principal_mailing_zip               lobbyist_zip principal_mailing_zip_norm 
##                      "89%"                      "92%"                      "99%" 
##          lobbyist_zip_norm 
##                     "100%"
```

### State

Running the following commands tells us the state fields are mostl clean.

``` r
wi_lobby %>% select(ends_with('state')) %>% 
  map_dbl(prop_in, valid_state, na.rm = TRUE) %>% map_chr(percent) %>% glimpse()
##  Named chr [1:2] "100%" "100%"
##  - attr(*, "names")= chr [1:2] "principal_mailing_state" "lobbyist_state"

wi_lobby <- wi_lobby %>% mutate(principal_mailing_state = normal_state(principal_mailing_state))
```

### City

The city field needs some work. We'll use the three-step cleaning method.

``` r
wi_lobby %>% select(ends_with('city')) %>% 
  map_dbl(prop_in, valid_city, na.rm = TRUE) %>% map_chr(percent) %>% glimpse()
##  Named chr [1:2] "96%" "98%"
##  - attr(*, "names")= chr [1:2] "principal_mailing_city" "lobbyist_city"

valid_place <- c(valid_city,extra_city)
```

#### Prep

``` r
wi_lobby <- wi_lobby %>% 
  mutate_at(.vars = vars(ends_with('city')),
            .funs = list(norm = ~ normal_city(city = .,abbs = usps_city,
                                            states = c(valid_state),
                                            na = invalid_city,
                                            na_rep = TRUE)))
wi_lobby %>% select(contains('city')) %>% 
  map_dbl(prop_in, valid_place, na.rm = TRUE) %>%  map_chr(percent)
##      principal_mailing_city               lobbyist_city principal_mailing_city_norm 
##                       "97%"                       "99%"                       "99%" 
##          lobbyist_city_norm 
##                       "99%"
```

#### Check

The `campfin` package uses the `check_city` function to check for misspelled cities by matching the returned results of the misspelled cities from the Google Maps Geocoding API. The function also pulls the clean city and place names in the `lobbyist_city_fetch` column for us to inspect and approve.

``` r
api_key <- Sys.getenv("GEOCODING_API")

wi_lobbyist_out <- wi_lobby %>% 
  filter(lobbyist_city_norm %out% valid_place) %>% 
  drop_na(lobbyist_city_norm,lobbyist_state) %>% 
  count(lobbyist_city_norm, lobbyist_state) 

wi_lobbyist_out <- wi_lobbyist_out %>% cbind(
  pmap_dfr(.l = list(wi_lobbyist_out$lobbyist_city_norm, wi_lobbyist_out$lobbyist_state), .f = check_city, key = api_key, guess = T))

valid_place_lb <-  c(wi_lobbyist_out$lobbyist_city_norm[wi_lobbyist_out$check_city_flag], valid_place) %>% unique()
```

``` r
wi_lobbyist_out <- wi_lobbyist_out %>% mutate(lobbyist_city_fetch = coalesce(guess_city, guess_place))

wi_lobby <- wi_lobbyist_out %>% 
  filter(!check_city_flag) %>% 
  select(lobbyist_city_norm, lobbyist_state, lobbyist_city_fetch) %>% 
  right_join(wi_lobby, by = c("lobbyist_city_norm","lobbyist_state")) 

wi_lobby <- wi_lobby %>% mutate(lobbyist_city_clean = coalesce(lobbyist_city_fetch, lobbyist_city_norm))

prop_in(wi_lobby$lobbyist_city, valid_place)
```

    ## [1] 0.9890435

``` r
prop_in(wi_lobby$lobbyist_norm, valid_place)
```

    ## [1] NaN

``` r
prop_in(wi_lobby$lobbyist_clean, valid_place_lb)
```

    ## [1] NaN

We then proceed to process using Google Maps Geocoding API to match cities.

``` r
wi_principal_out <- wi_lobby %>% 
  filter(principal_mailing_city_norm %out% valid_place) %>% 
  drop_na(principal_mailing_city_norm,principal_mailing_state) %>% 
  count(principal_mailing_city_norm, principal_mailing_state)

wi_principal_out <- wi_principal_out %>% cbind(
  pmap_dfr(.l = list(wi_principal_out$principal_mailing_city_norm, wi_principal_out$principal_mailing_city_norm), .f = check_city, key = api_key, guess = T))

valid_place_post <-  c(wi_principal_out$principal_mailing_city_norm[wi_principal_out$check_city_flag], valid_place_lb) %>% unique()
```

After manually inspecting the `wi_principal_out` table, we can make a confident switch.

``` r
wi_principal_out <- wi_principal_out %>% mutate(principal_mailing_city_fetch = coalesce(guess_city, guess_place))

wi_lobby <- wi_principal_out %>% 
  filter(!check_city_flag) %>% 
  select(principal_mailing_city_norm, principal_mailing_state,principal_mailing_city_fetch) %>% 
  right_join(wi_lobby, by = c("principal_mailing_city_norm","principal_mailing_state")) 

wi_lobby <- wi_lobby %>% mutate(principal_mailing_city_clean = coalesce(principal_mailing_city_fetch, principal_mailing_city_norm))

prop_in(wi_lobby$principal_mailing_city, valid_place)
```

    ## [1] 0.9749778

``` r
prop_in(wi_lobby$principal_mailing_norm, valid_place)
```

    ## [1] NaN

``` r
prop_in(wi_lobby$principal_mailing_clean, valid_place_post)
```

    ## [1] NaN

This is a very fast way to increase the valid lobbyist proportion to 100% and reduce the number of distinct *invalid* values from 24 to only 0. On the other hand, we increaesed the valid principal proportion to 99% and reduce the number of distinct *invalid* values from 49 to only 4.

| Data Type  | Normalization Stage | Percent Valid |  Total Distinct|  Unique Invalid|
|:-----------|:--------------------|:--------------|---------------:|---------------:|
| Lobbyists  | raw                 | 99%           |             192|              12|
| Lobbyists  | norm                | 99%           |             189|               6|
| Lobbyists  | clean               | 100%          |             185|               0|
| Principals | raw                 | 97%           |             367|              34|
| Principals | norm                | 99%           |             360|              23|
| Principals | clean               | 100%          |             354|               4|

Export
------

``` r
clean_reg_dir <- here("wi", "lobbyists", "data", "processed", "registration")

dir_create(clean_reg_dir)

wi_lobby %>% 
  select(-c(lobbyist_city_norm,
            lobbyist_city_fetch,
            principal_mailing_city_norm,
            principal_mailing_city_fetch)) %>% 
  write_csv(
    path = glue("{clean_reg_dir}/wi_lobbyists_reg.csv"),
    na = ""
  )
```
