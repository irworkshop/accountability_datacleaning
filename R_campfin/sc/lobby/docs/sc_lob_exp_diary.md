South Carolina Lobbying Expenditure Diary
================
Yanqi Xu
2020-03-27 14:21:31

<!-- Place comments regarding knitting here -->

## Project

The Accountability Project is an effort to cut across data silos and
give journalists, policy professionals, activists, and the public at
large a simple way to search across huge volumes of public data about
people and organizations.

Our goal is to standardizing public data on a few key fields by thinking
of each dataset row as a transaction. For each transaction there should
be (at least) 3 variables:

1.  All **parties** to a transaction.
2.  The **date** of the transaction.
3.  The **amount** of money involved.

## Objectives

This document describes the process used to complete the following
objectives:

1.  How many records are in the database?
2.  Check for entirely duplicated records.
3.  Check ranges of continuous variables.
4.  Is there anything blank or missing?
5.  Check for consistency issues.
6.  Create a five-digit ZIP Code called `zip`.
7.  Create a `year` field from the transaction date.
8.  Make sure there is data on both parties to a transaction.

## Packages

The following packages are needed to collect, manipulate, visualize,
analyze, and communicate these results. The `pacman` package will
facilitate their installation and attachment.

The IRW’s `campfin` package will also have to be installed from GitHub.
This package contains functions custom made to help facilitate the
processing of campaign finance data.

``` r
if (!require("pacman")) install.packages("pacman")
pacman::p_load_current_gh("irworkshop/campfin")
pacman::p_load(
  readxl, # read excel files
  rvest, # used to scrape website and get html elements
  tidyverse, # data manipulation
  stringdist, # calculate distances between strings
  lubridate, # datetime strings
  magrittr, # pipe opperators
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  httr, # http queries
  glue, # combine strings
  here, # relative storage
  fs # search storage 
)
```

