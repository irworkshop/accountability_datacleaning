COVID-19-Hit Nursing Home Disease Control History
================
Yanqi Xu
2020-05-01 16:44:31

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Variable Encodings](#variable-encodings)

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
  readxl, # read excel
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
#> [1] "/Users/yanqixu/code/accountability_datacleaning"
```

## Data

We’ll join the dataset of nursing homes with reported cases of COVID-19
patients with CMS’s Nursing Home Compare’s disease control-related
deficiencies. The list of nursing homes is compiled by [The Washington
Post](https://wpinvestigative.github.io/nursing_homes_covid19/index.html# "Wash Post repo")
and downloaded May 1, 2020. The nursing home history dataset was
downloaded from [the Centers for Medicare & Medicaid
Services](https://www.medicare.gov/nursinghomecompare/Data/About.html)
and wrangled by the [Accountability
Project](https://github.com/irworkshop/accountability_datacleaning/blob/master/nursing_home/cms_nursing_health_diary.md#Data "TAP CMS")
dated March 16, 2020.

There’re two columns to join by, the CMS Provider Number and Provider
Name.

``` r
data_dir <- "../nursing_home/data"
nursing <- read_csv(dir_ls(data_dir,regexp = "nursing_infection.*"))
covid <- read_csv((dir_ls(data_dir,regexp = "U.S."))) %>% 
  clean_names() %>% 
  rename(provname = provider_name,
         provnum = cms_provider_number)
```

We can take a glimpse of the COVID-19 dataset.

``` r
sample_frac(covid)
#> # A tibble: 2,747 x 6
#>       x1 provname                                       county   state ownership_type provnum
#>    <dbl> <chr>                                          <chr>    <chr> <chr>          <chr>  
#>  1   834 WESTWOOD HEALTHCARE AND REHABILITATION         Bulloch  GA    For profit     115601 
#>  2  2745 SUMMERSVILLE REGIONAL MEDICAL CENTER           Nicholas WV    Government     515029 
#>  3  2255 FOREST MANOR HCC                               Warren   NJ    For profit     315224 
#>  4   889 PRUITTHEALTH - BROOKHAVEN                      De Kalb  GA    For profit     115313 
#>  5  1833 RIVERVIEW HEALTH & REHAB CENTER                Wayne    MI    For profit     235659 
#>  6  1246 EDMONSON CENTER                                Edmonson KY    For profit     185401 
#>  7  1527 RECUPERATIVE SERVICES UNIT-HEBREW REHAB CENTER Suffolk  MA    Non profit     225759 
#>  8   387 JULIA TEMPLE HEALTHCARE CENTER                 Arapahoe CO    For profit     065322 
#>  9   826 ARCHWAY TRANSITIONAL CARE CENTER               Bibb     GA    Non profit     115728 
#> 10   943 LAUREL PARK AT HENRY MED CTR                   Henry    GA    For profit     115673 
#> # … with 2,737 more rows
covid <- flag_dupes(covid, dplyr::everything())
```

``` r
infected_nursing <- covid %>% 
  left_join(nursing, by = c("provname","provnum","state"))
```

## Variable Encodings

Since not every nursing home with COVID-19 cases had a Emergency
Preparedness dificiency related to disease-control, thus resulting in
columns originally from the CMS table missing. We will create a column
named `def_count` and mark records with these fields missing `0`, and
all others 1, since they mean that there’s indeed one count of
dificiency from previous inspections.

``` r
infected_explore <- infected_nursing %>% 
  # if the number of empty column is 0, there's 1 disease control deficiency, def_boolean = 1
  mutate(def_boolean = case_when(rowSums(is.na(.)) == 0 ~ 1,
                               rowSums(is.na(.)) != 0 ~ 0))
```

``` r
# generate a raw count `def_count` of the def_boolean column
infected_table <- infected_explore %>% 
  group_by(provnum) %>% 
  summarize(def_count = sum(def_boolean))
# join the count back to explore so that we have all the information 
infected_table <- infected_table %>% 
  left_join(covid, by = "provnum") %>% 
  select(-x1)
```

We can see that COVID-19-Impacted nursing homes with most with the most
previous disease control dificiencies are overwhelmingly for-profit.

``` r
top20 <- infected_table %>% 
  arrange(desc(def_count)) %>% 
  head(20)

top20$provnum <- reorder(top20$provnum, top20$def_count)
top20$provname <- reorder(top20$provname, top20$def_count)

top20 %>% 
  ggplot(aes(x = provname,y = def_count,fill = ownership_type)) +
  geom_col() +
  scale_x_discrete(labels =  wrap_format(8))+
  scale_y_continuous()+
  scale_fill_brewer(palette = "Dark2") + 
  labs(
    title = "COVID-19-Impacted Nursing Homes'with Most Previous Disease Control Deficiencies",
    caption = "Source: CMS, The Washington Post",
    x = "Nursing Home Name",
    y = "Total disease-control-related deficiencies"
  ) +
  theme_bw()
```

![](../plots/infected%20vis-1.png)<!-- --> \#\#\# Group by Owners The
ownership data is obtained from
[CMS](https://www.medicare.gov/nursinghomecompare/Data/About.html) and
wrangled by a staff member of the Investigative Reporting Workshop. The
data diary can be accessed
[here](https://github.com/irworkshop/accountability_datacleaning/blob/master/nursing_home/docs/cms_nursing_diary.md#Data).

Then we can join it to the joined table of COVID-19-impacted nursing
homes’ history of disease-control related deficiencies.

``` r
owner <- read_csv(dir_ls(data_dir, regexp = "owner")) 

owner <- owner %>% 
  select(provname, provnum,owner_name,owner_type,owner_percentage_clean, role_desc,association_date_clean)

infected_owner <- infected_explore %>% left_join(owner, by = c("provnum", "provname"))
```

Note that this table contains all owner information. We can group by
owners this time and see whose nursing homes have the most
disease-related deficiencies while having COVID-19 cases. Note that here
as long as the owner has a share in the nursing home facility, we’ll
count as once. This table doesn’t take account of Before we make the
join, we need to make sure that each owner is associated with each
nursing home once.

``` r
owner_dedupe <- owner %>% flag_dupes(c(owner_name, provnum), .both=F) %>% filter(!dupe_flag)

infected_owner_dedupe <- infected_explore %>% left_join(owner_dedupe, by = c("provnum", "provname"))

infected_owner_table <- infected_owner_dedupe %>% 
  group_by(owner_name) %>% 
  summarize(def_count_by_owner = sum(def_boolean)) %>% 
  arrange(desc(def_count_by_owner)) %>% 
  left_join(infected_owner_dedupe, by= "owner_name") %>% 
  left_join(infected_table, by = names(infected_table) %>% setdiff("def_count")) %>% 
  rename(nursing_def_count = def_count)

infected_owner_dedupe %>% 
  group_by(owner_name) %>% 
  summarize(def_count_by_owner = sum(def_boolean)) %>% 
  arrange(desc(def_count_by_owner)) %>% 
          head(20) %>% 
    ggplot(aes(x = reorder(owner_name,def_count_by_owner),y = def_count_by_owner)) +
  geom_col(fill = "#66c2a5") +
  scale_x_discrete(labels =  wrap_format(8))+
  scale_y_continuous()+
  labs(
    title = "COVID-19-Impacted Nursing Homes with Most Previous Disease Control Deficiencies by Owners",
    caption = "Source: CMS, The Washington Post",
    x = "Owner Name",
    y = "Total number of disease-control-related deficiencies at owned nursing homes"
  ) +
  theme_bw()
```

![](../plots/explore%20owner-1.png)<!-- -->

### Export

There’re several data products from the above joining and analysis.

``` r
# Set up processed directory
proc_dir <- dir_create(path(data_dir,"processed"))
```

1.  Table 1: Table of all COVID-19-impacted nursing homes with one added
    column counting total numbers of disease control dificiencies

<!-- end list -->

``` r
glimpse(infected_table %>% sample_frac())
#> Rows: 2,747
#> Columns: 6
#> $ provnum        <chr> "315320", "115628", "395628", "115711", "075201", "055856", "335757", "10…
#> $ def_count      <dbl> 2, 0, 1, 0, 2, 1, 0, 4, 3, 3, 2, 2, 1, 3, 2, 1, 0, 3, 1, 0, 4, 3, 4, 3, 1…
#> $ provname       <chr> "COMPLETE CARE AT HOLIDAY CITY", "PRUITTHEALTH - PALMYRA", "RENAISSANCE H…
#> $ county         <chr> "Ocean", "Dougherty", "Philadelphia", "Decatur", "New Haven", "Los Angele…
#> $ state          <chr> "NJ", "GA", "PA", "GA", "CT", "CA", "NY", "FL", "PA", "CA", "MA", "MA", "…
#> $ ownership_type <chr> "For profit", "For profit", "For profit", "Government", "For profit", "Fo…
infected_table %>% write_csv(path = path(proc_dir,"infected_counts.csv"), na = "")
```

2.  Table 2: Table of all COVID-19-impacted nursing homes and each of
    their disease-control related deficiencies detail table.

<!-- end list -->

``` r
glimpse(infected_table %>% sample_frac())
#> Rows: 2,747
#> Columns: 6
#> $ provnum        <chr> "115002", "225272", "225505", "555443", "235726", "555165", "185194", "07…
#> $ def_count      <dbl> 1, 4, 1, 1, 0, 1, 0, 1, 1, 0, 0, 3, 1, 1, 1, 2, 0, 2, 2, 2, 0, 1, 2, 1, 3…
#> $ provname       <chr> "A.G. RHODES HOME WESLEY WOODS", "BEAR HILL HEALTHCARE AND REHABILITATION…
#> $ county         <chr> "De Kalb", "Middlesex", "Essex", "San Bernardino", "Oakland", "Los Angele…
#> $ state          <chr> "GA", "MA", "MA", "CA", "MI", "CA", "KY", "CT", "NY", "MA", "DC", "CA", "…
#> $ ownership_type <chr> "Non profit", "For profit", "For profit", "For profit", "For profit", "Fo…
infected_explore %>% write_csv(path = path(proc_dir,"infected_details.csv"), na = "")
```

3.  Table 3: This is essentially table 2, with additional owner
    information, types, first\_association date etc. Note that if a
    nursing home has one deficiency but multiple owner rows, it will
    show up multiple times.

<!-- end list -->

``` r
glimpse(infected_owner %>% sample_frac())
#> Rows: 48,909
#> Columns: 32
#> $ x1                     <dbl> 1217, 1209, 726, 1191, 2292, 1915, 1695, 574, 1659, 591, 1994, 57…
#> $ provname               <chr> "ST JAMES WELLNESS REHAB VILLAS", "MEMORIAL CARE CENTER", "UNITY …
#> $ county                 <chr> "Will", "St. Clair", "Miami-Dade", "Macon", "Washoe", "Durham", "…
#> $ state                  <chr> "IL", "IL", "FL", "IL", "NV", "NC", "MD", "DC", "MD", "DE", "NJ",…
#> $ ownership_type         <chr> "For profit", "For profit", "For profit", "For profit", "For prof…
#> $ provnum                <chr> "145611", "145102", "105510", "145422", "295043", "345551", "2153…
#> $ address                <chr> "1251 EAST RICHTON ROAD", "4315 MEMORIAL DRIVE", "1404 NW 22ND ST…
#> $ city_raw               <chr> "CRETE", "BELLEVILLE", "MIAMI", "DECATUR", "RENO", NA, "SALISBURY…
#> $ zip                    <dbl> 60417, 62226, 33142, 62521, 89509, NA, 21801, 20005, 20895, 19805…
#> $ survey_date_output     <date> 2018-02-01, 2016-10-27, 2018-02-02, 2017-08-24, 2017-09-06, NA, …
#> $ surveytype             <chr> "HEALTH", "HEALTH", "HEALTH", "HEALTH", "HEALTH", NA, "HEALTH", "…
#> $ defpref                <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, NA, FALSE, FALSE, FALSE, FALSE…
#> $ category               <chr> "ENVIRONMENTAL DEFICIENCIES", "ENVIRONMENTAL DEFICIENCIES", "ENVI…
#> $ tag                    <chr> "0880", "0441", "0880", "0441", "0441", NA, "0441", "0880", "0441…
#> $ tag_desc               <chr> "PROVIDE AND IMPLEMENT AN INFECTION PREVENTION AND CONTROL PROGRA…
#> $ scope                  <chr> "D", "E", "E", "E", "D", NA, "F", "F", "D", "E", NA, "F", "F", "D…
#> $ defstat                <chr> "DEFICIENT, PROVIDER HAS DATE OF CORRECTION", "DEFICIENT, PROVIDE…
#> $ statdate               <date> 2018-02-02, 2016-11-18, 2018-04-02, 2017-09-08, 2017-10-13, NA, …
#> $ cycle                  <dbl> 2, 3, 2, 3, 3, NA, 3, 1, 3, 1, NA, 2, 2, 3, 2, 1, 2, 3, 2, 1, 2, …
#> $ standard               <chr> "Y", "Y", "Y", "Y", "Y", NA, "Y", "Y", "Y", "Y", NA, "Y", "Y", "Y…
#> $ complaint              <chr> "N", "N", "N", "N", "N", NA, "N", "N", "Y", "Y", NA, "N", "N", "N…
#> $ filedate               <date> 2020-02-01, 2020-02-01, 2020-02-01, 2020-02-01, 2020-02-01, NA, …
#> $ address_norm           <chr> "1251 E RICHTON RD", "4315 MEMORIAL DR", "1404 NW 22 ND ST", "179…
#> $ zip5                   <dbl> 60417, 62226, 33142, 62521, 89509, NA, 21801, 20005, 20895, 19805…
#> $ city_clean             <chr> "CRETE", "BELLEVILLE", "MIAMI", "DECATUR", "RENO", NA, "SALISBURY…
#> $ year                   <dbl> 2018, 2016, 2018, 2017, 2017, NA, 2016, 2019, 2017, 2019, NA, 201…
#> $ def_boolean            <dbl> 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,…
#> $ owner_name             <chr> "MIRETZKY, STEVEN", "MCMANUS, MICHAEL", "STEPHEN ROSENBERG 2009 D…
#> $ owner_type             <chr> "INDIVIDUAL", "INDIVIDUAL", "ORGANIZATION", "INDIVIDUAL", "INDIVI…
#> $ owner_percentage_clean <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ role_desc              <chr> "DIRECTOR", "MANAGING EMPLOYEE", "5% OR GREATER INDIRECT OWNERSHI…
#> $ association_date_clean <date> 2014-04-01, 2012-05-21, 2012-12-31, 2014-01-01, 2018-08-10, 2008…

infected_owner %>% write_csv(path = path(proc_dir,"infected_owners.csv"), na = "")
```
