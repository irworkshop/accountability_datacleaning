# Deleware Contributions Data Dictionary

|Column        |Type        |Definition                                        |
|:-------------|:-----------|:-------------------------------------------------|
|`date`        |`double`    |Date contribution was made                        |
|`contributor` |`character` |Contributor full name                             |
|`addr1`       |`character` |Contributor street address                        |
|`addr2`       |`character` |Contributor secondary address                     |
|`city`        |`character` |Contributor city name                             |
|`state`       |`character` |Contributor 2-digit state abbreviation            |
|`zip`         |`character` |Contributor ZIP+4 code                            |
|`type`        |`character` |Contributor type                                  |
|`employer`    |`character` |Contributor employer name                         |
|`occupation`  |`character` |Contributor occupation                            |
|`method`      |`character` |Contribution method                               |
|`amount`      |`double`    |Contribution amount or correction                 |
|`cf_id`       |`character` |Unique campaign finance ID                        |
|`recipient`   |`character` |Recipient committee name                          |
|`period`      |`character` |Report filing period                              |
|`office`      |`character` |Office sought by recipient                        |
|`fixed_asset` |`logical`   |Fix asset flag                                    |
|`na_flag`     |`logical`   |Flag for missing date, amount, or name            |
|`dupe_flag`   |`logical`   |Flag for completely duplicated record             |
|`year`        |`double`    |Calendar year of contribution date                |
|`addr_clean`  |`character` |Normalized contributor street address             |
|`zip_clean`   |`character` |Normalized contributor 5-digit ZIP code           |
|`state_clean` |`character` |Normalized contributor 2-digit state abbreviation |
|`city_clean`  |`character` |Normalized contributor city name                  |
