library(tidyverse)
library(pdftools)
library(tabulizer)
library(lubridate)
library(fs)

pdf_url <- "https://www.vermontjudiciary.org/sites/default/files/documents/AttorneyGoodStanding_3.pdf"
pdf_tmp <- file_temp(ext = "pdf")
download.file(pdf_url1, pdf_tmp1)

vtl <- extract_tables(
  file = "https://www.vermontjudiciary.org/sites/default/files/documents/AttorneyGoodStanding_3.pdf",
  method = "lattice"
)

zz <- vtl

vtl <- vtl %>%
  map(as.data.frame) %>%
  bind_rows() %>%
  as_tibble() %>%
  row_to_names(1) %>%
  clean_names() %>%
  na_if("") %>%
  mutate(
    across(admitted, mdy),
    across(where(is.character), str_replace, "\r", " ")
  )
