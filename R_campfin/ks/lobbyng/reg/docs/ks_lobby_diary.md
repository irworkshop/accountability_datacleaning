Kansas Lobbyists
================
Kiernan Nicholls
2019-10-23 14:45:30

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
raw_dir <- here("ks", "lobbyng", "reg", "data", "raw")
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
  mutate(client = "")
```

As you can see, the clients of each lobbyist are not listed as a
separate column, but are instead listed as in the first `name` *under*
each lobbyist.

``` r
kslr
#> # A tibble: 2,648 x 7
#>    name        addr_1_addr_2      city_state_zip     phone      fax        email_address     client
#>    <chr>       <chr>              <chr>              <chr>      <chr>      <chr>             <chr> 
#>  1 ALDERSON, … 2101 S.W. 21ST ST… TOPEKA, KS 66604   (785) 232… (785) 232… boba@aldersonlaw… ""    
#>  2 * CASEY'S … * CASEY'S GENERAL… * CASEY'S GENERAL… * CASEY'S… * CASEY'S… * CASEY'S GENERA… ""    
#>  3 * KANSAS M… * KANSAS MANUFACT… * KANSAS MANUFACT… * KANSAS … * KANSAS … * KANSAS MANUFAC… ""    
#>  4 * ONE CALL… * ONE CALL CONCEP… * ONE CALL CONCEP… * ONE CAL… * ONE CAL… * ONE CALL CONCE… ""    
#>  5 <NA>        <NA>               <NA>               <NA>       <NA>       <NA>              ""    
#>  6 ALLEN, SHI… 5317 SW 11TH TER.  TOPEKA, KS 66604   (785) 633… <NA>       sallen5948@outlo… ""    
#>  7 * KRITC     * KRITC            * KRITC            * KRITC    * KRITC    * KRITC           ""    
#>  8 <NA>        <NA>               <NA>               <NA>       <NA>       <NA>              ""    
#>  9 ANDERSON, … 2910 SW TOPEKA BO… TOPEKA, KS 66611   (778) 267… (785) 267… leslie@k4ad.org   ""    
#> 10 * KANSAS A… * KANSAS ASSOCIAT… * KANSAS ASSOCIAT… * KANSAS … * KANSAS … * KANSAS ASSOCIA… ""    
#> # … with 2,638 more rows
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
    remove = FALSE
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
prop_in(kslr$city_sep, valid_city)
#> [1] 0.9667969
prop_in(kslr$state_sep, valid_state)
#> [1] 0.9980469
prop_in(kslr$zip_sep, valid_zip)
#> [1] 0.9550781
```

## Explore

``` r
head(kslr)
#> # A tibble: 6 x 10
#>   name   addr_1_addr_2  city_state_zip city_sep state_sep zip_sep phone fax   email_address client 
#>   <chr>  <chr>          <chr>          <chr>    <chr>     <chr>   <chr> <chr> <chr>         <chr>  
#> 1 ALDER… 2101 S.W. 21S… TOPEKA, KS 66… TOPEKA   KS        66604   (785… (785… boba@alderso… CASEY'…
#> 2 ALDER… 2101 S.W. 21S… TOPEKA, KS 66… TOPEKA   KS        66604   (785… (785… boba@alderso… KANSAS…
#> 3 ALDER… 2101 S.W. 21S… TOPEKA, KS 66… TOPEKA   KS        66604   (785… (785… boba@alderso… ONE CA…
#> 4 ALLEN… 5317 SW 11TH … TOPEKA, KS 66… TOPEKA   KS        66604   (785… <NA>  sallen5948@o… KRITC  
#> 5 ANDER… 2910 SW TOPEK… TOPEKA, KS 66… TOPEKA   KS        66611   (778… (785… leslie@k4ad.… KANSAS…
#> 6 ANGLE… 455 SE GOLF P… TOPEKA, KS 66… TOPEKA   KS        66605   (785… <NA>  scott@kacap.… KANSAS…
tail(kslr)
#> # A tibble: 6 x 10
#>   name   addr_1_addr_2  city_state_zip  city_sep state_sep zip_sep phone fax   email_address client
#>   <chr>  <chr>          <chr>           <chr>    <chr>     <chr>   <chr> <chr> <chr>         <chr> 
#> 1 YOUNG… 800 SW JACKSON TOPEKA, KS 666… TOPEKA   KS        66612   (785… (785… jyounger@kap… KAPA-…
#> 2 ZAKOU… 7400 WEST 110… OVERLAND PARK,… OVERLAN… KS        66210   (913… (913… jim@smizak-l… KANSA…
#> 3 ZALEN… 1038 LAKE VIK… ALTAMONT, MO 6… ALTAMONT MO        64620   (913… <NA>  szalensk@its… JOHNS…
#> 4 ZEHR,… 217 SE 8TH AVE TOPEKA, KS 666… TOPEKA   KS        66603   (785… (785… debra@leadin… LEADI…
#> 5 ZENZ,… 1 EMBARCADERO… SAN FRANCISCO,… SAN FRA… CA        941113… (415… (973… lobbying@pru… QMA L…
#> 6 ZIMME… 1540 SW 23RD … TOPEKA, KS 666… TOPEKA   KS        66611   (816… <NA>  zjeff53@yaho… CBD A…
glimpse(sample_frac(kslr))
#> Observations: 1,536
#> Variables: 10
#> $ name           <chr> "LAFAVER, JEREMY J", "HUMMELL, JON", "BUTLER, MICHELLE R", "JASKINIA, ED"…
#> $ addr_1_addr_2  <chr> "7200 MADISON AVE", "3929 SW AMBASSADOR PL.", "212 SW EIGHTH AVENUE, SUIT…
#> $ city_state_zip <chr> "KANSAS CITY, MO 64114", "TOPEKA, KS 66610", "TOPEKA, KS 66603", "KANSAS …
#> $ city_sep       <chr> "KANSAS CITY", "TOPEKA", "TOPEKA", "KANSAS CITY", "LAWRENCE", "TOPEKA", "…
#> $ state_sep      <chr> "MO", "KS", "KS", "KS", "KS", "KS", "KS", "KS", "KS", "KS", "MO", "IN", "…
#> $ zip_sep        <chr> "64114", "66610", "66603", "66112", "66049", "66612", "66603", "66603", "…
#> $ phone          <chr> "(816) 654-3666", "(785) 409-8836", "(785) 233-1903", "(913) 207-0567", "…
#> $ fax            <chr> NA, NA, "(785) 233-3518", NA, NA, NA, "(785) 354-4374", NA, NA, "(866) 58…
#> $ email_address  <chr> "jeremylafaver@gmail.com", "jhummell@lexialearning.com", "mbutler@kansass…
#> $ client         <chr> "BIRD RIDES INC Term Date: 3/1/2019", "ROSETTA STONE/LEXIA LEARNING INC."…
```

``` r
glimpse_fun(kslr, count_na)
#> # A tibble: 10 x 4
#>    col            type      n     p
#>    <chr>          <chr> <dbl> <dbl>
#>  1 name           chr       0 0    
#>  2 addr_1_addr_2  chr       0 0    
#>  3 city_state_zip chr       0 0    
#>  4 city_sep       chr       0 0    
#>  5 state_sep      chr       0 0    
#>  6 zip_sep        chr       0 0    
#>  7 phone          chr       0 0    
#>  8 fax            chr     744 0.484
#>  9 email_address  chr       0 0    
#> 10 client         chr       0 0
```