This document should be run as part of the `R_campfin` project, which
lives as a sub-directory of the more general, language-agnostic
[`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning)
GitHub repository.

The `R_campfin` project uses the [Rstudio
projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects "Rproj")
feature and should be run as such. The project also uses the dynamic
`here::here()` tool for file paths relative to *your* machine.

``` r
# where does this document knit?
here::here()
#> [1] "/Users/yanqixu/code/accountability_datacleaning/R_campfin"
```

## Data

Lobbyist data is obtained from the \[South Carolina State Ethics
Commission\]\[03\].

> #### Welcome
> 
> Registrations for both lobbyists and their respective lobbyist’s
> principals are available online for viewing. Disclosure for both
> lobbyists and their respective lobbyist’s principals will also be
> available at the conclusion of the first disclosure period, June 30,
> 2009, for the period, January 1, 2009 through May 31, 2009.

The \[lobbying activity page\]\[04\], we can see the files that can be
retrieved:

> #### Lobbying Activity
> 
> Welcome to the State Ethics Commission Online Public Disclosure and
> Accountability Reporting System for Lobbying Activity. Registrations
> for both lobbyists and their respective lobbyist’s principals are
> available online for viewing.
> 
> Disclosure for both lobbyists and their respective lobbyist’s
> principals are available for the period June 30, 2009 through the
> present.
> 
> These filings can be accessed by searching individual reports by
> lobbyist and lobbyist’s principal names and by complete list of
> current lobbyist and lobbyist’s principal registrations.

> #### List Reports
> 
> View a list of lobbyists, lobbyists’ principals or their contact
> information.
> 
>   - [Lobbyists and Their
>     Principals](https://apps.sc.gov/LobbyingActivity/SelectLobbyistGroup.aspx)
>   - [Download Lobbyist Contacts (CSV
>     file)](https://apps.sc.gov/LobbyingActivity/DisplayCsv.aspx)
>   - [Individual Lobbyist
>     Lookup](https://apps.sc.gov/LobbyingActivity/SearchLobbyistContact.aspx)
>   - [Lobbyists’ Principals and Their
>     Lobbyists](https://apps.sc.gov/LobbyingActivity/SelectLobbyistPrincipalGroup.aspx)
>   - [Download Lobbyist’s Principal Contacts (CSV
>     file)](https://apps.sc.gov/LobbyingActivity/DisplayCsv.aspx)
>   - [Individual Lobbyist’s Principal
>     Lookup](https://apps.sc.gov/LobbyingActivity/SearchLPContact.aspx)
>   - [Year End Compilation
>     Report](https://apps.sc.gov/LobbyingActivity/CompilationReport.aspx)

This data diary handles processing of the lobbyist compensation and
expenditure data, which can be accessed from the `Year End Compilation
Report` by year.

## Import

### Setting up Raw Data Directory

``` r
raw_dir <- dir_create(here("sc", "lobby", "data", "raw", "exp"))
```

### Download

We can see that though 2007 and 2008 were selectable in the drowdown
menu, there’s actually no data.

### Read

``` r
read_exp <- function(file_path){
  df <- read_lines(file_path) %>% 
  str_replace_all("(?<!^|,)\"(?!$|,)", "'") %>% 
  read_delim(",", escape_backslash = FALSE, escape_double = FALSE)
  #get rid of the extraneous column 'X27'
  df <- df %>% select(-ncol(df))
  df <- df %>% 
    clean_names() %>% 
    mutate(year = str_extract(file_path, "\\d{4}"))
}

scle <- map_dfr(dir_ls(raw_dir), read_exp)
```

## Explore

``` r
head(scle)
#> # A tibble: 6 x 27
#>   lobbyist lobbyists_princ… income_received… income_received… income_received… supplies_period…
#>   <chr>    <chr>            <chr>            <chr>            <chr>            <chr>           
#> 1 Aaron  … SC Education As… $10,000.00       $10,000.00       $20,000.00       $0.00           
#> 2 Aaron J… American Colleg… $15,000.00       $0.00            $15,000.00       $0.00           
#> 3 Adrian … SC Bankers Asso… $38,547.76       $41,551.61       $80,099.37       $335.30         
#> 4 Alan  W… Citigroup Washi… $3,396.47        $0.00            $3,396.47        $0.00           
#> 5 Allan E… Covering Caroli… $0.00            $0.00            $0.00            $0.00           
#> 6 Allan E… South Carolina … $58,188.46       $19,396.15       $77,584.61       $0.00           
#> # … with 21 more variables: supplies_period_2 <chr>, supplies_period_calendar_year_total <chr>,
#> #   rent_period_1 <chr>, rent_period_2 <chr>, rent_period_calendar_year_total <chr>,
#> #   utilities_period_1 <chr>, utilities_period_2 <chr>,
#> #   utilities_period_calendar_year_total <chr>, compensation_period_1 <chr>,
#> #   compensation_period_2 <chr>, compensation_period_calendar_year_total <chr>,
#> #   other_expenditures_period_1 <chr>, other_expenditures_period_2 <chr>,
#> #   other_expenditures_calendar_year_total <chr>,
#> #   expenditures_made_on_behalf_of_judiciary_period_1 <chr>,
#> #   expenditures_made_on_behalf_of_judiciary_period_2 <chr>,
#> #   expenditures_made_on_behalf_of_judiciary_period_calendar_year_total <chr>,
#> #   total_income_and_expenditures_period_1 <chr>, total_income_and_expenditures_period_2 <chr>,
#> #   total_income_and_expenditures_calendar_year_total <chr>, year <chr>
tail(scle)
#> # A tibble: 6 x 27
#>   lobbyist lobbyists_princ… income_received… income_received… income_received… supplies_period…
#>   <chr>    <chr>            <chr>            <chr>            <chr>            <chr>           
#> 1 Derek  … CenturyLink      $0.00            $0.00            $0.00            $0.00           
#> 2 Edward … Richland County  $2,125.00        $0.00            $2,125.00        $26.00          
#> 3 Edwin D… South Carolina … $0.00            $0.00            $0.00            $0.00           
#> 4 Justin … Optum, Inc.      $0.00            $0.00            $0.00            $0.00           
#> 5 Justin … United Healthca… $0.00            $0.00            $0.00            $0.00           
#> 6 Michael… Molina Healthca… $0.00            $0.00            $0.00            $0.00           
#> # … with 21 more variables: supplies_period_2 <chr>, supplies_period_calendar_year_total <chr>,
#> #   rent_period_1 <chr>, rent_period_2 <chr>, rent_period_calendar_year_total <chr>,
#> #   utilities_period_1 <chr>, utilities_period_2 <chr>,
#> #   utilities_period_calendar_year_total <chr>, compensation_period_1 <chr>,
#> #   compensation_period_2 <chr>, compensation_period_calendar_year_total <chr>,
#> #   other_expenditures_period_1 <chr>, other_expenditures_period_2 <chr>,
#> #   other_expenditures_calendar_year_total <chr>,
#> #   expenditures_made_on_behalf_of_judiciary_period_1 <chr>,
#> #   expenditures_made_on_behalf_of_judiciary_period_2 <chr>,
#> #   expenditures_made_on_behalf_of_judiciary_period_calendar_year_total <chr>,
#> #   total_income_and_expenditures_period_1 <chr>, total_income_and_expenditures_period_2 <chr>,
#> #   total_income_and_expenditures_calendar_year_total <chr>, year <chr>
glimpse(sample_n(scle, 20))
#> Observations: 20
#> Variables: 27
#> $ lobbyist                                                            <chr> "Merrill A McGregor"…
#> $ lobbyists_principal                                                 <chr> "South Carolina Coas…
#> $ income_received_for_lobbying_period_1                               <chr> "$10,090.40", "$7,50…
#> $ income_received_for_lobbying_period_2                               <chr> "$1,935.62", "$7,500…
#> $ income_received_for_lobbying_calendar_year_total                    <chr> "$12,026.02", "$15,0…
#> $ supplies_period_1                                                   <chr> "$0.00", "$0.00", "$…
#> $ supplies_period_2                                                   <chr> "$0.00", "$0.00", "$…
#> $ supplies_period_calendar_year_total                                 <chr> "$0.00", "$0.00", "$…
#> $ rent_period_1                                                       <chr> "$939.72", "$0.00", …
#> $ rent_period_2                                                       <chr> "$308.62", "$0.00", …
#> $ rent_period_calendar_year_total                                     <chr> "$1,248.34", "$0.00"…
#> $ utilities_period_1                                                  <chr> "$366.44", "$0.00", …
#> $ utilities_period_2                                                  <chr> "$113.80", "$0.00", …
#> $ utilities_period_calendar_year_total                                <chr> "$480.24", "$0.00", …
#> $ compensation_period_1                                               <chr> "$0.00", "$0.00", "$…
#> $ compensation_period_2                                               <chr> "$0.00", "$0.00", "$…
#> $ compensation_period_calendar_year_total                             <chr> "$0.00", "$0.00", "$…
#> $ other_expenditures_period_1                                         <chr> "$2,246.65", "$0.00"…
#> $ other_expenditures_period_2                                         <chr> "$914.71", "$0.00", …
#> $ other_expenditures_calendar_year_total                              <chr> "$3,161.36", "$0.00"…
#> $ expenditures_made_on_behalf_of_judiciary_period_1                   <chr> "$0.00", "$0.00", "$…
#> $ expenditures_made_on_behalf_of_judiciary_period_2                   <chr> "$0.00", "$0.00", "$…
#> $ expenditures_made_on_behalf_of_judiciary_period_calendar_year_total <chr> "$0.00", "$0.00", "$…
#> $ total_income_and_expenditures_period_1                              <chr> "$13,643.21", "$7,50…
#> $ total_income_and_expenditures_period_2                              <chr> "$3,272.75", "$7,500…
#> $ total_income_and_expenditures_calendar_year_total                   <chr> "$16,915.96", "$15,0…
#> $ year                                                                <chr> "2019", "2018", "201…
```

### Missing

There’re no missing fields

``` r
col_stats(scle, count_na)
#> # A tibble: 27 x 4
#>    col                                                                 class     n     p
#>    <chr>                                                               <chr> <int> <dbl>
#>  1 lobbyist                                                            <chr>     0     0
#>  2 lobbyists_principal                                                 <chr>     0     0
#>  3 income_received_for_lobbying_period_1                               <chr>     0     0
#>  4 income_received_for_lobbying_period_2                               <chr>     0     0
#>  5 income_received_for_lobbying_calendar_year_total                    <chr>     0     0
#>  6 supplies_period_1                                                   <chr>     0     0
#>  7 supplies_period_2                                                   <chr>     0     0
#>  8 supplies_period_calendar_year_total                                 <chr>     0     0
#>  9 rent_period_1                                                       <chr>     0     0
#> 10 rent_period_2                                                       <chr>     0     0
#> 11 rent_period_calendar_year_total                                     <chr>     0     0
#> 12 utilities_period_1                                                  <chr>     0     0
#> 13 utilities_period_2                                                  <chr>     0     0
#> 14 utilities_period_calendar_year_total                                <chr>     0     0
#> 15 compensation_period_1                                               <chr>     0     0
#> 16 compensation_period_2                                               <chr>     0     0
#> 17 compensation_period_calendar_year_total                             <chr>     0     0
#> 18 other_expenditures_period_1                                         <chr>     0     0
#> 19 other_expenditures_period_2                                         <chr>     0     0
#> 20 other_expenditures_calendar_year_total                              <chr>     0     0
#> 21 expenditures_made_on_behalf_of_judiciary_period_1                   <chr>     0     0
#> 22 expenditures_made_on_behalf_of_judiciary_period_2                   <chr>     0     0
#> 23 expenditures_made_on_behalf_of_judiciary_period_calendar_year_total <chr>     0     0
#> 24 total_income_and_expenditures_period_1                              <chr>     0     0
#> 25 total_income_and_expenditures_period_2                              <chr>     0     0
#> 26 total_income_and_expenditures_calendar_year_total                   <chr>     0     0
#> 27 year                                                                <chr>     0     0
```

### Duplicates

There 0 duplicate columns.

``` r
scle <- flag_dupes(scle, dplyr::everything())
sum(scle$dupe_flag)
#> [1] 6
```

### Continuous

All the amount columns are character columns that contain special
characters like “$” and “,”.We will turn them into numeric columns.

``` r
scle <- scle %>% 
  mutate_at(.vars = vars(-c(lobbyist, lobbyists_principal, year, dupe_flag)), .funs = str_remove_all,"\\$|,") %>% 
  mutate_at(.vars = vars(-c(lobbyist, lobbyists_principal, year, dupe_flag)), .funs = as.numeric) %>% 
  mutate_if(is.character, str_to_upper)
```

``` r
scle%>% 
  group_by(lobbyists_principal) %>% 
  summarize(med = median(total_income_and_expenditures_calendar_year_total)) %>% 
  arrange(desc(med)) %>% 
  top_n(10) %>% 
  ggplot(aes(x = reorder(lobbyists_principal,med),
         y = med)) +
  geom_col(fill = RColorBrewer::brewer.pal(3, "Dark2")[3]) +
  theme(legend.position = "none") +
  scale_x_discrete(labels = wrap_format(15)) +
  scale_y_continuous(labels = dollar) +
  coord_flip() +
  theme_minimal() +
  labs(
    title = "Top 10 Highest-spending Lobbying Principals",
    subtitle = "(Measued by median total compensation and expenditures to lobbyists)",
    caption = "Source: South Carolina State Ethics Commission",
    x = "median expenses",
    y = 'dollar'
  )
```

![](../plots/plot%20top%20receipients%20ecoh-1.png)<!-- -->

## Conclude

``` r
glimpse(sample_n(scle, 20))
#> Observations: 20
#> Variables: 28
#> $ lobbyist                                                            <chr> "L. DEWITT  ZEMP", "…
#> $ lobbyists_principal                                                 <chr> "FREEHOLD CAPITAL PA…
#> $ income_received_for_lobbying_period_1                               <dbl> 0.00, 18854.00, 3750…
#> $ income_received_for_lobbying_period_2                               <dbl> 1000.00, 18854.00, 3…
#> $ income_received_for_lobbying_calendar_year_total                    <dbl> 1000.00, 37708.00, 7…
#> $ supplies_period_1                                                   <dbl> 0.00, 100.00, 0.00, …
#> $ supplies_period_2                                                   <dbl> 0.00, 100.00, 0.00, …
#> $ supplies_period_calendar_year_total                                 <dbl> 0.00, 200.00, 0.00, …
#> $ rent_period_1                                                       <dbl> 0.00, 1539.37, 0.00,…
#> $ rent_period_2                                                       <dbl> 0.00, 1539.37, 0.00,…
#> $ rent_period_calendar_year_total                                     <dbl> 0.00, 3078.74, 0.00,…
#> $ utilities_period_1                                                  <dbl> 0.00, 0.00, 0.00, 75…
#> $ utilities_period_2                                                  <dbl> 0.00, 0.00, 0.00, 10…
#> $ utilities_period_calendar_year_total                                <dbl> 0.00, 0.00, 0.00, 18…
#> $ compensation_period_1                                               <dbl> 0.00, 0.00, 0.00, 50…
#> $ compensation_period_2                                               <dbl> 0.00, 0.00, 0.00, 70…
#> $ compensation_period_calendar_year_total                             <dbl> 0.00, 0.00, 0.00, 12…
#> $ other_expenditures_period_1                                         <dbl> 0.00, 0.00, 0.00, 20…
#> $ other_expenditures_period_2                                         <dbl> 0.00, 0.00, 0.00, 0.…
#> $ other_expenditures_calendar_year_total                              <dbl> 0.00, 0.00, 0.00, 20…
#> $ expenditures_made_on_behalf_of_judiciary_period_1                   <dbl> 0, 0, 0, 0, 0, 0, 0,…
#> $ expenditures_made_on_behalf_of_judiciary_period_2                   <dbl> 0, 0, 0, 0, 0, 0, 0,…
#> $ expenditures_made_on_behalf_of_judiciary_period_calendar_year_total <dbl> 0, 0, 0, 0, 0, 0, 0,…
#> $ total_income_and_expenditures_period_1                              <dbl> 0.00, 20493.37, 3750…
#> $ total_income_and_expenditures_period_2                              <dbl> 1000.00, 20493.37, 3…
#> $ total_income_and_expenditures_calendar_year_total                   <dbl> 1000.00, 40986.74, 7…
#> $ year                                                                <chr> "2010", "2010", "200…
#> $ dupe_flag                                                           <lgl> FALSE, FALSE, FALSE,…
```

1.  There are 12633 records in the database.
2.  There’s no duplicate record in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 0 records missing either recipient or date.
5.  Consistency in goegraphic data has been improved with
    `campfin::normal_*()`.

## Export

``` r
clean_dir <- dir_create(here("sc", "lobby", "data", "processed","exp"))
```

``` r
write_csv(
  x = scle,
  path = path(clean_dir, "sc_lob_exp_clean.csv"),
  na = ""
)
```
