------------------------------------------------------------------------------------------------------------------------------------------------------------------ReadMe.txt

                        TEXAS ETHICS COMMISSION
         DATA FROM ELECTRONICALLY FILED CAMPAIGN FINANCE REPORTS
             www.ethics.state.tx.us  *   512.463.5800

This zip package contains detailed information from campaign finance reports
filed electronically with the Texas Ethics Commission beginning July 1, 2000.

Flat File Architecture Record Listing  --  Generated 06/11/2016 12:38:08 PM


   Record Name        File Contents                                                      File Name(s)
   
----------------   ----------------------------------------------------------------   ---------------------------------------------------------
   
AssetData          Assets - Schedule M                                                assets.csv
   
CandidateData      Direct Campaign Expenditure Candidates                             cand.csv

ContributionData   Contributions - Schedules A/C                                      contribs_##.csv, cont_ss.csv, cont_t.csv, returns.csv
   
CoverSheet1Data    Cover Sheet 1 - Cover sheet information and totals                 cover.csv, cover_ss.csv, cover_t.csv
   
CoverSheet2Data    Cover Sheet 2 - Notices received by candidates/office holders      notices.csv 
   
CoverSheet3Data    Cover Sheet 3 - Committee purpose                                  purpose.csv
   
CreditData         Credits - Schedule K                                               credits.csv
   
DebtData           Debts - Schedule L                                                 debts.csv
   
ExpendData         Expenditures - Schedules F/G/H/I                                   expend_##.csv, expn_t.csv
   
ExpendCategory     Expenditure category codes                                         expn_catg.csv
   
FilerData          Filer index                                                        filers.csv
   
FinalData          Final reports                                                      final.csv
   
LoanData           Loans - Schedule E                                                 loans.csv
   
PledgeData         Pledges - Schedule B                                               pledges.csv, pldg_ss.csv, pldg_t.csv
   
SpacData           Index of Specific-purpose committees                               spacs.csv
   
TravelData         Travel outside the State of Texas - Schedule T                     travel.csv
	

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

Record #: 1     Record Name: AssetData     Length: 521
Description: Assets - Schedule M - Assets valued at $500 or more for judicial filers only.
             File: assets.csv

 #  Field Name                                    Type       Mask                             Len Description
--- --------------------------------------------- ---------- ------------------------------ ----- -----------------------------------------------------------------
  1 recordType                                    String                                       20 Record type code - always ASSET                                  
  2 formTypeCd                                    String                                       20 TEC form used                                                    
  3 schedFormTypeCd                               String                                       20 TEC Schedule Used                                                
  4 reportInfoIdent                               Long       00000000000                       11 Unique report #                                                  
  5 receivedDt                                    Date       yyyyMMdd                           8 Date report received by TEC                                      
  6 infoOnlyFlag                                  String                                        1 Superseded by other report                                       
  7 filerIdent                                    String                                      100 Filer account #                                                  
  8 filerTypeCd                                   String                                       30 Type of filer                                                    
  9 filerName                                     String                                      200 Filer name                                                       
 10 assetInfoId                                   Long       00000000000                       11 Asset unique identifier                                          
 11 assetDescr                                    String                                      100 Description of asset                                             

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

Record #: 2     Record Name: CandidateData     Length: 1590
Description: Candidate benefiting from a direct campaign expenditure. A direct campaign expenditure to benefit a candidate is not a political 
             contribution to that candidate. Instead, a direct campaign expenditure is a campaign expenditure made on someone else's behalf and
             without the prior consent or approval of that person. A given EXPN record can have zero or more related CAND records. Any CAND 
             records are written to the file immediately after their related EXPN record.
             File: cand.csv

 #  Field Name                                    Type       Mask                             Len Description
--- --------------------------------------------- ---------- ------------------------------ ----- -----------------------------------------------------------------
  1 recordType                                    String                                       20 Record type code - always CAND                                   
  2 formTypeCd                                    String                                       20 TEC form used                                                    
  3 schedFormTypeCd                               String                                       20 TEC Schedule Used                                                
  4 reportInfoIdent                               Long       00000000000                       11 Unique report #                                                  
  5 receivedDt                                    Date       yyyyMMdd                           8 Date report received by TEC                                      
  6 infoOnlyFlag                                  String                                        1 Superseded by other report                                       
  7 filerIdent                                    String                                      100 Filer account #                                                  
  8 filerTypeCd                                   String                                       30 Type of filer                                                    
  9 filerName                                     String                                      200 Filer name                                                       
 10 expendInfoId                                  Long       00000000000                       11 Expenditure unique identifier                                    
 11 expendPersentId                               Long       00000000000                       11 Candidate unique identifier                                      
 12 expendDt                                      Date       yyyyMMdd                           8 Expenditure date                                                 
 13 expendAmount                                  BigDecimal 0000000000.00                     12 Expenditure amount                                               
 14 expendDescr                                   String                                      100 Expenditure description                                          
 15 expendCatCd                                   String                                       30 Expenditure category code                                        
 16 expendCatDescr                                String                                      100 Expenditure category description                                 
 17 itemizeFlag                                   String                                        1 Y indicates that the expenditure is itemized                     
 18 politicalExpendCd                             String                                       30 Political expenditure indicator                                  
 19 reimburseIntendedFlag                         String                                        1 Reimbursement intended indicator                                 
 20 srcCorpContribFlag                            String                                        1 Expenditure from corporate funds indicator                       
 21 capitalLivingexpFlag                          String                                        1 Austin living expense indicator                                  
 22 candidatePersentTypeCd                        String                                       30 Type of candidate name data - INDIVIDUAL or ENTITY               
 23 candidateNameOrganization                     String                                      100 For ENTITY, the candidate organization name                      
 24 candidateNameLast                             String                                      100 For INDIVIDUAL, the candidate last name                          
 25 candidateNameSuffixCd                         String                                       30 For INDIVIDUAL, the candidate name suffix (e.g. JR, MD, II)      
 26 candidateNameFirst                            String                                       45 For INDIVIDUAL, the candidate first name                         
 27 candidateNamePrefixCd                         String                                       30 For INDIVIDUAL, the candidate name prefix (e.g. MR, MRS, MS)     
 28 candidateNameShort                            String                                       25 For INDIVIDUAL, the candidate short name (nickname)              
 29 candidateHoldOfficeCd                         String                                       30 Candidate office held                                            
 30 candidateHoldOfficeDistrict                   String                                       11 Candidate office held district                                   
 31 candidateHoldOfficePlace                      String                                       11 Candidate office held place                                      
 32 candidateHoldOfficeDescr                      String                                      100 Candidate office held description                                
 33 candidateHoldOfficeCountyCd                   String                                        5 Candidate office held country code                               
 34 candidateHoldOfficeCountyDescr                String                                      100 Candidate office help county description                         
 35 candidateSeekOfficeCd                         String                                       30 Candidate office sought                                          
 36 candidateSeekOfficeDistrict                   String                                       11 Candidate office sought district                                 
 37 candidateSeekOfficePlace                      String                                       11 Candidate office sought place                                    
 38 candidateSeekOfficeDescr                      String                                      100 Candidate office sought description                              
 39 candidateSeekOfficeCountyCd                   String                                        5 Candidate office sought county code                              
 40 candidateSeekOfficeCountyDescr                String                                      100 Candidate office sought county description                       

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

Record #: 3     Record Name: ContributionData     Length: 1366
Description: Contributions - Schedules A/C - Contributions from special session and special pre-election (formerly Telegram) reports are stored
             in the file cont_ss and cont_t. These records are kept separate from the contribs files to avoid creating duplicates, because they
             are supposed to be re-reported on the next regular campaign finance report.
             Files: contribs_##.csv, cont_ss.csv, cont_t.csv

 #  Field Name                                    Type       Mask                             Len Description
