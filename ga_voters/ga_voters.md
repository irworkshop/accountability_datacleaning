## Georgia voter processing notes

This data was obtained Jan. 2019 via public records request in csv formal.

Record count: 6,947,649

**Fix cities by creating a lookup table of clean cities:**

`create table city_lookup as
select residence_city, upper(residence_city) as residence_city_clean, count(*)
from ga_voters
group by 1
order by 1`

Using a mix of check against other data, openref and viewing, get the city_lookup table as clean as we can.

**Add fields in main table for new fields:**

`ALTER TABLE ga_voters ADD COLUMN RESIDENCE_CITY_CLEAN;
ALTER TABLE ga_voters ADD COLUMN ZIP5;
ALTER TABLE ga_voters ADD COLUMN YEAR;`

**Update main table using cleaned city lookup data:**

`UPDATE GA_VOTERS
set RESIDENCE_CITY_CLEAN = (select y.RESIDENCE_CITY_CLEAN from CITY_LOOKUP as y where y.RESIDENCE_CITY=GA_VOTERS.RESIDENCE_CITY)`

**Create ZIP5**

`UPDATE GA_VOTERS
set ZIP5 = SUBSTR(RESIDENCE_ZIPCODE,1,5)`

**Extract YEAR**

`UPDATE GA_VOTERS
set YEAR = SUBSTR(REGISTRATION_DATE,1,4)`

**Known problems**
A few cases with ZIPs out of state or invalid.
BIRTHDATES range from 1800 to 2018

**Extract table for upload:**

`CREATE TABLE GA_VOTERS_OUT AS
SELECT COUNTY_CODE, REGISTRATION_NUMBER, VOTER_STATUS, LAST_NAME,
FIRST_NAME, MIDDLE_MAIDEN_NAME, NAME_SUFFIX, NAME_TITLE,
RESIDENCE_HOUSE_NUMBER, RESIDENCE_STREET_NAME, RESIDENCE_STREET_SUFFIX,
RESIDENCE_APT_UNIT_NBR, RESIDENCE_CITY, RESIDENCE_ZIPCODE, BIRTHDATE,
REGISTRATION_DATE, STATUS_REASON, DATE_LAST_VOTED, PARTY_LAST_VOTED,
DATE_ADDED,  RESIDENCE_CITY_CLEAN AS RESIDENCE_CITY, ZIP5, YEAR
FROM GA_VOTERS`
