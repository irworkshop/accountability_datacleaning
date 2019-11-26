Iowa Expenditures
================
Kiernan Nicholls
2019-07-29 17:22:45

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
  - [Conclude](#conclude)
  - [Export](#export)

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
pacman::p_load(
  stringdist, # levenshtein value
  tidyverse, # data manipulation
  lubridate, # datetime strings
  RSocrata, # read SODA api
  magrittr, # pipe opperators
  janitor, # dataframe clean
  zipcode, # clean & database
  scales, # format strings
  knitr, # knit documents
  glue, # combine strings
  here, # relative storage
  fs # search storage 
)
```

The IRW’s `campfin` package will also have to be installed from GitHub.
This package contains functions custom made to help facilitate the
processing of campaign finance data.

``` r
pacman::p_load_current_gh("kiernann/campfin")
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
# where dfs this document knit?
here::here()
#> [1] "/home/ubuntu/R/accountability_datacleaning/R_campfin"
```

## Data

[Data](https://data.iowa.gov/Campaigns-Elections/Iowa-Campaign-Expenditures/3adi-mht4)
is obtained from the Iowa Ethics & Campaign Disclosure Board’s open data
portal.

> This dataset contains information on expenditures made by state-wide,
> legislative or local candidate committees, state PACs, county central
> committees, state parties, and state and local ballot issue committees
> in Iowa. Data is available beginning in 2003 for all reports filed
> electronically, and some paper filed reports. Data is provided through
> reports submitted by candidate committees, state political committees,
> federal/out-of-state political committees, county central committees,
> ballot issue committees and organizations making contributions or
> independent expenditures. Quality of the data provided in the dataset
> is dependent upon the accuracy of the data reported electronically.

## Import

The data can be directly read using `RSocrata::read.socrata()`.

``` r
ia <- as_tibble(read.socrata("https://data.iowa.gov/resource/3adi-mht4.json"))
ia$amount <- as.double(ia$amount)
```

## Explore

``` r
head(ia)
```

    #> # A tibble: 6 x 15
    #>   transaction_id date                committee_cd committee_nm rec_committee_cd organization_nm
    #>   <chr>          <dttm>              <chr>        <chr>        <chr>            <chr>          
    #> 1 {29060620-251… 2006-06-29 00:00:00 6087         Iowa Teleco… 1338             Danielson Work…
    #> 2 {06010620-021… 2005-11-02 00:00:00 13583        Mahrt for M… <NA>             KDSN Radio     
    #> 3 {19070420-261… 2004-07-12 00:00:00 1567         Drury for I… <NA>             KLMJ Radio     
    #> 4 {27090320-431… 2003-09-27 00:00:00 679          Larson for … <NA>             Republican Par…
    #> 5 {14060420-500… 2004-03-23 00:00:00 9042         Clayton Cou… <NA>             <NA>           
    #> 6 {17070420-120… 2004-06-02 00:00:00 1513         Sands for S… <NA>             Wells Fargo Ba…
    #> # … with 9 more variables: address_line_1 <chr>, city <chr>, state_cd <chr>, zip <chr>,
    #> #   amount <dbl>, city_coordinates_zip <chr>, first_nm <chr>, last_nm <chr>, address_line_2 <chr>

``` r
tail(ia)
```

    #> # A tibble: 6 x 15
    #>   transaction_id date                committee_cd committee_nm rec_committee_cd organization_nm
    #>   <chr>          <dttm>              <chr>        <chr>        <chr>            <chr>          
    #> 1 {8EB9837A-3BD… 2012-10-23 00:00:00 9022         Butler Coun… <NA>             Bravo Printing 
    #> 2 {D4DF8EB8-24C… 2017-08-07 00:00:00 8035         Union Pacif… 1887             VANDER LINDEN …
    #> 3 {AA7771EB-D8C… 2017-03-31 00:00:00 14384        Hinzman For… <NA>             Facebook       
    #> 4 {DA1B101D-4D9… 2008-10-03 00:00:00 9161         REPUBLICAN … 0                <NA>           
    #> 5 {06F8CEFE-745… 2017-02-17 00:00:00 9098         Iowa Democr… <NA>             <NA>           
    #> 6 {D4730BCD-261… 2010-06-01 00:00:00 9041         Clay County… <NA>             Spencer Munici…
    #> # … with 9 more variables: address_line_1 <chr>, city <chr>, state_cd <chr>, zip <chr>,
    #> #   amount <dbl>, city_coordinates_zip <chr>, first_nm <chr>, last_nm <chr>, address_line_2 <chr>

``` r
glimpse(sample_frac(ia))
```

    #> Observations: 411,410
    #> Variables: 15
    #> $ transaction_id       <chr> "{C3562064-B845-4F6A-86A2-D3B0DE7AEF08}", "{17100620-3301-6045-1586…
    #> $ date                 <dttm> 2014-05-12, 2006-09-28, 2008-09-11, 2008-01-10, 2011-12-05, 2013-1…
    #> $ committee_cd         <chr> "2113", "1648", "9736", "9105", "6070", "21692", "5166", "14019", "…
    #> $ committee_nm         <chr> "Johnson for State House", "Wiskus for House", "Iowans For A Skille…
    #> $ rec_committee_cd     <chr> NA, NA, "1385", NA, "9098", NA, NA, NA, "9161", NA, NA, NA, NA, "91…
    #> $ organization_nm      <chr> "West Branch Communications Corp", "Bloomfield Democrat", "McCarthy…
    #> $ address_line_1       <chr> "108 1st St SW", "207 S. Madison St.", "5220 SE 31st Court", "509 S…
    #> $ city                 <chr> "Mount Vernon", "Bloomfield", "Des Moines", "Iowa City", "Des Moine…
    #> $ state_cd             <chr> "IA", "IA", "IA", "IA", "IA", "IA", "AZ", "IA", "IA", "IA", "IA", "…
    #> $ zip                  <chr> "52314", "52537", "50320", "52240", "50321", "52233", "85260", "502…
    #> $ amount               <dbl> 43.50, 831.60, 500.00, 65.00, 250.00, 29.91, 180.24, 100.00, 400.00…
    #> $ city_coordinates_zip <chr> "52314", "52537", "50320", "52240", "50321", "52233", "85260", "502…
    #> $ first_nm             <chr> NA, NA, NA, "Steven", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
    #> $ last_nm              <chr> NA, NA, NA, "Klienschmidt", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
    #> $ address_line_2       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "P.O. Box 973", NA, NA, NA,…

### Missing

The variables range in their degree of missing values. There are 0
missing values for variables like `transaction_id`, `date`, or `amount`.

``` r
glimpse_fun(ia, count_na)
```

    #> # A tibble: 15 x 4
    #>    var                  type       n       p
    #>    <chr>                <chr>  <int>   <dbl>
    #>  1 transaction_id       chr        0 0      
    #>  2 date                 dttm       0 0      
    #>  3 committee_cd         chr        0 0      
    #>  4 committee_nm         chr        0 0      
    #>  5 rec_committee_cd     chr   274709 0.668  
    #>  6 organization_nm      chr    62203 0.151  
    #>  7 address_line_1       chr     1858 0.00452
    #>  8 city                 chr      704 0.00171
    #>  9 state_cd             chr      678 0.00165
    #> 10 zip                  chr     1571 0.00382
    #> 11 amount               dbl        0 0      
    #> 12 city_coordinates_zip chr     4913 0.0119 
    #> 13 first_nm             chr   348355 0.847  
    #> 14 last_nm              chr   348353 0.847  
    #> 15 address_line_2       chr   388444 0.944

While there are 0 missing values for `committee_nm`, 15.1% of
`organization_nm` is missing. However, 15.3% of records *do* have a
`last_nm` value. We will flag any record without either an
`organization_nm` or `last_nm`.

``` r
ia <- mutate(ia, na_flag = is.na(organization_nm) & is.na(last_nm))
sum(ia$na_flag)
#> [1] 21
```

### Distinct

The variables also range in their degree of distinctness. We can see
that the `transaction_id` is 100% distinct and can be used to identify a
unique expenditure.

``` r
glimpse_fun(ia, n_distinct)
```

    #> # A tibble: 16 x 4
    #>    var                  type       n          p
    #>    <chr>                <chr>  <int>      <dbl>
    #>  1 transaction_id       chr   411410 1         
    #>  2 date                 dttm    5858 0.0142    
    #>  3 committee_cd         chr     4973 0.0121    
    #>  4 committee_nm         chr     5091 0.0124    
    #>  5 rec_committee_cd     chr     2709 0.00658   
    #>  6 organization_nm      chr    37642 0.0915    
    #>  7 address_line_1       chr    57406 0.140     
    #>  8 city                 chr     4171 0.0101    
    #>  9 state_cd             chr       56 0.000136  
    #> 10 zip                  chr     5800 0.0141    
    #> 11 amount               dbl    61334 0.149     
    #> 12 city_coordinates_zip chr     5738 0.0139    
    #> 13 first_nm             chr     4403 0.0107    
    #> 14 last_nm              chr     8714 0.0212    
    #> 15 address_line_2       chr     3029 0.00736   
    #> 16 na_flag              lgl        2 0.00000486

### Duplicates

There are no duplicate records.

``` r
ia_dupes <- get_dupes(ia)
nrow(ia_dupes)
#> [1] 0
```

### Ranges

For continuous variables, we should check the range and distribution of
values.

#### Amounts

The `amount` value ranges from $-100,000 to $1,800,000 with 2183 values
less than $0 (which typically indicates a correction). The mean
expenditure is has a value of $1,280.97, while the median is only
$179.56.

``` r
summary(ia$amount)
```

    #>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
    #> -100000.0      45.0     179.6    1281.0     500.0 1800000.0

``` r
sum(ia$amount < 0)
```

    #> [1] 2183

``` r
percent(mean(ia$amount < 0))
```

    #> [1] "0.531%"

![](../plots/amount_hist-1.png)<!-- -->

We can view the smallest and largest expenditures to see if these are
potentially typos.

``` r
glimpse(ia %>% filter(amount == min(amount)))
```

    #> Observations: 1
    #> Variables: 16
    #> $ transaction_id       <chr> "{F34CBA47-1F6D-4F8A-B3F4-BCA9331AF0A4}"
    #> $ date                 <dttm> 2008-06-27
    #> $ committee_cd         <chr> "5083"
    #> $ committee_nm         <chr> "Chet Culver Committee"
    #> $ rec_committee_cd     <chr> NA
    #> $ organization_nm      <chr> "Iowa Democratic Party"
    #> $ address_line_1       <chr> "5661 Fleur Drive"
    #> $ city                 <chr> "Des Moines"
    #> $ state_cd             <chr> "IA"
    #> $ zip                  <chr> "50321"
    #> $ amount               <dbl> -1e+05
    #> $ city_coordinates_zip <chr> "50321"
    #> $ first_nm             <chr> NA
    #> $ last_nm              <chr> NA
    #> $ address_line_2       <chr> NA
    #> $ na_flag              <lgl> FALSE

``` r
glimpse(ia %>% filter(amount == max(amount)))
```

    #> Observations: 1
    #> Variables: 16
    #> $ transaction_id       <chr> "{EEDE7329-FCAE-42FE-AB34-207DD7AA34B8}"
    #> $ date                 <dttm> 2018-10-22
    #> $ committee_cd         <chr> "8681"
    #> $ committee_nm         <chr> "RGA Right Direction PAC"
    #> $ rec_committee_cd     <chr> "5173"
    #> $ organization_nm      <chr> "Kim Reynolds for Iowa"
    #> $ address_line_1       <chr> "1010 A Park Lane"
    #> $ city                 <chr> "Osceola"
    #> $ state_cd             <chr> "IA"
    #> $ zip                  <chr> "50213"
    #> $ amount               <dbl> 1800000
    #> $ city_coordinates_zip <chr> "50213"
    #> $ first_nm             <chr> NA
    #> $ last_nm              <chr> NA
    #> $ address_line_2       <chr> NA
    #> $ na_flag              <lgl> FALSE

#### Dates

The ranges for `date` seem reasonable. There are 0 dates beyond
2019-07-29.

``` r
min(ia$date)
#> [1] "2001-09-23 EDT"
max(ia$date)
#> [1] "2019-02-07 EST"
sum(ia$date > today())
#> [1] 0
```

We can create a `year` variable to better explore and search the data,
using `lubridate::year()`

``` r
ia <- ia %>% 
  mutate(
    year = year(date),
    on_year = is_even(year)
  )
```

``` r
sum(ia$year == min(ia$year))
#> [1] 1
sum(ia$year == max(ia$year))
#> [1] 84
```

![](../plots/year_count_bar-1.png)<!-- -->

![](../plots/amount_year_bar-1.png)<!-- -->

``` r
ia %>% 
  mutate(month = month(date)) %>% 
  group_by(on_year, month) %>% 
  summarize(mean = mean(amount)) %>% 
  ggplot(aes(month, mean)) +
  geom_line(aes(color = on_year), size = 2) +
  scale_y_continuous(labels = dollar) +
  scale_x_continuous(labels = month.abb, breaks = 1:12) +
  scale_color_brewer(
    type = "qual",
    palette = "Dark2"
  ) +
  labs(
    title = "Iowa Expenditure Amount by Month",
    caption = "Source: IA ECDB",
    color = "Election Year",
    x = "Month",
    y = "Amount"
  )
```

![](../plots/amount_month_line-1.png)<!-- -->

## Wrangle

### Address

``` r
ia <- ia %>% 
  unite(
    col = address_comb,
    address_line_1, address_line_2,
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    address_norm = normal_address(
      address = address_comb,
      add_abbs = usps,
      na = c("", "NA"),
      na_rep = TRUE
    )
  )
```

``` r
ia %>% 
  select(
    address_line_1,
    address_line_2,
    address_norm
  ) %>% 
  sample_frac()
```

    #> # A tibble: 411,410 x 3
    #>    address_line_1     address_line_2 address_norm       
    #>    <chr>              <chr>          <chr>              
    #>  1 20 East 5th Street <NA>           20 EAST 5TH STREET 
    #>  2 105 So. Birch      <NA>           105 SO BIRCH       
    #>  3 717 7th St.        <NA>           717 7TH STREET     
    #>  4 40 Kings Way 401A  <NA>           40 KINGS WAY 401A  
    #>  5 201 S Locust St    <NA>           201 S LOCUST STREET
    #>  6 P.O. Box 382110    <NA>           PO BOX 382110      
    #>  7 429 Clarke Drive   <NA>           429 CLARKE DRIVE   
    #>  8 P.O. Box 279       <NA>           PO BOX 279         
    #>  9 P.O. Box 45950     <NA>           PO BOX 45950       
    #> 10 460 summit         <NA>           460 SUMMIT         
    #> # … with 411,400 more rows

### ZIP

``` r
n_distinct(ia$zip)
#> [1] 5800
prop_in(ia$zip, geo$zip)
#> [1] 0.9038622
sum(unique(ia$zip) %out% geo$zip)
#> [1] 2487
```

``` r
ia <- ia %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
n_distinct(ia$zip_norm)
#> [1] 3692
prop_in(ia$zip_norm, geo$zip)
#> [1] 0.997427
sum(unique(ia$zip_norm) %out% geo$zip)
#> [1] 260
```

### State

``` r
n_distinct(ia$state_cd)
#> [1] 56
prop_in(ia$state_cd, geo$state)
#> [1] 0.9978867
sum(unique(ia$state_cd) %out% geo$state)
#> [1] 5
```

``` r
ia <- ia %>% 
  mutate(
    state_norm = normal_state(
      state = str_replace(state_cd, "AI", "IA"),
      na_rep = TRUE,
      valid = geo$state
    )
  )
```

``` r
n_distinct(ia$state_norm)
#> [1] 52
prop_in(ia$state_norm, geo$state)
#> [1] 1
sum(unique(ia$state_norm) %out% geo$state)
#> [1] 1
```

### City

``` r
n_distinct(ia$city)
#> [1] 4171
prop_in(str_to_upper(ia$city), geo$city)
#> [1] 0.9653061
sum(unique(str_to_upper(ia$city)) %out% geo$city)
#> [1] 1183
```

### Normalize

``` r
ia <- ia %>% 
  mutate(
    city_norm = normal_city(
      city = city %>% str_replace("DesMoines", "Des Moines"),
      geo_abbs = usps_city,
      st_abbs = c("IA", "IOWA", "DC"),
      na = c("", "NA"),
      na_rep = TRUE
    )
  )
```

``` r
n_distinct(ia$city_norm)
#> [1] 2858
prop_in(str_to_upper(ia$city_norm), geo$city)
#> [1] 0.9849898
sum(unique(str_to_upper(ia$city_norm)) %out% geo$city)
#> [1] 957
```

``` r
ia %>% 
  filter(city_norm %out% geo$city) %>% 
  count(state_norm, city, city_norm, sort = TRUE)
```

    #> # A tibble: 1,129 x 4
    #>    state_norm city            city_norm           n
    #>    <chr>      <chr>           <chr>           <int>
    #>  1 IA         LeMars          LEMARS            678
    #>  2 <NA>       <NA>            <NA>              644
    #>  3 IA         NA              <NA>              616
    #>  4 IA         n/a             <NA>              444
    #>  5 IA         Hiawtha         HIAWTHA           392
    #>  6 <NA>       NA              <NA>              300
    #>  7 MA         West Somerville WEST SOMERVILLE   258
    #>  8 MA         Sommerville     SOMMERVILLE       242
    #>  9 <NA>       ---             <NA>              228
    #> 10 <NA>       --              <NA>              217
    #> # … with 1,119 more rows

### Swap

``` r
ia <- ia %>% 
  rename(city_raw = city) %>% 
  left_join(
    y = geo,
    by = c(
      "state_norm" = "state",
      "zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_dist = stringdist(city_norm, city_match),
    city_swap = if_else(
      condition = match_dist == 1,
      true = city_match,
      false = city_norm
    )
  )
```

``` r
n_distinct(ia$city_swap)
#> [1] 2147
prop_in(str_to_upper(ia$city_swap), geo$city)
#> [1] 0.9957818
sum(unique(str_to_upper(ia$city_swap)) %out% geo$city)
#> [1] 271
```

## Conclude

1.  There are 411410 records in the database.
2.  There are 0 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 21 records missing a recipient.
5.  Consistency in goegraphic data has been improved with
    `campfin::normal_*()`.
6.  The 5-digit `zip_norm` variable has been created with
    `campfin::normal_zip(ia$zip)`.
7.  The 4-digit `year` variable has been created with
    `lubridate::year(ia$date)`.

## Export

``` r
proc_dir <- here("ia", "expends", "data", "processed")
dir_create(proc_dir)
```

``` r
ia %>% 
  select(
    -state_cd,
    -city_raw,
    -zip,
    -city_match,
    -city_norm,
    -match_dist
  ) %>% 
  write_csv(
    path = glue("{proc_dir}/ia_expends_clean.csv"),
    na = ""
  )
```
