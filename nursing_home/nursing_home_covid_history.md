COVID-19-Hit Nursing Home Disease Control History
================
Yanqi Xu
2020-05-01 19:52:39

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

top20 %>% kable()
```

| provnum | def\_count | provname                                           | county      | state | ownership\_type |
| :------ | ---------: | :------------------------------------------------- | :---------- | :---- | :-------------- |
| 056078  |          7 | LAKEVIEW TERRACE                                   | Los Angeles | CA    | For profit      |
| 145969  |          7 | APERION CARE FOREST PARK                           | Cook        | IL    | For profit      |
| 555397  |          7 | COUNTRY VILLA REHABILITATION CENTER                | Los Angeles | CA    | For profit      |
| 056294  |          6 | SAN JOAQUIN NURSING CENTER AND REHABILITATION CENT | Kern        | CA    | For profit      |
| 056334  |          6 | BEACHWOOD POST-ACUTE & REHAB                       | Los Angeles | CA    | For profit      |
| 145334  |          6 | LANDMARK OF DES PLAINES REHAB                      | Cook        | IL    | For profit      |
| 145424  |          6 | LANDMARK OF RICHTON PARK REHAB & NSG CTR           | Cook        | IL    | For profit      |
| 145453  |          6 | ALDEN TERRACE OF MCHENRY REHAB                     | Mc Henry    | IL    | For profit      |
| 145555  |          6 | EDWARDSVILLE NSG & REHAB CTR                       | Madison     | IL    | For profit      |
| 145881  |          6 | UPTOWN HEALTH CENTER                               | Cook        | IL    | For profit      |
| 365933  |          6 | BUCKEYE TERRACE REHABILITATION AND NURSING CENTER  | Franklin    | OH    | For profit      |
| 055409  |          5 | COMMUNITY CARE AND REHABILITATION CENTER           | Riverside   | CA    | For profit      |
| 055430  |          5 | WHITTIER HILLS HEALTH CARE CTR                     | Los Angeles | CA    | For profit      |
| 055750  |          5 | AMBERWOOD GARDENS                                  | Santa Clara | CA    | For profit      |
| 056129  |          5 | BURBANK HEALTHCARE & REHAB                         | Los Angeles | CA    | For profit      |
| 056380  |          5 | COUNTRY VILLA LOS FELIZ NURSING CENTER             | Los Angeles | CA    | For profit      |
| 065222  |          5 | BOULDER MANOR                                      | Boulder     | CO    | For profit      |
| 145208  |          5 | BRIDGEVIEW HEALTH CARE CENTER                      | Cook        | IL    | For profit      |
| 145662  |          5 | ELEVATE CARE NILES                                 | Cook        | IL    | For profit      |
| 145963  |          5 | ALDEN ESTATES OF ORLAND PARK                       | Cook        | IL    | For profit      |

### Group by Owners

The ownership data is obtained from
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
  scale_x_discrete()+
  scale_y_continuous()+
  theme(axis.text= element_text(size=8)) +
  labs(
    title = "COVID-19-Impacted Nursing Homes with Most Previous Disease Control Deficiencies by Owners",
    caption = "Source: CMS, The Washington Post",
    x = "Owner Name",
    y = "Total number of disease-control-related deficiencies at owned nursing homes"
  ) +
  coord_flip() +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0))
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
infected_table %>% sample_frac()
#> # A tibble: 2,747 x 6
#>    provnum def_count provname                                    county        state ownership_type
#>    <chr>       <dbl> <chr>                                       <chr>         <chr> <chr>         
#>  1 315320          2 COMPLETE CARE AT HOLIDAY CITY               Ocean         NJ    For profit    
#>  2 115628          0 PRUITTHEALTH - PALMYRA                      Dougherty     GA    For profit    
#>  3 395628          1 RENAISSANCE HEALTHCARE & REHABILITATION CE… Philadelphia  PA    For profit    
#>  4 115711          0 MEMORIAL MANOR NURSING HOME                 Decatur       GA    Government    
#>  5 075201          2 REGALCARE AT WEST HAVEN                     New Haven     CT    For profit    
#>  6 055856          1 HIGH VALLEY LODGE                           Los Angeles   CA    For profit    
#>  7 335757          0 HARRIS HILL NURSING FACILITY, L L C         Erie          NY    For profit    
#>  8 105895          4 CONSULATE HEALTH CARE OF ST PETERSBURG      Pinellas      FL    For profit    
#>  9 395015          3 BRIGHTON REHABILITATION AND WELLNESS CENTER Beaver        PA    For profit    
#> 10 555476          3 APPLE VALLEY POST ACUTE CENTER              San Bernardi… CA    For profit    
#> # … with 2,737 more rows
infected_table %>% write_csv(path = path(proc_dir,"infected_counts.csv"), na = "")
```

