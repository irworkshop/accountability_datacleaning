Indiana Lobbying Expenditure Diary
================
Yanqi Xu
2023-06-03 14:14:36

- <a href="#project" id="toc-project">Project</a>
- <a href="#objectives" id="toc-objectives">Objectives</a>
- <a href="#packages" id="toc-packages">Packages</a>
- <a href="#data" id="toc-data">Data</a>
- <a href="#conclude" id="toc-conclude">Conclude</a>
- <a href="#export" id="toc-export">Export</a>

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
  readxl, # read excel
  httr, # GET request
  rvest, # scrape web page
  tidyverse, # data manipulation
  lubridate, # datetime strings
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
#> [1] "/Users/yanqixu/code/accountability_datacleaning"
```

## Data

Lobbyist data is obtained from the [Indiana Lobby Registration
Commission](https://www.in.gov/ilrc/2335.htm). The data was updated
through 2022.

``` r
raw_dir <- dir_create(here("state","in", "lobby", "data", "raw", "exp"))
```

``` r
landing_url <- 'https://www.in.gov/ilrc/2335.htm'

urls <- GET(landing_url) %>% content() %>% html_nodes("a")

comp_urls <- paste0('https://www.in.gov',urls[str_detect(html_text(urls), 'Compensated Lobbyist Total')] %>% html_attr('href'))

wget <- function(url, dir) {
  system2(
    command = "wget",
    args = c(
      "--no-verbose",
      "--content-disposition",
      url,
      paste("-P", dir)
    )
  )
}

if (!this_file_new(raw_dir)) {
  map(comp_urls, wget, raw_dir)
}
```

### Read

Lobbyist data is obtained from the [Indiana Lobby Registration
Commission](https://www.in.gov/ilrc/2335.htm). At the time of data
aquisition, exployer lobbyist lists are available in xls format from
2006 to 2022.

These files come in various formats, and we will need to parse them
differently according to their file extensions. The excel files have
certain rows that we need to skip. For the terminated column, TA=Term.
April, TO=Term. October

``` r
inle_csv <- read_csv(dir_ls(raw_dir) %>% str_subset('csv'), 
                 col_types = cols(.default = col_character())) %>% 
  clean_names() 

in_0809_fs <- dir_ls(raw_dir) %>% str_subset('2008|2009')

in_1112_fs <- dir_ls(raw_dir) %>% str_subset('2011|2012')

in_1322_fs <- dir_ls(raw_dir) %>% str_subset('2013|2014|2015|2016|2017|2019|2020|2021|2022')

# Get the vector of column names by reading in the 2019 file and accessing its column headers
names_inle <- names(inle_csv)


#for (in_file in dir_ls(raw_dir) %>% str_subset('xl')) {
  
read_inxl <- function(in_file) {
df <- read_excel(in_file,range = cell_cols(1:29), col_types = "text")
                 #, col_types = c(rep("text",4), rep("numeric",25)))
# find the index of the first row whose first column (year) is not blank
 start_index <- which(!is.na(df[,1]))[1]
    df <- df[start_index:nrow(df),]
    names(df) <- names_inle
        # we also need to fill down the  lobbyist column and year column that are often shared by multiple clients
    df <- df %>% 
      mutate(year_clean = str_extract(in_file, "\\d{4}"),
             lobbyist_clean = lobbyist) %>% 
      fill(lobbyist_clean)
    return(df)
}


read_1112_inxl <- function(in_file) {
  # for 2011 and 2012
df <- read_excel(in_file, col_types = "text", range = cell_cols(1:27))
# find the index of the first row that has zero blanks
start_index <- which(rowSums(is.na(df)) == 0)[1]
    df <- df[start_index:nrow(df),]
    df <- df %>% 
      add_column(year = str_extract(in_file, "\\d{4}"),.before = 1) %>% 
      add_column(terminated = NA, .after = 3) 
    names(df) <- names_inle
    
    df <- df %>% 
      mutate(year_clean = str_extract(in_file, "\\d{4}"),
             lobbyist_clean = lobbyist) %>% 
      fill(lobbyist_clean)
    
    return(df)
}

