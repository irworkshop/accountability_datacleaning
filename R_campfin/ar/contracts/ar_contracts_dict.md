# Arkansas Contracts Data Dictionary

|Column                |Type        |Overlaped |Definition                             |
|:---------------------|:-----------|:---------|:--------------------------------------|
|`file`                |`character` |TRUE      |Source file                            |
|`fiscal_year`         |`integer`   |TRUE      |Transaction's fiscal year              |
|`agency`              |`character` |TRUE      |Spending agency name                   |
|`document_category`   |`character` |FALSE     |Contract category                      |
|`contract_number`     |`character` |TRUE      |Tracking contract number               |
|`material_group`      |`character` |TRUE      |Purchase order category                |
|`type_of_contract`    |`character` |FALSE     |Contract sub-type                      |
|`vendor_name`         |`character` |TRUE      |Vendor name                            |
|`vendor_dba`          |`character` |FALSE     |Vendor "doing business as"             |
|`contract_start_date` |`double`    |FALSE     |Contract start date                    |
|`contract_end_date`   |`double`    |FALSE     |Contract end date                      |
|`contract_value`      |`double`    |FALSE     |Total contract value                   |
|`amount_ordered`      |`double`    |TRUE      |Amount initially ordered               |
|`amount_spent`        |`double`    |TRUE      |Amount finally spent                   |
|`agency_id`           |`character` |FALSE     |Spending agency ID                     |
|`release_po`          |`character` |FALSE     |Releasing agency ID                    |
|`release_date`        |`double`    |FALSE     |Purchase order date                    |
|`type`                |`character` |TRUE      |Type of record (Contract or purchase)  |
|`date`                |`double`    |TRUE      |Unified transaction date               |
|`na_flag`             |`logical`   |TRUE      |Flag for missing date, amount, or name |
|`dupe_flag`           |`logical`   |TRUE      |Flag for completely duplicated record  |
|`year`                |`double`    |TRUE      |Calendar year from unified date        |
