Kentucky Lobbyists
================
Kiernan Nicholls
2020-01-30 16:03:06

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
    #> [2] "January 27, 2020"                                                                                 
    #> [3] "Legislative Agents/Employer\tPhone\tContact\tAddress"                                             
    #> [4] "Abbott, Elizabeth \t859-200-5159\t936 Vernon Avenue, , Winston Salem NC 27106"                    
    #> [5] "Kentuckians for the Commonwealth\t859-276-0563\tBrown, Morgan Q\tP.O. Box 1450, , London KY 40743"
    #> [6] "Abell, Kelley \t502-216-9990\tP. O. Box 70331, , Louisville KY 40270"

First, we need to remove the header and footer from each page and keep
only those lines which contain the lobbyist name table information.

``` r
kylr <- str_subset(kylr, "Kentucky Registered Legislative Agents", negate = TRUE)
kylr <- str_subset(kylr, "\\w+\\s\\d{1,2},\\s\\d{4}", negate = TRUE)
kylr <- str_subset(kylr, "Legislative Agents/Employer\tPhone\tContact\tAddress", negate = TRUE)
kylr <- str_subset(kylr, "\\d{1,2}/\\d{1,2}/\\d{4}\t\\d{1,2}", negate = TRUE)
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
    #>    line name                      phone     contact                  address                       
    #>   <int> <chr>                     <chr>     <chr>                    <chr>                         
    #> 1     1 "Abbott, Elizabeth "      859-200-… "936 Vernon Avenue, , W… <NA>                          
    #> 2     2 "Kentuckians for the Com… 859-276-… "Brown, Morgan Q"        P.O. Box 1450, , London KY 40…
    #> 3     3 "Abell, Kelley "          502-216-… "P. O. Box 70331, , Lou… <NA>                          
    #> 4     4 "American Assn. for Marr… 502-494-… "Rankin, Mike "          12401 Tyler Woods Court, , Lo…
    #> 5     5 "American College of Obs… 502-649-… "Krause, Dr. Miriam "    4123 Dutchmans Ln., Suite 414…
    #> 6     6 "American Express Travel… 202-434-… "Testa, Joseph "         801 Pennsylvania Avenue, NW, …

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
    #> 1 ABBOTT   ELIZABETH 859-200-… 936 VER… WINSTON… NC        27106   KENTUCK… 859-276-… BROWN, MOR…
    #> 2 ABELL    KELLEY    502-216-… P. O. B… LOUISVI… KY        40270   AMERICA… 502-494-… RANKIN, MI…
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

    #> # A tibble: 427 x 2
    #>    lob_phone    lob_phone_norm
    #>    <chr>        <chr>         
    #>  1 804-484-8606 (804) 484-8606
    #>  2 202-905-2025 (202) 905-2025
    #>  3 502-569-3600 (502) 569-3600
    #>  4 859-258-3600 (859) 258-3600
    #>  5 502-893-0788 (502) 893-0788
    #>  6 502-227-8043 (502) 227-8043
    #>  7 270-779-0991 (270) 779-0991
    #>  8 859-278-0569 (859) 278-0569
    #>  9 859-254-0000 (859) 254-0000
    #> 10 606-878-2161 (606) 878-2161
    #> # … with 417 more rows

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

    #> # A tibble: 482 x 2
    #>    lob_addr                                           lob_addr_norm                                
    #>    <chr>                                              <chr>                                        
    #>  1 1285 ISLAND FORD ROAD                              1285 IS FRD RD                               
    #>  2 205 B CAPITAL AVE.                                 205 B CAPITAL AVE                            
    #>  3 2001 MERCER RD.                                    2001 MERCER RD                               
    #>  4 999 NIELD RD.                                      999 NIELD RD                                 
    #>  5 130 W. NEW CIRCLE RD. SUITE 170                    130 W NEW CIR RD STE 170                     
    #>  6 707 VIRGINIA STREET EAST SUITE 1300                707 VIRGINIA ST E STE 1300                   
    #>  7 MML&K 305 ANN ST. SUITE 308                        MML K 305 ANN ST STE 308                     
    #>  8 464 CHENAULT ROAD                                  464 CHENAULT RD                              
    #>  9 205 W. THIRD STREET COMMONWEALTH ALLIANCES         205 W THIRD ST COMMONWEALTH ALLIANCES        
    #> 10 87 C. MICHAEL DAVENPORT BLVD. KY. ASSN. OF SCHOOL… 87 C MICHAEL DAVENPORT BLVD KY ASSN OF SCHOO…
    #> # … with 472 more rows

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
    #> 1 lob_zip        0.976        169       0    59     20
    #> 2 lob_zip_norm   1.00         153       0     1      1
    #> 3 pri_zip        0.935        324       0   160     44
    #> 4 pri_zip_norm   0.997        299       0     8      3

## State

The state variables are already entirely normalized to their 2-digit
USPS abbreviations.

``` r
count(kylr, lob_state, sort = TRUE)
#> # A tibble: 22 x 2
#>    lob_state     n
#>    <chr>     <int>
#>  1 KY         2366
#>  2 OH           15
#>  3 DC           11
#>  4 CA            9
#>  5 TN            8
#>  6 VA            7
#>  7 IL            6
#>  8 IN            5
#>  9 MI            4
#> 10 NY            3
#> # … with 12 more rows
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
    #> 1 lob_city        0.998         81 0            4      4
    #> 2 lob_city_norm   0.999         80 0            2      2
    #> 3 lob_city_swap   1.00          81 0.000816     1      2
    #> # A tibble: 3 x 6
    #>   stage         prop_in n_distinct prop_na n_out n_diff
    #>   <chr>           <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 pri_city        0.978        168 0          55     11
    #> 2 pri_city_norm   0.995        167 0          12      5
    #> 3 pri_city_swap   0.998        166 0.00816     5      3

