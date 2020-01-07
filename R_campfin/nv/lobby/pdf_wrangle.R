library(tidyverse)
library(pdftools)
backup_options <- options()
options(dplyr.print_min = 30)
# read the x/y coord of every word
pages <- pdf_data("https://www.leg.state.nv.us/Session/79th2017/Lobbyist/Reports/Lobbyists.pdf")
data <- rep(list(NA), length(pages))
for (i in seq_along(pages)) {
  x <- pages[[i]]
  x <- x %>%
    # trim excess
    filter(
      y > 61, # header
      y < 741 # footer
    ) %>%
    # identify column
    mutate(lob = x < 274, id = row_number()) %>%
    # collapse x line by column
    group_by(y, lob) %>%
    mutate(line = str_c(text, collapse = " ")) %>%
    # keep only one collapsed line
    slice(1) %>%
    arrange(id) %>%
    ungroup() %>%
    # remove word cols
    select(id, lob, line) %>%
    # identify new row section
    mutate(
      section = line %>%
        lead(default = FALSE) %>%
        str_detect("Paid Lobbyist") %>%
        cumsum()
    ) %>%
    group_split(section)

  frame_section <- function(y) {
    # find lob parts
    lob_phone <- str_subset(y$line, "^\\(\\d{3}\\)\\s\\d{3}-\\d{4}$")
    if (length(lob_phone) == 0) lob_phone <- NA_character_
    lob_email <- str_subset(y$line, "[^@]+@[^\\.]+\\..+")
    if (length(lob_email) == 0) lob_email <- NA_character_
    # make 1 row for lob
    lob <- tibble(
      lob_name = y$line[1],
      lob_type = y$line[2],
      lob_addr = y$line[3],
      lob_city = y$line[4],
      # look for regex, else NA
      lob_phone,
      lob_email
    )
    lob_end <- sum(!map_lgl(lob, is.na))
    # make 1 row per pri
    pri <- enframe(y$line[-seq(1, lob_end)], name = "row", value = "pri_name")
    pri <- mutate(pri, pri_addr = NA_character_)
    pri$pri_addr[pri$row %% 2 == 0] <- pri$pri_name[pri$row %% 2 == 0]
    pri$pri_name[pri$row %% 2 == 0] <- pri$pri_name[pri$row %% 2 != 0]
    pri <- select(filter(pri, !is.na(pri_addr)) , -row)

    # col bind, dupe lob
    as_tibble(cbind(lob, pri))
  }
  data[[i]] <- map_df(x, frame_section)
}
