Kansas Lobbyists
================
Kiernan Nicholls
2020-01-21 10:29:09

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Wrangle](#wrangle)
  - [Explore](#explore)
  - [Export](#export)

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
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  magrittr, # pipe opperators
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  rvest, # scrape html pages
  glue, # combine strings
  here, # relative storage
  httr, # http queries
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

Data is obtained from the [Kansas Secretary of State’s
Office](https://sos.kansas.gov/).

As described on the SOS website:

> Lobbyists are required to register with the Secretary of State’s
> office if they meet the qualifications outlined in K.S.A. 46-222.
> Individuals who meet one of the following criteria in a calendar year
> must register as a lobbyist:
> 
>   - receives compensation to lobby;
>   - serves as the primary representative of an organization,
>     individual or other entity to lobby, regardless of whether
>     compensation is received; or
>   - expends a total of $100 or more for lobbying activities in a
>     calendar year.
> 
> For more information on lobbying activities in Kansas, please contact
> the Kansas Governmental Ethics Commission. For assistance with the
> Kansas Lobbyist Center, please contact the Elections Division at
> 785-296-4561.

## Import

We can use `httr::GET()` to query the [SOS lobbyist
directory](http://www.sos.ks.gov/elections/elections_lobbyists.html) and
scrape then scrape the HTML table that’s returned with
`rves::html_table()`.

``` r
url <- "http://www.kssos.org/elections/lobbyist_directory_display.aspx?"
response <- GET(url, query = list(SearchBy = "Lobbyist", LobbyYear = "2019"))
kslr <- content(response) %>% 
  html_node("table") %>% 
  html_table(fill = TRUE) %>% 
  as_tibble(.name_repair = make_clean_names)
```

Or, we can download the file manually and read it directly…

``` r
raw_dir <- here("ks", "lobby", "data", "raw")
dir_create(raw_dir)
```

``` r
kslr <- dir_ls(raw_dir, glob = "*.html$") %>% 
  read_html() %>% 
  html_node("table") %>% 
  html_table(fill = TRUE) %>% 
  as_tibble(.name_repair = make_clean_names) %>% 
  mutate_all(str_squish) %>% 
  na_if("") %>% 
  select(-starts_with("x")) %>% 
  mutate(client = "") %>% 
  mutate_at(vars(registration_date), parse_date, "%m/%d/%Y")
```

As you can see, the clients of each lobbyist are not listed as a
separate column, but are instead listed as in the first `name` *under*
each lobbyist.

``` r
kslr
#> # A tibble: 2,655 x 8
#>    name     addr_1_addr_2   city_state_zip   phone   fax     email_address  registration_da… client
#>    <chr>    <chr>           <chr>            <chr>   <chr>   <chr>          <date>           <chr> 
#>  1 ALDERSO… 2101 S.W. 21ST… TOPEKA, KS 66604 (785) … (785) … boba@alderson… 2018-11-02       ""    
#>  2 * CASEY… * CASEY'S GENE… * CASEY'S GENER… * CASE… * CASE… * CASEY'S GEN… NA               ""    
#>  3 * KANSA… * KANSAS MANUF… * KANSAS MANUFA… * KANS… * KANS… * KANSAS MANU… NA               ""    
#>  4 * ONE C… * ONE CALL CON… * ONE CALL CONC… * ONE … * ONE … * ONE CALL CO… NA               ""    
#>  5 <NA>     <NA>            <NA>             <NA>    <NA>    <NA>           NA               ""    
#>  6 ALLEN, … 5317 SW 11TH T… TOPEKA, KS 66604 (785) … <NA>    sallen5948@ou… 2018-12-27       ""    
#>  7 * KRITC  * KRITC         * KRITC          * KRITC * KRITC * KRITC        NA               ""    
#>  8 <NA>     <NA>            <NA>             <NA>    <NA>    <NA>           NA               ""    
#>  9 ANDERSO… 2910 SW TOPEKA… TOPEKA, KS 66611 (778) … (785) … leslie@k4ad.o… 2019-06-18       ""    
#> 10 * KANSA… * KANSAS ASSOC… * KANSAS ASSOCI… * KANS… * KANS… * KANSAS ASSO… NA               ""    
#> # … with 2,645 more rows
```

Looping from the bottom to top, we can check every row and attempt to
concatinate each client name into a new client column.

``` r
for (i in nrow(kslr):1) {
  if (is.na(kslr$name[i])) {
    next
  } else {
    if (str_sub(kslr$name[i], end = 1) == "*") {
      kslr$client[i-1] <- str_c(kslr$name[i], kslr$client[i], collapse = "#")
      kslr[i, 1:7] <- NA
    }
  }
}
```

Then, we can split this new column into a list-column and use
`tidyr::pivot_longer()` to create a new row for every client with the
lobbyist repeated in each row.

``` r
kslr <- kslr %>% 
  drop_na(name) %>% 
  mutate(client = client %>% str_remove("\\*\\s") %>% str_split("\\*\\s")) %>% 
  unnest_longer(client) %>% 
  distinct()
```

## Wrangle

The single `city_state_zip` needs to be separated into three columns
with `tidyr::separate()`.

``` r
kslr <- kslr %>% 
  separate(
    col = city_state_zip,
    into = c("city_sep", "state_zip"),
    sep = ",\\s",
    remove = TRUE
  ) %>% 
  separate(
    col = state_zip,
    into = c("state_sep", "zip_sep"),
    sep = "\\s",
    remove = TRUE
  )
```

From these three new columns, we can see almost all rows already contain
valid values.

``` r
prop_in(kslr$city_sep, c(valid_city, extra_city))
#> [1] 0.9974076
prop_in(kslr$state_sep, valid_state)
#> [1] 0.9980557
prop_in(kslr$zip_sep, valid_zip)
#> [1] 0.9552819
```

``` r
kslr <- kslr %>%
  rename(address = addr_1_addr_2) %>% 
  mutate_at(vars(address), normal_address, abbs = usps_street) %>% 
  mutate_at(vars(city_sep), normal_city, abbs = usps_city) %>% 
  mutate_at(vars(state_sep), normal_state, na_rep = TRUE) %>% 
  mutate_at(vars(zip_sep), normal_zip, na_rep = TRUE)
```

``` r
prop_in(kslr$city_sep, c(valid_city, extra_city))
#> [1] 0.9993519
prop_in(kslr$state_sep, valid_state)
#> [1] 0.9980557
prop_in(kslr$zip_sep, valid_zip)
#> [1] 1
```

## Explore

``` r
head(kslr)
#> # A tibble: 6 x 10
#>   name   address   city_sep state_sep zip_sep phone  fax    email_address registration_da… client  
#>   <chr>  <chr>     <chr>    <chr>     <chr>   <chr>  <chr>  <chr>         <date>           <chr>   
#> 1 ALDER… 2101 SOU… TOPEKA   KS        66604   (785)… (785)… boba@alderso… 2018-11-02       CASEY'S…
#> 2 ALDER… 2101 SOU… TOPEKA   KS        66604   (785)… (785)… boba@alderso… 2018-11-02       KANSAS …
#> 3 ALDER… 2101 SOU… TOPEKA   KS        66604   (785)… (785)… boba@alderso… 2018-11-02       ONE CAL…
#> 4 ALLEN… 5317 SOU… TOPEKA   KS        66604   (785)… <NA>   sallen5948@o… 2018-12-27       KRITC   
#> 5 ANDER… 2910 SOU… TOPEKA   KS        66611   (778)… (785)… leslie@k4ad.… 2019-06-18       KANSAS …
#> 6 ANGLE… 455 SOUT… TOPEKA   KS        66605   (785)… <NA>   scott@kacap.… 2018-12-20       KANSAS …
tail(kslr)
#> # A tibble: 6 x 10
#>   name   address   city_sep  state_sep zip_sep phone  fax    email_address registration_da… client 
#>   <chr>  <chr>     <chr>     <chr>     <chr>   <chr>  <chr>  <chr>         <date>           <chr>  
#> 1 YOUNG… 800 SOUT… TOPEKA    KS        66612   (785)… (785)… jyounger@kap… 2018-12-07       KAPA-K…
#> 2 ZAKOU… 7400 WES… OVERLAND… KS        66210   (913)… (913)… jim@smizak-l… 2019-07-08       KANSAS…
#> 3 ZALEN… 1038 LAK… ALTAMONT  MO        64620   (913)… <NA>   szalensk@its… 2018-11-20       JOHNSO…
#> 4 ZEHR,… 217 SOUT… TOPEKA    KS        66603   (785)… (785)… debra@leadin… 2018-10-08       LEADIN…
#> 5 ZENZ,… 1 EMBARC… SAN FRAN… CA        94111   (415)… (973)… lobbying@pru… 2018-10-05       QMA LLC
#> 6 ZIMME… 1540 SOU… TOPEKA    KS        66611   (816)… <NA>   zjeff53@yaho… 2019-03-21       CBD AM…
glimpse(sample_frac(kslr))
#> Observations: 1,543
#> Variables: 10
#> $ name              <chr> "DAMRON, WHITNEY B", "MURRAY, MICHAEL R", "STEPHAN, JOHN", "FEDERICO, …
#> $ address           <chr> "919 SOUTH KANSAS AVENUE", "100 SOUTHEAST 9TH STREET SUITE 503", "88 E…
#> $ city_sep          <chr> "TOPEKA", "TOPEKA", "COLUMBUS", "TOPEKA", "OLATHE", "TOPEKA", "SAN RAF…
#> $ state_sep         <chr> "KS", "KS", "OH", "KS", "KS", "KS", "CA", "MO", "KS", "KS", "KS", "KS"…
#> $ zip_sep           <chr> "66612", "66612", "43215", "66612", "66062", "66612", "94901", "64081"…
#> $ phone             <chr> "(785) 354-1354", "(785) 235-9000", "(614) 464-7475", "(785) 232-2557"…
#> $ fax               <chr> "(785) 354-8092", "(785) 235-9002", NA, "(785) 232-1703", NA, NA, "(41…
#> $ email_address     <chr> "wbdamron@gmail.com", "mikemurray@capitoladvantage.biz", "sstetson@mul…
#> $ registration_date <date> 2018-12-29, 2018-12-27, 2018-12-31, 2018-12-18, 2019-01-09, 2018-11-2…
#> $ client            <chr> "KANSAS GAS SERVICE", "CAPITOL ADVANTAGE LLC", "CGI TECHNOLOGIES Term …
```

``` r
col_stats(kslr, count_na)
#> # A tibble: 10 x 4
#>    col               class      n     p
#>    <chr>             <chr>  <int> <dbl>
#>  1 name              <chr>      0 0    
#>  2 address           <chr>      0 0    
#>  3 city_sep          <chr>      0 0    
#>  4 state_sep         <chr>      0 0    
#>  5 zip_sep           <chr>      0 0    
#>  6 phone             <chr>      0 0    
#>  7 fax               <chr>    748 0.485
#>  8 email_address     <chr>      0 0    
#>  9 registration_date <date>     0 0    
#> 10 client            <chr>      0 0
```

## Export

``` r
proc_dir <- here("ks", "lobby", "data", "processed")
dir_create(proc_dir)
write_csv(
  x = kslr,
  path = glue("{proc_dir}/ks_lobbyists.csv"),
  na = ""
)
```
