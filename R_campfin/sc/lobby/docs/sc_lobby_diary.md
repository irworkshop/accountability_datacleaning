South Carolina
================
Kiernan Nicholls
2019-12-09 14:15:01

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)

<!-- Place comments regarding knitting here -->

## Project

The Accountability Project is an effort to cut across data silos and
give journalists, policy professionals, activists, and the public at
large a simple way to search across huge volumes of public data about
people and organizations.

Our goal is to standardizing public data on a few key fields by thinking
of each dataset row as a transaction. For each transaction there should
be (at least) 3 variables:

1.  All **parties** to a transaction
2.  The **date** of the transaction
3.  The **amount** of money involved

## Objectives

This document describes the process used to complete the following
objectives:

1.  How many records are in the database?
2.  Check for duplicates
3.  Check ranges
4.  Is there anything blank or missing?
5.  Check for consistency issues
6.  Create a five-digit ZIP Code called `ZIP5`
7.  Create a `YEAR` field from the transaction date
8.  Make sure there is data on both parties to a transaction

## Packages

The following packages are needed to collect, manipulate, visualize,
analyze, and communicate these results. The `pacman` package will
facilitate their installation and attachment.

The IRW’s `campfin` package will also have to be installed from GitHub.
This package contains functions custom made to help facilitate the
processing of campaign finance data.

``` r
if (!require("pacman")) install.packages("pacman")
pacman::p_load_gh("irworkshop/campfin")
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  magrittr, # pipe opperators
  janitor, # dataframe clean
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  glue, # combine strings
  here, # relative storage
  fs # search storage 
)
```

This document should be run as part of the `R_campfin` project, which
lives as a sub-directory of the more general, language-agnostic
[`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning "TAP repo")
GitHub repository.

The `R_campfin` project uses the [RStudio
projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects "Rproj")
feature and should be run as such. The project also uses the dynamic
`here::here()` tool for file paths relative to *your* machine.

``` r
# where does this document knit?
here::here()
```

## Data

Lobbyist data is obtained from the [South Carolina State Ethics
Commission](https://apps.sc.gov/PublicReporting/Index.aspx).

> #### Welcome
> 
> Registrations for both lobbyists and their respective lobbyist’s
> principals are available online for viewing. Disclosure for both
> lobbyists and their respective lobbyist’s principals will also be
> available at the conclusion of the first disclosure period, June 30,
> 2009, for the period, January 1, 2009 through May 31, 2009.

The [lobbying activity
page](https://apps.sc.gov/LobbyingActivity/LAIndex.aspx), we can see the
files that can be retrieved:

> #### Lobbying Activity
> 
> Welcome to the State Ethics Commission Online Public Disclosure and
> Accountability Reporting System for Lobbying Activity. Registrations
> for both lobbyists and their respective lobbyist’s principals are
> available online for viewing.
> 
> Disclosure for both lobbyists and their respective lobbyist’s
> principals are available for the period June 30, 2009 through the
> present.
> 
> These filings can be accessed by searching individual reports by
> lobbyist and lobbyist’s principal names and by complete list of
> current lobbyist and lobbyist’s principal registrations.

> #### List Reports
> 
> View a list of lobbyists, lobbyists’ principals or their contact
> information.
> 
>   - [Lobbyists and Their
>     Principals](https://apps.sc.gov/LobbyingActivity/SelectLobbyistGroup.aspx)
>   - [Download Lobbyist Contacts (CSV
>     file)](https://apps.sc.gov/LobbyingActivity/DisplayCsv.aspx)
>   - [Individual Lobbyist
>     Lookup](https://apps.sc.gov/LobbyingActivity/SearchLobbyistContact.aspx)
>   - [Lobbyists’ Principals and Their
>     Lobbyists](https://apps.sc.gov/LobbyingActivity/SelectLobbyistPrincipalGroup.aspx)
>   - [Download Lobbyist’s Principal Contacts (CSV
>     file)](https://apps.sc.gov/LobbyingActivity/DisplayCsv.aspx)
>   - [Individual Lobbyist’s Principal
>     Lookup](https://apps.sc.gov/LobbyingActivity/SearchLPContact.aspx)
>   - [Year End Compilation
>     Report](https://apps.sc.gov/LobbyingActivity/CompilationReport.aspx)
