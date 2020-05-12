# Indiana Contracts Data Dictionary

|Column        |Type        |Definition                                     |
|:-------------|:-----------|:----------------------------------------------|
|`amount`      |`double`    |Contract amount                                |
|`contract_id` |`character` |Unique contract ID                             |
|`amendment`   |`double`    |Contract amendment number                      |
|`action_type` |`character` |Contract action type (New, Amendment, Renewal) |
|`start_date`  |`double`    |Contract start date                            |
|`end_date`    |`double`    |Contract end date                              |
|`agency`      |`character` |Spending agency name                           |
|`vendor_name` |`character` |Recieving vendor name                          |
|`zip_code`    |`character` |Vendor 5-digit ZIP code                        |
|`na_flag`     |`logical`   |Flag for missing date, amount, or name         |
|`dupe_flag`   |`logical`   |Flag for completely duplicated record          |
|`start_year`  |`double`    |Calendar year contract started                 |
