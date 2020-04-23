# Wisconsin Contributions Data Dictionary

|Column        |Type     |Definition                                  |
|:-------------|:--------|:-------------------------------------------|
|`date`        |`<date>` |Date contribution was made                  |
|`period`      |`<chr>`  |Election during which contribution was made |
|`con_name`    |`<chr>`  |Contributor full name                       |
|`amount`      |`<dbl>`  |Contribution amount or correction           |
|`addr1`       |`<chr>`  |Contributor street address                  |
|`addr2`       |`<chr>`  |Contributor secondary address               |
|`city`        |`<chr>`  |Contributor city name                       |
|`state`       |`<chr>`  |Contributor 2-digit state abbreviation      |
|`zip`         |`<chr>`  |Contributor ZIP+4 code                      |
|`occupation`  |`<chr>`  |Contributor occupation                      |
|`emp_name`    |`<chr>`  |Contributor employer name                   |
|`emp_addr`    |`<chr>`  |Contributor employer address                |
|`con_type`    |`<chr>`  |Contributor type                            |
|`rec_name`    |`<chr>`  |Recipient committee name                    |
|`ethcfid`     |`<chr>`  |Recipient ethics & campaign finance ID      |
|`conduit`     |`<chr>`  |Contribution condiut (method)               |
|`branch`      |`<chr>`  |Recipient election office sought            |
|`comment`     |`<chr>`  |Comment (typically check date)              |
|`seg_fund`    |`<lgl>`  |PAC segregated fund sourced                 |
|`na_flag`     |`<lgl>`  |Flag for missing date, amount, or name      |
|`dupe_flag`   |`<lgl>`  |Flag for completely duplicated record       |
|`year`        |`<dbl>`  |Calendar year of contribution date          |
|`addr_clean`  |`<chr>`  |Normalized combined street address          |
|`zip_clean`   |`<chr>`  |Normalized 5-digit ZIP code                 |
|`state_clean` |`<chr>`  |Normalized 2-digit state abbreviation       |
|`city_clean`  |`<chr>`  |Normalized city name                        |