--- --------------------------------------------- ---------- ------------------------------ ----- -----------------------------------------------------------------
  1 recordType                                    String                                       20 Record type code - always RCPT                                   
  2 formTypeCd                                    String                                       20 TEC form used                                                    
  3 schedFormTypeCd                               String                                       20 TEC Schedule Used                                                
  4 reportInfoIdent                               Long       00000000000                       11 Unique report #                                                  
  5 receivedDt                                    Date       yyyyMMdd                           8 Date report received by TEC                                      
  6 infoOnlyFlag                                  String                                        1 Superseded by other report                                       
  7 filerIdent                                    String                                      100 Filer account #                                                  
  8 filerTypeCd                                   String                                       30 Type of filer                                                    
  9 filerName                                     String                                      200 Filer name                                                       
 10 contributionInfoId                            Long       00000000000                       11 Contribution unique identifier                                   
 11 contributionDt                                Date       yyyyMMdd                           8 Contribution date                                                
 12 contributionAmount                            BigDecimal 0000000000.00                     12 Contribution amount                                              
 13 contributionDescr                             String                                      100 Contribution description                                         
 14 itemizeFlag                                   String                                        1 Y indicates that the contribution is itemized                    
 15 travelFlag                                    String                                        1 Y indicates that the contribution has associated travel          
 16 contributorPersentTypeCd                      String                                       30 Type of contributor name data - INDIVIDUAL or ENTITY             
 17 contributorNameOrganization                   String                                      100 For ENTITY, the contributor organization name                    
 18 contributorNameLast                           String                                      100 For INDIVIDUAL, the contributor last name                        
 19 contributorNameSuffixCd                       String                                       30 For INDIVIDUAL, the contributor name suffix (e.g. JR, MD, II)    
 20 contributorNameFirst                          String                                       45 For INDIVIDUAL, the contributor first name                       
 21 contributorNamePrefixCd                       String                                       30 For INDIVIDUAL, the contributor name prefix (e.g. MR, MRS, MS)   
 22 contributorNameShort                          String                                       25 For INDIVIDUAL, the contributor short name (nickname)            
 23 contributorStreetCity                         String                                       30 Contributor street address - city                                
 24 contributorStreetStateCd                      String                                        2 Contributor street address - state code (e.g. TX, CA) - for      
                                                                                                  country=USA/UMI only
 25 contributorStreetCountyCd                     String                                        5 Contributor street address - Texas county                        
 26 contributorStreetCountryCd                    String                                        3 Contributor street address - country (e.g. USA, UMI, MEX, CAN)   
 27 contributorStreetPostalCode                   String                                       20 Contributor street address - postal code - for USA addresses only
 28 contributorStreetRegion                       String                                       30 Contributor street address - region for country other than USA   
 29 contributorEmployer                           String                                       60 Contributor employer                                             
 30 contributorOccupation                         String                                       60 Contributor occupation                                           
 31 contributorJobTitle                           String                                       60 Contributor job title                                            
 32 contributorPacFein                            String                                       12 FEC ID of out-of-state PAC contributor                           
 33 contributorOosPacFlag                         String                                        1 Indicates if contributor is an out-of-state PAC                  
 34 contributorSpouseLawFirmName                  String                                       60 Contributor spouse law firm name                                 
 35 contributorParent1LawFirmName                 String                                       60 Contributor parent #1 law firm name                              
 36 contributorParent2LawFirmName                 String                                       60 Contributor parent #2 law firm name                              

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

Record #: 4     Record Name: CoverSheet1Data     Length: 4001
Description: Cover Sheet 1 - Cover sheet information and totals. cover_ss and cover_t contain cover sheet information for special session 
             reports and special pre-election (formerly Telegram) Reports. Cover sheets for these reports do not contain totals.
             Files: cover.csv, cover_ss.csv, cover_t.csv

 #  Field Name                                    Type       Mask                             Len Description
--- --------------------------------------------- ---------- ------------------------------ ----- -----------------------------------------------------------------
  1 recordType                                    String                                       20 Record type code - always CVR1                                   
  2 formTypeCd                                    String                                       20 TEC form used                                                    
  3 reportInfoIdent                               Long       00000000000                       11 Unique report #                                                  
  4 receivedDt                                    Date       yyyyMMdd                           8 Date report received by TEC                                      
  5 infoOnlyFlag                                  String                                        1 Superseded by other report                                       
  6 filerIdent                                    String                                      100 Filer account #                                                  
  7 filerTypeCd                                   String                                       30 Type of filer                                                    
  8 filerName                                     String                                      200 Filer name                                                       

    Array                                                                                     300
    reportTypeCd[10]                              String                                       30 Report types covered (maximum 10)                                
  9    reportTypeCd                               String                                       30 Report type covered                                              
 10 sourceCategoryCd                              String                                       30 Source of report (ELECTRONIC, KEYED)                             
 11 dueDt                                         Date       yyyyMMdd                           8 Report due date                                                  
 12 filedDt                                       Date       yyyyMMdd                           8 Date report was filed (postmark)                                 
 13 periodStartDt                                 Date       yyyyMMdd                           8 Beginning of period covered                                      
 14 periodEndDt                                   Date       yyyyMMdd                           8 Ending of period covered                                         
 15 unitemizedContribAmount                       BigDecimal 0000000000.00                     12 Total unitemized political contribs                              
 16 totalContribAmount                            BigDecimal 0000000000.00                     12 Total political contribs                                         
 17 unitemizedExpendAmount                        BigDecimal 0000000000.00                     12 Total unitemized political expend below threshold                
 18 totalExpendAmount                             BigDecimal 0000000000.00                     12 Total political expend                                           
 19 loanBalanceAmount                             BigDecimal 0000000000.00                     12 Total principal amount of all outstanding loans as of the last   
                                                                                                  day of the reporting period
 20 contribsMaintainedAmount                      BigDecimal 0000000000.00                     12 Total contributions maintained as of the last day of the         
                                                                                                  reporting period
 21 unitemizedPledgeAmount                        BigDecimal 0000000000.00                     12 Total unitemized pledges                                         
 22 unitemizedLoanAmount                          BigDecimal 0000000000.00                     12 Total unitemized loans                                           
 23 totalInterestEarnedAmount                     BigDecimal 0000000000.00                     12 Total amount of interest and other income earned on unexpended   
                                                                                                  political contributions during the previous year
 24 electionDt                                    Date       yyyyMMdd                           8 Election date                                                    
 25 electionTypeCd                                String                                       30 Election type (PRIMARY, GENERAL, etc)                            
 26 electionTypeDescr                             String                                      100 Election type description (electionTypeCd=OTHER)                 
 27 noActivityFlag                                String                                        1 No activity indicator                                            
 28 politicalPartyCd                              String                                       30 Political party (DEM, REP, LIB, etc)                             
 29 politicalDivisionCd                           String                                       30 Political division (STATE, COUNTY, etc)                          
 30 politicalPartyOtherDescr                      String                                      100 Political party description (politicalPartyCd=OTHER)             
 31 politicalPartyCountyCd                        String                                       30 Political party county                                           
 32 timelyCorrectionFlag                          String                                        1 Correction aff timely indicator                                  
 33 semiannualCheckboxFlag                        String                                        1 Correction aff semiannual indicator                              
 34 highContribThreshholdCd                       String                                       30 High itemization threshold indicator                             
 35 softwareRelease                               String                                       20 Software release (version)                                       
 36 internetVisibleFlag                           String                                        1 Internet visible indicator                                       
 37 signerPrintedName                             String                                      100 Document signer name                                             
 38 addrChangeFilerFlag                           String                                        1 Filer address change indicator                                   
 39 addrChangeTreasFlag                           String                                        1 Treasurer address change indicator                               
 40 addrChangeChairFlag                           String                                        1 Chair address change indicator                                   
 41 filerPersentTypeCd                            String                                       30 Type of filer name data - INDIVIDUAL or ENTITY                   
 42 filerNameOrganization                         String                                      100 For ENTITY, the filer organization name                          
 43 filerNameLast                                 String                                      100 For INDIVIDUAL, the filer last name                              
 44 filerNameSuffixCd                             String                                       30 For INDIVIDUAL, the filer name suffix (e.g. JR, MD, II)          
 45 filerNameFirst                                String                                       45 For INDIVIDUAL, the filer first name                             
 46 filerNamePrefixCd                             String                                       30 For INDIVIDUAL, the filer name prefix (e.g. MR, MRS, MS)         
 47 filerNameShort                                String                                       25 For INDIVIDUAL, the filer short name (nickname)                  
 48 filerStreetAddr1                              String                                       55 Filer street address - line 1                                    
 49 filerStreetAddr2                              String                                       55 Filer street address - line 2                                    
 50 filerStreetCity                               String                                       30 Filer street address - city                                      
 51 filerStreetStateCd                            String                                        2 Filer street address - state code (e.g. TX, CA) - for            
                                                                                                  country=USA/UMI only
 52 filerStreetCountyCd                           String                                        5 Filer street address - Texas county                              
 53 filerStreetCountryCd                          String                                        3 Filer street address - country (e.g. USA, UMI, MEX, CAN)         
 54 filerStreetPostalCode                         String                                       20 Filer street address - postal code - for USA addresses only      
 55 filerStreetRegion                             String                                       30 Filer street address - region for country other than USA         
 56 filerHoldOfficeCd                             String                                       30 Filer office held                                                
 57 filerHoldOfficeDistrict                       String                                       11 Filer office held district                                       
 58 filerHoldOfficePlace                          String                                       11 Filer office held place                                          
 59 filerHoldOfficeDescr                          String                                      100 Filer office held description                                    
 60 filerHoldOfficeCountyCd                       String                                        5 Filer office held country code                                   
 61 filerHoldOfficeCountyDescr                    String                                      100 Filer office help county description                             
 62 filerSeekOfficeCd                             String                                       30 Filer office sought                                              
 63 filerSeekOfficeDistrict                       String                                       11 Filer office sought district                                     
 64 filerSeekOfficePlace                          String                                       11 Filer office sought place                                        
 65 filerSeekOfficeDescr                          String                                      100 Filer office sought description                                  
 66 filerSeekOfficeCountyCd                       String                                        5 Filer office sought county code                                  
 67 filerSeekOfficeCountyDescr                    String                                      100 Filer office sought county description                           
 68 treasPersentTypeCd                            String                                       30 Type of treasurer name data - INDIVIDUAL or ENTITY               
 69 treasNameOrganization                         String                                      100 For ENTITY, the treasurer organization name                      
 70 treasNameLast                                 String                                      100 For INDIVIDUAL, the treasurer last name                          
 71 treasNameSuffixCd                             String                                       30 For INDIVIDUAL, the treasurer name suffix (e.g. JR, MD, II)      
 72 treasNameFirst                                String                                       45 For INDIVIDUAL, the treasurer first name                         
 73 treasNamePrefixCd                             String                                       30 For INDIVIDUAL, the treasurer name prefix (e.g. MR, MRS, MS)     
 74 treasNameShort                                String                                       25 For INDIVIDUAL, the treasurer short name (nickname)              
 75 treasStreetAddr1                              String                                       55 Treasurer street address - line 1                                
 76 treasStreetAddr2                              String                                       55 Treasurer street address - line 2                                
 77 treasStreetCity                               String                                       30 Treasurer street address - city                                  
 78 treasStreetStateCd                            String                                        2 Treasurer street address - state code (e.g. TX, CA) - for        
                                                                                                  country=USA/UMI only
 79 treasStreetCountyCd                           String                                        5 Treasurer street address - Texas county                          
 80 treasStreetCountryCd                          String                                        3 Treasurer street address - country (e.g. USA, UMI, MEX, CAN)     
 81 treasStreetPostalCode                         String                                       20 Treasurer street address - postal code - for USA addresses only  
 82 treasStreetRegion                             String                                       30 Treasurer street address - region for country other than USA     
 83 treasMailingAddr1                             String                                       55 Treasurer mailing address - line 1                               
 84 treasMailingAddr2                             String                                       55 Treasurer mailing address - line 2                               
 85 treasMailingCity                              String                                       30 Treasurer mailing address - city                                 
 86 treasMailingStateCd                           String                                        2 Treasurer mailing address - state code (e.g. TX, CA) - for       
                                                                                                  country=USA/UMI only
 87 treasMailingCountyCd                          String                                        5 Treasurer mailing address - Texas county                         
 88 treasMailingCountryCd                         String                                        3 Treasurer mailing address - country (e.g. USA, UMI, MEX, CAN)    
 89 treasMailingPostalCode                        String                                       20 Treasurer mailing address - postal code - USA addresses only     
 90 treasMailingRegion                            String                                       30 Treasurer mailing address - region for country other than USA    
 91 treasPrimaryUsaPhoneFlag                      String                                        1 Treasurer primary phone number - Y if number is a USA phone, N   
                                                                                                  otherwise
 92 treasPrimaryPhoneNumber                       String                                       20 Treasurer primary phone number                                   
 93 treasPrimaryPhoneExt                          String                                       10 Treasurer primary phone extension                                
 94 chairPersentTypeCd                            String                                       30 Type of chair name data - INDIVIDUAL or ENTITY                   
 95 chairNameOrganization                         String                                      100 For ENTITY, the chair organization name                          
 96 chairNameLast                                 String                                      100 For INDIVIDUAL, the chair last name                              
 97 chairNameSuffixCd                             String                                       30 For INDIVIDUAL, the chair name suffix (e.g. JR, MD, II)          
 98 chairNameFirst                                String                                       45 For INDIVIDUAL, the chair first name                             
 99 chairNamePrefixCd                             String                                       30 For INDIVIDUAL, the chair name prefix (e.g. MR, MRS, MS)         
