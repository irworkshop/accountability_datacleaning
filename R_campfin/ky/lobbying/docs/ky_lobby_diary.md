Kentucky Lobbyists
================
Kiernan Nicholls
2020-01-02 17:16:15

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Registration](#registration)
      - [Data](#data)
      - [Import](#import)
      - [Wrangle](#wrangle)
      - [Normal](#normal)
      - [State](#state)
      - [Export](#export)
  - [Compensation](#compensation)

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
  textreadr, # read text files
  magrittr, # pipe opperators
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  glue, # combine strings
  here, # relative storage
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

# Registration

## Data

The data is obtained from the [Kentucky Legislative Ethics Commission
(KLEC)](https://klec.ky.gov/Pages/default.aspx):

> KLEC has jurisdiction over
> 
>   - Legislative agents (lobbyists),
>   - Employers (individuals or entities who engage legislative agents),
>     and
>   - Members of the General Assembly.
> 
> The legislative ethics law covers four broad subject matters
> 
>   - Registration of legislative agents and employers;
>   - Statements by legislative agents and employers of:
>       - lobbying expenditures and expenses, and financial
>         transactions;
>   - Conduct of members of the General Assembly; and
>   - Financial disclosure statements of the General Assembly,
>     legislative candidates, and
>   - key legislative staff.

The KLEC provides [a rich text file
(RTF)](https://klec.ky.gov/Reports/Reports/Agents.rtf) containing a list
of legislative agents (lobbyists).

## Import

The text file is a table of lobbyists with their clients indented below
them. With the `textreadr` package, we can read the RTF file into a
character vector of the lines on the document.

``` r
lob_url <- "https://klec.ky.gov/Reports/Reports/Agents.rtf"
kylr <- read_rtf(file = lob_url)
```

    #> [1] "Kentucky Registered Legislative Agents"                                                              
    #> [2] "December 30, 2019"                                                                                   
    #> [3] "Legislative Agents/Employer\tPhone\tContact\tAddress"                                                
    #> [4] "Abbott, Elizabeth \t859-200-5159\t936 Vernon Avenue, , Winston Salem NC 27106"                       
    #> [5] "Kentuckians for the Commonwealth\t859-276-0563\tMahoney, Heather R\tP.O. Box 1450, , London KY 40743"
    #> [6] "Abell, Kelley \t502-216-9990\tP. O. Box 70331, , Louisville KY 40270"

First, we need to remove the header and footer from each page and keep
only those lines which contain the lobbyist name table information.

``` r
kylr <- str_subset(kylr, "Kentucky Registered Legislative Agents", negate = TRUE)
kylr <- str_subset(kylr, "\\w+\\s\\d{1,2},\\s\\d{4}", negate = TRUE)
kylr <- str_subset(kylr, "Legislative Agents/Employer\tPhone\tContact\tAddress", negate = TRUE)
kylr <- str_subset(kylr, "\\d{1,2}/\\d{1,2}/\\d{4}\t\\d{2}", negate = TRUE)
kylr <- str_replace_all(kylr, "\"", "\'")
```

## Wrangle

We need to `tibble::enframe()` the character vector and turn it into a
single column data frame. From there, we can `tidyr::separate()` the
column into it’s four component elements.

``` r
kylr <- kylr %>%
  enframe(name = "line", value = "text") %>%
  separate(
    col = text,
    into = c("name", "phone", "contact", "address"),
    sep = "\t"
  )
```

    #> # A tibble: 6 x 5
    #>    line name                     phone     contact                  address                        
    #>   <int> <chr>                    <chr>     <chr>                    <chr>                          
    #> 1     1 "Abbott, Elizabeth "     859-200-… 936 Vernon Avenue, , Wi… <NA>                           
    #> 2     2 Kentuckians for the Com… 859-276-… Mahoney, Heather R       P.O. Box 1450, , London KY 407…
    #> 3     3 "Abell, Kelley "         502-216-… P. O. Box 70331, , Loui… <NA>                           
    #> 4     4 American Assn. for Marr… 703-253-… "Evans, Laura "          112 S. Alfred St., Ste. 300, A…
    #> 5     5 American College of Obs… 502-649-… "Krause, Dr. Miriam "    4123 Dutchmans Ln., Suite 414,…
    #> 6     6 American Express Company 202-434-… "Testa, Joseph "         801 Pennsylvania Avenue, NW, S…

Then, we have to use the indentation of the text file to identify which
rows belong to lobbyist information and which belong to their principal
clients.

``` r
indent <- which(is.na(kylr$address))
kylr <- mutate(kylr, address = coalesce(address, contact))
kylr$contact[indent] <- NA
```

Using this identation, we can shift the lobbyist names over into a *new*
column and `dplyr::fill()` that name and address down *alongside* each
of their clients below. Then this new data frame is re-arranged into a
table with each record identifying a lobbyist and a single client. In
this sense, the lobbyist names are now repeated for each client.

``` r
kylr <- kylr %>%
  mutate(
    lob_name = if_else(
      condition = is.na(contact),
      true = name,
      false = NA_character_
    ),
    lob_phone = if_else(
      condition = is.na(contact),
      true = phone,
      false = NA_character_
    ),
    lob_address = if_else(
      condition = is.na(contact),
      true = address,
      false = NA_character_
    )
  ) %>%
  fill(starts_with("lob")) %>%
  mutate_if(is_character, str_trim) %>%
  mutate_all(str_to_upper) %>% 
  filter(!is.na(contact)) %>%
  rename(
    pri_name = name,
    pri_phone = phone,
    pri_contact = contact,
    pri_address = address
  ) %>%
  select(
    starts_with("lob"),
    starts_with("pri")
  )
```

Now, we need to `tidyr::separate()` the two new `*_address` columns into
the other components. First, we will split the lobbyist’s address into
the street, city, state, and ZIP code. We will

``` r
kylr <- kylr %>%
  separate(
    col = lob_address,
    into = c(glue("lob_addr{1:10}"), "lob_extra"),
    sep = ",\\s",
    fill = "left",
    extra = "merge"
  ) %>%
  na_if("") %>%
  unite(
    starts_with("lob_addr"),
    col = "lob_addr",
    na.rm = TRUE,
    sep = " ",
  ) %>% 
  separate(
    col = lob_extra,
    into = c("lob_extra", "lob_zip"),
    sep = "\\s(?=\\d)",
    fill = "left",
    extra = "merge"
  ) %>% 
  separate(
    col = lob_extra,
    into = c("lob_city", "lob_state"),
    sep = "\\s(?=[^ ]*$)",
    fill = "left",
    extra = "merge"
  )
```

Then, we will perform the same process for the associated principal
clients.

``` r
kylr <- kylr %>%
  separate(
    col = pri_address,
    into = c(glue("pri_addr{1:10}"), "pri_extra"),
    sep = ",\\s",
    fill = "left",
    extra = "merge"
  ) %>%
  na_if("") %>%
  unite(
    starts_with("pri_addr"),
    col = "pri_addr",
    na.rm = TRUE,
    sep = " ",
  ) %>% 
  separate(
    col = pri_extra,
    into = c("pri_extra", "pri_zip"),
    sep = "\\s(?=\\d)",
    fill = "left",
    extra = "merge"
  ) %>% 
  separate(
    col = pri_extra,
    into = c("pri_city", "pri_state"),
    sep = "\\s(?=[^ ]*$)",
    fill = "left",
    extra = "merge"
  )
```

We can also split the lobbyist name to improve searchability.

``` r
kylr <- kylr %>% 
  separate(
    col = lob_name,
    into = c("lob_last", "lob_first"),
    sep = ",\\s",
    extra = "merge" 
  )
```

Through this wrangling, we can see how we were able to reshape a single
column text file into a clear tidy data frame of lobbyist/client
relationships. Each record now identifies both parties in a lobbyist
relationship, with information split into separate columns for
searchability.

    #> # A tibble: 6 x 14
    #>   lob_last lob_first lob_phone lob_addr lob_city lob_state lob_zip pri_name pri_phone pri_contact
    #>   <chr>    <chr>     <chr>     <chr>    <chr>    <chr>     <chr>   <chr>    <chr>     <chr>      
    #> 1 ABBOTT   ELIZABETH 859-200-… 936 VER… WINSTON… NC        27106   KENTUCK… 859-276-… MAHONEY, H…
    #> 2 ABELL    KELLEY    502-216-… P. O. B… LOUISVI… KY        40270   AMERICA… 703-253-… EVANS, LAU…
    #> 3 ABELL    KELLEY    502-216-… P. O. B… LOUISVI… KY        40270   AMERICA… 502-649-… KRAUSE, DR…
    #> 4 ABELL    KELLEY    502-216-… P. O. B… LOUISVI… KY        40270   AMERICA… 202-434-… TESTA, JOS…
    #> 5 ABELL    KELLEY    502-216-… P. O. B… LOUISVI… KY        40270   APERTUR… 502-242-… GILFERT, J…
    #> 6 ABELL    KELLEY    502-216-… P. O. B… LOUISVI… KY        40270   BEAM SU… 202-962-… MCNAUGHTON…
    #> # … with 4 more variables: pri_addr <chr>, pri_city <chr>, pri_state <chr>, pri_zip <chr>

## Normal

Now that the text file has been wrangled into a database format, we can
proceed to manipulate the *content* of the file to improve the
searchability of the database.

### Phone

We can convert all telephone numbers to a single format with
`campfin::normal_phone()`.

``` r
kylr <- mutate_at(
  .tbl  = kylr,
  .vars = vars(ends_with("phone")),
  .funs = list(norm = normal_phone)
)
```

    #> # A tibble: 454 x 2
    #>    lob_phone    lob_phone_norm
    #>    <chr>        <chr>         
    #>  1 502-875-3411 (502) 875-3411
    #>  2 617-949-4285 (617) 949-4285
    #>  3 901-818-7558 (901) 818-7558
    #>  4 502-489-3036 (502) 489-3036
    #>  5 502-583-8374 (502) 583-8374
    #>  6 859-381-1414 (859) 381-1414
    #>  7 717-514-9480 (717) 514-9480
    #>  8 502-223-2379 (502) 223-2379
    #>  9 859-940-2441 (859) 940-2441
    #> 10 5            5             
    #> # … with 444 more rows

### Address

For street addresses, we can use `campfin::normal_address()` to force
string consistency and expand abbreviations.

``` r
kylr <- mutate_at(
  .tbl  = kylr,
  .vars = vars(ends_with("addr")),
  .funs = list(norm = normal_address),
  abbs  = usps_street
)
```

    #> # A tibble: 502 x 2
    #>    lob_addr                    lob_addr_norm                 
    #>    <chr>                       <chr>                         
    #>  1 143A RUMSEY CIRCLE          143A RUMSEY CIRCLE            
    #>  2 958 COLLETT AVE. SUITE 310  958 COLLETT AVENUE SUITE 310  
    #>  3 MML&K 305 ANN ST. SUITE 308 MML K 305 ANN STREET SUITE 308
    #>  4 1285 ISLAND FORD ROAD       1285 ISLAND FORD ROAD         
    #>  5 936 VERNON AVENUE           936 VERNON AVENUE             
    #>  6 106 PROGRESS DRIVE          106 PROGRESS DRIVE            
    #>  7 250 PLAZA DR. STE. 4        250 PLAZA DRIVE SUITE 4       
    #>  8 2701 EASTPOINT PARKWAY      2701 EASTPOINT PARKWAY        
    #>  9 ONE MEDICAL VILLAGE DR.     ONE MEDICAL VILLAGE DRIVE     
    #> 10 250 PLAZA DR. SUITE 4       250 PLAZA DRIVE SUITE 4       
    #> # … with 492 more rows

### ZIP

Only the 5-digit ZIP codes are desired. The `campfin::normal_zip()`
function trims and pads ZIP codes to make them valid.

``` r
kylr <- mutate_at(
  .tbl  = kylr,
  .vars = vars(ends_with("zip")),
  .funs = list(norm = normal_zip)
)
```

    #> # A tibble: 4 x 6
    #>   stage        prop_in n_distinct prop_na n_out n_diff
    #>   <chr>          <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 lob_zip        0.977        186       0    58     21
    #> 2 lob_zip_norm   1.000        169       0     1      1
    #> 3 pri_zip        0.927        345       0   183     47
    #> 4 pri_zip_norm   0.994        317       0    15      4

## State

The state variables are already entirely normalized to their 2-digit
USPS abbreviations.

``` r
count(kylr, lob_state, sort = TRUE)
#> # A tibble: 25 x 2
#>    lob_state     n
#>    <chr>     <int>
#>  1 KY         2385
#>  2 OH           18
#>  3 DC           17
#>  4 VA           14
#>  5 CA           13
#>  6 IN            8
#>  7 TN            8
#>  8 IL            7
#>  9 MI            5
#> 10 PA            4
#> # … with 15 more rows
prop_in(kylr$lob_state, valid_state)
#> [1] 1
# USPS store, manually checked
kylr$pri_state <- str_replace(kylr$pri_state, "RD", "KY")
prop_in(kylr$pri_state, valid_state)
#> [1] 1
```

### City

City strings are the most troublesome due to the sheer variety in names
and the multiple valid ways to list the same cities. Using
`campfin::normal_city()` is the first step in improving the consistency.

``` r
kylr <- mutate_at(
  .tbl  = kylr,
  .vars = vars(ends_with("city")),
  .funs = list(norm = normal_city),
  abbs  = usps_city
)
```

Then, we compare the normalized city string to the *expected* city for
that record’s state and ZIP code. If the two are *extremelly* similar,
we can confidently use the correct, expected value.

``` r
kylr <- kylr %>% 
  left_join(
    y = zipcodes,
    by = c(
      "lob_state" = "state",
      "lob_zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(lob_city_norm, city_match),
    match_dist = str_dist(lob_city_norm, city_match),
    lob_city_swap = if_else(
      condition = match_abb | match_dist == 1,
      true = city_match,
      false = lob_city_norm
    )
  ) %>% 
  select(
    -city_match,
    -match_dist,
    -match_abb
  )
```

Then simply repeat that checking for the principal city.

``` r
kylr <- kylr %>% 
  left_join(
    y = zipcodes,
    by = c(
      "pri_state" = "state",
      "pri_zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(pri_city_norm, city_match),
    match_dist = str_dist(pri_city_norm, city_match),
    pri_city_swap = if_else(
      condition = match_abb | match_dist == 1,
      true = city_match,
      false = pri_city_norm
    )
  ) %>% 
  select(
    -city_match,
    -match_dist,
    -match_abb
  )
```

These two-step process is able to bring both city variables to near
complete normality.

    #> # A tibble: 3 x 6
    #>   stage         prop_in n_distinct  prop_na n_out n_diff
    #>   <chr>           <dbl>      <dbl>    <dbl> <dbl>  <dbl>
    #> 1 lob_city        0.998         95 0            6      5
    #> 2 lob_city_norm   0.999         94 0            2      2
    #> 3 lob_city_swap   1.000         95 0.000799     1      2
    #> # A tibble: 3 x 6
    #>   stage         prop_in n_distinct prop_na n_out n_diff
    #>   <chr>           <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 pri_city        0.979        181 0          52     12
    #> 2 pri_city_norm   0.996        180 0          11      5
    #> 3 pri_city_swap   0.998        177 0.00959     6      4

## Export

``` r
glimpse(kylr)
#> Observations: 2,502
#> Variables: 24
#> $ lob_last       <chr> "ABBOTT", "ABELL", "ABELL", "ABELL", "ABELL", "ABELL", "ABELL", "ABELL", …
#> $ lob_first      <chr> "ELIZABETH", "KELLEY", "KELLEY", "KELLEY", "KELLEY", "KELLEY", "KELLEY", …
#> $ lob_phone      <chr> "859-200-5159", "502-216-9990", "502-216-9990", "502-216-9990", "502-216-…
#> $ lob_addr       <chr> "936 VERNON AVENUE", "P. O. BOX 70331", "P. O. BOX 70331", "P. O. BOX 703…
#> $ lob_city       <chr> "WINSTON SALEM", "LOUISVILLE", "LOUISVILLE", "LOUISVILLE", "LOUISVILLE", …
#> $ lob_state      <chr> "NC", "KY", "KY", "KY", "KY", "KY", "KY", "KY", "KY", "KY", "KY", "KY", "…
#> $ lob_zip        <chr> "27106", "40270", "40270", "40270", "40270", "40270", "40270", "40270", "…
#> $ pri_name       <chr> "KENTUCKIANS FOR THE COMMONWEALTH", "AMERICAN ASSN. FOR MARRIAGE & FAMILY…
#> $ pri_phone      <chr> "859-276-0563", "703-253-0453", "502-649-2584", "202-434-0155", "502-242-…
#> $ pri_contact    <chr> "MAHONEY, HEATHER R", "EVANS, LAURA", "KRAUSE, DR. MIRIAM", "TESTA, JOSEP…
#> $ pri_addr       <chr> "P.O. BOX 1450", "112 S. ALFRED ST. STE. 300", "4123 DUTCHMANS LN. SUITE …
#> $ pri_city       <chr> "LONDON", "ALEXANDRIA", "LOUISVILLE", "WASHINGTON", "LOUISVILLE", "WASHIN…
#> $ pri_state      <chr> "KY", "VA", "KY", "DC", "KY", "DC", "KY", "KY", "MO", "DC", "KY", "KY", "…
#> $ pri_zip        <chr> "40743", "22314", "40207", "20004", "40223", "20001", "40223", "40223", "…
#> $ lob_phone_norm <chr> "(859) 200-5159", "(502) 216-9990", "(502) 216-9990", "(502) 216-9990", "…
#> $ pri_phone_norm <chr> "(859) 276-0563", "(703) 253-0453", "(502) 649-2584", "(202) 434-0155", "…
#> $ lob_addr_norm  <chr> "936 VERNON AVENUE", "PO BOX 70331", "PO BOX 70331", "PO BOX 70331", "PO …
#> $ pri_addr_norm  <chr> "PO BOX 1450", "112 SOUTH ALFRED STREET SUITE 300", "4123 DUTCHMANS LANE …
#> $ lob_zip_norm   <chr> "27106", "40270", "40270", "40270", "40270", "40270", "40270", "40270", "…
#> $ pri_zip_norm   <chr> "40743", "22314", "40207", "20004", "40223", "20001", "40223", "40223", "…
#> $ lob_city_norm  <chr> "WINSTON SALEM", "LOUISVILLE", "LOUISVILLE", "LOUISVILLE", "LOUISVILLE", …
#> $ pri_city_norm  <chr> "LONDON", "ALEXANDRIA", "LOUISVILLE", "WASHINGTON", "LOUISVILLE", "WASHIN…
#> $ lob_city_swap  <chr> "WINSTON SALEM", "LOUISVILLE", "LOUISVILLE", "LOUISVILLE", "LOUISVILLE", …
#> $ pri_city_swap  <chr> "LONDON", "ALEXANDRIA", "LOUISVILLE", "WASHINGTON", "LOUISVILLE", "WASHIN…
```

We can now export this wrangled and normalized data set.

``` r
proc_dir <- here("ky", "lobbying", "data", "processed")
dir_create(proc_dir)
```

``` r
kylr %>% 
  # swap over norm
  select(-ends_with("city_norm")) %>%
  rename(
    lob_city_norm = lob_city_swap,
    pri_city_norm = pri_city_swap
  ) %>% 
  write_csv(
    path = glue("{proc_dir}/ky_lobby_reg.csv"),
    na = ""
  )
```

# Compensation

We can also download lobbyist compensation data for the past two years.
We can directly read both files into a single data frame with
`purrr:map_dfr()`.

``` r
kylc <- map_dfr(
  .x = c(
    "https://klec.ky.gov/Reports/Reports/LAComp.txt",
    "https://klec.ky.gov/Reports/Reports/LACompPrior.txt"
  ),
  .f = read_delim,
  delim = ";",
  skip = 2,
  col_types = cols(
    `Legislative Agent` = col_character(),
    `Report Period` = col_character(),
    Employer = col_character(),
    Compensation = col_number()
  )
)
```

Repeat column headers can be removed, names converted to snake case,
date columns separated and converted to date objects, and character
columns converted to a consistent case.

``` r
kylc <- kylc %>% 
  filter(
    `Legislative Agent` != "Legislative Agent",
    `Report Period` != "Report Period",
    `Employer` != "Employer",
    `Compensation` != "Compensation"
  ) %>% 
  clean_names("snake") %>% 
  separate(
    col = report_period,
    into = c("start_date", "end_date"),
    sep = "\\s"
  ) %>% 
  mutate_at(
    .vars = vars(ends_with("date")),
    .funs = parse_date,
    format = "%m/%d/%Y"
  ) %>% 
  mutate_if(
    .predicate = is_character,
    .funs = ~str_trim(str_to_upper(str_replace(., "\"", "\'")))
    )
```

``` r
head(kylc)
#> # A tibble: 6 x 5
#>   legislative_agent start_date end_date   employer                                     compensation
#>   <chr>             <date>     <date>     <chr>                                               <dbl>
#> 1 ABBOTT ELIZABETH  2019-01-01 2019-01-31 KENTUCKIANS FOR THE COMMONWEALTH                     421.
#> 2 ABBOTT ELIZABETH  2019-02-01 2019-02-28 KENTUCKIANS FOR THE COMMONWEALTH                     444.
#> 3 ABBOTT ELIZABETH  2019-03-01 2019-03-31 KENTUCKIANS FOR THE COMMONWEALTH                     170.
#> 4 ABELL KELLEY      2019-01-01 2019-01-31 AMERICAN ASSN. FOR MARRIAGE & FAMILY THERAPY        1000 
#> 5 ABELL KELLEY      2019-01-01 2019-01-31 AMERICAN COLLEGE OF OBSTETRICIAN/GYNECOLOGI…         500 
#> 6 ABELL KELLEY      2019-01-01 2019-01-31 AMERICAN EXPRESS COMPANY                            1125
tail(kylc)
#> # A tibble: 6 x 5
#>   legislative_agent start_date end_date   employer                                     compensation
#>   <chr>             <date>     <date>     <chr>                                               <dbl>
#> 1 YOUNG V. WAYNE    2018-09-01 2018-12-31 KY ASSN. OF SCHOOL ADMINISTRATORS                  4000  
#> 2 ZARING SASHA      2018-01-01 2018-01-31 KENTUCKIANS FOR THE COMMONWEALTH                     14.5
#> 3 ZARING SASHA      2018-02-01 2018-02-28 KENTUCKIANS FOR THE COMMONWEALTH                     37.6
#> 4 ZARING SASHA      2018-03-01 2018-03-31 KENTUCKIANS FOR THE COMMONWEALTH                     30.9
#> 5 ZELLER SARAH      2018-03-01 2018-03-31 MOUNTAIN ASSN. FOR COMMUNITY ECONOMIC DEVEL.        183. 
#> 6 ZIBART DARLENE    2018-02-01 2018-02-28 KY SOCIETY OF CERTIFIED PUBLIC ACCOUNTANTS          697.
glimpse(sample_frac(kylc))
#> Observations: 20,095
#> Variables: 5
#> $ legislative_agent <chr> "JENNINGS M. PATRICK", "BROWN SHERMAN A", "MARTIN ANDREW 'SKIPPER\"", …
#> $ start_date        <date> 2018-05-01, 2019-03-01, 2018-01-01, 2019-02-01, 2018-01-01, 2019-04-0…
#> $ end_date          <date> 2018-08-31, 2019-03-31, 2018-01-31, 2019-02-28, 2018-01-31, 2019-04-3…
#> $ employer          <chr> "GENERAL CIGAR COMPANY, INC.", "AIR EVAC LIFETEAM", "KY AMERICAN WATER…
#> $ compensation      <dbl> 1122.13, 200.00, 187.50, 650.00, 62.50, 62.50, 131.25, 3000.00, 5000.0…
```

This compensation database can also be written to disk.

``` r
write_csv(
  x = kylc,
  path = glue("{proc_dir}/ky_lobby_comp.csv"),
  na = ""
)
```
