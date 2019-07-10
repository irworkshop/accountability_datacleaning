Florida Expenditures
================
Kienan Nicholls
2019-07-09 17:45:12

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
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
  lubridate, # datetime strings
  magrittr, # pipe opperators
  janitor, # dataframe clean
  zipcode, # clean & database
  knitr, # knit documents
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
2.  Check the appropriate file **List** type box (Payee, Candidate,
    Committee)
3.  In the **From Date Range** text box, enter “01/01/2008.”
4.  Select “Return Results in a Tab Delimited Text File” **Retrieval
    Format** option.
5.  Save to the `/fl/expends/data/raw` directory.

### Read

``` r
fl <- 
  dir_ls(path = "fl/data/raw/") %>% 
  map(
    read_delim,
    delim = "\t",
    escape_double = FALSE,
    escape_backslash = FALSE,
    col_types = cols(
      .default = col_character(),
      Date = col_date("%m/%d/%Y"),
      Amount = col_double()
    )
  ) %>% 
  bind_rows() %>% 
  distinct() %>% 
  clean_names() %>% 
  mutate_if(is_character, str_to_upper) %>% 
  map_if(is_character, str_replace_all, "\\\"", "\'") %>% 
  as_tibble()
```

## Explore

``` r
head(fl)
```

    #> # A tibble: 6 x 8
    #>   candidate_committee date       amount payee_name     address     city_state_zip  purpose    type 
    #>   <chr>               <date>      <dbl> <chr>          <chr>       <chr>           <chr>      <chr>
    #> 1 ACKERMAN, PAUL J (… 2008-01-01   15.0 STAPLES        1950 STATE… OVIEDO, FL 327… OFFICE SU… MON  
    #> 2 ADKINS, JANET H. (… 2008-01-01   30   PAY PAL, INC.  2145 HAMIL… "SAN JOSE, CA " SERVICE C… MON  
    #> 3 CONSTANCE, CHRIS  … 2008-01-01  200   JACQUELINE SC… PO BOX 330… ATLANTIC BEACH… DECEMBER … MON  
    #> 4 DETERT, NANCY C. (… 2008-01-01 3750   POWERS, BREND… 5960 7TH A… BRADENTON, FL … CAMPAIGN … MON  
    #> 5 DOMINO, CARL J (RE… 2008-01-01   54.8 BUDGET PRINTI… 4152 W. BL… RIVIERA BEACH,… BUSINESS … MON  
    #> 6 DOMINO, CARL J (RE… 2008-01-01  484.  BUDGET PRINTI… 4152 W. BL… RIVIERA BEACH,… INVITATIO… MON

``` r
tail(fl)
```

    #> # A tibble: 6 x 8
    #>   candidate_committ… date       amount payee_name   address         city_state_zip purpose   type  
    #>   <chr>              <date>      <dbl> <chr>        <chr>           <chr>          <chr>     <chr> 
    #> 1 FLORIDA CUPAC (CC… 9919-12-03   2.5  99FARKAS, F… FLORIDA HOUSE … SAINT PETERSB… ONRE-ELE… X     
    #> 2 FLORIDA CUPAC (CC… 9919-12-20   2.5  99DOBSON, M… THE MICHAEL DO… TALLAHASSEE, … ONELECTI… X     
    #> 3 FLORIDA CUPAC (CC… 9919-12-20  15    99SENATE MA… PO BOX 311      TALLAHASSEE, … ONSUGAR … X     
    #> 4 FLORIDA CUPAC (CC… 9919-12-31   0.12 99SOUTHEAST… 3555 COMMONWEA… TALLAHASSEE, … ONCU CHA… X     
    #> 5 PLASENCIA, RENE '… 2016-08-26  78.6  CATRON, KIM  "'14866 FAVERS… 08/26/2016     11460.00  MILLE…
    #> 6 PLASENCIA, RENE '… 2016-08-26 158.   CROW, BRAXT… 843 HONEYSUCKL… ROCKLEDGE, FL… STAFF     MON

