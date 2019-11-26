District Contributions
================
Kiernan Nicholls
2019-10-03 15:44:47

  - [Project](#project)
  - [Objectives](#objectives)
  - [Project](#project-1)
  - [Objectives](#objectives-1)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Separate](#separate)
  - [Normalize](#normalize)
  - [Conclude](#conclude)
  - [Lookup](#lookup)
  - [Write](#write)

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
  tidytext, # text analysis
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

Data comes courtesy of the Washington, [DC Office of Campaign Finance
(OCF)](https://ocf.dc.gov/ "OCF").

As the [OCF
website](https://ocf.dc.gov/service/view-contributions-expenditures)
explains:

> The Office of Campaign Finance (OCF) provides easy access to all
> contributions and expenditures reported from 2003, through the current
> reporting period. Because the system is updated on a daily basis, you
> may be able to retrieve data received by OCF after the latest
> reporting period. This data is as reported, but may not be complete.

### About

The data is found on the dc.gov [OpenData
website](https://opendata.dc.gov/datasets/campaign-financial-expenditures).
The file abstract reads:

> The Office of Campaign Finance (OCF) is pleased to publicly share
> election campaign contribution data. The Campaign Finance Office is
> charged with administering and enforcing the District of Columbia laws
> pertaining to campaign finance operations, lobbying activities,
> conflict of interest matters, the ethical conduct of public officials,
> and constituent service and statehood fund programs. OCF provides easy
> access to all contributions and expenditures reported from 2003,
> through the current reporting period. Because the system is updated on
> a daily basis, you may be able to retrieve data received by OCF after
> the latest reporting period. This data is as reported, but may not be
> complete. Visit the <http://ocf.dc.gov> for more information.

## Import

The most recent file can be read directly from the OCF with
`readr::read_csv()`.

``` r
dir_raw <- here("dc", "contribs", "data", "raw")
dir_create(dir_raw)
raw_url <- "https://opendata.arcgis.com/datasets/6443e0b5b2454e86a3208b8a38fdee84_34.csv"

dc <- 
  read_csv(raw_url) %>% 
  clean_names("snake") %>%
  mutate_if(is_character, str_to_upper)
```

## Explore

There are 244678 records of 20 variables in the full database.

``` r
head(dc)
#> # A tibble: 6 x 20
#>   objectid committeename candidatename electionyear contributorname address contributortype
#>      <dbl> <chr>         <chr>                <dbl> <chr>           <chr>   <chr>          
#> 1        1 FENTY 2006    ADRIAN FENTY          2006 STUART & VIRGI… 2950 C… INDIVIDUAL     
#> 2        2 EVANS FOR MA… JACK EVANS            2014 STUART PAPE     2950 C… INDIVIDUAL     
#> 3        3 FENTY 2006    ADRIAN FENTY          2006 LINDA ADAMS & … 2950 M… INDIVIDUAL     
#> 4        4 EVANS 2008    JACK EVANS            2008 L DUEMLING      2950 U… INDIVIDUAL     
#> 5        5 COMMITTEE TO… GREG RHETT            2007 L.C. DUEMLING   2950 U… INDIVIDUAL     
#> 6        6 JEREMIAH AT … JEREMIAH LOW…         2018 LINDA BENESCH   2950 V… INDIVIDUAL     
#> # … with 13 more variables: contributiontype <chr>, employer <chr>, employeraddress <chr>,
#> #   amount <dbl>, dateofreceipt <dttm>, address_id <dbl>, xcoord <dbl>, ycoord <dbl>,
#> #   latitude <dbl>, longitude <dbl>, fulladdress <chr>, gis_last_mod_dttm <dttm>, ward <chr>
tail(dc)
#> # A tibble: 6 x 20
#>   objectid committeename candidatename electionyear contributorname address contributortype
#>      <dbl> <chr>         <chr>                <dbl> <chr>           <chr>   <chr>          
#> 1   244673 WASHINGTON D… <NA>                  2002 KATIE BOLT      3201 N… INDIVIDUAL     
#> 2   244674 WASHINGTON D… <NA>                  2002 SALLY YICK      3201 N… INDIVIDUAL     
#> 3   244675 WASHINGTON D… <NA>                  2002 DANA LANDRY     3201 N… INDIVIDUAL     
#> 4   244676 WASHINGTON D… <NA>                  2002 LAURIE OSERAN   3201 N… INDIVIDUAL     
#> 5   244677 WASHINGTON D… <NA>                  2002 KATHLEEN MCGRA… 3201 N… INDIVIDUAL     
#> 6   244678 WASHINGTON D… <NA>                  2002 CATHIE GILL     3201 N… INDIVIDUAL     
#> # … with 13 more variables: contributiontype <chr>, employer <chr>, employeraddress <chr>,
#> #   amount <dbl>, dateofreceipt <dttm>, address_id <dbl>, xcoord <dbl>, ycoord <dbl>,
#> #   latitude <dbl>, longitude <dbl>, fulladdress <chr>, gis_last_mod_dttm <dttm>, ward <chr>
glimpse(dc)
#> Observations: 244,678
#> Variables: 20
#> $ objectid          <dbl> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,…
#> $ committeename     <chr> "FENTY 2006", "EVANS FOR MAYOR", "FENTY 2006", "EVANS 2008", "COMMITTE…
#> $ candidatename     <chr> "ADRIAN FENTY", "JACK EVANS", "ADRIAN FENTY", "JACK EVANS", "GREG RHET…
#> $ electionyear      <dbl> 2006, 2014, 2006, 2008, 2007, 2018, 2010, 2018, 2018, 2006, 2014, 2004…
#> $ contributorname   <chr> "STUART & VIRGINIA PAPE", "STUART PAPE", "LINDA ADAMS & JONATHAN GREEN…
#> $ address           <chr> "2950 CHAIN BRIDGE RD NW, WASHINGTON, DC 20016", "2950 CHAIN BRIDGE RO…
#> $ contributortype   <chr> "INDIVIDUAL", "INDIVIDUAL", "INDIVIDUAL", "INDIVIDUAL", "INDIVIDUAL", …
#> $ contributiontype  <chr> "CHECK", "CHECK", "CHECK", "CHECK", "CHECK", "CREDIT CARD", "CHECK", "…
#> $ employer          <chr> NA, "PATTON BOGGS LLP", "SHERMAN & STERLING, LLP", "DUPONG EI DE NEMOU…
#> $ employeraddress   <chr> NA, "2550 M STREET NW, WASHINGTON, DC 20037", "WASHINGTON, DC", "WASHI…
#> $ amount            <dbl> 1000, 500, 500, 250, 200, 25, 50, 100, 150, 100, 500, 300, 250, 250, 1…
#> $ dateofreceipt     <dttm> 2006-10-29, 2013-09-29, 2006-08-03, 2008-05-27, 2007-03-15, 2017-11-2…
#> $ address_id        <dbl> 224723, 224723, 221195, 224173, 224173, 219415, 219415, 219415, 219415…
#> $ xcoord            <dbl> 391629.0, 391629.0, 394808.6, 391537.1, 391537.1, 394699.6, 394699.6, …
#> $ ycoord            <dbl> 140190.3, 140190.3, 140604.4, 140169.9, 140169.9, 141669.4, 141669.4, …
#> $ latitude          <dbl> 38.92955, 38.92955, 38.93331, 38.92937, 38.92937, 38.94290, 38.94290, …
#> $ longitude         <dbl> -77.09654, -77.09654, -77.05987, -77.09760, -77.09760, -77.06114, -77.…
#> $ fulladdress       <chr> "2950 CHAIN BRIDGE ROAD NW", "2950 CHAIN BRIDGE ROAD NW", "2950 MACOMB…
#> $ gis_last_mod_dttm <dttm> 2019-09-30 06:20:49, 2019-09-30 06:20:49, 2019-09-30 06:20:49, 2019-0…
#> $ ward              <chr> "WARD 3", "WARD 3", "WARD 3", "WARD 3", "WARD 3", "WARD 3", "WARD 3", …
```

### Distinct

The variables range in their degree of distinctness.

``` r
glimpse_fun(dc, n_distinct)
#> # A tibble: 20 x 4
#>    col               type       n          p
#>    <chr>             <chr>  <dbl>      <dbl>
#>  1 objectid          dbl   244678 1         
#>  2 committeename     chr     1522 0.00622   
#>  3 candidatename     chr      429 0.00175   
#>  4 electionyear      dbl       17 0.0000695 
#>  5 contributorname   chr   111821 0.457     
#>  6 address           chr   139770 0.571     
#>  7 contributortype   chr       27 0.000110  
#>  8 contributiontype  chr        9 0.0000368 
#>  9 employer          chr    35410 0.145     
#> 10 employeraddress   chr    21049 0.0860    
#> 11 amount            dbl     5125 0.0209    
#> 12 dateofreceipt     dttm    5681 0.0232    
#> 13 address_id        dbl    28688 0.117     
#> 14 xcoord            dbl    28101 0.115     
#> 15 ycoord            dbl    28085 0.115     
#> 16 latitude          dbl    37527 0.153     
#> 17 longitude         dbl    37747 0.154     
#> 18 fulladdress       chr    28721 0.117     
#> 19 gis_last_mod_dttm dttm       1 0.00000409
#> 20 ward              chr        9 0.0000368
```

![](../plots/who_bar-1.png)<!-- -->

![](../plots/how_bar-1.png)<!-- -->

### Missing

There are several variables missing key values:

``` r
glimpse_fun(dc, count_na)
#> # A tibble: 20 x 4
#>    col               type       n        p
#>    <chr>             <chr>  <dbl>    <dbl>
#>  1 objectid          dbl        0 0       
#>  2 committeename     chr        0 0       
#>  3 candidatename     chr    22054 0.0901  
#>  4 electionyear      dbl       28 0.000114
#>  5 contributorname   chr     1164 0.00476 
#>  6 address           chr     1149 0.00470 
#>  7 contributortype   chr     1452 0.00593 
#>  8 contributiontype  chr     2425 0.00991 
#>  9 employer          chr    96892 0.396   
#> 10 employeraddress   chr   140419 0.574   
#> 11 amount            dbl      367 0.00150 
#> 12 dateofreceipt     dttm       0 0       
#> 13 address_id        dbl    93949 0.384   
#> 14 xcoord            dbl    93949 0.384   
#> 15 ycoord            dbl    93949 0.384   
#> 16 latitude          dbl    93949 0.384   
#> 17 longitude         dbl    93949 0.384   
#> 18 fulladdress       chr    93949 0.384   
#> 19 gis_last_mod_dttm dttm       0 0       
#> 20 ward              chr    93949 0.384
```

Any row with a missing either the `candidatename`, `committeename`
`dateofreceipt`, *or* `amount` will have a `TRUE` value in the new
`na_flag` variable.

``` r
dc <- flag_na(dc, candidatename, committeename, amount, dateofreceipt)
sum(dc$na_flag)
#> [1] 22054
percent(mean(dc$na_flag))
#> [1] "9.01%"
```

### Duplicates

There are no duplicate records.

``` r
dc <- flag_dupes(dc, everything())
sum(dc$dupe_flag)
#> [1] 0
if (sum(dc$dupe_flag == 0)) {
  dc <- select(dc, -dupe_flag)
}
```

### Ranges

#### Amounts

The `amount` varies from $-31,889.24 to $400,000.

``` r
summary(dc$amount)
#>     Min.  1st Qu.   Median     Mean  3rd Qu.     Max.     NA's 
#> -31889.2     50.0    100.0    373.7    400.0 400000.0      367
sum(dc$amount < 0, na.rm = TRUE)
#> [1] 58
```

![](../plots/amount_hist-1.png)<!-- -->

#### Dates

The dates range from  and -. There are 0 records with a date greater
than 2019-10-03.

``` r
summary(as_date(dc$dateofreceipt))
#>         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
#> "2003-01-01" "2007-07-20" "2012-01-25" "2011-09-28" "2015-01-02" "2019-05-08"
sum(dc$dateofreceipt > today())
#> [1] 0
```

![](../plots/year_bar-1.png)<!-- -->

![](../plots/amount_bar_median_year-1.png)<!-- -->

Since we’ve already used `readr::parse_datetime()`, we can use
`lubridate::year()` to create a new variable representing the year of
the receipt.

``` r
dc <- mutate(dc, transactionyear = year(dateofreceipt))
```

## Separate

We will have to break the `address` variable into distinct variables for
each component (address, city, state, ZIP).

``` r
select(sample_frac(dc), address)
#> # A tibble: 244,678 x 1
#>    address                                            
#>    <chr>                                              
#>  1 3834 WINDOM PL NW, WASHINGTON, DC 20016            
#>  2 14113 ARTIC AVENUE, ROCKVILLE, MD 20853            
#>  3 6613 13TH PL NW, WASHINGTON, DC 20012              
#>  4 1314  KENYON ST NW, WASHINGTON, DC 20010           
#>  5 3303 18TH ST NW, MCLEAN, VA 20010                  
#>  6 4339 CONNECTICUT AVE., NW., WASHINGTON, DC 20008   
#>  7 2929 38TH ST NW, WASHINGTON, DC 20016              
#>  8 101 CONSTITUTION AVENUE, N.W., WASHINGTON, DC 20080
#>  9 6503 N CAPITOL ST NE, WASHINGTON, DC 20012         
#> 10 113 10TH ST NE, WASHINGTON, DC 20002               
#> # … with 244,668 more rows
```

First, we can split the `address` variable into new columns at each
comma in the original variable using `tidyr::separate()`

``` r
dc %>% separate(
  col = address,
  into = c(glue("street{1:5}"), "city_sep", "state_zip"),
  sep = ",\\s",
  remove = FALSE,
  extra = "merge",
  fill = "left"
) -> dc
```

Since the street address portion of the `address` variable can contain a
wide variety of components, we have split the original column into an
excessive number of new columns. Now, we can use `tidyr::unite()` to
merge those many columns back into a single `address_sep` variable.

``` r
dc %>% unite(
  starts_with("street"),
  col = "address_sep",
  sep = " ",
  na.rm = TRUE,
  remove = TRUE
) -> dc
```

Finally, the state and ZIP code portion of the string is not separated
by a comma, so we will have to separate this into two strings based on
the space before the ZIP code digits.

``` r
dc %>% separate(
  col = state_zip,
  into = c("state_sep", "zip_sep"),  
  sep = "\\s{1,}(?=\\d)",
  remove = TRUE
) -> dc
```

    #> # A tibble: 244,678 x 5
    #>    address                                   address_sep             city_sep     state_sep zip_sep
    #>    <chr>                                     <chr>                   <chr>        <chr>     <chr>  
    #>  1 4002 COTTON TREE LN, BURTONSVILLE, MD 20… 4002 COTTON TREE LN     BURTONSVILLE MD        20866  
    #>  2 140 BRINKWOOD RD, BROOKEVILLE, DC 20833   140 BRINKWOOD RD        BROOKEVILLE  DC        20833  
    #>  3 3716 NASH STREET, SE, WASHINGTON, DC 200… 3716 NASH STREET SE     WASHINGTON   DC        20020  
    #>  4 3 CREEK PARK DRIVE , PORTOLA VALLEY, CA … "3 CREEK PARK DRIVE "   PORTOLA VAL… CA        94028  
    #>  5 1828 L STREET, NW SUITE 625, WASHINGTON,… 1828 L STREET NW SUITE… WASHINGTON   DC        20003  
    #>  6 23117 77TH AVE., SE., WOODINVILLE, WA 98… 23117 77TH AVE. SE.     WOODINVILLE  WA        98072  
    #>  7 2877 ARIZONA TERRACE,  NW, WASHINGTON, D… 2877 ARIZONA TERRACE  … WASHINGTON   DC        20016  
    #>  8 1312 FLORAL STREET, NW, WASHINGTON, DC 2… 1312 FLORAL STREET NW   WASHINGTON   DC        20012  
    #>  9 1445 CHURCH ST. NW, #31, WASHINGTON, DC … 1445 CHURCH ST. NW #31  WASHINGTON   DC        20005  
    #> 10 1505 Q STREET, NW, WASHINGTON, DC 20009   1505 Q STREET NW        WASHINGTON   DC        20009  
    #> # … with 244,668 more rows

There are a number of columns where the lack of a component in the
original `address` has caused the separation to incorrectly shift
content.

    #> # A tibble: 350 x 5
    #>    address                               address_sep         city_sep        state_sep      zip_sep
    #>    <chr>                                 <chr>               <chr>           <chr>          <chr>  
    #>  1 1350 PENNSYLVANIA AVE., NW SUITE 107  ""                  1350 PENNSYLVA… NW SUITE       107    
    #>  2 5431 WOODLAND BLVD, OXON HILL 20745   ""                  5431 WOODLAND … OXON HILL      20745  
    #>  3 202 VARNUM ST NW, WASHINGTON 20011    ""                  202 VARNUM ST … WASHINGTON     20011  
    #>  4 1212 NEW YORK AVENUE, #300-A, WASHIN… 1212 NEW YORK AVEN… WASHINGTON      DISTICT OF CO… 20005  
    #>  5 20910 BEALLSVILLE RD, DICKERSON, MAR… 20910 BEALLSVILLE … DICKERSON       MARYLAND       20842  
    #>  6 1750 K STREET NW #200, WASHINGTON 20… ""                  1750 K STREET … WASHINGTON     20006  
    #>  7 6305 WAYLES STREET, SPRINGFIELD, VIR… 6305 WAYLES STREET  SPRINGFIELD     VIRGINIA       22150  
    #>  8 4122 16TH STREET, NW, WASHINGTON 200… 4122 16TH STREET    NW              WASHINGTON     20011  
    #>  9 PO BOX 1732, BELTSVILLE, MARYLAND 20… PO BOX 1732         BELTSVILLE      MARYLAND       20706  
    #> 10 316 BAYLEN STREET, PENSACOLA, FLORID… 316 BAYLEN STREET   PENSACOLA       FLORIDA        32502  
    #> # … with 340 more rows

We can fix many of these errors using index subsetting. The most common
error is the original `address` leaving out the “DC” part of the string.

``` r
z <- dc[which(dc$state_sep == "WASHINGTON" & dc$address_sep == ""), ]
z$address_sep <- z$city_sep
z$city_sep <- z$state_sep
z$state_sep <- "DC"
dc[which(dc$state_sep == "WASHINGTON" & dc$address_sep == ""), ] <- z
z <- dc[which(dc$state_sep %out% valid_state & !is.na(dc$state_sep) & dc$address_sep == ""), ]
z$address_sep <- z$city_sep
z$city_sep <- z$state_sep
z$state_sep <- NA
dc[which(dc$state_sep %out% valid_state & !is.na(dc$state_sep) & dc$address_sep == ""), ] <- z
```

There are only 19 remaining rows with a unique `state_sep` value outside
of `valid_state` of `valid_name`.

    #> # A tibble: 29 x 4
    #>    address_sep              city_sep     state_sep                zip_sep
    #>    <chr>                    <chr>        <chr>                    <chr>  
    #>  1 10707 GLOXINIA DRIVE     ROCKVILLE    MARYALND                 20852  
    #>  2 4419 35TH STREET NW      WASHINGTON   DISTICT OF COLUMBIA      20008  
    #>  3 CALLE 84 #105            BOGATA       COLOMBIA                 00000  
    #>  4 8 MCCAUSLAND PLACE #T-1  GAITHERSBURG MARYALND                 20877  
    #>  5 131 INDUSTRY LN          #2           FOREST HILL              21050  
    #>  6 343 CEDAR STREET NW #116 WASHINGTON   DISTICT OF COLUMBIA      20012  
    #>  7 2200 20TH STREET NW      WASHINGTON   DISTICT OF COLUMBIA      20009  
    #>  8 7703 13TH STREET NW      WASHNGTON    DISTRICT OF THE COLUMBIA 20012  
    #>  9 REQUESTED                REQUESTED    REQUESTED                20000  
    #> 10 REQUESTED                REQUESTED    REQUESTED                0      
    #> # … with 19 more rows

## Normalize

Once these components of `address` have been separated into their
respective columns, we can use the `campfin::normal_*()` functions to
improve searchability.

### Address

The `campfin::normal_address()` function can be used to improve
consistency by removing punctuation and expanding abbreviations.

``` r
dc <- dc %>% 
  mutate(
    address_norm = normal_address(
      address = address_sep,
      add_abbs = usps_street,
      na_rep = TRUE
    )
  )
```

    #> # A tibble: 124,731 x 2
    #>    address_sep              address_norm                    
    #>    <chr>                    <chr>                           
    #>  1 6604 NEWPORT PALIVIS CT  6604 NEWPORT PALIVIS COURT      
    #>  2 1737 P ST NW #201        1737 P STREET NORTHWEST 201     
    #>  3 4207 CHESAPEAKE ST NW    4207 CHESAPEAKE STREET NORTHWEST
    #>  4 7621 TREMAYNE PLACE #311 7621 TREMAYNE PLACE 311         
    #>  5 7111 ELIZABETH DR        7111 ELIZABETH DRIVE            
    #>  6 28 BAILESY CT            28 BAILESY COURT                
    #>  7 43709 MAHOGNY RUN CT     43709 MAHOGNY RUN COURT         
    #>  8 "14 GLENHURST COURT "    14 GLENHURST COURT              
    #>  9 17 SEATON PLACE NW       17 SEATON PLACE NORTHWEST       
    #> 10 1029 VERMONT AVENUE NW   1029 VERMONT AVENUE NORTHWEST   
    #> # … with 124,721 more rows

### ZIP

Similarly, the `campfin::normal_zip()` function can be used to form
valid 5-digit US ZIP codes.

``` r
dc <- dc %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip_sep,
      na_rep = TRUE
    )
  )
```

    #> # A tibble: 1,114 x 2
    #>    zip_sep    zip_norm
    #>    <chr>      <chr>   
    #>  1 209011133  20901   
    #>  2 200081707  20008   
    #>  3 482363546  48236   
    #>  4 480701515  48070   
    #>  5 200095775  20009   
    #>  6 03755-3206 03755   
    #>  7 200072122  20007   
    #>  8 200101767  20010   
    #>  9 20017-4309 20017   
    #> 10 2726       02726   
    #> # … with 1,104 more rows

This process improves the consistency of our ZIP code variable and
removes some obviously invalid ZIP codes (e.g., 00000, 99999).

``` r
progress_table(
  dc$zip_sep,
  dc$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct prop_na n_out n_diff
#>   <chr>      <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 zip_sep    0.973       7478 0.00482  6672   1493
#> 2 zip_norm   0.996       6394 0.0101    885    386
```

### State

We can use `campfin::normal_state()` to improve the `state_sep` variable
by abbreviating state names and removing invalid values.

``` r
setdiff(dc$state_sep, valid_state)
#>  [1] NA                         "DISTICT OF COLUMBIA"      "WASHINGTON"              
#>  [4] "VIRGINIA"                 "MARYLAND"                 "OHIO"                    
#>  [7] "NORTH CAROLINA"           "WISCONSIN"                "CALIFORNIA"              
#> [10] "FLORIDA"                  "PENNSYLVANIA"             "NEW YORK"                
#> [13] "TEXAS"                    "NEW JERSEY"               "WASH"                    
#> [16] "DC INFOR"                 "MARYALND"                 "CONNECTICUT"             
#> [19] "DISTRICT OF COLUMBIA"     "REQUESTED"                "DISTRICT OF THE COLUMBIA"
#> [22] "FOREST HILL"              "SUITE"                    "GEORGIA"                 
#> [25] " #400"                    "UNIT A"                   "KINSHASA"                
#> [28] "BALTIMORE"                "ARLINGTON"                "COLOMBIA"                
#> [31] "D.C."                     "MISSOURI"                 "ALABAMA"                 
#> [34] "ILLINOIS"                 "MISSISSIPPI"              ""                        
#> [37] "SOUTH KOREA, DC"          "MASSACHUSETTES"           "CALIFORRNIA"
```

``` r
dc <- dc %>% 
  mutate(
    state_norm = normal_state(
      state = state_sep,
      abbreviate = TRUE,
      na = c("", "NA"),
      na_rep = TRUE,
      valid = NULL
    )
  )
```

``` r
progress_table(
  dc$state_sep,
  dc$state_norm,
  compare = valid_state
)
#> # A tibble: 2 x 6
#>   stage      prop_in n_distinct prop_na n_out n_diff
#>   <chr>        <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 state_sep    0.999         95 0.00518   226     39
#> 2 state_norm   1.000         73 0.00520    47     17
```

There are still a handful of invalid state names we can repair by hand.

``` r
dc %>% 
  filter(state_norm %out% valid_state) %>% 
  drop_na(state_norm) %>% 
  count(state_norm, sort = TRUE)
#> # A tibble: 16 x 2
#>    state_norm                   n
#>    <chr>                    <int>
#>  1 REQUESTED                   16
#>  2 DISTICT OF COLUMBIA         10
#>  3 MARYALND                     4
#>  4 SUITE                        3
#>  5 UNIT A                       3
#>  6 ARLINGTON                    1
#>  7 BALTIMORE                    1
#>  8 CALIFORRNIA                  1
#>  9 COLOMBIA                     1
#> 10 DC INFOR                     1
#> 11 DISTRICT OF THE COLUMBIA     1
#> 12 FOREST HILL                  1
#> 13 KINSHASA                     1
#> 14 MASSACHUSETTES               1
#> 15 SOUTH KOREA DC               1
#> 16 WASH                         1
```

``` r
dc <- dc %>% 
  mutate(
    state_norm = state_norm %>% 
      str_replace("^DISTICT OF COLUMBIA$",      "DC") %>%
      str_replace("^MARYALND$",                 "MD") %>%
      str_replace("^ARLINGTON$",                "VA") %>%
      str_replace("^BALTIMORE$",                "MD") %>%
      str_replace("^CALIFORRNIA$",              "CA") %>%
      str_replace("^COLOMBIA$",                 "DC") %>%
      str_replace("^DC INFOR$",                 "DC") %>%
      str_replace("^DISTRICT OF THE COLUMBIA$", "DC") %>%
      str_replace("^MASSACHUSETTES$",           "MA") %>%
      str_replace("^WASH$",                     "DC")
  )

dc$state_norm[which(dc$state_norm %out% valid_state)] <- NA
```

### City

The `city_sep` variable is the most difficult to normalize due to the
sheer number of possible valid values and the variety in which those
values can be types. There is a four stage process we can use to make
extremely confident changes.

1.  **Normalize** the values with `campfin::normal_zip()`.
2.  **Compare** to the *expected* value with `dplyr::left_join()`.
3.  **Swap** with some expected values using `campfin::str_dist()` and
    `campfin::is_abbrev()`.
4.  **Refine** the remaining similar values with
    `refinr::n_gram_merge()`.

#### Normal City

``` r
dc <- dc %>% 
  mutate(
    city_norm = normal_city(
      city = str_replace(city_sep, "DC", "WASHINGTON"),
      geo_abbs = usps_city,
      st_abbs = c("DC", "D C"),
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

    #> # A tibble: 410 x 4
    #>    city_sep       city_norm             state_norm     n
    #>    <chr>          <chr>                 <chr>      <int>
    #>  1 FT. WASHINGTON FORT WASHINGTON       MD           117
    #>  2 FT WASHINGTON  FORT WASHINGTON       MD            78
    #>  3 ST. LOUIS      SAINT LOUIS           MO            71
    #>  4 FT. WASHINGTON FORT WASHINGTON       DC            55
    #>  5 FT WASHINGTON  FORT WASHINGTON       DC            48
    #>  6 WASHINGTON DC  WASHINGTON WASHINGTON DC            45
    #>  7 ST. PETERSBURG SAINT PETERSBURG      FL            19
    #>  8 NW             NORTHWEST             <NA>          15
    #>  9 DC             WASHINGTON            DC            14
    #> 10 ST LOUIS       SAINT LOUIS           MO            12
    #> # … with 400 more rows

#### Match City

To assess the normalization of city values, it’s useful to compare our
`city_norm` value to the *expected* city value for that record’s state
and ZIP code. To do this, we can use `dplyr::left_join()` with the
`campfin::zipcodes` data frame.

``` r
dc <- dc %>% 
  left_join(zipcodes, by = c("zip_norm" = "zip", "state_norm" = "state")) %>% 
  rename(city_match = city)
```

Most of our `city_match` values are the same as `city_norm`, and most of
the different values are records where no matched city could be found
for a record’s state and/or ZIP code.

``` r
percent(mean(dc$city_norm == dc$city_match, na.rm = TRUE))
#> [1] "97.0%"
percent(prop_na(dc$city_match))
#> [1] "7.89%"
```

#### Swap city

The next step involves comparing our `city_norm` values to `city_match`.
We want to check whether `city_match` might be the valid value for any
invalid `city_norm`. We only want to use this matched value if we can be
very confident. To do this, we’ll use two tests: (1)
`campfin::str_dist()` checks the string distance between the two values,
(2) `campfin::is_abbrev()` checks whether `city_norm` might be an
abbreviation of `city_match`. See the help files (`?is_abbrev`) to
understand exactly what these two functions test.

``` r
dc <- dc %>%
  mutate(
    match_dist = str_dist(city_norm, city_match),
    match_abb = is_abbrev(city_norm, city_match)
  )
```

``` r
summary(dc$match_dist)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
#>    0.00    0.00    0.00    0.22    0.00   27.00   19332
sum(dc$match_abb, na.rm = TRUE)
#> [1] 281
```

Here we can see the 281 records where `city_norm` appears to be an
abbreviation of `city_match`, so the later was used in `city_swap`.

``` r
dc %>% 
  filter(match_abb) %>% 
  count(state_norm, zip_norm, city_norm, city_match, match_abb, sort = TRUE)
#> # A tibble: 148 x 6
#>    state_norm zip_norm city_norm   city_match           match_abb     n
#>    <chr>      <chr>    <chr>       <chr>                <lgl>     <int>
#>  1 MD         21093    LUTHERVILLE LUTHERVILLE TIMONIUM TRUE         30
#>  2 MD         21152    SPARKS      SPARKS GLENCOE       TRUE         19
#>  3 VA         22039    FAIRFAX     FAIRFAX STATION      TRUE         16
#>  4 MD         20769    GLENDALE    GLENN DALE           TRUE         13
#>  5 MD         21090    LINTHICUM   LINTHICUM HEIGHTS    TRUE         10
#>  6 FL         33139    MIAMI       MIAMI BEACH          TRUE          5
#>  7 MA         02460    NEWTON      NEWTONVILLE          TRUE          5
#>  8 VA         20132    PURCEVILLE  PURCELLVILLE         TRUE          5
#>  9 FL         33141    MIAMI       MIAMI BEACH          TRUE          4
#> 10 KS         66217    SHAWNEE     SHAWNEE MISSION      TRUE          4
#> # … with 138 more rows
```

Furthermore, 1652 records has a string distance of only 1, meaning only
1 character was different between `city_norm` and `city_match`, so again
the later was used in `city_swap`.

``` r
dc %>% 
  filter(match_dist == 1) %>% 
  count(state_norm, zip_norm, city_norm, city_match, match_abb, sort = TRUE)
#> # A tibble: 850 x 6
#>    state_norm zip_norm city_norm   city_match   match_abb     n
#>    <chr>      <chr>    <chr>       <chr>        <lgl>     <int>
#>  1 DC         20005    WASHNGTON   WASHINGTON   FALSE        61
#>  2 MD         20646    LAPLATA     LA PLATA     FALSE        34
#>  3 MD         21117    OWINGS MILL OWINGS MILLS FALSE        34
#>  4 VA         22101    MC LEAN     MCLEAN       FALSE        30
#>  5 VA         22003    ANNADALE    ANNANDALE    FALSE        27
#>  6 VA         22191    WOODBRIGE   WOODBRIDGE   FALSE        27
#>  7 VA         22101    MCCLEAN     MCLEAN       FALSE        23
#>  8 MD         20769    GLEN DALE   GLENN DALE   FALSE        21
#>  9 PA         15230    PITTSBURG   PITTSBURGH   FALSE        20
#> 10 PA         15219    PITTSBURG   PITTSBURGH   FALSE        17
#> # … with 840 more rows
```

If a `city_norm` value has either (1) a really small string distance or
(2) appears to be an abbreviation of `city_match`, we can confidently
use the matched value of the messy `city_norm`.

``` r
dc <- dc %>% 
  mutate(
    city_swap = if_else(
      condition = match_abb | match_dist == 1,
      true = city_match,
      false = city_norm
    )
  )
```

#### Refine City

The above steps catch most changes, but we can do one last check using
the OpenRefine key collision and n-gram merging algorithms to check for
any further valid fixes. These algorithms group similar values and use
the most common value in each group.

``` r
good_refine <- dc %>% 
  mutate(
    city_refine = city_swap %>% 
      key_collision_merge(dict = valid_city) %>% 
      n_gram_merge(numgram = 1)
  ) %>% 
  # keep only rows where a change was made
  filter(city_refine != city_swap) %>% 
  # keep only rows where a _correct_ change was made
  inner_join(
    y = zipcodes,
    by = c(
      "city_refine" = "city",
      "state_norm" = "state",
      "zip_norm" = "zip"
    )
  )
```

Very few changes were made this way, but they are useful changes
nonetheless.

``` r
count(x = good_refine, state_norm, city_swap, city_refine, sort = TRUE)
#> # A tibble: 27 x 4
#>    state_norm city_swap             city_refine           n
#>    <chr>      <chr>                 <chr>             <int>
#>  1 DC         WASHINGTON WASHINGTON WASHINGTON           47
#>  2 FL         PONTE VERDE BEACH     PONTE VEDRA BEACH     2
#>  3 MD         BRYAN ROADS           BRYANS ROAD           2
#>  4 MD         OWNINGS MILL          OWINGS MILLS          2
#>  5 NY         SETAUKET              EAST SETAUKET         2
#>  6 CA         SAN FRANCISCO CA      SAN FRANCISCO         1
#>  7 DC         WASHINGONT            WASHINGTON            1
#>  8 GA         ALPHERTTA             ALPHARETTA            1
#>  9 GA         MARRIETA              MARIETTA              1
#> 10 LA         NEWS ORLEAN           NEW ORLEANS           1
#> # … with 17 more rows
```

``` r
dc <- dc %>% 
  left_join(good_refine) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### City Progress

``` r
dc %>% 
  filter(city_refine %out% valid_city) %>% 
  count(state_norm, zip_norm, city_refine, sort = TRUE) %>% 
  drop_na()
#> # A tibble: 623 x 4
#>    state_norm zip_norm city_refine        n
#>    <chr>      <chr>    <chr>          <int>
#>  1 MD         20785    LANDOVER         326
#>  2 MD         20746    CAMP SPRINGS      95
#>  3 MD         20785    CHEVERLY          80
#>  4 MD         20878    NORTH POTOMAC     74
#>  5 FL         33134    CORAL GABLES      72
#>  6 MD         20852    NORTH BETHESDA    63
#>  7 FL         33133    COCONUT GROVE     55
#>  8 MD         20882    LAYTONSVILLE      35
#>  9 MD         20784    NEW CARROLLTON    34
#> 10 MD         20706    GLENARDEN         28
#> # … with 613 more rows
```

By two common Washington/Maryland suburbs to our list of common cities,
we can see our normalization process has brought us above 99% “valid.”

``` r
valid_city <- c(valid_city, "LANDOVER", "CHEVERLY")
```

``` r
progress_table(
  dc$city_sep,
  dc$city_norm,
  dc$city_swap,
  dc$city_refine,
  compare = valid_city
)
#> # A tibble: 4 x 6
#>   stage       prop_in n_distinct prop_na n_out n_diff
#>   <chr>         <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 city_sep      0.963       4963 0.00470  8892   2334
#> 2 city_norm     0.982       4160 0.00529  4286   1474
#> 3 city_swap     0.992       3058 0.0792   1804    545
#> 4 city_refine   0.992       3031 0.0792   1727    518
```

![](../plots/prop_valid_bar-1.png)<!-- -->

![](../plots/distinct_val_bar-1.png)<!-- -->

## Conclude

1.  How are 244678 records in the database.
2.  There are 0 duplicate records.
3.  The `amount` values range from $-31,889.24 to $400,000.
4.  The `dateofreceipt` ranges from to .
5.  The 22054 records missing a `candidatename` or `payee` value are
    flagged with the logical `na_flag` variable.
6.  Consistency in ZIP codes and state abbreviations has been fixed from
    `address`.
7.  The `zip_clean` variable contains the 5 digit ZIP from `address`.
8.  The `transactionyear` variable contains the 4 digit year of the
    receipt.
9.  Only 91.0% of records contain all the data needed to identify the
    transaction.

## Lookup

``` r
lookup <- read_csv("dc/contribs/data/dc_city_lookup_CONT.csv") %>% select(1:2)
dc <- left_join(dc, lookup, by = "city_refine")

progress_table(
  dc$city_refine, 
  dc$city_refine2, 
  compare = valid_city
)
#> # A tibble: 2 x 6
#>   stage        prop_in n_distinct prop_na n_out n_diff
#>   <chr>          <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 city_refine    0.992       3031  0.0792  1727    518
#> 2 city_refine2   0.993       2895  0.0792  1525    390
```

## Write

``` r
dir_proc <- here("dc", "contribs", "data", "processed")
dir_create(dir_proc)
raw_file <- glue("{dir_proc}/dc_contribs_clean.csv")

dc <- dc %>% 
  select(
    -address_sep,
    -city_sep,
    -state_sep,
    -zip_sep,
    -city_norm,
    -city_match,
    -match_dist,
    -match_abb,
    -city_swap,
    -city_refine,
    -address_id,
    -xcoord,
    -ycoord,
    -fulladdress,
    -gis_last_mod_dttm
  )

if (!this_file_new(raw_file)) {
  write_csv(dc, raw_file, na = "")
}
```
