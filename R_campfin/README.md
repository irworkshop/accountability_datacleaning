# contributions

The Accountability Project is an effort to cut across data silos and give journalists, policy professionals, activists, and the public at large a simple way to search across huge volumes of public data about people and organizations.

This repository contains the code used to collected and clean **state-level public campaign contribution data**.

## Data

Data is collected from the individual states. All data is public record, but not all data is easily accesible from the internet; some states deliver data on an individual basis in a hard disk format.

## Process

We've are standardizing public data on a few key fields by thinking of each dataset row as a transaction. For each transaction there should be at least these 3 variables:

1. All **parties** to a transaction
2. The **date** of the contribution
3. The **amount** of money involved

Data manipulation follows the [IRW data cleaning guide](accountability_datacleaning/IRW_guides/data_check_guide.md).

The documents in each state's `docs/` folder record the entire process to allow for reproducability and transparency.

Software used is free and open source. R can be downloaded from a [CRAN mirror](https://cloud.r-project.org/). 

The following R packages should be installed to reproduce our findings:

```
install.packages("pacman")
pacman::p_load(
  tidyverse, 
  lubridate, 
  magrittr, 
  janitor, 
  zipcode, 
  here
)
```

## Help

If you know of a dataset that you think belongs here, [suggest it for inclusion](https://www.publicaccountability.org/static/apps/submit/index.html). We're especially interested in the data that agencies have hidden behind "search portals" or state legislative exemptions. Have you scraped a gnarly records site? Share it with us and we'll credit you. And more importantly, other people may benefit from your hard work.
