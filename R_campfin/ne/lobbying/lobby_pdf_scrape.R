# Kiernan Nicholls
# Wed Nov 20 10:12:50 2019 ------------------------------
library(tidyverse)
library(pdftools)
library(glue)

pdf_file <- "https://nebraskalegislature.gov/FloorDocs/Current/PDF/Lobby/principallist.pdf"

pdf_table <- function(text) {
  text %>%
    str_remove_all("\\sWD\\s") %>%
    str_split("\n") %>%
    `[[`(1) %>%
    enframe(NULL) %>%
    slice(-c(1:4)) %>%
    mutate(
      indent = startsWith(value, "   "),
      value = str_trim(value)
    ) %>%
    separate(
      col = value,
      sep = "\\s{3,}",
      into = c("name", "address", "phone")
    )
}

lobbyists <- pdf_file %>%
  pdf_text() %>%
  map_dfr(pdf_table) %>%
  filter(phone %>% startsWith("(")) %>%
  mutate(principal = ifelse(!indent, name, NA)) %>%
  fill(principal) %>%
  filter(indent) %>%
  select(-indent) %>%
  select(lobyist = name, principal, everything())

lobbyists %>%
  separate(
    col = address,
    into = c(glue("street{1:10}"), "city_sep", "state_zip"),
    sep = ",\\s",
    fill = "left"
  ) %>%
  unite(
    starts_with("street"),
    col = "address_sep",
    sep = " ",
    na.rm = TRUE
  ) %>%
  separate(
    col = state_zip,
    sep = "\\s(?=\\d)",
    into = c("state_sep", "zip_sep")
  )
