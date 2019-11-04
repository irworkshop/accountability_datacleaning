North Carolina Expenditures
================
Kiernan Nicholls
2019-11-04 16:11:01

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
  RSelenium, # remote browser
  lubridate, # datetime strings
  magrittr, # pipe opperators
  tidytext, # text analysis
  janitor, # dataframe clean
  batman, # parse logical
  refinr, # cluster and merge
  scales, # format strings
  rvest, # read html files
  knitr, # knit documents
  vroom, # read files fast
  glue, # combine strings
  here, # relative storage
  fs # search storage 
)
```

This document should be run as part of the `R_campfin` project, which
lives as a sub-directory of the more general, language-agnostic
\[`irworkshop/accountability_datacleaning`\]\[01\] GitHub repository.

The `R_campfin` project uses the \[RStudio projects\]\[02\] feature and
should be run as such. The project also uses the dynamic `here::here()`
tool for file paths relative to *your* machine.

``` r
# where does this document knit?
here::here()
#> [1] "/home/kiernan/R/accountability_datacleaning/R_campfin"
```

## Data

Data is obtained from the North Carolina State Board of Elections (NC
SBoE).

> The State Board of Elections (State Board) is the state agency charged
> with the administration of the elections process and campaign finance
> disclosure and compliance.

> The state’s Campaign Reporting Act applies to:
> 
>   - all candidates for public office;  
>   - all political party groups and political action committees;  
>   - all groups organized to support or oppose a referendum;  
>   - every person or group participating in activities that support or
>     oppose the nomination or  
>   - election of one or more clearly identified candidates, or a
>     political party or a referendum.

### Download

To download the data, perform a [Transaction Entity
Search](https://cf.ncsbe.gov/CFTxnLkup/) for type “Expenditure” from
2008-01-01 to 2019-11-04.

> This page allows for searching through the NC SBoE Campaign Finance
> database of transactions that committees have received (Receipts) or
> spent (Expenditures). Report data that is imported does not appear on
> our website in real-time. Our website updates overnight each
> weeknight. All data imported during a business day will appear on our
> website the following day.

``` r
raw_dir <- here("nc", "expends", "data", "raw")
dir_create(raw_dir) 
```

### Read

``` r
nc <- read_csv(
  file = glue("{raw_dir}/transinq_results.csv"),
  na = c("NA", "", "Not Available"),
  skip = 1,
  col_names = c(
    "payee_name",
    "payee_street1",
    "payee_street2",
    "payee_city",
    "payee_state",
    "payee_zip",
    "profession",
    "employer",
    "transction_type",
    "comm_name",
    "comm_id",
    "comm_street1",
    "comm_street2",
    "comm_city",
    "comm_state",
    "comm_zip",
    "report_name",
    "date",
    "account_code",
    "amount",
    "form_of_payment",
    "purpose",
    "referendum_name",
    "declaration",
    "supports"
  ),
  col_types = cols(
    .default = col_character(),
    date = col_date_usa(),
    amount = col_double()
  )
) %>% 
  mutate_if(is_character, str_to_upper) %>% 
  mutate(supports = equals(declaration, "SUPPORT"))