100 chairNameShort                                String                                       25 For INDIVIDUAL, the chair short name (nickname)                  
101 chairStreetAddr1                              String                                       55 Chair street address - line 1                                    
102 chairStreetAddr2                              String                                       55 Chair street address - line 2                                    
103 chairStreetCity                               String                                       30 Chair street address - city                                      
104 chairStreetStateCd                            String                                        2 Chair street address - state code (e.g. TX, CA) - for            
                                                                                                  country=USA/UMI only
105 chairStreetCountyCd                           String                                        5 Chair street address - Texas county                              
106 chairStreetCountryCd                          String                                        3 Chair street address - country (e.g. USA, UMI, MEX, CAN)         
107 chairStreetPostalCode                         String                                       20 Chair street address - postal code - for USA addresses only      
108 chairStreetRegion                             String                                       30 Chair street address - region for country other than USA         
109 chairMailingAddr1                             String                                       55 Chair mailing address - line 1                                   
110 chairMailingAddr2                             String                                       55 Chair mailing address - line 2                                   
111 chairMailingCity                              String                                       30 Chair mailing address - city                                     
112 chairMailingStateCd                           String                                        2 Chair mailing address - state code (e.g. TX, CA) - for           
                                                                                                  country=USA/UMI only
113 chairMailingCountyCd                          String                                        5 Chair mailing address - Texas county                             
114 chairMailingCountryCd                         String                                        3 Chair mailing address - country (e.g. USA, UMI, MEX, CAN)        
115 chairMailingPostalCode                        String                                       20 Chair mailing address - postal code - USA addresses only         
116 chairMailingRegion                            String                                       30 Chair mailing address - region for country other than USA        
117 chairPrimaryUsaPhoneFlag                      String                                        1 Chair primary phone number - Y if number is a USA phone, N       
                                                                                                  otherwise
118 chairPrimaryPhoneNumber                       String                                       20 Chair primary phone number                                       
119 chairPrimaryPhoneExt                          String                                       10 Chair primary phone extension                                    

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

Record #: 5     Record Name: CoverSheet2Data     Length: 1551
Description: Cover Sheet 2 - Notices received by candidates/office holders. These notices are reported at the bottom of Cover Sheet Page 1 and
             the top of Cover Sheet Page 2 for FORMNAME = COH, COHFR, CORCOH, JCOH, SCCOH, SCSPAC.
             File: notices.csv

 #  Field Name                                    Type       Mask                             Len Description
--- --------------------------------------------- ---------- ------------------------------ ----- -----------------------------------------------------------------
  1 recordType                                    String                                       20 Record type code - always CVR2                                   
  2 formTypeCd                                    String                                       20 TEC form used                                                    
  3 reportInfoIdent                               Long       00000000000                       11 Unique report #                                                  
  4 receivedDt                                    Date       yyyyMMdd                           8 Date report received by TEC                                      
  5 infoOnlyFlag                                  String                                        1 Superseded by other report                                       
  6 filerIdent                                    String                                      100 Filer account #                                                  
  7 filerTypeCd                                   String                                       30 Type of filer                                                    
  8 filerName                                     String                                      200 Filer name                                                       
  9 committeeActivityId                           Long       00000000000                       11 Contribution unique identifier                                   
 10 notifierCommactPersentKindCd                  String                                       30 Committee activity person/entity kind                            
 11 notifierPersentTypeCd                         String                                       30 Type of notifier name data - INDIVIDUAL or ENTITY                
 12 notifierNameOrganization                      String                                      100 For ENTITY, the notifier organization name                       
 13 notifierNameLast                              String                                      100 For INDIVIDUAL, the notifier last name                           
 14 notifierNameSuffixCd                          String                                       30 For INDIVIDUAL, the notifier name suffix (e.g. JR, MD, II)       
 15 notifierNameFirst                             String                                       45 For INDIVIDUAL, the notifier first name                          
 16 notifierNamePrefixCd                          String                                       30 For INDIVIDUAL, the notifier name prefix (e.g. MR, MRS, MS)      
 17 notifierNameShort                             String                                       25 For INDIVIDUAL, the notifier short name (nickname)               
 18 notifierStreetAddr1                           String                                       55 Notifier street address - line 1                                 
 19 notifierStreetAddr2                           String                                       55 Notifier street address - line 2                                 
 20 notifierStreetCity                            String                                       30 Notifier street address - city                                   
 21 notifierStreetStateCd                         String                                        2 Notifier street address - state code (e.g. TX, CA) - for         
                                                                                                  country=USA/UMI only
 22 notifierStreetCountyCd                        String                                        5 Notifier street address - Texas county                           
 23 notifierStreetCountryCd                       String                                        3 Notifier street address - country (e.g. USA, UMI, MEX, CAN)      
 24 notifierStreetPostalCode                      String                                       20 Notifier street address - postal code - for USA addresses only   
 25 notifierStreetRegion                          String                                       30 Notifier street address - region for country other than USA      
 26 treasPersentTypeCd                            String                                       30 Type of treasurer name data - INDIVIDUAL or ENTITY               
 27 treasNameOrganization                         String                                      100 For ENTITY, the treasurer organization name                      
 28 treasNameLast                                 String                                      100 For INDIVIDUAL, the treasurer last name                          
 29 treasNameSuffixCd                             String                                       30 For INDIVIDUAL, the treasurer name suffix (e.g. JR, MD, II)      
 30 treasNameFirst                                String                                       45 For INDIVIDUAL, the treasurer first name                         
 31 treasNamePrefixCd                             String                                       30 For INDIVIDUAL, the treasurer name prefix (e.g. MR, MRS, MS)     
 32 treasNameShort                                String                                       25 For INDIVIDUAL, the treasurer short name (nickname)              
 33 treasStreetAddr1                              String                                       55 Treasurer street address - line 1                                
 34 treasStreetAddr2                              String                                       55 Treasurer street address - line 2                                
 35 treasStreetCity                               String                                       30 Treasurer street address - city                                  
 36 treasStreetStateCd                            String                                        2 Treasurer street address - state code (e.g. TX, CA) - for        
                                                                                                  country=USA/UMI only
 37 treasStreetCountyCd                           String                                        5 Treasurer street address - Texas county                          
 38 treasStreetCountryCd                          String                                        3 Treasurer street address - country (e.g. USA, UMI, MEX, CAN)     
 39 treasStreetPostalCode                         String                                       20 Treasurer street address - postal code - for USA addresses only  
 40 treasStreetRegion                             String                                       30 Treasurer street address - region for country other than USA     

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

