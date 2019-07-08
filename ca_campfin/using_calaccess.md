# Preparing and loading CalAccess data
## (For certain itemizations of Form 460)

The folks at [CalAccess](https://www.californiacivicdata.org/) have done a ton of work with the state's raw data files. Using their work, it's much less painful to grab the relatively few line itemizations that we're interested in making searchable.


You can find a link to the downloadable tables for form 460 in the appendix below, thanks to James Gordon. We're going to ignore most of the tables and just focus on certain classes of giving and spending, just using the filing tables as needed to populate details. In general we want to use the current files, not the "version" ones.

### Goal

We want to make contributions searchable. They mostly appear on form 460, although more research is needed to understand what else we should include.

In general we're going to standardize the input files to have the same header rows. That generally means adding a few empty rows that are missing in each datafile. 

We also need to join each of the line items to some data from filers.csv. These files are not huge and can be read into memory and joined with files as we go. It's possible there's other data that we need, but it would be awesome to be able to grab everything we need from filers.csv.

Once we are able to process contributions, we should write a similar process for expenditures. 





### Contributions

The schedules we need to use are listed in [the github docstrings](https://github.com/california-civic-data-coalition/django-calaccess-processed-data/blob/master/calaccess_processed_filings/models/campaign/base/contribution.py#L11) ; money into a political org using this form gets reported on Schedules A, C and I. 


We can read more in Cal Access' [awesome form description](https://calaccess.californiacivicdata.org/documentation/calaccess-forms/f460/).

Schedule A are "regular" contributions, and they represent the vast majority of the itemizations.

Schedules C is for "Non-Monetary Contributions Received" and is  just like Schedule A except with two added columns: `fair_market_value` and `contribution_description`.

Schedule I is "Miscellanous increases to cash". It's the same as A but has a `receipt_description` field.

We will put all three files in a .csv file with common headers.


### Expenditures

The [expenditures](https://github.com/california-civic-data-coalition/django-calaccess-processed-data/blob/master/calaccess_processed_filings/models/campaign/base/expenditure.py#L15) on Form 460 are on schedules D, E and G. 

According to the [form description](https://calaccess.californiacivicdata.org/documentation/calaccess-forms/f460/) those are: 

- Schedule D, Summary of Expenditures Supporting / Opposing Other Candidates, Measures and Committees"
- Schedule E, Payments Made 
- Schedule G, Payments Made by an Agent or Independent Contractor (on Behalf of This Committee) 

Similarly as to contributions, we are going to put these into files with the same headers. 

### Loans

We haven't done anything with loans. They are [found on](https://github.com/california-civic-data-coalition/django-calaccess-processed-data/blob/master/calaccess_processed_filings/models/campaign/base/loan.py#L15) "Schedules B (Parts 1 and 2) and H of
    Form 460 filings"

 

### Appendix
Here are links to the downloadable tables. Many of these can be ignored for our purposes.  The versioned files include `filing_version_id` instead of `filing_id`, I believe these include data from earlier filing versions even when they have been superseded by a later filing amendment, but need to confirm.


- [https://calaccess.download/latest/Form460Filing.csv](https://calaccess.download/latest/Form460Filing.csv)
- [https://calaccess.download/latest/Form460FilingVersion.csv](https://calaccess.download/latest/Form460FilingVersion.csv)
- [https://calaccess.download/latest/Form460ScheduleAItem.csv](https://calaccess.download/latest/Form460ScheduleAItem.csv)
- [https://calaccess.download/latest/Form460ScheduleAItemVersion.csv](https://calaccess.download/latest/Form460ScheduleAItemVersion.csv)
- [https://calaccess.download/latest/Form460ScheduleASummary.csv](https://calaccess.download/latest/Form460ScheduleASummary.csv)
- [https://calaccess.download/latest/Form460ScheduleASummaryVersion.csv](https://calaccess.download/latest/Form460ScheduleASummaryVersion.csv)
- [https://calaccess.download/latest/Form460ScheduleB1Item.csv](https://calaccess.download/latest/Form460ScheduleB1Item.csv)
- [https://calaccess.download/latest/Form460ScheduleB1ItemVersion.csv](https://calaccess.download/latest/Form460ScheduleB1ItemVersion.csv)
- [https://calaccess.download/latest/Form460ScheduleB2Item.csv](https://calaccess.download/latest/Form460ScheduleB2Item.csv)
- [https://calaccess.download/latest/Form460ScheduleB2ItemOld.csv](https://calaccess.download/latest/Form460ScheduleB2ItemOld.csv)
- [https://calaccess.download/latest/Form460ScheduleB2ItemVersion.csv](https://calaccess.download/latest/Form460ScheduleB2ItemVersion.csv)
- [https://calaccess.download/latest/Form460ScheduleB2ItemVersionOld.csv](https://calaccess.download/latest/Form460ScheduleB2ItemVersionOld.csv)
- [https://calaccess.download/latest/Form460ScheduleCItem.csv](https://calaccess.download/latest/Form460ScheduleCItem.csv)
- [https://calaccess.download/latest/Form460ScheduleCItemVersion.csv](https://calaccess.download/latest/Form460ScheduleCItemVersion.csv)
- [https://calaccess.download/latest/Form460ScheduleCSummary.csv](https://calaccess.download/latest/Form460ScheduleCSummary.csv)
- [https://calaccess.download/latest/Form460ScheduleCSummaryVersion.csv](https://calaccess.download/latest/Form460ScheduleCSummaryVersion.csv)
- [https://calaccess.download/latest/Form460ScheduleDItem.csv](https://calaccess.download/latest/Form460ScheduleDItem.csv)
- [https://calaccess.download/latest/Form460ScheduleDItemVersion.csv](https://calaccess.download/latest/Form460ScheduleDItemVersion.csv)
- [https://calaccess.download/latest/Form460ScheduleEItem.csv](https://calaccess.download/latest/Form460ScheduleEItem.csv)
- [https://calaccess.download/latest/Form460ScheduleEItemVersion.csv](https://calaccess.download/latest/Form460ScheduleEItemVersion.csv)
- [https://calaccess.download/latest/Form460ScheduleESubItem.csv](https://calaccess.download/latest/Form460ScheduleESubItem.csv)
- [https://calaccess.download/latest/Form460ScheduleESubItemVersion.csv](https://calaccess.download/latest/Form460ScheduleESubItemVersion.csv)
- [https://calaccess.download/latest/Form460ScheduleESummary.csv](https://calaccess.download/latest/Form460ScheduleESummary.csv)
- [https://calaccess.download/latest/Form460ScheduleESummaryVersion.csv](https://calaccess.download/latest/Form460ScheduleESummaryVersion.csv)
- [https://calaccess.download/latest/Form460ScheduleFItem.csv](https://calaccess.download/latest/Form460ScheduleFItem.csv)
- [https://calaccess.download/latest/Form460ScheduleFItemVersion.csv](https://calaccess.download/latest/Form460ScheduleFItemVersion.csv)
- [https://calaccess.download/latest/Form460ScheduleGItem.csv](https://calaccess.download/latest/Form460ScheduleGItem.csv)
- [https://calaccess.download/latest/Form460ScheduleGItemVersion.csv](https://calaccess.download/latest/Form460ScheduleGItemVersion.csv)
- [https://calaccess.download/latest/Form460ScheduleH2ItemOld.csv](https://calaccess.download/latest/Form460ScheduleH2ItemOld.csv)
- [https://calaccess.download/latest/Form460ScheduleH2ItemVersionOld.csv](https://calaccess.download/latest/Form460ScheduleH2ItemVersionOld.csv)
- [https://calaccess.download/latest/Form460ScheduleHItem.csv](https://calaccess.download/latest/Form460ScheduleHItem.csv)
- [https://calaccess.download/latest/Form460ScheduleHItemVersion.csv](https://calaccess.download/latest/Form460ScheduleHItemVersion.csv)
- [https://calaccess.download/latest/Form460ScheduleIItem.csv](https://calaccess.download/latest/Form460ScheduleIItem.csv)
- [https://calaccess.download/latest/Form460ScheduleIItemVersion.csv](https://calaccess.download/latest/Form460ScheduleIItemVersion.csv)
- [https://calaccess.download/latest/Form461Filing.csv](https://calaccess.download/latest/Form461Filing.csv)
- [https://calaccess.download/latest/Form461FilingVersion.csv](https://calaccess.download/latest/Form461FilingVersion.csv)
- [https://calaccess.download/latest/Form461Part5Item.csv](https://calaccess.download/latest/Form461Part5Item.csv)
- [https://calaccess.download/latest/Form461Part5ItemVersion.csv](https://calaccess.download/latest/Form461Part5ItemVersion.csv)
- [https://calaccess.download/latest/Form496Filing.csv](https://calaccess.download/latest/Form496Filing.csv)
- [https://calaccess.download/latest/Form496FilingVersion.csv](https://calaccess.download/latest/Form496FilingVersion.csv)
- [https://calaccess.download/latest/Form496Part1Item.csv](https://calaccess.download/latest/Form496Part1Item.csv)
- [https://calaccess.download/latest/Form496Part1ItemVersion.csv](https://calaccess.download/latest/Form496Part1ItemVersion.csv)
- [https://calaccess.download/latest/Form496Part2Item.csv](https://calaccess.download/latest/Form496Part2Item.csv)
- [https://calaccess.download/latest/Form496Part2ItemVersion.csv](https://calaccess.download/latest/Form496Part2ItemVersion.csv)
- [https://calaccess.download/latest/Form496Part3Item.csv](https://calaccess.download/latest/Form496Part3Item.csv)
- [https://calaccess.download/latest/Form496Part3ItemVersion.csv](https://calaccess.download/latest/Form496Part3ItemVersion.csv)
- [https://calaccess.download/latest/Form497Filing.csv](https://calaccess.download/latest/Form497Filing.csv)
- [https://calaccess.download/latest/Form497FilingVersion.csv](https://calaccess.download/latest/Form497FilingVersion.csv)
- [https://calaccess.download/latest/Form497Part1Item.csv](https://calaccess.download/latest/Form497Part1Item.csv)
- [https://calaccess.download/latest/Form497Part1ItemVersion.csv](https://calaccess.download/latest/Form497Part1ItemVersion.csv)
- [https://calaccess.download/latest/Form497Part2Item.csv](https://calaccess.download/latest/Form497Part2Item.csv)
- [https://calaccess.download/latest/Form497Part2ItemVersion.csv](https://calaccess.download/latest/Form497Part2ItemVersion.csv)
- [https://calaccess.download/latest/Form501Filing.csv](https://calaccess.download/latest/Form501Filing.csv)
- [https://calaccess.download/latest/Form501FilingVersion.csv](https://calaccess.download/latest/Form501FilingVersion.csv)
