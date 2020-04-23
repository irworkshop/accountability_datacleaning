# West Virginia Lobbying Registration Dictionary

|Column               |Type    |Definition                                                |
|:--------------------|:-------|:---------------------------------------------------------|
|`lobbyist_name`      |`<chr>` |Original Field                                            |
|`address_line1`      |`<chr>` |Original Field                                            |
|`address_line2`      |`<chr>` |Original Field                                            |
|`city_state_zip`     |`<chr>` |City field extracted from`city_state_zip`                 |
|`city`               |`<chr>` |State field extracted from`city_state_zip`                |
|`state`              |`<chr>` |Zip field extracted from`city_state_zip`                  |
|`zip`                |`<chr>` |Original Field                                            |
|`phone_primary`      |`<chr>` |Original Field                                            |
|`email`              |`<chr>` |Original Field                                            |
|`topics`             |`<chr>` |Original Field                                            |
|`represents`         |`<chr>` |The latest year in the current lobbying cycle             |
|`year`               |`<chr>` |Normalized primary phone numbers from`phone_primary_norm` |
|`phone_primary_norm` |`<chr>` |Normalized combined street address                        |
|`address_norm`       |`<chr>` |Normalized 5-digit ZIP code                               |
|`zip5`               |`<chr>` |Normalized 2-digit state abbreviation                     |
|`city_clean`         |`<chr>` |Normalized city name                                      |
