Connecticut Lobbying Compensation Data Diary
================
Yanqi Xu
2020-04-15 16:38:43

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Download](#download)
  - [Import](#import)
  - [Explore](#explore)
  - [Export](#export)

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

``` r
if (!require("pacman")) install.packages("pacman")
pacman::p_load_current_gh("irworkshop/campfin")
pacman::p_load(
  rvest, # read html tables
  httr, # interact with http requests
  stringdist, # levenshtein value
  tidyverse, # data manipulation
  lubridate, # datetime strings
  tidytext, # string analysis
  magrittr, # pipe opperators
  janitor, # dataframe clean
  refinr, # cluster and merge
  knitr, # knit documents
  glue, # combine strings
  scales, #format strings
  here, # relative storage
  fs, # search storage 
  vroom, #read deliminated files
  readxl #read excel files
)
```

This document should be run as part of the `R_campfin` project, which
lives as a sub-directory of the more general, language-agnostic
\[`irworkshop/accountability_datacleaning`\]\[01\] GitHub repository.

The `R_campfin` project uses the \[RStudio projects\]\[02\] feature and
should be run as such. The project also uses the dynamic `here::here()`
tool for file paths relative to *your* machine.

## Download

Set the download directory first.

``` r
# create a directory for the raw data
raw_dir <- here("ct", "lobby", "data", "raw","exp")

dir_create(raw_dir)
```

According to \[CT Office of State Ethics\]
[03](https://www.oseapps.ct.gov/NewLobbyist/PublicReports/LobbyistFAQ.aspx),

> Lobbying in Connecticut is defined as “communicating directly or
> soliciting others to communicate with any official or his or her staff
> in the legislative or executive branch of government or in a
> quasi-public agency, for the purpose of influencing any legislative or
> administrative action.”

Lobbyist terms:  
\> A Client Lobbyist is the party paying for lobbying services on its
behalf. In other words, the client lobbyist is expending or agreeing to
expend the threshold amount of $3,000 in a calendar year. A Communicator
Lobbyist receives payment and does the actual lobbying legwork (i.e.,
communicating or soliciting others to communicate).  
\> A Communicator Lobbyist receives or agrees to receive $3,000 for
lobbying activities in a calendar year. A communicator lobbyist can
be:  
1\. An individual; or 2. A member of a Business Organization (e.g., a
firm or association that is owned by or employs a number of lobbyists),
Conn. Gen. Stat. § 1-91 (t); or 3. An In-house Communicator (a lobbyist
who is a salaried employee of a client lobbyist).

Registration and Filing Specifics:

> Individuals or entities are required by law to register as a lobbyist
> with the Office of State Ethics (OSE) if they:  
> 1\. Expend or agree to expend $3,000 or more in a calendar year in
> lobbying; OR 2. Receive or agree to receive $3,000 or more in a
> calendar year in lobbying. Once the $3,000 threshold is met,
> registration with the OSE is required. Registration occurs biennially
> (every two years) by January 15, or prior to the commencement of
> lobbying, whichever is later.

Client Lobbyists:  
\> Client lobbyists file quarterly financial reports, with the third and
fourth quarters combined. These reports are filed between the 1st and
10th days of April, July and January.  
2\. To ensure timely transparency, if a client lobbyist spends or agrees
to spend more than $100 in legislative lobbying while the Legislature is
in regular session, that lobbyist must file monthly financial reports.  
3\. The quarterly and monthly reports gather information such as
compensation, sales tax and money expended in connection with lobbying;
expenditures benefiting a public official or his/her staff or immediate
family; all other lobbying expenditures; and the fundamental terms of
any lobbying contract or agreement.

Communicator Lobbyists:

    > Communicator lobbyists also register upon meeting the threshold amount. Communicator lobbyists generally file a financial report once a year, due by January 10. These reports capture compensation, reimbursements from the client lobbyist and sales tax for the previous year.  
    If a communicator lobbyist makes unreimbursed expenditures of $10 or more for the benefit of a public official, a member of his/her staff, or his/her immediate family, that lobbyist must also file on the client lobbyists schedule (either monthly or quarterly).

This Rmd file documents the data processing workflow for CT lobbying
compensation only, whereas the registration data is wrangled in a
separate data diary. The data is last downloaded on April 15, 2020.

## Import

To create a single clean data file of lobbyist compensation, we will
merge the data tables of each year into a master data frame.

### Download

We’ll download the `Communicator Detail Compensation` reports from
[Office of State
Ethics](https://www.oseapps.ct.gov/NewLobbyist/PublicReports/AdditionalReports.aspx#)
=\> Additional Reports +\> Issue/Financial Reports, as they specify the
payors (clients) and payees (lobbyists) in a single data frame. The data
is separated by year.

We can download each TXT file to the `/ct/data/raw` directory.

    #> # A tibble: 4 x 4
    #>   path                                       type         size birth_time         
    #>   <chr>                                      <fct> <fs::bytes> <dttm>             
    #> 1 /ct/lobby/data/raw/exp/lobby_comp_2013.csv file         534K 2019-12-23 08:08:08
    #> 2 /ct/lobby/data/raw/exp/lobby_comp_2015.csv file         581K 2019-12-23 07:51:36
    #> 3 /ct/lobby/data/raw/exp/lobby_comp_2017.csv file         569K 2019-12-23 07:51:14
    #> 4 /ct/lobby/data/raw/exp/lobby_comp_2019.csv file         478K 2020-04-15 14:37:40

### Read

We will remove the commas and dollar signs in currency expressions.

``` r
ctlc <- map_dfr(
  .x = dir_ls(raw_dir),
  .f = read_csv,
  .id = "source_file",
  col_types = cols(
    .default = col_character()
      ))

ctlc <- clean_names(ctlc)

ctlc <- ctlc %>% mutate_if(.predicate = str_detect(.,"\\$"),
                           .funs = ~str_remove_all(.,"\\$|,"))

ctlc[5:8] <-  ctlc[5:8] %>% map(as.numeric)
```

## Explore

``` r
head(ctlc)
#> # A tibble: 6 x 8
#>   source_file              communicator  client   selected_type comp_amt sales_tax exp_reimb  total
#>   <chr>                    <chr>         <chr>    <chr>            <dbl>     <dbl>     <dbl>  <dbl>
#> 1 /Users/yanqixu/code/acc… 3D Consultin… Eversou… Administrati…        0         0         0      0
#> 2 /Users/yanqixu/code/acc… 3D Consultin… Eversou… Legislative     240000         0       750 240750
#> 3 /Users/yanqixu/code/acc… 3D Consultin… Eversou… ClientTotal     240000         0       750 240750
#> 4 /Users/yanqixu/code/acc… Aaron Cheever Advance… Administrati…        0         0         0      0
#> 5 /Users/yanqixu/code/acc… Aaron Cheever Advance… Legislative          0         0         0      0
#> 6 /Users/yanqixu/code/acc… Aaron Cheever Advance… ClientTotal          0         0         0      0
tail(ctlc)
#> # A tibble: 6 x 8
#>   source_file              communicator client    selected_type comp_amt sales_tax exp_reimb  total
#>   <chr>                    <chr>        <chr>     <chr>            <dbl>     <dbl>     <dbl>  <dbl>
#> 1 /Users/yanqixu/code/acc… Zachary Lea… AFSCME C… ClientTotal     75661.         0      685. 76346.
#> 2 /Users/yanqixu/code/acc… Zachary McK… CT Confe… Administrati…       0          0        0      0 
#> 3 /Users/yanqixu/code/acc… Zachary McK… CT Confe… Legislative     19025          0      408  19433 
#> 4 /Users/yanqixu/code/acc… Zachary McK… CT Confe… ClientTotal     19025          0      408  19433 
#> 5 /Users/yanqixu/code/acc… Zack Campbe… Working … Legislative      7194.         0        0   7194.
#> 6 /Users/yanqixu/code/acc… Zack Campbe… Working … ClientTotal      7194.         0        0   7194.
glimpse(sample_frac(ctlc))
#> Rows: 19,552
#> Columns: 8
#> $ source_file   <chr> "/Users/yanqixu/code/accountability_datacleaning/R_campfin/ct/lobby/data/r…
#> $ communicator  <chr> "Lorelei Mottese", "Halloran & Sage Government Affairs, LLC", "Reynolds St…
#> $ client        <chr> "Wakefern Food Corporation", "CT Society of Plastic and Reconstructive Sur…
#> $ selected_type <chr> "Administrative", "ClientTotal", "Administrative", "Administrative", "Admi…
#> $ comp_amt      <dbl> 0.00, 14000.00, 60416.67, 94029.24, 0.00, 18910.30, 29732.75, 6006.51, 855…
#> $ sales_tax     <dbl> 0.00, 0.00, 0.00, 5970.84, 0.00, 0.00, 0.00, 0.00, 5427.78, 0.00, 0.00, 0.…
#> $ exp_reimb     <dbl> 0.00, 0.00, 0.00, 0.00, 0.00, 1171.60, 561.83, 0.00, 0.00, 1350.00, 0.00, …
#> $ total         <dbl> 0.00, 14000.00, 60416.67, 100000.08, 0.00, 20081.90, 30294.58, 6006.51, 90…
```

``` r
ctlc <- distinct(ctlc)
```

### Missing

The data file doesn’t seem to miss any important fields.

``` r
col_stats(ctlc, count_na)
#> # A tibble: 8 x 4
#>   col           class     n     p
#>   <chr>         <chr> <int> <dbl>
#> 1 source_file   <chr>     0     0
#> 2 communicator  <chr>     0     0
#> 3 client        <chr>     0     0
#> 4 selected_type <chr>     0     0
#> 5 comp_amt      <dbl>     0     0
#> 6 sales_tax     <dbl>     0     0
#> 7 exp_reimb     <dbl>     0     0
#> 8 total         <dbl>     0     0
```

### Duplicates

We can see there’s no duplicate entry.

``` r
ctlc <- flag_dupes(ctlc, dplyr::everything())
sum(ctlc$dupe_flag)
#> [1] 0
```

### Session

The original data doesn’t contain fields indicative of time. We’ll use
the file name to identify the legislative sessions they correspond to by
creating a variable `session`.

``` r
ctlc <- ctlc %>% mutate(session = str_extract(source_file, "\\d{4}")) %>% 
                          mutate(session = case_when(session == "2013" ~ "2013-2014",
                            session == "2015" ~ "2015-2016",
                             session == "2017" ~ "2017-2018",
                             session == "2019" ~ "2019-2020")) %>% 
        select(-source_file)
```

![](../plots/year_bar_quarter-1.png)<!-- -->

### Continuous

We can use the data to find out who are the top spenders, and how their
payment amounts are distributed. ![](../plots/top%20comp-1.png)<!-- -->

We’ll need the ID information from the registration list that we
previously processed. Note that the registration data is arranged by
year and not session, so a session may include multiple
`client-communicator` intances.Since duplicates will be joined multiple
times to the actual compensation data frame, and thus we do not wish to
introduce duplicates in this joined data frame. We will de-dupe the
registration data for each year and prioritize years that have more
comprehensive information than the other year of the same session. That
is, we will create a column `na_count` counting the `NA` values of each
row and only maintain the intance with a smaller `na_count` value.

``` r
reg_dir <- here("ct", "lobby", "data", "processed","reg")
ct_reg <- read_csv(glue("{reg_dir}/ct_lobby_reg.csv"),col_types = cols(.default = col_character()))

ct_reg <- ct_reg %>% 
  # Remove some nonessential columns where communicator is "`"
  filter(communicator_name_clean != "1") %>% 
  mutate(session = case_when(str_detect(client_year, "2013|2014") ~ "2013-2014",
                             str_detect(client_year, "2015|2016") ~ "2015-2016",
                             str_detect(client_year, "2017|2018") ~ "2017-2018",
                             str_detect(client_year, "2019|2020") ~ "2019-2020"))

ct_join <- ct_reg %>% 
  select(client_name,client_year, lobbyist_first_name,lobbyist_last_name,lobbyist_year,client_address_clean, session,client_phone,client_city_clean,client_email, client_zip, client_state, lobbyist_city_clean, lobbyist_address_clean, lobbyist_state, lobbyist_zip, lobbyist_email) %>% 
  # we can safely de-dupe the rows where only the lobbyist_year is different from one another 
  flag_dupes(-lobbyist_year) %>% 
  filter(!dupe_flag)

ct_count <- ct_join %>% count(client_name, lobbyist_first_name, lobbyist_last_name, session) %>% arrange(desc(n))
  #count(client_name, lobbyist_first_name, lobbyist_last_name)
```

Our goal is to reduce the number of rows in the `ct_reg` table to 9932,
which is the total number of ct\_reg rows (each row represents a
distinct relationship between a client and a lobbyist for a session).

``` r
ct_join <- ct_join %>% 
  add_count(client_name, lobbyist_first_name, lobbyist_last_name, session)
#the ct_dedupe dataframe contains twice as many rows as the difference between nrow(ct_join) and nrow(ct_count)
ct_dupe <- ct_join %>% filter(n==2) %>% 
  mutate(row_sum = rowSums(is.na(.)))

ct_dedupe <- ct_dupe %>% group_split(client_name, lobbyist_first_name, lobbyist_last_name, session)

# For entries with the same client_name, lobbyist_first_name, lobbyist_last_name, session, we group them in a list for comparison
for (i in seq_along(ct_dedupe)){
ct_dedupe[[i]] <- ct_dedupe[[i]] %>% 
  # early_more_info suggests whether the first entry has more information
  mutate(early_more_info = ct_dedupe[[i]]$row_sum[1] - ct_dedupe[[i]]$row_sum[2] < 0 ) 
# if the first entry has more non-NA columns, use the first entry, otherwise use the second instance.
  if (ct_dedupe[[i]]$early_more_info[1]) {
  ct_dedupe[[i]] <- ct_dedupe[[i]][1,]
  }
  else{
  ct_dedupe[[i]] <- ct_dedupe[[i]][2,]
  }
}

ct_deduped <- ct_dedupe %>% plyr::ldply() %>% select(-c(row_sum,early_more_info,n))
# first remove all the double entries
ct_join<- ct_join %>% filter(n != 2) %>% 
  unite(remove = T, col = "communicator", lobbyist_first_name, lobbyist_last_name,sep = " ", na.rm = TRUE) %>% select(-n) %>% 
#then add the ones we're keeping back
  bind_rows(ct_deduped) %>% 
  rename(client = client_name)
```

``` r
ctlc_clean <- ctlc %>% 
  mutate_if(is.character, str_to_upper) %>% 
  left_join(ct_join, by = c("client", "communicator", "session")) 

col_stats(ctlc_clean, count_na)         
#> # A tibble: 24 x 4
#>    col                    class     n     p
#>    <chr>                  <chr> <int> <dbl>
#>  1 communicator           <chr>     0 0    
#>  2 client                 <chr>     0 0    
#>  3 selected_type          <chr>     0 0    
#>  4 comp_amt               <dbl>     0 0    
#>  5 sales_tax              <dbl>     0 0    
#>  6 exp_reimb              <dbl>     0 0    
#>  7 total                  <dbl>     0 0    
#>  8 session                <chr>     0 0    
#>  9 client_year            <chr> 12312 0.630
#> 10 lobbyist_year          <chr> 12312 0.630
#> 11 client_address_clean   <chr> 12312 0.630
#> 12 client_phone           <chr> 12312 0.630
#> 13 client_city_clean      <chr> 12332 0.631
#> 14 client_email           <chr> 12312 0.630
#> 15 client_zip             <chr> 12312 0.630
#> 16 client_state           <chr> 12312 0.630
#> 17 lobbyist_city_clean    <chr> 12355 0.632
#> 18 lobbyist_address_clean <chr> 12335 0.631
#> 19 lobbyist_state         <chr> 12335 0.631
#> 20 lobbyist_zip           <chr> 12335 0.631
#> 21 lobbyist_email         <chr> 12335 0.631
#> 22 dupe_flag              <lgl> 12312 0.630
#> 23 lobbyist_first_name    <chr> 19550 1    
#> 24 lobbyist_last_name     <chr> 19550 1

sample_frac(ctlc)
#> # A tibble: 19,550 x 8
#>    communicator      client              selected_type  comp_amt sales_tax exp_reimb  total session
#>    <chr>             <chr>               <chr>             <dbl>     <dbl>     <dbl>  <dbl> <chr>  
#>  1 Camilliere, Clou… Hartford Distribut… ClientTotal      15000       952.       500 1.65e4 2019-2…
#>  2 Rome Smith & Lutz EPMJR, LLC          Administrative    8000       508        500 9.01e3 2013-2…
#>  3 Gallo & Robinson… Legal Assistance R… ClientTotal     112000.     7112.         0 1.19e5 2013-2…
#>  4 Diane Manning     United Services, I… Legislative       1597.        0          0 1.60e3 2019-2…
#>  5 Nome Associates   CT Food Assoc.      Legislative      90467.     5745.       250 9.65e4 2015-2…
#>  6 Ashley Bogle      Health New England… Legislative       1080.        0          0 1.08e3 2015-2…
#>  7 Jennifer Alexand… Connecticut Coalit… ClientTotal      14804.        0          0 1.48e4 2015-2…
#>  8 The Connecticut … The Carpet and Rug… Administrative       0         0          0 0.     2013-2…
#>  9 Gallo & Robinson… CT Coalition to En… ClientTotal      11000         0       1750 1.27e4 2013-2…
#> 10 Walkovich Associ… Connecticut Allian… Legislative      10000         0        500 1.05e4 2013-2…
#> # … with 19,540 more rows
```

1.  There are 19550 records in the database.
2.  There are 0 duplicate records in the database.
3.  The range and distribution of `year` seems mostly reasonable except
    for a few entries.
4.  Consistency in goegraphic data has been improved with
    `campfin::normal_*()`.
5.  The 4-digit `year` variable has been created with
    `lubridate::year()`.

## Export

``` r
clean_dir <- here("ct", "lobby", "data", "processed","exp")
dir_create(clean_dir)
ctlc_clean %>% 
  select(-c(lobbyist_first_name, lobbyist_last_name)) %>% 
  mutate_if(is.character, str_to_upper) %>% 
  write_csv(
    path = glue("{clean_dir}/ct_lobby_exp.csv"),
    na = ""
  )
```
