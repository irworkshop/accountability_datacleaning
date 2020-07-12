Illinois Lobbyists Registration Data Diary
================
Yanqi Xu
2020-07-08 17:22:28

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Read](#read)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
  - [Conclude](#conclude)
  - [Export](#export)
  - [Upload](#upload)

<!-- Place comments regarding knitting here -->

## Project

The Accountability Project is an effort to cut across data silos and
give journalists, policy professionals, activists, and the public at
large a simple way to search across huge volumes of public data about
people and organizations.

Our goal is to standardizing public data on a few key fields by thinking
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

The IRW’s `campfin` package will also have to be installed from GitHub.
This package contains functions custom made to help facilitate the
processing of campaign finance data.

``` r
if (!require("pacman")) install.packages("pacman")
pacman::p_load_gh("irworkshop/campfin")
pacman::p_load(
  tidyverse, # data manipulation
  lubridate, # datetime strings
  gluedown, # printing markdown
  magrittr, # pipe operators
  janitor, # clean data frames
  refinr, # cluster and merge
  scales, # format strings
  knitr, # knit documents
  vroom, # read files fast
  rvest, # html scraping
  glue, # combine strings
  here, # relative paths
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
here::here()
#> [1] "/Users/yanqixu/code/accountability_datacleaning/R_campfin"
```

## Data

Lobbying data is obtained from the Illinois Secretary of State via a
public record request. The data is as current as of June 26, 2020.
There’re six relational tables which can be joined by IDs.

1.  `Agent.csv` for lobbyist names and addresses.
2.  `BillSearch.csv` for lobbying activity on certain bills.
3.  `Client.csv` for client names.
4.  `Firm.csv` for firm names and addresses.
5.  `IndexClient.csv` for agent, firm, client relationships.

## Read

The results data was manually exported to the `data/raw/` directory.

``` r
raw_dir <- dir_create(here("il", "lobbying", "data", "raw"))
raw_info <- as_tibble(dir_info(raw_dir))
raw_info %>% 
  select(path, size, modification_time)
#> # A tibble: 7 x 3
#>   path                                                                     size modification_time  
#>   <fs::path>                                                          <fs::byt> <dttm>             
#> 1 /Users/yanqixu/code/accountability_datacleaning/R_campfin/il/lobby…    36.98M 2020-06-26 07:31:18
#> 2 /Users/yanqixu/code/accountability_datacleaning/R_campfin/il/lobby…    410.7K 2020-06-26 07:31:02
#> 3 /Users/yanqixu/code/accountability_datacleaning/R_campfin/il/lobby…    78.43M 2020-06-26 07:31:26
#> 4 /Users/yanqixu/code/accountability_datacleaning/R_campfin/il/lobby…    14.77M 2020-07-08 17:09:51
#> 5 /Users/yanqixu/code/accountability_datacleaning/R_campfin/il/lobby…    68.39M 2020-06-26 07:31:24
#> 6 /Users/yanqixu/code/accountability_datacleaning/R_campfin/il/lobby…    37.56M 2020-06-26 07:31:18
#> 7 /Users/yanqixu/code/accountability_datacleaning/R_campfin/il/lobby…     1.66M 2020-06-26 07:31:04
```

First, we will read the `LR_LOBBING_ENT.csv` file containing the
relationships between lobbying agents, their firms, and the client
entities they represent.

According to the [IL
SOS](https://www.cyberdriveillinois.com/departments/index/lobbyist/lobbyist_search.html),
\> A lobbying entity is a corporation, association, group, firm or
person that engages in activities that require registration under the
Lobbyist Registration Act. The entity’s contact information will be
displayed with exclusive lobbyist, contractual lobbyists and/or any
clients the lobbying entity may represent. A contractual lobbyist is a
person or firm that is retained to lobby on another firm’s behalf. A
client is any corporation, association, group, firm or person that
retains a contractual lobbying entity to lobby on their behalf. The
lobbying entity registration search will also provide a list of state
agencies a lobbying entity intends to lobby and the subject matter of
their lobbying activities. The Exclusive Lobbyist Registration Search
allows you to view an exclusive lobbyist’s contact information. An
exclusive lobbyist is an employee of a registered lobbying entity. This
search will list the lobbying entity for which the Lobbyist is employed,
as well as display his or her photo.

More information about the registering entities and agents can be found
in the [Illinois Lobbyists Registration Annual Registration
Guide](https://www.cyberdriveillinois.com/publications/pdf_publications/ipub31.pdf).
\> Companies that have individual employees whose duties include
lobbying, or that have retained outside lobbyists or lobbying entities
to lobby on their behalf, are required to register as a lobbying entity.
Each calendar year, lobbying entities and exclusive lobbyists must
register before any services are performed, no later than two business
days after being employed or retained.

> A Sub-Client is an external entity, who is one of your listed clients,
> for whom you anticipate lobbying. A registering entity should not list
> themselves as their own sub-client.

The exclusive lobbyist corresponds to in-house lobbyists in other
states, while the contractual lobbyists likely work for lobbying firms
contracted by entities.

``` r
illr<- as_tibble(read.csv(file = path(raw_dir, "LR_LOBBYING_ENT.csv"), stringsAsFactors = FALSE, fileEncoding = 'UTF-16LE'))
```

The `illr` table contains all the relationships between clients and
their agents

``` r
illr <- illr %>% clean_names()
```

## Explore

``` r
glimpse(illr)
#> Rows: 49,350
#> Columns: 64
#> $ ent_id             <int> 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 8985, 8989, 8987, 8988, 2, …
#> $ ent_reg_year       <int> 2000, 2001, 2002, 2003, 2000, 2001, 2002, 2003, 2005, 2011, 2012, 201…
#> $ ent_name           <chr> "HOWLETT & PERKINS ASSOCIATES, LTD.                                  …
#> $ ent_addr1          <chr> "2501 SOUTH DESPLAINES AVENUE       ", "2501 SOUTH DESPLAINES AVENUE …
#> $ ent_addr2          <chr> "                                   ", "                             …
#> $ ent_city           <chr> "NORTH RIVERSIDE               ", "NORTH RIVERSIDE               ", "…
#> $ ent_st_abbr        <chr> "IL", "IL", "IL", "IL", "MN", "MN", "MN", "MN", "MN", "MN", "MN", "MN…
#> $ ent_zip            <chr> "60546    ", "60546    ", "60546    ", "60546    ", "551441000", "551…
#> $ ent_phone          <dbl> 7087951333, 7087951333, 7087951333, 7087951333, 6517333229, 651733715…
#> $ ent_ext            <chr> "      ", "      ", "      ", "      ", "      ", "      ", "      ",…
#> $ ent_fax            <dbl> 7087951349, 7087951349, 7087951349, 7087951349, 6515753498, 651736303…
#> $ for_profit_flag    <int> 9, 9, 9, 9, 9, 9, 9, 9, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9, …
#> $ agent_fname        <chr> "WILLIAM             ", "WILLIAM             ", "WILLIAM             …
#> $ agent_lname        <chr> "PERKINS, JR.                       ", "PERKINS, JR.                 …
#> $ agent_mname        <chr> "H.                  ", "H.                  ", "H.                  …
#> $ agent_addr1        <chr> "2501 SOUTH DES PLAINES AVENUE      ", "2501 SOUTH DES PLAINES AVENUE…
#> $ agent_addr2        <chr> "                                   ", "                             …
#> $ agent_city         <chr> "NORTH RIVERSIDE               ", "NORTH RIVERSIDE               ", "…
#> $ agent_st_abbr      <chr> "IL", "IL", "IL", "IL", "MI", "MN", "MN", "MN", "MN", "  ", "  ", "  …
#> $ agent_zip          <chr> "60546    ", "60546    ", "60546    ", "60546    ", "48152    ", "551…
#> $ agent_phone        <dbl> NA, NA, NA, NA, 7347795190, 6517367159, NA, NA, 6517376335, NA, NA, N…
#> $ agent_ext          <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ agent_fax          <dbl> NA, NA, NA, NA, NA, NA, NA, NA, 6515754920, NA, NA, NA, NA, NA, NA, N…
#> $ agent_email_addr   <chr> "WILLIAM H. PERKINS, JR.                                             …
#> $ annual_reg_dt      <int> 20000105, 20010103, 20011220, 20030110, 20000131, 20010131, 20020130,…
#> $ annual_file_dt     <int> 20000105, 20010103, 20011220, 20030110, 20000131, 20010131, 20020130,…
#> $ semi_reg_dt        <int> 0, 0, 0, 0, 0, 0, 0, 0, 20050705, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
#> $ semi_file_dt       <int> 0, 0, 0, 0, 0, 0, 0, 0, 20050705, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
#> $ amend_reg_dt       <int> 0, 0, 0, 0, 0, 0, 0, 20030825, 20050808, 20110422, 20120117, 0, 20140…
#> $ amend_file_dt      <int> 0, 0, 0, 0, 0, 0, 0, 20030825, 20050817, 20110422, 20120130, 0, 20140…
#> $ annual_exp_rec_dt  <int> 20010103, 20011220, 20021223, 20040123, 20010131, 20020129, 20021218,…
#> $ annual_exp_file_dt <int> 20010103, 20011220, 20021223, 20040123, 20010131, 20020129, 20021218,…
#> $ semi_exp_rec_dt    <int> 20000614, 20010614, 20020613, 20030609, 20000920, 20010723, 20020730,…
#> $ semi_exp_file_dt   <int> 20000614, 20010614, 20020613, 20030609, 20000920, 20010723, 20020730,…
#> $ amend_exp_rec_dt   <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ amend_exp_file_dt  <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ annual_exp_total   <dbl> 0.00, 0.00, 0.00, 0.00, 537.57, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0…
#> $ semi_exp_total     <dbl> 0.00, 0.00, 0.00, 0.00, 0.00, 2110.82, 0.00, 0.00, 0.00, 0.00, 0.00, …
#> $ self_empl_flag     <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ exempt_flag        <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ late_overide_flag  <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ late_overide_dt    <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20130726, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
#> $ date_terminated    <int> 0, 0, 0, 0, 0, 0, 0, 20030825, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
#> $ term_rec_dt        <int> 0, 0, 0, 0, 0, 0, 0, 20030825, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
#> $ ent_status_id      <int> 99, 99, 99, 99, 99, 99, 99, 99, 98, 98, 98, 100, 98, 100, 100, 100, 1…
#> $ ent_status_dt      <int> 20050715, 20050715, 20050715, 20050715, 20050715, 20050715, 20050715,…
#> $ np_letter_rec_dt   <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ np_warn_sent_dt    <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ delinq_notify_dt   <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ revoke_notify_dt   <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ appeal_notify_dt   <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ atty_gen_notify_dt <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ convict_notify_dt  <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ policy_flag        <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ signature_flag     <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ notary_flag        <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ date_created       <chr> "2005-07-15-16.05.33.958159", "2005-07-15-16.05.34.000362", "2005-07-…
#> $ created_by         <chr> "LRX01A  ", "LRX01A  ", "LRX01A  ", "LRX01A  ", "LRX01A  ", "LRX01A  …
#> $ date_updated       <chr> "2000-04-24-00.00.00.000000", "2001-01-18-00.00.00.000000", "2002-01-…
#> $ updated_by         <chr> "UNKNOWN ", "UNKNOWN ", "UNKNOWN ", "UNKNOWN ", "UNKNOWN ", "UNKNOWN …
#> $ reg_type_cd        <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ exp_override_flag  <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ exp_override_dt    <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
#> $ fee_tier_no        <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, …
tail(illr)
#> # A tibble: 6 x 64
#>   ent_id ent_reg_year ent_name ent_addr1 ent_addr2 ent_city ent_st_abbr ent_zip ent_phone ent_ext
#>    <int>        <int> <chr>    <chr>     <chr>     <chr>    <chr>       <chr>       <dbl> <chr>  
#> 1 9.00e7         2020 "HARVEY… "16001LI… "       … "HARVEY… IL          "60426…    7.08e9 "     …
#> 2 9.00e7         2020 "ILLINO… "71 WEST… "       … "SPRING… IL          "62711…    2.18e9 "     …
#> 3 9.00e7         2020 "ILLINO… "1910 S.… "SUITE 1… "LOMBAR… IL          "60148…    6.30e9 "     …
#> 4 9.00e7         2020 "GOVERN… "227 W. … "SUITE 2… "CHICAG… IL          "60606…    3.13e9 "     …
#> 5 9.00e7         2020 "AEROSO… "101 LIB… "       … "KEVIL … KY          "42053…    2.70e9 "     …
#> 6 9.00e7         2020 "ILLINO… "928 S. … "       … "SPRING… IL          "62704…    2.18e9 "     …
#> # … with 54 more variables: ent_fax <dbl>, for_profit_flag <int>, agent_fname <chr>,
#> #   agent_lname <chr>, agent_mname <chr>, agent_addr1 <chr>, agent_addr2 <chr>, agent_city <chr>,
#> #   agent_st_abbr <chr>, agent_zip <chr>, agent_phone <dbl>, agent_ext <lgl>, agent_fax <dbl>,
#> #   agent_email_addr <chr>, annual_reg_dt <int>, annual_file_dt <int>, semi_reg_dt <int>,
#> #   semi_file_dt <int>, amend_reg_dt <int>, amend_file_dt <int>, annual_exp_rec_dt <int>,
#> #   annual_exp_file_dt <int>, semi_exp_rec_dt <int>, semi_exp_file_dt <int>,
#> #   amend_exp_rec_dt <int>, amend_exp_file_dt <int>, annual_exp_total <dbl>, semi_exp_total <dbl>,
#> #   self_empl_flag <int>, exempt_flag <int>, late_overide_flag <int>, late_overide_dt <int>,
#> #   date_terminated <int>, term_rec_dt <int>, ent_status_id <int>, ent_status_dt <int>,
#> #   np_letter_rec_dt <int>, np_warn_sent_dt <int>, delinq_notify_dt <int>, revoke_notify_dt <int>,
#> #   appeal_notify_dt <int>, atty_gen_notify_dt <int>, convict_notify_dt <int>, policy_flag <int>,
#> #   signature_flag <int>, notary_flag <int>, date_created <chr>, created_by <chr>,
#> #   date_updated <chr>, updated_by <chr>, reg_type_cd <int>, exp_override_flag <int>,
#> #   exp_override_dt <int>, fee_tier_no <int>
```

### Missing

A quick look at the dataset’s date fields tells us that this dataset is
mostly complete.

``` r
col_stats(illr, count_na)
#> # A tibble: 64 x 4
#>    col                class     n      p
#>    <chr>              <chr> <int>  <dbl>
#>  1 ent_id             <int>     0 0     
#>  2 ent_reg_year       <int>     0 0     
#>  3 ent_name           <chr>     0 0     
#>  4 ent_addr1          <chr>     0 0     
#>  5 ent_addr2          <chr>     0 0     
#>  6 ent_city           <chr>     0 0     
#>  7 ent_st_abbr        <chr>     0 0     
#>  8 ent_zip            <chr>     0 0     
#>  9 ent_phone          <dbl>  1523 0.0309
#> 10 ent_ext            <chr>     0 0     
#> 11 ent_fax            <dbl> 17474 0.354 
#> 12 for_profit_flag    <int>     0 0     
#> 13 agent_fname        <chr>     0 0     
#> 14 agent_lname        <chr>     0 0     
#> 15 agent_mname        <chr>     0 0     
#> 16 agent_addr1        <chr>     0 0     
#> 17 agent_addr2        <chr>     0 0     
#> 18 agent_city         <chr>     0 0     
#> 19 agent_st_abbr      <chr>     0 0     
#> 20 agent_zip          <chr>     0 0     
#> 21 agent_phone        <dbl> 42476 0.861 
#> 22 agent_ext          <lgl> 49350 1     
#> 23 agent_fax          <dbl> 46125 0.935 
#> 24 agent_email_addr   <chr>     0 0     
#> 25 annual_reg_dt      <int>     0 0     
#> 26 annual_file_dt     <int>     0 0     
#> 27 semi_reg_dt        <int>     0 0     
#> 28 semi_file_dt       <int>     0 0     
#> 29 amend_reg_dt       <int>     0 0     
#> 30 amend_file_dt      <int>     0 0     
#> 31 annual_exp_rec_dt  <int>     0 0     
#> 32 annual_exp_file_dt <int>     0 0     
#> 33 semi_exp_rec_dt    <int>     0 0     
#> 34 semi_exp_file_dt   <int>     0 0     
#> 35 amend_exp_rec_dt   <int>     0 0     
#> 36 amend_exp_file_dt  <int>     0 0     
#> 37 annual_exp_total   <dbl>     0 0     
#> 38 semi_exp_total     <dbl>     0 0     
#> 39 self_empl_flag     <int>     0 0     
#> 40 exempt_flag        <int>     0 0     
#> 41 late_overide_flag  <int>     0 0     
#> 42 late_overide_dt    <int>     0 0     
#> 43 date_terminated    <int>     0 0     
#> 44 term_rec_dt        <int>     0 0     
#> 45 ent_status_id      <int>     0 0     
#> 46 ent_status_dt      <int>     0 0     
#> 47 np_letter_rec_dt   <int>     0 0     
#> 48 np_warn_sent_dt    <int>     0 0     
#> 49 delinq_notify_dt   <int>     0 0     
#> 50 revoke_notify_dt   <int>     0 0     
#> 51 appeal_notify_dt   <int>     0 0     
#> 52 atty_gen_notify_dt <int>     0 0     
#> 53 convict_notify_dt  <int>     0 0     
#> 54 policy_flag        <int>     0 0     
#> 55 signature_flag     <int>     0 0     
#> 56 notary_flag        <int>     0 0     
#> 57 date_created       <chr>     0 0     
#> 58 created_by         <chr>     0 0     
#> 59 date_updated       <chr>     0 0     
#> 60 updated_by         <chr>     0 0     
#> 61 reg_type_cd        <int>     0 0     
#> 62 exp_override_flag  <int>     0 0     
#> 63 exp_override_dt    <int>     0 0     
#> 64 fee_tier_no        <int>     0 0
```

### Duplicates

There are no duplicate records.

``` r
illr <- flag_dupes(illr, everything())
#> Warning in flag_dupes(illr, everything()): no duplicate rows, column not created
```

### Categorical

``` r
col_stats(illr, n_distinct)
#> # A tibble: 64 x 4
#>    col                class     n         p
#>    <chr>              <chr> <int>     <dbl>
#>  1 ent_id             <int> 13772 0.279    
#>  2 ent_reg_year       <int>    21 0.000426 
#>  3 ent_name           <chr> 12743 0.258    
#>  4 ent_addr1          <chr> 12567 0.255    
#>  5 ent_addr2          <chr>  1756 0.0356   
#>  6 ent_city           <chr>  1338 0.0271   
#>  7 ent_st_abbr        <chr>    58 0.00118  
#>  8 ent_zip            <chr>  2598 0.0526   
#>  9 ent_phone          <dbl> 10598 0.215    
#> 10 ent_ext            <chr>   409 0.00829  
#> 11 ent_fax            <dbl>  5754 0.117    
#> 12 for_profit_flag    <int>     4 0.0000811
#> 13 agent_fname        <chr>   759 0.0154   
#> 14 agent_lname        <chr>  2269 0.0460   
#> 15 agent_mname        <chr>   156 0.00316  
#> 16 agent_addr1        <chr>  3604 0.0730   
#> 17 agent_addr2        <chr>   606 0.0123   
#> 18 agent_city         <chr>   496 0.0101   
#> 19 agent_st_abbr      <chr>    40 0.000811 
#> 20 agent_zip          <chr>   992 0.0201   
#> 21 agent_phone        <dbl>  2332 0.0473   
#> 22 agent_ext          <lgl>     1 0.0000203
#> 23 agent_fax          <dbl>  1471 0.0298   
#> 24 agent_email_addr   <chr>  3043 0.0617   
#> 25 annual_reg_dt      <int>  3745 0.0759   
#> 26 annual_file_dt     <int>  3127 0.0634   
#> 27 semi_reg_dt        <int>   537 0.0109   
#> 28 semi_file_dt       <int>   430 0.00871  
#> 29 amend_reg_dt       <int>  3382 0.0685   
#> 30 amend_file_dt      <int>  2751 0.0557   
#> 31 annual_exp_rec_dt  <int>  1004 0.0203   
#> 32 annual_exp_file_dt <int>   521 0.0106   
#> 33 semi_exp_rec_dt    <int>   889 0.0180   
#> 34 semi_exp_file_dt   <int>   532 0.0108   
#> 35 amend_exp_rec_dt   <int>  1847 0.0374   
#> 36 amend_exp_file_dt  <int>    71 0.00144  
#> 37 annual_exp_total   <dbl>   892 0.0181   
#> 38 semi_exp_total     <dbl>  1267 0.0257   
#> 39 self_empl_flag     <int>     3 0.0000608
#> 40 exempt_flag        <int>     2 0.0000405
#> 41 late_overide_flag  <int>     1 0.0000203
#> 42 late_overide_dt    <int>   386 0.00782  
#> 43 date_terminated    <int>   666 0.0135   
#> 44 term_rec_dt        <int>   666 0.0135   
#> 45 ent_status_id      <int>     5 0.000101 
#> 46 ent_status_dt      <int>  3279 0.0664   
#> 47 np_letter_rec_dt   <int>   484 0.00981  
#> 48 np_warn_sent_dt    <int>     1 0.0000203
#> 49 delinq_notify_dt   <int>     1 0.0000203
#> 50 revoke_notify_dt   <int>     1 0.0000203
#> 51 appeal_notify_dt   <int>     1 0.0000203
#> 52 atty_gen_notify_dt <int>     1 0.0000203
#> 53 convict_notify_dt  <int>     1 0.0000203
#> 54 policy_flag        <int>     1 0.0000203
#> 55 signature_flag     <int>     1 0.0000203
#> 56 notary_flag        <int>     1 0.0000203
#> 57 date_created       <chr> 49350 1        
#> 58 created_by         <chr>  5683 0.115    
#> 59 date_updated       <chr> 37395 0.758    
#> 60 updated_by         <chr>  5356 0.109    
#> 61 reg_type_cd        <int>     1 0.0000203
#> 62 exp_override_flag  <int>     2 0.0000405
#> 63 exp_override_dt    <int>    34 0.000689 
#> 64 fee_tier_no        <int>     1 0.0000203
```

### Dates

Most of the dates were read as strings. We’ll need to manually convert
them to date types.

``` r
illr <- illr %>%
  mutate_at(.vars = vars(ends_with("dt")), .funs = as.character) %>% 
  mutate_at(.vars = vars(ends_with("dt")),.funs = as.Date,format="%Y%m%d")
```

![](../plots/bar_year-1.png)<!-- -->

## Wrangle

We can see that the agents’ names have extraneous white spaces, which
can be removed by `str_trim()`

``` r
illr <-  illr %>% 
  mutate_at(.vars = vars(ends_with("name")),.funs = str_trim)
```

To improve the searchability of the database, we will perform some
consistent, confident string normalization. For geographic variables
like city names and ZIP codes, the corresponding `campfin::normal_*()`
functions are tailor made to facilitate this process.

### Address

For the street `addresss` variable, the `campfin::normal_address()`
function will force consistence case, remove punctuation, and abbreviate
official USPS suffixes.

``` r
illr <- illr %>% 
      # combine street addr
  unite(
    col = ent_address,
    starts_with("ent_addr"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
    unite(
    col = agent_address,
    starts_with("agent_addr"),
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  )

illr <- illr %>% mutate_at(
   .vars = vars(ends_with('address')), 
   .funs = list(norm = ~ normal_address(
    .,
     abbs = usps_street,
     na = invalid_city
   )
 ))
```

``` r
illr %>% 
  select(ends_with("address"), ends_with("address_norm")) %>% 
  distinct() %>% 
  sample_n(10)
#> # A tibble: 10 x 4
#>    ent_address                   agent_address                  ent_address_norm   agent_address_n…
#>    <chr>                         <chr>                          <chr>              <chr>           
#>  1 "5 NORTH COUNTRY CLUB RD.   … "                            … 5 N COUNTRY CLB RD <NA>            
#>  2 "6801 SPRING CREEK RD       … "                            … 6801 SPG CRK RD 3… <NA>            
#>  3 "500 SUMMIT LAKE DRIVE, SUIT… "                            … 500 SMT LK DR STE… <NA>            
#>  4 "#2 LAWRENCE SQUARE         … "                            … 2 LAWRENCE SQ      <NA>            
#>  5 "601 W. MONROE ST.          … "1717 S. FIFTH ST.           … 601 W MONROE ST    1717 S FIFTH ST 
#>  6 "1901 TOM MERWIN DR., BOX 45… "                            … 1901 TOM MERWIN D… <NA>            
#>  7 "112 WEST COOK STREET       … "112 WEST COOK STREET        … 112 W COOK ST      112 W COOK ST   
#>  8 "2341 IROQUOIS LANE         … "                            … 2341 IROQUOIS LN   <NA>            
#>  9 "23815 S. RAYMOND AVE       … "                            … 23815 S RAYMOND A… <NA>            
#> 10 "P.O. BOX 25001             … "P.O. BOX 25001              … PO BOX 25001       PO BOX 25001
illr <- illr %>% select(-ends_with("address"))
```

### ZIP

For ZIP codes, the `campfin::normal_zip()` function will attempt to
create valid *five* digit codes by removing the ZIP+4 suffix and
returning leading zeroes dropped by other programs like Microsoft Excel.

``` r
illr <- illr %>% mutate_at(
  .vars = vars(ends_with("zip")),
  .funs = list(norm = ~ normal_zip(
    .,
    na_rep = TRUE
  )
)
)
```

``` r
progress_table(
  illr$ent_zip,
  illr$ent_zip_norm,
  illr$agent_zip,
  illr$agent_zip_norm,
  compare = valid_zip
)
#> # A tibble: 4 x 6
#>   stage          prop_in n_distinct prop_na n_out n_diff
#>   <chr>            <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 ent_zip          0           2598  0      49350   2598
#> 2 ent_zip_norm     0.998       2015  0.0321   115     44
#> 3 agent_zip        0            992  0      49350    992
#> 4 agent_zip_norm   0.999        767  0.786     12      7
```

### State

Valid two digit state abbreviations can be made using the
`campfin::normal_state()` function.

``` r
illr <- illr %>% 
  mutate_at(
    .vars = vars(ends_with("st_abbr")),
  .funs = list(norm = ~ normal_state(
      .,
      abbreviate = TRUE,
      na_rep = TRUE,
      valid = valid_state
    )
  )
  )
```

``` r
progress_table(
  illr$ent_st_abbr,
  illr$ent_st_abbr_norm,
  illr$agent_st_abbr,
  illr$agent_st_abbr_norm,
  compare = valid_state
)
#> # A tibble: 4 x 6
#>   stage              prop_in n_distinct prop_na n_out n_diff
#>   <chr>                <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 ent_st_abbr          0.969         58  0       1521      7
#> 2 ent_st_abbr_norm     1             52  0.0308     0      1
#> 3 agent_st_abbr        0.214         40  0      38795      1
#> 4 agent_st_abbr_norm   1             40  0.786      0      1
```

### City

Cities are the most difficult geographic variable to normalize, simply
due to the wide variety of valid cities and formats.

#### Normal

The `campfin::normal_city()` function is a good start, again converting
case, removing punctuation, but *expanding* USPS abbreviations. We can
also remove `invalid_city` values.

``` r
illr <- illr %>% 
  mutate_at(
    .vars = vars(ends_with("city")),
  .funs = list(norm = ~ normal_city(
      ., 
      abbs = usps_city,
      states = valid_state,
      na = invalid_city,
      na_rep = TRUE
    )
  )
  )
```

#### Swap

We can further improve normalization by comparing our normalized value
against the *expected* value for that record’s state abbreviation and
ZIP code. If the normalized value is either an abbreviation for or very
similar to the expected value, we can confidently swap those two.

``` r
illr <- illr %>% 
  left_join(
    y = zipcodes,
    by = c(
      "ent_st_abbr_norm" = "state",
      "ent_zip_norm" = "zip"
    )
  ) %>% 
  rename(ent_city_match = city) %>% 
  mutate(
    match_abb = is_abbrev(ent_city_norm, ent_city_match),
    match_dist = str_dist(ent_city_norm, ent_city_match),
    ent_city_swap = if_else(
      condition = !is.na(match_dist) & match_abb | match_dist == 1,
      true = ent_city_match,
      false = ent_city_norm
    )
  ) %>% 
  select(
    -ent_city_match,
    -match_dist,
    -match_abb
  )
```

#### Progress

| stage             | prop\_in | n\_distinct | prop\_na | n\_out | n\_diff |
| :---------------- | -------: | ----------: | -------: | -----: | ------: |
| ent\_city)        |    0.000 |        1338 |    0.000 |  49350 |    1338 |
| ent\_city\_norm   |    0.987 |        1288 |    0.029 |    617 |     174 |
| ent\_city\_swap   |    0.994 |        1147 |    0.037 |    263 |      49 |
| agent\_city)      |    0.000 |         496 |    0.000 |  49350 |     496 |
| agent\_city\_norm |    0.993 |         493 |    0.786 |     72 |      31 |

``` r
illr <- illr %>% 
  select(-ent_city_norm) %>% 
  rename(ent_city_norm = ent_city_swap)
```

## Conclude

Before exporting, we can remove the intermediary normalization columns
and rename all added variables with the `_clean` suffix.

``` r
illr <- illr %>% 
  rename_all(~str_replace(., "_norm", "_clean")) 
```

``` r
glimpse(sample_n(illr, 20))
#> Rows: 20
#> Columns: 72
#> $ ent_id              <int> 5347, 6438, 1597, 90004556, 1974, 5172, 484, 240, 5285, 7230, 4037, …
#> $ ent_reg_year        <int> 2009, 2014, 2003, 2012, 2006, 2008, 2014, 2001, 2011, 2014, 2010, 20…
#> $ ent_name            <chr> "SIRCON CORPORATION", "SAMCO ENTERPRISES", "GOVERNMENT PROPERTY FUND…
#> $ ent_addr1           <chr> "2112 UNIVERSITY PARK DRIVE         ", "155 W. KINZIE               …
#> $ ent_addr2           <chr> "                                   ", "                            …
#> $ ent_city            <chr> "OKEMOS                        ", "CHICAGO                       ", …
#> $ ent_st_abbr         <chr> "MI", "IL", "IL", "CA", "IL", "NY", "IL", "IL", "DC", "NY", "IL", "I…
#> $ ent_zip             <chr> "48864    ", "60654    ", "62701    ", "91745    ", "62704    ", "10…
#> $ ent_phone           <dbl> 5173813888, 7733488899, 2177891770, 6263367711, 2175226121, 21253852…
#> $ ent_ext             <chr> "      ", "      ", "      ", "      ", "      ", "      ", "      "…
#> $ ent_fax             <dbl> NA, NA, NA, 6263363777, 2175229848, 9173264392, 3128324700, 77354951…
#> $ for_profit_flag     <int> 1, 1, 9, 2, 1, 1, 1, 9, 1, 1, 1, 9, 1, 1, 9, 1, 1, 1, 1, 9
#> $ agent_fname         <chr> "", "", "PENNY", "", "", "", "", "TRACY", "", "", "", "WILLIAM", "",…
#> $ agent_lname         <chr> "", "", "WILLIAMS", "", "", "", "", "SHEPHERD", "", "", "", "MCGUFFA…
#> $ agent_mname         <chr> "", "", "", "", "", "", "", "K.", "", "", "", "", "", "", "M.", "", …
#> $ agent_addr1         <chr> "                                   ", "                            …
#> $ agent_addr2         <chr> "                                   ", "                            …
#> $ agent_city          <chr> "                              ", "                              ", …
#> $ agent_st_abbr       <chr> "  ", "  ", "IL", "  ", "  ", "  ", "  ", "IL", "  ", "  ", "  ", "I…
#> $ agent_zip           <chr> "         ", "         ", "62701    ", "         ", "         ", "  …
#> $ agent_phone         <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ agent_ext           <lgl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ agent_fax           <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
#> $ agent_email_addr    <chr> "                                                                   …
#> $ annual_reg_dt       <date> 2009-03-05, 2014-03-11, 2003-01-31, NA, 2006-01-29, 2008-06-23, 201…
#> $ annual_file_dt      <date> 2009-03-12, 2014-03-12, 2003-01-31, NA, 2006-02-17, 2008-06-30, 201…
#> $ semi_reg_dt         <date> 2009-07-08, NA, NA, NA, 2006-08-09, 2008-07-24, NA, NA, NA, NA, NA,…
#> $ semi_file_dt        <date> 2009-07-08, NA, NA, NA, 2006-08-15, 2008-08-12, NA, NA, NA, NA, NA,…
#> $ amend_reg_dt        <date> NA, 2014-03-12, NA, NA, 2006-07-31, 2009-01-30, NA, NA, NA, NA, NA,…
#> $ amend_file_dt       <date> NA, 2014-03-12, NA, NA, 2006-08-04, 2009-02-05, NA, NA, NA, NA, NA,…
#> $ annual_exp_rec_dt   <date> 2010-01-12, NA, 2004-01-20, NA, 2007-01-30, 2009-01-30, NA, 2002-01…
#> $ annual_exp_file_dt  <date> NA, NA, 2004-01-20, NA, NA, NA, NA, 2002-01-31, NA, NA, NA, 2003-01…
#> $ semi_exp_rec_dt     <date> 2009-07-09, NA, 2003-06-10, NA, 2007-01-28, 2008-07-24, NA, 2001-07…
#> $ semi_exp_file_dt    <date> NA, NA, 2003-06-10, NA, 2006-07-31, NA, NA, 2001-07-31, NA, NA, NA,…
#> $ amend_exp_rec_dt    <date> 2009-07-09, NA, NA, NA, NA, 2009-01-30, NA, NA, NA, NA, NA, NA, NA,…
#> $ amend_exp_file_dt   <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ annual_exp_total    <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
#> $ semi_exp_total      <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
#> $ self_empl_flag      <int> 0, 0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
#> $ exempt_flag         <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
#> $ late_overide_flag   <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
#> $ late_overide_dt     <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ date_terminated     <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
#> $ term_rec_dt         <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ ent_status_id       <int> 98, 98, 99, 98, 98, 98, 100, 99, 100, 100, 100, 99, 100, 100, 99, 10…
#> $ ent_status_dt       <date> 2009-03-05, 2014-03-11, 2005-07-15, 2012-05-01, 2006-01-29, 2008-06…
#> $ np_letter_rec_dt    <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ np_warn_sent_dt     <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ delinq_notify_dt    <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ revoke_notify_dt    <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ appeal_notify_dt    <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ atty_gen_notify_dt  <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ convict_notify_dt   <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ policy_flag         <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
#> $ signature_flag      <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
#> $ notary_flag         <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
#> $ date_created        <chr> "2009-03-05-09.44.54.164635", "2014-03-11-14.14.24.241422", "2005-07…
#> $ created_by          <chr> "WSIE0102", "OMPANTOJ", "LRX01A  ", "DMAN0103", "TMCA0101", "AARNOLD…
#> $ date_updated        <chr> "2010-01-12-10.00.55.776052", "2014-03-12-16.08.24.075549", "2003-02…
#> $ updated_by          <chr> "WSIE0102", "OMPANTOJ", "UNKNOWN ", "DMAN0103", "TMCA0101", "CSBACC …
#> $ reg_type_cd         <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
#> $ exp_override_flag   <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
#> $ exp_override_dt     <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
#> $ fee_tier_no         <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
#> $ ent_address_clean   <chr> "2112 UNIVERSITY PARK DR", "155 W KINZIE", "241 N FIFTH ST", "16150 …
#> $ agent_address_clean <chr> NA, NA, "241 N FIFTH ST", NA, NA, NA, NA, "2060 N CLARK ST", NA, NA,…
#> $ ent_zip_clean       <chr> "48864", "60654", "62701", "91745", "62704", "10010", "60654", "6061…
#> $ agent_zip_clean     <chr> NA, NA, "62701", NA, NA, NA, NA, "60614", NA, NA, NA, "60602", NA, N…
#> $ ent_st_abbr_clean   <chr> "MI", "IL", "IL", "CA", "IL", "NY", "IL", "IL", "DC", "NY", "IL", "I…
#> $ agent_st_abbr_clean <chr> NA, NA, "IL", NA, NA, NA, NA, "IL", NA, NA, NA, "IL", NA, NA, "IL", …
#> $ agent_city_clean    <chr> NA, NA, "SPRINGFIELD", NA, NA, NA, NA, "CHICAGO", NA, NA, NA, "CHICA…
#> $ ent_city_clean      <chr> "OKEMOS", "CHICAGO", "SPRINGFIELD", "CITY OF INDUSTRY", "SPRINGFIELD…
```

1.  There are 49,350 records in the database.
2.  There are no duplicate records in the database.
3.  The range and distribution of `amount` and `date` seem reasonable.
4.  There are 0 records missing key variables.
5.  Consistency in geographic data has been improved with
    `campfin::normal_*()`.
6.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

Now the file can be saved on disk for upload to the Accountability
server.

``` r
clean_dir <- dir_create(here("il", "lobbying", "data", "clean","reg"))
clean_path <- path(clean_dir, "il_lobby_reg_clean.csv")
write_csv(illr, clean_path, na = "")
file_size(clean_path)
#> 29M
```

## Upload

Using the [duckr](https://github.com/kiernann/duckr) R package, we can
wrap around the [duck](https://duck.sh/) command line tool to upload the
file to the IRW server.

``` r
# remotes::install_github("kiernann/duckr")
s3_dir <- "s3:/publicaccountability/csv/"
s3_path <- path(s3_dir, basename(clean_path))
if (require(duckr)) {
  duckr::duck_upload(clean_path, s3_path)
}
```
