# New Hampshire Contributions Data Dictionary

|Column        |Type        |Definition                                     |
|:-------------|:-----------|:----------------------------------------------|
|`cf_id`       |`character` |Recipient unique ID                            |
|`date`        |`double`    |Date contribution was made                     |
|`con_type`    |`character` |Contributor type                               |
|`contributor` |`character` |Contributor name                               |
|`geo_full`    |`character` |Contributor full address                       |
|`recipient`   |`character` |Recipient committee name                       |
|`rec_type`    |`character` |Recipient type                                 |
|`office`      |`character` |Recipient office sought                        |
|`county`      |`character` |Election county                                |
|`cycle`       |`character` |Election cycle                                 |
|`period`      |`double`    |Contribution period reported                   |
|`method`      |`character` |Contribution method                            |
|`amount`      |`double`    |Contribution amount or correction              |
|`total`       |`double`    |Total ammount contributor given                |
|`comments`    |`character` |Contribution comments                          |
|`in_kind`     |`character` |Contribution In-Kind category                  |
|`city_old`    |`character` |Original contributor city                      |
|`state_old`   |`character` |Original contributor state                     |
|`occupation`  |`character` |Contributor occupation                         |
|`employer`    |`character` |Contributor employer name                      |
|`na_flag`     |`logical`   |Flag for missing date, amount, or name         |
|`dupe_flag`   |`logical`   |Flag for completely duplicated record          |
|`year`        |`double`    |Calendar year of contribution date             |
|`addr_clean`  |`character` |Separated & normalized combined street address |
|`zip_clean`   |`character` |Separated & normalized 5-digit ZIP code        |
|`state_clean` |`character` |Separated & normalized state abbreviation      |
|`city_clean`  |`character` |Separated & normalized city name               |
