##Rhode Island voter registration data

Obtained via public records request Oct. 2018  
Number of records: 792,686

NOTE: Data starts on line 2. Line one is: "Note: Pipe is the delimiter" 

--CREATE TABLE  
CREATE TABLE 'RI_VOTERS' ( 'VOTERID', 'STATUSCODE', 'LASTNAME', 'FIRSTNAME', 'MIDDLENAME', 'PREFIX', 'SUFFIX',
'STREETNUMBER', 'STREETNAME', 'STREETNAME2', 'ZIPCODE', 'ZIP4CODE', 'CITY', 'UNIT', 'SUFFIXA', 'SUFFIXB', 
'STATE', 'CARRIERCODE', 'POSTALCITY', 'MAILINGSTREETNUMBER', 'MAILINGSTREETNAME1', 'MAILINGSTREETNAME2', 
'MAILINGZIPCODE', 'MAILINGCITY', 'MAILINGUNIT', 'MAILINGSUFFIXA', 'MAILINGSUFFIXB', 'MAILINGSTATE', 
'MAILINGCOUNTRY', 'MAILINGCARRIERCODE', 'PARTYCODE', 'SPECIALSTATUSCODE', 'DATEEFFECTIVE', 'DATEOFPRIVILEGE', 
'SEX', 'DATEACCEPTED', 'DATEOFSTATUSCHANGE', 'YEAROFBIRTH', 'OFFREASONCODE', 'DATELASTACTIVE', 'CONGRESSIONALDISTRICT', 
'STATESENATEDISTRICT', 'STATEREPDISTRICT', 'PRECINCT', 'WARD/COUNCIL', 'WARDDISTRICT', 'SCHOOLCOMMITTEEDISTRICT', 
'SPECIALDISTRICT', 'FIREDISTRICT', 'PHONENUMBER', 'EMAIL', 'filler' )  

--CREATE AND UPDATE YEAR  
ALTER TABLE RI_VOTERS add column YEAR;  
UPDATE RI_VOTERS SET YEAR=SUBSTR(DATEEFFECTIVE,7,4)  

--EXPORT FOR UPLOAD
CREATE TABLE RI_VOTERS_OUT AS  
SELECT VOTERID, STATUSCODE, LASTNAME, FIRSTNAME, MIDDLENAME, PREFIX, SUFFIX, STREETNUMBER,
STREETNAME, STREETNAME2, ZIPCODE AS ZIP5, CITY, UNIT, SUFFIXA, SUFFIXB, STATE, CARRIERCODE,
POSTALCITY, PARTYCODE, SPECIALSTATUSCODE, DATEEFFECTIVE, YEAR, DATEOFPRIVILEGE, SEX, DATEACCEPTED,
DATEOFSTATUSCHANGE, YEAROFBIRTH, OFFREASONCODE, DATELASTACTIVE, CONGRESSIONALDISTRICT,
STATESENATEDISTRICT, STATEREPDISTRICT, PRECINCT, "WARD/COUNCIL" AS WARDCOUNCIL, WARDDISTRICT, SCHOOLCOMMITTEEDISTRICT, 
SPECIALDISTRICT, FIREDISTRICT, PHONENUMBER, EMAIL
FROM RI_VOTERS

**Known issues**  
19 records have EFFECTIVEDATES in the 1800s  
82 records are have EFFECTIVEDATES in 2020  
YEAROFBIRTH has records listed in 1800  