Record #: 6     Record Name: CoverSheet3Data     Length: 1093
Description: Cover Sheet 3 - Committee purpose. The committee purpose is reported at the top of Cover Sheet Page 2 FORMNAME = CEC, GPAC, JSPAC,
             MCEC, MPAC, SCSPAC, SPAC, SPACSS.
             File: purpose.csv

 #  Field Name                                    Type       Mask                             Len Description
--- --------------------------------------------- ---------- ------------------------------ ----- -----------------------------------------------------------------
  1 recordType                                    String                                       20 Record type code - always CVR3                                   
  2 formTypeCd                                    String                                       20 TEC form used                                                    
  3 reportInfoIdent                               Long       00000000000                       11 Unique report #                                                  
  4 receivedDt                                    Date       yyyyMMdd                           8 Date report received by TEC                                      
  5 infoOnlyFlag                                  String                                        1 Superseded by other report                                       
  6 filerIdent                                    String                                      100 Filer account #                                                  
  7 filerTypeCd                                   String                                       30 Type of filer                                                    
  8 filerName                                     String                                      200 Filer name                                                       
  9 committeeActivityId                           Long       00000000000                       11 Committee activity unique identifier                             
 10 subjectCategoryCd                             String                                       30 Subject Category ()                                              
 11 subjectPositionCd                             String                                       30 Subject Position (SUPPORT, OPPOSE, ASSIST)                       
 12 subjectDescr                                  String                                      100 Subject description                                              
 13 subjectBallotNumber                           String                                       10 Ballot number                                                    
 14 subjectElectionDt                             Date       yyyyMMdd                           8 Election date                                                    
 15 activityHoldOfficeCd                          String                                       30 Activity office held                                             
 16 activityHoldOfficeDistrict                    String                                       11 Activity office held district                                    
 17 activityHoldOfficePlace                       String                                       11 Activity office held place                                       
 18 activityHoldOfficeDescr                       String                                      100 Activity office held description                                 
 19 activityHoldOfficeCountyCd                    String                                        5 Activity office held country code                                
 20 activityHoldOfficeCountyDescr                 String                                      100 Activity office help county description                          
 21 activitySeekOfficeCd                          String                                       30 Activity office sought                                           
 22 activitySeekOfficeDistrict                    String                                       11 Activity office sought district                                  
 23 activitySeekOfficePlace                       String                                       11 Activity office sought place                                     
 24 activitySeekOfficeDescr                       String                                      100 Activity office sought description                               
 25 activitySeekOfficeCountyCd                    String                                        5 Activity office sought county code                               
 26 activitySeekOfficeCountyDescr                 String                                      100 Activity office sought county description                        

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

Record #: 7     Record Name: CreditData     Length: 1101
Description: Credits - Schedule K - Interest, credits, gains, refunds, and contributions returned to filer.
             File: credits.csv

 #  Field Name                                    Type       Mask                             Len Description
--- --------------------------------------------- ---------- ------------------------------ ----- -----------------------------------------------------------------
  1 recordType                                    String                                       20 Record type code - always CRED                                   
  2 formTypeCd                                    String                                       20 TEC form used                                                    
  3 schedFormTypeCd                               String                                       20 TEC Schedule Used                                                
  4 reportInfoIdent                               Long       00000000000                       11 Unique report #                                                  
  5 receivedDt                                    Date       yyyyMMdd                           8 Date report received by TEC                                      
  6 infoOnlyFlag                                  String                                        1 Superseded by other report                                       
  7 filerIdent                                    String                                      100 Filer account #                                                  
  8 filerTypeCd                                   String                                       30 Type of filer                                                    
  9 filerName                                     String                                      200 Filer name                                                       
 10 creditInfoId                                  Long       00000000000                       11 Credit unique identifier                                         
 11 creditDt                                      Date       yyyyMMdd                           8 Credit date                                                      
 12 creditAmount                                  BigDecimal 0000000000.00                     12 Credit amount                                                    
 13 creditDescr                                   String                                      100 Credit description                                               
 14 payorPersentTypeCd                            String                                       30 Type of payor name data - INDIVIDUAL or ENTITY                   
 15 payorNameOrganization                         String                                      100 For ENTITY, the payor organization name                          
 16 payorNameLast                                 String                                      100 For INDIVIDUAL, the payor last name                              
 17 payorNameSuffixCd                             String                                       30 For INDIVIDUAL, the payor name suffix (e.g. JR, MD, II)          
 18 payorNameFirst                                String                                       45 For INDIVIDUAL, the payor first name                             
 19 payorNamePrefixCd                             String                                       30 For INDIVIDUAL, the payor name prefix (e.g. MR, MRS, MS)         
 20 payorNameShort                                String                                       25 For INDIVIDUAL, the payor short name (nickname)                  
 21 payorStreetAddr1                              String                                       55 Payor street address - line 1                                    
 22 payorStreetAddr2                              String                                       55 Payor street address - line 2                                    
 23 payorStreetCity                               String                                       30 Payor street address - city                                      
 24 payorStreetStateCd                            String                                        2 Payor street address - state code (e.g. TX, CA) - for            
                                                                                                  country=USA/UMI only
 25 payorStreetCountyCd                           String                                        5 Payor street address - Texas county                              
 26 payorStreetCountryCd                          String                                        3 Payor street address - country (e.g. USA, UMI, MEX, CAN)         
 27 payorStreetPostalCode                         String                                       20 Payor street address - postal code - for USA addresses only      
 28 payorStreetRegion                             String                                       30 Payor street address - region for country other than USA         

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

Record #: 8     Record Name: DebtData     Length: 3122
Description: Debts - Schedule L - Outstanding judicial loans.
             File: debts.csv

 #  Field Name                                    Type       Mask                             Len Description
--- --------------------------------------------- ---------- ------------------------------ ----- -----------------------------------------------------------------
  1 recordType                                    String                                       20 Record type code - always DEBT                                   
  2 formTypeCd                                    String                                       20 TEC form used                                                    
  3 schedFormTypeCd                               String                                       20 TEC Schedule Used                                                
  4 reportInfoIdent                               Long       00000000000                       11 Unique report #                                                  
  5 receivedDt                                    Date       yyyyMMdd                           8 Date report received by TEC                                      
  6 infoOnlyFlag                                  String                                        1 Superseded by other report                                       
  7 filerIdent                                    String                                      100 Filer account #                                                  
  8 filerTypeCd                                   String                                       30 Type of filer                                                    
  9 filerName                                     String                                      200 Filer name                                                       
 10 loanInfoId                                    Long       00000000000                       11 Loan unique identifier                                           
 11 loanGuaranteedFlag                            String                                        1 Loan guaranteed indicator                                        
 12 lenderPersentTypeCd                           String                                       30 Type of lender name data - INDIVIDUAL or ENTITY                  
 13 lenderNameOrganization                        String                                      100 For ENTITY, the lender organization name                         
 14 lenderNameLast                                String                                      100 For INDIVIDUAL, the lender last name                             
 15 lenderNameSuffixCd                            String                                       30 For INDIVIDUAL, the lender name suffix (e.g. JR, MD, II)         
 16 lenderNameFirst                               String                                       45 For INDIVIDUAL, the lender first name                            
 17 lenderNamePrefixCd                            String                                       30 For INDIVIDUAL, the lender name prefix (e.g. MR, MRS, MS)        
 18 lenderNameShort                               String                                       25 For INDIVIDUAL, the lender short name (nickname)                 
 19 lenderStreetCity                              String                                       30 Lender street address - city                                     
 20 lenderStreetStateCd                           String                                        2 Lender street address - state code (e.g. TX, CA) - for           
                                                                                                  country=USA/UMI only
 21 lenderStreetCountyCd                          String                                        5 Lender street address - Texas county                             
 22 lenderStreetCountryCd                         String                                        3 Lender street address - country (e.g. USA, UMI, MEX, CAN)        
 23 lenderStreetPostalCode                        String                                       20 Lender street address - postal code - for USA addresses only     
 24 lenderStreetRegion                            String                                       30 Lender street address - region for country other than USA        

    Array                                                                                    2250
    debtGuarantorLoanPersent[5/ROW_MAJOR]         CsvPublicExportDebtGuarantorLoanPersent     450 Loan guarantors (maxiumum 5)                                     
 25    guarantorPersentTypeCd                     String                                       30 Type of guarantor name data - INDIVIDUAL or ENTITY               
 26    guarantorNameOrganization                  String                                      100 For ENTITY, the guarantor organization name                      
 27    guarantorNameLast                          String                                      100 For INDIVIDUAL, the guarantor last name                          
 28    guarantorNameSuffixCd                      String                                       30 For INDIVIDUAL, the guarantor name suffix (e.g. JR, MD, II)      
 29    guarantorNameFirst                         String                                       45 For INDIVIDUAL, the guarantor first name                         
 30    guarantorNamePrefixCd                      String                                       30 For INDIVIDUAL, the guarantor name prefix (e.g. MR, MRS, MS)     
 31    guarantorNameShort                         String                                       25 For INDIVIDUAL, the guarantor short name (nickname)              
 32    guarantorStreetCity                        String                                       30 Guarantor street address - city                                  
 33    guarantorStreetStateCd                     String                                        2 Guarantor street address - state code (e.g. TX, CA) - for        
                                                                                                  country=USA/UMI only
 34    guarantorStreetCountyCd                    String                                        5 Guarantor street address - Texas county                          
 35    guarantorStreetCountryCd                   String                                        3 Guarantor street address - country (e.g. USA, UMI, MEX, CAN)     
 36    guarantorStreetPostalCode                  String                                       20 Guarantor street address - postal code - for USA addresses only  
 37    guarantorStreetRegion                      String                                       30 Guarantor street address - region for country other than USA     

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

