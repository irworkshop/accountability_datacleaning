New York Payroll Data Diary
================
Yanqi Xu
2020-04-15 11:32:00

  - [Project](#project)
  - [Objectives](#objectives)
  - [Packages](#packages)
  - [Data](#data)
  - [Wrangle](#wrangle)
  - [Explore](#explore)
  - [Conclude](#conclude)
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
  kableExtra, # create styled kable
  readxl, # read excel files
  tidyverse, # data manipulation
  lubridate, # datetime strings
  gluedown, # printing markdown
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
#> [1] "/Users/yanqixu/code/accountability_datacleaning/R_campfin"
```

## Data

Data is obtained from the [New York City’s data
portal](https://data.ny.gov/City-Government/Citywide-Payroll-Data-Fiscal-Year-/k397-673e).
According to the website, the data was created October 31, 2015 and Last
Updated on January 14, 2020. It comes from the Office of Payroll
Administration and is updated annually.

> Data is collected because of public interest in how the City’s budget
> is being spent on salary and overtime pay for all municipal employees.
> Data is input into the City’s Personnel Management System (“PMS”) by
> the respective user Agencies. Each record represents the following
> statistics for every city employee: Agency, Last Name, First Name,
> Middle Initial, Agency Start Date, Work Location Borough, Job Title
> Description, Leave Status as of the close of the FY (June 30th), Base
> Salary, Pay Basis, Regular Hours Paid, Regular Gross Paid, Overtime
> Hours worked, Total Overtime Paid, and Total Other Compensation
> (i.e. lump sum and/or retro payments). This data can be used to
> analyze how the City’s financial resources are allocated and how much
> of the City’s budget is being devoted to overtime. The reader of this
> data should be aware that increments of salary increases received over
> the course of any one fiscal year will not be reflected. All that is
> captured, is the employee’s final base and gross salary at the end of
> the fiscal year.

> NOTE: As a part of FISA-OPA’s routine process for reviewing and
> releasing Citywide Payroll Data, data for some agencies (specifically
> NYC Police Department (NYPD) and the District Attorneys’ Offices
> (Manhattan, Kings, Queens, Richmond, Bronx, and Special Narcotics))
> have been redacted since they are exempt from disclosure pursuant to
> the Freedom of Information Law, POL § 87(2)(f), on the ground that
> disclosure of the information could endanger the life and safety of
> the public servants listed thereon. They are further exempt from
> disclosure pursuant to POL § 87(2)(e)(iii), on the ground that any
> release of the information would identify confidential sources or
> disclose confidential information relating to a criminal
> investigation, and POL § 87(2)(e)(iv), on the ground that disclosure
> would reveal non-routine criminal investigative techniques or
> procedures.

``` r
raw_dir <- dir_create(here("ny", "nyc","salaries", "data", "raw"))
data_dir <- here("ny", "nyc","salaries", "data")
```

### Import

Besides the raw data, a data dictionary is also available for
[download](https://data.ny.gov/api/views/k397-673e/files/6a4a6c57-7579-4d51-a7e2-9698ef6f96e3?download=true&filename=Open-Data-Dictionary-Citywide_Payroll.FINAL.XLSX).

``` r
nyp <- dir_ls(raw_dir) %>% read_csv() 
# change column names into snake case, i.e. snake_case
nyp <- nyp %>% clean_names()
```

### Inspect

We can take a look at the top, bottom and a random sample of the
dataset.

``` r
head(nyp)
#> # A tibble: 6 x 17
#>   fiscal_year payroll_number agency_name last_name first_name mid_init agency_start_da…
#>         <dbl>          <dbl> <chr>       <chr>     <chr>      <chr>    <chr>           
#> 1        2019             67 ADMIN FOR … SIMMONS   DONALD     <NA>     07/04/2011      
#> 2        2019             67 ADMIN FOR … MOHAMMED  KATHIE     S        10/24/2011      
#> 3        2019             67 ADMIN FOR … MCRAE     TANESIA    M        09/11/2017      
#> 4        2019             67 ADMIN FOR … ROZON     GINNETTE   <NA>     08/14/2017      
#> 5        2019             67 ADMIN FOR … LOPEZ     RAFAEL     <NA>     01/17/2012      
#> 6        2019             67 ADMIN FOR … GONZALEZ… ANDREA     M        12/02/2013      
#> # … with 10 more variables: work_location_borough <chr>, title_description <chr>,
#> #   leave_status_as_of_june_30 <chr>, base_salary <dbl>, pay_basis <chr>, regular_hours <dbl>,
#> #   regular_gross_paid <dbl>, ot_hours <dbl>, total_ot_paid <dbl>, total_other_pay <dbl>
tail(nyp)
#> # A tibble: 6 x 17
#>   fiscal_year payroll_number agency_name last_name first_name mid_init agency_start_da…
#>         <dbl>          <dbl> <chr>       <chr>     <chr>      <chr>    <chr>           
#> 1        2017             NA TEACHERS R… YEOSTROS  CONSTANTI… L        06/06/2016      
#> 2        2017             NA TEACHERS R… YERUSHAL… DAVID      <NA>     04/19/1999      
#> 3        2017             NA TEACHERS R… YUKHVIDOV ALEXANDER  V        09/13/2010      
#> 4        2017             NA TEACHERS R… ZAMKOVSKY ELLA       <NA>     10/04/2010      
#> 5        2017             NA TEACHERS R… ZHOU      HUI ZHEN   <NA>     10/18/2004      
#> 6        2017             NA TEACHERS R… ZHU       JIN CHANG  <NA>     10/04/2004      
#> # … with 10 more variables: work_location_borough <chr>, title_description <chr>,
#> #   leave_status_as_of_june_30 <chr>, base_salary <dbl>, pay_basis <chr>, regular_hours <dbl>,
#> #   regular_gross_paid <dbl>, ot_hours <dbl>, total_ot_paid <dbl>, total_other_pay <dbl>
glimpse(sample_frac(nyp))
#> Rows: 3,333,368
#> Columns: 17
#> $ fiscal_year                <dbl> 2016, 2014, 2015, 2019, 2014, 2015, 2019, 2017, 2016, 2016, 2…
#> $ payroll_number             <dbl> NA, 827, NA, 747, 300, NA, 816, NA, NA, NA, 742, 56, NA, 744,…
#> $ agency_name                <chr> "BOARD OF ELECTION POLL WORKERS", "DEPARTMENT OF SANITATION",…
#> $ last_name                  <chr> "MITCHELL", "SCIARETTA", "HARDING", "DIXON", "ROYAL", "ABREU …
#> $ first_name                 <chr> "VALERIE", "PATRICK", "BLAYNE", "ANN MARIE", "NEVA", "CARLOS"…
#> $ mid_init                   <chr> NA, "A", "R", "V", NA, "M", NA, "K", "D", NA, NA, "A", "R", N…
#> $ agency_start_date          <chr> "01/01/2010", "12/27/1999", "10/25/2001", "09/08/2015", "01/0…
#> $ work_location_borough      <chr> "MANHATTAN", NA, "QUEENS", "MANHATTAN", NA, "MANHATTAN", "BRO…
#> $ title_description          <chr> "ELECTION WORKER", "SANITATION WORKER", "ELECTRICIAN", "TEACH…
#> $ leave_status_as_of_june_30 <chr> "ACTIVE", "ACTIVE", "ACTIVE", "ACTIVE", "ACTIVE", "CEASED", "…
#> $ base_salary                <dbl> 1.00, 69339.00, 343.00, 33.18, 1.00, 26343.00, 105161.00, 920…
#> $ pay_basis                  <chr> "per Hour", "per Annum", "per Day", "per Day", "per Hour", "p…
#> $ regular_hours              <dbl> 0.00, 2085.72, 1825.00, 0.00, 0.00, 0.00, 2085.72, 0.00, 0.00…
#> $ regular_gross_paid         <dbl> 225.00, 69073.16, 89180.00, 1443.91, 778.00, 147.72, 104443.6…
#> $ ot_hours                   <dbl> 0.00, 170.00, 1044.25, 0.00, 0.00, 0.00, 24.00, 0.00, 0.00, 0…
#> $ total_ot_paid              <dbl> 0.00, 7489.62, 76458.38, 0.00, 0.00, 0.00, 1820.78, 0.00, 0.0…
#> $ total_other_pay            <dbl> 0.00, 17901.17, 2388.75, 0.00, 0.00, 0.00, 12716.08, 0.00, 0.…
```

We can also view the data ditcionary.

``` r
dict <- dir_ls(data_dir, glob = "*.XLSX") %>% read_xlsx(sheet = 2, skip = 1, col_types = "text")
```

<table class="table table-striped" style="margin-left: auto; margin-right: auto;">

<thead>

<tr>

<th style="text-align:left;">

Column Name

</th>

<th style="text-align:left;">

Column Description

</th>

<th style="text-align:left;">

Term, Acronym, or Code Definitions

</th>

<th style="text-align:left;">

Additional Notes (where applicable, include the range of possible
values, units of measure, how to interpret null/zero values, whether
there are specific relationships between columns, and information on
column source)

</th>

</tr>

</thead>

<tbody>

<tr>

<td style="text-align:left;">

Payroll Description

</td>

<td style="text-align:left;">

The Payroll agency that the employee works for

</td>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

</td>

</tr>

<tr>

<td style="text-align:left;">

Last Name

</td>

<td style="text-align:left;">

Last name of employee

</td>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

</td>

</tr>

<tr>

<td style="text-align:left;">

First Name

</td>

<td style="text-align:left;">

First name of employee

</td>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

</td>

</tr>

<tr>

<td style="text-align:left;">

Middle Initial

</td>

<td style="text-align:left;">

Middle initial of employee

</td>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

</td>

</tr>

<tr>

<td style="text-align:left;">

Agency Start Date

</td>

<td style="text-align:left;">

Date which employee began working for their current agency

</td>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

</td>

</tr>

<tr>

<td style="text-align:left;">

Work Location Borough

</td>

<td style="text-align:left;">

Borough of employee’s primary work location

</td>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

</td>

</tr>

<tr>

<td style="text-align:left;">

Title Description

</td>

<td style="text-align:left;">

Civil service title description of the employee

</td>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

</td>

</tr>

<tr>

<td style="text-align:left;">

Leave Status as of Jun 30

</td>

<td style="text-align:left;">

Status of employee as of the close of the relevant fiscal year: Active,
Ceased, or On Leave

</td>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

</td>

</tr>

<tr>

<td style="text-align:left;">

Base Salary

</td>

<td style="text-align:left;">

Base Salary assigned to the employee

</td>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

Base Salary represents the amount the job pays (not necessarily what was
earned) and not including any other pay (differentials, lump sums,
uniform allowance, meal allowance, retroactive pay increases, settlement
amounts, etc) or overtime

</td>

</tr>

<tr>

<td style="text-align:left;">

Pay Basis

</td>

<td style="text-align:left;">

Lists whether the employee is paid on an hourly, per diem or annual
basis

</td>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

</td>

</tr>

<tr>

<td style="text-align:left;">

Regular Hours

</td>

<td style="text-align:left;">

Number of regular hours employee worked in the fiscal year

</td>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

This does not include overtime hours

</td>

</tr>

<tr>

<td style="text-align:left;">

Regular Gross Paid

</td>

<td style="text-align:left;">

The amount paid to the employee for base salary during the fiscal year

</td>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

Regular gross paid represents actual base salary during reporting
period, which is the portion of the person’s annual salary paid before
deductions are calculated. This does not include overtime pay or other
compensation and does not reflect the after tax amount or net pay. Total
gross pay is calculated by adding columns L, N and O.

</td>

</tr>

<tr>

<td style="text-align:left;">

OT Hours

</td>

<td style="text-align:left;">

Overtime Hours worked by employee in the fiscal year

</td>

<td style="text-align:left;">

OT= Overtime

</td>

<td style="text-align:left;">

</td>

</tr>

<tr>

<td style="text-align:left;">

Total OT Paid

</td>

<td style="text-align:left;">

Total overtime pay paid to the employee in the fiscal year

</td>

<td style="text-align:left;">

OT= Overtime

</td>

<td style="text-align:left;">

</td>

</tr>

<tr>

<td style="text-align:left;">

Total Other Pay

</td>

<td style="text-align:left;">

Includes any compensation in addition to gross salary and overtime pay,
ie Differentials, lump sums, uniform allowance, meal allowance,
retroactive pay increases, settlement amounts, and bonus pay, if
applicable.

</td>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

Not every employee will have a value in this field. For those employees
with no other pay, earnings will be stated as $0

</td>

</tr>

</tbody>

</table>

## Wrangle

### State

We can add the state column.

``` r
nyp <- nyp %>% 
  mutate(state = "NY")
```

### City

We can add the city column “New York City” as well

``` r
nyp <- nyp %>% 
  mutate(city = "NEW YORK CITY")
```

### Date

The column `agency_start_date` is read as character. Here we can use
`as.Date` and specify the `format` argument to turn this column into
dates.

``` r
nyp <- nyp %>% 
  mutate(agency_start_date = as.Date(agency_start_date, format = "%m/%d/%Y"))
```

### Total Gross Pay

According to the data dictionary, Total gross pay is the sum of
`regular_gross_paid`, `total_ot_paid` and `total_other_pay`, so we will
need to generate a new column that we will use for The Public
Accountability Project.

``` r
nyp <- nyp %>% 
  mutate(total_gross_pay = regular_gross_paid + total_ot_paid + total_other_pay)
```

## Explore

### Duplicates

Then we can take a look at the *NA* fields and number of distinct values
for each column.

``` r
col_stats(nyp, count_na)
#> # A tibble: 20 x 4
#>    col                        class        n         p
#>    <chr>                      <chr>    <int>     <dbl>
#>  1 fiscal_year                <dbl>        0 0        
#>  2 payroll_number             <dbl>  1745440 0.524    
#>  3 agency_name                <chr>        0 0        
#>  4 last_name                  <chr>     1677 0.000503 
#>  5 first_name                 <chr>     1698 0.000509 
#>  6 mid_init                   <chr>  1355588 0.407    
#>  7 agency_start_date          <date>       0 0        
#>  8 work_location_borough      <chr>   506223 0.152    
#>  9 title_description          <chr>       78 0.0000234
#> 10 leave_status_as_of_june_30 <chr>        0 0        
#> 11 base_salary                <dbl>        0 0        
#> 12 pay_basis                  <chr>        0 0        
#> 13 regular_hours              <dbl>        0 0        
#> 14 regular_gross_paid         <dbl>        0 0        
#> 15 ot_hours                   <dbl>        0 0        
#> 16 total_ot_paid              <dbl>        0 0        
#> 17 total_other_pay            <dbl>        0 0        
#> 18 state                      <chr>        0 0        
#> 19 city                       <chr>        0 0        
#> 20 total_gross_pay            <dbl>        0 0
col_stats(nyp, n_distinct) 
#> # A tibble: 20 x 4
#>    col                        class        n           p
#>    <chr>                      <chr>    <int>       <dbl>
#>  1 fiscal_year                <dbl>        6 0.00000180 
#>  2 payroll_number             <dbl>      158 0.0000474  
#>  3 agency_name                <chr>      165 0.0000495  
#>  4 last_name                  <chr>   151359 0.0454     
#>  5 first_name                 <chr>    84277 0.0253     
#>  6 mid_init                   <chr>       44 0.0000132  
#>  7 agency_start_date          <date>   14621 0.00439    
#>  8 work_location_borough      <chr>       23 0.00000690 
#>  9 title_description          <chr>     1762 0.000529   
#> 10 leave_status_as_of_june_30 <chr>        5 0.00000150 
#> 11 base_salary                <dbl>    89793 0.0269     
#> 12 pay_basis                  <chr>        4 0.00000120 
#> 13 regular_hours              <dbl>    80637 0.0242     
#> 14 regular_gross_paid         <dbl>  1614009 0.484      
#> 15 ot_hours                   <dbl>    47946 0.0144     
#> 16 total_ot_paid              <dbl>   706694 0.212      
#> 17 total_other_pay            <dbl>   659463 0.198      
#> 18 state                      <chr>        1 0.000000300
#> 19 city                       <chr>        1 0.000000300
#> 20 total_gross_pay            <dbl>  2255830 0.677
```

### Missing

We’ll use the `campfin:flag_na()` function to flag the records without
any names and title description

``` r
nyp <- nyp %>% 
  flag_na(first_name, last_name, title_description)
```

There are no duplicate rows in the database.

``` r
nyp <- flag_dupes(nyp, dplyr::everything())
```

### Categorical

![](../plots/year_plot-1.png)<!-- -->

### Continuous

``` r
nyp %>% 
  ggplot(aes(total_gross_pay)) +
  geom_histogram(fill = RColorBrewer::brewer.pal(3, "Dark2")[1]) +
  geom_vline(xintercept = median(nyp$total_gross_pay[nyp$total_gross_pay != 0], na.rm = TRUE), linetype = 2) +
  scale_y_continuous(labels = comma) +
  scale_x_continuous(
    breaks = c(1 %o% 10^(0:6)),
    labels = dollar,
    trans = "log10"
  ) +
  labs(
    title = "New York City Payroll Amount Distribution",
    caption = "Source: NYC Office of Payroll Administration via data.ny.gov",
    x = "Amount",
    y = "Count"
  ) +
  theme_minimal()
```

![](../plots/unnamed-chunk-1-1.png)<!-- -->

## Conclude

``` r
glimpse(sample_n(nyp, 20))
#> Rows: 20
#> Columns: 22
#> $ fiscal_year                <dbl> 2018, 2016, 2017, 2018, 2018, 2017, 2018, 2014, 2019, 2017, 2…
#> $ payroll_number             <dbl> 827, NA, NA, 742, 841, NA, 744, 827, 56, NA, NA, 56, 826, 836…
#> $ agency_name                <chr> "DEPARTMENT OF SANITATION", "DEPT OF ED PEDAGOGICAL", "DEPART…
#> $ last_name                  <chr> "MORACA", "DIETZ", "GARCIA JR.", "CEBOLLERO", "GARRY", "MANDU…
#> $ first_name                 <chr> "LEOPOLDO", "DOROTHY", "ANDERSON", "V", "NEIL", "MICHELE", "J…
#> $ mid_init                   <chr> "M", "J", NA, NA, "J", "E", NA, NA, "M", "L", "A", NA, "G", "…
#> $ agency_start_date          <date> 2017-08-14, 2004-09-07, 1997-10-23, 1995-09-29, 2014-01-06, …
#> $ work_location_borough      <chr> "MANHATTAN", "MANHATTAN", "QUEENS", "MANHATTAN", "MANHATTAN",…
#> $ title_description          <chr> "SANITATION WORKER", "TEACHER", "CORRECTION OFFICER", "TEACHE…
#> $ leave_status_as_of_june_30 <chr> "ACTIVE", "ACTIVE", "ACTIVE", "CEASED", "CEASED", "ACTIVE", "…
#> $ base_salary                <dbl> 40820.00, 85793.00, 82808.00, 80695.00, 55596.00, 86185.00, 3…
#> $ pay_basis                  <chr> "per Annum", "per Annum", "per Annum", "per Annum", "per Annu…
#> $ regular_hours              <dbl> 1840.00, 0.00, 2085.72, 0.00, 285.00, 0.00, 0.00, 2077.72, 20…
#> $ regular_gross_paid         <dbl> 32681.88, 83382.24, 84295.91, 1000.00, 13846.52, 94753.94, 31…
#> $ ot_hours                   <dbl> 266.33, 0.00, 145.50, 0.00, 0.00, 0.00, 0.00, 326.00, 389.00,…
#> $ total_ot_paid              <dbl> 7141.86, 0.00, 9405.51, 0.00, 381.01, 0.00, 0.00, 18260.06, 4…
#> $ total_other_pay            <dbl> 3242.94, 0.00, 11379.02, 0.00, 64.04, 0.00, 0.00, 15257.30, 2…
#> $ state                      <chr> "NY", "NY", "NY", "NY", "NY", "NY", "NY", "NY", "NY", "NY", "…
#> $ city                       <chr> "NEW YORK CITY", "NEW YORK CITY", "NEW YORK CITY", "NEW YORK …
#> $ total_gross_pay            <dbl> 43066.68, 83382.24, 105080.44, 1000.00, 14291.57, 94753.94, 3…
#> $ na_flag                    <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
#> $ dupe_flag                  <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE…
```

1.  There are 3333368 records in the database.
2.  There are no duplicate records in the database.
3.  The range and distribution of `year` seems mostly reasonable.
4.  There are 1751 records missing either recipient or date.

## Export

``` r
proc_dir <- dir_create(here("ny", "nyc", "salaries", "data", "processed"))
```

``` r
write_csv(
  x = nyp,
  path = path(proc_dir, "nyc_salaries_clean.csv"),
  na = ""
)
```
