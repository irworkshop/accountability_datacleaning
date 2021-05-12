# District Of Columbia Contracts Data Dictionary

|Column          |Found in both |Type  |Definition                                         |
|:---------------|:-------------|:-----|:--------------------------------------------------|
|`type`          |`character`   |TRUE  |Transaction type (contract or purchae)             |
|`id`            |`character`   |TRUE  |Unique contract number                             |
|`title`         |`character`   |TRUE  |Contract title                                     |
|`agency`        |`character`   |TRUE  |Awarding agency name                               |
|`state`         |`character`   |FALSE |Awarding agency state location                     |
|`option_period` |`character`   |FALSE |Option period awarded                              |
|`start_date`    |`double`      |FALSE |Contract start date                                |
|`end_date`      |`double`      |TRUE  |Contract end date                                  |
|`date`          |`double`      |TRUE  |Contract awarded date, purchase made date          |
|`nigp_code`     |`character`   |TRUE  |National Institute of Governmental Purchasing code |
|`vendor`        |`character`   |TRUE  |Recipient vendor name                              |
|`amount`        |`double`      |FALSE |Contract amount awarded, total purchase amount     |
|`fiscal_year`   |`character`   |NA    |Purchase order fiscal year                         |
|`na_flag`       |`logical`     |NA    |Flag for missing date, amount, or name             |
|`dupe_flag`     |`logical`     |NA    |Flag for completely duplicated record              |
|`year`          |`double`      |TRUE  |Calendar year contract awarded                     |
