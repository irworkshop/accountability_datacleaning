FAA Pilot Registration - Python 
================
Janelle O'Dea
Friday January 31 2023

-   [Project](#project)
-   [Objectives](#objectives)
-   [Packages-setup](#packages-setup)
-   [Data](#data)
    -   [Overview](#overview)
-   [Download](#download)
-   [Conclude](#conclude)
-   [Export](#export)
-   [Upload](#upload)

## Project

The Accountability Project is an effort to cut across data silos and
give journalists, policy professionals, activists, and the public at
large a simple way to search volumes of public data about
people and organizations.

We seek to standardize public data on a few key fields by thinking
of each dataset row as a transaction. For each transaction there should
be (at least) 3 variables:

1.  All **parties** to a transaction.
2.  The **date** of the transaction.
3.  The **amount** of money involved.

## Objectives

This document describes the process used to complete the following
objectives:

1.  How many records are in the database?
2.  Check for entirely duplicated records.
3.  Check ranges of continuous variables.
4.  Is there anything blank or missing?
5.  Check for consistency issues.
6.  Create a five-digit US ZIP Code field called `uszip5` out of the nine-digit US ZIP codes provided.
7.  Create a `nonuszip` field.
8.  Create a `year`, a `month` and a `day` field (when applicable) from the transaction date(s).
9.  Make sure there is data on both parties to a transaction.

## Packages-setup

To replicate this project:

* You have Python 3 installed
* You have [virtualenv](https://pypi.python.org/pypi/virtualenv) and [virtualenvwrapper](https://pypi.python.org/pypi/virtualenvwrapper) installed and working.
* Create a virtual environment `mkvirtualenv (virtualenvname)` and activate it by changing directories to the Scripts folder and running the `activate` command.
* Install packages `pip install -r requirements.txt`
* From here, you can either launch Jupyter Notebook with the `jupyter notebook` command, or run the `pilots.py` script from the command line/terminal.


## Data

The database of Federal Aviation Administration (FAA) pilot
registrations can be obtained from [the FAA
website](https://www.faa.gov/licenses_certificates/airmen_certification/releasable_airmen_download/).

From the FAA website:

> ### Airmen Certification Database
>
> -   Airmen Certification Branch is not the authoritative source for
>     medical data.
> -   The expiration date provided in the downloadable file is for
>     informational purposes only.
> -   Any questions regarding medical information should be directed to
>     Aerospace Medical Certification Division.
>
> We update these files monthly. The records in each database file are
> stored in either fixed length ASCII text format (TXT) or
> comma-delimited text format (CSV) which is already separated into
> airmen basic records and certificate records. Both formats can be
> accessed using common database applications such as MS Access.
>
> This information does not include airmen certificate number data, nor
> does it include the records of those airmen who do not want their
> addresses released. You can also elect to Change the Releasability
> Status of your Address if you do not want it listed in the database.


### Download

We will be downloading the data in fixed length ASCII text format and
can use the [provided
documentation](https://www.faa.gov/licenses_certificates/airmen_certification/media/Help.pdf)
to learn more about the data and how to read it.

### Overview

> On April 5, 2000, the Wendell H. Ford Aviation Investment and Reform
> Act for the 21st Century became Public Law 106-181. Section 715 of
> that law requires the Federal Aviation Administration to release
> names, addresses, and ratings information for all airmen after the
> 120th day following the date of enactment.
>
> The law also requires that the airmen be given an opportunity to elect
> that their address information be withheld from release under this
> law. Accordingly, the FAA sent letters to all active airmen informing
> them of the provisions of the law, and giving them the option to
> withhold their address information. The FAA will be continuing this
> procedure for airmen who become active. Responses from the letters
> have been processed
>
> This file contains the names, addresses, and certificate information
> of those airmen who did not respond to indicate that they wished to
> withhold their address information. It is the intent of the Airmen
> Certification Branch to produce this file, in its entirety, on a
> monthly basis. The file may be downloaded from the Civil Aviation
> Registry web site at <http://registry.faa.gov>.

## Conclude

1.  There are 954,997 records in the database as of the January 2023 upload.
2.  There are duplicate records.
3.  Date ranges are reasonable, but the formatting is unconventional on two fields (the format is MYYYY or MMYYYY, depending on if one- or two-digit month). 
4.  There are many records missing medical exam information (the last four fields in the original data). The FAA website states explicitly that this database is not the authoritative source for medical information.
5.  Consistency in geographic data doesn't really apply here. The only note is: There are non-US ZIP codes in the original zip field. A 5-digit US ZIP field — uszip5 — has been created out of the 9 digit ZIP codes provided in the original ZIP field. Note: In the uszip5 field, leading zeros will not show in Excel. They're there.
6.  The 'year' field reflects the year the data was uploaded.
7.  The FAA updates this data on the first of every month or the first business day after. The Accountability Project will not update it monthly, however.

## Export

The last line in the script exports a pilot_2023.csv file. If you're uploading data in a different year, please change the 'yyyy' after the underscore to the current year.

## Upload

Upload the pilots_yyyy.csv file via FTP.

