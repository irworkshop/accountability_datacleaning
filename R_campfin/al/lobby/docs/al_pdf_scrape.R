# Kiernan Nicholls
# Mon Jan 13 11:20:47 2020 ------------------------------
library(tidyverse)
library(pdftools)
library(lubridate)
library(glue)
library(httr)
library(here)
library(fs)
raw_dir <- dir_create(here("al", "lobby", "data", "raw"))

# download many files -----------------------------------------------------

# lob id is sequential
# min 1, max ~12000 for 2020
# n <- 11100
n <- 100
start_time <- Sys.time()
for (i in seq(1, n)) {
  loop_start <- Sys.time()
  path <- glue("{raw_dir}/reg_{i}.pdf")
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
  }
  # print progress
  loop_time <- Sys.time() - loop_start
  loop_time <- paste(round(loop_time, 3), attributes(loop_time)$units)
  total_time <- Sys.time() - start_time
  total_time <- paste(round(total_time, 3), attributes(total_time)$units)
  message(glue("{i} done in {loop_time}, running {total_time} ({scales::percent(i/n)})"))
  # rand sleep
  Sys.sleep(time = runif(n = 1, min = 0, max = 3))
}

# pdf scraping functions --------------------------------------------------

# function to select lines of pdf by x/y coord
text_yxx <- function(df, y, x = 0, x2 = 600) {
  line <- str_c(df$text[df$y == y & df$x >= x & df$x < x2], collapse = " ")
  if (length(line) == 0) {
    return(NA_character_)
  } else {
    return(line)
  }
}

# function to list lines
frame_lob <- function(frame) {
  frame <- frame[[1]]
  if (!is_tibble(frame)) {
    stop("pass page tibble from pdf_data()")
  }
  lob <- list(
    lob_year  = text_yxx(frame, 115, 92),
    lob_name  = text_yxx(frame, 152, 159, 353),
    lob_addr1   = text_yxx(frame, 170, 159, 353),
    lob_addr2  = text_yxx(frame, 188, 159, 353),
    lob_city  = text_yxx(frame, 206, 159),
    lob_phone = text_yxx(frame, 152, 434),
    lob_email = text_yxx(frame, 170, 434),
    # weird normal business section
    # lob_nrm_biz = text_yxx(frame, 251, 159),
    # lob_nrm_addr = text_yxx(frame, 269, 159),
    # lob_nrm_city = text_yxx(frame, 287, 159),
    lob_pub = text_yxx(frame, 314, 159) == "Yes",
    lob_topic = str_split(text_yxx(frame, 350), "ZZZ")
  )
  as_tibble(lob)
}


frame_pri <- function(section) {
  a <- section$line
  pri <- list(
    pri_name = str_extract(a[1], "(?<=Principal Name:\\s)(.*)(?=\\sPhone)"),
    pri_phone = str_extract(a[1], "(?<=Phone:\\s)(.*)"),
    pri_addr = str_extract(a[2], "(?<=Address:\\s)(.*)"),
    pri_start = mdy(str_extract(a[3], "(?<=Effective Date:\\s)(.*)(?=\\s)")),
    pri_end_date = mdy(str_extract(a[3], "(?<=Termination Date:\\s)(.*)(?=\\s)")),
    pri_sign = str_extract(a[4], "(?<=:\\s)(.*)"),
    pri_behalf = if (nrow(section > 5)) a[6] else NA_character_
  )
  as_tibble(pri)
}

# pdf formatting ----------------------------------------------------------

frame_pdf <- function(file) {
  id <- str_extract(file, "\\d+")
  # read pages of single file
  pages <- pdf_data(file)
  # remove header and footer
  pages <- map(pages, ~filter(., y > 40, y < 742))

  # 1 row for lob
  lob <- frame_lob(pages) %>%
    mutate(id) %>%
    select(id, everything())

  # adjust running y coord
  for (i in seq_along(pages)[-length(pages)]) {
    pages[[i + 1]]$y <- pages[[i + 1]]$y + max(pages[[i]]$y)
  }

  # collapse frame by pri section
  sections <- pages %>%
    bind_rows(.id = "page") %>%
    filter() %>%
    mutate(id = row_number()) %>%
    group_by(y) %>%
    mutate(line = str_c(text, collapse = " ")) %>%
    # keep only one collapsed line
    slice(1) %>%
    arrange(id) %>%
    ungroup() %>%
    # remove original word cols
    select(page, line) %>%
    # identify new row section by lob text
    mutate(
      section = line %>%
        # look for consistent text
        str_detect("^Principal Name") %>%
        # sum previous TRUEs
        cumsum()
    ) %>%
    filter(section > 0) %>%
    group_split(section)

  # remove last signature section
  sections[[length(sections)]] <- sections[[length(sections)]] %>%
    filter(
      str_detect(line, "^I certify that", negate = TRUE),
      str_detect(line, "^Date:\\s\\d", negate = TRUE),
      str_detect(line, "^Type or Legibly", negate = TRUE),
    )

  # frame every section
  pri <- map_df(sections, frame_pri)

  # rep lob by col bind
  as_tibble(cbind(lob, pri))
}

# scape all files ---------------------------------------------------------

allr <- map_df(
  .x = dir_ls(raw_dir),
  .f = frame_pdf
)

# check lob per file
n_distinct(allr$lob_name)
length(dir_ls(raw_dir))

# check id per loop
max(as.numeric(allr$id))
print(n)

# write csv ---------------------------------------------------------------

proc_dir <- dir_create(here("al", "lobby", "data", "processed"))
write_csv(
  x = allr,
  path = glue("{proc_dir}/al_lobbyist.csv")
)
