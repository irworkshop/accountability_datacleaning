## New Hampshire campaign contributions

Number of records:

Note: Only contributions starting in 2016 are available electronically.


--ADD NEW COLUMNS  
alter table nh_contribs add column YEAR;  
alter table nh_contribs add column ZIP5;  
alter table nh_contribs add column CITY_CLEAN;  
alter table nh_contribs add column STATE_CLEAN; 
alter table nh_contribs add column UT_FLAG;  

--UPDATE NEW FIELDS
UPDATE nh_contribs SET ZIP5=substr(Contributoraddress,instr(Contributoraddress,'-')-5,5)  
where instr(Contributoraddress,'-')=length(contributorAddress)-4;  

UPDATE nh_contribs SET ZIP5=substr(Contributoraddress,length(Contributoraddress)-4,5)  
where zip5 is null;  

UPDATE nh_contribs SET ZIP5=substr(Contributoraddress,instr(Contributoraddress,'-')-5,5)  
where instr(Contributoraddress,'-')=length(contributorAddress)-4;  

UPDATE nh_contribs set state_clean=substr(Contributoraddress,instr(Contributoraddress,'-')-8,2)  
where instr(Contributoraddress,'-')=length(contributorAddress)-4;  

UPDATE nh_contribs set state_clean="NH"  
where townstate="N" and state_clean is null;  

UPDATE nh_contribs set UT_FLAG="Y"  
where contributorname LIKE "UNITEMIZED";  

UPDATE nh_contribs set CITY_CLEAN = (select y.CLEANCITY from city_extract  as y   
where y.ADDRESS=nh_contribs.CONTRIBUTORADDRESS);  

UPDATE nh_contribs
SET YEAR=SUBSTR(TRANSACTIONDATE,LENGTH(TRANSACTIONDATE)-15,4)
WHERE SUBSTR(TRANSACTIONDATE,5,1)="/"
