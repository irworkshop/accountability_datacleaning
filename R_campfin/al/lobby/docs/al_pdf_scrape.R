# Kiernan Nicholls
# Mon Jan 13 11:20:47 2020 ------------------------------
library(tidyverse)
library(pdftools)
library(lubridate)
library(scales)
library(glue)
library(httr)
library(here)
library(fs)
raw_dir <- dir_create(here("al", "lobby", "data", "raw"))

# download many files -----------------------------------------------------

# lob id is sequential
# min 1, max ~12000 for 2020
# n <- 11100
min <- max(as.numeric(str_extract(dir_ls(raw_dir), "\\d+")))
# min <- 6405
n <- 11100
start_time <- Sys.time()
for (i in seq(min, n)) {
  path <- glue("{raw_dir}/reg_{i}.pdf")
  loop_start <- Sys.time()
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
    deleted <- TRUE
  } else {
    deleted <- FALSE
  }
  # track progress
  loop_time <- Sys.time() - loop_start
  loop_time <- paste(round(loop_time, 2), attributes(loop_time)$units)
  total_time <- Sys.time() - start_time
  total_time <- paste(round(total_time, 2), attributes(total_time)$units)
  message(glue(
    "{i} done in {str_pad(loop_time, 2)}",
    "running for {str_pad(total_time, 2)}",
    "({percent(i/n)})",
    deleted,
    .sep = " / "
  ))
  # rand sleep
  Sys.sleep(time = runif(n = 1, min = 0, max = 3))
}

length(dir_ls(raw_dir))

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
    lob_city  = text_yxx(frame, frame$y[frame$text == "City/State/Zip:"][[1]], 159),
    lob_phone = text_yxx(frame, 152, 434),
    lob_email = text_yxx(frame, frame$y[str_which(frame$text, "E-Mail")]),
    # weird normal business section
    # lob_nrm_biz = text_yxx(frame, 251, 159),
    # lob_nrm_addr = text_yxx(frame, 269, 159),
    # lob_nrm_city = text_yxx(frame, 287, 159),
    lob_pub = text_yxx(frame, frame$y[str_which(frame$text, "Public Employee")], 159),
    lob_topic = text_yxx(frame, frame$y[str_which(frame$text, "Categories")])
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
  .x = dir_ls(raw_dir, glob = "*/reg_\\d+.pdf"),
  .f = frame_pdf
)

nrow(allr)
#> 16982

# check lob per file
n_distinct(allr$lob_name)
length(dir_ls(raw_dir))

# check id per loop
max(as.numeric(allr$id))
print(n)

# normalize ---------------------------------------------------------------

# sep cols
allr %>%
  mutate_all(str_to_upper) %>%
  separate(
    col = lob_name,
    into = c("lob_last", "lob_first"),
    sep = ",\\s",
    extra = "merge",
    fill = "right"
  )

allr %>%
  select(lob_city) %>%
  distinct()

# write csv ---------------------------------------------------------------

proc_dir <- dir_create(here("al", "lobby", "data", "processed"))
write_csv(
  x = allr,
  path = glue("{proc_dir}/al_lobbyist.csv")
)
