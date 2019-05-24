## Missouri voters processing notes

Data was acquired via public records request in tab-delimited format.

Record count: 4,210,231

**Add year and ZIP5 columns:**

`alter table mo_voters add column DOBYEAR;
ALTER TABLE mo_voters ADD COLUMN YEAR;
ALTER TABLE mo_voters ADD COLUMN ZIP5;
UPDATE MO_VOTERS SET DOBYEAR=SUBSTR(BIRTHDATE, 7,4);
UPDATE MO_VOTERS SET YEAR=SUBSTR(RegistrationDate,7,4)
UPDATE MO_VOTERS SET ZIP5=SUBSTR(ResidentialZipCode, 1,5)`


**Check ZIP5 range**

`select zip5, count(*)
from mo_voters
group by 1
order by 1`

Two ZIP codes are for IA zips for Davis City. There also are 719 records with XXXXX as ZIP.

**Check cities for consistency**

`select ResidentialCity, count(*)
from mo_voters
group by 1
order by 1`


**Export table**

`CREATE TABLE MO_VOTERS_OUT AS 
select County, VoterID, FirstName, MiddleName, LastName, Suffix, HouseNumber, HouseSuffix, PreDirection, StreetName, StreetType, PostDirection, UnitType,UnitNumber, NonStandardAddress, 
ResidentialCity as CITY, ResidentialState as STATE, ZIP5, Birthdate, RegistrationDate, Precinct, Split, Township, Ward, "Congressional-New" as CONGRESSIONAL, 
"Legislative-New" as LEGISLATIVE, "StateSenate-New" as STATESENATE,YEAR
FROM mo_voters`

**Known issues:**

DOBYEAR span: 1800 to 2018

YEAR span: Several records with clearly invalid date info such as 01/01/0418

Cities appear to be clean, except for 719 that are XXXXX

States are mostly clean except for 2 in AR, 719 that are XXXXX and 29 null.