Record #: 9     Record Name: ExpendData     Length: 1266
Description: Expenditures - Schedules F/G/H/I - Expenditures from special pre-election (formerly Telegram) reports are stored in the file 
             expn_t. They are kept separate from the expends file to avoid creating duplicates, because they are supposed to be re-reported on
             the next regular campaign finance report.
             Files: expend_##.csv, expn_t.csv

 #  Field Name                                    Type       Mask                             Len Description
--- --------------------------------------------- ---------- ------------------------------ ----- -----------------------------------------------------------------
  1 recordType                                    String                                       20 Record type code - always EXPN                                   
  2 formTypeCd                                    String                                       20 TEC form used                                                    
  3 schedFormTypeCd                               String                                       20 TEC Schedule Used                                                
  4 reportInfoIdent                               Long       00000000000                       11 Unique report #                                                  
  5 receivedDt                                    Date       yyyyMMdd                           8 Date report received by TEC                                      
  6 infoOnlyFlag                                  String                                        1 Superseded by other report                                       
  7 filerIdent                                    String                                      100 Filer account #                                                  
  8 filerTypeCd                                   String                                       30 Type of filer                                                    
  9 filerName                                     String                                      200 Filer name                                                       
 10 expendInfoId                                  Long       00000000000                       11 Expenditure unique identifier                                    
 11 expendDt                                      Date       yyyyMMdd                           8 Expenditure date                                                 
 12 expendAmount                                  BigDecimal 0000000000.00                     12 Expenditure amount                                               
 13 expendDescr                                   String                                      100 Expenditure description                                          
 14 expendCatCd                                   String                                       30 Expenditure category code                                        
 15 expendCatDescr                                String                                      100 Expenditure category description                                 
 16 itemizeFlag                                   String                                        1 Y indicates that the expenditure is itemized                     
 17 travelFlag                                    String                                        1 Y indicates that the expenditure has associated travel           
 18 politicalExpendCd                             String                                       30 Political expenditure indicator                                  
 19 reimburseIntendedFlag                         String                                        1 Reimbursement intended indicator                                 
 20 srcCorpContribFlag                            String                                        1 Expenditure from corporate funds indicator                       
 21 capitalLivingexpFlag                          String                                        1 Austin living expense indicator                                  
 22 payeePersentTypeCd                            String                                       30 Type of payee name data - INDIVIDUAL or ENTITY                   
 23 payeeNameOrganization                         String                                      100 For ENTITY, the payee organization name                          
 24 payeeNameLast                                 String                                      100 For INDIVIDUAL, the payee last name                              
 25 payeeNameSuffixCd                             String                                       30 For INDIVIDUAL, the payee name suffix (e.g. JR, MD, II)          
 26 payeeNameFirst                                String                                       45 For INDIVIDUAL, the payee first name                             
 27 payeeNamePrefixCd                             String                                       30 For INDIVIDUAL, the payee name prefix (e.g. MR, MRS, MS)         
 28 payeeNameShort                                String                                       25 For INDIVIDUAL, the payee short name (nickname)                  
 29 payeeStreetAddr1                              String                                       55 Payee street address - line 1                                    
 30 payeeStreetAddr2                              String                                       55 Payee street address - line 2                                    
 31 payeeStreetCity                               String                                       30 Payee street address - city                                      
 32 payeeStreetStateCd                            String                                        2 Payee street address - state code (e.g. TX, CA) - for            
                                                                                                  country=USA/UMI only
 33 payeeStreetCountyCd                           String                                        5 Payee street address - Texas county                              
 34 payeeStreetCountryCd                          String                                        3 Payee street address - country (e.g. USA, UMI, MEX, CAN)         
 35 payeeStreetPostalCode                         String                                       20 Payee street address - postal code - for USA addresses only      
 36 payeeStreetRegion                             String                                       30 Payee street address - region for country other than USA         

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

Record #: 10     Record Name: ExpendCategory     Length: 150
Description: Expenditure category codes.
             File: expn_catg.csv

 #  Field Name                                    Type       Mask                             Len Description
--- --------------------------------------------- ---------- ------------------------------ ----- -----------------------------------------------------------------
  1 recordType                                    String                                       20 Record type code - always EXCAT                                  
  2 expendCategoryCodeValue                       String                                       30 Expenditure category code                                        
  3 expendCategoryCodeLabel                       String                                      100 Expenditure category description                                 

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

Record #: 11     Record Name: FilerData     Length: 4529
Description: Filer index. The names, addresses and offices in this file are entered by TEC staff from various sources; e.g., amended campaign 
             treasurer appointments, change-of-address notices, and ballot information from the Texas Secretary of State.
             File: filers.csv

 #  Field Name                                    Type       Mask                             Len Description
