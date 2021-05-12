# Georgia Lobbying Registration Data Dictionary

|Column           |Type        |Definition                                               |
|:----------------|:-----------|:--------------------------------------------------------|
|`FilerID`        |`character` |ID of the filer (lobbyist)                               |
|`LastName`       |`character` |Lobbyist last name                                       |
|`Suffix`         |`character` |Lobbyist name suffix                                     |
|`FirstName`      |`character` |Lobbyist first name                                      |
|`MiddleName`     |`character` |Lobbyist middle name                                     |
|`Address1`       |`character` |Lobbyist street address line 1                           |
|`Address2`       |`character` |Lobbyist street address line 2                           |
|`City`           |`character` |Lobbyist City                                            |
|`State`          |`character` |Lobbyis State                                            |
|`Zip`            |`character` |Lobbyist ZIP code                                        |
|`Phone_clean`    |`character` |Normalized Lobbyist phone                                |
|`Phone`          |`character` |Lobbyist phone                                           |
|`PhoneExt`       |`character` |Lobbyist phone extension                                 |
|`Phone2`         |`character` |Secondary lobbyist phone                                 |
|`Public_EMail`   |`character` |Lobbyist email                                           |
|`Association`    |`character` |Organization to which lobbyists were associated          |
|`PaymentExceeds` |`character` |Payment exceeds $10,000                                  |
|`DateRegistered` |`character` |Date registered                                          |
|`DateTerminated` |`character` |Date terminated                                          |
|`LobbyingLevel`  |`character` |Level of lobbying activity                               |
|`Year`           |`integer`   |Year of data publication                                 |
|`dupe_flag`      |`logical`   |Flag for missing date, organization, or, filerID or name |
|`na_flag`        |`logical`   |Flag for completely duplicated record                    |
|`address_clean`  |`character` |Normalized lobbyist street address                       |
|`zip_clean`      |`character` |Normalized 5-digit ZIP code                              |
|`city_clean`     |`character` |Normalized city name                                     |
