Hawaii Lobbyists
================
Kiernan Nicholls
2019-11-25 12:24:36

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Wrangle](#wrangle)
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
pacman::p_load_gh("kiernann/gluedown")
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  jsonlite, # read json files
  magrittr, # pipe opperators
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
  readxl, # read excel files
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

Data can be obtained by the [Hawaii State Ethics
Commission](https://ethics.hawaii.gov/) via their [Socrata
portal](https://data.hawaii.gov/).

The relavent file is named $, hi\_meta, name with the ID of `gdxe-t5ff`.
The file was created at 2013-10-29 22:49:30.

There are 8 columns in the database.

``` r
hi_meta %>% 
  use_series("columns") %>% 
  as_tibble() %>% 
  select(
    position,
    fieldName,
    name,
    dataTypeName
  ) %>%
  mutate(fieldName = md_code(fieldName)) %>% 
  kable(col.names = c("col", "variable", "name", "type"))
```

| col | variable            | name              |      type      |
| --: | :------------------ | :---------------- | :------------: |
|   1 | `registration_form` | View              |      url       |
|   2 | `lobbyist`          | Lobbyist Name     |      text      |
|   3 | `organization`      | Organization Name |      text      |
|   4 | `lobby_year`        | Lobby Year        |      text      |
|   5 | `registration`      | Registration      | calendar\_date |
|   6 | `termination`       | Termination       | calendar\_date |
|   7 | `original`          | Original          |    checkbox    |
|   8 | `amended`           | Amended           |    checkbox    |

This data does *not* include the mailing addresses of the lobbyists and
principal organizations. After contacting the Ethics Commission, I was
provided with an Excel file containing the additional mailing address
variable; this data will be processed and added to the site.

## Import

If the file containing addresses is found on disc, the wrangling will
continue; otherwise, the raw file will be read from the portal and not
wrangled any futher.

``` r
raw_dir <- here("hi", "lobbying", "data", "raw")
dir_create(raw_dir)
```

``` r
geo_file <- dir_ls(raw_dir, type = "file", glob = "*.xlsx") 
raw_file <- "https://data.hawaii.gov/api/views/gdxe-t5ff/rows.csv"

if (file_exists(geo_file)) {
  # read the excel file
  hilr <- 
     read_csv(
      file = format_csv(read_excel(geo_file)),
      skip = 1,
      col_names = c(
        "reg_name", "lob_name", "org_name", "lob_firm", "date_filed", "status", 
        "date_reg", "date_term", "lob_email", "lob_phone", "lob_ext", "lob_geo", 
        "lob_city", "lob_state", "lob_zip"
      ),
      col_types = cols(
        .default = col_character(),
        date_filed = col_date_usa(),
        date_reg = col_date_usa(),
        date_term = col_date_usa()
      )
    )
} else {
  # read the portal file
  hilr <- 
    read_csv(
      file = raw_file,
      col_types = cols(
        Registration = col_date_usa(),
        Termination = col_date_usa()
      )
    ) %>%
    # rename, reorder, and clean
    rename(
      lob_name = `Lobbyist Name`,
      org_name = `Organization Name`,
      session = `Lobby Year`
    ) %>% 
    select(-View, View) %>% 
    clean_names() %>% 
    mutate(view = str_extract(view, "(?<=\\()(.*)(?=\\))"))
  # stop the document
  knit_exit()
}
```

## Wrangle

### Phone

To normalize the lobbyist phone number variable, will will combine the
number and extension with `tidyr::unite()` and pass the united string to
`campfin::normal_phone()`.

``` r
hilr <- hilr %>% 
  unite(
    lob_phone, lob_ext,
    col = "lob_phone_norm",
    sep = "x",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    lob_phone_norm = normal_phone(
      number = lob_phone_norm,
      na_bad = FALSE,
      rm_ext = FALSE
    )
  )
```

    #> # A tibble: 267 x 3
    #>    lob_phone      lob_ext lob_phone_norm
    #>    <chr>          <chr>   <chr>         
    #>  1 3016952228     <NA>    (301) 695-2228
    #>  2 (808) 973-1690 <NA>    (808) 973-1690
    #>  3 (808) 521-2437 <NA>    (808) 521-2437
    #>  4 8085876625     <NA>    (808) 587-6625
    #>  5 (808) 544-1406 <NA>    (808) 544-1406
    #>  6 808-447-1840   <NA>    (808) 447-1840
    #>  7 (808) 531-4551 <NA>    (808) 531-4551
    #>  8 808-432-5224   <NA>    (808) 432-5224
    #>  9 8086770375     <NA>    (808) 677-0375
    #> 10 808 791-7830   <NA>    (808) 791-7830
    #> # … with 257 more rows

### Address

``` r
hilr <- hilr %>%
  mutate(
    lob_addr_split = str_remove(lob_geo, glue(",\\s{lob_city},\\s{lob_state}\\s{lob_zip}.*$")),
    lob_addr_norm = normal_address(
      address = lob_addr_split,
      abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-lob_addr_split)
```

    #> # A tibble: 229 x 2
    #>    lob_geo                                                        lob_addr_norm                    
    #>    <chr>                                                          <chr>                            
    #>  1 835 Colchester Dr., Suite E, Port Orchard, Washington 94107 U… 835 COLCHESTER DRIVE SUITE EAST  
    #>  2 "Peters Communications\r\r\n3655 Kawelolani Place, Honolulu, … PETERS COMMUNICATIONS 3655 KAWEL…
    #>  3 733 Bishop Street, Suite 1900, Honolulu, Hawaii 96813 United … 733 BISHOP STREET SUITE 1900     
    #>  4 677 Ala Moana Blvd., Ste. 226, Honolulu, Hawaii 96813 United … 677 ALA MOANA BOULEVARD SUITE 226
    #>  5 1357 Kapiolani Blvd, Suite 1250, Honolulu, Hawaii 96814 Unite… 1357 KAPIOLANI BOULEVARD SUITE 1…
    #>  6 P.O. Box 327, Waianae, Hawaii 96792 United States              PO BOX 327                       
    #>  7 711 Kapiolani Blvd., Honolulu, Hawaii 96813 United States      711 KAPIOLANI BOULEVARD          
    #>  8 1775 Tysons Boulevard,  7th Floor, Tysons, Virginia 22102 Uni… 1775 TYSONS BOULEVARD 7TH FLOOR  
    #>  9 1018 Palm Drive, Honolulu, Hawaii 96814 United States          1018 PALM DRIVE                  
    #> 10 677 Ala Moana Blvd, Ste 705, Honolulu, Hawaii 96813 United St… 677 ALA MOANA BOULEVARD SUITE 705
    #> # … with 219 more rows

### ZIP

``` r
hilr <- hilr %>% 
  mutate(
    lob_zip_norm = normal_zip(
      zip = lob_zip,
      na_rep = TRUE
    )
  )
```

    #> # A tibble: 2 x 6
    #>   stage        prop_in n_distinct prop_na n_out n_diff
    #>   <chr>          <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 lob_zip        0.999         80 0.00977     1      2
    #> 2 lob_zip_norm   1             79 0.00977     0      1

### State

Aside from abbreviation the `lob_state` to the 2-digit USPS
abbreviation, no other changes need to be made to clean completely.

``` r
hilr <- hilr %>% 
  mutate(
    lob_state_norm = normal_state(
      state = lob_state,
      abbreviate = TRUE
    )
  )
```

``` r
progress_table(
  hilr$lob_state,
  hilr$lob_state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage          prop_in n_distinct prop_na n_out n_diff
#>   <chr>            <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 lob_state            0         15 0.00733   813     15
#> 2 lob_state_norm       1         15 0.00733     0      1
```

### City

The `lob_city` variable is already quite clean

``` r
hilr <- hilr %>% 
  mutate(
    lob_city_norm = normal_city(
      city = lob_city, 
      abbs = usps_city,
      states = c("HI", "DC", "HAWAII"),
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

``` r
hilr <- hilr %>% 
  left_join(
    y = zipcodes,
    by = c(
      "lob_state_norm" = "state",
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
    -match_abb,
    -match_dist
  )
```

``` r
progress_table(
  hilr$lob_city,
  hilr$lob_city_norm,
  hilr$lob_city_swap,
  compare = valid_city
)
#> # A tibble: 3 x 6
#>   stage         prop_in n_distinct prop_na n_out n_diff
#>   <chr>           <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 lob_city       0.0148         52 0.00977   799     51
#> 2 lob_city_norm  0.988          51 0.00977    10      7
#> 3 lob_city_swap  0.998          49 0.0122      2      3
```

## Export

``` r
proc_dir <- here("hi", "lobbying", "data", "processed")
dir_create(proc_dir)
```

``` r
hilr %>% 
  select(
    -lob_city_norm,
    -city_match,
    -lob_city,
    -lob_state,
    -lob_zip
  ) %>% 
  rename(
    lob_phone_clean = lob_phone_norm,
    lob_addr_clean = lob_addr_norm,
    lob_zip_clean = lob_zip_norm,
    lob_state_clean = lob_state_norm,
    lob_city_clean = lob_city_swap
  ) %>% 
  write_csv(
    path = glue("{proc_dir}/hi_lobby_clean.csv"),
    na = ""
  )
```
