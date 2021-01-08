# Florida Contribution Data Dictionary

|Column                |Type        |Definition                             |
|:---------------------|:-----------|:--------------------------------------|
|`Candidate_Committee` |`character` |Recipient candidate or committee       |
|`Date`                |`double`    |Date of contribution made              |
|`Amount`              |`double`    |Contribution amount                    |
|`Type`                |`character` |Contributor type                       |
|`ContribName`         |`character` |Contributor name                       |
|`Address`             |`character` |Contributor street address             |
|`City_State_Zip`      |`character` |Contributor City, State and ZIP code   |
|`Occupation`          |`character` |Contributor occupation                 |
|`InkindDesc`          |`character` |Description of Inkind Contributions    |
|`na_flag`             |`logical`   |Flag for missing date, amount, or name |
|`dupe_flag`           |`logical`   |Flag for completely duplicated record  |
|`YEAR`                |`double`    |Calendar year of contribution date     |
|`Address_clean`       |`character` |Normalized combined street address     |
|`ZIP5`                |`character` |Normalized 5-digit ZIP code            |
|`State_clean`         |`character` |Normalized 2-digit state abbreviation  |
|`City_clean`          |`character` |Normalized city name                   |
