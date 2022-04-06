## Florida voter data processing notes

Data obtained via public records request in Dec. 2018  
Data comes in county-by-county tab-delimited files. See record layout for more information  

Number of records: 1,4195,961  


--CREATE TABLE 
CREATE TABLE "fl_voters" (
	"County Code"	TEXT,
	"Voter ID"	TEXT,
	"Lastname"	TEXT,
	"Suffix"	TEXT,
	"Firstname"	TEXT,
	"Middle"	TEXT,
	"Exempt"	TEXT,
	"Address1"	TEXT,
	"Address2"	TEXT,
	"City"	TEXT,
	"State"	TEXT,
	"ZIP"	TEXT,
	"Mailaddress1"	TEXT,
	"Mailaddress2"	TEXT,
	"Mailaddress3"	TEXT,
	"mail_city"	TEXT,
	"mail_state"	TEXT,
	"mail_zip"	TEXT,
	"mail_country"	TEXT,
	"gender"	TEXT,
	"race"	TEXT,
	"dob"	TEXT,
	"reg_date"	TEXT,
	"party"	TEXT,
	"precinct"	TEXT,
	"precinct_group"	TEXT,
	"precinct_split"	TEXT,
	"precinct_suffix"	TEXT,
	"Voter_status"	TEXT,
	"Cong_dist"		TEXT,
	"House_dist"	TEXT,
	"Senate_dist"	TEXT,
	"County_comm_dist"	TEXT,
	"School_bd_dist"	TEXT,
	"Daytime_area_code"	TEXT,
	"Daytime_phone"	TEXT,
	"Daytime_ext"	TEXT,
	"email_address"	TEXT);
	
--ADD NEW COLUMNS  
ALTER TABLE FL_VOTERS ADD COLUMN ZIP5;  
ALTER TABLE FL_VOTERS ADD COLUMN YEAR;  
ALTER TABLE FL_VOTERS ADD COLUMN BIRTHYEAR;  
ALTER TABLE FL_VOTERS ADD COLUMN CITY_CLEAN;  
ALTER TABLE FL_VOTERS ADD COLUMN RACE_TXT;   

--UPDATE NEW COLUMNS  
UPDATE FL_VOTERS SET ZIP5=SUBSTR(ZIP,1,5);  
UPDATE FL_VOTERS SET ZIP5=NULL WHERE ZIP5="99999";  
UPDATE FL_VOTERS SET ZIP5=NULL WHERE ZIP5="*";  
UPDATE FL_VOTERS SET YEAR=SUBSTR(reg_date,7,4);    
UPDATE FL_VOTERS SET BIRTHYEAR=SUBSTR(dob,7,4);    
UPDATE FL_VOTERS set RACE_TXT = (select y.Race_txt from race_codes as y where y.Race_code=FL_VOTERS.race);    

--CREATE CITY LOOKUP TABLE  
CREATE TABLE CITY_LOOKUP AS SELECT CITY, UPPER(CITY) AS CITY_CLEAN, COUNT(*) FROM UT_VOTERS GROUP BY 1 ORDER BY 1;  

--EXPORT FOR OUTPUT 
CREATE TABLE FL_VOTERS_OUT AS  
SELECT	County Code, Voter ID, Lastname, Suffix, Firstname, Middle, Exempt, Address1, Address2, City, CITY_CLEAN, State, ZIP, ZIP5, Mailaddress1, Mailaddress2, Mailaddress3, mail_city, mail_state, mail_zip, mail_country, gender, race, RACE_TXT, dob, BIRTHYEAR, reg_date, YEAR, party, precinct, precinct_group, precinct_split, precinct_suffix, 	Voter_status, Cong_dist, House_dist, Senate_dist, County_comm_dist, School_bd_dist, Daytime_area_code||Daytime_phone AS PHONE, Daytime_ext, email_address
FROM FL_VOTERS  


**Known issues**
More than 63,000 dates of birth are blank 
Some birthyears are out of range  


