# Louisiana Contracts Data Dictionary

|Column              |Type        |Definition                              |
|:-------------------|:-----------|:---------------------------------------|
|`source`            |`character` |Source Excel file name                  |
|`id`                |`character` |Unique contract or purchase ID          |
|`type`              |`character` |Contract or single purchase order       |
|`service_type`      |`character` |Service type code                       |
|`service_type_name` |`character` |Service type full name                  |
|`dept`              |`character` |Spending department code                |
|`department_name`   |`character` |Spending department name                |
|`state`             |`character` |Spending department state abbreviation  |
|`common_vendor`     |`character` |Common vendor ID                        |
|`vendor`            |`character` |Unique vendor ID                        |
|`vendor_name`       |`character` |Vendor full name                        |
|`total_amount`      |`double`    |Total contract or purchase amount       |
|`total_count`       |`integer`   |Total number of contracts ordered       |
|`description`       |`character` |Free-form text description of contracts |
|`year`              |`integer`   |Fiscal year ordered from source file    |
|`dupe_flag`         |`logical`   |Flag indicating duplicate record        |