## Export

``` r
glimpse(kylr)
#> Observations: 2,451
#> Variables: 24
#> $ lob_last       <chr> "ABBOTT", "ABELL", "ABELL", "ABELL", "ABELL", "ABELL", "ABELL", "ABELL", …
#> $ lob_first      <chr> "ELIZABETH", "KELLEY", "KELLEY", "KELLEY", "KELLEY", "KELLEY", "KELLEY", …
#> $ lob_phone      <chr> "859-200-5159", "502-216-9990", "502-216-9990", "502-216-9990", "502-216-…
#> $ lob_addr       <chr> "936 VERNON AVENUE", "P. O. BOX 70331", "P. O. BOX 70331", "P. O. BOX 703…
#> $ lob_city       <chr> "WINSTON SALEM", "LOUISVILLE", "LOUISVILLE", "LOUISVILLE", "LOUISVILLE", …
#> $ lob_state      <chr> "NC", "KY", "KY", "KY", "KY", "KY", "KY", "KY", "KY", "KY", "KY", "KY", "…
#> $ lob_zip        <chr> "27106", "40270", "40270", "40270", "40270", "40270", "40270", "40270", "…
#> $ pri_name       <chr> "KENTUCKIANS FOR THE COMMONWEALTH", "AMERICAN ASSN. FOR MARRIAGE & FAMILY…
#> $ pri_phone      <chr> "859-276-0563", "502-494-2929", "502-649-2584", "202-434-0155", "502-242-…
#> $ pri_contact    <chr> "BROWN, MORGAN Q", "RANKIN, MIKE", "KRAUSE, DR. MIRIAM", "TESTA, JOSEPH",…
#> $ pri_addr       <chr> "P.O. BOX 1450", "12401 TYLER WOODS COURT", "4123 DUTCHMANS LN. SUITE 414…
#> $ pri_city       <chr> "LONDON", "LOUISVILLE", "LOUISVILLE", "WASHINGTON", "LOUISVILLE", "WASHIN…
#> $ pri_state      <chr> "KY", "KY", "KY", "DC", "KY", "DC", "KY", "KY", "MO", "DC", "KY", "KY", "…
#> $ pri_zip        <chr> "40743", "40299", "40207", "20004", "40223", "20001", "40222", "40223", "…
#> $ lob_phone_norm <chr> "(859) 200-5159", "(502) 216-9990", "(502) 216-9990", "(502) 216-9990", "…
#> $ pri_phone_norm <chr> "(859) 276-0563", "(502) 494-2929", "(502) 649-2584", "(202) 434-0155", "…
#> $ lob_addr_norm  <chr> "936 VERNON AVE", "PO BOX 70331", "PO BOX 70331", "PO BOX 70331", "PO BOX…
#> $ pri_addr_norm  <chr> "PO BOX 1450", "12401 TYLER WOODS CT", "4123 DUTCHMANS LN STE 414", "801 …
#> $ lob_zip_norm   <chr> "27106", "40270", "40270", "40270", "40270", "40270", "40270", "40270", "…
#> $ pri_zip_norm   <chr> "40743", "40299", "40207", "20004", "40223", "20001", "40222", "40223", "…
#> $ lob_city_norm  <chr> "WINSTON SALEM", "LOUISVILLE", "LOUISVILLE", "LOUISVILLE", "LOUISVILLE", …
#> $ pri_city_norm  <chr> "LONDON", "LOUISVILLE", "LOUISVILLE", "WASHINGTON", "LOUISVILLE", "WASHIN…
#> $ lob_city_swap  <chr> "WINSTON SALEM", "LOUISVILLE", "LOUISVILLE", "LOUISVILLE", "LOUISVILLE", …
#> $ pri_city_swap  <chr> "LONDON", "LOUISVILLE", "LOUISVILLE", "WASHINGTON", "LOUISVILLE", "WASHIN…
```

