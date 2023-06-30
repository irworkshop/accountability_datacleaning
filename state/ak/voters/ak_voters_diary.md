Alaska voters
================
Jennifer LaFleur
2023-06-15 15:49:33

-   [Project](#project)
-   [Objectives](#objectives)
-   [Packages](#packages)
-   [Read](#read)
-   [Data](#data)
-   [Explore](#explore)
    -   [Missing](#missing)
    -   [Duplicates](#duplicates)
    -   [Categorical](#categorical)
    -   [Cleaning](#cleaning)
-   [Explore](#explore-1)
-   [Wrangle](#wrangle)
-   [Conclude](#conclude)
-   [Export](#export)
-   [Dictionary](#dictionary)

<!-- Place comments regarding knitting here -->

## Project

The Accountability Project is an effort to cut across data silos and
give journalists, policy professionals, activists, and the public at
large a simple way to search across public data about individuals,
organizations and locations.

Our goal is to standardize public data on a few key fields by thinking
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

``` r
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  gluedown, # printing markdown
  janitor, # clean data frames
  campfin, # custom irw tools
  aws.s3, # aws cloud storage
  readxl, # read excel files
  refinr, # cluster & merge
  scales, # format strings
  digest, # hash strings
  knitr, # knit documents
  vroom, # fast reading
  rvest, # scrape html
  glue, # code strings
  here, # project paths
  httr, # http requests
  fs, # local storage 
  stringr # string functions
 )
```

## Read

``` r
akv <- read.csv('ak_Public_Voter_List_20230118.csv',strip.white=TRUE)
```

``` r
party <- read.csv('party.csv')
akv <- akv %>%  
    left_join(party, by = c("PARTY"="partycode"))
```

## Data

The Alaska voter data was obtained via open records request from the
Alaska Division of Elections. And received in January 2023.

Two files were provided to the Accountability Project:

1.  a csv containing the voter data
2.  a pdf containing the record layout

#### Columns

| column            | description                                                |
|:------------------|:-----------------------------------------------------------|
| UN                | Address undeliverable                                      |
| PARTY             | Voter party affiliation                                    |
| DP                | Voter house district and precinct                          |
| LAST_NAME         | Voter last name                                            |
| FIRST_NAME        | Voter first name                                           |
| MIDDLE_NAME       | Voter middle init_name                                     |
| SUFFIX_NAME       | Voter suffix                                               |
| ASCENSION         | Random number assigned to the voter                        |
| REG_DATE          | Date of most recent registration (if included)             |
| ORG_REG_DATE      | Date when voter originally registered (if included)        |
| DIST_DATE         | Date when voter registered in house district (if included) |
| RESIDENCE_ADDRESS | Voter residence address                                    |
| RESIDENCE_CITY    | Voter residence city                                       |
| RESIDENCE_ZIP     | Voter residence ZIP                                        |
| MAILING_ADDRESS1  | Line 1 voter mailing address                               |
| MAILING_ADDRESS2  | Line 2 voter mailing address                               |
| MAILING_ADDRESS3  | Line 3 voter mailing address                               |
| MAILING_CITY      | Voter mailing city                                         |
| MAILING_STATE     | Voter mailing state                                        |
| MAILING_ZIP       | Voter mailing ZIP                                          |
| MAILING_COUNTRY   | If overseas, voter mailing country                         |
| GENDER            | Voter gender                                               |
| VH1               | voter history columns                                      |
| VH2               |                                                            |
| VH3               |                                                            |
| VH4               |                                                            |
| VH5               |                                                            |
| VH6               |                                                            |
| VH7               |                                                            |
| VH8               |                                                            |
| VH9               |                                                            |
| VH10              |                                                            |
| VH11              |                                                            |
| VH12              |                                                            |
| VH13              |                                                            |
| VH14              |                                                            |
| VH15              |                                                            |
| VH16              |                                                            |

Voter history is represented by an election ID that consists of five to
six characters with the first two digits being the year of the election
followed by a three to four lettered election name code. The second set
of data is the method that the voter voted:

P Voted in person at the polls  
E Voted an Early Vote ballot  
A Voted an Absentee ballot  
Q Voted a Questioned ballot

Statewide primary and general elections are consistently named with the
year and  
election codes of PRIM and GENR:  
18PRIM 2018 Primary Election  
18GENR 2018 General Election

Statewide special elections are reflected as:  
07SPEC 2007 Statewide Special Election

State conducted Regional Educational Attendance Area elections (school
board elections  
in unorganized boroughs of Alaska) are reflected as REAA, RE## or R###:
18REAA 2018 Regional Educational Attendance Area elections  
18RE17 2018 Regional Educational Attendance Area election in REAA 17  
18R123 2018 Regional Education Attendance Area election in REAA 12  
Section 3

Local and special city and borough elections from 2016 forward, the
election ID will show the two-digit year and three to four alpha
characters that represents the city/borough name or geographic region
name:

18VALD 2018 local election for the City of Valdez  
18MOA 2018 local election for the Municipality of Anchorage 18WASI 2018
local election for the City of Wasilla  
18FNSB 2018 local election for the Fairbanks North Star Borough 18NSLB
2018 local election for the North Slope Borough

At times, city and boroughs will conduct special or run-off elections.
The last characterof the election ID will reflect either a â€˜Sâ€™ or
â€˜Râ€™ for special or runoff. Prior to 2016, local and special city and
borough elections were:  
12REGL 2012 Regular Local Election  
12SPEL 2012 Special Local Election

For a list of city and/or boroughs within the State of Alaska, visit the
division  
Research webpage below and locate the Alaska Community List selections:
<http://www.elections.alaska.gov/Core/electionresources.php>

#### Political party

Voter political party affiliation. Recognized Political Parties: Are
those parties that have gained recognized political party status under
Alaska Statute 15.80.010(27) and voters appear on voter lists as
follows: A:Alaskan Independence Party D:Alaska Democratic Party R:Alaska
Republican Party

Political Groups: Are those groups that have applied for party status
but have not met the qualifications to be a recognized political party
under Alaska Statute 15.80.010(26) and voters appear on voter lists as
follows: C:Alaska Constitution Party L:Alaska Libertarian Party
E:Moderate Party of Alaska O:Progressive Party of Alaska F:Freedom
Reform Party P:Patriot’s Party of Alaska G:Green Party of Alaska
V:Veterans Party of Alaska H:OWL Party W:UCES Clowns Party K:Alliance
Party of Alaska No Affiliation / Undeclared: Voters who chose not to
declare an affiliation or who are unaffiliated appear on voter lists as
follows: N:Nonpartisan (no affiliation) U:Undeclared

## Explore

There are 604,108 rows of 39 columns.

``` r
glimpse(akv)
#> Rows: 604,108
#> Columns: 39
#> $ UN                <chr> "", "", "", "", "", "", "", "", "", "", "", "", "", "*", "", "", "", ""…
#> $ PARTY             <chr> "U", "N", "U", "D", "U", "N", "R", "D", "N", "N", "U", "D", "U", "D", "…
#> $ DP                <chr> "23-810", "19-610", "19-625", "30-585", "37-738", "19-610", "30-585", "…
#> $ LAST_NAME         <chr> "A'ASA", "A'ASA", "A-SOLOMONA", "AABERG", "AABERG", "AABERG", "AABERG",…
#> $ FIRST_NAME        <chr> "FAITUPE", "NIAGAI", "FAALUAINA", "AADEN", "ILLEAH", "JEANNICE", "KAROL…
#> $ MIDDLE_NAME       <chr> "M", "S", "", "ELEPH", "A", "M", "MARIE", "", "J", "S", "MARY", "LAEL",…
#> $ SUFFIX_NAME       <chr> "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",…
#> $ ASCENSION         <int> 1172993, 1016003, 1435921, 564072, 1192708, 607559, 564004, 842244, 931…
#> $ REG_DATE          <chr> "8/16/2022", "11/23/2021", "5/20/2022", "10/17/2022", "11/4/2014", "5/2…
#> $ ORG_REG_DATE      <chr> "6/19/2014", "6/18/2008", "5/20/2022", "10/2/1992", "11/4/2014", "4/23/…
#> $ DIST_DATE         <chr> "5/15/2020", "11/23/2021", "5/20/2022", "7/1/2018", "11/4/2014", "11/13…
#> $ RESIDENCE_ADDRESS <chr> "16810  EASY ST UNIT 4", "1625  DOLINA CIR", "310  BRAGAW ST APT 5", "6…
#> $ RESIDENCE_CITY    <chr> "EAGLE RIVER", "ANCHORAGE", "ANCHORAGE", "WASILLA", "NONDALTON", "ANCHO…
#> $ RESIDENCE_ZIP     <int> 99577, 99508, 99508, 99654, 99640, 99508, 99654, 99516, 99504, 99504, 9…
#> $ MAILING_ADDRESS1  <chr> "16810 EASY ST APT 4", "1625  DOLINA CIR", "310 BRAGAW ST APT 5", "PO B…
#> $ MAILING_ADDRESS2  <chr> "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",…
#> $ MAILING_ADDRESS3  <chr> "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",…
#> $ MAILING_CITY      <chr> "EAGLE RIVER", "ANCHORAGE", "ANCHORAGE", "WASILLA", "NONDALTON", "ANCHO…
#> $ MAILING_STATE     <chr> "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK",…
#> $ MAILING_ZIP       <chr> "99577", "99508", "99508-2157", "99687", "99640-0043", "99508-2845", "9…
#> $ MAILING_COUNTRY   <chr> "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",…
#> $ GENDER            <chr> "F", "F", "F", "M", "M", "F", "F", "F", "F", "M", "F", "M", "M", "M", "…
#> $ VH1               <chr> "22GENR P", "20GENR A", "", "22GENR A", "22GENR P", "22GENR P", "22MSB …
#> $ VH2               <chr> "22PRIM Q", "16GENR E", "", "22SSPE A", "20GENR P", "22PRIM P", "22GENR…
#> $ VH3               <chr> "21MOA M", "", "", "20GENR P", "18GENR P", "22SSPE A", "22PRIM P", "22M…
#> $ VH4               <chr> "20GENR P", "", "", "18GENR P", "16GENR P", "22MOA M", "22SSPE A", "20G…
#> $ VH5               <chr> "20PRIM P", "", "", "16GENR P", "14GENR Q", "", "20MSB P", "20PRIM P", …
#> $ VH6               <chr> "18GENR A", "", "", "14GENR P", "", "", "20GENR P", "18GENR P", "20GENR…
#> $ VH7               <chr> "16GENR P", "", "", "", "", "", "18GENR P", "18PRIM P", "18GENR P", "20…
#> $ VH8               <chr> "15SPEL P", "", "", "", "", "", "18PRIM P", "16GENR E", "16GENR E", "19…
#> $ VH9               <chr> "14GENR P", "", "", "", "", "", "16GENR P", "16PRIM P", "", "18GENR P",…
#> $ VH10              <chr> "", "", "", "", "", "", "16PRIM P", "16MOA3 P", "", "18MOA M", "", "14R…
#> $ VH11              <chr> "", "", "", "", "", "", "14GENR P", "15SPEL P", "", "17MOA P", "", "", …
#> $ VH12              <chr> "", "", "", "", "", "", "", "14GENR A", "", "16GENR E", "", "", "", "",…
#> $ VH13              <chr> "", "", "", "", "", "", "", "14PRIM P", "", "16MOA5 P", "", "", "", "",…
#> $ VH14              <chr> "", "", "", "", "", "", "", "14REGL P", "", "15SPEL P", "", "", "", "",…
#> $ VH15              <chr> "", "", "", "", "", "", "", "", "", "15REGL P", "", "", "", "", "", "16…
#> $ VH16              <chr> "", "", "", "", "", "", "", "", "", "14GENR P", "", "", "", "", "", "16…
#> $ party_name        <chr> "Undeclared", "Nonpartisan (no affiliation)", "Undeclared", "Alaska Dem…
tail(akv)
#> # A tibble: 6 × 39
#>   UN    PARTY DP    LAST_…¹ FIRST…² MIDDL…³ SUFFI…⁴ ASCEN…⁵ REG_D…⁶ ORG_R…⁷ DIST_…⁸ RESID…⁹ RESID…˟
#>   <chr> <chr> <chr> <chr>   <chr>   <chr>   <chr>     <int> <chr>   <chr>   <chr>   <chr>   <chr>  
#> 1 ""    N     30-5… ZYWNA   JOSEFA  M       ""       472955 5/20/2… 10/6/1… 4/16/2… 16516 … "TALKE…
#> 2 ""    N     30-5… ZYWNA   ROBERT  JAMES   ""       473483 5/20/2… 10/3/1… 4/16/2… 16516 … "TALKE…
#> 3 ""    U     25-3… ZYWOT   JOSEPH  ANDREW  ""      1410079 12/2/2… 6/2/20… 6/2/20… PRIVATE ""     
#> 4 ""    N     25-3… ZYWOT   MARTINA L       ""       743304 5/19/2… 5/15/1… 9/25/2… 2816  … "PALME…
#> 5 ""    R     25-3… ZYWOT   NICHOL… ANDREW  ""       154860 5/20/2… 11/9/2… 7/6/20… 2816  … "PALME…
#> 6 ""    U     29-5… ZYWOT   NICHOL… R       ""      1062510 5/24/2… 12/21/… 12/21/… 7140  … "WASIL…
#> # … with 26 more variables: RESIDENCE_ZIP <int>, MAILING_ADDRESS1 <chr>, MAILING_ADDRESS2 <chr>,
#> #   MAILING_ADDRESS3 <chr>, MAILING_CITY <chr>, MAILING_STATE <chr>, MAILING_ZIP <chr>,
#> #   MAILING_COUNTRY <chr>, GENDER <chr>, VH1 <chr>, VH2 <chr>, VH3 <chr>, VH4 <chr>, VH5 <chr>,
#> #   VH6 <chr>, VH7 <chr>, VH8 <chr>, VH9 <chr>, VH10 <chr>, VH11 <chr>, VH12 <chr>, VH13 <chr>,
#> #   VH14 <chr>, VH15 <chr>, VH16 <chr>, party_name <chr>, and abbreviated variable names
#> #   ¹​LAST_NAME, ²​FIRST_NAME, ³​MIDDLE_NAME, ⁴​SUFFIX_NAME, ⁵​ASCENSION, ⁶​REG_DATE, ⁷​ORG_REG_DATE,
#> #   ⁸​DIST_DATE, ⁹​RESIDENCE_ADDRESS, ˟​RESIDENCE_CITY
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(akv, count_na)
#> # A tibble: 39 × 4
#>    col               class     n          p
#>    <chr>             <chr> <int>      <dbl>
#>  1 UN                <chr>     0 0         
#>  2 PARTY             <chr>     0 0         
#>  3 DP                <chr>     0 0         
#>  4 LAST_NAME         <chr>     6 0.00000993
#>  5 FIRST_NAME        <chr>     2 0.00000331
#>  6 MIDDLE_NAME       <chr>    25 0.0000414 
#>  7 SUFFIX_NAME       <chr>     0 0         
#>  8 ASCENSION         <int>     0 0         
#>  9 REG_DATE          <chr>     0 0         
#> 10 ORG_REG_DATE      <chr>     0 0         
#> 11 DIST_DATE         <chr>     0 0         
#> 12 RESIDENCE_ADDRESS <chr>     0 0         
#> 13 RESIDENCE_CITY    <chr>     0 0         
#> 14 RESIDENCE_ZIP     <int> 83264 0.138     
#> 15 MAILING_ADDRESS1  <chr>     0 0         
#> 16 MAILING_ADDRESS2  <chr>     0 0         
#> 17 MAILING_ADDRESS3  <chr>     0 0         
#> 18 MAILING_CITY      <chr>     0 0         
#> 19 MAILING_STATE     <chr>     0 0         
#> 20 MAILING_ZIP       <chr>     0 0         
#> 21 MAILING_COUNTRY   <chr>     0 0         
#> 22 GENDER            <chr>     0 0         
#> 23 VH1               <chr>     0 0         
#> 24 VH2               <chr>     0 0         
#> 25 VH3               <chr>     0 0         
#> 26 VH4               <chr>     0 0         
#> 27 VH5               <chr>     0 0         
#> 28 VH6               <chr>     0 0         
#> 29 VH7               <chr>     0 0         
#> 30 VH8               <chr>     0 0         
#> 31 VH9               <chr>     0 0         
#> 32 VH10              <chr>     0 0         
#> 33 VH11              <chr>     0 0         
#> 34 VH12              <chr>     0 0         
#> 35 VH13              <chr>     0 0         
#> 36 VH14              <chr>     0 0         
#> 37 VH15              <chr>     0 0         
#> 38 VH16              <chr>     0 0         
#> 39 party_name        <chr>     0 0
```

No columns are missing the registration date or last name needed to
identify a voter.

### Duplicates

We can also flag any record completely duplicated across every column.

``` r
d1 <- duplicated(akv, fromLast = FALSE)
d2 <- duplicated(akv, fromLast = TRUE)
akv <- mutate(akv, dupe_flag = d1 | d2)
sum(akv$dupe_flag)
#> [1] 0
```

``` r
akv %>% 
  filter(dupe_flag) %>% 
  select(ORG_REG_DATE, LAST_NAME, PARTY) %>% 
  arrange(ORG_REG_DATE)
#> # A tibble: 0 × 3
#> # … with 3 variables: ORG_REG_DATE <chr>, LAST_NAME <chr>, PARTY <chr>
```

### Categorical

``` r
col_stats(akv, n_distinct)
#> # A tibble: 40 × 4
#>    col               class      n          p
#>    <chr>             <chr>  <int>      <dbl>
#>  1 UN                <chr>      3 0.00000497
#>  2 PARTY             <chr>     16 0.0000265 
#>  3 DP                <chr>    401 0.000664  
#>  4 LAST_NAME         <chr>  87721 0.145     
#>  5 FIRST_NAME        <chr>  47808 0.0791    
#>  6 MIDDLE_NAME       <chr>  41967 0.0695    
#>  7 SUFFIX_NAME       <chr>     25 0.0000414 
#>  8 ASCENSION         <int> 604108 1         
#>  9 REG_DATE          <chr>   5999 0.00993   
#> 10 ORG_REG_DATE      <chr>  17889 0.0296    
#> 11 DIST_DATE         <chr>  15322 0.0254    
#> 12 RESIDENCE_ADDRESS <chr> 319100 0.528     
#> 13 RESIDENCE_CITY    <chr>    324 0.000536  
#> 14 RESIDENCE_ZIP     <int>    249 0.000412  
#> 15 MAILING_ADDRESS1  <chr> 286566 0.474     
#> 16 MAILING_ADDRESS2  <chr>   6465 0.0107    
#> 17 MAILING_ADDRESS3  <chr>     63 0.000104  
#> 18 MAILING_CITY      <chr>   7127 0.0118    
#> 19 MAILING_STATE     <chr>     62 0.000103  
#> 20 MAILING_ZIP       <chr> 141650 0.234     
#> 21 MAILING_COUNTRY   <chr>    128 0.000212  
#> 22 GENDER            <chr>      3 0.00000497
#> 23 VH1               <chr>    832 0.00138   
#> 24 VH2               <chr>    939 0.00155   
#> 25 VH3               <chr>    917 0.00152   
#> 26 VH4               <chr>    885 0.00146   
#> 27 VH5               <chr>    886 0.00147   
#> 28 VH6               <chr>    872 0.00144   
#> 29 VH7               <chr>    796 0.00132   
#> 30 VH8               <chr>    757 0.00125   
#> 31 VH9               <chr>    692 0.00115   
#> 32 VH10              <chr>    635 0.00105   
#> 33 VH11              <chr>    566 0.000937  
#> 34 VH12              <chr>    524 0.000867  
#> 35 VH13              <chr>    464 0.000768  
#> 36 VH14              <chr>    397 0.000657  
#> 37 VH15              <chr>    357 0.000591  
#> 38 VH16              <chr>    301 0.000498  
#> 39 party_name        <chr>     16 0.0000265 
#> 40 dupe_flag         <lgl>      1 0.00000166
```

### Cleaning

Pull the year from ORG_REG_DATE

``` r
akv <- mutate(akv, year = str_sub(ORG_REG_DATE, start= -4))
```

Add the state

``` r
akv <- mutate(akv, state = "Alaska")
```

Create a five-digit zip field

``` r
akv <- mutate(akv, zip = str_sub(RESIDENCE_ZIP, 1, 5))
```

Clean column names

``` r
akv <- clean_names(akv)
```

## Explore

![](../plots/bar_year-1.png)<!-- -->![](../plots/bar_year-2.png)<!-- -->

## Wrangle

Check geo variables

    #>   [1] "EAGLE RIVER"          "ANCHORAGE"            "WASILLA"              "NONDALTON"           
    #>   [5] ""                     "JUNEAU"               "UTQIAGVIK"            "STERLING"            
    #>   [9] "FAIRBANKS"            "SOLDOTNA"             "MOOSE PASS"           "NORTH POLE"          
    #>  [13] "HOMER"                "CRAIG"                "PALMER"               "CHINIAK"             
    #>  [17] "KENAI"                "PETERSBURG"           "SEWARD"               "FORT WAINWRIGHT"     
    #>  [21] "KODIAK"               "DOUGLAS"              "BIG LAKE"             "DELTA JUNCTION"      
    #>  [25] "KETCHIKAN"            "AKUTAN"               "EGEGIK"               "CHUGIAK"             
    #>  [29] "TALKEETNA"            "UNALASKA"             "SALCHA"               "WILLOW"              
    #>  [33] "GRAYLING"             "WRANGELL"             "JBER"                 "TRAPPER CREEK"       
    #>  [37] "NOME"                 "KACHEMAK BAY"         "SAXMAN"               "SITKA"               
    #>  [41] "SHUNGNAK"             "ANGOON"               "BETHEL"               "TOK"                 
    #>  [45] "CLAM GULCH"           "EAGLE"                "ANCHOR POINT"         "HYDER"               
    #>  [49] "PERRYVILLE"           "DUTCH HARBOR"         "GAKONA"               "KOTZEBUE"            
    #>  [53] "GLENNALLEN"           "TELLER"               "EIELSON AFB"          "CHIGNIK LAGOON"      
    #>  [57] "STEBBINS"             "ST MICHAEL"           "CHEFORNAK"            "SLANA"               
    #>  [61] "HOOPER BAY"           "TOGIAK"               "NUNAM IQUA"           "TWIN HILLS"          
    #>  [65] "TOKSOOK BAY"          "TAKOTNA"              "TWO RIVERS"           "NENANA"              
    #>  [69] "GALENA"               "DILLINGHAM"           "SCAMMON BAY"          "LOWER KALSKAG"       
    #>  [73] "QUINHAGAK"            "GIRDWOOD"             "ILIAMNA"              "WHITTIER"            
    #>  [77] "PILOT POINT"          "VALDEZ"               "SUTTON"               "KAKE"                
    #>  [81] "HAINES"               "KASILOF"              "ALLAKAKET"            "SKAGWAY"             
    #>  [85] "CORDOVA"              "NEW STUYAHOK"         "EKWOK"                "ATMAUTLUAK"          
    #>  [89] "NEWTOK"               "KIPNUK"               "KASIGLUK"             "ALEKNAGIK"           
    #>  [93] "KONGIGANAK"           "TULUKSAK"             "HEALY"                "BREVIG MISSION"      
    #>  [97] "COOPER LANDING"       "KIVALINA"             "NOATAK"               "SAND POINT"          
    #> [101] "SHISHMAREF"           "KOYUK"                "FORT YUKON"           "YAKUTAT"             
    #> [105] "MOUNTAIN VILLAGE"     "NORTHWAY"             "ARCTIC VILLAGE"       "KING SALMON"         
    #> [109] "ALAKANUK"             "TETLIN"               "KAKTOVIK"             "HOUSTON"             
    #> [113] "VENETIE"              "BEAVER"               "METLAKATLA"           "LARSEN BAY"          
    #> [117] "HYDABURG"             "ST PAUL ISLAND"       "WHITE MOUNTAIN"       "NOORVIK"             
    #> [121] "MENTASTA LAKE"        "NINILCHIK"            "INDIAN"               "PLATINUM"            
    #> [125] "TANANA"               "PORT HEIDEN"          "PELICAN"              "RUBY"                
    #> [129] "PRUDHOE BAY"          "COFFMAN COVE"         "KLAWOCK"              "THORNE BAY"          
    #> [133] "CLEAR"                "ESTER"                "ANIAK"                "HOLLIS"              
    #> [137] "EMMONAK"              "ST MARYS"             "GUSTAVUS"             "UNALAKLEET"          
    #> [141] "CHEVAK"               "TUNUNAK"              "NAKNEK"               "SELDOVIA"            
    #> [145] "WAINWRIGHT"           "ATQASUK"              "HUSLIA"               "NULATO"              
    #> [149] "KALTAG"               "AKHIOK"               "OUZINKIE"             "NIGHTMUTE"           
    #> [153] "TUNTUTULIAK"          "MARSHALL"             "KOKHANOK"             "PILOT STATION"       
    #> [157] "EEK"                  "ANAKTUVUK PASS"       "DIOMEDE"              "WALES"               
    #> [161] "NUIQSUT"              "BUCKLAND"             "SELAWIK"              "POINT LAY"           
    #> [165] "POINT HOPE"           "COPPER CENTER"        "KING COVE"            "HOPE"                
    #> [169] "BARROW"               "KOTLIK"               "AKIACHAK"             "WISEMAN"             
    #> [173] "MANLEY HOT SPRINGS"   "SAVOONGA"             "MANOKOTAK"            "KOYUKUK"             
    #> [177] "AKIAK"                "KWIGILLINGOK"         "PAXSON"               "CHIGNIK LAKE"        
    #> [181] "CHIGNIK"              "RAMPART"              "MINTO"                "PORT GRAHAM"         
    #> [185] "MCCARTHY"             "CHITINA"              "OLD HARBOR"           "NIKOLAI"             
    #> [189] "NUNAPITCHUK"          "KWETHLUK"             "RUSSIAN MISSION"      "NAPAKIAK"            
    #> [193] "KALSKAG"              "CROOKED CREEK"        "MCGRATH"              "NAPASKIAK"           
    #> [197] "MEKORYUK"             "SLEETMUTE"            "EUREKA"               "WHALE PASS"          
    #> [201] "DENALI NATIONAL PARK" "TATITLEK"             "CENTRAL"              "SKWENTNA"            
    #> [205] "NAUKATI"              "TENAKEE SPRINGS"      "HOONAH"               "HOLY CROSS"          
    #> [209] "PORT ALSWORTH"        "TANACROSS"            "CLEAR SFS"            "IGIUGIG"             
    #> [213] "ADAK"                 "GOLOVIN"              "GAMBELL"              "ELIM"                
    #> [217] "PORT PROTECTION"      "HUGHES"               "NANWALEK"             "CANTWELL"            
    #> [221] "ELFIN COVE"           "SOUTH NAKNEK"         "EVANSVILLE"           "KUPREANOF"           
    #> [225] "EARECKSON AS"         "NIKISKI"              "ANDERSON"             "FORT GREELY"         
    #> [229] "STONY RIVER"          "KARLUK"               "KOLIGANEK"            "LEVELOCK"            
    #> [233] "SHAKTOOLIK"           "NEWHALEN"             "CHICKALOON"           "POINT BAKER"         
    #> [237] "COLDFOOT"             "KIANA"                "SHAGELUK"             "COLD BAY"            
    #> [241] "UPPER KALSKAG"        "CHUATHBALUK"          "EDNA BAY"             "GOODNEWS BAY"        
    #> [245] "TYONEK"               "ST PAUL"              "FALSE PASS"           "DEERING"             
    #> [249] "AMBLER"               "BIRD CREEK"           "KOBUK"                "PORT LIONS"          
    #> [253] "HALIBUT COVE"         "CHISTOCHINA"          "ANVIK"                "KASAAN"              
    #> [257] "OSCARVILLE"           "TAZLINA"              "CIRCLE"               "BELUGA"              
    #> [261] "CHALKYITSIK"          "LIME VILLAGE"         "KENNY LAKE"           "PEDRO BAY"           
    #> [265] "ST GEORGE ISLAND"     "NELSON LAGOON"        "MEYERS CHUCK"         "FLAT"                
    #> [269] "PORT ALEXANDER"       "UGASHIK"              "SHEMYA AFS"           "KLUKWAN"             
    #> [273] "STEVENS VILLAGE"      "CHICKEN"              "LIVENGOOD"            "BETTLES FIELD"       
    #> [277] "BETTLES"              "EXCURSION INLET"      "CHIGNIK BAY"          "PORTAGE CREEK"       
    #> [281] "MENTASTA"             "CLARKS POINT"         "PORT MOLLER"          "ALEXANDER CREEK"     
    #> [285] "CHENEGA BAY"          "ELLAMAR"              "FERRY"                "COUNCIL"             
    #> [289] "MAIN BAY"             "FUNTER BAY"           "DOT LAKE"             "NIKOLSKI"            
    #> [293] "ATKA"                 "FORTUNA LEDGE"        "GULKANA"              "KENNICOTT"           
    #> [297] "ALATNA"               "RED DEVIL"            "SHEEP MOUNTAIN"       "AMCHITKA"            
    #> [301] "HEALY LAKE"           "PITKAS POINT"         "LAKE MINCHUMINA"      "CHISANA"             
    #> [305] "ESTHER ISLAND"        "KUPREANOF ISLAND"     "PORTAGE"              "PORT FIDALGO"        
    #> [309] "CIRCLE CITY"          "LAKE LOUISE"          "DEADHORSE"            "BIRCH CREEK"         
    #> [313] "HAWKINS ISLAND"       "HOBART BAY"           "FORT RICHARDSON"      "MANKOMEN LAKE"       
    #> [317] "UNAKWIK INLET"        "BOUNDARY"             "PORT ARMSTRONG"       "HAWK INLET"          
    #> [321] "CLEAR AFS"            "CHANDALAR LAKE"       "ELMENDORF AFB"        "TIN CITY"
    #> [1] "Alaska"
    #> [1] 0.9999981

## Conclude

``` r
glimpse(sample_n(akv, 25))
#> Rows: 25
#> Columns: 43
#> $ un                <chr> "", "", "", "*", "?", "", "", "", "*", "", "", "", "", "*", "?", "", ""…
#> $ party             <chr> "R", "U", "U", "N", "N", "U", "U", "U", "U", "N", "U", "U", "D", "R", "…
#> $ dp                <chr> "27-425", "01-610", "37-707", "25-335", "35-582", "17-505", "31-446", "…
#> $ last_name         <chr> "COTTLE", "TOOLE", "WHEELER", "PHILLIPS", "FITZGERALD", "ZIMMER", "LOBL…
#> $ first_name        <chr> "SAILOR", "CARMEN", "GRACE", "DANIEL", "TERESA", "TERESA", "BRADLEY", "…
#> $ middle_name       <chr> "ADDISON", "M", "HELEN", "SCOTT", "L", "KAY", "ALLEN", "", "EZEKIEL", "…
#> $ suffix_name       <chr> "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",…
#> $ ascension         <int> 1359575, 880038, 1298393, 193709, 857145, 652549, 801047, 135749, 13473…
#> $ reg_date          <chr> "11/8/2022", "5/20/2022", "5/20/2022", "5/20/2022", "3/25/2015", "10/11…
#> $ org_reg_date      <chr> "8/13/2019", "2/10/2003", "7/1/2018", "7/24/1982", "3/19/2002", "8/31/1…
#> $ dist_date         <chr> "8/13/2019", "2/10/2003", "7/1/2018", "11/6/1990", "3/25/2015", "3/4/20…
#> $ residence_address <chr> "425  W LAKE VIEW AVE", "2111  2ND AVE", "1ST  RD HOUSING 3RD HOUSE ON …
#> $ residence_city    <chr> "WASILLA", "KETCHIKAN", "ANIAK", "", "FAIRBANKS", "ANCHORAGE", "FAIRBAN…
#> $ residence_zip     <int> 99654, 99901, 99557, NA, 99709, 99501, 99709, 99835, 99517, 99835, 9990…
#> $ mailing_address1  <chr> "425 W LAKE VIEW AVE", "2111 SECOND AVE", "PO BOX 174", "1150 S COLONY …
#> $ mailing_address2  <chr> "", "", "", "", "", "", "", "", "", "", "", "", "UNIT 403", "", "", "",…
#> $ mailing_address3  <chr> "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",…
#> $ mailing_city      <chr> "WASILLA", "KETCHIKAN", "ANIAK", "PALMER", "NORTH POLE", "ANCHORAGE", "…
#> $ mailing_state     <chr> "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK", "AK",…
#> $ mailing_zip       <chr> "99654-7967", "99901-6033", "99557-0174", "99645-6967", "99705", "99501…
#> $ mailing_country   <chr> "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",…
#> $ gender            <chr> "F", "F", "F", "M", "F", "F", "M", "F", "M", "F", "M", "M", "F", "M", "…
#> $ vh1               <chr> "22GENR Q", "22GENR P", "", "20GENR A", "", "22GENR A", "22GENR P", "22…
#> $ vh2               <chr> "22PRIM P", "22KTNB P", "", "20PRIM A", "", "22PRIM E", "22PRIM P", "22…
#> $ vh3               <chr> "22SSPE A", "22PRIM P", "", "19MSB P", "", "22SSPE A", "22SSPE A", "22S…
#> $ vh4               <chr> "21MSB P", "22SSPE A", "", "18GENR P", "", "22MOA M", "21FBX P", "21SIT…
#> $ vh5               <chr> "20MSB P", "21KTNB P", "", "18MSB P", "", "21MOAR M", "21FNSB P", "20GE…
#> $ vh6               <chr> "20GENR P", "21KETC P", "", "16GENR E", "", "21MOA M", "20GENR P", "20S…
#> $ vh7               <chr> "20WASR P", "20KETC P", "", "15MSB1 P", "", "20GENR A", "20FNSB P", "20…
#> $ vh8               <chr> "20WAS P", "20GENR P", "", "14GENR P", "", "20MOA M", "20FBX P", "19SIT…
#> $ vh9               <chr> "20PRIM P", "20KTNB P", "", "14PRIM P", "", "19MOA M", "18GENR Q", "18G…
#> $ vh10              <chr> "", "19KTNB P", "", "14REGL P", "", "18GENR A", "17FNSB Q", "18SITK A",…
#> $ vh11              <chr> "", "18GENR P", "", "13REGL P", "", "18MOA M", "16GENR P", "17SITK P", …
#> $ vh12              <chr> "", "18KTNB P", "", "", "", "17MOA P", "16FNSB Q", "16GENR P", "", "17S…
#> $ vh13              <chr> "", "17KTNB P", "", "", "", "16GENR P", "15REGL P", "16SITK P", "", "16…
#> $ vh14              <chr> "", "16GENR P", "", "", "", "16MOA1 P", "", "15REGL P", "", "16SITK P",…
#> $ vh15              <chr> "", "15REGL P", "", "", "", "15SPEL P", "", "14GENR A", "", "16PRIM P",…
#> $ vh16              <chr> "", "14GENR P", "", "", "", "14GENR A", "", "14PRIM P", "", "15REGL P",…
#> $ party_name        <chr> "Alaska Republican Party", "Undeclared", "Undeclared", "Nonpartisan (no…
#> $ dupe_flag         <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, F…
#> $ year              <chr> "2019", "2003", "2018", "1982", "2002", "1995", "2000", "1980", "2019",…
#> $ state             <chr> "Alaska", "Alaska", "Alaska", "Alaska", "Alaska", "Alaska", "Alaska", "…
#> $ zip               <chr> "99654", "99901", "99557", NA, "99709", "99501", "99709", "99835", "995…
```

1.  There are 604,108 records in the database.
2.  There are 0 duplicate records in the database.
3.  The range and distribution of `year` seem reasonable.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("ak", "voters", "data", "clean"))
clean_path <- path(clean_dir, "ak_voters_clean.csv")
write_csv(akv, clean_path, na = "")
(clean_size <- file_size(clean_path))
#> 142M
file_encoding(clean_path) %>% 
  mutate(across(path, path.abbrev))
#> # A tibble: 1 × 3
#>   path                                       mime     charset 
#>   <fs::path>                                 <chr>    <chr>   
#> 1 ~/ak/voters/data/clean/ak_voters_clean.csv text/csv us-ascii
```

## Dictionary

The following table describes the variables in our final exported file:

| Column              | Type        | Definition                        |
|:--------------------|:------------|:----------------------------------|
| `un`                | `character` | undeliverable                     |
| `party`             | `character` | party                             |
| `dp`                | `character` | district precinct                 |
| `last_name`         | `character` | last name                         |
| `first_name`        | `character` | first name                        |
| `middle_name`       | `character` | middle name/init                  |
| `suffix_name`       | `character` | suffix                            |
| `ascension`         | `integer`   | random ID                         |
| `reg_date`          | `character` | Most recent registration date     |
| `org_reg_date`      | `character` | Original registration date        |
| `dist_date`         | `character` | date voter registered in district |
| `residence_address` | `character` | residence address                 |
| `residence_city`    | `character` | residence city                    |
| `residence_zip`     | `integer`   | residence zip                     |
| `mailing_address1`  | `character` | mailing address1                  |
| `mailing_address2`  | `character` | mailing address2                  |
| `mailing_address3`  | `character` | mailing address3                  |
| `mailing_city`      | `character` | mailing city                      |
| `mailing_state`     | `character` | mailing state                     |
| `mailing_zip`       | `character` | mailing ZIP code                  |
| `mailing_country`   | `character` | mailing country if outside U.S.   |
| `gender`            | `character` | gender                            |
| `vh1`               | `character` | voting history                    |
| `vh2`               | `character` | voting history                    |
| `vh3`               | `character` | voting history                    |
| `vh4`               | `character` | voting history                    |
| `vh5`               | `character` | voting history                    |
| `vh6`               | `character` | voting history                    |
| `vh7`               | `character` | voting history                    |
| `vh8`               | `character` | voting history                    |
| `vh9`               | `character` | voting history                    |
| `vh10`              | `character` | voting history                    |
| `vh11`              | `character` | voting history                    |
| `vh12`              | `character` | voting history                    |
| `vh13`              | `character` | voting history                    |
| `vh14`              | `character` | voting history                    |
| `vh15`              | `character` | voting history                    |
| `vh16`              | `character` | voting history                    |
| `party_name`        | `character` | party name                        |
| `dupe_flag`         | `logical`   | duplicate flag                    |
| `year`              | `character` | Original registration year        |
| `state`             | `character` | Residential state                 |
| `zip`               | `character` | 5-digit residential ZIP code      |
