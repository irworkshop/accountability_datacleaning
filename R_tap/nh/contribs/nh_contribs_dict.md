# New Hampshire Contributions Data Dictionary

|Column                      |Type        |Definition                                     |
|:---------------------------|:-----------|:----------------------------------------------|
|`cf_id`                     |`character` |Recipient unique ID                            |
|`transaction_date`          |`double`    |Date contribution was made                     |
|`contributor_type`          |`character` |Contributor type                               |
|`contributor_name`          |`character` |Contributor name                               |
|`contributor_address`       |`character` |Contributor full address                       |
|`receiving_registrant`      |`character` |Recipient committee name                       |
|`receiving_registrant_type` |`character` |Recipient type                                 |
|`office`                    |`character` |Recipient office sought                        |
|`county`                    |`character` |Election county                                |
|`election_cycle`            |`character` |Election cycle                                 |
|`reporting_period`          |`double`    |Contribution period reported                   |
|`contribution_type`         |`character` |Contribution method                            |
|`amount`                    |`double`    |Contribution amount or correction              |
|`total_contribution_amount` |`double`    |Total ammount contributor given                |
|`comments`                  |`character` |Contribution comments                          |
|`in_kind_sub_category`      |`character` |Contribution In-Kind category                  |
|`town_city`                 |`character` |Original contributor city                      |
|`town_state`                |`character` |Original contributor state                     |
|`occupation`                |`character` |Contributor occupation                         |
|`employer_name`             |`character` |Contributor employer name                      |
|`na_flag`                   |`logical`   |Flag for missing date, amount, or name         |
|`dupe_flag`                 |`logical`   |Flag for completely duplicated record          |
|`transaction_year`          |`double`    |Calendar year of contribution date             |
|`addr_clean`                |`character` |Separated & normalized combined street address |
|`city_clean`                |`character` |Separated & normalized city name               |
|`state_clean`               |`character` |Separated & normalized state abbreviation      |
|`zip_clean`                 |`character` |Separated & normalized 5-digit ZIP code        |
