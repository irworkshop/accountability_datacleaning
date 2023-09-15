Missouri Voters
================
Janelle O'Dea
2023-08-28

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

Results you see are from work done in a Jupyter Notebook. That notebook, mo-voters-2023.ipynb is in this repo.
The script version of this is also in the repo, called mo_voters_2023.py.

## File structure

File structure:

├── accountability_datacleaning
│   ├── state
│   │   ├── mo
            ├──contribs
            ├──expends
            ├──licenses
            ├──lobby
            ├──voters_2020
            ├──voters_2023
                ├──data
                mo-voters-2023.ipynb
                mo_voters_2023_README.md 
                    ├──Missouri
                       Missouri.zip
                        ├──data
                ├──reqs
                   requirements.txt
            ├──voters_old

## Packages

To install packages, use: pip install -r requirements.txt, in the reqs directory. 

```
import pandas as pd
from zipfile import ZipFile
import os
import math
import numpy as np
from slugify import slugify
import locale
locale.setlocale(locale.LC_ALL, '')

# for printing dfs
pd.options.display.max_rows = 100
# for printing lists
pd.options.display.max_seq_items = 50
```

## Data

Missouri Centralized Voter Registration (MCVR) data was obtained as an
open record pursuant to Section 115.157, RSMo. from the Elections
Division, Office of Secretary of State.

The MCVR data was provided as a ZIP archive through a file sharing site.

```
# Set relative filepaths
# Missouri voter data is obtained via public records request to the Elections Division, Office of Secretary of State
# More info about data source can be found in the README

__file__ = 'os.path.abspath('')'

script_dir = os.path.dirname(__file__)
rel_path = './data/Missouri'
abs_file_path = os.path.join(script_dir, rel_path)

# Get list of files from zipfile opened in next step

files = os.listdir(abs_file_path)

# Read the zipfile

voters = (files[1])
zf = ZipFile(abs_file_path + "/" + voters)

# List files in zipfile

zf.namelist()
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
# Load data into dataframe, first with no header for processing reasons
voters = pd.read_csv(zf.open('data\\PSR_VotersList_01032023_9-51-24 AM.txt'), sep='\t', header=None)

# Now set the first row as header
voters.columns = voters.iloc[0] 
```

There are 20 columns at the end of the dataframe containing all of the
past elections in which each person has voted. We are going to keep the
most recent election and then save all the columns as a separate data
frame. 

```
# There are 20 voter history columns. We'll keep the most recent and store the others in a different dataframe.
# Also get the names of column headers so we can use them to put the columns we need in another dataframe.

column_headers = list(voters.columns.values)
del_cols = column_headers[35:]
print(del_cols)

# Put old voter history 2-20 into a new, separate dataframe
voters2 = pd.DataFrame()
voters2 = pd.concat([voters2,voters[del_cols]],axis=0)
```

We then remove the extra election columns at the end.

```
# Drop voter history 2-20 from original dataframe

voters.drop(columns=['voter_history_2', 'voter_history_3', 'voter_history_4', 'voter_history_5', 'voter_history_6', 'voter_history_7', 'voter_history_8', 'voter_history_9', 'voter_history_10', 'voter_history_11', 'voter_history_12', 'voter_history_13', 'voter_history_14', 'voter_history_15', 'voter_history_16', 'voter_history_17', 'voter_history_18', 'voter_history_19', 'voter_history_20'], inplace=True)
```

## Old

In 2020, the TAP team received a similar file. We are going to keep any
registered voters not found in the current MCVR file.

Most of the voters in the 2020 data are in the 2023 data. 

```
# Comparing voter ID columns
# In 2020, the TAP team received a similar file. We are going to keep any
# registered voters not found in the current file.

idx1 = pd.Index(voters.voter_id)
idx2 = pd.Index(voters20.voter_id)

diff = idx2.difference(idx1).values


There are 706,371 voters in the 2020 data who are not in the current data.
```

We'll put the voters who were not found in the 2023 file but were in the 2020 file into their own dataframe.
We will need them later, when we want to join the old voter data to the most recent voter registrations.
We'll do that at the end.


```
# Convert diff array to list

diff = list(diff)

# Put those voters from 2020 data not in current data into a df; we'll need it later.

keepers = voters20[voters20['voter_id'].isin(diff)]

# To join the old unique 2020 voter data to the 2023 dataset, we'll use the following code

<code>

But we won't do that until we get the 2023 data cleaned up and in the same structure as the 2020 data.
If we try to join them now, the fieldnames do not match and it won't work.
```

## Explore

In the new 2023 file, as we got it, there are 4,268,187 records with 54 columns. Columns are described in the record layout under #Data. 