--- --------------------------------------------- ---------- ------------------------------ ----- -----------------------------------------------------------------
  1 recordType                                    String                                       20 Record type code - always FILER                                  
  2 filerIdent                                    String                                      100 Filer account #                                                  
  3 filerTypeCd                                   String                                       30 Type of filer                                                    
  4 filerName                                     String                                      200 Filer name                                                       
  5 unexpendContribFilerFlag                      String                                        1 Unexpended contributions indicator                               
  6 modifiedElectCycleFlag                        String                                        1 Modified for election cycle indicator                            
  7 filerJdiCd                                    String                                       30 Judicial declaration of intent code                              
  8 committeeStatusCd                             String                                       30 PAC filing status code                                           
  9 ctaSeekOfficeCd                               String                                       30 CTA office sought                                                
 10 ctaSeekOfficeDistrict                         String                                       11 CTA office sought district                                       
 11 ctaSeekOfficePlace                            String                                       11 CTA office sought place                                          
 12 ctaSeekOfficeDescr                            String                                      100 CTA office sought description                                    
 13 ctaSeekOfficeCountyCd                         String                                        5 CTA office sought county code                                    
 14 ctaSeekOfficeCountyDescr                      String                                      100 CTA office sought county description                             
 15 filerPersentTypeCd                            String                                       30 Type of filer name data - INDIVIDUAL or ENTITY                   
 16 filerNameOrganization                         String                                      100 For ENTITY, the filer organization name                          
 17 filerNameLast                                 String                                      100 For INDIVIDUAL, the filer last name                              
 18 filerNameSuffixCd                             String                                       30 For INDIVIDUAL, the filer name suffix (e.g. JR, MD, II)          
 19 filerNameFirst                                String                                       45 For INDIVIDUAL, the filer first name                             
 20 filerNamePrefixCd                             String                                       30 For INDIVIDUAL, the filer name prefix (e.g. MR, MRS, MS)         
 21 filerNameShort                                String                                       25 For INDIVIDUAL, the filer short name (nickname)                  
 22 filerStreetAddr1                              String                                       55 Filer street address - line 1                                    
 23 filerStreetAddr2                              String                                       55 Filer street address - line 2                                    
 24 filerStreetCity                               String                                       30 Filer street address - city                                      
 25 filerStreetStateCd                            String                                        2 Filer street address - state code (e.g. TX, CA) - for            
                                                                                                  country=USA/UMI only
 26 filerStreetCountyCd                           String                                        5 Filer street address - Texas county                              
 27 filerStreetCountryCd                          String                                        3 Filer street address - country (e.g. USA, UMI, MEX, CAN)         
 28 filerStreetPostalCode                         String                                       20 Filer street address - postal code - for USA addresses only      
 29 filerStreetRegion                             String                                       30 Filer street address - region for country other than USA         
 30 filerMailingAddr1                             String                                       55 Filer mailing address - line 1                                   
 31 filerMailingAddr2                             String                                       55 Filer mailing address - line 2                                   
 32 filerMailingCity                              String                                       30 Filer mailing address - city                                     
 33 filerMailingStateCd                           String                                        2 Filer mailing address - state code (e.g. TX, CA) - for           
                                                                                                  country=USA/UMI only
 34 filerMailingCountyCd                          String                                        5 Filer mailing address - Texas county                             
 35 filerMailingCountryCd                         String                                        3 Filer mailing address - country (e.g. USA, UMI, MEX, CAN)        
 36 filerMailingPostalCode                        String                                       20 Filer mailing address - postal code - USA addresses only         
 37 filerMailingRegion                            String                                       30 Filer mailing address - region for country other than USA        
 38 filerPrimaryUsaPhoneFlag                      String                                        1 Filer primary phone number - Y if number is a USA phone, N       
                                                                                                  otherwise
 39 filerPrimaryPhoneNumber                       String                                       20 Filer primary phone number                                       
 40 filerPrimaryPhoneExt                          String                                       10 Filer primary phone extension                                    
 41 filerHoldOfficeCd                             String                                       30 Filer office held                                                
 42 filerHoldOfficeDistrict                       String                                       11 Filer office held district                                       
 43 filerHoldOfficePlace                          String                                       11 Filer office held place                                          
 44 filerHoldOfficeDescr                          String                                      100 Filer office held description                                    
 45 filerHoldOfficeCountyCd                       String                                        5 Filer office held country code                                   
 46 filerHoldOfficeCountyDescr                    String                                      100 Filer office help county description                             
 47 filerFilerpersStatusCd                        String                                       30 Filer status (CURRENT, etc)                                      
 48 filerEffStartDt                               Date       yyyyMMdd                           8 Filer start date                                                 
 49 filerEffStopDt                                Date       yyyyMMdd                           8 Filer end date                                                   
 50 contestSeekOfficeCd                           String                                       30 Filer office sought                                              
 51 contestSeekOfficeDistrict                     String                                       11 Filer office sought district                                     
 52 contestSeekOfficePlace                        String                                       11 Filer office sought place                                        
 53 contestSeekOfficeDescr                        String                                      100 Filer office sought description                                  
 54 contestSeekOfficeCountyCd                     String                                        5 Filer office sought county code                                  
 55 contestSeekOfficeCountyDescr                  String                                      100 Filer office sought county description                           
 56 treasPersentTypeCd                            String                                       30 Type of treasurer name data - INDIVIDUAL or ENTITY               
 57 treasNameOrganization                         String                                      100 For ENTITY, the treasurer organization name                      
 58 treasNameLast                                 String                                      100 For INDIVIDUAL, the treasurer last name                          
 59 treasNameSuffixCd                             String                                       30 For INDIVIDUAL, the treasurer name suffix (e.g. JR, MD, II)      
 60 treasNameFirst                                String                                       45 For INDIVIDUAL, the treasurer first name                         
 61 treasNamePrefixCd                             String                                       30 For INDIVIDUAL, the treasurer name prefix (e.g. MR, MRS, MS)     
 62 treasNameShort                                String                                       25 For INDIVIDUAL, the treasurer short name (nickname)              
 63 treasStreetAddr1                              String                                       55 Treasurer street address - line 1                                
 64 treasStreetAddr2                              String                                       55 Treasurer street address - line 2                                
 65 treasStreetCity                               String                                       30 Treasurer street address - city                                  
 66 treasStreetStateCd                            String                                        2 Treasurer street address - state code (e.g. TX, CA) - for        
                                                                                                  country=USA/UMI only
 67 treasStreetCountyCd                           String                                        5 Treasurer street address - Texas county                          
 68 treasStreetCountryCd                          String                                        3 Treasurer street address - country (e.g. USA, UMI, MEX, CAN)     
 69 treasStreetPostalCode                         String                                       20 Treasurer street address - postal code - for USA addresses only  
 70 treasStreetRegion                             String                                       30 Treasurer street address - region for country other than USA     
 71 treasMailingAddr1                             String                                       55 Treasurer mailing address - line 1                               
 72 treasMailingAddr2                             String                                       55 Treasurer mailing address - line 2                               
 73 treasMailingCity                              String                                       30 Treasurer mailing address - city                                 
 74 treasMailingStateCd                           String                                        2 Treasurer mailing address - state code (e.g. TX, CA) - for       
                                                                                                  country=USA/UMI only
 75 treasMailingCountyCd                          String                                        5 Treasurer mailing address - Texas county                         
 76 treasMailingCountryCd                         String                                        3 Treasurer mailing address - country (e.g. USA, UMI, MEX, CAN)    
 77 treasMailingPostalCode                        String                                       20 Treasurer mailing address - postal code - USA addresses only     
 78 treasMailingRegion                            String                                       30 Treasurer mailing address - region for country other than USA    
 79 treasPrimaryUsaPhoneFlag                      String                                        1 Treasurer primary phone number - Y if number is a USA phone, N   
                                                                                                  otherwise
 80 treasPrimaryPhoneNumber                       String                                       20 Treasurer primary phone number                                   
 81 treasPrimaryPhoneExt                          String                                       10 Treasurer primary phone extension                                
 82 treasAppointorNameLast                        String                                      100 For INDIVIDUAL, the treasurer last name                          
 83 treasAppointorNameFirst                       String                                       45 For INDIVIDUAL, the treasurer first name                         
 84 treasFilerpersStatusCd                        String                                       30 Treasurer status (CURRENT, etc)                                  
 85 treasEffStartDt                               Date       yyyyMMdd                           8 Treasurer start date                                             
 86 treasEffStopDt                                Date       yyyyMMdd                           8 Treasurer end date                                               
 87 assttreasPersentTypeCd                        String                                       30 Type of asst treasurer name data - INDIVIDUAL or ENTITY          
 88 assttreasNameOrganization                     String                                      100 For ENTITY, the asst treasurer organization name                 
 89 assttreasNameLast                             String                                      100 For INDIVIDUAL, the asst treasurer last name                     
 90 assttreasNameSuffixCd                         String                                       30 For INDIVIDUAL, the asst treasurer name suffix (e.g. JR, MD, II) 
 91 assttreasNameFirst                            String                                       45 For INDIVIDUAL, the asst treasurer first name                    
 92 assttreasNamePrefixCd                         String                                       30 For INDIVIDUAL, the asst treasurer name prefix (e.g. MR, MRS, MS)
 93 assttreasNameShort                            String                                       25 For INDIVIDUAL, the asst treasurer short name (nickname)         
 94 assttreasStreetAddr1                          String                                       55 Asst treasurer street address - line 1                           
 95 assttreasStreetAddr2                          String                                       55 Asst treasurer street address - line 2                           
 96 assttreasStreetCity                           String                                       30 Asst treasurer street address - city                             
 97 assttreasStreetStateCd                        String                                        2 Asst treasurer street address - state code (e.g. TX, CA) - for   
                                                                                                  country=USA/UMI only
 98 assttreasStreetCountyCd                       String                                        5 Asst treasurer street address - Texas county                     
 99 assttreasStreetCountryCd                      String                                        3 Asst treasurer street address - country (e.g. USA, UMI, MEX, CAN)
100 assttreasStreetPostalCode                     String                                       20 Asst treasurer street address - postal code - for USA addresses  
                                                                                                  only
101 assttreasStreetRegion                         String                                       30 Asst treasurer street address - region for country other than USA
102 assttreasPrimaryUsaPhoneFlag                  String                                        1 Asst treasurer primary phone number - Y if number is a USA phone,
                                                                                                  N otherwise
103 assttreasPrimaryPhoneNumber                   String                                       20 Asst treasurer primary phone number                              
104 assttreasPrimaryPhoneExt                      String                                       10 Asst treasurer primary phone extension                           
105 assttreasAppointorNameLast                    String                                      100 For INDIVIDUAL, the asst treasurer last name                     
106 assttreasAppointorNameFirst                   String                                       45 For INDIVIDUAL, the asst treasurer first name                    
107 chairPersentTypeCd                            String                                       30 Type of chair name data - INDIVIDUAL or ENTITY                   
108 chairNameOrganization                         String                                      100 For ENTITY, the chair organization name                          
109 chairNameLast                                 String                                      100 For INDIVIDUAL, the chair last name                              
110 chairNameSuffixCd                             String                                       30 For INDIVIDUAL, the chair name suffix (e.g. JR, MD, II)          
111 chairNameFirst                                String                                       45 For INDIVIDUAL, the chair first name                             
112 chairNamePrefixCd                             String                                       30 For INDIVIDUAL, the chair name prefix (e.g. MR, MRS, MS)         
113 chairNameShort                                String                                       25 For INDIVIDUAL, the chair short name (nickname)                  
114 chairStreetAddr1                              String                                       55 Chair street address - line 1                                    
115 chairStreetAddr2                              String                                       55 Chair street address - line 2                                    
116 chairStreetCity                               String                                       30 Chair street address - city                                      
117 chairStreetStateCd                            String                                        2 Chair street address - state code (e.g. TX, CA) - for            
                                                                                                  country=USA/UMI only
118 chairStreetCountyCd                           String                                        5 Chair street address - Texas county                              
119 chairStreetCountryCd                          String                                        3 Chair street address - country (e.g. USA, UMI, MEX, CAN)         
120 chairStreetPostalCode                         String                                       20 Chair street address - postal code - for USA addresses only      
121 chairStreetRegion                             String                                       30 Chair street address - region for country other than USA         
122 chairMailingAddr1                             String                                       55 Chair mailing address - line 1                                   
123 chairMailingAddr2                             String                                       55 Chair mailing address - line 2                                   
124 chairMailingCity                              String                                       30 Chair mailing address - city                                     
125 chairMailingStateCd                           String                                        2 Chair mailing address - state code (e.g. TX, CA) - for           
                                                                                                  country=USA/UMI only
126 chairMailingCountyCd                          String                                        5 Chair mailing address - Texas county                             
127 chairMailingCountryCd                         String                                        3 Chair mailing address - country (e.g. USA, UMI, MEX, CAN)        
128 chairMailingPostalCode                        String                                       20 Chair mailing address - postal code - USA addresses only         
129 chairMailingRegion                            String                                       30 Chair mailing address - region for country other than USA        
130 chairPrimaryUsaPhoneFlag                      String                                        1 Chair primary phone number - Y if number is a USA phone, N       
                                                                                                  otherwise
131 chairPrimaryPhoneNumber                       String                                       20 Chair primary phone number                                       
132 chairPrimaryPhoneExt                          String                                       10 Chair primary phone extension                                    

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

Record #: 12     Record Name: FinalData     Length: 393
Description: Final reports.
             File: final.csv

 #  Field Name                                    Type       Mask                             Len Description
