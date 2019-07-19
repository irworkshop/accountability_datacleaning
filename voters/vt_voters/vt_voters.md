## Vermont voter registation

Obtained via public records request from Vermont Secretary of State in Pipe-delimited format.  
See field_listing.xls for full record descriptions.  

Record count: 487,210  


--CREATE ZIP_LOOKUP TO FIX INCONSISTENCIES IN ZIPCODE  
CREATE TABLE ZIP_LOOKUP AS  
SELECT LEGALADDRESSZIP, UPPER(LEGALADDRESSZIP), COUNT(*)  
FROM VT_VOTERS  
GROUP BY 1  
ORDER BY 1  


--INCONSISTENT CASE IN NAME FIELDS NEW VERSIONS TO FIX ALONG WITH A FEW STRAY TYPOS  
Create table vt_voters_out as  
Select VoterID, LastName_CLEAN AS LASTNAME, FirstName_CLEAN AS FIRSTNAME, MiddleName_CLEAN AS MIDDLENAME,
Suffix AS SUFFIX, LegalAddressLine1 AS ADDRESS1, LegalAddressLine2 AS ADDRESS2, 
LegalAddressCity AS CITY, LegalAddressState AS STATE, RESZIP_CLEAN AS ZIP5, YearofBirth,
DateofRegistration as REG_DATE, YEAR, DatelastVoted as LASTVOTEDATE, COUNTY,STATUS,TOWNOFREGISTRATION FROM VT_VOTERS  

--UPDATE RESZIP_CLEAN WITH FIXED ZIPS  
UPDATE VT_VOTERS
set RESZIP_CLEAN = (select y.LEGALADDRESSZIP from ZIP_LOOKUP as y where y.LEGALADDRESSZIP=VT_VOTERS.LEGALADDRESSZIP)  

--EXPORT FOR UPLOAD  
Create table vt_voters_out as  
Select VoterID, LastName_CLEAN AS LASTNMAE, FirstName_CLEAN AS FIRSTNAME, MiddleName_CLEAN AS MIDDLENAME,
Suffix AS SUFFIX, LegalAddressLine1 AS ADDRESS1, LegalAddressLine2 AS ADDRESS2, 
LegalAddressCity AS CITY, LegalAddressState AS STATE, RESZIP_CLEAN AS ZIP5, YearofBirth,
DateofRegistration as REG_DATE, YEAR, DatelastVoted as LASTVOTEDATE, COUNTY,STATUS,TOWNOFREGISTRATION FROM VT_VOTERS  

**Known issues:**

Birthyears that are invalid and several out of range, including 49,257 for 1900.  
Year, based on registration date has 8 invalid entries and several out of range, including 65,745 for 1900.  
114,377 ZIPs are blank.  

 
