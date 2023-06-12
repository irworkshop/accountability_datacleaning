Alabama Lobbyists
================
First Last
2020-01-15 17:07:56
By Kiernan Nicholls

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Import](#import)
  - [Explore](#explore)
  - [Wrangle](#wrangle)
  - [Normalize](#normalize)
  - [Export](#export)

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
  pdftools, # process pdf text
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
#> [1] "/home/kiernan/R/accountability_datacleaning/R_campfin"
```

## Data

Data is obtained from the [Alabama Ethics Commission
(AEC)](http://ethics.alabama.gov/).

> The Alabama Ethics Commission was created by the Alabama Legislature
> in 1973 by Act No. 1056. The mission of this Commission is to ensure
> that public officials are independent and impartial; that decisions
> and policies are made in the proper governmental channels; that public
> office is not used for private gain; and, most importantly, that there
> is public confidence in the integrity of government.

On the [lobbyist section](http://ethics.alabama.gov/lobbyists.aspx) of
the AEC website, the requirments for lobbyist registration are given.

> Registration as a Lobbyist is now required if your duties include
> promoting or attempting to influence the awarding of a grant or
> contract with any department or agency of the Executive, Legislative
> or Judicial Branch of state government.

Per
[Section 36-25-1(20)](http://ethics.alabama.gov/docs/WhatisLobbyingREVISEDDec2012.pdf):

> Lobby or Lobbying is: “The practice of promoting, opposing, or in any
> manner influencing or attempting to influence the introduction,
> defeat, or enactment of legislation before any legislative body;
> opposing or in any manner influencing the executive approval, veto, or
> amendment of legislation; or the practice of promoting, opposing, or
> in any manner influencing or attempting to influence the enactment,
> promulgation, modification, or deletion of regulations before any
> regulatory body. The term does not include providing public testimony
> before a legislative body or regulatory body or any committee
> thereof.”

## Import

While the AEC *does* provide two Excel files listing [registered
lobbyists](https://ethics-form.alabama.gov/entity/FileUpload2015/RegisteredLobbyist/WebDataForExcel_2010.aspx)
and [registered principal
clients](https://ethics-form.alabama.gov/entity/FileUpload2015/RegisteredLobbyist/rptPrincipalsListing_Excel.aspx)
for 2020, these two files do not show the relationship between each
lobbyist and those entites for which they lobby.

Instead, that relationship is documented on annual filings for each
individual lobbyist. These reports are given as PDF documents and can be
searched from the [AEC search
page](http://ethics.alabama.gov/search/PublicEmployeeSearch.aspx).

The PDF statements can be then be viewed one at a time. Each yearly PDF
has a unique lobbyist ID (`lid`), which can be passed to an
`httr::GET()` request to save the PDF.

``` r
GET(
  url = "http://ethics.alabama.gov/search/ViewReports.aspx",
  write_disk(path, overwrite = TRUE),
  query = list(
    lid = 21,
    rpt = "rptLobbyistRegistration"
  )
)
```

### Download

Opening random PDF’s from 2008 to 2020, it seems as though their are
valid lobbyist ID’s from 1 to 11,000 (with roughly 25% inbetween leading
to “empty” files without any information).

This takes **hours**, but we can loop through each ID and write the file
to disk.

``` r
raw_dir <- dir_create(here("al", "lobby", "data", "raw"))
```

``` r
n <- 11100
start_time <- Sys.time()
if (length(dir_ls(raw_dir)) < 5000) {
  for (i in seq(min, n)) {
    path <- glue("{raw_dir}/reg_{str_pad(i, nchar(n), pad = '0')}.pdf")
    loop_start <- Sys.time()
    # make get request
    GET(
      url = "http://ethics.alabama.gov/search/ViewReports.aspx",
      write_disk(path, overwrite = TRUE),
      query = list(
        lid = i,
        rpt = "rptLobbyistRegistration"
      )
    )
    # delete if empty pdf
    if (file_size(path) == 55714) {
      file_delete(path)
      deleted <- TRUE
    } else {
      deleted <- FALSE
    }
    # track progress
    loop_time <- Sys.time() - loop_start
    loop_time <- paste(round(loop_time, 2), attributes(loop_time)$units)
    total_time <- Sys.time() - start_time
    total_time <- paste(round(total_time, 2), attributes(total_time)$units)
    message(glue(
      "{i} done in {str_pad(loop_time, 2)}",
      "running for {str_pad(total_time, 2)}",
      "({percent(i/n)})",
      deleted,
      .sep = " / "
    ))
    # rand sleep
    Sys.sleep(time = runif(n = 1, min = 0, max = 3))
  }
}
```

### Read

Once we have downloaded all 7,500 PDF files to the same directory, we
can write some generic functions that use the `pdftools::pdf_text()` and
`stringr::str_extract()` functions to scan the embeded text of each page
and extract the bits of information we want.

The overall technic is to create 1 data rame row with lobbyist
information per document and an individual row per principal client. We
can then combine those two data frames to produce a single row per
lobbyist-principal relationship.

This `str_get()` function is just a simple way to look for the line
containing the information we want (e.g., Lobbyist Name) and extract the
relevant text from that line using regular expressions. Each page has
the exact same layout, so we can then use this function to get each bit
of text from every page.

``` r
# extract first from which contains
str_get <- function(string, pattern, n = 1) {
  got <- str_trim(str_extract(str_subset(string, pattern), pattern)[[n]])
  if (nchar(got) == 0) {
    got <- NA_character_
  }
  return(got)
}
```

This `frame_lob()` function uses `str_get()` to locate each piece of
information and turn it into the column of a single row tibble.

``` r
frame_lob <- function(x) {
    # find email line index
    which_email <- str_which(x, "E-Mail")
    # check for no address after email
    if (str_detect(x[which_email + 1], "Address", negate = TRUE)) {
      # collapse two lines
      x[which_email] <- str_c(x[which_email], x[which_email + 1], collapse = "")
      # remove overflow line
      x <- x[-(which_email + 1)]
    }
    # extract content from lines of text
    tibble(
      lob_year = as.integer(str_get(x, "(?<=Year:)(.*)")),
      lob_date = mdy(str_get(x[str_which(x, "I certify that") + 1], "(?<=Date:)(.*)")),
      lob_name = str_get(x, "(?<=Lobbyist:)(.*)(?=Business Phone:)"),
      lob_phone = str_get(x, "(?<=Business Phone:)(.*)"),
      lob_addr1 = str_get(x, "(?<=Business)(.*)(?=E-Mail)"),
      lob_addr2 = str_get(x, "(?<=Address:)(.*)"),
      lob_city = str_get(x, "(?<=City/State/Zip:)(.*)"),
      lob_public = str_get(x, "(?<=Public Employee\\?)(.*)"),
      # combine all lines between these
      lob_subjects = str_c(x[seq(
        str_which(x, "Categories of legislation") + 1,
        str_which(x, "List Business Entities") - 1
      )], collapse = " "
      )
    )
  }
```

This `frame_pri()` function does a similar thing for each principal
section of the document.

``` r
# extract content from lines of text
frame_pri <- function(section) {
    a <- section$text
    tibble(
      pri_name = str_get(a, "(?<=Principal Name:\\s)(.*)(?=\\sPhone)"),
      pri_phone = str_get(a, "(?<=Phone:)(.*)"),
      pri_addr = str_get(a, "(?<=Address:)(.*)"),
      pri_start = mdy(str_get(a, "(?<=Effective Date:)(.*)(?=\\s)")),
      pri_end_date = mdy(str_get(a, "(?<=Termination Date:)(.*)")),
      pri_sign = str_get(a, "(?<=Principal:)(.*)"),
      pri_behalf = a[str_which(a, "If your activity") + 1]
    )
  }
```

The final `frame_pdf()` function reads the PDF document and
appropriately formats the text before calling `frame_lob()` and
`frame_pri()` to return a single combined data frame.

``` r
frame_pdf <- function(file) {
  id <- str_extract(file, "\\d+")

  # read text of single file
  text <-
    # read lines of text
    pdf_text(pdf = file) %>%
    # concat pages of text
    str_c(collapse = "\n") %>%
    # split by newline
    str_split(pattern = "\n") %>%
    pluck(1) %>%
    # reduce whitespace
    str_squish() %>%
    # remove header, footer, empty
    str_subset("^Page \\d+ of \\d+$", negate = TRUE) %>%
    str_subset("^\\d{1,2}/\\d{1,2}/\\d{4}$", negate = TRUE) %>%
    str_subset("^$", negate = TRUE)
  
  lob <-
    frame_lob(x = text) %>%
    mutate(id) %>%
    select(id, everything())

  # keep only pri lines
  pri <- text[seq(
    str_which(text, "List Business Entities") + 1,
    str_which(text, "I certify that") - 1
  )]

  pri <- pri %>%
    enframe(name = "line", value = "text") %>%
    # count pri section
    mutate(section = cumsum(str_detect(text, "Principal Name:"))) %>%
    # split into list
    group_split(section)
  
  # frame every section
  pri <- map_df(pri, frame_pri)

  # rep lob by col bind
  as_tibble(cbind(lob, pri))
}
```

We can then apply this function to every PDF downloaded and combine the
results of each into a single giant data frame.

``` r
allr <- map_df(
  .x = dir_ls(raw_dir),
  .f = frame_pdf
)
```

## Explore

``` r
head(allr)
#> # A tibble: 6 x 17
#>   id    lob_year lob_date   lob_name lob_phone lob_addr1 lob_addr2 lob_city lob_public lob_subjects
#>   <chr>    <int> <date>     <chr>    <chr>     <chr>     <chr>     <chr>    <chr>      <chr>       
#> 1 00004     2008 NA         ADAMS, … 334-265-… Post Off… 465 Sout… Montgom… No         ZZZ Child A…
#> 2 00004     2008 NA         ADAMS, … 334-265-… Post Off… 465 Sout… Montgom… No         ZZZ Child A…
#> 3 00004     2008 NA         ADAMS, … 334-265-… Post Off… 465 Sout… Montgom… No         ZZZ Child A…
#> 4 00004     2008 NA         ADAMS, … 334-265-… Post Off… 465 Sout… Montgom… No         ZZZ Child A…
#> 5 00004     2008 NA         ADAMS, … 334-265-… Post Off… 465 Sout… Montgom… No         ZZZ Child A…
#> 6 00005     2008 2008-12-09 ADAMS, … 334-265-… 400 S. U… Suite 23… Montgom… No         ZZZ Budgeta…
#> # … with 7 more variables: pri_name <chr>, pri_phone <chr>, pri_addr <chr>, pri_start <date>,
#> #   pri_end_date <date>, pri_sign <chr>, pri_behalf <chr>
tail(allr)
#> # A tibble: 6 x 17
#>   id    lob_year lob_date   lob_name lob_phone lob_addr1 lob_addr2 lob_city lob_public lob_subjects
#>   <chr>    <int> <date>     <chr>    <chr>     <chr>     <chr>     <chr>    <chr>      <chr>       
#> 1 11077     2020 2020-01-01 HOSP, A… 334-263-… 7265 Hal… <NA>      Montgom… No         General Bus…
#> 2 11079     2020 2020-01-06 SAUNDER… 334-265-… 555 Alab… <NA>      Montgom… No         Trucking In…
#> 3 11081     2020 2020-01-02 HOBBIE,… 770-389-… 2155 Hig… <NA>      McDonou… No         Law Enforce…
#> 4 11092     2020 2020-01-06 WALKER,… 334-264-… 445 Dext… Suite 40… Montgom… No         Payday Lend…
#> 5 11098     2020 2020-01-02 VUCOVIC… 334-356-… 4266 Lom… <NA>      Montgom… No         Education   
#> 6 11100     2020 2020-01-02 deGRAFF… 334-271-… 4156 Car… <NA>      Montgom… No         Nursing Hom…
#> # … with 7 more variables: pri_name <chr>, pri_phone <chr>, pri_addr <chr>, pri_start <date>,
#> #   pri_end_date <date>, pri_sign <chr>, pri_behalf <chr>
glimpse(sample_frac(allr))
#> Observations: 16,982
#> Variables: 17
#> $ id           <chr> "03747", "08080", "10144", "04608", "02643", "08174", "06735", "09070", "10…
#> $ lob_year     <int> 2010, 2016, 2019, 2011, 2009, 2016, 2014, 2017, 2019, 2009, 2011, 2014, 201…
#> $ lob_date     <date> 2010-01-11, 2016-01-21, 2019-01-29, 2011-01-28, 2009-01-30, 2016-01-28, 20…
#> $ lob_name     <chr> "WEEKS, MIKE", "DEARBORN, GINA", "BRADLEY, STEPHEN E.", "ROWE, CHARLES C.",…
#> $ lob_phone    <chr> "334-263-3407", "334-391-4518", "205-933-6676", "334-244-2187", "334-262-25…
#> $ lob_addr1    <chr> "Post Office Box 56", "217 Country Club Park", "2101 Highland Avenue, Suite…
#> $ lob_addr2    <chr> NA, "PMB 302", NA, NA, NA, "1819 North 5th Avenue", NA, NA, "Suite 300", NA…
#> $ lob_city     <chr> "Montgomery, AL 36101-0056", "Birmingham, AL 35213", "Birmingham, AL 35205"…
#> $ lob_public   <chr> "No", "No", "No", "No", "No", "No", "No", "No", "No", "No", "No", "No", "No…
#> $ lob_subjects <chr> "Regulations, Worker's Compensation, Vending, Tort Reform, Trade Associatio…
#> $ pri_name     <chr> "Alabama Pawnbrokers Association", "Brewer Attorneys and Counselors obo 3M"…
#> $ pri_phone    <chr> "334-493-4447", "214-653-4000", "815-436-1310", "334-244-2187", "334-834-90…
#> $ pri_addr     <chr> "1907 Highway 84 West , Opp, AL 36467", "1717 Main Street Ste. 5900, Dallas…
#> $ pri_start    <date> 2010-02-01, 2016-01-29, 2019-03-04, 2011-02-02, 2009-01-30, 2016-02-01, 20…
#> $ pri_end_date <date> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, 2012-03-28…
#> $ pri_sign     <chr> "JOE M. MOULTON", "Travis J. Carter", "Darius Holmes", "John D Crawford", "…
#> $ pri_behalf   <chr> "over 25", "corporation", "corporation", "6-10", NA, "public entity", "over…
```

``` r
col_stats(allr, count_na)
#> # A tibble: 17 x 4
#>    col          class      n         p
#>    <chr>        <chr>  <int>     <dbl>
#>  1 id           <chr>      0 0        
#>  2 lob_year     <int>      0 0        
#>  3 lob_date     <date>  1379 0.0812   
#>  4 lob_name     <chr>      0 0        
#>  5 lob_phone    <chr>     20 0.00118  
#>  6 lob_addr1    <chr>      1 0.0000589
#>  7 lob_addr2    <chr>  11873 0.699    
#>  8 lob_city     <chr>      0 0        
#>  9 lob_public   <chr>      0 0        
#> 10 lob_subjects <chr>      0 0        
#> 11 pri_name     <chr>      0 0        
#> 12 pri_phone    <chr>     92 0.00542  
#> 13 pri_addr     <chr>      0 0        
#> 14 pri_start    <date>     2 0.000118 
#> 15 pri_end_date <date> 15231 0.897    
#> 16 pri_sign     <chr>     16 0.000942 
#> 17 pri_behalf   <chr>   3156 0.186
```

``` r
col_stats(allr, n_distinct)
#> # A tibble: 17 x 4
#>    col          class      n        p
#>    <chr>        <chr>  <int>    <dbl>
#>  1 id           <chr>   7588 0.447   
#>  2 lob_year     <int>     13 0.000766
#>  3 lob_date     <date>  1033 0.0608  
#>  4 lob_name     <chr>   2117 0.125   
#>  5 lob_phone    <chr>   1640 0.0966  
#>  6 lob_addr1    <chr>   1706 0.100   
#>  7 lob_addr2    <chr>    494 0.0291  
#>  8 lob_city     <chr>    627 0.0369  
#>  9 lob_public   <chr>      2 0.000118
#> 10 lob_subjects <chr>   3467 0.204   
#> 11 pri_name     <chr>   2794 0.165   
#> 12 pri_phone    <chr>   2981 0.176   
#> 13 pri_addr     <chr>   3538 0.208   
#> 14 pri_start    <date>  1795 0.106   
#> 15 pri_end_date <date>   963 0.0567  
#> 16 pri_sign     <chr>   5602 0.330   
#> 17 pri_behalf   <chr>     20 0.00118
```

``` r
ggplot(data = allr) +
  geom_bar(mapping = aes(x = lob_year))
```

![](../plots/plot_year-1.png)<!-- -->

## Wrangle

Now we can separate some of the lobbyist information into distinct
columns.

``` r
allr <- allr %>%
  mutate_all(str_to_upper) %>%
  separate(
    col = lob_name,
    into = c("lob_last", "lob_first"),
    sep = ",\\s",
    extra = "merge",
    fill = "right"
  ) %>%
  separate(
    col = lob_city,
    into = c("lob_city", "lob_state"),
    sep = ",\\s(?=[:upper:])",
    extra = "merge"
  ) %>%
  mutate_at(
    .vars = vars(lob_state),
    .funs = str_remove,
    pattern = "(.*,\\s)(?=[:upper:])"
  ) %>%
  separate(
    col = lob_state,
    into = c("lob_state", "lob_zip"),
    sep = "\\s(?=\\d+)"
  )
```

    #> # A tibble: 7,588 x 12
    #>    lob_year lob_date lob_last lob_first lob_phone lob_addr1 lob_addr2 lob_city lob_state lob_zip
    #>    <chr>    <chr>    <chr>    <chr>     <chr>     <chr>     <chr>     <chr>    <chr>     <chr>  
    #>  1 2019     2019-01… MATHISON ADRIENNE  251-359-… 5811 JAC… <NA>      ATMORE   AL        36502  
    #>  2 2012     2012-01… ALMEIDA  JEFFREY D 803-546-… 101 EAST… <NA>      LEXINGT… SC        29072  
    #>  3 2012     2012-01… EDWARDS  SUZANNE   334-549-… 1116 GRE… <NA>      MONTGOM… AL        36111  
    #>  4 2013     2013-02… WHISENA… JENNIFER… 205-980-… 2101 PRO… SUITE 150 BIRMING… AL        35242  
    #>  5 2011     2011-01… MILLER   JEFF M.   334-264-… 3 SOUTH … <NA>      MONTGOM… AL        36104  
    #>  6 2008     <NA>     WOOD     JR., JAM… 334-215-… POST OFF… <NA>      MT. MEI… AL        36057  
    #>  7 2013     2013-01… FORRIST… VERNER K… 334-832-… POST OFF… SUITE 90… MONTGOM… AL        36101-…
    #>  8 2020     2020-01… HUTCHENS C. WAYNE  205-988-… 1884 DAT… ROOM 116  BIRMING… AL        35244  
    #>  9 2018     2018-01… FLETCHER JAMES B.  334-272-… 4264 LOM… <NA>      MONTGOM… AL        36106  
    #> 10 2009     2009-01… BARGANI… JON D.    334-272-… 8112 HEN… <NA>      MONTGOM… AL        36117  
    #> # … with 7,578 more rows, and 2 more variables: lob_public <chr>, lob_subjects <chr>

And we can do the same for principal clients.

``` r
allr <- allr %>%
  separate(
    col = pri_addr,
    into = c(
      glue("pri_addr{1:10}"),
      "pri_city",
      "pri_state"
    ),
    sep = ",\\s+",
    extra = "merge",
    fill = "left"
  ) %>%
  unite(
    starts_with("pri_addr"),
    col = pri_addr,
    sep = ", ",
    na.rm = TRUE
  ) %>%
  separate(
    col = pri_state,
    into = c("pri_state", "pri_zip"),
    sep = "\\s(?=\\d+)",
    extra = "merge",
    fill = "right"
  ) %>%
  mutate_if(
    .predicate = is_character,
    .funs = str_trim
  ) %>%
  na_if("")
```

    #> # A tibble: 14,290 x 10
    #>    pri_name pri_phone pri_addr pri_city pri_state pri_zip pri_start pri_end_date pri_sign
    #>    <chr>    <chr>     <chr>    <chr>    <chr>     <chr>   <chr>     <chr>        <chr>   
    #>  1 COSBY C… 334-412-… P. O. B… SELMA    AL        36702   2018-01-… <NA>         WILLIAM…
    #>  2 SCHOOL … 334-262-… 400 S. … MONTGOM… AL        36104   2008-01-… <NA>         SUSAN L…
    #>  3 COMMUNI… 615-651-… 424 CHU… NASHVIL… TN        37219   2015-01-… <NA>         DAVID S…
    #>  4 GLOBAL … 703-955-… 12021 S… RESTON   VA        20190   2014-12-… <NA>         DASVID …
    #>  5 ALABAMA… 256-538-… 180 JAK… STEELE   AL        35987   2013-02-… <NA>         VALLEY …
    #>  6 BLUE CR… 205-220-… 450 RIV… BIRMING… AL        35244   2012-02-… <NA>         J. ROBI…
    #>  7 SYNCORA… 212-478-… 1221 AV… NEW YORK NY        10020   2008-08-… <NA>         JOHN WI…
    #>  8 ALABAMA… 334-260-… P.O. BO… MONTGOM… AL        36124   2018-01-… <NA>         LARRY V…
    #>  9 BAYER H… 914-333-… C/O SAN… TARRYTO… NY        10591   2010-01-… <NA>         SANDRA …
    #> 10 CHILDRE… 334-242-… 401 ADA… MONTGOM… AL        36104   2008-01-… <NA>         CHRISTY…
    #> # … with 14,280 more rows, and 1 more variable: pri_behalf <chr>

## Normalize

### Address

``` r
allr <- allr %>% 
  # combine street addr
  unite(
    starts_with("lob_addr"),
    col = lob_addr_full,
    sep = " ",
    remove = FALSE,
    na.rm = TRUE
  ) %>% 
  # normalize combined addr
  mutate(
    lob_addr_norm = normal_address(
      address = lob_addr_full,
      abbs = usps_street,
      na_rep = TRUE
    )
  ) %>% 
  select(-lob_addr_full)
```

``` r
allr <- allr %>% 
  mutate(
    pri_addr_norm = normal_address(
      address = pri_addr,
      abbs = usps_street,
      na_rep = TRUE
    )
  )
```

``` r
allr %>% 
  select(contains("lob_addr")) %>% 
  distinct() %>% 
  sample_frac()
#> # A tibble: 1,882 x 3
#>    lob_addr1                         lob_addr2 lob_addr_norm                     
#>    <chr>                             <chr>     <chr>                             
#>  1 1079 NORMANDY TRACE ROAD          <NA>      1079 NORMANDY TRACE ROAD          
#>  2 531 HERRON STREET                 <NA>      531 HERRON STREET                 
#>  3 2100 3RD AVENUE NORTH, SUITE 1100 <NA>      2100 3RD AVENUE NORTH SUITE 1100  
#>  4 20700 CIVIC CENTER DRIVE          SUITE 200 20700 CIVIC CENTER DRIVE SUITE 200
#>  5 P.O. BOX 76                       <NA>      PO BOX 76                         
#>  6 173 MEDICAL CENTER DRIVE          <NA>      173 MEDICAL CENTER DRIVE          
#>  7 202 BUILDING A, FIELDCREST        <NA>      202 BUILDING A FIELDCREST         
#>  8 1166 GINGER DR                    <NA>      1166 GINGER DRIVE                 
#>  9 770 WASHINGTON AVE.               SUITE 180 770 WASHINGTON AVENUE SUITE 180   
#> 10 600 CLAY STREET                   <NA>      600 CLAY STREET                   
#> # … with 1,872 more rows
```

### ZIP

``` r
allr <- mutate_at(
  .tbl = allr,
  .vars = vars(ends_with("_zip")),
  .funs = list(norm = normal_zip),
  na_rep = TRUE
)
```

``` r
progress_table(
  allr$lob_zip,
  allr$lob_zip_norm,
  allr$pri_zip,
  allr$pri_zip_norm,
  compare = valid_zip
)
#> # A tibble: 4 x 6
#>   stage        prop_in n_distinct  prop_na n_out n_diff
#>   <chr>          <dbl>      <dbl>    <dbl> <dbl>  <dbl>
#> 1 lob_zip        0.893        571 0         1824    129
#> 2 lob_zip_norm   1.00         461 0            6      3
#> 3 pri_zip        0.896       1160 0.000589  1773    187
#> 4 pri_zip_norm   0.999       1022 0.000648    22      8
```

### State

``` r
allr <- mutate_at(
  .tbl = allr,
  .vars = vars(ends_with("_state")),
  .funs = list(norm = normal_state),
  na_rep = TRUE
)
```

``` r
progress_table(
  allr$lob_state,
  allr$lob_state_norm,
  allr$pri_state,
  allr$pri_state_norm,
  compare = valid_state
)
#> # A tibble: 4 x 6
#>   stage          prop_in n_distinct prop_na n_out n_diff
#>   <chr>            <dbl>      <dbl>   <dbl> <dbl>  <dbl>
#> 1 lob_state        1             33       0     0      0
#> 2 lob_state_norm   1             33       0     0      0
#> 3 pri_state        0.999         52       0    13     11
#> 4 pri_state_norm   1.00          46       0     5      5
```

### City

``` r
allr <- allr %>% 
  mutate_at(
    .vars = vars(ends_with("_city")),
    .funs = list(norm = normal_city),
    abbs = usps_city,
    states = c("AL", "ALA", "ALABAMA", "DC"),
    na = invalid_city,
    na_rep = TRUE
  )
```

``` r
allr <- allr %>% 
  left_join(
    y = zipcodes,
    by = c(
      "lob_state_norm" = "state",
      "lob_zip_norm" = "zip"
    )
  ) %>% 
  rename(lob_city_match = city) %>% 
  mutate(
    lob_match_abb = is_abbrev(lob_city_norm, lob_city_match),
    lob_match_dist = str_dist(lob_city_norm, lob_city_match),
    lob_city_swap = if_else(
      condition = lob_match_abb | lob_match_dist == 1,
      true = lob_city_match,
      false = lob_city_norm
    )
  ) %>% 
  select(
    -lob_city_match,
    -lob_match_abb,
    -lob_match_dist
  )
```

``` r
allr <- allr %>% 
  left_join(
    y = zipcodes,
    by = c(
      "pri_state_norm" = "state",
      "pri_zip_norm" = "zip"
    )
  ) %>% 
  rename(pri_city_match = city) %>% 
  mutate(
    pri_match_abb = is_abbrev(pri_city_norm, pri_city_match),
    pri_match_dist = str_dist(pri_city_norm, pri_city_match),
    pri_city_swap = if_else(
      condition = pri_match_abb | pri_match_dist == 1,
      true = pri_city_match,
      false = pri_city_norm
    )
  ) %>% 
  select(
    -pri_city_match,
    -pri_match_abb,
    -pri_match_dist
  )
```

``` r
progress_table(
  allr$lob_city,
  allr$lob_city_norm,
  allr$lob_city_swap,
  allr$pri_city,
  allr$pri_city_norm,
  allr$pri_city_swap,
  compare = valid_city
)
#> # A tibble: 6 x 6
#>   stage         prop_in n_distinct   prop_na n_out n_diff
#>   <chr>           <dbl>      <dbl>     <dbl> <dbl>  <dbl>
#> 1 lob_city        0.984        269 0           264     24
#> 2 lob_city_norm   0.985        266 0           255     19
#> 3 lob_city_swap   0.987        261 0.000530    217     12
#> 4 pri_city        0.971        598 0.0000589   498     84
#> 5 pri_city_norm   0.979        584 0.0000589   355     60
#> 6 pri_city_swap   0.983        559 0.00253     284     37
```

## Export

``` r
proc_dir <- dir_create(here("al", "lobby", "data", "processed"))
```

``` r
allr %>% 
  select(
    -lob_city_norm,
    -pri_city_norm
  ) %>% 
  rename(
    lob_city_norm = lob_city_swap,
    pri_city_norm = pri_city_swap,
  ) %>% 
  write_csv(
    path = glue("{proc_dir}/al_lobbyists.csv"),
    na = ""
  )
```