inle_csv <- inle_csv %>% 
      mutate(year_clean = year,
             lobbyist_clean = lobbyist) %>% 
      fill(year_clean, lobbyist_clean)

in_1322 <- map_dfr(in_1322_fs, read_inxl) %>% 
  bind_rows(inle_csv)

in_1112 <- map_dfr(in_1112_fs, read_1112_inxl)

inle <- read_inxl(dir_ls(raw_dir) %>% str_subset("2010")) %>% 
  bind_rows(in_1112) %>% 
  bind_rows(in_1322)
```

Next, we can see that the file structures for 2008 and 2009 are
different from the one later on. The main difference is that: 1. The
grand_totals for each year is in its own row. 2. The `first_period_*`
and `second_period_*` columns use the same column for each category, but
there’s a `PD` column for period.

We will transform the data accordingly.

``` r
read_0809_inxl <- function(in_file){
  # Step 1: move the orphan columns to the right
  df <- read_excel(in_file, col_types = "text")
  # fix year-end
  df <- df %>% 
    # create a new column total_gross filled with all net figure columns from the left
    mutate(grand_totals = `Net Figure`) %>% 
    rename_all(.funs = str_to_lower) 
    
  #identify the index of all columns that only have three valid fields (the Year-End rows), the year-end field, the actual net figure field, and the grand_total field that we just added
  grand_total_index <- which(rowSums(!is.na(df))== 3)
  # replace all other rows' grand_total as NA
  other_index <- setdiff(1:nrow(df), grand_total_index) 
  df$grand_totals[other_index] <- NA_integer_
  # Fill the NA_interger_ with actual total_gross from the bottom
  df <- df %>% 
    fill(grand_totals, .direction = "up")
  # After this step problem 1 is fixed.
  
  # Step 2. Pivot_wider based on pd
  # We'll remove the orphan rows.
  df <- df[-grand_total_index,]
  
    # create a new column that fills down column names
  df <- df %>% 
    add_column(year = NA_character_,.before = 1) %>% 
    mutate(year_clean = str_extract(in_file,"\\d{4}"))
  
  x <- df %>% filter(pd == 1)
  x <- x %>% select(-pd)
  names(x) <- c("year","lobbyist", "client", names_inle %>% str_subset("first"),"grand_totals", "year_clean")
  
  y <- df %>% filter(pd == 2)
  y <- y %>% select(-pd)
  names(y) <- c("year","lobbyist", "client", names_inle[17:length(names_inle)], "year_clean")
  
  y <- unique(y)
  x <- unique(x)
  combined <- x %>% full_join(y, by = c("year","client","lobbyist", "grand_totals","year_clean"),multiple="all")
  
  return(combined)
}

in_0809 <- map_dfr(in_0809_fs, read_0809_inxl) %>% 
  add_column(terminated = NA_character_, .after = 3)

inle <- inle %>% 
  bind_rows(in_0809)
```

We’ll do some basic cleaning by turning all text columns to uppercase.
We also need to get rid of the commas in supposedly numeric columns,
which we deliberately read as plain text at first.

``` r
inle <-inle %>% 
  mutate_if(is.character, str_to_upper) %>% 
  clean_names() %>% 
  mutate_at(.vars = vars(-c("year", "lobbyist", "terminated", "client", "lobbyist_clean")), 
              .funs=funs(as.numeric(str_remove_all(.,"\\$|,|`"))))
