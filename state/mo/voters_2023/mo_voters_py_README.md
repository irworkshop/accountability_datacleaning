Missouri Voters
================
Janelle O'Dea
10/12/2023

  - [Project](#project)
  - [Objectives](#objectives)
  - [Structure](#structure)
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

## Structure

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

We will derive the year from the registration date field. Change the type of variable to datetime, first. Some of the values come in as text, some as non-text.

```
voters['registration_date'] = pd.to_datetime(voters['registration_date'], errors="coerce")
unique = voters.nunique()
unique_df = pd.DataFrame({"Column": unique.index, "Unique Values": unique.values})
print(unique_df)`

voters['reg_year'] = voters['reg_date'].dt.year
```

There is also a birth date field, which we do keep, and there is a note about that field below.

A note about birth dates:

There are voters — more than 1,000 of them — whose birth dates are 1800, 1895, 1899. There are more than 3,400 voters who are over 100 years old. Janelle has an inquiry in to the Missouri Secretary of State about this and is investigating. We note it in the data description but leave them in the final output, here. 


## Wrangle

Perform some consistent string normalization on address variables.

### Address

We can create a single, unified normalized address field.

```
voters["address_norm"] = voters["house_number"].astype(str) +"-"+ voters["house_suffix"].astype(str) +"-"+ voters["pre_direction"].astype(str) +"-"+ voters["street_name"].astype(str) +"-"+ voters["street_type"].astype(str) +"-"+ voters["post_direction"].astype(str) +"-"+ voters["unit_type"].astype(str) +"-"+ voters["unit_number"].astype(str) +"-"+ voters["non_standard_address"].astype(str)
```

Replace and clean up nan values in the address_norm field.

```
voters["address_norm"] = voters["address_norm"].str.replace('nan-', '')
voters["address_norm"] = voters["address_norm"].str.replace('-nan', '')
voters["address_norm"] = voters["address_norm"].str.replace(' ', '-')
voters["address_norm"] = voters["address_norm"].str.replace('-', ' ')
```

First, fix inconsistent/misspellings/etc that may confuse code, in street type field
I can't believe this exact Py dict, that I created, doesn't already exist, but
I didn't find it anywhere, and found people on Stack asking how to do what I'm doing here

```
voters['street_type'].unique()

array(['DR', 'ST', 'WAY', nan, 'CT', 'AVE', 'LN', 'TRL', 'PL', 'RD',
       'PLZ', 'XXXXX', 'TER', 'CIRC', 'SQ', 'BLVD', 'TERR', 'EST', 'RDG',
       'CIR', 'LANE', 'VLG', 'CV', 'PKWY', 'RD.', 'LOOP', 'HWY', 'BND',
       'CR', 'RUN', 'ALY', 'DM', 'LK', 'HGTS', 'PT', 'SPGS', 'ST.', 'A',
       'HLS', 'PARK', 'VW', 'BR', 'GRV', 'VLY', 'HOLW', 'TRLS', 'APT',
       'PASS', 'COND', 'COR', 'TRCE', 'HILL', 'PK', 'JCT', 'BLF', 'XING',
       'AV', 'BYP', 'PATH', 'ESTS', 'TR', 'TRFY', 'MEWS', 'WAYE', 'GDNS',
       'SPUR', 'CRK', 'HL', 'HTS', 'S', 'LP', 'COVE', 'LNDG', 'RUE',
       'MNR', 'WALK', 'FLDS', 'EXPY', 'PSGE', 'WY', 'PKY', 'EXT', 'GLN',
       'FRK', 'BRK', 'CTR', 'TPKE', 'MDWS', 'TFWY', 'HVN', 'RD2', 'PLN',
       'MHP', 'ROW', 'ANX', 'STA', 'MDW', 'CMN', 'IS', 'CRST', 'CLB',
       'HBR', 'FRST', 'SHR', 'CORS', 'MTN', 'MWS', 'GTWY', 'RNCH', 'FLD'],
      dtype=object)

``` 

Translations are taken from here: https://pe.usps.com/text/pub28/28apc_002.htm. Any others needed are added (XXXXX = redacted). I put those into a Google Sheet, then saved it as a .csv. Then into a df here. Then map the values defined in the dict to the col in the df. Then make replacements.

```
usps_street_types = pd.read_csv('usps_street_types.csv')
mapping_dict = usps_street_types.set_index('abbr')['full'].to_dict()
voters['street_type'] = voters['street_type'].replace(mapping_dict)
```

CQ'd any that did not show up in USPS by Googling the address. Not sure about MHP, which in Missouri usually stands for Missouri Highway Patrol. Also not sure about ANEX.

```
voters['street_type'].unique()
array(['DRIVE', 'STREET', 'WAY', nan, 'COURT', 'AVENUE', 'LANE', 'TRAIL',
       'PLACE', 'ROAD', 'PLAZA', 'redacted', 'TERRACE', 'CIRCLE',
       'SQUARE', 'BOULEVARD', 'ESTATE', 'RIDGE', 'VILLAGE', 'COVE',
       'PARKWAY', 'LOOP', 'HIGHWAY', 'BEND', 'RUN', 'ALLEY', 'DAM',
       'LAKE', 'HEIGHTS', 'POINT', 'SPRINGS', 'A', 'HILLS', 'PARK',
       'VIEW', 'BRANCH', 'GROVE', 'VALLEY', 'HOLLOW', 'APT', 'PASS',
       'COND', 'CORNER', 'TRACE', 'HILL', 'JUNCTION', 'BLUFF', 'CROSSING',
       'BYPASS', 'PATH', 'ESTATES', 'TRAILS', 'TRAFFICWAY', 'MEWS',
       'WAYE', 'GARDENS', 'SPUR', 'CREEK', 'LANDING', 'RUE', 'MANOR',
       'WALK', 'FIELDS', 'EXPRESSWAY', 'PASSAGE', 'EXTENSION', 'GLEN',
       'FORK', 'BROOK', 'CENTER', 'TURNPIKE', 'MEADOWS', 'HAVEN',
       'ROAD #2', 'PLAIN', 'MHP', 'ROW', 'ANEX', 'STATION', 'COMMON',
       'ISLAND', 'CREST', 'CLUB', 'HARBOR', 'FOREST', 'SHORE', 'CORNERS',
       'MOUNTAIN', 'GATEWAY', 'RANCH', 'FIELD'], dtype=object)
```

### ZIP

Let's see what we're working with.

zip_code_lengths1 = voters['residential_zipcode'].str.len().value_counts()
print(zip_code_lengths1)

```
zip_code_lengths1 = voters['residential_zipcode'].str.len().value_counts()
print(zip_code_lengths1)

5.0     3808894
10.0     270265
7.0       57759
9.0         161
8.0          36
Name: residential_zipcode, dtype: int64
```

There are some 9-digit ZIPs in here; we clean those up to be just 5 digits

```
voters['zip_clean'] = voters['residential_zipcode'].str.slice(0, 5)
```

This is to be sure the 5-digit ZIPs that begin with leading 0s do have the leading 0s. Python strips them, and, when we export to .csv, they will not show up in Excel - so the ZIP 01234 would appear as 1234. However, if you open the file in a text editor, the 0s are there.

```
voters['zip_clean'] = voters['zip_clean'].str.zfill(5)
```

Just making sure that worked.

```
zip_code_lengths2 = voters['zip_clean'].str.len().value_counts()
print(zip_code_lengths2)

5.0    4137115
Name: zip_clean, dtype: int64
```

### State

As expected, all voters registered to vote live in the state of Missouri.

``` 
voters['residential_state'].unique()

array(['MO', 'XXXXX', nan], dtype=object)
```

### City

Cities are the most difficult to normalize bc of wide variety of cities/formats. The state of Missouri seems to have normalized them, though; there aren't any misspellings of any cities that I can see.
The only step left w/ addresses would be to standardize these fields/addresses against USPS records. There are several Python libraries that do this, but doing so is outside of the scope of work here, so we leave it.

``` 
voters['residential_city'].unique()

array(['KIRKSVILLE', 'BRASHEAR', 'GIBBS', 'LA PLATA', 'NOVINGER',
       'GREENTOP', 'GREENCASTLE', 'XXXXX', 'HURDLAND', 'NEW BOSTON',
       'COUNTRY CLUB', 'SAVANNAH', 'ST JOSEPH', 'COSBY', 'UNION STAR',
       'AMAZONIA', 'ROSENDALE', 'FILLMORE', 'CLARKSDALE', 'HELENA',
       'BOLCKOW', 'KING CITY', 'REA', 'BARNARD', 'GUILFORD', 'GRAHAM',
       'ROCK PORT', 'TARKIO', 'FAIRFAX', 'BURLINGTON JUNCTION',
       'WESTBORO', 'CRAIG', 'WATSON', 'ELMO', 'SKIDMORE', 'VANDALIA',
       'MEXICO', 'LADDONIA', 'BENTON CITY', 'CENTRALIA', 'THOMPSON',
       'FARBER', 'MARTINSBURG', 'RUSH HILL', 'MIDDLETOWN', 'WELLSVILLE',
       'AUXVASSE', 'STURGEON', 'CLARK', 'MADISON', 'MONETT', 'PURDY',
       'SHELL KNOB', 'CASSVILLE', 'WASHBURN', 'GOLDEN', 'EXETER',
       'SELIGMAN', 'CRANE', 'AURORA', 'BUTTERFIELD', 'EAGLE ROCK',
       'VERONA', 'WHEATON', 'PIERCE CITY', 'CAPE FAIR', 'FAIRVIEW',
       'GALENA', 'JENKINS', 'ROCKY COMFORT', 'LAMAR', 'MINDENMINES',
       'GOLDEN CITY', 'SHELDON', 'LIBERAL', 'ASBURY', 'JERICO SPRINGS',
       'JASPER', 'ORONOGO', 'BRONAUGH', 'IRWIN', 'IANTHA', 'LOCKWOOD',
       'ADRIAN', 'BUTLER', 'RICH HILL', 'AMSTERDAM', 'DREXEL', 'AMORET',
       'FOSTER', 'APPLETON CITY', 'HUME', 'ARCHIE', 'ROCKVILLE',
       'MONTROSE', 'URICH', 'WARSAW', 'QUINCY', 'LINCOLN', 'COLE CAMP',
       'EDWARDS', 'WINDSOR', 'CLINTON', 'OSCEOLA', 'STOVER', 'IONIA',
       'MORA', 'WHEATLAND', 'CROSS TIMBERS', 'CLIMAX SPRINGS', 'MARQUAND',
       'MARBLE HILL', 'PATTON', 'SEDGEWICKVILLE', 'GLENALLEN',
       'MILLERSVILLE', 'LEOPOLD', 'ZALMA', 'STURDIVANT', 'FREDERICKTOWN',
       'BROWNWOOD', 'ADVANCE', 'GRASSY', 'DAISY', 'PERRYVILLE', 'GIPSY',
       'FRIEDHEIM', 'PUXICO', 'WHITEWATER', 'MC GEE', 'ARAB', 'COLUMBIA',
       'HALLSVILLE', 'ASHLAND', 'HARTSBURG', 'HARRISBURG', 'ROCHEPORT',
       'EDGERTON', 'GOWER', 'DE KALB', 'AGENCY', 'EASTON', 'RUSHVILLE',
       'FAUCETT', 'DEARBORN', 'STEWARTSVILLE', 'POPLAR BLUFF',
       'WAPPAPELLO', 'QULIN', 'WILLIAMSVILLE', 'BROSELEY', 'HARVIELL',
       'FISK', 'NEELYVILLE', 'ELLSINORE', 'NAYLOR', 'ROMBAUER',
       'FAIRDEALING', 'BRAYMER', 'CAMERON', 'KIDDER', 'HAMILTON',
       'LATHROP', 'KINGSTON', 'BRECKENRIDGE', 'POLO', 'COWGILL', 'LAWSON',
       'TURNEY', 'TEBBETTS', 'FULTON', 'NEW BLOOMFIELD', 'HOLTS SUMMIT',
       'MOKANE', 'STEEDMAN', 'MONTGOMERY CITY', 'PORTLAND',
       'KINGDOM CITY', 'RHINELAND', 'WILLIAMSBURG', 'JEFFERSON CITY',
       'ROACH', 'CAMDENTON', 'OSAGE BEACH', 'LINN CREEK', 'LAKE OZARK',
       'SUNRISE BEACH', 'FOUR SEASONS', 'STOUTLAND', 'GRAVOIS MILLS',
       'MACKS CREEK', 'KAISER', 'MONTREAL', 'RICHLAND', 'LEBANON',
       'ELDRIDGE', 'BRUMLEY', 'TUNAS', 'CAPE GIRARDEAU', 'DELTA',
       'JACKSON', 'OAK RIDGE', 'ALTENBURG', 'BURFORDVILLE', 'CHAFFEE',
       'OLD APPLETON', 'POCAHONTAS', 'ORAN', 'SCOTT CITY', 'CARROLLTON',
       'HALE', 'NORBORNE', 'BOGARD', 'TINA', 'BOSWORTH', 'DE WITT',
       'DAWN', 'HARDIN', 'VAN BUREN', 'GRANDIN', 'FREMONT', 'DONIPHAN',
       'ELLINGTON', 'PIEDMONT', 'RAYMORE', 'HARRISONVILLE', 'BELTON',
       'GARDEN CITY', 'PLEASANT HILL', 'PECULIAR', 'CREIGHTON',
       'CLEVELAND', 'VILLAGE OF LOCH LLOYD', 'FREEMAN', 'GUNN CITY',
       'LEES SUMMIT', 'LAKE WINNEBAGO', 'EAST LYNNE', 'KINGSVILLE',
       'GREENWOOD', 'KANSAS CITY', 'STRASBURG', 'LAKE ANNETTE',
       'WEST LINE', 'LATOUR', 'HOLDEN', 'LONE JACK', 'EL DORADO SPRINGS',
       'HUMANSVILLE', 'STOCKTON', 'FAIR PLAY', 'DADEVILLE', 'DUNNEGAN',
       'ALDRICH', 'GLASGOW', 'BRUNSWICK', 'KEYTESVILLE', 'MARCELINE',
       'SALISBURY', 'NEW CAMBRIA', 'SUMNER', 'DALTON', 'TRIPLETT',
       'ROTHVILLE', 'MENDON', 'CLIFTON HILL', 'BROOKFIELD', 'OZARK',
       'ROGERSVILLE', 'NIXA', 'SPOKANE', 'HIGHLANDVILLE', 'CHESTNUTRIDGE',
       'SPARTA', 'BRUNER', 'BILLINGS', 'CLEVER', 'BRADLEYVILLE',
       'CHADWICK', 'REPUBLIC', 'BROOKLINE STATION', 'FORDLAND',
       'SADDLEBROOKE', 'OLDFIELD', 'GARRISON', 'FORSYTH', 'WALNUT SHADE',
       'PONCE DE LEON', 'REEDS SPRING', 'MARIONVILLE', 'TANEYVILLE',
       'KAHOKA', 'WILLIAMSTOWN', 'WAYLAND', 'CANTON', 'LURAY', 'REVERE',
       'ALEXANDRIA', 'WYACONDA', 'ARBELA', 'ST PATRICK', 'KEARNEY',
       'LIBERTY', 'HOLT', 'GLADSTONE', 'SMITHVILLE', 'EXCELSIOR SPRINGS',
       'NORTH KANSAS CITY', 'MISSOURI CITY', 'TRIMBLE', 'MOSBY', 'ORRICK',
       'PLATTSBURG', 'OSBORN', 'RUSSELLVILLE', 'HENLEY', 'EUGENE',
       'WARDSVILLE', 'LOHMAN', 'CENTERTOWN', 'ST THOMAS', 'META',
       'BOONVILLE', 'PILOT GROVE', 'BLACKWATER', 'WOOLDRIDGE',
       'OTTERVILLE', 'BUNCETON', 'PRAIRIE HOME', 'CALIFORNIA', 'SYRACUSE',
       'TIPTON', 'NELSON', 'CLARKSBURG', 'SMITHTON', 'SEDALIA',
       'JAMESTOWN', 'LEASBURG', 'CUBA', 'BOURBON', 'STEELVILLE',
       'SULLIVAN', 'CHERRYVILLE', 'OWENSVILLE', 'ST JAMES',
       'COOK STATION', 'DAVISVILLE', 'SALEM', 'VIBURNUM', 'WESCO',
       'EVERTON', 'GREENFIELD', 'WALNUT GROVE', 'SOUTH GREENFIELD',
       'ARCOLA', 'ASH GROVE', 'BUFFALO', 'URBANA', 'FAIR GROVE',
       'ELKLAND', 'LOUISBURG', 'LONG LANE', 'PHILLIPSBURG', 'CONWAY',
       'WINDYVILLE', 'PRESTON', 'JAMESPORT', 'GALLATIN', 'WINSTON',
       'PATTONSBURG', 'WEATHERBY', 'ALTAMONT', 'JAMESON', 'COFFEY',
       'CHILLICOTHE', 'GILMAN CITY', 'MC FALL', 'TRENTON', 'MAYSVILLE',
       'AMITY', 'LENOX', 'JADWIN', 'LICKING', 'BUNKER', 'BOSS', 'ROLLA',
       'EDGAR SPRINGS', 'LAKE SPRING', 'LECOMA', 'BIXBY', 'AVA',
       'MOUNTAIN GROVE', 'VANZANT', 'DORA', 'SQUIRES', 'DRURY',
       'WILLOW SPRINGS', 'WEST PLAINS', 'SEYMOUR', 'NORWOOD', 'WASOLA',
       'MANSFIELD', 'CABOOL', 'MACOMB', 'KENNETT', 'CLARKTON', 'CAMPBELL',
       'MALDEN', 'HOLCOMB', 'SENATH', 'CARDWELL', 'WHITEOAK', 'ARBYRD',
       'BERNIE', 'HORNERSVILLE', 'GIBSON', 'GOBLER', 'STEELE',
       'GRUBVILLE', 'ROBERTSVILLE', 'VILLA RIDGE', 'UNION', 'WASHINGTON',
       'NEW HAVEN', 'ST CLAIR', 'PACIFIC', 'GERALD', 'LABADIE',
       'ST ALBANS', 'CATAWISSA', 'LONEDELL', 'LESLIE', 'GRAY SUMMIT',
       'LUEBBERING', 'BEAUFORT', 'BERGER', 'ROSEBUD', 'CHESTERFIELD',
       'HERMANN', 'GASCONADE', 'BLAND', 'MORRISON', 'LINN', 'MT STERLING',
       'ALBANY', 'DARLINGTON', 'STANBERRY', 'GENTRY', 'NEW HAMPTON',
       'DENVER', 'RAVENWOOD', 'WORTH', 'PARNELL', 'MARTINSVILLE',
       'SPRINGFIELD', 'WILLARD', 'STRAFFORD', 'PLEASANT HOPE',
       'BOIS D ARC', 'BRIGHTON', 'MARSHFIELD', 'BROOKLINE', 'TURNERS',
       'BRIMSON', 'GALT', 'SPICKARD', 'LAREDO', 'CHULA', 'BETHANY',
       'EAGLEVILLE', 'CAINSVILLE', 'RIDGEWAY', 'HATFIELD', 'BLYTHEDALE',
       'GRANT CITY', 'MT MORIAH', 'DAVIS CITY', 'LAMONI', 'CHILHOWEE',
       'DEEPWATER', 'CALHOUN', 'BLAIRSTOWN', 'LEETON', 'FLEMINGTON',
       'WEAUBLEAU', 'HERMITAGE', 'PITTSBURG', 'POLK', 'NO CITY DATA',
       'HALF WAY', 'COLLINS', 'FOREST CITY', 'OREGON', 'MOUND CITY',
       'MAITLAND', 'FAYETTE', 'ARMSTRONG', 'FRANKLIN', 'NEW FRANKLIN',
       'HIGBEE', 'MOUNTAIN VIEW', 'POMONA', 'CAULFIELD', 'POTTERSVILLE',
       'PEACE VALLEY', 'MOODY', 'KOSHKONONG', 'BAKERSFIELD', 'ARCADIA',
       'IRONTON', 'VULCAN', 'ANNAPOLIS', 'DES ARC', 'BLACK',
       'MIDDLE BROOK', 'PILOT KNOB', 'BELLEVIEW', 'CALEDONIA', 'COURTOIS',
       'BISMARCK', 'LESTERVILLE', 'BLUE SPRINGS', 'INDEPENDENCE',
       'GRANDVIEW', 'GRAIN VALLEY', 'LAKE LOTAWANA', 'OAK GROVE',
       'BUCKNER', 'SUGAR CREEK', 'RAYTOWN', 'LAKE TAPAWINGO', 'SIBLEY',
       'UNITY VILLAGE', 'LEVASY', 'NAPOLEON', 'DUENWEG', 'WEBB CITY',
       'JOPLIN', 'CARL JUNCTION', 'CARTHAGE', 'ALBA', 'CARTERVILLE',
       'PURCELL', 'SARCOXIE', 'LA RUSSELL', 'REEDS', 'NECK CITY',
       'DIAMOND', 'WACO', 'AVILLA', 'ARNOLD', 'IMPERIAL', 'PEVELY',
       'HIGH RIDGE', 'EUREKA', 'FENTON', 'CEDAR HILL', 'HILLSBORO',
       'FESTUS', 'DE SOTO', 'DITTMER', 'CRYSTAL CITY', 'HERCULANEUM',
       'HOUSE SPRINGS', 'BARNHART', 'LABARQUE CREEK', 'FLETCHER',
       'BLOOMSDALE', 'VALLES MINES', 'KIMMSWICK', 'BYRNES MILL',
       'BONNE TERRE', 'SULPHUR SPRINGS', 'MORSE MILL', 'HEMATITE',
       'LIGUORI', 'MAPAVILLE', 'RICHWOODS', 'WARRENSBURG', 'CONCORDIA',
       'BATES CITY', 'HIGGINSVILLE', 'KNOB NOSTER', 'CENTERVIEW',
       'WHITEMAN AIR FORCE BASE', 'LA MONTE', 'ODESSA', 'SWEET SPRINGS',
       'MAYVIEW', 'GREEN RIDGE', 'EDINA', 'SHELBYVILLE', 'NEWARK',
       'KNOX CITY', 'NOVELTY', 'RUTLEDGE', 'BARING', 'LA BELLE',
       'LEONARD', 'GORIN', 'FALCON', 'LYNCHBURG', 'PLATO', 'GROVESPRING',
       'LAQUEY', 'LEXINGTON', 'WELLINGTON', 'ALMA', 'WAVERLY', 'CORDER',
       'BLACKBURN', 'DOVER', 'EMMA', 'CAMDEN', 'MOUNT VERNON', 'MILLER',
       'WENTWORTH', 'STOTTS CITY', 'FREISTATT', 'HALLTOWN', 'EWING',
       'LA GRANGE', 'LEWISTOWN', 'MONTICELLO', 'MAYWOOD', 'DURHAM',
       'BETHEL', 'TAYLOR', 'TROY', 'MOSCOW MILLS', 'FOLEY', 'FORISTELL',
       'OLD MONROE', 'WINFIELD', 'HAWK POINT', 'ELSBERRY', 'EOLIA',
       'SILEX', 'WRIGHT CITY', 'WARRENTON', 'WHITESIDE', 'TRUXTON',
       'BOWLING GREEN', 'BELLFLOWER', 'MEADVILLE', 'LACLEDE', 'BUCKLIN',
       'BROWNING', 'PURDIN', 'ST CATHERINE', 'LINNEUS', 'HUMPHREYS',
       'WINIGAN', 'WHEELING', 'MOORESVILLE', 'LUDLOW', 'UTICA', 'MACON',
       'BEVIER', 'ATLANTA', 'EXCELLO', 'CALLAO', 'ETHEL', 'ELMER',
       'ANABEL', 'JACKSONVILLE', 'CLARENCE', 'FARMINGTON', 'SILVA',
       'BELLE', 'VIENNA', 'DIXON', 'VICHY', 'ARGYLE', 'BRINKTOWN',
       'FREEBURG', 'HANNIBAL', 'PALMYRA', 'MONROE CITY', 'PHILADELPHIA',
       'HUNNEWELL', 'EMDEN', 'NOEL', 'PINEVILLE', 'STELLA', 'ANDERSON',
       'GOODMAN', 'SOUTH WEST CITY', 'SENECA', 'POWELL', 'JANE', 'NEOSHO',
       'LANAGAN', 'TIFF CITY', 'PRINCETON', 'HARRIS', 'MERCER', 'NEWTOWN',
       'POWERSVILLE', 'ELDON', 'IBERIA', 'ROCKY MOUNT', 'ULMAN',
       'TUSCUMBIA', 'ST ELIZABETH', 'OLEAN', 'CROCKER', 'BARNETT',
       'CHARLESTON', 'EAST PRAIRIE', 'WYATT', 'BERTRAND', 'SIKESTON',
       'ANNISTON', 'WILSON CITY', 'LATHAM', 'FORTUNA', 'VERSAILLES',
       'HIGH POINT', 'MC GIRK', 'PARIS', 'SANTA FE', 'SHELBINA',
       'MOBERLY', 'STOUTSVILLE', 'PERRY', 'HOLLIDAY', 'LENTNER',
       'JONESBURG', 'NEW FLORENCE', 'HIGH HILL', 'MCKITTRICK',
       'BIG SPRING', 'MINEOLA', 'AMERICUS', 'DANVILLE', 'BUELL', 'GAMMA',
       'LAURIE', 'FLORENCE', 'PORTAGEVILLE', 'LILBOURN', 'MATTHEWS',
       'MARSTON', 'GIDEON', 'NEW MADRID', 'CATRON', 'PARMA', 'RISCO',
       'MOREHOUSE', 'KEWANEE', 'TALLAPOOSA', 'HOWARDVILLE', 'CANALOU',
       'NORTH LILBOURN', 'WARDELL', 'CONRAN', 'GRANBY', 'STARK CITY',
       'LOMA LINDA', 'RACINE', 'SAGINAW', 'MARYVILLE', 'CONCEPTION',
       'CLYDE', 'CLEARMONT', 'CONCEPTION JUNCTION', 'PICKERING',
       'HOPKINS', 'SHERIDAN', 'THAYER', 'BIRCH TREE', 'ALTON', 'COUCH',
       'MYRTLE', 'GATEWOOD', 'WINONA', 'WESTPHALIA', 'CHAMOIS',
       'BONNOTS MILL', 'LOOSE CREEK', 'KOELTZTOWN', 'THORNFIELD',
       'TECUMSEH', 'UDALL', 'GAINESVILLE', 'NOBLE', 'THEODOSIA',
       'PONTIAC', 'ISABELLA', 'BRIXEY', 'ZANONI', 'PROTEM', 'HARDENVILLE',
       'SYCAMORE', 'ROCKBRIDGE', 'COOTER', 'HAYTI', 'CARUTHERSVILLE',
       'HOLLAND', 'BRAGG CITY', 'PASCOLA', 'BRAGGADOCIO', 'DEERING',
       'UNIONTOWN', 'FROHNA', 'ST MARY', 'BRAZEAU', 'FARRAR', 'MC BRIDE',
       'HOUSTONIA', 'HUGHESVILLE', 'MARSHALL', 'NEWBURG', 'JEROME',
       'BEULAH', 'DUKE', 'DEVILS ELBOW', 'LOUISIANA', 'NEW LONDON',
       'FRANKFORD', 'CLARKSVILLE', 'CURRYVILLE', 'NEW HARTFORD',
       'ASHBURN', 'ANNADA', 'PAYNESVILLE', 'WESTON', 'PARKVILLE',
       'RIVERSIDE', 'WEATHERBY LAKE', 'PLATTE CITY', 'NORTHMOOR',
       'LAKE WAUKOMIS', 'FERRELVIEW', 'HOUSTON LAKE', 'PLATTE WOODS',
       'CAMDEN POINT', 'FARLEY', 'WALDRON', 'BOLIVAR', 'MORRISVILLE',
       'GOODSON', 'WAYNESVILLE', 'ST ROBERT', 'FORT LEONARD WOOD',
       'UNIONVILLE', 'LIVONIA', 'LUCERNE', 'WORTHINGTON', 'COATSVILLE',
       'POLLOCK', 'CENTER', 'SAVERTON', 'HUNTSVILLE', 'CAIRO', 'RENICK',
       'RICHMOND', 'RAYVILLE', 'HENRIETTA', 'WOOD HEIGHTS', 'CENTERVILLE',
       'REDFORD', 'REYNOLDS', 'OXLY', 'SLATER', 'MIAMI', 'MALTA BEND',
       'GRAND PASS', 'ARROW ROCK', 'GILLIAM', 'QUEEN CITY', 'LANCASTER',
       'GLENWOOD', 'DOWNING', 'MEMPHIS', 'GRANGER', 'KELSO', 'BENTON',
       'PERKINS', 'VANDUSER', 'COMMERCE', 'MORLEY', 'BELL CITY',
       'BLODGETT', 'EMINENCE', 'SUMMERSVILLE', 'HARTSHORN',
       'STEFFENVILLE', 'ST PETERS', 'ST CHARLES', 'O FALLON',
       'WENTZVILLE', 'LAKE ST LOUIS', 'MARTHASVILLE', 'AUGUSTA',
       'DEFIANCE', 'PORTAGE DES SIOUX', 'WEST ALTON', 'NEW MELLE',
       'LOWRY CITY', 'SCHELL CITY', 'ROSCOE', 'HARWOOD', 'PARK HILLS',
       'FRENCH VILLAGE', 'DESLOGE', 'DOE RUN', 'LEADWOOD', 'IRONDALE',
       'LEADINGTON', 'BLACKWELL', 'CADET', 'ST LOUIS', 'FLORISSANT',
       'BALLWIN', 'MARYLAND HEIGHTS', 'ELLISVILLE', 'MANCHESTER',
       'ST ANN', 'BRIDGETON', 'WILDWOOD', 'HAZELWOOD', 'VALLEY PARK',
       'ALLENTON', 'STE GENEVIEVE', 'ESSEX', 'DEXTER', 'BLOOMFIELD',
       'GRAYRIDGE', 'DUDLEY', 'PAINTON', 'BRANSON WEST',
       'KIMBERLING CITY', 'LAMPE', 'BLUE EYE', 'BRANSON', 'HURLEY',
       'HOLLISTER', 'GREEN CITY', 'MILAN', 'KIRBYVILLE', 'CEDAR CREEK',
       'MERRIAM WOODS', 'RIDGEDALE', 'ROCKAWAY BEACH', 'KISSEE MILLS',
       'POWERSITE', 'POINT LOOKOUT', 'RUETER', 'CHESTNUT RIDGE',
       'RAYMONDVILLE', 'SUCCESS', 'HOUSTON', 'SOLO', 'ELK CREEK',
       'BUCYRUS', 'GRAFF', 'ROBY', 'HUGGINS', 'BENDAVIS', 'YUKON',
       'EUNICE', 'MAPLES', 'NEVADA', 'WALKER', 'MILO', 'DEERFIELD',
       'RICHARDS', 'MOUNDVILLE', 'METZ', 'TRUESDALE', 'LAKE SHERWOOD',
       'DUTZOW', 'INNSBROOK', 'POTOSI', 'MINERAL POINT', 'BELGRADE',
       'TIFF', 'PATTERSON', 'GREENVILLE', 'MILL SPRING', 'LODI', 'CLUBB',
       'LOWNDES', 'GLEN ALLEN', 'NIANGUA', 'HARTVILLE', 'ALLENDALE'],
      dtype=object)
```

```
How many unique cities are there? 989, which seems reasonable: There are roughly 1,000 muni governments, and several other types of smaller gov'ts in MO. (Taken from here https://www2.census.gov/govs/cog/gc0212mo.pdf)

print(len(voters['residential_city'].unique()))

989
```

## Conclude

Before exporting:

Rename specified fields in the df to match the prior TAP MO voter data file format so that we do not need to create a new dataset.

```
voters.rename(columns = {'address_norm':'address_clean', 'residential_city':'city', 'residential_state': 'state', 'residential_zipcode': 'zip', 'birthdate': 'birth_date', 'registration_date': 'reg_date', 'congressional_district_20': 'congressional', 'legislative_district_20': 'legislative', 'senate_district_20': 'state_senate', 'voter_history_1': 'last_election'}, inplace = True)
```

Change names/create fields that don't exist in df currently but are in old data. Create source flag in new file (in joined file at end, 1 = old data, 2 = new).

```
voters['reg_year'] = voters['reg_date'].dt.year
voters['source'] = 2
voters['zip_clean'] = voters['zip']
voters['city_clean'] = voters['city']
```

Create a new df that has only the data we need.

```
fields_needed = ['county', 'voter_id', 'first_name', 'middle_name', 'last_name', 'suffix', 'house_number', 'house_suffix', 'pre_direction', 'street_name', 'street_type', 'post_direction', 'unit_type', 'unit_number', 'non_standard_address', 'city', 'state', 'zip', 'birth_date', 'reg_date', 'precinct', 'precinct_name', 'split', 'township', 'ward', 'congressional', 'legislative', 'state_senate', 'voter_status', 'last_election', 'source', 'dupe_flag', 'reg_year', 'address_clean', 'zip_clean', 'city_clean']

# Filter df to only those fields 

voters_tap = voters[fields_needed]
```

Join it with the old file.

```
joined = pd.concat([voters_tap, keepers])
```

Check for duplicates in new, joined file, create dupe flag in join file based on check.

```
# Now we need to check the joined file for duplicate values
# keep=False here is marking all duplicates, based on voter_id, as True
# The dupe analysis based on unique IDs seems to indicate there aren't any
# BUT, caveat: There are unique IDs, and still duplicate voters; see below

is_duplicated = joined['voter_id'].duplicated(keep=False)

# Check for duplicates across name, birthdate, mailing ZIP
# Reveals that despite unique voter IDs (per Kiernan's R script), there are dupes
# Recast dupe_flag based on this

duped_names = joined.duplicated(subset=["first_name", "last_name", "birth_date", "zip"])

# This filters the dataframe to only the duplicated names 

names_duped = joined[duped_names]

# This recasts the dupe flag
joined['dupe_flag'] = np.where(joined.duplicated(subset=["first_name", "last_name", "birth_date", "zip"], keep=False), 'TRUE', 'FALSE')

t = ['TRUE']
filtered_t = joined[joined['dupe_flag'].isin(t)]
print('In the 2023 and 2020 data, combined, there are ' + "{:,}".format(len(filtered_t['voter_id'])) + ' duplicates.')

In the 2023 and 2020 data, combined, there are 3,969 duplicates.
```

## Export

Now the file can be saved on disk for upload to the Accountability
server.

```
# Export for TAP

joined.to_csv('mo_voters_2023.csv')
```
