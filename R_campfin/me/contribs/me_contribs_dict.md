# Maine Contributions Data Dictionary

|Column               |Type        |Definition                             |
|:--------------------|:-----------|:--------------------------------------|
|`org_id`             |`character` |Recipient unique ID                    |
|`amount`             |`double`    |Contribution amount                    |
|`date`               |`double`    |Date contribution was made             |
|`contributor`        |`character` |Contributor full name                  |
|`last`               |`character` |Contributor first name                 |
|`first`              |`character` |Contributor middle name                |
|`middle`             |`character` |Contributor last name                  |
|`suffix`             |`character` |Contributor name suffix                |
|`address1`           |`character` |Contributor street address             |
|`address2`           |`character` |Contributor secondary address          |
|`city`               |`character` |Contributor city name                  |
|`state`              |`character` |Contributor 2-digit state abbreviation |
|`zip`                |`character` |Contributor ZIP+4 code                 |
|`id`                 |`character` |Contribution unique ID                 |
|`filed_date`         |`double`    |Date contribution filed                |
|`type`               |`character` |Contribution type                      |
|`source_type`        |`character` |Contribution source                    |
|`committee_type`     |`character` |Recipient committee type               |
|`committee`          |`character` |Recipient commttee name                |
|`candidate`          |`character` |Recipient candidate name               |
|`amended`            |`logical`   |Contribution amended                   |
|`description`        |`character` |Contribution description               |
|`employer`           |`character` |Contributor employer name              |
|`occupation`         |`character` |Contributor occupation                 |
|`occupation_comment` |`character` |Occupation comment                     |
|`emp_info_req`       |`logical`   |Employer information requested         |
|`file`               |`character` |Source file name                       |
|`legacy_id`          |`character` |Legacy recipient ID                    |
|`office`             |`character` |Recipient office sought                |
|`district`           |`character` |Recipient district election            |
|`report`             |`character` |Report contribution listed on          |
|`forgiven_loan`      |`character` |Forgiven loan reason                   |
|`election_type`      |`character` |Election type                          |
|`recipient`          |`character` |Combined type recipient name           |
|`na_flag`            |`logical`   |Flag for missing date, amount, or name |
|`dupe_flag`          |`logical`   |Flag for completely duplicated record  |
|`year`               |`double`    |Calendar year of contribution date     |
|`address_clean`      |`character` |Normalized combined street address     |
|`zip_clean`          |`character` |Normalized 5-digit ZIP code            |
|`state_clean`        |`character` |Normalized 2-digit state abbreviation  |
|`city_clean`         |`character` |Normalized city name                   |