```

``` r
head(inle)
#> # A tibble: 6 × 31
#>   year      lobbyist client termi…¹ first…² first…³ first…⁴ first…⁵ first…⁶ first…⁷ first…⁸ first…⁹
#>   <chr>     <chr>    <chr>  <chr>     <dbl>   <dbl>   <dbl>   <dbl>   <dbl>   <dbl>   <dbl>   <dbl>
#> 1 2009/2010 ABEL, E… BLUE … <NA>         0        0       0       0       0       0       0       0
#> 2 2009      AGUILER… TAN C… X-10     10000        0       0       0       0       0       0       0
#> 3 2009      AHLERIN… NUCOR… X-10         0        0       0       0       0       0       0       0
#> 4 2009/2010 AINSWOR… IN FA… <NA>      1051.       0       0       0       0       0       0       0
#> 5 2009/2010 ALLDRED… NATL … <NA>         0        0       0       0       0       0       0       0
#> 6 2009      ALLEN, … CHECK… X-10         0        0       0       0       0       0       0       0
#> # … with 19 more variables: first_period_other_expenses <dbl>,
#> #   first_period_gross_expenditures <dbl>, first_period_deductions <dbl>,
#> #   first_period_net_expenditures <dbl>, second_period_compensation <dbl>,
#> #   second_period_reimburse <dbl>, second_period_receptions <dbl>,
#> #   second_period_other_entertainment <dbl>, second_period_other_gifts <dbl>,
#> #   second_period_expenditures_all_members <dbl>, second_period_gifts <dbl>,
#> #   second_period_registration_late_fees <dbl>, second_period_other_expenses <dbl>, …
tail(inle)
#> # A tibble: 6 × 31
#>   year  lobbyist     client termi…¹ first…² first…³ first…⁴ first…⁵ first…⁶ first…⁷ first…⁸ first…⁹
#>   <chr> <chr>        <chr>  <chr>     <dbl>   <dbl>   <dbl>   <dbl>   <dbl>   <dbl>   <dbl>   <dbl>
#> 1 <NA>  <NA>         INDIA… <NA>         NA      NA      NA      NA      NA      NA      NA      NA
#> 2 <NA>  YAGER, STEP… INDIA… <NA>         NA      NA      NA      NA      NA      NA      NA      NA
#> 3 <NA>  <NA>         BERNA… <NA>         NA      NA      NA      NA      NA      NA      NA      NA
#> 4 <NA>  ZARICH, KAT… INDIA… <NA>         NA      NA      NA      NA      NA      NA      NA      NA
#> 5 <NA>  <NA>         IN OP… <NA>         NA      NA      NA      NA      NA      NA      NA      NA
#> 6 <NA>  <NA>         ARCEL… <NA>         NA      NA      NA      NA      NA      NA      NA      NA
#> # … with 19 more variables: first_period_other_expenses <dbl>,
#> #   first_period_gross_expenditures <dbl>, first_period_deductions <dbl>,
#> #   first_period_net_expenditures <dbl>, second_period_compensation <dbl>,
#> #   second_period_reimburse <dbl>, second_period_receptions <dbl>,
#> #   second_period_other_entertainment <dbl>, second_period_other_gifts <dbl>,
#> #   second_period_expenditures_all_members <dbl>, second_period_gifts <dbl>,
#> #   second_period_registration_late_fees <dbl>, second_period_other_expenses <dbl>, …
glimpse(sample_n(inle, 20))
#> Rows: 20
#> Columns: 31
#> $ year                                   <chr> "2019", NA, NA, NA, NA, "2011", NA, "2014", NA, NA…
#> $ lobbyist                               <chr> "HILDEBRAND, EMMY", NA, NA, NA, NA, NA, "LYLE, JUN…
#> $ client                                 <chr> "HVAF OF INDIANA, INC.", "IN FARM BUREAU", "INDIAN…
#> $ terminated                             <chr> NA, "TO", NA, NA, NA, NA, NA, NA, NA, NA, NA, "FIR…
#> $ first_period_compensation              <dbl> 0.00, 5055.23, 2116.67, 6461.54, 35830.53, 49916.5…
#> $ first_period_reimburse                 <dbl> 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.…
#> $ first_period_receptions                <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, NA, 0, 0, 0, 0, NA, 0, …
#> $ first_period_other_entertainment       <dbl> 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 32…
#> $ first_period_other_gifts               <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, NA, 0, 0, 0, 0, NA, 0, …
#> $ first_period_expenditures_all_members  <dbl> 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 13…
#> $ first_period_gifts                     <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, NA, 0, 0, 0, 0, NA, 0, …
#> $ first_period_registration_late_fees    <dbl> 0, 0, 0, 0, 10, 0, 0, 0, 0, NA, 0, 0, 100, 55, NA,…
#> $ first_period_other_expenses            <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, NA, 0, 0, 0, 0, NA, 0, …
#> $ first_period_gross_expenditures        <dbl> 0.00, 5055.23, 2116.67, 6461.54, 35840.53, 49916.5…
#> $ first_period_deductions                <dbl> 0.00, 5055.23, 2116.67, 0.00, 35840.53, 0.00, 0.00…
#> $ first_period_net_expenditures          <dbl> 0.00, 0.00, 0.00, 6461.54, 0.00, 49916.50, 8470.00…
#> $ second_period_compensation             <dbl> 0.00, 1147.18, 350.00, 1292.31, 1040.85, 55054.50,…
#> $ second_period_reimburse                <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NA, 0, 0, 0, 0, 0…
#> $ second_period_receptions               <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NA, 0, 0, 0, 0, 0…
#> $ second_period_other_entertainment      <dbl> 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 20…
#> $ second_period_other_gifts              <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NA, 0, 0, 0, 0, 0…
#> $ second_period_expenditures_all_members <dbl> 0.0, 376.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0…
#> $ second_period_gifts                    <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NA, 0, 0, 0, 0, 0…
#> $ second_period_registration_late_fees   <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NA, 0, 0, 0, 0, 0…
#> $ second_period_other_expenses           <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NA, 0, 0, 0, 0, 0…
#> $ second_period_gross_expenditures       <dbl> 0.00, 1523.38, 350.00, 1292.31, 1040.85, 55054.50,…
#> $ second_period_deductions               <dbl> 0.00, 1523.38, 350.00, 0.00, 1040.85, 0.00, 0.00, …
#> $ second_period_net_expenditures         <dbl> 0.00, 0.00, 0.00, 1292.31, 0.00, 55054.50, 25410.0…
#> $ grand_totals                           <dbl> 0.00, 0.00, 0.00, 7753.85, 0.00, 104971.00, 33880.…
#> $ year_clean                             <dbl> 2019, 2017, 2018, 2014, 2019, 2011, 2008, 2014, 20…
#> $ lobbyist_clean                         <chr> "HILDEBRAND, EMMY", "TAFT STETTINIUS & HOLLISTER L…
```

### Missing

``` r
col_stats(inle, count_na)
#> # A tibble: 31 × 4
#>    col                                    class     n       p
#>    <chr>                                  <chr> <int>   <dbl>
#>  1 year                                   <chr> 11214 0.477  
#>  2 lobbyist                               <chr>  9340 0.398  
#>  3 client                                 <chr>    52 0.00221
#>  4 terminated                             <chr> 19860 0.846  
#>  5 first_period_compensation              <dbl>  2685 0.114  
#>  6 first_period_reimburse                 <dbl>  2687 0.114  
#>  7 first_period_receptions                <dbl>  2687 0.114  
#>  8 first_period_other_entertainment       <dbl>  2686 0.114  
#>  9 first_period_other_gifts               <dbl>  2686 0.114  
#> 10 first_period_expenditures_all_members  <dbl>  2687 0.114  
#> 11 first_period_gifts                     <dbl>  2681 0.114  
#> 12 first_period_registration_late_fees    <dbl>  2679 0.114  
#> 13 first_period_other_expenses            <dbl>  2594 0.110  
#> 14 first_period_gross_expenditures        <dbl>  1932 0.0823 
#> 15 first_period_deductions                <dbl>  2034 0.0866 
#> 16 first_period_net_expenditures          <dbl>  1932 0.0823 
#> 17 second_period_compensation             <dbl>  3384 0.144  
#> 18 second_period_reimburse                <dbl>  3386 0.144  
#> 19 second_period_receptions               <dbl>  3387 0.144  
#> 20 second_period_other_entertainment      <dbl>  3386 0.144  
#> 21 second_period_other_gifts              <dbl>  3388 0.144  
#> 22 second_period_expenditures_all_members <dbl>  3387 0.144  
#> 23 second_period_gifts                    <dbl>  3387 0.144  
#> 24 second_period_registration_late_fees   <dbl>  3387 0.144  
#> 25 second_period_other_expenses           <dbl>  3385 0.144  
#> 26 second_period_gross_expenditures       <dbl>  2111 0.0899 
#> 27 second_period_deductions               <dbl>  3362 0.143  
#> 28 second_period_net_expenditures         <dbl>  2111 0.0899 
#> 29 grand_totals                           <dbl>    38 0.00162
#> 30 year_clean                             <dbl>     0 0      
#> 31 lobbyist_clean                         <chr>  4101 0.175
```

``` r
inle <- inle %>% flag_na(client, lobbyist_clean)
sum(inle$na_flag)
#> [1] 4153
```

### Duplicates

We can see there’s no duplicate entry.

``` r
inle <- flag_dupes(inle, dplyr::everything())
sum(inle$dupe_flag)
#> [1] 36
```

### Categorical

All the numeric columns are read as plain text. We will clean these
columns with `stringr::str_remove()`.

``` r
inle %>% 
  ggplot(aes(grand_totals)) +
  geom_histogram(fill = dark2["purple"]) +
  scale_y_continuous(labels = comma) +
  scale_x_continuous(
    breaks = c(1 %o% 10^(0:5)),
    labels = dollar,
    trans = "log10"
  ) +
  labs(
    title = "Indiana Contributions Amount Distribution",
    subtitle = "from 2008 to 2022",
    caption = "Source: Indiana Lobby Registration Commission",
    x = "Amount",
    y = "Count"
  )