--- --------------------------------------------- ---------- ------------------------------ ----- -----------------------------------------------------------------
  1 recordType                                    String                                       20 Record type code - always FINL                                   
  2 formTypeCd                                    String                                       20 TEC form used                                                    
  3 reportInfoIdent                               Long       00000000000                       11 Unique report #                                                  
  4 receivedDt                                    Date       yyyyMMdd                           8 Date report received by TEC                                      
  5 infoOnlyFlag                                  String                                        1 Superseded by other report                                       
  6 filerIdent                                    String                                      100 Filer account #                                                  
  7 filerTypeCd                                   String                                       30 Type of filer                                                    
  8 filerName                                     String                                      200 Filer name                                                       
  9 finalUnexpendContribFlag                      String                                        1 Unexpended contributions indicator                               
 10 finalRetainedAssetsFlag                       String                                        1 Retained assets indicator                                        
 11 finalOfficeholderAckFlag                      String                                        1 Office holder ack indicator                                      

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

Record #: 13     Record Name: LoanData     Length: 5695
Description: Loans - Schedule E.
             File: loans.csv

 #  Field Name                                    Type       Mask                             Len Description
--- --------------------------------------------- ---------- ------------------------------ ----- -----------------------------------------------------------------
  1 recordType                                    String                                       20 Record type code - always LOAN                                   
  2 formTypeCd                                    String                                       20 TEC form used                                                    
  3 schedFormTypeCd                               String                                       20 TEC Schedule Used                                                
  4 reportInfoIdent                               Long       00000000000                       11 Unique report #                                                  
  5 receivedDt                                    Date       yyyyMMdd                           8 Date report received by TEC                                      
  6 infoOnlyFlag                                  String                                        1 Superseded by other report                                       
  7 filerIdent                                    String                                      100 Filer account #                                                  
  8 filerTypeCd                                   String                                       30 Type of filer                                                    
  9 filerName                                     String                                      200 Filer name                                                       
 10 loanInfoId                                    Long       00000000000                       11 Loan unique identifier                                           
 11 loanDt                                        Date       yyyyMMdd                           8 Loan date                                                        
 12 loanAmount                                    BigDecimal 0000000000.00                     12 Loan amount                                                      
 13 loanDescr                                     String                                      100 Loan description                                                 
 14 interestRate                                  String                                       15 Interest rate                                                    
 15 maturityDt                                    Date       yyyyMMdd                           8 Loan maturity date                                               
 16 collateralFlag                                String                                        1 Collateral indicator                                             
 17 collateralDescr                               String                                      100 Collateral description                                           
 18 loanStatusCd                                  String                                       30 Loan status (1STRPT, RPTUNPAID, RPTPAID)                         
 19 paymentMadeFlag                               String                                        1 Payment made indicator                                           
 20 paymentAmount                                 BigDecimal 0000000000.00                     12 Payment amount                                                   
 21 paymentSource                                 String                                      100 Source of payment                                                
 22 loanGuaranteedFlag                            String                                        1 Loan guaranteed indicator                                        
 23 financialInstitutionFlag                      String                                        1 Financial institution indicator                                  
 24 loanGuaranteeAmount                           BigDecimal 0000000000.00                     12 Loan guarantee amount                                            
 25 lenderPersentTypeCd                           String                                       30 Type of lender name data - INDIVIDUAL or ENTITY                  
 26 lenderNameOrganization                        String                                      100 For ENTITY, the lender organization name                         
 27 lenderNameLast                                String                                      100 For INDIVIDUAL, the lender last name                             
 28 lenderNameSuffixCd                            String                                       30 For INDIVIDUAL, the lender name suffix (e.g. JR, MD, II)         
 29 lenderNameFirst                               String                                       45 For INDIVIDUAL, the lender first name                            
 30 lenderNamePrefixCd                            String                                       30 For INDIVIDUAL, the lender name prefix (e.g. MR, MRS, MS)        
 31 lenderNameShort                               String                                       25 For INDIVIDUAL, the lender short name (nickname)                 
 32 lenderStreetCity                              String                                       30 Lender street address - city                                     
 33 lenderStreetStateCd                           String                                        2 Lender street address - state code (e.g. TX, CA) - for           
                                                                                                  country=USA/UMI only
 34 lenderStreetCountyCd                          String                                        5 Lender street address - Texas county                             
 35 lenderStreetCountryCd                         String                                        3 Lender street address - country (e.g. USA, UMI, MEX, CAN)        
 36 lenderStreetPostalCode                        String                                       20 Lender street address - postal code - for USA addresses only     
 37 lenderStreetRegion                            String                                       30 Lender street address - region for country other than USA        
 38 lenderEmployer                                String                                       60 Lender employer                                                  
 39 lenderOccupation                              String                                       60 Lender occupation                                                
 40 lenderJobTitle                                String                                       60 Lender job title                                                 
 41 lenderPacFein                                 String                                       12 FEC ID of out-of-state PAC lender                                
 42 lenderOosPacFlag                              String                                        1 Indicates if lender is an out-of-state PAC                       
 43 lenderSpouseLawFirmName                       String                                       60 Lender spouse law firm name                                      
 44 lenderParent1LawFirmName                      String                                       60 Lender parent #1 law firm name                                   
 45 lenderParent2LawFirmName                      String                                       60 Lender parent #2 law firm name                                   

    Array                                                                                    4050
    loanGuarantorLoanPersent[5/ROW_MAJOR]         CsvPublicExportLoanGuarantorLoanPersent     810 Guarantors for the loan (maximum 5)                              
 46    guarantorPersentTypeCd                     String                                       30 Type of guarantor name data - INDIVIDUAL or ENTITY               
 47    guarantorNameOrganization                  String                                      100 For ENTITY, the guarantor organization name                      
 48    guarantorNameLast                          String                                      100 For INDIVIDUAL, the guarantor last name                          
 49    guarantorNameSuffixCd                      String                                       30 For INDIVIDUAL, the guarantor name suffix (e.g. JR, MD, II)      
 50    guarantorNameFirst                         String                                       45 For INDIVIDUAL, the guarantor first name                         
 51    guarantorNamePrefixCd                      String                                       30 For INDIVIDUAL, the guarantor name prefix (e.g. MR, MRS, MS)     
 52    guarantorNameShort                         String                                       25 For INDIVIDUAL, the guarantor short name (nickname)              
 53    guarantorStreetCity                        String                                       30 Guarantor street address - city                                  
 54    guarantorStreetStateCd                     String                                        2 Guarantor street address - state code (e.g. TX, CA) - for        
                                                                                                  country=USA/UMI only
 55    guarantorStreetCountyCd                    String                                        5 Guarantor street address - Texas county                          
 56    guarantorStreetCountryCd                   String                                        3 Guarantor street address - country (e.g. USA, UMI, MEX, CAN)     
 57    guarantorStreetPostalCode                  String                                       20 Guarantor street address - postal code - for USA addresses only  
 58    guarantorStreetRegion                      String                                       30 Guarantor street address - region for country other than USA     
 59    guarantorEmployer                          String                                       60 Guarantor employer                                               
 60    guarantorOccupation                        String                                       60 Guarantor occupation                                             
 61    guarantorJobTitle                          String                                       60 Guarantor job title                                              
 62    guarantorSpouseLawFirmName                 String                                       60 Guarantor spouse law firm name                                   
 63    guarantorParent1LawFirmName                String                                       60 Guarantor parent #1 law firm name                                
 64    guarantorParent2LawFirmName                String                                       60 Guarantor parent #2 law firm name                                

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

Record #: 14     Record Name: PledgeData     Length: 1366
Description: Pledges - Schedule B - Pledges from special session and special pre-election (formerly Telegram) reports are stored in the file 
             pldg_ss and pldg_t. These records are kept separate from the pledges files to avoid creating duplicates, because they are supposed
             to be re-reported on the next regular campaign finance report.
             Files: pledges.csv, pldg_ss.csv, pldg_t.csv

 #  Field Name                                    Type       Mask                             Len Description