```
county  voter_id  first_name  middle_name last_name suffix  house_number  house_suffix  pre_direction street_name ... voter_history_11  voter_history_12  voter_history_13  voter_history_14  voter_history_15  voter_history_16  voter_history_17  voter_history_18  voter_history_19  voter_history_20
1 Adair 461017702 JOHN  WILLIAM MCNEILL NaN 1306  NaN NaN ROOK  ... NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
2 Adair 751833496 ALEXANDER DOUGLAS STONEBURNER KARST NaN 702 NaN S SHERIDAN  ... NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
3 Adair 751105687 KEVIN LEE WINDSPERGER NaN 17469 NaN NaN DAIRY ... NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
4 Adair 752025280 TAYLOR  ANN CLAYTON NaN 809 NaN S MULANIX ... NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
5 Adair 751367266 AUSTIN  BRADLEY MORSE NaN 1214  NaN S WABASH  ... NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
```

### Missing

Columns vary in their degree of missing values.

``` 
county                             0
voter_id                           0
first_name                        30
middle_name                   401624
last_name                        456
suffix                       4114617
house_number                   31179
house_suffix                 4256636
pre_direction                2963552
street_name                    31198
street_type                   531846
post_direction               4233141
unit_type                    3874393
unit_number                  3874425
non_standard_address         4235200
residential_city                   0
residential_state                 16
residential_zipcode                0
mailing_address              4035157
mailing_city                 4039026
mailing_state                4039175
mailing_zipcode              4039164
birthdate                          0
political_party              4084653
registration_date                  0
precinct                           0
precinct_name                      0
split                              0
township                      913574
ward                         1788722
congressional_district_20         19
legislative_district_20           56
senate_district_20                56
voter_status                       0
voter_history_1               598452
voter_history_2              1018238
voter_history_3              1315678
voter_history_4              1547307
voter_history_5              1742024
voter_history_6              1911056
voter_history_7              2059904
voter_history_8              2192849
voter_history_9              2313466
voter_history_10             2423630
voter_history_11             2525953
voter_history_12             2620435
voter_history_13             2708562
voter_history_14             2790824
voter_history_15             2868254
voter_history_16             2941071
voter_history_17             3010628
voter_history_18             3076092
voter_history_19             3138099
voter_history_20             3196461
```

### Duplicates

We can flag any record completely duplicated across every column. We can also flag across chosen columns.
Multiple tests are done to deterine there are no entirely duplicate rows in the dataframe. 
In the 2023 data, there do not appear to be any duplicates. 

```
all_dupe = voters[voters.duplicated()]
all_dupe.info

...]
Index: []

[0 rows x 54 columns]>

voterids = voters.duplicated(subset=["voter_id"])
print("Duplicate voter IDs:")

# Print voter ID records only if duplicate = True
if voterids[2] == True:
    print(voterids)

Duplicate voter IDs:

```

### Categorical

```                       Column  Unique Values
0                      county            116
1                    voter_id        4268187
2                  first_name         140907
3                 middle_name         133899
4                   last_name         229386
5                      suffix            985
6                house_number          67853
7                house_suffix            106
8               pre_direction              9
9                 street_name          55604
10                street_type            109
11             post_direction              9
12                  unit_type             32
13                unit_number          14843
14       non_standard_address          21251
15           residential_city            989
16          residential_state              2
17        residential_zipcode         101865
18            mailing_address         112175
19               mailing_city           3859
20              mailing_state             60
21            mailing_zipcode           7330
22                  birthdate            111
23            political_party              4
24          registration_date          23598
25                   precinct           1053
26              precinct_name           2793
27                      split           1612
28                   township           1131
29                       ward            962
30  congressional_district_20              8
31    legislative_district_20            163
32         senate_district_20             34
33               voter_status              2
34            voter_history_1            538
35            voter_history_2            581
36            voter_history_3            602
37            voter_history_4            615
38            voter_history_5            603
39            voter_history_6            620
40            voter_history_7            616
41            voter_history_8            625
42            voter_history_9            631
43           voter_history_10            631
44           voter_history_11            619
45           voter_history_12            631
46           voter_history_13            629
47           voter_history_14            632
48           voter_history_15            623
49           voter_history_16            622
50           voter_history_17            616
51           voter_history_18            615
52           voter_history_19            607
53           voter_history_20            605
```

### Dates

We can add the calendar year from `date` with `lubridate::year()`

There are voters — more than 1,000 of them — whose birth dates are 1800, 1895, 1899. There are more than 3,400 voters who are over 100 years old. Janelle has an inquiry in to the Missouri Secretary of State about this. We note it in the data description but leave them in the final output, here. 

Change the type of variabe to datetime. 

``` 
voters['registration_date'] = pd.to_datetime(voters['registration_date'], errors="coerce")
```


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
