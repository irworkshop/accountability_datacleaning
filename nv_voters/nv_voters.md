##Nevada voter registration

Data acquired via public records request in October 2018 in csv format.  
See NEVADA DATA FORMAT.PDF for more information.    

Number of records: 1,778,501

--CREATE TABLE  
CREATE TABLE 'NV_VOTERS' ( 'VOTERID, 'COUNTY', 'FIRSTNAME', 'MIDDLENAME', 'LASTNAME', 'SUFFIX', 'DOB', 
'REGDATE', 'ADDRESS1', 'ADDRESS2', 'CITY', 'STATE', 'ZIP', 'PHONE', 'PARTY', 'CONGDIST', 'SENATEDIST', 
'ASSYDIST', 'EDDIST', 'REGENTDIST', 'PRECINCT', 'COUNTY_STATUS', 'VOTERID', 'IDREQUIRED' )  


--CREATE NEW FIELDES
alter table nv_voters add column CITY_CLEAN;  
alter table nv_voters add column BIRTHYEAR;  
alter table nv_voters add column YEAR;  
--UPDATE NEW FIELDS  
update nv_voters set BIRTHYEAR=SUBSTR(DOB,7,4);  
update nv_voters set YEAR=SUBSTR(REGDATE,7,4);  

--CREATE CITY_LOOKUP  
CREATE TABLE CITY_LOOKUP AS  
select city,UPPER(CITY) as CITY_CLEAN, count(*)  
FROM NV_VOTERS  
GROUP BY 1  
ORDER BY 1  

--UPDATE DATA BASED ON CITY_LOOKUP
UPDATE NV_VOTERS set CITY_CLEAN = (select y.CITY_CLEAN from CITY_LOOKUP as y where y.CITY=NV_VOTERS.CITY);  

--EXPORT TABLE FOR UPLOAD
CREATE TABLE NV_VOTERS_OUT AS SELECT VOTERID, COUNTY, FIRSTNAME, MIDDLENAME, LASTNAME, SUFFIX, DOB, REGDATE, ADDRESS1, ADDRESS2, CITY_CLEAN AS CITY, STATE, ZIP, PHONE, PARTY, CONGDIST, SENATEDIST, ASSYDIST, EDDIST, REGENTDIST, PRECINCT, COUNTY_STATUS, CNTYVOTERID, IDREQUIRED, BIRTHYEAR, YEAR from NV_VOTERS



**Known data issues**  
CITY and STATE missing from 18,067 records  
ZIP is missing from 18,068 records. ZIP is 00000 in another 2,445 records  
A few ZIPs are out of range for NV  
A few BIRTHYEARs that seem out of range on the low end (1900, 1902,etc...)  
1,300+ registration years that are out of range on the low end.  