```

## Explore

``` r
head(nc)
```

    #> # A tibble: 6 x 25
    #>   payee_name payee_street1 payee_street2 payee_city payee_state payee_zip profession employer
    #>   <chr>      <chr>         <chr>         <chr>      <chr>       <chr>     <chr>      <chr>   
    #> 1 <NA>       1100 WATERMA… <NA>          RALEIGH    NC          27609     <NA>       <NA>    
    #> 2 <NA>       THE COMMITTE… <NA>          RALEIGH    NC          27611     <NA>       <NA>    
    #> 3 <NA>       3353 RIVER RD <NA>          COLUMBUS   NC          28722     <NA>       <NA>    
    #> 4 <NA>       PO BOX 2012   <NA>          RALEIGH    NC          27603     <NA>       <NA>    
    #> 5 <NA>       <NA>          <NA>          <NA>       <NA>        <NA>      <NA>       <NA>    
    #> 6 <NA>       <NA>          <NA>          <NA>       NE          <NA>      <NA>       <NA>    
    #> # … with 17 more variables: transction_type <chr>, comm_name <chr>, comm_id <chr>,
    #> #   comm_street1 <chr>, comm_street2 <chr>, comm_city <chr>, comm_state <chr>, comm_zip <chr>,
    #> #   report_name <chr>, date <date>, account_code <chr>, amount <dbl>, form_of_payment <chr>,
    #> #   purpose <chr>, referendum_name <chr>, declaration <chr>, supports <lgl>

``` r
tail(nc)
```

    #> # A tibble: 6 x 25
    #>   payee_name payee_street1 payee_street2 payee_city payee_state payee_zip profession employer
    #>   <chr>      <chr>         <chr>         <chr>      <chr>       <chr>     <chr>      <chr>   
    #> 1 ZWELI'S K… 4600 DURHAM … STE 26        DURHAM     NC          27707-26… <NA>       <NA>    
    #> 2 BARRY D Z… 5423 17TH AV… <NA>          BROOKLYN   NY          11204     EXECUTIVE  AMTRUST…
    #> 3 MICHAEL Z… 2754 COMMONW… <NA>          CHARLOTTE  NC          28205     FIELD ORG… GREEN P…
    #> 4 MICHAEL Z… 2754 COMMONW… <NA>          CHARLOTTE  NC          28205     FIELD ORG… GREEN P…
    #> 5 MICHAEL Z… 2754 COMMONW… <NA>          CHARLOTTE  NC          28205     FIELD ORG… GREEN P…
    #> 6 ZZZ        718 ATLANTIC… <NA>          ATLANTIC … NC          28512     <NA>       <NA>    
    #> # … with 17 more variables: transction_type <chr>, comm_name <chr>, comm_id <chr>,
    #> #   comm_street1 <chr>, comm_street2 <chr>, comm_city <chr>, comm_state <chr>, comm_zip <chr>,
    #> #   report_name <chr>, date <date>, account_code <chr>, amount <dbl>, form_of_payment <chr>,
    #> #   purpose <chr>, referendum_name <chr>, declaration <chr>, supports <lgl>

``` r
glimpse(sample_frac(nc))
```

    #> Observations: 631,559
    #> Variables: 25
    #> $ payee_name      <chr> "TAVERNA AGORA", "AGGREGATED NON-MEDIA EXPENDITURE", "MR. KEVIN DANIELS"…
    #> $ payee_street1   <chr> "326 HILLSBOROUGH ST", NA, "1903 LIVE OAK STREET", "PO BOX 20550", "200 …
    #> $ payee_street2   <chr> NA, NA, "#1009", NA, NA, NA, "BUILDING TWO", NA, NA, NA, "APT 381", NA, …
    #> $ payee_city      <chr> "RALEIGH", NA, "BEAUFORT", "ROHESTER", "WILSON", "NAGS HEAD", "DALLAS", …
    #> $ payee_state     <chr> "NC", NA, "NC", "NY", "NC", "NC", "TX", "NC", "NC", NA, "NC", "NC", NA, …
    #> $ payee_zip       <chr> "27603-1726", NA, "28516-7994", "14602", "27893", "27959-9998", "75254",…
    #> $ profession      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "AUDIT P…
    #> $ employer        <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "ERNST &…
    #> $ transction_type <chr> "OPERATING EXP", "OPERATING EXP", "OPERATING EXP", "OPERATING EXP", "OPE…
    #> $ comm_name       <chr> "PAUL LOWE FOR NC SENATE", "CATHERINE WHITEFORD FOR NC HOUSE", "NORTH CA…
    #> $ comm_id         <chr> "STA-R6XPTX-C-001", "STA-73EB7Q-C-001", "STA-C4184N-C-001", "STA-C1F0ED-…
    #> $ comm_street1    <chr> "P O BOX 20262", "6218 DIXON DRIVE", "PO BOX 12905", "P O BOX 13479", "P…
    #> $ comm_street2    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ comm_city       <chr> "WINSTON-SALEM", "RALEIGH", "RALEIGH", "DURHAM", "WILSON", "SOUTHERN SHO…
    #> $ comm_state      <chr> "NC", "NC", "NC", "NC", "NC", "NC", "NC", "NC", "NC", "NC", "NC", "NC", …
    #> $ comm_zip        <chr> "27120", "27609", "27605", "27709", "27893", "27949", "27601", "27615", …
    #> $ report_name     <chr> "2015 YEAR END SEMI-ANNUAL (AMENDMENT)", "2018 THIRD QUARTER (AMENDMENT)…
    #> $ date            <date> 2015-10-28, 2018-09-02, 2018-02-06, 2014-11-05, 2018-01-16, 2012-04-11,…
    #> $ account_code    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ amount          <dbl> 308.40, 18.13, 1000.00, 118.60, 195.00, 70.00, 106.55, 8500.00, 1000.00,…
    #> $ form_of_payment <chr> "DEBIT CARD", "DEBIT CARD", "CHECK", "CHECK", "CHECK", "CHECK", "DRAFT",…
    #> $ purpose         <chr> "CATERING FOR FUNDRAISER", "MEAL FOR VOLUNTEERS", NA, "TELEPHONE AND INT…
    #> $ referendum_name <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ declaration     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
    #> $ supports        <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …

### Missing

``` r
glimpse_fun(nc, count_na)
```

    #> # A tibble: 25 x 4
    #>    col             type       n        p
    #>    <chr>           <chr>  <dbl>    <dbl>
    #>  1 payee_name      chr      393 0.000622
    #>  2 payee_street1   chr   165695 0.262   
    #>  3 payee_street2   chr   591574 0.937   
    #>  4 payee_city      chr   153824 0.244   
    #>  5 payee_state     chr   132232 0.209   
    #>  6 payee_zip       chr   169894 0.269   
    #>  7 profession      chr   567057 0.898   
    #>  8 employer        chr   573582 0.908   
    #>  9 transction_type chr      672 0.00106 
    #> 10 comm_name       chr      672 0.00106 
    #> 11 comm_id         chr      672 0.00106 
    #> 12 comm_street1    chr      976 0.00155 
    #> 13 comm_street2    chr   588039 0.931   
    #> 14 comm_city       chr      672 0.00106 
    #> 15 comm_state      chr      672 0.00106 
    #> 16 comm_zip        chr      672 0.00106 
    #> 17 report_name     chr      672 0.00106 
    #> 18 date            date     672 0.00106 
    #> 19 account_code    chr   631559 1       
    #> 20 amount          dbl      680 0.00108 
    #> 21 form_of_payment chr    34135 0.0540  
    #> 22 purpose         chr    94658 0.150   
    #> 23 referendum_name chr   600332 0.951   
    #> 24 declaration     chr   600357 0.951   
    #> 25 supports        lgl   600357 0.951

There seems to be a regular block of records missing the variables
needed to properly identify a transaction. We can flag those
expenditures with `campfin::flag_na()`.

``` r
nc <- nc %>% flag_na(payee_name, comm_name, date, amount)
sum(nc$na_flag)
```

    #> [1] 756

``` r
percent(mean(nc$na_flag))
```

    #> [1] "0.120%"

### Duplicates

There are a fairly significant number of duplicate records in the
database. It’s possible for a committee to make multiple legitimate
expenditures to the same vendor, on the same day, for the same amount.
Still, we will flag these records with `campfin::dupe_flag()`.

``` r
nc <- flag_dupes(nc, everything())
sum(nc$dupe_flag)
```

    #> [1] 20074

``` r
percent(mean(nc$dupe_flag))
```

    #> [1] "3.18%"

### Categorical

We can check the distribution of categorical variables to gain a better
understanding as to what kind of expenditures are being made.

``` r
glimpse_fun(nc, n_distinct)
```

    #> # A tibble: 27 x 4
    #>    col             type       n          p
    #>    <chr>           <chr>  <dbl>      <dbl>
    #>  1 payee_name      chr    99439 0.157     
    #>  2 payee_street1   chr    89561 0.142     
    #>  3 payee_street2   chr     4359 0.00690   
    #>  4 payee_city      chr     4483 0.00710   
    #>  5 payee_state     chr       74 0.000117  
    #>  6 payee_zip       chr    16317 0.0258    
    #>  7 profession      chr     3742 0.00593   
    #>  8 employer        chr     6383 0.0101    
    #>  9 transction_type chr       10 0.0000158 
    #> 10 comm_name       chr     4150 0.00657   
    #> 11 comm_id         chr     4154 0.00658   
    #> 12 comm_street1    chr     3765 0.00596   
    #> 13 comm_street2    chr      183 0.000290  
    #> 14 comm_city       chr      547 0.000866  
    #> 15 comm_state      chr       36 0.0000570 
    #> 16 comm_zip        chr     1035 0.00164   
    #> 17 report_name     chr      297 0.000470  
    #> 18 date            date    4235 0.00671   
    #> 19 account_code    chr        1 0.00000158
    #> 20 amount          dbl    77775 0.123     
    #> 21 form_of_payment chr        9 0.0000143 
    #> 22 purpose         chr   125834 0.199     
    #> 23 referendum_name chr      378 0.000599  
    #> 24 declaration     chr        3 0.00000475
    #> 25 supports        lgl        3 0.00000475
    #> 26 na_flag         lgl        2 0.00000317
    #> 27 dupe_flag       lgl        2 0.00000317

We can use `campfin::explore_plot()` to explore the distribution of the
least distinct categorical variables.

![](../plots/type_bar-1.png)<!-- -->

![](../plots/method_bar-1.png)<!-- -->

![](../plots/support_bar-1.png)<!-- -->

We can use `tidytext::unnest_tokens()` and `ggplot2::geom_col()` to
explore the most frequent word usage of the long-form `purpose`
variable.

![](../plots/purpose_bar-1.png)<!-- -->

### Continuous

We should also check the range and distribution of continuous variables.

#### Amounts

``` r
summary(nc$amount)
```

    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
    #>  -31961      28     105    1130     500 3201000     680

``` r
sum(nc$amount <= 0, na.rm = TRUE)
```

    #> [1] 1479

![](../plots/amount_histogram-1.png)<!-- -->

![](../plots/amount_box_type-1.png)<!-- -->

![](../plots/amount_box_method-1.png)<!-- -->

#### Dates

We can add a `year` variable using `lubridate::year()`.

``` r
nc <- mutate(nc, year = year(date))
```

The `date` variable is very clean, with 0 records before 2008 and 0
records after 2019-11-04.

``` r
min(nc$date, na.rm = TRUE)
#> [1] "2008-01-01"
sum(nc$year < 2008, na.rm = TRUE)
#> [1] 0
max(nc$date, na.rm = TRUE)
#> [1] "2019-08-15"
sum(nc$date > today(), na.rm = TRUE)
#> [1] 0
```

![](../plots/year_bar_count-1.png)<!-- -->

![](../plots/year_bar_median-1.png)<!-- -->

![](../plots/year_bar_total-1.png)<!-- -->

![](../plots/month_amount_line-1.png)<!-- -->

![](../plots/cycle_amount_line-1.png)<!-- -->

## Wrangle

To improve the searchability of the database, we can perform some
functional text normalization of geographic data. Here, we have
geographic data for both the expender and payee.

### Adress

``` r
nc <- nc %>% 
  unite(
    starts_with("payee_street"),
    col = payee_street,
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  unite(
    starts_with("comm_street"),
    col = comm_street,
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate_at(
   .vars = vars(ends_with("street")),
   .funs = list(norm = normal_address),
   add_abbs = usps_street,
   na = invalid_city,
   na_rep = TRUE
  ) %>% 
  select(
    -ends_with("street")
  )
```

### States

``` r
nc <- nc %>%
  mutate_at(
    .vars = vars(ends_with("state")),
    .funs = str_replace_all,
    "^N$", "NC"
  ) %>% 
  mutate_at(
   .vars = vars(ends_with("state")),
   .funs = list(norm = normal_state),
   abbreviate = TRUE,
   na = c("", "NA"),
   na_rep = TRUE,
   valid = valid_state
  )
```

``` r
progress_table(
  nc$payee_state,
  nc$payee_state_norm,
  compare = valid_state
)
```

    #> # A tibble: 2 x 6
    #>   stage            prop_in n_distinct prop_na n_out n_diff
    #>   <chr>              <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 payee_state        1.000         73   0.209    29     16
    #> 2 payee_state_norm   1             58   0.209     0      1

### Zip

``` r
nc <- nc %>%
  mutate_at(
   .vars = vars(ends_with("zip")),
   .funs = list(norm = normal_zip),
   na = c("", "NA"),
   na_rep = TRUE
  )
```

``` r
progress_table(
  nc$payee_zip,
  nc$payee_zip_norm,
  nc$comm_zip,
  nc$comm_zip_norm,
  compare = valid_zip
)
```

    #> # A tibble: 4 x 6
    #>   stage          prop_in n_distinct prop_na n_out n_diff
    #>   <chr>            <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 payee_zip        0.787      16317 0.269   98233  12356
    #> 2 payee_zip_norm   0.996       5030 0.270    1722    582
    #> 3 comm_zip         0.901       1035 0.00106 62481    280
    #> 4 comm_zip_norm    0.999        793 0.00114   547     13

### City

``` r
nc <- nc %>% 
  mutate_at(
   .vars = vars(ends_with("city")),
   .funs = list(norm = normal_city),
   geo_abbs = usps_city,
   st_abbs = c("NC", "DC"),
   na = invalid_city,
   na_rep = TRUE
  )
```

``` r
nc <- nc %>% 
  left_join(
    y = zipcodes,
    by = c(
      "payee_state_norm" = "state",
      "payee_zip_norm" = "zip"
    )
  ) %>% 
  rename(payee_city_match = city) %>% 
  left_join(
    y = zipcodes,
    by = c(
      "comm_state_norm" = "state",
      "comm_zip_norm" = "zip"
    )
  ) %>% 
  rename(comm_city_match = city)
```

``` r
nc <- nc %>%
  # check and swap payee city
  mutate(
    match_abb = is_abbrev(payee_city_norm, payee_city_match),
    match_dist = str_dist(payee_city_norm, payee_city_match),
    payee_city_swap = if_else(
      condition = match_abb | match_dist <= 1,
      true = payee_city_match,
      false = payee_city_norm
    )
  ) %>% 
  # check and swap committee city
  mutate(
    match_abb = is_abbrev(comm_city_norm, comm_city_match),
    match_dist = str_dist(comm_city_norm, comm_city_match),
    comm_city_swap = if_else(
      condition = match_abb | match_dist <= 2,
      true = comm_city_match,
      false = comm_city_norm
    )
  )
```

``` r
progress_table(
  nc$payee_city,
  nc$payee_city_norm,
  nc$payee_city_swap,
  compare = valid_city
)
```

    #> # A tibble: 3 x 6
    #>   stage           prop_in n_distinct prop_na n_out n_diff
    #>   <chr>             <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 payee_city        0.965       4483   0.244 16547   2367
    #> 2 payee_city_norm   0.978       4170   0.244 10414   2039
    #> 3 payee_city_swap   0.990       2497   0.276  4639    474

``` r
progress_table(
  nc$comm_city,
  nc$comm_city_norm,
  nc$comm_city_swap,
  compare = valid_city
)
```

    #> # A tibble: 3 x 6
    #>   stage          prop_in n_distinct prop_na n_out n_diff
    #>   <chr>            <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 comm_city        0.975        547 0.00106 15640     66
    #> 2 comm_city_norm   0.990        535 0.00106  6607     53
    #> 3 comm_city_swap   0.996        502 0.00317  2787     21

![](../plots/progress_bar-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivilent.

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
  scale_fill_brewer(palette = "Dark2") +
  scale_y_continuous(labels = comma) +
  theme(legend.position = "bottom") +
  labs(
    title = "Massachusetts City Normalization Progress",
    subtitle = "Distinct values, valid and invalid",
    x = "Stage",
    y = "Percent Valid",
    fill = "Valid"
  )
```

![](../plots/distinct_bar-1.png)<!-- -->

## Conclude

1.  There are 631559 records in the database
2.  There are 20074 (3.18%) duplicate records
3.  The range and distribution of `amount` and `date` are reasonable
4.  There are 756 (0.120%) records missing names
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`
6.  The 5-digit `zip_norm` variable has been created with
    `campfin::normal_zip()`
7.  The 4-digit `year` variable has been created with
    `lubridate::year()`

## Lookup

``` r
nc_payee_city_lookup <- read_csv(here("nc", "expends", "data", "nc_payee_city_lookup.csv"))
nc_comm_city_lookup <- read_csv(here("nc", "expends", "data", "nc_comm_city_lookup.csv"))
nc <- nc %>% 
  left_join(nc_payee_city_lookup) %>% 
  left_join(nc_comm_city_lookup)
```

``` r
progress_table(
  nc$payee_city,
  nc$payee_city_norm,
  nc$payee_city_swap,
  nc$payee_city_clean,
  compare = valid_city
)
```

    #> # A tibble: 4 x 6
    #>   stage            prop_in n_distinct prop_na n_out n_diff
    #>   <chr>              <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 payee_city         0.965       4483   0.244 16547   2367
    #> 2 payee_city_norm    0.978       4170   0.244 10414   2039
    #> 3 payee_city_swap    0.990       2497   0.276  4639    474
    #> 4 payee_city_clean   0.991       2252   0.277  4246    250

## Export

``` r
proc_dir <- here("nc", "expends", "data", "processed")
dir_create(proc_dir)
```

``` r
nc %>% select(
  -payee_city_clean,
  -comm_city_clean,
  -payee_city_match,
  -comm_city_match,
  -match_abb,
  -match_dist,
  -payee_city_swap,
  -comm_city_swap
) -> nc

names(nc) %>% str_replace("_norm$", "_clean") -> names(nc)

write_csv(
  x = nc,
  na = "",
  path = glue("{proc_dir}/nc_expends_clean.csv")
)
```
