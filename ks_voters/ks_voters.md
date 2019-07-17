## Kansas voter registration processing notes

Data obtained via public records request in January 2019.
Record count: 1,842,596

--ADD NEW FIELDS
ALTER TABLE ks_voters ADD COLUMN RES_CITY_CLEAN;  
ALTER TABLE ks_voters ADD COLUMN YEAR;  
--UPDATE YEAR COLUMN  
UPDATE KS_VOTERS set YEAR = SUBSTR(DATE_OF_REGISTRATION,7,4)  

--CREATE CITY_LOOKUP TABLE  
create table city_lookup as  
select text_res_city, UPPER(text_res_city) as res_city_clean, count(*)  
from ks_voters  
group by 1  
order by 1  

-- UPDATE TABLE BASED ON CITY_LOOKUP  
UPDATE KS_VOTERS set RES_CITY_CLEAN = (select y.RES_CITY_CLEAN from CITY_LOOKUP as y where y.TEXT_RES_CITY=KS_VOTERS.TEXT_RES_CITY)  

--EXPORT FOR UPLOAD
`CREATE TABLE KS_VOTERS_OUT AS
SELECT db_logid,cde_registrant_status,cde_name_title as TITLE,text_name_first as FIRSTNAME,
text_name_middle AS MIDDLENAME,text_name_last AS LASTNAME,cde_name_suffix AS SUFFIX, 
cde_gender AS GENDER, text_registrant_id AS REGID,text_res_address_nbr AS ADDRESS_NUMBER,
text_res_address_nbr_suffix AS ADDRESS_SUFFIX, cde_street_dir_prefix AS ADDRESS_DIR,
text_street_name AS ADDRESS_STREET,cde_street_type AS ADDRESS_STREET_TYPE,
cde_street_dir_suffix AS ADDRESS_DIR_SUFFIX, cde_res_unit_type AS UNIT_TYPE,text_res_unit_nbr AS UNIT_NUM,
RES_CITY_CLEAN AS RES_CITY,cde_res_state AS RES_STATE, text_res_zip5 AS ZIP5,
date_of_birth AS DATE_OF_BIRTH,date_of_registration AS REG_DATE,text_phone_area_code||text_phone_exchange||text_phone_last_four AS PHONE,YEAR
FROM KS_VOTERS`


**Know data issues:**
There are dates of birth that are out of range or invalid.