``` r
glimpse(fl)
```

    #> Observations: 1,320,441
    #> Variables: 8
    #> $ candidate_committee <chr> "ACKERMAN, PAUL J (REP)(STR)", "ADKINS, JANET H. (REP)(STR)", "CONST…
    #> $ date                <date> 2008-01-01, 2008-01-01, 2008-01-01, 2008-01-01, 2008-01-01, 2008-01…
    #> $ amount              <dbl> 14.97, 30.00, 200.00, 3750.00, 54.85, 483.78, 434.62, 29.98, 14.99, …
    #> $ payee_name          <chr> "STAPLES", "PAY PAL, INC.", "JACQUELINE SCHALL, LLC", "POWERS, BREND…
    #> $ address             <chr> "1950 STATE RD 426", "2145 HAMILTON AVENUE", "PO BOX 330965", "5960 …
    #> $ city_state_zip      <chr> "OVIEDO, FL 32765", "SAN JOSE, CA ", "ATLANTIC BEACH, FL 32233", "BR…
    #> $ purpose             <chr> "OFFICE SUPPLIES", "SERVICE CHARGE", "DECEMBER TREASURY SERVICES", "…
    #> $ type                <chr> "MON", "MON", "MON", "MON", "MON", "MON", "MON", "MON", "MON", "MON"…

### Categorical

``` r
fl %>% glimpse_fun(n_distinct)
```

    #> # A tibble: 8 x 4
    #>   var                 type       n         p
    #>   <chr>               <chr>  <int>     <dbl>
    #> 1 candidate_committee chr     7601 0.00576  
    #> 2 date                date    8579 0.00650  
    #> 3 amount              dbl   147644 0.112    
    #> 4 payee_name          chr   309585 0.234    
    #> 5 address             chr   344617 0.261    
    #> 6 city_state_zip      chr    39581 0.0300   
    #> 7 purpose             chr   240433 0.182    
    #> 8 type                chr       25 0.0000189

![](../plots/type_bar-1.png)<!-- -->

![](../plots/purpose_bar-1.png)<!-- -->

### Continuous

``` r
ggplot(data = fl) +
  geom_histogram(aes(amount)) +
  scale_x_continuous(labels = scales::dollar, trans = "log10")
```

![](../plots/amount_hist-1.png)<!-- -->

``` r
fl %>% 
  filter(year(date) > 2008, date < today()) %>% 
  ggplot() +
  geom_bar(aes(year(date))) +
  scale_x_continuous(breaks = 2008:2019)
```

![](../plots/year_bar-1.png)<!-- -->

``` r
fl %>% 
  mutate(year = year(date), election_year = year %% 2 == 0) %>% 
  group_by(election_year, month = month(date)) %>% 
  filter(year > 2008, year < 2019) %>% 
  summarise(mean = mean(amount)) %>% 
  ggplot(mapping = aes(x = month, y = mean)) +
  geom_line(aes(color = election_year), size = 2) +
  scale_x_continuous(breaks = 1:12, labels = month.abb)
```

![](../plots/month_line-1.png)<!-- -->

### Duplicates

Since the three seperate files have siginificant overlap, duplicate rows
were removed during the initial importing step.

### Missing

``` r
fl %>% glimpse_fun(count_na)
```

    #> # A tibble: 8 x 4
    #>   var                 type      n           p
    #>   <chr>               <chr> <int>       <dbl>
    #> 1 candidate_committee chr       1 0.000000757
    #> 2 date                date    597 0.000452   
    #> 3 amount              dbl       1 0.000000757
    #> 4 payee_name          chr     664 0.000503   
    #> 5 address             chr    9888 0.00749    
    #> 6 city_state_zip      chr       4 0.00000303 
    #> 7 purpose             chr    7676 0.00581    
    #> 8 type                chr       5 0.00000379

## Export

``` r
dir_create("fl/data/processed")
write_csv(
  x = fl,
  path = "fl/data/processed/fl_expends_clean.csv",
  na = ""
)
```