We can now export this wrangled and normalized data set.

``` r
proc_dir <- dir_create(here("ky", "lobbying", "data", "processed"))
```

``` r
kylr <- kylr %>% 
  # swap over norm
  select(-ends_with("city_norm")) %>%
  rename(
    lob_city_norm = lob_city_swap,
    pri_city_norm = pri_city_swap
  )

write_csv(
  x = kylr,
  path = glue("{proc_dir}/ky_lobby_reg.csv"),
  na = ""
)
```

# Compensation

We can also download lobbyist compensation data for the past two years.
These files can be read by reading the lines of each, manipulating them
slightly, and passing them back into `readr::read_delim()`.

``` r
# read lines from both years
kylc_lines <- map(
  .f = read_lines,
  .x = c(
    "https://klec.ky.gov/Reports/Reports/LAComp.txt",
    "https://klec.ky.gov/Reports/Reports/LACompPrior.txt"
  )
)

kylc_lines <- as_vector(kylc_lines)
# remove headers
kylc_lines <- str_subset(kylc_lines, "^Legislative\\sAgent\\sCompensation$", negate = TRUE)
kylc_lines <- str_subset(kylc_lines, "^\\w+\\s\\d{1,2},\\s\\d{4}$", negate = TRUE)
# remove repeated col headers
kylc_names <- kylc_lines[[1]]
kylc_lines <- str_subset(kylc_lines, kylc_names, negate = TRUE)
kylc_names <- make_clean_names(str_split(kylc_names, ";", simplify = TRUE))
kylc_names <- c("lob_name", "report_period", "pri_name", "compensation")
# identify overflow lines
overflow <- which(str_count(kylc_lines, ";") < 3)
# collapse with previous line
kylc_lines[overflow - 1] <- str_replace(
  string = kylc_lines[overflow - 1], 
  pattern = "(\\s)(?=;\\$)", 
  replacement = glue("\\1{kylc_lines[overflow]}")
)
# remove overflow lines
kylc_lines <- kylc_lines[-overflow]

# reas as tabular 
kylc <- 
  read_delim(
    file = kylc_lines,
    delim = ";",
    escape_double = FALSE,
    escape_backslash = FALSE,
    col_names = kylc_names,
    col_types = cols(
      .default = col_character(),
      compensation = col_number()
    )
  ) %>%
  # split start and end dates
  separate(
    col = report_period,
    into = c("start_date", "end_date"),
    sep = "\\s"
  ) %>% 
  # convert both to date cols
  mutate_at(
    .vars = vars(ends_with("date")),
    .funs = lubridate::mdy
  ) %>% 
  mutate_if(
    .predicate = is_character,
    .funs = str_normal,
    punct = FALSE
  ) %>% 
  separate(
    col = lob_name,
    into = c("lob_last", "lob_first"),
    sep = "\\s",
    extra = "merge" 
  )
```

