

Employee Benefits Security Administration Enforcement Data
Processed by: David Herzog
OK’d by: Charles Minshew

Employee Benefits Security Administration enforcement data
Range: 2000-2020 Publisher: U.S. Department of Labor
Record Count: 6,774

The dataset consists of closed cases that resulted in penalty assessments by EBSA since 2000. This data provides information on EBSA's enforcement programs to enforce the Employee Retirement Income Security Act Form 5500 Annual Return/Report filing requirement focusing on deficient filers, late filers and non-filers. This data was updated on Jan. 12, 2021. The most recent final close date for the actions is Dec. 29, 2020. Each record represents an enforcement case against an employee benefits plans by the U.S. Department of Labor. The full data set contains all original variables and new variables added to it. Data was processed using SQLite database language and documented in the following data diary.

Download date:
2/5/2021

Downloaded from:
https://enforcedata.dol.gov/views/data_summary.php

Database contact information:
Name and Title: Laura K. McGinnis, Digital Media Specialist
Email mcginnis.laura.k@dol.gov
Phone: (202) 251-7929

Data is most recent and correct?
Yes

Data generated
Jan. 12, 2021, according to load_dt field

Documentation file(s):
Ebsa_metadata.csv
See this file for a description of the data’s contents.

Ebsa_data_dictionary.csv
See this file for a description of the table contents.


Original Data file(s)
Ebsa_ocats_csv
6,774 rows, excluding header

Cleaned data files:
States_lookup.csv
52 rows, excluding header

Ebsa_ocats_clean.csv
6,774 rows, excluding header





Names included in the data file: (Companies)
Plan_name
Plan_administrator



SQLite audit trail for checks and cleaning

Duplicate_record_check
Are there any duplicate records?

SELECT ein, load_dt, final_close_date, penalty_amount, plan_admin, final_close_reason, plan_name, plan_admin_state, case_type, plan_year, plan_admin_zip_code, pn, count()
FROM ebsa_ocats
GROUP BY ein, load_dt, final_close_date, penalty_amount, plan_admin, final_close_reason, plan_name, plan_admin_state, case_type, plan_year, plan_admin_zip_code, pn
ORDER BY count() DESC

6,774 rows
No duplicate records


Ic_plan_year
Plan_year integrity check

SELECT plan_year, count()
FROM ebsa_ocats
GROUP BY plan_year
ORDER BY plan_year

111 rows

32 entered as “0”

Some are single years, others are ranges separated by a dash.
Example: 2011-2014
Years cover 1991-2019.
Create plan_year_clean field, format as text

ALTER TABLE ebsa_ocats ADD COLUMN plan_year_clean TEXT

All are NULL

Test_plan_year_clean
Check to see if the cleaning SQL works

SELECT plan_year, substr(plan_year, instr(plan_year, "-")+1, 4)
FROM ebsa_ocats

Success, returns four character years, regardless whether it is reported as a range or with four characters..

SQL to update plan_year

UPDATE ebsa_ocats
SET plan_year_clean = substr(plan_year, instr(plan_year, "-")+1, 4)





Ic_plan_admin_zip_code
Plan_admin_zip_code_integrity_check

SELECT plan_admin_zip_code, count()
FROM ebsa_ocats
GROUP BY plan_admin_zip_code
ORDER BY plan_admin_zip_code

4,673 rows

713 have “-”

“0000--”    1
“00000-”    1
“00000-0000”    1

ZIPs are mix of five characters with a dash and nine with a dash.

Examples:


00726-
00726-0594



Use SQL to create new ZIP5 field and standardize

Create plan_admin_zip_code_clean field

ALTER TABLE ebsa_ocats ADD COLUMN plan_admin_zip_code_clean TEXT

All are NULL


Test plan_admin_zip_code_clean SQL

SELECT plan_admin_zip_code, substr(plan_admin_zip_code, 1, 5)
FROM ebsa_ocats
WHERE plan_admin_zip_code <> "-"
ORDER BY 2

Success, returns five characters ZIPs


UPDATE plan_admin_zip_code_clean field

UPDATE ebsa_ocats
SET plan_admin_zip_code_clean = substr(plan_admin_zip_code, 1, 5)
WHERE plan_admin_zip_code <> "-"

Success, populates with five character ZIPs




ic_final_close_date
Final_close_date integrity check

SELECT final_close_date, count()
FROM ebsa_ocats
GROUP BY final_close_date
ORDER BY final_close_date

1,404 rows

Range:

2000-02-18


To


2020-12-29



Within expected range


Create final_close_year_clean, format as text.

ALTER TABLE ebsa_ocats ADD COLUMN final_close_year_clean TEXT

All NULL


test_final_close_year_clean
Test SQL to clean field

SELECT final_close_date, substr(final_close_date, 1, 4)
FROM ebsa_ocats
ORDER BY 2

6,774 rows

Success, range 2000-2020.


Update final_close_year_clean field using SQL

UPDATE ebsa_ocats
SET final_close_year_clean = substr(final_close_date, 1, 4)


Success, all four character years.


Ic_plan_admin_state
Plan_admin_state integrity check

SELECT plan_admin_state, count()
FROM ebsa_ocats
GROUP BY plan_admin_state
ORDER BY plan_admin_state

53 rows
1,047 NULL

52 states including
Puerto Rico
District of Columbia
All 50 states

All states in proper case:
“Alabama”

Output result as CSV file and added state postal abbreviations in Excel. Saved as CSV:

States_lookup.csv

Import into DB Browser.


Test_state_abbv_clean_join

SELECT ebsa_ocats.*, st_abbv
FROM ebsa_ocats
LEFT JOIN states_lookup ON ebsa_ocats.plan_admin_state = states_lookup.st_name

6774 rows, st_abbv added to end of view


Use the join to create ebsa_ocats_clean

CREATE TABLE ebsa_ocats_clean AS
SELECT ebsa_ocats.*, st_abbv
FROM ebsa_ocats
LEFT JOIN states_lookup ON ebsa_ocats.plan_admin_state = states_lookup.st_name

6774 rows, success

Exported CSVs from DB Browser







