library(tidyverse)
library(pdftools)
backup_options <- options()
options(dplyr.print_min = 39)

# read and wrangle --------------------------------------------------------

# read the x/y coord of every word
pages <- pdf_data("")

# trim header and footer
pages <- map(pages, ~filter(., between(y, 62, 740)))

# create running y increasing per page
for (i in seq_along(pages)[-length(pages)]) {
  pages[[i + 1]]$y <- pages[[i + 1]]$y + max(pages[[i]]$y)
}

# bind into a single frame
data <- bind_rows(pages, .id = "page")

# list split --------------------------------------------------------------

sections <- data %>%
  # lob left of x 274 and pri to right
  mutate(lob = x < 274, id = row_number()) %>%
  # collapse x line by column
  group_by(y, lob) %>%
  mutate(line = str_c(text, collapse = " ")) %>%
  # keep only one collapsed line
  slice(1) %>%
  arrange(id) %>%
  ungroup() %>%
  # remove original word cols
  select(page, id, lob, line) %>%
  # identify new row section by lob text
  mutate(
    section = line %>%
      # look ahead
      lead(default = FALSE) %>%
      # look for consistent text
      str_detect("^(Non-Paid|Paid)") %>%
      # sum previous TRUEs
      cumsum()
  ) %>%
  # split frame into lists
  group_split(section)


tidyr <- rep(list(NA), length(sections))
for (s in sections) {

  # tidy lob --------------------------------------------------------------

  a <- s$line[s$lob]

  # collapse lob type overflow
  if (a[2] == "Non-Paid Military Veteran") {
    a[2] <- paste(a[2], a[3])
    a <- a[-3]
  } else if (a[3] == "Lobbyist") {
    a[2] <- paste(a[2], a[3])
    a <- a[-3]
  }

  # first tel is lob tel
  rx_tel <- "\\(\\d{3}\\)\\s\\d{3}-\\d{4}"
  lob_phone <- str_subset(a, sprintf("^%s$", rx_tel))[1]
  # if not, replace with NA
  if (length(lob_phone) == 0) lob_phone <- NA_character_

  # collapse lob email overflow
  rx_email <- "[^@]+@[^\\.]+\\..+"
  # look for email in last line
  if (str_detect(a[length(a)], "@", negate = TRUE)) {
    if (str_detect(a[length(a) - 1], "@")) {
      # if not collapse two last lines
      a[length(a)-1] <- str_c(a[(length(a)-1):length(a)], collapse = "")
      # replace into single line
      a <- a[-length(a)]
      lob_email <- a[length(a)]
    } else {
      # fill with NA if none
      lob_email <- NA_character_
    }
  }

  # use comp if 3 lines
  if (str_which(a, rx_tel) > 5) {
    lob_comp <- a[3]
    lob_addr <- a[4]
    lob_city <- a[5]
  } else {
    lob_comp <- NA_character_
    lob_addr <- a[3]
    lob_city <- a[4]
  }

  # make 1 row for lob
  lob <- tibble(
    lob_name = a[1],
    lob_type = a[2],
    lob_comp,
    lob_addr,
    lob_city,
    lob_phone,
    lob_email
  )

  lob <- lob %>%
    # split lob city
    separate(
      col = lob_city,
      into = c("lob_city", "more"),
      sep = ",\\s"
    ) %>%
    separate(
      col = more,
      into = c("lob_state", "lob_zip"),
      sep = "\\s(?=\\d)"
    ) %>%
    # split lob name
    separate(
      col = lob_name,
      into = c("lob_last", "lob_first"),
      sep = ",\\s"
    )

  # tidy pri --------------------------------------------------------------

  # make 1 row per pri
  # some pri overflow one line
  # look for tels or lack thereof and combine
  z <- s$line[!s$lob]
  for (i in seq_along(z)) {
    # look for only nums or tel num
    if (str_detect(z[i], "^\\d+$") | str_detect(z[i], sprintf("^%s$", rx_tel))) {
      # combine with previous line
      z[i-1] <- str_c(z[i-1], z[i])
      # remove overflow
      z[i] <- NA
    }
  }
  # omit removed
  z <- na.omit(z)

  # turn lines to tibble
  pri <- enframe(z, name = "row", value = "pri_name")

  # initialize empty addr col
  pri <- mutate(pri, pri_addr = NA_character_)

  # shift every other line over and previous down
  pri$pri_addr[pri$row %% 2 == 0] <- pri$pri_name[pri$row %% 2 == 0]
  pri$pri_name[pri$row %% 2 == 0] <- pri$pri_name[pri$row %% 2 != 0]

  # remove leftover lines and row id
  pri <- select(filter(pri, !is.na(pri_addr)) , -row)

  # combine lob pri -------------------------------------------------------
  tidy[[s]] <- as_tibble(cbind(lob, pri))
}
