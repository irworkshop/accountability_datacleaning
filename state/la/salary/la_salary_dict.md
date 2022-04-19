# Louisiana Salary Data Dictionary

|Column            |Type        |Definition                                |
|:-----------------|:-----------|:-----------------------------------------|
|`pers_no`         |`double`    |Unique personnel number                   |
|`last_name`       |`character` |Employee last name                        |
|`first_name`      |`character` |Emplyee first name                        |
|`employment_type` |`character` |Employment type (full, part)              |
|`job_title`       |`character` |Full job title                            |
|`annual_salary`   |`double`    |Annual salary before overtime or hours    |
|`hours_worked`    |`double`    |Estimated hours worked per pay period     |
|`wage_type`       |`character` |Reported wage type for `gross_wage`       |
|`gross_wages`     |`double`    |Gross wages paid, including overtime      |
|`ytd_overtime`    |`double`    |Overtime year-to-date                     |
|`hire_date`       |`double`    |Date hired at agency                      |
|`agency_abb`      |`character` |Personnel area agency                     |
|`agency_state`    |`character` |Agency state, single value manually added |
|`area`            |`character` |Personnel area name                       |
|`dupe_flag`       |`logical`   |Flag indicating duplicate record          |
|`hire_year`       |`double`    |Calendar year hired at agency             |
