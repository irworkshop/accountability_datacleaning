# Georgia Lobbying Registration Data Dictionary

|Column              |Type        |Definition                                               |
|:-------------------|:-----------|:--------------------------------------------------------|
|`filer_id`          |`character` |ID of the filer (lobbyist)                               |
|`last_name`         |`character` |Lobbyist last name                                       |
|`suffix`            |`character` |Lobbyist name suffix                                     |
|`first_name`        |`character` |Lobbyist first name                                      |
|`middle_name`       |`character` |Lobbyist middle name                                     |
|`address1`          |`character` |Lobbyist street address line 1                           |
|`address2`          |`character` |Lobbyist street address line 2                           |
|`city`              |`character` |Lobbyist City                                            |
|`state`             |`character` |Lobbyis State                                            |
|`zip`               |`character` |Lobbyist ZIP code                                        |
|`phone_clean`       |`character` |Normalized Lobbyist phone                                |
|`phone`             |`character` |Lobbyist phone                                           |
|`phone_ext`         |`character` |Lobbyist phone extension                                 |
|`phone2`            |`character` |Secondary lobbyist phone                                 |
|`public_e_mail`     |`character` |Lobbyist email                                           |
|`association`       |`character` |Organization to which lobbyists were associated          |
|`payment_exceeds`   |`logical`   |Payment exceeds $10,000                                  |
|`date_registered`   |`double`    |Date registered                                          |
|`date_terminated`   |`double`    |Date terminated                                          |
|`lobbying_level`    |`character` |Level of lobbying activity                               |
|`year`              |`integer`   |Year of data publication                                 |
|`dupe_flag`         |`logical`   |Flag for missing date, organization, or, filerID or name |
|`na_flag`           |`logical`   |Flag for completely duplicated record                    |
|`grp_address1`      |`character` |Lobbying group street address line 1                     |
|`grp_address2`      |`character` |Lobbying group street address line 2                     |
|`grp_phone`         |`character` |Lobbying group phone                                     |
|`grp_city`          |`character` |Lobbying group city                                      |
|`grp_state`         |`character` |Lobbying group state                                     |
|`grp_zip`           |`character` |Lobbying group zip                                       |
|`grp_phone_clean`   |`character` |Normalized Lobbying phone number                         |
|`address_clean`     |`character` |Normalized lobbying group street address                 |
|`grp_address_clean` |`character` |Normalized lobbyist street address                       |
|`zip_clean`         |`character` |Normalized 5-digit lobbyist ZIP code                     |
|`grp_zip_clean`     |`character` |Normalized 5-digit lobbying group ZIP code               |
|`city_clean`        |`character` |Normalized lobbyist city name                            |
|`grp_city_clean`    |`character` |Normalized lobbying group city name                      |
