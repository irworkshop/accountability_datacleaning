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
  readxl, # read excel files
  knitr, # knit documents
  vroom, # read files fast
  rvest, # html scraping
  glue, # combine strings
  here, # relative paths
  httr, # http requests
  fs # local storage
)

## ----raw_download----------------------------------------------------------------------------------------------------------------------
raw_dir <- dir_create(here("us", "eidl", "data", "raw"))
sba_home <- file.path(
  "https://www.sba.gov",
  "about-sba", "sba-performance",
  "open-government", "digital-sba",
  "open-data", "open-data-sources"
)

sba_urls <- read_html(sba_home) %>%
  html_node(".responsive-columns") %>%
  html_nodes("a") %>%
  html_attr("href") %>%
  str_subset("Disaster_Loan_Data_FY\\d")

raw_paths <- path(raw_dir, basename(sba_urls))


## --------------------------------------------------------------------------------------------------------------------------------------
if (!all(file_exists(raw_paths))) {
  download.file(sba_urls, raw_paths)
}


## ----results='asis', echo=FALSE--------------------------------------------------------------------------------------------------------
xls_sheets <- excel_sheets(raw_path[1])
md_bullet(xls_sheets)


## ----xls_instruction-------------------------------------------------------------------------------------------------------------------
instruct <- read_excel(
  path = raw_path[1],
  sheet = xls_sheets[1],
  range = "A3",
  col_names = FALSE
)


## ----results='asis', echo=FALSE--------------------------------------------------------------------------------------------------------
instruct[[1]] %>%
  str_split("\n") %>%
  map(md_quote) %>%
  extract2(1)


## ----dict_home-------------------------------------------------------------------------------------------------------------------------
dict_home <- read_excel(
  path = raw_path[1],
  range = "A1:B15",
  sheet = xls_sheets[2]
)


## ----results='asis', echo=FALSE--------------------------------------------------------------------------------------------------------
kable(dict_home)


## ----echo=FALSE------------------------------------------------------------------------------------------------------------------------
cols_home <- c(
  "sba_declare_id",
  "sba_eidl_id",
  "fema_id",
  "disaster_id",
  "disaster_desc",
  "city",
  "zip",
  "county",
  "state",
  "loss_total",
  "loss_estate",
  "loss_content",
  "loan_amount",
  "loan_estate",
  "loan_content"
)


## ----dict_biz, echo=FALSE--------------------------------------------------------------------------------------------------------------
dict_biz <- read_excel(
  path = raw_path[1],
  range = "A1:B16",
  sheet = xls_sheets[3]
)


## ----results='asis', echo=FALSE--------------------------------------------------------------------------------------------------------
kable(dict_biz)


## ----echo=FALSE------------------------------------------------------------------------------------------------------------------------
cols_biz <- c(
  "sba_declare_id",
  "sba_eidl_id",
  "fema_id",
  "disaster_id",
  "disaster_desc",
  "city",
  "zip",
  "county",
  "state",
  "loss_total",
  "loss_estate",
  "loss_content",
  "loan_amount",
  "loan_estate",
  "loan_content",
  "amount_eidl"
)


## ----xls_meta_fun----------------------------------------------------------------------------------------------------------------------
xls_meta <- function(path, sheet) {
  # read top rows
  x <- read_excel(
    path = path,
    sheet = sheet,
    range = "A1:H4",
    col_types = "text",
    col_names = LETTERS[1:8]
  )
  # coerce into list
  list(
    run_time = x$H[1:2] %>%
      map_chr(str_extract, "(?<=\\s{2}).*") %>%
      str_c(collapse = "") %>%
      mdy_hms(),
    reporting_period = x$A[3] %>%
      str_extract_all("\\d{1,2}/\\d{1,2}/\\d{4}") %>%
      as_vector() %>%
      mdy() %>%
      int_diff(),
    delcaration_types = x$A[4] %>%
      str_extract("(?<=\\s{2}).*")
  )
}


## ----xls_home_data---------------------------------------------------------------------------------------------------------------------
xls_home_data <- function(path, sheet = 4) {
  bind_cols(
    # read home data sheet
    read_excel(
      path = path,
      sheet = sheet,
      skip = 4,
      col_types = "text",
      # use dictionary for col names
      # col_names = cols_home
    ),
    # bind with meta data from top 4 rows
    as_tibble(xls_meta(path, sheet))
  )
}


## ----xls_biz_data----------------------------------------------------------------------------------------------------------------------
xls_biz_data <- function(path, sheet = 5) {
  bind_cols(
    read_excel(
      path = path,
      sheet = sheet,
      skip = 4,
      col_types = "text",
      # col_names = cols_biz
    ),
    as_tibble(xls_meta(path, sheet))
  )
}


## ----xls_home_names--------------------------------------------------------------------------------------------------------------------
# read all home sheets data into list
hd <- map(raw_paths, xls_home_data)
# find elements with 18 columns
home_which_18 <- map_lgl(hd, ~ncol(.) == 18)
# add metadata col names
cols_home <- append(cols_home, c("time", "period", "delcaration"))
# set 18 cols names to 18 col data
hd[home_which_18] <- map(hd[home_which_18], setNames, cols_home)
# remove disaster description name from 17 col data
home_which_17 <- map_lgl(hd, ~ncol(.) == 17)
hd[home_which_17] <- map(hd[home_which_17], setNames, cols_home[-5])
# bind all data together
hd <- bind_rows(hd)
# add data type to front
hd <- mutate(hd, type = "home", .before = 1)


## ----xls_biz_names---------------------------------------------------------------------------------------------------------------------
# repeat name fix for biz data
bd <- map(raw_paths, xls_biz_data)
biz_which_19 <- map_lgl(bd, ~ncol(.) == 19)
cols_biz <- append(cols_biz, c("time", "period", "delcaration"))
bd[biz_which_19] <- map(bd[biz_which_19], setNames, cols_biz)
biz_which_18 <- map_lgl(bd, ~ncol(.) == 18)
bd[biz_which_18] <- map(bd[biz_which_18], setNames, cols_biz[-5])
bd <- bind_rows(bd)
bd <- mutate(bd, type = "business", .before = 1)


## ----xls_bind_data---------------------------------------------------------------------------------------------------------------------
eidl <- type_convert(
  df = bind_rows(hd, bd),
  col_types = cols(
    loss_total = col_double(),
    loss_estate = col_double(),
    loss_content = col_double(),
    loan_amount = col_double(),
    loan_estate = col_double(),
    loan_content = col_double(),
    time = col_datetime(),
    amount_eidl = col_double()
  )
)


## ----echo=FALSE------------------------------------------------------------------------------------------------------------------------
rm(hd, bd)
flush_memory()


## ----glimpse---------------------------------------------------------------------------------------------------------------------------
glimpse(eidl)
tail(eidl)
