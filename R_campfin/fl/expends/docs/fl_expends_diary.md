Florida Expenditures
================
Kienan Nicholls
2019-07-10 16:16:33

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Clean](#clean)
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
6.  Create a five-digit `zip` Code variable
7.  Create a `year` variable from the transaction date
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
  RSelenium, # remote browser
  lubridate, # datetime strings
  tidytext, # string analysis
  magrittr, # pipe opperators
  janitor, # dataframe clean
  zipcode, # clean & database
  refinr, # cluster and merge
  knitr, # knit documents
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
# where dfs this document knit?
here::here()
#> [1] "/home/ubuntu/R/accountability_datacleaning/R_campfin"
```

## Data

Data is obtained from the Florida Division of Elections.

As the [agency home
page](https://dos.myflorida.com/elections/candidates-committees/campaign-finance/ "source")
explains:

> By Florida law, campaigns, committees, and electioneering
> communications organizations are required to disclose detailed
> financial records of campaign contributions and expenditures. Chapter
> 106, Florida Statutes, regulates campaign financing for all
> candidates, including judicial candidates, political committees,
> electioneering communication organizations, affiliated party
> committees, and political parties. It does not regulate campaign
> financing for candidates for federal office.

### About

A more detailed description of available data can be found on the
[Campaign Finance
page](https://dos.myflorida.com/elections/candidates-committees/campaign-finance/campaign-finance-database/):

> #### Quality of Data
> 
> The information presented in the campaign finance database is an
> accurate representation of the reports filed with the Florida Division
> of Elections.
> 
> Some of the information in the campaign finance database was submitted
> in electronic form, and some of the information was key-entered from
> paper reports. Sometimes items which are not consistent with filing
> requirements, such as incorrect codes or incorrectly formatted or
> blank items, are present in the results of a query. They are incorrect
> in the database because they were incorrect on reports submitted to
> the division.

> #### What does the Database Contain?
> 
> By law candidates and committees are required to disclose detailed
> financial records of contributions received and expenditures made. For
> committees, the campaign finance database contains all contributions
> and expenditures reported to the Florida Division of Elections since
> January 1, 1996. For candidates, the campaign finance database
> contains all contributions and expenditures reported to the Division
> since the candidacy was announced, beginning with the 1996 election.

> #### Whose Records are Included?
> 
> Included are campaign finance reports which have been filed by
> candidates for any multi-county office, with the exception of U.S.
> Senator and U.S. Representative, and by organizations that receive
> contributions or make expenditures of more than $500 in a calendar
> year to support or oppose any multi-county candidate, issue, or party.
> To obtain reports from local county or municipal candidates and
> committees, contact county or city filing offices.

> #### When are the Records Available?
> 
> Campaign finance reports are posted to the database as they are
> received from the candidates and committees. Our data is as current as
> possible, consistent with the reporting requirements of Florida law.

## Import

### Download

We will use the [Expenditure
Records](https://dos.elections.myflorida.com/campaign-finance/expenditures/)
querey form to download three separate files covering all campaign
expenditures. [The previous
page](https://dos.myflorida.com/elections/candidates-committees/campaign-finance/campaign-finance-database/)
lists instructions on how to download the desired files:

> #### How to Use the Campaign Finance Database
> 
> 1.  Specify a subset of the \[Expenditure\]…
> 2.  Select an election year entry from the list box
> 3.  Select a candidate/committee option:
> 4.  Select contribution criteria (for Detail report only):
> 5.  Select how you would like the records sorted.
> 6.  Select the format in which you would like the data returned.
> 7.  Limit the number of records to return.
> 8.  Click on the Submit Query button.

To get all files covering all expenditures:

1.  Select “All” from the **Election Year** drop down menu
2.  In the **From Date Range** text box, enter “01/01/2008”
3.  Delete “500” from the **Limit Records** text box
4.  Select “Return Results in a Tab Delimited Text File” **Retrieval
    Format** option
5.  Save to the `/fl/expends/data/raw` directory

We can automate this process using the `RSelenium` package:

``` r
# create a directory for the raw data
raw_dir <- here("fl", "expends", "data", "raw")
dir_create(raw_dir)
```

``` r
# open the driver with auto download options
remote_driver <- rsDriver(
  port = 4444L,
  browser = "firefox",
  extraCapabilities = makeFirefoxProfile(
    list(
      browser.download.dir = raw_dir,
      browser.download.folderList = 2L,
      browser.helperApps.neverAsk.saveToDisk = "text/txt"
    )
  )
)

# navigate to the FL DOE download site
remote_browser <- remote_driver$client
expends_url <- "https://dos.elections.myflorida.com/campaign-finance/expenditures/"
remote_browser$navigate(expends_url)

# chose "All" from elections list
year_menu <- "/html/body/div/div[1]/div/div/div/div/div/div/div/div/form/select[1]/option[@value = 'All']"
remote_browser$findElement("xpath", year_menu)$clickElement()

# remove the records limit text of 500
limit_box <- "div.marginBot:nth-child(64) > input:nth-child(1)"
remote_browser$findElement("css", limit_box)$clearElement()

# enter Jan 1 2008 as start date
date_box <- "div.indent:nth-child(2) > input:nth-child(1)"
remote_browser$findElement("css", )$sendKeysToElement(list("01/01/2008"))

# chose "txt" as export option
txt_button <- "ul.noBullet:nth-child(70) > li:nth-child(2) > input:nth-child(1)"
remote_browser$findElement("css", txt_button)$clickElement()

# click the submit button
submit_button <- "#rightContent > form:nth-child(6) > div:nth-child(71) > input:nth-child(2)"
remote_browser$findElement("css", submit_button)$clickElement()

# close the browser and driver
remote_browser$close()
remote_driver$server$stop()
```

### Read

``` r
fl <- 
  read_delim(
    file = dir_ls(path = raw_dir),
    delim = "\t",
    escape_double = FALSE,
    escape_backslash = FALSE,
    trim_ws = TRUE,
    col_types = cols(
      .default = col_character(),
      Date = col_date("%m/%d/%Y"),
      Amount = col_double()
    )
  ) %>% 
  select(-starts_with("X")) %>% 
  clean_names() %>% 
  mutate_if(is_character, str_to_upper)
```

## Explore

``` r
head(fl)
```

    #> # A tibble: 6 x 8
    #>   candidate_committee    date       amount payee_name    address     city_state_zip  purpose  type 
    #>   <chr>                  <date>      <dbl> <chr>         <chr>       <chr>           <chr>    <chr>
    #> 1 ACKERMAN, PAUL J (REP… 2008-01-01   15.0 STAPLES       1950 STATE… OVIEDO, FL 327… OFFICE … MON  
    #> 2 ADKINS, JANET H. (REP… 2008-01-01   30   PAY PAL, INC. 2145 HAMIL… SAN JOSE, CA    SERVICE… MON  
    #> 3 FLORIDA JUSTICE PAC (… 2008-01-01   30   REGIONS BANK  2000 CAPIT… TALLAHASSEE, F… BANK FE… MON  
    #> 4 CITIZENS SPEAKING OUT… 2008-01-01 2000   DSI, INC      PO BOX 126… GAINESVILLE, F… CONSULT… MON  
    #> 5 CITIZENS SPEAKING OUT… 2008-01-01 9000   DATA TARGETI… 6211 NW 13… GAINESVILLE, F… CONSULT… MON  
    #> 6 FLORIDA HOMETOWN DEMO… 2008-01-01   48.5 RACEWAY       INT'L SPEE… DAYTONA BEACH,… GAS      MON

``` r
tail(fl)
```

    #> # A tibble: 6 x 8
    #>   candidate_commit… date       amount payee_name    address       city_state_zip  purpose     type 
    #>   <chr>             <date>      <dbl> <chr>         <chr>         <chr>           <chr>       <chr>
    #> 1 FLORIDA CUPAC (C… 9919-12-03   5    99FLORIDA DE… POST OFFICE … TALLAHASSEE,  … ONHOLIDAY … X    
    #> 2 FLORIDA CUPAC (C… 9919-12-03   5    99LAURENT, J… FLORIDA HOUS… BARTOW,  FL338  ONRE-ELECT… X    
    #> 3 FLORIDA CUPAC (C… 9919-12-03   2.5  99FARKAS, FR… FLORIDA HOUS… SAINT PETERSBU… ONRE-ELECT… X    
    #> 4 FLORIDA CUPAC (C… 9919-12-20   2.5  99DOBSON, MI… THE MICHAEL … TALLAHASSEE,  … ONELECTION… X    
    #> 5 FLORIDA CUPAC (C… 9919-12-20  15    99SENATE MAJ… PO BOX 311    TALLAHASSEE,  … ONSUGAR BO… X    
    #> 6 FLORIDA CUPAC (C… 9919-12-31   0.12 99SOUTHEAST … 3555 COMMONW… TALLAHASSEE,  … ONCU CHARG… X

``` r
glimpse(fl)
```

    #> Observations: 814,775
    #> Variables: 8
    #> $ candidate_committee <chr> "ACKERMAN, PAUL J (REP)(STR)", "ADKINS, JANET H. (REP)(STR)", "FLORI…
    #> $ date                <date> 2008-01-01, 2008-01-01, 2008-01-01, 2008-01-01, 2008-01-01, 2008-01…
    #> $ amount              <dbl> 14.97, 30.00, 30.00, 2000.00, 9000.00, 48.51, 43.55, 46.05, 200.00, …
    #> $ payee_name          <chr> "STAPLES", "PAY PAL, INC.", "REGIONS BANK", "DSI, INC", "DATA TARGET…
    #> $ address             <chr> "1950 STATE RD 426", "2145 HAMILTON AVENUE", "2000 CAPITAL CIRCLE NE…
    #> $ city_state_zip      <chr> "OVIEDO, FL 32765", "SAN JOSE, CA", "TALLAHASSEE, FL 32308", "GAINES…
    #> $ purpose             <chr> "OFFICE SUPPLIES", "SERVICE CHARGE", "BANK FEES", "CONSULTING", "CON…
    #> $ type                <chr> "MON", "MON", "MON", "MON", "MON", "MON", "MON", "MON", "MON", "MON"…

### Categorical

We can explore the least distinct variables with `ggplot::geom_bar()` or
perform tidytext analysis on complex character strings.

``` r
fl %>% glimpse_fun(n_distinct)
```

    #> # A tibble: 8 x 4
    #>   var                 type       n         p
    #>   <chr>               <chr>  <int>     <dbl>
    #> 1 candidate_committee chr     6830 0.00838  
    #> 2 date                date    3757 0.00461  
    #> 3 amount              dbl   109834 0.135    
    #> 4 payee_name          chr   191917 0.236    
    #> 5 address             chr   223179 0.274    
    #> 6 city_state_zip      chr    22714 0.0279   
    #> 7 purpose             chr   125610 0.154    
    #> 8 type                chr       28 0.0000344

![](../plots/type_bar-1.png)<!-- -->

![](../plots/purpose_bar-1.png)<!-- -->

### Continuous

![](../plots/amount_hist-1.png)<!-- -->

![](../plots/year_bar-1.png)<!-- -->

![](../plots/month_line-1.png)<!-- -->

### Duplicates

The `janitor::get_dupes()` function can locate records with duplicate
values across every variable.

``` r
fl_dupes <- fl %>% 
  get_dupes() %>% 
  distinct() %>% 
  mutate(dupe_flag = TRUE)

nrow(fl_dupes)
#> [1] 6573
mean(fl_dupes$dupe_count)
#> [1] 2.444698
max(fl_dupes$dupe_count)
#> [1] 50
sum(fl_dupes$dupe_count)
#> [1] 16069
```

This data frame of duplicate records can then be flagged on the original
database.

``` r
fl <- fl %>% 
  left_join(fl_dupes) %>% 
  mutate(
    dupe_count = if_else(is.na(dupe_count), 0L, dupe_count),
    dupe_flag = !is.na(dupe_flag)
    )
```

### Missing

There are a number of rows missing key information.

``` r
fl %>% glimpse_fun(count_na)
```

    #> # A tibble: 10 x 4
    #>    var                 type      n         p
    #>    <chr>               <chr> <int>     <dbl>
    #>  1 candidate_committee chr       0 0        
    #>  2 date                date      9 0.0000110
    #>  3 amount              dbl      11 0.0000135
    #>  4 payee_name          chr      42 0.0000515
    #>  5 address             chr     783 0.000961 
    #>  6 city_state_zip      chr       9 0.0000110
    #>  7 purpose             chr     243 0.000298 
    #>  8 type                chr      15 0.0000184
    #>  9 dupe_count          int       0 0        
    #> 10 dupe_flag           lgl       0 0

These rows will be flagged with a new `na_flag` variable.

``` r
fl <- fl %>% 
  mutate(
    na_flag = is.na(candidate_committee) | is.na(date) | is.na(amount) | is.na(payee_name)
  )
```

## Clean

We need to separate the `city_state_zip` variable into their respective
variables. Then we can clean each part.

``` r
fl <- fl %>% 
  separate(
    col = city_state_zip,
    into = c("city_sep", "state_zip"),
    sep = ",\\s",
    remove = FALSE
  ) %>% 
  separate(
    col = state_zip,
    into = c("state_sep", "zip_sep"),
    sep = "\\s",
    remove = TRUE
  )
```

### Address

The database seems to use repeating astricks characters as `NA` values.
We can remove any value with a single repeating character.

``` r
fl %<>% mutate(address_clean = normalize_address(address, na_rep = TRUE))
```

### Zip

``` r
sample(fl$zip_sep[which(nchar(fl$zip_sep) != 5)], 10)
#>  [1] "0059" ""     "403"  "3231" "500"  "613"  "752"  "T2G"  "3367" "613"
```

``` r
fl %<>% mutate(zip_clean = normalize_zip(zip_sep, na_rep = TRUE))
```

### State

``` r
valid_state <- c(unique(zipcode$state), "ON", "BC", "QC", "NB", "AB")
n_distinct(fl$state_sep)
#> [1] 138
mean(fl$state_sep %in% valid_state)
#> [1] 0.9954699
sum(fl$state_sep %out% valid_state)
#> [1] 3691
sample(unique(na.omit(fl$state_sep[fl$state_sep %out% valid_state])), 20)
#>  [1] "PL"        "AUSTRALIA" "33"        "BOCA"      "32"        "LN"        "XX"       
#>  [8] "THE"       "BA"        "CL"        "TOKYO"     "ALBERTA"   "ONTARIO"   "FF"       
#> [15] "NSW"       "DD"        "KENT"      "BRITISH"   "M"         "FLORIDA"
```

``` r
fl %<>% mutate(
  state_clean = normalize_state(
    state = state_sep,
    expand = TRUE,
    na = c("", "XC")
  )
)
```

``` r
unique(fl$state_clean[which(fl$state_clean %out% valid_state)])
#>  [1] NA   "F"  "NW" "CN" "MM" "KE" "3"  "FK" "B"  "SU" "M"  "BE" "TR" "NA" "MY" "DD" "AU" "PE" "W" 
#> [20] "2"  "BA" "CL" "DR" "QU" "LN" "PQ" "41" "PL" "NL" "HO" "VG" "XX" "*"  "IS" "SA" "CH" "BR" "BO"
#> [39] "HA" "NS" "ST" "SO" "V"  "JO" "PO" "HM" "TH" "WE" "UK" "XE" "GE" "FF" "FR" "TO"
fl$state_clean[which(fl$state_clean == "F")] <- "FL"
fl$state_clean[which(fl$state_clean %out% valid_state)] <- NA
n_distinct(fl$state_clean)
#> [1] 61
```

### City

``` r
valid_city <- unique(zipcode$city)

n_distinct(fl$city_sep)
#> [1] 7622

mean(fl$city_sep %in% valid_city)
#> [1] 0.8806603

sum(fl$city_sep %out% valid_city)
#> [1] 97235

sample(unique(na.omit(fl$city_sep[fl$city_sep %out% valid_city])), 20)
#>  [1] "COCO BEACH"      "SEDALIA,"        "MARY ESTER"      "IRWINDALE"       "ST AUGISTINE"   
#>  [6] "BLOUTSTOWN"      "AVENURA"         "TALALHASSEE"     "ST; PETERSBURG"  "BINYAMINA"      
#> [11] "MINNEAPOLIS,"    "QIUNCY"          "ALTANTIS"        "7TH FLOOR"       "ST. PAETERSBURG"
#> [16] "HALENDALE"       "KEY LARGE"       "WILLIMGTON"      "STILL WATER"     "TITUSVILLLE"
```

### Normalize

``` r
fl <- fl %>% 
  mutate(
    city_norm = normalize_city(
      city = city_sep,
      na_rep = TRUE,
      state_abbs = c("FL", "DC"),
      geo_abbs = read_csv(here("R", "data", "city_abvs.csv"))
    )
  )

n_distinct(fl$city_norm)
```

    #> [1] 7013

### Match

``` r
fl <- fl %>% 
  left_join(
    y = zipcode, 
    by = c(
      "zip_clean" = "zip", 
      "state_clean" = "state"
    )
  ) %>% 
  rename(city_match = city)
```

### Swap

``` r
fl <- fl %>% 
  mutate(
    match_dist = stringdist(city_norm, city_match),
    city_swap = if_else(
      condition = match_dist <= 2,
      true = city_match,
      false = city_norm
    )
  )

summary(fl$match_dist)
```

    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
    #>   0.000   0.000   0.000   1.171   0.000  20.000   23522

``` r
sum(fl$match_dist == 1, na.rm = TRUE)
```

    #> [1] 6699

``` r
n_distinct(fl$city_swap)
```

    #> [1] 4896

### Refine

``` r
fl_refine <- fl %>% 
  filter(state_clean == "FL") %>% 
  mutate(
    city_refine = city_swap %>% 
      key_collision_merge() %>% 
      n_gram_merge()
  ) %>% 
  filter(city_refine != city_swap)

fl_refine %>% 
  count(
    city_swap, 
    city_refine,
    sort = TRUE
  )
```

    #> # A tibble: 189 x 3
    #>    city_swap           city_refine               n
    #>    <chr>               <chr>                 <int>
    #>  1 SPRINGHILL          SPRING HILL              32
    #>  2 GREEN ACRES         GREENACRES               22
    #>  3 LAUDERDALE BYTHESEA LAUDERDALE BY THE SEA    18
    #>  4 HALLANDALE BEAC     HALLANDALE BEACH         16
    #>  5 ANNA MARIA          MARIANNA                 15
    #>  6 BAY HARBOR ISLAND   BAY HARBOR ISLANDS       15
    #>  7 MIAMII GARDENS      MIAMI GARDENS            13
    #>  8 LAKE BUENA VIST     LAKE BUENA VISTA         10
    #>  9 PASADENA            S PASADENA                9
    #> 10 CHAMPIONSGATE       CHAMPIONS GATE            8
    #> # … with 179 more rows

``` r
fl <- fl %>% 
  left_join(fl_refine) %>% 
  mutate(city_clean = coalesce(city_refine, city_swap))
```

``` r
n_distinct(fl$city_sep)
#> [1] 7622
n_distinct(fl$city_norm)
#> [1] 7013
n_distinct(fl$city_swap)
#> [1] 4896
n_distinct(fl$city_clean)
#> [1] 4709
```

## Export

``` r
clean_dir <- here("fl", "expends", "data", "processed")
dir_create(clean_dir)
fl %>% 
  select(
    -address,
    -city_state_zip,
    -city_sep,
    -state_sep,
    -zip_sep,
    -city_norm,
    -city_match,
    -match_dist,
    -city_swap
  ) %>% 
  write_csv(
    path = glue("{clean_dir}/fl_expends_clean.csv"),
    na = ""
  )
```
