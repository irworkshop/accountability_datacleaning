# Georgia Contributions Data Dictionary

|Column                  |Type        |Definition                                  |
|:-----------------------|:-----------|:-------------------------------------------|
|`filer_id`              |`character` |ID of filer                                 |
|`type`                  |`character` |Contribution method                         |
|`last_name`             |`character` |Last name of filer                          |
|`first_name`            |`character` |First name of filer                         |
|`address`               |`character` |Contributor street address                  |
|`city`                  |`character` |Contributor city name                       |
|`state`                 |`character` |Contributor state abbreviation              |
|`zip`                   |`character` |Contributor ZIP+4 code                      |
|`pac`                   |`character` |PAC                                         |
|`occupation`            |`character` |Contributor occupation                      |
|`employer`              |`character` |Contributor employer                        |
|`date`                  |`double`    |Date contribution was made                  |
|`election`              |`character` |Election type                               |
|`election_year`         |`character` |Election cycle                              |
|`cash_amount`           |`double`    |Contribution amount or correction in cash   |
|`in_kind_amount`        |`double`    |In-kind contribution amount or correction   |
|`in_kind_description`   |`character` |Description of in-kind contribution         |
|`candidate_first_name`  |`character` |Candidate first name                        |
|`candidate_middle_name` |`character` |Candidate middle name                       |
|`candidate_last_name`   |`character` |Candidate last name                         |
|`candidate_suffix`      |`character` |Candidate suffix                            |
|`committee_name`        |`character` |Committee name                              |
|`na_flag`               |`logical`   |Flag for missing name, city or address      |
|`dupe_flag`             |`logical`   |Flag for completely duplicated record       |
|`total_amount`          |`double`    |Sum of in-kind and cash contribution amount |
|`year`                  |`double`    |Calendar year of contribution date          |
|`address_clean`         |`character` |Normalized combined street address          |
|`zip_clean`             |`character` |Normalized 5-digit ZIP code                 |
|`state_clean`           |`character` |Normalized 2-digit state abbreviation       |
|`city_clean`            |`character` |Normalized city name                        |
