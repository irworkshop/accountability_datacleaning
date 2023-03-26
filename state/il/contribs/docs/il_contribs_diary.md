Illinois Contributions
================
Kiernan Nicholls & Aarushi Sahejpal
Sun Mar 26 14:54:58 2023

- <a href="#project" id="toc-project">Project</a>
- <a href="#objectives" id="toc-objectives">Objectives</a>
- <a href="#packages" id="toc-packages">Packages</a>
- <a href="#data" id="toc-data">Data</a>
- <a href="#download" id="toc-download">Download</a>
  - <a href="#dictionary" id="toc-dictionary">Dictionary</a>
  - <a href="#receipts" id="toc-receipts">Receipts</a>
- <a href="#fix" id="toc-fix">Fix</a>
- <a href="#read" id="toc-read">Read</a>
- <a href="#committees" id="toc-committees">Committees</a>
- <a href="#explore" id="toc-explore">Explore</a>
  - <a href="#missing" id="toc-missing">Missing</a>
  - <a href="#duplicates" id="toc-duplicates">Duplicates</a>
  - <a href="#categorical" id="toc-categorical">Categorical</a>
  - <a href="#amounts" id="toc-amounts">Amounts</a>
  - <a href="#dates" id="toc-dates">Dates</a>
- <a href="#wrangle-1" id="toc-wrangle-1">Wrangle</a>
  - <a href="#address" id="toc-address">Address</a>
  - <a href="#zip" id="toc-zip">ZIP</a>
  - <a href="#state" id="toc-state">State</a>
  - <a href="#city" id="toc-city">City</a>
- <a href="#conclude" id="toc-conclude">Conclude</a>
- <a href="#export" id="toc-export">Export</a>
- <a href="#upload" id="toc-upload">Upload</a>

<!-- Place comments regarding knitting here -->

## Project

The Accountability Project is an effort to cut across data silos and
give journalists, policy professionals, activists, and the public at
large a simple way to search across huge volumes of public data about
people and organizations.

Our goal is to standardize public data on a few key fields by thinking
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
6.  Create a five-digit ZIP Code called `zip`.
7.  Create a `year` field from the transaction date.
8.  Make sure there is data on both parties to a transaction.

## Packages

The following packages are needed to collect, manipulate, visualize,
analyze, and communicate these results. The `pacman` package will
facilitate their installation and attachment.

``` r
if (!require("pacman")) {
  install.packages("pacman")
}
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  gluedown, # printing markdown
  janitor, # clean data frames
  campfin, # custom irw tools
  aws.s3, # aws cloud storage
  refinr, # cluster & merge
  scales, # format strings
  knitr, # knit documents
  vroom, # fast reading
  rvest, # scrape html
  glue, # code strings
  here, # project paths
  httr, # http requests
  fs # local storage 
)
```

