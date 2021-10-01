     WV Contracts and Political Contributions Merging

WV Contracts and Political Contributions Merging
================================================

#### Kevin Shrawder

#### 11/23/2020

## Project

The Accountability Project is an effort to cut across data silos and give journalists, policy professionals, activists, and the public at large a simple way to search across huge volumes of public data about people and organizations.

Our goal is to standardizing public data on a few key fields by thinking of each dataset row as a transaction.

## Objectives

This document describes the process used to complete the following objectives:

1.  Prepare contracts and contributions from West Virginia for combination to search for relations
2.  Merge the data sets
3.  Check for vendors who also made contributions
4.  Create new column in the contracts file that includes a flag for each observation indicating whether the vendor has contributed to a West Virginia political campaign between 2018 - 2020 (data available for campaign contributions).

## Packages

The following packages are needed to collect, manipulate, visualize, analyze, and communicate these results. The `tiddyverse` package will facilitate their installation and attachment.

The `RecordLinkage` package will also have to be installed. This package contains functions custom made to help facilitate the processing of records including calculating the levenshtein distances and similarities.

    library(tidyverse)
    library(RecordLinkage)

## Data

Data is obtained from the West Virginia Purchasing Division and the West Virginia [Secretary of State](https://cfrs.wvsos.gov/#/dataDownload) contributions and loans data. For information on how to process preceding data files, please see additional documentation on The Accountability Project’s Github site ([https://github.com/irworkshop/accountability\_datacleaning](https://github.com/irworkshop/accountability_datacleaning)).

    df18 <- read_csv('CON_2018.csv')
    df19 <- read_csv('CON_2019.csv')
    df20 <- read_csv('CON_2020.csv')
    
    contracts <- read_csv('WestVirginiaContracts_fy2006_fy2020.csv')

Combine all of the contributions data for 2018 - 2020 into one full data set, reduce the dimension of the data by selecting only the relevant variables and filtering out all political contributions that are not from a business or organization.

    df18 %>%
      rbind(df19, df20) %>%
      select(`Receipt Amount`, `Receipt Date`, `Last Name`, Address1, City, State, Zip, `Receipt Source Type`, `Receipt Type`, `Committee Type`, `Candidate Name`, Employer, Occupation, `Contribution Type`, `Receipt ID`) %>%
      filter(`Receipt Source Type` == 'Business or Organization') %>%
      filter(!is.na(`Last Name`)) %>%
      mutate(`Last Name` = str_squish(str_trim(parse_character(`Last Name`))),
             `Last Name` = str_replace(`Last Name`, '&', 'and'),
             `Last Name` = str_replace(`Last Name`, '.', ''),
             `Last Name` = str_replace(`Last Name`, '-', ''),
             `Last Name` = str_replace(`Last Name`, ',', ''))->
      contributions

Re-process the contracts data so it will be easier to merge with the contributions data. Select only the relevant variables and complete string processing on the vendor names such that it is standardized with the political contributions data.

    contracts %>%
      select(PaymentOrder_Number, FiscalYear, VendorName, VendorNumber, PaymentOrder_Type, PaymentOrder_Total) %>%
      mutate(VendorName = str_to_title(VendorName),
             VendorName = str_squish(str_trim(parse_character(VendorName)))) %>%
      mutate(VendorName = str_replace(VendorName, '&', 'and'),
             VendorName = str_replace(VendorName, '.', ''),
             VendorName = str_replace(VendorName, '-', ''),
             VendorName = str_replace(VendorName, ',', '')) %>%
      filter(!is.na(VendorName)) ->
      cntracts

Search the contracts data and compare the vendor names with the list of business contributors in the contributions file.

    cntracts$RECEIPTMATCH <- c()
    for(i in 1:length(cntracts$PaymentOrder_Number)){
      appendicies <- c()
      temp2 <- c()
      distancesVec <- c()
      for(j in 1:length(contributions$`Last Name`)){
        temp <- levenshteinSim(cntracts$VendorName[i], contributions$`Last Name`[j]) #Calculate the similarities between each business name and vendor name
        appendicies <- c(appendicies, contributions$`Receipt ID`[j]) #Gather the the receipt ID from the contributions data file into a temporary vector
        distancesVec <- c(distancesVec, temp) #Gather the similarities of each comparison into a temporary vector
      }
      cntracts$RECEIPTMATCH[i] <- appendicies[which.max(distancesVec)] #Determine the most probable match between the vendor name and the contributor company name
      cntracts$SIM[i] <- distancesVec[which.max(distancesVec)] #Add the receipt ID of the most probable match 
    }

Once the receipt ID’s have been matched to the contracts data set, filter the calculated levenstein’s distance and similarities to ensure only the most probable matches are evaluated.

    cntracts %>%
      mutate(RECEIPTMATCH = ifelse(SIM < .7, '', RECEIPTMATCH),  #Replace the Receipt and SIM values value with null if the similarity is below a 70% match between vendor name and most probable business name
             SIM = ifelse(SIM < .7, '', SIM)) %>%
      merge(contributions, by.x = 'RECEIPTMATCH', by.y = 'Receipt ID') %>% #Add the contributions data to the contracts data by the remaining receipt ID's
      mutate(dst = levenshteinDist(VendorName, `Last Name`)) %>% #Compute levenstein distance between the vendor name and the business contributor name
      select(VendorName, `Last Name`, SIM, dst) %>% #Select relevant variables
      arrange(desc(SIM), dst) ->
      step1

The step1 vectors were analyzed by hand to determine if a match should indeed be considered a match, or if it should be removed. A text file of the matches to remove was created by manually adding those which should be removed into the text file, separated by a comma.

Read in the aforementioned text file indicating which values should not be considered matches and process the data.

    discard <- read_delim('remove.txt', delim = ',')%>% 
      mutate(A = str_squish(str_trim(parse_character(A))),
             B = str_squish(str_trim(parse_character(B))))

Once the data is processed, remove the unintended matches from the final list of matched receipts and contract numbers.

    cntracts %>%
      mutate(RECEIPTMATCH = ifelse(SIM < .7, '', RECEIPTMATCH),
             SIM = ifelse(SIM < .7, '', SIM)) %>%
      merge(contributions, by.x = 'RECEIPTMATCH', by.y = 'Receipt ID') %>%
      mutate(dst = levenshteinDist(VendorName, `Last Name`),
             VendorName = str_squish(str_trim(parse_character(VendorName))),
             `Last Name` = str_squish(str_trim(parse_character(`Last Name`)))) ->
       step2
    
    for(i in 1:length(step2$RECEIPTMATCH)){
      for(j in 1:length(discard$A)){
        if(step2$VendorName[i] == discard$A[j] & step2$`Last Name`[i] == discard$B[j]){
          step2$RECEIPTMATCH[i] <- NA
        }
      }
    }
    
    step2 %>%
      filter(!is.na(RECEIPTMATCH)) %>%
      select(VendorName, `Last Name`, SIM, dst) -> #Final hand check that remaining matches are correct
      checkvec

With the final list of matches between contributors and vendors, return to the contracts data set and create a new column which includes a 1 if the vendor has contributed to a political campaign, and a 0 if they have not.

    step2 %>%
      filter(!is.na(RECEIPTMATCH)) %>%
      select(PaymentOrder_Number, `Receipt Type`) ->
      CONTRIBFLAG
    
    cntracts %>%
      left_join(CONTRIBFLAG, by = 'PaymentOrder_Number') %>%
      mutate(CampFinContribFlag = ifelse(is.na(`Receipt Type`), 0, 1)) %>%
      select(-`Receipt Type`) ->
      matchedContribContracts

Write the final file to a CSV for the final analysis

    write_csv(matchedContribContracts, 'Contributions_Contracts_Matched.csv')

## Conclusion

The political contributions data is now merged with the vendor contracts data for the State of West Virginia and ready for additional analysis. It should be noted that this merging process requires a large amount of computing power and may take several hours to finish processing.

