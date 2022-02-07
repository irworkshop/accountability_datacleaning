# Kiernan Nicholls
# Investigative Reporting Workshop
# Thu Oct 28 16:07 2021

library(tidyverse)
library(lubridate)
library(fuzzyjoin)
library(pdftools)
library(campfin)

# Read --------------------------------------------------------------------

# returns xy coordinates for every word on each page
dhs_pdf <- pdf_data("us/dhs_complain/2021-CRFO-00058 - Interim Records 1.pdf")

# Widths ------------------------------------------------------------------

# read the manually determined column widths
w <- read.csv("us/dhs_complain/dhs_cols.csv")
n_col <- nrow(w)

# Page --------------------------------------------------------------------

# used for later to match state overflows
no_space_st <- str_remove_all(state.name, "\\s")

# used to determine if Y coord equals or is close to value
almost <- function(x, y, d = 2) {
  (x %in% y) | sapply(x, function(z) min(abs(y - z)) < d)
}


all <- rep(list(NA), length(dhs_pdf))

# page by page read columns
for (n in seq_along(dhs_pdf)) {
  message(n)
  pg <- dhs_pdf[[n]]

  # all the regular text is 3 pixels tall
  pg <- pg[pg$height == 3, ]

  if (n == 1) {
    # trim off the column headers on page 1
    pg <- pg[pg$y >= 73, ]
  }

  # find all text between width X coordinates and Y row coordinates
  # rows are easily delineated by the running integer on leftmost side
  row_y <- pg$y[pg$x >= 54 & pg$x <= 62]

  if (n == 16) {
    # this page has one redacted row num, use date Y coord
    row_y <- sort(c(row_y, pg$y[pg$text == "3/9/2021"]))
  }

  out <- tibble(y = row_y)

  # column by column
  for (i in seq(n_col)) {

    res <- pg %>%
      # find all text between X coords
      filter(x >= w$start[i], x <= w$end[i])

    if (i == 12) {
      # the redacted (b)(6) lines are shifted a few pixels down
      # check for any redaction and remap Y coord upwards
      res <- res %>%
        group_by(y) %>%
        # ignore any line that is ALL redacted
        filter(!all(str_detect(text, "\\((b|\\d)\\)")))
      b6_y <- str_which(res$text, "\\((b|\\d)\\)")
      y_diff <- any(res$y[b6_y] != res$y[ b6_y - 1])
      while (y_diff) {
        res$y <- ifelse(str_detect(res$text, "\\("), lag(res$y), res$y)
        y_diff <- any(res$y[b6_y] != res$y[ b6_y - 1])
      }
    }

    # back combine overflow city lines
    if (i == 23) {
      k <- 1
      while (i < nrow(res)) {
        if (res$space[k]) {
          res$text[k] <- paste0(res$text[i], res$text[k + 1])
          res <- res[-(k + 1), ]
        }
        k <- k + 1
      }
    }

    res <- res %>%
      arrange(y, x) %>%
      # combine text by Y coord line
      group_by(y) %>%
      mutate(text = paste(text, collapse = " ")) %>%
      # keep only one combined version
      slice(1) %>%
      ungroup()

    if (nrow(res) != 0) {
      res <- res %>%
        # add running count of Y line
        mutate(group = cumsum(almost(y, row_y))) %>%
        # combine text by group between X coord
        group_by(group) %>%
        mutate(text = paste(text, collapse = " ")) %>%
        arrange(y) %>%
        # keep one line of each group
        slice(1) %>%
        ungroup() %>%
        # keep the Y and text for left join
        select(y, text) %>%
        set_names(c("y", w$column[i]))

      out <- out %>%
        # join if Y coord within 1 pixel
        difference_left_join(res, by = "y") %>%
        rename(y = y.x) %>%
        select(-y.y)
    }
  }

  out <- out %>%
    arrange(y) %>%
    select(-y) %>%
    # merge overflow ID number
    mutate(across(Number, str_remove, "\\s"))
  # match and swap separated state names
  out$State <- state.name[match(str_remove_all(out$State, "\\s"), no_space_st)]
  all[[n]] <- out
}

# combine all the pages and write to file
all <- bind_rows(all)
write_csv(all, "us/dhs_complain/all_dhs.csv", na = "")