--- --------------------------------------------- ---------- ------------------------------ ----- -----------------------------------------------------------------
  1 recordType                                    String                                       20 Record type code - always PLDG                                   
  2 formTypeCd                                    String                                       20 TEC form used                                                    
  3 schedFormTypeCd                               String                                       20 TEC Schedule Used                                                
  4 reportInfoIdent                               Long       00000000000                       11 Unique report #                                                  
  5 receivedDt                                    Date       yyyyMMdd                           8 Date report received by TEC                                      
  6 infoOnlyFlag                                  String                                        1 Superseded by other report                                       
  7 filerIdent                                    String                                      100 Filer account #                                                  
  8 filerTypeCd                                   String                                       30 Type of filer                                                    
  9 filerName                                     String                                      200 Filer name                                                       
 10 pledgeInfoId                                  Long       00000000000                       11 Pledge unique identifier                                         
 11 pledgeDt                                      Date       yyyyMMdd                           8 Pledge data                                                      
 12 pledgeAmount                                  BigDecimal 0000000000.00                     12 Pledge amount                                                    
 13 pledgeDescr                                   String                                      100 Pledge description                                               
 14 itemizeFlag                                   String                                        1 Y indicates that the pledge is itemized                          
 15 travelFlag                                    String                                        1 Y indicates that the pledge has associated travel                
 16 pledgerPersentTypeCd                          String                                       30 Type of pledger name data - INDIVIDUAL or ENTITY                 
 17 pledgerNameOrganization                       String                                      100 For ENTITY, the pledger organization name                        
 18 pledgerNameLast                               String                                      100 For INDIVIDUAL, the pledger last name                            
 19 pledgerNameSuffixCd                           String                                       30 For INDIVIDUAL, the pledger name suffix (e.g. JR, MD, II)        
 20 pledgerNameFirst                              String                                       45 For INDIVIDUAL, the pledger first name                           
 21 pledgerNamePrefixCd                           String                                       30 For INDIVIDUAL, the pledger name prefix (e.g. MR, MRS, MS)       
 22 pledgerNameShort                              String                                       25 For INDIVIDUAL, the pledger short name (nickname)                
 23 pledgerStreetCity                             String                                       30 Pledger street address - city                                    
 24 pledgerStreetStateCd                          String                                        2 Pledger street address - state code (e.g. TX, CA) - for          
                                                                                                  country=USA/UMI only
 25 pledgerStreetCountyCd                         String                                        5 Pledger street address - Texas county                            
 26 pledgerStreetCountryCd                        String                                        3 Pledger street address - country (e.g. USA, UMI, MEX, CAN)       
 27 pledgerStreetPostalCode                       String                                       20 Pledger street address - postal code - for USA addresses only    
 28 pledgerStreetRegion                           String                                       30 Pledger street address - region for country other than USA       
 29 pledgerEmployer                               String                                       60 Pledger employer                                                 
 30 pledgerOccupation                             String                                       60 Pledger occupation                                               
 31 pledgerJobTitle                               String                                       60 Pledger job title                                                
 32 pledgerPacFein                                String                                       12 For PAC pledger the FEIN                                         
 33 pledgerOosPacFlag                             String                                        1 Indicates if pledger is an out-of-state PAC                      
 34 pledgerSpouseLawFirmName                      String                                       60 Pledger spouse law firm name                                     
 35 pledgerParent1LawFirmName                     String                                       60 Pledger parent #1 law firm name                                  
 36 pledgerParent2LawFirmName                     String                                       60 Pledger parent #2 law firm name                                  

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

Record #: 15     Record Name: SpacData     Length: 1644
Description: Index of Specific-purpose committees. This file contains links between specific-purpose committees (FILER_TYPE = SPAC, JSPC and 
             SCPC) and the candidates/office holders they support, oppose or assist. The information is entered by TEC staff from the paper 
             Form STA (treasurer appointment for a speficic- purpose committee) and amendments thereto (Form ASTA). TEC staff does not enter 
             links based on information from campaign finance reports. The links are not broken when the STA is terminated.
             File: spacs.csv

 #  Field Name                                    Type       Mask                             Len Description
--- --------------------------------------------- ---------- ------------------------------ ----- -----------------------------------------------------------------
  1 recordType                                    String                                       20 Record type code - always SPAC                                   
  2 spacFilerIdent                                String                                      100 SPAC filer account #                                             
  3 spacFilerTypeCd                               String                                       30 SPAC type of filer                                               
  4 spacFilerName                                 String                                      200 SPAC filer name                                                  
  5 spacFilerNameShort                            String                                       25 SPAC acronym                                                     
  6 spacCommitteeStatusCd                         String                                       30 SPAC committee status (ACTIVE, TERMINATED)                       
  7 spactreasEffStartDt                           Date       yyyyMMdd                           8 SPAC treasurer start date                                        
  8 spactreasEffStopDt                            Date       yyyyMMdd                           8 SPAC treasurer end date                                          
  9 spacPositionCd                                String                                       30 SPAC position (SUPPORT, OPPOSE, ASSIST)                          
 10 candidateFilerIdent                           String                                      100 Candidate filer account #                                        
 11 candidateFilerTypeCd                          String                                       30 Candidate type of filer                                          
 12 candidateFilerName                            String                                      200 Candidate filer name                                             
 13 candidateFilerpersStatusCd                    String                                       30 Candidate status (CURRENT, etc)                                  
 14 candidateEffStartDt                           Date       yyyyMMdd                           8 Candidate start date                                             
 15 candidateEffStopDt                            Date       yyyyMMdd                           8 Candidate end date                                               
 16 candidateHoldOfficeCd                         String                                       30 Candidate office held                                            
 17 candidateHoldOfficeDistrict                   String                                       11 Candidate office held district                                   
 18 candidateHoldOfficePlace                      String                                       11 Candidate office held place                                      
 19 candidateHoldOfficeDescr                      String                                      100 Candidate office held description                                
 20 candidateHoldOfficeCountyCd                   String                                        5 Candidate office held country code                               
 21 candidateHoldOfficeCountyDescr                String                                      100 Candidate office help county description                         
 22 candidateSeekOfficeCd                         String                                       30 Candidate office sought                                          
 23 candidateSeekOfficeDistrict                   String                                       11 Candidate office sought district                                 
 24 candidateSeekOfficePlace                      String                                       11 Candidate office sought place                                    
 25 candidateSeekOfficeDescr                      String                                      100 Candidate office sought description                              
 26 candidateSeekOfficeCountyCd                   String                                        5 Candidate office sought county code                              
 27 candidateSeekOfficeCountyDescr                String                                      100 Candidate office sought county description                       
 28 ctaSeekOfficeCd                               String                                       30 CTA office sought                                                
 29 ctaSeekOfficeDistrict                         String                                       11 CTA office sought district                                       
 30 ctaSeekOfficePlace                            String                                       11 CTA office sought place                                          
 31 ctaSeekOfficeDescr                            String                                      100 CTA office sought description                                    
 32 ctaSeekOfficeCountyCd                         String                                        5 CTA office sought county code                                    
 33 ctaSeekOfficeCountyDescr                      String                                      100 CTA office sought county description                             
 34 candtreasFilerpersStatusCd                    String                                       30 Candidate treasurer status (CURRENT, etc)                        
 35 candtreasEffStartDt                           Date       yyyyMMdd                           8 Candidate treasurer start date                                   
 36 candtreasEffStopDt                            Date       yyyyMMdd                           8 Candidate treasurer end date                                     

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

Record #: 16     Record Name: TravelData     Length: 1433
Description: Travel outside the State of Texas - Schedule T - Travel records are linked to records in contribs, pledges and expenditure files 
             through the fields parentType and parentId. They store information about in-kind contributions accepted for travel outside the 
             State of Texas and for expenditures made for travel outside the State of Texas.
             File: travel.csv

 #  Field Name                                    Type       Mask                             Len Description
--- --------------------------------------------- ---------- ------------------------------ ----- -----------------------------------------------------------------
  1 recordType                                    String                                       20 Record type code - always TRVL                                   
  2 formTypeCd                                    String                                       20 TEC form used                                                    
  3 schedFormTypeCd                               String                                       20 TEC Schedule Used                                                
  4 reportInfoIdent                               Long       00000000000                       11 Unique report #                                                  
  5 receivedDt                                    Date       yyyyMMdd                           8 Date report received by TEC                                      
  6 infoOnlyFlag                                  String                                        1 Superseded by other report                                       
  7 filerIdent                                    String                                      100 Filer account #                                                  
  8 filerTypeCd                                   String                                       30 Type of filer                                                    
  9 filerName                                     String                                      200 Filer name                                                       
 10 travelInfoId                                  Long       00000000000                       11 Travel unique identifier                                         
 11 parentType                                    String                                       20 Parent record type (CONTRIB, EXPEND, PLEDGE)                     
 12 parentId                                      Long       00000000000                       11 Parent unique identifier                                         
 13 parentDt                                      Date       yyyyMMdd                           8 Date of parent transaction                                       
 14 parentAmount                                  BigDecimal 0000000000.00                     12 Amount of parent transaction                                     
 15 parentFullName                                String                                      100 Full name associated with parent                                 
 16 transportationTypeCd                          String                                       30 Type of transportation (COMMAIR, PRIVAIR, etc)                   
 17 transportationTypeDescr                       String                                      100 Transporation type description                                   
 18 departureCity                                 String                                       50 Departure city                                                   
 19 arrivalCity                                   String                                       50 Arrival city                                                     
 20 departureDt                                   Date       yyyyMMdd                           8 Departure date                                                   
 21 arrivalDt                                     Date       yyyyMMdd                           8 Arrival date                                                     
 22 travelPurpose                                 String                                      255 Purpose of travel                                                
 23 travellerPersentTypeCd                        String                                       30 Type of traveller name data - INDIVIDUAL or ENTITY               
 24 travellerNameOrganization                     String                                      100 For ENTITY, the traveller organization name                      
 25 travellerNameLast                             String                                      100 For INDIVIDUAL, the traveller last name                          
 26 travellerNameSuffixCd                         String                                       30 For INDIVIDUAL, the traveller name suffix (e.g. JR, MD, II)      
 27 travellerNameFirst                            String                                       45 For INDIVIDUAL, the traveller first name                         
 28 travellerNamePrefixCd                         String                                       30 For INDIVIDUAL, the traveller name prefix (e.g. MR, MRS, MS)     
 29 travellerNameShort                            String                                       25 For INDIVIDUAL, the traveller short name (nickname)              

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
Legend:
 Type: Data type for the field.
 Mask: For numeric and date fields, a DecimalFormat or SimpleDateFormat mask. BWZ indicates 'Blank When Zero'
 Len: Length of the field.
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
