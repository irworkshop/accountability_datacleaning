# Accountability Project

The Accountability Project curates, standardizes and indexes public data to give
journalists, researchers, and others a simple way to search across otherwise
siloed records. Our collection includes 1.4 billion public records so far.

## Data cleaning

This repository contains the code and documentation used to clean public data
hosted on [The Accountability Project][tap]. We make our data cleaning workflows
open source so anybody can double check the way we handle public data.

Data is organized by either the state or federal level, with subdirectories for
each _type_ of data (e.g., voter registration, campaign contributions).

This repository is language agnostic, with code in R, SQL, and Python depending
on the contributor's preference and the raw data used. Regardless of language,
try to follow IRW's [guide to accountability data cleaning][guide].

## Contribute

When contributing data to TAP, document your work and track changes in git. The
git workflow can be daunting, but there are [many helpful guides online][githow]
and only a few commands can get you most of the functionality. You maybe be able
to use GUI tools in your IDE (e.g., [RStudio's version control pane][rsvs]) or
a [desktop application][ghdesk].

1. Clone the master branch of this repository to a local directory. This will
download everything from GitHub and give your new files a place to live.
    ```shell
    cd ~/Documents
    git clone git@github.com:irworkshop/accountability_datacleaning.git
    ```
2. Create a new branch for the data you're working on. This branch should have
a simple and distinct name describing the locale and data (i.e., `st_type`).
    ```shell
    git checkout -b vt_contribs
    ```
3. Initialize a directory on your new branch, if needed. For state data, find
the appropriate state directory; for federal or national data, try naming the
directory with the agency and program abbreviation (e.g., `hhs_prf`).
    ```
    mkdir state/vt/contribs
    ```
4. Track your work in a source code file. Consider using [RMarkdown][rmd],
[Jupyter notebooks][jup], or some other literate programming format where your
process is explained in natural language intertwined with code. This makes it
easy for others to check your work. Code exported in Markdown format is
particularly readable when hosted on GitHub.
5. Organize your files into separate subdirectories for code, data, images, etc.
Treat raw source data as immutable; try to download it directory from the source
within your code and only make changes to a copy or final export.
    ```
    state
    ├── vt
    │   ├── contracts
    │   ├── contribs
    │   │   ├── data
    │   │   │   ├── export
    │   │   │   |   └── vt_contribs_20201031.csv
    │   │   │   └── raw
    │   │   │       ├── ContributionsList-2020.csv
    │   │   │       └── ContributionsList-2021.csv
    │   │   ├── docs
    │   │   │   ├── vt_contribs_diary.Rmd
    │   │   │   └── vt_contribs_diary.md
    │   │   └── plots
    │   │       ├── amount_histogram-1.png
    │   │       └── year_count_bar-1.png
    │   ├── expends
    │   └── voters
    ```
6. Commit your work along the way. This helps track progress and undo mistakes.
    ```shell
    git commit -a -m "Read VT contrib data from SOS"
    ```
7. Submit a [pull request][pr] to this repository so your additions can be
reviewed and merged into the master branch!

## Tips

* If you're using [RStudio][rstudio] with the R language, use the `R_tap.Rproj`
[project][rproj] file for easy directory management.
* Install IRW's own [campfin] R package for a suite of handy tools.
* Try the `campfin::use_diary()` function to automatically create a template
RMarkdown diary in the appropriate state directory.
    ```r
    use_diary(st = "VT", type = "contribs")
    ```

[tap]: https://publicaccountability.org/
[githow]: https://guides.github.com/introduction/git-handbook/
[guide]: GUIDE.md
[rsvs]: https://support.rstudio.com/hc/en-us/articles/200532077-Version-Control-with-Git-and-SVN
[ghdesk]: https://desktop.github.com/
[rmd]: https://rmarkdown.rstudio.com/
[jup]: https://jupyter.org/
[rproj]: https://support.rstudio.com/hc/en-us/articles/200526207-Using-Projects
[rstudio]: https://www.rstudio.com/
[pr]: https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests
[campfin]: https://github.com/irworkshop/campfin
[here]: https://here.r-lib.org/
