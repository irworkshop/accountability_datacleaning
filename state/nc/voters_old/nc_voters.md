## North Carolina voter registration processing

Number of records: 8,176,835

-- CREATE CITY LOOKUP TABLE TO CLEAN INCONSISTENCIES  
create table nc_city_lookup as  
select res_city_desc, upper(res_city_desc) as CITY_CLEAN, count(*)  
from nc_voters  
group by 1  
order by 1  

--ADD NEW FIELDS
ALTER TABLE nc_voters add column YEAR;  
ALTER TABLE nc_voters add column CITY_CLEAN; 
--UPDATE YEAR
UPDATE nc_voters SET YEAR=SUBSTR(REGSTR_DT,7,4);

UPDATE NC_VOTERS set CITY_CLEAN = (select y.CITY_CLEAN from nc_city_lookup as y where y.res_city_desc=NC_VOTERS.res_city_desc)

--EXPORT FOR UPLOAD
create table nc_voters_out as
SELECT county_id, county_desc, voter_reg_num, status_cd, voter_status_desc, reason_cd, voter_status_reason_desc, absent_ind, name_prefx_cd, last_name, first_name, 	middle_name, name_suffix_lbl, res_street_address, res_city_desc, state_cd, zip_code, mail_addr1, mail_addr2, mail_addr3, mail_addr4, mail_city, mail_state, mail_zipcode, 	full_phone_number, race_code, ethnic_code, party_cd, gender_code, birth_age, birth_state, registr_dt, precinct_abbrv, precinct_desc, municipality_abbrv, municipality_desc, 	ward_abbrv, ward_desc, cong_dist_abbrv, super_court_abbrv, judic_dist_abbrv, nc_senate_abbrv, nc_house_abbrv, county_commiss_abbrv, county_commiss_desc, township_abbrv, 	township_desc, school_dist_abbrv, school_dist_desc, fire_dist_abbrv, fire_dist_desc, water_dist_abbrv, water_dist_desc, sewer_dist_abbrv, sewer_dist_desc, sanit_dist_abbrv, 	sanit_dist_desc, rescue_dist_abbrv, rescue_dist_desc, munic_dist_abbrv, munic_dist_desc, dist_1_abbrv, dist_1_desc, dist_2_abbrv, dist_2_desc, confidential_ind, 	birth_year, ncid, vtd_abbrv, vtd_desc, YEAR, CITY_CLEAN
FROM nc_voters


**Known issues**
967,449 addresses have been removed based on these reason:

ADMINISTRATIVE	1875  
DECEASED	440912  
DUPLICATE	4711  
FELONY CONVICTION	23303  
FELONY SENTENCE COMPLETED	7230  
MOVED FROM COUNTY	104517  
MOVED FROM STATE	160724  
MOVED WITHIN STATE	11973  
REMOVED AFTER 2 FED GENERAL ELECTIONS IN INACTIVE STATUS	196605  
REMOVED DUE TO SUSTAINED CHALLENGE	1576  
REQUEST FROM VOTER	5224  
TEMPORARY REGISTRANT	8797  
UNVERIFIED	2  