``` r
head(kylc)
#> # A tibble: 6 x 6
#>   lob_last lob_first start_date end_date   pri_name                                    compensation
#>   <chr>    <chr>     <date>     <date>     <chr>                                              <dbl>
#> 1 ABBOTT   ELIZABETH 2019-01-01 2019-01-31 KENTUCKIANS FOR THE COMMONWEALTH                    421.
#> 2 ABBOTT   ELIZABETH 2019-02-01 2019-02-28 KENTUCKIANS FOR THE COMMONWEALTH                    444.
#> 3 ABBOTT   ELIZABETH 2019-03-01 2019-03-31 KENTUCKIANS FOR THE COMMONWEALTH                    170.
#> 4 ABELL    KELLEY    2019-01-01 2019-01-31 AMERICAN ASSN. FOR MARRIAGE & FAMILY THERA…        1000 
#> 5 ABELL    KELLEY    2019-01-01 2019-01-31 AMERICAN COLLEGE OF OBSTETRICIAN/GYNECOLOG…         500 
#> 6 ABELL    KELLEY    2019-01-01 2019-01-31 AMERICAN EXPRESS TRAVEL REL. SERVICES, INC.        1125
tail(kylc)
#> # A tibble: 6 x 6
#>   lob_last lob_first start_date end_date   pri_name                                    compensation
#>   <chr>    <chr>     <date>     <date>     <chr>                                              <dbl>
#> 1 ZELLER   SARAH     2019-04-01 2019-04-30 MOUNTAIN ASSN. FOR COMMUNITY ECONOMIC DEVE…         41.8
#> 2 ZELLER   SARAH     2019-05-01 2019-08-31 MOUNTAIN ASSN. FOR COMMUNITY ECONOMIC DEVE…         95.8
#> 3 ZIBART   DARLENE   2019-01-01 2019-01-31 KY SOCIETY OF CERTIFIED PUBLIC ACCOUNTANTS         610. 
#> 4 ZIBART   DARLENE   2019-02-01 2019-02-28 KY SOCIETY OF CERTIFIED PUBLIC ACCOUNTANTS         741. 
#> 5 ZIBART   DARLENE   2019-03-01 2019-03-31 KY SOCIETY OF CERTIFIED PUBLIC ACCOUNTANTS        1046. 
#> 6 ZIBART   DARLENE   2019-05-01 2019-08-31 KY SOCIETY OF CERTIFIED PUBLIC ACCOUNTANTS         272
glimpse(sample_frac(kylc))
#> Observations: 11,105
#> Variables: 6
#> $ lob_last     <chr> "SCHUSTER", "NOLAN", "WHITEHOUSE", "COOPER", "ALLEN", "BROWN", "LAMBERT", "…
#> $ lob_first    <chr> "SHEILA A", "CHRIS", "DAVID M", "JOHN P", "JAMES 'JITTER' W", "SHERMAN A", …
#> $ start_date   <date> 2019-01-01, 2019-01-01, 2019-09-01, 2019-02-01, 2019-09-01, 2019-02-01, 20…
#> $ end_date     <date> 2019-01-31, 2019-01-31, 2019-12-31, 2019-02-28, 2019-12-31, 2019-02-28, 20…
#> $ pri_name     <chr> "KY NURSES ASSOCIATION", "NUCOR CORP.", "ELI LILLY AND COMPANY", "TOYOTA MO…
#> $ compensation <dbl> 1000.00, 1500.00, 10800.00, 6000.00, 41666.68, 375.00, 50.00, 275.00, 5000.…
```

Since this database will be uploaded separately from the lobbyist
registration containing the phone number and addresses of lobbyists and
principal clients, we will have to add these columns so that the
compensation records will show up when this information is searched.

