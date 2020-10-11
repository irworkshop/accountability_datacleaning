# Louisiana Contributions Data Dictionary

|Column                      |Type        |Definition                             |
|:---------------------------|:-----------|:--------------------------------------|
|`filer_last_name`           |`character` |Last name of filer                     |
|`filer_first_name`          |`character` |First name of filer                    |
|`report_code`               |`character` |Type of document filed                 |
|`report_type`               |`character` |Form schedule                          |
|`report_number`             |`character` |Date contribution was made             |
|`contributor_name`          |`character` |Contributor name                       |
|`contributor_addr1`         |`character` |Contributor street address             |
|`contributor_addr2`         |`character` |Contributor secondary address          |
|`contributor_city`          |`character` |Contributor city name                  |
|`contributor_state`         |`character` |Contributor state abbreviation         |
|`contributor_zip`           |`character` |Contributor ZIP+4 code                 |
|`contribution_type`         |`character` |Contribution method                    |
|`contribution_description`  |`character` |Contribution description               |
|`contribution_date`         |`double`    |Contribution date                      |
|`contribution_amt`          |`double`    |Contribution amount or correction      |
|`na_flag`                   |`logical`   |Flag for missing name, city or address |
|`dupe_flag`                 |`logical`   |Flag for completely duplicated record  |
|`year`                      |`double`    |Calendar year of contribution date     |
|`contributor_address_clean` |`character` |Normalized combined street address     |
|`contributor_zip_clean`     |`character` |Normalized 5-digit ZIP code            |
|`contributor_state_clean`   |`character` |Normalized 2-digit state abbreviation  |
|`contributor_city_clean`    |`character` |Normalized city name                   |
