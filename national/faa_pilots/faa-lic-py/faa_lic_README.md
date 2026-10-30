FAA Pilot Registration - Python 
================
Janelle O'Dea
Friday February 17 2023

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

The database of Federal Aviation Administration (FAA) aircraft
registrations can be obtained from [the FAA
website](https://www.faa.gov/licenses_certificates/aircraft_certification/aircraft_registry/releasable_aircraft_download).

From the FAA website:

>The data in the download is refreshed daily at 11:30 pm central time. 
>The download is delivered in a Comma-Separated Value (.csv extension) format or often referred to as Comma-Delimited. This format was selected due to multitude and availability of tools that can open, read, and manipulate the data. 
>The file is comprised of "Required" and "Permissible" data.Required data is information necessary to meet the minimum Regulatory requirements, while Permissible data is supplement and delivered during the course of users submittinginformation associated with the forms and documents to fulfill Aircraft registration service requests. Permissible data is therefore, not required, and only recorded when is provided.This is supplemental data was deemed valuable in supporting additional mission benefits, such as research activities. As a result of recording the supplemental data in the database,the fields associated with permissible data, may be blank and should not be considered in error.

### Download

We will be downloading the data in CSV format and
can use the [provided
documentation](https://www.faa.gov/sites/faa.gov/files/licenses_certificates/aircraft_certification/aircraft_registry/releasable_aircraft_download/ardata.pdf)
to learn more about the data and how to read it.

### Overview

From the FAA website:

> The FAA is extending the duration of aircraft registration certificates from three to seven years, effective January 23, 2023.

> The FAA Registry is now offering limited online aircraft registration services [here](https://www.faa.gov/licenses_certificates/aircraft_certification/aircraft_registry/media/CARES\%20User\%20Guide\%202023.pdf). Individual aircraft owners can complete self-guided aircraft registration applications, upload legal and supplemental documents, receive auto-generated notification, request aircraft registration N- Numbers, use modernized online payment options, receive instant notification of payment, and digitally sign Aircraft Registration Applications. Services will be continuously improved.

>The Federal Aviation Administration accepts documents containing digital signatures by email. The documents may be submitted electronically as an attachment to an email at 9-avs-ar-electronic-submittals@faa.gov. Documents signed in ink must be submitted by U.S. Post Office or commercial delivery services. The link to Contact the [Aircraft Registation Branch](mailto:209-AMC-AFS750-Aircraft@faa.gov) provides our contact information including our mailing and physical addresses. Any questions can be by email Aircraft Registration Branch, or you can call 1-866-762-9434, or 405-954-3116.

>We are processing documents received on approximately September 29, 2022.

The Registry will no longer issue letters of extension, effective January 23, 2023. The FAA revised [14 CFR 47.31(c)(1)](https://www.ecfr.gov/current/title-14/chapter-I/subchapter-C/part-47/subpart-B/section-47.31) removing the time limit within which the FAA must either issue a letter extending the temporary authority to continue to operate or deny the application. The Aircraft Registration Application (“Pink Copy”) is valid until the applicant receives the aircraft registration certificate, application is denied by the FAA, or 12 months have elapsed during which the registration is pending on the aircraft.

## Conclude

1.  

## Export

The last line in the script exports an aircraft_2023.csv file. If you're uploading data in a different year, please change the 'yyyy' after the underscore to the current year.

## Upload

Upload the pilots_yyyy.csv file via FTP.

