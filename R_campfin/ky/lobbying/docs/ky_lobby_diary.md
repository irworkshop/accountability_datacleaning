Kentucky Lobbyists
================
Kiernan Nicholls
2019-12-02 14:21:16

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Wrangle](#wrangle)
  - [Normal](#normal)
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
    #> [2] "November 22, 2019"                                                                                   
    #> [3] "Legislative Agents/Employer\tPhone\tContact\tAddress"                                                
    #> [4] "Abbott, Elizabeth \t859-986-1624\t210 N. Broadway #3, , Berea KY 40403"                              
    #> [5] "Kentuckians for the Commonwealth\t859-276-0563\tMahoney, Heather R\tP.O. Box 1450, , London KY 40743"
    #> [6] "Abell, Kelley \t502-216-9990\tP. O. Box 70331, , Louisville KY 40270"

First, we need to remove the header and footer from each page and keep
only those lines which contain the lobbyist name table information.

``` r
kylr <- str_subset(kylr, "Kentucky Registered Legislative Agents", negate = TRUE)
kylr <- str_subset(kylr, "November 22, 2019", negate = TRUE)
kylr <- str_subset(kylr, "Legislative Agents/Employer\tPhone\tContact\tAddress", negate = TRUE)
kylr <- str_subset(kylr, "11/22/2019\t\\d{2}", negate = TRUE)
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
    #>    line name                      phone     contact                address                         
    #>   <int> <chr>                     <chr>     <chr>                  <chr>                           
    #> 1     1 "Abbott, Elizabeth "      859-986-… 210 N. Broadway #3, ,… <NA>                            
    #> 2     2 Kentuckians for the Comm… 859-276-… Mahoney, Heather R     P.O. Box 1450, , London KY 40743
    #> 3     3 "Abell, Kelley "          502-216-… P. O. Box 70331, , Lo… <NA>                            
    #> 4     4 American Assn. for Marri… 703-253-… "Evans, Laura "        112 S. Alfred St., Ste. 300, Al…
    #> 5     5 American College of Obst… 502-649-… "Krause, Dr. Miriam "  4123 Dutchmans Ln., Suite 414, …
    #> 6     6 American Express Company  202-434-… "Testa, Joseph "       801 Pennsylvania Avenue, NW, Su…

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

``` r
kylr <- kylr %>% 
  separate(
    col = lob_name,
    into = c("lob_last", "lob_first"),
    sep = ",\\s",
    extra = "merge" 
  )
```

    #> # A tibble: 6 x 14
    #>   lob_last lob_first lob_phone lob_addr lob_city lob_state lob_zip pri_name pri_phone pri_contact
    #>   <chr>    <chr>     <chr>     <chr>    <chr>    <chr>     <chr>   <chr>    <chr>     <chr>      
    #> 1 ABBOTT   ELIZABETH 859-986-… 210 N. … BEREA    KY        40403   KENTUCK… 859-276-… MAHONEY, H…
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

``` r
kylr <- mutate_at(
  .tbl  = kylr,
  .vars = vars(ends_with("phone")),
  .funs = list(norm = normal_phone)
)
```

    #> # A tibble: 442 x 2
    #>    lob_phone    lob_phone_norm
    #>    <chr>        <chr>         
    #>  1 502-892-2032 (502) 892-2032
    #>  2 859-629-6203 (859) 629-6203
    #>  3 502-893-9795 (502) 893-9795
    #>  4 859-431-2075 (859) 431-2075
    #>  5 502-815-1865 (502) 815-1865
    #>  6 859-272-6700 (859) 272-6700
    #>  7 713-479-8059 (713) 479-8059
    #>  8 606-263-4982 (606) 263-4982
    #>  9 502-223-2338 (502) 223-2338
    #> 10 502-819-9005 (502) 819-9005
    #> # … with 432 more rows

### Address

``` r
kylr <- mutate_at(
  .tbl  = kylr,
  .vars = vars(ends_with("addr")),
  .funs = list(norm = normal_address),
  abbs  = usps_street
)
```

    #> # A tibble: 499 x 2
    #>    lob_addr                               lob_addr_norm                             
    #>    <chr>                                  <chr>                                     
    #>  1 ALKERMES INC. 852 WINTER STREET        ALKERMES INC 852 WINTER STREET            
    #>  2 28 LIBERTY SHIP WAY STE. 2815          28 LIBERTY SHIP WAY SUITE 2815            
    #>  3 632 COMANCHE TRAIL                     632 COMANCHE TRAIL                        
    #>  4 13420 EASTPOINT CENTRE DRIVE STE. 134  13420 EASTPOINT CENTER DRIVE SUITE 134    
    #>  5 1050 HICKORY HILL DRIVE                1050 HICKORY HILL DRIVE                   
    #>  6 130 W. NEW CIRCLE RD.                  130 WEST NEW CIRCLE ROAD                  
    #>  7 420 CAPITOL AVENUE CHILDREN'S ALLIANCE 420 CAPITOL AVENUE CHILDREN SOUTH ALLIANCE
    #>  8 851 CORPORATE DR SUITE 105             851 CORPORATE DRIVE SUITE 105             
    #>  9 942 S. SHADY GROVE ROAD                942 SOUTH SHADY GROVE ROAD                
    #> 10 74 OLD ENGLISH LN.                     74 OLD ENGLISH LANE                       
    #> # … with 489 more rows

### ZIP

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
    #> 1 lob_zip        0.976        183       0    57     22
    #> 2 lob_zip_norm   1.000        165       0     1      1
    #> 3 pri_zip        0.923        346       0   183     50
    #> 4 pri_zip_norm   0.994        316       0    15      4

### City

``` r
kylr <- mutate_at(
  .tbl  = kylr,
  .vars = vars(ends_with("city")),
  .funs = list(norm = normal_city),
  abbs  = usps_city
)
```

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

    #> # A tibble: 3 x 6
    #>   stage         prop_in n_distinct  prop_na n_out n_diff
    #>   <chr>           <dbl>      <dbl>    <dbl> <dbl>  <dbl>
    #> 1 lob_city        0.997         94 0            6      5
    #> 2 lob_city_norm   0.999         93 0            2      2
    #> 3 lob_city_swap   1.000         94 0.000839     1      2
    #> # A tibble: 3 x 6
    #>   stage         prop_in n_distinct prop_na n_out n_diff
    #>   <chr>           <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 pri_city        0.977        183  0         56     17
    #> 2 pri_city_norm   0.992        182  0         18     10
    #> 3 pri_city_swap   0.995        179  0.0113    11      7

## Export

``` r
glimpse(kylr)
#> Observations: 2,384
#> Variables: 24
#> $ lob_last       <chr> "ABBOTT", "ABELL", "ABELL", "ABELL", "ABELL", "ABELL", "ABELL", "ABELL", …
#> $ lob_first      <chr> "ELIZABETH", "KELLEY", "KELLEY", "KELLEY", "KELLEY", "KELLEY", "KELLEY", …
#> $ lob_phone      <chr> "859-986-1624", "502-216-9990", "502-216-9990", "502-216-9990", "502-216-…
#> $ lob_addr       <chr> "210 N. BROADWAY #3", "P. O. BOX 70331", "P. O. BOX 70331", "P. O. BOX 70…
#> $ lob_city       <chr> "BEREA", "LOUISVILLE", "LOUISVILLE", "LOUISVILLE", "LOUISVILLE", "LOUISVI…
#> $ lob_state      <chr> "KY", "KY", "KY", "KY", "KY", "KY", "KY", "KY", "KY", "KY", "KY", "KY", "…
#> $ lob_zip        <chr> "40403", "40270", "40270", "40270", "40270", "40270", "40270", "40270", "…
#> $ pri_name       <chr> "KENTUCKIANS FOR THE COMMONWEALTH", "AMERICAN ASSN. FOR MARRIAGE & FAMILY…
#> $ pri_phone      <chr> "859-276-0563", "703-253-0453", "502-649-2584", "202-434-0155", "502-242-…
#> $ pri_contact    <chr> "MAHONEY, HEATHER R", "EVANS, LAURA", "KRAUSE, DR. MIRIAM", "TESTA, JOSEP…
#> $ pri_addr       <chr> "P.O. BOX 1450", "112 S. ALFRED ST. STE. 300", "4123 DUTCHMANS LN. SUITE …
#> $ pri_city       <chr> "LONDON", "ALEXANDRIA", "LOUISVILLE", "WASHINGTON", "LOUISVILLE", "WASHIN…
#> $ pri_state      <chr> "KY", "VA", "KY", "DC", "KY", "DC", "KY", "KY", "MO", "DC", "KY", "KY", "…
#> $ pri_zip        <chr> "40743", "22314", "40207", "20004", "40223", "20001", "40223", "40223", "…
#> $ lob_phone_norm <chr> "(859) 986-1624", "(502) 216-9990", "(502) 216-9990", "(502) 216-9990", "…
#> $ pri_phone_norm <chr> "(859) 276-0563", "(703) 253-0453", "(502) 649-2584", "(202) 434-0155", "…
#> $ lob_addr_norm  <chr> "210 NORTH BROADWAY 3", "PO BOX 70331", "PO BOX 70331", "PO BOX 70331", "…
#> $ pri_addr_norm  <chr> "PO BOX 1450", "112 SOUTH ALFRED STREET SUITE 300", "4123 DUTCHMANS LANE …
#> $ lob_zip_norm   <chr> "40403", "40270", "40270", "40270", "40270", "40270", "40270", "40270", "…
#> $ pri_zip_norm   <chr> "40743", "22314", "40207", "20004", "40223", "20001", "40223", "40223", "…
#> $ lob_city_norm  <chr> "BEREA", "LOUISVILLE", "LOUISVILLE", "LOUISVILLE", "LOUISVILLE", "LOUISVI…
#> $ pri_city_norm  <chr> "LONDON", "ALEXANDRIA", "LOUISVILLE", "WASHINGTON", "LOUISVILLE", "WASHIN…
#> $ lob_city_swap  <chr> "BEREA", "LOUISVILLE", "LOUISVILLE", "LOUISVILLE", "LOUISVILLE", "LOUISVI…
#> $ pri_city_swap  <chr> "LONDON", "ALEXANDRIA", "LOUISVILLE", "WASHINGTON", "LOUISVILLE", "WASHIN…
```

``` r
proc_dir <- here("ky", "lobbying", "data", "processed")
dir_create(proc_dir)
```

``` r
kylr %>% 
  select(-ends_with("city_norm")) %>% 
  write_csv(
    path = glue("{proc_dir}/ky_lobby_reg.csv"),
    na = ""
  )
```
