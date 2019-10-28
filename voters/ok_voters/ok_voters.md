## Oklahoma voter data processing

Number of records: 2,120,475

See readme.pdf for more info.

-- CREATE CITY LOOKUP table  
Create TABLE ok_city_lookup as  
Select city, UPPER(CITY) AS CITY_CLEAN, COUNT(*)  
FROM ok_voters  
GROUP BY 1  
ORDER BY 1  


-- ADD COLUMNS  
ALTER TABLE OK_VOTERS ADD column BIRTHYEAR;  
ALTER TABLE OK_VOTERS ADD column YEAR;  
ALTER TABLE OK_VOTERS ADD column BLDGNUM_CLEAN;  
ALTER TABLE OK_VOTERS ADD column ZIP5;  
ALTER TABLE OK_VOTERS ADD column STATE;  
ALTER TABLE OK_VOTERS ADD column CITY_CLEAN;  

--UPDATE FIELDS  
UPDATE OK_VOTERS SET BIRTHYEAR=SUBSTR(DATEOFBIRTH,7,4);  
UPDATE OK_VOTERS SET YEAR=SUBSTR(ORIGINALREGISTRATION,7,4);  
UPDATE OK_VOTERS SET BLDGNUM_CLEAN=BLDGNUM;  
UPDATE OK_VOTERS SET BLDGNUM_CLEAN=BLDGNUM||CITY WHERE CITY <"ACHILLE" AND CITY>"" ;  
UPDATE OK_VOTERS SET STATE="OK";  
UPDATE OK_VOTERS SET ZIP5=SUBSTR(ZIP,1,5);  
UPDATE OK_VOTERS set CITY_CLEAN = (select y.CITY_CLEAN from OK_CITY_LOOKUP as y where y.CITY=OK_VOTERS.CITY);

--EXPORT  
CREATE TABLE OK_VOTERS_OUT as
SELECT Precinct, LastName, FirstName, MiddleName, Suffix, VoterID, PolitalAff, Status, StreetNum, StreetDir, StreetName, StreetType, BldgNum, City, Zip, DateOfBirth, OriginalRegistration, MailStreet1, MailStreet2, MailCity, MailState, MailZip, Muni, MuniSub, School, SchoolSub, TechCenter, TechCenterSub, CountyComm, VoterHist1, HistMethod1, VoterHist2, HistMethod2, VoterHist3, HistMethod3, VoterHist4, HistMethod4, VoterHist5, HistMethod5, VoterHist6, HistMethod6, VoterHist7, HistMethod7, VoterHist8, HistMethod8, VoterHist9, HistMethod9, VoterHist10, HistMethod10, BIRTHYEAR, YEAR, BLDGNUM_CLEAN, ZIP5, STATE, CITY_CLEAN, CITY_EST_FLAG AS CITY_ZIP_FLAG  
FROM OK_VOTERS;

**Known issues:**  
Many of the addresses are descriptive, such as "2 miles down Rte 3 on left" rather than street addresses. Where possible we have updated based on postal code.    
Some years are out of range - early 1900s. YEAR is missing for 246,423 records.  
Some birthyear are out of range or incorrect. BIRTHYEAR is missing for 6,250 records.  
City_clean fills in cities where possible from ZIPcode. City_clean is missing for 14,454 records.  
ZIP5 is missing for 20,302 records.  
CITY_ZIP_FLAG indicates whether CITY_CLEAN OR ZIP5 were from U.S.P.S. data. C=CITY is pulled based on ZIP5, Z=ZIP5 is pulled based on city.  



