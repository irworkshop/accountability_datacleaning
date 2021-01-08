Nebraska Lobbyists
================
Kiernan Nicholls
2020-04-07 15:18:07

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
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  pdftools, # read pdf file text
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
[`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning)
GitHub repository.

The `R_campfin` project uses the [RStudio
projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects)
feature and should be run as such. The project also uses the dynamic
`here::here()` tool for file paths relative to *your* machine.

``` r
# where does this document knit?
here::here()
#> [1] "/home/kiernan/Code/accountability_datacleaning/R_campfin"
```

## Data

A list of registered lobbyists can be obtained from the [Nebraska
Legislature’s
website](https://nebraskalegislature.gov/reports/lobby.php).

> The following reports identify lobbyists registered in Nebraska with
> the Office of the Clerk of the Legislature.
> 
> ##### Lists of Registered Lobbyists
> 
>   - [Lobby Registration Report by
>     Principal](https://nebraskalegislature.gov/FloorDocs/Current/PDF/Lobby/principallist.pdf)
>   - [Lobby Registration Report by
>     Lobbyist](https://nebraskalegislature.gov/FloorDocs/Current/PDF/Lobby/lobbyistlist.pdf)
>   - [Lobbyist/Principal Expenditures
>     Report](https://nebraskalegislature.gov/FloorDocs/Current/PDF/Lobby/expense.pdf)
>   - [Lobbyist/Principal Statement of
>     Activity](https://nebraskalegislature.gov/FloorDocs/Current/PDF/Lobby/activity_final_by_bill.pdf)
>   - [Counts of
>     Lobbyists/Principals](https://nebraskalegislature.gov/FloorDocs/Current/PDF/Lobby/counts.pdf)

Each of these data files comes in PDF format only.

## Import

We will have to use the `pdftools` package to read these files and
extract the text content. We are first interested in the list of
registered lobbyists by principal clients.

``` r
pdf_file <- "https://nebraskalegislature.gov/FloorDocs/Current/PDF/Lobby/principallist.pdf"
```

The `pdftools::pdf_text()` file can read each page of the file into a
list of character strings, with each page being read as a *single*
character string list element.

``` r
nelr <- pdf_text(pdf_file)
cat(nelr[[1]])
#>                                                            CLERK OF THE LEGISLATURE'S OFFICE
#>                                                           PRINCIPALS AND REGISTERED LOBBYISTS
#>                                                           CURRENT SESSION - AS OF MARCH 12, 2020
#> Principal and Lobbyist                                        WD              Address                                                       Phone
#> 3M COMPANY                                                                    225-4N-14, St. Paul, MN 55144-100                             (651)503-4554
#>    Bromm Nielsen & Mines                                                         635 S 14th Suite 315, Lincoln, NE 68508                    (402)327-1603
#> 4 Lanes 4 Nebraska                                                            1327 H St., Ste. 101, Lincoln, NE 68508                       (402)434-8040
#>    Husch Blackwell Strategies                                                    1327 H Street, Lincoln, NE 68508                           (402)434-8040
#> AAA Nebraska and The Auto Club Group                                          910 N. 96th Street, Omaha, NE 68114                           (402)938-3806
#>    White, Rosemary                                                               910 N. 96th Street, Omaha, NE 68114                        (402)938-3806
#> AARP Nebraska                                                                 301 S. 13th Street Suite 201, Lincoln, NE 68508               (402)323-5421
#>    American Communications Group, Inc.                                           1141 H Street, Suite B, Lincoln, NE 68508                  (402)475-0727
#>    Decamp, Suzan                                                                 301 South 13th Street, Suite 201, Lincoln, NE 68508        (402)323-5424
#>    DeLong, Danny                                                                 P.O. Box 501, Beatrice, NE 68310                           (402)323-5424
#>    Holmquist, David                                                              301 S. 13th Street, Suite 201, Lincoln, NE 68508           (402)323-5424
#>    Lassen, Robert                                                                301 S. 13th Street, Suite 201, Lincoln, NE 68508           (402)323-5424
#>    Nathan, Robbie                                                                301 S. 13th Street, Suite 201, Lincoln, NE 68508           (402)323-5424
#>    Potter, Tim                                                                   301 South 13th Street, Suite 201, Lincoln, NE 68508        (402)323-5424
#>    Ragland, Jina                                                                 301 S. 13th St. Ste. 201, Lincoln, NE 68508                (402)323-2524
#>    Stubbendieck, Todd                                                            301 S. 13th Street Suite 201, Lincoln, NE 68508            (402)323-5421
#>    Ward, Kathryn                                                                 301 S. 13th Street, Suite 201, Lincoln, NE 68508           (402)323-5424
#> ACLU Nebraska                                                                 134 S. 13th Street, #1010, Lincoln, NE 68508                  (402)476-8091
#>    Conrad, Danielle                                                              134 S. 13th Street, #1010, Lincoln, NE 68508               (402)476-8091
#>    Eickholt, Christopher/Spike                                                   134 South 13th Street Suite #505, Lincoln, NE 68508        (402)310-5663
#>    Godinez, Rosangela                                                            134 South 13th Street, #1010, Lincoln, NE 68508            (402)476-8091
#>    Radcliffe, Walter H. of Radcliffe Gilbertson & Brady                          625 S. 14th Street, Suite 100, Lincoln, NE 68508           (402)476-7272
#>    Richters, Rebecca S.                                                          134 South 13th Street, #1010, Lincoln, NE 68508            (402)476-8091
#>    Sipple, Adam                                                                  134 South 13th Streeet, #1010, Lincoln, NE 68508           (402)476-8091106
#> ACT, Inc.                                                                     c/o 2350 Kerner Blvd., Ste. 250, San Rafael, CA 94901         (415)389-6800
#>    Lawrence, Katherine                                                           c/o 2350 Kerner Blvd., Ste. 250, San Rafael, CA 94901      (415)389-6800
#> Adams Central Public Schools                                                  1090 S. Adams Central Road, Box 1088, Hastings, NE 68902-1088 (402)463-3285
#>    Nowka & Edwards                                                               1233 Lincoln Mall, Suite 201, Lincoln, NE 68508            (402)476-1440
#> Advance America                                                               135 North Church Street, Spartanburg, SC 29306                (573)424-0760
#>    Townsend, Julie                                                               135 North Church Street, Spartanburg, SC 29306             (573)424-0760
#> Advance America c/o MultiState Associates, Inc.                               515 King Street, Suite 300, Alexandria, VA 22314              (703)684-1110
#>    Radcliffe, Walter H. of Radcliffe Gilbertson & Brady                          625 S. 14th Street, Suite 100, Lincoln, NE 68508           (402)476-7272
#> Advanced Power Alliance                                                       610 Brazos Street, Suite 210, Austin, TX 78701                (512)651-0291
#>    American Communications Group, Inc.                                           1141 H Street, Suite B, Lincoln, NE 68508                  (402)475-0727
#> Advantage Capital                                                             190 Carondelet Plaza, St. Louis, MO 63105                     (314)882-6168
#>    Kelley Plucker, LLC                                                           2804 S 87th Avenue, Omaha, NE 68124                        (402)397-1898
#> Advocates for Behavioral Health                                               14302 FNB Parkway, Omaha, NE 68154                            (402)691-9518
#>    Peetz & Company                                                               1233 Lincoln Mall, Suite 202, Lincoln, NE 68508            (402)438-4960
#> Aflac                                                                         1932 Wynnton Road, Columbus, GA 31999                         (706)596-3855
#>    Bromm Nielsen & Mines                                                         635 S 14th Suite 315, Lincoln, NE 68508                    (402)327-1603
#> 03/12/2020             09:45 am                         Lobbyist Registration, Room 2014 State Capitol, Lincoln NE 68509 (402) 471-2608               1
```

We can define a function that uses the `stringr` and `tibble` packages
to takes these page strings and split them up and wrangle them into a
data frame. The file is structured so that lobbyists are listed below
each of their principals, indented by 3 spaces. We can use that
structure to identify which rows are lobbyists, then split the string
into three columns.

Before this, we will need to note the date of the file.

``` r
lob_date <- mdy(str_extract(nelr[[1]], "(?<=AS OF )\\w+ \\d{1,2}, \\d{4}"))
lob_year <- year(lob_date)
```

``` r
pdf_table <- function(page) {
  # split the page into lines
  x <- page %>%
    str_remove_all("\\sWD\\s") %>%
    str_split("\n") %>%
    `[[`(1)
  # define the rows to remove
  heading <- 1:str_which(x, "^Principal and Lobbyist\\s")
  footer <- str_which(x, "Lobbyist Registration, Room 2014 State Capitol"):length(x)
  x <- x[-c(heading, footer)]
  # enframe the rows and separate
  x <- x %>%
    enframe(name = NULL, value = "line") %>%
    mutate(
      indent = str_detect(line, "^\\s{3}\\w"),
      line = str_trim(line)
    ) %>%
    separate(
      col = line,
      into = c("name", "address"),
      sep = "\\s{2,}",
      extra = "merge"
    ) %>% 
    separate(
      col = address,
      into = c("address", "phone"),
      sep = "\\s+(?=\\()"
    )
}
```

``` r
nelr <- nelr %>% 
  map_dfr(pdf_table) %>%
  filter(phone %>% str_detect("^\\(")) %>%
  mutate(
    pri_name = ifelse(!indent, name, NA),
    pri_geo = ifelse(!indent, address, NA),
    pri_phone = ifelse(!indent, phone, NA)
  ) %>%
  fill(starts_with("pri")) %>%
  filter(indent) %>%
  select(-indent) %>% 
  rename(
    lob_name = name,
    lob_geo = address,
    lob_phone = phone
  )
```

    #> # A tibble: 809 x 6
    #>    lob_name         lob_geo              lob_phone   pri_name         pri_geo            pri_phone 
    #>    <chr>            <chr>                <chr>       <chr>            <chr>              <chr>     
    #>  1 Bromm Nielsen &… 635 S 14th Suite 31… (402)327-1… 3M COMPANY       225-4N-14, St. Pa… (651)503-…
    #>  2 Husch Blackwell… 1327 H Street, Linc… (402)434-8… 4 Lanes 4 Nebra… 1327 H St., Ste. … (402)434-…
    #>  3 White, Rosemary  910 N. 96th Street,… (402)938-3… AAA Nebraska an… 910 N. 96th Stree… (402)938-…
    #>  4 American Commun… 1141 H Street, Suit… (402)475-0… AARP Nebraska    301 S. 13th Stree… (402)323-…
    #>  5 Decamp, Suzan    301 South 13th Stre… (402)323-5… AARP Nebraska    301 S. 13th Stree… (402)323-…
    #>  6 DeLong, Danny    P.O. Box 501, Beatr… (402)323-5… AARP Nebraska    301 S. 13th Stree… (402)323-…
    #>  7 Holmquist, David 301 S. 13th Street,… (402)323-5… AARP Nebraska    301 S. 13th Stree… (402)323-…
    #>  8 Lassen, Robert   301 S. 13th Street,… (402)323-5… AARP Nebraska    301 S. 13th Stree… (402)323-…
    #>  9 Nathan, Robbie   301 S. 13th Street,… (402)323-5… AARP Nebraska    301 S. 13th Stree… (402)323-…
    #> 10 Potter, Tim      301 South 13th Stre… (402)323-5… AARP Nebraska    301 S. 13th Stree… (402)323-…
    #> # … with 799 more rows

## Wrangle

This new `lob_address` column can now be split into it’s components with
`tidyr::separate()`.

``` r
nelr <- nelr %>%
  separate(
    col = lob_geo,
    into = c(glue("lob_street{1:10}"), "lob_city", "lob_state_zip"),
    sep = ",\\s",
    fill = "left",
    remove = FALSE
  ) %>%
  unite(
    starts_with("lob_street"),
    col = "lob_address",
    sep = " ",
    na.rm = TRUE
  ) %>%
  separate(
    col = lob_state_zip,
    sep = "\\s(?=\\d)",
    into = c("lob_state", "lob_zip")
  )
```

The same process needs to be done for the `pri_address`.

``` r
nelr <- nelr %>%
  separate(
    col = pri_geo,
    into = c(glue("pri_street{1:10}"), "pri_city", "pri_state_zip"),
    sep = ",\\s",
    fill = "left",
    remove = FALSE
  ) %>%
  unite(
    starts_with("pri_street"),
    col = "pri_address",
    sep = " ",
    na.rm = TRUE
  ) %>%
  separate(
    col = pri_state_zip,
    sep = "\\s(?=\\d)",
    into = c("pri_state", "pri_zip")
  )
```

### Phone

``` r
nelr <- nelr %>% 
  mutate_at(
    .vars = vars(ends_with("phone")),
    .fun = list(norm = normal_phone)
  )
```

### Address

``` r
nelr <- nelr %>% 
  mutate_at(
    .vars = vars(ends_with("address")),
    .fun = list(norm = normal_address),
    abbs = usps_street,
    na_rep = TRUE
  )
```

    #> # A tibble: 514 x 2
    #>    pri_address                               pri_address_norm                       
    #>    <chr>                                     <chr>                                  
    #>  1 1650 Farnam Street                        1650 FARNAM ST                         
    #>  2 PO Box 406                                PO BOX 406                             
    #>  3 6601 Pioneers Boulevard Ste 1             6601 PIONEERS BLVD STE 1               
    #>  4 8055 O Street Suite 300                   8055 O ST STE 300                      
    #>  5 66455 Ponderrosa Road                     66455 PONDERROSA RD                    
    #>  6 9019 South 72nd Street                    9019 S 72 ND ST                        
    #>  7 215 Centennial Mall South Suite 310       215 CENTENNIAL MALL S STE 310          
    #>  8 C/O Morrow Willnauer 1299 Farnam Ste. 250 CO MORROW WILLNAUER 1299 FARNAM STE 250
    #>  9 P.O. Box 200                              PO BOX 200                             
    #> 10 1321 Jones St.                            1321 JONES ST                          
    #> # … with 504 more rows

### ZIP

``` r
nelr <- nelr %>% 
  mutate_at(
    .vars = vars(ends_with("zip")),
    .fun = list(norm = normal_zip),
    na_rep = TRUE
  )
```

    #> # A tibble: 4 x 6
    #>   stage        prop_in n_distinct prop_na n_out n_diff
    #>   <chr>          <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 lob_zip        0.974        110 0.00371    21     15
    #> 2 lob_zip_norm   1             98 0.00371     0      1
    #> 3 pri_zip        0.931        238 0.0136     55     39
    #> 4 pri_zip_norm   0.995        213 0.0136      4      5

### State

The `*_state` components do not need to be wrangled.

``` r
prop_in(nelr$lob_state, valid_state)
#> [1] 0.9950556
prop_in(nelr$pri_state, valid_state)
#> [1] 0.9975278
```

### City

``` r
nelr <- nelr %>% 
  mutate_at(
    .vars = vars(ends_with("city")),
    .fun = list(norm = normal_city),
    na_rep = TRUE
  )
```

``` r
nelr <- nelr %>% 
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
nelr <- nelr %>% 
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
    #>   stage         prop_in n_distinct prop_na n_out n_diff
    #>   <chr>           <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 lob_city        0             57 0.00124   808     57
    #> 2 lob_city_norm   0.996         56 0.00124     3      4
    #> 3 lob_city_swap   1             55 0.00618     0      1

    #> # A tibble: 3 x 6
    #>   stage         prop_in n_distinct prop_na n_out n_diff
    #>   <chr>           <dbl>      <dbl>   <dbl> <dbl>  <dbl>
    #> 1 pri_city      0.00124        129 0.00124   807    128
    #> 2 pri_city_norm 0.978          125 0.00124    18      6
    #> 3 pri_city_swap 1              121 0.0247      0      1

## Export

``` r
nelr <- nelr %>% 
  select(
    lob_name,
    lob_addr = lob_address_norm,
    lob_city = lob_city_swap,
    lob_state,
    lob_zip = lob_zip_norm,
    pri_name,
    pri_addr = pri_address_norm,
    pri_city = pri_city_swap,
    pri_state,
    pri_zip = pri_zip_norm,
  ) %>% 
  mutate(
    date = lob_date, 
    year = lob_year,
    .before = lob_name
  )
```

``` r
clean_dir <- dir_create(here("ne", "lobbying", "data", "clean"))
clean_path <- path(clean_dir, "ne_lobbyist_clean.csv")
write_csv(nelr, clean_path, na = "")
```

``` r
nrow(nelr)
#> [1] 809
file_size(clean_path)
#> 115K
guess_encoding(clean_path)
#> # A tibble: 1 x 2
#>   encoding confidence
#>   <chr>         <dbl>
#> 1 ASCII             1
```
