    West Virginia Contracts Cleaning - TAP

West Virginia Contracts Cleaning - TAP
======================================

#### Kevin Shrawder

#### 9/27/2020

## Project

The Accountability Project is an effort to cut across data silos and give journalists, policy professionals, activists, and the public at large a simple way to search across huge volumes of public data about people and organizations.

Our goal is to standardizing public data on a few key fields by thinking of each dataset row as a transaction. For each transaction there should be (at least) 7 varaibles:

1.  Payment Order Number - Identifier for the contract
2.  Payer Department Abbreviation - Which department is the vendor contracting for
3.  FiscalYear - Fiscal Year the contract was issued (West Virginia fiscal year begins on July 1 of each calendar year. For instance, the 2020 fiscal year began July 1, 2019 and ended June 30, 2020)
4.  VendorName - Name of the entity who received the contract
5.  Payment Order Type - General overview of the services required
6.  Payment Order Description - Detailed description of the contract services
7.  PaymentOrder Total - Amount of Money involved
8.  ContractLocationState - The state in which the contract is being executed, not the state in which the company resides (all should be WV for this data set)

## Objectives

The following section describes the process used to complete and verify the following objectives:

*   How many records are in the database?
*   Check for entirely duplicated records.
*   Check ranges of continuous variables.
*   Is there anything blank or missing?
*   Check for consistency issues.
*   Expand on the `year` field to ensure clarity.

## Software

