## Kansas voter registration processing notes

Data obtained via public records request in January 2019.

**Created city_lookup table to clean cities. All cities longer than 9 characters were cut off.**

`create table city_lookup as
select text_res_city, UPPER(text_res_city) as res_city_clean, count(*)
from ks_voters
group by 1
order by 1`

Using a mix of check against other data, openref and viewing, get the city_lookup table as clean as we can.

**Insert fields for clean city and year (of registration date)**

`ALTER TABLE ks_voters ADD COLUMN RES_CITY_CLEAN;
ALTER TABLE ks_voters ADD COLUMN YEAR;`


**Pull year from registration date:**

`UPDATE KS_VOTERS
set YEAR = SUBSTR(DATE_OF_REGISTRATION,7,4)`

**Fix cities using cities lookup**

`UPDATE KS_VOTERS
set RES_CITY_CLEAN = (select y.RES_CITY_CLEAN from CITY_LOOKUP as y where y.TEXT_RES_CITY=KS_VOTERS.TEXT_RES_CITY)`

**Know data issues:**
There are dates of birth that are out of range or invalid.

**Export data for upload:**

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
