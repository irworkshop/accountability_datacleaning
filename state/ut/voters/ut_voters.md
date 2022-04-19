## UT_VOTERS data process

Data obtained via open records request

--ADD NEW COLUMNS

ALTER TABLE UT_VOTERS ADD COLUMN ZIP5;  
ALTER TABLE UT_VOTERS ADD COLUMN YEAR;  
ALTER TABLE UT_VOTERS ADD COLUMN STATE_CLEAN;  
ALTER TABLE UT_VOTERS ADD COLUMN CITY_CLEAN;  

--UPDATE NEW COLUMNS

UPDATE UT_VOTERS SET ZIP5=SUBSTR(ZIP,1,5);  
UPDATE UT_VOTERS SET YEAR=SUBSTR(RegistrationDate,length(RegistrationDate)-3,4);  
UPDATE UT_VOTERS SET YEAR="" WHERE YEAR="0 AM";  
UPDATE UT_VOTERS SET STATE_CLEAN="UT";  

--CREATE CITY LOOKUP TABLE

CREATE TABLE CITY_LOOKUP AS
SELECT CITY, UPPER(CITY) AS CITY_CLEAN, COUNT(*)
FROM UT_VOTERS
GROUP BY 1
ORDER BY 1;

--UPDATE CITY_CLEAN BASED ON LOOKUP TABLE

UPDATE UT_VOTERS  
set CITY_CLEAN = (select y.CITY_CLEAN from CITY_LOOKUP as y where y.CITY=UT_VOTERS.CITY)

--EXPORT FOR UPLOAD

CREATE TABLE UT_VOTERS_OUT as  
SELECT VoterID, LastName, FirstName, MiddleName, NameSuffix, Status, PermanentAbsentee, UOCAVA, RegistrationDate, OriginalRegistrationDate, Party, Phone, MailingAddress, CountyID, Precinct, HouseNumber, HouseNumberSuffix, DirectionPrefix,Street, DirectionSuffix ,StreetType, UnitType, UnitNumber, City, CITY_CLEAN, STATE_CLEAN, Zip, ZIP5, YEAR
FROM UT_VOTERS


**Known issues**

A few rows have stray " - clean before import  
DOB is not in the data  
State was not in original data. Added and verified against ZIP  
Mailing_city_state_zip throwing import error - not included

1,287 records have a timestamp and no date for registration data, year is BLANK in those cases. In other cases, the date is out of range, but the year was not change.  
