# District Of Columbia Contracts Data Dictionary

|Column            |Type        |Definition                                         |
|:-----------------|:-----------|:--------------------------------------------------|
|`contract_number` |`character` |Unique contract number                             |
|`title`           |`character` |Contract title                                     |
|`agency`          |`character` |Awarding agency name                               |
|`option_period`   |`character` |Option period awarded                              |
|`start_date`      |`double`    |Contract start date                                |
|`end_date`        |`double`    |Contract end date                                  |
|`award_date`      |`double`    |Contract awarded date                              |
|`nigp_code`       |`character` |National Institute of Governmental Purchasing code |
|`vendor`          |`character` |Recipient vendor name                              |
|`amount`          |`double`    |Contract amount awarded                            |
|`na_flag`         |`logical`   |Flag for missing date, amount, or name             |
|`dupe_flag`       |`logical`   |Flag for completely duplicated record              |
|`award_year`      |`double`    |Calendar year contract awarded                     |
