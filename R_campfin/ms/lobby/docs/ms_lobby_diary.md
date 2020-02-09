Mississippi Lobbying Registration Data Diary
================
Yanqi Xu
2020-02-06 20:31:16

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
pacman::p_load_current_gh("irworkshop/campfin")
pacman::p_load(
  rvest, # read html tables
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

This document should be run as part of the `R_campfin` project, which
lives as a sub-directory of the more general, language-agnostic
\[`irworkshop/accountability_datacleaning`\]\[01\] GitHub repository.

The `R_campfin` project uses the \[RStudio projects\]\[02\] feature and
should be run as such. The project also uses the dynamic `here::here()`
tool for file paths relative to *your* machine.

## Download

Set the download directory first.

``` r
# create a directory for the raw data
raw_dir <- here("ms", "lobby", "data", "raw","reg")

dir_create(raw_dir)
```

According to \[The Secretary of State’s Office\]
[03](https://www.sos.ms.gov/Elections-Voting/Documents/2019%20Lobbying%20Guide.pdf),

> Mississippi law defines “lobbying” as:  influencing or attempting to
> influence legislative or executive action through oral or written
> communication;  solicitation of others to influence legislative or
> executive action;  paying or promising to pay anything of value
> directly or indirectly related to legislative or executive action.
> (Miss. Code Ann. § 5-8-3(k)).

> Mississippi law defines a “lobbyist’s client” as:  an entity or
> person in whose behalf the lobbyist influences or attempts to
> influence legislative or executive action.

> Mississippi law defines a “lobbyist” as an individual who:  is
> employed and receives payments, or who contracts for economic
> consideration, including reimbursement for reasonable travel and
> living expenses, for the purpose of lobbying;  represents a
> legislative or public official or public employee, or who represents a
> person, organization, association or other group, for the purpose of
> lobbying; or is a sole proprietor, owner, part owner, or shareholder
> in a business, who has a pecuniary interest in legislative or
> executive action, who engages in lobbying activities. (Miss. Code Ann.
> § 5-8-3(l)).

> Mississippi law excludes certain individuals from the definition of
> “lobbyist” and “lobbyist’s client” who are exempt from the
> registration and reporting requirements of the Lobbying Law Reform Act
> of 1994. See, Miss. Code Ann. § 5-8-7 at Appendix D for further
> information.

This Rmd file documents the MS registration data only, whereas the
expenditure data is wrangled in a separate data diary.

[Mississippi Secretary of
State](https://sos.ms.gov/elec/portal/msel2/page/search/portal.aspx)
makes lobbyist and client registry searchable and downloadable from 2010
to
2020.

``` r
ms_url_lb <- glue("https://sos.ms.gov/elec/portal/msel2/Config/Mississippi/Elections/Controls/SosWeb/Lobbyist/LobbyistSearchControls/HandlerWrap.aspx?type=1&year={2009:2020}&lastName=&firstName=&clientName=")

ms_url_cl <-  glue("https://sos.ms.gov/elec/portal/msel2/Config/Mississippi/Elections/Controls/SosWeb/Lobbyist/LobbyistSearchControls/HandlerWrap.aspx?type=3&year={2010:2020}&lastName=&firstName=&clientName=")
  

dest_file_lb <- glue("{raw_dir}/ms_lobby_lb_{2010:2019}.xls")
dest_file_cl <- glue("{raw_dir}/ms_lobby_cl_{2010:2019}.xls")
if (!all_files_new(raw_dir)) {
    download.file(
      url = ms_url_cl,
      destfile = dest_file_cl)
  download.file(
      url = ms_url_lb,
      destfile = dest_file_lb)
  Sys.sleep(1)
}
```

Then, we’ll merge each dataset into a master dataset. Note that there is
no date or year field in the individual databases, and we will need to
create such fields. [Miss. Code Ann. §§ 5-8-1, et
seq.](https://www.sos.ms.gov/Elections-Voting/Documents/2019%20Lobbying%20Guide.pdf)
regulates lobbyists registration as such.

> Current lobbying reporting processes applicable to all lobbyists and
> their respective clients in the State of Mississippi are the result of
> the Lobbying Law Reform Act of 1994. (Miss. Code Ann. §§ 5-8-1, et
> seq.). Unless excepted from the statutory definition of “lobbyist,”
> every lobbyist and lobbyist’s client must file a registration
> statement with the Secretary of State’s Office within five (5)
> calendar days after becoming a lobbyist or lobbyist’s client, or
> beginning to lobby on behalf of a new client.  
> The Mississippi lobbying cycle begins on January 1 and ends on
> December 31 of each calendar year and registration is required each
> calendar year. All lobbying reports for the cycle are filed
> electronically with the Secretary of State’s Office. Mississippi
> statute requires all registered lobbyists to file three (3) reports
> during the lobbying cycle:  
> - Legislative Mid-Session Report due on February 25th  
> \- Legislative End-of-Session Report due within ten (10) days after
> sine die  
> \- Annual Report of Expenditures due no later than January 30th  
> (Miss. Code Ann. § 5-8-11(5)(6)).  
> Registered lobbyists’ clients file one (1) report, the Annual Report,
> with the Secretary of State’s Office during the lobbying cycle.

## Reading

We discovered that the xls files are actually structured as html tables.
We’ll use the `rvest` package to read these files. Also, although 2010
is the earliest year available, the lobbyist dataset only contains one
row, and the client dataset contains none. We’ll remove them in our
directory and read the rest.

``` r
ms_cl_files <- dir_ls(raw_dir, regexp= "Client.*")
ms_lb_files <- dir_ls(raw_dir, regexp = "Lobbyist.*")
# Create function to read a html table
read_web_tb <- function(file){
  df <- read_html(file) %>% html_node("table") %>% html_table(header = T)
  return(df)
}

ms_lobby_cl <- ms_cl_files %>% map_dfr(read_web_tb, .id = "file") %>% 
                   bind_rows() %>% 
                   clean_names()


ms_lobby_lb <- ms_lb_files %>% map_dfr(read_web_tb, .id = "file") %>% 
                   bind_rows() %>% 
                   clean_names()
```

## Explore

### Duplicates

We’ll use the `flag_dupes()` function to see if there are records
identical to one another and flag the duplicates. A new variable
`dupe_flag` will be created.

``` r
ms_lobby_lb <- flag_dupes(ms_lobby_lb, dplyr::everything())
ms_lobby_cl <- flag_dupes(ms_lobby_cl, dplyr::everything())
```

### Year

``` r
ms_lobby_lb <- ms_lobby_lb %>% mutate (date = registration_date %>% as.Date(format = "%b %d %Y %I:%M%p"),
                                       year = str_extract(date,"\\d{4}")) %>% 
  select(-file)

ms_lobby_cl <- ms_lobby_cl %>% mutate (date = registration_date %>% as.Date(format = "%b %d %Y %I:%M%p"),
                                       year = str_extract(date,"\\d{4}")) %>% 
  select(-file)
```

``` r
ms_lobby_lb %>% 
  mutate(year = as.numeric(year)) %>% 
  group_by(year) %>% 
  ggplot(aes(year)) +
  scale_x_continuous(breaks = 2010:2019) +
  geom_bar(fill = RColorBrewer::brewer.pal(3, "Dark2")[1]) +
  labs(
    title = "Mississippi Lobbyists Registration by Year",
    caption = "Source: Mississippi Elections Division: Lobbying",
    x = "Year",
    y = "Count"
  )
```

![](../plots/unnamed-chunk-1-1.png)<!-- --> \#\#\# Missing There’s not a
single empty field in the two data frames.

``` r
ms_lobby_cl  %>% col_stats(count_na)
#> # A tibble: 14 x 4
#>    col                  class      n     p
#>    <chr>                <chr>  <int> <dbl>
#>  1 client_name          <chr>      0     0
#>  2 telephone            <chr>      0     0
#>  3 fax                  <chr>      0     0
#>  4 address_line1        <chr>      0     0
#>  5 address_line2        <chr>      0     0
#>  6 city                 <chr>      0     0
#>  7 state                <chr>      0     0
#>  8 postal_code          <chr>      0     0
#>  9 registration_date    <chr>      0     0
#> 10 certification_number <chr>      0     0
#> 11 description          <chr>      0     0
#> 12 dupe_flag            <lgl>      0     0
#> 13 date                 <date>     0     0
#> 14 year                 <chr>      0     0
ms_lobby_lb  %>% col_stats(count_na)
#> # A tibble: 14 x 4
#>    col                  class      n     p
#>    <chr>                <chr>  <int> <dbl>
#>  1 first_name           <chr>      0     0
#>  2 last_name            <chr>      0     0
#>  3 registration_date    <chr>      0     0
#>  4 certification_number <chr>      0     0
#>  5 client_name          <chr>      0     0
#>  6 address_line1        <chr>      0     0
#>  7 address_line2        <chr>      0     0
#>  8 city                 <chr>      0     0
#>  9 state                <chr>      0     0
#> 10 postal_code          <chr>      0     0
#> 11 telephone            <chr>      0     0
#> 12 dupe_flag            <lgl>      0     0
#> 13 date                 <date>     0     0
#> 14 year                 <chr>      0     0
```

Few values are missing from the lobbyists database.

## Wrangling

We’ll wrangle the two datasets to extract information such as address,
city, ZIP, state, phone for both lobbyists and their clients, as well as
authorization date. The lobbyists registry has the one-to-one
relationship between lobbyists and clients, so we will use `ms_lobby_lb`
as the main data frame and join the clients’ information from the
`ms_lobby_cl` data
frame.

### Phone

``` r
ms_lobby_cl <- ms_lobby_cl %>% mutate(telephone_norm = normal_phone(telephone))
ms_lobby_lb  <- ms_lobby_lb  %>% mutate(telephone_norm = normal_phone(telephone))
```

### Address

``` r
ms_lobby_lb <- ms_lobby_lb %>% 
  mutate(address_norm = normal_address(address = str_c(address_line1, address_line2, sep = " "),
      abbs = usps_city,
      na_rep = TRUE))

ms_lobby_cl <- ms_lobby_cl %>% 
  mutate(address_norm = normal_address(address = str_c(address_line1, address_line2, sep = " "),
      abbs = usps_city,
      na_rep = TRUE))
```

### ZIP

The ZIP code fields need a little bit cleaning. After cleaning, it
reaches 100% validity.

``` r
prop_in(ms_lobby_lb$postal_code, valid_zip, na.rm = TRUE) %>% percent()
#> [1] "43%"
prop_in(ms_lobby_cl$postal_code, valid_zip, na.rm = TRUE) %>% percent()
#> [1] "48%"

ms_lobby_lb <- ms_lobby_lb %>% 
  mutate(zip5 = normal_zip(postal_code))
  
ms_lobby_cl <- ms_lobby_cl %>% 
  mutate(zip5 = normal_zip(postal_code))

prop_in(ms_lobby_lb$zip5, valid_zip, na.rm = TRUE) %>% percent()
#> [1] "100%"
prop_in(ms_lobby_cl$zip5, valid_zip, na.rm = TRUE) %>% percent()
#> [1] "100%"
```

### State

Running the following commands tells us the state fields are clean.

``` r
prop_in(ms_lobby_cl$state, valid_state, na.rm = TRUE) %>% percent()
#> [1] "100%"
prop_in(ms_lobby_lb$state, valid_state, na.rm = TRUE) %>% percent()
#> [1] "100%"
```

### City

The city fields in both data frames use upper-case letters and
lower-case letters inconsistently. We’ll convert everything to upper
case.

``` r
prop_in(ms_lobby_cl$city, valid_city, na.rm = TRUE) %>% percent()
#> [1] "47%"
prop_in(ms_lobby_lb$city, valid_city, na.rm = TRUE) %>% percent()
#> [1] "55%"
```

#### Normalize

``` r
ms_lobby_lb <- ms_lobby_lb %>% mutate(city_norm = normal_city(city = city,
                                            abbs = usps_city,
                                            states = c(valid_state),
                                            na = invalid_city,
                                            na_rep = TRUE))
n_distinct(ms_lobby_lb$city)
#> [1] 247
n_distinct(ms_lobby_lb$city_norm)
#> [1] 201

prop_in(ms_lobby_lb$city, valid_city, na.rm = TRUE)
#> [1] 0.5528044
prop_in(ms_lobby_lb$city_norm, valid_city, na.rm = TRUE)
#> [1] 0.9659424
```

``` r
ms_lobby_cl <- ms_lobby_cl %>% mutate(city_norm = normal_city(city = city,
                                            abbs = usps_city,
                                            states = c(valid_state),
                                            na = invalid_city,
                                            na_rep = TRUE))
n_distinct(ms_lobby_cl$city)
#> [1] 462
n_distinct(ms_lobby_cl$city_norm)
#> [1] 367

prop_in(ms_lobby_cl$city, valid_city, na.rm = TRUE)
#> [1] 0.4659765
prop_in(ms_lobby_cl$city_norm, valid_city, na.rm = TRUE)
#> [1] 0.9603765
```

#### Swap

Then, we will compare these normalized `city_norm` values to the
*expected* city value for that vendor’s ZIP code. If the [levenshtein
distance](https://en.wikipedia.org/wiki/Levenshtein_distance) is less
than 3, we can confidently swap these two values.

``` r
ms_lobby_cl <- ms_lobby_cl %>% 
  left_join(
    y = zipcodes,
    by = c(
      "state" = "state",
      "zip5" = "zip"
    )
  ) %>% 
  rename(city_match = city.y,
         city = city.x) %>% 
  mutate(
    match_abb = is_abbrev(city_norm, city_match),
    match_dist = str_dist(city_norm, city_match),
    city_swap = if_else(
      condition = match_abb | match_dist == 1 | is.na(match_dist),
      true = city_match,
      false = city_norm
    )
  ) %>% 
  select(
    -city_match,
    -match_dist,
    -match_abb
  )

prop_in(ms_lobby_cl$city_swap, valid_city, na.rm = TRUE) %>% percent()
#> [1] "97%"
```

``` r
ms_lobby_lb <- ms_lobby_lb %>% 
  left_join(
    y = zipcodes,
    by = c(
      "state" = "state",
      "zip5" = "zip"
    )
  ) %>% 
  rename(city_match = city.y,
         city = city.x) %>% 
  mutate(
    match_abb = is_abbrev(city_norm, city_match),
    match_dist = str_dist(city_norm, city_match),
    city_swap = if_else(
      condition = match_abb | match_dist == 1,
      true = city_match,
      false = city_norm
    )
  ) %>% 
  select(
    -city_match,
    -match_dist,
    -match_abb
  )

prop_in(ms_lobby_lb$city_swap, valid_city, na.rm = TRUE) %>% percent()
#> [1] "97%"
```

Besides the `valid_city` vector, there is another vector of `extra_city`
that contains other locales. We’ll incorporate that in our comparison.

``` r
valid_place <- c(valid_city, extra_city) %>% unique()

progress_table(
  ms_lobby_cl$city,
  ms_lobby_cl$city_norm,
  ms_lobby_cl$city_swap,
  compare = valid_place
)
#> # A tibble: 3 x 6
#>   stage     prop_in n_distinct prop_na n_out n_diff
#>   <chr>       <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 city        0.481        462 0        5519    304
#> 2 city_norm   0.990        367 0         103     17
#> 3 city_swap   0.997        357 0.00508    36      7

progress_table(
  ms_lobby_lb$city,
  ms_lobby_lb$city_norm,
  ms_lobby_lb$city_swap,
  compare = valid_place
)
#> # A tibble: 3 x 6
#>   stage     prop_in n_distinct prop_na n_out n_diff
#>   <chr>       <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 city        0.560        247 0        4350    159
#> 2 city_norm   0.999        201 0           9      3
#> 3 city_swap   1.00         201 0.00121     4      2
```

This is a very fast way to increase the valid proportion in the lobbyist
data frame to 3% and reduce the number of distinct *invalid* values from
3 to only 2

Similarly, the valid proportion in the clients data frame was bumped up
to 3% and reduce the number of distinct *invalid* values from 17 to only
7

## Join

First， we noticed that the lobbyist fields in the client directory is
jumbled together. We’ll separate them first using `unnest_longer()`.

``` r
ms_lobby_cl <- ms_lobby_cl %>% 
  mutate(lobbyist = str_match(description, "Lobbyist: (\\D+) ;\\s")[,2]) 

count_na(ms_lobby_cl$lobbyist)
#> [1] 0
# remove suffixes and titles
ms_lobby_cl <- ms_lobby_cl %>% 
  mutate(lobbyist = lobbyist %>% str_remove("^Dr. |^Mr. |^Mrs. |^Ms. |^Rev. |\\sEsq.$| \\sII.$|, Sr.|, III.$|\\W*Jr.$") %>% trimws(),
         first_name = str_match(lobbyist, "(^\\S+)\\s")[,2],
         last_name = str_match(lobbyist, "\\s(\\S+)$")[,2])

count_na(ms_lobby_cl$first_name)
#> [1] 0
count_na(ms_lobby_cl$last_name)
#> [1] 0
```

After the process above, no fields of names is left empty.

``` r
ms_lobby_cl <- ms_lobby_cl %>% mutate_if(is.character, str_to_upper)
ms_lobby_lb <- ms_lobby_lb %>% mutate_if(is.character, str_to_upper)

ms_lobby_lb$dupe_flag %>% tabyl()
#> # A tibble: 1 x 3
#>   .         n percent
#>   <lgl> <dbl>   <dbl>
#> 1 FALSE  9895       1
ms_lobby_cl$dupe_flag %>% tabyl()
#> # A tibble: 1 x 3
#>   .         n percent
#>   <lgl> <dbl>   <dbl>
#> 1 FALSE 10625       1

ms_lobby_cl <- ms_lobby_cl %>% 
  select(-c(dupe_flag,
            city_norm,
            lobbyist)) %>% 
  rename(city_clean = city_swap) %>% 
  rename_at(.vars = vars(-c(first_name, last_name,starts_with("client"))),
    .funs = ~str_c("client_",.))
```

``` r
ms_lobby_reg <- ms_lobby_cl %>% 
  full_join(ms_lobby_lb %>% filter(!dupe_flag),
            by = c("client_name" = "client_name",
            "client_certification_number" = "certification_number",
            "last_name" = "last_name")) %>% 
  select(-first_name.x) %>% 
  rename(first_name = first_name.y)
```

## Export

``` r
clean_dir <- here("ms", "lobby", "data", "processed","reg")
dir_create(clean_dir)
ms_lobby_reg %>% 
  select(-c(dupe_flag,
            city_norm)) %>% 
  mutate_if(is.character, str_to_upper) %>% 
  rename(city_clean = city_swap) %>% 
  write_csv(
    path = glue("{clean_dir}/ms_lobby_reg.csv"),
    na = ""
  )

col_stats(ms_lobby_reg, count_na)
#> # A tibble: 34 x 4
#>    col                         class      n      p
#>    <chr>                       <chr>  <int>  <dbl>
#>  1 client_name                 <chr>      0 0     
#>  2 client_telephone            <chr>   1135 0.0965
#>  3 client_fax                  <chr>   1135 0.0965
#>  4 client_address_line1        <chr>   1135 0.0965
#>  5 client_address_line2        <chr>   1135 0.0965
#>  6 client_city                 <chr>   1135 0.0965
#>  7 client_state                <chr>   1135 0.0965
#>  8 client_postal_code          <chr>   1135 0.0965
#>  9 client_registration_date    <chr>   1135 0.0965
#> 10 client_certification_number <chr>      0 0     
#> 11 client_description          <chr>   1135 0.0965
#> 12 client_date                 <date>  1135 0.0965
#> 13 client_year                 <chr>   1135 0.0965
#> 14 client_telephone_norm       <chr>   1135 0.0965
#> 15 client_address_norm         <chr>   1135 0.0965
#> 16 client_zip5                 <chr>   1135 0.0965
#> 17 client_city_clean           <chr>   1189 0.101 
#> 18 last_name                   <chr>      0 0     
#> 19 first_name                  <chr>   1838 0.156 
#> 20 registration_date           <chr>   1838 0.156 
#> 21 address_line1               <chr>   1838 0.156 
#> 22 address_line2               <chr>   1838 0.156 
#> 23 city                        <chr>   1838 0.156 
#> 24 state                       <chr>   1838 0.156 
#> 25 postal_code                 <chr>   1838 0.156 
#> 26 telephone                   <chr>   1838 0.156 
#> 27 dupe_flag                   <lgl>   1838 0.156 
#> 28 date                        <date>  1838 0.156 
#> 29 year                        <chr>   1838 0.156 
#> 30 telephone_norm              <chr>   1838 0.156 
#> 31 address_norm                <chr>   1838 0.156 
#> 32 zip5                        <chr>   1847 0.157 
#> 33 city_norm                   <chr>   1838 0.156 
#> 34 city_swap                   <chr>   1850 0.157
```

We can see that there are over 1,000 columns from each dataframe that
doesn’t have corresponding information from another one.
