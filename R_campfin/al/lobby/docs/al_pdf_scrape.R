# Kiernan Nicholls
# Mon Jan 13 11:20:47 2020 ------------------------------
library(tidyverse)
library(pdftools)
library(lubridate)
library(campfin)
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
if (length(dir_ls(raw_dir)) < 5000) {
  for (i in seq(min, n)) {
    path <- glue("{raw_dir}/reg_{str_pad(i, nchar(n), pad = '0')}.pdf")
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
}

# remove timers
rm(start_time, loop_start, loop_time, total_time)

# pdf scraping functions --------------------------------------------------

frame_pdf <- function(file) {
  id <- str_extract(file, "\\d+")

  # read text of single file
  text <-
    # read lines of text
    pdf_text(pdf = file) %>%
    # concat pages of text
    str_c(collapse = "\n") %>%
    # split by newline
    str_split(pattern = "\n") %>%
    pluck(1) %>%
    # reduce whitespace
    str_squish() %>%
    # remove header, footer, empty
    str_subset("^Page \\d+ of \\d+$", negate = TRUE) %>%
    str_subset("^\\d{1,2}/\\d{1,2}/\\d{4}$", negate = TRUE) %>%
    str_subset("^$", negate = TRUE)

  frame_lob <- function(x) {
    # find email line index
    which_email <- str_which(x, "E-Mail")
    # check for no address after email
    if (str_detect(x[which_email + 1], "Address", negate = TRUE)) {
      # collapse two lines
      x[which_email] <- str_c(x[which_email], x[which_email + 1], collapse = "")
      # remove overflow line
      x <- x[-(which_email + 1)]
    }

    # extract first from which contains
    str_get <- function(string, pattern, n = 1) {
      got <- str_trim(str_extract(str_subset(string, pattern), pattern)[[n]])
      if (nchar(got) == 0) {
        got <- NA_character_
      }
      return(got)
    }
    # extract content from lines of text
    tibble(
      lob_year = as.integer(str_get(x, "(?<=Year:)(.*)")),
      lob_date = mdy(str_get(x[str_which(x, "I certify that") + 1], "(?<=Date:)(.*)")),
      lob_name = str_get(x, "(?<=Lobbyist:)(.*)(?=Business Phone:)"),
      lob_phone = str_get(x, "(?<=Business Phone:)(.*)"),
      lob_addr1 = str_get(x, "(?<=Business)(.*)(?=E-Mail)"),
      lob_addr2 = str_get(x, "(?<=Address:)(.*)"),
      lob_city = str_get(x, "(?<=City/State/Zip:)(.*)"),
      lob_public = str_get(x, "(?<=Public Employee\\?)(.*)"),
      # combine all lines between these
      lob_subjects = str_c(x[seq(
        str_which(x, "Categories of legislation") + 1,
        str_which(x, "List Business Entities") - 1
      )], collapse = " "
      )
    )
  }

  lob <-
    frame_lob(x = text) %>%
    mutate(id) %>%
    select(id, everything())

  # keep only pri lines
  pri <- text[seq(
    str_which(text, "List Business Entities") + 1,
    str_which(text, "I certify that") - 1
  )]

  pri <- pri %>%
    enframe(name = "line", value = "text") %>%
    # count pri section
    mutate(section = cumsum(str_detect(text, "Principal Name:"))) %>%
    # split into list
    group_split(section)

  # extract content from lines of text
  frame_pri <- function(section) {
    a <- section$text
    tibble(
      pri_name = str_get(a, "(?<=Principal Name:\\s)(.*)(?=\\sPhone)"),
      pri_phone = str_get(a, "(?<=Phone:)(.*)"),
      pri_addr = str_get(a, "(?<=Address:)(.*)"),
      pri_start = mdy(str_get(a, "(?<=Effective Date:)(.*)(?=\\s)")),
      pri_end_date = mdy(str_get(a, "(?<=Termination Date:)(.*)")),
      pri_sign = str_get(a, "(?<=Principal:)(.*)"),
      pri_behalf = a[str_which(a, "If your activity") + 1]
    )
  }

  # frame every section
  pri <- map_df(pri, frame_pri)

  # rep lob by col bind
  as_tibble(cbind(lob, pri))
}

# scape all files ---------------------------------------------------------

# intialize empty tibble
allr <- tibble()
files <- dir_ls(raw_dir)
pb <- txtProgressBar(1, length(files), 1)
# read each and append
for (i in seq_along(files)) {
  allr <- bind_rows(allr, frame_pdf(files[i]))
  setTxtProgressBar(pb, i)
}

# explore -----------------------------------------------------------------

nrow(allr)
#> 16982

# check lob per file
n_distinct(allr$lob_name)
length(dir_ls(raw_dir))

# check id per loop
max(as.numeric(allr$id))
print(n)

head(allr)
tail(allr)
glimpse(allr)

col_stats(allr, count_na)
col_stats(allr, n_distinct)

# evenly distributed
ggplot(data = allr) +
  geom_bar(mapping = aes(x = lob_year))

ggplot(data = allr) +
  geom_bar(mapping = aes(x = lob_public))

# wrangle -----------------------------------------------------------------

# sep lob cols
allr <- allr %>%
  mutate_all(str_to_upper) %>%
  separate(
    col = lob_name,
    into = c("lob_last", "lob_first"),
    sep = ",\\s",
    extra = "merge",
    fill = "right"
  ) %>%
  separate(
    col = lob_city,
    into = c("lob_city", "lob_state"),
    sep = ",\\s(?=[:upper:])",
    extra = "merge"
  ) %>%
  mutate_at(
    .vars = vars(lob_state),
    .funs = str_remove,
    pattern = "(.*,\\s)(?=[:upper:])"
  ) %>%
  separate(
    col = lob_state,
    into = c("lob_state", "lob_zip"),
    sep = "\\s(?=\\d+)"
  )

# sep pri cols
allr <- allr %>%
  separate(
    col = pri_addr,
    into = c(
      glue("pri_addr{1:10}"),
      "pri_city",
      "pri_state"
    ),
    sep = ",\\s+",
    extra = "merge",
    fill = "left"
  ) %>%
  unite(
    starts_with("pri_addr"),
    col = pri_addr,
    sep = ", ",
    na.rm = TRUE
  ) %>%
  separate(
    col = pri_state,
    into = c("pri_state", "pri_zip"),
    sep = "\\s(?=\\d+)",
    extra = "merge",
    fill = "right"
  ) %>%
  mutate_if(
    .predicate = is_character,
    .funs = str_trim
  ) %>%
  na_if("")

# write csv ---------------------------------------------------------------

proc_dir <- dir_create(here("al", "lobby", "data", "processed"))
write_csv(
  x = allr,
  path = glue("{proc_dir}/al_lobbyist.csv")
)