``` r
lob_info <- kylr %>% 
  select(starts_with("lob_")) %>% 
  select(lob_first, lob_last, ends_with("_norm")) %>% 
  distinct()

pri_info <- kylr %>% 
  select(starts_with("pri_")) %>% 
  select(pri_name, ends_with("_norm")) %>% 
  distinct()

kylc <- kylc %>% 
  left_join(lob_info, by = c("lob_last", "lob_first")) %>% 
  left_join(pri_info, by = "pri_name")
```

We can see that most of these new columns were joined successfully.

``` r
col_stats(kylc, count_na)
#> # A tibble: 14 x 4
#>    col            class      n      p
#>    <chr>          <chr>  <int>  <dbl>
#>  1 lob_last       <chr>      0 0     
#>  2 lob_first      <chr>      0 0     
#>  3 start_date     <date>     0 0     
#>  4 end_date       <date>     0 0     
#>  5 pri_name       <chr>      0 0     
#>  6 compensation   <dbl>      0 0     
#>  7 lob_phone_norm <chr>   1409 0.127 
#>  8 lob_addr_norm  <chr>   1409 0.127 
#>  9 lob_zip_norm   <chr>   1409 0.127 
#> 10 lob_city_norm  <chr>   1416 0.128 
#> 11 pri_phone_norm <chr>    900 0.0810
#> 12 pri_addr_norm  <chr>    900 0.0810
#> 13 pri_zip_norm   <chr>    900 0.0810
#> 14 pri_city_norm  <chr>    996 0.0897
```

``` r
glimpse(sample_frac(kylc))
#> Observations: 11,105
#> Variables: 14
#> $ lob_last       <chr> "BUSICK", "HIGDON", "MCCARTHY,", "COOPER", "BUSHART", "CRESS,", "MILLIGAN…
#> $ lob_first      <chr> "JEFFERY M", "JAMES M", "III JOHN T", "JOHN P", "WILLIAM MACK", "JR. LLOY…
#> $ start_date     <date> 2019-04-01, 2019-03-01, 2019-04-01, 2019-05-01, 2019-02-01, 2019-02-01, …
#> $ end_date       <date> 2019-04-30, 2019-03-31, 2019-04-30, 2019-08-31, 2019-02-28, 2019-02-28, …
#> $ pri_name       <chr> "KY STATE UNIVERSITY", "MERCK SHARP & DOHME CORP. & ITS AFFILIATES", "FOR…
#> $ compensation   <dbl> 250.00, 1470.00, 840.00, 11666.00, 2666.00, 880.88, 125.00, 600.00, 1000.…
#> $ lob_phone_norm <chr> "(502) 875-0081", "(502) 875-1176", NA, "(502) 223-8967", "(859) 595-0911…
#> $ lob_addr_norm  <chr> "113 W MAIN ST", "MML K 305 ANN ST STE 308", NA, "225 CAPITOL AVE", "514 …
#> $ lob_zip_norm   <chr> "40601", "40601", NA, "40601", "40391", NA, "40601", NA, "40601", "40601"…
#> $ lob_city_norm  <chr> "FRANKFORT", "FRANKFORT", NA, "FRANKFORT", "WINCHESTER", NA, "FRANKFORT",…
#> $ pri_phone_norm <chr> "(502) 597-5054", "(415) 389-6800", "(202) 962-5392", "(314) 577-3076", "…
#> $ pri_addr_norm  <chr> "400 E MAIN ST HUME HALL", "NIELSEN MERKSAMER ET AL 2350 KERNER BLVD STE …
#> $ pri_zip_norm   <chr> "40601", "94901", "20004", "32218", "40391", "40507", "40362", "40202", "…
#> $ pri_city_norm  <chr> "FRANKFORT", "SAN RAFAEL", "WASHINGTON", "JACKSONVILLE", "WINCHESTER", "L…
```

This compensation database can also be written to disk.

``` r
write_csv(
  x = kylc,
  path = glue("{proc_dir}/ky_lobby_comp.csv"),
  na = ""
)
```
