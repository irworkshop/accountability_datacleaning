# District Of Columbia Contracts Data Dictionary

|Column          |Found in both |Type  |Definition                                         |
|:---------------|:-------------|:-----|:--------------------------------------------------|
|`type`          |`character`   |TRUE  |Transaction type (contract or purchae)             |
|`id`            |`character`   |TRUE  |Unique contract number                             |
|`title`         |`character`   |TRUE  |Contract title                                     |
|`agency`        |`character`   |TRUE  |Awarding agency name                               |
|`option_period` |`character`   |FALSE |Option period awarded                              |
|`start_date`    |`double`      |FALSE |Contract start date                                |
|`end_date`      |`double`      |FALSE |Contract end date                                  |
|`date`          |`double`      |TRUE  |Contract awarded date, purchase made date          |
|`nigp_code`     |`character`   |TRUE  |National Institute of Governmental Purchasing code |
|`vendor`        |`character`   |TRUE  |Recipient vendor name                              |
|`amount`        |`double`      |TRUE  |Contract amount awarded, total purchase amount     |
|`fiscal_year`   |`character`   |FALSE |Purchase order fiscal year                         |
|`na_flag`       |`logical`     |NA    |Flag for missing date, amount, or name             |
|`dupe_flag`     |`logical`     |NA    |Flag for completely duplicated record              |
|`year`          |`double`      |NA    |Calendar year contract awarded                     |