This data is processed using the free, open-source statistical computing language R, which can be installed from CRAN \[[https://cran.r-project.org/](https://cran.r-project.org/)\] for various opperating systems. For example, R can be installed from the apt package repository on Ubuntu.

The following additional R packages are needed to collect, manipulate, visualize, analyze, and communicate these results. The `tidyverse` package will facilitate their installation and attachment.

    library(tidyverse)

## Data

The data was obtained via a Freedom of Information Act to the West Virginina Purchasing Department.

Read data into R.

    df <- readxl::read_excel('Updated Imaging System Report.xlsx')

## Processing

Change names of column headers for clarity. Ensure FY indicator is fully present by including leading numbers for the year. Ensure all columns are free of any data reading errors such as extra spaces, accidental characters in numerical categories, etc.

    df %>%
      select(PaymentOrder_Prefix = `PO PREFIX`, PaymentOrder_Number = `PO NO.`, PaymentOrder_SplitOrder = `PO SPLIT`, ChangeOrder_Number = `CO NO`, DepartmentAbbreviation = `DEPT NAME`, FiscalYear = `FY`, VendorName = `VENDOR NAME`, VendorNumber = `VENDOR NO`, PaymentOrder_Type = `PO TYPE`, PaymentOrder_Description = `PO DESCRIPTION`, PaymentOrder_Total = `PO TOTAL`) %>%
      mutate(FiscalYear = ifelse(nchar(FiscalYear) == 1, str_c('200', FiscalYear), str_c('20', FiscalYear))) %>%
      mutate(PaymentOrder_Prefix = str_trim(str_squish(parse_character(PaymentOrder_Prefix))),
             PaymentOrder_Number = str_trim(str_squish(parse_character(PaymentOrder_Number))),
             PaymentOrder_SplitOrder = str_trim(str_squish(parse_character(PaymentOrder_SplitOrder))),
             DepartmentAbbreviation = str_trim(str_squish(parse_character(DepartmentAbbreviation))),
             VendorName = str_trim(str_squish(parse_character(VendorName))),
             VendorNumber = str_replace_all(str_trim(str_squish(parse_character(VendorNumber))), '\\*', ''),
             PaymentOrder_Type = str_trim(str_squish(parse_character(PaymentOrder_Type))),
             PaymentOrder_Description = str_trim(str_squish(parse_character(PaymentOrder_Description)))) ->
      df1

Check for issues where the vendor name is present, but no vendor number. Add vendor number based on duplicate vendor names within the data and check again for missing vendor numbers. Correct some misspellings and re-run the vendor number filler. Check final number of unidentified vendor names. Number seems relatively small.

    #Initital count of the number of entires without a vendor name or number
    df1 %>%
      filter(is.na(VendorName) & !is.na(VendorNumber)) %>%
      count()

    ## # A tibble: 1 x 1
    ##       n
    ##   <int>
    ## 1     0

    #Comoparing that to the number of vectors which are complete, and those inherently without a vendor number due to having multiple vendors on the same contract
    
    df1 %>%
      filter(!is.na(VendorName) & is.na(VendorNumber)) %>%
      filter(!str_detect(VendorName, str_c('MULTIPLE', 'NO', 'NON', 'MULTI', 'MULITIPLE', 'VARIOUS', sep = '|', collapse = T))) %>%
      count()

    ## # A tibble: 1 x 1
    ##       n
    ##   <int>
    ## 1  2404

    #Identify vectors to be reconciled
      
    df1 %>%
      filter(!is.na(VendorNumber)) %>%
      select(VendorName, VendorNumber) %>%
      distinct() ->
      recVectors
    
    #Reconcile the missing vendor names or vendor numbers
    
    for(i in 1:length(df1$VendorName)){
      if(!is.na(df1$VendorName[i]) & is.na(df1$VendorNumber[i])){
        if(!str_detect(df1$VendorName[i], str_c('MULTIPLE', 'NO', 'NON', 'MULTI', 'MULTIPLE', 'VARIOUS', sep = '|', collapse = T))){
          if(df1$VendorName[i] %in% recVectors$VendorName){
            for(j in 1:length(recVectors$VendorName)){
              if(df1$VendorName[i] == recVectors$VendorName[j]){
                df1$VendorNumber[i] <- recVectors$VendorNumber[j] 
              }
            }
          }
        }
      }
    }
    
    #Identify vendor names that are not specified
    
    df1 %>%
      filter(!is.na(VendorName) & is.na(VendorNumber)) %>%
      filter(!str_detect(VendorName, str_c('MULTIPLE', 'NO', 'NON', 'MULTI', 'MULITIPLE', 'VARIOUS', sep = '|', collapse = T))) %>%
      count()

    ## # A tibble: 1 x 1
    ##       n
    ##   <int>
    ## 1   195

    #Reconcile the data entry errors of mispelled vendor names
    
    df1 %>%
      mutate(VendorName = str_replace(VendorName, 'ARCHITECURE', 'ARCHITECTURE'),
             VendorName = str_replace(VendorName,'ALL QUALITY', 'ALL QUALITY LLC'),
             VendorName = str_replace(VendorName,'-', ' '),
             VendorName = str_replace(VendorName,'EMC CORP', 'EMC CORPORATION'),
             VendorName = str_replace(VendorName,'WILSON RESTORATION', 'WILSON RESTORATION INC'),
             VendorName = str_replace(VendorName,'RYAN ENVIRONMENTAL LLC', 'RYAN ENVIRONMENTAL INC'),
             VendorName = str_replace(VendorName,'GIBBONS & KAWASH A C', 'GIBBONS & KAWASH AC'),
             VendorName = str_replace(VendorName,'THE MURPHEY ELEVATOR CO INC', 'MURPHY ELEVATOR CO INC'),
             VendorName = str_replace(VendorName,'LOGA CONCRETE INC', 'LOGAN CONCRETE INC'),
             VendorName = str_replace(VendorName,'SUPERIOR SUPPLY', 'SUPERIOR SUPPLY COMPANY INC'),
             VendorName = str_replace(VendorName,'SNYDER ENVIROMENTAL SERVICES INC', 'SNYDER ENVIRONMENTAL SERVICES INC' ),
             VendorName = str_replace(VendorName,'SNYDER ENVIRONMENTAL SERVICES INC INC', 'SNYDER ENVIRONMENTAL SERVICES INC' ),
             VendorName = str_replace(VendorName,'NATIONAL TRAVEL SERVICES INC', 'NATIONAL TRAVEL SERVICE INC'),
             VendorName = str_replace(VendorName,'WHITESIDE OF ST CLAIRSVILLE IN', 'WHITESIDE OF ST CLAIRSVILLE INC'),
             VendorName = str_replace(VendorName,'CHAPMAN TECHINICAL GROUP LTD', 'CHAPMAN TECHNICAL GROUP LTD'),
             VendorName = str_replace(VendorName,'NATIONAL BUS SALES & LEASING 1', 'NATIONAL BUS SALES & LEASING I'),
             VendorName = str_replace(VendorName,'WV ASSOC OF REHAB FACILIES', 'WV ASSOC OF REHAB FACILITIES'),
             VendorName = str_replace(VendorName,'AMERIGAS PROPAINE LP', 'AMERIGAS PROPANE LP'),
             VendorName = str_replace(VendorName,'THORNHILL GROUPS LLC', 'THORNHILL GROUP INC'),
             VendorName = str_replace(VendorName,'C & B BLUEPRINT CO', 'C&B BLUEPRINT INC'),
             VendorName = str_replace(VendorName,'SPEPHENS AUTO CENTER', 'STEPHENS AUTO CENTER'),
             VendorName = str_replace(VendorName,'BUSINESS SVCS VERIZON', 'VERIZON BUSINESS SERVS'),
             VendorName = str_replace(VendorName,'MCALLISTER CONSTRUCTION LLC', 'SI MCALLISTER CONSTRUCTION CO'),
             VendorName = str_replace(VendorName,'DEBORAH O BARRY', 'BARRY DEBORAH O'),
             VendorName = str_replace(VendorName,'MID ATLANTIC STORAGE SYSTEMS 1', 'MID ATLANTIC STORAGE SYSTEMS I'),
             VendorName = str_replace(VendorName,'POWER PRODUCTS', 'POWER PRODUCTS INC'),
             VendorName = str_replace(VendorName,'GOV DEALS INC', 'GOVDEALS INC'),
             VendorName = str_replace(VendorName,'WV PAVING', 'WV PAVING INC'),
             VendorName = str_replace(VendorName,'JF ALLEN CO', 'J F ALLEN CO'),
             VendorName = str_replace(VendorName,'MOUNTAIN AGGREGATES', 'MOUNTAIN AGGREGATES INC'),
             VendorName = str_replace(VendorName,'OHIO RIVER AGGREGATES', 'OHIO RIVER AGGREGATE INC'),
             VendorName = str_replace(VendorName,'XPEDX', 'XPEDX LLC'),
             VendorName = str_replace(VendorName,'WINCHESTER SPEECH PATHOLOGIST', 'WINCHESTER SPEECH PATHOLOGISTS'),
             VendorName = str_replace(VendorName,'BURROUGHS INC', 'BURROUGHS PAYMENT SYSTEMS INC'),
             VendorName = str_replace(VendorName,'SUMMIT ELECTRIC GROUP', 'SUMMIT ELECTRIC GROUP INC'),
             VendorName = str_replace(VendorName,'SOFTCHOICE CORP', 'SOFTCHOICE CORPORATION'),
             VendorName = str_replace(VendorName,'SOLID ROCK EXCAVATING, INC.', 'SOLID ROCK EXCAVATING INC'),
             VendorName = str_replace(VendorName,'KOBETRON LLC', 'KOBETRON INC'),
             VendorName = str_replace(VendorName,'L-3 COMMUNICATIONS CORP', 'L3 TECHNOLOGIES INC'),
             VendorName = str_replace(VendorName,'GIBBONS & KAWASH, A.C.', 'GIBBONS & KAWASH AC'),
             VendorName = str_replace(VendorName,'MATHENY COMMERCIAL TRUCKS', 'MATHENY MOTOR TRUCK CO'),
             VendorName = str_replace(VendorName,'BREAKAWAY, INC', 'BREAKAWAY INC'),
             VendorName = str_replace(VendorName,'R R DONNELLEY', 'R R DONNELLEY & SONS CO'),
             VendorName = str_replace(VendorName,'CELL STAFF, LLC', 'CELL STAFF LLC'),
             VendorName = str_replace(VendorName,'M S CONSULTANTS INC', 'MS CONSULTANTS INC'),
             VendorName = str_replace(VendorName,'STAR LINEN', 'STAR LINEN INC'),
             VendorName = str_replace(VendorName,'NETWORK FOR EDUCATIONAL TELECOMPUTI', 'WV NETWORK FOR EDUCATIONAL TEL'),
             VendorName = str_replace(VendorName,'VIRTRA SYSTEMS, INC', 'VIRTRA SYSTEMS'),
             VendorName = str_replace(VendorName,'ADVANCED COMMUNICATIONS CO', 'ADVANCED COMMUNICATIONS'),
             VendorName = str_replace(VendorName,'NEWTECH SYSTEMS, INC', 'NEWTECH SYSTEMS INC'),
             VendorName = str_replace(VendorName,'CHESAPEAKE THERMITE WELDING LL', 'CHESAPEAKE THERMITE WELDING LLC'),
             VendorName = str_replace(VendorName,'RADON MEDICAL IMAGING CORP OF WV', 'RADON MEDICAL IMAGING CORP WV'),
             VendorName = str_replace(VendorName,'EASTERN ARROW CORP IN', 'EASTERN ARROW CORP INC'),
             VendorName = str_replace(VendorName,'RT ROGERS OIL COMPANY INC', 'R T ROGERS OIL CO INC'),
             VendorName = str_replace(VendorName,'RTC GIS, INC.', 'RTC GIS INC'),
             VendorName = str_replace(VendorName,'BETSON PITTSBURGH DISTRIBUTING CO', 'BETSON COIN OP DISTRIBUTING CO'),
             VendorName = str_replace(VendorName,'BETSON PITTSBURGH DISTRIBUTING', 'BETSON COIN OP DISTRIBUTING CO'),
             VendorName = str_replace(VendorName,'J P MORGAN ELECTRONIC FINANCIAL SVC', 'J P MORGAN ELECTRONIC FINANCIAL SVS'),
             VendorName = str_replace(VendorName,'DIGITAL RELATIVITY, LLC', 'DIGITAL RELATIVITY LLC'),
             VendorName = str_replace(VendorName,'SOUTHERN WEST VIRGINIA INC', 'SOUTHERN WV ASPHALT INC'),
             VendorName = str_replace(VendorName,'SOUTHERN WEST VIRGINIA ASPHALT, INC', 'SOUTHERN WV ASPHALT INC'),
             VendorName = str_replace(VendorName,'CARR CONCRETE CORP', 'CARR CONCRETE CORPORATION'),
             VendorName = str_replace(VendorName,'THOMAS E. GUTHRIE INVESTIGATION', 'THOMAS E GUTHRIE INVESTIGATIONS LLC'),
             VendorName = str_replace(VendorName,'NITRO CARPET OUTLET', 'NITRO ELECTRIC CO INC'),
             VendorName = str_replace(VendorName,'WISEMAN CONSTRUCTION CO IN', 'WISEMAN CONSTRUCTION CO INC'),
             VendorName = str_replace(VendorName,'ELERT & ASSOCIATES NETWORKING DIVISI', 'ELERT & ASSOCIATES NETWORKING DIVIS'),
             VendorName = str_replace(VendorName,'CENTER FOR HEALTH CARE STRATEGIES,', 'CENTER FOR HEALTH CARE STRATEGIES I'),
             VendorName = str_replace(VendorName,'DRUG TESTING CENTERS OF AMERICA', 'DRUG TESTING CENTERS OF AMERIC'),
             VendorName = str_replace(VendorName,'VENTOSA ELITE K9 KENNEL, INC', 'VENTOSA ELITE K9 KENNEL INC'),
             VendorName = str_replace(VendorName,'LAND O LAKES, INC', 'LAND O LAKES INC'),
             VendorName = str_replace(VendorName,'NEIGHBORGALL CONSTRUCTION COMPANY', 'NEIGHBORGALL CONSTRUCTION COMP'),
             VendorName = str_replace(VendorName,'AMERICAN NATIONAL SKYLINE INC OF O', 'AMERICAN NATIONAL SKYLINE INC OF OH'),
             VendorName = str_replace(VendorName,'MOORE CONCRETE PLUMBING', 'MOORE CONCRETE PUMPING'),
             VendorName = str_replace(VendorName,'BOXLEY CONCRETE PRODUCTS OF VA INC', 'BOXLEY CONCRETE PRODUCTS OF WV'),
             VendorName = str_replace(VendorName,'L. ADKINS OIL', 'L ADKINS OIL INC'),
             VendorName = str_replace(VendorName,'J&J FABRICATING', 'J & J FABRICATING & TRAILERS INC'),
             VendorName = str_replace(VendorName,'BURDETTE ELECTRIC, INC', 'BURDETTE ELECTRIC INC'),
             VendorName = str_replace(VendorName,'LUSHER TRUCKING CO. INC','LUSHER TRUCKING CO INC'),
             VendorName = str_replace(VendorName,'WVU BUREAU OF BUSINESS RESEARCH', 'WVU BUREAU OF BUSINESS RESEARC'),
             VendorName = str_replace(VendorName,'PJ DICK INC', 'P J DICK INCORPORATED'),
             VendorName = str_replace(VendorName,'P J DICK INC','P J DICK INCORPORATED'),
             VendorName = str_replace(VendorName,'P J DICK INCORPORATEDORPORATED','P J DICK INCORPORATED'),
             VendorName = str_replace(VendorName, 'MYERS AND STAUFFER LC', 'MYERS & STAUFFER LC'),
             VendorName = str_replace(VendorName, 'GIBRAL TAR CABLE BARRIER SYSTEM LP', 'GIBRALTAR CABLE BARRIER SYSTEM LP'),
             VendorName = str_replace(VendorName, 'SNYDER ENVIROMENTAL SERVICES', 'SNYDER ENVIRONMENTAL SERVICES INC'),
             VendorName = str_replace(VendorName, 'THORNHILL GROUPS INC', 'THORNHILL GROUP INC'),
             VendorName = str_replace(VendorName, 'L 3 COMMUNICATIONS CORP', 'L3 TECHNOLOGIES INC'),
             VendorName = str_replace(VendorName, 'VIRTRA SYSTEMS INC', 'VIRTRA SYSTEMS'),
             VendorName = str_replace(VendorName, 'OM OFFICE SUPPLY INC', 'O M OFFICE SUPPLY INC'),
             VendorName = str_replace(VendorName, 'ELERT & ASSOCITES NETWORKING DIVIS', 'ELERT & ASSOCIATES NETWORKING DIVIS'),
             VendorName = str_replace(VendorName, 'GAS STRUCTURAL ENGINEERING INC', 'CAS STRUCTURAL ENGINEERING INC'),
             VendorName = str_replace(VendorName, 'INDUSTRIAL COMMERCIAL RESIDENTIAL E', 'INDUSTRIAL COMMERCIAL RESIDENTIAL'),
             VendorName = str_replace(VendorName, 'LESLIE EQUIPMENT CO INC', 'LESLIE EQUIPMENT CO'),
             VendorName = str_replace(VendorName, 'TOOMBS TRUCKING & EQUIPMENT CO INC', 'TOOMBS TRUCK & EQUIPMENT CO INC'),
             VendorName = str_replace(VendorName, 'AMERICAN NATIONAL SKYLINE, INC OF O', 'AMERICAN NATIONAL SKYLINE INC OF OH')) ->
      df1
    
    #Re-run the reconciliation loops to catch any that may have been missed from the 
    
    for(i in 1:length(df1$VendorName)){
      if(!is.na(df1$VendorName[i]) & is.na(df1$VendorNumber[i])){
        if(!str_detect(df1$VendorName[i], str_c('MULTIPLE', 'NO', 'NON', 'MULTI', 'MULTIPLE', 'VARIOUS', sep = '|', collapse = T))){
          if(df1$VendorName[i] %in% recVectors$VendorName){
            for(j in 1:length(recVectors$VendorName)){
              if(df1$VendorName[i] == recVectors$VendorName[j]){
                df1$VendorNumber[i] <- recVectors$VendorNumber[j] 
              }
            }
          }
        }
      }
    }
    
    #count the number of remining entries without the vendor name or ID
    
    df1 %>%
      filter(!is.na(VendorName) & is.na(VendorNumber)) %>%
      filter(!str_detect(VendorName, str_c('MULTIPLE', 'NO', 'NON', 'MULTI', 'MULITIPLE', 'VARIOUS', sep = '|', collapse = T))) %>%
      count()

    ## # A tibble: 1 x 1
    ##       n
    ##   <int>
    ## 1    75

Check payment split order identifier to see if there are any issues. It appears there may be an issue with data entry in a few columns, edited them.

    #Identify the unique number of split orders present in the data
    unique(df1$PaymentOrder_SplitOrder)

    ##   [1] NA    "A"   "B"   "F"   "C"   "D"   "E"   "G"   "H"   "1"   "ZA"  "DD" 
    ##  [13] "I"   "J"   "K"   "L"   "M"   "N"   "O"   "P"   "Q"   "R"   "S"   "T"  
    ##  [25] "U"   "V"   "W"   "X"   "Y"   "Z"   "AA"  "BB"  "CC"  "EE"  "FF"  "GG" 
    ##  [37] "HH"  "II"  "JJ"  "KK"  "LL"  "MM"  "NN"  "III" "OO"  "PP"  "QQ"  "RR" 
    ##  [49] "SS"  "TT"  "UU"  "VV"  "WW"  "XX"  "YY"  "ZZ"  "BBB" "CCC" "DDD" "EEE"
    ##  [61] "FFF" "GGG" "HHH" "AB"  "AC"  "AD"  "AF"  "AG"  "AH"  "AI"  "AJ"  "AK" 
    ##  [73] "AL"  "FA"  "AAA" "AE"  "DB"  "BA"  "AM"  "AN"  "ZC"  "DA"  "HA"  "AO" 
    ##  [85] "AP"  "AQ"  "AR"  "AT"  "AU"  "AV"  "AW"  "AX"  "AY"  "AZ"  "AAB" "AAC"
    ##  [97] "AAD" "AAE" "AAG" "AAI" "AAJ" "AAK" "AAL" "AAM" "AAN" "AAP" "AAQ" "AAR"
    ## [109] "AAS" "AAT" "AAU" "AAV" "AAW" "AAX" "AAY" "AAZ" "ABA" "ACA" "ADA" "AEA"
    ## [121] "AFA" "AGA" "AHA" "AIA" "AJA" "AKA" "ALA" "AMA" "ANA" "AOA" "EA"  "CA" 
    ## [133] "AS"  "CB"  "BE"  "BF"  "BI"  "BJ"  "BK"  "BL"  "BM"  "BN"  "BO"  "BR" 
    ## [145] "BS"  "BT"  "BU"  "BV"  "BW"  "BX"  "BY"  "BZ"  "OA"  "CD"  "CE"  "CF" 
    ## [157] "CG"  "VA"  "CH"  "CI"  "CJ"  "2"   "BD"  "VB"  "VE"  "VD"  "GA"  "LA" 
    ## [169] "DE"  "DC"  "VC"  "CAA" "11"  "4"   "UA"  "WA"  "19"

    #Recitify data entry errors of the payment order split identifier; also fix one payment order prefix issue
    df1 %>%
      mutate(PaymentOrder_Prefix = ifelse(PaymentOrder_Prefix == '+', 'SWC', PaymentOrder_Prefix),
             PaymentOrder_SplitOrder = ifelse(PaymentOrder_SplitOrder == '1', 'A', PaymentOrder_SplitOrder),
             PaymentOrder_SplitOrder = ifelse(PaymentOrder_SplitOrder == '11', NA, PaymentOrder_SplitOrder),
             PaymentOrder_SplitOrder = ifelse(PaymentOrder_SplitOrder == '2', NA, PaymentOrder_SplitOrder),
             PaymentOrder_SplitOrder = ifelse(PaymentOrder_Number == '106436', NA, PaymentOrder_SplitOrder),
             PaymentOrder_SplitOrder = ifelse(PaymentOrder_SplitOrder == '19', NA, PaymentOrder_SplitOrder)) ->
      df2

Checking for duplicate values, it appears that there are some so we will remove those.

    #Count the number of duplicate entries
    df2[duplicated(df2),] %>%
      count()

    ## # A tibble: 1 x 1
    ##       n
    ##   <int>
    ## 1   196

    #Remove the duplicate entries
    df2 %>%
      distinct() ->
      df3

Check for issues with a few other variables. Change Order seems to have some issues. Upon further investigation, they were special cases and entered incorrectly.

    #Look at the unique values of FiscalYear to see if there are any inconcistances
    df3 %>%
      select(FiscalYear) %>%
      unique()

    ## # A tibble: 15 x 1
    ##    FiscalYear
    ##    <chr>     
    ##  1 2006      
    ##  2 2007      
    ##  3 2008      
    ##  4 2009      
    ##  5 2010      
    ##  6 2011      
    ##  7 2012      
    ##  8 2013      
    ##  9 2014      
    ## 10 2015      
    ## 11 2016      
    ## 12 2017      
    ## 13 2018      
    ## 14 2019      
    ## 15 2020

    #Check for the unique values of the payment order prefix to see if there are any inconsistances
    df3 %>%
      select(PaymentOrder_Prefix) %>%
      unique()

    ## # A tibble: 178 x 1
    ##    PaymentOrder_Prefix
    ##    <chr>              
    ##  1 DEP                
    ##  2 HHR                
    ##  3 BPH                
    ##  4 CSE                
    ##  5 BHS                
    ##  6 EHS                
    ##  7 LBS                
    ##  8 BCF                
    ##  9 DMV                
    ## 10 GSD                
    ## # ... with 168 more rows

    #Check for the unique values of the change order entries to see if there are any inconsistances
    df3 %>%
      select(ChangeOrder_Number) %>%
      unique() %>%
      arrange(ChangeOrder_Number)

    ## # A tibble: 77 x 1
    ##    ChangeOrder_Number
    ##                 <dbl>
    ##  1                  0
    ##  2                  1
    ##  3                  2
    ##  4                  3
    ##  5                  4
    ##  6                  5
    ##  7                  6
    ##  8                  7
    ##  9                  8
    ## 10                  9
    ## # ... with 67 more rows

    #Check for the unique values of the payment order type to see if there are any inconsistances
    df3 %>%
      select(PaymentOrder_Type) %>%
      unique()

    ## # A tibble: 14 x 1
    ##    PaymentOrder_Type                    
    ##    <chr>                                
    ##  1 F CONSTRUCTION                       
    ##  2 B AGENCY CONTRACT                    
    ##  3 R REGULAR PURCHASE (RFQ)             
    ##  4 D DIRECT PURCHASE                    
    ##  5 E EQUIPMENT RELEASE ORDER            
    ##  6 I ATTACHMENT (ADDITIONAL INFORMATION)
    ##  7 C STATEWIDE CONTRACT                 
    ##  8 N NO AWARD                           
    ##  9 X EMERGENCY PURCHASE                 
    ## 10 P REQUEST FOR PROPOSAL (RFP)         
    ## 11 <NA>                                 
    ## 12 A AGREEMENT                          
    ## 13 O CHANGE ORDER                       
    ## 14 Q REQUEST FOR INFORMATION (RFI)

    #Check for the unique values of the change order prefix to see if there are any inconsistances
    df3 %>%
      filter(PaymentOrder_Type == 'O CHANGE ORDER' & is.na(ChangeOrder_Number)) %>%
      count()

    ## # A tibble: 1 x 1
    ##       n
    ##   <int>
    ## 1   111

Inheritances were identified in the change order check. Fix change order numbering issues.

    df3 %>%
      mutate(ChangeOrder_Number = ifelse(ChangeOrder_Number == 43837, '1 - 7', ifelse(ChangeOrder_Number == 43838, '1 - 8', ChangeOrder_Number))) ->
      df3

Fix issues where the description identifies a change order, but change order is not selected. Also fixes an issue where the change order becomes mis-ordered due to adding a new change order into the mix.

    for(i in 1:length(df3$PaymentOrder_Type)){
      if(is.na(df3$PaymentOrder_Type[i])){
        
      }else if(df3$PaymentOrder_Type[i] == 'O CHANGE ORDER'){
        if(is.na(df3$ChangeOrder_Number[i]) == TRUE){
          temp <- df3$PaymentOrder_Number[i]
          df3 %>%
            filter(PaymentOrder_Number == temp) %>%
            count() ->
            look
          
          
          
            df3 %>%
              filter(PaymentOrder_Number == temp) %>%
              arrange(parse_number(FiscalYear), parse_number(ChangeOrder_Number)) ->
              temp2
            
            which(is.na(temp2$ChangeOrder_Number)) ->
              CO_fill
            
            df3$ChangeOrder_Number[i] <- CO_fill
        }
      }
    }
    
    
    df3 %>%
      filter(PaymentOrder_Type == 'O CHANGE ORDER') %>%
      group_by(PaymentOrder_Number) %>%
      mutate(ChangeOrder_Number = order(order(FiscalYear, ChangeOrder_Number)),) %>%
      ungroup() %>%
      mutate(ChangeOrder_Number = as.character(ChangeOrder_Number))->
      reOrdered
    
    
    df3 %>%
      filter(PaymentOrder_Type != 'O CHANGE ORDER' | is.na(PaymentOrder_Type)) %>%
      bind_rows(reOrdered) %>%
      mutate(ContractLocationState = 'WV') -> #Add the state in which the contract is executed
      df4

Write final file to CSV.

    df4[is.na(df4)] <- '' #Ensure the proper encoding for null values is an empty value instead of a NA entry

    write_csv(df4, 'WestVirginiaContracts.csv')

## Conclusion

1.  There are 41933 records in the database.
2.  There are 1535 records missing key variables.
3.  The 4-digit FiscalYear variable has been created with lubridate::year().

The data is now cleaned and ready for processing into the TAP servers, and then mapped into the website for indexing and searching.

