# Accountability Data Cleaning

A collection of scripts and notes used for [The Accountability Project][tap].

[tap]: https://publicaccountability.org/

Files are typically organized by either state or federal agency. While this
repository serves as an [R project][rproj], and many files are written in the
R language, many SQL or Python files are also stored here and should normally.

Many of the files used in the project are obtained and handled elsewhere; this
only describes a subset where code was used for exploring and cleaning data.

## Structure

To begin working on the project, clone the master branch of this repository.

``` bash
git clone git@github.com:irworkshop/accountability_datacleaning.git
```

For working in R and [RStudio][rstudio], open the `tap.Rproj` file in RStudio.
This will let you create and edit data documentation using the proper file
hierarchy.

Data is organized by state at the top level of the R project, with files
organized by data type subdirectories (e.g., contributions, expenditures,
lobbyists, voters, salaries). In each _data_ type directory, file are then
typically organized by their _file_ type:

1. `docs/` for code, diaries, and keys
2. `data/raw/` for *immutable* raw data
3. `data/clean/` for processed data
4. `plots/` for exploratory graphics

<!-- end list -->

```
md/contribs/
├── data
│   ├── clean
│   │   └── md_contribs_clean.csv
│   ├── dupes.csv.xz
│   ├── fix_file.txt
│   └── raw
│       ├── ContributionsList-2019.csv
│       ├── ContributionsList-2020.csv
│       └── ContributionsList-2021.csv
├── docs
│   ├── md_contribs_diary.Rmd
│   └── md_contribs_diary.md
└── plots
    ├── amount_histogram.png
    └── year_bar.png
```

## Data

Data is collected from the individual states or agencies. All data is public
record, but not all data is easily accessible from the internet; some states
provided data in bulk downloads while others deliver them in hard copy for a
nominal fee.

## Process

We are standardizing public data on a few key fields by thinking of each dataset
row as a transaction or registration. For each row there should typically be:

1. Both **parties** to a transaction
2. The **date** of the transaction
3. Any **amount** of money involved

Data manipulation follows the [IRW data cleaning guide][guide] to achieve the
following objectives:

1. How many records are in the database?
2. Check for duplicate records if that might be a problem?
3. Check numeric and date ranges. Anything too high or too low?
4. Is there anything blank or missing?
5. Is there information in the wrong field?
6. Check for consistency issues - particularly on city, state and ZIP.
7. Create a five-digit `zip` code variable if one does not exist.
8. Create a four-digit `year` field from the transaction `date`.
9. Make sure there is both a donor *and* recipient for transactions.

The documents in each state’s `docs/` folder record the entire process to
promote for reproducibility and transparency. From our campfin package, call
the `use_diary()` function to create a new template diary for exploration, with
all the necessary steps laid out:

1. Describe
2. Import
3. Explore
4. Wrangle
5. Export

``` r
campfin::use_diary(
  st = "DC", 
  type = "voters", 
  author = "Kiernan Nicholls", 
  auto = TRUE
)
# ✓ ~/states/dc/voters/docs/dc_voters_diary.Rmd was created
```

This template should approximate the workflow but tweak each section according
to your data source and structure (e.g., template column names are replaced with
the actual names).

The R markdown diary should run/knit from start to finish without errors,
ending with a saved comma-delimited file from `readr::write_csv()`. 

The processed CSV file is then uploaded to the Workshop's AWS server where it
can be searched from the Accountability Project website.

``` r
put_object(
  file = "dc/voters/data/clean/dc_voters_clean.csv",
  object = "csv/dc_voters_clean.csv", 
  bucket = "publicaccountability",
  acl = "public-read"
)
```

Knitting the diary should produce a `.md` markdown file _alongside_ your `.Rmd`
diary. This markdown file is rendered on GitHub as an HTML page for others to
view your work.

## Software

Software used is free and open source. R can be downloaded from the [CRAN].

The campfin R package has been written by IRW to facilitate exploration and
wrangling of campaign finance data. The stable version is on CRAN but the
latest version lives on GitHub.

``` r
# install.packages("remotes")
remotes::install_github("irworkshp/campfin")
```

Most cleaning is done using the [tidyverse][tverse], an opinionated collection
of R packages for data manipulation.

``` r
install.packages("tidyverse")
```

## Help

If you know of a dataset that you think belongs here, [suggest it for
inclusion](https://www.publicaccountability.org/static/apps/submit/index.html).
We’re especially interested in the data that agencies have hidden behind
“search portals” or state legislative exemptions. Have you scraped a
gnarly records site? Share it with us and we’ll credit you. And more
importantly, other people may benefit from your hard work.

[rproj]: https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects
[rstudio]: https://www.rstudio.com/
[CRAN]: https://cran.r-project.org/mirrors.html
[campfin]: https://github.com/irworkshop/campfin
[tverse]: https://github.com/tidyverse
[guide]: https://github.com/irworkshop/accountability_datacleaning/blob/campfin/IRW_guides/data_check_guide.md

