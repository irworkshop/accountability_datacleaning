# HHS Provider Relief Data Dictionary

|Column     |Type        |Definition                                                                   |
|:----------|:-----------|:----------------------------------------------------------------------------|
|`agency`   |`character` |Distributing agency name                                                     |
|`provider` |`character` |Provider name associated with the billing TIN to whom the payment was issued |
|`state`    |`character` |Provider city name (with expanded abbreviations)                             |
|`city`     |`character` |Provider state abbreviation                                                  |
|`payment`  |`double`    |The cumulative payment that the provider has received AND attested to        |
|`year`     |`double`    |Current calendar year                                                        |
