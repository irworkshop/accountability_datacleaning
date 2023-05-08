Missouri Voters
================
Janelle O'Dea
2023-05-04

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Read](#read)
  - [Old](#old)
  - [Explore](#explore)
      - [Missing](#missing)
      - [Duplicates](#duplicates)
      - [Categorical](#categorical)
      - [Dates](#dates)
  - [Wrangle](#wrangle)
      - [Address](#address)
      - [ZIP](#zip)
      - [State](#state)
      - [City](#city)
  - [Conclude](#conclude)
  - [Export](#export)
  - [Upload](#upload)

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

To install packages, use: pip install -r requirements.txt

```

## Data

Missouri Centralized Voter Registration (MCVR) data was obtained as an
open record pursuant to Section 115.157, RSMo. from the Elections
Division, Office of Secretary of State.

The MCVR data was provided as a ZIP archive through a file sharing site.

``` r
raw_dir <- dir_create(here("mo", "voters", "data", "raw"))
raw_zip <- path(raw_dir, "Files.zip")
raw_out <- as_fs_path(unzip(raw_zip, exdir = raw_dir))
```

The archive contains a README file to explain the data:

> State law requires that certain statewide voter registration data be
> made available to the public. To avoid requiring that recipients of
> this data have specific software, the data is provided in
> tab-delimited text format. Tab-delimited data is readily importable to
> applications that provide data manipulation capabilities (such as
> database software). Due to the size of the file a simple text editor
> such as Notepad may not be able to open the file.

The README also contains a disclaimer:

> This file contains voter registration information inputted by the
> local election authorities in the state of Missouri. While the
> Missouri Secretary of State’s office makes all reasonable efforts to
> ensure the accuracy of information contained in this file, it is
> dependent on information provided by local election authorities.

And a record layout describing the columns of the file:


| Name                   | Description                                                                |
| :--------------------- | :------------------------------------------------------------------------- |
| `County`               | Local Jurisdiction Name                                                    |
| `Voter ID`             | Identification Number                                                      |
| `First Name`           | First Name                                                                 |
| `Middle Name`          | Middle Name                                                                |
| `Last Name`            | Last Name                                                                  |
| `Suffix`               | Name Suffix (e.g. Jr. III, etc.)                                           |
| `House Number`         | Residence Address House Number                                             |
| `House Suffix`         | Residence Address House Number Suffix (e.g. 1/2, A, etc.)                  |
| `Pre Direction`        | Residence Address Street Direction (e.g. the “E” in E Main St)             |
| `Street Name`          | Residence Address Street                                                   |
| `Street Type`          | Residence Address Type of Street (e.g. Ave, Blvd, etc.)                    |
| `Post Direction`       | Residence Address Street Post Dir. (e.g. the “NE” in Main St NE)           |
| `Unit Type`            | Residence Address Type of Unit (e.g. Apt, Suite, Lot, etc.)                |
| `Unit Number`          | Residence Address Unit Number (e.g. the “6” in Apt 6)                      |
| `Non Standard Address` | Used if Residence Address is not regular format (e.g. Rural Route)         |
| `Residential City`     | Residence Address City                                                     |
| `Residential State`    | Residential Address State                                                  |
| `Residential ZipCode`  | Residence Address Zip Code                                                 |
| `Mailing Address`      | Mailing Address (P.O. Box, etc.)                                           |
| `Mailing City`         | Mailing City                                                               |
| `Mailing State`        | Mailing State                                                              |
| `Mailing ZipCode`      | Mailing ZipCode                                                            |
| `Birthdate`            | Birthdate                                                                  |
| `Registration Date`    | Date Voter Registered in the Current County                                |
| `Precinct`             | Precinct Identifier                                                        |
| `Precinct Name`        | Full Name of the Precinct                                                  |
| `Split`                | Split code (the specific combination of districts that include this voter) |
| `Township`             | Township                                                                   |
| `Ward`                 | Ward                                                                       |
| `Congressional - New`  | Congressional District Code after 2011 Redistricting                       |
| `Legislative - New`    | State House District Code after 2011 Redistricting                         |
| `State Senate - New`   | State Senate District Code after 2011 Redistricting                        |
| `Status`               | Voter Status                                                               |
| `Voter History 1`      | Voter History (most recently voted-in Election Date and Election Name)     |
| `Voter History 2`      | Voter History (next most recent Election Date and Election Name)           |
| `Voter History 3`      | Voter History (Election Date and Election Name)                            |
| `Voter History 4`      | Voter History (Election Date and Election Name)                            |
| `Voter History 5`      | Voter History (Election Date and Election Name)                            |
| `Voter History 6`      | Voter History (Election Date and Election Name)                            |
| `Voter History 7`      | Voter History (Election Date and Election Name)                            |
| `Voter History 8`      | Voter History (Election Date and Election Name)                            |
| `Voter History 9`      | Voter History (Election Date and Election Name)                            |
| `Voter History 10`     | Voter History (Election Date and Election Name)                            |
| `Voter History 11`     | Voter History (Election Date and Election Name)                            |
| `Voter History 12`     | Voter History (Election Date and Election Name)                            |
| `Voter History 13`     | Voter History (Election Date and Election Name)                            |
| `Voter History 14`     | Voter History (Election Date and Election Name)                            |
| `Voter History 15`     | Voter History (Election Date and Election Name)                            |
| `Voter History 16`     | Voter History (Election Date and Election Name)                            |
| `Voter History 17`     | Voter History (Election Date and Election Name)                            |
| `Voter History 18`     | Voter History (Election Date and Election Name)                            |
| `Voter History 19`     | Voter History (Election Date and Election Name)                            |
| `Voter History 20`     | Voter History (Election Date and Election Name)                            |

## Read

We can read the tab-delimited file as a dataframe.

```

There are 20 columns at the end of the dataframe containing all of the
past elections in which each person has voted. We are going to keep the
most recent election and then save all the columns as a separate data
frame. This data frame will be kept in a *long* format, with a row for
every election.

``` r
hist_file <- path(dirname(raw_dir), "vote_history.csv")
if (file_exists(hist_file)) {
  vote_hist <- vroom(
    file = hist_file,
    col_types = cols(
      voter_id = col_character(),
      order = col_integer(),
      date = col_date(),
      election = col_character()
    )
  )
} else {
  vote_hist <- select(mov, `Voter ID`, starts_with("Voter History"))
  vote_hist <- pivot_longer(
    data = vote_hist,
    cols = starts_with("Voter History"),
    names_to = "order",
    values_to = "election"
  )
  vote_hist <- vote_hist %>% 
    clean_names("snake") %>% 
    filter(!is.na(election))
  vote_hist <- separate(
    data = vote_hist,
    col = election,
    sep = "(?<=\\d)\\s",
    into = c("date", "election")
  )
  vote_hist <- mutate(
    .data = vote_hist,
    order = as.integer(str_extract(order, "\\d+")),
    date = parse_date(date, "%m/%d/%Y")
  )
  write_csv(
    x = vote_hist,
    path = hist_file
  )
}
```

We can then remove the election columns.

## Old

In 2020, the TAP team received a similar file. We are going to keep any
registered voters not found in the current MCVR file.

Most of the voters in the 2020 data are in the 2023 data. There were 706,371 voters in the 2020 data not in the current MCVR file. 

``` r
prop_in(moo$voter_id, mov$voter_id)
#> [1] 0.9233826
prop_in(mov$voter_id, moo$voter_id)
#> [1] 0.9068094
```

Using the unique `voter_id` we will remove any voter found in the newer
data.

``` r
nrow(moo)
#> [1] 4210231
moo <- filter(moo, voter_id %out% mov$voter_id)
nrow(moo)
#> [1] 322577
```

The unique old data can then be joined to the most recent voter
registrations.

``` r
mov <- bind_rows(mov, moo, .id = "source")
mov <- relocate(mov, source, .after = last_col())
add_prop(count(mov, source))
#> # A tibble: 2 x 3
#>   source       n      p
#>   <chr>    <int>  <dbl>
#> 1 1      4287158 0.930 
#> 2 2       322577 0.0700
```

## Explore

There are 4,609,735 rows of 31 columns.

``` r
glimpse(mov)
#> Rows: 4,609,735
#> Columns: 31
#> $ county               <chr> "Adair", "Adair", "Adair", "Adair", "Adair", "Adair", "Adair", "Ada…
#> $ voter_id             <chr> "751417626", "460039164", "23351760", "750155978", "23351765", "750…
#> $ first_name           <chr> "CHRISTIAN", "MIRANDA", "DIANA", "TRACY", "ROBIN", "LEONNA", "ROGER…
#> $ middle_name          <chr> "MESHACK", "KAY", "L", "LYNN", "M", "R", "L", "BETH", "AVERY", "MAR…
#> $ last_name            <chr> "HATALA", "ABERNATHY", "REYNOLDS", "REYNOLDS", "SACK", "ALTER", "CA…
#> $ suffix               <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ house_number         <chr> "906", "304", "24183", "24183", "24294", "1512", "1512", "9", "9", …
#> $ house_suffix         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ pre_direction        <chr> "E", "E", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "S", NA, …
#> $ street_name          <chr> "WASHINGTON", "BURTON", "STATE HWY 3", "STATE HWY 3", "STATE HWY V"…
#> $ street_type          <chr> "ST", "ST", NA, NA, NA, "DR", "DR", NA, NA, NA, NA, NA, "TRL", "DR"…
#> $ post_direction       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ unit_type            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ unit_number          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ non_standard_address <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ city                 <chr> "KIRKSVILLE", "KIRKSVILLE", "KIRKSVILLE", "KIRKSVILLE", "BRASHEAR",…
#> $ state                <chr> "MO", "MO", "MO", "MO", "MO", "MO", "MO", "MO", "MO", "MO", "MO", "…
#> $ zip                  <chr> "63501", "63501", "63501", "63501", "63533", "63501", "63501", "635…
#> $ birth_date           <date> 1996-08-28, 1985-11-24, 1946-10-13, 1976-12-16, 1955-03-09, 1958-0…
#> $ reg_date             <date> 2015-12-14, 2006-03-08, 1980-04-21, 2007-07-10, 1990-10-15, 2010-0…
#> $ precinct             <chr> "104", "105", "108", "108", "809", "102", "102", "102", "102", "102…
#> $ precinct_name        <chr> "NORTHEAST FOUR/BENTON", "NORTHEAST FIVE/BENTON", "RURAL BENTON/BEN…
#> $ split                <chr> "01", "01", "04", "04", "01", "01", "01", "01", "01", "01", "01", "…
#> $ township             <chr> "BENTON TOWNSHIP", "BENTON TOWNSHIP", "BENTON TOWNSHIP", "BENTON TO…
#> $ ward                 <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ congressional        <chr> "CN-N 6", "CN-N 6", "CN-N 6", "CN-N 6", "CN-N 6", "CN-N 6", "CN-N 6…
#> $ legislative          <chr> "LE-N 003", "LE-N 003", "LE-N 004", "LE-N 004", "LE-N 004", "LE-N 0…
#> $ state_senate         <chr> "SE-N 18", "SE-N 18", "SE-N 18", "SE-N 18", "SE-N 18", "SE-N 18", "…
#> $ voter_status         <chr> "Active", "Active", "Active", "Inactive", "Active", "Active", "Acti…
#> $ last_election        <chr> "08/04/2020 Primary", "11/06/2018 General", "08/04/2020 Primary", "…
#> $ source               <chr> "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1…
tail(mov)
#> # A tibble: 6 x 31
#>   county voter_id first_name middle_name last_name suffix house_number house_suffix pre_direction
#>   <chr>  <chr>    <chr>      <chr>       <chr>     <chr>  <chr>        <chr>        <chr>        
#> 1 Wright 37309118 BERNICE    <NA>        GASPERSON <NA>   8655         <NA>         <NA>         
#> 2 Wright 7500444… STEVEN     P           RUTZ      <NA>   1503         <NA>         N            
#> 3 Wright 37312915 NOAH       <NA>        HANCOCK   <NA>   475          <NA>         W            
#> 4 Wright 49598325 DALE       <NA>        HINTT     <NA>   11270        <NA>         <NA>         
#> 5 Wright 7506473… ROXANNE    MARY        COLLINS   <NA>   6530         <NA>         <NA>         
#> 6 Wright 37311115 BUEL       L           JEMES     <NA>   9672         <NA>         <NA>         
#> # … with 22 more variables: street_name <chr>, street_type <chr>, post_direction <chr>,
#> #   unit_type <chr>, unit_number <chr>, non_standard_address <chr>, city <chr>, state <chr>,
#> #   zip <chr>, birth_date <date>, reg_date <date>, precinct <chr>, precinct_name <chr>,
#> #   split <chr>, township <chr>, ward <chr>, congressional <chr>, legislative <chr>,
#> #   state_senate <chr>, voter_status <chr>, last_election <chr>, source <chr>
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(mov, count_na)
#> # A tibble: 31 x 4
#>    col                  class        n          p
#>    <chr>                <chr>    <int>      <dbl>
#>  1 county               <chr>        0 0         
#>  2 voter_id             <chr>        0 0         
#>  3 first_name           <chr>       43 0.00000933
#>  4 middle_name          <chr>   423492 0.0919    
#>  5 last_name            <chr>        8 0.00000174
#>  6 suffix               <chr>  4440694 0.963     
#>  7 house_number         <chr>    72852 0.0158    
#>  8 house_suffix         <chr>  4595759 0.997     
#>  9 pre_direction        <chr>  3222794 0.699     
#> 10 street_name          <chr>    72879 0.0158    
#> 11 street_type          <chr>   620541 0.135     
#> 12 post_direction       <chr>  4573435 0.992     
#> 13 unit_type            <chr>  4160252 0.902     
#> 14 unit_number          <chr>  4160266 0.902     
#> 15 non_standard_address <chr>  4535998 0.984     
#> 16 city                 <chr>      981 0.000213  
#> 17 state                <chr>     1001 0.000217  
#> 18 zip                  <chr>      974 0.000211  
#> 19 birth_date           <date>     623 0.000135  
#> 20 reg_date             <date>       0 0         
#> 21 precinct             <chr>      974 0.000211  
#> 22 precinct_name        <chr>   323494 0.0702    
#> 23 split                <chr>      974 0.000211  
#> 24 township             <chr>  1017415 0.221     
#> 25 ward                 <chr>  1894187 0.411     
#> 26 congressional        <chr>      608 0.000132  
#> 27 legislative          <chr>       43 0.00000933
#> 28 state_senate         <chr>       12 0.00000260
#> 29 voter_status         <chr>   322577 0.0700    
#> 30 last_election        <chr>  1069026 0.232     
#> 31 source               <chr>        0 0
```

### Duplicates

We can also flag any record completely duplicated across every column.

``` r
dupe_file <- here("mo", "voters", "dupes.csv")
if (!file_exists(dupe_file)) {
  file_create(dupe_file)
  write_lines("voter_id,dupe_flag", dupe_file)
  mos <- mov %>% 
    select(-voter_id) %>% 
    group_split(county)
  split_id <- split(mov$voter_id, mov$county)
  pb <- txtProgressBar(max = length(mos), style = 3)
  for (i in seq_along(mos)) {
    write_csv(
      path = dupe_file,
      append = TRUE,
      col_names = FALSE,
      x = tibble(
        voter_id = split_id[[i]],
        dupe_flag = or(
          e1 = duplicated(mos[[i]], fromLast = FALSE),
          e2 = duplicated(mos[[i]], fromLast = TRUE)
        )
      )
    )
    flush_memory(1)
    setTxtProgressBar(pb, i)
  }
  rm(mos)
}
```

``` r
dupes <- read_csv(
  file = dupe_file,
  col_types = cols(
    voter_id = col_character(),
    dupe_flag = col_logical()
  )
)
```

``` r
nrow(mov)
#> [1] 4609735
mov <- left_join(mov, dupes)
nrow(mov)
#> [1] 4609735
mov <- mutate(mov, dupe_flag = !is.na(dupe_flag))
sum(mov$dupe_flag)
#> [1] 71
```

We can see that, despite unique IDs, there are duplicate voters.

``` r
mov %>% 
  filter(dupe_flag) %>% 
  select(voter_id, first_name, last_name, birth_date, zip)
#> # A tibble: 71 x 5
#>    voter_id  first_name last_name birth_date zip  
#>    <chr>     <chr>      <chr>     <date>     <chr>
#>  1 750534633 TREISHA    STRINGER  1990-12-06 64759
#>  2 752044678 TREISHA    STRINGER  1990-12-06 64759
#>  3 752173868 ETINOSA    OMOROGBE  1998-10-21 65201
#>  4 752173869 ETINOSA    OMOROGBE  1998-10-21 65201
#>  5 752033376 TERI       TURNBULL  1961-01-11 65020
#>  6 752033377 TERI       TURNBULL  1961-01-11 65020
#>  7 752125335 JANESSA    STEWART   1999-10-10 64012
#>  8 752125334 JANESSA    STEWART   1999-10-10 64012
#>  9 752140371 NATHANIEL  SKOW      1977-11-03 64012
#> 10 752140368 NATHANIEL  SKOW      1977-11-03 64012
#> # … with 61 more rows
```

### Categorical

``` r
col_stats(mov, n_distinct)
#> # A tibble: 32 x 4
#>    col                  class        n           p
#>    <chr>                <chr>    <int>       <dbl>
#>  1 county               <chr>      116 0.0000252  
#>  2 voter_id             <chr>  4609734 1.00       
#>  3 first_name           <chr>   144695 0.0314     
#>  4 middle_name          <chr>   129055 0.0280     
#>  5 last_name            <chr>   234791 0.0509     
#>  6 suffix               <chr>     1115 0.000242   
#>  7 house_number         <chr>    42079 0.00913    
#>  8 house_suffix         <chr>      139 0.0000302  
#>  9 pre_direction        <chr>        9 0.00000195 
#> 10 street_name          <chr>    55911 0.0121     
#> 11 street_type          <chr>      119 0.0000258  
#> 12 post_direction       <chr>       11 0.00000239 
#> 13 unit_type            <chr>       32 0.00000694 
#> 14 unit_number          <chr>    17253 0.00374    
#> 15 non_standard_address <chr>    49794 0.0108     
#> 16 city                 <chr>     1527 0.000331   
#> 17 state                <chr>       35 0.00000759 
#> 18 zip                  <chr>    78026 0.0169     
#> 19 birth_date           <date>   32205 0.00699    
#> 20 reg_date             <date>   24318 0.00528    
#> 21 precinct             <chr>     1600 0.000347   
#> 22 precinct_name        <chr>     2758 0.000598   
#> 23 split                <chr>     1860 0.000403   
#> 24 township             <chr>     1508 0.000327   
#> 25 ward                 <chr>     1235 0.000268   
#> 26 congressional        <chr>       24 0.00000521 
#> 27 legislative          <chr>      169 0.0000367  
#> 28 state_senate         <chr>       48 0.0000104  
#> 29 voter_status         <chr>        4 0.000000868
#> 30 last_election        <chr>      551 0.000120   
#> 31 source               <chr>        2 0.000000434
#> 32 dupe_flag            <lgl>        2 0.000000434
```

![](../plots/distinct_plots-1.png)<!-- -->![](../plots/distinct_plots-2.png)<!-- -->

### Dates

We can add the calendar year from `date` with `lubridate::year()`

``` r
mov <- mutate(mov, reg_year = year(reg_date))
```

``` r
min(mov$reg_date)
#> [1] "101-07-16"
mean(mov$reg_year < 2000)
#> [1] 0.2916372
max(mov$reg_date)
#> [1] "2020-10-05"
sum(mov$reg_date > today())
#> [1] 0
```

![](../plots/bar_year-1.png)<!-- -->

## Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are tailor made to facilitate this process.

### Address

We can create a single, unified normalized address field.

``` r
mov <- mov %>% 
  unite(
    col = address_norm,
    house_number:non_standard_address,
    sep = " ",
    na.rm = TRUE,
    remove = FALSE
  ) %>% 
  relocate(address_norm, .after = last_col())
```

``` r
mov %>% 
  select(address_norm, house_number:non_standard_address) %>% 
  sample_n(20) %>% 
  remove_empty("cols")
#> # A tibble: 20 x 8
#>    address_norm house_number pre_direction street_name street_type unit_type unit_number
#>    <chr>        <chr>        <chr>         <chr>       <chr>       <chr>     <chr>      
#>  1 3160 ROCK Q… <NA>         <NA>          <NA>        <NA>        <NA>      <NA>       
#>  2 5414 VILLAG… 5414         <NA>          VILLAGE CO… LN          <NA>      <NA>       
#>  3 3962 HIGHWA… 3962         <NA>          HIGHWAY JJ  <NA>        <NA>      <NA>       
#>  4 4105 DERBY … 4105         <NA>          DERBY RIDGE DR          <NA>      <NA>       
#>  5 3582 LAKEVI… 3582         <NA>          LAKEVIEW H… DR          <NA>      <NA>       
#>  6 625 CHELSEA… 625          <NA>          CHELSEA     AVE         <NA>      <NA>       
#>  7 901 E PEAR … 901          E             PEAR        AVE         <NA>      <NA>       
#>  8 1901 CAIRO … 1901         <NA>          CAIRO       DR          <NA>      <NA>       
#>  9 9231 OLD BO… 9231         <NA>          OLD BONHOM… RD          <NA>      <NA>       
#> 10 704 HEDGEWO… 704          <NA>          HEDGEWOOD   CT          <NA>      <NA>       
#> 11 2407 S OVER… 2407         S             OVERTON     AVE         <NA>      <NA>       
#> 12 904 MASON ST 904          <NA>          MASON       ST          <NA>      <NA>       
#> 13 2404 E MECH… 2404         E             MECHANIC    ST          APT       31         
#> 14 5919 PAMPLI… 5919         <NA>          PAMPLIN     PL          <NA>      <NA>       
#> 15 2334 SW RIV… 2334         SW            RIVER TRAIL RD          <NA>      <NA>       
#> 16 13720 MASON… 13720        <NA>          MASON GREEN CT          <NA>      <NA>       
#> 17 519 TIMBER … 519          <NA>          TIMBER      DR          APT       B          
#> 18 1407 HIGHWA… 1407         <NA>          HIGHWAY 19  <NA>        <NA>      <NA>       
#> 19 3510 BROWNI… 3510         <NA>          BROWNING    AVE         <NA>      <NA>       
#> 20 16037 E 828… 16037        E             828         RD          <NA>      <NA>       
#> # … with 1 more variable: non_standard_address <chr>
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
mov <- mov %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  mov$zip,
  mov$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 x 6
#>   stage    prop_in n_distinct  prop_na  n_out n_diff
#>   <chr>      <dbl>      <dbl>    <dbl>  <dbl>  <dbl>
#> 1 zip        0.927      78026 0.000211 334286  76967
#> 2 zip_norm   1.00        1063 0.000348    504      4
```

### State

As we would expect, all the Missouri voters live in Missouri.

``` r
count(mov, state, sort = TRUE)
#> # A tibble: 35 x 2
#>    state             n
#>    <chr>         <int>
#>  1 MO          4608112
#>  2 <NA>           1001
#>  3 DONIPHAN        304
#>  4 NAYLOR          141
#>  5 FAIRDEALING      41
#>  6 KAHOKA           34
#>  7 GATEWOOD         18
#>  8 ALEXANDRIA       14
#>  9 OXLY             14
#> 10 REVERE           13
#> # … with 25 more rows
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
mov <- mov %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("MO", "DC", "MISSOURI"),
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

#### Progress

Our goal for normalization was to increase the proportion of city values
known to be valid and reduce the total distinct values by correcting
misspellings.

| stage      | prop\_in | n\_distinct | prop\_na |  n\_out | n\_diff |
| :--------- | -------: | ----------: | -------: | ------: | ------: |
| city)      |    0.777 |        1527 |        0 | 1026936 |     583 |
| city\_norm |    0.996 |        1024 |        0 |   19571 |      64 |

## Conclude

Before exporting, we can remove the intermediary normalization columns
and rename all added variables with the `_clean` suffix.

``` r
mov <- rename_all(mov, ~str_replace(., "_norm", "_clean"))
```

``` r
glimpse(sample_n(mov, 50))
#> Rows: 50
#> Columns: 36
#> $ county               <chr> "Boone", "Jefferson", "Boone", "Pettis", "Gentry", "St. Louis City"…
#> $ voter_id             <chr> "1094876", "13134337", "4628917", "15544030", "750441438", "7513581…
#> $ first_name           <chr> "ROBERT", "KACI", "JOHNNY", "JULIE", "CINDY", "TAYLOR", "RACHEAL", …
#> $ middle_name          <chr> "LEE", "JEAN", NA, "A", "S", "ANISE", "LEAH", "S", "JOE", NA, "P", …
#> $ last_name            <chr> "YOUNG", "DIXON", "WILLIAMS", "WASSON", "COCHRAN", "BAKER", "BEASLE…
#> $ suffix               <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "JR", NA, NA, NA, NA, "…
#> $ house_number         <chr> "1109", "1824", NA, "1205", "307", "3032", "1717", "5039", "1026", …
#> $ house_suffix         <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ pre_direction        <chr> NA, NA, NA, NA, NA, NA, "E", NA, NA, "W", NA, NA, "S", NA, "E", NA,…
#> $ street_name          <chr> "ELSDON", "WEST", NA, "ELM HILLS", "3 RD.ST", "W NORWOOD", "PRIMROS…
#> $ street_type          <chr> "DR", "DR", NA, "BLVD", NA, "DR", "ST", "AVE", "DR", "ST", "ST", "P…
#> $ post_direction       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ unit_type            <chr> NA, NA, NA, NA, NA, NA, "APT", NA, NA, NA, NA, "APT", NA, NA, NA, N…
#> $ unit_number          <chr> NA, NA, NA, NA, NA, NA, "F-109", NA, NA, NA, NA, "A", NA, NA, NA, N…
#> $ non_standard_address <chr> NA, NA, "901 WILKES BLVD", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ city                 <chr> "COLUMBIA", "HIGH RIDGE", "COLUMBIA", "SEDALIA", "KING CITY", "ST L…
#> $ state                <chr> "MO", "MO", "MO", "MO", "MO", "MO", "MO", "MO", "MO", "MO", "MO", "…
#> $ zip                  <chr> "65203-0", "63049", "65201-0", "65301", "64463", "63115", "65804", …
#> $ birth_date           <date> 1961-05-17, 1975-06-29, 1957-05-31, 1968-12-27, 1962-05-25, 1997-0…
#> $ reg_date             <date> 2017-07-15, 2004-09-01, 2007-03-27, 2000-07-17, 2008-10-08, 2015-0…
#> $ precinct             <chr> "5I", "71.A", "1A", "47", "9", "01", "411", "01", "5B", "03", "14",…
#> $ precinct_name        <chr> "5I", "71.A Brennan", "1A", "SEDALIA WEST", "JACKSON EAST", "WARD 0…
#> $ split                <chr> "5I1", "01", "1A3", "03", "01", "02", "01", "03", "01", "01", "06",…
#> $ township             <chr> "MISSOURI", "Rock Township", "MISSOURI", "SEDALIA WEST", "JACKSON T…
#> $ ward                 <chr> "WD 05", NA, "WD 01", NA, "KCEW", "0001", "ZN 4", "0001", "WD 05", …
#> $ congressional        <chr> "CN-N 4", "CN-N 2", "CN-N 4", "CN-N 4", "CN-N 6", "CN-N 1", "CN-N 7…
#> $ legislative          <chr> "LE-N 046", "LE-N 097", "LE-N 045", "LE-N 052", "LE-N 002", "LE-N 0…
#> $ state_senate         <chr> "SE-N 19", "SE-N 22", "SE-N 19", "SE-N 28", "SE-N 12", "SE-N 04", "…
#> $ voter_status         <chr> "Active", "Active", "Inactive", "Active", "Active", "Active", "Inac…
#> $ last_election        <chr> NA, "11/06/2018 General", NA, "08/04/2020 Primary", "08/04/2020 Pri…
#> $ source               <chr> "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1…
#> $ dupe_flag            <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ reg_year             <dbl> 2017, 2004, 2007, 2000, 2008, 2015, 2016, 2016, 1986, 1999, 2014, 2…
#> $ address_clean        <chr> "1109 ELSDON DR", "1824 WEST DR", "901 WILKES BLVD", "1205 ELM HILL…
#> $ zip_clean            <chr> "65203", "63049", "65201", "65301", "64463", "63115", "65804", "631…
#> $ city_clean           <chr> "COLUMBIA", "HIGH RIDGE", "COLUMBIA", "SEDALIA", "KING CITY", "SAIN…
```

1.  There are 4,609,735 records in the database.
2.  There are 71 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 0 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("mo", "voters", "data", "clean"))
clean_path <- path(clean_dir, "mo_voters.csv")
write_csv(mov, clean_path, na = "")
(clean_size <- file_size(clean_path))
#> 1G
file_encoding(clean_path) %>% 
  mutate(across(path, path.abbrev))
#> # A tibble: 1 x 3
#>   path                                 mime            charset
#>   <chr>                                <chr>           <chr>  
#> 1 ~/mo/voters/data/clean/mo_voters.csv application/csv utf-8
```

## Upload

We can use the `aws.s3::put_object()` to upload the text file to the IRW
server.

``` r
aws_path <- path("csv", basename(clean_path))
if (!object_exists(aws_path, "publicaccountability")) {
  put_object(
    file = clean_path,
    object = aws_path, 
    bucket = "publicaccountability",
    acl = "public-read",
    show_progress = TRUE,
    multipart = TRUE
  )
}
aws_head <- head_object(aws_path, "publicaccountability")
(aws_size <- as_fs_bytes(attr(aws_head, "content-length")))
unname(aws_size == clean_size)
```
