# DB Queries for nonprofit data

These queries are run against a postgres database built according to the [irs-xml-database](https://github.com/jsfenfen/990-xml-database) repo. They are used to extract the top paid employees and schedule I grants. 


## Employees

### From form 990

Make a temporary address lookup table for easier joining:

		DROP TABLE if exists address_table;
	
	
		SELECT  
		   return_returnheader990x_part_i.ein,
		   return_returnheader990x_part_i.object_id,
	       return_returnheader990x_part_i."RtrnHdr_TxPrdEndDt",
	       return_returnheader990x_part_i."RtrnHdr_TxYr",
	       return_returnheader990x_part_i."BsnssNm_BsnssNmLn1Txt",
	       return_returnheader990x_part_i."BsnssNm_BsnssNmLn2Txt",
	       return_returnheader990x_part_i."BsnssOffcr_PrsnNm",
	       return_returnheader990x_part_i."BsnssOffcr_PrsnTtlTxt",
	       return_returnheader990x_part_i."BsnssOffcr_PhnNm",
	       return_returnheader990x_part_i."BsnssOffcr_EmlAddrssTxt",
	       return_returnheader990x_part_i."USAddrss_AddrssLn1Txt",
	       return_returnheader990x_part_i."USAddrss_AddrssLn2Txt",
	       return_returnheader990x_part_i."USAddrss_CtyNm",
	       return_returnheader990x_part_i."USAddrss_SttAbbrvtnCd",
	       return_returnheader990x_part_i."USAddrss_ZIPCd",
	       return_returnheader990x_part_i."FrgnAddrss_AddrssLn1Txt",
			return_returnheader990x_part_i."FrgnAddrss_AddrssLn2Txt",
			return_returnheader990x_part_i."FrgnAddrss_CtyNm",
			return_returnheader990x_part_i."FrgnAddrss_PrvncOrSttNm",
			return_returnheader990x_part_i."FrgnAddrss_CntryCd"      
		INTO address_table
		FROM return_returnheader990x_part_i;

Index it so the queries don't take forever

	DROP INDEX IF EXISTS xx_990_address_oid_ein;
	CREATE INDEX xx_990_address_oid_ein ON address_table (object_id, ein);


Make a temporary table with the stuff to pull from Part VII Section A

	DROP TABLE IF EXISTS tmp_990_employees;
	
	SELECT address_table.*,
       "PrsnNm",
       "TtlTxt",
       "RprtblCmpFrmOrgAmt" as "CmpnstnAmt"
    INTO tmp_990_employees
	FROM return_Frm990PrtVIISctnA
	LEFT JOIN address_table ON return_Frm990PrtVIISctnA.ein = address_table.ein
	AND return_Frm990PrtVIISctnA.object_id=address_table.object_id;




Copy back with:



	\copy tmp_990_employees to '/tmp/990_employees.csv' with csv header;




### 990EZ


	DROP TABLE IF EXISTS tmp_990ez_employees;
	
	SELECT address_table.*,
       "PrsnNm",
       "TtlTxt",
       "CmpnstnAmt" 
   INTO tmp_990EZ_employees
   FROM return_EZOffcrDrctrTrstEmpl
	LEFT JOIN address_table ON return_EZOffcrDrctrTrstEmpl.ein = address_table.ein
	AND return_EZOffcrDrctrTrstEmpl.object_id= address_table.object_id;


And then move with: 

 	\copy tmp_990ez_employees to '/tmp/990EZ_employees.csv' with csv header;
 	


### 990PF

Get PF values

	DROP TABLE IF EXISTS tmp_990PF_employees;
	
	SELECT address_table.*,
	       "OffcrDrTrstKyEmpl_PrsnNm" AS "PrsnNm",
	       "OffcrDrTrstKyEmpl_TtlTxt" AS "TtlTxt",
	       "OffcrDrTrstKyEmpl_CmpnstnAmt" AS "CmpnstnAmt" 
	INTO tmp_990PF_employees
	FROM return_PFOffcrDrTrstKyEmpl
	LEFT JOIN address_table ON return_PFOffcrDrTrstKyEmpl.ein = address_table.ein
	AND return_PFOffcrDrTrstKyEmpl.object_id= address_table.object_id;



	
copy it with: 

	\copy tmp_990PF_employees to '/tmp/990PF_employees.csv' with csv header;

## Schedule I

The schedule I variables are defined in the [irsx documentation](http://www.irsx.info/metadata/groups/SkdIRcpntTbl.html).

Here's a query to a temp table


	DROP TABLE IF EXISTS grants;
	
	SELECT 
           address_table."RtrnHdr_TxPrdEndDt",
           address_table."RtrnHdr_TxYr",
           address_table."BsnssNm_BsnssNmLn1Txt" as "Donor_BsnssNmLn1",
           address_table."BsnssNm_BsnssNmLn2Txt" as "Donor_BsnssNmL21",
           address_table."BsnssOffcr_PrsnNm" as "Donor_BsnssOffcr_PrsnNm",
           address_table."BsnssOffcr_PrsnTtlTxt" as "Donor_ BsnssOffcr_PrsnTtlTxt",
           address_table."BsnssOffcr_PhnNm" as "Donor_ BsnssOffcr_PhnNm" ,
           address_table."BsnssOffcr_EmlAddrssTxt"  as "Donor_ BsnssOffcr_EmlAddrssTxt" ,
           address_table."USAddrss_AddrssLn1Txt" as "Donor_AddrssLn1Txt",
           address_table."USAddrss_AddrssLn2Txt" as "Donor_AddrssLn2Txt",
           address_table."USAddrss_CtyNm" as "Donor_CtyNm",
           address_table."USAddrss_SttAbbrvtnCd" as "Donor_SttAbbrvtnCd",
           address_table."USAddrss_ZIPCd" as "Donor_ZIPCd",
           address_table."FrgnAddrss_AddrssLn1Txt" as "Donor_FrgnAddrss_AddrssLn1Txt",
           address_table."FrgnAddrss_AddrssLn2Txt" as "Donor_FrgnAddrss_AddrssLn2Txt",
           address_table."FrgnAddrss_CtyNm" as "Donor_FrgnAddrss_CtyNm",
           address_table."FrgnAddrss_PrvncOrSttNm" as "Donor_PrvncOrSttNm",
           address_table."FrgnAddrss_CntryCd" as "Donor_CntryCd",
	       return_SkdIRcpntTbl.* 
	INTO TEMP TABLE grants
	FROM return_SkdIRcpntTbl
	LEFT JOIN address_table 
	ON return_SkdIRcpntTbl.object_id = address_table.object_id
	AND return_SkdIRcpntTbl.ein = address_table.ein;
	



Then copy to local with \copy: 

	\copy grants to '/tmp/skedigrants.csv' with csv header;
	


## Form PF Part XV "Grant or Contribution Paid During Year"

See the IRSX documentation for form PPF Part XV [Grant or Contribution Paid During Year](http://www.irsx.info/metadata/groups/PFGrntOrCntrbtnPdDrYr.html)

Note that there's also a different section for grants of contributions approved for future years that we aren't using to avoid double-counting; see [the form instructions](https://www.irs.gov/instructions/i990pf#idm140486306377296) for (not much) more info. 


	
	DROP TABLE IF EXISTS pfgrants;
	
	SELECT 
           address_table."RtrnHdr_TxPrdEndDt",
           address_table."RtrnHdr_TxYr",
           address_table."BsnssNm_BsnssNmLn1Txt" as "Donor_BsnssNmLn1",
           address_table."BsnssNm_BsnssNmLn2Txt" as "Donor_BsnssNmL21",
           address_table."BsnssOffcr_PrsnNm" as "Donor_BsnssOffcr_PrsnNm",
           address_table."BsnssOffcr_PrsnTtlTxt" as "Donor_ BsnssOffcr_PrsnTtlTxt",
           address_table."BsnssOffcr_PhnNm" as "Donor_ BsnssOffcr_PhnNm" ,
           address_table."BsnssOffcr_EmlAddrssTxt"  as "Donor_ BsnssOffcr_EmlAddrssTxt" ,
           address_table."USAddrss_AddrssLn1Txt" as "Donor_AddrssLn1Txt",
           address_table."USAddrss_AddrssLn2Txt" as "Donor_AddrssLn2Txt",
           address_table."USAddrss_CtyNm" as "Donor_CtyNm",
           address_table."USAddrss_SttAbbrvtnCd" as "Donor_SttAbbrvtnCd",
           address_table."USAddrss_ZIPCd" as "Donor_ZIPCd",
           address_table."FrgnAddrss_AddrssLn1Txt" as "Donor_FrgnAddrss_AddrssLn1Txt",
           address_table."FrgnAddrss_AddrssLn2Txt" as "Donor_FrgnAddrss_AddrssLn2Txt",
           address_table."FrgnAddrss_CtyNm" as "Donor_FrgnAddrss_CtyNm",
           address_table."FrgnAddrss_PrvncOrSttNm" as "Donor_PrvncOrSttNm",
           address_table."FrgnAddrss_CntryCd" as "Donor_CntryCd",
	        return_PFGrntOrCntrbtnPdDrYr.*
	       
			INTO TABLE pfgrants
				FROM return_PFGrntOrCntrbtnPdDrYr
				LEFT JOIN address_table ON return_PFGrntOrCntrbtnPdDrYr.object_id = address_table.object_id
				AND return_PFGrntOrCntrbtnPdDrYr.ein = address_table.ein;
	
Copy to local 

	\copy pfgrants to '/tmp/pfgrants.csv' with csv header;



## Contractor compensation



990: 


	DROP TABLE IF EXISTS contractor_comp_990;
	
	SELECT 
		address_table."RtrnHdr_TxPrdEndDt",
		address_table."RtrnHdr_TxYr",
		address_table."BsnssNm_BsnssNmLn1Txt" as "Org_BsnssNmLn1",
		address_table."BsnssNm_BsnssNmLn2Txt" as "Org_BsnssNmL21",
		address_table."BsnssOffcr_PrsnNm" as "Org_BsnssOffcr_PrsnNm",
		address_table."BsnssOffcr_PrsnTtlTxt" as "Org_ BsnssOffcr_PrsnTtlTxt",
		address_table."BsnssOffcr_PhnNm" as "Org_ BsnssOffcr_PhnNm" ,
		address_table."BsnssOffcr_EmlAddrssTxt"  as "Org_ BsnssOffcr_EmlAddrssTxt" ,
		address_table."USAddrss_AddrssLn1Txt" as "Org_AddrssLn1Txt",
		address_table."USAddrss_AddrssLn2Txt" as "Org_AddrssLn2Txt",
		address_table."USAddrss_CtyNm" as "Org_CtyNm",
		address_table."USAddrss_SttAbbrvtnCd" as "Org_SttAbbrvtnCd",
		address_table."USAddrss_ZIPCd" as "Org_ZIPCd",
		address_table."FrgnAddrss_AddrssLn1Txt" as "Org_FrgnAddrss_AddrssLn1Txt",
		address_table."FrgnAddrss_AddrssLn2Txt" as "Org_FrgnAddrss_AddrssLn2Txt",
		address_table."FrgnAddrss_CtyNm" as "Org_FrgnAddrss_CtyNm",
		address_table."FrgnAddrss_PrvncOrSttNm" as "Org_PrvncOrSttNm",
		address_table."FrgnAddrss_CntryCd" as "Org_CntryCd",
		return_CntrctrCmpnstn."CntrctrNm_PrsnNm" as "CntrctrNm_PrsnNm",
		trim(concat(return_CntrctrCmpnstn."BsnssNm_BsnssNmLn1Txt", ' ', return_CntrctrCmpnstn."BsnssNm_BsnssNmLn2Txt")) as "Cntrctr_Business",
		trim(concat(return_CntrctrCmpnstn."USAddrss_AddrssLn1Txt", ' ', return_CntrctrCmpnstn."FrgnAddrss_AddrssLn1Txt")) as "Cntrctr_Address1",
		trim(concat(return_CntrctrCmpnstn."USAddrss_AddrssLn2Txt", ' ', return_CntrctrCmpnstn."FrgnAddrss_AddrssLn2Txt")) as "Cntrctr_Address2",
		trim(concat(return_CntrctrCmpnstn."USAddrss_CtyNm", ' ', return_CntrctrCmpnstn."FrgnAddrss_CtyNm")) as "Cntrctr_City",
		trim(concat(return_CntrctrCmpnstn."USAddrss_ZIPCd", ' ', return_CntrctrCmpnstn."FrgnAddrss_FrgnPstlCd")) as "Cntrctr_ZIP",
		trim(concat(return_CntrctrCmpnstn."USAddrss_SttAbbrvtnCd" , ' ',  return_CntrctrCmpnstn."FrgnAddrss_PrvncOrSttNm")) as "Cntrctr_State",
		return_CntrctrCmpnstn."FrgnAddrss_CntryCd" as "Cntrctr_FrgnAddrss_CntryCd",
		return_CntrctrCmpnstn."CntrctrCmpnstn_SrvcsDsc" as "SrvcsDsc",
		return_CntrctrCmpnstn."CntrctrCmpnstn_CmpnstnAmt" as "CmpnstnAmt"
			      
	INTO TABLE contractor_comp_990
		FROM return_CntrctrCmpnstn
		LEFT JOIN address_table ON return_CntrctrCmpnstn.object_id = address_table.object_id
		AND return_CntrctrCmpnstn.ein = address_table.ein;
	
	
	\copy contractor_comp_990 to '/tmp/contractors_990.csv' with csv header;


### 990 PF

	
	DROP TABLE IF EXISTS contractor_comp_990_pf;
		
	SELECT 
		address_table."RtrnHdr_TxPrdEndDt",
		address_table."RtrnHdr_TxYr",
		address_table."BsnssNm_BsnssNmLn1Txt" as "Org_BsnssNmLn1",
		address_table."BsnssNm_BsnssNmLn2Txt" as "Org_BsnssNmL21",
		address_table."BsnssOffcr_PrsnNm" as "Org_BsnssOffcr_PrsnNm",
		address_table."BsnssOffcr_PrsnTtlTxt" as "Org_ BsnssOffcr_PrsnTtlTxt",
		address_table."BsnssOffcr_PhnNm" as "Org_ BsnssOffcr_PhnNm" ,
		address_table."BsnssOffcr_EmlAddrssTxt"  as "Org_ BsnssOffcr_EmlAddrssTxt" ,
		address_table."USAddrss_AddrssLn1Txt" as "Org_AddrssLn1Txt",
		address_table."USAddrss_AddrssLn2Txt" as "Org_AddrssLn2Txt",
		address_table."USAddrss_CtyNm" as "Org_CtyNm",
		address_table."USAddrss_SttAbbrvtnCd" as "Org_SttAbbrvtnCd",
		address_table."USAddrss_ZIPCd" as "Org_ZIPCd",
		address_table."FrgnAddrss_AddrssLn1Txt" as "Org_FrgnAddrss_AddrssLn1Txt",
		address_table."FrgnAddrss_AddrssLn2Txt" as "Org_FrgnAddrss_AddrssLn2Txt",
		address_table."FrgnAddrss_CtyNm" as "Org_FrgnAddrss_CtyNm",
		address_table."FrgnAddrss_PrvncOrSttNm" as "Org_PrvncOrSttNm",
		address_table."FrgnAddrss_CntryCd" as "Org_CntryCd",
		return_PFCmpnstnOfHghstPdCntrct."CmpnstnOfHghstPdCntrct_PrsnNm" as "CntrctrNm_PrsnNm",
		trim(concat(return_PFCmpnstnOfHghstPdCntrct."CmpnstnOfHghstPdCntrct_BsnssNmLn1", ' ', return_PFCmpnstnOfHghstPdCntrct."CmpnstnOfHghstPdCntrct_BsnssNmLn2")) as "Cntrctr_Business",
		trim(concat(return_PFCmpnstnOfHghstPdCntrct."USAddrss_AddrssLn1Txt", ' ', return_PFCmpnstnOfHghstPdCntrct."FrgnAddrss_AddrssLn1Txt")) as "Cntrctr_Address1",
		trim(concat(return_PFCmpnstnOfHghstPdCntrct."USAddrss_AddrssLn2Txt", ' ', return_PFCmpnstnOfHghstPdCntrct."FrgnAddrss_AddrssLn2Txt")) as "Cntrctr_Address2",
		trim(concat(return_PFCmpnstnOfHghstPdCntrct."USAddrss_CtyNm", ' ', return_PFCmpnstnOfHghstPdCntrct."FrgnAddrss_CtyNm")) as "Cntrctr_City",
		trim(concat(return_PFCmpnstnOfHghstPdCntrct."USAddrss_ZIPCd", ' ', return_PFCmpnstnOfHghstPdCntrct."FrgnAddrss_FrgnPstlCd")) as "Cntrctr_ZIP",
		trim(concat(return_PFCmpnstnOfHghstPdCntrct."USAddrss_SttAbbrvtnCd" , ' ',  return_PFCmpnstnOfHghstPdCntrct."FrgnAddrss_PrvncOrSttNm")) as "Cntrctr_State",
		return_PFCmpnstnOfHghstPdCntrct."FrgnAddrss_CntryCd" as "Cntrctr_FrgnAddrss_CntryCd",
		return_PFCmpnstnOfHghstPdCntrct."CmpnstnOfHghstPdCntrct_SrvcTxt" as "SrvcsDsc",
		return_PFCmpnstnOfHghstPdCntrct."CmpnstnOfHghstPdCntrct_CmpnstnAmt" as "CmpnstnAmt"	      
	INTO TABLE contractor_comp_990_pf
		FROM return_PFCmpnstnOfHghstPdCntrct
		LEFT JOIN address_table ON return_PFCmpnstnOfHghstPdCntrct.object_id = address_table.object_id
		AND return_PFCmpnstnOfHghstPdCntrct.ein = address_table.ein;
	
	
	\copy contractor_comp_990_pf to '/tmp/contractor_comp_990_pf.csv' with csv header;

### 990EZ

This is rarely used

	DROP TABLE IF EXISTS contractor_comp_990_ez;
		
	SELECT 
		address_table."RtrnHdr_TxPrdEndDt",
		address_table."RtrnHdr_TxYr",
		address_table."BsnssNm_BsnssNmLn1Txt" as "Org_BsnssNmLn1",
		address_table."BsnssNm_BsnssNmLn2Txt" as "Org_BsnssNmL21",
		address_table."BsnssOffcr_PrsnNm" as "Org_BsnssOffcr_PrsnNm",
		address_table."BsnssOffcr_PrsnTtlTxt" as "Org_ BsnssOffcr_PrsnTtlTxt",
		address_table."BsnssOffcr_PhnNm" as "Org_ BsnssOffcr_PhnNm" ,
		address_table."BsnssOffcr_EmlAddrssTxt"  as "Org_ BsnssOffcr_EmlAddrssTxt" ,
		address_table."USAddrss_AddrssLn1Txt" as "Org_AddrssLn1Txt",
		address_table."USAddrss_AddrssLn2Txt" as "Org_AddrssLn2Txt",
		address_table."USAddrss_CtyNm" as "Org_CtyNm",
		address_table."USAddrss_SttAbbrvtnCd" as "Org_SttAbbrvtnCd",
		address_table."USAddrss_ZIPCd" as "Org_ZIPCd",
		address_table."FrgnAddrss_AddrssLn1Txt" as "Org_FrgnAddrss_AddrssLn1Txt",
		address_table."FrgnAddrss_AddrssLn2Txt" as "Org_FrgnAddrss_AddrssLn2Txt",
		address_table."FrgnAddrss_CtyNm" as "Org_FrgnAddrss_CtyNm",
		address_table."FrgnAddrss_PrvncOrSttNm" as "Org_PrvncOrSttNm",
		address_table."FrgnAddrss_CntryCd" as "Org_CntryCd",
		return_EZCmpnstnOfHghstPdCntrct ."CmpnstnOfHghstPdCntrct_PrsnNm" as "CntrctrNm_PrsnNm",
		trim(concat(return_EZCmpnstnOfHghstPdCntrct ."CmpnstnOfHghstPdCntrct_BsnssNmLn1", ' ', return_EZCmpnstnOfHghstPdCntrct ."CmpnstnOfHghstPdCntrct_BsnssNmLn2")) as "Cntrctr_Business",
		trim(concat(return_EZCmpnstnOfHghstPdCntrct ."USAddrss_AddrssLn1Txt", ' ', return_EZCmpnstnOfHghstPdCntrct ."FrgnAddrss_AddrssLn1Txt")) as "Cntrctr_Address1",
		trim(concat(return_EZCmpnstnOfHghstPdCntrct ."USAddrss_AddrssLn2Txt", ' ', return_EZCmpnstnOfHghstPdCntrct ."FrgnAddrss_AddrssLn2Txt")) as "Cntrctr_Address2",
		trim(concat(return_EZCmpnstnOfHghstPdCntrct ."USAddrss_CtyNm", ' ', return_EZCmpnstnOfHghstPdCntrct ."FrgnAddrss_CtyNm")) as "Cntrctr_City",
		trim(concat(return_EZCmpnstnOfHghstPdCntrct ."USAddrss_ZIPCd", ' ', return_EZCmpnstnOfHghstPdCntrct ."FrgnAddrss_FrgnPstlCd")) as "Cntrctr_ZIP",
		trim(concat(return_EZCmpnstnOfHghstPdCntrct ."USAddrss_SttAbbrvtnCd" , ' ',  return_EZCmpnstnOfHghstPdCntrct ."FrgnAddrss_PrvncOrSttNm")) as "Cntrctr_State",
		return_EZCmpnstnOfHghstPdCntrct ."FrgnAddrss_CntryCd" as "Cntrctr_FrgnAddrss_CntryCd",
		return_EZCmpnstnOfHghstPdCntrct ."CmpnstnOfHghstPdCntrct_SrvcTxt" as "SrvcsDsc",
		return_EZCmpnstnOfHghstPdCntrct ."CmpnstnOfHghstPdCntrct_CmpnstnAmt" as "CmpnstnAmt"	      
	INTO TABLE contractor_comp_990_ez
		FROM return_EZCmpnstnOfHghstPdCntrct 
		LEFT JOIN address_table ON return_EZCmpnstnOfHghstPdCntrct .object_id = address_table.object_id
		AND return_EZCmpnstnOfHghstPdCntrct .ein = address_table.ein;


	\copy contractor_comp_990_ez to '/tmp/contractor_comp_990_ez.csv' with csv header;


