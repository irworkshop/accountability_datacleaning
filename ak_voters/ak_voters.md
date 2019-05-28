## Alaska voter registration processing notes

Obtained via public records request in Nov. 2018 from Alaska Secretary of State. See documentation for more information.

Total records: 574,392

**Add new fields**

`alter table ak_voters add column STATE;
ALTER TABLE AK_voters ADD COLUMN YEAR;
ALTER TABLE ak_voters ADD COLUMN UNREACHABLE`

**Update new fields**

`Update AK_VOTERS set STATE="AK";
Update AK_VOTERS set YEAR=SUBSTR(REGDATE,7,4);
UPDATE AK_VOTERS SET UNREACHABLE="Y"
WHERE UN='*' OR UN='?'`

**Known problems**

If "Y" in unreachable - address could not be verified or voter inactive
Address listed as "private" for 9,922

**Export syntax**

`create table AK_VOTERS_OUT as
Select  PARTY, "D/P" AS District_Precinct, LASTNAME, FIRSTNAME, MIDDLENAME, SUFFIXNAME, "ASCENSION#" as ASCENSION, REGDATE, ORGREGDATE, DISTDATE, RESIDENCEADDRESS, RESIDENCECITY, RESIDENCEZIP as ZIP5, GENDER, STATE, YEAR, UNREACHABLE
from AK_VOTERS` 
