## Missouri voters processing notes

Data was acquired via public records request in tab-delimited format.  

Record count: 4,210,231  

--ADD NEW COLUMNS  
alter table mo_voters add column DOBYEAR;  
ALTER TABLE mo_voters ADD COLUMN YEAR;  
ALTER TABLE mo_voters ADD COLUMN ZIP5;  
--UPDATE NEW COLUMNS  
UPDATE MO_VOTERS SET DOBYEAR=SUBSTR(BIRTHDATE, 7,4);  
UPDATE MO_VOTERS SET YEAR=SUBSTR(RegistrationDate,7,4);  
UPDATE MO_VOTERS SET ZIP5=SUBSTR(ResidentialZipCode, 1,5)  


--EXPORT FOR UPLOAD
CREATE TABLE MO_VOTERS_OUT AS 
select County, VoterID, FirstName, MiddleName, LastName, Suffix, HouseNumber, HouseSuffix, PreDirection, StreetName, StreetType, PostDirection, UnitType,UnitNumber, NonStandardAddress, 
ResidentialCity as CITY, ResidentialState as STATE, ZIP5, Birthdate, RegistrationDate, Precinct, Split, Township, Ward, "Congressional-New" as CONGRESSIONAL, 
"Legislative-New" as LEGISLATIVE, "StateSenate-New" as STATESENATE,YEAR
FROM mo_voters

**Known issues:**  
DOBYEAR span: 1800 to 2018  
YEAR span: Several records with clearly invalid date info such as 01/01/0418  
Cities appear to be clean, except for 719 that are XXXXX.  
States are mostly clean except for 2 in AR, 719 that are XXXXX and 29 null.  

