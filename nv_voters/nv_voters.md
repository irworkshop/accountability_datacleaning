##Nevada voter registration

Data acquired via public records request in Oct. 2018 in csv

Number of records: 1,778,501

**Create table**

`CREATE TABLE `NV_VOTERS` ( `VOTERID` , `COUNTY` , `FIRSTNAME` , `MIDDLENAME` , `LASTNAME` , `SUFFIX` , `DOB` , 
`REGDATE` , `ADDRESS1` , `ADDRESS2` , `CITY` , `STATE` , `ZIP` , `PHONE` , `PARTY` , `CONGDIST` , `SENATEDIST` , 
`ASSYDIST` , `EDDIST` , `REGENTDIST` , `PRECINCT` , `COUNTY_STATUS` , `VOTERID` , `IDREQUIRED` )`

**Create lookup table for city to fix inconsistencies**

`CREATE TABLE CITY_LOOKUP AS
select city,UPPER(CITY) as CITY_CLEAN, count(*)
FROM NV_VOTERS
GROUP BY 1
ORDER BY 1`

**Update main table using cleaned city lookup data:**

`UPDATE NV_VOTERS
set CITY_CLEAN = (select y.CITY_CLEAN from CITY_LOOKUP as y where y.CITY=NV_VOTERS.CITY)`


CITY and STATE missing from 18,067 records

**Create new fields and extract year from dates**

`alter table nv_voters add column CITY_CLEAN;
alter table nv_voters add column BIRTHYEAR;
alter table nv_voters add column YEAR;
update nv_voters set BIRTHYEAR=SUBSTR(DOB,7,4);
update nv_voters set YEAR=SUBSTR(REGDATE,7,4)`


ZIP missing from 18,068 records, 00000 in another 2,445 records
A few ZIPs are out of range for NV.

**Export**

`CREATE TABLE NV_VOTERS_OUT AS SELECT VOTERID, COUNTY, FIRSTNAME, MIDDLENAME, LASTNAME, SUFFIX, DOB, REGDATE, ADDRESS1, ADDRESS2, CITY_CLEAN AS CITY, STATE, ZIP, PHONE, PARTY, CONGDIST, SENATEDIST, ASSYDIST, EDDIST, REGENTDIST, PRECINCT, COUNTY_STATUS, CNTYVOTERID, IDREQUIRED, BIRTHYEAR, YEAR from NV_VOTERS`
