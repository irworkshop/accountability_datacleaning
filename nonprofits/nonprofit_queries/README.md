# DB Queries for nonprofit data

These queries are run against a postgres database built according to the [irs-xml-database](https://github.com/jsfenfen/990-xml-database) repo. They are used to extract the top paid employees and schedule I grants. 


## Employees

Make a temporary address lookup table for easier joining:


	SELECT "USAddrss_AddrssLn1Txt",
       "USAddrss_AddrssLn2Txt",
       "USAddrss_CtyNm",
       "USAddrss_SttAbbrvtnCd",
       "USAddrss_ZIPCd",
       object_id,
       ein 
    INTO address_table
	FROM return_part_0;

Index it so the queries don't take forever


	CREATE INDEX tmp1_zz ON tmp1 (object_id, ein);


### From form 990

990:

Make a temporary table with the stuff to pull from Part VII Section A
	
	SELECT filing_filing.submission_year,
       filing_filing.ein,
       filing_filing.object_id,
       taxpayer_name,
       tax_period,
       "PrsnNm",
       "TtlTxt",
       "RprtblCmpFrmOrgAmt" 
    INTO tmp1
	FROM return_Frm990PrtVIISctnA
	LEFT JOIN filing_filing ON return_Frm990PrtVIISctnA.ein = filing_filing.ein
	AND return_Frm990PrtVIISctnA.object_id=filing_filing.object_id;




Join it back to the address info:


	SELECT tmp1.*,
       "USAddrss_AddrssLn1Txt",
       "USAddrss_AddrssLn2Txt",
       "USAddrss_CtyNm",
       "USAddrss_SttAbbrvtnCd",
       "USAddrss_ZIPCd" 
 	INTO tmp2
	FROM tmp1
	LEFT JOIN address_table ON tmp1.object_id = address_table.object_id
	AND tmp1.ein = address_table.ein;


Copy back with:

	\copy tmp2 to '/local/path/here/990_employees.csv' with csv header;



### 990EZ


For the EZ filings:
	
	SELECT filing_filing.submission_year,
	       filing_filing.ein,
	       filing_filing.object_id,
	       taxpayer_name,
	       tax_period,
	       "PrsnNm",
	       "TtlTxt",
	       "CmpnstnAmt" 
	INTO tmpEZ1
	FROM return_EZOffcrDrctrTrstEmpl
	LEFT JOIN filing_filing ON return_EZOffcrDrctrTrstEmpl.ein = filing_filing.ein
	AND return_EZOffcrDrctrTrstEmpl.object_id=filing_filing.object_id;
	

 Index it

	CREATE INDEX tmp1EZ_zz ON tmpEZ1 (object_id, ein);

Then the EZ specific records

	SELECT tmpEZ1.*,
	       "USAddrss_AddrssLn1Txt",
	       "USAddrss_AddrssLn2Txt",
	       "USAddrss_CtyNm",
	       "USAddrss_SttAbbrvtnCd",
	       "USAddrss_ZIPCd" 
	INTO tmpEZ2
	FROM tmpEZ1
	LEFT JOIN address_table ON tmpEZ1.object_id = address_table.object_id
	AND tmpEZ1.ein = address_table.ein;

And then move with: 

 	\copy tmpEZ2 to '/local/path/here/990EZ_employees.csv' with csv header;


### 990PF

Get PF values

	SELECT filing_filing.submission_year,
	       filing_filing.ein,
	       filing_filing.object_id,
	       taxpayer_name,
	       tax_period,
	       "OffcrDrTrstKyEmpl_PrsnNm" AS "PrsnNm",
	       "OffcrDrTrstKyEmpl_TtlTxt" AS "TtlTxt",
	       "OffcrDrTrstKyEmpl_CmpnstnAmt" AS "CmpnstnAmt" 
	INTO tmpPF1
	FROM return_PFOffcrDrTrstKyEmpl
	LEFT JOIN filing_filing ON return_PFOffcrDrTrstKyEmpl.ein = filing_filing.ein
	AND return_PFOffcrDrTrstKyEmpl.object_id=filing_filing.object_id;


join with addresses

	SELECT tmpPF1.*,
	       "USAddrss_AddrssLn1Txt",
	       "USAddrss_AddrssLn2Txt",
	       "USAddrss_CtyNm",
	       "USAddrss_SttAbbrvtnCd",
	       "USAddrss_ZIPCd" 
	INTO tmpPF2
	FROM tmpPF1
	LEFT JOIN address_table ON tmpPF1.object_id = address_table.object_id
	AND tmpPF1.ein = address_table.ein;
	
copy it with: 

	\copy tmpPF2 to '/tmp/990PF_employees.csv' with csv header;

## Schedule I

The schedule I variables are defined in the [irsx documentation](http://www.irsx.info/metadata/groups/SkdIRcpntTbl.html).

Here's a query to a temp table



	SELECT return_returnheader990x_part_i.ein AS "Donor_EIN",
	       return_returnheader990x_part_i."RtrnHdr_TxPrdEndDt" AS "TxPrdEndDt",
	       return_returnheader990x_part_i."RtrnHdr_TxYr" AS "TxYr",
	       return_returnheader990x_part_i."BsnssNm_BsnssNmLn1Txt",
	       return_returnheader990x_part_i."BsnssNm_BsnssNmLn2Txt",
	       return_returnheader990x_part_i."BsnssOffcr_PrsnNm",
	       return_returnheader990x_part_i."BsnssOffcr_PrsnTtlTxt",
	       return_returnheader990x_part_i."BsnssOffcr_PhnNm",
	       return_returnheader990x_part_i."BsnssOffcr_EmlAddrssTxt",
	       return_returnheader990x_part_i."USAddrss_AddrssLn1Txt" AS "AddrssLn1Txt",
	       return_returnheader990x_part_i."USAddrss_AddrssLn2Txt" AS "AddrssLn2Txt",
	       return_returnheader990x_part_i."USAddrss_CtyNm" AS "CtyNm",
	       return_returnheader990x_part_i."USAddrss_SttAbbrvtnCd" AS "SttAbbrvtnCd",
	       return_returnheader990x_part_i."USAddrss_ZIPCd" AS "ZIPCd",
	       return_SkdIRcpntTbl."RcpntBsnssNm_BsnssNmLn1Txt",
	       return_SkdIRcpntTbl."RcpntBsnssNm_BsnssNmLn2Txt",
	       return_SkdIRcpntTbl."RcpntTbl_RcpntEIN",
	       return_SkdIRcpntTbl."RcpntTbl_CshGrntAmt",
	       return_SkdIRcpntTbl."RcpntTbl_NnCshAssstncAmt",
	       return_SkdIRcpntTbl."RcpntTbl_VltnMthdUsdDsc",
	       return_SkdIRcpntTbl."RcpntTbl_NnCshAssstncDsc",
	       return_SkdIRcpntTbl."RcpntTbl_PrpsOfGrntTxt",
	       return_SkdIRcpntTbl."USAddrss_AddrssLn1Txt" AS "Rcpnt_AddrssLn1Txt",
	       return_SkdIRcpntTbl."USAddrss_AddrssLn2Txt" AS "Rcpnt_AddrssLn2Txt",
	       return_SkdIRcpntTbl."USAddrss_CtyNm" AS "Rcpnt_CtyNm",
	       return_SkdIRcpntTbl."USAddrss_SttAbbrvtnCd" AS "Rcpnt_SttAbbrvtnCd",
	       return_SkdIRcpntTbl."USAddrss_ZIPCd" AS "Rcpnt_ZIPCd" INTO TEMP TABLE grants
	FROM return_SkdIRcpntTbl
	LEFT JOIN return_returnheader990x_part_i ON return_SkdIRcpntTbl.object_id = return_returnheader990x_part_i.object_id
	AND return_SkdIRcpntTbl.ein = return_returnheader990x_part_i.ein;
	



Then copy to local with \copy: 

	\copy grants to '/local/path/here/grants.csv' with csv header;