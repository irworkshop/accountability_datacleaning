# Pennsylvania Contributions Data Dictionary

|Column              |Type      |Definition                                |
|:-------------------|:---------|:-----------------------------------------|
|`filerid`           |double    |Filer unique filer ID                     |
|`eyear`             |double    |Election year                             |
|`cycle`             |double    |Election cycle                            |
|`section`           |character |Election section                          |
|`contributor`       |character |Contributor full name                     |
|`con_address1`      |character |Contributor street address                |
|`con_address2`      |character |Contributor secondary address             |
|`con_city`          |character |Contributor city name                     |
|`con_state`         |character |Contributor state abbreviation            |
|`con_zip`           |character |Contributor ZIP+4 code                    |
|`occupation`        |character |Contributor occupation                    |
|`ename`             |character |Contributor employer name                 |
|`date`              |double    |Date contribution made                    |
|`amount`            |double    |Contribution amount or correction         |
|`fil_type`          |double    |Filer type                                |
|`filer`             |character |Filer committee name                      |
|`office`            |character |Filer office sought                       |
|`district`          |integer   |District election held                    |
|`party`             |character |Filer political party                     |
|`fil_address1`      |character |Filer street address                      |
|`fil_address2`      |logical   |Filer secondary address                   |
|`fil_city`          |character |Filer city name                           |
|`fil_state`         |character |Filer 2-digit state abbreviation          |
|`fil_zip`           |character |Filer ZIP+4 code                          |
|`county`            |character |County election held in                   |
|`fil_phone`         |logical   |Filer telephone number                    |
|`na_flag`           |logical   |Flag for missing date, amount, or name    |
|`dupe_flag`         |logical   |Flag for completely duplicated record     |
|`year`              |double    |Calendar year of contribution date        |
|`con_address_clean` |character |Normalized contributor street address     |
|`fil_address_clean` |character |Normalized Filer street address           |
|`con_zip_clean`     |character |Normalized contributor 5-digit ZIP code   |
|`fil_zip_clean`     |character |Normalized Filer 5-digit ZIP code         |
|`con_state_clean`   |character |Normalized contributor state abbreviation |
|`fil_state_clean`   |character |Normalized Filer state abbreviation       |
|`fil_city_clean`    |character |Normalized Filer city name                |
|`con_city_clean`    |character |Normalized contributor city name          |
