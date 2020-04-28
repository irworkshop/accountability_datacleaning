# North Carolina Contributions Data Dictionary

|Column            |Type     |Definition                                        |
|:-----------------|:--------|:-------------------------------------------------|
|`con_name`        |`<chr>`  |Contributor full name                             |
|`con_addr1`       |`<chr>`  |Contributor street address                        |
|`con_addr2`       |`<chr>`  |Contributor secondary address                     |
|`con_city`        |`<chr>`  |Contributor city name                             |
|`con_state`       |`<chr>`  |Contributor 2-digit state abbreviation            |
|`con_zip`         |`<chr>`  |Contributor ZIP+4 code                            |
|`con_job`         |`<chr>`  |Contributor occupation                            |
|`con_emp`         |`<chr>`  |Contributor employer name                         |
|`con_type`        |`<chr>`  |Contributor type                                  |
|`rec_name`        |`<chr>`  |Recipient committee name                          |
|`rec_id`          |`<chr>`  |Recipient unique ID                               |
|`rec_addr1`       |`<chr>`  |Recipient street address                          |
|`rec_addr2`       |`<chr>`  |Recipient secondary address                       |
|`rec_city`        |`<chr>`  |Recipient city name                               |
|`rec_state`       |`<chr>`  |Recipient 2-digit state abbreviation              |
|`rec_zip`         |`<chr>`  |Recipient ZIP+4 code                              |
|`report`          |`<chr>`  |Election contribution reported for                |
|`date`            |`<date>` |Date contribution was made                        |
|`amount`          |`<dbl>`  |Contribution amount or correction                 |
|`method`          |`<chr>`  |Contribution method                               |
|`purpose`         |`<chr>`  |Contribution purpose                              |
|`candidate`       |`<chr>`  |Recipient candidate or referendum                 |
|`declaration`     |`<chr>`  |Support or oppose declaration                     |
|`na_flag`         |`<lgl>`  |Flag for missing date, amount, or name            |
|`dupe_flag`       |`<lgl>`  |Flag for completely duplicated record             |
|`year`            |`<dbl>`  |Calendar year of contribution date                |
|`con_addr_clean`  |`<chr>`  |Normalized contributor street address             |
|`rec_addr_clean`  |`<chr>`  |Normalized recipient street address               |
|`con_zip_clean`   |`<chr>`  |Normalized contributor 5-digit ZIP code           |
|`rec_zip_clean`   |`<chr>`  |Normalized recipient 5-digit ZIP code             |
|`con_state_clean` |`<chr>`  |Normalized contributor 2-digit state abbreviation |
|`rec_state_clean` |`<chr>`  |Normalized recipient 2-digit state abbreviation   |
|`rec_city_clean`  |`<chr>`  |Normalized recipient city name                    |
|`con_city_clean`  |`<chr>`  |Normalized contributor city name                  |