This document should be run as part of the `R_campfin` project, which
lives as a sub-directory of the more general, language-agnostic
[`irworkshop/accountability_datacleaning`](https://github.com/irworkshop/accountability_datacleaning)
GitHub repository.

The `R_campfin` project uses the [RStudio
projects](https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects)
feature and should be run as such. The project also uses the dynamic
`here::here()` tool for file paths relative to *your* machine.

``` r
# where does this document knit?
here::i_am("il/contribs/docs/il_contribs_diary.Rmd")
```

## Data

Contribution data is available from the [Illinois State Board of
Elections](https://elections.il.gov/Default.aspx). The ILSBOE operates a
[contributions search
portal](https://elections.il.gov/CampaignDisclosure/ContributionSearchByAllContributions.aspx)
where users can find and export data on certain contributions. Data is
also available in \[bulk\] from the ILSBOE.

> ### Frequently Asked Questions
>
> #### What about campaign disclosure?\*\*
>
> The Campaign Financing Act covers the public’s right to know certain
> financial information about candidates, elected officials and those
> individuals and groups who are financially involved in political
> campaigns. The State Board of Elections supervises the administration
> of the Illinois act and closely monitors campaign expenditures which
> appear on reports submitted by candidates and committees as required
> by law. These reports, detailing contributions and expenditures, give
> the media and the public information on where candidates received
> their campaign money and where it is being spent. Board hearings are
> held if suspected or actual violations of the Campaign Financing Act
> occur. The Board is authorized to levy fines and turn over evidence of
> wrongdoing to local prosecutors.
>
> #### Is electronically filed data available on the Board of Elections website?
>
> Yes, the data is available in a searchable format. It may be accessed
> in a number of ways by selecting from the different search options
> available. Search tips are provided for each type of search. In
> addition, all itemized receipts for statewide candidates, legislative
> candidates, and legislative leadership committees for the period from
> July 1, 1994 through December 31, 1998, may be searched.
>
> #### Is electronically filed data downloadable from the Board website?
>
> Contribution and expenditure data may be downloaded in either a
> Tab-Delimited Text File or XML file. The data is also available at no
> cost from the Board on cdrom.
>
> #### When is a political committee required to file electronically?
>
> Electronic filing is required for all political committees that during
> a reporting period (i) had at any time a balance or an accumulation of
> contributions of \$10,000 or more, (ii) made aggregate expenditures of
> \$10,000 or more, or (iii) received loans of an aggregate of \$10,000
> or more. Once a committee exceeds the threshold that requires it to
> report electronically, it must continue thereafter to report
> electronically until it dissolves, whether or not its accumulation,
> receipts or expenditures fall beneath the levels set by statute for
> mandatory electronic filing.
>
> #### Who must file campaign disclosure reports?
>
> Any individual, trust, partnership, committee, association,
> corporation, or any other organization or group of persons which
> receives or spends more than \$5,000 on behalf of or in opposition to
> a candidate or question of public policy, meets the definition of a
> political committee and must comply with all provisions of the
> Illinois Campaign Financing Act, including the filing of campaign
> disclosure reports. The \$5,000 threshold does not apply to political
> party committees. In addition, any entity other than a natural person
> that makes expenditures of any kind in an aggregate amount of more
> than \$3,000 during any 12-month period supporting or opposing a
> public official or candidate must organize as a political committee.

## Download

The campaign finance database is hosted at
`/campaigndisclosuredatafiles`. There, we can see the 13 files available
for download.

``` r
il_home <- read_html("https://elections.il.gov/campaigndisclosuredatafiles/")
```

This table of files includes the date, size, name and URL.

| date                |  length | name                                                                                                                                |
|:--------------------|--------:|:------------------------------------------------------------------------------------------------------------------------------------|
| 2020-01-17 15:25:00 |   11.7K | [`CampaignDisclosureDataDictionary.txt`](https://elections.il.gov/campaigndisclosuredatafiles/CampaignDisclosureDataDictionary.txt) |
| 2023-03-26 08:10:00 |   3.18M | [`Candidates.txt`](https://elections.il.gov/campaigndisclosuredatafiles/Candidates.txt)                                             |
| 2023-03-26 08:10:00 |   2.53M | [`CanElections.txt`](https://elections.il.gov/campaigndisclosuredatafiles/CanElections.txt)                                         |
| 2023-03-26 08:10:00 | 609.88K | [`CmteCandidateLinks.txt`](https://elections.il.gov/campaigndisclosuredatafiles/CmteCandidateLinks.txt)                             |
| 2023-03-26 08:10:00 |   1.05M | [`CmteOfficerLinks.txt`](https://elections.il.gov/campaigndisclosuredatafiles/CmteOfficerLinks.txt)                                 |
| 2023-03-26 08:12:00 |   8.09M | [`Committees.txt`](https://elections.il.gov/campaigndisclosuredatafiles/Committees.txt)                                             |
| 2023-03-26 08:10:00 |  48.67M | [`D2Totals.txt`](https://elections.il.gov/campaigndisclosuredatafiles/D2Totals.txt)                                                 |
| 2023-03-26 08:11:00 | 654.13M | [`Expenditures.txt`](https://elections.il.gov/campaigndisclosuredatafiles/Expenditures.txt)                                         |
| 2023-03-26 08:12:00 | 114.88M | [`FiledDocs.txt`](https://elections.il.gov/campaigndisclosuredatafiles/FiledDocs.txt)                                               |
| 2023-03-26 08:12:00 |   2.86M | [`Investments.txt`](https://elections.il.gov/campaigndisclosuredatafiles/Investments.txt)                                           |
| 2023-03-26 08:12:00 |   6.37M | [`Officers.txt`](https://elections.il.gov/campaigndisclosuredatafiles/Officers.txt)                                                 |
| 2023-03-26 08:12:00 |   2.28M | [`PrevOfficers.txt`](https://elections.il.gov/campaigndisclosuredatafiles/PrevOfficers.txt)                                         |
| 2023-03-26 08:12:00 | 895.09M | [`Receipts.txt`](https://elections.il.gov/campaigndisclosuredatafiles/Receipts.txt)                                                 |

### Dictionary

The
[`CampaignDisclosureDataDictionary.txt`](https://elections.il.gov/campaigndisclosuredatafiles/CampaignDisclosureDataDictionary.txt)
file contains the columns within each of the available files. We are
interested in the `Receipts.txt` file that contains all campaign
contributions.

| column               | description                                                          |
|:---------------------|:---------------------------------------------------------------------|
| `ID`                 | ID number generated for each record                                  |
| `CommitteeID`        | Political Committee ID number assigned by SBE                        |
| `FiledDocID`         | ID number for the filed document containing the receipt              |
| `ETransID`           | ID number generated for electronically filed document                |
| `LastOnlyName`       | Last/Business name for donor                                         |
| `FirstName`          | First name for donor                                                 |
| `RcvDate`            | Date receipt received                                                |
| `Amount`             | Amount of the receipt                                                |
| `AggregateAmount`    | Aggregate receipt total for filing period                            |
| `LoanAmount`         | Amount of loan                                                       |
| `Occupation`         | Occupation of donor                                                  |
| `Employer`           | Employer of donor                                                    |
| `Address1`           | Donor’s address                                                      |
| `Addresss2`          | Donor’s address                                                      |
| `City`               | Donor’s city                                                         |
| `State`              | Donor’s state                                                        |
| `Zip`                | Donor’s zip code                                                     |
| `D2Part`             | Indicates section of the D-2 form for the receipt                    |
| `Description`        | Description of the receipt                                           |
| `VendorLastOnlyName` | Last name of vendor, for in-kind contribution                        |
| `VendorFirstName`    | First name of vendor, for in-kind contribution                       |
| `VendorAddress1`     | Vendor’s address, for in-kind contribution                           |
| `VendorAddress2`     | Vendor’s address, for in-kind contribution                           |
| `VendorCity`         | Vendor’s city, for in-kind contribution                              |
| `VendorState`        | Vendor’s state, for in-kind contribution                             |
| `VendorZip`          | Vendor’s zip code, for in-kind contribution                          |
| `Archived`           | Indicates the receipt has been superseded by an amendment            |
| `Country`            | Country of the receipt entity (if any)                               |
| `RedactionRequested` | Donor has requested address redaction under the Judicial Privacy Act |

### Receipts

``` r
raw_dir <- dir_create(here("il", "contribs", "data", "raw"))
raw_txt <- path(raw_dir, str_subset(il_ls$name, "Receipts"))
```

``` r
if (!file_exists(raw_txt)) {
  download.file(
    url = str_subset(raw_url, "Receipts"),
    destfile = raw_txt,
    method = "curl"
  )
}
```

## Fix

There are 3 problems within the `Receipts.txt` text file: 1. There are
two instances of a line being erroneously split in the middle and spread
across 7 lines with information repeated in the middle 5 lines. 2. There
are two instances of a name ending with `\n` causing that line to be
split across two lines. 3. There is one address with two extra `\t`
delimiters between the street number and street type.

Presuming the `Receipts.txt` file is the same one (or at least in the
same order) as the one downloaded today (September 16, 2021), then we
can fix these issues manually, removing the bad lines, and saving the
fixed lines to a new text file.

``` r
fix_txt <- here("il", "contribs", "data", "Receipts-fix.txt")
fixes <- rep(FALSE, 4)
if (!file_exists(fix_txt)) {
  x <- read_lines(raw_txt)
  Sys.sleep(5)
  
  # middle newline, repeated column in split middle
  if (str_starts(x[4170845], "\\d", negate = TRUE)) {
    x[4170839] <- paste(x[4170839], x[4170845], sep = "\t")
    fixes[1] <- TRUE
  }
  
  if (str_starts(x[4193501], "\\d", negate = TRUE)) {
    x[4193495] <- paste(x[4193495], x[4193501], sep = "\t")
    fixes[2] <- TRUE
  }

  # newline in name
  if (all(str_starts(x[c(4351744, 4377250)], "\\d", negate = TRUE))) {
    x[4351743] <- paste0(x[4351743], x[4351744])
    x[4377249] <- paste0(x[4377249], x[4377250])
    fixes[3] <- TRUE
  }

  # two tabs within address
  if (str_count(x[5452831], "\t") > 28) {
    x[5452831] <- str_replace(
      string = x[5452831],
      pattern = "672\tS Lincoln\tAve",
      replacement = "672 S Lincoln Ave"
    )
    fixes[4] <- TRUE
  }
  
  
  # remove bad lines
  if (all(fixes)) {
    bad_rows <- c(
      4170840:4170845, # fix one
      4193496:4193501, # fix two
      4351744,         # fix three
      4377250          # fix four
    )
    x <- x[-bad_rows]
  }
  write_lines(x, fix_txt)
}
```

## Read

We can read the manually fixed tab-delimited file.

``` r
ilc <- read_delim(
  file = fix_txt,
  delim = "\t",
  quote = "",
  escape_backslash = FALSE,
  escape_double = FALSE,
  trim_ws = TRUE,
  col_types = cols(
    .default = col_character(),
    ID = col_integer(),
    CommitteeID = col_integer(),
    FiledDocID = col_integer(),
    RcvDate = col_datetime(),
    Amount = col_double(),
    AggregateAmount = col_double(),
    LoanAmount = col_double(),
    Archived = col_logical(),
    RedactionRequested = col_logical()
  )
)
```

``` r
problems(ilc)
#> # A tibble: 10 × 5
#>        row   col expected   actual     file                                                                            
#>      <int> <int> <chr>      <chr>      <chr>                                                                           
#>  1 5608089    30 29 columns 30 columns /Volumes/TAP/accountability_datacleaning/state/il/contribs/data/Receipts-fix.txt
#>  2 5629734    30 29 columns 30 columns /Volumes/TAP/accountability_datacleaning/state/il/contribs/data/Receipts-fix.txt
#>  3 5745750    15 29 columns 15 columns /Volumes/TAP/accountability_datacleaning/state/il/contribs/data/Receipts-fix.txt
#>  4 5745751     1 an integer Chicago    /Volumes/TAP/accountability_datacleaning/state/il/contribs/data/Receipts-fix.txt
#>  5 5745751     2 an integer IL         /Volumes/TAP/accountability_datacleaning/state/il/contribs/data/Receipts-fix.txt
#>  6 5745751    15 29 columns 15 columns /Volumes/TAP/accountability_datacleaning/state/il/contribs/data/Receipts-fix.txt
#>  7 5804800    15 29 columns 15 columns /Volumes/TAP/accountability_datacleaning/state/il/contribs/data/Receipts-fix.txt
#>  8 5804801     1 an integer Chicago    /Volumes/TAP/accountability_datacleaning/state/il/contribs/data/Receipts-fix.txt
#>  9 5804801     2 an integer IL         /Volumes/TAP/accountability_datacleaning/state/il/contribs/data/Receipts-fix.txt
#> 10 5804801    15 29 columns 15 columns /Volumes/TAP/accountability_datacleaning/state/il/contribs/data/Receipts-fix.txt
```

To ensure the file was properly read, we should count the distinct
values of a discrete variable like the logical `RedactionRequested`
column, which should only contain `TRUE` and `FALSE` values.

``` r
count(ilc, RedactionRequested)
#> # A tibble: 3 × 2
#>   RedactionRequested       n
#>   <lgl>                <int>
#> 1 FALSE              5809846
#> 2 TRUE                 12672
#> 3 NA                       4
```

``` r
ilc <- clean_names(ilc, case = "snake")
```

## Committees

The contribution records contain the name and address of the contributor
but only identify the receiving committee with an `committee_id`
variable. We can use that `committee_id` to join against the
`Committees.txt` database.

``` r
cmt_txt <- path(raw_dir, str_subset(il_ls$name, "Committees"))
if (!file_exists(cmt_txt)) {
  download.file(
    url = str_subset(raw_url, "Committees"),
    destfile = cmt_txt
  )
}
```

``` r
committees <- read_delim(
  file = cmt_txt,
  delim = "\t",
  quote = "",
  escape_backslash = FALSE,
  escape_double = FALSE,
  trim_ws = TRUE,
  col_types = cols(
    .default = col_character(),
    ID = col_integer(),
    StateCommittee = col_logical(),
    StateID = col_integer(),
    LocalCommittee = col_logical(),
    LocalID = col_integer(),
    StatusDate = col_datetime(),
    CreationDate = col_datetime(),
    CreationAmount = col_double(),
    DispFundsReturn = col_logical(),
    DispFundsPolComm = col_logical(),
    DispFundsCharity = col_logical(),
    DispFunds95 = col_logical()
  )
)
```

``` r
committees <- clean_names(committees, case = "snake")
```

We are only interested in the columns which identify the receiving
committee by name and address so they can be easily searched.

``` r
committees <- committees %>% 
  select(id, name, starts_with("address"), city, state, zip)
```

#### Wrangle

Before we join the tables, we are going to normalize the geographic
variables of the address. The explanation for this process is detailed
in the `Wrangle` section below.

``` r
committees <- committees %>% 
  unite(
    col = address,
    starts_with("address"),
    sep = " ",
    remove = TRUE,
    na.rm = TRUE
  ) %>% 
  mutate(
    address = normal_address(
      address = address,
      abbs = usps_street,
      na_rep = TRUE
    )
  )
```

``` r
committees$zip <- normal_zip(
  zip = committees$zip,
  na_rep = TRUE,
  na = ""
)
```

``` r
il_zip <- zipcodes$zip[zipcodes$state == "IL"]
committees$state[committees$state == "L" & committees$zip %in% il_zip] <- "IL"
committees$state[committees$state == "O:" & committees$zip %in% il_zip] <- "IL"
committees$state <- normal_state(
  state = committees$state,
  valid = valid_state
)
```

``` r
committees <- committees %>% 
  mutate(
    city = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("IL", "DC", "ILLINOIS"),
      na = invalid_city,
      na_rep = TRUE
    )
  ) %>% 
  left_join(
    y = zipcodes,
    by = c("state", "zip"),
    suffix = c("_norm", "_match")
  ) %>% 
  mutate(
    match_abb = is_abbrev(city_norm, city_match),
    match_dist = str_dist(city_norm, city_match),
    city_swap = if_else(
      condition = !is.na(match_dist) & (match_abb | match_dist == 1),
      true = city_match,
      false = city_norm
    ),
    .after = city_norm
  ) %>% 
  select(
    -match_abb,
    -match_dist,
    -city_norm,
    -city_match
  ) %>% 
  rename(city = city_swap)
```

#### Join

These columns can be joined with every contribution. We will identify
columns from the `Committees.txt` column with the `cmte_` prefix.

``` r
committees <- rename_with(
  .data = committees,
  .fn = ~paste0("cmte_", .),
  .cols = -id
)
```

``` r
ilc <- left_join(
  x = ilc,
  y = committees,
  by = c("committee_id" = "id")
)
```

## Explore

There are 5,822,522 rows of 34 columns. Each record represents a single
contribution from an individual or business to a campaign or committee.

``` r
glimpse(ilc)
#> Rows: 5,822,522
#> Columns: 34
#> $ id                    <int> 236628, 236629, 236630, 236631, 236632, 236633, 236634, 236635, 236636, 236637, 236638, …
#> $ committee_id          <int> 10353, 10353, 10353, 10353, 10353, 10353, 10353, 10353, 10353, 10353, 10353, 10353, 1035…
#> $ filed_doc_id          <int> 82298, 82298, 82298, 82298, 82298, 82298, 82298, 82298, 82298, 82298, 82298, 82298, 8229…
#> $ e_trans_id            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ last_only_name        <chr> "Abc Pac", "Bacon", "Baum", "Burns", "Cable Television & Commission Pac", "Carus", "Cate…
#> $ first_name            <chr> NA, "Donald", "H James", "John & Sandy", NA, "Cynthia", NA, "Roger", NA, NA, NA, "Robert…
#> $ rcv_date              <dttm> 1998-10-28, 1998-09-03, 1998-09-10, 1998-09-14, 1998-09-21, 1998-09-02, 1998-10-27, 199…
#> $ amount                <dbl> 500.00, 250.00, 150.00, 176.00, 1000.00, 200.00, 1000.00, 200.00, 1000.00, 2000.00, 850.…
#> $ aggregate_amount      <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0…
#> $ loan_amount           <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0…
#> $ occupation            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ employer              <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ address1              <chr> "Rt 1 Box 255", "16 Bruarckuff", "221 Liberty St", "610 Houston", "2400 E Devon Ave Ste …
#> $ address2              <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ city                  <chr> "Decatur", "Bourbonnais", "Morris", "Ottawa", "Des Plaines", "Peru", "Peoria", "Peru", "…
#> $ state                 <chr> "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL"…
#> $ zip                   <chr> "62526", "60914", "60450", "61350", "60018", "61354", "61629", "61354", "60601", "60601"…
#> $ d2part                <chr> "2A", "1A", "1A", "5A", "2A", "1A", "2A", "1A", "2A", "2A", "5A", "1A", "2A", "2A", "1A"…
#> $ description           <chr> NA, NA, NA, "Food For Fundraiser", NA, NA, NA, NA, NA, NA, "Copier For Office", NA, NA, …
#> $ vendor_last_only_name <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ vendor_first_name     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ vendor_address1       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ vendor_address2       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ vendor_city           <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ vendor_state          <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ vendor_zip            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ archived              <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ country               <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ redaction_requested   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ cmte_name             <chr> "Citizens For Studzinski", "Citizens For Studzinski", "Citizens For Studzinski", "Citize…
#> $ cmte_address          <chr> "C/O JO HERRINGTON 2412 PLUM", "C/O JO HERRINGTON 2412 PLUM", "C/O JO HERRINGTON 2412 PL…
#> $ cmte_city             <chr> "PERU", "PERU", "PERU", "PERU", "PERU", "PERU", "PERU", "PERU", "PERU", "PERU", "PERU", …
#> $ cmte_state            <chr> "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL"…
#> $ cmte_zip              <chr> "61354", "61354", "61354", "61354", "61354", "61354", "61354", "61354", "61354", "61354"…
tail(ilc)
#> # A tibble: 6 × 34
#>        id committee_id filed_doc_id e_trans_id last_only_name     first_name rcv_date            amount aggregate_amount
#>     <int>        <int>        <int> <chr>      <chr>              <chr>      <dttm>               <dbl>            <dbl>
#> 1 5942260        38806       879499 <NA>       SEIU HealthCare I… <NA>       2023-03-25 00:00:00  30000                0
#> 2 5942261        38799       879500 <NA>       citizen for sophi… <NA>       2023-03-25 00:00:00  10000                0
#> 3 5942262        38799       879500 <NA>       Bridges            Vasco      2023-03-25 00:00:00   1000                0
#> 4 5942263        38799       879501 <NA>       stevens            reginald   2023-03-23 00:00:00   1500                0
#> 5 5942264        38799       879501 <NA>       peterson           james      2023-03-23 00:00:00   1500                0
#> 6 5942265        38806       879502 <NA>       Cook County Colle… <NA>       2023-03-25 00:00:00   2000                0
#> # ℹ 25 more variables: loan_amount <dbl>, occupation <chr>, employer <chr>, address1 <chr>, address2 <chr>, city <chr>,
#> #   state <chr>, zip <chr>, d2part <chr>, description <chr>, vendor_last_only_name <chr>, vendor_first_name <chr>,
#> #   vendor_address1 <chr>, vendor_address2 <chr>, vendor_city <chr>, vendor_state <chr>, vendor_zip <chr>,
#> #   archived <lgl>, country <chr>, redaction_requested <lgl>, cmte_name <chr>, cmte_address <chr>, cmte_city <chr>,
#> #   cmte_state <chr>, cmte_zip <chr>
```

### Missing

Columns vary in their degree of missing values.

``` r
col_stats(ilc, count_na)
#> # A tibble: 34 × 4
#>    col                   class        n           p
#>    <chr>                 <chr>    <int>       <dbl>
#>  1 id                    <int>        2 0.000000343
#>  2 committee_id          <int>        2 0.000000343
#>  3 filed_doc_id          <int>        0 0          
#>  4 e_trans_id            <chr>  5753663 0.988      
#>  5 last_only_name        <chr>        2 0.000000343
#>  6 first_name            <chr>  3395551 0.583      
#>  7 rcv_date              <dttm>       2 0.000000343
#>  8 amount                <dbl>        2 0.000000343
#>  9 aggregate_amount      <dbl>        2 0.000000343
#> 10 loan_amount           <dbl>        2 0.000000343
#> 11 occupation            <chr>  5012754 0.861      
#> 12 employer              <chr>  5014127 0.861      
#> 13 address1              <chr>    24387 0.00419    
#> 14 address2              <chr>  5008222 0.860      
#> 15 city                  <chr>    33065 0.00568    
#> 16 state                 <chr>    15050 0.00258    
#> 17 zip                   <chr>    41771 0.00717    
#> 18 d2part                <chr>        4 0.000000687
#> 19 description           <chr>  5365976 0.922      
#> 20 vendor_last_only_name <chr>  5489138 0.943      
#> 21 vendor_first_name     <chr>  5696160 0.978      
#> 22 vendor_address1       <chr>  5493259 0.943      
#> 23 vendor_address2       <chr>  5787481 0.994      
#> 24 vendor_city           <chr>  5492795 0.943      
#> 25 vendor_state          <chr>  5489656 0.943      
#> 26 vendor_zip            <chr>  5489626 0.943      
#> 27 archived              <lgl>        6 0.00000103 
#> 28 country               <chr>  5741045 0.986      
#> 29 redaction_requested   <lgl>        4 0.000000687
#> 30 cmte_name             <chr>        2 0.000000343
#> 31 cmte_address          <chr>        2 0.000000343
#> 32 cmte_city             <chr>      361 0.0000620  
#> 33 cmte_state            <chr>      452 0.0000776  
#> 34 cmte_zip              <chr>     4333 0.000744
```

We can flag any record missing a key variable needed to identify a
transaction.

``` r
key_vars <- c("rcv_date", "last_only_name", "amount", "cmte_name")
ilc <- flag_na(ilc, all_of(key_vars))
sum(ilc$na_flag)
#> [1] 2
```

0.0% rows are missing a key variable.

``` r
if (sum(ilc$na_flag) == 0) {
  ilc <- select(ilc, -na_flag)
}
```

### Duplicates

We can also flag any entirely duplicate rows. To keep memory usage low
with such a large data frame, we will split our data into a list and
check each element of the list. For each chunk, we will write the
duplicate `id` to a text file.

``` r
prop_distinct(ilc$id)
#> [1] 0.9999998
```

``` r
dupe_file <- here("il", "contribs", "data", "dupe_ids.txt")
if (!file_exists(dupe_file)) {
  tmp <- file_temp(ext = "rds")
  write_rds(ilc, file = tmp)
  file_size(tmp)
  il_id <- split(ilc$id, ilc$rcv_date)
  ils <- ilc %>%
    select(-id) %>% 
    group_split(rcv_date)
  if (file_exists(tmp)) {
    rm(ilc)
    Sys.sleep(5)
    flush_memory(2)
  }
  ils <- ils[map_lgl(ils, function(x) nrow(x) > 1)]
  pb <- txtProgressBar(max = length(ils), style = 3)
  for (i in seq_along(ils)) {
    d1 <- duplicated(ils[[i]], fromLast = FALSE)
    d2 <- duplicated(ils[[i]], fromLast = TRUE)
    dupe_vec <- d1 | d2
    rm(d1, d2)
    if (any(dupe_vec)) {
      write_lines(
        x = il_id[[i]][dupe_vec], 
        file = dupe_file, 
        append = file_exists(dupe_file),
        na = ""
      )
    }
    rm(dupe_vec)
    ils[[i]] <- NA
    il_id[[i]] <- NA
    if (i %% 100 == 0) {
      Sys.sleep(2)
      flush_memory()
    }
    setTxtProgressBar(pb, i)
  }
  rm(ils, il_id)
  Sys.sleep(5)
  flush_memory()
  ilc <- read_rds(tmp)
}
```

``` r
dupe_id <- tibble(
  id = as.integer(read_lines(dupe_file, skip_empty_rows = TRUE)),
  dupe_flag = TRUE
)
ilc <- left_join(ilc, dupe_id, by = "id")
ilc <- mutate(ilc, across(dupe_flag, Negate(is.na)))
```

0.3% of rows are duplicates.

``` r
ilc %>% 
  filter(dupe_flag) %>% 
  count(rcv_date, last_only_name, amount, cmte_name, sort = TRUE)
#> # A tibble: 19,065 × 5
#>    rcv_date            last_only_name           amount cmte_name                         n
#>    <dttm>              <chr>                     <dbl> <chr>                         <int>
#>  1 2002-03-08 00:00:00 437 North Rush            1916. Friends of Blagojevich            7
#>  2 2002-03-08 00:00:00 Grais                      300  Friends of Blagojevich            6
#>  3 2002-03-08 00:00:00 Landis Plastics Inc.      1250  Citizens for Patrick O'Malley     6
#>  4 2002-05-01 00:00:00 Discount Smoke Shop        250  Citizens for Jim Watson           6
#>  5 2002-03-08 00:00:00 Bilbrey & Hylla P.C.       250  Friends of Blagojevich            5
#>  6 2002-03-08 00:00:00 DYN-PAC Illinois          2500  Friends of Blagojevich            5
#>  7 2002-05-01 00:00:00 Kelso                      500  Friends of Blagojevich            5
#>  8 2002-03-08 00:00:00 Citizens for Steve Davis  2500  Friends of Blagojevich            4
#>  9 2002-03-08 00:00:00 Deterding                  250  Friends of Blagojevich            4
#> 10 2002-03-08 00:00:00 Fernandez                 1000  Friends for Gutierrez             4
#> # ℹ 19,055 more rows
```

### Categorical

``` r
col_stats(ilc, n_distinct)
#> # A tibble: 36 × 4
#>    col                   class        n           p
#>    <chr>                 <chr>    <int>       <dbl>
#>  1 id                    <int>  5822521 1.00       
#>  2 committee_id          <int>    12507 0.00215    
#>  3 filed_doc_id          <int>   325836 0.0560     
#>  4 e_trans_id            <chr>    66905 0.0115     
#>  5 last_only_name        <chr>   493806 0.0848     
#>  6 first_name            <chr>    96356 0.0165     
#>  7 rcv_date              <dttm>   10491 0.00180    
#>  8 amount                <dbl>   115967 0.0199     
#>  9 aggregate_amount      <dbl>    90744 0.0156     
#> 10 loan_amount           <dbl>    11592 0.00199    
#> 11 occupation            <chr>    21350 0.00367    
#> 12 employer              <chr>    67279 0.0116     
#> 13 address1              <chr>   756902 0.130      
#> 14 address2              <chr>    44282 0.00761    
#> 15 city                  <chr>    17209 0.00296    
#> 16 state                 <chr>      151 0.0000259  
#> 17 zip                   <chr>    92939 0.0160     
#> 18 d2part                <chr>        7 0.00000120 
#> 19 description           <chr>    66498 0.0114     
#> 20 vendor_last_only_name <chr>    38513 0.00661    
#> 21 vendor_first_name     <chr>     4946 0.000849   
#> 22 vendor_address1       <chr>    52699 0.00905    
#> 23 vendor_address2       <chr>     2676 0.000460   
#> 24 vendor_city           <chr>     3255 0.000559   
#> 25 vendor_state          <chr>       83 0.0000143  
#> 26 vendor_zip            <chr>     6027 0.00104    
#> 27 archived              <lgl>        3 0.000000515
#> 28 country               <chr>      209 0.0000359  
#> 29 redaction_requested   <lgl>        3 0.000000515
#> 30 cmte_name             <chr>    12375 0.00213    
#> 31 cmte_address          <chr>    10760 0.00185    
#> 32 cmte_city             <chr>      819 0.000141   
#> 33 cmte_state            <chr>       29 0.00000498 
#> 34 cmte_zip              <chr>      980 0.000168   
#> 35 na_flag               <lgl>        2 0.000000343
#> 36 dupe_flag             <lgl>        2 0.000000343
```

![](../plots/distinct_plots-1.png)<!-- -->![](../plots/distinct_plots-2.png)<!-- -->

### Amounts

``` r
summary(ilc$amount)
#>      Min.   1st Qu.    Median      Mean   3rd Qu.      Max.      NA's 
#>         0       200       400      2272      1000 400164048         2
mean(ilc$amount <= 0)
#> [1] NA
```

These are the records with the minimum and maximum amounts.

``` r
glimpse(ilc[c(which.max(ilc$amount), which.min(ilc$amount)), ])
#> Rows: 2
#> Columns: 36
#> $ id                    <int> 5464817, 28693
#> $ committee_id          <int> 34699, 8511
#> $ filed_doc_id          <int> 787508, 85873
#> $ e_trans_id            <chr> NA, NA
#> $ last_only_name        <chr> "Iosbaker", "Brownstone Beverage"
#> $ first_name            <chr> "Joe", NA
#> $ rcv_date              <dttm> 2020-11-02, 1994-07-26
#> $ amount                <dbl> 400164048, 0
#> $ aggregate_amount      <dbl> 0, 0
#> $ loan_amount           <dbl> 0, 0
#> $ occupation            <chr> NA, NA
#> $ employer              <chr> NA, NA
#> $ address1              <chr> "6324 S Kimbark Ave", "5190 28th Ave"
#> $ address2              <chr> NA, NA
#> $ city                  <chr> "Chicago", "Rockford"
#> $ state                 <chr> "IL", "IL"
#> $ zip                   <chr> "60637", "61109"
#> $ d2part                <chr> "1A", "5A"
#> $ description           <chr> NA, "1 Sgnd Bo Jackson Bsbl,1 Gmn Br Stn"
#> $ vendor_last_only_name <chr> NA, NA
#> $ vendor_first_name     <chr> NA, NA
#> $ vendor_address1       <chr> NA, NA
#> $ vendor_address2       <chr> NA, NA
#> $ vendor_city           <chr> NA, NA
#> $ vendor_state          <chr> NA, NA
#> $ vendor_zip            <chr> NA, NA
#> $ archived              <lgl> TRUE, FALSE
#> $ country               <chr> NA, NA
#> $ redaction_requested   <lgl> FALSE, FALSE
#> $ cmte_name             <chr> "Friends for Celina Villanueva", "Giolitto For State Representative"
#> $ cmte_address          <chr> "4140 S ARCHER AVE SUITE N", "807 BRAE BURN LN"
#> $ cmte_city             <chr> "CHICAGO", "ROCKFORD"
#> $ cmte_state            <chr> "IL", "IL"
#> $ cmte_zip              <chr> "60632", "61107"
#> $ na_flag               <lgl> FALSE, FALSE
#> $ dupe_flag             <lgl> FALSE, FALSE
```

![](../plots/hist_amount-1.png)<!-- -->

### Dates

We can add the calendar year from `date` with `lubridate::year()`

``` r
ilc <- mutate(ilc, rcv_year = year(rcv_date))
```

``` r
min(ilc$rcv_date)
#> [1] NA
sum(ilc$rcv_year < 1994)
#> [1] NA
max(ilc$rcv_date)
#> [1] NA
sum(ilc$rcv_date > today())
#> [1] NA
```

![](../plots/bar_year-1.png)<!-- -->

## Wrangle

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are tailor made to facilitate this process.

### Address

For the street `addresss` variable, the `campfin::normal_address()`
function will force consistence case, remove punctuation, and abbreviate
official USPS suffixes.

``` r
norm_addr <- ilc %>% 
  distinct(address1, address2) %>% 
  unite(
    col = address_full,
    starts_with("address"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  mutate(
    address_norm = normal_address(
      address = address_full,
      abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-address_full)
```

``` r
sample_n(norm_addr, 10)
#> # A tibble: 10 × 3
#>    address1                    address2 address_norm                 
#>    <chr>                       <chr>    <chr>                        
#>  1 P.O. Box 1745               <NA>     PO BOX 1745                  
#>  2 1621 East New York Street   <NA>     1621 EAST NEW YORK ST        
#>  3 1103 Galen Drive            <NA>     1103 GALEN DR                
#>  4 3731 W. ROOSEVELT           <NA>     3731 W ROOSEVELT             
#>  5 6 Candlelight Dr            <NA>     6 CANDLELIGHT DR             
#>  6 7107 West Belmont Ave.      Suite 5  7107 WEST BELMONT AVE SUITE 5
#>  7 1750 New York Ave., NW      <NA>     1750 NEW YORK AVE NW         
#>  8 323 S. ASHLAND              <NA>     323 S ASHLAND                
#>  9 2210 W. Carmen Ave. Apt. 1W <NA>     2210 W CARMEN AVE APT 1W     
#> 10 8140 S. Prairei  Park       <NA>     8140 S PRAIREI PARK
```

``` r
ilc <- left_join(ilc, norm_addr, by = c("address1", "address2"))
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
ilc <- ilc %>% 
  mutate(
    zip_norm = normal_zip(
      zip = zip,
      na_rep = TRUE
    )
  )
```

``` r
progress_table(
  ilc$zip,
  ilc$zip_norm,
  compare = valid_zip
)
#> # A tibble: 2 × 6
#>   stage        prop_in n_distinct prop_na  n_out n_diff
#>   <chr>          <dbl>      <dbl>   <dbl>  <dbl>  <dbl>
#> 1 ilc$zip        0.876      92939 0.00717 715029  82204
#> 2 ilc$zip_norm   0.998      13082 0.00888  14271   1603
```

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

``` r
st_norm <- ilc %>% 
  distinct(state) %>% 
  mutate(
    state_norm = normal_state(
      state = state,
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = valid_state
    )
  )
```

``` r
st_norm %>% 
  filter(state != state_norm)
#> # A tibble: 37 × 2
#>    state state_norm
#>    <chr> <chr>     
#>  1 Mi    MI        
#>  2 Il    IL        
#>  3 Tx    TX        
#>  4 Ky    KY        
#>  5 Va    VA        
#>  6 il    IL        
#>  7 In    IN        
#>  8 Mn    MN        
#>  9 Wi    WI        
#> 10 wa    WA        
#> # ℹ 27 more rows
```

``` r
ilc <- left_join(ilc, st_norm, by = "state")
```

``` r
progress_table(
  ilc$state,
  ilc$state_norm,
  compare = valid_state
)
#> # A tibble: 2 × 6
#>   stage          prop_in n_distinct prop_na n_out n_diff
#>   <chr>            <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 ilc$state         1.00        151 0.00258  2104     95
#> 2 ilc$state_norm    1            57 0.00274     0      1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
norm_city <- ilc %>% 
  distinct(city, state_norm, zip_norm) %>% 
  mutate(
    city_norm = normal_city(
      city = city, 
      abbs = usps_city,
      states = c("IL", "DC", "ILLINOIS"),
      na = invalid_city,
      na_rep = TRUE
    )
  )
```

#### Swap

We can further improve normalization by comparing our normalized value
against the *expected* value for that record’s state abbreviation and
ZIP code. If the normalized value is either an abbreviation for or very
similar to the expected value, we can confidently swap those two.

``` r
norm_city <- norm_city %>% 
  rename(city_raw = city) %>% 
  left_join(
    y = zipcodes,
    by = c(
      "state_norm" = "state",
      "zip_norm" = "zip"
    )
  ) %>% 
  rename(city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(city_norm, city_match),
    match_dist = str_dist(city_norm, city_match),
    city_swap = if_else(
      condition = !is.na(match_dist) & (match_abb | match_dist == 1),
      true = city_match,
      false = city_norm
    )
  ) %>% 
  select(
    -city_match,
    -match_dist,
    -match_abb
  )
```

``` r
ilc <- left_join(
  x = ilc,
  y = norm_city,
  by = c(
    "city" = "city_raw", 
    "state_norm", 
    "zip_norm"
  )
)
```

#### Refine

The [OpenRefine](https://openrefine.org/) algorithms can be used to
group similar strings and replace the less common versions with their
most common counterpart. This can greatly reduce inconsistency, but with
low confidence; we will only keep any refined strings that have a valid
city/state/zip combination.

``` r
good_refine <- ilc %>% 
  mutate(
    city_refine = city_swap %>% 
      key_collision_merge() %>% 
      n_gram_merge(numgram = 1)
  ) %>% 
  filter(city_refine != city_swap) %>% 
  inner_join(
    y = zipcodes,
    by = c(
      "city_refine" = "city",
      "state_norm" = "state",
      "zip_norm" = "zip"
    )
  )
```

    #> # A tibble: 257 × 5
    #>    state_norm zip_norm city_swap          city_refine           n
    #>    <chr>      <chr>    <chr>              <chr>             <int>
    #>  1 IL         60411    SO CHICAGO HEIGHTS CHICAGO HEIGHTS     553
    #>  2 IL         60429    EAST HAZEL CREST   HAZEL CREST         470
    #>  3 IL         60010    NO BARRINGTON      BARRINGTON           65
    #>  4 IA         51102    SOUIX CITY         SIOUX CITY           53
    #>  5 IL         60429    EAST HAZELCREST    HAZEL CREST          40
    #>  6 NC         27102    WINSTIONSALEM      WINSTON SALEM        30
    #>  7 MD         20817    BESTHEDA           BETHESDA             29
    #>  8 IL         60411    SOCHICAGO HEIGHTS  CHICAGO HEIGHTS      23
    #>  9 IL         60476    THORTHON           THORNTON             23
    #> 10 IL         60007    LAKE GROVE VILLAGE ELK GROVE VILLAGE    21
    #> # ℹ 247 more rows

Then we can join the refined values back to the database.

``` r
ilc <- ilc %>% 
  left_join(good_refine, by = names(.)) %>% 
  mutate(city_refine = coalesce(city_refine, city_swap))
```

#### Progress

Our goal for normalization was to increase the proportion of city values
known to be valid and reduce the total distinct values by correcting
misspellings.

| stage                                                                      | prop_in | n_distinct | prop_na |  n_out | n_diff |
|:---------------------------------------------------------------------------|--------:|-----------:|--------:|-------:|-------:|
| str_to_upper(ilc$city) | 0.965| 13585| 0.006| 201928| 8375| |ilc$city_norm |   0.974 |      12156 |   0.006 | 152161 |   6924 |
| ilc$city_swap | 0.994| 7978| 0.006| 33812| 2754| |ilc$city_refine          |   0.995 |       7764 |   0.006 |  31787 |   2542 |

You can see how the percentage of valid values increased with each
stage.

![](../plots/bar_progress-1.png)<!-- -->

More importantly, the number of distinct values decreased each stage. We
were able to confidently change many distinct invalid values to their
valid equivalent.

![](../plots/bar_distinct-1.png)<!-- -->

Before exporting, we can remove the intermediary normalization columns
and rename all added variables with the `_clean` suffix.

``` r
ilc <- ilc %>% 
  select(
    -city_norm,
    -city_swap,
    city_clean = city_refine
  ) %>% 
  rename_all(~str_replace(., "_norm", "_clean")) %>% 
  rename_all(~str_remove(., "_raw")) %>% 
  relocate(city_clean, state_clean, zip_clean, .after = address_clean)
```

``` r
glimpse(sample_n(ilc, 50))
#> Rows: 50
#> Columns: 41
#> $ id                    <int> 5720047, 5685644, 3575904, 5251513, 3048014, 5327121, 1637265, 2792511, 562807, 4025039,…
#> $ committee_id          <int> 36993, 34087, 23965, 4255, 4565, 35482, 11769, 22077, 538, 23854, 497, 909, 22977, 25879…
#> $ filed_doc_id          <int> 839880, 831832, 477218, 748375, 413398, 760475, 294894, 391892, 204303, 538182, 753494, …
#> $ e_trans_id            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ last_only_name        <chr> "Eikenberry", "Jones", "Pierce Law Office", "Woodrow", "Republican State Senate Campaign…
#> $ first_name            <chr> "Patrick", "DeVaughn", NA, "Sheila", NA, "Matt", NA, "Venu", NA, NA, "Vicki", "Kevin", "…
#> $ rcv_date              <dttm> 2022-01-05, 2021-12-27, 2012-09-27, 2019-09-04, 2010-08-31, 2019-11-06, 2004-03-22, 200…
#> $ amount                <dbl> 250.00, 500.00, 500.00, 50.00, 268.23, 250.00, 750.00, 200.00, 1130.95, 1000.00, 257.50,…
#> $ aggregate_amount      <dbl> 250.00, 500.00, 500.00, 200.00, 18932.95, 250.00, 750.00, 1700.00, 6526.46, 1000.00, 257…
#> $ loan_amount           <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0…
#> $ occupation            <chr> NA, NA, NA, NA, NA, NA, NA, "Attorney", NA, NA, NA, NA, "VP, Global Sales", NA, "Attorne…
#> $ employer              <chr> NA, NA, NA, NA, NA, NA, NA, "Vedder Price Kaufman & Krammholz", NA, NA, NA, NA, "Wittern…
#> $ address1              <chr> "5212 N Richmond Cir", "10500 Ridgeland Ave", "461 W. Main", "1200 E Pershing Rd", "P.O.…
#> $ address2              <chr> NA, "2", "PO Box 147", NA, NA, NA, "4301 GARDEN CITY DR", NA, NA, "#300", NA, NA, NA, NA…
#> $ city                  <chr> "Bettendorf", "Chicago Ridge", "Bushnell", "Decatur", "Springfield", "Edwardsville", "LA…
#> $ state                 <chr> "IA", "IL", "IL", "IL", "IL", "IL", "MD", "IL", "IL", "DC", "IL", "IL", "IA", "IL", "IL"…
#> $ zip                   <chr> "52722", "60415", "61422", "62526", "62708", "62025", "20785", "60606", "60445", "20004"…
#> $ d2part                <chr> "1A", "1A", "1A", "1A", "5A", "1A", "2A", "1A", "1A", "1A", "1A", "1A", "1A", "2A", "1A"…
#> $ description           <chr> NA, NA, NA, NA, "Taxes", NA, NA, NA, NA, NA, NA, NA, "161549", NA, NA, NA, NA, NA, NA, N…
#> $ vendor_last_only_name <chr> NA, NA, NA, NA, "Internal Revenue Service", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ vendor_first_name     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ vendor_address1       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ vendor_address2       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ vendor_city           <chr> NA, NA, NA, NA, "Cincinnati", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ vendor_state          <chr> NA, NA, NA, NA, "OH", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA…
#> $ vendor_zip            <chr> NA, NA, NA, NA, "45999", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ archived              <lgl> FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
#> $ country               <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ redaction_requested   <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ cmte_name             <chr> "Thoms for Senate", "16th Ward Democratic Organization", "Friends of Ramon Escapa", "Ill…
#> $ cmte_address          <chr> "224 18TH STREET SUITE M200", "6200 S ADA", "PO BOX 341", "PO BOX 9493", "7805 W CATALPA…
#> $ cmte_city             <chr> "ROCK ISLAND", "CHICAGO", "RUSHVILLE", "SPRINGFIELD", "CHICAGO", "GLEN CARBON", "ROSEMON…
#> $ cmte_state            <chr> "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL", "IL"…
#> $ cmte_zip              <chr> "61201", "60636", "62681", "62791", "60656", "62034", "60018", "60305", "62705", "60011"…
#> $ na_flag               <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ dupe_flag             <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALS…
#> $ rcv_year              <dbl> 2022, 2021, 2012, 2019, 2010, 2019, 2004, 2009, 2000, 2014, 2019, 2004, 2011, 2019, 2000…
#> $ address_clean         <chr> "5212 N RICHMOND CIR", "10500 RIDGELAND AVE 2", "461 W MAIN PO BOX 147", "1200 E PERSHIN…
#> $ city_clean            <chr> "BETTENDORF", "CHICAGO RIDGE", "BUSHNELL", "DECATUR", "SPRINGFIELD", "EDWARDSVILLE", "LA…
#> $ state_clean           <chr> "IA", "IL", "IL", "IL", "IL", "IL", "MD", "IL", "IL", "DC", "IL", "IL", "IA", "IL", "IL"…
#> $ zip_clean             <chr> "52722", "60415", "61422", "62526", "62708", "62025", "20785", "60606", "60445", "20004"…
```

## Conclude

1.  There are 5,822,522 records in the database.
2.  There are 20,093 duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 2 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("il", "contribs", "data", "clean"))
clean_path <- path(clean_dir, "il_contribs_19940701-2023.csv")
write_csv(ilc, clean_path, na = "")
(clean_size <- file_size(clean_path))
#> 1.48G
```

## Upload

We can use the `aws.s3::put_object()` to upload the text file to the IRW
server.

``` r
aws_path <- path("csv", basename(clean_path))
if (!object_exists(aws_path, "publicaccountability")) {
  put_object(
    file = clean_path,
    object = aws_path, 
    bucket = "publicaccountability",
    acl = "public-read",
    show_progress = TRUE,
    multipart = TRUE
  )
}
aws_head <- head_object(aws_path, "publicaccountability")
(aws_size <- as_fs_bytes(attr(aws_head, "content-length")))
unname(aws_size == clean_size)
```