2.  Table 2: Table of all COVID-19-impacted nursing homes and each of
    their disease-control related deficiencies detail table.

<!-- end list -->

``` r
infected_explore %>% sample_frac()
#> # A tibble: 4,497 x 27
#>       x1 provname county state ownership_type provnum address city_raw   zip survey_date_out…
#>    <dbl> <chr>    <chr>  <chr> <chr>          <chr>   <chr>   <chr>    <dbl> <date>          
#>  1  1892 THE EST… Wright MN    For profit     245336  433 CO… DELANO   55328 2018-08-16      
#>  2   297 CEDAR M… San B… CA    For profit     555494  11970 … YUCAIPA  92399 2018-12-21      
#>  3  1523 MATTAPA… Suffo… MA    For profit     225532  405 RI… MATTAPAN  2126 2019-01-16      
#>  4  1714 MEDILOD… Genes… MI    For profit     235226  11941 … GRAND B… 48439 2019-04-05      
#>  5  1490 ALLIANC… Plymo… MA    Non profit     225259  804 PL… BROCKTON  2301 2016-05-09      
#>  6   570 FOX HIL… Tolla… CT    For profit     075183  <NA>    <NA>        NA NA              
#>  7  2729 WILLOW … Yakima WA    For profit     505367  4007 T… YAKIMA   98908 2018-02-16      
#>  8  1184 TERRACE… Lake   IL    For profit     146159  1615 S… WAUKEGAN 60087 2019-01-30      
#>  9  2506 GLENDOR… Wayne  OH    For profit     366036  <NA>    <NA>        NA NA              
#> 10   839 PLEASAN… Candl… GA    For profit     115411  <NA>    <NA>        NA NA              
#> # … with 4,487 more rows, and 17 more variables: surveytype <chr>, defpref <lgl>, category <chr>,
#> #   tag <chr>, tag_desc <chr>, scope <chr>, defstat <chr>, statdate <date>, cycle <dbl>,
#> #   standard <chr>, complaint <chr>, filedate <date>, address_norm <chr>, zip5 <dbl>,
#> #   city_clean <chr>, year <dbl>, def_boolean <dbl>
infected_explore %>% write_csv(path = path(proc_dir,"infected_details.csv"), na = "")
```

3.  Table 3: This is essentially table 2, with additional owner
    information from the ownership data from CMS, including types,
    first\_association date, and etc. Note that if a nursing home has
    one deficiency but multiple owner rows, it will show up multiple
    times.

<!-- end list -->

``` r
infected_owner %>% sample_frac()
#> # A tibble: 48,909 x 32
#>       x1 provname county state ownership_type provnum address city_raw   zip survey_date_out…
#>    <dbl> <chr>    <chr>  <chr> <chr>          <chr>   <chr>   <chr>    <dbl> <date>          
#>  1   754 HEARTLA… Palm … FL    Non profit     105755  <NA>    <NA>        NA NA              
#>  2   179 PALAZZO… Los A… CA    For profit     056456  5400 F… LOS ANG… 90029 2019-01-25      
#>  3   616 GOLFCRE… Browa… FL    For profit     105009  600 NO… HOLLYWO… 33020 2017-07-13      
#>  4  2406 BUCKEYE… Frank… OH    For profit     365933  140 N … WESTERV… 43081 2018-07-23      
#>  5   629 SPRINGT… Browa… FL    For profit     105686  <NA>    <NA>        NA NA              
#>  6   767 STRATFO… Palm … FL    For profit     105851  6343 V… BOCA RA… 33433 2019-06-27      
#>  7  1300 ST ANTH… Jeffe… LA    For profit     195570  6001 A… METAIRIE 70003 2018-04-12      
#>  8   638 GOVERNO… Clay   FL    For profit     105663  803 OA… GREEN C… 32043 2017-03-02      
#>  9  1261 SIGNATU… Jacks… KY    For profit     185249  96 HIG… ANNVILLE 40402 2019-09-25      
#> 10  1589 HERITAG… Balti… MD    For profit     215135  7232 G… DUNDALK  21222 2019-01-22      
#> # … with 48,899 more rows, and 22 more variables: surveytype <chr>, defpref <lgl>, category <chr>,
#> #   tag <chr>, tag_desc <chr>, scope <chr>, defstat <chr>, statdate <date>, cycle <dbl>,
#> #   standard <chr>, complaint <chr>, filedate <date>, address_norm <chr>, zip5 <dbl>,
#> #   city_clean <chr>, year <dbl>, def_boolean <dbl>, owner_name <chr>, owner_type <chr>,
#> #   owner_percentage_clean <dbl>, role_desc <chr>, association_date_clean <date>

infected_owner %>% write_csv(path = path(proc_dir,"infected_owners.csv"), na = "")
```