```

![](../plots/conv%20num-1.png)<!-- -->

## Conclude

``` r
inle <- inle %>% mutate(lobbyist_clean = coalesce(lobbyist_clean,lobbyist))
```

``` r
glimpse(sample_n(inle, 20))
#> Rows: 20
#> Columns: 33
#> $ year                                   <chr> "2012", NA, "2011", NA, NA, "2014", NA, "2020", NA…
#> $ lobbyist                               <chr> "KERCE, CLIFFORD", NA, NA, NA, NA, "CHURCH, DOUGLA…
#> $ client                                 <chr> "CARPENTERS INDUSTRIAL COUNCIL", "INDIANA STATE AS…
#> $ terminated                             <chr> NA, NA, NA, NA, NA, NA, NA, "FIRST PERIOD", NA, NA…
#> $ first_period_compensation              <dbl> 0.00, 1011.01, 0.00, 0.00, 0.00, 0.00, NA, 0.00, 0…
#> $ first_period_reimburse                 <dbl> 0.00, 57.97, 0.00, 0.00, 3.02, 0.00, NA, 0.00, 0.0…
#> $ first_period_receptions                <dbl> 0, 0, 0, 0, 0, 0, NA, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0…
#> $ first_period_other_entertainment       <dbl> 0.00, 0.00, 0.00, 0.00, 9.69, 0.00, NA, 0.00, 0.00…
#> $ first_period_other_gifts               <dbl> 0, 0, 0, 0, 0, 0, NA, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0…
#> $ first_period_expenditures_all_members  <dbl> 0.00, 75.61, 0.00, 0.00, 75.28, 0.00, NA, 0.00, 0.…
#> $ first_period_gifts                     <dbl> 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, NA, 0.00, 0.00…
#> $ first_period_registration_late_fees    <dbl> 0, 200, 0, 0, 206, 0, NA, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ first_period_other_expenses            <dbl> 0, 0, 0, 0, 0, 0, NA, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0…
#> $ first_period_gross_expenditures        <dbl> 0.00, 1344.59, 0.00, 0.00, 293.99, 0.00, NA, 0.00,…
#> $ first_period_deductions                <dbl> 0.00, 1344.59, 0.00, 0.00, 293.99, 0.00, NA, 0.00,…
#> $ first_period_net_expenditures          <dbl> 0.000000e+00, 0.000000e+00, 0.000000e+00, 0.000000…
#> $ second_period_compensation             <dbl> 0.00, 667.27, 0.00, 0.00, 846.11, 0.00, 1250.00, N…
#> $ second_period_reimburse                <dbl> 0.00, 0.00, 0.00, 0.00, 51.82, 0.00, 0.00, NA, 0.0…
#> $ second_period_receptions               <dbl> 0, 0, 0, 0, 0, 0, 0, NA, 0, 0, 0, 0, 0, 0, 0, 0, 0…
#> $ second_period_other_entertainment      <dbl> 0.0, 0.0, 0.0, 0.0, 1.8, 0.0, 0.0, NA, 0.0, 0.0, 0…
#> $ second_period_other_gifts              <dbl> 0, 0, 0, 0, 0, 0, 0, NA, 0, 0, 0, 0, 0, 0, 0, 0, 0…
#> $ second_period_expenditures_all_members <dbl> 0.00, 0.00, 0.00, 0.00, 44.58, 0.00, 0.00, NA, 0.0…
#> $ second_period_gifts                    <dbl> 0, 0, 0, 0, 0, 0, 0, NA, 0, 0, 0, 0, 0, 0, 0, 0, 0…
#> $ second_period_registration_late_fees   <dbl> 0, 0, 0, 0, 208, 0, 0, NA, 0, 0, 0, 0, 0, 0, 0, 0,…
#> $ second_period_other_expenses           <dbl> 0, 0, 0, 0, 0, 0, 0, NA, 0, 0, 0, 0, 0, 0, 0, 0, 0…
#> $ second_period_gross_expenditures       <dbl> 0.00, 667.27, 0.00, 0.00, 1152.31, 0.00, 1250.00, …
#> $ second_period_deductions               <dbl> 0.00, 667.27, 0.00, 0.00, 1152.31, 0.00, 1250.00, …
#> $ second_period_net_expenditures         <dbl> 0, 0, 0, 0, 0, 0, 0, NA, 0, 0, 0, 0, 0, 0, 0, 0, 0…
#> $ grand_totals                           <dbl> 0.000000e+00, 0.000000e+00, 0.000000e+00, 0.000000…
#> $ year_clean                             <dbl> 2012, 2018, 2011, 2010, 2014, 2014, 2008, 2020, 20…
#> $ lobbyist_clean                         <chr> "KERCE, CLIFFORD", "BOSE PUBLIC AFFAIRS GROUP", "C…
#> $ na_flag                                <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FA…
#> $ dupe_flag                              <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
min(inle$year_clean)
#> [1] 2008
max(inle$year_clean)
#> [1] 2022
```

1.  There are 23485 records in the database.
2.  There are 36 duplicate records in the database.
3.  The range and distribution of `year` seems mostly reasonable except
    for a few entries.
4.  There are 4153 records missing either recipient or date.
5.  Consistency in goegraphic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
clean_dir <- dir_create(here("state","in", "lobby", "data", "exp","clean"))
```

``` r
write_csv(
  x = inle,
  path = path(clean_dir, "in_lob_exp_clean.csv"),
  na = ""
)
```

We did a little spot check for the data and it checks out.
